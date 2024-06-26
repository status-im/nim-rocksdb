# Nim-RocksDB
# Copyright 2024 Status Research & Development GmbH
# Licensed under either of
#
#  * Apache License, version 2.0, ([LICENSE-APACHE](LICENSE-APACHE) or http://www.apache.org/licenses/LICENSE-2.0)
#  * GPL license, version 2.0, ([LICENSE-GPLv2](LICENSE-GPLv2) or https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)
#
# at your option. This file may not be copied, modified, or distributed except according to those terms.

{.push raises: [].}

import ../lib/librocksdb

type
  ColFamilyHandlePtr* = ptr rocksdb_column_family_handle_t

  ColFamilyHandleRef* = ref object
    cPtr: ColFamilyHandlePtr

proc newColFamilyHandle*(cPtr: ColFamilyHandlePtr): ColFamilyHandleRef =
  ColFamilyHandleRef(cPtr: cPtr)

proc isClosed*(handle: ColFamilyHandleRef): bool {.inline.} =
  handle.cPtr.isNil()

proc cPtr*(handle: ColFamilyHandleRef): ColFamilyHandlePtr =
  doAssert not handle.isClosed()
  handle.cPtr

proc close*(handle: ColFamilyHandleRef) =
  if not handle.isClosed():
    rocksdb_column_family_handle_destroy(handle.cPtr)
    handle.cPtr = nil
