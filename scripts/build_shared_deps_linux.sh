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

BUILD_DEST="${REPO_DIR}/build/"

git submodule update --init

${REPO_DIR}/vendor/vcpkg/bootstrap-vcpkg.sh -disableMetrics

${REPO_DIR}/vendor/vcpkg/vcpkg install rocksdb[lz4,zstd]:x64-linux-rocksdb --recurse --overlay-triplets=${REPO_DIR}/triplets

mkdir -p "${BUILD_DEST}"

cp "${REPO_DIR}/vendor/vcpkg/installed/x64-linux-rocksdb/lib/liblz4.so" "${BUILD_DEST}/"
cp "${REPO_DIR}/vendor/vcpkg/installed/x64-linux-rocksdb/lib/libzstd.so" "${BUILD_DEST}/"
cp "${REPO_DIR}/vendor/vcpkg/installed/x64-linux-rocksdb/lib/librocksdb.so" "${BUILD_DEST}/"
