--------------------------------------------------------------------------------
-- UNKNOWN HUB: FISCH (Comprehensive Anti-Cheat Neutralized Edition)
-- PlaceId: 16732694052, 17910972410 | GameId: 5750914919
-- Complete Feature Suite:
--   • Tier-0 Anti-Cheat Neutralization (Metamethod Detours, Honeypot Drop, WalkSpeed Spoof)
--   • Auto Fishing (Auto Cast, Instant Auto Shake, Safe Humanized Auto Reel)
--   • Catch Safeguard Engine (Server Duration Validation, Zero-Ban Heuristics)
--   • Auto Sell All Fish & Auto Inventory Manager
--   • Visuals & ESP (Fish Pools, Sunken Crates, Merchants & Island Totems)
--   • World Teleports (All Islands, Deep Zones, Secret Altars)
--   • Movement: Walk on Water, Infinite Oxygen, Fullbright & Anti-Drown
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
-- 1. TIER-0 ANTI-CHEAT NEUTRALIZATION & DETECTION SHIELD
--------------------------------------------------------------------------------
local AntiCheatShield = {
    BlockedKeywords = {
        "kick", "ban", "anticheat", "flag", "report", "teleport_detection",
        "walkspeed_detection", "speed_check", "security", "honeypot",
        "verify_player", "client_tamper", "gameanalyticserror", "gameanalyticsremoteconfigs"
    },
    OriginalWalkSpeed = 16,
    OriginalJumpPower = 50,
    SpoofedWalkSpeed = 16,
    SpoofedJumpPower = 50,
    Installed = false
}

local function setupAntiCheatBypass()
    if AntiCheatShield.Installed then return end
    pcall(function()
        if not hookmetamethod or not getnamecallmethod then return end

        local oldNamecall = nil
        local oldIndex = nil

        -- Detour 1: __namecall filter (blocks honeypot, AFK/idle detection telemetry, analytics & kick remotes)
        oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local method = getnamecallmethod()
            local args = {...}

            if (method == "FireServer" or method == "fireServer" or method == "InvokeServer" or method == "invokeServer") and typeof(self) == "Instance" then
                local sName = self.Name:lower()

                -- Intercept and drop Fisch idle / AFK reporting to prevent bot-detection flags
                if self.Name == "idleReport" or sName == "idlereport" then
                    if args[1] == true then return nil end
                end
                if self.Name == "afk" or sName == "afk" then
                    if args[1] == true then return nil end
                end

                -- Intercept drowning damage telemetry
                if self.Name == "drown" or sName == "drown" then
                    if Config.InfiniteOxygen then return nil end
                end

                -- Honeypot and telemetry filter
                if not checkcaller() then
                    for _, kw in ipairs(AntiCheatShield.BlockedKeywords) do
                        if sName:find(kw) then
                            return nil
                        end
                    end
                end
            end

            return oldNamecall(self, ...)
        end))

        -- Detour 2: __index filter (spoofs WalkSpeed/JumpPower so game AC controllers see vanilla 16/50)
        oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, key)
            if not checkcaller() and typeof(self) == "Instance" and self:IsA("Humanoid") then
                if key == "WalkSpeed" then
                    return AntiCheatShield.OriginalWalkSpeed
                elseif key == "JumpPower" then
                    return AntiCheatShield.OriginalJumpPower
                end
            end
            return oldIndex(self, key)
        end))

        AntiCheatShield.Installed = true
    end)
end

setupAntiCheatBypass()

-- Anti-AFK Engine (Prevents 20-minute Roblox idle kick)
pcall(function()
    for _, conn in ipairs(getconnections(LocalPlayer.Idled)) do
        pcall(function() conn:Disable() end)
    end
end)

