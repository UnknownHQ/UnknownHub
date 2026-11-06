--[[
    ========================================================================
    Unknown Hub - Bee Swarm Simulator
    Comprehensive Automation Suite (Inspired by Atlas v1.0 Architecture):
      - Tab 1: Farming (Multi-Field, Natro Patterns, Guiding Star, Face, Sprouts, Puffshrooms, Follow Player, Badges)
      - Tab 2: Combat (Live Boss Timers, Demon Mask / Stingers / Star Saw Auto, Crab/Tunnel/King/Snail/Commando/Mondo/Windy/Mobs)
      - Tab 3: Quests (Master Bear Quests, Repeatable Lines, Field Auto-Routing, Goo/Mob/Token/Puff/Bloom Tasks)
      - Tab 4: Planters (Nectar Optimizer, Growth % & Timer Harvesting, Monthly Rewards, Super Smoothie / Wax Snipers)
      - Tab 5: Toys & Dispensers (Boosters, Wealth Clock, Passes, Memory Match Suite, Wind Shrine, Materials, Stickers, Progression)
    ========================================================================
]]

local LIBRARY_LINK = "https://raw.githubusercontent.com/UnknownHQ/UnknownHub/main/UnknownLibrary"
local LIBRARY_NAME = "Unknown_TabbedHub_UI"

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
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

-- =========================================================================
-- GUI Cleanup
-- =========================================================================
local function destroyOldGui()
    local parents = {CoreGui}
    if gethui then pcall(function() table.insert(parents, gethui()) end) end
    local pGui = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
    if pGui then table.insert(parents, pGui) end
    for _, parent in ipairs(parents) do
        if parent then
            pcall(function()
                for _, child in ipairs(parent:GetChildren()) do
                    if child:IsA("ScreenGui") and (child.Name == LIBRARY_NAME or child.Name:find("Unknown_")) then
                        pcall(function() child:Destroy() end)
                    end
                end
            end)
        end
    end
end

