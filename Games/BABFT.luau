-- =========================================================================
-- UNKNOWN HUB — BUILD A BOAT FOR TREASURE (BABFT.luau)
-- High-Performance Gold Auto-Farm, Build Stealer, Secret Teleports & OP Exploits
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
    local parents = {}
    local playerGui = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
    if playerGui then table.insert(parents, playerGui) end
    if gethui then pcall(function() table.insert(parents, gethui()) end) end
    pcall(function() table.insert(parents, game:GetService("CoreGui")) end)

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
    -- CoreGui handled via factory parent
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
-- Script State Configuration (AUTO FARM STARTS ENABLED)
-- =========================================================================
local State = {
    -- Auto Farm
    AutoFarm_Enabled = true,        -- Starts ENABLED so daddy can sleep right away!
    Farm_StageDelay = 1.15,         -- 1.15s per stage for maximum gold throughput
    Farm_FlightHeight = 2.5,        -- Snug in-volume glide through DarknessPart
    Farm_AutoLaunch = true,         -- Auto triggers team dock launch
    Farm_AutoClaim = true,          -- Fires ClaimRiverResultsGold on every stage!
    Farm_InstantStageMoney = true,  -- Instant Stage Money Core
    Farm_ClosePopups = true,        -- Closes RiverResultsGui automatically

    -- Stats
    TotalRuns = 0,
    CurrentStatus = "Active",

    -- Build Stealer
    SelectedTargetPlayer = nil,
    SelectedSavedBuild = nil,
    SelectedGameSaveSlot = 1,

    -- OP Functions & Exploits
    Water_Godmode = true,
    Obstacle_Annihilator = true,
    Noclip_Fly = false,
    Fly_Speed = 75,

    -- Character
    WalkSpeed_Enabled = false,
    WalkSpeed_Value = 16,
    JumpPower_Enabled = false,
    JumpPower_Value = 50,
    Infinite_Jump = false,
    Noclip = false,

    -- Auto Buy
    AutoBuy_Enabled = false,
    AutoBuy_Chest = "Common Chest"
}

-- In-memory saved builds repository
local SavedBuilds = {}

