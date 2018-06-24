packageName   = "rocksdb"
version       = "0.2.0"
author        = "Status Research & Development GmbH"
description   = "A wrapper for Facebook's RocksDB, an embeddable, persistent key-value store for fast storage"
license       = "Apache License 2.0 or GPLv2"
srcDir        = "src"

### Dependencies
requires "nim >= 0.18.1",
         "ranges"

proc test(name: string, lang: string = "c") =
  if not dirExists "build":
    mkDir "build"
  if not dirExists "nimcache":
    mkDir "nimcache"
  --run
  --nimcache: "nimcache"
  switch("out", ("./build/" & name))
  setCommand lang, "tests/" & name & ".nim"

task test_c, "Run tests for the C wrapper":
  test "test_rocksdb_c"

task test, "Run tests for the Nim API":
  test "test_rocksdb"

