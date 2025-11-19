# Nim-RocksDB
# Copyright 2024 Status Research & Development GmbH
# Licensed under either of
#
#  * Apache License, version 2.0, ([LICENSE-APACHE](LICENSE-APACHE) or http://www.apache.org/licenses/LICENSE-2.0)
#  * GPL license, version 2.0, ([LICENSE-GPLv2](LICENSE-GPLv2) or https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)
#
# at your option. This file may not be copied, modified, or distributed except according to those terms.

## A `RocksDBRef` represents a reference to a RocksDB instance. It can be opened
## in read-only or read-write mode in which case a `RocksDbReadOnlyRef` or
## `RocksDbReadWriteRef` will be returned respectively. The `RocksDbReadOnlyRef`
## type doesn't support any of the write operations such as `put`, `delete` or
## `write`.
##
## Many of the operations on these types can potentially fail for various reasons,
## in which case a `RocksDbResult` containing an error will be returned.
##
## The types wrap and hold a handle to a c pointer which needs to be freed
## so `close` should be called to prevent a memory leak after use.
##
## Most of the procs below support passing in the name of the column family
## which should be used for the operation. The default column family will be
## used if none is provided.

{.push raises: [].}

import
  std/[sequtils, locks],
  ./lib/librocksdb,
  ./options/[dbopts, readopts, writeopts],
  ./columnfamily/[cfopts, cfdescriptor, cfhandle],
  ./internal/[cftable, utils],
  ./[rocksiterator, rocksresult, writebatch, writebatchwi, snapshot]

export
  rocksresult, dbopts, readopts, writeopts, cfdescriptor, cfhandle, rocksiterator,
  writebatch, writebatchwi, snapshot.SnapshotRef, snapshot.isClosed,
  snapshot.getSequenceNumber

type
  RocksDbPtr* = ptr rocksdb_t
  IngestExternalFilesOptionsPtr = ptr rocksdb_ingestexternalfileoptions_t
  FlushOptionsPtr = ptr rocksdb_flushoptions_t

  RocksDbRef* = ref object of RootObj
    lock: Lock
    cPtr: RocksDbPtr
    path: string
    dbOpts: DbOptionsRef
    readOpts: ReadOptionsRef
    cfDescriptors: seq[ColFamilyDescriptor]
    defaultCfHandle: ColFamilyHandleRef
    cfTable: ColFamilyTableRef

  RocksDbReadOnlyRef* = ref object of RocksDbRef

  RocksDbReadWriteRef* = ref object of RocksDbRef
    writeOpts: WriteOptionsRef
    ingestOptsPtr: IngestExternalFilesOptionsPtr
    flushOptsPtr: FlushOptionsPtr

proc listColumnFamilies*(path: string): RocksDBResult[seq[string]] =
  ## List exisiting column families on disk. This might be used to find out
  ## whether there were some columns missing with the version on disk.
  ##
  ## Column families previously used must be declared when re-opening an
  ## existing database. So this function can be used to add some CFs
  ## on-the-fly to the opener list of CFs
  ##
  ## Note that the on-the-fly adding might not be needed in the way described
  ## above once rocksdb has been upgraded to the latest version, see comments
  ## at the end of ./columnfamily/cfhandle.nim.

  var
    cfLen: csize_t
    errors: cstring
  let
    dbOpts = defaultDbOptions(autoClose = true)
    cfList = rocksdb_list_column_families(
      dbOpts.cPtr, path.cstring, addr cfLen, cast[cstringArray](errors.addr)
    )
  bailOnErrorsWithCleanup(errors):
    autoCloseNonNil(dbOpts)

  if cfList.isNil or cfLen == 0:
    return ok(newSeqOfCap[string](0))

  defer:
    rocksdb_list_column_families_destroy(cfList, cfLen)
    dbOpts.close()

  var colFamilyNames = newSeqOfCap[string](cfLen)
  for i in 0 ..< cfLen:
    colFamilyNames.add($cfList[i])

  ok(colFamilyNames)

