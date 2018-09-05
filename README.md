# Nim-RocksDB

[![Build Status (Travis)](https://img.shields.io/travis/status-im/nim-rocksdb/master.svg?label=Linux%20/%20macOS "Linux/macOS build status (Travis)")](https://travis-ci.org/status-im/nim-rocksdb)
[![Windows build status (Appveyor)](https://img.shields.io/appveyor/ci/nimbus/nim-rocksdb/master.svg?label=Windows "Windows build status (Appveyor)")](https://ci.appveyor.com/project/nimbus/nim-rocksdb)
[![License: Apache](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
![Stability: experimental](https://img.shields.io/badge/stability-experimental-orange.svg)

A Nim wrapper for [Facebook's RocksDB](https://github.com/facebook/rocksdb), a persistent key-value store for Flash and RAM Storage.

## Current status

Nim-RocksDB currently provides a wrapper for the low-level functions of RocksDB

## Usage

See [simple_example](examples/simple_example.nim)

## Future directions

In the future, Nim-RocksDB might provide a high-level API that:

- is more in line with Nim conventions (types in CamelCase),
- automatically checks for errors,
- leverage Nim features like destructors for automatic resource cleanup.

### Contribution

Any contribution intentionally submitted for inclusion in the work by you shall be dual licensed as above, without any
additional terms or conditions.

## License

Licensed under both of the following:

 * Apache License, Version 2.0, ([LICENSE-APACHE](LICENSE-APACHE) or http://www.apache.org/licenses/LICENSE-2.0)
 * MIT license: [LICENSE-MIT](LICENSE-MIT) or http://opensource.org/licenses/MIT
