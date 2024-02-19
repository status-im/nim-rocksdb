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
  std/[tables, sequtils],
  results,
  ./lib/librocksdb,
  ./options/[dbopts, readopts, writeopts],
  ./columnfamily/[cfopts, cfdescriptor, cfhandle],
  ./internal/cftable

export
  results,
  dbopts,
  readopts,
  writeopts,
  cfdescriptor

type
  RocksDBResult*[T] = Result[T, string]

  RocksDbPtr = ptr rocksdb_t

  RocksDbRef* = ref object of RootObj
    cPtr: RocksDbPtr
    path: string
    dbOpts: DbOptionsRef
    readOpts: ReadOptionsRef
    cfTable: ColFamilyTableRef

  RocksDbReadOnlyRef* = ref object of RocksDbRef

  RocksDbReadWriteRef* = ref object of RocksDbRef
    writeOpts: WriteOptionsRef

  DataProc* = proc(val: openArray[byte]) {.gcsafe, raises: [].}

template bailOnErrors(errors: cstring): auto =
  if not errors.isNil:
    let res = err($(errors))
    rocksdb_free(errors)
    return res

# proc openDb[T](
#     readOnly: bool,
#     path: string,
#     dbOpts: DbOptionsRef,
#     readOpts: ReadOptionsRef,
#     writeOpts: WriteOptionsRef,
#     columnFamilies: openArray[ColFamilyDescriptor],
#     errorIfWalFileExists: bool): RocksDBResult[T] =

#   if columnFamilies.len == 0:
#     return err("rocksdb: no column families")

#   var
#     cfNames = columnFamilies.mapIt(it.name().cstring)
#     cfOpts = columnFamilies.mapIt(it.options.cPtr)
#     columnFamilyHandles = newSeq[ColFamilyHandlePtr](columnFamilies.len)
#     errors: cstring

#   let rocksDbPtr = if readOnly:
#     rocksdb_open_for_read_only_column_families(
#         dbOpts.cPtr,
#         path,
#         cfNames.len().cint,
#         cast[cstringArray](cfNames[0].addr),
#         cfOpts[0].addr,
#         columnFamilyHandles[0].addr,
#         errorIfWalFileExists.uint8,
#         cast[cstringArray](errors.addr))
#   else:
#     rocksdb_open_column_families(
#         dbOpts.cPtr,
#         path,
#         cfNames.len().cint,
#         cast[cstringArray](cfNames[0].addr),
#         cfOpts[0].addr,
#         columnFamilyHandles[0].addr,
#         cast[cstringArray](errors.addr))
#   bailOnErrors(errors)

#   var cfTable = newColFamilyTableRef()
#   for i, cf in columnFamilies:
#     cfTable.put(cf.name(), columnFamilyHandles[i])

#   let db = if readOnly:
#     RocksDbReadOnlyRef(
#       cPtr: rocksDbPtr,
#       path: path,
#       dbOpts: dbOpts,
#       readOpts: readOpts,
#       writeOpts: writeOpts,
#       cfTable: cfTable)
#   else:
#     RocksDbReadWriteRef(
#       cPtr: rocksDbPtr,
#       path: path,
#       dbOpts: dbOpts,
#       readOpts: readOpts,
#       writeOpts: writeOpts,
#       cfTable: cfTable)
#   ok(db)

proc openRocksDb*(
    path: string,
    dbOpts = defaultDbOptions(),
    readOpts = defaultReadOptions(),
    writeOpts = defaultWriteOptions(),
    columnFamilies = @[defaultColFamilyDescriptor()]): RocksDBResult[RocksDbReadWriteRef] =
  # openDb[RocksDbReadWriteRef](
  #   false, path, dbOpts, readOpts, writeOpts, columnFamilies, false)
  if columnFamilies.len == 0:
    return err("rocksdb: no column families")

  var
    cfNames = columnFamilies.mapIt(it.name().cstring)
    cfOpts = columnFamilies.mapIt(it.options.cPtr)
    columnFamilyHandles = newSeq[ColFamilyHandlePtr](columnFamilies.len)
    errors: cstring

  let rocksDbPtr = rocksdb_open_column_families(
        dbOpts.cPtr,
        path,
        cfNames.len().cint,
        cast[cstringArray](cfNames[0].addr),
        cfOpts[0].addr,
        columnFamilyHandles[0].addr,
        cast[cstringArray](errors.addr))
  bailOnErrors(errors)

  var cfTable = newColFamilyTableRef()
  for i, cf in columnFamilies:
    cfTable.put(cf.name(), columnFamilyHandles[i])

  let db = RocksDbReadWriteRef(
      cPtr: rocksDbPtr,
      path: path,
      dbOpts: dbOpts,
      readOpts: readOpts,
      writeOpts: writeOpts,
      cfTable: cfTable)
  ok(db)

