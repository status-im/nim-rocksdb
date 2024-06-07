@echo off

SET SCRIPT_DIR=%~dp0

git submodule update --init

%SCRIPT_DIR\vendor\vcpkg\bootstrap-vcpkg.bat

%SCRIPT_DIR\vendor\vcpkg\vcpkg install rocksdb[lz4,zstd]:x64-windows-rocksdb --recurse --overlay-triplets=%SCRIPT_DIR\triplets

copy %SCRIPT_DIR\vendor\vcpkg\installed\x64-windows-rocksdb\bin\rocksdb-shared.dll %SCRIPT_DIR\librocksdb.dll
