# Nim-RocksDB
# Copyright 2018 Status Research & Development GmbH
# Licensed under either of
#
#  * Apache License, version 2.0, ([LICENSE-APACHE](LICENSE-APACHE) or http://www.apache.org/licenses/LICENSE-2.0)
#  * GPL license, version 2.0, ([LICENSE-GPLv2](LICENSE-GPLv2) or https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)
#
# at your option. This file may not be copied, modified, or distributed except according to those terms.

# Nim-RocksDB is a wrapper for Facebook's RocksDB
# RocksDB License
# Copyright (c) 2011-present, Facebook, Inc.  All rights reserved.
# Source code can be found at https://github.com/facebook/rocksdb
# under both the GPLv2 (found in the COPYING file in the RocksDB root directory) and Apache 2.0 License
# (found in the LICENSE.Apache file in the RocksDB root directory).

# RocksDB is derived work of LevelDB
# LevelDB License
# Copyright (c) 2011 The LevelDB Authors. All rights reserved.
# Source code can be found at https://github.com/google/leveldb
# Use of this source code is governed by a BSD-style license that can be
# found in the LevelDB LICENSE file. See the AUTHORS file for names of contributors.

## This file exposes the low-level C API of RocksDB

{.deadCodeElim: on.}
when defined(windows):
  const librocksdb = "librocksdb.dll"
elif defined(macosx):
  const librocksdb = "librocksdb.dylib"
else:
  const librocksdb = "librocksdb.so"
##  Exported types

const rocksdb_header = "rocksdb/c.h"

type
  rocksdb_t* {.importc: "rocksdb_t", header: rocksdb_header.} = object
  rocksdb_backup_engine_t* {.importc: "rocksdb_backup_engine_t", header: rocksdb_header.} = object
  rocksdb_backup_engine_info_t* {.importc: "rocksdb_backup_engine_info_t", header: rocksdb_header.} = object
  rocksdb_restore_options_t* {.importc: "rocksdb_restore_options_t", header: rocksdb_header.} = object
  rocksdb_cache_t* {.importc: "rocksdb_cache_t", header: rocksdb_header.} = object
  rocksdb_compactionfilter_t* {.importc: "rocksdb_compactionfilter_t", header: rocksdb_header.} = object
  rocksdb_compactionfiltercontext_t* {.importc: "rocksdb_compactionfiltercontext_t", header: rocksdb_header.} = object
  rocksdb_compactionfilterfactory_t* {.importc: "rocksdb_compactionfilterfactory_t", header: rocksdb_header.} = object
  rocksdb_comparator_t* {.importc: "rocksdb_comparator_t", header: rocksdb_header.} = object
  rocksdb_dbpath_t* {.importc: "rocksdb_dbpath_t", header: rocksdb_header.} = object
  rocksdb_env_t* {.importc: "rocksdb_env_t", header: rocksdb_header.} = object
  rocksdb_fifo_compaction_options_t* {.importc: "rocksdb_fifo_compaction_options_t", header: rocksdb_header.} = object
  rocksdb_filelock_t* {.importc: "rocksdb_filelock_t", header: rocksdb_header.} = object
  rocksdb_filterpolicy_t* {.importc: "rocksdb_filterpolicy_t", header: rocksdb_header.} = object
  rocksdb_flushoptions_t* {.importc: "rocksdb_flushoptions_t", header: rocksdb_header.} = object
  rocksdb_iterator_t* {.importc: "rocksdb_iterator_t", header: rocksdb_header.} = object
  rocksdb_logger_t* {.importc: "rocksdb_logger_t", header: rocksdb_header.} = object
  rocksdb_mergeoperator_t* {.importc: "rocksdb_mergeoperator_t", header: rocksdb_header.} = object
  rocksdb_options_t* {.importc: "rocksdb_options_t", header: rocksdb_header.} = object
  rocksdb_compactoptions_t* {.importc: "rocksdb_compactoptions_t", header: rocksdb_header.} = object
  rocksdb_block_based_table_options_t* {.importc: "rocksdb_block_based_table_options_t", header: rocksdb_header.} = object
  rocksdb_cuckoo_table_options_t* {.importc: "rocksdb_cuckoo_table_options_t", header: rocksdb_header.} = object
  rocksdb_randomfile_t* {.importc: "rocksdb_randomfile_t", header: rocksdb_header.} = object
  rocksdb_readoptions_t* {.importc: "rocksdb_readoptions_t", header: rocksdb_header.} = object
  rocksdb_seqfile_t* {.importc: "rocksdb_seqfile_t", header: rocksdb_header.} = object
  rocksdb_slicetransform_t* {.importc: "rocksdb_slicetransform_t", header: rocksdb_header.} = object
  rocksdb_snapshot_t* {.importc: "rocksdb_snapshot_t", header: rocksdb_header.} = object
  rocksdb_writablefile_t* {.importc: "rocksdb_writablefile_t", header: rocksdb_header.} = object
  rocksdb_writebatch_t* {.importc: "rocksdb_writebatch_t", header: rocksdb_header.} = object
  rocksdb_writebatch_wi_t* {.importc: "rocksdb_writebatch_wi_t", header: rocksdb_header.} = object
  rocksdb_writeoptions_t* {.importc: "rocksdb_writeoptions_t", header: rocksdb_header.} = object
  rocksdb_universal_compaction_options_t* {.importc: "rocksdb_universal_compaction_options_t", header: rocksdb_header.} = object
  rocksdb_livefiles_t* {.importc: "rocksdb_livefiles_t", header: rocksdb_header.} = object
  rocksdb_column_family_handle_t* {.importc: "rocksdb_column_family_handle_t", header: rocksdb_header.} = object
  rocksdb_envoptions_t* {.importc: "rocksdb_envoptions_t", header: rocksdb_header.} = object
  rocksdb_ingestexternalfileoptions_t* {.importc: "rocksdb_ingestexternalfileoptions_t", header: rocksdb_header.} = object
  rocksdb_sstfilewriter_t* {.importc: "rocksdb_sstfilewriter_t", header: rocksdb_header.} = object
  rocksdb_ratelimiter_t* {.importc: "rocksdb_ratelimiter_t", header: rocksdb_header.} = object
  rocksdb_pinnableslice_t* {.importc: "rocksdb_pinnableslice_t", header: rocksdb_header.} = object
  rocksdb_transactiondb_options_t* {.importc: "rocksdb_transactiondb_options_t", header: rocksdb_header.} = object
  rocksdb_transactiondb_t* {.importc: "rocksdb_transactiondb_t", header: rocksdb_header.} = object
  rocksdb_transaction_options_t* {.importc: "rocksdb_transaction_options_t", header: rocksdb_header.} = object
  rocksdb_optimistictransactiondb_t* {.importc: "rocksdb_optimistictransactiondb_t", header: rocksdb_header.} = object
  rocksdb_optimistictransaction_options_t* {.importc: "rocksdb_optimistictransaction_options_t", header: rocksdb_header.} = object
  rocksdb_transaction_t* {.importc: "rocksdb_transaction_t", header: rocksdb_header.} = object
  rocksdb_checkpoint_t* {.importc: "rocksdb_checkpoint_t", header: rocksdb_header.} = object

##  DB operations

proc rocksdb_open*(options: ptr rocksdb_options_t; name: cstring; errptr: cstringArray): ptr rocksdb_t {.
    cdecl, importc: "rocksdb_open", dynlib: librocksdb.}
proc rocksdb_open_for_read_only*(options: ptr rocksdb_options_t; name: cstring;
                                error_if_log_file_exist: cuchar;
                                errptr: cstringArray): ptr rocksdb_t {.cdecl,
    importc: "rocksdb_open_for_read_only", dynlib: librocksdb.}
proc rocksdb_backup_engine_open*(options: ptr rocksdb_options_t; path: cstring;
                                errptr: cstringArray): ptr rocksdb_backup_engine_t {.
    cdecl, importc: "rocksdb_backup_engine_open", dynlib: librocksdb.}
proc rocksdb_backup_engine_create_new_backup*(be: ptr rocksdb_backup_engine_t;
    db: ptr rocksdb_t; errptr: cstringArray) {.cdecl,
    importc: "rocksdb_backup_engine_create_new_backup", dynlib: librocksdb.}
proc rocksdb_backup_engine_purge_old_backups*(be: ptr rocksdb_backup_engine_t;
    num_backups_to_keep: uint32; errptr: cstringArray) {.cdecl,
    importc: "rocksdb_backup_engine_purge_old_backups", dynlib: librocksdb.}
proc rocksdb_restore_options_create*(): ptr rocksdb_restore_options_t {.cdecl,
    importc: "rocksdb_restore_options_create", dynlib: librocksdb.}
proc rocksdb_restore_options_destroy*(opt: ptr rocksdb_restore_options_t) {.cdecl,
    importc: "rocksdb_restore_options_destroy", dynlib: librocksdb.}
proc rocksdb_restore_options_set_keep_log_files*(
    opt: ptr rocksdb_restore_options_t; v: cint) {.cdecl,
    importc: "rocksdb_restore_options_set_keep_log_files", dynlib: librocksdb.}
proc rocksdb_backup_engine_restore_db_from_latest_backup*(
    be: ptr rocksdb_backup_engine_t; db_dir: cstring; wal_dir: cstring;
    restore_options: ptr rocksdb_restore_options_t; errptr: cstringArray) {.cdecl,
    importc: "rocksdb_backup_engine_restore_db_from_latest_backup",
    dynlib: librocksdb.}
proc rocksdb_backup_engine_get_backup_info*(be: ptr rocksdb_backup_engine_t): ptr rocksdb_backup_engine_info_t {.
    cdecl, importc: "rocksdb_backup_engine_get_backup_info", dynlib: librocksdb.}
proc rocksdb_backup_engine_info_count*(info: ptr rocksdb_backup_engine_info_t): cint {.
    cdecl, importc: "rocksdb_backup_engine_info_count", dynlib: librocksdb.}
proc rocksdb_backup_engine_info_timestamp*(
    info: ptr rocksdb_backup_engine_info_t; index: cint): int64 {.cdecl,
    importc: "rocksdb_backup_engine_info_timestamp", dynlib: librocksdb.}
proc rocksdb_backup_engine_info_backup_id*(
    info: ptr rocksdb_backup_engine_info_t; index: cint): uint32 {.cdecl,
    importc: "rocksdb_backup_engine_info_backup_id", dynlib: librocksdb.}
proc rocksdb_backup_engine_info_size*(info: ptr rocksdb_backup_engine_info_t;
                                     index: cint): uint64 {.cdecl,
    importc: "rocksdb_backup_engine_info_size", dynlib: librocksdb.}
proc rocksdb_backup_engine_info_number_files*(
    info: ptr rocksdb_backup_engine_info_t; index: cint): uint32 {.cdecl,
    importc: "rocksdb_backup_engine_info_number_files", dynlib: librocksdb.}
proc rocksdb_backup_engine_info_destroy*(info: ptr rocksdb_backup_engine_info_t) {.
    cdecl, importc: "rocksdb_backup_engine_info_destroy", dynlib: librocksdb.}
proc rocksdb_backup_engine_close*(be: ptr rocksdb_backup_engine_t) {.cdecl,
    importc: "rocksdb_backup_engine_close", dynlib: librocksdb.}
proc rocksdb_checkpoint_object_create*(db: ptr rocksdb_t; errptr: cstringArray): ptr rocksdb_checkpoint_t {.
    cdecl, importc: "rocksdb_checkpoint_object_create", dynlib: librocksdb.}
proc rocksdb_checkpoint_create*(checkpoint: ptr rocksdb_checkpoint_t;
                               checkpoint_dir: cstring;
                               log_size_for_flush: uint64; errptr: cstringArray) {.
    cdecl, importc: "rocksdb_checkpoint_create", dynlib: librocksdb.}
proc rocksdb_checkpoint_object_destroy*(checkpoint: ptr rocksdb_checkpoint_t) {.
    cdecl, importc: "rocksdb_checkpoint_object_destroy", dynlib: librocksdb.}
proc rocksdb_open_column_families*(options: ptr rocksdb_options_t; name: cstring;
                                  num_column_families: cint;
                                  column_family_names: cstringArray;
    column_family_options: ptr ptr rocksdb_options_t; column_family_handles: ptr ptr rocksdb_column_family_handle_t;
                                  errptr: cstringArray): ptr rocksdb_t {.cdecl,
    importc: "rocksdb_open_column_families", dynlib: librocksdb.}
proc rocksdb_open_for_read_only_column_families*(options: ptr rocksdb_options_t;
    name: cstring; num_column_families: cint; column_family_names: cstringArray;
    column_family_options: ptr ptr rocksdb_options_t;
    column_family_handles: ptr ptr rocksdb_column_family_handle_t;
    error_if_log_file_exist: cuchar; errptr: cstringArray): ptr rocksdb_t {.cdecl,
    importc: "rocksdb_open_for_read_only_column_families", dynlib: librocksdb.}
proc rocksdb_list_column_families*(options: ptr rocksdb_options_t; name: cstring;
                                  lencf: ptr csize; errptr: cstringArray): cstringArray {.
    cdecl, importc: "rocksdb_list_column_families", dynlib: librocksdb.}
proc rocksdb_list_column_families_destroy*(list: cstringArray; len: csize) {.cdecl,
    importc: "rocksdb_list_column_families_destroy", dynlib: librocksdb.}
proc rocksdb_create_column_family*(db: ptr rocksdb_t;
                                  column_family_options: ptr rocksdb_options_t;
                                  column_family_name: cstring;
                                  errptr: cstringArray): ptr rocksdb_column_family_handle_t {.
    cdecl, importc: "rocksdb_create_column_family", dynlib: librocksdb.}
proc rocksdb_drop_column_family*(db: ptr rocksdb_t;
                                handle: ptr rocksdb_column_family_handle_t;
                                errptr: cstringArray) {.cdecl,
    importc: "rocksdb_drop_column_family", dynlib: librocksdb.}
proc rocksdb_column_family_handle_destroy*(a2: ptr rocksdb_column_family_handle_t) {.
    cdecl, importc: "rocksdb_column_family_handle_destroy", dynlib: librocksdb.}
proc rocksdb_close*(db: ptr rocksdb_t) {.cdecl, importc: "rocksdb_close",
                                     dynlib: librocksdb.}
proc rocksdb_put*(db: ptr rocksdb_t; options: ptr rocksdb_writeoptions_t; key: cstring;
                 keylen: csize; val: cstring; vallen: csize; errptr: cstringArray) {.
    cdecl, importc: "rocksdb_put", dynlib: librocksdb.}
proc rocksdb_put_cf*(db: ptr rocksdb_t; options: ptr rocksdb_writeoptions_t;
                    column_family: ptr rocksdb_column_family_handle_t;
                    key: cstring; keylen: csize; val: cstring; vallen: csize;
                    errptr: cstringArray) {.cdecl, importc: "rocksdb_put_cf",
    dynlib: librocksdb.}
proc rocksdb_delete*(db: ptr rocksdb_t; options: ptr rocksdb_writeoptions_t;
                    key: cstring; keylen: csize; errptr: cstringArray) {.cdecl,
    importc: "rocksdb_delete", dynlib: librocksdb.}
proc rocksdb_delete_cf*(db: ptr rocksdb_t; options: ptr rocksdb_writeoptions_t;
                       column_family: ptr rocksdb_column_family_handle_t;
                       key: cstring; keylen: csize; errptr: cstringArray) {.cdecl,
    importc: "rocksdb_delete_cf", dynlib: librocksdb.}
proc rocksdb_merge*(db: ptr rocksdb_t; options: ptr rocksdb_writeoptions_t;
                   key: cstring; keylen: csize; val: cstring; vallen: csize;
                   errptr: cstringArray) {.cdecl, importc: "rocksdb_merge",
    dynlib: librocksdb.}
