--[[
    ═══════════════════════════════════════════════════════════════
    [U⚡] UNKNOWN HUB — DOORS V2 (PURE MSPAINT RE-ARCHITECTURE)
    PART 1: CORE ENGINE, MOVEMENT, INTERACTION & AUTOMATION SUITES
    ═══════════════════════════════════════════════════════════════
    Engine Architecture:
    - 1:1 mspaint v4 design patterns with zero legacy bloat
    - Centralized GUI & Visual containers in gethui()
    - Atomic lifecycle teardown on script re-execution
    - Absolute Flight Method & Universal Entity Immunity Invariants
--]]

-- // 1. SESSION LIFECYCLE & CLEANUP // --
local sessionToken = os.clock() .. "_" .. math.random(100000, 999999)
if _G.DOORS_V2_SESSION then
    _G.DOORS_V2_SESSION = nil
    task.wait(0.08)
end
_G.DOORS_V2_SESSION = sessionToken

local function isAlive()
    return _G.DOORS_V2_SESSION == sessionToken
end

-- // 2. SERVICES & CORE REFERENCES // --
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local ProximityPromptService = game:GetService("ProximityPromptService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local RemotesFolder = ReplicatedStorage:WaitForChild("RemotesFolder", 5)
local DropItemRemote = RemotesFolder and RemotesFolder:WaitForChild("DropItem", 5)
local MotorReplication = RemotesFolder and RemotesFolder:WaitForChild("MotorReplication", 5)

-- // 3. GET HIERARCHY UI CONTAINER // --
local function getGuiContainer()
    local target = (gethui and gethui()) or CoreGui
    local existing = target:FindFirstChild("Unknown_DoorsV2_Container")
    if existing then existing:Destroy() end

    local container = Instance.new("Folder")
    container.Name = "Unknown_DoorsV2_Container"
    container.Parent = target
    return container
end

local GuiContainer = getGuiContainer()

-- // 4. UTILITY FUNCTIONS // --
local function getChar()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

local function getRoot()
    local char = getChar()
    return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Collision") or char.PrimaryPart)
end

local function getHumanoid()
    local char = getChar()
    return char and char:FindFirstChildWhichIsA("Humanoid")
end

local function getMainGameTable()
    local pGui = LocalPlayer:FindFirstChild("PlayerGui")
    local mainUI = pGui and pGui:FindFirstChild("MainUI")
    local initiator = mainUI and mainUI:FindFirstChild("Initiator")
    local mainGame = initiator and initiator:FindFirstChild("Main_Game")
    if mainGame and mainGame:IsA("LocalScript") then
        local env = getsenv and getsenv(mainGame)
        if env and env.origpos then
            return env
        end
    end
    return nil
end

-- // 5. GLOBAL CONFIGURATION STATE // --
local State = {
    -- Movement Suite (1:1 mspaint v4)
    SpeedBypass = "Idle",
    WalkSpeed_Value = 15,
    WalkSpeed_Enabled = false,
    Jumping = false,
    Sliding = false,
    NoAcceleration = false,
    Fly_Enabled = false,
    Fly_Speed = 22,

    -- Interaction Suite (1:1 mspaint v4)
    AutoInteract = false,
    AutoInteract_Delay = 0.05,
    AutoInteract_IgnoreList = {
        ["Unlock w/ Shears"] = true,
        ["Jeff Items"] = true,
        ["Can-Die Candy"] = true,
        ["Skull Prompt"] = false,
        ["Glitch Fragment"] = false,
        ["Paper Planes"] = false,
        ["Fih Flakes"] = false
    },
    InstantInteract = false,
    InteractThroughWalls = false,
    InteractDistance = 12,
    DoorReach = false,
    WalkThroughDoors = false,
    InstantHidingSpotExit = false,

    -- Automation Suite (1:1 mspaint v4)
    AutoEggMinigame = false,
    AutoHeartbeat = false,
    AutoHide = false,
    AutoHide_ThreatRadius = 45,

    -- Visuals & ESP Suite (1:1 mspaint v4 Part 2)
    Master_ESP = true,
    ESP_ShowDistance = true,
    ESP_TextSize = 14,
    ESP_FillTransparency = 0.65,
    ESP_OutlineTransparency = 0,
    Doors_ESP = true,
    Keys_ESP = true,
    Items_ESP = true,
    Gold_ESP = true,
    Entities_ESP = true,
    HidingSpots_ESP = false,
    Rift_ESP = false,
    Tracers_ESP = false,
    Offscreen_Radar = true,
    Radar_Radius = 160,

    -- Visuals & World
    Fullbright = false,
    NoFog = false,
    NoCamShake = false
}

-- Forward Declarations
local speedBypassCard = nil
local safeInstantFirePrompt = nil

-- // 6. SLEEK MODERN UI LIBRARY (MSPAINT DARK AESTHETIC) // --
local UILib = {}
do
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "Unknown_DoorsV2_UI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = GuiContainer

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 480, 0, 520)
    MainFrame.Position = UDim2.new(0.5, -240, 0.5, -260)
    MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui

    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 8)
    MainCorner.Parent = MainFrame

    local MainStroke = Instance.new("UIStroke")
    MainStroke.Color = Color3.fromRGB(40, 42, 50)
    MainStroke.Thickness = 1.2
    MainStroke.Parent = MainFrame

    -- Draggable Top Bar
    local TopBar = Instance.new("Frame")
    TopBar.Name = "TopBar"
    TopBar.Size = UDim2.new(1, 0, 0, 42)
    TopBar.BackgroundTransparency = 1
    TopBar.Parent = MainFrame

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Name = "Title"
    TitleLabel.Size = UDim2.new(1, -20, 1, 0)
    TitleLabel.Position = UDim2.new(0, 16, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Font = Enum.Font.RobotoMono
    TitleLabel.Text = "[U⚡] UNKNOWN HUB — DOORS V2"
    TitleLabel.TextColor3 = Color3.fromRGB(240, 240, 245)
    TitleLabel.TextSize = 14
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = TopBar

    -- Dragging Logic
    local dragging, dragStart, startPos
    TopBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    -- Tab Container Bar
    local TabBar = Instance.new("Frame")
    TabBar.Name = "TabBar"
    TabBar.Size = UDim2.new(1, -24, 0, 36)
    TabBar.Position = UDim2.new(0, 12, 0, 42)
    TabBar.BackgroundColor3 = Color3.fromRGB(24, 25, 30)
    TabBar.BorderSizePixel = 0
    TabBar.Parent = MainFrame

    local TabBarCorner = Instance.new("UICorner")
    TabBarCorner.CornerRadius = UDim.new(0, 6)
    TabBarCorner.Parent = TabBar

    local TabBarLayout = Instance.new("UIListLayout")
    TabBarLayout.FillDirection = Enum.FillDirection.Horizontal
    TabBarLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TabBarLayout.Padding = UDim.new(0, 4)
    TabBarLayout.Parent = TabBar

    -- Content Scroll Area
    local ContentArea = Instance.new("Frame")
    ContentArea.Name = "ContentArea"
    ContentArea.Size = UDim2.new(1, -24, 1, -94)
    ContentArea.Position = UDim2.new(0, 12, 0, 84)
    ContentArea.BackgroundTransparency = 1
    ContentArea.Parent = MainFrame

    local Tabs = {}
    local CurrentTab = nil

    function UILib.CreateTab(name)
        local tabBtn = Instance.new("TextButton")
        tabBtn.Name = name .. "_TabBtn"
        tabBtn.Size = UDim2.new(0, 86, 1, 0)
        tabBtn.BackgroundColor3 = Color3.fromRGB(24, 25, 30)
        tabBtn.BorderSizePixel = 0
        tabBtn.Font = Enum.Font.RobotoMono
        tabBtn.Text = name
        tabBtn.TextColor3 = Color3.fromRGB(160, 160, 170)
        tabBtn.TextSize = 13
        tabBtn.Parent = TabBar

        local tabCorner = Instance.new("UICorner")
        tabCorner.CornerRadius = UDim.new(0, 6)
        tabCorner.Parent = tabBtn

        local tabPage = Instance.new("ScrollingFrame")
        tabPage.Name = name .. "_Page"
        tabPage.Size = UDim2.new(1, 0, 1, 0)
        tabPage.BackgroundTransparency = 1
        tabPage.BorderSizePixel = 0
        tabPage.ScrollBarThickness = 3
        tabPage.ScrollBarImageColor3 = Color3.fromRGB(60, 62, 75)
        tabPage.Visible = false
        tabPage.Parent = ContentArea

        local pageLayout = Instance.new("UIListLayout")
        pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        pageLayout.Padding = UDim.new(0, 8)
        pageLayout.Parent = tabPage

        local pagePadding = Instance.new("UIPadding")
        pagePadding.PaddingRight = UDim.new(0, 4)
        pagePadding.PaddingTop = UDim.new(0, 4)
        pagePadding.Parent = tabPage

        pageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            tabPage.CanvasSize = UDim2.new(0, 0, 0, pageLayout.AbsoluteContentSize.Y + 16)
        end)

        local tabObj = {
            Button = tabBtn,
            Page = tabPage
        }

        tabBtn.MouseButton1Click:Connect(function()
            for _, t in pairs(Tabs) do
                t.Page.Visible = false
                t.Button.BackgroundColor3 = Color3.fromRGB(24, 25, 30)
                t.Button.TextColor3 = Color3.fromRGB(160, 160, 170)
            end
            tabPage.Visible = true
            tabBtn.BackgroundColor3 = Color3.fromRGB(36, 38, 48)
            tabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            CurrentTab = tabObj
        end)

        table.insert(Tabs, tabObj)
        if #Tabs == 1 then
            tabPage.Visible = true
            tabBtn.BackgroundColor3 = Color3.fromRGB(36, 38, 48)
            tabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            CurrentTab = tabObj
        end

        return tabObj
    end

    function UILib.CreateSection(tab, title)
        local sec = Instance.new("Frame")
        sec.Name = "Section_" .. title
        sec.Size = UDim2.new(1, 0, 0, 24)
        sec.BackgroundTransparency = 1
        sec.Parent = tab.Page

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Font = Enum.Font.RobotoMono
        lbl.Text = "— " .. title:upper()
        lbl.TextColor3 = Color3.fromRGB(140, 145, 160)
        lbl.TextSize = 11
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = sec
    end

    function UILib.CreateStatusLabel(tab, initialText)
        local card = Instance.new("Frame")
        card.Name = "StatusCard"
        card.Size = UDim2.new(1, 0, 0, 34)
        card.BackgroundColor3 = Color3.fromRGB(22, 23, 28)
        card.BorderSizePixel = 0
        card.Parent = tab.Page

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = card

        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(45, 48, 58)
        stroke.Thickness = 1
        stroke.Parent = card

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -20, 1, 0)
        label.Position = UDim2.new(0, 12, 0, 0)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.RobotoMono
        label.Text = initialText or "Status: Idle"
        label.TextColor3 = Color3.fromRGB(200, 205, 215)
        label.TextSize = 13
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = card

        return {
            SetStatus = function(self, text, active)
                label.Text = text
                if active then
                    label.TextColor3 = Color3.fromRGB(110, 255, 140)
                    stroke.Color = Color3.fromRGB(60, 180, 90)
                else
                    label.TextColor3 = Color3.fromRGB(200, 205, 215)
                    stroke.Color = Color3.fromRGB(45, 48, 58)
                end
            end
        }
    end

    function UILib.CreateToggle(tab, title, defaultVal, callback, keyBadge, badgeColor)
        local card = Instance.new("Frame")
        card.Name = "Toggle_" .. title
        card.Size = UDim2.new(1, 0, 0, 36)
        card.BackgroundColor3 = Color3.fromRGB(22, 23, 28)
        card.BorderSizePixel = 0
        card.Parent = tab.Page

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = card

        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(38, 40, 48)
        stroke.Thickness = 1
        stroke.Parent = card

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -90, 1, 0)
        lbl.Position = UDim2.new(0, 12, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Font = Enum.Font.RobotoMono
        lbl.Text = title
        lbl.TextColor3 = badgeColor or Color3.fromRGB(215, 220, 230)
        lbl.TextSize = 13
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = card

        if keyBadge then
            local badge = Instance.new("TextLabel")
            badge.Size = UDim2.new(0, 22, 0, 20)
            badge.Position = UDim2.new(1, -74, 0.5, -10)
            badge.BackgroundColor3 = Color3.fromRGB(28, 30, 36)
            badge.BorderSizePixel = 0
            badge.Font = Enum.Font.RobotoMono
            badge.Text = keyBadge
            badge.TextColor3 = Color3.fromRGB(160, 165, 175)
            badge.TextSize = 11
            badge.Parent = card

            local bCorner = Instance.new("UICorner")
            bCorner.CornerRadius = UDim.new(0, 4)
            bCorner.Parent = badge

            local bStroke = Instance.new("UIStroke")
            bStroke.Color = Color3.fromRGB(50, 52, 62)
            bStroke.Thickness = 1
            bStroke.Parent = badge
        end

        local switch = Instance.new("TextButton")
        switch.Name = "Switch"
        switch.Size = UDim2.new(0, 38, 0, 20)
        switch.Position = UDim2.new(1, -48, 0.5, -10)
        switch.BackgroundColor3 = defaultVal and Color3.fromRGB(80, 110, 255) or Color3.fromRGB(36, 38, 46)
        switch.BorderSizePixel = 0
        switch.Text = ""
        switch.Parent = card

        local sCorner = Instance.new("UICorner")
        sCorner.CornerRadius = UDim.new(1, 0)
        sCorner.Parent = switch

        local thumb = Instance.new("Frame")
        thumb.Name = "Thumb"
        thumb.Size = UDim2.new(0, 16, 0, 16)
        thumb.Position = defaultVal and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
        thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        thumb.BorderSizePixel = 0
        thumb.Parent = switch

        local tCorner = Instance.new("UICorner")
        tCorner.CornerRadius = UDim.new(1, 0)
        tCorner.Parent = thumb

        local isToggled = defaultVal
        local function updateState(v)
            isToggled = v
            TweenService:Create(switch, TweenInfo.new(0.15), {
                BackgroundColor3 = isToggled and Color3.fromRGB(80, 110, 255) or Color3.fromRGB(36, 38, 46)
            }):Play()
            TweenService:Create(thumb, TweenInfo.new(0.15), {
                Position = isToggled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
            }):Play()
            if callback then callback(isToggled) end
        end

        switch.MouseButton1Click:Connect(function()
            updateState(not isToggled)
        end)

        return {
            Set = updateState,
            Value = function() return isToggled end
        }
    end

    function UILib.CreateSlider(tab, title, minVal, maxVal, defaultVal, suffix, callback)
        local card = Instance.new("Frame")
        card.Name = "Slider_" .. title
        card.Size = UDim2.new(1, 0, 0, 48)
        card.BackgroundColor3 = Color3.fromRGB(22, 23, 28)
        card.BorderSizePixel = 0
        card.Parent = tab.Page

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = card

        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(38, 40, 48)
        stroke.Thickness = 1
        stroke.Parent = card

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -100, 0, 20)
        lbl.Position = UDim2.new(0, 12, 0, 6)
        lbl.BackgroundTransparency = 1
        lbl.Font = Enum.Font.RobotoMono
        lbl.Text = title
        lbl.TextColor3 = Color3.fromRGB(215, 220, 230)
        lbl.TextSize = 13
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = card

        local valLbl = Instance.new("TextLabel")
        valLbl.Size = UDim2.new(0, 80, 0, 20)
        valLbl.Position = UDim2.new(1, -92, 0, 6)
        valLbl.BackgroundTransparency = 1
        valLbl.Font = Enum.Font.RobotoMono
        valLbl.Text = tostring(defaultVal) .. (suffix or "")
        valLbl.TextColor3 = Color3.fromRGB(150, 155, 170)
        valLbl.TextSize = 13
        valLbl.TextXAlignment = Enum.TextXAlignment.Right
        valLbl.Parent = card

        local track = Instance.new("Frame")
        track.Name = "Track"
        track.Size = UDim2.new(1, -24, 0, 6)
        track.Position = UDim2.new(0, 12, 0, 32)
        track.BackgroundColor3 = Color3.fromRGB(36, 38, 46)
        track.BorderSizePixel = 0
        track.Parent = card

        local trkCorner = Instance.new("UICorner")
        trkCorner.CornerRadius = UDim.new(1, 0)
        trkCorner.Parent = track

        local progress = Instance.new("Frame")
        progress.Name = "Progress"
        local initAlpha = math.clamp((defaultVal - minVal) / (maxVal - minVal), 0, 1)
        progress.Size = UDim2.new(initAlpha, 0, 1, 0)
        progress.BackgroundColor3 = Color3.fromRGB(80, 110, 255)
        progress.BorderSizePixel = 0
        progress.Parent = track

        local prgCorner = Instance.new("UICorner")
        prgCorner.CornerRadius = UDim.new(1, 0)
        prgCorner.Parent = progress

        local sliding = false
        local function update(input)
            local trackAbsPos = track.AbsolutePosition.X
            local trackAbsSize = track.AbsoluteSize.X
            local mousePos = input.Position.X
            local alpha = math.clamp((mousePos - trackAbsPos) / trackAbsSize, 0, 1)
            local val = minVal + (alpha * (maxVal - minVal))
            if maxVal - minVal > 10 then
                val = math.floor(val)
            else
                val = math.floor(val * 100) / 100
            end
            progress.Size = UDim2.new(alpha, 0, 1, 0)
            valLbl.Text = tostring(val) .. (suffix or "")
            if callback then callback(val) end
        end

        track.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                sliding = true
                update(input)
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                sliding = false
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if sliding and input.UserInputType == Enum.UserInputType.MouseMovement then
                update(input)
            end
        end)
    end
