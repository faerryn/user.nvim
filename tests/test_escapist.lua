vim.o.rtp = ".,"..vim.o.rtp

local escapist = require("user.escapist")

local function test_escape(s)
	assert(s == escapist.unescape(escapist.escape(s)))
end

test_escape("hello world")
test_escape("hello-world")
test_escape("hello/world")
test_escape("hello\\world")
test_escape("hello-sworld")
test_escape("hello-fworld")
test_escape("hello-bworld")