proc rocksdb_merge_cf*(db: ptr rocksdb_t; options: ptr rocksdb_writeoptions_t;
                      column_family: ptr rocksdb_column_family_handle_t;
                      key: cstring; keylen: csize; val: cstring; vallen: csize;
                      errptr: cstringArray) {.cdecl, importc: "rocksdb_merge_cf",
    dynlib: librocksdb.}
proc rocksdb_write*(db: ptr rocksdb_t; options: ptr rocksdb_writeoptions_t;
                   batch: ptr rocksdb_writebatch_t; errptr: cstringArray) {.cdecl,
    importc: "rocksdb_write", dynlib: librocksdb.}
##  Returns NULL if not found.  A malloc()ed array otherwise.
##    Stores the length of the array in *vallen.

proc rocksdb_get*(db: ptr rocksdb_t; options: ptr rocksdb_readoptions_t; key: cstring;
                 keylen: csize; vallen: ptr csize; errptr: cstringArray): cstring {.
    cdecl, importc: "rocksdb_get", dynlib: librocksdb.}
proc rocksdb_get_cf*(db: ptr rocksdb_t; options: ptr rocksdb_readoptions_t;
                    column_family: ptr rocksdb_column_family_handle_t;
                    key: cstring; keylen: csize; vallen: ptr csize;
                    errptr: cstringArray): cstring {.cdecl,
    importc: "rocksdb_get_cf", dynlib: librocksdb.}
##  if values_list[i] == NULL and errs[i] == NULL,
##  then we got status.IsNotFound(), which we will not return.
##  all errors except status status.ok() and status.IsNotFound() are returned.
## 
##  errs, values_list and values_list_sizes must be num_keys in length,
##  allocated by the caller.
##  errs is a list of strings as opposed to the conventional one error,
##  where errs[i] is the status for retrieval of keys_list[i].
##  each non-NULL errs entry is a malloc()ed, null terminated string.
##  each non-NULL values_list entry is a malloc()ed array, with
##  the length for each stored in values_list_sizes[i].

proc rocksdb_multi_get*(db: ptr rocksdb_t; options: ptr rocksdb_readoptions_t;
                       num_keys: csize; keys_list: cstringArray;
                       keys_list_sizes: ptr csize; values_list: cstringArray;
                       values_list_sizes: ptr csize; errs: cstringArray) {.cdecl,
    importc: "rocksdb_multi_get", dynlib: librocksdb.}
proc rocksdb_multi_get_cf*(db: ptr rocksdb_t; options: ptr rocksdb_readoptions_t;
    column_families: ptr ptr rocksdb_column_family_handle_t; num_keys: csize;
                          keys_list: cstringArray; keys_list_sizes: ptr csize;
                          values_list: cstringArray; values_list_sizes: ptr csize;
                          errs: cstringArray) {.cdecl,
    importc: "rocksdb_multi_get_cf", dynlib: librocksdb.}
proc rocksdb_create_iterator*(db: ptr rocksdb_t; options: ptr rocksdb_readoptions_t): ptr rocksdb_iterator_t {.
    cdecl, importc: "rocksdb_create_iterator", dynlib: librocksdb.}
proc rocksdb_create_iterator_cf*(db: ptr rocksdb_t;
                                options: ptr rocksdb_readoptions_t; column_family: ptr rocksdb_column_family_handle_t): ptr rocksdb_iterator_t {.
    cdecl, importc: "rocksdb_create_iterator_cf", dynlib: librocksdb.}
proc rocksdb_create_iterators*(db: ptr rocksdb_t; opts: ptr rocksdb_readoptions_t;
    column_families: ptr ptr rocksdb_column_family_handle_t;
                              iterators: ptr ptr rocksdb_iterator_t; size: csize;
                              errptr: cstringArray) {.cdecl,
    importc: "rocksdb_create_iterators", dynlib: librocksdb.}
proc rocksdb_create_snapshot*(db: ptr rocksdb_t): ptr rocksdb_snapshot_t {.cdecl,
    importc: "rocksdb_create_snapshot", dynlib: librocksdb.}
proc rocksdb_release_snapshot*(db: ptr rocksdb_t; snapshot: ptr rocksdb_snapshot_t) {.
    cdecl, importc: "rocksdb_release_snapshot", dynlib: librocksdb.}
##  Returns NULL if property name is unknown.
##    Else returns a pointer to a malloc()-ed null-terminated value.

proc rocksdb_property_value*(db: ptr rocksdb_t; propname: cstring): cstring {.cdecl,
    importc: "rocksdb_property_value", dynlib: librocksdb.}
##  returns 0 on success, -1 otherwise

proc rocksdb_property_int*(db: ptr rocksdb_t; propname: cstring; out_val: ptr uint64): cint {.
    cdecl, importc: "rocksdb_property_int", dynlib: librocksdb.}
proc rocksdb_property_value_cf*(db: ptr rocksdb_t; column_family: ptr rocksdb_column_family_handle_t;
                               propname: cstring): cstring {.cdecl,
    importc: "rocksdb_property_value_cf", dynlib: librocksdb.}
proc rocksdb_approximate_sizes*(db: ptr rocksdb_t; num_ranges: cint;
                               range_start_key: cstringArray;
                               range_start_key_len: ptr csize;
                               range_limit_key: cstringArray;
                               range_limit_key_len: ptr csize; sizes: ptr uint64) {.
    cdecl, importc: "rocksdb_approximate_sizes", dynlib: librocksdb.}
proc rocksdb_approximate_sizes_cf*(db: ptr rocksdb_t; column_family: ptr rocksdb_column_family_handle_t;
                                  num_ranges: cint; range_start_key: cstringArray;
                                  range_start_key_len: ptr csize;
                                  range_limit_key: cstringArray;
                                  range_limit_key_len: ptr csize; sizes: ptr uint64) {.
    cdecl, importc: "rocksdb_approximate_sizes_cf", dynlib: librocksdb.}
proc rocksdb_compact_range*(db: ptr rocksdb_t; start_key: cstring;
                           start_key_len: csize; limit_key: cstring;
                           limit_key_len: csize) {.cdecl,
    importc: "rocksdb_compact_range", dynlib: librocksdb.}
proc rocksdb_compact_range_cf*(db: ptr rocksdb_t; column_family: ptr rocksdb_column_family_handle_t;
                              start_key: cstring; start_key_len: csize;
                              limit_key: cstring; limit_key_len: csize) {.cdecl,
    importc: "rocksdb_compact_range_cf", dynlib: librocksdb.}
proc rocksdb_compact_range_opt*(db: ptr rocksdb_t;
                               opt: ptr rocksdb_compactoptions_t;
                               start_key: cstring; start_key_len: csize;
                               limit_key: cstring; limit_key_len: csize) {.cdecl,
    importc: "rocksdb_compact_range_opt", dynlib: librocksdb.}
proc rocksdb_compact_range_cf_opt*(db: ptr rocksdb_t; column_family: ptr rocksdb_column_family_handle_t;
                                  opt: ptr rocksdb_compactoptions_t;
                                  start_key: cstring; start_key_len: csize;
                                  limit_key: cstring; limit_key_len: csize) {.cdecl,
    importc: "rocksdb_compact_range_cf_opt", dynlib: librocksdb.}
proc rocksdb_delete_file*(db: ptr rocksdb_t; name: cstring) {.cdecl,
    importc: "rocksdb_delete_file", dynlib: librocksdb.}
proc rocksdb_livefiles*(db: ptr rocksdb_t): ptr rocksdb_livefiles_t {.cdecl,
    importc: "rocksdb_livefiles", dynlib: librocksdb.}
proc rocksdb_flush*(db: ptr rocksdb_t; options: ptr rocksdb_flushoptions_t;
                   errptr: cstringArray) {.cdecl, importc: "rocksdb_flush",
    dynlib: librocksdb.}
proc rocksdb_disable_file_deletions*(db: ptr rocksdb_t; errptr: cstringArray) {.cdecl,
    importc: "rocksdb_disable_file_deletions", dynlib: librocksdb.}
proc rocksdb_enable_file_deletions*(db: ptr rocksdb_t; force: cuchar;
                                   errptr: cstringArray) {.cdecl,
    importc: "rocksdb_enable_file_deletions", dynlib: librocksdb.}
##  Management operations

proc rocksdb_destroy_db*(options: ptr rocksdb_options_t; name: cstring;
                        errptr: cstringArray) {.cdecl,
    importc: "rocksdb_destroy_db", dynlib: librocksdb.}
proc rocksdb_repair_db*(options: ptr rocksdb_options_t; name: cstring;
                       errptr: cstringArray) {.cdecl, importc: "rocksdb_repair_db",
    dynlib: librocksdb.}
##  Iterator

proc rocksdb_iter_destroy*(a2: ptr rocksdb_iterator_t) {.cdecl,
    importc: "rocksdb_iter_destroy", dynlib: librocksdb.}
proc rocksdb_iter_valid*(a2: ptr rocksdb_iterator_t): cuchar {.cdecl,
    importc: "rocksdb_iter_valid", dynlib: librocksdb.}
proc rocksdb_iter_seek_to_first*(a2: ptr rocksdb_iterator_t) {.cdecl,
    importc: "rocksdb_iter_seek_to_first", dynlib: librocksdb.}
proc rocksdb_iter_seek_to_last*(a2: ptr rocksdb_iterator_t) {.cdecl,
    importc: "rocksdb_iter_seek_to_last", dynlib: librocksdb.}
proc rocksdb_iter_seek*(a2: ptr rocksdb_iterator_t; k: cstring; klen: csize) {.cdecl,
    importc: "rocksdb_iter_seek", dynlib: librocksdb.}
proc rocksdb_iter_seek_for_prev*(a2: ptr rocksdb_iterator_t; k: cstring; klen: csize) {.
    cdecl, importc: "rocksdb_iter_seek_for_prev", dynlib: librocksdb.}
proc rocksdb_iter_next*(a2: ptr rocksdb_iterator_t) {.cdecl,
    importc: "rocksdb_iter_next", dynlib: librocksdb.}
proc rocksdb_iter_prev*(a2: ptr rocksdb_iterator_t) {.cdecl,
    importc: "rocksdb_iter_prev", dynlib: librocksdb.}
proc rocksdb_iter_key*(a2: ptr rocksdb_iterator_t; klen: ptr csize): cstring {.cdecl,
    importc: "rocksdb_iter_key", dynlib: librocksdb.}
proc rocksdb_iter_value*(a2: ptr rocksdb_iterator_t; vlen: ptr csize): cstring {.cdecl,
    importc: "rocksdb_iter_value", dynlib: librocksdb.}
proc rocksdb_iter_get_error*(a2: ptr rocksdb_iterator_t; errptr: cstringArray) {.
    cdecl, importc: "rocksdb_iter_get_error", dynlib: librocksdb.}
##  Write batch

proc rocksdb_writebatch_create*(): ptr rocksdb_writebatch_t {.cdecl,
    importc: "rocksdb_writebatch_create", dynlib: librocksdb.}
proc rocksdb_writebatch_create_from*(rep: cstring; size: csize): ptr rocksdb_writebatch_t {.
    cdecl, importc: "rocksdb_writebatch_create_from", dynlib: librocksdb.}
proc rocksdb_writebatch_destroy*(a2: ptr rocksdb_writebatch_t) {.cdecl,
    importc: "rocksdb_writebatch_destroy", dynlib: librocksdb.}
proc rocksdb_writebatch_clear*(a2: ptr rocksdb_writebatch_t) {.cdecl,
    importc: "rocksdb_writebatch_clear", dynlib: librocksdb.}
proc rocksdb_writebatch_count*(a2: ptr rocksdb_writebatch_t): cint {.cdecl,
    importc: "rocksdb_writebatch_count", dynlib: librocksdb.}
proc rocksdb_writebatch_put*(a2: ptr rocksdb_writebatch_t; key: cstring; klen: csize;
                            val: cstring; vlen: csize) {.cdecl,
    importc: "rocksdb_writebatch_put", dynlib: librocksdb.}
proc rocksdb_writebatch_put_cf*(a2: ptr rocksdb_writebatch_t; column_family: ptr rocksdb_column_family_handle_t;
                               key: cstring; klen: csize; val: cstring; vlen: csize) {.
    cdecl, importc: "rocksdb_writebatch_put_cf", dynlib: librocksdb.}
proc rocksdb_writebatch_putv*(b: ptr rocksdb_writebatch_t; num_keys: cint;
                             keys_list: cstringArray; keys_list_sizes: ptr csize;
                             num_values: cint; values_list: cstringArray;
                             values_list_sizes: ptr csize) {.cdecl,
    importc: "rocksdb_writebatch_putv", dynlib: librocksdb.}
proc rocksdb_writebatch_putv_cf*(b: ptr rocksdb_writebatch_t; column_family: ptr rocksdb_column_family_handle_t;
                                num_keys: cint; keys_list: cstringArray;
                                keys_list_sizes: ptr csize; num_values: cint;
                                values_list: cstringArray;
                                values_list_sizes: ptr csize) {.cdecl,
    importc: "rocksdb_writebatch_putv_cf", dynlib: librocksdb.}
proc rocksdb_writebatch_merge*(a2: ptr rocksdb_writebatch_t; key: cstring;
                              klen: csize; val: cstring; vlen: csize) {.cdecl,
    importc: "rocksdb_writebatch_merge", dynlib: librocksdb.}
proc rocksdb_writebatch_merge_cf*(a2: ptr rocksdb_writebatch_t; column_family: ptr rocksdb_column_family_handle_t;
                                 key: cstring; klen: csize; val: cstring; vlen: csize) {.
    cdecl, importc: "rocksdb_writebatch_merge_cf", dynlib: librocksdb.}
proc rocksdb_writebatch_mergev*(b: ptr rocksdb_writebatch_t; num_keys: cint;
                               keys_list: cstringArray;
                               keys_list_sizes: ptr csize; num_values: cint;
                               values_list: cstringArray;
                               values_list_sizes: ptr csize) {.cdecl,
    importc: "rocksdb_writebatch_mergev", dynlib: librocksdb.}
proc rocksdb_writebatch_mergev_cf*(b: ptr rocksdb_writebatch_t; column_family: ptr rocksdb_column_family_handle_t;
                                  num_keys: cint; keys_list: cstringArray;
                                  keys_list_sizes: ptr csize; num_values: cint;
                                  values_list: cstringArray;
                                  values_list_sizes: ptr csize) {.cdecl,
    importc: "rocksdb_writebatch_mergev_cf", dynlib: librocksdb.}
proc rocksdb_writebatch_delete*(a2: ptr rocksdb_writebatch_t; key: cstring;
                               klen: csize) {.cdecl,
    importc: "rocksdb_writebatch_delete", dynlib: librocksdb.}
proc rocksdb_writebatch_delete_cf*(a2: ptr rocksdb_writebatch_t; column_family: ptr rocksdb_column_family_handle_t;
                                  key: cstring; klen: csize) {.cdecl,
    importc: "rocksdb_writebatch_delete_cf", dynlib: librocksdb.}
proc rocksdb_writebatch_deletev*(b: ptr rocksdb_writebatch_t; num_keys: cint;
                                keys_list: cstringArray;
                                keys_list_sizes: ptr csize) {.cdecl,
    importc: "rocksdb_writebatch_deletev", dynlib: librocksdb.}
proc rocksdb_writebatch_deletev_cf*(b: ptr rocksdb_writebatch_t; column_family: ptr rocksdb_column_family_handle_t;
                                   num_keys: cint; keys_list: cstringArray;
                                   keys_list_sizes: ptr csize) {.cdecl,
    importc: "rocksdb_writebatch_deletev_cf", dynlib: librocksdb.}
