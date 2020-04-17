# Nim-RocksDB
# Copyright 2018 Status Research & Development GmbH
# Licensed under either of
#
#  * Apache License, version 2.0, ([LICENSE-APACHE](LICENSE-APACHE) or http://www.apache.org/licenses/LICENSE-2.0)
#  * GPL license, version 2.0, ([LICENSE-GPLv2](LICENSE-GPLv2) or https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)
#
# at your option. This file may not be copied, modified, or distributed except according to those terms.

{.push raises: [Defect].}

import cpuinfo, options, stew/results

export results

const useCApi = true

when useCApi:
  import rocksdb/librocksdb
  export librocksdb

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
  # handle openArray[char] and openArray[byte] in the same way.
  KeyValueType = openArray[byte]

  RocksDBInstance* = object
    db: rocksdb_t
    backupEngine: rocksdb_backup_engine_t
    options: rocksdb_options_t
    readOptions: rocksdb_readoptions_t
    writeOptions: rocksdb_writeoptions_t

  RocksDBResult*[T] = Result[T, string]

template bailOnErrors {.dirty.} =
  if not errors.isNil:
    result.err($errors)
    rocksdb_free(errors)
    return

proc init*(rocks: var RocksDBInstance,
           dbPath, dbBackupPath: string,
           readOnly = false,
           cpus = countProcessors(),
           createIfMissing = true,
           maxOpenFiles = -1): RocksDBResult[void] =
  rocks.options = rocksdb_options_create()
  rocks.readOptions = rocksdb_readoptions_create()
  rocks.writeOptions = rocksdb_writeoptions_create()

  # Optimize RocksDB. This is the easiest way to get RocksDB to perform well:
  rocksdb_options_increase_parallelism(rocks.options, cpus.int32)
  # This requires snappy - disabled because rocksdb is not always compiled with
  # snappy support (for example Fedora 28, certain Ubuntu versions)
  # rocksdb_options_optimize_level_style_compaction(options, 0);
  rocksdb_options_set_create_if_missing(rocks.options, uint8(createIfMissing))
  # default set to keep all files open (-1), allow setting it to a specific
  # value, e.g. in case the application limit would be reached.
  rocksdb_options_set_max_open_files(rocks.options, maxOpenFiles.cint)

  var errors: cstring
  if readOnly:
    rocks.db = rocksdb_open_for_read_only(rocks.options, dbPath, 0'u8, errors.addr)
  else:
    rocks.db = rocksdb_open(rocks.options, dbPath, errors.addr)
  bailOnErrors()
  rocks.backupEngine = rocksdb_backup_engine_open(rocks.options,
                                                  dbBackupPath, errors.addr)
  bailOnErrors()
  ok()

template initRocksDB*(args: varargs[untyped]): Option[RocksDBInstance] =
  var db: RocksDBInstance
  if not init(db, args):
    none(RocksDBInstance)
  else:
    some(db)

# TODO: These should be in the standard lib somewhere.
proc to(chars: openArray[char], S: typedesc[string]): string =
  result = newString(chars.len)
  copyMem(addr result[0], unsafeAddr chars[0], chars.len * sizeof(char))

proc to(chars: openArray[char], S: typedesc[seq[byte]]): seq[byte] =
  result = newSeq[byte](chars.len)
  copyMem(addr result[0], unsafeAddr chars[0], chars.len * sizeof(char))

template getImpl(T: type) {.dirty.} =
  if key.len <= 0:
    return err("rocksdb: key cannot be empty on get")

  var
    errors: cstring
    len: csize_t
    data = rocksdb_get(db.db, db.readOptions,
                       cast[cstring](unsafeAddr key[0]), csize_t(key.len),
                       addr len, addr errors)
  bailOnErrors()
  if not data.isNil:
    result = ok(toOpenArray(data, 0, int(len) - 1).to(T))
    rocksdb_free(data)
  else:
    result = err("")

proc get*(db: RocksDBInstance, key: KeyValueType): RocksDBResult[string] =
  ## Get value for `key`. If no value exists, set `result.ok` to `false`,
  ## and result.error to `""`.
  getImpl(string)

proc getBytes*(db: RocksDBInstance, key: KeyValueType): RocksDBResult[seq[byte]] =
  ## Get value for `key`. If no value exists, set `result.ok` to `false`,
  ## and result.error to `""`.
  getImpl(seq[byte])

proc put*(db: RocksDBInstance, key, val: KeyValueType): RocksDBResult[void] =
  if key.len <= 0:
    return err("rocksdb: key cannot be empty on put")

  var
    errors: cstring

  rocksdb_put(db.db, db.writeOptions,
              cast[cstring](unsafeAddr key[0]), csize_t(key.len),
              cast[cstring](if val.len > 0: unsafeAddr val[0] else: nil),
              csize_t(val.len),
              errors.addr)

  bailOnErrors()
  ok()

proc del*(db: RocksDBInstance, key: KeyValueType): RocksDBResult[void] =
  if key.len <= 0:
    return err("rocksdb: key cannot be empty on del")

  var errors: cstring
  rocksdb_delete(db.db, db.writeOptions,
                  cast[cstring](unsafeAddr key[0]), csize_t(key.len),
                  errors.addr)
  bailOnErrors()
  ok()

proc contains*(db: RocksDBInstance, key: KeyValueType): RocksDBResult[bool] =
  if key.len <= 0:
    return err("rocksdb: key cannot be empty on contains")

  var
    errors: cstring
    len: csize_t
    data = rocksdb_get(db.db, db.readOptions,
                       cast[cstring](unsafeAddr key[0]), csize_t(key.len),
                       addr len, errors.addr)
  bailOnErrors()
  if not data.isNil:
    rocksdb_free(data)
    ok(true)
  else:
    ok(false)

proc backup*(db: RocksDBInstance): RocksDBResult[void] =
  var errors: cstring
  rocksdb_backup_engine_create_new_backup(db.backupEngine, db.db, errors.addr)
  bailOnErrors()
  ok()

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
