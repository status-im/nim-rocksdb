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

template autoCloseNonNil*(opts: typed) =
  if not opts.isNil and opts.autoClose:
    opts.close()

template bailOnErrors*(
    errors: cstring,
    dbOpts: DbOptionsRef = nil,
    readOpts: ReadOptionsRef = nil,
    writeOpts: WriteOptionsRef = nil,
    txDbOpts: TransactionDbOptionsRef = nil,
    backupOpts: BackupEngineOptionsRef = nil,
    cfDescriptors: openArray[ColFamilyDescriptor] = @[],
): auto =
  if not errors.isNil:
    autoCloseNonNil(dbOpts)
    autoCloseNonNil(readOpts)
    autoCloseNonNil(writeOpts)
    autoCloseNonNil(txDbOpts)
    autoCloseNonNil(backupOpts)

    for cfDesc in cfDescriptors:
      if cfDesc.autoClose:
        cfDesc.close()

    let res = err($(errors))
    rocksdb_free(errors)
    return res
