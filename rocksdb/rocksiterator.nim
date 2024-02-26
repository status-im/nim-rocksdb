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
  ./lib/librocksdb,
  ./internal/utils,
  ./rocksresult

export
  rocksresult

type
  RocksIteratorPtr* = ptr rocksdb_iterator_t

  RocksIteratorRef* = ref object
    cPtr: RocksIteratorPtr

proc newRocksIterator*(cPtr: RocksIteratorPtr): RocksIteratorRef =
  doAssert not cPtr.isNil()
  RocksIteratorRef(cPtr: cPtr)

template isClosed*(iter: RocksIteratorRef): bool =
  iter.cPtr.isNil()

proc seekToFirst*(iter: var RocksIteratorRef) =
  doAssert not iter.isClosed()
  rocksdb_iter_seek_to_first(iter.cPtr)

proc seekToLast*(iter: var RocksIteratorRef) =
  doAssert not iter.isClosed()
  rocksdb_iter_seek_to_last(iter.cPtr)

proc isValid*(iter: RocksIteratorRef): bool =
  rocksdb_iter_valid(iter.cPtr).bool

proc next*(iter: var RocksIteratorRef) =
  rocksdb_iter_next(iter.cPtr)

proc prev*(iter: var RocksIteratorRef) =
  rocksdb_iter_prev(iter.cPtr)

proc key*(iter: RocksIteratorRef, onData: DataProc) =
  var kLen: csize_t
  let kData = rocksdb_iter_key(iter.cPtr, kLen.addr)

  if kData.isNil or kLen == 0:
    onData([])
  else:
    onData(kData.toOpenArrayByte(0, kLen.int - 1))

proc key*(iter: RocksIteratorRef): seq[byte] =
  var res: seq[byte]
  proc onData(data: openArray[byte]) =
    res = @data

  iter.key(onData)
  res

proc value*(iter: RocksIteratorRef, onData: DataProc) =
  var vLen: csize_t
  let vData = rocksdb_iter_value(iter.cPtr, vLen.addr)

  if vData.isNil or vLen == 0:
    onData([])
  else:
    onData(vData.toOpenArrayByte(0, vLen.int - 1))

proc value*(iter: RocksIteratorRef): seq[byte] =
  var res: seq[byte]
  proc onData(data: openArray[byte]) =
    res = @data

  iter.value(onData)
  res

proc status*(iter: RocksIteratorRef): RocksDBResult[void] =
  doAssert not iter.isClosed()

  var errors: cstring
  rocksdb_iter_get_error(iter.cPtr, cast[cstringArray](errors.addr))
  bailOnErrors(errors)

  ok()

proc close*(iter: var RocksIteratorRef) =
  if not iter.isClosed():
    rocksdb_iter_destroy(iter.cPtr)
    iter.cPtr = nil

iterator pairs*(iter: var RocksIteratorRef): tuple[key: seq[byte], value: seq[byte]] =
  doAssert not iter.isClosed()
  defer: iter.close()

  iter.seekToFirst()
  while iter.isValid():
    var
      key: seq[byte]
      value: seq[byte]
    iter.key(proc(data: openArray[byte]) = key = @data)
    iter.value(proc(data: openArray[byte]) = value = @data)

    iter.next()
    yield (key, value)
