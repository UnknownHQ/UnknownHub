--[[
    ========================================================================
    Unknown Hub - Medved! (Hunt & Become Bears) Game Module
    Game ID: 7144947546 | Place ID: 132273534230449
    Features:
      - 100% Anti-Cheat Teleport Bypass (Neutralizes ClientInterface telemetry)
      - Smart Auto Farm Crates (Strictly unopened crates only)
      - Instant Prompt Loot Collector
      - Unopened Crates ESP
      - Auto Serverhop when all crates are cleared
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
-- 1. ANTI-CHEAT BYPASS SHIELD (TELEPORT / SPEED MONITOR NEUTRALIZER)
--------------------------------------------------------------------------------
local function applyAntiCheatBypass(char)
    char = char or LocalPlayer.Character
    if not char then return end

    local hum = char:WaitForChild("Humanoid", 5)
    local root = char:WaitForChild("HumanoidRootPart", 5)

    if hum then
        -- Satisfies Covered() in ClientInterface.ClientInterface -> stops telemetry reports
        pcall(function()
            hum:SetAttribute("BeingJumpscared", true)
        end)
    end

    if root then
        -- Presence of BodyVelocity inside root satisfies Covered() t8 check
        local shield = root:FindFirstChild("AntiCheatShield")
        if not shield then
            local bv = Instance.new("BodyVelocity")
            bv.Name = "AntiCheatShield"
            bv.MaxForce = Vector3.new(0, 0, 0)
            bv.Velocity = Vector3.new(0, 0, 0)
            bv.Parent = root
        end
    end
end

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    applyAntiCheatBypass(char)
end)

if LocalPlayer.Character then
    applyAntiCheatBypass(LocalPlayer.Character)
end

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
    FarmDelay = 0.4,
    AutoServerhop = false,
    CratesESP = false,
    NoClip = false
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
        -- Strict filter: never teleport to crates that are collected or disabled
        if collected ~= true and prompt and prompt.Enabled then
            table.insert(unopened, c)
        end
    end

    -- Sort by distance to LocalPlayer for optimized pathing
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

    -- Collect all 3 possible item spots
    for _, spotName in ipairs({"ItemSpot1", "ItemSpot2", "ItemSpot3"}) do
        local spot = cratePart:FindFirstChild(spotName)
        local prompt = spot and spot:FindFirstChildOfClass("ProximityPrompt")
        if prompt and prompt.Enabled and fireproximityprompt then
            fireproximityprompt(prompt)
            task.wait(0.08)
        end
    end
end

--------------------------------------------------------------------------------
-- 5. NOCLIP SYSTEM (Prevents getting stuck in terrain during farming)
--------------------------------------------------------------------------------
RunService.Stepped:Connect(function()
    if Config.AutoFarmCrates or Config.NoClip then
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end
end)

--------------------------------------------------------------------------------
-- 6. AUTO FARM CRATES LOOP
--------------------------------------------------------------------------------
task.spawn(function()
    while true do
        task.wait(0.2)
        if Config.AutoFarmCrates then
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")

            if root and hum and hum.Health > 0 then
                applyAntiCheatBypass(char)

                local unopenedCrates = getUnopenedCrates()
                if #unopenedCrates > 0 then
                    for _, crate in ipairs(unopenedCrates) do
                        if not Config.AutoFarmCrates then break end

                        -- Double check crate is still valid and not opened by another player
                        local collected = crate:GetAttribute("Collected")
                        local prompt = crate:FindFirstChild("Crate") and crate.Crate:FindFirstChild("CratePrompt")
                        if collected ~= true and prompt and prompt.Enabled then
                            -- 1. Teleport directly onto crate
                            local targetPos = crate.Crate.Position + Vector3.new(0, 3.2, 0)
                            root.CFrame = CFrame.new(targetPos)
                            root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                            task.wait(0.15)

                            -- 2. Trigger opening prompt
                            if prompt and prompt.Enabled and fireproximityprompt then
                                fireproximityprompt(prompt)
                            end

                            -- 3. Wait for loot to pop and collect all items
                            task.wait(0.25)
                            collectCrateLoot(crate)

                            task.wait(Config.FarmDelay)
                        end
                    end
                else
                    -- No crates left
                    if Config.AutoServerhop then
                        Hub.Notify("Medved", "All crates collected! Serverhopping...", 3)
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
-- 7. CRATES ESP SYSTEM
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
-- 8. UI TABS & CONTROLS
--------------------------------------------------------------------------------
local farmTab = Hub.CreateTab("Auto Farm", {
    Icon = "🌾",
    Size = 18,
    Color = Color3.fromRGB(0, 195, 245),
    ActiveColor = Color3.fromRGB(0, 230, 255)
})

Hub.CreateSection(farmTab, "🛡️ Anti-Cheat Bypass")

Hub.CreateToggle(farmTab, "Teleport Anti-Cheat Shield", true, function(v)
    if v then
        applyAntiCheatBypass()
        Hub.Notify("Shield", "Anti-Cheat bypass engaged (Covered state active)", 2)
    end
end)

Hub.CreateSection(farmTab, "📦 Crates Automation")

Hub.CreateToggle(farmTab, "Auto Farm Crates (Teleport & Loot)", Config.AutoFarmCrates, function(val)
    Config.AutoFarmCrates = val
    if val then
        applyAntiCheatBypass()
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

Hub.CreateSection(miscTab, "Movement & World")

Hub.CreateToggle(miscTab, "NoClip", Config.NoClip, function(val)
    Config.NoClip = val
    Hub.Notify("NoClip", val and "Enabled" or "Disabled", 2)
end)

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

Hub.Notify("Medved Hub", "Medved! Module Loaded Successfully 🐻", 3)
