# Nim-RocksDB
# Copyright 2024 Status Research & Development GmbH
# Licensed under either of
#
#  * Apache License, version 2.0, ([LICENSE-APACHE](LICENSE-APACHE) or http://www.apache.org/licenses/LICENSE-2.0)
#  * GPL license, version 2.0, ([LICENSE-GPLv2](LICENSE-GPLv2) or https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)
#
# at your option. This file may not be copied, modified, or distributed except according to those terms.

{.push raises: [].}

import
  ../lib/librocksdb

type
  BackupEngineOptionsPtr* = ptr rocksdb_options_t

  BackupEngineOptionsRef* = ref object
    cPtr: BackupEngineOptionsPtr

proc newBackupEngineOptions*(): BackupEngineOptionsRef =
  BackupEngineOptionsRef(cPtr: rocksdb_options_create())

template isClosed*(engineOpts: BackupEngineOptionsRef): bool =
  engineOpts.cPtr.isNil()

proc cPtr*(engineOpts: BackupEngineOptionsRef): BackupEngineOptionsPtr =
  doAssert not engineOpts.isClosed()
  engineOpts.cPtr

# TODO: Add setters and getters for backup options properties.

template defaultBackupEngineOptions*(): BackupEngineOptionsRef =
  newBackupEngineOptions()
  # TODO: set prefered defaults

proc close*(engineOpts: var BackupEngineOptionsRef) =
  if not engineOpts.isClosed():
    rocksdb_options_destroy(engineOpts.cPtr)
    engineOpts.cPtr = nil