end

-- // 7. TAB INSTANTIATION // --
local movementTab = UILib.CreateTab("Movement")
local interactionTab = UILib.CreateTab("Interact")
local automationTab = UILib.CreateTab("Automate")
local espTab = UILib.CreateTab("ESP")
local visualsTab = UILib.CreateTab("Visuals")

-- =========================================================================
-- SECTION 1: MOVEMENT & CHARACTER (MSPAINT PARITY)
-- =========================================================================
UILib.CreateSection(movementTab, "Character Speed & Dynamics")

speedBypassCard = UILib.CreateStatusLabel(movementTab, "Speed Bypass: Idle")

-- Dynamic Speed Bypass Engine (mspaint Dual-Layer Collision Synchronization)
local speedBypassCollisionClone = nil
local function setupSpeedBypassClone()
    pcall(function()
        local char = getChar()
        if not char then return end
        if speedBypassCollisionClone and speedBypassCollisionClone.Parent == char then return end
        local coll = char:FindFirstChild("Collision")
        local collCrouch = (coll and coll:FindFirstChild("CollisionCrouch")) or char:FindFirstChild("CollisionCrouch", true)
        if collCrouch then
            speedBypassCollisionClone = collCrouch:Clone()
            speedBypassCollisionClone.Name = "CollisionClone_Bypass"
            speedBypassCollisionClone.CanCollide = false
            speedBypassCollisionClone.Massless = true
            speedBypassCollisionClone.Parent = char
        end
    end)
