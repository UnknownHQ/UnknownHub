-- =========================================================================
-- UNKNOWN HUB вЂ” APHID HUNTER & DAILY LEADERBOARD EXTERMINATOR
-- Instance-Locked Real-Time Harvester + 100% Guaranteed Fresh Rolls
-- Goal: Top 5 Daily Aphid Exterminators Leaderboard -> Wavy Cyan Hive Skin
-- Target: Bee Swarm Simulator (PlaceId: 1537690962)
-- =========================================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId
local CurrentJobId = game.JobId

local sessionKey = tick()
_G.APHID_HUNTER_SESSION = sessionKey

local State = {
    Enabled = true,
    KillHoverHeight = 5.5,   -- Stay safely above Aphid hit radius (4.5 studs)
    CollectDrops = true,
    CollectLeafTokens = true,
    AutoServerHopWhenDry = false,
    MinServerPlayers = 4,
    MaxServerPlayers = 10,
    Status = "Idle",
}

local Stats = {
    LeavesChecked = 0,
    LeavesSwept = 0,
    TokensCollected = 0,
    AphidsKilled = 0,
    RageAphids = 0,
    ArmoredAphids = 0,
    DiamondAphids = 0,
    StartTime = tick(),
}

-- Instance-level tracking: tracks exact LeafBurst instances so no leaf is EVER re-visited
local sweptBursts = setmetatable({}, { __mode = "k" })

-- Anti-AFK
pcall(function()
    LocalPlayer.Idled:Connect(function()
        pcall(function()
            local vu = game:GetService("VirtualUser")
            if vu then
                vu:CaptureController()
                vu:ClickButton2(Vector2.new(0, 0))
            end
        end)
    end)
end)

-- Safe character getter
local function getCharacter()
    return Workspace:FindFirstChild(LocalPlayer.Name) or LocalPlayer.Character
end

-- Anti-ragdoll & stability
local function stabilizeCharacter(char)
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
    end
end

-- Scan for active Aphids in Workspace.Monsters
local function findActiveAphid()
    local monsters = Workspace:FindFirstChild("Monsters")
    if not monsters then return nil, nil, nil end

    for _, monster in ipairs(monsters:GetChildren()) do
        local name = monster.Name
        if string.find(name, "Aphid") then
            local hum = monster:FindFirstChildOfClass("Humanoid")
            local root = monster:FindFirstChild("HumanoidRootPart") or monster.PrimaryPart or monster:FindFirstChildWhichIsA("BasePart")
            if root and (not hum or hum.Health > 0) then
                return monster, root, hum
            end
        end
    end
    return nil, nil, nil
end

-- Dynamic real-time leaf picker: selects the closest genuinely fresh, unharvested leaf
local function getBestActiveLeaf()
    local flowers = Workspace:FindFirstChild("Flowers")
    local char = getCharacter()
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not flowers or not root then return nil, nil, 0 end

    local myPos = root.Position
    local bestFlower = nil
    local bestBurst = nil
    local bestDist = math.huge
    local totalActive = 0

    for _, f in ipairs(flowers:GetChildren()) do
        local burst = f:FindFirstChild("LeafBurst")
        -- Strict validation: Must have LeafBurst instance, not previously swept, enabled, rate > 0
        if burst and not sweptBursts[burst] and burst.Enabled and burst.Rate > 0 then
            local p = f.Position
            -- Validate main mountain boundaries
            if p.Y >= 0 and p.Y <= 200 and math.abs(p.X) <= 600 and math.abs(p.Z) <= 700 then
                totalActive = totalActive + 1
                local dist = (p - myPos).Magnitude
                if dist < bestDist then
                    bestDist = dist
                    bestFlower = f
                    bestBurst = burst
                end
            end
        end
    end

    return bestFlower, bestBurst, totalActive
end

