@echo off

SET SCRIPT_DIR=%~dp0

cd %SCRIPT_DIR%\..

git submodule update --init

CALL .\vendor\vcpkg\bootstrap-vcpkg.bat -disableMetrics

.\vendor\vcpkg\vcpkg install rocksdb[lz4,zstd]:x64-windows-rocksdb --recurse --overlay-triplets=.\triplets

mkdir .\build
copy .\vendor\vcpkg\installed\x64-windows-rocksdb\bin\rocksdb-shared.dll .\build\librocksdb.dll
