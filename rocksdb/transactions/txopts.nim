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
  TransactionOptionsPtr* = ptr rocksdb_transaction_options_t

  TransactionOptionsRef* = ref object
    cPtr: TransactionOptionsPtr
    autoClose*: bool # if true then close will be called when the transaction is closed

proc createTransactionOptions*(autoClose = false): TransactionOptionsRef =
  TransactionOptionsRef(
    cPtr: rocksdb_transaction_options_create(), autoClose: autoClose
  )

proc isClosed*(txOpts: TransactionOptionsRef): bool {.inline.} =
  txOpts.cPtr.isNil()

proc cPtr*(txOpts: TransactionOptionsRef): TransactionOptionsPtr =
  doAssert not txOpts.isClosed()
  txOpts.cPtr

template setOpt(nname, ntyp, ctyp: untyped) =
  proc `nname=`*(txOpts: TransactionOptionsRef, value: ntyp) =
    doAssert not txOpts.isClosed()
    `rocksdb_transaction_options_set nname`(txOpts.cPtr, value.ctyp)

setOpt setSnapshot, bool, uint8
setOpt deadlockDetect, bool, uint8
setOpt lockTimeout, int, int64
setOpt deadlockDetectDepth, int, int64
setOpt maxWriteBatchSize, int, csize_t
setOpt skipPrepare, bool, uint8

proc defaultTransactionOptions*(autoClose = false): TransactionOptionsRef {.inline.} =
  let txOpts = createTransactionOptions(autoClose)

  # TODO: set prefered defaults
  txOpts

proc close*(txOpts: TransactionOptionsRef) =
  if not txOpts.isClosed():
    rocksdb_transaction_options_destroy(txOpts.cPtr)
    txOpts.cPtr = nil
