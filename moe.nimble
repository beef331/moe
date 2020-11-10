# Package

version       = "0.2.4"
author        = "fox0430"
description   = "A command lined based text editor"
license       = "GPLv3"
srcDir        = "src"
bin           = @["moe"]

# Dependencies

requires "nim >= 1.4.0"
requires "https://github.com/walkre-niboshi/nim-ncurses >= 1.0.2"
requires "unicodedb >= 0.9.0"
requires "parsetoml >= 0.4.0"
requires "https://github.com/beef331/nimscripter"
requires "compiler"
task release, "Build for release":
  exec "nim c -o:moe -d:release src/moe"
task dScript, "Build For debug scripted":
  exec "nim c -o:moe -d:scripted -d:debugScript src/moe"
task script, "Build For debug scripted":
  exec "nim c -o:moe -d:scripted -d:release src/moe"
