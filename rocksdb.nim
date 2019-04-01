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

  type
    RocksPtr[T] = object
      res: T

  import typetraits

  when false:
    # XXX: generic types cannot have destructors at the moment:
    # https://github.com/nim-lang/Nim/issues/5366
      template managedResource(name) =
        template freeResource(r: `rocksdb name t`) =
          `rocksdb name destroy`(r)

      managedResource(WriteOptions)
      managedResource(ReadOptions)
      template initResource(resourceName): auto =
        var p = toRocksPtr(`rocksdb resourceName create`())
        # XXX: work-around the destructor issue above:
        # XXX: work-around disabled - it frees the resource too early - need to
        #      free resource manually!
        # defer: freeResource p.res
        p.res

      proc `=destroy`*[T](rocksPtr: var RocksPtr[T]) =
        freeResource rocksPtr.res

      proc toRocksPtr[T](res: T): RocksPtr[T] =
        result.res = res

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
    db: rocksdb_t
    backupEngine: rocksdb_backup_engine_t
    options: rocksdb_options_t
    readOptions: rocksdb_readoptions_t
    writeOptions: rocksdb_writeoptions_t

  RocksDBResult*[T] = object
    case ok*: bool
    of true:
      when T isnot void: value*: T
    else:
      error*: string

proc `$`*[T](s: RocksDBResult[T]): string =
  if s.ok:
    when T isnot void:
      $s.value
    else:
      ""
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
    result.error = $errors
    rocksdb_free(errors)
    return

proc init*(rocks: var RocksDBInstance,
           dbPath, dbBackupPath: string,
           readOnly = false,
           cpus = countProcessors(),
           createIfMissing = true): RocksDBResult[void] =
  rocks.options = rocksdb_options_create()
  rocks.readOptions = rocksdb_readoptions_create()
  rocks.writeOptions = rocksdb_writeoptions_create()

  # Optimize RocksDB. This is the easiest way to get RocksDB to perform well:
  rocksdb_options_increase_parallelism(rocks.options, cpus.int32)
  # This requires snappy - disabled because rocksdb is not always compiled with
  # snappy support (for example Fedora 28, certain Ubuntu versions)
  # rocksdb_options_optimize_level_style_compaction(options, 0);
  rocksdb_options_set_create_if_missing(rocks.options, uint8(createIfMissing))

  var errors: cstring
  if readOnly:
    rocks.db = rocksdb_open_for_read_only(rocks.options, dbPath, 0'u8, errors.addr)
  else:
    rocks.db = rocksdb_open(rocks.options, dbPath, errors.addr)
  bailOnErrors()
  rocks.backupEngine = rocksdb_backup_engine_open(rocks.options,
                                                  dbBackupPath, errors.addr)
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
  doAssert key.len > 0

  var
    errors: cstring
    len: csize
    data = rocksdb_get(db.db, db.readOptions,
                       cast[cstring](unsafeAddr key[0]), key.len,
                       addr len, errors.addr)
  bailOnErrors()
  if not data.isNil:
    result.ok = true
    result.value.copyFrom(data, len)
    rocksdb_free(data)
  else:
    result.error = $errors

proc get*(db: RocksDBInstance, key: KeyValueType): RocksDBResult[string] =
  ## Get value for `key`. If no value exists, set `result.ok` to `false`,
  ## and result.error to `""`.
  getImpl

proc getBytes*(db: RocksDBInstance, key: KeyValueType): RocksDBResult[seq[byte]] =
  ## Get value for `key`. If no value exists, set `result.ok` to `false`,
  ## and result.error to `""`.
  getImpl

proc put*(db: RocksDBInstance, key, val: KeyValueType): RocksDBResult[void] =
  doAssert key.len > 0

  var
    errors: cstring

  rocksdb_put(db.db, db.writeOptions,
              cast[cstring](unsafeAddr key[0]), key.len,
              cast[cstring](if val.len > 0: unsafeAddr val[0] else: nil), val.len,
              errors.addr)

  bailOnErrors()
  returnOk()

proc del*(db: RocksDBInstance, key: KeyValueType): RocksDBResult[void] =
  var errors: cstring
  rocksdb_delete(db.db, db.writeOptions,
                  cast[cstring](unsafeAddr key[0]), key.len,
                  errors.addr)
  bailOnErrors()
  returnOk()

proc contains*(db: RocksDBInstance, key: KeyValueType): RocksDBResult[bool] =
  doAssert key.len > 0

  var
    errors: cstring
    len: csize
    data = rocksdb_get(db.db, db.readOptions,
                       cast[cstring](unsafeAddr key[0]), key.len,
                       addr len, errors.addr)
  bailOnErrors()
  result.ok = true
  if not data.isNil:
    result.value = true
    rocksdb_free(data)

proc backup*(db: RocksDBInstance): RocksDBResult[void] =
  var errors: cstring
  rocksdb_backup_engine_create_new_backup(db.backupEngine, db.db, errors.addr)
  bailOnErrors()
  returnOk()

# XXX: destructors are just too buggy at the moment:
# https://github.com/nim-lang/Nim/issues/8112
# proc `=destroy`*(db: var RocksDBInstance) =
proc close*(db: var RocksDBInstance) =
  template freeField(name) =
    if db.`name`.isNil:
      `rocksdb name destroy`(db.`name`)
      db.`name` = nil
  freeField(writeOptions)
  freeField(readOptions)
  freeField(options)

  if not db.backupEngine.isNil:
    rocksdb_backup_engine_close(db.backupEngine)
    db.backupEngine = nil

  if not db.db.isNil:
    rocksdb_close(db.db)
    db.db = nil
