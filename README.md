# Nim-RocksDB

[![Linux/macOS Build Status (Travis)](https://img.shields.io/travis/status-im/nim-rocksdb/master.svg?label=Linux%20/%20MacOS "Linux / MacOS build status (Travis)")](https://travis-ci.org/mratsim/Arraymancer) [![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0) [![License: GPL v2](https://img.shields.io/badge/License-GPL%20v2-blue.svg)](https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)

A Nim wrapper for [Facebook's RocksDB](https://github.com/facebook/rocksdb), a persistent key-value store for Flash and RAM Storage.

## Current status

Nim-RocksDB currently provides a wrapper for the low-level functions of RocksDB

## Usage

See [simple_example](examples/simple_example.nim)

```nim
import rocksdb, cpuinfo

const
  dbPath: cstring = "/tmp/rocksdb_simple_example"
  dbBackupPath: cstring = "/tmp/rocksdb_simple_example_backup"

proc main() =
  var
    db: ptr rocksdb_t
    be: ptr rocksdb_backup_engine_t
    options = rocksdb_options_create()
  # Optimize RocksDB. This is the easiest way to
  # get RocksDB to perform well
  let cpus = countProcessors()
  rocksdb_options_increase_parallelism(options, cpus.int32)
  rocksdb_options_optimize_level_style_compaction(options, 0);
  # create the DB if it's not already present
  rocksdb_options_set_create_if_missing(options, 1);

  # open DB
  var err: cstringArray
  db = rocksdb_open(options, dbPath, err)
  doAssert err.isNil

  # open Backup Engine that we will use for backing up our database
  be = rocksdb_backup_engine_open(options, dbBackupPath, err)
  doAssert err.isNil

  # Put key-value
  var writeOptions = rocksdb_writeoptions_create()
  let key = "key"
  let put_value = "value"
  rocksdb_put(db, writeOptions, key.cstring, key.len, put_value.cstring, put_value.len, err)
  doAssert err.isNil

  # Get value
  var readOptions = rocksdb_readoptions_create()
  var len: csize
  let raw_value = rocksdb_get(db, readOptions, key, key.len, addr len, err) # Important: rocksdb_get is not null-terminated
  doAssert err.isNil

  # Copy it to a regular Nim string (copyMem workaround because raw value is NOT null-terminated)
  var get_value = newString(len)
  copyMem(addr get_value[0], unsafeAddr raw_value[0], len * sizeof(char))

  doAssert get_value == put_value

  # create new backup in a directory specified by DBBackupPath
  rocksdb_backup_engine_create_new_backup(be, db, err)
  doAssert err.isNil

  rocksdb_close(db)

  # If something is wrong, you might want to restore data from last backup
  var restoreOptions = rocksdb_restore_options_create()
  rocksdb_backup_engine_restore_db_from_latest_backup(be, dbPath, dbPath,
                                                      restoreOptions, err)
  doAssert err.isNil
  rocksdb_restore_options_destroy(restore_options)

  db = rocksdb_open(options, dbPath, err)
  doAssert err.isNil

  # cleanup
  rocksdb_writeoptions_destroy(writeOptions)
  rocksdb_readoptions_destroy(readOptions)
  rocksdb_options_destroy(options)
  rocksdb_backup_engine_close(be)
  rocksdb_close(db)

main()
```

## Future directions

In the future, Nim-RocksDB might provide a high-level API that:

- is more in line with Nim conventions (types in CamelCase),
- automatically checks for errors,
- leverage Nim features like destructors for automatic resource cleanup.

## License

Licensed under either of

 * Apache License, version 2.0, ([LICENSE-APACHE](LICENSE-APACHE) or http://www.apache.org/licenses/LICENSE-2.0)
 * GPL license, version 2.0, ([LICENSE-GPLv2](LICENSE-GPLv2) or https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)

at your option.

### Contribution

Any contribution intentionally submitted for inclusion in the work by you shall be dual licensed as above, without any
additional terms or conditions.