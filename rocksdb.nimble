packageName = "rocksdb"
version = "9.8.4.0"
author = "Status Research & Development GmbH"
description =
  "A wrapper for Facebook's RocksDB, an embeddable, persistent key-value store for fast storage"
license = "Apache License 2.0 or GPLv2"
skipDirs = @["examples", "tests"]
mode = ScriptMode.Verbose
installDirs = @["build"]

### Dependencies
requires "nim >= 2.0", "results", "tempfile", "unittest2"

before install:
  when defined(windows):
    exec ".\\scripts\\build_dlls_windows.bat"
  else:
    exec "scripts/build_static_deps.sh"

task format, "Format nim code using nph":
  exec "nimble install nph@0.6.0"
  exec "nph ."

task clean, "Remove temporary files":
  exec "rm -rf build"
  exec "make -C vendor/rocksdb clean"

task test, "Run tests":
  when defined(windows):
    exec "nim c -d:nimDebugDlOpen -r --threads:on tests/test_all.nim"
  else:
    exec "nim c -r --threads:on tests/test_all.nim"
