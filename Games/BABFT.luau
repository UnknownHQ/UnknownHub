-- =========================================================================
-- UNKNOWN HUB — BUILD A BOAT FOR TREASURE (BABFT.luau)
-- High-Performance Gold Auto-Farm, Stage Bypass & Overnight AFK Engine
-- PlaceId: 537413528 | Universal UnknownLibrary V2.2
-- =========================================================================

local LIBRARY_LINK = "https://raw.githubusercontent.com/UnknownHQ/UnknownHub/main/UnknownLibrary"
local LIBRARY_NAME = "Unknown_BABFT_Hub_UI"

local currentSession = tick()
_G.BABFT_SESSION = currentSession

-- =========================================================================
-- Core Roblox Services
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

-- =========================================================================
-- Anti-AFK Safeguard (Prevents 20-minute idle kicks while AFK)
-- =========================================================================
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

-- =========================================================================
-- UI Cleanup Handler
-- =========================================================================
local function destroyOldGui()
    local parents = {game:GetService("CoreGui")}
    if gethui then pcall(function() table.insert(parents, gethui()) end) end
    local playerGui = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
    if playerGui then table.insert(parents, playerGui) end
    for _, parent in ipairs(parents) do
        if parent then
            pcall(function()
                for _, child in ipairs(parent:GetChildren()) do
                    if child:IsA("ScreenGui") and (child.Name == LIBRARY_NAME or child.Name == "Unknown_MainGui") then
                        pcall(function() child:Destroy() end)
                    end
                end
            end)
        end
    end
end

-- =========================================================================
-- Load UI Library
-- =========================================================================
local ok, factory = pcall(function()
    local source = ""
    if isfile and isfile("UnknownLibrary.luau") then
        source = readfile("UnknownLibrary.luau")
    elseif isfile and isfile("UnknownLibrary") then
        source = readfile("UnknownLibrary")
    else
        source = game:HttpGet(LIBRARY_LINK)
    end
    pcall(function()
        source = source:gsub("game:GetService%([\"']CoreGui[\"']%)", "(gethui and gethui() or (game:GetService(\"Players\").LocalPlayer and game:GetService(\"Players\").LocalPlayer:WaitForChild(\"PlayerGui\")))")
    end)
    local factoryChunk = loadstring(source)
    return factoryChunk()
end)

if not ok or not factory then
    warn("[Unknown Hub] Failed to load library factory: " .. tostring(factory))
    return
end

destroyOldGui()

-- =========================================================================
-- Character Helpers
-- =========================================================================
local function getChar()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

local function getRoot()
    local char = getChar()
    return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso"))
end

local function getHumanoid()
    local char = getChar()
    return char and char:FindFirstChildOfClass("Humanoid")
end

local stopAutoFarmCleanly

-- =========================================================================
-- Script State Configuration
-- =========================================================================
local State = {
    -- Auto Farm
    AutoFarm_Enabled = false,
    Farm_StageDelay = 1.25,      -- Accelerated 1.25s per stage (12.5s river run) for max gold throughput without rollbacks
    Farm_FlightHeight = 0,       -- Safe river trigger height (Y = 0) is 13 studs above water, avoiding all water/log damage
    Farm_AutoLaunch = true,      -- Automatically triggers team dock launch
    Farm_AutoClaim = true,       -- Automatically fires ClaimRiverResultsGold:FireServer()
    Farm_ClosePopups = true,     -- Closes RiverResultsGui automatically

    -- Stats
    TotalRuns = 0,
    CurrentStatus = "Idle",

    -- Character
    WalkSpeed_Enabled = false,
    WalkSpeed_Value = 16,
    JumpPower_Enabled = false,
    JumpPower_Value = 50,
    Infinite_Jump = false,
    Noclip = false,
    Water_Godmode = true,

    -- Auto Buy
    AutoBuy_Enabled = false,
    AutoBuy_Chest = "Common Chest" -- "Common Chest", "Uncommon Chest", "Rare Chest", "Epic Chest", "Legendary Chest"
}

-- =========================================================================
-- Initialize Unknown Hub Interface
-- =========================================================================
local Hub = factory({
    name = LIBRARY_NAME,
    title = "UNKNOWN HUB",
    subTitle = "Build A Boat For Treasure",
    theme = Color3.fromRGB(245, 142, 32),          -- Vibrant Gold / Amber
    secondaryTheme = Color3.fromRGB(0, 195, 245), -- Cyber Cyan
    onClose = function()
        if stopAutoFarmCleanly then stopAutoFarmCleanly() end
        _G.BABFT_SESSION = nil
        print("[Unknown Hub] BABFT Session closed.")
    end
})

