# Package

version       = "0.1.0"
author        = "Christopher J Stehno"
description   = "A tool for generating random 5e treasure."
license       = "Apache-2.0"
srcDir        = "src"
bin           = @["lootgen"]



# Dependencies

requires "nim >= 1.2.6"
requires "docopt >= 0.6.7"
requires "polydice >= 0.1.0"
