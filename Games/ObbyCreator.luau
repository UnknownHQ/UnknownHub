local LIBRARY_LINK = "https://raw.githubusercontent.com/UnknownHQ/UnknownHub/main/UnknownLibrary"
local LIBRARY_NAME = "ENI_ObbyCreator_UI"

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer

-- =========================================================================
-- Built-in Anti-AFK
-- =========================================================================
pcall(function()
    LocalPlayer.Idled:Connect(function()
        pcall(function()
            if VirtualUser then
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new(0, 0))
            end
        end)
    end)
end)

local function destroyOldGui()
    local parents = {game:GetService("CoreGui")}
    if gethui then pcall(function() table.insert(parents, gethui()) end) end
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if playerGui then table.insert(parents, playerGui) end
    for _, parent in ipairs(parents) do
        if parent then
            for _, child in ipairs(parent:GetChildren()) do
                if child:IsA("ScreenGui") and (child.Name == LIBRARY_NAME or child.Name == "UnknownHub_ObbyCreator") then
                    pcall(function() child:Destroy() end)
                end
            end
        end
    end
end

-- =========================================================================
-- Load UI Library
-- =========================================================================
local ok, result = pcall(function()
    local source
    local cacheBuster = "?t=" .. tostring(os.time() or tick()) .. "_" .. tostring(math.random(1000, 9999))
    source = game:HttpGet(LIBRARY_LINK .. cacheBuster)
    local factoryChunk, compileErr = loadstring(source)
    assert(factoryChunk, "UnknownLibrary failed to compile: " .. tostring(compileErr))
    return factoryChunk()
end)

assert(ok and type(result) == "function", "UnknownLibrary failed to load: " .. tostring(result))

destroyOldGui()

local Hub = result({
    name = LIBRARY_NAME,
    title = "UNKNOWN HUB",
    subTitle = "Obby Creator",
    parent = (gethui and gethui()) or game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui"),
    theme = Color3.fromRGB(255, 120, 0),
    secondaryTheme = Color3.fromRGB(180, 50, 255)
})

assert(type(Hub) == "table", "UnknownLibrary returned an invalid hub")

-- =========================================================================
-- Hub Tabs
-- =========================================================================
local buildingTab = Hub.createTabButton("Building", "🏗️ Building & Tools", "rbxassetid://10723407389", true)
local propertiesTab = Hub.createTabButton("Properties", "🎨 Advanced Properties", "rbxassetid://10723407395", false)
local skyTab      = Hub.createTabButton("Environment", "🌌 Sky & Lighting", "rbxassetid://10723407395", false)
local playerTab   = Hub.createTabButton("Player", "🏃 Player & Movement", "rbxassetid://10723407390", false)
local teleportTab = Hub.createTabButton("Teleports", "📍 Teleports & Obby", "rbxassetid://10723407392", false)

-- =========================================================================
-- State Variables
-- =========================================================================
local state = {
    AutoGamepasses = true,
    Fly = false,
    FlySpeed = 50,
    WalkSpeedEnabled = false,
    WalkSpeed = 16,
    JumpPowerEnabled = false,
    JumpPower = 50,
    InfiniteJump = false,
    Noclip = false,
    GodMode = false,
    Fullbright = false,
    ClickTP = false,
    SelectedMaterial = "Neon",
    SelectedColor = Color3.fromRGB(0, 255, 255),
    SelectedTransparency = 0,
    SelectedSpawnItem = "Part"
}

-- =========================================================================
-- Helper Functions & Advanced Tools Unlock
-- =========================================================================
local ALL_GAMEPASSES = {
    "AdvancedTools",
    "VIPPremades",
    "VIP",
    "Underground",
    "Plugin_Archimedes",
    "Plugin_Reflect",
    "MoreSpace",
    "MoreHeight",
    "DoubleCash",
    "MorePremades",
    "EvenMorePremades",
    "MoreObbies"
}

