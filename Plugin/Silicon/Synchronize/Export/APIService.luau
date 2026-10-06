--[[

	[Instructions]:
	
	Use "require()" to reference this ModuleScript.
	
	Will automatically warn in Output window when out-of-date.
	
	RobloxAPI: Returns table of Roblox's API dump.
	GetProperties(<Instance>, <boolean> writableOnly): Returns readable properties. ([Name]=Value)
	(Returns writable-only properties if second argument is true. Default is false.)
	GetProperties(<string> ClassName, <boolean> writableOnly): Returns readable properties. (Name only)
	(Returns writable-only properties if second argument is true. Default is false.)
	GetFunctions(<Instance>): Returns readable functions. ([Name]=Value)
	GetEvents(<Instance>): Returns readable events. ([Name]=Value)
	GetClassIcon(<Instance>/<string> ClassName): Returns Icon data for class. Result is the same as StudioService:GetClassIcon().
	GetRawClassData(<string> ClassName): Returns class data for given ClassName from the API dump.
	GetRawSuperclassMembers(<string> ClassName): Returns all superclass members for given ClassName from the API dump.
	GetRawSuperclassProperties(<string> ClassName): Returns all superclass properties for given ClassName from the API dump.
	JSONEncodeValue(<DataType/Property>): Encodes value for use in JSONEncoding.
	JSONDecodeValue(<DataType/Property>): Decodes encoded value from JSON string format. Only compatible with interal "JSONEncodeValue".
	Serialize(<Instance>, <boolean> getDescendants, <boolean> ignoreScripts): Serializes an instance (and descendants if enabled) into a string format.
	(If second argument is true, descendants of the instance will also be serialized. Default is true.)
	(If third argument is true, script source code will be ignored. Default is false.)
	Deserialize(<Instance>): Returns deserialized instance (and descendants if any). Only compatible with interal serialization.
	PrintVersion(<void>): Prints all version information in "Output".
	VersionTime: Returns "os.time()" of version release.
	VersionDateTime: Returns timestamp version release.
	DeveloperVersion: Version number of release.
	DumpVersion: Version of API dump. (Not the version of Roblox API)
	LuaVersion: Returns Lua version used at time of version release.
	CreatorId: Returns the UserId of "API Service" (ModuleScript) developer.
	PrintCredits(<void>): Prints credits in "Output".
	Test(<void>): Returns <bool>"true" if base and required ModuleScripts have been required correctly.
	Constructors: Table of basic constructors. (Mainly used for internal operations.)
	
	
	Attributes of APIService:
		IgnoreUpdates: If true, update warnings will no longer appear in the output.

]]

local APIService = {}

local httpService = game:GetService('HttpService')
local marketPlaceService = game:GetService('MarketplaceService')
local Players = game:GetService('Players')
local memberSort = function(a,b) return string.lower(a.Name) < string.lower(b.Name) end
APIService.AssetLink = 'https://www.roblox.com/library/7995685995/API-Service'
local returnData = require(script:WaitForChild('API'))
if not returnData then
	warn(`\nAPI Service:\nJSON API dump is missing. (This is not a bug.)\nCheck the asset page for more information:\n{APIService.AssetLink}\n`)
	return nil
end
local references = require(script:WaitForChild('References'))
APIService.RobloxAPI = returnData.Raw
APIService.ClassAPI = returnData.Classes
APIService.DeveloperVersion = '1.0.7'
local description = marketPlaceService:GetProductInfo(7995685995).Description
local verLoc = string.find(description,'Version: ')
local latestVersion = 'Unkown'
if verLoc then
	latestVersion = string.sub(description,verLoc + 9)
end
if not script:GetAttribute('IgnoreUpdates') and not verLoc or string.find(description,'#') then
	warn('\n'..script:GetFullName()..': Could not find latest version. Check for updates manually.\nTo update, reinsert the model or download from:\n'..APIService.AssetLink..'\n\n'.."If you're seeing this message and you have required this module via an Id,\nyou're automatically using the latest version and can safely ignore this message.")