proc rocksdb_writebatch_delete_range*(b: ptr rocksdb_writebatch_t;
                                     start_key: cstring; start_key_len: csize;
                                     end_key: cstring; end_key_len: csize) {.cdecl,
    importc: "rocksdb_writebatch_delete_range", dynlib: librocksdb.}
proc rocksdb_writebatch_delete_range_cf*(b: ptr rocksdb_writebatch_t; column_family: ptr rocksdb_column_family_handle_t;
                                        start_key: cstring; start_key_len: csize;
                                        end_key: cstring; end_key_len: csize) {.
    cdecl, importc: "rocksdb_writebatch_delete_range_cf", dynlib: librocksdb.}
proc rocksdb_writebatch_delete_rangev*(b: ptr rocksdb_writebatch_t; num_keys: cint;
                                      start_keys_list: cstringArray;
                                      start_keys_list_sizes: ptr csize;
                                      end_keys_list: cstringArray;
                                      end_keys_list_sizes: ptr csize) {.cdecl,
    importc: "rocksdb_writebatch_delete_rangev", dynlib: librocksdb.}
proc rocksdb_writebatch_delete_rangev_cf*(b: ptr rocksdb_writebatch_t;
    column_family: ptr rocksdb_column_family_handle_t; num_keys: cint;
    start_keys_list: cstringArray; start_keys_list_sizes: ptr csize;
    end_keys_list: cstringArray; end_keys_list_sizes: ptr csize) {.cdecl,
    importc: "rocksdb_writebatch_delete_rangev_cf", dynlib: librocksdb.}
proc rocksdb_writebatch_put_log_data*(a2: ptr rocksdb_writebatch_t; blob: cstring;
                                     len: csize) {.cdecl,
    importc: "rocksdb_writebatch_put_log_data", dynlib: librocksdb.}
proc rocksdb_writebatch_iterate*(a2: ptr rocksdb_writebatch_t; state: pointer; put: proc (
    a2: pointer; k: cstring; klen: csize; v: cstring; vlen: csize) {.cdecl.}; deleted: proc (
    a2: pointer; k: cstring; klen: csize) {.cdecl.}) {.cdecl,
    importc: "rocksdb_writebatch_iterate", dynlib: librocksdb.}
proc rocksdb_writebatch_data*(a2: ptr rocksdb_writebatch_t; size: ptr csize): cstring {.
    cdecl, importc: "rocksdb_writebatch_data", dynlib: librocksdb.}
proc rocksdb_writebatch_set_save_point*(a2: ptr rocksdb_writebatch_t) {.cdecl,
    importc: "rocksdb_writebatch_set_save_point", dynlib: librocksdb.}
proc rocksdb_writebatch_rollback_to_save_point*(a2: ptr rocksdb_writebatch_t;
    errptr: cstringArray) {.cdecl,
                          importc: "rocksdb_writebatch_rollback_to_save_point",
                          dynlib: librocksdb.}
proc rocksdb_writebatch_pop_save_point*(a2: ptr rocksdb_writebatch_t;
                                       errptr: cstringArray) {.cdecl,
    importc: "rocksdb_writebatch_pop_save_point", dynlib: librocksdb.}
##  Write batch with index

proc rocksdb_writebatch_wi_create*(reserved_bytes: csize; overwrite_keys: cuchar): ptr rocksdb_writebatch_wi_t {.
    cdecl, importc: "rocksdb_writebatch_wi_create", dynlib: librocksdb.}
proc rocksdb_writebatch_wi_create_from*(rep: cstring; size: csize): ptr rocksdb_writebatch_wi_t {.
    cdecl, importc: "rocksdb_writebatch_wi_create_from", dynlib: librocksdb.}
proc rocksdb_writebatch_wi_destroy*(a2: ptr rocksdb_writebatch_wi_t) {.cdecl,
    importc: "rocksdb_writebatch_wi_destroy", dynlib: librocksdb.}
proc rocksdb_writebatch_wi_clear*(a2: ptr rocksdb_writebatch_wi_t) {.cdecl,
    importc: "rocksdb_writebatch_wi_clear", dynlib: librocksdb.}
proc rocksdb_writebatch_wi_count*(b: ptr rocksdb_writebatch_wi_t): cint {.cdecl,
    importc: "rocksdb_writebatch_wi_count", dynlib: librocksdb.}
proc rocksdb_writebatch_wi_put*(a2: ptr rocksdb_writebatch_wi_t; key: cstring;
                               klen: csize; val: cstring; vlen: csize) {.cdecl,
    importc: "rocksdb_writebatch_wi_put", dynlib: librocksdb.}
proc rocksdb_writebatch_wi_put_cf*(a2: ptr rocksdb_writebatch_wi_t; column_family: ptr rocksdb_column_family_handle_t;
                                  key: cstring; klen: csize; val: cstring; vlen: csize) {.
    cdecl, importc: "rocksdb_writebatch_wi_put_cf", dynlib: librocksdb.}
proc rocksdb_writebatch_wi_putv*(b: ptr rocksdb_writebatch_wi_t; num_keys: cint;
                                keys_list: cstringArray;
                                keys_list_sizes: ptr csize; num_values: cint;
                                values_list: cstringArray;
                                values_list_sizes: ptr csize) {.cdecl,
    importc: "rocksdb_writebatch_wi_putv", dynlib: librocksdb.}
proc rocksdb_writebatch_wi_putv_cf*(b: ptr rocksdb_writebatch_wi_t; column_family: ptr rocksdb_column_family_handle_t;
                                   num_keys: cint; keys_list: cstringArray;
                                   keys_list_sizes: ptr csize; num_values: cint;
                                   values_list: cstringArray;
                                   values_list_sizes: ptr csize) {.cdecl,
    importc: "rocksdb_writebatch_wi_putv_cf", dynlib: librocksdb.}
proc rocksdb_writebatch_wi_merge*(a2: ptr rocksdb_writebatch_wi_t; key: cstring;
                                 klen: csize; val: cstring; vlen: csize) {.cdecl,
    importc: "rocksdb_writebatch_wi_merge", dynlib: librocksdb.}
proc rocksdb_writebatch_wi_merge_cf*(a2: ptr rocksdb_writebatch_wi_t; column_family: ptr rocksdb_column_family_handle_t;
                                    key: cstring; klen: csize; val: cstring;
                                    vlen: csize) {.cdecl,
    importc: "rocksdb_writebatch_wi_merge_cf", dynlib: librocksdb.}
proc rocksdb_writebatch_wi_mergev*(b: ptr rocksdb_writebatch_wi_t; num_keys: cint;
                                  keys_list: cstringArray;
                                  keys_list_sizes: ptr csize; num_values: cint;
                                  values_list: cstringArray;
                                  values_list_sizes: ptr csize) {.cdecl,
    importc: "rocksdb_writebatch_wi_mergev", dynlib: librocksdb.}
proc rocksdb_writebatch_wi_mergev_cf*(b: ptr rocksdb_writebatch_wi_t; column_family: ptr rocksdb_column_family_handle_t;
                                     num_keys: cint; keys_list: cstringArray;
                                     keys_list_sizes: ptr csize; num_values: cint;
                                     values_list: cstringArray;
                                     values_list_sizes: ptr csize) {.cdecl,
    importc: "rocksdb_writebatch_wi_mergev_cf", dynlib: librocksdb.}
proc rocksdb_writebatch_wi_delete*(a2: ptr rocksdb_writebatch_wi_t; key: cstring;
                                  klen: csize) {.cdecl,
    importc: "rocksdb_writebatch_wi_delete", dynlib: librocksdb.}
proc rocksdb_writebatch_wi_delete_cf*(a2: ptr rocksdb_writebatch_wi_t; column_family: ptr rocksdb_column_family_handle_t;
                                     key: cstring; klen: csize) {.cdecl,
    importc: "rocksdb_writebatch_wi_delete_cf", dynlib: librocksdb.}
proc rocksdb_writebatch_wi_deletev*(b: ptr rocksdb_writebatch_wi_t; num_keys: cint;
                                   keys_list: cstringArray;
                                   keys_list_sizes: ptr csize) {.cdecl,
    importc: "rocksdb_writebatch_wi_deletev", dynlib: librocksdb.}
proc rocksdb_writebatch_wi_deletev_cf*(b: ptr rocksdb_writebatch_wi_t; column_family: ptr rocksdb_column_family_handle_t;
                                      num_keys: cint; keys_list: cstringArray;
                                      keys_list_sizes: ptr csize) {.cdecl,
    importc: "rocksdb_writebatch_wi_deletev_cf", dynlib: librocksdb.}
proc rocksdb_writebatch_wi_delete_range*(b: ptr rocksdb_writebatch_wi_t;
                                        start_key: cstring; start_key_len: csize;
                                        end_key: cstring; end_key_len: csize) {.
    cdecl, importc: "rocksdb_writebatch_wi_delete_range", dynlib: librocksdb.}
proc rocksdb_writebatch_wi_delete_range_cf*(b: ptr rocksdb_writebatch_wi_t;
    column_family: ptr rocksdb_column_family_handle_t; start_key: cstring;
    start_key_len: csize; end_key: cstring; end_key_len: csize) {.cdecl,
    importc: "rocksdb_writebatch_wi_delete_range_cf", dynlib: librocksdb.}
proc rocksdb_writebatch_wi_delete_rangev*(b: ptr rocksdb_writebatch_wi_t;
    num_keys: cint; start_keys_list: cstringArray; start_keys_list_sizes: ptr csize;
    end_keys_list: cstringArray; end_keys_list_sizes: ptr csize) {.cdecl,
    importc: "rocksdb_writebatch_wi_delete_rangev", dynlib: librocksdb.}
proc rocksdb_writebatch_wi_delete_rangev_cf*(b: ptr rocksdb_writebatch_wi_t;
    column_family: ptr rocksdb_column_family_handle_t; num_keys: cint;
    start_keys_list: cstringArray; start_keys_list_sizes: ptr csize;
    end_keys_list: cstringArray; end_keys_list_sizes: ptr csize) {.cdecl,
    importc: "rocksdb_writebatch_wi_delete_rangev_cf", dynlib: librocksdb.}
proc rocksdb_writebatch_wi_put_log_data*(a2: ptr rocksdb_writebatch_wi_t;
                                        blob: cstring; len: csize) {.cdecl,
    importc: "rocksdb_writebatch_wi_put_log_data", dynlib: librocksdb.}
proc rocksdb_writebatch_wi_iterate*(b: ptr rocksdb_writebatch_wi_t; state: pointer;
    put: proc (a2: pointer; k: cstring; klen: csize; v: cstring; vlen: csize) {.cdecl.};
    deleted: proc (a2: pointer; k: cstring; klen: csize) {.cdecl.}) {.cdecl,
    importc: "rocksdb_writebatch_wi_iterate", dynlib: librocksdb.}
proc rocksdb_writebatch_wi_data*(b: ptr rocksdb_writebatch_wi_t; size: ptr csize): cstring {.
    cdecl, importc: "rocksdb_writebatch_wi_data", dynlib: librocksdb.}
proc rocksdb_writebatch_wi_set_save_point*(a2: ptr rocksdb_writebatch_wi_t) {.cdecl,
    importc: "rocksdb_writebatch_wi_set_save_point", dynlib: librocksdb.}
proc rocksdb_writebatch_wi_rollback_to_save_point*(
    a2: ptr rocksdb_writebatch_wi_t; errptr: cstringArray) {.cdecl,
    importc: "rocksdb_writebatch_wi_rollback_to_save_point", dynlib: librocksdb.}
proc rocksdb_writebatch_wi_get_from_batch*(wbwi: ptr rocksdb_writebatch_wi_t;
    options: ptr rocksdb_options_t; key: cstring; keylen: csize; vallen: ptr csize;
    errptr: cstringArray): cstring {.cdecl, importc: "rocksdb_writebatch_wi_get_from_batch",
                                  dynlib: librocksdb.}
proc rocksdb_writebatch_wi_get_from_batch_cf*(wbwi: ptr rocksdb_writebatch_wi_t;
    options: ptr rocksdb_options_t;
    column_family: ptr rocksdb_column_family_handle_t; key: cstring; keylen: csize;
    vallen: ptr csize; errptr: cstringArray): cstring {.cdecl,
    importc: "rocksdb_writebatch_wi_get_from_batch_cf", dynlib: librocksdb.}
proc rocksdb_writebatch_wi_get_from_batch_and_db*(
    wbwi: ptr rocksdb_writebatch_wi_t; db: ptr rocksdb_t;
    options: ptr rocksdb_readoptions_t; key: cstring; keylen: csize; vallen: ptr csize;
    errptr: cstringArray): cstring {.cdecl, importc: "rocksdb_writebatch_wi_get_from_batch_and_db",
                                  dynlib: librocksdb.}
proc rocksdb_writebatch_wi_get_from_batch_and_db_cf*(
    wbwi: ptr rocksdb_writebatch_wi_t; db: ptr rocksdb_t;
    options: ptr rocksdb_readoptions_t;
    column_family: ptr rocksdb_column_family_handle_t; key: cstring; keylen: csize;
    vallen: ptr csize; errptr: cstringArray): cstring {.cdecl,
    importc: "rocksdb_writebatch_wi_get_from_batch_and_db_cf", dynlib: librocksdb.}
proc rocksdb_write_writebatch_wi*(db: ptr rocksdb_t;
                                 options: ptr rocksdb_writeoptions_t;
                                 wbwi: ptr rocksdb_writebatch_wi_t;
                                 errptr: cstringArray) {.cdecl,
    importc: "rocksdb_write_writebatch_wi", dynlib: librocksdb.}
proc rocksdb_writebatch_wi_create_iterator_with_base*(
    wbwi: ptr rocksdb_writebatch_wi_t; base_iterator: ptr rocksdb_iterator_t): ptr rocksdb_iterator_t {.
    cdecl, importc: "rocksdb_writebatch_wi_create_iterator_with_base",
    dynlib: librocksdb.}
proc rocksdb_writebatch_wi_create_iterator_with_base_cf*(
    wbwi: ptr rocksdb_writebatch_wi_t; base_iterator: ptr rocksdb_iterator_t;
    cf: ptr rocksdb_column_family_handle_t): ptr rocksdb_iterator_t {.cdecl,
    importc: "rocksdb_writebatch_wi_create_iterator_with_base_cf",
    dynlib: librocksdb.}
##  Block based table options

proc rocksdb_block_based_options_create*(): ptr rocksdb_block_based_table_options_t {.
    cdecl, importc: "rocksdb_block_based_options_create", dynlib: librocksdb.}
proc rocksdb_block_based_options_destroy*(
    options: ptr rocksdb_block_based_table_options_t) {.cdecl,
    importc: "rocksdb_block_based_options_destroy", dynlib: librocksdb.}
proc rocksdb_block_based_options_set_block_size*(
    options: ptr rocksdb_block_based_table_options_t; block_size: csize) {.cdecl,
    importc: "rocksdb_block_based_options_set_block_size", dynlib: librocksdb.}
proc rocksdb_block_based_options_set_block_size_deviation*(
    options: ptr rocksdb_block_based_table_options_t; block_size_deviation: cint) {.
    cdecl, importc: "rocksdb_block_based_options_set_block_size_deviation",
    dynlib: librocksdb.}
proc rocksdb_block_based_options_set_block_restart_interval*(
    options: ptr rocksdb_block_based_table_options_t; block_restart_interval: cint) {.
    cdecl, importc: "rocksdb_block_based_options_set_block_restart_interval",
    dynlib: librocksdb.}
proc rocksdb_block_based_options_set_index_block_restart_interval*(
    options: ptr rocksdb_block_based_table_options_t;
    index_block_restart_interval: cint) {.cdecl, importc: "rocksdb_block_based_options_set_index_block_restart_interval",
                                        dynlib: librocksdb.}
