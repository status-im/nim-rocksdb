# Nim-RocksDB
# Copyright 2024 Status Research & Development GmbH
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
  ../rocksdb/memoryusage,
  ../rocksdb/rocksdb,
  ../rocksdb/options/cache,
  ./test_helper

suite "MemoryUsage Tests":
  setup:
    let
      dbPath = mkdtemp() / "data"
      db = initReadWriteDb(dbPath)

  teardown:
    db.close()
    removeDir($dbPath)

  test "Collect memory usage from DB only":
    let consumers = createMemoryConsumers()
    check not consumers.isClosed()

    consumers.addDb(db)

    let usageRes = consumers.getApproximateMemoryUsage()
    check usageRes.isOk()

    let usage = usageRes.value()
    check not usage.isClosed()

    # Values are uint64 so always >= 0; just confirm the call succeeds and
    # the snapshot can be read without error.
    let _ = usage.memTableTotal()
    let _ = usage.memTableUnflushed()
    let _ = usage.memTableReadersTotal()
    let _ = usage.cacheTotal()

    usage.close()
    check usage.isClosed()

    consumers.close()
    check consumers.isClosed()

  test "Collect memory usage from DB and block cache":
    let cache = cacheCreateLRU(4 * 1024 * 1024) # 4 MiB test cache
    check not cache.isClosed()

    let consumers = createMemoryConsumers()
    consumers.addDb(db)
    consumers.addCache(cache)

    let usageRes = consumers.getApproximateMemoryUsage()
    check usageRes.isOk()

    let usage = usageRes.value()
    # cacheTotal reflects the registered cache; with an empty cache it is 0.
    let _ = usage.cacheTotal()

    usage.close()
    consumers.close()
    cache.close()

  test "Multiple snapshots from the same consumer set":
    let consumers = createMemoryConsumers()
    consumers.addDb(db)

    # Collect and discard two snapshots to confirm the consumer set is reusable.
    for _ in 0 ..< 2:
      let usage = consumers.getApproximateMemoryUsage().valueOr:
        fail()
        return
      usage.close()

    consumers.close()

  test "Close is idempotent":
    let consumers = createMemoryConsumers()
    let usage = consumers.getApproximateMemoryUsage().value()

    usage.close()
    usage.close() # should not crash

    consumers.close()
    consumers.close() # should not crash
