packageName = "rocksdb"
version = "0.4.0"
author = "Status Research & Development GmbH"
description =
  "A wrapper for Facebook's RocksDB, an embeddable, persistent key-value store for fast storage"
license = "Apache License 2.0 or GPLv2"
skipDirs = @["examples", "tests"]
mode = ScriptMode.Verbose

### Dependencies
requires "nim >= 1.6", "results", "tempfile", "unittest2"

# Format only works with nim version 2
task format, "Format nim code using nph":
  # Using the latest nph commit for now because the latest tagged version
  # doesn't work with the latest nim 2 version
  exec "nimble install nph@#head"
  exec "nph ."

task clean, "Remove temporary files":
  exec "rm -rf build"
  exec "make -C vendor/rocksdb clean"

task test, "Run tests":
  exec "nim c -r --threads:on tests/test_all.nim"

task test_static, "Run tests after static linking dependencies":
  when not defined(windows):
    exec "scripts/build_static_deps.sh"
  exec "nim c -d:rocksdb_static_linking -r --threads:on tests/test_all.nim"
