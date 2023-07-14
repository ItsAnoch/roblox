local PhysicsService = game:GetService('PhysicsService')

local forcePartsCollisioGroup = 'SoftBodiesForceParts'
local softBodyCollisionGroup = 'SoftBodies'

PhysicsService:RegisterCollisionGroup(softBodyCollisionGroup)
PhysicsService:RegisterCollisionGroup(forcePartsCollisioGroup)

PhysicsService:CollisionGroupSetCollidable(softBodyCollisionGroup, forcePartsCollisioGroup, false)

local SoftBody = {}
SoftBody.__index = SoftBody

function SoftBody.new(mesh, inflate, partSize, expansion, stiffness, damping, partConnectionDist)
	local self = setmetatable({}, SoftBody)
	local meshChildren = mesh:GetChildren()
	
	mesh.CollisionGroup = softBodyCollisionGroup
	mesh.CanCollide = false
	mesh.Anchored = true
	
	self.bones = {}
	self.meshCenter = mesh.Position
	self.partConnectionDist = partConnectionDist or 3
	self.expansion = expansion or 2
	self.stiffness = stiffness or 15
	self.damping = damping or 0.1
	self.inflate = inflate or 10
	self.Anchored = false
	
	-- Creating the parts
	for _, child in pairs(meshChildren) do
		if not child:IsA('Bone') then
			continue
		end
		
		local forcePart = Instance.new('Part')
		forcePart.Anchored = self.Anchored
		forcePart.Parent = mesh
		forcePart.Size = partSize
		forcePart.Position = child.WorldPosition 
		forcePart.Name = child.Name
		forcePart.Transparency = 1
		forcePart.Shape = Enum.PartType.Ball
		forcePart.CollisionGroup = forcePartsCollisioGroup
		
		local attachment = Instance.new('Attachment')
		attachment.Parent = forcePart
		
		local vectorForce = Instance.new('VectorForce')
		vectorForce.Parent = attachment
		vectorForce.Attachment0 = attachment
		vectorForce.Force = (forcePart.Position - self.meshCenter).Unit * self.inflate 
		
		local alignOrientation = Instance.new('AngularVelocity')
		alignOrientation.Parent = attachment
		alignOrientation.Attachment0 = attachment
		alignOrientation.MaxTorque = 100
		alignOrientation.AngularVelocity = (forcePart.Position - self.meshCenter).Unit 
		
		
		table.insert(self.bones, { child, forcePart, (forcePart.Position - self.meshCenter) })
	end
	
	-- Connecting the parts with a constraint
	for _, bone in ipairs(self.bones) do
		local forcePart = bone[2]
		local attachment = forcePart:FindFirstChild('Attachment')
			
		for _, boneNeighbor in ipairs(self.bones) do
			local forcePartNeighbor = boneNeighbor[2]
			if forcePart == forcePartNeighbor then 
				continue
			end
			
			local distBetween = (forcePart.Position - forcePartNeighbor.Position).Magnitude
			
			if distBetween > self.partConnectionDist then
				continue
			end
			
			local distFromCenter = (forcePart.Position - self.meshCenter).Magnitude
			
			-- If the parts are relatively close to each other, then connect them
			local neighborAttachment = forcePartNeighbor:FindFirstChild('Attachment')
			
			local spring = Instance.new('SpringConstraint')
			spring.Parent = attachment
			spring.Attachment0 = attachment
			spring.Attachment1 = neighborAttachment
			spring.MaxLength = distBetween + self.expansion - (distFromCenter/2)
			spring.MinLength = distBetween - (distFromCenter/2)
			spring.Stiffness = self.stiffness
			spring.Damping = self.damping
		end
	end
	
	return self
end

function SoftBody:update()
	local bones = self.bones
	for _, bone in ipairs(bones) do
		local forcePart = bone[2]
		local force = bone[3]
		bone = bone[1]
		
		forcePart.Anchored = self.Anchored
		bone.WorldPosition = forcePart.Position
		forcePart.Attachment.VectorForce.Force = force.Unit * self.inflate 
	end
end

return SoftBody
