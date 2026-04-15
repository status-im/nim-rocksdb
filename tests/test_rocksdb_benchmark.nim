# Nim-RocksDB
# Copyright 2018-2024 Status Research & Development GmbH
# Licensed under either of
#
#  * Apache License, version 2.0, ([LICENSE-APACHE](LICENSE-APACHE) or http://www.apache.org/licenses/LICENSE-2.0)
#  * GPL license, version 2.0, ([LICENSE-GPLv2](LICENSE-GPLv2) or https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)
#
# at your option. This file may not be copied, modified, or distributed except according to those terms.

#   RocksDB Read API Performance Benchmark
#   ======================================
#  
#   Benchmark Summary (16,384 keys × 128-byte values, up to 1M reads):
#  
#   Single-key reads (1M operations):
#     - get(callback):     ~0.82 us/key (~1.2M reads/sec)
#     - get(seq return):   ~1.46 us/key (~0.7M reads/sec)
#     - get(into buffer):  ~0.81 us/key (~1.2M reads/sec)
#  
#   Batched reads (400K operations, batch-size sweep):
#     - Best performer: multiGetIter(sorted) at batch=128/256 (~0.72-0.74 us/key)
#     - Async I/O: Modest but consistent gains in unsorted batched reads
#     - Sweet spot: batch size 64-128; diminishing returns beyond 128
#     - Iterator variant slightly faster than multiGet for all batch sizes

{.used.}

import
  std/[algorithm, os, strformat, strutils, times],
  tempfile,
  unittest2,
  ../rocksdb/rocksdb,
  ./test_helper

const benchmarkNameWidth = 52

proc benchmarkLine(name: string, elapsed: float, keyReads: int): string =
  let
    readsPerSecond = keyReads.float / elapsed
    microsecondsPerKey = (elapsed * 1_000_000.0) / keyReads.float
  "  " & alignLeft(name, benchmarkNameWidth) & " " & align(fmt"{elapsed:.4f}", 10) & " " &
    align(fmt"{readsPerSecond:.2f}", 14) & " " & align(
    fmt"{microsecondsPerKey:.4f}", 10
  )

proc benchmarkHeader(): string =
  "  " & alignLeft("benchmark", benchmarkNameWidth) & " " & align("elapsed(s)", 10) & " " &
    align("reads/s", 14) & " " & align("us/key", 10)

proc makeKey(i: int): seq[byte] =
  # Encode integer keys as fixed-width bytes so all APIs read identical keys.
  @[
    byte((i shr 24) and 0xFF),
    byte((i shr 16) and 0xFF),
    byte((i shr 8) and 0xFF),
    byte(i and 0xFF),
  ]

proc makeSortedReadKeys(
    keys: seq[seq[byte]], readIndexes: seq[int], keyReads, batchSize: int
): seq[seq[byte]] =
  result = newSeq[seq[byte]](keyReads)
  var batchStart = 0
  while batchStart < keyReads:
    let batchEnd = min(batchStart + batchSize, keyReads)
    var batchIndexes = readIndexes[batchStart ..< batchEnd]
    batchIndexes.sort()
    for offset, index in batchIndexes:
      result[batchStart + offset] = keys[index]
    batchStart = batchEnd

