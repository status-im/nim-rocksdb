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
  ./lib/librocksdb,
  ./internal/[cftable, utils],
  ./rocksresult

export
  rocksresult

type
  WriteBatchPtr* = ptr rocksdb_writebatch_t

  WriteBatchRef* = ref object
    cPtr: WriteBatchPtr
    cfTable: ColFamilyTableRef

proc newWriteBatch*(cfTable: ColFamilyTableRef): WriteBatchRef =
  WriteBatchRef(
    cPtr: rocksdb_writebatch_create(),
    cfTable: cfTable)

template isClosed*(batch: WriteBatchRef): bool =
  batch.cPtr.isNil()

proc cPtr*(batch: WriteBatchRef): WriteBatchPtr =
  doAssert not batch.isClosed()
  batch.cPtr

proc clear*(batch: var WriteBatchRef) =
  doAssert not batch.isClosed()
  rocksdb_writebatch_clear(batch.cPtr)

proc count*(batch: WriteBatchRef): int =
  doAssert not batch.isClosed()
  rocksdb_writebatch_count(batch.cPtr).int

proc put*(
    batch: var WriteBatchRef,
    key, val: openArray[byte],
    columnFamily = DEFAULT_COLUMN_FAMILY_NAME): RocksDBResult[void] =

  if key.len() == 0:
    return err("rocksdb: key is empty")

  let cfHandle = batch.cfTable.get(columnFamily)
  if cfHandle.isNil:
    return err("rocksdb: unknown column family")

  rocksdb_writebatch_put_cf(
      batch.cPtr,
      cfHandle.cPtr,
      cast[cstring](unsafeAddr key[0]),
      csize_t(key.len),
      cast[cstring](if val.len > 0: unsafeAddr val[0] else: nil),
      csize_t(val.len))

  ok()

proc delete*(
    batch: var WriteBatchRef,
    key: openArray[byte],
    columnFamily = DEFAULT_COLUMN_FAMILY_NAME): RocksDBResult[void] =

  if key.len() == 0:
    return err("rocksdb: key is empty")

  let cfHandle = batch.cfTable.get(columnFamily)
  if cfHandle.isNil:
    return err("rocksdb: unknown column family")

  rocksdb_writebatch_delete_cf(
      batch.cPtr,
      cfHandle.cPtr,
      cast[cstring](unsafeAddr key[0]),
      csize_t(key.len))

  ok()

proc close*(batch: var WriteBatchRef) =
  if not batch.isClosed():
    rocksdb_writebatch_destroy(batch.cPtr)
    batch.cPtr = nil