proc rocksdb_block_based_options_set_metadata_block_size*(
    options: ptr rocksdb_block_based_table_options_t; metadata_block_size: uint64) {.
    cdecl, importc: "rocksdb_block_based_options_set_metadata_block_size",
    dynlib: librocksdb.}
proc rocksdb_block_based_options_set_partition_filters*(
    options: ptr rocksdb_block_based_table_options_t; partition_filters: cuchar) {.
    cdecl, importc: "rocksdb_block_based_options_set_partition_filters",
    dynlib: librocksdb.}
proc rocksdb_block_based_options_set_use_delta_encoding*(
    options: ptr rocksdb_block_based_table_options_t; use_delta_encoding: cuchar) {.
    cdecl, importc: "rocksdb_block_based_options_set_use_delta_encoding",
    dynlib: librocksdb.}
proc rocksdb_block_based_options_set_filter_policy*(
    options: ptr rocksdb_block_based_table_options_t;
    filter_policy: ptr rocksdb_filterpolicy_t) {.cdecl,
    importc: "rocksdb_block_based_options_set_filter_policy", dynlib: librocksdb.}
proc rocksdb_block_based_options_set_no_block_cache*(
    options: ptr rocksdb_block_based_table_options_t; no_block_cache: cuchar) {.
    cdecl, importc: "rocksdb_block_based_options_set_no_block_cache",
    dynlib: librocksdb.}
proc rocksdb_block_based_options_set_block_cache*(
    options: ptr rocksdb_block_based_table_options_t;
    block_cache: ptr rocksdb_cache_t) {.cdecl, importc: "rocksdb_block_based_options_set_block_cache",
                                     dynlib: librocksdb.}
proc rocksdb_block_based_options_set_block_cache_compressed*(
    options: ptr rocksdb_block_based_table_options_t;
    block_cache_compressed: ptr rocksdb_cache_t) {.cdecl,
    importc: "rocksdb_block_based_options_set_block_cache_compressed",
    dynlib: librocksdb.}
proc rocksdb_block_based_options_set_whole_key_filtering*(
    a2: ptr rocksdb_block_based_table_options_t; a3: cuchar) {.cdecl,
    importc: "rocksdb_block_based_options_set_whole_key_filtering",
    dynlib: librocksdb.}
proc rocksdb_block_based_options_set_format_version*(
    a2: ptr rocksdb_block_based_table_options_t; a3: cint) {.cdecl,
    importc: "rocksdb_block_based_options_set_format_version", dynlib: librocksdb.}
const
  rocksdb_block_based_table_index_type_binary_search* = 0
  rocksdb_block_based_table_index_type_hash_search* = 1
  rocksdb_block_based_table_index_type_two_level_index_search* = 2

proc rocksdb_block_based_options_set_index_type*(
    a2: ptr rocksdb_block_based_table_options_t; a3: cint) {.cdecl,
    importc: "rocksdb_block_based_options_set_index_type", dynlib: librocksdb.}
##  uses one of the above enums

proc rocksdb_block_based_options_set_hash_index_allow_collision*(
    a2: ptr rocksdb_block_based_table_options_t; a3: cuchar) {.cdecl,
    importc: "rocksdb_block_based_options_set_hash_index_allow_collision",
    dynlib: librocksdb.}
proc rocksdb_block_based_options_set_cache_index_and_filter_blocks*(
    a2: ptr rocksdb_block_based_table_options_t; a3: cuchar) {.cdecl,
    importc: "rocksdb_block_based_options_set_cache_index_and_filter_blocks",
    dynlib: librocksdb.}
proc rocksdb_block_based_options_set_cache_index_and_filter_blocks_with_high_priority*(
    a2: ptr rocksdb_block_based_table_options_t; a3: cuchar) {.cdecl, importc: "rocksdb_block_based_options_set_cache_index_and_filter_blocks_with_high_priority",
    dynlib: librocksdb.}
proc rocksdb_block_based_options_set_pin_l0_filter_and_index_blocks_in_cache*(
    a2: ptr rocksdb_block_based_table_options_t; a3: cuchar) {.cdecl, importc: "rocksdb_block_based_options_set_pin_l0_filter_and_index_blocks_in_cache",
    dynlib: librocksdb.}
proc rocksdb_options_set_block_based_table_factory*(opt: ptr rocksdb_options_t;
    table_options: ptr rocksdb_block_based_table_options_t) {.cdecl,
    importc: "rocksdb_options_set_block_based_table_factory", dynlib: librocksdb.}
##  Cuckoo table options

proc rocksdb_cuckoo_options_create*(): ptr rocksdb_cuckoo_table_options_t {.cdecl,
    importc: "rocksdb_cuckoo_options_create", dynlib: librocksdb.}
proc rocksdb_cuckoo_options_destroy*(options: ptr rocksdb_cuckoo_table_options_t) {.
    cdecl, importc: "rocksdb_cuckoo_options_destroy", dynlib: librocksdb.}
proc rocksdb_cuckoo_options_set_hash_ratio*(
    options: ptr rocksdb_cuckoo_table_options_t; v: cdouble) {.cdecl,
    importc: "rocksdb_cuckoo_options_set_hash_ratio", dynlib: librocksdb.}
proc rocksdb_cuckoo_options_set_max_search_depth*(
    options: ptr rocksdb_cuckoo_table_options_t; v: uint32) {.cdecl,
    importc: "rocksdb_cuckoo_options_set_max_search_depth", dynlib: librocksdb.}
proc rocksdb_cuckoo_options_set_cuckoo_block_size*(
    options: ptr rocksdb_cuckoo_table_options_t; v: uint32) {.cdecl,
    importc: "rocksdb_cuckoo_options_set_cuckoo_block_size", dynlib: librocksdb.}
proc rocksdb_cuckoo_options_set_identity_as_first_hash*(
    options: ptr rocksdb_cuckoo_table_options_t; v: cuchar) {.cdecl,
    importc: "rocksdb_cuckoo_options_set_identity_as_first_hash",
    dynlib: librocksdb.}
proc rocksdb_cuckoo_options_set_use_module_hash*(
    options: ptr rocksdb_cuckoo_table_options_t; v: cuchar) {.cdecl,
    importc: "rocksdb_cuckoo_options_set_use_module_hash", dynlib: librocksdb.}
proc rocksdb_options_set_cuckoo_table_factory*(opt: ptr rocksdb_options_t;
    table_options: ptr rocksdb_cuckoo_table_options_t) {.cdecl,
    importc: "rocksdb_options_set_cuckoo_table_factory", dynlib: librocksdb.}
##  Options

proc rocksdb_set_options*(db: ptr rocksdb_t; count: cint; keys: ptr cstring;
                         values: ptr cstring; errptr: cstringArray) {.cdecl,
    importc: "rocksdb_set_options", dynlib: librocksdb.}
proc rocksdb_options_create*(): ptr rocksdb_options_t {.cdecl,
    importc: "rocksdb_options_create", dynlib: librocksdb.}
proc rocksdb_options_destroy*(a2: ptr rocksdb_options_t) {.cdecl,
    importc: "rocksdb_options_destroy", dynlib: librocksdb.}
proc rocksdb_options_increase_parallelism*(opt: ptr rocksdb_options_t;
    total_threads: cint) {.cdecl, importc: "rocksdb_options_increase_parallelism",
                         dynlib: librocksdb.}
proc rocksdb_options_optimize_for_point_lookup*(opt: ptr rocksdb_options_t;
    block_cache_size_mb: uint64) {.cdecl, importc: "rocksdb_options_optimize_for_point_lookup",
                                 dynlib: librocksdb.}
proc rocksdb_options_optimize_level_style_compaction*(opt: ptr rocksdb_options_t;
    memtable_memory_budget: uint64) {.cdecl, importc: "rocksdb_options_optimize_level_style_compaction",
                                    dynlib: librocksdb.}
proc rocksdb_options_optimize_universal_style_compaction*(
    opt: ptr rocksdb_options_t; memtable_memory_budget: uint64) {.cdecl,
    importc: "rocksdb_options_optimize_universal_style_compaction",
    dynlib: librocksdb.}
proc rocksdb_options_set_allow_ingest_behind*(a2: ptr rocksdb_options_t; a3: cuchar) {.
    cdecl, importc: "rocksdb_options_set_allow_ingest_behind", dynlib: librocksdb.}
proc rocksdb_options_set_compaction_filter*(a2: ptr rocksdb_options_t;
    a3: ptr rocksdb_compactionfilter_t) {.cdecl, importc: "rocksdb_options_set_compaction_filter",
                                       dynlib: librocksdb.}
proc rocksdb_options_set_compaction_filter_factory*(a2: ptr rocksdb_options_t;
    a3: ptr rocksdb_compactionfilterfactory_t) {.cdecl,
    importc: "rocksdb_options_set_compaction_filter_factory", dynlib: librocksdb.}
proc rocksdb_options_compaction_readahead_size*(a2: ptr rocksdb_options_t; a3: csize) {.
    cdecl, importc: "rocksdb_options_compaction_readahead_size", dynlib: librocksdb.}
proc rocksdb_options_set_comparator*(a2: ptr rocksdb_options_t;
                                    a3: ptr rocksdb_comparator_t) {.cdecl,
    importc: "rocksdb_options_set_comparator", dynlib: librocksdb.}
proc rocksdb_options_set_merge_operator*(a2: ptr rocksdb_options_t;
                                        a3: ptr rocksdb_mergeoperator_t) {.cdecl,
    importc: "rocksdb_options_set_merge_operator", dynlib: librocksdb.}
proc rocksdb_options_set_uint64add_merge_operator*(a2: ptr rocksdb_options_t) {.
    cdecl, importc: "rocksdb_options_set_uint64add_merge_operator",
    dynlib: librocksdb.}
proc rocksdb_options_set_compression_per_level*(opt: ptr rocksdb_options_t;
    level_values: ptr cint; num_levels: csize) {.cdecl,
    importc: "rocksdb_options_set_compression_per_level", dynlib: librocksdb.}
proc rocksdb_options_set_create_if_missing*(a2: ptr rocksdb_options_t; a3: cuchar) {.
    cdecl, importc: "rocksdb_options_set_create_if_missing", dynlib: librocksdb.}
proc rocksdb_options_set_create_missing_column_families*(
    a2: ptr rocksdb_options_t; a3: cuchar) {.cdecl, importc: "rocksdb_options_set_create_missing_column_families",
                                        dynlib: librocksdb.}
proc rocksdb_options_set_error_if_exists*(a2: ptr rocksdb_options_t; a3: cuchar) {.
    cdecl, importc: "rocksdb_options_set_error_if_exists", dynlib: librocksdb.}
proc rocksdb_options_set_paranoid_checks*(a2: ptr rocksdb_options_t; a3: cuchar) {.
    cdecl, importc: "rocksdb_options_set_paranoid_checks", dynlib: librocksdb.}
proc rocksdb_options_set_db_paths*(a2: ptr rocksdb_options_t;
                                  path_values: ptr ptr rocksdb_dbpath_t;
                                  num_paths: csize) {.cdecl,
    importc: "rocksdb_options_set_db_paths", dynlib: librocksdb.}
proc rocksdb_options_set_env*(a2: ptr rocksdb_options_t; a3: ptr rocksdb_env_t) {.
    cdecl, importc: "rocksdb_options_set_env", dynlib: librocksdb.}
proc rocksdb_options_set_info_log*(a2: ptr rocksdb_options_t;
                                  a3: ptr rocksdb_logger_t) {.cdecl,
    importc: "rocksdb_options_set_info_log", dynlib: librocksdb.}
proc rocksdb_options_set_info_log_level*(a2: ptr rocksdb_options_t; a3: cint) {.cdecl,
    importc: "rocksdb_options_set_info_log_level", dynlib: librocksdb.}
proc rocksdb_options_set_write_buffer_size*(a2: ptr rocksdb_options_t; a3: csize) {.
    cdecl, importc: "rocksdb_options_set_write_buffer_size", dynlib: librocksdb.}
proc rocksdb_options_set_db_write_buffer_size*(a2: ptr rocksdb_options_t; a3: csize) {.
    cdecl, importc: "rocksdb_options_set_db_write_buffer_size", dynlib: librocksdb.}
proc rocksdb_options_set_max_open_files*(a2: ptr rocksdb_options_t; a3: cint) {.cdecl,
    importc: "rocksdb_options_set_max_open_files", dynlib: librocksdb.}
proc rocksdb_options_set_max_file_opening_threads*(a2: ptr rocksdb_options_t;
    a3: cint) {.cdecl, importc: "rocksdb_options_set_max_file_opening_threads",
              dynlib: librocksdb.}
proc rocksdb_options_set_max_total_wal_size*(opt: ptr rocksdb_options_t; n: uint64) {.
    cdecl, importc: "rocksdb_options_set_max_total_wal_size", dynlib: librocksdb.}
proc rocksdb_options_set_compression_options*(a2: ptr rocksdb_options_t; a3: cint;
    a4: cint; a5: cint; a6: cint) {.cdecl, importc: "rocksdb_options_set_compression_options",
                              dynlib: librocksdb.}
proc rocksdb_options_set_prefix_extractor*(a2: ptr rocksdb_options_t;
    a3: ptr rocksdb_slicetransform_t) {.cdecl, importc: "rocksdb_options_set_prefix_extractor",
                                     dynlib: librocksdb.}
proc rocksdb_options_set_num_levels*(a2: ptr rocksdb_options_t; a3: cint) {.cdecl,
    importc: "rocksdb_options_set_num_levels", dynlib: librocksdb.}
proc rocksdb_options_set_level0_file_num_compaction_trigger*(
    a2: ptr rocksdb_options_t; a3: cint) {.cdecl, importc: "rocksdb_options_set_level0_file_num_compaction_trigger",
                                      dynlib: librocksdb.}
proc rocksdb_options_set_level0_slowdown_writes_trigger*(
    a2: ptr rocksdb_options_t; a3: cint) {.cdecl, importc: "rocksdb_options_set_level0_slowdown_writes_trigger",
                                      dynlib: librocksdb.}
proc rocksdb_options_set_level0_stop_writes_trigger*(a2: ptr rocksdb_options_t;
    a3: cint) {.cdecl, importc: "rocksdb_options_set_level0_stop_writes_trigger",
              dynlib: librocksdb.}
proc rocksdb_options_set_max_mem_compaction_level*(a2: ptr rocksdb_options_t;
    a3: cint) {.cdecl, importc: "rocksdb_options_set_max_mem_compaction_level",
              dynlib: librocksdb.}
proc rocksdb_options_set_target_file_size_base*(a2: ptr rocksdb_options_t;
    a3: uint64) {.cdecl, importc: "rocksdb_options_set_target_file_size_base",
                dynlib: librocksdb.}
proc rocksdb_options_set_target_file_size_multiplier*(a2: ptr rocksdb_options_t;
    a3: cint) {.cdecl, importc: "rocksdb_options_set_target_file_size_multiplier",
              dynlib: librocksdb.}
proc rocksdb_options_set_max_bytes_for_level_base*(a2: ptr rocksdb_options_t;
    a3: uint64) {.cdecl, importc: "rocksdb_options_set_max_bytes_for_level_base",
                dynlib: librocksdb.}
proc rocksdb_options_set_level_compaction_dynamic_level_bytes*(
    a2: ptr rocksdb_options_t; a3: cuchar) {.cdecl, importc: "rocksdb_options_set_level_compaction_dynamic_level_bytes",
                                        dynlib: librocksdb.}
proc rocksdb_options_set_max_bytes_for_level_multiplier*(
    a2: ptr rocksdb_options_t; a3: cdouble) {.cdecl,
    importc: "rocksdb_options_set_max_bytes_for_level_multiplier",
    dynlib: librocksdb.}
