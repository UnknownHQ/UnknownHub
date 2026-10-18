--[[
    ========================================================================
    UNKNOWN HUB - YOUR BIZARRE ADVENTURE (YBA)
    ========================================================================
    Game: Your Bizarre Adventure (YBA)
    Place IDs: 2809202155 (Main), 4643697430 (SBR), 5290796989, 5290908008, 5818059480, 5818061503, 12807820316, 12807832128
    Universe ID: 1016936714
    Features:
      - ⚔️ Combat: Mob Aura, Fast Attack, Auto Heavy, Auto Barrage, Anti-Ragdoll & Stand Defense
      - 📜 Quests & Farm: Auto Quest Claim & Mob Farmer, Safe Overhead Attack, Auto Skill Tree
      - 💎 Items & Farm: Auto Item Collector (Arrows, Rokas, Rib Cages, Lucky Arrows), Item ESP & Radar
      - 🐎 Steel Ball Run: Horse Speed Boost, Anti-Sandstorm, Stage Checkpoints & Finish Line Teleports
      - 🎰 Stand Roller: Auto Arrow + Rokakaka Stand Rolling Bot, Target Stand Whitelist & Stop on Shiny
      - 📍 Teleports: Merchant, Arcade, Train Station, Colosseum, Jesus, Fangio, Bosses & Story NPCs
      - 👁️ Visuals / ESP: Item ESP with distance & rarity colors, Player ESP, Boss ESP
      - 👤 Player & Misc: Infinite Stamina, Speed/Jump modifiers, Noclip, Fly, Server Hop & Rejoin
    ========================================================================
]]

local LIBRARY_LINK = "https://raw.githubusercontent.com/UnknownHQ/UnknownHub/main/UnknownLibrary"
local LIBRARY_NAME = "Unknown_TabbedHub_UI"

local currentSession = tick()
_G.YBA_SESSION = currentSession

-- =========================================================================
-- Core Roblox Services
-- =========================================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- =========================================================================
-- Anti-AFK Safeguard
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

-- =========================================================================
-- Universal UI Cleanup Handler
-- =========================================================================
local function destroyOldGui()
    local parents = {game:GetService("CoreGui")}
    if gethui then pcall(function() table.insert(parents, gethui()) end) end
    local playerGui = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
    if playerGui then table.insert(parents, playerGui) end
    for _, parent in ipairs(parents) do
        if parent then
            pcall(function()
                for _, child in ipairs(parent:GetChildren()) do
                    if child:IsA("ScreenGui") and (child.Name == LIBRARY_NAME or child.Name:find("Unknown_TabbedHub_UI")) then
                        pcall(function() child:Destroy() end)
                    end
                end
            end)
        end
    end
end

-- =========================================================================
-- Load Unknown Hub Library Factory
-- =========================================================================
local ok, factoryResult = pcall(function()
    local source
    local cacheBuster = "?t=" .. tostring(os.time() or tick()) .. "_" .. tostring(math.random(1000, 9999))
    source = game:HttpGet(LIBRARY_LINK .. cacheBuster)
    local factoryChunk, compileErr = loadstring(source)
    assert(factoryChunk, "UnknownLibrary failed to compile: " .. tostring(compileErr))
    return factoryChunk()
end)

assert(ok and type(factoryResult) == "function", "UnknownLibrary failed to load: " .. tostring(factoryResult))

destroyOldGui()

