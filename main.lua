--// ========== SERVICES ==========
local TweenService        = game:GetService("TweenService")
local RunService          = game:GetService("RunService")
local Players             = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService    = game:GetService("UserInputService")
local Lighting            = game:GetService("Lighting")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

--// ========== STATE ==========
local state = {
	noclip       = false,
	fly          = false,
	flySpeed     = 100,
	speed        = false,
	walkSpeed    = 32,
	jump         = false,
	jumpPower    = 50,
	infJump      = false,
	esp          = false,
	fullbright   = false,
	antiAfk      = false,
	gravity      = false,
	gravityValue = 0,
	freeze       = false,
	farm         = false,
}

local orig = {
	walkspeed      = 16,
	jumppower      = 50,
	gravity        = workspace.Gravity,
	brightness     = Lighting.Brightness,
	clockTime      = Lighting.ClockTime,
	ambient        = Lighting.Ambient,
	outdoorAmbient = Lighting.OutdoorAmbient,
	fogEnd         = Lighting.FogEnd,
	fogStart       = Lighting.FogStart,
}

local destinations = {
	CFrame.new(-43.6134491, 62.1137619, 672.744934,  -0.999842644, -0.00183729955, 0.017645346, 0, 0.994622767, 0.103564225, -0.0177407414, 0.103547923, -0.994466245),
	CFrame.new(-60.1504707, 97.4659729, 8767.91406,  -0.99889338,   0.000705028593, 0.0470264405, 0, 0.999887645, -0.0149902813, -0.047031723, -0.0149736926, -0.998781145),
	CFrame.new(-54.331871, -345.398346, 9488.60645,  -0.98221302,   0,               0.187770084,  0, 1,          0,            -0.187770084,  0,             -0.98221302),
}

--// ========== THEME ==========
local Theme = {
	Bg      = Color3.fromRGB(20, 20, 26),
	BgAlt   = Color3.fromRGB(28, 28, 36),
	BgDeep  = Color3.fromRGB(14, 14, 18),
	Side    = Color3.fromRGB(24, 24, 32),
	Stroke  = Color3.fromRGB(48, 48, 62),
	Text    = Color3.fromRGB(235, 235, 245),
	TextDim = Color3.fromRGB(150, 150, 165),
	Accent  = Color3.fromRGB(120, 90, 255),
	Accent2 = Color3.fromRGB(255, 90, 180),
	On      = Color3.fromRGB(80, 220, 150),
	Off     = Color3.fromRGB(60, 60, 75),
	Danger  = Color3.fromRGB(230, 70, 90),
}

--// ========== HELPERS ==========
local function corner(p, r)
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 8); c.Parent = p; return c
end
local function stroke(p, color, th)
	local s = Instance.new("UIStroke"); s.Color = color or Theme.Stroke
	s.Thickness = th or 1; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = p; return s
end
local function pad(p, t, b, l, r)
	local u = Instance.new("UIPadding")
	u.PaddingTop    = UDim.new(0, t or 0)
	u.PaddingBottom = UDim.new(0, b or t or 0)
	u.PaddingLeft   = UDim.new(0, l or t or 0)
	u.PaddingRight  = UDim.new(0, r or l or t or 0)
	u.Parent = p; return u
end

--// Toggle switch component
local function makeToggle(parent, label, default, callback)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 26)
	row.BackgroundTransparency = 1
	row.Parent = parent

	local lbl = Instance.new("TextLabel")
	lbl.BackgroundTransparency = 1
	lbl.Size = UDim2.new(0.65, 0, 1, 0)
	lbl.Font = Enum.Font.Gotham
	lbl.Text = label
	lbl.TextColor3 = Theme.Text
	lbl.TextSize = 13
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = row

	local sw = Instance.new("TextButton")
	sw.Size = UDim2.fromOffset(40, 20)
	sw.Position = UDim2.new(1, -40, 0.5, -10)
	sw.BackgroundColor3 = default and Theme.On or Theme.Off
	sw.Text = ""
	sw.AutoButtonColor = false
	sw.Parent = row
	corner(sw, 10)

	local ball = Instance.new("Frame")
	ball.Size = UDim2.fromOffset(16, 16)
	ball.Position = default and UDim2.new(1, -18, 0, 2) or UDim2.new(0, 2, 0, 2)
	ball.BackgroundColor3 = Color3.new(1, 1, 1)
	ball.Parent = sw
	corner(ball, 8)

	local value = default or false
	sw.MouseButton1Click:Connect(function()
		value = not value
		TweenService:Create(sw, TweenInfo.new(0.15), {BackgroundColor3 = value and Theme.On or Theme.Off}):Play()
		TweenService:Create(ball, TweenInfo.new(0.15), {
			Position = value and UDim2.new(1, -18, 0, 2) or UDim2.new(0, 2, 0, 2)
		}):Play()
		callback(value)
	end)
	return row
