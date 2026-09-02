# Copyright 2018-2025 Status Research & Development GmbH
# Licensed under either of
#
#  * Apache License, version 2.0, ([LICENSE-APACHE](LICENSE-APACHE) or http://www.apache.org/licenses/LICENSE-2.0)
#  * GPL license, version 2.0, ([LICENSE-GPLv2](LICENSE-GPLv2) or https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)
#
# at your option. This file may not be copied, modified, or distributed except according to those terms.

# Nim-RocksDB is a wrapper for Facebook's RocksDB
# RocksDB License
# Copyright (c) 2011-present, Facebook, Inc.  All rights reserved.
# Source code can be found at https://github.com/facebook/rocksdb
# under both the GPLv2 (found in the COPYING file in the RocksDB root directory) and Apache 2.0 License
# (found in the LICENSE.Apache file in the RocksDB root directory).

# RocksDB is derived work of LevelDB
# LevelDB License
# Copyright (c) 2011 The LevelDB Authors. All rights reserved.
# Source code can be found at https://github.com/google/leveldb
# Use of this source code is governed by a BSD-style license that can be
# found in the LevelDB LICENSE file. See the AUTHORS file for names of contributors.

## This file exposes the low-level C API of RocksDB

{.push raises: [].}

when defined(windows):
  const librocksdb = "librocksdb.dll"
elif defined(macosx):
  const librocksdb = "librocksdb.dylib"
else:
  const librocksdb = "librocksdb.so"

when defined(linux) and not defined(rocksdb_dynamic_linking):
  var ioUringEnabled = true

  proc rocksDbIOUringEnable(): bool {.exportc: "RocksDbIOUringEnable", cdecl, used.} =
    ioUringEnabled

  proc setIoUringEnabled*(enabled: bool) =
    ioUringEnabled = enabled

else:
  proc setIoUringEnabled*(enabled: bool) =
    discard

when defined(rocksdb_dynamic_linking) or defined(windows):
  {.push importc, cdecl, dynlib: librocksdb.}
else:
  import std/[os, strutils]

  const
    topLevelPath = currentSourcePath.parentDir().parentDir().parentDir()
    libsDir = topLevelPath.replace('\\', '/') & "/build"

  {.passl: libsDir & "/librocksdb.a".}
  {.passl: libsDir & "/liblz4.a".}
  {.passl: libsDir & "/libzstd.a".}

  when defined(linux):
    {.passl: libsDir & "/liburing.a".}

  when defined(windows):
    {.passl: "-lshlwapi -lrpcrt4".}

  {.push importc, cdecl.}

include ./rocksdb_gen.nim
