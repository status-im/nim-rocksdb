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
#     - get(callback):     ~0.80 us/key (~1.2M reads/sec)
#     - get(seq return):   ~1.28 us/key (~0.8M reads/sec)
#     - get(into buffer):  ~0.78 us/key (~1.3M reads/sec)
#  
#   Batched reads (400K operations, batch-size sweep):
#     - Best performer: multiGet(buffers, sorted) at batch >= 32
#       (~0.59-0.61 us/key)
#     - The buffer variant is fastest at every batch size, sorted or not: it
#       writes into caller-owned memory, so it skips the seq allocated per
#       value that the other two variants pay for
#     - Ranking is consistent across the sweep: multiGet(buffers) ~0.59-0.74,
#       multiGetIter ~0.72-0.87, multiGet ~0.97-1.16 us/key
#     - Async I/O: Modest but consistent gains in unsorted batched reads
#     - Sweet spot: batch size 64-128; diminishing returns beyond 128
#     - The buffer variant takes at most MULTI_GET_MAX_KEYS keys per call, so
#       the sweep skips it for batch sizes above that limit
#
#   The read API benchmarks above run from a temporary directory, which is
#   normally memory backed, and so compare the cost of the APIs themselves
#   rather than the cost of reaching storage.
#
#   The last benchmark measures something different: what linking liburing into
#   the RocksDb build is worth, by running the batched reads with the io_uring
#   paths enabled and disabled.
#
#   RocksDb only uses io_uring when both of these hold:
#     1. It was compiled with ROCKSDB_IOURING_PRESENT, which requires liburing
#        to be present at build time (see scripts/build_static_deps.sh).
#     2. The weak symbol `RocksDbIOUringEnable` is defined and returns true.
#        nim-rocksdb defines it in lib/librocksdb.nim, enabled by default on
#        Linux static builds and controllable through setIoUringEnabled.
#
#   This benchmark uses setIoUringEnabled to turn the io_uring paths on and off
#   at runtime. Turning them off reproduces what a build without liburing does:
#   PosixRandomAccessFile::MultiRead sees a null ring and defers to
#   FSRandomAccessFile::MultiRead, which reads each request in turn. Measuring
#   both from one process keeps the data, the key order and the machine state
#   identical across the comparison.
#
#   That benchmark reads with direct I/O from a database on real storage, so
#   that reads reach the device instead of the page cache, and it reports the
#   number of pread syscalls each phase made. The syscall count is what proves
#   the comparison is real: with io_uring disabled there is roughly one pread
#   per block read, and with it enabled there are almost none.
#
#   Interpreting the result: io_uring wins by having many reads outstanding at
#   once, so it only pays off on storage whose throughput rises with the number
#   of concurrent requests. Where it does not rise, submitting through a ring is
#   pure overhead and io_uring will measure slower. Virtualised disks are often
#   in that category even when the underlying device is a fast NVMe drive, so a
#   slowdown here says more about the storage stack than about RocksDb.

{.used.}

import
  std/[algorithm, os, strformat, strutils, times],
  tempfile,
  unittest2,
  ../rocksdb/rocksdb,
  ./test_helper

const benchmarkNameWidth = 52

proc readSyscallCount(): int64 =
  ## Number of read syscalls this process has made, from /proc/self/io. Reads
  ## issued through io_uring are not read syscalls, so this stops rising once
  ## io_uring is in use.
  try:
    for line in lines("/proc/self/io"):
      let fields = line.split(": ")
      if fields.len == 2 and fields[0] == "syscr":
        return parseBiggestInt(fields[1])
  except CatchableError:
    discard

proc fileSystemType(path: string): string =
  ## Filesystem backing `path`, taken from the longest matching mount point in
  ## /proc/mounts.
  var bestLen = -1
  try:
    for line in lines("/proc/mounts"):
      let fields = line.split(' ')
      if fields.len < 3:
        continue
      let
        mountPoint = fields[1]
        prefix =
          if mountPoint.endsWith('/'):
            mountPoint
          else:
            mountPoint & "/"
      if (path == mountPoint or path.startsWith(prefix)) and mountPoint.len > bestLen:
        bestLen = mountPoint.len
        result = fields[2]
  except CatchableError:
    discard

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

