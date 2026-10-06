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
local RecycleBinParentName: string = (Settings.RecycleBinParent or 'ReplicatedStorage/Silicon');
local RecycleBinName: string = (Settings.RecycleBinName or 'Recycle Bin');
local IgnoredAncestors: { [number]: string } = (Settings.IgnoredAncestors or { });



local Variables: { [string]: any } = (Dependencies.Variables);
local IrreplicableClasses: { [number]: string } = (Variables.IrreplicableClasses);
local State: { IsApplyingRemoteUpdate: boolean } = (Variables.State);
local LastKnownScriptHashes: { [string]: string } = (Variables.LastKnownScriptHashes);
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

	local SiliconFolder: Instance? = ReplicatedStorageInstance:FindFirstChild('Silicon');

	if SiliconFolder then
		local PluginFolder: Instance? = SiliconFolder:FindFirstChild('Plugin');

		if PluginFolder and ((Object == PluginFolder) or Object:IsDescendantOf(PluginFolder)) then
			return true;
		end
	end

	local DirectPluginFolder: Instance? = ReplicatedStorageInstance:FindFirstChild('Plugin');

	if DirectPluginFolder and ((Object == DirectPluginFolder) or Object:IsDescendantOf(DirectPluginFolder)) then
		return true;
	end

	return false;
end



local function IsRecycleBinInstance(Object: Instance?): (boolean)
	if not Object then return false end

	local TargetParentName: string = (Settings.RecycleBinParent or RecycleBinParentName or 'ReplicatedStorage/Silicon');
	local TargetBinName: string = (Settings.RecycleBinName or RecycleBinName or 'Recycle Bin');

	local ParentInstance: Instance? = ResolveHierarchyPath(TargetParentName, false);

	if ParentInstance then
		local ConfiguredBin: Instance? = ParentInstance:FindFirstChild(TargetBinName);

		if ConfiguredBin and ((Object == ConfiguredBin) or Object:IsDescendantOf(ConfiguredBin)) then
			return true;
		end
	end

	local ServiceSuccess: boolean, ServiceResult: any = pcall(function(): (Instance)
		return game:GetService('ReplicatedStorage');
	end);

	local ReplicatedStorageInstance: Instance? = ServiceSuccess and ServiceResult or game:FindFirstChild('ReplicatedStorage');

	if ReplicatedStorageInstance then
		local SiliconFolder: Instance? = ReplicatedStorageInstance:FindFirstChild('Silicon');

		if SiliconFolder then
			local SiliconBin: Instance? = SiliconFolder:FindFirstChild('Recycle Bin');

			if SiliconBin and ((Object == SiliconBin) or Object:IsDescendantOf(SiliconBin)) then
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

	if (Object.Name == 'Silicon') and (Object.Parent and (Object.Parent.Name == 'ReplicatedStorage')) then
		return true;
	end

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
	local TargetParentName: string = (Settings.RecycleBinParent or RecycleBinParentName or 'ReplicatedStorage/Silicon');
	local TargetBinName: string = (Settings.RecycleBinName or RecycleBinName or 'Recycle Bin');

	local ParentInstance: Instance? = ResolveHierarchyPath(TargetParentName, true);

	if not ParentInstance then
		local RepStorageSuccess: boolean, RepStorage: any = pcall(function(): (Instance)
			return game:GetService('ReplicatedStorage');
		end);

		ParentInstance = RepStorageSuccess and RepStorage or game:FindFirstChild('ReplicatedStorage');
	end

	local Bin: Instance? = (ParentInstance :: Instance):FindFirstChild(TargetBinName);

	if not Bin then
		local NewBin: Folder = Instance.new('Folder');

		NewBin.Name = TargetBinName;
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

local function DecodePropertyValue(Value: any, PropertyName: string?): (any)
	if (Value == nil) then return nil end

	local DecodedAttempt: boolean, DecodedResult: any = pcall(function(): (any)
		return APIService:JSONDecodeValue(Value);
	end);

	if DecodedAttempt and (DecodedResult ~= nil) then
		return DecodedResult;
	end

	if (type(Value) == 'table') then
		if (#Value == 3) and (type(Value[1]) == 'number') and (type(Value[2]) == 'number') and (type(Value[3]) == 'number') then
			if PropertyName and (string.find(PropertyName, 'Color') ~= nil) then
				if (Value[1] > 1) or (Value[2] > 1) or (Value[3] > 1) then
					return Color3.fromRGB(Value[1], Value[2], Value[3]);
				else
					return Color3.new(Value[1], Value[2], Value[3]);
				end
			else
				return Vector3.new(Value[1], Value[2], Value[3]);
			end
		end

		if (#Value == 12) then
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

		if Value.X and Value.Y and Value.Z and (type(Value.X) == 'number') and (type(Value.Y) == 'number') and (type(Value.Z) == 'number') then
			return Vector3.new(Value.X, Value.Y, Value.Z);
		end

		if Value.R and Value.G and Value.B and (type(Value.R) == 'number') and (type(Value.G) == 'number') and (type(Value.B) == 'number') then
			return Color3.new(Value.R, Value.G, Value.B);
		end
	end

	if (type(Value) == 'string') and PropertyName then
		local EnumLookupSuccess: boolean, FoundEnumItem: any = pcall(function(): (any)
			local TargetEnumType: any = (Enum :: any)[PropertyName];

			if TargetEnumType and TargetEnumType[Value] then
				return TargetEnumType[Value];
			end

			return nil;
		end);

		if EnumLookupSuccess and (FoundEnumItem ~= nil) then
			return FoundEnumItem;
		end
	end

	return Value;
end

local function ApplyPropertiesToObject(Object: Instance, Properties: { [string]: any }?, Attributes: { [string]: any }?, Tags: { [number]: string }?): ()
	if Properties then
		for PropertyName: string, RawValue: any in Properties do
			if (PropertyName == 'Name') or (PropertyName == 'Parent') or (PropertyName == 'Source') or (PropertyName == 'BrickColor') then
				continue;
			end

			local DecodedValue: any = DecodePropertyValue(RawValue, PropertyName);

			if (DecodedValue ~= nil) then
				pcall(function(): ()
					(Object :: any)[PropertyName] = DecodedValue;
				end);
			end
		end
	end

	if Attributes then
		for AttributeKey: string, RawAttrValue: any in Attributes do
			local DecodedAttr: any = DecodePropertyValue(RawAttrValue, nil);

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
		RecycleBinParentName = (Settings.RecycleBinParent or RecycleBinParentName or 'ReplicatedStorage/Silicon');
		RecycleBinName = (Settings.RecycleBinName or RecycleBinName or 'Recycle Bin');
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
