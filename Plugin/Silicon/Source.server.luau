--!strict

local Toolbar: PluginToolbar = plugin:CreateToolbar('Silicon');



local T = require(script.Shared.Types);
local Dependencies = require(script.Create.GetDependencies);



local IsHTTPServerRunning: ((string?, string?, { [string]: string }?) -> (boolean)) = (Dependencies.Connect.IsHTTPServerRunning);
local Export: ((Instance?) -> ()) = require(Dependencies.__Export__); ---> <Export> requires <APIService>, that requires <API> which is too large, and that might cause problems if directly returned through the <GetDependencies>-MetaTable (C-Call Boundary).
local ImportModule: any = (Dependencies.Import);
local Import: ((boolean?) -> ()) = (ImportModule.Import or ImportModule);
local Synchronize: { [string]: (() -> ( ... any)) } = (Dependencies.Synchronize);
local Variables: { [string]: any } = (Dependencies.Variables);
local EnsurePluginCopy: (() -> (Instance?)) = (Variables.EnsurePluginCopy);



local PluginName: string = (script.Name);
local Status: { 
	Connections: { [number?]: RBXScriptConnection }, 
	State: boolean 
} = {
	Connections = { },
	State       = false,	
};
local Connections: { [number?]: RBXScriptConnection } = (Status.Connections);



local ActiveMethod: string? = nil;



EnsurePluginCopy();

local Settings: { [string]: any } = (Dependencies.Settings);
local Version: string = (Settings.Version or '0.0.0');

print(`[Silicon] Silicon Roblox Plugin v{Version} initialized!`);



local UIModule: any = require(script.UI);
local UIController: any = nil;

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

	local NewConnections: { [number?]: RBXScriptConnection } = { Synchronize[Method]() };

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



local MainButton: PluginToolbarButton = Toolbar:CreateButton(
	'Silicon',
	'Open the Silicon synchronization dashboard and controls',
	'rbxasset://textures/Silicon/live.png',
	'Silicon'
);
MainButton.ClickableWhenViewportHidden = true;

local OpenUIAction: PluginAction = plugin:CreatePluginAction(
	'SiliconOpenUI',
	'Silicon UI',
	'Open the Silicon synchronization dashboard',
	'rbxasset://textures/Silicon/live.png',
	true
);

local BidirectionalAction: PluginAction = plugin:CreatePluginAction(
	'SiliconBidirectional',
	'Live Sync',
	'Toggle bidirectional synchronization',
	'rbxasset://textures/Silicon/live.png',
	true
);

local ExportAction: PluginAction = plugin:CreatePluginAction(
	'SiliconExport',
	'Export to IDE',
	'Export all scripts to local files',
	'rbxasset://textures/Silicon/upload.png',
	true
);

local ImportAction: PluginAction = plugin:CreatePluginAction(
	'SiliconImport',
	'Import from IDE',
	'Import all scripts from local files',
	'rbxasset://textures/Silicon/download.png',
	true
);



UIController = UIModule(plugin, {
	ToggleSynchronization = function(Method: string): ()
		if IsHTTPServerRunning() then
			ToggleSynchronization(Method);
		end
	end,
	Export = function(): ()
		if IsHTTPServerRunning() then
			Export();
		end
	end,
	Import = function(): ()
		if IsHTTPServerRunning() then
			Import();
		end
	end,
	CheckServer = function(): (boolean)
		return IsHTTPServerRunning();
	end,
	GetActiveMethod = function(): (string?)
		return ActiveMethod;
	end,
	GetVersion = function(): (string)
		return Version;
	end,
});

MainButton.Click:Connect(function(): ()
	UIController.ToggleUI();
end);

OpenUIAction.Triggered:Connect(function(): ()
	UIController.ToggleUI();
end);

BidirectionalAction.Triggered:Connect(function(): ()
	if IsHTTPServerRunning() then
		ToggleSynchronization('Bidirectional');
	end
end);

ExportAction.Triggered:Connect(function(): ()
	if IsHTTPServerRunning() then
		Export();
	end
end);

ImportAction.Triggered:Connect(function(): ()
	if IsHTTPServerRunning() then
		Import();
	end
end);

UIController.Widget:GetPropertyChangedSignal('Enabled'):Connect(function(): ()
	MainButton:SetActive((UIController.Widget.Enabled));
end);


