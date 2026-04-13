-- ELIXIR 3.5 -- REDESIGNED: DEEP PURPLE THEME + TEXT SIDEBAR
local Players = game:GetService("Players")
local player = game.Players.LocalPlayer
local vim = game:GetService("VirtualInputManager")
local ContextActionService = game:GetService("ContextActionService")
local VirtualUser = game:GetService("VirtualUser")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

repeat task.wait() until player.Character

local playerGui = player:WaitForChild("PlayerGui")

local running = false
local autoSellEnabled = false
local buyAmount = 1

local autoFarmRunning = false
local autoFarmStopping = false
local cookAmount = 5

local buyRemote = game:GetService("ReplicatedStorage").RemoteEvents.StorePurchase

local npcPos = CFrame.new(510.762817,3.58721066,600.791504)
local tierPos = CFrame.new(1110.18726,4.28433371,117.139168)

-- ============================================================
-- ANTI AFK
-- ============================================================
player.Idled:Connect(function()
	VirtualUser:CaptureController()
	VirtualUser:ClickButton2(Vector2.new())
end)

-- ============================================================
-- HELPERS
-- ============================================================
local function holdE(t)
	vim:SendKeyEvent(true,"E",false,game)
	task.wait(t)
	vim:SendKeyEvent(false,"E",false,game)
end

local function equip(name)
	local char = player.Character
	local tool = player.Backpack:FindFirstChild(name) or char:FindFirstChild(name)
	if tool then
		char.Humanoid:EquipTool(tool)
		task.wait(.3)
		return true
	end
end

local function countItem(name)
	local total = 0
	for _,v in pairs(player.Backpack:GetChildren()) do
		if v.Name == name then total += 1 end
	end
	for _,v in pairs(player.Character:GetChildren()) do
		if v:IsA("Tool") and v.Name == name then total += 1 end
	end
	return total
end

local function vehicleTeleport(cf)
	local char = player.Character
	if not char then return end
	local humanoid = char:FindFirstChild("Humanoid")
	if not humanoid then return end
	local seat = humanoid.SeatPart
	if not seat then return end
	local vehicle = seat:FindFirstAncestorOfClass("Model")
	if not vehicle then return end
	if not vehicle.PrimaryPart then vehicle.PrimaryPart = seat end
	vehicle:SetPrimaryPartCFrame(cf)
	task.wait(1)
	seat.Throttle = 1
	task.wait(0.5)
	seat.Throttle = 0
end

local function fill(bar, time)
	bar.Size = UDim2.new(0,0,1,0)
	bar:TweenSize(UDim2.new(1,0,1,0), Enum.EasingDirection.InOut, Enum.EasingStyle.Linear, time, true)
	task.delay(time, function() bar.Size = UDim2.new(0,0,1,0) end)
end

-- ============================================================
-- GUI SETUP
-- ============================================================
local gui = Instance.new("ScreenGui")
gui.Name = "ELIXIR_3_5"
gui.Parent = playerGui
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- ============================================================
-- COLOR PALETTE
-- ============================================================
local C = {
	bg        = Color3.fromRGB(8,  7,  14),
	surface   = Color3.fromRGB(14, 12, 24),
	panel     = Color3.fromRGB(18, 16, 30),
	card      = Color3.fromRGB(24, 21, 40),
	sidebar   = Color3.fromRGB(11,  9, 20),
	accent    = Color3.fromRGB(130, 60, 240),
	accentDim = Color3.fromRGB(75,  35, 140),
	accentGlow= Color3.fromRGB(175, 120, 255),
	accentSoft= Color3.fromRGB(100, 55, 190),
	text      = Color3.fromRGB(220, 215, 245),
	textMid   = Color3.fromRGB(145, 138, 175),
	textDim   = Color3.fromRGB(75,  68, 100),
	green     = Color3.fromRGB(55,  200, 110),
	red       = Color3.fromRGB(220, 60,  75),
	border    = Color3.fromRGB(38,  32,  62),
	borderAct = Color3.fromRGB(100, 55, 190),
}

-- ============================================================
-- SIMPLE LOADING OVERLAY
-- Hanya hitam + tulisan "ELIXIR STORE" yang keren
-- showLoading() / hideLoading() exposed ke luar
-- ============================================================
local showLoading, hideLoading
do
	local loadGui = Instance.new("ScreenGui")
	loadGui.Name = "ELIXIR_LOAD"
	loadGui.IgnoreGuiInset = true
	loadGui.ResetOnSpawn = false
	loadGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	loadGui.DisplayOrder = 999
	loadGui.Enabled = false
	pcall(function() loadGui.Parent = game:GetService("CoreGui") end)
	if not loadGui.Parent then loadGui.Parent = playerGui end

	-- Full-screen hitam
	local bg = Instance.new("Frame", loadGui)
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	bg.BackgroundTransparency = 0
	bg.BorderSizePixel = 0
	bg.ZIndex = 10

	-- Subtle purple center glow
	local glow = Instance.new("Frame", bg)
	glow.Size = UDim2.new(0, 400, 0, 180)
	glow.Position = UDim2.new(0.5, -200, 0.5, -90)
	glow.BackgroundColor3 = Color3.fromRGB(80, 30, 160)
	glow.BackgroundTransparency = 0.88
	glow.BorderSizePixel = 0
	glow.ZIndex = 11
	Instance.new("UICorner", glow).CornerRadius = UDim.new(1, 0)

	-- Tulisan utama "ELIXIR STORE"
	local title = Instance.new("TextLabel", bg)
	title.Size = UDim2.new(0, 500, 0, 56)
	title.Position = UDim2.new(0.5, -250, 0.5, -50)
	title.BackgroundTransparency = 1
	title.Text = "ELIXIR STORE"
	title.Font = Enum.Font.GothamBlack
	title.TextSize = 44
	title.TextColor3 = Color3.fromRGB(220, 215, 245)
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.ZIndex = 12
	do
		local g = Instance.new("UIGradient", title)
		g.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(175, 120, 255)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(220, 215, 245)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(130, 60, 240)),
		})
		g.Rotation = 0
	end

	-- Garis aksen tipis di bawah judul
	local line = Instance.new("Frame", bg)
	line.Size = UDim2.new(0, 200, 0, 1)
	line.Position = UDim2.new(0.5, -100, 0.5, 14)
	line.BackgroundColor3 = Color3.fromRGB(130, 60, 240)
	line.BackgroundTransparency = 0.3
	line.BorderSizePixel = 0
	line.ZIndex = 12
	Instance.new("UICorner", line).CornerRadius = UDim.new(1, 0)

	-- Tulisan kecil bawah "Teleporting..."
	local subLbl = Instance.new("TextLabel", bg)
	subLbl.Size = UDim2.new(0, 400, 0, 22)
	subLbl.Position = UDim2.new(0.5, -200, 0.5, 24)
	subLbl.BackgroundTransparency = 1
	subLbl.Text = "Teleporting..."
	subLbl.Font = Enum.Font.Gotham
	subLbl.TextSize = 13
	subLbl.TextColor3 = Color3.fromRGB(100, 55, 190)
	subLbl.TextXAlignment = Enum.TextXAlignment.Center
	subLbl.ZIndex = 12

	-- Versi kecil pojok bawah
	local ver = Instance.new("TextLabel", bg)
	ver.Size = UDim2.new(1, 0, 0, 18)
	ver.Position = UDim2.new(0, 0, 1, -22)
	ver.BackgroundTransparency = 1
	ver.Text = "ELIXIR v3.5  •  Deep Purple Edition"
	ver.Font = Enum.Font.Gotham
	ver.TextSize = 11
	ver.TextColor3 = Color3.fromRGB(45, 38, 70)
	ver.TextXAlignment = Enum.TextXAlignment.Center
	ver.ZIndex = 12

	-- Animasi dots pada subLbl
	task.spawn(function()
		local pats = {"Teleporting", "Teleporting.", "Teleporting..", "Teleporting..."}
		local idx = 1
		while loadGui and loadGui.Parent do
			if loadGui.Enabled then
				subLbl.Text = pats[idx]
				idx = (idx % #pats) + 1
			end
			task.wait(0.3)
		end
	end)

	showLoading = function(subText)
		subLbl.Text = subText or "Teleporting"
		loadGui.Enabled = true
	end

	hideLoading = function()
		loadGui.Enabled = false
	end
end

-- ============================================================
-- NOTIFICATION SYSTEM
-- ============================================================
local notifContainer = Instance.new("Frame", gui)
notifContainer.Size = UDim2.new(0, 270, 1, 0)
notifContainer.Position = UDim2.new(1, -280, 0, 0)
notifContainer.BackgroundTransparency = 1
notifContainer.ZIndex = 100

local notifLayout = Instance.new("UIListLayout", notifContainer)
notifLayout.Padding = UDim.new(0, 6)
notifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
notifLayout.SortOrder = Enum.SortOrder.LayoutOrder

local notifPadding = Instance.new("UIPadding", notifContainer)
notifPadding.PaddingBottom = UDim.new(0, 14)
notifPadding.PaddingRight = UDim.new(0, 8)

local notifCount = 0
local function notify(title, msg, ntype)
	notifCount += 1
	local color = ntype == "success" and C.green or ntype == "error" and C.red or C.accent

	local card = Instance.new("Frame", notifContainer)
	card.Size = UDim2.new(1, 0, 0, 58)
	card.BackgroundColor3 = C.card
	card.BorderSizePixel = 0
	card.ClipsDescendants = true
	card.ZIndex = 100
	card.LayoutOrder = notifCount

	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

	local stroke = Instance.new("UIStroke", card)
	stroke.Color = color
	stroke.Thickness = 1
	stroke.Transparency = 0.5

	local bar_left = Instance.new("Frame", card)
	bar_left.Size = UDim2.new(0, 3, 1, 0)
	bar_left.BackgroundColor3 = color
	bar_left.BorderSizePixel = 0
	bar_left.ZIndex = 101

	local t = Instance.new("TextLabel", card)
	t.Position = UDim2.new(0, 14, 0, 7)
	t.Size = UDim2.new(1, -22, 0, 18)
	t.BackgroundTransparency = 1
	t.Text = title
	t.Font = Enum.Font.GothamBold
	t.TextSize = 13
	t.TextColor3 = C.text
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.ZIndex = 101

	local m = Instance.new("TextLabel", card)
	m.Position = UDim2.new(0, 14, 0, 26)
	m.Size = UDim2.new(1, -22, 0, 26)
	m.BackgroundTransparency = 1
	m.Text = msg
	m.Font = Enum.Font.Gotham
	m.TextSize = 11
	m.TextColor3 = C.textMid
	m.TextXAlignment = Enum.TextXAlignment.Left
	m.TextWrapped = true
	m.ZIndex = 101

	local timerBar = Instance.new("Frame", card)
	timerBar.Position = UDim2.new(0, 3, 1, -2)
	timerBar.Size = UDim2.new(1, -3, 0, 2)
	timerBar.BackgroundColor3 = color
	timerBar.BorderSizePixel = 0
	timerBar.ZIndex = 101

	card.Position = UDim2.new(1, 16, 0, 0)
	TweenService:Create(card, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {Position = UDim2.new(0,0,0,0)}):Play()
	TweenService:Create(timerBar, TweenInfo.new(3.5, Enum.EasingStyle.Linear), {Size = UDim2.new(0,3,0,2)}):Play()

	task.delay(3.5, function()
		TweenService:Create(card, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {Position = UDim2.new(1,16,0,0)}):Play()
		task.wait(0.3)
		card:Destroy()
	end)
end

-- ============================================================
-- MAIN WINDOW
-- ============================================================
local main = Instance.new("Frame", gui)
main.Size = UDim2.new(0, 660, 0, 430)
main.Position = UDim2.new(0.5, -330, 0.5, -215)
main.BackgroundColor3 = C.bg
main.Active = true
main.Draggable = true
main.ClipsDescendants = false

Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)

