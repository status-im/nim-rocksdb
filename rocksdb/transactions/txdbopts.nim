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
  TransactionDbOptionsPtr* = ptr rocksdb_transactiondb_options_t

  TransactionDbOptionsRef* = ref object
    cPtr: TransactionDbOptionsPtr
    autoClose*: bool # if true then close will be called when the database is closed

proc createTransactionDbOptions*(autoClose = false): TransactionDbOptionsRef =
  TransactionDbOptionsRef(
    cPtr: rocksdb_transactiondb_options_create(), autoClose: autoClose
  )

proc isClosed*(txDbOpts: TransactionDbOptionsRef): bool {.inline.} =
  txDbOpts.cPtr.isNil()

proc cPtr*(txDbOpts: TransactionDbOptionsRef): TransactionDbOptionsPtr =
  doAssert not txDbOpts.isClosed()
  txDbOpts.cPtr

# TODO: Add setters and getters for backup options properties.

proc defaultTransactionDbOptions*(
    autoClose = false
): TransactionDbOptionsRef {.inline.} =
  createTransactionDbOptions(autoClose)
  # TODO: set prefered defaults

proc close*(txDbOpts: TransactionDbOptionsRef) =
  if not txDbOpts.isClosed():
    rocksdb_transactiondb_options_destroy(txDbOpts.cPtr)
    txDbOpts.cPtr = nil
