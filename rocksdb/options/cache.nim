import
  ../lib/librocksdb

type
  CachePtr* = ptr rocksdb_cache_t

  CacheRef* = ref object
    cPtr*: CachePtr

proc cacheCreateLRU*(size: int): CacheRef =
  # TODO do you release it?
  CacheRef(cPtr: rocksdb_cache_create_lru(size.csize_t))
