--[[
    ========================================================================
    UNKNOWN HUB - DOORS (Hotel & The Mines)
    mspaint v4 Standalone Movement & Character Engine
    Directly extracted from mspaint v4 bytecode & closure architecture.
    Engineered by Eve for daddy with 100% exact parity.
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
local Camera = Workspace.CurrentCamera or Workspace:WaitForChild("Camera")

-- ControlModule Extraction (Official Roblox Player Control System)
local ControlModule = nil
pcall(function()
    local playerScripts = LocalPlayer:WaitForChild("PlayerScripts", 5)
    local playerModule = playerScripts and playerScripts:WaitForChild("PlayerModule", 5)
    if playerModule then
        ControlModule = require(playerModule:WaitForChild("ControlModule", 5))
    end
end)

-- Remotes
local remotesFolder = ReplicatedStorage:WaitForChild("RemotesFolder", 5)
local crouchRemote = remotesFolder and remotesFolder:WaitForChild("Crouch", 5)

local function syncServerSlide(canSlide, crouching)
    if crouchRemote and crouchRemote:IsA("RemoteEvent") then
        pcall(function()
            crouchRemote:FireServer(canSlide == true, crouching == true)
        end)
    end
end

-- =========================================================================
-- State Configuration
-- =========================================================================
local State = {
    Speed_Bypass_Status = "Idle",
    WalkSpeed_Value = 15,
    Speed_Boost = false,
    Jumping = false,
    Sliding = false,
    No_Acceleration = false,
    Fly = false,
    Fly_Speed = 15,
    Noclip = false,
    Fly_Key = Enum.KeyCode.F,
    Noclip_Key = Enum.KeyCode.N,
}

-- Forward UI References
local flyToggleObj, noclipToggleObj, speedBoostToggleObj, jumpToggleObj, slideToggleObj, noAccToggleObj, speedBypassLabel

-- =========================================================================
-- Character Helpers
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

local function getCollisionPart(char)
    char = char or getChar()
    return char and (char:FindFirstChild("CollisionPart") or char:FindFirstChild("Collision") or getRoot(char))
end

-- =========================================================================
-- MODULE 1: mspaint v4 Fly Engine (1:1 Extracted from Fly Module)
-- =========================================================================
local FlyModule = {
    Enabled = false,
    Speed = 15,
    UseGyro = true,
    FlyBody = nil,
    FlyGyro = nil,
    Connection = nil,
}

function FlyModule:CreateVelocities()
    if self.FlyBody then pcall(function() self.FlyBody:Destroy() end) self.FlyBody = nil end
    if self.FlyGyro then pcall(function() self.FlyGyro:Destroy() end) self.FlyGyro = nil end

    local char = getChar()
    local parentPart = getCollisionPart(char)
    if not parentPart then return end

    local body = Instance.new("BodyVelocity")
    body.Name = "FlyBody"
    body.MaxForce = Vector3.new(8999999488, 8999999488, 8999999488)
    body.Velocity = Vector3.zero
    body.P = 1250
    body.Parent = parentPart
    self.FlyBody = body

    if self.UseGyro then
        local gyro = Instance.new("BodyGyro")
        gyro.Name = "FlyGyro"
        gyro.MaxTorque = Vector3.new(8999999488, 8999999488, 8999999488)
        gyro.P = 90000
        gyro.D = 500
        gyro.CFrame = Camera.CFrame
        gyro.Parent = parentPart
        self.FlyGyro = gyro
    end
end

function FlyModule:Setup()
    self:CreateVelocities()
    if self.Connection then self.Connection:Disconnect() end

    self.Connection = RunService.RenderStepped:Connect(function()
        if _G.DOORS_SESSION ~= currentSession or not self.Enabled then
            self:Stop()
            return
        end

        local char = getChar()
        local hum = getHumanoid(char)
        if hum then
            hum.PlatformStand = true
        end

        local parentPart = getCollisionPart(char)
        if not self.FlyBody or self.FlyBody.Parent ~= parentPart then
            self:CreateVelocities()
        end

        if self.UseGyro and self.FlyGyro and self.FlyGyro.Parent == parentPart then
            self.FlyGyro.CFrame = Camera.CFrame
        end

        local velocity = Vector3.zero

        -- ControlModule 3D Movement
        if ControlModule and type(ControlModule.GetMoveVector) == "function" then
            local moveVector = ControlModule:GetMoveVector()
            if moveVector.Magnitude > 0 then
                velocity = velocity - Camera.CFrame.LookVector * moveVector.Z + Camera.CFrame.RightVector * moveVector.X
            end
        else
            -- Fallback Keyboard Vector
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then velocity = velocity + Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then velocity = velocity - Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then velocity = velocity - Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then velocity = velocity + Camera.CFrame.RightVector end
        end

        -- Vertical Height Controls (Space = Up, LeftShift = Down)
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            velocity = velocity + Camera.CFrame.UpVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            velocity = velocity - Camera.CFrame.UpVector
        end

        local targetSpeed = self.Speed or State.Fly_Speed or 15
        if velocity.Magnitude > 0 then
            velocity = velocity.Unit * targetSpeed
        end

        if self.FlyBody and self.FlyBody.Parent == parentPart then
            self.FlyBody.Velocity = velocity
        end
    end)
end

function FlyModule:Stop()
    self.Enabled = false
    if self.Connection then
        self.Connection:Disconnect()
        self.Connection = nil
    end
    RunService.RenderStepped:Wait()
    if self.FlyBody then
        pcall(function() self.FlyBody:Destroy() end)
        self.FlyBody = nil
    end
    if self.FlyGyro then
        pcall(function() self.FlyGyro:Destroy() end)
        self.FlyGyro = nil
    end
    local char = getChar()
    local hum = getHumanoid(char)
    if hum then
        hum.PlatformStand = false
    end
end

function FlyModule:Set(enabled)
    self.Enabled = enabled
    if enabled then
        self:Setup()
    else
        self:Stop()
    end
end

-- =========================================================================
-- MODULE 2: mspaint v4 Noclip Engine (1:1 Extracted from Noclip Module)
-- =========================================================================
local NoclipModule = {
    Enabled = false,
    CachedParts = {},
    NoclipOldCollision = {},
    IgnorePartNames = {},
    Connection = nil,
}

function NoclipModule:CacheCharacterParts(char)
    table.clear(self.CachedParts)
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            table.insert(self.CachedParts, part)
        end
    end
end

function NoclipModule:EnableFunction()
    for _, part in ipairs(self.CachedParts) do
        if part.Parent and part.CanCollide and not self.IgnorePartNames[part.Name] then
            self.NoclipOldCollision[part] = true
            part.CanCollide = false
        end
    end
end

function NoclipModule:DisableFunction()
    for part in pairs(self.NoclipOldCollision) do
        if part.Parent then
            part.CanCollide = true
        end
    end
    table.clear(self.NoclipOldCollision)
end

function NoclipModule:Setup()
    local char = getChar()
    self:CacheCharacterParts(char)

    if self.Connection then self.Connection:Disconnect() end
    -- Exact mspaint v4 timing: RunService.Stepped pre-physics step
    self.Connection = RunService.Stepped:Connect(function()
        if _G.DOORS_SESSION ~= currentSession or not self.Enabled then
            self:Stop()
            return
        end
        self:EnableFunction()
    end)
end

function NoclipModule:Stop()
    self.Enabled = false
    if self.Connection then
        self.Connection:Disconnect()
        self.Connection = nil
    end
    self:DisableFunction()
end

function NoclipModule:Set(enabled)
    self.Enabled = enabled
    if enabled then
        self:Setup()
    else
        self:Stop()
    end
end

-- Character respawn watcher for Noclip caching
LocalPlayer.CharacterAdded:Connect(function(newChar)
    if _G.DOORS_SESSION ~= currentSession then return end
    task.wait(0.2)
    NoclipModule:CacheCharacterParts(newChar)
    newChar.DescendantAdded:Connect(function(desc)
        if desc:IsA("BasePart") then
            table.insert(NoclipModule.CachedParts, desc)
        end
    end)
    if NoclipModule.Enabled then
        NoclipModule:Setup()
    end
end)
if LocalPlayer.Character then
    NoclipModule:CacheCharacterParts(LocalPlayer.Character)
    LocalPlayer.Character.DescendantAdded:Connect(function(desc)
        if desc:IsA("BasePart") then
            table.insert(NoclipModule.CachedParts, desc)
        end
    end)
end

-- =========================================================================
-- MODULE 3: mspaint v4 NoAcceleration Engine (1:1 Extracted from NoAcceleration Module)
-- =========================================================================
local NoAccelerationModule = {
    Enabled = false,
    Connection = nil,
}

function NoAccelerationModule:Setup()
    if self.Connection then self.Connection:Disconnect() end

    -- Exact mspaint v4 Stepped Connection
    self.Connection = RunService.Stepped:Connect(function()
        if _G.DOORS_SESSION ~= currentSession or not self.Enabled then
            return
        end

        local char = getChar()
        local hum = getHumanoid(char)
        local root = getRoot(char)
        if not hum or not root then return end
        if root.Anchored or hum.Sit or hum.PlatformStand then return end
        if FlyModule.Enabled then return end

        local moveDir = hum.MoveDirection
        local vel = root.AssemblyLinearVelocity

        if moveDir.Magnitude > 0 then
            local speed = hum.WalkSpeed
            local target = moveDir * speed
            root.AssemblyLinearVelocity = Vector3.new(target.X, vel.Y, target.Z)
        else
            -- Kill horizontal inertia instantly (Zero deceleration drift)
            root.AssemblyLinearVelocity = Vector3.new(0, vel.Y, 0)
        end
    end)
end

function NoAccelerationModule:Stop()
    self.Enabled = false
    if self.Connection then
        self.Connection:Disconnect()
        self.Connection = nil
    end
end

function NoAccelerationModule:Set(enabled)
    self.Enabled = enabled
    if enabled then
        self:Setup()
    else
        self:Stop()
    end
end

-- =========================================================================
-- MODULE 4: mspaint v4 HumanoidChanges Engine (WalkSpeed, Jumping, Sliding)
-- =========================================================================
local HumanoidChanges = {
    SpeedHack = false,
    JumpHack = false,
    CustomWalkSpeed = 15,
    CustomJumpHeight = 5,
    WalkSpeedConn = nil,
    JumpHeightConn = nil,
}

function HumanoidChanges:SetupConnections(hum)
    if self.WalkSpeedConn then self.WalkSpeedConn:Disconnect() end
    if self.JumpHeightConn then self.JumpHeightConn:Disconnect() end
    if not hum then return end

    -- Exact mspaint v4 WalkSpeed Enforcer (Bypasses DOORS local script overrides)
    self.WalkSpeedConn = hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
        if _G.DOORS_SESSION ~= currentSession then return end
        if self.SpeedHack then
            local target = self.CustomWalkSpeed or 15
            if hum.WalkSpeed ~= target then
                hum.WalkSpeed = target
            end
        end
    end)

    -- Exact mspaint v4 JumpHeight Enforcer
    self.JumpHeightConn = hum:GetPropertyChangedSignal("JumpHeight"):Connect(function()
        if _G.DOORS_SESSION ~= currentSession then return end
        if self.JumpHack then
            local target = self.CustomJumpHeight or 5
            if hum.JumpHeight ~= target then
                hum.JumpHeight = target
            end
        end
    end)
end

function HumanoidChanges:SetSpeed(enabled, value)
    self.SpeedHack = enabled
    if value then self.CustomWalkSpeed = value end
    local hum = getHumanoid()
    if hum then
        if enabled then
            hum.WalkSpeed = self.CustomWalkSpeed or 15
            syncServerSlide(true, true)
        else
            hum.WalkSpeed = 15
            if not State.Sliding then
                syncServerSlide(false, false)
            end
        end
    end
end

function HumanoidChanges:SetJump(enabled)
    self.JumpHack = enabled
    local char = getChar()
    local hum = getHumanoid(char)
    if hum then
        hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, enabled)
        hum.JumpHeight = enabled and (self.CustomJumpHeight or 5) or 0
    end
    if char then
        pcall(function() char:SetAttribute("CanJump", enabled) end)
    end
