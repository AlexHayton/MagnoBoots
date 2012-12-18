//________________________________
//
//   	Magno Boots for NS2
//		by MCMLXXXIV
//		
//________________________________

// MagnoBootsMixin.lua

Script.Load("lua/FunctionContracts.lua")

MagnoBootsMixin = CreateMixin( MagnoBootsMixin )
MagnoBootsMixin.type = "MagnoBoots"

// Balance, movement, animation
MagnoBootsMixin.kJumpRepeatTime = 0.1
MagnoBootsMixin.kWallJumpInterval = 0.3

MagnoBootsMixin.kWallWalkCheckInterval = .1
// This is how quickly the 3rd person model will adjust to the new normal.
MagnoBootsMixin.kWallWalkNormalSmoothRate = 4
// How big the spheres are that are casted out to find walls, "feelers".
// The size is calculated so the "balls" touch each other at the end of their range
MagnoBootsMixin.kNormalWallWalkFeelerSize = 0.3
MagnoBootsMixin.kNormalWallWalkRange = 0.35

// jump is valid when you are close to a wall but not attached yet at this range
MagnoBootsMixin.kJumpWallRange = 0.4
MagnoBootsMixin.kJumpWallFeelerSize = 0.1
MagnoBootsMixin.kMaxVerticalAirAccel = 12

// when we slow down to less than 97% of previous speed we check for walls to attach to
MagnoBootsMixin.kWallStickFactor = 1

// force added to player, depends on timing
MagnoBootsMixin.kWallJumpYBoost = 2.5
MagnoBootsMixin.kWallJumpYDirection = 5

MagnoBootsMixin.kMaxVerticalAirAccel = 12

MagnoBootsMixin.kWallJumpForce = 1.2
MagnoBootsMixin.kMinWallJumpSpeed = 9

MagnoBootsMixin.kAirZMoveWeight = 5
MagnoBootsMixin.kAirStrafeWeight = 2.5
MagnoBootsMixin.kAirAccelerationFraction = 0.5

MagnoBootsMixin.expectedMixins =
{
	 WallMovement = "Needed for processing the wall walking.",
}

MagnoBootsMixin.expectedCallbacks =
{
}

MagnoBootsMixin.expectedConstants =
{
}

MagnoBootsMixin.networkVars =
{
    wallWalking = "compensated boolean",
    timeLastWallWalkCheck = "private compensated time",
    wallWalkingNormalGoal = "private compensated vector (-1 to 1 by 0.001)",
    wallWalkingNormalCurrent = "private compensated vector (-1 to 1 by 0.001 [ 8 ], -1 to 1 by 0.001 [ 9 ])",
    // wallwalking is enabled only after we bump into something that changes our velocity
    // it disables when we are on ground or after we jump or leap
    wallWalkingEnabled = "private compensated boolean",
    timeOfLastJumpLand = "private compensated time",
    timeLastWallJump = "private compensated time",
    jumpLandSpeed = "private compensated float",
	hasMagnoBoots = "private boolean"
}

function MagnoBootsMixin:__initmixin()

	if self.hasMagnoBoots == nil then
		self.hasMagnoBoots = false
	end
	
	self.wallWalking = false
    self.wallWalkingNormalCurrent = Vector.yAxis
    self.wallWalkingNormalGoal = Vector.yAxis
    
    if Client then
    
        self.currentCameraRoll = 0
        self.goalCameraRoll = 0
        
    end
    
    self.timeLastWallJump = 0

end

function MagnoBootsMixin:GiveMagnoBoots()

	if not self:GetHasMagnoBoots() then
		self.hasMagnoBoots = true
	end
	
end
AddFunctionContract(MagnoBootsMixin.GiveMagnoBoots, { Arguments = { "Entity" }, Returns = { } })

function MagnoBootsMixin:GetHasMagnoBoots()

	return self.hasMagnoBoots
	
end
AddFunctionContract(MagnoBootsMixin.GetHasMagnoBoots, { Arguments = { "Entity" }, Returns = { "boolean" } })

// required to trigger wall walking animation
function MagnoBootsMixin:GetIsJumping()

    return Player.GetIsJumping(self) and not self.wallWalking
	
end
AddFunctionContract(MagnoBootsMixin.GetIsJumping, { Arguments = { "Entity" }, Returns = { "boolean" } })

