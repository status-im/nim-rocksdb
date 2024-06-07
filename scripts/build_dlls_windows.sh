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

git submodule update --init

${REPO_DIR}/vendor/vcpkg/bootstrap-vcpkg.sh -disableMetrics

${REPO_DIR}/vendor/vcpkg/vcpkg install rocksdb[lz4,zstd]:x64-windows-rocksdb --recurse --overlay-triplets=${REPO_DIR}/triplets

mkdir -p ${REPO_DIR}/build
cp ${REPO_DIR}/vendor/vcpkg/installed/x64-windows-rocksdb/bin/rocksdb-shared.dll ./build/librocksdb.dll
