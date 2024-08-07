# Nim-RocksDB
# Copyright 2024 Status Research & Development GmbH
# Licensed under either of
#
#  * Apache License, version 2.0, ([LICENSE-APACHE](LICENSE-APACHE) or http://www.apache.org/licenses/LICENSE-2.0)
#  * GPL license, version 2.0, ([LICENSE-GPLv2](LICENSE-GPLv2) or https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)
#
# at your option. This file may not be copied, modified, or distributed except according to those terms.

{.used.}

import std/os, tempfile, unittest2, ../rocksdb/optimistictxdb, ./test_helper

suite "OptimisticTxDbRef Tests":
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
      db = initOptimisticTxDb(dbPath, columnFamilyNames = @[CF_OTHER])
      defaultCfHandle = db.getColFamilyHandle(CF_DEFAULT).get()
      otherCfHandle = db.getColFamilyHandle(CF_OTHER).get()

  teardown:
    db.close()
    removeDir($dbPath)

  # test multiple transactions
  test "Test rollback using default column family":
    var tx = db.beginTransaction()
    defer:
      tx.close()
    check not tx.isClosed()

    check:
      tx.put(key1, val1).isOk()
      tx.put(key2, val2).isOk()
      tx.put(key3, val3).isOk()

      tx.delete(key2).isOk()
      not tx.isClosed()

    check:
      tx.get(key1).get() == val1
      tx.get(key2).error() == ""
      tx.get(key3).get() == val3

    let res = tx.rollback()
    check:
      res.isOk()
      tx.get(key1).error() == ""
      tx.get(key2).error() == ""
      tx.get(key3).error() == ""

  test "Test commit using default column family":
    var tx = db.beginTransaction()
    defer:
      tx.close()
    check not tx.isClosed()

    check:
      tx.put(key1, val1).isOk()
      tx.put(key2, val2).isOk()
      tx.put(key3, val3).isOk()

      tx.delete(key2).isOk()
      not tx.isClosed()

    check:
      tx.get(key1).get() == val1
      tx.get(key2).error() == ""
      tx.get(key3).get() == val3

    let res = tx.commit()
    check:
      res.isOk()
      tx.get(key1).get() == val1
      tx.get(key2).error() == ""
      tx.get(key3).get() == val3

  test "Test setting column family in beginTransaction":
    var tx = db.beginTransaction(cfHandle = otherCfHandle)
    defer:
      tx.close()
    check not tx.isClosed()

    check:
      tx.put(key1, val1).isOk()
      tx.put(key2, val2).isOk()
      tx.put(key3, val3).isOk()

      tx.delete(key2).isOk()
      not tx.isClosed()

    check:
      tx.get(key1, defaultCfHandle).error() == ""
      tx.get(key2, defaultCfHandle).error() == ""
      tx.get(key3, defaultCfHandle).error() == ""
      tx.get(key1, otherCfHandle).get() == val1
      tx.get(key2, otherCfHandle).error() == ""
      tx.get(key3, otherCfHandle).get() == val3

  test "Test rollback and commit with multiple transactions":
    var tx1 = db.beginTransaction(cfHandle = defaultCfHandle)
    defer:
      tx1.close()
    check not tx1.isClosed()
    var tx2 = db.beginTransaction(cfHandle = otherCfHandle)
    defer:
      tx2.close()
    check not tx2.isClosed()

    check:
      tx1.put(key1, val1).isOk()
      tx1.put(key2, val2).isOk()
      tx1.put(key3, val3).isOk()
      tx1.delete(key2).isOk()
      not tx1.isClosed()
      tx2.put(key1, val1).isOk()
      tx2.put(key2, val2).isOk()
      tx2.put(key3, val3).isOk()
      tx2.delete(key2).isOk()
      not tx2.isClosed()

    check:
      tx1.get(key1, defaultCfHandle).get() == val1
      tx1.get(key2, defaultCfHandle).error() == ""
      tx1.get(key3, defaultCfHandle).get() == val3
      tx1.get(key1, otherCfHandle).error() == ""
      tx1.get(key2, otherCfHandle).error() == ""
      tx1.get(key3, otherCfHandle).error() == ""

      tx2.get(key1, defaultCfHandle).error() == ""
      tx2.get(key2, defaultCfHandle).error() == ""
      tx2.get(key3, defaultCfHandle).error() == ""
      tx2.get(key1, otherCfHandle).get() == val1
      tx2.get(key2, otherCfHandle).error() == ""
      tx2.get(key3, otherCfHandle).get() == val3

    block:
      let res = tx1.rollback()
      check:
        res.isOk()
        tx1.get(key1, defaultCfHandle).error() == ""
        tx1.get(key2, defaultCfHandle).error() == ""
        tx1.get(key3, defaultCfHandle).error() == ""
        tx1.get(key1, otherCfHandle).error() == ""
        tx1.get(key2, otherCfHandle).error() == ""
        tx1.get(key3, otherCfHandle).error() == ""

    block:
      let res = tx2.commit()
      check:
        res.isOk()
        tx2.get(key1, defaultCfHandle).error() == ""
        tx2.get(key2, defaultCfHandle).error() == ""
        tx2.get(key3, defaultCfHandle).error() == ""
        tx2.get(key1, otherCfHandle).get() == val1
        tx2.get(key2, otherCfHandle).error() == ""
        tx2.get(key3, otherCfHandle).get() == val3

  test "Test close":
    var tx = db.beginTransaction()

    check not tx.isClosed()
    tx.close()
    check tx.isClosed()
    tx.close()
    check tx.isClosed()

    check not db.isClosed()
    db.close()
    check db.isClosed()
    db.close()
    check db.isClosed()

  test "Test close multiple tx":
    var tx1 = db.beginTransaction()
    var tx2 = db.beginTransaction()

    check not db.isClosed()
    check not tx1.isClosed()
    tx1.close()
    check tx1.isClosed()
    tx1.close()
    check tx1.isClosed()

    check not db.isClosed()
    check not tx2.isClosed()
    tx2.close()
    check tx2.isClosed()
    tx2.close()
    check tx2.isClosed()

  test "Test auto close enabled":
    let
      dbPath = mkdtemp() / "autoclose-enabled"
      dbOpts = defaultDbOptions(autoClose = true)
      columnFamilies =
        @[
          initColFamilyDescriptor(CF_DEFAULT, defaultColFamilyOptions(autoClose = true))
        ]
      db = openOptimisticTxDb(dbPath, dbOpts, columnFamilies).get()

    check:
      dbOpts.isClosed() == false
      columnFamilies[0].isClosed() == false
      db.isClosed() == false

    db.close()

    check:
      dbOpts.isClosed() == true
      columnFamilies[0].isClosed() == true
      db.isClosed() == true

  test "Test auto close enabled":
    let
      dbPath = mkdtemp() / "autoclose-disabled"
      dbOpts = defaultDbOptions(autoClose = false)
      columnFamilies =
        @[
          initColFamilyDescriptor(
            CF_DEFAULT, defaultColFamilyOptions(autoClose = false)
          )
        ]
      db = openOptimisticTxDb(dbPath, dbOpts, columnFamilies).get()

    check:
      dbOpts.isClosed() == false
      columnFamilies[0].isClosed() == false
      db.isClosed() == false

    db.close()

    check:
      dbOpts.isClosed() == false
      columnFamilies[0].isClosed() == false
      db.isClosed() == true

  test "Test auto close tx enabled":
    let
      readOpts = defaultReadOptions(autoClose = true)
      writeOpts = defaultWriteOptions(autoClose = true)
      otxOpts = defaultOptimisticTxOptions(autoClose = true)
      tx = db.beginTransaction(readOpts, writeOpts, otxOpts)

    check:
      readOpts.isClosed() == false
      writeOpts.isClosed() == false
      otxOpts.isClosed() == false
      tx.isClosed() == false

    tx.close()

    check:
      readOpts.isClosed() == true
      writeOpts.isClosed() == true
      otxOpts.isClosed() == true
      tx.isClosed() == true

  test "Test auto close tx disabled":
    let
      readOpts = defaultReadOptions(autoClose = false)
      writeOpts = defaultWriteOptions(autoClose = false)
      otxOpts = defaultOptimisticTxOptions(autoClose = false)
      tx = db.beginTransaction(readOpts, writeOpts, otxOpts)

    check:
      readOpts.isClosed() == false
      writeOpts.isClosed() == false
      otxOpts.isClosed() == false
      tx.isClosed() == false

    tx.close()

    check:
      readOpts.isClosed() == false
      writeOpts.isClosed() == false
      otxOpts.isClosed() == false
      tx.isClosed() == true