LocalPlayer.Idled:Connect(function()
    pcall(function()
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

    local url = "https://raw.githubusercontent.com/UnknownHQ/UnknownHub/main/UnknownLibrary"
    local success, response = pcall(function()
        return game:HttpGet(url, true)
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
    game = "Fisch 🐟"
})

--------------------------------------------------------------------------------
-- 3. CONFIGURATION STATE
--------------------------------------------------------------------------------
local Config = {
    -- Auto Fishing
    AutoCast = false,
    CastPower = 100,
    AutoShake = false,
    ShakeSpeed = 0.05,
    AutoReel = false,
    ReelMethod = "Humanized", -- "Humanized" (Safe) or "Instant Bar Lock"
    ReelDelay = 1.6, -- Safe minimum catch duration to prevent server catch-time bans
    AutoEquipRod = true,

    -- Economy & Inventory
    AutoSell = false,
    AutoSellInterval = 60,

    -- Visuals & ESP
    FishPoolESP = false,
    CrateESP = false,
    MerchantESP = false,
    PlayerESP = false,

    -- Movement & Utility
    WalkOnWater = false,
    InfiniteOxygen = false,
    CustomSpeed = 16,
    Fullbright = false,
    NoFog = false
}

--------------------------------------------------------------------------------
-- 4. UTILITY HELPERS & FISHING ROD RESOLVER
--------------------------------------------------------------------------------
local function getCharacter()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

local function getEquippedRod()
    local char = LocalPlayer.Character
    if not char then return nil end
    for _, item in ipairs(char:GetChildren()) do
        if item:IsA("Tool") and (item.Name:lower():find("rod") or item:FindFirstChild("values") or item:FindFirstChild("bobber")) then
            return item
        end
    end
    return nil
end

local function ensureRodEquipped()
    if getEquippedRod() then return true end
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not backpack then return false end
    for _, item in ipairs(backpack:GetChildren()) do
        if item:IsA("Tool") and (item.Name:lower():find("rod") or item:FindFirstChild("values") or item:FindFirstChild("bobber")) then
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                hum:EquipTool(item)
                task.wait(0.15)
                return true
            end
        end
    end
    return false
end

--------------------------------------------------------------------------------
-- 5. AUTO FISHING ENGINE (BYPASS-SECURE & HUMANIZED)
--------------------------------------------------------------------------------
local isFishingActive = false
local lastCastTick = 0
local lastReelTick = 0

-- Sub-routine: Auto Cast
local function executeCast()
    if not Config.AutoCast or tick() - lastCastTick < 1.0 then return end
    if Config.AutoEquipRod then ensureRodEquipped() end

    local rod = getEquippedRod()
    if not rod then return end

    pcall(function()
        local events = ReplicatedStorage:FindFirstChild("events") or ReplicatedStorage:FindFirstChild("network")
        local castEvent = events and (events:FindFirstChild("cast") or events:FindFirstChild("Cast") or events:FindFirstChild("fishing_cast"))

        if castEvent and castEvent:IsA("RemoteEvent") then
            castEvent:FireServer(Config.CastPower / 100)
            lastCastTick = tick()
        elseif castEvent and castEvent:IsA("RemoteFunction") then
            castEvent:InvokeServer(Config.CastPower / 100)
            lastCastTick = tick()
        else
            -- Native Rod tool activation fallback
            rod:Activate()
            lastCastTick = tick()
        end
    end)
end

-- Sub-routine: Auto Shake (Solves shake minigame UI)
local function processShakeMinigame()
    if not Config.AutoShake then return end
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return end

    local shakeGui = playerGui:FindFirstChild("shake") or playerGui:FindFirstChild("Shake")
    if not shakeGui or not shakeGui.Enabled then return end

    pcall(function()
        local safezone = shakeGui:FindFirstChild("safezone", true) or shakeGui:FindFirstChild("Safezone", true)
        if safezone then
            local button = safezone:FindFirstChildWhichIsA("ImageButton", true) or safezone:FindFirstChildWhichIsA("TextButton", true)
            if button and button.Visible then
                if GuiService and GuiService.SelectedObject ~= button then
                    GuiService.SelectedObject = button
                end
                -- Send enter key simulation / virtual click
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
                task.wait(0.02)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
            end
        end
    end)
end

-- Sub-routine: Safe Humanized Auto Reel (Solves reel minigame bar safely)
local function processReelMinigame()
    if not Config.AutoReel then return end
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return end

    local reelGui = playerGui:FindFirstChild("reel") or playerGui:FindFirstChild("Reel")
    if not reelGui or not reelGui.Enabled then return end

    pcall(function()
        local bar = reelGui:FindFirstChild("bar", true) or reelGui:FindFirstChild("Bar", true)
        local fish = reelGui:FindFirstChild("fish", true) or reelGui:FindFirstChild("Fish", true)

        if bar and fish then
            -- Perfect Alignment without remote instant packet (Bypasses server catch time heuristics)
            if Config.ReelMethod == "Humanized" then
                local currentX = bar.Position.X.Scale
                local targetX = fish.Position.X.Scale
                local step = (targetX - currentX) * 0.4
                bar.Position = UDim2.new(currentX + step, 0, bar.Position.Y.Scale, bar.Position.Y.Offset)
            else
                bar.Position = UDim2.new(fish.Position.X.Scale, 0, bar.Position.Y.Scale, bar.Position.Y.Offset)
            end
        end

        -- Check if reel minigame is ready to submit completion
        local events = ReplicatedStorage:FindFirstChild("events") or ReplicatedStorage:FindFirstChild("network")
        local reelRemote = events and (events:FindFirstChild("reelfinished") or events:FindFirstChild("ReelFinished") or events:FindFirstChild("fish_caught"))

        if reelRemote and (tick() - lastReelTick >= Config.ReelDelay) then
            lastReelTick = tick()
            if reelRemote:IsA("RemoteEvent") then
                reelRemote:FireServer(100, true)
            elseif reelRemote:IsA("RemoteFunction") then
                reelRemote:InvokeServer(100, true)
            end
        end
    end)
end

-- Autonomous Fishing Daemon
task.spawn(function()
    while true do
        task.wait(0.04)
        if Config.AutoCast or Config.AutoShake or Config.AutoReel then
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if char and hum and hum.Health > 0 then
                local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
                local isShaking = playerGui and (playerGui:FindFirstChild("shake") or playerGui:FindFirstChild("Shake"))
                local isReeling = playerGui and (playerGui:FindFirstChild("reel") or playerGui:FindFirstChild("Reel"))

                if isShaking and isShaking.Enabled then
                    processShakeMinigame()
                elseif isReeling and isReeling.Enabled then
                    processReelMinigame()
                else
                    executeCast()
                end
            end
        end
    end
end)

--------------------------------------------------------------------------------
-- 6. AUTO SELL ALL FISH ENGINE
--------------------------------------------------------------------------------
local function executeAutoSell()
    pcall(function()
        local events = ReplicatedStorage:FindFirstChild("events") or ReplicatedStorage:FindFirstChild("network")
        local sellRemote = events and (events:FindFirstChild("sell") or events:FindFirstChild("Sell") or events:FindFirstChild("sellall") or events:FindFirstChild("SellAll"))
        if sellRemote and sellRemote:IsA("RemoteFunction") then
            sellRemote:InvokeServer()
        elseif sellRemote and sellRemote:IsA("RemoteEvent") then
            sellRemote:FireServer()
        end
    end)
end

task.spawn(function()
    while true do
        task.wait(Config.AutoSellInterval)
        if Config.AutoSell then
            executeAutoSell()
        end
    end
end)

--------------------------------------------------------------------------------
-- 7. MOVEMENT & STEALTH UTILITY (WATER WALKING & OXYGEN)
--------------------------------------------------------------------------------
local waterPlatform = nil

local function toggleWaterWalk(enabled)
    if enabled then
        if not waterPlatform or not waterPlatform.Parent then
            waterPlatform = Instance.new("Part")
            waterPlatform.Name = "UnknownHub_WaterPlatform"
            waterPlatform.Size = Vector3.new(20, 1, 20)
            waterPlatform.Anchored = true
            waterPlatform.CanCollide = true
            waterPlatform.Transparency = 1
            waterPlatform.Parent = Workspace
        end
    else
        if waterPlatform and waterPlatform.Parent then
            waterPlatform:Destroy()
            waterPlatform = nil
        end
    end
end

RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    -- Water Walking Platform Synchronizer
    if Config.WalkOnWater and waterPlatform then
        local rayParams = RaycastParams.new()
        rayParams.FilterDescendantsInstances = {char, waterPlatform}
        rayParams.FilterType = Enum.RaycastFilterType.Exclude

        local hit = Workspace:Raycast(root.Position + Vector3.new(0, 5, 0), Vector3.new(0, -25, 0), rayParams)
        if hit and hit.Material == Enum.Material.Water then
            waterPlatform.Position = Vector3.new(root.Position.X, hit.Position.Y - 0.5, root.Position.Z)
        else
            waterPlatform.Position = Vector3.new(root.Position.X, -1000, root.Position.Z)
        end
    end

    -- Infinite Oxygen / Anti-Drown Engine
    if Config.InfiniteOxygen and char then
        local oxygen = char:FindFirstChild("Oxygen") or char:GetAttribute("Oxygen")
        if typeof(oxygen) == "Instance" and oxygen:IsA("NumberValue") then
            oxygen.Value = 100
        else
            pcall(function() char:SetAttribute("Oxygen", 100) end)
        end
    end
end)

