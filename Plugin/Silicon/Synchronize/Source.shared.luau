--!strict

local os: typeof(os) = os; 

local Clock: typeof(os.clock) = (os.clock);



local Synchronize: { [string]: (() -> ( ... any)) } = { };



local Root: Script = script:FindFirstAncestorOfClass('Script');

local T = require(Root.Shared.Types);
local Dependencies = require(Root.Create.GetDependencies);



local Services: { [string]: any } = (Dependencies.Services);
local HTTP: HttpService, SES: ScriptEditorService = (Services.HTTP), (Services.SES);



local Export: ((Instance?, boolean?) -> ()) = require(Dependencies.__Export__);
local ImportModule: any = (Dependencies.Import);
local ApplyIncrementalChange: (({ [string]: any }) -> ()) = (ImportModule.ApplyIncrementalChange);
local Connect: { [string]: (( ... any) -> ( ... any)) } = (Dependencies.Connect);
local Variables: { [string]: any } = (Dependencies.Variables);
local EnsurePluginCopy: (() -> (Instance?)) = (Variables.EnsurePluginCopy);
local GetAncestry: ((Instance) -> ({ [number]: string })) = (Variables.GetAncestry);
local LastKnownScriptHashes: { [string]: string } = (Variables.LastKnownScriptHashes);
local RootFolderName: string = (Variables.RootFolderName or 'Silicon');
local PluginFolderName: string = (Variables.PluginFolderName or 'Plugin');



local Settings: { [string]: any } = (Dependencies.Settings);

local ExportDebounceTime: number = (Settings.SynchronizationRSDebounceTime or 0.1);
local LongPollTimeout: number = (Settings.LongPollTimeout or 5.0);
local Host: string = (Settings.ServerHost or 'localhost');
local Port: number = (Settings.ServerPort or 6969);
local IgnoredAncestors: { [number]: string } = (Settings.IgnoredAncestors or { });



local SynchronizedServices: { [number]: string } = {
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
	PlayerGui                 = true,
	PlayerScripts             = true,
	Player                    = true,
	CoreGui                   = true,
	Backpack                  = true,
	PlayerMouse               = true,
	StarterGear               = true,
};

local function IsPluginInternal(Object: Instance?): (boolean)
	if not Object then return false end
	if (Object == Root) or Object:IsDescendantOf(Root) then return true end

	if (Object.Name == 'APIService') or (Object.Name == 'API') or Object:FindFirstAncestor('APIService') or Object:FindFirstAncestor('API') then
		return true;
	end

	local SiliconAncestor: Instance? = Object:FindFirstAncestor('Silicon');

	if SiliconAncestor and (SiliconAncestor:FindFirstChild('Synchronize') or SiliconAncestor:FindFirstChild('Create') or SiliconAncestor:FindFirstChild('Shared')) then
		return true;
	end

	if (Object.Name == 'Silicon') and (Object:FindFirstChild('Synchronize') or Object:FindFirstChild('Create') or Object:FindFirstChild('Shared')) then
		return true;
	end

	local ServiceSuccess: boolean, ServiceResult: any = pcall(function(): (Instance)
		return game:GetService('ReplicatedStorage');
	end);

	local ReplicatedStorageInstance: Instance? = ServiceSuccess and ServiceResult or game:FindFirstChild('ReplicatedStorage');

	if not ReplicatedStorageInstance then return false end

	local ConfiguredRootFolderName: string = (Settings.RootFolderName or RootFolderName or 'Silicon');
	local ConfiguredPluginFolderName: string = (Settings.PluginFolderName or PluginFolderName or 'Plugin');

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

		local SiliconPlugin: Instance? = ConfiguredRoot:FindFirstChild('Silicon');

		if SiliconPlugin and ((Object == SiliconPlugin) or Object:IsDescendantOf(SiliconPlugin)) then
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

