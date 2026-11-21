-- =========================================================================
-- UNKNOWN HUB — PLS DONATE (PlsDonate.luau)
-- High-Conversion Donation Suite: Whale Hunter, Premium Finder,
-- Smart Inactivity Auto-Hopper, Auto-Booth Snatcher & RichText Styler
-- PlaceId: 8737602449, 8943844393 | UniverseId: 3317679266
-- Universal UnknownLibrary V2.2
-- =========================================================================

local LIBRARY_LINK = "https://raw.githubusercontent.com/UnknownHQ/UnknownHub/main/UnknownLibrary"
local LIBRARY_NAME = "Unknown_PlsDonate_Hub_UI"

local currentSession = tick()
_G.PLSDONATE_SESSION = currentSession

-- =========================================================================
-- Core Services & State
-- =========================================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId
local CurrentJobId = game.JobId

-- Global visited servers cache to prevent looping back into stale servers
getgenv().VisitedServers = getgenv().VisitedServers or {}
getgenv().VisitedServers[CurrentJobId] = true

local State = {
    -- Whale & Premium Targeting
    WhaleHunter = true,
    WhaleThreshold = 10000, -- Min donated Robux to consider player a whale
    PremiumPriority = true,
    MinPremiumPlayers = 2,
    MinServerTotalDonated = 25000,
    RequireMinTotalDonated = false,
    HopIfWhaleLeaves = true,

    -- Smart Inactivity Auto-Hop
    AutoHopInactivity = true,
    InactivityMinutes = 8, -- Sweet-spot: 8 minutes without donation triggers server hop
    ResetTimerOnDonate = true,
    MinPlayersInServer = 14,
    MaxPlayersInServer = 28,

    -- Booth Automation
    AutoClaimBooth = true,
    PreferSpawnBooth = true,
    AutoStandAtBooth = true,
    DynamicRaisedUpdate = true,
    ActivePreset = "Golden Goal",
    CustomBoothText = '<font color="#FFD700" size="18"><b>⭐ GOAL: [Raised]/1,000 R$ ⭐</b></font><br/><font color="#00FFFF">Every donation helps a lot! ❤️</font>',

    -- Anti-AFK
    AntiAFK = true,
    AutoReconnect = true,
}

-- Session Metrics Tracking
local Metrics = {
    InitialRaised = 0,
    TotalRaisedThisSession = 0,
    DonationsCount = 0,
    LargestDonation = 0,
    LastDonationTick = tick(),
    JoinTick = tick(),
    ClaimedBoothModel = nil,
    ClaimedBoothPart = nil,
    IsHopping = false,
}

-- =========================================================================
-- Anti-AFK & Auto-Reconnect Safeguard (24/7 Persistence)
-- =========================================================================
pcall(function()
    if getconnections then
        for _, conn in ipairs(getconnections(LocalPlayer.Idled)) do
            if conn.Disable then conn:Disable()
            elseif conn.Disconnect then conn:Disconnect() end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(45)
        if _G.PLSDONATE_SESSION ~= currentSession then break end
        if State.AntiAFK then
            pcall(function()
                local vim = game:GetService("VirtualInputManager")
                if vim then
                    vim:SendKeyEvent(true, Enum.KeyCode.RightControl, false, game)
                    task.wait(0.04)
                    vim:SendKeyEvent(false, Enum.KeyCode.RightControl, false, game)
                end
                if VirtualUser then
                    VirtualUser:CaptureController()
                    VirtualUser:ClickButton2(Vector2.new(0, 0))
                end
            end)
        end
    end
end)

-- Auto-Reconnect on Disconnect Error
pcall(function()
    local coreGui = game:GetService("CoreGui")
    local function watchPromptGui(promptGui)
        local overlay = promptGui:FindFirstChild("promptOverlay")
        if overlay then
            overlay.ChildAdded:Connect(function(child)
                if child.Name == "ErrorPrompt" and State.AutoReconnect then
                    task.wait(2)
                    pcall(function()
                        TeleportService:Teleport(PlaceId, LocalPlayer)
                    end)
                end
            end)
        end
    end
    local promptGui = coreGui:FindFirstChild("RobloxPromptGui")
    if promptGui then watchPromptGui(promptGui) end
end)

