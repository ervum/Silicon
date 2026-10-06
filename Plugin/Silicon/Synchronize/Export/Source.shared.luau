--!strict

local table: typeof(table) = table.clone(table);



local Root: Script = script:FindFirstAncestorOfClass('Script');

local T = require(Root.Shared.Types);
local Dependencies = require(Root.Create.GetDependencies);



local Services: { [string]: any } = (Dependencies.Services);
local HTTP: HttpService = (Services.HTTP);



local Settings: { [string]: any } = (Dependencies.Settings);

local PN: string, AN: string, TN: string, SN: string, DN: string, UN: string, SPN: string = (Settings.PropertiesName), (Settings.AttributesName), (Settings.TagsName), (Settings.SourceName), (Settings.DuplicatedAttributeName), (Settings.UnnamedTableName), (Settings.StringifiedPropertyName);
local ExportPropertyBlacklist: { [number]: string }, ExportDuplicated: boolean = (Settings.ExportFromRSPropertyBlacklist), (Settings.ExportFromRSDuplicated);
local Host: string = (Settings.ServerHost or 'localhost');
local Port: number = (Settings.ServerPort or 6969);
local RootFolderName: string = (Settings.RootFolderName or 'Silicon');
local PluginFolderName: string = (Settings.PluginFolderName or 'Silicon');
local RecycleBinFolderName: string = (Settings.RecycleBinFolderName or 'Recycle Bin');
local ChunkSize: number = (Settings.ExportFromRSDataChunkSize);
local IgnoredAncestors: { [number]: string } = (Settings.IgnoredAncestors);
local NameBlacklist: { [number]: string } = (Settings.ExportFromRSNameBlacklist.Windows);



local Variables: { [string]: any } = (Dependencies.Variables);

local EmptyPropertiesTable: (T.PropertiesObject) = (Variables.EmptyPropertiesTable);
local JSONReturnablePropertyTypes: { [number]: string } = (Variables.JSONReturnablePropertyTypes);
local GetAncestry: ((Instance) -> ({ [number]: string })) = (Variables.GetAncestry);
local State: { IsApplyingRemoteUpdate: boolean } = (Variables.State);
local LastKnownScriptHashes: { [string]: string } = (Variables.LastKnownScriptHashes);
local EnsurePluginCopy: (() -> (Instance?)) = (Variables.EnsurePluginCopy);



local Pad: ((number, number?) -> (string)) = (Dependencies.Pad);
local Connect: { [string]: (( ... any) -> ( ... any)) } = (Dependencies.Connect);
local APIService: { [string]: (( ... any) -> ( ... any)) } = require(Dependencies.__APIService__);



table = (Dependencies.Table);



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

local function IsScript(Object: Instance): (boolean)
	return Object:IsA('LocalScript') or Object:IsA('ModuleScript') or Object:IsA('Script');
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

	local LegacyRootPlugin: Instance? = ReplicatedStorageInstance:FindFirstChild('Plugin');

	if LegacyRootPlugin and ((Object == LegacyRootPlugin) or Object:IsDescendantOf(LegacyRootPlugin)) then
		return true;
	end

	return false;
end

local function IsIgnored(Object: Instance): (boolean)
	if IsPluginInternal(Object) then return true end

	if Object:FindFirstAncestorOfClass('CoreGui') then return true end

	if not Object:IsDescendantOf(game) and (Object ~= game) then return true end

	if Object:IsA('Terrain') then return true end

	for _: number, IgnoredName: string in IgnoredAncestors do
		if (Object.Name == IgnoredName) or Object:FindFirstAncestor(IgnoredName) then
			return true;
		end
	end

	return false;
end

local function SanitizeName(RawName: string): (string, boolean)
	local SanitizedName: string = RawName;
	local WasSanitized: boolean = false;

	for _: number, ForbiddenChar: string in NameBlacklist do
		if string.find(SanitizedName, ForbiddenChar, 1, true) then
			SanitizedName = string.gsub(SanitizedName, ForbiddenChar, '_');

			WasSanitized = true;
		end
	end

	return SanitizedName, WasSanitized;
