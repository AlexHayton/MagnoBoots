//________________________________
//
//   	Magno Boots for NS2
//		by MCMLXXXIV
//		
//________________________________

// MagnoBoots_CommanderHelp.lua
// Hooks for the CommanderHelp class...

MagnoBootsCommanderHelp = MagnoBootsCommanderHelp or {}
ClassHooker:Mixin("MagnoBootsCommanderHelp")
    
function MagnoBootsCommanderHelp:OnLoad()
   
    self:PostHookFunction("CommanderHelp_GetWorldButtons", "CommanderHelp_GetWorldButtons_Hook"):SetPassHandle(true)
    
end

local gGetMarineCommanderHelp = {}
local gGetAlienCommanderHelp = {}

local function BuildCommanderHelpFunctions()

    table.insert(gGetMarineCommanderHelp, {kTechId.MagnoBootsTech, GetResearchHelpFunction("PrototypeLab", kTechId.MagnoBootsTech, -kWorldButtonSize*1.5) })

end

// Add new functions to the Commander Help
function MagnoBootsCommanderHelp:CommanderHelp_GetWorldButtons_Hook(handle)

    local localPlayer = Client.GetLocalPlayer()
    local useFunctions = nil
    local worldButtons = handle:GetReturn()
    
    if not gGetMarineCommanderHelp or not gGetAlienCommanderHelp then
        BuildCommanderHelpFunctions()
    end
    
    if localPlayer then
    
        if GetIsMarineUnit(localPlayer) then
            useFunctions = gGetMarineCommanderHelp    
        elseif GetIsAlienUnit(localPlayer) then
            useFunctions = gGetAlienCommanderHelp   
        end
        
        local teamNumber = localPlayer:GetTeamNumber()
        
        for i = 1, #useFunctions do
        
            local entry = useFunctions[i]
        
            local techId = entry[1]
            local helpFunc = entry[2]
        
            if GetCostForTech(techId) <= localPlayer:GetTeamResources() and GetIsTechAvailable(teamNumber, techId) then
        
                local resultList = helpFunc()
                for j = 1, #resultList do
                    table.insert(worldButtons, { TechId = techId, Position = resultList[j].Position, Entity = resultList[j].Entity })
                end
            
            end
        
        end
    
    end
    
    handle:SetReturn(worldButtons)

end

MagnoBootsCommanderHelp:OnLoad()