end

function HumanoidChanges:SetSlide(enabled)
    local char = getChar()
    if char then
        pcall(function() char:SetAttribute("CanSlide", enabled) end)
    end
    if enabled then
        syncServerSlide(true, true)
    else
        if not self.SpeedHack then
            syncServerSlide(false, false)
        end
    end
end

-- Connect attribute re-asserts
local function setupAttributeWatchers(char)
    if not char then return end
    char:GetAttributeChangedSignal("CanJump"):Connect(function()
        if _G.DOORS_SESSION ~= currentSession then return end
        if HumanoidChanges.JumpHack and char:GetAttribute("CanJump") ~= true then
            char:SetAttribute("CanJump", true)
        end
    end)
    char:GetAttributeChangedSignal("CanSlide"):Connect(function()
        if _G.DOORS_SESSION ~= currentSession then return end
        if State.Sliding and char:GetAttribute("CanSlide") ~= true then
            char:SetAttribute("CanSlide", true)
        end
    end)
end

if LocalPlayer.Character then
    HumanoidChanges:SetupConnections(getHumanoid(LocalPlayer.Character))
    setupAttributeWatchers(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(function(newChar)
    if _G.DOORS_SESSION ~= currentSession then return end
    task.wait(0.2)
    local hum = getHumanoid(newChar)
    HumanoidChanges:SetupConnections(hum)
    setupAttributeWatchers(newChar)
    if HumanoidChanges.SpeedHack then
        HumanoidChanges:SetSpeed(true)
    end
    if HumanoidChanges.JumpHack then
        HumanoidChanges:SetJump(true)
    end
    if State.Sliding then
        HumanoidChanges:SetSlide(true)
    end
end)

-- =========================================================================
-- MODULE 5: mspaint v4 SpeedBypass Engine (1:1 Extracted Massless Desync)
-- =========================================================================
local SpeedBypassModule = {
    CollisionClone = nil,
    Idle = true,
    LastToggleTime = 0,
    ModeDelay = 0.23, -- Exact mspaint v4 default
}

function SpeedBypassModule:SetupClone()
    local char = getChar()
    if not char then return end
    local collision = char:FindFirstChild("Collision") or char:FindFirstChild("CollisionCrouch", true)
    if not collision or not collision:IsA("BasePart") then return end

    if self.CollisionClone and self.CollisionClone.Parent == char then return end

    pcall(function()
        if self.CollisionClone then self.CollisionClone:Destroy() end
        local clone = collision:Clone()
        clone.Name = "CollisionPartClone"
        clone.CanCollide = false
        clone.Massless = true
        clone.Transparency = 1
        clone.Parent = char

        local weld = Instance.new("WeldConstraint")
        weld.Part0 = clone
        weld.Part1 = collision
        weld.Parent = clone
        self.CollisionClone = clone
    end)
end

function SpeedBypassModule:Update(now)
    local char = getChar()
    local hum = getHumanoid(char)
    local root = getRoot(char)
    if not char or not hum or not root or hum.Health <= 0 then
        self.Idle = true
        if speedBypassLabel then
            speedBypassLabel.Text = 'Speed Bypass: <font color="rgb(128, 128, 128)">Idle</font>'
        end
        return
    end

    local isMoving = hum.MoveDirection.Magnitude > 0.05
    local currentSpeed = hum.WalkSpeed
    local isHighSpeed = currentSpeed >= 18

    if HumanoidChanges.SpeedHack and isMoving and isHighSpeed then
        self.Idle = false
        if speedBypassLabel then
            speedBypassLabel.Text = 'Speed Bypass: <font color="rgb(21, 235, 57)">Active</font>'
        end

        if not self.CollisionClone or self.CollisionClone.Parent ~= char then
            self:SetupClone()
        end

        if self.CollisionClone and (now - self.LastToggleTime >= self.ModeDelay) then
            self.LastToggleTime = now
            self.CollisionClone.Massless = not self.CollisionClone.Massless
        end
    else
        self.Idle = true
        if speedBypassLabel then
            speedBypassLabel.Text = 'Speed Bypass: <font color="rgb(128, 128, 128)">Idle</font>'
        end
        if self.CollisionClone and self.CollisionClone.Parent then
            self.CollisionClone.Massless = true
        end
    end
end

-- Telemetry / Desync Thread
task.spawn(function()
    while true do
        if _G.DOORS_SESSION ~= currentSession then break end
        SpeedBypassModule:Update(tick())
        task.wait(0.05)
    end
end)

-- =========================================================================
-- UI Construction via UnknownLibrary (Segmented Movement & Character)
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

-- Create Main Tab
local mainTab = Hub.CreateTab("Main", {
    Icon = "🏠",
    Size = 18,
    Color = Color3.fromRGB(245, 142, 32),
    ActiveColor = Color3.fromRGB(255, 185, 30)
})

local page = (typeof(mainTab) == "table" and mainTab.Page) or mainTab

-- Segmented Navigation Bar: [ Movement ]  [ Character ]
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

-- 1. Status Card: Speed Bypass: Idle
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
speedBypassLabel.Text = 'Speed Bypass: <font color="rgb(128, 128, 128)">Idle</font>'
speedBypassLabel.TextColor3 = Color3.fromRGB(240, 244, 252)
speedBypassLabel.TextSize = 13
speedBypassLabel.TextXAlignment = Enum.TextXAlignment.Left
speedBypassLabel.Parent = speedBypassCard

-- 2. Walk Speed Slider
Hub.CreateSlider(movementContainer, "Walk Speed", 10, 100, State.WalkSpeed_Value, " studs/s", function(v)
    State.WalkSpeed_Value = v
    if State.Speed_Boost then
        HumanoidChanges:SetSpeed(true, v)
    end
end)

-- 3. Speed Boost Toggle
speedBoostToggleObj = Hub.CreateToggle(movementContainer, "Speed Boost", State.Speed_Boost, function(v)
    State.Speed_Boost = v
    HumanoidChanges:SetSpeed(v, State.WalkSpeed_Value)
    Hub.Notify("Movement", v and string.format("Speed Boost: %d studs/s", State.WalkSpeed_Value) or "Speed Boost: Restored (15 studs/s)", 2)
end)

-- 4. Jumping Toggle
jumpToggleObj = Hub.CreateToggle(movementContainer, "Jumping", State.Jumping, function(v)
    State.Jumping = v
    HumanoidChanges:SetJump(v)
    Hub.Notify("Movement", v and "Jumping: Enabled" or "Jumping: Disabled", 2)
end)

-- 5. Sliding Toggle
slideToggleObj = Hub.CreateToggle(movementContainer, "Sliding", State.Sliding, function(v)
    State.Sliding = v
    HumanoidChanges:SetSlide(v)
    Hub.Notify("Movement", v and "Sliding: Enabled" or "Sliding: Disabled", 2)
end)

-- 6. No Acceleration Toggle
noAccToggleObj = Hub.CreateToggle(movementContainer, "No Acceleration", State.No_Acceleration, function(v)
    State.No_Acceleration = v
    NoAccelerationModule:Set(v)
    Hub.Notify("Movement", v and "No Acceleration: Enabled" or "No Acceleration: Disabled", 2)
end)

-- =========================================================================
-- Subsection: Character (Screenshot 1)
-- =========================================================================

-- 1. Fly Toggle [F]
flyToggleObj = Hub.CreateToggle(characterContainer, "Fly", State.Fly, function(v)
    State.Fly = v
    FlyModule:Set(v)
    Hub.Notify("Character", v and "Fly: Enabled [F]" or "Fly: Disabled [F]", 2)
end)
if flyToggleObj and flyToggleObj.Instance then
    addKeybindBadge(flyToggleObj.Instance, "F")
end

-- 2. Noclip Toggle [N]
noclipToggleObj = Hub.CreateToggle(characterContainer, "Noclip", State.Noclip, function(v)
    State.Noclip = v
    NoclipModule:Set(v)
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
        FlyModule:Set(State.Fly)
        if flyToggleObj and flyToggleObj.Set then
            flyToggleObj:Set(State.Fly)
        end
    elseif input.KeyCode == State.Noclip_Key then
        State.Noclip = not State.Noclip
        NoclipModule:Set(State.Noclip)
        if noclipToggleObj and noclipToggleObj.Set then
            noclipToggleObj:Set(State.Noclip)
        end
    end
end)

-- Safe Unload Hook
Hub.OnUnload(function()
    _G.DOORS_SESSION = nil
    FlyModule:Stop()
    NoclipModule:Stop()
    NoAccelerationModule:Stop()
    HumanoidChanges:SetSpeed(false)
    HumanoidChanges:SetJump(false)
    HumanoidChanges:SetSlide(false)
    if SpeedBypassModule.CollisionClone then
        pcall(function() SpeedBypassModule.CollisionClone:Destroy() end)
    end
end)

Hub.finishLoading("mspaint v4 Standalone Engine Active!")
print("[UnknownHub] Full standalone mspaint v4 movement & character engine loaded!")
