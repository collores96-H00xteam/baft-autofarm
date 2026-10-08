local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
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

--// ========== THEME ==========
local T = {
	Bg      = Color3.fromRGB(20, 20, 26),
	Card    = Color3.fromRGB(34, 34, 44),
	Line    = Color3.fromRGB(58, 58, 76),
	Text    = Color3.fromRGB(245, 245, 255),
	TextDim = Color3.fromRGB(150, 150, 175),
	Accent  = Color3.fromRGB(130, 100, 255),
	Accent2 = Color3.fromRGB(255, 95, 180),
	On      = Color3.fromRGB(70, 220, 140),
	Danger  = Color3.fromRGB(235, 75, 95),
}

local function corner(p, r)
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 8); c.Parent = p
end
local function outline(p, color, th)
	local s = Instance.new("UIStroke"); s.Color = color or T.Line; s.Thickness = th or 1
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = p; return s
end

--// ========== GUI ==========
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoFarmUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() screenGui.Parent = game:GetService("CoreGui") end)
if not screenGui.Parent then screenGui.Parent = player:WaitForChild("PlayerGui") end

local menu = Instance.new("Frame")
menu.Size = UDim2.fromOffset(260, 128)
menu.Position = UDim2.new(0, 20, 0, 80)
menu.BackgroundColor3 = T.Bg
menu.BorderSizePixel = 0
menu.Active = true
menu.Draggable = true
menu.Parent = screenGui
corner(menu, 14)
outline(menu, T.Line, 1)

-- акцентная полоска сверху
local topLine = Instance.new("Frame")
topLine.Size = UDim2.new(1, 0, 0, 3)
topLine.BackgroundColor3 = T.Accent
topLine.BorderSizePixel = 0
topLine.Parent = menu
corner(topLine, 14)
local topGrad = Instance.new("UIGradient")
topGrad.Color = ColorSequence.new(T.Accent, T.Accent2)
topGrad.Parent = topLine

-- заголовок
local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.new(0, 14, 0, 10)
title.Size = UDim2.new(1, -50, 0, 18)
title.Font = Enum.Font.GothamBold
title.Text = "AUTO FARM"
title.TextColor3 = T.Text
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = menu

-- подпись
local subtitle = Instance.new("TextLabel")
subtitle.BackgroundTransparency = 1
subtitle.Position = UDim2.new(0, 14, 0, 28)
subtitle.Size = UDim2.new(1, -50, 0, 14)
subtitle.Font = Enum.Font.Gotham
subtitle.Text = "waypoints • anti-afk"
subtitle.TextColor3 = T.TextDim
subtitle.TextSize = 10
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = menu

-- кнопка закрытия
local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(20, 20)
close.Position = UDim2.new(1, -26, 0, 9)
close.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
close.BackgroundTransparency = 0.92
close.Text = "✕"
close.Font = Enum.Font.GothamBold
close.TextSize = 11
close.TextColor3 = T.Text
close.AutoButtonColor = false
close.Parent = menu
corner(close, 5)
close.MouseEnter:Connect(function()
	TweenService:Create(close, TweenInfo.new(0.15), {BackgroundTransparency = 0.7}):Play()
end)
close.MouseLeave:Connect(function()
	TweenService:Create(close, TweenInfo.new(0.15), {BackgroundTransparency = 0.92}):Play()
end)

-- кнопка START
local toggle = Instance.new("TextButton")
toggle.Size = UDim2.new(1, -28, 0, 40)
toggle.Position = UDim2.new(0, 14, 1, -52)
toggle.BackgroundColor3 = T.Accent
toggle.Text = "START"
toggle.Font = Enum.Font.GothamBold
toggle.TextSize = 14
toggle.TextColor3 = Color3.new(1, 1, 1)
toggle.AutoButtonColor = false
toggle.Parent = menu
corner(toggle, 10)
outline(toggle, T.Line, 1)

local btnGrad = Instance.new("UIGradient")
btnGrad.Color = ColorSequence.new(T.Accent, T.Accent2)
btnGrad.Parent = toggle

toggle.MouseEnter:Connect(function()
	if not isRunning then
		TweenService:Create(toggle, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(150, 120, 255)}):Play()
	end
end)
toggle.MouseLeave:Connect(function()
	if not isRunning then
		TweenService:Create(toggle, TweenInfo.new(0.15), {BackgroundColor3 = T.Accent}):Play()
	end
end)

--// ========== ЛОГИКА ==========

close.MouseButton1Click:Connect(function()
    isRunning = false
    workspace.Gravity = gravityNormal
    if currentTween then
        currentTween:Cancel()
    end
    screenGui:Destroy()
end)

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
        toggle.Text = "START"
        TweenService:Create(toggle, TweenInfo.new(0.2), {BackgroundColor3 = T.Accent}):Play()
        workspace.Gravity = gravityNormal
        if currentTween then
            currentTween:Cancel()
        end
    else
        toggle.Text = "STOP"
        TweenService:Create(toggle, TweenInfo.new(0.2), {BackgroundColor3 = T.Danger}):Play()
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
