--[[
    ========================================================================
    UNKNOWN HUB - DOORS (Hotel & The Mines)
    Pure Rebuild Architecture (V2.0 Live mspaint Bridge Edition)
    Direct In-Memory Bridge & 1:1 Parity with mspaint v4
    Engineered by Eve for daddy.
    ========================================================================
]]

-- Session Isolation
local currentSession = tick()
_G.DOORS_SESSION = currentSession

-- Core Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
assert(LocalPlayer, "LocalPlayer is not available")

-- =========================================================================
-- Live mspaint Bridge (Zero-Guesswork Direct Runtime Binding)
-- =========================================================================
local function getMspaint()
    local ok, tbl = pcall(function()
        if type(filtergc) == "function" then
            return filtergc("table", {Keys = {"Toggles", "Options"}}, true)
        end
        return nil
    end)
    return (ok and tbl) or nil
end

local Mspaint = getMspaint()

-- Live Mspaint TextLabel Finder (for Speed Bypass Status)
local function getMspaintSpeedBypassLabel()
    local parent = (type(gethui) == "function" and gethui()) or game:GetService("CoreGui")
    local obsidian = parent:FindFirstChild("Obsidian") or game:GetService("CoreGui"):FindFirstChild("Obsidian", true)
    if obsidian then
        for _, desc in ipairs(obsidian:GetDescendants()) do
            if desc:IsA("TextLabel") and desc.Text:find("Speed Bypass") then
                return desc
            end
        end
    end
    return nil
end

-- =========================================================================
-- State Configuration
-- =========================================================================
local State = {
    Speed_Bypass_Text = 'Speed Bypass: <font color="rgb(128, 128, 128)">Idle</font>',
    WalkSpeed_Value = (Mspaint and Mspaint.Options and Mspaint.Options.WalkSpeed and Mspaint.Options.WalkSpeed.Value) or 15,
    Speed_Boost = (Mspaint and Mspaint.Toggles and Mspaint.Toggles.EnableSpeedHack and Mspaint.Toggles.EnableSpeedHack.Value) or false,
    Jumping = (Mspaint and Mspaint.Toggles and Mspaint.Toggles.EnableJump and Mspaint.Toggles.EnableJump.Value) or false,
    Sliding = (Mspaint and Mspaint.Toggles and Mspaint.Toggles.EnableSliding and Mspaint.Toggles.EnableSliding.Value) or false,
    No_Acceleration = (Mspaint and Mspaint.Toggles and Mspaint.Toggles.NoAcceleration and Mspaint.Toggles.NoAcceleration.Value) or false,
    Fly = (Mspaint and Mspaint.Toggles and Mspaint.Toggles.Fly and Mspaint.Toggles.Fly.Value) or false,
    Noclip = (Mspaint and Mspaint.Toggles and Mspaint.Toggles.Noclip and Mspaint.Toggles.Noclip.Value) or false,
    Fly_Key = Enum.KeyCode.F,
    Noclip_Key = Enum.KeyCode.N,
}

-- Forward UI handles
local flyToggleObj, noclipToggleObj, speedBoostToggleObj, jumpToggleObj, slideToggleObj, noAccToggleObj, speedBypassLabel

-- =========================================================================
-- Native Action Dispatchers (Directly invokes mspaint if present, else fallback)
-- =========================================================================
local function setMspaintToggle(toggleName, val)
    Mspaint = Mspaint or getMspaint()
    if Mspaint and Mspaint.Toggles and Mspaint.Toggles[toggleName] then
        pcall(function()
            if Mspaint.Toggles[toggleName].Value ~= val then
                Mspaint.Toggles[toggleName]:SetValue(val)
            end
        end)
    end
end

local function setMspaintOption(optionName, val)
    Mspaint = Mspaint or getMspaint()
    if Mspaint and Mspaint.Options and Mspaint.Options[optionName] then
        pcall(function()
            if Mspaint.Options[optionName].Value ~= val then
                Mspaint.Options[optionName]:SetValue(val)
            end
        end)
    end
end

-- =========================================================================
-- Fallback Controllers (if mspaint ever unloads)
-- =========================================================================
local function getChar()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

local function getHumanoid(char)
    char = char or getChar()
    return char and char:FindFirstChildWhichIsA("Humanoid")
end

local function getRoot(char)
    char = char or getChar()
    return char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart or char:FindFirstChild("Collision"))
end