local function getMyObby()
    local getMeObby = LocalPlayer.PlayerGui:FindFirstChild("GetMeObby")
    if getMeObby then
        local ob = getMeObby:Invoke()
        if ob then return ob end
    end
    if Workspace:FindFirstChild("Obbies") and Workspace.Obbies:FindFirstChild(LocalPlayer.Name) then
        return Workspace.Obbies[LocalPlayer.Name]
    end
    return nil
end

local function unlockAdvancedTools()
    local gp = Workspace:FindFirstChild("Gamepasses")
    if gp then
        for _, passName in ipairs(ALL_GAMEPASSES) do
            local folder = gp:FindFirstChild(passName)
            if folder and not folder:FindFirstChild(LocalPlayer.Name) then
                local pFolder = Instance.new("Folder")
                pFolder.Name = LocalPlayer.Name
                pFolder.Parent = folder
            end
        end
    end

    pcall(function()
        local events = ReplicatedStorage:FindFirstChild("Events")
        if events and events:FindFirstChild("PlayerBoughtSomething") then
            events.PlayerBoughtSomething:Fire("AdvancedTools")
        end
    end)

    -- Remove UI locks and alerts completely
    pcall(function()
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        if playerGui and playerGui:FindFirstChild("Edit") then
            local editGui = playerGui.Edit
            local gf = editGui:FindFirstChild("PropertiesFrame") and editGui.PropertiesFrame:FindFirstChild("GlobalFrame")
            if gf and gf:FindFirstChild("Advanced") then
                gf.Advanced.BuyButton.Visible = false
                gf.Advanced.AdvancedWarning.Visible = false
                gf.Advanced.AdvancedBack.Visible = false
                if gf.Advanced:FindFirstChild("ScrollingFrame") then
                    gf.Advanced.ScrollingFrame.Position = UDim2.new(0, 0, 0.07, 0)
                    gf.Advanced.ScrollingFrame.Size = UDim2.new(1, 0, 0.93, 0)
                end
                if gf.Advanced:FindFirstChild("TextLabel") then
                    gf.Advanced.TextLabel.Position = UDim2.new(0.5, 0, 0, 0)
                end
                if gf.Advanced:FindFirstChild("ResetButton") then
                    gf.Advanced.ResetButton.Position = UDim2.new(0.95, 0, 0.035, 0)
                end
                if gf.Advanced:FindFirstChild("BackButton") then
                    gf.Advanced.BackButton.Position = UDim2.new(0, 0, 0, 0)
                end
            end

            local cf = editGui:FindFirstChild("ChooseFrame")
            if cf and cf:FindFirstChild("ObjectFrame") and cf.ObjectFrame:FindFirstChild("Advanced") then
                for _, obj in ipairs(cf.ObjectFrame.Advanced:GetDescendants()) do
                    if obj.Name == "AdvancedAlert" then
                        obj:Destroy()
                    end
                end
            end
        end
    end)
end

unlockAdvancedTools()

task.spawn(function()
    while true do
        task.wait(2)
        if state.AutoGamepasses then
            pcall(unlockAdvancedTools)
        end
    end
end)

-- Character getters
local function getCharacter()
    return LocalPlayer.Character
end

local function getRoot()
    local char = getCharacter()
    return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
end

local function getHumanoid()
    local char = getCharacter()
    return char and char:FindFirstChildWhichIsA("Humanoid")
end

-- =========================================================================
-- TAB 1: BUILDING & PART SPAWNER
-- =========================================================================
Hub.CreateSection(buildingTab, "Gamepass & Tools Unlocks")

Hub.CreateButton(buildingTab, "⚡ Free Advanced Tools", function()
    unlockAdvancedTools()
    pcall(function()
        local localOutput = LocalPlayer.PlayerGui:FindFirstChild("LocalOutput")
        if localOutput then
            localOutput:Fire("Advanced Tools & Gamepasses Unlocked!", Color3.fromRGB(0, 255, 120), 4)
        end
    end)
end)

