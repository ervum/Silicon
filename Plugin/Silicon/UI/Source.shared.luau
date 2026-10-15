--!strict

local StudioSettings: Studio = settings().Studio;



export type UIControllerCallbacks = {
	ToggleSynchronization: ((string) -> ()),
	Export:                (() -> ()),
	Import:                (() -> ()),
	CheckServer:           (() -> (boolean)),
	GetActiveMethod:       (() -> (string?)),
	GetVersion:            (() -> (string)),
	GetAllDescendants:     (() -> (boolean)),
	SetAllDescendants:     ((boolean) -> ()),
	GetInitialFromRS:      (() -> (boolean)),
	SetInitialFromRS:      ((boolean) -> ()),
	GetShowRibbonTab:      (() -> (boolean)),
	SetShowRibbonTab:      ((boolean) -> ()),
	GetConflictMode:       (() -> (string)),
	SetConflictMode:       ((string) -> ()),
	ClearProject:          (() -> ()),
};

export type UIController = {
	Widget:        DockWidgetPluginGui,
	RootContainer: Frame,
	ToggleUI:      (() -> ()),
	SetStatus:     ((string, boolean, string?) -> ()),
	Log:           ((string) -> ()),
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
		true,
		360,
		680,
		300,
		480
	);

	local Widget: DockWidgetPluginGui = PluginInstance:CreateDockWidgetPluginGui('SiliconSynchronizationWidget', WidgetInfo);
	Widget.Title = 'Silicon';
	Widget.ZIndexBehavior = (Enum.ZIndexBehavior.Sibling);

	for _: number, ChildInstance: Instance in (Widget:GetChildren()) do
		ChildInstance:Destroy();
	end

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
	ListLayout.Padding = UDim.new(0, 8);
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
	HeaderCard.Size = UDim2.new(1.0, 0, 0, 64);
	HeaderCard.LayoutOrder = 1;
	HeaderCard.BackgroundColor3 = Theme:GetColor(Enum.StudioStyleGuideColor.InputFieldBackground);
	HeaderCard.BorderSizePixel = 0;
	HeaderCard.Parent = ScrollContainer;

	CreateUICorner(8, HeaderCard);
	local HeaderStroke: UIStroke = CreateUIStroke(Theme:GetColor(Enum.StudioStyleGuideColor.Border), 1, HeaderCard);
	CreateUIPadding(8, 8, 12, 12, HeaderCard);

	RegisterThemeColor(HeaderCard, 'BackgroundColor3', (Enum.StudioStyleGuideColor.InputFieldBackground));
	RegisterThemeColor(HeaderStroke, 'Color', (Enum.StudioStyleGuideColor.Border));

	local LogoImage: ImageLabel = Instance.new('ImageLabel');
	LogoImage.Name = 'LogoImage';
	LogoImage.Size = UDim2.fromOffset(36, 36);
	LogoImage.Position = UDim2.new(0, 0, 0.5, -18);
	LogoImage.BackgroundTransparency = 1.0;
	LogoImage.Image = 'rbxassetid://78911552761219';
	LogoImage.ScaleType = (Enum.ScaleType.Fit);
	LogoImage.Parent = HeaderCard;

	local TitleLabel: TextLabel = Instance.new('TextLabel');
	TitleLabel.Name = 'TitleLabel';
	TitleLabel.Size = UDim2.new(1.0, -160, 0, 22);
	TitleLabel.Position = UDim2.fromOffset(46, 4);
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
	SubtitleLabel.Position = UDim2.fromOffset(46, 26);
	SubtitleLabel.BackgroundTransparency = 1.0;
	local VersionString: string = Callbacks.GetVersion();
	SubtitleLabel.Text = `Roblox RS Daemon v{VersionString}`;
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
	ConnectionCard.Size = UDim2.new(1.0, 0, 0, 40);
	ConnectionCard.LayoutOrder = 2;
	ConnectionCard.BackgroundColor3 = Theme:GetColor(Enum.StudioStyleGuideColor.InputFieldBackground);
	ConnectionCard.BorderSizePixel = 0;
	ConnectionCard.Parent = ScrollContainer;

	CreateUICorner(6, ConnectionCard);
	local ConnectionStroke: UIStroke = CreateUIStroke(Theme:GetColor(Enum.StudioStyleGuideColor.Border), 1, ConnectionCard);
	CreateUIPadding(6, 6, 10, 10, ConnectionCard);

	RegisterThemeColor(ConnectionCard, 'BackgroundColor3', (Enum.StudioStyleGuideColor.InputFieldBackground));
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
	PingButton.Size = UDim2.fromOffset(80, 26);
	PingButton.Position = UDim2.new(1.0, -80, 0.5, -13);
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
		Label.Size = UDim2.new(1.0, 0, 0, 18);
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

	CreateSectionLabel('SYNCHRONIZATION OPTIONS', 3);

	local function CreateToggleRow(
		Name: string,
		TitleText: string,
		GetDescription: ((boolean) -> (string)),
		InitialValue: boolean,
		OnToggle: ((boolean) -> ()),
		Order: number
	): (() -> ())
		local CurrentState: boolean = InitialValue;

		local RowCard: TextButton = Instance.new('TextButton');
		RowCard.Name = Name;
		RowCard.Size = UDim2.new(1.0, 0, 0, 48);
		RowCard.LayoutOrder = Order;
		RowCard.BackgroundColor3 = Theme:GetColor(Enum.StudioStyleGuideColor.InputFieldBackground);
		RowCard.BorderSizePixel = 0;
		RowCard.AutoButtonColor = true;
		RowCard.Text = '';
		RowCard.Parent = ScrollContainer;

		CreateUICorner(6, RowCard);
		local RowStroke: UIStroke = CreateUIStroke(Theme:GetColor(Enum.StudioStyleGuideColor.Border), 1, RowCard);
		CreateUIPadding(6, 6, 10, 10, RowCard);

		RegisterThemeColor(RowCard, 'BackgroundColor3', (Enum.StudioStyleGuideColor.InputFieldBackground));
		RegisterThemeColor(RowStroke, 'Color', (Enum.StudioStyleGuideColor.Border));

		local RowTitle: TextLabel = Instance.new('TextLabel');
		RowTitle.Name = 'RowTitle';
		RowTitle.Size = UDim2.new(1.0, -70, 0, 18);
		RowTitle.Position = UDim2.fromOffset(0, 1);
		RowTitle.BackgroundTransparency = 1.0;
		RowTitle.Text = TitleText;
		RowTitle.TextColor3 = Theme:GetColor(Enum.StudioStyleGuideColor.MainText);
		RowTitle.TextXAlignment = (Enum.TextXAlignment.Left);
		RowTitle.Font = (Enum.Font.GothamBold);
		RowTitle.TextSize = 12;
		RowTitle.Parent = RowCard;

		RegisterThemeColor(RowTitle, 'TextColor3', (Enum.StudioStyleGuideColor.MainText));

		local RowSub: TextLabel = Instance.new('TextLabel');
		RowSub.Name = 'RowSub';
		RowSub.Size = UDim2.new(1.0, -70, 0, 16);
		RowSub.Position = UDim2.fromOffset(0, 19);
		RowSub.BackgroundTransparency = 1.0;
		RowSub.Text = GetDescription(CurrentState);
		RowSub.TextColor3 = Theme:GetColor(Enum.StudioStyleGuideColor.SubText);
		RowSub.TextXAlignment = (Enum.TextXAlignment.Left);
		RowSub.Font = (Enum.Font.Gotham);
		RowSub.TextSize = 10;
		RowSub.Parent = RowCard;

		RegisterThemeColor(RowSub, 'TextColor3', (Enum.StudioStyleGuideColor.SubText));

		local ToggleBadge: Frame = Instance.new('Frame');
		ToggleBadge.Name = 'ToggleBadge';
		ToggleBadge.Size = UDim2.fromOffset(54, 24);
		ToggleBadge.Position = UDim2.new(1.0, -54, 0.5, -12);
		ToggleBadge.BorderSizePixel = 0;
		ToggleBadge.Parent = RowCard;

		CreateUICorner(12, ToggleBadge);
		local ToggleStroke: UIStroke = CreateUIStroke(Color3.fromRGB(60, 66, 78), 1, ToggleBadge);

		local ToggleText: TextLabel = Instance.new('TextLabel');
		ToggleText.Name = 'ToggleText';
		ToggleText.Size = UDim2.fromScale(1.0, 1.0);
		ToggleText.BackgroundTransparency = 1.0;
		ToggleText.Font = (Enum.Font.GothamBold);
		ToggleText.TextSize = 11;
		ToggleText.Parent = ToggleBadge;

		local function RefreshVisuals(): ()
			RowSub.Text = GetDescription(CurrentState);

			if CurrentState then
				ToggleBadge.BackgroundColor3 = Color3.fromRGB(0, 145, 90);
				ToggleStroke.Color = Color3.fromRGB(0, 200, 125);
				ToggleText.Text = 'ON';
				ToggleText.TextColor3 = Color3.fromRGB(255, 255, 255);
			else
				ToggleBadge.BackgroundColor3 = Color3.fromRGB(48, 52, 62);
				ToggleStroke.Color = Color3.fromRGB(75, 82, 96);
				ToggleText.Text = 'OFF';
				ToggleText.TextColor3 = Color3.fromRGB(185, 190, 200);
			end

			return;
		end

		RefreshVisuals();

		RowCard.MouseButton1Click:Connect(function(): ()
			CurrentState = not CurrentState;
			RefreshVisuals();
			OnToggle(CurrentState);

			return;
		end);

		return RefreshVisuals;
	end

	CreateToggleRow(
		'AllDescendantsToggle',
		'All Descendants',
		function(IsEnabled: boolean): (string)
			return IsEnabled
				and 'ON: Syncing all instances, properties, and scripts'
				or 'OFF: Syncing scripts and direct ancestry only';
		end,
		Callbacks.GetAllDescendants(),
		function(NewState: boolean): ()
			Callbacks.SetAllDescendants(NewState);

			return;
		end,
		4
	);

	CreateToggleRow(
		'InitialSyncFromRSToggle',
		'Initial Sync From RS',
		function(IsEnabled: boolean): (string)
			return IsEnabled
				and 'ON: Initial export RS -> IDE (Unidirectional: RS -> IDE)'
				or 'OFF: Initial import IDE -> RS (Unidirectional: IDE -> RS)';
		end,
		Callbacks.GetInitialFromRS(),
		function(NewState: boolean): ()
			Callbacks.SetInitialFromRS(NewState);

			return;
		end,
		5
	);

	---> Four-state slider / segmented selector for conflict resolution policy
	local ConflictStates: { [number]: { Key: string, Label: string } } = {
		{
			Key   = 'Both',
			Label = '1. Both',
		},
		{
			Key   = 'Delete',
			Label = '2. Delete',
		},
		{
			Key   = 'IDE',
			Label = '3. IDE',
		},
		{
			Key   = 'RS',
			Label = '4. RS',
		},
	};

	local CurrentConflictMode: string = Callbacks.GetConflictMode();

	local ConflictCard: Frame = Instance.new('Frame');
	ConflictCard.Name = 'ConflictResolutionCard';
	ConflictCard.Size = UDim2.new(1.0, 0, 0, 82);
	ConflictCard.LayoutOrder = 6;
	ConflictCard.BackgroundColor3 = Theme:GetColor(Enum.StudioStyleGuideColor.InputFieldBackground);
	ConflictCard.BorderSizePixel = 0;
	ConflictCard.Parent = ScrollContainer;

	CreateUICorner(6, ConflictCard);
	local ConflictCardStroke: UIStroke = CreateUIStroke(Theme:GetColor(Enum.StudioStyleGuideColor.Border), 1, ConflictCard);
	CreateUIPadding(6, 6, 10, 10, ConflictCard);

	RegisterThemeColor(ConflictCard, 'BackgroundColor3', (Enum.StudioStyleGuideColor.InputFieldBackground));
	RegisterThemeColor(ConflictCardStroke, 'Color', (Enum.StudioStyleGuideColor.Border));

	local ConflictTitle: TextLabel = Instance.new('TextLabel');
	ConflictTitle.Name = 'ConflictTitle';
	ConflictTitle.Size = UDim2.new(1.0, 0, 0, 16);
	ConflictTitle.Position = UDim2.fromOffset(0, 0);
	ConflictTitle.BackgroundTransparency = 1.0;
	ConflictTitle.Text = 'Conflict Resolution Policy';
	ConflictTitle.TextColor3 = Theme:GetColor(Enum.StudioStyleGuideColor.MainText);
	ConflictTitle.TextXAlignment = (Enum.TextXAlignment.Left);
	ConflictTitle.Font = (Enum.Font.GothamBold);
	ConflictTitle.TextSize = 12;
	ConflictTitle.Parent = ConflictCard;

	RegisterThemeColor(ConflictTitle, 'TextColor3', (Enum.StudioStyleGuideColor.MainText));

	local ConflictSub: TextLabel = Instance.new('TextLabel');
	ConflictSub.Name = 'ConflictSub';
	ConflictSub.Size = UDim2.new(1.0, 0, 0, 16);
	ConflictSub.Position = UDim2.fromOffset(0, 16);
	ConflictSub.BackgroundTransparency = 1.0;
	ConflictSub.Text = 'How conflicts should be handled when a file has different contents in RS and the IDE.';
	ConflictSub.TextColor3 = Theme:GetColor(Enum.StudioStyleGuideColor.SubText);
	ConflictSub.TextXAlignment = (Enum.TextXAlignment.Left);
	ConflictSub.Font = (Enum.Font.Gotham);
	ConflictSub.TextSize = 10;
	ConflictSub.TextTruncate = (Enum.TextTruncate.AtEnd);
	ConflictSub.Parent = ConflictCard;

	RegisterThemeColor(ConflictSub, 'TextColor3', (Enum.StudioStyleGuideColor.SubText));

	local SliderTrack: Frame = Instance.new('Frame');
	SliderTrack.Name = 'SliderTrack';
	SliderTrack.Size = UDim2.new(1.0, 0, 0, 30);
	SliderTrack.Position = UDim2.fromOffset(0, 38);
	SliderTrack.BackgroundColor3 = Color3.fromRGB(36, 40, 48);
	SliderTrack.BorderSizePixel = 0;
	SliderTrack.Parent = ConflictCard;

	CreateUICorner(6, SliderTrack);
	CreateUIStroke(Color3.fromRGB(60, 66, 78), 1, SliderTrack);
	CreateUIPadding(2, 2, 2, 2, SliderTrack);

	local SliderLayout: UIListLayout = Instance.new('UIListLayout');
	SliderLayout.FillDirection = (Enum.FillDirection.Horizontal);
	SliderLayout.Padding = UDim.new(0, 4);
	SliderLayout.SortOrder = (Enum.SortOrder.LayoutOrder);
	SliderLayout.Parent = SliderTrack;

	local StateButtons: { [string]: { Button: TextButton, Stroke: UIStroke } } = { };

	local function RefreshConflictSlider(): ()
		for _: number, StateInfo in ConflictStates do
			local Entry = StateButtons[StateInfo.Key];
			local IsSelected: boolean = (StateInfo.Key == CurrentConflictMode);

			if Entry then
				Entry.Button.BackgroundColor3 = IsSelected and Color3.fromRGB(0, 145, 90) or Color3.fromRGB(48, 52, 62);
				Entry.Button.TextColor3 = IsSelected and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(185, 190, 200);
				Entry.Stroke.Color = IsSelected and Color3.fromRGB(0, 200, 125) or Color3.fromRGB(70, 76, 90);
			end
		end

		return;
	end

	for StateIndex: number, StateInfo in ConflictStates do
		local SegmentButton: TextButton = Instance.new('TextButton');
		SegmentButton.Name = `ConflictState_{StateInfo.Key}`;
		SegmentButton.Size = UDim2.new(0.25, -3, 1.0, 0);
		SegmentButton.LayoutOrder = StateIndex;
		SegmentButton.BorderSizePixel = 0;
		SegmentButton.AutoButtonColor = true;
		SegmentButton.Text = StateInfo.Label;
		SegmentButton.Font = (Enum.Font.GothamBold);
		SegmentButton.TextSize = 11;
		SegmentButton.Parent = SliderTrack;

		CreateUICorner(4, SegmentButton);
		local SegmentStroke: UIStroke = CreateUIStroke(Color3.fromRGB(70, 76, 90), 1, SegmentButton);

		StateButtons[StateInfo.Key] = {
			Button = SegmentButton,
			Stroke = SegmentStroke,
		};

		SegmentButton.MouseButton1Click:Connect(function(): ()
			CurrentConflictMode = StateInfo.Key;
			RefreshConflictSlider();
			Callbacks.SetConflictMode(StateInfo.Key);

			return;
		end);
	end

	RefreshConflictSlider();

	CreateSectionLabel('LIVE Modes', 7);

	local function CreateLiveModeCard(
		Name: string,
		TitleText: string,
		SubtitleText: string,
		DefaultBgColor: Color3,
		DefaultStrokeColor: Color3,
		MethodName: string,
		Order: number
	): (TextButton, UIStroke)
		local CardButton: TextButton = Instance.new('TextButton');
		CardButton.Name = Name;
		CardButton.Size = UDim2.new(1.0, 0, 0, 50);
		CardButton.LayoutOrder = Order;
		CardButton.BackgroundColor3 = DefaultBgColor;
		CardButton.BorderSizePixel = 0;
		CardButton.AutoButtonColor = true;
		CardButton.Text = '';
		CardButton.Parent = ScrollContainer;

		CreateUICorner(8, CardButton);
		local CardStroke: UIStroke = CreateUIStroke(DefaultStrokeColor, 1.5, CardButton);
		CreateUIPadding(6, 6, 12, 12, CardButton);

		local ModeIcon: ImageLabel = Instance.new('ImageLabel');
		ModeIcon.Name = 'ModeIcon';
		ModeIcon.Size = UDim2.fromOffset(24, 24);
		ModeIcon.Position = UDim2.new(0, 0, 0.5, -12);
		ModeIcon.BackgroundTransparency = 1.0;
		ModeIcon.Image = 'rbxassetid://78911552761219';
		ModeIcon.ScaleType = (Enum.ScaleType.Fit);
		ModeIcon.Parent = CardButton;

		local ModeTitle: TextLabel = Instance.new('TextLabel');
		ModeTitle.Name = 'ModeTitle';
		ModeTitle.Size = UDim2.new(1.0, -34, 0, 18);
		ModeTitle.Position = UDim2.fromOffset(34, 2);
		ModeTitle.BackgroundTransparency = 1.0;
		ModeTitle.Text = TitleText;
		ModeTitle.TextColor3 = Color3.fromRGB(255, 255, 255);
		ModeTitle.TextXAlignment = (Enum.TextXAlignment.Left);
		ModeTitle.Font = (Enum.Font.GothamBold);
		ModeTitle.TextSize = 13;
		ModeTitle.Parent = CardButton;

		local ModeSub: TextLabel = Instance.new('TextLabel');
		ModeSub.Name = 'ModeSub';
		ModeSub.Size = UDim2.new(1.0, -34, 0, 16);
		ModeSub.Position = UDim2.fromOffset(34, 20);
		ModeSub.BackgroundTransparency = 1.0;
		ModeSub.Text = SubtitleText;
		ModeSub.TextColor3 = Color3.fromRGB(220, 240, 235);
		ModeSub.TextXAlignment = (Enum.TextXAlignment.Left);
		ModeSub.Font = (Enum.Font.Gotham);
		ModeSub.TextSize = 10;
		ModeSub.Parent = CardButton;

		CardButton.MouseButton1Click:Connect(function(): ()
			Callbacks.ToggleSynchronization(MethodName);

			return;
		end);

		return CardButton, CardStroke;
	end

	local BidirectionalCard: TextButton, BidirectionalStroke: UIStroke = CreateLiveModeCard(
		'BidirectionalCard',
		'Bidirectional',
		'Two-way live synchronization between IDE and RS',
		Color3.fromRGB(0, 140, 90),
		Color3.fromRGB(0, 180, 115),
		'Bidirectional',
		8
	);

	local UnidirectionalCard: TextButton, UnidirectionalStroke: UIStroke = CreateLiveModeCard(
		'UnidirectionalCard',
		'Unidirectional',
		'One-way live synchronization governed by Initial Sync toggle',
		Color3.fromRGB(25, 105, 165),
		Color3.fromRGB(45, 145, 215),
		'Unidirectional',
		9
	);

	local StopButton: TextButton = Instance.new('TextButton');
	StopButton.Name = 'StopButton';
	StopButton.Size = UDim2.new(1.0, 0, 0, 36);
	StopButton.LayoutOrder = 10;
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

		return;
	end);

	CreateSectionLabel('Non-LIVE Modes', 11);

	local OneShotRow: Frame = Instance.new('Frame');
	OneShotRow.Name = 'OneShotRow';
	OneShotRow.Size = UDim2.new(1.0, 0, 0, 40);
	OneShotRow.LayoutOrder = 12;
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
		Icon.Size = UDim2.fromOffset(18, 18);
		Icon.Position = UDim2.new(0, 0, 0.5, -9);
		Icon.BackgroundTransparency = 1.0;
		Icon.Image = IconAsset;
		Icon.ScaleType = (Enum.ScaleType.Fit);
		Icon.Parent = Button;

		local Label: TextLabel = Instance.new('TextLabel');
		Label.Name = 'Label';
		Label.Size = UDim2.new(1.0, -26, 1.0, 0);
		Label.Position = UDim2.fromOffset(24, 0);
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

	CreateOneShotButton('ExportButton', 'Export to IDE', 'rbxassetid://78911552761219', function(): ()
		Callbacks.Export();

		return;
	end, 1);

	CreateOneShotButton('ImportButton', 'Import to RS', 'rbxassetid://78911552761219', function(): ()
		Callbacks.Import();

		return;
	end, 2);

	CreateSectionLabel('PROJECT & RIBBON', 13);

	local RibbonTabVisible: boolean = Callbacks.GetShowRibbonTab();

	local RibbonToggleButton: TextButton = Instance.new('TextButton');
	RibbonToggleButton.Name = 'RibbonToggleButton';
	RibbonToggleButton.Size = UDim2.new(1.0, 0, 0, 36);
	RibbonToggleButton.LayoutOrder = 14;
	RibbonToggleButton.BackgroundColor3 = Theme:GetColor(Enum.StudioStyleGuideColor.Button);
	RibbonToggleButton.BorderSizePixel = 0;
	RibbonToggleButton.AutoButtonColor = true;
	RibbonToggleButton.Text = RibbonTabVisible and 'Hide Silicon Ribbon Tab' or 'Show Silicon Ribbon Tab';
	RibbonToggleButton.TextColor3 = Theme:GetColor(Enum.StudioStyleGuideColor.MainText);
	RibbonToggleButton.Font = (Enum.Font.GothamMedium);
	RibbonToggleButton.TextSize = 11;
	RibbonToggleButton.Parent = ScrollContainer;

	CreateUICorner(6, RibbonToggleButton);
	local RibbonToggleStroke: UIStroke = CreateUIStroke(Theme:GetColor(Enum.StudioStyleGuideColor.Border), 1, RibbonToggleButton);

	RegisterThemeColor(RibbonToggleButton, 'BackgroundColor3', (Enum.StudioStyleGuideColor.Button));
	RegisterThemeColor(RibbonToggleButton, 'TextColor3', (Enum.StudioStyleGuideColor.MainText));
	RegisterThemeColor(RibbonToggleStroke, 'Color', (Enum.StudioStyleGuideColor.Border));

	RibbonToggleButton.MouseButton1Click:Connect(function(): ()
		RibbonTabVisible = not RibbonTabVisible;
		RibbonToggleButton.Text = RibbonTabVisible and 'Hide Silicon Ribbon Tab' or 'Show Silicon Ribbon Tab';
		Callbacks.SetShowRibbonTab(RibbonTabVisible);

		return;
	end);

	local ClearProjectButton: TextButton = Instance.new('TextButton');
	ClearProjectButton.Name = 'ClearProjectButton';
	ClearProjectButton.Size = UDim2.new(1.0, 0, 0, 36);
	ClearProjectButton.LayoutOrder = 15;
	ClearProjectButton.BackgroundColor3 = Color3.fromRGB(130, 32, 36);
	ClearProjectButton.BorderSizePixel = 0;
	ClearProjectButton.AutoButtonColor = true;
	ClearProjectButton.Text = 'Clear project';
	ClearProjectButton.TextColor3 = Color3.fromRGB(255, 235, 235);
	ClearProjectButton.Font = (Enum.Font.GothamBold);
	ClearProjectButton.TextSize = 11;
	ClearProjectButton.Parent = ScrollContainer;

	CreateUICorner(6, ClearProjectButton);
	CreateUIStroke(Color3.fromRGB(185, 55, 60), 1, ClearProjectButton);

	---> Confirmation Popover Modal for "Clear project"
	local ConfirmBackdrop: TextButton = Instance.new('TextButton');
	ConfirmBackdrop.Name = 'ConfirmClearBackdrop';
	ConfirmBackdrop.Size = UDim2.fromScale(1.0, 1.0);
	ConfirmBackdrop.Position = UDim2.fromScale(0.0, 0.0);
	ConfirmBackdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0);
	ConfirmBackdrop.BackgroundTransparency = 0.35;
	ConfirmBackdrop.BorderSizePixel = 0;
	ConfirmBackdrop.AutoButtonColor = false;
	ConfirmBackdrop.Text = '';
	ConfirmBackdrop.Visible = false;
	ConfirmBackdrop.ZIndex = 50;
	ConfirmBackdrop.Parent = RootContainer;

	local ConfirmModal: Frame = Instance.new('Frame');
	ConfirmModal.Name = 'ConfirmClearModal';
	ConfirmModal.Size = UDim2.new(1.0, -32, 0, 150);
	ConfirmModal.Position = UDim2.new(0.5, 0, 0.5, 0);
	ConfirmModal.AnchorPoint = Vector2.new(0.5, 0.5);
	ConfirmModal.BackgroundColor3 = Color3.fromRGB(32, 36, 44);
	ConfirmModal.BorderSizePixel = 0;
	ConfirmModal.ZIndex = 51;
	ConfirmModal.Parent = ConfirmBackdrop;

	CreateUICorner(10, ConfirmModal);
	CreateUIStroke(Color3.fromRGB(200, 65, 70), 1.5, ConfirmModal);
	CreateUIPadding(14, 14, 14, 14, ConfirmModal);

	local ConfirmTitle: TextLabel = Instance.new('TextLabel');
	ConfirmTitle.Name = 'ConfirmTitle';
	ConfirmTitle.Size = UDim2.new(1.0, 0, 0, 20);
	ConfirmTitle.Position = UDim2.fromOffset(0, 0);
	ConfirmTitle.BackgroundTransparency = 1.0;
	ConfirmTitle.Text = 'Confirm Clear Project';
	ConfirmTitle.TextColor3 = Color3.fromRGB(255, 255, 255);
	ConfirmTitle.TextXAlignment = (Enum.TextXAlignment.Left);
	ConfirmTitle.Font = (Enum.Font.GothamBold);
	ConfirmTitle.TextSize = 13;
	ConfirmTitle.ZIndex = 52;
	ConfirmTitle.Parent = ConfirmModal;

	local ConfirmBody: TextLabel = Instance.new('TextLabel');
	ConfirmBody.Name = 'ConfirmBody';
	ConfirmBody.Size = UDim2.new(1.0, 0, 0, 56);
	ConfirmBody.Position = UDim2.fromOffset(0, 24);
	ConfirmBody.BackgroundTransparency = 1.0;
	ConfirmBody.Text = 'Are you sure you want to clear the project? Synchronized files in RS (and Silicon/Game if connected) will be moved to the Recycle Bin.';
	ConfirmBody.TextColor3 = Color3.fromRGB(205, 210, 220);
	ConfirmBody.TextXAlignment = (Enum.TextXAlignment.Left);
	ConfirmBody.TextYAlignment = (Enum.TextYAlignment.Top);
	ConfirmBody.TextWrapped = true;
	ConfirmBody.Font = (Enum.Font.Gotham);
	ConfirmBody.TextSize = 11;
	ConfirmBody.ZIndex = 52;
	ConfirmBody.Parent = ConfirmModal;

	local ConfirmButtonsRow: Frame = Instance.new('Frame');
	ConfirmButtonsRow.Name = 'ConfirmButtonsRow';
	ConfirmButtonsRow.Size = UDim2.new(1.0, 0, 0, 34);
	ConfirmButtonsRow.Position = UDim2.new(0.0, 0, 1.0, -34);
	ConfirmButtonsRow.BackgroundTransparency = 1.0;
	ConfirmButtonsRow.ZIndex = 52;
	ConfirmButtonsRow.Parent = ConfirmModal;

	local CancelClearButton: TextButton = Instance.new('TextButton');
	CancelClearButton.Name = 'CancelClearButton';
	CancelClearButton.Size = UDim2.new(0.5, -4, 1.0, 0);
	CancelClearButton.Position = UDim2.fromScale(0.0, 0.0);
	CancelClearButton.BackgroundColor3 = Color3.fromRGB(54, 60, 72);
	CancelClearButton.BorderSizePixel = 0;
	CancelClearButton.AutoButtonColor = true;
	CancelClearButton.Text = 'Cancel';
	CancelClearButton.TextColor3 = Color3.fromRGB(230, 235, 245);
	CancelClearButton.Font = (Enum.Font.GothamMedium);
	CancelClearButton.TextSize = 11;
	CancelClearButton.ZIndex = 53;
	CancelClearButton.Parent = ConfirmButtonsRow;

	CreateUICorner(6, CancelClearButton);
	CreateUIStroke(Color3.fromRGB(80, 88, 104), 1, CancelClearButton);

	local ConfirmClearActionButton: TextButton = Instance.new('TextButton');
	ConfirmClearActionButton.Name = 'ConfirmClearActionButton';
	ConfirmClearActionButton.Size = UDim2.new(0.5, -4, 1.0, 0);
	ConfirmClearActionButton.Position = UDim2.new(0.5, 4, 0.0, 0);
	ConfirmClearActionButton.BackgroundColor3 = Color3.fromRGB(185, 42, 46);
	ConfirmClearActionButton.BorderSizePixel = 0;
	ConfirmClearActionButton.AutoButtonColor = true;
	ConfirmClearActionButton.Text = 'Clear Project';
	ConfirmClearActionButton.TextColor3 = Color3.fromRGB(255, 255, 255);
	ConfirmClearActionButton.Font = (Enum.Font.GothamBold);
	ConfirmClearActionButton.TextSize = 11;
	ConfirmClearActionButton.ZIndex = 53;
	ConfirmClearActionButton.Parent = ConfirmButtonsRow;

	CreateUICorner(6, ConfirmClearActionButton);
	CreateUIStroke(Color3.fromRGB(230, 70, 75), 1, ConfirmClearActionButton);

	ClearProjectButton.MouseButton1Click:Connect(function(): ()
		ConfirmBackdrop.Visible = true;

		return;
	end);

	CancelClearButton.MouseButton1Click:Connect(function(): ()
		ConfirmBackdrop.Visible = false;

		return;
	end);

	ConfirmBackdrop.MouseButton1Click:Connect(function(): ()
		ConfirmBackdrop.Visible = false;

		return;
	end);

	ConfirmClearActionButton.MouseButton1Click:Connect(function(): ()
		ConfirmBackdrop.Visible = false;
		Callbacks.ClearProject();

		return;
	end);

	CreateSectionLabel('ACTIVITY LOG', 16);

	local LogCard: Frame = Instance.new('Frame');
	LogCard.Name = 'LogCard';
	LogCard.Size = UDim2.new(1.0, 0, 0, 88);
	LogCard.LayoutOrder = 17;
	LogCard.BackgroundColor3 = Theme:GetColor(Enum.StudioStyleGuideColor.InputFieldBackground);
	LogCard.BorderSizePixel = 0;
	LogCard.Parent = ScrollContainer;

	CreateUICorner(6, LogCard);
	local LogStroke: UIStroke = CreateUIStroke(Theme:GetColor(Enum.StudioStyleGuideColor.Border), 1, LogCard);
	CreateUIPadding(6, 6, 8, 8, LogCard);

	RegisterThemeColor(LogCard, 'BackgroundColor3', (Enum.StudioStyleGuideColor.InputFieldBackground));
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

			local IsBidirectional: boolean = (ActiveMethodName == 'Bidirectional');
			local IsUnidirectional: boolean = (ActiveMethodName == 'Unidirectional');

			BidirectionalCard.BackgroundColor3 = IsBidirectional and Color3.fromRGB(0, 170, 105) or Color3.fromRGB(45, 52, 64);
			BidirectionalStroke.Color = IsBidirectional and Color3.fromRGB(0, 230, 130) or Color3.fromRGB(70, 78, 92);

			UnidirectionalCard.BackgroundColor3 = IsUnidirectional and Color3.fromRGB(0, 170, 105) or Color3.fromRGB(45, 52, 64);
			UnidirectionalStroke.Color = IsUnidirectional and Color3.fromRGB(0, 230, 130) or Color3.fromRGB(70, 78, 92);

		elseif IsConnected then
			StatusBadge.BackgroundColor3 = Color3.fromRGB(20, 45, 65);
			StatusBadgeStroke.Color = Color3.fromRGB(30, 130, 210);
			StatusDot.BackgroundColor3 = Color3.fromRGB(40, 160, 255);
			StatusTextLabel.TextColor3 = Color3.fromRGB(100, 190, 255);
			StatusTextLabel.Text = 'CONNECTED';
			StopButton.Visible = false;

			BidirectionalCard.BackgroundColor3 = Color3.fromRGB(0, 140, 90);
			BidirectionalStroke.Color = Color3.fromRGB(0, 180, 115);

			UnidirectionalCard.BackgroundColor3 = Color3.fromRGB(25, 105, 165);
			UnidirectionalStroke.Color = Color3.fromRGB(45, 145, 215);

		else
			StatusBadge.BackgroundColor3 = Color3.fromRGB(42, 46, 54);
			StatusBadgeStroke.Color = Color3.fromRGB(60, 66, 78);
			StatusDot.BackgroundColor3 = Color3.fromRGB(150, 150, 160);
			StatusTextLabel.TextColor3 = Color3.fromRGB(180, 185, 195);
			StatusTextLabel.Text = 'OFFLINE';
			StopButton.Visible = false;

			BidirectionalCard.BackgroundColor3 = Color3.fromRGB(0, 140, 90);
			BidirectionalStroke.Color = Color3.fromRGB(0, 180, 115);

			UnidirectionalCard.BackgroundColor3 = Color3.fromRGB(25, 105, 165);
			UnidirectionalStroke.Color = Color3.fromRGB(45, 145, 215);
		end

		return;
	end

	PingButton.MouseButton1Click:Connect(function(): ()
		PingButton.Text = '...';
		task.spawn(function(): ()
			local Alive: boolean = Callbacks.CheckServer();
			PingButton.Text = Alive and 'Alive!' or 'Offline';
			UpdateStatusUI(Alive and 'Connected' or 'Offline', Alive, Callbacks.GetActiveMethod());
			AppendLog(Alive and 'Server daemon responsive at localhost:6969' or 'Cannot reach server daemon at localhost:6969');
			task.wait(2.0);
			PingButton.Text = 'Check';

			return;
		end);

		return;
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

	Widget:BindToClose(function(): ()
		Widget.Enabled = false;

		return;
	end);

	local function ToggleUI(): ()
		Widget.Enabled = not (Widget.Enabled);

		if (Widget.Enabled) then
			pcall(function(): ()
				Widget:RequestRaise();

				return;
			end);
		end

		return;
	end

	local Controller: UIController = {
		Widget        = Widget,
		RootContainer = RootContainer,
		ToggleUI      = ToggleUI,
		SetStatus     = UpdateStatusUI,
		Log           = AppendLog,
	};

	return Controller;
end

