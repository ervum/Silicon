--!strict

return function(n: number, Length: number?): (string)
	local n: string = tostring(n);

	return `{string.rep('0', ((Length or 2) - #n))}{n}`;
end