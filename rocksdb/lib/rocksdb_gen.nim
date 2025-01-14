##   Copyright (c) 2011-present, Facebook, Inc.  All rights reserved.
##   This source code is licensed under both the GPLv2 (found in the
##   COPYING file in the root directory) and Apache 2.0 License
##   (found in the LICENSE.Apache file in the root directory).
##  Copyright (c) 2011 The LevelDB Authors. All rights reserved.
##   Use of this source code is governed by a BSD-style license that can be
##   found in the LICENSE file. See the AUTHORS file for names of contributors.
##
##   C bindings for rocksdb.  May be useful as a stable ABI that can be
##   used by programs that keep rocksdb in a shared library, or for
##   a JNI api.
##
##   Does not support:
##   . getters for the option types
##   . custom comparators that implement key shortening
##   . capturing post-write-snapshot
##   . custom iter, db, env, cache implementations using just the C bindings
##
##   Some conventions:
##
##   (1) We expose just opaque struct pointers and functions to clients.
##   This allows us to change internal representations without having to
##   recompile clients.
##
##   (2) For simplicity, there is no equivalent to the Slice type.  Instead,
##   the caller has to pass the pointer and length as separate
##   arguments.
##
##   (3) Errors are represented by a null-terminated c string.  NULL
##   means no error.  All operations that can raise an error are passed
##   a "char** errptr" as the last argument.  One of the following must
##   be true on entry:
## errptr == NULL
## errptr points to a malloc()ed null-terminated error message
##   On success, a leveldb routine leaves *errptr unchanged.
##   On failure, leveldb frees the old value of *errptr and
##   set *errptr to a malloc()ed error message.
##
##   (4) Bools have the type unsigned char (0 == false; rest == true)
##
##   (5) All of the pointer arguments must be non-NULL.
##

##  Exported types


##  DB operations

proc rocksdb_open*(options: ptr rocksdb_options_t; name: cstring; errptr: cstringArray): ptr rocksdb_t {.
    cdecl.}
proc rocksdb_open_with_ttl*(options: ptr rocksdb_options_t; name: cstring; ttl: cint;
                           errptr: cstringArray): ptr rocksdb_t {.cdecl.}
proc rocksdb_open_for_read_only*(options: ptr rocksdb_options_t; name: cstring;
                                error_if_wal_file_exists: uint8;
                                errptr: cstringArray): ptr rocksdb_t {.cdecl.}
proc rocksdb_open_as_secondary*(options: ptr rocksdb_options_t; name: cstring;
                               secondary_path: cstring; errptr: cstringArray): ptr rocksdb_t {.
    cdecl.}
proc rocksdb_backup_engine_open*(options: ptr rocksdb_options_t; path: cstring;
                                errptr: cstringArray): ptr rocksdb_backup_engine_t {.
    cdecl.}
proc rocksdb_backup_engine_open_opts*(options: ptr rocksdb_backup_engine_options_t;
                                     env: ptr rocksdb_env_t; errptr: cstringArray): ptr rocksdb_backup_engine_t {.
    cdecl.}
proc rocksdb_backup_engine_create_new_backup*(be: ptr rocksdb_backup_engine_t;
    db: ptr rocksdb_t; errptr: cstringArray) {.cdecl.}
proc rocksdb_backup_engine_create_new_backup_flush*(
    be: ptr rocksdb_backup_engine_t; db: ptr rocksdb_t; flush_before_backup: uint8;
    errptr: cstringArray) {.cdecl.}
proc rocksdb_backup_engine_purge_old_backups*(be: ptr rocksdb_backup_engine_t;
    num_backups_to_keep: uint32; errptr: cstringArray) {.cdecl.}
proc rocksdb_restore_options_create*(): ptr rocksdb_restore_options_t {.cdecl.}
proc rocksdb_restore_options_destroy*(opt: ptr rocksdb_restore_options_t) {.cdecl.}
proc rocksdb_restore_options_set_keep_log_files*(
    opt: ptr rocksdb_restore_options_t; v: cint) {.cdecl.}
proc rocksdb_backup_engine_verify_backup*(be: ptr rocksdb_backup_engine_t;
    backup_id: uint32; errptr: cstringArray) {.cdecl.}
proc rocksdb_backup_engine_restore_db_from_latest_backup*(
    be: ptr rocksdb_backup_engine_t; db_dir: cstring; wal_dir: cstring;
    restore_options: ptr rocksdb_restore_options_t; errptr: cstringArray) {.cdecl.}
proc rocksdb_backup_engine_restore_db_from_backup*(
    be: ptr rocksdb_backup_engine_t; db_dir: cstring; wal_dir: cstring;
    restore_options: ptr rocksdb_restore_options_t; backup_id: uint32;
    errptr: cstringArray) {.cdecl.}
proc rocksdb_backup_engine_get_backup_info*(be: ptr rocksdb_backup_engine_t): ptr rocksdb_backup_engine_info_t {.
    cdecl.}
proc rocksdb_backup_engine_info_count*(info: ptr rocksdb_backup_engine_info_t): cint {.
    cdecl.}
proc rocksdb_backup_engine_info_timestamp*(
    info: ptr rocksdb_backup_engine_info_t; index: cint): int64 {.cdecl.}
proc rocksdb_backup_engine_info_backup_id*(
    info: ptr rocksdb_backup_engine_info_t; index: cint): uint32 {.cdecl.}
proc rocksdb_backup_engine_info_size*(info: ptr rocksdb_backup_engine_info_t;
                                     index: cint): uint64 {.cdecl.}
proc rocksdb_backup_engine_info_number_files*(
    info: ptr rocksdb_backup_engine_info_t; index: cint): uint32 {.cdecl.}
proc rocksdb_backup_engine_info_destroy*(info: ptr rocksdb_backup_engine_info_t) {.
    cdecl.}
proc rocksdb_backup_engine_close*(be: ptr rocksdb_backup_engine_t) {.cdecl.}
proc rocksdb_put_with_ts*(db: ptr rocksdb_t; options: ptr rocksdb_writeoptions_t;
                         key: cstring; keylen: csize_t; ts: cstring; tslen: csize_t;
                         val: cstring; vallen: csize_t; errptr: cstringArray) {.cdecl.}
proc rocksdb_put_cf_with_ts*(db: ptr rocksdb_t; options: ptr rocksdb_writeoptions_t;
                            column_family: ptr rocksdb_column_family_handle_t;
                            key: cstring; keylen: csize_t; ts: cstring;
                            tslen: csize_t; val: cstring; vallen: csize_t;
                            errptr: cstringArray) {.cdecl.}
proc rocksdb_delete_with_ts*(db: ptr rocksdb_t; options: ptr rocksdb_writeoptions_t;
                            key: cstring; keylen: csize_t; ts: cstring;
                            tslen: csize_t; errptr: cstringArray) {.cdecl.}
proc rocksdb_delete_cf_with_ts*(db: ptr rocksdb_t;
                               options: ptr rocksdb_writeoptions_t; column_family: ptr rocksdb_column_family_handle_t;
                               key: cstring; keylen: csize_t; ts: cstring;
                               tslen: csize_t; errptr: cstringArray) {.cdecl.}
proc rocksdb_singledelete*(db: ptr rocksdb_t; options: ptr rocksdb_writeoptions_t;
                          key: cstring; keylen: csize_t; errptr: cstringArray) {.cdecl.}
proc rocksdb_singledelete_cf*(db: ptr rocksdb_t;
                             options: ptr rocksdb_writeoptions_t;
                             column_family: ptr rocksdb_column_family_handle_t;
                             key: cstring; keylen: csize_t; errptr: cstringArray) {.
    cdecl.}
proc rocksdb_singledelete_with_ts*(db: ptr rocksdb_t;
                                  options: ptr rocksdb_writeoptions_t;
                                  key: cstring; keylen: csize_t; ts: cstring;
                                  tslen: csize_t; errptr: cstringArray) {.cdecl.}
proc rocksdb_singledelete_cf_with_ts*(db: ptr rocksdb_t;
                                     options: ptr rocksdb_writeoptions_t;
    column_family: ptr rocksdb_column_family_handle_t; key: cstring; keylen: csize_t;
                                     ts: cstring; tslen: csize_t;
                                     errptr: cstringArray) {.cdecl.}
proc rocksdb_increase_full_history_ts_low*(db: ptr rocksdb_t;
    column_family: ptr rocksdb_column_family_handle_t; ts_low: cstring;
    ts_lowlen: csize_t; errptr: cstringArray) {.cdecl.}
proc rocksdb_get_full_history_ts_low*(db: ptr rocksdb_t; column_family: ptr rocksdb_column_family_handle_t;
                                     ts_lowlen: ptr csize_t; errptr: cstringArray): cstring {.
    cdecl.}
##  BackupEngineOptions

proc rocksdb_backup_engine_options_create*(backup_dir: cstring): ptr rocksdb_backup_engine_options_t {.
    cdecl.}
proc rocksdb_backup_engine_options_set_backup_dir*(
    options: ptr rocksdb_backup_engine_options_t; backup_dir: cstring) {.cdecl.}
proc rocksdb_backup_engine_options_set_env*(
    options: ptr rocksdb_backup_engine_options_t; env: ptr rocksdb_env_t) {.cdecl.}
proc rocksdb_backup_engine_options_set_share_table_files*(
    options: ptr rocksdb_backup_engine_options_t; val: uint8) {.cdecl.}
proc rocksdb_backup_engine_options_get_share_table_files*(
    options: ptr rocksdb_backup_engine_options_t): uint8 {.cdecl.}
proc rocksdb_backup_engine_options_set_sync*(
    options: ptr rocksdb_backup_engine_options_t; val: uint8) {.cdecl.}
proc rocksdb_backup_engine_options_get_sync*(
    options: ptr rocksdb_backup_engine_options_t): uint8 {.cdecl.}
proc rocksdb_backup_engine_options_set_destroy_old_data*(
    options: ptr rocksdb_backup_engine_options_t; val: uint8) {.cdecl.}
proc rocksdb_backup_engine_options_get_destroy_old_data*(
    options: ptr rocksdb_backup_engine_options_t): uint8 {.cdecl.}
proc rocksdb_backup_engine_options_set_backup_log_files*(
    options: ptr rocksdb_backup_engine_options_t; val: uint8) {.cdecl.}
proc rocksdb_backup_engine_options_get_backup_log_files*(
    options: ptr rocksdb_backup_engine_options_t): uint8 {.cdecl.}
proc rocksdb_backup_engine_options_set_backup_rate_limit*(
    options: ptr rocksdb_backup_engine_options_t; limit: uint64) {.cdecl.}
proc rocksdb_backup_engine_options_get_backup_rate_limit*(
    options: ptr rocksdb_backup_engine_options_t): uint64 {.cdecl.}
proc rocksdb_backup_engine_options_set_restore_rate_limit*(
    options: ptr rocksdb_backup_engine_options_t; limit: uint64) {.cdecl.}
proc rocksdb_backup_engine_options_get_restore_rate_limit*(
    options: ptr rocksdb_backup_engine_options_t): uint64 {.cdecl.}
proc rocksdb_backup_engine_options_set_max_background_operations*(
    options: ptr rocksdb_backup_engine_options_t; val: cint) {.cdecl.}
proc rocksdb_backup_engine_options_get_max_background_operations*(
    options: ptr rocksdb_backup_engine_options_t): cint {.cdecl.}
proc rocksdb_backup_engine_options_set_callback_trigger_interval_size*(
    options: ptr rocksdb_backup_engine_options_t; size: uint64) {.cdecl.}
proc rocksdb_backup_engine_options_get_callback_trigger_interval_size*(
    options: ptr rocksdb_backup_engine_options_t): uint64 {.cdecl.}
proc rocksdb_backup_engine_options_set_max_valid_backups_to_open*(
    options: ptr rocksdb_backup_engine_options_t; val: cint) {.cdecl.}
proc rocksdb_backup_engine_options_get_max_valid_backups_to_open*(
    options: ptr rocksdb_backup_engine_options_t): cint {.cdecl.}
proc rocksdb_backup_engine_options_set_share_files_with_checksum_naming*(
    options: ptr rocksdb_backup_engine_options_t; val: cint) {.cdecl.}
proc rocksdb_backup_engine_options_get_share_files_with_checksum_naming*(
    options: ptr rocksdb_backup_engine_options_t): cint {.cdecl.}
proc rocksdb_backup_engine_options_destroy*(
    a1: ptr rocksdb_backup_engine_options_t) {.cdecl.}
##  Checkpoint

proc rocksdb_checkpoint_object_create*(db: ptr rocksdb_t; errptr: cstringArray): ptr rocksdb_checkpoint_t {.
    cdecl.}
proc rocksdb_checkpoint_create*(checkpoint: ptr rocksdb_checkpoint_t;
                               checkpoint_dir: cstring;
                               log_size_for_flush: uint64; errptr: cstringArray) {.
    cdecl.}
proc rocksdb_checkpoint_object_destroy*(checkpoint: ptr rocksdb_checkpoint_t) {.
    cdecl.}
proc rocksdb_open_and_trim_history*(options: ptr rocksdb_options_t; name: cstring;
                                   num_column_families: cint;
                                   column_family_names: cstringArray;
    column_family_options: ptr ptr rocksdb_options_t; column_family_handles: ptr ptr rocksdb_column_family_handle_t;
                                   trim_ts: cstring; trim_tslen: csize_t;
                                   errptr: cstringArray): ptr rocksdb_t {.cdecl.}
proc rocksdb_open_column_families*(options: ptr rocksdb_options_t; name: cstring;
                                  num_column_families: cint;
                                  column_family_names: cstringArray;
    column_family_options: ptr ptr rocksdb_options_t; column_family_handles: ptr ptr rocksdb_column_family_handle_t;
                                  errptr: cstringArray): ptr rocksdb_t {.cdecl.}
proc rocksdb_open_column_families_with_ttl*(options: ptr rocksdb_options_t;
    name: cstring; num_column_families: cint; column_family_names: cstringArray;
    column_family_options: ptr ptr rocksdb_options_t;
    column_family_handles: ptr ptr rocksdb_column_family_handle_t; ttls: ptr cint;
    errptr: cstringArray): ptr rocksdb_t {.cdecl.}
proc rocksdb_open_for_read_only_column_families*(options: ptr rocksdb_options_t;
    name: cstring; num_column_families: cint; column_family_names: cstringArray;
    column_family_options: ptr ptr rocksdb_options_t;
    column_family_handles: ptr ptr rocksdb_column_family_handle_t;
    error_if_wal_file_exists: uint8; errptr: cstringArray): ptr rocksdb_t {.cdecl.}
proc rocksdb_open_as_secondary_column_families*(options: ptr rocksdb_options_t;
    name: cstring; secondary_path: cstring; num_column_families: cint;
    column_family_names: cstringArray;
    column_family_options: ptr ptr rocksdb_options_t;
    column_family_handles: ptr ptr rocksdb_column_family_handle_t;
    errptr: cstringArray): ptr rocksdb_t {.cdecl.}
proc rocksdb_list_column_families*(options: ptr rocksdb_options_t; name: cstring;
                                  lencf: ptr csize_t; errptr: cstringArray): cstringArray {.
    cdecl.}
proc rocksdb_list_column_families_destroy*(list: cstringArray; len: csize_t) {.cdecl.}
proc rocksdb_create_column_family*(db: ptr rocksdb_t;
                                  column_family_options: ptr rocksdb_options_t;
                                  column_family_name: cstring;
                                  errptr: cstringArray): ptr rocksdb_column_family_handle_t {.
    cdecl.}
proc rocksdb_create_column_families*(db: ptr rocksdb_t; column_family_options: ptr rocksdb_options_t;
                                    num_column_families: cint;
                                    column_family_names: cstringArray;
                                    lencfs: ptr csize_t; errptr: cstringArray): ptr ptr rocksdb_column_family_handle_t {.
    cdecl.}
proc rocksdb_create_column_families_destroy*(
    list: ptr ptr rocksdb_column_family_handle_t) {.cdecl.}
proc rocksdb_create_column_family_with_ttl*(db: ptr rocksdb_t;
    column_family_options: ptr rocksdb_options_t; column_family_name: cstring;
    ttl: cint; errptr: cstringArray): ptr rocksdb_column_family_handle_t {.cdecl.}
proc rocksdb_drop_column_family*(db: ptr rocksdb_t;
                                handle: ptr rocksdb_column_family_handle_t;
                                errptr: cstringArray) {.cdecl.}
proc rocksdb_get_default_column_family_handle*(db: ptr rocksdb_t): ptr rocksdb_column_family_handle_t {.
    cdecl.}
proc rocksdb_column_family_handle_destroy*(a1: ptr rocksdb_column_family_handle_t) {.
    cdecl.}
proc rocksdb_column_family_handle_get_id*(
    handle: ptr rocksdb_column_family_handle_t): uint32 {.cdecl.}
proc rocksdb_column_family_handle_get_name*(
    handle: ptr rocksdb_column_family_handle_t; name_len: ptr csize_t): cstring {.cdecl.}
proc rocksdb_close*(db: ptr rocksdb_t) {.cdecl.}
proc rocksdb_put*(db: ptr rocksdb_t; options: ptr rocksdb_writeoptions_t; key: cstring;
                 keylen: csize_t; val: cstring; vallen: csize_t; errptr: cstringArray) {.
    cdecl.}
proc rocksdb_put_cf*(db: ptr rocksdb_t; options: ptr rocksdb_writeoptions_t;
                    column_family: ptr rocksdb_column_family_handle_t;
                    key: cstring; keylen: csize_t; val: cstring; vallen: csize_t;
                    errptr: cstringArray) {.cdecl.}
proc rocksdb_delete*(db: ptr rocksdb_t; options: ptr rocksdb_writeoptions_t;
                    key: cstring; keylen: csize_t; errptr: cstringArray) {.cdecl.}
proc rocksdb_delete_cf*(db: ptr rocksdb_t; options: ptr rocksdb_writeoptions_t;
                       column_family: ptr rocksdb_column_family_handle_t;
                       key: cstring; keylen: csize_t; errptr: cstringArray) {.cdecl.}
proc rocksdb_delete_range_cf*(db: ptr rocksdb_t;
                             options: ptr rocksdb_writeoptions_t;
                             column_family: ptr rocksdb_column_family_handle_t;
                             start_key: cstring; start_key_len: csize_t;
                             end_key: cstring; end_key_len: csize_t;
                             errptr: cstringArray) {.cdecl.}
proc rocksdb_merge*(db: ptr rocksdb_t; options: ptr rocksdb_writeoptions_t;
                   key: cstring; keylen: csize_t; val: cstring; vallen: csize_t;
                   errptr: cstringArray) {.cdecl.}
proc rocksdb_merge_cf*(db: ptr rocksdb_t; options: ptr rocksdb_writeoptions_t;
                      column_family: ptr rocksdb_column_family_handle_t;
                      key: cstring; keylen: csize_t; val: cstring; vallen: csize_t;
                      errptr: cstringArray) {.cdecl.}
proc rocksdb_write*(db: ptr rocksdb_t; options: ptr rocksdb_writeoptions_t;
                   batch: ptr rocksdb_writebatch_t; errptr: cstringArray) {.cdecl.}
##  Returns NULL if not found.  A malloc()ed array otherwise.
##    Stores the length of the array in *vallen.

proc rocksdb_get*(db: ptr rocksdb_t; options: ptr rocksdb_readoptions_t; key: cstring;
                 keylen: csize_t; vallen: ptr csize_t; errptr: cstringArray): cstring {.
    cdecl.}
proc rocksdb_get_with_ts*(db: ptr rocksdb_t; options: ptr rocksdb_readoptions_t;
                         key: cstring; keylen: csize_t; vallen: ptr csize_t;
                         ts: cstringArray; tslen: ptr csize_t; errptr: cstringArray): cstring {.
    cdecl.}
proc rocksdb_get_cf*(db: ptr rocksdb_t; options: ptr rocksdb_readoptions_t;
                    column_family: ptr rocksdb_column_family_handle_t;
                    key: cstring; keylen: csize_t; vallen: ptr csize_t;
                    errptr: cstringArray): cstring {.cdecl.}
proc rocksdb_get_cf_with_ts*(db: ptr rocksdb_t; options: ptr rocksdb_readoptions_t;
                            column_family: ptr rocksdb_column_family_handle_t;
                            key: cstring; keylen: csize_t; vallen: ptr csize_t;
                            ts: cstringArray; tslen: ptr csize_t;
                            errptr: cstringArray): cstring {.cdecl.}
##
##  Returns a malloc() buffer with the DB identity, assigning the length to
##  *id_len. Returns NULL if an error occurred.
##

proc rocksdb_get_db_identity*(db: ptr rocksdb_t; id_len: ptr csize_t): cstring {.cdecl.}
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
                       num_keys: csize_t; keys_list: cstringArray;
                       keys_list_sizes: ptr csize_t; values_list: cstringArray;
                       values_list_sizes: ptr csize_t; errs: cstringArray) {.cdecl.}
