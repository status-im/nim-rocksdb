# Nim-RocksDB
# Copyright 2024 Status Research & Development GmbH
# Licensed under either of
#
#  * Apache License, version 2.0, ([LICENSE-APACHE](LICENSE-APACHE) or http://www.apache.org/licenses/LICENSE-2.0)
#  * GPL license, version 2.0, ([LICENSE-GPLv2](LICENSE-GPLv2) or https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)
#
# at your option. This file may not be copied, modified, or distributed except according to those terms.

{.push raises: [].}

import std/cpuinfo, ../lib/librocksdb, ./[cache, tableopts]

export cache, tableopts

type
  DbOptionsPtr* = ptr rocksdb_options_t

  DbOptionsRef* = ref object
    cPtr: DbOptionsPtr

proc newDbOptions*(): DbOptionsRef =
  DbOptionsRef(cPtr: rocksdb_options_create())

proc isClosed*(dbOpts: DbOptionsRef): bool {.inline.} =
  dbOpts.cPtr.isNil()

proc cPtr*(dbOpts: DbOptionsRef): DbOptionsPtr =
  doAssert not dbOpts.isClosed()
  dbOpts.cPtr

proc increaseParallelism*(dbOpts: DbOptionsRef, totalThreads: int) =
  doAssert totalThreads > 0
  doAssert not dbOpts.isClosed()
  rocksdb_options_increase_parallelism(dbOpts.cPtr, totalThreads.cint)

# Options roughly in the order found in `options.h`

template opt(nname, ntyp, ctyp: untyped) =
  proc `nname=`*(dbOpts: DbOptionsRef, value: ntyp) =
    doAssert not dbOpts.isClosed
    `rocksdb_options_set nname`(dbOpts.cPtr, value.ctyp)

  proc `nname`*(dbOpts: DbOptionsRef): ntyp =
    doAssert not dbOpts.isClosed
    ntyp `rocksdb_options_get nname`(dbOpts.cPtr)

opt createIfMissing, bool, uint8
opt createMissingColumnFamilies, bool, uint8
opt errorIfExists, bool, uint8
opt paranoidChecks, bool, uint8

opt maxOpenFiles, int, cint
opt maxFileOpeningThreads, int, cint
opt maxTotalWalSize, int, uint64
opt useFsync, bool, cint
opt deleteObsoleteFilesPeriodMicros, int, uint64
opt maxBackgroundJobs, int, cint
opt maxBackgroundCompactions, int, cint
opt maxSubcompactions, int, uint32
opt maxLogFileSize, int, csize_t
opt logFiletimeToRoll, int, csize_t
opt keepLogFileNum, int, csize_t
opt recycleLogFileNum, int, csize_t
opt maxManifestFileSize, int, csize_t
opt tableCacheNumshardbits, int, cint
opt walTtlSeconds, int, uint64
opt walSizeLimitMB, int, uint64
opt manifestPreallocationSize, int, csize_t
opt allowMmapReads, bool, uint8
opt allowMmapWrites, bool, uint8
opt useDirectReads, bool, uint8
opt useDirectIoForFlushAndCompaction, bool, uint8
opt isFdCloseOnExec, bool, uint8
opt statsDumpPeriodSec, int, cuint
opt statsPersistPeriodSec, int, cuint
opt adviseRandomOnOpen, bool, uint8
opt dbWriteBufferSize, int, csize_t
opt writableFileMaxBufferSize, int, csize_t
opt useAdaptiveMutex, bool, uint8
opt bytesPerSync, int, uint64
opt walBytesPerSync, int, uint64
opt enablePipelinedWrite, bool, uint8
opt unorderedWrite, bool, uint8
opt allowConcurrentMemtableWrite, bool, uint8
opt enableWriteThreadAdaptiveYield, bool, uint8
opt skipStatsUpdateOnDbOpen, bool, uint8
opt skipCheckingSstFileSizesOnDbOpen, bool, uint8
opt allowIngestBehind, bool, uint8
opt manualWalFlush, bool, uint8
opt atomicFlush, bool, uint8
opt avoidUnnecessaryBlockingIo, bool, uint8

proc `rowCache=`*(dbOpts: DbOptionsRef, cache: CacheRef) =
  doAssert not dbOpts.isClosed()
  rocksdb_options_set_row_cache(dbOpts.cPtr, cache.cPtr)

proc defaultDbOptions*(): DbOptionsRef =
  let opts: DbOptionsRef = newDbOptions()

  # Optimize RocksDB. This is the easiest way to get RocksDB to perform well:
  opts.increaseParallelism(countProcessors())
  opts.createIfMissing = true

  # Enable creating column families if they do not exist
  opts.createMissingColumnFamilies = true

  # Options recommended by rocksdb devs themselves, for new databases
  # https://github.com/facebook/rocksdb/wiki/Setup-Options-and-Basic-Tuning#other-general-options

  opts.maxBackgroundJobs = 6
  opts.bytesPerSync = 1048576

  opts

proc close*(dbOpts: DbOptionsRef) =
  if not dbOpts.isClosed():
    rocksdb_options_destroy(dbOpts.cPtr)
    dbOpts.cPtr = nil
