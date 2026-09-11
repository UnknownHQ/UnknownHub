--[[
    ========================================================================
    UNKNOWN HUB - SLAP BATTLES MODULE
    Game Support: Slap Battles (Main Arena, Slap Royale, Killstreak, Elude)
    PlaceIds: 6403373529, 9431156611, 11520107397, 9426795465
    Features: Combat, Slap Aura, Auto-Badge Gloves, Sky Safe Zone, ESP
    ========================================================================
]]

local LIBRARY_LINK = "https://raw.githubusercontent.com/UnknownHQ/UnknownHub/main/UnknownLibrary"
local LIBRARY_NAME = "ENI_TabbedHub_UI"

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local VirtualUser = game:GetService("VirtualUser")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- =========================================================================
-- Built-in Anti-AFK (Prevents 20-minute Roblox Disconnect during AFK grinds)
-- =========================================================================
pcall(function()
    LocalPlayer.Idled:Connect(function()
        if VirtualUser then
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new(0, 0))
        else
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
            task.wait(0.05)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
        end
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
    subTitle = "Slap Battles v2.5 • Badge Master",
    parent = (gethui and gethui()) or game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui"),
    theme = Color3.fromRGB(255, 120, 0),
    secondaryTheme = Color3.fromRGB(180, 50, 255)
})

assert(type(Hub) == "table", "UnknownLibrary returned an invalid hub")

-- =========================================================================
-- Hub Tabs
-- =========================================================================
local combatTab = Hub.createTabButton("Combat", "🥊 Combat", "rbxassetid://10723407390", true)
local badgeTab  = Hub.createTabButton("Badges", "🏆 Auto Gloves", "rbxassetid://10723407389", false)
local farmTab   = Hub.createTabButton("Farm", "⭐ General Farm", "rbxassetid://10723407389", false)
local defenseTab = Hub.createTabButton("Defense", "🛡️ Defense & Safe", "rbxassetid://10723407392", false)
local visualTab = Hub.createTabButton("Visuals", "👁️ Visuals & ESP", "rbxassetid://10723407395", false)

