//________________________________
//
//   	Magno Boots for NS2
//		by MCMLXXXIV
//		
//________________________________

// MagnoBoots_Marine.lua
MagnoBootsMarine = MagnoBootsMarine or {}
ClassHooker:Mixin("MagnoBootsMarine")
    
// This is where all the hooks are bound to the class. 
// Note that you don't need the SetClassCreatedIn if the class you are hooking has a kMapName, but I have done it here anyway for illustration.
// Calls to ClassHooker just take a class name (they are binding to the class itself)
// Calls to LoadTracker also need to know where the hooked script file is located so they can inject code at the right place.
function MagnoBootsMarine:OnLoad()
   
    ClassHooker:SetClassCreatedIn("Marine", "lua/Marine.lua") 
	LoadTracker:HookFileLoadBefore("lua/Marine.lua", self, "AddScriptLoads")
	ClassHooker:ClassDeclaredCallback("Marine", self, "AddNetworkVars")
    self:PostHookClassFunction("Marine", "OnCreate", "OnCreate_Hook")
	
	LoadTracker:HookFileLoadFinished("lua/Marine.lua", self, "AddNewFunctions")
    
end

// Load any dependent scripts before the main Marine class has loaded
// This allows us to load our custom scripts at exactly the right point.
function MagnoBootsMarine:AddScriptLoads()
	
	Script.Load("lua/MagnoBoots/MagnoBootsMixin.lua")

end

// This function is used to inject any network vars just before the file is loaded.
// You need to do this in ClassDeclaredCallback, like I have done here. 
// Otherwise you can't append to the existing networkVars.
function MagnoBootsMarine:AddNetworkVars(classname, networkVars)

	if (networkVars) then
		AddMixinNetworkVars(MagnoBootsMixin, networkVars)
		
		networkVars["wallWalking"] = "compensated boolean"
		networkVars["timeLastWallWalkCheck"] = "private compensated time"
		networkVars["wallWalkingNormalGoal"] = "private compensated vector (-1 to 1 by 0.001)"
		networkVars["wallWalkingNormalCurrent"] = "private compensated vector (-1 to 1 by 0.001 [ 8 ], -1 to 1 by 0.001 [ 9 ])"
		
		// wallwalking is enabled only after we bump into something that changes our velocity
		// it disables when we are on ground or after we jump or leap
		networkVars["wallWalkingEnabled"] = "private compensated boolean"
		networkVars["timeOfLastJumpLand"] = "private compensated time"
		networkVars["timeLastWallJump"] = "private compensated time"
		networkVars["jumpLandSpeed"] = "private compensated float"
	end
	
	return networkVars

end

// Here I have hooked the create function. Simply initialise our new Mixin.
// The ClassHooker will create a hook to run this code *after* the regular NS2 Marine:OnCreate function.
// Other options are: 
// RawHook = call this code just before the hooked function executes.
// ReplaceHook = replace the function entirely.
// PostHook = call this code just after the hooked function executes.

// There are also options you can pass to be able to access the return value and have multiple return arguments,
// but as they slow down the hooks mechanism slightly you have to set that up specifically.
function MagnoBootsMarine:OnCreate_Hook(self)

	// Init mixins
    InitMixin(self, WallMovementMixin)
	InitMixin(self, MagnoBootsMixin)
	
	// Wall walking stuff
	self.wallWalking = false
    self.wallWalkingNormalCurrent = Vector.yAxis
    self.wallWalkingNormalGoal = Vector.yAxis
    
    if Client then
    
        self.currentCameraRoll = 0
        self.goalCameraRoll = 0
        
    end
    
    self.timeLastWallJump = 0
	
end

