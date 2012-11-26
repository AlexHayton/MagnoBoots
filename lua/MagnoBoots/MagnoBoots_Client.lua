//________________________________
//
//   	Magno Boots for NS2
//		by MCMLXXXIV
//		
//________________________________

// MagnoBoots_Client.lua

// Load the hooks
Script.Load("lua/MagnoBoots/MagnoBoots_SharedHooks.lua")

// Load the main NS2 script for this VM.
Script.Load("lua/Client.lua")

// Load the shared classes.
Script.Load("lua/MagnoBoots/MagnoBoots_Shared.lua")

// Tell the class hooker that we've fully loaded.
ClassHooker:OnLuaFullyLoaded()