local mainStroke = Instance.new("UIStroke", main)
mainStroke.Color = C.border
mainStroke.Thickness = 1

local topGlow = Instance.new("Frame", main)
topGlow.Size = UDim2.new(1, 0, 0, 1)
topGlow.BackgroundColor3 = C.accentSoft
topGlow.BorderSizePixel = 0
topGlow.ZIndex = 5
topGlow.BackgroundTransparency = 0.3

-- ============================================================
-- TOP BAR
-- ============================================================
local topBar = Instance.new("Frame", main)
topBar.Size = UDim2.new(1, 0, 0, 46)
topBar.BackgroundColor3 = C.surface
topBar.ZIndex = 2
Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 12)

do
	local fix = Instance.new("Frame", topBar)
	fix.Size = UDim2.new(1, 0, 0, 12)
	fix.Position = UDim2.new(0, 0, 1, -12)
	fix.BackgroundColor3 = C.surface
	fix.BorderSizePixel = 0

	local accentLine = Instance.new("Frame", topBar)
	accentLine.Size = UDim2.new(1, 0, 0, 1)
	accentLine.Position = UDim2.new(0, 0, 1, -1)
	accentLine.BackgroundColor3 = C.border
	accentLine.BorderSizePixel = 0

	local sq = Instance.new("Frame", topBar)
	sq.Size = UDim2.new(0, 4, 0, 20)
	sq.Position = UDim2.new(0, 16, 0.5, -10)
	sq.BackgroundColor3 = C.accent
	sq.BorderSizePixel = 0
	Instance.new("UICorner", sq).CornerRadius = UDim.new(0, 2)

	local titleLbl = Instance.new("TextLabel", topBar)
	titleLbl.Position = UDim2.new(0, 28, 0, 0)
	titleLbl.Size = UDim2.new(0, 160, 1, 0)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Text = "ELIXIR 3.5"
	titleLbl.Font = Enum.Font.GothamBlack
	titleLbl.TextSize = 15
	titleLbl.TextColor3 = C.text
	titleLbl.TextXAlignment = Enum.TextXAlignment.Left

	local badge = Instance.new("Frame", topBar)
	badge.Size = UDim2.new(0, 38, 0, 18)
	badge.Position = UDim2.new(0, 190, 0.5, -9)
	badge.BackgroundColor3 = C.accentDim
	badge.BorderSizePixel = 0
	Instance.new("UICorner", badge).CornerRadius = UDim.new(0, 4)
	local badgeTxt = Instance.new("TextLabel", badge)
	badgeTxt.Size = UDim2.new(1,0,1,0)
	badgeTxt.BackgroundTransparency = 1
	badgeTxt.Text = "v3.5"
	badgeTxt.Font = Enum.Font.GothamBold
	badgeTxt.TextSize = 10
	badgeTxt.TextColor3 = C.accentGlow
end

local closeBtn = Instance.new("TextButton", topBar)
closeBtn.Size = UDim2.new(0, 28, 0, 28)
closeBtn.Position = UDim2.new(1, -38, 0.5, -14)
closeBtn.BackgroundColor3 = Color3.fromRGB(50, 15, 22)
closeBtn.Text = "x"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 12
closeBtn.TextColor3 = C.red
closeBtn.BorderSizePixel = 0
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

closeBtn.MouseButton1Click:Connect(function()
	running = false
	autoSellEnabled = false
	notify("Elixir", "Script dihentikan.", "error")
	task.wait(0.4)
	gui:Destroy()
end)

local minBtn = Instance.new("TextButton", topBar)
minBtn.Size = UDim2.new(0, 28, 0, 28)
minBtn.Position = UDim2.new(1, -72, 0.5, -14)
minBtn.BackgroundColor3 = C.card
minBtn.Text = "-"
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 14
minBtn.TextColor3 = C.textMid
minBtn.BorderSizePixel = 0
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 6)

-- ============================================================
-- TEXT SIDEBAR
-- ============================================================
local sidebar = Instance.new("Frame", main)
sidebar.Size = UDim2.new(0, 80, 1, -46)
sidebar.Position = UDim2.new(0, 0, 0, 46)
sidebar.BackgroundColor3 = C.sidebar
sidebar.ZIndex = 2
sidebar.ClipsDescendants = false

local sidebarLine = Instance.new("Frame", main)
sidebarLine.Size = UDim2.new(0, 1, 1, -46)
sidebarLine.Position = UDim2.new(0, 79, 0, 46)
sidebarLine.BackgroundColor3 = C.border
sidebarLine.BorderSizePixel = 0
sidebarLine.ZIndex = 3

local sidebarLayout = Instance.new("UIListLayout", sidebar)
sidebarLayout.Padding = UDim.new(0, 4)
sidebarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
sidebarLayout.VerticalAlignment = Enum.VerticalAlignment.Top
sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder

local sidebarPad = Instance.new("UIPadding", sidebar)
sidebarPad.PaddingTop = UDim.new(0, 10)

-- ============================================================
-- CONTENT AREA
-- ============================================================
local content = Instance.new("Frame", main)
content.Size = UDim2.new(1, -80, 1, -46)
content.Position = UDim2.new(0, 80, 0, 46)
content.BackgroundColor3 = C.panel
content.ClipsDescendants = true
Instance.new("UICorner", content).CornerRadius = UDim.new(0, 0)

local contentFix = Instance.new("Frame", content)
contentFix.Size = UDim2.new(0, 12, 1, 0)
contentFix.BackgroundColor3 = C.panel
contentFix.BorderSizePixel = 0

-- ============================================================
-- TAB SYSTEM
-- ============================================================
local pages = {}
local tabBtns = {}
local currentTab = nil

local tabDefs = {
	{label = "FARM",     order = 1},
	{label = "AUTO",     order = 2},
	{label = "STATUS",   order = 3},
	{label = "TP",       order = 4},
	{label = "ESP",      order = 5},
	{label = "RESPAWN",  order = 6},
	{label = "UNDERPOT", order = 7},
}

local function switchTab(name)
	for n, p in pairs(pages) do
		p.Visible = (n == name)
	end
	for n, b in pairs(tabBtns) do
		if n == name then
			b.BackgroundColor3 = C.accentDim
			b.BackgroundTransparency = 0
			b.TextColor3 = C.accentGlow
		else
			b.BackgroundTransparency = 1
			b.TextColor3 = C.textDim
		end
	end
	currentTab = name
end

