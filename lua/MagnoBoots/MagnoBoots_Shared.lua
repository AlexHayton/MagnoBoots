//________________________________
//
//   	Magno Boots for NS2
//		by MCMLXXXIV
//		
//________________________________

// MagnoBoots_Shared.lua

// Load the Locale scripts
Script.Load("lua/Locale/OverrideLocale.lua")

// Load the locale data. Localise for clients if supported.
if Client then
	//local locale = Client.GetOptionString( "locale", "enUS" )
	// Test for locale here when we have more languages added.
	Script.Load("gamestrings/MagnoBoots/enUS.lua")
else
	Script.Load("gamestrings/MagnoBoots/enUS.lua")
end

// Load any globally defined classes and script files here.
Script.Load("lua/MagnoBoots/MagnoBoots.lua")