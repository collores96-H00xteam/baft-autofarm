--// ========== SERVICES ==========
local TweenService        = game:GetService("TweenService")
local RunService          = game:GetService("RunService")
local Players             = game:GetService("Players")
local UserInputService    = game:GetService("UserInputService")
local Lighting            = game:GetService("Lighting")
local TeleportService     = game:GetService("TeleportService")

-- VirtualInputManager есть только в экзекьюторе — оборачиваем в pcall
local VirtualInputManager
pcall(function() VirtualInputManager = game:GetService("VirtualInputManager") end)

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

--// ========== STATE ==========
local state = {
	noclip = false, fly = false, flySpeed = 120,
	speed = false, walkSpeed = 50,
	jump = false, jumpPower = 60, infJump = false,
	esp = false, fullbright = false,
	antiAfk = false, gravity = false, gravityValue = 0,
	freeze = false, farm = false, hitbox = false,
}

local orig = {
	walkspeed = 16, jumppower = 50, gravity = workspace.Gravity,
	brightness = Lighting.Brightness, clockTime = Lighting.ClockTime,
	ambient = Lighting.Ambient, outdoorAmbient = Lighting.OutdoorAmbient,
	fogEnd = Lighting.FogEnd, fogStart = Lighting.FogStart,
}

local destinations = {
	CFrame.new(-43.6134491, 62.1137619, 672.744934),
	CFrame.new(-60.1504707, 97.4659729, 8767.91406),
	CFrame.new(-54.331871, -345.398346, 9488.60645),
}

--// ========== THEME (ярче) ==========
local T = {
	Win       = Color3.fromRGB(26, 26, 34),
	Side      = Color3.fromRGB(18, 18, 24),
	Card      = Color3.fromRGB(38, 38, 50),
	CardHover = Color3.fromRGB(48, 48, 62),
	Line      = Color3.fromRGB(60, 60, 78),
	Text      = Color3.fromRGB(245, 245, 255),
	TextDim   = Color3.fromRGB(150, 150, 175),
	Accent    = Color3.fromRGB(130, 100, 255),
	Accent2   = Color3.fromRGB(255, 95, 180),
	On        = Color3.fromRGB(70, 220, 140),
	Off       = Color3.fromRGB(70, 70, 90),
	Danger    = Color3.fromRGB(235, 75, 95),
}

--// ========== HELPERS ==========
local function corner(p, r)
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 8); c.Parent = p
end
local function outline(p, color, th)
	local s = Instance.new("UIStroke"); s.Color = color or T.Line; s.Thickness = th or 1
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = p; return s
end
local function pad(p, n)
	local u = Instance.new("UIPadding")
	u.PaddingTop = UDim.new(0, n); u.PaddingBottom = UDim.new(0, n)
	u.PaddingLeft = UDim.new(0, n); u.PaddingRight = UDim.new(0, n); u.Parent = p
end
local function pad2(p, l, t, r, b)
	local u = Instance.new("UIPadding")
	u.PaddingTop = UDim.new(0, t or 0); u.PaddingBottom = UDim.new(0, b or t or 0)
	u.PaddingLeft = UDim.new(0, l or 0); u.PaddingRight = UDim.new(0, r or l or 0); u.Parent = p
end

--// Section header inside page
local function section(parent, text)
	local lbl = Instance.new("TextLabel")
	lbl.BackgroundTransparency = 1
	lbl.Size = UDim2.new(1, 0, 0, 22)
	lbl.Font = Enum.Font.GothamBold
	lbl.Text = text
	lbl.TextColor3 = T.Accent
	lbl.TextSize = 12
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = parent
	return lbl
end