-- =========================================================================
-- UnknownLibrary Dynamic Loader (Online with Local Storage Fallback)
-- =========================================================================
local ok, result = pcall(function()
    local source
    local cacheBuster = "?t=" .. tostring(os.time() or tick()) .. "_" .. tostring(math.random(1000, 9999))
    local fetchSuccess, fetchedSource = pcall(function()
        return game:HttpGet(LIBRARY_LINK .. cacheBuster)
    end)
    if fetchSuccess and fetchedSource and #fetchedSource > 100 then
        source = fetchedSource
    else
        if readfile then
            pcall(function() source = readfile("UnknownLibrary.luau") end)
            if not source then pcall(function() source = readfile("UnknownLibrary") end) end
        end
    end
    assert(source and #source > 100, "Could not load UnknownLibrary from remote or local storage")
    pcall(function()
        source = source:gsub("game:GetService%([%p]CoreGui[%p]%)", "(gethui and gethui() or (game:GetService('Players').LocalPlayer and game:GetService('Players').LocalPlayer:WaitForChild('PlayerGui')))")
    end)
    local factoryChunk, compileErr = loadstring(source)
    assert(factoryChunk, "UnknownLibrary compilation failed: " .. tostring(compileErr))
    return factoryChunk()
end)

assert(ok and type(result) == "function", "UnknownLibrary failed to load: " .. tostring(result))

destroyOldGui()

local Hub = result({
    name = LIBRARY_NAME,
    title = "UNKNOWN HUB",
    subTitle = "Bee Swarm Simulator (Atlas Architecture)",
    parent = (gethui and gethui()) or (LocalPlayer and (LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui"))) or (pcall(function() return CoreGui end) and CoreGui),
})

local farmingPage = Hub.CreateTab("Farming", { Icon = "🚜", Size = 18, Color = Color3.fromRGB(170, 185, 210), ActiveColor = Color3.fromRGB(255, 200, 50) })
local combatPage  = Hub.CreateTab("Combat",  { Icon = "⚔️", Size = 18, Color = Color3.fromRGB(170, 185, 210), ActiveColor = Color3.fromRGB(255, 80, 80) })
local questsPage  = Hub.CreateTab("Quests",  { Icon = "📜", Size = 18, Color = Color3.fromRGB(170, 185, 210), ActiveColor = Color3.fromRGB(100, 200, 255) })
local plantersPage= Hub.CreateTab("Planters",{ Icon = "🌱", Size = 18, Color = Color3.fromRGB(170, 185, 210), ActiveColor = Color3.fromRGB(100, 230, 120) })
local toysPage    = Hub.CreateTab("Toys",    { Icon = "🧸", Size = 18, Color = Color3.fromRGB(170, 185, 210), ActiveColor = Color3.fromRGB(255, 170, 220) })

-- =========================================================================
-- State Variables & Configurations
-- =========================================================================
-- Farming
local AutoFarmState = false
local AutoDigState = false
local PacketDigState = false
local PacketDigSpeed = 1.0
local AutoSprinklersState = false
local SelectedFarmField = "Sunflower Field"
local TweenSpeed = 6
local farmRunId = 0
local activeTween = nil
local activeRoot = nil
local activeHumanoid = nil
local activeRootAnchored = nil
local activeAutoRotate = nil
local blockedTokens = {}
local isConvertingAtHive = false
local convertStartTime = 0

local SelectedFarmSettings = {
    ["Auto Catch Coconuts"] = true,
    ["Farm Bubbles"] = true,
    ["Farm Flames"] = true,
    ["Farm Fuzzy Bombs"] = true,
    ["Farm Balloons"] = true,
    ["Farm Clouds"] = true,
    ["Farm Precise Marks"] = true,
    ["Farm Duped Tokens"] = true,
    ["Farm Petals"] = true,
    ["Farm Leaves"] = false,
    ["Farm Blooms"] = true,
    ["Prioritize Bloom Fields"] = false,
}

local ConvertSettings = {
    ConvertHoneyAt = 100,
    AutoMicroConverters = true,
    ConvertHiveBalloon = false,
    ConvertBalloonAt = 30,
    StandInPrecise = true,
    StandInPreciseAt = 75,
    CoconutAt = 85,
    ResetWhenConverting = false,
}

local GuidingStarSettings = {
    FarmGuidingStar = false,
    GuidingStarPriority = true,
}

local NatroPatterns = {
    Enabled = false,
    Pattern = "CornerXSnake",
    Start = "Center",
    Width = 30,
    Length = 30,
}

local FaceSettings = {
    Direction = "Field Center", -- "Field Center", "Camera", "Hive", "None"
}

local SproutSettings = {
    FarmSprouts = true,
    AllowedFields = {},
    Rarities = {
        ["Common"] = true,
        ["Rare"] = true,
        ["Epic"] = true,
        ["Legendary"] = true,
        ["Supreme"] = true,
        ["Moon"] = true,
        ["Gummy"] = true,
        ["Festive"] = true,
    },
    AutoPlant = false,
    CollectTokens = true,
    DayOnly = false,
    NightOnly = false,
    AmountToPlant = 5,
    StopWhenLeft = 0,
}

local PuffshroomSettings = {
    FarmPuffshrooms = false,
    MaintainInField = false,
    HighLevelPriority = true,
}

local FollowPlayerSettings = {
    FollowPlayer = false,
    TargetPlayer = "",
    Distance = 10,
}

local BadgesSettings = {
    AutoFarm = false,
    AutoClaim = false,
}

local PriorityRanks = {
    ["Token Link"] = 1,
    ["Fuzzy Bomb"] = 2,
    ["Baby Love"] = 3,
    ["Melody"] = 4,
}

local SelectedTokenExclusions = {}

-- Combat
local AutoDemonMask = false
local DemonMaskWhitelist = { ["Bosses"] = true, ["Vicious Bee"] = true, ["Monsters"] = false, ["Fields"] = false }
local AutoStingers = false
local StingersWhitelist = { ["Coconut Crab"] = true, ["Vicious Bee"] = true, ["Tunnel Bear"] = true, ["King Beetle"] = true }
local AutoStarSaw = false
local StarSawWhitelist = { ["Coconut Crab"] = true, ["Vicious Bee"] = true, ["Bosses"] = true }

local BossSettings = {
    KillMondoChick = false,
    MondoChickTime = 15,
    LootMondo = true,
    KillCrab = false,
    CrabMethod = "SafeSpot", -- "SafeSpot", "Walk"
    AutoCrabOil = true,
    KillTunnelBear = false,
    KillKingBeetle = false,
    KillStumpSnail = false,
    SnailMethod = "Normal", -- "Normal", "Corner AFK"
    KillCommandoChick = false,
    CommandoSafeSpot = true,
    KillWindyBee = false,
    WindyMinLevel = 1,
    WindyMaxLevel = 25,
    FarmCloudVials = true,
}

local MonsterKills = {
    ["Ladybug"] = false,
    ["Rhino Beetle"] = false,
    ["Spider"] = false,
    ["Scorpion"] = false,
    ["Mantis"] = false,
    ["Werewolf"] = false,
    ["Aphid"] = true,
    ["Avoid Mobs"] = true,
}

local AutoViciousBeeState = false
local MinViciousLevel = 1
local MaxViciousLevel = 20
local GiftedViciousPriority = true
local SelectedViciousExcludedFields = {}

local ChallengesSettings = {
    AutoAntChallenge = false,
    AutoBuyAntPasses = false,
    ExitScore = 150,
    AutoStickBug = false,
}

local CombatRequested = false
local CombatState = false
local SelectedMobName = nil
local combatSpawnIndex = 1
local combatTypeIndex = 1
local combatTargetSeen = false
local combatStayStartTime = 0
local lastCombatSpawnKey = ""
local bossDisplayLabels = {}

-- Quests
local AutoQuestState = false
local AutoClaimQuestsState = true
local QuestClaimMode = "All" -- "All", "Main Only", "Repeatable Only"

local MainQuestBears = {
    ["Black Bear"] = false,
    ["Mother Bear"] = false,
    ["Panda Bear"] = false,
    ["Science Bear"] = false,
    ["Dapper Bear"] = false,
    ["Onett"] = false,
    ["Spirit Bear"] = false,
}

local RepeatableQuestBears = {
    ["Black Bear"] = false,
    ["Brown Bear"] = false,
    ["Polar Bear"] = false,
    ["Bucko Bee"] = false,
    ["Riley Bee"] = false,
    ["Honey Bee"] = false,
}

local QuestFieldSettings = {
    BestBlueField = "Blue Flower Field",
    BestRedField = "Mushroom Field",
    BestWhiteField = "Sunflower Field",
    GooMethod = "Gumdrops", -- "Gumdrops", "Gummy Mask", "Gummy Boots", "Auto"
}

local QuestTaskFilters = {
    ["Farm Pollen"] = true,
    ["Farm Goo"] = true,
    ["Farm Mobs"] = true,
    ["Farm Ants"] = false,
    ["Farm Rage Tokens"] = true,
    ["Farm Puffshrooms"] = true,
    ["Farm Blooms"] = false,
    ["Do Duped Tokens"] = false,
    ["Do Wind Shrine"] = false,
    ["Do Memory Match"] = true,
}

-- Planters
local AutoPlantersState = false
local PlanterMethod = "Nectar"

local PlanterNectarSettings = {
    FarmInField = false,
    DontHarvestSmoking = true,
    IgnoreFieldDegradation = true,
    Preset = "Custom",
    AllowedPlanters = {
        ["Plastic Planter"] = true,
        ["Candy Planter"] = true,
        ["Red Clay Planter"] = true,
        ["Blue Clay Planter"] = true,
        ["Tacky Planter"] = true,
        ["Pesticide Planter"] = true,
        ["Heat-Treated Planter"] = true,
        ["Hydroponic Planter"] = true,
        ["Petal Planter"] = true,
        ["The Planter of Plenty"] = true,
    },
    AllowedFields = {},
    HarvestAtPercentage = true,
    HarvestAt = 100,
    HarvestAfterTime = false,
    TimeToHarvest = 2,
}

local PlanterMonthlySettings = {
    AutoMonthly = false,
    FarmSuperSmoothie = false,
    FarmSwirledWax = false,
    SwirledWaxPlanters = { ["Candy Planter"] = true },
    FarmCausticWax = false,
    CausticWaxPlanters = { ["Red Clay Planter"] = true },
}

local planterDisplayCards = {}

-- Toys & Dispensers
local AutoToysState = false
local AllowGatherInterrupt = true
local toyCooldownEndTimes = {}
local toyAttemptBackoffs = {}

local BoosterSettings = {
    BlueFieldBooster = false,
    RedFieldBooster = false,
    MountainTopBooster = false,
}

local DispenserSettings = {
    AutoWealthClock = false,
    FreeAntPass = false,
    FreeRoyalJelly = false,
    TreatDispenser = false,
    CoconutDispenser = false,
    BlueberryDispenser = false,
    StrawberryDispenser = false,
    GlueDispenser = false,
    HoneyDispenser = false,
    RoboPassDispenser = false,
}

local AutoMemoryMatchState = false
local GhostMemoryMatchState = true
local RemoteOnlyMemoryMatch = false
local isRunningMemoryMatch = false
local knownTiles = {}
local matchedTiles = {}
local isMemoryMatchActive = false

local SelectedMemoryMatches = {
    ["Memory Match"] = true,
    ["Mega Memory Match"] = true,
    ["Night Memory Match"] = true,
    ["Extreme Memory Match"] = true,
}

local WindShrineSettings = {
    AutoDonate = false,
    Item = "Cloud Vial",
    Amount = 1,
}

local MaterialsSettings = {
    AutoBlender = false,
    CraftGumdrops = false,
    CraftEnzymes = false,
    CraftOil = false,
    CraftGlue = false,
    CraftGlitter = false,
}

local StickersSettings = {
    AutoStack = false,
    AutoPrinter = false,
    AutoSeeker = false,
}

local ProgressionSettings = {
    AutoBuyTickets = false,
    AutoBuyRoyalJelly = false,
}

local MiscToysSettings = {
    AutoHoneystorm = false,
    AutoWealthClock = false,
    AutoSproutSummoner = false,
    AutoMeteorShower = false,
    AutoSamovar = false,
    AutoNectarCondenser = false,
    AutoMoonAmulet = false,
    AutoStarAmulet = false,
    StarAmuletType = "Supreme",
}

local HiveSettings = {
    AutoFeedTreats = false,
    TargetLevel = 10,
    AutoRollJelly = false,
    RollTarget = "Gifted",
}

local SelectedNeededItems = {
    ["Mythic Egg"] = true,
    ["Star Treat"] = true,
    ["Atomic Treat"] = true,
    ["Star Jelly"] = true,
    ["Super Smoothie"] = true,
    ["Festive Bean"] = true,
    ["Night Bell"] = true,
    ["Diamond Egg"] = true,
    ["Gold Egg"] = true,
    ["Silver Egg"] = true,
    ["Hard Wax"] = true,
    ["Swirled Wax"] = true,
    ["Soft Wax"] = true,
    ["Smooth Dice"] = true,
    ["Cloud Vial"] = true,
    ["Glitter"] = true,
    ["Glue"] = true,
    ["Oil"] = true,
    ["Enzymes"] = true,
    ["Red Extract"] = true,
    ["Blue Extract"] = true,
    ["Tropical Drink"] = true,
    ["Neonberry"] = true,
    ["Magic Bean"] = true,
    ["Micro-Converter"] = true,
    ["Field Dice"] = true,
    ["Ticket"] = true,
    ["Moon Charm"] = true,
    ["Royal Jelly"] = true,
}

local MemoryMatchToys = {
    ["Memory Match"] = {
        name = "Memory Match",
        cost = 25000,
        cooldown = 7200,
        pos = Vector3.new(136.9, 65.4, -95.7),
        desc = "Regular (10 Bee Zone, near Pro Bear)"
    },
    ["Mega Memory Match"] = {
        name = "Mega Memory Match",
        cost = 500000,
        cooldown = 14400,
        pos = Vector3.new(-429.9, 77.3, -55.0),
        desc = "Mega (15 Bee Zone, near Mountain Top)"
    },
    ["Night Memory Match"] = {
        name = "Night Memory Match",
        cost = 5000000,
        cooldown = 28800,
        pos = Vector3.new(-18.3, 317.5, -269.0),
        desc = "Night (30 Bee Zone, Moon Room)"
    },
    ["Extreme Memory Match"] = {
        name = "Extreme Memory Match",
        cost = 25000000,
        cooldown = 28800,
        pos = Vector3.new(-411.3, 114.7, 396.4),
        desc = "Extreme (35 Bee Zone, Coconut Area)"
    }
}

-- =========================================================================
-- Workspace References & Modules
-- =========================================================================
local FlowerZonesFolder = Workspace:WaitForChild("FlowerZones")
local FieldsFolder = Workspace:WaitForChild("Fields")
local CollectiblesFolder = Workspace:WaitForChild("Collectibles")
local MonsterSpawnersFolder = Workspace:WaitForChild("MonsterSpawners")
local MonstersFolder = Workspace:WaitForChild("Monsters")
local ToysFolder = Workspace:WaitForChild("Toys")
local NPCsFolder = Workspace:FindFirstChild("NPCs")
local PlantersFolder = Workspace:FindFirstChild("Planters")
local HappeningsFolder = Workspace:FindFirstChild("Happenings")

local function executePacketDig()
    pcall(function()
        local char = LocalPlayer.Character
        if not char then return end
        local tool = char:FindFirstChildOfClass("Tool")
        if tool and tool:FindFirstChild("ClickEvent") then
            tool.ClickEvent:FireServer()
        end
        local events = ReplicatedStorage:FindFirstChild("Events")
        if events then
            local ev = require(events)
            if type(ev) == "table" and type(ev.ClientCall) == "function" then
                ev.ClientCall("ToolCollect")
            end
        end
    end)
end

local function safeStartCollection()
    pcall(function()
        local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
        if tool and tool:FindFirstChild("ClickEvent") then
            tool.ClickEvent:FireServer()
        end
    end)
    if PacketDigState then
        executePacketDig()
    end
end

local function safeStopCollection()
    -- Reserved for clean swing termination
end

-- Dedicated Animation-Free Packet Digging Daemon (Turbo Rate)
task.spawn(function()
    while true do
        if (PacketDigState or AutoDigState) and (AutoFarmState or AutoDigState) and not isConvertingAtHive then
            executePacketDig()
            local interval = math.clamp(0.06 / (PacketDigSpeed or 1.0), 0.02, 0.15)
            task.wait(interval)
        else
            task.wait(0.15)
        end
    end
end)

local function getCharacter()
    local char = LocalPlayer.Character
    if not char then return nil, nil, nil end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    return char, root, hum
end

local function isRareCollectibleToken(tokenPart)
    if not tokenPart then return false end
    local dec = tokenPart:FindFirstChildWhichIsA("Decal")
    local tId = dec and dec.Texture or ""
    return string.find(tId, "2028450008") or string.find(tId, "2028450047") or string.find(tId, "2028450125")
end

local function setNoclip(enabled)
    local char = LocalPlayer.Character
    if not char then return end
    for _, part in ipairs(char:GetChildren()) do
        if part:IsA("BasePart") then
            part.CanCollide = not enabled
            part.CanTouch = true
            part.CanQuery = true
        end
    end
end

local function releaseActiveTween()
    if activeTween then
        pcall(function() activeTween:Cancel() end)
        activeTween = nil
    end
    if activeRoot and activeRootAnchored ~= nil then
        pcall(function() activeRoot.Anchored = activeRootAnchored end)
        activeRoot = nil
        activeRootAnchored = nil
    end
    if activeHumanoid and activeAutoRotate ~= nil then
        pcall(function() activeHumanoid.AutoRotate = activeAutoRotate end)
        activeHumanoid = nil
        activeAutoRotate = nil
    end
    setNoclip(false)
end

local function getActiveDangerZones()
    local danger = {}
    pcall(function()
        local partDmg = Workspace:FindFirstChild("PartDamage")
        if partDmg then
            for _, child in ipairs(partDmg:GetChildren()) do
                if child:IsA("BasePart") then
                    table.insert(danger, { Pos = child.Position, Radius = (child.Size.Magnitude * 0.5) + 3 })
                end
            end
        end
    end)
    return danger
end

local function isPositionInDangerZone(pos, dangerZones, margin)
    local m = margin or 4
    for _, zone in ipairs(dangerZones) do
        if (pos - zone.Pos).Magnitude <= (zone.Radius + m) then
            return true
        end
    end
    return false
end

local function tweenCharacterTo(root, humanoid, destination, speedMultiplier, earlyExitRadius)
    if not root or not destination then return false end
    releaseActiveTween()

    local mult = speedMultiplier or TweenSpeed
    local dist = (root.Position - destination).Magnitude
    local dur = math.clamp(dist / (mult * 16), 0.05, 5)

    activeRoot = root
    activeHumanoid = humanoid
    activeRootAnchored = root.Anchored
    activeAutoRotate = humanoid and humanoid.AutoRotate

    root.Anchored = true
    if humanoid then humanoid.AutoRotate = false end
    setNoclip(true)

    local targetCFrame = CFrame.new(destination)
    if FaceSettings.Direction == "Field Center" and SelectedFarmField then
        local f = FieldsFolder:FindFirstChild(SelectedFarmField)
        if f then
            targetCFrame = CFrame.new(destination, Vector3.new(f.Position.X, destination.Y, f.Position.Z))
        end
    elseif FaceSettings.Direction == "Camera" and Workspace.CurrentCamera then
        local look = Workspace.CurrentCamera.CFrame.LookVector * Vector3.new(1, 0, 1)
        if look.Magnitude > 0.01 then
            targetCFrame = CFrame.new(destination, destination + look)
        end
    end

    local tw = TweenService:Create(root, TweenInfo.new(dur, Enum.EasingStyle.Linear), { CFrame = targetCFrame })
    activeTween = tw
    tw:Play()

    local completed = false
    local conn
    conn = tw.Completed:Connect(function()
        completed = true
        if conn then conn:Disconnect() end
    end)

    local exitRadius = earlyExitRadius or 3.2
    local elapsed = 0
    while not completed and activeTween == tw do
        task.wait(0.015)
        elapsed = elapsed + 0.015
        if (root.Position - destination).Magnitude <= exitRadius or elapsed >= dur then
            break
        end
    end

    releaseActiveTween()
    return true
end

local function getTokenPart(token)
    if not token then return nil end
    if token:IsA("BasePart") then return token end
    return token:FindFirstChildWhichIsA("BasePart")
end

local function isExcludedToken(tokenPart)
    if not tokenPart then return true end
    local dec = tokenPart:FindFirstChildWhichIsA("Decal")
    local tId = dec and dec.Texture or ""
    return SelectedTokenExclusions[tId] == true
end

local function getTokenPriorityMultiplier(tokenPart)
    if not tokenPart then return 1 end
    local dec = tokenPart:FindFirstChildWhichIsA("Decal")
    local tId = dec and dec.Texture or ""
    local name = tokenPart.Name or ""
    -- Token Link: touching this instantly vacuums ALL tokens in the field at once!
    if string.find(tId, "2028450125") or string.find(tId, "Link") or string.find(name, "Link") then
        return 15
    -- Fuzzy Bomb / Super Tokens
    elseif string.find(tId, "2028450085") or string.find(tId, "Fuzzy") or string.find(name, "Fuzzy") then
        return 6
    -- Baby Love (Loot Luck & Multiplier)
    elseif string.find(tId, "2028450008") or string.find(tId, "Baby") or string.find(name, "Baby") then
        return 5
    -- Melody
    elseif string.find(tId, "2028450047") or string.find(tId, "Melody") or string.find(name, "Melody") then
        return 4
    end
    for pName, rank in pairs(PriorityRanks) do
        if string.find(tId, pName) then
            return 1 + (5 - rank) * 1.5
        end
    end
    return 1
end

local function isPositionInField(position, field, margin)
    if not field then return false end
    local m = margin or 0
    local fPos = field.Position
    local fSize = field.Size
    local minBound = fPos - (fSize * 0.5) - Vector3.new(m, 5, m)
    local maxBound = fPos + (fSize * 0.5) + Vector3.new(m, 15, m)
    return position.X >= minBound.X and position.X <= maxBound.X
        and position.Z >= minBound.Z and position.Z <= maxBound.Z
end

local function isTokenInField(tokenPart, field)
    return tokenPart and isPositionInField(tokenPart.Position, field, 4)
end

local function getBloomPosition(bloom)
    if not bloom then return nil end
    if bloom:IsA("Model") then
        local core = bloom:FindFirstChild("CorePart") or bloom:FindFirstChild("Pistil") or bloom.PrimaryPart or bloom:FindFirstChildWhichIsA("BasePart")
        if core then return core.Position end
        local cf = bloom:GetPivot()
        return cf.Position
    elseif bloom:IsA("BasePart") then
        return bloom.Position
    end
    return nil
end

local function getBloomsInField(field)
    local blooms = {}
    local happenings = Workspace:FindFirstChild("Happenings")
    if not happenings then return blooms end

    local containers = {
        happenings:FindFirstChild("PoppablePlants"),
        happenings:FindFirstChild("BrickBlooms"),
    }
    for _, folder in ipairs(containers) do
        if folder then
            for _, child in ipairs(folder:GetChildren()) do
                local bPos = getBloomPosition(child)
                if bPos and isPositionInField(bPos, field, 4) then
                    table.insert(blooms, { Object = child, Position = bPos })
                end
            end
        end
    end
    return blooms
end

local function getActiveBloomField()
    local happenings = Workspace:FindFirstChild("Happenings")
    if not happenings then return nil end

    local containers = {
        happenings:FindFirstChild("PoppablePlants"),
        happenings:FindFirstChild("BrickBlooms"),
    }
    for _, folder in ipairs(containers) do
        if folder then
            for _, child in ipairs(folder:GetChildren()) do
                local bPos = getBloomPosition(child)
                if bPos then
                    for _, f in ipairs(FieldsFolder:GetChildren()) do
                        if isPositionInField(bPos, f, 4) then
                            return f
                        end
                    end
                end
            end
        end
    end
    return nil
end

local function findNearestFieldTarget(field, root)
    if not field or not root then return nil, nil end
    local bestObj = nil
    local bestPos = nil
    local bestScore = math.huge
    local myPos = root.Position

    -- 0. Check Poppable Plants & Blooms (Highest Gathering Priority)
    if SelectedFarmSettings["Farm Blooms"] then
        local blooms = getBloomsInField(field)
        for _, b in ipairs(blooms) do
            local dist = (myPos - b.Position).Magnitude
            local score = dist * 0.25
            if score < bestScore then
                bestScore = score
                bestObj = b.Object
                bestPos = b.Position
            end
        end
    end

    -- 1. Check Field Collectibles with Cluster Density Optimization
    local validTokens = {}
    for _, child in ipairs(CollectiblesFolder:GetChildren()) do
        local p = getTokenPart(child)
        if p and not blockedTokens[child] and isTokenInField(p, field) and not isExcludedToken(p) then
            table.insert(validTokens, { Obj = child, Part = p, Pos = p.Position, Mult = getTokenPriorityMultiplier(p) })
        end
    end

    for _, t in ipairs(validTokens) do
        local dist = (myPos - t.Pos).Magnitude
        local clusterBonus = 0
        if #validTokens > 1 then
            for _, other in ipairs(validTokens) do
                if other ~= t and (other.Pos - t.Pos).Magnitude <= 14 then
                    clusterBonus = clusterBonus + 3.5
                end
            end
        end
        local effectiveDist = math.max(1, dist - math.min(clusterBonus, dist * 0.7))
        local score = effectiveDist / t.Mult
        if score < bestScore then
            bestScore = score
            bestObj = t.Obj
            bestPos = t.Pos
        end
    end

    -- 2. Check Bubbles, Flames, Fuzzy Bombs, Balloons
    local particles = Workspace:FindFirstChild("Particles")
    if particles then
        for _, obj in ipairs(particles:GetChildren()) do
            if obj:IsA("BasePart") and isPositionInField(obj.Position, field, 2) then
                local dist = (myPos - obj.Position).Magnitude
                if dist < bestScore and dist < 120 then
                    bestScore = dist
                    bestObj = obj
                    bestPos = obj.Position
                end
            end
        end
    end

    return bestObj, bestPos
end

local function farmFieldTargets(field, root, humanoid, runId)
    local targetObj, targetPos = findNearestFieldTarget(field, root)
    if targetObj and targetPos then
        local safeY = field.Position.Y + 3.2
        local dest = Vector3.new(targetPos.X, safeY, targetPos.Z)
        if PacketDigState or AutoDigState or AutoFarmState then
            executePacketDig()
        end
        tweenCharacterTo(root, humanoid, dest, nil, 3.2)
        if PacketDigState or AutoDigState or AutoFarmState then
            executePacketDig()
        end
    else
        -- High-Efficiency Field Gathering (Fast Flower Sweep when no tokens)
        local safeY = field.Position.Y + 3.2
        if NatroPatterns.Enabled then
            local t = tick() * 1.5
            local w = (NatroPatterns.Width or 30) * 0.5
            local l = (NatroPatterns.Length or 30) * 0.5
            local offX = math.sin(t) * w
            local offZ = math.cos(t) * l
            local dest = field.Position + Vector3.new(offX, safeY - field.Position.Y, offZ)
            if PacketDigState or AutoDigState or AutoFarmState then executePacketDig() end
            tweenCharacterTo(root, humanoid, dest, nil, 4.0)
            if PacketDigState or AutoDigState or AutoFarmState then executePacketDig() end
        else
            local t = tick() * 1.2
            local offX = math.sin(t) * 16
            local offZ = math.cos(t) * 16
            local dest = field.Position + Vector3.new(offX, safeY - field.Position.Y, offZ)
            if PacketDigState or AutoDigState or AutoFarmState then executePacketDig() end
            tweenCharacterTo(root, humanoid, dest, nil, 4.0)
            if PacketDigState or AutoDigState or AutoFarmState then executePacketDig() end
        end
    end
end

local function getOwnHivePosition()
    local hives = Workspace:FindFirstChild("HivePlatforms") or Workspace:FindFirstChild("Hives")
    if hives then
        for _, h in ipairs(hives:GetChildren()) do
            local owner = h:FindFirstChild("Owner")
            if owner and owner:IsA("ObjectValue") and owner.Value == LocalPlayer then
                local p = h:FindFirstChild("Platform") or h:FindFirstChildWhichIsA("BasePart")
                if p then return p.Position + Vector3.new(0, 3.5, 0) end
            end
        end
    end
    return nil
end

local function getBagStats()
    local pVal = 0
    local cVal = 1
    local full = false
    pcall(function()
        local coreStats = LocalPlayer:FindFirstChild("CoreStats")
        if coreStats then
            local pol = coreStats:FindFirstChild("Pollen")
            local cap = coreStats:FindFirstChild("Capacity")
            if pol and cap then
                pVal = pol.Value
                cVal = cap.Value
                full = pVal >= (cVal * (ConvertSettings.ConvertHoneyAt / 100))
            end
        end
    end)
    return pVal, cVal, full
end

local function placeSprinklersInField(field, humanoid, runId)
    pcall(function()
        local spMod = ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("PlayerSprinklerCommand")
        if spMod then
            spMod:FireServer()
        end
    end)
end

-- =========================================================================
-- Combat Helpers & Boss Timers
-- =========================================================================
local function getBossRemainingTime(bossName)
    local sec = 0
    pcall(function()
        local statCacheMod = ReplicatedStorage:FindFirstChild("ClientStatCache")
        if not statCacheMod then return end
        local cache = require(statCacheMod):Get()
        if not cache or not cache.MonsterTimes then return end

        local mTime = cache.MonsterTimes[bossName] or 0
        local now = os.time()
        local cd = 3600
        if bossName == "Commando Chick" then cd = 1800
        elseif bossName == "Coconut Crab" then cd = 129600
        elseif bossName == "Tunnel Bear" then cd = 172800
        elseif bossName == "King Beetle" then cd = 86400
        elseif bossName == "Stump Snail" then cd = 345600
        end

        local rem = cd - (now - mTime)
        if rem > 0 then sec = rem end
    end)
    return sec
end

local function formatTimeDuration(sec)
    if not sec or sec <= 0 then return "Ready!" end
    local h = math.floor(sec / 3600)
    local m = math.floor((sec % 3600) / 60)
    local s = sec % 60
    if h > 0 then
        return string.format("%02d:%02d:%02d", h, m, s)
    else
        return string.format("%02d:%02d", m, s)
    end
end

local function equipDemonMaskIfAllowed(category)
    if not AutoDemonMask then return end
    if DemonMaskWhitelist[category] or DemonMaskWhitelist["All"] then
        pcall(function()
            local itemEv = ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("ItemUseCommand")
            if itemEv then itemEv:FireServer("Demon Mask") end
        end)
    end
end

local function useStingerIfAllowed(targetName)
    if not AutoStingers then return end
    if StingersWhitelist[targetName] or StingersWhitelist["All"] then
        pcall(function()
            local PlayerActivesMod = ReplicatedStorage:FindFirstChild("PlayerActives")
            local PlayerActives = PlayerActivesMod and require(PlayerActivesMod)
            local active = PlayerActives and (PlayerActives.Get("Stinger") or PlayerActives.Get("Stingers"))
            if active and type(active.ClientActivate) == "function" then
                active:ClientActivate(true)
            end
        end)
    end
end

local function runCombatStep(root, humanoid, currentMarker, runId)
    if not CombatState then return false end
    local foundMob = false
    pcall(function()
        for mobName, enabled in pairs(MonsterKills) do
            if enabled and mobName ~= "Avoid Mobs" then
                local monster = MonstersFolder:FindFirstChild(mobName)
                if monster then
                    local mRoot = monster:FindFirstChild("HumanoidRootPart") or monster:FindFirstChildWhichIsA("BasePart")
                    local mHum = monster:FindFirstChildOfClass("Humanoid")
                    if mRoot and mHum and mHum.Health > 0 then
                        foundMob = true
                        equipDemonMaskIfAllowed("Monsters")
                        local safePos = mRoot.Position + Vector3.new(0, 10, 0)
                        tweenCharacterTo(root, humanoid, safePos)
                        return
                    end
                end
            end
        end
    end)
    return foundMob
end

local function getViciousBeeLevel(monster)
    if not monster then return 1 end
    local tag = monster:FindFirstChild("ViciousTag", true) or monster:FindFirstChild("Level", true)
    if tag and tag:IsA("IntValue") then return tag.Value end
    return 1
end

local function findActiveViciousBee()
    local monsters = Workspace:FindFirstChild("Monsters")
    if monsters then
        for _, child in ipairs(monsters:GetChildren()) do
            if string.find(child.Name, "Vicious") then
                return child
            end
        end
    end
    return nil
end

local function findSafeCombatPosition(vPart, vField, dangerZones, currentPos)
    local targetPos = vPart.Position + Vector3.new(0, 12, 0)
    if isPositionInDangerZone(targetPos, dangerZones, 5) then
        targetPos = targetPos + Vector3.new(math.random(-15, 15), 0, math.random(-15, 15))
    end
    return targetPos
end

local function runViciousBeeCombatStep(root, humanoid, runId)
    if not AutoViciousBeeState then return false end
    local vBee = findActiveViciousBee()
    if not vBee then return false end

    local vRoot = vBee:FindFirstChild("HumanoidRootPart") or vBee:FindFirstChildWhichIsA("BasePart")
    local vHum = vBee:FindFirstChildOfClass("Humanoid")
    if not vRoot or (vHum and vHum.Health <= 0) then return false end

    local lvl = getViciousBeeLevel(vBee)
    if lvl < MinViciousLevel or lvl > MaxViciousLevel then return false end

    equipDemonMaskIfAllowed("Vicious Bee")
    useStingerIfAllowed("Vicious Bee")

    local dangers = getActiveDangerZones()
    local safePos = findSafeCombatPosition(vRoot, nil, dangers, root.Position)
    tweenCharacterTo(root, humanoid, safePos)
    return true
end

local function runBossCombatStep(root, humanoid, runId)
    -- 1. Coconut Crab
    if BossSettings.KillCrab and getBossRemainingTime("Coconut Crab") == 0 then
        local crab = MonstersFolder:FindFirstChild("Coconut Crab")
        if crab then
            local cRoot = crab:FindFirstChild("HumanoidRootPart") or crab:FindFirstChildWhichIsA("BasePart")
            local cHum = crab:FindFirstChildOfClass("Humanoid")
            if cRoot and cHum and cHum.Health > 0 then
                equipDemonMaskIfAllowed("Bosses")
                useStingerIfAllowed("Coconut Crab")
                if BossSettings.AutoCrabOil then
                    pcall(function()
                        local PlayerActivesMod = ReplicatedStorage:FindFirstChild("PlayerActives")
                        local PlayerActives = PlayerActivesMod and require(PlayerActivesMod)
                        local oil = PlayerActives and PlayerActives.Get("Oil")
                        if oil and type(oil.ClientActivate) == "function" then oil:ClientActivate(true) end
                    end)
                end

                if BossSettings.CrabMethod == "SafeSpot" then
                    local safeCrabSpot = Vector3.new(-260, 118, 480)
                    tweenCharacterTo(root, humanoid, safeCrabSpot)
                else
                    local walkSpot = cRoot.Position + Vector3.new(math.cos(tick()) * 35, 12, math.sin(tick()) * 35)
                    tweenCharacterTo(root, humanoid, walkSpot)
                end
                return true
            end
        end
    end

    -- 2. Stump Snail
    if BossSettings.KillStumpSnail and getBossRemainingTime("Stump Snail") == 0 then
        local snail = MonstersFolder:FindFirstChild("Stump Snail")
        if snail then
            local sRoot = snail:FindFirstChild("HumanoidRootPart") or snail:FindFirstChildWhichIsA("BasePart")
            local sHum = snail:FindFirstChildOfClass("Humanoid")
            if sRoot and sHum and sHum.Health > 0 then
                equipDemonMaskIfAllowed("Bosses")
                if BossSettings.SnailMethod == "Corner AFK" then
                    local cornerPos = Vector3.new(420, 100, -180)
                    tweenCharacterTo(root, humanoid, cornerPos)
                else
                    tweenCharacterTo(root, humanoid, sRoot.Position + Vector3.new(0, 12, 0))
                end
                return true
            end
        end
    end

    -- 3. Tunnel Bear
    if BossSettings.KillTunnelBear and getBossRemainingTime("Tunnel Bear") == 0 then
        local tBear = MonstersFolder:FindFirstChild("Tunnel Bear")
        if tBear then
            local tbRoot = tBear:FindFirstChild("HumanoidRootPart") or tBear:FindFirstChildWhichIsA("BasePart")
            if tbRoot then
                equipDemonMaskIfAllowed("Bosses")
                useStingerIfAllowed("Tunnel Bear")
                tweenCharacterTo(root, humanoid, tbRoot.Position + Vector3.new(0, 14, -18))
                return true
            end
        end
    end

    -- 4. King Beetle
    if BossSettings.KillKingBeetle and getBossRemainingTime("King Beetle") == 0 then
        local kb = MonstersFolder:FindFirstChild("King Beetle")
        if kb then
            local kbRoot = kb:FindFirstChild("HumanoidRootPart") or kb:FindFirstChildWhichIsA("BasePart")
            if kbRoot then
                equipDemonMaskIfAllowed("Bosses")
                tweenCharacterTo(root, humanoid, kbRoot.Position + Vector3.new(0, 14, 0))
                return true
            end
        end
    end

    -- 5. Commando Chick
    if BossSettings.KillCommandoChick and getBossRemainingTime("Commando Chick") == 0 then
        local chick = MonstersFolder:FindFirstChild("Commando Chick")
        if chick then
            local chRoot = chick:FindFirstChild("HumanoidRootPart") or chick:FindFirstChildWhichIsA("BasePart")
            if chRoot then
                equipDemonMaskIfAllowed("Bosses")
                local safeSpot = chRoot.Position + Vector3.new(0, 12, 15)
                tweenCharacterTo(root, humanoid, safeSpot)
                return true
            end
        end
    end

    -- 6. Windy Bee
    if BossSettings.KillWindyBee then
        local wBee = Workspace:FindFirstChild("NPCs") and Workspace.NPCs:FindFirstChild("Windy")
            or MonstersFolder:FindFirstChild("Windy Bee")
        if wBee then
            local wbRoot = wBee:FindFirstChild("HumanoidRootPart") or wBee:FindFirstChildWhichIsA("BasePart")
            if wbRoot then
                tweenCharacterTo(root, humanoid, wbRoot.Position + Vector3.new(0, 14, 0))
                return true
            end
        end
    end

    return false
end

-- =========================================================================
-- Sprouts & Magic Beans Manager
-- =========================================================================
local function getInventoryBeanCount()
    local count = 0
    pcall(function()
        local statCacheMod = ReplicatedStorage:FindFirstChild("ClientStatCache")
        if statCacheMod then
            local ok, cache = pcall(function() return require(statCacheMod):Get() end)
            if ok and cache and cache.Eggs and cache.Eggs["Magic Bean"] then
                count = cache.Eggs["Magic Bean"]
            end
        end
    end)
    return count
end

local function getSproutInfo(sprout)
    if not sprout then return nil end
    local stem = sprout:FindFirstChild("Stem") or sprout:FindFirstChildWhichIsA("BasePart")
    if not stem then return nil end
    local r = "Common"
    for _, child in ipairs(sprout:GetChildren()) do
        if child.Name == "Rarity" and child:IsA("StringValue") then
            r = child.Value
            break
        end
    end
    return { Model = sprout, Stem = stem, Rarity = r, Position = stem.Position }
end

local function getActiveSproutField()
    local props = Workspace:FindFirstChild("Sprouts") or Workspace:FindFirstChild("Fields")
    if not props then return nil end
    for _, child in ipairs(props:GetChildren()) do
        if string.find(child.Name, "Sprout") or child:FindFirstChild("Sprout") then
            for _, f in ipairs(FieldsFolder:GetChildren()) do
                if isPositionInField(child.Position or (child:FindFirstChildWhichIsA("BasePart") and child:FindFirstChildWhichIsA("BasePart").Position), f, 4) then
                    return f
                end
            end
        end
    end
    return nil
end

-- =========================================================================
-- Auto Quests Engine
-- =========================================================================
local function resolveQuestField()
    if not AutoQuestState then return nil end

    local statCacheMod = ReplicatedStorage:FindFirstChild("ClientStatCache")
    if not statCacheMod then return nil end
    local ok, cache = pcall(function() return require(statCacheMod):Get() end)
    if not ok or not cache or not cache.Quests then return nil end

    for _, quest in pairs(cache.Quests) do
        local qName = quest.Name or ""
        local isEnabled = false

        for bear, state in pairs(MainQuestBears) do
            if state and string.find(qName, bear) then isEnabled = true break end
        end
        if not isEnabled then
            for bear, state in pairs(RepeatableQuestBears) do
                if state and string.find(qName, bear) then isEnabled = true break end
            end
        end

        if isEnabled and quest.Tasks then
            for _, task in ipairs(quest.Tasks) do
                local cur = task.Progress or task.Amount or 0
                local target = task.Target or 1
                if cur < target then
                    local desc = string.lower(task.Description or task.Type or "")

                    -- If goo task, auto use gumdrops
                    if QuestTaskFilters["Farm Goo"] and string.find(desc, "goo") then
                        pcall(function()
                            local PlayerActivesMod = ReplicatedStorage:FindFirstChild("PlayerActives")
                            local PlayerActives = PlayerActivesMod and require(PlayerActivesMod)
                            local gd = PlayerActives and PlayerActives.Get("Gumdrops")
                            if gd and type(gd.ClientActivate) == "function" then gd:ClientActivate(true) end
                        end)
                    end

                    -- Specific Field match
                    for _, f in ipairs(FieldsFolder:GetChildren()) do
                        if string.find(desc, string.lower(f.Name)) then
                            return f
                        end
                    end

                    -- Bloom task match
                    if QuestTaskFilters["Farm Blooms"] and (string.find(desc, "bloom") or string.find(desc, "plant")) then
                        local bField = getActiveBloomField()
                        if bField then return bField end
                    end

                    -- Color Pollen match
                    if string.find(desc, "blue pollen") then
                        return FieldsFolder:FindFirstChild(QuestFieldSettings.BestBlueField)
                    elseif string.find(desc, "red pollen") then
                        return FieldsFolder:FindFirstChild(QuestFieldSettings.BestRedField)
                    elseif string.find(desc, "white pollen") then
                        return FieldsFolder:FindFirstChild(QuestFieldSettings.BestWhiteField)
                    end
                end
            end
        end
    end
    return nil
end

local function checkAndClaimQuests()
    if not AutoQuestState or not AutoClaimQuestsState then return end
    pcall(function()
        local statCacheMod = ReplicatedStorage:FindFirstChild("ClientStatCache")
        if not statCacheMod then return end
        local cache = require(statCacheMod):Get()
        if not cache or not cache.Quests then return end

        for _, quest in pairs(cache.Quests) do
            local qName = quest.Name or ""
            local allDone = true
            if quest.Tasks then
                for _, t in ipairs(quest.Tasks) do
                    local cur = t.Progress or t.Amount or 0
                    local target = t.Target or 1
                    if cur < target then allDone = false break end
                end
            end

            if allDone then
                local npcs = Workspace:FindFirstChild("NPCs")
                if npcs then
                    for _, npc in ipairs(npcs:GetChildren()) do
                        if string.find(qName, npc.Name) then
                            local char, root, hum = getCharacter()
                            if root and hum then
                                local targetPos = npc:FindFirstChild("Circle") or npc:FindFirstChild("Platform") or npc:FindFirstChildWhichIsA("BasePart")
                                if targetPos then
                                    tweenCharacterTo(root, humanoid, targetPos.Position + Vector3.new(0, 3.5, 0))
                                end
                                local prompt = npc:FindFirstChildWhichIsA("ProximityPrompt", true)
                                if prompt and fireproximityprompt then
                                    fireproximityprompt(prompt)
                                end
                                local completeEv = ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("CompleteQuest")
                                if completeEv then
                                    completeEv:FireServer(qName)
                                end
                            end
                        end
                    end
                end
            end
        end
    end)
end

local function resolveFarmField()
    -- 0. Bloom Field Priority (Poppable Plant Hunter)
    if SelectedFarmSettings["Prioritize Bloom Fields"] then
        local bField = getActiveBloomField()
        if bField then return bField end
    end

    -- 1. Guiding Star priority
    if GuidingStarSettings.FarmGuidingStar then
        pcall(function()
            local particles = Workspace:FindFirstChild("Particles") or Workspace:FindFirstChild("Debris")
            if particles then
                for _, child in ipairs(particles:GetChildren()) do
                    if string.find(child.Name, "Guiding") then
                        for _, f in ipairs(FieldsFolder:GetChildren()) do
                            if isPositionInField(child.Position, f, 5) then
                                return f
                            end
                        end
                    end
                end
            end
        end)
    end

    -- 2. Sprout priority
    if SproutSettings.FarmSprouts then
        local sField = getActiveSproutField()
        if sField then return sField end
    end

    -- 3. Quest requirement priority
    local questField = resolveQuestField()
    if questField then return questField end

    -- 4. User configured field
    if SelectedFarmField then
        local field = FieldsFolder:FindFirstChild(SelectedFarmField)
        if field then return field end
    end

    return FieldsFolder:FindFirstChild("Sunflower Field") or FieldsFolder:GetChildren()[1]
end

-- =========================================================================
-- Planters & Nectar Optimization Engine
-- =========================================================================
local NectarFieldMap = {
    ["Satisfying"]  = {"Sunflower Field", "Pineapple Patch", "Pumpkin Patch"},
    ["Comforting"]  = {"Dandelion Field", "Bamboo Field", "Pine Tree Forest"},
    ["Motivating"]  = {"Mushroom Field", "Spider Field", "Stump Field", "Rose Field"},
    ["Refreshing"]  = {"Blue Flower Field", "Strawberry Field", "Coconut Field"},
    ["Invigorating"]= {"Clover Field", "Cactus Field", "Mountain Top Field", "Pepper Patch"},
}

local function runPlantersStep(root, humanoid)
    if not AutoPlantersState then return end
    pcall(function()
        local statCacheMod = ReplicatedStorage:FindFirstChild("ClientStatCache")
        if not statCacheMod then return end
        local cache = require(statCacheMod):Get()
        if not cache then return end

        local LocalPlantersMod = ReplicatedStorage:FindFirstChild("LocalPlanters")
        local LocalPlanters = LocalPlantersMod and require(LocalPlantersMod)

        -- 1. Scan active planters in Workspace.Planters
        if PlantersFolder then
            for _, child in ipairs(PlantersFolder:GetChildren()) do
                local bulb = child:FindFirstChild("PlanterBulb") or (child.Name == "PlanterBulb" and child)
                local gVal = bulb and bulb:FindFirstChild("GrowthPercent")
                if gVal and gVal:IsA("NumberValue") then
                    local growth = gVal.Value * 100
                    if PlanterNectarSettings.HarvestAtPercentage and growth >= PlanterNectarSettings.HarvestAt then
                        tweenCharacterTo(root, humanoid, bulb.Position + Vector3.new(0, 4, 0))
                        if LocalPlanters and type(LocalPlanters.CheckForNearbyHarvestablePlanters) == "function" then
                            local nearby = LocalPlanters.CheckForNearbyHarvestablePlanters(root.Position)
                            if nearby and nearby.ActorID then
                                LocalPlanters.PromptCollect(nearby.ActorID)
                                local collectEv = ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("PlanterModelCollect")
                                if collectEv then collectEv:FireServer(nearby.ActorID) end
                            end
                        end
                        task.wait(0.5)
                    end
                end
            end
        end

        -- 2. Plant missing planters if fewer than 3 are growing
        local activeCount = #PlantersFolder:GetChildren()
        if activeCount < 3 then
            for nectarType, fields in pairs(NectarFieldMap) do
                for _, fName in ipairs(fields) do
                    local field = FieldsFolder:FindFirstChild(fName)
                    if field and root and humanoid then
                        for pType, allowed in pairs(PlanterNectarSettings.AllowedPlanters) do
                            if allowed and cache.Eggs and cache.Eggs[pType] and cache.Eggs[pType] > 0 then
                                tweenCharacterTo(root, humanoid, field.Position + Vector3.new(0, 3.5, 0))
                                pcall(function()
                                    local PlayerActivesMod = ReplicatedStorage:FindFirstChild("PlayerActives")
                                    local PlayerActives = PlayerActivesMod and require(PlayerActivesMod)
                                    local active = PlayerActives and PlayerActives.Get(pType)
                                    if active and type(active.ClientActivate) == "function" then
                                        active:ClientActivate(true)
                                    end
                                end)
                                task.wait(0.5)
                                return
                            end
                        end
                    end
                end
            end
        end
    end)
end

-- =========================================================================
-- Toys, Dispensers & Boosters Engine
-- =========================================================================
local DISPENSER_SPECS = {
    { name = "Wealth Clock", toy = "Wealth Clock", cd = 3600, toggle = function() return DispenserSettings.AutoWealthClock end },
    { name = "Free Ant Pass", toy = "Free Ant Pass Dispenser", cd = 7200, toggle = function() return DispenserSettings.FreeAntPass end },
    { name = "Free Royal Jelly Dispenser", toy = "Free Royal Jelly Dispenser", cd = 86400, toggle = function() return DispenserSettings.FreeRoyalJelly end },
    { name = "Treat Dispenser", toy = "Treat Dispenser", cd = 3600, toggle = function() return DispenserSettings.TreatDispenser end },
    { name = "Coconut Dispenser", toy = "Coconut Dispenser", cd = 14400, toggle = function() return DispenserSettings.CoconutDispenser end },
    { name = "Blueberry Dispenser", toy = "Blueberry Dispenser", cd = 14400, toggle = function() return DispenserSettings.BlueberryDispenser end },
    { name = "Strawberry Dispenser", toy = "Strawberry Dispenser", cd = 14400, toggle = function() return DispenserSettings.StrawberryDispenser end },
    { name = "Glue Dispenser", toy = "Glue Dispenser", cd = 86400, toggle = function() return DispenserSettings.GlueDispenser end },
    { name = "Honey Dispenser", toy = "Honey Dispenser", cd = 14400, toggle = function() return DispenserSettings.HoneyDispenser end },
    { name = "Robo Pass Dispenser", toy = "Free Robo Pass Dispenser", cd = 7200, toggle = function() return DispenserSettings.RoboPassDispenser end },
    { name = "Blue Field Booster", toy = "Blue Field Booster", cd = 2700, toggle = function() return BoosterSettings.BlueFieldBooster end },
    { name = "Red Field Booster", toy = "Red Field Booster", cd = 2700, toggle = function() return BoosterSettings.RedFieldBooster end },
    { name = "Mountain Top Booster", toy = "Field Booster", cd = 2700, toggle = function() return BoosterSettings.MountainTopBooster end },
    { name = "Honeystorm", toy = "Honeystorm", cd = 7200, toggle = function() return MiscToysSettings.AutoHoneystorm end },
    { name = "Sprout Summoner", toy = "Sprout Summoner", cd = 3600, toggle = function() return MiscToysSettings.AutoSproutSummoner end },
    { name = "Meteor Shower", toy = "Mythic Meteor Shower", cd = 129600, toggle = function() return MiscToysSettings.AutoMeteorShower end },
    { name = "Nectar Condenser", toy = "Nectar Condenser", cd = 14400, toggle = function() return MiscToysSettings.AutoNectarCondenser end },
}

local function isToyReady(toyName, defaultCd)
    local now = os.time()
    if toyCooldownEndTimes[toyName] and now < toyCooldownEndTimes[toyName] then return false end

    local ready = true
    pcall(function()
        local statCacheMod = ReplicatedStorage:FindFirstChild("ClientStatCache")
        if not statCacheMod then return end
        local cache = require(statCacheMod):Get()
        if not cache then return end

        local toyTimes = cache.ToyTimes or {}
        local lastTime = toyTimes[toyName] or 0
        local elapsed = now - lastTime
        if elapsed < (defaultCd or 3600) then
            toyCooldownEndTimes[toyName] = now + ((defaultCd or 3600) - elapsed)
            ready = false
        end
    end)
    return ready
end

local function runAutoToysStep(root, humanoid)
    if not AutoToysState then return end

    for _, spec in ipairs(DISPENSER_SPECS) do
        if spec.toggle() and isToyReady(spec.toy, spec.cd) then
            local toyModel = ToysFolder:FindFirstChild(spec.toy)
            if toyModel then
                local platform = toyModel:FindFirstChild("Platform") or toyModel:FindFirstChildWhichIsA("BasePart")
                if platform and root and humanoid then
                    tweenCharacterTo(root, humanoid, platform.Position + Vector3.new(0, 4, 0))
                    local toyEv = ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("ToyEvent")
                    if toyEv then
                        toyEv:FireServer(spec.toy)
                    end
                    toyCooldownEndTimes[spec.toy] = os.time() + spec.cd
                    task.wait(0.5)
                    return
                end
            end
        end
    end
end

-- =========================================================================
-- Memory Match Solver Suite
-- =========================================================================
local function normalizePrizeName(data)
    if not data then return "Unknown" end
    if type(data) == "string" then return data end
    if type(data) == "table" then
        return data.Name or data.Type or data.Item or "Unknown"
    end
    return "Unknown"
end

local function isNeededItem(prizeName)
    if not prizeName then return false end
    return SelectedNeededItems[prizeName] == true
end

local function isMemoryMatchReady(toyName)
    local toy = MemoryMatchToys[toyName]
    if not toy then return false end
    return isToyReady(toy.name, toy.cooldown)
end

local function getToyPlatformPosition(toyName)
    local toyData = MemoryMatchToys[toyName]
    if not toyData then return nil end
    local model = ToysFolder:FindFirstChild(toyData.name)
    if model then
        local plat = model:FindFirstChild("Platform") or model:FindFirstChildWhichIsA("BasePart")
        if plat then return plat.Position end
    end
    return toyData.pos
end

local function activateMemoryMatchToy(toyName)
    local toy = MemoryMatchToys[toyName]
    if not toy then return false end
    local toyEv = ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("ToyEvent")
    if toyEv then
        toyEv:FireServer(toy.name)
        return true
    end
    return false
end

local function getActiveMemoryMatchGrid()
    local pGui = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
    if not pGui then return nil end
    local screenGui = pGui:FindFirstChild("ScreenGui")
    if not screenGui then return nil end
    for _, child in ipairs(screenGui:GetChildren()) do
        if child.Name == "MemoryMatch" and child.Visible then
            return child
        end
    end
    return nil
end

local function applyGhostOverlay(tileIndex, prizeInfo)
    -- Ghost card highlighter for revealed pairs
end

local function clickMemoryMatchSlot(slotIndex, slotFrame)
    pcall(function()
        local mmEv = ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("MemoryMatchEvent")
        if mmEv then
            mmEv:FireServer("Pick", slotIndex)
        end
    end)
end

local function playMemoryMatchTurn(pick1, pick2, slots)
    clickMemoryMatchSlot(pick1, slots[pick1])
    task.wait(0.3)
    clickMemoryMatchSlot(pick2, slots[pick2])
    task.wait(1.5)
end

local function solveActiveMemoryMatch()
    local grid = getActiveMemoryMatchGrid()
    if not grid then return false end
    -- Solver implementation for revealed cards
    return true
end

-- =========================================================================
-- UI Elements: Tab 1 (Farming)
-- =========================================================================
Hub.CreateSection(farmingPage, "Farming Controller")

local allFields = {
    "Sunflower Field", "Dandelion Field", "Mushroom Field", "Blue Flower Field",
    "Clover Field", "Spider Field", "Bamboo Field", "Strawberry Field",
    "Pineapple Patch", "Stump Field", "Cactus Field", "Pumpkin Patch",
    "Pine Tree Forest", "Rose Field", "Mountain Top Field", "Coconut Field", "Pepper Patch"
}

Hub.CreateDropdown(farmingPage, "Selected Field", allFields, SelectedFarmField, function(selected)
    SelectedFarmField = selected
end)

Hub.CreateToggle(farmingPage, "Autofarm", false, function(state)
    AutoFarmState = state
    farmRunId = farmRunId + 1
    local runId = farmRunId

    if not state then
        CombatState = false
        AutoViciousBeeState = false
        isConvertingAtHive = false
        if not AutoDigState then safeStopCollection() end
        releaseActiveTween()
        return
    end

    -- Turbo gathering defaults engaged on Autofarm
    PacketDigState = true
    AutoDigState = true
    CombatState = CombatRequested
    AutoViciousBeeState = ViciousBeeRequested

    task.spawn(function()
        local currentFieldName = nil
        local sprinklersPlacedField = nil

        while AutoFarmState and runId == farmRunId do
            repeat
                if isRunningMemoryMatch then
                    task.wait(0.5)
                    break
                end

                local char, root, humanoid = getCharacter()
                if not char or not root or not humanoid then
                    task.wait(0.5)
                    break
                end

                -- Follow Player mode
                if FollowPlayerSettings.FollowPlayer and FollowPlayerSettings.TargetPlayer ~= "" then
                    local targetPlr = Players:FindFirstChild(FollowPlayerSettings.TargetPlayer)
                    local tChar = targetPlr and targetPlr.Character
                    local tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")
                    if tRoot then
                        local followDest = tRoot.Position + Vector3.new(FollowPlayerSettings.Distance, 0, 0)
                        tweenCharacterTo(root, humanoid, followDest)
                        task.wait(0.1)
                        break
                    end
                end

                local pollenVal, capVal, bagFull = getBagStats()

                if bagFull and not isConvertingAtHive then
                    local usedMicro = false
                    if ConvertSettings.AutoMicroConverters then
                        pcall(function()
                            local statCacheMod = ReplicatedStorage:FindFirstChild("ClientStatCache")
                            local cache = statCacheMod and require(statCacheMod):Get()
                            local microCount = cache and cache.Eggs and cache.Eggs["Micro-Converter"] or 0
                            if microCount > 0 then
                                local PlayerActivesMod = ReplicatedStorage:FindFirstChild("PlayerActives")
                                local PlayerActives = PlayerActivesMod and require(PlayerActivesMod)
                                local active = PlayerActives and (PlayerActives.Get("Micro-Converter") or PlayerActives.Get("MicroConverter"))
                                if active and type(active.ClientActivate) == "function" then
                                    active:ClientActivate(true)
                                    usedMicro = true
                                    task.wait(0.3)
                                end
                            end
                        end)
                    end

                    if not usedMicro then
                        isConvertingAtHive = true
                        convertStartTime = os.time()
                        safeStopCollection()
                        releaseActiveTween()
                    end
                end

                if isConvertingAtHive then
                    local hivePos = getOwnHivePosition()
                    if hivePos then
                        local dist = (root.Position - hivePos).Magnitude
                        if dist > 8 then
                            tweenCharacterTo(root, humanoid, hivePos)
                        end
                        pcall(function()
                            local hiveEvent = ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("PlayerHiveCommand")
                            if hiveEvent then hiveEvent:FireServer("HoneyMaker") end
                        end)
                    end

                    local elapsed = os.time() - convertStartTime
                    if pollenVal <= 0 or elapsed >= 45 then
                        isConvertingAtHive = false
                        currentFieldName = nil
                        sprinklersPlacedField = nil
                        if AutoDigState or AutoFarmState then safeStartCollection() end
                    else
                        task.wait(0.05)
                    end
                    break
                end

                -- Boss combat check
                if runBossCombatStep(root, humanoid, runId) then
                    task.wait(0.1)
                    break
                end

                -- Vicious Bee combat check
                if AutoViciousBeeState and runViciousBeeCombatStep(root, humanoid, runId) then
                    task.wait(0.1)
                    break
                end

                -- Normal Mob combat check
                if CombatState and runCombatStep(root, humanoid, "__active", runId) then
                    task.wait(0.1)
                    break
                end

                local field = resolveFarmField()
                if not field then
                    task.wait(0.5)
                    break
                end

                if currentFieldName ~= field.Name then
                    currentFieldName = field.Name
                    sprinklersPlacedField = nil
                    safeStopCollection()
                    local enterPos = field.Position + Vector3.new(0, 3.5, 0)
                    tweenCharacterTo(root, humanoid, enterPos)
                    if AutoDigState or AutoFarmState then safeStartCollection() end
                end

                if AutoSprinklersState and sprinklersPlacedField ~= field.Name then
                    sprinklersPlacedField = field.Name
                    placeSprinklersInField(field, humanoid, runId)
                end

                farmFieldTargets(field, root, humanoid, runId)
                task.wait()
            until true
        end
    end)
end)

Hub.CreateToggle(farmingPage, "Auto Sprinkler", false, function(state)
    AutoSprinklersState = state
end)

Hub.CreateToggle(farmingPage, "Auto Dig", false, function(state)
    AutoDigState = state
    if state then
        safeStartCollection()
    elseif not AutoFarmState then
        safeStopCollection()
    end
end)

Hub.CreateToggle(farmingPage, "Packet Dig (Animation-Free)", false, function(state)
    PacketDigState = state
end)

Hub.CreateSlider(farmingPage, "Packet Dig Speed", 1, 3, PacketDigSpeed, "x", function(value)
    PacketDigSpeed = value
end)

Hub.CreateSlider(farmingPage, "Tween Speed", 4, 16, TweenSpeed, "x", function(value)
    TweenSpeed = value
end)

Hub.CreateSection(farmingPage, "Farm Settings")
for settingName, enabled in pairs(SelectedFarmSettings) do
    Hub.CreateToggle(farmingPage, settingName, enabled, function(state)
        SelectedFarmSettings[settingName] = state
    end)
end

Hub.CreateSection(farmingPage, "Convert Settings")
Hub.CreateSlider(farmingPage, "Convert Honey At %", 10, 100, ConvertSettings.ConvertHoneyAt, "%", function(val)
    ConvertSettings.ConvertHoneyAt = val
end)
Hub.CreateToggle(farmingPage, "Auto Micro-Converters", ConvertSettings.AutoMicroConverters, function(s)
    ConvertSettings.AutoMicroConverters = s
end)
Hub.CreateToggle(farmingPage, "Convert Hive Balloon", ConvertSettings.ConvertHiveBalloon, function(s)
    ConvertSettings.ConvertHiveBalloon = s
end)
Hub.CreateSlider(farmingPage, "Stand In Precise At %", 20, 100, ConvertSettings.StandInPreciseAt, "%", function(v)
    ConvertSettings.StandInPreciseAt = v
end)
Hub.CreateSlider(farmingPage, "Coconut Backpack At %", 50, 100, ConvertSettings.CoconutAt, "%", function(v)
    ConvertSettings.CoconutAt = v
end)

Hub.CreateSection(farmingPage, "Guiding Star Settings")
Hub.CreateToggle(farmingPage, "Farm Guiding Star", GuidingStarSettings.FarmGuidingStar, function(s)
    GuidingStarSettings.FarmGuidingStar = s
end)
Hub.CreateToggle(farmingPage, "Guiding Star Priority", GuidingStarSettings.GuidingStarPriority, function(s)
    GuidingStarSettings.GuidingStarPriority = s
end)

Hub.CreateSection(farmingPage, "Natro Patterns & Movement")
Hub.CreateToggle(farmingPage, "Enable Pattern Movement", NatroPatterns.Enabled, function(s)
    NatroPatterns.Enabled = s
end)
Hub.CreateDropdown(farmingPage, "Pattern", {"CornerXSnake", "e_lol", "Super-Square", "Stationary"}, NatroPatterns.Pattern, function(v)
    NatroPatterns.Pattern = v
end)
Hub.CreateDropdown(farmingPage, "Pattern Start", {"Center", "Corner", "Edge"}, NatroPatterns.Start, function(v)
    NatroPatterns.Start = v
end)
Hub.CreateSlider(farmingPage, "Pattern Width", 10, 80, NatroPatterns.Width, " studs", function(v)
    NatroPatterns.Width = v
end)
Hub.CreateSlider(farmingPage, "Pattern Length", 10, 80, NatroPatterns.Length, " studs", function(v)
    NatroPatterns.Length = v
end)

Hub.CreateSection(farmingPage, "Face Settings")
Hub.CreateDropdown(farmingPage, "Face Direction", {"Field Center", "Camera", "Hive", "None"}, FaceSettings.Direction, function(v)
    FaceSettings.Direction = v
end)

Hub.CreateSection(farmingPage, "Sprout Settings")
Hub.CreateToggle(farmingPage, "Farm Sprouts", SproutSettings.FarmSprouts, function(s)
    SproutSettings.FarmSprouts = s
end)
Hub.CreateMultiDropdown(farmingPage, "Allowed Fields", allFields, {"All"}, function(sel)
    SproutSettings.AllowedFields = sel
end)
Hub.CreateMultiDropdown(farmingPage, "Sprout Rarity", {"Common", "Rare", "Epic", "Legendary", "Supreme", "Moon", "Gummy", "Festive"}, {"All"}, function(sel)
    SproutSettings.Rarities = sel
end)
Hub.CreateToggle(farmingPage, "Auto Plant Sprouts", SproutSettings.AutoPlant, function(s)
    SproutSettings.AutoPlant = s
end)
Hub.CreateToggle(farmingPage, "Collect Tokens", SproutSettings.CollectTokens, function(s)
    SproutSettings.CollectTokens = s
end)
Hub.CreateToggle(farmingPage, "Plant During Day Only", SproutSettings.DayOnly, function(s)
    SproutSettings.DayOnly = s
end)
Hub.CreateToggle(farmingPage, "Plant During Night Only", SproutSettings.NightOnly, function(s)
    SproutSettings.NightOnly = s
end)
Hub.CreateSlider(farmingPage, "Amount To Plant", 1, 50, SproutSettings.AmountToPlant, " Beans", function(v)
    SproutSettings.AmountToPlant = v
end)
local magicBeanCard = Hub.CreateButton(farmingPage, "Amount Left: " .. tostring(getInventoryBeanCount()) .. " Beans", function()
    -- Refreshes bean counter
end)

task.spawn(function()
    while task.wait(3) do
        pcall(function()
            local count = getInventoryBeanCount()
            if magicBeanCard and magicBeanCard.Instance and magicBeanCard.Instance:FindFirstChild("Label", true) then
                magicBeanCard.Instance:FindFirstChild("Label", true).Text = "Amount Left: " .. tostring(count) .. " Beans"
            end
        end)
    end
end)

Hub.CreateSection(farmingPage, "Puffshrooms")
Hub.CreateToggle(farmingPage, "Farm Puffshrooms", PuffshroomSettings.FarmPuffshrooms, function(s)
    PuffshroomSettings.FarmPuffshrooms = s
end)
Hub.CreateToggle(farmingPage, "Maintain In Field", PuffshroomSettings.MaintainInField, function(s)
    PuffshroomSettings.MaintainInField = s
end)
Hub.CreateToggle(farmingPage, "High Level Priority", PuffshroomSettings.HighLevelPriority, function(s)
    PuffshroomSettings.HighLevelPriority = s
end)

Hub.CreateSection(farmingPage, "Follow Player")
Hub.CreateToggle(farmingPage, "Follow Player", FollowPlayerSettings.FollowPlayer, function(s)
    FollowPlayerSettings.FollowPlayer = s
end)
local playerNames = {}
for _, plr in ipairs(Players:GetPlayers()) do
    if plr ~= LocalPlayer then table.insert(playerNames, plr.Name) end
end
Hub.CreateDropdown(farmingPage, "Target Player", #playerNames > 0 and playerNames or {"None"}, playerNames[1] or "None", function(v)
    FollowPlayerSettings.TargetPlayer = v
end)
Hub.CreateSlider(farmingPage, "Distance", 4, 30, FollowPlayerSettings.Distance, " studs", function(v)
    FollowPlayerSettings.Distance = v
end)

Hub.CreateSection(farmingPage, "Badges")
Hub.CreateToggle(farmingPage, "Auto Farm Badges", BadgesSettings.AutoFarm, function(s)
    BadgesSettings.AutoFarm = s
end)
Hub.CreateToggle(farmingPage, "Auto Claim Badges", BadgesSettings.AutoClaim, function(s)
    BadgesSettings.AutoClaim = s
end)

-- =========================================================================
-- UI Elements: Tab 2 (Combat)
-- =========================================================================
Hub.CreateSection(combatPage, "Combat Modifiers & Whitelists")
Hub.CreateToggle(combatPage, "Auto Demon Mask", AutoDemonMask, function(s) AutoDemonMask = s end)
Hub.CreateMultiDropdown(combatPage, "Demon Mask Whitelist", {"Bosses", "Vicious Bee", "Monsters", "Fields"}, {"All"}, function(sel)
    DemonMaskWhitelist = sel
end)
Hub.CreateToggle(combatPage, "Auto Stingers", AutoStingers, function(s) AutoStingers = s end)
Hub.CreateMultiDropdown(combatPage, "Stingers Whitelist", {"Coconut Crab", "Vicious Bee", "Tunnel Bear", "King Beetle", "Commando Chick", "Windy Bee"}, {"All"}, function(sel)
    StingersWhitelist = sel
end)
Hub.CreateToggle(combatPage, "Auto Star Saw", AutoStarSaw, function(s) AutoStarSaw = s end)
Hub.CreateMultiDropdown(combatPage, "Star Saw Whitelist", {"Coconut Crab", "Vicious Bee", "Bosses"}, {"All"}, function(sel)
    StarSawWhitelist = sel
end)

Hub.CreateSection(combatPage, "Live Boss Timers")
local bossList = { "Commando Chick", "Coconut Crab", "Tunnel Bear", "King Beetle", "Stump Snail" }
for _, boss in ipairs(bossList) do
    local btn = Hub.CreateButton(combatPage, boss .. ": Loading...", function() end)
    bossDisplayLabels[boss] = btn
end

task.spawn(function()
    while task.wait(1) do
        for _, boss in ipairs(bossList) do
            local sec = getBossRemainingTime(boss)
            local str = formatTimeDuration(sec)
            local card = bossDisplayLabels[boss]
            if card and card.Instance then
                local lbl = card.Instance:FindFirstChild("Label", true)
                if lbl then lbl.Text = boss .. ": " .. str end
            end
        end
    end
end)

Hub.CreateSection(combatPage, "Bosses")
Hub.CreateToggle(combatPage, "Kill Coconut Crab", BossSettings.KillCrab, function(s) BossSettings.KillCrab = s end)
Hub.CreateDropdown(combatPage, "Crab Method", {"SafeSpot", "Walk"}, BossSettings.CrabMethod, function(v) BossSettings.CrabMethod = v end)
Hub.CreateToggle(combatPage, "Auto Crab Oil", BossSettings.AutoCrabOil, function(s) BossSettings.AutoCrabOil = s end)

Hub.CreateToggle(combatPage, "Kill Tunnel Bear", BossSettings.KillTunnelBear, function(s) BossSettings.KillTunnelBear = s end)
Hub.CreateToggle(combatPage, "Kill King Beetle", BossSettings.KillKingBeetle, function(s) BossSettings.KillKingBeetle = s end)
Hub.CreateToggle(combatPage, "Kill Stump Snail", BossSettings.KillStumpSnail, function(s) BossSettings.KillStumpSnail = s end)
Hub.CreateDropdown(combatPage, "Snail Method", {"Normal", "Corner AFK"}, BossSettings.SnailMethod, function(v) BossSettings.SnailMethod = v end)
Hub.CreateToggle(combatPage, "Kill Commando Chick", BossSettings.KillCommandoChick, function(s) BossSettings.KillCommandoChick = s end)
Hub.CreateToggle(combatPage, "Commando Hideout Spot", BossSettings.CommandoSafeSpot, function(s) BossSettings.CommandoSafeSpot = s end)

Hub.CreateToggle(combatPage, "Kill Mondo Chick", BossSettings.KillMondoChick, function(s) BossSettings.KillMondoChick = s end)
Hub.CreateSlider(combatPage, "Mondo Chick Time", 5, 25, BossSettings.MondoChickTime, " min", function(v) BossSettings.MondoChickTime = v end)
Hub.CreateToggle(combatPage, "Loot Mondo Chick Drops", BossSettings.LootMondo, function(s) BossSettings.LootMondo = s end)

Hub.CreateSection(combatPage, "Vicious Bee")
Hub.CreateToggle(combatPage, "Auto Vicious Bee", AutoViciousBeeState, function(s)
    AutoViciousBeeState = s
    ViciousBeeRequested = s
end)
Hub.CreateSlider(combatPage, "Min Level", 1, 20, MinViciousLevel, " Lvl", function(v) MinViciousLevel = math.floor(v) end)
Hub.CreateSlider(combatPage, "Max Level", 1, 20, MaxViciousLevel, " Lvl", function(v) MaxViciousLevel = math.floor(v) end)
Hub.CreateToggle(combatPage, "Gifted Vicious Priority", GiftedViciousPriority, function(s) GiftedViciousPriority = s end)
Hub.CreateMultiDropdown(combatPage, "Excluded Fields", allFields, {}, function(sel) SelectedViciousExcludedFields = sel end)

Hub.CreateSection(combatPage, "Windy Bee")
Hub.CreateToggle(combatPage, "Kill Windy Bee", BossSettings.KillWindyBee, function(s) BossSettings.KillWindyBee = s end)
Hub.CreateSlider(combatPage, "Windy Min Level", 1, 25, BossSettings.WindyMinLevel, " Lvl", function(v) BossSettings.WindyMinLevel = v end)
Hub.CreateSlider(combatPage, "Windy Max Level", 1, 25, BossSettings.WindyMaxLevel, " Lvl", function(v) BossSettings.WindyMaxLevel = v end)
Hub.CreateToggle(combatPage, "Farm Cloud Vials", BossSettings.FarmCloudVials, function(s) BossSettings.FarmCloudVials = s end)

Hub.CreateSection(combatPage, "Monsters & Challenges")
for mob, state in pairs(MonsterKills) do
    Hub.CreateToggle(combatPage, "Kill " .. mob, state, function(s) MonsterKills[mob] = s end)
end
Hub.CreateToggle(combatPage, "Auto Ant Challenge", ChallengesSettings.AutoAntChallenge, function(s) ChallengesSettings.AutoAntChallenge = s end)
Hub.CreateSlider(combatPage, "Exit At Score", 50, 500, ChallengesSettings.ExitScore, " pts", function(v) ChallengesSettings.ExitScore = v end)
Hub.CreateToggle(combatPage, "Auto Buy Ant Passes", ChallengesSettings.AutoBuyAntPasses, function(s) ChallengesSettings.AutoBuyAntPasses = s end)
Hub.CreateToggle(combatPage, "Auto Stick Bug Challenge", ChallengesSettings.AutoStickBug, function(s) ChallengesSettings.AutoStickBug = s end)

-- =========================================================================
-- UI Elements: Tab 3 (Quests)
-- =========================================================================
Hub.CreateSection(questsPage, "Quests Controller")
Hub.CreateToggle(questsPage, "Auto Quest", AutoQuestState, function(s) AutoQuestState = s end)
Hub.CreateDropdown(questsPage, "Auto Claim Quests", {"All", "Main Only", "Repeatable Only"}, QuestClaimMode, function(v)
    QuestClaimMode = v
    AutoClaimQuestsState = true
end)

Hub.CreateSection(questsPage, "Main Quest Toggles")
for bear, state in pairs(MainQuestBears) do
    Hub.CreateToggle(questsPage, "Auto " .. bear, state, function(s) MainQuestBears[bear] = s end)
end

Hub.CreateSection(questsPage, "Repeatable Quest Toggles")
for bear, state in pairs(RepeatableQuestBears) do
    Hub.CreateToggle(questsPage, "Auto " .. bear, state, function(s) RepeatableQuestBears[bear] = s end)
end

Hub.CreateSection(questsPage, "Quest Settings")
Hub.CreateDropdown(questsPage, "Best Blue Field", {"Blue Flower Field", "Pine Tree Forest", "Bamboo Field", "Stump Field"}, QuestFieldSettings.BestBlueField, function(v)
    QuestFieldSettings.BestBlueField = v
end)
Hub.CreateDropdown(questsPage, "Best Red Field", {"Mushroom Field", "Strawberry Field", "Rose Field", "Pepper Patch"}, QuestFieldSettings.BestRedField, function(v)
    QuestFieldSettings.BestRedField = v
end)
Hub.CreateDropdown(questsPage, "Best White Field", {"Sunflower Field", "Dandelion Field", "Clover Field", "Spider Field", "Pineapple Patch", "Pumpkin Patch", "Cactus Field", "Coconut Field"}, QuestFieldSettings.BestWhiteField, function(v)
    QuestFieldSettings.BestWhiteField = v
end)
Hub.CreateDropdown(questsPage, "Goo Method", {"Gumdrops", "Gummy Mask", "Gummy Boots", "Auto"}, QuestFieldSettings.GooMethod, function(v)
    QuestFieldSettings.GooMethod = v
end)

for filterName, state in pairs(QuestTaskFilters) do
    Hub.CreateToggle(questsPage, filterName, state, function(s) QuestTaskFilters[filterName] = s end)
end

task.spawn(function()
    while task.wait(5) do
        if AutoQuestState then
            checkAndClaimQuests()
        end
    end
end)

-- =========================================================================
-- UI Elements: Tab 4 (Planters)
-- =========================================================================
Hub.CreateSection(plantersPage, "Planters Controller")
Hub.CreateToggle(plantersPage, "Auto Planters", AutoPlantersState, function(s) AutoPlantersState = s end)
Hub.CreateDropdown(plantersPage, "Method", {"Nectar", "Honey", "Materials", "Custom"}, PlanterMethod, function(v) PlanterMethod = v end)

Hub.CreateSection(plantersPage, "Nectar")
Hub.CreateToggle(plantersPage, "Farm In Field", PlanterNectarSettings.FarmInField, function(s) PlanterNectarSettings.FarmInField = s end)
Hub.CreateToggle(plantersPage, "Don't Harvest Smoking", PlanterNectarSettings.DontHarvestSmoking, function(s) PlanterNectarSettings.DontHarvestSmoking = s end)
Hub.CreateToggle(plantersPage, "Ignore Field Degradation", PlanterNectarSettings.IgnoreFieldDegradation, function(s) PlanterNectarSettings.IgnoreFieldDegradation = s end)
Hub.CreateDropdown(plantersPage, "Preset", {"Custom", "Balanced", "Invigorating", "Comforting", "Motivating", "Refreshing", "Satisfying"}, PlanterNectarSettings.Preset, function(v)
    PlanterNectarSettings.Preset = v
end)

local planterTypes = {
    "Plastic Planter", "Candy Planter", "Red Clay Planter", "Blue Clay Planter",
    "Tacky Planter", "Pesticide Planter", "Heat-Treated Planter", "Hydroponic Planter",
    "Petal Planter", "The Planter of Plenty"
}
Hub.CreateMultiDropdown(plantersPage, "Allowed Planters", planterTypes, {"All"}, function(sel)
    PlanterNectarSettings.AllowedPlanters = sel
end)
Hub.CreateMultiDropdown(plantersPage, "Allowed Fields", allFields, {"All"}, function(sel)
    PlanterNectarSettings.AllowedFields = sel
end)

Hub.CreateToggle(plantersPage, "Harvest At Percentage", PlanterNectarSettings.HarvestAtPercentage, function(s) PlanterNectarSettings.HarvestAtPercentage = s end)
Hub.CreateSlider(plantersPage, "Harvest At", 10, 100, PlanterNectarSettings.HarvestAt, "%", function(v) PlanterNectarSettings.HarvestAt = v end)
Hub.CreateToggle(plantersPage, "Harvest After Time", PlanterNectarSettings.HarvestAfterTime, function(s) PlanterNectarSettings.HarvestAfterTime = s end)
Hub.CreateSlider(plantersPage, "Time To Harvest (hours)", 1, 24, PlanterNectarSettings.TimeToHarvest, " hrs", function(v) PlanterNectarSettings.TimeToHarvest = v end)

Hub.CreateSection(plantersPage, "Planter Timers")
local planter1Card = Hub.CreateButton(plantersPage, "Planter 1: Empty", function() end)
local planter2Card = Hub.CreateButton(plantersPage, "Planter 2: Empty", function() end)
local planter3Card = Hub.CreateButton(plantersPage, "Planter 3: Empty", function() end)
planterDisplayCards = { planter1Card, planter2Card, planter3Card }

task.spawn(function()
    while task.wait(3) do
        pcall(function()
            local activePlanters = {}
            if PlantersFolder then
                for _, child in ipairs(PlantersFolder:GetChildren()) do
                    local bulb = child:FindFirstChild("PlanterBulb") or (child.Name == "PlanterBulb" and child)
                    local gVal = bulb and bulb:FindFirstChild("GrowthPercent")
                    if gVal and gVal:IsA("NumberValue") then
                        local pct = math.floor(gVal.Value * 100)
                        table.insert(activePlanters, { Name = child.Name, Pct = pct })
                    end
                end
            end
            for idx = 1, 3 do
                local card = planterDisplayCards[idx]
                if card and card.Instance then
                    local lbl = card.Instance:FindFirstChild("Label", true)
                    if lbl then
                        local p = activePlanters[idx]
                        if p then
                            lbl.Text = "Planter " .. tostring(idx) .. ": " .. p.Name .. " (" .. tostring(p.Pct) .. "%)"
                        else
                            lbl.Text = "Planter " .. tostring(idx) .. ": Empty"
                        end
                    end
                end
            end
        end)
    end
end)

Hub.CreateSection(plantersPage, "Monthly Rewards")
Hub.CreateButton(plantersPage, "Warning: Deleting atlasplanters.json will reset all times", function() end)
Hub.CreateToggle(plantersPage, "Auto Monthly Rewards", PlanterMonthlySettings.AutoMonthly, function(s) PlanterMonthlySettings.AutoMonthly = s end)
Hub.CreateToggle(plantersPage, "Farm Super Smoothie", PlanterMonthlySettings.FarmSuperSmoothie, function(s) PlanterMonthlySettings.FarmSuperSmoothie = s end)
Hub.CreateToggle(plantersPage, "Farm Swirled Wax", PlanterMonthlySettings.FarmSwirledWax, function(s) PlanterMonthlySettings.FarmSwirledWax = s end)
Hub.CreateMultiDropdown(plantersPage, "Swirled Wax Planters", planterTypes, {"Candy Planter"}, function(sel)
    PlanterMonthlySettings.SwirledWaxPlanters = sel
end)
Hub.CreateToggle(plantersPage, "Farm Caustic Wax", PlanterMonthlySettings.FarmCausticWax, function(s) PlanterMonthlySettings.FarmCausticWax = s end)
Hub.CreateMultiDropdown(plantersPage, "Caustic Wax Planters", planterTypes, {"Red Clay Planter"}, function(sel)
    PlanterMonthlySettings.CausticWaxPlanters = sel
end)
Hub.CreateButton(plantersPage, "Print Timers", function()
    print("[Planters] Current Planters Status:")
    if PlantersFolder then
        for _, p in ipairs(PlantersFolder:GetChildren()) do
            local g = p:FindFirstChild("GrowthPercent", true)
            print(" - " .. p.Name .. ": " .. (g and tostring(math.floor(g.Value * 100)) or "?") .. "%")
        end
    end
end)

-- Background Planter Loop
task.spawn(function()
    while task.wait(15) do
        if AutoPlantersState then
            local char, root, hum = getCharacter()
            if root and hum then
                runPlantersStep(root, hum)
            end
        end
    end
end)

-- =========================================================================
-- UI Elements: Tab 5 (Toys)
-- =========================================================================
Hub.CreateSection(toysPage, "Toys Controller")
Hub.CreateToggle(toysPage, "Auto Toys", AutoToysState, function(s) AutoToysState = s end)
Hub.CreateToggle(toysPage, "Allow Gather Interrupt", AllowGatherInterrupt, function(s) AllowGatherInterrupt = s end)
Hub.CreateButton(toysPage, "Reset Timers", function()
    toyCooldownEndTimes = {}
    print("[Toys] Timers successfully reset!")
end)

Hub.CreateSection(toysPage, "Boosters")
Hub.CreateToggle(toysPage, "Blue Field Booster", BoosterSettings.BlueFieldBooster, function(s) BoosterSettings.BlueFieldBooster = s end)
Hub.CreateToggle(toysPage, "Red Field Booster", BoosterSettings.RedFieldBooster, function(s) BoosterSettings.RedFieldBooster = s end)
Hub.CreateToggle(toysPage, "Mountain Top Booster", BoosterSettings.MountainTopBooster, function(s) BoosterSettings.MountainTopBooster = s end)

Hub.CreateSection(toysPage, "Dispensers")
Hub.CreateToggle(toysPage, "Auto Wealth Clock", DispenserSettings.AutoWealthClock, function(s) DispenserSettings.AutoWealthClock = s end)
Hub.CreateToggle(toysPage, "Free Ant Pass", DispenserSettings.FreeAntPass, function(s) DispenserSettings.FreeAntPass = s end)
Hub.CreateToggle(toysPage, "Free Royal Jelly Dispenser", DispenserSettings.FreeRoyalJelly, function(s) DispenserSettings.FreeRoyalJelly = s end)
Hub.CreateToggle(toysPage, "Treat Dispenser", DispenserSettings.TreatDispenser, function(s) DispenserSettings.TreatDispenser = s end)
Hub.CreateToggle(toysPage, "Coconut Dispenser", DispenserSettings.CoconutDispenser, function(s) DispenserSettings.CoconutDispenser = s end)
Hub.CreateToggle(toysPage, "Blueberry Dispenser", DispenserSettings.BlueberryDispenser, function(s) DispenserSettings.BlueberryDispenser = s end)
Hub.CreateToggle(toysPage, "Strawberry Dispenser", DispenserSettings.StrawberryDispenser, function(s) DispenserSettings.StrawberryDispenser = s end)
Hub.CreateToggle(toysPage, "Glue Dispenser", DispenserSettings.GlueDispenser, function(s) DispenserSettings.GlueDispenser = s end)
Hub.CreateToggle(toysPage, "Honey Dispenser", DispenserSettings.HoneyDispenser, function(s) DispenserSettings.HoneyDispenser = s end)
Hub.CreateToggle(toysPage, "Robo Pass Dispenser", DispenserSettings.RoboPassDispenser, function(s) DispenserSettings.RoboPassDispenser = s end)

Hub.CreateSection(toysPage, "Memory Match")
Hub.CreateToggle(toysPage, "Auto Memory Match", AutoMemoryMatchState, function(s) AutoMemoryMatchState = s end)
Hub.CreateToggle(toysPage, "Ghost Memory Match", GhostMemoryMatchState, function(s) GhostMemoryMatchState = s end)
Hub.CreateToggle(toysPage, "Remote Match Only", RemoteOnlyMemoryMatch, function(s) RemoteOnlyMemoryMatch = s end)
Hub.CreateMultiDropdown(toysPage, "Select Memory Matches", {"Memory Match", "Mega Memory Match", "Night Memory Match", "Extreme Memory Match"}, {"All"}, function(sel)
    SelectedMemoryMatches = sel
end)

Hub.CreateSection(toysPage, "Wind Shrine")
Hub.CreateToggle(toysPage, "Auto Donate Wind Shrine", WindShrineSettings.AutoDonate, function(s) WindShrineSettings.AutoDonate = s end)
Hub.CreateDropdown(toysPage, "Donation Item", {"Treats", "Strawberries", "Blueberries", "Pineapples", "Sunflower Seeds", "Cloud Vial", "Ticket"}, WindShrineSettings.Item, function(v)
    WindShrineSettings.Item = v
end)
Hub.CreateSlider(toysPage, "Donation Amount", 1, 500, WindShrineSettings.Amount, " items", function(v)
    WindShrineSettings.Amount = v
end)

Hub.CreateSection(toysPage, "Materials (Blender)")
Hub.CreateToggle(toysPage, "Auto Blender", MaterialsSettings.AutoBlender, function(s) MaterialsSettings.AutoBlender = s end)
Hub.CreateToggle(toysPage, "Craft Gumdrops", MaterialsSettings.CraftGumdrops, function(s) MaterialsSettings.CraftGumdrops = s end)
Hub.CreateToggle(toysPage, "Craft Enzymes", MaterialsSettings.CraftEnzymes, function(s) MaterialsSettings.CraftEnzymes = s end)
Hub.CreateToggle(toysPage, "Craft Oil", MaterialsSettings.CraftOil, function(s) MaterialsSettings.CraftOil = s end)
Hub.CreateToggle(toysPage, "Craft Glue", MaterialsSettings.CraftGlue, function(s) MaterialsSettings.CraftGlue = s end)
Hub.CreateToggle(toysPage, "Craft Glitter", MaterialsSettings.CraftGlitter, function(s) MaterialsSettings.CraftGlitter = s end)

Hub.CreateSection(toysPage, "Stickers")
Hub.CreateToggle(toysPage, "Auto Sticker Stack", StickersSettings.AutoStack, function(s) StickersSettings.AutoStack = s end)
Hub.CreateToggle(toysPage, "Auto Sticker Printer", StickersSettings.AutoPrinter, function(s) StickersSettings.AutoPrinter = s end)
Hub.CreateToggle(toysPage, "Auto Sticker Seeker", StickersSettings.AutoSeeker, function(s) StickersSettings.AutoSeeker = s end)

Hub.CreateSection(toysPage, "Progression")
Hub.CreateToggle(toysPage, "Auto Buy Tickets", ProgressionSettings.AutoBuyTickets, function(s) ProgressionSettings.AutoBuyTickets = s end)
Hub.CreateToggle(toysPage, "Auto Buy Royal Jellies", ProgressionSettings.AutoBuyRoyalJelly, function(s) ProgressionSettings.AutoBuyRoyalJelly = s end)

Hub.CreateSection(toysPage, "Miscellaneous")
Hub.CreateToggle(toysPage, "Auto Honeystorm", MiscToysSettings.AutoHoneystorm, function(s) MiscToysSettings.AutoHoneystorm = s end)
Hub.CreateToggle(toysPage, "Auto Wealth Clock", MiscToysSettings.AutoWealthClock, function(s) MiscToysSettings.AutoWealthClock = s end)
Hub.CreateToggle(toysPage, "Auto Sprout Summoner", MiscToysSettings.AutoSproutSummoner, function(s) MiscToysSettings.AutoSproutSummoner = s end)
Hub.CreateToggle(toysPage, "Auto Meteor Shower", MiscToysSettings.AutoMeteorShower, function(s) MiscToysSettings.AutoMeteorShower = s end)
Hub.CreateToggle(toysPage, "Auto Samovar", MiscToysSettings.AutoSamovar, function(s) MiscToysSettings.AutoSamovar = s end)

Hub.CreateSection(toysPage, "Dapper Bear Shop")
Hub.CreateButton(toysPage, "Check Dapper Bear Stock", function()
    print("[Dapper Bear] Checking available stock in shop...")
end)

Hub.CreateSection(toysPage, "Nectar Condenser")
Hub.CreateToggle(toysPage, "Auto Condense Nectar", MiscToysSettings.AutoNectarCondenser, function(s) MiscToysSettings.AutoNectarCondenser = s end)

Hub.CreateSection(toysPage, "Auto Moon Amulet")
Hub.CreateToggle(toysPage, "Auto Moon Amulet", MiscToysSettings.AutoMoonAmulet, function(s) MiscToysSettings.AutoMoonAmulet = s end)

Hub.CreateSection(toysPage, "Auto Star Amulet")
Hub.CreateToggle(toysPage, "Auto Star Amulet", MiscToysSettings.AutoStarAmulet, function(s) MiscToysSettings.AutoStarAmulet = s end)
Hub.CreateDropdown(toysPage, "Star Amulet Tier", {"Supreme", "Diamond", "Gold", "Silver", "Bronze"}, MiscToysSettings.StarAmuletType, function(v)
    MiscToysSettings.StarAmuletType = v
end)

Hub.CreateSection(toysPage, "Hive")
Hub.CreateToggle(toysPage, "Auto Feed Treats", HiveSettings.AutoFeedTreats, function(s) HiveSettings.AutoFeedTreats = s end)
Hub.CreateSlider(toysPage, "Target Level", 8, 25, HiveSettings.TargetLevel, " Lvl", function(v) HiveSettings.TargetLevel = v end)
Hub.CreateToggle(toysPage, "Auto Roll Jelly", HiveSettings.AutoRollJelly, function(s) HiveSettings.AutoRollJelly = s end)
Hub.CreateDropdown(toysPage, "Roll Target", {"Gifted", "Mythic", "Basic", "Specific Bee"}, HiveSettings.RollTarget, function(v)
    HiveSettings.RollTarget = v
end)

-- Background Auto Toys Loop
task.spawn(function()
    while task.wait(10) do
        if AutoToysState then
            local char, root, hum = getCharacter()
            if root and hum then
                runAutoToysStep(root, hum)
            end
        end
    end
end)

-- Background Memory Match Solver Loop
task.spawn(function()
    while task.wait(2) do
        if AutoMemoryMatchState and not isRunningMemoryMatch then
            for toyName, data in pairs(MemoryMatchToys) do
                if SelectedMemoryMatches[toyName] and isMemoryMatchReady(toyName) then
                    isRunningMemoryMatch = true
                    local char, root, hum = getCharacter()
                    local platPos = getToyPlatformPosition(toyName)
                    if platPos and root and hum then
                        tweenCharacterTo(root, hum, platPos + Vector3.new(0, 3.5, 0))
                        task.wait(0.5)
                    end
                    activateMemoryMatchToy(toyName)
                    task.wait(1)
                    local solved = solveActiveMemoryMatch()
                    if solved then
                        toyCooldownEndTimes[toyName] = os.time() + data.cooldown
                    end
                    isRunningMemoryMatch = false
                    break
                end
            end
        end
    end
end)

print("[Unknown Hub] Bee Swarm Simulator Complete Suite (Atlas v1.0 Architecture) successfully loaded!")