for i, def in ipairs(tabDefs) do
	local btn = Instance.new("TextButton", sidebar)
	btn.Size = UDim2.new(0, 68, 0, 36)
	btn.BackgroundTransparency = 1
	btn.Text = def.label
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 10
	btn.TextColor3 = C.textDim
	btn.BorderSizePixel = 0
	btn.LayoutOrder = def.order
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)

	local indicator = Instance.new("Frame", btn)
	indicator.Size = UDim2.new(0, 2, 0, 18)
	indicator.Position = UDim2.new(0, 0, 0.5, -9)
	indicator.BackgroundColor3 = C.accent
	indicator.BorderSizePixel = 0
	indicator.Visible = false
	Instance.new("UICorner", indicator).CornerRadius = UDim.new(0, 2)

	local page = Instance.new("ScrollingFrame", content)
	page.Size = UDim2.new(1, 0, 1, 0)
	page.BackgroundTransparency = 1
	page.ScrollBarThickness = 3
	page.ScrollBarImageColor3 = C.accentSoft
	page.Visible = false
	page.BorderSizePixel = 0

	local layout = Instance.new("UIListLayout", page)
	layout.Padding = UDim.new(0, 7)
	layout.SortOrder = Enum.SortOrder.LayoutOrder

	local pad = Instance.new("UIPadding", page)
	pad.PaddingTop = UDim.new(0, 14)
	pad.PaddingLeft = UDim.new(0, 12)
	pad.PaddingRight = UDim.new(0, 12)
	pad.PaddingBottom = UDim.new(0, 14)

	pages[def.label] = page
	tabBtns[def.label] = btn

	btn.MouseButton1Click:Connect(function()
		switchTab(def.label)
		for _, b2 in pairs(tabBtns) do
			local ind = b2:FindFirstChild("Frame")
			if ind then ind.Visible = (b2 == btn) end
		end
	end)
end

-- ============================================================
-- UI COMPONENT BUILDERS
-- ============================================================
local function sectionLabel(parent, text, order)
	local wrap = Instance.new("Frame", parent)
	wrap.Size = UDim2.new(1, 0, 0, 22)
	wrap.BackgroundTransparency = 1
	wrap.LayoutOrder = order or 0

	local lbl = Instance.new("TextLabel", wrap)
	lbl.Size = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = text:upper()
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 9
	lbl.TextColor3 = C.textDim
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.LayoutOrder = order or 0

	local line = Instance.new("Frame", wrap)
	line.Size = UDim2.new(1, 0, 0, 1)
	line.Position = UDim2.new(0, 0, 1, -1)
	line.BackgroundColor3 = C.border
	line.BorderSizePixel = 0

	return wrap
end

local function card(parent, h, order)
	local f = Instance.new("Frame", parent)
	f.Size = UDim2.new(1, 0, 0, h or 46)
	f.BackgroundColor3 = C.card
	f.BorderSizePixel = 0
	f.LayoutOrder = order or 0
	Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)
	local s = Instance.new("UIStroke", f)
	s.Color = C.border
	s.Thickness = 1
	return f
end

local function makeToggleBtn(parent, text, order)
	local f = card(parent, 38, order)
	local btn = Instance.new("TextButton", f)
	btn.Size = UDim2.new(1, 0, 1, 0)
	btn.BackgroundTransparency = 1
	btn.Font = Enum.Font.GothamSemibold
	btn.TextSize = 12
	btn.TextColor3 = C.text
	btn.Text = text
	btn.BorderSizePixel = 0

	local pill = Instance.new("Frame", f)
	pill.Size = UDim2.new(0, 28, 0, 14)
	pill.Position = UDim2.new(1, -40, 0.5, -7)
	pill.BackgroundColor3 = C.textDim
	pill.BorderSizePixel = 0
	Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)

	local knob = Instance.new("Frame", pill)
	knob.Size = UDim2.new(0, 10, 0, 10)
	knob.Position = UDim2.new(0, 2, 0.5, -5)
	knob.BackgroundColor3 = Color3.new(1,1,1)
	knob.BorderSizePixel = 0
	Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

	local state = false
	local function setToggle(on)
		state = on
		if on then
			TweenService:Create(pill, TweenInfo.new(0.18), {BackgroundColor3 = C.accent}):Play()
			TweenService:Create(knob, TweenInfo.new(0.18), {Position = UDim2.new(1, -12, 0.5, -5)}):Play()
			btn.TextColor3 = C.accentGlow
		else
			TweenService:Create(pill, TweenInfo.new(0.18), {BackgroundColor3 = C.textDim}):Play()
			TweenService:Create(knob, TweenInfo.new(0.18), {Position = UDim2.new(0, 2, 0.5, -5)}):Play()
			btn.TextColor3 = C.text
		end
	end

	btn.MouseButton1Click:Connect(function()
		setToggle(not state)
	end)

	return btn, f, setToggle
end

local function makeActionBtn(parent, text, color, order)
	local f = Instance.new("TextButton", parent)
	f.Size = UDim2.new(1, 0, 0, 36)
	f.BackgroundColor3 = color or C.accentDim
	f.Font = Enum.Font.GothamBold
	f.TextSize = 12
	f.TextColor3 = C.text
	f.Text = text
	f.BorderSizePixel = 0
	f.LayoutOrder = order or 0
	Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)

	local s = Instance.new("UIStroke", f)
	s.Color = C.border
	s.Thickness = 1

	f.MouseEnter:Connect(function()
		TweenService:Create(f, TweenInfo.new(0.12), {BackgroundColor3 = C.accent}):Play()
	end)
	f.MouseLeave:Connect(function()
		TweenService:Create(f, TweenInfo.new(0.12), {BackgroundColor3 = color or C.accentDim}):Play()
	end)
	return f
end

local function makeSlider(parent, labelText, minV, maxV, defaultV, order, callback)
	local wrap = card(parent, 54, order)

	local lbl = Instance.new("TextLabel", wrap)
	lbl.Position = UDim2.new(0, 12, 0, 8)
	lbl.Size = UDim2.new(1, -80, 0, 16)
	lbl.BackgroundTransparency = 1
	lbl.Text = labelText
	lbl.Font = Enum.Font.GothamSemibold
	lbl.TextSize = 11
	lbl.TextColor3 = C.textMid
	lbl.TextXAlignment = Enum.TextXAlignment.Left

	local valLbl = Instance.new("TextLabel", wrap)
	valLbl.Position = UDim2.new(1, -52, 0, 8)
	valLbl.Size = UDim2.new(0, 42, 0, 16)
	valLbl.BackgroundTransparency = 1
	valLbl.Text = tostring(defaultV)
	valLbl.Font = Enum.Font.GothamBold
	valLbl.TextSize = 12
	valLbl.TextColor3 = C.accentGlow
	valLbl.TextXAlignment = Enum.TextXAlignment.Right

	local track = Instance.new("Frame", wrap)
	track.Position = UDim2.new(0, 12, 0, 34)
	track.Size = UDim2.new(1, -24, 0, 5)
	track.BackgroundColor3 = C.border
	track.BorderSizePixel = 0
	track.Active = true
	Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

	local fill2 = Instance.new("Frame", track)
	fill2.Size = UDim2.new((defaultV - minV)/(maxV - minV), 0, 1, 0)
	fill2.BackgroundColor3 = C.accent
	fill2.BorderSizePixel = 0
	Instance.new("UICorner", fill2).CornerRadius = UDim.new(1, 0)

	local knob2 = Instance.new("Frame", track)
	local kp = (defaultV - minV)/(maxV - minV)
	knob2.Size = UDim2.new(0, 14, 0, 14)
	knob2.Position = UDim2.new(kp, -7, 0.5, -7)
	knob2.BackgroundColor3 = Color3.new(1,1,1)
	knob2.BorderSizePixel = 0
	Instance.new("UICorner", knob2).CornerRadius = UDim.new(1, 0)

	local ks = Instance.new("UIStroke", knob2)
	ks.Color = C.accent
	ks.Thickness = 2

	local dragging = false

	local function update(x)
		local pos = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
		local val = math.floor(minV + pos * (maxV - minV))
		knob2.Position = UDim2.new(pos, -7, 0.5, -7)
		fill2.Size = UDim2.new(pos, 0, 1, 0)
		valLbl.Text = tostring(val)
		if callback then callback(val) end
	end

	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			update(input.Position.X)
		end
	end)

	UIS.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			update(input.Position.X)
		end
	end)

	UIS.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	return wrap, valLbl
end

local function makeStatusRow(parent, label, order)
	local f = card(parent, 30, order)

	local lbl2 = Instance.new("TextLabel", f)
	lbl2.Position = UDim2.new(0, 12, 0, 0)
	lbl2.Size = UDim2.new(0.6, 0, 1, 0)
	lbl2.BackgroundTransparency = 1
	lbl2.Text = label
	lbl2.Font = Enum.Font.GothamSemibold
	lbl2.TextSize = 11
	lbl2.TextColor3 = C.textMid
	lbl2.TextXAlignment = Enum.TextXAlignment.Left

	local val2 = Instance.new("TextLabel", f)
	val2.Position = UDim2.new(0.6, 0, 0, 0)
	val2.Size = UDim2.new(0.4, -10, 1, 0)
	val2.BackgroundTransparency = 1
	val2.Text = "0"
	val2.Font = Enum.Font.GothamBold
	val2.TextSize = 12
	val2.TextColor3 = C.accentGlow
	val2.TextXAlignment = Enum.TextXAlignment.Right

	return val2, f