proc rocksdb_multi_get_with_ts*(db: ptr rocksdb_t;
                               options: ptr rocksdb_readoptions_t;
                               num_keys: csize_t; keys_list: cstringArray;
                               keys_list_sizes: ptr csize_t;
                               values_list: cstringArray;
                               values_list_sizes: ptr csize_t;
                               timestamp_list: cstringArray;
                               timestamp_list_sizes: ptr csize_t;
                               errs: cstringArray) {.cdecl.}
proc rocksdb_multi_get_cf*(db: ptr rocksdb_t; options: ptr rocksdb_readoptions_t;
    column_families: ptr ptr rocksdb_column_family_handle_t; num_keys: csize_t;
                          keys_list: cstringArray; keys_list_sizes: ptr csize_t;
                          values_list: cstringArray;
                          values_list_sizes: ptr csize_t; errs: cstringArray) {.cdecl.}
proc rocksdb_multi_get_cf_with_ts*(db: ptr rocksdb_t;
                                  options: ptr rocksdb_readoptions_t;
    column_families: ptr ptr rocksdb_column_family_handle_t; num_keys: csize_t;
                                  keys_list: cstringArray;
                                  keys_list_sizes: ptr csize_t;
                                  values_list: cstringArray;
                                  values_list_sizes: ptr csize_t;
                                  timestamps_list: cstringArray;
                                  timestamps_list_sizes: ptr csize_t;
                                  errs: cstringArray) {.cdecl.}
##  The MultiGet API that improves performance by batching operations
##  in the read path for greater efficiency. Currently, only the block based
##  table format with full filters are supported. Other table formats such
##  as plain table, block based table with block based filters and
##  partitioned indexes will still work, but will not get any performance
##  benefits.
##
##  Note that all the keys passed to this API are restricted to a single
##  column family.
##
##  Parameters -
##  db - the RocksDB instance.
##  options - ReadOptions
##  column_family - ColumnFamilyHandle* that the keys belong to. All the keys
##                  passed to the API are restricted to a single column family
##  num_keys - Number of keys to lookup
##  keys_list - Pointer to C style array of keys with num_keys elements
##  keys_list_sizes - Pointer to C style array of the size of corresponding key
##    in key_list with num_keys elements.
##  values - Pointer to C style array of PinnableSlices with num_keys elements
##  statuses - Pointer to C style array of Status with num_keys elements
##  sorted_input - If true, it means the input keys are already sorted by key
##                 order, so the MultiGet() API doesn't have to sort them
##                 again. If false, the keys will be copied and sorted
##                 internally by the API - the input array will not be
##                 modified

proc rocksdb_batched_multi_get_cf*(db: ptr rocksdb_t;
                                  options: ptr rocksdb_readoptions_t; column_family: ptr rocksdb_column_family_handle_t;
                                  num_keys: csize_t; keys_list: cstringArray;
                                  keys_list_sizes: ptr csize_t;
                                  values: ptr ptr rocksdb_pinnableslice_t;
                                  errs: cstringArray; sorted_input: bool) {.cdecl.}
##  The value is only allocated (using malloc) and returned if it is found and
##  value_found isn't NULL. In that case the user is responsible for freeing it.

proc rocksdb_key_may_exist*(db: ptr rocksdb_t; options: ptr rocksdb_readoptions_t;
                           key: cstring; key_len: csize_t; value: cstringArray;
                           val_len: ptr csize_t; timestamp: cstring;
                           timestamp_len: csize_t; value_found: ptr uint8): uint8 {.
    cdecl.}
##  The value is only allocated (using malloc) and returned if it is found and
##  value_found isn't NULL. In that case the user is responsible for freeing it.

proc rocksdb_key_may_exist_cf*(db: ptr rocksdb_t;
                              options: ptr rocksdb_readoptions_t; column_family: ptr rocksdb_column_family_handle_t;
                              key: cstring; key_len: csize_t; value: cstringArray;
                              val_len: ptr csize_t; timestamp: cstring;
                              timestamp_len: csize_t; value_found: ptr uint8): uint8 {.
    cdecl.}
proc rocksdb_create_iterator*(db: ptr rocksdb_t; options: ptr rocksdb_readoptions_t): ptr rocksdb_iterator_t {.
    cdecl.}
proc rocksdb_get_updates_since*(db: ptr rocksdb_t; seq_number: uint64;
                               options: ptr rocksdb_wal_readoptions_t;
                               errptr: cstringArray): ptr rocksdb_wal_iterator_t {.
    cdecl.}
proc rocksdb_create_iterator_cf*(db: ptr rocksdb_t;
                                options: ptr rocksdb_readoptions_t; column_family: ptr rocksdb_column_family_handle_t): ptr rocksdb_iterator_t {.
    cdecl.}
proc rocksdb_create_iterators*(db: ptr rocksdb_t; opts: ptr rocksdb_readoptions_t;
    column_families: ptr ptr rocksdb_column_family_handle_t;
                              iterators: ptr ptr rocksdb_iterator_t; size: csize_t;
                              errptr: cstringArray) {.cdecl.}
proc rocksdb_create_snapshot*(db: ptr rocksdb_t): ptr rocksdb_snapshot_t {.cdecl.}
proc rocksdb_release_snapshot*(db: ptr rocksdb_t; snapshot: ptr rocksdb_snapshot_t) {.
    cdecl.}
proc rocksdb_snapshot_get_sequence_number*(snapshot: ptr rocksdb_snapshot_t): uint64 {.
    cdecl.}
##  Returns NULL if property name is unknown.
##    Else returns a pointer to a malloc()-ed null-terminated value.

proc rocksdb_property_value*(db: ptr rocksdb_t; propname: cstring): cstring {.cdecl.}
##  returns 0 on success, -1 otherwise

proc rocksdb_property_int*(db: ptr rocksdb_t; propname: cstring; out_val: ptr uint64): cint {.
    cdecl.}
##  returns 0 on success, -1 otherwise

proc rocksdb_property_int_cf*(db: ptr rocksdb_t;
                             column_family: ptr rocksdb_column_family_handle_t;
                             propname: cstring; out_val: ptr uint64): cint {.cdecl.}
proc rocksdb_property_value_cf*(db: ptr rocksdb_t; column_family: ptr rocksdb_column_family_handle_t;
                               propname: cstring): cstring {.cdecl.}
proc rocksdb_approximate_sizes*(db: ptr rocksdb_t; num_ranges: cint;
                               range_start_key: cstringArray;
                               range_start_key_len: ptr csize_t;
                               range_limit_key: cstringArray;
                               range_limit_key_len: ptr csize_t; sizes: ptr uint64;
                               errptr: cstringArray) {.cdecl.}
proc rocksdb_approximate_sizes_cf*(db: ptr rocksdb_t; column_family: ptr rocksdb_column_family_handle_t;
                                  num_ranges: cint; range_start_key: cstringArray;
                                  range_start_key_len: ptr csize_t;
                                  range_limit_key: cstringArray;
                                  range_limit_key_len: ptr csize_t;
                                  sizes: ptr uint64; errptr: cstringArray) {.cdecl.}
const
  rocksdb_size_approximation_flags_none* = 0
  rocksdb_size_approximation_flags_include_memtable* = 1 shl 0
  rocksdb_size_approximation_flags_include_files* = 1 shl 1

proc rocksdb_approximate_sizes_cf_with_flags*(db: ptr rocksdb_t;
    column_family: ptr rocksdb_column_family_handle_t; num_ranges: cint;
    range_start_key: cstringArray; range_start_key_len: ptr csize_t;
    range_limit_key: cstringArray; range_limit_key_len: ptr csize_t;
    include_flags: uint8; sizes: ptr uint64; errptr: cstringArray) {.cdecl.}
proc rocksdb_compact_range*(db: ptr rocksdb_t; start_key: cstring;
                           start_key_len: csize_t; limit_key: cstring;
                           limit_key_len: csize_t) {.cdecl.}
proc rocksdb_compact_range_cf*(db: ptr rocksdb_t; column_family: ptr rocksdb_column_family_handle_t;
                              start_key: cstring; start_key_len: csize_t;
                              limit_key: cstring; limit_key_len: csize_t) {.cdecl.}
proc rocksdb_suggest_compact_range*(db: ptr rocksdb_t; start_key: cstring;
                                   start_key_len: csize_t; limit_key: cstring;
                                   limit_key_len: csize_t; errptr: cstringArray) {.
    cdecl.}
proc rocksdb_suggest_compact_range_cf*(db: ptr rocksdb_t; column_family: ptr rocksdb_column_family_handle_t;
                                      start_key: cstring; start_key_len: csize_t;
                                      limit_key: cstring; limit_key_len: csize_t;
                                      errptr: cstringArray) {.cdecl.}
proc rocksdb_compact_range_opt*(db: ptr rocksdb_t;
                               opt: ptr rocksdb_compactoptions_t;
                               start_key: cstring; start_key_len: csize_t;
                               limit_key: cstring; limit_key_len: csize_t) {.cdecl.}
proc rocksdb_compact_range_cf_opt*(db: ptr rocksdb_t; column_family: ptr rocksdb_column_family_handle_t;
                                  opt: ptr rocksdb_compactoptions_t;
                                  start_key: cstring; start_key_len: csize_t;
                                  limit_key: cstring; limit_key_len: csize_t) {.
    cdecl.}
proc rocksdb_delete_file*(db: ptr rocksdb_t; name: cstring) {.cdecl.}
proc rocksdb_livefiles*(db: ptr rocksdb_t): ptr rocksdb_livefiles_t {.cdecl.}
proc rocksdb_flush*(db: ptr rocksdb_t; options: ptr rocksdb_flushoptions_t;
                   errptr: cstringArray) {.cdecl.}
proc rocksdb_flush_cf*(db: ptr rocksdb_t; options: ptr rocksdb_flushoptions_t;
                      column_family: ptr rocksdb_column_family_handle_t;
                      errptr: cstringArray) {.cdecl.}
proc rocksdb_flush_cfs*(db: ptr rocksdb_t; options: ptr rocksdb_flushoptions_t;
                       column_family: ptr ptr rocksdb_column_family_handle_t;
                       num_column_families: cint; errptr: cstringArray) {.cdecl.}
proc rocksdb_flush_wal*(db: ptr rocksdb_t; sync: uint8; errptr: cstringArray) {.cdecl.}
proc rocksdb_disable_file_deletions*(db: ptr rocksdb_t; errptr: cstringArray) {.cdecl.}
proc rocksdb_enable_file_deletions*(db: ptr rocksdb_t; errptr: cstringArray) {.cdecl.}
##  Management operations

proc rocksdb_destroy_db*(options: ptr rocksdb_options_t; name: cstring;
                        errptr: cstringArray) {.cdecl.}
proc rocksdb_repair_db*(options: ptr rocksdb_options_t; name: cstring;
                       errptr: cstringArray) {.cdecl.}
##  Iterator

proc rocksdb_iter_destroy*(a1: ptr rocksdb_iterator_t) {.cdecl.}
proc rocksdb_iter_valid*(a1: ptr rocksdb_iterator_t): uint8 {.cdecl.}
proc rocksdb_iter_seek_to_first*(a1: ptr rocksdb_iterator_t) {.cdecl.}
proc rocksdb_iter_seek_to_last*(a1: ptr rocksdb_iterator_t) {.cdecl.}
proc rocksdb_iter_seek*(a1: ptr rocksdb_iterator_t; k: cstring; klen: csize_t) {.cdecl.}
proc rocksdb_iter_seek_for_prev*(a1: ptr rocksdb_iterator_t; k: cstring; klen: csize_t) {.
    cdecl.}
proc rocksdb_iter_next*(a1: ptr rocksdb_iterator_t) {.cdecl.}
proc rocksdb_iter_prev*(a1: ptr rocksdb_iterator_t) {.cdecl.}
proc rocksdb_iter_key*(a1: ptr rocksdb_iterator_t; klen: ptr csize_t): cstring {.cdecl.}
proc rocksdb_iter_value*(a1: ptr rocksdb_iterator_t; vlen: ptr csize_t): cstring {.cdecl.}
proc rocksdb_iter_timestamp*(a1: ptr rocksdb_iterator_t; tslen: ptr csize_t): cstring {.
    cdecl.}
proc rocksdb_iter_get_error*(a1: ptr rocksdb_iterator_t; errptr: cstringArray) {.cdecl.}
proc rocksdb_iter_refresh*(iter: ptr rocksdb_iterator_t; errptr: cstringArray) {.cdecl.}
proc rocksdb_wal_iter_next*(iter: ptr rocksdb_wal_iterator_t) {.cdecl.}
proc rocksdb_wal_iter_valid*(a1: ptr rocksdb_wal_iterator_t): uint8 {.cdecl.}
proc rocksdb_wal_iter_status*(iter: ptr rocksdb_wal_iterator_t; errptr: cstringArray) {.
    cdecl.}
proc rocksdb_wal_iter_get_batch*(iter: ptr rocksdb_wal_iterator_t; seq: ptr uint64): ptr rocksdb_writebatch_t {.
    cdecl.}
proc rocksdb_get_latest_sequence_number*(db: ptr rocksdb_t): uint64 {.cdecl.}
proc rocksdb_wal_iter_destroy*(iter: ptr rocksdb_wal_iterator_t) {.cdecl.}
##  Write batch

proc rocksdb_writebatch_create*(): ptr rocksdb_writebatch_t {.cdecl.}
proc rocksdb_writebatch_create_from*(rep: cstring; size: csize_t): ptr rocksdb_writebatch_t {.
    cdecl.}
proc rocksdb_writebatch_create_with_params*(reserved_bytes: csize_t;
    max_bytes: csize_t; protection_bytes_per_key: csize_t; default_cf_ts_sz: csize_t): ptr rocksdb_writebatch_t {.
    cdecl.}
proc rocksdb_writebatch_destroy*(a1: ptr rocksdb_writebatch_t) {.cdecl.}
proc rocksdb_writebatch_clear*(a1: ptr rocksdb_writebatch_t) {.cdecl.}
proc rocksdb_writebatch_count*(a1: ptr rocksdb_writebatch_t): cint {.cdecl.}
proc rocksdb_writebatch_put*(a1: ptr rocksdb_writebatch_t; key: cstring;
                            klen: csize_t; val: cstring; vlen: csize_t) {.cdecl.}
proc rocksdb_writebatch_put_cf*(a1: ptr rocksdb_writebatch_t; column_family: ptr rocksdb_column_family_handle_t;
                               key: cstring; klen: csize_t; val: cstring;
                               vlen: csize_t) {.cdecl.}
proc rocksdb_writebatch_put_cf_with_ts*(a1: ptr rocksdb_writebatch_t; column_family: ptr rocksdb_column_family_handle_t;
                                       key: cstring; klen: csize_t; ts: cstring;
                                       tslen: csize_t; val: cstring; vlen: csize_t) {.
    cdecl.}
proc rocksdb_writebatch_putv*(b: ptr rocksdb_writebatch_t; num_keys: cint;
                             keys_list: cstringArray;
                             keys_list_sizes: ptr csize_t; num_values: cint;
                             values_list: cstringArray;
                             values_list_sizes: ptr csize_t) {.cdecl.}
proc rocksdb_writebatch_putv_cf*(b: ptr rocksdb_writebatch_t; column_family: ptr rocksdb_column_family_handle_t;
                                num_keys: cint; keys_list: cstringArray;
                                keys_list_sizes: ptr csize_t; num_values: cint;
                                values_list: cstringArray;
                                values_list_sizes: ptr csize_t) {.cdecl.}
proc rocksdb_writebatch_merge*(a1: ptr rocksdb_writebatch_t; key: cstring;
                              klen: csize_t; val: cstring; vlen: csize_t) {.cdecl.}
proc rocksdb_writebatch_merge_cf*(a1: ptr rocksdb_writebatch_t; column_family: ptr rocksdb_column_family_handle_t;
                                 key: cstring; klen: csize_t; val: cstring;
                                 vlen: csize_t) {.cdecl.}
proc rocksdb_writebatch_mergev*(b: ptr rocksdb_writebatch_t; num_keys: cint;
                               keys_list: cstringArray;
                               keys_list_sizes: ptr csize_t; num_values: cint;
                               values_list: cstringArray;
                               values_list_sizes: ptr csize_t) {.cdecl.}
proc rocksdb_writebatch_mergev_cf*(b: ptr rocksdb_writebatch_t; column_family: ptr rocksdb_column_family_handle_t;
                                  num_keys: cint; keys_list: cstringArray;
                                  keys_list_sizes: ptr csize_t; num_values: cint;
                                  values_list: cstringArray;
                                  values_list_sizes: ptr csize_t) {.cdecl.}
proc rocksdb_writebatch_delete*(a1: ptr rocksdb_writebatch_t; key: cstring;
                               klen: csize_t) {.cdecl.}
proc rocksdb_writebatch_singledelete*(b: ptr rocksdb_writebatch_t; key: cstring;
                                     klen: csize_t) {.cdecl.}
proc rocksdb_writebatch_delete_cf*(a1: ptr rocksdb_writebatch_t; column_family: ptr rocksdb_column_family_handle_t;
                                  key: cstring; klen: csize_t) {.cdecl.}
proc rocksdb_writebatch_delete_cf_with_ts*(a1: ptr rocksdb_writebatch_t;
    column_family: ptr rocksdb_column_family_handle_t; key: cstring; klen: csize_t;
    ts: cstring; tslen: csize_t) {.cdecl.}
proc rocksdb_writebatch_singledelete_cf*(b: ptr rocksdb_writebatch_t; column_family: ptr rocksdb_column_family_handle_t;
                                        key: cstring; klen: csize_t) {.cdecl.}
proc rocksdb_writebatch_singledelete_cf_with_ts*(b: ptr rocksdb_writebatch_t;
    column_family: ptr rocksdb_column_family_handle_t; key: cstring; klen: csize_t;
    ts: cstring; tslen: csize_t) {.cdecl.}
proc rocksdb_writebatch_deletev*(b: ptr rocksdb_writebatch_t; num_keys: cint;
                                keys_list: cstringArray;
                                keys_list_sizes: ptr csize_t) {.cdecl.}
proc rocksdb_writebatch_deletev_cf*(b: ptr rocksdb_writebatch_t; column_family: ptr rocksdb_column_family_handle_t;
                                   num_keys: cint; keys_list: cstringArray;
                                   keys_list_sizes: ptr csize_t) {.cdecl.}
proc rocksdb_writebatch_delete_range*(b: ptr rocksdb_writebatch_t;
                                     start_key: cstring; start_key_len: csize_t;
                                     end_key: cstring; end_key_len: csize_t) {.cdecl.}
proc rocksdb_writebatch_delete_range_cf*(b: ptr rocksdb_writebatch_t; column_family: ptr rocksdb_column_family_handle_t;
                                        start_key: cstring;
                                        start_key_len: csize_t; end_key: cstring;
                                        end_key_len: csize_t) {.cdecl.}
proc rocksdb_writebatch_delete_rangev*(b: ptr rocksdb_writebatch_t; num_keys: cint;
                                      start_keys_list: cstringArray;
                                      start_keys_list_sizes: ptr csize_t;
                                      end_keys_list: cstringArray;
                                      end_keys_list_sizes: ptr csize_t) {.cdecl.}
proc rocksdb_writebatch_delete_rangev_cf*(b: ptr rocksdb_writebatch_t;
    column_family: ptr rocksdb_column_family_handle_t; num_keys: cint;
    start_keys_list: cstringArray; start_keys_list_sizes: ptr csize_t;
    end_keys_list: cstringArray; end_keys_list_sizes: ptr csize_t) {.cdecl.}
proc rocksdb_writebatch_put_log_data*(a1: ptr rocksdb_writebatch_t; blob: cstring;
                                     len: csize_t) {.cdecl.}
proc rocksdb_writebatch_iterate*(a1: ptr rocksdb_writebatch_t; state: pointer; put: proc (
    a1: pointer; k: cstring; klen: csize_t; v: cstring; vlen: csize_t) {.cdecl.}; deleted: proc (
    a1: pointer; k: cstring; klen: csize_t) {.cdecl.}) {.cdecl.}
proc rocksdb_writebatch_iterate_cf*(a1: ptr rocksdb_writebatch_t; state: pointer;
    put_cf: proc (a1: pointer; cfid: uint32; k: cstring; klen: csize_t; v: cstring;
                vlen: csize_t) {.cdecl.}; deleted_cf: proc (a1: pointer; cfid: uint32;
    k: cstring; klen: csize_t) {.cdecl.}; merge_cf: proc (a1: pointer; cfid: uint32;
    k: cstring; klen: csize_t; v: cstring; vlen: csize_t) {.cdecl.}) {.cdecl.}
proc rocksdb_writebatch_data*(a1: ptr rocksdb_writebatch_t; size: ptr csize_t): cstring {.
    cdecl.}