proc rocksdb_options_set_max_bytes_for_level_multiplier_additional*(
    a2: ptr rocksdb_options_t; level_values: ptr cint; num_levels: csize) {.cdecl,
    importc: "rocksdb_options_set_max_bytes_for_level_multiplier_additional",
    dynlib: librocksdb.}
proc rocksdb_options_enable_statistics*(a2: ptr rocksdb_options_t) {.cdecl,
    importc: "rocksdb_options_enable_statistics", dynlib: librocksdb.}
proc rocksdb_options_set_skip_stats_update_on_db_open*(
    opt: ptr rocksdb_options_t; val: cuchar) {.cdecl,
    importc: "rocksdb_options_set_skip_stats_update_on_db_open",
    dynlib: librocksdb.}
##  returns a pointer to a malloc()-ed, null terminated string

proc rocksdb_options_statistics_get_string*(opt: ptr rocksdb_options_t): cstring {.
    cdecl, importc: "rocksdb_options_statistics_get_string", dynlib: librocksdb.}
proc rocksdb_options_set_max_write_buffer_number*(a2: ptr rocksdb_options_t;
    a3: cint) {.cdecl, importc: "rocksdb_options_set_max_write_buffer_number",
              dynlib: librocksdb.}
proc rocksdb_options_set_min_write_buffer_number_to_merge*(
    a2: ptr rocksdb_options_t; a3: cint) {.cdecl, importc: "rocksdb_options_set_min_write_buffer_number_to_merge",
                                      dynlib: librocksdb.}
proc rocksdb_options_set_max_write_buffer_number_to_maintain*(
    a2: ptr rocksdb_options_t; a3: cint) {.cdecl, importc: "rocksdb_options_set_max_write_buffer_number_to_maintain",
                                      dynlib: librocksdb.}
proc rocksdb_options_set_max_background_compactions*(a2: ptr rocksdb_options_t;
    a3: cint) {.cdecl, importc: "rocksdb_options_set_max_background_compactions",
              dynlib: librocksdb.}
proc rocksdb_options_set_base_background_compactions*(a2: ptr rocksdb_options_t;
    a3: cint) {.cdecl, importc: "rocksdb_options_set_base_background_compactions",
              dynlib: librocksdb.}
proc rocksdb_options_set_max_background_flushes*(a2: ptr rocksdb_options_t; a3: cint) {.
    cdecl, importc: "rocksdb_options_set_max_background_flushes",
    dynlib: librocksdb.}
proc rocksdb_options_set_max_log_file_size*(a2: ptr rocksdb_options_t; a3: csize) {.
    cdecl, importc: "rocksdb_options_set_max_log_file_size", dynlib: librocksdb.}
proc rocksdb_options_set_log_file_time_to_roll*(a2: ptr rocksdb_options_t; a3: csize) {.
    cdecl, importc: "rocksdb_options_set_log_file_time_to_roll", dynlib: librocksdb.}
proc rocksdb_options_set_keep_log_file_num*(a2: ptr rocksdb_options_t; a3: csize) {.
    cdecl, importc: "rocksdb_options_set_keep_log_file_num", dynlib: librocksdb.}
proc rocksdb_options_set_recycle_log_file_num*(a2: ptr rocksdb_options_t; a3: csize) {.
    cdecl, importc: "rocksdb_options_set_recycle_log_file_num", dynlib: librocksdb.}
proc rocksdb_options_set_soft_rate_limit*(a2: ptr rocksdb_options_t; a3: cdouble) {.
    cdecl, importc: "rocksdb_options_set_soft_rate_limit", dynlib: librocksdb.}
proc rocksdb_options_set_hard_rate_limit*(a2: ptr rocksdb_options_t; a3: cdouble) {.
    cdecl, importc: "rocksdb_options_set_hard_rate_limit", dynlib: librocksdb.}
proc rocksdb_options_set_soft_pending_compaction_bytes_limit*(
    opt: ptr rocksdb_options_t; v: csize) {.cdecl, importc: "rocksdb_options_set_soft_pending_compaction_bytes_limit",
                                       dynlib: librocksdb.}
proc rocksdb_options_set_hard_pending_compaction_bytes_limit*(
    opt: ptr rocksdb_options_t; v: csize) {.cdecl, importc: "rocksdb_options_set_hard_pending_compaction_bytes_limit",
                                       dynlib: librocksdb.}
proc rocksdb_options_set_rate_limit_delay_max_milliseconds*(
    a2: ptr rocksdb_options_t; a3: cuint) {.cdecl, importc: "rocksdb_options_set_rate_limit_delay_max_milliseconds",
                                       dynlib: librocksdb.}
proc rocksdb_options_set_max_manifest_file_size*(a2: ptr rocksdb_options_t;
    a3: csize) {.cdecl, importc: "rocksdb_options_set_max_manifest_file_size",
               dynlib: librocksdb.}
proc rocksdb_options_set_table_cache_numshardbits*(a2: ptr rocksdb_options_t;
    a3: cint) {.cdecl, importc: "rocksdb_options_set_table_cache_numshardbits",
              dynlib: librocksdb.}
proc rocksdb_options_set_table_cache_remove_scan_count_limit*(
    a2: ptr rocksdb_options_t; a3: cint) {.cdecl, importc: "rocksdb_options_set_table_cache_remove_scan_count_limit",
                                      dynlib: librocksdb.}
proc rocksdb_options_set_arena_block_size*(a2: ptr rocksdb_options_t; a3: csize) {.
    cdecl, importc: "rocksdb_options_set_arena_block_size", dynlib: librocksdb.}
proc rocksdb_options_set_use_fsync*(a2: ptr rocksdb_options_t; a3: cint) {.cdecl,
    importc: "rocksdb_options_set_use_fsync", dynlib: librocksdb.}
proc rocksdb_options_set_db_log_dir*(a2: ptr rocksdb_options_t; a3: cstring) {.cdecl,
    importc: "rocksdb_options_set_db_log_dir", dynlib: librocksdb.}
proc rocksdb_options_set_wal_dir*(a2: ptr rocksdb_options_t; a3: cstring) {.cdecl,
    importc: "rocksdb_options_set_wal_dir", dynlib: librocksdb.}
proc rocksdb_options_set_WAL_ttl_seconds*(a2: ptr rocksdb_options_t; a3: uint64) {.
    cdecl, importc: "rocksdb_options_set_WAL_ttl_seconds", dynlib: librocksdb.}
proc rocksdb_options_set_WAL_size_limit_MB*(a2: ptr rocksdb_options_t; a3: uint64) {.
    cdecl, importc: "rocksdb_options_set_WAL_size_limit_MB", dynlib: librocksdb.}
proc rocksdb_options_set_manifest_preallocation_size*(a2: ptr rocksdb_options_t;
    a3: csize) {.cdecl, importc: "rocksdb_options_set_manifest_preallocation_size",
               dynlib: librocksdb.}
proc rocksdb_options_set_purge_redundant_kvs_while_flush*(
    a2: ptr rocksdb_options_t; a3: cuchar) {.cdecl, importc: "rocksdb_options_set_purge_redundant_kvs_while_flush",
                                        dynlib: librocksdb.}
proc rocksdb_options_set_allow_mmap_reads*(a2: ptr rocksdb_options_t; a3: cuchar) {.
    cdecl, importc: "rocksdb_options_set_allow_mmap_reads", dynlib: librocksdb.}
proc rocksdb_options_set_allow_mmap_writes*(a2: ptr rocksdb_options_t; a3: cuchar) {.
    cdecl, importc: "rocksdb_options_set_allow_mmap_writes", dynlib: librocksdb.}
proc rocksdb_options_set_use_direct_reads*(a2: ptr rocksdb_options_t; a3: cuchar) {.
    cdecl, importc: "rocksdb_options_set_use_direct_reads", dynlib: librocksdb.}
proc rocksdb_options_set_use_direct_io_for_flush_and_compaction*(
    a2: ptr rocksdb_options_t; a3: cuchar) {.cdecl, importc: "rocksdb_options_set_use_direct_io_for_flush_and_compaction",
                                        dynlib: librocksdb.}
proc rocksdb_options_set_is_fd_close_on_exec*(a2: ptr rocksdb_options_t; a3: cuchar) {.
    cdecl, importc: "rocksdb_options_set_is_fd_close_on_exec", dynlib: librocksdb.}
proc rocksdb_options_set_skip_log_error_on_recovery*(a2: ptr rocksdb_options_t;
    a3: cuchar) {.cdecl, importc: "rocksdb_options_set_skip_log_error_on_recovery",
                dynlib: librocksdb.}
proc rocksdb_options_set_stats_dump_period_sec*(a2: ptr rocksdb_options_t; a3: cuint) {.
    cdecl, importc: "rocksdb_options_set_stats_dump_period_sec", dynlib: librocksdb.}
proc rocksdb_options_set_advise_random_on_open*(a2: ptr rocksdb_options_t;
    a3: cuchar) {.cdecl, importc: "rocksdb_options_set_advise_random_on_open",
                dynlib: librocksdb.}
proc rocksdb_options_set_access_hint_on_compaction_start*(
    a2: ptr rocksdb_options_t; a3: cint) {.cdecl, importc: "rocksdb_options_set_access_hint_on_compaction_start",
                                      dynlib: librocksdb.}
proc rocksdb_options_set_use_adaptive_mutex*(a2: ptr rocksdb_options_t; a3: cuchar) {.
    cdecl, importc: "rocksdb_options_set_use_adaptive_mutex", dynlib: librocksdb.}
proc rocksdb_options_set_bytes_per_sync*(a2: ptr rocksdb_options_t; a3: uint64) {.
    cdecl, importc: "rocksdb_options_set_bytes_per_sync", dynlib: librocksdb.}
proc rocksdb_options_set_wal_bytes_per_sync*(a2: ptr rocksdb_options_t; a3: uint64) {.
    cdecl, importc: "rocksdb_options_set_wal_bytes_per_sync", dynlib: librocksdb.}
proc rocksdb_options_set_writable_file_max_buffer_size*(
    a2: ptr rocksdb_options_t; a3: uint64) {.cdecl, importc: "rocksdb_options_set_writable_file_max_buffer_size",
                                        dynlib: librocksdb.}
proc rocksdb_options_set_allow_concurrent_memtable_write*(
    a2: ptr rocksdb_options_t; a3: cuchar) {.cdecl, importc: "rocksdb_options_set_allow_concurrent_memtable_write",
                                        dynlib: librocksdb.}
proc rocksdb_options_set_enable_write_thread_adaptive_yield*(
    a2: ptr rocksdb_options_t; a3: cuchar) {.cdecl, importc: "rocksdb_options_set_enable_write_thread_adaptive_yield",
                                        dynlib: librocksdb.}
proc rocksdb_options_set_max_sequential_skip_in_iterations*(
    a2: ptr rocksdb_options_t; a3: uint64) {.cdecl, importc: "rocksdb_options_set_max_sequential_skip_in_iterations",
                                        dynlib: librocksdb.}
proc rocksdb_options_set_disable_auto_compactions*(a2: ptr rocksdb_options_t;
    a3: cint) {.cdecl, importc: "rocksdb_options_set_disable_auto_compactions",
              dynlib: librocksdb.}
proc rocksdb_options_set_optimize_filters_for_hits*(a2: ptr rocksdb_options_t;
    a3: cint) {.cdecl, importc: "rocksdb_options_set_optimize_filters_for_hits",
              dynlib: librocksdb.}
proc rocksdb_options_set_delete_obsolete_files_period_micros*(
    a2: ptr rocksdb_options_t; a3: uint64) {.cdecl, importc: "rocksdb_options_set_delete_obsolete_files_period_micros",
                                        dynlib: librocksdb.}
proc rocksdb_options_prepare_for_bulk_load*(a2: ptr rocksdb_options_t) {.cdecl,
    importc: "rocksdb_options_prepare_for_bulk_load", dynlib: librocksdb.}
proc rocksdb_options_set_memtable_vector_rep*(a2: ptr rocksdb_options_t) {.cdecl,
    importc: "rocksdb_options_set_memtable_vector_rep", dynlib: librocksdb.}
proc rocksdb_options_set_memtable_prefix_bloom_size_ratio*(
    a2: ptr rocksdb_options_t; a3: cdouble) {.cdecl,
    importc: "rocksdb_options_set_memtable_prefix_bloom_size_ratio",
    dynlib: librocksdb.}
proc rocksdb_options_set_max_compaction_bytes*(a2: ptr rocksdb_options_t; a3: uint64) {.
    cdecl, importc: "rocksdb_options_set_max_compaction_bytes", dynlib: librocksdb.}
proc rocksdb_options_set_hash_skip_list_rep*(a2: ptr rocksdb_options_t; a3: csize;
    a4: int32; a5: int32) {.cdecl, importc: "rocksdb_options_set_hash_skip_list_rep",
                        dynlib: librocksdb.}
proc rocksdb_options_set_hash_link_list_rep*(a2: ptr rocksdb_options_t; a3: csize) {.
    cdecl, importc: "rocksdb_options_set_hash_link_list_rep", dynlib: librocksdb.}
proc rocksdb_options_set_plain_table_factory*(a2: ptr rocksdb_options_t; a3: uint32;
    a4: cint; a5: cdouble; a6: csize) {.cdecl, importc: "rocksdb_options_set_plain_table_factory",
                                  dynlib: librocksdb.}
proc rocksdb_options_set_min_level_to_compress*(opt: ptr rocksdb_options_t;
    level: cint) {.cdecl, importc: "rocksdb_options_set_min_level_to_compress",
                 dynlib: librocksdb.}
proc rocksdb_options_set_memtable_huge_page_size*(a2: ptr rocksdb_options_t;
    a3: csize) {.cdecl, importc: "rocksdb_options_set_memtable_huge_page_size",
               dynlib: librocksdb.}
proc rocksdb_options_set_max_successive_merges*(a2: ptr rocksdb_options_t; a3: csize) {.
    cdecl, importc: "rocksdb_options_set_max_successive_merges", dynlib: librocksdb.}
proc rocksdb_options_set_bloom_locality*(a2: ptr rocksdb_options_t; a3: uint32) {.
    cdecl, importc: "rocksdb_options_set_bloom_locality", dynlib: librocksdb.}
proc rocksdb_options_set_inplace_update_support*(a2: ptr rocksdb_options_t;
    a3: cuchar) {.cdecl, importc: "rocksdb_options_set_inplace_update_support",
                dynlib: librocksdb.}
proc rocksdb_options_set_inplace_update_num_locks*(a2: ptr rocksdb_options_t;
    a3: csize) {.cdecl, importc: "rocksdb_options_set_inplace_update_num_locks",
               dynlib: librocksdb.}
proc rocksdb_options_set_report_bg_io_stats*(a2: ptr rocksdb_options_t; a3: cint) {.
    cdecl, importc: "rocksdb_options_set_report_bg_io_stats", dynlib: librocksdb.}
const
  rocksdb_tolerate_corrupted_tail_records_recovery* = 0
  rocksdb_absolute_consistency_recovery* = 1
  rocksdb_point_in_time_recovery* = 2
  rocksdb_skip_any_corrupted_records_recovery* = 3

proc rocksdb_options_set_wal_recovery_mode*(a2: ptr rocksdb_options_t; a3: cint) {.
    cdecl, importc: "rocksdb_options_set_wal_recovery_mode", dynlib: librocksdb.}
const
  rocksdb_no_compression* = 0
  rocksdb_snappy_compression* = 1
  rocksdb_zlib_compression* = 2
  rocksdb_bz2_compression* = 3
  rocksdb_lz4_compression* = 4
  rocksdb_lz4hc_compression* = 5
  rocksdb_xpress_compression* = 6
  rocksdb_zstd_compression* = 7

