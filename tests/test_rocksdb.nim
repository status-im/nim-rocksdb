# Nim-RocksDB
# Copyright 2018-2019 Status Research & Development GmbH
# Licensed under either of
#
#  * Apache License, version 2.0, ([LICENSE-APACHE](LICENSE-APACHE) or http://www.apache.org/licenses/LICENSE-2.0)
#  * GPL license, version 2.0, ([LICENSE-GPLv2](LICENSE-GPLv2) or https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)
#
# at your option. This file may not be copied, modified, or distributed except according to those terms.

import
  os, unittest,
  tempfile,
  ../rocksdb

type
  MyDB = object
    rocksdb: RocksDBInstance

# TODO no tests for failures / error reporting

proc initMyDb(path: string): MyDB =
  let
    dataDir = path / "data"
    backupsDir = path / "backups"

  createDir(dataDir)
  createDir(backupsDir)

  var s = result.rocksdb.init(dataDir, backupsDir)
  doAssert s.ok, $s

suite "Nim API tests":
  setup:
    var
      dbDir = mkdtemp()
      db = initMyDb(dbDir)

  teardown:
    close(db.rocksdb)
    removeDir(dbDir)

  test "Basic operations":
    let key = @[byte(1), 2, 3, 4, 5]
    let otherKey = @[byte(1), 2, 3, 4, 5, 6]
    let val = @[byte(1), 2, 3, 4, 5]

    var s = db.rocksdb.put(key, val)
    check s.ok

    var r1 = db.rocksdb.getBytes(key)
    check r1.ok and r1.value == val

    var r2 = db.rocksdb.getBytes(otherKey)
    # there's no error string for missing keys
    check r2.ok == false and r2.error.len == 0

    var e1 = db.rocksdb.contains(key)
    check e1.ok and e1.value == true

    var e2 = db.rocksdb.contains(otherKey)
    check e2.ok and e2.value == false

    s = db.rocksdb.del(key)
    check s.ok

    e1 = db.rocksdb.contains(key)
    check e1.ok and e1.value == false