-- =========================================================================
-- Server Intelligence & Diagnostics Engine
-- =========================================================================
local function scanServerEconomy()
    local players = Players:GetPlayers()
    local totalDonated = 0
    local premiumCount = 0
    local whaleCount = 0
    local topDonators = {}

    for _, p in ipairs(players) do
        local isPremium = (p.MembershipType == Enum.MembershipType.Premium)
        if isPremium then
            premiumCount = premiumCount + 1
        end

        local leaderstats = p:FindFirstChild("leaderstats")
        local donatedVal = 0
        local raisedVal = 0

        if leaderstats then
            local dObj = leaderstats:FindFirstChild("Donated")
            local rObj = leaderstats:FindFirstChild("Raised")
            if dObj and tonumber(dObj.Value) then donatedVal = tonumber(dObj.Value) end
            if rObj and tonumber(rObj.Value) then raisedVal = tonumber(rObj.Value) end
        end

        totalDonated = totalDonated + donatedVal

        if donatedVal >= State.WhaleThreshold and p ~= LocalPlayer then
            whaleCount = whaleCount + 1
            table.insert(topDonators, {
                Player = p,
                Name = p.Name,
                DisplayName = p.DisplayName,
                Donated = donatedVal,
                Raised = raisedVal,
                IsPremium = isPremium
            })
        end
    end

    table.sort(topDonators, function(a, b) return a.Donated > b.Donated end)

    return {
        PlayerCount = #players,
        PremiumCount = premiumCount,
        WhaleCount = whaleCount,
        TotalDonated = totalDonated,
        TopDonators = topDonators
    }
end

-- =========================================================================
-- Bulletproof Public Server Hopper
-- =========================================================================
local function hopToNextServer(reason)
    if Metrics.IsHopping then return end
    Metrics.IsHopping = true

    pcall(function()
        if Hub and Hub.Notify then
            Hub.Notify({
                Title = "🚀 Server Hop Triggered",
                Content = tostring(reason or "Searching for a rich lobby..."),
                Duration = 4
            })
        end
    end)

    -- Queue this script so it automatically reloads upon arrival
    pcall(function()
        local queueFn = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
        if queueFn then
            local loaderCode = [[
                task.spawn(function()
                    task.wait(2)
                    pcall(function()
                        local code = game:HttpGet("https://raw.githubusercontent.com/UnknownHQ/UnknownHub/main/Games/PlsDonate.luau")
                        loadstring(code)()
                    end)
                end)
            ]]
            queueFn(loaderCode)
        end
    end)

    task.spawn(function()
        local cursor = ""
        local attempts = 0

        while attempts < 8 do
            attempts = attempts + 1
            local url = string.format(
                "https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Desc&limit=100%s",
                tostring(PlaceId),
                cursor ~= "" and ("&cursor=" .. cursor) or ""
            )

            local ok, raw = pcall(function() return game:HttpGet(url) end)
            if ok and raw then
                local data = nil
                pcall(function() data = HttpService:JSONDecode(raw) end)
                if data and data.data then
                    for _, srv in ipairs(data.data) do
                        local playing = tonumber(srv.playing) or 0
                        local maxP = tonumber(srv.maxPlayers) or 28
                        if playing >= State.MinPlayersInServer
                            and playing < maxP
                            and srv.id ~= CurrentJobId
                            and not getgenv().VisitedServers[srv.id] then

                            getgenv().VisitedServers[srv.id] = true
                            pcall(function()
                                TeleportService:TeleportToPlaceInstance(PlaceId, srv.id, LocalPlayer)
                            end)
                            task.wait(3)
                        end
                    end
                    cursor = data.nextPageCursor or ""
                    if cursor == "" then break end
                end
            end
            task.wait(1)
        end

        -- Fallback default teleport
        pcall(function()
            TeleportService:Teleport(PlaceId, LocalPlayer)
        end)
        Metrics.IsHopping = false
    end)
