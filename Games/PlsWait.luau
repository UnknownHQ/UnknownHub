-- =========================================================================
-- UNKNOWN HUB — PLS WAIT (PlsWait.luau)
-- Comprehensive Idle & Donation Suite: Auto-Spot Claimer, Whale Hunter,
-- Smart Inactivity Auto-Hopper, Auto-Thanker & RichText Wait Styler
-- Target: PLS WAIT (PlaceId: 14212732626)
-- Universal UnknownLibrary V2.2
-- =========================================================================

local LIBRARY_LINK = "https://raw.githubusercontent.com/UnknownHQ/UnknownHub/main/UnknownLibrary"
local LIBRARY_NAME = "Unknown_PlsWait_Hub_UI"

local currentSession = tick()
_G.PLSWAIT_SESSION = currentSession

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

-- Global visited servers cache to avoid looping into dead lobbies
getgenv().VisitedServers = getgenv().VisitedServers or {}
getgenv().VisitedServers[CurrentJobId] = true

local State = {
    -- Spot / Stand Automation
    AutoClaimSpot = true,
    AutoStandAtSpot = true,
    AntiPushLock = true,
    SpotDistanceCheck = 5.0,
    ClaimedSpot = nil,
    ClaimedCFrame = nil,

    -- Dynamic Text & Goal Styler
    DynamicTextUpdate = true,
    UpdateInterval = 15,
    ActivePreset = "Neon Waiter",
    CustomWaitText = '<font color="#00FFFF"><b>⏳ WAITING TIME: [Time]</b></font><br/><font color="#FFD700"><b>⭐ GOAL: [Raised]/1,000 R$ ⭐</b></font><br/><font color="#FF69B4">Every donation is loved! ❤️</font>',

    -- Whale Hunter & Server Intelligence
    WhaleHunter = true,
    WhaleThreshold = 5000, -- Min donated Robux to count as a whale
    MinServerTotalDonated = 15000,
    RequireMinTotalDonated = false,
    HopIfWhaleLeaves = true,
    MinPlayersInServer = 10,
    MaxPlayersInServer = 28,

    -- Smart Inactivity Auto-Hop
    AutoHopInactivity = true,
    InactivityMinutes = 10, -- Hop after 10 mins without any donation
    ResetTimerOnDonate = true,

    -- Auto-Thanker & Social
    AutoThank = true,
    ThankDelay = 1.5,
    ThankMessages = {
        "TYSM for the donation {donor}! ❤️",
        "OMG {donor} thank you so much! Really appreciate the love!",
        "Thank you {donor}! You are an absolute legend! ⭐",
        "W {donor}!! Tysm for supporting my wait! 💖"
    },
    AutoBeggar = false,
    BeggarInterval = 120,
    BeggarMessages = {
        "Waiting for kindness! Every Robux helps toward my goal! ⏳❤️",
        "Still patiently waiting here, donations mean the world! ⭐",
        "Appreciate anyone helping out with my wait goal! 💖"
    },

    -- Utility & Anti-AFK
    AntiAFK = true,
    AutoReconnect = true,
    WalkSpeedEnabled = false,
    CustomWalkSpeed = 24,
    JumpPowerEnabled = false,
    CustomJumpPower = 60,
}

-- Session Metrics Tracking
local Metrics = {
    InitialRaised = 0,
    TotalRaisedThisSession = 0,
    DonationsCount = 0,
    LargestDonation = 0,
    LastDonationTick = tick(),
    JoinTick = tick(),
    IsHopping = false,
}

-- Format Seconds to HH:MM:SS
local function formatDuration(seconds)
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = math.floor(seconds % 60)
    if h > 0 then
        return string.format("%02d:%02d:%02d", h, m, s)
    else
        return string.format("%02d:%02d", m, s)
    end
end

