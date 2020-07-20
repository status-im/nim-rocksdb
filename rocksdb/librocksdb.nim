# Nim-RocksDB
# Copyright 2018 Status Research & Development GmbH
# Licensed under either of
#
#  * Apache License, version 2.0, ([LICENSE-APACHE](LICENSE-APACHE) or http://www.apache.org/licenses/LICENSE-2.0)
#  * GPL license, version 2.0, ([LICENSE-GPLv2](LICENSE-GPLv2) or https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)
#
# at your option. This file may not be copied, modified, or distributed except according to those terms.

# Nim-RocksDB is a wrapper for Facebook's RocksDB
# Copyright (c) 2011-present, Facebook, Inc.  All rights reserved.
# This source code is licensed under both the GPLv2 (found in the
# COPYING file in the root directory) and Apache 2.0 License
# (found in the LICENSE.Apache file in the root directory).
# Copyright (c) 2011 The LevelDB Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file. See the AUTHORS file for names of contributors.
#
# C bindings for rocksdb.  May be useful as a stable ABI that can be
# used by programs that keep rocksdb in a shared library, or for
# a JNI api.
#
# Does not support:
# . getters for the option types
# . custom comparators that implement key shortening
# . capturing post-write-snapshot
# . custom iter, db, env, cache implementations using just the C bindings
#
# Some conventions:
#
# (1) We expose just opaque struct pointers and functions to clients.
# This allows us to change internal representations without having to
# recompile clients.
#
# (2) For simplicity, there is no equivalent to the Slice type.  Instead,
# the caller has to pass the pointer and length as separate
# arguments.
#
# (3) Errors are represented by a null-terminated c string.  NULL
# means no error.  All operations that can raise an error are passed
# a "char** errptr" as the last argument.  One of the following must
# be true on entry:
# errptr == NULL
# errptr points to a malloc()ed null-terminated error message
# On success, a leveldb routine leaves *errptr unchanged.
# On failure, leveldb frees the old value of *errptr and
# set *errptr to a malloc()ed error message.
#
# (4) Bools have the type unsigned char (0 == false; rest == true)
#
# (5) All of the pointer arguments must be non-NULL.

## This file exposes the low-level C API of RocksDB

{.push raises: [].}

{.deadCodeElim: on.}
when defined(windows):
  const librocksdb = "librocksdb(|_lite).dll"
elif defined(macosx):
  const librocksdb = "librocksdb(|_lite).dylib"
else:
  # TODO linking to just the .so file here is wrong:
  # * soname of library is librocksdb.so.X.Y, indicating that ABI compatibility
  #   is kept for patches only, and may break for minor versions
  # * linking like this makes the wrapper swallow any ABI version that the user
  #   happens to have installed when running the application - notably this may
  #   be completely different from what the developer used when writing the
  #   wrapper
  # * with good luck, the above will lead to crashes that are hard to diagnose
  #   with bad luck, it will be exploited as a security hole
  # * Fedora28 for example ships with soname librocksdb.so.5.7 while Ubuntu
  #   14.04 (what travis uses at the time of writing) comes with 4.5!
  const librocksdb = "librocksdb(|_lite).so"
##  Exported types

proc shouldUseNativeLinking(): bool {.compileTime.} =
  when defined(linux):
    return true

template rocksType(T) =
  type T* = distinct pointer
  proc isNil*(v: T): bool {.borrow.}

rocksType rocksdb_t
rocksType rocksdb_backup_engine_t
rocksType rocksdb_backup_engine_info_t
rocksType rocksdb_restore_options_t
rocksType rocksdb_cache_t
rocksType rocksdb_compactionfilter_t
rocksType rocksdb_compactionfiltercontext_t
rocksType rocksdb_compactionfilterfactory_t
rocksType rocksdb_comparator_t
rocksType rocksdb_dbpath_t
rocksType rocksdb_env_t
rocksType rocksdb_fifo_compaction_options_t
rocksType rocksdb_filelock_t
rocksType rocksdb_filterpolicy_t
rocksType rocksdb_flushoptions_t
rocksType rocksdb_iterator_t
rocksType rocksdb_logger_t
rocksType rocksdb_mergeoperator_t
rocksType rocksdb_options_t
rocksType rocksdb_compactoptions_t
rocksType rocksdb_block_based_table_options_t
rocksType rocksdb_cuckoo_table_options_t
rocksType rocksdb_randomfile_t
rocksType rocksdb_readoptions_t
rocksType rocksdb_seqfile_t
rocksType rocksdb_slicetransform_t
rocksType rocksdb_snapshot_t
rocksType rocksdb_writablefile_t
rocksType rocksdb_writebatch_t
rocksType rocksdb_writebatch_wi_t
rocksType rocksdb_writeoptions_t
rocksType rocksdb_universal_compaction_options_t
rocksType rocksdb_livefiles_t
rocksType rocksdb_column_family_handle_t
rocksType rocksdb_envoptions_t
rocksType rocksdb_ingestexternalfileoptions_t
rocksType rocksdb_sstfilewriter_t
rocksType rocksdb_ratelimiter_t
rocksType rocksdb_pinnableslice_t
rocksType rocksdb_transactiondb_options_t
rocksType rocksdb_transactiondb_t
rocksType rocksdb_transaction_options_t
rocksType rocksdb_optimistictransactiondb_t
rocksType rocksdb_optimistictransaction_options_t
rocksType rocksdb_transaction_t
rocksType rocksdb_checkpoint_t
rocksType rocksdb_wal_readoptions_t
rocksType rocksdb_wal_iterator_t
rocksType rocksdb_perfcontext_t
rocksType rocksdb_memory_consumers_t
rocksType rocksdb_memory_usage_t

##  DB operations
when shouldUseNativeLinking():
  {.pragma: importrocks, importc, cdecl.}
  {.passL: "-lrocksdb".}
else:
  {.pragma: importrocks, importc, cdecl, dynlib: librocksdb.}

proc rocksdb_open*(options: rocksdb_options_t; name: cstring; errptr: ptr cstring): rocksdb_t {.importrocks.}
proc rocksdb_open_with_ttl*(options: rocksdb_options_t; name: cstring; ttl: cint;
                           errptr: ptr cstring): rocksdb_t {.importrocks.}
proc rocksdb_open_for_read_only*(options: rocksdb_options_t; name: cstring;
                                error_if_log_file_exist: uint8;
                                errptr: ptr cstring): rocksdb_t {.importrocks.}
proc rocksdb_open_as_secondary*(options: rocksdb_options_t; name: cstring;
                               secondary_path: cstring; errptr: ptr cstring): rocksdb_t {.importrocks.}
proc rocksdb_backup_engine_open*(options: rocksdb_options_t; path: cstring;
                                errptr: ptr cstring): rocksdb_backup_engine_t {.importrocks.}
proc rocksdb_backup_engine_create_new_backup*(be: rocksdb_backup_engine_t;
    db: rocksdb_t; errptr: ptr cstring) {.importrocks.}
proc rocksdb_backup_engine_create_new_backup_flush*(
    be: rocksdb_backup_engine_t; db: rocksdb_t; flush_before_backup: uint8;
    errptr: ptr cstring) {.importrocks.}
proc rocksdb_backup_engine_purge_old_backups*(be: rocksdb_backup_engine_t;
    num_backups_to_keep: uint32; errptr: ptr cstring) {.importrocks.}
proc rocksdb_restore_options_create*(): rocksdb_restore_options_t {.importrocks.}
proc rocksdb_restore_options_destroy*(opt: rocksdb_restore_options_t) {.importrocks.}
proc rocksdb_restore_options_set_keep_log_files*(
    opt: rocksdb_restore_options_t; v: cint) {.importrocks.}
proc rocksdb_backup_engine_verify_backup*(be: rocksdb_backup_engine_t;
    backup_id: uint32; errptr: ptr cstring) {.importrocks.}
proc rocksdb_backup_engine_restore_db_from_latest_backup*(
    be: rocksdb_backup_engine_t; db_dir: cstring; wal_dir: cstring;
    restore_options: rocksdb_restore_options_t; errptr: ptr cstring) {.importrocks.}
proc rocksdb_backup_engine_restore_db_from_backup*(
    be: rocksdb_backup_engine_t; db_dir: cstring; wal_dir: cstring;
    restore_options: rocksdb_restore_options_t; backup_id: uint32;
    errptr: ptr cstring) {.importrocks.}
proc rocksdb_backup_engine_get_backup_info*(be: rocksdb_backup_engine_t): rocksdb_backup_engine_info_t {.importrocks.}
proc rocksdb_backup_engine_info_count*(info: rocksdb_backup_engine_info_t): cint {.importrocks.}
proc rocksdb_backup_engine_info_timestamp*(
    info: rocksdb_backup_engine_info_t; index: cint): int64 {.importrocks.}
proc rocksdb_backup_engine_info_backup_id*(
    info: rocksdb_backup_engine_info_t; index: cint): uint32 {.importrocks.}
proc rocksdb_backup_engine_info_size*(info: rocksdb_backup_engine_info_t;
                                     index: cint): uint64 {.importrocks.}
proc rocksdb_backup_engine_info_number_files*(
    info: rocksdb_backup_engine_info_t; index: cint): uint32 {.importrocks.}
proc rocksdb_backup_engine_info_destroy*(info: rocksdb_backup_engine_info_t) {.importrocks.}
proc rocksdb_backup_engine_close*(be: rocksdb_backup_engine_t) {.importrocks.}
proc rocksdb_checkpoint_object_create*(db: rocksdb_t; errptr: ptr cstring): rocksdb_checkpoint_t {.importrocks.}
proc rocksdb_checkpoint_create*(checkpoint: rocksdb_checkpoint_t;
                               checkpoint_dir: cstring;
                               log_size_for_flush: uint64; errptr: ptr cstring) {.importrocks.}
proc rocksdb_checkpoint_object_destroy*(checkpoint: rocksdb_checkpoint_t) {.importrocks.}
proc rocksdb_open_column_families*(options: rocksdb_options_t; name: cstring;
                                  num_column_families: cint;
                                  column_family_names: cstringArray;
    column_family_options: ptr rocksdb_options_t; column_family_handles: ptr rocksdb_column_family_handle_t;
                                  errptr: ptr cstring): rocksdb_t {.importrocks.}
proc rocksdb_open_for_read_only_column_families*(options: rocksdb_options_t;
    name: cstring; num_column_families: cint; column_family_names: cstringArray;
    column_family_options: ptr rocksdb_options_t;
    column_family_handles: ptr rocksdb_column_family_handle_t;
    error_if_log_file_exist: uint8; errptr: ptr cstring): rocksdb_t {.importrocks.}
proc rocksdb_open_as_secondary_column_families*(options: rocksdb_options_t;
    name: cstring; secondary_path: cstring; num_column_families: cint;
    column_family_names: ptr cstring;
    column_family_options: ptr rocksdb_options_t;
    colummn_family_handles: ptr rocksdb_column_family_handle_t;
    errptr: ptr cstring): rocksdb_t {.importrocks.}
proc rocksdb_list_column_families*(options: rocksdb_options_t; name: cstring;
                                  lencf: ptr csize_t; errptr: ptr cstring): cstringArray {.importrocks.}
proc rocksdb_list_column_families_destroy*(list: cstringArray; len: csize_t) {.importrocks.}
proc rocksdb_create_column_family*(db: rocksdb_t;
                                  column_family_options: rocksdb_options_t;
                                  column_family_name: cstring;
                                  errptr: ptr cstring): rocksdb_column_family_handle_t {.importrocks.}
proc rocksdb_drop_column_family*(db: rocksdb_t;
                                handle: rocksdb_column_family_handle_t;
                                errptr: ptr cstring) {.importrocks.}
proc rocksdb_column_family_handle_destroy*(a1: rocksdb_column_family_handle_t) {.importrocks.}
proc rocksdb_close*(db: rocksdb_t) {.importrocks.}
proc rocksdb_put*(db: rocksdb_t; options: rocksdb_writeoptions_t; key: cstring;
                 keylen: csize_t; val: cstring; vallen: csize_t; errptr: ptr cstring) {.importrocks.}
proc rocksdb_put_cf*(db: rocksdb_t; options: rocksdb_writeoptions_t;
                    column_family: rocksdb_column_family_handle_t;
                    key: cstring; keylen: csize_t; val: cstring; vallen: csize_t;
                    errptr: ptr cstring) {.importrocks.}
proc rocksdb_delete*(db: rocksdb_t; options: rocksdb_writeoptions_t;
                    key: cstring; keylen: csize_t; errptr: ptr cstring) {.importrocks.}
proc rocksdb_delete_cf*(db: rocksdb_t; options: rocksdb_writeoptions_t;
                       column_family: rocksdb_column_family_handle_t;
                       key: cstring; keylen: csize_t; errptr: ptr cstring) {.importrocks.}
proc rocksdb_delete_range_cf*(db: rocksdb_t;
                             options: rocksdb_writeoptions_t;
                             column_family: rocksdb_column_family_handle_t;
                             start_key: cstring; start_key_len: csize_t;
                             end_key: cstring; end_key_len: csize_t;
                             errptr: ptr cstring) {.importrocks.}
proc rocksdb_merge*(db: rocksdb_t; options: rocksdb_writeoptions_t;
                   key: cstring; keylen: csize_t; val: cstring; vallen: csize_t;
                   errptr: ptr cstring) {.importrocks.}
proc rocksdb_merge_cf*(db: rocksdb_t; options: rocksdb_writeoptions_t;
                      column_family: rocksdb_column_family_handle_t;
                      key: cstring; keylen: csize_t; val: cstring; vallen: csize_t;
                      errptr: ptr cstring) {.importrocks.}
proc rocksdb_write*(db: rocksdb_t; options: rocksdb_writeoptions_t;
                   batch: rocksdb_writebatch_t; errptr: ptr cstring) {.importrocks.}
