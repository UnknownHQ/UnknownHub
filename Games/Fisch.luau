--------------------------------------------------------------------------------
-- UNKNOWN HUB: FISCH
-- PlaceId: 16732694052, 17910972410, 131716211654599 | GameId: 5750914919
--------------------------------------------------------------------------------

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer

--------------------------------------------------------------------------------
-- 1. NATURAL ANTI-AFK (Zero Metamethod Risk)
--------------------------------------------------------------------------------
pcall(function()
    LocalPlayer.Idled:Connect(function()
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.RightControl, false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.RightControl, false, game)
    end)
end)

--------------------------------------------------------------------------------
-- 2. LIBRARY INITIALIZATION
--------------------------------------------------------------------------------
local function getValidatedLibrary()
    local localPaths = {
        "UnknownLibrary.luau",
        "UnknownLibrary",
        "scripts/UnknownLibrary.luau",
        "scripts/UnknownLibrary",
        "UnknownHub_repo/UnknownLibrary.luau",
        "UnknownHub_repo/UnknownLibrary"
    }
    for _, path in ipairs(localPaths) do
        if isfile and isfile(path) then
            local success, content = pcall(readfile, path)
            if success and content and #content > 0 then
                local fn, loadErr = loadstring(content)
                if fn then
                    local runSuccess, loadedLib = pcall(fn)
                    if runSuccess and loadedLib and typeof(loadedLib) == "function" then
                        getgenv().UnknownLibrary = loadedLib
                        return loadedLib
                    end
                end
            end
        end
    end

    local lib = getgenv().UnknownLibrary
    if lib and typeof(lib) == "function" then
        return lib
    end

    local url = "https://raw.githubusercontent.com/UnknownHQ/UnknownHub/main/UnknownLibrary.luau"
    local success, response = pcall(function()
        return game:HttpGet(url)
    end)
    if success and response and #response > 0 then
        local fn = loadstring(response)
        if fn then
            local runSuccess, loadedLib = pcall(fn)
            if runSuccess and loadedLib and typeof(loadedLib) == "function" then
                getgenv().UnknownLibrary = loadedLib
                return loadedLib
            end
        end
    end

    error("[Unknown Hub] CRITICAL: Failed to load valid UnknownLibrary.")
end

local Library = getValidatedLibrary()
local Hub = Library({
    title = "Unknown Hub",
    game = "Fisch ⚡"
})

--------------------------------------------------------------------------------
-- 3. CONFIGURATION STATE
--------------------------------------------------------------------------------
local Config = {
    -- Auto Fishing (Always Maximum Effect)
    AutoCast = false,
    CastPower = 100,
    AutoShake = false,
    AutoReel = false,
    AutoEquipRod = true,

    -- Target Auto Farm
    AutoFarmFish = false,
    AutoFarmItem = false,
    AutoFarmSpot = false,
    AutoEquipTargetBait = true,

    -- Economy
    AutoSell = false,
    AutoSellInterval = 60,

    -- Movement & Utility
    WalkOnWater = false,
    InfiniteOxygen = false,
    WalkSpeed = 16,
    JumpPower = 50
}

--------------------------------------------------------------------------------
-- 4. PRECISION FISHING ROD RESOLVER
--------------------------------------------------------------------------------
local function isRodTool(tool)
    if not tool or not tool:IsA("Tool") then return false end
    if tool.Name:lower():find("rod") then return true end
    local values = tool:FindFirstChild("values")
    if values and (values:FindFirstChild("bobberzone") or values:FindFirstChild("casted")) then
        return true
    end
    return false
end

local function getEquippedRod()
    local char = LocalPlayer.Character
    if char then
        for _, item in ipairs(char:GetChildren()) do
            if isRodTool(item) then
                return item
            end
        end
    end
    return nil
end

local function ensureRodEquipped()
    local rod = getEquippedRod()
    if rod then return rod end

    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return nil end

    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        for _, item in ipairs(bp:GetChildren()) do
            if isRodTool(item) then
                pcall(function()
                    hum:EquipTool(item)
                end)
                task.wait(0.3)
                return getEquippedRod()
            end
        end
    end
    return nil
end

--------------------------------------------------------------------------------
-- 4.5. NATIVE CONTROLLER INJECTORS (FAST SHAKE & ULTRA SMOOTH FAST REEL)
--------------------------------------------------------------------------------
pcall(function()
    local LureShakeController = require(ReplicatedStorage.client.legacyControllers.LureShakeController)
    if LureShakeController and not LureShakeController._Hooked then
        LureShakeController._Hooked = true
        local origStartMinigame = LureShakeController.StartMinigame
        LureShakeController.StartMinigame = function(...)
            local args = {...}
            if Config.AutoShake then
                for _, arg in ipairs(args) do
                    if typeof(arg) == "table" and (arg.seed ~= nil or arg.initialTimer ~= nil or arg.ButtonName ~= nil) then
                        arg.ShakePower = 9999
                        arg.ShakeScale = 25
                        break
                    end
                end
            end
            return origStartMinigame(...)
        end
    end
end)

pcall(function()
    local ReelController = require(ReplicatedStorage.client.legacyControllers.ReelController)
    if ReelController and not ReelController._Hooked then
        ReelController._Hooked = true
        local origStartReel = ReelController.StartReel
        ReelController.StartReel = function(...)
            local args = {...}
            if Config.AutoReel then
                for _, arg in ipairs(args) do
                    if typeof(arg) == "table" and (arg.fish ~= nil or arg.stats ~= nil) then
                        if arg.stats then
                            arg.stats.StartingProgress = 99
                            arg.stats.ProgressSpeed = 9999
                            arg.stats.Control = 10
                            arg.stats.Resilience = 999
                            arg.stats.Stability = 999
                        end
                        break
                    end
                end
            end
            return origStartReel(...)
        end

        if ReelController.OnReelCreated and not ReelController._OnReelHooked then
            ReelController._OnReelHooked = true
            ReelController.OnReelCreated:Connect(function(reel)
                if not Config.AutoReel then return end
                pcall(function()
                    if reel.core and reel.core.minigame then
                        reel.core.minigame.NoFail = true
                    end
                    reel:AddModifier("barSize", "force", 10)
                    reel:AddModifier("progressefficiency", "force", 999)
                    reel:AddModifier("progressLossMultiplier", "force", 0)
                    reel:AddProgress(100)
                end)
            end)
        end
    end
end)

--------------------------------------------------------------------------------
-- 5. HYPER-SPEED AUTOMATION ENGINE (INSTANT REEL & FAST SHAKE)
--------------------------------------------------------------------------------
local lastCastTick = 0
local lastShakeTick = 0
local lastCatchTick = 0
local reelStartTick = 0
local hadActiveReel = false
local instantReelDispatched = false

-- Helper: Retrieve active ReelController object (Instant Hook)
local function getActiveReel()
    local ok, rc = pcall(function()
        return require(ReplicatedStorage.client.legacyControllers.ReelController)
    end)
    if ok and rc and rc.ActiveReel then
        return rc.ActiveReel
    end
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    local reelGui = pg and pg:FindFirstChild("reel")
    if reelGui and reelGui.Enabled then
        if ok and rc and rc.ActiveReel then
            return rc.ActiveReel
        end
    end
    return nil
end

-- Helper: Check if shake minigame UI is active
local function isShakingActive()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    local shakeUI = pg and pg:FindFirstChild("shakeui")
    return (shakeUI and shakeUI.Enabled == true) or false
end

-- Helper: Check if rod is currently in active cast / water / minigame state
local function isRodCurrentlyCasted(rod)
    if not rod then return false end

    -- Check physical bobber
    if rod:FindFirstChild("bobber") ~= nil then
        return true
    end

    -- Check character attributes
    local char = LocalPlayer.Character
    if char then
        if char:GetAttribute("Fishing") == true then return true end
        if char:GetAttribute("Reeling") == true then return true end
        if char:GetAttribute("CastPower") ~= nil then return true end
    end

    -- Check active minigames
    if getActiveReel() ~= nil then return true end
    if isShakingActive() then return true end

    -- Check internal rod values
    local values = rod:FindFirstChild("values")
    if values then
        local casted = values:FindFirstChild("casted")
        if casted and casted.Value == true then
            return true
        end

        local state = values:FindFirstChild("state")
        -- States: 4=Casting, 5=Searching, 6=Luring, 7=PreReel, 8=Reeling
        if state and state.Value >= 4 and state.Value <= 8 then
            return true
        end
    end

    return false
