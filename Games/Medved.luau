--[[
    ========================================================================
    Unknown Hub - Medved! (Hunt & Become Bears) Game Module
    Game ID: 7144947546 | Place ID: 132273534230449
    Features:
      - 100% Anti-Cheat Teleport Bypass (Neutralizes ClientInterface telemetry)
      - Smart Auto Farm Crates (Filters out already opened/collected crates)
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

local window = library({
    title = "UNKNOWN HUB • MEDVED! 🐻",
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
local farmTab = window:CreateTab("Auto Farm", "🌾")

farmTab:CreateSection("Anti-Cheat Bypass Status")
farmTab:CreateParagraph({
    Title = "🛡️ Teleport Shield Active",
    Content = "ClientInterface speed/teleport monitor is neutralized. Zero rubberbands and zero slowdowns."
})

farmTab:CreateSection("Crates Automation")

farmTab:CreateToggle({
    Name = "Auto Farm Crates (Teleport & Loot)",
    Default = false,
    Callback = function(val)
        Config.AutoFarmCrates = val
        if val then
            applyAntiCheatBypass()
        end
    end
})

farmTab:CreateSlider({
    Name = "Teleport Delay (Seconds)",
    Min = 0.2,
    Max = 1.5,
    Default = 0.4,
    Precision = 1,
    Callback = function(val)
        Config.FarmDelay = val
    end
})

farmTab:CreateToggle({
    Name = "Auto Serverhop When Map Cleared",
    Default = false,
    Callback = function(val)
        Config.AutoServerhop = val
    end
})

farmTab:CreateButton({
    Name = "Farm All Available Crates (One-Time)",
    Callback = function()
        task.spawn(function()
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
        end)
    end
})

local visualTab = window:CreateTab("Visuals", "👁️")
visualTab:CreateSection("ESP")

visualTab:CreateToggle({
    Name = "Unopened Crates ESP",
    Default = false,
    Callback = function(val)
        Config.CratesESP = val
        if val then
            updateCratesESP()
        else
            clearESP()
        end
    end
})

local miscTab = window:CreateTab("Misc", "⚙️")
miscTab:CreateSection("Player & World")

miscTab:CreateToggle({
    Name = "NoClip",
    Default = false,
    Callback = function(val)
        Config.NoClip = val
    end
})

miscTab:CreateButton({
    Name = "Serverhop (New Server)",
    Callback = function()
        if getgenv().serverhop then
            getgenv().serverhop()
        else
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
        end
    end
})

miscTab:CreateButton({
    Name = "Rejoin Current Server",
    Callback = function()
        if getgenv().rejoin then
            getgenv().rejoin()
        else
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
        end
    end
})