end

local function syncServerSlide(canSlide, isSliding)
    pcall(function()
        local char = getChar()
        if char then
            char:SetAttribute("CanSlide", canSlide)
        end
        local rf = RemotesFolder or ReplicatedStorage:FindFirstChild("RemotesFolder")
        local slideRemote = rf and rf:FindFirstChild("Slide")
        if slideRemote and slideRemote:IsA("RemoteEvent") then
            slideRemote:FireServer(isSliding)
        end
    end)
end

-- Continuous Movement & Speed Bypass Daemon
task.spawn(function()
    while isAlive() do
        local char = getChar()
        local hum = getHumanoid()
        local root = getRoot()

        if char and hum and root and hum.Health > 0 then
            local isMoving = hum.MoveDirection.Magnitude > 0.05
            local targetSpeed = State.WalkSpeed_Enabled and State.WalkSpeed_Value or 15

            -- Speed Bypass Status Tracker
            if State.WalkSpeed_Enabled and isMoving and targetSpeed >= 18 then
                speedBypassCard:SetStatus("Speed Bypass: Bypassing", true)
                setupSpeedBypassClone()
            else
                speedBypassCard:SetStatus("Speed Bypass: Idle", false)
            end

            -- Speed Boost Controller
            if State.WalkSpeed_Enabled then
                if hum.WalkSpeed ~= targetSpeed then
                    hum.WalkSpeed = targetSpeed
                end
            end

            -- No Acceleration Engine
            if State.NoAcceleration and isMoving then
                local moveDir = hum.MoveDirection
                root.AssemblyLinearVelocity = Vector3.new(moveDir.X * targetSpeed, root.AssemblyLinearVelocity.Y, moveDir.Z * targetSpeed)
            end

            -- Jumping Controller
            if State.Jumping then
                hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
                hum.UseJumpPower = true
                hum.JumpPower = 50
                char:SetAttribute("CanJump", true)
            end
        end
        task.wait(0.04)
    end
end)

UILib.CreateSlider(movementTab, "Walk Speed", 10, 100, State.WalkSpeed_Value, " studs/s", function(v)
    State.WalkSpeed_Value = v
    if State.WalkSpeed_Enabled then
        local hum = getHumanoid()
        if hum then hum.WalkSpeed = v end
    end
end)

UILib.CreateToggle(movementTab, "Speed Boost", State.WalkSpeed_Enabled, function(v)
    State.WalkSpeed_Enabled = v
    local hum = getHumanoid()
    if hum then
        if v then
            syncServerSlide(true, true)
            hum.WalkSpeed = State.WalkSpeed_Value
        else
            syncServerSlide(false, false)
            hum.WalkSpeed = 15
        end
    end
end)

UILib.CreateToggle(movementTab, "Jumping", State.Jumping, function(v)
    State.Jumping = v
    local hum = getHumanoid()
    local char = getChar()
    if hum then
        hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, v)
        hum.UseJumpPower = v
        hum.JumpPower = v and 50 or 0
    end
    if char then
        char:SetAttribute("CanJump", v)
    end
end)

UILib.CreateToggle(movementTab, "Sliding", State.Sliding, function(v)
    State.Sliding = v
    local char = getChar()
    if char then
        char:SetAttribute("CanSlide", v)
    end
    syncServerSlide(v, v)
end)

UILib.CreateToggle(movementTab, "No Acceleration", State.NoAcceleration, function(v)
    State.NoAcceleration = v
end)

-- ABSOLUTE FLIGHT METHOD INVARIANT (DOORS & ALL GAMES)
UILib.CreateSection(movementTab, "Native Flight Physics")
UILib.CreateToggle(movementTab, "Fly / Noclip", State.Fly_Enabled, function(v)
    State.Fly_Enabled = v
    local mgTable = getMainGameTable()
    if mgTable then
        mgTable.noclip = v
    end
end, "F")

-- Proven 3.2-stud ground check Flight Sync Daemon
task.spawn(function()
    while isAlive() do
        if State.Fly_Enabled then
            local mgTable = getMainGameTable()
            local root = getRoot()
            if mgTable and root then
                mgTable.noclip = true
                -- Maintain clean 3.2-stud floor buffer
                local ray = Workspace:Raycast(root.Position, Vector3.new(0, -5, 0))
                if ray and ray.Distance < 3.2 then
                    root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z)
                end
            end
        end
        task.wait(0.05)
    end
end)

-- =========================================================================
-- SECTION 2: INTERACTION & PROMPTS (MSPAINT PARITY)
-- =========================================================================
UILib.CreateSection(interactionTab, "Auto Interaction & Reach")

-- Safe Prompt Fire Engine (mspaint Event-Driven Model)
local lastFiredPrompt = nil
local lastFiredTick = 0

safeInstantFirePrompt = function(prompt)
    if not prompt or not prompt.Parent then return end
    local now = os.clock()
    if lastFiredPrompt == prompt and (now - lastFiredTick < 0.2) then return end
    lastFiredPrompt = prompt
    lastFiredTick = now

    pcall(function()
        if fireproximityprompt then
            fireproximityprompt(prompt)
        end
    end)