-- =========================================================================
-- TAB 1: AUTO FARM (Master AFK Engine)
-- =========================================================================
local farmTab = Hub.CreateTab("Auto Farm", {
    Icon = "⛵",
    Size = 18,
    Color = Color3.fromRGB(170, 185, 210),
    ActiveColor = Color3.fromRGB(245, 142, 32)
})

Hub.CreateSection(farmTab, "STATUS & PERFORMANCE")

local statusSection = Hub.CreateSection(farmTab, "STATUS: IDLE | RUNS: 0")

local function updateStatus(text)
    State.CurrentStatus = text
    pcall(function()
        local lbl = statusSection:FindFirstChild("Title")
        if lbl then
            lbl.Text = string.upper(string.format("STATUS: %s | RUNS: %d", text, State.TotalRuns))
        end
    end)
end

local function updateRuns()
    State.TotalRuns = State.TotalRuns + 1
    pcall(function()
        local lbl = statusSection:FindFirstChild("Title")
        if lbl then
            lbl.Text = string.upper(string.format("STATUS: %s | RUNS: %d", State.CurrentStatus, State.TotalRuns))
        end
    end)
end

-- Comprehensive Farm Shutdown & Anti-Levitation Routine
local function stopAutoFarmCleanly()
    State.AutoFarm_Enabled = false
    updateStatus("Idle")

    local char = LocalPlayer.Character
    local root = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))

    if root then
        -- 1. Purge all BodyVelocity and physics constraints holding character in air
        for _, child in ipairs(root:GetChildren()) do
            if child.Name == "FarmBV" or child:IsA("BodyVelocity") or child:IsA("BodyGyro") or child:IsA("BodyPosition") then
                pcall(function() child:Destroy() end)
            end
        end
        -- 2. Clear lingering velocities and unanchor
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        root.Anchored = false
    end

    -- 3. Restore collision on all character parts
    if char then
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then
                p.CanCollide = true
            end
        end
    end

    -- 4. Safely reposition character onto dock spawn so they are grounded at dock
    pcall(function()
        local team = LocalPlayer.Team
        local teamName = team and team.TeamColor.Name
        local spawnsFolder = Workspace.Teams:FindFirstChild(teamName .. "Team") and Workspace.Teams[teamName .. "Team"]:FindFirstChild("Spawns")
        local spawnPart = spawnsFolder and spawnsFolder:FindFirstChildOfClass("SpawnLocation")
        if spawnPart and root and root.Parent then
            root.CFrame = spawnPart.CFrame + Vector3.new(0, 3, 0)
        end
    end)
    Hub.Notify({ Title = "Auto Farm", Content = "Auto-Farm Stopped. Returned safely to dock.", Duration = 2 })
end

Hub.CreateSection(farmTab, "GOLD AUTO-FARM CONFIG")

-- Safe Boat Launcher Helper
local function triggerLaunchBoat()
    pcall(function()
        local lb = LocalPlayer.PlayerGui:FindFirstChild("LaunchBoatGui")
        if lb then
            if lb.LaunchFrame and lb.LaunchFrame.Visible then
                local btn = lb.LaunchFrame:FindFirstChild("LaunchBoat")
                if btn and getconnections then
                    for _, c in ipairs(getconnections(btn.MouseButton1Click)) do c:Fire() end
                end
            end
            task.wait(0.25)
            if lb.PromptLaunch and lb.PromptLaunch.Visible then
                local yesBtn = lb.PromptLaunch:FindFirstChild("Yes")
                if yesBtn and getconnections then
                    for _, c in ipairs(getconnections(yesBtn.MouseButton1Click)) do c:Fire() end
                end
            end
        end
    end)
end

-- Close Results Popups Helper
local function dismissResultsPopup()
    pcall(function()
        local rr = LocalPlayer.PlayerGui:FindFirstChild("RiverResultsGui")
        if rr and rr:FindFirstChild("Frame") then
            local exitBtn = rr.Frame:FindFirstChild("ExitButton")
            if exitBtn and getconnections then
                for _, c in ipairs(getconnections(exitBtn.MouseButton1Click)) do c:Fire() end
            end
        end
    end)
end

