packageName   = "rocksdb"
version       = "0.2.0"
author        = "Status Research & Development GmbH"
description   = "A wrapper for Facebook's RocksDB, an embeddable, persistent key-value store for fast storage"
license       = "Apache License 2.0 or GPLv2"
skipDirs      = @["examples", "tests"]

### Dependencies
requires "nim >= 0.18.1",
         "stew",
         "tempfile"

proc test(name: string, lang: string = "c") =
  if not dirExists "build":
    mkDir "build"
  if not dirExists "nimcache":
    mkDir "nimcache"
  --run
  --nimcache: nimcache
  switch("out", ("./build/" & name))
  --threads: on
  setCommand lang, "tests/" & name & ".nim"

task test, "Run tests":
  test "all"

