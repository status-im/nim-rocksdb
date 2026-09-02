# Nim-RocksDB
# Copyright 2024 Status Research & Development GmbH
# Licensed under either of
#
#  * Apache License, version 2.0, ([LICENSE-APACHE](LICENSE-APACHE) or http://www.apache.org/licenses/LICENSE-2.0)
#  * GPL license, version 2.0, ([LICENSE-GPLv2](LICENSE-GPLv2) or https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)
#
# at your option. This file may not be copied, modified, or distributed except according to those terms.

{.used.}

import unittest2, ../../rocksdb/options/dbopts

suite "DbOptionsRef Tests":
  test "Test newDbOptions":
    let dbOpts = createDbOptions()

    check not dbOpts.cPtr.isNil()

    dbOpts.maxOpenFiles = 10
    dbOpts.createMissingColumnFamilies = false

    check:
      dbOpts.maxOpenFiles == 10
      not dbOpts.createMissingColumnFamilies

    dbOpts.close()

  test "Test set and get options":
    let dbOpts = createDbOptions()

    dbOpts.openFilesAsync = true
    dbOpts.infoLogLevel = InfoLogLevel.warnLevel
    dbOpts.maxBackgroundFlushes = 2
    dbOpts.walRecoveryMode = WalRecoveryMode.absoluteConsistency
    dbOpts.walCompression = WalCompressionType.zstdCompression
    dbOpts.enableStatistics()
    dbOpts.statisticsLevel = StatisticsLevel.exceptTimers
    dbOpts.trackAndVerifyWalsInManifest = true
    dbOpts.writeDbidToManifest = true
    dbOpts.writeIdentityFile = false
    dbOpts.readIoExecutorThreads = 4
    dbOpts.avoidUnnecessaryBlockingIo = true

    check:
      dbOpts.openFilesAsync
      dbOpts.infoLogLevel == InfoLogLevel.warnLevel
      dbOpts.maxBackgroundFlushes == 2
      dbOpts.walRecoveryMode == WalRecoveryMode.absoluteConsistency
      dbOpts.walCompression == WalCompressionType.zstdCompression
      dbOpts.statisticsLevel == StatisticsLevel.exceptTimers
      dbOpts.trackAndVerifyWalsInManifest
      dbOpts.writeDbidToManifest
      not dbOpts.writeIdentityFile
      dbOpts.readIoExecutorThreads == 4
      dbOpts.avoidUnnecessaryBlockingIo

    dbOpts.dumpMallocStats = true
    dbOpts.dbLogDir = "."
    dbOpts.walDir = "."

    dbOpts.close()

  test "Test close":
    let dbOpts = defaultDbOptions()

    check not dbOpts.isClosed()
    dbOpts.close()
    check dbOpts.isClosed()
    dbOpts.close()
    check dbOpts.isClosed()

  test "Test auto close enabled":
    let
      dbOpts = defaultDbOptions()
      cache = cacheCreateLRU(1000, autoClose = true)

    dbOpts.rowCache = cache

    check:
      dbOpts.isClosed() == false
      cache.isClosed() == false

    dbOpts.close()

    check:
      dbOpts.isClosed() == true
      cache.isClosed() == true
