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
  ReadOptionsPtr = ptr rocksdb_readoptions_t

  ReadOptionsRef* = ref object
    readOptsPtr: ReadOptionsPtr

proc newReadOptions*(): ReadOptionsRef =
  ReadOptionsRef(readOptsPtr: rocksdb_readoptions_create())

template defaultReadOptions*(): ReadOptionsRef =
  newReadOptions()

template isClosed(readOpts: ReadOptionsRef): bool =
  readOpts.readOptsPtr.isNil()

# TODO: Add setters and getters for read options properties.
# Currently we are using the default settings.

proc close*(readOpts: var ReadOptionsRef) =
  if not readOpts.isClosed():
    rocksdb_readoptions_destroy(readOpts.readOptsPtr)
    readOpts.readOptsPtr = nil