end

local function BuildRelativePath(Object: Instance): (string, string?, string)
	local AncestryNames: { [number]: string } = GetAncestry(Object);
	local Segments: { [number]: string } = { };
	local OriginalName: string? = nil;

	local TotalSegments: number = #AncestryNames;

	for Index: number, SegmentName: string in AncestryNames do
		local SanitizedSegment: string, WasSanitized: boolean = SanitizeName(SegmentName);

		if (Index == TotalSegments) and WasSanitized then
			OriginalName = SegmentName;
		end

		table.insert(Segments, SanitizedSegment);
	end

	return table.concat(Segments, '/'), OriginalName, AncestryNames[TotalSegments];
end

local function SerializeObject(Object: Instance): ({ [string]: any })
	local RelativePath: string, OriginalName: string?, BaseName: string = BuildRelativePath(Object);
	local ClassName: string = (Object.ClassName);

	local RawProperties: { [string]: any } = APIService:GetProperties(Object, true) or { };
	local SerializedProperties: { [string]: any } = { };

	for PropertyName: string, PropertyValue: any in RawProperties do
		if (PropertyName == 'Name') or (PropertyName == 'Parent') or (PropertyName == 'BrickColor') or (PropertyName == 'Source') then
			continue;
		end

		if (table.find(ExportPropertyBlacklist, PropertyName) ~= nil) then
			continue;
		end

		local EncodedValue: any = APIService:JSONEncodeValue(PropertyValue);

		if (EncodedValue ~= nil) then
			SerializedProperties[PropertyName] = EncodedValue;
		end
	end

	local SerializedAttributes: { [string]: any } = { };

	for AttributeKey: string, AttributeValue: any in Object:GetAttributes() do
		local EncodedAttribute: any = APIService:JSONEncodeValue(AttributeValue);

		if (EncodedAttribute ~= nil) then
			SerializedAttributes[AttributeKey] = EncodedAttribute;
		end
	end

	local SerializedTags: { [number]: string } = Object:GetTags();

	local ScriptSource: string? = nil;
	local ScriptType: string? = nil;

	if Object:IsA('LuaSourceContainer') then
		ScriptSource = (Object :: any).Source or '';

		if Object:IsA('LocalScript') then
			ScriptType = 'client';
		elseif Object:IsA('Script') then
			local RunContextSuccess: boolean, RunContextVal: any = pcall(function(): (any)
				return (Object :: any).RunContext;
			end);

			if RunContextSuccess and (RunContextVal == (Enum.RunContext.Client)) then
				ScriptType = 'client';
			else
				ScriptType = 'server';
			end
		else
			ScriptType = 'shared';
		end
	end

	return {
		path         = RelativePath,
		className    = ClassName,
		originalName = OriginalName,
		properties   = SerializedProperties,
		attributes   = SerializedAttributes,
		tags         = SerializedTags,
		source       = ScriptSource,
		scriptType   = ScriptType,
	};
end

