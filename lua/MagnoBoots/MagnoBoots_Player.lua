//________________________________
//
//   	Magno Boots for NS2
//		by MCMLXXXIV
//		
//________________________________

// MagnoBoots_PlayerHooks.lua

MagnoBootsPlayer = MagnoBootsPlayer or {}
MagnoBootsPlayer:Mixin("MagnoBootsPlayer")
    
function MagnoBootsPlayer:OnLoad()
   
    ClassHooker:SetClassCreatedIn("Player", "lua/Player.lua") 
    self:PostHookClassFunction("Player", "Reset", "Reset_Hook")
    
end

function MagnoBootsPlayer:Reset(self)

end