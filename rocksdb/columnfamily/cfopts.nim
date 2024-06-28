# Nim-RocksDB
# Copyright 2024 Status Research & Development GmbH
# Licensed under either of
#
#  * Apache License, version 2.0, ([LICENSE-APACHE](LICENSE-APACHE) or http://www.apache.org/licenses/LICENSE-2.0)
#  * GPL license, version 2.0, ([LICENSE-GPLv2](LICENSE-GPLv2) or https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)
#
# at your option. This file may not be copied, modified, or distributed except according to those terms.

{.push raises: [].}

import ../lib/librocksdb, ../options/tableopts

type
  SlicetransformPtr* = ptr rocksdb_slicetransform_t

  SlicetransformRef* = ref object
    cPtr: SlicetransformPtr
    autoClose*: bool # if true then close will be called when the parent is closed

  ColFamilyOptionsPtr* = ptr rocksdb_options_t

  ColFamilyOptionsRef* = ref object
    # In the C API, both family and database options are exposed using the same
    # type - CF options are a subset of rocksdb_options_t - when in doubt, check:
    # https://github.com/facebook/rocksdb/blob/b8c9a2576af6a1d0ffcfbb517dfcb7e7037bd460/include/rocksdb/options.h#L66
    cPtr: ColFamilyOptionsPtr
    sliceTransform: SlicetransformRef
    tableOpts: TableOptionsRef
    autoClose*: bool # if true then close will be called when the database is closed

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

proc createFixedPrefix*(value: int, autoClose = false): SlicetransformRef =
  SlicetransformRef(
    cPtr: rocksdb_slicetransform_create_fixed_prefix(value.csize_t),
    autoClose: autoClose,
  )

proc isClosed*(s: SlicetransformRef): bool {.inline.} =
  s.cPtr.isNil()

proc cPtr*(s: SlicetransformRef): SlicetransformPtr =
  doAssert not s.isClosed()
  s.cPtr

proc close*(s: SlicetransformRef) =
  if not s.isClosed():
    rocksdb_slicetransform_destroy(s.cPtr)
    s.cPtr = nil

proc newColFamilyOptions*(autoClose = false): ColFamilyOptionsRef =
  ColFamilyOptionsRef(cPtr: rocksdb_options_create(), autoClose: autoClose)

proc isClosed*(cfOpts: ColFamilyOptionsRef): bool {.inline.} =
  cfOpts.cPtr.isNil()

proc cPtr*(cfOpts: ColFamilyOptionsRef): ColFamilyOptionsPtr =
  doAssert not cfOpts.isClosed()
  cfOpts.cPtr

proc close*(cfOpts: ColFamilyOptionsRef) =
  if not cfOpts.isClosed():
    rocksdb_options_destroy(cfOpts.cPtr)
    cfOpts.cPtr = nil

    if not cfOpts.sliceTransform.isNil() and cfOpts.sliceTransform.autoClose:
      cfOpts.sliceTransform.close()
    if not cfOpts.tableOpts.isNil() and cfOpts.tableOpts.autoClose:
      cfOpts.tableOpts.close()

template opt(nname, ntyp, ctyp: untyped) =
  proc `nname=`*(cfOpts: ColFamilyOptionsRef, value: ntyp) =
    doAssert not cfOpts.isClosed
    `rocksdb_options_set nname`(cfOpts.cPtr, value.ctyp)

  proc `nname`*(cfOpts: ColFamilyOptionsRef): ntyp =
    doAssert not cfOpts.isClosed
    ntyp `rocksdb_options_get nname`(cfOpts.cPtr)

opt writeBufferSize, int, csize_t
opt compression, Compression, cint
opt bottommostCompression, Compression, cint
opt level0FileNumCompactionTrigger, int, cint
opt maxBytesForLevelBase, int, uint64
opt disableAutoCompactions, bool, cint