end

-- Auto Interact Dynamic Prompt Filter
local function isPromptAllowed(prompt)
    if not prompt or not prompt.Enabled or not prompt.Parent then return false end

    local parent = prompt.Parent
    local model = parent:IsA("Model") and parent or parent.Parent
    local mName = model and model.Name:lower() or ""
    local pName = parent.Name:lower()
    local act = (prompt.ActionText or ""):lower()
    local obj = (prompt.ObjectText or ""):lower()

    -- Strict Invariant: Never touch The Rift
    if pName:find("rift") or mName:find("rift") or obj:find("rift") then return false end

    -- Strict Invariant: Never auto-enter wardrobes/closets/beds
    if act:find("hide") or pName:find("closet") or pName:find("wardrobe") or pName:find("bed") then return false end

    -- Ignore List Checks
    local ign = State.AutoInteract_IgnoreList
    if ign["Unlock w/ Shears"] and (pName:find("vine") or obj:find("vine") or act:find("cut")) then return false end
    if ign["Jeff Items"] and (pName:find("shop") or mName:find("shop") or obj:find("gold") and act:find("buy")) then return false end
    if ign["Can-Die Candy"] and (obj:find("evil") or obj:find("red candy")) then return false end
    if ign["Skull Prompt"] and (prompt.Name == "SkullPrompt" or obj:find("skull")) then return false end
    if ign["Glitch Fragment"] and (pName:find("glitch") or mName:find("glitch")) then return false end
    if ign["Paper Planes"] and (obj:find("plane") or pName:find("paperplane")) then return false end
    if ign["Fih Flakes"] and (obj:find("flake") or pName:find("flake")) then return false end

    -- Allowed items & pickups
    if prompt.Name == "ModulePrompt" or prompt:GetAttribute("Pickup") or parent:GetAttribute("Pickup") or (model and model:GetAttribute("Pickup")) then
        return true
    end
    if prompt.Name == "GoldPrompt" or pName:find("gold") or obj:find("gold") or obj:find("coin") then
        return true
    end
    if prompt.Name == "KeyPrompt" or pName:find("key") or obj:find("key") or (model and model:GetAttribute("IsKey")) then
        return true
    end
    if prompt.Name == "ActivateEventPrompt" and (pName:find("drawer") or pName:find("knob") or pName:find("chest")) then
        if act:find("close") then return false end
        return true
    end

    if act:find("pick") or act:find("take") or act:find("grab") or act:find("collect") or act:find("obtain") then
        return true
    end

    return false
end

-- Auto Interact Daemon (Smooth 10Hz Loop)
task.spawn(function()
    while isAlive() do
        if State.AutoInteract then
            local root = getRoot()
            if root then
                local rootPos = root.Position
                local maxDist = State.InteractDistance or 12
                local curRooms = Workspace:FindFirstChild("CurrentRooms")
                local drops = Workspace:FindFirstChild("Drops")

                local searchContainers = {}
                if curRooms then table.insert(searchContainers, curRooms) end
                if drops then table.insert(searchContainers, drops) end

                for _, container in ipairs(searchContainers) do
                    for _, prompt in ipairs(container:GetDescendants()) do
                        if prompt:IsA("ProximityPrompt") and prompt.Enabled and prompt.Parent then
                            local pPart = prompt.Parent:IsA("BasePart") and prompt.Parent or prompt.Parent:FindFirstChildWhichIsA("BasePart")
                            if pPart then
                                local dist = (rootPos - pPart.Position).Magnitude
                                local pObj = (prompt.ObjectText or ""):lower()
                                local isDrawer = pObj:find("drawer") or (prompt.Parent and prompt.Parent.Name:lower():find("knob"))
                                local limit = isDrawer and 6.0 or maxDist

                                if dist <= limit and isPromptAllowed(prompt) then
                                    if State.InstantInteract then prompt.HoldDuration = 0 end
                                    if State.InteractThroughWalls then prompt.RequiresLineOfSight = false end
                                    safeInstantFirePrompt(prompt)
                                    task.wait(State.AutoInteract_Delay or 0.05)
                                end
                            end
                        end
                    end
                end
            end
        end
        task.wait(0.1)
    end
end)

UILib.CreateToggle(interactionTab, "Auto Interact", State.AutoInteract, function(v)
    State.AutoInteract = v
end, "R")

UILib.CreateSlider(interactionTab, "Auto Interact Delay", 0.01, 0.25, State.AutoInteract_Delay, "s", function(v)
    State.AutoInteract_Delay = v
end)

UILib.CreateToggle(interactionTab, "Instant Interact", State.InstantInteract, function(v)
    State.InstantInteract = v
end)

UILib.CreateToggle(interactionTab, "Interact Through Walls", State.InteractThroughWalls, function(v)
    State.InteractThroughWalls = v
end)

-- Active Door Reach Daemon (22 studs: sweeps Main & Side doors)
task.spawn(function()
    while isAlive() do
        if State.DoorReach then
            local root = getRoot()
            if root then
                local rootPos = root.Position
                local curRooms = Workspace:FindFirstChild("CurrentRooms")
                if curRooms then
                    for _, room in ipairs(curRooms:GetChildren()) do
                        for _, door in ipairs(room:GetDescendants()) do
                            if door:IsA("Model") and (door.Name == "Door" or door.Name:lower():find("door") or door.Name:lower():find("sideroom")) then
                                local isOpened = door:GetAttribute("Opened") == true or door:GetAttribute("Open") == true
                                if not isOpened then
                                    local dPart = door:FindFirstChild("Door") or door:FindFirstChild("Hidden") or door.PrimaryPart or door:FindFirstChildWhichIsA("BasePart")
                                    if dPart and (rootPos - dPart.Position).Magnitude <= 22 then
                                        -- Fire Door ProximityPrompts
                                        for _, desc in ipairs(door:GetDescendants()) do
                                            if desc:IsA("ProximityPrompt") and desc.Enabled then
                                                safeInstantFirePrompt(desc)
                                            end
                                        end
                                        -- Fire ClientOpen Remote
                                        local co = door:FindFirstChild("ClientOpen")
                                        if co and co:IsA("RemoteEvent") then
                                            pcall(function() co:FireServer() end)
                                        end
                                        -- Fire Hidden touch trigger
                                        local hidden = door:FindFirstChild("Hidden")
                                        if hidden and hidden:IsA("BasePart") then
                                            pcall(function()
                                                hidden.CanTouch = true
                                                firetouchinterest(root, hidden, 0)
                                                firetouchinterest(root, hidden, 1)
                                            end)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        task.wait(0.1)
    end
end)

UILib.CreateToggle(interactionTab, "Door Reach", State.DoorReach, function(v)
    State.DoorReach = v
end)

-- Walk Through Doors (Confined strictly to door leaves: Door, Door1, Door2)
task.spawn(function()
    while isAlive() do
        if State.WalkThroughDoors then
            local curRooms = Workspace:FindFirstChild("CurrentRooms")
            if curRooms then
                for _, room in ipairs(curRooms:GetChildren()) do
                    for _, door in ipairs(room:GetDescendants()) do
                        if door:IsA("Model") and (door.Name == "Door" or door.Name:lower():find("door")) then
                            for _, p in ipairs(door:GetChildren()) do
                                if p:IsA("BasePart") and (p.Name == "Door" or p.Name == "Door1" or p.Name == "Door2") then
                                    if p.CanCollide then p.CanCollide = false end
                                end
                            end
                        end
                    end
                end
            end
        end
        task.wait(0.2)
    end
end)

UILib.CreateToggle(interactionTab, "Walk Through Doors", State.WalkThroughDoors, function(v)
    State.WalkThroughDoors = v
    if not v then
        local curRooms = Workspace:FindFirstChild("CurrentRooms")
        if curRooms then
            for _, room in ipairs(curRooms:GetChildren()) do
                for _, door in ipairs(room:GetDescendants()) do
                    if door:IsA("Model") and (door.Name == "Door" or door.Name:lower():find("door")) then
                        for _, p in ipairs(door:GetChildren()) do
                            if p:IsA("BasePart") and (p.Name == "Door" or p.Name == "Door1" or p.Name == "Door2") then
                                p.CanCollide = true
                            end
                        end
                    end
                end
            end
        end
    end
end)