proc runBatchedBench(
    readDb: RocksDbRef,
    readKeys: seq[seq[byte]],
    sortedReadKeys: seq[seq[byte]],
    keyReads, batchSize: int,
): tuple[
  multiGetElapsed: float,
  multiGetIterElapsed: float,
  multiGetSortedElapsed: float,
  multiGetIterSortedElapsed: float,
  multiGetBytes: int64,
  multiGetIterBytes: int64,
  multiGetSortedBytes: int64,
  multiGetIterSortedBytes: int64,
] =
  var
    multiGetBytes = 0'i64
    multiGetIterBytes = 0'i64
    multiGetSortedBytes = 0'i64
    multiGetIterSortedBytes = 0'i64
    batchStart = 0

  let multiGetStart = epochTime()
  while batchStart < keyReads:
    let batchEnd = min(batchStart + batchSize, keyReads)
    let res = readDb.multiGet(readKeys.toOpenArray(batchStart, batchEnd - 1))
    check res.isOk()
    for valueOpt in res.value():
      check valueOpt.isSome()
      multiGetBytes += int64(valueOpt.get().len)
    batchStart = batchEnd
  let multiGetElapsed = epochTime() - multiGetStart

  batchStart = 0
  let multiGetIterStart = epochTime()
  while batchStart < keyReads:
    let batchEnd = min(batchStart + batchSize, keyReads)
    let res = readDb.multiGetIter(readKeys.toOpenArray(batchStart, batchEnd - 1))
    check res.isOk()
    for valueOpt in res.value():
      check valueOpt.isSome()
      multiGetIterBytes += int64(valueOpt.get().data().len)
    batchStart = batchEnd
  let multiGetIterElapsed = epochTime() - multiGetIterStart

  batchStart = 0
  let multiGetSortedStart = epochTime()
  while batchStart < keyReads:
    let batchEnd = min(batchStart + batchSize, keyReads)
    let res = readDb.multiGet(
      sortedReadKeys.toOpenArray(batchStart, batchEnd - 1), sortedInput = true
    )
    check res.isOk()
    for valueOpt in res.value():
      check valueOpt.isSome()
      multiGetSortedBytes += int64(valueOpt.get().len)
    batchStart = batchEnd
  let multiGetSortedElapsed = epochTime() - multiGetSortedStart

  batchStart = 0
  let multiGetIterSortedStart = epochTime()
  while batchStart < keyReads:
    let batchEnd = min(batchStart + batchSize, keyReads)
    let res = readDb.multiGetIter(
      sortedReadKeys.toOpenArray(batchStart, batchEnd - 1), sortedInput = true
    )
    check res.isOk()
    for valueOpt in res.value():
      check valueOpt.isSome()
      multiGetIterSortedBytes += int64(valueOpt.get().data().len)
    batchStart = batchEnd
  let multiGetIterSortedElapsed = epochTime() - multiGetIterSortedStart

  (
    multiGetElapsed, multiGetIterElapsed, multiGetSortedElapsed,
    multiGetIterSortedElapsed, multiGetBytes, multiGetIterBytes, multiGetSortedBytes,
    multiGetIterSortedBytes,
  )

