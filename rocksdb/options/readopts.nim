# Nim-RocksDB
# Copyright 2024 Status Research & Development GmbH
# Licensed under either of
#
#  * Apache License, version 2.0, ([LICENSE-APACHE](LICENSE-APACHE) or http://www.apache.org/licenses/LICENSE-2.0)
#  * GPL license, version 2.0, ([LICENSE-GPLv2](LICENSE-GPLv2) or https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)
#
# at your option. This file may not be copied, modified, or distributed except according to those terms.

{.push raises: [].}

import ../lib/librocksdb

type
  ReadOptionsPtr* = ptr rocksdb_readoptions_t

  ReadOptionsRef* = ref object
    cPtr: ReadOptionsPtr
    autoClose*: bool # if true then close will be called when the database is closed

proc createReadOptions*(autoClose = false): ReadOptionsRef =
  ReadOptionsRef(cPtr: rocksdb_readoptions_create(), autoClose: autoClose)

proc isClosed*(readOpts: ReadOptionsRef): bool {.inline.} =
  readOpts.cPtr.isNil()

proc cPtr*(readOpts: ReadOptionsRef): ReadOptionsPtr =
  doAssert not readOpts.isClosed()
  readOpts.cPtr

template opt(nname, ntyp, ctyp: untyped) =
  proc `nname=`*(readOpts: ReadOptionsRef, value: ntyp) =
    doAssert not readOpts.isClosed()
    `rocksdb_readoptions_set nname`(readOpts.cPtr, value.ctyp)

  proc `nname`*(readOpts: ReadOptionsRef): ntyp =
    doAssert not readOpts.isClosed()
    ntyp `rocksdb_readoptions_get nname`(readOpts.cPtr)

opt verifyChecksums, bool, uint8
opt fillCache, bool, uint8
opt readTier, int, cint
opt tailing, bool, uint8
opt totalOrderSeek, bool, uint8
opt prefixSameAsStart, bool, uint8
opt pinData, bool, uint8
opt backgroundPurgeOnIteratorCleanup, bool, uint8
opt readaheadSize, int, csize_t
opt maxSkippableInternalKeys, int, csize_t
opt ignoreRangeDeletions, bool, uint8
opt deadline, int, uint64
opt ioTimeout, int, uint64

proc defaultReadOptions*(autoClose = false): ReadOptionsRef {.inline.} =
  let readOpts = createReadOptions(autoClose)

  # TODO: set prefered defaults
  readOpts

proc close*(readOpts: ReadOptionsRef) =
  if not readOpts.isClosed():
    rocksdb_readoptions_destroy(readOpts.cPtr)
    readOpts.cPtr = nil
