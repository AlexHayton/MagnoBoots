//________________________________
//
//   	Magno Boots for NS2
//		by MCMLXXXIV
//		
//________________________________

// MagnoBoots_Marine.lua

MagnoBootsMarine = MagnoBootsMarine or {}
ClassHooker:Mixin("MagnoBootsMarine")
    
function MagnoBootsMarine:OnLoad()
   
    ClassHooker:SetClassCreatedIn("Marine", "lua/Marine.lua") 
    self:PostHookClassFunction("Marine", "OnCreate", "OnCreate_Hook")
	
	LoadTracker:HookFileLoadFinished("lua/Marine.lua", self, "AddNewFunctions")
    
end

function MagnoBootsMarine:OnCreate_Hook(self)

    InitMixin(self, WallMovementMixin)
	InitMixin(self, MagnoBootsMixin)
	
end

function MagnoBootsMarine:AddNewFunctions()

	// No gravity if we are gripping a wall.
	function Marine:AdjustGravityForce(input, gravity)

		if self:GetIsWallGripping() then
			return 0
		end
	
	end

end

MagnoBootsMarine:OnLoad()