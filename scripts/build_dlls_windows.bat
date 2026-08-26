@echo off

SET SCRIPT_DIR=%~dp0

cd %SCRIPT_DIR%\..

git submodule update --init

CALL .\vendor\vcpkg\bootstrap-vcpkg.bat -disableMetrics

REM The vcpkg buildtrees contain deeply nested paths which can exceed the
REM Windows MAX_PATH limit, so in CI (where RUNNER_TEMP is set) redirect
REM them to a short path outside the repository.
SET VCPKG_EXTRA_ARGS=
IF DEFINED RUNNER_TEMP SET VCPKG_EXTRA_ARGS=--x-buildtrees-root=%RUNNER_TEMP%\vbt

.\vendor\vcpkg\vcpkg install rocksdb[lz4,zstd]:x64-windows-rocksdb --recurse --overlay-triplets=.\triplets %VCPKG_EXTRA_ARGS%

mkdir .\build
copy .\vendor\vcpkg\installed\x64-windows-rocksdb\bin\rocksdb-shared.dll .\build\librocksdb.dll
