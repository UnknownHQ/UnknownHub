--[[
    ========================================================================
    Unknown Hub - Booga Booga Dedicated Script Module (v8 Ultimate Edition)
    Library: UnknownLibrary (Unknown Hub UI)
    Features:
      - Native Network Packet Auto Hit (Packets.SwingTool with EntityIDs & Toolbar Sync)
      - Native Server-Side Auto Pickup (Packets.Pickup by EntityID, Zero Teleporting)
      - Physical Item Magnet Toggle (Separate option, moves unanchored items smoothly)
      - No-Slip Mountain (Infinite MaxSlopeAngle 89.9° + Anti-Slide Velocity Lock)
      - No-Slow Water (Automatic WalkSpeed & Velocity Maintenance while Swimming)
      - Body-Frozen & No-Fall Item Collision Guards
      - Whitelist Selectors via CreateList() (Resources, Mobs, Players, Full Items)
      - Movement & Teleports & Visuals ESP
    ========================================================================
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local CollectionService = game:GetService("CollectionService")
local LocalPlayer = Players.LocalPlayer

local LIBRARY_LINK = "https://raw.githubusercontent.com/UnknownHQ/UnknownHub/main/UnknownLibrary"
local LIBRARY_NAME = "Unknown_TabbedHub_UI"

-- =========================================================================
-- Master Script Lifecycle & Re-Execution Cleanup Manager
-- =========================================================================
if getgenv and getgenv()._UnknownHub_Cleanup then
    pcall(getgenv()._UnknownHub_Cleanup)
    getgenv()._UnknownHub_Cleanup = nil
elseif _G._UnknownHub_Cleanup then
    pcall(_G._UnknownHub_Cleanup)
    _G._UnknownHub_Cleanup = nil
end

local isScriptAlive = true
local scriptCleanups = {}

local function addCleanup(fn)
    table.insert(scriptCleanups, fn)
end

local function safeConnect(signal, callback)
    local conn = signal:Connect(callback)
    addCleanup(function()
        pcall(function() conn:Disconnect() end)
    end)
    return conn
end

local function destroyOldGui()
    local parents = {game:GetService("CoreGui")}
    if gethui then pcall(function() table.insert(parents, gethui()) end) end
    local playerGui = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
    if playerGui then table.insert(parents, playerGui) end
    for _, parent in ipairs(parents) do
        if parent then
            pcall(function()
                for _, child in ipairs(parent:GetChildren()) do
                    if child:IsA("ScreenGui") and (child.Name == LIBRARY_NAME or child.Name == "Unknown_BoogaBooga_UI") then
                        pcall(function() child:Destroy() end)
                    end
                end
            end)
        end
    end
end

local function cleanupEverything()
    isScriptAlive = false
    destroyOldGui()
    for _, fn in ipairs(scriptCleanups) do
        pcall(fn)
    end
    table.clear(scriptCleanups)
    pcall(function()
        local char = LocalPlayer and LocalPlayer.Character
        local hum = char and char:FindFirstChildWhichIsA("Humanoid")
        if hum then
            hum.WalkSpeed = 16
            hum.JumpPower = 50
            hum.MaxSlopeAngle = 46
            hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
            hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
        end
    end)
end

if getgenv then
    getgenv()._UnknownHub_Cleanup = cleanupEverything
end
_G._UnknownHub_Cleanup = cleanupEverything

-- Built-in Anti-AFK
safeConnect(LocalPlayer.Idled, function()
    pcall(function()
        if VirtualUser then
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new(0, 0))
        end
    end)
end)

-- Load UI Library
local ok, result = pcall(function()
    local source
    local cacheBuster = "?t=" .. tostring(os.time() or tick()) .. "_" .. tostring(math.random(1000, 9999))
    source = game:HttpGet(LIBRARY_LINK .. cacheBuster)
    local factoryChunk, compileErr = loadstring(source)
    assert(factoryChunk, "Library compile failed: " .. tostring(compileErr))
    return factoryChunk()
end)

if not ok or type(result) ~= "function" then
    warn("[UnknownHub] Remote library failed loading, standing by...")
end

destroyOldGui()

local Hub = result({
    name = LIBRARY_NAME,
    title = "UNKNOWN HUB",
    subTitle = "Booga Booga",
    parent = (gethui and gethui()) or (LocalPlayer and (LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui"))) or (pcall(function() return game:GetService("CoreGui") end) and game:GetService("CoreGui")),
    theme = Color3.fromRGB(0, 195, 245),
    secondaryTheme = Color3.fromRGB(255, 165, 0)
})

assert(type(Hub) == "table", "UnknownLibrary returned invalid hub")

-- =========================================================================
-- Game Internals (Booga Booga Reborn ByteNet / Packets / Modules)
-- =========================================================================
local Packets = nil
pcall(function()
    Packets = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Packets"))
end)
local GameUtil = nil
pcall(function()
    GameUtil = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameUtil"))
end)
local Clock = nil
pcall(function()
    Clock = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Clock"))
end)
local ToolModule = nil
pcall(function()
    ToolModule = require(ReplicatedStorage:WaitForChild("Game"):WaitForChild("tool"))
end)
local GameFunctions = nil
pcall(function()
    GameFunctions = require(ReplicatedStorage:WaitForChild("Game"):WaitForChild("functions"))
end)

-- =========================================================================
-- State Registry
-- =========================================================================
local state = {
    -- Auto Hit (Single Toggle + Whitelist List: Resources, Mobs, Players)
    AutoHit = false,
    AutoHitTargets = { Resources = true, Mobs = false, Players = false },
    AutoHitRange = 500,
    FastHit = true,
    BypassHitLimit = true,
    HitMultiplier = 5,

    -- Silent Projectile Aimbot
    SilentAimbot = false,
    AimbotTargets = "Both",
    AimbotRange = 500,

    -- Defense & Reach
    ReachHitbox = false,
    ReachSize = 12,
    AutoParry = false,
    AutoEat = false,
    EatThreshold = 60,

    -- Auto Pickup (Instant Server-Side Packets.Pickup - Max Range)
    AutoPickup = false,
    PickupCategoryWhitelist = "All Items (Everything)",
    PickupCustomFilter = "",
    PickupExcludeList = {},
    PickupRange = 500,

    -- Remote Chest Sucker & Looter
    ChestSucker = false,
    ChestSuckerRange = 300,

    -- Smart Combat & Auto Hit Synergies
    SmartToolEquip = true,

    -- Movement & Player
    NoSlipMountain = false,
    NoSlowWater = false,
    WaterSwimSpeed = 16.5,
    GodMode = false,
    WalkSpeedToggle = false,
    WalkSpeedValue = 24,
    JumpPowerToggle = false,
    JumpPowerValue = 75,
    InfiniteStamina = false,
    Noclip = false,
    Fly = false,
    FlySpeed = 50,
    WaterWalk = false,

    -- Visuals
    PlayerESP = false,
    ResourceESP = false,
    MobESP = false,
    Fullbright = false,

    -- Waypoints
    SavedWaypoints = {}
}

-- Helpers
local function getCharacter(player)
    player = player or LocalPlayer
    return player and player.Character
end

local function getRoot(player)
    local char = getCharacter(player)
    return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("Head"))
end

local function getHumanoid(player)
    local char = getCharacter(player)
    return char and char:FindFirstChildWhichIsA("Humanoid")
end

-- Crash-Proof Part Finder (Never errors on Camera/Terrain/Folders)
local function getPrimaryOrAnyPart(obj)
    if not obj or typeof(obj) ~= "Instance" then return nil end
    if obj:IsA("BasePart") then return obj end
    if obj:IsA("Model") then
        local trunk = obj:FindFirstChild("Trunk")
        if trunk and trunk:IsA("BasePart") then return trunk end
        local okPrim, prim = pcall(function() return obj.PrimaryPart end)
        if okPrim and prim and prim:IsA("BasePart") then return prim end
        local anyPart = obj:FindFirstChildWhichIsA("BasePart", true)
        if anyPart then return anyPart end
    end
    return nil
end

-- Smart Tool Auto-Switcher (Equips best tool dynamically)
local TOOL_PRIORITIES = {
    Axe = {"God Axe", "Void Axe", "Adurite Axe", "Steel Axe", "Iron Axe", "Stone Axe", "Wood Axe"},
    Pickaxe = {"God Pick", "Void Pick", "Adurite Pick", "Steel Pick", "Iron Pick", "Stone Pick", "Wood Pick"},
    Weapon = {"God Club", "God's Bolt", "God Sling", "Adurite Club", "Steel Club", "Adurite Blade", "Steel Blade", "Iron Club", "Spear", "Club"}
}

local function equipBestTool(toolType)
    if not state.SmartToolEquip then return end
    pcall(function()
        local char = getCharacter()
        local hum = getHumanoid()
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        if not char or not hum or not backpack then return end

        local priorities = TOOL_PRIORITIES[toolType]
        if not priorities then return end

        local curTool = char:FindFirstChildWhichIsA("Tool")
        if curTool then
            for _, name in ipairs(priorities) do
                if curTool.Name:lower():find(name:lower()) then
                    return
                end
            end
        end

        for _, name in ipairs(priorities) do
            for _, t in ipairs(backpack:GetChildren()) do
                if t:IsA("Tool") and t.Name:lower():find(name:lower()) then
                    hum:EquipTool(t)
                    return
                end
            end
        end
    end)
end

-- Silent Projectile Aimbot Target Resolver
local function getBestAimbotTarget()
    local root = getRoot()
    if not root then return nil end
    local myPos = root.Position
    local bestTarget = nil
    local shortestDist = state.AimbotRange or 500

    if state.AimbotTargets == "Players" or state.AimbotTargets == "Both" then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local pHum = p.Character:FindFirstChildWhichIsA("Humanoid")
                local pHead = p.Character:FindFirstChild("Head") or p.Character:FindFirstChild("HumanoidRootPart")
                if pHum and pHum.Health > 0 and pHead then
                    local d = (pHead.Position - myPos).Magnitude
                    if d < shortestDist then
                        shortestDist = d
                        bestTarget = pHead
                    end
                end
            end
        end
    end

    if not bestTarget and (state.AimbotTargets == "Mobs" or state.AimbotTargets == "Both") then
        local critFolder = Workspace:FindFirstChild("Critters")
        if critFolder then
            for _, c in ipairs(critFolder:GetChildren()) do
                local mHum = c:FindFirstChildWhichIsA("Humanoid")
                local mPart = c:FindFirstChild("Head") or getPrimaryOrAnyPart(c)
                local isAlive = (not mHum) or (mHum.Health > 0)
                if mPart and isAlive then
                    local d = (mPart.Position - myPos).Magnitude
                    if d < shortestDist then
                        shortestDist = d
                        bestTarget = mPart
                    end
                end
            end
        end
    end

    return bestTarget
end

-- Hook Packets.CreateProjectile for Silent Aimbot
pcall(function()
    if Packets and Packets.CreateProjectile and Packets.CreateProjectile.send then
        local oldSend = Packets.CreateProjectile.send
        Packets.CreateProjectile.send = function(payload)
            if state.SilentAimbot and typeof(payload) == "table" then
                pcall(function()
                    local targetPart = getBestAimbotTarget()
                    if targetPart then
                        local root = getRoot()
                        local origin = root and (root.Position + Vector3.new(0, 1.5, 0)) or (payload.origin or targetPart.Position)
                        local spd = payload.velocity and payload.velocity.Magnitude or 180
                        if spd < 50 then spd = 180 end
                        local dir = (targetPart.Position - origin).Unit
                        payload.velocity = dir * spd
                        if payload.cframe then
                            payload.cframe = CFrame.new(origin, targetPart.Position)
                        end
                    end
                end)
            end
            return oldSend(payload)
        end
    end
end)

-- Comprehensive Remote Collectors
local function getAllRemotes()
    local remotes = {}
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            table.insert(remotes, obj)
        end
    end
    return remotes
end

local function getRemotesMatching(patterns)
    local matched = {}
    for _, r in ipairs(getAllRemotes()) do
        local rName = r.Name:lower()
        for _, pattern in ipairs(patterns) do
            if rName:find(pattern:lower()) then
                table.insert(matched, r)
                break
            end
        end
    end
    return matched
end

-- Resource Whitelist Matcher (All In-Game Resources including Cactus, Trees, Rocks, Crops, Ores, Mounds)
local RESOURCE_KEYWORDS = {
    "tree", "wood", "log", "palm", "oak", "birch", "pine", "driftwood", "ancient", "chestnut", "trunk",
    "rock", "ore", "stone", "gold", "iron", "adurite", "crystal", "meteor", "essence", "magma", "void",
    "node", "coal", "pink diamond", "mound", "debris", "structure", "chest", "crate", "box", "totem",
    "berry", "bush", "fruit", "plant", "bloodfruit", "bluefruit", "sunfruit", "jellyfruit", "cloudberry",
    "cactus", "cacti", "crop", "flora", "flower", "grass", "reed", "lily", "coral", "boulder", "shroom", "mushroom"
}

local function isTargetResource(name, parentFolder)
    if parentFolder and (parentFolder.Name == "Resources" or parentFolder.Name == "Crops" or parentFolder.Name == "Mounds" or parentFolder.Name == "Nodes" or parentFolder.Name == "Flora" or parentFolder.Name == "Trees" or parentFolder.Name == "Ores") then
        return true
    end
    name = name:lower()
    for _, kw in ipairs(RESOURCE_KEYWORDS) do
        if name:find(kw) then
            return true
        end
    end
    return false
end

-- Item Category Whitelist Matcher (All Booga Booga Game Items)
local ITEM_CATEGORIES = {
    ["Ores & Gems"] = {"stone", "coal", "iron", "gold", "adurite", "crystal", "pink diamond", "meteorite", "magma", "void stone", "essence", "ore", "gem"},
    ["Wood & Logs"] = {"wood", "oak", "birch", "pine", "palm", "chestnut", "driftwood", "ancient", "log"},
    ["Food & Consumables"] = {"berry", "bloodfruit", "bluefruit", "sunfruit", "jellyfruit", "cloudberry", "meat", "fish", "fruit", "food", "cooked", "raw"},
    ["Equipment & Gear"] = {"pickaxe", "axe", "club", "spear", "sword", "bag", "armor", "helmet", "shield", "bow", "arrow"},
    ["Valuables & Essences"] = {"coin", "feather", "hide", "fang", "horn", "essence", "chestnut", "tooth", "bone"}
}

local function isWhitelistedItem(itemName)
    itemName = itemName:lower()

    -- 1. Check Exclude / Blacklist First (Absolute Core Anti-Pickup Priority)
    if state.PickupExcludeList then
        for _, excluded in ipairs(state.PickupExcludeList) do
            if excluded and excluded ~= "" then
                local exLower = string.lower(excluded)
                if string.find(itemName, exLower) then
                    return false
                end
            end
        end
    end

    -- 2. Specific Item Filter
    if state.PickupCustomFilter and state.PickupCustomFilter ~= "" then
        local filterLower = state.PickupCustomFilter:lower()
        if itemName:find(filterLower) then return true end
    end

    -- 3. Category Filter
    local category = state.PickupCategoryWhitelist
    if category == "All Items (Everything)" then
        return true
    end

    local keywords = ITEM_CATEGORIES[category]
    if keywords then
        for _, kw in ipairs(keywords) do
            if itemName:find(kw) then
                return true
            end
        end
    end

    return false
end

-- =========================================================================
-- Tabs Setup
-- =========================================================================
local combatTab   = Hub.createTabButton("Combat", "🥊 Combat & Auto Hit", "rbxassetid://10723407390", true)
local farmTab     = Hub.createTabButton("Farm", "🪵 Auto Pickup & Farm", "rbxassetid://10723407389", false)
local playerTab   = Hub.createTabButton("Player", "⚡ Movement", "rbxassetid://10723407392", false)
local visualsTab  = Hub.createTabButton("Visuals", "👁️ ESP & Visuals", "rbxassetid://10723407395", false)
local teleportTab = Hub.createTabButton("Teleports", "🌐 Teleports", "rbxassetid://10723407389", false)
local miscTab     = Hub.createTabButton("Misc", "🛠️ Utility & Server", "rbxassetid://10723407392", false)

-- =========================================================================
-- 1. COMBAT TAB: AUTO HIT (NATIVE BYTE-NET PACKETS & REMOTE SYNC)
-- =========================================================================
Hub.CreateSection(combatTab, "Single Toggle Auto Hit")

Hub.CreateToggle(combatTab, "⚡ Auto Hit", false, function(toggled)
    state.AutoHit = toggled
end)

-- Multi-select List using Hub.CreateList() for Auto Hit Targets: Resources, Mobs, Players
local autoHitTargetsList = Hub.CreateList(combatTab, "🎯 Auto Hit Targets (Whitelist)", {"Resources", "Mobs", "Players"}, 150, true, true)
autoHitTargetsList:SetSelectedItems({"Resources"})
autoHitTargetsList.OnSelect = function(selectedName, entryData)
    state.AutoHitTargets.Resources = false
    state.AutoHitTargets.Mobs = false
    state.AutoHitTargets.Players = false

    local selectedList = autoHitTargetsList.SelectedItems or {}
    for _, item in ipairs(selectedList) do
        local n = type(item) == "table" and item.Name or tostring(item)
        if state.AutoHitTargets[n] ~= nil then
            state.AutoHitTargets[n] = true
        end
    end
end

Hub.CreateSlider(combatTab, "Auto Hit Range (Studs - Max 5000)", 10, 5000, 500, " studs", function(val)
    state.AutoHitRange = val
end)

Hub.CreateToggle(combatTab, "⚡ Max Hit Speed (0ms Delay)", true, function(toggled)
    state.FastHit = toggled
end)

Hub.CreateToggle(combatTab, "💥 Limit Bypass (Super Fast Multi-Hit)", true, function(toggled)
    state.BypassHitLimit = toggled
end)

Hub.CreateSlider(combatTab, "Hit Multiplier / Burst", 1, 25, 5, "x", function(val)
    state.HitMultiplier = val
end)

Hub.CreateSection(combatTab, "🏹 Silent Bow & Projectile Aimbot")

Hub.CreateToggle(combatTab, "🏹 Silent Projectile Aimbot", false, function(toggled)
    state.SilentAimbot = toggled
end)

local aimbotModeList = Hub.CreateList(combatTab, "🎯 Aimbot Target Filter", {"Both (Players & Mobs)", "Players Only", "Mobs Only"}, 120, true)
aimbotModeList:SetSelected("Both (Players & Mobs)")
aimbotModeList.OnSelect = function(selected)
    if selected == "Players Only" then state.AimbotTargets = "Players"
    elseif selected == "Mobs Only" then state.AimbotTargets = "Mobs"
    else state.AimbotTargets = "Both" end
end

Hub.CreateSlider(combatTab, "Aimbot Max Range (Studs)", 50, 2000, 500, " studs", function(val)
    state.AimbotRange = val
end)

Hub.CreateSection(combatTab, "🛠️ Smart Tool Auto-Switcher")

Hub.CreateToggle(combatTab, "🛠️ Smart Auto-Equip (Best Axe/Pick/Weapon)", true, function(toggled)
    state.SmartToolEquip = toggled
end)

Hub.CreateSection(combatTab, "Reach & Auto Defense")

Hub.CreateToggle(combatTab, "Hitbox Expander / Reach", false, function(toggled)
    state.ReachHitbox = toggled
end)

Hub.CreateSlider(combatTab, "Hitbox Size", 5, 30, 12, " studs", function(val)
    state.ReachSize = val
end)

Hub.CreateToggle(combatTab, "Auto Parry / Shield", false, function(toggled)
    state.AutoParry = toggled
end)

Hub.CreateToggle(combatTab, "Auto Eat Food & Potions", false, function(toggled)
    state.AutoEat = toggled
end)

Hub.CreateSlider(combatTab, "Eat Threshold (% HP/Hunger)", 20, 80, 60, "%", function(val)
    state.EatThreshold = val
end)

-- Native High-Speed Animation-Free Packet Auto Hit Loop
-- Cached Remotes for Auto Hit Fallback (Fetched once, zero frame drops)
local cachedSwingRemote = nil
local cachedInteractStructure = nil
pcall(function()
    if ReplicatedStorage:FindFirstChild("Events") then
        cachedSwingRemote = ReplicatedStorage.Events:FindFirstChild("SwingTool")
        cachedInteractStructure = ReplicatedStorage.Events:FindFirstChild("InteractStructure")
    end
end)

-- High-Performance Animation-Free Packet Auto Hit Loop (Optimized for 144+ FPS)
task.spawn(function()
    while isScriptAlive do
        task.wait(state.FastHit and 0.02 or 0.08)
        if state.AutoHit then
            pcall(function()
                local char = getCharacter()
                local myRoot = getRoot()
                if not char or not myRoot then return end

                local packetTargets = {}
                local targetsToHit = {}
                local myPos = myRoot.Position
                local maxDist = state.AutoHitRange or 5000
                local targetResourceCategory = nil

                -- 1. Resources Target Scanner (All Resources, Cactus, Crops, Trees, Ores, Mounds)
                if state.AutoHitTargets.Resources then
                    local containers = {}
                    for _, name in ipairs({"Resources", "Crops", "Mounds", "Trees", "Ores", "Nodes", "Flora", "Entities", "Structures"}) do
                        local f = Workspace:FindFirstChild(name)
                        if f then table.insert(containers, f) end
                    end

                    for _, container in ipairs(containers) do
                        for _, child in ipairs(container:GetChildren()) do
                            if child ~= char and (child:IsA("Model") or child:IsA("BasePart")) then
                                local part = getPrimaryOrAnyPart(child)
                                if part and isTargetResource(child.Name, container) then
                                    local dist = (myPos - part.Position).Magnitude
                                    if dist <= maxDist then
                                        local entityID = child:GetAttribute("EntityID") or part:GetAttribute("EntityID")
                                        if entityID then
                                            table.insert(packetTargets, { entityID = entityID, buffer = nil })
                                        else
                                            table.insert(targetsToHit, { part = part, parent = child })
                                        end
                                    end
                                end
                            end
                        end
                    end
                end

                -- 2. Mobs & Critters Target Scanner (Critters, Animals, NPCs, Bosses)
                if state.AutoHitTargets.Mobs then
                    local mobContainers = {}
                    for _, name in ipairs({"Critters", "HumanoidCritters", "Mobs", "Animals", "NPCs", "Entities", "Enemies", "Fauna"}) do
                        local f = Workspace:FindFirstChild(name)
                        if f then table.insert(mobContainers, f) end
                    end

                    for _, container in ipairs(mobContainers) do
                        for _, child in ipairs(container:GetChildren()) do
                            if child ~= char and (child:IsA("Model") or child:IsA("BasePart")) then
                                local isPlr = Players:GetPlayerFromCharacter(child) ~= nil
                                if not isPlr then
                                    local mHum = child:FindFirstChildWhichIsA("Humanoid")
                                    local mRoot = getPrimaryOrAnyPart(child)
                                    local isAlive = (not mHum) or (mHum.Health > 0)
                                    if mRoot and isAlive then
                                        local dist = (myPos - mRoot.Position).Magnitude
                                        if dist <= maxDist then
                                            local entityID = child:GetAttribute("EntityID") or mRoot:GetAttribute("EntityID")
                                            if entityID then
                                                table.insert(packetTargets, { entityID = entityID, buffer = nil })
                                            else
                                                table.insert(targetsToHit, { part = mRoot, parent = child })
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end

                -- 3. Players Target Scanner
                if state.AutoHitTargets.Players then
                    for _, otherPlr in ipairs(Players:GetPlayers()) do
                        if otherPlr ~= LocalPlayer and otherPlr.Character then
                            local oChar = otherPlr.Character
                            local oHum = oChar:FindFirstChildWhichIsA("Humanoid")
                            local oRoot = getPrimaryOrAnyPart(oChar)
                            if oHum and oHum.Health > 0 and oRoot then
                                local dist = (myPos - oRoot.Position).Magnitude
                                if dist <= maxDist then
                                    local entityID = oChar:GetAttribute("EntityID") or oRoot:GetAttribute("EntityID")
                                    if entityID then
                                        table.insert(packetTargets, { entityID = entityID, buffer = nil })
                                    else
                                        table.insert(targetsToHit, { part = oRoot, parent = oChar })
                                    end
                                end
                            end
                        end
                    end
                end

                -- Native Packets.SwingTool.send Execution (Unlimited Chunked Multi-Cleave)
                if (#packetTargets > 0 or #targetsToHit > 0) and ToolModule and ToolModule.swingTool then
                    pcall(function() ToolModule.swingTool() end)
                end

                if #packetTargets > 0 and Packets and Packets.SwingTool then
                    pcall(function()
                        local baseTime = Clock and Clock.getServerTime(true) or os.clock()
                        local bursts = state.BypassHitLimit and (state.HitMultiplier or 5) or 1

                        -- Chunk targets in groups of 60 IDs per packet to prevent ByteNet packet truncation
                        local chunkSize = 60
                        for i = 1, #packetTargets, chunkSize do
                            local chunk = {}
                            for j = i, math.min(i + chunkSize - 1, #packetTargets) do
                                table.insert(chunk, packetTargets[j])
                            end

                            for b = 1, bursts do
                                Packets.SwingTool.send({
                                    entityIDs = chunk,
                                    cframe = char:GetPivot(),
                                    timestamp = baseTime - (b - 1) * 0.008
                                })
                            end
                        end
                    end)
                end

                -- Fallback Execution for Non-Packet Objects Only
                if #targetsToHit > 0 then
                    for _, targetData in ipairs(targetsToHit) do
                        local targetPart = targetData.part
                        local targetModel = targetData.parent

                        if cachedSwingRemote then
                            pcall(function() cachedSwingRemote:FireServer(targetPart) end)
                            pcall(function() cachedSwingRemote:FireServer(targetModel) end)
                        end

                        if cachedInteractStructure then
                            pcall(function() cachedInteractStructure:FireServer(targetModel or targetPart) end)
                        end
                    end
                end
            end)
        end
    end
end)

-- Hitbox Expander Loop
task.spawn(function()
    while isScriptAlive do
        task.wait(0.5)
        if state.ReachHitbox then
            pcall(function()
                local char = getCharacter()
                local tool = char and char:FindFirstChildWhichIsA("Tool")
                local handle = tool and (tool:FindFirstChild("Handle") or tool:FindFirstChildWhichIsA("BasePart"))
                if handle then
                    handle.Size = Vector3.new(state.ReachSize, state.ReachSize, state.ReachSize)
                    handle.Massless = true
                    handle.CanCollide = false
                end
            end)
        end
    end
end)

-- Auto Eat Loop
task.spawn(function()
    while isScriptAlive do
        task.wait(1.5)
        if state.AutoEat then
            pcall(function()
                local hum = getHumanoid()
                if hum and (hum.Health <= (hum.MaxHealth * (state.EatThreshold / 100))) then
                    local backpack = LocalPlayer:FindFirstChild("Backpack")
                    local char = getCharacter()
                    local foodKeywords = {"berry", "meat", "fruit", "food", "cooked", "bloodfruit", "bluefruit", "sunfruit", "jellyfruit"}
                    local foundFood = nil

                    if backpack then
                        for _, item in ipairs(backpack:GetChildren()) do
                            local iName = item.Name:lower()
                            for _, kw in ipairs(foodKeywords) do
                                if iName:find(kw) then
                                    foundFood = item
                                    break
                                end
                            end
                            if foundFood then break end
                        end
                    end

                    if foundFood and char then
                        local curTool = char:FindFirstChildWhichIsA("Tool")
                        hum:EquipTool(foundFood)
                        task.wait(0.1)
                        foundFood:Activate()
                        local eatRemotes = getRemotesMatching({"eat", "consume", "use", "useitem"})
                        for _, r in ipairs(eatRemotes) do
                            pcall(function()
                                if r:IsA("RemoteEvent") then r:FireServer(foundFood)
                                elseif r:IsA("RemoteFunction") then r:InvokeServer(foundFood) end
                            end)
                        end
                        task.wait(0.1)
                        if curTool then hum:EquipTool(curTool) end
                    end
                end
            end)
        end
    end
end)

-- =========================================================================
-- 2. FARM TAB: NATIVE AUTO PICKUP (EXPANDED SERVER RADIUS)
-- =========================================================================
Hub.CreateSection(farmTab, "Native Server Auto Pickup (Fast Loot)")

Hub.CreateToggle(farmTab, "🧲 Auto Pickup (Instant Drops Collector)", false, function(toggled)
    state.AutoPickup = toggled
end)

local pickupCategories = {
    "All Items (Everything)",
    "Ores & Gems",
    "Wood & Logs",
    "Food & Consumables",
    "Equipment & Gear",
    "Valuables & Essences"
}
local itemCategoryList = Hub.CreateList(farmTab, "🪵 Item Whitelist Category", pickupCategories, 200, true)
itemCategoryList:SetSelected(state.PickupCategoryWhitelist or "All Items (Everything)")
itemCategoryList.OnSelect = function(selected)
    state.PickupCategoryWhitelist = selected
end

Hub.CreateTextBox(farmTab, "Specific Item Name Filter", "Type item name (e.g. Berry, Adurite)", function(text)
    state.PickupCustomFilter = text
end)

Hub.CreateSlider(farmTab, "Pickup Radius (Studs - Max 5000)", 10, 5000, 500, " studs", function(val)
    state.PickupRange = val
end)

Hub.CreateSection(farmTab, "🚫 Auto Pickup Exclude Blacklist")

local typedExcludeText = ""
Hub.CreateTextBox(farmTab, "Item Name to Exclude", "Type item name (e.g. Leaves, Log, Rock)", function(text)
    typedExcludeText = text
end)

local excludeListDisplay = nil

local function refreshExcludeList()
    if excludeListDisplay and excludeListDisplay.SetItems then
        local items = {}
        for _, ex in ipairs(state.PickupExcludeList) do
            table.insert(items, "⛔ " .. ex)
        end
        if #items == 0 then table.insert(items, "(No Excluded Items)") end
        excludeListDisplay:SetItems(items)
    end
end

Hub.CreateButton(farmTab, "➕ Add to Exclude List", function()
    if typedExcludeText and typedExcludeText:gsub("%s+", "") ~= "" then
        local clean = typedExcludeText:match("^%s*(.-)%s*$")
        local found = false
        for _, ex in ipairs(state.PickupExcludeList) do
            if ex:lower() == clean:lower() then found = true break end
        end
        if not found then
            table.insert(state.PickupExcludeList, clean)
            refreshExcludeList()
        end
    end
end)

Hub.CreateButton(farmTab, "🗑️ Clear All Excluded Items", function()
    table.clear(state.PickupExcludeList)
    refreshExcludeList()
end)

excludeListDisplay = Hub.CreateList(farmTab, "⛔ Currently Blacklisted Items", {"(No Excluded Items)"}, 120, false)

Hub.CreateSection(farmTab, "⚡ Quick Preset Exclusions")

Hub.CreateButton(farmTab, "🚫 + Exclude Leaves & Twigs", function()
    local presets = {"Leaves", "Twig", "Leaf"}
    for _, p in ipairs(presets) do
        local found = false
        for _, ex in ipairs(state.PickupExcludeList) do
            if ex:lower() == p:lower() then found = true break end
        end
        if not found then table.insert(state.PickupExcludeList, p) end
    end
    refreshExcludeList()
end)

Hub.CreateButton(farmTab, "🚫 + Exclude Normal Stone & Rocks", function()
    local presets = {"Stone", "Rock"}
    for _, p in ipairs(presets) do
        local found = false
        for _, ex in ipairs(state.PickupExcludeList) do
            if ex:lower() == p:lower() then found = true break end
        end
        if not found then table.insert(state.PickupExcludeList, p) end
    end
    refreshExcludeList()
end)

Hub.CreateButton(farmTab, "🚫 + Exclude Normal Wood & Logs", function()
    local presets = {"Wood", "Log"}
    for _, p in ipairs(presets) do
        local found = false
        for _, ex in ipairs(state.PickupExcludeList) do
            if ex:lower() == p:lower() then found = true break end
        end
        if not found then table.insert(state.PickupExcludeList, p) end
    end
    refreshExcludeList()
end)

Hub.CreateSection(farmTab, "📦 Remote Chest & Loot Sucker")

Hub.CreateToggle(farmTab, "🧲 Remote Chest & Loot Sucker", false, function(toggled)
    state.ChestSucker = toggled
end)

Hub.CreateSlider(farmTab, "Chest Sucker Radius (Studs)", 50, 1000, 300, " studs", function(val)
    state.ChestSuckerRange = val
end)

-- Remote Chest & Deployable Looter Loop
task.spawn(function()
    while isScriptAlive do
        task.wait(0.25)
        if state.ChestSucker then
            pcall(function()
                local root = getRoot()
                if not root then return end
                local myPos = root.Position
                local maxRange = state.ChestSuckerRange or 300

                local checkFolders = {Workspace, Workspace:FindFirstChild("dropChests"), Workspace:FindFirstChild("Deployables")}
                for _, folder in ipairs(checkFolders) do
                    if folder then
                        for _, obj in ipairs(folder:GetChildren()) do
                            local lName = obj.Name:lower()
                            if lName:find("chest") or lName:find("present") or lName:find("mound") then
                                local part = obj:IsA("BasePart") and obj or (obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")))
                                if part then
                                    local dist = (myPos - part.Position).Magnitude
                                    if dist <= maxRange then
                                        local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
                                        if prompt and fireproximityprompt then
                                            fireproximityprompt(prompt)
                                        end

                                        local cd = obj:FindFirstChildWhichIsA("ClickDetector", true)
                                        if cd and fireclickdetector then
                                            fireclickdetector(cd)
                                        end

                                        local entityID = obj:GetAttribute("EntityID")
                                        if entityID and Packets and Packets.InteractStructure and Packets.InteractStructure.send then
                                            Packets.InteractStructure.send({ entityID = entityID, itemID = 0 })
                                        end

                                        if not part.Anchored then
                                            part.AssemblyLinearVelocity = (myPos - part.Position).Unit * 35
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- =========================================================================
-- FARM TAB: AUTO PLANT & AUTO HARVEST CROPS / BERRIES
-- =========================================================================
Hub.CreateSection(farmTab, "🌱 Auto Plant Berries & Crops (Max Range)")

state.AutoPlant = false
state.SelectedBerry = "Bloodfruit"
state.PlantRange = 150
state.PlantDelay = 0.1

Hub.CreateToggle(farmTab, "🌱 Auto Plant Seeds / Berries", false, function(toggled)
    state.AutoPlant = toggled
end)

local plantableCrops = {
    "Bloodfruit",
    "Sunfruit",
    "Berry",
    "Bluefruit",
    "Cloudberry",
    "Frostfruit",
    "Oddberry",
    "Strawberry",
    "Watermelon",
    "Barley",
    "Corn"
}

local cropSelector = Hub.CreateList(farmTab, "🍓 Select Berry / Crop to Plant", plantableCrops, 180, true)
cropSelector:SetSelected(state.SelectedBerry or "Bloodfruit")
cropSelector.OnSelect = function(selected)
    state.SelectedBerry = selected
end

Hub.CreateSlider(farmTab, "Planting Radius (Max 500 Studs)", 10, 500, 150, " studs", function(val)
    state.PlantRange = val
end)

Hub.CreateSlider(farmTab, "Planting Delay", 0.05, 1.0, 0.1, "s", function(val)
    state.PlantDelay = val
end)

Hub.CreateSection(farmTab, "🌾 Auto Harvest Berries & Grown Crops")

state.AutoHarvest = false
state.HarvestRange = 150

Hub.CreateToggle(farmTab, "🌾 Auto Harvest Grown Crop Bushes", false, function(toggled)
    state.AutoHarvest = toggled
end)

Hub.CreateSlider(farmTab, "Harvesting Radius (Max 500 Studs)", 10, 500, 150, " studs", function(val)
    state.HarvestRange = val
end)

local function isHarvestableCrop(name)
    local l = string.lower(name)
    return string.find(l, "bush") or string.find(l, "crop") or string.find(l, "bushel") or string.find(l, "fruit tree") or string.find(l, "plant box")
end

-- Auto Plant Loop
task.spawn(function()
    while isScriptAlive do
        task.wait(state.PlantDelay or 0.1)
        if state.AutoPlant then
            pcall(function()
                local root = getRoot()
                if not root then return end
                local myPos = root.Position
                local targetBerry = state.SelectedBerry or "Bloodfruit"
                local itemIDS = require(ReplicatedStorage.Modules.ItemIDS)
                local berryID = itemIDS and itemIDS[targetBerry]
                if not berryID then return end

                local deployables = Workspace:FindFirstChild("Deployables")
                if deployables then
                    for _, box in ipairs(deployables:GetChildren()) do
                        if box.Name == "Plant Box" then
                            local part = box.PrimaryPart or box:FindFirstChildWhichIsA("BasePart")
                            if part then
                                local dist = (myPos - part.Position).Magnitude
                                if dist <= (state.PlantRange or 150) then
                                    local entityID = box:GetAttribute("EntityID")
                                    if entityID then
                                        if Packets and Packets.InteractStructure and Packets.InteractStructure.send then
                                            Packets.InteractStructure.send({
                                                entityID = entityID,
                                                itemID = berryID
                                            })
                                        else
                                            local interactRemote = ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("InteractStructure")
                                            if interactRemote then
                                                interactRemote:FireServer({ entityID = entityID, itemID = berryID })
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- Auto Harvest Loop
task.spawn(function()
    while isScriptAlive do
        task.wait(0.15)
        if state.AutoHarvest then
            pcall(function()
                local root = getRoot()
                if not root then return end
                local myPos = root.Position
                local curTool = getEquippedTool()
                local toolID = curTool and curTool:GetAttribute("EntityID") or 0

                local folders = {Workspace:FindFirstChild("Resources"), Workspace:FindFirstChild("Deployables")}
                for _, folder in ipairs(folders) do
                    if folder then
                        for _, obj in ipairs(folder:GetChildren()) do
                            if isHarvestableCrop(obj.Name) then
                                local part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                                if part then
                                    local dist = (myPos - part.Position).Magnitude
                                    if dist <= (state.HarvestRange or 150) then
                                        local entityID = obj:GetAttribute("EntityID")
                                        if entityID then
                                            if Packets and Packets.SwingTool and Packets.SwingTool.send then
                                                Packets.SwingTool.send(entityID, toolID)
                                            else
                                                local swingRemote = ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("SwingTool")
                                                if swingRemote then
                                                    swingRemote:FireServer(entityID, part.Position)
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- =========================================================================
-- INSTANT REACTIVE AUTO PICKUP ENGINE (0ms Drop Sucker + Continuous Frame Sweep)
-- =========================================================================
local monitoredContainers = {"Items", "Drops", "Loot", "Debris", "Rubble", "dropChests"}

local function instantPickupItem(item)
    if not isScriptAlive or not state.AutoPickup then return end
    pcall(function()
        local char = getCharacter()
        local myRoot = getRoot()
        local hum = getHumanoid()
        if not char or not myRoot or not hum or hum.Health <= 0 then return end

        local part = item:IsA("BasePart") and item or item:FindFirstChildWhichIsA("BasePart", true)
        if part and not part:IsDescendantOf(char) then
            local dist = (myRoot.Position - part.Position).Magnitude
            if dist <= (state.PickupRange or 5000) and isWhitelistedItem(item.Name) then
                local entityID = item:GetAttribute("EntityID") or part:GetAttribute("EntityID")
                if entityID and Packets and Packets.Pickup then
                    Packets.Pickup.send(entityID)
                end

                if firetouchinterest then
                    firetouchinterest(myRoot, part, 0)
                    firetouchinterest(myRoot, part, 1)
                end

                local pickupRemote = ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("Pickup")
                if pickupRemote then
                    pickupRemote:FireServer(item)
                    pickupRemote:FireServer(part)
                end

                local cd = item:FindFirstChildWhichIsA("ClickDetector", true) or part:FindFirstChildWhichIsA("ClickDetector", true)
                if cd then fireclickdetector(cd) end

                local prompt = item:FindFirstChildWhichIsA("ProximityPrompt", true) or part:FindFirstChildWhichIsA("ProximityPrompt", true)
                if prompt and fireproximityprompt then fireproximityprompt(prompt) end
            end
        end
    end)
end

-- 1. Realtime 0ms ChildAdded Hook (Vacuums drops the instant they spawn)
for _, name in ipairs(monitoredContainers) do
    local f = Workspace:FindFirstChild(name)
    if f then
        safeConnect(f.ChildAdded, function(item)
            instantPickupItem(item)
        end)
    end
end
safeConnect(Workspace.ChildAdded, function(child)
    for _, name in ipairs(monitoredContainers) do
        if child.Name == name then
            safeConnect(child.ChildAdded, function(item)
                instantPickupItem(item)
            end)
        end
    end
end)

-- 2. Ultra-Fast Continuous Sweep Loop
safeConnect(RunService.Heartbeat, function()
    if not isScriptAlive or not state.AutoPickup then return end
    pcall(function()
        local char = getCharacter()
        local myRoot = getRoot()
        local hum = getHumanoid()
        if not char or not myRoot or not hum or hum.Health <= 0 then return end
        local myPos = myRoot.Position
        local maxRange = state.PickupRange or 5000

        for _, name in ipairs(monitoredContainers) do
            local container = Workspace:FindFirstChild(name)
            if container then
                for _, item in ipairs(container:GetChildren()) do
                    local part = item:IsA("BasePart") and item or item:FindFirstChildWhichIsA("BasePart", true)
                    if part and not part:IsDescendantOf(char) then
                        local dist = (myPos - part.Position).Magnitude
                        if dist <= maxRange and isWhitelistedItem(item.Name) then
                            local entityID = item:GetAttribute("EntityID") or part:GetAttribute("EntityID")
                            if entityID and Packets and Packets.Pickup then
                                Packets.Pickup.send(entityID)
                            end
                            if firetouchinterest then
                                firetouchinterest(myRoot, part, 0)
                                firetouchinterest(myRoot, part, 1)
                            end
                        end
                    end
                end
            end
        end
    end)
end)

-- =========================================================================
-- 3. PLAYER TAB: MOVEMENT, NO-SLIP MOUNTAIN, NO-SLOW WATER & GODMODE
-- =========================================================================
Hub.CreateSection(playerTab, "Mountain & Water Enhancements")

Hub.CreateToggle(playerTab, "⛰️ No-Slip Mountain (Walk Up Cliffs)", false, function(toggled)
    state.NoSlipMountain = toggled
    pcall(function()
        local hum = getHumanoid()
        if hum then
            hum.MaxSlopeAngle = toggled and 89.9 or 46
        end
    end)
end)

Hub.CreateToggle(playerTab, "🌊 No-Slow Water (Full Speed Swimming)", false, function(toggled)
    state.NoSlowWater = toggled
end)

Hub.CreateSlider(playerTab, "🌊 Swim Speed (Anti-Rubberband)", 12, 30, 16, " speed", function(val)
    state.WaterSwimSpeed = val
end)

-- High-Performance No-Slip Mountain & No-Slow Water Runner
safeConnect(RunService.Heartbeat, function()
    pcall(function()
        local char = getCharacter()
        local hum = getHumanoid()
        local root = getRoot()
        if not char or not hum or not root then return end

        -- No-Slip Mountain: Keep MaxSlopeAngle 89.9 and prevent sliding downwards on steep slopes
        if state.NoSlipMountain then
            if hum.MaxSlopeAngle < 89 then
                hum.MaxSlopeAngle = 89.9
            end
            local stateType = hum:GetState()
            if (stateType == Enum.HumanoidStateType.Freefall or stateType == Enum.HumanoidStateType.FallingDown) and root.AssemblyLinearVelocity.Y < -5 then
                local rayParams = RaycastParams.new()
                rayParams.FilterDescendantsInstances = {char}
                rayParams.FilterType = Enum.RaycastFilterType.Exclude
                local ray = Workspace:Raycast(root.Position, Vector3.new(0, -4, 0), rayParams)
                if ray and ray.Instance and not ray.Instance:IsA("Terrain") and ray.Normal.Y < 0.7 then
                    root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z)
                end
            end
        end

        -- No-Slow Water: Full Speed Safe Swimming Without Server Rubberbanding
        if state.NoSlowWater then
            local isWater = (hum:GetState() == Enum.HumanoidStateType.Swimming) or (hum.FloorMaterial == Enum.Material.Water) or (root.Position.Y < 4.5 and root.Position.Y > -200)
            if isWater then
                local swimSpeed = state.WalkSpeedToggle and state.WalkSpeedValue or (state.WaterSwimSpeed or 16.5)
                local moveDir = hum.MoveDirection

                -- Maintain humanoid walkspeed in water
                if hum.WalkSpeed < swimSpeed then
                    hum.WalkSpeed = swimSpeed
                end

                if moveDir.Magnitude > 0 then
                    local cam = Workspace.CurrentCamera
                    local vy = root.AssemblyLinearVelocity.Y
                    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                        vy = math.clamp(swimSpeed * 0.6, 5, 12)
                    elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                        vy = -math.clamp(swimSpeed * 0.6, 5, 12)
                    elseif cam and moveDir.Magnitude > 0 then
                        local pitch = cam.CFrame.LookVector.Y
                        if math.abs(pitch) > 0.3 then
                            vy = math.clamp(pitch * swimSpeed * 0.5, -10, 10)
                        end
                    end

                    root.AssemblyLinearVelocity = Vector3.new(moveDir.X * swimSpeed, vy, moveDir.Z * swimSpeed)
                end
            end
        end
    end)
end)

Hub.CreateSection(playerTab, "Godmode & Defense")

Hub.CreateToggle(playerTab, "God Mode (No Fall / Health Guard)", false, function(toggled)
    state.GodMode = toggled
    pcall(function()
        local hum = getHumanoid()
        if hum then
            hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, not toggled)
            hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, not toggled)
        end
    end)
end)

Hub.CreateToggle(playerTab, "Infinite Stamina", false, function(toggled)
    state.InfiniteStamina = toggled
end)

Hub.CreateSection(playerTab, "Speed & Jump Modifications")

Hub.CreateToggle(playerTab, "Enable Custom WalkSpeed", false, function(toggled)
    state.WalkSpeedToggle = toggled
    pcall(function()
        local hum = getHumanoid()
        if hum then hum.WalkSpeed = toggled and state.WalkSpeedValue or 16 end
    end)
end)

Hub.CreateSlider(playerTab, "WalkSpeed Value", 16, 150, 24, " speed", function(val)
    state.WalkSpeedValue = val
    if state.WalkSpeedToggle then
        pcall(function()
            local hum = getHumanoid()
            if hum then hum.WalkSpeed = val end
        end)
    end
end)

Hub.CreateToggle(playerTab, "Enable Custom JumpPower", false, function(toggled)
    state.JumpPowerToggle = toggled
    pcall(function()
        local hum = getHumanoid()
        if hum then hum.JumpPower = toggled and state.JumpPowerValue or 50 end
    end)
end)

Hub.CreateSlider(playerTab, "JumpPower Value", 50, 250, 75, " jump", function(val)
    state.JumpPowerValue = val
    if state.JumpPowerToggle then
        pcall(function()
            local hum = getHumanoid()
            if hum then hum.JumpPower = val end
        end)
    end
end)

Hub.CreateSection(playerTab, "Ghost Fly & Undetected Noclip")

Hub.CreateToggle(playerTab, "👻 Ghost Noclip (Pass Through Objects)", false, function(toggled)
    state.Noclip = toggled
    if not toggled then
        pcall(function()
            local char = getCharacter()
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                        part.CanCollide = true
                    end
                end
            end
        end)
    end
end)

safeConnect(RunService.Stepped, function()
    if state.Noclip or (state.Fly and state.FlyNoclip) then
        pcall(function()
            local char = getCharacter()
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
    end
end)

Hub.CreateToggle(playerTab, "🕊️ Undetected Fly (Server-Safe)", false, function(toggled)
    state.Fly = toggled
    if toggled then
        pcall(function()
            local root = getRoot()
            if root then
                state._flyVirtualPos = root.Position
                state._flyLastTick = tick()
            end
        end)
    else
        pcall(function()
            local root = getRoot()
            if root then
                root.AssemblyLinearVelocity = Vector3.zero
                root.AssemblyAngularVelocity = Vector3.zero
            end
        end)
    end
end)

Hub.CreateToggle(playerTab, "🧱 Auto Noclip During Flight", true, function(toggled)
    state.FlyNoclip = toggled
end)

state.FlyNoclip = true
state.FlySpeed = 20

Hub.CreateSlider(playerTab, "Fly Speed (Safe Max 20)", 10, 30, 20, " studs/s", function(val)
    state.FlySpeed = val
end)

Hub.CreateToggle(playerTab, "🌊 Water Walk (Jesus Mode)", false, function(toggled)
    state.WaterWalk = toggled
end)

-- Undetected Fly & Water Walk Heartbeat Runner (Zero BodyMovers Inserted)
safeConnect(RunService.Heartbeat, function()
    if not isScriptAlive then return end

    if state.Fly then
        pcall(function()
            local root = getRoot()
            local hum = getHumanoid()
            local cam = Workspace.CurrentCamera
            if not root or not cam then return end

            local now = tick()
            local dt = math.clamp(now - (state._flyLastTick or now), 0, 0.1)
            state._flyLastTick = now

            if not state._flyVirtualPos then
                state._flyVirtualPos = root.Position
            end

            local moveDir = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir - Vector3.new(0, 1, 0) end

            local currentSpeed = state.FlySpeed or 20

            if moveDir.Magnitude > 0 then
                local unitDir = moveDir.Unit
                state._flyVirtualPos = state._flyVirtualPos + (unitDir * (currentSpeed * dt))
                root.CFrame = CFrame.new(state._flyVirtualPos) * cam.CFrame.Rotation
                root.AssemblyLinearVelocity = unitDir * currentSpeed
                root.AssemblyAngularVelocity = Vector3.zero
            else
                -- Hover Mode: lock virtual position in place
                root.CFrame = CFrame.new(state._flyVirtualPos) * cam.CFrame.Rotation
                root.AssemblyLinearVelocity = Vector3.zero
                root.AssemblyAngularVelocity = Vector3.zero
            end

            if hum then
                hum:ChangeState(Enum.HumanoidStateType.Freefall)
            end
        end)
    end

    if state.WaterWalk then
        pcall(function()
            local root = getRoot()
            if root and root.Position.Y < 4.5 and root.Position.Y > -5 then
                root.Velocity = Vector3.new(root.Velocity.X, 0, root.Velocity.Z)
                root.CFrame = CFrame.new(root.Position.X, 5, root.Position.Z) * root.CFrame.Rotation
            end
        end)
    end
end)

addCleanup(function()
    pcall(function()
        local root = getRoot()
        if root then
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end
    end)
end)

-- =========================================================================
-- 4. VISUALS TAB: COMPREHENSIVE ESP, GODS, ORES & NIGHT VISION
-- =========================================================================
Hub.CreateSection(visualsTab, "👑 Special World ESP")

Hub.CreateToggle(visualsTab, "👑 Gods & Mythic Shrines ESP", false, function(toggled)
    state.GodESP = toggled
end)

Hub.CreateToggle(visualsTab, "💎 Precious Ores ESP (Adurite / Emerald / Crystal / Meteor / Gold)", false, function(toggled)
    state.PreciousOreESP = toggled
end)

Hub.CreateToggle(visualsTab, "📦 Treasure Chests & Loot ESP", false, function(toggled)
    state.ChestESP = toggled
end)

Hub.CreateToggle(visualsTab, "🦖 Bosses & Rare Mobs ESP", false, function(toggled)
    state.BossESP = toggled
end)

Hub.CreateSection(visualsTab, "Standard ESP")

Hub.CreateToggle(visualsTab, "🧑 Player ESP", false, function(toggled)
    state.PlayerESP = toggled
end)

Hub.CreateToggle(visualsTab, "🌲 General Trees & Resources ESP", false, function(toggled)
    state.ResourceESP = toggled
end)

Hub.CreateToggle(visualsTab, "🐾 Common Animals & Critters ESP", false, function(toggled)
    state.MobESP = toggled
end)

Hub.CreateSection(visualsTab, "⚡ Special Vision & Silent Harvester")

Hub.CreateToggle(visualsTab, "🌌 Fullbright & Night Cave Vision", false, function(toggled)
    state.Fullbright = toggled
    pcall(function()
        if toggled then
            Lighting.Brightness = 2.5
            Lighting.ClockTime = 14
            Lighting.FogEnd = 1000000
            Lighting.GlobalShadows = false
            Lighting.OutdoorAmbient = Color3.fromRGB(180, 180, 180)
            Lighting.Ambient = Color3.fromRGB(180, 180, 180)
        else
            Lighting.Brightness = 1
            Lighting.GlobalShadows = true
            Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
        end
    end)
end)

Hub.CreateToggle(visualsTab, "⚔️ Silent Auto-Harvest Aura (Nearest Ore/Mob)", false, function(toggled)
    state.SilentAura = toggled
end)

-- Silent Auto-Harvest Aura Loop (Silent Packet Strike on nearby nodes)
task.spawn(function()
    while isScriptAlive do
        task.wait(0.2)
        if state.SilentAura then
            pcall(function()
                local root = getRoot()
                if not root then return end
                local curTool = getEquippedTool()
                local toolID = curTool and curTool:GetAttribute("EntityID")

                local targetEntity = nil
                local targetPart = nil
                local shortestDist = 20

                -- Scan nearby Resources / Ores / Gods / Critters
                local resFolder = Workspace:FindFirstChild("Resources")
                if resFolder then
                    for _, res in ipairs(resFolder:GetChildren()) do
                        local p = res:IsA("BasePart") and res or (res:IsA("Model") and (res.PrimaryPart or res:FindFirstChildWhichIsA("BasePart")))
                        if p then
                            local d = (p.Position - root.Position).Magnitude
                            if d <= shortestDist then
                                shortestDist = d
                                targetEntity = res:GetAttribute("EntityID")
                                targetPart = p
                            end
                        end
                    end
                end

                local critFolder = Workspace:FindFirstChild("Critters")
                if critFolder and not targetEntity then
                    for _, c in ipairs(critFolder:GetChildren()) do
                        local p = c:IsA("BasePart") and c or (c:IsA("Model") and (c.PrimaryPart or c:FindFirstChildWhichIsA("BasePart")))
                        if p then
                            local d = (p.Position - root.Position).Magnitude
                            if d <= shortestDist then
                                shortestDist = d
                                targetEntity = c:GetAttribute("EntityID")
                                targetPart = p
                            end
                        end
                    end
                end

                if targetEntity and targetPart then
                    if Packets and Packets.SwingTool and Packets.SwingTool.send then
                        Packets.SwingTool.send(targetEntity, toolID or 0)
                    else
                        local swingRemote = ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("SwingTool")
                        if swingRemote then
                            swingRemote:FireServer(targetEntity, targetPart.Position)
                        end
                    end
                end
            end)
        end
    end
end)

-- Master High-Performance ESP Manager
local espFolder = Instance.new("Folder")
espFolder.Name = "Unknown_BoogaMasterESP"
pcall(function() espFolder.Parent = (gethui and gethui()) or CoreGui or Workspace end)

addCleanup(function()
    pcall(function() espFolder:Destroy() end)
end)

local function isGodObject(name)
    local l = string.lower(name)
    return string.find(l, "god") or string.find(l, "spirit lock") or string.find(l, "dancing shelly")
end

local function isPreciousOre(name)
    local l = string.lower(name)
    return string.find(l, "adurite") or string.find(l, "emerald") or string.find(l, "crystal") or string.find(l, "meteor") or string.find(l, "gold node") or string.find(l, "gold stone")
end

local function getPreciousOreColor(name)
    local l = string.lower(name)
    if string.find(l, "adurite") then return Color3.fromRGB(255, 0, 140)
    elseif string.find(l, "emerald") then return Color3.fromRGB(0, 255, 120)
    elseif string.find(l, "crystal") then return Color3.fromRGB(0, 230, 255)
    elseif string.find(l, "meteor") then return Color3.fromRGB(255, 90, 0)
    elseif string.find(l, "gold") then return Color3.fromRGB(255, 215, 0)
    end
    return Color3.fromRGB(0, 255, 200)
end

local function isBossOrRareMob(name)
    local l = string.lower(name)
    return string.find(l, "queen") or string.find(l, "giant shelly") or string.find(l, "mammoth") or string.find(l, "greybeard") or string.find(l, "horseman") or string.find(l, "golden banto") or string.find(l, "crystal shelly") or string.find(l, "gold shelly") or string.find(l, "huge ant") or string.find(l, "shelly spirit")
end

local function isChestObject(name)
    local l = string.lower(name)
    return string.find(l, "chest") or string.find(l, "present") or string.find(l, "mound")
end

local function createBillboard(parent, text, color)
    local bb = Instance.new("BillboardGui")
    bb.Name = "ESP_Label"
    bb.Size = UDim2.new(0, 150, 0, 30)
    bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.AlwaysOnTop = true
    bb.Adornee = parent
    bb.Parent = espFolder

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = color
    label.TextStrokeColor3 = Color3.new(0, 0, 0)
    label.TextStrokeTransparency = 0.2
    label.Font = Enum.Font.GothamBold
    label.TextSize = 13
    label.Parent = bb
    return bb
end

task.spawn(function()
    while isScriptAlive do
        task.wait(1.5)
        pcall(function()
            espFolder:ClearAllChildren()
            local root = getRoot()
            local rootPos = root and root.Position or Vector3.zero

            -- 1. Player ESP
            if state.PlayerESP then
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and p.Character then
                        local pRoot = p.Character:FindFirstChild("HumanoidRootPart")
                        if pRoot then
                            local dist = math.floor((pRoot.Position - rootPos).Magnitude)
                            local h = Instance.new("Highlight")
                            h.FillColor = Color3.fromRGB(255, 40, 40)
                            h.OutlineColor = Color3.fromRGB(255, 255, 255)
                            h.FillTransparency = 0.5
                            h.Adornee = p.Character
                            h.Parent = espFolder
                            createBillboard(pRoot, string.format("🧑 %s [%dm]", p.DisplayName or p.Name, dist), Color3.fromRGB(255, 80, 80))
                        end
                    end
                end
            end

            -- 2. Gods & Shrines ESP
            local resFolder = Workspace:FindFirstChild("Resources")
            if resFolder then
                for _, res in ipairs(resFolder:GetChildren()) do
                    local p = res:IsA("BasePart") and res or (res:IsA("Model") and (res.PrimaryPart or res:FindFirstChildWhichIsA("BasePart")))
                    if p then
                        local dist = math.floor((p.Position - rootPos).Magnitude)

                        if state.GodESP and isGodObject(res.Name) then
                            local h = Instance.new("Highlight")
                            h.FillColor = Color3.fromRGB(180, 50, 255)
                            h.OutlineColor = Color3.fromRGB(255, 215, 0)
                            h.FillTransparency = 0.4
                            h.Adornee = res
                            h.Parent = espFolder
                            createBillboard(p, string.format("👑 %s [%dm]", res.Name, dist), Color3.fromRGB(230, 100, 255))
                        elseif state.PreciousOreESP and isPreciousOre(res.Name) then
                            local color = getPreciousOreColor(res.Name)
                            local h = Instance.new("Highlight")
                            h.FillColor = color
                            h.OutlineColor = Color3.fromRGB(255, 255, 255)
                            h.FillTransparency = 0.4
                            h.Adornee = res
                            h.Parent = espFolder
                            createBillboard(p, string.format("💎 %s [%dm]", res.Name, dist), color)
                        elseif state.ResourceESP and not isGodObject(res.Name) and not isPreciousOre(res.Name) then
                            if isTargetResource(res.Name) then
                                local h = Instance.new("Highlight")
                                h.FillColor = Color3.fromRGB(0, 220, 100)
                                h.OutlineColor = Color3.fromRGB(255, 255, 255)
                                h.FillTransparency = 0.6
                                h.Adornee = res
                                h.Parent = espFolder
                            end
                        end
                    end
                end
            end

            -- 3. Chests & Drop Loot ESP
            if state.ChestESP then
                for _, obj in ipairs(Workspace:GetChildren()) do
                    if isChestObject(obj.Name) then
                        local p = obj:IsA("BasePart") and obj or (obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")))
                        if p then
                            local dist = math.floor((p.Position - rootPos).Magnitude)
                            local h = Instance.new("Highlight")
                            h.FillColor = Color3.fromRGB(255, 200, 0)
                            h.OutlineColor = Color3.fromRGB(255, 255, 255)
                            h.FillTransparency = 0.4
                            h.Adornee = obj
                            h.Parent = espFolder
                            createBillboard(p, string.format("📦 %s [%dm]", obj.Name, dist), Color3.fromRGB(255, 220, 50))
                        end
                    end
                end
                local dropChests = Workspace:FindFirstChild("dropChests")
                if dropChests then
                    for _, c in ipairs(dropChests:GetChildren()) do
                        local p = c:IsA("BasePart") and c or (c:IsA("Model") and (c.PrimaryPart or c:FindFirstChildWhichIsA("BasePart")))
                        if p then
                            local dist = math.floor((p.Position - rootPos).Magnitude)
                            createBillboard(p, string.format("📦 Drop Chest [%dm]", dist), Color3.fromRGB(255, 220, 50))
                        end
                    end
                end
            end

            -- 4. Critters & Bosses ESP
            local critFolder = Workspace:FindFirstChild("Critters")
            if critFolder then
                for _, c in ipairs(critFolder:GetChildren()) do
                    local p = c:IsA("BasePart") and c or (c:IsA("Model") and (c.PrimaryPart or c:FindFirstChildWhichIsA("BasePart")))
                    if p then
                        local dist = math.floor((p.Position - rootPos).Magnitude)
                        if state.BossESP and isBossOrRareMob(c.Name) then
                            local h = Instance.new("Highlight")
                            h.FillColor = Color3.fromRGB(255, 40, 40)
                            h.OutlineColor = Color3.fromRGB(255, 200, 0)
                            h.FillTransparency = 0.3
                            h.Adornee = c
                            h.Parent = espFolder
                            createBillboard(p, string.format("🦖 [BOSS] %s [%dm]", c.Name, dist), Color3.fromRGB(255, 70, 70))
                        elseif state.MobESP and not isBossOrRareMob(c.Name) then
                            local h = Instance.new("Highlight")
                            h.FillColor = Color3.fromRGB(255, 170, 0)
                            h.OutlineColor = Color3.fromRGB(255, 255, 255)
                            h.FillTransparency = 0.6
                            h.Adornee = c
                            h.Parent = espFolder
                        end
                    end
                end
            end
        end)
    end
end)

-- =========================================================================
-- 5. TELEPORTS TAB: SERVER-SAFE FAST TRAVEL (ANTI-ROLLBACK IMMUNE)
-- =========================================================================
Hub.CreateSection(teleportTab, "🚀 Server-Safe Fast Travel (No Rollback)")

local transitSpeed = 20
local isTransiting = false
local currentTransitConn = nil
local savedWaypoints = {}

Hub.CreateSlider(teleportTab, "Travel Speed (Studs/sec - Safe Max 20)", 10, 22, 20, " studs/s", function(val)
    transitSpeed = val
end)

local function stopTransit()
    isTransiting = false
    if currentTransitConn then
        pcall(function() currentTransitConn:Disconnect() end)
        currentTransitConn = nil
    end
    pcall(function()
        local root = getRoot()
        if root then
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end
    end)
end

addCleanup(stopTransit)

local function startServerSafeTransit(targetPosition, targetName)
    stopTransit()
    task.spawn(function()
        local char = getCharacter()
        local root = getRoot()
        local hum = getHumanoid()
        if not char or not root or not targetPosition then return end

        isTransiting = true
        local startPos = root.Position
        local targetPos = typeof(targetPosition) == "CFrame" and targetPosition.Position or targetPosition
        -- Elevate target slightly so we don't land inside terrain
        if targetPos.Y < 5 and targetPos.Y > -10 then
            targetPos = Vector3.new(targetPos.X, math.max(targetPos.Y, 5), targetPos.Z)
        end

        local totalDist = (targetPos - startPos).Magnitude
        local speed = math.clamp(transitSpeed, 10, 22)
        local totalTime = math.max(totalDist / speed, 0.1)
        local startTime = tick()

        currentTransitConn = RunService.Heartbeat:Connect(function()
            if not isTransiting or not isScriptAlive then
                stopTransit()
                return
            end

            local elapsed = tick() - startTime
            local alpha = math.clamp(elapsed / totalTime, 0, 1)
            local currentPos = startPos:Lerp(targetPos, alpha)

            pcall(function()
                local charObj = getCharacter()
                local r = getRoot()
                if not r then return end

                -- Temporary noclip during transit
                if charObj then
                    for _, p in ipairs(charObj:GetDescendants()) do
                        if p:IsA("BasePart") and p.CanCollide then
                            p.CanCollide = false
                        end
                    end
                end

                local moveDir = (targetPos - startPos).Unit
                r.CFrame = CFrame.new(currentPos) * r.CFrame.Rotation
                r.AssemblyLinearVelocity = moveDir * speed
            end)

            if alpha >= 1 then
                stopTransit()
            end
        end)
    end)
end

Hub.CreateButton(teleportTab, "🛑 Stop / Cancel Current Transit", function()
    stopTransit()
end)

Hub.CreateSection(teleportTab, "📍 Custom Saved Waypoints")

Hub.CreateButton(teleportTab, "💾 Save Waypoint 1 (Current Position)", function()
    local root = getRoot()
    if root then savedWaypoints["Waypoint 1"] = root.Position end
end)
Hub.CreateButton(teleportTab, "✈️ Travel to Waypoint 1", function()
    if savedWaypoints["Waypoint 1"] then
        startServerSafeTransit(savedWaypoints["Waypoint 1"], "Waypoint 1")
    end
end)

Hub.CreateButton(teleportTab, "💾 Save Waypoint 2 (Current Position)", function()
    local root = getRoot()
    if root then savedWaypoints["Waypoint 2"] = root.Position end
end)
Hub.CreateButton(teleportTab, "✈️ Travel to Waypoint 2", function()
    if savedWaypoints["Waypoint 2"] then
        startServerSafeTransit(savedWaypoints["Waypoint 2"], "Waypoint 2")
    end
end)

Hub.CreateSection(teleportTab, "🏝️ Island Fast Travel Routes")

local islands = {
    ["Spawn Island"] = Vector3.new(0, 50, 0),
    ["Volcano Island"] = Vector3.new(-1200, 75, -800),
    ["Ice Island"] = Vector3.new(1500, 60, -1200),
    ["Desert Island"] = Vector3.new(-900, 50, 1400),
    ["Floating Island (Sky)"] = Vector3.new(0, 500, -500),
    ["Sunken Island (Underwater)"] = Vector3.new(800, -40, 800)
}

for name, pos in pairs(islands) do
    Hub.CreateButton(teleportTab, "🏝️ Safe Travel: " .. name, function()
        startServerSafeTransit(pos, name)
    end)
end

-- =========================================================================
-- 6. MISC TAB: SERVER & UTILITY
-- =========================================================================
Hub.CreateSection(miscTab, "Server & Utility")

Hub.CreateButton(miscTab, "⚡ Rejoin Current Server", function()
    pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end)
end)

Hub.CreateButton(miscTab, "🌐 Server Hop (Low Player Server)", function()
    pcall(function()
        local serversUrl = "https://games.roblox.com/v1/games/" .. tostring(game.PlaceId) .. "/servers/Public?sortOrder=Asc&limit=100"
        local response = HttpService:JSONDecode(game:HttpGet(serversUrl))
        if response and response.data then
            for _, server in ipairs(response.data) do
                if server.playing < server.maxPlayers and server.id ~= game.JobId then
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer)
                    break
                end
            end
        end
    end)
end)

Hub.CreateButton(miscTab, "📋 Copy JobId / Server Code", function()
    pcall(function()
        if setclipboard then
            setclipboard(game.JobId)
        end
    end)
end)

print("[UnknownHub] Booga Booga Script Module v8 Ultimate Edition Loaded Successfully!")