proc rocksdb_writebatch_set_save_point*(a1: ptr rocksdb_writebatch_t) {.cdecl.}
proc rocksdb_writebatch_rollback_to_save_point*(a1: ptr rocksdb_writebatch_t;
    errptr: cstringArray) {.cdecl.}
proc rocksdb_writebatch_pop_save_point*(a1: ptr rocksdb_writebatch_t;
                                       errptr: cstringArray) {.cdecl.}
proc rocksdb_writebatch_update_timestamps*(wb: ptr rocksdb_writebatch_t;
    ts: cstring; tslen: csize_t; state: pointer;
    get_ts_size: proc (a1: pointer; a2: uint32): csize_t {.cdecl.}; errptr: cstringArray) {.
    cdecl.}
##  Write batch with index

proc rocksdb_writebatch_wi_create*(reserved_bytes: csize_t; overwrite_keys: uint8): ptr rocksdb_writebatch_wi_t {.
    cdecl.}
proc rocksdb_writebatch_wi_create_from*(rep: cstring; size: csize_t): ptr rocksdb_writebatch_wi_t {.
    cdecl.}
proc rocksdb_writebatch_wi_create_with_params*(
    backup_index_comparator: ptr rocksdb_comparator_t; reserved_bytes: csize_t;
    overwrite_key: uint8; max_bytes: csize_t; protection_bytes_per_key: csize_t): ptr rocksdb_writebatch_wi_t {.
    cdecl.}
proc rocksdb_writebatch_wi_destroy*(a1: ptr rocksdb_writebatch_wi_t) {.cdecl.}
proc rocksdb_writebatch_wi_clear*(a1: ptr rocksdb_writebatch_wi_t) {.cdecl.}
proc rocksdb_writebatch_wi_count*(b: ptr rocksdb_writebatch_wi_t): cint {.cdecl.}
proc rocksdb_writebatch_wi_put*(a1: ptr rocksdb_writebatch_wi_t; key: cstring;
                               klen: csize_t; val: cstring; vlen: csize_t) {.cdecl.}
proc rocksdb_writebatch_wi_put_cf*(a1: ptr rocksdb_writebatch_wi_t; column_family: ptr rocksdb_column_family_handle_t;
                                  key: cstring; klen: csize_t; val: cstring;
                                  vlen: csize_t) {.cdecl.}
proc rocksdb_writebatch_wi_putv*(b: ptr rocksdb_writebatch_wi_t; num_keys: cint;
                                keys_list: cstringArray;
                                keys_list_sizes: ptr csize_t; num_values: cint;
                                values_list: cstringArray;
                                values_list_sizes: ptr csize_t) {.cdecl.}
proc rocksdb_writebatch_wi_putv_cf*(b: ptr rocksdb_writebatch_wi_t; column_family: ptr rocksdb_column_family_handle_t;
                                   num_keys: cint; keys_list: cstringArray;
                                   keys_list_sizes: ptr csize_t; num_values: cint;
                                   values_list: cstringArray;
                                   values_list_sizes: ptr csize_t) {.cdecl.}
proc rocksdb_writebatch_wi_merge*(a1: ptr rocksdb_writebatch_wi_t; key: cstring;
                                 klen: csize_t; val: cstring; vlen: csize_t) {.cdecl.}
proc rocksdb_writebatch_wi_merge_cf*(a1: ptr rocksdb_writebatch_wi_t; column_family: ptr rocksdb_column_family_handle_t;
                                    key: cstring; klen: csize_t; val: cstring;
                                    vlen: csize_t) {.cdecl.}
proc rocksdb_writebatch_wi_mergev*(b: ptr rocksdb_writebatch_wi_t; num_keys: cint;
                                  keys_list: cstringArray;
                                  keys_list_sizes: ptr csize_t; num_values: cint;
                                  values_list: cstringArray;
                                  values_list_sizes: ptr csize_t) {.cdecl.}
proc rocksdb_writebatch_wi_mergev_cf*(b: ptr rocksdb_writebatch_wi_t; column_family: ptr rocksdb_column_family_handle_t;
                                     num_keys: cint; keys_list: cstringArray;
                                     keys_list_sizes: ptr csize_t;
                                     num_values: cint; values_list: cstringArray;
                                     values_list_sizes: ptr csize_t) {.cdecl.}
proc rocksdb_writebatch_wi_delete*(a1: ptr rocksdb_writebatch_wi_t; key: cstring;
                                  klen: csize_t) {.cdecl.}
proc rocksdb_writebatch_wi_singledelete*(a1: ptr rocksdb_writebatch_wi_t;
                                        key: cstring; klen: csize_t) {.cdecl.}
proc rocksdb_writebatch_wi_delete_cf*(a1: ptr rocksdb_writebatch_wi_t; column_family: ptr rocksdb_column_family_handle_t;
                                     key: cstring; klen: csize_t) {.cdecl.}
proc rocksdb_writebatch_wi_singledelete_cf*(a1: ptr rocksdb_writebatch_wi_t;
    column_family: ptr rocksdb_column_family_handle_t; key: cstring; klen: csize_t) {.
    cdecl.}
proc rocksdb_writebatch_wi_deletev*(b: ptr rocksdb_writebatch_wi_t; num_keys: cint;
                                   keys_list: cstringArray;
                                   keys_list_sizes: ptr csize_t) {.cdecl.}
proc rocksdb_writebatch_wi_deletev_cf*(b: ptr rocksdb_writebatch_wi_t; column_family: ptr rocksdb_column_family_handle_t;
                                      num_keys: cint; keys_list: cstringArray;
                                      keys_list_sizes: ptr csize_t) {.cdecl.}
##  DO NOT USE - rocksdb_writebatch_wi_delete_range is not yet supported

proc rocksdb_writebatch_wi_delete_range*(b: ptr rocksdb_writebatch_wi_t;
                                        start_key: cstring;
                                        start_key_len: csize_t; end_key: cstring;
                                        end_key_len: csize_t) {.cdecl.}
##  DO NOT USE - rocksdb_writebatch_wi_delete_range_cf is not yet supported

proc rocksdb_writebatch_wi_delete_range_cf*(b: ptr rocksdb_writebatch_wi_t;
    column_family: ptr rocksdb_column_family_handle_t; start_key: cstring;
    start_key_len: csize_t; end_key: cstring; end_key_len: csize_t) {.cdecl.}
##  DO NOT USE - rocksdb_writebatch_wi_delete_rangev is not yet supported

proc rocksdb_writebatch_wi_delete_rangev*(b: ptr rocksdb_writebatch_wi_t;
    num_keys: cint; start_keys_list: cstringArray;
    start_keys_list_sizes: ptr csize_t; end_keys_list: cstringArray;
    end_keys_list_sizes: ptr csize_t) {.cdecl.}
##  DO NOT USE - rocksdb_writebatch_wi_delete_rangev_cf is not yet supported

proc rocksdb_writebatch_wi_delete_rangev_cf*(b: ptr rocksdb_writebatch_wi_t;
    column_family: ptr rocksdb_column_family_handle_t; num_keys: cint;
    start_keys_list: cstringArray; start_keys_list_sizes: ptr csize_t;
    end_keys_list: cstringArray; end_keys_list_sizes: ptr csize_t) {.cdecl.}
proc rocksdb_writebatch_wi_put_log_data*(a1: ptr rocksdb_writebatch_wi_t;
                                        blob: cstring; len: csize_t) {.cdecl.}
proc rocksdb_writebatch_wi_iterate*(b: ptr rocksdb_writebatch_wi_t; state: pointer;
    put: proc (a1: pointer; k: cstring; klen: csize_t; v: cstring; vlen: csize_t) {.cdecl.};
    deleted: proc (a1: pointer; k: cstring; klen: csize_t) {.cdecl.}) {.cdecl.}
proc rocksdb_writebatch_wi_data*(b: ptr rocksdb_writebatch_wi_t; size: ptr csize_t): cstring {.
    cdecl.}
proc rocksdb_writebatch_wi_set_save_point*(a1: ptr rocksdb_writebatch_wi_t) {.cdecl.}
proc rocksdb_writebatch_wi_rollback_to_save_point*(
    a1: ptr rocksdb_writebatch_wi_t; errptr: cstringArray) {.cdecl.}
proc rocksdb_writebatch_wi_get_from_batch*(wbwi: ptr rocksdb_writebatch_wi_t;
    options: ptr rocksdb_options_t; key: cstring; keylen: csize_t; vallen: ptr csize_t;
    errptr: cstringArray): cstring {.cdecl.}
proc rocksdb_writebatch_wi_get_from_batch_cf*(wbwi: ptr rocksdb_writebatch_wi_t;
    options: ptr rocksdb_options_t;
    column_family: ptr rocksdb_column_family_handle_t; key: cstring; keylen: csize_t;
    vallen: ptr csize_t; errptr: cstringArray): cstring {.cdecl.}
proc rocksdb_writebatch_wi_get_from_batch_and_db*(
    wbwi: ptr rocksdb_writebatch_wi_t; db: ptr rocksdb_t;
    options: ptr rocksdb_readoptions_t; key: cstring; keylen: csize_t;
    vallen: ptr csize_t; errptr: cstringArray): cstring {.cdecl.}
proc rocksdb_writebatch_wi_get_from_batch_and_db_cf*(
    wbwi: ptr rocksdb_writebatch_wi_t; db: ptr rocksdb_t;
    options: ptr rocksdb_readoptions_t;
    column_family: ptr rocksdb_column_family_handle_t; key: cstring; keylen: csize_t;
    vallen: ptr csize_t; errptr: cstringArray): cstring {.cdecl.}
proc rocksdb_write_writebatch_wi*(db: ptr rocksdb_t;
                                 options: ptr rocksdb_writeoptions_t;
                                 wbwi: ptr rocksdb_writebatch_wi_t;
                                 errptr: cstringArray) {.cdecl.}
proc rocksdb_writebatch_wi_create_iterator_with_base*(
    wbwi: ptr rocksdb_writebatch_wi_t; base_iterator: ptr rocksdb_iterator_t): ptr rocksdb_iterator_t {.
    cdecl.}
proc rocksdb_writebatch_wi_create_iterator_with_base_cf*(
    wbwi: ptr rocksdb_writebatch_wi_t; base_iterator: ptr rocksdb_iterator_t;
    cf: ptr rocksdb_column_family_handle_t): ptr rocksdb_iterator_t {.cdecl.}
proc rocksdb_writebatch_wi_update_timestamps*(wbwi: ptr rocksdb_writebatch_wi_t;
    ts: cstring; tslen: csize_t; state: pointer;
    get_ts_size: proc (a1: pointer; a2: uint32): csize_t {.cdecl.}; errptr: cstringArray) {.
    cdecl.}
##  Options utils
##  Load the latest rocksdb options from the specified db_path.
##
##  On success, num_column_families will be updated with a non-zero
##  number indicating the number of column families.
##  The returned db_options, column_family_names, and column_family_options
##  should be released via rocksdb_load_latest_options_destroy().
##
##  On error, a non-null errptr that includes the error message will be
##  returned.  db_options, column_family_names, and column_family_options
##  will be set to NULL.

proc rocksdb_load_latest_options*(db_path: cstring; env: ptr rocksdb_env_t;
                                 ignore_unknown_options: bool;
                                 cache: ptr rocksdb_cache_t;
                                 db_options: ptr ptr rocksdb_options_t;
                                 num_column_families: ptr csize_t;
                                 column_family_names: ptr cstringArray;
    column_family_options: ptr ptr ptr rocksdb_options_t; errptr: cstringArray) {.cdecl.}
proc rocksdb_load_latest_options_destroy*(db_options: ptr rocksdb_options_t;
    list_column_family_names: cstringArray;
    list_column_family_options: ptr ptr rocksdb_options_t; len: csize_t) {.cdecl.}
##  Block based table options

proc rocksdb_block_based_options_create*(): ptr rocksdb_block_based_table_options_t {.
    cdecl.}
proc rocksdb_block_based_options_destroy*(
    options: ptr rocksdb_block_based_table_options_t) {.cdecl.}
proc rocksdb_block_based_options_set_checksum*(
    a1: ptr rocksdb_block_based_table_options_t; a2: char) {.cdecl.}
proc rocksdb_block_based_options_set_block_size*(
    options: ptr rocksdb_block_based_table_options_t; block_size: csize_t) {.cdecl.}
proc rocksdb_block_based_options_set_block_size_deviation*(
    options: ptr rocksdb_block_based_table_options_t; block_size_deviation: cint) {.
    cdecl.}
proc rocksdb_block_based_options_set_block_restart_interval*(
    options: ptr rocksdb_block_based_table_options_t; block_restart_interval: cint) {.
    cdecl.}
proc rocksdb_block_based_options_set_index_block_restart_interval*(
    options: ptr rocksdb_block_based_table_options_t;
    index_block_restart_interval: cint) {.cdecl.}
proc rocksdb_block_based_options_set_metadata_block_size*(
    options: ptr rocksdb_block_based_table_options_t; metadata_block_size: uint64) {.
    cdecl.}
proc rocksdb_block_based_options_set_partition_filters*(
    options: ptr rocksdb_block_based_table_options_t; partition_filters: uint8) {.
    cdecl.}
proc rocksdb_block_based_options_set_optimize_filters_for_memory*(
    options: ptr rocksdb_block_based_table_options_t;
    optimize_filters_for_memory: uint8) {.cdecl.}
proc rocksdb_block_based_options_set_use_delta_encoding*(
    options: ptr rocksdb_block_based_table_options_t; use_delta_encoding: uint8) {.
    cdecl.}
proc rocksdb_block_based_options_set_filter_policy*(
    options: ptr rocksdb_block_based_table_options_t;
    filter_policy: ptr rocksdb_filterpolicy_t) {.cdecl.}
proc rocksdb_block_based_options_set_no_block_cache*(
    options: ptr rocksdb_block_based_table_options_t; no_block_cache: uint8) {.cdecl.}
proc rocksdb_block_based_options_set_block_cache*(
    options: ptr rocksdb_block_based_table_options_t;
    block_cache: ptr rocksdb_cache_t) {.cdecl.}
proc rocksdb_block_based_options_set_whole_key_filtering*(
    a1: ptr rocksdb_block_based_table_options_t; a2: uint8) {.cdecl.}
proc rocksdb_block_based_options_set_format_version*(
    a1: ptr rocksdb_block_based_table_options_t; a2: cint) {.cdecl.}
const
  rocksdb_block_based_table_index_type_binary_search* = 0
  rocksdb_block_based_table_index_type_hash_search* = 1
  rocksdb_block_based_table_index_type_two_level_index_search* = 2

proc rocksdb_block_based_options_set_index_type*(
    a1: ptr rocksdb_block_based_table_options_t; a2: cint) {.cdecl.}
##  uses one of the above enums

const
  rocksdb_block_based_table_data_block_index_type_binary_search* = 0
  rocksdb_block_based_table_data_block_index_type_binary_search_and_hash* = 1

proc rocksdb_block_based_options_set_data_block_index_type*(
    a1: ptr rocksdb_block_based_table_options_t; a2: cint) {.cdecl.}
##  uses one of the above enums

proc rocksdb_block_based_options_set_data_block_hash_ratio*(
    options: ptr rocksdb_block_based_table_options_t; v: cdouble) {.cdecl.}
##  rocksdb_block_based_options_set_hash_index_allow_collision()
##  is removed since BlockBasedTableOptions.hash_index_allow_collision()
##  is removed

proc rocksdb_block_based_options_set_cache_index_and_filter_blocks*(
    a1: ptr rocksdb_block_based_table_options_t; a2: uint8) {.cdecl.}
proc rocksdb_block_based_options_set_cache_index_and_filter_blocks_with_high_priority*(
    a1: ptr rocksdb_block_based_table_options_t; a2: uint8) {.cdecl.}
proc rocksdb_block_based_options_set_pin_l0_filter_and_index_blocks_in_cache*(
    a1: ptr rocksdb_block_based_table_options_t; a2: uint8) {.cdecl.}
proc rocksdb_block_based_options_set_pin_top_level_index_and_filter*(
    a1: ptr rocksdb_block_based_table_options_t; a2: uint8) {.cdecl.}
proc rocksdb_options_set_block_based_table_factory*(opt: ptr rocksdb_options_t;
    table_options: ptr rocksdb_block_based_table_options_t) {.cdecl.}
const
  rocksdb_block_based_k_fallback_pinning_tier* = 0
  rocksdb_block_based_k_none_pinning_tier* = 1
  rocksdb_block_based_k_flush_and_similar_pinning_tier* = 2
  rocksdb_block_based_k_all_pinning_tier* = 3

proc rocksdb_block_based_options_set_top_level_index_pinning_tier*(
    a1: ptr rocksdb_block_based_table_options_t; a2: cint) {.cdecl.}
proc rocksdb_block_based_options_set_partition_pinning_tier*(
    a1: ptr rocksdb_block_based_table_options_t; a2: cint) {.cdecl.}
proc rocksdb_block_based_options_set_unpartitioned_pinning_tier*(
    a1: ptr rocksdb_block_based_table_options_t; a2: cint) {.cdecl.}
proc rocksdb_options_set_write_buffer_manager*(opt: ptr rocksdb_options_t;
    wbm: ptr rocksdb_write_buffer_manager_t) {.cdecl.}
##  Cuckoo table options

proc rocksdb_cuckoo_options_create*(): ptr rocksdb_cuckoo_table_options_t {.cdecl.}
proc rocksdb_cuckoo_options_destroy*(options: ptr rocksdb_cuckoo_table_options_t) {.
    cdecl.}
proc rocksdb_cuckoo_options_set_hash_ratio*(
    options: ptr rocksdb_cuckoo_table_options_t; v: cdouble) {.cdecl.}
proc rocksdb_cuckoo_options_set_max_search_depth*(
    options: ptr rocksdb_cuckoo_table_options_t; v: uint32) {.cdecl.}
proc rocksdb_cuckoo_options_set_cuckoo_block_size*(
    options: ptr rocksdb_cuckoo_table_options_t; v: uint32) {.cdecl.}
proc rocksdb_cuckoo_options_set_identity_as_first_hash*(
    options: ptr rocksdb_cuckoo_table_options_t; v: uint8) {.cdecl.}
proc rocksdb_cuckoo_options_set_use_module_hash*(
    options: ptr rocksdb_cuckoo_table_options_t; v: uint8) {.cdecl.}
proc rocksdb_options_set_cuckoo_table_factory*(opt: ptr rocksdb_options_t;
    table_options: ptr rocksdb_cuckoo_table_options_t) {.cdecl.}
##  Options

proc rocksdb_set_options*(db: ptr rocksdb_t; count: cint; keys: ptr cstring;
                         values: ptr cstring; errptr: cstringArray) {.cdecl.}
proc rocksdb_set_options_cf*(db: ptr rocksdb_t;
                            handle: ptr rocksdb_column_family_handle_t;
                            count: cint; keys: ptr cstring; values: ptr cstring;
                            errptr: cstringArray) {.cdecl.}
proc rocksdb_options_create*(): ptr rocksdb_options_t {.cdecl.}
proc rocksdb_options_destroy*(a1: ptr rocksdb_options_t) {.cdecl.}
proc rocksdb_options_create_copy*(a1: ptr rocksdb_options_t): ptr rocksdb_options_t {.
    cdecl.}
proc rocksdb_options_increase_parallelism*(opt: ptr rocksdb_options_t;
    total_threads: cint) {.cdecl.}
proc rocksdb_options_optimize_for_point_lookup*(opt: ptr rocksdb_options_t;
    block_cache_size_mb: uint64) {.cdecl.}
proc rocksdb_options_optimize_level_style_compaction*(opt: ptr rocksdb_options_t;
    memtable_memory_budget: uint64) {.cdecl.}
proc rocksdb_options_optimize_universal_style_compaction*(
    opt: ptr rocksdb_options_t; memtable_memory_budget: uint64) {.cdecl.}
proc rocksdb_options_set_allow_ingest_behind*(a1: ptr rocksdb_options_t; a2: uint8) {.
    cdecl.}
proc rocksdb_options_get_allow_ingest_behind*(a1: ptr rocksdb_options_t): uint8 {.
    cdecl.}
proc rocksdb_options_set_compaction_filter*(a1: ptr rocksdb_options_t;
    a2: ptr rocksdb_compactionfilter_t) {.cdecl.}
proc rocksdb_options_set_compaction_filter_factory*(a1: ptr rocksdb_options_t;
    a2: ptr rocksdb_compactionfilterfactory_t) {.cdecl.}
proc rocksdb_options_compaction_readahead_size*(a1: ptr rocksdb_options_t;
    a2: csize_t) {.cdecl.}
proc rocksdb_options_get_compaction_readahead_size*(a1: ptr rocksdb_options_t): csize_t {.
    cdecl.}
proc rocksdb_options_set_comparator*(a1: ptr rocksdb_options_t;
                                    a2: ptr rocksdb_comparator_t) {.cdecl.}
proc rocksdb_options_set_merge_operator*(a1: ptr rocksdb_options_t;
                                        a2: ptr rocksdb_mergeoperator_t) {.cdecl.}