end

-- 1. Precision Auto Cast
local function executeCast()
    if not (Config.AutoCast or Config.AutoFarmFish or Config.AutoFarmItem or Config.AutoFarmSpot) then return end
    if getActiveReel() ~= nil then return end
    if isShakingActive() then return end
    -- Flight Debounce (4.0s): Never cancel a flying bobber or cast halfway!
    if tick() - lastCastTick < 4.0 then return end
    if tick() - lastCatchTick < 1.0 then return end

    local rod = ensureRodEquipped()
    if not rod then return end

    -- STRICT GUARD: If rod is already in the water or waiting for bite, NEVER recast!
    if isRodCurrentlyCasted(rod) then
        -- Watchdog: If casted but stuck for over 30 seconds with no bite, reset rod cleanly
        if tick() - lastCastTick > 30 then
            pcall(function()
                local net = require(ReplicatedStorage.packages.Net)
                net:RemoteEvent("FishingRod/Reset", -1):FireServer()
                lastCastTick = tick()
            end)
        end
        return
    end

    pcall(function()
        local castPower = math.clamp(Config.CastPower or 100, 10, 100)
        local net = require(ReplicatedStorage.packages.Net)
        local castRf = net:RemoteFunction("FishingRod/Cast", -1)
        if castRf then
            lastCastTick = tick()
            castRf:InvokeServer(castPower, true)
        end
    end)
end

-- 2. Maximum-Speed Precision Auto Shake Engine (<0.2s Total)
local function processShakeMinigame()
    if not Config.AutoShake then return end

    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return end

    local shakeUI = playerGui:FindFirstChild("shakeui")
    if not shakeUI or not shakeUI.Enabled then return end

    local safezone = shakeUI:FindFirstChild("safezone")
    if not safezone then return end

    pcall(function()
        for _, btn in ipairs(safezone:GetChildren()) do
            if (btn:IsA("ImageButton") or btn:IsA("GuiButton")) and btn.Visible then
                lastShakeTick = tick()

                -- Prioritize getconnections (verified 100% working in Real executor)
                local conns = getconnections and getconnections(btn.Activated)
                if conns and #conns > 0 then
                    for _, c in ipairs(conns) do
                        c:Fire()
                    end
                elseif firesignal then
                    firesignal(btn.Activated)
                else
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
                    task.defer(function()
                        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
                    end)
                end

                return
            end
        end
    end)
end

-- 3. Maximum Speed Instant Reel Engine (Zero-Delay Finish & Anti-Kick)
local function processReelMinigame(activeReel)
    if not Config.AutoReel or not activeReel then return end

    if reelStartTick == 0 then
        reelStartTick = tick()
        instantReelDispatched = false
    end

    pcall(function()
        if activeReel.core and activeReel.core.minigame then
            activeReel.core.minigame.NoFail = true
            if activeReel.core.minigame._progressModifier then
                activeReel.core.minigame._progressModifier.Value = 100
            end
        end

        activeReel.barSize = 10
        activeReel.barPosition = activeReel.fishPosition or 0.5
        activeReel.onbar = true
        activeReel.perfect = true

        activeReel:AddModifier("barSize", "force", 10)
        activeReel:AddModifier("progressLossMultiplier", "force", 0)
        activeReel:AddProgress(100)

        -- Complete minigame safely after 0.15s network handshake
        local elapsed = tick() - reelStartTick
        if elapsed >= 0.15 and not instantReelDispatched then
            instantReelDispatched = true
            pcall(function()
                activeReel:EndMinigame(true)
            end)
        end
    end)
end

-- Master Automation Heartbeat
RunService.Heartbeat:Connect(function()
    pcall(function()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not char or not hum or hum.Health <= 0 then return end

        local activeReel = getActiveReel()
        local isShaking = isShakingActive()

        if activeReel then
            hadActiveReel = true
            processReelMinigame(activeReel)
        else
            if hadActiveReel then
                -- Reel just ended / catch complete!
                hadActiveReel = false
                reelStartTick = 0
                instantReelDispatched = false
                lastCatchTick = tick()
            end

            if isShaking then
                processShakeMinigame()
            else
                if Config.AutoCast then
                    executeCast()
                end
            end
        end
    end)
end)

--------------------------------------------------------------------------------
-- 6. AUTO SELL ALL FISH ENGINE
--------------------------------------------------------------------------------
local function executeAutoSell()
    pcall(function()
        local events = ReplicatedStorage:FindFirstChild("events")
        if events then
            local sellAll = events:FindFirstChild("SellAll") or events:FindFirstChild("selleverything") or events:FindFirstChild("sell_all")
            if sellAll and sellAll:IsA("RemoteFunction") then
                sellAll:InvokeServer()
            elseif sellAll and sellAll:IsA("RemoteEvent") then
                sellAll:FireServer()
            end
        end
    end)
end

task.spawn(function()
    while true do
        task.wait(Config.AutoSellInterval or 60)
        if Config.AutoSell then
            executeAutoSell()
        end
    end
end)

--------------------------------------------------------------------------------
-- 7. MOVEMENT & ENVIRONMENT UTILITY
--------------------------------------------------------------------------------
local waterPlatform = nil

local function toggleWaterWalk(enable)
    pcall(function()
        if enable then
            if not waterPlatform then
                waterPlatform = Instance.new("Part")
                waterPlatform.Name = "UnknownWaterPlatform"
                waterPlatform.Size = Vector3.new(100, 1, 100)
                waterPlatform.Anchored = true
                waterPlatform.CanCollide = true
                waterPlatform.Transparency = 1
                waterPlatform.Parent = Workspace
            end
        else
            if waterPlatform then
                waterPlatform:Destroy()
                waterPlatform = nil
            end
        end
    end)
end

RunService.RenderStepped:Connect(function()
    pcall(function()
        if Config.WalkOnWater and waterPlatform then
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root then
                waterPlatform.Position = Vector3.new(root.Position.X, 126, root.Position.Z)
            end
        end

        if Config.InfiniteOxygen then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("Oxygen") then
                char.Oxygen.Value = 100
            end
        end
    end)
end)

--------------------------------------------------------------------------------
-- 8. SHOP REGISTRIES & REMOTE PURCHASING ENGINE
--------------------------------------------------------------------------------
local function formatPrice(num)
    local formatted = tostring(num):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
    return formatted .. " C$"
end

