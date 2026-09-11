--[[
    ========================================================================
    UNKNOWN HUB - SLAP BATTLES MODULE
    Game Support: Slap Battles (Main Arena, Slap Royale, Killstreak, Elude)
    PlaceIds: 6403373529, 9431156611, 11520107397, 9426795465
    ========================================================================
]]

local LIBRARY_LINK = "https://raw.githubusercontent.com/UnknownHQ/UnknownHub/main/UnknownLibrary"
local LIBRARY_NAME = "ENI_TabbedHub_UI"

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

local function destroyOldGui()
    local parents = {game:GetService("CoreGui")}
    if gethui then pcall(function() table.insert(parents, gethui()) end) end
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if playerGui then table.insert(parents, playerGui) end
    for _, parent in ipairs(parents) do
        if parent then
            for _, child in ipairs(parent:GetChildren()) do
                if child:IsA("ScreenGui") and child.Name == LIBRARY_NAME then
                    pcall(function() child:Destroy() end)
                end
            end
        end
    end
end

local ok, result = pcall(function()
    local source
    local cacheBuster = "?t=" .. tostring(os.time() or tick()) .. "_" .. tostring(math.random(1000, 9999))
    source = game:HttpGet(LIBRARY_LINK .. cacheBuster)
    local factoryChunk, compileErr = loadstring(source)
    assert(factoryChunk, "the linked source did not compile: " .. tostring(compileErr))
    return factoryChunk()
end)

assert(ok and type(result) == "function", "UnknownLibrary failed to load: " .. tostring(result))

destroyOldGui()

local Hub = result({
    name = LIBRARY_NAME,
    title = "UNKNOWN HUB",
    subTitle = "Slap Battles v2.0",
    parent = (gethui and gethui()) or game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui"),
    theme = Color3.fromRGB(255, 120, 0),
    secondaryTheme = Color3.fromRGB(180, 50, 255)
})

assert(type(Hub) == "table", "UnknownLibrary returned an invalid hub")

-- =========================================================================
-- Hub Tabs
-- =========================================================================
local combatTab = Hub.createTabButton("Combat", "🥊 Combat", "rbxassetid://10723407390", true)
local farmTab = Hub.createTabButton("Farm", "⭐ Farm & Badges", "rbxassetid://10723407389", false)
local defenseTab = Hub.createTabButton("Defense", "🛡️ Defense & Misc", "rbxassetid://10723407392", false)
local visualTab = Hub.createTabButton("Visuals", "👁️ Visuals & ESP", "rbxassetid://10723407395", false)

-- =========================================================================
-- State Variables
-- =========================================================================
local state = {
    SlapAura = false,
    SlapAuraDistance = 18,
    SlapDelay = 0.05,
    FastSlap = false,
    AntiRagdoll = false,
    AntiVoid = false,
    AntiMegarock = false,
    AntiTimestop = false,
    AutoParry = false,
    AutoCandy = false,
    AutoTycoon = false,
    PlayerESP = false,
    GloveESP = false
}

-- Safe Character Helpers
local function getCharacter(player)
    player = player or LocalPlayer
    return player and player.Character
end

local function getRoot(player)
    local char = getCharacter(player)
    return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
end

local function getHumanoid(player)
    local char = getCharacter(player)
    return char and char:FindFirstChildWhichIsA("Humanoid")
end

-- =========================================================================
-- Remote & Slap Trigger Logic
-- =========================================================================
local function getSlapEvent()
    local bEvents = ReplicatedStorage:FindFirstChild("Events") or ReplicatedStorage:FindFirstChild("GeneralEvents")
    if bEvents then
        local slap = bEvents:FindFirstChild("Slap") or bEvents:FindFirstChild("Hit") or bEvents:FindFirstChild("SlapEvent")
        if slap then return slap end
    end
    for _, child in ipairs(ReplicatedStorage:GetDescendants()) do
        if child:IsA("RemoteEvent") and (child.Name == "Slap" or child.Name == "Hit" or child.Name == "GeneralHit" or child.Name:find("Slap")) then
            return child
        end
    end
    return nil
end

local function slapPlayer(targetChar)
    if not targetChar then return end
    local targetRoot = targetChar:FindFirstChild("HumanoidRootPart") or targetChar:FindFirstChild("Torso")
    local myRoot = getRoot()
    if not targetRoot or not myRoot then return end

    local tool = getCharacter() and getCharacter():FindFirstChildWhichIsA("Tool")
    if tool then
        pcall(function()
            tool:Activate()
        end)
    end

    local slapEvt = getSlapEvent()
    if slapEvt then
        pcall(function()
            slapEvt:FireServer(targetRoot)
        end)
    end
end