##  Returns NULL if not found.  A malloc()ed array otherwise.
##    Stores the length of the array in *vallen.

proc rocksdb_get*(db: rocksdb_t; options: rocksdb_readoptions_t; key: cstring;
                 keylen: csize_t; vallen: ptr csize_t; errptr: ptr cstring): cstring {.importrocks.}
proc rocksdb_get_cf*(db: rocksdb_t; options: rocksdb_readoptions_t;
                    column_family: rocksdb_column_family_handle_t;
                    key: cstring; keylen: csize_t; vallen: ptr csize_t;
                    errptr: ptr cstring): cstring {.importrocks.}
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

proc rocksdb_multi_get*(db: rocksdb_t; options: rocksdb_readoptions_t;
                       num_keys: csize_t; keys_list: cstringArray;
                       keys_list_sizes: ptr csize_t; values_list: cstringArray;
                       values_list_sizes: ptr csize_t; errs: cstringArray) {.importrocks.}
proc rocksdb_multi_get_cf*(db: rocksdb_t; options: rocksdb_readoptions_t;
    column_families: ptr rocksdb_column_family_handle_t; num_keys: csize_t;
                          keys_list: cstringArray; keys_list_sizes: ptr csize_t;
                          values_list: cstringArray; values_list_sizes: ptr csize_t;
                          errs: cstringArray) {.importrocks.}
##  The value is only allocated (using malloc) and returned if it is found and
##  value_found isn't NULL. In that case the user is responsible for freeing it.

proc rocksdb_key_may_exist*(db: rocksdb_t; options: rocksdb_readoptions_t;
                           key: cstring; key_len: csize_t; value: ptr cstring;
                           val_len: ptr csize_t; timestamp: cstring;
                           timestamp_len: csize_t; value_found: ptr uint8): uint8 {.importrocks.}
##  The value is only allocated (using malloc) and returned if it is found and
##  value_found isn't NULL. In that case the user is responsible for freeing it.

proc rocksdb_key_may_exist_cf*(db: rocksdb_t;
                              options: rocksdb_readoptions_t; column_family: rocksdb_column_family_handle_t;
                              key: cstring; key_len: csize_t; value: ptr cstring;
                              val_len: ptr csize_t; timestamp: cstring;
                              timestamp_len: csize_t; value_found: ptr uint8): uint8 {.importrocks.}
proc rocksdb_create_iterator*(db: rocksdb_t; options: rocksdb_readoptions_t): rocksdb_iterator_t {.importrocks.}
proc rocksdb_get_updates_since*(db: rocksdb_t; seq_number: uint64;
                               options: rocksdb_wal_readoptions_t;
                               errptr: ptr cstring): rocksdb_wal_iterator_t {.importrocks.}
proc rocksdb_create_iterator_cf*(db: rocksdb_t;
                                options: rocksdb_readoptions_t; column_family: rocksdb_column_family_handle_t): rocksdb_iterator_t {.importrocks.}
proc rocksdb_create_iterators*(db: rocksdb_t; opts: rocksdb_readoptions_t;
    column_families: ptr rocksdb_column_family_handle_t;
                              iterators: ptr rocksdb_iterator_t; size: csize_t;
                              errptr: ptr cstring) {.importrocks.}
proc rocksdb_create_snapshot*(db: rocksdb_t): rocksdb_snapshot_t {.importrocks.}
proc rocksdb_release_snapshot*(db: rocksdb_t; snapshot: rocksdb_snapshot_t) {.importrocks.}
##  Returns NULL if property name is unknown.
##    Else returns a pointer to a malloc()-ed null-terminated value.

proc rocksdb_property_value*(db: rocksdb_t; propname: cstring): cstring {.importrocks.}
##  returns 0 on success, -1 otherwise

proc rocksdb_property_int*(db: rocksdb_t; propname: cstring; out_val: ptr uint64): cint {.importrocks.}
##  returns 0 on success, -1 otherwise

proc rocksdb_property_int_cf*(db: rocksdb_t;
                             column_family: rocksdb_column_family_handle_t;
                             propname: cstring; out_val: ptr uint64): cint {.importrocks.}
proc rocksdb_property_value_cf*(db: rocksdb_t; column_family: rocksdb_column_family_handle_t;
                               propname: cstring): cstring {.importrocks.}
proc rocksdb_approximate_sizes*(db: rocksdb_t; num_ranges: cint;
                               range_start_key: cstringArray;
                               range_start_key_len: ptr csize_t;
                               range_limit_key: cstringArray;
                               range_limit_key_len: ptr csize_t; sizes: ptr uint64) {.importrocks.}
proc rocksdb_approximate_sizes_cf*(db: rocksdb_t; column_family: rocksdb_column_family_handle_t;
                                  num_ranges: cint; range_start_key: cstringArray;
                                  range_start_key_len: ptr csize_t;
                                  range_limit_key: cstringArray;
                                  range_limit_key_len: ptr csize_t; sizes: ptr uint64) {.importrocks.}
proc rocksdb_compact_range*(db: rocksdb_t; start_key: cstring;
                           start_key_len: csize_t; limit_key: cstring;
                           limit_key_len: csize_t) {.importrocks.}
proc rocksdb_compact_range_cf*(db: rocksdb_t; column_family: rocksdb_column_family_handle_t;
                              start_key: cstring; start_key_len: csize_t;
                              limit_key: cstring; limit_key_len: csize_t) {.importrocks.}
proc rocksdb_compact_range_opt*(db: rocksdb_t;
                               opt: rocksdb_compactoptions_t;
                               start_key: cstring; start_key_len: csize_t;
                               limit_key: cstring; limit_key_len: csize_t) {.importrocks.}
proc rocksdb_compact_range_cf_opt*(db: rocksdb_t; column_family: rocksdb_column_family_handle_t;
                                  opt: rocksdb_compactoptions_t;
                                  start_key: cstring; start_key_len: csize_t;
                                  limit_key: cstring; limit_key_len: csize_t) {.importrocks.}
proc rocksdb_delete_file*(db: rocksdb_t; name: cstring) {.importrocks.}
proc rocksdb_livefiles*(db: rocksdb_t): rocksdb_livefiles_t {.importrocks.}
proc rocksdb_flush*(db: rocksdb_t; options: rocksdb_flushoptions_t;
                   errptr: ptr cstring) {.importrocks.}
proc rocksdb_flush_cf*(db: rocksdb_t; options: rocksdb_flushoptions_t;
                      column_family: rocksdb_column_family_handle_t;
                      errptr: ptr cstring) {.importrocks.}
proc rocksdb_disable_file_deletions*(db: rocksdb_t; errptr: ptr cstring) {.importrocks.}
proc rocksdb_enable_file_deletions*(db: rocksdb_t; force: uint8;
                                   errptr: ptr cstring) {.importrocks.}
##  Management operations

proc rocksdb_destroy_db*(options: rocksdb_options_t; name: cstring;
                        errptr: ptr cstring) {.importrocks.}
proc rocksdb_repair_db*(options: rocksdb_options_t; name: cstring;
                       errptr: ptr cstring) {.importrocks.}
##  Iterator

proc rocksdb_iter_destroy*(a1: rocksdb_iterator_t) {.importrocks.}
proc rocksdb_iter_valid*(a1: rocksdb_iterator_t): uint8 {.importrocks.}
proc rocksdb_iter_seek_to_first*(a1: rocksdb_iterator_t) {.importrocks.}
proc rocksdb_iter_seek_to_last*(a1: rocksdb_iterator_t) {.importrocks.}
proc rocksdb_iter_seek*(a1: rocksdb_iterator_t; k: cstring; klen: csize_t) {.importrocks.}
proc rocksdb_iter_seek_for_prev*(a1: rocksdb_iterator_t; k: cstring; klen: csize_t) {.importrocks.}
proc rocksdb_iter_next*(a1: rocksdb_iterator_t) {.importrocks.}
proc rocksdb_iter_prev*(a1: rocksdb_iterator_t) {.importrocks.}
proc rocksdb_iter_key*(a1: rocksdb_iterator_t; klen: ptr csize_t): cstring {.importrocks.}
proc rocksdb_iter_value*(a1: rocksdb_iterator_t; vlen: ptr csize_t): cstring {.importrocks.}
proc rocksdb_iter_get_error*(a1: rocksdb_iterator_t; errptr: ptr cstring) {.importrocks.}
proc rocksdb_wal_iter_next*(iter: rocksdb_wal_iterator_t) {.importrocks.}
proc rocksdb_wal_iter_valid*(a1: rocksdb_wal_iterator_t): uint8 {.importrocks.}
proc rocksdb_wal_iter_status*(iter: rocksdb_wal_iterator_t; errptr: ptr cstring) {.importrocks.}
proc rocksdb_wal_iter_get_batch*(iter: rocksdb_wal_iterator_t; seq: ptr uint64): rocksdb_writebatch_t {.importrocks.}
proc rocksdb_get_latest_sequence_number*(db: rocksdb_t): uint64 {.importrocks.}
proc rocksdb_wal_iter_destroy*(iter: rocksdb_wal_iterator_t) {.importrocks.}
##  Write batch

proc rocksdb_writebatch_create*(): rocksdb_writebatch_t {.importrocks.}
proc rocksdb_writebatch_create_from*(rep: cstring; size: csize_t): rocksdb_writebatch_t {.importrocks.}
proc rocksdb_writebatch_destroy*(a1: rocksdb_writebatch_t) {.importrocks.}
proc rocksdb_writebatch_clear*(a1: rocksdb_writebatch_t) {.importrocks.}
proc rocksdb_writebatch_count*(a1: rocksdb_writebatch_t): cint {.importrocks.}
proc rocksdb_writebatch_put*(a1: rocksdb_writebatch_t; key: cstring; klen: csize_t;
                            val: cstring; vlen: csize_t) {.importrocks.}
proc rocksdb_writebatch_put_cf*(a1: rocksdb_writebatch_t; column_family: rocksdb_column_family_handle_t;
                               key: cstring; klen: csize_t; val: cstring; vlen: csize_t) {.importrocks.}
proc rocksdb_writebatch_putv*(b: rocksdb_writebatch_t; num_keys: cint;
                             keys_list: cstringArray; keys_list_sizes: ptr csize_t;
                             num_values: cint; values_list: cstringArray;
                             values_list_sizes: ptr csize_t) {.importrocks.}
proc rocksdb_writebatch_putv_cf*(b: rocksdb_writebatch_t; column_family: rocksdb_column_family_handle_t;
                                num_keys: cint; keys_list: cstringArray;
                                keys_list_sizes: ptr csize_t; num_values: cint;
                                values_list: cstringArray;
                                values_list_sizes: ptr csize_t) {.importrocks.}
proc rocksdb_writebatch_merge*(a1: rocksdb_writebatch_t; key: cstring;
                              klen: csize_t; val: cstring; vlen: csize_t) {.importrocks.}
proc rocksdb_writebatch_merge_cf*(a1: rocksdb_writebatch_t; column_family: rocksdb_column_family_handle_t;
                                 key: cstring; klen: csize_t; val: cstring; vlen: csize_t) {.importrocks.}
proc rocksdb_writebatch_mergev*(b: rocksdb_writebatch_t; num_keys: cint;
                               keys_list: cstringArray;
                               keys_list_sizes: ptr csize_t; num_values: cint;
                               values_list: cstringArray;
                               values_list_sizes: ptr csize_t) {.importrocks.}
proc rocksdb_writebatch_mergev_cf*(b: rocksdb_writebatch_t; column_family: rocksdb_column_family_handle_t;
                                  num_keys: cint; keys_list: cstringArray;
                                  keys_list_sizes: ptr csize_t; num_values: cint;
                                  values_list: cstringArray;
                                  values_list_sizes: ptr csize_t) {.importrocks.}
proc rocksdb_writebatch_delete*(a1: rocksdb_writebatch_t; key: cstring;
                               klen: csize_t) {.importrocks.}
proc rocksdb_writebatch_singledelete*(b: rocksdb_writebatch_t; key: cstring;
                                     klen: csize_t) {.importrocks.}
proc rocksdb_writebatch_delete_cf*(a1: rocksdb_writebatch_t; column_family: rocksdb_column_family_handle_t;
                                  key: cstring; klen: csize_t) {.importrocks.}
proc rocksdb_writebatch_singledelete_cf*(b: rocksdb_writebatch_t; column_family: rocksdb_column_family_handle_t;
                                        key: cstring; klen: csize_t) {.importrocks.}
proc rocksdb_writebatch_deletev*(b: rocksdb_writebatch_t; num_keys: cint;
                                keys_list: cstringArray;
                                keys_list_sizes: ptr csize_t) {.importrocks.}
proc rocksdb_writebatch_deletev_cf*(b: rocksdb_writebatch_t; column_family: rocksdb_column_family_handle_t;
                                   num_keys: cint; keys_list: cstringArray;
                                   keys_list_sizes: ptr csize_t) {.importrocks.}
proc rocksdb_writebatch_delete_range*(b: rocksdb_writebatch_t;
                                     start_key: cstring; start_key_len: csize_t;
                                     end_key: cstring; end_key_len: csize_t) {.importrocks.}
proc rocksdb_writebatch_delete_range_cf*(b: rocksdb_writebatch_t; column_family: rocksdb_column_family_handle_t;
                                        start_key: cstring; start_key_len: csize_t;
                                        end_key: cstring; end_key_len: csize_t) {.importrocks.}
proc rocksdb_writebatch_delete_rangev*(b: rocksdb_writebatch_t; num_keys: cint;
                                      start_keys_list: cstringArray;
                                      start_keys_list_sizes: ptr csize_t;
                                      end_keys_list: cstringArray;
                                      end_keys_list_sizes: ptr csize_t) {.importrocks.}
