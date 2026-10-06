--!strict

local function Clone(t: { [any]: any }): ({ [any]: any })
	local Requested: { [any]: any } = { };

	for k: any, v: any in t or Requested do
		if (typeof(v) ~= 'table') then
			Requested[k] = v;
		else
			Requested[k] = Clone(v);
			
			continue;
		end
	end

	return Requested;
end



return Clone;