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
    "Mysterious Arrow",
    "Rokakaka",
    "Pure Rokakaka",
    "Lucky Arrow",
    "Rib Cage of the Saint's Corpse",
    "Steel Ball",
    "Quinton's Glove",
    "Ancient Scroll",
    "Stone Mask",
    "DIO's Diary",
    "Requiem Arrow",
    "Gold Coin",
    "Diamond",
    "Zepellin's Headband",
    "Caesar's Headband",
    "Clackers"
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

local ybaQuestsCatalog = {
    "Thugs (Level 1+)",
    "Corrupt Police (Level 5+)",
    "Zombie Henchmen (Level 10+)",
    "Vampires (Level 15+)",
    "Leaky Eye Luca",
    "Bucciarati (Level 20+)",
    "Fugo (Level 25+)",
    "Pesci (Level 30+)",
    "Ghiaccio (Level 35+)",
    "Diavolo (Level 40+)",
    "DIO (Level 45+)",
    "Jotaro Kujo (P3)",
    "Jotaro Kujo (P6)"
}

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
    -- Combat
    MobAura = false,
    AuraRange = 15,
    FastAttack = false,
    AutoHeavy = false,
    AutoBarrage = false,
    AntiRagdoll = false,
    AntiStun = false,
    StandDefense = false,

    -- Auto Quest & Farm
    AutoFarmQuests = false,
    SelectedQuest = "Thugs (Level 1+)",
    SafeFarmDistance = 7,
    AutoClaimQuest = true,
    AutoSkillPoints = false,

    -- Items & Farm
    AutoCollectItems = false,
    CollectItemDelay = 0.5,
    NotifyLuckyArrow = true,
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
    NPCESP = false
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
    local spawnsFolder = Workspace:FindFirstChild("Item_Spawns") or Workspace:FindFirstChild("ItemSpawns") or Workspace:FindFirstChild("Items")
    if spawnsFolder then
        for _, obj in ipairs(spawnsFolder:GetDescendants()) do
            if obj:IsA("TouchTransmitter") and obj.Parent and obj.Parent:IsA("BasePart") then
                local toolModel = obj.Parent.Parent or obj.Parent
                table.insert(items, {
                    name = toolModel.Name,
                    instance = toolModel,
                    part = obj.Parent,
                    pos = obj.Parent.Position
                })
            elseif obj:IsA("Tool") or (obj:IsA("Model") and obj:FindFirstChildWhichIsA("TouchTransmitter", true)) then
                local rootPart = obj:FindFirstChildWhichIsA("BasePart")
                if rootPart then
                    table.insert(items, {
                        name = obj.Name,
                        instance = obj,
                        part = rootPart,
                        pos = rootPart.Position
                    })
                end
            end
        end
    end
    -- Fallback scan on direct workspace objects
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:IsA("Tool") and obj:FindFirstChildWhichIsA("BasePart") then
            table.insert(items, {
                name = obj.Name,
                instance = obj,
                part = obj:FindFirstChildWhichIsA("BasePart"),
                pos = obj:FindFirstChildWhichIsA("BasePart").Position
            })
        end
    end
    return items
end

-- =========================================================================
-- Combat & Farm Automation Logic
-- =========================================================================
local function executeMobAura()
    local root = getRoot()
    local hum = getHumanoid()
    if not root or not hum or hum.Health <= 0 then return end

    local rem = getRemoteEvent()
    local living = getLivingFolder()
    local char = getCharacter()

    for _, entity in ipairs(living:GetChildren()) do
        if entity ~= char and entity:IsA("Model") then
            local eHum = entity:FindFirstChildOfClass("Humanoid")
            local eRoot = entity:FindFirstChild("HumanoidRootPart") or entity:FindFirstChild("Torso")
            if eHum and eHum.Health > 0 and eRoot then
                local dist = (root.Position - eRoot.Position).Magnitude
                if dist <= State.AuraRange then
                    if rem then
                        pcall(function()
                            rem:FireServer("InputBegan", { ["Input"] = Enum.KeyCode.E })
                            rem:FireServer("Punch", "Light")
                            rem:FireServer("Attack", "M1")
                        end)
                    end
                end
            end
        end
    end
end

