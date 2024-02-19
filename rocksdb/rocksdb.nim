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

export results

type
  RocksDBResult*[T] = Result[T, string]

  RocksDbPtr = ptr rocksdb_t
  RocksDbRef = ref object
    rocksDbPtr: RocksDbPtr
    path: string
    dbOpts: DbOptionsRef
    readOpts: ReadOptionsRef
    writeOpts: WriteOptionsRef
    cfTable: ColFamilyTableRef

  RocksDbReadWriteRef* = distinct RocksDbRef
  RocksDbReadOnlyRef* = distinct RocksDbRef

  DataProc* = proc(val: openArray[byte]) {.gcsafe, raises: [].}

template bailOnErrors(errors: cstring): auto =
  if not errors.isNil:
    let r = err($(errors))
    rocksdb_free(errors)
    return r

proc openDb[T](
    readOnly: bool,
    path: string,
    dbOpts: DbOptionsRef,
    readOpts: ReadOptionsRef,
    writeOpts: WriteOptionsRef,
    columnFamilies: openArray[ColFamilyDescriptor],
    errorIfWalFileExists: bool): RocksDBResult[T] =

  if columnFamilies.len == 0:
    return err("rocksdb: no column families")

  var
    cfNames = columnFamilies.mapIt(it.name().cstring)
    cfOpts = columnFamilies.mapIt(it.options.cPtr)
    columnFamilyHandles = newSeq[ColFamilyHandlePtr](columnFamilies.len)
    errors: cstring

  let rocksDbPtr = if readOnly:
    rocksdb_open_for_read_only_column_families(
        dbOpts.cPtr,
        path,
        cfNames.len().cint,
        cast[cstringArray](cfNames[0].addr),
        cfOpts[0].addr,
        columnFamilyHandles[0].addr,
        errorIfWalFileExists.uint8,
        cast[cstringArray](errors.addr))
  else:
    rocksdb_open_column_families(
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

  let db = RocksDbRef(
    rocksDbPtr: rocksDbPtr,
    path: path,
    dbOpts: dbOpts,
    readOpts: readOpts,
    writeOpts: writeOpts,
    cfTable: cfTable)
  ok(db.T)

proc openRocksDb*(
    path: string,
    dbOpts = defaultDbOptions(),
    readOpts = defaultReadOptions(),
    writeOpts = defaultWriteOptions(),
    columnFamilies = @[defaultColFamilyDescriptor()]): RocksDBResult[RocksDbReadWriteRef] =
  openDb[RocksDbReadWriteRef](
    false, path, dbOpts, readOpts, writeOpts, columnFamilies, false)

proc openRocksDbReadOnly*(
    path: string,
    dbOpts = defaultDbOptions(),
    readOpts = defaultReadOptions(),
    columnFamilies = @[defaultColFamilyDescriptor()],
    errorIfWalFileExists = false): RocksDBResult[RocksDbReadOnlyRef] =
  openDb[RocksDbReadOnlyRef](
    true, path, dbOpts, readOpts, nil, columnFamilies, errorIfWalFileExists)

proc get*(
    db: RocksDbReadWriteRef | RocksDbReadOnlyRef,
    key: openArray[byte],
    columnFamily = "default"): RocksDBResult[seq[byte]] =
  discard

proc get*(
    db: RocksDbReadWriteRef | RocksDbReadOnlyRef,
    key: openArray[byte],
    value: var openArray[byte],
    columnFamily = "default"): RocksDBResult[bool] =
  discard

proc get*(
    db: RocksDbReadWriteRef | RocksDbReadOnlyRef,
    key: openArray[byte],
    onData: DataProc,
    columnFamily = "default"): RocksDBResult[bool] =
  discard

proc put*(
    db: RocksDbReadWriteRef,
    key, val: openArray[byte],
    columnFamily = "default"): RocksDBResult[void] =
  discard

proc keyExists*(
    db: RocksDbReadWriteRef | RocksDbReadOnlyRef,
    key: openArray[byte],
    columnFamily = "default"): RocksDBResult[bool] =
  discard

proc delete*(
    db: RocksDbReadWriteRef,
    key: openArray[byte],
    columnFamily = "default"): RocksDBResult[void] =
  discard

proc backup*(
    db: RocksDbReadWriteRef | RocksDbReadOnlyRef): RocksDBResult[void] =
  discard

proc close*(db: RocksDbReadWriteRef | RocksDbReadOnlyRef) =
  discard