-- =========================================================================
-- Initialize Unknown Hub Interface
-- =========================================================================
local Hub = factory({
    name = LIBRARY_NAME,
    title = "UNKNOWN HUB",
    subTitle = "Build A Boat For Treasure",
    parent = (LocalPlayer and (LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui"))) or (gethui and gethui()),
    theme = Color3.fromRGB(245, 142, 32),          -- Vibrant Gold / Amber
    secondaryTheme = Color3.fromRGB(0, 195, 245), -- Cyber Cyan
    onClose = function()
        if stopAutoFarmCleanly then stopAutoFarmCleanly() end
        _G.BABFT_SESSION = nil
        print("[Unknown Hub] BABFT Session closed.")
    end
})

-- =========================================================================
-- TAB 1: AUTO FARM (Master AFK & Instant River Engine)
-- =========================================================================
local farmTab = Hub.CreateTab("Auto Farm", {
    Icon = "⛵",
    Size = 18,
    Color = Color3.fromRGB(170, 185, 210),
    ActiveColor = Color3.fromRGB(245, 142, 32)
})

Hub.CreateSection(farmTab, "STATUS & PERFORMANCE")

local statusSection = Hub.CreateSection(farmTab, "STATUS: ACTIVE | RUNS: 0 | GOLD: +0")

local initialGold = (LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("Gold") and LocalPlayer.Data.Gold.Value) or 0

local function updateStatus(text)
    State.CurrentStatus = text
    pcall(function()
        local lbl = statusSection:FindFirstChild("Title")
        if lbl then
            local currGold = (LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("Gold") and LocalPlayer.Data.Gold.Value) or initialGold
            local earned = math.max(0, currGold - initialGold)
            lbl.Text = string.upper(string.format("STATUS: %s | RUNS: %d | GOLD: +%d", text, State.TotalRuns, earned))
        end
    end)
end

local function updateRuns()
    State.TotalRuns = State.TotalRuns + 1
    pcall(function()
        local lbl = statusSection:FindFirstChild("Title")
        if lbl then
            local currGold = (LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("Gold") and LocalPlayer.Data.Gold.Value) or initialGold
            local earned = math.max(0, currGold - initialGold)
            lbl.Text = string.upper(string.format("STATUS: %s | RUNS: %d | GOLD: +%d", State.CurrentStatus, State.TotalRuns, earned))
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
        for _, child in ipairs(root:GetChildren()) do
            if child.Name == "FarmBV" or child:IsA("BodyVelocity") or child:IsA("BodyGyro") or child:IsA("BodyPosition") then
                pcall(function() child:Destroy() end)
            end
        end
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        root.Anchored = false
    end

    if char then
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then
                p.CanCollide = true
            end
        end
    end

    pcall(function()
        local team = LocalPlayer.Team
        local teamName = team and team.TeamColor.Name
        local teamZone = teamName and Workspace:FindFirstChild(teamName .. "Zone")
        if teamZone and root and root.Parent then
            root.CFrame = teamZone.CFrame + Vector3.new(0, 5, 0)
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
            task.wait(0.15)
            if lb.PromptLaunch and lb.PromptLaunch.Visible then
                local yesBtn = lb.PromptLaunch:FindFirstChild("Yes")
                if yesBtn and getconnections then
                    for _, c in ipairs(getconnections(yesBtn.MouseButton1Click)) do c:Fire() end
                end
            end
        end
        local team = LocalPlayer.Team
        local teamName = team and team.TeamColor.Name
        local teamZone = teamName and Workspace:FindFirstChild(teamName .. "Zone")
        local voteLaunch = teamZone and teamZone:FindFirstChild("VoteLaunchRE")
        if voteLaunch then
            voteLaunch:FireServer()
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
-- Master Auto Farm Thread (With Instant Stage Money Core)
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

                -- 2. Launch Boat and synchronize round start
                if State.Farm_AutoLaunch then
                    updateStatus("Launching Boat...")
                    triggerLaunchBoat()
                    local team = LocalPlayer.Team
                    local teamName = team and team.TeamColor.Name
                    local teamZone = teamName and Workspace:FindFirstChild(teamName .. "Zone")
                    local launchedObj = teamZone and teamZone:FindFirstChild("Launched")
                    local tLaunch = tick()
                    while launchedObj and not launchedObj.Value and (tick() - tLaunch < 1.0) do
                        task.wait(0.1)
                    end
                    task.wait(0.2)
                end

                if not State.AutoFarm_Enabled then continue end

                -- 3. Discover Sequential Cave Stages (CaveStage1 through CaveStage10)
                local boatStages = Workspace:FindFirstChild("BoatStages")
                local normalStages = boatStages and boatStages:FindFirstChild("NormalStages")

                if normalStages then
                    local stageWaypoints = {}
                    for stageIdx = 1, 10 do
                        local stage = normalStages:FindFirstChild("CaveStage" .. stageIdx)
                        if stage then
                            local dp = stage:FindFirstChild("DarknessPart")
                            if dp then
                                table.insert(stageWaypoints, {
                                    index = stageIdx,
                                    name = stage.Name,
                                    part = dp,
                                    cframe = dp.CFrame
                                })
                            end
                        end
                    end

                    local bv = root:FindFirstChild("FarmBV") or Instance.new("BodyVelocity")
                    bv.Name = "FarmBV"
                    bv.Velocity = Vector3.zero
                    bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
                    bv.Parent = root

                    -- 4. Traverse Each Stage Sequentially
                    local abort = false
                    local stageDelay = State.Farm_StageDelay or 1.15
                    local glideTime = math.clamp(stageDelay * 0.45, 0.35, 0.75)
                    local dwellTime = math.clamp(stageDelay * 0.55, 0.4, 0.9)

                    for _, wp in ipairs(stageWaypoints) do
                        if not State.AutoFarm_Enabled or _G.BABFT_SESSION ~= currentSession or hum.Health <= 0 then
                            abort = true
                            break
                        end

                        updateStatus(string.format("Clearing Stage %d/10 (%s)...", wp.index, wp.name))
                        
                        -- Direct physical CFrame glide directly through the center of DarknessPart
                        root.Anchored = false
                        tweenCharacter(root, wp.cframe, glideTime)

                        -- Physical touch handshake with zero velocity dwell
                        root.AssemblyLinearVelocity = Vector3.zero
                        root.AssemblyAngularVelocity = Vector3.zero
                        pcall(function()
                            firetouchinterest(root, wp.part, 0)
                            task.wait(0.06)
                            firetouchinterest(root, wp.part, 1)
                        end)

                        -- INSTANT STAGE MONEY CORE: Fire Claim remote on every stage!
                        if State.Farm_InstantStageMoney then
                            pcall(function()
                                local claim = Workspace:FindFirstChild("ClaimRiverResultsGold")
                                if claim then claim:FireServer() end
                            end)
                        end
                        
                        -- Dwell briefly to ensure the server tick registers the stage clearance
                        local tDwell = tick()
                        while tick() - tDwell < dwellTime do
                            task.wait(0.05)
                            if not State.AutoFarm_Enabled or _G.BABFT_SESSION ~= currentSession then break end
                        end
                    end

                    if abort then
                        root.Anchored = false
                        continue
                    end

                    -- 5. Claim The End & Golden Chest
                    local theEnd = normalStages:FindFirstChild("TheEnd")
                    local chest = theEnd and theEnd:FindFirstChild("GoldenChest")
                    local trigger = chest and chest:FindFirstChild("Trigger")

                    if trigger then
                        updateStatus("Opening Golden Chest & Collecting Prizes...")
                        
                        pcall(function()
                            local dbp = theEnd:FindFirstChild("DestroyBoatPart")
                            if dbp then dbp.CanTouch = false; dbp.CanCollide = false end
                            for _, obj in ipairs(theEnd:GetDescendants()) do
                                if obj:IsA("BasePart") and (obj.Name:find("Point") or obj.Name:find("Rock")) then
                                    obj.CanTouch = false
                                    obj.CanCollide = false
                                end
                            end
                        end)

                        root.Anchored = false
                        bv.Velocity = Vector3.zero
                        root.CFrame = CFrame.new(trigger.Position + Vector3.new(0, 1.8, 0))
                        root.AssemblyLinearVelocity = Vector3.zero
                        root.AssemblyAngularVelocity = Vector3.zero

                        local initialCapPivot = nil
                        pcall(function()
                            local cap = chest:FindFirstChild("Cap")
                            if cap then
                                initialCapPivot = cap:GetPivot()
                                local openPivot = initialCapPivot * CFrame.Angles(math.rad(-75), 0, 0) + Vector3.new(0, 4, 3)
                                task.spawn(function()
                                    for step = 1, 10 do
                                        task.wait(0.02)
                                        cap:PivotTo(initialCapPivot:Lerp(openPivot, step / 10))
                                    end
                                end)
                            end
                        end)

                        pcall(function()
                            firetouchinterest(root, trigger, 0)
                            task.wait(0.12)
                            firetouchinterest(root, trigger, 1)
                        end)

                        if State.Farm_AutoClaim then
                            pcall(function()
                                local claimRemote = Workspace:FindFirstChild("ClaimRiverResultsGold")
                                if claimRemote then
                                    claimRemote:FireServer()
                                end
                            end)
                        end

                        local prizeCollectionTime = 2.8
                        local startWait = tick()
                        while tick() - startWait < prizeCollectionTime do
                            task.wait(0.15)
                            if not State.AutoFarm_Enabled or _G.BABFT_SESSION ~= currentSession then break end
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

                        if State.Farm_ClosePopups then
                            task.wait(0.15)
                            dismissResultsPopup()
                        end

                        pcall(function()
                            local cap = chest:FindFirstChild("Cap")
                            if cap and initialCapPivot then
                                cap:PivotTo(initialCapPivot)
                            end
                        end)

                        -- Smooth Dock Return (Zero Death)
                        if hum and hum.Health > 0 then
                            pcall(function()
                                local team = LocalPlayer.Team
                                local teamName = team and team.TeamColor.Name
                                local teamZone = teamName and Workspace:FindFirstChild(teamName .. "Zone")
                                if teamZone and root and root.Parent then
                                    root.CFrame = teamZone.CFrame + Vector3.new(0, 5, 0)
                                    root.AssemblyLinearVelocity = Vector3.zero
                                    root.AssemblyAngularVelocity = Vector3.zero
                                end
                            end)
                            root.Anchored = false
                            task.wait(0.5)
                        else
                            LocalPlayer.CharacterAdded:Wait()
                            task.wait(0.8)
                        end
                        updateStatus("Ready for next run!")
                    else
                        root.Anchored = false
                        task.wait(0.8)
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

Hub.CreateToggle(farmTab, "Instant Money Per Island (Core Mode)", State.Farm_InstantStageMoney, function(v)
    State.Farm_InstantStageMoney = v
end)

Hub.CreateButton(farmTab, "Emergency Unstuck (Clear Levitation & Return to Dock)", function()
    stopAutoFarmCleanly()
end)

Hub.CreateSlider(farmTab, "Stage Glide Duration (Seconds)", 0.6, 2.5, State.Farm_StageDelay, function(val)
    State.Farm_StageDelay = val
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
-- TAB 2: BUILD STEALER & BOAT COPIER (SUPER FEATURE)
-- =========================================================================
local buildTab = Hub.CreateTab("Build Stealer", {
    Icon = "🚢",
    Size = 18,
    Color = Color3.fromRGB(170, 185, 210),
    ActiveColor = Color3.fromRGB(0, 230, 180)
})

Hub.CreateSection(buildTab, "TARGET PLAYER SELECTION")

local function getOnlinePlayerNames()
    local names = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(names, p.Name)
        end
    end
    if #names == 0 then table.insert(names, "No Other Players") end
    return names
end

local targetPlayerList = getOnlinePlayerNames()
State.SelectedTargetPlayer = targetPlayerList[1]

local playerDropdown = Hub.CreateDropdown(buildTab, "Select Player to Copy Build", targetPlayerList, State.SelectedTargetPlayer, function(sel)
    State.SelectedTargetPlayer = sel
end)

Hub.CreateButton(buildTab, "🔄 Refresh Players List", function()
    local freshList = getOnlinePlayerNames()
    if playerDropdown and playerDropdown.Refresh then
        playerDropdown:Refresh(freshList)
    end
    Hub.Notify({ Title = "Build Stealer", Content = "Player list refreshed (" .. tostring(#freshList) .. " players)", Duration = 2 })
end)

Hub.CreateSection(buildTab, "METHOD 1: IN-SCRIPT BUILD MANAGER")

-- Serialize target player's build into relative CFrame data
local function exportPlayerBuild(targetPlayerName)
    if not targetPlayerName or targetPlayerName == "No Other Players" then
        Hub.Notify({ Title = "Build Stealer", Content = "Please select a valid player first!", Duration = 3 })
        return nil
    end

    local targetPlayer = Players:FindFirstChild(targetPlayerName)
    if not targetPlayer then
        Hub.Notify({ Title = "Build Stealer", Content = "Target player left the server!", Duration = 3 })
        return nil
    end

    local blocksFolder = Workspace:FindFirstChild("Blocks")
    local playerBlocks = blocksFolder and blocksFolder:FindFirstChild(targetPlayerName)

    if not playerBlocks or #playerBlocks:GetChildren() == 0 then
        Hub.Notify({ Title = "Build Stealer", Content = "Target player has no active blocks on their plot!", Duration = 3 })
        return nil
    end

    local targetTeam = targetPlayer.Team
    local teamColorName = targetTeam and targetTeam.TeamColor.Name
    local targetZone = teamColorName and Workspace:FindFirstChild(teamColorName .. "Zone")

    if not targetZone then
        Hub.Notify({ Title = "Build Stealer", Content = "Could not locate target player's team zone!", Duration = 3 })
        return nil
    end

    local buildData = {
        Author = targetPlayerName,
        ExportTime = os.date("%X"),
        BlockCount = 0,
        Blocks = {}
    }

    local targetZoneCF = targetZone.CFrame

    for _, model in ipairs(playerBlocks:GetChildren()) do
        local ppart = model:FindFirstChild("PPart") or model:FindFirstChildWhichIsA("BasePart")
        if ppart then
            local relCF = targetZoneCF:ToObjectSpace(ppart.CFrame)
            table.insert(buildData.Blocks, {
                Name = model.Name,
                RelativeCF = {relCF:GetComponents()},
                Size = {ppart.Size.X, ppart.Size.Y, ppart.Size.Z},
                Color = {ppart.Color.R, ppart.Color.G, ppart.Color.B},
                Material = tostring(ppart.Material):gsub("Enum.Material.", ""),
                Transparency = ppart.Transparency
            })
            buildData.BlockCount = buildData.BlockCount + 1
        end
    end

    local saveKey = string.format("%s (%d blocks)", targetPlayerName, buildData.BlockCount)
    SavedBuilds[saveKey] = buildData
    State.SelectedSavedBuild = saveKey

    -- Also save to executor file storage if supported
    pcall(function()
        if writefile and makefolder then
            makefolder("BABFT_Builds")
            writefile("BABFT_Builds/" .. targetPlayerName .. ".json", HttpService:JSONEncode(buildData))
        end
    end)

    Hub.Notify({
        Title = "Build Exported!",
        Content = string.format("Successfully saved %d blocks from %s!", buildData.BlockCount, targetPlayerName),
        Duration = 4
    })
    return buildData
end

Hub.CreateButton(buildTab, "💾 Export & Save Selected Player's Build", function()
    exportPlayerBuild(State.SelectedTargetPlayer)
end)

-- Reconstruct / Clone build onto LocalPlayer's plot
local function constructBuildOnMyIsland(buildKey)
    local data = SavedBuilds[buildKey]
    if not data then
        Hub.Notify({ Title = "Build Stealer", Content = "No build selected or found in memory!", Duration = 3 })
        return
    end

    local myTeam = LocalPlayer.Team
    local myTeamColor = myTeam and myTeam.TeamColor.Name
    local myZone = myTeamColor and Workspace:FindFirstChild(myTeamColor .. "Zone")

    if not myZone then
        Hub.Notify({ Title = "Build Stealer", Content = "Could not find your team zone!", Duration = 3 })
        return
    end

    local myZoneCF = myZone.CFrame
    local myBlocksFolder = Workspace:FindFirstChild("Blocks") and Workspace.Blocks:FindFirstChild(LocalPlayer.Name)

    local container = Instance.new("Model")
    container.Name = "StolenBuild_" .. data.Author
    container.Parent = Workspace

    local count = 0
    for _, block in ipairs(data.Blocks) do
        local relCF = CFrame.new(unpack(block.RelativeCF))
        local worldCF = myZoneCF:ToWorldSpace(relCF)

        local part = Instance.new("Part")
        part.Name = block.Name
        part.Size = Vector3.new(unpack(block.Size))
        part.CFrame = worldCF
        part.Color = Color3.new(unpack(block.Color))
        pcall(function() part.Material = Enum.Material[block.Material] end)
        part.Transparency = block.Transparency or 0
        part.Anchored = true
        part.CanCollide = true
        part.Parent = container
        count = count + 1
    end

    Hub.Notify({
        Title = "Build Reconstructed!",
        Content = string.format("Placed %d blocks onto your island!", count),
        Duration = 4
    })
end

Hub.CreateButton(buildTab, "🔨 Construct Selected Build on My Island", function()
    if State.SelectedSavedBuild then
        constructBuildOnMyIsland(State.SelectedSavedBuild)
    else
        Hub.Notify({ Title = "Build Stealer", Content = "Please export a build first!", Duration = 2 })
    end
end)

Hub.CreateButton(buildTab, "🗑️ Clear My Plot (Wipe Active Build)", function()
    pcall(function()
        local clearRemote = Workspace:FindFirstChild("ClearAllPlayersBoatParts")
        if clearRemote then
            clearRemote:FireServer()
            Hub.Notify({ Title = "Build Stealer", Content = "Plot cleared successfully!", Duration = 2 })
        end
    end)
end)

Hub.CreateSection(buildTab, "METHOD 2: IN-GAME SAVES TAB INTEGRATION")

local GAME_SLOTS = {"Slot 1", "Slot 2", "Slot 3", "Slot 4", "Slot 5", "Slot 6", "Slot 7", "Slot 8", "Slot 9", "Slot 10"}
Hub.CreateDropdown(buildTab, "Select In-Game Save Slot", GAME_SLOTS, "Slot 1", function(sel)
    local slotNum = tonumber(sel:match("%d+")) or 1
    State.SelectedGameSaveSlot = slotNum
end)

Hub.CreateButton(buildTab, "📥 Save Active Plot to In-Game Save Slot", function()
    pcall(function()
        local sbd = Workspace:FindFirstChild("SaveBoatData")
        if sbd then
            sbd:InvokeServer(State.SelectedGameSaveSlot)
            local updateName = Workspace:FindFirstChild("UpdateSlotNameRE")
            if updateName then
                updateName:FireServer(State.SelectedGameSaveSlot, "UnknownHub_Stolen")
            end
            Hub.Notify({ Title = "Game Saves", Content = "Saved current build to Slot " .. tostring(State.SelectedGameSaveSlot) .. "!", Duration = 3 })
        end
    end)
end)

Hub.CreateButton(buildTab, "⚡ Instant Load Slot (Bypass Build Timer)", function()
    pcall(function()
        local instaLoad = Workspace:FindFirstChild("InstaLoadFunction")
        if instaLoad then
            instaLoad:InvokeServer(State.SelectedGameSaveSlot)
            Hub.Notify({ Title = "Game Saves", Content = "Instant loaded Slot " .. tostring(State.SelectedGameSaveSlot) .. "!", Duration = 2 })
        else
            local loadRE = Workspace:FindFirstChild("LoadBoatData")
            if loadRE then
                loadRE:FireServer(State.SelectedGameSaveSlot)
                Hub.Notify({ Title = "Game Saves", Content = "Loading Slot " .. tostring(State.SelectedGameSaveSlot) .. "...", Duration = 2 })
            end
        end
    end)
end)

-- =========================================================================
-- TAB 3: SECRET TELEPORTS & EASTER EGGS
-- =========================================================================
local teleTab = Hub.CreateTab("Secret Teleports", {
    Icon = "🔮",
    Size = 18,
    Color = Color3.fromRGB(170, 185, 210),
    ActiveColor = Color3.fromRGB(160, 100, 255)
})

local function safeTeleport(cframe, name)
    local root = getRoot()
    if root then
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        root.CFrame = cframe
        Hub.Notify({ Title = "Secret Teleport", Content = "Teleported to " .. name .. "!", Duration = 2 })
    end
end

Hub.CreateSection(teleTab, "EASTER EGGS & SECRET ROOMS")

Hub.CreateButton(teleTab, "🏆 The End / Golden Chest Room", function()
    safeTeleport(CFrame.new(-54.3, -345.4, 9488.6), "Golden Chest Room")
end)

Hub.CreateButton(teleTab, "🧸 Secret Chillz Plushie Room (Waterfall Cave)", function()
    safeTeleport(CFrame.new(-450, 48, 1420), "Chillz Plushie Room")
end)

Hub.CreateButton(teleTab, "💻 Secret Coding & Computer Room", function()
    safeTeleport(CFrame.new(-180, -320, 9485), "Computer Room")
end)

Hub.CreateButton(teleTab, "🏜️ Secret Sandman Tomb / Pyramid", function()
    safeTeleport(CFrame.new(280, 50, 3600), "Sandman Tomb")
end)

Hub.CreateButton(teleTab, "📚 Secret Library & Mystery Bookshelf Room", function()
    safeTeleport(CFrame.new(-420, 65, 5200), "Secret Library")
end)

Hub.CreateButton(teleTab, "🔮 Secret Portal & Crystal Cavern", function()
    safeTeleport(CFrame.new(-150, 45, 6800), "Crystal Cavern")
end)

Hub.CreateButton(teleTab, "🎪 Secret Duck Room", function()
    safeTeleport(CFrame.new(-450, 30, 2800), "Duck Room")
end)

Hub.CreateSection(teleTab, "TEAM DOCKS TELEPORTS")

local TEAM_DOCKS = {
    ["White Dock"] = CFrame.new(-53.5, 4, -345.5),
    ["Camo Dock"] = CFrame.new(-328.9, 4, 285.8),
    ["Yellow Dock"] = CFrame.new(-328.9, 4, 643.8),
    ["Magenta Dock"] = CFrame.new(221.8, 4, 647.6),
    ["Blue Dock"] = CFrame.new(221.8, 4, 289.4),
    ["Red Dock"] = CFrame.new(221.8, 4, -68.7),
    ["Black Dock"] = CFrame.new(-328.9, 4, -72.1)
}

for dockName, dockCF in pairs(TEAM_DOCKS) do
    Hub.CreateButton(teleTab, "⛵ " .. dockName, function()
        safeTeleport(dockCF, dockName)
    end)
end

-- =========================================================================
-- TAB 4: OP EXPLOITS & CHEATS (THAT ACTUALLY WORK)
-- =========================================================================
local opTab = Hub.CreateTab("OP Exploits", {
    Icon = "⚡",
    Size = 18,
    Color = Color3.fromRGB(170, 185, 210),
    ActiveColor = Color3.fromRGB(255, 50, 80)
})

Hub.CreateSection(opTab, "GODMODE & OBSTACLE IMMUNITY")

Hub.CreateToggle(opTab, "🛡️ Water Godmode (Immune to Water)", State.Water_Godmode, function(v)
    State.Water_Godmode = v
    if v then Hub.Notify({ Title = "OP Exploits", Content = "Water Godmode Enabled!", Duration = 2 }) end
end)

RunService.Heartbeat:Connect(function()
    if State.Water_Godmode or State.AutoFarm_Enabled then
        local hum = getHumanoid()
        if hum and hum.Health > 0 and hum.Health < 100 then
            hum.Health = 100
        end
    end
end)

Hub.CreateToggle(opTab, "⚡ River Obstacle Annihilator", State.Obstacle_Annihilator, function(v)
    State.Obstacle_Annihilator = v
    if v then Hub.Notify({ Title = "OP Exploits", Content = "Obstacles Neutralized!", Duration = 2 }) end
end)

task.spawn(function()
    while true do
        task.wait(1.5)
        if _G.BABFT_SESSION ~= currentSession then break end
        if State.Obstacle_Annihilator or State.AutoFarm_Enabled then
            pcall(function()
                local bs = Workspace:FindFirstChild("BoatStages")
                local ns = bs and bs:FindFirstChild("NormalStages")
                if ns then
                    for _, stage in ipairs(ns:GetChildren()) do
                        for _, desc in ipairs(stage:GetDescendants()) do
                            if desc:IsA("BasePart") and (desc.Name:find("Rock") or desc.Name:find("Spike") or desc.Name:find("Lava") or desc.Name:find("Point") or desc.Name:find("Destroy")) then
                                desc.CanTouch = false
                                desc.CanCollide = false
                            end
                        end
                    end
                end
            end)
        end
    end
end)

Hub.CreateSection(opTab, "FLIGHT & NOCLIP ENGINE")

local flyBodyVel = nil
local flyBodyGyro = nil

Hub.CreateToggle(opTab, "✈️ High-Speed Noclip Flight", State.Noclip_Fly, function(v)
    State.Noclip_Fly = v
    local root = getRoot()
    local char = getChar()

    if v then
        if root then
            flyBodyVel = Instance.new("BodyVelocity")
            flyBodyVel.Name = "UnknownFlyBV"
            flyBodyVel.MaxForce = Vector3.new(1e9, 1e9, 1e9)
            flyBodyVel.Velocity = Vector3.zero
            flyBodyVel.Parent = root

            flyBodyGyro = Instance.new("BodyGyro")
            flyBodyGyro.Name = "UnknownFlyBG"
            flyBodyGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
            flyBodyGyro.P = 10000
            flyBodyGyro.CFrame = root.CFrame
            flyBodyGyro.Parent = root
        end
        Hub.Notify({ Title = "Flight", Content = "Flight enabled! Use WASD + Space/Shift to navigate.", Duration = 3 })
    else
        if flyBodyVel then flyBodyVel:Destroy() flyBodyVel = nil end
        if flyBodyGyro then flyBodyGyro:Destroy() flyBodyGyro = nil end
        if char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = true end
            end
        end
    end
end)

Hub.CreateSlider(opTab, "Flight Speed (Studs/s)", 20, 250, State.Fly_Speed, function(v)
    State.Fly_Speed = v
end)

RunService.RenderStepped:Connect(function()
    if State.Noclip_Fly then
        local root = getRoot()
        local char = getChar()
        local camera = Workspace.CurrentCamera

        if char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end

        if root and flyBodyVel and flyBodyGyro and camera then
            flyBodyGyro.CFrame = camera.CFrame
            local moveDir = Vector3.zero

            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir - Vector3.new(0, 1, 0) end

            flyBodyVel.Velocity = moveDir.Unit * State.Fly_Speed
            if moveDir.Magnitude == 0 then
                flyBodyVel.Velocity = Vector3.zero
            end
        end
    end
end)

Hub.CreateSection(opTab, "SPEED & JUMP")

Hub.CreateToggle(opTab, "Custom WalkSpeed", State.WalkSpeed_Enabled, function(v)
    State.WalkSpeed_Enabled = v
    local hum = getHumanoid()
    if hum then hum.WalkSpeed = v and State.WalkSpeed_Value or 16 end
end)

Hub.CreateSlider(opTab, "WalkSpeed Value", 16, 150, State.WalkSpeed_Value, function(v)
    State.WalkSpeed_Value = v
    if State.WalkSpeed_Enabled then
        local hum = getHumanoid()
        if hum then hum.WalkSpeed = v end
    end
end)

Hub.CreateToggle(opTab, "Infinite Jump", State.Infinite_Jump, function(v)
    State.Infinite_Jump = v
end)

UserInputService.JumpRequest:Connect(function()
    if State.Infinite_Jump then
        local hum = getHumanoid()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- =========================================================================
-- TAB 5: SHOP & AUTO-BUY
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
-- TAB 6: SERVER & AFK GPU SAVER
-- =========================================================================
local serverTab = Hub.CreateTab("Server & AFK", {
    Icon = "⚙️",
    Size = 18,
    Color = Color3.fromRGB(170, 185, 210),
    ActiveColor = Color3.fromRGB(140, 120, 255)
})

Hub.CreateSection(serverTab, "AFK OPTIMIZATIONS")

Hub.CreateToggle(serverTab, "Black Screen (Overnight GPU Saver)", false, function(enabled)
    Hub.SetBlackScreen(enabled)
end)

Hub.CreateButton(serverTab, "Rejoin Current Server", function()
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
end)

Hub.CreateButton(serverTab, "Server Hop", function()
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
-- Auto-Rejoin Safeguard (Overnight AFK Disconnection Shield)
-- =========================================================================
pcall(function()
    local GuiService = game:GetService("GuiService")
    GuiService.ErrorMessageChanged:Connect(function()
        task.wait(1)
        pcall(function()
            if #Players:GetPlayers() <= 1 then
                TeleportService:Teleport(game.PlaceId, LocalPlayer)
            else
                TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
            end
        end)
    end)
end)

-- =========================================================================
-- Startup Notification
-- =========================================================================
Hub.Notify({
    Title = "Unknown Hub",
    Content = "BABFT Master Suite Loaded! Instant River Auto-Farm Active.",
    Duration = 5
})
