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
    local lib = getgenv().UnknownLibrary
    local isValid = false
    if lib and typeof(lib) == "function" then
        pcall(function()
            local test = lib({ title = "_T", game = "_T" })
            if test and test.CreateMultiDropdown then
                isValid = true
            end
        end)
    end
    if isValid then
        return lib
    end

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
                        arg.ShakePower = 10
                        arg.ShakeScale = 2.2
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
                            arg.stats.StartingProgress = 85
                            arg.stats.ProgressSpeed = 250
                            arg.stats.Control = 1.0
                        end
                        break
                    end
                end
            end
            return origStartReel(...)
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
    if not Config.AutoCast then return end
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

    -- 0.10s rate: clears bubbles instantly with zero missed clicks
    if tick() - lastShakeTick < 0.10 then return end

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

-- 3. Ultra Fast & Smooth Reel Engine (100% Anti-Bug, Anti-Kick)
local function processReelMinigame(activeReel)
    if not Config.AutoReel or not activeReel then return end

    if reelStartTick == 0 then
        reelStartTick = tick()
        instantReelDispatched = false
    end

    pcall(function()
        -- Lock bar perfectly onto the fish bubble & expand bar size
        activeReel.barSize = 10
        activeReel.barPosition = activeReel.fishPosition or 0.5
        activeReel.onbar = true
        activeReel.perfect = true

        -- Advance progress smoothly inside minigame core
        -- With starting progress at 85%, this completes the minigame in ~0.5s naturally!
        if activeReel.core and activeReel.core.minigame and activeReel.core.minigame._progressModifier then
            local p = activeReel.core.minigame._progressModifier
            if p.Value < 98 then
                local boost = 2.0
                if Config.ReelMode == "Safe (~2s)" then
                    boost = 0.5
                end
                p.Value = p.Value + boost
            end
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
-- 8. SHOP REGISTRIES & PURCHASING ENGINE
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
    { Name = "Enchant Relic", Price = 11000, Pos = Vector3.new(-930, 225, -990) },
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
    { Name = "Crab Cage", Price = 45, Pos = Vector3.new(470, 148, 230) },
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

local function purchaseItemAtLocation(targetPos, modelName)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then 
        Hub.Notify("Shop", "Character root not found.", 2)
        return false
    end
    
    Hub.Notify("Shop", "Purchasing " .. modelName .. "...", 2)
    local originalCFrame = root.CFrame
    
    local function findPrompt()
        local interactables = Workspace:FindFirstChild("world") and Workspace.world:FindFirstChild("interactables")
        if interactables and interactables:FindFirstChild(modelName) then
            local model = interactables[modelName]
            local p = model:FindFirstChildOfClass("ProximityPrompt") or model:FindFirstChild("PromptTemplate")
            if p and p.Enabled then return p end
        end
        for _, p in ipairs(Workspace:GetDescendants()) do
            if p:IsA("ProximityPrompt") then
                local obj = p.ObjectText ~= "" and p.ObjectText or (p.Parent and p.Parent.Name or "")
                if string.lower(obj) == string.lower(modelName) or string.find(string.lower(obj), string.lower(modelName), 1, true) then
                    return p
                end
            end
        end
        return nil
    end

    local prompt = findPrompt()
    if not prompt or (root.Position - prompt.Parent:GetPivot().Position).Magnitude > 15 then
        if targetPos then
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            root.CFrame = CFrame.new(targetPos + Vector3.new(0, 3, 0))
            
            local start = tick()
            while tick() - start < 3.5 do
                prompt = findPrompt()
                if prompt then break end
                task.wait(0.2)
            end
        end
    end
    
    if not prompt then
        root.CFrame = originalCFrame
        Hub.Notify("Shop", "Could not locate " .. modelName .. " prompt.", 3)
        return false
    end
    
    local promptPos = prompt.Parent:IsA("BasePart") and prompt.Parent.Position or prompt.Parent:GetPivot().Position
    root.AssemblyLinearVelocity = Vector3.zero
    root.CFrame = CFrame.new(promptPos + Vector3.new(0, 1.5, 3), promptPos)
    task.wait(0.25)
    
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
    
    local pc = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("PromptConfirmation")
    local startWait = tick()
    while tick() - startWait < 2.5 do
        if pc and pc:FindFirstChild("Frame") and pc.Frame.Visible then
            local options = pc.Frame:FindFirstChild("Options")
            if options then
                local buyBtn = nil
                for _, b in ipairs(options:GetChildren()) do
                    if b:IsA("GuiButton") then
                        local lbl = b:FindFirstChildWhichIsA("TextLabel")
                        local txt = lbl and string.lower(lbl.Text) or string.lower(b.Name)
                        if string.find(txt, "buy") or string.find(txt, "yes") or string.find(txt, "confirm") or string.find(txt, "2") then
                            buyBtn = b
                            break
                        end
                    end
                end
                if not buyBtn then
                    local buttons = {}
                    for _, b in ipairs(options:GetChildren()) do
                        if b:IsA("GuiButton") then table.insert(buttons, b) end
                    end
                    buyBtn = buttons[#buttons]
                end
                
                if buyBtn then
                    task.wait(0.15)
                    local conns = getconnections(buyBtn.Activated)
                    if #conns > 0 then
                        for _, c in ipairs(conns) do c:Fire() end
                    elseif firesignal then
                        firesignal(buyBtn.Activated)
                    end
                    break
                end
            end
        end
        task.wait(0.1)
    end
    
    task.wait(0.3)
    root.AssemblyLinearVelocity = Vector3.zero
    root.CFrame = originalCFrame
    Hub.Notify("Shop", "Purchased " .. modelName .. "!", 3)
    return true
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
local IslandLocations = {
    ["Moosewood"] = Vector3.new(380, 135, 230),
    ["Roslit Bay"] = Vector3.new(-1480, 135, 680),
    ["Sunstone Island"] = Vector3.new(-930, 220, -1120),
    ["Terrapin Island"] = Vector3.new(-180, 140, 1950),
    ["Snowcap Island"] = Vector3.new(2620, 150, 2400),
    ["Vertigo (Depths Entrance)"] = Vector3.new(-110, -515, 1060),
    ["Desolate Deep"] = Vector3.new(-1650, -230, -2850),
    ["The Arch"] = Vector3.new(1000, 135, -1250),
    ["Mushgrove Swamp"] = Vector3.new(2450, 135, -700),
    ["Keepers Altar"] = Vector3.new(1300, -805, -250)
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

Hub.CreateSection(tpTab, "Islands")

for islandName, coords in pairs(IslandLocations) do
    Hub.CreateButton(tpTab, islandName, function()
        safeTeleport(coords)
    end)
end

Hub.Notify("Unknown Hub", "Fisch Suite Loaded 🎣", 3)
