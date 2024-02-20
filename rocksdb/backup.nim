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
  ./lib/librocksdb,
  ./internal/utils,
  ./options/backupopts,
  ./rocksdb

type
  BackupEnginePtr* = ptr rocksdb_backup_engine_t

  BackupEngineRef* = ref object
    cPtr: BackupEnginePtr
    path: string
    backupOpts: BackupEngineOptionsRef

proc openBackupEngine*(
    path: string,
    backupOpts = defaultBackupEngineOptions()): RocksDBResult[BackupEngineRef] =

  var errors: cstring
  let backupEnginePtr = rocksdb_backup_engine_open(
    backupOpts.cPtr,
    path.cstring,
    cast[cstringArray](errors.addr))
  bailOnErrors(errors)

  let engine = BackupEngineRef(
    cPtr: backupEnginePtr,
    path: path,
    backupOpts: backupOpts)
  ok(engine)

template isClosed*(backupEngine: BackupEngineRef): bool =
  backupEngine.cPtr.isNil()

proc backup*(backupEngine: BackupEngineRef, db: RocksDbRef): RocksDBResult[void] =
  doAssert not backupEngine.isClosed()

  var errors: cstring
  rocksdb_backup_engine_create_new_backup(
    backupEngine.cPtr,
    db.cPtr,
    cast[cstringArray](errors.addr))
  bailOnErrors(errors)

  ok()

proc close*(backupEngine: var BackupEngineRef) =
  if not backupEngine.isClosed():
    rocksdb_backup_engine_close(backupEngine.cPtr)
    backupEngine.cPtr = nil


