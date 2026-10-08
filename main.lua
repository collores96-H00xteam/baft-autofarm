-- v3.0 premium
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer
local gravityNormal = workspace.Gravity
local isRunning = false
local speed = 375
local currentTween = nil

local destinations = {
    CFrame.new(-43.6134491, 62.1137619, 672.744934, -0.999842644, -0.00183729955, 0.017645346, 0, 0.994622767, 0.103564225, -0.0177407414, 0.103547923, -0.994466245),
    CFrame.new(-60.1504707, 97.4659729, 8767.91406, -0.99889338, 0.000705028593, 0.0470264405, 0, 0.999887645, -0.0149902813, -0.047031723, -0.0149736926, -0.998781145),
    CFrame.new(-54.331871, -345.398346, 9488.60645, -0.98221302, 0, 0.187770084, 0, 1, 0, -0.187770084, 0, -0.98221302),
}

local function safeTween(obj, info, goal)
    pcall(function()
        TweenService:Create(obj, info, goal):Play()
    end)
end

local T = {
	Bg      = Color3.fromRGB(16, 16, 22),
	HeaderA = Color3.fromRGB(38, 26, 72),
	HeaderB = Color3.fromRGB(72, 40, 130),
	Card    = Color3.fromRGB(24, 24, 32),
	Line    = Color3.fromRGB(52, 52, 70),
	Text    = Color3.fromRGB(245, 245, 255),
	TextDim = Color3.fromRGB(150, 150, 175),
	Accent  = Color3.fromRGB(130, 100, 255),
	Accent2 = Color3.fromRGB(255, 95, 180),
	Gold    = Color3.fromRGB(255, 200, 100),
	On      = Color3.fromRGB(70, 220, 140),
	Danger  = Color3.fromRGB(235, 75, 95),
}

local function corner(p, r)
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 8); c.Parent = p
end
local function outline(p, color, th, trans)
	local s = Instance.new("UIStroke"); s.Color = color or T.Line; s.Thickness = th or 1
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Transparency = trans or 0
	s.Parent = p; return s
end
local function gradient2(parent, c1, c2, rot)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, c1),
		ColorSequenceKeypoint.new(1, c2),
	})
	if rot then g.Rotation = rot end
	g.Parent = parent
	return g
end

-- GUI ROOT
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoFarmUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() screenGui.Parent = game:GetService("CoreGui") end)
if not screenGui.Parent then screenGui.Parent = player:WaitForChild("PlayerGui") end

-- GREETING (по центру, полностью изолированное)
do
	local greetHolder = Instance.new("Frame")
	greetHolder.BackgroundTransparency = 1
	greetHolder.AnchorPoint = Vector2.new(0.5, 0.5)
	greetHolder.Position = UDim2.new(0.5, 0, 0.4, 0)
	greetHolder.Size = UDim2.new(0, 600, 0, 100)
	greetHolder.Active = false
	greetHolder.Parent = screenGui

	local line1 = Instance.new("TextLabel")
	line1.BackgroundTransparency = 1
	line1.Size = UDim2.new(1, 0, 0, 24)
	line1.Font = Enum.Font.Gotham
	line1.Text = "✦  welcome back  ✦"
	line1.TextColor3 = Color3.fromRGB(180, 155, 255)
	line1.TextSize = 14
	line1.TextTransparency = 1
	line1.Parent = greetHolder

	local line2 = Instance.new("TextLabel")
	line2.BackgroundTransparency = 1
	line2.Position = UDim2.new(0, 0, 0, 26)
	line2.Size = UDim2.new(1, 0, 0, 50)
	line2.Font = Enum.Font.GothamBold
	line2.Text = player.Name
	line2.TextColor3 = Color3.fromRGB(248, 248, 255)
	line2.TextSize = 42
	line2.TextStrokeTransparency = 0.5
	line2.TextStrokeColor3 = Color3.new(0, 0, 0)
	line2.TextTransparency = 1
	line2.Parent = greetHolder

	local divider = Instance.new("Frame")
	divider.AnchorPoint = Vector2.new(0.5, 0)
	divider.Position = UDim2.new(0.5, 0, 0, 82)
	divider.Size = UDim2.new(0, 0, 0, 2)
	divider.BackgroundColor3 = T.Accent
	divider.BorderSizePixel = 0
	divider.Parent = greetHolder
	corner(divider, 1)
	gradient2(divider, T.Accent, T.Accent2)

	task.spawn(function()
		task.wait(0.15)
		safeTween(line1, TweenInfo.new(0.4, Enum.EasingStyle.Quart), {TextTransparency = 0})
		task.wait(0.1)
		safeTween(line2, TweenInfo.new(0.5, Enum.EasingStyle.Quart), {TextTransparency = 0})
		safeTween(divider, TweenInfo.new(0.5, Enum.EasingStyle.Quart), {Size = UDim2.new(0, 220, 0, 2)})
		task.wait(1.6)
		safeTween(line1, TweenInfo.new(0.5, Enum.EasingStyle.Quart), {TextTransparency = 1})
		safeTween(line2, TweenInfo.new(0.5, Enum.EasingStyle.Quart), {TextTransparency = 1})
		safeTween(divider, TweenInfo.new(0.5, Enum.EasingStyle.Quart), {Size = UDim2.new(0, 0, 0, 2)})
		task.wait(0.6)
		if greetHolder then greetHolder:Destroy() end
	end)