proc openRocksDb*(
    path: string,
    dbOpts = defaultDbOptions(autoClose = true),
    readOpts = defaultReadOptions(autoClose = true),
    writeOpts = defaultWriteOptions(autoClose = true),
    columnFamilies: openArray[ColFamilyDescriptor] = [],
): RocksDBResult[RocksDbReadWriteRef] =
  ## Open a RocksDB instance in read-write mode. If `columnFamilies` is empty
  ## then it will open the default column family. If `dbOpts`, `readOpts`, or
  ## `writeOpts` are not supplied then the default options will be used.
  ## These default options will be closed when the database is closed.
  ## If any options are provided, they will need to be closed manually.
  ##
  ## By default, column families will be created if they don't yet exist.
  ## All existing column families must be specified if the database has
  ## previously created any column families.

  var cfs = columnFamilies.toSeq()
  if DEFAULT_COLUMN_FAMILY_NAME notin columnFamilies.mapIt(it.name()):
    cfs.add(defaultColFamilyDescriptor(autoClose = true))

  var
    cfNames = cfs.mapIt(it.name().cstring)
    cfOpts = cfs.mapIt(it.options.cPtr)
    cfHandles = newSeq[ColFamilyHandlePtr](cfs.len)
    errors: cstring
  let rocksDbPtr = rocksdb_open_column_families(
    dbOpts.cPtr,
    path.cstring,
    cfNames.len().cint,
    cast[cstringArray](cfNames[0].addr),
    cfOpts[0].addr,
    cfHandles[0].addr,
    cast[cstringArray](errors.addr),
  )
  bailOnErrorsWithCleanup(errors):
    autoCloseNonNil(dbOpts)
    autoCloseNonNil(readOpts)
    autoCloseNonNil(writeOpts)
    autoCloseAll(cfs)

  let flushOptsPtr = rocksdb_flushoptions_create()
  rocksdb_flushoptions_set_wait(flushOptsPtr, 1)

  let
    cfTable = newColFamilyTable(cfNames.mapIt($it), cfHandles)
    db = RocksDbReadWriteRef(
      lock: createLock(),
      cPtr: rocksDbPtr,
      path: path,
      dbOpts: dbOpts,
      readOpts: readOpts,
      writeOpts: writeOpts,
      flushOptsPtr: flushOptsPtr,
      cfDescriptors: cfs,
      ingestOptsPtr: rocksdb_ingestexternalfileoptions_create(),
      defaultCfHandle: cfTable.get(DEFAULT_COLUMN_FAMILY_NAME),
      cfTable: cfTable,
    )
  ok(db)

proc openRocksDbReadOnly*(
    path: string,
    dbOpts = defaultDbOptions(autoClose = true),
    readOpts = defaultReadOptions(autoClose = true),
    columnFamilies: openArray[ColFamilyDescriptor] = [],
    errorIfWalFileExists = false,
): RocksDBResult[RocksDbReadOnlyRef] =
  ## Open a RocksDB instance in read-only mode. If `columnFamilies` is empty
  ## then it will open the default column family. If `dbOpts` or `readOpts` are
  ## not supplied then the default options will be used.
  ## These default options will be closed when the database is closed.
  ## If any options are provided, they will need to be closed manually.
  ##
  ## By default, column families will be created if they don't yet exist.
  ## If the database already contains any column families, then all or
  ## a subset of the existing column families can be opened for reading.

  var cfs = columnFamilies.toSeq()
  if DEFAULT_COLUMN_FAMILY_NAME notin columnFamilies.mapIt(it.name()):
    cfs.add(defaultColFamilyDescriptor(autoClose = true))

  var
    cfNames = cfs.mapIt(it.name().cstring)
    cfOpts = cfs.mapIt(it.options.cPtr)
    cfHandles = newSeq[ColFamilyHandlePtr](cfs.len)
    errors: cstring
  let rocksDbPtr = rocksdb_open_for_read_only_column_families(
    dbOpts.cPtr,
    path.cstring,
    cfNames.len().cint,
    cast[cstringArray](cfNames[0].addr),
    cfOpts[0].addr,
    cfHandles[0].addr,
    errorIfWalFileExists.uint8,
    cast[cstringArray](errors.addr),
  )
  bailOnErrorsWithCleanup(errors):
    autoCloseNonNil(dbOpts)
    autoCloseNonNil(readOpts)
    autoCloseAll(cfs)

  let
    cfTable = newColFamilyTable(cfNames.mapIt($it), cfHandles)
    db = RocksDbReadOnlyRef(
      lock: createLock(),
      cPtr: rocksDbPtr,
      path: path,
      dbOpts: dbOpts,
      readOpts: readOpts,
      cfDescriptors: cfs,
      defaultCfHandle: cfTable.get(DEFAULT_COLUMN_FAMILY_NAME),
      cfTable: cfTable,
    )
  ok(db)

