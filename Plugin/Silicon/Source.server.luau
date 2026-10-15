--!strict

local Toolbar: PluginToolbar = plugin:CreateToolbar('Silicon');



local T = require(script.Shared.Types);
local Dependencies = require(script.Create.GetDependencies);



local Connect: { [string]: (( ... any) -> ( ... any)) } = (Dependencies.Connect);
local IsHTTPServerRunning: ((string?, string?, { [string]: string }?) -> (boolean)) = (Connect.IsHTTPServerRunning);
local PostSettings: (({ [string]: any }, string?, string?, { [string]: string }?) -> ({ [string]: any })) = (Connect.PostSettings);
local Export: ((Instance?) -> ()) = require(Dependencies.__Export__); ---> <Export> requires <APIService>, that requires <API> which is too large, and that might cause problems if directly returned through the <GetDependencies>-MetaTable (C-Call Boundary).
local ImportModule: any = (Dependencies.Import);
local Import: ((boolean?) -> ()) = (ImportModule.Import or ImportModule);
local ClearRSProject: (() -> (number)) = (ImportModule.ClearRSProject);
local ClearIDEProject: ((string?, string?) -> (boolean)) = (Connect.ClearProject);
local Synchronize: { [string]: (() -> ( ... any)) } = (Dependencies.Synchronize);
local ResolveConflicts: (() -> ()) = (Synchronize.ResolveConflicts);
local Variables: { [string]: any } = (Dependencies.Variables);
local EnsurePluginCopy: (() -> (Instance?)) = (Variables.EnsurePluginCopy);
local SetPluginUIRoot: ((Instance?) -> ()) = (Variables.SetPluginUIRoot);



local Status: {
	Connections: { [number?]: RBXScriptConnection },
	State:       boolean,
} = {
	Connections = { },
	State       = false,
};
local Connections: { [number?]: RBXScriptConnection } = (Status.Connections);



local ActiveMethod: string? = nil;



EnsurePluginCopy();

local Settings: { [string]: any } = (Dependencies.Settings);
local Version: string = (Settings.Version or '0.0.0');

local function LoadPersistedSetting(SettingKey: string, DefaultValue: boolean): (boolean)
	local Success: boolean, SavedValue: any = pcall(function(): (any)
		return plugin:GetSetting(SettingKey);
	end);

	if Success and (type(SavedValue) == 'boolean') then
		return SavedValue;
	end

	return DefaultValue;
end

local function LoadPersistedStringSetting(SettingKey: string, DefaultValue: string): (string)
	local Success: boolean, SavedValue: any = pcall(function(): (any)
		return plugin:GetSetting(SettingKey);
	end);

	if Success and (type(SavedValue) == 'string') and (SavedValue ~= '') then
		return SavedValue;
	end

	return DefaultValue;
end

local function SavePersistedSetting(SettingKey: string, NewValue: any): ()
	pcall(function(): ()
		plugin:SetSetting(SettingKey, NewValue);

		return;
	end);

	return;
end

Settings.SynchronizeAllDescendants = LoadPersistedSetting(
	'Silicon_SynchronizeAllDescendants',
	(Settings.SynchronizeAllDescendants == true)
);
Settings.InitialSyncFromRS = LoadPersistedSetting(
	'Silicon_InitialSyncFromRS',
	(Settings.InitialSyncFromRS == true)
);
Settings.ShowRibbonTab = LoadPersistedSetting(
	'Silicon_ShowRibbonTab',
	(Settings.ShowRibbonTab ~= false)
);

local LoadedConflictMode: string = LoadPersistedStringSetting(
	'Silicon_ConflictMode',
	(Settings.ConflictMode or 'Both')
);

if (LoadedConflictMode ~= 'Both') and (LoadedConflictMode ~= 'Delete') and (LoadedConflictMode ~= 'IDE') and (LoadedConflictMode ~= 'RS') then
	LoadedConflictMode = 'Both';
end

Settings.ConflictMode = LoadedConflictMode;

print(`[Silicon] Silicon Roblox Plugin v{Version} initialized!`);



local UIModule: any = require(script.UI);
local UIController: any = nil;

local SiliconIconAsset: string = 'rbxassetid://78911552761219';

---> Only register <Launch Silicon> on the built-in Plugins Ribbon Tab.
local LaunchButton: PluginToolbarButton = Toolbar:CreateButton(
	'LaunchSilicon',
	'Open the Silicon synchronization dashboard and controls',
	SiliconIconAsset,
	'Launch Silicon'
);
LaunchButton.ClickableWhenViewportHidden = true;



local function SynchronizePersistedSettings(): ()
	local Response: { [string]: any } = PostSettings({
		SynchronizeAllDescendants = (Settings.SynchronizeAllDescendants == true),
		SyncAllDescendants        = (Settings.SynchronizeAllDescendants == true),
		InitialSyncFromRS         = (Settings.InitialSyncFromRS == true),
		ShowRibbonTab             = (Settings.ShowRibbonTab ~= false),
		ConflictMode              = (Settings.ConflictMode or 'Both'),
	});

	if Response and (Response.clearRS == true) then
		local RSClearedCount: number = 0;

		if ClearRSProject then
			RSClearedCount = ClearRSProject();
		end

		if UIController then
			UIController.Log(`Remote IDE Clear Project executed: {RSClearedCount} RS object{(RSClearedCount ~= 1) and 's' or ''} recycled.`);
		end
	end

	return;
