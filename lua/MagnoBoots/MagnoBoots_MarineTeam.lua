//________________________________
//
//   	Magno Boots for NS2
//		by MCMLXXXIV
//		
//________________________________

// MagnoBoots_MarineTeam.lua
// Hooks for the MarineTeam class...

MagnoBootsMarineTeam = MagnoBootsMarineTeam or {}
ClassHooker:Mixin("MagnoBootsMarineTeam")
    
function MagnoBootsMarineTeam:OnLoad()
   
	ClassHooker:SetClassCreatedIn("MarineTeam", "lua/MarineTeam.lua") 
    self:PostHookClassFunction("MarineTeam", "InitTechTree", "InitTechTree_Hook")
    
end

function MagnoBootsMarineTeam:InitTechTree_Hook(self)
	
	// Magno Boots
    self.techTree:AddResearchNode(kTechId.MagnoBootsTech,        kTechId.PrototypeLab, kTechId.TwoCommandStations)
    self.techTree:AddBuyNode(kTechId.MagnoBoots,                 kTechId.MagnoBootsTech, kTechId.TwoCommandStations)
    self.techTree:AddTargetedActivation(kTechId.DropMagnoBoots,     kTechId.MagnoBootsTech, kTechId.TwoCommandStations)
	
	self.techTree:SetComplete()

end

MagnoBootsMarineTeam:OnLoad()