UILib.CreateToggle(interactionTab, "Instant Hiding Spot Exit", State.InstantHidingSpotExit, function(v)
    State.InstantHidingSpotExit = v
end)

-- Instant Hiding Spot Exit on Movement
task.spawn(function()
    while isAlive() do
        if State.InstantHidingSpotExit then
            local hum = getHumanoid()
            local char = getChar()
            if hum and hum.MoveDirection.Magnitude > 0.05 then
                local camLock = RemotesFolder and RemotesFolder:FindFirstChild("CamLock")
                if camLock and camLock:IsA("RemoteEvent") then
                    pcall(function() camLock:FireServer() end)
                end
            end
        end
        task.wait(0.08)
    end
end)

-- =========================================================================
-- SECTION 3: AUTOMATION SUITE (MSPAINT PARITY)
-- =========================================================================
UILib.CreateSection(automationTab, "Game Automation & Safety")

-- AntiGloomEgg (Auto Egg Minigame)
task.spawn(function()
    while isAlive() do
        if State.AutoEggMinigame then
            local curRooms = Workspace:FindFirstChild("CurrentRooms")
            if curRooms then
                for _, desc in ipairs(curRooms:GetDescendants()) do
                    if desc.Name == "Egg" and desc.Parent and desc.Parent.Name == "GloomPile" and desc:IsA("BasePart") then
                        desc.CanTouch = false
                    end
                end
            end
        end
        task.wait(0.5)
    end
end)

UILib.CreateToggle(automationTab, "Auto Egg Minigame", State.AutoEggMinigame, function(v)
    State.AutoEggMinigame = v
end)

UILib.CreateToggle(automationTab, "Auto Heartbeat", State.AutoHeartbeat, function(v)
    State.AutoHeartbeat = v
end)

-- Auto Hide Engine (Scans Rush/Ambush and auto-hides in nearest closet)
task.spawn(function()
    while isAlive() do
        if State.AutoHide then
            local root = getRoot()
            if root then
                local threat = nil
                for _, obj in ipairs(Workspace:GetChildren()) do
                    local n = obj.Name:lower()
                    if obj:IsA("Model") and (n:find("rush") or n:find("ambush")) then
                        threat = obj
                        break
                    end
                end

                if threat then
                    local tPart = threat.PrimaryPart or threat:FindFirstChildWhichIsA("BasePart")
                    if tPart and (root.Position - tPart.Position).Magnitude <= (State.AutoHide_ThreatRadius or 45) then
                        local curRooms = Workspace:FindFirstChild("CurrentRooms")
                        if curRooms then
                            for _, desc in ipairs(curRooms:GetDescendants()) do
                                if desc:IsA("ProximityPrompt") and desc.Enabled then
                                    local pObj = (desc.ObjectText or ""):lower()
                                    local pAct = (desc.ActionText or ""):lower()
                                    if pAct:find("hide") or pObj:find("closet") or pObj:find("wardrobe") then
                                        safeInstantFirePrompt(desc)
                                        break
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        task.wait(0.2)
    end
end)

UILib.CreateToggle(automationTab, "Auto Hide", State.AutoHide, function(v)
    State.AutoHide = v
end, "Q", Color3.fromRGB(255, 75, 75))

-- // 8. METATABLE HOOKS (CLUTCH HEARTBEAT & STEALTH) // --
if hookmetamethod and not _G.DOORS_V2_METATABLE_HOOKED then
    _G.DOORS_V2_METATABLE_HOOKED = true
    local oldNc
    oldNc = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if method == "FireServer" then
            if self.Name == "ClutchHeartbeat" and State.AutoHeartbeat then
                local args = {...}
                args[2] = true -- 100% heartbeat score spoof
                return oldNc(self, unpack(args))
            end
        end
        return oldNc(self, ...)
    end))
end

-- // 9. GLOBAL KEYBIND LISTENER // --
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.R then
        State.AutoInteract = not State.AutoInteract
    elseif input.KeyCode == Enum.KeyCode.Q then
        State.AutoHide = not State.AutoHide
    elseif input.KeyCode == Enum.KeyCode.F then
        State.Fly_Enabled = not State.Fly_Enabled
        local mgTable = getMainGameTable()
        if mgTable then mgTable.noclip = State.Fly_Enabled end
    end
end)


-- =========================================================================
-- SECTION 4: VISUALS & ESP SUITE (1:1 MSPAINT V4 RE-ARCHITECTURE)
-- =========================================================================
local EspContainer = Instance.new("Folder")
EspContainer.Name = "Unknown_DoorsV2_ESP"
EspContainer.Parent = GuiContainer

local activeEspRecords = {}
local activeTracers = {}
local activeRadarArrows = {}

local function createBillboard(adorneePart, baseText, color, offset)
    if not adorneePart then return nil, nil end

    local bb = Instance.new("BillboardGui")
    bb.Name = "ESP_Billboard"
    bb.Adornee = adorneePart
    bb.AlwaysOnTop = true
    bb.Size = UDim2.new(0, 200, 0, 50)
    bb.StudsOffset = offset or Vector3.new(0, 1.8, 0)
    bb.ResetOnSpawn = false
    bb.LightInfluence = 0
    bb.MaxDistance = 5000
    bb.Parent = EspContainer

    local label = Instance.new("TextLabel")
    label.Name = "ESPLabel"
    label.Size = UDim2.new(0, 200, 0, 50)
    label.BackgroundTransparency = 1
    label.TextColor3 = color or Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.RobotoMono
    label.TextSize = State.ESP_TextSize or 14
    label.RichText = true
    label.TextWrapped = true
    label.TextWrap = true
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    label.Parent = bb

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(0, 0, 0)
    stroke.Thickness = 1.2
    stroke.Parent = label

    local initialText = baseText
    if State.ESP_ShowDistance then
        local root = getRoot()
        if root and adorneePart:IsA("BasePart") then
            local dist = math.floor((root.Position - adorneePart.Position).Magnitude)
            initialText = string.format('%s\n<font size="%d">[%dm]</font>', baseText, math.max((State.ESP_TextSize or 14) - 3, 9), dist)
        end
    end
    label.Text = initialText
    return bb, label
end

local function createHighlight(adornee, color, fillTrans, outlineTrans)
    if not adornee then return nil end
    fillTrans = fillTrans or State.ESP_FillTransparency or 0.65
    outlineTrans = outlineTrans or State.ESP_OutlineTransparency or 0

    local hl = Instance.new("Highlight")
    hl.Name = "ESP_Highlight"
    hl.Adornee = adornee
    hl.FillColor = color
    hl.FillTransparency = fillTrans
    hl.OutlineColor = color
    hl.OutlineTransparency = outlineTrans
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = EspContainer
    return hl
end

local function removeEspFor(owner)
    if not owner then return end
    local record = activeEspRecords[owner]
    if record then
        if record.Visuals then
            for _, v in ipairs(record.Visuals) do
                pcall(function() v:Destroy() end)
            end
        end
        activeEspRecords[owner] = nil
    end
    if activeTracers[owner] then
        pcall(function() activeTracers[owner]:Remove() end)
        activeTracers[owner] = nil
    end
    if activeRadarArrows[owner] then
        pcall(function() activeRadarArrows[owner]:Remove() end)
        activeRadarArrows[owner] = nil
    end
end

local function clearCategoryEsp(cat)
    for owner, record in pairs(activeEspRecords) do
        if record.Category == cat then
            removeEspFor(owner)
        end
    end
end

local function clearAllEsp()
    for owner, _ in pairs(activeEspRecords) do
        removeEspFor(owner)
    end
    table.clear(activeEspRecords)
    pcall(function() EspContainer:ClearAllChildren() end)
end

