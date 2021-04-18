local function escape(s)
	s = s:gsub("-", "-s")
	s = s:gsub("/", "-f")
	s = s:gsub("\\", "-b")
	return s
end

local function unescape(s)
	s = s:gsub("-b", "\\")
	s = s:gsub("-f", "/")
	s = s:gsub("-s", "-")
	return s
end

return {
	escape = escape,
	unescape = unescape,
}
