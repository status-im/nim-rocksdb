# Nim-RocksDB
# Copyright 2024 Status Research & Development GmbH
# Licensed under either of
#
#  * Apache License, version 2.0, ([LICENSE-APACHE](LICENSE-APACHE) or http://www.apache.org/licenses/LICENSE-2.0)
#  * GPL license, version 2.0, ([LICENSE-GPLv2](LICENSE-GPLv2) or https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)
#
# at your option. This file may not be copied, modified, or distributed except according to those terms.

{.used.}

import unittest2, ../../rocksdb/options/tableopts

suite "TableOptionsRef Tests":
  test "Test createTableOptions":
    let tableOpts = createTableOptions()

    check not tableOpts.cPtr.isNil()

    tableOpts.close()

  test "Test defaultTableOptions":
    let tableOpts = defaultTableOptions()

    check not tableOpts.cPtr.isNil()

    tableOpts.close()

  test "Test close":
    let tableOpts = defaultTableOptions()

    check not tableOpts.isClosed()
    tableOpts.close()
    check tableOpts.isClosed()
    tableOpts.close()
    check tableOpts.isClosed()

  test "Test auto close enabled":
    let
      tableOpts = defaultTableOptions()
      cache = cacheCreateLRU(1000, autoClose = true)
      filter = createRibbon(9.9)

    tableOpts.blockCache = cache
    tableOpts.filterPolicy = filter

    check:
      tableOpts.isClosed() == false
      cache.isClosed() == false
      filter.isClosed() == true # closed because tableopts takes ownership

    tableOpts.close()

    check:
      tableOpts.isClosed() == true
      cache.isClosed() == true
      filter.isClosed() == true

  test "Test auto close disabled":
    let
      tableOpts = defaultTableOptions()
      cache = cacheCreateLRU(1000, autoClose = false)
      filter = createRibbon(9.9)

    tableOpts.blockCache = cache
    tableOpts.filterPolicy = filter

    check:
      tableOpts.isClosed() == false
      cache.isClosed() == false
      filter.isClosed() == true # closed because tableopts takes ownership

    tableOpts.close()

    check:
      tableOpts.isClosed() == true
      cache.isClosed() == false
      filter.isClosed() == true