Hub.CreateToggle(buildingTab, "🔄 Auto-Persist Gamepasses", true, function(toggled)
    state.AutoGamepasses = toggled
    if toggled then unlockAdvancedTools() end
end)

Hub.CreateSection(buildingTab, "Instant Item Spawner")

local POPULAR_ITEMS = {
    "Part",
    "Lava",
    "Checkpoint",
    "Conveyor",
    "Jump Pad",
    "Speed Pad",
    "Fading Part",
    "Timed Lava",
    "Push Block",
    "Button",
    "Button Deactivator",
    "Pressure Plate",
    "Seat",
    "Cutter",
    "Truss",
    "Teleport Pad"
}

Hub.CreateDropdown(buildingTab, "Select Item to Spawn", POPULAR_ITEMS, "Part", function(selected)
    state.SelectedSpawnItem = selected
end)

Hub.CreateButton(buildingTab, "✨ Spawn Selected Item at Character", function()
    pcall(function()
        local root = getRoot()
        local events = ReplicatedStorage:FindFirstChild("Events")
        if root and events and events:FindFirstChild("AddObject") then
            local targetPos = root.CFrame + (root.CFrame.LookVector * 5)
            local ok, success, msg = pcall(function()
                return events.AddObject:InvokeServer(state.SelectedSpawnItem, targetPos)
            end)
            local localOutput = LocalPlayer.PlayerGui:FindFirstChild("LocalOutput")
            if localOutput then
                if success then
                    localOutput:Fire("Spawned " .. state.SelectedSpawnItem .. " successfully!", Color3.fromRGB(0, 255, 120), 3)
                else
                    localOutput:Fire("Spawn notice: " .. tostring(msg or "Failed"), Color3.fromRGB(255, 150, 0), 3)
                end
            end
        end
    end)
end)

Hub.CreateButton(buildingTab, "🧹 Remove Build Distance Limits", function()
    pcall(function()
        local settings = require(ReplicatedStorage:WaitForChild("PlayerSettings"))
        if settings then
            settings.MaxBuildDistance = 999999
            settings.MaxSelectDistance = 999999
        end
    end)
end)

-- =========================================================================
-- TAB 2: ADVANCED PROPERTIES MODIFIER
-- =========================================================================
Hub.CreateSection(propertiesTab, "Bulk Part Painter")

local MATERIALS = {
    "Neon",
    "SmoothPlastic",
    "Plastic",
    "Glass",
    "ForceField",
    "Foil",
    "Metal",
    "Wood",
    "WoodPlanks",
    "CorrodedMetal",
    "DiamondPlate",
    "Granite",
    "Brick",
    "Cobblestone",
    "Concrete",
    "Ice",
    "Sand"
}

Hub.CreateDropdown(propertiesTab, "Material", MATERIALS, "Neon", function(selected)
    state.SelectedMaterial = selected
end)

