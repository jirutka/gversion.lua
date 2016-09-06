---------
-- Lua library for Gentoo-style versioning format
--
-- **Examples:**
--     local v = require 'gversion'
--
--     -- Parse version
--     ver = v"2.1_rc3-r1"
--     ver = v.parse("2.1_rc3-r1")
--
--     -- Access version parts
--     ver[1]    --> "2"
--     ver.major --> "2"
--     ver[2]    --> "1"
--     ver.minor --> "1"
--     ver.rc    --> "3"
--     ver.r     --> "1"
--
--     -- Change version parts
--     ver[1] = "2"    -- 2.1_rc3-r1
--     ver.minor = "0" -- 2.0_rc3-r1
--     ver.rc = nil    -- 2.0-r1
--
--     -- Compare versions
--     v"1.5" == v"1.005"          --> true
--     v"1.2_rc1" < v"1.2b"        --> true
--     v"1.2_beta_pre" > v"1.2_p1" --> false
--
-- See https://devmanual.gentoo.org/ebuild-writing/file-format/#file-naming-rules
-- for specification of the versioning format.
--
-- @author Jakub Jirutka <jakub@jirutka.cz>
-- @license MIT
--

local join = table.concat

local function cmp (a, b, field, conv, default)
  local lhs = conv(a[field]) or default
  local rhs = conv(b[field]) or default

  if lhs == rhs then
    return 0
  elseif lhs > rhs then
    return 1
  else
    return -1
  end
end

local function identity (a)
  return a
end


local M = {}

--- Version of this module.
M._VERSION = '0.0.0'

-- List of pre/post-release suffixes (initialized in `set_suffixes`).
local suffixes_pre = {}
local suffixes_post = {}

-- Map of all suffixes as keys for quick lookup (initialized in `set_suffixes`).
local suffixes = {}

-- List of field aliases.
local aliases = { major = 1, minor = 2, tiny = 3 }


--- Sets pre-release and post-release suffixes.
--
-- Default pre-release suffixes are: *alpha, beta, pre, rc*.
-- Default post-release suffixes are: *p*.
--
-- Suffix **must not** be `r` or `suffix`, these have special meaning!
--
-- @tparam {string,...} pre_release
-- @tparam {string,...} post_release
function M.set_suffixes (pre_release, post_release)
  suffixes_pre = pre_release
  suffixes_post = post_release
  suffixes = {}

  for _, list in ipairs { suffixes_pre, suffixes_post } do
    for _, suffix in ipairs(list) do
      suffixes[suffix] = true
    end
  end
end

-- Initialize default suffixes.
M.set_suffixes({ 'alpha', 'beta', 'pre', 'rc' }, { 'p' })


-- Metatable for `Version` type.
local meta = {}

function meta:__eq (other)
  return M.compare(self, other) == 0
end

function meta:__lt (other)
  return M.compare(self, other) == -1
end

function meta:__index (key)
  key = aliases[key] or key
  return rawget(self, key)
end

function meta:__newindex (key, value)
  key = aliases[key] or key
  rawset(self, key, value)
end

function meta:__tostring ()
  local res = join(self, '.')

  if self.suffix then
    res = res..self.suffix
  end

  for _, list in ipairs { suffixes_pre, suffixes_post } do
    for _, suffix in ipairs(list) do
      local val = self[suffix]
      if val then
        res = res..'_'..suffix..(val ~= '0' and val or '')
      end
    end
  end

  if self.r then
    res = res..'-r'..self.r
  end

  return res
end


--- Parses given `str` and returns `Version`, if `str` is a valid version.
--
-- @tparam string str The string to parse.
-- @treturn Version A parsed version.
-- @raise Error when `str` is not a valid version.
function M.parse (str)
  assert(type(str) == 'string', 'str must be a string')

  local version = {}
  local pos = 1

  -- Numbers
  str = '.'..str
  while true do
    local _, eend, digits = str:find('^%.(%d+)', pos)
    if not eend then break end

    table.insert(version, digits)
    pos = eend + 1
  end

  -- A letter after the final number
  if str:match('^%l', pos) then
    version['suffix'] = str:sub(pos, pos)
    pos = pos + 1
  end

  -- Suffixes
  while true do
    local _, eend , suffix, digits = str:find('^_(%l+)(%d*)', pos)
    if not eend then break end

    if not suffixes[suffix] then
      error(("Invalid version %s, unknown suffix %s"):format(str, suffix))
    end
    version[suffix] = tonumber(digits) and digits or '0'
    pos = eend + 1
  end

  -- Revision
  do
    local _, eend, digits = str:find('^-r(%d+)', pos)
    if eend then
      version['r'] = digits
      pos = eend + 1
    end
  end

  if #str ~= pos - 1 then
    error('Invalid version: '..str)
  end

  return setmetatable(version, meta)
end

--- Compares two versions.
--
-- @tparam Version a
-- @tparam Version b
-- @treturn number -1 if `a < b`, 0 if `a == b`, or 1 if `a > b`
function M.compare (a, b)
  local res

  -- Numerical part
  for i=1, math.max(#a, #b) do
    res = cmp(a, b, i, tonumber, 0)
    if res ~= 0 then return res end
  end

  -- A Letter after the final number
  res = cmp(a, b, 'suffix', identity, '')
  if res ~= 0 then return res end

  -- Pre-release suffixes
  for _, suffix in ipairs(suffixes_pre) do
    res = cmp(a, b, suffix, tonumber, math.huge)
    if res ~= 0 then return res end
  end

  -- Post-release suffixes
  for _, suffix in ipairs(suffixes_post) do
    res = cmp(a, b, suffix, tonumber, -1)
    if res ~= 0 then return res end
  end

  -- Revision
  res = cmp(a, b, 'r', tonumber, 0)
  if res ~= 0 then return res end

  return 0
end


--- An alias for `parse`.
-- @function __call
return setmetatable(M, {
  __call = function(_, ...)
    return M.parse(...)
  end,
})
