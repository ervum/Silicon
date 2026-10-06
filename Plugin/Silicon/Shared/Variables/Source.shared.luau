--!strict

local Root: Script = script:FindFirstAncestorOfClass('Script');

local T = require(Root.Shared.Types);
local Dependencies = require(Root.Create.GetDependencies);



local Settings: { [string]: any } = (Dependencies.Settings);

local PN: string, AN: string, TN: string = (Settings.PropertiesName), (Settings.AttributesName), (Settings.TagsName);



local RootFolderName: string = (Settings.RootFolderName or 'Silicon');
local PluginFolderName: string = (Settings.PluginFolderName or 'Silicon');
local RecycleBinFolderName: string = (Settings.RecycleBinFolderName or 'Recycle Bin');



local GenericHTTPCallsArguments: { [string]: { [number]: any }} = { 
	PostAsync = { 
		'',
		(Enum.HttpContentType.ApplicationJson),
		true,
	}, 
	GetAsync  = { 
		true,
	},
};

local EmptyPropertiesTable: (T.PropertiesObject) = { [PN] = { [AN] = { }, [TN] = { }}};

local JSONReturnablePropertyTypes: { [number]: string } = { 'string', 'number', 'boolean', 'table', 'nil' };

local IrreplicableClasses: { [number]: string } = {
	'StarterPlayerScripts',
	'StarterCharacterScripts',

	'ClientReplicator',

	'ChatWindowConfiguration',
	'ChatInputBarConfiguration',
	'ChannelTabsConfiguration',
	'BubbleChatConfiguration',
};

local LastKnownScriptHashes: { [string]: string } = { };

local State: { IsApplyingRemoteUpdate: boolean } = {
	IsApplyingRemoteUpdate = false,
};



local function EnsurePluginCopy(): (Instance?)
	local ServiceSuccess: boolean, ServiceResult: any = pcall(function(): (Instance)
		return game:GetService('ReplicatedStorage');
	end);

	local ReplicatedStorageInstance: Instance? = ServiceSuccess and ServiceResult or game:FindFirstChild('ReplicatedStorage');

	if not ReplicatedStorageInstance then return nil end

	local ConfiguredRootFolderName: string = (Settings.RootFolderName or RootFolderName or 'Silicon');
	local ConfiguredPluginFolderName: string = (Settings.PluginFolderName or PluginFolderName or 'Silicon');

	local RootFolder: Instance? = ReplicatedStorageInstance:FindFirstChild(ConfiguredRootFolderName);

	if not RootFolder then
		local NewRootFolder: Folder = Instance.new('Folder');

		NewRootFolder.Name = ConfiguredRootFolderName;
		NewRootFolder.Parent = ReplicatedStorageInstance;

		RootFolder = NewRootFolder;
	end

	local PluginContainer: Instance? = (RootFolder :: Instance):FindFirstChild(ConfiguredPluginFolderName);

	if not PluginContainer then
		local NewPluginFolder: Folder = Instance.new('Folder');

		NewPluginFolder.Name = ConfiguredPluginFolderName;
		NewPluginFolder.Parent = RootFolder;

		PluginContainer = NewPluginFolder;
	end

	local LegacySiliconPlugin: Instance? = (RootFolder :: Instance):FindFirstChild('Plugin');

	if LegacySiliconPlugin and (LegacySiliconPlugin ~= PluginContainer) then
		LegacySiliconPlugin:Destroy();
	end

	local LegacyRootPlugin: Instance? = ReplicatedStorageInstance:FindFirstChild('Plugin');

	if LegacyRootPlugin and (LegacyRootPlugin ~= PluginContainer) and (LegacyRootPlugin ~= RootFolder) then
		LegacyRootPlugin:Destroy();
	end

	local ExistingPlugin: Instance? = (PluginContainer :: Instance):FindFirstChild((Root.Name));

	if (PluginContainer :: Instance):IsA('Folder') and (Root.Parent ~= PluginContainer) and (not ExistingPlugin or (#ExistingPlugin:GetChildren() < #Root:GetChildren())) then
		if ExistingPlugin then
			ExistingPlugin:Destroy();
		end

		Root.Archivable = true;

		for _: number, DescendantInstance: Instance in Root:GetDescendants() do
			DescendantInstance.Archivable = true;
		end

		local ScriptClone: Instance? = Root:Clone();

		if ScriptClone then
			ScriptClone.Archivable = true;
			ScriptClone.Parent = PluginContainer;

			print(`[Silicon] Successfully installed copy of Silicon into ReplicatedStorage/{ConfiguredRootFolderName}/{ConfiguredPluginFolderName}.`);
		end
	end

	return PluginContainer;
end

local function GetAncestry(Object: Instance): ({ [number]: string })
	local Ancestry: { [number]: string } = { };
	local CurrentObject: Instance? = Object;

	repeat 
		if CurrentObject then
			table.insert(Ancestry, 1, (CurrentObject.Name));

			CurrentObject = (CurrentObject.Parent);
		end
	until not CurrentObject or (CurrentObject == game);

	return Ancestry;
end



return {
	GenericHTTPCallsArguments   = GenericHTTPCallsArguments,
	EmptyPropertiesTable        = EmptyPropertiesTable,
	JSONReturnablePropertyTypes = JSONReturnablePropertyTypes,
	IrreplicableClasses         = IrreplicableClasses,
	LastKnownScriptHashes       = LastKnownScriptHashes,
	State                       = State,
	RootFolderName              = RootFolderName,
	PluginFolderName            = PluginFolderName,
	RecycleBinFolderName        = RecycleBinFolderName,
	EnsurePluginCopy            = EnsurePluginCopy,
	GetAncestry                 = GetAncestry,
} :: { [string]: any };
