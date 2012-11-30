//________________________________
//
//   	Magno Boots for NS2
//		by MCMLXXXIV
//		
//________________________________

// TechData.lua
// Hooks for the TechData class...

MagnoBootsTechData = MagnoBootsTechData or {}
ClassHooker:Mixin("MagnoBootsTechData")
    
function MagnoBootsTechData:OnLoad()
  
	LoadTracker:HookFileLoadFinished("lua/TechTreeConstants.lua", self, "AppendTechIds")
    self:PostHookFunction("BuildTechData", "BuildTechData_Hook"):SetPassHandle(true)
    
end

local function addTechId(techIdName)
	
	// We have to reconstruct the kTechId enum to add values.
	local enumTable = {}
	for index, value in ipairs(kTechId) do
		table.insert(enumTable, value)
	end
	
	table.remove(enumTable, #enumTable)
	table.insert(enumTable, techIdName)
	table.insert(enumTable, 'Max')
	
	kTechId = enum(enumTable)
	kTechIdMax = kTechId.Max
	
end

// Insert these upgrades into kTechId
function MagnoBootsTechData:AppendTechIds()

	addTechId("MagnoBoots")
	addTechId("MagnoBootsTech")
	addTechId("DropMagnoBoots")

end

function MagnoBootsTechData:BuildTechData_Hook(handle)

	local techData = handle:GetReturn()
	
	// Insert upgrades into TechData
	local magnoBoots = { [kTechDataId] = kTechId.MagnoBoots,       [kTechDataImplemented] = true,        [kTechDataMapName] = MagnoBoots.kMapName,                   [kTechDataDisplayName] = "MAGNO_BOOTS", [kTechDataModel] = MagnoBoots.kModelName, [kTechDataCostKey] = kMagnoBootsCost, [kTechDataSpawnHeightOffset] = kCommanderEquipmentDropSpawnHeight }
	local magnoBootsTech = { [kTechDataId] = kTechId.MagnoBootsTech,     [kTechDataImplemented] = true,      [kTechDataCostKey] = kMagnoBootsTechResearchCost,               [kTechDataResearchTimeKey] = kMagnoBootsTechResearchTime,     [kTechDataDisplayName] = "MAGNO_BOOTS_TECH" }
	local dropMagnoBoots = { [kTechDataId] = kTechId.DropMagnoBoots,   [kTechDataMapName] = MagnoBoots.kMapName, [kTechDataDisplayName] = "MAGNO_BOOTS", [kTechIDShowEnables] = false, [kTechDataTooltipInfo] =  "MAGNO_BOOTS_TOOLTIP", [kTechDataModel] = MagnoBoots.kModelName, [kTechDataCostKey] = kMagnoBootsCost, [kStructureAttachId] = kTechId.PrototypeLab, [kStructureAttachRange] = kArmoryWeaponAttachRange, [kStructureAttachRequiresPower] = true }
	
	table.insert(techData, magnoBoots)
	table.insert(techData, magnoBootsTech)
	table.insert(techData, dropMagnoBoots)
	
	handle:SetReturn(techData)

end

MagnoBootsTechData:OnLoad()