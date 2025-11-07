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
  OptimisticTxOptionsPtr* = ptr rocksdb_optimistictransaction_options_t

  OptimisticTxOptionsRef* = ref object
    cPtr: OptimisticTxOptionsPtr
    autoClose*: bool # if true then close will be called when the transaction is closed

proc createOptimisticTxOptions*(autoClose = false): OptimisticTxOptionsRef =
  OptimisticTxOptionsRef(
    cPtr: rocksdb_optimistictransaction_options_create(), autoClose: autoClose
  )

template isClosed*(txOpts: OptimisticTxOptionsRef): bool =
  txOpts.cPtr.isNil()

proc cPtr*(txOpts: OptimisticTxOptionsRef): OptimisticTxOptionsPtr =
  doAssert not txOpts.isClosed()
  txOpts.cPtr

template setOpt(nname, ntyp, ctyp: untyped) =
  proc `nname=`*(txOpts: OptimisticTxOptionsRef, value: ntyp) =
    doAssert not txOpts.isClosed()
    `rocksdb_optimistictransaction_options_set nname`(txOpts.cPtr, value.ctyp)

setOpt setSnapshot, bool, uint8

proc defaultOptimisticTxOptions*(autoClose = false): OptimisticTxOptionsRef =
  let txOpts = createOptimisticTxOptions(autoClose)

  # TODO: set prefered defaults
  txOpts

proc close*(txOpts: OptimisticTxOptionsRef) =
  if not txOpts.isClosed():
    rocksdb_optimistictransaction_options_destroy(txOpts.cPtr)
    txOpts.cPtr = nil
