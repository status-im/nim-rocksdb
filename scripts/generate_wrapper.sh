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

#nimble install c2nim

cd "$(dirname "${BASH_SOURCE[0]}")"/..

VENDOR_HEADER_FILE="vendor/rocksdb/include/rocksdb/c.h"
OUTPUT_HEADER_FILE="rocksdb/lib/rocksdb.h"
C2NIM_GENERATED_WRAPPER="rocksdb/lib/rocksdb_gen.nim"

# copy and rename vendor c.h to rocksdb.h
cp ${VENDOR_HEADER_FILE} ${OUTPUT_HEADER_FILE}

# update rocksdb.h file with c2nim settings required to generate nim wrapper
sed -i ':a;N;$!ba;s/#ifdef _WIN32\
#ifdef ROCKSDB_DLL\
#ifdef ROCKSDB_LIBRARY_EXPORTS\
#define ROCKSDB_LIBRARY_API __declspec(dllexport)\
#else\
#define ROCKSDB_LIBRARY_API __declspec(dllimport)\
#endif\
#else\
#define ROCKSDB_LIBRARY_API\
#endif\
#else\
#define ROCKSDB_LIBRARY_API\
#endif/#ifdef C2NIM\
#  def ROCKSDB_LIBRARY_API\
#  cdecl\
#  mangle uint32_t uint32\
#  mangle uint16_t uint16\
#  mangle uint8_t  uint8\
#  mangle uint64_t uint64\
#  mangle int32_t  int32\
#  mangle int16_t  int16\
#  mangle int8_t   int8\
#  mangle int64_t  int64\
#  mangle cuchar   uint8\
#else\
#  ifdef _WIN32\
#  ifdef ROCKSDB_DLL\
#  ifdef ROCKSDB_LIBRARY_EXPORTS\
#  define ROCKSDB_LIBRARY_API __declspec(dllexport)\
#  else\
#  define ROCKSDB_LIBRARY_API __declspec(dllimport)\
#  endif\
#  else\
#  define ROCKSDB_LIBRARY_API\
#  endif\
#  else\
#  define ROCKSDB_LIBRARY_API\
#  endif\
#endif/g' ${OUTPUT_HEADER_FILE}

# generate nim wrapper
c2nim ${OUTPUT_HEADER_FILE} --out:"${C2NIM_GENERATED_WRAPPER}"

#nimble format