suite "RocksDb Benchmark Tests":
  test "Benchmark get APIs":
    const
      keyCount = 16_384
      readCount = 1_000_000
      sweepReadCount = 400_000
      valueSize = 128
      warmupBatchSize = 32
      sweepBatchSizes = [8, 16, 32, 64, 128, 256]

    let benchmarkPath = mkdtemp() / "benchmark"
    defer:
      removeDir(benchmarkPath)

    let writeDb = initReadWriteDb(benchmarkPath)

    var keys = newSeq[seq[byte]](keyCount)
    for i in 0 ..< keyCount:
      keys[i] = makeKey(i)

      var value = newSeq[byte](valueSize)
      for j in 0 ..< valueSize:
        value[j] = byte((i + j) and 0xFF)

      check writeDb.put(keys[i], value).isOk()

    check writeDb.flush().isOk()
    writeDb.close()

    let syncReadDb = openRocksDbReadOnly(benchmarkPath).expect("open sync benchmark db")
    defer:
      syncReadDb.close()

    let asyncReadOpts = defaultReadOptions(autoClose = true)
    asyncReadOpts.asyncIo = true
    let asyncReadDb = openRocksDbReadOnly(benchmarkPath, readOpts = asyncReadOpts)
      .expect("open async benchmark db")
    defer:
      asyncReadDb.close()

    var
      readKeys = newSeq[seq[byte]](readCount)
      readIndexes = newSeq[int](readCount)
    for i in 0 ..< readCount:
      let index = ((i * 2654435761'i64) mod keyCount.int64).int
      readIndexes[i] = index
      readKeys[i] = keys[index]

    let
      sweepIndexes = readIndexes[0 ..< sweepReadCount]
      sweepKeys = readKeys[0 ..< sweepReadCount]

    # Warm-up to reduce one-off effects (cache and initialization noise).
    block:
      var warmupBytes = 0'i64
      for i in 0 ..< min(readCount, 20_000):
        let res = syncReadDb.get(readKeys[i])
        check res.isOk()
        warmupBytes += int64(res.value().len)
      check warmupBytes > 0

    block:
      var warmupBytes = 0'i64
      var batchStart = 0
      while batchStart < min(readCount, 20_000):
        let batchEnd = min(batchStart + warmupBatchSize, min(readCount, 20_000))
        let res = asyncReadDb.multiGet(readKeys.toOpenArray(batchStart, batchEnd - 1))
        check res.isOk()
        for valueOpt in res.value():
          check valueOpt.isSome()
          warmupBytes += int64(valueOpt.get().len)
        batchStart = batchEnd
      check warmupBytes > 0

    var
      callbackBytes = 0'i64
      seqGetBytes = 0'i64
      bufferGetBytes = 0'i64

    let callbackStart = epochTime()
    for key in readKeys:
      let res = syncReadDb.get(
        key,
        proc(data: openArray[byte]) =
          callbackBytes += int64(data.len),
      )
      check:
        res.isOk()
        res.value() == true
    let callbackElapsed = epochTime() - callbackStart

    let seqGetStart = epochTime()
    for key in readKeys:
      let res = syncReadDb.get(key)
      check res.isOk()
      seqGetBytes += int64(res.value().len)
    let seqGetElapsed = epochTime() - seqGetStart

    var buffer = newSeq[byte](valueSize)
    var dataLen = -1
    let bufferGetStart = epochTime()
    for key in readKeys:
      let res = syncReadDb.get(key, buffer, dataLen)
      check:
        res.isOk()
        res.value() == true
      bufferGetBytes += int64(dataLen)
    let bufferGetElapsed = epochTime() - bufferGetStart

    check:
      callbackBytes == seqGetBytes
      callbackBytes == bufferGetBytes

    debugEcho "RocksDB get benchmark (single-threaded):"
    debugEcho benchmarkHeader()
    debugEcho benchmarkLine("get(callback)", callbackElapsed, readCount)
    debugEcho benchmarkLine("get(seq return)", seqGetElapsed, readCount)
    debugEcho benchmarkLine("get(into buffer)", bufferGetElapsed, readCount)
    debugEcho "RocksDB batched read sweep (single-threaded):"
    debugEcho benchmarkHeader()

    for batchSize in sweepBatchSizes:
      let sortedSweepKeys =
        makeSortedReadKeys(keys, sweepIndexes, sweepReadCount, batchSize)
      let syncResults = runBatchedBench(
        syncReadDb, sweepKeys, sortedSweepKeys, sweepReadCount, batchSize
      )
      let asyncResults = runBatchedBench(
        asyncReadDb, sweepKeys, sortedSweepKeys, sweepReadCount, batchSize
      )
      let expectedSweepBytes = int64(sweepReadCount * valueSize)

      check:
        syncResults.multiGetBytes == expectedSweepBytes
        syncResults.multiGetIterBytes == expectedSweepBytes
        syncResults.multiGetSortedBytes == expectedSweepBytes
        syncResults.multiGetIterSortedBytes == expectedSweepBytes
        asyncResults.multiGetBytes == expectedSweepBytes
        asyncResults.multiGetIterBytes == expectedSweepBytes
        asyncResults.multiGetSortedBytes == expectedSweepBytes
        asyncResults.multiGetIterSortedBytes == expectedSweepBytes

      debugEcho benchmarkLine(
        fmt"multiGet(sync, batch={batchSize})",
        syncResults.multiGetElapsed,
        sweepReadCount,
      )
      debugEcho benchmarkLine(
        fmt"multiGet(async, batch={batchSize})",
        asyncResults.multiGetElapsed,
        sweepReadCount,
      )
      debugEcho benchmarkLine(
        fmt"multiGetIter(sync, batch={batchSize})",
        syncResults.multiGetIterElapsed,
        sweepReadCount,
      )
      debugEcho benchmarkLine(
        fmt"multiGetIter(async, batch={batchSize})",
        asyncResults.multiGetIterElapsed,
        sweepReadCount,
      )
      debugEcho benchmarkLine(
        fmt"multiGet(sync, sorted, batch={batchSize})",
        syncResults.multiGetSortedElapsed,
        sweepReadCount,
      )
      debugEcho benchmarkLine(
        fmt"multiGet(async, sorted, batch={batchSize})",
        asyncResults.multiGetSortedElapsed,
        sweepReadCount,
      )
      debugEcho benchmarkLine(
        fmt"multiGetIter(sync, sorted, batch={batchSize})",
        syncResults.multiGetIterSortedElapsed,
        sweepReadCount,
      )
      debugEcho benchmarkLine(
        fmt"multiGetIter(async, sorted, batch={batchSize})",
        asyncResults.multiGetIterSortedElapsed,
        sweepReadCount,
      )
