import
  ../lib/librocksdb,
  ./cache

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
    binarySearchAndHash = rocksdb_block_based_table_data_block_index_type_binary_search_and_hash

proc createRibbon*(bitsPerKey: float): FilterPolicyRef =
  FilterPolicyRef(cPtr: rocksdb_filterpolicy_create_ribbon(bitsPerKey))

proc createRibbonHybrid*(bitsPerKey: float, bloomBeforeLevel: int = 0): FilterPolicyRef =
  FilterPolicyRef(cPtr: rocksdb_filterpolicy_create_ribbon_hybrid(bitsPerKey, bloomBeforeLevel.cint))

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

# TODO there's _a lot_ of options to set - here we expose a select few..

proc setBlockSize*(opts: TableOptionsRef, size: int) =
  rocksdb_block_based_options_set_block_size(opts.cPtr, size.csize_t)

proc setBlockCache*(opts: TableOptionsRef, cache: CacheRef) =
  rocksdb_block_based_options_set_block_cache(opts.cPtr, cache.cPtr)

proc setFormatVersion*(opts: TableOptionsRef, version: int) =
  rocksdb_block_based_options_set_format_version(opts.cPtr, version.cint)

proc setCacheIndexAndFilterBlocks*(opts: TableOptionsRef, value: bool) =
  rocksdb_block_based_options_set_cache_index_and_filter_blocks(opts.cPtr, value.uint8)

proc setPinL0FilterAndIndexBlocksInCache*(opts: TableOptionsRef, value: bool) =
  rocksdb_block_based_options_set_pin_l0_filter_and_index_blocks_in_cache(opts.cPtr, value.uint8)

proc setPinTopLevelIndexAndFilter*(opts: TableOptionsRef, value: bool) =
  rocksdb_block_based_options_set_pin_top_level_index_and_filter(opts.cPtr, value.uint8)

proc setCacheIndexAndFilterBlocksWithHighPriority*(opts: TableOptionsRef, value: bool) =
  rocksdb_block_based_options_set_cache_index_and_filter_blocks_with_high_priority(opts.cPtr, value.uint8)

proc setFilterPolicy*(opts: TableOptionsRef, policy: FilterPolicyRef) =
  rocksdb_block_based_options_set_filter_policy(opts.cPtr, policy.cPtr)

proc setIndexType*(opts: TableOptionsRef, typ: IndexType) =
  rocksdb_block_based_options_set_index_type(opts.cPtr, typ.cint)

proc setPartitionFilters*(opts: TableOptionsRef, value: bool) =
  rocksdb_block_based_options_set_partition_filters(opts.cPtr, value.uint8)

proc setDataBlockIndexType*(opts: TableOptionsRef, value: DataBlockIndexType) =
  rocksdb_block_based_options_set_data_block_index_type(opts.cPtr, value.cint)

proc setDataBlockHashRatio*(opts: TableOptionsRef, value: float) =
  rocksdb_block_based_options_set_data_block_hash_ratio(opts.cPtr, value.cdouble)

proc defaultTableOptions*(): TableOptionsRef =
  # https://github.com/facebook/rocksdb/wiki/Setup-Options-and-Basic-Tuning#other-general-options
  let opts = createTableOptions()
  opts.setBlockSize(16*1024)
  opts.setCacheIndexAndFilterBlocks(true)
  opts.setPinL0FilterAndIndexBlocksInCache(true)
  opts.setFormatVersion(5)
  opts