// The MagnoBootsMixin movement should factor in the vertical velocity
// only when wall walking.
function MagnoBootsMixin:GetMoveSpeedIs2D()

    return not self:GetIsWallWalking()
	
end
AddFunctionContract(MagnoBootsMixin.GetMoveSpeedIs2D, { Arguments = { "Entity" }, Returns = { "boolean" } })

function MagnoBootsMixin:GetRecentlyWallJumped()

    return self.timeLastWallJump + MagnoBootsMixin.kWallJumpInterval > Shared.GetTime()
	
end
AddFunctionContract(MagnoBootsMixin.GetRecentlyWallJumped, { Arguments = { "Entity" }, Returns = { "boolean" } })

function MagnoBootsMixin:GetCanWallJump()

    return self:GetIsWallWalking() or (not self:GetIsOnGround() and self:GetAverageWallWalkingNormal(MagnoBootsMixin.kJumpWallRange, MagnoBootsMixin.kJumpWallFeelerSize) ~= nil)
	
end
AddFunctionContract(MagnoBootsMixin.GetCanWallJump, { Arguments = { "Entity" }, Returns = { "boolean" } })

// Players with magno boots don't need ladders
function MagnoBootsMixin:GetIsOnLadder()

	if self:GetHasMagnoBoots() then
		return false
	else
		return Player.GetIsOnLadder(self)
	end
	
end
AddFunctionContract(MagnoBootsMixin.GetIsOnLadder, { Arguments = { "Entity" }, Returns = { "boolean" } })

function MagnoBootsMixin:GetCanJump()

    return Player.GetCanJump(self) or self:GetCanWallJump()    
	
end
AddFunctionContract(MagnoBootsMixin.GetCanJump, { Arguments = { "Entity" }, Returns = { "boolean" } })

function MagnoBootsMixin:GetIsWallWalking()

    return self.wallWalking
	
end
AddFunctionContract(MagnoBootsMixin.GetIsWallWalking, { Arguments = { "Entity" }, Returns = { "boolean" } })

function MagnoBootsMixin:GetIsWallWalkingPossible() 

	// Can only wall walk if you have magno boots
    return self:GetHasMagnoBoots() and not self.crouching and not self:GetRecentlyJumped()
	
end
AddFunctionContract(MagnoBootsMixin.GetIsWallWalkingPossible, { Arguments = { "Entity" }, Returns = { "boolean" } })

function MagnoBootsMixin:PreUpdateMove(input, runningPrediction)

    PROFILE("MagnoBootsMixin:PreUpdateMove")
    
    self.moveButtonPressed = input.move:GetLength() ~= 0
    
    if not self.wallWalkingEnabled or not self:GetIsWallWalkingPossible() then
    
        self.wallWalking = false
        
    else

        // Don't check wall walking every frame for performance    
        if (Shared.GetTime() > (self.timeLastWallWalkCheck + MagnoBootsMixin.kWallWalkCheckInterval)) then

            // Most of the time, it returns a fraction of 0, which means
            // trace started outside the world (and no normal is returned)           
            local goal = self:GetAverageWallWalkingNormal(MagnoBootsMixin.kNormalWallWalkRange, MagnoBootsMixin.kNormalWallWalkFeelerSize)
            
            if goal ~= nil then
            
                self.wallWalkingNormalGoal = goal
                self.wallWalking = true
                       
            else
                self.wallWalking = false                
            end
            
            self.timeLastWallWalkCheck = Shared.GetTime()
            
        end 
    
    end
    
    if not self:GetIsWallWalking() then
        // When not wall walking, the goal is always directly up (running on ground).
      
        self.wallWalkingNormalGoal = Vector.yAxis
        
        if self:GetIsOnGround() then        
            self.wallWalkingEnabled = false            
        end
    end
    
    local fraction = input.time * MagnoBootsMixin.kWallWalkNormalSmoothRate
    self.wallWalkingNormalCurrent = self:SmoothWallNormal(self.wallWalkingNormalCurrent, self.wallWalkingNormalGoal, fraction)
end
AddFunctionContract(MagnoBootsMixin.PreUpdateMove, { Arguments = { "Entity", "Move", "boolean" }, Returns = { } })

function MagnoBootsMixin:GetAngleSmoothRate()

    if self:GetIsWallWalking() then
        return 1.5
    end    

    return 7
    
end
AddFunctionContract(MagnoBootsMixin.GetAngleSmoothRate, { Arguments = { "Entity" }, Returns = { "number" } })

