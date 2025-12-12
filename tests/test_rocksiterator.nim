# Nim-RocksDB
# Copyright 2024-2025 Status Research & Development GmbH
# Licensed under either of
#
#  * Apache License, version 2.0, ([LICENSE-APACHE](LICENSE-APACHE) or http://www.apache.org/licenses/LICENSE-2.0)
#  * GPL license, version 2.0, ([LICENSE-GPLv2](LICENSE-GPLv2) or https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)
#
# at your option. This file may not be copied, modified, or distributed except according to those terms.

{.used.}

import std/os, tempfile, unittest2, ../rocksdb/[rocksdb, rocksiterator], ./test_helper

suite "RocksIteratorRef Tests":
  const
    CF_DEFAULT = "default"
    CF_OTHER = "other"
    CF_EMPTY = "empty"

  let
    key1 = @[byte(1)]
    val1 = @[byte(1)]
    key2 = @[byte(2)]
    val2 = @[byte(2)]
    key3 = @[byte(3)]
    val3 = @[byte(3)]

  setup:
    let
      dbPath = mkdtemp() / "data"
      db =
        initReadWriteDb(dbPath, columnFamilyNames = @[CF_DEFAULT, CF_OTHER, CF_EMPTY])
      defaultCfHandle = db.getColFamilyHandle(CF_DEFAULT).get()
      otherCfHandle = db.getColFamilyHandle(CF_OTHER).get()
      emptyCfHandle = db.getColFamilyHandle(CF_EMPTY).get()

    doAssert db.put(key1, val1).isOk()
    doAssert db.put(key2, val2).isOk()
    doAssert db.put(key3, val3).isOk()
    doAssert db.put(key1, val1, otherCfHandle).isOk()
    doAssert db.put(key2, val2, otherCfHandle).isOk()
    doAssert db.put(key3, val3, otherCfHandle).isOk()

  teardown:
    db.close()
    removeDir($dbPath)

  test "Iterate forwards using default column family":
    let res = db.openIterator(cfHandle = defaultCfHandle)
    check res.isOk()

    var iter = res.get()
    defer:
      iter.close()

    iter.seekToFirst()
    check iter.isValid()

    var expected = byte(1)
    while iter.isValid():
      let
        key = iter.key()
        val = iter.value()

      check:
        key == @[expected]
        val == @[expected]

      inc expected
      iter.next()

    check expected == byte(4)

  test "Iterate backwards using other column family":
    let res = db.openIterator(cfHandle = otherCfHandle)
    check res.isOk()

    var iter = res.get()
    defer:
      iter.close()

    iter.seekToLast()
    check iter.isValid()

    var expected = byte(3)
    while iter.isValid():
      var key: seq[byte]
      iter.key(
        proc(data: openArray[byte]) =
          key = @data
      )
      var val: seq[byte]
      iter.value(
        proc(data: openArray[byte]) =
          val = @data
      )

      check:
        key == @[expected]
        val == @[expected]

      dec expected
      iter.prev()

    check expected == byte(0)
    iter.close()

  test "Open two iterators on the same column family":
    let res1 = db.openIterator(cfHandle = defaultCfHandle)
    check res1.isOk()
    var iter1 = res1.get()
    defer:
      iter1.close()
    let res2 = db.openIterator(cfHandle = defaultCfHandle)
    check res2.isOk()
    var iter2 = res2.get()
    defer:
      iter2.close()

    iter1.seekToFirst()
    check iter1.isValid()
    iter2.seekToLast()
    check iter2.isValid()

    check:
      iter1.key() == @[byte(1)]
      iter1.value() == @[byte(1)]
      iter2.key() == @[byte(3)]
      iter2.value() == @[byte(3)]

  test "Open two iterators on different column families":
    let res1 = db.openIterator(cfHandle = defaultCfHandle)
    check res1.isOk()
    var iter1 = res1.get()
    defer:
      iter1.close()
    let res2 = db.openIterator(cfHandle = otherCfHandle)
    check res2.isOk()
    var iter2 = res2.get()
    defer:
      iter2.close()

    iter1.seekToFirst()
    check iter1.isValid()
    iter2.seekToLast()
    check iter2.isValid()

    check:
      iter1.key() == @[byte(1)]
      iter1.value() == @[byte(1)]
      iter2.key() == @[byte(3)]
      iter2.value() == @[byte(3)]

  test "Iterate forwards using seek to key":
    let res = db.openIterator(cfHandle = defaultCfHandle)
    check res.isOk()

    var iter = res.get()
    defer:
      iter.close()

    iter.seekToKey(key2)
    check:
      iter.isValid()
      iter.key() == key2
      iter.value() == val2

  test "Seek to empty key":
    let empty: seq[byte] = @[]
    check db.put(empty, val1).isOk()

    let iter = db.openIterator().get()
    defer:
      iter.close()

    iter.seekToKey(empty)
    check:
      iter.isValid()
      iter.key() == empty
      iter.value() == val1

  test "Empty value":
    let key = @[0x1.byte, 0x2, 0x3]
    let empty: seq[byte] = @[]
    check db.put(key, empty).isOk()

    let iter = db.openIterator().get()
    defer:
      iter.close()

    iter.seekToKey(key)
    check:
      iter.isValid()
      iter.key() == key
      iter.value() == empty

  test "Empty column family":
    let res = db.openIterator(cfHandle = emptyCfHandle)
    check res.isOk()
    var iter = res.get()
    defer:
      iter.close()

    iter.seekToFirst()
    check not iter.isValid()

    iter.seekToLast()
    check not iter.isValid()

  test "Test status":
    let res = db.openIterator(cfHandle = emptyCfHandle)
    check res.isOk()
    var iter = res.get()
    defer:
      iter.close()

    check iter.status().isOk()
    iter.seekToLast()
    check iter.status().isOk()

  test "Test pairs iterator":
    let res = db.openIterator(cfHandle = defaultCfHandle)
    check res.isOk()
    var iter = res.get()

    block:
      var expected = byte(1)
      for k, v in iter.pairs(autoClose = false):
        check:
          k == @[expected]
          v == @[expected]
        inc expected
      check not iter.isClosed()

    block:
      var expected = byte(1)
      for k, v in iter:
        check:
          k == @[expected]
          v == @[expected]
        inc expected
      check iter.isClosed()

  test "Test pairs slice iterator":
    let res = db.openIterator(cfHandle = defaultCfHandle)
    check res.isOk()
    var iter = res.get()

    block:
      var expected = byte(1)
      for k, v in iter.slicePairs(autoClose = false):
        check:
          k.data() == @[expected]
          v.data() == @[expected]
          k.data(asOpenArray = true) == [expected]
          v.data(asOpenArray = true) == @[expected]
        inc expected
      check not iter.isClosed()

    block:
      var expected = byte(1)
      for k, v in iter.slicePairs():
        check:
          k.data() == @[expected]
          v.data() == @[expected]
          k.data(asOpenArray = true) == [expected]
          v.data(asOpenArray = true) == @[expected]
        inc expected
      check iter.isClosed()

  test "Test close":
    let res = db.openIterator()
    check res.isOk()
    var iter = res.get()

    check not iter.isClosed()
    iter.close()
    check iter.isClosed()
    iter.close()
    check iter.isClosed()