local function ExportSingleObject(Object: Instance, IsDeleted: boolean?): ()
	EnsurePluginCopy();

	if (State.IsApplyingRemoteUpdate == true) then return end

	if IsIgnored(Object) then return end

	local RelativePath: string, OriginalName: string?, BaseName: string = BuildRelativePath(Object);

	local ShouldSyncAllDescendants: boolean = (Settings.SyncAllDescendants == true) or (Settings.SyncMode == 'AllDescendants');

	if not ShouldSyncAllDescendants and not IsDeleted then
		local IsInRecycleBin: boolean = false;
		local ConfiguredRootFolderName: string = (Settings.RootFolderName or RootFolderName or 'Silicon');
		local ConfiguredBinFolderName: string = (Settings.RecycleBinFolderName or RecycleBinFolderName or 'Recycle Bin');
		local RepStorage: Instance? = game:FindFirstChild('ReplicatedStorage');

		if RepStorage then
			local RootFolder: Instance? = RepStorage:FindFirstChild(ConfiguredRootFolderName);

			if RootFolder then
				local RecycleBin: Instance? = RootFolder:FindFirstChild(ConfiguredBinFolderName);

				if RecycleBin and ((Object == RecycleBin) or Object:IsDescendantOf(RecycleBin)) then
					IsInRecycleBin = true;
				end
			end
		end

		local HasScript: boolean = IsScript(Object) or (Object:FindFirstChildWhichIsA('LuaSourceContainer', true) ~= nil);

		if not HasScript and not IsInRecycleBin then
			return;
		end
	end

	local TargetHost: string = Host or (Settings.ServerHost) or 'localhost';
	local TargetPort: number = Port or (Settings.ServerPort) or 6969;
	local TargetURL: string = `http://{TargetHost}:{TargetPort}/sync`;

	if IsDeleted then
		local Payload: string = HTTP:JSONEncode({
			action = 'delete',
			path   = RelativePath,
		});

		pcall(function(): ()
			HTTP:PostAsync(TargetURL, Payload, (Enum.HttpContentType.ApplicationJson));
		end);

		LastKnownScriptHashes[RelativePath] = nil;

		print(`[Silicon Export] Synchronized deletion of <{BaseName}> to local disk.`);

		return;
	end

	local ObjectData: { [string]: any } = SerializeObject(Object);

	if ObjectData.source then
		LastKnownScriptHashes[RelativePath] = (ObjectData.source :: string);
	end

	local Payload: string = HTTP:JSONEncode({
		path       = (ObjectData.path),
		action     = 'update',
		className  = (ObjectData.className),
		properties = (ObjectData.properties),
		attributes = (ObjectData.attributes),
		tags       = (ObjectData.tags),
		source     = (ObjectData.source),
		scriptType = (ObjectData.scriptType),
		objects    = { ObjectData },
		scripts    = { ObjectData },
	});

	pcall(function(): ()
		HTTP:PostAsync(TargetURL, Payload, (Enum.HttpContentType.ApplicationJson));
	end);

	print(`[Silicon Export] Synchronized <{BaseName}> ({ObjectData.className}) to local disk.`);

	return;
end