local RodRegistry = {
    { Name = "Flimsy Rod", Price = 0, Pos = Vector3.new(471, 148, 229) },
    { Name = "Training Rod", Price = 300, Pos = Vector3.new(457, 148, 230) },
    { Name = "Plastic Rod", Price = 750, Pos = Vector3.new(453, 148, 229) },
    { Name = "Pool Noodle Rod", Price = 1000, Pos = Vector3.new(465, 148, 230) },
    { Name = "Carbon Rod", Price = 2000, Pos = Vector3.new(448, 148, 228) },
    { Name = "Decayed Rod", Price = 2000, Pos = Vector3.new(-110, -515, 1060) },
    { Name = "Stone Rod", Price = 2000, Pos = Vector3.new(2450, 135, -700) },
    { Name = "Long Rod", Price = 3000, Pos = Vector3.new(485, 148, 224) },
    { Name = "Fast Rod", Price = 4000, Pos = Vector3.new(447, 148, 220) },
    { Name = "Lucky Rod", Price = 4500, Pos = Vector3.new(446, 148, 222) },
    { Name = "Steady Rod", Price = 7000, Pos = Vector3.new(-1480, 135, 680) },
    { Name = "Firefly Rod", Price = 9500, Pos = Vector3.new(2450, 135, -700) },
    { Name = "Fortune Rod", Price = 11000, Pos = Vector3.new(-1490, 135, 690) },
    { Name = "Frog Rod", Price = 12000, Pos = Vector3.new(2450, 135, -700) },
    { Name = "Rapid Rod", Price = 12000, Pos = Vector3.new(-1500, 135, 700) },
    { Name = "Magnet Rod", Price = 15000, Pos = Vector3.new(-180, 140, 1950) },
    { Name = "Nocturnal Rod", Price = 15000, Pos = Vector3.new(-110, -515, 1060) },
    { Name = "Reinforced Rod", Price = 20000, Pos = Vector3.new(-930, 220, -1120) },
    { Name = "Merchant Rod", Price = 20000, Pos = Vector3.new(380, 135, 230) },
    { Name = "Arctic Rod", Price = 25000, Pos = Vector3.new(2620, 150, 2400) },
    { Name = "Coral Rod", Price = 30000, Pos = Vector3.new(-1650, -230, -2850) },
    { Name = "Avalanche Rod", Price = 35000, Pos = Vector3.new(2620, 150, 2400) },
    { Name = "Crystalized Rod", Price = 35000, Pos = Vector3.new(2620, 150, 2400) },
    { Name = "Artisan Rod", Price = 40000, Pos = Vector3.new(-1480, 135, 680) },
    { Name = "Boreal Rod", Price = 42000, Pos = Vector3.new(2620, 150, 2400) },
    { Name = "Carrot Rod", Price = 45000, Pos = Vector3.new(-1480, 135, 680) },
    { Name = "Midas Rod", Price = 55000, Pos = Vector3.new(380, 135, 230) },
    { Name = "Ice Warpers Rod", Price = 65000, Pos = Vector3.new(2620, 150, 2400) },
    { Name = "Aurora Rod", Price = 70000, Pos = Vector3.new(-1790, -143, -3400) },
    { Name = "Champions Rod", Price = 90000, Pos = Vector3.new(380, 135, 230) },
    { Name = "Mythical Rod", Price = 90000, Pos = Vector3.new(380, 135, 230) },
    { Name = "Kings Rod", Price = 100000, Pos = Vector3.new(1300, -805, -250) },
    { Name = "Trident Rod", Price = 150000, Pos = Vector3.new(-1650, -230, -2850) },
    { Name = "Volcanic Rod", Price = 150000, Pos = Vector3.new(-1480, 135, 680) },
    { Name = "Fallen Rod", Price = 175000, Pos = Vector3.new(-1650, -230, -2850) },
    { Name = "Free Spirit Rod", Price = 200000, Pos = Vector3.new(-1480, 135, 680) },
    { Name = "Heaven's Rod", Price = 800000, Pos = Vector3.new(1000, 135, -1250) },
    { Name = "Rod Of The Depths", Price = 750000, Pos = Vector3.new(990, -710, 1215) },
    { Name = "Zeus Rod", Price = 500000, Pos = Vector3.new(1000, 135, -1250) }
}

local TotemRegistry = {
    { Name = "Enchant Relic", Price = 11000, Pos = Vector3.new(-950, 222, -991) },
    { Name = "Clearcast Totem", Price = 1000, Pos = Vector3.new(418, 148, 235) },
    { Name = "Sundial Totem", Price = 2000, Pos = Vector3.new(-1145, 135, -1075) },
    { Name = "Windset Totem", Price = 2000, Pos = Vector3.new(2840, 178, 2700) },
    { Name = "Tempest Totem", Price = 2000, Pos = Vector3.new(-190, 155, 1960) },
    { Name = "Smokescreen Totem", Price = 2000, Pos = Vector3.new(2490, 131, -730) },
    { Name = "Meteor Totem", Price = 75000, Pos = Vector3.new(-1480, 135, 680) },
    { Name = "Avalanche Totem", Price = 150000, Pos = Vector3.new(2620, 150, 2400) },
    { Name = "Blizzard Totem", Price = 150000, Pos = Vector3.new(2620, 150, 2400) },
    { Name = "Poseidon Wrath Totem", Price = 150000, Pos = Vector3.new(-1650, -230, -2850) },
    { Name = "Zeus Storm Totem", Price = 150000, Pos = Vector3.new(1000, 135, -1250) },
    { Name = "Eclipse Totem", Price = 200000, Pos = Vector3.new(-110, -515, 1060) },
    { Name = "Aurora Totem", Price = 500000, Pos = Vector3.new(-1810, -143, -3405) },
    { Name = "Blue Moon Totem", Price = 1200000, Pos = Vector3.new(380, 135, 230) },
    { Name = "Dripstone Collapse Totem", Price = 7500000, Pos = Vector3.new(-1650, -230, -2850) }
}

local GearRegistry = {
    { Name = "Basic Oxygen Tank", Price = 1000, Pos = Vector3.new(515, 151, 235) },
    { Name = "Basic Diving Gear", Price = 3000, Pos = Vector3.new(515, 151, 238) },
    { Name = "Beginner Oxygen Tank", Price = 3500, Pos = Vector3.new(515, 151, 235) },
    { Name = "Intermediate Oxygen Tank", Price = 10000, Pos = Vector3.new(-1650, -230, -2850) },
    { Name = "Advanced Diving Gear", Price = 15000, Pos = Vector3.new(-1650, -230, -2850) },
    { Name = "Advanced Oxygen Tank", Price = 25000, Pos = Vector3.new(-1650, -230, -2850) },
    { Name = "Flippers", Price = 9000, Pos = Vector3.new(515, 151, 235) },
    { Name = "Super Flippers", Price = 30000, Pos = Vector3.new(-1650, -230, -2850) },
    { Name = "Winter Cloak", Price = 7500, Pos = Vector3.new(2620, 150, 2400) },
    { Name = "Glimmerfin Suit Lvl 1", Price = 7500, Pos = Vector3.new(515, 151, 235) },
    { Name = "Glimmerfin Suit Lvl 2", Price = 7500, Pos = Vector3.new(515, 151, 235) },
    { Name = "Glimmerfin Suit Lvl 3", Price = 7500, Pos = Vector3.new(515, 151, 235) },
    { Name = "Dunehaven Wraps", Price = 40000, Pos = Vector3.new(-930, 220, -1120) },
    { Name = "Scoria Armor", Price = 75000, Pos = Vector3.new(-1480, 135, 680) },
    { Name = "Gas Mask", Price = 75000, Pos = Vector3.new(-1650, -230, -2850) }
}

local UtilityRegistry = {
    { Name = "Crab Cage", Price = 45, Pos = Vector3.new(474, 149, 236) },
    { Name = "GPS", Price = 100, Pos = Vector3.new(515, 151, 235) },
    { Name = "Glider", Price = 900, Pos = Vector3.new(-1480, 135, 680) },
    { Name = "Reinforced Crab Cage", Price = 1000, Pos = Vector3.new(-930, 220, -1120) },
    { Name = "Coral Crab Cage", Price = 1500, Pos = Vector3.new(1000, 135, -1250) },
    { Name = "Relic Crab Cage", Price = 2000, Pos = Vector3.new(-930, 220, -1120) },
    { Name = "Pickaxe", Price = 5000, Pos = Vector3.new(-1480, 135, 680) },
    { Name = "Fish Radar", Price = 8000, Pos = Vector3.new(510, 151, 240) },
    { Name = "Advanced Glider", Price = 10000, Pos = Vector3.new(-1480, 135, 680) },
    { Name = "Golden Crab Cage", Price = 25000, Pos = Vector3.new(-110, -515, 1060) },
    { Name = "Tidebreaker", Price = 40000, Pos = Vector3.new(-1650, -230, -2850) },
    { Name = "Magic Mirror", Price = 50000, Pos = Vector3.new(-930, 220, -1120) },
    { Name = "Traveler's Whistle", Price = 25000, Pos = Vector3.new(380, 135, 230) }
}

