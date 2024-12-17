packageName = "rocksdb"
version = "0.5.0"
author = "Status Research & Development GmbH"
description =
  "A wrapper for Facebook's RocksDB, an embeddable, persistent key-value store for fast storage"
license = "Apache License 2.0 or GPLv2"
skipDirs = @["examples", "tests"]
mode = ScriptMode.Verbose
installDirs = @["build"]

### Dependencies
requires "nim >= 2.0", "results", "tempfile", "unittest2"

# Format only works with nim version 2
task format, "Format nim code using nph":
  # Using the latest nph commit for now because the latest tagged version
  # doesn't work with the latest nim 2 version
  exec "nimble install nph@0.6.0"
  exec "nph ."

task clean, "Remove temporary files":
  exec "rm -rf build"
  exec "make -C vendor/rocksdb clean"

task test, "Run tests":
  let runTests = "nim c -d:nimDebugDlOpen -r --threads:on tests/test_all.nim"
  when defined(linux):
    exec "export LD_LIBRARY_PATH=build; " & runTests
  when defined(macosx):
    exec "export DYLD_LIBRARY_PATH=build; " & runTests
  when defined(windows):
    exec runTests

task test_static, "Run tests after static linking dependencies":
  when defined(windows):
    echo "Static linking is not supported on windows"
    quit(1)

  exec "scripts/build_static_deps.sh"
  exec "nim c -d:rocksdb_static_linking -r --threads:on tests/test_all.nim"

before install:
  when defined(linux):
    exec "scripts/build_shared_deps_linux.sh"
  when defined(macosx):
    exec "scripts/build_shared_deps_osx.sh"
  when defined(windows):
    exec ".\\scripts\\build_dlls_windows.bat"
