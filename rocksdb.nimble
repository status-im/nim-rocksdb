packageName   = "rocksdb"
version       = "0.1.0"
author        = "Status Research & Development GmbH"
description   = "A wrapper for Facebook's RocksDB, an embeddable, persistent key-value store for fast storage"
license       = "Apache License 2.0 or GPLv2"
srcDir        = "src"

### Dependencies
requires "nim >= 0.17.2"

proc test(name: string, lang: string = "c") =
  if not dirExists "build":
    mkDir "bin"
  if not dirExists "nimcache":
    mkDir "nimcache"
  --run
  --nimcache: "nimcache"
  switch("out", ("./build/" & name))
  setCommand lang, "tests/" & name & ".nim"

task test_c, "Run tests for the C wrapper":
  test "test_rocksdb_c"