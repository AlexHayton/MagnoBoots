//________________________________
//
//   	Magno Boots for NS2
//		by MCMLXXXIV
//		
//________________________________

// MagnoBootsMixin.lua

Script.Load("lua/FunctionContracts.lua")
Script.Load("lua/WallMovementMixin.lua")

MagnoBootsMixin = CreateMixin( MagnoBootsMixin )
MagnoBootsMixin.type = "MagnoBoots"

// if the user hits a wall and holds the use key and the resulting speed is < this, grip starts
MagnoBootsMixin.kWallGripMaxSpeed = 4
// once you press grip, you will slide for this long a time and then stop. This is also the time you
// have to release your movement keys, after this window of time, pressing movement keys will release the grip.
MagnoBootsMixin.kWallGripSlideTime = 0.7
// after landing, the y-axis of the model will be adjusted to the wallGripNormal after this time.
MagnoBootsMixin.kWallGripSmoothTime = 0.6

// how to grab for stuff ... same as the skulk tight-in code
MagnoBootsMixin.kWallGripRange = 0.2
MagnoBootsMixin.kWallGripFeelerSize = 0.25

MagnoBootsMixin.expectedMixins =
{
	 WallMovement = "Needed for processing the wall walking.",
}

if Server then

    MagnoBootsMixin.expectedCallbacks =
    {
    }

end

MagnoBootsMixin.expectedConstants =
{
}

MagnoBootsMixin.networkVars =
{
}

function MagnoBootsMixin:__initmixin()

	if self.hasMagnoBoots == nil then
		self.hasMagnoBoots = false
	end
	
	InitMixin(self, WallMovementMixin)

end

function MagnoBootsMixin:GiveMagnoBoots()

	if not self.hasMagnoBoots then
		self.hasMagnoBoots = true
	end
	
end
AddFunctionContract(MagnoBootsMixin.GiveMagnoBoots, { Arguments = { "Entity" }, Returns = { } })

local breakWallGrip = false

function MagnoBootsMixin:OnUpdate(deltaTime)

	if (self.hasMagnoBoots) then
		
		// check if we can grab anything around us
		local wallNormal = self:GetAverageWallWalkingNormal(MagnoBootsMixin.kWallGripRange, MagnoBootsMixin.kWallGripFeelerSize)
		
		if wallNormal then
		
			self.wallGripTime = Shared.GetTime()
			self.wallGripNormalGoal = wallNormal
			self.wallGripRecheckDone = false
			self:SetVelocity(Vector(0,0,0))
			
			// Reduce the player's speed when wallwalking
			
		end
		
		// we always abandon wall gripping if pressing jump or crouch
        local breakWallGrip = (bit.band(input.commands, Move.Jump) ~= 0) or (bit.band(input.commands, Move.Crouch) ~= 0)
        
        if breakWallGrip then
            self.wallGripTime = 0
            self.wallGripNormal = nil
            self.wallGripRecheckDone = false
        end
	end
	
end
AddFunctionContract(MagnoBootsMixin.OnUpdate, { Arguments = { "Entity", "number" }, Returns = { } })

function MagnoBootsMixin:OnDestroy()

	self.hasMagnoBoots = false
	self.wallGripTime = 0
	self.wallGripNormal = nil
	self.wallGripRecheckDone = false
	
end
AddFunctionContract(MagnoBootsMixin.OnDestroy, { Arguments = { "Entity" }, Returns = { } })