end
if not script:GetAttribute('IgnoreUpdates') and verLoc and APIService.DeveloperVersion ~= latestVersion then
	warn('\n'..script:GetFullName()..':\nAPI Service utility ModuleScript is out-of-date.\nReinsert the model or download from:\n'..APIService.AssetLink..'\n')
end
APIService.DumpVersion = APIService.RobloxAPI.Version
APIService.LuaVersion = 'Luau'
APIService.CreatorId = 16554100
function APIService:PrintCredits() print('\nAPI Service Credits:\nCreator: '..Players:GetNameFromUserIdAsync(APIService.CreatorId)..'\nAPI Dump Tool: Github User "MaximumADHD"\n') end
function APIService:PrintVersion() print('\nAPI Service Version: '..APIService.DeveloperVersion..'\nAPI Dump Version: '..APIService.DumpVersion..'\n') end
function APIService:Test() if APIService.RobloxAPI then return true end end
function APIService:GetRawClassData(className)
	local classData = APIService.ClassAPI[className]
	if classData then
		return classData
	end
	warn('Invalid Class: '..className)
end
local cachedRawSuperClassMembers = {}
local function GenerateRawSuperclassMembers(className,superclass)
	className = superclass or className
	local class = APIService:GetRawClassData(className)
	local members = {}
	for _,member in class.Members do
		table.insert(members,member)
	end
	if class.Superclass ~= '<<<ROOT>>>' then
		for _,member in APIService:GetRawSuperclassMembers(class.Superclass) do
			table.insert(members,member)
		end
	end
	table.sort(members,memberSort)
	cachedRawSuperClassMembers[className] = members
	return members
end
function APIService:GetRawSuperclassMembers(className)
	return cachedRawSuperClassMembers[className] or GenerateRawSuperclassMembers(className)
end
function APIService:GetRawSuperclassProperties(className)
	local properties = {}
	for _,member in pairs(APIService:GetRawSuperclassMembers(className)) do
		if member.MemberType == 'Property' then
			table.insert(properties,member)
		end
	end
	return properties
end
function APIService:JSONEncodeValue(value)
	return references:JSONEncodeValue(value)
end
APIService.Constructors = references.Constructors
function APIService:JSONDecodeValue(value)
	return references:JSONDecodeValue(value)
end
function APIService:GetProperties(instance,writableOnly)
	local class = typeof(instance)
	if class ~= 'Instance' and class ~= 'string' then
		warn('"'..tostring(instance)..'" is not an "Instance" or "string"')
		return
	end
	local className = tostring(instance)
	if class == 'Instance' then
		className = instance.ClassName
	end
	local properties = {}
	if not writableOnly then
		for _,property in pairs(APIService:GetRawSuperclassProperties(className)) do
			if class == 'Instance' then
				pcall(function()properties[property.Name] = instance[property.Name]end)
			elseif not table.find(properties,property.Name) and property.Security.Read == 'None' and (not property.Tags or (property.Tags and not table.find(property.Tags,'NotScriptable') and not table.find(property.Tags,'Hidden') and not table.find(property.Tags,'ReadOnly') and not table.find(property.Tags,'Deprecated'))) then
				table.insert(properties,property.Name)
			end
		end
	else
		for _,property in pairs(APIService:GetRawSuperclassProperties(className)) do
			if class == 'Instance' and property.Security.Write == 'None' and property.Security.Read == 'None' and (not property.Tags or (property.Tags and not table.find(property.Tags,'NotScriptable') and not table.find(property.Tags,'ReadOnly') and not table.find(property.Tags,'Hidden') and not table.find(property.Tags,'Deprecated'))) then
				pcall(function()properties[property.Name] = instance[property.Name]end)
			elseif not table.find(properties,property.Name) and property.Security.Write == 'None' and property.Security.Read == 'None' and (not property.Tags or (property.Tags and not table.find(property.Tags,'NotScriptable') and not table.find(property.Tags,'ReadOnly') and not table.find(property.Tags,'Hidden') and not table.find(property.Tags,'Deprecated'))) then
				table.insert(properties,property.Name)
			end
		end
	end
	return properties
