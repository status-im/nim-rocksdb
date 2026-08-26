# Nim-RocksDB
# Copyright 2018-2025 Status Research & Development GmbH
# Licensed under either of
#
#  * Apache License, version 2.0, ([LICENSE-APACHE](LICENSE-APACHE) or http://www.apache.org/licenses/LICENSE-2.0)
#  * GPL license, version 2.0, ([LICENSE-GPLv2](LICENSE-GPLv2) or https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)
#
# at your option. This file may not be copied, modified, or distributed except according to those terms.

#   RocksDB io_uring (liburing) MultiGet Benchmark
#   ==============================================
#
#   Measures what linking liburing into the RocksDb build actually buys, by
#   running the same multiGet workload with the io_uring read paths enabled and
#   disabled.
#
#   RocksDb only uses io_uring when both of these hold:
#     1. It was compiled with ROCKSDB_IOURING_PRESENT, which requires liburing
#        to be present at build time (see scripts/build_static_deps.sh).
#     2. The application defines the weak symbol `RocksDbIOUringEnable` and it
#        returns true. When that symbol is left undefined, RocksDb hands every
#        file it opens a null io_uring instance (env/fs_posix.cc) and both
#        MultiRead and ReadAsync fall back to serialized pread calls.
#
#   This benchmark defines that symbol itself, so the io_uring paths can be
#   turned on and off at runtime. Turning them off reproduces exactly what a
#   build without liburing does: PosixRandomAccessFile::MultiRead sees a null
#   ring and defers to FSRandomAccessFile::MultiRead, which reads each request
#   in turn. Running both from one process keeps the data, the key order and the
#   machine state identical across the comparison.
#
#   Both read paths are measured, because they use io_uring differently:
#     - asyncIo = false uses MultiRead, which submits a batch's block reads to
#       the ring together.
#     - asyncIo = true uses ReadAsync/Poll, which starts reads before the point
#       at which they are needed. This is what defaultReadOptions() enables.
#
#   Reads are made with direct I/O against a database on real storage, so that
#   they reach the device rather than being served from the page cache. On a
#   tmpfs directory (which is what /tmp usually is) this would only measure
#   memory copies and both configurations would look identical, so the benchmark
#   refuses to run from one. Set NIM_ROCKSDB_BENCH_DIR to choose the location.
#
#   Every phase reports the number of pread syscalls it made, read from
#   /proc/self/io. This is what proves the comparison is real: with io_uring
#   disabled there is roughly one pread per block read, and with it enabled
#   there are almost none, because the reads went to the ring instead.
#
#   Interpreting the result: io_uring wins by having many reads outstanding at
#   once, so it can only pay off on storage whose throughput actually rises with
#   the number of concurrent requests. Where it does not rise, submitting
#   through a ring is pure overhead and this benchmark will report io_uring as
#   slower. Virtualised disks are frequently in that category even when the
#   underlying device is a fast NVMe drive, so a negative result here says more
#   about the storage stack than about RocksDb. Before drawing conclusions from
#   a slowdown, check whether the storage parallelises at all, for example by
#   timing several concurrent processes each doing random O_DIRECT reads and
#   seeing whether the combined throughput scales with the process count.

{.used.}

import std/[os, strformat, strutils, times], unittest2, ../rocksdb/rocksdb

# RocksDb calls this weak symbol to decide whether io_uring may be used. It is
# consulted every time a file is opened, so flipping this flag and reopening the
# database switches the io_uring paths on or off.
var ioUringEnabled = false

proc rocksDbIOUringEnable(): bool {.exportc: "RocksDbIOUringEnable", cdecl, used.} =
  ioUringEnabled

const
  keyCount = 200_000
  valueSize = 1024
  batchSize = 128
  readCount = 6_400
  rounds = 3
  nameWidth = 30

type PhaseResult = object
  elapsed: float
  preads: int64
  bytesFromDevice: int64
  bytesRead: int64

proc ioCounters(): tuple[preads, bytesFromDevice: int64] =
  ## Read syscall count and bytes actually fetched from storage for this
  ## process, from /proc/self/io. Reads issued through io_uring are not read
  ## syscalls, so `preads` drops to almost nothing once io_uring is in use.
  try:
    for line in lines("/proc/self/io"):
      let fields = line.split(": ")
      if fields.len == 2:
        if fields[0] == "syscr":
          result.preads = parseBiggestInt(fields[1])
        elif fields[0] == "read_bytes":
          result.bytesFromDevice = parseBiggestInt(fields[1])
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

proc makeKey(i: int): seq[byte] =
  # Fixed width big endian keys, so they sort in the same order as the integers
  # they are derived from.
  @[
    byte((i shr 24) and 0xFF),
    byte((i shr 16) and 0xFF),
    byte((i shr 8) and 0xFF),
    byte(i and 0xFF),
  ]

proc header(): string =
  "  " & alignLeft("configuration", nameWidth) & " " & align("elapsed(s)", 10) & " " &
    align("us/key", 8) & " " & align("preads", 8) & " " & align("MB read", 9)

proc line(name: string, r: PhaseResult): string =
  "  " & alignLeft(name, nameWidth) & " " & align(fmt"{r.elapsed:.4f}", 10) & " " &
    align(fmt"{r.elapsed * 1_000_000.0 / readCount.float:.1f}", 8) & " " &
    align($r.preads, 8) & " " &
    align(fmt"{r.bytesFromDevice.float / 1_048_576.0:.1f}", 9)

