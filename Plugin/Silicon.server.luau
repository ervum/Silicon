--!strict

local Toolbar: PluginToolbar = plugin:CreateToolbar('Silicon');



local T = require(script.Shared.Types);
local Dependencies = require(script.Create.GetDependencies);



local IsHTTPServerRunning: ((string?, string?, { [string]: string }?) -> (boolean)) = (Dependencies.Connect.IsHTTPServerRunning);
local Export: ((Instance?) -> ()) = require(Dependencies.__Export__); ---> <Export> requires <APIService>, that requires <API> which is too large, and that might cause problems if directly returned through the <GetDependencies>-MetaTable (C-Call Boundary).
local ImportModule: any = (Dependencies.Import);
local Import: ((boolean?) -> ()) = (ImportModule.Import or ImportModule);
local Synchronize: { [string]: (() -> ( ... any)) } = (Dependencies.Synchronize);



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



local function EnsurePluginCopy(): (Instance?)
	local ReplicatedStorage: Instance? = nil;

	local ServiceSuccess: boolean, ServiceResult: any = pcall(function(): (Instance)
		return game:GetService('ReplicatedStorage');
	end);

	if ServiceSuccess and ServiceResult then
		ReplicatedStorage = ServiceResult;
	else
		ReplicatedStorage = game:FindFirstChild('ReplicatedStorage');
	end

	if not ReplicatedStorage then return nil end

	local SiliconFolder: Instance? = ReplicatedStorage:FindFirstChild('Silicon');

	if not SiliconFolder then
		local NewSiliconFolder: Folder = Instance.new('Folder');

		NewSiliconFolder.Name = 'Silicon';
		NewSiliconFolder.Parent = ReplicatedStorage;

		SiliconFolder = NewSiliconFolder;
	end

	local PluginContainer: Instance? = SiliconFolder:FindFirstChild('Plugin');

	if not PluginContainer then
		local NewPluginFolder: Folder = Instance.new('Folder');

		NewPluginFolder.Name = 'Plugin';
		NewPluginFolder.Parent = SiliconFolder;

		PluginContainer = NewPluginFolder;
	end

	local ExistingPlugin: Instance? = PluginContainer:FindFirstChild((script.Name));

	if PluginContainer:IsA('Folder') and (script.Parent ~= PluginContainer) and (not ExistingPlugin or (#ExistingPlugin:GetChildren() < #script:GetChildren())) then
		if ExistingPlugin then
			ExistingPlugin:Destroy();
		end

		script.Archivable = true;

		for _: number, DescendantInstance: Instance in script:GetDescendants() do
			DescendantInstance.Archivable = true;
		end

		local ScriptClone: Instance? = script:Clone();

		if ScriptClone then
			ScriptClone.Archivable = true;
			ScriptClone.Parent = PluginContainer;

			print('[Silicon] Successfully installed copy of Silicon into ReplicatedStorage/Silicon/Plugin.');
		end
	end

	return PluginContainer;
end

EnsurePluginCopy();



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

	return;
end



Dependencies.Create(
	Toolbar,
	`Export`,
	`Exports all scripts within the specified current place to the local IDE directory.`,
	'rbxassetid://78911552761219',
	`Exported all scripts to locally hosted server via {PluginName}`,
	true,
	function(): ()
		if IsHTTPServerRunning() then
			Export();
		end
	end,
	nil
);

Dependencies.Create(
	Toolbar,
	`Import`,
	`Imports all scripts within the specified local IDE directory to the current place.`,
	'rbxassetid://78911552761219',
	`Imported all scripts from locally hosted server via {PluginName}`,
	true,
	function(): ()
		if IsHTTPServerRunning() then
			Import();
		end
	end,
	nil
);

Dependencies.Create(
	Toolbar,
	`Export-Synchronize`,
	`Synchronizes scripts to the IDE by sending their updated versions upon ending typing.`,
	'rbxassetid://78911552761219',
	`Synchronized scripts to locally hosted server via {PluginName}`,
	true,
	function(): ()
		if IsHTTPServerRunning() then
			ToggleSynchronization('Export');
		end
	end,
	nil
);

Dependencies.Create(
	Toolbar,
	`Import-Synchronize`,
	`Synchronizes scripts from the IDE by receiving their updated versions upon ending typing.`,
	'rbxassetid://78911552761219',
	`Synchronized scripts to locally hosted server via {PluginName}`,
	true,
	function(): ()
		if IsHTTPServerRunning() then
			ToggleSynchronization('Import');
		end
	end,
	nil
);

Dependencies.Create(
	Toolbar,
	`Bidirectional`,
	`Continuously synchronizes scripts and hierarchy bidirectionally between Roblox Studio and the local IDE directory with instant reactivity and Recycle Bin safety.`,
	'rbxassetid://78911552761219',
	`Synchronized scripts bidirectionally via {PluginName}`,
	true,
	function(): ()
		if IsHTTPServerRunning() then
			ToggleSynchronization('Bidirectional');
		end
	end,
	nil
);

Dependencies.Create(
	Toolbar,
	`Bidirectional from Roblox`,
	`Starts bidirectional synchronization with an initial export from Roblox Studio to the local IDE directory.`,
	'rbxassetid://78911552761219',
	`Synchronized scripts bidirectionally from Roblox via {PluginName}`,
	true,
	function(): ()
		if IsHTTPServerRunning() then
			ToggleSynchronization('BidirectionalFromRoblox');
		end
	end,
	nil
);

Dependencies.Create(
	Toolbar,
	`Bidirectional from IDE`,
	`Starts bidirectional synchronization with an initial import from the local IDE directory to Roblox Studio.`,
	'rbxassetid://78911552761219',
	`Synchronized scripts bidirectionally from IDE via {PluginName}`,
	true,
	function(): ()
		if IsHTTPServerRunning() then
			ToggleSynchronization('BidirectionalFromIDE');
		end
	end,
	nil
);

Dependencies.Create(
	Toolbar,
	`All Descendants`,
	`Continuously synchronizes ALL descendants of game bidirectionally between Roblox Studio and the local IDE directory, including all non-script instances.`,
	'rbxassetid://78911552761219',
	`Synchronized all descendants of game via {PluginName}`,
	true,
	function(): ()
		if IsHTTPServerRunning() then
			ToggleSynchronization('AllDescendants');
		end
	end,
	nil
);