proc rocksdb_writebatch_delete_rangev_cf*(b: rocksdb_writebatch_t;
    column_family: rocksdb_column_family_handle_t; num_keys: cint;
    start_keys_list: cstringArray; start_keys_list_sizes: ptr csize_t;
    end_keys_list: cstringArray; end_keys_list_sizes: ptr csize_t) {.importrocks.}
proc rocksdb_writebatch_put_log_data*(a1: rocksdb_writebatch_t; blob: cstring;
                                     len: csize_t) {.importrocks.}
proc rocksdb_writebatch_iterate*(a1: rocksdb_writebatch_t; state: pointer; put: proc (
    a1: pointer; k: cstring; klen: csize_t; v: cstring; vlen: csize_t) {.cdecl.}; deleted: proc (
    a1: pointer; k: cstring; klen: csize_t) {.cdecl.}) {.importrocks.}
proc rocksdb_writebatch_data*(a1: rocksdb_writebatch_t; size: ptr csize_t): cstring {.importrocks.}
proc rocksdb_writebatch_set_save_point*(a1: rocksdb_writebatch_t) {.importrocks.}
proc rocksdb_writebatch_rollback_to_save_point*(a1: rocksdb_writebatch_t;
    errptr: ptr cstring) {.importrocks.}
proc rocksdb_writebatch_pop_save_point*(a1: rocksdb_writebatch_t;
                                       errptr: ptr cstring) {.importrocks.}
##  Write batch with index

proc rocksdb_writebatch_wi_create*(reserved_bytes: csize_t; overwrite_keys: uint8): rocksdb_writebatch_wi_t {.importrocks.}
proc rocksdb_writebatch_wi_create_from*(rep: cstring; size: csize_t): rocksdb_writebatch_wi_t {.importrocks.}
proc rocksdb_writebatch_wi_destroy*(a1: rocksdb_writebatch_wi_t) {.importrocks.}
proc rocksdb_writebatch_wi_clear*(a1: rocksdb_writebatch_wi_t) {.importrocks.}
proc rocksdb_writebatch_wi_count*(b: rocksdb_writebatch_wi_t): cint {.importrocks.}
proc rocksdb_writebatch_wi_put*(a1: rocksdb_writebatch_wi_t; key: cstring;
                               klen: csize_t; val: cstring; vlen: csize_t) {.importrocks.}
proc rocksdb_writebatch_wi_put_cf*(a1: rocksdb_writebatch_wi_t; column_family: rocksdb_column_family_handle_t;
                                  key: cstring; klen: csize_t; val: cstring; vlen: csize_t) {.importrocks.}
proc rocksdb_writebatch_wi_putv*(b: rocksdb_writebatch_wi_t; num_keys: cint;
                                keys_list: cstringArray;
                                keys_list_sizes: ptr csize_t; num_values: cint;
                                values_list: cstringArray;
                                values_list_sizes: ptr csize_t) {.importrocks.}
proc rocksdb_writebatch_wi_putv_cf*(b: rocksdb_writebatch_wi_t; column_family: rocksdb_column_family_handle_t;
                                   num_keys: cint; keys_list: cstringArray;
                                   keys_list_sizes: ptr csize_t; num_values: cint;
                                   values_list: cstringArray;
                                   values_list_sizes: ptr csize_t) {.importrocks.}
proc rocksdb_writebatch_wi_merge*(a1: rocksdb_writebatch_wi_t; key: cstring;
                                 klen: csize_t; val: cstring; vlen: csize_t) {.importrocks.}
proc rocksdb_writebatch_wi_merge_cf*(a1: rocksdb_writebatch_wi_t; column_family: rocksdb_column_family_handle_t;
                                    key: cstring; klen: csize_t; val: cstring;
                                    vlen: csize_t) {.importrocks.}
proc rocksdb_writebatch_wi_mergev*(b: rocksdb_writebatch_wi_t; num_keys: cint;
                                  keys_list: cstringArray;
                                  keys_list_sizes: ptr csize_t; num_values: cint;
                                  values_list: cstringArray;
                                  values_list_sizes: ptr csize_t) {.importrocks.}
proc rocksdb_writebatch_wi_mergev_cf*(b: rocksdb_writebatch_wi_t; column_family: rocksdb_column_family_handle_t;
                                     num_keys: cint; keys_list: cstringArray;
                                     keys_list_sizes: ptr csize_t; num_values: cint;
                                     values_list: cstringArray;
                                     values_list_sizes: ptr csize_t) {.importrocks.}
proc rocksdb_writebatch_wi_delete*(a1: rocksdb_writebatch_wi_t; key: cstring;
                                  klen: csize_t) {.importrocks.}
proc rocksdb_writebatch_wi_singledelete*(a1: rocksdb_writebatch_wi_t;
                                        key: cstring; klen: csize_t) {.importrocks.}
proc rocksdb_writebatch_wi_delete_cf*(a1: rocksdb_writebatch_wi_t; column_family: rocksdb_column_family_handle_t;
                                     key: cstring; klen: csize_t) {.importrocks.}
proc rocksdb_writebatch_wi_singledelete_cf*(a1: rocksdb_writebatch_wi_t;
    column_family: rocksdb_column_family_handle_t; key: cstring; klen: csize_t) {.importrocks.}
proc rocksdb_writebatch_wi_deletev*(b: rocksdb_writebatch_wi_t; num_keys: cint;
                                   keys_list: cstringArray;
                                   keys_list_sizes: ptr csize_t) {.importrocks.}
proc rocksdb_writebatch_wi_deletev_cf*(b: rocksdb_writebatch_wi_t; column_family: rocksdb_column_family_handle_t;
                                      num_keys: cint; keys_list: cstringArray;
                                      keys_list_sizes: ptr csize_t) {.importrocks.}
##  DO NOT USE - rocksdb_writebatch_wi_delete_range is not yet supported

proc rocksdb_writebatch_wi_delete_range*(b: rocksdb_writebatch_wi_t;
                                        start_key: cstring; start_key_len: csize_t;
                                        end_key: cstring; end_key_len: csize_t) {.importrocks.}
##  DO NOT USE - rocksdb_writebatch_wi_delete_range_cf is not yet supported

proc rocksdb_writebatch_wi_delete_range_cf*(b: rocksdb_writebatch_wi_t;
    column_family: rocksdb_column_family_handle_t; start_key: cstring;
    start_key_len: csize_t; end_key: cstring; end_key_len: csize_t) {.importrocks.}
##  DO NOT USE - rocksdb_writebatch_wi_delete_rangev is not yet supported

proc rocksdb_writebatch_wi_delete_rangev*(b: rocksdb_writebatch_wi_t;
    num_keys: cint; start_keys_list: cstringArray; start_keys_list_sizes: ptr csize_t;
    end_keys_list: cstringArray; end_keys_list_sizes: ptr csize_t) {.importrocks.}
##  DO NOT USE - rocksdb_writebatch_wi_delete_rangev_cf is not yet supported

proc rocksdb_writebatch_wi_delete_rangev_cf*(b: rocksdb_writebatch_wi_t;
    column_family: rocksdb_column_family_handle_t; num_keys: cint;
    start_keys_list: cstringArray; start_keys_list_sizes: ptr csize_t;
    end_keys_list: cstringArray; end_keys_list_sizes: ptr csize_t) {.importrocks.}
proc rocksdb_writebatch_wi_put_log_data*(a1: rocksdb_writebatch_wi_t;
                                        blob: cstring; len: csize_t) {.importrocks.}
proc rocksdb_writebatch_wi_iterate*(b: rocksdb_writebatch_wi_t; state: pointer;
    put: proc (a1: pointer; k: cstring; klen: csize_t; v: cstring; vlen: csize_t) {.cdecl.};
    deleted: proc (a1: pointer; k: cstring; klen: csize_t) {.cdecl.}) {.importrocks.}
proc rocksdb_writebatch_wi_data*(b: rocksdb_writebatch_wi_t; size: ptr csize_t): cstring {.importrocks.}
proc rocksdb_writebatch_wi_set_save_point*(a1: rocksdb_writebatch_wi_t) {.importrocks.}
proc rocksdb_writebatch_wi_rollback_to_save_point*(
    a1: rocksdb_writebatch_wi_t; errptr: ptr cstring) {.importrocks.}
proc rocksdb_writebatch_wi_get_from_batch*(wbwi: rocksdb_writebatch_wi_t;
    options: rocksdb_options_t; key: cstring; keylen: csize_t; vallen: ptr csize_t;
    errptr: ptr cstring): cstring {.importrocks.}
proc rocksdb_writebatch_wi_get_from_batch_cf*(wbwi: rocksdb_writebatch_wi_t;
    options: rocksdb_options_t;
    column_family: rocksdb_column_family_handle_t; key: cstring; keylen: csize_t;
    vallen: ptr csize_t; errptr: ptr cstring): cstring {.importrocks.}
proc rocksdb_writebatch_wi_get_from_batch_and_db*(
    wbwi: rocksdb_writebatch_wi_t; db: rocksdb_t;
    options: rocksdb_readoptions_t; key: cstring; keylen: csize_t; vallen: ptr csize_t;
    errptr: ptr cstring): cstring {.importrocks.}
proc rocksdb_writebatch_wi_get_from_batch_and_db_cf*(
    wbwi: rocksdb_writebatch_wi_t; db: rocksdb_t;
    options: rocksdb_readoptions_t;
    column_family: rocksdb_column_family_handle_t; key: cstring; keylen: csize_t;
    vallen: ptr csize_t; errptr: ptr cstring): cstring {.importrocks.}
proc rocksdb_write_writebatch_wi*(db: rocksdb_t;
                                 options: rocksdb_writeoptions_t;
                                 wbwi: rocksdb_writebatch_wi_t;
                                 errptr: ptr cstring) {.importrocks.}
proc rocksdb_writebatch_wi_create_iterator_with_base*(
    wbwi: rocksdb_writebatch_wi_t; base_iterator: rocksdb_iterator_t): rocksdb_iterator_t {.importrocks.}
proc rocksdb_writebatch_wi_create_iterator_with_base_cf*(
    wbwi: rocksdb_writebatch_wi_t; base_iterator: rocksdb_iterator_t;
    cf: rocksdb_column_family_handle_t): rocksdb_iterator_t {.importrocks.}
##  Block based table options

proc rocksdb_block_based_options_create*(): rocksdb_block_based_table_options_t {.importrocks.}
proc rocksdb_block_based_options_destroy*(
    options: rocksdb_block_based_table_options_t) {.importrocks.}
proc rocksdb_block_based_options_set_block_size*(
    options: rocksdb_block_based_table_options_t; block_size: csize_t) {.importrocks.}
proc rocksdb_block_based_options_set_block_size_deviation*(
    options: rocksdb_block_based_table_options_t; block_size_deviation: cint) {.importrocks.}
proc rocksdb_block_based_options_set_block_restart_interval*(
    options: rocksdb_block_based_table_options_t; block_restart_interval: cint) {.importrocks.}
proc rocksdb_block_based_options_set_index_block_restart_interval*(
    options: rocksdb_block_based_table_options_t;
    index_block_restart_interval: cint) {.importrocks.}
proc rocksdb_block_based_options_set_metadata_block_size*(
    options: rocksdb_block_based_table_options_t; metadata_block_size: uint64) {.importrocks.}
proc rocksdb_block_based_options_set_partition_filters*(
    options: rocksdb_block_based_table_options_t; partition_filters: uint8) {.importrocks.}
proc rocksdb_block_based_options_set_use_delta_encoding*(
    options: rocksdb_block_based_table_options_t; use_delta_encoding: uint8) {.importrocks.}
proc rocksdb_block_based_options_set_filter_policy*(
    options: rocksdb_block_based_table_options_t;
    filter_policy: rocksdb_filterpolicy_t) {.importrocks.}
proc rocksdb_block_based_options_set_no_block_cache*(
    options: rocksdb_block_based_table_options_t; no_block_cache: uint8) {.importrocks.}
proc rocksdb_block_based_options_set_block_cache*(
    options: rocksdb_block_based_table_options_t;
    block_cache: rocksdb_cache_t) {.importrocks.}
proc rocksdb_block_based_options_set_block_cache_compressed*(
    options: rocksdb_block_based_table_options_t;
    block_cache_compressed: rocksdb_cache_t) {.importrocks.}
proc rocksdb_block_based_options_set_whole_key_filtering*(
    a1: rocksdb_block_based_table_options_t; a2: uint8) {.importrocks.}
proc rocksdb_block_based_options_set_format_version*(
    a1: rocksdb_block_based_table_options_t; a2: cint) {.importrocks.}
const
  rocksdb_block_based_table_index_type_binary_search* = 0
  rocksdb_block_based_table_index_type_hash_search* = 1
  rocksdb_block_based_table_index_type_two_level_index_search* = 2

proc rocksdb_block_based_options_set_index_type*(
    a1: rocksdb_block_based_table_options_t; a2: cint) {.importrocks.}
##  uses one of the above enums

const
  rocksdb_block_based_table_data_block_index_type_binary_search* = 0
  rocksdb_block_based_table_data_block_index_type_binary_search_and_hash* = 1

proc rocksdb_block_based_options_set_data_block_index_type*(
    a1: rocksdb_block_based_table_options_t; a2: cint) {.importrocks.}
##  uses one of the above enums

proc rocksdb_block_based_options_set_data_block_hash_ratio*(
    options: rocksdb_block_based_table_options_t; v: cdouble) {.importrocks.}
proc rocksdb_block_based_options_set_hash_index_allow_collision*(
    a1: rocksdb_block_based_table_options_t; a2: uint8) {.importrocks.}
proc rocksdb_block_based_options_set_cache_index_and_filter_blocks*(
    a1: rocksdb_block_based_table_options_t; a2: uint8) {.importrocks.}
proc rocksdb_block_based_options_set_cache_index_and_filter_blocks_with_high_priority*(
    a1: rocksdb_block_based_table_options_t; a2: uint8) {.importrocks.}
