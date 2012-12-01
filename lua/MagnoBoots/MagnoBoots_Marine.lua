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
	LoadTracker:HookFileLoadBefore("Marine", self, "AddScriptLoads")
	ClassHooker:ClassDeclaredCallback("Marine", self, "AddNetworkVars")
    self:PostHookClassFunction("Marine", "OnCreate", "OnCreate_Hook")
	
	LoadTracker:HookFileLoadFinished("lua/Marine.lua", self, "AddNewFunctions")
    
end

function MagnoBootsMarine:AddScriptLoads()
	
	Script.Load("lua/MagnoBoots/MagnoBootsMixin.lua")

end

function MagnoBootsMarine:AddNetworkVars(self, classname, networkVars)

	if (networkVars) then
		AddMixinNetworkVars(MagnoBootsMixin, networkVars)
	end

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