end

-- MAIN WINDOW
local menu = Instance.new("Frame")
menu.Size = UDim2.fromOffset(300, 240)
menu.Position = UDim2.new(0, 20, 0, 80)
menu.BackgroundColor3 = T.Bg
menu.BorderSizePixel = 0
menu.Active = true
menu.Draggable = true
menu.Parent = screenGui
corner(menu, 16)
outline(menu, T.Line, 1)

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 56)
header.BackgroundColor3 = T.HeaderA
header.BorderSizePixel = 0
header.Parent = menu
corner(header, 16)

local headerMask = Instance.new("Frame")
headerMask.Size = UDim2.new(1, 0, 0, 16)
headerMask.Position = UDim2.new(0, 0, 1, -16)
headerMask.BackgroundColor3 = T.HeaderA
headerMask.BorderSizePixel = 0
headerMask.ZIndex = 2
headerMask.Parent = header

gradient2(header, T.HeaderA, T.HeaderB, 25)

local topLine = Instance.new("Frame")
topLine.Size = UDim2.new(1, 0, 0, 3)
topLine.BackgroundColor3 = T.Accent
topLine.BorderSizePixel = 0
topLine.ZIndex = 4
topLine.Parent = menu
corner(topLine, 16)
gradient2(topLine, T.Accent, T.Accent2)

local iconBox = Instance.new("Frame")
iconBox.Size = UDim2.fromOffset(34, 34)
iconBox.Position = UDim2.new(0, 16, 0, 11)
iconBox.BackgroundColor3 = T.Accent
iconBox.BorderSizePixel = 0
iconBox.ZIndex = 5
iconBox.Parent = header
corner(iconBox, 10)
gradient2(iconBox, T.Accent, T.Accent2, 45)

local iconGlyph = Instance.new("TextLabel")
iconGlyph.BackgroundTransparency = 1
iconGlyph.Size = UDim2.new(1, 0, 1, 0)
iconGlyph.Font = Enum.Font.GothamBold
iconGlyph.Text = "⚡"
iconGlyph.TextColor3 = Color3.new(1, 1, 1)
iconGlyph.TextSize = 20
iconGlyph.ZIndex = 6
iconGlyph.Parent = iconBox

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.new(0, 60, 0, 10)
title.Size = UDim2.new(1, -110, 0, 20)
title.Font = Enum.Font.GothamBold
title.Text = "AUTO FARM"
title.TextColor3 = T.Text
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 5
title.Parent = header

local subtitle = Instance.new("TextLabel")
subtitle.BackgroundTransparency = 1
subtitle.Position = UDim2.new(0, 60, 0, 30)
subtitle.Size = UDim2.new(1, -110, 0, 14)
subtitle.Font = Enum.Font.Gotham
subtitle.Text = "premium edition  •  v3.0"
subtitle.TextColor3 = T.Gold
subtitle.TextSize = 10
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.ZIndex = 5
subtitle.Parent = header

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(24, 24)
close.Position = UDim2.new(1, -34, 0, 16)
close.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
close.BackgroundTransparency = 0.92
close.Text = "✕"
close.Font = Enum.Font.GothamBold
close.TextSize = 12
close.TextColor3 = T.Text
close.AutoButtonColor = false
close.ZIndex = 6
close.Parent = header
corner(close, 7)

local statusDot = Instance.new("Frame")
statusDot.Size = UDim2.fromOffset(8, 8)
statusDot.Position = UDim2.new(0, 20, 0, 72)
statusDot.BackgroundColor3 = T.TextDim
statusDot.BorderSizePixel = 0
statusDot.Parent = menu
corner(statusDot, 4)

local statusText = Instance.new("TextLabel")
statusText.BackgroundTransparency = 1
statusText.Position = UDim2.new(0, 34, 0, 68)
statusText.Size = UDim2.new(1, -50, 0, 16)
statusText.Font = Enum.Font.Gotham
statusText.Text = "idle"
statusText.TextColor3 = T.TextDim
statusText.TextSize = 11
statusText.TextXAlignment = Enum.TextXAlignment.Left
statusText.Parent = menu

