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
  ../lib/librocksdb

type
  WriteOptionsPtr = ptr rocksdb_writeoptions_t

  WriteOptionsRef* = ref object
    writeOptsPtr: WriteOptionsPtr

proc newWriteOptions*(): WriteOptionsRef =
  WriteOptionsRef(writeOptsPtr: rocksdb_writeoptions_create())

template defaultWriteOptions*(): WriteOptionsRef =
  newWriteOptions()

template isClosed(writeOpts: WriteOptionsRef): bool =
  writeOpts.writeOptsPtr.isNil()

# TODO: Add setters and getters for write options properties.
# Currently we are using the default settings.

proc close*(writeOpts: var WriteOptionsRef) =
  if not writeOpts.isClosed():
    rocksdb_writeoptions_destroy(writeOpts.writeOptsPtr)
    writeOpts.writeOptsPtr = nil

