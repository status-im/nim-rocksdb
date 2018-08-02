# Nim-RocksDB
# Copyright 2018 Status Research & Development GmbH
# Licensed under either of
#
#  * Apache License, version 2.0, ([LICENSE-APACHE](LICENSE-APACHE) or http://www.apache.org/licenses/LICENSE-2.0)
#  * GPL license, version 2.0, ([LICENSE-GPLv2](LICENSE-GPLv2) or https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)
#
# at your option. This file may not be copied, modified, or distributed except according to those terms.

import  ../rocksdb,
        unittest, cpuinfo

suite "RocksDB C wrapper tests":
  test "Simple create-update-close example":
    const
      dbPath: cstring = "/tmp/rocksdb_simple_example"
      dbBackupPath: cstring = "/tmp/rocksdb_simple_example_backup"

    var
      db: rocksdb_t
      be: rocksdb_backup_engine_t
      options = rocksdb_options_create()

    let cpus = countProcessors()
    rocksdb_options_increase_parallelism(options, cpus.int32)
    rocksdb_options_optimize_level_style_compaction(options, 0);
    # create the DB if it's not already present
    rocksdb_options_set_create_if_missing(options, 1);

    # open DB
    var err: cstringArray
    db = rocksdb_open(options, dbPath, err)
    check: err.isNil

    # open Backup Engine that we will use for backing up our database
    be = rocksdb_backup_engine_open(options, dbBackupPath, err)
    check: err.isNil

    # Put key-value
    var writeOptions = rocksdb_writeoptions_create()
    let key = "key"
    let put_value = "value"
    rocksdb_put(db, writeOptions, key.cstring, key.len, put_value.cstring, put_value.len, err)
    check: err.isNil

    # Get value
    var readOptions = rocksdb_readoptions_create()
    var len: csize
    let raw_value = rocksdb_get(db, readOptions, key, key.len, addr len, err) # Important: rocksdb_get is not null-terminated
    check: err.isNil

    # Copy it to a regular Nim string (copyMem workaround because non-null terminated)
    var get_value = newString(len)
    copyMem(addr get_value[0], unsafeAddr raw_value[0], len * sizeof(char))

    check: $get_value == $put_value

    # create new backup in a directory specified by DBBackupPath
    rocksdb_backup_engine_create_new_backup(be, db, err)
    check: err.isNil

    rocksdb_close(db)

    # If something is wrong, you might want to restore data from last backup
    var restoreOptions = rocksdb_restore_options_create()
    rocksdb_backup_engine_restore_db_from_latest_backup(be, dbPath, dbPath,
                                                        restoreOptions, err)
    check: err.isNil
    rocksdb_restore_options_destroy(restore_options)

    db = rocksdb_open(options, dbPath, err)
    check: err.isNil

    # cleanup
    rocksdb_writeoptions_destroy(writeOptions)
    rocksdb_readoptions_destroy(readOptions)
    rocksdb_options_destroy(options)
    rocksdb_backup_engine_close(be)
    rocksdb_close(db)