-- Vacuum leaf drops strictly at the leaf tile (20-stud radius with exact 1:1 deduplication)
local function vacuumLeafDrops(flowerPos)
    local collectibles = Workspace:FindFirstChild("Collectibles")
    local char = getCharacter()
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not collectibles or not root or not flowerPos then return 0 end

    local touchedTokens = {}
    local collected = 0
    local startT = tick()

    -- Reactive listener: grab token the exact frame it spawns near this flower
    local conn
    conn = collectibles.ChildAdded:Connect(function(child)
        if child:IsA("BasePart") and child.Name == "C" and not touchedTokens[child] then
            task.wait(0.02)
            if child.Parent == collectibles and not touchedTokens[child] then
                local dist = (child.Position - flowerPos).Magnitude
                if dist <= 20 then
                    touchedTokens[child] = true
                    root.CFrame = CFrame.new(child.Position + Vector3.new(0, 0.35, 0))
                    root.AssemblyLinearVelocity = Vector3.zero
                    pcall(function()
                        if firetouchinterest then
                            firetouchinterest(root, child, 0)
                            firetouchinterest(root, child, 1)
                        end
                    end)
                    collected = collected + 1
                end
            end
        end
    end)

    -- Remain anchored at the flower tile for server eruption (~0.85s)
    while (tick() - startT) < 1.15 do
        task.wait(0.04)
        for _, token in ipairs(collectibles:GetChildren()) do
            if token:IsA("BasePart") and token.Name == "C" and not touchedTokens[token] then
                local dist = (token.Position - flowerPos).Magnitude
                if dist <= 20 then
                    touchedTokens[token] = true
                    root.CFrame = CFrame.new(token.Position + Vector3.new(0, 0.35, 0))
                    root.AssemblyLinearVelocity = Vector3.zero
                    pcall(function()
                        if firetouchinterest then
                            firetouchinterest(root, token, 0)
                            firetouchinterest(root, token, 1)
                        end
                    end)
                    collected = collected + 1
                    task.wait(0.02)
                end
            end
        end

        -- Finish if at least 1 token was bagged and server eruption window has elapsed
        if collected > 0 and (tick() - startT) >= 0.85 then
            break
        end
    end

    if conn then conn:Disconnect() end
    Stats.TokensCollected = Stats.TokensCollected + collected
    return collected
end

-- Vacuum Aphid dropped loot (wide 60-stud radius with exact 1:1 deduplication)
local function vacuumAphidLoot(centerPos)
    local collectibles = Workspace:FindFirstChild("Collectibles")
    local char = getCharacter()
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not collectibles or not root or not centerPos then return 0 end

    local touched = {}
    local collected = 0
    local startT = tick()
    local emptyStreak = 0

    while (tick() - startT) < 3.8 do
        local targets = {}
        for _, token in ipairs(collectibles:GetChildren()) do
            if token:IsA("BasePart") and token.Name == "C" and not touched[token] then
                local dist = (token.Position - centerPos).Magnitude
                if dist <= 60 then
                    table.insert(targets, { Token = token, Dist = dist })
                end
            end
        end

        if #targets > 0 then
            emptyStreak = 0
            table.sort(targets, function(a, b) return a.Dist < b.Dist end)
            for _, item in ipairs(targets) do
                local tPart = item.Token
                if tPart and tPart.Parent == collectibles and not touched[tPart] then
                    touched[tPart] = true
                    root.CFrame = CFrame.new(tPart.Position + Vector3.new(0, 0.4, 0))
                    root.AssemblyLinearVelocity = Vector3.zero
                    pcall(function()
                        if firetouchinterest then
                            firetouchinterest(root, tPart, 0)
                            firetouchinterest(root, tPart, 1)
                        end
                    end)
                    collected = collected + 1
                    task.wait(0.03)
                end
            end
        else
            emptyStreak = emptyStreak + 1
            if emptyStreak >= 3 and (tick() - startT) >= 1.6 then break end
            task.wait(0.1)
        end
    end

    Stats.TokensCollected = Stats.TokensCollected + collected
    return collected
end

