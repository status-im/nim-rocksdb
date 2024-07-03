# Nim-RocksDB

[![Build Status (Travis)](https://img.shields.io/travis/status-im/nim-rocksdb/master.svg?label=Linux%20/%20macOS "Linux/macOS build status (Travis)")](https://travis-ci.org/status-im/nim-rocksdb)
[![Windows build status (Appveyor)](https://img.shields.io/appveyor/ci/nimbus/nim-rocksdb/master.svg?label=Windows "Windows build status (Appveyor)")](https://ci.appveyor.com/project/nimbus/nim-rocksdb)
[![License: Apache](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
![Stability: experimental](https://img.shields.io/badge/stability-experimental-orange.svg)

A Nim wrapper for [Facebook's RocksDB](https://github.com/facebook/rocksdb), a persistent key-value store for Flash and RAM Storage.

## Current status

Nim-RocksDB provides a wrapper for the low-level functions in the librocksdb c library.

## Installation

Nim-RocksDB requires Nim and the Nimble package manager. For Windows you will need Visual Studio 2015 Update 3 or greater with the English language pack.

To get started run:
```
nimble install
```

This will download and install the RocksDB dynamic libraries for your platform and copy them into the `build/` directory of the project. When including this library in your application you may want to copy these libraries into another location or set the LD_LIBRARY_PATH environment variable (DYLD_LIBRARY_PATH on MacOS, PATH on Windows) to include the `build/` directory so that your application can find them on startup.

Alternatively you can use the `rocksdb_static_linking` flag to statically link the library into your application.

### Static linking

To build the RocksDB static libraries run:
```
./scripts/build_static_deps.sh
```

To statically link RocksDB, you would do something like:

```
nim c -d:rocksdb_static_linking --threads:on your_program.nim
```

See the config.nims file which contains the static linking configuration which is switched on with the `rocksdb_static_linking` flag. Note that static linking is currently not supported on windows.

## Usage

See [simple_example](examples/simple_example.nim)


### Contribution

Any contribution intentionally submitted for inclusion in the work by you shall be dual licensed as above, without any
additional terms or conditions.

## License

### Wrapper License

This repository is licensed and distributed under either of

* MIT license: [LICENSE-MIT](LICENSE-MIT) or http://opensource.org/licenses/MIT

or

* Apache License, Version 2.0, ([LICENSE-APACHEv2](LICENSE-APACHEv2) or http://www.apache.org/licenses/LICENSE-2.0)

at your option. This file may not be copied, modified, or distributed except according to those terms.

### Dependency License

RocksDB is developed and maintained by Facebook Database Engineering Team.
It is built on earlier work on LevelDB by Sanjay Ghemawat (sanjay@google.com)
and Jeff Dean (jeff@google.com)

RocksDB is dual-licensed under both the [GPLv2](https://github.com/facebook/rocksdb/blob/master/COPYING) and Apache License, Version 2.0, ([LICENSE-APACHEv2](LICENSE-APACHEv2) or http://www.apache.org/licenses/LICENSE-2.0).  You may select, at your option, one of the above-listed licenses.