end
function APIService:GetFunctions(instance)
	local class = typeof(instance)
	if class ~= 'Instance' and class ~= 'string' then
		warn('"'..tostring(instance)..'" is not an "Instance" or "string"')
		return
	end
	local className = tostring(instance)
	if class == 'Instance' then
		className = instance.ClassName
	end
	local list = {}
	for _,member in pairs(APIService:GetRawSuperclassMembers(className)) do
		if member.MemberType == 'Function' then
			if class == 'Instance' then
				pcall(function()list[member.Name] = instance[member.Name]end)
			elseif not table.find(list,member.Name) then
				table.insert(list,member.Name)
			end
		end
	end
	return list
end
function APIService:GetEvents(instance)
	local class = typeof(instance)
	if class ~= 'Instance' and class ~= 'string' then
		warn('"'..tostring(instance)..'" is not an "Instance" or "string"')
		return
	end
	local className = tostring(instance)
	if class == 'Instance' then
		className = instance.ClassName
	end
	local list = {}
	for _,member in pairs(APIService:GetRawSuperclassMembers(className)) do
		if member.MemberType == 'Event' then
			if class == 'Instance' then
				pcall(function()list[member.Name] = instance[member.Name]end)
			elseif not table.find(list,member.Name) then
				table.insert(list,member.Name)
			end
		end
	end
	return list
end
function APIService:GetClassIcon(instance)
	local class = typeof(instance)
	if class ~= 'Instance' and class ~= 'string' then
		warn('"'..tostring(instance)..'" is not an "Instance" or "string"')
		return
	end
	local className = tostring(instance)
	if class == 'Instance' then
		className = instance.ClassName
	end
	local data = APIService:GetRawClassData(className)
	if data and data.Icon then
		return data.Icon
	end
end

function APIService:Serialize(instance,getDescendants,ignoreScripts)
	if typeof(getDescendants) ~= 'boolean' then
		getDescendants = true
	end
	if typeof(ignoreScripts) ~= 'boolean' then
		ignoreScripts = false
	end
	if typeof(instance) ~= 'Instance' then
		warn('"'..tostring(instance)..'" is not an "Instance"')
		return
	end
	local idList = {}
	local objectList = {}
	local function IdObject(object)
		table.insert(objectList,object)
		table.insert(idList,httpService:GenerateGUID(false))
	end
	IdObject(instance)
	if getDescendants then
		for _,descendant in pairs(instance:GetDescendants()) do
			IdObject(descendant)
		end
	end
	local output = {}
	output.Properties = APIService:GetProperties(instance,true)
	output.ClassName = instance.ClassName
	local foundId = table.find(objectList,instance)
	output.Id = idList[foundId]
	foundId = nil
	output.Parent = nil
	if instance:IsA('BasePart') then
		output.Properties.BrickColor = nil
	end
	if ignoreScripts and instance:IsA('LuaSourceContainer') then
		output.Properties.Source = nil
	end
	for name,value in pairs(output.Properties) do
		if typeof(value) ~= 'Instance' then
			output.Properties[name] = APIService:JSONEncodeValue(value)
		else
			if (value == instance or instance:FindFirstChild(value.Name,true)) and getDescendants then
				local foundId = table.find(objectList,value)
				output.Properties[name] = {idList[foundId],'path'}
				foundId = nil
			else
				output.Properties[name] = APIService:JSONEncodeValue(value)
			end
		end
	end
	output.Attributes = {}
	for name,value in pairs(instance:GetAttributes()) do
		output.Attributes[name] = APIService:JSONEncodeValue(value)
	end
	output.Children = {}
	if getDescendants then
		local function SerializeChildren(parent,object)
			for _,child in pairs(object:GetChildren()) do
				local newChild = {}
				newChild.Properties = APIService:GetProperties(child,true)
				newChild.ClassName = child.ClassName
				newChild.Parent = nil
				if child:IsA('BasePart') then
					newChild.Properties.BrickColor = nil
				end
				if ignoreScripts and child:IsA('LuaSourceContainer') then
					newChild.Properties.Source = nil
				end
				for name,value in pairs(newChild.Properties) do
					if typeof(value) ~= 'Instance' then
						newChild.Properties[name] = APIService:JSONEncodeValue(value)
					else
						if value == instance or instance:FindFirstChild(value.Name,true) then
							newChild.Properties[name] = {idList[table.find(objectList,value)],'path'}
						else
							newChild.Properties[name] = APIService:JSONEncodeValue(value)
						end
					end
				end
				newChild.Attributes = {}
				for name,value in pairs(child:GetAttributes()) do
					newChild.Attributes[name] = APIService:JSONEncodeValue(value)
				end
				newChild.Children = {}
				local foundId = table.find(objectList,child)
				newChild.Id = idList[foundId]
				foundId = nil
				table.insert(parent.Children,newChild)
				task.wait()
				if #child:GetChildren() > 0 then
					SerializeChildren(newChild,child)
				end
				newChild = {}
				child = nil
			end
		end
		SerializeChildren(output,instance)
	end
	return httpService:JSONEncode(output)