local function IsLockedInstance(Object: Instance?): (boolean)
	if not Object or (Object == game) or (Object.Parent == game) or (Object.Parent == nil) then
		return true;
	end

	if Object:IsA('Terrain') or Object:IsA('Camera') or Object:IsA('Player') or Object:IsA('PlayerGui') or Object:IsA('PlayerScripts') or Object:IsA('Backpack') then
		return true;
	end

	if Object:FindFirstAncestorOfClass('Player') or Object:FindFirstAncestorOfClass('CoreGui') then
		return true;
	end

	local ClassName: string = (Object.ClassName);

	if LockedClasses[ClassName] then
		return true;
	end

	return false;
end

local function IsIgnored(Object: Instance): (boolean)
	if IsPluginInternal(Object) then return true end
	if IsLockedInstance(Object) then return true end

	if Object:FindFirstAncestorOfClass('CoreGui') then return true end
	if Object:FindFirstAncestorOfClass('Player') then return true end

	if not Object:IsDescendantOf(game) and (Object ~= game) then return true end

	if Object:IsA('Terrain') or Object:IsA('Camera') then return true end

	local IgnoredList: { [number]: string } = (Settings.IgnoredAncestors or IgnoredAncestors or { });

	for _: number, IgnoredName: string in IgnoredList do
		if (Object.Name == IgnoredName) or Object:FindFirstAncestor(IgnoredName) then
			return true;
		end
	end

	return false;
end



local LastTypingTime: number = os.clock();
local IsTyping: boolean = false;



local function SynchronizeExport(): (RBXScriptConnection)
	return SES.TextDocumentDidChange:Connect(function(ChangedScript: ScriptDocument, _: { [number]: { [string]: any } }): ()
		IsTyping = true;
		LastTypingTime = Clock();

		task.delay(ExportDebounceTime, function(): ()
			if ((Clock() - LastTypingTime) >= ExportDebounceTime) then
				if IsTyping then
					local TargetScript: LuaSourceContainer? = ChangedScript:GetScript();

					if TargetScript then
						EnsurePluginCopy();

						Export(TargetScript, true);
					end

					IsTyping = false;
				end
			end
		end);
	end);
end

local function SynchronizeImport(): (RBXScriptConnection)
	local LifecycleSignaler: BindableEvent = Instance.new('BindableEvent');
	local Connection: RBXScriptConnection = LifecycleSignaler.Event:Connect(function(): () end);

	task.spawn(function(): ()
		local TargetHost: string = (Settings.ServerHost or Host or 'localhost');
		local TargetPort: number = (Settings.ServerPort or Port or 6969);

		local LastEventId: number = 0;

		local InitURL: string = `http://{TargetHost}:{TargetPort}/changes?since=999999999&timeout=0`;

		local InitSuccess: boolean, InitBody: string? = pcall(function(): (string)
			return HTTP:GetAsync(InitURL, true);
		end);

		if InitSuccess and InitBody and (InitBody ~= '') then
			local InitDecodeSuccess: boolean, DecodedInit: any = pcall(function(): (any)
				return HTTP:JSONDecode(InitBody);
			end);

			if InitDecodeSuccess and DecodedInit and DecodedInit.latestId then
				LastEventId = (DecodedInit.latestId);
			end
		end

		while (Connection.Connected == true) do
			local RequestURL: string = `http://{TargetHost}:{TargetPort}/changes?since={LastEventId}&timeout={LongPollTimeout}`;

			local Success: boolean, ResponseBody: string? = pcall(function(): (string)
				return HTTP:GetAsync(RequestURL, true);
			end);

			if not (Connection.Connected) then break end

			if Success and (ResponseBody ~= nil) and (ResponseBody ~= '') then
				local DecodeSuccess: boolean, DecodedPayload: any = pcall(function(): (any)
					return HTTP:JSONDecode(ResponseBody);
				end);

				if DecodeSuccess and DecodedPayload and DecodedPayload.events then
					for _: number, ChangeEvent: { [string]: any } in DecodedPayload.events do
						if not (Connection.Connected) then break end

						EnsurePluginCopy();

						ApplyIncrementalChange(ChangeEvent);

						if ChangeEvent.id and (ChangeEvent.id > LastEventId) then
							LastEventId = (ChangeEvent.id);
						end
					end

					if DecodedPayload.latestId and (DecodedPayload.latestId > LastEventId) then
						LastEventId = (DecodedPayload.latestId);
					end
				end
			else
				task.wait(0.5);
			end
		end

		LifecycleSignaler:Destroy();
	end);

	return Connection;
