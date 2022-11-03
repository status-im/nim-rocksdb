# Nim-RocksDB
# Copyright 2018 Status Research & Development GmbH
# Licensed under either of
#
#  * Apache License, version 2.0, ([LICENSE-APACHE](LICENSE-APACHE) or http://www.apache.org/licenses/LICENSE-2.0)
#  * GPL license, version 2.0, ([LICENSE-GPLv2](LICENSE-GPLv2) or https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)
#
# at your option. This file may not be copied, modified, or distributed except according to those terms.

{.push raises: [Defect].}

import cpuinfo, options, stew/[byteutils, results]

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
  RocksDBInstance* = object
    db*: rocksdb_t
    backupEngine: rocksdb_backup_engine_t
    options*: rocksdb_options_t
    readOptions*: rocksdb_readoptions_t
    writeOptions: rocksdb_writeoptions_t

  DataProc* = proc(val: openArray[byte]) {.gcsafe, raises: [Defect].}

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

proc get*(db: RocksDBInstance, key: openArray[byte], onData: DataProc): RocksDBResult[bool] =
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
    # TODO onData may raise a Defect - in theory we could catch it and free the
    #      memory but this has a small overhead - setjmp (C) or RTTI (C++) -
    #      reconsider this once the exception dust settles
    onData(toOpenArrayByte(data, 0, int(len) - 1))
    rocksdb_free(data)
    ok(true)
  else:
    ok(false)

proc get*(db: RocksDBInstance, key: openArray[byte]): RocksDBResult[string] {.deprecated: "DataProc".} =
  ## Get value for `key`. If no value exists, set `result.ok` to `false`,
  ## and result.error to `""`.
  var res: RocksDBResult[string]
  proc onData(data: openArray[byte]) =
    res.ok(string.fromBytes(data))

  if ? db.get(key, onData):
    res
  else:
    ok("")

proc getBytes*(db: RocksDBInstance, key: openArray[byte]): RocksDBResult[seq[byte]]  {.deprecated: "DataProc".} =
  ## Get value for `key`. If no value exists, set `result.ok` to `false`,
  ## and result.error to `""`.
  var res: RocksDBResult[seq[byte]]
  proc onData(data: openArray[byte]) =
    res.ok(@data)

  if ? db.get(key, onData):
    res
  else:
    err("")

proc put*(db: RocksDBInstance, key, val: openArray[byte]): RocksDBResult[void] =
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

proc del*(db: RocksDBInstance, key: openArray[byte]): RocksDBResult[void] =
  if key.len <= 0:
    return err("rocksdb: key cannot be empty on del")

  var errors: cstring
  rocksdb_delete(db.db, db.writeOptions,
                  cast[cstring](unsafeAddr key[0]), csize_t(key.len),
                  errors.addr)
  bailOnErrors()
  ok()

proc contains*(db: RocksDBInstance, key: openArray[byte]): RocksDBResult[bool] =
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
      db.`name` = typeof(db.`name`)(nil)
  freeField(writeOptions)
  freeField(readOptions)
  freeField(options)

  if not db.backupEngine.isNil:
    rocksdb_backup_engine_close(db.backupEngine)
    db.backupEngine = nil

  if not db.db.isNil:
    rocksdb_close(db.db)
    db.db = nil