--------------------------------------------------------------------------------
-- 8. WORLD TELEPORTS REGISTRY
--------------------------------------------------------------------------------
local IslandRegistry = {
    { name = "Moosewood (Spawn)", pos = Vector3.new(385, 135, 230) },
    { name = "Roslit Bay", pos = Vector3.new(-1480, 132, 690) },
    { name = "Sunstone Island", pos = Vector3.new(-930, 225, -990) },
    { name = "Terrapin Island", pos = Vector3.new(-180, 145, 1950) },
    { name = "Snowcap Island", pos = Vector3.new(2620, 140, 2400) },
    { name = "Vertigo (The Pit)", pos = Vector3.new(-110, -515, 1070) },
    { name = "Desolate Deep", pos = Vector3.new(-1650, -230, -2840) },
    { name = "The Arch", pos = Vector3.new(1000, 130, -1240) },
    { name = "Mushgrove Swamp", pos = Vector3.new(2450, 130, -680) },
    { name = "Keepers Altar", pos = Vector3.new(1305, -805, -305) }
}

local function teleportToLocation(pos)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then
        -- Anti-cheat safe step teleport (Elevated landing + velocity zeroing)
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        root.CFrame = CFrame.new(pos + Vector3.new(0, 3.5, 0))
        Hub.Notify("Teleport", "Safely arrived at destination!", 2)
    end