end

-- =========================================================================
-- Auto-Booth Claimer & Snatcher Engine
-- =========================================================================
local function getMyClaimedBooth()
    -- Method 1: Check BoothInteractions / Booths for LocalPlayer ownership
    local boothsFolder = Workspace:FindFirstChild("BoothInteractions") or Workspace:FindFirstChild("Booths") or Workspace:FindFirstChild("CustomiseBooths")
    if boothsFolder then
        for _, b in ipairs(boothsFolder:GetChildren()) do
            local ownerAttr = b:GetAttribute("Owner") or b:GetAttribute("owner") or b:GetAttribute("UserId")
            if ownerAttr and (ownerAttr == LocalPlayer.UserId or ownerAttr == LocalPlayer.Name) then
                return b
            end
            local ownerVal = b:FindFirstChild("Owner") or b:FindFirstChild("owner")
            if ownerVal and (ownerVal.Value == LocalPlayer.UserId or ownerVal.Value == LocalPlayer.Name or ownerVal.Value == LocalPlayer) then
                return b
            end
        end
    end

    -- Method 2: Check LocalPlayer attributes
    local boothId = LocalPlayer:GetAttribute("Booth") or LocalPlayer:GetAttribute("BoothId")
    if boothId and boothsFolder then
        local b = boothsFolder:FindFirstChild(tostring(boothId))
        if b then return b end
    end

    return nil
end

local function findBestOpenBooth()
    local boothsFolder = Workspace:FindFirstChild("BoothInteractions") or Workspace:FindFirstChild("Booths") or Workspace:FindFirstChild("CustomiseBooths")
    local candidates = {}

    local spawnPos = Vector3.new(0, 0, 0)
    local spawnLoc = Workspace:FindFirstChild("SpawnLocation", true)
    if spawnLoc and spawnLoc:IsA("BasePart") then
        spawnPos = spawnLoc.Position
    end

    local function checkBoothCandidate(b)
        if not b then return end
        local isClaimed = false

        -- Check ownership attributes / children
        if b:GetAttribute("Owner") or b:GetAttribute("owner") or b:GetAttribute("UserId") then
            isClaimed = true
        end
        local ownerVal = b:FindFirstChild("Owner") or b:FindFirstChild("owner")
        if ownerVal and ownerVal.Value and tostring(ownerVal.Value) ~= "" and tostring(ownerVal.Value) ~= "0" then
            isClaimed = true
        end

        local prompt = b:FindFirstChildWhichIsA("ProximityPrompt", true)
        if prompt and prompt.Enabled and not isClaimed then
            local part = prompt.Parent:IsA("BasePart") and prompt.Parent or b:FindFirstChildWhichIsA("BasePart", true)
            if part then
                local distToSpawn = (part.Position - spawnPos).Magnitude
                table.insert(candidates, {
                    Model = b,
                    Part = part,
                    Prompt = prompt,
                    DistanceToSpawn = distToSpawn
                })
            end
        end
    end

    if boothsFolder then
        for _, child in ipairs(boothsFolder:GetChildren()) do
            checkBoothCandidate(child)
        end
    end

    -- Also scan global ProximityPrompts with ActionText "Claim"
    if #candidates == 0 then
        for _, desc in ipairs(Workspace:GetDescendants()) do
            if desc:IsA("ProximityPrompt") and desc.Enabled then
                local action = desc.ActionText:lower()
                local obj = desc.ObjectText:lower()
                if action:find("claim") or obj:find("booth") then
                    local part = desc.Parent:IsA("BasePart") and desc.Parent or desc:FindFirstAncestorWhichIsA("BasePart")
                    if part then
                        table.insert(candidates, {
                            Model = desc.Parent,
                            Part = part,
                            Prompt = desc,
                            DistanceToSpawn = (part.Position - spawnPos).Magnitude
                        })
                    end
                end
            end
        end
    end

    if #candidates == 0 then return nil end

    if State.PreferSpawnBooth then
        table.sort(candidates, function(a, b) return a.DistanceToSpawn < b.DistanceToSpawn end)
    end

    return candidates[1]
