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
  ./rocksdb

export rocksdb

type
  ColFamilyReadOnly* = object
    db: RocksDbReadOnlyRef
    name: string

  ColFamilyReadWrite* = object
    db: RocksDbReadWriteRef
    name: string

proc withColFamily*(db: RocksDbReadOnlyRef, name: string): RocksDBResult[ColFamilyReadOnly] =
  # validate that the column family exists
  discard db.keyExists(@[0.byte], name).valueOr:
    return err(error)

  ok(ColFamilyReadOnly(db: db, name: name))

proc withColFamily*(db: RocksDbReadWriteRef, name: string): RocksDBResult[ColFamilyReadWrite] =
  # validate that the column family exists
  discard db.keyExists(@[0.byte], name).valueOr:
    return err(error)

  ok(ColFamilyReadWrite(db: db, name: name))

proc db*(cf: ColFamilyReadOnly | ColFamilyReadWrite): auto = cf.db

proc name*(cf: ColFamilyReadOnly | ColFamilyReadWrite): string = cf.name

proc get*(
    cf: ColFamilyReadOnly | ColFamilyReadWrite,
    key: openArray[byte],
    onData: DataProc): RocksDBResult[bool] = cf.db.get(key, onData, cf.name)

proc get*(
    cf: ColFamilyReadOnly | ColFamilyReadWrite,
    key: openArray[byte]): RocksDBResult[seq[byte]] = cf.db.get(key, cf.name)

proc put*(
    cf: ColFamilyReadWrite,
    key, val: openArray[byte]): RocksDBResult[void] = cf.db.put(key, val, cf.name)

proc keyExists*(
    cf: ColFamilyReadOnly | ColFamilyReadWrite,
    key: openArray[byte]): RocksDBResult[bool] = cf.db.keyExists(key, cf.name)

proc delete*(
    cf: ColFamilyReadWrite,
    key: openArray[byte]): RocksDBResult[void] = cf.db.delete(key, cf.name)

proc openIterator*(
    cf: ColFamilyReadOnly | ColFamilyReadWrite): RocksDBResult[RocksIteratorRef] =
  cf.db.openIterator(cf.name)

proc openWriteBatch*(cf: ColFamilyReadWrite): WriteBatchRef =
  cf.db.openWriteBatch(cf.name)

proc write*(cf: ColFamilyReadWrite, updates: WriteBatchRef): RocksDBResult[void] =
  cf.db.write(updates)

# To close the column family simply call:
# cf.db.close()
# which will close the underlying rocksdb instance
