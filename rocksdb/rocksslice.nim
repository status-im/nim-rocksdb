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

import ./lib/librocksdb

type
  RocksDbSlice* = object
    data: ptr byte
    len: csize_t

  RocksDbMutSlice* = object
    data: ptr byte
    len: int
    capacity: int

static:
  doAssert sizeof(RocksDbSlice) == sizeof(rocksdb_slice_t)
  doAssert offsetOf(RocksDbSlice, data) == offsetOf(rocksdb_slice_t, data)
  doAssert offsetOf(RocksDbSlice, len) == offsetOf(rocksdb_slice_t, size)
  doAssert typeof(default(RocksDbSlice).len) is typeof(default(rocksdb_slice_t).size)

func init*(T: type RocksDbSlice, data: cstring, len: csize_t): T =
  T(data: cast[ptr byte](data), len: len)

func init*(T: type RocksDbSlice, data: openArray[byte]): T =
  T(data: if data.len > 0: unsafeAddr data[0] else: nil, len: csize_t(data.len))

func init*(T: type RocksDbMutSlice, data: var openArray[byte]): T =
  T(
    data: if data.len > 0: addr data[0] else: nil,
    len: 0,
    capacity: data.len,
  )

func capacity*(slice: RocksDbMutSlice): int =
  slice.capacity

func setLen*(slice: var RocksDbMutSlice, len: int) =
  doAssert len >= 0 and len <= slice.capacity
  slice.len = len

func len*(slice: RocksDbSlice | RocksDbMutSlice): int =
  int(slice.len)

func baseAddr*(slice: RocksDbSlice | RocksDbMutSlice): pointer =
  cast[pointer](slice.data)

template toOpenArray*(data: cstring | ptr byte, len: csize_t | int): openArray[byte] =
  const empty: array[0, byte] = []
  if data.isNil or len == 0:
    empty.toOpenArray(0, -1)
  else:
    cast[ptr UncheckedArray[byte]](data).toOpenArray(0, len.int - 1)

template toOpenArray*(slice: RocksDbSlice | RocksDbMutSlice): openArray[byte] =
  toOpenArray(slice.data, slice.len)

template data*(
    slice: RocksDbSlice | RocksDbMutSlice, asOpenArray: static bool = false
): auto =
  when asOpenArray:
    slice.toOpenArray()
  else:
    @(slice.toOpenArray())
