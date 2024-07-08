# Nim-RocksDB
# Copyright 2024 Status Research & Development GmbH
# Licensed under either of
#
#  * Apache License, version 2.0, ([LICENSE-APACHE](LICENSE-APACHE) or http://www.apache.org/licenses/LICENSE-2.0)
#  * GPL license, version 2.0, ([LICENSE-GPLv2](LICENSE-GPLv2) or https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)
#
# at your option. This file may not be copied, modified, or distributed except according to those terms.

## A `WriteBatchRef` holds a collection of updates to apply atomically to the database.
## It depends on resources from an instance of `RocksDbRef' and therefore should be used
## and closed before the `RocksDbRef` is closed.

{.push raises: [].}

import ./lib/librocksdb, ./internal/cftable, ./rocksresult

export rocksresult

type
  WriteBatchPtr* = ptr rocksdb_writebatch_t

  WriteBatchRef* = ref object
    cPtr: WriteBatchPtr
    defaultCfHandle: ColFamilyHandleRef

proc createWriteBatch*(defaultCfHandle: ColFamilyHandleRef): WriteBatchRef =
  WriteBatchRef(cPtr: rocksdb_writebatch_create(), defaultCfHandle: defaultCfHandle)

proc isClosed*(batch: WriteBatchRef): bool {.inline.} =
  ## Returns `true` if the `WriteBatchRef` has been closed and `false` otherwise.
  batch.cPtr.isNil()

proc cPtr*(batch: WriteBatchRef): WriteBatchPtr =
  ## Get the underlying database pointer.
  doAssert not batch.isClosed()
  batch.cPtr

proc clear*(batch: WriteBatchRef) =
  ## Clears the write batch.
  doAssert not batch.isClosed()
  rocksdb_writebatch_clear(batch.cPtr)

proc count*(batch: WriteBatchRef): int =
  ## Get the number of updates in the write batch.
  doAssert not batch.isClosed()
  rocksdb_writebatch_count(batch.cPtr).int

proc put*(
    batch: WriteBatchRef, key, val: openArray[byte], cfHandle = batch.defaultCfHandle
): RocksDBResult[void] =
  ## Add a put operation to the write batch.

  if key.len() == 0:
    return err("rocksdb: key is empty")

  rocksdb_writebatch_put_cf(
    batch.cPtr,
    cfHandle.cPtr,
    cast[cstring](unsafeAddr key[0]),
    csize_t(key.len),
    cast[cstring](if val.len > 0:
      unsafeAddr val[0]
    else:
      nil
    ),
    csize_t(val.len),
  )

  ok()

proc delete*(
    batch: WriteBatchRef, key: openArray[byte], cfHandle = batch.defaultCfHandle
): RocksDBResult[void] =
  ## Add a delete operation to the write batch.

  if key.len() == 0:
    return err("rocksdb: key is empty")

  rocksdb_writebatch_delete_cf(
    batch.cPtr, cfHandle.cPtr, cast[cstring](unsafeAddr key[0]), csize_t(key.len)
  )

  ok()

proc close*(batch: WriteBatchRef) =
  ## Close the `WriteBatchRef`.
  if not batch.isClosed():
    rocksdb_writebatch_destroy(batch.cPtr)
    batch.cPtr = nil
