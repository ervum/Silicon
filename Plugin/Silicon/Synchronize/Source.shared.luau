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
local EnsureInstanceHierarchy: ((string, string) -> (Instance?)) = (ImportModule.EnsureInstanceHierarchy);
local ApplyPropertiesToObject: ((Instance, { [string]: any }?, { [string]: any }?, { [number]: string }?) -> ()) = (ImportModule.ApplyPropertiesToObject);
local SafelyDeleteOrRecycle: ((Instance, string) -> (boolean)) = (ImportModule.SafelyDeleteOrRecycle);
local Connect: { [string]: (( ... any) -> ( ... any)) } = (Dependencies.Connect);
local Variables: { [string]: any } = (Dependencies.Variables);
local EnsurePluginCopy: (() -> (Instance?)) = (Variables.EnsurePluginCopy);
local GetAncestry: ((Instance) -> ({ [number]: string })) = (Variables.GetAncestry);
local State: { IsApplyingRemoteUpdate: boolean } = (Variables.State);



local Settings: { [string]: any } = (Dependencies.Settings);

local ExportDebounceTime: number = (Settings.SynchronizationRSDebounceTime or 0.1);
local LongPollTimeout: number = (Settings.LongPollTimeout or 5.0);
local Host: string = (Settings.ServerHost or 'localhost');
local Port: number = (Settings.ServerPort or 6969);



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



local LastTypingTime: number = os.clock();
local IsTyping: boolean = false;



local function NormalizeSourceText(RawText: string?): (string)
	if not RawText then return '' end

	local Normalized: string = string.gsub(RawText, '\r\n', '\n');
	Normalized = string.gsub(Normalized, '\r', '\n');
	Normalized = string.gsub(Normalized, '^%s*(.-)%s*$', '%1');

	return Normalized;
end

local function SetScriptSourceSafe(TargetInstance: Instance, NewSource: string): ()
	local UpdatedViaSES: boolean = false;

	if SES then
		pcall(function(): ()
			SES:UpdateSourceAsync(TargetInstance, function(_: string): (string)
				return NewSource;
			end);

			UpdatedViaSES = true;

			return;
		end);
	end

	if not UpdatedViaSES then
		pcall(function(): ()
			(TargetInstance :: any).Source = NewSource;

			return;
		end);
	end

	return;
end

local function DeleteRemotePath(RelativePath: string): ()
	local TargetHost: string = (Settings.ServerHost or Host or 'localhost');
	local TargetPort: number = (Settings.ServerPort or Port or 6969);
	local TargetURL: string = `http://{TargetHost}:{TargetPort}/synchronization`;

	local Payload: string = HTTP:JSONEncode({
		action = 'delete',
		path   = RelativePath,
	});

	pcall(function(): ()
		HTTP:PostAsync(TargetURL, Payload, (Enum.HttpContentType.ApplicationJson));

		return;
	end);

	return;
end

