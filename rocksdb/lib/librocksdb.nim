# Copyright 2018-2025 Status Research & Development GmbH
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

import std/[os, strutils]

{.push raises: [].}

type
  rocksdb_t* = object
  rocksdb_backup_engine_t* = object
  rocksdb_backup_engine_info_t* = object
  rocksdb_backup_engine_options_t* = object
  rocksdb_restore_options_t* = object
  rocksdb_cache_t* = object
  rocksdb_compactionfilter_t* = object
  rocksdb_compactionfiltercontext_t* = object
  rocksdb_compactionfilterfactory_t* = object
  rocksdb_comparator_t* = object
  rocksdb_dbpath_t* = object
  rocksdb_env_t* = object
  rocksdb_fifo_compaction_options_t* = object
  rocksdb_filelock_t* = object
  rocksdb_filterpolicy_t* = object
  rocksdb_flushoptions_t* = object
  rocksdb_iterator_t* = object
  rocksdb_logger_t* = object
  rocksdb_mergeoperator_t* = object
  rocksdb_options_t* = object
  rocksdb_compactoptions_t* = object
  rocksdb_block_based_table_options_t* = object
  rocksdb_cuckoo_table_options_t* = object
  rocksdb_randomfile_t* = object
  rocksdb_readoptions_t* = object
  rocksdb_seqfile_t* = object
  rocksdb_slicetransform_t* = object
  rocksdb_snapshot_t* = object
  rocksdb_writablefile_t* = object
  rocksdb_writebatch_t* = object
  rocksdb_writebatch_wi_t* = object
  rocksdb_writeoptions_t* = object
  rocksdb_universal_compaction_options_t* = object
  rocksdb_livefiles_t* = object
  rocksdb_column_family_handle_t* = object
  rocksdb_envoptions_t* = object
  rocksdb_ingestexternalfileoptions_t* = object
  rocksdb_sstfilewriter_t* = object
  rocksdb_ratelimiter_t* = object
  rocksdb_pinnableslice_t* = object
  rocksdb_transactiondb_options_t* = object
  rocksdb_transactiondb_t* = object
  rocksdb_transaction_options_t* = object
  rocksdb_optimistictransactiondb_t* = object
  rocksdb_optimistictransaction_options_t* = object
  rocksdb_transaction_t* = object
  rocksdb_checkpoint_t* = object
  rocksdb_wal_readoptions_t* = object
  rocksdb_wal_iterator_t* = object
  rocksdb_write_buffer_manager_t* = object
  rocksdb_statistics_histogram_data_t* = object
  rocksdb_perfcontext_t* = object
  rocksdb_memory_allocator_t* = object
  rocksdb_lru_cache_options_t* = object
  rocksdb_hyper_clock_cache_options_t* = object
  rocksdb_level_metadata_t* = object
  rocksdb_sst_file_metadata_t* = object
  rocksdb_column_family_metadata_t* = object
  rocksdb_memory_usage_t* = object
  rocksdb_memory_consumers_t* = object
  rocksdb_wait_for_compact_options_t* = object

when defined(windows):
  const librocksdb = "librocksdb.dll"
elif defined(macosx):
  const librocksdb = "librocksdb.dylib"
else:
  const librocksdb = "librocksdb.so"

when defined(rocksdb_dynamic_linking) or defined(windows):
  {.push importc, cdecl, dynlib: librocksdb.}
else:
  const
    topLevelPath = currentSourcePath.parentDir().parentDir().parentDir()
    libsDir = topLevelPath.replace('\\', '/') & "/build/lib/"

  {.passl: libsDir & "/librocksdb.a".}
  {.passl: libsDir & "/liblz4.a".}
  {.passl: libsDir & "/libzstd.a".}

  when defined(windows):
    {.passl: "-lshlwapi -lrpcrt4".}

  {.push importc, cdecl.}

include ./rocksdb_gen.nim