--// Toggle
local function toggleRow(parent, label, default, cb)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 34)
	row.BackgroundColor3 = T.Card
	row.BorderSizePixel = 0
	row.Parent = parent
	corner(row, 8)

	local lbl = Instance.new("TextLabel")
	lbl.BackgroundTransparency = 1
	lbl.Position = UDim2.new(0, 12, 0, 0)
	lbl.Size = UDim2.new(1, -70, 1, 0)
	lbl.Font = Enum.Font.Gotham
	lbl.Text = label
	lbl.TextColor3 = T.Text
	lbl.TextSize = 13
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = row

	local sw = Instance.new("TextButton")
	sw.Size = UDim2.fromOffset(44, 22)
	sw.Position = UDim2.new(1, -54, 0.5, -11)
	sw.BackgroundColor3 = default and T.On or T.Off
	sw.Text = ""
	sw.AutoButtonColor = false
	sw.Parent = row
	corner(sw, 11)

	local ball = Instance.new("Frame")
	ball.Size = UDim2.fromOffset(18, 18)
	ball.Position = default and UDim2.new(1, -20, 0, 2) or UDim2.new(0, 2, 0, 2)
	ball.BackgroundColor3 = Color3.new(1, 1, 1)
	ball.Parent = sw
	corner(ball, 9)

	local val = default or false
	sw.MouseButton1Click:Connect(function()
		val = not val
		TweenService:Create(sw, TweenInfo.new(0.18), {BackgroundColor3 = val and T.On or T.Off}):Play()
		TweenService:Create(ball, TweenInfo.new(0.18), {
			Position = val and UDim2.new(1, -20, 0, 2) or UDim2.new(0, 2, 0, 2)
		}):Play()
		cb(val)
	end)
	return row
end

--// Slider
local function sliderRow(parent, label, min, max, default, cb)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 48)
	row.BackgroundColor3 = T.Card
	row.BorderSizePixel = 0
	row.Parent = parent
	corner(row, 8)

	local lbl = Instance.new("TextLabel")
	lbl.BackgroundTransparency = 1
	lbl.Position = UDim2.new(0, 12, 0, 4)
	lbl.Size = UDim2.new(0.7, -12, 0, 16)
	lbl.Font = Enum.Font.Gotham
	lbl.Text = label
	lbl.TextColor3 = T.Text
	lbl.TextSize = 13
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = row

	local valLbl = Instance.new("TextLabel")
	valLbl.BackgroundTransparency = 1
	valLbl.Position = UDim2.new(0.7, 0, 0, 4)
	valLbl.Size = UDim2.new(0.3, -12, 0, 16)
	valLbl.Font = Enum.Font.GothamBold
	valLbl.Text = tostring(default)
	valLbl.TextColor3 = T.Accent2
	valLbl.TextSize = 13
	valLbl.TextXAlignment = Enum.TextXAlignment.Right
	valLbl.Parent = row

	local bar = Instance.new("Frame")
	bar.Position = UDim2.new(0, 12, 0, 28)
	bar.Size = UDim2.new(1, -24, 0, 10)
	bar.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
	bar.Parent = row
	corner(bar, 5)
	outline(bar, T.Line, 1)

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(math.clamp((default - min) / (max - min), 0, 1), 0, 1, 0)
	fill.BackgroundColor3 = T.Accent
	fill.Parent = bar
	corner(fill, 5)

	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(T.Accent, T.Accent2)
	g.Parent = fill

	local dragging = false
	local function setFromX(x)
		local rel = math.clamp((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
		local v = math.floor(min + (max - min) * rel + 0.5)
		fill.Size = UDim2.new(rel, 0, 1, 0)
		valLbl.Text = tostring(v)
		cb(v)
	end

	bar.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging = true; setFromX(i.Position.X)
		end
	end)
	UserInputService.InputChanged:Connect(function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			setFromX(i.Position.X)
		end
	end)
	UserInputService.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	return row
end

--// Button
local function buttonRow(parent, label, cb, color)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1, 0, 0, 34)
	b.BackgroundColor3 = color or T.Card
	b.Text = label
	b.Font = Enum.Font.GothamBold
	b.TextSize = 13
	b.TextColor3 = T.Text
	b.AutoButtonColor = false
	b.Parent = parent
	corner(b, 8)
	outline(b, T.Line, 1)

	local base = color or T.Card
	b.MouseEnter:Connect(function() TweenService:Create(b, TweenInfo.new(0.12), {BackgroundColor3 = T.CardHover}):Play() end)
	b.MouseLeave:Connect(function() TweenService:Create(b, TweenInfo.new(0.12), {BackgroundColor3 = base}):Play() end)
	b.MouseButton1Click:Connect(cb)
	return b
end

--// ========== GUI ROOT ==========
local gui = Instance.new("ScreenGui")
gui.Name = "BinMenu"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() gui.Parent = game:GetService("CoreGui") end)
if not gui.Parent then gui.Parent = player:WaitForChild("PlayerGui") end

local win = Instance.new("Frame")
win.Size = UDim2.fromOffset(640, 400)
win.Position = UDim2.new(0.5, -320, 0.5, -200)
win.BackgroundColor3 = T.Win
win.BorderSizePixel = 0
win.Active = true
win.Draggable = true
win.Parent = gui
corner(win, 14)
outline(win, T.Line, 1)