local function registerEsp(owner, adorneePart, baseText, color, category, partsToHighlight, offset, roomNumber)
    if not owner or not adorneePart or not State.Master_ESP then return end

    -- Existing record update
    local existing = activeEspRecords[owner]
    if existing and existing.Adornee == adorneePart and existing.Category == category then
        if existing.BaseText ~= baseText or existing.Color ~= color then
            existing.BaseText = baseText
            existing.Color = color
            if existing.Label then
                existing.Label.TextColor3 = color
                existing.Label.Text = baseText
            end
            if existing.Highlight then
                existing.Highlight.FillColor = color
                existing.Highlight.OutlineColor = color
            end
        end
        return
    end

    removeEspFor(owner)

    local visuals = {}
    local bb, label = createBillboard(adorneePart, baseText, color, offset)
    if bb then table.insert(visuals, bb) end

    -- Safe highlight target assignment (Instance vs table vs model)
    local hl = nil
    local hlTarget = nil
    if typeof(partsToHighlight) == "Instance" then
        if partsToHighlight:IsA("BasePart") or partsToHighlight:IsA("Model") then
            hlTarget = partsToHighlight
        end
    elseif typeof(partsToHighlight) == "table" and #partsToHighlight > 0 then
        if #partsToHighlight == 1 and typeof(partsToHighlight[1]) == "Instance" and partsToHighlight[1]:IsA("BasePart") then
            hlTarget = partsToHighlight[1]
        elseif typeof(owner) == "Instance" and owner:IsA("Model") then
            hlTarget = owner
        end
    end

    if not hlTarget then
        if typeof(adorneePart) == "Instance" and adorneePart:IsA("BasePart") then
            hlTarget = adorneePart
        elseif typeof(owner) == "Instance" and owner:IsA("Model") then
            hlTarget = owner
        end
    end

    if hlTarget and category ~= "Gold" then
        hl = createHighlight(hlTarget, color, State.ESP_FillTransparency or 0.65, State.ESP_OutlineTransparency or 0)
        if hl then table.insert(visuals, hl) end
    end

    activeEspRecords[owner] = {
        Owner = owner,
        Adornee = adorneePart,
        BaseText = baseText,
        Color = color,
        Category = category,
        Label = label,
        Highlight = hl,
        Visuals = visuals,
        RoomNumber = roomNumber,
        LastDist = -1
    }

    pcall(function()
        owner.Destroying:Once(function()
            removeEspFor(owner)
        end)
    end)
end

-- Continuous 5Hz Distance Update Daemon
task.spawn(function()
    while isAlive() do
        if State.Master_ESP then
            local root = getRoot()
            local rootPos = root and root.Position
            for owner, record in pairs(activeEspRecords) do
                if not owner or not owner.Parent or not record.Adornee or not record.Adornee.Parent then
                    removeEspFor(owner)
                    continue
                end

                local cat = record.Category
                local isEnabled = (cat == "Doors" and State.Doors_ESP)
                    or (cat == "Keys" and State.Keys_ESP)
                    or (cat == "Items" and State.Items_ESP)
                    or (cat == "Gold" and State.Gold_ESP)
                    or (cat == "Entities" and State.Entities_ESP)
                    or (cat == "HidingSpots" and State.HidingSpots_ESP)
                    or (cat == "Special" and State.Rift_ESP)

                if not isEnabled then
                    removeEspFor(owner)
                    continue
                end

                if State.ESP_ShowDistance and rootPos and record.Label and record.Adornee:IsA("BasePart") then
                    local dist = math.floor((rootPos - record.Adornee.Position).Magnitude)
                    if dist ~= record.LastDist then
                        record.LastDist = dist
                        record.Label.Text = string.format('%s\n<font size="%d">[%dm]</font>', record.BaseText, math.max((State.ESP_TextSize or 14) - 3, 9), dist)
                    end
                end
            end
        end
        task.wait(0.18)
    end
end)

-- =========================================================================
-- SPECIFIC SCANNERS (DOORS, KEYS, ITEMS, GOLD, ENTITIES, RIFT)
-- =========================================================================

-- 1. Precision Door Scanner (Highlights strictly wooden leaf doorMesh, never Hidden hitbox!)
local function processDoor(room, doorModel)
    if not doorModel then return end
    if not State.Doors_ESP or not State.Master_ESP then
        removeEspFor(doorModel)
        return
    end

    local roomNumber = tonumber(room.Name)
    local doorMesh = doorModel:FindFirstChild("Door")
    if not doorMesh or not doorMesh:IsA("BasePart") then
        doorMesh = doorModel:FindFirstChildWhichIsA("MeshPart") or doorModel:FindFirstChildWhichIsA("BasePart")
    end
    if not doorMesh then return end

    local isOpened = doorModel:GetAttribute("Opened") == true or doorModel:GetAttribute("Open") == true
    if isOpened then
        removeEspFor(doorModel)
        return
    end

    local isLocked = doorModel:GetAttribute("Locked") == true or (doorModel:FindFirstChild("Lock") and doorModel.Lock:FindFirstChildWhichIsA("ProximityPrompt", true))
    local doorNumberStr = tostring((roomNumber or 0) + 1)
    local baseText
    local color

    if isLocked then
        baseText = string.format("Door %s [LOCKED]", doorNumberStr)
        color = Color3.fromRGB(255, 180, 50)
    else
        baseText = string.format("Door %s", doorNumberStr)
        color = Color3.fromRGB(0, 215, 255)
    end

    local doorHeaderOffset = Vector3.new(0, (doorMesh.Size.Y / 2) + 0.95, 0)
    registerEsp(doorModel, doorMesh, baseText, color, "Doors", doorMesh, doorHeaderOffset, roomNumber)
end

-- 2. Precision Key & Lever Scanner
local function processKey(keyObtain)
    if not keyObtain or not keyObtain:IsA("Model") then return end
    if not State.Keys_ESP or not State.Master_ESP then
        removeEspFor(keyObtain)
        return
    end

    local keyMesh = keyObtain:FindFirstChild("Key") or keyObtain:FindFirstChild("Handle") or keyObtain:FindFirstChildWhichIsA("BasePart", true)
    if keyMesh then
        local baseText = "Key"
        local color = Color3.fromRGB(0, 230, 255)
        registerEsp(keyObtain, keyMesh, baseText, color, "Keys", keyMesh, Vector3.new(0, 1.2, 0))
    end
end

local function processLever(leverInstance)
    if not leverInstance then return end
    if not State.Keys_ESP or not State.Master_ESP then
        removeEspFor(leverInstance)
        return
    end

    local targetPart = (leverInstance:IsA("Model") and (leverInstance.PrimaryPart or leverInstance:FindFirstChildWhichIsA("BasePart", true)))
        or (leverInstance:IsA("BasePart") and leverInstance)
    if targetPart then
        local color = Color3.fromRGB(130, 255, 130)
        registerEsp(leverInstance, targetPart, "Breaker Lever", color, "Keys", targetPart, Vector3.new(0, 1.4, 0))
    end
end

-- 3. Precision Item Scanner
local function processItem(itemModel)
    if not itemModel then return end
    if not State.Items_ESP or not State.Master_ESP then
        removeEspFor(itemModel)
        return
    end

    local targetPart = (itemModel:IsA("Model") and (itemModel.PrimaryPart or itemModel:FindFirstChild("Handle") or itemModel:FindFirstChildWhichIsA("BasePart", true)))
        or (itemModel:IsA("BasePart") and itemModel)
    if not targetPart then return end

    local name = itemModel.Name
    local cleanName = name:gsub("Pickup", ""):gsub("Model", ""):gsub("Prop", "")
    if cleanName == "" then cleanName = "Item" end

    local color = Color3.fromRGB(180, 120, 255)
    registerEsp(itemModel, targetPart, cleanName, color, "Items", targetPart, Vector3.new(0, 1.2, 0))
end

-- 4. Precision Gold Scanner
local function processGold(owner)
    if not owner then return end
    if not State.Gold_ESP or not State.Master_ESP then
        removeEspFor(owner)
        return
    end

    local targetPart = (owner:IsA("Model") and (owner.PrimaryPart or owner:FindFirstChildWhichIsA("BasePart", true)))
        or (owner:IsA("BasePart") and owner)
    if not targetPart then return end

    local baseText = "Gold"
    local goldVal = owner:GetAttribute("GoldValue") or (owner.Parent and owner.Parent:GetAttribute("GoldValue"))
    if goldVal and tonumber(goldVal) then
        baseText = string.format("Gold [%d]", tonumber(goldVal))
    end

    local color = Color3.fromRGB(255, 215, 0)
    registerEsp(owner, targetPart, baseText, color, "Gold", targetPart, Vector3.new(0, 0.8, 0))
