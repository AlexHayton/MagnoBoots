//________________________________
//
//   	Magno Boots for NS2
//		by MCMLXXXIV
//		
//________________________________

if (AddLocaleMessageOverrides) then
	local kMagnoBootsLocaleMessages = {}
	kMagnoBootsLocaleMessages["MAGNO_BOOTS"] = "Magno Boots"
	kMagnoBootsLocaleMessages["MAGNO_BOOTS_TECH"] = "Magno Boots Tech"
	kMagnoBootsLocaleMessages["MAGNO_BOOTS_TOOLTIP"] = "Gives you the ability to walk on walls!"

	// Add these to the locale overrider.
	AddLocaleMessageOverrides(kMagnoBootsLocaleMessages)
end