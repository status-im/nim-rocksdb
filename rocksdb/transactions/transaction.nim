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
  ../lib/librocksdb,
  ../options/[dbopts, readopts, writeopts],
  ../columnfamily/[cfopts, cfdescriptor, cfhandle],
  ../internal/[cftable, utils],
  ../rocksresult,
  ./txopts

export
  rocksresult

type
  TransactionPtr* = ptr rocksdb_transaction_t

  TransactionRef* = ref object
    cPtr: TransactionPtr
    readOpts: ReadOptionsRef
    writeOpts: WriteOptionsRef
    txOpts: TransactionOptionsRef
    defaultCfName: string
    cfTable: ColFamilyTableRef

proc newTransaction*(
    cPtr: TransactionPtr,
    readOpts: ReadOptionsRef,
    writeOpts: WriteOptionsRef,
    txOpts: TransactionOptionsRef,
    defaultCfName: string,
    cfTable: ColFamilyTableRef): TransactionRef =

  TransactionRef(
      cPtr: cPtr,
      readOpts: readOpts,
      writeOpts: writeOpts,
      txOpts: txOpts,
      defaultCfName: defaultCfName,
      cfTable: cfTable)

template isClosed*(tx: TransactionRef): bool =
  tx.cPtr.isNil()

proc withDefaultColFamily*(tx: var TransactionRef, name: string): TransactionRef =
  tx.defaultCfName = name
  tx

proc defaultColFamily*(tx: TransactionRef): string =
  tx.defaultCfName

proc get*(
    tx: TransactionRef,
    key: openArray[byte],
    onData: DataProc,
    columnFamily = tx.defaultCfName): RocksDBResult[bool] =

  if key.len() == 0:
    return err("rocksdb: key is empty")

  let cfHandle = tx.cfTable.get(columnFamily)
  if cfHandle.isNil():
    return err("rocksdb: unknown column family")

  var
    len: csize_t
    errors: cstring
  let data = rocksdb_transaction_get_cf(
        tx.cPtr,
        tx.readOpts.cPtr,
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
    tx: TransactionRef,
    key: openArray[byte],
    columnFamily = tx.defaultCfName): RocksDBResult[seq[byte]] =

  var dataRes: RocksDBResult[seq[byte]]
  proc onData(data: openArray[byte]) =
    dataRes.ok(@data)

  let res = tx.get(key, onData, columnFamily)
  if res.isOk():
    return dataRes

  dataRes.err(res.error())

proc put*(
    tx: var TransactionRef,
    key, val: openArray[byte],
    columnFamily = tx.defaultCfName): RocksDBResult[void] =

  if key.len() == 0:
    return err("rocksdb: key is empty")

  let cfHandle = tx.cfTable.get(columnFamily)
  if cfHandle.isNil():
    return err("rocksdb: unknown column family")

  var errors: cstring
  rocksdb_transaction_put_cf(
      tx.cPtr,
      cfHandle.cPtr,
      cast[cstring](unsafeAddr key[0]),
      csize_t(key.len),
      cast[cstring](if val.len > 0: unsafeAddr val[0] else: nil),
      csize_t(val.len),
      cast[cstringArray](errors.addr))
  bailOnErrors(errors)

  ok()

proc delete*(
    tx: var TransactionRef,
    key: openArray[byte],
    columnFamily = tx.defaultCfName): RocksDBResult[void] =

  if key.len() == 0:
    return err("rocksdb: key is empty")

  let cfHandle = tx.cfTable.get(columnFamily)
  if cfHandle.isNil:
    return err("rocksdb: unknown column family")

  var errors: cstring
  rocksdb_transaction_delete_cf(
      tx.cPtr,
      cfHandle.cPtr,
      cast[cstring](unsafeAddr key[0]),
      csize_t(key.len),
      cast[cstringArray](errors.addr))
  bailOnErrors(errors)

  ok()

proc commit*(tx: var TransactionRef): RocksDBResult[void] =
  doAssert not tx.isClosed()

  var errors: cstring
  rocksdb_transaction_commit(tx.cPtr, cast[cstringArray](errors.addr))
  bailOnErrors(errors)

  ok()

proc rollback*(tx: var TransactionRef): RocksDBResult[void] =
  doAssert not tx.isClosed()

  var errors: cstring
  rocksdb_transaction_rollback(tx.cPtr, cast[cstringArray](errors.addr))
  bailOnErrors(errors)

  ok()

proc close*(tx: var TransactionRef) =
  if not tx.isClosed():
    tx.readOpts.close()
    tx.writeOpts.close()
    tx.txOpts.close()

    rocksdb_transaction_destroy(tx.cPtr)
    tx.cPtr = nil