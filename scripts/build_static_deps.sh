#!/usr/bin/env bash

# Nim-RocksDB
# Copyright 2018-2024 Status Research & Development GmbH
# Licensed under either of
#
#  * Apache License, version 2.0, ([LICENSE-APACHE](LICENSE-APACHE) or http://www.apache.org/licenses/LICENSE-2.0)
#  * GPL license, version 2.0, ([LICENSE-GPLv2](LICENSE-GPLv2) or https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)
#
# at your option. This file may not be copied, modified, or distributed except according to those terms.

set -e

cd "$(dirname "${BASH_SOURCE[0]}")"/..
REPO_DIR="${PWD}"
ROCKSDB_LIB_DIR=$REPO_DIR/vendor/rocksdb
BUILD_DEST=$REPO_DIR/build/lib

git submodule update --init
DEBUG_LEVEL=0 make -C "${ROCKSDB_LIB_DIR}" libz.a
DEBUG_LEVEL=0 make -C "${ROCKSDB_LIB_DIR}" static_lib
# TODO: add this in later
#exec "strip --strip-unneeded vendor/rocksdb/libz.a vendor/rocksdb/librocksdb.a"

mkdir -p "${BUILD_DEST}"
cp "${ROCKSDB_LIB_DIR}/libz.a" "${ROCKSDB_LIB_DIR}/librocksdb.a" "${BUILD_DEST}/"
