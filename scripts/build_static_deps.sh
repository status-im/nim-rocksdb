#!/usr/bin/env bash

# Nim-RocksDB
# Copyright 2024 Status Research & Development GmbH
# Licensed under either of
#
#  * Apache License, version 2.0, ([LICENSE-APACHE](LICENSE-APACHE) or http://www.apache.org/licenses/LICENSE-2.0)
#  * GPL license, version 2.0, ([LICENSE-GPLv2](LICENSE-GPLv2) or https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)
#
# at your option. This file may not be copied, modified, or distributed except according to those terms.

set -e

cd "$(dirname "${BASH_SOURCE[0]}")"/..

REPO_DIR="${PWD}"
ROCKSDB_LIB_DIR="${REPO_DIR}/vendor/rocksdb"
BUILD_DEST="${REPO_DIR}/build/lib"

: "${MAKE:=make}"

[[ -z "$NPROC" ]] && NPROC=2 # number of CPU cores available

git submodule update --init

export DISABLE_WARNING_AS_ERROR=1

export ROCKSDB_DISABLE_SNAPPY=1
export ROCKSDB_DISABLE_ZLIB=1
export ROCKSDB_DISABLE_BZIP=1

export PORTABLE=1
export DEBUG_LEVEL=0

if ${MAKE} -C "${ROCKSDB_LIB_DIR}" --dry-run static_lib | grep -q 'Nothing to be done'; then
  echo "RocksDb static libraries already built. Skipping build."
  exit 0
else
  ${REPO_DIR}/scripts/clean_build_artifacts.sh
  echo "Building RocksDb static libraries."
fi

${MAKE} -C "${ROCKSDB_LIB_DIR}" liblz4.a libzstd.a --no-print-directory > /dev/null

export EXTRA_CFLAGS="-fpermissive -Wno-error -w -I${ROCKSDB_LIB_DIR}/lz4-1.9.4/lib -I${ROCKSDB_LIB_DIR}/zstd-1.5.5/lib -DLZ4 -DZSTD"
export EXTRA_CXXFLAGS="-fpermissive -Wno-error -w -I${ROCKSDB_LIB_DIR}/lz4-1.9.4/lib -I${ROCKSDB_LIB_DIR}/zstd-1.5.5/lib -DLZ4 -DZSTD"

${MAKE} -C "${ROCKSDB_LIB_DIR}" unity.a --no-print-directory > /dev/null

#cat "${REPO_DIR}/vendor/rocksdb/make_config.mk"

mkdir -p "${BUILD_DEST}"

cp "${ROCKSDB_LIB_DIR}/liblz4.a" "${BUILD_DEST}/"
cp "${ROCKSDB_LIB_DIR}/libzstd.a" "${BUILD_DEST}/"
cp "${ROCKSDB_LIB_DIR}/unity.a" "${BUILD_DEST}/librocksdb.a"