end

-- ============================================================
-- FARM PAGE
-- ============================================================
local fp = pages["FARM"]

sectionLabel(fp, "Status", 1)

local statusCard = card(fp, 36, 2)
local statusLabel = Instance.new("TextLabel", statusCard)
statusLabel.Size = UDim2.new(1, -20, 1, 0)
statusLabel.Position = UDim2.new(0, 12, 0, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "IDLE"
statusLabel.Font = Enum.Font.GothamBold
statusLabel.TextSize = 12
statusLabel.TextColor3 = C.textMid
statusLabel.TextXAlignment = Enum.TextXAlignment.Left

sectionLabel(fp, "Inventory", 3)

local waterVal, _  = makeStatusRow(fp, "Water",            4)
local sugarVal, _  = makeStatusRow(fp, "Sugar Block Bag",  5)
local gelatinVal,_ = makeStatusRow(fp, "Gelatin",          6)
local bagVal, _    = makeStatusRow(fp, "Empty Bag",        7)

sectionLabel(fp, "Controls", 8)

local buySliderWrap, buyValLbl = makeSlider(fp, "BUY AMOUNT", 1, 25, 1, 9, function(v)
	buyAmount = v
end)

local farmToggleBtn = makeActionBtn(fp, "START FARM", C.accentDim, 10)
local sellToggleBtn = makeActionBtn(fp, "AUTO SELL : OFF", C.card, 11)
local buyNowBtn     = makeActionBtn(fp, "BUY NOW", C.card, 12)

sectionLabel(fp, "Cook Progress", 13)

local function makeProgressCard(label, order)
	local f = card(fp, 34, order)
	local lbl3 = Instance.new("TextLabel", f)
	lbl3.Position = UDim2.new(0, 10, 0, 5)
	lbl3.Size = UDim2.new(0.6, 0, 0, 13)
	lbl3.BackgroundTransparency = 1
	lbl3.Text = label
	lbl3.Font = Enum.Font.GothamSemibold
	lbl3.TextSize = 10
	lbl3.TextColor3 = C.textMid
	lbl3.TextXAlignment = Enum.TextXAlignment.Left
	local bg2 = Instance.new("Frame", f)
	bg2.Position = UDim2.new(0, 10, 0, 22)
	bg2.Size = UDim2.new(1, -20, 0, 5)
	bg2.BackgroundColor3 = C.border
	bg2.BorderSizePixel = 0
	Instance.new("UICorner", bg2).CornerRadius = UDim.new(1, 0)
	local bar2 = Instance.new("Frame", bg2)
	bar2.Size = UDim2.new(0, 0, 1, 0)
	bar2.BackgroundColor3 = C.accent
	bar2.BorderSizePixel = 0
	Instance.new("UICorner", bar2).CornerRadius = UDim.new(1, 0)
	return bar2
end

local waterBar   = makeProgressCard("Water (20s)",   14)
local sugarBar   = makeProgressCard("Sugar (1s)",    15)
local gelatinBar = makeProgressCard("Gelatin (1s)",  16)
local bagBar     = makeProgressCard("Bag (45s)",     17)

-- ============================================================
-- AUTO PAGE
-- ============================================================
local ap = pages["AUTO"]

sectionLabel(ap, "Auto Farm", 1)

local autoFarmToggle, autoFarmCard = makeToggleBtn(ap, "Auto Farm Loop", 2)
autoFarmCard.Size = UDim2.new(1,0,0,42)

local _, cookValLbl = makeSlider(ap, "COOK AMOUNT", 1, 50, 5, 3, function(v)
	cookAmount = v
end)

sectionLabel(ap, "Protection", 4)
local antiHitToggle, antiHitCard = makeToggleBtn(ap, "Anti Hit + Anti Approach", 5)
antiHitCard.Size = UDim2.new(1,0,0,42)

local antiStatusCard = card(ap, 30, 6)
local antiStatusLbl = Instance.new("TextLabel", antiStatusCard)
antiStatusLbl.Size = UDim2.new(1,-20,1,0)
antiStatusLbl.Position = UDim2.new(0,12,0,0)
antiStatusLbl.BackgroundTransparency = 1
antiStatusLbl.Text = "Idle"
antiStatusLbl.Font = Enum.Font.Gotham
antiStatusLbl.TextSize = 11
antiStatusLbl.TextColor3 = C.textMid
antiStatusLbl.TextXAlignment = Enum.TextXAlignment.Left

-- ============================================================
-- STATUS PAGE
-- ============================================================
local sp = pages["STATUS"]

local avatarCard = card(sp, 70, 1)
local avatarImg2 = Instance.new("ImageLabel", avatarCard)
avatarImg2.Position = UDim2.new(0, 10, 0.5, -26)
avatarImg2.Size = UDim2.new(0, 52, 0, 52)
avatarImg2.BackgroundColor3 = C.border
avatarImg2.BorderSizePixel = 0
Instance.new("UICorner", avatarImg2).CornerRadius = UDim.new(0, 8)

local usernameLbl = Instance.new("TextLabel", avatarCard)
usernameLbl.Position = UDim2.new(0, 72, 0, 14)
usernameLbl.Size = UDim2.new(1, -82, 0, 20)
usernameLbl.BackgroundTransparency = 1
usernameLbl.Text = player.Name
usernameLbl.Font = Enum.Font.GothamBlack
usernameLbl.TextSize = 15
usernameLbl.TextColor3 = C.text
usernameLbl.TextXAlignment = Enum.TextXAlignment.Left

local displayLbl = Instance.new("TextLabel", avatarCard)
displayLbl.Position = UDim2.new(0, 72, 0, 36)
displayLbl.Size = UDim2.new(1, -82, 0, 14)
displayLbl.BackgroundTransparency = 1
displayLbl.Text = "@" .. player.DisplayName
displayLbl.Font = Enum.Font.Gotham
displayLbl.TextSize = 11
displayLbl.TextColor3 = C.textDim
displayLbl.TextXAlignment = Enum.TextXAlignment.Left

task.spawn(function()
	local img, _ = Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
	avatarImg2.Image = img
end)

sectionLabel(sp, "Inventory", 2)
local statWaterVal   = makeStatusRow(sp, "Water",           3)
local statSugarVal   = makeStatusRow(sp, "Sugar Block Bag", 4)
local statGelatinVal = makeStatusRow(sp, "Gelatin",         5)
local statBagVal     = makeStatusRow(sp, "Empty Bag",       6)

sectionLabel(sp, "Marshmallow Bags", 7)
local statSmallVal  = makeStatusRow(sp, "Small Bag",  8)
local statMedVal    = makeStatusRow(sp, "Medium Bag", 9)
local statLargeVal  = makeStatusRow(sp, "Large Bag",  10)

local totalCard = card(sp, 36, 11)
local totalLblLeft = Instance.new("TextLabel", totalCard)
totalLblLeft.Position = UDim2.new(0,12,0,0)
totalLblLeft.Size = UDim2.new(0.5,0,1,0)
totalLblLeft.BackgroundTransparency = 1
totalLblLeft.Text = "Total Bags"
totalLblLeft.Font = Enum.Font.GothamBold
totalLblLeft.TextSize = 12
totalLblLeft.TextColor3 = C.text
totalLblLeft.TextXAlignment = Enum.TextXAlignment.Left

local totalVal = Instance.new("TextLabel", totalCard)
totalVal.Position = UDim2.new(0.5,0,0,0)
totalVal.Size = UDim2.new(0.5,-12,1,0)
totalVal.BackgroundTransparency = 1
totalVal.Text = "0"
totalVal.Font = Enum.Font.GothamBlack
totalVal.TextSize = 15
totalVal.TextColor3 = C.accentGlow
totalVal.TextXAlignment = Enum.TextXAlignment.Right

-- ============================================================
-- TELEPORT PAGE
-- ============================================================
local tp = pages["TP"]

do
	local apart1 = CFrame.new(1140.319091796875,10.105062484741211,450.2520446777344)*CFrame.new(0,2,0)
	local apart2 = CFrame.new(1141.39099,10.1050625,422.805542)*CFrame.new(0,2,0)
	local apart3 = CFrame.new(986.987305,10.1050644,248.435837)*CFrame.new(0,2,0)
	local apart4 = CFrame.new(986.299194,10.1050644,219.940186)*CFrame.new(0,2,0)
	local apart5 = CFrame.new(924.781006,10.1050644,41.1367264)*CFrame.Angles(0,math.rad(90),0)
	local apart6 = CFrame.new(896.671997,10.1050644,40.6403999)*CFrame.Angles(0,math.rad(90),0)
	local csn1 = CFrame.new(1178.8331298828125,3.95,-227.3722381591797)
	local csn2 = CFrame.new(1205.0880126953125,3.95,-220.54200744628906)
	local csn3 = CFrame.new(1204.281005859375,3.7122225761413574,-182.851318359375)
	local csn4 = CFrame.new(1178.5850830078125,3.712223529815674,-189.7107696533203)

	local function tpBtn(label, cf, order)
		local b = makeActionBtn(tp, label, C.card, order)
		b.MouseButton1Click:Connect(function()
			notify("Teleport", "Menuju "..label.."...", "info")
			showLoading("Menuju " .. label)
			vehicleTeleport(cf)
			hideLoading()
			notify("Teleport", "Tiba di "..label, "success")
		end)
	end

	sectionLabel(tp, "Quick", 1)
	tpBtn("NPC Store",  npcPos, 2)
	tpBtn("Tier",       tierPos, 3)
	sectionLabel(tp, "Apartments", 4)
	tpBtn("Apart 1", apart1, 5)
	tpBtn("Apart 2", apart2, 6)
	tpBtn("Apart 3", apart3, 7)
	tpBtn("Apart 4", apart4, 8)
	tpBtn("Apart 5", apart5, 9)
	tpBtn("Apart 6", apart6, 10)
	sectionLabel(tp, "CSN", 11)
	tpBtn("CSN 1", csn1, 12)
	tpBtn("CSN 2", csn2, 13)
	tpBtn("CSN 3", csn3, 14)
	tpBtn("CSN 4", csn4, 15)
end

-- ============================================================
-- ESP PAGE
-- ============================================================
local ep = pages["ESP"]

local MaxDistance = 500
local Enabled = false
local ShowName = true
local ShowHealth = true
local ShowDistance = true

sectionLabel(ep, "ESP Settings", 1)

local espToggle, espCard, setEsp = makeToggleBtn(ep, "ESP Enabled", 2)
espCard.Size = UDim2.new(1,0,0,42)

do
	local nameToggle, nameCard, setName = makeToggleBtn(ep, "Show Names", 3)
	nameCard.Size = UDim2.new(1,0,0,42)
	setName(true)
	nameToggle.MouseButton1Click:Connect(function() ShowName = not ShowName end)

	local healthToggle, healthCard, setHealth = makeToggleBtn(ep, "Show Health Bar", 4)
	healthCard.Size = UDim2.new(1,0,0,42)
	setHealth(true)
	healthToggle.MouseButton1Click:Connect(function() ShowHealth = not ShowHealth end)

	local distToggle, distCard, setDist = makeToggleBtn(ep, "Show Distance", 5)
	distCard.Size = UDim2.new(1,0,0,42)
	setDist(true)
	distToggle.MouseButton1Click:Connect(function() ShowDistance = not ShowDistance end)
end

makeSlider(ep, "MAX DISTANCE", 50, 8000, 500, 6, function(v)
	MaxDistance = v
end)

espToggle.MouseButton1Click:Connect(function()
	Enabled = not Enabled
	setEsp(Enabled)
	notify("ESP", Enabled and "ESP diaktifkan" or "ESP dimatikan", Enabled and "success" or "error")
end)

-- ============================================================
-- RESPAWN PAGE
-- ============================================================
local rp = pages["RESPAWN"]

local selectedSpawn = nil

local respStatusCard = card(rp, 36, 1)
local respStatusLbl = Instance.new("TextLabel", respStatusCard)
respStatusLbl.Size = UDim2.new(1,-20,1,0)
respStatusLbl.Position = UDim2.new(0,12,0,0)
respStatusLbl.BackgroundTransparency = 1
respStatusLbl.Text = "Belum dipilih"
respStatusLbl.Font = Enum.Font.GothamSemibold
respStatusLbl.TextSize = 11
respStatusLbl.TextColor3 = C.textMid
respStatusLbl.TextXAlignment = Enum.TextXAlignment.Left

sectionLabel(rp, "Pilih Spawn", 2)

local spawnBtns = {}
local function makeSpawnBtn2(name, pos, order)
	local b = makeActionBtn(rp, name, C.card, order)
	b.MouseButton1Click:Connect(function()
		selectedSpawn = pos
		for _, sb in pairs(spawnBtns) do
			TweenService:Create(sb, TweenInfo.new(0.15), {BackgroundColor3 = C.card}):Play()
		end
		TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = C.accentDim}):Play()
		respStatusLbl.Text = name
		notify("Spawn", name .. " dipilih", "success")
	end)
	table.insert(spawnBtns, b)
