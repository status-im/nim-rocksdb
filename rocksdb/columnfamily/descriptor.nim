# Nim-RocksDB
# Copyright 2024 Status Research & Development GmbH
# Licensed under either of
#
#  * Apache License, version 2.0, ([LICENSE-APACHE](LICENSE-APACHE) or http://www.apache.org/licenses/LICENSE-2.0)
#  * GPL license, version 2.0, ([LICENSE-GPLv2](LICENSE-GPLv2) or https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)
#
# at your option. This file may not be copied, modified, or distributed except according to those terms.

{.push raises: [].}

import
  ./cfopts

const DEFAULT_COLUMN_FAMILY* = "default"

type
  ColFamilyDescriptor* = object
    name: string
    options: ColFamilyOptionsRef

proc initColFamilyDescriptor*(
    name: string,
    options = defaultColFamilyOptions()): ColFamilyDescriptor =
  ColFamilyDescriptor(name: name, options: options)

proc name*(descriptor: ColFamilyDescriptor): string =
  descriptor.name

proc options*(descriptor: ColFamilyDescriptor): ColFamilyOptionsRef =
  descriptor.options

proc defaultColFamilyDescriptor*(): ColFamilyDescriptor =
  initColFamilyDescriptor(DEFAULT_COLUMN_FAMILY)

template close*(descriptor: var ColFamilyDescriptor) =
  descriptor.options.close()
