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
  ColFamilyOptionsPtr* = ptr rocksdb_options_t

  ColFamilyOptionsRef* = ref object
    cPtr: ColFamilyOptionsPtr

  Compression* {.pure.} = enum
    # Use a slightly clunky name here to avoid global symbol conflicts
    noCompression = rocksdb_no_compression
    snappyCompression = rocksdb_snappy_compression
    zlibCompression = rocksdb_zlib_compression
    bz2Compression = rocksdb_bz2_compression
    lz4Compression = rocksdb_lz4_compression
    lz4hcCompression = rocksdb_lz4hc_compression
    xpressCompression = rocksdb_xpress_compression
    zstdCompression = rocksdb_zstd_compression

proc newColFamilyOptions*(): ColFamilyOptionsRef =
  ColFamilyOptionsRef(cPtr: rocksdb_options_create())

proc isClosed*(cfOpts: ColFamilyOptionsRef): bool {.inline.} =
  cfOpts.cPtr.isNil()

proc cPtr*(cfOpts: ColFamilyOptionsRef): ColFamilyOptionsPtr =
  doAssert not cfOpts.isClosed()
  cfOpts.cPtr

proc setCreateMissingColumnFamilies*(cfOpts: ColFamilyOptionsRef, flag: bool) =
  doAssert not cfOpts.isClosed()
  rocksdb_options_set_create_missing_column_families(cfOpts.cPtr, flag.uint8)

proc defaultColFamilyOptions*(): ColFamilyOptionsRef =
  let opts = newColFamilyOptions()

  # rocksdb_options_set_compression(opts.cPtr, rocksdb_lz4_compression)
  # rocksdb_options_set_bottommost_compression(opts.cPtr, rocksdb_zstd_compression)

  # Enable creating column families if they do not exist
  opts.setCreateMissingColumnFamilies(true)
  return opts

# TODO: These procs below will not work unless using the latest version of rocksdb
# Currently, when installing librocksdb-dev on linux the RocksDb version used is 6.11.4
# Need to complete this task: https://github.com/status-im/nim-rocksdb/issues/10

# proc getCreateMissingColumnFamilies*(cfOpts: ColFamilyOptionsRef): bool =
#   doAssert not cfOpts.isClosed()
#   rocksdb_options_get_create_missing_column_families(cfOpts.cPtr).bool

proc setWriteBufferSize*(dbOpts: ColFamilyOptionsRef, maxBufferSize: int) =
  doAssert not dbOpts.isClosed()
  rocksdb_options_set_write_buffer_size(dbOpts.cPtr, maxBufferSize.csize_t)

# https://github.com/facebook/rocksdb/wiki/MemTable
proc setHashSkipListRep*(
    dbOpts: ColFamilyOptionsRef, bucketCount, skipListHeight,
    skipListBranchingFactor: int) =
  doAssert not dbOpts.isClosed()
  rocksdb_options_set_hash_skip_list_rep(
    dbOpts.cPtr, bucketCount.csize_t, skipListHeight.cint,
    skipListBranchingFactor.cint)

proc setHashLinkListRep*(
    dbOpts: ColFamilyOptionsRef, bucketCount: int) =
  doAssert not dbOpts.isClosed()
  rocksdb_options_set_hash_link_list_rep(dbOpts.cPtr, bucketCount.csize_t)

proc setMemtableVectorRep*(dbOpts: ColFamilyOptionsRef) =
  doAssert not dbOpts.isClosed()
  rocksdb_options_set_memtable_vector_rep(dbOpts.cPtr)

proc setMemtableWholeKeyFiltering*(dbOpts: ColFamilyOptionsRef, value: bool) =
  doAssert not dbOpts.isClosed()
  rocksdb_options_set_memtable_whole_key_filtering(dbOpts.cPtr, value.uint8)

proc setMemtablePrefixBloomSizeRatio*(dbOpts: ColFamilyOptionsRef, value: float) =
  doAssert not dbOpts.isClosed()
  rocksdb_options_set_memtable_prefix_bloom_size_ratio(dbOpts.cPtr, value)

proc setFixedPrefixExtractor*(dbOpts: ColFamilyOptionsRef, length: int) =
  doAssert not dbOpts.isClosed()
  rocksdb_options_set_prefix_extractor(
    dbOpts.cPtr, rocksdb_slicetransform_create_fixed_prefix(length.csize_t))

proc setCompression*(dbOpts: ColFamilyOptionsRef, value: Compression) =
  doAssert not dbOpts.isClosed()
  rocksdb_options_set_compression(dbOpts.cPtr, value.cint)

proc setBottommostCompression*(dbOpts: ColFamilyOptionsRef, value: Compression) =
  doAssert not dbOpts.isClosed()
  rocksdb_options_set_bottommost_compression(dbOpts.cPtr, value.cint)

proc close*(cfOpts: ColFamilyOptionsRef) =
  if not cfOpts.isClosed():
    rocksdb_options_destroy(cfOpts.cPtr)
    cfOpts.cPtr = nil