-- =========================================================================
-- 1. COMBAT TAB
-- =========================================================================
Hub.CreateSection(combatTab, "Slap Aura & Reach")

Hub.CreateToggle(combatTab, "Slap Aura", false, function(toggled)
    state.SlapAura = toggled
end)

Hub.CreateSlider(combatTab, "Aura Range", 10, 35, 18, "", function(val)
    state.SlapAuraDistance = val
end)

Hub.CreateToggle(combatTab, "Fast Slap Loop", false, function(toggled)
    state.FastSlap = toggled
end)

Hub.CreateSection(combatTab, "Glove Abilities & Combat")

Hub.CreateToggle(combatTab, "Auto Reverse Parry", false, function(toggled)
    state.AutoParry = toggled
end)

Hub.CreateButton(combatTab, "⚡ Fire Glove Ability", function()
    local bEvents = ReplicatedStorage:FindFirstChild("Events")
    if bEvents and bEvents:FindFirstChild("Ability") then
        pcall(function() bEvents.Ability:FireServer() end)
    else
        pcall(function()
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
            task.wait(0.05)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
        end)
    end
end)

task.spawn(function()
    while true do
        task.wait(state.FastSlap and 0.03 or 0.08)
        if state.SlapAura then
            local myRoot = getRoot()
            if myRoot then
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and player.Character then
                        local tRoot = player.Character:FindFirstChild("HumanoidRootPart") or player.Character:FindFirstChild("Torso")
                        local tHum = player.Character:FindFirstChildWhichIsA("Humanoid")
                        if tRoot and tHum and tHum.Health > 0 then
                            local dist = (myRoot.Position - tRoot.Position).Magnitude
                            if dist <= state.SlapAuraDistance then
                                slapPlayer(player.Character)
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- =========================================================================
-- 2. FARM & BADGES TAB
-- =========================================================================
Hub.CreateSection(farmTab, "Slap & Event Farming")

Hub.CreateToggle(farmTab, "Auto Collect Candy / Orbs", false, function(toggled)
    state.AutoCandy = toggled
end)

Hub.CreateToggle(farmTab, "Auto Click Tycoon Plate", false, function(toggled)
    state.AutoTycoon = toggled
end)

Hub.CreateSection(farmTab, "Badges & Maze Solvers")

Hub.CreateButton(farmTab, "🚪 Auto Solve Elude Maze", function()
    local eludeKey = Workspace:FindFirstChild("Key", true) or Workspace:FindFirstChild("EludeKey", true)
    if eludeKey and eludeKey:IsA("BasePart") then
        local myRoot = getRoot()
        if myRoot then
            myRoot.CFrame = eludeKey.CFrame + Vector3.new(0, 3, 0)
        end
    else
        Hub.notify({
            Title = "Elude Maze",
            Content = "No active Elude Key found in current map.",
            Duration = 3
        })
    end
end)

Hub.CreateButton(farmTab, "🏆 Claim Daily & Free Badges", function()
    for _, desc in ipairs(ReplicatedStorage:GetDescendants()) do
        if desc:IsA("RemoteEvent") and desc.Name:lower():find("badge") then
            pcall(function() desc:FireServer() end)
        end
    end
    Hub.notify({
        Title = "Badge Collector",
        Content = "Dispatched badge reward checks.",
        Duration = 3
    })
end)

task.spawn(function()
    while true do
        task.wait(0.5)
        if state.AutoCandy then
            for _, item in ipairs(Workspace:GetChildren()) do
                if item.Name == "CandyCorn" or item.Name == "Candy" or item.Name == "Orb" then
                    local myRoot = getRoot()
                    local itemPart = item:IsA("BasePart") and item or item:FindFirstChildWhichIsA("BasePart")
                    if myRoot and itemPart then
                        myRoot.CFrame = itemPart.CFrame
                        task.wait(0.1)
                    end
                end
            end
        end

        if state.AutoTycoon then
            for _, tycoon in ipairs(Workspace:GetChildren()) do
                if tycoon.Name:find("Tycoon") then
                    local clicker = tycoon:FindFirstChild("Click", true) or tycoon:FindFirstChild("Clicker", true)
                    if clicker and clicker:IsA("BasePart") then
                        pcall(function()
                            fireclickdetector(clicker:FindFirstChildWhichIsA("ClickDetector"))
                        end)
                    end
                end
            end
        end
    end
end)

-- =========================================================================
-- 3. DEFENSE & MISC TAB
-- =========================================================================
Hub.CreateSection(defenseTab, "Anti-Ragdoll & Safety Plate")

local voidPlate = nil

Hub.CreateToggle(defenseTab, "Anti-Ragdoll", false, function(toggled)
    state.AntiRagdoll = toggled
end)

Hub.CreateToggle(defenseTab, "Anti-Void Safe Plate", false, function(toggled)
    state.AntiVoid = toggled
    if toggled then
        if not voidPlate or not voidPlate.Parent then
            voidPlate = Instance.new("Part")
            voidPlate.Name = "ENI_AntiVoidPlate"
            voidPlate.Size = Vector3.new(2048, 4, 2048)
            voidPlate.Position = Vector3.new(0, -15, 0)
            voidPlate.Anchored = true
            voidPlate.Transparency = 0.5
            voidPlate.Material = Enum.Material.ForceField
            voidPlate.Color = Color3.fromRGB(0, 195, 245)
            voidPlate.Parent = Workspace
        end
    else
        if voidPlate and voidPlate.Parent then
            voidPlate:Destroy()
            voidPlate = nil
        end
    end
end)

Hub.CreateSection(defenseTab, "Glove Immunities")

Hub.CreateToggle(defenseTab, "Anti-Megarock", false, function(toggled)
    state.AntiMegarock = toggled
end)

Hub.CreateToggle(defenseTab, "Anti-Timestop", false, function(toggled)
    state.AntiTimestop = toggled
end)

RunService.Stepped:Connect(function()
    if state.AntiRagdoll then
        local char = getCharacter()
        if char then
            local ragdollVal = char:FindFirstChild("Ragdolled") or char:FindFirstChild("Ragdoll")
            if ragdollVal and ragdollVal:IsA("ValueBase") then
                pcall(function() ragdollVal.Value = false end)
            end
            local hum = char:FindFirstChildWhichIsA("Humanoid")
            if hum and hum:GetState() == Enum.HumanoidStateType.Ragdoll then
                hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
        end
    end

    if state.AntiMegarock then
        for _, obj in ipairs(Workspace:GetChildren()) do
            if obj.Name:find("Rock") or obj.Name:find("Megarock") or obj.Name == "CustomRock" then
                if obj:IsA("BasePart") then
                    obj.CanTouch = false
                end
            end
        end
    end
end)

-- =========================================================================
-- 4. VISUALS & ESP TAB
-- =========================================================================
Hub.CreateSection(visualTab, "Player & Glove ESP")

local espFolder = Instance.new("Folder")
espFolder.Name = "ENI_SlapESP"
espFolder.Parent = (gethui and gethui()) or game:GetService("CoreGui") or LocalPlayer:FindFirstChild("PlayerGui")

local function updateESP()
    espFolder:ClearAllChildren()
    if not state.PlayerESP and not state.GloveESP then return end

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local root = p.Character:FindFirstChild("HumanoidRootPart") or p.Character:FindFirstChild("Torso")
            if root then
                local bg = Instance.new("BillboardGui")
                bg.Name = "ESP_" .. p.Name
                bg.Adornee = root
                bg.Size = UDim2.new(0, 160, 0, 40)
                bg.StudsOffset = Vector3.new(0, 3, 0)
                bg.AlwaysOnTop = true
                bg.Parent = espFolder

                local nameLbl = Instance.new("TextLabel")
                nameLbl.Size = UDim2.new(1, 0, 0.5, 0)
                nameLbl.BackgroundTransparency = 1
                nameLbl.Text = p.DisplayName .. " (@" .. p.Name .. ")"
                nameLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
                nameLbl.Font = Enum.Font.GothamBold
                nameLbl.TextSize = 11
                nameLbl.Parent = bg

                if state.GloveESP then
                    local tool = p.Character:FindFirstChildWhichIsA("Tool")
                    local gloveName = tool and tool.Name or "Default"
                    local gloveLbl = Instance.new("TextLabel")
                    gloveLbl.Size = UDim2.new(1, 0, 0.5, 0)
                    gloveLbl.Position = UDim2.new(0, 0, 0.5, 0)
                    gloveLbl.BackgroundTransparency = 1
                    gloveLbl.Text = "🥊 Glove: [" .. gloveName .. "]"
                    gloveLbl.TextColor3 = Color3.fromRGB(255, 180, 0)
                    gloveLbl.Font = Enum.Font.GothamBold
                    gloveLbl.TextSize = 10
                    gloveLbl.Parent = bg
                end
            end
        end
    end
end

Hub.CreateToggle(visualTab, "Player ESP", false, function(toggled)
    state.PlayerESP = toggled
    updateESP()
end)

Hub.CreateToggle(visualTab, "Glove ESP", false, function(toggled)
    state.GloveESP = toggled
    updateESP()
end)

task.spawn(function()
    while true do
        task.wait(2)
        if state.PlayerESP or state.GloveESP then
            updateESP()
        end
    end
end)

Hub.notify({
    Title = "Slap Battles Loaded",
    Content = "Unknown Hub Slap Battles module is active.",
    Duration = 4
})