function MagnoBootsMixin:GetRollSmoothRate()
    return 4
end
AddFunctionContract(MagnoBootsMixin.GetRollSmoothRate, { Arguments = { "Entity" }, Returns = { "number" } })

function MagnoBootsMixin:GetPitchSmoothRate()
    return 3
end
AddFunctionContract(MagnoBootsMixin.GetPitchSmoothRate, { Arguments = { "Entity" }, Returns = { "number" } })

function MagnoBootsMixin:GetDesiredAngles(deltaTime)

    if self:GetIsWallWalking() then    
        return self:GetAnglesFromWallNormal(self.wallWalkingNormalCurrent, 1)        
    end
    
    return Player.GetDesiredAngles(self)
    
end 
AddFunctionContract(MagnoBootsMixin.GetDesiredAngles, { Arguments = { "Entity", "number" }, Returns = { "Vector" } })

function MagnoBootsMixin:GetSmoothAngles()

	return not self:GetIsWallWalking()	
	
end
AddFunctionContract(MagnoBootsMixin.GetSmoothAngles, { Arguments = { "Entity"}, Returns = { "boolean" } })

local kUpVector = Vector(0, 1, 0)
function MagnoBootsMixin:UpdatePosition(velocity, time)

    PROFILE("MagnoBootsMixin:UpdatePosition")

    local yAxis = self.wallWalkingNormalGoal
    local requestedVelocity = Vector(velocity)
    local moveDirection = GetNormalizedVector(velocity)
    local storeSpeed = false
    local hitEntities = nil
    
    if self.adjustToGround then
        velocity.y = 0
        self.adjustToGround = false
    end
    
    local wasOnSurface = self:GetIsOnSurface()
    local oldSpeed = velocity:GetLengthXZ()
    
    velocity, hitEntities, self.averageSurfaceNormal = Player.UpdatePosition(self, velocity, time)
    local newSpeed = velocity:GetLengthXZ()

    if not self.wallWalkingEnabled then

        // we enable wallkwalk if we are no longer on ground but were the previous 
        if wereOnGround and not self:GetIsOnGround() then
            self.wallWalkingEnabled = self:GetIsWallWalkingPossible()
        else
            // we enable wallwalk if our new velocity is significantly smaller than the requested velocity
            if newSpeed < oldSpeed * MagnoBootsMixin.kWallStickFactor then
                self.wallWalkingEnabled = self:GetIsWallWalkingPossible()
                if self.wallWalkingEnabled then
                    storeSpeed = true
                end
            end
        end

    end
    
    if not wasOnSurface and self:GetIsOnSurface() then
        storeSpeed = true
    end
    
    if storeSpeed then

        self.timeOfLastJumpLand = Shared.GetTime()
        self.jumpLandSpeed = requestedVelocity:GetLengthXZ()

    end
    
    // prevent jumping against the same wall constantly as a method to ramp up speed
    local steepImpact = self.averageSurfaceNormal ~= nil and hitEntities == nil and moveDirection:DotProduct(self.averageSurfaceNormal) < -.6
    // never lose speed on ground
    local groundSurface = self.averageSurfaceNormal ~= nil and kUpVector:DotProduct(self.averageSurfaceNormal) > .4
    
    //Print("steepImpact %s, groundSurface %s ",ToString(steepImpact), ToString(groundSurface))

    if steepImpact and not groundSurface then
        SetSpeedDebugText("flup %s", ToString(Shared.GetTime()))
        return velocity
    else
        return requestedVelocity
    end

end
AddFunctionContract(MagnoBootsMixin.UpdatePosition, { Arguments = { "Entity", "Vector", "number" }, Returns = { "Vector" } })

function MagnoBootsMixin:GetRecentlyJumped()

    return not (self.timeOfLastJump == nil or (Shared.GetTime() > (self.timeOfLastJump + MagnoBootsMixin.kJumpRepeatTime)))
	
end
AddFunctionContract(MagnoBootsMixin.GetRecentlyJumped, { Arguments = { "Entity" }, Returns = { "boolean" } })

