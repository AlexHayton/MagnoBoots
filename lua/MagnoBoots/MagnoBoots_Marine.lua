//________________________________
//
//   	Magno Boots for NS2
//		by MCMLXXXIV
//		
//________________________________

// MagnoBoots_Marine.lua
MagnoBootsMarine = MagnoBootsMarine or {}
ClassHooker:Mixin("MagnoBootsMarine")
    
// This is where all the hooks are bound to the class. 
// Note that you don't need the SetClassCreatedIn if the class you are hooking has a kMapName, but I have done it here anyway for illustration.
// Calls to ClassHooker just take a class name (they are binding to the class itself)
// Calls to LoadTracker also need to know where the hooked script file is located so they can inject code at the right place.
function MagnoBootsMarine:OnLoad()
   
    ClassHooker:SetClassCreatedIn("Marine", "lua/Marine.lua") 
	LoadTracker:HookFileLoadBefore("lua/Marine.lua", self, "AddScriptLoads")
	ClassHooker:ClassDeclaredCallback("Marine", self, "AddNetworkVars")
    self:PostHookClassFunction("Marine", "OnCreate", "OnCreate_Hook")
	
	LoadTracker:HookFileLoadFinished("lua/Marine.lua", self, "AddNewFunctions")
    
end

// Load any dependent scripts before the main Marine class has loaded
// This allows us to load our custom scripts at exactly the right point.
function MagnoBootsMarine:AddScriptLoads()
	
	Script.Load("lua/MagnoBoots/MagnoBootsMixin.lua")

end

// This function is used to inject any network vars just before the file is loaded.
// You need to do this in ClassDeclaredCallback, like I have done here. 
// Otherwise you can't append to the existing networkVars.
function MagnoBootsMarine:AddNetworkVars(classname, networkVars)

	if (networkVars) then
		AddMixinNetworkVars(MagnoBootsMixin, networkVars)
	end
	
	return networkVars

end

// Here I have hooked the create function. Simply initialise our new Mixin.
// The ClassHooker will create a hook to run this code *after* the regular NS2 Marine:OnCreate function.
// Other options are: 
// RawHook = call this code just before the hooked function executes.
// ReplaceHook = replace the function entirely.
// PostHook = call this code just after the hooked function executes.

// There are also options you can pass to be able to access the return value and have multiple return arguments,
// but as they slow down the hooks mechanism slightly you have to set that up specifically.
function MagnoBootsMarine:OnCreate_Hook(self)

    InitMixin(self, WallMovementMixin)
	InitMixin(self, MagnoBootsMixin)
	
end

// You can add any new functions to the Marine class here.
function MagnoBootsMarine:AddNewFunctions()

	function Marine:Test()
		Shared.Message("Test")
	end

end

// This line is important! If you forget it none of these hooks will actually get bound.
// We call it last so that any functions we need are already declared when we come to use them.
// Load the scripts via this mechanism so that we can use the 'self' notation in our loader.
MagnoBootsMarine:OnLoad()