proc getColFamilyHandle*(
    db: RocksDbRef, name: string
): RocksDBResult[ColFamilyHandleRef] =
  let cfHandle = db.cfTable.get(name)
  if cfHandle.isNil():
    err("rocksdb: unknown column family")
  else:
    ok(cfHandle)

template isClosed*(db: RocksDbRef): bool =
  ## Returns `true` if the database has been closed and `false` otherwise.
  db.cPtr.isNil()

proc cPtr*(db: RocksDbRef): RocksDbPtr =
  ## Get the underlying database pointer.
  doAssert not db.isClosed()
  db.cPtr

proc get*(
    db: RocksDbRef,
    key: openArray[byte],
    onData: DataProc,
    cfHandle = db.defaultCfHandle,
): RocksDBResult[bool] =
  ## Get the value for the given key from the specified column family.
  ## If the value does not exist, `false` will be returned in the result
  ## and `onData` will not be called. If the value does exist, `true` will be
  ## returned in the result and `onData` will be called with the value.
  ## The `onData` callback reduces the number of copies and therefore should be
  ## preferred if performance is required.

  var
    len: csize_t
    errors: cstring
  let data = rocksdb_get_cf(
    db.cPtr,
    db.readOpts.cPtr,
    cfHandle.cPtr,
    cast[cstring](key.unsafeAddrOrNil()),
    csize_t(key.len),
    len.addr,
    cast[cstringArray](errors.addr),
  )
  bailOnErrors(errors)

  if data.isNil():
    doAssert len == 0
    ok(false)
  else:
    onData(toOpenArrayByte(data, 0, len.int - 1))
    rocksdb_free(data)
    ok(true)

proc get*(
    db: RocksDbRef, key: openArray[byte], cfHandle = db.defaultCfHandle
): RocksDBResult[seq[byte]] =
  ## Get the value for the given key from the specified column family.
  ## If the value does not exist, an error will be returned in the result.
  ## If the value does exist, the value will be returned in the result.

  var value: seq[byte]
  proc onData(data: openArray[byte]) =
    value = @data

  let valueExists = ?db.get(key, onData, cfHandle)
  if valueExists:
    ok(value)
  else:
    err("rocksdb: value does not exist")

proc multiGet*(
    db: RocksDbRef,
    keys: openArray[seq[byte]],
    sortedInput = false,
    cfHandle = db.defaultCfHandle,
): RocksDBResult[seq[Opt[seq[byte]]]] =
  ## Get a batch of values for the given set of keys.
  ##
  ## The multiGet API improves performance by batching operations
  ## in the read path for greater efficiency. Currently, only the block based
  ## table format with full filters are supported. Other table formats such
  ## as plain table, block based table with block based filters and
  ## partitioned indexes will still work, but will not get any performance
  ## benefits.
  ##
  ## sortedInput - If true, it means the input keys are already sorted by key
  ## order, so the MultiGet() API doesn't have to sort them again. If false,
  ## the keys will be copied and sorted internally by the API - the input
  ## array will not be modified.
  assert keys.len() > 0

  var
    keysList = keys.mapIt(cast[cstring](it.unsafeAddrOrNil()))
    keysListSizes = keys.mapIt(csize_t(it.len))
    errors = newSeq[cstring](keys.len())

  var valuesPtrs =
    when NimMajor >= 2 and NimMinor >= 2:
      newSeqUninit[ptr rocksdb_pinnableslice_t](keys.len)
    else:
      newSeq[ptr rocksdb_pinnableslice_t](keys.len)

  rocksdb_batched_multi_get_cf(
    db.cPtr,
    db.readOpts.cPtr,
    cfHandle.cPtr,
    csize_t(keys.len),
    cast[cstringArray](keysList[0].addr),
    keysListSizes[0].addr,
    valuesPtrs[0].addr,
    cast[cstringArray](errors[0].addr),
    sortedInput,
  )

  for e in errors:
    if not e.isNil:
      let res = err($(e))
      rocksdb_free(e)
      return res

  var values = newSeq[Opt[seq[byte]]](keys.len())
  for i, v in valuesPtrs:
    if v.isNil():
      values[i] = Opt.none(seq[byte])
      continue

    var vLen: csize_t = 0
    let src = rocksdb_pinnableslice_value(v, vLen.addr)
    if vLen == 0:
      values[i] = Opt.some(default(seq[byte]))
      continue

    assert vLen > 0
    var dest =
      when NimMajor >= 2 and NimMinor >= 2:
        newSeqUninit[byte](vLen.int)
      else:
        newSeq[byte](vLen.int)
    copyMem(dest[0].addr, src, vLen)
    values[i] = Opt.some(dest)
    rocksdb_pinnableslice_destroy(v)

  ok(values)