---> Reconciles conflicting files (different content, same name, same hierarchical path)
---> according to <Settings.ConflictMode> ('Both' | 'Delete' | 'IDE' | 'RS').
---> Non-conflicting files are never renamed with prefixes.
local function ResolveSynchronizationConflicts(): ()
	local TargetHost: string = (Settings.ServerHost or Host or 'localhost');
	local TargetPort: number = (Settings.ServerPort or Port or 6969);
	local ConflictPolicy: string = (Settings.ConflictMode or 'Both');
	local ShouldSynchronizeAllDescendants: boolean = (Settings.SynchronizeAllDescendants == true) or (Settings.SyncAllDescendants == true);

	local Data: any = Connect.GetData(TargetHost, TargetPort);

	if not Data or not Data.files then return end

	local IDEObjectsByPath: { [string]: { [string]: any } } = { };

	for _: number, Item: { [string]: any } in Data.files do
		if Item.path then
			IDEObjectsByPath[Item.path] = Item;
		end
	end

	local RSInstancesByPath: { [string]: Instance } = { };

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

		if not ServiceInstance then continue end

		for _: number, DescendantObject: Instance in ServiceInstance:GetDescendants() do
			if not ShouldSynchronizeAllDescendants and not DescendantObject:IsA('LuaSourceContainer') then
				continue;
			end

			local AncestryNames: { [number]: string } = GetAncestry(DescendantObject);
			local RelativePath: string = table.concat(AncestryNames, '/');

			if string.find(RelativePath, '^ReplicatedStorage/Silicon/') or (RelativePath == 'ReplicatedStorage/Silicon') then
				continue;
			end

			RSInstancesByPath[RelativePath] = DescendantObject;
		end
	end

	State.IsApplyingRemoteUpdate = true;

	for RelativePath: string, RSInstance: Instance in RSInstancesByPath do
		local IDEObject: { [string]: any }? = IDEObjectsByPath[RelativePath];

		if not IDEObject then continue end

		local Segments: { [number]: string } = string.split(RelativePath, '/');
		local LeafName: string = Segments[#Segments];

		if (string.sub(LeafName, 1, 3) == 'RS.') or (string.sub(LeafName, 1, 4) == 'IDE.') then
			continue;
		end

		local ParentPath: string = table.concat(Segments, '/', 1, (#Segments - 1));
		local IsScriptConflict: boolean = false;

		if RSInstance:IsA('LuaSourceContainer') or (IDEObject.source ~= nil) then
			local RSSource: string = RSInstance:IsA('LuaSourceContainer') and ((RSInstance :: any).Source or '') or '';
			local IDESource: string = (IDEObject.source or '');

			if (NormalizeSourceText(RSSource) ~= NormalizeSourceText(IDESource)) then
				IsScriptConflict = true;
			end
		end

		if not IsScriptConflict then continue end

		if (ConflictPolicy == 'Both') then
			---> State 1: Both files persist with 'RS.' and 'IDE.' prefixes
			local RSPrefixedName: string = `RS.{LeafName}`;
			local IDEPrefixedName: string = `IDE.{LeafName}`;
			local RSPrefixedPath: string = `{ParentPath}/{RSPrefixedName}`;
			local IDEPrefixedPath: string = `{ParentPath}/{IDEPrefixedName}`;

			pcall(function(): ()
				RSInstance.Name = RSPrefixedName;

				return;
			end);

			local IDEInstance: Instance? = EnsureInstanceHierarchy(IDEPrefixedPath, (IDEObject.className or RSInstance.ClassName));

			if IDEInstance then
				ApplyPropertiesToObject(IDEInstance, IDEObject.properties, IDEObject.attributes, IDEObject.tags);

				if (IDEObject.source ~= nil) and IDEInstance:IsA('LuaSourceContainer') then
					SetScriptSourceSafe(IDEInstance, IDEObject.source);
				end
			end

			DeleteRemotePath(RelativePath);
			Export(RSInstance, true);

			if IDEInstance then
				Export(IDEInstance, true);
			end

			print(`[Silicon Conflict] Conflicting file at <{RelativePath}> resolved with State 1 (Both Persist): created <{RSPrefixedPath}> and <{IDEPrefixedPath}>.`);

		elseif (ConflictPolicy == 'Delete') then
			---> State 2: Delete conflicting file from both RS and IDE
			SafelyDeleteOrRecycle(RSInstance, RelativePath);
			DeleteRemotePath(RelativePath);

			print(`[Silicon Conflict] Conflicting file at <{RelativePath}> resolved with State 2 (Delete Both): moved to Recycle Bin.`);

		elseif (ConflictPolicy == 'IDE') then
			---> State 3: IDE file persists (overwrite RS with IDE)
			ApplyPropertiesToObject(RSInstance, IDEObject.properties, IDEObject.attributes, IDEObject.tags);

			if (IDEObject.source ~= nil) and RSInstance:IsA('LuaSourceContainer') then
				SetScriptSourceSafe(RSInstance, IDEObject.source);
			end

			print(`[Silicon Conflict] Conflicting file at <{RelativePath}> resolved with State 3 (IDE Persists): updated RS from IDE.`);

		elseif (ConflictPolicy == 'RS') then
			---> State 4: RS file persists (overwrite IDE with RS)
			Export(RSInstance, true);

			print(`[Silicon Conflict] Conflicting file at <{RelativePath}> resolved with State 4 (RS Persists): updated IDE from RS.`);
		end
	end

	State.IsApplyingRemoteUpdate = false;

	return;
end



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



local function SynchronizeBidirectional(): (RBXScriptConnection, RBXScriptConnection)
	EnsurePluginCopy();

	local ShouldSynchronizeAllDescendants: boolean = (Settings.SynchronizeAllDescendants == true) or (Settings.SyncAllDescendants == true);
	local InitialFromRS: boolean = (Settings.InitialSyncFromRS == true);
	local ConflictPolicy: string = (Settings.ConflictMode or 'Both');

	Connect.PostSettings({
		SynchronizeAllDescendants = ShouldSynchronizeAllDescendants,
		SyncAllDescendants        = ShouldSynchronizeAllDescendants,
		InitialSyncFromRS         = InitialFromRS,
		ConflictMode              = ConflictPolicy,
	});

	ResolveSynchronizationConflicts();

	if InitialFromRS then
		print('[Silicon] Performing initial export from RS to IDE before starting Bidirectional synchronization...');

		Export(nil, true);
	else
		print('[Silicon] Performing initial import from IDE into RS before starting Bidirectional synchronization...');

		local ImportFunc: ((boolean?) -> ()) = (ImportModule.Import or ImportModule);

		ImportFunc(true);

		EnsurePluginCopy();
	end

	print('[Silicon] Initial synchronization completed. Starting Bidirectional live synchronization...');

	return SynchronizeExport(), SynchronizeImport();
end



local function SynchronizeUnidirectional(): (RBXScriptConnection)
	EnsurePluginCopy();

	local ShouldSynchronizeAllDescendants: boolean = (Settings.SynchronizeAllDescendants == true) or (Settings.SyncAllDescendants == true);
	local InitialFromRS: boolean = (Settings.InitialSyncFromRS == true);
	local ConflictPolicy: string = (Settings.ConflictMode or 'Both');

	Connect.PostSettings({
		SynchronizeAllDescendants = ShouldSynchronizeAllDescendants,
		SyncAllDescendants        = ShouldSynchronizeAllDescendants,
		InitialSyncFromRS         = InitialFromRS,
		ConflictMode              = ConflictPolicy,
	});

	ResolveSynchronizationConflicts();

	if InitialFromRS then
		print('[Silicon] Performing initial export from RS to IDE before starting Unidirectional (RS -> IDE) synchronization...');

		Export(nil, true);

		print('[Silicon] Initial export completed. Starting Unidirectional (RS -> IDE) live synchronization...');

		return SynchronizeExport();
	else
		print('[Silicon] Performing initial import from IDE into RS before starting Unidirectional (IDE -> RS) synchronization...');

		local ImportFunc: ((boolean?) -> ()) = (ImportModule.Import or ImportModule);

		ImportFunc(true);

		EnsurePluginCopy();

		print('[Silicon] Initial import completed. Starting Unidirectional (IDE -> RS) live synchronization...');

		return SynchronizeImport();
	end
end



Synchronize.Export = SynchronizeExport;
Synchronize.Import = SynchronizeImport;
Synchronize.Bidirectional = SynchronizeBidirectional;
Synchronize.Unidirectional = SynchronizeUnidirectional;
Synchronize.ResolveConflicts = ResolveSynchronizationConflicts;



return Synchronize;