proc rocksdb_options_set_compression*(a2: ptr rocksdb_options_t; a3: cint) {.cdecl,
    importc: "rocksdb_options_set_compression", dynlib: librocksdb.}
const
  rocksdb_level_compaction* = 0
  rocksdb_universal_compaction* = 1
  rocksdb_fifo_compaction* = 2

proc rocksdb_options_set_compaction_style*(a2: ptr rocksdb_options_t; a3: cint) {.
    cdecl, importc: "rocksdb_options_set_compaction_style", dynlib: librocksdb.}
proc rocksdb_options_set_universal_compaction_options*(a2: ptr rocksdb_options_t;
    a3: ptr rocksdb_universal_compaction_options_t) {.cdecl,
    importc: "rocksdb_options_set_universal_compaction_options",
    dynlib: librocksdb.}
proc rocksdb_options_set_fifo_compaction_options*(opt: ptr rocksdb_options_t;
    fifo: ptr rocksdb_fifo_compaction_options_t) {.cdecl,
    importc: "rocksdb_options_set_fifo_compaction_options", dynlib: librocksdb.}
proc rocksdb_options_set_ratelimiter*(opt: ptr rocksdb_options_t;
                                     limiter: ptr rocksdb_ratelimiter_t) {.cdecl,
    importc: "rocksdb_options_set_ratelimiter", dynlib: librocksdb.}
##  RateLimiter

proc rocksdb_ratelimiter_create*(rate_bytes_per_sec: int64;
                                refill_period_us: int64; fairness: int32): ptr rocksdb_ratelimiter_t {.
    cdecl, importc: "rocksdb_ratelimiter_create", dynlib: librocksdb.}
proc rocksdb_ratelimiter_destroy*(a2: ptr rocksdb_ratelimiter_t) {.cdecl,
    importc: "rocksdb_ratelimiter_destroy", dynlib: librocksdb.}
##  Compaction Filter

proc rocksdb_compactionfilter_create*(state: pointer;
                                     destructor: proc (a2: pointer) {.cdecl.}; filter: proc (
    a2: pointer; level: cint; key: cstring; key_length: csize; existing_value: cstring;
    value_length: csize; new_value: cstringArray; new_value_length: ptr csize;
    value_changed: ptr cuchar): cuchar {.cdecl.};
                                     name: proc (a2: pointer): cstring {.cdecl.}): ptr rocksdb_compactionfilter_t {.
    cdecl, importc: "rocksdb_compactionfilter_create", dynlib: librocksdb.}
proc rocksdb_compactionfilter_set_ignore_snapshots*(
    a2: ptr rocksdb_compactionfilter_t; a3: cuchar) {.cdecl,
    importc: "rocksdb_compactionfilter_set_ignore_snapshots", dynlib: librocksdb.}
proc rocksdb_compactionfilter_destroy*(a2: ptr rocksdb_compactionfilter_t) {.cdecl,
    importc: "rocksdb_compactionfilter_destroy", dynlib: librocksdb.}
##  Compaction Filter Context

proc rocksdb_compactionfiltercontext_is_full_compaction*(
    context: ptr rocksdb_compactionfiltercontext_t): cuchar {.cdecl,
    importc: "rocksdb_compactionfiltercontext_is_full_compaction",
    dynlib: librocksdb.}
proc rocksdb_compactionfiltercontext_is_manual_compaction*(
    context: ptr rocksdb_compactionfiltercontext_t): cuchar {.cdecl,
    importc: "rocksdb_compactionfiltercontext_is_manual_compaction",
    dynlib: librocksdb.}
##  Compaction Filter Factory

proc rocksdb_compactionfilterfactory_create*(state: pointer;
    destructor: proc (a2: pointer) {.cdecl.}; create_compaction_filter: proc (
    a2: pointer; context: ptr rocksdb_compactionfiltercontext_t): ptr rocksdb_compactionfilter_t {.
    cdecl.}; name: proc (a2: pointer): cstring {.cdecl.}): ptr rocksdb_compactionfilterfactory_t {.
    cdecl, importc: "rocksdb_compactionfilterfactory_create", dynlib: librocksdb.}
proc rocksdb_compactionfilterfactory_destroy*(
    a2: ptr rocksdb_compactionfilterfactory_t) {.cdecl,
    importc: "rocksdb_compactionfilterfactory_destroy", dynlib: librocksdb.}
##  Comparator

proc rocksdb_comparator_create*(state: pointer;
                               destructor: proc (a2: pointer) {.cdecl.}; compare: proc (
    a2: pointer; a: cstring; alen: csize; b: cstring; blen: csize): cint {.cdecl.};
                               name: proc (a2: pointer): cstring {.cdecl.}): ptr rocksdb_comparator_t {.
    cdecl, importc: "rocksdb_comparator_create", dynlib: librocksdb.}
proc rocksdb_comparator_destroy*(a2: ptr rocksdb_comparator_t) {.cdecl,
    importc: "rocksdb_comparator_destroy", dynlib: librocksdb.}
##  Filter policy

proc rocksdb_filterpolicy_create*(state: pointer;
                                 destructor: proc (a2: pointer) {.cdecl.};
    create_filter: proc (a2: pointer; key_array: cstringArray;
                       key_length_array: ptr csize; num_keys: cint;
                       filter_length: ptr csize): cstring {.cdecl.}; key_may_match: proc (
    a2: pointer; key: cstring; length: csize; filter: cstring; filter_length: csize): cuchar {.
    cdecl.}; delete_filter: proc (a2: pointer; filter: cstring; filter_length: csize) {.
    cdecl.}; name: proc (a2: pointer): cstring {.cdecl.}): ptr rocksdb_filterpolicy_t {.
    cdecl, importc: "rocksdb_filterpolicy_create", dynlib: librocksdb.}
proc rocksdb_filterpolicy_destroy*(a2: ptr rocksdb_filterpolicy_t) {.cdecl,
    importc: "rocksdb_filterpolicy_destroy", dynlib: librocksdb.}
proc rocksdb_filterpolicy_create_bloom*(bits_per_key: cint): ptr rocksdb_filterpolicy_t {.
    cdecl, importc: "rocksdb_filterpolicy_create_bloom", dynlib: librocksdb.}
proc rocksdb_filterpolicy_create_bloom_full*(bits_per_key: cint): ptr rocksdb_filterpolicy_t {.
    cdecl, importc: "rocksdb_filterpolicy_create_bloom_full", dynlib: librocksdb.}
##  Merge Operator

proc rocksdb_mergeoperator_create*(state: pointer;
                                  destructor: proc (a2: pointer) {.cdecl.};
    full_merge: proc (a2: pointer; key: cstring; key_length: csize;
                    existing_value: cstring; existing_value_length: csize;
                    operands_list: cstringArray; operands_list_length: ptr csize;
                    num_operands: cint; success: ptr cuchar;
                    new_value_length: ptr csize): cstring {.cdecl.}; partial_merge: proc (
    a2: pointer; key: cstring; key_length: csize; operands_list: cstringArray;
    operands_list_length: ptr csize; num_operands: cint; success: ptr cuchar;
    new_value_length: ptr csize): cstring {.cdecl.}; delete_value: proc (a2: pointer;
    value: cstring; value_length: csize) {.cdecl.};
                                  name: proc (a2: pointer): cstring {.cdecl.}): ptr rocksdb_mergeoperator_t {.
    cdecl, importc: "rocksdb_mergeoperator_create", dynlib: librocksdb.}
proc rocksdb_mergeoperator_destroy*(a2: ptr rocksdb_mergeoperator_t) {.cdecl,
    importc: "rocksdb_mergeoperator_destroy", dynlib: librocksdb.}
##  Read options

proc rocksdb_readoptions_create*(): ptr rocksdb_readoptions_t {.cdecl,
    importc: "rocksdb_readoptions_create", dynlib: librocksdb.}
proc rocksdb_readoptions_destroy*(a2: ptr rocksdb_readoptions_t) {.cdecl,
    importc: "rocksdb_readoptions_destroy", dynlib: librocksdb.}
proc rocksdb_readoptions_set_verify_checksums*(a2: ptr rocksdb_readoptions_t;
    a3: cuchar) {.cdecl, importc: "rocksdb_readoptions_set_verify_checksums",
                dynlib: librocksdb.}
proc rocksdb_readoptions_set_fill_cache*(a2: ptr rocksdb_readoptions_t; a3: cuchar) {.
    cdecl, importc: "rocksdb_readoptions_set_fill_cache", dynlib: librocksdb.}
proc rocksdb_readoptions_set_snapshot*(a2: ptr rocksdb_readoptions_t;
                                      a3: ptr rocksdb_snapshot_t) {.cdecl,
    importc: "rocksdb_readoptions_set_snapshot", dynlib: librocksdb.}
proc rocksdb_readoptions_set_iterate_upper_bound*(a2: ptr rocksdb_readoptions_t;
    key: cstring; keylen: csize) {.cdecl, importc: "rocksdb_readoptions_set_iterate_upper_bound",
                               dynlib: librocksdb.}
proc rocksdb_readoptions_set_iterate_lower_bound*(a2: ptr rocksdb_readoptions_t;
    key: cstring; keylen: csize) {.cdecl, importc: "rocksdb_readoptions_set_iterate_lower_bound",
                               dynlib: librocksdb.}
proc rocksdb_readoptions_set_read_tier*(a2: ptr rocksdb_readoptions_t; a3: cint) {.
    cdecl, importc: "rocksdb_readoptions_set_read_tier", dynlib: librocksdb.}
proc rocksdb_readoptions_set_tailing*(a2: ptr rocksdb_readoptions_t; a3: cuchar) {.
    cdecl, importc: "rocksdb_readoptions_set_tailing", dynlib: librocksdb.}
proc rocksdb_readoptions_set_managed*(a2: ptr rocksdb_readoptions_t; a3: cuchar) {.
    cdecl, importc: "rocksdb_readoptions_set_managed", dynlib: librocksdb.}
proc rocksdb_readoptions_set_readahead_size*(a2: ptr rocksdb_readoptions_t;
    a3: csize) {.cdecl, importc: "rocksdb_readoptions_set_readahead_size",
               dynlib: librocksdb.}
proc rocksdb_readoptions_set_prefix_same_as_start*(a2: ptr rocksdb_readoptions_t;
    a3: cuchar) {.cdecl, importc: "rocksdb_readoptions_set_prefix_same_as_start",
                dynlib: librocksdb.}
proc rocksdb_readoptions_set_pin_data*(a2: ptr rocksdb_readoptions_t; a3: cuchar) {.
    cdecl, importc: "rocksdb_readoptions_set_pin_data", dynlib: librocksdb.}
proc rocksdb_readoptions_set_total_order_seek*(a2: ptr rocksdb_readoptions_t;
    a3: cuchar) {.cdecl, importc: "rocksdb_readoptions_set_total_order_seek",
                dynlib: librocksdb.}
proc rocksdb_readoptions_set_max_skippable_internal_keys*(
    a2: ptr rocksdb_readoptions_t; a3: uint64) {.cdecl,
    importc: "rocksdb_readoptions_set_max_skippable_internal_keys",
    dynlib: librocksdb.}
proc rocksdb_readoptions_set_background_purge_on_iterator_cleanup*(
    a2: ptr rocksdb_readoptions_t; a3: cuchar) {.cdecl,
    importc: "rocksdb_readoptions_set_background_purge_on_iterator_cleanup",
    dynlib: librocksdb.}
proc rocksdb_readoptions_set_ignore_range_deletions*(
    a2: ptr rocksdb_readoptions_t; a3: cuchar) {.cdecl,
    importc: "rocksdb_readoptions_set_ignore_range_deletions", dynlib: librocksdb.}
##  Write options

proc rocksdb_writeoptions_create*(): ptr rocksdb_writeoptions_t {.cdecl,
    importc: "rocksdb_writeoptions_create", dynlib: librocksdb.}
proc rocksdb_writeoptions_destroy*(a2: ptr rocksdb_writeoptions_t) {.cdecl,
    importc: "rocksdb_writeoptions_destroy", dynlib: librocksdb.}
proc rocksdb_writeoptions_set_sync*(a2: ptr rocksdb_writeoptions_t; a3: cuchar) {.
    cdecl, importc: "rocksdb_writeoptions_set_sync", dynlib: librocksdb.}
proc rocksdb_writeoptions_disable_WAL*(opt: ptr rocksdb_writeoptions_t;
                                      disable: cint) {.cdecl,
    importc: "rocksdb_writeoptions_disable_WAL", dynlib: librocksdb.}
proc rocksdb_writeoptions_set_ignore_missing_column_families*(
    a2: ptr rocksdb_writeoptions_t; a3: cuchar) {.cdecl,
    importc: "rocksdb_writeoptions_set_ignore_missing_column_families",
    dynlib: librocksdb.}
proc rocksdb_writeoptions_set_no_slowdown*(a2: ptr rocksdb_writeoptions_t;
    a3: cuchar) {.cdecl, importc: "rocksdb_writeoptions_set_no_slowdown",
                dynlib: librocksdb.}
proc rocksdb_writeoptions_set_low_pri*(a2: ptr rocksdb_writeoptions_t; a3: cuchar) {.
    cdecl, importc: "rocksdb_writeoptions_set_low_pri", dynlib: librocksdb.}
##  Compact range options

proc rocksdb_compactoptions_create*(): ptr rocksdb_compactoptions_t {.cdecl,
    importc: "rocksdb_compactoptions_create", dynlib: librocksdb.}
proc rocksdb_compactoptions_destroy*(a2: ptr rocksdb_compactoptions_t) {.cdecl,
    importc: "rocksdb_compactoptions_destroy", dynlib: librocksdb.}
proc rocksdb_compactoptions_set_exclusive_manual_compaction*(
    a2: ptr rocksdb_compactoptions_t; a3: cuchar) {.cdecl,
    importc: "rocksdb_compactoptions_set_exclusive_manual_compaction",
    dynlib: librocksdb.}
proc rocksdb_compactoptions_set_change_level*(a2: ptr rocksdb_compactoptions_t;
    a3: cuchar) {.cdecl, importc: "rocksdb_compactoptions_set_change_level",
                dynlib: librocksdb.}
proc rocksdb_compactoptions_set_target_level*(a2: ptr rocksdb_compactoptions_t;
    a3: cint) {.cdecl, importc: "rocksdb_compactoptions_set_target_level",
              dynlib: librocksdb.}
##  Flush options

proc rocksdb_flushoptions_create*(): ptr rocksdb_flushoptions_t {.cdecl,
    importc: "rocksdb_flushoptions_create", dynlib: librocksdb.}
proc rocksdb_flushoptions_destroy*(a2: ptr rocksdb_flushoptions_t) {.cdecl,
    importc: "rocksdb_flushoptions_destroy", dynlib: librocksdb.}
proc rocksdb_flushoptions_set_wait*(a2: ptr rocksdb_flushoptions_t; a3: cuchar) {.
    cdecl, importc: "rocksdb_flushoptions_set_wait", dynlib: librocksdb.}
##  Cache

proc rocksdb_cache_create_lru*(capacity: csize): ptr rocksdb_cache_t {.cdecl,
    importc: "rocksdb_cache_create_lru", dynlib: librocksdb.}
proc rocksdb_cache_destroy*(cache: ptr rocksdb_cache_t) {.cdecl,
    importc: "rocksdb_cache_destroy", dynlib: librocksdb.}
proc rocksdb_cache_set_capacity*(cache: ptr rocksdb_cache_t; capacity: csize) {.cdecl,
    importc: "rocksdb_cache_set_capacity", dynlib: librocksdb.}
proc rocksdb_cache_get_usage*(cache: ptr rocksdb_cache_t): csize {.cdecl,
    importc: "rocksdb_cache_get_usage", dynlib: librocksdb.}