function MagnoBootsMixin:ModifyVelocity(input, velocity)

    local viewCoords = self:GetViewCoords()

    if self.jumpLandSpeed and self.timeOfLastJumpLand + 0.3 > Shared.GetTime() and input.move:GetLength() ~= 0 then
    
        // check if the current move is in the same direction as the requested move
        local moveXZ = GetNormalizedVectorXZ( viewCoords:TransformVector(input.move) )
        
        if moveXZ:DotProduct(GetNormalizedVectorXZ(velocity)) > 0.5 then
        
            local currentSpeed = velocity:GetLength()
            local prevY = velocity.y
            
            local scale = math.max(1, self.jumpLandSpeed / currentSpeed)        
            velocity:Scale(scale)
            velocity.y = prevY
        
        end
    
    end


    Player.ModifyVelocity(self, input, velocity)


    if not self:GetIsOnSurface() and input.move:GetLength() ~= 0 then

        local moveLengthXZ = velocity:GetLengthXZ()
        local previousY = velocity.y
        local adjustedZ = false

        if input.move.z ~= 0 then
        
            local redirectedVelocityZ = GetNormalizedVectorXZ(self:GetViewCoords().zAxis) * input.move.z
            redirectedVelocityZ.y = 0
            redirectedVelocityZ:Normalize()
            
            if input.move.z < 0 then
            
                if viewCoords:TransformVector(input.move):DotProduct(velocity) > 0 then
                
                    redirectedVelocityZ = redirectedVelocityZ + GetNormalizedVectorXZ(velocity) * 8
                    redirectedVelocityZ:Normalize()
                    
                    local xzVelocity = Vector(velocity)
                    xzVelocity.y = 0
                    
                    VectorCopy(velocity - (xzVelocity * input.time * 2), velocity)
                    
                end
                
            else
            
                redirectedVelocityZ = redirectedVelocityZ * input.time * MagnoBootsMixin.kAirZMoveWeight + GetNormalizedVectorXZ(velocity)
                redirectedVelocityZ:Normalize()                
                redirectedVelocityZ:Scale(moveLengthXZ)
                redirectedVelocityZ.y = previousY
                
                adjustedZ = true
                
                VectorCopy(redirectedVelocityZ,  velocity)
            
            end
        
        end
        
        if input.move.x ~= 0  then
        
            local redirectedVelocityX = GetNormalizedVectorXZ(self:GetViewCoords().xAxis) * input.move.x
            redirectedVelocityX.y = 0
            redirectedVelocityX:Normalize()
            
            redirectedVelocityX = redirectedVelocityX * input.time * MagnoBootsMixin.kAirStrafeWeight + GetNormalizedVectorXZ(velocity)
            
            redirectedVelocityX:Normalize()            
            redirectedVelocityX:Scale(moveLengthXZ)
            redirectedVelocityX.y = previousY            
            VectorCopy(redirectedVelocityX,  velocity)
        
        end
        
    end
	
	// accelerate XZ speed when falling down
    if not self:GetIsOnSurface() and velocity:GetLengthXZ() < MagnoBootsMixin.kMaxVerticalAirAccel then
    
        local acceleration = 9
        local accelFraction = Clamp( (-velocity.y - 3.5) / 7, 0, 1)
        
        local addAccel = GetNormalizedVectorXZ(velocity) * accelFraction * input.time * acceleration

        velocity.x = velocity.x + addAccel.x
        velocity.z = velocity.z + addAccel.z
        
    end
    
end
AddFunctionContract(MagnoBootsMixin.ModifyVelocity, { Arguments = { "Entity", "Move", "Vector" }, Returns = { } })

function MagnoBootsMixin:GetFrictionForce(input, velocity)

    local friction = Player.GetFrictionForce(self, input, velocity)
    if self:GetIsWallWalking() then
        friction.y = -self:GetVelocity().y * self:GetGroundFrictionForce()
    end
    
    return friction

end
AddFunctionContract(MagnoBootsMixin.GetFrictionForce, { Arguments = { "Entity", "Move", "Vector" }, Returns = { "Vector" } })

function MagnoBootsMixin:GetGravityAllowed()
    return not self:GetIsWallWalking()
end
AddFunctionContract(MagnoBootsMixin.GetGravityAllowed, { Arguments = { "Entity" }, Returns = { "boolean" } })

function MagnoBootsMixin:GetIsOnSurface()

    return Player.GetIsOnSurface(self) or self:GetIsWallWalking()
	
end
AddFunctionContract(MagnoBootsMixin.GetIsOnSurface, { Arguments = { "Entity" }, Returns = { "boolean" } })

function MagnoBootsMixin:GetIsAffectedByAirFriction()
    return not self:GetIsOnSurface()
