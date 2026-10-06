--!strict

local Root: Script = script:FindFirstAncestorOfClass('Script');



return setmetatable({ }, {
	---> Calling self.<ScriptName> where `ScriptName` is a descendant of `Root`, which is the plugin's main file, will require the module script with such a name if any.
	---> Calling self.__<ScriptName>__ in lieu, will return the module script instance, without requring it.
	__index = function(t: { }, k: any): (any)
		for _: number, Object: Instance in Root:GetDescendants() do
			local ManuallyRequire: boolean = (string.sub(k, 1, 2) == '__') and (string.sub(k, -2) == '__');
			local N: string = ManuallyRequire and string.sub(k, 3, (#k - 2)) or k;
			
			if ((Object.Name) == N) and Object:IsA('ModuleScript') then
				local Requested: (any);
				
				if ManuallyRequire then
					Requested = Object;
				else
					Requested = require(Object);
				end
				
				rawset(t, N, Requested);
				
				return Requested;
			end
		end
		
		return;
	end
});