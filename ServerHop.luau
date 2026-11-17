-- =========================================================================
-- UnknownHub: Universal Turbo Server Hop Engine (Standalone)
-- Architecture: Multi-API Server Scraper + Continuous Auto-Hop + Visual Cyber HUD
-- Compatible with: All Executors (Real, Synapse, Fluxus, Delta, etc.) & All Games
-- =========================================================================

if not game:IsLoaded() then
    pcall(function() game.Loaded:Wait() end)
end

local PlaceId = game.PlaceId
local JobId = game.JobId
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local Stats = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer

-- =========================================================================
-- Settings & State
-- =========================================================================
local Settings = {
    AutoHop = false,            -- Start auto-hop loop (can toggle from HUD)
    AutoHopInterval = 5,        -- Seconds to stay in server before next hop
    PreferLowPlayerCount = false,
    MaxCapacityMargin = 2,      -- Leave at least 2 open slots
    VisitedCacheFile = "ServerHop_Visited.json",
    CacheExpirySeconds = 1800,  -- 30 minutes
}

local State = {
    IsHopping = false,
    Countdown = Settings.AutoHopInterval,
    LastHopAttempt = 0,
    Status = "Ready",
    TotalHopsSession = 0,
}

-- Re-execute across servers automatically
pcall(function()
    local qot = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
    if qot then
        qot([[loadfile("ServerHop.luau")()]])
    end
end)

-- =========================================================================
-- Visited Server Cache Persistence
-- =========================================================================
local function loadVisitedCache()
    local cache = {}
    pcall(function()
        if isfile and isfile(Settings.VisitedCacheFile) then
            local data = readfile(Settings.VisitedCacheFile)
            local parsed = HttpService:JSONDecode(data)
            local now = os.time()
            if type(parsed) == "table" then
                for id, ts in pairs(parsed) do
                    if (now - (tonumber(ts) or 0)) < Settings.CacheExpirySeconds then
                        cache[tostring(id)] = ts
                    end
                end
            end
        end
    end)
    cache[tostring(JobId)] = os.time()
    return cache
end

local function saveVisitedCache(cache)
    pcall(function()
        if writefile then
            writefile(Settings.VisitedCacheFile, HttpService:JSONEncode(cache))
        end
    end)
end

local VisitedServers = loadVisitedCache()
saveVisitedCache(VisitedServers)

-- =========================================================================
-- HTTP Request Wrapper
-- =========================================================================
local function customHttpRequest(url)
    local fn = (syn and syn.request) or (http and http.request) or http_request or request
    if fn then
        local ok, res = pcall(function()
            return fn({ Url = url, Method = "GET" })
        end)
        if ok and res and res.Body then
            return res.Body
        end
    end

    local ok, res = pcall(function()
        return game:HttpGet(url)
    end)
    if ok and res then return res end

    return nil
end

-- =========================================================================
-- Server Finder Engine
-- =========================================================================
local function fetchAvailableServers(sortOrder, maxPages)
    sortOrder = sortOrder or "Desc"
    maxPages = maxPages or 3
    local candidates = {}
    local cursor = ""
    local page = 0

    while page < maxPages do
        page = page + 1
        local url = string.format(
            "https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=%s&limit=100%s",
            tostring(PlaceId),
            sortOrder,
            (cursor ~= "" and ("&cursor=" .. cursor) or "")
        )

        local body = customHttpRequest(url)
        if not body then break end

        local parsed = nil
        pcall(function() parsed = HttpService:JSONDecode(body) end)
        if not parsed or not parsed.data then break end

        for _, s in ipairs(parsed.data) do
            local id = tostring(s.id)
            local playing = tonumber(s.playing) or 0
            local maxp = tonumber(s.maxPlayers) or 1
            local ping = tonumber(s.ping) or 999

            if id ~= tostring(JobId) and playing < (maxp - Settings.MaxCapacityMargin) and not VisitedServers[id] then
                table.insert(candidates, {
                    Id = id,
                    Playing = playing,
                    MaxPlayers = maxp,
                    Ping = ping,
                })
            end
        end

        if parsed.nextPageCursor and parsed.nextPageCursor ~= "null" and parsed.nextPageCursor ~= cursor then
            cursor = parsed.nextPageCursor
        else
            break
        end
    end

    return candidates
end

-- =========================================================================
-- Modern Draggable HUD
-- =========================================================================
local hudGui = nil
local statusText = nil
local statsText = nil
local countdownText = nil
local autoHopBtn = nil