end

makeSpawnBtn2("Dealer",     Vector3.new(511,3,601),         3)
makeSpawnBtn2("RS 1",       Vector3.new(1140.8,10.1,451.8), 4)
makeSpawnBtn2("RS 2",       Vector3.new(1141.2,10.1,423.2), 5)
makeSpawnBtn2("Tier 1",     Vector3.new(985.9,10.1,247),    6)
makeSpawnBtn2("Tier 2",     Vector3.new(989.3,11.0,228.3),  7)
makeSpawnBtn2("Trash 1",    Vector3.new(890.9,10.1,44.3),   8)
makeSpawnBtn2("Trash 2",    Vector3.new(920.4,10.1,46.3),   9)
makeSpawnBtn2("Dealership", Vector3.new(733.5,4.6,431.9),   10)
makeSpawnBtn2("GS Ujung",   Vector3.new(-467.1,4.8,353.5),  11)
makeSpawnBtn2("GS Mid",     Vector3.new(218.7,3.7,-176.2),  12)

local respawnBtn = makeActionBtn(rp, "RESPAWN SEKARANG", C.accent, 13)

respawnBtn.MouseButton1Click:Connect(function()
	if not selectedSpawn then
		notify("Respawn", "Pilih spawn terlebih dulu!", "error")
		return
	end
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	notify("Respawn", "Sedang respawn...", "info")
	local StarterGui = game:GetService("StarterGui")
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
	showLoading("Sedang Respawn")
	task.wait(0.3)
	hum.Health = 0
	task.wait(0.2)
	player.CharacterAdded:Wait()
	task.wait(1)
	local newChar = player.Character
	local hrp = newChar and newChar:FindFirstChild("HumanoidRootPart")
	if hrp then
		hrp.CFrame = CFrame.new(selectedSpawn)
		task.wait(0.3)
	end
	hideLoading()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
	notify("Respawn", "Berhasil respawn!", "success")
	respStatusLbl.Text = "Respawn berhasil!"
end)

-- ============================================================
-- UNDERPOT PAGE
-- ============================================================
local up = pages["UNDERPOT"]

-- Variables
local deletedStack = {}
local originalPositions = {}
local currentRoadOffset = 0
local isDeleting = false
getgenv().LOWER_ROAD = false

local scannedPrompts = {}
local SCAN_RADIUS = 50
local ROAD_DEPTH = 6

local ROAD_KEYWORDS = {
	"road","street","sidewalk","pavement","asphalt",
	"ground","floor","path","lane","crossing",
	"jalan","trotoar","jalanan"
}

-- Status card
local upStatusCard = card(up, 36, 1)
local upStatusLbl = Instance.new("TextLabel", upStatusCard)
upStatusLbl.Size = UDim2.new(1,-20,1,0)
upStatusLbl.Position = UDim2.new(0,12,0,0)
upStatusLbl.BackgroundTransparency = 1
upStatusLbl.Text = "Idle"
upStatusLbl.Font = Enum.Font.GothamSemibold
upStatusLbl.TextSize = 11
upStatusLbl.TextColor3 = C.textMid
upStatusLbl.TextXAlignment = Enum.TextXAlignment.Left

local upUndoCard = card(up, 30, 2)
local upUndoLbl = Instance.new("TextLabel", upUndoCard)
upUndoLbl.Size = UDim2.new(1,-20,1,0)
upUndoLbl.Position = UDim2.new(0,12,0,0)
upUndoLbl.BackgroundTransparency = 1
upUndoLbl.Text = "Undo Stack: 0 object"
upUndoLbl.Font = Enum.Font.Gotham
upUndoLbl.TextSize = 11
upUndoLbl.TextColor3 = C.textDim
upUndoLbl.TextXAlignment = Enum.TextXAlignment.Left

-- Section: Lower
sectionLabel(up, "Lower Road (depth: 6)", 3)

local lowerRoadBtn = makeActionBtn(up, "LOWER : OFF", Color3.fromRGB(60, 20, 140), 4)

-- Section: Delete Floor
sectionLabel(up, "Delete Floor", 5)

local deleteFloorBtn = makeActionBtn(up, "DELETE FLOOR DI BAWAH", Color3.fromRGB(120, 20, 50), 6)
local undoFloorBtn   = makeActionBtn(up, "UNDO", C.card, 7)

-- Section: Prompt Scanner
sectionLabel(up, "Prompt Scanner (radius: 50)", 8)

local upPromptCountCard = card(up, 30, 9)
local upPromptCountLbl = Instance.new("TextLabel", upPromptCountCard)
upPromptCountLbl.Size = UDim2.new(1,-20,1,0)
upPromptCountLbl.Position = UDim2.new(0,12,0,0)
upPromptCountLbl.BackgroundTransparency = 1
upPromptCountLbl.Text = "0 prompt ditemukan"
upPromptCountLbl.Font = Enum.Font.Gotham
upPromptCountLbl.TextSize = 11
upPromptCountLbl.TextColor3 = C.textDim
upPromptCountLbl.TextXAlignment = Enum.TextXAlignment.Left

local findCookBtn    = makeActionBtn(up, "FIND COOK", Color3.fromRGB(0, 100, 80), 10)
local restoreCookBtn = makeActionBtn(up, "RESTORE COOK", C.card, 11)

