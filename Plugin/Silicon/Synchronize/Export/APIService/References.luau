local references = {}

references.Constructors = {
	['Vector3']=Vector3,
	['CFrame']=CFrame,
	['Color3']=Color3,
	['Vector2']=Vector2,
	['Rect']=Rect,
	['UDim']=UDim,
	['PhysicalProperties']=PhysicalProperties,
	['Faces']=Faces,
	['ColorSequence']=ColorSequence,
	['NumberRange']=NumberRange,
	['NumberSequence']=NumberSequence,
	['UDim2']=UDim2,
	['BrickColor']=BrickColor,
	['Region3int16']=Region3int16,
	['Ray']=Ray,
	['TweenInfo']=TweenInfo,
	['Enum']=Enum
}

function references:JSONEncodeValue(value)
	local valueType = typeof(value)
	if valueType == 'number' or valueType == 'string' or valueType == 'nil' or valueType == 'boolean' then
		return value
	elseif valueType == 'Instance' then
		return {value:GetFullName(),0}
	elseif valueType == 'Vector3' or valueType == 'CFrame' or valueType == 'Color3' or valueType == 'Vector2' or valueType == 'Rect' or valueType == 'UDim' or valueType == 'PhysicalProperties' then
		return {tostring(value),1,valueType}
	elseif valueType == 'Faces' then
		return {tostring(value),2}
	elseif valueType == 'ColorSequence' or valueType == 'NumberRange' or valueType == 'NumberSequence' then
		return {tostring(value),3,valueType}
	elseif valueType == 'UDim2' then
		return {{value.X.Scale,value.X.Offset,value.Y.Scale,value.Y.Offset},4}
	elseif valueType == 'BrickColor' or valueType == 'Content' then
		if valueType == 'Content' then
			return tostring(value)
		else
			return {tostring(value),5}
		end
	elseif valueType == 'Region3int16' then
		local min = value.Min
		local max = value.Max
		return {{min.X,min.Y,min.Z,max.X,max.Y,max.Z},6}
	elseif valueType == 'Ray' then
		local origin = value.Origin
		local direction = value.Direction
		return {{origin.X,origin.Y,origin.Z,direction.X,direction.Y,direction.Z},7}
	elseif valueType == 'TweenInfo' then
		return {{value.Time,value.EasingStyle.Value,value.EasingDirection.Value,value.RepeatCount,value.Reverses,value.DelayTime},8}
	elseif valueType == 'EnumItem' then
		return {{tostring(value.EnumType),value.Name},9}
	end
end

function references:JSONDecodeValue(value)
	if typeof(value) ~= 'table' then
		return value
	end
	local source = value[1]
	local id = value[2]
	local construct
	if value[3] then
		construct = references.Constructors[value[3]]
	end
	if id == 1 then
		return construct.new(table.unpack(string.split(source,', ')))
	elseif id == 2 then
		local list = {}
		for _,item in pairs(string.split(source,', ')) do
			table.insert(list,Enum.NormalId[item])
		end
		return Faces.new(table.unpack(list))
	elseif id == 3 then
		return construct.new(table.unpack(string.split(source,' ')))
	elseif id == 4 then
		return UDim2.new(source[1],source[2],source[3],source[4])
	elseif id == 5 then
		return BrickColor.new(source)
	elseif id == 6 then
		return Region3int16.new(Vector3int16.new(source[1],source[2],source[3]),Vector3int16.new(source[4],source[5],source[6]))
	elseif id == 7 then
		return Ray.new(Vector3.new(source[1],source[2],source[3]),Vector3.new(source[4],source[5],source[6]))
	elseif id == 8 then
		return TweenInfo.new(table.unpack(source))
	elseif id == 9 then
		return Enum[source[1]][source[2]]
	elseif id == 0 then
		local attempt,output = pcall(function()
			local target = game
			for _,child in pairs(string.split(source,'.')) do
				target = target[child]
			end
			return target
		end)
		if attempt then
			return output
		end
	else
		return source
	end
end

return references