proc multiGet*[N](
    db: RocksDbRef,
    keys: array[N, seq[byte]],
    sortedInput = false,
    cfHandle = db.defaultCfHandle,
): RocksDBResult[array[N, Opt[seq[byte]]]] =
  ## Get a batch of values for the given set of keys.
  ##
  ## The multiGet API improves performance by batching operations
  ## in the read path for greater efficiency. Currently, only the block based
  ## table format with full filters are supported. Other table formats such
  ## as plain table, block based table with block based filters and
  ## partitioned indexes will still work, but will not get any performance
  ## benefits.
  ##
  ## sortedInput - If true, it means the input keys are already sorted by key
  ## order, so the MultiGet() API doesn't have to sort them again. If false,
  ## the keys will be copied and sorted internally by the API - the input
  ## array will not be modified.
  assert keys.len() > 0

  var
    keysList {.noinit.}: array[N, cstring]
    keysListSizes {.noinit.}: array[N, csize_t]
    errors: array[N, cstring]

  for i in 0..keys.high:
    keysList[i] = cast[cstring](keys[i].unsafeAddrOrNil())
    keysListSizes[i] = csize_t(keys[i].len)

  var valuesPtrs: array[N, ptr rocksdb_pinnableslice_t]
  rocksdb_batched_multi_get_cf(
    db.cPtr,
    db.readOpts.cPtr,
    cfHandle.cPtr,
    csize_t(keys.len),
    cast[cstringArray](keysList[0].addr),
    keysListSizes[0].addr,
    valuesPtrs[0].addr,
    cast[cstringArray](errors[0].addr),
    sortedInput,
  )

  for e in errors:
    if not e.isNil:
      let res = err($(e))
      rocksdb_free(e)
      return res

  var values {.noinit.}: array[N, Opt[seq[byte]]]
  for i, v in valuesPtrs:
    if v.isNil():
      values[i] = Opt.none(seq[byte])
      continue

    var vLen: csize_t = 0
    let src = rocksdb_pinnableslice_value(v, vLen.addr)
    if vLen == 0:
      values[i] = Opt.some(default(seq[byte]))
      continue

    assert vLen > 0
    var dest =
      when NimMajor >= 2 and NimMinor >= 2:
        newSeq[byte](vLen.int)
      else:
        newSeq[byte](vLen.int)
    copyMem(dest[0].addr, src, vLen)
    values[i] = Opt.some(dest)
    rocksdb_pinnableslice_destroy(v)

  ok(values)

proc put*(
    db: RocksDbReadWriteRef, key, val: openArray[byte], cfHandle = db.defaultCfHandle
): RocksDBResult[void] =
  ## Put the value for the given key into the specified column family.

  var errors: cstring
  rocksdb_put_cf(
    db.cPtr,
    db.writeOpts.cPtr,
    cfHandle.cPtr,
    cast[cstring](key.unsafeAddrOrNil()),
    csize_t(key.len),
    cast[cstring](val.unsafeAddrOrNil()),
    csize_t(val.len),
    cast[cstringArray](errors.addr),
  )
  bailOnErrors(errors)

  ok()

proc keyMayExist*(
    db: RocksDbRef, key: openArray[byte], cfHandle = db.defaultCfHandle
): RocksDBResult[bool] =
  ## If the key definitely does not exist in the database, then this method
  ## returns false, otherwise it returns true if the key might exist. That is
  ## to say that this method is probabilistic and may return false positives,
  ## but never a false negative. This check is potentially lighter-weight than
  ## invoking keyExists.

  let keyMayExist = rocksdb_key_may_exist_cf(
    db.cPtr,
    db.readOpts.cPtr,
    cfHandle.cPtr,
    cast[cstring](key.unsafeAddrOrNil()),
    csize_t(key.len),
    nil,
    nil,
    nil,
    0,
    nil,
  ).bool

  ok(keyMayExist)

proc keyExists*(
    db: RocksDbRef, key: openArray[byte], cfHandle = db.defaultCfHandle
): RocksDBResult[bool] =
  ## Check if the key exists in the specified column family.
  ## Returns a result containing `true` if the key exists or a result
  ## containing `false` otherwise.

  db.get(
    key,
    proc(data: openArray[byte]) =
      discard,
    cfHandle,
  )

