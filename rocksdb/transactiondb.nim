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
  ./transactions/[transaction, txdbopts, txopts],
  ./columnfamily/[cfopts, cfdescriptor, cfhandle],
  ./internal/[cftable, utils],
  ./rocksresult

export
  dbopts,
  txdbopts,
  cfdescriptor,
  readopts,
  writeopts,
  txopts,
  transaction,
  rocksresult

type
  TransactionDbPtr* = ptr rocksdb_transactiondb_t

  TransactionDbRef* = ref object
    cPtr: TransactionDbPtr
    path: string
    dbOpts: DbOptionsRef
    txDbOpts: TransactionDbOptionsRef
    cfTable: ColFamilyTableRef

proc openTransactionDb*(
    path: string,
    dbOpts = defaultDbOptions(),
    txDbOpts = defaultTransactionDbOptions(),
    columnFamilies = @[defaultColFamilyDescriptor()]): RocksDBResult[TransactionDbRef] =

  if columnFamilies.len == 0:
    return err("rocksdb: no column families")

  var
    cfNames = columnFamilies.mapIt(it.name().cstring)
    cfOpts = columnFamilies.mapIt(it.options.cPtr)
    columnFamilyHandles = newSeq[ColFamilyHandlePtr](columnFamilies.len)
    errors: cstring

  let txDbPtr = rocksdb_transactiondb_open_column_families(
        dbOpts.cPtr,
        txDbOpts.cPtr,
        path.cstring,
        cfNames.len().cint,
        cast[cstringArray](cfNames[0].addr),
        cfOpts[0].addr,
        columnFamilyHandles[0].addr,
        cast[cstringArray](errors.addr))
  bailOnErrors(errors)

  let db = TransactionDbRef(
      cPtr: txDbPtr,
      path: path,
      dbOpts: dbOpts,
      txDbOpts: txDbOpts,
      cfTable: newColFamilyTable(cfNames.mapIt($it), columnFamilyHandles))
  ok(db)

template isClosed*(db: TransactionDbRef): bool =
  db.cPtr.isNil()

proc beginTransaction*(
    db: TransactionDbRef,
    readOpts = defaultReadOptions(),
    writeOpts = defaultWriteOptions(),
    txOpts = defaultTransactionOptions(),
    columnFamily = DEFAULT_COLUMN_FAMILY_NAME): TransactionRef =
  doAssert not db.isClosed()

  let txPtr = rocksdb_transaction_begin(
        db.cPtr,
        writeOpts.cPtr,
        txOpts.cPtr,
        nil)

  newTransaction(txPtr, readOpts, writeOpts, txOpts, columnFamily, db.cfTable)

proc close*(db: TransactionDbRef) =
  if not db.isClosed():
    db.dbOpts.close()
    db.txDbOpts.close()
    db.cfTable.close()

    rocksdb_transactiondb_close(db.cPtr)
    db.cPtr = nil
