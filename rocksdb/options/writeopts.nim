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
  WriteOptionsPtr* = ptr rocksdb_writeoptions_t

  WriteOptionsRef* = ref object
    cPtr: WriteOptionsPtr
    autoClose*: bool # if true then close will be called when the database is closed

proc createWriteOptions*(autoClose = false): WriteOptionsRef =
  WriteOptionsRef(cPtr: rocksdb_writeoptions_create(), autoClose: autoClose)

template isClosed*(writeOpts: WriteOptionsRef): bool =
  writeOpts.cPtr.isNil()

proc cPtr*(writeOpts: WriteOptionsRef): WriteOptionsPtr =
  doAssert not writeOpts.isClosed()
  writeOpts.cPtr

template opt(nname, ntyp, ctyp: untyped) =
  proc `nname=`*(writeOpts: WriteOptionsRef, value: ntyp) =
    doAssert not writeOpts.isClosed()
    `rocksdb_writeoptions_set nname`(writeOpts.cPtr, value.ctyp)

  proc `nname`*(writeOpts: WriteOptionsRef): ntyp =
    doAssert not writeOpts.isClosed()
    ntyp `rocksdb_writeoptions_get nname`(writeOpts.cPtr)

opt sync, bool, uint8
opt ignoreMissingColumnFamilies, bool, uint8
opt noSlowdown, bool, uint8
opt lowPri, bool, uint8
opt memtableInsertHintPerBatch, bool, uint8

proc `disableWAL=`*(writeOpts: WriteOptionsRef, value: bool) =
  doAssert not writeOpts.isClosed()
  rocksdb_writeoptions_disable_WAL(writeOpts.cPtr, value.cint)

proc disableWAL*(writeOpts: WriteOptionsRef): bool =
  doAssert not writeOpts.isClosed()
  rocksdb_writeoptions_get_disable_WAL(writeOpts.cPtr).bool

proc defaultWriteOptions*(autoClose = false): WriteOptionsRef =
  let writeOpts = createWriteOptions(autoClose)

  # TODO: set prefered defaults
  writeOpts

proc close*(writeOpts: WriteOptionsRef) =
  if not writeOpts.isClosed():
    rocksdb_writeoptions_destroy(writeOpts.cPtr)
    writeOpts.cPtr = nil