proc rocksdb_block_based_options_set_pin_l0_filter_and_index_blocks_in_cache*(
    a1: rocksdb_block_based_table_options_t; a2: uint8) {.importrocks.}
proc rocksdb_block_based_options_set_pin_top_level_index_and_filter*(
    a1: rocksdb_block_based_table_options_t; a2: uint8) {.importrocks.}
proc rocksdb_options_set_block_based_table_factory*(opt: rocksdb_options_t;
    table_options: rocksdb_block_based_table_options_t) {.importrocks.}
##  Cuckoo table options

proc rocksdb_cuckoo_options_create*(): rocksdb_cuckoo_table_options_t {.importrocks.}
proc rocksdb_cuckoo_options_destroy*(options: rocksdb_cuckoo_table_options_t) {.importrocks.}
proc rocksdb_cuckoo_options_set_hash_ratio*(
    options: rocksdb_cuckoo_table_options_t; v: cdouble) {.importrocks.}
proc rocksdb_cuckoo_options_set_max_search_depth*(
    options: rocksdb_cuckoo_table_options_t; v: uint32) {.importrocks.}
proc rocksdb_cuckoo_options_set_cuckoo_block_size*(
    options: rocksdb_cuckoo_table_options_t; v: uint32) {.importrocks.}
proc rocksdb_cuckoo_options_set_identity_as_first_hash*(
    options: rocksdb_cuckoo_table_options_t; v: uint8) {.importrocks.}
proc rocksdb_cuckoo_options_set_use_module_hash*(
    options: rocksdb_cuckoo_table_options_t; v: uint8) {.importrocks.}
proc rocksdb_options_set_cuckoo_table_factory*(opt: rocksdb_options_t;
    table_options: rocksdb_cuckoo_table_options_t) {.importrocks.}
##  Options

proc rocksdb_set_options*(db: rocksdb_t; count: cint; keys: ptr cstring;
                         values: ptr cstring; errptr: ptr cstring) {.importrocks.}
proc rocksdb_set_options_cf*(db: rocksdb_t;
                            handle: rocksdb_column_family_handle_t;
                            count: cint; keys: ptr cstring; values: ptr cstring;
                            errptr: ptr cstring) {.importrocks.}
proc rocksdb_options_create*(): rocksdb_options_t {.importrocks.}
proc rocksdb_options_destroy*(a1: rocksdb_options_t) {.importrocks.}
proc rocksdb_options_create_copy*(a1: rocksdb_options_t): rocksdb_options_t {.importrocks.}
proc rocksdb_options_increase_parallelism*(opt: rocksdb_options_t;
    total_threads: cint) {.importrocks.}
proc rocksdb_options_optimize_for_point_lookup*(opt: rocksdb_options_t;
    block_cache_size_mb: uint64) {.importrocks.}
proc rocksdb_options_optimize_level_style_compaction*(opt: rocksdb_options_t;
    memtable_memory_budget: uint64) {.importrocks.}
proc rocksdb_options_optimize_universal_style_compaction*(
    opt: rocksdb_options_t; memtable_memory_budget: uint64) {.importrocks.}
proc rocksdb_options_set_allow_ingest_behind*(a1: rocksdb_options_t; a2: uint8) {.importrocks.}
proc rocksdb_options_get_allow_ingest_behind*(a1: rocksdb_options_t): uint8 {.importrocks.}
proc rocksdb_options_set_compaction_filter*(a1: rocksdb_options_t;
    a2: rocksdb_compactionfilter_t) {.importrocks.}
proc rocksdb_options_set_compaction_filter_factory*(a1: rocksdb_options_t;
    a2: rocksdb_compactionfilterfactory_t) {.importrocks.}
proc rocksdb_options_compaction_readahead_size*(a1: rocksdb_options_t; a2: csize_t) {.importrocks.}
proc rocksdb_options_get_compaction_readahead_size*(a1: rocksdb_options_t): csize_t {.importrocks.}
proc rocksdb_options_set_comparator*(a1: rocksdb_options_t;
                                    a2: rocksdb_comparator_t) {.importrocks.}
proc rocksdb_options_set_merge_operator*(a1: rocksdb_options_t;
                                        a2: rocksdb_mergeoperator_t) {.importrocks.}
proc rocksdb_options_set_uint64add_merge_operator*(a1: rocksdb_options_t) {.importrocks.}
proc rocksdb_options_set_compression_per_level*(opt: rocksdb_options_t;
    level_values: ptr cint; num_levels: csize_t) {.importrocks.}
proc rocksdb_options_set_create_if_missing*(a1: rocksdb_options_t; a2: uint8) {.importrocks.}
proc rocksdb_options_get_create_if_missing*(a1: rocksdb_options_t): uint8 {.importrocks.}
proc rocksdb_options_set_create_missing_column_families*(
    a1: rocksdb_options_t; a2: uint8) {.importrocks.}
proc rocksdb_options_get_create_missing_column_families*(
    a1: rocksdb_options_t): uint8 {.importrocks.}
proc rocksdb_options_set_error_if_exists*(a1: rocksdb_options_t; a2: uint8) {.importrocks.}
proc rocksdb_options_get_error_if_exists*(a1: rocksdb_options_t): uint8 {.importrocks.}
proc rocksdb_options_set_paranoid_checks*(a1: rocksdb_options_t; a2: uint8) {.importrocks.}
proc rocksdb_options_get_paranoid_checks*(a1: rocksdb_options_t): uint8 {.importrocks.}
proc rocksdb_options_set_db_paths*(a1: rocksdb_options_t;
                                  path_values: ptr rocksdb_dbpath_t;
                                  num_paths: csize_t) {.importrocks.}
proc rocksdb_options_set_env*(a1: rocksdb_options_t; a2: rocksdb_env_t) {.importrocks.}
proc rocksdb_options_set_info_log*(a1: rocksdb_options_t;
                                  a2: rocksdb_logger_t) {.importrocks.}
proc rocksdb_options_set_info_log_level*(a1: rocksdb_options_t; a2: cint) {.importrocks.}
proc rocksdb_options_get_info_log_level*(a1: rocksdb_options_t): cint {.importrocks.}
proc rocksdb_options_set_write_buffer_size*(a1: rocksdb_options_t; a2: csize_t) {.importrocks.}
proc rocksdb_options_get_write_buffer_size*(a1: rocksdb_options_t): csize_t {.importrocks.}
proc rocksdb_options_set_db_write_buffer_size*(a1: rocksdb_options_t; a2: csize_t) {.importrocks.}
proc rocksdb_options_get_db_write_buffer_size*(a1: rocksdb_options_t): csize_t {.importrocks.}
proc rocksdb_options_set_max_open_files*(a1: rocksdb_options_t; a2: cint) {.importrocks.}
proc rocksdb_options_get_max_open_files*(a1: rocksdb_options_t): cint {.importrocks.}
proc rocksdb_options_set_max_file_opening_threads*(a1: rocksdb_options_t;
    a2: cint) {.importrocks.}
proc rocksdb_options_get_max_file_opening_threads*(a1: rocksdb_options_t): cint {.importrocks.}
proc rocksdb_options_set_max_total_wal_size*(opt: rocksdb_options_t; n: uint64) {.importrocks.}
proc rocksdb_options_get_max_total_wal_size*(opt: rocksdb_options_t): uint64 {.importrocks.}
proc rocksdb_options_set_compression_options*(a1: rocksdb_options_t; a2: cint;
    a3: cint; a4: cint; a5: cint) {.importrocks.}
proc rocksdb_options_set_compression_options_zstd_max_train_bytes*(
    a1: rocksdb_options_t; a2: cint) {.importrocks.}
proc rocksdb_options_set_bottommost_compression_options*(
    a1: rocksdb_options_t; a2: cint; a3: cint; a4: cint; a5: cint; a6: uint8) {.importrocks.}
proc rocksdb_options_set_bottommost_compression_options_zstd_max_train_bytes*(
    a1: rocksdb_options_t; a2: cint; a3: uint8) {.importrocks.}
proc rocksdb_options_set_prefix_extractor*(a1: rocksdb_options_t;
    a2: rocksdb_slicetransform_t) {.importrocks.}
proc rocksdb_options_set_num_levels*(a1: rocksdb_options_t; a2: cint) {.importrocks.}
proc rocksdb_options_get_num_levels*(a1: rocksdb_options_t): cint {.importrocks.}
proc rocksdb_options_set_level0_file_num_compaction_trigger*(
    a1: rocksdb_options_t; a2: cint) {.importrocks.}
proc rocksdb_options_get_level0_file_num_compaction_trigger*(
    a1: rocksdb_options_t): cint {.importrocks.}
proc rocksdb_options_set_level0_slowdown_writes_trigger*(
    a1: rocksdb_options_t; a2: cint) {.importrocks.}
proc rocksdb_options_get_level0_slowdown_writes_trigger*(
    a1: rocksdb_options_t): cint {.importrocks.}
proc rocksdb_options_set_level0_stop_writes_trigger*(a1: rocksdb_options_t;
    a2: cint) {.importrocks.}
proc rocksdb_options_get_level0_stop_writes_trigger*(a1: rocksdb_options_t): cint {.importrocks.}
proc rocksdb_options_set_max_mem_compaction_level*(a1: rocksdb_options_t;
    a2: cint) {.importrocks.}
proc rocksdb_options_set_target_file_size_base*(a1: rocksdb_options_t;
    a2: uint64) {.importrocks.}
proc rocksdb_options_get_target_file_size_base*(a1: rocksdb_options_t): uint64 {.importrocks.}
proc rocksdb_options_set_target_file_size_multiplier*(a1: rocksdb_options_t;
    a2: cint) {.importrocks.}
proc rocksdb_options_get_target_file_size_multiplier*(a1: rocksdb_options_t): cint {.importrocks.}
proc rocksdb_options_set_max_bytes_for_level_base*(a1: rocksdb_options_t;
    a2: uint64) {.importrocks.}
proc rocksdb_options_get_max_bytes_for_level_base*(a1: rocksdb_options_t): uint64 {.importrocks.}
proc rocksdb_options_set_level_compaction_dynamic_level_bytes*(
    a1: rocksdb_options_t; a2: uint8) {.importrocks.}
proc rocksdb_options_get_level_compaction_dynamic_level_bytes*(
    a1: rocksdb_options_t): uint8 {.importrocks.}
proc rocksdb_options_set_max_bytes_for_level_multiplier*(
    a1: rocksdb_options_t; a2: cdouble) {.importrocks.}
proc rocksdb_options_get_max_bytes_for_level_multiplier*(
    a1: rocksdb_options_t): cdouble {.importrocks.}
proc rocksdb_options_set_max_bytes_for_level_multiplier_additional*(
    a1: rocksdb_options_t; level_values: ptr cint; num_levels: csize_t) {.importrocks.}
proc rocksdb_options_enable_statistics*(a1: rocksdb_options_t) {.importrocks.}
proc rocksdb_options_set_skip_stats_update_on_db_open*(
    opt: rocksdb_options_t; val: uint8) {.importrocks.}
proc rocksdb_options_get_skip_stats_update_on_db_open*(opt: rocksdb_options_t): uint8 {.importrocks.}
proc rocksdb_options_set_skip_checking_sst_file_sizes_on_db_open*(
    opt: rocksdb_options_t; val: uint8) {.importrocks.}
proc rocksdb_options_get_skip_checking_sst_file_sizes_on_db_open*(
    opt: rocksdb_options_t): uint8 {.importrocks.}
##  returns a pointer to a malloc()-ed, null terminated string

proc rocksdb_options_statistics_get_string*(opt: rocksdb_options_t): cstring {.importrocks.}
proc rocksdb_options_set_max_write_buffer_number*(a1: rocksdb_options_t;
    a2: cint) {.importrocks.}
proc rocksdb_options_get_max_write_buffer_number*(a1: rocksdb_options_t): cint {.importrocks.}
proc rocksdb_options_set_min_write_buffer_number_to_merge*(
    a1: rocksdb_options_t; a2: cint) {.importrocks.}
proc rocksdb_options_get_min_write_buffer_number_to_merge*(
    a1: rocksdb_options_t): cint {.importrocks.}
proc rocksdb_options_set_max_write_buffer_number_to_maintain*(
    a1: rocksdb_options_t; a2: cint) {.importrocks.}
proc rocksdb_options_get_max_write_buffer_number_to_maintain*(
    a1: rocksdb_options_t): cint {.importrocks.}
proc rocksdb_options_set_max_write_buffer_size_to_maintain*(
    a1: rocksdb_options_t; a2: int64) {.importrocks.}
proc rocksdb_options_get_max_write_buffer_size_to_maintain*(
    a1: rocksdb_options_t): int64 {.importrocks.}
proc rocksdb_options_set_enable_pipelined_write*(a1: rocksdb_options_t;
    a2: uint8) {.importrocks.}
proc rocksdb_options_get_enable_pipelined_write*(a1: rocksdb_options_t): uint8 {.importrocks.}
proc rocksdb_options_set_unordered_write*(a1: rocksdb_options_t; a2: uint8) {.importrocks.}
proc rocksdb_options_get_unordered_write*(a1: rocksdb_options_t): uint8 {.importrocks.}
proc rocksdb_options_set_max_subcompactions*(a1: rocksdb_options_t; a2: uint32) {.importrocks.}
proc rocksdb_options_get_max_subcompactions*(a1: rocksdb_options_t): uint32 {.importrocks.}
proc rocksdb_options_set_max_background_jobs*(a1: rocksdb_options_t; a2: cint) {.importrocks.}
proc rocksdb_options_get_max_background_jobs*(a1: rocksdb_options_t): cint {.importrocks.}
proc rocksdb_options_set_max_background_compactions*(a1: rocksdb_options_t;
    a2: cint) {.importrocks.}
