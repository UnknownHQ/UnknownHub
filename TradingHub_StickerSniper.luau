-- =========================================================================
-- UnknownHub: Bee Swarm Simulator - Trading Hub / Sticker Sprout Sniper
-- Architecture: Turbo Zero-Delay Alt Engine with Live Visual HUD & Instant Hop
-- Target Place: Trading Hub / Hive Hub (PlaceId: 15579077077) & BSS Main (1537690962)
-- =========================================================================

if not game:IsLoaded() then
    pcall(function() game.Loaded:Wait() end)
end

local PlaceId = game.PlaceId
local JobId = game.JobId
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- Auto-queue on teleport to guarantee script runs across every hop
pcall(function()
    local qot = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
    if qot then
        qot([[loadfile("TradingHub_StickerSniper.luau")()]])
    end
end)

-- =========================================================================
-- Settings & State
-- =========================================================================
local Settings = {
    SnipeStickers = true,
    PrioritizePlanters = true,
    AutoPopSprouts = true,
    AutoServerHop = true,
    IgnoreDonateBoard = true,
    HopDelaySeconds = 2.5, -- Turbo fast hop: checks in 2.5s and leaves if dead!
    SafeHeightOffset = 1.6,
    CollectTimeout = 0.08,
}

local DONATE_BOARD_POS = Vector3.new(-210.7, 70.9, -9960.0)

local State = {
    Running = true,
    Status = "Scanning Server...",
    LastHopAttempt = 0,
    StickersCollectedSession = 0,
    SproutsHarvestedSession = 0,
    ServerJoinTime = tick(),
}

-- Persistent Visited Servers Cache (Avoids Rejoining Dead Servers)
local VISITED_FILE = "StickerSniper_Visited.json"
local function getVisitedServers()
    local visited = {}
    pcall(function()
        if isfile and isfile(VISITED_FILE) then
            local data = HttpService:JSONDecode(readfile(VISITED_FILE))
            if type(data) == "table" then visited = data end
        end
    end)
    return visited
end

local function recordVisitedServer(id)
    pcall(function()
        local visited = getVisitedServers()
        visited[id] = os.time()
        -- Prune entries older than 2 hours or keep max 50
        local count = 0
        local clean = {}
        for k, v in pairs(visited) do
            if os.time() - v < 7200 and count < 50 then
                clean[k] = v
                count = count + 1
            end
        end
        if writefile then
            writefile(VISITED_FILE, HttpService:JSONEncode(clean))
        end
    end)
end

-- Record current server on join
recordVisitedServer(JobId)

-- =========================================================================
-- Visual On-Screen HUD (Fixes Blank / Missing Console Feedback!)
-- =========================================================================
local hudGui = nil
local statusLabel = nil
local statsLabel = nil