-- top gradient line
local topLine = Instance.new("Frame")
topLine.Size = UDim2.new(1, 0, 0, 3)
topLine.BackgroundColor3 = T.Accent
topLine.BorderSizePixel = 0
topLine.Parent = win
corner(topLine, 14)
local topG = Instance.new("UIGradient")
topG.Color = ColorSequence.new(T.Accent, T.Accent2)
topG.Parent = topLine

-- header
local header = Instance.new("Frame")
header.Position = UDim2.new(0, 0, 0, 3)
header.Size = UDim2.new(1, 0, 0, 40)
header.BackgroundTransparency = 1
header.Parent = win

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.new(0, 16, 0, 0)
title.Size = UDim2.new(1, -60, 1, 0)
title.Font = Enum.Font.GothamBold
title.Text = "BIN  •  MULTI-TOOL"
title.TextColor3 = T.Text
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local subtitle = Instance.new("TextLabel")
subtitle.BackgroundTransparency = 1
subtitle.Position = UDim2.new(0, 16, 0, 22)
subtitle.Size = UDim2.new(1, -60, 0, 14)
subtitle.Font = Enum.Font.Gotham
subtitle.Text = "v2.1  •  executor build"
subtitle.TextColor3 = T.TextDim
subtitle.TextSize = 11
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = header

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromOffset(26, 26)
closeBtn.Position = UDim2.new(1, -36, 0, 7)
closeBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.BackgroundTransparency = 0.9
closeBtn.Text = "✕"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.TextColor3 = T.Text
closeBtn.AutoButtonColor = false
closeBtn.Parent = header
corner(closeBtn, 6)
closeBtn.MouseEnter:Connect(function() closeBtn.BackgroundTransparency = 0.7 end)
closeBtn.MouseLeave:Connect(function() closeBtn.BackgroundTransparency = 0.9 end)

-- sidebar
local side = Instance.new("Frame")
side.Position = UDim2.new(0, 12, 0, 52)
side.Size = UDim2.new(0, 140, 1, -64)
side.BackgroundColor3 = T.Side
side.BorderSizePixel = 0
side.Parent = win
corner(side, 10)
outline(side, T.Line, 1)
pad(side, 8)

-- content
local content = Instance.new("Frame")
content.Position = UDim2.new(0, 164, 0, 52)
content.Size = UDim2.new(1, -176, 1, -64)
content.BackgroundColor3 = T.Win
content.BackgroundTransparency = 1
content.BorderSizePixel = 0
content.Parent = win

local pageHolder = Instance.new("Frame")
pageHolder.Size = UDim2.new(1, 0, 1, 0)
pageHolder.BackgroundTransparency = 1
pageHolder.Parent = content

-- sidebar layout
local sideList = Instance.new("UIListLayout")
sideList.Padding = UDim.new(0, 4)
sideList.SortOrder = Enum.SortOrder.LayoutOrder
sideList.Parent = side

-- ========== TABS ==========
local pages = {}
local sideBtns = {}
local currentPage

local function setPage(name)
	for n, p in pairs(pages) do p.Visible = (n == name) end
	for n, b in pairs(sideBtns) do
		TweenService:Create(b, TweenInfo.new(0.15), {
			BackgroundColor3 = (n == name) and T.Accent or T.Side,
			BackgroundTransparency = (n == name) and 0 or 1,
		}):Play()
		b.TextColor3 = (n == name) and Color3.new(1,1,1) or T.TextDim
	end
	currentPage = name
end

local function addTab(name)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1, 0, 0, 32)
	b.BackgroundColor3 = T.Side
	b.BackgroundTransparency = 1
	b.Text = name
	b.Font = Enum.Font.GothamBold
	b.TextSize = 12
	b.TextColor3 = T.TextDim
	b.AutoButtonColor = false
	b.Parent = side
	corner(b, 6)
	b.MouseButton1Click:Connect(function() setPage(name) end)
	sideBtns[name] = b

	local page = Instance.new("ScrollingFrame")
	page.Size = UDim2.new(1, 0, 1, 0)
	page.BackgroundTransparency = 1
	page.BorderSizePixel = 0
	page.CanvasSize = UDim2.new(0, 0, 0, 0)
	page.AutomaticCanvasSize = Enum.AutomaticSize.Y
	page.ScrollBarThickness = 4
	page.ScrollBarImageColor3 = T.Accent
	page.Visible = false
	page.Parent = pageHolder

	local ll = Instance.new("UIListLayout")
	ll.Padding = UDim.new(0, 6)
	ll.SortOrder = Enum.SortOrder.LayoutOrder
	ll.Parent = page

	pages[name] = page
	return page