opt maxWriteBufferNumber, int, cint
opt minWriteBufferNumberToMerge, int, cint
opt maxWriteBufferSizeToMaintain, int, int64
opt inplaceUpdateSupport, bool, uint8
opt inplaceUpdateNumLocks, int, csize_t
opt memtablePrefixBloomSizeRatio, float, cdouble
opt memtableHugePageSize, int, csize_t
opt bloomLocality, int, uint32
opt arenaBlockSize, int, csize_t
opt numLevels, int, cint
opt level0SlowdownWritesTrigger, int, cint
opt level0StopWritesTrigger, int, cint
opt targetFileSizeBase, int, uint64
opt targetFileSizeMultiplier, int, cint
opt maxBytesForLevelMultiplier, float, cdouble
opt maxCompactionBytes, int, uint64
opt softPendingCompactionBytesLimit, int, csize_t
opt hardPendingCompactionBytesLimit, int, csize_t
opt maxSequentialSkipInIterations, int, uint64
opt maxSuccessiveMerges, int, csize_t
opt optimizeFiltersForHits, bool, cint
opt paranoidChecks, bool, uint8
opt reportBgIoStats, bool, cint
opt enableBlobFiles, bool, uint8
opt minBlobSize, int, uint64
opt blobFileSize, int, uint64
opt blobCompressionType, Compression, cint
opt enableBlobGC, bool, uint8
opt blobGCAgeCutoff, float, cdouble
opt blobGCForceThreshold, float, cdouble
opt blobCompactionReadaheadSize, int, uint64
opt blobFileStartingLevel, int, cint

proc defaultColFamilyOptions*(autoClose = false): ColFamilyOptionsRef =
  newColFamilyOptions(autoClose)

# proc setFixedPrefixExtractor*(dbOpts: ColFamilyOptionsRef, length: int) =
#   doAssert not dbOpts.isClosed()
#   rocksdb_options_set_prefix_extractor(
#     dbOpts.cPtr, rocksdb_slicetransform_create_fixed_prefix(length.csize_t))

proc `setPrefixExtractor`*(cfOpts: ColFamilyOptionsRef, value: SlicetransformRef) =
  doAssert not cfOpts.isClosed()
  doAssert cfOpts.sliceTransform.isNil()
    # don't allow overwriting an existing sliceTransform which could leak memory

  rocksdb_options_set_prefix_extractor(cfOpts.cPtr, value.cPtr)
  cfOpts.sliceTransform = value

proc `blockBasedTableFactory=`*(
    cfOpts: ColFamilyOptionsRef, tableOpts: TableOptionsRef
) =
  doAssert not cfOpts.isClosed()
  doAssert cfOpts.tableOpts.isNil()
    # don't allow overwriting an existing tableOpts which could leak memory

  rocksdb_options_set_block_based_table_factory(cfOpts.cPtr, tableOpts.cPtr)
  cfOpts.tableOpts = tableOpts

# https://github.com/facebook/rocksdb/wiki/MemTable
proc setHashSkipListRep*(
    cfOpts: ColFamilyOptionsRef,
    bucketCount, skipListHeight, skipListBranchingFactor: int,
) =
  doAssert not cfOpts.isClosed()
  rocksdb_options_set_hash_skip_list_rep(
    cfOpts.cPtr, bucketCount.csize_t, skipListHeight.cint, skipListBranchingFactor.cint
  )

proc setHashLinkListRep*(cfOpts: ColFamilyOptionsRef, bucketCount: int) =
  doAssert not cfOpts.isClosed()
  rocksdb_options_set_hash_link_list_rep(cfOpts.cPtr, bucketCount.csize_t)

proc setMemtableVectorRep*(cfOpts: ColFamilyOptionsRef) =
  doAssert not cfOpts.isClosed()
  rocksdb_options_set_memtable_vector_rep(cfOpts.cPtr)

proc `memtableWholeKeyFiltering=`*(dbOpts: ColFamilyOptionsRef, value: bool) =
  doAssert not dbOpts.isClosed()
  rocksdb_options_set_memtable_whole_key_filtering(dbOpts.cPtr, value.uint8)
