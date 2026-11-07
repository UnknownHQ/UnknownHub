--[[
    ========================================================================
    UNKNOWN HUB - DOORS (Hotel & The Mines)
    Pure Rebuild Architecture (V1.0 Clean Slate Edition)
    Direct 1:1 Parity with mspaint v4 Movement & Character Suite
    Engineered by Eve for daddy with surgical precision.
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
-- State Configuration (mspaint v4 Movement & Character 1:1 Alignment)
-- =========================================================================
local State = {
    -- Movement Suite
    Speed_Bypass = true,
    Speed_Bypass_Status = "Idle",
    WalkSpeed_Value = 15,
    WalkSpeed_Enabled = false,
    Enable_Jumping = false,
    Enable_Sliding = false,
    No_Acceleration = false,

    -- Character Suite (Flight & Noclip)
    Fly_Enabled = false,
    Fly_Speed = 22,
    Noclip_Enabled = false,
    Fly_Key = Enum.KeyCode.F,
    Noclip_Key = Enum.KeyCode.N,
}

-- Forward Declarations
local flyToggleObj, noclipToggleObj, speedBypassLabel

-- =========================================================================
-- Character & Engine Helpers
-- =========================================================================
local function getChar()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

local function getRoot(char)
    char = char or getChar()
    return char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart or char:FindFirstChild("Collision"))
end

local function getHumanoid(char)
    char = char or getChar()
    return char and char:FindFirstChildWhichIsA("Humanoid")
end

local function getMainGameTable()
    local mainUI = LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("MainUI")
    local initiator = mainUI and mainUI:FindFirstChild("Initiator")
    local mgScript = initiator and initiator:FindFirstChild("Main_Game")
    if mgScript and mgScript:IsA("ModuleScript") then
        local ok, res = pcall(require, mgScript)
        if ok and type(res) == "table" then
            return res
        end
    end
    return nil
end

local function syncServerSlide(canSlide, crouching)
    pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("RemotesFolder")
        local crouchRemote = remotes and remotes:FindFirstChild("Crouch")
        if crouchRemote and crouchRemote:IsA("RemoteEvent") then
            crouchRemote:FireServer(canSlide == true, crouching == true)
        end
    end)
end

-- =========================================================================
-- Permanent Invariant: Locked Flight & Noclip Engine (DOORS Native Method)
-- =========================================================================
local function syncNativeFlightSpeed(speed)
    local mg = getMainGameTable()
    if mg and mg.flightSpeed ~= nil then
        mg.flightSpeed = speed
    end
end

local function toggleFlight(enabled)
    State.Fly_Enabled = enabled
    local char = getChar()
    local hum = getHumanoid(char)
    local mg = getMainGameTable()

    if enabled then
        if hum then
            hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
        end
        if mg then
            mg.noclip = true
            syncNativeFlightSpeed(State.Fly_Speed)
        end
    else
        if mg then
            if not State.Noclip_Enabled then
                mg.noclip = false
            end
        end
    end
end

local function toggleNoclip(enabled)
    State.Noclip_Enabled = enabled
    local mg = getMainGameTable()
    if mg then
        if enabled or State.Fly_Enabled then
            mg.noclip = true
        else
            mg.noclip = false
        end
    end
end

-- =========================================================================
-- Speed Bypass Controller (mspaint v4 Massless Desync Engine)
-- =========================================================================
local speedBypassCollisionClone = nil
local lastMasslessToggle = 0

local function setupSpeedBypassCollisionClone()
    local char = getChar()
    if not char then return end
    local collision = char:FindFirstChild("Collision") or char:FindFirstChild("CollisionCrouch", true)
    if not collision or not collision:IsA("BasePart") then return end

    if speedBypassCollisionClone and speedBypassCollisionClone.Parent == char then
        return
    end

    pcall(function()
        if speedBypassCollisionClone then speedBypassCollisionClone:Destroy() end
        local clone = collision:Clone()
        clone.Name = "CollisionSpeedBypassClone"
        clone.CanCollide = false
        clone.Massless = true
        clone.Transparency = 1
        clone.Parent = char

        local weld = Instance.new("WeldConstraint")
        weld.Part0 = clone
        weld.Part1 = collision
        weld.Parent = clone
        speedBypassCollisionClone = clone
    end)
end

