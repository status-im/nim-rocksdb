import ../lib/librocksdb, ./cache

type
  # TODO might eventually wrap this
  TableOptionsPtr* = ptr rocksdb_block_based_table_options_t

  TableOptionsRef* = ref object
    cPtr*: TableOptionsPtr

  FilterPolicyPtr* = ptr rocksdb_filterpolicy_t

  FilterPolicyRef* = ref object
    cPtr*: FilterPolicyPtr

  IndexType* {.pure.} = enum
    binarySearch = rocksdb_block_based_table_index_type_binary_search
    hashSearch = rocksdb_block_based_table_index_type_hash_search
    twoLevelIndexSearch = rocksdb_block_based_table_index_type_two_level_index_search

  DataBlockIndexType* {.pure.} = enum
    binarySearch = rocksdb_block_based_table_data_block_index_type_binary_search
    binarySearchAndHash =
      rocksdb_block_based_table_data_block_index_type_binary_search_and_hash

proc createRibbon*(bitsPerKey: float): FilterPolicyRef =
  FilterPolicyRef(cPtr: rocksdb_filterpolicy_create_ribbon(bitsPerKey))

proc createRibbonHybrid*(
    bitsPerKey: float, bloomBeforeLevel: int = 0
): FilterPolicyRef =
  FilterPolicyRef(
    cPtr: rocksdb_filterpolicy_create_ribbon_hybrid(bitsPerKey, bloomBeforeLevel.cint)
  )

proc isClosed*(policy: FilterPolicyRef): bool =
  isNil(policy.cPtr)

proc close*(policy: FilterPolicyRef) =
  if not isClosed(policy):
    rocksdb_filterpolicy_destroy(policy.cPtr)
    policy.cPtr = nil

proc createTableOptions*(): TableOptionsRef =
  TableOptionsRef(cPtr: rocksdb_block_based_options_create())

proc isClosed*(opts: TableOptionsRef): bool =
  isNil(opts.cPtr)

proc close*(opts: TableOptionsRef) =
  if not isClosed(opts):
    rocksdb_block_based_options_destroy(opts.cPtr)
    opts.cPtr = nil

template opt(nname, ntyp, ctyp: untyped) =
  proc `nname=`*(opts: TableOptionsRef, value: ntyp) =
    doAssert not opts.isClosed
    `rocksdb_block_based_options_set nname`(opts.cPtr, value.ctyp)

opt cacheIndexAndFilterBlocks, bool, uint8
opt cacheIndexAndFilterBlocksWithHighPriority, bool, uint8
opt pinL0FilterAndIndexBlocksInCache, bool, uint8
opt pinTopLevelIndexAndFilter, bool, uint8
opt indexType, IndexType, cint
opt dataBlockIndexType, DataBlockIndexType, cint
opt dataBlockHashRatio, float, cdouble
opt noBlockCache, bool, uint8
opt blockSize, int, csize_t
opt blockSizeDeviation, int, cint
opt blockRestartInterval, int, cint
opt indexBlockRestartInterval, int, cint
opt metadataBlockSize, int, csize_t
opt partitionFilters, bool, uint8
opt optimizeFiltersForMemory, bool, uint8
opt useDeltaEncoding, bool, uint8
opt wholeKeyFiltering, bool, uint8
opt formatVersion, int, cint

proc `blockCache=`*(opts: TableOptionsRef, cache: CacheRef) =
  rocksdb_block_based_options_set_block_cache(opts.cPtr, cache.cPtr)

proc `filterPolicy=`*(opts: TableOptionsRef, policy: FilterPolicyRef) =
  rocksdb_block_based_options_set_filter_policy(opts.cPtr, policy.cPtr)

proc defaultTableOptions*(): TableOptionsRef =
  # https://github.com/facebook/rocksdb/wiki/Setup-Options-and-Basic-Tuning#other-general-options
  let opts = createTableOptions()
  opts.blockSize = 16 * 1024
  opts.cacheIndexAndFilterBlocks = true
  opts.pinL0FilterAndIndexBlocksInCache = true
  opts