end



local function NormalizeSourceText(SourceText: string?): (string)
	if not SourceText then return '' end

	local CleanedText: string = string.gsub(SourceText, '\r\n', '\n');
	CleanedText = string.gsub(CleanedText, '\r', '\n');

	return (string.gsub(CleanedText, '%s+$', ''));
end



local function PerformBidirectionalMerge(): ()
	EnsurePluginCopy();

	local TargetHost: string = (Settings.ServerHost or Host or 'localhost');
	local TargetPort: number = (Settings.ServerPort or Port or 6969);

	if not Connect.IsHTTPServerRunning(TargetHost, TargetPort) then
		warn(`[Silicon Merge] Server at {TargetHost}:{TargetPort} is not reachable. Skipping merge.`);

		return;
	end

	print(`[Silicon Merge] Fetching IDE objects from {TargetHost}:{TargetPort}...`);

	local Data: any = Connect.GetData(TargetHost, TargetPort);

	if not Data or not Data.files then
		print('[Silicon Merge] No IDE files found. Exporting current Roblox Studio place to IDE...');

		Export(nil, false);

		return;
	end

	local IDEObjectsList: { [number]: { [string]: any } } = Data.files;
	local IDEObjectsByPath: { [string]: { [string]: any } } = { };

	for _: number, IDEObject: { [string]: any } in IDEObjectsList do
		if IDEObject.path and (IDEObject.path ~= '') then
			IDEObjectsByPath[IDEObject.path] = IDEObject;
		end
	end

	local ShouldSynchronizeAllDescendants: boolean = (Settings.SynchronizeAllDescendants == true) or (Settings.SyncAllDescendants == true) or (Settings.SynchronizationMode == 'AllDescendants') or (Settings.SyncMode == 'AllDescendants');

	local StudioInstancesByPath: { [string]: Instance } = { };
	local AllPathsSet: { [string]: boolean } = { };

	for _: number, ServiceName: string in SynchronizedServices do
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
			if IsIgnored(DescendantObject) or IsLockedInstance(DescendantObject) then continue end

			local AncestryNames: { [number]: string } = GetAncestry(DescendantObject);
			local RelativePath: string = table.concat(AncestryNames, '/');

			if ShouldSynchronizeAllDescendants or DescendantObject:IsA('LuaSourceContainer') or (IDEObjectsByPath[RelativePath] ~= nil) then
				StudioInstancesByPath[RelativePath] = DescendantObject;
				AllPathsSet[RelativePath] = true;
			end
		end
	end

	for IDEPath: string in IDEObjectsByPath do
		AllPathsSet[IDEPath] = true;
	end

	local function HasDescendantInSet(BasePath: string): (boolean)
		local Prefix: string = `{BasePath}/`;

		for OtherPath: string in AllPathsSet do
			if (string.sub(OtherPath, 1, #Prefix) == Prefix) then
				return true;
			end
		end

		return false;
	end

	local SortedPaths: { [number]: string } = { };

	for PathKey: string in AllPathsSet do
		table.insert(SortedPaths, PathKey);
	end

	table.sort(SortedPaths, function(FirstPath: string, SecondPath: string): (boolean)
		local FirstDepth: number = #(string.split(FirstPath, '/'));
		local SecondDepth: number = #(string.split(SecondPath, '/'));

		return (FirstDepth > SecondDepth);
	end);

	local RenamedCount: number = 0;
	local ImportedCount: number = 0;
	local ConflictCount: number = 0;
	local MatchedCount: number = 0;

	for _: number, RelativePath: string in SortedPaths do
		local Segments: { [number]: string } = string.split(RelativePath, '/');
		local SegmentCount: number = #Segments;

		if (SegmentCount <= 1) then continue end

		local LeafName: string = Segments[SegmentCount];
		local ParentPath: string = table.concat(Segments, '/', 1, (SegmentCount - 1));

		local StudioInstance: Instance? = StudioInstancesByPath[RelativePath];
		local IDEObject: { [string]: any }? = IDEObjectsByPath[RelativePath];

		local IsScriptItem: boolean = (StudioInstance and StudioInstance:IsA('LuaSourceContainer')) or (IDEObject and (IDEObject.source ~= nil));

		if not IsScriptItem and HasDescendantInSet(RelativePath) then
			continue;
		end

		if StudioInstance and IDEObject then
			local StudioSource: string? = StudioInstance:IsA('LuaSourceContainer') and (StudioInstance :: any).Source or nil;
			local IDESource: string? = (IDEObject.source);

			local IsIdentical: boolean = false;

			if (StudioSource ~= nil) and (IDESource ~= nil) then
				IsIdentical = (NormalizeSourceText(StudioSource) == NormalizeSourceText(IDESource));
			elseif (StudioSource == nil) and (IDESource == nil) then
				IsIdentical = ((StudioInstance.ClassName) == (IDEObject.className or 'Folder'));
			end

			if IsIdentical then
				MatchedCount += 1;

				if StudioSource then
					LastKnownScriptHashes[RelativePath] = StudioSource;
				end
			else
				ConflictCount += 1;

				local RSName: string = (string.sub(LeafName, 1, 3) == 'RS.') and LeafName or (`RS.{LeafName}`);
				local IDEName: string = (string.sub(LeafName, 1, 4) == 'IDE.') and LeafName or (`IDE.{LeafName}`);

				pcall(function(): ()
					StudioInstance.Name = RSName;
				end);

				local IDEClassName: string = (IDEObject.className) or (StudioInstance.ClassName);
				local TargetIDEPath: string = `{ParentPath}/{IDEName}`;
				local CreatedIDEInstance: Instance? = ImportModule.EnsureInstanceHierarchy(TargetIDEPath, IDEClassName);

				if CreatedIDEInstance then
					ImportModule.ApplyPropertiesToObject(CreatedIDEInstance, (IDEObject.properties), (IDEObject.attributes), (IDEObject.tags));

					if (IDEObject.source ~= nil) and CreatedIDEInstance:IsA('LuaSourceContainer') then
						(CreatedIDEInstance :: any).Source = (IDEObject.source);

						LastKnownScriptHashes[TargetIDEPath] = (IDEObject.source);
					end
				end

				print(`[Silicon Merge] Conflict merged for <{RelativePath}> -> Studio: <{RSName}>, IDE: <{IDEName}>.`);
			end

		elseif StudioInstance and not IDEObject then
			local IsFileItem: boolean = StudioInstance:IsA('LuaSourceContainer') or ShouldSynchronizeAllDescendants;

			if IsFileItem and (string.sub(LeafName, 1, 3) ~= 'RS.') and (string.sub(LeafName, 1, 4) ~= 'IDE.') then
				local RSName: string = `RS.{LeafName}`;

				local RenameSuccess: boolean = pcall(function(): ()
					StudioInstance.Name = RSName;
				end);

				if RenameSuccess then
					RenamedCount += 1;

					print(`[Silicon Merge] Prefixed Studio-only object <{LeafName}> -> <{RSName}>.`);
				end
			end

		elseif not StudioInstance and IDEObject then
			local IsFileItem: boolean = (IDEObject.source ~= nil) or ShouldSynchronizeAllDescendants;
			local IDEName: string = (IsFileItem and (string.sub(LeafName, 1, 4) ~= 'IDE.')) and (`IDE.{LeafName}`) or LeafName;
			local TargetIDEPath: string = `{ParentPath}/{IDEName}`;
			local IDEClassName: string = (IDEObject.className) or 'Folder';
			local CreatedIDEInstance: Instance? = ImportModule.EnsureInstanceHierarchy(TargetIDEPath, IDEClassName);

			if CreatedIDEInstance then
				ImportModule.ApplyPropertiesToObject(CreatedIDEInstance, (IDEObject.properties), (IDEObject.attributes), (IDEObject.tags));

				if (IDEObject.source ~= nil) and CreatedIDEInstance:IsA('LuaSourceContainer') then
					(CreatedIDEInstance :: any).Source = (IDEObject.source);

					LastKnownScriptHashes[TargetIDEPath] = (IDEObject.source);
				end

				ImportedCount += 1;

				print(`[Silicon Merge] Imported IDE-only object <{LeafName}> as <{IDEName}>.`);
			end
		end
	end

	print(`[Silicon Merge] Reconciliation completed ({MatchedCount} identical, {ConflictCount} conflicts merged, {RenamedCount} Studio-prefixed, {ImportedCount} IDE-imported).`);
	print('[Silicon Merge] Exporting consolidated merged place hierarchy to IDE...');

	Export(nil, false);

	print('[Silicon Merge] Successfully finalized Bidirectional merge on both Studio and IDE!');

	return;
end



local function SynchronizeBidirectional(): (RBXScriptConnection, RBXScriptConnection)
	EnsurePluginCopy();

	print('[Silicon] Initiating Bidirectional synchronization with automatic merge...');

	PerformBidirectionalMerge();

	print('[Silicon] Starting Bidirectional live synchronization...');

	return SynchronizeExport(), SynchronizeImport();
end



local function SynchronizeBidirectionalFromRoblox(): (RBXScriptConnection, RBXScriptConnection)
	EnsurePluginCopy();

	Settings.SynchronizeAllDescendants = false;
	Settings.SyncAllDescendants = false;

	Connect.PostSettings({ SynchronizeAllDescendants = false, SyncAllDescendants = false });

	print('[Silicon] Performing initial export from Roblox Studio to IDE before starting Bidirectional synchronization...');

	Export(nil, false);

	print('[Silicon] Initial export completed. Starting Bidirectional live synchronization...');

	return SynchronizeExport(), SynchronizeImport();
end



local function SynchronizeBidirectionalFromIDE(): (RBXScriptConnection, RBXScriptConnection)
	EnsurePluginCopy();

	Settings.SynchronizeAllDescendants = false;
	Settings.SyncAllDescendants = false;

	Connect.PostSettings({ SynchronizeAllDescendants = false, SyncAllDescendants = false });

	print('[Silicon] Performing initial import from IDE into Roblox Studio before starting Bidirectional synchronization...');

	local ImportFunc: ((boolean?) -> ()) = (ImportModule.Import or ImportModule);

	ImportFunc(false);

	EnsurePluginCopy();

	print('[Silicon] Initial import completed. Starting Bidirectional live synchronization...');

	return SynchronizeExport(), SynchronizeImport();
end



local function SynchronizeAllDescendants(): (RBXScriptConnection, RBXScriptConnection)
	EnsurePluginCopy();

	print('[Silicon] Initiating AllDescendants synchronization (all place descendants)...');

	Settings.SynchronizeAllDescendants = true;
	Settings.SyncAllDescendants = true;

	Connect.PostSettings({ SynchronizeAllDescendants = true, SyncAllDescendants = true });

	print('[Silicon] Performing initial export of ALL descendants from Roblox Studio to IDE...');

	Export(nil, false);

	print('[Silicon] Initial all-descendants export completed. Starting Bidirectional live synchronization...');

	return SynchronizeExport(), SynchronizeImport();
end



Synchronize.Export                  = SynchronizeExport;
Synchronize.Import                  = SynchronizeImport;
Synchronize.Bidirectional           = SynchronizeBidirectional;
Synchronize.BidirectionalFromRoblox = SynchronizeBidirectionalFromRoblox;
Synchronize.BidirectionalFromIDE    = SynchronizeBidirectionalFromIDE;
Synchronize.AllDescendants          = SynchronizeAllDescendants;



return Synchronize;