-- ============================================================
-- UNDERPOT LOGIC
-- ============================================================
local function isRoadPart(part)
	if not part:IsA("BasePart") and not part:IsA("UnionOperation") then return false end
	local nameLower = part.Name:lower()
	for _, kw in pairs(ROAD_KEYWORDS) do
		if nameLower:find(kw) then return true end
	end
	if part.Parent then
		local parentName = part.Parent.Name:lower()
		for _, kw in pairs(ROAD_KEYWORDS) do
			if parentName:find(kw) then return true end
		end
	end
	return false
end

local function lowerAllRoads()
	local count = 0
	originalPositions = {}
	currentRoadOffset = ROAD_DEPTH
	upStatusLbl.Text = "Mencari jalanan..."
	task.wait(0.1)
	for _, obj in pairs(workspace:GetDescendants()) do
		if isRoadPart(obj) then
			originalPositions[obj] = obj.CFrame
			obj.CFrame = obj.CFrame * CFrame.new(0, -ROAD_DEPTH, 0)
			count += 1
		end
	end
	local char = player.Character
	if char then
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if hrp then hrp.CFrame = hrp.CFrame * CFrame.new(0, -ROAD_DEPTH, 0) end
	end
	upStatusLbl.Text = count .. " part jalan diturunkan -6Y"
end

local function restoreAllRoads()
	local count = 0
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	for part, originalCF in pairs(originalPositions) do
		if part and part.Parent then
			part.CFrame = originalCF
			count += 1
		end
	end
	if hrp and currentRoadOffset ~= 0 then
		hrp.CFrame = CFrame.new(hrp.Position.X, hrp.Position.Y + currentRoadOffset, hrp.Position.Z)
		hrp.AssemblyLinearVelocity = Vector3.zero
	end
	originalPositions = {}
	currentRoadOffset = 0
	upStatusLbl.Text = count .. " part jalan dikembalikan"
end

lowerRoadBtn.MouseButton1Click:Connect(function()
	getgenv().LOWER_ROAD = not getgenv().LOWER_ROAD
	if getgenv().LOWER_ROAD then
		lowerRoadBtn.Text = "LOWER : ON"
		TweenService:Create(lowerRoadBtn, TweenInfo.new(0.2), {BackgroundColor3 = C.green}):Play()
		notify("Lower", "Jalan diturunkan!", "success")
		task.spawn(lowerAllRoads)
	else
		lowerRoadBtn.Text = "LOWER : OFF"
		TweenService:Create(lowerRoadBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(60, 20, 140)}):Play()
		restoreAllRoads()
		notify("Lower", "Jalan dikembalikan.", "error")
	end
end)

undoFloorBtn.MouseButton1Click:Connect(function()
	local last = table.remove(deletedStack)
	if last and last.object then
		last.object.Parent = last.parent
		upUndoLbl.Text = "Undo Stack: " .. #deletedStack .. " object"
		upStatusLbl.Text = "Undo berhasil"
		notify("Delete", "Undo berhasil!", "success")
	else
		upStatusLbl.Text = "Tidak ada yang bisa di-undo"
		notify("Delete", "Tidak ada yang bisa di-undo.", "error")
	end
end)

deleteFloorBtn.MouseButton1Click:Connect(function()
	if isDeleting then return end
	isDeleting = true
	deleteFloorBtn.Text = "Memproses..."
	TweenService:Create(deleteFloorBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(60, 0, 30)}):Play()

	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then
		upStatusLbl.Text = "HumanoidRootPart tidak ada"
		isDeleting = false
		deleteFloorBtn.Text = "DELETE FLOOR DI BAWAH"
		TweenService:Create(deleteFloorBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(120, 20, 50)}):Play()
		return
	end

	upStatusLbl.Text = "Mencari object di bawah..."

	local rayOrigin = hrp.Position
	local rayDir = Vector3.new(0, -15, 0)
	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = {char}
	rayParams.FilterType = Enum.RaycastFilterType.Exclude

	local result = workspace:Raycast(rayOrigin, rayDir, rayParams)
	if result and result.Instance then
		local hit = result.Instance
		if hit and hit.Parent then
			table.insert(deletedStack, {object = hit:Clone(), parent = hit.Parent})
			hit:Destroy()
			upUndoLbl.Text = "Undo Stack: " .. #deletedStack .. " object"
			upStatusLbl.Text = "Deleted: " .. hit.Name
			notify("Delete", "Part dihapus!", "success")
		end
	else
		upStatusLbl.Text = "Tidak ada object di bawah"
		notify("Delete", "Tidak ada object terdeteksi.", "error")
	end

	task.wait(0.3)
	isDeleting = false
	deleteFloorBtn.Text = "DELETE FLOOR DI BAWAH"
	TweenService:Create(deleteFloorBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(120, 20, 50)}):Play()
end)

-- Prompt Scanner Logic
local function getPromptPosition(prompt)
	local p = prompt.Parent
	if not p then return nil end
	if p:IsA("BasePart") then return p.Position end
	if p:IsA("Attachment") then return p.WorldPosition end
	if p:IsA("Model") then
		if p.PrimaryPart then return p.PrimaryPart.Position end
		for _, child in ipairs(p:GetDescendants()) do
			if child:IsA("BasePart") then return child.Position end
		end
	end
	local gp = p.Parent
	if gp then
		if gp:IsA("BasePart") then return gp.Position end
		if gp:IsA("Model") then
			if gp.PrimaryPart then return gp.PrimaryPart.Position end
			for _, child in ipairs(gp:GetDescendants()) do
				if child:IsA("BasePart") then return child.Position end
			end
		end
	end
	return nil
end

local function doPromptScan()
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then upStatusLbl.Text = "HumanoidRootPart tidak ada" return end

	for prompt, data in pairs(scannedPrompts) do
		if prompt and prompt.Parent then
			prompt.MaxActivationDistance = data.maxDist
			prompt.RequiresLineOfSight   = data.lineOfSight
			prompt.Enabled               = data.enabled
			prompt.HoldDuration          = data.holdDuration
		end
	end
	scannedPrompts = {}

	upStatusLbl.Text = "Scanning prompt..."
	local found = 0

	for _, v in ipairs(workspace:GetDescendants()) do
		if v:IsA("ProximityPrompt") then
			local pos = getPromptPosition(v)
			if pos then
				local dist = (hrp.Position - pos).Magnitude
				if dist <= SCAN_RADIUS then
					scannedPrompts[v] = {
						maxDist      = v.MaxActivationDistance,
						lineOfSight  = v.RequiresLineOfSight,
						enabled      = v.Enabled,
						holdDuration = v.HoldDuration,
					}
					v.Enabled               = true
					v.MaxActivationDistance = 20
					v.RequiresLineOfSight   = false
					v.HoldDuration          = 0
					found += 1
				end
			end
		end
	end

	upPromptCountLbl.Text = found .. " prompt ditemukan"
	upStatusLbl.Text = "Scan: " .. found .. " prompt dimodifikasi"
end

local function doRestorePrompts()
	local count = 0
	for prompt, data in pairs(scannedPrompts) do
		if prompt and prompt.Parent then
			prompt.MaxActivationDistance = data.maxDist
			prompt.RequiresLineOfSight   = data.lineOfSight
			prompt.Enabled               = data.enabled
			prompt.HoldDuration          = data.holdDuration
			count += 1
		end
	end
	scannedPrompts = {}
	upPromptCountLbl.Text = "0 prompt ditemukan"
	upStatusLbl.Text = count .. " prompt di-restore"
end

findCookBtn.MouseButton1Click:Connect(function()
	findCookBtn.Text = "Scanning..."
	TweenService:Create(findCookBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(0, 60, 50)}):Play()
	task.spawn(function()
		doPromptScan()
		notify("Prompt", upPromptCountLbl.Text, "success")
		task.wait(0.3)
		findCookBtn.Text = "FIND COOK"
		TweenService:Create(findCookBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(0, 100, 80)}):Play()
	end)
end)

restoreCookBtn.MouseButton1Click:Connect(function()
	doRestorePrompts()
	notify("Prompt", "Prompt di-restore.", "info")
end)

-- ============================================================
-- FARM LOGIC
-- ============================================================
local function cook()
	while running do
		if equip("Water") then
			statusLabel.Text = "Cooking Water..."
			statusLabel.TextColor3 = C.accentGlow
			if waterBar then fill(waterBar, 20) end
			holdE(.7)
			task.wait(20)
		end
		if equip("Sugar Block Bag") then
			statusLabel.Text = "Cooking Sugar..."
			if sugarBar then fill(sugarBar, 1) end
			holdE(.7)
			task.wait(1)
		end
		if equip("Gelatin") then
			statusLabel.Text = "Cooking Gelatin..."
			if gelatinBar then fill(gelatinBar, 1) end
			holdE(.7)
			task.wait(1)
		end
		statusLabel.Text = "Waiting..."
		if bagBar then fill(bagBar, 45) end
		task.wait(45)
		if equip("Empty Bag") then
			statusLabel.Text = "Collecting..."
			holdE(.7)
			task.wait(1)
		end
	end
	statusLabel.Text = "IDLE"
	statusLabel.TextColor3 = C.textMid
end