pcall(function()
    local targetParent = CoreGui:FindFirstChild("RobloxGui") or CoreGui or LocalPlayer:FindFirstChild("PlayerGui")
    local oldHud = targetParent:FindFirstChild("UnknownHub_StickerSniper_HUD")
    if oldHud then oldHud:Destroy() end

    hudGui = Instance.new("ScreenGui")
    hudGui.Name = "UnknownHub_StickerSniper_HUD"
    hudGui.ResetOnSpawn = false
    hudGui.Parent = targetParent

    local card = Instance.new("Frame")
    card.Name = "StatusCard"
    card.Size = UDim2.new(0, 250, 0, 135)
    card.Position = UDim2.new(1, -265, 0, 25)
    card.BackgroundColor3 = Color3.fromRGB(15, 18, 26)
    card.BorderSizePixel = 0
    card.Parent = hudGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = card

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(0, 215, 255)
    stroke.Thickness = 1.5
    stroke.Parent = card

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -16, 0, 24)
    title.Position = UDim2.new(0, 8, 0, 6)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.Text = "⚡ UnknownHub | Sticker Sniper"
    title.TextColor3 = Color3.fromRGB(0, 215, 255)
    title.TextSize = 13
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = card

    statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, -16, 0, 32)
    statusLabel.Position = UDim2.new(0, 8, 0, 32)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.Text = "Status: Initializing..."
    statusLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
    statusLabel.TextSize = 12
    statusLabel.TextWrapped = true
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.Parent = card

    statsLabel = Instance.new("TextLabel")
    statsLabel.Size = UDim2.new(1, -16, 0, 20)
    statsLabel.Position = UDim2.new(0, 8, 0, 68)
    statsLabel.BackgroundTransparency = 1
    statsLabel.Font = Enum.Font.GothamBold
    statsLabel.Text = "Stickers: 0  |  Sprouts: 0"
    statsLabel.TextColor3 = Color3.fromRGB(46, 204, 113)
    statsLabel.TextSize = 11
    statsLabel.TextXAlignment = Enum.TextXAlignment.Left
    statsLabel.Parent = card

    local hopBtn = Instance.new("TextButton")
    hopBtn.Size = UDim2.new(1, -16, 0, 28)
    hopBtn.Position = UDim2.new(0, 8, 0, 96)
    hopBtn.BackgroundColor3 = Color3.fromRGB(25, 30, 42)
    hopBtn.BorderSizePixel = 0
    hopBtn.Font = Enum.Font.GothamBold
    hopBtn.Text = "🚀 Force Server Hop Now"
    hopBtn.TextColor3 = Color3.fromRGB(255, 215, 0)
    hopBtn.TextSize = 11
    hopBtn.Parent = card

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = hopBtn

    hopBtn.MouseButton1Click:Connect(function()
        State.ServerJoinTime = 0
        hopBtn.Text = "🌐 Hopping..."
    end)
end)

local function updateHUD(statusText)
    if statusText then State.Status = statusText end
    if statusLabel then
        statusLabel.Text = "Status: " .. tostring(State.Status)
    end
    if statsLabel then
        statsLabel.Text = string.format("Stickers: %d  |  Sprouts: %d", State.StickersCollectedSession, State.SproutsHarvestedSession)
    end
end

-- =========================================================================
-- Anti-teleport / Noclip / Character Helpers
-- =========================================================================
local function setNoclip(enabled)
    local char = LocalPlayer.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = not enabled
            part.CanTouch = true
            part.CanQuery = true
        end
    end
end

local function getLocalCharacter()
    local char = LocalPlayer.Character
    if not char then return nil, nil, nil end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    return char, root, hum
end

-- =========================================================================
-- Filter: Donate Board Wall Filter
-- =========================================================================
local function isDonateBoardSticker(part, obj)
    if not part then return true end
    -- 1. Anchored to a wall/board -> pinned donation
    if part.Anchored then return true end
    -- 2. Wall canvas height check (field ground is Y ~ 0.6)
    if part.Position.Y > 15 then return true end
    -- 3. Proximity to Public Sticker Board
    if (part.Position - DONATE_BOARD_POS).Magnitude < 50 then return true end
    -- 4. Inside StickerCanvases or HiveDeco
    if (obj and (obj:FindFirstAncestor("StickerCanvases") or obj:FindFirstAncestor("Public Sticker Board") or obj:FindFirstAncestor("HiveDeco"))) or
       (part:FindFirstAncestor("StickerCanvases") or part:FindFirstAncestor("Public Sticker Board") or part:FindFirstAncestor("HiveDeco")) then
        return true
    end
    return false
end

-- =========================================================================
-- 1. Sticker Planter Detection & Instant Collection (Highest Priority)
-- =========================================================================
local function findStickerPlanter()
    local plantersFolder = Workspace:FindFirstChild("Planters") or Workspace:FindFirstChild("PlanterModels")
    if not plantersFolder then return nil, nil end

    for _, planter in ipairs(plantersFolder:GetChildren()) do
        local nameLower = string.lower(planter.Name)
        local isSticker = string.find(nameLower, "sticker")
        if not isSticker and planter:FindFirstChild("Type") then
            local typeVal = string.lower(tostring(planter.Type.Value))
            if string.find(typeVal, "sticker") then isSticker = true end
        end

        if isSticker then
            local rootPart = planter:IsA("BasePart") and planter or planter:FindFirstChildWhichIsA("BasePart") or planter.PrimaryPart
            if rootPart then
                return planter, rootPart.Position
            end
        end
    end
    return nil, nil
