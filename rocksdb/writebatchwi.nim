# Nim-RocksDB
# Copyright 2024 Status Research & Development GmbH
# Licensed under either of
#
#  * Apache License, version 2.0, ([LICENSE-APACHE](LICENSE-APACHE) or http://www.apache.org/licenses/LICENSE-2.0)
#  * GPL license, version 2.0, ([LICENSE-GPLv2](LICENSE-GPLv2) or https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)
#
# at your option. This file may not be copied, modified, or distributed except according to those terms.

## A `WriteBatchWIRef` holds a collection of updates to apply atomically to the database.
## It depends on resources from an instance of `RocksDbRef' and therefore should be used
## and closed before the `RocksDbRef` is closed.
##
## `WriteBatchWIRef` is similar to `WriteBatchRef` but with a binary searchable index
## built for all the keys inserted which allows reading the data which has been writen
## to the batch.

{.push raises: [].}

import ./lib/librocksdb, ./internal/[cftable, utils], ./options/dbopts, ./rocksresult

export rocksresult

type
  WriteBatchWIPtr* = ptr rocksdb_writebatch_wi_t

  WriteBatchWIRef* = ref object
    cPtr: WriteBatchWIPtr
    dbOpts: DbOptionsRef
    defaultCfHandle: ColFamilyHandleRef

proc createWriteBatch*(
    reservedBytes: int,
    overwriteKey: bool,
    dbOpts: DbOptionsRef,
    defaultCfHandle: ColFamilyHandleRef,
): WriteBatchWIRef =
  WriteBatchWIRef(
    cPtr: rocksdb_writebatch_wi_create(reservedBytes.csize_t, overwriteKey.uint8),
    dbOpts: dbOpts,
    defaultCfHandle: defaultCfHandle,
  )

proc isClosed*(batch: WriteBatchWIRef): bool {.inline.} =
  ## Returns `true` if the `WriteBatchWIRef` has been closed and `false` otherwise.
  batch.cPtr.isNil()

proc cPtr*(batch: WriteBatchWIRef): WriteBatchWIPtr =
  ## Get the underlying write batch pointer.
  doAssert not batch.isClosed()
  batch.cPtr

proc clear*(batch: WriteBatchWIRef) =
  ## Clears the write batch.
  doAssert not batch.isClosed()
  rocksdb_writebatch_wi_clear(batch.cPtr)

proc count*(batch: WriteBatchWIRef): int =
  ## Get the number of updates in the write batch.
  doAssert not batch.isClosed()
  rocksdb_writebatch_wi_count(batch.cPtr).int

proc put*(
    batch: WriteBatchWIRef, key, val: openArray[byte], cfHandle = batch.defaultCfHandle
): RocksDBResult[void] =
  ## Add a put operation to the write batch.

  rocksdb_writebatch_wi_put_cf(
    batch.cPtr,
    cfHandle.cPtr,
    cast[cstring](key.unsafeAddrOrNil()),
    csize_t(key.len),
    cast[cstring](val.unsafeAddrOrNil()),
    csize_t(val.len),
  )

  ok()

proc delete*(
    batch: WriteBatchWIRef, key: openArray[byte], cfHandle = batch.defaultCfHandle
): RocksDBResult[void] =
  ## Add a delete operation to the write batch.

  rocksdb_writebatch_wi_delete_cf(
    batch.cPtr, cfHandle.cPtr, cast[cstring](key.unsafeAddrOrNil()), csize_t(key.len)
  )

  ok()

proc getFromBatch*(
    batch: WriteBatchWIRef,
    key: openArray[byte],
    onData: DataProc,
    cfHandle = batch.defaultCfHandle,
): RocksDBResult[bool] =
  ## Get the value for a given key from the batch using the provided
  ## `onData` callback.

  var
    len: csize_t
    errors: cstring
  let data = rocksdb_writebatch_wi_get_from_batch_cf(
    batch.cPtr,
    batch.dbOpts.cPtr,
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

proc getFromBatch*(
    batch: WriteBatchWIRef, key: openArray[byte], cfHandle = batch.defaultCfHandle
): RocksDBResult[seq[byte]] =
  ## Get the value for a given key from the batch.

  var dataRes: RocksDBResult[seq[byte]]
  proc onData(data: openArray[byte]) =
    dataRes.ok(@data)

  let res = batch.getFromBatch(key, onData, cfHandle)
  if res.isOk():
    return dataRes

  dataRes.err(res.error())

proc close*(batch: WriteBatchWIRef) =
  ## Close the `WriteBatchWIRef`.
  if not batch.isClosed():
    rocksdb_writebatch_wi_destroy(batch.cPtr)
    batch.cPtr = nil
