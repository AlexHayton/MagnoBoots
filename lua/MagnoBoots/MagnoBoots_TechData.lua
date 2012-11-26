//________________________________
//
//   	Magno Boots for NS2
//		by MCMLXXXIV
//		
//________________________________

// TechData.lua
// Hooks for the TechData class...

MagnoBootsTechData = MagnoBootsTechData or {}
MagnoBootsTechData:Mixin("MagnoBootsTechData")
    
function MagnoBootsTechData:OnLoad()
   
    self:PostHookFunction("Player", "BuildTechData", "BuildTechData_Hook"):SetPassHandle(true)
    
end

// Insert these upgrades.
local magnoBoots = { [kTechDataId] = kTechId.MagnoBoots,       [kTechDataImplemented] = true,        [kTechDataMapName] = MagnoBoots.kMapName,                   [kTechDataDisplayName] = "MAGNO_BOOTS", [kTechDataModel] = MagnoBoots.kModelName, [kTechDataCostKey] = kMagnoBootsCost, [kTechDataSpawnHeightOffset] = kCommanderEquipmentDropSpawnHeight },
local magnoBootsTech = { [kTechDataId] = kTechId.MagnoBootsTech,     [kTechDataImplemented] = true,      [kTechDataCostKey] = kMagnoBootsTechResearchCost,               [kTechDataResearchTimeKey] = kMagnoBootsTechResearchTime,     [kTechDataDisplayName] = "MAGNO_BOOTS_TECH" },

function MagnoBootsTechData:BuildTechData_Hook(handle)

	local techData = handle:GetReturn()
	table.insert(techData, magnoBoots)
	table.insert(techData, magnoBootsTech)

end