Hub.CreateButton(propertiesTab, "🎨 Set Material to ALL Obby Parts", function()
    pcall(function()
        local obby = getMyObby()
        local events = ReplicatedStorage:FindFirstChild("Events")
        if obby and obby:FindFirstChild("Items") and events and events:FindFirstChild("PaintObject") then
            local parts = {}
            for _, desc in ipairs(obby.Items:GetDescendants()) do
                if desc:IsA("BasePart") then
                    table.insert(parts, desc)
                end
            end
            if #parts > 0 then
                events.PaintObject:InvokeServer(parts, "Material", state.SelectedMaterial)
                local localOutput = LocalPlayer.PlayerGui:FindFirstChild("LocalOutput")
                if localOutput then
                    localOutput:Fire("Changed material of " .. #parts .. " parts to " .. state.SelectedMaterial, Color3.fromRGB(0, 255, 120), 3)
                end
            end
        end
    end)
end)

Hub.CreateSlider(propertiesTab, "Transparency (0 to 100%)", 0, 100, 0, "%", function(val)
    state.SelectedTransparency = val / 100
end)

Hub.CreateButton(propertiesTab, "✨ Set Transparency to ALL Obby Parts", function()
    pcall(function()
        local obby = getMyObby()
        local events = ReplicatedStorage:FindFirstChild("Events")
        if obby and obby:FindFirstChild("Items") and events and events:FindFirstChild("PaintObject") then
            local parts = {}
            for _, desc in ipairs(obby.Items:GetDescendants()) do
                if desc:IsA("BasePart") then
                    table.insert(parts, desc)
                end
            end
            if #parts > 0 then
                events.PaintObject:InvokeServer(parts, "Transparency", state.SelectedTransparency)
            end
        end
    end)
end)

Hub.CreateSection(propertiesTab, "Color Presets")

local COLORS = {
    ["Cyan Neon"] = Color3.fromRGB(0, 255, 255),
    ["Magenta Purple"] = Color3.fromRGB(255, 0, 255),
    ["Bright Orange"] = Color3.fromRGB(255, 120, 0),
    ["Lime Green"] = Color3.fromRGB(0, 255, 100),
    ["Pure White"] = Color3.fromRGB(255, 255, 255),
    ["Pitch Black"] = Color3.fromRGB(20, 20, 20),
    ["Golden Yellow"] = Color3.fromRGB(255, 215, 0),
    ["Crimson Red"] = Color3.fromRGB(255, 30, 30)
}

for name, color in pairs(COLORS) do
    Hub.CreateButton(propertiesTab, "🎨 Paint Obby: " .. name, function()
        pcall(function()
            local obby = getMyObby()
            local events = ReplicatedStorage:FindFirstChild("Events")
            if obby and obby:FindFirstChild("Items") and events and events:FindFirstChild("PaintObject") then
                local parts = {}
                for _, desc in ipairs(obby.Items:GetDescendants()) do
                    if desc:IsA("BasePart") then
                        table.insert(parts, desc)
                    end
                end
                if #parts > 0 then
                    events.PaintObject:InvokeServer(parts, "Color", color)
                end
            end
        end)
    end)
end

-- =========================================================================
-- TAB 3: SKY & LIGHTING ENVIRONMENT (Advanced Tools feature)
-- =========================================================================
Hub.CreateSection(skyTab, "Skybox Presets")

local SKYBOX_PRESETS = {
    ["Space Galaxy"] = {
        SkyboxBk = "rbxassetid://159454299",
        SkyboxDn = "rbxassetid://159454296",
        SkyboxFt = "rbxassetid://159454293",
        SkyboxLf = "rbxassetid://159454286",
        SkyboxRt = "rbxassetid://159454300",
        SkyboxUp = "rbxassetid://159454288"
    },
    ["Purple Cyberpunk"] = {
        SkyboxBk = "rbxassetid://144933338",
        SkyboxDn = "rbxassetid://144933336",
        SkyboxFt = "rbxassetid://144933334",
        SkyboxLf = "rbxassetid://144933335",
        SkyboxRt = "rbxassetid://144933337",
        SkyboxUp = "rbxassetid://144933339"
    },
    ["Sunset Clouds"] = {
        SkyboxBk = "rbxassetid://583726774",
        SkyboxDn = "rbxassetid://583726677",
        SkyboxFt = "rbxassetid://583726832",
        SkyboxLf = "rbxassetid://583726715",
        SkyboxRt = "rbxassetid://583726740",
        SkyboxUp = "rbxassetid://583726796"
    }
}

local currentSky = nil
local function applySkybox(presetData)
    if not currentSky then
        currentSky = Lighting:FindFirstChildWhichIsA("Sky")
        if not currentSky then
            currentSky = Instance.new("Sky")
            currentSky.Parent = Lighting
        end
    end
    for prop, id in pairs(presetData) do
        currentSky[prop] = id
    end
end

for name, data in pairs(SKYBOX_PRESETS) do
    Hub.CreateButton(skyTab, "🌌 Apply Skybox: " .. name, function()
        applySkybox(data)
    end)
end

Hub.CreateSection(skyTab, "Atmosphere & Lighting")

Hub.CreateSlider(skyTab, "Time of Day (ClockTime)", 0, 24, 14, "h", function(val)
    Lighting.ClockTime = val
end)

Hub.CreateSlider(skyTab, "Brightness", 0, 10, 2, "", function(val)
    Lighting.Brightness = val
end)

Hub.CreateSlider(skyTab, "Fog Distance", 50, 10000, 10000, " studs", function(val)
    Lighting.FogEnd = val
end)

-- =========================================================================
-- TAB 4: PLAYER & MOVEMENT
-- =========================================================================
Hub.CreateSection(playerTab, "Fly System")

local flyBodyGyro, flyBodyVel
local function startFly()
    local root = getRoot()
    if not root then return end
    
    flyBodyGyro = Instance.new("BodyGyro")
    flyBodyGyro.P = 9e4
    flyBodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    flyBodyGyro.CFrame = root.CFrame
    flyBodyGyro.Parent = root
    
    flyBodyVel = Instance.new("BodyVelocity")
    flyBodyVel.Velocity = Vector3.zero
    flyBodyVel.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    flyBodyVel.Parent = root
end

local function stopFly()
    if flyBodyGyro then flyBodyGyro:Destroy() flyBodyGyro = nil end
    if flyBodyVel then flyBodyVel:Destroy() flyBodyVel = nil end
    local hum = getHumanoid()
    if hum then hum.PlatformStand = false end
end

RunService.RenderStepped:Connect(function()
    if state.Fly and flyBodyVel and flyBodyGyro then
        local root = getRoot()
        local hum = getHumanoid()
        local cam = Workspace.CurrentCamera
        if root and hum and cam then
            hum.PlatformStand = true
            local moveDir = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + (cam.CFrame.LookVector) end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - (cam.CFrame.LookVector) end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - (cam.CFrame.RightVector) end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + (cam.CFrame.RightVector) end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir - Vector3.new(0, 1, 0) end

            if moveDir.Magnitude > 0 then
                flyBodyVel.Velocity = moveDir.Unit * state.FlySpeed
            else
                flyBodyVel.Velocity = Vector3.zero
            end
            flyBodyGyro.CFrame = cam.CFrame
        end
    end
end)

Hub.CreateToggle(playerTab, "🚀 Fly Mode (WASD + Space/Shift)", false, function(toggled)
    state.Fly = toggled
    if toggled then startFly() else stopFly() end
end)

Hub.CreateSlider(playerTab, "Fly Speed", 10, 200, 50, "", function(val)
    state.FlySpeed = val
end)

Hub.CreateSection(playerTab, "Speed & Jump")

Hub.CreateToggle(playerTab, "🏃 Custom WalkSpeed", false, function(toggled)
    state.WalkSpeedEnabled = toggled
    local hum = getHumanoid()
    if hum then hum.WalkSpeed = toggled and state.WalkSpeed or 16 end
end)

Hub.CreateSlider(playerTab, "WalkSpeed", 16, 200, 32, "", function(val)
    state.WalkSpeed = val
    if state.WalkSpeedEnabled then
        local hum = getHumanoid()
        if hum then hum.WalkSpeed = val end
    end
end)

Hub.CreateToggle(playerTab, "🦘 Custom JumpPower", false, function(toggled)
    state.JumpPowerEnabled = toggled
    local hum = getHumanoid()
    if hum then
        hum.UseJumpPower = true
        hum.JumpPower = toggled and state.JumpPower or 50
    end
end)

Hub.CreateSlider(playerTab, "JumpPower", 50, 300, 100, "", function(val)
    state.JumpPower = val
    if state.JumpPowerEnabled then
        local hum = getHumanoid()
        if hum then
            hum.UseJumpPower = true
            hum.JumpPower = val
        end
    end
end)

Hub.CreateToggle(playerTab, "♾️ Infinite Jump", false, function(toggled)
    state.InfiniteJump = toggled
end)

UserInputService.JumpRequest:Connect(function()
    if state.InfiniteJump then
        local hum = getHumanoid()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

Hub.CreateSection(playerTab, "Safety & Collision")

Hub.CreateToggle(playerTab, "🧱 Noclip", false, function(toggled)
    state.Noclip = toggled
end)

RunService.Stepped:Connect(function()
    if state.Noclip then
        local char = getCharacter()
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end
end)

Hub.CreateToggle(playerTab, "🛡️ God Mode / Anti-Lava", false, function(toggled)
    state.GodMode = toggled
end)

task.spawn(function()
    while true do
        task.wait(0.5)
        if state.GodMode then
            pcall(function()
                local char = getCharacter()
                if char then
                    for _, child in ipairs(Workspace:GetDescendants()) do
                        if child:IsA("TouchTransmitter") and child.Parent then
                            local part = child.Parent
                            local pName = string.lower(part.Name)
                            if string.find(pName, "lava") or string.find(pName, "kill") or string.find(pName, "hazard") or string.find(pName, "damage") then
                                child:Destroy()
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- =========================================================================
-- TAB 5: TELEPORTS & OBBY
-- =========================================================================
Hub.CreateSection(teleportTab, "My Obby")

Hub.CreateButton(teleportTab, "🏠 Teleport to My Obby Spawn", function()
    pcall(function()
        local obby = getMyObby()
        local root = getRoot()
        if obby and root then
            if obby:FindFirstChild("StartingSpawn") and obby.StartingSpawn:FindFirstChildWhichIsA("BasePart") then
                root.CFrame = obby.StartingSpawn:FindFirstChildWhichIsA("BasePart").CFrame + Vector3.new(0, 4, 0)
            elseif obby:FindFirstChild("Area") and obby.Area:FindFirstChild("Grid") then
                root.CFrame = obby.Area.Grid.CFrame + Vector3.new(0, 5, 0)
            end
        end
    end)
end)

Hub.CreateSection(teleportTab, "Navigation Tools")

Hub.CreateToggle(teleportTab, "🎯 Click to Teleport (Ctrl + Click)", false, function(toggled)
    state.ClickTP = toggled
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and state.ClickTP and input.UserInputType == Enum.UserInputType.MouseButton1 then
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl) then
            local mouse = LocalPlayer:GetMouse()
            local root = getRoot()
            if mouse and mouse.Hit and root then
                root.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0))
            end
        end
    end
end)

Hub.CreateButton(teleportTab, "🏆 Teleport to Current Obby Checkpoints / Finish", function()
    pcall(function()
        local currentObbyVal = LocalPlayer.PlayerGui:FindFirstChild("CurrentObby")
        local obbyName = currentObbyVal and currentObbyVal.Value
        local root = getRoot()
        if obbyName and root and Workspace:FindFirstChild("Obbies") and Workspace.Obbies:FindFirstChild(obbyName) then
            local obby = Workspace.Obbies[obbyName]
            local targetPart = nil
            for _, desc in ipairs(obby:GetDescendants()) do
                if desc:IsA("BasePart") then
                    local dName = string.lower(desc.Name)
                    if string.find(dName, "win") or string.find(dName, "finish") or string.find(dName, "end") or string.find(dName, "checkpoint") then
                        targetPart = desc
                    end
                end
            end
            if targetPart then
                root.CFrame = targetPart.CFrame + Vector3.new(0, 4, 0)
            end
        end
    end)
end)

print("[Unknown Hub] Enhanced Obby Creator loaded with Advanced Tools, Item Spawner & Property Modifier!")