return function(ObjectToSynchronize: Instance?, IsLIVE: boolean?): ()
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
		ChunkSize = (Settings.ExportFromRSDataChunkSize or ChunkSize);
		IgnoredAncestors = (Settings.IgnoredAncestors or IgnoredAncestors);
	end

	if ObjectToSynchronize then
		ExportSingleObject(ObjectToSynchronize);

		return;
	end

	local ShouldSyncAllDescendants: boolean = (Settings.SyncAllDescendants == true) or (Settings.SyncMode == 'AllDescendants');

	print(`[Silicon Export] Scanning place hierarchy ({ShouldSyncAllDescendants and 'All Descendants' or 'Script Ancestry Only'}) to export to IDE...`);

	local ScriptAncestors: { [Instance]: boolean } = { };

	if not ShouldSyncAllDescendants then
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

			if not ServiceInstance or IsIgnored(ServiceInstance) then continue end

			for _: number, DescendantObject: Instance in ServiceInstance:GetDescendants() do
				if IsIgnored(DescendantObject) then continue end

				if IsScript(DescendantObject) then
					local CurrentAncestor: Instance? = DescendantObject;

					while CurrentAncestor and (CurrentAncestor ~= game) do
						if IsIgnored(CurrentAncestor) then break end

						ScriptAncestors[CurrentAncestor] = true;
						CurrentAncestor = (CurrentAncestor.Parent);
					end
				end
			end
		---> Always preserve and export the in-Studio Recycle Bin and all its contents
		local ServiceSuccess: boolean, ServiceResult: any = pcall(function(): (Instance)
			return game:GetService('ReplicatedStorage');
		end);

		local ReplicatedStorageInstance: Instance? = ServiceSuccess and ServiceResult or game:FindFirstChild('ReplicatedStorage');

		if ReplicatedStorageInstance and not IsIgnored(ReplicatedStorageInstance) then
			local ConfiguredRootFolderName: string = (Settings.RootFolderName or RootFolderName or 'Silicon');
			local ConfiguredBinFolderName: string = (Settings.RecycleBinFolderName or RecycleBinFolderName or 'Recycle Bin');

			local RootFolder: Instance? = ReplicatedStorageInstance:FindFirstChild(ConfiguredRootFolderName);

			if RootFolder and not IsIgnored(RootFolder) then
				local RecycleBin: Instance? = RootFolder:FindFirstChild(ConfiguredBinFolderName);

				if RecycleBin and not IsIgnored(RecycleBin) then
					ScriptAncestors[ReplicatedStorageInstance] = true;
					ScriptAncestors[RootFolder] = true;
					ScriptAncestors[RecycleBin] = true;

					for _: number, BinDescendant: Instance in RecycleBin:GetDescendants() do
						if not IsIgnored(BinDescendant) then
							ScriptAncestors[BinDescendant] = true;
						end
					end
				end
			end
		end
	end

	local ObjectsToExport: { [number]: { [string]: any } } = { };
	local ObjectCount: number = 0;

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

		if ShouldSyncAllDescendants or ScriptAncestors[ServiceInstance] then
			local ServiceData: { [string]: any } = SerializeObject(ServiceInstance);
			ObjectCount += 1;
			table.insert(ObjectsToExport, ServiceData);
		end

		for _: number, DescendantObject: Instance in ServiceInstance:GetDescendants() do
			if IsIgnored(DescendantObject) then continue end

			if ShouldSyncAllDescendants or ScriptAncestors[DescendantObject] then
				local ObjectData: { [string]: any } = SerializeObject(DescendantObject);

				if ObjectData.source then
					LastKnownScriptHashes[ObjectData.path] = (ObjectData.source :: string);
				end

				ObjectCount += 1;
				table.insert(ObjectsToExport, ObjectData);
			end
		end
	end

	print(`[Silicon Export] Exporting {ObjectCount} object{(ObjectCount ~= 1) and 's' or ''} from Roblox Studio to IDE...`);

	local TargetHost: string = Host or (Settings.ServerHost) or 'localhost';
	local TargetPort: number = Port or (Settings.ServerPort) or 6969;
	local TargetURL: string = `http://{TargetHost}:{TargetPort}/sync`;

	if (ObjectCount == 0) then
		local EmptyPayload: string = HTTP:JSONEncode({
			path      = 'empty_sync',
			objects   = { },
			scripts   = { },
			full_sync = true,
		});

		pcall(function(): ()
			HTTP:PostAsync(TargetURL, EmptyPayload, (Enum.HttpContentType.ApplicationJson));
		end);

		print('[Silicon Export] Exported 0 objects to IDE (place has no synced objects).');

		return;
	end

	local MaxBatchBytes: number = 300000;
	local AllExportedPaths: { [number]: string } = { };
	local CurrentBatch: { [number]: { [string]: any } } = { };
	local CurrentBatchSize: number = 0;
	local ExportedTotal: number = 0;

	for _: number, ObjectData: { [string]: any } in ObjectsToExport do
		table.insert(AllExportedPaths, ObjectData.path);

		local ItemJSON: string = HTTP:JSONEncode(ObjectData);
		local ItemLength: number = #ItemJSON;

		if (ItemLength > MaxBatchBytes) and ObjectData.source then
			if (#CurrentBatch > 0) then
				local BatchPayload: string = HTTP:JSONEncode({
					path    = 'batch',
					action  = 'batch',
					objects = CurrentBatch,
					scripts = CurrentBatch,
				});

				local BatchSuccess: boolean, BatchResponse: string? = pcall(function(): (string)
					return HTTP:PostAsync(TargetURL, BatchPayload, (Enum.HttpContentType.ApplicationJson));
				end);

				if BatchSuccess then
					ExportedTotal += #CurrentBatch;
					print(`[Silicon Export] Exported batch ({ExportedTotal}/{ObjectCount}) objects to IDE.`);
				else
					warn(`[Silicon Export] Failed exporting batch to IDE: {BatchResponse}`);
				end

				CurrentBatch = { };
				CurrentBatchSize = 0;
				task.wait();
			end

			local FullSource: string = (ObjectData.source :: string);
			local SourceLength: number = #FullSource;
			local TotalChunks: number = math.ceil(SourceLength / MaxBatchBytes);

			for ChunkIndex: number = 1, TotalChunks do
				local StartIndex: number = (((ChunkIndex - 1) * MaxBatchBytes) + 1);
				local EndIndex: number = math.min((ChunkIndex * MaxBatchBytes), SourceLength);
				local ChunkSlice: string = string.sub(FullSource, StartIndex, EndIndex);

				local ChunkPayload: { [string]: any } = {
					action       = 'chunk',
					path         = (ObjectData.path),
					chunk_index  = ChunkIndex,
					total_chunks = TotalChunks,
					chunk_source = ChunkSlice,
					className    = (ObjectData.className),
					originalName = (ObjectData.originalName),
					properties   = (ObjectData.properties),
					attributes   = (ObjectData.attributes),
					tags         = (ObjectData.tags),
					scriptType   = (ObjectData.scriptType),
				};

				local ChunkSuccess: boolean, ChunkResponse: string? = pcall(function(): (string)
					return HTTP:PostAsync(TargetURL, HTTP:JSONEncode(ChunkPayload), (Enum.HttpContentType.ApplicationJson));
				end);

				if not ChunkSuccess then
					warn(`[Silicon Export] Failed exporting chunk {ChunkIndex}/{TotalChunks} of <{ObjectData.path}>: {ChunkResponse}`);
				end

				task.wait();
			end

			ExportedTotal += 1;
			print(`[Silicon Export] Exported large object ({ExportedTotal}/{ObjectCount}) <{ObjectData.path}> in {TotalChunks} chunks to IDE.`);
		else
			if (((CurrentBatchSize + ItemLength) > MaxBatchBytes) and (#CurrentBatch > 0)) then
				local BatchPayload: string = HTTP:JSONEncode({
					path    = 'batch',
					action  = 'batch',
					objects = CurrentBatch,
					scripts = CurrentBatch,
				});

				local BatchSuccess: boolean, BatchResponse: string? = pcall(function(): (string)
					return HTTP:PostAsync(TargetURL, BatchPayload, (Enum.HttpContentType.ApplicationJson));
				end);

				if BatchSuccess then
					ExportedTotal += #CurrentBatch;
					print(`[Silicon Export] Exported batch ({ExportedTotal}/{ObjectCount}) objects to IDE.`);
				else
					warn(`[Silicon Export] Failed exporting batch to IDE: {BatchResponse}`);
				end

				CurrentBatch = { };
				CurrentBatchSize = 0;
				task.wait();
			end

			table.insert(CurrentBatch, ObjectData);
			CurrentBatchSize += ItemLength;
		end
	end

	if (#CurrentBatch > 0) then
		local FinalBatchPayload: string = HTTP:JSONEncode({
			path    = 'batch',
			action  = 'batch',
			objects = CurrentBatch,
			scripts = CurrentBatch,
		});

		local FinalBatchSuccess: boolean, FinalBatchResponse: string? = pcall(function(): (string)
			return HTTP:PostAsync(TargetURL, FinalBatchPayload, (Enum.HttpContentType.ApplicationJson));
		end);

		if FinalBatchSuccess then
			ExportedTotal += #CurrentBatch;
			print(`[Silicon Export] Exported batch ({ExportedTotal}/{ObjectCount}) objects to IDE.`);
		else
			warn(`[Silicon Export] Failed exporting batch to IDE: {FinalBatchResponse}`);
		end
	end

	local FinalizePayload: string = HTTP:JSONEncode({
		path           = 'finalize_sync',
		action         = 'finalize_sync',
		received_paths = AllExportedPaths,
	});

	pcall(function(): ()
		HTTP:PostAsync(TargetURL, FinalizePayload, (Enum.HttpContentType.ApplicationJson));
	end);

	print(`[Silicon Export] Successfully exported {ExportedTotal} object{(ExportedTotal ~= 1) and 's' or ''} to IDE!`);

	return;
end :: ((Instance?, boolean?) -> ());
