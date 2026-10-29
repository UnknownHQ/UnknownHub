--[[
    ========================================================================
    Unknown Hub - Medved! (Hunt & Become Bears) Game Module
    Game ID: 7144947546 | Place ID: 132273534230449
    Features:
      - Silent Telemetry Interceptor (Neutralizes Report codes 1-8 without bans)
      - Zero False-Flag Injections (NO BodyMovers, NO fake attributes)
      - Smart Auto Farm Crates (Strictly unopened crates only)
      - ProximityPrompt Item Collector
      - Unopened Crates ESP
    ========================================================================
]]

local LIBRARY_LINK = "https://raw.githubusercontent.com/UnknownHQ/UnknownHub/main/UnknownLibrary"

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- Anti-AFK Safeguard
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

--------------------------------------------------------------------------------
-- 1. SILENT TELEMETRY SHIELD (REPORT SUPPRESSOR)
-- Neutralizes client-side security reports (Codes 1-8) before they reach the server.
-- Preserves natural heartbeat (Echo) and script status (Blocks) so server is happy.
--------------------------------------------------------------------------------
local function applySilentShield()
    -- Layer 1: Hook Packet.Write in ClientInterface.Packet module
    pcall(function()
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        local clientInterface = playerGui and playerGui:FindFirstChild("ClientInterface")
        local mainScript = clientInterface and clientInterface:FindFirstChild("ClientInterface")
        local packetMod = mainScript and mainScript:FindFirstChild("Packet")

        if packetMod then
            local Packet = require(packetMod)
            if Packet and Packet.Write and not Packet.__ShieldHooked then
                local oldWrite = Packet.Write
                Packet.Write = function(pktType, data, keyTable, nonce)
                    if pktType == Packet.TO_SERVER and typeof(data) == "table" then
                        -- Purge all violation reports completely
                        if data.Reports and #data.Reports > 0 then
                            table.clear(data.Reports)
                        end
                        data.Reports = {}
                    end
                    return oldWrite(pktType, data, keyTable, nonce)
                end
                Packet.__ShieldHooked = true
                if hookfunction then
                    hookfunction(oldWrite, Packet.Write)
                end
            end
        end
    end)

    -- Layer 2: Neutralize Report closure via getgc
    pcall(function()
        if not getgc or not islclosure or not hookfunction then return end
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        local clientInterface = playerGui and playerGui:FindFirstChild("ClientInterface")
        local mainScript = clientInterface and clientInterface:FindFirstChild("ClientInterface")
        if not mainScript then return end

        for _, obj in ipairs(getgc()) do
            if typeof(obj) == "function" and islclosure(obj) then
                local env = getfenv(obj)
                if env and env.script == mainScript then
                    local info = debug.getinfo(obj)
                    if info.name == "Report" then
                        hookfunction(obj, function(...)
                            return -- Drop report completely
                        end)
                        break
                    end
                end
            end
        end
    end)
end

applySilentShield()

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1.0)
    applySilentShield()
end)

--------------------------------------------------------------------------------
-- 2. FETCH & INITIALIZE UNKNOWN LIBRARY
--------------------------------------------------------------------------------
local function loadLibrary()
    local ok, res = pcall(function()
        return game:HttpGet(LIBRARY_LINK .. "?t=" .. tostring(os.time()))
    end)
    if ok and res and res ~= "" then
        local fn, err = loadstring(res)
        if fn then return fn() end
        warn("[UnknownHub] Library compile error: " .. tostring(err))
    end
    return nil
end

local library = loadLibrary()
if not library then
    warn("[UnknownHub] Failed to load UnknownLibrary for Medved!")
    return
end

local Hub = library({
    title = "UNKNOWN HUB",
    game = "MEDVED! 🐻",
    theme = Color3.fromRGB(0, 195, 245),
    secondaryTheme = Color3.fromRGB(165, 95, 255)
})

--------------------------------------------------------------------------------
-- 3. STATE & CONFIGURATION
--------------------------------------------------------------------------------
local Config = {
    AutoFarmCrates = false,
    FarmDelay = 0.5,
    AutoServerhop = false,
    CratesESP = false
}

local activeESP = {}