proc rocksdb_options_set_uint64add_merge_operator*(a1: ptr rocksdb_options_t) {.
    cdecl.}
proc rocksdb_options_set_compression_per_level*(opt: ptr rocksdb_options_t;
    level_values: ptr cint; num_levels: csize_t) {.cdecl.}
proc rocksdb_options_set_create_if_missing*(a1: ptr rocksdb_options_t; a2: uint8) {.
    cdecl.}
proc rocksdb_options_get_create_if_missing*(a1: ptr rocksdb_options_t): uint8 {.cdecl.}
proc rocksdb_options_set_create_missing_column_families*(
    a1: ptr rocksdb_options_t; a2: uint8) {.cdecl.}
proc rocksdb_options_get_create_missing_column_families*(
    a1: ptr rocksdb_options_t): uint8 {.cdecl.}
proc rocksdb_options_set_error_if_exists*(a1: ptr rocksdb_options_t; a2: uint8) {.
    cdecl.}
proc rocksdb_options_get_error_if_exists*(a1: ptr rocksdb_options_t): uint8 {.cdecl.}
proc rocksdb_options_set_paranoid_checks*(a1: ptr rocksdb_options_t; a2: uint8) {.
    cdecl.}
proc rocksdb_options_get_paranoid_checks*(a1: ptr rocksdb_options_t): uint8 {.cdecl.}
proc rocksdb_options_set_db_paths*(a1: ptr rocksdb_options_t;
                                  path_values: ptr ptr rocksdb_dbpath_t;
                                  num_paths: csize_t) {.cdecl.}
proc rocksdb_options_set_cf_paths*(a1: ptr rocksdb_options_t;
                                  path_values: ptr ptr rocksdb_dbpath_t;
                                  num_paths: csize_t) {.cdecl.}
proc rocksdb_options_set_env*(a1: ptr rocksdb_options_t; a2: ptr rocksdb_env_t) {.cdecl.}
proc rocksdb_options_set_info_log*(a1: ptr rocksdb_options_t;
                                  a2: ptr rocksdb_logger_t) {.cdecl.}
proc rocksdb_options_get_info_log*(opt: ptr rocksdb_options_t): ptr rocksdb_logger_t {.
    cdecl.}
proc rocksdb_options_set_info_log_level*(a1: ptr rocksdb_options_t; a2: cint) {.cdecl.}
proc rocksdb_options_get_info_log_level*(a1: ptr rocksdb_options_t): cint {.cdecl.}
proc rocksdb_logger_create_stderr_logger*(log_level: cint; prefix: cstring): ptr rocksdb_logger_t {.
    cdecl.}
proc rocksdb_logger_create_callback_logger*(log_level: cint;
    a2: proc (priv: pointer; lev: cuint; msg: cstring; len: csize_t) {.cdecl.};
    priv: pointer): ptr rocksdb_logger_t {.cdecl.}
proc rocksdb_logger_destroy*(logger: ptr rocksdb_logger_t) {.cdecl.}
proc rocksdb_options_set_write_buffer_size*(a1: ptr rocksdb_options_t; a2: csize_t) {.
    cdecl.}
proc rocksdb_options_get_write_buffer_size*(a1: ptr rocksdb_options_t): csize_t {.
    cdecl.}
proc rocksdb_options_set_db_write_buffer_size*(a1: ptr rocksdb_options_t;
    a2: csize_t) {.cdecl.}
proc rocksdb_options_get_db_write_buffer_size*(a1: ptr rocksdb_options_t): csize_t {.
    cdecl.}
proc rocksdb_options_set_max_open_files*(a1: ptr rocksdb_options_t; a2: cint) {.cdecl.}
proc rocksdb_options_get_max_open_files*(a1: ptr rocksdb_options_t): cint {.cdecl.}
proc rocksdb_options_set_max_file_opening_threads*(a1: ptr rocksdb_options_t;
    a2: cint) {.cdecl.}
proc rocksdb_options_get_max_file_opening_threads*(a1: ptr rocksdb_options_t): cint {.
    cdecl.}
proc rocksdb_options_set_max_total_wal_size*(opt: ptr rocksdb_options_t; n: uint64) {.
    cdecl.}
proc rocksdb_options_get_max_total_wal_size*(opt: ptr rocksdb_options_t): uint64 {.
    cdecl.}
proc rocksdb_options_set_compression_options*(a1: ptr rocksdb_options_t; a2: cint;
    a3: cint; a4: cint; a5: cint) {.cdecl.}
proc rocksdb_options_set_compression_options_zstd_max_train_bytes*(
    a1: ptr rocksdb_options_t; a2: cint) {.cdecl.}
proc rocksdb_options_get_compression_options_zstd_max_train_bytes*(
    opt: ptr rocksdb_options_t): cint {.cdecl.}
proc rocksdb_options_set_compression_options_use_zstd_dict_trainer*(
    a1: ptr rocksdb_options_t; a2: uint8) {.cdecl.}
proc rocksdb_options_get_compression_options_use_zstd_dict_trainer*(
    opt: ptr rocksdb_options_t): uint8 {.cdecl.}
proc rocksdb_options_set_compression_options_parallel_threads*(
    a1: ptr rocksdb_options_t; a2: cint) {.cdecl.}
proc rocksdb_options_get_compression_options_parallel_threads*(
    opt: ptr rocksdb_options_t): cint {.cdecl.}
proc rocksdb_options_set_compression_options_max_dict_buffer_bytes*(
    a1: ptr rocksdb_options_t; a2: uint64) {.cdecl.}
proc rocksdb_options_get_compression_options_max_dict_buffer_bytes*(
    opt: ptr rocksdb_options_t): uint64 {.cdecl.}
proc rocksdb_options_set_bottommost_compression_options*(
    a1: ptr rocksdb_options_t; a2: cint; a3: cint; a4: cint; a5: cint; a6: uint8) {.cdecl.}
proc rocksdb_options_set_bottommost_compression_options_zstd_max_train_bytes*(
    a1: ptr rocksdb_options_t; a2: cint; a3: uint8) {.cdecl.}
proc rocksdb_options_set_bottommost_compression_options_use_zstd_dict_trainer*(
    a1: ptr rocksdb_options_t; a2: uint8; a3: uint8) {.cdecl.}
proc rocksdb_options_get_bottommost_compression_options_use_zstd_dict_trainer*(
    opt: ptr rocksdb_options_t): uint8 {.cdecl.}
proc rocksdb_options_set_bottommost_compression_options_max_dict_buffer_bytes*(
    a1: ptr rocksdb_options_t; a2: uint64; a3: uint8) {.cdecl.}
proc rocksdb_options_set_prefix_extractor*(a1: ptr rocksdb_options_t;
    a2: ptr rocksdb_slicetransform_t) {.cdecl.}
proc rocksdb_options_set_num_levels*(a1: ptr rocksdb_options_t; a2: cint) {.cdecl.}
proc rocksdb_options_get_num_levels*(a1: ptr rocksdb_options_t): cint {.cdecl.}
proc rocksdb_options_set_level0_file_num_compaction_trigger*(
    a1: ptr rocksdb_options_t; a2: cint) {.cdecl.}
proc rocksdb_options_get_level0_file_num_compaction_trigger*(
    a1: ptr rocksdb_options_t): cint {.cdecl.}
proc rocksdb_options_set_level0_slowdown_writes_trigger*(
    a1: ptr rocksdb_options_t; a2: cint) {.cdecl.}
proc rocksdb_options_get_level0_slowdown_writes_trigger*(
    a1: ptr rocksdb_options_t): cint {.cdecl.}
proc rocksdb_options_set_level0_stop_writes_trigger*(a1: ptr rocksdb_options_t;
    a2: cint) {.cdecl.}
proc rocksdb_options_get_level0_stop_writes_trigger*(a1: ptr rocksdb_options_t): cint {.
    cdecl.}
proc rocksdb_options_set_target_file_size_base*(a1: ptr rocksdb_options_t;
    a2: uint64) {.cdecl.}
proc rocksdb_options_get_target_file_size_base*(a1: ptr rocksdb_options_t): uint64 {.
    cdecl.}
proc rocksdb_options_set_target_file_size_multiplier*(a1: ptr rocksdb_options_t;
    a2: cint) {.cdecl.}
proc rocksdb_options_get_target_file_size_multiplier*(a1: ptr rocksdb_options_t): cint {.
    cdecl.}
proc rocksdb_options_set_max_bytes_for_level_base*(a1: ptr rocksdb_options_t;
    a2: uint64) {.cdecl.}
proc rocksdb_options_get_max_bytes_for_level_base*(a1: ptr rocksdb_options_t): uint64 {.
    cdecl.}
proc rocksdb_options_set_level_compaction_dynamic_level_bytes*(
    a1: ptr rocksdb_options_t; a2: uint8) {.cdecl.}
proc rocksdb_options_get_level_compaction_dynamic_level_bytes*(
    a1: ptr rocksdb_options_t): uint8 {.cdecl.}
proc rocksdb_options_set_max_bytes_for_level_multiplier*(
    a1: ptr rocksdb_options_t; a2: cdouble) {.cdecl.}
proc rocksdb_options_get_max_bytes_for_level_multiplier*(
    a1: ptr rocksdb_options_t): cdouble {.cdecl.}
proc rocksdb_options_set_max_bytes_for_level_multiplier_additional*(
    a1: ptr rocksdb_options_t; level_values: ptr cint; num_levels: csize_t) {.cdecl.}
proc rocksdb_options_enable_statistics*(a1: ptr rocksdb_options_t) {.cdecl.}
proc rocksdb_options_set_ttl*(a1: ptr rocksdb_options_t; a2: uint64) {.cdecl.}
proc rocksdb_options_get_ttl*(a1: ptr rocksdb_options_t): uint64 {.cdecl.}
proc rocksdb_options_set_periodic_compaction_seconds*(a1: ptr rocksdb_options_t;
    a2: uint64) {.cdecl.}
proc rocksdb_options_get_periodic_compaction_seconds*(a1: ptr rocksdb_options_t): uint64 {.
    cdecl.}
const
  rocksdb_statistics_level_disable_all* = 0
  rocksdb_statistics_level_except_tickers* = rocksdb_statistics_level_disable_all
  rocksdb_statistics_level_except_histogram_or_timers* = 1
  rocksdb_statistics_level_except_timers* = 2
  rocksdb_statistics_level_except_detailed_timers* = 3
  rocksdb_statistics_level_except_time_for_mutex* = 4
  rocksdb_statistics_level_all* = 5

proc rocksdb_options_set_statistics_level*(a1: ptr rocksdb_options_t; level: cint) {.
    cdecl.}
proc rocksdb_options_get_statistics_level*(a1: ptr rocksdb_options_t): cint {.cdecl.}
proc rocksdb_options_set_skip_stats_update_on_db_open*(
    opt: ptr rocksdb_options_t; val: uint8) {.cdecl.}
proc rocksdb_options_get_skip_stats_update_on_db_open*(opt: ptr rocksdb_options_t): uint8 {.
    cdecl.}
proc rocksdb_options_set_skip_checking_sst_file_sizes_on_db_open*(
    opt: ptr rocksdb_options_t; val: uint8) {.cdecl.}
proc rocksdb_options_get_skip_checking_sst_file_sizes_on_db_open*(
    opt: ptr rocksdb_options_t): uint8 {.cdecl.}
##  Blob Options Settings

proc rocksdb_options_set_enable_blob_files*(opt: ptr rocksdb_options_t; val: uint8) {.
    cdecl.}
proc rocksdb_options_get_enable_blob_files*(opt: ptr rocksdb_options_t): uint8 {.
    cdecl.}
proc rocksdb_options_set_min_blob_size*(opt: ptr rocksdb_options_t; val: uint64) {.
    cdecl.}
proc rocksdb_options_get_min_blob_size*(opt: ptr rocksdb_options_t): uint64 {.cdecl.}
proc rocksdb_options_set_blob_file_size*(opt: ptr rocksdb_options_t; val: uint64) {.
    cdecl.}
proc rocksdb_options_get_blob_file_size*(opt: ptr rocksdb_options_t): uint64 {.cdecl.}
proc rocksdb_options_set_blob_compression_type*(opt: ptr rocksdb_options_t;
    val: cint) {.cdecl.}
proc rocksdb_options_get_blob_compression_type*(opt: ptr rocksdb_options_t): cint {.
    cdecl.}
proc rocksdb_options_set_enable_blob_gc*(opt: ptr rocksdb_options_t; val: uint8) {.
    cdecl.}
proc rocksdb_options_get_enable_blob_gc*(opt: ptr rocksdb_options_t): uint8 {.cdecl.}
proc rocksdb_options_set_blob_gc_age_cutoff*(opt: ptr rocksdb_options_t;
    val: cdouble) {.cdecl.}
proc rocksdb_options_get_blob_gc_age_cutoff*(opt: ptr rocksdb_options_t): cdouble {.
    cdecl.}
proc rocksdb_options_set_blob_gc_force_threshold*(opt: ptr rocksdb_options_t;
    val: cdouble) {.cdecl.}
proc rocksdb_options_get_blob_gc_force_threshold*(opt: ptr rocksdb_options_t): cdouble {.
    cdecl.}
proc rocksdb_options_set_blob_compaction_readahead_size*(
    opt: ptr rocksdb_options_t; val: uint64) {.cdecl.}
proc rocksdb_options_get_blob_compaction_readahead_size*(
    opt: ptr rocksdb_options_t): uint64 {.cdecl.}
proc rocksdb_options_set_blob_file_starting_level*(opt: ptr rocksdb_options_t;
    val: cint) {.cdecl.}
proc rocksdb_options_get_blob_file_starting_level*(opt: ptr rocksdb_options_t): cint {.
    cdecl.}
proc rocksdb_options_set_blob_cache*(opt: ptr rocksdb_options_t;
                                    blob_cache: ptr rocksdb_cache_t) {.cdecl.}
const
  rocksdb_prepopulate_blob_disable* = 0
  rocksdb_prepopulate_blob_flush_only* = 1

proc rocksdb_options_set_prepopulate_blob_cache*(opt: ptr rocksdb_options_t;
    val: cint) {.cdecl.}
proc rocksdb_options_get_prepopulate_blob_cache*(opt: ptr rocksdb_options_t): cint {.
    cdecl.}
##  returns a pointer to a malloc()-ed, null terminated string

proc rocksdb_options_statistics_get_string*(opt: ptr rocksdb_options_t): cstring {.
    cdecl.}
proc rocksdb_options_statistics_get_ticker_count*(opt: ptr rocksdb_options_t;
    ticker_type: uint32): uint64 {.cdecl.}
proc rocksdb_options_statistics_get_histogram_data*(opt: ptr rocksdb_options_t;
    histogram_type: uint32; data: ptr rocksdb_statistics_histogram_data_t) {.cdecl.}
proc rocksdb_options_set_max_write_buffer_number*(a1: ptr rocksdb_options_t;
    a2: cint) {.cdecl.}
proc rocksdb_options_get_max_write_buffer_number*(a1: ptr rocksdb_options_t): cint {.
    cdecl.}
proc rocksdb_options_set_min_write_buffer_number_to_merge*(
    a1: ptr rocksdb_options_t; a2: cint) {.cdecl.}
proc rocksdb_options_get_min_write_buffer_number_to_merge*(
    a1: ptr rocksdb_options_t): cint {.cdecl.}
proc rocksdb_options_set_max_write_buffer_number_to_maintain*(
    a1: ptr rocksdb_options_t; a2: cint) {.cdecl.}
proc rocksdb_options_get_max_write_buffer_number_to_maintain*(
    a1: ptr rocksdb_options_t): cint {.cdecl.}
proc rocksdb_options_set_max_write_buffer_size_to_maintain*(
    a1: ptr rocksdb_options_t; a2: int64) {.cdecl.}
proc rocksdb_options_get_max_write_buffer_size_to_maintain*(
    a1: ptr rocksdb_options_t): int64 {.cdecl.}
proc rocksdb_options_set_enable_pipelined_write*(a1: ptr rocksdb_options_t;
    a2: uint8) {.cdecl.}
proc rocksdb_options_get_enable_pipelined_write*(a1: ptr rocksdb_options_t): uint8 {.
    cdecl.}
proc rocksdb_options_set_unordered_write*(a1: ptr rocksdb_options_t; a2: uint8) {.
    cdecl.}
proc rocksdb_options_get_unordered_write*(a1: ptr rocksdb_options_t): uint8 {.cdecl.}
proc rocksdb_options_set_max_subcompactions*(a1: ptr rocksdb_options_t; a2: uint32) {.
    cdecl.}
proc rocksdb_options_get_max_subcompactions*(a1: ptr rocksdb_options_t): uint32 {.
    cdecl.}
proc rocksdb_options_set_max_background_jobs*(a1: ptr rocksdb_options_t; a2: cint) {.
    cdecl.}
proc rocksdb_options_get_max_background_jobs*(a1: ptr rocksdb_options_t): cint {.
    cdecl.}
proc rocksdb_options_set_max_background_compactions*(a1: ptr rocksdb_options_t;
    a2: cint) {.cdecl.}
proc rocksdb_options_get_max_background_compactions*(a1: ptr rocksdb_options_t): cint {.
    cdecl.}
proc rocksdb_options_set_max_background_flushes*(a1: ptr rocksdb_options_t; a2: cint) {.
    cdecl.}
proc rocksdb_options_get_max_background_flushes*(a1: ptr rocksdb_options_t): cint {.
    cdecl.}
proc rocksdb_options_set_max_log_file_size*(a1: ptr rocksdb_options_t; a2: csize_t) {.
    cdecl.}
proc rocksdb_options_get_max_log_file_size*(a1: ptr rocksdb_options_t): csize_t {.
    cdecl.}
proc rocksdb_options_set_log_file_time_to_roll*(a1: ptr rocksdb_options_t;
    a2: csize_t) {.cdecl.}
proc rocksdb_options_get_log_file_time_to_roll*(a1: ptr rocksdb_options_t): csize_t {.
    cdecl.}
proc rocksdb_options_set_keep_log_file_num*(a1: ptr rocksdb_options_t; a2: csize_t) {.
    cdecl.}
proc rocksdb_options_get_keep_log_file_num*(a1: ptr rocksdb_options_t): csize_t {.
    cdecl.}
proc rocksdb_options_set_recycle_log_file_num*(a1: ptr rocksdb_options_t;
    a2: csize_t) {.cdecl.}
proc rocksdb_options_get_recycle_log_file_num*(a1: ptr rocksdb_options_t): csize_t {.
    cdecl.}
proc rocksdb_options_set_soft_pending_compaction_bytes_limit*(
    opt: ptr rocksdb_options_t; v: csize_t) {.cdecl.}
proc rocksdb_options_get_soft_pending_compaction_bytes_limit*(
    opt: ptr rocksdb_options_t): csize_t {.cdecl.}
proc rocksdb_options_set_hard_pending_compaction_bytes_limit*(
    opt: ptr rocksdb_options_t; v: csize_t) {.cdecl.}
proc rocksdb_options_get_hard_pending_compaction_bytes_limit*(
    opt: ptr rocksdb_options_t): csize_t {.cdecl.}
proc rocksdb_options_set_max_manifest_file_size*(a1: ptr rocksdb_options_t;
    a2: csize_t) {.cdecl.}
proc rocksdb_options_get_max_manifest_file_size*(a1: ptr rocksdb_options_t): csize_t {.
    cdecl.}
proc rocksdb_options_set_table_cache_numshardbits*(a1: ptr rocksdb_options_t;
    a2: cint) {.cdecl.}
proc rocksdb_options_get_table_cache_numshardbits*(a1: ptr rocksdb_options_t): cint {.
    cdecl.}
proc rocksdb_options_set_arena_block_size*(a1: ptr rocksdb_options_t; a2: csize_t) {.
    cdecl.}
proc rocksdb_options_get_arena_block_size*(a1: ptr rocksdb_options_t): csize_t {.
    cdecl.}
proc rocksdb_options_set_use_fsync*(a1: ptr rocksdb_options_t; a2: cint) {.cdecl.}
proc rocksdb_options_get_use_fsync*(a1: ptr rocksdb_options_t): cint {.cdecl.}
proc rocksdb_options_set_db_log_dir*(a1: ptr rocksdb_options_t; a2: cstring) {.cdecl.}
proc rocksdb_options_set_wal_dir*(a1: ptr rocksdb_options_t; a2: cstring) {.cdecl.}
proc rocksdb_options_set_WAL_ttl_seconds*(a1: ptr rocksdb_options_t; a2: uint64) {.
    cdecl.}
proc rocksdb_options_get_WAL_ttl_seconds*(a1: ptr rocksdb_options_t): uint64 {.cdecl.}
proc rocksdb_options_set_WAL_size_limit_MB*(a1: ptr rocksdb_options_t; a2: uint64) {.
    cdecl.}
proc rocksdb_options_get_WAL_size_limit_MB*(a1: ptr rocksdb_options_t): uint64 {.
    cdecl.}
