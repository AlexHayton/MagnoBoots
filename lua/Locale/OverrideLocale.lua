//________________________________
//
//   	Locale Overrides    
//	by Winston Smith (MCMLXXXIV) 2012
//
//________________________________

kOverrideLocaleMessages = {}

// Replace the normal Locale.ResolveString with our own version!
if Locale then
	if Locale.ResolveString then
		local NS2ResolveFunction = Locale.ResolveString

		function Override_ResolveString(input)

			local resolvedString = nil
			if (kOverrideLocaleMessages[input] ~= nil) then
				resolvedString = kOverrideLocaleMessages[input]
			end
			
			if (resolvedString == nil) then
				resolvedString = NS2ResolveFunction(input)
			end
			
			return resolvedString

		end
		
		// Add new locale messages with this
		function AddLocaleMessageOverrides(overrideTable)
		
			for key, message in pairs(overrideTable) do
				kOverrideLocaleMessages[key] = message
			end
		
		end

		Locale.ResolveString = Override_ResolveString
	end
end