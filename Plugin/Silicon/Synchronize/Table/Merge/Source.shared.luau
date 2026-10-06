--!strict

local function Merge(t1: { [any]: any }, t2: { [any]: any }, Override: boolean?): ({ [any]: any })
	Override = Override or false;
	
	for k: any, v: any in t2 do
		if Override or (not Override and ((t1[k] == nil) or next(t1[k]) == nil)) then
			t1[k] = v;
		end
	end

	return t1;
end



return Merge;