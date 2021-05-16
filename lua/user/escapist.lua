local function escape(s)
	return s:gsub("-", "-s"):gsub("/", "-f"):gsub("\\", "-b")
end

local function unescape(s)
	return s:gsub("-b", "\\"):gsub("-f", "/"):gsub("-s", "-")
end

return {
	escape = escape,
	unescape = unescape,
}
