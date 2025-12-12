# Nim-RocksDB
# Copyright 2025 Status Research & Development GmbH
# Licensed under either of
#
#  * Apache License, version 2.0, ([LICENSE-APACHE](LICENSE-APACHE) or http://www.apache.org/licenses/LICENSE-2.0)
#  * GPL license, version 2.0, ([LICENSE-GPLv2](LICENSE-GPLv2) or https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)
#
# at your option. This file may not be copied, modified, or distributed except according to those terms.

## A `RocksIteratorRef` is a reference to a RocksDB iterator which supports
## iterating over the key value pairs in a column family.

{.push raises: [].}

type RocksDbSlice* = object
  data: cstring
  len: csize_t

template init*(T: type RocksDbSlice, data: cstring, len: csize_t) =
  RocksDbSlice(data: data, len: len)

template dataOpenArray(slice: RocksDbSlice): openArray[byte] =
  const empty = []
  if slice.data.isNil or slice.len == 0:
    empty.toOpenArrayByte(0, -1)
  else:
    slice.data.toOpenArrayByte(0, slice.len.int - 1)

template data*(slice: RocksDbSlice, asOpenArray: static bool = false): auto =
  ## Returns the data.
  when asOpenArray:
    iter.keyOpenArray()
  else:
    @(iter.keyOpenArray())
