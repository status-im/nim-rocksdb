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
BUILD_DEST="${REPO_DIR}/build"

git submodule update --init

if [ -f "${BUILD_DEST}/librocksdb.dll" ] && \
   [ -f "${BUILD_DEST}/version.txt" ]; then

  ROCKSDB_VERSION_BEFORE=$(cat "${BUILD_DEST}/version.txt")

  cd ${REPO_DIR}/vendor/rocksdb
  ROCKSDB_VERSION_AFTER=$(${REPO_DIR}/vendor/rocksdb/build_tools/version.sh full)
  cd ${REPO_DIR}

  if [[ ${ROCKSDB_VERSION_BEFORE} == ${ROCKSDB_VERSION_AFTER} ]]; then
    echo "RocksDb dll libraries already built. Skipping build."
    exit 0
  fi
fi


${REPO_DIR}/vendor/vcpkg/bootstrap-vcpkg.sh -disableMetrics

${REPO_DIR}/vendor/vcpkg/vcpkg install rocksdb[lz4,zstd]:x64-windows-rocksdb --recurse --overlay-triplets=${REPO_DIR}/triplets

mkdir -p "${BUILD_DEST}"
cp ${REPO_DIR}/vendor/vcpkg/installed/x64-windows-rocksdb/bin/rocksdb-shared.dll ${BUILD_DEST}/librocksdb.dll

cd ${REPO_DIR}/vendor/rocksdb
${REPO_DIR}/vendor/rocksdb/build_tools/version.sh full > "${BUILD_DEST}/version.txt" 2>&1
cd ${REPO_DIR}
