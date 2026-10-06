--!strict

local table: typeof(table) = table.clone(table);



local Dependencies = require(script:FindFirstAncestorOfClass('Script').Create.GetDependencies);
local Clone, Merge = (Dependencies.Clone), (Dependencies.Merge);



table.clone = Clone;
table.merge = Merge;



return table;