--!strict

local table: typeof(table) = table.clone(table);



local Dependencies = require(script:FindFirstAncestorOfClass('Script').Create.GetDependencies);


local RS: RunService = (Dependencies.Services.RS);



table = (Dependencies.Table);



---> TimeoutMode: true = Looping every Timeout seconds. false = Every iteration after Timeout seconds. nil = Only once after Timeout seconds.
return function(
	Method: ((... any) -> (... any)), 
	Await: number?, 
	SignalType: string?, 
	Arguments: { }?, 
	Timeout: number?,
	TimeoutMode: boolean?,
	TimeoutMethod: ((... any) -> (... any))?,
	TimeoutMethodArguments: { }?,
	WaitForTimeout: boolean?,
	TimeoutCondition: ((... any) -> (... any))?,
	TimeoutConditionArguments: { }?
): ((() -> (number, boolean, boolean, { }?, { }?)), RBXScriptConnection)
	Await = Await or 0.017;
	SignalType = SignalType or 'Heartbeat';
	WaitForTimeout = (WaitForTimeout ~= false);

	local Connection: RBXScriptConnection;

	local StartTime: number = os.clock();

	local HistoricalElapsed: number = 0.0;
	local TimeoutElapsed: number = 0.0;
	local Elapsed: number = 0.0;

	local ShouldDisconnect: boolean = false;

	local TimeoutTriedTriggering: boolean = false;
	local TimeoutTriggered: boolean = false;

	local ArgumentsForRunner: { [string?]: boolean } = { };

	local TimeoutRequested: any;
	local Requested: { [number]: any } = { };

	Connection = RS[SignalType]:Connect(function(DeltaTime: number): ()
		HistoricalElapsed += DeltaTime;
		TimeoutElapsed += DeltaTime;
		Elapsed += DeltaTime;

		if (TimeoutMode == nil) and (TimeoutTriedTriggering == true) then
			TimeoutElapsed = -1.0;
		end

		if (Elapsed >= Await) and not ArgumentsForRunner['{STOP UNTIL TIMEOUT}'] then
			Elapsed = 0.0;
			
			if Arguments then
				Requested = { Method(table.unpack(Arguments)) };
			else
				Requested = { Method() };
			end

			if next(Requested) and (typeof(Requested[1]) == 'table') and Requested[1]['{RETURNED ARGUMENTS}'] then
				ArgumentsForRunner = Requested[1];

				table.remove(Requested, 1);
			end
		end

		if Timeout and (TimeoutElapsed >= Timeout) then
			if (TimeoutMode == true) then
				TimeoutElapsed = 0.0;
			end

			if ArgumentsForRunner['{NO TIMEOUT}'] then
				ShouldDisconnect = true;
			else
				local ShouldTrigger: boolean = true;

				TimeoutTriedTriggering = true;

				if TimeoutCondition then	
					TimeoutConditionArguments = TimeoutConditionArguments and table.merge(TimeoutConditionArguments, Requested) or Requested or { };

					if not TimeoutCondition(table.unpack(TimeoutConditionArguments)) then
						ShouldTrigger = false;
					end
				end

				if ShouldTrigger then
					TimeoutTriggered = true;
					
					TimeoutMethodArguments = TimeoutMethodArguments and table.merge(TimeoutMethodArguments, Requested) or Requested or { };	
					TimeoutRequested = { TimeoutMethod(table.unpack(TimeoutMethodArguments)) };

					ShouldDisconnect = true;
				end
			end
		end

		if ShouldDisconnect and Connection and (Connection.Connected) then
			Connection:Disconnect();
			Connection = nil;
		end
	end);

	return function(): (number, boolean, boolean, { }?, { }?)
		if Timeout and WaitForTimeout then
			while true do
				if not Connection then
					return HistoricalElapsed, TimeoutTriggered, TimeoutTriedTriggering, Requested, TimeoutRequested;		
				end

				task.wait();
			end
		else
			return (os.clock() - StartTime), TimeoutTriggered, TimeoutTriedTriggering;
		end
	end, Connection;
end