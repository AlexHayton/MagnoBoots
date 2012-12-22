//________________________________
//
//   	Magno Boots for NS2
//		by MCMLXXXIV
//		
//________________________________

// MagnoBoots_CommanderHelp.lua
// Hooks for the CommanderHelp class...

MagnoBootsPlayerClient = MagnoBootsPlayerClient or {}
ClassHooker:Mixin("MagnoBootsPlayerClient")
    
function MagnoBootsPlayerClient:OnLoad()
   
    self:PostHookFunction("InitTechTreeMaterialOffsets", "InitTechTreeMaterialOffsets_Hook")
    
end

// that tier2 and tier3 have the right icons
function MagnoBootsPlayerClient:InitTechTreeMaterialOffsets_Hook()

    // Icons for Magno Boots
    kTechIdToMaterialOffset[kTechId.MagnoBoots] = 77
    kTechIdToMaterialOffset[kTechId.MagnoBootsTech] = 77
	kTechIdToMaterialOffset[kTechId.DropMagnoBoots] = 77
	
end

MagnoBootsPlayerClient:OnLoad()