end

local function ApplyRibbonTabVisibility(IsVisible: boolean): ()
	Settings.ShowRibbonTab = IsVisible;

	task.spawn(function(): ()
		SynchronizePersistedSettings();

		return;
	end);

	return;
end

local function ToggleSynchronization(Method: string): ()
	EnsurePluginCopy();

	if (ActiveMethod == Method) then
		print(`[Silicon] Stopping active synchronization ({Method})...`);

		for i: number, Connection: RBXScriptConnection in Connections do
			Connection:Disconnect();

			Connections[i] = nil;
		end

		Status.State = false;
		ActiveMethod = nil;

		print(`Successfully stopped script synchronization ({Method})!`);

		if UIController then
			UIController.SetStatus('Idle', true, nil);
			UIController.Log(`Stopped {Method} synchronization.`);
		end

		return;
	end

	if (next(Connections) ~= nil) then
		print(`[Silicon] Stopping active synchronization ({ActiveMethod or 'Previous'})...`);

		for i: number, Connection: RBXScriptConnection in Connections do
			Connection:Disconnect();

			Connections[i] = nil;
		end

		Status.State = false;
		ActiveMethod = nil;
	end

	print(`[Silicon] Initiating {Method} synchronization...`);

	Status.State = true;
	ActiveMethod = Method;

	local TargetSynchronizer: (() -> ( ... any))? = (Synchronize[Method]);

	if not TargetSynchronizer then
		warn(`[Silicon] Unknown synchronization mode <{Method}>!`);

		Status.State = false;
		ActiveMethod = nil;

		return;
	end

	local NewConnections: { [number?]: RBXScriptConnection } = { TargetSynchronizer() };

	for _: number, NewConnection: RBXScriptConnection in NewConnections do
		table.insert(Connections, NewConnection);
	end

	print(`Successfully started script synchronization ({Method})!`);

	if UIController then
		UIController.SetStatus('Live', true, Method);
		UIController.Log(`Started {Method} live synchronization.`);
	end

	return;
end



local function SafeCreatePluginAction(ActionID: string, Text: string, StatusTip: string, IconName: string, AllowBinding: boolean): (PluginAction?)
	local Success: boolean, Result: any = pcall(function(): (PluginAction)
		return plugin:CreatePluginAction(ActionID, Text, StatusTip, IconName, AllowBinding);
	end);

	if Success then
		return (Result :: PluginAction);
	end

	return nil;
end

local BidirectionalAction: PluginAction? = SafeCreatePluginAction(
	'SiliconBidirectional',
	'Bidirectional',
	'Toggle two-way live synchronization between IDE and RS',
	SiliconIconAsset,
	true
);

local UnidirectionalAction: PluginAction? = SafeCreatePluginAction(
	'SiliconUnidirectional',
	'Unidirectional',
	'Toggle one-way live synchronization based on the Initial Sync From RS setting',
	SiliconIconAsset,
	true
);

local ExportAction: PluginAction? = SafeCreatePluginAction(
	'SiliconExport',
	'Export to IDE',
	'Export RS objects to local IDE files',
	SiliconIconAsset,
	true
);

local ImportAction: PluginAction? = SafeCreatePluginAction(
	'SiliconImport',
	'Import to RS',
	'Import local IDE files into RS',
	SiliconIconAsset,
	true
);



