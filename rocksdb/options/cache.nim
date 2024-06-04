import
  ../lib/librocksdb

type
  CachePtr* = ptr rocksdb_cache_t

  CacheRef* = ref object
    cPtr*: CachePtr

proc cacheCreateLRU*(size: int): CacheRef =
  # TODO do you release it?
  CacheRef(cPtr: rocksdb_cache_create_lru(size.csize_t))

proc close*(cache: CacheRef) =
  if cache.cPtr != nil:
    rocksdb_cache_destroy(cache.cPtr)
    cache.cPtr = nil
