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
  std/locks,
  ../lib/librocksdb,
  ../options/[dbopts, readopts, writeopts, backupopts],
  ../transactions/txdbopts,
  ../columnfamily/cfdescriptor

proc createLock*(): Lock =
  var lock = Lock()
  initLock(lock)
  lock

template bailOnErrors*(
    errors: cstring,
    dbOpts: DbOptionsRef = nil,
    readOpts: ReadOptionsRef = nil,
    writeOpts: WriteOptionsRef = nil,
    txDbOpts: TransactionDbOptionsRef = nil,
    cfDescriptors: openArray[ColFamilyDescriptor] = [],
    backupOpts: BackupEngineOptionsRef = nil,
): auto =
  if not errors.isNil:
    if not dbOpts.isNil() and dbOpts.autoClose:
      dbOpts.close()
    if not readOpts.isNil() and dbOpts.autoClose:
      readOpts.close()
    if not writeOpts.isNil() and dbOpts.autoClose:
      writeOpts.close()
    if not txDbOpts.isNil() and dbOpts.autoClose:
      txDbOpts.close()
    for cfDesc in cfDescriptors:
      if cfDesc.autoClose:
        cfDesc.close()
    if not backupOpts.isNil() and backupOpts.autoClose:
      backupOpts.close()

    let res = err($(errors))
    rocksdb_free(errors)
    return res
