# Nim-RocksDB
# Copyright 2024 Status Research & Development GmbH
# Licensed under either of
#
#  * Apache License, version 2.0, ([LICENSE-APACHE](LICENSE-APACHE) or http://www.apache.org/licenses/LICENSE-2.0)
#  * GPL license, version 2.0, ([LICENSE-GPLv2](LICENSE-GPLv2) or https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)
#
# at your option. This file may not be copied, modified, or distributed except according to those terms.

{.used.}

import unittest2, ../../rocksdb/options/cache

suite "CacheRef Tests":
  test "Test cacheCreateLRU":
    let cache = cacheCreateLRU(1024 * 1024)
    check not cache.isClosed()
    cache.close()
    check cache.isClosed()

  test "Test cacheCreateLRU close idempotent":
    let cache = cacheCreateLRU(1024 * 1024)
    cache.close()
    cache.close()
    check cache.isClosed()

  test "Test cacheCreateHyperClock default (auto charge)":
    let cache = cacheCreateHyperClock(1024 * 1024)
    check not cache.isClosed()
    cache.close()
    check cache.isClosed()

  test "Test cacheCreateHyperClock explicit entry charge":
    let cache = cacheCreateHyperClock(1024 * 1024, estimatedEntryCharge = 8192)
    check not cache.isClosed()
    cache.close()
    check cache.isClosed()

  test "Test cacheCreateHyperClock close idempotent":
    let cache = cacheCreateHyperClock(1024 * 1024)
    cache.close()
    cache.close()
    check cache.isClosed()

  test "Test autoClose flag is stored":
    let cache = cacheCreateHyperClock(1024 * 1024, autoClose = true)
    check cache.autoClose == true
    cache.close()