local function applyFallbackJumping(enabled)
    local char = getChar()
    local hum = getHumanoid(char)
    if hum then
        hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, enabled)
        hum.JumpHeight = enabled and 5 or 0
    end
    if char then
        pcall(function() char:SetAttribute("CanJump", enabled) end)
    end
end

local function applyFallbackSliding(enabled)
    local char = getChar()
    if char then
        pcall(function() char:SetAttribute("CanSlide", enabled) end)
    end
    pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("RemotesFolder")
        local crouch = remotes and remotes:FindFirstChild("Crouch")
        if crouch and crouch:IsA("RemoteEvent") then
            crouch:FireServer(enabled == true, enabled == true)
        end
    end)
end

-- Fallback Noclip Stepped Loop
RunService.Stepped:Connect(function()
    if _G.DOORS_SESSION ~= currentSession then return end
    if State.Noclip and not (Mspaint and Mspaint.Toggles and Mspaint.Toggles.Noclip and Mspaint.Toggles.Noclip.Value) then
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end
end)

-- =========================================================================
-- UI Library Initialization
-- =========================================================================
local function loadLibrary()
    local source
    if readfile then
        pcall(function() source = readfile("UnknownLibrary.luau") end)
        if not source or #source < 100 then
            pcall(function() source = readfile("UnknownLibrary") end)
        end
    end
    if not source or #source < 100 then
        local cacheBuster = "?t=" .. tostring(os.time() or tick()) .. "_" .. tostring(math.random(1000, 9999))
        local ok, fetched = pcall(function()
            return game:HttpGet("https://raw.githubusercontent.com/UnknownHQ/UnknownHub/main/UnknownLibrary" .. cacheBuster)
        end)
        if ok and fetched and #fetched > 100 then
            source = fetched
        end
    end
    assert(source and #source > 100, "Could not load UnknownLibrary")
    local chunk = loadstring(source)
    assert(chunk, "UnknownLibrary compile failed")
    return chunk()
end

local libraryFactory = loadLibrary()

if _G.UNKNOWN_ACTIVE_HUB and _G.UNKNOWN_ACTIVE_HUB.destroy then
    pcall(function() _G.UNKNOWN_ACTIVE_HUB.destroy() end)
end

local Hub = libraryFactory({
    name = "Unknown_TabbedHub_UI",
    title = "UNKNOWN HUB",
    subTitle = "DOORS (Hotel & Mines)",
    primaryColor = Color3.fromRGB(245, 142, 32),
    secondaryColor = Color3.fromRGB(0, 195, 245)
})
_G.UNKNOWN_ACTIVE_HUB = Hub

local function addKeybindBadge(toggleCard, keyText)
    if not toggleCard then return end
    local badge = Instance.new("TextLabel")
    badge.Name = "KeyBadge"
    badge.Size = UDim2.new(0, 24, 0, 20)
    badge.Position = UDim2.new(1, -82, 0.5, -10)
    badge.BackgroundColor3 = Color3.fromRGB(24, 25, 29)
    badge.BorderSizePixel = 0
    badge.Font = Enum.Font.RobotoMono
    badge.Text = keyText
    badge.TextColor3 = Color3.fromRGB(180, 180, 185)
    badge.TextSize = 12
    badge.Parent = toggleCard

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = badge

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(48, 50, 58)
    stroke.Thickness = 1
    stroke.Parent = badge
    return badge
end

-- =========================================================================
-- Main Tab: Segmented Movement & Character Selector
-- =========================================================================
local mainTab = Hub.CreateTab("Main", {
    Icon = "🏠",
    Size = 18,
    Color = Color3.fromRGB(245, 142, 32),
    ActiveColor = Color3.fromRGB(255, 185, 30)
})

local page = (typeof(mainTab) == "table" and mainTab.Page) or mainTab

local segmentedRow = Instance.new("Frame")
segmentedRow.Name = "SegmentedRow_Main"
segmentedRow.Size = UDim2.new(1, 0, 0, 36)
segmentedRow.BackgroundColor3 = Color3.fromRGB(17, 20, 27)
segmentedRow.BorderSizePixel = 0
segmentedRow.Parent = page

local segCorner = Instance.new("UICorner")
segCorner.CornerRadius = UDim.new(0, 8)
segCorner.Parent = segmentedRow

local segStroke = Instance.new("UIStroke")
segStroke.Color = Color3.fromRGB(34, 40, 53)
segStroke.Thickness = 1
segStroke.Parent = segmentedRow

local segLayout = Instance.new("UIListLayout")
segLayout.FillDirection = Enum.FillDirection.Horizontal
segLayout.SortOrder = Enum.SortOrder.LayoutOrder
segLayout.Padding = UDim.new(0, 4)
segLayout.Parent = segmentedRow

local segPadding = Instance.new("UIPadding")
segPadding.PaddingLeft = UDim.new(0, 4)
segPadding.PaddingRight = UDim.new(0, 4)
segPadding.PaddingTop = UDim.new(0, 4)
segPadding.PaddingBottom = UDim.new(0, 4)
segPadding.Parent = segmentedRow

local movementContainer = Instance.new("Frame")
movementContainer.Name = "MovementContainer"
movementContainer.Size = UDim2.new(1, 0, 0, 0)
movementContainer.AutomaticSize = Enum.AutomaticSize.Y
movementContainer.BackgroundTransparency = 1
movementContainer.Parent = page

local moveLayout = Instance.new("UIListLayout")
moveLayout.SortOrder = Enum.SortOrder.LayoutOrder
moveLayout.Padding = UDim.new(0, 8)
moveLayout.Parent = movementContainer

local characterContainer = Instance.new("Frame")
characterContainer.Name = "CharacterContainer"
characterContainer.Size = UDim2.new(1, 0, 0, 0)
characterContainer.AutomaticSize = Enum.AutomaticSize.Y
characterContainer.BackgroundTransparency = 1
characterContainer.Visible = false
characterContainer.Parent = page

local charLayout = Instance.new("UIListLayout")
charLayout.SortOrder = Enum.SortOrder.LayoutOrder
charLayout.Padding = UDim.new(0, 8)
charLayout.Parent = characterContainer

local movementBtn = Instance.new("TextButton")
movementBtn.Name = "MovementTabBtn"
movementBtn.Size = UDim2.new(0.5, -2, 1, 0)
movementBtn.BackgroundColor3 = Color3.fromRGB(28, 33, 44)
movementBtn.BorderSizePixel = 0
movementBtn.Font = Enum.Font.RobotoMono
movementBtn.Text = "Movement"
movementBtn.TextColor3 = Color3.fromRGB(245, 142, 32)
movementBtn.TextSize = 13
movementBtn.LayoutOrder = 1
movementBtn.Parent = segmentedRow

local movBtnCorner = Instance.new("UICorner")
movBtnCorner.CornerRadius = UDim.new(0, 6)
movBtnCorner.Parent = movementBtn

local characterBtn = Instance.new("TextButton")
characterBtn.Name = "CharacterTabBtn"
characterBtn.Size = UDim2.new(0.5, -2, 1, 0)
characterBtn.BackgroundColor3 = Color3.fromRGB(17, 20, 27)
characterBtn.BorderSizePixel = 0
characterBtn.Font = Enum.Font.RobotoMono
characterBtn.Text = "Character"
characterBtn.TextColor3 = Color3.fromRGB(140, 152, 172)
characterBtn.TextSize = 13
characterBtn.LayoutOrder = 2
characterBtn.Parent = segmentedRow

local charBtnCorner = Instance.new("UICorner")
charBtnCorner.CornerRadius = UDim.new(0, 6)
charBtnCorner.Parent = characterBtn

movementBtn.MouseButton1Click:Connect(function()
    movementBtn.BackgroundColor3 = Color3.fromRGB(28, 33, 44)
    movementBtn.TextColor3 = Color3.fromRGB(245, 142, 32)
    characterBtn.BackgroundColor3 = Color3.fromRGB(17, 20, 27)
    characterBtn.TextColor3 = Color3.fromRGB(140, 152, 172)
    movementContainer.Visible = true
    characterContainer.Visible = false
end)

characterBtn.MouseButton1Click:Connect(function()
    characterBtn.BackgroundColor3 = Color3.fromRGB(28, 33, 44)
    characterBtn.TextColor3 = Color3.fromRGB(245, 142, 32)
    movementBtn.BackgroundColor3 = Color3.fromRGB(17, 20, 27)
    movementBtn.TextColor3 = Color3.fromRGB(140, 152, 172)
    movementContainer.Visible = false
    characterContainer.Visible = true
end)

-- =========================================================================
-- Subsection: Movement (Screenshot 2)
-- =========================================================================

-- 1. Status Display: Speed Bypass: Idle
local speedBypassCard = Instance.new("Frame")
speedBypassCard.Name = "StatusCard_SpeedBypass"
speedBypassCard.Size = UDim2.new(1, 0, 0, 36)
speedBypassCard.BackgroundColor3 = Color3.fromRGB(22, 26, 35)
speedBypassCard.BorderSizePixel = 0
speedBypassCard.LayoutOrder = 1
speedBypassCard.Parent = movementContainer

local cardCorner = Instance.new("UICorner")
cardCorner.CornerRadius = UDim.new(0, 6)
cardCorner.Parent = speedBypassCard

local cardStroke = Instance.new("UIStroke")
cardStroke.Color = Color3.fromRGB(34, 40, 53)
cardStroke.Thickness = 1
cardStroke.Parent = speedBypassCard

speedBypassLabel = Instance.new("TextLabel")
speedBypassLabel.Name = "StatusLabel"
speedBypassLabel.Size = UDim2.new(1, -20, 1, 0)
speedBypassLabel.Position = UDim2.new(0, 10, 0, 0)
speedBypassLabel.BackgroundTransparency = 1
speedBypassLabel.Font = Enum.Font.RobotoMono
speedBypassLabel.RichText = true
speedBypassLabel.Text = State.Speed_Bypass_Text
speedBypassLabel.TextColor3 = Color3.fromRGB(240, 244, 252)
speedBypassLabel.TextSize = 13
speedBypassLabel.TextXAlignment = Enum.TextXAlignment.Left
speedBypassLabel.Parent = speedBypassCard

-- 2. Walk Speed Slider
Hub.CreateSlider(movementContainer, "Walk Speed", 10, 100, State.WalkSpeed_Value, " studs/s", function(v)
    State.WalkSpeed_Value = v
    setMspaintOption("WalkSpeed", v)
    if State.Speed_Boost and not (Mspaint and Mspaint.Options and Mspaint.Options.WalkSpeed) then
        local hum = getHumanoid()
        if hum then hum.WalkSpeed = v end
    end
end)

-- 3. Speed Boost Toggle
speedBoostToggleObj = Hub.CreateToggle(movementContainer, "Speed Boost", State.Speed_Boost, function(v)
    State.Speed_Boost = v
    setMspaintToggle("EnableSpeedHack", v)
    if not (Mspaint and Mspaint.Toggles and Mspaint.Toggles.EnableSpeedHack) then
        local hum = getHumanoid()
        if hum then hum.WalkSpeed = v and State.WalkSpeed_Value or 15 end
    end
    Hub.Notify("Movement", v and string.format("Speed Boost: %d studs/s", State.WalkSpeed_Value) or "Speed Boost: Restored (15 studs/s)", 2)
end)

-- 4. Jumping Toggle
jumpToggleObj = Hub.CreateToggle(movementContainer, "Jumping", State.Jumping, function(v)
    State.Jumping = v
    setMspaintToggle("EnableJump", v)
    if not (Mspaint and Mspaint.Toggles and Mspaint.Toggles.EnableJump) then
        applyFallbackJumping(v)
    end
    Hub.Notify("Movement", v and "Jumping: Enabled" or "Jumping: Disabled", 2)
end)

-- 5. Sliding Toggle
slideToggleObj = Hub.CreateToggle(movementContainer, "Sliding", State.Sliding, function(v)
    State.Sliding = v
    setMspaintToggle("EnableSliding", v)
    if not (Mspaint and Mspaint.Toggles and Mspaint.Toggles.EnableSliding) then
        applyFallbackSliding(v)
    end
    Hub.Notify("Movement", v and "Sliding: Enabled" or "Sliding: Disabled", 2)
end)

-- 6. No Acceleration Toggle
noAccToggleObj = Hub.CreateToggle(movementContainer, "No Acceleration", State.No_Acceleration, function(v)
    State.No_Acceleration = v
    setMspaintToggle("NoAcceleration", v)
    Hub.Notify("Movement", v and "No Acceleration: Enabled" or "No Acceleration: Disabled", 2)
end)

-- =========================================================================
-- Subsection: Character (Screenshot 1)
-- =========================================================================

-- 1. Fly Toggle [F]
flyToggleObj = Hub.CreateToggle(characterContainer, "Fly", State.Fly, function(v)
    State.Fly = v
    setMspaintToggle("Fly", v)
    Hub.Notify("Character", v and "Fly: Enabled [F]" or "Fly: Disabled [F]", 2)
end)
if flyToggleObj and flyToggleObj.Instance then
    addKeybindBadge(flyToggleObj.Instance, "F")
end

-- 2. Noclip Toggle [N]
noclipToggleObj = Hub.CreateToggle(characterContainer, "Noclip", State.Noclip, function(v)
    State.Noclip = v
    setMspaintToggle("Noclip", v)
    Hub.Notify("Character", v and "Noclip: Enabled [N]" or "Noclip: Disabled [N]", 2)
end)
if noclipToggleObj and noclipToggleObj.Instance then
    addKeybindBadge(noclipToggleObj.Instance, "N")
end

-- =========================================================================
-- Keybind Triggers ([F] = Fly, [N] = Noclip)
-- =========================================================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if _G.DOORS_SESSION ~= currentSession then return end
    if gameProcessed then return end

    if input.KeyCode == State.Fly_Key then
        State.Fly = not State.Fly
        if flyToggleObj and flyToggleObj.Set then
            flyToggleObj:Set(State.Fly)
        else
            setMspaintToggle("Fly", State.Fly)
        end
    elseif input.KeyCode == State.Noclip_Key then
        State.Noclip = not State.Noclip
        if noclipToggleObj and noclipToggleObj.Set then
            noclipToggleObj:Set(State.Noclip)
        else
            setMspaintToggle("Noclip", State.Noclip)
        end
    end
end)

