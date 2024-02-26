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
  std/tables,
  ../columnfamily/cfhandle

export
  cfhandle

type
  ColFamilyTableRef* = ref object
    columnFamilies: TableRef[string, ColFamilyHandleRef]

proc newColFamilyTable*(): ColFamilyTableRef =
  ColFamilyTableRef(columnFamilies: newTable[string, ColFamilyHandleRef]())

template isClosed*(table: ColFamilyTableRef): bool =
  table.columnFamilies.isNil()

proc put*(
    table: var ColFamilyTableRef,
    name: string,
    handle: ColFamilyHandlePtr) =
  doAssert not table.isClosed()
  doAssert not handle.isNil()
  table.columnFamilies[name] = newColFamilyHandle(handle)

proc get*(table: ColFamilyTableRef, name: string): ColFamilyHandleRef =
  doAssert not table.isClosed()
  table.columnFamilies.getOrDefault(name)

proc close*(table: var ColFamilyTableRef) =
  if not table.isClosed():
    for _, v in table.columnFamilies.mpairs():
      v.close()
    table.columnFamilies = nil