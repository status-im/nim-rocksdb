#!/usr/bin/env bash

# Nim-RocksDB
# Copyright 2024-2025 Status Research & Development GmbH
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
BUILD_DEST="${REPO_DIR}/build"
LZ4_VERSION=1.10.0
ZSTD_VERSION=1.5.7
LIBURING_VERSION=2.14
LIBURING_DIR="${ROCKSDB_LIB_DIR}/liburing-liburing-${LIBURING_VERSION}"

: "${MAKE:=make}"

[[ -z "$NPROC" ]] && NPROC=2 # number of CPU cores available

git submodule update --init

export DISABLE_WARNING_AS_ERROR=1
export ROCKSDB_DISABLE_SNAPPY=1
export ROCKSDB_DISABLE_ZLIB=1
export ROCKSDB_DISABLE_BZIP=1
export PORTABLE=1
export DEBUG_LEVEL=0
#export USE_LTO=1
export ALLOW_BUILD_PARAMETER_CHANGE=1

build_liburing() {
  if [ ! -f "${LIBURING_DIR}/src/liburing.a" ]; then
    curl -sSL "https://github.com/axboe/liburing/archive/refs/tags/liburing-${LIBURING_VERSION}.tar.gz" | \
      tar xz -C "${ROCKSDB_LIB_DIR}"
    (cd "${LIBURING_DIR}" && ./configure > /dev/null && \
      ${MAKE} -j${NPROC} -C src liburing.a > /dev/null 2>&1)
  fi
  export CPATH="${LIBURING_DIR}/src/include${CPATH:+:${CPATH}}"
  export LIBRARY_PATH="${LIBURING_DIR}/src${LIBRARY_PATH:+:${LIBRARY_PATH}}"
  mkdir -p "${BUILD_DEST}"
  cp "${LIBURING_DIR}/src/liburing.a" "${BUILD_DEST}/"
}

if [ -f "${BUILD_DEST}/librocksdb.a" ] && \
   [ -f "${BUILD_DEST}/liblz4.a" ] && \
   [ -f "${BUILD_DEST}/libzstd.a" ] && \
   [ -f "${BUILD_DEST}/version.txt" ] && \
   { [[ "$(uname)" != "Linux" ]] || [ -f "${BUILD_DEST}/liburing.a" ]; }; then

  ROCKSDB_VERSION_BEFORE=$(cat "${BUILD_DEST}/version.txt")

  cd ${REPO_DIR}/vendor/rocksdb
  ROCKSDB_VERSION_AFTER=$(${REPO_DIR}/vendor/rocksdb/build_tools/version.sh full)
  cd ${REPO_DIR}

  if [[ ${ROCKSDB_VERSION_BEFORE} == ${ROCKSDB_VERSION_AFTER} ]]; then
    echo "RocksDb static libraries already built. Skipping build."
    exit 0
  fi
fi

if ${MAKE} -C "${ROCKSDB_LIB_DIR}" -q unity.a; then
  echo "RocksDb static libraries already built. Skipping build."

  # Copy the built libraries in case the build directory has been removed
  mkdir -p "${BUILD_DEST}"
  cp "${ROCKSDB_LIB_DIR}/liblz4.a" "${BUILD_DEST}/"
  cp "${ROCKSDB_LIB_DIR}/libzstd.a" "${BUILD_DEST}/"
  cp "${ROCKSDB_LIB_DIR}/unity.a" "${BUILD_DEST}/librocksdb.a"
  [[ "$(uname)" != "Linux" ]] || build_liburing

  cd ${REPO_DIR}/vendor/rocksdb
  ${REPO_DIR}/vendor/rocksdb/build_tools/version.sh full > "${BUILD_DEST}/version.txt" 2>&1
  cd ${REPO_DIR}

  exit 0
else
  ${REPO_DIR}/scripts/clean_build_artifacts.sh
  echo "Building RocksDb static libraries."
fi

[[ "$(uname)" != "Linux" ]] || build_liburing

${MAKE} -j${NPROC} -C "${ROCKSDB_LIB_DIR}" liblz4.a libzstd.a --no-print-directory > /dev/null 2>&1

export EXTRA_CFLAGS="-fpermissive -Wno-error -w -I${ROCKSDB_LIB_DIR}/lz4-${LZ4_VERSION}/lib -I${ROCKSDB_LIB_DIR}/zstd-${ZSTD_VERSION}/lib -DLZ4 -DZSTD"
export EXTRA_CXXFLAGS="-fpermissive -Wno-error -w -I${ROCKSDB_LIB_DIR}/lz4-${LZ4_VERSION}/lib -I${ROCKSDB_LIB_DIR}/zstd-${ZSTD_VERSION}/lib -DLZ4 -DZSTD"

${MAKE} -j${NPROC} -C "${ROCKSDB_LIB_DIR}" unity.a --no-print-directory > /dev/null 2>&1

#cat "${REPO_DIR}/vendor/rocksdb/make_config.mk"

if [[ "$(uname)" == "Linux" ]] && \
   ! grep -q "ROCKSDB_IOURING_PRESENT" "${ROCKSDB_LIB_DIR}/make_config.mk"; then
  echo "io_uring support was not detected by the RocksDb build."
  exit 1
fi

mkdir -p "${BUILD_DEST}"

cp "${ROCKSDB_LIB_DIR}/liblz4.a" "${BUILD_DEST}/"
cp "${ROCKSDB_LIB_DIR}/libzstd.a" "${BUILD_DEST}/"
cp "${ROCKSDB_LIB_DIR}/unity.a" "${BUILD_DEST}/librocksdb.a"

cd ${REPO_DIR}/vendor/rocksdb
${REPO_DIR}/vendor/rocksdb/build_tools/version.sh full > "${BUILD_DEST}/version.txt" 2>&1
cd ${REPO_DIR}
