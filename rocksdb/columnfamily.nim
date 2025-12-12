# Nim-RocksDB
# Copyright 2024 Status Research & Development GmbH
# Licensed under either of
#
#  * Apache License, version 2.0, ([LICENSE-APACHE](LICENSE-APACHE) or http://www.apache.org/licenses/LICENSE-2.0)
#  * GPL license, version 2.0, ([LICENSE-GPLv2](LICENSE-GPLv2) or https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)
#
# at your option. This file may not be copied, modified, or distributed except according to those terms.

## `ColFamilyReadOnly` and `ColFamilyReadWrite` types both hold a reference to a
## `RocksDbReadOnlyRef` or `RocksDbReadWriteRef` respectively. They are convenience
## types which enable writing to a specific column family without having to specify the
## column family in each call.
##
## These column family types do not own the underlying `RocksDbRef` and therefore
## to close the database, simply call `columnFamily.db.close()` which will close
## the underlying `RocksDbRef`. Note that doing so will also impact any other column
## families that hold a reference to the same `RocksDbRef`.

{.push raises: [].}

import ./rocksdb
import ./columnfamily/cfhandle, ./rocksdb

export rocksdb

type
  ColFamilyReadOnly* = object
    db: RocksDbReadOnlyRef
    name: string
    handle: ColFamilyHandleRef

  ColFamilyReadWrite* = object
    db: RocksDbReadWriteRef
    name: string
    handle: ColFamilyHandleRef

proc getColFamily*(
    db: RocksDbReadOnlyRef, name: string
): RocksDBResult[ColFamilyReadOnly] =
  ## Creates a new `ColFamilyReadOnly` from the given `RocksDbReadOnlyRef` and
  ## column family name.
  doAssert not db.isClosed()

  ok(ColFamilyReadOnly(db: db, name: name, handle: ?db.getColFamilyHandle(name)))

proc getColFamily*(
    db: RocksDbReadWriteRef, name: string
): RocksDBResult[ColFamilyReadWrite] =
  ## Create a new `ColFamilyReadWrite` from the given `RocksDbReadWriteRef` and
  ## column family name.
  doAssert not db.isClosed()

  ok(ColFamilyReadWrite(db: db, name: name, handle: ?db.getColFamilyHandle(name)))

template db*(cf: ColFamilyReadOnly | ColFamilyReadWrite): auto =
  ## Returns the underlying `RocksDbReadOnlyRef` or `RocksDbReadWriteRef`.
  cf.db

template name*(cf: ColFamilyReadOnly | ColFamilyReadWrite): string =
  ## Returns the name of the column family.
  cf.name

template handle*(cf: ColFamilyReadOnly | ColFamilyReadWrite): ColFamilyHandleRef =
  ## Returns the name of the column family.
  cf.handle

template get*(
    cf: ColFamilyReadOnly | ColFamilyReadWrite, key: openArray[byte], onData: DataProc
): RocksDBResult[bool] =
  ## Gets the value of the given key from the column family using the `onData`
  ## callback.
  cf.db.get(key, onData, cf.handle)

template get*(
    cf: ColFamilyReadOnly | ColFamilyReadWrite, key: openArray[byte]
): RocksDBResult[seq[byte]] =
  ## Gets the value of the given key from the column family.
  cf.db.get(key, cf.handle)

template multiGetIter*(
    cf: ColFamilyReadOnly | ColFamilyReadWrite,
    keys: openArray[seq[byte]],
    sortedInput = false,
): RocksDBResult[MultiGetIteratorRef] =
  ## Get a batch of values for the given set of keys.
  cf.db.multiGetIter(keys, sortedInput, cf.handle)

template multiGet*(
    cf: ColFamilyReadOnly | ColFamilyReadWrite,
    keys: openArray[seq[byte]],
    sortedInput = false,
): RocksDBResult[seq[Opt[seq[byte]]]] =
  ## Get a batch of values for the given set of keys.
  cf.db.multiGet(keys, sortedInput, cf.handle)

template put*(cf: ColFamilyReadWrite, key, val: openArray[byte]): RocksDBResult[void] =
  ## Puts a value for the given key into the column family.
  cf.db.put(key, val, cf.handle)

template keyExists*(
    cf: ColFamilyReadOnly | ColFamilyReadWrite, key: openArray[byte]
): RocksDBResult[bool] =
  ## Checks if the given key exists in the column family.
  cf.db.keyExists(key, cf.handle)

template delete*(cf: ColFamilyReadWrite, key: openArray[byte]): RocksDBResult[void] =
  ## Deletes the given key from the column family.
  cf.db.delete(key, cf.handle)

template deleteRange*(
    cf: ColFamilyReadWrite, startKey, endKey: openArray[byte]
): RocksDBResult[void] =
  ## Deletes the given key range from the column family including startKey and
  ## excluding endKey.
  cf.db.deleteRange(startKey, endKey, cf.handle)

template compactRange*(
    cf: ColFamilyReadWrite, startKey, endKey: openArray[byte]
): RocksDBResult[void] =
  ## Trigger range compaction for the given key range.
  cf.db.compactRange(startKey, endKey, cf.handle)

template suggestCompactRange*(
    cf: ColFamilyReadWrite, startKey, endKey: openArray[byte]
): RocksDBResult[void] =
  ## Suggest the range to compact.
  cf.db.suggestCompactRange(startKey, endKey, cf.handle)

template openIterator*(
    cf: ColFamilyReadOnly | ColFamilyReadWrite,
    readOpts = defaultReadOptions(autoClose = true),
): RocksDBResult[RocksIteratorRef] =
  ## Opens an `RocksIteratorRef` for the given column family.
  cf.db.openIterator(readOpts, cf.handle)

template openWriteBatch*(cf: ColFamilyReadWrite): WriteBatchRef =
  ## Opens a `WriteBatchRef` for the given column family.
  cf.db.openWriteBatch(cf.handle)

template openWriteBatchWithIndex*(
    cf: ColFamilyReadWrite, reservedBytes = 0, overwriteKey = false
): WriteBatchWIRef =
  ## Opens a `WriteBatchRef` for the given column family.
  cf.db.openWriteBatchWithIndex(reservedBytes, overwriteKey, cf.handle)

template write*(
    cf: ColFamilyReadWrite, updates: WriteBatchRef | WriteBatchWIRef
): RocksDBResult[void] =
  ## Writes the updates in the `WriteBatchRef` to the column family.
  cf.db.write(updates)