proc rocksdb_options_get_max_background_compactions*(a1: rocksdb_options_t): cint {.importrocks.}
proc rocksdb_options_set_base_background_compactions*(a1: rocksdb_options_t;
    a2: cint) {.importrocks.}
proc rocksdb_options_get_base_background_compactions*(a1: rocksdb_options_t): cint {.importrocks.}
proc rocksdb_options_set_max_background_flushes*(a1: rocksdb_options_t; a2: cint) {.importrocks.}
proc rocksdb_options_get_max_background_flushes*(a1: rocksdb_options_t): cint {.importrocks.}
proc rocksdb_options_set_max_log_file_size*(a1: rocksdb_options_t; a2: csize_t) {.importrocks.}
proc rocksdb_options_get_max_log_file_size*(a1: rocksdb_options_t): csize_t {.importrocks.}
proc rocksdb_options_set_log_file_time_to_roll*(a1: rocksdb_options_t; a2: csize_t) {.importrocks.}
proc rocksdb_options_get_log_file_time_to_roll*(a1: rocksdb_options_t): csize_t {.importrocks.}
proc rocksdb_options_set_keep_log_file_num*(a1: rocksdb_options_t; a2: csize_t) {.importrocks.}
proc rocksdb_options_get_keep_log_file_num*(a1: rocksdb_options_t): csize_t {.importrocks.}
proc rocksdb_options_set_recycle_log_file_num*(a1: rocksdb_options_t; a2: csize_t) {.importrocks.}
proc rocksdb_options_get_recycle_log_file_num*(a1: rocksdb_options_t): csize_t {.importrocks.}
proc rocksdb_options_set_soft_rate_limit*(a1: rocksdb_options_t; a2: cdouble) {.importrocks.}
proc rocksdb_options_get_soft_rate_limit*(a1: rocksdb_options_t): cdouble {.importrocks.}
proc rocksdb_options_set_hard_rate_limit*(a1: rocksdb_options_t; a2: cdouble) {.importrocks.}
proc rocksdb_options_get_hard_rate_limit*(a1: rocksdb_options_t): cdouble {.importrocks.}
proc rocksdb_options_set_soft_pending_compaction_bytes_limit*(
    opt: rocksdb_options_t; v: csize_t) {.importrocks.}
proc rocksdb_options_get_soft_pending_compaction_bytes_limit*(
    opt: rocksdb_options_t): csize_t {.importrocks.}
proc rocksdb_options_set_hard_pending_compaction_bytes_limit*(
    opt: rocksdb_options_t; v: csize_t) {.importrocks.}
proc rocksdb_options_get_hard_pending_compaction_bytes_limit*(
    opt: rocksdb_options_t): csize_t {.importrocks.}
proc rocksdb_options_set_rate_limit_delay_max_milliseconds*(
    a1: rocksdb_options_t; a2: cuint) {.importrocks.}
proc rocksdb_options_get_rate_limit_delay_max_milliseconds*(
    a1: rocksdb_options_t): cuint {.importrocks.}
proc rocksdb_options_set_max_manifest_file_size*(a1: rocksdb_options_t;
    a2: csize_t) {.importrocks.}
proc rocksdb_options_get_max_manifest_file_size*(a1: rocksdb_options_t): csize_t {.importrocks.}
proc rocksdb_options_set_table_cache_numshardbits*(a1: rocksdb_options_t;
    a2: cint) {.importrocks.}
proc rocksdb_options_get_table_cache_numshardbits*(a1: rocksdb_options_t): cint {.importrocks.}
proc rocksdb_options_set_table_cache_remove_scan_count_limit*(
    a1: rocksdb_options_t; a2: cint) {.importrocks.}
proc rocksdb_options_set_arena_block_size*(a1: rocksdb_options_t; a2: csize_t) {.importrocks.}
proc rocksdb_options_get_arena_block_size*(a1: rocksdb_options_t): csize_t {.importrocks.}
proc rocksdb_options_set_use_fsync*(a1: rocksdb_options_t; a2: cint) {.importrocks.}
proc rocksdb_options_get_use_fsync*(a1: rocksdb_options_t): cint {.importrocks.}
proc rocksdb_options_set_db_log_dir*(a1: rocksdb_options_t; a2: cstring) {.importrocks.}
proc rocksdb_options_set_wal_dir*(a1: rocksdb_options_t; a2: cstring) {.importrocks.}
proc rocksdb_options_set_WAL_ttl_seconds*(a1: rocksdb_options_t; a2: uint64) {.importrocks.}
proc rocksdb_options_get_WAL_ttl_seconds*(a1: rocksdb_options_t): uint64 {.importrocks.}
proc rocksdb_options_set_WAL_size_limit_MB*(a1: rocksdb_options_t; a2: uint64) {.importrocks.}
proc rocksdb_options_get_WAL_size_limit_MB*(a1: rocksdb_options_t): uint64 {.importrocks.}
proc rocksdb_options_set_manifest_preallocation_size*(a1: rocksdb_options_t;
    a2: csize_t) {.importrocks.}
proc rocksdb_options_get_manifest_preallocation_size*(a1: rocksdb_options_t): csize_t {.importrocks.}
proc rocksdb_options_set_purge_redundant_kvs_while_flush*(
    a1: rocksdb_options_t; a2: uint8) {.importrocks.}
proc rocksdb_options_set_allow_mmap_reads*(a1: rocksdb_options_t; a2: uint8) {.importrocks.}
proc rocksdb_options_get_allow_mmap_reads*(a1: rocksdb_options_t): uint8 {.importrocks.}
proc rocksdb_options_set_allow_mmap_writes*(a1: rocksdb_options_t; a2: uint8) {.importrocks.}
proc rocksdb_options_get_allow_mmap_writes*(a1: rocksdb_options_t): uint8 {.importrocks.}
proc rocksdb_options_set_use_direct_reads*(a1: rocksdb_options_t; a2: uint8) {.importrocks.}
proc rocksdb_options_get_use_direct_reads*(a1: rocksdb_options_t): uint8 {.importrocks.}
proc rocksdb_options_set_use_direct_io_for_flush_and_compaction*(
    a1: rocksdb_options_t; a2: uint8) {.importrocks.}
proc rocksdb_options_get_use_direct_io_for_flush_and_compaction*(
    a1: rocksdb_options_t): uint8 {.importrocks.}
proc rocksdb_options_set_is_fd_close_on_exec*(a1: rocksdb_options_t; a2: uint8) {.importrocks.}
proc rocksdb_options_get_is_fd_close_on_exec*(a1: rocksdb_options_t): uint8 {.importrocks.}
proc rocksdb_options_set_skip_log_error_on_recovery*(a1: rocksdb_options_t;
    a2: uint8) {.importrocks.}
proc rocksdb_options_get_skip_log_error_on_recovery*(a1: rocksdb_options_t): uint8 {.importrocks.}
proc rocksdb_options_set_stats_dump_period_sec*(a1: rocksdb_options_t; a2: cuint) {.importrocks.}
proc rocksdb_options_get_stats_dump_period_sec*(a1: rocksdb_options_t): cuint {.importrocks.}
proc rocksdb_options_set_advise_random_on_open*(a1: rocksdb_options_t; a2: uint8) {.importrocks.}
proc rocksdb_options_get_advise_random_on_open*(a1: rocksdb_options_t): uint8 {.importrocks.}
proc rocksdb_options_set_access_hint_on_compaction_start*(
    a1: rocksdb_options_t; a2: cint) {.importrocks.}
proc rocksdb_options_get_access_hint_on_compaction_start*(
    a1: rocksdb_options_t): cint {.importrocks.}
proc rocksdb_options_set_use_adaptive_mutex*(a1: rocksdb_options_t; a2: uint8) {.importrocks.}
proc rocksdb_options_get_use_adaptive_mutex*(a1: rocksdb_options_t): uint8 {.importrocks.}
proc rocksdb_options_set_bytes_per_sync*(a1: rocksdb_options_t; a2: uint64) {.importrocks.}
proc rocksdb_options_get_bytes_per_sync*(a1: rocksdb_options_t): uint64 {.importrocks.}
proc rocksdb_options_set_wal_bytes_per_sync*(a1: rocksdb_options_t; a2: uint64) {.importrocks.}
proc rocksdb_options_get_wal_bytes_per_sync*(a1: rocksdb_options_t): uint64 {.importrocks.}
proc rocksdb_options_set_writable_file_max_buffer_size*(
    a1: rocksdb_options_t; a2: uint64) {.importrocks.}
proc rocksdb_options_get_writable_file_max_buffer_size*(a1: rocksdb_options_t): uint64 {.importrocks.}
proc rocksdb_options_set_allow_concurrent_memtable_write*(
    a1: rocksdb_options_t; a2: uint8) {.importrocks.}
proc rocksdb_options_get_allow_concurrent_memtable_write*(
    a1: rocksdb_options_t): uint8 {.importrocks.}
proc rocksdb_options_set_enable_write_thread_adaptive_yield*(
    a1: rocksdb_options_t; a2: uint8) {.importrocks.}
proc rocksdb_options_get_enable_write_thread_adaptive_yield*(
    a1: rocksdb_options_t): uint8 {.importrocks.}
proc rocksdb_options_set_max_sequential_skip_in_iterations*(
    a1: rocksdb_options_t; a2: uint64) {.importrocks.}
proc rocksdb_options_get_max_sequential_skip_in_iterations*(
    a1: rocksdb_options_t): uint64 {.importrocks.}
proc rocksdb_options_set_disable_auto_compactions*(a1: rocksdb_options_t;
    a2: cint) {.importrocks.}
proc rocksdb_options_get_disable_auto_compactions*(a1: rocksdb_options_t): uint8 {.importrocks.}
proc rocksdb_options_set_optimize_filters_for_hits*(a1: rocksdb_options_t;
    a2: cint) {.importrocks.}
proc rocksdb_options_get_optimize_filters_for_hits*(a1: rocksdb_options_t): uint8 {.importrocks.}
proc rocksdb_options_set_delete_obsolete_files_period_micros*(
    a1: rocksdb_options_t; a2: uint64) {.importrocks.}
proc rocksdb_options_get_delete_obsolete_files_period_micros*(
    a1: rocksdb_options_t): uint64 {.importrocks.}
proc rocksdb_options_prepare_for_bulk_load*(a1: rocksdb_options_t) {.importrocks.}
proc rocksdb_options_set_memtable_vector_rep*(a1: rocksdb_options_t) {.importrocks.}
proc rocksdb_options_set_memtable_prefix_bloom_size_ratio*(
    a1: rocksdb_options_t; a2: cdouble) {.importrocks.}
proc rocksdb_options_get_memtable_prefix_bloom_size_ratio*(
    a1: rocksdb_options_t): cdouble {.importrocks.}
proc rocksdb_options_set_max_compaction_bytes*(a1: rocksdb_options_t; a2: uint64) {.importrocks.}
proc rocksdb_options_get_max_compaction_bytes*(a1: rocksdb_options_t): uint64 {.importrocks.}
proc rocksdb_options_set_hash_skip_list_rep*(a1: rocksdb_options_t; a2: csize_t;
    a3: int32; a4: int32) {.importrocks.}
proc rocksdb_options_set_hash_link_list_rep*(a1: rocksdb_options_t; a2: csize_t) {.importrocks.}
proc rocksdb_options_set_plain_table_factory*(a1: rocksdb_options_t; a2: uint32;
    a3: cint; a4: cdouble; a5: csize_t) {.importrocks.}
proc rocksdb_options_set_min_level_to_compress*(opt: rocksdb_options_t;
    level: cint) {.importrocks.}
proc rocksdb_options_set_memtable_huge_page_size*(a1: rocksdb_options_t;
    a2: csize_t) {.importrocks.}
proc rocksdb_options_get_memtable_huge_page_size*(a1: rocksdb_options_t): csize_t {.importrocks.}
proc rocksdb_options_set_max_successive_merges*(a1: rocksdb_options_t; a2: csize_t) {.importrocks.}
proc rocksdb_options_get_max_successive_merges*(a1: rocksdb_options_t): csize_t {.importrocks.}
proc rocksdb_options_set_bloom_locality*(a1: rocksdb_options_t; a2: uint32) {.importrocks.}
proc rocksdb_options_get_bloom_locality*(a1: rocksdb_options_t): uint32 {.importrocks.}
proc rocksdb_options_set_inplace_update_support*(a1: rocksdb_options_t;
    a2: uint8) {.importrocks.}
proc rocksdb_options_get_inplace_update_support*(a1: rocksdb_options_t): uint8 {.importrocks.}
proc rocksdb_options_set_inplace_update_num_locks*(a1: rocksdb_options_t;
    a2: csize_t) {.importrocks.}
proc rocksdb_options_get_inplace_update_num_locks*(a1: rocksdb_options_t): csize_t {.importrocks.}
proc rocksdb_options_set_report_bg_io_stats*(a1: rocksdb_options_t; a2: cint) {.importrocks.}
proc rocksdb_options_get_report_bg_io_stats*(a1: rocksdb_options_t): uint8 {.importrocks.}
const
  rocksdb_tolerate_corrupted_tail_records_recovery* = 0
  rocksdb_absolute_consistency_recovery* = 1
  rocksdb_point_in_time_recovery* = 2
  rocksdb_skip_any_corrupted_records_recovery* = 3

proc rocksdb_options_set_wal_recovery_mode*(a1: rocksdb_options_t; a2: cint) {.importrocks.}
proc rocksdb_options_get_wal_recovery_mode*(a1: rocksdb_options_t): cint {.importrocks.}
const
  rocksdb_no_compression* = 0
  rocksdb_snappy_compression* = 1
  rocksdb_zlib_compression* = 2
  rocksdb_bz2_compression* = 3
  rocksdb_lz4_compression* = 4
  rocksdb_lz4hc_compression* = 5
  rocksdb_xpress_compression* = 6
  rocksdb_zstd_compression* = 7