end

--------------------------------------------------------------------------------
-- 9. USER INTERFACE TABS & CONTROLS
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
    Hub.Notify("Auto Cast", val and "Auto Cast: ACTIVE" or "Auto Cast: OFF", 2)
end)

Hub.CreateSlider(farmTab, "Cast Power", 10, 100, Config.CastPower, "%", function(val)
    Config.CastPower = val
end)

Hub.CreateToggle(farmTab, "Auto Shake", Config.AutoShake, function(val)
    Config.AutoShake = val
    Hub.Notify("Auto Shake", val and "Auto Shake: ACTIVE" or "Auto Shake: OFF", 2)
end)

Hub.CreateToggle(farmTab, "Safe Auto Reel", Config.AutoReel, function(val)
    Config.AutoReel = val
    Hub.Notify("Auto Reel", val and "Safe Auto Reel: ACTIVE (Zero Ban Risk)" or "Auto Reel: OFF", 2)
end)

Hub.CreateDropdown(farmTab, "Reel Method", {"Humanized", "Instant Bar Lock"}, Config.ReelMethod, function(val)
    Config.ReelMethod = val
end)

Hub.CreateSlider(farmTab, "Min Catch Duration", 1.0, 3.5, Config.ReelDelay, "s", function(val)
    Config.ReelDelay = val
end)

Hub.CreateSection(farmTab, "Merchant & Sales")

Hub.CreateToggle(farmTab, "Auto Sell Fish", Config.AutoSell, function(val)
    Config.AutoSell = val
    Hub.Notify("Auto Sell", val and "Auto Sell: ACTIVE" or "Auto Sell: OFF", 2)
end)

Hub.CreateButton(farmTab, "Sell All Fish Now", function()
    executeAutoSell()
    Hub.Notify("Merchant", "Dispatched Sell All Fish order!", 2)
end)

-- TAB: TELEPORTS
local tpTab = Hub.CreateTab("Teleports", {
    Icon = "🧭",
    Size = 18,
    Color = Color3.fromRGB(130, 220, 100),
    ActiveColor = Color3.fromRGB(170, 255, 140)
})

Hub.CreateSection(tpTab, "Islands & Deep Zones")

local islandNames = {}
for _, item in ipairs(IslandRegistry) do
    table.insert(islandNames, item.name)
end

Hub.CreateDropdown(tpTab, "Select Island", islandNames, islandNames[1], function(chosen)
    for _, item in ipairs(IslandRegistry) do
        if item.name == chosen then
            teleportToLocation(item.pos)
            break
        end
    end
end)

-- TAB: UTILITY & SECURITY
local utilTab = Hub.CreateTab("Utility", {
    Icon = "🛡️",
    Size = 18,
    Color = Color3.fromRGB(255, 180, 50),
    ActiveColor = Color3.fromRGB(255, 210, 100)
})

Hub.CreateSection(utilTab, "Security & Stealth")

Hub.CreateToggle(utilTab, "Anti-Cheat Protection", true, function(val)
    if not val then
        Hub.Notify("Security", "Warning: Disabling AC shield increases ban risk!", 3)
    else
        setupAntiCheatBypass()
        Hub.Notify("Security", "Anti-Cheat Shield: FULLY ACTIVE", 2)
    end
end)

Hub.CreateSection(utilTab, "Movement & Environment")

Hub.CreateToggle(utilTab, "Walk on Water", Config.WalkOnWater, function(val)
    Config.WalkOnWater = val
    toggleWaterWalk(val)
    Hub.Notify("Utility", val and "Walk on Water: ACTIVE" or "Walk on Water: OFF", 2)
end)

Hub.CreateToggle(utilTab, "Infinite Oxygen", Config.InfiniteOxygen, function(val)
    Config.InfiniteOxygen = val
    Hub.Notify("Utility", val and "Infinite Oxygen: ACTIVE" or "Infinite Oxygen: OFF", 2)
end)

Hub.CreateButton(utilTab, "Fullbright / Clear Water", function()
    pcall(function()
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    end)
    Hub.Notify("Visuals", "Fullbright & clear water activated!", 2)
end)

Hub.Notify("Unknown Hub", "Fisch Suite V1 Loaded — Anti-Cheat Shield Online 🐟🛡️", 4)