--------------------------------------------------------------------------------
-- 4. UTILITY FUNCTIONS: CRATE DETECTION & LOOT COLLECTION
--------------------------------------------------------------------------------
local function getUnopenedCrates()
    local unopened = {}
    local interactables = Workspace:FindFirstChild("Interactables")
    local cratesFolder = interactables and interactables:FindFirstChild("Crates")
    if not cratesFolder then return unopened end

    for _, c in ipairs(cratesFolder:GetChildren()) do
        local collected = c:GetAttribute("Collected")
        local prompt = c:FindFirstChild("Crate") and c.Crate:FindFirstChild("CratePrompt")
        -- Strict filter: never target collected or disabled crates
        if collected ~= true and prompt and prompt.Enabled then
            table.insert(unopened, c)
        end
    end

    -- Sort by distance
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then
        table.sort(unopened, function(a, b)
            local posA = a:GetPivot().Position
            local posB = b:GetPivot().Position
            return (posA - root.Position).Magnitude < (posB - root.Position).Magnitude
        end)
    end

    return unopened
end

local function collectCrateLoot(crateModel)
    if not crateModel or not crateModel:FindFirstChild("Crate") then return end
    local cratePart = crateModel.Crate

    -- Check all 3 possible item spots
    for _, spotName in ipairs({"ItemSpot1", "ItemSpot2", "ItemSpot3"}) do
        local spot = cratePart:FindFirstChild(spotName)
        local prompt = spot and spot:FindFirstChildOfClass("ProximityPrompt")
        if prompt and prompt.Enabled and fireproximityprompt then
            fireproximityprompt(prompt)
            task.wait(0.1)
        end
    end
end

--------------------------------------------------------------------------------
-- 5. AUTO FARM CRATES LOOP
--------------------------------------------------------------------------------
task.spawn(function()
    while true do
        task.wait(0.3)
        if Config.AutoFarmCrates then
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")

            if root and hum and hum.Health > 0 then
                applySilentShield()

                local unopenedCrates = getUnopenedCrates()
                if #unopenedCrates > 0 then
                    for _, crate in ipairs(unopenedCrates) do
                        if not Config.AutoFarmCrates then break end

                        local collected = crate:GetAttribute("Collected")
                        local prompt = crate:FindFirstChild("Crate") and crate.Crate:FindFirstChild("CratePrompt")
                        if collected ~= true and prompt and prompt.Enabled then
                            -- 1. Teleport onto crate
                            local targetPos = crate.Crate.Position + Vector3.new(0, 3.2, 0)
                            root.CFrame = CFrame.new(targetPos)
                            root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                            task.wait(0.2)

                            -- 2. Open crate
                            if prompt and prompt.Enabled and fireproximityprompt then
                                fireproximityprompt(prompt)
                            end

                            -- 3. Wait for loot items to spawn and collect
                            task.wait(0.35)
                            collectCrateLoot(crate)

                            task.wait(Config.FarmDelay)
                        end
                    end
                else
                    if Config.AutoServerhop then
                        Hub.Notify("Medved", "All map crates looted! Serverhopping...", 3)
                        task.wait(1.5)
                        if getgenv().serverhop then
                            getgenv().serverhop()
                        else
                            TeleportService:Teleport(game.PlaceId, LocalPlayer)
                        end
                        task.wait(5)
                    else
                        task.wait(2.0)
                    end
                end
            end
        end
    end
end)

--------------------------------------------------------------------------------
-- 6. CRATES ESP SYSTEM
--------------------------------------------------------------------------------
local function clearESP()
    for _, obj in pairs(activeESP) do
        if obj and obj.Parent then
            pcall(function() obj:Destroy() end)
        end
    end
    table.clear(activeESP)
end

local function updateCratesESP()
    clearESP()
    if not Config.CratesESP then return end

    local interactables = Workspace:FindFirstChild("Interactables")
    local cratesFolder = interactables and interactables:FindFirstChild("Crates")
    if not cratesFolder then return end

    for _, c in ipairs(cratesFolder:GetChildren()) do
        local collected = c:GetAttribute("Collected")
        local cratePart = c:FindFirstChild("Crate")
        if collected ~= true and cratePart then
            local bb = Instance.new("BillboardGui")
            bb.Name = "CrateESP"
            bb.Adornee = cratePart
            bb.Size = UDim2.new(0, 100, 0, 30)
            bb.AlwaysOnTop = true
            bb.StudsOffset = Vector3.new(0, 2, 0)

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, 0, 1, 0)
            label.BackgroundTransparency = 1
            label.Text = "📦 " .. c.Name
            label.TextColor3 = Color3.fromRGB(0, 240, 255)
            label.Font = Enum.Font.GothamBold
            label.TextSize = 11
            label.Parent = bb

            bb.Parent = CoreGui
            table.insert(activeESP, bb)
        end
    end
