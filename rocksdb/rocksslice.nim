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
    buf: ptr byte
    size: csize_t

  RocksDbMutSlice* = object
    buf: ptr byte
    size: int
    cap: int
    hasValue: bool

static:
  doAssert sizeof(RocksDbSlice) == sizeof(rocksdb_slice_t)
  doAssert offsetOf(RocksDbSlice, buf) == offsetOf(rocksdb_slice_t, data)
  doAssert offsetOf(RocksDbSlice, size) == offsetOf(rocksdb_slice_t, size)
  doAssert typeof(default(RocksDbSlice).size) is typeof(default(rocksdb_slice_t).size)

func init*(T: type RocksDbSlice, data: cstring, len: csize_t): T =
  T(buf: cast[ptr byte](data), size: len)

func init*(T: type RocksDbSlice, data: openArray[byte]): T =
  T(
    buf:
      if data.len > 0:
        unsafeAddr data[0]
      else:
        nil,
    size: csize_t(data.len),
  )

func init*(T: type RocksDbMutSlice, data: var openArray[byte]): T =
  T(
    buf:
      if data.len > 0:
        addr data[0]
      else:
        nil,
    size: 0,
    cap: data.len,
    hasValue: false,
  )

func toSlices*(keys: openArray[seq[byte]], slices: var openArray[RocksDbSlice]) =
  for i in 0 ..< keys.len:
    slices[i] = RocksDbSlice.init(keys[i])

func toSlices*(keys: openArray[seq[byte]]): seq[RocksDbSlice] =
  result = newSeq[RocksDbSlice](keys.len)
  keys.toSlices(result)

template baseAddr*(slice: RocksDbSlice | RocksDbMutSlice): pointer =
  cast[pointer](slice.buf)

template len*(slice: RocksDbSlice | RocksDbMutSlice): int =
  int(slice.size)

template `len=`*(slice: var RocksDbMutSlice, len: int) =
  slice.size = len

template capacity*(slice: RocksDbMutSlice): int =
  slice.cap

template found*(slice: RocksDbMutSlice): bool =
  slice.hasValue

template `found=`*(slice: var RocksDbMutSlice, found: bool) =
  slice.hasValue = found

template toOpenArray*(data: cstring | ptr byte, len: csize_t | int): openArray[byte] =
  const empty: array[0, byte] = []
  if data.isNil or len == 0:
    empty.toOpenArray(0, -1)
  else:
    cast[ptr UncheckedArray[byte]](data).toOpenArray(0, len.int - 1)

template toOpenArray*(slice: RocksDbSlice | RocksDbMutSlice): openArray[byte] =
  toOpenArray(slice.buf, slice.size)

template data*(
    slice: RocksDbSlice | RocksDbMutSlice, asOpenArray: static bool = false
): auto =
  when asOpenArray:
    slice.toOpenArray()
  else:
    @(slice.toOpenArray())
