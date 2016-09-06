-- vim: set ft=lua:

package = 'gversion'
version = 'dev-0'

source = {
  url = 'git://github.com/jirutka/gversion.lua.git',
  branch = 'master',
}

description = {
  summary = 'Lua library for Gentoo-style versioning format',
  detailed = [[
    Gentoo versioning format (scheme) is like Semantic Versioning, but more
    flexible and complex. See details in
    https://devmanual.gentoo.org/ebuild-writing/file-format/#file-naming-rules.
  ]],
  homepage = 'https://github.com/jirutka/gversion.lua',
  maintainer = 'Jakub Jirutka <jakub@jirutka.cz>',
  license = 'MIT',
}

dependencies = {
  'lua >= 5.1',
}

build = {
  type = 'builtin',
  modules = {
    gversion = 'src/gversion.lua',
  },
}
