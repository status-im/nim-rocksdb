# Nim-RocksDB
# Copyright 2024 Status Research & Development GmbH
# Licensed under either of
#
#  * Apache License, version 2.0, ([LICENSE-APACHE](LICENSE-APACHE) or http://www.apache.org/licenses/LICENSE-2.0)
#  * GPL license, version 2.0, ([LICENSE-GPLv2](LICENSE-GPLv2) or https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)
#
# at your option. This file may not be copied, modified, or distributed except according to those terms.

{.used.}

import std/os, tempfile, unittest2, ../rocksdb/[rocksdb, writebatchwi], ./test_helper

suite "WriteBatchWIRef Tests":
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
      db = initReadWriteDb(dbPath, columnFamilyNames = @[CF_DEFAULT, CF_OTHER])
      defaultCfHandle = db.getColFamilyHandle(CF_DEFAULT).get()
      otherCfHandle = db.getColFamilyHandle(CF_OTHER).get()

  teardown:
    db.close()
    removeDir($dbPath)

  test "Test writing batch to the default column family":
    let batch = db.openWriteBatchWithIndex()
    defer:
      batch.close()
    check not batch.isClosed()

    check:
      batch.put(key1, val1).isOk()
      batch.put(key2, val2).isOk()
      batch.put(key3, val3).isOk()
      batch.count() == 3

      batch.delete(key2).isOk()
      batch.count() == 4
      not batch.isClosed()

      batch.getFromBatch(key1).get() == val1
      batch.getFromBatch(key2).isErr()
      batch.getFromBatch(key3).get() == val3

    let res = db.write(batch)
    check:
      res.isOk()
      db.write(batch).isOk() # test that it's idempotent
      db.get(key1).get() == val1
      db.keyExists(key2).get() == false
      db.get(key3).get() == val3

      batch.getFromBatch(key1).get() == val1
      batch.getFromBatch(key2).isErr()
      batch.getFromBatch(key3).get() == val3

    batch.clear()
    check:
      batch.count() == 0
      not batch.isClosed()

  test "Test writing batch to column family":
    let batch = db.openWriteBatchWithIndex()
    defer:
      batch.close()
    check not batch.isClosed()

    check:
      batch.put(key1, val1, otherCfHandle).isOk()
      batch.put(key2, val2, otherCfHandle).isOk()
      batch.put(key3, val3, otherCfHandle).isOk()
      batch.count() == 3

      batch.delete(key2, otherCfHandle).isOk()
      batch.count() == 4
      not batch.isClosed()

      batch.getFromBatch(key1, otherCfHandle).get() == val1
      batch.getFromBatch(key2, otherCfHandle).isErr()
      batch.getFromBatch(key3, otherCfHandle).get() == val3

    let res = db.write(batch)
    check:
      res.isOk()
      db.get(key1, otherCfHandle).get() == val1
      db.keyExists(key2, otherCfHandle).get() == false
      db.get(key3, otherCfHandle).get() == val3

      batch.getFromBatch(key1, otherCfHandle).get() == val1
      batch.getFromBatch(key2, otherCfHandle).isErr()
      batch.getFromBatch(key3, otherCfHandle).get() == val3

    batch.clear()
    check:
      batch.count() == 0
      not batch.isClosed()

  test "Test writing to multiple column families in single batch":
    let batch = db.openWriteBatchWithIndex()
    defer:
      batch.close()
    check not batch.isClosed()

    check:
      batch.put(key1, val1, defaultCfHandle).isOk()
      batch.put(key1, val1, otherCfHandle).isOk()
      batch.put(key2, val2, otherCfHandle).isOk()
      batch.put(key3, val3, otherCfHandle).isOk()
      batch.count() == 4

      batch.delete(key2, otherCfHandle).isOk()
      batch.count() == 5
      not batch.isClosed()

    let res = db.write(batch)
    check:
      res.isOk()
      db.get(key1, defaultCfHandle).get() == val1
      db.get(key1, otherCfHandle).get() == val1
      db.keyExists(key2, otherCfHandle).get() == false
      db.get(key3, otherCfHandle).get() == val3

    batch.clear()
    check:
      batch.count() == 0
      not batch.isClosed()

  test "Test writing to multiple column families in multiple batches":
    let
      batch1 = db.openWriteBatchWithIndex()
      batch2 = db.openWriteBatchWithIndex()
    defer:
      batch1.close()
      batch2.close()

    check:
      not batch1.isClosed()
      not batch2.isClosed()
      batch1.put(key1, val1).isOk()
      batch1.delete(key2, otherCfHandle).isOk()
      batch1.put(key3, val3, otherCfHandle).isOk()
      batch2.put(key1, val1, otherCfHandle).isOk()
      batch2.delete(key1, otherCfHandle).isOk()
      batch2.put(key3, val3).isOk()
      batch1.count() == 3
      batch2.count() == 3

    let res1 = db.write(batch1)
    let res2 = db.write(batch2)
    check:
      res1.isOk()
      res2.isOk()
      db.get(key1).get() == val1
      db.keyExists(key2).get() == false
      db.get(key3).get() == val3
      db.keyExists(key1, otherCfHandle).get() == false
      db.keyExists(key2, otherCfHandle).get() == false
      db.get(key3, otherCfHandle).get() == val3

      # Write batch is unchanged after write
      batch1.count() == 3
      batch2.count() == 3
      not batch1.isClosed()
      not batch2.isClosed()

  test "Test write empty batch":
    let batch = db.openWriteBatchWithIndex()
    defer:
      batch.close()
    check not batch.isClosed()

    check batch.count() == 0
    let res1 = db.write(batch)
    check:
      res1.isOk()
      batch.count() == 0
      not batch.isClosed()

  test "Test multiple writes to same key":
    let
      batch1 = db.openWriteBatchWithIndex(overwriteKey = false)
      batch2 = db.openWriteBatchWithIndex(overwriteKey = true)
    defer:
      batch1.close()
      batch2.close()
    check:
      not batch1.isClosed()
      not batch2.isClosed()

    check:
      batch1.put(key1, val1).isOk()
      batch1.delete(key1).isOk()
      batch1.put(key1, val3).isOk()
      batch1.count() == 3
      batch1.getFromBatch(key1).get() == val3

      batch2.put(key1, val3).isOk()
      batch2.put(key1, val2).isOk()
      batch2.put(key1, val1).isOk()
      batch2.count() == 3
      batch2.getFromBatch(key1).get() == val1

  test "Put, get and delete empty key":
    let batch = db.openWriteBatchWithIndex()
    defer:
      batch.close()

    let empty: seq[byte] = @[]
    check:
      batch.put(empty, val1).isOk()
      batch.getFromBatch(empty).get() == val1
      batch.delete(empty).isOk()
      batch.getFromBatch(empty).isErr()

  test "Test close":
    let batch = db.openWriteBatchWithIndex()

    check not batch.isClosed()
    batch.close()
    check batch.isClosed()
    batch.close()
    check batch.isClosed()