proc rocksdb_options_set_manifest_preallocation_size*(a1: ptr rocksdb_options_t;
    a2: csize_t) {.cdecl.}
proc rocksdb_options_get_manifest_preallocation_size*(a1: ptr rocksdb_options_t): csize_t {.
    cdecl.}
proc rocksdb_options_set_allow_mmap_reads*(a1: ptr rocksdb_options_t; a2: uint8) {.
    cdecl.}
proc rocksdb_options_get_allow_mmap_reads*(a1: ptr rocksdb_options_t): uint8 {.cdecl.}
proc rocksdb_options_set_allow_mmap_writes*(a1: ptr rocksdb_options_t; a2: uint8) {.
    cdecl.}
proc rocksdb_options_get_allow_mmap_writes*(a1: ptr rocksdb_options_t): uint8 {.cdecl.}
proc rocksdb_options_set_use_direct_reads*(a1: ptr rocksdb_options_t; a2: uint8) {.
    cdecl.}
proc rocksdb_options_get_use_direct_reads*(a1: ptr rocksdb_options_t): uint8 {.cdecl.}
proc rocksdb_options_set_use_direct_io_for_flush_and_compaction*(
    a1: ptr rocksdb_options_t; a2: uint8) {.cdecl.}
proc rocksdb_options_get_use_direct_io_for_flush_and_compaction*(
    a1: ptr rocksdb_options_t): uint8 {.cdecl.}
proc rocksdb_options_set_is_fd_close_on_exec*(a1: ptr rocksdb_options_t; a2: uint8) {.
    cdecl.}
proc rocksdb_options_get_is_fd_close_on_exec*(a1: ptr rocksdb_options_t): uint8 {.
    cdecl.}
proc rocksdb_options_set_stats_dump_period_sec*(a1: ptr rocksdb_options_t; a2: cuint) {.
    cdecl.}
proc rocksdb_options_get_stats_dump_period_sec*(a1: ptr rocksdb_options_t): cuint {.
    cdecl.}
proc rocksdb_options_set_stats_persist_period_sec*(a1: ptr rocksdb_options_t;
    a2: cuint) {.cdecl.}
proc rocksdb_options_get_stats_persist_period_sec*(a1: ptr rocksdb_options_t): cuint {.
    cdecl.}
proc rocksdb_options_set_advise_random_on_open*(a1: ptr rocksdb_options_t; a2: uint8) {.
    cdecl.}
proc rocksdb_options_get_advise_random_on_open*(a1: ptr rocksdb_options_t): uint8 {.
    cdecl.}
proc rocksdb_options_set_use_adaptive_mutex*(a1: ptr rocksdb_options_t; a2: uint8) {.
    cdecl.}
proc rocksdb_options_get_use_adaptive_mutex*(a1: ptr rocksdb_options_t): uint8 {.
    cdecl.}
proc rocksdb_options_set_bytes_per_sync*(a1: ptr rocksdb_options_t; a2: uint64) {.
    cdecl.}
proc rocksdb_options_get_bytes_per_sync*(a1: ptr rocksdb_options_t): uint64 {.cdecl.}
proc rocksdb_options_set_wal_bytes_per_sync*(a1: ptr rocksdb_options_t; a2: uint64) {.
    cdecl.}
proc rocksdb_options_get_wal_bytes_per_sync*(a1: ptr rocksdb_options_t): uint64 {.
    cdecl.}
proc rocksdb_options_set_writable_file_max_buffer_size*(
    a1: ptr rocksdb_options_t; a2: uint64) {.cdecl.}
proc rocksdb_options_get_writable_file_max_buffer_size*(a1: ptr rocksdb_options_t): uint64 {.
    cdecl.}
proc rocksdb_options_set_allow_concurrent_memtable_write*(
    a1: ptr rocksdb_options_t; a2: uint8) {.cdecl.}
proc rocksdb_options_get_allow_concurrent_memtable_write*(
    a1: ptr rocksdb_options_t): uint8 {.cdecl.}
proc rocksdb_options_set_enable_write_thread_adaptive_yield*(
    a1: ptr rocksdb_options_t; a2: uint8) {.cdecl.}
proc rocksdb_options_get_enable_write_thread_adaptive_yield*(
    a1: ptr rocksdb_options_t): uint8 {.cdecl.}
proc rocksdb_options_set_max_sequential_skip_in_iterations*(
    a1: ptr rocksdb_options_t; a2: uint64) {.cdecl.}
proc rocksdb_options_get_max_sequential_skip_in_iterations*(
    a1: ptr rocksdb_options_t): uint64 {.cdecl.}
proc rocksdb_options_set_disable_auto_compactions*(a1: ptr rocksdb_options_t;
    a2: cint) {.cdecl.}
proc rocksdb_options_get_disable_auto_compactions*(a1: ptr rocksdb_options_t): uint8 {.
    cdecl.}
proc rocksdb_options_set_optimize_filters_for_hits*(a1: ptr rocksdb_options_t;
    a2: cint) {.cdecl.}
proc rocksdb_options_get_optimize_filters_for_hits*(a1: ptr rocksdb_options_t): uint8 {.
    cdecl.}
proc rocksdb_options_set_delete_obsolete_files_period_micros*(
    a1: ptr rocksdb_options_t; a2: uint64) {.cdecl.}
proc rocksdb_options_get_delete_obsolete_files_period_micros*(
    a1: ptr rocksdb_options_t): uint64 {.cdecl.}
proc rocksdb_options_prepare_for_bulk_load*(a1: ptr rocksdb_options_t) {.cdecl.}
proc rocksdb_options_set_memtable_vector_rep*(a1: ptr rocksdb_options_t) {.cdecl.}
proc rocksdb_options_set_memtable_prefix_bloom_size_ratio*(
    a1: ptr rocksdb_options_t; a2: cdouble) {.cdecl.}
proc rocksdb_options_get_memtable_prefix_bloom_size_ratio*(
    a1: ptr rocksdb_options_t): cdouble {.cdecl.}
proc rocksdb_options_set_max_compaction_bytes*(a1: ptr rocksdb_options_t; a2: uint64) {.
    cdecl.}
proc rocksdb_options_get_max_compaction_bytes*(a1: ptr rocksdb_options_t): uint64 {.
    cdecl.}
proc rocksdb_options_set_hash_skip_list_rep*(a1: ptr rocksdb_options_t; a2: csize_t;
    a3: int32; a4: int32) {.cdecl.}
proc rocksdb_options_set_hash_link_list_rep*(a1: ptr rocksdb_options_t; a2: csize_t) {.
    cdecl.}
proc rocksdb_options_set_plain_table_factory*(a1: ptr rocksdb_options_t; a2: uint32;
    a3: cint; a4: cdouble; a5: csize_t; a6: csize_t; a7: char; a8: uint8; a9: uint8) {.cdecl.}
proc rocksdb_options_get_write_dbid_to_manifest*(a1: ptr rocksdb_options_t): uint8 {.
    cdecl.}
proc rocksdb_options_set_write_dbid_to_manifest*(a1: ptr rocksdb_options_t;
    a2: uint8) {.cdecl.}
proc rocksdb_options_get_write_identity_file*(a1: ptr rocksdb_options_t): uint8 {.
    cdecl.}
proc rocksdb_options_set_write_identity_file*(a1: ptr rocksdb_options_t; a2: uint8) {.
    cdecl.}
proc rocksdb_options_get_track_and_verify_wals_in_manifest*(
    a1: ptr rocksdb_options_t): uint8 {.cdecl.}
proc rocksdb_options_set_track_and_verify_wals_in_manifest*(
    a1: ptr rocksdb_options_t; a2: uint8) {.cdecl.}
proc rocksdb_options_set_min_level_to_compress*(opt: ptr rocksdb_options_t;
    level: cint) {.cdecl.}
proc rocksdb_options_set_memtable_huge_page_size*(a1: ptr rocksdb_options_t;
    a2: csize_t) {.cdecl.}
proc rocksdb_options_get_memtable_huge_page_size*(a1: ptr rocksdb_options_t): csize_t {.
    cdecl.}
proc rocksdb_options_set_max_successive_merges*(a1: ptr rocksdb_options_t;
    a2: csize_t) {.cdecl.}
proc rocksdb_options_get_max_successive_merges*(a1: ptr rocksdb_options_t): csize_t {.
    cdecl.}
proc rocksdb_options_set_bloom_locality*(a1: ptr rocksdb_options_t; a2: uint32) {.
    cdecl.}
proc rocksdb_options_get_bloom_locality*(a1: ptr rocksdb_options_t): uint32 {.cdecl.}
proc rocksdb_options_set_inplace_update_support*(a1: ptr rocksdb_options_t;
    a2: uint8) {.cdecl.}
proc rocksdb_options_get_inplace_update_support*(a1: ptr rocksdb_options_t): uint8 {.
    cdecl.}
proc rocksdb_options_set_inplace_update_num_locks*(a1: ptr rocksdb_options_t;
    a2: csize_t) {.cdecl.}
proc rocksdb_options_get_inplace_update_num_locks*(a1: ptr rocksdb_options_t): csize_t {.
    cdecl.}
proc rocksdb_options_set_report_bg_io_stats*(a1: ptr rocksdb_options_t; a2: cint) {.
    cdecl.}
proc rocksdb_options_get_report_bg_io_stats*(a1: ptr rocksdb_options_t): uint8 {.
    cdecl.}
proc rocksdb_options_set_avoid_unnecessary_blocking_io*(
    a1: ptr rocksdb_options_t; a2: uint8) {.cdecl.}
proc rocksdb_options_get_avoid_unnecessary_blocking_io*(a1: ptr rocksdb_options_t): uint8 {.
    cdecl.}
proc rocksdb_options_set_experimental_mempurge_threshold*(
    a1: ptr rocksdb_options_t; a2: cdouble) {.cdecl.}
proc rocksdb_options_get_experimental_mempurge_threshold*(
    a1: ptr rocksdb_options_t): cdouble {.cdecl.}
const
  rocksdb_tolerate_corrupted_tail_records_recovery* = 0
  rocksdb_absolute_consistency_recovery* = 1
  rocksdb_point_in_time_recovery* = 2
  rocksdb_skip_any_corrupted_records_recovery* = 3

proc rocksdb_options_set_wal_recovery_mode*(a1: ptr rocksdb_options_t; a2: cint) {.
    cdecl.}
proc rocksdb_options_get_wal_recovery_mode*(a1: ptr rocksdb_options_t): cint {.cdecl.}
const
  rocksdb_no_compression* = 0
  rocksdb_snappy_compression* = 1
  rocksdb_zlib_compression* = 2
  rocksdb_bz2_compression* = 3
  rocksdb_lz4_compression* = 4
  rocksdb_lz4hc_compression* = 5
  rocksdb_xpress_compression* = 6
  rocksdb_zstd_compression* = 7

proc rocksdb_options_set_compression*(a1: ptr rocksdb_options_t; a2: cint) {.cdecl.}
proc rocksdb_options_get_compression*(a1: ptr rocksdb_options_t): cint {.cdecl.}
proc rocksdb_options_set_bottommost_compression*(a1: ptr rocksdb_options_t; a2: cint) {.
    cdecl.}
proc rocksdb_options_get_bottommost_compression*(a1: ptr rocksdb_options_t): cint {.
    cdecl.}
const
  rocksdb_level_compaction* = 0
  rocksdb_universal_compaction* = 1
  rocksdb_fifo_compaction* = 2

proc rocksdb_options_set_compaction_style*(a1: ptr rocksdb_options_t; a2: cint) {.
    cdecl.}
proc rocksdb_options_get_compaction_style*(a1: ptr rocksdb_options_t): cint {.cdecl.}
proc rocksdb_options_set_universal_compaction_options*(a1: ptr rocksdb_options_t;
    a2: ptr rocksdb_universal_compaction_options_t) {.cdecl.}
proc rocksdb_options_set_fifo_compaction_options*(opt: ptr rocksdb_options_t;
    fifo: ptr rocksdb_fifo_compaction_options_t) {.cdecl.}
proc rocksdb_options_set_ratelimiter*(opt: ptr rocksdb_options_t;
                                     limiter: ptr rocksdb_ratelimiter_t) {.cdecl.}
proc rocksdb_options_set_atomic_flush*(opt: ptr rocksdb_options_t; a2: uint8) {.cdecl.}
proc rocksdb_options_get_atomic_flush*(opt: ptr rocksdb_options_t): uint8 {.cdecl.}
proc rocksdb_options_set_row_cache*(opt: ptr rocksdb_options_t;
                                   cache: ptr rocksdb_cache_t) {.cdecl.}
proc rocksdb_options_add_compact_on_deletion_collector_factory*(
    a1: ptr rocksdb_options_t; window_size: csize_t; num_dels_trigger: csize_t) {.cdecl.}
proc rocksdb_options_add_compact_on_deletion_collector_factory_del_ratio*(
    a1: ptr rocksdb_options_t; window_size: csize_t; num_dels_trigger: csize_t;
    deletion_ratio: cdouble) {.cdecl.}
proc rocksdb_options_set_manual_wal_flush*(opt: ptr rocksdb_options_t; a2: uint8) {.
    cdecl.}
proc rocksdb_options_get_manual_wal_flush*(opt: ptr rocksdb_options_t): uint8 {.cdecl.}
proc rocksdb_options_set_wal_compression*(opt: ptr rocksdb_options_t; a2: cint) {.
    cdecl.}
proc rocksdb_options_get_wal_compression*(opt: ptr rocksdb_options_t): cint {.cdecl.}
const
  rocksdb_k_by_compensated_size_compaction_pri* = 0
  rocksdb_k_oldest_largest_seq_first_compaction_pri* = 1
  rocksdb_k_oldest_smallest_seq_first_compaction_pri* = 2
  rocksdb_k_min_overlapping_ratio_compaction_pri* = 3
  rocksdb_k_round_robin_compaction_pri* = 4

proc rocksdb_options_set_compaction_pri*(a1: ptr rocksdb_options_t; a2: cint) {.cdecl.}
proc rocksdb_options_get_compaction_pri*(a1: ptr rocksdb_options_t): cint {.cdecl.}
##  RateLimiter

proc rocksdb_ratelimiter_create*(rate_bytes_per_sec: int64;
                                refill_period_us: int64; fairness: int32): ptr rocksdb_ratelimiter_t {.
    cdecl.}
proc rocksdb_ratelimiter_create_auto_tuned*(rate_bytes_per_sec: int64;
    refill_period_us: int64; fairness: int32): ptr rocksdb_ratelimiter_t {.cdecl.}
proc rocksdb_ratelimiter_create_with_mode*(rate_bytes_per_sec: int64;
    refill_period_us: int64; fairness: int32; mode: cint; auto_tuned: bool): ptr rocksdb_ratelimiter_t {.
    cdecl.}
proc rocksdb_ratelimiter_destroy*(a1: ptr rocksdb_ratelimiter_t) {.cdecl.}
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
  rocksdb_number_async_seek* = 68
  rocksdb_blob_cache_hit_count* = 69
  rocksdb_blob_read_count* = 70
  rocksdb_blob_read_byte* = 71
  rocksdb_blob_read_time* = 72
  rocksdb_blob_checksum_time* = 73
  rocksdb_blob_decompress_time* = 74
  rocksdb_internal_range_del_reseek_count* = 75
  rocksdb_block_read_cpu_time* = 76
  rocksdb_total_metric_count* = 79

proc rocksdb_set_perf_level*(a1: cint) {.cdecl.}
proc rocksdb_perfcontext_create*(): ptr rocksdb_perfcontext_t {.cdecl.}
proc rocksdb_perfcontext_reset*(context: ptr rocksdb_perfcontext_t) {.cdecl.}
proc rocksdb_perfcontext_report*(context: ptr rocksdb_perfcontext_t;
                                exclude_zero_counters: uint8): cstring {.cdecl.}
proc rocksdb_perfcontext_metric*(context: ptr rocksdb_perfcontext_t; metric: cint): uint64 {.
    cdecl.}
proc rocksdb_perfcontext_destroy*(context: ptr rocksdb_perfcontext_t) {.cdecl.}
##  Compaction Filter

proc rocksdb_compactionfilter_create*(state: pointer;
                                     destructor: proc (a1: pointer) {.cdecl.}; filter: proc (
    a1: pointer; level: cint; key: cstring; key_length: csize_t;
    existing_value: cstring; value_length: csize_t; new_value: cstringArray;
    new_value_length: ptr csize_t; value_changed: ptr uint8): uint8 {.cdecl.};
                                     name: proc (a1: pointer): cstring {.cdecl.}): ptr rocksdb_compactionfilter_t {.
    cdecl.}
proc rocksdb_compactionfilter_set_ignore_snapshots*(
    a1: ptr rocksdb_compactionfilter_t; a2: uint8) {.cdecl.}
proc rocksdb_compactionfilter_destroy*(a1: ptr rocksdb_compactionfilter_t) {.cdecl.}
##  Compaction Filter Context

proc rocksdb_compactionfiltercontext_is_full_compaction*(
    context: ptr rocksdb_compactionfiltercontext_t): uint8 {.cdecl.}
proc rocksdb_compactionfiltercontext_is_manual_compaction*(
    context: ptr rocksdb_compactionfiltercontext_t): uint8 {.cdecl.}
##  Compaction Filter Factory

proc rocksdb_compactionfilterfactory_create*(state: pointer;
    destructor: proc (a1: pointer) {.cdecl.}; create_compaction_filter: proc (
    a1: pointer; context: ptr rocksdb_compactionfiltercontext_t): ptr rocksdb_compactionfilter_t {.
    cdecl.}; name: proc (a1: pointer): cstring {.cdecl.}): ptr rocksdb_compactionfilterfactory_t {.
    cdecl.}
proc rocksdb_compactionfilterfactory_destroy*(
    a1: ptr rocksdb_compactionfilterfactory_t) {.cdecl.}
##  Comparator

proc rocksdb_comparator_create*(state: pointer;
                               destructor: proc (a1: pointer) {.cdecl.}; compare: proc (
    a1: pointer; a: cstring; alen: csize_t; b: cstring; blen: csize_t): cint {.cdecl.};
                               name: proc (a1: pointer): cstring {.cdecl.}): ptr rocksdb_comparator_t {.
    cdecl.}
proc rocksdb_comparator_destroy*(a1: ptr rocksdb_comparator_t) {.cdecl.}
proc rocksdb_comparator_with_ts_create*(state: pointer;
                                       destructor: proc (a1: pointer) {.cdecl.};
    compare: proc (a1: pointer; a: cstring; alen: csize_t; b: cstring; blen: csize_t): cint {.
    cdecl.}; compare_ts: proc (a1: pointer; a_ts: cstring; a_tslen: csize_t;
                            b_ts: cstring; b_tslen: csize_t): cint {.cdecl.};
    compare_without_ts: proc (a1: pointer; a: cstring; alen: csize_t; a_has_ts: uint8;
                            b: cstring; blen: csize_t; b_has_ts: uint8): cint {.cdecl.};
    name: proc (a1: pointer): cstring {.cdecl.}; timestamp_size: csize_t): ptr rocksdb_comparator_t {.
    cdecl.}
##  Filter policy

proc rocksdb_filterpolicy_destroy*(a1: ptr rocksdb_filterpolicy_t) {.cdecl.}
proc rocksdb_filterpolicy_create_bloom*(bits_per_key: cdouble): ptr rocksdb_filterpolicy_t {.
    cdecl.}
proc rocksdb_filterpolicy_create_bloom_full*(bits_per_key: cdouble): ptr rocksdb_filterpolicy_t {.
    cdecl.}
proc rocksdb_filterpolicy_create_ribbon*(bloom_equivalent_bits_per_key: cdouble): ptr rocksdb_filterpolicy_t {.
    cdecl.}
proc rocksdb_filterpolicy_create_ribbon_hybrid*(
    bloom_equivalent_bits_per_key: cdouble; bloom_before_level: cint): ptr rocksdb_filterpolicy_t {.
    cdecl.}
##  Merge Operator

proc rocksdb_mergeoperator_create*(state: pointer;
                                  destructor: proc (a1: pointer) {.cdecl.};
    full_merge: proc (a1: pointer; key: cstring; key_length: csize_t;
                    existing_value: cstring; existing_value_length: csize_t;
                    operands_list: cstringArray;
                    operands_list_length: ptr csize_t; num_operands: cint;
                    success: ptr uint8; new_value_length: ptr csize_t): cstring {.cdecl.};
    partial_merge: proc (a1: pointer; key: cstring; key_length: csize_t;
                       operands_list: cstringArray;
                       operands_list_length: ptr csize_t; num_operands: cint;
                       success: ptr uint8; new_value_length: ptr csize_t): cstring {.
    cdecl.}; delete_value: proc (a1: pointer; value: cstring; value_length: csize_t) {.
    cdecl.}; name: proc (a1: pointer): cstring {.cdecl.}): ptr rocksdb_mergeoperator_t {.
    cdecl.}