local buying = false
local function autoBuy()
	if buying then return end
	buying = true
	notify("Buy", "Membeli x" .. buyAmount, "info")
	for i = 1, buyAmount do
		buyRemote:FireServer("Water") task.wait(.35)
		buyRemote:FireServer("Sugar Block Bag") task.wait(.35)
		buyRemote:FireServer("Gelatin") task.wait(.35)
		buyRemote:FireServer("Empty Bag") task.wait(.45)
	end
	notify("Buy", "Selesai beli x" .. buyAmount, "success")
	buying = false
end

local function autoSell()
	local bags = {"Small Marshmallow Bag","Medium Marshmallow Bag","Large Marshmallow Bag"}
	for _,bag in pairs(bags) do
		while countItem(bag) > 0 and autoSellEnabled do
			if equip(bag) then holdE(.7) task.wait(1)
			else break end
		end
	end
	notify("Sell", "Semua bag terjual!", "success")
end

farmToggleBtn.MouseButton1Click:Connect(function()
	autoFarmRunning = false
	autoFarmStopping = true
	running = not running
	if running then
		farmToggleBtn.Text = "STOP FARM"
		TweenService:Create(farmToggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = C.red}):Play()
		notify("Farm", "Auto farm dimulai!", "success")
		task.spawn(cook)
	else
		farmToggleBtn.Text = "START FARM"
		TweenService:Create(farmToggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = C.accentDim}):Play()
		notify("Farm", "Auto farm dihentikan.", "error")
	end
end)

buyNowBtn.MouseButton1Click:Connect(function()
	task.spawn(autoBuy)
end)

sellToggleBtn.MouseButton1Click:Connect(function()
	autoSellEnabled = not autoSellEnabled
	if autoSellEnabled then
		sellToggleBtn.Text = "AUTO SELL : ON"
		TweenService:Create(sellToggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = C.accentDim}):Play()
		notify("Sell", "Auto sell aktif!", "success")
		task.spawn(autoSell)
	else
		sellToggleBtn.Text = "AUTO SELL : OFF"
		TweenService:Create(sellToggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = C.card}):Play()
	end
end)

-- ============================================================
-- AUTO FARM (full v2 logic)
-- ============================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local function getChar() return player.Character or player.CharacterAdded:Wait() end
local function getHumanoid() return getChar():WaitForChild("Humanoid") end
local function getHRP() return getChar():FindFirstChild("HumanoidRootPart") end
local buyRemoteV2 = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("StorePurchase")
local farmID = 0
local storePos = Vector3.new(510.7584,3.5872,600.3163)

local function freezeVehicle(vehicle)
	if not vehicle or not vehicle.PrimaryPart then return end
	local p = vehicle.PrimaryPart
	p.AssemblyLinearVelocity = Vector3.zero
	p.AssemblyAngularVelocity = Vector3.zero
	p.Velocity = Vector3.zero
	p.RotVelocity = Vector3.zero
end

local function pressE(d)
	d = d or 0.8
	vim:SendKeyEvent(true,"E",false,game)
	task.wait(d)
	vim:SendKeyEvent(false,"E",false,game)
end

local function equipV2(name)
	if autoFarmStopping then return end
	local char = getChar()
	local tool = player.Backpack:FindFirstChild(name) or char:FindFirstChild(name)
	if tool then getHumanoid():EquipTool(tool) task.wait(.25) return true end
end

local function countItemV2(name)
	local total = 0
	for _,v in pairs(player.Backpack:GetChildren()) do if v.Name == name then total += 1 end end
	for _,v in pairs(getChar():GetChildren()) do if v:IsA("Tool") and v.Name == name then total += 1 end end
	return total
end

local function autoBuyV2()
	for i = 1, cookAmount do
		if not autoFarmRunning or autoFarmStopping then break end
		buyRemoteV2:FireServer("Water") task.wait(0.35)
		buyRemoteV2:FireServer("Sugar Block Bag") task.wait(0.35)
		buyRemoteV2:FireServer("Gelatin") task.wait(0.35)
		buyRemoteV2:FireServer("Empty Bag") task.wait(0.35)
	end
end

local function findStove()
	local hrp = getHRP()
	if not hrp then return end
	local nearest, dist = nil, math.huge
	for _,v in pairs(workspace:GetDescendants()) do
		if v:IsA("BasePart") and string.find(v.Name:lower(),"stove") then
			local d = (v.Position - hrp.Position).Magnitude
			if d < dist then dist = d nearest = v end
		end
	end
	return nearest
end

local function vehicleTP(target)
	if autoFarmStopping then return end
	showLoading("Auto Farm")
	local seat = getHumanoid().SeatPart
	if not seat then hideLoading() return end
	local vehicle = seat:FindFirstAncestorOfClass("Model")
	if not vehicle then hideLoading() return end
	if not vehicle.PrimaryPart then vehicle.PrimaryPart = seat end
	local rot = vehicle.PrimaryPart.CFrame - vehicle.PrimaryPart.Position
	vehicle:SetPrimaryPartCFrame(CFrame.new(target + Vector3.new(0,2,0)) * rot)
	freezeVehicle(vehicle)
	task.wait(0.25)
	vehicle:SetPrimaryPartCFrame(CFrame.new(target) * rot)
	freezeVehicle(vehicle)
	task.wait(0.4)
	hideLoading()
end

local function moveToStove(stove)
	if not stove or autoFarmStopping then return end
	local seat = getHumanoid().SeatPart
	if not seat then return end
	local vehicle = seat:FindFirstAncestorOfClass("Model")
	if not vehicle or not vehicle.PrimaryPart then return end
	local hrp = getHRP()
	if not hrp then return end
	local dir = (stove.Position - hrp.Position).Unit
	local targetPos = stove.Position - (dir * 3.5) + Vector3.new(0,1.5,0)
	local _, y, _ = vehicle.PrimaryPart.CFrame:ToOrientation()
	vehicle:SetPrimaryPartCFrame(CFrame.new(targetPos) * CFrame.Angles(0,y,0))
	freezeVehicle(vehicle)
	task.wait(0.4)
end

local function cookV2()
	if not autoFarmRunning or autoFarmStopping then return end
	local stove = findStove()
	moveToStove(stove)
	for i = 1, cookAmount do
		if autoFarmStopping then return end
		if autoFarmRunning and equipV2("Water") then pressE() task.wait(20) end
		if autoFarmRunning and equipV2("Sugar Block Bag") then task.wait(0.25) pressE(1) task.wait(1.3) end
		if autoFarmRunning and equipV2("Gelatin") then task.wait(0.25) pressE(1) task.wait(1.3) end
		task.wait(45)
		if autoFarmRunning and equipV2("Empty Bag") then pressE() task.wait(1.5) end
	end
end

local function autoSellV2()
	local bags = {"Small Marshmallow Bag","Medium Marshmallow Bag","Large Marshmallow Bag"}
	for _,bag in pairs(bags) do
		while autoFarmRunning and not autoFarmStopping and countItemV2(bag) > 0 do
			if equipV2(bag) then pressE() task.wait(0.8)
			else break end
		end
	end
end

local function farmLoop(id)
	local hrp = getHRP()
	if not hrp then return end
	local apartPos = hrp.Position
	while id == farmID and autoFarmRunning and not autoFarmStopping do
		vehicleTP(storePos)
		task.wait(0.5)
		autoBuyV2()
		task.wait(1)
		vehicleTP(apartPos)
		task.wait(1.2)
		cookV2()
		vehicleTP(storePos)
		task.wait(0.5)
		autoSellV2()
		task.wait(0.5)
	end
end

autoFarmToggle.MouseButton1Click:Connect(function()
	autoFarmRunning = not autoFarmRunning
	if autoFarmRunning then
		farmID += 1
		local currentID = farmID
		autoFarmStopping = false
		notify("Auto Farm", "Loop dimulai!", "success")
		task.spawn(function() farmLoop(currentID) end)
	else
		autoFarmRunning = false
		autoFarmStopping = true
		notify("Auto Farm", "Loop dihentikan.", "error")
	end
end)

-- ============================================================
-- ANTI HIT + APPROACH LOGIC
-- ============================================================
local SAFE_POS = Vector3.new(579.0, 3.5, -539.7)
local MALL_POS = Vector3.new(-725.4, 4.8, 587.4)
local APPROACH_RADIUS = 20
local antiHitConn, antiApprConn
getgenv().ANTI_HIT = false

local function startAntiHit()
	local char = player.Character or player.CharacterAdded:Wait()
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	antiHitConn = hum.HealthChanged:Connect(function(newHealth)
		if not getgenv().ANTI_HIT then return end
		if newHealth < hum.MaxHealth and newHealth > 0 then
			antiStatusLbl.Text = "Kena hit! TP..."
			vehicleTeleport(CFrame.new(SAFE_POS))
		end
	end)
end

local NPC_ZONE_POS = Vector3.new(510.7584, 3.5872, 600.3163)
local NPC_ZONE_RADIUS = 35

