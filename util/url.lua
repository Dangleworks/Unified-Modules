function urlencode(str)
	if str == nil then
		return ""
	end
	str = string.gsub(str, "([^%w _ %- . ~])", cth)
	str = str:gsub(" ", "%%20")
	return str
end

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