local function buildHUD()
    pcall(function()
        local old = CoreGui:FindFirstChild("UnknownHub_ServerHop_HUD") or (LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("UnknownHub_ServerHop_HUD"))
        if old then old:Destroy() end
    end)

    hudGui = Instance.new("ScreenGui")
    hudGui.Name = "UnknownHub_ServerHop_HUD"
    hudGui.ResetOnSpawn = false

    local targetParent = CoreGui
    pcall(function()
        hudGui.Parent = CoreGui
    end)
    if not hudGui.Parent then
        hudGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end

    local card = Instance.new("Frame")
    card.Name = "Card"
    card.Size = UDim2.new(0, 270, 0, 220)
    card.Position = UDim2.new(1, -290, 0, 60)
    card.BackgroundColor3 = Color3.fromRGB(15, 17, 26)
    card.BorderSizePixel = 0
    card.Active = true
    card.Parent = hudGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = card

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(0, 215, 255)
    stroke.Thickness = 1.5
    stroke.Parent = card

    -- Draggable Header
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 32)
    header.BackgroundTransparency = 1
    header.Parent = card

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -16, 1, 0)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.Text = "⚡ UnknownHub | Turbo Hop"
    title.TextColor3 = Color3.fromRGB(0, 215, 255)
    title.TextSize = 13
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header

    -- Drag Logic
    local dragging, dragInput, dragStart, startPos
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = card.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    header.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            card.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    -- Status Label
    statusText = Instance.new("TextLabel")
    statusText.Size = UDim2.new(1, -20, 0, 20)
    statusText.Position = UDim2.new(0, 10, 0, 36)
    statusText.BackgroundTransparency = 1
    statusText.Font = Enum.Font.GothamMedium
    statusText.Text = "Status: Ready"
    statusText.TextColor3 = Color3.fromRGB(240, 240, 240)
    statusText.TextSize = 12
    statusText.TextXAlignment = Enum.TextXAlignment.Left
    statusText.Parent = card

    -- Stats Label
    statsText = Instance.new("TextLabel")
    statsText.Size = UDim2.new(1, -20, 0, 18)
    statsText.Position = UDim2.new(0, 10, 0, 58)
    statsText.BackgroundTransparency = 1
    statsText.Font = Enum.Font.Gotham
    local playerCount = #Players:GetPlayers()
    local maxPlayers = Players.MaxPlayers or 0
    statsText.Text = string.format("Players: %d / %d  |  Place: %s", playerCount, maxPlayers, tostring(PlaceId))
    statsText.TextColor3 = Color3.fromRGB(170, 175, 190)
    statsText.TextSize = 11
    statsText.TextXAlignment = Enum.TextXAlignment.Left
    statsText.Parent = card

    -- Countdown Label
    countdownText = Instance.new("TextLabel")
    countdownText.Size = UDim2.new(1, -20, 0, 18)
    countdownText.Position = UDim2.new(0, 10, 0, 78)
    countdownText.BackgroundTransparency = 1
    countdownText.Font = Enum.Font.GothamBold
    countdownText.Text = Settings.AutoHop and string.format("⏱️ Auto-Hop in: %.1fs", State.Countdown) or "⏱️ Auto-Hop: PAUSED"
    countdownText.TextColor3 = Settings.AutoHop and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(231, 76, 60)
    countdownText.TextSize = 11
    countdownText.TextXAlignment = Enum.TextXAlignment.Left
    countdownText.Parent = card

    -- Action Button Helper
    local function createBtn(text, yPos, color, onClick)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -20, 0, 26)
        btn.Position = UDim2.new(0, 10, 0, yPos)
        btn.BackgroundColor3 = color
        btn.Font = Enum.Font.GothamBold
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextSize = 11
        btn.AutoButtonColor = true
        btn.BorderSizePixel = 0
        btn.Parent = card

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = btn

        btn.MouseButton1Click:Connect(onClick)
        return btn
    end

    -- Button 1: Hop Random Server
    createBtn("🚀 Hop Random Server", 102, Color3.fromRGB(0, 130, 200), function()
        if not State.IsHopping then
            task.spawn(function()
                executeHop("Random")
            end)
        end
    end)

    -- Button 2: Hop Low Player Server
    createBtn("⚡ Hop Low Player Server", 132, Color3.fromRGB(142, 68, 173), function()
        if not State.IsHopping then
            task.spawn(function()
                executeHop("LowPlayer")
            end)
        end
    end)

    -- Button 3: Toggle Auto-Hop
    autoHopBtn = createBtn(Settings.AutoHop and "⏸️ Auto-Hop: [ ON ]" or "▶️ Auto-Hop: [ OFF ]", 162, Settings.AutoHop and Color3.fromRGB(39, 174, 96) or Color3.fromRGB(120, 120, 120), function()
        Settings.AutoHop = not Settings.AutoHop
        autoHopBtn.Text = Settings.AutoHop and "⏸️ Auto-Hop: [ ON ]" or "▶️ Auto-Hop: [ OFF ]"
        autoHopBtn.BackgroundColor3 = Settings.AutoHop and Color3.fromRGB(39, 174, 96) or Color3.fromRGB(120, 120, 120)
        State.Countdown = Settings.AutoHopInterval
    end)

    -- Button 4: Rejoin Current Server
    createBtn("🔄 Rejoin Current Server", 192, Color3.fromRGB(52, 73, 94), function()
        if not State.IsHopping then
            task.spawn(function()
                executeRejoin()
            end)
        end
    end)
