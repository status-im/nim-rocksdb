# Nim-RocksDB
# Copyright 2024 Status Research & Development GmbH
# Licensed under either of
#
#  * Apache License, version 2.0, ([LICENSE-APACHE](LICENSE-APACHE) or http://www.apache.org/licenses/LICENSE-2.0)
#  * GPL license, version 2.0, ([LICENSE-GPLv2](LICENSE-GPLv2) or https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)
#
# at your option. This file may not be copied, modified, or distributed except according to those terms.

## A `MemoryConsumersRef` is used to collect approximate memory usage from a
## set of RocksDB databases and/or block caches using the RocksDB MemoryUtil
## C API (`rocksdb_memory_consumers_*`).
##
## Typical usage:
## ```nim
## let consumers = createMemoryConsumers()
## consumers.addDb(db)
## consumers.addCache(cache) # optional
## let usage = consumers.getApproximateMemoryUsage().valueOr:
##   echo "error: ", error
##   return
## echo "memtable total: ", usage.memTableTotal()
## usage.close()
## consumers.close()
## ```

{.push raises: [].}

import ./lib/librocksdb, ./internal/utils, ./options/cache, ./rocksdb, ./rocksresult

export cache, rocksdb, rocksresult

type
  MemoryConsumersPtr* = ptr rocksdb_memory_consumers_t
  MemoryUsagePtr* = ptr rocksdb_memory_usage_t

  MemoryConsumersRef* = ref object
    ## A set of RocksDB databases and caches whose memory usage can be sampled
    ## together via `getApproximateMemoryUsage`.
    cPtr: MemoryConsumersPtr

  MemoryUsageRef* = ref object
    ## An approximate memory usage snapshot. Call `close` when done to free
    ## the underlying resources.
    cPtr: MemoryUsagePtr

# ------------------------------------------------------------------------------
# MemoryConsumersRef
# ------------------------------------------------------------------------------

proc createMemoryConsumers*(): MemoryConsumersRef =
  ## Create a new, empty memory consumer set.
  ## Call `addDb` and/or `addCache` to register consumers, then call
  ## `getApproximateMemoryUsage` to collect a snapshot.
  MemoryConsumersRef(cPtr: rocksdb_memory_consumers_create())

template isClosed*(consumers: MemoryConsumersRef): bool =
  ## Returns `true` if the `MemoryConsumersRef` has been closed.
  consumers.cPtr.isNil()

proc addDb*(consumers: MemoryConsumersRef, db: RocksDbRef) =
  ## Register a RocksDB database instance as a memory consumer.
  ## The `db` must remain open for the lifetime of any usage snapshot created
  ## from this consumer set.
  doAssert not consumers.isClosed()
  doAssert not db.isClosed()
  rocksdb_memory_consumers_add_db(consumers.cPtr, db.cPtr)

proc addCache*(consumers: MemoryConsumersRef, cache: CacheRef) =
  ## Register a block cache as a memory consumer. This allows the cache's
  ## memory to be reported separately from mem table memory in the usage
  ## snapshot.
  ## The `cache` must remain open for the lifetime of any usage snapshot
  ## created from this consumer set.
  doAssert not consumers.isClosed()
  doAssert not cache.isClosed()
  rocksdb_memory_consumers_add_cache(consumers.cPtr, cache.cPtr)

proc getApproximateMemoryUsage*(
    consumers: MemoryConsumersRef
): RocksDBResult[MemoryUsageRef] =
  ## Collect an approximate memory usage snapshot from all registered databases
  ## and caches. The returned `MemoryUsageRef` must be closed when done.
  doAssert not consumers.isClosed()

  var errors: cstring
  let usagePtr = rocksdb_approximate_memory_usage_create(
    consumers.cPtr, cast[cstringArray](errors.addr)
  )
  bailOnErrors(errors)

  if usagePtr.isNil():
    return err("rocksdb: approximate memory usage returned nil")

  ok(MemoryUsageRef(cPtr: usagePtr))

proc close*(consumers: MemoryConsumersRef) =
  ## Free the memory consumer set.
  if not consumers.isClosed():
    rocksdb_memory_consumers_destroy(consumers.cPtr)
    consumers.cPtr = nil

# ------------------------------------------------------------------------------
# MemoryUsageRef
# ------------------------------------------------------------------------------

template isClosed*(usage: MemoryUsageRef): bool =
  ## Returns `true` if the `MemoryUsageRef` has been closed.
  usage.cPtr.isNil()

proc memTableTotal*(usage: MemoryUsageRef): uint64 =
  ## Approximate total memory held in all mem tables across registered DBs.
  doAssert not usage.isClosed()
  rocksdb_approximate_memory_usage_get_mem_table_total(usage.cPtr)

proc memTableUnflushed*(usage: MemoryUsageRef): uint64 =
  ## Approximate memory held in unflushed mem tables across registered DBs.
  doAssert not usage.isClosed()
  rocksdb_approximate_memory_usage_get_mem_table_unflushed(usage.cPtr)

proc memTableReadersTotal*(usage: MemoryUsageRef): uint64 =
  ## Approximate total memory held by all SST table readers across registered DBs.
  doAssert not usage.isClosed()
  rocksdb_approximate_memory_usage_get_mem_table_readers_total(usage.cPtr)

proc cacheTotal*(usage: MemoryUsageRef): uint64 =
  ## Approximate total memory held in all registered block caches.
  doAssert not usage.isClosed()
  rocksdb_approximate_memory_usage_get_cache_total(usage.cPtr)

proc close*(usage: MemoryUsageRef) =
  ## Free the memory usage snapshot.
  if not usage.isClosed():
    rocksdb_approximate_memory_usage_destroy(usage.cPtr)
    usage.cPtr = nil
