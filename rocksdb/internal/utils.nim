# Nim-RocksDB
# Copyright 2024 Status Research & Development GmbH
# Licensed under either of
#
#  * Apache License, version 2.0, ([LICENSE-APACHE](LICENSE-APACHE) or http://www.apache.org/licenses/LICENSE-2.0)
#  * GPL license, version 2.0, ([LICENSE-GPLv2](LICENSE-GPLv2) or https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)
#
# at your option. This file may not be copied, modified, or distributed except according to those terms.

{.push raises: [].}

import std/locks, ../lib/librocksdb

proc createLock*(): Lock =
  var lock = Lock()
  initLock(lock)
  lock

template autoCloseNonNil*(closable: typed) =
  if not closable.isNil and closable.autoClose:
    closable.close()

template autoCloseAll*(closables: openArray[typed]) =
  for c in closables:
    if c.autoClose:
      c.close()

template bailOnErrorsWithCleanup*(errors: cstring, cleanup: untyped): auto =
  if not errors.isNil:
    cleanup

    let res = err($(errors))
    rocksdb_free(errors)
    return res

template bailOnErrors*(errors: cstring): auto =
  if not errors.isNil:
    let res = err($(errors))
    rocksdb_free(errors)
    return res

template unsafeAddrOrNil*(s: openArray[byte]): auto =
  if s.len > 0:
    unsafeAddr s[0]
  else:
    nil