proc delete*(
    db: RocksDbReadWriteRef, key: openArray[byte], cfHandle = db.defaultCfHandle
): RocksDBResult[void] =
  ## Delete the value for the given key from the specified column family.
  ## If the value does not exist, the delete will be a no-op.
  ## To check if the value exists before or after a delete, use `keyExists`.

  var errors: cstring
  rocksdb_delete_cf(
    db.cPtr,
    db.writeOpts.cPtr,
    cfHandle.cPtr,
    cast[cstring](key.unsafeAddrOrNil()),
    csize_t(key.len),
    cast[cstringArray](errors.addr),
  )
  bailOnErrors(errors)

  ok()

proc deleteRange*(
    db: RocksDbReadWriteRef,
    startKey, endKey: openArray[byte],
    cfHandle = db.defaultCfHandle,
): RocksDBResult[void] =
  ## Removes the database entries in the range [startKey, endKey), i.e. including
  ## startKey and excluding endKey. It is not an error if no keys exist in the
  ## range ["beginKey", "endKey").

  var errors: cstring
  rocksdb_delete_range_cf(
    db.cPtr,
    db.writeOpts.cPtr,
    cfHandle.cPtr,
    cast[cstring](startKey.unsafeAddrOrNil()),
    csize_t(startKey.len),
    cast[cstring](endKey.unsafeAddrOrNil()),
    csize_t(endKey.len),
    cast[cstringArray](errors.addr),
  )
  bailOnErrors(errors)

  ok()

proc compactRange*(
    db: RocksDbReadWriteRef,
    startKey, endKey: openArray[byte],
    cfHandle = db.defaultCfHandle,
): RocksDBResult[void] =
  ## Trigger range compaction for the given key range.

  rocksdb_compact_range_cf(
    db.cPtr,
    cfHandle.cPtr,
    cast[cstring](startKey.unsafeAddrOrNil()),
    csize_t(startKey.len),
    cast[cstring](endKey.unsafeAddrOrNil()),
    csize_t(endKey.len),
  )

  ok()

proc suggestCompactRange*(
    db: RocksDbReadWriteRef,
    startKey, endKey: openArray[byte],
    cfHandle = db.defaultCfHandle,
): RocksDBResult[void] =
  ## Suggest the range to compact.

  var errors: cstring
  rocksdb_suggest_compact_range_cf(
    db.cPtr,
    cfHandle.cPtr,
    cast[cstring](startKey.unsafeAddrOrNil()),
    csize_t(startKey.len),
    cast[cstring](endKey.unsafeAddrOrNil()),
    csize_t(endKey.len),
    cast[cstringArray](errors.addr),
  )
  bailOnErrors(errors)

  ok()

proc openIterator*(
    db: RocksDbRef,
    readOpts = defaultReadOptions(autoClose = true),
    cfHandle = db.defaultCfHandle,
): RocksDBResult[RocksIteratorRef] =
  ## Opens an `RocksIteratorRef` for the specified column family.
  ## The iterator should be closed using the `close` method after usage.
  doAssert not db.isClosed()

  let rocksIterPtr = rocksdb_create_iterator_cf(db.cPtr, readOpts.cPtr, cfHandle.cPtr)

  ok(newRocksIterator(rocksIterPtr, readOpts))

proc openWriteBatch*(
    db: RocksDbReadWriteRef, cfHandle = db.defaultCfHandle
): WriteBatchRef =
  ## Opens a `WriteBatchRef` which defaults to using the specified column family.
  ## The write batch should be closed using the `close` method after usage.
  doAssert not db.isClosed()

  createWriteBatch(cfHandle)

proc openWriteBatchWithIndex*(
    db: RocksDbReadWriteRef,
    reservedBytes = 0,
    overwriteKey = false,
    cfHandle = db.defaultCfHandle,
): WriteBatchWIRef =
  ## Opens a `WriteBatchWIRef` which defaults to using the specified column family.
  ## The write batch should be closed using the `close` method after usage.
  ## `WriteBatchWIRef` is similar to `WriteBatchRef` but with a binary searchable
  ## index built for all the keys inserted which allows reading the data which has
  ## been writen to the batch.
  ##
  ## Optionally set the number of bytes to be reserved for the batch by setting
  ## `reservedBytes`. Set `overwriteKey` to true to overwrite the key in the index
  ## when inserting a duplicate key, in this way an iterator will never show two
  ## entries with the same key.
  doAssert not db.isClosed()

  createWriteBatch(reservedBytes, overwriteKey, db.dbOpts, cfHandle)

