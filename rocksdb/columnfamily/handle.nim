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
  ./descriptor

type
  ColFamilyHandlePtr* = ptr rocksdb_column_family_handle_t

  ColFamilyHandleRef* = ref object
    handlePtr: ColFamilyHandlePtr

proc newColFamilyHandle*(handlePtr: ColFamilyHandlePtr): ColFamilyHandleRef =
  ColFamilyHandleRef(handlePtr: handlePtr)

template isClosed(handle: ColFamilyHandleRef): bool =
  handle.handlePtr.isNil()

proc getId*(handle: ColFamilyHandleRef): int =
  doAssert not handle.isClosed()
  rocksdb_column_family_handle_get_id(handle.handlePtr).int

proc getName*(handle: ColFamilyHandleRef): string =
  doAssert not handle.isClosed()
  var nameLen: csize_t # do we need to use this?
  $rocksdb_column_family_handle_get_name(handle.handlePtr, nameLen.addr)

proc isDefault*(handle: ColFamilyHandleRef): bool =
  handle.getName() == DEFAULT_COLUMN_FAMILY

# proc getDescriptor*(handle: ColFamilyHandleRef): ColumnFamilyDescriptor =
#   doAssert not handle.isClosed()

proc close*(handle: var ColFamilyHandleRef) =
  if not handle.isClosed():
    rocksdb_column_family_handle_destroy(handle.handlePtr)
    handle.handlePtr = nil