--!strict

local Root: Script = script:FindFirstAncestorOfClass('Script');

local T = require(Root.Shared.Types);
local Dependencies = require(Root.Create.GetDependencies);



local Services: { [string]: any } = (Dependencies.Services);
local HTTP: HttpService, D: Debris, SES: ScriptEditorService = (Services.HTTP), (Services.D), (Services.SES);



local Settings: { [string]: any } = (Dependencies.Settings);

local PN: string, AN: string, TN: string, SN: string, DN: string, UN: string, SPN: string = (Settings.PropertiesName), (Settings.AttributesName), (Settings.TagsName), (Settings.SourceName), (Settings.DuplicatedAttributeName), (Settings.UnnamedTableName), (Settings.StringifiedPropertyName);
local MaximumLengthScriptContainer: string, MaximumScriptLength: number = (Settings.MaximumLengthRSScriptContainer), (Settings.MaximumRSScriptLength);
local Host: string = (Settings.ServerHost or 'localhost');
local Port: number = (Settings.ServerPort or 6969);
local RootFolderName: string = (Settings.RootFolderName or 'Silicon');
local PluginFolderName: string = (Settings.PluginFolderName or 'Silicon');
local RecycleBinFolderName: string = (Settings.RecycleBinFolderName or 'Recycle Bin');
local IgnoredAncestors: { [number]: string } = (Settings.IgnoredAncestors or { });



local Variables: { [string]: any } = (Dependencies.Variables);
local IrreplicableClasses: { [number]: string } = (Variables.IrreplicableClasses);
local State: { IsApplyingRemoteUpdate: boolean } = (Variables.State);
local LastKnownScriptHashes: { [string]: string } = (Variables.LastKnownScriptHashes);
local EnsurePluginCopy: (() -> (Instance?)) = (Variables.EnsurePluginCopy);
local GetAncestry: ((Instance) -> ({ [number]: string })) = (Variables.GetAncestry);



local Pad: ((number, number?) -> (string)) = (Dependencies.Pad);
local Connect: { [string]: (( ... any) -> ( ... any)) } = (Dependencies.Connect);
local APIService: { [string]: (( ... any) -> ( ... any)) } = require(Dependencies.__APIService__);



local SyncedServices: { [number]: string } = {
	'Workspace',
	'ReplicatedStorage',
	'ServerScriptService',
	'ServerStorage',
	'StarterPlayer',
	'StarterGui',
	'StarterPack',
	'Lighting',
	'SoundService',
	'MaterialService',
	'Teams',
	'TextChatService',
	'ReplicatedFirst',
	'Chat',
	'LocalizationService',
	'TestService',
};

local LockedClasses: { [string]: boolean } = {
	StarterPlayerScripts      = true,
	StarterCharacterScripts   = true,
	Terrain                   = true,
	Camera                    = true,
	ClientReplicator          = true,
	ChatWindowConfiguration   = true,
	ChatInputBarConfiguration = true,
	ChannelTabsConfiguration  = true,
	BubbleChatConfiguration   = true,
};

local function IsIrreplicable(ClassName: string): (boolean)
	for _: number, IrreplicableClass: string in IrreplicableClasses do
		if (ClassName == IrreplicableClass) then return true end
	end

	return false;
end

local function IsLockedInstance(Object: Instance?): (boolean)
	if not Object or (Object == game) or (Object.Parent == game) or (Object.Parent == nil) then
		return true;
	end

	if Object:IsA('Terrain') or Object:IsA('Camera') then
		return true;
	end

	local ClassName: string = (Object.ClassName);

	if LockedClasses[ClassName] or IsIrreplicable(ClassName) then
		return true;
	end

	return false;
end

