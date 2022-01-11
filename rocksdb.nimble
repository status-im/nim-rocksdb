packageName   = "rocksdb"
version       = "0.3.1"
author        = "Status Research & Development GmbH"
description   = "A wrapper for Facebook's RocksDB, an embeddable, persistent key-value store for fast storage"
license       = "Apache License 2.0 or GPLv2"
skipDirs      = @["examples", "tests"]

### Dependencies
requires "nim >= 1.2.0",
         "stew",
         "tempfile"

proc test(args, path: string) =
  if not dirExists "build":
    mkDir "build"
  exec "nim " & getEnv("TEST_LANG", "c") & " " & getEnv("NIMFLAGS") & " " & args &
    " --outdir:build -r --hints:off --threads:on --skipParentCfg " & path

task test, "Run tests":
  test "", "tests/all.nim"

