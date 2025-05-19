# Nim-RocksDb

![Github action](https://github.com/status-im/nim-rocksdb/workflows/CI/badge.svg)
[![License: Apache](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
![Stability: experimental](https://img.shields.io/badge/stability-experimental-orange.svg)

A Nim wrapper for [Facebook's RocksDB](https://github.com/facebook/rocksdb), a persistent key-value store for Flash and RAM Storage.

## Current status

Nim-RocksDb provides a wrapper for the low-level functions in the librocksdb c
library.

## Installation

Nim-RocksDb requires Nim and the Nimble package manager. For Windows you will
need Visual Studio 2015 Update 3 or greater with the English language pack.

To get started run:
```
nimble install rocksdb
```

This will download and install the RocksDB libraries for your platform and copy
them into the `build/` directory of the project. On Linux and MacOS only static
linking to the RocksDb libraries is supported and on Windows only dynamic linking
is supported.

On Windows you may want to copy the dll into another location or set your PATH
to include the `build/` directory so that your application can find the dll on
startup.

### Compression libraries

RocksDb supports using a number of compression libraries. This library builds
and only supports the following compression libraries:
- lz4
- zstd

On Linux and MacOS these libraries are staticly linked into the final binary
along with the RocksDb static library. On Windows they are staticly linked into
the RocksDb dll.


### Static linking

On Linux and MacOS your Nim program will need to use the C++ linker profile
because RocksDb is a C++ library. For example:

```
  when defined(macosx):
    switch("clang.linkerexe", "clang++")
  when defined(linux):
    switch("gcc.linkerexe", "g++")
```

Note that static linking is currently not supported on windows.

## Usage

See [simple_example](examples/simple_example.nim)

### Contribution

Any contribution intentionally submitted for inclusion in the work by you shall
be dual licensed as above, without any additional terms or conditions.

## Versioning

The library generally follows the upstream RocksDb version number, adding one
more number for tracking changes to the Nim wrapper itself.

## License

### Wrapper License

This repository is licensed and distributed under either of

* MIT license: [LICENSE-MIT](LICENSE-MIT) or http://opensource.org/licenses/MIT

or

* Apache License, Version 2.0, ([LICENSE-APACHEv2](LICENSE-APACHEv2) or http://www.apache.org/licenses/LICENSE-2.0)

at your option. This file may not be copied, modified, or distributed except
according to those terms.

### Dependency License

RocksDB is developed and maintained by Facebook Database Engineering Team.
It is built on earlier work on LevelDB by Sanjay Ghemawat (sanjay@google.com)
and Jeff Dean (jeff@google.com)

RocksDB is dual-licensed under both the [GPLv2](https://github.com/facebook/rocksdb/blob/master/COPYING) and Apache License, Version 2.0, ([LICENSE-APACHEv2](LICENSE-APACHEv2) or http://www.apache.org/licenses/LICENSE-2.0).  You may select, at your option, one of the above-listed licenses.