local function ResolveHierarchyPath(Path: string, CreateIfMissing: boolean?): (Instance?)
	local Segments: { [number]: string } = string.split(Path, '/');

	if (#Segments == 0) then return nil end

	local FirstSegment: string = Segments[1];
	local CurrentInstance: Instance? = nil;

	local ServiceSuccess: boolean, ServiceResult: any = pcall(function(): (Instance)
		return game:GetService(FirstSegment);
	end);

	if ServiceSuccess and ServiceResult then
		CurrentInstance = ServiceResult;
	else
		CurrentInstance = game:FindFirstChild(FirstSegment);
	end

	if not CurrentInstance then
		if (CreateIfMissing == true) then
			local NewFolder: Folder = Instance.new('Folder');

			NewFolder.Name = FirstSegment;
			NewFolder.Parent = game;

			CurrentInstance = NewFolder;
		else
			return nil;
		end
	end

	for Index: number = 2, #Segments do
		local SegmentName: string = Segments[Index];

		if (SegmentName == '') then continue end

		local Child: Instance? = (CurrentInstance :: Instance):FindFirstChild(SegmentName);

		if not Child then
			if (CreateIfMissing == true) then
				local NewFolder: Folder = Instance.new('Folder');

				NewFolder.Name = SegmentName;
				NewFolder.Parent = CurrentInstance;

				Child = NewFolder;
			else
				return nil;
			end
		end

		CurrentInstance = Child;
	end

	return CurrentInstance;
end



local function IsPluginInternal(Object: Instance?): (boolean)
	if not Object then return false end
	if (Object == Root) or Object:IsDescendantOf(Root) then return true end

	local ServiceSuccess: boolean, ServiceResult: any = pcall(function(): (Instance)
		return game:GetService('ReplicatedStorage');
	end);

	local ReplicatedStorageInstance: Instance? = ServiceSuccess and ServiceResult or game:FindFirstChild('ReplicatedStorage');

	if not ReplicatedStorageInstance then return false end

	local ConfiguredRootFolderName: string = (Settings.RootFolderName or RootFolderName or 'Silicon');
	local ConfiguredPluginFolderName: string = (Settings.PluginFolderName or PluginFolderName or 'Silicon');

	local ConfiguredRoot: Instance? = ReplicatedStorageInstance:FindFirstChild(ConfiguredRootFolderName);

	if ConfiguredRoot then
		local ConfiguredPlugin: Instance? = ConfiguredRoot:FindFirstChild(ConfiguredPluginFolderName);

		if ConfiguredPlugin and ((Object == ConfiguredPlugin) or Object:IsDescendantOf(ConfiguredPlugin)) then
			return true;
		end

		local LegacyPlugin: Instance? = ConfiguredRoot:FindFirstChild('Plugin');

		if LegacyPlugin and ((Object == LegacyPlugin) or Object:IsDescendantOf(LegacyPlugin)) then
			return true;
		end
	end

	local DirectPluginFolder: Instance? = ReplicatedStorageInstance:FindFirstChild(ConfiguredPluginFolderName);

	if DirectPluginFolder and ((Object == DirectPluginFolder) or Object:IsDescendantOf(DirectPluginFolder)) then
		return true;
	end

	return false;
end



local function IsRecycleBinInstance(Object: Instance?): (boolean)
	if not Object then return false end

	local ConfiguredRootFolderName: string = (Settings.RootFolderName or RootFolderName or 'Silicon');
	local ConfiguredBinFolderName: string = (Settings.RecycleBinFolderName or RecycleBinFolderName or 'Recycle Bin');

	local TargetParentName: string = `ReplicatedStorage/{ConfiguredRootFolderName}`;
	local ParentInstance: Instance? = ResolveHierarchyPath(TargetParentName, false);

	if ParentInstance then
		local ConfiguredBin: Instance? = ParentInstance:FindFirstChild(ConfiguredBinFolderName);

		if ConfiguredBin and ((Object == ConfiguredBin) or Object:IsDescendantOf(ConfiguredBin)) then
			return true;
		end
	end

	local ServiceSuccess: boolean, ServiceResult: any = pcall(function(): (Instance)
		return game:GetService('ReplicatedStorage');
	end);

	local ReplicatedStorageInstance: Instance? = ServiceSuccess and ServiceResult or game:FindFirstChild('ReplicatedStorage');

	if ReplicatedStorageInstance then
		local ConfiguredRoot: Instance? = ReplicatedStorageInstance:FindFirstChild(ConfiguredRootFolderName);

		if ConfiguredRoot then
			local RootBin: Instance? = ConfiguredRoot:FindFirstChild(ConfiguredBinFolderName);

			if RootBin and ((Object == RootBin) or Object:IsDescendantOf(RootBin)) then
				return true;
			end
		end

		local LegacyBin: Instance? = ReplicatedStorageInstance:FindFirstChild('Recycle Bin');

		if LegacyBin and ((Object == LegacyBin) or Object:IsDescendantOf(LegacyBin)) then
			return true;
		end
	end

	return false;
end



local function IsIgnored(Object: Instance): (boolean)
	if IsPluginInternal(Object) then return true end
	if IsRecycleBinInstance(Object) then return true end

	if Object:FindFirstAncestorOfClass('CoreGui') then return true end

	if not Object:IsDescendantOf(game) and (Object ~= game) then return true end

	if Object:IsA('Terrain') or Object:IsA('Camera') then return true end

	for _: number, IgnoredName: string in IgnoredAncestors do
		if (Object.Name == IgnoredName) or Object:FindFirstAncestor(IgnoredName) then
			return true;
		end
	end

	return false;
end

local function GetOrCreateRecycleBin(): (Instance)
	local ConfiguredRootFolderName: string = (Settings.RootFolderName or RootFolderName or 'Silicon');
	local ConfiguredBinFolderName: string = (Settings.RecycleBinFolderName or RecycleBinFolderName or 'Recycle Bin');

	local TargetParentName: string = `ReplicatedStorage/{ConfiguredRootFolderName}`;
	local ParentInstance: Instance? = ResolveHierarchyPath(TargetParentName, true);

	if not ParentInstance then
		local RepStorageSuccess: boolean, RepStorage: any = pcall(function(): (Instance)
			return game:GetService('ReplicatedStorage');
		end);

		ParentInstance = RepStorageSuccess and RepStorage or game:FindFirstChild('ReplicatedStorage');
	end

	local Bin: Instance? = (ParentInstance :: Instance):FindFirstChild(ConfiguredBinFolderName);

	if not Bin then
		local NewBin: Folder = Instance.new('Folder');

		NewBin.Name = ConfiguredBinFolderName;
		NewBin.Parent = ParentInstance;

		Bin = NewBin;
	end

	---> Migrate legacy Recycle Bin if it exists under ReplicatedStorage directly
	local RepStorageSuccess: boolean, RepStorage: any = pcall(function(): (Instance)
		return game:GetService('ReplicatedStorage');
	end);

	local RootRepStorage: Instance? = RepStorageSuccess and RepStorage or game:FindFirstChild('ReplicatedStorage');

	if RootRepStorage then
		local LegacyBin: Instance? = RootRepStorage:FindFirstChild('Recycle Bin');

		if LegacyBin and (LegacyBin ~= Bin) then
			for _: number, LegacyChild: Instance in LegacyBin:GetChildren() do
				LegacyChild.Parent = Bin;
			end

			LegacyBin:Destroy();
		end
	end

	return (Bin :: Instance);
end

local function ExtractNumbersFromString(RawString: string): ({ [number]: number })
	local ExtractedNumbers: { [number]: number } = { };
	local SanitizedString: string = string.gsub(string.gsub(RawString, '[{}()]', ' '), ',', ' ');

	for Token: string in string.gmatch(SanitizedString, '%S+') do
		local ParsedNumber: number? = tonumber(Token);

		if (ParsedNumber ~= nil) then
			table.insert(ExtractedNumbers, ParsedNumber);
		end
	end

	return ExtractedNumbers;
end

local StringDeserializers: { [string]: ((string, any?, Instance?, string?) -> (any)) } = {
	['CFrame'] = function(RawString: string, _: any?, _: Instance?, _: string?): (any)
		local Numbers: { [number]: number } = ExtractNumbersFromString(RawString);

		if (#Numbers == 12) then
			return CFrame.new(table.unpack(Numbers));
		elseif (#Numbers == 3) then
			return CFrame.new(Numbers[1], Numbers[2], Numbers[3]);
		elseif (#Numbers == 7) then
			return CFrame.new(Numbers[1], Numbers[2], Numbers[3], Numbers[4], Numbers[5], Numbers[6], Numbers[7]);
		end

		return nil;
	end,

	['Vector3'] = function(RawString: string, _: any?, _: Instance?, _: string?): (any)
		local Numbers: { [number]: number } = ExtractNumbersFromString(RawString);

		if (#Numbers >= 3) then
			return Vector3.new(Numbers[1], Numbers[2], Numbers[3]);
		elseif (#Numbers == 1) then
			return Vector3.new(Numbers[1], Numbers[1], Numbers[1]);
		end

		return nil;
	end,

	['Vector2'] = function(RawString: string, _: any?, _: Instance?, _: string?): (any)
		local Numbers: { [number]: number } = ExtractNumbersFromString(RawString);

		if (#Numbers >= 2) then
			return Vector2.new(Numbers[1], Numbers[2]);
		elseif (#Numbers == 1) then
			return Vector2.new(Numbers[1], Numbers[1]);
		end

		return nil;
	end,

	['Color3'] = function(RawString: string, _: any?, _: Instance?, _: string?): (any)
		local Trimmed: string = string.gsub(RawString, '^%s*(.-)%s*$', '%1');

		if (string.sub(Trimmed, 1, 1) == '#') then
			local HexSuccess: boolean, HexColor: any = pcall(function(): (Color3)
				return Color3.fromHex(Trimmed);
			end);

			if HexSuccess and HexColor then
				return HexColor;
			end
		end

		local Numbers: { [number]: number } = ExtractNumbersFromString(RawString);

		if (#Numbers >= 3) then
			if (Numbers[1] > 1.0) or (Numbers[2] > 1.0) or (Numbers[3] > 1.0) then
				return Color3.fromRGB(Numbers[1], Numbers[2], Numbers[3]);
			else
				return Color3.new(Numbers[1], Numbers[2], Numbers[3]);
			end
		end

		return nil;
	end,

	['UDim2'] = function(RawString: string, _: any?, _: Instance?, _: string?): (any)
		local Numbers: { [number]: number } = ExtractNumbersFromString(RawString);

		if (#Numbers >= 4) then
			return UDim2.new(Numbers[1], Numbers[2], Numbers[3], Numbers[4]);
		elseif (#Numbers == 2) then
			return UDim2.new(Numbers[1], 0, Numbers[2], 0);
		end

		return nil;
	end,

	['UDim'] = function(RawString: string, _: any?, _: Instance?, _: string?): (any)
		local Numbers: { [number]: number } = ExtractNumbersFromString(RawString);

		if (#Numbers >= 2) then
			return UDim.new(Numbers[1], Numbers[2]);
		elseif (#Numbers == 1) then
			return UDim.new(Numbers[1], 0);
		end

		return nil;
	end,

	['Rect'] = function(RawString: string, _: any?, _: Instance?, _: string?): (any)
		local Numbers: { [number]: number } = ExtractNumbersFromString(RawString);

		if (#Numbers >= 4) then
			return Rect.new(Numbers[1], Numbers[2], Numbers[3], Numbers[4]);
		end

		return nil;
	end,

	['NumberRange'] = function(RawString: string, _: any?, _: Instance?, _: string?): (any)
		local Numbers: { [number]: number } = ExtractNumbersFromString(RawString);

		if (#Numbers >= 2) then
			return NumberRange.new(Numbers[1], Numbers[2]);
		elseif (#Numbers == 1) then
			return NumberRange.new(Numbers[1]);
		end

		return nil;
	end,

	['NumberSequence'] = function(RawString: string, _: any?, _: Instance?, _: string?): (any)
		local Numbers: { [number]: number } = ExtractNumbersFromString(RawString);

		if (#Numbers == 1) then
			return NumberSequence.new(Numbers[1]);
		elseif (#Numbers == 2) then
			return NumberSequence.new(Numbers[1], Numbers[2]);
		elseif ((#Numbers % 2) == 0) and (#Numbers >= 4) then
			local Keypoints: { [number]: NumberSequenceKeypoint } = { };

			for Index: number = 1, #Numbers, 2 do
				table.insert(Keypoints, NumberSequenceKeypoint.new(Numbers[Index], Numbers[(Index + 1)]));
			end

			local SequenceSuccess: boolean, SequenceResult: any = pcall(function(): (NumberSequence)
				return NumberSequence.new(Keypoints);
			end);

			if SequenceSuccess and SequenceResult then
				return SequenceResult;
			end
		end

		return nil;
	end,

	['ColorSequence'] = function(RawString: string, _: any?, _: Instance?, _: string?): (any)
		local Trimmed: string = string.gsub(RawString, '^%s*(.-)%s*$', '%1');

		if (string.sub(Trimmed, 1, 1) == '#') then
			local HexSuccess: boolean, HexColor: any = pcall(function(): (Color3)
				return Color3.fromHex(Trimmed);
			end);

			if HexSuccess and HexColor then
				return ColorSequence.new(HexColor);
			end
		end

		local Numbers: { [number]: number } = ExtractNumbersFromString(RawString);

		if (#Numbers >= 3) then
			local SingleColor: Color3 = ((Numbers[1] > 1.0) or (Numbers[2] > 1.0) or (Numbers[3] > 1.0))
				and Color3.fromRGB(Numbers[1], Numbers[2], Numbers[3])
				or Color3.new(Numbers[1], Numbers[2], Numbers[3]);

			return ColorSequence.new(SingleColor);
		end

		return nil;
	end,

	['BrickColor'] = function(RawString: string, _: any?, _: Instance?, _: string?): (any)
		local Trimmed: string = string.gsub(RawString, '^%s*(.-)%s*$', '%1');
		local ParsedNumber: number? = tonumber(Trimmed);

		if (ParsedNumber ~= nil) then
			local NumSuccess: boolean, NumResult: any = pcall(function(): (BrickColor)
				return BrickColor.new(ParsedNumber :: number);
			end);

			if NumSuccess and NumResult then
				return NumResult;
			end
		end

		local StrSuccess: boolean, StrResult: any = pcall(function(): (BrickColor)
			return BrickColor.new(Trimmed);
		end);

		if StrSuccess and StrResult then
			return StrResult;
		end

		return nil;
	end,

	['EnumItem'] = function(RawString: string, CurrentValue: any?, _: Instance?, PropertyName: string?): (any)
		local Trimmed: string = string.gsub(RawString, '^%s*(.-)%s*$', '%1');

		if CurrentValue and (typeof(CurrentValue) == 'EnumItem') then
			local TargetEnumType: any = CurrentValue.EnumType;

			if TargetEnumType then
				local ItemName: string = Trimmed;

				if string.find(ItemName, '.', 1, true) then
					local Segments: { [number]: string } = string.split(ItemName, '.');
					ItemName = Segments[#Segments];
				end

				if TargetEnumType[ItemName] then
					return TargetEnumType[ItemName];
				end
			end
		end

		if string.find(Trimmed, '^Enum%.') then
			local Segments: { [number]: string } = string.split(Trimmed, '.');

			if (#Segments >= 3) then
				local EnumTypeGroup: any = (Enum :: any)[Segments[2]];

				if EnumTypeGroup and EnumTypeGroup[Segments[3]] then
					return EnumTypeGroup[Segments[3]];
				end
			end
		end

		if PropertyName then
			local EnumTypeGroup: any = (Enum :: any)[PropertyName];

			if EnumTypeGroup and EnumTypeGroup[Trimmed] then
				return EnumTypeGroup[Trimmed];
			end
		end

		return nil;
	end,

	['PhysicalProperties'] = function(RawString: string, _: any?, _: Instance?, _: string?): (any)
		local Numbers: { [number]: number } = ExtractNumbersFromString(RawString);

		if (#Numbers >= 5) then
			return PhysicalProperties.new(Numbers[1], Numbers[2], Numbers[3], Numbers[4], Numbers[5]);
		elseif (#Numbers >= 3) then
			return PhysicalProperties.new(Numbers[1], Numbers[2], Numbers[3]);
		end

		return nil;
	end,

	['Ray'] = function(RawString: string, _: any?, _: Instance?, _: string?): (any)
		local Numbers: { [number]: number } = ExtractNumbersFromString(RawString);

		if (#Numbers >= 6) then
			return Ray.new(
				Vector3.new(Numbers[1], Numbers[2], Numbers[3]),
				Vector3.new(Numbers[4], Numbers[5], Numbers[6])
			);
		end

		return nil;
	end,

	['boolean'] = function(RawString: string, _: any?, _: Instance?, _: string?): (any)
		local Lower: string = string.lower(string.gsub(RawString, '^%s*(.-)%s*$', '%1'));

		if (Lower == 'true') or (Lower == '1') or (Lower == 'yes') then
			return true;
		elseif (Lower == 'false') or (Lower == '0') or (Lower == 'no') then
			return false;
		end

		return nil;
	end,

	['number'] = function(RawString: string, _: any?, _: Instance?, _: string?): (any)
		return tonumber(string.gsub(RawString, '^%s*(.-)%s*$', '%1'));
	end,
};

local function DecodePropertyValue(Value: any, PropertyName: string?, TargetObject: Instance?): (any)
	if (Value == nil) then return nil end

	---> Step 1: Check legacy APIService JSON-encoded tuples ({ source, id, type })
	local DecodedAttempt: boolean, DecodedResult: any = pcall(function(): (any)
		return APIService:JSONDecodeValue(Value);
	end);

	if DecodedAttempt and (DecodedResult ~= nil) and (DecodedResult ~= Value) then
		return DecodedResult;
	end

	---> Step 2: Determine expected property type from target object if available
	local TargetType: string? = nil;
	local CurrentPropertyValue: any = nil;

	if TargetObject and PropertyName then
		local ReadSuccess: boolean, ReadResult: any = pcall(function(): (any)
			return (TargetObject :: any)[PropertyName];
		end);

		if ReadSuccess and (ReadResult ~= nil) then
			CurrentPropertyValue = ReadResult;
			TargetType = typeof(ReadResult);
		end
	end

	---> Step 3: String deserialization via dedicated converter dispatcher
	if (type(Value) == 'string') then
		local RawString: string = Value;

		if TargetType and StringDeserializers[TargetType] then
			local ConvertedValue: any = StringDeserializers[TargetType](RawString, CurrentPropertyValue, TargetObject, PropertyName);

			if (ConvertedValue ~= nil) then
				return ConvertedValue;
			end
		end

		---> Fallback heuristics when TargetType was not resolved
		local TrimmedString: string = string.gsub(RawString, '^%s*(.-)%s*$', '%1');

		if string.find(TrimmedString, '^Enum%.') then
			local EnumResult: any = StringDeserializers.EnumItem(TrimmedString, nil, TargetObject, PropertyName);

			if (EnumResult ~= nil) then
				return EnumResult;
			end
		end

		if (string.sub(TrimmedString, 1, 1) == '#') then
			local HexColor: any = StringDeserializers.Color3(TrimmedString, nil, TargetObject, PropertyName);

			if (HexColor ~= nil) then
				return HexColor;
			end
		end

		if string.find(TrimmedString, '^{.*},%s*{.*}$') then
			local UDim2Result: any = StringDeserializers.UDim2(TrimmedString, nil, TargetObject, PropertyName);

			if (UDim2Result ~= nil) then
				return UDim2Result;
			end
		end

		if string.find(TrimmedString, '^{.*}$') then
			local UDimResult: any = StringDeserializers.UDim(TrimmedString, nil, TargetObject, PropertyName);

			if (UDimResult ~= nil) then
				return UDimResult;
			end
		end

		local ExtractedNumbers: { [number]: number } = ExtractNumbersFromString(RawString);
		local ExtractedCount: number = #ExtractedNumbers;

		if (ExtractedCount == 12) then
			return CFrame.new(table.unpack(ExtractedNumbers));
		elseif (ExtractedCount == 4) then
			if PropertyName and (string.find(PropertyName, 'Rect') ~= nil) then
				return Rect.new(table.unpack(ExtractedNumbers));
			else
				return UDim2.new(table.unpack(ExtractedNumbers));
			end
		elseif (ExtractedCount == 3) then
			if PropertyName and (string.find(PropertyName, 'Color') ~= nil) then
				if (ExtractedNumbers[1] > 1.0) or (ExtractedNumbers[2] > 1.0) or (ExtractedNumbers[3] > 1.0) then
					return Color3.fromRGB(ExtractedNumbers[1], ExtractedNumbers[2], ExtractedNumbers[3]);
				else
					return Color3.new(ExtractedNumbers[1], ExtractedNumbers[2], ExtractedNumbers[3]);
				end
			else
				return Vector3.new(ExtractedNumbers[1], ExtractedNumbers[2], ExtractedNumbers[3]);
			end
		elseif (ExtractedCount == 2) then
			if PropertyName and ((string.find(PropertyName, 'Range') ~= nil) or (string.find(PropertyName, 'Lifetime') ~= nil)) then
				return NumberRange.new(ExtractedNumbers[1], ExtractedNumbers[2]);
			elseif PropertyName and (string.find(PropertyName, 'Padding') ~= nil) then
				return UDim.new(ExtractedNumbers[1], ExtractedNumbers[2]);
			else
				return Vector2.new(ExtractedNumbers[1], ExtractedNumbers[2]);
			end
		end

		if PropertyName then
			local EnumResult: any = StringDeserializers.EnumItem(TrimmedString, nil, TargetObject, PropertyName);

			if (EnumResult ~= nil) then
				return EnumResult;
			end
		end
	end

	---> Step 4: Table deserialization (JSON / YAML numeric arrays and dictionaries)
	if (type(Value) == 'table') then
		local TableLength: number = #Value;

		if (TargetType == 'CFrame') then
			if (TableLength == 12) then
				return CFrame.new(table.unpack(Value));
			elseif (TableLength == 3) then
				return CFrame.new(Value[1], Value[2], Value[3]);
			end
		end

		if (TargetType == 'Vector3') and (TableLength >= 3) then
			return Vector3.new(Value[1], Value[2], Value[3]);
		end

		if (TargetType == 'Color3') and (TableLength >= 3) then
			if (Value[1] > 1.0) or (Value[2] > 1.0) or (Value[3] > 1.0) then
				return Color3.fromRGB(Value[1], Value[2], Value[3]);
			else
				return Color3.new(Value[1], Value[2], Value[3]);
			end
		end

		if (TargetType == 'UDim2') and (TableLength >= 4) then
			return UDim2.new(Value[1], Value[2], Value[3], Value[4]);
		end

		if (TargetType == 'UDim') and (TableLength >= 2) then
			return UDim.new(Value[1], Value[2]);
		end

		if (TargetType == 'Vector2') and (TableLength >= 2) then
			return Vector2.new(Value[1], Value[2]);
		end

		if (TargetType == 'NumberRange') and (TableLength >= 2) then
			return NumberRange.new(Value[1], Value[2]);
		end

		if (TableLength == 3) and (type(Value[1]) == 'number') and (type(Value[2]) == 'number') and (type(Value[3]) == 'number') then
			if PropertyName and (string.find(PropertyName, 'Color') ~= nil) then
				if (Value[1] > 1.0) or (Value[2] > 1.0) or (Value[3] > 1.0) then
					return Color3.fromRGB(Value[1], Value[2], Value[3]);
				else
					return Color3.new(Value[1], Value[2], Value[3]);
				end
			else
				return Vector3.new(Value[1], Value[2], Value[3]);
			end
		end

		if (TableLength == 12) then
			local AllNumbers: boolean = true;

			for _: number, NumericVal: any in Value do
				if (type(NumericVal) ~= 'number') then
					AllNumbers = false;
					break;
				end
			end

			if AllNumbers then
				return CFrame.new(table.unpack(Value));
			end
		end

		if (TableLength == 4) and (type(Value[1]) == 'number') and (type(Value[2]) == 'number') and (type(Value[3]) == 'number') and (type(Value[4]) == 'number') then
			if PropertyName and (string.find(PropertyName, 'Rect') ~= nil) then
				return Rect.new(Value[1], Value[2], Value[3], Value[4]);
			else
				return UDim2.new(Value[1], Value[2], Value[3], Value[4]);
			end
		end

		if (TableLength == 2) and (type(Value[1]) == 'number') and (type(Value[2]) == 'number') then
			if PropertyName and ((string.find(PropertyName, 'Range') ~= nil) or (string.find(PropertyName, 'Lifetime') ~= nil)) then
				return NumberRange.new(Value[1], Value[2]);
			elseif PropertyName and (string.find(PropertyName, 'Padding') ~= nil) then
				return UDim.new(Value[1], Value[2]);
			else
				return Vector2.new(Value[1], Value[2]);
			end
		end

		if Value.X and Value.Y and Value.Z and (type(Value.X) == 'number') and (type(Value.Y) == 'number') and (type(Value.Z) == 'number') then
			return Vector3.new(Value.X, Value.Y, Value.Z);
		end

		if Value.R and Value.G and Value.B and (type(Value.R) == 'number') and (type(Value.G) == 'number') and (type(Value.B) == 'number') then
			return Color3.new(Value.R, Value.G, Value.B);
		end

		if Value.Scale and Value.Offset and (type(Value.Scale) == 'number') and (type(Value.Offset) == 'number') then
			return UDim.new(Value.Scale, Value.Offset);
		end

		if Value.Min and Value.Max and (type(Value.Min) == 'number') and (type(Value.Max) == 'number') then
			return NumberRange.new(Value.Min, Value.Max);
		end
	end

	return Value;
end

local function ApplyPropertiesToObject(Object: Instance, Properties: { [string]: any }?, Attributes: { [string]: any }?, Tags: { [number]: string }?): ()
	if Properties then
		for PropertyName: string, RawValue: any in Properties do
			if (PropertyName == 'Name') or (PropertyName == 'Parent') or (PropertyName == 'Source') then
				continue;
			end

			if (PropertyName == 'BrickColor') and (Properties.Color ~= nil) then
				continue;
			end

			local DecodedValue: any = DecodePropertyValue(RawValue, PropertyName, Object);

			if (DecodedValue ~= nil) then
				pcall(function(): ()
					(Object :: any)[PropertyName] = DecodedValue;
				end);
			end
		end
	end

	if Attributes then
		for AttributeKey: string, RawAttrValue: any in Attributes do
			local DecodedAttr: any = DecodePropertyValue(RawAttrValue, nil, Object);

			pcall(function(): ()
				Object:SetAttribute(AttributeKey, DecodedAttr);
			end);
		end
	end

	if Tags then
		for _: number, TagName: string in Tags do
			pcall(function(): ()
				Object:AddTag(TagName);
			end);
		end
	end

	return;
end

local function FindInstanceByRelativePath(RelativePath: string): (Instance?)
	if (RelativePath == '') then return nil end

	local Segments: { [number]: string } = string.split(RelativePath, '/');
	local SegmentCount: number = #Segments;

	if (SegmentCount == 0) then return nil end

	local RootServiceName: string = Segments[1];
	local CurrentInstance: Instance? = nil;

	local ServiceSuccess: boolean, ServiceResult: any = pcall(function(): (Instance)
		return game:GetService(RootServiceName);
	end);

	if ServiceSuccess and ServiceResult then
		CurrentInstance = ServiceResult;
	else
		CurrentInstance = game:FindFirstChild(RootServiceName);
	end

	if not CurrentInstance then return nil end

	for Index: number = 2, SegmentCount do
		local ChildName: string = Segments[Index];
		local NextChild: Instance? = CurrentInstance:FindFirstChild(ChildName);

		if not NextChild then return nil end

		CurrentInstance = NextChild;
	end

	return CurrentInstance;
end

local function EnsureInstanceHierarchy(RelativePath: string, ClassName: string): (Instance?)
	if (RelativePath == '') then return nil end

	local Segments: { [number]: string } = string.split(RelativePath, '/');
	local SegmentCount: number = #Segments;

	if (SegmentCount == 0) then return nil end

	local RootServiceName: string = Segments[1];
	local CurrentInstance: Instance? = nil;

	local ServiceSuccess: boolean, ServiceResult: any = pcall(function(): (Instance)
		return game:GetService(RootServiceName);
	end);

	if ServiceSuccess and ServiceResult then
		CurrentInstance = ServiceResult;
	else
		CurrentInstance = game:FindFirstChild(RootServiceName);
	end

	if not CurrentInstance then return nil end

	if (SegmentCount == 1) then
		return CurrentInstance;
	end

	for Index: number = 2, (SegmentCount - 1) do
		local FolderName: string = Segments[Index];
		local NextChild: Instance? = CurrentInstance:FindFirstChild(FolderName);

		if not NextChild then
			local NewFolder: Folder = Instance.new('Folder');

			NewFolder.Name = FolderName;
			NewFolder.Parent = CurrentInstance;

			NextChild = NewFolder;
		end

		CurrentInstance = NextChild;
	end

	local TargetName: string = Segments[SegmentCount];
	local TargetChild: Instance? = CurrentInstance:FindFirstChild(TargetName);

	if TargetChild then
		if (TargetChild.ClassName ~= ClassName) and not IsLockedInstance(TargetChild) then
			local ReplacementInstance: Instance = Instance.new(ClassName);

			ReplacementInstance.Name = TargetName;

			for _: number, ChildOfOld: Instance in TargetChild:GetChildren() do
				ChildOfOld.Parent = ReplacementInstance;
			end

			ReplacementInstance.Parent = CurrentInstance;

			pcall(function(): ()
				TargetChild:Destroy();
			end);

			TargetChild = ReplacementInstance;
		end
	else
		local NewInstance: Instance = Instance.new(ClassName);

		NewInstance.Name = TargetName;
		NewInstance.Parent = CurrentInstance;

		TargetChild = NewInstance;
	end

	return TargetChild;
end

local function SafelyDeleteOrRecycle(TargetObject: Instance, RelativePath: string): (boolean)
	if IsLockedInstance(TargetObject) or IsPluginInternal(TargetObject) or IsRecycleBinInstance(TargetObject) then
		return false;
	end

	local RecycleBin: Instance = GetOrCreateRecycleBin();

	if (TargetObject == RecycleBin) or RecycleBin:IsDescendantOf(TargetObject) or TargetObject:IsDescendantOf(RecycleBin) then
		return false;
	end

	local Recycled: boolean = false;

	local ReparentSuccess: boolean = pcall(function(): ()
		TargetObject.Parent = RecycleBin;
		Recycled = true;
	end);

	if not ReparentSuccess or not Recycled then
		local DestroySuccess: boolean = pcall(function(): ()
			TargetObject:Destroy();
		end);

		if not DestroySuccess then
			return false;
		end
	end

	print(`[Silicon Import] Moved deleted object <{RelativePath}> to Studio Recycle Bin.`);

	return true;
end

local function ApplyIncrementalChange(Event: { [string]: any }): ()
	EnsurePluginCopy();

	local Action: string = Event.action or 'update_properties';
	local RelativePath: string = Event.path or '';

	if (RelativePath == '') then return end

	State.IsApplyingRemoteUpdate = true;

	if (Action == 'delete') then
		local TargetToDelete: Instance? = FindInstanceByRelativePath(RelativePath);

		if TargetToDelete then
			SafelyDeleteOrRecycle(TargetToDelete, RelativePath);
		end

		LastKnownScriptHashes[RelativePath] = nil;

		task.defer(function(): ()
			State.IsApplyingRemoteUpdate = false;
		end);

		return;
	end

	if (Action == 'update_properties') or (Action == 'create') then
		local ClassName: string = Event.className or 'Folder';
		local TargetInstance: Instance? = EnsureInstanceHierarchy(RelativePath, ClassName);

		if TargetInstance then
			ApplyPropertiesToObject(TargetInstance, Event.properties, Event.attributes, Event.tags);

			print(`[Silicon Import] Synchronized properties of <{RelativePath}> ({ClassName}) into Roblox Studio!`);
		end
	end

	if (Action == 'update_source') then
		local TargetInstance: Instance? = FindInstanceByRelativePath(RelativePath);
		local Source: string = Event.source or '';

		if TargetInstance and TargetInstance:IsA('LuaSourceContainer') then
			LastKnownScriptHashes[RelativePath] = Source;

			local SourceUpdated: boolean = false;

			if SES then
				pcall(function(): ()
					SES:UpdateSourceAsync(TargetInstance, function(_: string): (string)
						return Source;
					end);

					SourceUpdated = true;
				end);
			end

			if not SourceUpdated then
				pcall(function(): ()
					(TargetInstance :: any).Source = Source;
				end);
			end

			print(`[Silicon Import] Synchronized script source of <{RelativePath}> into Roblox Studio!`);
		end
	end

	task.defer(function(): ()
		State.IsApplyingRemoteUpdate = false;
	end);

	return;
end

local function Import(IsLIVE: boolean?): ()
	EnsurePluginCopy();

	IsLIVE = (IsLIVE == true);

	local LocalSyncAllDescendants: boolean? = Settings.SyncAllDescendants;
	local RemoteSettings: any = Connect.GetSettings();

	if (type(RemoteSettings) == 'table') and RemoteSettings.ServerPort then
		Settings = RemoteSettings;

		if (LocalSyncAllDescendants ~= nil) then
			Settings.SyncAllDescendants = LocalSyncAllDescendants;
		end

		Host = (Settings.ServerHost or Host);
		Port = (Settings.ServerPort or Port);
		RootFolderName = (Settings.RootFolderName or RootFolderName or 'Silicon');
		PluginFolderName = (Settings.PluginFolderName or PluginFolderName or 'Silicon');
		RecycleBinFolderName = (Settings.RecycleBinFolderName or RecycleBinFolderName or 'Recycle Bin');
	end

	print(`[Silicon Import] Requesting full import from IDE server at {Host}:{Port}...`);

	local Data: any = Connect.GetData(Host, Port);

	if not Data or not Data.files then
		warn(`[Silicon Import] No object data received from IDE server at {Host}:{Port}.`);

		return;
	end

	local ObjectsList: { [number]: { [string]: any } } = Data.files;
	local ObjectCount: number = #ObjectsList;

	table.sort(ObjectsList, function(FirstItem: { [string]: any }, SecondItem: { [string]: any }): (boolean)
		local FirstDepth: number = #(string.split(FirstItem.path, '/'));
		local SecondDepth: number = #(string.split(SecondItem.path, '/'));

		return (FirstDepth < SecondDepth);
	end);

	local ExpectedObjectPaths: { [string]: boolean } = { };

	for _: number, ObjectItem: { [string]: any } in ObjectsList do
		if ObjectItem.path then
			ExpectedObjectPaths[ObjectItem.path] = true;
		end
	end

	print(`[Silicon Import] Reconciling Roblox Studio objects with {ObjectCount} IDE object folder{(ObjectCount ~= 1) and 's' or ''}...`);

	local DeletedCount: number = 0;
	local StudioObjectsToDelete: { [number]: Instance } = { };

	for _: number, ServiceName: string in SyncedServices do
		local ServiceInstance: Instance? = nil;

		local ServiceSuccess: boolean, ServiceResult: any = pcall(function(): (Instance)
			return game:GetService(ServiceName);
		end);

		if ServiceSuccess and ServiceResult then
			ServiceInstance = ServiceResult;
		else
			ServiceInstance = game:FindFirstChild(ServiceName);
		end

		if not ServiceInstance then continue end
		if IsIgnored(ServiceInstance) then continue end

		local ShouldSyncAllDescendants: boolean = (Settings.SyncAllDescendants == true) or (Settings.SyncMode == 'AllDescendants');

		for _: number, DescendantObject: Instance in ServiceInstance:GetDescendants() do
			if IsIgnored(DescendantObject) then continue end
			if IsLockedInstance(DescendantObject) then continue end

			local AncestryNames: { [number]: string } = GetAncestry(DescendantObject);
			local ObjectPath: string = table.concat(AncestryNames, '/');

			if not ExpectedObjectPaths[ObjectPath] then
				if ShouldSyncAllDescendants or DescendantObject:IsA('LuaSourceContainer') then
					table.insert(StudioObjectsToDelete, DescendantObject);
				end
			end
		end
	end

	for _: number, ObjectToDelete: Instance in StudioObjectsToDelete do
		if not ObjectToDelete or not ObjectToDelete.Parent then continue end
		if IsLockedInstance(ObjectToDelete) then continue end

		local AncestryNames: { [number]: string } = GetAncestry(ObjectToDelete);
		local ObjectPath: string = table.concat(AncestryNames, '/');

		local DeletedSuccessfully: boolean = SafelyDeleteOrRecycle(ObjectToDelete, ObjectPath);

		if DeletedSuccessfully then
			DeletedCount += 1;
		end
	end

	print(`[Silicon Import] Processing {ObjectCount} object{(ObjectCount ~= 1) and 's' or ''} from IDE into Roblox Studio...`);

	for Index: number, ObjectItem: { [string]: any } in ObjectsList do
		local RelativePath: string = ObjectItem.path;
		local ClassName: string = ObjectItem.className or 'Folder';
		local TargetInstance: Instance? = EnsureInstanceHierarchy(RelativePath, ClassName);

		if TargetInstance then
			ApplyPropertiesToObject(TargetInstance, ObjectItem.properties, ObjectItem.attributes, ObjectItem.tags);

			if ObjectItem.source and TargetInstance:IsA('LuaSourceContainer') then
				local ScriptSource: string = ObjectItem.source;

				LastKnownScriptHashes[RelativePath] = ScriptSource;

				local SourceUpdated: boolean = false;

				if SES then
					pcall(function(): ()
						SES:UpdateSourceAsync(TargetInstance, function(_: string): (string)
							return ScriptSource;
						end);

						SourceUpdated = true;
					end);
				end

				if not SourceUpdated then
					pcall(function(): ()
						(TargetInstance :: any).Source = ScriptSource;
					end);
				end
			end
		end

		if ((Index % 10) == 0) then
			task.wait();
		end
	end

	EnsurePluginCopy();

	print(`[Silicon Import] Successfully synchronized from IDE! ({ObjectCount} imported, {DeletedCount} deleted)`);

	return;
end



return setmetatable({
	Import                 = Import,
	ApplyIncrementalChange = ApplyIncrementalChange,
}, {
	__call = function(_: any, IsLIVE: boolean?): ()
		Import(IsLIVE);
	end,
});
