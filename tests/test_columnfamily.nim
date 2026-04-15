# Nim-RocksDB
# Copyright 2018-2024 Status Research & Development GmbH
# Licensed under either of
#
#  * Apache License, version 2.0, ([LICENSE-APACHE](LICENSE-APACHE) or http://www.apache.org/licenses/LICENSE-2.0)
#  * GPL license, version 2.0, ([LICENSE-GPLv2](LICENSE-GPLv2) or https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)
#
# at your option. This file may not be copied, modified, or distributed except according to those terms.

{.used.}

import std/os, tempfile, unittest2, ../rocksdb/columnfamily, ./test_helper

suite "ColFamily Tests":
  const
    CF_DEFAULT = "default"
    CF_OTHER = "other"

  let
    key = @[byte(1), 2, 3, 4, 5]
    otherKey = @[byte(1), 2, 3, 4, 5, 6]
    val = @[byte(1), 2, 3, 4, 5]

  setup:
    let
      dbPath = mkdtemp() / "data"
      db = initReadWriteDb(dbPath, columnFamilyNames = @[CF_DEFAULT, CF_OTHER])

  teardown:
    db.close()
    removeDir($dbPath)

  test "Basic operations":
    let r0 = db.getColFamily(CF_OTHER)
    check r0.isOk()
    let cf = r0.value()

    check cf.put(key, val).isOk()

    var bytes: seq[byte]
    check cf.get(
      key,
      proc(data: openArray[byte]) =
        bytes = @data,
    )[]
    check not cf.get(
      otherKey,
      proc(data: openArray[byte]) =
        bytes = @data,
    )[]

    var r1 = cf.get(key)
    check r1.isOk() and r1.value == val

    var r2 = cf.get(otherKey)
    check r2.isErr() and r2.error.len > 0

    var e1 = cf.keyExists(key)
    check e1.isOk() and e1.value == true

    var e2 = cf.keyExists(otherKey)
    check e2.isOk() and e2.value == false

    var d = cf.delete(key)
    check d.isOk()

    e1 = cf.keyExists(key)
    check e1.isOk() and e1.value == false

    d = cf.delete(otherKey)
    check d.isOk()

    cf.db.close()
    check db.isClosed()

    # Open database in read only mode
    block:
      var res = initReadOnlyDb(dbPath).getColFamily(CF_DEFAULT)
      check res.isOk()

      let readOnlyCf = res.value()
      let r = readOnlyCf.keyExists(key)
      check r.isOk() and r.value == false

      readOnlyCf.db.close()
      check readOnlyCf.db.isClosed()

  test "Test iterator":
    let cf = db.getColFamily(CF_OTHER).get()
    check cf.put(key, val).isOk()

    let iter = cf.openIterator().get()
    defer:
      iter.close()

    iter.seekToKey(key)
    check:
      iter.isValid() == true
      iter.key() == key
      iter.value() == val
    iter.seekToKey(otherKey)
    check iter.isValid() == false

  test "Test deleteRange":
    let cf = db.getColFamily(CF_OTHER).get()

    let
      keyValue1 = @[1.byte]
      keyValue2 = @[2.byte]
      keyValue3 = @[3.byte]

    check:
      cf.put(keyValue1, keyValue1).isOk()
      cf.put(keyValue2, keyValue2).isOk()
      cf.put(keyValue3, keyValue3).isOk()
      cf.keyExists(keyValue1).get() == true
      cf.keyExists(keyValue2).get() == true
      cf.keyExists(keyValue3).get() == true

      cf.suggestCompactRange(keyValue1, keyValue3).isOk()
      cf.deleteRange(keyValue1, keyValue3).isOk()
      cf.compactRange(keyValue1, keyValue3).isOk()

      cf.keyExists(keyValue1).get() == false
      cf.keyExists(keyValue2).get() == false
      cf.keyExists(keyValue3).get() == true

  test "Test multiget":
    let cf = db.getColFamily(CF_OTHER).get()

    let
      keyValue1 = @[100.byte]
      keyValue2 = @[300.byte]
      keyValue3 = default(seq[byte])

    check:
      cf.put(keyValue1, keyValue1).isOk()
      cf.put(keyValue2, keyValue2).isOk()
      cf.put(keyValue3, keyValue3).isOk()
      cf.keyExists(keyValue1).get() == true
      cf.keyExists(keyValue2).get() == true
      cf.keyExists(keyValue3).get() == true

    let dataRes = cf.multiGet(@[keyValue1, keyValue2, keyValue3]).expect("ok")
    check:
      dataRes.len() == 3
      dataRes[0] == Opt.some(keyValue1)
      dataRes[1] == Opt.some(keyValue2)
      dataRes[2] == Opt.some(default(seq[byte]))

  test "Test multiget iterator":
    let cf = db.getColFamily(CF_OTHER).get()

    let
      keyValue1 = @[100.byte]
      keyValue2 = @[300.byte]
      keyValue3 = default(seq[byte])

    check:
      cf.put(keyValue1, keyValue1).isOk()
      cf.put(keyValue2, keyValue2).isOk()
      cf.put(keyValue3, keyValue3).isOk()
      cf.keyExists(keyValue1).get() == true
      cf.keyExists(keyValue2).get() == true
      cf.keyExists(keyValue3).get() == true

    let
      expected =
        [Opt.some(keyValue1), Opt.some(keyValue2), Opt.some(default(seq[byte]))]
      iter = cf.multiGetIter(@[keyValue1, keyValue2, keyValue3]).expect("ok")

    block:
      var i = 0
      for slice in iter.items(autoClose = false):
        check slice.map(
          proc(s: auto): auto =
            s.data()
        ) == expected[i]
        inc i
      check:
        i == 3
        not iter.isClosed()

    block:
      var i = 0
      for slice in iter.items(autoClose = true):
        check slice.map(
          proc(s: auto): auto =
            s.data()
        ) == expected[i]
        inc i
      check:
        i == 3
        iter.isClosed()

  test "Test get into buffer":
    let cf = db.getColFamily(CF_OTHER).get()

    check cf.put(key, val).isOk()

    # Key found, buffer is exactly the right size
    var buf = newSeq[byte](val.len)
    var dataLen = -1
    let r1 = cf.get(key, buf, dataLen)
    check:
      r1.isOk() and r1.value == true
      dataLen == val.len
      buf == val

    # Key found, larger buffer also works
    var bigBuf = newSeq[byte](val.len + 10)
    dataLen = -1
    let r2 = cf.get(key, bigBuf, dataLen)
    check:
      r2.isOk() and r2.value == true
      dataLen == val.len
      bigBuf[0 ..< val.len] == val

    # Key found but buffer too small
    var smallBuf = newSeq[byte](val.len - 1)
    dataLen = -1
    let r3 = cf.get(key, smallBuf, dataLen)
    check:
      r3.isErr()
      dataLen == val.len

    # Key not found
    var buf2 = newSeq[byte](val.len)
    dataLen = -1
    let r4 = cf.get(otherKey, buf2, dataLen)
    check:
      r4.isOk() and r4.value == false
      dataLen == 0