proc rocksdb_options_set_compression*(a1: rocksdb_options_t; a2: cint) {.importrocks.}
proc rocksdb_options_get_compression*(a1: rocksdb_options_t): cint {.importrocks.}
proc rocksdb_options_set_bottommost_compression*(a1: rocksdb_options_t; a2: cint) {.importrocks.}
proc rocksdb_options_get_bottommost_compression*(a1: rocksdb_options_t): cint {.importrocks.}
const
  rocksdb_level_compaction* = 0
  rocksdb_universal_compaction* = 1
  rocksdb_fifo_compaction* = 2

proc rocksdb_options_set_compaction_style*(a1: rocksdb_options_t; a2: cint) {.importrocks.}
proc rocksdb_options_get_compaction_style*(a1: rocksdb_options_t): cint {.importrocks.}
proc rocksdb_options_set_universal_compaction_options*(a1: rocksdb_options_t;
    a2: rocksdb_universal_compaction_options_t) {.importrocks.}
proc rocksdb_options_set_fifo_compaction_options*(opt: rocksdb_options_t;
    fifo: rocksdb_fifo_compaction_options_t) {.importrocks.}
proc rocksdb_options_set_ratelimiter*(opt: rocksdb_options_t;
                                     limiter: rocksdb_ratelimiter_t) {.importrocks.}
proc rocksdb_options_set_atomic_flush*(opt: rocksdb_options_t; a2: uint8) {.importrocks.}
proc rocksdb_options_get_atomic_flush*(opt: rocksdb_options_t): uint8 {.importrocks.}
proc rocksdb_options_set_row_cache*(opt: rocksdb_options_t;
                                   cache: rocksdb_cache_t) {.importrocks.}
##  RateLimiter

proc rocksdb_ratelimiter_create*(rate_bytes_per_sec: int64;
                                refill_period_us: int64; fairness: int32): rocksdb_ratelimiter_t {.importrocks.}
proc rocksdb_ratelimiter_destroy*(a1: rocksdb_ratelimiter_t) {.importrocks.}
##  PerfContext

const
  rocksdb_uninitialized* = 0
  rocksdb_disable* = 1
  rocksdb_enable_count* = 2
  rocksdb_enable_time_except_for_mutex* = 3
  rocksdb_enable_time* = 4
  rocksdb_out_of_bounds* = 5

const
  rocksdb_user_key_comparison_count* = 0
  rocksdb_block_cache_hit_count* = 1
  rocksdb_block_read_count* = 2
  rocksdb_block_read_byte* = 3
  rocksdb_block_read_time* = 4
  rocksdb_block_checksum_time* = 5
  rocksdb_block_decompress_time* = 6
  rocksdb_get_read_bytes* = 7
  rocksdb_multiget_read_bytes* = 8
  rocksdb_iter_read_bytes* = 9
  rocksdb_internal_key_skipped_count* = 10
  rocksdb_internal_delete_skipped_count* = 11
  rocksdb_internal_recent_skipped_count* = 12
  rocksdb_internal_merge_count* = 13
  rocksdb_get_snapshot_time* = 14
  rocksdb_get_from_memtable_time* = 15
  rocksdb_get_from_memtable_count* = 16
  rocksdb_get_post_process_time* = 17
  rocksdb_get_from_output_files_time* = 18
  rocksdb_seek_on_memtable_time* = 19
  rocksdb_seek_on_memtable_count* = 20
  rocksdb_next_on_memtable_count* = 21
  rocksdb_prev_on_memtable_count* = 22
  rocksdb_seek_child_seek_time* = 23
  rocksdb_seek_child_seek_count* = 24
  rocksdb_seek_min_heap_time* = 25
  rocksdb_seek_max_heap_time* = 26
  rocksdb_seek_internal_seek_time* = 27
  rocksdb_find_next_user_entry_time* = 28
  rocksdb_write_wal_time* = 29
  rocksdb_write_memtable_time* = 30
  rocksdb_write_delay_time* = 31
  rocksdb_write_pre_and_post_process_time* = 32
  rocksdb_db_mutex_lock_nanos* = 33
  rocksdb_db_condition_wait_nanos* = 34
  rocksdb_merge_operator_time_nanos* = 35
  rocksdb_read_index_block_nanos* = 36
  rocksdb_read_filter_block_nanos* = 37
  rocksdb_new_table_block_iter_nanos* = 38
  rocksdb_new_table_iterator_nanos* = 39
  rocksdb_block_seek_nanos* = 40
  rocksdb_find_table_nanos* = 41
  rocksdb_bloom_memtable_hit_count* = 42
  rocksdb_bloom_memtable_miss_count* = 43
  rocksdb_bloom_sst_hit_count* = 44
  rocksdb_bloom_sst_miss_count* = 45
  rocksdb_key_lock_wait_time* = 46
  rocksdb_key_lock_wait_count* = 47
  rocksdb_env_new_sequential_file_nanos* = 48
  rocksdb_env_new_random_access_file_nanos* = 49
  rocksdb_env_new_writable_file_nanos* = 50
  rocksdb_env_reuse_writable_file_nanos* = 51
  rocksdb_env_new_random_rw_file_nanos* = 52
  rocksdb_env_new_directory_nanos* = 53
  rocksdb_env_file_exists_nanos* = 54
  rocksdb_env_get_children_nanos* = 55
  rocksdb_env_get_children_file_attributes_nanos* = 56
  rocksdb_env_delete_file_nanos* = 57
  rocksdb_env_create_dir_nanos* = 58
  rocksdb_env_create_dir_if_missing_nanos* = 59
  rocksdb_env_delete_dir_nanos* = 60
  rocksdb_env_get_file_size_nanos* = 61
  rocksdb_env_get_file_modification_time_nanos* = 62
  rocksdb_env_rename_file_nanos* = 63
  rocksdb_env_link_file_nanos* = 64
  rocksdb_env_lock_file_nanos* = 65
  rocksdb_env_unlock_file_nanos* = 66
  rocksdb_env_new_logger_nanos* = 67
  rocksdb_total_metric_count* = 68

proc rocksdb_set_perf_level*(a1: cint) {.importrocks.}
proc rocksdb_perfcontext_create*(): rocksdb_perfcontext_t {.importrocks.}
proc rocksdb_perfcontext_reset*(context: rocksdb_perfcontext_t) {.importrocks.}
proc rocksdb_perfcontext_report*(context: rocksdb_perfcontext_t;
                                exclude_zero_counters: uint8): cstring {.importrocks.}
proc rocksdb_perfcontext_metric*(context: rocksdb_perfcontext_t; metric: cint): uint64 {.importrocks.}
proc rocksdb_perfcontext_destroy*(context: rocksdb_perfcontext_t) {.importrocks.}
##  Compaction Filter

proc rocksdb_compactionfilter_create*(state: pointer;
                                     destructor: proc (a1: pointer) {.cdecl.}; filter: proc (
    a1: pointer; level: cint; key: cstring; key_length: csize_t; existing_value: cstring;
    value_length: csize_t; new_value: cstringArray; new_value_length: ptr csize_t;
    value_changed: ptr uint8): uint8 {.cdecl.};
                                     name: proc (a1: pointer): cstring {.cdecl.}): rocksdb_compactionfilter_t {.importrocks.}
proc rocksdb_compactionfilter_set_ignore_snapshots*(
    a1: rocksdb_compactionfilter_t; a2: uint8) {.importrocks.}
proc rocksdb_compactionfilter_destroy*(a1: rocksdb_compactionfilter_t) {.importrocks.}
##  Compaction Filter Context

proc rocksdb_compactionfiltercontext_is_full_compaction*(
    context: rocksdb_compactionfiltercontext_t): uint8 {.importrocks.}
proc rocksdb_compactionfiltercontext_is_manual_compaction*(
    context: rocksdb_compactionfiltercontext_t): uint8 {.importrocks.}
##  Compaction Filter Factory

proc rocksdb_compactionfilterfactory_create*(state: pointer;
    destructor: proc (a1: pointer) {.cdecl.}; create_compaction_filter: proc (
    a1: pointer; context: rocksdb_compactionfiltercontext_t): rocksdb_compactionfilter_t {.
    cdecl.}; name: proc (a1: pointer): cstring {.cdecl.}): rocksdb_compactionfilterfactory_t {.importrocks.}
proc rocksdb_compactionfilterfactory_destroy*(
    a1: rocksdb_compactionfilterfactory_t) {.importrocks.}
##  Comparator

proc rocksdb_comparator_create*(state: pointer;
                               destructor: proc (a1: pointer) {.cdecl.}; compare: proc (
    a1: pointer; a: cstring; alen: csize_t; b: cstring; blen: csize_t): cint {.cdecl.};
                               name: proc (a1: pointer): cstring {.cdecl.}): rocksdb_comparator_t {.importrocks.}
proc rocksdb_comparator_destroy*(a1: rocksdb_comparator_t) {.importrocks.}
##  Filter policy

proc rocksdb_filterpolicy_create*(state: pointer;
                                 destructor: proc (a1: pointer) {.cdecl.};
    create_filter: proc (a1: pointer; key_array: cstringArray;
                       key_length_array: ptr csize_t; num_keys: cint;
                       filter_length: ptr csize_t): cstring {.cdecl.}; key_may_match: proc (
    a1: pointer; key: cstring; length: csize_t; filter: cstring; filter_length: csize_t): uint8 {.
    cdecl.}; delete_filter: proc (a1: pointer; filter: cstring; filter_length: csize_t) {.
    cdecl.}; name: proc (a1: pointer): cstring {.cdecl.}): rocksdb_filterpolicy_t {.importrocks.}
proc rocksdb_filterpolicy_destroy*(a1: rocksdb_filterpolicy_t) {.importrocks.}
proc rocksdb_filterpolicy_create_bloom*(bits_per_key: cint): rocksdb_filterpolicy_t {.importrocks.}
proc rocksdb_filterpolicy_create_bloom_full*(bits_per_key: cint): rocksdb_filterpolicy_t {.importrocks.}
##  Merge Operator

proc rocksdb_mergeoperator_create*(state: pointer;
                                  destructor: proc (a1: pointer) {.cdecl.};
    full_merge: proc (a1: pointer; key: cstring; key_length: csize_t;
                    existing_value: cstring; existing_value_length: csize_t;
                    operands_list: cstringArray; operands_list_length: ptr csize_t;
                    num_operands: cint; success: ptr uint8;
                    new_value_length: ptr csize_t): cstring {.cdecl.}; partial_merge: proc (
    a1: pointer; key: cstring; key_length: csize_t; operands_list: cstringArray;
    operands_list_length: ptr csize_t; num_operands: cint; success: ptr uint8;
    new_value_length: ptr csize_t): cstring {.cdecl.}; delete_value: proc (a1: pointer;
    value: cstring; value_length: csize_t) {.cdecl.};
                                  name: proc (a1: pointer): cstring {.cdecl.}): rocksdb_mergeoperator_t {.importrocks.}
proc rocksdb_mergeoperator_destroy*(a1: rocksdb_mergeoperator_t) {.importrocks.}
##  Read options

proc rocksdb_readoptions_create*(): rocksdb_readoptions_t {.importrocks.}
proc rocksdb_readoptions_destroy*(a1: rocksdb_readoptions_t) {.importrocks.}
proc rocksdb_readoptions_set_verify_checksums*(a1: rocksdb_readoptions_t;
    a2: uint8) {.importrocks.}
proc rocksdb_readoptions_set_fill_cache*(a1: rocksdb_readoptions_t; a2: uint8) {.importrocks.}
proc rocksdb_readoptions_set_snapshot*(a1: rocksdb_readoptions_t;
                                      a2: rocksdb_snapshot_t) {.importrocks.}
proc rocksdb_readoptions_set_iterate_upper_bound*(a1: rocksdb_readoptions_t;
    key: cstring; keylen: csize_t) {.importrocks.}
proc rocksdb_readoptions_set_iterate_lower_bound*(a1: rocksdb_readoptions_t;
    key: cstring; keylen: csize_t) {.importrocks.}
proc rocksdb_readoptions_set_read_tier*(a1: rocksdb_readoptions_t; a2: cint) {.importrocks.}
proc rocksdb_readoptions_set_tailing*(a1: rocksdb_readoptions_t; a2: uint8) {.importrocks.}
##  The functionality that this option controlled has been removed.

proc rocksdb_readoptions_set_managed*(a1: rocksdb_readoptions_t; a2: uint8) {.importrocks.}
proc rocksdb_readoptions_set_readahead_size*(a1: rocksdb_readoptions_t;
    a2: csize_t) {.importrocks.}
proc rocksdb_readoptions_set_prefix_same_as_start*(a1: rocksdb_readoptions_t;
    a2: uint8) {.importrocks.}
proc rocksdb_readoptions_set_pin_data*(a1: rocksdb_readoptions_t; a2: uint8) {.importrocks.}
proc rocksdb_readoptions_set_total_order_seek*(a1: rocksdb_readoptions_t;
    a2: uint8) {.importrocks.}
proc rocksdb_readoptions_set_max_skippable_internal_keys*(
    a1: rocksdb_readoptions_t; a2: uint64) {.importrocks.}
proc rocksdb_readoptions_set_background_purge_on_iterator_cleanup*(
    a1: rocksdb_readoptions_t; a2: uint8) {.importrocks.}
proc rocksdb_readoptions_set_ignore_range_deletions*(
    a1: rocksdb_readoptions_t; a2: uint8) {.importrocks.}
##  Write options

proc rocksdb_writeoptions_create*(): rocksdb_writeoptions_t {.importrocks.}
proc rocksdb_writeoptions_destroy*(a1: rocksdb_writeoptions_t) {.importrocks.}
proc rocksdb_writeoptions_set_sync*(a1: rocksdb_writeoptions_t; a2: uint8) {.importrocks.}
proc rocksdb_writeoptions_disable_WAL*(opt: rocksdb_writeoptions_t;
                                      disable: cint) {.importrocks.}
