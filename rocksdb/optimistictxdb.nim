# Nim-RocksDB
# Copyright 2024 Status Research & Development GmbH
# Licensed under either of
#
#  * Apache License, version 2.0, ([LICENSE-APACHE](LICENSE-APACHE) or http://www.apache.org/licenses/LICENSE-2.0)
#  * GPL license, version 2.0, ([LICENSE-GPLv2](LICENSE-GPLv2) or https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)
#
# at your option. This file may not be copied, modified, or distributed except according to those terms.

## A `OptimisticTxDbRef` can be used to open a connection to the RocksDB database
## with support for transactional operations against multiple column families.
## To create a new transaction call `beginTransaction` which will return a
## `TransactionRef`. To commit or rollback the transaction call `commit` or
## `rollback` on the `TransactionRef` type after applying changes to the transaction.

{.push raises: [].}

import
  std/[sequtils, locks],
  ./lib/librocksdb,
  ./options/[dbopts, readopts, writeopts],
  ./transactions/[transaction, otxopts],
  ./columnfamily/[cfopts, cfdescriptor, cfhandle],
  ./internal/[cftable, utils],
  ./rocksresult

export dbopts, cfdescriptor, readopts, writeopts, otxopts, transaction, rocksresult

type
  OptimisticTxDbPtr* = ptr rocksdb_optimistictransactiondb_t

  OptimisticTxDbRef* = ref object
    lock: Lock
    cPtr: OptimisticTxDbPtr
    path: string
    dbOpts: DbOptionsRef
    cfDescriptors: seq[ColFamilyDescriptor]
    defaultCfHandle: ColFamilyHandleRef
    cfTable: ColFamilyTableRef

proc openOptimisticTxDb*(
    path: string,
    dbOpts = defaultDbOptions(autoClose = true),
    columnFamilies: openArray[ColFamilyDescriptor] = [],
): RocksDBResult[OptimisticTxDbRef] =
  ## Open a `OptimisticTxDbRef` with the given options and column families.
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

  let txDbPtr = rocksdb_optimistictransactiondb_open_column_families(
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
    autoCloseAll(cfs)

  let
    cfTable = newColFamilyTable(cfNames.mapIt($it), cfHandles)
    db = OptimisticTxDbRef(
      lock: createLock(),
      cPtr: txDbPtr,
      path: path,
      dbOpts: dbOpts,
      cfDescriptors: cfs,
      defaultCfHandle: cfTable.get(DEFAULT_COLUMN_FAMILY_NAME),
      cfTable: cfTable,
    )
  ok(db)

proc getColFamilyHandle*(
    db: OptimisticTxDbRef, name: string
): RocksDBResult[ColFamilyHandleRef] =
  let cfHandle = db.cfTable.get(name)
  if cfHandle.isNil():
    err("rocksdb: unknown column family")
  else:
    ok(cfHandle)

proc isClosed*(db: OptimisticTxDbRef): bool {.inline.} =
  ## Returns `true` if the `OptimisticTxDbRef` has been closed.
  db.cPtr.isNil()

proc beginTransaction*(
    db: OptimisticTxDbRef,
    readOpts = defaultReadOptions(autoClose = true),
    writeOpts = defaultWriteOptions(autoClose = true),
    otxOpts = defaultOptimisticTxOptions(autoClose = true),
    cfHandle = db.defaultCfHandle,
): TransactionRef =
  ## Begin a new transaction against the database. The transaction will default
  ## to using the specified column family. If no column family is specified
  ## then the default column family will be used.
  doAssert not db.isClosed()

  let txPtr =
    rocksdb_optimistictransaction_begin(db.cPtr, writeOpts.cPtr, otxOpts.cPtr, nil)

  newTransaction(txPtr, readOpts, writeOpts, nil, otxOpts, cfHandle)

proc close*(db: OptimisticTxDbRef) =
  ## Close the `OptimisticTxDbRef`.

  withLock(db.lock):
    if not db.isClosed():
      # the column families should be closed before the database
      db.cfTable.close()

      rocksdb_optimistictransactiondb_close(db.cPtr)
      db.cPtr = nil

      # opts should be closed after the database is closed
      autoCloseNonNil(db.dbOpts)
      autoCloseAll(db.cfDescriptors)