proc openRocksDbReadOnly*(
    path: string,
    dbOpts = defaultDbOptions(),
    readOpts = defaultReadOptions(),
    columnFamilies = @[defaultColFamilyDescriptor()],
    errorIfWalFileExists = false): RocksDBResult[RocksDbReadOnlyRef] =
  # openDb[RocksDbReadOnlyRef](
  #   true, path, dbOpts, readOpts, nil, columnFamilies, errorIfWalFileExists)
  if columnFamilies.len == 0:
    return err("rocksdb: no column families")

  var
    cfNames = columnFamilies.mapIt(it.name().cstring)
    cfOpts = columnFamilies.mapIt(it.options.cPtr)
    columnFamilyHandles = newSeq[ColFamilyHandlePtr](columnFamilies.len)
    errors: cstring

  let rocksDbPtr = rocksdb_open_for_read_only_column_families(
        dbOpts.cPtr,
        path,
        cfNames.len().cint,
        cast[cstringArray](cfNames[0].addr),
        cfOpts[0].addr,
        columnFamilyHandles[0].addr,
        errorIfWalFileExists.uint8,
        cast[cstringArray](errors.addr))
  bailOnErrors(errors)

  var cfTable = newColFamilyTableRef()
  for i, cf in columnFamilies:
    cfTable.put(cf.name(), columnFamilyHandles[i])

  let db = RocksDbReadOnlyRef(
      cPtr: rocksDbPtr,
      path: path,
      dbOpts: dbOpts,
      readOpts: readOpts,
      cfTable: cfTable)
  ok(db)

template isClosed*(db: RocksDbRef): bool =
  db.cPtr.isNil()

proc get*(
    db: RocksDbRef,
    key: openArray[byte],
    onData: DataProc,
    columnFamily = "default"): RocksDBResult[bool] =

  if key.len() == 0:
    return err("rocksdb: key is empty")

  let cfHandle = db.cfTable.get(columnFamily)
  if cfHandle.isNil:
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

  if data.isNil:
    doAssert len == 0
    ok(false)
  else:
    onData(toOpenArrayByte(data, 0, len.int - 1))
    rocksdb_free(data)
    ok(true)

proc get*(
    db: RocksDbRef,
    key: openArray[byte],
    columnFamily = "default"): RocksDBResult[seq[byte]] =

  var dataRes: RocksDBResult[seq[byte]]
  proc onData(data: openArray[byte]) =
    dataRes.ok(@data)

  let res = db.get(key, onData, columnFamily)
  if res.isOk():
    return dataRes

  dataRes.err(res.error())

proc put*(
    db: RocksDbReadWriteRef,
    key, val: openArray[byte],
    columnFamily = "default"): RocksDBResult[void] =

  if key.len() == 0:
    return err("rocksdb: key is empty")

  let cfHandle = db.cfTable.get(columnFamily)
  if cfHandle.isNil():
    return err("rocksdb: unknown column family")

  var
    errors: cstring
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
    columnFamily = "default"): RocksDBResult[bool] =

  # TODO: Call rocksdb_key_may_exist_cf to improve performance for the case
  # when the key does not exist

  db.get(key, proc(data: openArray[byte]) = discard, columnFamily)


proc delete*(
    db: RocksDbReadWriteRef,
    key: openArray[byte],
    columnFamily = "default"): RocksDBResult[void] =

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

proc backup*(
    db: RocksDbRef): RocksDBResult[void] =
  discard

proc close*(db: RocksDbRef) =
  if not db.isClosed():
    db.dbOpts.close()
    db.readOpts.close()
    db.cfTable.close()

    if db of RocksDbReadWriteRef:
      db.RocksDbReadWriteRef.writeOpts.close()

    rocksdb_close(db.cPtr)
    db.cPtr = nil