proc rocksdb_writeoptions_set_ignore_missing_column_families*(
    a1: rocksdb_writeoptions_t; a2: uint8) {.importrocks.}
proc rocksdb_writeoptions_set_no_slowdown*(a1: rocksdb_writeoptions_t; a2: uint8) {.importrocks.}
proc rocksdb_writeoptions_set_low_pri*(a1: rocksdb_writeoptions_t; a2: uint8) {.importrocks.}
proc rocksdb_writeoptions_set_memtable_insert_hint_per_batch*(
    a1: rocksdb_writeoptions_t; a2: uint8) {.importrocks.}
##  Compact range options

proc rocksdb_compactoptions_create*(): rocksdb_compactoptions_t {.importrocks.}
proc rocksdb_compactoptions_destroy*(a1: rocksdb_compactoptions_t) {.importrocks.}
proc rocksdb_compactoptions_set_exclusive_manual_compaction*(
    a1: rocksdb_compactoptions_t; a2: uint8) {.importrocks.}
proc rocksdb_compactoptions_set_bottommost_level_compaction*(
    a1: rocksdb_compactoptions_t; a2: uint8) {.importrocks.}
proc rocksdb_compactoptions_set_change_level*(a1: rocksdb_compactoptions_t;
    a2: uint8) {.importrocks.}
proc rocksdb_compactoptions_set_target_level*(a1: rocksdb_compactoptions_t;
    a2: cint) {.importrocks.}
##  Flush options

proc rocksdb_flushoptions_create*(): rocksdb_flushoptions_t {.importrocks.}
proc rocksdb_flushoptions_destroy*(a1: rocksdb_flushoptions_t) {.importrocks.}
proc rocksdb_flushoptions_set_wait*(a1: rocksdb_flushoptions_t; a2: uint8) {.importrocks.}
##  Cache

proc rocksdb_cache_create_lru*(capacity: csize_t): rocksdb_cache_t {.importrocks.}
proc rocksdb_cache_destroy*(cache: rocksdb_cache_t) {.importrocks.}
proc rocksdb_cache_set_capacity*(cache: rocksdb_cache_t; capacity: csize_t) {.importrocks.}
proc rocksdb_cache_get_usage*(cache: rocksdb_cache_t): csize_t {.importrocks.}
proc rocksdb_cache_get_pinned_usage*(cache: rocksdb_cache_t): csize_t {.importrocks.}
##  DBPath

proc rocksdb_dbpath_create*(path: cstring; target_size: uint64): rocksdb_dbpath_t {.importrocks.}
proc rocksdb_dbpath_destroy*(a1: rocksdb_dbpath_t) {.importrocks.}
##  Env

proc rocksdb_create_default_env*(): rocksdb_env_t {.importrocks.}
proc rocksdb_create_mem_env*(): rocksdb_env_t {.importrocks.}
proc rocksdb_env_set_background_threads*(env: rocksdb_env_t; n: cint) {.importrocks.}
proc rocksdb_env_set_high_priority_background_threads*(env: rocksdb_env_t;
    n: cint) {.importrocks.}
proc rocksdb_env_join_all_threads*(env: rocksdb_env_t) {.importrocks.}
proc rocksdb_env_lower_thread_pool_io_priority*(env: rocksdb_env_t) {.importrocks.}
proc rocksdb_env_lower_high_priority_thread_pool_io_priority*(
    env: rocksdb_env_t) {.importrocks.}
proc rocksdb_env_lower_thread_pool_cpu_priority*(env: rocksdb_env_t) {.importrocks.}
proc rocksdb_env_lower_high_priority_thread_pool_cpu_priority*(
    env: rocksdb_env_t) {.importrocks.}
proc rocksdb_env_destroy*(a1: rocksdb_env_t) {.importrocks.}
proc rocksdb_envoptions_create*(): rocksdb_envoptions_t {.importrocks.}
proc rocksdb_envoptions_destroy*(opt: rocksdb_envoptions_t) {.importrocks.}
##  SstFile

proc rocksdb_sstfilewriter_create*(env: rocksdb_envoptions_t;
                                  io_options: rocksdb_options_t): rocksdb_sstfilewriter_t {.importrocks.}
proc rocksdb_sstfilewriter_create_with_comparator*(env: rocksdb_envoptions_t;
    io_options: rocksdb_options_t; comparator: rocksdb_comparator_t): rocksdb_sstfilewriter_t {.importrocks.}
proc rocksdb_sstfilewriter_open*(writer: rocksdb_sstfilewriter_t; name: cstring;
                                errptr: ptr cstring) {.importrocks.}
proc rocksdb_sstfilewriter_add*(writer: rocksdb_sstfilewriter_t; key: cstring;
                               keylen: csize_t; val: cstring; vallen: csize_t;
                               errptr: ptr cstring) {.importrocks.}
proc rocksdb_sstfilewriter_put*(writer: rocksdb_sstfilewriter_t; key: cstring;
                               keylen: csize_t; val: cstring; vallen: csize_t;
                               errptr: ptr cstring) {.importrocks.}
proc rocksdb_sstfilewriter_merge*(writer: rocksdb_sstfilewriter_t; key: cstring;
                                 keylen: csize_t; val: cstring; vallen: csize_t;
                                 errptr: ptr cstring) {.importrocks.}
proc rocksdb_sstfilewriter_delete*(writer: rocksdb_sstfilewriter_t;
                                  key: cstring; keylen: csize_t; errptr: ptr cstring) {.importrocks.}
proc rocksdb_sstfilewriter_finish*(writer: rocksdb_sstfilewriter_t;
                                  errptr: ptr cstring) {.importrocks.}
proc rocksdb_sstfilewriter_file_size*(writer: rocksdb_sstfilewriter_t;
                                     file_size: ptr uint64) {.importrocks.}
proc rocksdb_sstfilewriter_destroy*(writer: rocksdb_sstfilewriter_t) {.importrocks.}
proc rocksdb_ingestexternalfileoptions_create*(): rocksdb_ingestexternalfileoptions_t {.importrocks.}
proc rocksdb_ingestexternalfileoptions_set_move_files*(
    opt: rocksdb_ingestexternalfileoptions_t; move_files: uint8) {.importrocks.}
proc rocksdb_ingestexternalfileoptions_set_snapshot_consistency*(
    opt: rocksdb_ingestexternalfileoptions_t; snapshot_consistency: uint8) {.importrocks.}
proc rocksdb_ingestexternalfileoptions_set_allow_global_seqno*(
    opt: rocksdb_ingestexternalfileoptions_t; allow_global_seqno: uint8) {.importrocks.}
proc rocksdb_ingestexternalfileoptions_set_allow_blocking_flush*(
    opt: rocksdb_ingestexternalfileoptions_t; allow_blocking_flush: uint8) {.importrocks.}
proc rocksdb_ingestexternalfileoptions_set_ingest_behind*(
    opt: rocksdb_ingestexternalfileoptions_t; ingest_behind: uint8) {.importrocks.}
proc rocksdb_ingestexternalfileoptions_destroy*(
    opt: rocksdb_ingestexternalfileoptions_t) {.importrocks.}
proc rocksdb_ingest_external_file*(db: rocksdb_t; file_list: cstringArray;
                                  list_len: csize_t;
                                  opt: rocksdb_ingestexternalfileoptions_t;
                                  errptr: ptr cstring) {.importrocks.}
proc rocksdb_ingest_external_file_cf*(db: rocksdb_t; handle: rocksdb_column_family_handle_t;
                                     file_list: cstringArray; list_len: csize_t; opt: rocksdb_ingestexternalfileoptions_t;
                                     errptr: ptr cstring) {.importrocks.}
proc rocksdb_try_catch_up_with_primary*(db: rocksdb_t; errptr: ptr cstring) {.importrocks.}
##  SliceTransform

proc rocksdb_slicetransform_create*(state: pointer;
                                   destructor: proc (a1: pointer) {.cdecl.};
    transform: proc (a1: pointer; key: cstring; length: csize_t; dst_length: ptr csize_t): cstring {.
    cdecl.}; in_domain: proc (a1: pointer; key: cstring; length: csize_t): uint8 {.cdecl.};
    in_range: proc (a1: pointer; key: cstring; length: csize_t): uint8 {.cdecl.};
                                   name: proc (a1: pointer): cstring {.cdecl.}): rocksdb_slicetransform_t {.importrocks.}
proc rocksdb_slicetransform_create_fixed_prefix*(a1: csize_t): rocksdb_slicetransform_t {.importrocks.}
proc rocksdb_slicetransform_create_noop*(): rocksdb_slicetransform_t {.importrocks.}
proc rocksdb_slicetransform_destroy*(a1: rocksdb_slicetransform_t) {.importrocks.}
##  Universal Compaction options

const
  rocksdb_similar_size_compaction_stop_style* = 0
  rocksdb_total_size_compaction_stop_style* = 1

proc rocksdb_universal_compaction_options_create*(): rocksdb_universal_compaction_options_t {.importrocks.}
proc rocksdb_universal_compaction_options_set_size_ratio*(
    a1: rocksdb_universal_compaction_options_t; a2: cint) {.importrocks.}
proc rocksdb_universal_compaction_options_set_min_merge_width*(
    a1: rocksdb_universal_compaction_options_t; a2: cint) {.importrocks.}
proc rocksdb_universal_compaction_options_set_max_merge_width*(
    a1: rocksdb_universal_compaction_options_t; a2: cint) {.importrocks.}
proc rocksdb_universal_compaction_options_set_max_size_amplification_percent*(
    a1: rocksdb_universal_compaction_options_t; a2: cint) {.importrocks.}
proc rocksdb_universal_compaction_options_set_compression_size_percent*(
    a1: rocksdb_universal_compaction_options_t; a2: cint) {.importrocks.}
proc rocksdb_universal_compaction_options_set_stop_style*(
    a1: rocksdb_universal_compaction_options_t; a2: cint) {.importrocks.}
proc rocksdb_universal_compaction_options_destroy*(
    a1: rocksdb_universal_compaction_options_t) {.importrocks.}
proc rocksdb_fifo_compaction_options_create*(): rocksdb_fifo_compaction_options_t {.importrocks.}
proc rocksdb_fifo_compaction_options_set_max_table_files_size*(
    fifo_opts: rocksdb_fifo_compaction_options_t; size: uint64) {.importrocks.}
proc rocksdb_fifo_compaction_options_destroy*(
    fifo_opts: rocksdb_fifo_compaction_options_t) {.importrocks.}
proc rocksdb_livefiles_count*(a1: rocksdb_livefiles_t): cint {.importrocks.}
proc rocksdb_livefiles_name*(a1: rocksdb_livefiles_t; index: cint): cstring {.importrocks.}
proc rocksdb_livefiles_level*(a1: rocksdb_livefiles_t; index: cint): cint {.importrocks.}
proc rocksdb_livefiles_size*(a1: rocksdb_livefiles_t; index: cint): csize_t {.importrocks.}
proc rocksdb_livefiles_smallestkey*(a1: rocksdb_livefiles_t; index: cint;
                                   size: ptr csize_t): cstring {.importrocks.}
proc rocksdb_livefiles_largestkey*(a1: rocksdb_livefiles_t; index: cint;
                                  size: ptr csize_t): cstring {.importrocks.}
proc rocksdb_livefiles_entries*(a1: rocksdb_livefiles_t; index: cint): uint64 {.importrocks.}
proc rocksdb_livefiles_deletions*(a1: rocksdb_livefiles_t; index: cint): uint64 {.importrocks.}
proc rocksdb_livefiles_destroy*(a1: rocksdb_livefiles_t) {.importrocks.}
##  Utility Helpers

proc rocksdb_get_options_from_string*(base_options: rocksdb_options_t;
                                     opts_str: cstring;
                                     new_options: rocksdb_options_t;
                                     errptr: ptr cstring) {.importrocks.}
proc rocksdb_delete_file_in_range*(db: rocksdb_t; start_key: cstring;
                                  start_key_len: csize_t; limit_key: cstring;
                                  limit_key_len: csize_t; errptr: ptr cstring) {.importrocks.}
proc rocksdb_delete_file_in_range_cf*(db: rocksdb_t; column_family: rocksdb_column_family_handle_t;
                                     start_key: cstring; start_key_len: csize_t;
                                     limit_key: cstring; limit_key_len: csize_t;
                                     errptr: ptr cstring) {.importrocks.}
##  Transactions

proc rocksdb_transactiondb_create_column_family*(
    txn_db: rocksdb_transactiondb_t;
    column_family_options: rocksdb_options_t; column_family_name: cstring;
    errptr: ptr cstring): rocksdb_column_family_handle_t {.importrocks.}
proc rocksdb_transactiondb_open*(options: rocksdb_options_t; txn_db_options: rocksdb_transactiondb_options_t;
                                name: cstring; errptr: ptr cstring): rocksdb_transactiondb_t {.importrocks.}
proc rocksdb_transactiondb_open_column_families*(options: rocksdb_options_t;
    txn_db_options: rocksdb_transactiondb_options_t; name: cstring;
    num_column_families: cint; column_family_names: cstringArray;
    column_family_options: ptr rocksdb_options_t;
    column_family_handles: ptr rocksdb_column_family_handle_t;
    errptr: ptr cstring): rocksdb_transactiondb_t {.importrocks.}
proc rocksdb_transactiondb_create_snapshot*(txn_db: rocksdb_transactiondb_t): rocksdb_snapshot_t {.importrocks.}
proc rocksdb_transactiondb_release_snapshot*(txn_db: rocksdb_transactiondb_t;
    snapshot: rocksdb_snapshot_t) {.importrocks.}