end

local function setStatus(msg)
    State.Status = msg
    if statusText then
        statusText.Text = "Status: " .. msg
    end
end

-- =========================================================================
-- Execution & Teleport Routines
-- =========================================================================
function executeHop(mode)
    if State.IsHopping then return end
    State.IsHopping = true
    setStatus("Scraping Roblox Servers...")

    local sortOrder = (mode == "LowPlayer") and "Asc" or "Desc"
    local candidates = fetchAvailableServers(sortOrder, 4)

    if #candidates == 0 then
        -- Fallback: try opposite sort order or clear old cache
        candidates = fetchAvailableServers((sortOrder == "Asc") and "Desc" or "Asc", 4)
    end

    if #candidates > 0 then
        local chosen = nil
        if mode == "LowPlayer" then
            table.sort(candidates, function(a, b) return a.Playing < b.Playing end)
            chosen = candidates[1]
        else
            chosen = candidates[math.random(1, #candidates)]
        end

        if chosen then
            VisitedServers[chosen.Id] = os.time()
            saveVisitedCache(VisitedServers)

            setStatus(string.format("Hopping to: %s (%d/%d)...", string.sub(chosen.Id, 1, 8), chosen.Playing, chosen.MaxPlayers))
            
            pcall(function()
                TeleportService:TeleportToPlaceInstance(PlaceId, chosen.Id, LocalPlayer)
            end)

            task.wait(4)
        end
    end

    -- Universal API Fallback: If HTTP blocked or candidates empty
    setStatus("Standard Hop Fallback...")
    pcall(function()
        TeleportService:Teleport(PlaceId, LocalPlayer)
    end)

    task.wait(3)
    State.IsHopping = false
    setStatus("Ready")
end

function executeRejoin()
    if State.IsHopping then return end
    State.IsHopping = true
    setStatus("Rejoining server...")
    pcall(function()
        TeleportService:TeleportToPlaceInstance(PlaceId, JobId, LocalPlayer)
    end)
    task.wait(3)
    pcall(function()
        TeleportService:Teleport(PlaceId, LocalPlayer)
    end)
    State.IsHopping = false
end

-- =========================================================================
-- Main Auto-Hop Loop
-- =========================================================================
buildHUD()

task.spawn(function()
    while true do
        task.wait(0.2)
        
        -- Update player count
        if statsText then
            local pCount = #Players:GetPlayers()
            local maxP = Players.MaxPlayers or 0
            statsText.Text = string.format("Players: %d / %d  |  Hops: %d", pCount, maxP, State.TotalHopsSession)
        end

        if Settings.AutoHop and not State.IsHopping then
            State.Countdown = math.max(0, State.Countdown - 0.2)
            if countdownText then
                countdownText.Text = string.format("⏱️ Auto-Hop in: %.1fs", State.Countdown)
                countdownText.TextColor3 = Color3.fromRGB(46, 204, 113)
            end

            if State.Countdown <= 0 then
                State.Countdown = Settings.AutoHopInterval
                State.TotalHopsSession = State.TotalHopsSession + 1
                executeHop(Settings.PreferLowPlayerCount and "LowPlayer" or "Random")
            end
        else
            if countdownText and not State.IsHopping then
                countdownText.Text = "⏱️ Auto-Hop: PAUSED"
                countdownText.TextColor3 = Color3.fromRGB(231, 76, 60)
            end
        end
    end
end)

print("[UnknownHub] Universal Turbo Server Hop loaded successfully!")
