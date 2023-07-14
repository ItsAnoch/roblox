-- This is sample usage of the softbodies library
local SoftBody = require(script.Parent.SoftBody)
local body = workspace.Cube

local softbody = SoftBody.new(body)

while wait() do
	--softbody.inflate += 2 -- This code makes the body inflate, gaining size
	softbody:update()
end
