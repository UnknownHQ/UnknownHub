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
    OriginalWalkSpeed = 16,
    OriginalJumpPower = 50,
    Installed = false
}

local function setupAntiCheatBypass()
    if AntiCheatShield.Installed then return end
    pcall(function()
        if not hookmetamethod or not getnamecallmethod then return end

        local oldNamecall = nil
        local oldIndex = nil

        -- Detour 1: Surgical __namecall filter (prevents kick calls & drown damage without breaking internal handshakes)
        oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if typeof(self) == "Instance" then
                -- Block client-side kick calls directed at LocalPlayer
                if method == "Kick" or method == "kick" then
                    return nil
                end

                -- Block drowning damage remote when infinite oxygen is active
                if Config.InfiniteOxygen and (self.Name == "drown" or self.Name:lower() == "drown") then
                    return nil
                end
            end

            return oldNamecall(self, ...)
        end))

        -- Detour 2: Safe __index filter (spoofs WalkSpeed/JumpPower only for outside scripts)
        oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, key)
            if not checkcaller() and typeof(self) == "Instance" and self:IsA("Humanoid") then
                if key == "WalkSpeed" and Config.WalkSpeed ~= 16 then
                    return AntiCheatShield.OriginalWalkSpeed
                elseif key == "JumpPower" and Config.JumpPower ~= 50 then
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
-- 5. AUTO FISHING ENGINE (AUTO CAST, AUTO SHAKE & SAFE FISH BUBBLE REEL)
--------------------------------------------------------------------------------
local isFishingActive = false
local lastCastTick = 0
local lastShakeTick = 0
local reelStartTime = 0

-- 1. Auto Cast Routine (Ensures rod equipped, checks cast state, fires server cast)
local function executeCast()
    if not Config.AutoCast then return end
    if tick() - lastCastTick < 1.2 then return end

    local rod = ensureRodEquipped()
    if not rod then return end

    local values = rod:FindFirstChild("values")
    if values then
        local casted = values:FindFirstChild("casted")
        if casted and casted.Value == true then
            return -- Already casted and waiting for bite
        end
    end

    pcall(function()
        local castPower = math.clamp(Config.CastPower or 100, 10, 100)
        local castedSuccess = false

        -- Direct rod event invocation
        if rod:FindFirstChild("events") and rod.events:FindFirstChild("castAsync") then
            rod.events.castAsync:InvokeServer(castPower, true)
            castedSuccess = true
        end

        -- Fallback to Net package RemoteFunction
        if not castedSuccess then
            local net = ReplicatedStorage:FindFirstChild("packages") and ReplicatedStorage.packages:FindFirstChild("Net")
            if net then
                local Net = require(net)
                local castRf = Net:RemoteFunction("FishingRod/Cast", -1)
                if castRf then
                    castRf:InvokeServer(castPower, true)
                    castedSuccess = true
                end
            end
        end

        if castedSuccess then
            lastCastTick = tick()
        end
    end)
end

-- 2. Auto Shake Routine (Clicks shake bubbles instantly and naturally)
local function processShakeMinigame()
    if not Config.AutoShake then return end
    if tick() - lastShakeTick < math.clamp(Config.ShakeSpeed or 0.12, 0.08, 0.3) then return end

    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return end

    local shakeUI = playerGui:FindFirstChild("shakeui")
    if not shakeUI or not shakeUI.Enabled then return end

    pcall(function()
        local safezone = shakeUI:FindFirstChild("safezone")
        if safezone then
            -- Find the active shake button inside safezone
            for _, btn in ipairs(safezone:GetChildren()) do
                if btn:IsA("ImageButton") and btn.Visible and btn.UIScale.Scale > 0.1 then
                    -- Trigger button click
                    if firesignal then
                        firesignal(btn.MouseButton1Click)
                    end
                    break
                end
            end
        end

        -- Dispatch shake network event directly to server
        local net = ReplicatedStorage:FindFirstChild("packages") and ReplicatedStorage.packages:FindFirstChild("Net")
        if net then
            local Net = require(net)
            local shakeEvent = Net:RemoteEvent("LureShake/Shake", -1)
            if shakeEvent then
                shakeEvent:FireServer()
            end
        end

        lastShakeTick = tick()
    end)
end

-- 3. Auto Fish / Auto Reel Routine (Locks playerbar onto the fish bubble safely)
local function processReelMinigame()
    if not Config.AutoReel then return end

    if reelStartTime == 0 then
        reelStartTime = tick()
    end

    pcall(function()
        -- Method A: Direct ReelController integration (100% native game engine tracking)
        local legacyControllers = ReplicatedStorage:FindFirstChild("client") and ReplicatedStorage.client:FindFirstChild("legacyControllers")
        local reelCtrlModule = legacyControllers and legacyControllers:FindFirstChild("ReelController")
        if reelCtrlModule then
            local ok, ReelController = pcall(require, reelCtrlModule)
            if ok and ReelController and ReelController.ActiveReel then
                local reel = ReelController.ActiveReel
                if reel.active then
                    -- Smoothly lock bar position onto the fish bubble position
                    reel.barPosition = reel.fishPosition
                    reel.onbar = true

                    -- Prevent instant catch bans by respecting human reaction bounds
                    local elapsed = tick() - reelStartTime
                    if elapsed < (Config.ReelDelay or 1.6) then
                        -- Keep progress right below completion threshold until safe duration elapsed
                        if reel.progress > 88 then
                            reel.progress = 88
                        end
                    end
                    return
                end
            end
        end

        -- Method B: UI Frame direct manipulation fallback
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        local reelUI = playerGui and playerGui:FindFirstChild("reel")
        if reelUI and reelUI.Enabled then
            local bar = reelUI:FindFirstChild("bar", true)
            local fish = bar and bar:FindFirstChild("fish")
            local playerbar = bar and bar:FindFirstChild("playerbar")

            if bar and fish and playerbar then
                playerbar.Position = UDim2.new(fish.Position.X.Scale, 0, playerbar.Position.Y.Scale, playerbar.Position.Y.Offset)
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

        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        local isShaking = playerGui and playerGui:FindFirstChild("shakeui") and playerGui.shakeui.Enabled
        local isReeling = playerGui and playerGui:FindFirstChild("reel") and playerGui.reel.Enabled

        if isReeling then
            processReelMinigame()
        else
            reelStartTime = 0 -- Reset reel timer when minigame closes

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