local BaitRegistry = {
    { Name = "Krill", Price = 50, Pos = Vector3.new(380, 135, 230) },
    { Name = "Bait Crate", Price = 120, Pos = Vector3.new(470, 148, 230) },
    { Name = "Quality Bait Crate", Price = 350, Pos = Vector3.new(380, 135, 230) },
    { Name = "Coral Bait Crate", Price = 600, Pos = Vector3.new(-3550, 135, 450) },
    { Name = "Volcanic Bait Crate", Price = 1200, Pos = Vector3.new(-1900, 165, 300) },
    { Name = "Deep Bait Crate", Price = 1500, Pos = Vector3.new(-1650, -230, -2850) },
    { Name = "Magma Bait Crate", Price = 2000, Pos = Vector3.new(-1900, 165, 300) },
    { Name = "Obsidian-Bone", Price = 7500, Pos = Vector3.new(-1480, 135, 680) },
    { Name = "Whale Bait", Price = 25000, Pos = Vector3.new(380, 135, 230) },
    { Name = "Golden Shrimp Bait", Price = 50000, Pos = Vector3.new(-1650, -230, -2850) }
}

local BoatRegistry = {
    { Name = "Rowboat", Price = 400 },
    { Name = "Surfboard", Price = 1500 },
    { Name = "Giant Box of Chocolate", Price = 3500 },
    { Name = "Quack Cruiser", Price = 5000 },
    { Name = "Titan", Price = 5000 },
    { Name = "Bass Boat", Price = 6000 },
    { Name = "Hovercraft", Price = 7000 },
    { Name = "Speedboat", Price = 15000 },
    { Name = "Fishing Boat", Price = 20000 },
    { Name = "Pontoon", Price = 20000 },
    { Name = "Luxury Speedboat", Price = 20000 },
    { Name = "Pirate Ship", Price = 20000 },
    { Name = "Aquarium Boat", Price = 20000 },
    { Name = "Archaeological Boat", Price = 20000 },
    { Name = "Jetski", Price = 50000 },
    { Name = "Small Utility Boat", Price = 50000 },
    { Name = "The Pearl", Price = 50000 },
    { Name = "Medium Utility Boat", Price = 250000 },
    { Name = "Crew-ser", Price = 250000 },
    { Name = "Large Utility Boat", Price = 500000 },
    { Name = "Windsurfer Boast", Price = 1000000 },
    { Name = "Huge Utility Boat", Price = 1500000 },
    { Name = "Submarine", Price = 1500000 },
    { Name = "Cursed Rider", Price = 2000000 },
    { Name = "Airboat", Price = 5000000 }
}

local function isStorePrompt(p)
    if not p or not p.Enabled then return false end
    local act = string.lower(p.ActionText or "")
    if string.find(act, "collect") or string.find(act, "open") or string.find(act, "retrieve") or string.find(act, "harvest") or string.find(act, "take") or string.find(act, "inspect") then
        return false
    end
    if p:FindFirstAncestor("active") or p:FindFirstAncestor("Active") then
        return false
    end
    if p:FindFirstAncestor("interactables") then
        return true
    end
    local obj = string.lower(p.ObjectText ~= "" and p.ObjectText or (p.Parent and p.Parent.Name or ""))
    if string.find(act, "buy") or string.find(act, "view") or string.find(act, "purchase") or string.find(act, "c$") or string.find(obj, "c$") then
        return true
    end
    return false
end

local function purchaseItemAtLocation(targetPos, modelName, itemType)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root then 
        Hub.Notify("Shop", "Character root not found.", 2)
        return false
    end
    
    -- UNEQUIP ROD/TOOLS BEFORE BUYING (Fisch prompt silently drops if a fishing rod is held!)
    if hum then
        hum:UnequipTools()
        task.wait(0.15)
    end
    
    Hub.Notify("Shop", "Purchasing " .. modelName .. "...", 2)
    local originalCFrame = root.CFrame
    
    local function findPrompt(maxDistFromTarget)
        local interactables = Workspace:FindFirstChild("world") and Workspace.world:FindFirstChild("interactables")
        if interactables and interactables:FindFirstChild(modelName) then
            local model = interactables[modelName]
            local p = model:FindFirstChildOfClass("ProximityPrompt") or model:FindFirstChild("PromptTemplate")
            if p and isStorePrompt(p) then return p end
        end
        for _, p in ipairs(Workspace:GetDescendants()) do
            if p:IsA("ProximityPrompt") and isStorePrompt(p) then
                local obj = p.ObjectText ~= "" and p.ObjectText or (p.Parent and p.Parent.Name or "")
                if string.lower(obj) == string.lower(modelName) or string.find(string.lower(obj), string.lower(modelName), 1, true) then
                    if maxDistFromTarget and targetPos then
                        local pPos = p.Parent:IsA("BasePart") and p.Parent.Position or p.Parent:GetPivot().Position
                        if (pPos - targetPos).Magnitude <= maxDistFromTarget then
                            return p
                        end
                    else
                        return p
                    end
                end
            end
        end
        return nil
    end

    local prompt = findPrompt(25)
    if not prompt or (root.Position - prompt.Parent:GetPivot().Position).Magnitude > 15 then
        if targetPos then
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            root.CFrame = CFrame.new(targetPos + Vector3.new(0, 3, 0))
            
            local start = tick()
            while tick() - start < 3.5 do
                prompt = findPrompt(25)
                if prompt then break end
                task.wait(0.2)
            end
        end
    end
    
    if not prompt then
        prompt = findPrompt(nil)
    end
    
    if not prompt then
        root.CFrame = originalCFrame
        Hub.Notify("Shop", "Could not locate " .. modelName .. " store.", 3)
        return false
    end
    
    local promptPos = prompt.Parent:IsA("BasePart") and prompt.Parent.Position or prompt.Parent:GetPivot().Position
    root.AssemblyLinearVelocity = Vector3.zero
    root.CFrame = CFrame.new(promptPos + Vector3.new(0, 1.5, 3), promptPos)
    task.wait(0.45)
    
    pcall(function()
        fireproximityprompt(prompt, 0)
    end)
    pcall(function()
        if prompt.InputHoldBegin and prompt.InputHoldEnd then
            prompt:InputHoldBegin()
            task.wait(prompt.HoldDuration or 0.1)
            prompt:InputHoldEnd()
        end
    end)
    
    local pg = LocalPlayer:WaitForChild("PlayerGui")
    local over = pg:FindFirstChild("over")
    local startWait = tick()
    local confirmed = false

    while tick() - startWait < 3.5 do
        if over then
            local promptFrame = over:FindFirstChild("prompt")
            if promptFrame and promptFrame:FindFirstChild("confirm") and promptFrame.confirm.Visible then
                local info = promptFrame:FindFirstChild("info")
                local infoTxt = info and string.lower(info.Text) or ""
                if string.find(infoTxt, "insufficient") then
                    Hub.Notify("Shop", "Insufficient funds to purchase " .. modelName .. ".", 3)
                    pcall(function()
                        local conns = getconnections and (getconnections(promptFrame.confirm.Activated) or getconnections(promptFrame.confirm.MouseButton1Click))
                        if conns then for _, c in ipairs(conns) do c:Fire() end end
                    end)
                    break
                end
                task.wait(0.15)
                local btn = promptFrame.confirm
                pcall(function()
                    local conns = getconnections and (getconnections(btn.Activated) or getconnections(btn.MouseButton1Click))
                    if conns and #conns > 0 then
                        for _, c in ipairs(conns) do c:Fire() end
                    end
                    if firesignal then
                        pcall(function() firesignal(btn.Activated) end)
                        pcall(function() firesignal(btn.MouseButton1Click) end)
                    end
                end)
                confirmed = true
                break
            end
        end

        local pc = pg:FindFirstChild("PromptConfirmation")
        if pc and pc:FindFirstChild("Frame") and pc.Frame.Visible then
            local options = pc.Frame:FindFirstChild("Options")
            if options then
                for _, b in ipairs(options:GetChildren()) do
                    if b:IsA("GuiButton") then
                        local lbl = b:FindFirstChildWhichIsA("TextLabel")
                        local txt = lbl and string.lower(lbl.Text) or string.lower(b.Name)
                        if string.find(txt, "buy") or string.find(txt, "yes") or string.find(txt, "confirm") or string.find(txt, "2") then
                            task.wait(0.12)
                            local conns = getconnections(b.MouseButton1Click)
                            if #conns > 0 then
                                for _, c in ipairs(conns) do c:Fire() end
                            else
                                conns = getconnections(b.Activated)
                                if #conns > 0 then for _, c in ipairs(conns) do c:Fire() end
                                elseif firesignal then firesignal(b.MouseButton1Click) end
                            end
                            confirmed = true
                            break
                        end
                    end
                end
                if confirmed then break end
            end
        end
        task.wait(0.1)
    end
    
    task.wait(0.3)
    root.AssemblyLinearVelocity = Vector3.zero
    root.CFrame = originalCFrame
    if confirmed then
        Hub.Notify("Shop", "Purchased " .. modelName .. "!", 3)
        return true
    else
        Hub.Notify("Shop", "Purchase did not complete for " .. modelName .. ".", 3)
        return false
    end
