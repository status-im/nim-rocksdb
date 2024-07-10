# Nim-RocksDB
# Copyright 2024 Status Research & Development GmbH
# Licensed under either of
#
#  * Apache License, version 2.0, ([LICENSE-APACHE](LICENSE-APACHE) or http://www.apache.org/licenses/LICENSE-2.0)
#  * GPL license, version 2.0, ([LICENSE-GPLv2](LICENSE-GPLv2) or https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)
#
# at your option. This file may not be copied, modified, or distributed except according to those terms.

## A `TransactionDbRef` can be used to open a connection to the RocksDB database
## with support for transactional operations against multiple column families.
## To create a new transaction call `beginTransaction` which will return a
## `TransactionRef`. To commit or rollback the transaction call `commit` or
## `rollback` on the `TransactionRef` type after applying changes to the transaction.

{.push raises: [].}

import
  std/[sequtils, locks],
  ./lib/librocksdb,
  ./options/[dbopts, readopts, writeopts],
  ./transactions/[transaction, txdbopts, txopts],
  ./columnfamily/[cfopts, cfdescriptor, cfhandle],
  ./internal/[cftable, utils],
  ./[rocksiterator, rocksresult, snapshot]

export
  dbopts, txdbopts, cfdescriptor, readopts, writeopts, txopts, transaction,
  rocksiterator, rocksresult, snapshot.SnapshotRef, snapshot.isClosed,
  snapshot.getSequenceNumber

type
  TransactionDbPtr* = ptr rocksdb_transactiondb_t

  TransactionDbRef* = ref object
    lock: Lock
    cPtr: TransactionDbPtr
    path: string
    dbOpts: DbOptionsRef
    txDbOpts: TransactionDbOptionsRef
    cfDescriptors: seq[ColFamilyDescriptor]
    defaultCfHandle: ColFamilyHandleRef
    cfTable: ColFamilyTableRef

proc openTransactionDb*(
    path: string,
    dbOpts = defaultDbOptions(autoClose = true),
    txDbOpts = defaultTransactionDbOptions(autoClose = true),
    columnFamilies: openArray[ColFamilyDescriptor] = [],
): RocksDBResult[TransactionDbRef] =
  ## Open a `TransactionDbRef` with the given options and column families.
  ## If no column families are provided the default column family will be used.
  ## If no options are provided the default options will be used.
  ## These default options will be closed when the database is closed.
  ## If any options are provided, they will need to be closed manually.

  var cfs = columnFamilies.toSeq()
  if DEFAULT_COLUMN_FAMILY_NAME notin columnFamilies.mapIt(it.name()):
    cfs.add(defaultColFamilyDescriptor(autoClose = true))

  var
    cfNames = cfs.mapIt(it.name().cstring)
    cfOpts = cfs.mapIt(it.options.cPtr)
    cfHandles = newSeq[ColFamilyHandlePtr](cfs.len)
    errors: cstring

  let txDbPtr = rocksdb_transactiondb_open_column_families(
    dbOpts.cPtr,
    txDbOpts.cPtr,
    path.cstring,
    cfNames.len().cint,
    cast[cstringArray](cfNames[0].addr),
    cfOpts[0].addr,
    cfHandles[0].addr,
    cast[cstringArray](errors.addr),
  )
  bailOnErrorsWithCleanup(errors):
    autoCloseNonNil(dbOpts)
    autoCloseNonNil(txDbOpts)
    autoCloseAll(cfs)

  let
    cfTable = newColFamilyTable(cfNames.mapIt($it), cfHandles)
    db = TransactionDbRef(
      lock: createLock(),
      cPtr: txDbPtr,
      path: path,
      dbOpts: dbOpts,
      txDbOpts: txDbOpts,
      cfDescriptors: cfs,
      defaultCfHandle: cfTable.get(DEFAULT_COLUMN_FAMILY_NAME),
      cfTable: cfTable,
    )
  ok(db)

proc getColFamilyHandle*(
    db: TransactionDbRef, name: string
): RocksDBResult[ColFamilyHandleRef] =
  let cfHandle = db.cfTable.get(name)
  if cfHandle.isNil():
    err("rocksdb: unknown column family")
  else:
    ok(cfHandle)

proc isClosed*(db: TransactionDbRef): bool {.inline.} =
  ## Returns `true` if the `TransactionDbRef` has been closed.
  db.cPtr.isNil()

proc beginTransaction*(
    db: TransactionDbRef,
    readOpts = defaultReadOptions(autoClose = true),
    writeOpts = defaultWriteOptions(autoClose = true),
    txOpts = defaultTransactionOptions(autoClose = true),
    cfHandle = db.defaultCfHandle,
): TransactionRef =
  ## Begin a new transaction against the database. The transaction will default
  ## to using the specified column family. If no column family is specified
  ## then the default column family will be used.
  doAssert not db.isClosed()

  let txPtr = rocksdb_transaction_begin(db.cPtr, writeOpts.cPtr, txOpts.cPtr, nil)

  newTransaction(txPtr, readOpts, writeOpts, txOpts, nil, cfHandle)

proc openIterator*(
    db: TransactionDbRef,
    readOpts = defaultReadOptions(autoClose = true),
    cfHandle = db.defaultCfHandle,
): RocksDBResult[RocksIteratorRef] =
  ## Opens an `RocksIteratorRef` for the specified column family.
  ## The iterator should be closed using the `close` method after usage.
  doAssert not db.isClosed()

  let rocksIterPtr =
    rocksdb_transactiondb_create_iterator_cf(db.cPtr, readOpts.cPtr, cfHandle.cPtr)

  ok(newRocksIterator(rocksIterPtr, readOpts))

proc getSnapshot*(db: TransactionDbRef): RocksDBResult[SnapshotRef] =
  ## Return a handle to the current DB state. Iterators created with this handle
  ## will all observe a stable snapshot of the current DB state. The caller must
  ## call ReleaseSnapshot(result) when the snapshot is no longer needed.
  doAssert not db.isClosed()

  let sHandle = rocksdb_transactiondb_create_snapshot(db.cPtr)
  if sHandle.isNil():
    err("rocksdb: failed to create snapshot")
  else:
    ok(newSnapshot(sHandle, SnapshotType.transactiondb))

proc releaseSnapshot*(db: TransactionDbRef, snapshot: SnapshotRef) =
  ## Release a previously acquired snapshot. The caller must not use "snapshot"
  ## after this call.
  doAssert not db.isClosed()
  doAssert snapshot.kind == SnapshotType.transactiondb

  if not snapshot.isClosed():
    rocksdb_transactiondb_release_snapshot(db.cPtr, snapshot.cPtr)
    snapshot.setClosed()

proc close*(db: TransactionDbRef) =
  ## Close the `TransactionDbRef`.

  withLock(db.lock):
    if not db.isClosed():
      # the column families should be closed before the database
      db.cfTable.close()

      rocksdb_transactiondb_close(db.cPtr)
      db.cPtr = nil

      # opts should be closed after the database is closed
      autoCloseNonNil(db.dbOpts)
      autoCloseNonNil(db.txDbOpts)
      autoCloseAll(db.cfDescriptors)