end

local pMove   = addTab("🏃  Movement")
local pVisual = addTab("👁  Visual")
local pPlayer = addTab("🧍  Player")
local pFarm   = addTab("🌾  Farm")
local pMisc   = addTab("⚙  Misc")

-- ========== FORWARD DECLARATIONS ==========
local startFly, stopFly, applyESP, applyFullbright
local farmLoop, stopFarm

-- ========== MOVEMENT PAGE ==========
section(pMove, "MOVEMENT")
toggleRow(pMove, "Noclip", false, function(v) state.noclip = v end)
toggleRow(pMove, "Fly", false, function(v)
	state.fly = v
	if v then startFly() else stopFly() end
end)
sliderRow(pMove, "Fly Speed", 20, 500, 120, function(v) state.flySpeed = v end)
toggleRow(pMove, "Speed Hack", false, function(v)
	state.speed = v
	local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if h then h.WalkSpeed = v and state.walkSpeed or orig.walkspeed end
end)
sliderRow(pMove, "WalkSpeed", 16, 300, 50, function(v)
	state.walkSpeed = v
	if state.speed then
		local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if h then h.WalkSpeed = v end
	end
end)
section(pMove, "JUMPING")
toggleRow(pMove, "Custom JumpPower", false, function(v)
	state.jump = v
	local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if h then
		if v then h.UseJumpPower = true; h.JumpPower = state.jumpPower
		else h.JumpPower = orig.jumppower end
	end
end)
sliderRow(pMove, "JumpPower", 50, 500, 60, function(v)
	state.jumpPower = v
	if state.jump then
		local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if h then h.UseJumpPower = true; h.JumpPower = v end
	end
end)
toggleRow(pMove, "Infinite Jump", false, function(v) state.infJump = v end)

-- ========== VISUAL PAGE ==========
section(pVisual, "VISUALS")
toggleRow(pVisual, "Player ESP", false, function(v) state.esp = v; applyESP(v) end)
toggleRow(pVisual, "Fullbright", false, function(v) state.fullbright = v; applyFullbright(v) end)
toggleRow(pVisual, "Hitbox Expand (R6/R15)", false, function(v)
	state.hitbox = v
	local char = player.Character
	if not char then return end
	for _, p in ipairs(char:GetDescendants()) do
		if p:IsA("BasePart") then
			if v then
				p.Size = p.Size + Vector3.new(2, 2, 2)
			end
		end
	end
end)
buttonRow(pVisual, "Reset Lighting", function()
	Lighting.Brightness = orig.brightness
	Lighting.ClockTime = orig.clockTime
	Lighting.Ambient = orig.ambient
	Lighting.OutdoorAmbient = orig.outdoorAmbient
	Lighting.FogEnd = orig.fogEnd
	Lighting.FogStart = orig.fogStart
end)

-- ========== PLAYER PAGE ==========
section(pPlayer, "TELEPORT")
local targetBtn = Instance.new("TextButton")
targetBtn.Size = UDim2.new(1, 0, 0, 34)
targetBtn.BackgroundColor3 = T.Card
targetBtn.Text = "Target: (click to cycle)"
targetBtn.Font = Enum.Font.Gotham
targetBtn.TextSize = 12
targetBtn.TextColor3 = T.Text
targetBtn.AutoButtonColor = false
targetBtn.Parent = pPlayer
corner(targetBtn, 8)
outline(targetBtn, T.Line, 1)

local tIndex = 0
local function targetPool()
	local pool = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player then table.insert(pool, p) end
	end
	return pool