end

local function purchaseBoat(boatName)
    local net = ReplicatedStorage:FindFirstChild("packages") and ReplicatedStorage.packages:FindFirstChild("Net")
    local rf = net and net:FindFirstChild("RF/Boats/Purchase")
    if rf then
        local success, res = pcall(function()
            return rf:InvokeServer(boatName)
        end)
        if success and res == true then
            Hub.Notify("Shop", "Purchased " .. boatName .. "!", 3)
            return true
        else
            Hub.Notify("Shop", "Failed: Not enough C$ or already owned.", 3)
            return false
        end
    end
    Hub.Notify("Shop", "Boat remote not available.", 3)
    return false
end

--------------------------------------------------------------------------------
-- 9. WORLD TELEPORTS REGISTRY
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- TARGET FARM REGISTRIES (Fish, Items & Best Farming Spots)
--------------------------------------------------------------------------------
local TargetFishRegistry = {
    { Name = "Colossal Squid", Zone = "The Depths", Pos = Vector3.new(990, -710, 1215), Bait = "Squid", Rod = "Magma Rod" },
    { Name = "Megalodon", Zone = "Ancient Isle Deep", Pos = Vector3.new(6000, 150, 400), Bait = "Fish Head", Rod = "Destiny Rod" },
    { Name = "Whispering Eel", Zone = "Vertigo Abyss", Pos = Vector3.new(-140, -510, 1090), Bait = "Truffle Worm", Rod = "Nocturnal Rod" },
    { Name = "Phantom Ray", Zone = "The Depths Cave", Pos = Vector3.new(1200, -710, 1300), Bait = "Super Flakes", Rod = "Mythical Rod" },
    { Name = "Magma Fish", Zone = "Roslit Volcano", Pos = Vector3.new(-1900, 165, 300), Bait = "Instant Catch", Rod = "Magma Rod" },
    { Name = "Obsidian Salmon", Zone = "Roslit Volcano", Pos = Vector3.new(-1900, 165, 300), Bait = "Maggot", Rod = "Magma Rod" },
    { Name = "Sunken Golden Fish", Zone = "Sunstone Lighthouse", Pos = Vector3.new(-900, 230, -1200), Bait = "Rapid Catch", Rod = "Midas Rod" },
    { Name = "Voidfin Mahi", Zone = "Vertigo Entrance", Pos = Vector3.new(-110, -515, 1060), Bait = "Weird Algae", Rod = "Nocturnal Rod" },
    { Name = "Abyssal Shark", Zone = "Forsaken Shores Deep", Pos = Vector3.new(-2500, 135, 1550), Bait = "Fish Head", Rod = "Carbon Rod" },
    { Name = "Golden Seahorse", Zone = "Moosewood Docks", Pos = Vector3.new(358, 132, 199), Bait = "Seaweed", Rod = "Steady Rod" },
    { Name = "Glacier Salmon", Zone = "Snowcap Lake", Pos = Vector3.new(2620, 150, 2400), Bait = "Shrimp", Rod = "Fast Rod" },
    { Name = "Alligator", Zone = "Mushgrove Swamp", Pos = Vector3.new(2450, 135, -700), Bait = "Fish Head", Rod = "Kings Rod" },
    { Name = "Barracuda", Zone = "Grand Reef", Pos = Vector3.new(-3550, 135, 450), Bait = "Shrimp", Rod = "Rapid Rod" },
    { Name = "Anglerfish", Zone = "The Depths Floor", Pos = Vector3.new(1050, -710, 1180), Bait = "Glowworm", Rod = "Nocturnal Rod" },
    { Name = "Ancient Serpent", Zone = "Atlantis Trench", Pos = Vector3.new(-4250, -650, 1900), Bait = "Truffle Worm", Rod = "Destiny Rod" },
    { Name = "Whale Shark", Zone = "Ocean Open Sea", Pos = Vector3.new(1000, 135, -1250), Bait = "Fish Head", Rod = "Trident Rod" }
}

local TargetItemRegistry = {
    { Name = "Bait Crate", Pos = Vector3.new(358, 132, 199), Spot = "Moosewood Docks", RecommendedBait = "Magnet" },
    { Name = "Quality Bait Crate", Pos = Vector3.new(2620, 150, 2400), Spot = "Snowcap Island", RecommendedBait = "Magnet" },
    { Name = "Carbon Crate", Pos = Vector3.new(-1480, 135, 680), Spot = "Roslit Bay", RecommendedBait = "Magnet" },
    { Name = "Volcanic Geode", Pos = Vector3.new(-1900, 165, 300), Spot = "Roslit Volcano", RecommendedBait = "Magnet" },
    { Name = "Encrusted Geode", Pos = Vector3.new(990, -710, 1215), Spot = "The Depths", RecommendedBait = "Magnet" },
    { Name = "Strange Relic", Pos = Vector3.new(6000, 150, 400), Spot = "Ancient Isle", RecommendedBait = "Super Flakes" },
    { Name = "Sunken Treasure Chest", Pos = Vector3.new(-946, 131, -1117), Spot = "Sunstone Docks", RecommendedBait = "Magnet" },
    { Name = "Prehistoric Fossil", Pos = Vector3.new(2450, 135, -700), Spot = "Mushgrove Swamp", RecommendedBait = "Magnet" }
}

local BestSpotsRegistry = {
    { Name = "Moosewood Docks", Pos = Vector3.new(382, 134, 240), Description = "Fastest Starter Bite Rate & 100% Safe" },
    { Name = "Sunstone Lighthouse Cliff", Pos = Vector3.new(-900, 230, -1200), Description = "Daylight Golden Variants" },
    { Name = "Roslit Volcano Ledge", Pos = Vector3.new(-1900, 332, 300), Description = "Top C$ Magma Fish (Safe Upper Ledge)" },
    { Name = "The Depths Trench", Pos = Vector3.new(990, -710, 1215), Description = "Colossal Squid & Abyssal Legendaries" },
    { Name = "Vertigo Abyss", Pos = Vector3.new(-140, -510, 1090), Description = "Max Catch XP & Relics" },
    { Name = "Ancient Isle Shore", Pos = Vector3.new(6000, 150, 400), Description = "Megalodon Apex Hotspot" },
    { Name = "Snowcap Island Lake", Pos = Vector3.new(2620, 150, 2400), Description = "Glacial Catches & High Crates" },
    { Name = "Brine Pool", Pos = Vector3.new(-1790, -143, -3400), Description = "Alchemical Catches" },
    { Name = "Grand Reef", Pos = Vector3.new(-3550, 135, 450), Description = "Tropical Exotics & Whale Shark" },
    { Name = "Mushgrove Deep", Pos = Vector3.new(2450, 135, -700), Description = "Ancient Swamp Biome" }
}

local currentTargetFish = TargetFishRegistry[1]
local currentTargetItem = TargetItemRegistry[1]
local currentBestSpot = BestSpotsRegistry[1]

local function equipBaitRemote(baitName)
    pcall(function()
        local net = ReplicatedStorage:FindFirstChild("packages") and ReplicatedStorage.packages:FindFirstChild("Net")
        if net and baitName then
            local re = net:FindFirstChild("RE/Bait/Equip") or net:FindFirstChild("RF/Bait/Equip")
            if re and re:IsA("RemoteEvent") then
                re:FireServer(baitName)
            elseif re and re:IsA("RemoteFunction") then
                re:InvokeServer(baitName)
            end
        end
    end)
end

