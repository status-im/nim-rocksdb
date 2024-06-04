import
  ../lib/librocksdb,
  ./cache

type
  # TODO might eventually wrap this
  TableOptionsPtr* = ptr rocksdb_block_based_table_options_t

  TableOptionsRef* = ref object
    cPtr*: TableOptionsPtr

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

proc defaultTableOptions*(): TableOptionsRef =
  # https://github.com/facebook/rocksdb/wiki/Setup-Options-and-Basic-Tuning#other-general-options
  let opts = createTableOptions()
  opts.setBlockSize(16*1024)
  opts.setCacheIndexAndFilterBlocks(true)
  opts.setPinL0FilterAndIndexBlocksInCache(true)
  opts.setFormatVersion(5)
  opts
