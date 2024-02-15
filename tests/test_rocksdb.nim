# Nim-RocksDB
# Copyright 2018-2024 Status Research & Development GmbH
# Licensed under either of
#
#  * Apache License, version 2.0, ([LICENSE-APACHE](LICENSE-APACHE) or http://www.apache.org/licenses/LICENSE-2.0)
#  * GPL license, version 2.0, ([LICENSE-GPLv2](LICENSE-GPLv2) or https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)
#
# at your option. This file may not be copied, modified, or distributed except according to those terms.

{.used.}

import
  std/os,
  tempfile,
  unittest2,
  ../rocksdb

proc initMyDb(
    path: string,
    readOnly = false,
    columnFamilyNames = @["default"]): RocksDBInstance =

  let
    dataDir = path / "data"
    backupsDir = path / "backups"

  createDir(dataDir)
  createDir(backupsDir)

  var s = result.init(
      dataDir,
      backupsDir,
      readOnly = readOnly,
      columnFamilyNames = columnFamilyNames)
  doAssert s.isOk(), $s


suite "Nim API tests":
  const
    CF_DEFAULT = "default"
    CF_OTHER = "other"

  let
    key = @[byte(1), 2, 3, 4, 5]
    otherKey = @[byte(1), 2, 3, 4, 5, 6]
    val = @[byte(1), 2, 3, 4, 5]

  test "Basic operations":
    var
      dbDir = mkdtemp()
      db = initMyDb(dbDir)

    var s = db.put(key, val)
    check s.isOk()

    var bytes: seq[byte]
    check db.get(key, proc(data: openArray[byte]) = bytes = @data)[]
    check not db.get(
      otherkey, proc(data: openArray[byte]) = bytes = @data)[]

    var r1 = db.getBytes(key)
    check r1.isOk() and r1.value == val

    var r2 = db.getBytes(otherKey)
    # there's no error string for missing keys
    check r2.isOk() == false and r2.error.len == 0

    var e1 = db.contains(key)
    check e1.isOk() and e1.value == true

    var e2 = db.contains(otherKey)
    check e2.isOk() and e2.value == false

    var d = db.del(key)
    check d.isOk() and d.value == true

    e1 = db.contains(key)
    check e1.isOk() and e1.value == false

    d = db.del(otherKey)
    check d.isOk() and d.value == false

    close(db)

    # Open database in read only mode
    block:
      var
        readOnlyDb = initMyDb(dbDir, readOnly = true)

      var r = readOnlyDb.contains(key)
      check r.isOk() and r.value == false

      var r2 = readOnlyDb.put(key, @[123.byte])
      check r2.isErr()

      close(readOnlyDb)

    removeDir(dbDir)

  test "Basic operations - default column family":
    var
      dbDir = mkdtemp()
      db = initMyDb(dbDir, columnFamilyNames = @[CF_DEFAULT])

    var s = db.put(key, val, CF_DEFAULT)
    check s.isOk()

    var bytes: seq[byte]
    check db.get(key, proc(data: openArray[byte]) = bytes = @data, CF_DEFAULT)[]
    check not db.get(
      otherkey, proc(data: openArray[byte]) = bytes = @data, CF_DEFAULT)[]

    var r1 = db.getBytes(key)
    check r1.isOk() and r1.value == val

    var r2 = db.getBytes(otherKey)
    # there's no error string for missing keys
    check r2.isOk() == false and r2.error.len == 0

    var e1 = db.contains(key, CF_DEFAULT)
    check e1.isOk() and e1.value == true

    var e2 = db.contains(otherKey, CF_DEFAULT)
    check e2.isOk() and e2.value == false

    var d = db.del(key, CF_DEFAULT)
    check d.isOk() and d.value == true

    e1 = db.contains(key, CF_DEFAULT)
    check e1.isOk() and e1.value == false

    d = db.del(otherKey, CF_DEFAULT)
    check d.isOk() and d.value == false

    close(db)

    # Open database in read only mode
    block:
      var
        readOnlyDb = initMyDb(dbDir, readOnly = true, columnFamilyNames = @[CF_DEFAULT])

      var r = readOnlyDb.contains(key, CF_DEFAULT)
      check r.isOk() and r.value == false

      var r2 = readOnlyDb.put(key, @[123.byte], CF_DEFAULT)
      check r2.isErr()

      close(readOnlyDb)

    removeDir(dbDir)

  test "Basic operations - multiple column families":
    var
      dbDir = mkdtemp()
      db = initMyDb(dbDir, columnFamilyNames = @[CF_DEFAULT, CF_OTHER])

    var s = db.put(key, val, CF_DEFAULT)
    check s.isOk()

    var s2 = db.put(otherKey, val, CF_OTHER)
    check s2.isOk()

    var bytes: seq[byte]
    check db.get(key, proc(data: openArray[byte]) = bytes = @data, CF_DEFAULT)[]
    check not db.get(
      otherkey, proc(data: openArray[byte]) = bytes = @data, CF_DEFAULT)[]

    var bytes2: seq[byte]
    check db.get(otherKey, proc(data: openArray[byte]) = bytes2 = @data, CF_OTHER)[]
    check not db.get(
      key, proc(data: openArray[byte]) = bytes2 = @data, CF_OTHER)[]

    var e1 = db.contains(key, CF_DEFAULT)
    check e1.isOk() and e1.value == true
    var e2 = db.contains(otherKey, CF_DEFAULT)
    check e2.isOk() and e2.value == false

    var e3 = db.contains(key, CF_OTHER)
    check e3.isOk() and e3.value == false
    var e4 = db.contains(otherKey, CF_OTHER)
    check e4.isOk() and e4.value == true

    var d = db.del(key, CF_DEFAULT)
    check d.isOk() and d.value == true
    e1 = db.contains(key, CF_DEFAULT)
    check e1.isOk() and e1.value == false
    d = db.del(otherKey, CF_DEFAULT)
    check d.isOk() and d.value == false

    var d2 = db.del(key, CF_OTHER)
    check d2.isOk() and d2.value == false
    e3 = db.contains(key, CF_OTHER)
    check e3.isOk() and e3.value == false
    d2 = db.del(otherKey, CF_OTHER)
    check d2.isOk() and d2.value == true
    d2 = db.del(otherKey, CF_OTHER)
    check d2.isOk() and d2.value == false

    db.close()

    # Open database in read only mode
    block:
      var
        readOnlyDb = initMyDb(dbDir, readOnly = true, columnFamilyNames = @[CF_DEFAULT, CF_OTHER])

      var r = readOnlyDb.contains(key, CF_OTHER)
      check r.isOk() and r.value == false

      var r2 = readOnlyDb.put(key, @[123.byte], CF_OTHER)
      check r2.isErr()

      close(readOnlyDb)

    removeDir(dbDir)

  test "Close multiple times":
    var
      dbDir = mkdtemp()
      db = initMyDb(dbDir)
    check not db.db.isNil

    db.close()
    check db.db.isNil

    db.close()
    check db.db.isNil

    removeDir(dbDir)

  test "Unknown column family":
    const CF_UNKNOWN = "unknown"

    var
      dbDir = mkdtemp()
      db = initMyDb(dbDir, columnFamilyNames = @[CF_DEFAULT, CF_OTHER])

    let r = db.put(key, val, CF_UNKNOWN)
    check r.isErr() and r.error() == "rocksdb: unknown column family"

    var bytes: seq[byte]
    let r2 = db.get(key, proc(data: openArray[byte]) = bytes = @data, CF_UNKNOWN)
    check r2.isErr() and r2.error() == "rocksdb: unknown column family"

    let r3 = db.contains(key, CF_UNKNOWN)
    check r3.isErr() and r3.error() == "rocksdb: unknown column family"

    let r4 = db.del(key, CF_UNKNOWN)
    check r4.isErr() and r4.error() == "rocksdb: unknown column family"

    db.close()
    removeDir(dbDir)