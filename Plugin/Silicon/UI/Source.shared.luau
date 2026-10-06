--!strict

local StudioSettings: Studio = settings().Studio;



export type UIControllerCallbacks = {
	ToggleSynchronization: ((string) -> ()),
	Export:                (() -> ()),
	Import:                (() -> ()),
	CheckServer:           (() -> (boolean)),
	GetActiveMethod:       (() -> (string?)),
	GetVersion:            (() -> (string)),
};

export type UIController = {
	Widget:    DockWidgetPluginGui,
	ToggleUI:  (() -> ()),
	SetStatus: ((string, boolean, string?) -> ()),
	Log:       ((string) -> ()),
};



local function CreateUICorner(Radius: number, Parent: Instance): (UICorner)
	local Corner: UICorner = Instance.new('UICorner');
	Corner.CornerRadius = UDim.new(0, Radius);
	Corner.Parent = Parent;

	return Corner;
end

local function CreateUIStroke(Color: Color3, Thickness: number, Parent: Instance): (UIStroke)
	local Stroke: UIStroke = Instance.new('UIStroke');
	Stroke.Color = Color;
	Stroke.Thickness = Thickness;
	Stroke.ApplyStrokeMode = (Enum.ApplyStrokeMode.Border);
	Stroke.Parent = Parent;

	return Stroke;
end

local function CreateUIPadding(Top: number, Bottom: number, Left: number, Right: number, Parent: Instance): (UIPadding)
	local Padding: UIPadding = Instance.new('UIPadding');
	Padding.PaddingTop = UDim.new(0, Top);
	Padding.PaddingBottom = UDim.new(0, Bottom);
	Padding.PaddingLeft = UDim.new(0, Left);
	Padding.PaddingRight = UDim.new(0, Right);
	Padding.Parent = Parent;

	return Padding;
end