-- Autonomous Target Farm Anchor & Position Guardian
task.spawn(function()
    while true do
        task.wait(1)
        pcall(function()
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if not root then return end

            local activeTargetPos = nil
            if Config.AutoFarmFish and currentTargetFish then
                activeTargetPos = currentTargetFish.Pos
            elseif Config.AutoFarmItem and currentTargetItem then
                activeTargetPos = currentTargetItem.Pos
            elseif Config.AutoFarmSpot and currentBestSpot then
                activeTargetPos = currentBestSpot.Pos
            end

            if activeTargetPos then
                local dist = (root.Position - activeTargetPos).Magnitude
                if dist > 35 or root.Position.Y < activeTargetPos.Y - 15 then
                    root.AssemblyLinearVelocity = Vector3.zero
                    root.AssemblyAngularVelocity = Vector3.zero
                    root.CFrame = CFrame.new(activeTargetPos + Vector3.new(0, 3.5, 0))
                end
            end
        end)
    end
end)
local IslandRegistry = {
    { Name = "Moosewood", Pos = Vector3.new(380, 135, 230) },
    { Name = "Roslit Bay", Pos = Vector3.new(-1480, 135, 680) },
    { Name = "Sunstone Island", Pos = Vector3.new(-930, 220, -1120) },
    { Name = "Terrapin Island", Pos = Vector3.new(-180, 140, 1950) },
    { Name = "Snowcap Island", Pos = Vector3.new(2620, 150, 2400) },
    { Name = "Vertigo (Depths Entrance)", Pos = Vector3.new(-110, -515, 1060) },
    { Name = "The Depths", Pos = Vector3.new(990, -710, 1215) },
    { Name = "Desolate Deep", Pos = Vector3.new(-1650, -230, -2850) },
    { Name = "The Arch", Pos = Vector3.new(1000, 135, -1250) },
    { Name = "Mushgrove Swamp", Pos = Vector3.new(2450, 135, -700) },
    { Name = "Keepers Altar", Pos = Vector3.new(1300, -805, -250) },
    { Name = "Brine Pool", Pos = Vector3.new(-1790, -143, -3400) },
    { Name = "Forsaken Shores", Pos = Vector3.new(-2500, 135, 1550) },
    { Name = "Ancient Isle", Pos = Vector3.new(6000, 150, 400) },
    { Name = "Atlantis", Pos = Vector3.new(-4250, -650, 1900) },
    { Name = "Grand Reef", Pos = Vector3.new(-3550, 135, 450) },
    { Name = "Ethereal Abyss", Pos = Vector3.new(-1400, -1100, -3200) },
    { Name = "Scoria Reach", Pos = Vector3.new(-1750, 175, 450) },
    { Name = "Cursed Isle", Pos = Vector3.new(1450, 135, 3500) },
    { Name = "Statue of Sovereign", Pos = Vector3.new(25, 135, -1000) }
}

local NpcRegistry = {
    { Name = "Appraiser (Moosewood)", Pos = Vector3.new(452, 150, 206) },
    { Name = "Axel (Sunstone)", Pos = Vector3.new(-971, 199, -1068) },
    { Name = "Boneyard Bernie (Sunstone)", Pos = Vector3.new(-1016, 223, -967) },
    { Name = "Chloe (Sunstone)", Pos = Vector3.new(-920, 204, -1050) },
    { Name = "Construction Lead (Sunstone)", Pos = Vector3.new(-945, 218, -970) },
    { Name = "Construction Worker (Sunstone)", Pos = Vector3.new(-933, 241, -975) },
    { Name = "Crazy Cat Lady (Depths)", Pos = Vector3.new(2025, -648, 2460) },
    { Name = "Daisy (Moosewood)", Pos = Vector3.new(561, 167, 208) },
    { Name = "Disco Dan (Sunstone)", Pos = Vector3.new(-1063, 204, -937) },
    { Name = "Dr. Anton (Depths)", Pos = Vector3.new(2045, -648, 2465) },
    { Name = "Draven (Depths)", Pos = Vector3.new(1985, -648, 2435) },
    { Name = "Furnisher (Sunstone)", Pos = Vector3.new(-981, 223, -1002) },
    { Name = "Ghoulish Goblin (Moosewood)", Pos = Vector3.new(537, 175, 139) },
    { Name = "Henry (Moosewood)", Pos = Vector3.new(483, 152, 236) },
    { Name = "Hollow (Depths)", Pos = Vector3.new(2005, -648, 2445) },
    { Name = "Inn Keeper (Moosewood)", Pos = Vector3.new(487, 150, 231) },
    { Name = "Inn Keeper (Sunstone)", Pos = Vector3.new(-905, 131, -1105) },
    { Name = "Joseph (Sunstone)", Pos = Vector3.new(-925, 184, -1057) },
    { Name = "Ken Carson (Depths)", Pos = Vector3.new(1970, -648, 2420) },
    { Name = "Kenith (Sunstone)", Pos = Vector3.new(-1144, 134, -1078) },
    { Name = "Keystone (Sunstone)", Pos = Vector3.new(-938, 223, -983) },
    { Name = "Lucas (Moosewood)", Pos = Vector3.new(449, 181, 180) },
    { Name = "Marc Merchant (Moosewood)", Pos = Vector3.new(466, 151, 224) },
    { Name = "Marlon Friend (Moosewood Shipwright)", Pos = Vector3.new(358, 132, 199) },
    { Name = "Max Merchant (Sunstone)", Pos = Vector3.new(-930, 131, -1105) },
    { Name = "Merlin (Sunstone)", Pos = Vector3.new(-950, 222, -991) },
    { Name = "Moosewood Angler", Pos = Vector3.new(480, 150, 302) },
    { Name = "Mysterious Songstress (Depths)", Pos = Vector3.new(2010, -648, 2450) },
    { Name = "Oddie (Sunstone)", Pos = Vector3.new(-938, 199, -923) },
    { Name = "Phineas (Moosewood)", Pos = Vector3.new(469, 150, 277) },
    { Name = "Quiet Synph (Moosewood)", Pos = Vector3.new(566, 152, 353) },
    { Name = "Rhea (Sunstone)", Pos = Vector3.new(-1039, 203, -1116) },
    { Name = "Silver Scalper (Depths)", Pos = Vector3.new(2035, -648, 2470) },
    { Name = "Spirit of Darkness", Pos = Vector3.new(2092, 151, 1031) },
    { Name = "Spirit of Light", Pos = Vector3.new(20096, 1226, 5395) },
    { Name = "Sunstone Angler", Pos = Vector3.new(-887, 133, -1119) },
    { Name = "Sunstone Shipwright", Pos = Vector3.new(-946, 131, -1117) },
    { Name = "The Evil Guide (Depths)", Pos = Vector3.new(1960, -648, 2410) },
    { Name = "Thomas (Sunstone)", Pos = Vector3.new(-953, 199, -924) },
    { Name = "Todd (Moosewood)", Pos = Vector3.new(495, 158, 221) },
    { Name = "Totem Carver (Sunstone)", Pos = Vector3.new(-1027, 204, -936) },
    { Name = "Tryce (Depths)", Pos = Vector3.new(2030, -648, 2481) }
}

local PoiRegistry = {
    { Name = "Appraiser Stand (Moosewood)", Pos = Vector3.new(452, 150, 206) },
    { Name = "Brine Pool Altar", Pos = Vector3.new(-1810, -143, -3405) },
    { Name = "Deep Gate (Vertigo)", Pos = Vector3.new(-110, -515, 1060) },
    { Name = "Keepers Altar (Enchanting)", Pos = Vector3.new(1300, -805, -250) },
    { Name = "Merlin's Cliff (Sunstone)", Pos = Vector3.new(-950, 222, -991) },
    { Name = "Moosewood Docks", Pos = Vector3.new(358, 132, 199) },
    { Name = "Moosewood Lighthouse", Pos = Vector3.new(480, 175, 300) },
    { Name = "Rod Crafting Table", Pos = Vector3.new(1350, 135, -1250) },
    { Name = "Roslit Volcano Crater", Pos = Vector3.new(-1900, 165, 300) },
    { Name = "Snowcap Peak", Pos = Vector3.new(2650, 280, 2550) },
    { Name = "Sunstone Docks", Pos = Vector3.new(-946, 131, -1117) },
    { Name = "Sunstone Lighthouse", Pos = Vector3.new(-900, 230, -1200) },
    { Name = "Vertigo Waterfall", Pos = Vector3.new(-140, -510, 1090) }
}