-- Kill and track active Aphid
local function executeAphidElimination(aphid, mRoot, mHum)
    local char = getCharacter()
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root or not mRoot then return end

    local aphidName = aphid.Name
    local lastDeathPos = mRoot.Position
    State.Status = "KILLING " .. string.upper(aphidName) .. "!"

    local tool = char:FindFirstChildOfClass("Tool") or LocalPlayer.Backpack:FindFirstChildOfClass("Tool")
    if tool and tool.Parent ~= char then tool.Parent = char end

    local events = ReplicatedStorage:FindFirstChild("Events")
    local toolCollect = events and events:FindFirstChild("ToolCollect")

    local startCombat = tick()
    while aphid.Parent and mRoot.Parent and (tick() - startCombat < 35) do
        if _G.APHID_HUNTER_SESSION ~= sessionKey or not State.Enabled then break end
        if mHum and mHum.Health <= 0 then break end

        lastDeathPos = mRoot.Position

        -- Hover tightly above the Aphid (safe from 4.5-stud bite radius)
        local targetCF = CFrame.new(mRoot.Position + Vector3.new(0, State.KillHoverHeight, 0))
        root.CFrame = targetCF
        root.AssemblyLinearVelocity = Vector3.zero

        -- Trigger collector swing
        pcall(function()
            local LocalCollect = require(ReplicatedStorage.Collectors.LocalCollect)
            if LocalCollect and LocalCollect.Run then LocalCollect.Run() end
        end)
        if tool then tool:Activate() end
        if toolCollect then
            pcall(function() toolCollect:FireServer() end)
        end

        task.wait(0.04)
    end

    Stats.AphidsKilled = Stats.AphidsKilled + 1
    if aphidName:find("Rage") then
        Stats.RageAphids = Stats.RageAphids + 1
    elseif aphidName:find("Armored") then
        Stats.ArmoredAphids = Stats.ArmoredAphids + 1
    elseif aphidName:find("Diamond") then
        Stats.DiamondAphids = Stats.DiamondAphids + 1
    end

    print(string.format("[Aphid Hunter] рџ’Ђ %s ELIMINATED! Vacuuming loot at %s...", aphidName, tostring(lastDeathPos)))

    -- Wait 0.35s for server to erupt tokens into Workspace.Collectibles
    task.wait(0.35)

    -- Collect all dropped tokens unconditionally using recorded death position
    if State.CollectDrops and lastDeathPos then
        State.Status = "Vacuuming Aphid Loot..."
        vacuumAphidLoot(lastDeathPos)
    end
end