proc rocksdb_mergeoperator_destroy*(a1: ptr rocksdb_mergeoperator_t) {.cdecl.}
##  Read options

proc rocksdb_readoptions_create*(): ptr rocksdb_readoptions_t {.cdecl.}
proc rocksdb_readoptions_destroy*(a1: ptr rocksdb_readoptions_t) {.cdecl.}
proc rocksdb_readoptions_set_verify_checksums*(a1: ptr rocksdb_readoptions_t;
    a2: uint8) {.cdecl.}
proc rocksdb_readoptions_get_verify_checksums*(a1: ptr rocksdb_readoptions_t): uint8 {.
    cdecl.}
proc rocksdb_readoptions_set_fill_cache*(a1: ptr rocksdb_readoptions_t; a2: uint8) {.
    cdecl.}
proc rocksdb_readoptions_get_fill_cache*(a1: ptr rocksdb_readoptions_t): uint8 {.
    cdecl.}
proc rocksdb_readoptions_set_snapshot*(a1: ptr rocksdb_readoptions_t;
                                      a2: ptr rocksdb_snapshot_t) {.cdecl.}
proc rocksdb_readoptions_set_iterate_upper_bound*(a1: ptr rocksdb_readoptions_t;
    key: cstring; keylen: csize_t) {.cdecl.}
proc rocksdb_readoptions_set_iterate_lower_bound*(a1: ptr rocksdb_readoptions_t;
    key: cstring; keylen: csize_t) {.cdecl.}
proc rocksdb_readoptions_set_read_tier*(a1: ptr rocksdb_readoptions_t; a2: cint) {.
    cdecl.}
proc rocksdb_readoptions_get_read_tier*(a1: ptr rocksdb_readoptions_t): cint {.cdecl.}
proc rocksdb_readoptions_set_tailing*(a1: ptr rocksdb_readoptions_t; a2: uint8) {.
    cdecl.}
proc rocksdb_readoptions_get_tailing*(a1: ptr rocksdb_readoptions_t): uint8 {.cdecl.}
##  The functionality that this option controlled has been removed.

proc rocksdb_readoptions_set_managed*(a1: ptr rocksdb_readoptions_t; a2: uint8) {.
    cdecl.}
proc rocksdb_readoptions_set_readahead_size*(a1: ptr rocksdb_readoptions_t;
    a2: csize_t) {.cdecl.}
proc rocksdb_readoptions_get_readahead_size*(a1: ptr rocksdb_readoptions_t): csize_t {.
    cdecl.}
proc rocksdb_readoptions_set_prefix_same_as_start*(a1: ptr rocksdb_readoptions_t;
    a2: uint8) {.cdecl.}
proc rocksdb_readoptions_get_prefix_same_as_start*(a1: ptr rocksdb_readoptions_t): uint8 {.
    cdecl.}
proc rocksdb_readoptions_set_pin_data*(a1: ptr rocksdb_readoptions_t; a2: uint8) {.
    cdecl.}
proc rocksdb_readoptions_get_pin_data*(a1: ptr rocksdb_readoptions_t): uint8 {.cdecl.}
proc rocksdb_readoptions_set_total_order_seek*(a1: ptr rocksdb_readoptions_t;
    a2: uint8) {.cdecl.}
proc rocksdb_readoptions_get_total_order_seek*(a1: ptr rocksdb_readoptions_t): uint8 {.
    cdecl.}
proc rocksdb_readoptions_set_max_skippable_internal_keys*(
    a1: ptr rocksdb_readoptions_t; a2: uint64) {.cdecl.}
proc rocksdb_readoptions_get_max_skippable_internal_keys*(
    a1: ptr rocksdb_readoptions_t): uint64 {.cdecl.}
proc rocksdb_readoptions_set_background_purge_on_iterator_cleanup*(
    a1: ptr rocksdb_readoptions_t; a2: uint8) {.cdecl.}
proc rocksdb_readoptions_get_background_purge_on_iterator_cleanup*(
    a1: ptr rocksdb_readoptions_t): uint8 {.cdecl.}
proc rocksdb_readoptions_set_ignore_range_deletions*(
    a1: ptr rocksdb_readoptions_t; a2: uint8) {.cdecl.}
proc rocksdb_readoptions_get_ignore_range_deletions*(
    a1: ptr rocksdb_readoptions_t): uint8 {.cdecl.}
proc rocksdb_readoptions_set_deadline*(a1: ptr rocksdb_readoptions_t;
                                      microseconds: uint64) {.cdecl.}
proc rocksdb_readoptions_get_deadline*(a1: ptr rocksdb_readoptions_t): uint64 {.cdecl.}
proc rocksdb_readoptions_set_io_timeout*(a1: ptr rocksdb_readoptions_t;
                                        microseconds: uint64) {.cdecl.}
proc rocksdb_readoptions_get_io_timeout*(a1: ptr rocksdb_readoptions_t): uint64 {.
    cdecl.}
proc rocksdb_readoptions_set_async_io*(a1: ptr rocksdb_readoptions_t; a2: uint8) {.
    cdecl.}
proc rocksdb_readoptions_get_async_io*(a1: ptr rocksdb_readoptions_t): uint8 {.cdecl.}
proc rocksdb_readoptions_set_timestamp*(a1: ptr rocksdb_readoptions_t; ts: cstring;
                                       tslen: csize_t) {.cdecl.}
proc rocksdb_readoptions_set_iter_start_ts*(a1: ptr rocksdb_readoptions_t;
    ts: cstring; tslen: csize_t) {.cdecl.}
proc rocksdb_readoptions_set_auto_readahead_size*(a1: ptr rocksdb_readoptions_t;
    a2: uint8) {.cdecl.}
##  Write options

proc rocksdb_writeoptions_create*(): ptr rocksdb_writeoptions_t {.cdecl.}
proc rocksdb_writeoptions_destroy*(a1: ptr rocksdb_writeoptions_t) {.cdecl.}
proc rocksdb_writeoptions_set_sync*(a1: ptr rocksdb_writeoptions_t; a2: uint8) {.cdecl.}
proc rocksdb_writeoptions_get_sync*(a1: ptr rocksdb_writeoptions_t): uint8 {.cdecl.}
proc rocksdb_writeoptions_disable_WAL*(opt: ptr rocksdb_writeoptions_t;
                                      disable: cint) {.cdecl.}
proc rocksdb_writeoptions_get_disable_WAL*(opt: ptr rocksdb_writeoptions_t): uint8 {.
    cdecl.}
proc rocksdb_writeoptions_set_ignore_missing_column_families*(
    a1: ptr rocksdb_writeoptions_t; a2: uint8) {.cdecl.}
proc rocksdb_writeoptions_get_ignore_missing_column_families*(
    a1: ptr rocksdb_writeoptions_t): uint8 {.cdecl.}
proc rocksdb_writeoptions_set_no_slowdown*(a1: ptr rocksdb_writeoptions_t; a2: uint8) {.
    cdecl.}
proc rocksdb_writeoptions_get_no_slowdown*(a1: ptr rocksdb_writeoptions_t): uint8 {.
    cdecl.}
proc rocksdb_writeoptions_set_low_pri*(a1: ptr rocksdb_writeoptions_t; a2: uint8) {.
    cdecl.}
proc rocksdb_writeoptions_get_low_pri*(a1: ptr rocksdb_writeoptions_t): uint8 {.cdecl.}
proc rocksdb_writeoptions_set_memtable_insert_hint_per_batch*(
    a1: ptr rocksdb_writeoptions_t; a2: uint8) {.cdecl.}
proc rocksdb_writeoptions_get_memtable_insert_hint_per_batch*(
    a1: ptr rocksdb_writeoptions_t): uint8 {.cdecl.}
##  Compact range options

proc rocksdb_compactoptions_create*(): ptr rocksdb_compactoptions_t {.cdecl.}
proc rocksdb_compactoptions_destroy*(a1: ptr rocksdb_compactoptions_t) {.cdecl.}
proc rocksdb_compactoptions_set_exclusive_manual_compaction*(
    a1: ptr rocksdb_compactoptions_t; a2: uint8) {.cdecl.}
proc rocksdb_compactoptions_get_exclusive_manual_compaction*(
    a1: ptr rocksdb_compactoptions_t): uint8 {.cdecl.}
proc rocksdb_compactoptions_set_bottommost_level_compaction*(
    a1: ptr rocksdb_compactoptions_t; a2: uint8) {.cdecl.}
proc rocksdb_compactoptions_get_bottommost_level_compaction*(
    a1: ptr rocksdb_compactoptions_t): uint8 {.cdecl.}
proc rocksdb_compactoptions_set_change_level*(a1: ptr rocksdb_compactoptions_t;
    a2: uint8) {.cdecl.}
proc rocksdb_compactoptions_get_change_level*(a1: ptr rocksdb_compactoptions_t): uint8 {.
    cdecl.}
proc rocksdb_compactoptions_set_target_level*(a1: ptr rocksdb_compactoptions_t;
    a2: cint) {.cdecl.}
proc rocksdb_compactoptions_get_target_level*(a1: ptr rocksdb_compactoptions_t): cint {.
    cdecl.}
proc rocksdb_compactoptions_set_full_history_ts_low*(
    a1: ptr rocksdb_compactoptions_t; ts: cstring; tslen: csize_t) {.cdecl.}
##  Flush options

proc rocksdb_flushoptions_create*(): ptr rocksdb_flushoptions_t {.cdecl.}
proc rocksdb_flushoptions_destroy*(a1: ptr rocksdb_flushoptions_t) {.cdecl.}
proc rocksdb_flushoptions_set_wait*(a1: ptr rocksdb_flushoptions_t; a2: uint8) {.cdecl.}
proc rocksdb_flushoptions_get_wait*(a1: ptr rocksdb_flushoptions_t): uint8 {.cdecl.}
##  Memory allocator

proc rocksdb_jemalloc_nodump_allocator_create*(errptr: cstringArray): ptr rocksdb_memory_allocator_t {.
    cdecl.}
proc rocksdb_memory_allocator_destroy*(a1: ptr rocksdb_memory_allocator_t) {.cdecl.}
##  Cache

proc rocksdb_lru_cache_options_create*(): ptr rocksdb_lru_cache_options_t {.cdecl.}
proc rocksdb_lru_cache_options_destroy*(a1: ptr rocksdb_lru_cache_options_t) {.cdecl.}
proc rocksdb_lru_cache_options_set_capacity*(a1: ptr rocksdb_lru_cache_options_t;
    a2: csize_t) {.cdecl.}
proc rocksdb_lru_cache_options_set_num_shard_bits*(
    a1: ptr rocksdb_lru_cache_options_t; a2: cint) {.cdecl.}
proc rocksdb_lru_cache_options_set_memory_allocator*(
    a1: ptr rocksdb_lru_cache_options_t; a2: ptr rocksdb_memory_allocator_t) {.cdecl.}
proc rocksdb_cache_create_lru*(capacity: csize_t): ptr rocksdb_cache_t {.cdecl.}
proc rocksdb_cache_create_lru_with_strict_capacity_limit*(capacity: csize_t): ptr rocksdb_cache_t {.
    cdecl.}
proc rocksdb_cache_create_lru_opts*(a1: ptr rocksdb_lru_cache_options_t): ptr rocksdb_cache_t {.
    cdecl.}
proc rocksdb_cache_destroy*(cache: ptr rocksdb_cache_t) {.cdecl.}
proc rocksdb_cache_disown_data*(cache: ptr rocksdb_cache_t) {.cdecl.}
proc rocksdb_cache_set_capacity*(cache: ptr rocksdb_cache_t; capacity: csize_t) {.
    cdecl.}
proc rocksdb_cache_get_capacity*(cache: ptr rocksdb_cache_t): csize_t {.cdecl.}
proc rocksdb_cache_get_usage*(cache: ptr rocksdb_cache_t): csize_t {.cdecl.}
proc rocksdb_cache_get_pinned_usage*(cache: ptr rocksdb_cache_t): csize_t {.cdecl.}
proc rocksdb_cache_get_table_address_count*(cache: ptr rocksdb_cache_t): csize_t {.
    cdecl.}
proc rocksdb_cache_get_occupancy_count*(cache: ptr rocksdb_cache_t): csize_t {.cdecl.}
##  WriteBufferManager

proc rocksdb_write_buffer_manager_create*(buffer_size: csize_t; allow_stall: bool): ptr rocksdb_write_buffer_manager_t {.
    cdecl.}
proc rocksdb_write_buffer_manager_create_with_cache*(buffer_size: csize_t;
    cache: ptr rocksdb_cache_t; allow_stall: bool): ptr rocksdb_write_buffer_manager_t {.
    cdecl.}
proc rocksdb_write_buffer_manager_destroy*(
    wbm: ptr rocksdb_write_buffer_manager_t) {.cdecl.}
proc rocksdb_write_buffer_manager_enabled*(
    wbm: ptr rocksdb_write_buffer_manager_t): bool {.cdecl.}
proc rocksdb_write_buffer_manager_cost_to_cache*(
    wbm: ptr rocksdb_write_buffer_manager_t): bool {.cdecl.}
proc rocksdb_write_buffer_manager_memory_usage*(
    wbm: ptr rocksdb_write_buffer_manager_t): csize_t {.cdecl.}
proc rocksdb_write_buffer_manager_mutable_memtable_memory_usage*(
    wbm: ptr rocksdb_write_buffer_manager_t): csize_t {.cdecl.}
proc rocksdb_write_buffer_manager_dummy_entries_in_cache_usage*(
    wbm: ptr rocksdb_write_buffer_manager_t): csize_t {.cdecl.}
proc rocksdb_write_buffer_manager_buffer_size*(
    wbm: ptr rocksdb_write_buffer_manager_t): csize_t {.cdecl.}
proc rocksdb_write_buffer_manager_set_buffer_size*(
    wbm: ptr rocksdb_write_buffer_manager_t; new_size: csize_t) {.cdecl.}
proc rocksdb_write_buffer_manager_set_allow_stall*(
    wbm: ptr rocksdb_write_buffer_manager_t; new_allow_stall: bool) {.cdecl.}
##  HyperClockCache

proc rocksdb_hyper_clock_cache_options_create*(capacity: csize_t;
    estimated_entry_charge: csize_t): ptr rocksdb_hyper_clock_cache_options_t {.
    cdecl.}
proc rocksdb_hyper_clock_cache_options_destroy*(
    a1: ptr rocksdb_hyper_clock_cache_options_t) {.cdecl.}
proc rocksdb_hyper_clock_cache_options_set_capacity*(
    a1: ptr rocksdb_hyper_clock_cache_options_t; a2: csize_t) {.cdecl.}
proc rocksdb_hyper_clock_cache_options_set_estimated_entry_charge*(
    a1: ptr rocksdb_hyper_clock_cache_options_t; a2: csize_t) {.cdecl.}
proc rocksdb_hyper_clock_cache_options_set_num_shard_bits*(
    a1: ptr rocksdb_hyper_clock_cache_options_t; a2: cint) {.cdecl.}
proc rocksdb_hyper_clock_cache_options_set_memory_allocator*(
    a1: ptr rocksdb_hyper_clock_cache_options_t; a2: ptr rocksdb_memory_allocator_t) {.
    cdecl.}
proc rocksdb_cache_create_hyper_clock*(capacity: csize_t;
                                      estimated_entry_charge: csize_t): ptr rocksdb_cache_t {.
    cdecl.}
proc rocksdb_cache_create_hyper_clock_opts*(
    a1: ptr rocksdb_hyper_clock_cache_options_t): ptr rocksdb_cache_t {.cdecl.}
##  DBPath

proc rocksdb_dbpath_create*(path: cstring; target_size: uint64): ptr rocksdb_dbpath_t {.
    cdecl.}
proc rocksdb_dbpath_destroy*(a1: ptr rocksdb_dbpath_t) {.cdecl.}
##  Env

proc rocksdb_create_default_env*(): ptr rocksdb_env_t {.cdecl.}
proc rocksdb_create_mem_env*(): ptr rocksdb_env_t {.cdecl.}
proc rocksdb_env_set_background_threads*(env: ptr rocksdb_env_t; n: cint) {.cdecl.}
proc rocksdb_env_get_background_threads*(env: ptr rocksdb_env_t): cint {.cdecl.}
proc rocksdb_env_set_high_priority_background_threads*(env: ptr rocksdb_env_t;
    n: cint) {.cdecl.}
proc rocksdb_env_get_high_priority_background_threads*(env: ptr rocksdb_env_t): cint {.
    cdecl.}
proc rocksdb_env_set_low_priority_background_threads*(env: ptr rocksdb_env_t;
    n: cint) {.cdecl.}
proc rocksdb_env_get_low_priority_background_threads*(env: ptr rocksdb_env_t): cint {.
    cdecl.}
proc rocksdb_env_set_bottom_priority_background_threads*(env: ptr rocksdb_env_t;
    n: cint) {.cdecl.}
proc rocksdb_env_get_bottom_priority_background_threads*(env: ptr rocksdb_env_t): cint {.
    cdecl.}
proc rocksdb_env_join_all_threads*(env: ptr rocksdb_env_t) {.cdecl.}
proc rocksdb_env_lower_thread_pool_io_priority*(env: ptr rocksdb_env_t) {.cdecl.}
proc rocksdb_env_lower_high_priority_thread_pool_io_priority*(
    env: ptr rocksdb_env_t) {.cdecl.}
proc rocksdb_env_lower_thread_pool_cpu_priority*(env: ptr rocksdb_env_t) {.cdecl.}
proc rocksdb_env_lower_high_priority_thread_pool_cpu_priority*(
    env: ptr rocksdb_env_t) {.cdecl.}
proc rocksdb_env_destroy*(a1: ptr rocksdb_env_t) {.cdecl.}
proc rocksdb_envoptions_create*(): ptr rocksdb_envoptions_t {.cdecl.}
proc rocksdb_envoptions_destroy*(opt: ptr rocksdb_envoptions_t) {.cdecl.}
proc rocksdb_create_dir_if_missing*(env: ptr rocksdb_env_t; path: cstring;
                                   errptr: cstringArray) {.cdecl.}
##  SstFile

proc rocksdb_sstfilewriter_create*(env: ptr rocksdb_envoptions_t;
                                  io_options: ptr rocksdb_options_t): ptr rocksdb_sstfilewriter_t {.
    cdecl.}
proc rocksdb_sstfilewriter_create_with_comparator*(env: ptr rocksdb_envoptions_t;
    io_options: ptr rocksdb_options_t; comparator: ptr rocksdb_comparator_t): ptr rocksdb_sstfilewriter_t {.
    cdecl.}
proc rocksdb_sstfilewriter_open*(writer: ptr rocksdb_sstfilewriter_t; name: cstring;
                                errptr: cstringArray) {.cdecl.}
proc rocksdb_sstfilewriter_add*(writer: ptr rocksdb_sstfilewriter_t; key: cstring;
                               keylen: csize_t; val: cstring; vallen: csize_t;
                               errptr: cstringArray) {.cdecl.}
proc rocksdb_sstfilewriter_put*(writer: ptr rocksdb_sstfilewriter_t; key: cstring;
                               keylen: csize_t; val: cstring; vallen: csize_t;
                               errptr: cstringArray) {.cdecl.}
proc rocksdb_sstfilewriter_put_with_ts*(writer: ptr rocksdb_sstfilewriter_t;
                                       key: cstring; keylen: csize_t; ts: cstring;
                                       tslen: csize_t; val: cstring;
                                       vallen: csize_t; errptr: cstringArray) {.
    cdecl.}
proc rocksdb_sstfilewriter_merge*(writer: ptr rocksdb_sstfilewriter_t; key: cstring;
                                 keylen: csize_t; val: cstring; vallen: csize_t;
                                 errptr: cstringArray) {.cdecl.}
proc rocksdb_sstfilewriter_delete*(writer: ptr rocksdb_sstfilewriter_t;
                                  key: cstring; keylen: csize_t;
                                  errptr: cstringArray) {.cdecl.}
proc rocksdb_sstfilewriter_delete_with_ts*(writer: ptr rocksdb_sstfilewriter_t;
    key: cstring; keylen: csize_t; ts: cstring; tslen: csize_t; errptr: cstringArray) {.
    cdecl.}
proc rocksdb_sstfilewriter_delete_range*(writer: ptr rocksdb_sstfilewriter_t;
                                        begin_key: cstring; begin_keylen: csize_t;
                                        end_key: cstring; end_keylen: csize_t;
                                        errptr: cstringArray) {.cdecl.}
proc rocksdb_sstfilewriter_finish*(writer: ptr rocksdb_sstfilewriter_t;
                                  errptr: cstringArray) {.cdecl.}
proc rocksdb_sstfilewriter_file_size*(writer: ptr rocksdb_sstfilewriter_t;
                                     file_size: ptr uint64) {.cdecl.}
proc rocksdb_sstfilewriter_destroy*(writer: ptr rocksdb_sstfilewriter_t) {.cdecl.}
proc rocksdb_ingestexternalfileoptions_create*(): ptr rocksdb_ingestexternalfileoptions_t {.
    cdecl.}