proc runBufferBatchedBench(
    readDb: RocksDbRef,
    readKeys: seq[seq[byte]],
    sortedReadKeys: seq[seq[byte]],
    keyReads, batchSize, valueSize: int,
): tuple[elapsed: float, sortedElapsed: float, bytes: int64, sortedBytes: int64] =
  ## Batched reads through the buffer based multiGet, which writes values into
  ## caller-owned memory instead of returning freshly allocated seqs.
  ##
  ## The key slices and the destination buffers are built once up front rather
  ## than per batch. That is how the API is meant to be used - it is the reason
  ## it takes slices at all - and it keeps the timed region to the calls
  ## themselves, matching the other variants.
  doAssert batchSize <= MULTI_GET_MAX_KEYS

  var
    keySlices = newSeq[RocksDbSlice](keyReads)
    sortedKeySlices = newSeq[RocksDbSlice](keyReads)
  for i in 0 ..< keyReads:
    keySlices[i] = RocksDbSlice.init(readKeys[i])
    sortedKeySlices[i] = RocksDbSlice.init(sortedReadKeys[i])

  var buffers = newSeq[seq[byte]](batchSize)
  for i in 0 ..< batchSize:
    buffers[i] = newSeq[byte](valueSize)
  var values = newSeq[RocksDbMutSlice](batchSize)
  for i in 0 ..< batchSize:
    values[i] = RocksDbMutSlice.init(buffers[i])

  var
    bytes = 0'i64
    sortedBytes = 0'i64
    batchStart = 0

  let start = epochTime()
  while batchStart < keyReads:
    let
      batchEnd = min(batchStart + batchSize, keyReads)
      count = batchEnd - batchStart
    let res = readDb.multiGet(
      keySlices.toOpenArray(batchStart, batchEnd - 1), values.toOpenArray(0, count - 1)
    )
    check res.isOk()
    for i in 0 ..< count:
      check values[i].found()
      bytes += int64(values[i].len)
    batchStart = batchEnd
  let elapsed = epochTime() - start

  batchStart = 0
  let sortedStart = epochTime()
  while batchStart < keyReads:
    let
      batchEnd = min(batchStart + batchSize, keyReads)
      count = batchEnd - batchStart
    let res = readDb.multiGet(
      sortedKeySlices.toOpenArray(batchStart, batchEnd - 1),
      values.toOpenArray(0, count - 1),
      sortedInput = true,
    )
    check res.isOk()
    for i in 0 ..< count:
      check values[i].found()
      sortedBytes += int64(values[i].len)
    batchStart = batchEnd
  let sortedElapsed = epochTime() - sortedStart

  (elapsed, sortedElapsed, bytes, sortedBytes)

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

      # The buffer based multiGet takes at most MULTI_GET_MAX_KEYS per call, so
      # the larger batch sizes in the sweep have no comparable measurement.
      if batchSize > MULTI_GET_MAX_KEYS:
        debugEcho "  " &
          alignLeft(fmt"multiGet(buffers, batch={batchSize})", benchmarkNameWidth) &
          fmt" skipped - above MULTI_GET_MAX_KEYS ({MULTI_GET_MAX_KEYS})"
      else:
        let
          syncBuffers = runBufferBatchedBench(
            syncReadDb, sweepKeys, sortedSweepKeys, sweepReadCount, batchSize, valueSize
          )
          asyncBuffers = runBufferBatchedBench(
            asyncReadDb, sweepKeys, sortedSweepKeys, sweepReadCount, batchSize,
            valueSize,
          )

        check:
          syncBuffers.bytes == expectedSweepBytes
          syncBuffers.sortedBytes == expectedSweepBytes
          asyncBuffers.bytes == expectedSweepBytes
          asyncBuffers.sortedBytes == expectedSweepBytes

        debugEcho benchmarkLine(
          fmt"multiGet(sync, buffers, batch={batchSize})",
          syncBuffers.elapsed,
          sweepReadCount,
        )
        debugEcho benchmarkLine(
          fmt"multiGet(async, buffers, batch={batchSize})",
          asyncBuffers.elapsed,
          sweepReadCount,
        )
        debugEcho benchmarkLine(
          fmt"multiGet(sync, buffers, sorted, batch={batchSize})",
          syncBuffers.sortedElapsed,
          sweepReadCount,
        )
        debugEcho benchmarkLine(
          fmt"multiGet(async, buffers, sorted, batch={batchSize})",
          asyncBuffers.sortedElapsed,
          sweepReadCount,
        )

  test "Benchmark multiGet with and without io_uring":
    const
      keyCount = 200_000
      valueSize = 1024
      readCount = 6_400
      batchSize = 128
      rounds = 3

    # The database has to live on real storage for this to measure anything. A
    # temporary directory is normally memory backed, where every read is a
    # memory copy and both configurations look identical.
    let benchmarkPath =
      if getEnv("NIM_ROCKSDB_BENCH_DIR").len > 0:
        getEnv("NIM_ROCKSDB_BENCH_DIR")
      else:
        getHomeDir() / ".cache" / "nim-rocksdb-benchmark"

    createDir(benchmarkPath.parentDir())
    let fsType = fileSystemType(benchmarkPath.parentDir())
    if fsType in ["tmpfs", "ramfs"]:
      debugEcho "Skipping io_uring benchmark: " & benchmarkPath & " is on " & fsType &
        ", which is memory backed. Set NIM_ROCKSDB_BENCH_DIR to a path on real storage."
      skip()
      return

    removeDir(benchmarkPath)
    createDir(benchmarkPath)
    defer:
      removeDir(benchmarkPath)

    # Write the dataset and compact it, so that a batch of lookups becomes many
    # block reads against few files, which is the case MultiRead submits to the
    # ring together.
    var keys = newSeq[seq[byte]](keyCount)
    block:
      let writeDb = initReadWriteDb(benchmarkPath)
      var value = newSeq[byte](valueSize)
      for i in 0 ..< keyCount:
        keys[i] = makeKey(i)
        for j in 0 ..< valueSize:
          value[j] = byte((i + j) and 0xFF)
        check writeDb.put(keys[i], value).isOk()
      check writeDb.flush().isOk()
      check writeDb.compactRange(makeKey(0), makeKey(keyCount)).isOk()
      writeDb.close()

    var
      readKeys = newSeq[seq[byte]](readCount)
      readIndexes = newSeq[int](readCount)
    for i in 0 ..< readCount:
      let index = ((i * 2654435761'i64) mod keyCount.int64).int
      readIndexes[i] = index
      readKeys[i] = keys[index]
    let sortedReadKeys = makeSortedReadKeys(keys, readIndexes, readCount, batchSize)

    proc runUringPhase(
        uringOn: bool
    ): tuple[
      multiGet: float,
      multiGetIter: float,
      multiGetSorted: float,
      multiGetIterSorted: float,
      reads: int64,
    ] =
      ## Open the database with io_uring either enabled or disabled, then run
      ## the same batched reads against it.
      setIoUringEnabled(uringOn)

      let dbOpts = defaultDbOptions(autoClose = true)
      # Bypass the page cache so reads reach the device, which is the only place
      # where the way they are submitted can make a difference.
      dbOpts.useDirectReads = true

      let readOpts = defaultReadOptions(autoClose = true)
      # Leave the block cache empty so each round re-reads from storage rather
      # than measuring progressively warmer caches.
      readOpts.fillCache = false

      let readDb = openRocksDbReadOnly(
          benchmarkPath, dbOpts = dbOpts, readOpts = readOpts
        )
        .expect("open io_uring benchmark db")
      defer:
        readDb.close()

      let syscallsBefore = readSyscallCount()
      let results =
        runBatchedBench(readDb, readKeys, sortedReadKeys, readCount, batchSize)
      let reads = readSyscallCount() - syscallsBefore

      let expectedBytes = int64(readCount * valueSize)
      check:
        results.multiGetBytes == expectedBytes
        results.multiGetIterBytes == expectedBytes
        results.multiGetSortedBytes == expectedBytes
        results.multiGetIterSortedBytes == expectedBytes

      (
        results.multiGetElapsed, results.multiGetIterElapsed,
        results.multiGetSortedElapsed, results.multiGetIterSortedElapsed, reads,
      )

    var
      offTotals, onTotals: array[4, float]
      offReads, onReads: int64

    for round in 1 .. rounds:
      # Alternate the two settings inside each round, so any drift in machine
      # state is shared between them rather than favouring one.
      let
        off = runUringPhase(uringOn = false)
        on = runUringPhase(uringOn = true)

      for i, elapsed in [
        off.multiGet, off.multiGetIter, off.multiGetSorted, off.multiGetIterSorted
      ]:
        offTotals[i] += elapsed
      for i, elapsed in [
        on.multiGet, on.multiGetIter, on.multiGetSorted, on.multiGetIterSorted
      ]:
        onTotals[i] += elapsed
      offReads += off.reads
      onReads += on.reads

    debugEcho "RocksDB multiGet with and without io_uring (direct I/O, " & fsType & ", " &
      $keyCount & " keys x " & $valueSize & " byte values, batch=" & $batchSize &
      ", mean of " & $rounds & " rounds):"
    debugEcho benchmarkHeader()

    const variantNames =
      ["multiGet", "multiGetIter", "multiGet(sorted)", "multiGetIter(sorted)"]
    for i, name in variantNames:
      let
        offAverage = offTotals[i] / rounds.float
        onAverage = onTotals[i] / rounds.float
      debugEcho benchmarkLine(fmt"{name}(io_uring off)", offAverage, readCount)
      debugEcho benchmarkLine(fmt"{name}(io_uring on)", onAverage, readCount)
      debugEcho fmt"    io_uring is {offAverage / onAverage:.2f}x the throughput of the fallback path"

    debugEcho fmt"  read syscalls: {offReads} with io_uring off, {onReads} with io_uring on"

    # With io_uring active the block reads go to the ring instead of pread, so a
    # run that still made as many read syscalls as the fallback never exercised
    # io_uring and the numbers above would be meaningless.
    check onReads * 10 < offReads
