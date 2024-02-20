packageName   = "rocksdb"
version       = "0.4.0"
author        = "Status Research & Development GmbH"
description   = "A wrapper for Facebook's RocksDB, an embeddable, persistent key-value store for fast storage"
license       = "Apache License 2.0 or GPLv2"
skipDirs      = @["examples", "tests"]
mode          = ScriptMode.Verbose

### Dependencies
requires "nim >= 1.6.0",
         "stew",
         "tempfile",
         "unittest2"

proc test(args, path: string) =
  if not dirExists "build":
    mkDir "build"
  exec "nim " & getEnv("TEST_LANG", "c") & " " & getEnv("NIMFLAGS") & " " & args &
    " --outdir:build -r --hints:off --threads:on --skipParentCfg " & path

task test, "Run tests":
  test "", "tests/test_all.nim"
  # Too troublesome to install "librocksdb.a" in CI, but this is how we would
  # test it (we need the C++ linker profile because it's a C++ library):
  # test "-d:LibrocksbStaticArgs='-l:librocksdb.a' --gcc.linkerexe=g++", "tests/all.nim"