end

local function claimBooth(candidate)
    if not candidate then return false end
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return false end

    local success = false
    pcall(function()
        -- Teleport character near booth to satisfy server magnitude validation
        root.CFrame = candidate.Part.CFrame + Vector3.new(0, 2, 0)
        task.wait(0.2)

        -- Fire proximity prompt
        if fireproximityprompt and candidate.Prompt then
            fireproximityprompt(candidate.Prompt, 0)
            success = true
        end

        -- Remote invocation fallback
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if remotes then
            pcall(function()
                local claimFunc = remotes:FindFirstChild("ClaimBooth")
                if claimFunc and claimFunc:IsA("RemoteFunction") then
                    claimFunc:InvokeServer(candidate.Model.Name or candidate.Model)
                end
            end)
            pcall(function()
                local claimEvt = remotes:FindFirstChild("ClaimBooth")
                if claimEvt and claimEvt:IsA("RemoteEvent") then
                    claimEvt:FireServer(candidate.Model.Name or candidate.Model)
                end
            end)
            pcall(function()
                require(remotes).Function("ClaimBooth"):InvokeServer(candidate.Model.Name or candidate.Model)
            end)
        end
    end)

    return success
end

-- =========================================================================
-- RichText Booth Styler Engine
-- =========================================================================
local Presets = {
    ["Golden Goal"] = '<font color="#FFD700" size="18"><b>⭐ GOAL: [Raised]/1,000 R$ ⭐</b></font><br/><font color="#00FFFF">Every donation helps a lot! ❤️</font>',
    ["Cyber Neon"] = '<font color="#00FFCC"><b>⚡ DREAM GOAL ⚡</b></font><br/><stroke color="#000000" thickness="2"><font color="#FF00FF"><b>[Raised] Robux Raised</b></font></stroke><br/><font color="#FFFF00">Thank you for donating!</font>',
    ["Pastel Dreams"] = '<font color="#FFB6C1"><b>ʚ Any donation appreciated ɞ</b></font><br/><font color="#E0FFFF">goal: [Raised] / 500 R$</font>',
    ["Diamond VIP"] = '<font color="#55FFFF"><b>💎 Premium Supporter Goal 💎</b></font><br/><font color="#FF88FF"><b>Raised: [Raised] R$</b></font><br/><font color="#FFFFAA">Bless you!</font>'
}

local function formatBoothText(rawText)
    local curRaised = 0
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    if leaderstats and leaderstats:FindFirstChild("Raised") then
        curRaised = tonumber(leaderstats.Raised.Value) or 0
    end

    local formatted = rawText:gsub("%[Raised%]", tostring(curRaised))
    formatted = formatted:gsub("%[raised%]", tostring(curRaised))
    return formatted
end

local function applyBoothText(textToApply)
    local finalText = formatBoothText(textToApply or State.CustomBoothText)

    pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if remotes then
            -- Method A: Direct RemoteEvent inside Remotes folder
            local setEvt = remotes:FindFirstChild("SetBoothText")
            if setEvt and setEvt:IsA("RemoteEvent") then
                setEvt:FireServer(finalText, "booth")
            end

            -- Method B: require(Remotes).Event("SetBoothText")
            pcall(function()
                require(remotes).Event("SetBoothText"):FireServer(finalText, "booth")
            end)

            -- Method C: Events folder fallback
            local evts = ReplicatedStorage:FindFirstChild("Events")
            if evts then
                local editEvt = evts:FindFirstChild("EditBooth") or evts:FindFirstChild("SetBoothText")
                if editEvt and editEvt:IsA("RemoteEvent") then
                    editEvt:FireServer(finalText, "booth")
                end
            end
        end
    end)
end

