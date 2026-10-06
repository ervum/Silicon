--!strict

local Root: Script = script:FindFirstAncestorOfClass('Script');

local T = require(Root.Shared.Types);
local Dependencies = require(Root.Create.GetDependencies);



local Settings: { [string]: any } = (Dependencies.Settings);

local PN: string, AN: string, TN: string = (Settings.PropertiesName), (Settings.AttributesName), (Settings.TagsName);



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
	GetAncestry                 = GetAncestry,
} :: { [string]: any };