end

function APIService:Deserialize(json)
	if typeof(json) ~= 'string' then
		warn('"'..tostring(json)..'" is not a "string"')
		return
	end
	local attempt,output = pcall(function()
		return httpService:JSONDecode(json)
	end)
	if not attempt then
		warn('Attempted to deserialize malformed or non-JSON string')
		return
	end
	local objectQueue = {}
	local main = Instance.new(output.ClassName)
	for name,value in pairs(output.Properties) do
		if name ~= 'ClassName' then
			if typeof(value) == 'table' and value[2] == 'path' then
				table.insert(objectQueue,{Object=main,Name=name,Id=value[1]})
			else
				pcall(function() main[name] = APIService:JSONDecodeValue(value) end)
			end
		end
	end
	for name,value in pairs(output.Attributes) do
		main:SetAttribute(name,APIService:JSONDecodeValue(value))
	end
	output.Object = main
	local function DeserializeChildren(parent,object)
		task.wait()
		for _,child in pairs(parent.Children) do
			local new = Instance.new(child.ClassName,object)
			for name,value in pairs(child.Properties) do
				if name ~= 'ClassName' then
					if typeof(value) == 'table' and value[2] == 'path' then
						table.insert(objectQueue,{Object=new,Name=name,Id=value[1]})
					else
						pcall(function() new[name] = APIService:JSONDecodeValue(value) end)
					end
				end
			end
			for name,value in pairs(child.Attributes) do
				new:SetAttribute(name,APIService:JSONDecodeValue(value))
			end
			child.Object = new
			task.wait()
			if #child.Children > 0 then
				DeserializeChildren(child,new)
			end
			child = nil
			new = nil
		end
	end
	DeserializeChildren(output,main)
	for _,object in pairs(objectQueue) do
		local value
		if output.Id == object.Id then
			value = output.Object
		end
		local function FindId(parent)
			if typeof(parent) ~= 'table' then
				return
			end
			warn(parent,typeof(parent))
			for _,child in parent do
				if typeof(child) == 'table' and child.Id == object.Id then
					return child.Object
				else
					local found
					found = FindId(child)
					if found then
						return found
					end
				end
			end
		end
		if not value then
			value = FindId(output)
		end
		if value then
			pcall(function() object.Object[object.Name] = value end)
		end
	end
	return main
end

return APIService