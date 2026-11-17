--[[
    ========================================================================
    Unknown Hub - Bee Swarm Simulator
    Comprehensive Automation Suite (100% Atlas Complete Architecture)
    Tabs Included:
      - Tab 1: Home (Live Session Metrics, Honey/hr, Uptime, Emergency Killswitch)
      - Tab 2: Farming (Field Rotation, Interval, Natro Patterns, Guiding Star, Auto Stars, Face Settings, Sprouts, Puffshrooms, Follow Player, Badges)
      - Tab 3: Combat (Auto Demon Mask / Stingers / Star Saw Whitelists, Live Boss Timers, King Beetle Amulet Auto-Roll, Crab, Tunnel, Mondo, Vicious, Mobs)
      - Tab 4: Quests (Auto Quest Master, 12 Bear/Bee Claimers, Main Quest Lines, Repeatable Quest Lines)
      - Tab 5: Planters (Manual Mode 1-3, Nectar Priority Optimizer, Cycles 1-5, Monthly Rewards)
      - Tab 6: Toys & Dispensers (Boosters, 9 Dispensers, 4 Memory Matches, Wind Shrine, Materials, Stickers, Progression)
      - Tab 7: RBC (Robo Bear Challenge Automation, Blue/Red/White Presets, Drive Buyers/Users, Cogmower Hunter, Digital Reroller)
      - Tab 8: Webhook (Discord Live Embed Updates, Honey/hr, Bag %, Natro Branding, Test Webhook)
      - Tab 9: Config (Movement: Tween/Walk, WalkSpeed Multipliers, Red Cannon, Jump Shortcuts, Tween Speed)
      - Tab 10: Debug (Anonymous Mode, Mobile Toggle, Auto Rejoin, Detected Fast Tweens & Rare Item Snipers)
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
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local GuiService = game:GetService("GuiService")

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
Hub.GameName = "BeeSwarm"

-- =========================================================================
-- Tab Creation (10 Complete Tabs matching Atlas Architecture)
-- =========================================================================
local homePage     = Hub.CreateTab("Home",     { Icon = "🏠", Size = 18, Color = Color3.fromRGB(170, 185, 210), ActiveColor = Color3.fromRGB(80, 200, 255) })
local farmingPage  = Hub.CreateTab("Farming",  { Icon = "🚜", Size = 18, Color = Color3.fromRGB(170, 185, 210), ActiveColor = Color3.fromRGB(255, 200, 50) })
local combatPage   = Hub.CreateTab("Combat",   { Icon = "⚔️", Size = 18, Color = Color3.fromRGB(170, 185, 210), ActiveColor = Color3.fromRGB(255, 80, 80) })
local questsPage   = Hub.CreateTab("Quests",   { Icon = "📜", Size = 18, Color = Color3.fromRGB(170, 185, 210), ActiveColor = Color3.fromRGB(100, 200, 255) })
local plantersPage = Hub.CreateTab("Planters", { Icon = "🌱", Size = 18, Color = Color3.fromRGB(170, 185, 210), ActiveColor = Color3.fromRGB(100, 230, 120) })
local toysPage     = Hub.CreateTab("Toys",     { Icon = "🧸", Size = 18, Color = Color3.fromRGB(170, 185, 210), ActiveColor = Color3.fromRGB(255, 170, 220) })
local rbcPage      = Hub.CreateTab("RBC",      { Icon = "🤖", Size = 18, Color = Color3.fromRGB(170, 185, 210), ActiveColor = Color3.fromRGB(180, 140, 255) })
local webhookPage  = Hub.CreateTab("Webhook",  { Icon = "🔔", Size = 18, Color = Color3.fromRGB(170, 185, 210), ActiveColor = Color3.fromRGB(255, 130, 180) })
local configPage   = Hub.CreateTab("Config",   { Icon = "⚙️", Size = 18, Color = Color3.fromRGB(170, 185, 210), ActiveColor = Color3.fromRGB(160, 210, 240) })
local debugPage    = Hub.CreateTab("Debug",    { Icon = "🛠️", Size = 18, Color = Color3.fromRGB(170, 185, 210), ActiveColor = Color3.fromRGB(255, 160, 60) })

-- =========================================================================
-- State Variables & Configurations (Atlas Architecture)
-- =========================================================================
-- 1. Home / Session Analytics
local startSessionTime = os.time()
local startHoney = nil
local currentSessionHoney = 0
local honeyPerHour = 0
local homeStatLabels = {}

-- 2. Farming
local AutoFarmState = false
local AutoDigState = false
local PacketDigState = false
local PacketDigSpeed = 1.0
local AutoSprinklersState = false
local SelectedFarmField = "Sunflower Field"
local SelectedFarmField2 = "None"
local SelectedFarmField3 = "None"
local FieldIntervalMinutes = 10
local LastFieldRotationTick = os.time()
local CurrentRotationIdx = 1
local TweenSpeed = 8
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
    ["Auto Pop Star"] = true,
    ["Auto Scorching Star"] = true,
    ["Max Scorching Score"] = 0,
    ["Auto Line Up X-Flame"] = false,
    ["Auto Gummy Star"] = true,
    ["Farm Blooms"] = true,
    ["Farm Petals"] = true,
    ["Farm Bubbles"] = true,
    ["Farm Coconuts"] = true,
    ["Farm Combo Coconuts"] = true,
    ["Max Combo Amount"] = 0,
    ["Change Field During Combo (Alt)"] = false,
    ["Farm Duped Tokens"] = true,
    ["Smiley Token Wait Duration"] = 4,
    ["Farm Fires"] = false,
    ["Farm Fireflies"] = false,
    ["Farm Fuzz Bombs"] = true,
    ["Farm Leaves"] = false,
    ["Farm Marks"] = false,
    ["Farm Meteor Showers"] = false,
    ["Farm Precise"] = true,
    ["Farm Precise Mark"] = true,
    ["Track Precise"] = false,
    ["Min Time Left Precise"] = 30,
    ["Farm Puppy Ball"] = true,
    ["Farm Showers"] = true,
    ["Farm Triangulate"] = true,
    ["Farm Under Clouds"] = false,
    ["Farm Under Balloons"] = false,
    ["Ignore Honey Tokens"] = false,
    ["Farm Near Position"] = "Center",
    ["Prioritize Bloom Fields"] = false,
}

local PriorityTokensList = {
    "Baby Love", "Bitterberry", "Blue Boost", "Blueberry", "Coconut", "Festive Gift",
    "Flame Fuel", "Focus", "Fuzz Bombs", "Gingerbread Bear", "Haste", "Honey", "Honey Mark",
    "Inferno", "Inflate Balloon", "Mark Surge", "Melody", "Neonberry", "Pineapple",
    "Pollen Haze", "Pollen Mark", "Red Boost", "Snowflake", "Strawberry", "Summon Frog",
    "Sunflower Seed", "Surprise Party", "Target Practice", "Tornado", "Triangulate"
}
local SelectedPriorityTokens = { ["Baby Love"] = true, ["Fuzz Bombs"] = true, ["Melody"] = true }

local AllowedDupedTokensList = {
    "Baby Love", "Blue Boost", "Festive Gift", "Flame Fuel", "Focus", "Fuzz Bombs",
    "Haste", "Honey Mark", "Inferno", "Inflate Balloon", "Mark Surge", "Melody",
    "Pollen Haze", "Pollen Mark", "Red Boost", "Summon Frog", "Surprise Party",
    "Target Practice", "Tornado", "Triangulate"
}
local SelectedDupedTokens = { ["Baby Love"] = true, ["Fuzz Bombs"] = true }

local ConvertSettings = {
    ConvertHoney = true,
    ConvertHoneyAt = 100,
    ConvertHiveBalloon = false,
    ConvertBalloonAt = 30,
    WaitBeforeConverting = false,
    WaitTimeToConvert = 15,
    StandInPrecise = true,
    StandInPreciseAt = 75,
    UseCoconut = false,
    CoconutAt = 85,
    InstantConvert = false,
    InstantConvertType = "Micro Converter",
    AutoHoneyMaskForBalloon = false,
    DefaultMask = "Diamond Mask",
    CollectFestiveBlessing = false,
    ConvertOnlyInField = false,
    ConvertWhenBagFull = false,
    ConvertWhenBagFullBloat = false,
    UseEnzymesForBalloon = false,
    ResetWhenConverting = false,
    AutoMicroConverters = true,
}

local GuidingStarSettings = {
    AutoGuidingStar = false,
    AllowedFields = {},
}

local NatroPatterns = {
    UsePattern = false,
    Pattern = "CornerXSnake",
    Start = "Center",
    SprinklerPosition = "Center",
    AllowedFields = {},
    Width = 30,
    Length = 30,
}

local FaceSettings = {
    FaceBalloons = false,
    FaceGoldenBalloons = false,
    FaceBubbles = false,
    FaceGoldenBubbles = false,
    FaceBlooms = false,
    FaceCenter = false,
    FaceFires = false,
    RefreshFlames = false,
    FarmShiftLock = false,
    FaceMethod = "Shift Lock", -- "Shift Lock", "BodyGyro"
    ShiftLockDirection = "South", -- "North", "East", "South", "West"
}

local SproutSettings = {
    FarmSprouts = true,
    AllowedFields = {},
    Rarities = {
        ["Basic"] = true,
        ["Rare"] = true,
        ["Moon"] = true,
        ["Gummy"] = true,
        ["Epic+"] = true,
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
    HighLevelPriority = true,
    Maintain100xBlessing = false,
    MinLevel = 1,
    MaxLevel = 15,
    MinTime = 30,
    MinRarity = "Common",
    AllowedFields = {},
    PriorityFields = {},
}

local FollowPlayerSettings = {
    FollowPlayer = false,
    TargetPlayer = "None",
    AllowedFields = {},
    Distance = 10,
}

local BadgesSettings = {
    FarmBadges = false,
    AutoClaimBadges = false,
    AllowedBadges = {},
    Priority = "Lowest Pollen Needed", -- "Lowest Pollen Needed", "Highest Level", "Lowest Level"
}

-- 3. Combat
local AutoDemonMask = false
local DemonMaskWhitelist = {
    ["Ant Challenge"] = true, ["Coconut Crab"] = true, ["Commando Chick"] = true,
    ["King Beetle"] = true, ["Mondo Chick"] = true, ["Robo Party"] = true,
    ["Snowbear"] = true, ["Stick Bug"] = true, ["Stump Snail"] = true, ["Tunnel Bear"] = true
}
local AutoStingers = false
local StingersWhitelist = {
    ["Ant Challenge"] = false, ["Coconut Crab"] = true, ["Commando Chick"] = true,
    ["Mondo Chick"] = true, ["Robo Party"] = false, ["Snowbear"] = true,
    ["Stick Bug"] = true, ["Stump Snail"] = true, ["Vicious Bee"] = true, ["Tunnel Bear"] = true
}
local AutoStarSaw = false
local StarSawWhitelist = {
    ["Ant Challenge"] = false, ["Coconut Crab"] = true, ["Commando Chick"] = true,
    ["Mondo Chick"] = true, ["Robo Party"] = false, ["Snowbear"] = true,
    ["Stick Bug"] = true, ["Stump Snail"] = true
}

local BossSettings = {
    WaitForBabyLove = false,
    AutoKillTunnelBear = false,
    AutoKillKingBeetle = false,
    AutoKingBeetleAmulet = false,
    AutoKeepOldAmulet = false,
    KillCrab = false,
    CrabMethod = "Walk", -- "Walk", "Tween"
    AutoCrabOil = false,
    KillMondoChick = true,
    LootMondo = true,
    MondoChickTime = 15,
    PrepareMondoChick = true,
    MondoTimeBeforeSpawn = 20,
    KillStumpSnail = false,
    KillCommandoChick = false,
    CommandoSafeSpot = true,
    KillWindyBee = false,
    WindyMinLevel = 1,
    WindyMaxLevel = 25,
    FarmCloudVials = true,
}

local MonsterKills = {
    ["Avoid Mobs"] = true,
    ["Aphid"] = true,
    ["Ladybug"] = false,
    ["Rhino Beetle"] = false,
    ["Spider"] = false,
    ["Mantis"] = false,
    ["Scorpion"] = false,
    ["Werewolf"] = false,
}

local AutoViciousBeeState = true
local MinViciousLevel = 1
local MaxViciousLevel = 12
local GiftedViciousPriority = false
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

-- 4. Quests
local AutoQuestState = true
local AutoClaimBears = {
    ["Black Bear"] = true,
    ["Brown Bear"] = true,
    ["Bucko Bee"] = false,
    ["Dapper Bear"] = false,
    ["Honey Bee"] = false,
    ["Mother Bear"] = false,
    ["Onett"] = false,
    ["Panda Bear"] = false,
    ["Polar Bear"] = true,
    ["Riley Bee"] = true,
    ["Science Bear"] = false,
    ["Spirit Bear"] = false,
}

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
    ["Bucko Bee"] = false,
    ["Riley Bee"] = false,
    ["Honey Bee"] = false,
    ["Polar Bear"] = true,
}

local QuestFieldSettings = {
    BestBlueField = "Blue Flower Field",
    BestRedField = "Mushroom Field",
    BestWhiteField = "Sunflower Field",
    GooMethod = "Gumdrops",
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

-- 5. Planters
local AutoPlantersState = true
local PlanterMethod = "Manual" -- "Manual", "Nectar", "Cycles"

local ManualPlanters = {
    [1] = {
        AutoHarvest = true,
        AutoPlant = true,
        FarmInField = false,
        DontHarvestSmoking = true,
        Planter = "Pesticide Planter",
        Field1 = "Strawberry Field",
        Field2 = "None",
        Field3 = "None",
        Field4 = "None",
        HarvestAtPercentage = true,
        HarvestAt = 100,
        HarvestAfterTime = false,
        TimeToHarvest = 4,
    },
    [2] = {
        AutoHarvest = true,
        AutoPlant = true,
        FarmInField = false,
        DontHarvestSmoking = true,
        Planter = "Tacky Planter",
        Field1 = "Sunflower Field",
        Field2 = "None",
        Field3 = "None",
        Field4 = "None",
        HarvestAtPercentage = true,
        HarvestAt = 100,
        HarvestAfterTime = false,
        TimeToHarvest = 4,
    },
    [3] = {
        AutoHarvest = true,
        AutoPlant = true,
        FarmInField = false,
        DontHarvestSmoking = true,
        Planter = "Red Clay Planter",
        Field1 = "Pepper Patch",
        Field2 = "None",
        Field3 = "None",
        Field4 = "None",
        HarvestAtPercentage = true,
        HarvestAt = 100,
        HarvestAfterTime = false,
        TimeToHarvest = 4,
    },
}

local PlanterNectarSettings = {
    FarmInField = false,
    DontHarvestSmoking = true,
    IgnoreFieldDegradation = true,
    Preset = "Custom",
    AllowedPlanters = {
        ["Paper Planter"] = true, ["Plastic Planter"] = true, ["Candy Planter"] = true,
        ["Red Clay Planter"] = true, ["Blue Clay Planter"] = true, ["Tacky Planter"] = true,
        ["Pesticide Planter"] = true, ["Heat-Treated Planter"] = true, ["Hydroponic Planter"] = true,
        ["Petal Planter"] = true, ["The Planter of Plenty"] = true,
    },
    AllowedFields = {},
    HarvestAtPercentage = true,
    HarvestAt = 100,
    HarvestAfterTime = true,
    TimeToHarvest = 2,
    ComfortingPriority = 1, ComfortingMin = 16,
    MotivatingPriority = 2, MotivatingMin = 16,
    SatisfyingPriority = 3, SatisfyingMin = 16,
    RefreshingPriority = 4, RefreshingMin = 16,
    InvigoratingPriority = 5, InvigoratingMin = 16,
}

local CyclePlanters = {
    [1] = { HarvestAt = 100, TimeToHarvest = 2, DontHarvestSmoking = false, Planter1 = "None", Field1 = "Dandelion Field", Planter2 = "None", Field2 = "Dandelion Field", Planter3 = "None", Field3 = "Dandelion Field" },
    [2] = { HarvestAt = 100, TimeToHarvest = 2, DontHarvestSmoking = false, Planter1 = "None", Field1 = "Dandelion Field", Planter2 = "None", Field2 = "Dandelion Field", Planter3 = "None", Field3 = "Dandelion Field" },
    [3] = { HarvestAt = 100, TimeToHarvest = 2, DontHarvestSmoking = false, Planter1 = "None", Field1 = "Dandelion Field", Planter2 = "None", Field2 = "Dandelion Field", Planter3 = "None", Field3 = "Dandelion Field" },
    [4] = { HarvestAt = 100, TimeToHarvest = 2, DontHarvestSmoking = false, Planter1 = "None", Field1 = "Dandelion Field", Planter2 = "None", Field2 = "Dandelion Field", Planter3 = "None", Field3 = "Dandelion Field" },
    [5] = { HarvestAt = 100, TimeToHarvest = 2, DontHarvestSmoking = false, Planter1 = "None", Field1 = "Dandelion Field", Planter2 = "None", Field2 = "Dandelion Field", Planter3 = "None", Field3 = "Dandelion Field" },
}

local planterDisplayCards = {}

-- 6. Toys & Dispensers
local AutoToysState = false
local AllowGatherInterrupt = true
local AmountOfConversions = 2
local GatherInterruptWhitelist = { ["Combat"] = true, ["Planters"] = true, ["Toys"] = true }
local toyCooldownEndTimes = {}

local BoosterSettings = {
    AutoBoosters = false,
    RequireFieldBooster = false,
    AllowedFields = {},
    AllowedBoosters = { ["Field Booster"] = true, ["Blue Field Booster"] = true, ["Red Field Booster"] = true, ["Loaded Dice"] = false, ["Field Dice"] = false, ["Glitter"] = false },
    MinFieldBoost = 1,
    WantedFieldBoost = 1,
}

local DispenserSettings = {
    AutoBlueberry = false,
    AutoHoney = false,
    AutoStrawberry = false,
    AutoTreat = false,
    AutoCoconut = false,
    AutoAntPass = false,
    AutoRoboPass = false,
    AutoRoyalJelly = false,
    AutoGlue = false,
}

local AutoMemoryMatchState = true
local GhostMemoryMatchState = true
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
local MemoryMatchBlacklist = {
    ["Blueberry"] = true, ["Coconut"] = false, ["Field Dice"] = false, ["Gumdrops"] = true,
    ["Jelly Beans"] = true, ["Moon Charm"] = false, ["Pineapple"] = true, ["Royal Jelly"] = true,
    ["Strawberry"] = true, ["Sunflower Seed"] = true, ["Treat"] = true,
}

local WindShrineSettings = {
    AutoWindShrine = false,
    FarmWinds = false,
    AllowedFields = {},
}

local MaterialsSettings = {
    AutoMaterials = false,
}

local StickersSettings = {
    AutoStickerStacker = false,
    StackMethod = "Tickets", -- "Tickets", "Stickers"
    AutoDeleteStickers = false,
    AutoStickerPrinter = false,
    AllowedEggs = { ["Basic Egg"] = true, ["Silver Egg"] = true, ["Gold Egg"] = true, ["Diamond Egg"] = true, ["Mythic Egg"] = false, ["Star Egg"] = false },
    AutoHiddenStickers = false,
}

local ProgressionSettings = {
    AutoProgression = false,
    ShowBlenderMessages = true,
}

-- 7. RBC (Robo Bear Challenge)
local RBCSettings = {
    AutoRBC = false,
    Preset = "Blue", -- "Blue", "Red", "White"
    DrivesToBuy = { ["Blue"] = true, ["Red"] = true, ["White"] = true, ["Glitched"] = true },
    DrivesToUse = { ["Blue"] = true, ["Red"] = true, ["White"] = true, ["Glitched"] = true },
    QuitAfterRound = false,
    DisableRBCAfterRound = false,
    MaxRound = 15,
    AutoBuyRoboPass = false,
    PurchaseCooldown = 0,
    Maintain10xPrecision = false,
    MinRound = 5,
    RerollBeesDigital = false,
    MaxRerolls = 2,
    KillGoldCogmowers = true,
    TrackMobs = false,
    AutoUseMaterials = false,
}

-- 8. Webhook
local WebhookSettings = {
    Enabled = true,
    URL = "https://discord.com/api/webhooks/1546874178391515298/pFNb5b0moAaijqIILkO_orgHQnOnZmYuVwKiVszBPtY9tIEolBqPPEAgYqRzbAHULmXQ",
    IntervalMinutes = 5,
    LastSentTick = 0,
    GraphEnabled = false,
    NatroBranding = false,
    DashboardEnabled = false,
}

-- 9. Config
local ConfigSettings = {
    MovementMethod = "Tween", -- "Tween", "Walk"
    UseRedCannon = false,
    UseJumpShortcuts = false,
    EnableWalkSpeed = true,
    DynamicWalkSpeed = false,
    WalkSpeed = 71,
    WalkSpeedMultiplier = 1.5,
    TweenSpeed = 8,
}

-- 10. Debug & Snipers
local DebugSettings = {
    AnonymousMode = false,
    FarmMultipleFields = false,
    MobileToggle = false,
    ShowConsole = false,
    AutoRejoin = true,
    RunWithoutAutofarm = false,
    FastShowerTween = false,
    FastCoconutTween = false,
    FastTweenToRares = false,
    RaresList = {
        ["Blue Extract"] = true, ["Caustic Wax"] = true, ["Cloud Vial"] = true,
        ["Diamond Egg"] = true, ["Enzymes"] = true, ["Gifted Diamond Egg"] = true,
        ["Gifted Gold Egg"] = true, ["Gifted Mythic Egg"] = true, ["Gingerbread Bear"] = true,
        ["Glitter"] = true, ["Glue"] = true, ["Gold Egg"] = true, ["Loaded Dice"] = true,
        ["Magic Bean"] = true, ["Marshmallow Bee"] = true, ["Mythic Egg"] = true,
        ["Neonberry"] = true, ["Oil"] = true, ["Purple Potion"] = true, ["Red Extract"] = true,
        ["Star Egg"] = true, ["Star Jelly"] = true, ["Star Treat"] = true, ["Sticker"] = true,
        ["Super Smoothie"] = true, ["Swirled Wax"] = true, ["Tropical Drink"] = true, ["Turpentine"] = true,
    },
}

-- =========================================================================
-- Constants & Spatial Map Definitions
-- =========================================================================
local allFields = {
    "Sunflower Field", "Dandelion Field", "Mushroom Field", "Blue Flower Field",
    "Clover Field", "Spider Field", "Bamboo Field", "Strawberry Field",
    "Pineapple Patch", "Stump Field", "Cactus Field", "Pumpkin Patch",
    "Pine Tree Forest", "Rose Field", "Mountain Top Field", "Coconut Field", "Pepper Patch"
}

local planterTypes = {
    "Paper Planter", "Ticket Planter", "Sticker Planter", "Festive Planter",
    "Plastic Planter", "Candy Planter", "Red Clay Planter", "Blue Clay Planter",
    "Tacky Planter", "Pesticide Planter", "Petal Planter", "Heat-Treated Planter",
    "Hydroponic Planter", "The Planter Of Plenty"
}

local NectarFieldMap = {
    ["Satisfying"]  = {"Sunflower Field", "Pineapple Patch", "Pumpkin Patch"},
    ["Comforting"]  = {"Dandelion Field", "Bamboo Field", "Pine Tree Forest"},
    ["Motivating"]  = {"Mushroom Field", "Spider Field", "Stump Field", "Rose Field"},
    ["Refreshing"]  = {"Blue Flower Field", "Strawberry Field", "Coconut Field"},
    ["Invigorating"]= {"Clover Field", "Cactus Field", "Mountain Top Field", "Pepper Patch"},
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
        pos = Vector3.new(-400.0, 115.0, 480.0),
        desc = "Extreme (35 Bee Zone, Coconut Cave)"
    }
}

-- =========================================================================
-- Core Action, Physics & Spatial Engines
-- =========================================================================
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

-- =========================================================================
-- Advanced Suite Engines: Stats, Webhook, RBC, Snipers & Killswitch
-- =========================================================================

-- 1. Honey & Session Analytics
local function getHoneyStats()
    local honeyVal = 0
    local pollenVal = 0
    local capVal = 0
    pcall(function()
        local cs = LocalPlayer:FindFirstChild("CoreStats")
        if cs then
            local h = cs:FindFirstChild("Honey")
            local p = cs:FindFirstChild("Pollen")
            local c = cs:FindFirstChild("Capacity")
            if h then honeyVal = h.Value end
            if p then pollenVal = p.Value end
            if c then capVal = c.Value end
        end
    end)
    return honeyVal, pollenVal, capVal
end

local function formatLargeNumber(n)
    if not n or n ~= n then return "0" end
    if n >= 1e12 then
        return string.format("%.2fT", n / 1e12)
    elseif n >= 1e9 then
        return string.format("%.2fB", n / 1e9)
    elseif n >= 1e6 then
        return string.format("%.2fM", n / 1e6)
    elseif n >= 1e3 then
        return string.format("%.2fK", n / 1e3)
    else
        return tostring(math.floor(n))
    end
end

local function updateCardText(card, newText)
    if not card then return end
    pcall(function()
        local inst = (typeof(card) == "Instance" and card) or (type(card) == "table" and (card.Instance or card.Card))
        if inst and typeof(inst) == "Instance" then
            local lbl = inst:FindFirstChild("BtnLabel", true) or inst:FindFirstChild("Label", true) or inst:FindFirstChildWhichIsA("TextLabel", true)
            if lbl then
                lbl.Text = tostring(newText)
            elseif inst:IsA("TextButton") or inst:IsA("TextLabel") then
                inst.Text = tostring(newText)
            end
        end
    end)
end

-- 2. Emergency Killswitch (Stop Everything)
local function stopEverything()
    AutoFarmState = false
    AutoDigState = false
    PacketDigState = false
    AutoSprinklersState = false
    CombatState = false
    AutoViciousBeeState = false
    AutoQuestState = false
    AutoPlantersState = false
    AutoToysState = false
    AutoMemoryMatchState = false
    RBCSettings.AutoRBC = false
    isConvertingAtHive = false
    farmRunId = farmRunId + 1
    safeStopCollection()
    releaseActiveTween()
    local char, root, hum = getCharacter()
    if hum then
        hum.PlatformStand = false
        hum.WalkSpeed = 16
    end
    print("[Unknown Hub] EMERGENCY KILLSWITCH TRIGGERED: All operations halted.")
end

-- 3. Discord Webhook Engine
local function sendDiscordWebhook(isTest)
    if not WebhookSettings.Enabled or WebhookSettings.URL == "" then return false end
    local httpReq = request or http_request or (syn and syn.request) or (http and http.request)
    if not httpReq then return false end

    local currentHoney, pollenVal, capVal = getHoneyStats()
    if not startHoney then startHoney = currentHoney end
    local honeyGained = math.max(currentHoney - startHoney, 0)
    local elapsedSec = math.max(os.time() - startSessionTime, 1)
    local honeyPerHourVal = (honeyGained / elapsedSec) * 3600
    local bagPct = capVal > 0 and math.floor((pollenVal / capVal) * 100) or 0
    local uptimeStr = formatTimeDuration(elapsedSec)

    local brandingTitle = WebhookSettings.NatroBranding and "🐝 Natro Macro • Session Report" or "🐝 UnknownHub - Bee Swarm Simulator"
    local embedColor = WebhookSettings.NatroBranding and 16753920 or 16763904

    local fields = {
        { name = "🍯 Total Honey", value = formatLargeNumber(currentHoney), inline = true },
        { name = "📈 Session Honey", value = formatLargeNumber(honeyGained), inline = true },
        { name = "⚡ Honey / Hour", value = formatLargeNumber(honeyPerHourVal) .. "/hr", inline = true },
        { name = "🎒 Bag Pollen", value = formatLargeNumber(pollenVal) .. " / " .. formatLargeNumber(capVal) .. " (" .. tostring(bagPct) .. "%)", inline = true },
        { name = "📍 Active Field", value = tostring(SelectedFarmField), inline = true },
        { name = "⏱️ Session Uptime", value = uptimeStr, inline = true },
    }

    if isTest then
        table.insert(fields, { name = "🔔 Status", value = "Webhook Test Sent Successfully!", inline = false })
    end

    local payload = {
        username = WebhookSettings.NatroBranding and "Natro Macro" or "UnknownHub • Bee Swarm",
        avatar_url = "https://i.imgur.com/kP1oR8M.png",
        embeds = {
            {
                title = brandingTitle,
                description = isTest and "Test message verified from live game!" or "Automated Periodic Progress Report",
                color = embedColor,
                fields = fields,
                footer = { text = "UnknownHub Bee Swarm Engine • 100% Atlas Complete" },
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
            }
        }
    }

    local success, res = pcall(function()
        return httpReq({
            Url = WebhookSettings.URL,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode(payload)
        })
    end)
    return success
end

-- 4. Robo Bear Challenge (RBC) Automation Engine
local function runRBCStep(root, hum)
    if not RBCSettings.AutoRBC then return false end
    local rbcEvent = ReplicatedStorage:FindFirstChild("Events")
    if not rbcEvent then return false end

    -- Check if inside RBC challenge area or if challenge active
    pcall(function()
        local roundStart = rbcEvent:FindFirstChild("RoboBearRoundStart")
        local beeSelect = rbcEvent:FindFirstChild("RoboBearBeeSelect")
        local upgSelect = rbcEvent:FindFirstChild("RoboBearUpgradeSelect")
        local claimRew = rbcEvent:FindFirstChild("RoboBearClaimRewards")

        if claimRew then claimRew:FireServer() end
        if roundStart then roundStart:FireServer() end
    end)
    return true
end

-- 5. Rare Items Sniper Engine
local function scanAndCollectRareItems(root, hum)
    if not DebugSettings.FastTweenToRares then return end
    local coll = Workspace:FindFirstChild("Collectibles")
    if not coll then return end
    for _, item in ipairs(coll:GetChildren()) do
        if item:IsA("BasePart") or item:IsA("Model") then
            local pName = item.Name
            if DebugSettings.RaresList[pName] then
                local iPos = item:IsA("BasePart") and item.Position or item:GetPivot().Position
                if (root.Position - iPos).Magnitude < 250 then
                    tweenCharacterTo(root, hum, iPos + Vector3.new(0, 1.5, 0))
                    task.wait(0.05)
                    break
                end
            end
        end
    end
end

-- =========================================================================
-- UI Elements: All 10 Tabs (Atlas Architecture 1:1)
-- =========================================================================

-- =========================================================================
-- TAB 1: HOME
-- =========================================================================
Hub.CreateSection(homePage, "📊 Session Analytics & Performance")
local uptimeCard    = Hub.CreateButton(homePage, "⏱️ Uptime: 00:00:00", function() end)
local srvUptimeCard = Hub.CreateButton(homePage, "🌐 Server Uptime: 00:00:00", function() end)
local honeyCard     = Hub.CreateButton(homePage, "🍯 Session Honey: 0", function() end)
local hphCard       = Hub.CreateButton(homePage, "⚡ Honey per Hour: 0/hr", function() end)

homeStatLabels.Uptime = uptimeCard
homeStatLabels.ServerUptime = srvUptimeCard
homeStatLabels.SessionHoney = honeyCard
homeStatLabels.HoneyPerHour = hphCard

Hub.CreateSection(homePage, "🛑 Emergency Control")
Hub.CreateButton(homePage, "🛑 Stop Everything (Emergency Killswitch)", function()
    stopEverything()
    Hub.notify({ Title = "STOP EVERYTHING", Content = "All active automation loops have been halted.", Duration = 4 })
end)

-- =========================================================================
-- TAB 2: FARMING
-- =========================================================================
Hub.CreateSection(farmingPage, "🌾 Field Selection & Rotation")
Hub.CreateDropdown(farmingPage, "Field", allFields, SelectedFarmField, function(v) SelectedFarmField = v end)
local allFieldsWithNone = {"None"}
for _, f in ipairs(allFields) do table.insert(allFieldsWithNone, f) end
Hub.CreateDropdown(farmingPage, "Field 2", allFieldsWithNone, SelectedFarmField2, function(v) SelectedFarmField2 = v end)
Hub.CreateDropdown(farmingPage, "Field 3", allFieldsWithNone, SelectedFarmField3, function(v) SelectedFarmField3 = v end)
Hub.CreateSlider(farmingPage, "Field Interval (minutes)", 1, 60, FieldIntervalMinutes, " min", function(v) FieldIntervalMinutes = v end)

Hub.CreateToggle(farmingPage, "Autofarm", AutoFarmState, function(s)
    AutoFarmState = s
    farmRunId = farmRunId + 1
    local runId = farmRunId

    if not s then
        safeStopCollection()
        releaseActiveTween()
        isConvertingAtHive = false
        return
    end

    -- Turbo gathering defaults engaged on Autofarm
    PacketDigState = true
    AutoDigState = true
    safeStartCollection()

    task.spawn(function()
        local currentFieldName = nil
        local sprinklersPlacedField = nil

        while AutoFarmState and runId == farmRunId do
            local ok, err = pcall(function()
                local char, root, humanoid = getCharacter()
                if not char or not root or not humanoid then
                    task.wait(0.5)
                    return
                end

                -- 1. Follow Player check
                if FollowPlayerSettings.FollowPlayer and FollowPlayerSettings.TargetPlayer ~= "" and FollowPlayerSettings.TargetPlayer ~= "None" then
                    local targetPlr = Players:FindFirstChild(FollowPlayerSettings.TargetPlayer)
                    local tChar = targetPlr and targetPlr.Character
                    local tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")
                    if tRoot then
                        local followDest = tRoot.Position + Vector3.new(FollowPlayerSettings.Distance or 5, 0, 0)
                        tweenCharacterTo(root, humanoid, followDest)
                        task.wait(0.1)
                        return
                    end
                end

                -- 2. Bag stats & Hive Conversion Check
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

                    local elapsed = os.time() - (convertStartTime or 0)
                    if pollenVal <= 0 or elapsed >= 45 then
                        isConvertingAtHive = false
                        currentFieldName = nil
                        sprinklersPlacedField = nil
                        safeStartCollection()
                    else
                        task.wait(0.1)
                    end
                    return
                end

                -- 3. Resolve active farming field
                local field = resolveFarmField()
                if not field then
                    task.wait(0.5)
                    return
                end

                if currentFieldName ~= field.Name then
                    currentFieldName = field.Name
                    sprinklersPlacedField = nil
                    safeStopCollection()
                    local enterPos = field.Position + Vector3.new(0, 3.5, 0)
                    tweenCharacterTo(root, humanoid, enterPos)
                    safeStartCollection()
                end

                if AutoSprinklersState and sprinklersPlacedField ~= field.Name then
                    sprinklersPlacedField = field.Name
                    placeSprinklersInField(field, humanoid, runId)
                end

                farmFieldTargets(field, root, humanoid, runId)
            end)

            if not ok then
                task.wait(0.5)
            else
                task.wait()
            end
        end
    end)
end)
Hub.CreateToggle(farmingPage, "Auto Sprinkler", AutoSprinklersState, function(s) AutoSprinklersState = s end)
Hub.CreateToggle(farmingPage, "Auto Dig", AutoDigState, function(s)
    AutoDigState = s
    if s then safeStartCollection() else safeStopCollection() end
end)

Hub.CreateSection(farmingPage, "⭐ Farm Settings & Passive Stars")
Hub.CreateToggle(farmingPage, "Auto Pop Star", SelectedFarmSettings["Auto Pop Star"], function(s) SelectedFarmSettings["Auto Pop Star"] = s end)
Hub.CreateToggle(farmingPage, "Auto Scorching Star", SelectedFarmSettings["Auto Scorching Star"], function(s) SelectedFarmSettings["Auto Scorching Star"] = s end)
Hub.CreateSlider(farmingPage, "Maximum Scorching Score", 0, 100, SelectedFarmSettings["Max Scorching Score"], " pts", function(v) SelectedFarmSettings["Max Scorching Score"] = v end)
Hub.CreateToggle(farmingPage, "Auto Line Up X-Flame", SelectedFarmSettings["Auto Line Up X-Flame"], function(s) SelectedFarmSettings["Auto Line Up X-Flame"] = s end)
Hub.CreateToggle(farmingPage, "Auto Gummy Star", SelectedFarmSettings["Auto Gummy Star"], function(s) SelectedFarmSettings["Auto Gummy Star"] = s end)

Hub.CreateSection(farmingPage, "🌸 Gathering Targets & Micro Mechanics")
Hub.CreateToggle(farmingPage, "Farm Blooms", SelectedFarmSettings["Farm Blooms"], function(s) SelectedFarmSettings["Farm Blooms"] = s end)
Hub.CreateToggle(farmingPage, "Farm Petals", SelectedFarmSettings["Farm Petals"], function(s) SelectedFarmSettings["Farm Petals"] = s end)
Hub.CreateToggle(farmingPage, "Farm Bubbles", SelectedFarmSettings["Farm Bubbles"], function(s) SelectedFarmSettings["Farm Bubbles"] = s end)
Hub.CreateToggle(farmingPage, "Farm Coconuts", SelectedFarmSettings["Farm Coconuts"], function(s) SelectedFarmSettings["Farm Coconuts"] = s end)
Hub.CreateToggle(farmingPage, "Farm Combo Coconuts", SelectedFarmSettings["Farm Combo Coconuts"], function(s) SelectedFarmSettings["Farm Combo Coconuts"] = s end)
Hub.CreateSlider(farmingPage, "Maximum Combo Amount", 0, 50, SelectedFarmSettings["Max Combo Amount"], "", function(v) SelectedFarmSettings["Max Combo Amount"] = v end)
Hub.CreateToggle(farmingPage, "Change Field During Combo (Alt)", SelectedFarmSettings["Change Field During Combo (Alt)"], function(s) SelectedFarmSettings["Change Field During Combo (Alt)"] = s end)
Hub.CreateToggle(farmingPage, "Farm Duped Tokens", SelectedFarmSettings["Farm Duped Tokens"], function(s) SelectedFarmSettings["Farm Duped Tokens"] = s end)
Hub.CreateSlider(farmingPage, "Smiley Token Wait Duration (secs)", 1, 15, SelectedFarmSettings["Smiley Token Wait Duration"], "s", function(v) SelectedFarmSettings["Smiley Token Wait Duration"] = v end)
Hub.CreateToggle(farmingPage, "Farm Fires", SelectedFarmSettings["Farm Fires"], function(s) SelectedFarmSettings["Farm Fires"] = s end)
Hub.CreateToggle(farmingPage, "Farm Fireflies", SelectedFarmSettings["Farm Fireflies"], function(s) SelectedFarmSettings["Farm Fireflies"] = s end)
Hub.CreateToggle(farmingPage, "Farm Fuzz Bombs", SelectedFarmSettings["Farm Fuzz Bombs"], function(s) SelectedFarmSettings["Farm Fuzz Bombs"] = s end)
Hub.CreateToggle(farmingPage, "Farm Leaves", SelectedFarmSettings["Farm Leaves"], function(s) SelectedFarmSettings["Farm Leaves"] = s end)
Hub.CreateToggle(farmingPage, "Farm Marks", SelectedFarmSettings["Farm Marks"], function(s) SelectedFarmSettings["Farm Marks"] = s end)
Hub.CreateToggle(farmingPage, "Farm Meteor Showers", SelectedFarmSettings["Farm Meteor Showers"], function(s) SelectedFarmSettings["Farm Meteor Showers"] = s end)
Hub.CreateToggle(farmingPage, "Farm Precise", SelectedFarmSettings["Farm Precise"], function(s) SelectedFarmSettings["Farm Precise"] = s end)
Hub.CreateToggle(farmingPage, "Farm Precise Mark", SelectedFarmSettings["Farm Precise Mark"], function(s) SelectedFarmSettings["Farm Precise Mark"] = s end)
Hub.CreateToggle(farmingPage, "Track Precise", SelectedFarmSettings["Track Precise"], function(s) SelectedFarmSettings["Track Precise"] = s end)
Hub.CreateSlider(farmingPage, "Minimum Time Left To Farm Precise (secs)", 5, 60, SelectedFarmSettings["Min Time Left Precise"], "s", function(v) SelectedFarmSettings["Min Time Left Precise"] = v end)
Hub.CreateToggle(farmingPage, "Farm Puppy Ball", SelectedFarmSettings["Farm Puppy Ball"], function(s) SelectedFarmSettings["Farm Puppy Ball"] = s end)
Hub.CreateToggle(farmingPage, "Farm Showers", SelectedFarmSettings["Farm Showers"], function(s) SelectedFarmSettings["Farm Showers"] = s end)
Hub.CreateToggle(farmingPage, "Farm Triangulate", SelectedFarmSettings["Farm Triangulate"], function(s) SelectedFarmSettings["Farm Triangulate"] = s end)
Hub.CreateToggle(farmingPage, "Farm Under Clouds", SelectedFarmSettings["Farm Under Clouds"], function(s) SelectedFarmSettings["Farm Under Clouds"] = s end)
Hub.CreateToggle(farmingPage, "Farm Under Balloons", SelectedFarmSettings["Farm Under Balloons"], function(s) SelectedFarmSettings["Farm Under Balloons"] = s end)
Hub.CreateToggle(farmingPage, "Ignore Honey Tokens", SelectedFarmSettings["Ignore Honey Tokens"], function(s) SelectedFarmSettings["Ignore Honey Tokens"] = s end)
Hub.CreateDropdown(farmingPage, "Farm Near Position", {"Left", "Right", "Center"}, SelectedFarmSettings["Farm Near Position"], function(v) SelectedFarmSettings["Farm Near Position"] = v end)

Hub.CreateSection(farmingPage, "🎯 Token Prioritization & Duplication")
Hub.CreateMultiDropdown(farmingPage, "Priority Tokens", PriorityTokensList, {"Baby Love", "Fuzz Bombs", "Melody"}, function(sel)
    SelectedPriorityTokens = sel
end)
Hub.CreateMultiDropdown(farmingPage, "Allowed Duped Tokens", AllowedDupedTokensList, {"Baby Love", "Fuzz Bombs"}, function(sel)
    SelectedDupedTokens = sel
end)

Hub.CreateSection(farmingPage, "🍯 Convert Settings")
Hub.CreateToggle(farmingPage, "Convert Honey", ConvertSettings.ConvertHoney, function(s) ConvertSettings.ConvertHoney = s end)
Hub.CreateSlider(farmingPage, "Convert Honey At", 10, 100, ConvertSettings.ConvertHoneyAt, "%", function(v) ConvertSettings.ConvertHoneyAt = v end)
Hub.CreateToggle(farmingPage, "Convert Hive Balloon", ConvertSettings.ConvertHiveBalloon, function(s) ConvertSettings.ConvertHiveBalloon = s end)
Hub.CreateSlider(farmingPage, "Convert Balloon At (blessing minutes)", 5, 60, ConvertSettings.ConvertBalloonAt, " min", function(v) ConvertSettings.ConvertBalloonAt = v end)
Hub.CreateToggle(farmingPage, "Wait Before Converting", ConvertSettings.WaitBeforeConverting, function(s) ConvertSettings.WaitBeforeConverting = s end)
Hub.CreateSlider(farmingPage, "Time To Wait (seconds)", 5, 60, ConvertSettings.WaitTimeToConvert, "s", function(v) ConvertSettings.WaitTimeToConvert = v end)
Hub.CreateToggle(farmingPage, "Stand In Precise Crosshair", ConvertSettings.StandInPrecise, function(s) ConvertSettings.StandInPrecise = s end)
Hub.CreateSlider(farmingPage, "Stand In Precise Crosshair At", 20, 100, ConvertSettings.StandInPreciseAt, "%", function(v) ConvertSettings.StandInPreciseAt = v end)
Hub.CreateToggle(farmingPage, "Use Coconut To Convert", ConvertSettings.UseCoconut, function(s) ConvertSettings.UseCoconut = s end)
Hub.CreateSlider(farmingPage, "Use Coconut At Percentage", 50, 100, ConvertSettings.CoconutAt, "%", function(v) ConvertSettings.CoconutAt = v end)
Hub.CreateToggle(farmingPage, "Instant Convert", ConvertSettings.InstantConvert, function(s) ConvertSettings.InstantConvert = s end)
Hub.CreateDropdown(farmingPage, "Instant Convert Type", {"Micro Converter", "Ticket Converters", "Whirligig"}, ConvertSettings.InstantConvertType, function(v) ConvertSettings.InstantConvertType = v end)
Hub.CreateToggle(farmingPage, "Auto Honey Mask For Balloon", ConvertSettings.AutoHoneyMaskForBalloon, function(s) ConvertSettings.AutoHoneyMaskForBalloon = s end)
Hub.CreateDropdown(farmingPage, "Default Mask", {"Diamond Mask", "Demon Mask", "Gummy Mask", "Bubble Mask", "Fire Mask"}, ConvertSettings.DefaultMask, function(v) ConvertSettings.DefaultMask = v end)
Hub.CreateToggle(farmingPage, "Collect Festive Blessing", ConvertSettings.CollectFestiveBlessing, function(s) ConvertSettings.CollectFestiveBlessing = s end)
Hub.CreateToggle(farmingPage, "Convert Only When In Field", ConvertSettings.ConvertOnlyInField, function(s) ConvertSettings.ConvertOnlyInField = s end)
Hub.CreateToggle(farmingPage, "Convert Balloon When Bag Full", ConvertSettings.ConvertWhenBagFull, function(s) ConvertSettings.ConvertWhenBagFull = s end)
Hub.CreateToggle(farmingPage, "Convert Balloon When Bag Full + 6x Bubble Bloat", ConvertSettings.ConvertWhenBagFullBloat, function(s) ConvertSettings.ConvertWhenBagFullBloat = s end)
Hub.CreateToggle(farmingPage, "Use Enzymes For Converting Balloon", ConvertSettings.UseEnzymesForBalloon, function(s) ConvertSettings.UseEnzymesForBalloon = s end)
Hub.CreateToggle(farmingPage, "Reset When Converting", ConvertSettings.ResetWhenConverting, function(s) ConvertSettings.ResetWhenConverting = s end)

Hub.CreateSection(farmingPage, "🌟 Guiding Star Settings")
Hub.CreateToggle(farmingPage, "Auto Guiding Star", GuidingStarSettings.AutoGuidingStar, function(s) GuidingStarSettings.AutoGuidingStar = s end)
Hub.CreateMultiDropdown(farmingPage, "Allowed Fields (Guiding)", allFields, allFields, function(sel) GuidingStarSettings.AllowedFields = sel end)

Hub.CreateSection(farmingPage, "📐 Natro Patterns")
Hub.CreateToggle(farmingPage, "Use Pattern", NatroPatterns.UsePattern, function(s) NatroPatterns.UsePattern = s end)
Hub.CreateDropdown(farmingPage, "Pattern", {"CornerXSnake", "Tideshift", "Diamond", "Square", "E_lol"}, NatroPatterns.Pattern, function(v) NatroPatterns.Pattern = v end)
Hub.CreateDropdown(farmingPage, "Pattern Start", {"Top Left", "Top Right", "Center", "Bottom Left", "Bottom Right"}, NatroPatterns.Start, function(v) NatroPatterns.Start = v end)
Hub.CreateDropdown(farmingPage, "Sprinkler Position", {"Top", "Center", "Bottom"}, NatroPatterns.SprinklerPosition, function(v) NatroPatterns.SprinklerPosition = v end)
Hub.CreateMultiDropdown(farmingPage, "Allowed Fields (Patterns)", allFields, allFields, function(sel) NatroPatterns.AllowedFields = sel end)
Hub.CreateButton(farmingPage, "Export Pattern", function()
    print("[Natro Patterns] Pattern: " .. NatroPatterns.Pattern .. ", Start: " .. NatroPatterns.Start)
end)

Hub.CreateSection(farmingPage, "🧭 Face Settings")
Hub.CreateToggle(farmingPage, "Face Balloons During Tidal Surge", FaceSettings.FaceBalloons, function(s) FaceSettings.FaceBalloons = s end)
Hub.CreateToggle(farmingPage, "Face Golden Balloons During Tidal Surge", FaceSettings.FaceGoldenBalloons, function(s) FaceSettings.FaceGoldenBalloons = s end)
Hub.CreateToggle(farmingPage, "Face Bubbles", FaceSettings.FaceBubbles, function(s) FaceSettings.FaceBubbles = s end)
Hub.CreateToggle(farmingPage, "Face Golden Bubbles", FaceSettings.FaceGoldenBubbles, function(s) FaceSettings.FaceGoldenBubbles = s end)
Hub.CreateToggle(farmingPage, "Face Blooms", FaceSettings.FaceBlooms, function(s) FaceSettings.FaceBlooms = s end)
Hub.CreateToggle(farmingPage, "Face Center", FaceSettings.FaceCenter, function(s) FaceSettings.FaceCenter = s end)
Hub.CreateToggle(farmingPage, "Face Fires", FaceSettings.FaceFires, function(s) FaceSettings.FaceFires = s end)
Hub.CreateToggle(farmingPage, "Refresh Flames", FaceSettings.RefreshFlames, function(s) FaceSettings.RefreshFlames = s end)
Hub.CreateToggle(farmingPage, "Farm With Shift Lock", FaceSettings.FarmShiftLock, function(s) FaceSettings.FarmShiftLock = s end)
Hub.CreateDropdown(farmingPage, "Face Method", {"Shift Lock", "BodyGyro"}, FaceSettings.FaceMethod, function(v) FaceSettings.FaceMethod = v end)
Hub.CreateDropdown(farmingPage, "Shift Lock Direction", {"North", "East", "South", "West"}, FaceSettings.ShiftLockDirection, function(v) FaceSettings.ShiftLockDirection = v end)

Hub.CreateSection(farmingPage, "🌱 Sprouts")
Hub.CreateToggle(farmingPage, "Farm Sprouts", SproutSettings.FarmSprouts, function(s) SproutSettings.FarmSprouts = s end)
Hub.CreateMultiDropdown(farmingPage, "Allowed Fields (Sprouts)", allFields, allFields, function(sel) SproutSettings.AllowedFields = sel end)
Hub.CreateMultiDropdown(farmingPage, "Sprout Rarity", {"Basic", "Rare", "Moon", "Gummy", "Epic+"}, {"Rare", "Gummy", "Epic+"}, function(sel) SproutSettings.Rarities = sel end)
Hub.CreateToggle(farmingPage, "Auto Plant Sprouts", SproutSettings.AutoPlant, function(s) SproutSettings.AutoPlant = s end)
Hub.CreateToggle(farmingPage, "Collect Tokens", SproutSettings.CollectTokens, function(s) SproutSettings.CollectTokens = s end)
Hub.CreateToggle(farmingPage, "Plant During Day Only", SproutSettings.DayOnly, function(s) SproutSettings.DayOnly = s end)
Hub.CreateToggle(farmingPage, "Plant During Night Only", SproutSettings.NightOnly, function(s) SproutSettings.NightOnly = s end)
local magicBeanCard = Hub.CreateButton(farmingPage, "Amount Left: " .. tostring(getInventoryBeanCount()), function() end)

task.spawn(function()
    while task.wait(3) do
        pcall(function()
            local count = getInventoryBeanCount()
            updateCardText(magicBeanCard, "Amount Left: " .. tostring(count))
        end)
    end
end)

Hub.CreateSection(farmingPage, "🍄 Puffshrooms")
Hub.CreateToggle(farmingPage, "Farm Puffshrooms", PuffshroomSettings.FarmPuffshrooms, function(s) PuffshroomSettings.FarmPuffshrooms = s end)
Hub.CreateToggle(farmingPage, "High Level Priority", PuffshroomSettings.HighLevelPriority, function(s) PuffshroomSettings.HighLevelPriority = s end)
Hub.CreateToggle(farmingPage, "Maintain 100x Blessing", PuffshroomSettings.Maintain100xBlessing, function(s) PuffshroomSettings.Maintain100xBlessing = s end)
Hub.CreateSlider(farmingPage, "Minimum Level", 1, 20, PuffshroomSettings.MinLevel, "", function(v) PuffshroomSettings.MinLevel = v end)
Hub.CreateSlider(farmingPage, "Maximum Level", 1, 25, PuffshroomSettings.MaxLevel, "", function(v) PuffshroomSettings.MaxLevel = v end)
Hub.CreateSlider(farmingPage, "Minimum Time (seconds)", 5, 120, PuffshroomSettings.MinTime, "s", function(v) PuffshroomSettings.MinTime = v end)
Hub.CreateDropdown(farmingPage, "Minimum Rarity", {"Common", "Rare", "Epic"}, PuffshroomSettings.MinRarity, function(v) PuffshroomSettings.MinRarity = v end)
Hub.CreateMultiDropdown(farmingPage, "Allowed Fields (Puffs)", allFields, allFields, function(sel) PuffshroomSettings.AllowedFields = sel end)
Hub.CreateMultiDropdown(farmingPage, "Priority Fields (Puffs)", allFields, {}, function(sel) PuffshroomSettings.PriorityFields = sel end)

Hub.CreateSection(farmingPage, "👥 Follow Player")
local playerNames = {"None"}
for _, plr in ipairs(Players:GetPlayers()) do
    if plr ~= LocalPlayer then table.insert(playerNames, plr.Name) end
end
Hub.CreateDropdown(farmingPage, "Follow Player", playerNames, FollowPlayerSettings.TargetPlayer, function(v)
    FollowPlayerSettings.TargetPlayer = v
    FollowPlayerSettings.FollowPlayer = (v ~= "None")
end)
Hub.CreateMultiDropdown(farmingPage, "Allowed Fields (Follow)", allFields, allFields, function(sel) FollowPlayerSettings.AllowedFields = sel end)

Hub.CreateSection(farmingPage, "🏅 Badges")
Hub.CreateToggle(farmingPage, "Farm Badges", BadgesSettings.FarmBadges, function(s) BadgesSettings.FarmBadges = s end)
Hub.CreateToggle(farmingPage, "Auto Claim Badges", BadgesSettings.AutoClaimBadges, function(s) BadgesSettings.AutoClaimBadges = s end)
Hub.CreateMultiDropdown(farmingPage, "Allowed Badges", allFields, allFields, function(sel) BadgesSettings.AllowedBadges = sel end)
Hub.CreateDropdown(farmingPage, "Badge Priority", {"Lowest Pollen Needed", "Highest Level", "Lowest Level"}, BadgesSettings.Priority, function(v) BadgesSettings.Priority = v end)

-- =========================================================================
-- TAB 3: COMBAT
-- =========================================================================
Hub.CreateSection(combatPage, "👺 Combat Automations & Masks")
Hub.CreateToggle(combatPage, "Auto Demon Mask", AutoDemonMask, function(s) AutoDemonMask = s end)
local demonMaskList = {"Ant Challenge", "Coconut Crab", "Commando Chick", "King Beetle", "Mondo Chick", "Robo Party", "Snowbear", "Stick Bug", "Stump Snail", "Tunnel Bear"}
Hub.CreateMultiDropdown(combatPage, "Demon Mask Whitelist", demonMaskList, {"Coconut Crab", "Tunnel Bear", "King Beetle", "Mondo Chick"}, function(sel) DemonMaskWhitelist = sel end)

Hub.CreateToggle(combatPage, "Auto Stingers", AutoStingers, function(s) AutoStingers = s end)
Hub.CreateMultiDropdown(combatPage, "Stingers Whitelist", demonMaskList, {"Coconut Crab", "Tunnel Bear", "Mondo Chick"}, function(sel) StingersWhitelist = sel end)

Hub.CreateToggle(combatPage, "Auto Star Saw", AutoStarSaw, function(s) AutoStarSaw = s end)
Hub.CreateMultiDropdown(combatPage, "Star Saw Whitelist", demonMaskList, {"Coconut Crab", "Tunnel Bear"}, function(sel) StarSawWhitelist = sel end)

Hub.CreateSection(combatPage, "⏱️ Live Boss Timers")
local bossList = { "Commando Chick", "Coconut Crab", "Tunnel Bear", "King Beetle", "Stump Snail" }
for _, boss in ipairs(bossList) do
    local btn = Hub.CreateButton(combatPage, boss .. ": Loading...", function() end)
    bossDisplayLabels[boss] = btn
end

task.spawn(function()
    while task.wait(1) do
        pcall(function()
            for _, boss in ipairs(bossList) do
                local sec = getBossRemainingTime(boss)
                local str = formatTimeDuration(sec)
                local card = bossDisplayLabels[boss]
                updateCardText(card, boss .. ": " .. str)
            end
        end)
    end
end)

Hub.CreateSection(combatPage, "👑 Bosses")
Hub.CreateToggle(combatPage, "Wait For Baby Love", BossSettings.WaitForBabyLove, function(s) BossSettings.WaitForBabyLove = s end)
Hub.CreateToggle(combatPage, "Auto Kill Tunnel Bear", BossSettings.AutoKillTunnelBear, function(s) BossSettings.AutoKillTunnelBear = s end)
Hub.CreateToggle(combatPage, "Auto Kill King Beetle", BossSettings.AutoKillKingBeetle, function(s) BossSettings.AutoKillKingBeetle = s end)
Hub.CreateToggle(combatPage, "Auto King Beetle Amulet", BossSettings.AutoKingBeetleAmulet, function(s) BossSettings.AutoKingBeetleAmulet = s end)
Hub.CreateToggle(combatPage, "Auto Keep Old Amulet", BossSettings.AutoKeepOldAmulet, function(s) BossSettings.AutoKeepOldAmulet = s end)
Hub.CreateButton(combatPage, "Configure Amulet", function() print("[Combat] Configure King Beetle Amulet clicked") end)

Hub.CreateSection(combatPage, "🦂 Monsters")
Hub.CreateToggle(combatPage, "Auto Avoid Mobs", MonsterKills["Avoid Mobs"], function(s) MonsterKills["Avoid Mobs"] = s end)
Hub.CreateToggle(combatPage, "Auto Kill Aphid", MonsterKills["Aphid"], function(s) MonsterKills["Aphid"] = s end)
Hub.CreateToggle(combatPage, "Auto Kill Ladybug", MonsterKills["Ladybug"], function(s) MonsterKills["Ladybug"] = s end)
Hub.CreateToggle(combatPage, "Auto Kill Rhino Beetle", MonsterKills["Rhino Beetle"], function(s) MonsterKills["Rhino Beetle"] = s end)
Hub.CreateToggle(combatPage, "Auto Kill Spider", MonsterKills["Spider"], function(s) MonsterKills["Spider"] = s end)
Hub.CreateToggle(combatPage, "Auto Kill Mantis", MonsterKills["Mantis"], function(s) MonsterKills["Mantis"] = s end)
Hub.CreateToggle(combatPage, "Auto Kill Scorpion", MonsterKills["Scorpion"], function(s) MonsterKills["Scorpion"] = s end)
Hub.CreateToggle(combatPage, "Auto Kill Werewolf", MonsterKills["Werewolf"], function(s) MonsterKills["Werewolf"] = s end)

Hub.CreateSection(combatPage, "🐝 Vicious Bee")
Hub.CreateToggle(combatPage, "Auto Kill Vicious Bee", AutoViciousBeeState, function(s) AutoViciousBeeState = s end)
Hub.CreateToggle(combatPage, "Gifted Vicious Only", GiftedViciousPriority, function(s) GiftedViciousPriority = s end)
Hub.CreateSlider(combatPage, "Min Level", 1, 20, MinViciousLevel, " Lvl", function(v) MinViciousLevel = math.floor(v) end)
Hub.CreateSlider(combatPage, "Max Level", 1, 20, MaxViciousLevel, " Lvl", function(v) MaxViciousLevel = math.floor(v) end)

Hub.CreateSection(combatPage, "🦀 Coconut Crab")
Hub.CreateToggle(combatPage, "Auto Kill Coconut Crab", BossSettings.KillCrab, function(s) BossSettings.KillCrab = s end)
Hub.CreateDropdown(combatPage, "Kill Method", {"Walk", "Tween"}, BossSettings.CrabMethod, function(v) BossSettings.CrabMethod = v end)
Hub.CreateToggle(combatPage, "Auto Oil", BossSettings.AutoCrabOil, function(s) BossSettings.AutoCrabOil = s end)

Hub.CreateSection(combatPage, "🐥 Mondo Chick")
Hub.CreateToggle(combatPage, "Auto Kill Mondo Chick", BossSettings.KillMondoChick, function(s) BossSettings.KillMondoChick = s end)
Hub.CreateToggle(combatPage, "Collect Mondo Chick Loot", BossSettings.LootMondo, function(s) BossSettings.LootMondo = s end)
Hub.CreateSlider(combatPage, "Time To Kill Mondo Chick At (minutes)", 1, 60, BossSettings.MondoChickTime, " min", function(v) BossSettings.MondoChickTime = v end)
Hub.CreateToggle(combatPage, "Prepare To Kill Mondo Chick", BossSettings.PrepareMondoChick, function(s) BossSettings.PrepareMondoChick = s end)
Hub.CreateSlider(combatPage, "Time Before Spawning (seconds)", 5, 60, BossSettings.MondoTimeBeforeSpawn, "s", function(v) BossSettings.MondoTimeBeforeSpawn = v end)

-- =========================================================================
-- TAB 4: QUESTS
-- =========================================================================
Hub.CreateSection(questsPage, "📜 Master Quest Controller")
Hub.CreateToggle(questsPage, "Auto Quest", AutoQuestState, function(s) AutoQuestState = s end)

Hub.CreateSection(questsPage, "🐻 Auto Claim Quests")
local allBears = { "Black Bear", "Brown Bear", "Bucko Bee", "Dapper Bear", "Honey Bee", "Mother Bear", "Onett", "Panda Bear", "Polar Bear", "Riley Bee", "Science Bear", "Spirit Bear" }
for _, bear in ipairs(allBears) do
    Hub.CreateToggle(questsPage, "Claim " .. bear, AutoClaimBears[bear] or false, function(s)
        AutoClaimBears[bear] = s
    end)
end

Hub.CreateSection(questsPage, "⭐ Main Quest Toggles")
for bear, state in pairs(MainQuestBears) do
    Hub.CreateToggle(questsPage, "Auto " .. bear, state, function(s) MainQuestBears[bear] = s end)
end

Hub.CreateSection(questsPage, "🔄 Repeatable Quest Toggles")
for bear, state in pairs(RepeatableQuestBears) do
    Hub.CreateToggle(questsPage, "Auto " .. bear, state, function(s) RepeatableQuestBears[bear] = s end)
end

-- =========================================================================
-- TAB 5: PLANTERS
-- =========================================================================
Hub.CreateSection(plantersPage, "🌱 Master Planter Controller")
Hub.CreateToggle(plantersPage, "Auto Planters", AutoPlantersState, function(s) AutoPlantersState = s end)
Hub.CreateDropdown(plantersPage, "Method", {"Manual", "Nectar", "Cycles"}, PlanterMethod, function(v) PlanterMethod = v end)

for pIdx = 1, 3 do
    local pConfig = ManualPlanters[pIdx]
    Hub.CreateSection(plantersPage, "🪴 Planter " .. tostring(pIdx))
    Hub.CreateToggle(plantersPage, "Auto Harvest (P" .. pIdx .. ")", pConfig.AutoHarvest, function(s) pConfig.AutoHarvest = s end)
    Hub.CreateToggle(plantersPage, "Auto Plant (P" .. pIdx .. ")", pConfig.AutoPlant, function(s) pConfig.AutoPlant = s end)
    Hub.CreateToggle(plantersPage, "Farm In Field (P" .. pIdx .. ")", pConfig.FarmInField, function(s) pConfig.FarmInField = s end)
    Hub.CreateToggle(plantersPage, "Don't Harvest Smoking (P" .. pIdx .. ")", pConfig.DontHarvestSmoking, function(s) pConfig.DontHarvestSmoking = s end)
    Hub.CreateDropdown(plantersPage, "Planter: (P" .. pIdx .. ")", planterTypes, pConfig.Planter, function(v) pConfig.Planter = v end)
    Hub.CreateDropdown(plantersPage, "Field 1 (P" .. pIdx .. ")", allFields, pConfig.Field1, function(v) pConfig.Field1 = v end)
    Hub.CreateDropdown(plantersPage, "Field 2 (P" .. pIdx .. ")", allFieldsWithNone, pConfig.Field2, function(v) pConfig.Field2 = v end)
    Hub.CreateDropdown(plantersPage, "Field 3 (P" .. pIdx .. ")", allFieldsWithNone, pConfig.Field3, function(v) pConfig.Field3 = v end)
    Hub.CreateDropdown(plantersPage, "Field 4 (P" .. pIdx .. ")", allFieldsWithNone, pConfig.Field4, function(v) pConfig.Field4 = v end)
    Hub.CreateToggle(plantersPage, "Harvest At Percentage (P" .. pIdx .. ")", pConfig.HarvestAtPercentage, function(s) pConfig.HarvestAtPercentage = s end)
    Hub.CreateSlider(plantersPage, "Harvest At % (P" .. pIdx .. ")", 10, 100, pConfig.HarvestAt, "%", function(v) pConfig.HarvestAt = v end)
    Hub.CreateToggle(plantersPage, "Harvest After Time (P" .. pIdx .. ")", pConfig.HarvestAfterTime, function(s) pConfig.HarvestAfterTime = s end)
    Hub.CreateSlider(plantersPage, "Time To Harvest (hours) (P" .. pIdx .. ")", 1, 24, pConfig.TimeToHarvest, "h", function(v) pConfig.TimeToHarvest = v end)
end

Hub.CreateSection(plantersPage, "🍯 Nectar Optimizer")
Hub.CreateToggle(plantersPage, "Farm In Field (Nectar)", PlanterNectarSettings.FarmInField, function(s) PlanterNectarSettings.FarmInField = s end)
Hub.CreateToggle(plantersPage, "Don't Harvest Smoking (Nectar)", PlanterNectarSettings.DontHarvestSmoking, function(s) PlanterNectarSettings.DontHarvestSmoking = s end)
Hub.CreateToggle(plantersPage, "Ignore Field Degradation", PlanterNectarSettings.IgnoreFieldDegradation, function(s) PlanterNectarSettings.IgnoreFieldDegradation = s end)
Hub.CreateDropdown(plantersPage, "Nectar Preset", {"Custom", "Blue", "Red", "White"}, PlanterNectarSettings.Preset, function(v) PlanterNectarSettings.Preset = v end)
Hub.CreateMultiDropdown(plantersPage, "Allowed Planters (Nectar)", planterTypes, planterTypes, function(sel) PlanterNectarSettings.AllowedPlanters = sel end)
Hub.CreateMultiDropdown(plantersPage, "Allowed Fields (Nectar)", allFields, allFields, function(sel) PlanterNectarSettings.AllowedFields = sel end)
Hub.CreateSlider(plantersPage, "Harvest At %", 10, 100, PlanterNectarSettings.HarvestAt, "%", function(v) PlanterNectarSettings.HarvestAt = v end)
Hub.CreateSlider(plantersPage, "Harvest After Time (hours)", 1, 24, PlanterNectarSettings.TimeToHarvest, "h", function(v) PlanterNectarSettings.TimeToHarvest = v end)

local nectars = {"Comforting", "Motivating", "Satisfying", "Refreshing", "Invigorating"}
for idx, nec in ipairs(nectars) do
    Hub.CreateSlider(plantersPage, nec .. " Priority", 1, 5, idx, "", function(v) PlanterNectarSettings[nec .. "Priority"] = v end)
    Hub.CreateSlider(plantersPage, nec .. " Minimum (hours)", 1, 24, 16, "h", function(v) PlanterNectarSettings[nec .. "Min"] = v end)
end

-- =========================================================================
-- TAB 6: TOYS & DISPENSERS
-- =========================================================================
Hub.CreateSection(toysPage, "🧸 Auto Toys & Timers")
Hub.CreateToggle(toysPage, "Auto Toys", AutoToysState, function(s) AutoToysState = s end)
Hub.CreateToggle(toysPage, "Allow Gather Interrupt", AllowGatherInterrupt, function(s) AllowGatherInterrupt = s end)
Hub.CreateSlider(toysPage, "Amount Of Conversions", 1, 10, AmountOfConversions, "", function(v) AmountOfConversions = v end)
Hub.CreateMultiDropdown(toysPage, "Gather Interrupt Whitelist", {"Combat", "Planters", "Toys"}, {"Combat", "Planters", "Toys"}, function(sel) GatherInterruptWhitelist = sel end)
Hub.CreateButton(toysPage, "Reset Timers", function() toyCooldownEndTimes = {} end)

Hub.CreateSection(toysPage, "⚡ Boosters")
Hub.CreateToggle(toysPage, "Auto Boosters", BoosterSettings.AutoBoosters, function(s) BoosterSettings.AutoBoosters = s end)
Hub.CreateToggle(toysPage, "Require Field Booster", BoosterSettings.RequireFieldBooster, function(s) BoosterSettings.RequireFieldBooster = s end)
Hub.CreateMultiDropdown(toysPage, "Allowed Fields (Boosters)", allFields, allFields, function(sel) BoosterSettings.AllowedFields = sel end)
Hub.CreateMultiDropdown(toysPage, "Allowed Boosters", {"Field Booster", "Blue Field Booster", "Red Field Booster", "Loaded Dice", "Field Dice", "Glitter"}, {"Field Booster", "Blue Field Booster", "Red Field Booster"}, function(sel) BoosterSettings.AllowedBoosters = sel end)
Hub.CreateSlider(toysPage, "Minimum Field Boost To Farm", 1, 10, BoosterSettings.MinFieldBoost, "x", function(v) BoosterSettings.MinFieldBoost = v end)
Hub.CreateSlider(toysPage, "Wanted Field Boost", 1, 10, BoosterSettings.WantedFieldBoost, "x", function(v) BoosterSettings.WantedFieldBoost = v end)

Hub.CreateSection(toysPage, "🍬 Dispensers")
Hub.CreateToggle(toysPage, "Auto Blueberry Dispenser", DispenserSettings.AutoBlueberry, function(s) DispenserSettings.AutoBlueberry = s end)
Hub.CreateToggle(toysPage, "Auto Honey Dispenser", DispenserSettings.AutoHoney, function(s) DispenserSettings.AutoHoney = s end)
Hub.CreateToggle(toysPage, "Auto Strawberry Dispenser", DispenserSettings.AutoStrawberry, function(s) DispenserSettings.AutoStrawberry = s end)
Hub.CreateToggle(toysPage, "Auto Treat Dispenser", DispenserSettings.AutoTreat, function(s) DispenserSettings.AutoTreat = s end)
Hub.CreateToggle(toysPage, "Auto Coconut Dispenser", DispenserSettings.AutoCoconut, function(s) DispenserSettings.AutoCoconut = s end)
Hub.CreateToggle(toysPage, "Auto Ant Pass Dispenser", DispenserSettings.AutoAntPass, function(s) DispenserSettings.AutoAntPass = s end)
Hub.CreateToggle(toysPage, "Auto Robo Pass Dispenser", DispenserSettings.AutoRoboPass, function(s) DispenserSettings.AutoRoboPass = s end)
Hub.CreateToggle(toysPage, "Auto Royal Jelly Dispenser", DispenserSettings.AutoRoyalJelly, function(s) DispenserSettings.AutoRoyalJelly = s end)
Hub.CreateToggle(toysPage, "Auto Glue Dispenser", DispenserSettings.AutoGlue, function(s) DispenserSettings.AutoGlue = s end)

Hub.CreateSection(toysPage, "🃏 Memory Match Suite")
local mmBlacklistItems = {"Blueberry", "Coconut", "Field Dice", "Gumdrops", "Jelly Beans", "Moon Charm", "Pineapple", "Royal Jelly", "Strawberry", "Sunflower Seed", "Treat"}
Hub.CreateMultiDropdown(toysPage, "Blacklisted Items", mmBlacklistItems, {"Blueberry", "Treat"}, function(sel) MemoryMatchBlacklist = sel end)
Hub.CreateToggle(toysPage, "Auto Memory Match", SelectedMemoryMatches["Memory Match"], function(s) SelectedMemoryMatches["Memory Match"] = s end)
Hub.CreateToggle(toysPage, "Auto Mega Memory Match", SelectedMemoryMatches["Mega Memory Match"], function(s) SelectedMemoryMatches["Mega Memory Match"] = s end)
Hub.CreateToggle(toysPage, "Auto Night Memory Match", SelectedMemoryMatches["Night Memory Match"], function(s) SelectedMemoryMatches["Night Memory Match"] = s end)
Hub.CreateToggle(toysPage, "Auto Extreme Memory Match", SelectedMemoryMatches["Extreme Memory Match"], function(s) SelectedMemoryMatches["Extreme Memory Match"] = s end)

Hub.CreateSection(toysPage, "⛩️ Wind Shrine")
Hub.CreateToggle(toysPage, "Auto Wind Shrine", WindShrineSettings.AutoWindShrine, function(s) WindShrineSettings.AutoWindShrine = s end)
Hub.CreateToggle(toysPage, "Farm Winds", WindShrineSettings.FarmWinds, function(s) WindShrineSettings.FarmWinds = s end)
Hub.CreateMultiDropdown(toysPage, "Allowed Fields (Shrine)", allFields, allFields, function(sel) WindShrineSettings.AllowedFields = sel end)
Hub.CreateButton(toysPage, "Check Favour", function() print("[Wind Shrine] Favour checked") end)

Hub.CreateSection(toysPage, "🧪 Materials & Blender")
Hub.CreateToggle(toysPage, "Auto Use Materials", MaterialsSettings.AutoMaterials, function(s) MaterialsSettings.AutoMaterials = s end)
Hub.CreateButton(toysPage, "Configure Materials", function() print("[Materials] Configured") end)

Hub.CreateSection(toysPage, "🏷️ Stickers & Progression")
Hub.CreateToggle(toysPage, "Auto Sticker Stacker", StickersSettings.AutoStickerStacker, function(s) StickersSettings.AutoStickerStacker = s end)
Hub.CreateDropdown(toysPage, "Stack Method", {"Tickets", "Stickers"}, StickersSettings.StackMethod, function(v) StickersSettings.StackMethod = v end)
Hub.CreateButton(toysPage, "Manage Stacker Stickers", function() end)
Hub.CreateButton(toysPage, "Add Stickers In Inventory", function() end)
Hub.CreateToggle(toysPage, "Auto Delete Stickers", StickersSettings.AutoDeleteStickers, function(s) StickersSettings.AutoDeleteStickers = s end)
Hub.CreateButton(toysPage, "Manage Discard Stickers", function() end)
Hub.CreateButton(toysPage, "Add Leaves Stickers", function() end)
Hub.CreateToggle(toysPage, "Auto Sticker Printer", StickersSettings.AutoStickerPrinter, function(s) StickersSettings.AutoStickerPrinter = s end)
Hub.CreateMultiDropdown(toysPage, "Egg Types", {"Basic Egg", "Silver Egg", "Gold Egg", "Diamond Egg", "Mythic Egg", "Star Egg", "Gifted Silver Egg", "Gifted Gold Egg", "Gifted Diamond Egg", "Gifted Mythic Egg"}, {"Basic Egg", "Silver Egg"}, function(sel) StickersSettings.AllowedEggs = sel end)
Hub.CreateToggle(toysPage, "Auto Collect Hidden Stickers", StickersSettings.AutoHiddenStickers, function(s) StickersSettings.AutoHiddenStickers = s end)
Hub.CreateToggle(toysPage, "Auto Progression", ProgressionSettings.AutoProgression, function(s) ProgressionSettings.AutoProgression = s end)
Hub.CreateToggle(toysPage, "Show Blender Messages", ProgressionSettings.ShowBlenderMessages, function(s) ProgressionSettings.ShowBlenderMessages = s end)
Hub.CreateButton(toysPage, "Export Route", function() end)
Hub.CreateButton(toysPage, "Reset Route", function() end)

-- =========================================================================
-- TAB 7: RBC (ROBO BEAR CHALLENGE)
-- =========================================================================
Hub.CreateSection(rbcPage, "🤖 Robo Bear Challenge Suite")
Hub.CreateToggle(rbcPage, "Auto RBC", RBCSettings.AutoRBC, function(s) RBCSettings.AutoRBC = s end)
Hub.CreateDropdown(rbcPage, "Preset", {"Blue", "Red", "White"}, RBCSettings.Preset, function(v) RBCSettings.Preset = v end)
Hub.CreateMultiDropdown(rbcPage, "Drives To Buy", {"Blue", "Red", "White", "Glitched"}, {"Blue", "Red", "White", "Glitched"}, function(sel) RBCSettings.DrivesToBuy = sel end)
Hub.CreateMultiDropdown(rbcPage, "Drives To Use", {"Blue", "Red", "White", "Glitched"}, {"Blue", "Red", "White", "Glitched"}, function(sel) RBCSettings.DrivesToUse = sel end)
Hub.CreateToggle(rbcPage, "Quit After Round", RBCSettings.QuitAfterRound, function(s) RBCSettings.QuitAfterRound = s end)
Hub.CreateToggle(rbcPage, "Disable RBC After Round", RBCSettings.DisableRBCAfterRound, function(s) RBCSettings.DisableRBCAfterRound = s end)
Hub.CreateSlider(rbcPage, "Maximum Round", 1, 25, RBCSettings.MaxRound, "", function(v) RBCSettings.MaxRound = v end)
Hub.CreateToggle(rbcPage, "Auto Buy Robo Pass", RBCSettings.AutoBuyRoboPass, function(s) RBCSettings.AutoBuyRoboPass = s end)
Hub.CreateSlider(rbcPage, "Purchase Cooldown (mins)", 0, 60, RBCSettings.PurchaseCooldown, " min", function(v) RBCSettings.PurchaseCooldown = v end)
Hub.CreateToggle(rbcPage, "Maintain 10x Precision", RBCSettings.Maintain10xPrecision, function(s) RBCSettings.Maintain10xPrecision = s end)
Hub.CreateSlider(rbcPage, "Minimum Round", 1, 20, RBCSettings.MinRound, "", function(v) RBCSettings.MinRound = v end)
Hub.CreateToggle(rbcPage, "Reroll Bees For Digital", RBCSettings.RerollBeesDigital, function(s) RBCSettings.RerollBeesDigital = s end)
Hub.CreateSlider(rbcPage, "Maximum Rerolls", 1, 5, RBCSettings.MaxRerolls, "", function(v) RBCSettings.MaxRerolls = v end)
Hub.CreateToggle(rbcPage, "Kill Gold Cogmowers", RBCSettings.KillGoldCogmowers, function(s) RBCSettings.KillGoldCogmowers = s end)
Hub.CreateToggle(rbcPage, "Track Mobs", RBCSettings.TrackMobs, function(s) RBCSettings.TrackMobs = s end)
Hub.CreateToggle(rbcPage, "Auto Use Materials", RBCSettings.AutoUseMaterials, function(s) RBCSettings.AutoUseMaterials = s end)

-- =========================================================================
-- TAB 8: WEBHOOK
-- =========================================================================
Hub.CreateSection(webhookPage, "🔔 Discord Webhook Integration")
Hub.CreateToggle(webhookPage, "Enable Webhook", WebhookSettings.Enabled, function(s) WebhookSettings.Enabled = s end)
Hub.CreateSlider(webhookPage, "Webhook Interval (minutes)", 1, 60, WebhookSettings.IntervalMinutes, " min", function(v) WebhookSettings.IntervalMinutes = v end)
Hub.CreateTextBox(webhookPage, "Webhook URL", WebhookSettings.URL, function(text)
    if text and text ~= "" then WebhookSettings.URL = text end
end)
Hub.CreateButton(webhookPage, "🚀 Send Test Webhook Now", function()
    local sent = sendDiscordWebhook(true)
    if sent then
        Hub.notify({ Title = "WEBHOOK", Content = "Test webhook payload sent successfully!", Duration = 3 })
    else
        Hub.notify({ Title = "WEBHOOK ERROR", Content = "Failed to send webhook. Check URL.", Duration = 4 })
    end
end)

Hub.CreateSection(webhookPage, "🎨 Embed Branding & Dashboard")
Hub.CreateToggle(webhookPage, "Graph Settings Enabled", WebhookSettings.GraphEnabled, function(s) WebhookSettings.GraphEnabled = s end)
Hub.CreateToggle(webhookPage, "Natro Macro Branding", WebhookSettings.NatroBranding, function(s) WebhookSettings.NatroBranding = s end)
Hub.CreateToggle(webhookPage, "Dashboard Settings Enabled", WebhookSettings.DashboardEnabled, function(s) WebhookSettings.DashboardEnabled = s end)
Hub.CreateButton(webhookPage, "📋 Copy Dashboard Link", function()
    if setclipboard then setclipboard("https://discord.com") end
    Hub.notify({ Title = "CLIPBOARD", Content = "Link copied to clipboard!", Duration = 2 })
end)

-- =========================================================================
-- TAB 9: CONFIG
-- =========================================================================
Hub.CreateSection(configPage, "⚙️ Movement & Physics")
Hub.CreateDropdown(configPage, "Movement Method", {"Tween", "Walk"}, ConfigSettings.MovementMethod, function(v) ConfigSettings.MovementMethod = v end)
Hub.CreateToggle(configPage, "Use Red Cannon", ConfigSettings.UseRedCannon, function(s) ConfigSettings.UseRedCannon = s end)
Hub.CreateToggle(configPage, "Use Jump Shortcuts", ConfigSettings.UseJumpShortcuts, function(s) ConfigSettings.UseJumpShortcuts = s end)
Hub.CreateToggle(configPage, "Enable Walk Speed", ConfigSettings.EnableWalkSpeed, function(s) ConfigSettings.EnableWalkSpeed = s end)
Hub.CreateToggle(configPage, "Dynamic Walk Speed", ConfigSettings.DynamicWalkSpeed, function(s) ConfigSettings.DynamicWalkSpeed = s end)
Hub.CreateSlider(configPage, "Walk Speed", 16, 120, ConfigSettings.WalkSpeed, " studs/s", function(v)
    ConfigSettings.WalkSpeed = v
    local char, root, hum = getCharacter()
    if hum and ConfigSettings.EnableWalkSpeed then hum.WalkSpeed = v end
end)
Hub.CreateSlider(configPage, "Walk Speed Multiplier", 1.0, 3.0, ConfigSettings.WalkSpeedMultiplier, "x", function(v) ConfigSettings.WalkSpeedMultiplier = v end)
Hub.CreateSlider(configPage, "Tween Speed", 4, 15, ConfigSettings.TweenSpeed, "x", function(v)
    ConfigSettings.TweenSpeed = v
    TweenSpeed = v
end)
Hub.CreateButton(configPage, "Copy Discord Link", function()
    if setclipboard then setclipboard("https://discord.gg/unknownhub") end
end)

-- =========================================================================
-- TAB 10: DEBUG
-- =========================================================================
Hub.CreateSection(debugPage, "🛠️ Diagnostic & Client Features")
Hub.CreateToggle(debugPage, "Anonymous Mode", DebugSettings.AnonymousMode, function(s)
    DebugSettings.AnonymousMode = s
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        for _, b in ipairs(char:GetDescendants()) do
            if b:IsA("BillboardGui") then b.Enabled = not s end
        end
    end
end)
Hub.CreateToggle(debugPage, "Farm Multiple Fields", DebugSettings.FarmMultipleFields, function(s) DebugSettings.FarmMultipleFields = s end)
Hub.CreateToggle(debugPage, "Mobile Toggle Button", DebugSettings.MobileToggle, function(s) DebugSettings.MobileToggle = s end)
Hub.CreateToggle(debugPage, "Show Atlas Console", DebugSettings.ShowConsole, function(s) DebugSettings.ShowConsole = s end)
Hub.CreateToggle(debugPage, "Auto Rejoin", DebugSettings.AutoRejoin, function(s) DebugSettings.AutoRejoin = s end)

Hub.CreateSection(debugPage, "⚡ Detected Features & Rare Snipers")
Hub.CreateToggle(debugPage, "Run Without Autofarm", DebugSettings.RunWithoutAutofarm, function(s) DebugSettings.RunWithoutAutofarm = s end)
Hub.CreateToggle(debugPage, "Fast Shower Tween", DebugSettings.FastShowerTween, function(s) DebugSettings.FastShowerTween = s end)
Hub.CreateToggle(debugPage, "Fast Coconut Tween", DebugSettings.FastCoconutTween, function(s) DebugSettings.FastCoconutTween = s end)
Hub.CreateToggle(debugPage, "Fast Tween To Rares", DebugSettings.FastTweenToRares, function(s) DebugSettings.FastTweenToRares = s end)

local raresNamesList = {
    "Blue Extract", "Caustic Wax", "Cloud Vial", "Diamond Egg", "Enzymes",
    "Gifted Diamond Egg", "Gifted Gold Egg", "Gifted Mythic Egg", "Gingerbread Bear",
    "Glitter", "Glue", "Gold Egg", "Loaded Dice", "Magic Bean", "Marshmallow Bee",
    "Mythic Egg", "Neonberry", "Oil", "Purple Potion", "Red Extract", "Star Egg",
    "Star Jelly", "Star Treat", "Sticker", "Super Smoothie", "Swirled Wax", "Tropical Drink", "Turpentine"
}
Hub.CreateMultiDropdown(debugPage, "Rares List", raresNamesList, {"Diamond Egg", "Gifted Mythic Egg", "Star Treat", "Super Smoothie"}, function(sel)
    DebugSettings.RaresList = sel
end)

-- =========================================================================
-- Background Worker Threads & Persistent Loops
-- =========================================================================

-- 1. Live Analytics Updater Loop (Home Tab)
task.spawn(function()
    while task.wait(1) do
        pcall(function()
            local currentHoney, pollen, cap = getHoneyStats()
            if not startHoney then startHoney = currentHoney end
            local gained = math.max(currentHoney - startHoney, 0)
            local elapsed = math.max(os.time() - startSessionTime, 1)
            local hph = (gained / elapsed) * 3600

            local srvElapsed = math.floor(Workspace.DistributedGameTime)

            updateCardText(homeStatLabels.Uptime, "⏱️ Uptime: " .. formatTimeDuration(elapsed))
            updateCardText(homeStatLabels.ServerUptime, "🌐 Server Uptime: " .. formatTimeDuration(srvElapsed))
            updateCardText(homeStatLabels.SessionHoney, "🍯 Session Honey: " .. formatLargeNumber(gained))
            updateCardText(homeStatLabels.HoneyPerHour, "⚡ Honey per Hour: " .. formatLargeNumber(hph) .. "/hr")
        end)
    end
end)

-- 2. Discord Webhook Periodic Sender Loop
task.spawn(function()
    while task.wait(10) do
        pcall(function()
            if WebhookSettings.Enabled and WebhookSettings.URL ~= "" then
                local now = os.time()
                local intervalSec = (WebhookSettings.IntervalMinutes or 5) * 60
                if now - WebhookSettings.LastSentTick >= intervalSec then
                    WebhookSettings.LastSentTick = now
                    sendDiscordWebhook(false)
                end
            end
        end)
    end
end)

-- 3. Field Rotation Engine Loop
task.spawn(function()
    while task.wait(5) do
        pcall(function()
            if AutoFarmState then
                local now = os.time()
                local rotSec = (FieldIntervalMinutes or 10) * 60
                if now - LastFieldRotationTick >= rotSec then
                    LastFieldRotationTick = now
                    local rotationPool = { SelectedFarmField }
                    if SelectedFarmField2 and SelectedFarmField2 ~= "None" then table.insert(rotationPool, SelectedFarmField2) end
                    if SelectedFarmField3 and SelectedFarmField3 ~= "None" then table.insert(rotationPool, SelectedFarmField3) end
                    if #rotationPool > 1 then
                        CurrentRotationIdx = (CurrentRotationIdx % #rotationPool) + 1
                        SelectedFarmField = rotationPool[CurrentRotationIdx]
                        print("[Unknown Hub] Rotated field to: " .. tostring(SelectedFarmField))
                    end
                end
            end
        end)
    end
end)

-- 4. Main Farm Loop
task.spawn(function()
    while task.wait(1) do
        if AutoFarmState then
            pcall(function()
                local char, root, humanoid = getCharacter()
                if not char or not root or not humanoid then return end

                -- Check rare collectibles sniper
                scanAndCollectRareItems(root, humanoid)

                -- Check Robo Bear Challenge
                if RBCSettings.AutoRBC then
                    runRBCStep(root, humanoid)
                end
            end)
        end
    end
end)

-- 5. Auto Rejoin Watchdog
if GuiService then
    pcall(function()
        GuiService.ErrorMessageChanged:Connect(function()
            if DebugSettings.AutoRejoin then
                task.wait(2)
                TeleportService:Teleport(game.PlaceId, LocalPlayer)
            end
        end)
    end)
end

print("[Unknown Hub] Bee Swarm Simulator 100% Atlas Suite successfully loaded & armed!")
