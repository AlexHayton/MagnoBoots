//________________________________
//
//   	Magno Boots for NS2
//		by MCMLXXXIV
//		
//________________________________

// MagnoBoots.lua

Script.Load("lua/ScriptActor.lua")
Script.Load("lua/Mixins/ModelMixin.lua")
Script.Load("lua/TeamMixin.lua")
Script.Load("lua/PickupableMixin.lua")
Script.Load("lua/SelectableMixin.lua")

class 'MagnoBoots' (ScriptActor)

MagnoBoots.kMapName = "magnoboots"

MagnoBoots.kModelName = PrecacheAsset("models/marine/jetpack/jetpack.model")
MagnoBoots.kAttachPoint = "Boots"
MagnoBoots.kPickupSound = PrecacheAsset("sound/NS2.fev/marine/common/pickup_jetpack")

MagnoBoots.kThinkInterval = .5

local networkVars = { }

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ModelMixin, networkVars)
AddMixinNetworkVars(TeamMixin, networkVars)
AddMixinNetworkVars(SelectableMixin, networkVars)

function MagnoBoots:OnCreate ()

    ScriptActor.OnCreate(self)
    
    InitMixin(self, BaseModelMixin)
    InitMixin(self, ModelMixin)
    InitMixin(self, TeamMixin)
    InitMixin(self, SelectableMixin)
    
    InitMixin(self, PickupableMixin, { kRecipientType = "Marine" })
    
end

function MagnoBoots:OnInitialized()

    ScriptActor.OnInitialized(self)    
    self:SetModel(MagnoBoots.kModelName)
    
    local coords = self:GetCoords()

    self.MagnoBootsBody = Shared.CreatePhysicsSphereBody(false, 0.4, 0, coords)
    self.MagnoBootsBody:SetCollisionEnabled(true)    
    self.MagnoBootsBody:SetGroup(PhysicsGroup.WeaponGroup)    
    self.MagnoBootsBody:SetEntity(self)
    
end

function MagnoBoots:OnDestroy() 

    ScriptActor.OnDestroy(self)

    if self.MagnoBootsBody then
    
        Shared.DestroyCollisionObject(self.MagnoBootsBody)
        self.MagnoBootsBody = nil
        
    end

end

function MagnoBoots:OnTouch(recipient)    
end

// only give MagnoBootss to standard marines
function MagnoBoots:GetIsValidRecipient(recipient)
    return not recipient:isa("MagnoBootsMarine") and not recipient:isa("Exo") and not recipient:isa("JetpackMarine")
end

function MagnoBoots:GetIsPermanent()
    return true
end  

function MagnoBoots:GetCanBeUsed(player, useSuccessTable)
    useSuccessTable.useSuccess = self:GetIsValidRecipient(player)      
end  

function MagnoBoots:_GetNearbyRecipient()
end

if Server then

    function MagnoBoots:OnUse(player, elapsedTime, useAttachPoint, usePoint, useSuccessTable)

        if self:GetIsValidRecipient(player) then
            DestroyEntity(self)
            player:GiveMagnoBoots()
        end

    end

end

Shared.LinkClassToMap("MagnoBoots", MagnoBoots.kMapName, networkVars)