-- Server Hopper (to find unharvested fields with accumulated leaves)
local function hopToFreshServer()
    State.Status = "Server Hopping..."
    local url = string.format(
        "https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Desc&excludeFullGames=true&limit=50",
        tostring(PlaceId)
    )
    local ok, res = pcall(function() return game:HttpGet(url) end)
    if ok and res then
        local decodeOk, data = pcall(function() return HttpService:JSONDecode(res) end)
        if decodeOk and data and data.data then
            local viable = {}
            for _, s in ipairs(data.data) do
                if s.id ~= CurrentJobId and s.playing >= State.MinServerPlayers and s.playing <= State.MaxServerPlayers then
                    table.insert(viable, s)
                end
            end
            if #viable > 0 then
                local chosen = viable[math.random(1, #viable)]
                TeleportService:TeleportToPlaceInstance(PlaceId, chosen.id, LocalPlayer)
                return
            end
        end
    end
    TeleportService:Teleport(PlaceId, LocalPlayer)
end

-- =========================================================================
-- Clean HUD Interface
-- =========================================================================
pcall(function()
    local existing = CoreGui:FindFirstChild("AphidHunterHUD") or LocalPlayer.PlayerGui:FindFirstChild("AphidHunterHUD")
    if existing then existing:Destroy() end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AphidHunterHUD"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = RunService:IsStudio() and LocalPlayer.PlayerGui or CoreGui

    local frame = Instance.new("Frame")
    frame.Name = "MainFrame"
    frame.Size = UDim2.new(0, 250, 0, 185)
    frame.Position = UDim2.new(0, 20, 0, 200)
    frame.BackgroundColor3 = Color3.fromRGB(18, 22, 28)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true
    frame.Parent = screenGui

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(0, 220, 255)
    stroke.Thickness = 1.5
    stroke.Parent = frame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 28)
    title.BackgroundTransparency = 1
    title.Text = "рџђ› APHID EXTERMINATOR"
    title.TextColor3 = Color3.fromRGB(0, 220, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 13
    title.Parent = frame

    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusLabel"
    statusLabel.Size = UDim2.new(1, -16, 0, 18)
    statusLabel.Position = UDim2.new(0, 8, 0, 30)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Status: Initializing..."
    statusLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    statusLabel.Font = Enum.Font.GothamSemibold
    statusLabel.TextSize = 11
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.Parent = frame

    local leavesLabel = Instance.new("TextLabel")
    leavesLabel.Name = "LeavesLabel"
    leavesLabel.Size = UDim2.new(1, -16, 0, 18)
    leavesLabel.Position = UDim2.new(0, 8, 0, 50)
    leavesLabel.BackgroundTransparency = 1
    leavesLabel.Text = "Leaves Swept: 0"
    leavesLabel.TextColor3 = Color3.fromRGB(100, 255, 120)
    leavesLabel.Font = Enum.Font.Gotham
    leavesLabel.TextSize = 12
    leavesLabel.TextXAlignment = Enum.TextXAlignment.Left
    leavesLabel.Parent = frame

    local tokensLabel = Instance.new("TextLabel")
    tokensLabel.Name = "TokensLabel"
    tokensLabel.Size = UDim2.new(1, -16, 0, 18)
    tokensLabel.Position = UDim2.new(0, 8, 0, 70)
    tokensLabel.BackgroundTransparency = 1
    tokensLabel.Text = "Tokens Vacuumed: 0"
    tokensLabel.TextColor3 = Color3.fromRGB(255, 200, 80)
    tokensLabel.Font = Enum.Font.Gotham
    tokensLabel.TextSize = 12
    tokensLabel.TextXAlignment = Enum.TextXAlignment.Left
    tokensLabel.Parent = frame

    local killsLabel = Instance.new("TextLabel")
    killsLabel.Name = "KillsLabel"
    killsLabel.Size = UDim2.new(1, -16, 0, 18)
    killsLabel.Position = UDim2.new(0, 8, 0, 90)
    killsLabel.BackgroundTransparency = 1
    killsLabel.Text = "Aphids Slain: 0 (Goal: Top 5)"
    killsLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    killsLabel.Font = Enum.Font.GothamBold
    killsLabel.TextSize = 12
    killsLabel.TextXAlignment = Enum.TextXAlignment.Left
    killsLabel.Parent = frame

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Name = "ToggleBtn"
    toggleBtn.Size = UDim2.new(0.46, 0, 0, 26)
    toggleBtn.Position = UDim2.new(0.04, 0, 0, 120)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(35, 140, 60)
    toggleBtn.Text = "ACTIVE"
    toggleBtn.TextColor3 = Color3.new(1, 1, 1)
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextSize = 11
    toggleBtn.Parent = frame
    local btnCorner1 = Instance.new("UICorner")
    btnCorner1.CornerRadius = UDim.new(0, 6)
    btnCorner1.Parent = toggleBtn

    toggleBtn.MouseButton1Click:Connect(function()
        State.Enabled = not State.Enabled
        if State.Enabled then
            toggleBtn.Text = "ACTIVE"
            toggleBtn.BackgroundColor3 = Color3.fromRGB(35, 140, 60)
        else
            toggleBtn.Text = "PAUSED"
            toggleBtn.BackgroundColor3 = Color3.fromRGB(140, 40, 40)
            State.Status = "Paused"
        end
    end)

    local hopBtn = Instance.new("TextButton")
    hopBtn.Name = "HopBtn"
    hopBtn.Size = UDim2.new(0.44, 0, 0, 26)
    hopBtn.Position = UDim2.new(0.52, 0, 0, 120)
    hopBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 180)
    hopBtn.Text = "HOP SERVER"
    hopBtn.TextColor3 = Color3.new(1, 1, 1)
    hopBtn.Font = Enum.Font.GothamBold
    hopBtn.TextSize = 11
    hopBtn.Parent = frame
    local btnCorner2 = Instance.new("UICorner")
    btnCorner2.CornerRadius = UDim.new(0, 6)
    btnCorner2.Parent = hopBtn

    hopBtn.MouseButton1Click:Connect(function()
        hopToFreshServer()
    end)

    -- Live HUD update loop
    task.spawn(function()
        while _G.APHID_HUNTER_SESSION == sessionKey do
            task.wait(0.3)
            pcall(function()
                statusLabel.Text = "Status: " .. State.Status
                leavesLabel.Text = "Leaves Swept: " .. tostring(Stats.LeavesSwept)
                tokensLabel.Text = "Tokens Vacuumed: " .. tostring(Stats.TokensCollected)
                killsLabel.Text = string.format("Aphids Slain: %d (Rage: %d, Dia: %d)", Stats.AphidsKilled, Stats.RageAphids, Stats.DiamondAphids)
            end)
        end
    end)
end)

-- =========================================================================
-- Main Rapid Leaf-Sweep & Aphid Hunter Loop (Instance-Locked Fresh Target Harvester)
-- =========================================================================
task.spawn(function()
    print("[Aphid Hunter] рџљЂ Instance-Locked Harvester & Aphid Hunter ENGAGED!")

    while _G.APHID_HUNTER_SESSION == sessionKey do
        if not State.Enabled then
            task.wait(0.5)
            continue
        end

        local char = getCharacter()
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not char or not root then
            task.wait(0.2)
            continue
        end
        stabilizeCharacter(char)

        -- 1. ABSOLUTE PRIORITY: Is an Aphid alive anywhere in the server?
        local aphid, mRoot, mHum = findActiveAphid()
        if aphid and mRoot then
            executeAphidElimination(aphid, mRoot, mHum)
            continue
        end

        -- 2. DYNAMIC REAL-TIME FRESH LEAF PICKER
        local flower, burst, totalActiveLeaves = getBestActiveLeaf()
        if not flower or not burst then
            State.Status = "All leaves cleared! Waiting for fresh spawn..."
            if State.AutoServerHopWhenDry then
                hopToFreshServer()
                break
            end
            task.wait(1.5)
            continue
        end

        State.Status = string.format("Harvesting leaf (%d active on map)...", totalActiveLeaves)

        -- 3. Lock this exact LeafBurst instance permanently so it is NEVER visited twice
        sweptBursts[burst] = true
        Stats.LeavesChecked = Stats.LeavesChecked + 1

        -- 4. Teleport directly onto the flower surface (Y + 0.4)
        local flowerPos = flower.Position
        root.CFrame = CFrame.new(flowerPos + Vector3.new(0, 0.4, 0))
        root.AssemblyLinearVelocity = Vector3.zero

        -- 5. Arrival verification: Did it despawn while moving?
        if burst.Parent ~= flower or not burst.Enabled or burst.Rate <= 0 then
            continue
        end

        -- 6. Persistent multi-scoop harvest loop until LeafBurst is consumed
        local startHarvest = tick()
        local scoops = 0
        while burst.Parent == flower and burst.Enabled and burst.Rate > 0 and (tick() - startHarvest) < 3.2 do
            -- Interruption check: did an Aphid spawn?
            local liveAphid, aRoot, aHum = findActiveAphid()
            if liveAphid and aRoot then
                executeAphidElimination(liveAphid, aRoot, aHum)
                break
            end

            pcall(function()
                local LocalCollect = require(ReplicatedStorage.Collectors.LocalCollect)
                if LocalCollect and LocalCollect.GetCooldownNow then
                    local cd = LocalCollect.GetCooldownNow()
                    if cd and cd > 0 then task.wait(cd + 0.02) end
                    LocalCollect.Run()
                end
            end)
            scoops = scoops + 1

            -- Micro-step across flower tile to cover the full 4x4 pollen area
            local offset = (scoops % 2 == 0) and Vector3.new(0.8, 0.4, 0.8) or Vector3.new(-0.8, 0.4, -0.8)
            root.CFrame = CFrame.new(flowerPos + offset)
            root.AssemblyLinearVelocity = Vector3.zero

            pcall(function()
                if firetouchinterest then
                    firetouchinterest(root, flower, 0)
                    firetouchinterest(root, flower, 1)
                end
            end)

            task.wait(0.18)
        end

        Stats.LeavesSwept = Stats.LeavesSwept + 1

        -- 7. Check if Aphid spawned right at this flower
        local spawnedAphid, spRoot, spHum = findActiveAphid()
        if spawnedAphid and spRoot then
            executeAphidElimination(spawnedAphid, spRoot, spHum)
            continue
        end

        -- 8. Proactive token vacuum: stays anchored on flower tile, catches only real leaf drops (20 studs)
        if State.CollectLeafTokens then
            vacuumLeafDrops(flowerPos)
        end

        task.wait(0.04)
    end
end)

return {
    State = State,
    Stats = Stats
}