proc rocksdb_ingestexternalfileoptions_set_move_files*(
    opt: ptr rocksdb_ingestexternalfileoptions_t; move_files: uint8) {.cdecl.}
proc rocksdb_ingestexternalfileoptions_set_snapshot_consistency*(
    opt: ptr rocksdb_ingestexternalfileoptions_t; snapshot_consistency: uint8) {.
    cdecl.}
proc rocksdb_ingestexternalfileoptions_set_allow_global_seqno*(
    opt: ptr rocksdb_ingestexternalfileoptions_t; allow_global_seqno: uint8) {.cdecl.}
proc rocksdb_ingestexternalfileoptions_set_allow_blocking_flush*(
    opt: ptr rocksdb_ingestexternalfileoptions_t; allow_blocking_flush: uint8) {.
    cdecl.}
proc rocksdb_ingestexternalfileoptions_set_ingest_behind*(
    opt: ptr rocksdb_ingestexternalfileoptions_t; ingest_behind: uint8) {.cdecl.}
proc rocksdb_ingestexternalfileoptions_set_fail_if_not_bottommost_level*(
    opt: ptr rocksdb_ingestexternalfileoptions_t;
    fail_if_not_bottommost_level: uint8) {.cdecl.}
proc rocksdb_ingestexternalfileoptions_destroy*(
    opt: ptr rocksdb_ingestexternalfileoptions_t) {.cdecl.}
proc rocksdb_ingest_external_file*(db: ptr rocksdb_t; file_list: cstringArray;
                                  list_len: csize_t;
                                  opt: ptr rocksdb_ingestexternalfileoptions_t;
                                  errptr: cstringArray) {.cdecl.}
proc rocksdb_ingest_external_file_cf*(db: ptr rocksdb_t; handle: ptr rocksdb_column_family_handle_t;
                                     file_list: cstringArray; list_len: csize_t; opt: ptr rocksdb_ingestexternalfileoptions_t;
                                     errptr: cstringArray) {.cdecl.}
proc rocksdb_try_catch_up_with_primary*(db: ptr rocksdb_t; errptr: cstringArray) {.
    cdecl.}
##  SliceTransform

proc rocksdb_slicetransform_create*(state: pointer;
                                   destructor: proc (a1: pointer) {.cdecl.};
    transform: proc (a1: pointer; key: cstring; length: csize_t; dst_length: ptr csize_t): cstring {.
    cdecl.}; in_domain: proc (a1: pointer; key: cstring; length: csize_t): uint8 {.cdecl.};
    in_range: proc (a1: pointer; key: cstring; length: csize_t): uint8 {.cdecl.};
                                   name: proc (a1: pointer): cstring {.cdecl.}): ptr rocksdb_slicetransform_t {.
    cdecl.}
proc rocksdb_slicetransform_create_fixed_prefix*(a1: csize_t): ptr rocksdb_slicetransform_t {.
    cdecl.}
proc rocksdb_slicetransform_create_noop*(): ptr rocksdb_slicetransform_t {.cdecl.}
proc rocksdb_slicetransform_destroy*(a1: ptr rocksdb_slicetransform_t) {.cdecl.}
##  Universal Compaction options

const
  rocksdb_similar_size_compaction_stop_style* = 0
  rocksdb_total_size_compaction_stop_style* = 1

proc rocksdb_universal_compaction_options_create*(): ptr rocksdb_universal_compaction_options_t {.
    cdecl.}
proc rocksdb_universal_compaction_options_set_size_ratio*(
    a1: ptr rocksdb_universal_compaction_options_t; a2: cint) {.cdecl.}
proc rocksdb_universal_compaction_options_get_size_ratio*(
    a1: ptr rocksdb_universal_compaction_options_t): cint {.cdecl.}
proc rocksdb_universal_compaction_options_set_min_merge_width*(
    a1: ptr rocksdb_universal_compaction_options_t; a2: cint) {.cdecl.}
proc rocksdb_universal_compaction_options_get_min_merge_width*(
    a1: ptr rocksdb_universal_compaction_options_t): cint {.cdecl.}
proc rocksdb_universal_compaction_options_set_max_merge_width*(
    a1: ptr rocksdb_universal_compaction_options_t; a2: cint) {.cdecl.}
proc rocksdb_universal_compaction_options_get_max_merge_width*(
    a1: ptr rocksdb_universal_compaction_options_t): cint {.cdecl.}
proc rocksdb_universal_compaction_options_set_max_size_amplification_percent*(
    a1: ptr rocksdb_universal_compaction_options_t; a2: cint) {.cdecl.}
proc rocksdb_universal_compaction_options_get_max_size_amplification_percent*(
    a1: ptr rocksdb_universal_compaction_options_t): cint {.cdecl.}
proc rocksdb_universal_compaction_options_set_compression_size_percent*(
    a1: ptr rocksdb_universal_compaction_options_t; a2: cint) {.cdecl.}
proc rocksdb_universal_compaction_options_get_compression_size_percent*(
    a1: ptr rocksdb_universal_compaction_options_t): cint {.cdecl.}
proc rocksdb_universal_compaction_options_set_stop_style*(
    a1: ptr rocksdb_universal_compaction_options_t; a2: cint) {.cdecl.}
proc rocksdb_universal_compaction_options_get_stop_style*(
    a1: ptr rocksdb_universal_compaction_options_t): cint {.cdecl.}
proc rocksdb_universal_compaction_options_destroy*(
    a1: ptr rocksdb_universal_compaction_options_t) {.cdecl.}
proc rocksdb_fifo_compaction_options_create*(): ptr rocksdb_fifo_compaction_options_t {.
    cdecl.}
proc rocksdb_fifo_compaction_options_set_allow_compaction*(
    fifo_opts: ptr rocksdb_fifo_compaction_options_t; allow_compaction: uint8) {.
    cdecl.}
proc rocksdb_fifo_compaction_options_get_allow_compaction*(
    fifo_opts: ptr rocksdb_fifo_compaction_options_t): uint8 {.cdecl.}
proc rocksdb_fifo_compaction_options_set_max_table_files_size*(
    fifo_opts: ptr rocksdb_fifo_compaction_options_t; size: uint64) {.cdecl.}
proc rocksdb_fifo_compaction_options_get_max_table_files_size*(
    fifo_opts: ptr rocksdb_fifo_compaction_options_t): uint64 {.cdecl.}
proc rocksdb_fifo_compaction_options_destroy*(
    fifo_opts: ptr rocksdb_fifo_compaction_options_t) {.cdecl.}
proc rocksdb_livefiles_count*(a1: ptr rocksdb_livefiles_t): cint {.cdecl.}
proc rocksdb_livefiles_column_family_name*(a1: ptr rocksdb_livefiles_t; index: cint): cstring {.
    cdecl.}
proc rocksdb_livefiles_name*(a1: ptr rocksdb_livefiles_t; index: cint): cstring {.cdecl.}
proc rocksdb_livefiles_level*(a1: ptr rocksdb_livefiles_t; index: cint): cint {.cdecl.}
proc rocksdb_livefiles_size*(a1: ptr rocksdb_livefiles_t; index: cint): csize_t {.cdecl.}
proc rocksdb_livefiles_smallestkey*(a1: ptr rocksdb_livefiles_t; index: cint;
                                   size: ptr csize_t): cstring {.cdecl.}
proc rocksdb_livefiles_largestkey*(a1: ptr rocksdb_livefiles_t; index: cint;
                                  size: ptr csize_t): cstring {.cdecl.}
proc rocksdb_livefiles_entries*(a1: ptr rocksdb_livefiles_t; index: cint): uint64 {.
    cdecl.}
proc rocksdb_livefiles_deletions*(a1: ptr rocksdb_livefiles_t; index: cint): uint64 {.
    cdecl.}
proc rocksdb_livefiles_destroy*(a1: ptr rocksdb_livefiles_t) {.cdecl.}
##  Utility Helpers

proc rocksdb_get_options_from_string*(base_options: ptr rocksdb_options_t;
                                     opts_str: cstring;
                                     new_options: ptr rocksdb_options_t;
                                     errptr: cstringArray) {.cdecl.}
proc rocksdb_delete_file_in_range*(db: ptr rocksdb_t; start_key: cstring;
                                  start_key_len: csize_t; limit_key: cstring;
                                  limit_key_len: csize_t; errptr: cstringArray) {.
    cdecl.}
proc rocksdb_delete_file_in_range_cf*(db: ptr rocksdb_t; column_family: ptr rocksdb_column_family_handle_t;
                                     start_key: cstring; start_key_len: csize_t;
                                     limit_key: cstring; limit_key_len: csize_t;
                                     errptr: cstringArray) {.cdecl.}
##  MetaData

proc rocksdb_get_column_family_metadata*(db: ptr rocksdb_t): ptr rocksdb_column_family_metadata_t {.
    cdecl.}
##
##  Returns the rocksdb_column_family_metadata_t of the specified
##  column family.
##
##  Note that the caller is responsible to release the returned memory
##  using rocksdb_column_family_metadata_destroy.
##

proc rocksdb_get_column_family_metadata_cf*(db: ptr rocksdb_t;
    column_family: ptr rocksdb_column_family_handle_t): ptr rocksdb_column_family_metadata_t {.
    cdecl.}
proc rocksdb_column_family_metadata_destroy*(
    cf_meta: ptr rocksdb_column_family_metadata_t) {.cdecl.}
proc rocksdb_column_family_metadata_get_size*(
    cf_meta: ptr rocksdb_column_family_metadata_t): uint64 {.cdecl.}
proc rocksdb_column_family_metadata_get_file_count*(
    cf_meta: ptr rocksdb_column_family_metadata_t): csize_t {.cdecl.}
proc rocksdb_column_family_metadata_get_name*(
    cf_meta: ptr rocksdb_column_family_metadata_t): cstring {.cdecl.}
proc rocksdb_column_family_metadata_get_level_count*(
    cf_meta: ptr rocksdb_column_family_metadata_t): csize_t {.cdecl.}
##
##  Returns the rocksdb_level_metadata_t of the ith level from the specified
##  column family metadata.
##
##  If the specified i is greater than or equal to the number of levels
##  in the specified column family, then NULL will be returned.
##
##  Note that the caller is responsible to release the returned memory
##  using rocksdb_level_metadata_destroy before releasing its parent
##  rocksdb_column_family_metadata_t.
##

proc rocksdb_column_family_metadata_get_level_metadata*(
    cf_meta: ptr rocksdb_column_family_metadata_t; i: csize_t): ptr rocksdb_level_metadata_t {.
    cdecl.}
##
##  Releases the specified rocksdb_level_metadata_t.
##
##  Note that the specified rocksdb_level_metadata_t must be released
##  before the release of its parent rocksdb_column_family_metadata_t.
##

proc rocksdb_level_metadata_destroy*(level_meta: ptr rocksdb_level_metadata_t) {.
    cdecl.}
proc rocksdb_level_metadata_get_level*(level_meta: ptr rocksdb_level_metadata_t): cint {.
    cdecl.}
proc rocksdb_level_metadata_get_size*(level_meta: ptr rocksdb_level_metadata_t): uint64 {.
    cdecl.}
proc rocksdb_level_metadata_get_file_count*(
    level_meta: ptr rocksdb_level_metadata_t): csize_t {.cdecl.}
##
##  Returns the sst_file_metadata_t of the ith file from the specified level
##  metadata.
##
##  If the specified i is greater than or equal to the number of files
##  in the specified level, then NULL will be returned.
##
##  Note that the caller is responsible to release the returned memory
##  using rocksdb_sst_file_metadata_destroy before releasing its
##  parent rocksdb_level_metadata_t.
##

proc rocksdb_level_metadata_get_sst_file_metadata*(
    level_meta: ptr rocksdb_level_metadata_t; i: csize_t): ptr rocksdb_sst_file_metadata_t {.
    cdecl.}
##
##  Releases the specified rocksdb_sst_file_metadata_t.
##
##  Note that the specified rocksdb_sst_file_metadata_t must be released
##  before the release of its parent rocksdb_level_metadata_t.
##

proc rocksdb_sst_file_metadata_destroy*(file_meta: ptr rocksdb_sst_file_metadata_t) {.
    cdecl.}
proc rocksdb_sst_file_metadata_get_relative_filename*(
    file_meta: ptr rocksdb_sst_file_metadata_t): cstring {.cdecl.}
proc rocksdb_sst_file_metadata_get_directory*(
    file_meta: ptr rocksdb_sst_file_metadata_t): cstring {.cdecl.}
proc rocksdb_sst_file_metadata_get_size*(file_meta: ptr rocksdb_sst_file_metadata_t): uint64 {.
    cdecl.}
##
##  Returns the smallest key of the specified sst file.
##  The caller is responsible for releasing the returned memory.
##
##  @param file_meta the metadata of an SST file to obtain its smallest key.
##  @param len the out value which will contain the length of the returned key
##      after the function call.
##

proc rocksdb_sst_file_metadata_get_smallestkey*(
    file_meta: ptr rocksdb_sst_file_metadata_t; len: ptr csize_t): cstring {.cdecl.}
##
##  Returns the smallest key of the specified sst file.
##  The caller is responsible for releasing the returned memory.
##
##  @param file_meta the metadata of an SST file to obtain its smallest key.
##  @param len the out value which will contain the length of the returned key
##      after the function call.
##

proc rocksdb_sst_file_metadata_get_largestkey*(
    file_meta: ptr rocksdb_sst_file_metadata_t; len: ptr csize_t): cstring {.cdecl.}
##  Transactions

proc rocksdb_transactiondb_create_column_family*(
    txn_db: ptr rocksdb_transactiondb_t;
    column_family_options: ptr rocksdb_options_t; column_family_name: cstring;
    errptr: cstringArray): ptr rocksdb_column_family_handle_t {.cdecl.}
proc rocksdb_transactiondb_open*(options: ptr rocksdb_options_t; txn_db_options: ptr rocksdb_transactiondb_options_t;
                                name: cstring; errptr: cstringArray): ptr rocksdb_transactiondb_t {.
    cdecl.}
proc rocksdb_transactiondb_open_column_families*(options: ptr rocksdb_options_t;
    txn_db_options: ptr rocksdb_transactiondb_options_t; name: cstring;
    num_column_families: cint; column_family_names: cstringArray;
    column_family_options: ptr ptr rocksdb_options_t;
    column_family_handles: ptr ptr rocksdb_column_family_handle_t;
    errptr: cstringArray): ptr rocksdb_transactiondb_t {.cdecl.}
proc rocksdb_transactiondb_create_snapshot*(txn_db: ptr rocksdb_transactiondb_t): ptr rocksdb_snapshot_t {.
    cdecl.}
proc rocksdb_transactiondb_release_snapshot*(txn_db: ptr rocksdb_transactiondb_t;
    snapshot: ptr rocksdb_snapshot_t) {.cdecl.}
proc rocksdb_transactiondb_property_value*(db: ptr rocksdb_transactiondb_t;
    propname: cstring): cstring {.cdecl.}
proc rocksdb_transactiondb_property_int*(db: ptr rocksdb_transactiondb_t;
                                        propname: cstring; out_val: ptr uint64): cint {.
    cdecl.}
proc rocksdb_transactiondb_get_base_db*(txn_db: ptr rocksdb_transactiondb_t): ptr rocksdb_t {.
    cdecl.}
proc rocksdb_transactiondb_close_base_db*(base_db: ptr rocksdb_t) {.cdecl.}
proc rocksdb_transaction_begin*(txn_db: ptr rocksdb_transactiondb_t;
                               write_options: ptr rocksdb_writeoptions_t;
                               txn_options: ptr rocksdb_transaction_options_t;
                               old_txn: ptr rocksdb_transaction_t): ptr rocksdb_transaction_t {.
    cdecl.}
proc rocksdb_transactiondb_get_prepared_transactions*(
    txn_db: ptr rocksdb_transactiondb_t; cnt: ptr csize_t): ptr ptr rocksdb_transaction_t {.
    cdecl.}
proc rocksdb_transaction_set_name*(txn: ptr rocksdb_transaction_t; name: cstring;
                                  name_len: csize_t; errptr: cstringArray) {.cdecl.}
proc rocksdb_transaction_get_name*(txn: ptr rocksdb_transaction_t;
                                  name_len: ptr csize_t): cstring {.cdecl.}
proc rocksdb_transaction_prepare*(txn: ptr rocksdb_transaction_t;
                                 errptr: cstringArray) {.cdecl.}
proc rocksdb_transaction_commit*(txn: ptr rocksdb_transaction_t;
                                errptr: cstringArray) {.cdecl.}
proc rocksdb_transaction_rollback*(txn: ptr rocksdb_transaction_t;
                                  errptr: cstringArray) {.cdecl.}
proc rocksdb_transaction_set_savepoint*(txn: ptr rocksdb_transaction_t) {.cdecl.}
proc rocksdb_transaction_rollback_to_savepoint*(txn: ptr rocksdb_transaction_t;
    errptr: cstringArray) {.cdecl.}
proc rocksdb_transaction_destroy*(txn: ptr rocksdb_transaction_t) {.cdecl.}
proc rocksdb_transaction_get_writebatch_wi*(txn: ptr rocksdb_transaction_t): ptr rocksdb_writebatch_wi_t {.
    cdecl.}
proc rocksdb_transaction_rebuild_from_writebatch*(txn: ptr rocksdb_transaction_t;
    writebatch: ptr rocksdb_writebatch_t; errptr: cstringArray) {.cdecl.}
##  This rocksdb_writebatch_wi_t should be freed with rocksdb_free

proc rocksdb_transaction_rebuild_from_writebatch_wi*(
    txn: ptr rocksdb_transaction_t; wi: ptr rocksdb_writebatch_wi_t;
    errptr: cstringArray) {.cdecl.}
proc rocksdb_transaction_set_commit_timestamp*(txn: ptr rocksdb_transaction_t;
    commit_timestamp: uint64) {.cdecl.}
proc rocksdb_transaction_set_read_timestamp_for_validation*(
    txn: ptr rocksdb_transaction_t; read_timestamp: uint64) {.cdecl.}
##  This snapshot should be freed using rocksdb_free

proc rocksdb_transaction_get_snapshot*(txn: ptr rocksdb_transaction_t): ptr rocksdb_snapshot_t {.
    cdecl.}
proc rocksdb_transaction_get*(txn: ptr rocksdb_transaction_t;
                             options: ptr rocksdb_readoptions_t; key: cstring;
                             klen: csize_t; vlen: ptr csize_t; errptr: cstringArray): cstring {.
    cdecl.}
proc rocksdb_transaction_get_pinned*(txn: ptr rocksdb_transaction_t;
                                    options: ptr rocksdb_readoptions_t;
                                    key: cstring; klen: csize_t;
                                    errptr: cstringArray): ptr rocksdb_pinnableslice_t {.
    cdecl.}
proc rocksdb_transaction_get_cf*(txn: ptr rocksdb_transaction_t;
                                options: ptr rocksdb_readoptions_t; column_family: ptr rocksdb_column_family_handle_t;
                                key: cstring; klen: csize_t; vlen: ptr csize_t;
                                errptr: cstringArray): cstring {.cdecl.}
proc rocksdb_transaction_get_pinned_cf*(txn: ptr rocksdb_transaction_t;
                                       options: ptr rocksdb_readoptions_t;
    column_family: ptr rocksdb_column_family_handle_t; key: cstring; klen: csize_t;
                                       errptr: cstringArray): ptr rocksdb_pinnableslice_t {.
    cdecl.}
proc rocksdb_transaction_get_for_update*(txn: ptr rocksdb_transaction_t;
                                        options: ptr rocksdb_readoptions_t;
                                        key: cstring; klen: csize_t;
                                        vlen: ptr csize_t; exclusive: uint8;
                                        errptr: cstringArray): cstring {.cdecl.}
proc rocksdb_transaction_get_pinned_for_update*(txn: ptr rocksdb_transaction_t;
    options: ptr rocksdb_readoptions_t; key: cstring; klen: csize_t; exclusive: uint8;
    errptr: cstringArray): ptr rocksdb_pinnableslice_t {.cdecl.}
proc rocksdb_transaction_get_for_update_cf*(txn: ptr rocksdb_transaction_t;
    options: ptr rocksdb_readoptions_t;
    column_family: ptr rocksdb_column_family_handle_t; key: cstring; klen: csize_t;
    vlen: ptr csize_t; exclusive: uint8; errptr: cstringArray): cstring {.cdecl.}
proc rocksdb_transaction_get_pinned_for_update_cf*(
    txn: ptr rocksdb_transaction_t; options: ptr rocksdb_readoptions_t;
    column_family: ptr rocksdb_column_family_handle_t; key: cstring; klen: csize_t;
    exclusive: uint8; errptr: cstringArray): ptr rocksdb_pinnableslice_t {.cdecl.}
