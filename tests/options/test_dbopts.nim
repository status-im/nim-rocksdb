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
  unittest2,
  ../../rocksdb/options/dbopts

suite "DbOptionsRef Tests":

  test "Test newDbOptions":
    var dbOpts = newDbOptions()

    check not dbOpts.cPtr.isNil()

    dbOpts.createIfMissing = true
    dbOpts.maxOpenFiles = 10
    dbOpts.createMissingColumnFamilies = false

    check:
      dbOpts.createIfMissing
      dbOpts.maxOpenFiles == 10
      not dbOpts.createMissingColumnFamilies

    dbOpts.close()

  test "Test close":
    var dbOpts = defaultDbOptions()

    check not dbOpts.isClosed()
    dbOpts.close()
    check dbOpts.isClosed()
    dbOpts.close()
    check dbOpts.isClosed()