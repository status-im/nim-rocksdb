# Nim-RocksDB
# Copyright 2024 Status Research & Development GmbH
# Licensed under either of
#
#  * Apache License, version 2.0, ([LICENSE-APACHE](LICENSE-APACHE) or http://www.apache.org/licenses/LICENSE-2.0)
#  * GPL license, version 2.0, ([LICENSE-GPLv2](LICENSE-GPLv2) or https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)
#
# at your option. This file may not be copied, modified, or distributed except according to those terms.

## To use transactions, you must first create a `TransactionDbRef`. Then to
## create a transaction call `beginTransaction` on the `TransactionDbRef`.
## `commit` and `rollback` are used to commit or rollback a transaction.
## The `TransactionDbRef` currently supports `put`, `delete` and `get` operations.
## Keys that have been writen to a transaction but are not yet committed can be
## read from the transaction using `get`. Uncommitted updates will not be visible
## to other transactions until they are committed to the database.
## Multiple column families can be written to and read from in a single transaction
## but a default column family will be used if none is specified in each call.

{.push raises: [].}

import
  ../lib/librocksdb,
  ../options/[readopts, writeopts],
  ../internal/[cftable, utils],
  ../[rocksiterator, rocksresult],
  ./[txopts, otxopts]

export rocksiterator, rocksresult

type
  TransactionPtr* = ptr rocksdb_transaction_t

  TransactionRef* = ref object
    cPtr: TransactionPtr
    readOpts: ReadOptionsRef
    writeOpts: WriteOptionsRef
    txOpts: TransactionOptionsRef
    otxOpts: OptimisticTxOptionsRef
    defaultCfHandle: ColFamilyHandleRef

proc newTransaction*(
    cPtr: TransactionPtr,
    readOpts: ReadOptionsRef,
    writeOpts: WriteOptionsRef,
    txOpts: TransactionOptionsRef,
    otxOpts: OptimisticTxOptionsRef,
    defaultCfHandle: ColFamilyHandleRef,
): TransactionRef =
  TransactionRef(
    cPtr: cPtr,
    readOpts: readOpts,
    writeOpts: writeOpts,
    txOpts: txOpts,
    otxOpts: otxOpts,
    defaultCfHandle: defaultCfHandle,
  )

proc isClosed*(tx: TransactionRef): bool {.inline.} =
  ## Returns `true` if the `TransactionRef` has been closed.
  tx.cPtr.isNil()

proc get*(
    tx: TransactionRef,
    key: openArray[byte],
    onData: DataProc,
    cfHandle = tx.defaultCfHandle,
): RocksDBResult[bool] =
  ## Get the value for a given key from the transaction using the provided
  ## `onData` callback.

  var
    len: csize_t
    errors: cstring
  let data = rocksdb_transaction_get_cf(
    tx.cPtr,
    tx.readOpts.cPtr,
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
    tx: TransactionRef, key: openArray[byte], cfHandle = tx.defaultCfHandle
): RocksDBResult[seq[byte]] =
  ## Get the value for a given key from the transaction.

  var dataRes: RocksDBResult[seq[byte]]
  proc onData(data: openArray[byte]) =
    dataRes.ok(@data)

  let res = tx.get(key, onData, cfHandle)
  if res.isOk():
    return dataRes

  dataRes.err(res.error())

proc put*(
    tx: TransactionRef, key, val: openArray[byte], cfHandle = tx.defaultCfHandle
): RocksDBResult[void] =
  ## Put the value for the given key into the transaction.

  var errors: cstring
  rocksdb_transaction_put_cf(
    tx.cPtr,
    cfHandle.cPtr,
    cast[cstring](key.unsafeAddrOrNil()),
    csize_t(key.len),
    cast[cstring](val.unsafeAddrOrNil()),
    csize_t(val.len),
    cast[cstringArray](errors.addr),
  )
  bailOnErrors(errors)

  ok()

proc delete*(
    tx: TransactionRef, key: openArray[byte], cfHandle = tx.defaultCfHandle
): RocksDBResult[void] =
  ## Delete the value for the given key from the transaction.

  var errors: cstring
  rocksdb_transaction_delete_cf(
    tx.cPtr,
    cfHandle.cPtr,
    cast[cstring](key.unsafeAddrOrNil()),
    csize_t(key.len),
    cast[cstringArray](errors.addr),
  )
  bailOnErrors(errors)

  ok()

proc commit*(tx: TransactionRef): RocksDBResult[void] =
  ## Commit the transaction.
  doAssert not tx.isClosed()

  var errors: cstring
  rocksdb_transaction_commit(tx.cPtr, cast[cstringArray](errors.addr))
  bailOnErrors(errors)

  ok()

proc rollback*(tx: TransactionRef): RocksDBResult[void] =
  ## Rollback the transaction.
  doAssert not tx.isClosed()

  var errors: cstring
  rocksdb_transaction_rollback(tx.cPtr, cast[cstringArray](errors.addr))
  bailOnErrors(errors)

  ok()

proc openIterator*(
    db: TransactionRef,
    readOpts = defaultReadOptions(autoClose = true),
    cfHandle = db.defaultCfHandle,
): RocksDBResult[RocksIteratorRef] =
  ## Opens an `RocksIteratorRef` for the specified column family.
  ## The iterator should be closed using the `close` method after usage.
  doAssert not db.isClosed()

  let rocksIterPtr =
    rocksdb_transaction_create_iterator_cf(db.cPtr, readOpts.cPtr, cfHandle.cPtr)

  ok(newRocksIterator(rocksIterPtr, readOpts))

proc close*(tx: TransactionRef) =
  ## Close the `TransactionRef`.
  if not tx.isClosed():
    rocksdb_transaction_destroy(tx.cPtr)
    tx.cPtr = nil

    # opts should be closed after the transaction is closed
    autoCloseNonNil(tx.readOpts)
    autoCloseNonNil(tx.writeOpts)
    autoCloseNonNil(tx.txOpts)
    autoCloseNonNil(tx.otxOpts)