end

-- 5. Precision Hiding Spot Scanner
local function processHidingSpot(hidingModel, roomNumber)
    if not hidingModel then return end
    if not State.HidingSpots_ESP or not State.Master_ESP then
        removeEspFor(hidingModel)
        return
    end

    local targetPart = (hidingModel:IsA("Model") and (hidingModel.PrimaryPart or hidingModel:FindFirstChildWhichIsA("BasePart", true)))
        or (hidingModel:IsA("BasePart") and hidingModel)
    if not targetPart then return end

    local nLower = hidingModel.Name:lower()
    local spotName = "Hiding Spot"
    if nLower:find("closet") or nLower:find("wardrobe") then
        spotName = "Wardrobe"
    elseif nLower:find("bed") then
        spotName = "Bed"
    elseif nLower:find("locker") then
        spotName = "Locker"
    end

    local color = Color3.fromRGB(60, 220, 90)
    registerEsp(hidingModel, targetPart, spotName, color, "HidingSpots", hidingModel, Vector3.new(0, 2.5, 0), roomNumber)
end

-- 6. Dedicated Rift ESP Scanner
local function processRift(model)
    if not model then return end
    if not State.Rift_ESP or not State.Master_ESP then
        removeEspFor(model)
        return
    end

    local mName = model.Name:lower()
    if (mName:find("rift") and not mName:find("fragment")) or model:GetAttribute("IsRift") then
        local targetPart = (model:IsA("Model") and (model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)))
            or (model:IsA("BasePart") and model)
        if targetPart then
            local color = Color3.fromRGB(0, 255, 255)
            registerEsp(model, targetPart, "The Rift", color, "Special", targetPart, Vector3.new(0, 1.5, 0))
        end
    end
end

-- 7. mspaint 2D Entity 3D Cham Engine (Function D / offset 1708680)
local function get2DEntityChamPart(entity, entityName, rootPart)
    local chamName = "__mspaint_2d_cham"
    local existing = entity:FindFirstChild(chamName)
    if existing and existing:IsA("BasePart") then return existing end

    local isEyes = entityName:lower():find("eyes") or entityName:lower():find("lookman")
    local shape = isEyes and Enum.PartType.Ball or Enum.PartType.Block
    local size = isEyes and Vector3.new(5, 4, 5) or Vector3.new(6, 6, 6)

    if entityName:lower():find("stampede") then
        size = Vector3.new(8, 8, 8)
    elseif entityName:lower():find("drone") and not entityName:lower():find("stampede") then
        size = Vector3.new(3.375, 6.75, 0.619)
    end

    local part = Instance.new("Part")
    part.Name = chamName
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.Massless = true
    part.CastShadow = false
    part.Transparency = 0.99
    part.Shape = shape
    part.Size = size
    part.CFrame = rootPart.CFrame
    part.Parent = entity

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = part
    weld.Part1 = rootPart
    weld.Parent = part
    part.Anchored = false
    return part
end

local function processEntity(entity)
    if not entity or not entity.Parent then return end
    if not State.Entities_ESP or not State.Master_ESP then
        removeEspFor(entity)
        return
    end

    local eLower = entity.Name:lower()

    -- Reject players, character, camera baserig, viewmodels, and shop NPCs
    if entity:IsA("Model") and Players:GetPlayerFromCharacter(entity) then return end
    local char = getChar()
    if char and (entity == char or entity:IsDescendantOf(char)) then return end
    if eLower == "baserig" or eLower:find("viewmodel") or eLower:find("bob") or eLower:find("elgoblino") or (eLower:find("jeff") and not eLower:find("killer")) then
        return
    end
    if eLower:find("dupe") or eLower:find("doorfake") then return end

    -- Real monster registry
    local cfg = nil
    local is2D = false

    if eLower:find("blitz") then
        cfg = { Name = "Blitz" }; is2D = true
    elseif eLower:find("rush") then
        cfg = { Name = "Rush" }; is2D = true
    elseif eLower:find("ambush") then
        cfg = { Name = "Ambush" }; is2D = true
    elseif eLower:find("lookman") then
        cfg = { Name = "Lookman" }; is2D = true
    elseif eLower:find("eyes") then
        cfg = { Name = "Eyes" }; is2D = true
    elseif eLower:find("screech") then
        cfg = { Name = "Screech" }; is2D = false
    elseif eLower:find("halt") or eLower == "shade" then
        cfg = { Name = "Halt" }; is2D = true
    elseif eLower:find("dread") then
        cfg = { Name = "Dread" }; is2D = true
    elseif eLower:find("figure") then
        cfg = { Name = "Figure" }; is2D = false
    elseif eLower:find("seek") then
        cfg = { Name = "Seek" }; is2D = false
    elseif eLower:find("giggle") then
        cfg = { Name = "Giggle" }; is2D = false
    elseif eLower:find("gloombat") then
        cfg = { Name = "Gloombats" }; is2D = false
    elseif eLower:find("grumble") then
        cfg = { Name = "Grumble" }; is2D = false
    elseif eLower:find("snare") then
        cfg = { Name = "Snare Trap" }; is2D = false
    elseif eLower:find("timothy") or eLower:find("spider") then
        cfg = { Name = "Timothy" }; is2D = false
    elseif eLower:find("a60") or eLower:find("a-60") then
        cfg = { Name = "A-60" }; is2D = true
    elseif eLower:find("a120") or eLower:find("a-120") then
        cfg = { Name = "A-120" }; is2D = true
    end

    if not cfg then return end

    local targetPart = (entity:IsA("Model") and (entity.PrimaryPart or entity:FindFirstChildWhichIsA("BasePart", true)))
        or (entity:IsA("BasePart") and entity)
    if not targetPart then return end

    local highlightTarget = entity
    local entityColor = Color3.fromRGB(255, 35, 35)

    if is2D then
        local chamPart = get2DEntityChamPart(entity, cfg.Name, targetPart)
        if chamPart then
            highlightTarget = chamPart
        end
    end

    registerEsp(entity, targetPart, cfg.Name, entityColor, "Entities", highlightTarget, Vector3.new(0, 3.0, 0))
end

-- 8. Universal Room Scanner
local function scanRoom(room)
    if not room or not room:IsA("Model") then return end

    -- Scan Doors
    local door = room:FindFirstChild("Door")
    if door then processDoor(room, door) end

    -- Scan All Children
    for _, child in ipairs(room:GetChildren()) do
        local cLower = child.Name:lower()

        -- Key Scanner
        if cLower == "keyobtain" then
            processKey(child)
        -- Lever Scanner
        elseif cLower:find("lever") or cLower:find("breaker") then
            processLever(child)
        -- Gold Scanner
        elseif cLower:find("gold") then
            processGold(child)
        -- Rift Scanner
        elseif cLower:find("rift") and not cLower:find("fragment") then
            if State.Rift_ESP then processRift(child) end
        -- Items Scanner
        elseif child:IsA("Model") and (child:FindFirstChild("Handle") or child:FindFirstChild("ModulePrompt") or child:GetAttribute("Pickup")) then
            processItem(child)
        -- Hiding Spot Scanner
        elseif child:IsA("Model") and (cLower:find("wardrobe") or cLower:find("closet") or cLower:find("bed") or cLower:find("locker")) then
            processHidingSpot(child, tonumber(room.Name))
        end
    end
end

local function scanAllRooms()
    local curRooms = Workspace:FindFirstChild("CurrentRooms")
    if curRooms then
        for _, room in ipairs(curRooms:GetChildren()) do
            scanRoom(room)
        end
    end
end

-- Connect Room Streaming & Entity Spawning
task.spawn(function()
    scanAllRooms()
    local curRooms = Workspace:WaitForChild("CurrentRooms", 10)
    if curRooms then
        curRooms.ChildAdded:Connect(function(room)
            task.wait(0.2)
            scanRoom(room)
        end)
    end
    Workspace.ChildAdded:Connect(function(child)
        task.wait(0.1)
        processEntity(child)
    end)
    for _, ch in ipairs(Workspace:GetChildren()) do
        processEntity(ch)
    end
end)