proc rocksdb_cache_get_pinned_usage*(cache: ptr rocksdb_cache_t): csize {.cdecl,
    importc: "rocksdb_cache_get_pinned_usage", dynlib: librocksdb.}
##  DBPath

proc rocksdb_dbpath_create*(path: cstring; target_size: uint64): ptr rocksdb_dbpath_t {.
    cdecl, importc: "rocksdb_dbpath_create", dynlib: librocksdb.}
proc rocksdb_dbpath_destroy*(a2: ptr rocksdb_dbpath_t) {.cdecl,
    importc: "rocksdb_dbpath_destroy", dynlib: librocksdb.}
##  Env

proc rocksdb_create_default_env*(): ptr rocksdb_env_t {.cdecl,
    importc: "rocksdb_create_default_env", dynlib: librocksdb.}
proc rocksdb_create_mem_env*(): ptr rocksdb_env_t {.cdecl,
    importc: "rocksdb_create_mem_env", dynlib: librocksdb.}
proc rocksdb_env_set_background_threads*(env: ptr rocksdb_env_t; n: cint) {.cdecl,
    importc: "rocksdb_env_set_background_threads", dynlib: librocksdb.}
proc rocksdb_env_set_high_priority_background_threads*(env: ptr rocksdb_env_t;
    n: cint) {.cdecl, importc: "rocksdb_env_set_high_priority_background_threads",
             dynlib: librocksdb.}
proc rocksdb_env_join_all_threads*(env: ptr rocksdb_env_t) {.cdecl,
    importc: "rocksdb_env_join_all_threads", dynlib: librocksdb.}
proc rocksdb_env_destroy*(a2: ptr rocksdb_env_t) {.cdecl,
    importc: "rocksdb_env_destroy", dynlib: librocksdb.}
proc rocksdb_envoptions_create*(): ptr rocksdb_envoptions_t {.cdecl,
    importc: "rocksdb_envoptions_create", dynlib: librocksdb.}
proc rocksdb_envoptions_destroy*(opt: ptr rocksdb_envoptions_t) {.cdecl,
    importc: "rocksdb_envoptions_destroy", dynlib: librocksdb.}
##  SstFile

proc rocksdb_sstfilewriter_create*(env: ptr rocksdb_envoptions_t;
                                  io_options: ptr rocksdb_options_t): ptr rocksdb_sstfilewriter_t {.
    cdecl, importc: "rocksdb_sstfilewriter_create", dynlib: librocksdb.}
proc rocksdb_sstfilewriter_create_with_comparator*(env: ptr rocksdb_envoptions_t;
    io_options: ptr rocksdb_options_t; comparator: ptr rocksdb_comparator_t): ptr rocksdb_sstfilewriter_t {.
    cdecl, importc: "rocksdb_sstfilewriter_create_with_comparator",
    dynlib: librocksdb.}
proc rocksdb_sstfilewriter_open*(writer: ptr rocksdb_sstfilewriter_t; name: cstring;
                                errptr: cstringArray) {.cdecl,
    importc: "rocksdb_sstfilewriter_open", dynlib: librocksdb.}
proc rocksdb_sstfilewriter_add*(writer: ptr rocksdb_sstfilewriter_t; key: cstring;
                               keylen: csize; val: cstring; vallen: csize;
                               errptr: cstringArray) {.cdecl,
    importc: "rocksdb_sstfilewriter_add", dynlib: librocksdb.}
proc rocksdb_sstfilewriter_put*(writer: ptr rocksdb_sstfilewriter_t; key: cstring;
                               keylen: csize; val: cstring; vallen: csize;
                               errptr: cstringArray) {.cdecl,
    importc: "rocksdb_sstfilewriter_put", dynlib: librocksdb.}
proc rocksdb_sstfilewriter_merge*(writer: ptr rocksdb_sstfilewriter_t; key: cstring;
                                 keylen: csize; val: cstring; vallen: csize;
                                 errptr: cstringArray) {.cdecl,
    importc: "rocksdb_sstfilewriter_merge", dynlib: librocksdb.}
proc rocksdb_sstfilewriter_delete*(writer: ptr rocksdb_sstfilewriter_t;
                                  key: cstring; keylen: csize; errptr: cstringArray) {.
    cdecl, importc: "rocksdb_sstfilewriter_delete", dynlib: librocksdb.}
proc rocksdb_sstfilewriter_finish*(writer: ptr rocksdb_sstfilewriter_t;
                                  errptr: cstringArray) {.cdecl,
    importc: "rocksdb_sstfilewriter_finish", dynlib: librocksdb.}
proc rocksdb_sstfilewriter_destroy*(writer: ptr rocksdb_sstfilewriter_t) {.cdecl,
    importc: "rocksdb_sstfilewriter_destroy", dynlib: librocksdb.}
proc rocksdb_ingestexternalfileoptions_create*(): ptr rocksdb_ingestexternalfileoptions_t {.
    cdecl, importc: "rocksdb_ingestexternalfileoptions_create", dynlib: librocksdb.}
proc rocksdb_ingestexternalfileoptions_set_move_files*(
    opt: ptr rocksdb_ingestexternalfileoptions_t; move_files: cuchar) {.cdecl,
    importc: "rocksdb_ingestexternalfileoptions_set_move_files",
    dynlib: librocksdb.}
proc rocksdb_ingestexternalfileoptions_set_snapshot_consistency*(
    opt: ptr rocksdb_ingestexternalfileoptions_t; snapshot_consistency: cuchar) {.
    cdecl, importc: "rocksdb_ingestexternalfileoptions_set_snapshot_consistency",
    dynlib: librocksdb.}
proc rocksdb_ingestexternalfileoptions_set_allow_global_seqno*(
    opt: ptr rocksdb_ingestexternalfileoptions_t; allow_global_seqno: cuchar) {.
    cdecl, importc: "rocksdb_ingestexternalfileoptions_set_allow_global_seqno",
    dynlib: librocksdb.}
proc rocksdb_ingestexternalfileoptions_set_allow_blocking_flush*(
    opt: ptr rocksdb_ingestexternalfileoptions_t; allow_blocking_flush: cuchar) {.
    cdecl, importc: "rocksdb_ingestexternalfileoptions_set_allow_blocking_flush",
    dynlib: librocksdb.}
proc rocksdb_ingestexternalfileoptions_set_ingest_behind*(
    opt: ptr rocksdb_ingestexternalfileoptions_t; ingest_behind: cuchar) {.cdecl,
    importc: "rocksdb_ingestexternalfileoptions_set_ingest_behind",
    dynlib: librocksdb.}
proc rocksdb_ingestexternalfileoptions_destroy*(
    opt: ptr rocksdb_ingestexternalfileoptions_t) {.cdecl,
    importc: "rocksdb_ingestexternalfileoptions_destroy", dynlib: librocksdb.}
proc rocksdb_ingest_external_file*(db: ptr rocksdb_t; file_list: cstringArray;
                                  list_len: csize;
                                  opt: ptr rocksdb_ingestexternalfileoptions_t;
                                  errptr: cstringArray) {.cdecl,
    importc: "rocksdb_ingest_external_file", dynlib: librocksdb.}
proc rocksdb_ingest_external_file_cf*(db: ptr rocksdb_t; handle: ptr rocksdb_column_family_handle_t;
                                     file_list: cstringArray; list_len: csize; opt: ptr rocksdb_ingestexternalfileoptions_t;
                                     errptr: cstringArray) {.cdecl,
    importc: "rocksdb_ingest_external_file_cf", dynlib: librocksdb.}
##  SliceTransform

proc rocksdb_slicetransform_create*(state: pointer;
                                   destructor: proc (a2: pointer) {.cdecl.};
    transform: proc (a2: pointer; key: cstring; length: csize; dst_length: ptr csize): cstring {.
    cdecl.}; in_domain: proc (a2: pointer; key: cstring; length: csize): cuchar {.cdecl.};
    in_range: proc (a2: pointer; key: cstring; length: csize): cuchar {.cdecl.};
                                   name: proc (a2: pointer): cstring {.cdecl.}): ptr rocksdb_slicetransform_t {.
    cdecl, importc: "rocksdb_slicetransform_create", dynlib: librocksdb.}
proc rocksdb_slicetransform_create_fixed_prefix*(a2: csize): ptr rocksdb_slicetransform_t {.
    cdecl, importc: "rocksdb_slicetransform_create_fixed_prefix",
    dynlib: librocksdb.}
proc rocksdb_slicetransform_create_noop*(): ptr rocksdb_slicetransform_t {.cdecl,
    importc: "rocksdb_slicetransform_create_noop", dynlib: librocksdb.}
proc rocksdb_slicetransform_destroy*(a2: ptr rocksdb_slicetransform_t) {.cdecl,
    importc: "rocksdb_slicetransform_destroy", dynlib: librocksdb.}
##  Universal Compaction options

const
  rocksdb_similar_size_compaction_stop_style* = 0
  rocksdb_total_size_compaction_stop_style* = 1

proc rocksdb_universal_compaction_options_create*(): ptr rocksdb_universal_compaction_options_t {.
    cdecl, importc: "rocksdb_universal_compaction_options_create",
    dynlib: librocksdb.}
proc rocksdb_universal_compaction_options_set_size_ratio*(
    a2: ptr rocksdb_universal_compaction_options_t; a3: cint) {.cdecl,
    importc: "rocksdb_universal_compaction_options_set_size_ratio",
    dynlib: librocksdb.}
proc rocksdb_universal_compaction_options_set_min_merge_width*(
    a2: ptr rocksdb_universal_compaction_options_t; a3: cint) {.cdecl,
    importc: "rocksdb_universal_compaction_options_set_min_merge_width",
    dynlib: librocksdb.}
proc rocksdb_universal_compaction_options_set_max_merge_width*(
    a2: ptr rocksdb_universal_compaction_options_t; a3: cint) {.cdecl,
    importc: "rocksdb_universal_compaction_options_set_max_merge_width",
    dynlib: librocksdb.}
proc rocksdb_universal_compaction_options_set_max_size_amplification_percent*(
    a2: ptr rocksdb_universal_compaction_options_t; a3: cint) {.cdecl, importc: "rocksdb_universal_compaction_options_set_max_size_amplification_percent",
    dynlib: librocksdb.}
proc rocksdb_universal_compaction_options_set_compression_size_percent*(
    a2: ptr rocksdb_universal_compaction_options_t; a3: cint) {.cdecl, importc: "rocksdb_universal_compaction_options_set_compression_size_percent",
    dynlib: librocksdb.}
proc rocksdb_universal_compaction_options_set_stop_style*(
    a2: ptr rocksdb_universal_compaction_options_t; a3: cint) {.cdecl,
    importc: "rocksdb_universal_compaction_options_set_stop_style",
    dynlib: librocksdb.}
proc rocksdb_universal_compaction_options_destroy*(
    a2: ptr rocksdb_universal_compaction_options_t) {.cdecl,
    importc: "rocksdb_universal_compaction_options_destroy", dynlib: librocksdb.}
proc rocksdb_fifo_compaction_options_create*(): ptr rocksdb_fifo_compaction_options_t {.
    cdecl, importc: "rocksdb_fifo_compaction_options_create", dynlib: librocksdb.}
proc rocksdb_fifo_compaction_options_set_max_table_files_size*(
    fifo_opts: ptr rocksdb_fifo_compaction_options_t; size: uint64) {.cdecl,
    importc: "rocksdb_fifo_compaction_options_set_max_table_files_size",
    dynlib: librocksdb.}
proc rocksdb_fifo_compaction_options_destroy*(
    fifo_opts: ptr rocksdb_fifo_compaction_options_t) {.cdecl,
    importc: "rocksdb_fifo_compaction_options_destroy", dynlib: librocksdb.}
proc rocksdb_livefiles_count*(a2: ptr rocksdb_livefiles_t): cint {.cdecl,
    importc: "rocksdb_livefiles_count", dynlib: librocksdb.}
proc rocksdb_livefiles_name*(a2: ptr rocksdb_livefiles_t; index: cint): cstring {.
    cdecl, importc: "rocksdb_livefiles_name", dynlib: librocksdb.}
proc rocksdb_livefiles_level*(a2: ptr rocksdb_livefiles_t; index: cint): cint {.cdecl,
    importc: "rocksdb_livefiles_level", dynlib: librocksdb.}
proc rocksdb_livefiles_size*(a2: ptr rocksdb_livefiles_t; index: cint): csize {.cdecl,
    importc: "rocksdb_livefiles_size", dynlib: librocksdb.}
proc rocksdb_livefiles_smallestkey*(a2: ptr rocksdb_livefiles_t; index: cint;
                                   size: ptr csize): cstring {.cdecl,
    importc: "rocksdb_livefiles_smallestkey", dynlib: librocksdb.}
proc rocksdb_livefiles_largestkey*(a2: ptr rocksdb_livefiles_t; index: cint;
                                  size: ptr csize): cstring {.cdecl,
    importc: "rocksdb_livefiles_largestkey", dynlib: librocksdb.}
proc rocksdb_livefiles_destroy*(a2: ptr rocksdb_livefiles_t) {.cdecl,
    importc: "rocksdb_livefiles_destroy", dynlib: librocksdb.}
##  Utility Helpers

proc rocksdb_get_options_from_string*(base_options: ptr rocksdb_options_t;
                                     opts_str: cstring;
                                     new_options: ptr rocksdb_options_t;
                                     errptr: cstringArray) {.cdecl,
    importc: "rocksdb_get_options_from_string", dynlib: librocksdb.}
proc rocksdb_delete_file_in_range*(db: ptr rocksdb_t; start_key: cstring;
                                  start_key_len: csize; limit_key: cstring;
                                  limit_key_len: csize; errptr: cstringArray) {.
    cdecl, importc: "rocksdb_delete_file_in_range", dynlib: librocksdb.}
proc rocksdb_delete_file_in_range_cf*(db: ptr rocksdb_t; column_family: ptr rocksdb_column_family_handle_t;
                                     start_key: cstring; start_key_len: csize;
                                     limit_key: cstring; limit_key_len: csize;
                                     errptr: cstringArray) {.cdecl,
    importc: "rocksdb_delete_file_in_range_cf", dynlib: librocksdb.}
##  Transactions

proc rocksdb_transactiondb_create_column_family*(
    txn_db: ptr rocksdb_transactiondb_t;
    column_family_options: ptr rocksdb_options_t; column_family_name: cstring;
    errptr: cstringArray): ptr rocksdb_column_family_handle_t {.cdecl,
    importc: "rocksdb_transactiondb_create_column_family", dynlib: librocksdb.}
proc rocksdb_transactiondb_open*(options: ptr rocksdb_options_t; txn_db_options: ptr rocksdb_transactiondb_options_t;
                                name: cstring; errptr: cstringArray): ptr rocksdb_transactiondb_t {.
    cdecl, importc: "rocksdb_transactiondb_open", dynlib: librocksdb.}
proc rocksdb_transactiondb_create_snapshot*(txn_db: ptr rocksdb_transactiondb_t): ptr rocksdb_snapshot_t {.
    cdecl, importc: "rocksdb_transactiondb_create_snapshot", dynlib: librocksdb.}
proc rocksdb_transactiondb_release_snapshot*(txn_db: ptr rocksdb_transactiondb_t;
    snapshot: ptr rocksdb_snapshot_t) {.cdecl, importc: "rocksdb_transactiondb_release_snapshot",
                                     dynlib: librocksdb.}
proc rocksdb_transaction_begin*(txn_db: ptr rocksdb_transactiondb_t;
                               write_options: ptr rocksdb_writeoptions_t;
                               txn_options: ptr rocksdb_transaction_options_t;
                               old_txn: ptr rocksdb_transaction_t): ptr rocksdb_transaction_t {.
    cdecl, importc: "rocksdb_transaction_begin", dynlib: librocksdb.}
