--------------------------------------------------------------------------------
-- UNKNOWN HUB: FISCH (Continuous Precision Automation Edition)
-- PlaceId: 16732694052, 17910972410, 131716211654599 | GameId: 5750914919
-- Architecture:
--   • Continuous Auto Cast: Automatic re-casting loop with zero stall
--   • Misclick-Free Auto Shake: Pops bubbles cleanly via Activated signals & Return key
--   • Natural Auto-Detect Reel: Tracks fish bubble legitimately with auto-calculated duration
--   • 100% Pure Client Runtime: Zero dangerous metamethod detours (No Error 267)
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
    ShakeSpeed = 0.28,
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
-- 5. CONTINUOUS FISHING AUTOMATION ENGINE
--------------------------------------------------------------------------------
local lastCastTick = 0
local lastShakeTick = 0
local lastCatchTick = 0
local hadActiveReel = false

-- Helper: Retrieve active ReelController object if minigame is currently running
local function getActiveReel()
    local ok, rc = pcall(function()
        return require(ReplicatedStorage.client.legacyControllers.ReelController)
    end)
    if ok and rc and rc.ActiveReel and rc.ActiveReel.active then
        return rc.ActiveReel
    end
    return nil
end

-- Helper: Check if shake minigame UI is active
local function isShakingActive()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    local shakeUI = pg and pg:FindFirstChild("shakeui")
    return shakeUI and shakeUI.Enabled == true
end

-- 1. Precision Auto Cast (Runs continuously whenever rod is idle)
local function executeCast()
    if not Config.AutoCast then return end
    if getActiveReel() ~= nil then return end
    if isShakingActive() then return end
    if tick() - lastCastTick < 2.0 then return end
    if tick() - lastCatchTick < 2.0 then return end

    local rod = ensureRodEquipped()
    if not rod then return end

    -- If bobber is already in water waiting for a bite, do NOT re-cast!
    if rod:FindFirstChild("bobber") then return end

    local values = rod:FindFirstChild("values")
    if values then
        local state = values:FindFirstChild("state")
        -- States: 4=Casting, 5=Searching, 6=Luring, 7=PreReel, 8=Reeling
        if state and state.Value >= 4 and state.Value <= 8 then
            return
        end
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

-- 2. Misclick-Free Auto Shake (Pops bubbles cleanly)
local function processShakeMinigame()
    if not Config.AutoShake then return end
    if tick() - lastShakeTick < math.clamp(Config.ShakeSpeed or 0.28, 0.25, 0.45) then return end

    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return end

    local shakeUI = playerGui:FindFirstChild("shakeui")
    if not shakeUI or not shakeUI.Enabled then return end

    pcall(function()
        local safezone = shakeUI:FindFirstChild("safezone")
        if safezone then
            for _, btn in ipairs(safezone:GetChildren()) do
                if (btn:IsA("ImageButton") or btn:IsA("GuiButton")) and btn.Visible and btn.UIScale and btn.UIScale.Scale > 0.05 then
                    if firesignal then
                        firesignal(btn.Activated)
                    else
                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
                        task.wait(0.02)
                        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
                    end
                    lastShakeTick = tick()
                    return
                end
            end
        end

        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
        task.wait(0.02)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
        lastShakeTick = tick()
    end)
end

-- 3. Natural Auto-Detect Reel (Tracks fish bubble with native speed calculation)
local function processReelMinigame(activeReel)
    if not Config.AutoReel or not activeReel then return end

    pcall(function()
        -- Lock bar position directly onto the fish bubble
        activeReel.barPosition = activeReel.fishPosition
        activeReel.onbar = true

        -- Let the game's ReelController naturally calculate progress based on fish stats & rod speed
        -- When progress reaches 100, ReelController automatically triggers EndMinigame() safely!
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
                -- Catch just completed!
                hadActiveReel = false
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
-- 8. WORLD TELEPORTS REGISTRY
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

Hub.CreateToggle(farmTab, "Auto Shake (Bubble Pop)", Config.AutoShake, function(val)
    Config.AutoShake = val
    Hub.Notify("Auto Shake", val and "Auto Shake: ACTIVE" or "Auto Shake: OFF", 2)
end)

Hub.CreateToggle(farmTab, "Safe Auto Reel (Fish Bubble)", Config.AutoReel, function(val)
    Config.AutoReel = val
    Hub.Notify("Auto Reel", val and "Auto Reel: ACTIVE (Auto-Detect)" or "Auto Reel: OFF", 2)
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

local utilTab = Hub.CreateTab("Utility", {
    Icon = "⚡",
    Size = 18,
    Color = Color3.fromRGB(0, 255, 170),
    ActiveColor = Color3.fromRGB(80, 255, 200)
})

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

local tpTab = Hub.CreateTab("Teleports", {
    Icon = "📍",
    Size = 18,
    Color = Color3.fromRGB(255, 180, 0),
    ActiveColor = Color3.fromRGB(255, 210, 50)
})

Hub.CreateSection(tpTab, "Islands & Zones")

for islandName, coords in pairs(IslandLocations) do
    Hub.CreateButton(tpTab, "Teleport to " .. islandName, function()
        safeTeleport(coords)
    end)
end

Hub.Notify("Unknown Hub", "Fisch Suite Loaded - Ready To Fish! 🎣", 4)
