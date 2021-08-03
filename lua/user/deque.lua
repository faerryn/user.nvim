local Deque = {}

function Deque:new()
  local deque = {
    list = {},
    first = 1,
    last = 0,
  }
  self.__index = self
  setmetatable(deque, self)
  return deque
end

function Deque:len()
  return self.last + 1 - self.first
end

function Deque:front()
  return self.list[self.first]
end

function Deque:back()
  return self.list[self.last]
end

function Deque:pop_front()
  if self:len() == 0 then return nil end
  local value = self:front()
  self.list[self.first] = nil
  self.first = self.first + 1
  return value
end

function Deque:pop_back()
  if self:len() == 0 then return nil end
  local value = self:back()
  self.list[self.back] = nil
  self.last = self.last - 1
  return value
end

function Deque:push_front(value)
  self.first = self.first - 1
  self.list[self.first] = value
end

function Deque:push_back(value)
  self.last = self.last + 1
  self.list[self.last] = value
end

return { Deque = Deque }
