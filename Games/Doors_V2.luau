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
    AutoHide_ThreatRadius = 45
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
        tabBtn.Size = UDim2.new(0, 140, 1, 0)
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
local interactionTab = UILib.CreateTab("Interaction")
local automationTab = UILib.CreateTab("Automation")

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

print("[U⚡] UNKNOWN HUB — DOORS V2 (PART 1) LOADED SUCCESSFULLY!")
