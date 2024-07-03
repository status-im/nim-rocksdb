# Nim-RocksDB
# Copyright 2024 Status Research & Development GmbH
# Licensed under either of
#
#  * Apache License, version 2.0, ([LICENSE-APACHE](LICENSE-APACHE) or http://www.apache.org/licenses/LICENSE-2.0)
#  * GPL license, version 2.0, ([LICENSE-GPLv2](LICENSE-GPLv2) or https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)
#
# at your option. This file may not be copied, modified, or distributed except according to those terms.

{.used.}

import std/os, tempfile, unittest2, ../rocksdb/backup, ./test_helper

suite "BackupEngineRef Tests":
  let
    key = @[byte(1), 2, 3, 4, 5]
    val = @[byte(1), 2, 3, 4, 5]

  setup:
    let
      dbPath = mkdtemp() / "data"
      dbBackupPath = mkdtemp() / "backup"
      dbRestorePath = mkdtemp() / "restore"
      db = initReadWriteDb(dbPath)

  teardown:
    db.close()
    removeDir($dbPath)
    removeDir($dbBackupPath)
    removeDir($dbRestorePath)

  test "Test backup":
    let engine = initBackupEngine(dbBackupPath)

    check:
      db.put(key, val).isOk()
      db.keyExists(key).value()

    check engine.createNewBackup(db).isOk()

    check:
      db.delete(key).isOk()
      not db.keyExists(key).value()

    check engine.restoreDbFromLatestBackup(dbRestorePath).isOk()

    let db2 = initReadWriteDb(dbRestorePath)
    check db2.keyExists(key).value()
    db2.close()

    engine.close()

  test "Test close":
    let engine = openBackupEngine(dbPath).get()

    check not engine.isClosed()
    engine.close()
    check engine.isClosed()
    engine.close()
    check engine.isClosed()

  test "Test auto close enabled":
    let
      backupOpts = defaultBackupEngineOptions(dbPath, autoClose = true)
      backupEngine = openBackupEngine(dbPath, backupOpts).get()

    check:
      backupOpts.isClosed() == false
      backupEngine.isClosed() == false

    backupEngine.close()

    check:
      backupOpts.isClosed() == true
      backupEngine.isClosed() == true

  test "Test auto close disabled":
    let
      backupOpts = defaultBackupEngineOptions(dbPath, autoClose = false)
      backupEngine = openBackupEngine(dbPath, backupOpts).get()

    check:
      backupOpts.isClosed() == false
      backupEngine.isClosed() == false

    backupEngine.close()

    check:
      backupOpts.isClosed() == false
      backupEngine.isClosed() == true