end
AddFunctionContract(MagnoBootsMixin.GetIsAffectedByAirFriction, { Arguments = { "Entity" }, Returns = { "boolean" } })

function MagnoBootsMixin:AdjustGravityForce(input, gravity)

    // No gravity when we're sticking to a wall.
    if self:GetIsWallWalking() then
        gravity = 0
    end
    
    return gravity
    
end
AddFunctionContract(MagnoBootsMixin.AdjustGravityForce, { Arguments = { "Entity" }, Returns = { "boolean" } })

function MagnoBootsMixin:GetMoveDirection(moveVelocity)

    // Don't constrain movement to XZ so we can walk smoothly up walls
    if self:GetIsWallWalking() then
        return GetNormalizedVector(moveVelocity)
    end
    
    return Player.GetMoveDirection(self, moveVelocity)
    
end
AddFunctionContract(MagnoBootsMixin.GetMoveDirection, { Arguments = { "Entity", "Vector" }, Returns = { "Vector" } })

function MagnoBootsMixin:GetIsCloseToGround(distanceToGround)

    if self:GetIsWallWalking() then
        return false
    end
    
    return Player.GetIsCloseToGround(self, distanceToGround)
    
end
AddFunctionContract(MagnoBootsMixin.GetIsCloseToGround, { Arguments = { "Entity", "number" }, Returns = { "number" } })

function MagnoBootsMixin:GetIsOnGround()

    return Player.GetIsOnGround(self) and not self:GetIsWallWalking()    
	
end
AddFunctionContract(MagnoBootsMixin.GetIsOnGround, { Arguments = { "Entity" }, Returns = { "boolean" } })

function MagnoBootsMixin:PerformsVerticalMove()

    return self:GetIsWallWalking()
	
end
AddFunctionContract(MagnoBootsMixin.PerformsVerticalMove, { Arguments = { "Entity" }, Returns = { "boolean" } })

function MagnoBootsMixin:GetJumpVelocity(input, velocity)

    local viewCoords = self:GetViewAngles():GetCoords()
    
    local soundEffectName = "jump"
    
    // we add the bonus in the direction the move is going
    local move = input.move
    move.x = move.x * 0.01
    
    if input.move:GetLength() ~= 0 then
        self.bonusVec = viewCoords:TransformVector(move)
    else
        self.bonusVec = viewCoords.zAxis
    end

    self.bonusVec.y = 0
    self.bonusVec:Normalize()
    
    if self:GetCanWallJump() then
    
        if not self:GetRecentlyWallJumped() then
        
            local previousVelLength = self:GetVelocityLength()
    
            velocity.x = velocity.x + self.bonusVec.x * MagnoBootsMixin.kWallJumpForce
            velocity.z = velocity.z + self.bonusVec.z * MagnoBootsMixin.kWallJumpForce
            
            local speedXZ = velocity:GetLengthXZ()
            if speedXZ < MagnoBootsMixin.kMinWallJumpSpeed then
            
                velocity.y = 0
                velocity:Normalize()
                velocity:Scale(MagnoBootsMixin.kMinWallJumpSpeed)
                
            end
            
            velocity.y = viewCoords.zAxis.y * MagnoBootsMixin.kWallJumpYDirection + MagnoBootsMixin.kWallJumpYBoost

        end
        
        // spamming jump against a wall wont help
        self.timeLastWallJump = Shared.GetTime()
        
    else
        
        velocity.y = math.sqrt(math.abs(2 * self:GetJumpHeight() * self:GetMixinConstants().kGravity))
        
    end
    
    self:TriggerEffects(soundEffectName, {surface = self:GetMaterialBelowPlayer()})
    
end
AddFunctionContract(MagnoBootsMixin.GetJumpVelocity, { Arguments = { "Entity", "Move", "vector" }, Returns = { } })

// Handle jump sounds ourselves
function MagnoBootsMixin:GetPlayJumpSound()
    return false
end
AddFunctionContract(MagnoBootsMixin.GetPlayJumpSound, { Arguments = { "Entity" }, Returns = { "boolean" } })

function MagnoBootsMixin:HandleJump(input, velocity)

    local success = Player.HandleJump(self, input, velocity)
    
    if success then
    
        self.wallWalking = false
        self.wallWalkingEnabled = false
    
    end
        
    return success
    
end
AddFunctionContract(MagnoBootsMixin.HandleJump, { Arguments = { "Entity", "Move", "vector" }, Returns = { "boolean" } })