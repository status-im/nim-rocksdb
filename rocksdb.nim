# Nim-RocksDB
# Copyright 2018 Status Research & Development GmbH
# Licensed under either of
#
#  * Apache License, version 2.0, ([LICENSE-APACHE](LICENSE-APACHE) or http://www.apache.org/licenses/LICENSE-2.0)
#  * GPL license, version 2.0, ([LICENSE-GPLv2](LICENSE-GPLv2) or https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)
#
# at your option. This file may not be copied, modified, or distributed except according to those terms.

import cpuinfo, options, ranges

const useCApi = true

when useCApi:
  import rocksdb/librocksdb
  export librocksdb

  template managedResource(name) =
    template freeResource(r: ptr `rocksdb name t`) =
      `rocksdb name destroy`(r)

  managedResource(WriteOptions)
  managedResource(ReadOptions)

  type
    RocksPtr[T] = object
      res: ptr T

  import typetraits

  when false:
    # XXX: generic types cannot have destructors at the moment:
    # https://github.com/nim-lang/Nim/issues/5366
    proc `=destroy`*[T](rocksPtr: var RocksPtr[T]) =
      freeResource rocksPtr.res

  proc toRocksPtr[T](res: ptr T): RocksPtr[T] =
    result.res = res

  template initResource(resourceName): auto =
    var p = toRocksPtr(`rocksdb resourceName create`())
    # XXX: work-around the destructor issue above:
    defer: freeResource p.res
    p.res
else:
  {.error: "The C++ API of RocksDB is not supported yet".}

  # The intention of this template is that it will hide the
  # difference between the C and C++ APIs for objects such
  # as Read/WriteOptions, which are allocated either on the
  # stack or the heap.
  template initResource(resourceName) =
    var res = resourceName()
    res

type
  # TODO: Replace this with a converter concept that will
  # handle openarray[char] and openarray[byte] in the same way.
  KeyValueType = openarray[byte]

  RocksDBInstance* = object
    db: ptr rocksdb_t
    backupEngine: ptr rocksdb_backup_engine_t
    options: ptr rocksdb_options_t

  RocksDBResult*[T] = object
    case ok*: bool
    of true:
      when T isnot void: value*: T
    else:
      error*: string

proc `$`*(s: RocksDBResult): string =
  if s.ok:
    $s.value
  else:
    "(error) " & s.error

template returnOk() =
  result.ok = true
  return

template returnVal(v: auto) =
  result.ok = true
  result.value = v
  return

template bailOnErrors {.dirty.} =
  if not errors.isNil:
    result.ok = false
    result.error = $(errors[0])
    return

proc init*(rocks: var RocksDBInstance,
           dbPath, dbBackupPath: string,
           cpus = countProcessors(),
           createIfMissing = true): RocksDBResult[void] =
  rocks.options = rocksdb_options_create()

  # Optimize RocksDB. This is the easiest way to get RocksDB to perform well:
  rocksdb_options_increase_parallelism(rocks.options, cpus.int32)
  rocksdb_options_optimize_level_style_compaction(rocks.options, 0)
  rocksdb_options_set_create_if_missing(rocks.options, uint8(createIfMissing))

  var errors: cstringArray
  rocks.db = rocksdb_open(rocks.options, dbPath, errors)
  bailOnErrors()
  rocks.backupEngine = rocksdb_backup_engine_open(rocks.options,
                                                  dbBackupPath, errors)
  bailOnErrors()
  returnOk()

template initRocksDB*(args: varargs[untyped]): Option[RocksDBInstance] =
  var db: RocksDBInstance
  if not init(db, args):
    none(RocksDBInstance)
  else:
    some(db)

when false:
  # TODO: These should be in the standard lib somewhere.
  proc to*(chars: openarray[char], S: typedesc[string]): string =
    result = newString(chars.len)
    copyMem(addr result[0], unsafeAddr chars[0], chars.len * sizeof(char))

  proc to*(chars: openarray[char], S: typedesc[seq[byte]]): seq[byte] =
    result = newSeq[byte](chars.len)
    copyMem(addr result[0], unsafeAddr chars[0], chars.len * sizeof(char))

  template toOpenArray*[T](p: ptr T, sz: int): openarray[T] =
    # XXX: The `TT` type is a work-around the fact that the `T`
    # generic param is not resolved properly within the body of
    # the template: https://github.com/nim-lang/Nim/issues/7995
    type TT = type(p[])
    let arr = cast[ptr UncheckedArray[TT]](p)
    toOpenArray(arr[], 0, sz)
else:
  proc copyFrom(v: var seq[byte], data: cstring, sz: int) =
    v = newSeq[byte](sz)
    if sz > 0:
      copyMem(addr v[0], unsafeAddr data[0], sz)

  proc copyFrom(v: var string, data: cstring, sz: int) =
    v = newString(sz)
    if sz > 0:
      copyMem(addr v[0], unsafeAddr data[0], sz)

template getImpl {.dirty.} =
  assert key.len > 0

  var
    options = initResource ReadOptions
    errors: cstringArray
    len: csize
    data = rocksdb_get(db.db, options,
                       cast[cstring](unsafeAddr key[0]), key.len,
                       addr len, errors)
  bailOnErrors()
  result.ok = true
  result.value.copyFrom(data, len)
  # returnVal toOpenArray(cast[ptr char](data), len).to(type(result.value))

proc get*(db: RocksDBInstance, key: KeyValueType): RocksDBResult[string] =
  getImpl

proc getBytes*(db: RocksDBInstance, key: KeyValueType): RocksDBResult[seq[byte]] =
  getImpl

proc put*(db: RocksDBInstance, key, val: KeyValueType): RocksDBResult[void] =
  assert key.len > 0

  var
    options = initResource WriteOptions
    errors: cstringArray

  rocksdb_put(db.db, options,
              cast[cstring](unsafeAddr key[0]), key.len,
              cast[cstring](if val.len > 0: unsafeAddr val[0] else: nil), val.len,
              errors)

  bailOnErrors()
  returnOk()

proc del*(db: RocksDBInstance, key: KeyValueType): RocksDBResult[void] =
  when false:
    # XXX: For yet unknown reasons, the code below fails with SIGSEGV.
    # Investigate if this the correct usage of `rocksdb_delete`.
    var options = initResource WriteOptions
    var errors: cstringArray
    echo key.len
    rocksdb_delete(db.db, options,
                   cast[cstring](unsafeAddr key[0]), key.len,
                   errors)
    bailOnErrors()
    returnOk()
  else:
    put(db, key, @[])

proc contains*(db: RocksDBInstance, key: KeyValueType): RocksDBResult[bool] =
  assert key.len > 0

  let res = db.get(key)
  if res.ok:
    returnVal res.value.len > 0
  else:
    result.ok = false
    result.error = res.error

proc backup*(db: RocksDBInstance): RocksDBResult[void] =
  var errors: cstringArray
  rocksdb_backup_engine_create_new_backup(db.backupEngine, db.db, errors)
  bailOnErrors()
  returnOk()

# XXX: destructors are just too buggy at the moment:
# https://github.com/nim-lang/Nim/issues/8112
# proc `=destroy`*(db: var RocksDBInstance) =
proc close*(db: var RocksDBInstance) =
  if db.backupEngine != nil:
    rocksdb_backup_engine_close(db.backupEngine)
    db.backupEngine = nil

  if db.db != nil:
    rocksdb_close(db.db)
    db.db = nil

  if db.options != nil:
    rocksdb_options_destroy(db.options)
    db.options = nil