proc runPhase(
    path: string, readKeys: seq[seq[byte]], uringOn, asyncIo: bool
): PhaseResult =
  ## Open the database with io_uring either enabled or disabled, then time a
  ## sequence of multiGet batches against it.
  ioUringEnabled = uringOn

  let dbOpts = defaultDbOptions(autoClose = true)
  # Bypass the page cache so reads reach the device, which is the only place
  # where the way they are submitted can make a difference.
  dbOpts.useDirectReads = true

  let readOpts = defaultReadOptions(autoClose = true)
  readOpts.asyncIo = asyncIo
  # Leave the block cache empty so each round re-reads from storage instead of
  # measuring progressively warmer caches.
  readOpts.fillCache = false

  let db = openRocksDbReadOnly(path, dbOpts = dbOpts, readOpts = readOpts).expect(
      "open benchmark db"
    )
  defer:
    db.close()

  let before = ioCounters()
  var bytesRead = 0'i64

  let start = epochTime()
  var batchStart = 0
  while batchStart < readCount:
    let
      batchEnd = min(batchStart + batchSize, readCount)
      res = db.multiGet(readKeys.toOpenArray(batchStart, batchEnd - 1))
    doAssert res.isOk(), $res.error()
    for valueOpt in res.value():
      doAssert valueOpt.isSome()
      bytesRead += int64(valueOpt.get().len)
    batchStart = batchEnd
  let elapsed = epochTime() - start

  let after = ioCounters()
  PhaseResult(
    elapsed: elapsed,
    preads: after.preads - before.preads,
    bytesFromDevice: after.bytesFromDevice - before.bytesFromDevice,
    bytesRead: bytesRead,
  )

suite "RocksDb io_uring Benchmark":
  test "MultiGet with and without io_uring":
    let benchmarkPath =
      if getEnv("NIM_ROCKSDB_BENCH_DIR").len > 0:
        getEnv("NIM_ROCKSDB_BENCH_DIR")
      else:
        getHomeDir() / ".cache" / "nim-rocksdb-iouring-benchmark"

    createDir(benchmarkPath.parentDir())
    let fsType = fileSystemType(benchmarkPath.parentDir())
    if fsType in ["tmpfs", "ramfs"]:
      echo "  skipped: " & benchmarkPath & " is on " & fsType &
        ", which is memory backed. Set NIM_ROCKSDB_BENCH_DIR to a path on real storage."
      skip()
      return

    removeDir(benchmarkPath)
    createDir(benchmarkPath)
    defer:
      removeDir(benchmarkPath)

    echo "  database: " & benchmarkPath & " (" & fsType & ")"
    echo "  dataset:  " & $keyCount & " keys x " & $valueSize & " byte values"
    echo "  reads:    " & $readCount & " keys per phase, batches of " & $batchSize

    # Write the dataset and compact it, so that a batch of lookups turns into
    # many block reads against few files, which is the case MultiRead is meant
    # to submit to the ring together.
    block:
      let writeDb = openRocksDb(benchmarkPath).expect("open benchmark db for writing")
      var value = newSeq[byte](valueSize)
      for i in 0 ..< keyCount:
        for j in 0 ..< valueSize:
          value[j] = byte((i + j) and 0xFF)
        check writeDb.put(makeKey(i), value).isOk()
      check writeDb.flush().isOk()
      check writeDb.compactRange(makeKey(0), makeKey(keyCount)).isOk()
      writeDb.close()

    # Pseudo random lookup order, the same for every phase.
    var readKeys = newSeq[seq[byte]](readCount)
    for i in 0 ..< readCount:
      readKeys[i] = makeKey(((i * 2654435761'i64) mod keyCount.int64).int)

    var
      offTotals, onTotals: array[2, float]
      offPreads, onPreads: array[2, int64]

    echo ""
    echo header()

    for round in 1 .. rounds:
      # Alternate the two settings inside each round, so that any drift in
      # machine state is shared between them rather than favouring one.
      for asyncIndex, asyncIo in [false, true]:
        let
          label = if asyncIo: "asyncIo" else: "sync   "
          off = runPhase(benchmarkPath, readKeys, uringOn = false, asyncIo = asyncIo)
          on = runPhase(benchmarkPath, readKeys, uringOn = true, asyncIo = asyncIo)

        # Both configurations must return the same data, or they are not
        # comparable.
        check off.bytesRead == on.bytesRead

        offTotals[asyncIndex] += off.elapsed
        onTotals[asyncIndex] += on.elapsed
        offPreads[asyncIndex] += off.preads
        onPreads[asyncIndex] += on.preads

        echo line(fmt"round {round} {label} uring off", off)
        echo line(fmt"round {round} {label} uring on ", on)

    echo ""
    echo "  averages over " & $rounds & " rounds"
    for asyncIndex, asyncIo in [false, true]:
      let
        label = if asyncIo: "asyncIo" else: "sync   "
        offAverage = offTotals[asyncIndex] / rounds.float
        onAverage = onTotals[asyncIndex] / rounds.float
        ratio = offAverage / onAverage
      echo fmt"  {label} io_uring off {offAverage:8.4f}s   on {onAverage:8.4f}s   " &
        fmt"io_uring is {ratio:.2f}x the throughput of the fallback path"

      # With io_uring active the block reads go to the ring instead of pread, so
      # a phase that still made as many read syscalls as the fallback did never
      # exercised io_uring, and the numbers above would be meaningless.
      check onPreads[asyncIndex] * 10 < offPreads[asyncIndex]
