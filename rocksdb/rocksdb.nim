# Nim-RocksDB
# Copyright 2024 Status Research & Development GmbH
# Licensed under either of
#
#  * Apache License, version 2.0, ([LICENSE-APACHE](LICENSE-APACHE) or http://www.apache.org/licenses/LICENSE-2.0)
#  * GPL license, version 2.0, ([LICENSE-GPLv2](LICENSE-GPLv2) or https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)
#
# at your option. This file may not be copied, modified, or distributed except according to those terms.

{.push raises: [].}

import
  std/sequtils,
  ./lib/librocksdb,
  ./options/[dbopts, readopts, writeopts],
  ./columnfamily/[cfopts, cfdescriptor, cfhandle],
  ./internal/[cftable, utils],
  ./rocksiterator,
  ./rocksresult,
  ./writebatch

export
  rocksresult,
  dbopts,
  readopts,
  writeopts,
  cfdescriptor,
  rocksiterator

type
  RocksDbPtr* = ptr rocksdb_t

  RocksDbRef* = ref object of RootObj
    cPtr: RocksDbPtr
    path: string
    dbOpts: DbOptionsRef
    readOpts: ReadOptionsRef
    cfTable: ColFamilyTableRef

  RocksDbReadOnlyRef* = ref object of RocksDbRef

  RocksDbReadWriteRef* = ref object of RocksDbRef
    writeOpts: WriteOptionsRef

proc openRocksDb*(
    path: string,
    dbOpts = defaultDbOptions(),
    readOpts = defaultReadOptions(),
    writeOpts = defaultWriteOptions(),
    columnFamilies = @[defaultColFamilyDescriptor()]): RocksDBResult[RocksDbReadWriteRef] =

  if columnFamilies.len == 0:
    return err("rocksdb: no column families")

  var
    cfNames = columnFamilies.mapIt(it.name().cstring)
    cfOpts = columnFamilies.mapIt(it.options.cPtr)
    columnFamilyHandles = newSeq[ColFamilyHandlePtr](columnFamilies.len)
    errors: cstring

  let rocksDbPtr = rocksdb_open_column_families(
        dbOpts.cPtr,
        path.cstring,
        cfNames.len().cint,
        cast[cstringArray](cfNames[0].addr),
        cfOpts[0].addr,
        columnFamilyHandles[0].addr,
        cast[cstringArray](errors.addr))
  bailOnErrors(errors)

  let db = RocksDbReadWriteRef(
      cPtr: rocksDbPtr,
      path: path,
      dbOpts: dbOpts,
      readOpts: readOpts,
      writeOpts: writeOpts,
      cfTable: newColFamilyTable(cfNames.mapIt($it), columnFamilyHandles))
  ok(db)

proc openRocksDbReadOnly*(
    path: string,
    dbOpts = defaultDbOptions(),
    readOpts = defaultReadOptions(),
    columnFamilies = @[defaultColFamilyDescriptor()],
    errorIfWalFileExists = false): RocksDBResult[RocksDbReadOnlyRef] =

  if columnFamilies.len == 0:
    return err("rocksdb: no column families")

  var
    cfNames = columnFamilies.mapIt(it.name().cstring)
    cfOpts = columnFamilies.mapIt(it.options.cPtr)
    columnFamilyHandles = newSeq[ColFamilyHandlePtr](columnFamilies.len)
    errors: cstring

  let rocksDbPtr = rocksdb_open_for_read_only_column_families(
        dbOpts.cPtr,
        path.cstring,
        cfNames.len().cint,
        cast[cstringArray](cfNames[0].addr),
        cfOpts[0].addr,
        columnFamilyHandles[0].addr,
        errorIfWalFileExists.uint8,
        cast[cstringArray](errors.addr))
  bailOnErrors(errors)

  let db = RocksDbReadOnlyRef(
      cPtr: rocksDbPtr,
      path: path,
      dbOpts: dbOpts,
      readOpts: readOpts,
      cfTable: newColFamilyTable(cfNames.mapIt($it), columnFamilyHandles))
  ok(db)

template isClosed*(db: RocksDbRef): bool =
  db.cPtr.isNil()

proc cPtr*(db: RocksDbRef): RocksDbPtr =
  doAssert not db.isClosed()
  db.cPtr

