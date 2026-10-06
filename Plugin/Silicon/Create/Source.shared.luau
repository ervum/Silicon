--!strict

local Dependencies = require(script:FindFirstAncestorOfClass('Script').Create.GetDependencies);


local CHS: ChangeHistoryService = (Dependencies.Services.CHS);



return function(Toolbar: PluginToolbar, Title: string, Description: string, Icon: string, RecordName: string, CWVH: boolean, Method: (( ... any?) -> ( ... any?)), Arguments: { }?): ( ... any?)
	local ToolbarButton: PluginToolbarButton = Toolbar:CreateButton(Title, Description, Icon);

	ToolbarButton.ClickableWhenViewportHidden = CWVH; 

	local function ButtonMethod(): ()
		task.spawn(function(): ()
			if Arguments then
				Method(table.unpack(Arguments));
			else
				Method();
			end

			CHS:SetWaypoint(RecordName);
		end);
	end

	return ToolbarButton.Click:Connect(ButtonMethod);
end :: ((PluginToolbar, string, string, string, string, boolean, (( ... any?) -> ( ... any?)), { }?) -> ( ... any? ));