return function(PluginInstance: Plugin, Callbacks: UIControllerCallbacks): (UIController)
	local WidgetInfo: DockWidgetPluginGuiInfo = DockWidgetPluginGuiInfo.new(
		(Enum.InitialDockState.Float),
		false,
		false,
		360,
		560,
		300,
		420
	);

	local Widget: DockWidgetPluginGui = PluginInstance:CreateDockWidgetPluginGui('SiliconSynchronizationWidget', WidgetInfo);
	Widget.Title = 'Silicon';
	Widget.ZIndexBehavior = (Enum.ZIndexBehavior.Sibling);

	local Theme: StudioTheme = (StudioSettings.Theme);

	local RootContainer: Frame = Instance.new('Frame');
	RootContainer.Name = 'RootContainer';
	RootContainer.Size = UDim2.fromScale(1.0, 1.0);
	RootContainer.BackgroundColor3 = Theme:GetColor(Enum.StudioStyleGuideColor.MainBackground);
	RootContainer.BorderSizePixel = 0;
	RootContainer.Parent = Widget;

	local ScrollContainer: ScrollingFrame = Instance.new('ScrollingFrame');
	ScrollContainer.Name = 'ScrollContainer';
	ScrollContainer.Size = UDim2.fromScale(1.0, 1.0);
	ScrollContainer.BackgroundColor3 = Theme:GetColor(Enum.StudioStyleGuideColor.MainBackground);
	ScrollContainer.BackgroundTransparency = 1.0;
	ScrollContainer.BorderSizePixel = 0;
	ScrollContainer.ScrollBarThickness = 6;
	ScrollContainer.ScrollBarImageColor3 = Theme:GetColor(Enum.StudioStyleGuideColor.ScrollBar);
	ScrollContainer.CanvasSize = UDim2.fromScale(0.0, 0.0);
	ScrollContainer.AutomaticCanvasSize = (Enum.AutomaticSize.Y);
	ScrollContainer.Parent = RootContainer;

	CreateUIPadding(12, 16, 12, 12, ScrollContainer);

	local ListLayout: UIListLayout = Instance.new('UIListLayout');
	ListLayout.SortOrder = (Enum.SortOrder.LayoutOrder);
	ListLayout.Padding = UDim.new(0, 10);
	ListLayout.HorizontalAlignment = (Enum.HorizontalAlignment.Center);
	ListLayout.Parent = ScrollContainer;

	local ThemeObjects: { [number?]: { Instance: Instance, Property: string, ColorType: Enum.StudioStyleGuideColor } } = { };

	local function RegisterThemeColor(Object: Instance, PropertyName: string, ColorType: Enum.StudioStyleGuideColor): ()
		table.insert(ThemeObjects, {
			Instance  = Object,
			Property  = PropertyName,
			ColorType = ColorType,
		});

		(Object :: any)[PropertyName] = Theme:GetColor(ColorType);

		return;
	end

	local HeaderCard: Frame = Instance.new('Frame');
	HeaderCard.Name = 'HeaderCard';
	HeaderCard.Size = UDim2.new(1.0, 0, 0, 68);
	HeaderCard.LayoutOrder = 1;
	HeaderCard.BackgroundColor3 = Theme:GetColor(Enum.StudioStyleGuideColor.SubBackground);
	HeaderCard.BorderSizePixel = 0;
	HeaderCard.Parent = ScrollContainer;

	CreateUICorner(8, HeaderCard);
	local HeaderStroke: UIStroke = CreateUIStroke(Theme:GetColor(Enum.StudioStyleGuideColor.Border), 1, HeaderCard);
	CreateUIPadding(8, 8, 12, 12, HeaderCard);

	RegisterThemeColor(HeaderCard, 'BackgroundColor3', (Enum.StudioStyleGuideColor.SubBackground));
	RegisterThemeColor(HeaderStroke, 'Color', (Enum.StudioStyleGuideColor.Border));

	local LogoImage: ImageLabel = Instance.new('ImageLabel');
	LogoImage.Name = 'LogoImage';
	LogoImage.Size = UDim2.fromOffset(36, 36);
	LogoImage.Position = UDim2.new(0, 0, 0.5, -18);
	LogoImage.BackgroundTransparency = 1.0;
	LogoImage.Image = 'rbxasset://textures/Silicon/live.png';
	LogoImage.ScaleType = (Enum.ScaleType.Fit);
	LogoImage.Parent = HeaderCard;

	local TitleLabel: TextLabel = Instance.new('TextLabel');
	TitleLabel.Name = 'TitleLabel';
	TitleLabel.Size = UDim2.new(1.0, -160, 0, 22);
	TitleLabel.Position = UDim2.fromOffset(46, 6);
	TitleLabel.BackgroundTransparency = 1.0;
	TitleLabel.Text = 'SILICON';
	TitleLabel.TextColor3 = Theme:GetColor(Enum.StudioStyleGuideColor.MainText);
	TitleLabel.TextXAlignment = (Enum.TextXAlignment.Left);
	TitleLabel.Font = (Enum.Font.GothamBold);
	TitleLabel.TextSize = 16;
	TitleLabel.Parent = HeaderCard;

	RegisterThemeColor(TitleLabel, 'TextColor3', (Enum.StudioStyleGuideColor.MainText));

	local SubtitleLabel: TextLabel = Instance.new('TextLabel');
	SubtitleLabel.Name = 'SubtitleLabel';
	SubtitleLabel.Size = UDim2.new(1.0, -160, 0, 16);
	SubtitleLabel.Position = UDim2.fromOffset(46, 28);
	SubtitleLabel.BackgroundTransparency = 1.0;
	local VersionString: string = Callbacks.GetVersion();
	SubtitleLabel.Text = `Roblox Studio Daemon v{VersionString}`;
	SubtitleLabel.TextColor3 = Theme:GetColor(Enum.StudioStyleGuideColor.SubText);
	SubtitleLabel.TextXAlignment = (Enum.TextXAlignment.Left);
	SubtitleLabel.Font = (Enum.Font.Gotham);
	SubtitleLabel.TextSize = 11;
	SubtitleLabel.Parent = HeaderCard;

	RegisterThemeColor(SubtitleLabel, 'TextColor3', (Enum.StudioStyleGuideColor.SubText));

	local StatusBadge: Frame = Instance.new('Frame');
	StatusBadge.Name = 'StatusBadge';
	StatusBadge.Size = UDim2.fromOffset(116, 28);
	StatusBadge.Position = UDim2.new(1.0, -116, 0.5, -14);
	StatusBadge.BackgroundColor3 = Color3.fromRGB(42, 46, 54);
	StatusBadge.BorderSizePixel = 0;
	StatusBadge.Parent = HeaderCard;

	CreateUICorner(14, StatusBadge);
	local StatusBadgeStroke: UIStroke = CreateUIStroke(Color3.fromRGB(60, 66, 78), 1, StatusBadge);

	local StatusDot: Frame = Instance.new('Frame');
	StatusDot.Name = 'StatusDot';
	StatusDot.Size = UDim2.fromOffset(8, 8);
	StatusDot.Position = UDim2.fromOffset(10, 10);
	StatusDot.BackgroundColor3 = Color3.fromRGB(150, 150, 160);
	StatusDot.BorderSizePixel = 0;
	StatusDot.Parent = StatusBadge;

	CreateUICorner(4, StatusDot);

	local StatusTextLabel: TextLabel = Instance.new('TextLabel');
	StatusTextLabel.Name = 'StatusTextLabel';
	StatusTextLabel.Size = UDim2.new(1.0, -26, 1.0, 0);
	StatusTextLabel.Position = UDim2.fromOffset(22, 0);
	StatusTextLabel.BackgroundTransparency = 1.0;
	StatusTextLabel.Text = 'OFFLINE';
	StatusTextLabel.TextColor3 = Color3.fromRGB(180, 185, 195);
	StatusTextLabel.TextXAlignment = (Enum.TextXAlignment.Left);
	StatusTextLabel.Font = (Enum.Font.GothamBold);
	StatusTextLabel.TextSize = 11;
	StatusTextLabel.Parent = StatusBadge;

	local ConnectionCard: Frame = Instance.new('Frame');
	ConnectionCard.Name = 'ConnectionCard';
	ConnectionCard.Size = UDim2.new(1.0, 0, 0, 44);
	ConnectionCard.LayoutOrder = 2;
	ConnectionCard.BackgroundColor3 = Theme:GetColor(Enum.StudioStyleGuideColor.SubBackground);
	ConnectionCard.BorderSizePixel = 0;
	ConnectionCard.Parent = ScrollContainer;

	CreateUICorner(6, ConnectionCard);
	local ConnectionStroke: UIStroke = CreateUIStroke(Theme:GetColor(Enum.StudioStyleGuideColor.Border), 1, ConnectionCard);
	CreateUIPadding(6, 6, 10, 10, ConnectionCard);

	RegisterThemeColor(ConnectionCard, 'BackgroundColor3', (Enum.StudioStyleGuideColor.SubBackground));
	RegisterThemeColor(ConnectionStroke, 'Color', (Enum.StudioStyleGuideColor.Border));

	local HostLabel: TextLabel = Instance.new('TextLabel');
	HostLabel.Name = 'HostLabel';
	HostLabel.Size = UDim2.new(1.0, -90, 1.0, 0);
	HostLabel.Position = UDim2.fromOffset(0, 0);
	HostLabel.BackgroundTransparency = 1.0;
	HostLabel.Text = 'Server: http://localhost:6969';
	HostLabel.TextColor3 = Theme:GetColor(Enum.StudioStyleGuideColor.MainText);
	HostLabel.TextXAlignment = (Enum.TextXAlignment.Left);
	HostLabel.Font = (Enum.Font.RobotoMono or Enum.Font.Code);
	HostLabel.TextSize = 11;
	HostLabel.Parent = ConnectionCard;

	RegisterThemeColor(HostLabel, 'TextColor3', (Enum.StudioStyleGuideColor.MainText));

	local PingButton: TextButton = Instance.new('TextButton');
	PingButton.Name = 'PingButton';
	PingButton.Size = UDim2.fromOffset(80, 28);
	PingButton.Position = UDim2.new(1.0, -80, 0.5, -14);
	PingButton.BackgroundColor3 = Theme:GetColor(Enum.StudioStyleGuideColor.Button);
	PingButton.BorderSizePixel = 0;
	PingButton.Text = 'Check';
	PingButton.TextColor3 = Theme:GetColor(Enum.StudioStyleGuideColor.ButtonText);
	PingButton.Font = (Enum.Font.GothamMedium);
	PingButton.TextSize = 11;
	PingButton.Parent = ConnectionCard;

	CreateUICorner(4, PingButton);
	RegisterThemeColor(PingButton, 'BackgroundColor3', (Enum.StudioStyleGuideColor.Button));
	RegisterThemeColor(PingButton, 'TextColor3', (Enum.StudioStyleGuideColor.ButtonText));

	local function CreateSectionLabel(Title: string, Order: number): (TextLabel)
		local Label: TextLabel = Instance.new('TextLabel');
		Label.Name = `{Title}Label`;
		Label.Size = UDim2.new(1.0, 0, 0, 20);
		Label.LayoutOrder = Order;
		Label.BackgroundTransparency = 1.0;
		Label.Text = Title;
		Label.TextColor3 = Theme:GetColor(Enum.StudioStyleGuideColor.SubText);
		Label.TextXAlignment = (Enum.TextXAlignment.Left);
		Label.Font = (Enum.Font.GothamBold);
		Label.TextSize = 11;
		Label.Parent = ScrollContainer;

		RegisterThemeColor(Label, 'TextColor3', (Enum.StudioStyleGuideColor.SubText));

		return Label;
	end

	CreateSectionLabel('LIVE SYNCHRONIZATION', 3);

	local LivePrimaryCard: TextButton = Instance.new('TextButton');
	LivePrimaryCard.Name = 'LivePrimaryCard';
	LivePrimaryCard.Size = UDim2.new(1.0, 0, 0, 56);
	LivePrimaryCard.LayoutOrder = 4;
	LivePrimaryCard.BackgroundColor3 = Color3.fromRGB(0, 140, 90);
	LivePrimaryCard.BorderSizePixel = 0;
	LivePrimaryCard.AutoButtonColor = true;
	LivePrimaryCard.Text = '';
	LivePrimaryCard.Parent = ScrollContainer;

	CreateUICorner(8, LivePrimaryCard);
	local LivePrimaryStroke: UIStroke = CreateUIStroke(Color3.fromRGB(0, 180, 115), 1.5, LivePrimaryCard);
	CreateUIPadding(6, 6, 12, 12, LivePrimaryCard);

	local LiveIcon: ImageLabel = Instance.new('ImageLabel');
	LiveIcon.Name = 'LiveIcon';
	LiveIcon.Size = UDim2.fromOffset(30, 30);
	LiveIcon.Position = UDim2.new(0, 0, 0.5, -15);
	LiveIcon.BackgroundTransparency = 1.0;
	LiveIcon.Image = 'rbxasset://textures/Silicon/live.png';
	LiveIcon.ScaleType = (Enum.ScaleType.Fit);
	LiveIcon.Parent = LivePrimaryCard;

	local LiveTitle: TextLabel = Instance.new('TextLabel');
	LiveTitle.Name = 'LiveTitle';
	LiveTitle.Size = UDim2.new(1.0, -42, 0, 20);
	LiveTitle.Position = UDim2.fromOffset(40, 3);
	LiveTitle.BackgroundTransparency = 1.0;
	LiveTitle.Text = 'Bidirectional (Two-Way Live Sync)';
	LiveTitle.TextColor3 = Color3.fromRGB(255, 255, 255);
	LiveTitle.TextXAlignment = (Enum.TextXAlignment.Left);
	LiveTitle.Font = (Enum.Font.GothamBold);
	LiveTitle.TextSize = 13;
	LiveTitle.Parent = LivePrimaryCard;

	local LiveSub: TextLabel = Instance.new('TextLabel');
	LiveSub.Name = 'LiveSub';
	LiveSub.Size = UDim2.new(1.0, -42, 0, 16);
	LiveSub.Position = UDim2.fromOffset(40, 24);
	LiveSub.BackgroundTransparency = 1.0;
	LiveSub.Text = 'Instant reactive sync of scripts and properties';
	LiveSub.TextColor3 = Color3.fromRGB(215, 245, 230);
	LiveSub.TextXAlignment = (Enum.TextXAlignment.Left);
	LiveSub.Font = (Enum.Font.Gotham);
	LiveSub.TextSize = 11;
	LiveSub.Parent = LivePrimaryCard;

	local SecondaryGrid: Frame = Instance.new('Frame');
	SecondaryGrid.Name = 'SecondaryGrid';
	SecondaryGrid.Size = UDim2.new(1.0, 0, 0, 84);
	SecondaryGrid.LayoutOrder = 5;
	SecondaryGrid.BackgroundTransparency = 1.0;
	SecondaryGrid.Parent = ScrollContainer;

	local GridLayout: UIGridLayout = Instance.new('UIGridLayout');
	GridLayout.CellPadding = UDim2.fromOffset(8, 8);
	GridLayout.CellSize = UDim2.new(0.5, -4, 0, 38);
	GridLayout.SortOrder = (Enum.SortOrder.LayoutOrder);
	GridLayout.Parent = SecondaryGrid;

	local ActiveButtons: { [string]: TextButton } = { };

	local function CreateModeButton(Name: string, DisplayText: string, IconAsset: string, MethodName: string, Order: number): (TextButton)
		local Button: TextButton = Instance.new('TextButton');
		Button.Name = Name;
		Button.LayoutOrder = Order;
		Button.BackgroundColor3 = Theme:GetColor(Enum.StudioStyleGuideColor.Button);
		Button.BorderSizePixel = 0;
		Button.AutoButtonColor = true;
		Button.Text = '';
		Button.Parent = SecondaryGrid;

		CreateUICorner(6, Button);
		local Stroke: UIStroke = CreateUIStroke(Theme:GetColor(Enum.StudioStyleGuideColor.Border), 1, Button);
		CreateUIPadding(4, 4, 8, 8, Button);

		RegisterThemeColor(Button, 'BackgroundColor3', (Enum.StudioStyleGuideColor.Button));
		RegisterThemeColor(Stroke, 'Color', (Enum.StudioStyleGuideColor.Border));

		local ButtonIcon: ImageLabel = Instance.new('ImageLabel');
		ButtonIcon.Name = 'ButtonIcon';
		ButtonIcon.Size = UDim2.fromOffset(20, 20);
		ButtonIcon.Position = UDim2.new(0, 0, 0.5, -10);
		ButtonIcon.BackgroundTransparency = 1.0;
		ButtonIcon.Image = IconAsset;
		ButtonIcon.ScaleType = (Enum.ScaleType.Fit);
		ButtonIcon.Parent = Button;

		local ButtonText: TextLabel = Instance.new('TextLabel');
		ButtonText.Name = 'ButtonText';
		ButtonText.Size = UDim2.new(1.0, -28, 1.0, 0);
		ButtonText.Position = UDim2.fromOffset(26, 0);
		ButtonText.BackgroundTransparency = 1.0;
		ButtonText.Text = DisplayText;
		ButtonText.TextColor3 = Theme:GetColor(Enum.StudioStyleGuideColor.MainText);
		ButtonText.TextXAlignment = (Enum.TextXAlignment.Left);
		ButtonText.Font = (Enum.Font.GothamMedium);
		ButtonText.TextSize = 11;
		ButtonText.TextTruncate = (Enum.TextTruncate.AtEnd);
		ButtonText.Parent = Button;

		RegisterThemeColor(ButtonText, 'TextColor3', (Enum.StudioStyleGuideColor.MainText));

		ActiveButtons[MethodName] = Button;

		Button.MouseButton1Click:Connect(function(): ()
			Callbacks.ToggleSynchronization(MethodName);
		end);

		return Button;
	end

	CreateModeButton('FromStudioButton', 'From Studio', 'rbxasset://textures/Silicon/upload.png', 'BidirectionalFromRoblox', 1);
	CreateModeButton('FromIDEButton', 'From IDE', 'rbxasset://textures/Silicon/download.png', 'BidirectionalFromIDE', 2);
	CreateModeButton('AllDescendantsButton', 'All Descendants', 'rbxasset://textures/Silicon/arrow.png', 'AllDescendants', 3);
	CreateModeButton('StreamToIDEButton', 'Studio -> IDE Live', 'rbxasset://textures/Silicon/upload.png', 'Export', 4);

	local StopButton: TextButton = Instance.new('TextButton');
	StopButton.Name = 'StopButton';
	StopButton.Size = UDim2.new(1.0, 0, 0, 36);
	StopButton.LayoutOrder = 6;
	StopButton.BackgroundColor3 = Color3.fromRGB(180, 40, 40);
	StopButton.BorderSizePixel = 0;
	StopButton.Visible = false;
	StopButton.Text = '■ STOP SYNCHRONIZATION';
	StopButton.TextColor3 = Color3.fromRGB(255, 255, 255);
	StopButton.Font = (Enum.Font.GothamBold);
	StopButton.TextSize = 12;
	StopButton.Parent = ScrollContainer;

	CreateUICorner(6, StopButton);
	CreateUIStroke(Color3.fromRGB(220, 60, 60), 1, StopButton);

	StopButton.MouseButton1Click:Connect(function(): ()
		local CurrentActive: string? = Callbacks.GetActiveMethod();
		if CurrentActive then
			Callbacks.ToggleSynchronization(CurrentActive);
		end
	end);

	CreateSectionLabel('ONE-SHOT ACTIONS', 7);

	local OneShotRow: Frame = Instance.new('Frame');
	OneShotRow.Name = 'OneShotRow';
	OneShotRow.Size = UDim2.new(1.0, 0, 0, 42);
	OneShotRow.LayoutOrder = 8;
	OneShotRow.BackgroundTransparency = 1.0;
	OneShotRow.Parent = ScrollContainer;

	local OneShotLayout: UIListLayout = Instance.new('UIListLayout');
	OneShotLayout.FillDirection = (Enum.FillDirection.Horizontal);
	OneShotLayout.Padding = UDim.new(0, 8);
	OneShotLayout.SortOrder = (Enum.SortOrder.LayoutOrder);
	OneShotLayout.Parent = OneShotRow;

	local function CreateOneShotButton(Name: string, Title: string, IconAsset: string, OnClick: (() -> ()), Order: number): (TextButton)
		local Button: TextButton = Instance.new('TextButton');
		Button.Name = Name;
		Button.Size = UDim2.new(0.5, -4, 1.0, 0);
		Button.LayoutOrder = Order;
		Button.BackgroundColor3 = Theme:GetColor(Enum.StudioStyleGuideColor.Button);
		Button.BorderSizePixel = 0;
		Button.AutoButtonColor = true;
		Button.Text = '';
		Button.Parent = OneShotRow;

		CreateUICorner(6, Button);
		local Stroke: UIStroke = CreateUIStroke(Theme:GetColor(Enum.StudioStyleGuideColor.Border), 1, Button);
		CreateUIPadding(4, 4, 10, 10, Button);

		RegisterThemeColor(Button, 'BackgroundColor3', (Enum.StudioStyleGuideColor.Button));
		RegisterThemeColor(Stroke, 'Color', (Enum.StudioStyleGuideColor.Border));

		local Icon: ImageLabel = Instance.new('ImageLabel');
		Icon.Name = 'Icon';
		Icon.Size = UDim2.fromOffset(20, 20);
		Icon.Position = UDim2.new(0, 0, 0.5, -10);
		Icon.BackgroundTransparency = 1.0;
		Icon.Image = IconAsset;
		Icon.ScaleType = (Enum.ScaleType.Fit);
		Icon.Parent = Button;

		local Label: TextLabel = Instance.new('TextLabel');
		Label.Name = 'Label';
		Label.Size = UDim2.new(1.0, -28, 1.0, 0);
		Label.Position = UDim2.fromOffset(26, 0);
		Label.BackgroundTransparency = 1.0;
		Label.Text = Title;
		Label.TextColor3 = Theme:GetColor(Enum.StudioStyleGuideColor.MainText);
		Label.TextXAlignment = (Enum.TextXAlignment.Left);
		Label.Font = (Enum.Font.GothamMedium);
		Label.TextSize = 11;
		Label.Parent = Button;

		RegisterThemeColor(Label, 'TextColor3', (Enum.StudioStyleGuideColor.MainText));

		Button.MouseButton1Click:Connect(OnClick);

		return Button;
	end

	CreateOneShotButton('ExportButton', 'Export to IDE', 'rbxasset://textures/Silicon/upload.png', function(): ()
		Callbacks.Export();
	end, 1);

	CreateOneShotButton('ImportButton', 'Import to Studio', 'rbxasset://textures/Silicon/download.png', function(): ()
		Callbacks.Import();
	end, 2);

	CreateSectionLabel('ACTIVITY LOG', 9);

	local LogCard: Frame = Instance.new('Frame');
	LogCard.Name = 'LogCard';
	LogCard.Size = UDim2.new(1.0, 0, 0, 96);
	LogCard.LayoutOrder = 10;
	LogCard.BackgroundColor3 = Theme:GetColor(Enum.StudioStyleGuideColor.SubBackground);
	LogCard.BorderSizePixel = 0;
	LogCard.Parent = ScrollContainer;

	CreateUICorner(6, LogCard);
	local LogStroke: UIStroke = CreateUIStroke(Theme:GetColor(Enum.StudioStyleGuideColor.Border), 1, LogCard);
	CreateUIPadding(6, 6, 8, 8, LogCard);

	RegisterThemeColor(LogCard, 'BackgroundColor3', (Enum.StudioStyleGuideColor.SubBackground));
	RegisterThemeColor(LogStroke, 'Color', (Enum.StudioStyleGuideColor.Border));

	local LogTextLabel: TextLabel = Instance.new('TextLabel');
	LogTextLabel.Name = 'LogTextLabel';
	LogTextLabel.Size = UDim2.fromScale(1.0, 1.0);
	LogTextLabel.BackgroundTransparency = 1.0;
	LogTextLabel.Text = 'Ready. Click a button to begin.';
	LogTextLabel.TextColor3 = Theme:GetColor(Enum.StudioStyleGuideColor.SubText);
	LogTextLabel.TextXAlignment = (Enum.TextXAlignment.Left);
	LogTextLabel.TextYAlignment = (Enum.TextYAlignment.Top);
	LogTextLabel.Font = (Enum.Font.RobotoMono or Enum.Font.Code);
	LogTextLabel.TextSize = 10;
	LogTextLabel.TextWrapped = true;
	LogTextLabel.Parent = LogCard;

	RegisterThemeColor(LogTextLabel, 'TextColor3', (Enum.StudioStyleGuideColor.SubText));

	local RecentLogs: { [number?]: string } = { };

	local function AppendLog(Message: string): ()
		local TimeString: string = os.date('%X');
		local Formatted: string = `[{TimeString}] {Message}`;
		table.insert(RecentLogs, Formatted);

		if (#RecentLogs > 5) then
			table.remove(RecentLogs, 1);
		end

		LogTextLabel.Text = table.concat(RecentLogs, '\n');

		return;
	end

	local function UpdateStatusUI(StatusText: string, IsConnected: boolean, ActiveMethodName: string?): ()
		if ActiveMethodName then
			StatusBadge.BackgroundColor3 = Color3.fromRGB(15, 60, 35);
			StatusBadgeStroke.Color = Color3.fromRGB(0, 190, 110);
			StatusDot.BackgroundColor3 = Color3.fromRGB(0, 230, 130);
			StatusTextLabel.TextColor3 = Color3.fromRGB(0, 230, 130);
			StatusTextLabel.Text = 'LIVE SYNC';
			StopButton.Visible = true;
			LivePrimaryCard.BackgroundColor3 = (ActiveMethodName == 'Bidirectional') and Color3.fromRGB(0, 170, 105) or Color3.fromRGB(45, 52, 64);
			LivePrimaryStroke.Color = (ActiveMethodName == 'Bidirectional') and Color3.fromRGB(0, 230, 130) or Color3.fromRGB(70, 78, 92);

			for MethodKey: string, ButtonInstance: TextButton in ActiveButtons do
				local IsThisActive: boolean = (MethodKey == ActiveMethodName);
				ButtonInstance.BackgroundColor3 = IsThisActive and Color3.fromRGB(0, 140, 90) or Theme:GetColor(Enum.StudioStyleGuideColor.Button);
			end

		elseif IsConnected then
			StatusBadge.BackgroundColor3 = Color3.fromRGB(20, 45, 65);
			StatusBadgeStroke.Color = Color3.fromRGB(30, 130, 210);
			StatusDot.BackgroundColor3 = Color3.fromRGB(40, 160, 255);
			StatusTextLabel.TextColor3 = Color3.fromRGB(100, 190, 255);
			StatusTextLabel.Text = 'CONNECTED';
			StopButton.Visible = false;
			LivePrimaryCard.BackgroundColor3 = Color3.fromRGB(0, 140, 90);
			LivePrimaryStroke.Color = Color3.fromRGB(0, 180, 115);

			for _: string, ButtonInstance: TextButton in ActiveButtons do
				ButtonInstance.BackgroundColor3 = Theme:GetColor(Enum.StudioStyleGuideColor.Button);
			end

		else
			StatusBadge.BackgroundColor3 = Color3.fromRGB(42, 46, 54);
			StatusBadgeStroke.Color = Color3.fromRGB(60, 66, 78);
			StatusDot.BackgroundColor3 = Color3.fromRGB(150, 150, 160);
			StatusTextLabel.TextColor3 = Color3.fromRGB(180, 185, 195);
			StatusTextLabel.Text = 'OFFLINE';
			StopButton.Visible = false;
			LivePrimaryCard.BackgroundColor3 = Color3.fromRGB(0, 140, 90);
			LivePrimaryStroke.Color = Color3.fromRGB(0, 180, 115);

			for _: string, ButtonInstance: TextButton in ActiveButtons do
				ButtonInstance.BackgroundColor3 = Theme:GetColor(Enum.StudioStyleGuideColor.Button);
			end
		end

		return;
	end

	LivePrimaryCard.MouseButton1Click:Connect(function(): ()
		Callbacks.ToggleSynchronization('Bidirectional');
	end);

	PingButton.MouseButton1Click:Connect(function(): ()
		PingButton.Text = '...';
		task.spawn(function(): ()
			local Alive: boolean = Callbacks.CheckServer();
			PingButton.Text = Alive and 'Alive!' or 'Offline';
			UpdateStatusUI(Alive and 'Connected' or 'Offline', Alive, Callbacks.GetActiveMethod());
			AppendLog(Alive and 'Server daemon responsive at localhost:6969' or 'Cannot reach server daemon at localhost:6969');
			task.wait(2.0);
			PingButton.Text = 'Check';
		end);
	end);

	StudioSettings.ThemeChanged:Connect(function(): ()
		Theme = (StudioSettings.Theme);
		RootContainer.BackgroundColor3 = Theme:GetColor(Enum.StudioStyleGuideColor.MainBackground);

		for _: number, ThemeEntry in ThemeObjects do
			(ThemeEntry.Instance :: any)[ThemeEntry.Property] = Theme:GetColor(ThemeEntry.ColorType);
		end

		UpdateStatusUI('Updated', Callbacks.CheckServer(), Callbacks.GetActiveMethod());

		return;
	end);

	local function ToggleUI(): ()
		Widget.Enabled = not (Widget.Enabled);

		return;
	end

	local Controller: UIController = {
		Widget    = Widget,
		ToggleUI  = ToggleUI,
		SetStatus = UpdateStatusUI,
		Log       = AppendLog,
	};

	return Controller;
end