-- SPEED CARD
local speedCard = Instance.new("Frame")
speedCard.Size = UDim2.new(1, -32, 0, 54)
speedCard.Position = UDim2.new(0, 16, 0, 96)
speedCard.BackgroundColor3 = T.Card
speedCard.BorderSizePixel = 0
speedCard.Parent = menu
corner(speedCard, 12)
outline(speedCard, T.Line, 1)

local speedLabel = Instance.new("TextLabel")
speedLabel.BackgroundTransparency = 1
speedLabel.Position = UDim2.new(0, 12, 0, 7)
speedLabel.Size = UDim2.new(0.6, 0, 0, 14)
speedLabel.Font = Enum.Font.Gotham
speedLabel.Text = "SPEED"
speedLabel.TextColor3 = T.TextDim
speedLabel.TextSize = 10
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.Parent = speedCard

local speedValue = Instance.new("TextLabel")
speedValue.BackgroundTransparency = 1
speedValue.Position = UDim2.new(0.6, 0, 0, 5)
speedValue.Size = UDim2.new(0.4, -12, 0, 18)
speedValue.Font = Enum.Font.GothamBold
speedValue.Text = tostring(speed)
speedValue.TextColor3 = Color3.fromRGB(180, 155, 255)
speedValue.TextSize = 14
speedValue.TextXAlignment = Enum.TextXAlignment.Right
speedValue.Parent = speedCard

local speedBar = Instance.new("Frame")
speedBar.Position = UDim2.new(0, 12, 0, 34)
speedBar.Size = UDim2.new(1, -24, 0, 8)
speedBar.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
speedBar.BorderSizePixel = 0
speedBar.Parent = speedCard
corner(speedBar, 4)
outline(speedBar, T.Line, 1)

local speedFill = Instance.new("Frame")
speedFill.Size = UDim2.new((speed - 100) / 1900, 0, 1, 0)
speedFill.BackgroundColor3 = T.Accent
speedFill.BorderSizePixel = 0
speedFill.Parent = speedBar
corner(speedFill, 4)
gradient2(speedFill, T.Accent, T.Accent2)

local knob = Instance.new("Frame")
knob.AnchorPoint = Vector2.new(0.5, 0.5)
knob.Size = UDim2.fromOffset(14, 14)
knob.Position = UDim2.new((speed - 100) / 1900, 0, 0.5, 0)
knob.BackgroundColor3 = Color3.new(1, 1, 1)
knob.BorderSizePixel = 0
knob.ZIndex = 3
knob.Parent = speedBar
corner(knob, 7)
outline(knob, T.Accent, 2)

local SPEED_MIN = 100
local SPEED_MAX = 2000

local draggingSpeed = false
local function setSpeedFromX(x)
	local rel = math.clamp((x - speedBar.AbsolutePosition.X) / math.max(speedBar.AbsoluteSize.X, 1), 0, 1)
	local v = math.floor(SPEED_MIN + (SPEED_MAX - SPEED_MIN) * rel + 0.5)
	speed = v
	speedFill.Size = UDim2.new(rel, 0, 1, 0)
	knob.Position = UDim2.new(rel, 0, 0.5, 0)
	speedValue.Text = tostring(v)
end

speedBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		draggingSpeed = true
		setSpeedFromX(input.Position.X)
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if draggingSpeed and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		setSpeedFromX(input.Position.X)
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		draggingSpeed = false
	end
end)

-- START BUTTON
local toggle = Instance.new("TextButton")
toggle.Size = UDim2.new(1, -32, 0, 46)
toggle.Position = UDim2.new(0, 16, 1, -58)
toggle.BackgroundColor3 = T.Accent
toggle.Text = "▶   START FARM"
toggle.Font = Enum.Font.GothamBold
toggle.TextSize = 14
toggle.TextColor3 = Color3.new(1, 1, 1)
toggle.AutoButtonColor = false
toggle.Parent = menu
corner(toggle, 12)
outline(toggle, T.Line, 1, 0.4)
gradient2(toggle, T.Accent, T.Accent2)

-- ПЛАВНОЕ ПОЯВЛЕНИЕ (всё в pcall, чтоб не сломать ничего)
menu.BackgroundTransparency = 1
task.spawn(function()
	task.wait(0.05)
	local info = TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	safeTween(menu, info, {BackgroundTransparency = 0})
	safeTween(header, info, {BackgroundTransparency = 0})
	safeTween(headerMask, info, {BackgroundTransparency = 0})
	safeTween(speedCard, info, {BackgroundTransparency = 0})
	safeTween(speedBar, info, {BackgroundTransparency = 0})
	safeTween(speedFill, info, {BackgroundTransparency = 0})
	safeTween(toggle, info, {BackgroundTransparency = 0})
	safeTween(topLine, info, {BackgroundTransparency = 0})
	safeTween(iconBox, info, {BackgroundTransparency = 0})
	safeTween(statusDot, info, {BackgroundTransparency = 0})
	safeTween(knob, info, {BackgroundTransparency = 0})
	safeTween(title, info, {TextTransparency = 0})
	safeTween(subtitle, info, {TextTransparency = 0})
	safeTween(statusText, info, {TextTransparency = 0})
	safeTween(speedLabel, info, {TextTransparency = 0})
	safeTween(speedValue, info, {TextTransparency = 0})
	safeTween(toggle, info, {TextTransparency = 0})
	safeTween(close, info, {TextTransparency = 0})
	safeTween(iconGlyph, info, {TextTransparency = 0})
end)