end
targetBtn.MouseButton1Click:Connect(function()
	local pool = targetPool()
	if #pool == 0 then targetBtn.Text = "Target: (no players)"; return end
	tIndex = (tIndex % #pool) + 1
	targetBtn.Text = "Target: " .. pool[tIndex].Name
end)

buttonRow(pPlayer, "Teleport to Target", function()
	local pool = targetPool()
	if #pool == 0 or tIndex == 0 then return end
	local t = pool[((tIndex - 1) % #pool) + 1]
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local thp = t.Character and t.Character:FindFirstChild("HumanoidRootPart")
	if hrp and thp then hrp.CFrame = thp.CFrame + Vector3.new(0, 3, 0) end
end)
buttonRow(pPlayer, "Teleport to Mouse", function()
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	local m = UserInputService:GetMouseLocation()
	local unitRay = camera:ScreenPointToRay(m.X, m.Y)
	local ray = Ray.new(unitRay.Origin, unitRay.Direction * 1000)
	local hit, pos = workspace:FindPartOnRay(ray, player.Character)
	if pos then hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0)) end
end)

section(pPlayer, "PHYSICS")
toggleRow(pPlayer, "Freeze (Anchor HRP)", false, function(v)
	state.freeze = v
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if hrp then hrp.Anchored = v end
end)
buttonRow(pPlayer, "Sit", function()
	local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if h then h.Sit = true end
end)
buttonRow(pPlayer, "Unsit / Reset Pose", function()
	local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if h then h.Sit = false; h.PlatformStand = false end
end)

-- ========== FARM PAGE ==========
section(pFarm, "AUTO FARM")
toggleRow(pFarm, "Enable Auto Farm", false, function(v)
	state.farm = v
	if v then task.spawn(farmLoop) else stopFarm() end
end)
local farmStatus = Instance.new("TextLabel")
farmStatus.BackgroundTransparency = 1
farmStatus.Size = UDim2.new(1, 0, 0, 20)
farmStatus.Font = Enum.Font.Gotham
farmStatus.Text = "Status: idle"
farmStatus.TextColor3 = T.TextDim
farmStatus.TextSize = 12
farmStatus.TextXAlignment = Enum.TextXAlignment.Left
farmStatus.Parent = pFarm

-- ========== MISC PAGE ==========
section(pMisc, "QUALITY OF LIFE")
toggleRow(pMisc, "Anti-AFK", false, function(v) state.antiAfk = v end)
toggleRow(pMisc, "Zero Gravity", false, function(v)
	state.gravity = v
	workspace.Gravity = v and state.gravityValue or orig.gravity
end)
sliderRow(pMisc, "Gravity", 0, 196, 0, function(v)
	state.gravityValue = v
	if state.gravity then workspace.Gravity = v end
end)
section(pMisc, "DANGER ZONE")
buttonRow(pMisc, "Respawn", function()
	local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if h then h.Health = 0 end
end, T.Danger)
buttonRow(pMisc, "Rejoin Server", function()
	TeleportService:Teleport(game.PlaceId, player)
end, T.Danger)

-- ========== FEATURE IMPLEMENTATIONS ==========

-- Noclip
RunService.Stepped:Connect(function()
	if state.noclip and player.Character then
		for _, p in ipairs(player.Character:GetDescendants()) do
			if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
		end
	end
end)

-- Fly
local flyBV, flyBG, flyConn
startFly = function()
	local char = player.Character or player.CharacterAdded:Wait()
	local hrp = char:WaitForChild("HumanoidRootPart", 5)
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hrp then return end

	flyBV = Instance.new("BodyVelocity")
	flyBV.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	flyBV.Velocity = Vector3.zero
	flyBV.Parent = hrp

	flyBG = Instance.new("BodyGyro")
	flyBG.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
	flyBG.P = 3000; flyBG.D = 60
	flyBG.CFrame = camera.CFrame
	flyBG.Parent = hrp

	if hum then hum.PlatformStand = true end

	flyConn = RunService.RenderStepped:Connect(function()
		if not hrp.Parent then return end
		local dir = Vector3.zero
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += camera.CFrame.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= camera.CFrame.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= camera.CFrame.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += camera.CFrame.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0, 1, 0) end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.new(0, 1, 0) end
		flyBV.Velocity = dir * state.flySpeed
		flyBG.CFrame = camera.CFrame
	end)
end
stopFly = function()
	if flyConn then flyConn:Disconnect(); flyConn = nil end
	if flyBV then flyBV:Destroy(); flyBV = nil end
	if flyBG then flyBG:Destroy(); flyBG = nil end
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if hum then hum.PlatformStand = false end
end

-- Infinite jump
UserInputService.JumpRequest:Connect(function()
	if state.infJump then
		local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
	end
end)

-- ESP
local espFolder = Instance.new("Folder")
espFolder.Name = "ESP"
espFolder.Parent = gui
local espEntries = {}