end

task.spawn(function()
    while true do
        task.wait(3.0)
        if Config.CratesESP then
            updateCratesESP()
        end
    end
end)

--------------------------------------------------------------------------------
-- 7. UI TABS & CONTROLS
--------------------------------------------------------------------------------
local farmTab = Hub.CreateTab("Auto Farm", {
    Icon = "🌾",
    Size = 18,
    Color = Color3.fromRGB(0, 195, 245),
    ActiveColor = Color3.fromRGB(0, 230, 255)
})

Hub.CreateSection(farmTab, "🛡️ Anti-Cheat Bypass Status")
Hub.CreateParagraph({
    Title = "Silent Telemetry Shield: ACTIVE",
    Content = "Packet reports 1-8 are intercepted and dropped. Server receives authentic heartbeats with 0 violations."
})

Hub.CreateSection(farmTab, "📦 Crates Automation")

Hub.CreateToggle(farmTab, "Auto Farm Crates (Teleport & Loot)", Config.AutoFarmCrates, function(val)
    Config.AutoFarmCrates = val
    if val then
        applySilentShield()
    end
    Hub.Notify("Auto Farm", val and "Crate Farm: ACTIVE" or "Crate Farm: OFF", 2)
end)

Hub.CreateSlider(farmTab, "Teleport Delay (Seconds)", 0.2, 1.5, Config.FarmDelay, function(val)
    Config.FarmDelay = val
end)

Hub.CreateToggle(farmTab, "Auto Serverhop When Map Cleared", Config.AutoServerhop, function(val)
    Config.AutoServerhop = val
end)

Hub.CreateButton(farmTab, "Farm All Available Crates (One-Time)", function()
    task.spawn(function()
        applySilentShield()
        Hub.Notify("Auto Farm", "Collecting all unopened crates on map...", 2)
        local unopened = getUnopenedCrates()
        for _, crate in ipairs(unopened) do
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local prompt = crate:FindFirstChild("Crate") and crate.Crate:FindFirstChild("CratePrompt")
            if root and crate:GetAttribute("Collected") ~= true and prompt and prompt.Enabled then
                root.CFrame = CFrame.new(crate.Crate.Position + Vector3.new(0, 3.2, 0))
                task.wait(0.2)
                if fireproximityprompt then fireproximityprompt(prompt) end
                task.wait(0.35)
                collectCrateLoot(crate)
                task.wait(Config.FarmDelay)
            end
        end
        Hub.Notify("Auto Farm", "One-time sweep complete!", 3)
    end)
end)

local visualTab = Hub.CreateTab("Visuals", {
    Icon = "👁️",
    Size = 18,
    Color = Color3.fromRGB(165, 95, 255),
    ActiveColor = Color3.fromRGB(190, 130, 255)
})

Hub.CreateSection(visualTab, "ESP")

Hub.CreateToggle(visualTab, "Unopened Crates ESP", Config.CratesESP, function(val)
    Config.CratesESP = val
    if val then
        updateCratesESP()
    else
        clearESP()
    end
end)

local miscTab = Hub.CreateTab("Misc", {
    Icon = "⚙️",
    Size = 18,
    Color = Color3.fromRGB(200, 210, 230),
    ActiveColor = Color3.fromRGB(240, 245, 255)
})

Hub.CreateSection(miscTab, "Movement & World")

Hub.CreateButton(miscTab, "Serverhop (New Server)", function()
    Hub.Notify("Teleport", "Finding new server...", 2)
    if getgenv().serverhop then
        getgenv().serverhop()
    else
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end
end)

Hub.CreateButton(miscTab, "Rejoin Current Server", function()
    Hub.Notify("Teleport", "Rejoining...", 2)
    if getgenv().rejoin then
        getgenv().rejoin()
    else
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end
end)

Hub.Notify("Medved Hub", "Medved! Safe Module Loaded 🐻", 3)
