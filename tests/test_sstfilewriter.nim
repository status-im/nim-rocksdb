# Nim-RocksDB
# Copyright 2024 Status Research & Development GmbH
# Licensed under either of
#
#  * Apache License, version 2.0, ([LICENSE-APACHE](LICENSE-APACHE) or http://www.apache.org/licenses/LICENSE-2.0)
#  * GPL license, version 2.0, ([LICENSE-GPLv2](LICENSE-GPLv2) or https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)
#
# at your option. This file may not be copied, modified, or distributed except according to those terms.

{.used.}

import std/os, tempfile, unittest2, ../rocksdb/[rocksdb, sstfilewriter], ./test_helper

suite "SstFileWriterRef Tests":
  const
    CF_DEFAULT = "default"
    CF_OTHER = "other"

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
      sstFilePath = mkdtemp() / "sst"
      db = initReadWriteDb(dbPath, columnFamilyNames = @[CF_DEFAULT, CF_OTHER])
      defaultCfHandle = db.getColFamilyHandle(CF_DEFAULT).get()
      otherCfHandle = db.getColFamilyHandle(CF_OTHER).get()

  teardown:
    db.close()
    removeDir($dbPath)

  test "Write to sst file then load into db using default column family":
    let res = openSstFileWriter(sstFilePath)
    check res.isOk()
    let writer = res.get()
    defer:
      writer.close()

    check:
      writer.put(key1, val1).isOk()
      writer.put(key2, val2).isOk()
      writer.put(key3, val3).isOk()
      writer.delete(@[byte(4)]).isOk()
      writer.finish().isOk()

      db.ingestExternalFile(sstFilePath).isOk()
      db.get(key1).get() == val1
      db.get(key2).get() == val2
      db.get(key3).get() == val3

  test "Write to sst file then load into db using specific column family":
    let res = openSstFileWriter(sstFilePath)
    check res.isOk()
    let writer = res.get()
    defer:
      writer.close()

    check:
      writer.put(key1, val1).isOk()
      writer.put(key2, val2).isOk()
      writer.put(key3, val3).isOk()
      writer.finish().isOk()

      db.ingestExternalFile(sstFilePath, otherCfHandle).isOk()
      db.keyExists(key1, defaultCfHandle).get() == false
      db.keyExists(key2, defaultCfHandle).get() == false
      db.keyExists(key3, defaultCfHandle).get() == false
      db.get(key1, otherCfHandle).get() == val1
      db.get(key2, otherCfHandle).get() == val2
      db.get(key3, otherCfHandle).get() == val3

  test "Test close":
    let res = openSstFileWriter(sstFilePath)
    check res.isOk()
    let writer = res.get()

    check not writer.isClosed()
    writer.close()
    check writer.isClosed()
    writer.close()
    check writer.isClosed()

  test "Test auto close enabled":
    let
      dbOpts = defaultDbOptions(autoClose = true)
      writer = openSstFileWriter(sstFilePath, dbOpts).get()

    check:
      dbOpts.isClosed() == false
      writer.isClosed() == false

    writer.close()

    check:
      dbOpts.isClosed() == true
      writer.isClosed() == true

  test "Test auto close disabled":
    let
      dbOpts = defaultDbOptions(autoClose = false)
      writer = openSstFileWriter(sstFilePath, dbOpts).get()

    check:
      dbOpts.isClosed() == false
      writer.isClosed() == false

    writer.close()

    check:
      dbOpts.isClosed() == false
      writer.isClosed() == true
