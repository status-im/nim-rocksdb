packageName   = "rocksdb"
version       = "0.4.0"
author        = "Status Research & Development GmbH"
description   = "A wrapper for Facebook's RocksDB, an embeddable, persistent key-value store for fast storage"
license       = "Apache License 2.0 or GPLv2"
skipDirs      = @["examples", "tests"]
mode          = ScriptMode.Verbose

### Dependencies
requires "nim >= 1.6",
         "stew",
         "tempfile",
         "unittest2"

proc createBuildDir() =
  if not dirExists "build":
    mkDir "build"

proc buildStaticDeps() =
  exec "git submodule update --init"
  exec "DEBUG_LEVEL=0 make -C vendor/rocksdb libz.a"
  exec "DEBUG_LEVEL=0 make -C vendor/rocksdb static_lib"
  # TODO: add this in later
  #exec "strip --strip-unneeded vendor/rocksdb/libz.a vendor/rocksdb/librocksdb.a"

task build_static, "Build static library":
  createBuildDir()
  buildStaticDeps()
  exec "nim c -d:static_linking --app:staticlib rocksdb.nim"

task test, "Run tests":
  createBuildDir()
  exec "nim c -r --threads:on tests/test_all.nim"

task test_static, "Run tests after static linking dependencies":
  createBuildDir()
  buildStaticDeps()
  exec "nim c -d:static_linking -r --threads:on tests/test_all.nim"
