# Nim-RocksDB
# Copyright 2024-2025 Status Research & Development GmbH
# Licensed under either of
#
#  * Apache License, version 2.0, ([LICENSE-APACHE](LICENSE-APACHE) or http://www.apache.org/licenses/LICENSE-2.0)
#  * GPL license, version 2.0, ([LICENSE-GPLv2](LICENSE-GPLv2) or https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)
#
# at your option. This file may not be copied, modified, or distributed except according to those terms.

## A `RocksIteratorRef` is a reference to a RocksDB iterator which supports
## iterating over the key value pairs in a column family.

{.push raises: [].}

import ./lib/librocksdb, ./internal/utils, ./options/readopts, ./rocksresult, rocksslice

export rocksresult, rocksslice

type
  RocksIteratorPtr* = ptr rocksdb_iterator_t

  RocksIteratorRef* = ref object
    cPtr: RocksIteratorPtr
    readOpts: ReadOptionsRef

  PinnableSlicePtr = ptr rocksdb_pinnableslice_t

  MultiGetIteratorRef* = ref seq[PinnableSlicePtr]

func init*(T: type MultiGetIteratorRef, len: int): T =
  doAssert len > 0
  let iter = new T
  iter[] =
    when NimMajor >= 2 and NimMinor >= 2:
      newSeqUninit[PinnableSlicePtr](len)
    else:
      newSeq[PinnableSlicePtr](len)
  iter

func isClosed*(iter: MultiGetIteratorRef): bool =
  iter[].len() == 0

func close*(iter: MultiGetIteratorRef) =
  for pSlice in iter[]:
    rocksdb_pinnableslice_destroy(pSlice)
  iter[].setLen(0)

iterator items*(
    iter: MultiGetIteratorRef, autoClose: static bool = true
): Opt[RocksDbSlice] =
  ## Iterates over the values in the iterator returning an optional slice
  ## for each value. The iterator is automatically closed after the iteration
  ## unless autoClose is set to false.
  doAssert not iter.isClosed()

  when autoClose:
    defer:
      iter.close()

  for pSlice in iter[]:
    if pSlice.isNil():
      yield Opt.none(RocksDbSlice)
      continue

    var len: csize_t = 0
    let data = rocksdb_pinnableslice_value(pSlice, len.addr)
    yield Opt.some(RocksDbSlice.init(data, len))

proc newRocksIterator*(
    cPtr: RocksIteratorPtr, readOpts: ReadOptionsRef
): RocksIteratorRef =
  doAssert not cPtr.isNil()
  RocksIteratorRef(cPtr: cPtr, readOpts: readOpts)

template isClosed*(iter: RocksIteratorRef): bool =
  ## Returns `true` if the iterator is closed and `false` otherwise.
  iter.cPtr.isNil()

proc seekToKey*(iter: RocksIteratorRef, key: openArray[byte]) =
  ## Seeks to the `key` argument in the column family. If the return code is
  ## `false`, the iterator has become invalid and should be closed.
  ##
  ## It is not clear what happens when the `key` does not exist in the column
  ## family. The guess is that the interation will proceed at the next key
  ## position. This is suggested by a comment from the GO port at
  ##
  ##    //github.com/DanielMorsing/rocksdb/blob/master/iterator.go:
  ##
  ##    Seek moves the iterator the position of the key given or, if the key
  ##    doesn't exist, the next key that does exist in the database. If the
  ##    key doesn't exist, and there is no next key, the Iterator becomes
  ##    invalid.
  ##
  doAssert not iter.isClosed()
  rocksdb_iter_seek(iter.cPtr, cast[cstring](key.unsafeAddrOrNil()), csize_t(key.len))

proc seekToFirst*(iter: RocksIteratorRef) =
  ## Seeks to the first entry in the column family.
  doAssert not iter.isClosed()
  rocksdb_iter_seek_to_first(iter.cPtr)

proc seekToLast*(iter: RocksIteratorRef) =
  ## Seeks to the last entry in the column family.
  doAssert not iter.isClosed()
  rocksdb_iter_seek_to_last(iter.cPtr)

