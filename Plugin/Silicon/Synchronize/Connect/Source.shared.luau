--!strict

local table: typeof(table) = table.clone(table);



local Connect: { [string]: (( ... any) -> ( ... any)) } = { };



local Root: Script = script:FindFirstAncestorOfClass('Script');

local T = require(Root.Shared.Types);
local Dependencies = require(Root.Create.GetDependencies);


local HTTP: HttpService = (Dependencies.Services.HTTP);


local Settings: { [string]: any } = (Dependencies.Settings);

local DefaultChunkSize: number = (Settings.ExportFromRSDataChunkSize);
local DefaultStatusHeader: { [string]: string } = (Settings.StatusHeader);
local DefaultSettingsHeader: { [string]: string } = (Settings.SettingsHeader);
local DefaultDataHeader: { [string]: string } = (Settings.DataHeader);
local DefaultLIVEHeader: { [string]: string } = (Settings.LIVEHeader);
local DefaultHost: string, DefaultPort: string = (Settings.ServerHost), (Settings.ServerPort);


local GenericHTTPCallsArguments: { [string]: { [number]: any }} = (Dependencies.Variables.GenericHTTPCallsArguments);

local PostGenericArguments: { [number]: any } = (GenericHTTPCallsArguments.PostAsync);
local GetGenericArguments: { [number]: any } = (GenericHTTPCallsArguments.GetAsync);



table = (Dependencies.Table);



function Connect.IsHTTPServerRunning(Host: string?, Port: string?, StatusHeader: { [string]: string }?): (boolean)
	Host, Port = Host or DefaultHost, Port or DefaultPort;

	local RetrievedSettings: { [string]: any } = Connect.GetSettings(Host, Port);

	DefaultStatusHeader = (RetrievedSettings.StatusHeader or DefaultStatusHeader);
	StatusHeader = StatusHeader or DefaultStatusHeader;

	local ServerURL: string = `http://{Host}:{Port}`;

	local GenericPostCallArguments: { [number]: any } = table.clone(PostGenericArguments);
	local GenericGetCallArguments: { [number]: any } = table.clone(GetGenericArguments);

	table.insert(GenericPostCallArguments, StatusHeader);
	table.insert(GenericGetCallArguments, StatusHeader);

	local PostSuccess: boolean, PostResponse: string? = pcall(function(): (string)
		return HTTP:PostAsync(ServerURL, table.unpack(GenericPostCallArguments));
	end);

	local GetSuccess: boolean, GetResponse: string? = pcall(function(): (string)
		return HTTP:GetAsync(ServerURL, table.unpack(GenericGetCallArguments));
	end);

	if not PostSuccess and not GetSuccess then
		print(`The server has not yet been started, or otherwise cannot be found at {ServerURL}! - \nPOST: {PostResponse} \nGET: {GetResponse}`);
	end

	return PostSuccess or GetSuccess;
end

function Connect.PostSettings(NewSettings: { [string]: any }, Host: string?, Port: string?, SettingsHeader: { [string]: string }?): ({ [string]: any })
	Host, Port = Host or DefaultHost, Port or DefaultPort;
	SettingsHeader = SettingsHeader or DefaultSettingsHeader;

	local SettingsJSON: string = HTTP:JSONEncode(NewSettings);

	pcall(function(): ()
		HTTP:PostAsync(`http://{Host}:{Port}/settings`, SettingsJSON, (Enum.HttpContentType.ApplicationJson), false, SettingsHeader);
	end);

	return Settings;
end

function Connect.GetSettings(Host: string?, Port: string?, SettingsHeader: { [string]: string }?): ({ [string]: (string | number | boolean | { [number]: string })})
	Host, Port = Host or DefaultHost, Port or DefaultPort;
	SettingsHeader = SettingsHeader or DefaultSettingsHeader;

	local GenericCallArguments: { [number]: any } = table.clone(GetGenericArguments);

	table.insert(GenericCallArguments, SettingsHeader);

	local Success: boolean, NewSettings: string? = pcall(function(): (string)
		return HTTP:GetAsync(`http://{Host}:{Port}/settings`, table.unpack(GenericCallArguments));
	end);

	if Success and (NewSettings ~= nil) and (NewSettings ~= '') then
		local DecodeSuccess: boolean, DecodedSettings: any = pcall(function(): (any)
			return HTTP:JSONDecode(NewSettings);
		end);

		if DecodeSuccess and (type(DecodedSettings) == 'table') and DecodedSettings.ServerPort then
			return DecodedSettings;
		end
	end

	return Settings;