end

--// Slider component
local function makeSlider(parent, label, min, max, default, callback)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 40)
	row.BackgroundTransparency = 1
	row.Parent = parent

	local lbl = Instance.new("TextLabel")
	lbl.BackgroundTransparency = 1
	lbl.Size = UDim2.new(0.7, 0, 0, 16)
	lbl.Font = Enum.Font.Gotham
	lbl.Text = label
	lbl.TextColor3 = Theme.Text
	lbl.TextSize = 13
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = row

	local valLbl = Instance.new("TextLabel")
	valLbl.BackgroundTransparency = 1
	valLbl.Position = UDim2.new(0.7, 0, 0, 0)
	valLbl.Size = UDim2.new(0.3, 0, 0, 16)
	valLbl.Font = Enum.Font.GothamBold
	valLbl.Text = tostring(default)
	valLbl.TextColor3 = Theme.Accent2
	valLbl.TextSize = 13
	valLbl.TextXAlignment = Enum.TextXAlignment.Right
	valLbl.Parent = row

	local bar = Instance.new("Frame")
	bar.Position = UDim2.new(0, 0, 0, 24)
	bar.Size = UDim2.new(1, 0, 0, 10)
	bar.BackgroundColor3 = Theme.BgDeep
	bar.Parent = row
	corner(bar, 5)
	stroke(bar, Theme.Stroke, 1)

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
	fill.BackgroundColor3 = Theme.Accent
	fill.Parent = bar
	corner(fill, 5)

	local fillGrad = Instance.new("UIGradient")
	fillGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Theme.Accent),
		ColorSequenceKeypoint.new(1, Theme.Accent2),
	})
	fillGrad.Parent = fill

	local dragging = false
	local function updateFromX(x)
		local rel = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
		local v = min + (max - min) * rel
		fill.Size = UDim2.new(rel, 0, 1, 0)
		valLbl.Text = tostring(math.floor(v + 0.5))
		callback(math.floor(v + 0.5))
	end

	bar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			updateFromX(input.Position.X)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			updateFromX(input.Position.X)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	return row
end

--// Button component
local function makeButton(parent, label, callback, color)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1, 0, 0, 32)
	b.BackgroundColor3 = color or Theme.BgAlt
	b.Text = label
	b.Font = Enum.Font.GothamBold
	b.TextSize = 13
	b.TextColor3 = Theme.Text
	b.AutoButtonColor = false
	b.Parent = parent
	corner(b, 8)
	stroke(b, Theme.Stroke, 1)

	b.MouseEnter:Connect(function() TweenService:Create(b, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(50, 50, 65)}):Play() end)
	b.MouseLeave:Connect(function() TweenService:Create(b, TweenInfo.new(0.12), {BackgroundColor3 = color or Theme.BgAlt}):Play() end)
	b.MouseButton1Click:Connect(callback)
	return b
end

--// ========== ROOT ==========
local gui = Instance.new("ScreenGui")
gui.Name = "BinMenu"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = game.CoreGui

local main = Instance.new("Frame")
main.Size = UDim2.fromOffset(520, 340)
main.Position = UDim2.new(0.5, -260, 0.5, -170)
main.BackgroundColor3 = Theme.Bg
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.Parent = gui
corner(main, 14)
stroke(main, Theme.Stroke, 1)

--// Top header bar with gradient line
local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 3)
topBar.BackgroundColor3 = Theme.Accent
topBar.BorderSizePixel = 0
topBar.Parent = main
corner(topBar, 14)

local topGrad = Instance.new("UIGradient")
topGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Theme.Accent),
	ColorSequenceKeypoint.new(1, Theme.Accent2),
})
topGrad.Parent = topBar

--// Close button
local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(22, 22)
close.Position = UDim2.new(1, -30, 0, 10)
close.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
close.BackgroundTransparency = 0.9
close.Text = "✕"
close.Font = Enum.Font.GothamBold
close.TextSize = 13
close.TextColor3 = Theme.Text
close.AutoButtonColor = false
close.Parent = main
corner(close, 6)
close.MouseEnter:Connect(function() close.BackgroundTransparency = 0.7 end)
close.MouseLeave:Connect(function() close.BackgroundTransparency = 0.9 end)