local function addESPFor(p)
	if p == player or espEntries[p] then return end
	local char = p.Character or p.CharacterAdded:Wait()

	local hl = Instance.new("Highlight")
	hl.FillColor = T.Accent2
	hl.OutlineColor = Color3.new(1, 1, 1)
	hl.FillTransparency = 0.55
	hl.OutlineTransparency = 0
	hl.Adornee = char
	hl.Parent = espFolder

	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(140, 20)
	bb.StudsOffset = Vector3.new(0, 3.5, 0)
	bb.AlwaysOnTop = true
	bb.Adornee = char:FindFirstChild("Head")
	bb.Parent = espFolder

	local nameLbl = Instance.new("TextLabel")
	nameLbl.Size = UDim2.new(1, 0, 1, 0)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Font = Enum.Font.GothamBold
	nameLbl.Text = p.Name
	nameLbl.TextColor3 = T.Accent2
	nameLbl.TextStrokeTransparency = 0.3
	nameLbl.TextSize = 13
	nameLbl.Parent = bb

	espEntries[p] = { hl = hl, bb = bb }

	p.CharacterAdded:Connect(function(c)
		if not state.esp then return end
		hl.Adornee = c
		bb.Adornee = c:WaitForChild("Head", 5)
	end)
end

local function removeESPFor(p)
	local e = espEntries[p]
	if e then
		e.hl:Destroy(); e.bb:Destroy()
		espEntries[p] = nil
	end
end

applyESP = function(on)
	if on then
		for _, p in ipairs(Players:GetPlayers()) do addESPFor(p) end
	else
		for p in pairs(espEntries) do removeESPFor(p) end
	end
end
Players.PlayerAdded:Connect(function(p) if state.esp then addESPFor(p) end end)
Players.PlayerRemoving:Connect(removeESPFor)

-- Fullbright
applyFullbright = function(on)
	if on then
		Lighting.Brightness = 3
		Lighting.ClockTime = 14
		Lighting.Ambient = Color3.fromRGB(180, 180, 180)
		Lighting.OutdoorAmbient = Color3.fromRGB(180, 180, 180)
		Lighting.FogEnd = 1e6
		Lighting.FogStart = 1e6
		for _, e in ipairs(Lighting:GetChildren()) do
			if e:IsA("Atmosphere") or e:IsA("Sky") then e:Destroy() end
		end
	else
		Lighting.Brightness = orig.brightness
		Lighting.ClockTime = orig.clockTime
		Lighting.Ambient = orig.ambient
		Lighting.OutdoorAmbient = orig.outdoorAmbient
		Lighting.FogEnd = orig.fogEnd
		Lighting.FogStart = orig.fogStart
	end
end

-- Anti-AFK
task.spawn(function()
	while true do
		task.wait(60)
		if state.antiAfk and VirtualInputManager then
			pcall(function()
				VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.K, false, game)
				VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.K, false, game)
			end)
		end
	end
end)

-- Farm
local farmRunning = false
local function moveTo(cf, resetGrav)
	local char = player.Character or player.CharacterAdded:Wait()
	local hrp = char:WaitForChild("HumanoidRootPart", 5)
	if not hrp then return end
	local dist = (hrp.Position - cf.Position).Magnitude
	local tw = TweenService:Create(hrp, TweenInfo.new(dist / 375, Enum.EasingStyle.Linear), {CFrame = cf})
	tw:Play()
	workspace.Gravity = resetGrav and orig.gravity or 0
	tw.Completed:Wait()
end

farmLoop = function()
	farmRunning = true
	while farmRunning and state.farm do
		for i, cf in ipairs(destinations) do
			if not farmRunning or not state.farm then break end
			farmStatus.Text = ("Status: waypoint %d/%d"):format(i, #destinations)
			moveTo(cf, i == #destinations)
		end
		task.wait(1)
	end
	farmRunning = false
	farmStatus.Text = "Status: idle"
end

stopFarm = function()
	farmRunning = false
	workspace.Gravity = orig.gravity
end

-- Respawn reapply
player.CharacterAdded:Connect(function(char)
	task.wait(1)
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then
		if state.speed then hum.WalkSpeed = state.walkSpeed end
		if state.jump then hum.UseJumpPower = true; hum.JumpPower = state.jumpPower end
	end
	if state.freeze then
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if hrp then hrp.Anchored = true end
	end
	if state.fly then stopFly(); startFly() end
end)

-- Close
closeBtn.MouseButton1Click:Connect(function()
	state.noclip = false
	if state.fly then stopFly() end
	if state.fullbright then applyFullbright(false) end
	if state.esp then applyESP(false) end
	workspace.Gravity = orig.gravity
	gui:Destroy()
end)

setPage("🏃  Movement")
