packageName = "rocksdb"
version = "10.4.2.1"
author = "Status Research & Development GmbH"
description =
  "A wrapper for Facebook's RocksDB, an embeddable, persistent key-value store for fast storage"
license = "Apache License 2.0 or GPLv2"
skipDirs = @["examples", "tests"]
mode = ScriptMode.Verbose
installDirs = @["build"]

### Dependencies
requires "nim >= 2.0", "results", "tempfile", "unittest2"

template build() =
  when defined(windows):
    exec ".\\scripts\\build_dlls_windows.bat"
  else:
    exec "scripts/build_static_deps.sh"

before install:
  build()

task format, "Format nim code using nph":
  exec "nimble install nph"
  exec "nph ."

task test, "Run tests":
  build()
  when defined(windows):
    exec "nim c -d:nimDebugDlOpen -r --mm:refc --threads:on tests/test_all.nim"
    exec "nim c -d:nimDebugDlOpen -r --mm:orc --threads:on tests/test_all.nim"
  else:
    exec "nim c -r --mm:refc --threads:on tests/test_all.nim"
    exec "nim c -r --mm:orc --threads:on tests/test_all.nim"