--// Brand label
local brand = Instance.new("TextLabel")
brand.BackgroundTransparency = 1
brand.Position = UDim2.new(0, 100, 0, 12)
brand.Size = UDim2.new(0, 200, 0, 18)
brand.Font = Enum.Font.GothamBold
brand.Text = "BIN  •  MULTI-TOOL"
brand.TextColor3 = Theme.Text
brand.TextSize = 12
brand.TextXAlignment = Enum.TextXAlignment.Left
brand.Parent = main

local brandSub = Instance.new("TextLabel")
brandSub.BackgroundTransparency = 1
brandSub.Position = UDim2.new(0, 100, 0, 28)
brandSub.Size = UDim2.new(0, 300, 0, 14)
brandSub.Font = Enum.Font.Gotham
brandSub.Text = "v2.0  •  c++/c#/py/lua"
brandSub.TextColor3 = Theme.TextDim
brandSub.TextSize = 10
brandSub.TextXAlignment = Enum.TextXAlignment.Left
brandSub.Parent = main

--// Sidebar
local side = Instance.new("Frame")
side.Position = UDim2.new(0, 10, 0, 50)
side.Size = UDim2.new(0, 90, 1, -60)
side.BackgroundColor3 = Theme.Side
side.BorderSizePixel = 0
side.Parent = main
corner(side, 10)
stroke(side, Theme.Stroke, 1)

--// Content area
local content = Instance.new("Frame")
content.Position = UDim2.new(0, 110, 0, 50)
content.Size = UDim2.new(1, -120, 1, -60)
content.BackgroundColor3 = Theme.BgAlt
content.BorderSizePixel = 0
content.Parent = main
corner(content, 10)
stroke(content, Theme.Stroke, 1)
pad(content, 12)

local pageHolder = Instance.new("Frame")
pageHolder.Size = UDim2.new(1, 0, 1, 0)
pageHolder.BackgroundTransparency = 1
pageHolder.Parent = content

local pages = {}
local sideButtons = {}
local currentPage = nil

local function setPage(name)
	for n, p in pairs(pages) do p.Visible = (n == name) end
	for n, b in pairs(sideButtons) do
		TweenService:Create(b, TweenInfo.new(0.15), {
			BackgroundColor3 = (n == name) and Theme.Accent or Theme.Side,
			BackgroundTransparency = (n == name) and 0 or 1,
		}):Play()
		b.TextColor3 = (n == name) and Color3.new(1,1,1) or Theme.TextDim
	end
	currentPage = name
end

