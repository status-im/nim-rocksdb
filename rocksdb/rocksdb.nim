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
  std/[cpuinfo, tables],
  results,
  ./lib/librocksdb,
  ./options/[dbopts, readopts, writeopts],
  ./columnfamily/[cfopts, descriptor, handle]

export results

type
  RocksDBResult*[T] = Result[T, string]

  RocksDbPtr = ptr rocksdb_t

  RocksDbRef* = ref object
    rocksDbPtr: RocksDbPtr
    dbOpts: DbOptionsRef
    readOpts: ReadOptionsRef
    writeOpts: WriteOptionsRef
    # dbPath: string
    # columnFamilyNames: cstringArray
    # columnFamilies: TableRef[cstring, ptr rocksdb_column_family_handle_t]

  #DataProc* = proc(val: openArray[byte]) {.gcsafe, raises: [].}

proc openRocksDb*(
    path: string,
    dbOpts = defaultDbOptions(),
    readOpts = defaultReadOptions(),
    writeOpts = defaultWriteOptions(),
    columnFamilies = @[defaultColFamilyDescriptor()]): RocksDBResult[RocksDbRef] =

  discard

  # for i in 0..columnFamilyNames.high:
  #   rocks.options.add(rocksdb_options_create())
  # rocks.readOptions = rocksdb_readoptions_create()
  # rocks.writeOptions = rocksdb_writeoptions_create()
  # rocks.dbPath = dbPath
  # rocks.columnFamilyNames = columnFamilyNames.allocCStringArray
  # rocks.columnFamilies = newTable[cstring, ptr rocksdb_column_family_handle_t]()

  # for opts in rocks.options:
  #   # Optimize RocksDB. This is the easiest way to get RocksDB to perform well:
  #   rocksdb_options_increase_parallelism(opts, cpus.int32)
  #   # This requires snappy - disabled because rocksdb is not always compiled with
  #   # snappy support (for example Fedora 28, certain Ubuntu versions)
  #   # rocksdb_options_optimize_level_style_compaction(options, 0);
  #   rocksdb_options_set_create_if_missing(opts, uint8(createIfMissing))
  #   # default set to keep all files open (-1), allow setting it to a specific
  #   # value, e.g. in case the application limit would be reached.
  #   rocksdb_options_set_max_open_files(opts, maxOpenFiles.cint)
  #   # Enable creating column families if they do not exist
  #   rocksdb_options_set_create_missing_column_families(opts, uint8(true))

  # var
  #   columnFamilyHandles = newSeq[ptr rocksdb_column_family_handle_t](columnFamilyNames.len)
  #   errors: cstring
  #   rocks.db = rocksdb_open_column_families(
  #       rocks.options[0],
  #       dbPath,
  #       columnFamilyNames.len().cint,
  #       rocks.columnFamilyNames,
  #       rocks.options[0].addr,
  #       columnFamilyHandles[0].addr,
  #       cast[cstringArray](errors.addr))
  # bailOnErrors()

  # for i in 0..<columnFamilyNames.len:
  #   rocks.columnFamilies[columnFamilyNames[i].cstring] = columnFamilyHandles[i]

  # ok()


# openReadOnly
# get (two methods)
# put
# keyExists
# delete
# close

# backup
# iterator