proc rocksdb_transaction_multi_get*(txn: ptr rocksdb_transaction_t;
                                   options: ptr rocksdb_readoptions_t;
                                   num_keys: csize_t; keys_list: cstringArray;
                                   keys_list_sizes: ptr csize_t;
                                   values_list: cstringArray;
                                   values_list_sizes: ptr csize_t;
                                   errs: cstringArray) {.cdecl.}
proc rocksdb_transaction_multi_get_for_update*(txn: ptr rocksdb_transaction_t;
    options: ptr rocksdb_readoptions_t; num_keys: csize_t; keys_list: cstringArray;
    keys_list_sizes: ptr csize_t; values_list: cstringArray;
    values_list_sizes: ptr csize_t; errs: cstringArray) {.cdecl.}
proc rocksdb_transaction_multi_get_cf*(txn: ptr rocksdb_transaction_t;
                                      options: ptr rocksdb_readoptions_t;
    column_families: ptr ptr rocksdb_column_family_handle_t; num_keys: csize_t;
                                      keys_list: cstringArray;
                                      keys_list_sizes: ptr csize_t;
                                      values_list: cstringArray;
                                      values_list_sizes: ptr csize_t;
                                      errs: cstringArray) {.cdecl.}
proc rocksdb_transaction_multi_get_for_update_cf*(txn: ptr rocksdb_transaction_t;
    options: ptr rocksdb_readoptions_t;
    column_families: ptr ptr rocksdb_column_family_handle_t; num_keys: csize_t;
    keys_list: cstringArray; keys_list_sizes: ptr csize_t; values_list: cstringArray;
    values_list_sizes: ptr csize_t; errs: cstringArray) {.cdecl.}
proc rocksdb_transactiondb_get*(txn_db: ptr rocksdb_transactiondb_t;
                               options: ptr rocksdb_readoptions_t; key: cstring;
                               klen: csize_t; vlen: ptr csize_t; errptr: cstringArray): cstring {.
    cdecl.}
proc rocksdb_transactiondb_get_pinned*(txn_db: ptr rocksdb_transactiondb_t;
                                      options: ptr rocksdb_readoptions_t;
                                      key: cstring; klen: csize_t;
                                      errptr: cstringArray): ptr rocksdb_pinnableslice_t {.
    cdecl.}
proc rocksdb_transactiondb_get_cf*(txn_db: ptr rocksdb_transactiondb_t;
                                  options: ptr rocksdb_readoptions_t; column_family: ptr rocksdb_column_family_handle_t;
                                  key: cstring; keylen: csize_t;
                                  vallen: ptr csize_t; errptr: cstringArray): cstring {.
    cdecl.}
proc rocksdb_transactiondb_get_pinned_cf*(txn_db: ptr rocksdb_transactiondb_t;
    options: ptr rocksdb_readoptions_t;
    column_family: ptr rocksdb_column_family_handle_t; key: cstring; keylen: csize_t;
    errptr: cstringArray): ptr rocksdb_pinnableslice_t {.cdecl.}
proc rocksdb_transactiondb_multi_get*(txn_db: ptr rocksdb_transactiondb_t;
                                     options: ptr rocksdb_readoptions_t;
                                     num_keys: csize_t; keys_list: cstringArray;
                                     keys_list_sizes: ptr csize_t;
                                     values_list: cstringArray;
                                     values_list_sizes: ptr csize_t;
                                     errs: cstringArray) {.cdecl.}
proc rocksdb_transactiondb_multi_get_cf*(txn_db: ptr rocksdb_transactiondb_t;
                                        options: ptr rocksdb_readoptions_t;
    column_families: ptr ptr rocksdb_column_family_handle_t; num_keys: csize_t;
                                        keys_list: cstringArray;
                                        keys_list_sizes: ptr csize_t;
                                        values_list: cstringArray;
                                        values_list_sizes: ptr csize_t;
                                        errs: cstringArray) {.cdecl.}
proc rocksdb_transaction_put*(txn: ptr rocksdb_transaction_t; key: cstring;
                             klen: csize_t; val: cstring; vlen: csize_t;
                             errptr: cstringArray) {.cdecl.}
proc rocksdb_transaction_put_cf*(txn: ptr rocksdb_transaction_t; column_family: ptr rocksdb_column_family_handle_t;
                                key: cstring; klen: csize_t; val: cstring;
                                vlen: csize_t; errptr: cstringArray) {.cdecl.}
proc rocksdb_transactiondb_put*(txn_db: ptr rocksdb_transactiondb_t;
                               options: ptr rocksdb_writeoptions_t; key: cstring;
                               klen: csize_t; val: cstring; vlen: csize_t;
                               errptr: cstringArray) {.cdecl.}
proc rocksdb_transactiondb_put_cf*(txn_db: ptr rocksdb_transactiondb_t;
                                  options: ptr rocksdb_writeoptions_t;
    column_family: ptr rocksdb_column_family_handle_t; key: cstring; keylen: csize_t;
                                  val: cstring; vallen: csize_t;
                                  errptr: cstringArray) {.cdecl.}
proc rocksdb_transactiondb_write*(txn_db: ptr rocksdb_transactiondb_t;
                                 options: ptr rocksdb_writeoptions_t;
                                 batch: ptr rocksdb_writebatch_t;
                                 errptr: cstringArray) {.cdecl.}
proc rocksdb_transaction_merge*(txn: ptr rocksdb_transaction_t; key: cstring;
                               klen: csize_t; val: cstring; vlen: csize_t;
                               errptr: cstringArray) {.cdecl.}
proc rocksdb_transaction_merge_cf*(txn: ptr rocksdb_transaction_t; column_family: ptr rocksdb_column_family_handle_t;
                                  key: cstring; klen: csize_t; val: cstring;
                                  vlen: csize_t; errptr: cstringArray) {.cdecl.}
proc rocksdb_transactiondb_merge*(txn_db: ptr rocksdb_transactiondb_t;
                                 options: ptr rocksdb_writeoptions_t; key: cstring;
                                 klen: csize_t; val: cstring; vlen: csize_t;
                                 errptr: cstringArray) {.cdecl.}
proc rocksdb_transactiondb_merge_cf*(txn_db: ptr rocksdb_transactiondb_t;
                                    options: ptr rocksdb_writeoptions_t;
    column_family: ptr rocksdb_column_family_handle_t; key: cstring; klen: csize_t;
                                    val: cstring; vlen: csize_t;
                                    errptr: cstringArray) {.cdecl.}
proc rocksdb_transaction_delete*(txn: ptr rocksdb_transaction_t; key: cstring;
                                klen: csize_t; errptr: cstringArray) {.cdecl.}
proc rocksdb_transaction_delete_cf*(txn: ptr rocksdb_transaction_t; column_family: ptr rocksdb_column_family_handle_t;
                                   key: cstring; klen: csize_t; errptr: cstringArray) {.
    cdecl.}
proc rocksdb_transactiondb_delete*(txn_db: ptr rocksdb_transactiondb_t;
                                  options: ptr rocksdb_writeoptions_t;
                                  key: cstring; klen: csize_t; errptr: cstringArray) {.
    cdecl.}
proc rocksdb_transactiondb_delete_cf*(txn_db: ptr rocksdb_transactiondb_t;
                                     options: ptr rocksdb_writeoptions_t;
    column_family: ptr rocksdb_column_family_handle_t; key: cstring; keylen: csize_t;
                                     errptr: cstringArray) {.cdecl.}
proc rocksdb_transaction_create_iterator*(txn: ptr rocksdb_transaction_t;
    options: ptr rocksdb_readoptions_t): ptr rocksdb_iterator_t {.cdecl.}
proc rocksdb_transaction_create_iterator_cf*(txn: ptr rocksdb_transaction_t;
    options: ptr rocksdb_readoptions_t;
    column_family: ptr rocksdb_column_family_handle_t): ptr rocksdb_iterator_t {.
    cdecl.}
proc rocksdb_transactiondb_create_iterator*(txn_db: ptr rocksdb_transactiondb_t;
    options: ptr rocksdb_readoptions_t): ptr rocksdb_iterator_t {.cdecl.}
proc rocksdb_transactiondb_create_iterator_cf*(
    txn_db: ptr rocksdb_transactiondb_t; options: ptr rocksdb_readoptions_t;
    column_family: ptr rocksdb_column_family_handle_t): ptr rocksdb_iterator_t {.
    cdecl.}
proc rocksdb_transactiondb_close*(txn_db: ptr rocksdb_transactiondb_t) {.cdecl.}
proc rocksdb_transactiondb_flush*(txn_db: ptr rocksdb_transactiondb_t;
                                 options: ptr rocksdb_flushoptions_t;
                                 errptr: cstringArray) {.cdecl.}
proc rocksdb_transactiondb_flush_cf*(txn_db: ptr rocksdb_transactiondb_t;
                                    options: ptr rocksdb_flushoptions_t;
    column_family: ptr rocksdb_column_family_handle_t; errptr: cstringArray) {.cdecl.}
proc rocksdb_transactiondb_flush_cfs*(txn_db: ptr rocksdb_transactiondb_t;
                                     options: ptr rocksdb_flushoptions_t;
    column_families: ptr ptr rocksdb_column_family_handle_t;
                                     num_column_families: cint;
                                     errptr: cstringArray) {.cdecl.}
proc rocksdb_transactiondb_flush_wal*(txn_db: ptr rocksdb_transactiondb_t;
                                     sync: uint8; errptr: cstringArray) {.cdecl.}
proc rocksdb_transactiondb_checkpoint_object_create*(
    txn_db: ptr rocksdb_transactiondb_t; errptr: cstringArray): ptr rocksdb_checkpoint_t {.
    cdecl.}
proc rocksdb_optimistictransactiondb_open*(options: ptr rocksdb_options_t;
    name: cstring; errptr: cstringArray): ptr rocksdb_optimistictransactiondb_t {.
    cdecl.}
proc rocksdb_optimistictransactiondb_open_column_families*(
    options: ptr rocksdb_options_t; name: cstring; num_column_families: cint;
    column_family_names: cstringArray;
    column_family_options: ptr ptr rocksdb_options_t;
    column_family_handles: ptr ptr rocksdb_column_family_handle_t;
    errptr: cstringArray): ptr rocksdb_optimistictransactiondb_t {.cdecl.}
proc rocksdb_optimistictransactiondb_get_base_db*(
    otxn_db: ptr rocksdb_optimistictransactiondb_t): ptr rocksdb_t {.cdecl.}
proc rocksdb_optimistictransactiondb_close_base_db*(base_db: ptr rocksdb_t) {.cdecl.}
proc rocksdb_optimistictransaction_begin*(
    otxn_db: ptr rocksdb_optimistictransactiondb_t;
    write_options: ptr rocksdb_writeoptions_t;
    otxn_options: ptr rocksdb_optimistictransaction_options_t;
    old_txn: ptr rocksdb_transaction_t): ptr rocksdb_transaction_t {.cdecl.}
proc rocksdb_optimistictransactiondb_write*(
    otxn_db: ptr rocksdb_optimistictransactiondb_t;
    options: ptr rocksdb_writeoptions_t; batch: ptr rocksdb_writebatch_t;
    errptr: cstringArray) {.cdecl.}
proc rocksdb_optimistictransactiondb_close*(
    otxn_db: ptr rocksdb_optimistictransactiondb_t) {.cdecl.}
proc rocksdb_optimistictransactiondb_checkpoint_object_create*(
    otxn_db: ptr rocksdb_optimistictransactiondb_t; errptr: cstringArray): ptr rocksdb_checkpoint_t {.
    cdecl.}
##  Transaction Options

proc rocksdb_transactiondb_options_create*(): ptr rocksdb_transactiondb_options_t {.
    cdecl.}
proc rocksdb_transactiondb_options_destroy*(
    opt: ptr rocksdb_transactiondb_options_t) {.cdecl.}
proc rocksdb_transactiondb_options_set_max_num_locks*(
    opt: ptr rocksdb_transactiondb_options_t; max_num_locks: int64) {.cdecl.}
proc rocksdb_transactiondb_options_set_num_stripes*(
    opt: ptr rocksdb_transactiondb_options_t; num_stripes: csize_t) {.cdecl.}
proc rocksdb_transactiondb_options_set_transaction_lock_timeout*(
    opt: ptr rocksdb_transactiondb_options_t; txn_lock_timeout: int64) {.cdecl.}
proc rocksdb_transactiondb_options_set_default_lock_timeout*(
    opt: ptr rocksdb_transactiondb_options_t; default_lock_timeout: int64) {.cdecl.}
proc rocksdb_transaction_options_create*(): ptr rocksdb_transaction_options_t {.
    cdecl.}
proc rocksdb_transaction_options_destroy*(opt: ptr rocksdb_transaction_options_t) {.
    cdecl.}
proc rocksdb_transaction_options_set_set_snapshot*(
    opt: ptr rocksdb_transaction_options_t; v: uint8) {.cdecl.}
proc rocksdb_transaction_options_set_deadlock_detect*(
    opt: ptr rocksdb_transaction_options_t; v: uint8) {.cdecl.}
proc rocksdb_transaction_options_set_lock_timeout*(
    opt: ptr rocksdb_transaction_options_t; lock_timeout: int64) {.cdecl.}
proc rocksdb_transaction_options_set_expiration*(
    opt: ptr rocksdb_transaction_options_t; expiration: int64) {.cdecl.}
proc rocksdb_transaction_options_set_deadlock_detect_depth*(
    opt: ptr rocksdb_transaction_options_t; depth: int64) {.cdecl.}
proc rocksdb_transaction_options_set_max_write_batch_size*(
    opt: ptr rocksdb_transaction_options_t; size: csize_t) {.cdecl.}
proc rocksdb_transaction_options_set_skip_prepare*(
    opt: ptr rocksdb_transaction_options_t; v: uint8) {.cdecl.}
proc rocksdb_optimistictransaction_options_create*(): ptr rocksdb_optimistictransaction_options_t {.
    cdecl.}
proc rocksdb_optimistictransaction_options_destroy*(
    opt: ptr rocksdb_optimistictransaction_options_t) {.cdecl.}
proc rocksdb_optimistictransaction_options_set_set_snapshot*(
    opt: ptr rocksdb_optimistictransaction_options_t; v: uint8) {.cdecl.}
proc rocksdb_optimistictransactiondb_property_value*(
    db: ptr rocksdb_optimistictransactiondb_t; propname: cstring): cstring {.cdecl.}
proc rocksdb_optimistictransactiondb_property_int*(
    db: ptr rocksdb_optimistictransactiondb_t; propname: cstring; out_val: ptr uint64): cint {.
    cdecl.}
##  referring to convention (3), this should be used by client
##  to free memory that was malloc()ed

proc rocksdb_free*(`ptr`: pointer) {.cdecl.}
proc rocksdb_get_pinned*(db: ptr rocksdb_t; options: ptr rocksdb_readoptions_t;
                        key: cstring; keylen: csize_t; errptr: cstringArray): ptr rocksdb_pinnableslice_t {.
    cdecl.}
proc rocksdb_get_pinned_cf*(db: ptr rocksdb_t; options: ptr rocksdb_readoptions_t;
                           column_family: ptr rocksdb_column_family_handle_t;
                           key: cstring; keylen: csize_t; errptr: cstringArray): ptr rocksdb_pinnableslice_t {.
    cdecl.}
proc rocksdb_pinnableslice_destroy*(v: ptr rocksdb_pinnableslice_t) {.cdecl.}
proc rocksdb_pinnableslice_value*(t: ptr rocksdb_pinnableslice_t; vlen: ptr csize_t): cstring {.
    cdecl.}
proc rocksdb_memory_consumers_create*(): ptr rocksdb_memory_consumers_t {.cdecl.}
proc rocksdb_memory_consumers_add_db*(consumers: ptr rocksdb_memory_consumers_t;
                                     db: ptr rocksdb_t) {.cdecl.}
proc rocksdb_memory_consumers_add_cache*(consumers: ptr rocksdb_memory_consumers_t;
                                        cache: ptr rocksdb_cache_t) {.cdecl.}
proc rocksdb_memory_consumers_destroy*(consumers: ptr rocksdb_memory_consumers_t) {.
    cdecl.}
proc rocksdb_approximate_memory_usage_create*(
    consumers: ptr rocksdb_memory_consumers_t; errptr: cstringArray): ptr rocksdb_memory_usage_t {.
    cdecl.}
proc rocksdb_approximate_memory_usage_destroy*(usage: ptr rocksdb_memory_usage_t) {.
    cdecl.}
proc rocksdb_approximate_memory_usage_get_mem_table_total*(
    memory_usage: ptr rocksdb_memory_usage_t): uint64 {.cdecl.}
proc rocksdb_approximate_memory_usage_get_mem_table_unflushed*(
    memory_usage: ptr rocksdb_memory_usage_t): uint64 {.cdecl.}
proc rocksdb_approximate_memory_usage_get_mem_table_readers_total*(
    memory_usage: ptr rocksdb_memory_usage_t): uint64 {.cdecl.}
proc rocksdb_approximate_memory_usage_get_cache_total*(
    memory_usage: ptr rocksdb_memory_usage_t): uint64 {.cdecl.}
proc rocksdb_options_set_dump_malloc_stats*(a1: ptr rocksdb_options_t; a2: uint8) {.
    cdecl.}
proc rocksdb_options_set_memtable_whole_key_filtering*(a1: ptr rocksdb_options_t;
    a2: uint8) {.cdecl.}
proc rocksdb_cancel_all_background_work*(db: ptr rocksdb_t; wait: uint8) {.cdecl.}
proc rocksdb_disable_manual_compaction*(db: ptr rocksdb_t) {.cdecl.}
proc rocksdb_enable_manual_compaction*(db: ptr rocksdb_t) {.cdecl.}
proc rocksdb_statistics_histogram_data_create*(): ptr rocksdb_statistics_histogram_data_t {.
    cdecl.}
proc rocksdb_statistics_histogram_data_destroy*(
    data: ptr rocksdb_statistics_histogram_data_t) {.cdecl.}
proc rocksdb_statistics_histogram_data_get_median*(
    data: ptr rocksdb_statistics_histogram_data_t): cdouble {.cdecl.}
proc rocksdb_statistics_histogram_data_get_p95*(
    data: ptr rocksdb_statistics_histogram_data_t): cdouble {.cdecl.}
proc rocksdb_statistics_histogram_data_get_p99*(
    data: ptr rocksdb_statistics_histogram_data_t): cdouble {.cdecl.}
proc rocksdb_statistics_histogram_data_get_average*(
    data: ptr rocksdb_statistics_histogram_data_t): cdouble {.cdecl.}
proc rocksdb_statistics_histogram_data_get_std_dev*(
    data: ptr rocksdb_statistics_histogram_data_t): cdouble {.cdecl.}
proc rocksdb_statistics_histogram_data_get_max*(
    data: ptr rocksdb_statistics_histogram_data_t): cdouble {.cdecl.}
proc rocksdb_statistics_histogram_data_get_count*(
    data: ptr rocksdb_statistics_histogram_data_t): uint64 {.cdecl.}
proc rocksdb_statistics_histogram_data_get_sum*(
    data: ptr rocksdb_statistics_histogram_data_t): uint64 {.cdecl.}
proc rocksdb_statistics_histogram_data_get_min*(
    data: ptr rocksdb_statistics_histogram_data_t): cdouble {.cdecl.}
proc rocksdb_wait_for_compact*(db: ptr rocksdb_t;
                              options: ptr rocksdb_wait_for_compact_options_t;
                              errptr: cstringArray) {.cdecl.}
proc rocksdb_wait_for_compact_options_create*(): ptr rocksdb_wait_for_compact_options_t {.
    cdecl.}
proc rocksdb_wait_for_compact_options_destroy*(
    opt: ptr rocksdb_wait_for_compact_options_t) {.cdecl.}
proc rocksdb_wait_for_compact_options_set_abort_on_pause*(
    opt: ptr rocksdb_wait_for_compact_options_t; v: uint8) {.cdecl.}
proc rocksdb_wait_for_compact_options_get_abort_on_pause*(
    opt: ptr rocksdb_wait_for_compact_options_t): uint8 {.cdecl.}
proc rocksdb_wait_for_compact_options_set_flush*(
    opt: ptr rocksdb_wait_for_compact_options_t; v: uint8) {.cdecl.}
proc rocksdb_wait_for_compact_options_get_flush*(
    opt: ptr rocksdb_wait_for_compact_options_t): uint8 {.cdecl.}
proc rocksdb_wait_for_compact_options_set_close_db*(
    opt: ptr rocksdb_wait_for_compact_options_t; v: uint8) {.cdecl.}
proc rocksdb_wait_for_compact_options_get_close_db*(
    opt: ptr rocksdb_wait_for_compact_options_t): uint8 {.cdecl.}
proc rocksdb_wait_for_compact_options_set_timeout*(
    opt: ptr rocksdb_wait_for_compact_options_t; microseconds: uint64) {.cdecl.}
proc rocksdb_wait_for_compact_options_get_timeout*(
    opt: ptr rocksdb_wait_for_compact_options_t): uint64 {.cdecl.}