// You can add any brand new functions to the Marine class here.
function MagnoBootsMarine:AddNewFunctions()

	// Balance, movement, animation
	Marine.kJumpRepeatTime = 0.1
	Marine.kWallJumpInterval = 0.3

	Marine.kWallWalkCheckInterval = .1
	// This is how quickly the 3rd person model will adjust to the new normal.
	Marine.kWallWalkNormalSmoothRate = 4
	// How big the spheres are that are casted out to find walls, "feelers".
	// The size is calculated so the "balls" touch each other at the end of their range
	Marine.kNormalWallWalkFeelerSize = 0.3
	Marine.kNormalWallWalkRange = 0.35

	// jump is valid when you are close to a wall but not attached yet at this range
	Marine.kJumpWallRange = 0.4
	Marine.kJumpWallFeelerSize = 0.1
	Marine.kMaxVerticalAirAccel = 12

	// when we slow down to less than 97% of previous speed we check for walls to attach to
	Marine.kWallStickFactor = 1

	// force added to player, depends on timing
	Marine.kWallJumpYBoost = 2.5
	Marine.kWallJumpYDirection = 5

	Marine.kMaxVerticalAirAccel = 12

	Marine.kWallJumpForce = 1.2
	Marine.kMinWallJumpSpeed = 9

	Marine.kAirZMoveWeight = 5
	Marine.kAirStrafeWeight = 2.5
	Marine.kAirAccelerationFraction = 0.5

	// required to trigger wall walking animation
	function Marine:GetIsJumping()
	
		return Player.GetIsJumping(self) and not self.wallWalking	
		
	end
	
	// The Marine movement should factor in the vertical velocity
	// only when wall walking.
	function Marine:GetMoveSpeedIs2D()
	
		return not self:GetIsWallWalking()
		
	end
	
	function Marine:GetRecentlyWallJumped()
	
		return self.timeLastWallJump + Marine.kWallJumpInterval > Shared.GetTime()
		
	end
	
	function Marine:GetCanWallJump()
	
		return self:GetIsWallWalking() or (not self:GetIsOnGround() and self:GetAverageWallWalkingNormal(Marine.kJumpWallRange, Marine.kJumpWallFeelerSize) ~= nil)
		
	end

	// Players with magno boots don't need ladders
	function Marine:GetIsOnLadder()

		if self:GetHasMagnoBoots() then
			return false
		else
			return Player.GetIsOnLadder(self)
		end
	
	end
	
	function Marine:GetCanJump()

		return Player.GetCanJump(self) or self:GetCanWallJump()    
		
	end
	
	function Marine:GetIsWallWalking()

		return self.wallWalking
	
	end
	
	function Marine:GetIsWallWalkingPossible() 

		// Can only wall walk if you have magno boots
		return self:GetHasMagnoBoots() and not self.crouching and not self:GetRecentlyJumped()
		
	end
	
	function Marine:PreUpdateMove(input, runningPrediction)

		PROFILE("Marine:PreUpdateMove")
		
		self.moveButtonPressed = input.move:GetLength() ~= 0
		
		if not self.wallWalkingEnabled or not self:GetIsWallWalkingPossible() then
		
			self.wallWalking = false
			
		else

			// Don't check wall walking every frame for performance    
			if (Shared.GetTime() > (self.timeLastWallWalkCheck + Marine.kWallWalkCheckInterval)) then

				// Most of the time, it returns a fraction of 0, which means
				// trace started outside the world (and no normal is returned)           
				local goal = self:GetAverageWallWalkingNormal(Marine.kNormalWallWalkRange, Marine.kNormalWallWalkFeelerSize)
				
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
		
		local fraction = input.time * Marine.kWallWalkNormalSmoothRate
		self.wallWalkingNormalCurrent = self:SmoothWallNormal(self.wallWalkingNormalCurrent, self.wallWalkingNormalGoal, fraction)
	end
	
	function Marine:GetAngleSmoothRate()

		if self:GetIsWallWalking() then
			return 1.5
		end    

		return 7
		
	end
	
	function Marine:GetRollSmoothRate()
		return 4
	end

	function Marine:GetPitchSmoothRate()
		return 3
	end

	function Marine:GetDesiredAngles(deltaTime)

		if self:GetIsWallWalking() then    
			return self:GetAnglesFromWallNormal(self.wallWalkingNormalCurrent, 1)        
		end
		
		return Player.GetDesiredAngles(self)
		
	end 

	function Marine:GetSmoothAngles()

		return not self:GetIsWallWalking()	
		
	end

	local kUpVector = Vector(0, 1, 0)
	function Marine:UpdatePosition(velocity, time)

		PROFILE("Marine:UpdatePosition")

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
				if newSpeed < oldSpeed * Marine.kWallStickFactor then
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

	function Marine:GetRecentlyJumped()

		return not (self.timeOfLastJump == nil or (Shared.GetTime() > (self.timeOfLastJump + Marine.kJumpRepeatTime)))
		
	end

	function Marine:ModifyVelocity(input, velocity)

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
				
					redirectedVelocityZ = redirectedVelocityZ * input.time * Marine.kAirZMoveWeight + GetNormalizedVectorXZ(velocity)
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
				
				redirectedVelocityX = redirectedVelocityX * input.time * Marine.kAirStrafeWeight + GetNormalizedVectorXZ(velocity)
				
				redirectedVelocityX:Normalize()            
				redirectedVelocityX:Scale(moveLengthXZ)
				redirectedVelocityX.y = previousY            
				VectorCopy(redirectedVelocityX,  velocity)
			
			end
			
		end
		
		// accelerate XZ speed when falling down
		if not self:GetIsOnSurface() and velocity:GetLengthXZ() < Marine.kMaxVerticalAirAccel then
		
			local acceleration = 9
			local accelFraction = Clamp( (-velocity.y - 3.5) / 7, 0, 1)
			
			local addAccel = GetNormalizedVectorXZ(velocity) * accelFraction * input.time * acceleration

			velocity.x = velocity.x + addAccel.x
			velocity.z = velocity.z + addAccel.z
			
		end
		
	end

	function Marine:GetFrictionForce(input, velocity)

		local friction = Player.GetFrictionForce(self, input, velocity)
		if self:GetIsWallWalking() then
			friction.y = -self:GetVelocity().y * self:GetGroundFrictionForce()
		end
		
		return friction

	end

	function Marine:GetGravityAllowed()
	
		return not self:GetIsWallWalking()
		
	end

	function Marine:GetIsOnSurface()

		return Player.GetIsOnSurface(self) or self:GetIsWallWalking()
		
	end

	function Marine:GetIsAffectedByAirFriction()
		return not self:GetIsOnSurface()
	end

	function Marine:AdjustGravityForce(input, gravity)

		// No gravity when we're sticking to a wall.
		if self:GetIsWallWalking() then
			gravity = 0
		end
		
		return gravity
		
	end

	function Marine:GetMoveDirection(moveVelocity)

		// Don't constrain movement to XZ so we can walk smoothly up walls
		if self:GetIsWallWalking() then
			return GetNormalizedVector(moveVelocity)
		end
		
		return Player.GetMoveDirection(self, moveVelocity)
		
	end

	function Marine:GetIsCloseToGround(distanceToGround)

		if self:GetIsWallWalking() then
			return false
		end
		
		return Player.GetIsCloseToGround(self, distanceToGround)
		
	end

	function Marine:GetIsOnGround()

		return Player.GetIsOnGround(self) and not self:GetIsWallWalking()    
		
	end

	function Marine:PerformsVerticalMove()

		return self:GetIsWallWalking()
		
	end

	function Marine:GetJumpVelocity(input, velocity)

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
		
				velocity.x = velocity.x + self.bonusVec.x * Marine.kWallJumpForce
				velocity.z = velocity.z + self.bonusVec.z * Marine.kWallJumpForce
				
				local speedXZ = velocity:GetLengthXZ()
				if speedXZ < Marine.kMinWallJumpSpeed then
				
					velocity.y = 0
					velocity:Normalize()
					velocity:Scale(Marine.kMinWallJumpSpeed)
					
				end
				
				velocity.y = viewCoords.zAxis.y * Marine.kWallJumpYDirection + Marine.kWallJumpYBoost

			end
			
			// spamming jump against a wall wont help
			self.timeLastWallJump = Shared.GetTime()
			
		else
			
			velocity.y = math.sqrt(math.abs(2 * self:GetJumpHeight() * self:GetMixinConstants().kGravity))
			
		end
		
		self:TriggerEffects(soundEffectName, {surface = self:GetMaterialBelowPlayer()})
		
	end

	// Handle jump sounds ourselves
	function Marine:GetPlayJumpSound()
		return false
	end

	function Marine:HandleJump(input, velocity)

		local success = Player.HandleJump(self, input, velocity)
		
		if success then
		
			self.wallWalking = false
			self.wallWalkingEnabled = false
		
		end
			
		return success
		
	end
	
end

// This line is important! If you forget it none of these hooks will actually get bound.
// We call it last so that any functions we need are already declared when we come to use them.
// Load the scripts via this mechanism so that we can use the 'self' notation in our loader.
MagnoBootsMarine:OnLoad()