local function startAntiApproach()
	antiApprConn = RunService.Heartbeat:Connect(function()
		if not getgenv().ANTI_HIT then return end
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hrp then return end
		local distToNPC = (hrp.Position - NPC_ZONE_POS).Magnitude
		if distToNPC <= NPC_ZONE_RADIUS then
			antiStatusLbl.Text = "Paused (di zona NPC)"
			return
		end
		for _, plr in pairs(Players:GetPlayers()) do
			if plr == player then continue end
			local c = plr.Character
			local h = c and c:FindFirstChild("HumanoidRootPart")
			if h then
				local d = (hrp.Position - h.Position).Magnitude
				if d <= APPROACH_RADIUS then
					antiStatusLbl.Text = plr.Name .. " mendekat!"
					vehicleTeleport(CFrame.new(MALL_POS))
					task.wait(1)
					return
				end
			end
		end
		antiStatusLbl.Text = "Aktif | Radius: " .. APPROACH_RADIUS
	end)
end

local function stopAntiHit()
	if antiHitConn then antiHitConn:Disconnect() antiHitConn = nil end
	if antiApprConn then antiApprConn:Disconnect() antiApprConn = nil end
	antiStatusLbl.Text = "Idle"
end

player.CharacterAdded:Connect(function()
	if getgenv().ANTI_HIT then
		task.wait(1)
		startAntiHit()
		startAntiApproach()
	end
end)

antiHitToggle.MouseButton1Click:Connect(function()
	getgenv().ANTI_HIT = not getgenv().ANTI_HIT
	if getgenv().ANTI_HIT then
		startAntiHit()
		startAntiApproach()
		notify("Protection", "Anti Hit + Approach aktif!", "success")
	else
		stopAntiHit()
		notify("Protection", "Protection dimatikan.", "error")
	end
end)

-- ============================================================
-- STATUS LOOP
-- ============================================================
task.spawn(function()
	while gui and gui.Parent do
		local w  = countItem("Water")
		local sg = countItem("Sugar Block Bag")
		local ge = countItem("Gelatin")
		local bg = countItem("Empty Bag")
		local sm = countItem("Small Marshmallow Bag")
		local md = countItem("Medium Marshmallow Bag")
		local lg = countItem("Large Marshmallow Bag")

		if waterVal    then waterVal.Text    = tostring(w)  end
		if sugarVal    then sugarVal.Text    = tostring(sg) end
		if gelatinVal  then gelatinVal.Text  = tostring(ge) end
		if bagVal      then bagVal.Text      = tostring(bg) end
		if statWaterVal   then statWaterVal.Text   = tostring(w)  end
		if statSugarVal   then statSugarVal.Text   = tostring(sg) end
		if statGelatinVal then statGelatinVal.Text = tostring(ge) end
		if statBagVal     then statBagVal.Text     = tostring(bg) end
		if statSmallVal   then statSmallVal.Text   = tostring(sm) end
		if statMedVal     then statMedVal.Text     = tostring(md) end
		if statLargeVal   then statLargeVal.Text   = tostring(lg) end
		if totalVal       then totalVal.Text        = tostring(sm+md+lg) end

		task.wait(0.5)
	end
end)

-- ============================================================
-- MINIMIZE BUTTON
-- ============================================================
local bodyVisible = true

minBtn.MouseButton1Click:Connect(function()
	bodyVisible = not bodyVisible
	sidebar.Visible = bodyVisible
	content.Visible = bodyVisible
	if bodyVisible then
		TweenService:Create(main, TweenInfo.new(0.22, Enum.EasingStyle.Quint), {Size = UDim2.new(0, 660, 0, 430)}):Play()
	else
		TweenService:Create(main, TweenInfo.new(0.22, Enum.EasingStyle.Quint), {Size = UDim2.new(0, 660, 0, 46)}):Play()
	end
end)

-- ============================================================
-- HIDE BUTTON (MOBILE) + KEYBIND Z
-- ============================================================
local hideBtn2 = Instance.new("TextButton", gui)
hideBtn2.Size = UDim2.new(0, 42, 0, 42)
hideBtn2.Position = UDim2.new(1, -52, 0.5, -21)
hideBtn2.Text = "E"
hideBtn2.Font = Enum.Font.GothamBlack
hideBtn2.TextSize = 15
hideBtn2.BackgroundColor3 = C.accent
hideBtn2.TextColor3 = Color3.new(1,1,1)
hideBtn2.Active = true
hideBtn2.Draggable = true
hideBtn2.BorderSizePixel = 0
Instance.new("UICorner", hideBtn2).CornerRadius = UDim.new(0, 10)

hideBtn2.MouseButton1Click:Connect(function()
	main.Visible = not main.Visible
end)

-- Keybind Z untuk hide/show GUI
ContextActionService:BindAction("toggleUI_ELIXIR", function(_, state)
	if state == Enum.UserInputState.Begin then
		main.Visible = not main.Visible
	end
end, false, Enum.KeyCode.Z)

-- ============================================================
-- ESP SYSTEM
-- ============================================================
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local ESP_DATA = {}
local PURPLE_ESP = Color3.fromRGB(130, 60, 240)

local function createESP(p)
	local box = {}
	for i = 1,8 do
		local line = Drawing.new("Line")
		line.Thickness = 2
		line.Color = PURPLE_ESP
		line.Visible = false
		table.insert(box, line)
	end
	local name2 = Drawing.new("Text")
	name2.Size = 13
	name2.Center = true
	name2.Outline = true
	name2.Color = Color3.new(1,1,1)
	name2.Visible = false
	local health2 = Drawing.new("Line")
	health2.Thickness = 3
	health2.Visible = false
	ESP_DATA[p] = {box = box, name = name2, health = health2}
end

local function removeESP(p)
	if ESP_DATA[p] then
		for _,l in pairs(ESP_DATA[p].box) do l:Remove() end
		ESP_DATA[p].name:Remove()
		ESP_DATA[p].health:Remove()
		ESP_DATA[p] = nil
	end
end

for _,p in pairs(Players:GetPlayers()) do
	if p ~= LocalPlayer then createESP(p) end
end
Players.PlayerAdded:Connect(function(p) if p ~= LocalPlayer then createESP(p) end end)
Players.PlayerRemoving:Connect(removeESP)

RunService.RenderStepped:Connect(function()
	for p, data in pairs(ESP_DATA) do
		if not Enabled then
			for _,l in pairs(data.box) do l.Visible = false end
			data.name.Visible = false
			data.health.Visible = false
			continue
		end
		local char = p.Character
		if not char then continue end
		local hrp = char:FindFirstChild("HumanoidRootPart")
		local hum = char:FindFirstChild("Humanoid")
		if not hrp or not hum then continue end
		local pos, visible = Camera:WorldToViewportPoint(hrp.Position)
		if visible then
			local scale = Camera:WorldToViewportPoint(hrp.Position + Vector3.new(0,3,0)).Y - Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0,3,0)).Y
			local width = scale * 0.6
			local height = scale * 1.2
			local x, y = pos.X, pos.Y
			local left, right = x - width/2, x + width/2
			local top2, bottom = y - height/2, y + height/2
			local corner2 = width/4
			local lines = data.box
			lines[1].From = Vector2.new(left,top2); lines[1].To = Vector2.new(left+corner2,top2)
			lines[2].From = Vector2.new(left,top2); lines[2].To = Vector2.new(left,top2+corner2)
			lines[3].From = Vector2.new(right,top2); lines[3].To = Vector2.new(right-corner2,top2)
			lines[4].From = Vector2.new(right,top2); lines[4].To = Vector2.new(right,top2+corner2)
			lines[5].From = Vector2.new(left,bottom); lines[5].To = Vector2.new(left+corner2,bottom)
			lines[6].From = Vector2.new(left,bottom); lines[6].To = Vector2.new(left,bottom-corner2)
			lines[7].From = Vector2.new(right,bottom); lines[7].To = Vector2.new(right-corner2,bottom)
			lines[8].From = Vector2.new(right,bottom); lines[8].To = Vector2.new(right,bottom-corner2)
			for _,l in pairs(lines) do l.Visible = true end

			local lp = LocalPlayer.Character
			if not lp or not lp:FindFirstChild("HumanoidRootPart") then continue end
			local distance2 = math.floor((lp.HumanoidRootPart.Position - hrp.Position).Magnitude)

			if distance2 > MaxDistance then
				for _,l in pairs(data.box) do l.Visible = false end
				data.name.Visible = false
				data.health.Visible = false
				continue
			end

			if ShowName then
				data.name.Text = ShowDistance and (p.Name .. " [" .. distance2 .. "]") or p.Name
				data.name.Position = Vector2.new(x, top2 - 15)
				data.name.Visible = true
			else
				data.name.Visible = false
			end

			local hpPct = hum.MaxHealth > 0 and math.clamp(hum.Health/hum.MaxHealth, 0, 1) or 0
			data.health.From = Vector2.new(left+2, bottom-3)
			data.health.To = Vector2.new(left+2+((width-4)*hpPct), bottom-3)
			data.health.Color = Color3.fromRGB(255*(1-hpPct), 255*hpPct, 0)
			data.health.Visible = ShowHealth
		else
			for _,l in pairs(data.box) do l.Visible = false end
			data.name.Visible = false
			data.health.Visible = false
		end
	end
end)

-- ============================================================
-- STARTUP
-- ============================================================
switchTab("FARM")
task.wait(0.3)
notify("ELIXIR 3.5", "Script berhasil diload!", "success")