proc rocksdb_transaction_begin*(txn_db: rocksdb_transactiondb_t;
                               write_options: rocksdb_writeoptions_t;
                               txn_options: rocksdb_transaction_options_t;
                               old_txn: rocksdb_transaction_t): rocksdb_transaction_t {.importrocks.}
proc rocksdb_transaction_commit*(txn: rocksdb_transaction_t;
                                errptr: ptr cstring) {.importrocks.}
proc rocksdb_transaction_rollback*(txn: rocksdb_transaction_t;
                                  errptr: ptr cstring) {.importrocks.}
proc rocksdb_transaction_set_savepoint*(txn: rocksdb_transaction_t) {.importrocks.}
proc rocksdb_transaction_rollback_to_savepoint*(txn: rocksdb_transaction_t;
    errptr: ptr cstring) {.importrocks.}
proc rocksdb_transaction_destroy*(txn: rocksdb_transaction_t) {.importrocks.}
##  This snapshot should be freed using rocksdb_free

proc rocksdb_transaction_get_snapshot*(txn: rocksdb_transaction_t): rocksdb_snapshot_t {.importrocks.}
proc rocksdb_transaction_get*(txn: rocksdb_transaction_t;
                             options: rocksdb_readoptions_t; key: cstring;
                             klen: csize_t; vlen: ptr csize_t; errptr: ptr cstring): cstring {.importrocks.}
proc rocksdb_transaction_get_cf*(txn: rocksdb_transaction_t;
                                options: rocksdb_readoptions_t; column_family: rocksdb_column_family_handle_t;
                                key: cstring; klen: csize_t; vlen: ptr csize_t;
                                errptr: ptr cstring): cstring {.importrocks.}
proc rocksdb_transaction_get_for_update*(txn: rocksdb_transaction_t;
                                        options: rocksdb_readoptions_t;
                                        key: cstring; klen: csize_t; vlen: ptr csize_t;
                                        exclusive: uint8; errptr: ptr cstring): cstring {.importrocks.}
proc rocksdb_transaction_get_for_update_cf*(txn: rocksdb_transaction_t;
    options: rocksdb_readoptions_t;
    column_family: rocksdb_column_family_handle_t; key: cstring; klen: csize_t;
    vlen: ptr csize_t; exclusive: uint8; errptr: ptr cstring): cstring {.importrocks.}
proc rocksdb_transactiondb_get*(txn_db: rocksdb_transactiondb_t;
                               options: rocksdb_readoptions_t; key: cstring;
                               klen: csize_t; vlen: ptr csize_t; errptr: ptr cstring): cstring {.importrocks.}
proc rocksdb_transactiondb_get_cf*(txn_db: rocksdb_transactiondb_t;
                                  options: rocksdb_readoptions_t; column_family: rocksdb_column_family_handle_t;
                                  key: cstring; keylen: csize_t; vallen: ptr csize_t;
                                  errptr: ptr cstring): cstring {.importrocks.}
proc rocksdb_transaction_put*(txn: rocksdb_transaction_t; key: cstring;
                             klen: csize_t; val: cstring; vlen: csize_t;
                             errptr: ptr cstring) {.importrocks.}
proc rocksdb_transaction_put_cf*(txn: rocksdb_transaction_t; column_family: rocksdb_column_family_handle_t;
                                key: cstring; klen: csize_t; val: cstring; vlen: csize_t;
                                errptr: ptr cstring) {.importrocks.}
proc rocksdb_transactiondb_put*(txn_db: rocksdb_transactiondb_t;
                               options: rocksdb_writeoptions_t; key: cstring;
                               klen: csize_t; val: cstring; vlen: csize_t;
                               errptr: ptr cstring) {.importrocks.}
proc rocksdb_transactiondb_put_cf*(txn_db: rocksdb_transactiondb_t;
                                  options: rocksdb_writeoptions_t;
    column_family: rocksdb_column_family_handle_t; key: cstring; keylen: csize_t;
                                  val: cstring; vallen: csize_t; errptr: ptr cstring) {.importrocks.}
proc rocksdb_transactiondb_write*(txn_db: rocksdb_transactiondb_t;
                                 options: rocksdb_writeoptions_t;
                                 batch: rocksdb_writebatch_t;
                                 errptr: ptr cstring) {.importrocks.}
proc rocksdb_transaction_merge*(txn: rocksdb_transaction_t; key: cstring;
                               klen: csize_t; val: cstring; vlen: csize_t;
                               errptr: ptr cstring) {.importrocks.}
proc rocksdb_transaction_merge_cf*(txn: rocksdb_transaction_t; column_family: rocksdb_column_family_handle_t;
                                  key: cstring; klen: csize_t; val: cstring;
                                  vlen: csize_t; errptr: ptr cstring) {.importrocks.}
proc rocksdb_transactiondb_merge*(txn_db: rocksdb_transactiondb_t;
                                 options: rocksdb_writeoptions_t; key: cstring;
                                 klen: csize_t; val: cstring; vlen: csize_t;
                                 errptr: ptr cstring) {.importrocks.}
proc rocksdb_transactiondb_merge_cf*(txn_db: rocksdb_transactiondb_t;
                                    options: rocksdb_writeoptions_t;
    column_family: rocksdb_column_family_handle_t; key: cstring; klen: csize_t;
                                    val: cstring; vlen: csize_t; errptr: ptr cstring) {.importrocks.}
proc rocksdb_transaction_delete*(txn: rocksdb_transaction_t; key: cstring;
                                klen: csize_t; errptr: ptr cstring) {.importrocks.}
proc rocksdb_transaction_delete_cf*(txn: rocksdb_transaction_t; column_family: rocksdb_column_family_handle_t;
                                   key: cstring; klen: csize_t; errptr: ptr cstring) {.importrocks.}
proc rocksdb_transactiondb_delete*(txn_db: rocksdb_transactiondb_t;
                                  options: rocksdb_writeoptions_t;
                                  key: cstring; klen: csize_t; errptr: ptr cstring) {.importrocks.}
proc rocksdb_transactiondb_delete_cf*(txn_db: rocksdb_transactiondb_t;
                                     options: rocksdb_writeoptions_t;
    column_family: rocksdb_column_family_handle_t; key: cstring; keylen: csize_t;
                                     errptr: ptr cstring) {.importrocks.}
proc rocksdb_transaction_create_iterator*(txn: rocksdb_transaction_t;
    options: rocksdb_readoptions_t): rocksdb_iterator_t {.importrocks.}
proc rocksdb_transaction_create_iterator_cf*(txn: rocksdb_transaction_t;
    options: rocksdb_readoptions_t;
    column_family: rocksdb_column_family_handle_t): rocksdb_iterator_t {.importrocks.}
proc rocksdb_transactiondb_create_iterator*(txn_db: rocksdb_transactiondb_t;
    options: rocksdb_readoptions_t): rocksdb_iterator_t {.importrocks.}
proc rocksdb_transactiondb_create_iterator_cf*(
    txn_db: rocksdb_transactiondb_t; options: rocksdb_readoptions_t;
    column_family: rocksdb_column_family_handle_t): rocksdb_iterator_t {.importrocks.}
proc rocksdb_transactiondb_close*(txn_db: rocksdb_transactiondb_t) {.importrocks.}
proc rocksdb_transactiondb_checkpoint_object_create*(
    txn_db: rocksdb_transactiondb_t; errptr: ptr cstring): rocksdb_checkpoint_t {.importrocks.}
proc rocksdb_optimistictransactiondb_open*(options: rocksdb_options_t;
    name: cstring; errptr: ptr cstring): rocksdb_optimistictransactiondb_t {.importrocks.}
proc rocksdb_optimistictransactiondb_open_column_families*(
    options: rocksdb_options_t; name: cstring; num_column_families: cint;
    column_family_names: cstringArray;
    column_family_options: ptr rocksdb_options_t;
    column_family_handles: ptr rocksdb_column_family_handle_t;
    errptr: ptr cstring): rocksdb_optimistictransactiondb_t {.importrocks.}
proc rocksdb_optimistictransactiondb_get_base_db*(
    otxn_db: rocksdb_optimistictransactiondb_t): rocksdb_t {.importrocks.}
proc rocksdb_optimistictransactiondb_close_base_db*(base_db: rocksdb_t) {.importrocks.}
proc rocksdb_optimistictransaction_begin*(
    otxn_db: rocksdb_optimistictransactiondb_t;
    write_options: rocksdb_writeoptions_t;
    otxn_options: rocksdb_optimistictransaction_options_t;
    old_txn: rocksdb_transaction_t): rocksdb_transaction_t {.importrocks.}
proc rocksdb_optimistictransactiondb_close*(
    otxn_db: rocksdb_optimistictransactiondb_t) {.importrocks.}
##  Transaction Options

proc rocksdb_transactiondb_options_create*(): rocksdb_transactiondb_options_t {.importrocks.}
proc rocksdb_transactiondb_options_destroy*(
    opt: rocksdb_transactiondb_options_t) {.importrocks.}
proc rocksdb_transactiondb_options_set_max_num_locks*(
    opt: rocksdb_transactiondb_options_t; max_num_locks: int64) {.importrocks.}
proc rocksdb_transactiondb_options_set_num_stripes*(
    opt: rocksdb_transactiondb_options_t; num_stripes: csize_t) {.importrocks.}
proc rocksdb_transactiondb_options_set_transaction_lock_timeout*(
    opt: rocksdb_transactiondb_options_t; txn_lock_timeout: int64) {.importrocks.}
proc rocksdb_transactiondb_options_set_default_lock_timeout*(
    opt: rocksdb_transactiondb_options_t; default_lock_timeout: int64) {.importrocks.}
proc rocksdb_transaction_options_create*(): rocksdb_transaction_options_t {.importrocks.}
proc rocksdb_transaction_options_destroy*(opt: rocksdb_transaction_options_t) {.importrocks.}
proc rocksdb_transaction_options_set_set_snapshot*(
    opt: rocksdb_transaction_options_t; v: uint8) {.importrocks.}
proc rocksdb_transaction_options_set_deadlock_detect*(
    opt: rocksdb_transaction_options_t; v: uint8) {.importrocks.}
proc rocksdb_transaction_options_set_lock_timeout*(
    opt: rocksdb_transaction_options_t; lock_timeout: int64) {.importrocks.}
proc rocksdb_transaction_options_set_expiration*(
    opt: rocksdb_transaction_options_t; expiration: int64) {.importrocks.}
proc rocksdb_transaction_options_set_deadlock_detect_depth*(
    opt: rocksdb_transaction_options_t; depth: int64) {.importrocks.}
proc rocksdb_transaction_options_set_max_write_batch_size*(
    opt: rocksdb_transaction_options_t; size: csize_t) {.importrocks.}
proc rocksdb_optimistictransaction_options_create*(): rocksdb_optimistictransaction_options_t {.importrocks.}
proc rocksdb_optimistictransaction_options_destroy*(
    opt: rocksdb_optimistictransaction_options_t) {.importrocks.}
proc rocksdb_optimistictransaction_options_set_set_snapshot*(
    opt: rocksdb_optimistictransaction_options_t; v: uint8) {.importrocks.}
##  referring to convention (3), this should be used by client
##  to free memory that was malloc()ed

proc rocksdb_free*(`ptr`: pointer) {.importrocks.}
proc rocksdb_get_pinned*(db: rocksdb_t; options: rocksdb_readoptions_t;
                        key: cstring; keylen: csize_t; errptr: ptr cstring): rocksdb_pinnableslice_t {.importrocks.}
proc rocksdb_get_pinned_cf*(db: rocksdb_t; options: rocksdb_readoptions_t;
                           column_family: rocksdb_column_family_handle_t;
                           key: cstring; keylen: csize_t; errptr: ptr cstring): rocksdb_pinnableslice_t {.importrocks.}
proc rocksdb_pinnableslice_destroy*(v: rocksdb_pinnableslice_t) {.importrocks.}
proc rocksdb_pinnableslice_value*(t: rocksdb_pinnableslice_t; vlen: ptr csize_t): cstring {.importrocks.}
proc rocksdb_memory_consumers_create*(): rocksdb_memory_consumers_t {.importrocks.}
proc rocksdb_memory_consumers_add_db*(consumers: rocksdb_memory_consumers_t;
                                     db: rocksdb_t) {.importrocks.}
proc rocksdb_memory_consumers_add_cache*(consumers: rocksdb_memory_consumers_t;
                                        cache: rocksdb_cache_t) {.importrocks.}
proc rocksdb_memory_consumers_destroy*(consumers: rocksdb_memory_consumers_t) {.importrocks.}
proc rocksdb_approximate_memory_usage_create*(
    consumers: rocksdb_memory_consumers_t; errptr: ptr cstring): rocksdb_memory_usage_t {.importrocks.}
proc rocksdb_approximate_memory_usage_destroy*(usage: rocksdb_memory_usage_t) {.importrocks.}
proc rocksdb_approximate_memory_usage_get_mem_table_total*(
    memory_usage: rocksdb_memory_usage_t): uint64 {.importrocks.}
proc rocksdb_approximate_memory_usage_get_mem_table_unflushed*(
    memory_usage: rocksdb_memory_usage_t): uint64 {.importrocks.}
proc rocksdb_approximate_memory_usage_get_mem_table_readers_total*(
    memory_usage: rocksdb_memory_usage_t): uint64 {.importrocks.}
proc rocksdb_approximate_memory_usage_get_cache_total*(
    memory_usage: rocksdb_memory_usage_t): uint64 {.importrocks.}
proc rocksdb_options_set_dump_malloc_stats*(a1: rocksdb_options_t; a2: uint8) {.importrocks.}
proc rocksdb_options_set_memtable_whole_key_filtering*(a1: rocksdb_options_t;
    a2: uint8) {.importrocks.}
proc rocksdb_cancel_all_background_work*(db: rocksdb_t; wait: uint8) {.importrocks.}
