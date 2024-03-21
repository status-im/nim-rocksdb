# nim-rocksdb
# Copyright (c) 2019-2023 Status Research & Development GmbH
# Licensed under either of
#  * Apache License, version 2.0, ([LICENSE-APACHE](LICENSE-APACHE))
#  * MIT license ([LICENSE-MIT](LICENSE-MIT))
# at your option.
# This file may not be copied, modified, or distributed except according to
# those terms.

# begin Nimble config (version 1)
when fileExists("nimble.paths"):
  include "nimble.paths"
# end Nimble config

when defined(rocksdb_static_linking):
  #switch("gcc.linkerexe", "g++") # use the C++ linker profile because it's a C++ library
  switch("clang.linkerexe", "clang++") # use the C++ linker profile because it's a C++ library
  switch("dynlibOverride", "librocksdb.a")
  switch("dynlibOverride", "liblz4.a")
  switch("dynlibOverride", "libzstd.a")