-- ЗАКРЫТИЕ
close.MouseButton1Click:Connect(function()
	isRunning = false
	workspace.Gravity = gravityNormal
	if currentTween then currentTween:Cancel() end

	local info = TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
	safeTween(menu, info, {BackgroundTransparency = 1})
	safeTween(header, info, {BackgroundTransparency = 1})
	safeTween(headerMask, info, {BackgroundTransparency = 1})
	safeTween(speedCard, info, {BackgroundTransparency = 1})
	safeTween(speedBar, info, {BackgroundTransparency = 1})
	safeTween(speedFill, info, {BackgroundTransparency = 1})
	safeTween(toggle, info, {BackgroundTransparency = 1})
	safeTween(topLine, info, {BackgroundTransparency = 1})
	safeTween(iconBox, info, {BackgroundTransparency = 1})
	safeTween(statusDot, info, {BackgroundTransparency = 1})
	safeTween(knob, info, {BackgroundTransparency = 1})
	safeTween(title, info, {TextTransparency = 1})
	safeTween(subtitle, info, {TextTransparency = 1})
	safeTween(statusText, info, {TextTransparency = 1})
	safeTween(speedLabel, info, {TextTransparency = 1})
	safeTween(speedValue, info, {TextTransparency = 1})
	safeTween(toggle, info, {TextTransparency = 1})
	safeTween(close, info, {TextTransparency = 1})
	safeTween(iconGlyph, info, {TextTransparency = 1})

	task.wait(0.32)
	screenGui:Destroy()
end)

-- ЛОГИКА (из твоего рабочего файла, не менял)
local function moveTo(targetCFrame, setGravity)
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local distance = (root.Position - targetCFrame.Position).Magnitude
    local duration = distance / speed

    currentTween = TweenService:Create(root, TweenInfo.new(duration, Enum.EasingStyle.Linear), {CFrame = targetCFrame})
    currentTween:Play()

    local reached = false
    currentTween.Completed:Connect(function()
        reached = true
    end)

    if setGravity then
        workspace.Gravity = gravityNormal
    else
        workspace.Gravity = 0
    end

    while not reached and isRunning do
        RunService.Heartbeat:Wait()
    end
end

task.spawn(function()
    while true do
        task.wait(10)
        if isRunning then
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.K, false, game)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.K, false, game)
        end
    end
end)

local function autoFarmLoop()
    while isRunning do
        local char = player.Character or player.CharacterAdded:Wait()
        local root = char:WaitForChild("HumanoidRootPart", 5)
        if not root then return end

        for i, cf in ipairs(destinations) do
            if not isRunning then return end
            pcall(function()
                statusText.Text = ("flying %d/%d"):format(i, #destinations)
                statusText.TextColor3 = T.On
                statusDot.BackgroundColor3 = T.On
            end)
            moveTo(cf, i == #destinations)
        end

        repeat
            wait(1)
        until player.CharacterAdded:Wait()
    end
end

toggle.MouseButton1Click:Connect(function()
    isRunning = not isRunning
    if not isRunning then
        toggle.Text = "▶   START FARM"
        toggle.BackgroundColor3 = T.Accent
        pcall(function()
            statusText.Text = "idle"
            statusText.TextColor3 = T.TextDim
            statusDot.BackgroundColor3 = T.TextDim
        end)
        workspace.Gravity = gravityNormal
        if currentTween then
            currentTween:Cancel()
        end
    else
        toggle.Text = "■   STOP FARM"
        toggle.BackgroundColor3 = T.Danger
        pcall(function()
            statusText.Text = "starting..."
            statusText.TextColor3 = T.On
            statusDot.BackgroundColor3 = T.On
        end)
        task.spawn(autoFarmLoop)
    end
end)

player.CharacterAdded:Connect(function()
    if isRunning then
        task.spawn(autoFarmLoop)
    end
end)

player.CharacterAdded:Connect(function()
    if isRunning then
        local char = player.Character or player.CharacterAdded:Wait()
        local root = char:WaitForChild("HumanoidRootPart", 5)
        if root then
            wait(1)
            moveTo(destinations[1], false)
            task.spawn(autoFarmLoop)
        end
    end
end)