local function updateSpeedBypass(now)
    local char = getChar()
    local hum = getHumanoid(char)
    local root = getRoot(char)
    if not char or not hum or not root or hum.Health <= 0 then
        if speedBypassLabel then
            speedBypassLabel.Text = 'Speed Bypass: <font color="rgb(140, 152, 172)">Idle</font>'
        end
        return
    end

    local isMoving = hum.MoveDirection.Magnitude > 0.05
    local currentSpeed = State.WalkSpeed_Enabled and (State.WalkSpeed_Value or 15) or hum.WalkSpeed
    local isHighSpeed = currentSpeed >= 18

    if State.WalkSpeed_Enabled and isMoving and isHighSpeed then
        State.Speed_Bypass_Status = "Bypassing"
        if speedBypassLabel then
            speedBypassLabel.Text = 'Speed Bypass: <font color="rgb(45, 205, 115)">Bypassing</font>'
        end

        if not speedBypassCollisionClone or speedBypassCollisionClone.Parent ~= char then
            setupSpeedBypassCollisionClone()
        end

        -- Exact mspaint v4 timing (0.23s massless desync cycle)
        if speedBypassCollisionClone and (now - lastMasslessToggle >= 0.23) then
            lastMasslessToggle = now
            speedBypassCollisionClone.Massless = not speedBypassCollisionClone.Massless
        end
    else
        State.Speed_Bypass_Status = "Idle"
        if speedBypassLabel then
            speedBypassLabel.Text = 'Speed Bypass: <font color="rgb(140, 152, 172)">Idle</font>'
        end
        if speedBypassCollisionClone and speedBypassCollisionClone.Parent then
            speedBypassCollisionClone.Massless = true
        end
    end
end

-- =========================================================================
-- Jumping & Sliding State Enforcers (mspaint v4 Attribute Observers)
-- =========================================================================
local function applyJumping(enabled)
    State.Enable_Jumping = enabled
    local char = getChar()
    local hum = getHumanoid(char)
    if hum then
        hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, enabled)
        hum.UseJumpPower = enabled
        hum.JumpPower = enabled and 50 or 0
    end
    if char then
        pcall(function() char:SetAttribute("CanJump", enabled) end)
    end
end

local function applySliding(enabled)
    State.Enable_Sliding = enabled
    local char = getChar()
    if char then
        pcall(function() char:SetAttribute("CanSlide", enabled) end)
    end
    if enabled then
        syncServerSlide(true, true)
    else
        if not State.WalkSpeed_Enabled then
            syncServerSlide(false, false)
        end
    end
end

-- Auto-reassert attributes if DOORS resets them on room transitions
local function setupCharacterWatchers(char)
    if not char then return end
    char:GetAttributeChangedSignal("CanJump"):Connect(function()
        if _G.DOORS_SESSION ~= currentSession then return end
        if State.Enable_Jumping and char:GetAttribute("CanJump") ~= true then
            char:SetAttribute("CanJump", true)
        end
    end)
    char:GetAttributeChangedSignal("CanSlide"):Connect(function()
        if _G.DOORS_SESSION ~= currentSession then return end
        if State.Enable_Sliding and char:GetAttribute("CanSlide") ~= true then
            char:SetAttribute("CanSlide", true)
        end
    end)
end

if LocalPlayer.Character then
    setupCharacterWatchers(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(function(newChar)
    if _G.DOORS_SESSION ~= currentSession then return end
    task.wait(0.2)
    setupCharacterWatchers(newChar)
    if State.Enable_Jumping then applyJumping(true) end
    if State.Enable_Sliding then applySliding(true) end
    if State.WalkSpeed_Enabled then
        local hum = getHumanoid(newChar)
        if hum then hum.WalkSpeed = State.WalkSpeed_Value or 15 end
        syncServerSlide(true, true)
    end
end)

-- =========================================================================
-- Continuous Movement & Physics Heartbeat Daemon
-- =========================================================================
RunService.Heartbeat:Connect(function(dt)
    if _G.DOORS_SESSION ~= currentSession then return end
    local nowTime = tick()

    -- 1. Telemetry & Speed Bypass Desync
    updateSpeedBypass(nowTime)

    local char = getChar()
    local hum = getHumanoid(char)
    local root = getRoot(char)

    if char and hum and root and hum.Health > 0 then
        -- 2. No Acceleration (Zero-Inertia Instant Full-Speed Response)
        if State.No_Acceleration and hum.MoveDirection.Magnitude > 0.05 then
            local targetSpeed = State.WalkSpeed_Enabled and (State.WalkSpeed_Value or 15) or hum.WalkSpeed
            local moveDir = hum.MoveDirection
            local curY = root.AssemblyLinearVelocity.Y
            root.AssemblyLinearVelocity = Vector3.new(moveDir.X * targetSpeed, curY, moveDir.Z * targetSpeed)
        end

        -- 3. Universal Entity Immunity & Noclip Parts Management
        if State.Noclip_Enabled or State.Fly_Enabled then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                    part.CollisionGroup = "NoPlayer"
                    part.CanTouch = true
                    part.CanQuery = true
                end
            end
        end
    end
end)

-- =========================================================================
-- Keybind Trigger Listener ([F] = Fly, [N] = Noclip)
-- =========================================================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if _G.DOORS_SESSION ~= currentSession then return end
    if gameProcessed then return end

    if input.KeyCode == State.Fly_Key then
        State.Fly_Enabled = not State.Fly_Enabled
        toggleFlight(State.Fly_Enabled)
        if flyToggleObj and flyToggleObj.Set then
            flyToggleObj:Set(State.Fly_Enabled)
        end
        if Hub and Hub.Notify then
            Hub.Notify("Character", State.Fly_Enabled and "Fly: Enabled [F]" or "Fly: Disabled [F]", 2)
        end
    elseif input.KeyCode == State.Noclip_Key then
        State.Noclip_Enabled = not State.Noclip_Enabled
        toggleNoclip(State.Noclip_Enabled)
        if noclipToggleObj and noclipToggleObj.Set then
            noclipToggleObj:Set(State.Noclip_Enabled)
        end
        if Hub and Hub.Notify then
            Hub.Notify("Character", State.Noclip_Enabled and "Noclip: Enabled [N]" or "Noclip: Disabled [N]", 2)
        end
    end
end)

