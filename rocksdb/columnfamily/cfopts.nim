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
  OptionsPtr = ptr rocksdb_options_t

  ColFamilyOptionsRef* = ref object
    optionsPtr: OptionsPtr

proc newColFamilyOptions*(): ColFamilyOptionsRef =
  ColFamilyOptionsRef(optionsPtr: rocksdb_options_create())

template isClosed(dbOpts: ColFamilyOptionsRef): bool =
  dbOpts.optionsPtr.isNil()

proc setCreateMissingColumnFamilies*(cfOpts: var ColFamilyOptionsRef, flag: bool) =
  doAssert not cfOpts.isClosed()
  rocksdb_options_set_create_missing_column_families(cfOpts.optionsPtr, flag.uint8)

proc defaultColFamilyOptions*(): ColFamilyOptionsRef =
  var opts = newColFamilyOptions()
  # Enable creating column families if they do not exist
  opts.setCreateMissingColumnFamilies(true)
  return opts

proc getCreateMissingColumnFamilies*(cfOpts: ColFamilyOptionsRef): bool =
  doAssert not cfOpts.isClosed()
  rocksdb_options_get_create_missing_column_families(cfOpts.optionsPtr).bool

proc close*(cfOpts: var ColFamilyOptionsRef) =
  if not cfOpts.isClosed():
    rocksdb_options_destroy(cfOpts.optionsPtr)
    cfOpts.optionsPtr = nil

