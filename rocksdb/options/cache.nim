import ../lib/librocksdb

type
  CachePtr* = ptr rocksdb_cache_t

  CacheRef* = ref object
    cPtr*: CachePtr
    autoClose*: bool # if true then close will be called when the parent type is closed

proc cacheCreateLRU*(size: int, autoClose = false): CacheRef =
  CacheRef(cPtr: rocksdb_cache_create_lru(size.csize_t), autoClose: autoClose)

proc close*(cache: CacheRef) =
  if cache.cPtr != nil:
    rocksdb_cache_destroy(cache.cPtr)
    cache.cPtr = nil