-- Tween Helper for Character
local function tweenCharacter(root, targetCFrame, duration)
    if not root or not root.Parent then return false end
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    
    local tw = TweenService:Create(root, TweenInfo.new(duration, Enum.EasingStyle.Linear), { CFrame = targetCFrame })
    tw:Play()
    tw.Completed:Wait()

    if root and root.Parent then
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end
    return true
end

-- =========================================================================
-- Master Auto Farm Thread
-- =========================================================================
task.spawn(function()
    while true do
        task.wait(0.1)
        if _G.BABFT_SESSION ~= currentSession then break end

        if State.AutoFarm_Enabled then
            local char = getChar()
            local root = getRoot()
            local hum = getHumanoid()

            if char and root and hum and hum.Health > 0 then
                -- 1. Part Collision & Damage Shield
                pcall(function()
                    for _, p in ipairs(char:GetDescendants()) do
                        if p:IsA("BasePart") then p.CanCollide = false end
                    end
                end)

                -- 2. Launch Boat
                if State.Farm_AutoLaunch then
                    updateStatus("Launching Boat...")
                    triggerLaunchBoat()
                    task.wait(0.8)
                end

                if not State.AutoFarm_Enabled then continue end

                -- 3. Discover Stages & Corridor Waypoints (Both Cave Arches and Stage Interiors)
                local boatStages = Workspace:FindFirstChild("BoatStages")
                local normalStages = boatStages and boatStages:FindFirstChild("NormalStages")
                local otherStages = boatStages and boatStages:FindFirstChild("OtherStages")

                if normalStages then
                    local waypoints = {}
                    
                    -- A. Cave Archways (DarknessPart boundaries)
                    for _, ch in ipairs(normalStages:GetChildren()) do
                        local dp = ch:FindFirstChild("DarknessPart")
                        if dp then
                            table.insert(waypoints, { name = ch.Name, z = dp.Position.Z, part = dp, isCave = true })
                        end
                    end
                    
                    -- B. Stage Interiors (Ensures every single stage area is registered in OtherData)
                    if otherStages then
                        for _, stg in ipairs(otherStages:GetChildren()) do
                            local fp = stg:FindFirstChildWhichIsA("BasePart", true)
                            if fp then
                                table.insert(waypoints, { name = stg.Name, z = fp.Position.Z, part = fp, isCave = false })
                            end
                        end
                    end

                    -- Chronological river sequence from dock to TheEnd
                    table.sort(waypoints, function(a, b) return a.z < b.z end)

                    -- 4. Align with River Water Trigger Corridor (Y = 0)
                    updateStatus("Aligning River Corridor...")
                    root.Anchored = true
                    local safeY = State.Farm_FlightHeight or 0

                    -- Attach persistent Anti-Drop BodyVelocity so character never falls during pulses
                    local bv = root:FindFirstChild("FarmBV") or Instance.new("BodyVelocity")
                    bv.Name = "FarmBV"
                    bv.Velocity = Vector3.zero
                    bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
                    bv.Parent = root

                    tweenCharacter(root, CFrame.new(-51.5, safeY, root.Position.Z), 0.5)

                    -- 5. Traverse Each Waypoint (Guarantees 100% of areas are registered)
                    local abort = false
                    local wpDuration = math.clamp((State.Farm_StageDelay or 1.25) * 0.55, 0.5, 1.2)

                    for i, wp in ipairs(waypoints) do
                        if not State.AutoFarm_Enabled or _G.BABFT_SESSION ~= currentSession or hum.Health <= 0 then
                            abort = true
                            break
                        end

                        updateStatus(string.format("Clearing: Area %d/%d (%s)", i, #waypoints, wp.name))
                        local targetPos = Vector3.new(-51.5, safeY, wp.z)
                        tweenCharacter(root, CFrame.new(targetPos), wpDuration)
                        
                        -- Unanchored dwell pulse with BodyVelocity holding safe height
                        root.Anchored = false
                        if wp.isCave and wp.part then
                            pcall(function()
                                firetouchinterest(root, wp.part, 0)
                                task.wait(0.05)
                                firetouchinterest(root, wp.part, 1)
                            end)
                        else
                            task.wait(0.08)
                        end
                        root.Anchored = true
                    end

                    if abort then
                        root.Anchored = false
                        continue
                    end

                    -- 6. Claim The End & Golden Chest
                    local theEnd = normalStages:FindFirstChild("TheEnd")
                    local chest = theEnd and theEnd:FindFirstChild("GoldenChest")
                    local trigger = chest and chest:FindFirstChild("Trigger")

                    if trigger then
                        updateStatus("Opening Golden Chest & Collecting Prizes...")
                        -- Direct CFrame right onto chest (Bypasses lethal waterfall pointed rocks)
                        root.CFrame = CFrame.new(trigger.Position + Vector3.new(0, 1.5, 0))
                        root.AssemblyLinearVelocity = Vector3.zero
                        root.AssemblyAngularVelocity = Vector3.zero

                        -- 1. Physically swing open the chest cap on HingeConstraint so lid opens visually
                        pcall(function()
                            local cap = chest:FindFirstChild("Cap")
                            if cap then
                                for _, hinge in ipairs(cap:GetDescendants()) do
                                    if hinge:IsA("HingeConstraint") then
                                        hinge.TargetAngle = -105
                                    end
                                end
                            end
                        end)

                        -- 2. Touch trigger interest to initiate server chest opening sequence
                        pcall(function()
                            firetouchinterest(root, trigger, 0)
                            task.wait(0.15)
                            firetouchinterest(root, trigger, 1)
                        end)

                        -- 3. Ensure the client chest cutscene/effects play cleanly
                        pcall(function()
                            local effectsScript = trigger:FindFirstChild("EndTreasureScript") and trigger.EndTreasureScript:FindFirstChild("TreasureEndEffectsLS")
                            if effectsScript and not LocalPlayer.PlayerGui:FindFirstChild("TreasureEndEffectsLS") then
                                local cl = effectsScript:Clone()
                                cl.Parent = LocalPlayer.PlayerGui
                            end
                        end)

                        -- 4. Fire server claim remote
                        if State.Farm_AutoClaim then
                            pcall(function()
                                local claimRemote = Workspace:FindFirstChild("ClaimRiverResultsGold")
                                if claimRemote then
                                    claimRemote:FireServer()
                                end
                            end)
                        end

                        -- 5. Allow chest animation to open and dispense prizes (3.2s collection window)
                        local prizeCollectionTime = 3.2
                        local startWait = tick()
                        while tick() - startWait < prizeCollectionTime do
                            task.wait(0.2)
                            if not State.AutoFarm_Enabled or _G.BABFT_SESSION ~= currentSession then break end
                            -- Fast collect any spawned prizes directly into root
                            pcall(function()
                                local tempPrizes = chest:FindFirstChild("DisplayPrizesTemp")
                                if tempPrizes then
                                    for _, prize in ipairs(tempPrizes:GetChildren()) do
                                        if prize:IsA("BasePart") then
                                            prize.CFrame = root.CFrame
                                        elseif prize:IsA("Model") and prize.PrimaryPart then
                                            prize:SetPrimaryPartCFrame(root.CFrame)
                                        end
                                    end
                                end
                            end)
                        end

                        updateRuns()
                        updateStatus("Reward Claimed! Returning to Dock...")

                        -- Close popup
                        if State.Farm_ClosePopups then
                            task.wait(0.2)
                            dismissResultsPopup()
                        end

                        -- 6. Reset Chest Lid for next round
                        pcall(function()
                            local cap = chest:FindFirstChild("Cap")
                            if cap then
                                for _, hinge in ipairs(cap:GetDescendants()) do
                                    if hinge:IsA("HingeConstraint") then
                                        hinge.TargetAngle = 0
                                    end
                                end
                            end
                        end)

                        -- Smooth Dock Return (Zero Death, 100 Health Preserved)
                        if hum and hum.Health > 0 then
                            pcall(function()
                                local team = LocalPlayer.Team
                                local teamName = team and team.TeamColor.Name
                                local spawnsFolder = Workspace.Teams:FindFirstChild(teamName .. "Team") and Workspace.Teams[teamName .. "Team"]:FindFirstChild("Spawns")
                                local spawnPart = spawnsFolder and spawnsFolder:FindFirstChildOfClass("SpawnLocation")
                                if spawnPart and root and root.Parent then
                                    root.CFrame = spawnPart.CFrame + Vector3.new(0, 3, 0)
                                    root.AssemblyLinearVelocity = Vector3.zero
                                    root.AssemblyAngularVelocity = Vector3.zero
                                end
                            end)
                            root.Anchored = false
                            task.wait(0.6)
                        else
                            LocalPlayer.CharacterAdded:Wait()
                            task.wait(1.0)
                        end
                        updateStatus("Ready for next run!")
                    else
                        root.Anchored = false
                        task.wait(1.0)
                    end
                else
                    updateStatus("Waiting for BoatStages...")
                    task.wait(1.0)
                end
            else
                task.wait(0.5)
            end
        end
    end
end)

Hub.CreateToggle(farmTab, "Enable Gold Auto-Farm", State.AutoFarm_Enabled, function(v)
    if v then
        State.AutoFarm_Enabled = true
        Hub.Notify({ Title = "Auto Farm", Content = "Gold Auto-Farm Started! Bypassing stage filters...", Duration = 3 })
    else
        stopAutoFarmCleanly()
    end
end)

Hub.CreateButton(farmTab, "Emergency Unstuck (Clear Levitation & Return to Dock)", function()
    stopAutoFarmCleanly()
end)

Hub.CreateSlider(farmTab, "Stage Glide Duration (Seconds)", 0.8, 3.0, State.Farm_StageDelay, function(val)
    State.Farm_StageDelay = val
end)

Hub.CreateSlider(farmTab, "River Glide Height (Y)", -10, 30, State.Farm_FlightHeight, function(val)
    State.Farm_FlightHeight = val
end)

Hub.CreateToggle(farmTab, "Auto-Launch Boat", State.Farm_AutoLaunch, function(v)
    State.Farm_AutoLaunch = v
end)

Hub.CreateToggle(farmTab, "Auto-Claim Gold Remote", State.Farm_AutoClaim, function(v)
    State.Farm_AutoClaim = v
end)

Hub.CreateToggle(farmTab, "Auto-Dismiss Results Popup", State.Farm_ClosePopups, function(v)
    State.Farm_ClosePopups = v
end)

-- =========================================================================
-- TAB 2: SHOP & AUTO-BUY
-- =========================================================================
local shopTab = Hub.CreateTab("Shop & Chests", {
    Icon = "🎁",
    Size = 18,
    Color = Color3.fromRGB(170, 185, 210),
    ActiveColor = Color3.fromRGB(0, 215, 255)
})

Hub.CreateSection(shopTab, "CHEST AUTOMATION")

local CHEST_OPTIONS = {
    "Common Chest",
    "Uncommon Chest",
    "Rare Chest",
    "Epic Chest",
    "Legendary Chest"
}

Hub.CreateDropdown(shopTab, "Target Chest to Buy", CHEST_OPTIONS, State.AutoBuy_Chest, function(selected)
    State.AutoBuy_Chest = selected
end)

local function buyChest(chestName)
    pcall(function()
        local rf = Workspace:FindFirstChild("ItemBoughtFromShop")
        if rf and rf:IsA("RemoteFunction") then
            rf:InvokeServer(chestName, 1)
        end
    end)
end

Hub.CreateToggle(shopTab, "Auto-Buy Selected Chest", State.AutoBuy_Enabled, function(v)
    State.AutoBuy_Enabled = v
end)

Hub.CreateButton(shopTab, "Buy 1x Selected Chest Now", function()
    buyChest(State.AutoBuy_Chest)
    Hub.Notify({ Title = "Shop", Content = "Purchased 1x " .. State.AutoBuy_Chest, Duration = 2 })
end)

Hub.CreateButton(shopTab, "Buy 5x Selected Chests Now", function()
    task.spawn(function()
        for i = 1, 5 do
            buyChest(State.AutoBuy_Chest)
            task.wait(0.2)
        end
        Hub.Notify({ Title = "Shop", Content = "Purchased 5x " .. State.AutoBuy_Chest, Duration = 2 })
    end)
end)

-- Auto-Buy background worker
task.spawn(function()
    while true do
        task.wait(2.5)
        if _G.BABFT_SESSION ~= currentSession then break end
        if State.AutoBuy_Enabled then
            buyChest(State.AutoBuy_Chest)
        end
    end
end)

-- =========================================================================
-- TAB 3: CHARACTER & MOVEMENT
-- =========================================================================
local charTab = Hub.CreateTab("Character", {
    Icon = "🏃",
    Size = 18,
    Color = Color3.fromRGB(170, 185, 210),
    ActiveColor = Color3.fromRGB(50, 220, 120)
})

Hub.CreateSection(charTab, "SPEED & JUMP MODIFIERS")

Hub.CreateToggle(charTab, "Custom WalkSpeed", State.WalkSpeed_Enabled, function(v)
    State.WalkSpeed_Enabled = v
    local hum = getHumanoid()
    if hum then hum.WalkSpeed = v and State.WalkSpeed_Value or 16 end
end)

Hub.CreateSlider(charTab, "WalkSpeed Value", 16, 150, State.WalkSpeed_Value, function(v)
    State.WalkSpeed_Value = v
    if State.WalkSpeed_Enabled then
        local hum = getHumanoid()
        if hum then hum.WalkSpeed = v end
    end
end)

Hub.CreateToggle(charTab, "Custom JumpPower", State.JumpPower_Enabled, function(v)
    State.JumpPower_Enabled = v
    local hum = getHumanoid()
    if hum then
        hum.UseJumpPower = true
        hum.JumpPower = v and State.JumpPower_Value or 50
    end
end)

Hub.CreateSlider(charTab, "JumpPower Value", 50, 250, State.JumpPower_Value, function(v)
    State.JumpPower_Value = v
    if State.JumpPower_Enabled then
        local hum = getHumanoid()
        if hum then hum.JumpPower = v end
    end
end)

Hub.CreateToggle(charTab, "Infinite Jump", State.Infinite_Jump, function(v)
    State.Infinite_Jump = v
end)

UserInputService.JumpRequest:Connect(function()
    if State.Infinite_Jump then
        local hum = getHumanoid()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

Hub.CreateSection(charTab, "IMMUNITY & COLLISION")

Hub.CreateToggle(charTab, "Noclip (Walk Through Walls)", State.Noclip, function(v)
    State.Noclip = v
end)

RunService.Stepped:Connect(function()
    if State.Noclip or State.AutoFarm_Enabled then
        local char = LocalPlayer.Character
        if char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end
    end
end)

Hub.CreateToggle(charTab, "Water & Obstacle Godmode", State.Water_Godmode, function(v)
    State.Water_Godmode = v
end)

RunService.Heartbeat:Connect(function()
    if State.Water_Godmode or State.AutoFarm_Enabled then
        local hum = getHumanoid()
        if hum and hum.Health > 0 and hum.Health < 100 then
            hum.Health = 100
        end
    end
end)

-- =========================================================================
-- TAB 4: TELEPORTS & UTILITIES
-- =========================================================================
local utilTab = Hub.CreateTab("Teleports", {
    Icon = "🌐",
    Size = 18,
    Color = Color3.fromRGB(170, 185, 210),
    ActiveColor = Color3.fromRGB(140, 120, 255)
})

Hub.CreateSection(utilTab, "FAST DESTINATIONS")

Hub.CreateButton(utilTab, "Teleport to Golden Chest (The End)", function()
    local root = getRoot()
    if root then
        root.CFrame = CFrame.new(-55.7, -355, 9492.3)
        Hub.Notify({ Title = "Teleport", Content = "Teleported to Golden Chest!", Duration = 2 })
    end
end)

Hub.CreateButton(utilTab, "Teleport to Spawn / Building Docks", function()
    local root = getRoot()
    if root then
        root.CFrame = CFrame.new(-50, 5, -20)
        Hub.Notify({ Title = "Teleport", Content = "Returned to Spawn Docks!", Duration = 2 })
    end
end)

Hub.CreateSection(utilTab, "AFK & PERFORMANCE OPTIMIZATIONS")

Hub.CreateToggle(utilTab, "Black Screen (Overnight GPU Saver)", false, function(enabled)
    Hub.SetBlackScreen(enabled)
end)

Hub.CreateButton(utilTab, "Rejoin Current Server", function()
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
end)

Hub.CreateButton(utilTab, "Server Hop", function()
    local servers = {}
    local req = request or http_request or (syn and syn.request)
    if req then
        local res = req({
            Url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100", game.PlaceId)
        })
        if res and res.Body then
            local data = HttpService:JSONDecode(res.Body)
            if data and data.data then
                for _, s in ipairs(data.data) do
                    if s.playing and s.maxPlayers and s.playing < s.maxPlayers and s.id ~= game.JobId then
                        table.insert(servers, s.id)
                    end
                end
            end
        end
    end
    if #servers > 0 then
        TeleportService:TeleportToPlaceInstance(game.PlaceId, servers[math.random(1, #servers)], LocalPlayer)
    else
        Hub.Notify({ Title = "Server Hop", Content = "No alternate public servers found.", Duration = 2 })
    end
end)

-- =========================================================================
-- Startup Notification
-- =========================================================================
Hub.Notify({
    Title = "Unknown Hub",
    Content = "BABFT Auto-Farm Engine Loaded! Toggle 'Enable Gold Auto-Farm' to start.",
    Duration = 4
})