proc isValid*(iter: RocksIteratorRef): bool =
  ## Returns `true` if the iterator is valid and `false` otherwise.
  rocksdb_iter_valid(iter.cPtr).bool

proc next*(iter: RocksIteratorRef) =
  ## Seeks to the next entry in the column family.
  rocksdb_iter_next(iter.cPtr)

proc prev*(iter: RocksIteratorRef) =
  ## Seeks to the previous entry in the column family.
  rocksdb_iter_prev(iter.cPtr)

template keyOpenArray(iter: RocksIteratorRef): openArray[byte] =
  var kLen: csize_t
  let kData = rocksdb_iter_key(iter.cPtr, kLen.addr)
  toOpenArray(kData, kLen)

proc key*(iter: RocksIteratorRef, onData: DataProc) =
  ## Returns the current key using the provided `onData` callback.
  onData(iter.keyOpenArray())

template key*(iter: RocksIteratorRef, asOpenArray: static bool = false): auto =
  ## Returns the current key.
  when asOpenArray:
    iter.keyOpenArray()
  else:
    @(iter.keyOpenArray())

template valueOpenArray(iter: RocksIteratorRef): openArray[byte] =
  var vLen: csize_t
  let vData = rocksdb_iter_value(iter.cPtr, vLen.addr)
  toOpenArray(vData, vLen)

proc value*(iter: RocksIteratorRef, onData: DataProc) =
  ## Returns the current value using the provided `onData` callback.
  onData(iter.valueOpenArray())

template value*(iter: RocksIteratorRef, asOpenArray: static bool = false): auto =
  ## Returns the current value.
  when asOpenArray:
    iter.valueOpenArray()
  else:
    @(iter.valueOpenArray())

proc status*(iter: RocksIteratorRef): RocksDBResult[void] =
  ## Returns the status of the iterator.
  doAssert not iter.isClosed()

  var errors: cstring
  rocksdb_iter_get_error(iter.cPtr, cast[cstringArray](errors.addr))
  bailOnErrors(errors)

  ok()

proc close*(iter: RocksIteratorRef) =
  ## Closes the `RocksIteratorRef`.
  if not iter.isClosed():
    rocksdb_iter_destroy(iter.cPtr)
    iter.cPtr = nil

    autoCloseNonNil(iter.readOpts)

iterator pairs*(
    iter: RocksIteratorRef, autoClose: static bool = true
): tuple[key: seq[byte], value: seq[byte]] =
  ## Iterates over the key value pairs in the column family yielding them in
  ## the form of a tuple of seq[byte]. The iterator is automatically closed
  ## after the iteration unless autoClose is set to false.
  doAssert not iter.isClosed()
  when autoClose:
    defer:
      iter.close()

  iter.seekToFirst()

  while iter.isValid():
    yield (iter.key(), iter.value())
    iter.next()

func keySlice(iter: RocksIteratorRef): RocksDbSlice =
  ## Returns the current key as a slice.
  var kLen: csize_t
  let kData = rocksdb_iter_key(iter.cPtr, kLen.addr)
  RocksDbSlice.init(kData, kLen)

func valueSlice(iter: RocksIteratorRef): RocksDbSlice =
  ## Returns the current value as a slice.
  var vLen: csize_t
  let vData = rocksdb_iter_value(iter.cPtr, vLen.addr)
  RocksDbSlice.init(vData, vLen)

iterator slicePairs*(
    iter: RocksIteratorRef, autoClose: static bool = true
): tuple[key: RocksDbSlice, value: RocksDbSlice] =
  ## Iterates over the key value pairs in the column family yielding them in
  ## the form of a tuple of slices. The iterator is automatically closed
  ## after the iteration unless autoClose is set to false.
  doAssert not iter.isClosed()
  when autoClose:
    defer:
      iter.close()

  iter.seekToFirst()

  while iter.isValid():
    yield (iter.keySlice(), iter.valueSlice())
    iter.next()