local function addTab(name)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1, -8, 0, 30)
	b.Position = UDim2.new(0, 4, 0, 4 + (#sideButtons * 34))
	b.BackgroundColor3 = Theme.Side
	b.BackgroundTransparency = 1
	b.Text = name
	b.Font = Enum.Font.GothamBold
	b.TextSize = 12
	b.TextColor3 = Theme.TextDim
	b.AutoButtonColor = false
	b.Parent = side
	corner(b, 6)
	b.MouseButton1Click:Connect(function() setPage(name) end)
	table.insert(sideButtons, b)

	local page = Instance.new("ScrollingFrame")
	page.Size = UDim2.new(1, 0, 1, 0)
	page.BackgroundTransparency = 1
	page.BorderSizePixel = 0
	page.CanvasSize = UDim2.new(0, 0, 0, 0)
	page.AutomaticCanvasSize = Enum.AutomaticSize.Y
	page.ScrollBarThickness = 3
	page.Visible = false
	page.Parent = pageHolder

	local ll = Instance.new("UIListLayout")
	ll.Padding = UDim.new(0, 6)
	ll.SortOrder = Enum.SortOrder.LayoutOrder
	ll.Parent = page

	pages[name] = page
	return page
end

-- ============ PAGES ============
local pMove   = addTab("Movement")
local pVisual = addTab("Visual")
local pPlayer = addTab("Player")
local pFarm   = addTab("Farm")
local pMisc   = addTab("Misc")

-- Movement
makeToggle(pMove, "Noclip", false, function(v) state.noclip = v end)
makeToggle(pMove, "Fly", false, function(v)
	state.fly = v
	if v then startFly() else stopFly() end
end)
makeSlider(pMove, "Fly Speed", 10, 500, 100, function(v) state.flySpeed = v end)
makeToggle(pMove, "Speed Hack", false, function(v)
	state.speed = v
	local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if h then h.WalkSpeed = v and state.walkSpeed or orig.walkspeed end
end)
makeSlider(pMove, "WalkSpeed", 16, 300, 32, function(v)
	state.walkSpeed = v
	if state.speed then
		local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if h then h.WalkSpeed = v end
	end
end)
makeToggle(pMove, "Jump Power", false, function(v)
	state.jump = v
	local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if h then
		if v then
			h.UseJumpPower = true
			h.JumpPower = state.jumpPower
		else
			h.JumpPower = orig.jumppower
		end
	end
end)
makeSlider(pMove, "JumpPower", 50, 500, 50, function(v)
	state.jumpPower = v
	if state.jump then
		local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if h then h.UseJumpPower = true; h.JumpPower = v end
	end
end)
makeToggle(pMove, "Infinite Jump", false, function(v) state.infJump = v end)

-- Visual
makeToggle(pVisual, "Player ESP", false, function(v) state.esp = v; applyESP(v) end)
makeToggle(pVisual, "Fullbright", false, function(v) state.fullbright = v; applyFullbright(v) end)
makeButton(pVisual, "Reset Lighting", function()
	Lighting.Brightness     = orig.brightness
	Lighting.ClockTime      = orig.clockTime
	Lighting.Ambient        = orig.ambient
	Lighting.OutdoorAmbient = orig.outdoorAmbient
	Lighting.FogEnd         = orig.fogEnd
	Lighting.FogStart       = orig.fogStart
end)

-- Player
local targetDd = Instance.new("TextButton")
targetDd.Size = UDim2.new(1, 0, 0, 32)
targetDd.BackgroundColor3 = Theme.BgDeep
targetDd.Text = "Target: (click to cycle)"
targetDd.Font = Enum.Font.Gotham
targetDd.TextSize = 12
targetDd.TextColor3 = Theme.Text
targetDd.AutoButtonColor = false
targetDd.Parent = pPlayer
corner(targetDd, 8)
stroke(targetDd, Theme.Stroke, 1)

local targetIndex = 0
local function refreshTargets()
	local pool = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player then table.insert(pool, p) end
	end
	return pool
end
targetDd.MouseButton1Click:Connect(function()
	local pool = refreshTargets()
	if #pool == 0 then targetDd.Text = "Target: (no players)"; return end
	targetIndex = (targetIndex % #pool) + 1
	targetDd.Text = "Target: " .. pool[targetIndex].Name
end)

makeButton(pPlayer, "Teleport to Target", function()
	local pool = refreshTargets()
	if #pool == 0 or targetIndex == 0 then return end
	local t = pool[((targetIndex - 1) % #pool) + 1]
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local thp = t.Character and t.Character:FindFirstChild("HumanoidRootPart")
	if hrp and thp then hrp.CFrame = thp.CFrame + Vector3.new(0, 3, 0) end
end)

makeButton(pPlayer, "Teleport to Mouse", function()
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	local unitRay = camera:ScreenPointToRay(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y)
	local ray = Ray.new(unitRay.Origin, unitRay.Direction * 1000)
	local hit, pos = workspace:FindPartOnRay(ray, char)
	if pos then hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0)) end
end)

makeToggle(pPlayer, "Freeze (Anchor)", false, function(v)
	state.freeze = v
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if hrp then hrp.Anchored = v end
end)
makeButton(pPlayer, "Sit", function()
	local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if h then h.Sit = true end
end)
makeButton(pPlayer, "Unsit / Reset Pose", function()
	local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if h then
		h.Sit = false
		h.PlatformStand = false
	end
end)

-- Farm
makeToggle(pFarm, "Auto Farm (waypoints)", false, function(v)
	state.farm = v
	if v then task.spawn(farmLoop) else stopFarm() end
end)
local farmStatus = Instance.new("TextLabel")
farmStatus.BackgroundTransparency = 1
farmStatus.Size = UDim2.new(1, 0, 0, 20)
farmStatus.Font = Enum.Font.Gotham
farmStatus.Text = "Status: idle"
farmStatus.TextColor3 = Theme.TextDim
farmStatus.TextSize = 12
farmStatus.TextXAlignment = Enum.TextXAlignment.Left
farmStatus.Parent = pFarm

-- Misc
makeToggle(pMisc, "Anti-AFK", false, function(v) state.antiAfk = v end)
makeToggle(pMisc, "Zero Gravity", false, function(v)
	state.gravity = v
	workspace.Gravity = v and state.gravityValue or orig.gravity
end)
makeSlider(pMisc, "Gravity", 0, 196, 0, function(v)
	state.gravityValue = v
	if state.gravity then workspace.Gravity = v end
end)
makeButton(pMisc, "Rejoin (respawn)", function()
	local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if h then h.Health = 0 end
end)
makeButton(pMisc, "Server Hop", function()
	-- best-effort: use TeleportService to smallest server
	local ok, err = pcall(function()
		local TS = game:GetService("TeleportService")
		local servers = TS:GetPublicServersAsync and TS:GetPublicServersAsync(game.PlaceId) or nil
		if servers and #servers > 0 then
			local pick = servers[1]
			TS:TeleportToPlaceInstance(game.PlaceId, pick.id, player)
		end
	end)
end, Theme.Danger)

-- ============ FEATURES ============

-- Noclip loop
RunService.Stepped:Connect(function()
	if state.noclip and player.Character then
		for _, p in ipairs(player.Character:GetDescendants()) do
			if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
		end
	end
end)

-- Fly
local flyBV, flyBG, flyConn
function startFly()
	local char = player.Character
	if not char then return end
	local hrp = char:WaitForChild("HumanoidRootPart")
	local hum = char:FindFirstChildOfClass("Humanoid")

	flyBV = Instance.new("BodyVelocity")
	flyBV.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	flyBV.Velocity = Vector3.zero
	flyBV.Parent = hrp

	flyBG = Instance.new("BodyGyro")
	flyBG.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
	flyBG.P = 2000
	flyBG.D = 50
	flyBG.CFrame = camera.CFrame
	flyBG.Parent = hrp

	if hum then hum.PlatformStand = true end

	flyConn = RunService.RenderStepped:Connect(function()
		if not hrp or not hrp.Parent then return end
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
function stopFly()
	if flyConn then flyConn:Disconnect(); flyConn = nil end
	if flyBV then flyBV:Destroy(); flyBV = nil end
	if flyBG then flyBG:Destroy(); flyBG = nil end
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
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
local espFolder = Instance.new("Folder", gui)
espFolder.Name = "ESP"
local espEntries = {}

local function addESPFor(p)
	if p == player then return end
	if espEntries[p] then return end
	local hl = Instance.new("Highlight")
	hl.FillColor = Theme.Accent2
	hl.OutlineColor = Color3.new(1, 1, 1)
	hl.FillTransparency = 0.6
	hl.OutlineTransparency = 0
	hl.Adornee = p.Character or p.CharacterAdded:Wait()
	hl.Parent = espFolder

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(120, 20)
	billboard.StudsOffset = Vector3.new(0, 3.5, 0)
	billboard.AlwaysOnTop = true
	billboard.Adornee = p.Character and p.Character:FindFirstChild("Head")
	billboard.Parent = espFolder

	local nameLbl = Instance.new("TextLabel")
	nameLbl.Size = UDim2.new(1, 0, 1, 0)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Font = Enum.Font.GothamBold
	nameLbl.Text = p.Name
	nameLbl.TextColor3 = Theme.Accent2
	nameLbl.TextStrokeTransparency = 0.3
	nameLbl.TextSize = 13
	nameLbl.Parent = billboard

	espEntries[p] = { hl = hl, billboard = billboard }
	p.CharacterAdded:Connect(function(c)
		if not state.esp then return end
		hl.Adornee = c
		billboard.Adornee = c:WaitForChild("Head", 5)
	end)
end

local function removeESPFor(p)
	local e = espEntries[p]
	if e then
		e.hl:Destroy()
		e.billboard:Destroy()
		espEntries[p] = nil
	end
end

function applyESP(on)
	if on then
		for _, p in ipairs(Players:GetPlayers()) do addESPFor(p) end
		Players.PlayerAdded:Connect(addESPFor)
		Players.PlayerRemoving:Connect(removeESPFor)
	else
		for p in pairs(espEntries) do removeESPFor(p) end
	end
end

Players.PlayerAdded:Connect(function(p)
	if state.esp then addESPFor(p) end
end)
Players.PlayerRemoving:Connect(function(p)
	removeESPFor(p)
end)

-- Fullbright
function applyFullbright(on)
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
		if state.antiAfk then
			VirtualInputManager:SendKeyEvent(true,  Enum.KeyCode.K, false, game)
			VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.K, false, game)
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
function farmLoop()
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
function stopFarm()
	farmRunning = false
	workspace.Gravity = orig.gravity
end

-- Character respawn re-apply
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
close.MouseButton1Click:Connect(function()
	state.noclip = false
	if state.fly then stopFly() end
	if state.fullbright then applyFullbright(false) end
	if state.esp then applyESP(false) end
	workspace.Gravity = orig.gravity
	gui:Destroy()
end)

-- Init
setPage("Movement")
