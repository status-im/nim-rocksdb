# Nim-RocksDB
# Copyright 2024 Status Research & Development GmbH
# Licensed under either of
#
#  * Apache License, version 2.0, ([LICENSE-APACHE](LICENSE-APACHE) or http://www.apache.org/licenses/LICENSE-2.0)
#  * GPL license, version 2.0, ([LICENSE-GPLv2](LICENSE-GPLv2) or https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)
#
# at your option. This file may not be copied, modified, or distributed except according to those terms.

{.used.}

import unittest2, ../../rocksdb/columnfamily/cfopts

suite "ColFamilyOptionsRef Tests":
  test "Test close":
    var cfOpts = defaultColFamilyOptions()

    check not cfOpts.isClosed()
    cfOpts.close()
    check cfOpts.isClosed()
    cfOpts.close()
    check cfOpts.isClosed()

  test "Test auto close enabled":
    let
      cfOpts = defaultColFamilyOptions()
      tableOpts = defaultTableOptions(autoClose = true)
      sliceTransform = createFixedPrefix(1000)

    cfOpts.blockBasedTableFactory = tableOpts
    cfOpts.setPrefixExtractor(sliceTransform)

    check:
      cfOpts.isClosed() == false
      tableOpts.isClosed() == false
      sliceTransform.isClosed() == true # closed because tableopts takes ownership

    cfOpts.close()

    check:
      cfOpts.isClosed() == true
      tableOpts.isClosed() == true
      sliceTransform.isClosed() == true

  test "Test auto close disabled":
    let
      cfOpts = defaultColFamilyOptions()
      tableOpts = defaultTableOptions(autoClose = false)
      sliceTransform = createFixedPrefix(1000)

    cfOpts.blockBasedTableFactory = tableOpts
    cfOpts.setPrefixExtractor(sliceTransform)

    check:
      cfOpts.isClosed() == false
      tableOpts.isClosed() == false
      sliceTransform.isClosed() == true # closed because tableopts takes ownership

    cfOpts.close()

    check:
      cfOpts.isClosed() == true
      tableOpts.isClosed() == false
      sliceTransform.isClosed() == true