-- =========================================================================
-- Continuous Live Synchronization Daemon with mspaint
-- =========================================================================
task.spawn(function()
    while true do
        if _G.DOORS_SESSION ~= currentSession then break end

        -- 1. Synchronize Speed Bypass Status Text from mspaint
        local mspLabel = getMspaintSpeedBypassLabel()
        if mspLabel and speedBypassLabel then
            if speedBypassLabel.Text ~= mspLabel.Text then
                speedBypassLabel.Text = mspLabel.Text
            end
        end

        -- 2. Synchronize Toggles from mspaint if toggled in mspaint GUI
        Mspaint = Mspaint or getMspaint()
        if Mspaint and Mspaint.Toggles then
            local t = Mspaint.Toggles
            if t.Fly and flyToggleObj and State.Fly ~= t.Fly.Value then
                State.Fly = t.Fly.Value
                if flyToggleObj.Set then flyToggleObj:Set(State.Fly) end
            end
            if t.Noclip and noclipToggleObj and State.Noclip ~= t.Noclip.Value then
                State.Noclip = t.Noclip.Value
                if noclipToggleObj.Set then noclipToggleObj:Set(State.Noclip) end
            end
            if t.EnableSpeedHack and speedBoostToggleObj and State.Speed_Boost ~= t.EnableSpeedHack.Value then
                State.Speed_Boost = t.EnableSpeedHack.Value
                if speedBoostToggleObj.Set then speedBoostToggleObj:Set(State.Speed_Boost) end
            end
            if t.EnableJump and jumpToggleObj and State.Jumping ~= t.EnableJump.Value then
                State.Jumping = t.EnableJump.Value
                if jumpToggleObj.Set then jumpToggleObj:Set(State.Jumping) end
            end
            if t.EnableSliding and slideToggleObj and State.Sliding ~= t.EnableSliding.Value then
                State.Sliding = t.EnableSliding.Value
                if slideToggleObj.Set then slideToggleObj:Set(State.Sliding) end
            end
            if t.NoAcceleration and noAccToggleObj and State.No_Acceleration ~= t.NoAcceleration.Value then
                State.No_Acceleration = t.NoAcceleration.Value
                if noAccToggleObj.Set then noAccToggleObj:Set(State.No_Acceleration) end
            end
        end

        task.wait(0.1)
    end
end)

-- Safe Unload Hook
Hub.OnUnload(function()
    _G.DOORS_SESSION = nil
    setMspaintToggle("Fly", false)
    setMspaintToggle("Noclip", false)
    setMspaintToggle("EnableSpeedHack", false)
    setMspaintToggle("EnableJump", false)
    setMspaintToggle("EnableSliding", false)
    setMspaintToggle("NoAcceleration", false)
end)

Hub.finishLoading("Live mspaint Bridge Active!")
print("[UnknownHub] Connected directly to mspaint v4 runtime engine!")