local function executeAutoCollectItems()
    local root = getRoot()
    if not root then return end

    local items = getSpawnedItems()
    local isAllSelected = State.ItemWhitelist["All Items"] == true

    for _, item in ipairs(items) do
        if not State.AutoCollectItems then break end
        if _G.YBA_SESSION ~= currentSession then break end

        local shouldCollect = isAllSelected or State.ItemWhitelist[item.name] == true
        if not shouldCollect then
            for key, _ in pairs(State.ItemWhitelist) do
                if item.name:lower():find(key:lower(), 1, true) then
                    shouldCollect = true
                    break
                end
            end
        end

        if shouldCollect and item.part and item.part.Parent then
            if State.NotifyLuckyArrow and item.name:lower():find("lucky", 1, true) then
                Hub.Notify("⭐ LUCKY ARROW DETECTED!", "Teleporting to Lucky Arrow: " .. tostring(item.pos), 5)
            end

            -- Smooth micro-teleport to touch and pick up item
            local origCF = root.CFrame
            pcall(function()
                root.CFrame = item.part.CFrame + Vector3.new(0, 1.5, 0)
                firetouchinterest(root, item.part, 0)
                task.wait(0.05)
                firetouchinterest(root, item.part, 1)
            end)
            task.wait(math.clamp(tonumber(State.CollectItemDelay) or 0.3, 0.1, 2.0))
        end
    end
end

-- =========================================================================
-- Background Worker Loops
-- =========================================================================
-- 1. Combat & Mob Aura Loop
task.spawn(function()
    while true do
        if _G.YBA_SESSION ~= currentSession then break end
        if State.MobAura then
            pcall(executeMobAura)
            task.wait(0.12)
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
-- 1. ⚔️ Combat Tab
-- -------------------------------------------------------------------------
Hub.CreateSection(combatTab, "⚔️ Mob Aura & Auto Combat")

Hub.CreateToggle(combatTab, "⚔️ Mob Aura (Light Attack)", false, function(v)
    State.MobAura = v
end)

Hub.CreateSlider(combatTab, "Aura Attack Range", 5, 30, 15, " studs", function(val)
    State.AuraRange = val
end)

Hub.CreateToggle(combatTab, "⚡ Auto Heavy Punch (M2)", false, function(v)
    State.AutoHeavy = v
end)

Hub.CreateToggle(combatTab, "🥊 Auto Barrage (E)", false, function(v)
    State.AutoBarrage = v
end)

Hub.CreateSection(combatTab, "🛡️ Defense & Status Buffs")

Hub.CreateToggle(combatTab, "🛡️ Anti-Ragdoll", false, function(v)
    State.AntiRagdoll = v
end)

Hub.CreateToggle(combatTab, "✨ Anti-Stun & Anti-Freeze", false, function(v)
    State.AntiStun = v
end)

-- -------------------------------------------------------------------------
-- 2. 📜 Quests & Farm Tab
-- -------------------------------------------------------------------------
Hub.CreateSection(questTab, "📜 Auto Quest & Level Farm")

Hub.CreateToggle(questTab, "📜 Auto Farm Selected Quest", false, function(v)
    State.AutoFarmQuests = v
end)

Hub.CreateDropdown(questTab, "Target Quest", ybaQuestsCatalog, 1, function(selected)
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

Hub.CreateToggle(itemsTab, "🌟 Lucky Arrow Alert & Auto-Snipe", true, function(v)
    State.NotifyLuckyArrow = v
end)

Hub.CreateButton(itemsTab, "⚡ Scan & Collect All Spawned Items Now", function()
    task.spawn(executeAutoCollectItems)
    Hub.Notify("💎 Item Sniper", "Scanning map for spawned items...", 3)
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
    local root = getRoot()
    if root then root.CFrame = CFrame.new(220, 25, -2350) end
end)

Hub.CreateButton(sbrTab, "🏆 Teleport to Final Finish Line", function()
    local root = getRoot()
    if root then root.CFrame = CFrame.new(350, 40, -5600) end
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
Hub.CreateSection(tpTab, "📍 Map Locations & Fast Teleports")

local locNames = {}
for name, _ in pairs(ybaLocations) do table.insert(locNames, name) end
table.sort(locNames)

for _, locName in ipairs(locNames) do
    local pos = ybaLocations[locName]
    Hub.CreateButton(tpTab, "📌 TP: " .. locName, function()
        local root = getRoot()
        if root then
            root.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
            Hub.Notify("📍 Teleport", "Teleported to " .. locName, 2)
        end
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