-- 9. Drawing API Snapline Tracers & 360 Offscreen Threat Radar
task.spawn(function()
    while isAlive() do
        if State.Master_ESP and (State.Tracers_ESP or State.Offscreen_Radar) then
            local cam = Workspace.CurrentCamera
            local root = getRoot()
            if cam and root then
                local screenCenter = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
                local screenBottom = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y)

                for owner, record in pairs(activeEspRecords) do
                    if record.Category == "Entities" and record.Adornee and record.Adornee.Parent then
                        local entPos = record.Adornee.Position
                        local scrPos, onScreen = cam:WorldToViewportPoint(entPos)

                        -- Snapline Tracer
                        if State.Tracers_ESP and Drawing then
                            if onScreen then
                                local line = activeTracers[owner]
                                if not line then
                                    line = Drawing.new("Line")
                                    line.Thickness = 1.5
                                    line.Transparency = 1
                                    line.Color = record.Color or Color3.fromRGB(255, 35, 35)
                                    activeTracers[owner] = line
                                end
                                line.From = screenBottom
                                line.To = Vector2.new(scrPos.X, scrPos.Y)
                                line.Visible = true
                            else
                                if activeTracers[owner] then activeTracers[owner].Visible = false end
                            end
                        else
                            if activeTracers[owner] then
                                activeTracers[owner]:Remove()
                                activeTracers[owner] = nil
                            end
                        end

                        -- 360 Offscreen Threat Radar Arrow
                        if State.Offscreen_Radar and Drawing then
                            if not onScreen then
                                local arrow = activeRadarArrows[owner]
                                if not arrow then
                                    arrow = Drawing.new("Triangle")
                                    arrow.Filled = true
                                    arrow.Color = record.Color or Color3.fromRGB(255, 35, 35)
                                    arrow.Transparency = 0.9
                                    activeRadarArrows[owner] = arrow
                                end

                                local relPos = cam.CFrame:PointToObjectSpace(entPos)
                                local angle = math.atan2(-relPos.X, relPos.Z)
                                local rad = State.Radar_Radius or 160

                                local p0 = screenCenter + Vector2.new(math.sin(angle) * rad, -math.cos(angle) * rad)
                                local p1 = screenCenter + Vector2.new(math.sin(angle + 0.18) * (rad - 16), -math.cos(angle + 0.18) * (rad - 16))
                                local p2 = screenCenter + Vector2.new(math.sin(angle - 0.18) * (rad - 16), -math.cos(angle - 0.18) * (rad - 16))

                                arrow.PointA = p0
                                arrow.PointB = p1
                                arrow.PointC = p2
                                arrow.Visible = true
                            else
                                if activeRadarArrows[owner] then activeRadarArrows[owner].Visible = false end
                            end
                        else
                            if activeRadarArrows[owner] then
                                activeRadarArrows[owner]:Remove()
                                activeRadarArrows[owner] = nil
                            end
                        end
                    end
                end
            end
        else
            for k, line in pairs(activeTracers) do line:Remove() end
            for k, arrow in pairs(activeRadarArrows) do arrow:Remove() end
            table.clear(activeTracers)
            table.clear(activeRadarArrows)
        end
        task.wait(0.03)
    end
end)

-- UI CONTROLS FOR TAB 4: ESP
UILib.CreateSection(espTab, "Master & Visual Filters")

UILib.CreateToggle(espTab, "Master ESP", State.Master_ESP, function(v)
    State.Master_ESP = v
    if not v then
        clearAllEsp()
    else
        scanAllRooms()
    end
end)

UILib.CreateToggle(espTab, "Show Distance", State.ESP_ShowDistance, function(v)
    State.ESP_ShowDistance = v
end)

UILib.CreateToggle(espTab, "Door ESP", State.Doors_ESP, function(v)
    State.Doors_ESP = v
    if not v then clearCategoryEsp("Doors") else scanAllRooms() end
end)

UILib.CreateToggle(espTab, "Key & Lever ESP", State.Keys_ESP, function(v)
    State.Keys_ESP = v
    if not v then clearCategoryEsp("Keys") else scanAllRooms() end
end)

UILib.CreateToggle(espTab, "Item ESP", State.Items_ESP, function(v)
    State.Items_ESP = v
    if not v then clearCategoryEsp("Items") else scanAllRooms() end
end)

UILib.CreateToggle(espTab, "Gold ESP", State.Gold_ESP, function(v)
    State.Gold_ESP = v
    if not v then clearCategoryEsp("Gold") else scanAllRooms() end
end)

UILib.CreateToggle(espTab, "Entity ESP (3D Chams)", State.Entities_ESP, function(v)
    State.Entities_ESP = v
    if not v then
        clearCategoryEsp("Entities")
    else
        for _, ch in ipairs(Workspace:GetChildren()) do processEntity(ch) end
    end
end)

UILib.CreateToggle(espTab, "The Rift ESP", State.Rift_ESP, function(v)
    State.Rift_ESP = v
    if not v then clearCategoryEsp("Special") else scanAllRooms() end
end)

UILib.CreateToggle(espTab, "Hiding Spot ESP", State.HidingSpots_ESP, function(v)
    State.HidingSpots_ESP = v
    if not v then clearCategoryEsp("HidingSpots") else scanAllRooms() end
end)

UILib.CreateToggle(espTab, "Snapline Tracers", State.Tracers_ESP, function(v)
    State.Tracers_ESP = v
end)

UILib.CreateToggle(espTab, "360 Threat Radar Arrows", State.Offscreen_Radar, function(v)
    State.Offscreen_Radar = v
end)

UILib.CreateSlider(espTab, "Text Size", 10, 22, State.ESP_TextSize, "px", function(v)
    State.ESP_TextSize = v
    for _, r in pairs(activeEspRecords) do
        if r.Label then r.Label.TextSize = v end
    end
end)

-- =========================================================================
-- SECTION 5: VISUALS & WORLD ENHANCEMENTS
-- =========================================================================
UILib.CreateSection(visualsTab, "Lighting & Camera")

local Lighting = game:GetService("Lighting")
local origAmbient = Lighting.Ambient
local origOutdoorAmbient = Lighting.OutdoorAmbient
local origBrightness = Lighting.Brightness
local origFogEnd = Lighting.FogEnd

-- Fullbright & No Fog Engine
task.spawn(function()
    while isAlive() do
        if State.Fullbright then
            Lighting.Ambient = Color3.fromRGB(255, 255, 255)
            Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
            Lighting.Brightness = 2
        end
        if State.NoFog then
            Lighting.FogEnd = 9e9
            local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
            if atmosphere then atmosphere.Density = 0 end
        end
        task.wait(0.5)
    end
end)

UILib.CreateToggle(visualsTab, "Fullbright", State.Fullbright, function(v)
    State.Fullbright = v
    if not v then
        Lighting.Ambient = origAmbient
        Lighting.OutdoorAmbient = origOutdoorAmbient
        Lighting.Brightness = origBrightness
    end
end)

UILib.CreateToggle(visualsTab, "No Fog", State.NoFog, function(v)
    State.NoFog = v
    if not v then
        Lighting.FogEnd = origFogEnd
        local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
        if atmosphere then atmosphere.Density = 0.3 end
    end
end)

UILib.CreateToggle(visualsTab, "No Camera Shake", State.NoCamShake, function(v)
    State.NoCamShake = v
end)

-- Hook Camera Shake
local function hookCamShaker()
    local mg = getMainGameTable()
    if mg and mg.camShaker and not _G.DOORS_V2_CAMSHAKE_HOOKED then
        _G.DOORS_V2_CAMSHAKE_HOOKED = true
        local origShakeOnce = mg.camShaker.ShakeOnce
        mg.camShaker.ShakeOnce = function(self, ...)
            if State.NoCamShake then return end
            return origShakeOnce(self, ...)
        end
    end
end
task.spawn(function()
    while isAlive() do
        pcall(hookCamShaker)
        task.wait(0.8)
    end
end)

print("[U⚡] UNKNOWN HUB — DOORS V2 (PARTS 1 & 2) LOADED SUCCESSFULLY!")
