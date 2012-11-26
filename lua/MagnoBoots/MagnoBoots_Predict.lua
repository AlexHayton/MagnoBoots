//________________________________
//
//   	Magno Boots for NS2
//		by MCMLXXXIV
//		
//________________________________

// MagnoBoots_Predict.lua

// Set the name of the VM for debugging
decoda_name = "Predict"

// Load the hooks
Script.Load("lua/MagnoBoots/MagnoBoots_SharedHooks.lua")

// Load the main NS2 script for this VM.
Script.Load("lua/Predict.lua")

// Load the shared classes.
Script.Load("lua/MagnoBoots/MagnoBoots_Shared.lua")