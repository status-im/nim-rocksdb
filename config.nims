# nim-rocksdb
# Copyright (c) 2019-2025 Status Research & Development GmbH
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

when not defined(rocksdb_dynamic_linking) and not defined(windows):
  # use the C++ linker profile because it's a C++ library
  when defined(macosx):
    switch("clang.linkerexe", "clang++")
  else:
    switch("gcc.linkerexe", "g++")

--styleCheck:
  usages
--styleCheck:
  error