end

local function harvestStickerPlanter(planter, pos)
    local char, root, hum = getLocalCharacter()
    if not root then return false end

    updateHUD("⚡ Harvesting Sticker Planter!")
    setNoclip(true)

    root.CFrame = CFrame.new(pos.X, pos.Y + 2.5, pos.Z)
    root.AssemblyLinearVelocity = Vector3.zero

    pcall(function()
        local rootPart = planter:IsA("BasePart") and planter or planter:FindFirstChildWhichIsA("BasePart")
        if rootPart and firetouchinterest then
            firetouchinterest(root, rootPart, 0)
            firetouchinterest(root, rootPart, 1)
        end
    end)

    pcall(function()
        local ev = ReplicatedStorage:FindFirstChild("Events")
        if ev and ev:FindFirstChild("PlanterModelCollect") then
            ev.PlanterModelCollect:FireServer(planter)
        end
    end)

    pcall(function()
        for _, prompt in ipairs(planter:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") then
                fireproximityprompt(prompt, 0)
            end
        end
    end)

    task.wait(0.15)
    setNoclip(false)
    return true
end

-- =========================================================================
-- 2. Fast Sticker Token Sniping (Field Drops & Collectibles)
-- =========================================================================
local function getActiveStickers()
    local targets = {}
    local char, root = getLocalCharacter()
    local myPos = root and root.Position or Vector3.zero

    -- A. PublicStickers folder (Sprout drops ONLY, ignore board!)
    local pubFolder = Workspace:FindFirstChild("PublicStickers")
    if pubFolder then
        for _, s in ipairs(pubFolder:GetChildren()) do
            local p = s:IsA("BasePart") and s or s:FindFirstChildWhichIsA("BasePart") or s.PrimaryPart
            if p and not isDonateBoardSticker(p, s) then
                local dist = (myPos - p.Position).Magnitude
                table.insert(targets, { Object = s, Part = p, Position = p.Position, Type = "Public", Dist = dist })
            end
        end
    end

    -- B. Standard Stickers folder (Ground field drops)
    local stFolder = Workspace:FindFirstChild("Stickers")
    if stFolder then
        for _, s in ipairs(stFolder:GetChildren()) do
            local p = s:IsA("BasePart") and s or s:FindFirstChildWhichIsA("BasePart") or s.PrimaryPart
            if p and not isDonateBoardSticker(p, s) then
                local dist = (myPos - p.Position).Magnitude
                table.insert(targets, { Object = s, Part = p, Position = p.Position, Type = "Folder", Dist = dist })
            end
        end
    end

    -- C. Collectibles folder (Tokens from popped sprouts)
    local colFolder = Workspace:FindFirstChild("Collectibles")
    if colFolder then
        for _, c in ipairs(colFolder:GetChildren()) do
            local dec = c:FindFirstChildWhichIsA("Decal")
            local isStickerToken = false
            if dec and string.find(string.lower(dec.Texture), "sticker") then isStickerToken = true end
            if string.find(string.lower(c.Name), "sticker") then isStickerToken = true end

            if isStickerToken then
                local p = c:IsA("BasePart") and c or c:FindFirstChildWhichIsA("BasePart")
                if p and not isDonateBoardSticker(p, c) then
                    local dist = (myPos - p.Position).Magnitude
                    table.insert(targets, { Object = c, Part = p, Position = p.Position, Type = "Collectible", Dist = dist })
                end
            end
        end
    end

    table.sort(targets, function(a, b) return a.Dist < b.Dist end)
    return targets
end

local function snipeStickerTarget(target)
    local char, root, hum = getLocalCharacter()
    if not root then return false end

    local obj = target.Object
    local part = target.Part
    local pos = target.Position

    if not obj:IsDescendantOf(Workspace) or not part:IsDescendantOf(Workspace) then
        return false
    end

    setNoclip(true)

    root.CFrame = CFrame.new(pos.X, pos.Y + Settings.SafeHeightOffset, pos.Z)
    root.AssemblyLinearVelocity = Vector3.zero

    pcall(function()
        if firetouchinterest then
            firetouchinterest(root, part, 0)
            firetouchinterest(root, part, 1)
        end
    end)

    pcall(function()
        local ev = ReplicatedStorage:FindFirstChild("Events")
        if ev and ev:FindFirstChild("StickerPublicClick") then
            ev.StickerPublicClick:FireServer(obj)
        end
    end)

    -- Ultra-fast verification loop
    local startTick = tick()
    local timeout = Settings.CollectTimeout or 0.08
    while obj:IsDescendantOf(Workspace) and (tick() - startTick) < timeout do
        RunService.Heartbeat:Wait()
    end

    local collected = not obj:IsDescendantOf(Workspace)
    if collected then
        State.StickersCollectedSession = State.StickersCollectedSession + 1
        updateHUD()
    end

    setNoclip(false)
    return collected
end

-- =========================================================================
-- 3. Sticker Sprout Detection & Auto Pop
-- =========================================================================
local function findActiveStickerSprout()
    local sproutsFolder = Workspace:FindFirstChild("Sprouts")
    if sproutsFolder then
        local children = sproutsFolder:GetChildren()
        if #children > 0 then
            -- In Trading Hub, ANY sprout in this folder is in the Hub Field
            for _, s in ipairs(children) do
                local p = s:FindFirstChildWhichIsA("BasePart") or s.PrimaryPart or (s:IsA("BasePart") and s)
                if p then return s end
            end
        end
    end

    -- Secondary check: FlowerZones or Workspace direct search for any active Sprout
    local hubField = Workspace:FindFirstChild("FlowerZones") and Workspace.FlowerZones:FindFirstChild("Hub Field")
    if hubField then
        for _, obj in ipairs(hubField:GetChildren()) do
            if string.find(string.lower(obj.Name), "sprout") then
                return obj
            end
        end
    end

    for _, obj in ipairs(Workspace:GetChildren()) do
        if string.find(string.lower(obj.Name), "sprout") and not obj:IsA("Terrain") then
            return obj
        end
    end

    return nil
end

local function popStickerSprout(sprout)
    local char, root, hum = getLocalCharacter()
    if not root or not hum then return end

    local sproutPart = sprout:FindFirstChildWhichIsA("BasePart") or sprout.PrimaryPart
    if not sproutPart then return end

    updateHUD("🌱 Popping Sticker Sprout!")
    setNoclip(true)

    local center = sproutPart.Position
    local radius = 8
    local angle = tick() * 4
    local dest = center + Vector3.new(math.cos(angle) * radius, 3.2, math.sin(angle) * radius)

    root.CFrame = CFrame.new(dest)
    root.AssemblyLinearVelocity = Vector3.zero

    pcall(function()
        local tool = char:FindFirstChildOfClass("Tool")
        if tool and tool:FindFirstChild("ClickEvent") then
            tool.ClickEvent:FireServer()
        end
    end)

    pcall(function()
        local ev = ReplicatedStorage:FindFirstChild("Events")
        local tColl = ev and (ev:FindFirstChild("ToolCollect") or ev:FindFirstChild("PlayerActivesCommand"))
        if tColl then
            tColl:FireServer("ToolCollect")
        end
    end)
end

-- =========================================================================
-- 4. Turbo Smart Server Hopper (High Speed & Zero Duplicate Reconnects)
-- =========================================================================
local isHopping = false
local function serverHop()
    if isHopping then return end
    isHopping = true
    updateHUD("🌐 Finding new server with Sticker Sprout...")

    local visited = getVisitedServers()
    local targetPlaceId = PlaceId

    local req = request or http_request or (syn and syn.request) or (http and http.request)
    if not req then
        updateHUD("🚀 Teleporting to random server...")
        TeleportService:Teleport(targetPlaceId, LocalPlayer)
        return
    end

    local serverFound = false
    -- Try both Ascending and Descending sort orders for maximum server diversity
    for _, sortOrder in ipairs({"Desc", "Asc"}) do
        if serverFound then break end
        local url = string.format("https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=%s&limit=100", tostring(targetPlaceId), sortOrder)
        pcall(function()
            local response = req({ Url = url, Method = "GET" })
            if response and response.StatusCode == 200 then
                local body = HttpService:JSONDecode(response.Body)
                if body and body.data then
                    local candidates = {}
                    for _, srv in ipairs(body.data) do
                        if srv.id ~= JobId and srv.playing and srv.playing >= 1 and srv.playing < (srv.maxPlayers or 50) and not visited[srv.id] then
                            table.insert(candidates, srv.id)
                        end
                    end

                    if #candidates > 0 then
                        local chosen = candidates[math.random(1, #candidates)]
                        recordVisitedServer(chosen)
                        updateHUD("🚀 Hopping to: " .. string.sub(chosen, 1, 8) .. "...")
                        serverFound = true
                        TeleportService:TeleportToPlaceInstance(targetPlaceId, chosen, LocalPlayer)
                    end
                end
            end
        end)
    end

    if not serverFound then
        updateHUD("🚀 Hopping (Fallback)...")
        TeleportService:Teleport(targetPlaceId, LocalPlayer)
    end

    task.wait(4)
    isHopping = false
end

-- Handle Teleport Failures gracefully
TeleportService.TeleportInitFailed:Connect(function(player, teleportResult, errorMessage)
    if player == LocalPlayer then
        isHopping = false
        updateHUD("⚠️ Teleport failed, retrying...")
        task.wait(1.5)
        serverHop()
    end
end)

-- =========================================================================
-- 5. Main Execution Master Loop
-- =========================================================================
task.spawn(function()
    while State.Running do
        local ok, err = pcall(function()
            local char, root, hum = getLocalCharacter()
            if not root or not hum then
                updateHUD("Waiting for character...")
                task.wait(0.3)
                return
            end

            -- Priority 1: Sticker Planter!
            if Settings.PrioritizePlanters then
                local planter, planterPos = findStickerPlanter()
                if planter and planterPos then
                    harvestStickerPlanter(planter, planterPos)
                    task.wait(0.05)
                    return
                end
            end

            -- Priority 2: Active Sticker Drops on Field!
            if Settings.SnipeStickers then
                local stickers = getActiveStickers()
                if #stickers > 0 then
                    updateHUD(string.format("🎯 Sniping Stickers (%d remaining)!", #stickers))
                    for _, s in ipairs(stickers) do
                        if Settings.PrioritizePlanters then
                            local pl, plPos = findStickerPlanter()
                            if pl and plPos then
                                harvestStickerPlanter(pl, plPos)
                                break
                            end
                        end
                        snipeStickerTarget(s)
                    end
                    task.wait(0.02)
                    return
                end
            end

            -- Priority 3: Active Sticker Sprout!
            local sprout = findActiveStickerSprout()
            if sprout then
                if Settings.AutoPopSprouts then
                    popStickerSprout(sprout)
                end
                task.wait(0.05)
                return
            end

            -- Priority 4: No Sprout & No Stickers -> Fast Server Hop!
            if Settings.AutoServerHop then
                local timeInServer = tick() - State.ServerJoinTime
                if timeInServer >= Settings.HopDelaySeconds then
                    serverHop()
                    task.wait(2)
                    return
                else
                    local left = math.max(0, math.ceil((Settings.HopDelaySeconds - timeInServer) * 10) / 10)
                    updateHUD(string.format("⏳ Scanning... (Hop in %.1fs)", left))
                    task.wait(0.3)
                    return
                end
            else
                updateHUD("Idle (Waiting for Sticker Sprout)...")
                task.wait(1)
            end
        end)

        if not ok then
            task.wait(0.3)
        end
    end
end)

print("[UnknownHub] Trading Hub Sticker Sprout Alt Sniper Loaded with Live Visual HUD & Turbo Hop!")
