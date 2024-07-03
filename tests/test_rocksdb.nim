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
        bytes = @data
      ,
    )[]
    check not db.get(
      otherKey,
      proc(data: openArray[byte]) =
        bytes = @data
      ,
    )[]

    var r1 = db.get(key)
    check r1.isOk() and r1.value == val

    var r2 = db.get(otherKey)
    # there's no error string for missing keys
    check r2.isOk() == false and r2.error.len == 0

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
        bytes = @data
      ,
      defaultCfHandle,
    )[]
    check not db.get(
      otherKey,
      proc(data: openArray[byte]) =
        bytes = @data
      ,
      defaultCfHandle,
    )[]

    var r1 = db.get(key)
    check r1.isOk() and r1.value == val

    var r2 = db.get(otherKey)
    # there's no error string for missing keys
    check r2.isOk() == false and r2.error.len == 0

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
        bytes = @data
      ,
      defaultCfHandle,
    )[]
    check not db.get(
      otherKey,
      proc(data: openArray[byte]) =
        bytes = @data
      ,
      defaultCfHandle,
    )[]

    var bytes2: seq[byte]
    check db.get(
      otherKey,
      proc(data: openArray[byte]) =
        bytes2 = @data
      ,
      otherCfHandle,
    )[]
    check not db.get(
      key,
      proc(data: openArray[byte]) =
        bytes2 = @data
      ,
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
          v = @data
        ,
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
          v = @data
        ,
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
          v = @data
        ,
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
          v = @data
        ,
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
          v = @data
        ,
      )
      check:
        r.isOk()
        r.value() == false
        v.len() == 0
        db.get(key5).isErr()

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
    let cfDescriptor = initColFamilyDescriptor(CF_DEFAULT, cfOpts)
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
