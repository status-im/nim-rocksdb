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
  BackupEngineOptionsPtr* = ptr rocksdb_backup_engine_options_t

  BackupEngineOptionsRef* = ref object
    cPtr: BackupEngineOptionsPtr
    autoClose*: bool # if true then close will be called when the backup engine is closed

proc createBackupEngineOptions*(
    backupDir: string, autoClose = false
): BackupEngineOptionsRef =
  BackupEngineOptionsRef(
    cPtr: rocksdb_backup_engine_options_create(backupDir.cstring), autoClose: autoClose
  )

template isClosed*(backupOpts: BackupEngineOptionsRef): bool =
  backupOpts.cPtr.isNil()

proc cPtr*(backupOpts: BackupEngineOptionsRef): BackupEngineOptionsPtr =
  doAssert not backupOpts.isClosed()
  backupOpts.cPtr

template opt(nname, ntyp, ctyp: untyped) =
  proc `nname=`*(backupOpts: BackupEngineOptionsRef, value: ntyp) =
    doAssert not backupOpts.isClosed()
    `rocksdb_backup_engine_options_set nname`(backupOpts.cPtr, value.ctyp)

  proc `nname`*(backupOpts: BackupEngineOptionsRef): ntyp =
    doAssert not backupOpts.isClosed()
    ntyp `rocksdb_backup_engine_options_get nname`(backupOpts.cPtr)

opt shareTableFiles, bool, uint8
opt sync, bool, uint8
opt destroyOldData, bool, uint8
opt backupLogFiles, bool, uint8
opt backupRateLimit, int, uint64
opt restoreRateLimit, int, uint64
opt shareFilesWithChecksumNaming, bool, cint
opt maxBackgroundOperations, int, cint
opt callbackTriggerIntervalSize, int, uint64

proc defaultBackupEngineOptions*(
    backupDir: string, autoClose = false
): BackupEngineOptionsRef =
  let backupOpts = createBackupEngineOptions(backupDir, autoClose)

  # TODO: set defaults here
  backupOpts

proc close*(backupOpts: BackupEngineOptionsRef) =
  if not backupOpts.isClosed():
    rocksdb_backup_engine_options_destroy(backupOpts.cPtr)
    backupOpts.cPtr = nil