end

function Connect.PostData(Data: string, ChunkSize: number, Host: string?, Port: string?, IsLIVE: boolean?): ()
	Host, Port = Host or DefaultHost, Port or DefaultPort;
	IsLIVE = IsLIVE or false;

	Settings = Connect.GetSettings(Host, Port);

	DefaultDataHeader = (Settings.DataHeader);
	DefaultLIVEHeader = (Settings.LIVEHeader);
	DefaultChunkSize = (Settings.ExportFromRSDataChunkSize);
	
	ChunkSize = ChunkSize or DefaultChunkSize;
	
	local GenericCallArguments: { [number]: any } = table.clone(PostGenericArguments);

	table.insert(GenericCallArguments, IsLIVE and table.merge(table.clone(DefaultDataHeader), DefaultLIVEHeader) or DefaultDataHeader);
	
	local Chunks: { [number]: string } = { };
	
	for i: number = 1, #Data, ChunkSize do
		table.insert(Chunks, string.sub(Data, i, (i + ChunkSize - 1)));
	end

	local ChunkAmount: number = #Chunks;
	local ChunkSizeInMB: number = (ChunkSize / 1024000);
	local TotalChunkSizeInMB: number = (ChunkSizeInMB * ChunkAmount);
	
	local Coroutine: thread;
	
	for i: number, Chunk: string in Chunks do
		task.wait();
		
		Coroutine = coroutine.create(function(): ()
			local ChunkData: {
				Chunk: string,
				Index: number,
				Total: number
			} = {
				Chunk = Chunk,
				Index = i,
				Total = ChunkAmount
			};
			
			GenericCallArguments[1] = HTTP:JSONEncode(ChunkData);
			
			local Success: boolean, Response: string? = pcall(function(): (string)
				return HTTP:PostAsync(`http://{Host}:{Port}`, table.unpack(GenericCallArguments));
			end);

			if Success then
				print(`Successfully sent {i} of {ChunkAmount} data-chunk{(ChunkAmount ~= 1) and 's' or ''}!{(Response ~= nil) and ` - {Response}`}`);
			else
				warn(`Error whilst trying to send {i} of {ChunkAmount} data-chunk{(ChunkAmount ~= 1) and 's' or ''}! - {Response}`);

				return;
			end
		end);
		coroutine.resume(Coroutine);
	end
	
	repeat task.wait() until (coroutine.status(Coroutine) == 'dead');
	
	print(`Sent a total of {TotalChunkSizeInMB}MB{(TotalChunkSizeInMB > 1) and 's' or ''} of data, each packet containing {ChunkSizeInMB}MBs.`);
end

function Connect.GetData(Host: string?, Port: string?): (T.DataRoot?)
	Host, Port = Host or DefaultHost, Port or DefaultPort;

	DefaultDataHeader = (Settings.DataHeader);
	
	local GenericCallArguments: { [number]: any } = table.clone(GetGenericArguments);
	
	table.insert(GenericCallArguments, DefaultDataHeader);
	
	local Success: boolean, Response: string? = pcall(function(): (string)
		return HTTP:GetAsync(`http://{Host}:{Port}`, table.unpack(GenericCallArguments));
	end);

	if Success then
		print(`[Silicon Connect] Successfully retrieved data payload from IDE server ({if Response then #Response else 0} bytes).`);
	else
		warn(`[Silicon Connect] Error whilst trying to retrieve data from IDE server! - {Response}`);
	end	

	return Response and HTTP:JSONDecode(Response) or { };
end



return Connect;