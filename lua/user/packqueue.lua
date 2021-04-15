local PackQueue = {}

function PackQueue:new()
	local packqueue = {
		remaining = require'user.deque'.Deque:new(),
		completed = {}
	}
	self.__index = self
	setmetatable(packqueue, self)
	return packqueue
end

function PackQueue:can(pack)
	if pack.after then
		for _, after in ipairs(pack.after) do
			if not self.completed[after] then return false end
		end
	end
	return true
end

function PackQueue:enqueue(pack)
	self.remaining:push_back(pack)
end

function PackQueue:doqueue()
	local counter = 0

	while (self.remaining:__len() > 0) and (counter < self.remaining:__len())  do
		local pack = self.remaining:pop_front()

		if self:can(pack) then
			vim.api.nvim_command("packadd "..pack.short_install_path)
			if pack.config then pack.config() end

			self.completed[pack.short_url] = true

			counter = 0
		else
			self.remaining:push_back(pack)

			counter = counter + 1
		end
	end
end

return { PackQueue = PackQueue }
