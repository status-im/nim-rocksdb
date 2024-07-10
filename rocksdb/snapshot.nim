# Nim-RocksDB
# Copyright 2024 Status Research & Development GmbH
# Licensed under either of
#
#  * Apache License, version 2.0, ([LICENSE-APACHE](LICENSE-APACHE) or http://www.apache.org/licenses/LICENSE-2.0)
#  * GPL license, version 2.0, ([LICENSE-GPLv2](LICENSE-GPLv2) or https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)
#
# at your option. This file may not be copied, modified, or distributed except according to those terms.

## A `SnapshotRef` represents a view of the state of the database at some point in time.

{.push raises: [].}

import ./lib/librocksdb

type
  SnapshotPtr* = ptr rocksdb_snapshot_t

  SnapshotType* = enum
    rocksdb
    transactiondb

  SnapshotRef* = ref object
    cPtr: SnapshotPtr
    kind: SnapshotType

proc newSnapshot*(cPtr: SnapshotPtr, kind: SnapshotType): SnapshotRef =
  doAssert not cPtr.isNil()
  SnapshotRef(cPtr: cPtr, kind: kind)

proc isClosed*(snapshot: SnapshotRef): bool {.inline.} =
  ## Returns `true` if the `SnapshotRef` has been closed and `false` otherwise.
  snapshot.cPtr.isNil()

proc cPtr*(snapshot: SnapshotRef): SnapshotPtr =
  ## Get the underlying database pointer.
  doAssert not snapshot.isClosed()
  snapshot.cPtr

proc kind*(snapshot: SnapshotRef): SnapshotType =
  ## Get the kind of the `SnapshotRef`.
  snapshot.kind

proc getSequenceNumber*(snapshot: SnapshotRef): uint64 =
  ## Return the associated sequence number.
  doAssert not snapshot.isClosed()
  rocksdb_snapshot_get_sequence_number(snapshot.cPtr).uint64

proc setClosed*(snapshot: SnapshotRef) =
  # The snapshot should be released from `RocksDbRef` or `TransactionDbRef`
  snapshot.cPtr = nil