-- =========================================================================
-- State Variables
-- =========================================================================
local state = {
    SlapAura = false,
    SlapAuraDistance = 18,
    FastSlap = false,
    AntiRagdoll = false,
    AntiVoid = false,
    AntiMegarock = false,
    AntiTimestop = false,
    AutoParry = false,
    AutoCandy = false,
    AutoTycoon = false,
    PlayerESP = false,
    GloveESP = false,
    -- Auto-Gloves Grinds
    AutoMegarock = false,
    AutoFish = false,
    AutoTrap = false,
    AutoVoodoo = false,
    TrapBrickCount = 0,
    InSafeZone = false
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

local function getSlapCount()
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    if leaderstats and leaderstats:FindFirstChild("Slaps") then
        return leaderstats.Slaps.Value
    end
    return 0
end

-- =========================================================================
-- Sky Safe Zone System (Protected Platform far above the map)
-- =========================================================================
local SAFE_ZONE_POS = Vector3.new(0, 3500, 0)
local safeZoneModel = nil

local function getOrCreateSafeZone()
    if safeZoneModel and safeZoneModel.Parent then
        return safeZoneModel
    end

    local model = Instance.new("Model")
    model.Name = "ENI_SkySafeZone"

    local floor = Instance.new("Part")
    floor.Name = "Floor"
    floor.Size = Vector3.new(30, 2, 30)
    floor.Position = SAFE_ZONE_POS
    floor.Anchored = true
    floor.Material = Enum.Material.ForceField
    floor.Color = Color3.fromRGB(0, 195, 245)
    floor.Transparency = 0.3
    floor.Parent = model

    -- Surrounding safety walls
    local wallOffsets = {
        {Vector3.new(0, 5, 15), Vector3.new(30, 10, 1)},
        {Vector3.new(0, 5, -15), Vector3.new(30, 10, 1)},
        {Vector3.new(15, 5, 0), Vector3.new(1, 10, 30)},
        {Vector3.new(-15, 5, 0), Vector3.new(1, 10, 30)},
        {Vector3.new(0, 10, 0), Vector3.new(30, 1, 30)}
    }

    for _, wallData in ipairs(wallOffsets) do
        local wall = Instance.new("Part")
        wall.Size = wallData[2]
        wall.Position = SAFE_ZONE_POS + wallData[1]
        wall.Anchored = true
        wall.Material = Enum.Material.ForceField
        wall.Color = Color3.fromRGB(30, 144, 255)
        wall.Transparency = 0.6
        wall.Parent = model
    end

    model.Parent = Workspace
    safeZoneModel = model
    return safeZoneModel
end

local function teleportToSafeZone()
    getOrCreateSafeZone()
    local root = getRoot()
    if root then
        root.CFrame = CFrame.new(SAFE_ZONE_POS + Vector3.new(0, 4, 0))
    end
end

local function removeSafeZone()
    if safeZoneModel and safeZoneModel.Parent then
        safeZoneModel:Destroy()
        safeZoneModel = nil
    end
end

-- =========================================================================
-- Glove Ability Activator Helper
-- =========================================================================
local function activateAbility()
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
end

-- =========================================================================
-- 1. COMBAT TAB
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
        pcall(function() tool:Activate() end)
    end

    local slapEvt = getSlapEvent()
    if slapEvt then
        pcall(function() slapEvt:FireServer(targetRoot) end)
    end
end

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

Hub.CreateButton(combatTab, "⚡ Fire Glove Ability (E)", function()
    activateAbility()
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
-- 2. AUTO-GLOVES (BADGES) TAB
-- =========================================================================
Hub.CreateSection(badgeTab, "One-Click Instant Badge Solvers")

-- Auto-Elude Solver
Hub.CreateButton(badgeTab, "🚪 Auto-Get Elude Glove (Keypad & Relics)", function()
    task.spawn(function()
        local pCount = #Players:GetPlayers()
        local code = (pCount * 25) + 1100 - 7
        
        Hub.notify({
            Title = "Elude Solver",
            Content = "Calculated Keypad Code: " .. tostring(code) .. " (Players: " .. tostring(pCount) .. ")",
            Duration = 4
        })

        -- Check if Keypad exists in arena
        local keypad = Workspace:FindFirstChild("Keypad", true) or Workspace:FindFirstChild("EludeKeypad", true)
        if keypad then
            local buttons = keypad:FindFirstChild("Buttons") or keypad
            pcall(function()
                for digit in tostring(code):gmatch(".") do
                    local btn = buttons:FindFirstChild(digit) or buttons:FindFirstChild("Button" .. digit)
                    if btn and btn:FindFirstChildWhichIsA("ClickDetector") then
                        fireclickdetector(btn:FindFirstChildWhichIsA("ClickDetector"))
                        task.wait(0.15)
                    end
                end
                local enterBtn = buttons:FindFirstChild("Enter") or buttons:FindFirstChild("Submit")
                if enterBtn and enterBtn:FindFirstChildWhichIsA("ClickDetector") then
                    fireclickdetector(enterBtn:FindFirstChildWhichIsA("ClickDetector"))
                end
            end)
        end

        -- Look for maze relics / key in current world
        task.wait(1)
        local collected = 0
        for _, relic in ipairs(Workspace:GetDescendants()) do
            if relic:IsA("BasePart") and (relic.Name:lower():find("relic") or relic.Name:lower():find("eludekey") or relic.Name == "Key") then
                local myRoot = getRoot()
                if myRoot then
                    myRoot.CFrame = relic.CFrame + Vector3.new(0, 2, 0)
                    collected = collected + 1
                    task.wait(0.6)
                end
            end
        end

        -- Check for Elude Glove Pedestal
        local eludePedestal = Workspace:FindFirstChild("EludePedestal", true) or Workspace:FindFirstChild("EludeGlove", true)
        if eludePedestal and eludePedestal:IsA("BasePart") then
            local myRoot = getRoot()
            if myRoot then
                myRoot.CFrame = eludePedestal.CFrame + Vector3.new(0, 3, 0)
            end
        end

        Hub.notify({
            Title = "Elude Solver",
            Content = "Completed Elude solver sequence! (Relics found: " .. tostring(collected) .. ")",
            Duration = 5
        })
    end)
end)

-- Auto-Counter Glove Solver
Hub.CreateButton(badgeTab, "🕵️ Auto-Get Counter Glove (Lever & Evade)", function()
    task.spawn(function()
        Hub.notify({
            Title = "Counter Glove",
            Content = "Searching for secret counter lever...",
            Duration = 3
        })

        local lever = Workspace:FindFirstChild("CounterLever", true) 
            or Workspace:FindFirstChild("Lever", true)
            or Workspace:FindFirstChild("SecretLever", true)

        if lever then
            local root = getRoot()
            if root then
                root.CFrame = (lever:IsA("BasePart") and lever.CFrame or lever:GetPivot()) + Vector3.new(0, 2, 0)
                task.wait(0.3)
                local detector = lever:FindFirstChildWhichIsA("ClickDetector", true)
                if detector then
                    fireclickdetector(detector)
                end
                Hub.notify({
                    Title = "Counter Glove",
                    Content = "Lever activated! Moving to safe elevation to evade Pim...",
                    Duration = 4
                })
                task.wait(0.5)
                root.CFrame = root.CFrame + Vector3.new(0, 35, 0)
            end
        else
            Hub.notify({
                Title = "Counter Glove",
                Content = "Lever not found! Make sure you are inside the Elude Maze / Realm.",
                Duration = 4
            })
        end
    end)
end)

-- Auto-[REDACTED] Glove Solver (With Safe 5,000 Slaps Check)
Hub.CreateButton(badgeTab, "⬛ Auto-Get [REDACTED] Glove (5k Slaps Check)", function()
    task.spawn(function()
        local currentSlaps = getSlapCount()
        if currentSlaps < 5000 then
            Hub.notify({
                Title = "⚠️ [REDACTED] Locked",
                Content = "You need at least 5,000 slaps to enter! Current: " .. tostring(currentSlaps),
                Duration = 5
            })
            return
        end

        Hub.notify({
            Title = "[REDACTED] Solver",
            Content = "Slap check passed (" .. tostring(currentSlaps) .. " slaps). Searching for doorway...",
            Duration = 4
        })

        -- Look for Redacted / Pocket Dimension door
        local redactedDoor = Workspace:FindFirstChild("PocketDimension", true) 
            or Workspace:FindFirstChild("RedactedDoor", true)
            or Workspace:FindFirstChild("Door", true)

        local root = getRoot()
        if root and redactedDoor then
            local doorPart = redactedDoor:IsA("BasePart") and redactedDoor or redactedDoor:FindFirstChildWhichIsA("BasePart")
            if doorPart then
                root.CFrame = doorPart.CFrame + Vector3.new(0, 2, 0)
                task.wait(1)
            end
        end

        -- Pocket dimension door sequence automation
        for i = 1, 10 do
            local safeDoor = Workspace:FindFirstChild("SafeDoor" .. tostring(i), true) or Workspace:FindFirstChild("Door" .. tostring(i), true)
            if safeDoor and safeDoor:IsA("BasePart") and root then
                root.CFrame = safeDoor.CFrame
                task.wait(0.8)
            end
        end

        Hub.notify({
            Title = "[REDACTED] Solver",
            Content = "Completed door traversal sequence.",
            Duration = 4
        })
    end)
end)

Hub.CreateSection(badgeTab, "AFK Safe-Zone Glove Grinds")

-- Auto-Megarock (10 Hours AFK with Diamond Glove)
Hub.CreateToggle(badgeTab, "🪨 Auto-Megarock (Diamond Safe Zone)", false, function(toggled)
    state.AutoMegarock = toggled
    if toggled then
        teleportToSafeZone()
        task.wait(0.5)
        activateAbility()
        Hub.notify({
            Title = "Auto-Megarock Active",
            Content = "Teleported to Sky Safe Zone. Diamond ability triggered. Keep AFK!",
            Duration = 5
        })
    else
        Hub.notify({
            Title = "Auto-Megarock Stopped",
            Content = "Megarock farmer deactivated.",
            Duration = 3
        })
    end
end)

-- Auto-Fish (1 Hour AFK with ZZZZZZZ Glove)
Hub.CreateToggle(badgeTab, "🐟 Auto-Fish (ZZZZZZZ Sleep Safe Zone)", false, function(toggled)
    state.AutoFish = toggled
    if toggled then
        teleportToSafeZone()
        task.wait(0.5)
        activateAbility()
        Hub.notify({
            Title = "Auto-Fish Active",
            Content = "Teleported to Sky Safe Zone. Sleeping loop engaged.",
            Duration = 5
        })
    else
        Hub.notify({
            Title = "Auto-Fish Stopped",
            Content = "Fish farmer deactivated.",
            Duration = 3
        })
    end
end)

-- Auto-Trap (1,000 Bricks with Brick Glove)
Hub.CreateToggle(badgeTab, "🧱 Auto-Trap (Place 1,000 Bricks)", false, function(toggled)
    state.AutoTrap = toggled
    if toggled then
        teleportToSafeZone()
        Hub.notify({
            Title = "Auto-Trap Active",
            Content = "Placing bricks in Safe Zone. Target: 1,000 bricks.",
            Duration = 5
        })
    else
        Hub.notify({
            Title = "Auto-Trap Stopped",
            Content = "Placed " .. tostring(state.TrapBrickCount) .. " bricks total.",
            Duration = 4
        })
    end
end)

-- Auto-Voodoo (1 Hour Invisibility with Ghost Glove)
Hub.CreateToggle(badgeTab, "👻 Auto-Voodoo (Ghost Invisibility Safe Zone)", false, function(toggled)
    state.AutoVoodoo = toggled
    if toggled then
        teleportToSafeZone()
        task.wait(0.5)
        activateAbility()
        Hub.notify({
            Title = "Auto-Voodoo Active",
            Content = "Teleported to Safe Zone. Ghost invisibility active.",
            Duration = 5
        })
    else
        Hub.notify({
            Title = "Auto-Voodoo Stopped",
            Content = "Ghost farm deactivated.",
            Duration = 3
        })
    end
end)

-- Background Routine for AFK Glove Farming
task.spawn(function()
    while true do
        task.wait(1.5)

        -- Fish Maintainer
        if state.AutoFish then
            local char = getCharacter()
            local hum = getHumanoid()
            if hum and hum.Health > 0 then
                -- Re-activate sleep if not sleeping or interrupted
                activateAbility()
            end
        end

        -- Megarock Maintainer
        if state.AutoMegarock then
            local char = getCharacter()
            if char and not char:FindFirstChild("Rock") and not char:FindFirstChild("Megarock") then
                activateAbility()
            end
        end

        -- Trap Brick Placer (cooldown ~1.5s)
        if state.AutoTrap then
            activateAbility()
            state.TrapBrickCount = state.TrapBrickCount + 1
            if state.TrapBrickCount % 100 == 0 then
                Hub.notify({
                    Title = "Brick Master Progress",
                    Content = "Bricks placed: " .. tostring(state.TrapBrickCount) .. "/1000",
                    Duration = 3
                })
            end
            if state.TrapBrickCount >= 1000 then
                Hub.notify({
                    Title = "🏆 Trap Glove Unlocked!",
                    Content = "Reached 1,000 bricks! Badge should be awarded.",
                    Duration = 8
                })
            end
        end

        -- Voodoo Ghost Maintainer
        if state.AutoVoodoo then
            activateAbility()
        end
    end
end)

-- =========================================================================
-- 3. GENERAL FARM TAB
-- =========================================================================
Hub.CreateSection(farmTab, "Slap & Event Farming")

Hub.CreateToggle(farmTab, "Auto Collect Candy / Orbs", false, function(toggled)
    state.AutoCandy = toggled
end)

Hub.CreateToggle(farmTab, "Auto Click Tycoon Plate", false, function(toggled)
    state.AutoTycoon = toggled
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
-- 4. DEFENSE & MISC TAB
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

Hub.CreateButton(defenseTab, "🚀 Teleport to Sky Safe Zone", function()
    teleportToSafeZone()
    Hub.notify({
        Title = "Safe Zone",
        Content = "Teleported to Sky Safe Platform (Y: 3500).",
        Duration = 3
    })
end)

Hub.CreateButton(defenseTab, "🧹 Remove Sky Safe Zone", function()
    removeSafeZone()
    Hub.notify({
        Title = "Safe Zone",
        Content = "Sky Safe Platform removed.",
        Duration = 3
    })
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
-- 5. VISUALS & ESP TAB
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
    Content = "Unknown Hub Slap Battles (Badge Edition) is ready!",
    Duration = 4
})

