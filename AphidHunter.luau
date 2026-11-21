-- =========================================================================
-- UNKNOWN HUB — APHID HUNTER & DAILY LEADERBOARD EXTERMINATOR
-- Fast-Sweep Leaf Teleporter + Instant Aphid Spawner/Killer
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
    FastSweepDelay = 0.09,   -- Time spent on each leaf tile (fast instant check)
    KillHoverHeight = 5.5,   -- Stay safely above Aphid hit radius (4.5 studs)
    CollectDrops = true,
    AutoServerHopWhenDry = false,
    MinServerPlayers = 4,
    MaxServerPlayers = 10,
    Status = "Idle",
}

local Stats = {
    LeavesChecked = 0,
    AphidsKilled = 0,
    RageAphids = 0,
    ArmoredAphids = 0,
    DiamondAphids = 0,
    StartTime = tick(),
}

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

-- Scan for all active LeafBurst flowers on the main mountain
local function getActiveLeafFlowers()
    local flowers = Workspace:FindFirstChild("Flowers")
    if not flowers then return {} end

    local leaves = {}
    for _, f in ipairs(flowers:GetChildren()) do
        if f:FindFirstChild("LeafBurst") then
            local p = f.Position
            -- Validate main mountain boundaries
            if p.Y >= 0 and p.Y <= 200 and math.abs(p.X) <= 600 and math.abs(p.Z) <= 700 then
                table.insert(leaves, f)
            end
        end
    end
    return leaves
end

-- Collect dropped loot around position
local function collectLootTokens(centerPos, radius)
    local collectibles = Workspace:FindFirstChild("Collectibles")
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not collectibles or not root or not centerPos then return end

    State.Status = "Vacuuming Aphid Loot..."
    local startT = tick()
    local emptyStreak = 0

    while (tick() - startT) < 3.5 do
        local targets = {}
        for _, token in ipairs(collectibles:GetChildren()) do
            if token:IsA("BasePart") and token.Name == "C" then
                local dist = (token.Position - centerPos).Magnitude
                if dist <= (radius or 55) then
                    table.insert(targets, { Token = token, Dist = dist })
                end
            end
        end

        if #targets > 0 then
            emptyStreak = 0
            table.sort(targets, function(a, b) return a.Dist < b.Dist end)
            for _, item in ipairs(targets) do
                local tPart = item.Token
                if tPart and tPart.Parent then
                    root.CFrame = CFrame.new(tPart.Position + Vector3.new(0, 0.4, 0))
                    root.AssemblyLinearVelocity = Vector3.zero
                    pcall(function()
                        if firetouchinterest then
                            firetouchinterest(root, tPart, 0)
                            firetouchinterest(root, tPart, 1)
                        end
                    end)
                    task.wait(0.03)
                end
            end
        else
            emptyStreak = emptyStreak + 1
            if emptyStreak >= 3 then break end
            task.wait(0.12)
        end
    end
end

-- Kill and track active Aphid
local function executeAphidElimination(aphid, mRoot, mHum)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root or not mRoot then return end

    local aphidName = aphid.Name
    local lastDeathPos = mRoot.Position
    State.Status = "KILLING " .. string.upper(aphidName) .. "!"

    local tool = char:FindFirstChildOfClass("Tool")
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

    print(string.format("[Aphid Hunter] 💀 %s ELIMINATED! Vacuuming loot at %s...", aphidName, tostring(lastDeathPos)))

    -- Wait 0.35s for server to erupt tokens into Workspace.Collectibles
    task.wait(0.35)

    -- Collect all dropped tokens unconditionally using the recorded death position
    if State.CollectDrops and lastDeathPos then
        collectLootTokens(lastDeathPos, 55)
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
    frame.Size = UDim2.new(0, 240, 0, 160)
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
    title.Size = UDim2.new(1, 0, 0, 28)
    title.BackgroundTransparency = 1
    title.Text = "🐛 APHID EXTERMINATOR"
    title.TextColor3 = Color3.fromRGB(0, 220, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 13
    title.Parent = frame

    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, -16, 0, 20)
    statusLabel.Position = UDim2.new(0, 8, 0, 32)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Status: Initializing..."
    statusLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    statusLabel.Font = Enum.Font.GothamSemibold
    statusLabel.TextSize = 11
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.Parent = frame

    local leavesLabel = Instance.new("TextLabel")
    leavesLabel.Size = UDim2.new(1, -16, 0, 18)
    leavesLabel.Position = UDim2.new(0, 8, 0, 54)
    leavesLabel.BackgroundTransparency = 1
    leavesLabel.Text = "Leaves Swept: 0"
    leavesLabel.TextColor3 = Color3.fromRGB(100, 255, 120)
    leavesLabel.Font = Enum.Font.Gotham
    leavesLabel.TextSize = 12
    leavesLabel.TextXAlignment = Enum.TextXAlignment.Left
    leavesLabel.Parent = frame

    local killsLabel = Instance.new("TextLabel")
    killsLabel.Size = UDim2.new(1, -16, 0, 18)
    killsLabel.Position = UDim2.new(0, 8, 0, 74)
    killsLabel.BackgroundTransparency = 1
    killsLabel.Text = "Aphids Slain: 0 (Goal: Top 5)"
    killsLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    killsLabel.Font = Enum.Font.GothamBold
    killsLabel.TextSize = 12
    killsLabel.TextXAlignment = Enum.TextXAlignment.Left
    killsLabel.Parent = frame

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0.46, 0, 0, 26)
    toggleBtn.Position = UDim2.new(0.04, 0, 0, 105)
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
    hopBtn.Size = UDim2.new(0.44, 0, 0, 26)
    hopBtn.Position = UDim2.new(0.52, 0, 0, 105)
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
                leavesLabel.Text = "Leaves Swept: " .. tostring(Stats.LeavesChecked)
                killsLabel.Text = string.format("Aphids Slain: %d (Rage: %d, Dia: %d)", Stats.AphidsKilled, Stats.RageAphids, Stats.DiamondAphids)
            end)
        end
    end)