-- =========================================================================
-- UI Construction via UnknownLibrary (Segmented Movement & Character Suite)
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

-- Clean up any existing UI instance
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

-- Helper: Add Keybind Badge to Toggle Card
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

-- Create Main Tab
local mainTab = Hub.CreateTab("Main", {
    Icon = "🏠",
    Size = 18,
    Color = Color3.fromRGB(245, 142, 32),
    ActiveColor = Color3.fromRGB(255, 185, 30)
})

local page = (typeof(mainTab) == "table" and mainTab.Page) or mainTab

-- =========================================================================
-- Segmented Header Selector: [ Movement ]  [ Character ] (1:1 mspaint Look)
-- =========================================================================
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

-- Container Frames for Subsections
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

-- Segmented Buttons
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
-- Subsection 1: Movement Controls (Screenshot 2)
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
speedBypassLabel.Text = 'Speed Bypass: <font color="rgb(140, 152, 172)">Idle</font>'
speedBypassLabel.TextColor3 = Color3.fromRGB(240, 244, 252)
speedBypassLabel.TextSize = 13
speedBypassLabel.TextXAlignment = Enum.TextXAlignment.Left
speedBypassLabel.Parent = speedBypassCard

-- 2. Walk Speed Slider
Hub.CreateSlider(movementContainer, "Walk Speed", 10, 100, State.WalkSpeed_Value or 15, " studs/s", function(v)
    State.WalkSpeed_Value = v
    if State.WalkSpeed_Enabled then
        local hum = getHumanoid()
        if hum then hum.WalkSpeed = v end
    end
end)

-- 3. Speed Boost Toggle
Hub.CreateToggle(movementContainer, "Speed Boost", State.WalkSpeed_Enabled, function(v)
    State.WalkSpeed_Enabled = v
    local hum = getHumanoid()
    if hum then
        if v then
            syncServerSlide(true, true)
            hum.WalkSpeed = State.WalkSpeed_Value or 15
        else
            if not State.Enable_Sliding then
                syncServerSlide(false, false)
            end
            hum.WalkSpeed = 15
        end
    end
    Hub.Notify("Movement", v and string.format("Speed Boost: %d studs/s", State.WalkSpeed_Value) or "Speed Boost: Restored (15 studs/s)", 2)
end)

-- 4. Jumping Toggle
Hub.CreateToggle(movementContainer, "Jumping", State.Enable_Jumping, function(v)
    applyJumping(v)
    Hub.Notify("Movement", v and "Jumping: Enabled" or "Jumping: Disabled", 2)
end)

-- 5. Sliding Toggle
Hub.CreateToggle(movementContainer, "Sliding", State.Enable_Sliding, function(v)
    applySliding(v)
    Hub.Notify("Movement", v and "Sliding: Enabled" or "Sliding: Disabled", 2)
end)

-- 6. No Acceleration Toggle
Hub.CreateToggle(movementContainer, "No Acceleration", State.No_Acceleration, function(v)
    State.No_Acceleration = v
    Hub.Notify("Movement", v and "No Acceleration: Enabled" or "No Acceleration: Disabled", 2)
end)

-- =========================================================================
-- Subsection 2: Character Controls (Screenshot 1)
-- =========================================================================

-- 1. Fly Toggle [F]
flyToggleObj = Hub.CreateToggle(characterContainer, "Fly", State.Fly_Enabled, function(v)
    toggleFlight(v)
    Hub.Notify("Character", v and "Fly: Enabled [F]" or "Fly: Disabled [F]", 2)
end)
if flyToggleObj and flyToggleObj.Instance then
    addKeybindBadge(flyToggleObj.Instance, "F")
end

-- 2. Noclip Toggle [N]
noclipToggleObj = Hub.CreateToggle(characterContainer, "Noclip", State.Noclip_Enabled, function(v)
    toggleNoclip(v)
    Hub.Notify("Character", v and "Noclip: Enabled [N]" or "Noclip: Disabled [N]", 2)
end)
if noclipToggleObj and noclipToggleObj.Instance then
    addKeybindBadge(noclipToggleObj.Instance, "N")
end

-- Safe Teardown Hook
Hub.OnUnload(function()
    _G.DOORS_SESSION = nil
    toggleFlight(false)
    toggleNoclip(false)
    applyJumping(false)
    applySliding(false)
    local hum = getHumanoid()
    if hum then hum.WalkSpeed = 15 end
    if speedBypassCollisionClone then
        pcall(function() speedBypassCollisionClone:Destroy() end)
    end
end)

Hub.finishLoading("Movement & Character Suite Active!")
print("[UnknownHub] Clean Slate Doors.luau Loaded Successfully!")
