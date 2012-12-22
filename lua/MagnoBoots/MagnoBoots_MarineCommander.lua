//________________________________
//
//   	Magno Boots for NS2
//		by MCMLXXXIV
//		
//________________________________

// MagnoBoots_MarineCommander.lua
// Hooks for the MarineCommander class...

MagnoBootsMarineCommander = MagnoBootsMarineCommander or {}
ClassHooker:Mixin("MagnoBootsMarineCommander")

function MagnoBootsMarineCommander:OnLoad()
   
	ClassHooker:SetClassCreatedIn("MarineCommander", "lua/MarineCommander.lua") 
	if Server then 
		self:ReplaceClassFunction("MarineCommander", "ProcessTechTreeActionForEntity", "ProcessTechTreeActionForEntity_Hook")
	elseif Client then
		self:PostHookClassFunction("MarineCommander", "GetButtonTable", "GetButtonTable_Hook"):SetPassHandle(true)
	end
	
end

if Server then

	local function GetIsEquipment(techId)

    return techId == kTechId.DropWelder or techId == kTechId.DropMines or techId == kTechId.DropShotgun or techId == kTechId.DropGrenadeLauncher or
           techId == kTechId.DropFlamethrower or techId == kTechId.DropJetpack or techId == kTechId.DropExosuit or techId == kTechId.DropMagnoBoots 

	end
	
	local function GetIsDroppack(techId)
		return techId == kTechId.MedPack or techId == kTechId.AmmoPack or techId == kTechId.CatPack
	end

	// check if a notification should be send for successful actions
	function MagnoBootsMarineCommander:ProcessTechTreeActionForEntity_Hook(self, techNode, position, normal, pickVec, orientation, entity, trace)

		local techId = techNode:GetTechId()
		local success = false
		local keepProcessing = false
		
		if techId == kTechId.Scan then
			success = self:TriggerScan(position, trace)
			keepProcessing = false
			
		elseif techId == kTechId.NanoShield then
			success = self:TriggerNanoShield(position)   
			keepProcessing = false
		 
		elseif GetIsDroppack(techId) then
			success = self:TriggerDropPack(position, techId)
			keepProcessing = false
			
		elseif GetIsEquipment(techId) then
		
			success = self:AttemptToBuild(techId, position, normal, orientation, pickVec, false, entity)
		
			if success then
				self:ProcessSuccessAction(techId)
				self:TriggerEffects("spawn_weapon", { effecthostcoords = Coords.GetTranslation(position) })
			end    
				
			keepProcessing = false

		else
			success, keepProcessing = Commander.ProcessTechTreeActionForEntity(self, techNode, position, normal, pickVec, orientation, entity, trace)
		end

		if success then

			local location = GetLocationForPoint(position)
			local locationName = location and location:GetName() or ""
			self:TriggerNotification(Shared.GetStringIndex(locationName), techId)
		
		end   
		
		return success, keepProcessing

	end
end

if Client then	
	function MagnoBootsMarineCommander:GetButtonTable_Hook(handle)
		local gMarineMenuButtons = handle:GetReturn()
		for index, menuItem in ipairs(gMarineMenuButtons[kTechId.AssistMenu]) do
			if menuItem == kTechId.None then
				gMarineMenuButtons[kTechId.AssistMenu] = kTechId.DropMagnoBoots
			end
		end
	end
end

MagnoBootsMarineCommander:OnLoad()