-- =========================================================================
-- Donation Receiver & Real-Time Inactivity Engine
-- =========================================================================
task.spawn(function()
    local leaderstats = LocalPlayer:WaitForChild("leaderstats", 15)
    if not leaderstats then return end
    local raisedObj = leaderstats:WaitForChild("Raised", 10)
    if not raisedObj then return end

    Metrics.InitialRaised = tonumber(raisedObj.Value) or 0
    local lastKnown = Metrics.InitialRaised

    raisedObj:GetPropertyChangedSignal("Value"):Connect(function()
        local current = tonumber(raisedObj.Value) or 0
        if current > lastKnown then
            local delta = current - lastKnown
            lastKnown = current

            Metrics.DonationsCount = Metrics.DonationsCount + 1
            Metrics.TotalRaisedThisSession = Metrics.TotalRaisedThisSession + delta
            if delta > Metrics.LargestDonation then
                Metrics.LargestDonation = delta
            end

            if State.ResetTimerOnDonate then
                Metrics.LastDonationTick = tick()
            end

            pcall(function()
                if Hub and Hub.Notify then
                    Hub.Notify({
                        Title = "🎉 DONATION RECEIVED!",
                        Content = string.format("+%d Robux! (Session: +%d R$)", delta, Metrics.TotalRaisedThisSession),
                        Duration = 6
                    })
                end
            end)

            -- Auto-update booth text if using dynamic [Raised] tag
            if State.DynamicRaisedUpdate then
                task.delay(1, function()
                    applyBoothText()
                end)
            end
        end
    end)
end)

-- Background Evaluation & Inactivity Watchdog
task.spawn(function()
    -- Initial warm-up: allow server and player list to replicate (15 seconds)
    task.wait(15)

    while true do
        if _G.PLSDONATE_SESSION ~= currentSession then break end
        task.wait(2)

        local stats = scanServerEconomy()

        -- 1. Check Whale Hunter Filter
        if State.WhaleHunter and stats.WhaleCount == 0 then
            hopToNextServer("Whale Hunter: No players with " .. State.WhaleThreshold .. "+ donated in this server.")
            break
        end

        -- 2. Check Premium Priority Filter
        if State.PremiumPriority and stats.PremiumCount < State.MinPremiumPlayers then
            hopToNextServer(string.format("Premium Finder: Found %d/%d required Roblox Premium players.", stats.PremiumCount, State.MinPremiumPlayers))
            break
        end

        -- 3. Check Minimum Server Total Donated Filter
        if State.RequireMinTotalDonated and stats.TotalDonated < State.MinServerTotalDonated then
            hopToNextServer(string.format("Server Economy: Server total donated (%d R$) is below threshold (%d R$).", stats.TotalDonated, State.MinServerTotalDonated))
            break
        end

        -- 4. Check Inactivity Timeout (Sweet spot: default 8 minutes)
        if State.AutoHopInactivity then
            local elapsed = tick() - Metrics.LastDonationTick
            local limit = State.InactivityMinutes * 60
            if elapsed >= limit then
                hopToNextServer(string.format("Inactivity Sweet-Spot: No donations received in %d minutes. Hopping to fresher server...", State.InactivityMinutes))
                break
            end
        end
    end
end)

-- Player Leaving Listener (Whale Departure Detection)
Players.PlayerRemoving:Connect(function(player)
    if State.HopIfWhaleLeaves and player ~= LocalPlayer then
        local leaderstats = player:FindFirstChild("leaderstats")
        local donatedVal = leaderstats and leaderstats:FindFirstChild("Donated") and tonumber(leaderstats.Donated.Value) or 0
        if donatedVal >= State.WhaleThreshold then
            task.delay(3, function()
                local stats = scanServerEconomy()
                if stats.WhaleCount == 0 then
                    hopToNextServer("Whale Departure: The primary whale (" .. player.DisplayName .. ") left the server.")
                end
            end)
        end
    end
end)