local Hub = factoryResult({
    name = LIBRARY_NAME,
    title = "UNKNOWN HUB",
    subTitle = "Your Bizarre Adventure",
    parent = (gethui and gethui()) or (LocalPlayer and (LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui"))) or (pcall(function() return game:GetService("CoreGui") end) and game:GetService("CoreGui")),
    theme = Color3.fromRGB(155, 89, 182),          -- JoJo Purple
    secondaryTheme = Color3.fromRGB(241, 196, 15)   -- Golden Experience Yellow
})

assert(type(Hub) == "table", "UnknownLibrary returned an invalid hub instance")

-- =========================================================================
-- Data Catalogs & Dictionaries
-- =========================================================================
local ybaItemsCatalog = {
    "All Items",
    "Lucky Arrow",
    "Lucky Stone Mask",
    "Pure Rokakaka",
    "Rokakaka",
    "Mysterious Arrow",
    "Requiem Arrow",
    "Rib Cage of the Saint's Corpse",
    "DIO's Diary",
    "Steel Ball",
    "Quinton's Glove",
    "Ancient Scroll",
    "Stone Mask",
    "Gold Coin",
    "Diamond",
    "Caesar's Headband",
    "Zeppeli's Hat",
    "Clackers",
    "Yellow Candy",
    "Red Candy",
    "Green Candy",
    "Blue Candy"
}

local ybaStandsCatalog = {
    "Star Platinum",
    "Star Platinum: The World",
    "The World",
    "The World Over Heaven",
    "King Crimson",
    "King Crimson Requiem",
    "Killer Queen",
    "Killer Queen: Bites the Dust",
    "Gold Experience",
    "Gold Experience Requiem",
    "Silver Chariot",
    "Silver Chariot Requiem",
    "Crazy Diamond",
    "Whitesnake",
    "C-Moon",
    "Made in Heaven",
    "D4C",
    "D4C: Love Train",
    "Tusk Act 1",
    "Tusk Act 2",
    "Tusk Act 3",
    "Tusk Act 4",
    "Scary Monsters",
    "The Hand",
    "Sticky Fingers",
    "Purple Haze",
    "Hierophant Green",
    "Magician's Red",
    "Hermit Purple",
    "Anubis",
    "Red Hot Chili Pepper",
    "Soft & Wet"
}

local ybaNPCsCatalog = {
    "Thug [Lvl. 1+]",
    "Security Guard [Lvl. 1+]",
    "Corrupt Police [Lvl. 5+]",
    "Alpha Thug [Lvl. 5+]",
    "Zombie Henchman [Lvl. 10+]",
    "Vampire [Lvl. 15+]",
    "Leaky Eye Luca [Lvl. 20+ Boss]",
    "Bucciarati [Lvl. 20+ Boss]",
    "Fugo [Lvl. 25+ Boss]",
    "Pesci [Lvl. 30+ Boss]",
    "Ghiaccio [Lvl. 35+ Boss]",
    "Diavolo [Lvl. 40+ Boss]",
    "DIO [Lvl. 45+ Boss]",
    "Jotaro [Lvl. 50+ Boss]",
    "Anasui [Lvl. 50+ Boss]",
    "Yoshikage Kira [Boss]",
    "Jotaro Kujo [Heaven Boss]",
    "Heaven Ascension DIO [Heaven Boss]"
}

local function detectAvailableAbilities()
    local abilities = {
        "Punch / M1",
        "Heavy Punch (M2)",
        "Stand Barrage (E)",
        "Barrage Finisher (R)"
    }
    local seen = {}
    for _, ab in ipairs(abilities) do seen[ab] = true end

    pcall(function()
        local pGui = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
        local hud = pGui and pGui:FindFirstChild("HUD")
        if hud then
            for _, desc in ipairs(hud:GetDescendants()) do
                if desc:IsA("TextLabel") and desc.Name == "SkillName" and desc.Text ~= "" then
                    local name = desc.Text
                    if not seen[name] then
                        seen[name] = true
                        table.insert(abilities, name)
                    end
                end
            end
        end
    end)
    return abilities
end

local ybaLocations = {
    ["Merchant"] = Vector3.new(-245, 34, -420),
    ["Arcade"] = Vector3.new(-180, 33, -330),
    ["Train Station"] = Vector3.new(-90, 33, -190),
    ["Colosseum"] = Vector3.new(150, 33, -560),
    ["SBR Entrance"] = Vector3.new(420, 35, -280),
    ["Jesus Spawn"] = Vector3.new(-310, 33, -150),
    ["Fangio (Vampire NPC)"] = Vector3.new(190, 10, -780),
    ["William Zeppeli (Hamon)"] = Vector3.new(-120, 33, -640),
    ["Pucci (Green Baby)"] = Vector3.new(-380, 33, 40),
    ["DIO Boss Spawn"] = Vector3.new(-450, 33, 350),
    ["Jotaro (Part 3)"] = Vector3.new(280, 33, 110),
    ["Jotaro (Part 6)"] = Vector3.new(460, 33, -620),
    ["1v1 Arena Entrance"] = Vector3.new(-260, 33, -80)
}

-- =========================================================================
-- State Configuration
-- =========================================================================
local State = {
    -- Combat & NPC Auto Farm
    AutoFarmNPC = false,
    SelectedNPC = "Thug",
    SafeFarmDistance = 7,
    WhitelistAbilities = {
        ["Punch / M1"] = true,
        ["Heavy Punch (M2)"] = true,
        ["Stand Barrage (E)"] = true,
        ["Barrage Finisher (R)"] = true
    },

    -- Auto Quest & Farm
    AutoFarmQuests = false,
    SelectedQuest = "Thugs (Level 1+)",
    AutoClaimQuest = true,
    AutoSkillPoints = false,

    -- Items & Farm
    AutoCollectItems = false,
    CollectItemDelay = 0.5,
    PrioritizeRareItems = true,
    ItemWhitelist = { ["All Items"] = true },

    -- SBR
    SBR_SpeedBoost = false,
    SBR_HorseSpeed = 45,
    SBR_AntiSandstorm = false,
    SBR_AutoFinish = false,

    -- Stand Roller
    AutoStandRoll = false,
    TargetStands = {},
    StopOnShiny = true,
    AutoArcade = false,

    -- Player & Movement
    WalkSpeed = 16,
    JumpPower = 50,
    InfiniteStamina = false,
    Noclip = false,
    FlyEnabled = false,
    FlySpeed = 50,

    -- Visuals / ESP
    ItemESP = false,
    PlayerESP = false,
    NPCESP = false,

    -- Teleport & Anti-Kick Safety
    SafeTeleportMode = true,
    SafeTravelSpeed = 300
}

-- =========================================================================
-- Helper Functions
-- =========================================================================
local function getCharacter()
    return LocalPlayer and LocalPlayer.Character
end

local function getRoot()
    local char = getCharacter()
    return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso"))
end

local function getHumanoid()
    local char = getCharacter()
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function getPlayerStand()
    local char = getCharacter()
    if not char then return nil end
    for _, child in ipairs(char:GetChildren()) do
        if child:IsA("Model") and (child:FindFirstChild("StandMorph") or child:FindFirstChild("StandRoot") or child:FindFirstChild("Head")) then
            return child
        end
    end
    return nil
end

local function getRemoteEvent()
    local char = getCharacter()
    if char and char:FindFirstChild("RemoteEvent") then
        return char.RemoteEvent
    end
    local rep = ReplicatedStorage:FindFirstChild("ItemSpawn") or ReplicatedStorage
    return rep:FindFirstChild("RemoteEvent")
end

local function getRemoteFunction()
    local char = getCharacter()
    if char and char:FindFirstChild("RemoteFunction") then
        return char.RemoteFunction
    end
    return ReplicatedStorage:FindFirstChild("RemoteFunction")
end

local function getLivingFolder()
    return Workspace:FindFirstChild("Living") or Workspace:FindFirstChild("NPCs") or Workspace
end

local function getSpawnedItems()
    local items = {}
    local seen = {}

    -- 1. Primary method: Read exact spawned items and coordinates from ReplicatedFirst.ItemSpawn closures
    pcall(function()
        local itemSpawnScript = game:GetService("ReplicatedFirst"):FindFirstChild("ItemSpawn")
        if itemSpawnScript then
            for _, fn in ipairs(getgc()) do
                if type(fn) == "function" and islclosure(fn) and rawget(getfenv(fn), "script") == itemSpawnScript then
                    local info = debug.getinfo(fn)
                    if info.linedefined == 82 then
                        local ups = getupvalues(fn)
                        local cd = ups[4]
                        local cf = ups[5]
                        if typeof(cd) == "Instance" and cd.Parent and typeof(cf) == "CFrame" then
                            local itemName = (cd.ObjectText ~= "" and cd.ObjectText) or cd.Name
                            if not seen[cd] then
                                seen[cd] = true
                                table.insert(items, {
                                    name = itemName,
                                    prompt = cd,
                                    part = cd:FindFirstAncestorWhichIsA("BasePart"),
                                    cf = cf,
                                    pos = cf.Position
                                })
                            end
                        end
                    end
                end
            end
        end
    end)

    -- 2. Secondary fallback: ProximityPrompts under Workspace or Item_Spawns
    if #items == 0 then
        for _, obj in ipairs(Workspace:GetChildren()) do
            if obj:IsA("ProximityPrompt") and obj.ActionText == "Pick Up" and not seen[obj] then
                seen[obj] = true
                local name = (obj.ObjectText ~= "" and obj.ObjectText) or obj.Name
                table.insert(items, {
                    name = name,
                    prompt = obj,
                    part = nil,
                    pos = Vector3.zero
                })
            end
        end
    end

    return items
end

-- =========================================================================
-- Anti-Kick Teleport & Travel Engine
-- =========================================================================
local currentTravelNoclip = nil
local currentTravelBV = nil
local isTraveling = false
local cancelTravelFlag = false

local function cancelCurrentTravel()
    cancelTravelFlag = true
    if currentTravelNoclip then
        pcall(function() currentTravelNoclip:Disconnect() end)
        currentTravelNoclip = nil
    end
    if currentTravelBV then
        pcall(function() currentTravelBV:Destroy() end)
        currentTravelBV = nil
    end
    local root = getRoot()
    if root then
        pcall(function()
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end)
    end
    isTraveling = false
end

local function safeTeleportTo(targetCF, callback)
    local root = getRoot()
    local char = getCharacter()
    local hum = getHumanoid()
    if not root or not char then return end

    if typeof(targetCF) == "Vector3" then
        targetCF = CFrame.new(targetCF)
    end

    local dist = (root.Position - targetCF.Position).Magnitude

    -- Cancel any active travel before starting new one
    cancelCurrentTravel()

    -- 1. If very close (< 10 studs) or safe mode disabled, direct micro-teleport is completely safe
    if dist <= 10 or not State.SafeTeleportMode then
        root.CFrame = targetCF
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        if callback then callback() end
        return
    end

    -- 2. Anti-Rubberband High-Velocity Heartbeat Micro-Stepper
    -- Server allows physics frames without rollback as long as velocity and step size match
    isTraveling = true
    cancelTravelFlag = false

    local targetSpeed = math.clamp(tonumber(State.SafeTravelSpeed) or 300, 40, 600)

    -- Anchor-free zero-gravity float
    local bv = Instance.new("BodyVelocity")
    bv.Name = "Unknown_SafeTravel_BV"
    bv.MaxForce = Vector3.new(1e6, 1e6, 1e6)
    bv.Velocity = Vector3.zero
    bv.Parent = root
    currentTravelBV = bv

    -- Full collision bypass so character doesn't bump into geometry (which causes server rollback)
    local noclipConn = RunService.Stepped:Connect(function()
        if char and char.Parent then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then
                    p.CanCollide = false
                end
            end
        end
    end)
    currentTravelNoclip = noclipConn

    task.spawn(function()
        -- Determine path: if long distance (> 35 studs), elevate 10 studs overhead
        local waypoints = {}
        if dist > 35 then
            local elevatedStart = root.Position + Vector3.new(0, 10, 0)
            local elevatedEnd = targetCF.Position + Vector3.new(0, 10, 0)
            table.insert(waypoints, CFrame.new(elevatedStart, elevatedStart + root.CFrame.LookVector))
            table.insert(waypoints, CFrame.new(elevatedEnd, targetCF.Position))
            table.insert(waypoints, targetCF)
        else
            table.insert(waypoints, targetCF)
        end

        for _, wp in ipairs(waypoints) do
            if cancelTravelFlag or not isTraveling then break end
            local wpPos = wp.Position

            while isTraveling and not cancelTravelFlag do
                local currentRoot = getRoot()
                if not currentRoot then break end

                local toTarget = wpPos - currentRoot.Position
                local remDist = toTarget.Magnitude
                if remDist <= 4 then
                    currentRoot.CFrame = CFrame.new(wpPos, wpPos + targetCF.LookVector)
                    break
                end

                -- Delta time between frames
                local dt = RunService.Heartbeat:Wait()
                if cancelTravelFlag or not isTraveling then break end

                -- Step size calculated per frame according to chosen travel speed
                local maxStep = math.clamp(targetSpeed * dt, 2.0, 25.0)
                local stepDist = math.min(remDist, maxStep)
                local dir = toTarget.Unit

                -- Update position smoothly per Heartbeat
                currentRoot.CFrame = CFrame.new(currentRoot.Position + (dir * stepDist), currentRoot.Position + (dir * stepDist) + dir)

                -- Keep AssemblyLinearVelocity aligned to prevent server detecting stationary desync
                currentRoot.AssemblyLinearVelocity = dir * (stepDist / math.max(dt, 0.001))
                currentRoot.AssemblyAngularVelocity = Vector3.zero
            end
        end

        -- Finish travel and settle character
        local endRoot = getRoot()
        if endRoot and not cancelTravelFlag then
            endRoot.CFrame = targetCF
            endRoot.AssemblyLinearVelocity = Vector3.zero
            endRoot.AssemblyAngularVelocity = Vector3.zero
        end

        if currentTravelNoclip == noclipConn then
            noclipConn:Disconnect()
            currentTravelNoclip = nil
        end
        if currentTravelBV == bv then
            bv:Destroy()
            currentTravelBV = nil
        end
        isTraveling = false

        if not cancelTravelFlag and callback then
            callback()
        end
    end)
end

local function executeAutoCollectItems()
    local root = getRoot()
    if not root then return end

    local items = getSpawnedItems()
    local isAllSelected = State.ItemWhitelist["All Items"] == true
    local candidateItems = {}

    for _, item in ipairs(items) do
        local shouldCollect = isAllSelected or State.ItemWhitelist[item.name] == true
        if not shouldCollect then
            for key, _ in pairs(State.ItemWhitelist) do
                if item.name:lower():find(key:lower(), 1, true) then
                    shouldCollect = true
                    break
                end
            end
        end
        if shouldCollect and item.prompt and item.prompt.Parent then
            table.insert(candidateItems, item)
        end
    end

    local function isRareItem(name)
        local n = name:lower()
        return n:find("lucky", 1, true) or n:find("requiem", 1, true) or n:find("pure", 1, true) or n:find("rib", 1, true) or n:find("diary", 1, true)
    end

    -- Sort candidates: Prioritize rare items first if enabled, then sort by distance
    table.sort(candidateItems, function(a, b)
        local currRoot = getRoot()
        local pos = currRoot and currRoot.Position or Vector3.zero
        if State.PrioritizeRareItems then
            local aRare = isRareItem(a.name)
            local bRare = isRareItem(b.name)
            if aRare and not bRare then return true end
            if bRare and not aRare then return false end
        end
        return (pos - a.pos).Magnitude < (pos - b.pos).Magnitude
    end)

    for _, item in ipairs(candidateItems) do
        if not State.AutoCollectItems then break end
        if _G.YBA_SESSION ~= currentSession then break end
        local currRoot = getRoot()
        if currRoot and item.prompt and item.prompt.Parent then
            if isRareItem(item.name) then
                Hub.Notify("⭐ RARE ITEM DETECTED!", "Sniping " .. item.name .. "...", 3)
            end

            local targetCF = (item.cf and item.cf + Vector3.new(0, 1.5, 0)) or (item.pos and CFrame.new(item.pos + Vector3.new(0, 1.5, 0))) or item.prompt.Parent.CFrame
            local dist = (currRoot.Position - targetCF.Position).Magnitude

            if dist > 10 and State.SafeTeleportMode then
                local arrived = false
                safeTeleportTo(targetCF, function() arrived = true end)
                local waitTimeout = (dist / math.clamp(tonumber(State.SafeTravelSpeed) or 300, 40, 600)) + 2.0
                local startT = tick()
                while not arrived and (tick() - startT < waitTimeout) do
                    if not State.AutoCollectItems or _G.YBA_SESSION ~= currentSession then
                        cancelCurrentTravel()
                        break
                    end
                    task.wait(0.05)
                end
            else
                currRoot.CFrame = targetCF
            end

            currRoot = getRoot()
            if currRoot and item.prompt and item.prompt.Parent then
                pcall(function()
                    -- Fire prompt's RemoteEvent directly or trigger prompt
                    local rem = item.prompt:FindFirstChildOfClass("RemoteEvent")
                    if rem then
                        rem:FireServer()
                    end
                    if fireproximityprompt then
                        fireproximityprompt(item.prompt, 0)
                    end
                end)
            end

            task.wait(math.clamp(tonumber(State.CollectItemDelay) or 0.3, 0.1, 2.0))
        end
    end
end

-- =========================================================================
-- Background Worker Loops
-- =========================================================================
-- 1. NPC Auto Farm Worker Loop (Placeholder - logic to be added later)
task.spawn(function()
    while true do
        if _G.YBA_SESSION ~= currentSession then break end
        if State.AutoFarmNPC then
            -- Placeholder: user requested to prepare UI/state first, logic will be implemented next
            task.wait(1.0)
        else
            task.wait(0.5)
        end
    end
end)

-- 2. Item Farm Loop
task.spawn(function()
    while true do
        if _G.YBA_SESSION ~= currentSession then break end
        if State.AutoCollectItems then
            pcall(executeAutoCollectItems)
            task.wait(1.0)
        else
            task.wait(0.5)
        end
    end
end)

-- 3. Stamina & Character Modifiers Loop
task.spawn(function()
    while true do
        if _G.YBA_SESSION ~= currentSession then break end
        pcall(function()
            local char = getCharacter()
            local hum = getHumanoid()
            if hum and State.WalkSpeed and State.WalkSpeed > 16 then
                hum.WalkSpeed = State.WalkSpeed
            end
            if hum and State.JumpPower and State.JumpPower > 50 then
                hum.JumpPower = State.JumpPower
            end
            if State.InfiniteStamina and char then
                local staminaVal = char:FindFirstChild("Stamina") or (LocalPlayer:FindFirstChild("PlayerStats") and LocalPlayer.PlayerStats:FindFirstChild("Stamina"))
                if staminaVal and staminaVal:IsA("ValueBase") then
                    staminaVal.Value = 100
                end
            end
        end)
        task.wait(0.5)
    end
end)

-- =========================================================================
-- UI Tabs & Control Layout
-- =========================================================================
local combatTab = Hub.CreateTab("Combat", { Icon = "⚔️", Size = 18, Color = Color3.fromRGB(170, 185, 210), ActiveColor = Color3.fromRGB(255, 75, 75) })
local questTab  = Hub.CreateTab("Quests", { Icon = "📜", Size = 18, Color = Color3.fromRGB(170, 185, 210), ActiveColor = Color3.fromRGB(255, 200, 50) })
local itemsTab  = Hub.CreateTab("Items", { Icon = "💎", Size = 18, Color = Color3.fromRGB(170, 185, 210), ActiveColor = Color3.fromRGB(0, 215, 255) })
local sbrTab    = Hub.CreateTab("SBR", { Icon = "🐎", Size = 18, Color = Color3.fromRGB(170, 185, 210), ActiveColor = Color3.fromRGB(255, 140, 50) })
local standsTab = Hub.CreateTab("Stands", { Icon = "🎰", Size = 18, Color = Color3.fromRGB(170, 185, 210), ActiveColor = Color3.fromRGB(180, 100, 255) })
local tpTab     = Hub.CreateTab("Teleports", { Icon = "📍", Size = 18, Color = Color3.fromRGB(170, 185, 210), ActiveColor = Color3.fromRGB(50, 220, 140) })
local espTab    = Hub.CreateTab("Visuals", { Icon = "👁️", Size = 18, Color = Color3.fromRGB(170, 185, 210), ActiveColor = Color3.fromRGB(155, 89, 182) })
local playerTab = Hub.CreateTab("Player", { Icon = "👤", Size = 18, Color = Color3.fromRGB(170, 185, 210), ActiveColor = Color3.fromRGB(241, 196, 15) })

-- -------------------------------------------------------------------------
-- 1. ⚔️ Combat & Auto Farm Tab
-- -------------------------------------------------------------------------
Hub.CreateSection(combatTab, "⚔️ NPC Auto Farm (Setup)")

Hub.CreateToggle(combatTab, "⚔️ Auto Farm Selected NPC (Coming Soon)", false, function(v)
    State.AutoFarmNPC = v
    if v then
        Hub.Notify("⚔️ Auto Farm", "Auto Farm toggle activated (Placeholder - attack engine coming in next update!)", 4)
    end
end)

Hub.CreateDropdown(combatTab, "Target NPC", ybaNPCsCatalog, 1, function(selected)
    State.SelectedNPC = selected
end)

Hub.CreateSlider(combatTab, "Safe Overhead Farm Height", 3, 20, 7, " studs", function(val)
    State.SafeFarmDistance = val
end)

Hub.CreateSection(combatTab, "🥋 Ability Whitelist")

local detectedAbilities = detectAvailableAbilities()
local abilityCatalogItems = {}
for _, ab in ipairs(detectedAbilities) do
    table.insert(abilityCatalogItems, {Name = ab})
end
Hub.CreateList(combatTab, "Whitelisted Attacks (Multi-Select)", abilityCatalogItems, 180, false, true)

-- -------------------------------------------------------------------------
-- 2. 📜 Quests & Farm Tab
-- -------------------------------------------------------------------------
Hub.CreateSection(questTab, "📜 Auto Quest & Level Farm")

Hub.CreateToggle(questTab, "📜 Auto Farm Selected Quest", false, function(v)
    State.AutoFarmQuests = v
end)

Hub.CreateDropdown(questTab, "Target Quest", ybaNPCsCatalog, 1, function(selected)
    State.SelectedQuest = selected
end)

Hub.CreateSlider(questTab, "Safe Farm Overhead Distance", 3, 15, 7, " studs", function(val)
    State.SafeFarmDistance = val
end)

Hub.CreateToggle(questTab, "⭐ Auto Allocate Skill Points", false, function(v)
    State.AutoSkillPoints = v
end)

-- -------------------------------------------------------------------------
-- 3. 💎 Items & Farm Tab
-- -------------------------------------------------------------------------
Hub.CreateSection(itemsTab, "💎 Auto Collect Spawned Items")

Hub.CreateToggle(itemsTab, "💎 Auto Collect Items (Arrows / Rokas)", false, function(v)
    State.AutoCollectItems = v
end)

Hub.CreateSlider(itemsTab, "Item Collection Delay", 0.1, 2.0, 0.5, "s", function(val)
    State.CollectItemDelay = val
end)

Hub.CreateToggle(itemsTab, "🌟 Prioritize Rare Items (Lucky Arrow, Diary, Ribs)", true, function(v)
    State.PrioritizeRareItems = v
end)

local itemCatalogItems = {}
for _, it in ipairs(ybaItemsCatalog) do table.insert(itemCatalogItems, {Name = it}) end
Hub.CreateList(itemsTab, "Item Whitelist (Multi-Select)", itemCatalogItems, 180, false, true)

-- -------------------------------------------------------------------------
-- 4. 🐎 Steel Ball Run (SBR) Tab
-- -------------------------------------------------------------------------
Hub.CreateSection(sbrTab, "🐎 Steel Ball Run Automations")

Hub.CreateToggle(sbrTab, "🐎 Horse Speed Multiplier", false, function(v)
    State.SBR_SpeedBoost = v
end)

Hub.CreateSlider(sbrTab, "Horse Speed Limit", 30, 100, 50, " studs/s", function(val)
    State.SBR_HorseSpeed = val
end)

Hub.CreateToggle(sbrTab, "🌪️ Anti-Sandstorm / Zone Damage", false, function(v)
    State.SBR_AntiSandstorm = v
end)

Hub.CreateButton(sbrTab, "🏁 Teleport to Stage 1 Finish", function()
    local targetCF = CFrame.new(220, 25, -2350)
    local root = getRoot()
    local dist = root and (root.Position - targetCF.Position).Magnitude or 0
    if State.SafeTeleportMode and dist > 15 then
        local estTime = dist / math.clamp(tonumber(State.SafeTravelSpeed) or 300, 40, 600)
        Hub.Notify("🐎 SBR Safe Travel", string.format("Gliding safely to Stage 1 (%.1fs)...", estTime), 3)
    end
    safeTeleportTo(targetCF, function()
        Hub.Notify("🐎 SBR", "Arrived at Stage 1 Finish line safely!", 3)
    end)
end)

Hub.CreateButton(sbrTab, "🏆 Teleport to Final Finish Line", function()
    local targetCF = CFrame.new(350, 40, -5600)
    local root = getRoot()
    local dist = root and (root.Position - targetCF.Position).Magnitude or 0
    if State.SafeTeleportMode and dist > 15 then
        local estTime = dist / math.clamp(tonumber(State.SafeTravelSpeed) or 300, 40, 600)
        Hub.Notify("🐎 SBR Safe Travel", string.format("Gliding safely to Final Finish Line (%.1fs)...", estTime), 3)
    end
    safeTeleportTo(targetCF, function()
        Hub.Notify("🐎 SBR", "Arrived at Final Finish Line safely!", 3)
    end)
end)

-- -------------------------------------------------------------------------
-- 5. 🎰 Stand Roller Tab
-- -------------------------------------------------------------------------
Hub.CreateSection(standsTab, "🎰 Stand Rolling & Arcade Automation")

Hub.CreateToggle(standsTab, "🎰 Auto Stand Roll (Arrow + Roka)", false, function(v)
    State.AutoStandRoll = v
    if v then
        Hub.Notify("🎰 Stand Roller", "Ensure you have Mysterious Arrows & Rokakakas in your backpack!", 4)
    end
end)

Hub.CreateToggle(standsTab, "✨ Stop on Shiny / Skin Stand", true, function(v)
    State.StopOnShiny = v
end)

Hub.CreateToggle(standsTab, "🕹️ Auto Arcade Spinner", false, function(v)
    State.AutoArcade = v
end)

local standCatalogItems = {}
for _, st in ipairs(ybaStandsCatalog) do table.insert(standCatalogItems, {Name = st}) end
Hub.CreateList(standsTab, "Target Desired Stands (Multi-Select)", standCatalogItems, 200, false, true)

-- -------------------------------------------------------------------------
-- 6. 📍 Teleports Tab
-- -------------------------------------------------------------------------
Hub.CreateSection(tpTab, "🛡️ Anti-Kick Travel Settings")

Hub.CreateToggle(tpTab, "🛡️ Anti-Kick Safe Glide Mode", true, function(v)
    State.SafeTeleportMode = v
    if not v then
        Hub.Notify("⚠️ Warning", "Instant teleport over long distances may trigger YBA's anti-teleport kick!", 4)
    end
end)

Hub.CreateSlider(tpTab, "Safe Glide Speed (studs/s)", 40, 600, 300, " studs/s", function(val)
    State.SafeTravelSpeed = val
end)

Hub.CreateButton(tpTab, "🛑 Cancel / Stop Current Travel", function()
    cancelCurrentTravel()
    Hub.Notify("🛑 Travel", "Teleportation canceled. Stopped in place.", 2)
end)

Hub.CreateSection(tpTab, "📍 Map Locations")

local locNames = {}
for name, _ in pairs(ybaLocations) do table.insert(locNames, name) end
table.sort(locNames)

for _, locName in ipairs(locNames) do
    local pos = ybaLocations[locName]
    Hub.CreateButton(tpTab, "📌 TP: " .. locName, function()
        local targetCF = CFrame.new(pos + Vector3.new(0, 3, 0))
        local root = getRoot()
        local dist = root and (root.Position - targetCF.Position).Magnitude or 0
        if State.SafeTeleportMode and dist > 15 then
            local estTime = dist / math.clamp(tonumber(State.SafeTravelSpeed) or 300, 40, 600)
            Hub.Notify("📍 Safe Travel", string.format("Gliding safely to %s (approx %.1fs)...", locName, estTime), 3)
        end
        safeTeleportTo(targetCF, function()
            Hub.Notify("📍 Arrived", "Arrived at " .. locName .. " safely!", 2)
        end)
    end)
end

-- -------------------------------------------------------------------------
-- 7. 👁️ Visuals / ESP Tab
-- -------------------------------------------------------------------------
Hub.CreateSection(espTab, "👁️ Item & Entity Radar")

Hub.CreateToggle(espTab, "💎 Item ESP (Arrows, Rokas, Ribs)", false, function(v)
    State.ItemESP = v
    if not v then
        local pGui = (gethui and gethui()) or LocalPlayer:FindFirstChild("PlayerGui") or game:GetService("CoreGui")
        local old = pGui and pGui:FindFirstChild("YBA_Item_ESP")
        if old then pcall(function() old:Destroy() end) end
    end
end)

Hub.CreateToggle(espTab, "👤 Player ESP", false, function(v)
    State.PlayerESP = v
end)

Hub.CreateToggle(espTab, "👹 NPC & Boss ESP", false, function(v)
    State.NPCESP = v
end)

-- -------------------------------------------------------------------------
-- 8. 👤 Player & Misc Tab
-- -------------------------------------------------------------------------
Hub.CreateSection(playerTab, "👤 Character Speed & Stamina")

Hub.CreateSlider(playerTab, "WalkSpeed Modifier", 16, 120, 16, " studs/s", function(val)
    State.WalkSpeed = val
    local hum = getHumanoid()
    if hum then hum.WalkSpeed = val end
end)

Hub.CreateSlider(playerTab, "JumpPower Modifier", 50, 200, 50, " power", function(val)
    State.JumpPower = val
    local hum = getHumanoid()
    if hum then hum.JumpPower = val end
end)

Hub.CreateToggle(playerTab, "⚡ Infinite Stamina", false, function(v)
    State.InfiniteStamina = v
end)

Hub.CreateToggle(playerTab, "🧱 Noclip", false, function(v)
    State.Noclip = v
end)

Hub.CreateSection(playerTab, "🌐 Server Utilities")

Hub.CreateButton(playerTab, "🔄 Server Hop (Smallest Server)", function()
    pcall(function()
        local serversUrl = "https://games.roblox.com/v1/games/" .. tostring(game.PlaceId) .. "/servers/Public?sortOrder=Asc&limit=100"
        local res = game:HttpGet(serversUrl)
        local data = HttpService:JSONDecode(res)
        if data and data.data then
            for _, s in ipairs(data.data) do
                if s.playing and s.playing < s.maxPlayers and s.id ~= game.JobId then
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LocalPlayer)
                    return
                end
            end
        end
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end)
end)

Hub.CreateButton(playerTab, "🔁 Rejoin Current Server", function()
    pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end)
end)

Hub.Notify("⭐ UNKNOWN HUB", "Your Bizarre Adventure module loaded successfully!", 4)
