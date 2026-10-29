--[[
    ========================================================================
    Unknown Hub - Medved! (Hunt & Become Bears) Game Module
    Game ID: 7144947546 | Place ID: 132273534230449
    Security Architecture:
      - Silent Telemetry Neutralizer (Zero character tampering / zero body movers)
      - Packet.Write Report Stripper (Prevents Code 3, 4, 6 from ever reaching server)
      - BindableEvent Listener Disabler (Mutes Animate & Sprinting trap callers)
      - Safe Crates Auto Farm (Strict unopened filtering & instant proximity looting)
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
-- 1. SILENT TELEMETRY NEUTRALIZER (ZERO CHARACTER INJECTIONS)
--------------------------------------------------------------------------------
local function silenceTelemetry()
    pcall(function()
        local playerGui = LocalPlayer:WaitForChild("PlayerGui", 10)
        local ci = playerGui:WaitForChild("ClientInterface", 10)
        local scriptObj = ci:WaitForChild("ClientInterface", 10)
        local packetModule = scriptObj:WaitForChild("Packet", 10)

        -- 1. Hook Packet.Write to wipe any violation reports before serialization
        local Packet = require(packetModule)
        if Packet and not Packet.__ORIGINAL_WRITE then
            Packet.__ORIGINAL_WRITE = Packet.Write
            Packet.Write = function(p16, p17, p18, p19)
                if type(p17) == "table" and p17.Reports and #p17.Reports > 0 then
                    table.clear(p17.Reports) -- Strip all violation reports (Code 1, 3, 4, 6, 8)
                end
                return Packet.__ORIGINAL_WRITE(p16, p17, p18, p19)
            end
        end

        -- 2. Disconnect the BindableEvent listener in ClientInterface
        local event = ci:FindFirstChild("Event")
        if event and getconnections then
            for _, conn in ipairs(getconnections(event.Event)) do
                conn:Disable()
            end
        end
    end)
end

-- Re-apply on respawn/character added
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    silenceTelemetry()
end)

silenceTelemetry()

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
local crateAttempts = {}
local blacklistedCrates = {}
local openedCrates = {}

--------------------------------------------------------------------------------
-- 4. UTILITY FUNCTIONS: CRATE DETECTION & LOOT COLLECTION
--------------------------------------------------------------------------------
-- Dual-engine prompt trigger: fires both native executor prompt and direct Lua connection
local function triggerPrompt(prompt)
    if not prompt or not prompt.Enabled then return false end

    pcall(function()
        if fireproximityprompt then
            fireproximityprompt(prompt)
        end
    end)

    pcall(function()
        if getconnections then
            for _, con in ipairs(getconnections(prompt.Triggered)) do
                if con and con.Fire then
                    con:Fire()
                elseif con and con.Function then
                    con.Function()
                end
            end
        end
    end)
    return true
end

-- Helper to inspect any active item prompts on a crate model
local function getCrateItemPrompts(crateModel)
    local prompts = {}
    if not crateModel then return prompts end
    local cratePart = crateModel:FindFirstChild("Crate")
    if not cratePart then return prompts end

    for _, spotName in ipairs({"ItemSpot1", "ItemSpot2", "ItemSpot3"}) do
        local spot = cratePart:FindFirstChild(spotName)
        local prompt = spot and spot:FindFirstChildOfClass("ProximityPrompt")
        if prompt and prompt.Enabled then
            table.insert(prompts, prompt)
        end
    end
    return prompts
end

-- Collect all items in a crate model with fast active proximity polling
local function sweepCrateItems(crateModel, maxWait)
    if not crateModel or not crateModel:FindFirstChild("Crate") then return false end
    local cratePart = crateModel.Crate
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")

    local timeout = maxWait or 1.2
    local start = tick()
    local collectedAny = false

    while (tick() - start) < timeout do
        local activePrompts = getCrateItemPrompts(crateModel)
        if #activePrompts == 0 then
            if collectedAny or (tick() - start) > 0.35 then
                break
            end
        else
            for _, prompt in ipairs(activePrompts) do
                if root then
                    root.CFrame = cratePart.CFrame + Vector3.new(0, 2.0, 0)
                    root.AssemblyLinearVelocity = Vector3.zero
                end
                triggerPrompt(prompt)
                collectedAny = true
                task.wait(0.09)
            end
        end
        task.wait(0.04)
    end

    return collectedAny
end

-- Get all targets needing attention: crates with uncollected loot FIRST, then unopened crates
local function getCratesToProcess()
    local interactables = Workspace:FindFirstChild("Interactables")
    local cratesFolder = interactables and interactables:FindFirstChild("Crates")
    if not cratesFolder then return {} end

    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")

    local lootTargets = {}
    local unopenedTargets = {}

    for _, c in ipairs(cratesFolder:GetChildren()) do
        local name = c.Name
        -- Skip crates that reached attempt limit (max 2 attempts)
        if not blacklistedCrates[name] then
            local cratePart = c:FindFirstChild("Crate")
            if cratePart then
                local itemPrompts = getCrateItemPrompts(c)
                if #itemPrompts > 0 then
                    table.insert(lootTargets, { crate = c, mode = "loot" })
                elseif not openedCrates[name] then
                    local collected = c:GetAttribute("Collected")
                    local openPrompt = cratePart:FindFirstChild("CratePrompt")
                    if collected ~= true and openPrompt and openPrompt.Enabled then
                        table.insert(unopenedTargets, { crate = c, mode = "open" })
                    end
                end
            end
        end
    end

    -- Distance sort targets for optimal routing
    if root then
        table.sort(unopenedTargets, function(a, b)
            local posA = a.crate:GetPivot().Position
            local posB = b.crate:GetPivot().Position
            return (posA - root.Position).Magnitude < (posB - root.Position).Magnitude
        end)
        table.sort(lootTargets, function(a, b)
            local posA = a.crate:GetPivot().Position
            local posB = b.crate:GetPivot().Position
            return (posA - root.Position).Magnitude < (posB - root.Position).Magnitude
        end)
    end

    -- Always process uncollected loot crates FIRST, then unopened crates
    local targets = {}
    for _, t in ipairs(lootTargets) do table.insert(targets, t) end
    for _, t in ipairs(unopenedTargets) do table.insert(targets, t) end

    return targets
end

--------------------------------------------------------------------------------
-- 5. AUTO FARM CRATES LOOP (SINGLETON TOKEN ENFORCED)
--------------------------------------------------------------------------------
local currentFarmSession = tick()
_G.MedvedFarmSession = currentFarmSession

task.spawn(function()
    local mySession = currentFarmSession
    while _G.MedvedFarmSession == mySession do
        task.wait(0.12)
        if Config.AutoFarmCrates then
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")

            if root and hum and hum.Health > 0 then
                silenceTelemetry()

                local targets = getCratesToProcess()
                if #targets > 0 then
                    for _, target in ipairs(targets) do
                        if _G.MedvedFarmSession ~= mySession or not Config.AutoFarmCrates then break end

                        local crate = target.crate
                        local name = crate.Name
                        local cratePart = crate and crate:FindFirstChild("Crate")
                        if not cratePart then continue end

                        -- Strict attempt cap: max 2 attempts per crate to eliminate infinite retry loops
                        crateAttempts[name] = (crateAttempts[name] or 0) + 1
                        if crateAttempts[name] > 2 then
                            blacklistedCrates[name] = true
                            continue
                        end

                        local targetCFrame = cratePart.CFrame + Vector3.new(0, 2.0, 0)
                        root.CFrame = targetCFrame
                        root.AssemblyLinearVelocity = Vector3.zero
                        -- Settle window: ensures client position replicates to Roblox server before invoking remote
                        task.wait(0.22)

                        if target.mode == "open" then
                            local openPrompt = cratePart:FindFirstChild("CratePrompt")
                            if openPrompt and openPrompt.Enabled then
                                triggerPrompt(openPrompt)
                            end

                            -- Quick wait for loot prompts or opening acknowledgment (max 0.75s)
                            local waitStart = tick()
                            while (tick() - waitStart) < 0.75 do
                                if #getCrateItemPrompts(crate) > 0 or not openPrompt.Enabled then
                                    break
                                end
                                root.CFrame = targetCFrame
                                root.AssemblyLinearVelocity = Vector3.zero
                                task.wait(0.05)
                            end
                        end

                        -- Fast sweep of all loot items
                        local swept = sweepCrateItems(crate, 1.2)
                        if swept or crate:GetAttribute("Collected") == true then
                            openedCrates[name] = true
                        end

                        -- If crate remains unopened or unlootable after 2 tries, blacklist it permanently
                        if crateAttempts[name] >= 2 and crate:GetAttribute("Collected") ~= true and #getCrateItemPrompts(crate) == 0 then
                            blacklistedCrates[name] = true
                        end

                        task.wait(Config.FarmDelay)
                    end
                else
                    -- No crates or uncollected loot left
                    if Config.AutoServerhop then
                        Hub.Notify("Medved", "All crates & loot collected! Serverhopping...", 3)
                        task.wait(1)
                        if getgenv().serverhop then
                            getgenv().serverhop()
                        else
                            TeleportService:Teleport(game.PlaceId, LocalPlayer)
                        end
                        task.wait(5)
                    else
                        task.wait(1.5)
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
        local cratePart = c:FindFirstChild("Crate")
        if cratePart then
            local itemPrompts = getCrateItemPrompts(c)
            local collected = c:GetAttribute("Collected")
            local openPrompt = cratePart:FindFirstChild("CratePrompt")
            local isUnopened = (collected ~= true and openPrompt and openPrompt.Enabled)
            local hasLoot = (#itemPrompts > 0)

            if isUnopened or hasLoot then
                local bb = Instance.new("BillboardGui")
                bb.Name = "CrateESP"
                bb.Adornee = cratePart
                bb.Size = UDim2.new(0, 110, 0, 30)
                bb.AlwaysOnTop = true
                bb.StudsOffset = Vector3.new(0, 2.2, 0)

                local label = Instance.new("TextLabel")
                label.Size = UDim2.new(1, 0, 1, 0)
                label.BackgroundTransparency = 1
                if hasLoot then
                    label.Text = "💰 [LOOT] " .. c.Name
                    label.TextColor3 = Color3.fromRGB(255, 220, 60)
                else
                    label.Text = "📦 " .. c.Name
                    label.TextColor3 = Color3.fromRGB(0, 240, 255)
                end
                label.Font = Enum.Font.GothamBold
                label.TextSize = 11
                label.Parent = bb

                bb.Parent = CoreGui
                table.insert(activeESP, bb)
            end
        end
    end
end

-- Refresh ESP occasionally
task.spawn(function()
    while true do
        task.wait(2.5)
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

Hub.CreateSection(farmTab, "🛡️ Telemetry Shield: Active & Silent")

Hub.CreateSection(farmTab, "📦 Crates Automation")

Hub.CreateToggle(farmTab, "Auto Farm Crates (Teleport & Loot)", Config.AutoFarmCrates, function(val)
    Config.AutoFarmCrates = val
    if val then
        silenceTelemetry()
        table.clear(crateAttempts)
        table.clear(blacklistedCrates)
        table.clear(openedCrates)
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
        silenceTelemetry()
        Hub.Notify("Auto Farm", "Collecting all unopened crates on map...", 2)
        local unopened = getUnopenedCrates()
        for _, crate in ipairs(unopened) do
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local prompt = crate:FindFirstChild("Crate") and crate.Crate:FindFirstChild("CratePrompt")
            if root and crate:GetAttribute("Collected") ~= true and prompt and prompt.Enabled then
                root.CFrame = CFrame.new(crate.Crate.Position + Vector3.new(0, 3.2, 0))
                task.wait(0.15)
                if fireproximityprompt then fireproximityprompt(prompt) end
                task.wait(0.25)
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

Hub.CreateSection(miscTab, "Navigation & Server")

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

Hub.Notify("Medved Hub", "Medved! Module Loaded (Zero-Detection Mode) 🐻", 3)
