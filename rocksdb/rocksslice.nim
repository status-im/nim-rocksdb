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

func init*(T: type RocksDbSlice, data: cstring, len: csize_t): T =
  T(data: data, len: len)

template toOpenArray*(data: cstring, len: csize_t): openArray[byte] =
  const empty = []
  if data.isNil or len == 0:
    empty.toOpenArrayByte(0, -1)
  else:
    data.toOpenArrayByte(0, len.int - 1)

template toOpenArray*(slice: RocksDbSlice): openArray[byte] =
  toOpenArray(slice.data, slice.len)

template data*(slice: RocksDbSlice, asOpenArray: static bool = false): auto =
  ## Returns the data.
  when asOpenArray:
    slice.toOpenArray()
  else:
    @(slice.toOpenArray())
