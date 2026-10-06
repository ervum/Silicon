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



local Settings: { [string]: any } = (Dependencies.Settings);

local ExportDebounceTime: number = (Settings.SynchronizationRSDebounceTime or 0.1);
local LongPollTimeout: number = (Settings.LongPollTimeout or 5.0);
local Host: string = (Settings.ServerHost or 'localhost');
local Port: number = (Settings.ServerPort or 6969);



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



local function SynchronizeBidirectional(): (RBXScriptConnection, RBXScriptConnection)
	return SynchronizeExport(), SynchronizeImport();
end



local function SynchronizeBidirectionalFromRoblox(): (RBXScriptConnection, RBXScriptConnection)
	EnsurePluginCopy();

	Settings.SyncAllDescendants = false;

	Connect.PostSettings({ SyncAllDescendants = false });

	print('[Silicon] Performing initial export from Roblox Studio to IDE before starting Bidirectional sync...');

	Export(nil, false);

	print('[Silicon] Initial export completed. Starting Bidirectional live sync...');

	return SynchronizeBidirectional();
end



local function SynchronizeBidirectionalFromIDE(): (RBXScriptConnection, RBXScriptConnection)
	EnsurePluginCopy();

	Settings.SyncAllDescendants = false;

	Connect.PostSettings({ SyncAllDescendants = false });

	print('[Silicon] Performing initial import from IDE into Roblox Studio before starting Bidirectional sync...');

	local ImportFunc: ((boolean?) -> ()) = (ImportModule.Import or ImportModule);

	ImportFunc(false);

	EnsurePluginCopy();

	print('[Silicon] Initial import completed. Starting Bidirectional live sync...');

	return SynchronizeBidirectional();
end



local function SynchronizeAllDescendants(): (RBXScriptConnection, RBXScriptConnection)
	EnsurePluginCopy();

	print('[Silicon] Initiating AllDescendants synchronization (all place descendants)...');

	Settings.SyncAllDescendants = true;

	Connect.PostSettings({ SyncAllDescendants = true });

	print('[Silicon] Performing initial export of ALL descendants from Roblox Studio to IDE...');

	Export(nil, false);

	print('[Silicon] Initial all-descendants export completed. Starting Bidirectional live sync...');

	return SynchronizeBidirectional();
end



Synchronize.Export                  = SynchronizeExport;
Synchronize.Import                  = SynchronizeImport;
Synchronize.Bidirectional           = SynchronizeBidirectional;
Synchronize.BidirectionalFromRoblox = SynchronizeBidirectionalFromRoblox;
Synchronize.BidirectionalFromIDE    = SynchronizeBidirectionalFromIDE;
Synchronize.AllDescendants          = SynchronizeAllDescendants;



return Synchronize;
