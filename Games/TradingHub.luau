-- =========================================================================
-- UnknownHub: Bee Swarm Simulator - Trading Hub / Sticker Sprout Sniper
-- Architecture: 100% Zero-Delay Alt Automation Engine
-- Target Place: Trading Hub / Hive Hub (PlaceId: 15579077077) & BSS Main (1537690962)
-- =========================================================================

local PlaceId = game.PlaceId
local JobId = game.JobId
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- =========================================================================
-- State Configuration
-- =========================================================================
local Settings = {
    SnipeStickers = true,
    PrioritizePlanters = true,
    AutoPopSprouts = true,
    AutoServerHop = true,
    HopDelaySeconds = 8,
    SafeHeightOffset = 1.6,
    CollectTimeout = 0.08,
}

local State = {
    Running = true,
    Status = "Initializing...",
    VisitedServers = {},
    LastHopAttempt = 0,
    StickersCollectedSession = 0,
    SproutsHarvestedSession = 0,
}

-- Anti-teleport / Noclip helper
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
-- 1. Sticker Planter Detection & Fast Collection (Highest Priority)
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
                -- Check if ready to harvest
                local isReady = false
                if planter:FindFirstChild("Ready") or planter:FindFirstChild("ClaimPrompt") or planter:FindFirstChild("ProximityPrompt", true) then
                    isReady = true
                elseif planter:FindFirstChild("Growth") and planter.Growth.Value >= 100 then
                    isReady = true
                else
                    -- In trading hub, any active sticker planter is prime target
                    isReady = true
                end

                if isReady then
                    return planter, rootPart.Position
                end
            end
        end
    end
    return nil, nil
end

