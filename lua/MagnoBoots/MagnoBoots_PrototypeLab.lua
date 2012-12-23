//________________________________
//
//   	Magno Boots for NS2
//		by MCMLXXXIV
//		
//________________________________

// MagnoBoots_PrototypeLab.lua
// Hooks for the PrototypeLab class...

MagnoBootsPrototypeLab = MagnoBootsPrototypeLab or {}
ClassHooker:Mixin("MagnoBootsPrototypeLab")
    
function MagnoBootsPrototypeLab:OnLoad()
   
	ClassHooker:SetClassCreatedIn("PrototypeLab", "lua/PrototypeLab.lua") 
    self:PostHookClassFunction("PrototypeLab", "GetItemList", "GetItemList_Hook"):SetPassHandle(true)
	self:PostHookClassFunction("PrototypeLab", "GetTechButtons", "GetTechButtons_Hook"):SetPassHandle(true)
    
end

function MagnoBootsPrototypeLab:GetItemList_Hook(handle, self)
	
	// Add the magno boots to the prototype lab.
	local itemList = handle:GetReturn()
	table.insert(itemList, kTechId.MagnoBoots)
	handle:SetReturn(itemList)

end

function MagnoBootsPrototypeLab:GetTechButtons_Hook(handle, self)
	
	// Add the magno boots to the prototype lab.
	local techList = handle:GetReturn()
	table.insert(techList, kTechId.MagnoBootsTech)
	handle:SetReturn(techList)

end

MagnoBootsPrototypeLab:OnLoad()