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

task test, "Run tests":
  exec "nim c -r --threads:on tests/test_all.nim"

task test_static, "Run tests after static linking dependencies":
  exec "scripts/build_static_deps.sh"
  exec "nim c -d:static_linking -r --threads:on tests/test_all.nim"