-- Booth Anchor & Auto-Claim Loop
task.spawn(function()
    task.wait(3)
    while true do
        if _G.PLSDONATE_SESSION ~= currentSession then break end
        task.wait(5)

        if State.AutoClaimBooth and not Metrics.ClaimedBoothModel then
            local myBooth = getMyClaimedBooth()
            if myBooth then
                Metrics.ClaimedBoothModel = myBooth
                Metrics.ClaimedBoothPart = myBooth:FindFirstChildWhichIsA("BasePart", true)
                applyBoothText()
            else
                local bestOpen = findBestOpenBooth()
                if bestOpen then
                    claimBooth(bestOpen)
                    task.wait(2)
                    myBooth = getMyClaimedBooth()
                    if myBooth then
                        Metrics.ClaimedBoothModel = myBooth
                        Metrics.ClaimedBoothPart = myBooth:FindFirstChildWhichIsA("BasePart", true)
                        applyBoothText()
                    end
                end
            end
        end

        -- Maintain position at claimed booth
        if State.AutoStandAtBooth and Metrics.ClaimedBoothPart then
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root and (root.Position - Metrics.ClaimedBoothPart.Position).Magnitude > 25 then
                root.CFrame = Metrics.ClaimedBoothPart.CFrame + Vector3.new(0, 3, 0)
            end
        end
    end
end)

-- =========================================================================
-- Unknown Hub UI Initialization
-- =========================================================================
local Hub = nil
pcall(function()
    local libCode = readfile("UnknownLibrary.luau")
    Hub = loadstring(libCode)()
end)

if not Hub then
    local ok, res = pcall(function()
        return game:HttpGet(LIBRARY_LINK .. ".luau")
    end)
    if ok and res then
        Hub = loadstring(res)()
    end
end

if not Hub then
    warn("[Unknown Hub] Failed to load UnknownLibrary for PLS DONATE.")
    return
end

Hub.Init({
    title = "Unknown Hub",
    subTitle = "PLS DONATE",
    parent = (gethui and gethui()) or LocalPlayer:WaitForChild("PlayerGui"),
    theme = Color3.fromRGB(0, 215, 255),
    secondaryTheme = Color3.fromRGB(0, 160, 215)
})

-- UI Tabs
local overviewTab = Hub.CreateTab("Overview", { Icon = "🏠", Size = 18, Color = Color3.fromRGB(170, 185, 210), ActiveColor = Color3.fromRGB(0, 215, 255) })
local whaleTab = Hub.CreateTab("Whales & Premium", { Icon = "🐋", Size = 18, Color = Color3.fromRGB(170, 185, 210), ActiveColor = Color3.fromRGB(255, 180, 50) })
local hopperTab = Hub.CreateTab("Auto-Hop", { Icon = "⏳", Size = 18, Color = Color3.fromRGB(170, 185, 210), ActiveColor = Color3.fromRGB(50, 220, 120) })
local boothTab = Hub.CreateTab("Booth Styler", { Icon = "🎨", Size = 18, Color = Color3.fromRGB(170, 185, 210), ActiveColor = Color3.fromRGB(255, 110, 180) })
local safeTab = Hub.CreateTab("Safeguards", { Icon = "🛡️", Size = 18, Color = Color3.fromRGB(170, 185, 210), ActiveColor = Color3.fromRGB(180, 140, 255) })

-- =========================================================================
-- Tab 1: Overview & Live Metrics
-- =========================================================================
Hub.CreateSection(overviewTab, "📊 Live Server Intelligence")