local function harvestStickerPlanter(planter, pos)
    local char, root, hum = getLocalCharacter()
    if not root then return false end

    State.Status = "⚡ Harvesting Sticker Planter!"
    setNoclip(true)

    -- Teleport above planter
    root.CFrame = CFrame.new(pos.X, pos.Y + 2.5, pos.Z)
    root.AssemblyLinearVelocity = Vector3.zero

    -- Fire touch and interaction remotes
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

    -- Trigger proximity prompts if present
    pcall(function()
        for _, prompt in ipairs(planter:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") then
                fireproximityprompt(prompt, 0)
            end
        end
    end)

    task.wait(0.2)
    setNoclip(false)
    return true
end

-- =========================================================================
-- 2. Fast Sticker Token Detection & Instant Sniping
-- =========================================================================
local function getActiveStickers()
    local targets = {}
    local char, root = getLocalCharacter()
    local myPos = root and root.Position or Vector3.zero

    -- A. PublicStickers folder (Trading Hub Sprout drops)
    local pubFolder = Workspace:FindFirstChild("PublicStickers")
    if pubFolder then
        for _, s in ipairs(pubFolder:GetChildren()) do
            local p = s:IsA("BasePart") and s or s:FindFirstChildWhichIsA("BasePart") or s.PrimaryPart
            if p then
                local dist = (myPos - p.Position).Magnitude
                table.insert(targets, { Object = s, Part = p, Position = p.Position, Type = "Public", Dist = dist })
            end
        end
    end

    -- B. Standard Stickers folder
    local stFolder = Workspace:FindFirstChild("Stickers")
    if stFolder then
        for _, s in ipairs(stFolder:GetChildren()) do
            local p = s:IsA("BasePart") and s or s:FindFirstChildWhichIsA("BasePart") or s.PrimaryPart
            if p then
                local dist = (myPos - p.Position).Magnitude
                table.insert(targets, { Object = s, Part = p, Position = p.Position, Type = "Folder", Dist = dist })
            end
        end
    end

    -- C. Collectibles folder (token items that are stickers)
    local colFolder = Workspace:FindFirstChild("Collectibles")
    if colFolder then
        for _, c in ipairs(colFolder:GetChildren()) do
            local dec = c:FindFirstChildWhichIsA("Decal")
            local isStickerToken = false
            if dec and string.find(string.lower(dec.Texture), "sticker") then isStickerToken = true end
            if string.find(string.lower(c.Name), "sticker") then isStickerToken = true end

            if isStickerToken then
                local p = c:IsA("BasePart") and c or c:FindFirstChildWhichIsA("BasePart")
                if p then
                    local dist = (myPos - p.Position).Magnitude
                    table.insert(targets, { Object = c, Part = p, Position = p.Position, Type = "Collectible", Dist = dist })
                end
            end
        end
    end

    -- Sort closest first for maximum collection rate
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

    -- 1. Instant safe offset snap
    root.CFrame = CFrame.new(pos.X, pos.Y + Settings.SafeHeightOffset, pos.Z)
    root.AssemblyLinearVelocity = Vector3.zero

    -- 2. Trigger Touch
    pcall(function()
        if firetouchinterest then
            firetouchinterest(root, part, 0)
            firetouchinterest(root, part, 1)
        end
    end)

    -- 3. Trigger remote click
    pcall(function()
        local ev = ReplicatedStorage:FindFirstChild("Events")
        if ev and ev:FindFirstChild("StickerPublicClick") then
            ev.StickerPublicClick:FireServer(obj)
        end
    end)

    -- 4. High-Speed Collection Verification
    local startTick = tick()
    local timeout = Settings.CollectTimeout or 0.08
    while obj:IsDescendantOf(Workspace) and (tick() - startTick) < timeout do
        RunService.Heartbeat:Wait()
    end

    local collected = not obj:IsDescendantOf(Workspace)
    if collected then
        State.StickersCollectedSession = State.StickersCollectedSession + 1
    end

    setNoclip(false)
    return collected
end

-- =========================================================================
-- 3. Sticker Sprout Detection & Auto Pop
-- =========================================================================
local function findActiveStickerSprout()
    local sproutsFolder = Workspace:FindFirstChild("Sprouts")
    if not sproutsFolder then return nil end

    for _, s in ipairs(sproutsFolder:GetChildren()) do
        local nameLower = string.lower(s.Name)
        local isSticker = string.find(nameLower, "sticker")
        if not isSticker and s:FindFirstChild("Type") then
            local tVal = string.lower(tostring(s.Type.Value))
            if string.find(tVal, "sticker") then isSticker = true end
        end

        if isSticker then
            return s
        end
    end
    return nil
end

local function popStickerSprout(sprout)
    local char, root, hum = getLocalCharacter()
    if not root or not hum then return end

    local sproutPart = sprout:FindFirstChildWhichIsA("BasePart") or sprout.PrimaryPart
    if not sproutPart then return end

    State.Status = "🌱 Popping Sticker Sprout!"
    setNoclip(true)

    -- Circle around sprout while packet digging
    local center = sproutPart.Position
    local radius = 8
    local angle = tick() * 4
    local dest = center + Vector3.new(math.cos(angle) * radius, 3.2, math.sin(angle) * radius)

    root.CFrame = CFrame.new(dest)
    root.AssemblyLinearVelocity = Vector3.zero

    -- Swing tool / packet dig
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
-- 4. Fast Smart Server Hopper (Targeting Sticker Sprouts)
-- =========================================================================
local function serverHop()
    if tick() - State.LastHopAttempt < 5 then return end
    State.LastHopAttempt = tick()
    State.Status = "🌐 Finding new server with Sticker Sprout..."

    local targetPlaceId = PlaceId
    local url = string.format("https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Desc&limit=100", tostring(targetPlaceId))

    local req = request or http_request or (syn and syn.request) or (http and http.request)
    if not req then
        TeleportService:Teleport(targetPlaceId, LocalPlayer)
        return
    end

    pcall(function()
        local response = req({ Url = url, Method = "GET" })
        if response and response.StatusCode == 200 then
            local body = HttpService:JSONDecode(response.Body)
            if body and body.data then
                local candidates = {}
                for _, srv in ipairs(body.data) do
                    if srv.id ~= JobId and srv.playing and srv.playing > 5 and srv.playing < (srv.maxPlayers or 50) and not State.VisitedServers[srv.id] then
                        table.insert(candidates, srv.id)
                    end
                end

                if #candidates > 0 then
                    local chosenServer = candidates[math.random(1, #candidates)]
                    State.VisitedServers[chosenServer] = true
                    State.Status = "🚀 Hopping to server: " .. string.sub(chosenServer, 1, 8) .. "..."
                    TeleportService:TeleportToPlaceInstance(targetPlaceId, chosenServer, LocalPlayer)
                    return
                end
            end
        end
    end)

    -- Fallback standard teleport
    TeleportService:Teleport(targetPlaceId, LocalPlayer)
end

-- =========================================================================
-- 5. Main Execution Master Engine Loop
-- =========================================================================
task.spawn(function()
    local joinTime = tick()

    while State.Running do
        local ok, err = pcall(function()
            local char, root, hum = getLocalCharacter()
            if not root or not hum then
                task.wait(0.5)
                return
            end

            -- Priority 1: Check Sticker Planters FIRST!
            if Settings.PrioritizePlanters then
                local planter, planterPos = findStickerPlanter()
                if planter and planterPos then
                    harvestStickerPlanter(planter, planterPos)
                    task.wait(0.05)
                    return
                end
            end

            -- Priority 2: Check Active Sticker Tokens on Field!
            if Settings.SnipeStickers then
                local stickers = getActiveStickers()
                if #stickers > 0 then
                    State.Status = string.format("🎯 Sniping Stickers (%d remaining)!", #stickers)
                    for _, s in ipairs(stickers) do
                        -- Re-check if a planter spawned in between
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

            -- Priority 3: Check Sticker Sprout in Field!
            local sprout = findActiveStickerSprout()
            if sprout then
                if Settings.AutoPopSprouts then
                    popStickerSprout(sprout)
                end
                task.wait(0.05)
                return
            end

            -- Priority 4: No Sprout & No Stickers -> Server Hop!
            if Settings.AutoServerHop then
                local timeInServer = tick() - joinTime
                if timeInServer >= Settings.HopDelaySeconds then
                    serverHop()
                    task.wait(3)
                    return
                else
                    State.Status = string.format("⏳ Checking server... (Hop in %ds)", math.ceil(Settings.HopDelaySeconds - timeInServer))
                    task.wait(1)
                    return
                end
            else
                State.Status = "Idle (Waiting for Sticker Sprout)..."
                task.wait(1)
            end
        end)

        if not ok then
            task.wait(0.5)
        end
    end
end)

print("[UnknownHub] Trading Hub Sticker Sprout & Planter Sniper Engine Loaded!")
