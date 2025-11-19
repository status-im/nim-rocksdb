# Nim-RocksDB
# Copyright 2018-2024 Status Research & Development GmbH
# Licensed under either of
#
#  * Apache License, version 2.0, ([LICENSE-APACHE](LICENSE-APACHE) or http://www.apache.org/licenses/LICENSE-2.0)
#  * GPL license, version 2.0, ([LICENSE-GPLv2](LICENSE-GPLv2) or https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)
#
# at your option. This file may not be copied, modified, or distributed except according to those terms.

{.used.}

import std/os, tempfile, unittest2, ../rocksdb/rocksdb, ./test_helper

suite "RocksDbRef Tests":
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
      defaultCfHandle = db.getColFamilyHandle(CF_DEFAULT).get()
      otherCfHandle = db.getColFamilyHandle(CF_OTHER).get()

  teardown:
    db.close()
    removeDir($dbPath)

  test "Basic operations":
    var s = db.put(key, val)
    check s.isOk()

    var bytes: seq[byte]
    check db.get(
      key,
      proc(data: openArray[byte]) =
        bytes = @data,
    )[]
    check not db.get(
      otherKey,
      proc(data: openArray[byte]) =
        bytes = @data,
    )[]

    var r1 = db.get(key)
    check r1.isOk() and r1.value == val

    var r2 = db.get(otherKey)
    check r2.isErr() and r2.error.len > 0

    var e1 = db.keyExists(key)
    check e1.isOk() and e1.value == true

    var e2 = db.keyExists(otherKey)
    check e2.isOk() and e2.value == false

    var d = db.delete(key)
    check d.isOk()

    e1 = db.keyExists(key)
    check e1.isOk() and e1.value == false

    d = db.delete(otherKey)
    check d.isOk()

    close(db)
    check db.isClosed()

    # Open database in read only mode
    block:
      var
        readOnlyDb = initReadOnlyDb(dbPath)
        r = readOnlyDb.keyExists(key)
      check r.isOk() and r.value == false

      # This won't compile as designed:
      # var r2 = readOnlyDb.put(key, @[123.byte])
      # check r2.isErr()

      readOnlyDb.close()
      check readOnlyDb.isClosed()

  test "Basic operations - default column family":
    var s = db.put(key, val, defaultCfHandle)
    check s.isOk()

    var bytes: seq[byte]
    check db.get(
      key,
      proc(data: openArray[byte]) =
        bytes = @data,
      defaultCfHandle,
    )[]
    check not db.get(
      otherKey,
      proc(data: openArray[byte]) =
        bytes = @data,
      defaultCfHandle,
    )[]

    var r1 = db.get(key)
    check r1.isOk() and r1.value == val

    var r2 = db.get(otherKey)
    check r2.isErr() and r2.error.len > 0

    var e1 = db.keyExists(key, defaultCfHandle)
    check e1.isOk() and e1.value == true

    var e2 = db.keyExists(otherKey, defaultCfHandle)
    check e2.isOk() and e2.value == false

    var d = db.delete(key, defaultCfHandle)
    check d.isOk()

    e1 = db.keyExists(key, defaultCfHandle)
    check e1.isOk() and e1.value == false

    d = db.delete(otherKey, defaultCfHandle)
    check d.isOk()

    db.close()
    check db.isClosed()

    # Open database in read only mode
    block:
      var
        readOnlyDb = initReadOnlyDb(dbPath, columnFamilyNames = @[CF_DEFAULT])
        r = readOnlyDb.keyExists(key)
      check r.isOk() and r.value == false

      # Won't compile as designed:
      # var r2 = readOnlyDb.put(key, @[123.byte], defaultCfHandle)
      # check r2.isErr()

      readOnlyDb.close()
      check readOnlyDb.isClosed()

  test "Basic operations - multiple column families":
    var s = db.put(key, val, defaultCfHandle)
    check s.isOk()

    var s2 = db.put(otherKey, val, otherCfHandle)
    check s2.isOk()

    var bytes: seq[byte]
    check db.get(
      key,
      proc(data: openArray[byte]) =
        bytes = @data,
      defaultCfHandle,
    )[]
    check not db.get(
      otherKey,
      proc(data: openArray[byte]) =
        bytes = @data,
      defaultCfHandle,
    )[]

    var bytes2: seq[byte]
    check db.get(
      otherKey,
      proc(data: openArray[byte]) =
        bytes2 = @data,
      otherCfHandle,
    )[]
    check not db.get(
      key,
      proc(data: openArray[byte]) =
        bytes2 = @data,
      otherCfHandle,
    )[]

    var e1 = db.keyExists(key, defaultCfHandle)
    check e1.isOk() and e1.value == true
    var e2 = db.keyExists(otherKey, defaultCfHandle)
    check e2.isOk() and e2.value == false

    var e3 = db.keyExists(key, otherCfHandle)
    check e3.isOk() and e3.value == false
    var e4 = db.keyExists(otherKey, otherCfHandle)
    check e4.isOk() and e4.value == true

    var d = db.delete(key, defaultCfHandle)
    check d.isOk()
    e1 = db.keyExists(key, defaultCfHandle)
    check e1.isOk() and e1.value == false
    d = db.delete(otherKey, defaultCfHandle)
    check d.isOk()

    var d2 = db.delete(key, otherCfHandle)
    check d2.isOk()
    e3 = db.keyExists(key, otherCfHandle)
    check e3.isOk() and e3.value == false
    d2 = db.delete(otherKey, otherCfHandle)
    check d2.isOk()
    d2 = db.delete(otherKey, otherCfHandle)
    check d2.isOk()

    db.close()
    check db.isClosed()

    # Open database in read only mode
    block:
      var readOnlyDb =
        initReadOnlyDb(dbPath, columnFamilyNames = @[CF_DEFAULT, CF_OTHER])

      var r = readOnlyDb.keyExists(key, readOnlyDb.getColFamilyHandle(CF_OTHER).get())
      check r.isOk() and r.value == false

      # Does not compile as designed:
      # var r2 = readOnlyDb.put(key, @[123.byte], otherCfHandle)
      # check r2.isErr()

      readOnlyDb.close()
      check readOnlyDb.isClosed()

  test "Test missing key and values":
    let
      key1 = @[byte(1)] # exists with non empty value
      val1 = @[byte(1)]
      key2 = @[byte(2)] # exists with empty seq value
      val2: seq[byte] = @[]
      key3 = @[byte(3)] # exists with empty array value
      val3: array[0, byte] = []
      key4 = @[byte(4)] # deleted key
      key5 = @[byte(5)] # key not created

    check:
      db.put(key1, val1).isOk()
      db.put(key2, val2).isOk()
      db.put(key3, val3).isOk()
      db.delete(key4).isOk()

      db.keyExists(key1).get() == true
      db.keyExists(key2).get() == true
      db.keyExists(key3).get() == true
      db.keyExists(key4).get() == false
      db.keyExists(key5).get() == false

    block:
      var v: seq[byte]
      let r = db.get(
        key1,
        proc(data: openArray[byte]) =
          v = @data,
      )
      check:
        r.isOk()
        r.value() == true
        v == val1
        db.get(key1).isOk()

    block:
      var v: seq[byte]
      let r = db.get(
        key2,
        proc(data: openArray[byte]) =
          v = @data,
      )
      check:
        r.isOk()
        r.value() == true
        v.len() == 0
        db.get(key2).isOk()

    block:
      var v: seq[byte]
      let r = db.get(
        key3,
        proc(data: openArray[byte]) =
          v = @data,
      )
      check:
        r.isOk()
        r.value() == true
        v.len() == 0
        db.get(key3).isOk()

    block:
      var v: seq[byte]
      let r = db.get(
        key4,
        proc(data: openArray[byte]) =
          v = @data,
      )
      check:
        r.isOk()
        r.value() == false
        v.len() == 0
        db.get(key4).isErr()

    block:
      var v: seq[byte]
      let r = db.get(
        key5,
        proc(data: openArray[byte]) =
          v = @data,
      )
      check:
        r.isOk()
        r.value() == false
        v.len() == 0
        db.get(key5).isErr()

  test "Test keyMayExist":
    let
      key1 = @[byte(1)] # exists with non empty value
      val1 = @[byte(1)]
      key2 = @[byte(2)] # exists with empty seq value
      val2: seq[byte] = @[]
      key3 = @[byte(3)] # exists with empty array value
      val3: array[0, byte] = []
      key4 = @[byte(4)] # deleted key
      key5 = @[byte(5)] # key not created

    check:
      db.put(key1, val1).isOk()
      db.put(key2, val2).isOk()
      db.put(key3, val3).isOk()
      db.delete(key4).isOk()

      db.keyMayExist(key1).isOk()
      db.keyMayExist(key2).isOk()
      db.keyMayExist(key3).isOk()
      db.keyMayExist(key4).get() == false
      db.keyMayExist(key5).get() == false

  test "Put, get and delete empty key":
    let empty: seq[byte] = @[]

    check:
      db.put(empty, val).isOk()
      db.get(empty).get() == val
      db.delete(empty).isOk()
      db.get(empty).isErr()

  test "List column familes":
    let cfRes1 = listColumnFamilies(dbPath)
    check:
      cfRes1.isOk()
      cfRes1.value() == @[CF_DEFAULT, CF_OTHER]

    let
      dbPath2 = dbPath & "2"
      db2 = initReadWriteDb(dbPath2, columnFamilyNames = @[CF_DEFAULT])
      cfRes2 = listColumnFamilies(dbPath2)
    check:
      cfRes2.isOk()
      cfRes2.value() == @[CF_DEFAULT]

  test "Unknown column family":
    const CF_UNKNOWN = "unknown"
    let cfHandleRes = db.getColFamilyHandle(CF_UNKNOWN)
    check cfHandleRes.isErr() and cfHandleRes.error() == "rocksdb: unknown column family"

  test "Close multiple times":
    check not db.isClosed()
    db.close()
    check db.isClosed()
    db.close()
    check db.isClosed()

  test "Test auto close enabled":
    let
      dbPath = mkdtemp() / "autoclose-enabled"
      dbOpts = defaultDbOptions(autoClose = true)
      readOpts = defaultReadOptions(autoClose = true)
      writeOpts = defaultWriteOptions(autoClose = true)
      columnFamilies =
        @[
          initColFamilyDescriptor(CF_DEFAULT, defaultColFamilyOptions(autoClose = true))
        ]
      db = openRocksDb(dbPath, dbOpts, readOpts, writeOpts, columnFamilies).get()

    check:
      dbOpts.isClosed() == false
      readOpts.isClosed() == false
      writeOpts.isClosed() == false
      columnFamilies[0].isClosed() == false
      db.isClosed() == false

    db.close()

    check:
      dbOpts.isClosed() == true
      readOpts.isClosed() == true
      writeOpts.isClosed() == true
      columnFamilies[0].isClosed() == true
      db.isClosed() == true

  test "Test auto close disabled":
    let
      dbPath = mkdtemp() / "autoclose-disabled"
      dbOpts = defaultDbOptions(autoClose = false)
      readOpts = defaultReadOptions(autoClose = false)
      writeOpts = defaultWriteOptions(autoClose = false)
      columnFamilies =
        @[
          initColFamilyDescriptor(
            CF_DEFAULT, defaultColFamilyOptions(autoClose = false)
          )
        ]
      db = openRocksDb(dbPath, dbOpts, readOpts, writeOpts, columnFamilies).get()

    check:
      dbOpts.isClosed() == false
      readOpts.isClosed() == false
      writeOpts.isClosed() == false
      columnFamilies[0].isClosed() == false
      db.isClosed() == false

    db.close()

    check:
      dbOpts.isClosed() == false
      readOpts.isClosed() == false
      writeOpts.isClosed() == false
      columnFamilies[0].isClosed() == false
      db.isClosed() == true

  test "Test compression libraries linked":
    let
      dbPath = mkdtemp() / "compression"
      cfOpts = defaultColFamilyOptions(autoClose = false)
      cfDescriptor = initColFamilyDescriptor(CF_DEFAULT, cfOpts)

    cfOpts.compression = lz4Compression
    check cfOpts.compression == lz4Compression
    let db1 = openRocksDb(dbPath, columnFamilies = @[cfDescriptor]).get()
    check db1.put(key, val).isOk()
    db1.close()

    cfOpts.compression = zstdCompression
    check cfOpts.compression == zstdCompression
    let db2 = openRocksDb(dbPath, columnFamilies = @[cfDescriptor]).get()
    check db2.put(key, val).isOk()
    db2.close()

    cfOpts.close()
    removeDir($dbPath)

  test "Test iterator":
    check db.put(key, val).isOk()

    let iter = db.openIterator().get()
    defer:
      iter.close()

    iter.seekToKey(key)
    check:
      iter.isValid() == true
      iter.key() == key
      iter.value() == val
    iter.seekToKey(otherKey)
    check iter.isValid() == false

  test "Create and restore snapshot":
    check:
      db.put(key, val).isOk()
      db.keyExists(key).get() == true
      db.keyMayExist(otherKey).get() == false

    let snapshot = db.getSnapshot().get()
    check:
      snapshot.getSequenceNumber() > 0
      not snapshot.isClosed()

    # after taking snapshot, update the db
    check:
      db.delete(key).isOk()
      db.put(otherKey, val).isOk()
      db.keyMayExist(key).get() == false
      db.keyExists(otherKey).get() == true

    let readOpts = defaultReadOptions(autoClose = true)
    readOpts.setSnapshot(snapshot)

    # read from the snapshot using an iterator
    let iter = db.openIterator(readOpts = readOpts).get()
    defer:
      iter.close()
    iter.seekToKey(key)
    check:
      iter.isValid() == true
      iter.key() == key
      iter.value() == val
    iter.seekToKey(otherKey)
    check:
      iter.isValid() == false

    db.releaseSnapshot(snapshot)
    check snapshot.isClosed()

  test "Test flush":
    check:
      db.put(key, val).isOk()
      db.flush().isOk()

    check:
      db.put(otherKey, val, otherCfHandle).isOk()
      db.flush(otherCfHandle).isOk()

    let cfHandles = [defaultCfHandle, otherCfHandle]
    check:
      db.put(otherKey, val, defaultCfHandle).isOk()
      db.put(key, val, otherCfHandle).isOk()
      db.flush(cfHandles).isOk()

  test "Test deleteRange":
    let
      keyValue1 = @[1.byte]
      keyValue2 = @[2.byte]
      keyValue3 = @[3.byte]

    check:
      db.put(keyValue1, keyValue1).isOk()
      db.put(keyValue2, keyValue2).isOk()
      db.put(keyValue3, keyValue3).isOk()
      db.keyExists(keyValue1).get() == true
      db.keyExists(keyValue2).get() == true
      db.keyExists(keyValue3).get() == true

      db.deleteRange(keyValue1, keyValue3).isOk()
      db.compactRange(keyValue1, keyValue3).isOk()

      db.keyExists(keyValue1).get() == false
      db.keyExists(keyValue2).get() == false
      db.keyExists(keyValue3).get() == true

    check:
      db.put(keyValue1, keyValue1, otherCfHandle).isOk()
      db.put(keyValue2, keyValue2, otherCfHandle).isOk()
      db.keyExists(keyValue1, otherCfHandle).get() == true
      db.keyExists(keyValue2, otherCfHandle).get() == true
      db.keyExists(keyValue3, otherCfHandle).get() == false

      db.deleteRange(keyValue1, keyValue2, otherCfHandle).isOk()
      db.suggestCompactRange(keyValue1, keyValue3, otherCfHandle).isOk()

      db.keyExists(keyValue1, otherCfHandle).get() == false
      db.keyExists(keyValue2, otherCfHandle).get() == true
      db.keyExists(keyValue3, otherCfHandle).get() == false

  test "Test multiget":
    let
      keyValue1 = @[1.byte]
      keyValue2 = @[2.byte]
      keyValue3 = @[3.byte]
      keyValue4 = @[4.byte]
      keyValue5 = @[5.byte]
      keyValue6 = @[6.byte]
      keyValue7 = @[7.byte]
      keyValue8 = @[8.byte]
      keyValue9 = @[9.byte]

    check:
      db.put(keyValue1, keyValue1).isOk()
      db.put(keyValue2, keyValue2).isOk()
      db.put(keyValue5, keyValue5).isOk()
      db.put(keyValue7, keyValue7).isOk()
      db.put(keyValue9, keyValue9).isOk()
      db.keyExists(keyValue1).get() == true
      db.keyExists(keyValue2).get() == true
      db.keyExists(keyValue3).get() == false

    block:
      let dataRes = db.multiGet(@[keyValue1]).expect("ok")
      check:
        dataRes.len() == 1
        dataRes[0] == Opt.some(keyValue1)

    block:
      let dataRes = db.multiGet(@[keyValue1, keyValue2]).expect("ok")
      check:
        dataRes.len() == 2
        dataRes[0] == Opt.some(keyValue1)
        dataRes[1] == Opt.some(keyValue2)

    block:
      let dataRes = db.multiGet(@[keyValue2, keyValue3]).expect("ok")
      check:
        dataRes.len() == 2
        dataRes[0] == Opt.some(keyValue2)
        dataRes[1] == Opt.none(seq[byte])

    block:
      let dataRes = db.multiGet(@[keyValue1, keyValue2, keyValue3]).expect("ok")
      check:
        dataRes.len() == 3
        dataRes[0] == Opt.some(keyValue1)
        dataRes[1] == Opt.some(keyValue2)
        dataRes[2] == Opt.none(seq[byte])

    block:
      let dataRes =
        db.multiGet(@[keyValue1, keyValue2, keyValue3], sortedInput = true).expect("ok")
      check:
        dataRes.len() == 3
        dataRes[0] == Opt.some(keyValue1)
        dataRes[1] == Opt.some(keyValue2)
        dataRes[2] == Opt.none(seq[byte])

    block:
      let
        keys =
          @[
            keyValue1, keyValue2, keyValue3, keyValue4, keyValue5, keyValue6, keyValue7,
            keyValue8, keyValue9,
          ]
        dataRes = db.multiGet(keys).expect("ok")
      check:
        dataRes.len() == 9
        dataRes[0] == Opt.some(keyValue1)
        dataRes[1] == Opt.some(keyValue2)
        dataRes[2] == Opt.none(seq[byte])
        dataRes[3] == Opt.none(seq[byte])
        dataRes[4] == Opt.some(keyValue5)
        dataRes[5] == Opt.none(seq[byte])
        dataRes[6] == Opt.some(keyValue7)
        dataRes[7] == Opt.none(seq[byte])
        dataRes[8] == Opt.some(keyValue9)

  test "Test multiget - array":
    let
      keyValue1 = @[1.byte]
      keyValue2 = @[2.byte]
      keyValue3 = @[3.byte]
      keyValue4 = @[4.byte]
      keyValue5 = @[5.byte]
      keyValue6 = @[6.byte]
      keyValue7 = @[7.byte]
      keyValue8 = @[8.byte]
      keyValue9 = @[9.byte]

    check:
      db.put(keyValue1, keyValue1).isOk()
      db.put(keyValue2, keyValue2).isOk()
      db.put(keyValue5, keyValue5).isOk()
      db.put(keyValue7, keyValue7).isOk()
      db.put(keyValue9, keyValue9).isOk()
      db.keyExists(keyValue1).get() == true
      db.keyExists(keyValue2).get() == true
      db.keyExists(keyValue3).get() == false

    block:
      let dataRes = db.multiGet([keyValue1]).expect("ok")
      check:
        dataRes.len() == 1
        dataRes[0] == Opt.some(keyValue1)

    block:
      let dataRes = db.multiGet([keyValue1, keyValue2]).expect("ok")
      check:
        dataRes.len() == 2
        dataRes[0] == Opt.some(keyValue1)
        dataRes[1] == Opt.some(keyValue2)

    block:
      let dataRes = db.multiGet([keyValue2, keyValue3]).expect("ok")
      check:
        dataRes.len() == 2
        dataRes[0] == Opt.some(keyValue2)
        dataRes[1] == Opt.none(seq[byte])

    block:
      let dataRes = db.multiGet([keyValue1, keyValue2, keyValue3]).expect("ok")
      check:
        dataRes.len() == 3
        dataRes[0] == Opt.some(keyValue1)
        dataRes[1] == Opt.some(keyValue2)
        dataRes[2] == Opt.none(seq[byte])

    block:
      let dataRes =
        db.multiGet([keyValue1, keyValue2, keyValue3], sortedInput = true).expect("ok")
      check:
        dataRes.len() == 3
        dataRes[0] == Opt.some(keyValue1)
        dataRes[1] == Opt.some(keyValue2)
        dataRes[2] == Opt.none(seq[byte])