proc get*(
    db: RocksDbRef,
    key: openArray[byte],
    onData: DataProc,
    columnFamily = DEFAULT_COLUMN_FAMILY_NAME): RocksDBResult[bool] =

  if key.len() == 0:
    return err("rocksdb: key is empty")

  let cfHandle = db.cfTable.get(columnFamily)
  if cfHandle.isNil():
    return err("rocksdb: unknown column family")

  var
    len: csize_t
    errors: cstring
  let data = rocksdb_get_cf(
        db.cPtr,
        db.readOpts.cPtr,
        cfHandle.cPtr,
        cast[cstring](unsafeAddr key[0]),
        csize_t(key.len),
        len.addr,
        cast[cstringArray](errors.addr))
  bailOnErrors(errors)

  if data.isNil():
    doAssert len == 0
    ok(false)
  else:
    onData(toOpenArrayByte(data, 0, len.int - 1))
    rocksdb_free(data)
    ok(true)

proc get*(
    db: RocksDbRef,
    key: openArray[byte],
    columnFamily = DEFAULT_COLUMN_FAMILY_NAME): RocksDBResult[seq[byte]] =

  var dataRes: RocksDBResult[seq[byte]]
  proc onData(data: openArray[byte]) =
    dataRes.ok(@data)

  let res = db.get(key, onData, columnFamily)
  if res.isOk():
    return dataRes

  dataRes.err(res.error())

proc put*(
    db: var RocksDbReadWriteRef,
    key, val: openArray[byte],
    columnFamily = DEFAULT_COLUMN_FAMILY_NAME): RocksDBResult[void] =

  if key.len() == 0:
    return err("rocksdb: key is empty")

  let cfHandle = db.cfTable.get(columnFamily)
  if cfHandle.isNil():
    return err("rocksdb: unknown column family")

  var errors: cstring
  rocksdb_put_cf(
      db.cPtr,
      db.writeOpts.cPtr,
      cfHandle.cPtr,
      cast[cstring](unsafeAddr key[0]),
      csize_t(key.len),
      cast[cstring](if val.len > 0: unsafeAddr val[0] else: nil),
      csize_t(val.len),
      cast[cstringArray](errors.addr))
  bailOnErrors(errors)

  ok()

proc keyExists*(
    db: RocksDbRef,
    key: openArray[byte],
    columnFamily = DEFAULT_COLUMN_FAMILY_NAME): RocksDBResult[bool] =

  # TODO: Call rocksdb_key_may_exist_cf to improve performance for the case
  # when the key does not exist

  db.get(key, proc(data: openArray[byte]) = discard, columnFamily)

proc delete*(
    db: var RocksDbReadWriteRef,
    key: openArray[byte],
    columnFamily = DEFAULT_COLUMN_FAMILY_NAME): RocksDBResult[void] =

  if key.len() == 0:
    return err("rocksdb: key is empty")

  let cfHandle = db.cfTable.get(columnFamily)
  if cfHandle.isNil:
    return err("rocksdb: unknown column family")

  var errors: cstring
  rocksdb_delete_cf(
      db.cPtr,
      db.writeOpts.cPtr,
      cfHandle.cPtr,
      cast[cstring](unsafeAddr key[0]),
      csize_t(key.len),
      cast[cstringArray](errors.addr))
  bailOnErrors(errors)

  ok()

proc openIterator*(
    db: RocksDbRef,
    columnFamily = DEFAULT_COLUMN_FAMILY_NAME): RocksDBResult[RocksIteratorRef] =
  doAssert not db.isClosed()

  let cfHandle  = db.cfTable.get(columnFamily)
  if cfHandle.isNil():
    return err("rocksdb: unknown column family")

  let rocksIterPtr = rocksdb_create_iterator_cf(
        db.cPtr,
        db.readOpts.cPtr,
        cfHandle.cPtr)

  ok(newRocksIterator(rocksIterPtr))

proc openWriteBatch*(db: RocksDbReadWriteRef): WriteBatchRef =
  doAssert not db.isClosed()
  newWriteBatch(db.cfTable)

proc write*(db: var RocksDbReadWriteRef, updates: WriteBatchRef): RocksDBResult[void] =
  doAssert not db.isClosed()

  var errors: cstring
  rocksdb_write(
      db.cPtr,
      db.writeOpts.cPtr,
      updates.cPtr,
      cast[cstringArray](errors.addr))
  bailOnErrors(errors)

  ok()

proc close*(db: RocksDbRef) =
  if not db.isClosed():
    db.dbOpts.close()
    db.readOpts.close()
    db.cfTable.close()

    if db of RocksDbReadWriteRef:
      db.RocksDbReadWriteRef.writeOpts.close()

    rocksdb_close(db.cPtr)
    db.cPtr = nil