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
export EXTRA_CXXFLAGS=-fpermissive
export DISABLE_WARNING_AS_ERROR=true
DEBUG_LEVEL=0 make -C "${ROCKSDB_LIB_DIR}" libz.a libbz2.a liblz4.a libzstd.a \
    static_lib --no-print-directory # TODO: reduce output

mkdir -p "${BUILD_DEST}"

cp "${ROCKSDB_LIB_DIR}/libz.a" "${BUILD_DEST}/"
cp "${ROCKSDB_LIB_DIR}/libbz2.a" "${BUILD_DEST}/"
cp "${ROCKSDB_LIB_DIR}/liblz4.a" "${BUILD_DEST}/"
cp "${ROCKSDB_LIB_DIR}/libzstd.a" "${BUILD_DEST}/"
cp "${ROCKSDB_LIB_DIR}/librocksdb.a" "${BUILD_DEST}/"

# TODO: fix this. --strip-unneeded is not supported on macos
# strip --strip-unneeded "${BUILD_DEST}/libz.a"
# strip --strip-unneeded "${BUILD_DEST}/libbz2.a"
# strip --strip-unneeded "${BUILD_DEST}/liblz4.a"
# strip --strip-unneeded "${BUILD_DEST}/libzstd.a"
# strip --strip-unneeded "${BUILD_DEST}/librocksdb.a"