UIController = UIModule(plugin, {
	ToggleSynchronization = function(Method: string): ()
		if IsHTTPServerRunning() then
			ToggleSynchronization(Method);
		end

		return;
	end,
	Export = function(): ()
		if IsHTTPServerRunning() then
			if ResolveConflicts then
				ResolveConflicts();
			end

			Export();

			if UIController then
				UIController.Log(`Exported {(Settings.SynchronizeAllDescendants) and 'all descendants' or 'scripts'} to IDE.`);
			end
		end

		return;
	end,
	Import = function(): ()
		if IsHTTPServerRunning() then
			if ResolveConflicts then
				ResolveConflicts();
			end

			Import();

			if UIController then
				UIController.Log(`Imported {(Settings.SynchronizeAllDescendants) and 'all descendants' or 'scripts'} to RS.`);
			end
		end

		return;
	end,
	CheckServer = function(): (boolean)
		local Running: boolean = IsHTTPServerRunning();

		if Running then
			SynchronizePersistedSettings();
		end

		return Running;
	end,
	GetActiveMethod = function(): (string?)
		return ActiveMethod;
	end,
	GetVersion = function(): (string)
		return Version;
	end,
	GetAllDescendants = function(): (boolean)
		return (Settings.SynchronizeAllDescendants == true);
	end,
	SetAllDescendants = function(Enabled: boolean): ()
		Settings.SynchronizeAllDescendants = Enabled;
		SavePersistedSetting('Silicon_SynchronizeAllDescendants', Enabled);

		task.spawn(function(): ()
			SynchronizePersistedSettings();

			return;
		end);

		if UIController then
			UIController.Log(`All Descendants set to {Enabled and 'ON (all instances)' or 'OFF (scripts + ancestry)'}.`);
		end

		return;
	end,
	GetInitialFromRS = function(): (boolean)
		return (Settings.InitialSyncFromRS == true);
	end,
	SetInitialFromRS = function(Enabled: boolean): ()
		Settings.InitialSyncFromRS = Enabled;
		SavePersistedSetting('Silicon_InitialSyncFromRS', Enabled);

		task.spawn(function(): ()
			SynchronizePersistedSettings();

			return;
		end);

		if UIController then
			UIController.Log(`Initial Sync source set to {Enabled and 'RS -> IDE' or 'IDE -> RS'}.`);
		end

		return;
	end,
	GetShowRibbonTab = function(): (boolean)
		return (Settings.ShowRibbonTab ~= false);
	end,
	SetShowRibbonTab = function(IsVisible: boolean): ()
		Settings.ShowRibbonTab = IsVisible;
		SavePersistedSetting('Silicon_ShowRibbonTab', IsVisible);
		ApplyRibbonTabVisibility(IsVisible);

		if UIController then
			UIController.Log(`Silicon Ribbon Tab {IsVisible and 'shown' or 'hidden'} (restart RS if tab bar does not refresh).`);
		end

		return;
	end,
	GetConflictMode = function(): (string)
		return (Settings.ConflictMode or 'Both');
	end,
	SetConflictMode = function(NewMode: string): ()
		Settings.ConflictMode = NewMode;
		SavePersistedSetting('Silicon_ConflictMode', NewMode);

		task.spawn(function(): ()
			SynchronizePersistedSettings();

			return;
		end);

		if UIController then
			UIController.Log(`Conflict policy set to: {NewMode}.`);
		end

		return;
	end,
	ClearProject = function(): ()
		local ConnectedToIDE: boolean = IsHTTPServerRunning();

		if (next(Connections) ~= nil) then
			for i: number, Connection: RBXScriptConnection in Connections do
				Connection:Disconnect();

				Connections[i] = nil;
			end

			Status.State = false;
			ActiveMethod = nil;

			if UIController then
				UIController.SetStatus('Idle', ConnectedToIDE, nil);
			end
		end

		local RSClearedCount: number = 0;

		if ClearRSProject then
			RSClearedCount = ClearRSProject();
		end

		local IDECleared: boolean = false;

		if ConnectedToIDE and ClearIDEProject then
			IDECleared = ClearIDEProject(nil, nil);
		end

		if UIController then
			UIController.Log(`Cleared project: {RSClearedCount} RS object{(RSClearedCount ~= 1) and 's' or ''} recycled{IDECleared and ' + IDE Game folder cleared' or ' (local RS only; IDE disconnected)'}.`);
		end

		return;
	end,
});

if SetPluginUIRoot and UIController and UIController.RootContainer then
	SetPluginUIRoot(UIController.RootContainer);
	EnsurePluginCopy();
end

LaunchButton.Click:Connect(function(): ()
	UIController.ToggleUI();

	return;
end);

if BidirectionalAction then
	BidirectionalAction.Triggered:Connect(function(): ()
		if IsHTTPServerRunning() then
			ToggleSynchronization('Bidirectional');
		end

		return;
	end);
end

if UnidirectionalAction then
	UnidirectionalAction.Triggered:Connect(function(): ()
		if IsHTTPServerRunning() then
			ToggleSynchronization('Unidirectional');
		end

		return;
	end);
end

if ExportAction then
	ExportAction.Triggered:Connect(function(): ()
		if IsHTTPServerRunning() then
			if ResolveConflicts then
				ResolveConflicts();
			end

			Export();

			if UIController then
				UIController.Log(`Exported {(Settings.SynchronizeAllDescendants) and 'all descendants' or 'scripts'} to IDE.`);
			end
		end

		return;
	end);
end

if ImportAction then
	ImportAction.Triggered:Connect(function(): ()
		if IsHTTPServerRunning() then
			if ResolveConflicts then
				ResolveConflicts();
			end

			Import();

			if UIController then
				UIController.Log(`Imported {(Settings.SynchronizeAllDescendants) and 'all descendants' or 'scripts'} to RS.`);
			end
		end

		return;
	end);
end

UIController.Widget:GetPropertyChangedSignal('Enabled'):Connect(function(): ()
	LaunchButton:SetActive((UIController.Widget.Enabled));

	return;
end);

LaunchButton:SetActive((UIController.Widget.Enabled));

local PluginUnloaded: boolean = false;

task.spawn(function(): ()
	while not PluginUnloaded do
		SynchronizePersistedSettings();
		task.wait(3.0);
	end

	return;
end);

plugin.Unloading:Connect(function(): ()
	PluginUnloaded = true;

	for i: number, Connection: RBXScriptConnection in Connections do
		Connection:Disconnect();

		Connections[i] = nil;
	end

	return;
end);