local statPlayers = Hub.CreateStatRow(overviewTab, "Players In Server", tostring(#Players:GetPlayers()) .. " / 28")
local statPremium = Hub.CreateStatRow(overviewTab, "Roblox Premium Members", "Scanning...")
local statWhales = Hub.CreateStatRow(overviewTab, "Active Whales In Server", "Scanning...")
local statServerDonated = Hub.CreateStatRow(overviewTab, "Server Total Donated", "Calculating...")
local statInactivity = Hub.CreateStatRow(overviewTab, "Inactivity Hop Countdown", "Calculating...")

Hub.CreateSection(overviewTab, "💸 Session Raised Metrics")

local statTotalRaised = Hub.CreateStatRow(overviewTab, "Robux Raised This Session", "+0 R$")
local statDonationsCount = Hub.CreateStatRow(overviewTab, "Donations Received", "0")
local statLargestDonation = Hub.CreateStatRow(overviewTab, "Largest Donation", "0 R$")

Hub.CreateSection(overviewTab, "⚡ Quick Actions")

Hub.CreateButton(overviewTab, "🚀 Hop To Richer Server Now", function()
    hopToNextServer("Manual user trigger: searching for richer lobby...")
end)

Hub.CreateButton(overviewTab, "🎯 Snatch Nearest Open Booth", function()
    local best = findBestOpenBooth()
    if best then
        claimBooth(best)
        Hub.Notify({ Title = "Booth Snatcher", Content = "Attempting claim on booth near spawn!", Duration = 2 })
    else
        Hub.Notify({ Title = "Booth Snatcher", Content = "No open booths found.", Duration = 2 })
    end
end)

-- Live Overview Refresh Loop
task.spawn(function()
    while true do
        if _G.PLSDONATE_SESSION ~= currentSession then break end
        task.wait(1)

        pcall(function()
            local s = scanServerEconomy()
            if statPlayers and statPlayers.Set then statPlayers.Set(tostring(s.PlayerCount) .. " / 28") end
            if statPremium and statPremium.Set then statPremium.Set(tostring(s.PremiumCount) .. " Premium") end
            if statWhales and statWhales.Set then statWhales.Set(tostring(s.WhaleCount) .. " Whales (>" .. State.WhaleThreshold .. " R$)") end
            if statServerDonated and statServerDonated.Set then statServerDonated.Set(string.format("%d R$", s.TotalDonated)) end

            -- Inactivity countdown
            local elapsed = tick() - Metrics.LastDonationTick
            local rem = math.max(0, math.floor(State.InactivityMinutes * 60 - elapsed))
            local mins = math.floor(rem / 60)
            local secs = rem % 60
            if statInactivity and statInactivity.Set then
                statInactivity.Set(string.format("%dm %02ds remaining", mins, secs))
            end

            -- Session metrics
            if statTotalRaised and statTotalRaised.Set then statTotalRaised.Set(string.format("+%d R$", Metrics.TotalRaisedThisSession)) end
            if statDonationsCount and statDonationsCount.Set then statDonationsCount.Set(tostring(Metrics.DonationsCount)) end
            if statLargestDonation and statLargestDonation.Set then statLargestDonation.Set(string.format("%d R$", Metrics.LargestDonation)) end
        end)
    end
end)

-- =========================================================================
-- Tab 2: Whales & Roblox Premium Targeting
-- =========================================================================
Hub.CreateSection(whaleTab, "🐋 Whale Hunter Configuration")

Hub.CreateToggle(whaleTab, "🐋 Enable Whale Hunter", State.WhaleHunter, function(v)
    State.WhaleHunter = v
end)

Hub.CreateSlider(whaleTab, "Whale Donated Threshold (R$)", 1000, 100000, State.WhaleThreshold, " R$", function(v)
    State.WhaleThreshold = math.floor(v)
end)

Hub.CreateToggle(whaleTab, "🏃 Hop If Whale Leaves Server", State.HopIfWhaleLeaves, function(v)
    State.HopIfWhaleLeaves = v
end)

Hub.CreateSection(whaleTab, "⭐ Roblox Premium (Subscribers) Finder")

Hub.CreateToggle(whaleTab, "⭐ Prioritize Roblox Premium Servers", State.PremiumPriority, function(v)
    State.PremiumPriority = v
end)

Hub.CreateSlider(whaleTab, "Minimum Premium Players Required", 1, 8, State.MinPremiumPlayers, " Players", function(v)
    State.MinPremiumPlayers = math.floor(v)
end)

Hub.CreateSection(whaleTab, "💰 Server Economy Quality Filter")

Hub.CreateToggle(whaleTab, "Require Minimum Server Total Donated", State.RequireMinTotalDonated, function(v)
    State.RequireMinTotalDonated = v
end)

Hub.CreateSlider(whaleTab, "Min Server Total Donated", 5000, 200000, State.MinServerTotalDonated, " R$", function(v)
    State.MinServerTotalDonated = math.floor(v)
end)

-- =========================================================================
-- Tab 3: Smart Auto-Hop & Sweet-Spot Timing
-- =========================================================================
Hub.CreateSection(hopperTab, "⏳ Inactivity Sweet-Spot Server Hopper")

Hub.CreateToggle(hopperTab, "⏳ Auto-Hop on Inactivity", State.AutoHopInactivity, function(v)
    State.AutoHopInactivity = v
end)

Hub.CreateSlider(hopperTab, "Inactivity Timeout (Minutes)", 3, 20, State.InactivityMinutes, " mins", function(v)
    State.InactivityMinutes = math.floor(v)
end)

Hub.CreateToggle(hopperTab, "🔄 Reset Countdown When Donated", State.ResetTimerOnDonate, function(v)
    State.ResetTimerOnDonate = v
end)

Hub.CreateSection(hopperTab, "🌐 Server Lobby Population Filters")

Hub.CreateSlider(hopperTab, "Min Server Population", 8, 24, State.MinPlayersInServer, " Players", function(v)
    State.MinPlayersInServer = math.floor(v)
end)

Hub.CreateButton(hopperTab, "🔄 Reset Inactivity Timer Manually", function()
    Metrics.LastDonationTick = tick()
    Hub.Notify({ Title = "Timer Reset", Content = "Inactivity countdown refreshed.", Duration = 2 })
end)

-- =========================================================================
-- Tab 4: Booth Snatcher & RichText Styler
-- =========================================================================
Hub.CreateSection(boothTab, "⚡ Auto Booth Management")

Hub.CreateToggle(boothTab, "⚡ Auto-Claim Booth on Join", State.AutoClaimBooth, function(v)
    State.AutoClaimBooth = v
end)

Hub.CreateToggle(boothTab, "🎯 Prefer Closest Booth to Spawn", State.PreferSpawnBooth, function(v)
    State.PreferSpawnBooth = v
end)

Hub.CreateToggle(boothTab, "📍 Auto-Stand At Claimed Booth", State.AutoStandAtBooth, function(v)
    State.AutoStandAtBooth = v
end)

Hub.CreateSection(boothTab, "🎨 High-Contrast RichText Styler")

local presetList = { "Golden Goal", "Cyber Neon", "Pastel Dreams", "Diamond VIP" }

Hub.CreateDropdown(boothTab, "🎨 Style Presets", presetList, State.ActivePreset, function(chosen)
    State.ActivePreset = chosen
    if Presets[chosen] then
        State.CustomBoothText = Presets[chosen]
        applyBoothText()
        Hub.Notify({ Title = "Booth Style", Content = "Applied preset: " .. chosen, Duration = 2 })
    end
end)

Hub.CreateToggle(boothTab, "🔄 Auto-Update Dynamic [Raised] Tag", State.DynamicRaisedUpdate, function(v)
    State.DynamicRaisedUpdate = v
end)

Hub.CreateTextBox(boothTab, "Custom Booth Text (RichText & [Raised])", State.CustomBoothText, function(text)
    if text and text ~= "" then
        State.CustomBoothText = text
    end
end)

Hub.CreateButton(boothTab, "⚡ Apply Booth Text Now", function()
    applyBoothText()
    Hub.Notify({ Title = "Booth Styler", Content = "Booth text synchronized to server!", Duration = 2 })
end)

-- =========================================================================
-- Tab 5: Safeguards & Persistence
-- =========================================================================
Hub.CreateSection(safeTab, "🛡️ AFK Persistence & Safeguards")

Hub.CreateToggle(safeTab, "🛡️ Anti-AFK (Bypass 20m Kick)", State.AntiAFK, function(v)
    State.AntiAFK = v
end)

Hub.CreateToggle(safeTab, "🔄 Auto-Reconnect on Disconnect", State.AutoReconnect, function(v)
    State.AutoReconnect = v
end)

Hub.finishLoading("PLS DONATE high-conversion suite loaded!")
