# Nim-RocksDB

[![Linux/macOS Build Status (Travis)](https://img.shields.io/travis/status-im/nim-rocksdb/master.svg?label=Linux%20/%20MacOS "Linux / MacOS build status (Travis)")](https://travis-ci.org/status-im/nim-rocksdb) [![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0) [![License: GPL v2](https://img.shields.io/badge/License-GPL%20v2-blue.svg)](https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)

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

## License

Licensed under either of

 * Apache License, version 2.0, ([LICENSE-APACHE](LICENSE-APACHE) or http://www.apache.org/licenses/LICENSE-2.0)
 * GPL license, version 2.0, ([LICENSE-GPLv2](LICENSE-GPLv2) or https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)

at your option.

### Contribution

Any contribution intentionally submitted for inclusion in the work by you shall be dual licensed as above, without any
additional terms or conditions.
