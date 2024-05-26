--- URL encode a string
---@param str string
function urlencode(str)
  function cth(c) return string.format("%%%02X", string.byte(c)) end
  if str == nil then return "" end
  str = string.gsub(str, "([^%w _ %- . ~])", cth)
  str = str:gsub(" ", "%%20")
  return str
end

--- Decode a URL encoded string
---@param s string
function urldecode(s)
    s = s:gsub('+', ' '):gsub('%%(%x%x)', function(h) return string.char(tonumber(h, 16)) end)
    return s
end

function parseurl(s)
    --s = string.match(s, '%s+(.+)')
    local ans = {}
    for k,v in string.gmatch(s, '([^&=?]-)=([^&=?]+)' ) do
      ans[ k ] = urldecode(v)
    end
    return ans
end