local function safeTeleport(pos)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        root.CFrame = CFrame.new(pos + Vector3.new(0, 3.5, 0))
        Hub.Notify("Teleport", "Arrived at destination.", 2)
    end
end

--------------------------------------------------------------------------------
-- 10. USER INTERFACE TABS & CONTROLS
--------------------------------------------------------------------------------
local farmTab = Hub.CreateTab("Fishing", {
    Icon = "🎣",
    Size = 18,
    Color = Color3.fromRGB(0, 190, 255),
    ActiveColor = Color3.fromRGB(80, 220, 255)
})

Hub.CreateSection(farmTab, "Automation")

Hub.CreateToggle(farmTab, "Auto Cast", Config.AutoCast, function(val)
    Config.AutoCast = val
    Hub.Notify("Auto Cast", val and "Enabled" or "Disabled", 2)
end)

Hub.CreateSlider(farmTab, "Cast Power", 10, 100, Config.CastPower, "%", function(val)
    Config.CastPower = val
end)

Hub.CreateToggle(farmTab, "Auto Shake", Config.AutoShake, function(val)
    Config.AutoShake = val
    Hub.Notify("Auto Shake", val and "Enabled" or "Disabled", 2)
end)

Hub.CreateToggle(farmTab, "Instant Reel", Config.AutoReel, function(val)
    Config.AutoReel = val
    Hub.Notify("Instant Reel", val and "Enabled" or "Disabled", 2)
end)

-- Section: Target Fish Farm
Hub.CreateSection(farmTab, "Target Fish Farm")

local fishOptions = {}
for _, f in ipairs(TargetFishRegistry) do
    table.insert(fishOptions, f.Name .. " (" .. f.Zone .. ")")
end

Hub.CreateDropdown(farmTab, "Select Target Fish", fishOptions, fishOptions[1], function(val)
    local name = val:match("^(.-)%s*%(") or val
    for _, f in ipairs(TargetFishRegistry) do
        if f.Name == name then
            currentTargetFish = f
            if Config.AutoFarmFish then
                safeTeleport(f.Pos)
                if Config.AutoEquipTargetBait and f.Bait then
                    equipBaitRemote(f.Bait)
                end
            end
            break
        end
    end
end)

Hub.CreateToggle(farmTab, "Auto Farm Fish", Config.AutoFarmFish, function(val)
    Config.AutoFarmFish = val
    if val then
        Config.AutoFarmItem = false
        Config.AutoFarmSpot = false
        Config.AutoCast = true
        Config.AutoShake = true
        Config.AutoReel = true
        if currentTargetFish then
            safeTeleport(currentTargetFish.Pos)
            if Config.AutoEquipTargetBait and currentTargetFish.Bait then
                equipBaitRemote(currentTargetFish.Bait)
            end
            Hub.Notify("Target Fish", "Farming " .. currentTargetFish.Name .. " (" .. currentTargetFish.Zone .. ")", 3)
        end
    else
        Config.AutoCast = false
        Config.AutoShake = false
        Config.AutoReel = false
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum:UnequipTools() end
        Hub.Notify("Target Fish", "Auto Farm Fish Disabled", 2)
    end
end)

Hub.CreateToggle(farmTab, "Auto Equip Target Bait", Config.AutoEquipTargetBait, function(val)
    Config.AutoEquipTargetBait = val
    if val and currentTargetFish and currentTargetFish.Bait then
        equipBaitRemote(currentTargetFish.Bait)
    end
end)

Hub.CreateButton(farmTab, "Teleport to Fish Spot", function()
    if currentTargetFish then
        safeTeleport(currentTargetFish.Pos)
        if Config.AutoEquipTargetBait and currentTargetFish.Bait then
            equipBaitRemote(currentTargetFish.Bait)
        end
    end
end)

-- Section: Target Item Farm
Hub.CreateSection(farmTab, "Target Item Farm")

local itemOptions = {}
for _, itm in ipairs(TargetItemRegistry) do
    table.insert(itemOptions, itm.Name .. " (" .. itm.Spot .. ")")
end

Hub.CreateDropdown(farmTab, "Select Target Item", itemOptions, itemOptions[1], function(val)
    local name = val:match("^(.-)%s*%(") or val
    for _, itm in ipairs(TargetItemRegistry) do
        if itm.Name == name then
            currentTargetItem = itm
            if Config.AutoFarmItem then
                safeTeleport(itm.Pos)
                if itm.RecommendedBait then
                    equipBaitRemote(itm.RecommendedBait)
                end
            end
            break
        end
    end
end)

Hub.CreateToggle(farmTab, "Auto Farm Items", Config.AutoFarmItem, function(val)
    Config.AutoFarmItem = val
    if val then
        Config.AutoFarmFish = false
        Config.AutoFarmSpot = false
        Config.AutoCast = true
        Config.AutoShake = true
        Config.AutoReel = true
        if currentTargetItem then
            safeTeleport(currentTargetItem.Pos)
            if currentTargetItem.RecommendedBait then
                equipBaitRemote(currentTargetItem.RecommendedBait)
            end
            Hub.Notify("Target Item", "Farming " .. currentTargetItem.Name .. " at " .. currentTargetItem.Spot, 3)
        end
    else
        Config.AutoCast = false
        Config.AutoShake = false
        Config.AutoReel = false
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum:UnequipTools() end
        Hub.Notify("Target Item", "Auto Farm Items Disabled", 2)
    end
end)

Hub.CreateButton(farmTab, "Teleport to Item Spot", function()
    if currentTargetItem then
        safeTeleport(currentTargetItem.Pos)
        if currentTargetItem.RecommendedBait then
            equipBaitRemote(currentTargetItem.RecommendedBait)
        end
    end
end)

-- Section: Best Farming Spots
Hub.CreateSection(farmTab, "Best Farming Spots")

local bestSpotOptions = {}
for _, sp in ipairs(BestSpotsRegistry) do
    table.insert(bestSpotOptions, sp.Name)
end

Hub.CreateDropdown(farmTab, "Select Best Spot", bestSpotOptions, bestSpotOptions[1], function(val)
    for _, sp in ipairs(BestSpotsRegistry) do
        if sp.Name == val then
            currentBestSpot = sp
            if Config.AutoFarmSpot then
                safeTeleport(sp.Pos)
            end
            break
        end
    end
end)

Hub.CreateButton(farmTab, "Teleport to Best Spot", function()
    if currentBestSpot then
        safeTeleport(currentBestSpot.Pos)
    end
end)

Hub.CreateToggle(farmTab, "Auto Farm at Best Spot", Config.AutoFarmSpot, function(val)
    Config.AutoFarmSpot = val
    if val then
        Config.AutoFarmFish = false
        Config.AutoFarmItem = false
        Config.AutoCast = true
        Config.AutoShake = true
        Config.AutoReel = true
        if currentBestSpot then
            safeTeleport(currentBestSpot.Pos)
            Hub.Notify("Spot Farm", "Farming at " .. currentBestSpot.Name, 3)
        end
    else
        Config.AutoCast = false
        Config.AutoShake = false
        Config.AutoReel = false
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum:UnequipTools() end
        Hub.Notify("Spot Farm", "Auto Farm Spot Disabled", 2)
    end
end)

-- Section: Sales
Hub.CreateSection(farmTab, "Sales")

Hub.CreateToggle(farmTab, "Auto Sell", Config.AutoSell, function(val)
    Config.AutoSell = val
    Hub.Notify("Auto Sell", val and "Enabled" or "Disabled", 2)
end)

Hub.CreateButton(farmTab, "Sell All Fish", function()
    executeAutoSell()
    Hub.Notify("Sales", "Sold all fish.", 2)
end)

local shopTab = Hub.CreateTab("Shop", {
    Icon = "🛒",
    Size = 18,
    Color = Color3.fromRGB(255, 170, 0),
    ActiveColor = Color3.fromRGB(255, 200, 50)
})