end)

-- =========================================================================
-- Main Rapid Leaf-Sweep & Aphid Hunter Loop
-- =========================================================================
task.spawn(function()
    print("[Aphid Hunter] 🚀 Hyper-Fast Leaf Teleporter & Aphid Hunter ENGAGED!")

    while _G.APHID_HUNTER_SESSION == sessionKey do
        if not State.Enabled then
            task.wait(0.5)
            continue
        end

        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not char or not root then
            task.wait(0.2)
            continue
        end
        stabilizeCharacter(char)

        -- 1. PRIORITY CHECK: Is an Aphid already alive anywhere in the server?
        local aphid, mRoot, mHum = findActiveAphid()
        if aphid and mRoot then
            executeAphidElimination(aphid, mRoot, mHum)
            continue
        end

        -- 2. Scan map for LeafBurst flowers
        local leaves = getActiveLeafFlowers()
        if #leaves == 0 then
            State.Status = "No leaves found. Waiting for spawn..."
            if State.AutoServerHopWhenDry then
                hopToFreshServer()
                break
            end
            task.wait(1.2)
            continue
        end

        State.Status = string.format("Sweeping %d active leaves...", #leaves)

        -- 3. Sort leaves by distance to minimize transit time
        local myPos = root.Position
        table.sort(leaves, function(a, b)
            return (a.Position - myPos).Magnitude < (b.Position - myPos).Magnitude
        end)

        -- 4. Rapid-Sweep through leaves
        local tool = char:FindFirstChildOfClass("Tool")
        local events = ReplicatedStorage:FindFirstChild("Events")
        local toolCollect = events and events:FindFirstChild("ToolCollect")

        for _, flower in ipairs(leaves) do
            if _G.APHID_HUNTER_SESSION ~= sessionKey or not State.Enabled then break end

            -- Interruption check: did an Aphid spawn while moving?
            local liveAphid, aRoot, aHum = findActiveAphid()
            if liveAphid and aRoot then
                executeAphidElimination(liveAphid, aRoot, aHum)
                break
            end

            -- Teleport directly onto the leaf tile
            local flowerPos = flower.Position
            root.CFrame = CFrame.new(flowerPos + Vector3.new(0, 1.8, 0))
            root.AssemblyLinearVelocity = Vector3.zero

            -- Instant trigger: swing tool + ToolCollect packet
            if tool then tool:Activate() end
            if toolCollect then
                pcall(function() toolCollect:FireServer() end)
            end

            Stats.LeavesChecked = Stats.LeavesChecked + 1

            -- Micro-delay: wait just enough for server to process dig and check for Aphid
            task.wait(State.FastSweepDelay)

            -- Instant Aphid check right at this leaf
            local spawnedAphid, spRoot, spHum = findActiveAphid()
            if spawnedAphid and spRoot then
                executeAphidElimination(spawnedAphid, spRoot, spHum)
                break
            end
        end

        task.wait(0.01)
    end
end)

return {
    State = State,
    Stats = Stats
}