proc write*(db: RocksDbReadWriteRef, updates: WriteBatchRef): RocksDBResult[void] =
  ## Apply the updates in the `WriteBatchRef` to the database.
  doAssert not db.isClosed()

  var errors: cstring
  rocksdb_write(
    db.cPtr, db.writeOpts.cPtr, updates.cPtr, cast[cstringArray](errors.addr)
  )
  bailOnErrors(errors)

  ok()

proc write*(db: RocksDbReadWriteRef, updates: WriteBatchWIRef): RocksDBResult[void] =
  ## Apply the updates in the `WriteBatchWIRef` to the database.
  doAssert not db.isClosed()

  var errors: cstring
  rocksdb_write_writebatch_wi(
    db.cPtr, db.writeOpts.cPtr, updates.cPtr, cast[cstringArray](errors.addr)
  )
  bailOnErrors(errors)

  ok()

proc ingestExternalFile*(
    db: RocksDbReadWriteRef, filePath: string, cfHandle = db.defaultCfHandle
): RocksDBResult[void] =
  ## Ingest an external sst file into the database. The file will be ingested
  ## into the specified column family or the default column family if none is
  ## provided.
  doAssert not db.isClosed()

  var
    sstPath = filePath.cstring
    errors: cstring
  rocksdb_ingest_external_file_cf(
    db.cPtr,
    cfHandle.cPtr,
    cast[cstringArray](sstPath.addr),
    csize_t(1),
    db.ingestOptsPtr,
    cast[cstringArray](errors.addr),
  )
  bailOnErrors(errors)

  ok()

proc getSnapshot*(db: RocksDbRef): RocksDBResult[SnapshotRef] =
  ## Return a handle to the current DB state. Iterators created with this handle
  ## will all observe a stable snapshot of the current DB state. The caller must
  ## call ReleaseSnapshot(result) when the snapshot is no longer needed.
  doAssert not db.isClosed()

  let sHandle = rocksdb_create_snapshot(db.cPtr)
  if sHandle.isNil():
    err("rocksdb: failed to create snapshot")
  else:
    ok(newSnapshot(sHandle, SnapshotType.rocksdb))

proc releaseSnapshot*(db: RocksDbRef, snapshot: SnapshotRef) =
  ## Release a previously acquired snapshot. The caller must not use "snapshot"
  ## after this call.
  doAssert not db.isClosed()
  doAssert snapshot.kind == SnapshotType.rocksdb

  if not snapshot.isClosed():
    rocksdb_release_snapshot(db.cPtr, snapshot.cPtr)
    snapshot.setClosed()

proc flush*(
    db: RocksDbReadWriteRef, cfHandle = db.defaultCfHandle
): RocksDBResult[void] =
  ## Flush all memory table data for the given column family.
  doAssert not db.isClosed()

  var errors: cstring
  rocksdb_flush_cf(
    db.cPtr, db.flushOptsPtr, cfHandle.cPtr, cast[cstringArray](errors.addr)
  )
  bailOnErrors(errors)

  ok()

proc flush*(
    db: RocksDbReadWriteRef, cfHandles: openArray[ColFamilyHandleRef]
): RocksDBResult[void] =
  ## Flush all memory table data for the given column families.
  doAssert not db.isClosed()

  var
    cfs = cfHandles.mapIt(it.cPtr)
    errors: cstring
  rocksdb_flush_cfs(
    db.cPtr,
    db.flushOptsPtr,
    addr cfs[0],
    cint(cfs.len),
    cast[cstringArray](errors.addr),
  )
  bailOnErrors(errors)

  ok()

proc close*(db: RocksDbRef) =
  ## Close the `RocksDbRef` which will release the connection to the database
  ## and free the memory associated with it. `close` is idempotent and can
  ## safely be called multple times. `close` is a no-op if the `RocksDbRef`
  ## is already closed.

  withLock(db.lock):
    if not db.isClosed():
      # the column families should be closed before the database
      db.cfTable.close()

      rocksdb_close(db.cPtr)
      db.cPtr = nil

      # opts should be closed after the database is closed
      autoCloseNonNil(db.dbOpts)
      autoCloseNonNil(db.readOpts)
      autoCloseAll(db.cfDescriptors)

      if db of RocksDbReadWriteRef:
        let db = RocksDbReadWriteRef(db)
        autoCloseNonNil(db.writeOpts)

        rocksdb_ingestexternalfileoptions_destroy(db.ingestOptsPtr)
        db.ingestOptsPtr = nil

        rocksdb_flushoptions_destroy(db.flushOptsPtr)
        db.flushOptsPtr = nil