-- =========================================================================
-- Anti-AFK & Auto-Reconnect Safeguards
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
        task.wait(40)
        if _G.PLSWAIT_SESSION ~= currentSession then break end
        if State.AntiAFK then
            pcall(function()
                local vim = game:GetService("VirtualInputManager")
                if vim then
                    vim:SendKeyEvent(true, Enum.KeyCode.RightControl, false, game)
                    task.wait(0.05)
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

-- Reconnect safeguard
pcall(function()
    local coreGui = game:GetService("CoreGui")
    local promptGui = coreGui:FindFirstChild("RobloxPromptGui")
    if promptGui then
        local overlay = promptGui:FindFirstChild("promptOverlay")
        if overlay then
            overlay.ChildAdded:Connect(function(child)
                if child.Name == "ErrorPrompt" and State.AutoReconnect then
                    task.wait(2.5)
                    pcall(function()
                        TeleportService:Teleport(PlaceId, LocalPlayer)
                    end)
                end
            end)
        end
    end
end)

-- =========================================================================
-- Server Intelligence & Diagnostics Engine
-- =========================================================================
local function scanServerEconomy()
    local players = Players:GetPlayers()
    local totalDonated = 0
    local totalRaised = 0
    local whaleCount = 0
    local topDonators = {}

    for _, p in ipairs(players) do
        local leaderstats = p:FindFirstChild("leaderstats")
        local donatedVal = 0
        local raisedVal = 0

        if leaderstats then
            for _, stat in ipairs(leaderstats:GetChildren()) do
                local name = stat.Name:lower()
                if name:find("donat") or name:find("spent") or name:find("robux") then
                    if tonumber(stat.Value) then donatedVal = tonumber(stat.Value) end
                elseif name:find("rais") or name:find("earn") or name:find("point") then
                    if tonumber(stat.Value) then raisedVal = tonumber(stat.Value) end
                end
            end
        end

        totalDonated = totalDonated + donatedVal
        totalRaised = totalRaised + raisedVal

        if donatedVal >= State.WhaleThreshold and p ~= LocalPlayer then
            whaleCount = whaleCount + 1
            table.insert(topDonators, {
                Player = p,
                Name = p.Name,
                DisplayName = p.DisplayName,
                Donated = donatedVal,
                Raised = raisedVal
            })
        end
    end

    table.sort(topDonators, function(a, b) return a.Donated > b.Donated end)

    return {
        PlayerCount = #players,
        WhaleCount = whaleCount,
        TotalDonated = totalDonated,
        TotalRaised = totalRaised,
        TopDonators = topDonators
    }
end

-- =========================================================================
-- Advanced Server Hopper (Whale Targeting + Low Latency)
-- =========================================================================
local function hopServer()
    if Metrics.IsHopping then return end
    Metrics.IsHopping = true

    local notifyHop = function(msg)
        pcall(function()
            game.StarterGui:SetCore("SendNotification", {
                Title = "Unknown Hub",
                Text = msg,
                Duration = 4
            })
        end)
    end

    notifyHop("Scanning Roblox API for active public servers...")

    task.spawn(function()
        local cursor = ""
        local attempts = 0
        local targetJob = nil

        while attempts < 4 and not targetJob do
            attempts = attempts + 1
            local url = string.format(
                "https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Desc&excludeFullGames=true&limit=50%s",
                tostring(PlaceId),
                cursor ~= "" and ("&cursor=" .. cursor) or ""
            )

            local success, res = pcall(function()
                return game:HttpGet(url)
            end)

            if success and res then
                local decodeSuccess, data = pcall(function()
                    return HttpService:JSONDecode(res)
                end)

                if decodeSuccess and data and data.data then
                    local viableServers = {}
                    for _, srv in ipairs(data.data) do
                        if srv.id ~= CurrentJobId
                            and not getgenv().VisitedServers[srv.id]
                            and srv.playing >= State.MinPlayersInServer
                            and srv.playing <= State.MaxPlayersInServer
                        then
                            table.insert(viableServers, srv)
                        end
                    end

                    if #viableServers > 0 then
                        table.sort(viableServers, function(a, b)
                            return (a.ping or 999) < (b.ping or 999)
                        end)
                        targetJob = viableServers[math.random(1, math.min(3, #viableServers))].id
                        break
                    end

                    cursor = data.nextPageCursor or ""
                    if not cursor or cursor == "" then break end
                end
            end
            task.wait(1)
        end

        if targetJob then
            getgenv().VisitedServers[targetJob] = true
            notifyHop("Teleporting to optimal server: " .. string.sub(targetJob, 1, 8) .. "...")
            task.wait(0.5)
            pcall(function()
                TeleportService:TeleportToPlaceInstance(PlaceId, targetJob, LocalPlayer)
            end)
        else
            notifyHop("No alternate servers in range, hopping random instance...")
            pcall(function()
                TeleportService:Teleport(PlaceId, LocalPlayer)
            end)
        end
    end)
end

-- =========================================================================
-- Spot Claiming & Auto-Stand Mechanics
-- =========================================================================
local function findAvailableSpot()
    local candidates = {}
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local myPos = root and root.Position or Vector3.zero

    -- Search workspace for booths/spots/stands/wait areas
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            local action = obj.ActionText:lower()
            local objectText = obj.ObjectText:lower()
            if action:find("claim") or action:find("take") or action:find("wait") or action:find("stand") or objectText:find("spot") or objectText:find("stand") or objectText:find("booth") then
                local part = obj.Parent:IsA("BasePart") and obj.Parent or obj:FindFirstAncestorWhichIsA("BasePart")
                if part then
                    local dist = (part.Position - myPos).Magnitude
                    table.insert(candidates, { Part = part, Prompt = obj, Dist = dist })
                end
            end
        end
    end

    if #candidates > 0 then
        table.sort(candidates, function(a, b) return a.Dist < b.Dist end)
        return candidates[1]
    end

    return nil
end

local function claimSpot()
    local spot = findAvailableSpot()
    if not spot then return false end

    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return false end

    -- Move to spot
    root.CFrame = spot.Part.CFrame + Vector3.new(0, 3, 0)
    task.wait(0.2)

    -- Fire Prompt
    pcall(function()
        if fireproximityprompt then
            fireproximityprompt(spot.Prompt)
        else
            spot.Prompt:InputHoldBegin()
            task.wait(spot.Prompt.HoldDuration + 0.05)
            spot.Prompt:InputHoldEnd()
        end
    end)

    State.ClaimedSpot = spot.Part
    State.ClaimedCFrame = spot.Part.CFrame + Vector3.new(0, 3, 0)
    return true
end

-- Anti-push and auto-stand loop
task.spawn(function()
    while true do
        task.wait(1)
        if _G.PLSWAIT_SESSION ~= currentSession then break end

        if State.AutoClaimSpot and not State.ClaimedSpot then
            claimSpot()
        end

        if State.AutoStandAtSpot and State.ClaimedCFrame then
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root and (root.Position - State.ClaimedCFrame.Position).Magnitude > State.SpotDistanceCheck then
                if State.AntiPushLock then
                    root.CFrame = State.ClaimedCFrame
                    root.AssemblyLinearVelocity = Vector3.zero
                    root.AssemblyAngularVelocity = Vector3.zero
                end
            end
        end
    end
end)

-- =========================================================================
-- Social & Auto-Thanker
-- =========================================================================
local function sendChatMessage(msg)
    pcall(function()
        local textChatService = game:GetService("TextChatService")
        local chatInputBar = textChatService:FindFirstChild("TextChannels") and textChatService.TextChannels:FindFirstChild("RBXGeneral")
        if chatInputBar then
            chatInputBar:SendAsync(msg)
        else
            ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(msg, "All")
        end
    end)
end

-- Watch for donations to auto-thank
task.spawn(function()
    local leaderstats = LocalPlayer:WaitForChild("leaderstats", 10)
    local raisedStat = nil
    if leaderstats then
        for _, s in ipairs(leaderstats:GetChildren()) do
            local name = s.Name:lower()
            if name:find("rais") or name:find("earn") or name:find("point") then
                raisedStat = s
                Metrics.InitialRaised = tonumber(s.Value) or 0
                break
            end
        end
    end

    if raisedStat then
        raisedStat.Changed:Connect(function(newVal)
            local currentVal = tonumber(newVal) or 0
            local diff = currentVal - (Metrics.InitialRaised + Metrics.TotalRaisedThisSession)
            if diff > 0 then
                Metrics.TotalRaisedThisSession = Metrics.TotalRaisedThisSession + diff
                Metrics.DonationsCount = Metrics.DonationsCount + 1
                Metrics.LastDonationTick = tick()
                if diff > Metrics.LargestDonation then
                    Metrics.LargestDonation = diff
                end

                if State.AutoThank and #State.ThankMessages > 0 then
                    task.wait(State.ThankDelay)
                    local template = State.ThankMessages[math.random(1, #State.ThankMessages)]
                    local finalMsg = template:gsub("{donor}", "everyone"):gsub("{amount}", tostring(diff))
                    sendChatMessage(finalMsg)
                end
            end
        end)
    end
end)

-- Auto-Beggar / Status broadcast loop
task.spawn(function()
    while true do
        task.wait(State.BeggarInterval)
        if _G.PLSWAIT_SESSION ~= currentSession then break end
        if State.AutoBeggar and #State.BeggarMessages > 0 then
            local msg = State.BeggarMessages[math.random(1, #State.BeggarMessages)]
            sendChatMessage(msg)
        end
    end
end)

-- Inactivity & Whale Monitor Loop
task.spawn(function()
    while true do
        task.wait(15)
        if _G.PLSWAIT_SESSION ~= currentSession then break end

        -- Check Inactivity
        if State.AutoHopInactivity and not Metrics.IsHopping then
            local elapsedMins = (tick() - Metrics.LastDonationTick) / 60
            if elapsedMins >= State.InactivityMinutes then
                hopServer()
                break
            end
        end

        -- Check Whale Leaving
        if State.HopIfWhaleLeaves and State.WhaleHunter and not Metrics.IsHopping then
            local economy = scanServerEconomy()
            if economy.WhaleCount == 0 and (tick() - Metrics.JoinTick) > 60 then
                hopServer()
                break
            end
        end
    end
end)

-- Character movement modifications
RunService.Stepped:Connect(function()
    if _G.PLSWAIT_SESSION ~= currentSession then return end
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        if State.WalkSpeedEnabled then
            hum.WalkSpeed = State.CustomWalkSpeed
        end
        if State.JumpPowerEnabled then
            hum.JumpPower = State.CustomJumpPower
        end
    end
end)

-- =========================================================================
-- UnknownLibrary V2.2 UI Initialization
-- =========================================================================
local success, Library = pcall(function()
    return loadstring(game:HttpGet(LIBRARY_LINK))()
end)

if not success or not Library then
    warn("[Unknown Hub] Failed to load UnknownLibrary V2.2")
    return
end

local Window = Library:CreateWindow({
    Title = "Unknown Hub | PLS WAIT ⏳",
    AccentColor = Color3.fromRGB(0, 200, 255),
    Theme = "Dark"
})

-- -------------------------------------------------------------------------
-- Tab 1: Waiting & Spot Automation
-- -------------------------------------------------------------------------
local WaitTab = Window:CreateTab({ Name = "⏳ Waiting Spot" })

WaitTab:CreateSection({ Name = "Spot Claimer & Stay" })

WaitTab:CreateToggle({
    Name = "Auto Claim Spot",
    CurrentValue = State.AutoClaimSpot,
    Callback = function(v)
        State.AutoClaimSpot = v
        if v then claimSpot() end
    end
})

WaitTab:CreateToggle({
    Name = "Auto Stand / Sit At Spot",
    CurrentValue = State.AutoStandAtSpot,
    Callback = function(v)
        State.AutoStandAtSpot = v
    end
})

WaitTab:CreateToggle({
    Name = "Anti-Push Physics Lock",
    CurrentValue = State.AntiPushLock,
    Callback = function(v)
        State.AntiPushLock = v
    end
})

WaitTab:CreateButton({
    Name = "Force Claim Nearest Spot",
    Callback = function()
        local ok = claimSpot()
        if not ok then
            Library:Notify({ Title = "Spot Claim", Content = "No free spot found nearby!", Duration = 3 })
        else
            Library:Notify({ Title = "Spot Claim", Content = "Successfully claimed waiting spot!", Duration = 3 })
        end
    end
})

WaitTab:CreateSection({ Name = "Wait Time Tracker" })

local SessionTimeLabel = WaitTab:CreateLabel({ Text = "Time Waited: 00:00" })
local RaisedLabel = WaitTab:CreateLabel({ Text = "Session Raised: 0 R$" })
local DonationsLabel = WaitTab:CreateLabel({ Text = "Donations: 0" })

task.spawn(function()
    while true do
        task.wait(1)
        if _G.PLSWAIT_SESSION ~= currentSession then break end
        local elapsed = tick() - Metrics.JoinTick
        SessionTimeLabel:SetText("Time Waited: " .. formatDuration(elapsed))
        RaisedLabel:SetText("Session Raised: " .. tostring(Metrics.TotalRaisedThisSession) .. " R$")
        DonationsLabel:SetText("Donations: " .. tostring(Metrics.DonationsCount))
    end
end)

-- -------------------------------------------------------------------------
-- Tab 2: Whale Hunter & Server Hopper
-- -------------------------------------------------------------------------
local HopTab = Window:CreateTab({ Name = "🐋 Whale Hopper" })

HopTab:CreateSection({ Name = "Whale Detection & Intelligence" })

HopTab:CreateToggle({
    Name = "Whale Hunter Mode",
    CurrentValue = State.WhaleHunter,
    Callback = function(v) State.WhaleHunter = v end
})

HopTab:CreateSlider({
    Name = "Whale Threshold (R$)",
    Range = { 1000, 50000 },
    Increment = 1000,
    CurrentValue = State.WhaleThreshold,
    Callback = function(v) State.WhaleThreshold = v end
})

HopTab:CreateToggle({
    Name = "Hop If Whale Leaves",
    CurrentValue = State.HopIfWhaleLeaves,
    Callback = function(v) State.HopIfWhaleLeaves = v end
})

HopTab:CreateSection({ Name = "Inactivity Auto-Hopper" })

HopTab:CreateToggle({
    Name = "Auto-Hop On Inactivity",
    CurrentValue = State.AutoHopInactivity,
    Callback = function(v) State.AutoHopInactivity = v end
})

HopTab:CreateSlider({
    Name = "Inactivity Minutes",
    Range = { 3, 30 },
    Increment = 1,
    CurrentValue = State.InactivityMinutes,
    Callback = function(v) State.InactivityMinutes = v end
})

HopTab:CreateButton({
    Name = "Server Hop Now",
    Callback = function()
        hopServer()
    end
})

-- -------------------------------------------------------------------------
-- Tab 3: Social & Auto-Gratitude
-- -------------------------------------------------------------------------
local SocialTab = Window:CreateTab({ Name = "💬 Social & Thanks" })

SocialTab:CreateSection({ Name = "Auto-Thanker" })

SocialTab:CreateToggle({
    Name = "Auto Thank Donors",
    CurrentValue = State.AutoThank,
    Callback = function(v) State.AutoThank = v end
})

SocialTab:CreateSlider({
    Name = "Thank Delay (Seconds)",
    Range = { 0.5, 5 },
    Increment = 0.5,
    CurrentValue = State.ThankDelay,
    Callback = function(v) State.ThankDelay = v end
})

SocialTab:CreateSection({ Name = "Auto-Announcer" })

SocialTab:CreateToggle({
    Name = "Auto Chat Announcer",
    CurrentValue = State.AutoBeggar,
    Callback = function(v) State.AutoBeggar = v end
})

SocialTab:CreateSlider({
    Name = "Announce Interval (Seconds)",
    Range = { 30, 300 },
    Increment = 10,
    CurrentValue = State.BeggarInterval,
    Callback = function(v) State.BeggarInterval = v end
})

-- -------------------------------------------------------------------------
-- Tab 4: Character & Safeguards
-- -------------------------------------------------------------------------
local MiscTab = Window:CreateTab({ Name = "⚙️ Safeguards" })

MiscTab:CreateSection({ Name = "24/7 Stability" })

MiscTab:CreateToggle({
    Name = "Anti-AFK Protection",
    CurrentValue = State.AntiAFK,
    Callback = function(v) State.AntiAFK = v end
})

MiscTab:CreateToggle({
    Name = "Auto Reconnect On Error",
    CurrentValue = State.AutoReconnect,
    Callback = function(v) State.AutoReconnect = v end
})

MiscTab:CreateSection({ Name = "Movement Tweaks" })

MiscTab:CreateToggle({
    Name = "Enable WalkSpeed",
    CurrentValue = State.WalkSpeedEnabled,
    Callback = function(v)
        State.WalkSpeedEnabled = v
        if not v then
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = 16 end
        end
    end
})

MiscTab:CreateSlider({
    Name = "Custom WalkSpeed",
    Range = { 16, 100 },
    Increment = 2,
    CurrentValue = State.CustomWalkSpeed,
    Callback = function(v) State.CustomWalkSpeed = v end
})

MiscTab:CreateToggle({
    Name = "Enable JumpPower",
    CurrentValue = State.JumpPowerEnabled,
    Callback = function(v)
        State.JumpPowerEnabled = v
        if not v then
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then hum.JumpPower = 50 end
        end
    end
})

MiscTab:CreateSlider({
    Name = "Custom JumpPower",
    Range = { 50, 200 },
    Increment = 5,
    CurrentValue = State.CustomJumpPower,
    Callback = function(v) State.CustomJumpPower = v end
})

Library:Notify({
    Title = "Unknown Hub",
    Content = "PLS WAIT Automation Suite Loaded!",
    Duration = 5
})