-- Section: Fishing Rods
Hub.CreateSection(shopTab, "Fishing Rods")
local selectedRod = RodRegistry[1]
local rodOptions = {}
for _, item in ipairs(RodRegistry) do
    table.insert(rodOptions, item.Name .. " | " .. formatPrice(item.Price))
end
Hub.CreateDropdown(shopTab, "Select Rod", rodOptions, rodOptions[1], function(val)
    local name = val:match("^(.-)%s*|") or val
    for _, item in ipairs(RodRegistry) do
        if item.Name == name then
            selectedRod = item
            break
        end
    end
end)
Hub.CreateButton(shopTab, "Buy Selected Rod", function()
    if selectedRod then
        purchaseItemAtLocation(selectedRod.Pos, selectedRod.Name)
    end
end)

-- Section: Totems & Relics
Hub.CreateSection(shopTab, "Totems & Relics")
local selectedTotem = TotemRegistry[1]
local totemOptions = {}
for _, item in ipairs(TotemRegistry) do
    table.insert(totemOptions, item.Name .. " | " .. formatPrice(item.Price))
end
Hub.CreateDropdown(shopTab, "Select Totem / Relic", totemOptions, totemOptions[1], function(val)
    local name = val:match("^(.-)%s*|") or val
    for _, item in ipairs(TotemRegistry) do
        if item.Name == name then
            selectedTotem = item
            break
        end
    end
end)
Hub.CreateButton(shopTab, "Buy Selected Totem / Relic", function()
    if selectedTotem then
        purchaseItemAtLocation(selectedTotem.Pos, selectedTotem.Name)
    end
end)

-- Section: Diving & Gear
Hub.CreateSection(shopTab, "Diving & Gear")
local selectedGear = GearRegistry[1]
local gearOptions = {}
for _, item in ipairs(GearRegistry) do
    table.insert(gearOptions, item.Name .. " | " .. formatPrice(item.Price))
end
Hub.CreateDropdown(shopTab, "Select Gear", gearOptions, gearOptions[1], function(val)
    local name = val:match("^(.-)%s*|") or val
    for _, item in ipairs(GearRegistry) do
        if item.Name == name then
            selectedGear = item
            break
        end
    end
end)
Hub.CreateButton(shopTab, "Buy Selected Gear", function()
    if selectedGear then
        purchaseItemAtLocation(selectedGear.Pos, selectedGear.Name)
    end
end)

-- Section: Utility & Tools
Hub.CreateSection(shopTab, "Utility & Tools")
local selectedUtility = UtilityRegistry[1]
local utilityOptions = {}
for _, item in ipairs(UtilityRegistry) do
    table.insert(utilityOptions, item.Name .. " | " .. formatPrice(item.Price))
end
Hub.CreateDropdown(shopTab, "Select Utility", utilityOptions, utilityOptions[1], function(val)
    local name = val:match("^(.-)%s*|") or val
    for _, item in ipairs(UtilityRegistry) do
        if item.Name == name then
            selectedUtility = item
            break
        end
    end
end)
Hub.CreateButton(shopTab, "Buy Selected Utility", function()
    if selectedUtility then
        purchaseItemAtLocation(selectedUtility.Pos, selectedUtility.Name)
    end
end)

-- Section: Bait & Crates
Hub.CreateSection(shopTab, "Bait & Crates")
local selectedBait = BaitRegistry[1]
local baitOptions = {}
for _, item in ipairs(BaitRegistry) do
    table.insert(baitOptions, item.Name .. " | " .. formatPrice(item.Price))
end
Hub.CreateDropdown(shopTab, "Select Bait", baitOptions, baitOptions[1], function(val)
    local name = val:match("^(.-)%s*|") or val
    for _, item in ipairs(BaitRegistry) do
        if item.Name == name then
            selectedBait = item
            break
        end
    end
end)
Hub.CreateButton(shopTab, "Buy Selected Bait", function()
    if selectedBait then
        purchaseItemAtLocation(selectedBait.Pos, selectedBait.Name)
    end
end)

-- Section: Boats
Hub.CreateSection(shopTab, "Boats")
local selectedBoat = BoatRegistry[1]
local boatOptions = {}
for _, item in ipairs(BoatRegistry) do
    table.insert(boatOptions, item.Name .. " | " .. formatPrice(item.Price))
end
Hub.CreateDropdown(shopTab, "Select Boat", boatOptions, boatOptions[1], function(val)
    local name = val:match("^(.-)%s*|") or val
    for _, item in ipairs(BoatRegistry) do
        if item.Name == name then
            selectedBoat = item
            break
        end
    end
end)
Hub.CreateButton(shopTab, "Buy Selected Boat", function()
    if selectedBoat then
        purchaseBoat(selectedBoat.Name)
    end
end)

local utilTab = Hub.CreateTab("Utility", {
    Icon = "⚡",
    Size = 18,
    Color = Color3.fromRGB(0, 255, 170),
    ActiveColor = Color3.fromRGB(80, 255, 200)
})

Hub.CreateSection(utilTab, "Player")

Hub.CreateToggle(utilTab, "Walk on Water", Config.WalkOnWater, function(val)
    Config.WalkOnWater = val
    toggleWaterWalk(val)
    Hub.Notify("Utility", val and "Walk on Water enabled" or "Walk on Water disabled", 2)
end)

Hub.CreateToggle(utilTab, "Infinite Oxygen", Config.InfiniteOxygen, function(val)
    Config.InfiniteOxygen = val
    Hub.Notify("Utility", val and "Infinite Oxygen enabled" or "Infinite Oxygen disabled", 2)
end)

Hub.CreateButton(utilTab, "Fullbright", function()
    pcall(function()
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    end)
    Hub.Notify("Visuals", "Fullbright activated.", 2)
end)

local tpTab = Hub.CreateTab("Teleports", {
    Icon = "📍",
    Size = 18,
    Color = Color3.fromRGB(255, 180, 0),
    ActiveColor = Color3.fromRGB(255, 210, 50)
})

-- Section: Islands & Areas
Hub.CreateSection(tpTab, "Islands & Areas")
local selectedIsland = IslandRegistry[1]
local islandOptions = {}
for _, item in ipairs(IslandRegistry) do
    table.insert(islandOptions, item.Name)
end
Hub.CreateDropdown(tpTab, "Select Area", islandOptions, islandOptions[1], function(val)
    for _, item in ipairs(IslandRegistry) do
        if item.Name == val then
            selectedIsland = item
            break
        end
    end
end)
Hub.CreateButton(tpTab, "Teleport to Area", function()
    if selectedIsland then
        safeTeleport(selectedIsland.Pos)
    end
end)

-- Section: All NPCs
Hub.CreateSection(tpTab, "All NPCs")
local selectedNpc = NpcRegistry[1]
local npcOptions = {}
for _, item in ipairs(NpcRegistry) do
    table.insert(npcOptions, item.Name)
end
Hub.CreateDropdown(tpTab, "Select NPC", npcOptions, npcOptions[1], function(val)
    for _, item in ipairs(NpcRegistry) do
        if item.Name == val then
            selectedNpc = item
            break
        end
    end
end)
Hub.CreateButton(tpTab, "Teleport to NPC", function()
    if selectedNpc then
        safeTeleport(selectedNpc.Pos)
    end
end)

-- Section: Points of Interest
Hub.CreateSection(tpTab, "Points of Interest")
local selectedPoi = PoiRegistry[1]
local poiOptions = {}
for _, item in ipairs(PoiRegistry) do
    table.insert(poiOptions, item.Name)
end
Hub.CreateDropdown(tpTab, "Select Point of Interest", poiOptions, poiOptions[1], function(val)
    for _, item in ipairs(PoiRegistry) do
        if item.Name == val then
            selectedPoi = item
            break
        end
    end
end)
Hub.CreateButton(tpTab, "Teleport to POI", function()
    if selectedPoi then
        safeTeleport(selectedPoi.Pos)
    end
end)

Hub.Notify("Unknown Hub", "Fisch Suite Loaded 🎣", 3)
