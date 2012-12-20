//________________________________
//
//   	Magno Boots for NS2
//		by MCMLXXXIV
//		
//________________________________

// MagnoBootsMixin.lua

Script.Load("lua/FunctionContracts.lua")

MagnoBootsMixin = CreateMixin( MagnoBootsMixin )
MagnoBootsMixin.type = "MagnoBoots"

MagnoBootsMixin.expectedMixins =
{
	 WallMovement = "Needed for processing the wall walking.",
}

MagnoBootsMixin.expectedCallbacks =
{
}

MagnoBootsMixin.expectedConstants =
{
}

MagnoBootsMixin.networkVars =
{
	hasMagnoBoots = "private boolean"
}

function MagnoBootsMixin:__initmixin()

	if self.hasMagnoBoots == nil then
		self.hasMagnoBoots = false
	end

end

function MagnoBootsMixin:GiveMagnoBoots()

	if not self:GetHasMagnoBoots() then
		self.hasMagnoBoots = true
	end
	
end
AddFunctionContract(MagnoBootsMixin.GiveMagnoBoots, { Arguments = { "Entity" }, Returns = { } })

function MagnoBootsMixin:GetHasMagnoBoots()

	return self.hasMagnoBoots
	
end
AddFunctionContract(MagnoBootsMixin.GetHasMagnoBoots, { Arguments = { "Entity" }, Returns = { "boolean" } })