proc rocksdb_transaction_commit*(txn: ptr rocksdb_transaction_t;
                                errptr: cstringArray) {.cdecl,
    importc: "rocksdb_transaction_commit", dynlib: librocksdb.}
proc rocksdb_transaction_rollback*(txn: ptr rocksdb_transaction_t;
                                  errptr: cstringArray) {.cdecl,
    importc: "rocksdb_transaction_rollback", dynlib: librocksdb.}
proc rocksdb_transaction_set_savepoint*(txn: ptr rocksdb_transaction_t) {.cdecl,
    importc: "rocksdb_transaction_set_savepoint", dynlib: librocksdb.}
proc rocksdb_transaction_rollback_to_savepoint*(txn: ptr rocksdb_transaction_t;
    errptr: cstringArray) {.cdecl,
                          importc: "rocksdb_transaction_rollback_to_savepoint",
                          dynlib: librocksdb.}
proc rocksdb_transaction_destroy*(txn: ptr rocksdb_transaction_t) {.cdecl,
    importc: "rocksdb_transaction_destroy", dynlib: librocksdb.}
##  This snapshot should be freed using rocksdb_free

proc rocksdb_transaction_get_snapshot*(txn: ptr rocksdb_transaction_t): ptr rocksdb_snapshot_t {.
    cdecl, importc: "rocksdb_transaction_get_snapshot", dynlib: librocksdb.}
proc rocksdb_transaction_get*(txn: ptr rocksdb_transaction_t;
                             options: ptr rocksdb_readoptions_t; key: cstring;
                             klen: csize; vlen: ptr csize; errptr: cstringArray): cstring {.
    cdecl, importc: "rocksdb_transaction_get", dynlib: librocksdb.}
proc rocksdb_transaction_get_cf*(txn: ptr rocksdb_transaction_t;
                                options: ptr rocksdb_readoptions_t; column_family: ptr rocksdb_column_family_handle_t;
                                key: cstring; klen: csize; vlen: ptr csize;
                                errptr: cstringArray): cstring {.cdecl,
    importc: "rocksdb_transaction_get_cf", dynlib: librocksdb.}
proc rocksdb_transaction_get_for_update*(txn: ptr rocksdb_transaction_t;
                                        options: ptr rocksdb_readoptions_t;
                                        key: cstring; klen: csize; vlen: ptr csize;
                                        exclusive: cuchar; errptr: cstringArray): cstring {.
    cdecl, importc: "rocksdb_transaction_get_for_update", dynlib: librocksdb.}
proc rocksdb_transactiondb_get*(txn_db: ptr rocksdb_transactiondb_t;
                               options: ptr rocksdb_readoptions_t; key: cstring;
                               klen: csize; vlen: ptr csize; errptr: cstringArray): cstring {.
    cdecl, importc: "rocksdb_transactiondb_get", dynlib: librocksdb.}
proc rocksdb_transactiondb_get_cf*(txn_db: ptr rocksdb_transactiondb_t;
                                  options: ptr rocksdb_readoptions_t; column_family: ptr rocksdb_column_family_handle_t;
                                  key: cstring; keylen: csize; vallen: ptr csize;
                                  errptr: cstringArray): cstring {.cdecl,
    importc: "rocksdb_transactiondb_get_cf", dynlib: librocksdb.}
proc rocksdb_transaction_put*(txn: ptr rocksdb_transaction_t; key: cstring;
                             klen: csize; val: cstring; vlen: csize;
                             errptr: cstringArray) {.cdecl,
    importc: "rocksdb_transaction_put", dynlib: librocksdb.}
proc rocksdb_transaction_put_cf*(txn: ptr rocksdb_transaction_t; column_family: ptr rocksdb_column_family_handle_t;
                                key: cstring; klen: csize; val: cstring; vlen: csize;
                                errptr: cstringArray) {.cdecl,
    importc: "rocksdb_transaction_put_cf", dynlib: librocksdb.}
proc rocksdb_transactiondb_put*(txn_db: ptr rocksdb_transactiondb_t;
                               options: ptr rocksdb_writeoptions_t; key: cstring;
                               klen: csize; val: cstring; vlen: csize;
                               errptr: cstringArray) {.cdecl,
    importc: "rocksdb_transactiondb_put", dynlib: librocksdb.}
proc rocksdb_transactiondb_put_cf*(txn_db: ptr rocksdb_transactiondb_t;
                                  options: ptr rocksdb_writeoptions_t;
    column_family: ptr rocksdb_column_family_handle_t; key: cstring; keylen: csize;
                                  val: cstring; vallen: csize; errptr: cstringArray) {.
    cdecl, importc: "rocksdb_transactiondb_put_cf", dynlib: librocksdb.}
proc rocksdb_transactiondb_write*(txn_db: ptr rocksdb_transactiondb_t;
                                 options: ptr rocksdb_writeoptions_t;
                                 batch: ptr rocksdb_writebatch_t;
                                 errptr: cstringArray) {.cdecl,
    importc: "rocksdb_transactiondb_write", dynlib: librocksdb.}
proc rocksdb_transaction_merge*(txn: ptr rocksdb_transaction_t; key: cstring;
                               klen: csize; val: cstring; vlen: csize;
                               errptr: cstringArray) {.cdecl,
    importc: "rocksdb_transaction_merge", dynlib: librocksdb.}
proc rocksdb_transactiondb_merge*(txn_db: ptr rocksdb_transactiondb_t;
                                 options: ptr rocksdb_writeoptions_t; key: cstring;
                                 klen: csize; val: cstring; vlen: csize;
                                 errptr: cstringArray) {.cdecl,
    importc: "rocksdb_transactiondb_merge", dynlib: librocksdb.}
proc rocksdb_transaction_delete*(txn: ptr rocksdb_transaction_t; key: cstring;
                                klen: csize; errptr: cstringArray) {.cdecl,
    importc: "rocksdb_transaction_delete", dynlib: librocksdb.}
proc rocksdb_transaction_delete_cf*(txn: ptr rocksdb_transaction_t; column_family: ptr rocksdb_column_family_handle_t;
                                   key: cstring; klen: csize; errptr: cstringArray) {.
    cdecl, importc: "rocksdb_transaction_delete_cf", dynlib: librocksdb.}
proc rocksdb_transactiondb_delete*(txn_db: ptr rocksdb_transactiondb_t;
                                  options: ptr rocksdb_writeoptions_t;
                                  key: cstring; klen: csize; errptr: cstringArray) {.
    cdecl, importc: "rocksdb_transactiondb_delete", dynlib: librocksdb.}
proc rocksdb_transactiondb_delete_cf*(txn_db: ptr rocksdb_transactiondb_t;
                                     options: ptr rocksdb_writeoptions_t;
    column_family: ptr rocksdb_column_family_handle_t; key: cstring; keylen: csize;
                                     errptr: cstringArray) {.cdecl,
    importc: "rocksdb_transactiondb_delete_cf", dynlib: librocksdb.}
proc rocksdb_transaction_create_iterator*(txn: ptr rocksdb_transaction_t;
    options: ptr rocksdb_readoptions_t): ptr rocksdb_iterator_t {.cdecl,
    importc: "rocksdb_transaction_create_iterator", dynlib: librocksdb.}
proc rocksdb_transaction_create_iterator_cf*(txn: ptr rocksdb_transaction_t;
    options: ptr rocksdb_readoptions_t;
    column_family: ptr rocksdb_column_family_handle_t): ptr rocksdb_iterator_t {.
    cdecl, importc: "rocksdb_transaction_create_iterator_cf", dynlib: librocksdb.}
proc rocksdb_transactiondb_create_iterator*(txn_db: ptr rocksdb_transactiondb_t;
    options: ptr rocksdb_readoptions_t): ptr rocksdb_iterator_t {.cdecl,
    importc: "rocksdb_transactiondb_create_iterator", dynlib: librocksdb.}
proc rocksdb_transactiondb_close*(txn_db: ptr rocksdb_transactiondb_t) {.cdecl,
    importc: "rocksdb_transactiondb_close", dynlib: librocksdb.}
proc rocksdb_transactiondb_checkpoint_object_create*(
    txn_db: ptr rocksdb_transactiondb_t; errptr: cstringArray): ptr rocksdb_checkpoint_t {.
    cdecl, importc: "rocksdb_transactiondb_checkpoint_object_create",
    dynlib: librocksdb.}
proc rocksdb_optimistictransactiondb_open*(options: ptr rocksdb_options_t;
    name: cstring; errptr: cstringArray): ptr rocksdb_optimistictransactiondb_t {.
    cdecl, importc: "rocksdb_optimistictransactiondb_open", dynlib: librocksdb.}
proc rocksdb_optimistictransactiondb_open_column_families*(
    options: ptr rocksdb_options_t; name: cstring; num_column_families: cint;
    column_family_names: cstringArray;
    column_family_options: ptr ptr rocksdb_options_t;
    column_family_handles: ptr ptr rocksdb_column_family_handle_t;
    errptr: cstringArray): ptr rocksdb_optimistictransactiondb_t {.cdecl,
    importc: "rocksdb_optimistictransactiondb_open_column_families",
    dynlib: librocksdb.}
proc rocksdb_optimistictransactiondb_get_base_db*(
    otxn_db: ptr rocksdb_optimistictransactiondb_t): ptr rocksdb_t {.cdecl,
    importc: "rocksdb_optimistictransactiondb_get_base_db", dynlib: librocksdb.}
proc rocksdb_optimistictransactiondb_close_base_db*(base_db: ptr rocksdb_t) {.cdecl,
    importc: "rocksdb_optimistictransactiondb_close_base_db", dynlib: librocksdb.}
proc rocksdb_optimistictransaction_begin*(
    otxn_db: ptr rocksdb_optimistictransactiondb_t;
    write_options: ptr rocksdb_writeoptions_t;
    otxn_options: ptr rocksdb_optimistictransaction_options_t;
    old_txn: ptr rocksdb_transaction_t): ptr rocksdb_transaction_t {.cdecl,
    importc: "rocksdb_optimistictransaction_begin", dynlib: librocksdb.}
proc rocksdb_optimistictransactiondb_close*(
    otxn_db: ptr rocksdb_optimistictransactiondb_t) {.cdecl,
    importc: "rocksdb_optimistictransactiondb_close", dynlib: librocksdb.}
##  Transaction Options

proc rocksdb_transactiondb_options_create*(): ptr rocksdb_transactiondb_options_t {.
    cdecl, importc: "rocksdb_transactiondb_options_create", dynlib: librocksdb.}
proc rocksdb_transactiondb_options_destroy*(
    opt: ptr rocksdb_transactiondb_options_t) {.cdecl,
    importc: "rocksdb_transactiondb_options_destroy", dynlib: librocksdb.}
proc rocksdb_transactiondb_options_set_max_num_locks*(
    opt: ptr rocksdb_transactiondb_options_t; max_num_locks: int64) {.cdecl,
    importc: "rocksdb_transactiondb_options_set_max_num_locks", dynlib: librocksdb.}
proc rocksdb_transactiondb_options_set_num_stripes*(
    opt: ptr rocksdb_transactiondb_options_t; num_stripes: csize) {.cdecl,
    importc: "rocksdb_transactiondb_options_set_num_stripes", dynlib: librocksdb.}
proc rocksdb_transactiondb_options_set_transaction_lock_timeout*(
    opt: ptr rocksdb_transactiondb_options_t; txn_lock_timeout: int64) {.cdecl,
    importc: "rocksdb_transactiondb_options_set_transaction_lock_timeout",
    dynlib: librocksdb.}
proc rocksdb_transactiondb_options_set_default_lock_timeout*(
    opt: ptr rocksdb_transactiondb_options_t; default_lock_timeout: int64) {.cdecl,
    importc: "rocksdb_transactiondb_options_set_default_lock_timeout",
    dynlib: librocksdb.}
proc rocksdb_transaction_options_create*(): ptr rocksdb_transaction_options_t {.
    cdecl, importc: "rocksdb_transaction_options_create", dynlib: librocksdb.}
proc rocksdb_transaction_options_destroy*(opt: ptr rocksdb_transaction_options_t) {.
    cdecl, importc: "rocksdb_transaction_options_destroy", dynlib: librocksdb.}
proc rocksdb_transaction_options_set_set_snapshot*(
    opt: ptr rocksdb_transaction_options_t; v: cuchar) {.cdecl,
    importc: "rocksdb_transaction_options_set_set_snapshot", dynlib: librocksdb.}
proc rocksdb_transaction_options_set_deadlock_detect*(
    opt: ptr rocksdb_transaction_options_t; v: cuchar) {.cdecl,
    importc: "rocksdb_transaction_options_set_deadlock_detect", dynlib: librocksdb.}
proc rocksdb_transaction_options_set_lock_timeout*(
    opt: ptr rocksdb_transaction_options_t; lock_timeout: int64) {.cdecl,
    importc: "rocksdb_transaction_options_set_lock_timeout", dynlib: librocksdb.}
proc rocksdb_transaction_options_set_expiration*(
    opt: ptr rocksdb_transaction_options_t; expiration: int64) {.cdecl,
    importc: "rocksdb_transaction_options_set_expiration", dynlib: librocksdb.}
proc rocksdb_transaction_options_set_deadlock_detect_depth*(
    opt: ptr rocksdb_transaction_options_t; depth: int64) {.cdecl,
    importc: "rocksdb_transaction_options_set_deadlock_detect_depth",
    dynlib: librocksdb.}
proc rocksdb_transaction_options_set_max_write_batch_size*(
    opt: ptr rocksdb_transaction_options_t; size: csize) {.cdecl,
    importc: "rocksdb_transaction_options_set_max_write_batch_size",
    dynlib: librocksdb.}
proc rocksdb_optimistictransaction_options_create*(): ptr rocksdb_optimistictransaction_options_t {.
    cdecl, importc: "rocksdb_optimistictransaction_options_create",
    dynlib: librocksdb.}
proc rocksdb_optimistictransaction_options_destroy*(
    opt: ptr rocksdb_optimistictransaction_options_t) {.cdecl,
    importc: "rocksdb_optimistictransaction_options_destroy", dynlib: librocksdb.}
proc rocksdb_optimistictransaction_options_set_set_snapshot*(
    opt: ptr rocksdb_optimistictransaction_options_t; v: cuchar) {.cdecl,
    importc: "rocksdb_optimistictransaction_options_set_set_snapshot",
    dynlib: librocksdb.}
##  referring to convention (3), this should be used by client
##  to free memory that was malloc()ed

proc rocksdb_free*(`ptr`: pointer) {.cdecl, importc: "rocksdb_free",
                                  dynlib: librocksdb.}
proc rocksdb_get_pinned*(db: ptr rocksdb_t; options: ptr rocksdb_readoptions_t;
                        key: cstring; keylen: csize; errptr: cstringArray): ptr rocksdb_pinnableslice_t {.
    cdecl, importc: "rocksdb_get_pinned", dynlib: librocksdb.}
proc rocksdb_get_pinned_cf*(db: ptr rocksdb_t; options: ptr rocksdb_readoptions_t;
                           column_family: ptr rocksdb_column_family_handle_t;
                           key: cstring; keylen: csize; errptr: cstringArray): ptr rocksdb_pinnableslice_t {.
    cdecl, importc: "rocksdb_get_pinned_cf", dynlib: librocksdb.}
proc rocksdb_pinnableslice_destroy*(v: ptr rocksdb_pinnableslice_t) {.cdecl,
    importc: "rocksdb_pinnableslice_destroy", dynlib: librocksdb.}
proc rocksdb_pinnableslice_value*(t: ptr rocksdb_pinnableslice_t; vlen: ptr csize): cstring {.
    cdecl, importc: "rocksdb_pinnableslice_value", dynlib: librocksdb.}