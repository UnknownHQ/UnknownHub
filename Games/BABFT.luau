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
        source = game:HttpGet(LIBRARY_LINK .. "?v=" .. tostring(tick()))
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
    AutoFarm_Enabled = true,        -- Enabled for AFK farming
    Farm_StageDelay = 1.0,          -- Rock-solid 1.0s river stage glide
    WalkOnWater = false,
    AutoBuilder_File = "",
    AutoBuilder_Resolution = 2.0,
    AutoBuilder_GreedyMeshing = true,
    AutoBuilder_Solid = false,
    AutoBuilder_Material = "TitaniumBlock",
    Farm_FlightHeight = 55,        -- Snug in-volume glide through DarknessPart
    Farm_AutoChest = "Disabled",    -- Auto-open chests with farmed gold
    Farm_SoloLaunchOnly = true,     -- Protect friends on team plot
    Farm_AutoLaunch = true,         -- Auto triggers team dock launch
    Farm_AutoClaim = true,          -- Fires ClaimRiverResultsGold on every stage!
    Farm_InstantStageMoney = true,  -- Instant Stage Money Core
    Farm_ClosePopups = true,        -- Closes RiverResultsGui automatically

    -- Stats
    TotalRuns = 0,
    CurrentStatus = "Active",

    -- Build Stealer (Real Server-Side Block Construction)
    SelectedTargetPlayer = nil,
    SelectedSavedBuild = nil,
    SelectedGameSaveSlot = 1,
    Build_Anchored = true,
    Build_AutoSubstitute = true,
    Build_ExactMaterial = true,
    Build_ScaleEnabled = true,
    Build_PaintEnabled = true,

    -- OP Functions & Exploits
    Water_Godmode = true,
    Obstacle_Annihilator = true,
    WalkOnWater = false,
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
    if normalGravity then workspace.Gravity = normalGravity end
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
    root.Anchored = true
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
-- Master Auto Farm Thread (High-Performance Gold & Chest Engine)
-- =========================================================================
local normalGravity = workspace.Gravity

task.spawn(function()
    while true do
        task.wait(0.2)
        if _G.BABFT_SESSION ~= currentSession then
            workspace.Gravity = normalGravity
            break
        end

        if State.AutoFarm_Enabled then
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local root = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))

            -- Clean character lifecycle check (Deadlock-Free Single Respawn Handler)
            if not char or not root or not hum or hum.Health <= 0 then
                updateStatus("Respawning at Dock...")
                workspace.Gravity = normalGravity
                local newChar = LocalPlayer.CharacterAdded:Wait()
                newChar:WaitForChild("HumanoidRootPart", 5)
                newChar:WaitForChild("Humanoid", 5)
                task.wait(1.0)
                -- Auto-claim river results on spawn
                pcall(function()
                    local claimRemote = Workspace:FindFirstChild("ClaimRiverResultsGold")
                    if claimRemote then claimRemote:FireServer() end
                end)
                if State.Farm_ClosePopups then
                    task.wait(0.2)
                    dismissResultsPopup()
                end
                continue
            end

            -- Ensure clean collision and touch for character (Dead state enabled so voyage payout triggers on reset)
            pcall(function()
                hum:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
                for _, p in ipairs(char:GetDescendants()) do
                    if p:IsA("BasePart") then
                        p.CanCollide = false
                        p.CanTouch = true
                        p.CanQuery = true
                    end
                end
            end)

            local boatStages = Workspace:FindFirstChild("BoatStages")
            local normalStages = boatStages and boatStages:FindFirstChild("NormalStages")

            if normalStages then
                updateStatus("Voyage Active — Clearing Stages...")
                root.Anchored = false
                workspace.Gravity = 0

                local abort = false
                local stageDelay = math.clamp(State.Farm_StageDelay or 1.05, 0.9, 2.0)

                -- 1. Sequential River Stage Clearance (CaveStage1 through CaveStage10)
                for stageIdx = 1, 10 do
                    if not State.AutoFarm_Enabled or _G.BABFT_SESSION ~= currentSession or hum.Health <= 0 then
                        abort = true
                        break
                    end

                    local stage = normalStages:FindFirstChild("CaveStage" .. stageIdx)
                    local dp = stage and stage:FindFirstChild("DarknessPart")
                    if dp then
                        local stageName = stage.Name
                        updateStatus(string.format("Clearing Stage %d/10 (%s)...", stageIdx, stageName))

                        root.AssemblyLinearVelocity = Vector3.zero
                        root.AssemblyAngularVelocity = Vector3.zero
                        root.CFrame = dp.CFrame

                        pcall(function()
                            firetouchinterest(root, dp, 0)
                            task.wait(0.04)
                            firetouchinterest(root, dp, 1)
                        end)

                        task.wait(stageDelay)
                    end
                end

                if abort then
                    workspace.Gravity = normalGravity
                    root.Anchored = false
                    continue
                end

                -- 2. Golden Chest Room & Prize Extraction
                local theEnd = normalStages:FindFirstChild("TheEnd")
                local chest = theEnd and theEnd:FindFirstChild("GoldenChest")
                local trigger = chest and chest:FindFirstChild("Trigger")

                if trigger then
                    updateStatus("Opening Golden Chest & Claiming Blocks...")

                    -- Disarm lethal kill parts at TheEnd so player safely triggers chest
                    pcall(function()
                        local dbp = theEnd:FindFirstChild("DestroyBoatPart")
                        if dbp then dbp.CanTouch = false; dbp.CanCollide = false end
                        for _, obj in ipairs(theEnd:GetDescendants()) do
                            if obj:IsA("BasePart") and obj ~= trigger and not obj:IsDescendantOf(chest) then
                                obj.CanTouch = false
                                obj.CanCollide = false
                            end
                        end
                    end)

                    root.Anchored = false
                    root.AssemblyLinearVelocity = Vector3.zero
                    root.AssemblyAngularVelocity = Vector3.zero
                    root.CFrame = trigger.CFrame + Vector3.new(0, 2.5, 0)

                    -- Trigger touch handshake
                    pcall(function()
                        firetouchinterest(root, trigger, 0)
                        task.wait(0.05)
                        firetouchinterest(root, trigger, 1)
                    end)

                    -- Visual cap open animation
                    pcall(function()
                        local cap = chest:FindFirstChild("Cap")
                        if cap then
                            local initPivot = cap:GetPivot()
                            local openPivot = initPivot * CFrame.Angles(math.rad(-75), 0, 0) + Vector3.new(0, 4, 3)
                            task.spawn(function()
                                for step = 1, 8 do
                                    task.wait(0.03)
                                    cap:PivotTo(initPivot:Lerp(openPivot, step / 8))
                                end
                            end)
                        end
                    end)

                    -- Dwell 2.6s for prizes (GoldBars & GoldBlock) to spawn and be magneted
                    local startChest = tick()
                    while tick() - startChest < 2.6 do
                        task.wait(0.08)
                        if not State.AutoFarm_Enabled or _G.BABFT_SESSION ~= currentSession or hum.Health <= 0 then break end
                        pcall(function()
                            local tempPrizes = chest:FindFirstChild("DisplayPrizesTemp")
                            if tempPrizes then
                                for _, prize in ipairs(tempPrizes:GetChildren()) do
                                    if prize:IsA("BasePart") then
                                        prize.CFrame = root.CFrame
                                        firetouchinterest(root, prize, 0)
                                        task.wait(0.02)
                                        firetouchinterest(root, prize, 1)
                                    elseif prize:IsA("Model") and prize.PrimaryPart then
                                        prize:SetPrimaryPartCFrame(root.CFrame)
                                        firetouchinterest(root, prize.PrimaryPart, 0)
                                        task.wait(0.02)
                                        firetouchinterest(root, prize.PrimaryPart, 1)
                                    end
                                end
                            end
                        end)
                    end

                    updateRuns()

                    -- Optional Auto-Buy Chests
                    if State.Farm_AutoChest and State.Farm_AutoChest ~= "Disabled" then
                        pcall(function()
                            Workspace.ItemBoughtFromShop:InvokeServer(State.Farm_AutoChest, 1)
                        end)
                    end

                    -- Conclude Voyage: Resetting character triggers BABFT server payout & RiverResultsGui
                    updateStatus("Voyage Complete! Payout in progress...")
                    workspace.Gravity = normalGravity
                    hum.Health = 0
                    task.wait(0.5)
                else
                    workspace.Gravity = normalGravity
                    root.Anchored = false
                    task.wait(1.0)
                end
            else
                workspace.Gravity = normalGravity
                updateStatus("Waiting for BoatStages...")
                task.wait(1.0)
            end
        else
            workspace.Gravity = normalGravity
            task.wait(0.5)
        end
    end
end)

-- Hub Toggle & Sliders Configuration
Hub.CreateToggle(farmTab, "Enable Gold Auto-Farm", State.AutoFarm_Enabled, function(v)
    State.AutoFarm_Enabled = v
    if v then
        updateStatus("Active")
        Hub.Notify({ Title = "Auto Farm", Content = "Gold Auto-Farm Enabled!", Duration = 2 })
    else
        stopAutoFarmCleanly()
        Hub.Notify({ Title = "Auto Farm", Content = "Gold Auto-Farm Disabled.", Duration = 2 })
    end
end)

Hub.CreateSlider(farmTab, "Stage Dwell Duration (Seconds)", 0.9, 1.8, State.Farm_StageDelay or 1.05, function(val)
    State.Farm_StageDelay = val
end)

Hub.CreateDropdown(farmTab, "Auto-Buy Chest After Run", {
    "Disabled",
    "Common Chest",
    "Uncommon Chest",
    "Rare Chest",
    "Epic Chest",
    "Legendary Chest"
}, State.Farm_AutoChest, function(val)
    State.Farm_AutoChest = val
end)

Hub.CreateToggle(farmTab, "Auto-Dismiss Results Popups", State.Farm_ClosePopups, function(v)
    State.Farm_ClosePopups = v
end)

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

local playerDropdown = Hub.CreateDropdown(buildTab, "Select Target Player", targetPlayerList, State.SelectedTargetPlayer, function(sel)
    State.SelectedTargetPlayer = sel
end)

Hub.CreateButton(buildTab, "🔄 Refresh Players List", function()
    local freshList = getOnlinePlayerNames()
    if playerDropdown and playerDropdown.Refresh then
        playerDropdown.Refresh(freshList)
        local found = false
        for _, n in ipairs(freshList) do
            if n == State.SelectedTargetPlayer then
                found = true
                break
            end
        end
        if not found then
            State.SelectedTargetPlayer = freshList[1]
            if playerDropdown.Set then
                playerDropdown.Set(freshList[1])
            end
        end
    end
    Hub.Notify({ Title = "Build Stealer", Content = "Player list refreshed (" .. tostring(#freshList) .. " players)", Duration = 2 })
end)

Hub.CreateSection(buildTab, "METHOD 1: IN-SCRIPT BUILD MANAGER")

-- Serialize target player's build into relative CFrame data (Centered & Zone-Aligned)
-- =========================================================================
-- MATERIAL FAMILIES & SHOP DEFINITIONS FOR BUILD STEALER
-- =========================================================================
local MATERIAL_FAMILIES = {
    WoodBlock = "Wood",
    SmoothWoodBlock = "Wood",
    PlasticBlock = "SmoothPlastic",
    ConcreteBlock = "Stone",
    StoneBlock = "Stone",
    ObsidianBlock = "Stone",
    TitaniumBlock = "Metal",
    MetalBlock = "Metal",
    RustedBlock = "Metal",
    BrickBlock = "Brick",
    GlassBlock = "Glass",
    IceBlock = "Ice",
    FabricBlock = "Fabric",
    SandBlock = "Sand",
    CoalBlock = "Coal",
    NeonBlock = "Neon",
    GoldBlock = "Gold"
}

local FAMILY_SUBSTITUTES = {
    Wood = {"SmoothWoodBlock", "WoodBlock"},
    SmoothPlastic = {"PlasticBlock", "SmoothWoodBlock", "IceBlock"},
    Metal = {"TitaniumBlock", "MetalBlock", "RustedBlock", "GoldBlock"},
    Stone = {"ConcreteBlock", "StoneBlock", "ObsidianBlock", "MarbleBlock"},
    Brick = {"BrickBlock", "ConcreteBlock"},
    Glass = {"GlassBlock", "IceBlock"},
    Ice = {"IceBlock", "GlassBlock"},
    Fabric = {"FabricBlock", "PlasticBlock"},
    Sand = {"SandBlock", "ConcreteBlock", "SmoothWoodBlock", "WoodBlock"},
    Coal = {"CoalBlock", "ObsidianBlock", "ConcreteBlock"},
    Neon = {"NeonBlock", "PlasticBlock", "GlassBlock"},
    Gold = {"GoldBlock", "TitaniumBlock", "MetalBlock", "PlasticBlock"},
    Bouncy = {"BouncyBlock", "PlasticBlock"},
    Grass = {"GrassBlock", "SandBlock", "PlasticBlock"}
}

local SHOP_ITEMS_MAP = {
    WoodBlock = { ShopItem = "WoodBlock", PackQty = 50, Price = 250 },
    SmoothWoodBlock = { ShopItem = "SmoothWoodBlock", PackQty = 50, Price = 250 },
    PlasticBlock = { ShopItem = "PlasticBlock", PackQty = 50, Price = 300 },
    BrickBlock = { ShopItem = "BrickBlock", PackQty = 50, Price = 250 },
    ConcreteBlock = { ShopItem = "ConcreteBlock", PackQty = 50, Price = 250 },
    MarbleBlock = { ShopItem = "MarbleBlock", PackQty = 50, Price = 300 },
    ObsidianBlock = { ShopItem = "ObsidianBlock", PackQty = 50, Price = 450 },
    TitaniumBlock = { ShopItem = "TitaniumBlock", PackQty = 50, Price = 450 },
    MetalBlock = { ShopItem = "MetalBlock", PackQty = 50, Price = 350 },
    RustedBlock = { ShopItem = "RustedBlock", PackQty = 50, Price = 200 },
    IceBlock = { ShopItem = "IceBlock", PackQty = 50, Price = 150 },
    GlassBlock = { ShopItem = "GlassBlock", PackQty = 50, Price = 300 },
    SandBlock = { ShopItem = "SandBlock", PackQty = 50, Price = 150 },
    StoneBlock = { ShopItem = "StoneBlock", PackQty = 50, Price = 200 },
    FabricBlock = { ShopItem = "FabricBlock", PackQty = 50, Price = 300 },
    CoalBlock = { ShopItem = "CoalBlock", PackQty = 50, Price = 200 },
    GrassBlock = { ShopItem = "GrassBlock", PackQty = 50, Price = 200 },
    BouncyBlock = { ShopItem = "BouncyBlock", PackQty = 50, Price = 200 },
    Piston = { ShopItem = "Pistons", PackQty = 4, Price = 450 },
    Hinge = { ShopItem = "HingeBlocks", PackQty = 4, Price = 400 },
    Balloons = { ShopItem = "Balloons", PackQty = 25, Price = 250 }
}

local function getBlockImage(name)
    local btn = LocalPlayer.PlayerGui.BuildGui:FindFirstChild(name, true) or LocalPlayer.PlayerGui.ShopGui:FindFirstChild(name, true)
    if btn and (btn:IsA("ImageButton") or btn:IsA("ImageLabel")) and btn.Image and #btn.Image > 0 then
        return btn.Image
    end
    return "rbxassetid://4597411234"
end

local function showMissingBlocksHUD(missingList)
    if not missingList or #missingList == 0 then return end

    local pGui = LocalPlayer:WaitForChild("PlayerGui")
    if pGui:FindFirstChild("Unknown_MissingBlocksHUD") then
        pGui.Unknown_MissingBlocksHUD:Destroy()
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "Unknown_MissingBlocksHUD"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = pGui

    -- Authentic BABFT Blueprint Panel Design (100% Stealth & Natural)
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.AnchorPoint = Vector2.new(0.5, 0)
    mainFrame.Position = UDim2.new(0.5, 0, 0, -160)
    mainFrame.Size = UDim2.new(0, math.min(580, math.max(460, #missingList * 85 + 175)), 0, 142)
    mainFrame.BackgroundColor3 = Color3.fromRGB(36, 42, 56)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui

    local uicorner = Instance.new("UICorner")
    uicorner.CornerRadius = UDim.new(0, 12)
    uicorner.Parent = mainFrame

    local uistroke = Instance.new("UIStroke")
    uistroke.Color = Color3.fromRGB(65, 78, 105)
    uistroke.Thickness = 2
    uistroke.Parent = mainFrame

    -- Title Bar (Natural Game Blueprint Styling)
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 32)
    titleBar.BackgroundColor3 = Color3.fromRGB(28, 33, 45)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame

    local tCorner = Instance.new("UICorner")
    tCorner.CornerRadius = UDim.new(0, 12)
    tCorner.Parent = titleBar

    local flatCover = Instance.new("Frame")
    flatCover.Position = UDim2.new(0, 0, 1, -6)
    flatCover.Size = UDim2.new(1, 0, 0, 6)
    flatCover.BackgroundColor3 = Color3.fromRGB(28, 33, 45)
    flatCover.BorderSizePixel = 0
    flatCover.Parent = titleBar

    local title = Instance.new("TextLabel")
    title.Position = UDim2.new(0, 14, 0, 0)
    title.Size = UDim2.new(0.6, 0, 1, 0)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 16
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = "Boat Blueprint — Required Materials"
    title.Parent = titleBar

    local timer = Instance.new("TextLabel")
    timer.Position = UDim2.new(0.62, 0, 0, 0)
    timer.Size = UDim2.new(0.28, 0, 1, 0)
    timer.BackgroundTransparency = 1
    timer.Font = Enum.Font.SourceSans
    timer.TextSize = 13
    timer.TextColor3 = Color3.fromRGB(150, 165, 185)
    timer.TextXAlignment = Enum.TextXAlignment.Right
    timer.Text = "Auto-close in 15s"
    timer.Parent = titleBar

    local closeBtn = Instance.new("TextButton")
    closeBtn.Position = UDim2.new(1, -28, 0, 4)
    closeBtn.Size = UDim2.new(0, 24, 0, 24)
    closeBtn.BackgroundColor3 = Color3.fromRGB(50, 58, 76)
    closeBtn.BorderSizePixel = 0
    closeBtn.Font = Enum.Font.SourceSansBold
    closeBtn.TextSize = 14
    closeBtn.TextColor3 = Color3.fromRGB(220, 225, 235)
    closeBtn.Text = "✕"
    closeBtn.Parent = titleBar

    local cCorner = Instance.new("UICorner")
    cCorner.CornerRadius = UDim.new(0, 6)
    cCorner.Parent = closeBtn

    -- Block Slot Gallery (Styled like BABFT's native inventory grid)
    local scroll = Instance.new("ScrollingFrame")
    scroll.Position = UDim2.new(0, 12, 0, 40)
    scroll.Size = UDim2.new(1, -165, 0, 92)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 4
    scroll.ScrollBarImageColor3 = Color3.fromRGB(80, 95, 125)
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.X
    scroll.Parent = mainFrame

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 8)
    layout.Parent = scroll

    for _, it in ipairs(missingList) do
        local slot = Instance.new("Frame")
        slot.Size = UDim2.new(0, 75, 0, 78)
        slot.BackgroundColor3 = Color3.fromRGB(24, 28, 38)
        slot.BorderSizePixel = 0
        slot.Parent = scroll

        local sCorner = Instance.new("UICorner")
        sCorner.CornerRadius = UDim.new(0, 8)
        sCorner.Parent = slot

        local sStroke = Instance.new("UIStroke")
        sStroke.Color = Color3.fromRGB(55, 65, 85)
        sStroke.Thickness = 1
        sStroke.Parent = slot

        local img = Instance.new("ImageLabel")
        img.Position = UDim2.new(0.5, -22, 0, 4)
        img.Size = UDim2.new(0, 44, 0, 44)
        img.BackgroundTransparency = 1
        img.Image = getBlockImage(it.name)
        img.Parent = slot

        local nameLbl = Instance.new("TextLabel")
        nameLbl.Position = UDim2.new(0, 2, 0, 48)
        nameLbl.Size = UDim2.new(1, -4, 0, 14)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Font = Enum.Font.SourceSans
        nameLbl.TextSize = 11
        nameLbl.TextColor3 = Color3.fromRGB(180, 195, 215)
        nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
        nameLbl.Text = it.name:gsub("Block", "")
        nameLbl.Parent = slot

        local countBadge = Instance.new("TextLabel")
        countBadge.Position = UDim2.new(0, 2, 0, 62)
        countBadge.Size = UDim2.new(1, -4, 0, 14)
        countBadge.BackgroundTransparency = 1
        countBadge.Font = Enum.Font.SourceSansBold
        countBadge.TextSize = 12
        countBadge.TextColor3 = Color3.fromRGB(255, 120, 120)
        countBadge.Text = string.format("-%d (%d/%d)", it.missing, it.owned, it.needed)
        countBadge.Parent = slot
    end

    -- Action Frame (Build Anyway / Buy in Shop / Dismiss)
    local actionFrame = Instance.new("Frame")
    actionFrame.Position = UDim2.new(1, -150, 0, 36)
    actionFrame.Size = UDim2.new(0, 140, 0, 98)
    actionFrame.BackgroundTransparency = 1
    actionFrame.Parent = mainFrame

    local buildAnywayBtn = Instance.new("TextButton")
    buildAnywayBtn.Size = UDim2.new(1, 0, 0, 30)
    buildAnywayBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 240)
    buildAnywayBtn.BorderSizePixel = 0
    buildAnywayBtn.Font = Enum.Font.SourceSansBold
    buildAnywayBtn.TextSize = 13
    buildAnywayBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    buildAnywayBtn.Text = "🔨 Build Anyway"
    buildAnywayBtn.Parent = actionFrame

    local baCorner = Instance.new("UICorner")
    baCorner.CornerRadius = UDim.new(0, 6)
    baCorner.Parent = buildAnywayBtn

    local buyBtn = Instance.new("TextButton")
    buyBtn.Position = UDim2.new(0, 0, 0, 34)
    buyBtn.Size = UDim2.new(1, 0, 0, 30)
    buyBtn.BackgroundColor3 = Color3.fromRGB(38, 166, 91)
    buyBtn.BorderSizePixel = 0
    buyBtn.Font = Enum.Font.SourceSansBold
    buyBtn.TextSize = 13
    buyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    buyBtn.Text = "🛒 Buy in Shop"
    buyBtn.Parent = actionFrame

    local bCorner = Instance.new("UICorner")
    bCorner.CornerRadius = UDim.new(0, 6)
    bCorner.Parent = buyBtn

    local dismissBtn = Instance.new("TextButton")
    dismissBtn.Position = UDim2.new(0, 0, 0, 68)
    dismissBtn.Size = UDim2.new(1, 0, 0, 26)
    dismissBtn.BackgroundColor3 = Color3.fromRGB(50, 58, 76)
    dismissBtn.BorderSizePixel = 0
    dismissBtn.Font = Enum.Font.SourceSans
    dismissBtn.TextSize = 12
    dismissBtn.TextColor3 = Color3.fromRGB(200, 210, 225)
    dismissBtn.Text = "Dismiss"
    dismissBtn.Parent = actionFrame

    local dCorner = Instance.new("UICorner")
    dCorner.CornerRadius = UDim.new(0, 6)
    dCorner.Parent = dismissBtn

    local function dismiss()
        mainFrame:TweenPosition(UDim2.new(0.5, 0, 0, -170), Enum.EasingDirection.In, Enum.EasingStyle.Quad, 0.3, true, function()
            screenGui:Destroy()
        end)
    end

    closeBtn.MouseButton1Click:Connect(dismiss)
    dismissBtn.MouseButton1Click:Connect(dismiss)

    buildAnywayBtn.MouseButton1Click:Connect(function()
        dismiss()
        constructBuildOnMyIsland(State.SelectedSavedBuild, true)
    end)

    buyBtn.MouseButton1Click:Connect(function()
        buyBtn.Text = "Buying..."
        local boughtAny = false
        for _, it in ipairs(missingList) do
            local info = SHOP_ITEMS_MAP[it.name]
            if info then
                local packsNeeded = math.ceil(it.missing / info.PackQty)
                pcall(function()
                    LocalPlayer.PlayerGui.ItemGained.LastItemBoughtName.Value = info.ShopItem
                    for p = 1, packsNeeded do
                        Workspace.ItemBoughtFromShop:InvokeServer(info.ShopItem, 1)
                        task.wait(0.2)
                    end
                    boughtAny = true
                end)
            end
        end
        if boughtAny then
            Hub.Notify({ Title = "Shop", Content = "Purchased blueprint materials!", Duration = 3 })
            dismiss()
        else
            Hub.Notify({ Title = "Shop", Content = "Some items are not sold in shop.", Duration = 3 })
            buyBtn.Text = "Done"
        end
    end)

    mainFrame:TweenPosition(UDim2.new(0.5, 0, 0, 20), Enum.EasingDirection.Out, Enum.EasingStyle.Back, 0.45, true)

    task.spawn(function()
        for remaining = 15, 1, -1 do
            if not screenGui.Parent then break end
            timer.Text = string.format("Auto-close in %ds", remaining)
            task.wait(1)
        end
        if screenGui.Parent then dismiss() end
    end)
end

local function checkBuildMissingBlocks(buildData)
    if not buildData or not buildData.Blocks then return {} end
    local needed = {}

    -- Scalable structural blocks that consume inventory volume in BABFT (1 unit = 2x2x2 = 8 cubic studs)
    local SCALABLE_BLOCKS = {
        WoodBlock = true, SmoothWoodBlock = true, PlasticBlock = true,
        BrickBlock = true, ConcreteBlock = true, MarbleBlock = true,
        ObsidianBlock = true, TitaniumBlock = true, MetalBlock = true,
        RustedBlock = true, IceBlock = true, GlassBlock = true,
        SandBlock = true, StoneBlock = true, FabricBlock = true,
        CoalBlock = true, GrassBlock = true, NeonBlock = true,
        GoldBlock = true, BouncyBlock = true
    }

    for _, b in ipairs(buildData.Blocks) do
        local sx, sy, sz = 2, 2, 2
        if typeof(b.Size) == "Vector3" then
            sx, sy, sz = b.Size.X, b.Size.Y, b.Size.Z
        elseif typeof(b.Size) == "table" then
            sx = tonumber(b.Size[1] or b.Size.X) or 2
            sy = tonumber(b.Size[2] or b.Size.Y) or 2
            sz = tonumber(b.Size[3] or b.Size.Z) or 2
        end

        local isScalable = SCALABLE_BLOCKS[b.Name]
        if not isScalable and b.Name then
            local low = b.Name:lower()
            if low:find("block") or low:find("wedge") or low:find("truss") or low:find("pillar") or low:find("wall") or low:find("ramp") then
                isScalable = true
            end
        end

        local blockCost = 1
        if isScalable then
            local volume = sx * sy * sz
            -- Calculate true volume-adjusted block consumption (8 cubic studs per inventory block)
            blockCost = math.max(1, math.ceil((volume / 8) - 0.05))
        end
        needed[b.Name] = (needed[b.Name] or 0) + blockCost
    end

    local missingList = {}
    for name, count in pairs(needed) do
        local itemData = LocalPlayer.Data:FindFirstChild(name)
        local owned = itemData and itemData.Value or 0

        -- If seat is missing, check if user has Thrones, CarSeats, or PilotSeats
        if name:lower():find("seat") and owned < count then
            local altSeats = (LocalPlayer.Data:FindFirstChild("CarSeat") and LocalPlayer.Data.CarSeat.Value or 0)
                + (LocalPlayer.Data:FindFirstChild("Throne") and LocalPlayer.Data.Throne.Value or 0)
                + (LocalPlayer.Data:FindFirstChild("PilotSeat") and LocalPlayer.Data.PilotSeat.Value or 0)
            if altSeats >= count then
                continue -- User has usable seats, do not bother them
            end
        end

        -- If wheel is missing, check if user has other wheels
        if name:lower():find("wheel") and owned < count then
            local totalWheels = 0
            for _, it in ipairs(LocalPlayer.Data:GetChildren()) do
                if it.Name:lower():find("wheel") and it.Value > 0 then
                    totalWheels = totalWheels + it.Value
                end
            end
            if totalWheels >= count then
                continue -- User has usable wheels
            end
        end

        -- Report ALL missing blocks (shop purchasable or special/inventory) so incomplete builds are stopped
        if owned < count then
            local shopInfo = SHOP_ITEMS_MAP[name]
            table.insert(missingList, {
                name = name,
                needed = count,
                owned = owned,
                missing = count - owned,
                price = shopInfo and shopInfo.Price or "Special / Inventory"
            })
        end
    end

    table.sort(missingList, function(a, b) return a.missing > b.missing end)
    return missingList
end

-- Canonical dock coordinate system for any plot
local function getZoneDockCF(zone)
    local surfaceY = zone.Size.Y / 2
    -- Use zone native CFrame shifted to dock surface (preserves 100% true yaw/pitch/roll across all plots)
    return zone.CFrame * CFrame.new(0, surfaceY, 0)
end

-- Serialize target player's build into relative CFrame data (Centered & Zone-Aligned)
local function exportPlayerBuild(targetPlayerName)
    if not targetPlayerName or targetPlayerName == "No Other Players" then
        Hub.Notify({ Title = "Build Stealer", Content = "Please select a valid player first!", Duration = 3 })
        return nil
    end

    local targetPlayer = Players:FindFirstChild(targetPlayerName)
    local blocksFolder = Workspace:FindFirstChild("Blocks")
    if not blocksFolder then
        Hub.Notify({ Title = "Build Stealer", Content = "Workspace.Blocks not found!", Duration = 3 })
        return nil
    end

    -- 1. Candidate folders: target player, teammates, and plot builders
    local candidateFolders = {}
    local seenFolders = {}

    local function addFolder(folder)
        if folder and not seenFolders[folder] and #folder:GetChildren() > 0 then
            seenFolders[folder] = true
            table.insert(candidateFolders, folder)
        end
    end

    -- Always include target player's direct folder
    addFolder(blocksFolder:FindFirstChild(targetPlayerName))

    -- Check all teammates on target player's team
    local targetTeam = targetPlayer and targetPlayer.Team
    if targetTeam then
        for _, pl in ipairs(targetTeam:GetPlayers()) do
            if pl ~= LocalPlayer or pl.Name == targetPlayerName then
                addFolder(blocksFolder:FindFirstChild(pl.Name))
            end
        end
    end

    -- 2. Resolve target team zone
    local targetZone = nil
    local TEAM_ZONE_MAP = {
        white = "WhiteZone",
        blue = "Really blueZone",
        green = "CamoZone",
        red = "Really redZone",
        black = "BlackZone",
        yellow = "New YellerZone",
        magenta = "MagentaZone"
    }

    if targetTeam then
        local teamColorName = targetTeam.TeamColor and targetTeam.TeamColor.Name
        if teamColorName then
            targetZone = Workspace:FindFirstChild(teamColorName .. "Zone")
        end
        if not targetZone then
            local mappedName = TEAM_ZONE_MAP[targetTeam.Name:lower()]
            targetZone = mappedName and Workspace:FindFirstChild(mappedName)
        end
        if not targetZone then
            for _, z in ipairs(Workspace:GetChildren()) do
                if z.Name:find("Zone") and (z.Name:lower():find(targetTeam.Name:lower()) or (teamColorName and z.Name:lower():find(teamColorName:lower()))) then
                    targetZone = z
                    break
                end
            end
        end
    end

    -- Fallback: check if target player's character is standing near a zone
    if not targetZone and targetPlayer and targetPlayer.Character then
        local hrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local closestZ = nil
            local closestDist = 9999
            for _, z in ipairs(Workspace:GetChildren()) do
                if z.Name:find("Zone") and z:IsA("BasePart") then
                    local d = (z.Position - hrp.Position).Magnitude
                    if d < closestDist then
                        closestDist = d
                        closestZ = z
                    end
                end
            end
            if closestDist < 400 then
                targetZone = closestZ
            end
        end
    end

    -- Default fallback zone if unassigned
    if not targetZone then
        targetZone = Workspace:FindFirstChild("WhiteZone")
    end

    local targetDockCF = getZoneDockCF(targetZone)

    -- If no candidate folders were found for the player, check direct folder (never add unrelated player folders)
    if #candidateFolders == 0 then
        local directFolder = blocksFolder:FindFirstChild(targetPlayerName)
        if directFolder and #directFolder:GetChildren() > 0 then
            addFolder(directFolder)
        end
    end

    -- 3. Collect valid block parts strictly within target dock plot bounds (prevents capturing neighbor plots, plushies, or river debris)
    local validEntries = {}
    local minRel = Vector3.new(math.huge, math.huge, math.huge)
    local maxRel = Vector3.new(-math.huge, -math.huge, -math.huge)
    local maxHalfX = math.max(targetZone.Size.X / 2 + 15, 60)
    local maxHalfZ = math.max(targetZone.Size.Z / 2 + 25, 90)

    local seenModels = {}
    -- Pass A: Scan candidate folders (target player and teammates)
    for _, folder in ipairs(candidateFolders) do
        for _, model in ipairs(folder:GetChildren()) do
            if not seenModels[model] then
                local ppart = model:FindFirstChild("PPart") or model:FindFirstChildWhichIsA("BasePart")
                if ppart then
                    local localPos = targetZone.CFrame:PointToObjectSpace(ppart.Position)
                    if math.abs(localPos.X) <= maxHalfX and math.abs(localPos.Z) <= maxHalfZ and localPos.Y >= -10 and localPos.Y <= 250 then
                        seenModels[model] = true
                        local rel = targetDockCF:ToObjectSpace(ppart.CFrame)
                        minRel = minRel:Min(rel.Position)
                        maxRel = maxRel:Max(rel.Position)
                        table.insert(validEntries, {model = model, ppart = ppart, relCF = rel})
                    end
                end
            end
        end
    end

    -- Pass B: Dementia-Proof Global Plot Bound Scan (Captures shared blocks, disconnected teammates, or helper parts on plot)
    for _, folder in ipairs(blocksFolder:GetChildren()) do
        for _, model in ipairs(folder:GetChildren()) do
            if not seenModels[model] then
                local ppart = model:FindFirstChild("PPart") or model:FindFirstChildWhichIsA("BasePart")
                if ppart then
                    local localPos = targetZone.CFrame:PointToObjectSpace(ppart.Position)
                    if math.abs(localPos.X) <= maxHalfX and math.abs(localPos.Z) <= maxHalfZ and localPos.Y >= -10 and localPos.Y <= 250 then
                        seenModels[model] = true
                        local rel = targetDockCF:ToObjectSpace(ppart.CFrame)
                        minRel = minRel:Min(rel.Position)
                        maxRel = maxRel:Max(rel.Position)
                        table.insert(validEntries, {model = model, ppart = ppart, relCF = rel})
                    end
                end
            end
        end
    end

    -- 4. Ultimate safety fallback: if local bounds excluded parts, grab target player's direct folder blocks
    if #validEntries == 0 then
        local directFolder = blocksFolder:FindFirstChild(targetPlayerName)
        if directFolder and #directFolder:GetChildren() > 0 then
            for _, model in ipairs(directFolder:GetChildren()) do
                local ppart = model:FindFirstChild("PPart") or model:FindFirstChildWhichIsA("BasePart")
                if ppart then
                    local rel = targetDockCF:ToObjectSpace(ppart.CFrame)
                    minRel = minRel:Min(rel.Position)
                    maxRel = maxRel:Max(rel.Position)
                    table.insert(validEntries, {model = model, ppart = ppart, relCF = rel})
                end
            end
        end
    end

    if #validEntries == 0 then
        Hub.Notify({ Title = "Build Stealer", Content = "No blocks found on " .. targetPlayerName .. "'s plot!", Duration = 3 })
        return nil
    end

    -- Canonical alignment: center X and Z, ground Y with bottom surface 0.5 above dock floor
    local offsetX = (minRel.X + maxRel.X) / 2
    local offsetZ = (minRel.Z + maxRel.Z) / 2
    local lowestBottomY = minRel.Y - 1.0
    local targetBottomY = 0.5
    local offsetY = lowestBottomY - targetBottomY

    local buildData = {
        Author = targetPlayerName,
        ExportTime = os.date("%X"),
        BlockCount = 0,
        Blocks = {}
    }

    for _, entry in ipairs(validEntries) do
        local model = entry.model
        local ppart = entry.ppart
        local adjPos = Vector3.new(entry.relCF.X - offsetX, entry.relCF.Y - offsetY, entry.relCF.Z - offsetZ)
        local adjCF = CFrame.new(adjPos) * entry.relCF.Rotation
        table.insert(buildData.Blocks, {
            Name = model.Name,
            RelativeCF = {adjCF:GetComponents()},
            Size = {ppart.Size.X, ppart.Size.Y, ppart.Size.Z},
            Color = {ppart.Color.R, ppart.Color.G, ppart.Color.B},
            Material = tostring(ppart.Material):gsub("Enum.Material.", ""),
            Transparency = ppart.Transparency,
            CanCollide = ppart.CanCollide,
            CastShadow = ppart.CastShadow
        })
        buildData.BlockCount = buildData.BlockCount + 1
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

    local missingList = checkBuildMissingBlocks(buildData)
    if #missingList > 0 then
        showMissingBlocksHUD(missingList)
    end

    Hub.Notify({
        Title = "Build Exported!",
        Content = string.format("Successfully saved %d blocks from %s! (Missing: %d)", buildData.BlockCount, targetPlayerName, #missingList),
        Duration = 4
    })
    return buildData
end

Hub.CreateButton(buildTab, "💾 Export & Save Selected Player's Build", function()
    exportPlayerBuild(State.SelectedTargetPlayer)
end)

Hub.CreateButton(buildTab, "🔍 View Missing Materials Breakdown (HUD)", function()
    local data = SavedBuilds[State.SelectedSavedBuild]
    if not data then
        Hub.Notify({ Title = "Build Stealer", Content = "Please export or select a build first!", Duration = 3 })
        return
    end
    local missingList = checkBuildMissingBlocks(data)
    if #missingList == 0 then
        Hub.Notify({ Title = "Build Stealer", Content = "You own ALL required materials for this build!", Duration = 3 })
    else
        showMissingBlocksHUD(missingList)
    end
end)

Hub.CreateButton(buildTab, "🛒 Buy All Missing Blocks From Shop", function()
    local data = SavedBuilds[State.SelectedSavedBuild]
    if not data then
        Hub.Notify({ Title = "Build Stealer", Content = "Please export or select a build first!", Duration = 3 })
        return
    end
    local missingList = checkBuildMissingBlocks(data)
    if #missingList == 0 then
        Hub.Notify({ Title = "Shop", Content = "No blocks missing!", Duration = 2 })
        return
    end
    local boughtAny = false
    for _, it in ipairs(missingList) do
        local info = SHOP_ITEMS_MAP[it.name]
        if info then
            local packs = math.ceil(it.missing / info.PackQty)
            pcall(function()
                LocalPlayer.PlayerGui.ItemGained.LastItemBoughtName.Value = info.ShopItem
                for p = 1, packs do
                    Workspace.ItemBoughtFromShop:InvokeServer(info.ShopItem, 1)
                    task.wait(0.18)
                end
                boughtAny = true
            end)
        end
    end
    if boughtAny then
        Hub.Notify({ Title = "Shop", Content = "Successfully purchased available missing blocks!", Duration = 3 })
    else
        Hub.Notify({ Title = "Shop", Content = "Missing blocks are special/quest items not in basic shop.", Duration = 3 })
    end
end)

-- Clean up any obsolete client dummy containers
pcall(function()
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj.Name:find("StolenBuild_") then
            obj:Destroy()
        end
    end
end)

-- Track inventory counts dynamically
local function getLocalInventory()
    local inv = {}
    local dataFolder = LocalPlayer:FindFirstChild("Data")
    if dataFolder then
        for _, item in ipairs(dataFolder:GetChildren()) do
            if item:IsA("IntValue") then
                inv[item.Name] = item.Value
            end
        end
    end
    return inv
end

-- Allowed solid structural fallback blocks in descending priority (NEVER BALLOONS OR FURNITURE)
local SOLID_FALLBACKS = {
    "PlasticBlock",
    "SmoothWoodBlock",
    "WoodBlock",
    "ConcreteBlock",
    "StoneBlock",
    "TitaniumBlock",
    "MetalBlock",
    "ObsidianBlock",
    "BrickBlock",
    "RustedBlock",
    "IceBlock",
    "SandBlock",
    "MarbleBlock",
    "CoalBlock"
}

local function getBestSolidBlock(inv)
    local bestName = nil
    local bestCount = 0
    for _, name in ipairs(SOLID_FALLBACKS) do
        local count = inv[name] or 0
        if count > bestCount then
            bestCount = count
            bestName = name
        end
    end
    -- Fallback to ANY structural block if standard list is depleted
    if bestCount <= 0 then
        for name, count in pairs(inv) do
            if name:find("Block") and not name:find("Portal") and not name:find("Chest") and count > bestCount then
                bestCount = count
                bestName = name
            end
        end
    end
    return bestName, bestCount
end

-- Reconstruct REAL server-recognized blocks onto LocalPlayer's plot
local function constructBuildOnMyIsland(buildKey, forceBuild)
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

    -- 1. STRICT INVENTORY PRE-CHECK: Halt immediately if blocks are missing unless forceBuild is set!
    local missingList = checkBuildMissingBlocks(data)
    if #missingList > 0 and not forceBuild then
        showMissingBlocksHUD(missingList)
        local totalMissing = 0
        for _, it in ipairs(missingList) do
            totalMissing = totalMissing + (it.missing or 1)
        end
        Hub.Notify({
            Title = "Not Enough Blocks!",
            Content = string.format("Missing %d blocks (%d types). Check the blueprint panel above to Build Anyway or Buy in Shop!", totalMissing, #missingList),
            Duration = 5
        })
        return
    end

    local char = LocalPlayer.Character
    local bTool = LocalPlayer.Backpack:FindFirstChild("BuildingTool") or (char and char:FindFirstChild("BuildingTool"))
    if not bTool then
        Hub.Notify({ Title = "Build Stealer", Content = "BuildingTool not found! Please check inventory.", Duration = 3 })
        return
    end

    local bRF = bTool:FindFirstChild("RF")
    if not bRF then
        Hub.Notify({ Title = "Build Stealer", Content = "BuildingTool RF remote not found!", Duration = 3 })
        return
    end

    -- Auto-clear plot before building so old leftover blocks (e.g. wheels, TNT) never get merged into new builds
    local myBlocks = Workspace.Blocks:FindFirstChild(LocalPlayer.Name)
    if myBlocks and #myBlocks:GetChildren() > 0 then
        pcall(function()
            local clearRemote = Workspace:FindFirstChild("ClearAllPlayersBoatParts")
            if clearRemote then
                clearRemote:FireServer()
                task.wait(0.35)
            end
        end)
    end

    -- SAFETY: Temporarily pause AutoFarm so character resets do not destroy plot
    local wasFarming = State.AutoFarm_Enabled
    if wasFarming then
        State.AutoFarm_Enabled = false
        Hub.Notify({ Title = "Build Stealer", Content = "Paused Auto Farm during construction!", Duration = 3 })
    end

    local myDockCF = getZoneDockCF(myZone)
    local isAnchored = State.Build_Anchored ~= false

    Hub.Notify({
        Title = "Build Stealer",
        Content = string.format("Constructing %d REAL blocks onto your plot...", #data.Blocks),
        Duration = 3
    })

    task.spawn(function()
        local count = 0
        local substituted = 0
        local skipped = 0
        local placedList = {}
        local metaList = {}

        local myBlocks = Workspace.Blocks:FindFirstChild(LocalPlayer.Name)
        local conn
        if myBlocks then
            conn = myBlocks.ChildAdded:Connect(function(child)
                table.insert(placedList, child)
            end)
        end

        local function getBestFallback()
            local inv = getLocalInventory()
            local bestName, bestCount = getBestSolidBlock(inv)
            return bestName or "TitaniumBlock"
        end

        -- Phase 1: Silent Remote Structural Placement (100% Stealth, Zero Tool Equipping)
        for _, block in ipairs(data.Blocks) do
            local adjRelCF = CFrame.new(unpack(block.RelativeCF))
            local worldCF = myDockCF:ToWorldSpace(adjRelCF)
            local relToZone = myZone.CFrame:ToObjectSpace(worldCF)

            local blockToUse = block.Name
            local itemData = LocalPlayer.Data:FindFirstChild(blockToUse)
            local curVal = itemData and itemData.Value or 0

            -- If player does not own this block, handle substitutions
            if curVal <= 0 then
                if blockToUse:lower():find("seat") then
                    if (LocalPlayer.Data:FindFirstChild("CarSeat") and LocalPlayer.Data.CarSeat.Value > 0) then
                        blockToUse = "CarSeat"
                        curVal = LocalPlayer.Data.CarSeat.Value
                        substituted = substituted + 1
                    elseif (LocalPlayer.Data:FindFirstChild("Throne") and LocalPlayer.Data.Throne.Value > 0) then
                        blockToUse = "Throne"
                        curVal = LocalPlayer.Data.Throne.Value
                        substituted = substituted + 1
                    elseif (LocalPlayer.Data:FindFirstChild("PilotSeat") and LocalPlayer.Data.PilotSeat.Value > 0) then
                        blockToUse = "PilotSeat"
                        curVal = LocalPlayer.Data.PilotSeat.Value
                        substituted = substituted + 1
                    end
                elseif blockToUse:lower():find("wheel") then
                    for _, it in ipairs(LocalPlayer.Data:GetChildren()) do
                        if it.Name:lower():find("wheel") and it.Value > 0 then
                            blockToUse = it.Name
                            curVal = it.Value
                            substituted = substituted + 1
                            break
                        end
                    end
                elseif State.Build_ExactMaterial then
                    local family = MATERIAL_FAMILIES[blockToUse]
                    local familySubstitutes = family and FAMILY_SUBSTITUTES[family] or {}

                    for _, altName in ipairs(familySubstitutes) do
                        local altData = LocalPlayer.Data:FindFirstChild(altName)
                        if altData and altData.Value > 0 then
                            blockToUse = altName
                            itemData = altData
                            curVal = altData.Value
                            substituted = substituted + 1
                            break
                        end
                    end
                    -- If exact family substitute is depleted, fall back to solid structural block (painted in Phase 3)
                    if curVal <= 0 and State.Build_AutoSubstitute then
                        local fallback = getBestFallback()
                        blockToUse = fallback
                        itemData = LocalPlayer.Data:FindFirstChild(blockToUse)
                        curVal = itemData and itemData.Value or 0
                        if curVal > 0 then
                            substituted = substituted + 1
                        end
                    end
                elseif State.Build_AutoSubstitute then
                    local fallback = getBestFallback()
                    blockToUse = fallback
                    itemData = LocalPlayer.Data:FindFirstChild(blockToUse)
                    curVal = itemData and itemData.Value or 0
                    if curVal > 0 then
                        substituted = substituted + 1
                    end
                end

                if curVal <= 0 then
                    skipped = skipped + 1
                    continue
                end
            end

            -- Place real server block directly via RF (Fast & Silent)
            local success, err = pcall(function()
                return bRF:InvokeServer(blockToUse, curVal, myZone, relToZone, isAnchored, worldCF, nil, true)
            end)

            if not success then
                task.wait(0.02)
                pcall(function()
                    bRF:InvokeServer(blockToUse, curVal, myZone, relToZone, isAnchored, worldCF, nil, true)
                end)
            end

            table.insert(metaList, {
                blockName = blockToUse,
                worldCF = worldCF,
                targetPos = worldCF.Position,
                size = block.Size and Vector3.new(unpack(block.Size)) or nil,
                color = block.Color and Color3.new(unpack(block.Color)) or nil,
                transparency = block.Transparency,
                canCollide = block.CanCollide,
                castShadow = block.CastShadow
            })
            count = count + 1

            task.wait(0.015)
        end

        -- Allow server replication to settle
        task.wait(0.25)
        if conn then conn:Disconnect() end

        local finalBlockCount = myBlocks and #myBlocks:GetChildren() or 0

        -- 2-Pass Robust Spatial & BlockType Matching (Zero color/size scramble)
        local allChildren = myBlocks and myBlocks:GetChildren() or {}
        local used = {}
        local matched = {}

        for _, meta in ipairs(metaList) do
            local bestBlk = nil
            local bestDist = 9999

            -- Pass 1: Match by exact block model name and closest coordinate
            for _, blk in ipairs(allChildren) do
                if not used[blk] and blk.Name == meta.blockName then
                    local p = blk:FindFirstChild("PPart") or blk:FindFirstChildWhichIsA("BasePart")
                    if p then
                        local d = (p.Position - meta.targetPos).Magnitude
                        if d < bestDist then
                            bestDist = d
                            bestBlk = blk
                        end
                    end
                end
            end

            -- Pass 2: If substituted, match closest unused block
            if not bestBlk or bestDist > 3.5 then
                for _, blk in ipairs(allChildren) do
                    if not used[blk] then
                        local p = blk:FindFirstChild("PPart") or blk:FindFirstChildWhichIsA("BasePart")
                        if p then
                            local d = (p.Position - meta.targetPos).Magnitude
                            if d < bestDist then
                                bestDist = d
                                bestBlk = blk
                            end
                        end
                    end
                end
            end

            if bestBlk then
                used[bestBlk] = true
                table.insert(matched, {
                    block = bestBlk,
                    size = meta.size,
                    worldCF = meta.worldCF,
                    color = meta.color,
                    transparency = meta.transparency,
                    canCollide = meta.canCollide,
                    castShadow = meta.castShadow
                })
            end
        end

        -- Phase 2: Silent Remote Scaling (Zero Tool Equipping)
        local sTool = LocalPlayer.Backpack:FindFirstChild("ScalingTool") or (char and char:FindFirstChild("ScalingTool"))
        local sRF = sTool and sTool:FindFirstChild("RF")
        local scaledCount = 0
        if sRF and #matched > 0 then
            for _, m in ipairs(matched) do
                local sz = m.size
                local p = m.block:FindFirstChild("PPart") or m.block:FindFirstChildWhichIsA("BasePart")
                local curSz = p and p.Size or Vector3.new(2, 2, 2)
                if sz and (math.abs(sz.X - curSz.X) > 0.05 or math.abs(sz.Y - curSz.Y) > 0.05 or math.abs(sz.Z - curSz.Z) > 0.05) then
                    pcall(function()
                        sRF:InvokeServer(m.block, sz, m.worldCF)
                    end)
                    scaledCount = scaledCount + 1
                    task.wait(0.015)
                end
            end
        end

        -- Phase 3: Silent Chunked Batch Painting (Zero Tool Equipping)
        local pTool = LocalPlayer.Backpack:FindFirstChild("PaintingTool") or (char and char:FindFirstChild("PaintingTool"))
        local pRF = pTool and pTool:FindFirstChild("RF")
        local paintedCount = 0
        if pRF and #matched > 0 then
            if pRF then
                local batch = {}
                for _, m in ipairs(matched) do
                    if m.color then
                        table.insert(batch, {m.block, m.color})
                    end
                end
                -- Send in safe chunks of 25 with 80ms delay for 100% server replication
                for i = 1, #batch, 25 do
                    local slice = {}
                    for j = i, math.min(i + 24, #batch) do
                        table.insert(slice, batch[j])
                    end
                    pcall(function()
                        pRF:InvokeServer(slice)
                    end)
                    paintedCount = paintedCount + #slice
                    task.wait(0.08)
                end
            end
        end

        -- Phase 4: Silent Property Configuration (Zero Tool Equipping - True BABFT Toggle & Increment Protocol)
        local propTool = LocalPlayer.Backpack:FindFirstChild("PropertiesTool") or (char and char:FindFirstChild("PropertiesTool"))
        local propRF = propTool and propTool:FindFirstChild("SetPropertieRF")
        local propCount = 0
        if propRF and #matched > 0 then

            local nonCollideModels = {}
            local noShadowModels = {}
            local unanchoredModels = {}
            local transparencyGroups = {}

            for _, m in ipairs(matched) do
                if m.canCollide == false then
                    table.insert(nonCollideModels, m.block)
                end
                if m.castShadow == false then
                    table.insert(noShadowModels, m.block)
                end
                if m.anchored == false and isAnchored then
                    table.insert(unanchoredModels, m.block)
                end
                if m.transparency and m.transparency > 0.05 then
                    local roundedT = math.floor(m.transparency * 10 + 0.5) / 10
                    transparencyGroups[roundedT] = transparencyGroups[roundedT] or {}
                    table.insert(transparencyGroups[roundedT], m.block)
                end
            end

            -- In BABFT SetPropertieRF: "Collision" is a TOGGLE. Default placed blocks have Collision=true.
            -- Invoking once with the block list cleanly toggles collision to FALSE.
            if #nonCollideModels > 0 then
                pcall(function()
                    propRF:InvokeServer("Collision", nonCollideModels)
                end)
                propCount = propCount + #nonCollideModels
                task.wait(0.08)
            end

            -- In BABFT SetPropertieRF: "Cast shadow" is a TOGGLE.
            if #noShadowModels > 0 then
                pcall(function()
                    propRF:InvokeServer("Cast shadow", noShadowModels)
                end)
                propCount = propCount + #noShadowModels
                task.wait(0.08)
            end

            -- In BABFT SetPropertieRF: "Anchor" is a TOGGLE.
            if #unanchoredModels > 0 then
                pcall(function()
                    propRF:InvokeServer("Anchor", unanchoredModels)
                end)
                task.wait(0.08)
            end

            -- In BABFT SetPropertieRF: "Transparency" increments in steps of 0.25 (0 -> 0.25 -> 0.50 -> 0.75 -> 1.0)
            for tVal, models in pairs(transparencyGroups) do
                local clicks = math.clamp(math.round(tVal / 0.25), 1, 4)
                for _ = 1, clicks do
                    pcall(function()
                        propRF:InvokeServer("Transparency", models)
                    end)
                    task.wait(0.05)
                end
                propCount = propCount + #models
                task.wait(0.05)
            end
        end

        -- Done (Tools remained in backpack silently the entire time)

        if finalBlockCount == 0 and skipped > 0 then
            Hub.Notify({
                Title = "Blueprint Incomplete",
                Content = string.format("Could not build: missing %d required materials in your inventory.", skipped),
                Duration = 5
            })
        elseif finalBlockCount == 0 then
            Hub.Notify({
                Title = "Build Failed",
                Content = "No blocks were placed on your plot. Please check tool and plot permissions.",
                Duration = 5
            })
        else
            Hub.Notify({
                Title = "Build Completed!",
                Content = string.format("Successfully built %d blocks onto plot! (Scaled: %d, Painted: %d%s)",
                    finalBlockCount, scaledCount, paintedCount,
                    skipped > 0 and (", Skipped: " .. skipped .. " missing") or ""),
                Duration = 5
            })
        end
    end)
end

Hub.CreateToggle(buildTab, "Strict Material Match (No Texture Mismatch)", State.Build_ExactMaterial, function(v)
    State.Build_ExactMaterial = v
end)

Hub.CreateToggle(buildTab, "Auto-Substitute Missing Blocks (Loose)", State.Build_AutoSubstitute, function(v)
    State.Build_AutoSubstitute = v
end)

Hub.CreateToggle(buildTab, "Build Anchored", State.Build_Anchored, function(v)
    State.Build_Anchored = v
end)

Hub.CreateButton(buildTab, "🔨 Build Stolen Ship with REAL BLOCKS", function()
    local targetName = State.SelectedTargetPlayer
    if not targetName or targetName == "No Other Players" then
        Hub.Notify({ Title = "Build Stealer", Content = "Please select a target player first!", Duration = 3 })
        return
    end

    local activeData = State.SelectedSavedBuild and SavedBuilds[State.SelectedSavedBuild]
    if not activeData or activeData.Author ~= targetName then
        Hub.Notify({ Title = "Build Stealer", Content = "Auto-exporting " .. targetName .. "'s ship...", Duration = 2 })
        activeData = exportPlayerBuild(targetName)
        if not activeData then return end
    end

    constructBuildOnMyIsland(State.SelectedSavedBuild)
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

local function getSlotExt(slotNum)
    return slotNum == 1 and "" or tostring(slotNum)
end

Hub.CreateButton(buildTab, "📥 Save Active Plot to In-Game Save Slot", function()
    pcall(function()
        local sbd = Workspace:FindFirstChild("SaveBoatData")
        if not sbd then
            Hub.Notify({ Title = "Game Saves", Content = "SaveBoatData remote not found!", Duration = 3 })
            return
        end

        local myBlocks = Workspace.Blocks:FindFirstChild(LocalPlayer.Name)
        local count = myBlocks and #myBlocks:GetChildren() or 0
        if count == 0 then
            Hub.Notify({ Title = "Game Saves", Content = "Plot is empty! Build or load blocks first before saving.", Duration = 3 })
            return
        end

        local ext = getSlotExt(State.SelectedGameSaveSlot)
        
        local savingGui = LocalPlayer.PlayerGui:FindFirstChild("SavingBoatGui")
        local savingFrame = savingGui and savingGui:FindFirstChild("Frame")
        if savingFrame then savingFrame.Visible = true end

        sbd:InvokeServer(ext)

        if savingFrame then savingFrame.Visible = false end

        local updateName = Workspace:FindFirstChild("UpdateSlotNameRE")
        if updateName then
            updateName:FireServer(ext, "UnknownHub_Slot" .. tostring(State.SelectedGameSaveSlot))
        end

        Hub.Notify({ Title = "Game Saves", Content = string.format("Successfully saved %d blocks to Slot %d!", count, State.SelectedGameSaveSlot), Duration = 3 })
    end)
end)

Hub.CreateButton(buildTab, "⚡ Instant Load Slot (Bypass Build Timer)", function()
    pcall(function()
        local ext = getSlotExt(State.SelectedGameSaveSlot)
        local instaLoad = Workspace:FindFirstChild("InstaLoadFunction")
        if instaLoad then
            instaLoad:InvokeServer(ext)
            Hub.Notify({ Title = "Game Saves", Content = "Instant loaded Slot " .. tostring(State.SelectedGameSaveSlot) .. "!", Duration = 2 })
        else
            local loadRE = Workspace:FindFirstChild("LoadBoatData")
            if loadRE then
                loadRE:FireServer(ext, 0)
                Hub.Notify({ Title = "Game Saves", Content = "Loading Slot " .. tostring(State.SelectedGameSaveSlot) .. "...", Duration = 2 })
            end
        end
    end)
end)

-- =========================================================================
-- TAB 3: SECRET TELEPORTS & EASTER EGGS
-- =========================================================================

-- =========================================================================
-- SAVES DUPLICATOR (INFINITE EMPTY SAVE SLOTS)
-- =========================================================================
Hub.CreateSection(buildTab, "SAVED BUILDS & INFINITE SLOTS DUPLICATOR")

local function duplicateNativeSaveSlot()
    local shopGui = LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("ShopGui")
    local slotsFrame = shopGui and shopGui.MainFrame.TabFrame:FindFirstChild("SlotsFrame")
    local scroll = slotsFrame and slotsFrame:FindFirstChild("ScrollingFrameSlots")
    local template = scroll and scroll:FindFirstChild("BoatSlotTemplate")

    if not scroll or not template then
        Hub.Notify({ Title = "Saves Duplicator", Content = "SlotsFrame not found in ShopGui!", Duration = 3 })
        return
    end

    local maxSlot = 3
    for _, c in ipairs(scroll:GetChildren()) do
        if c:IsA("ImageButton") and c.Name:find("BoatSlot") then
            local num = tonumber(c.Name:match("%d+"))
            if num and num < 100000 and num > maxSlot then
                maxSlot = num
            end
        end
    end
    local newSlotNum = maxSlot + 1

    local otherData = LocalPlayer:FindFirstChild("OtherData")
    if otherData then
        local slotVal = otherData:FindFirstChild("Slot" .. newSlotNum)
        if not slotVal then
            slotVal = Instance.new("IntValue")
            slotVal.Name = "Slot" .. newSlotNum
            slotVal.Value = 1
            slotVal.Parent = otherData
        end
    end

    local newSlot = template:Clone()
    newSlot.Name = "BoatSlot" .. newSlotNum
    newSlot.Visible = true
    newSlot.LayoutOrder = newSlotNum
    if newSlot:FindFirstChild("SlotName") then
        newSlot.SlotName.Text = "Empty Slot " .. newSlotNum
    end
    newSlot.Parent = scroll

    pcall(function()
        workspace.UpdateSlotNameRE:FireServer("Empty Slot " .. newSlotNum, tostring(newSlotNum))
    end)

    newSlot.MouseButton1Click:Connect(function()
        local selectedFrame = slotsFrame:FindFirstChild("SelectedFrame")
        if selectedFrame then
            selectedFrame.TextBox.Text = "What would you like to do with your build in Slot " .. newSlotNum .. "?"
            local focus = selectedFrame:FindFirstChild("FocusImage")
            if focus then
                local old = focus:FindFirstChildOfClass("ImageButton")
                if old then old:Destroy() end
                local cl = newSlot:Clone()
                cl.Size = UDim2.new(1, 0, 1, 0)
                cl.Parent = focus
            end
        end
    end)

    Hub.Notify({
        Title = "Saves Duplicated!",
        Content = string.format("Created Slot %d! Infinite empty slots ready for saving.", newSlotNum),
        Duration = 4
    })
end

Hub.CreateButton(buildTab, "➕ Duplicate / Add New Empty Save Slot", function()
    duplicateNativeSaveSlot()
end)

Hub.CreateButton(buildTab, "📁 Quick Save Current Plot to Disk Blueprint", function()
    local myBlocks = Workspace.Blocks:FindFirstChild(LocalPlayer.Name)
    if not myBlocks or #myBlocks:GetChildren() == 0 then
        Hub.Notify({ Title = "Blueprint Save", Content = "Your plot is currently empty!", Duration = 3 })
        return
    end
    local myTeam = LocalPlayer.Team
    local myTeamColor = myTeam and myTeam.TeamColor.Name
    local myZone = myTeamColor and Workspace:FindFirstChild(myTeamColor .. "Zone")
    if not myZone then return end
    local myDockCF = getZoneDockCF(myZone)

    local buildData = {
        Author = LocalPlayer.Name,
        ExportTime = os.date("%X"),
        BlockCount = 0,
        Blocks = {}
    }

    for _, model in ipairs(myBlocks:GetChildren()) do
        local ppart = model:FindFirstChild("PPart") or model:FindFirstChildWhichIsA("BasePart")
        if ppart then
            local rel = myDockCF:ToObjectSpace(ppart.CFrame)
            table.insert(buildData.Blocks, {
                Name = model.Name,
                RelativeCF = {rel:GetComponents()},
                Size = {ppart.Size.X, ppart.Size.Y, ppart.Size.Z},
                Color = {ppart.Color.R, ppart.Color.G, ppart.Color.B},
                Material = tostring(ppart.Material):gsub("Enum.Material.", ""),
                Transparency = ppart.Transparency,
                CanCollide = ppart.CanCollide,
                CastShadow = ppart.CastShadow
            })
            buildData.BlockCount = buildData.BlockCount + 1
        end
    end

    local saveName = "Plot_Save_" .. os.date("%Y%m%d_%H%M%S")
    SavedBuilds[saveName] = buildData
    State.SelectedSavedBuild = saveName

    pcall(function()
        if writefile and makefolder then
            makefolder("BABFT_Builds")
            writefile("BABFT_Builds/" .. saveName .. ".json", HttpService:JSONEncode(buildData))
        end
    end)

    Hub.Notify({
        Title = "Blueprint Saved!",
        Content = string.format("Saved %d blocks to '%s'!", buildData.BlockCount, saveName),
        Duration = 4
    })
end)

-- =========================================================================
-- 3D MODEL AUTO-BUILDER (BLENDER / ROBLOX STUDIO EXPORTS)
-- =========================================================================
Hub.CreateSection(buildTab, "🏗️ 3D MODEL AUTO-BUILDER (BLENDER / STUDIO EXPORTS)")

local function getAvailableModelFiles()
    local files = {}
    local folders = {"UnknownHub\\BABFT-models", "UnknownHub/BABFT-models", "BABFT-models"}
    if listfiles then
        for _, fld in ipairs(folders) do
            local success, list = pcall(function() return listfiles(fld) end)
            if success and list then
                for _, f in ipairs(list) do
                    local fn = f:match("([^\\/]+)$")
                    if fn and (fn:find("%.obj$") or fn:find("%.json$")) then
                        table.insert(files, f)
                    end
                end
            end
        end
    end
    if #files == 0 then
        table.insert(files, "UnknownHub/BABFT-models/Example_Starship.json")
        table.insert(files, "UnknownHub/BABFT-models/Example_Pyramid.obj")
    end
    return files
end

local modelFilesList = getAvailableModelFiles()
State.AutoBuilder_File = modelFilesList[1] or ""

local modelDropdown = Hub.CreateDropdown(buildTab, "Select Model File", modelFilesList, State.AutoBuilder_File, function(sel)
    State.AutoBuilder_File = sel
end)

Hub.CreateButton(buildTab, "🔄 Refresh Model Files List", function()
    local fresh = getAvailableModelFiles()
    if modelDropdown and modelDropdown.Refresh then
        modelDropdown.Refresh(fresh)
        State.AutoBuilder_File = fresh[1] or ""
        if modelDropdown.Set then modelDropdown.Set(fresh[1] or "") end
    end
    Hub.Notify({ Title = "Auto Builder", Content = "Found " .. #fresh .. " model files in BABFT-models!", Duration = 2 })
end)

Hub.CreateSlider(buildTab, "Voxel Resolution (Studs per Block)", 1, 8, State.AutoBuilder_Resolution or 2, function(val)
    State.AutoBuilder_Resolution = val
end)

Hub.CreateToggle(buildTab, "Greedy Meshing (Merge Scaled Blocks)", State.AutoBuilder_GreedyMeshing ~= false, function(v)
    State.AutoBuilder_GreedyMeshing = v
end)

Hub.CreateToggle(buildTab, "Solid Infill (Fill Interior)", State.AutoBuilder_Solid or false, function(v)
    State.AutoBuilder_Solid = v
end)

local BUILDER_MATERIALS = {
    "TitaniumBlock",
    "ObsidianBlock",
    "PlasticBlock",
    "SmoothWoodBlock",
    "WoodBlock",
    "NeonBlock",
    "ConcreteBlock",
    "GlassBlock",
    "IceBlock",
    "GoldBlock",
    "MarbleBlock",
    "BrickBlock"
}

Hub.CreateDropdown(buildTab, "Default Construction Material", BUILDER_MATERIALS, State.AutoBuilder_Material or "TitaniumBlock", function(sel)
    State.AutoBuilder_Material = sel
end)

local function parseObjModel(content, resolution, greedy, solid, defaultMaterial)
    resolution = resolution or 2
    local vertices = {}
    local faces = {}
    local minV = Vector3.new(math.huge, math.huge, math.huge)
    local maxV = Vector3.new(-math.huge, -math.huge, -math.huge)

    for line in content:gmatch("[^\r\n]+") do
        local parts = {}
        for p in line:gmatch("%S+") do table.insert(parts, p) end
        if parts[1] == "v" and #parts >= 4 then
            local x = tonumber(parts[2]) or 0
            local y = tonumber(parts[3]) or 0
            local z = tonumber(parts[4]) or 0
            local v = Vector3.new(x, y, z)
            table.insert(vertices, v)
            minV = minV:Min(v)
            maxV = maxV:Max(v)
        elseif parts[1] == "f" and #parts >= 4 then
            local f = {}
            for i = 2, #parts do
                local idx = tonumber(parts[i]:match("^(%d+)"))
                if idx then table.insert(f, idx) end
            end
            if #f >= 3 then table.insert(faces, f) end
        end
    end

    if #vertices == 0 then return nil end

    local size = maxV - minV
    local maxDim = math.max(size.X, size.Y, size.Z)
    local scaleFactor = 1.0
    if maxDim > 80 then
        scaleFactor = 80 / maxDim
    elseif maxDim < 10 then
        scaleFactor = 20 / math.max(maxDim, 1)
    end

    local grid = {}
    local function setGrid(x, y, z)
        if not grid[x] then grid[x] = {} end
        if not grid[x][y] then grid[x][y] = {} end
        grid[x][y][z] = true
    end

    local minG = Vector3.new(math.huge, math.huge, math.huge)
    local maxG = Vector3.new(-math.huge, -math.huge, -math.huge)

    for _, f in ipairs(faces) do
        local v1 = (vertices[f[1]] - minV) * scaleFactor
        local v2 = (vertices[f[2]] - minV) * scaleFactor
        local v3 = (vertices[f[3]] - minV) * scaleFactor

        local steps = math.max(math.ceil((v2 - v1).Magnitude / resolution), 1)
        for s = 0, steps do
            local pA = v1:Lerp(v2, s / steps)
            local pB = v1:Lerp(v3, s / steps)
            local subSteps = math.max(math.ceil((pB - pA).Magnitude / resolution), 1)
            for ss = 0, subSteps do
                local pt = pA:Lerp(pB, ss / subSteps)
                local gx = math.floor(pt.X / resolution)
                local gy = math.floor(pt.Y / resolution)
                local gz = math.floor(pt.Z / resolution)
                setGrid(gx, gy, gz)
                minG = minG:Min(Vector3.new(gx, gy, gz))
                maxG = maxG:Max(Vector3.new(gx, gy, gz))
            end
        end
    end

    local blocks = {}
    local centerGX = (minG.X + maxG.X) / 2
    local centerGZ = (minG.Z + maxG.Z) / 2
    local groundGY = minG.Y

    if greedy then
        local visited = {}
        for y = minG.Y, maxG.Y do
            for z = minG.Z, maxG.Z do
                local startX = nil
                local runLen = 0
                for x = minG.X, maxG.X + 1 do
                    if grid[x] and grid[x][y] and grid[x][y][z] and not (visited[x] and visited[x][y] and visited[x][y][z]) then
                        if not startX then startX = x end
                        runLen = runLen + 1
                    else
                        if startX and runLen > 0 then
                            local relX = (startX + (runLen - 1) / 2 - centerGX) * resolution
                            local relY = (y - groundGY) * resolution + resolution / 2
                            local relZ = (z - centerGZ) * resolution
                            local blkSize = Vector3.new(runLen * resolution, resolution, resolution)
                            local cf = CFrame.new(relX, relY, relZ)

                            table.insert(blocks, {
                                Name = defaultMaterial,
                                RelativeCF = {cf:GetComponents()},
                                Size = {blkSize.X, blkSize.Y, blkSize.Z},
                                Color = {0.8, 0.8, 0.85},
                                Material = "Metal",
                                Transparency = 0,
                                CanCollide = true,
                                CastShadow = true
                            })

                            for markX = startX, startX + runLen - 1 do
                                if not visited[markX] then visited[markX] = {} end
                                if not visited[markX][y] then visited[markX][y] = {} end
                                visited[markX][y][z] = true
                            end
                            startX = nil
                            runLen = 0
                        end
                    end
                end
            end
        end
    else
        for x = minG.X, maxG.X do
            for y = minG.Y, maxG.Y do
                for z = minG.Z, maxG.Z do
                    if grid[x] and grid[x][y] and grid[x][y][z] then
                        local relX = (x - centerGX) * resolution
                        local relY = (y - groundGY) * resolution + resolution / 2
                        local relZ = (z - centerGZ) * resolution
                        local cf = CFrame.new(relX, relY, relZ)
                        table.insert(blocks, {
                            Name = defaultMaterial,
                            RelativeCF = {cf:GetComponents()},
                            Size = {resolution, resolution, resolution},
                            Color = {0.8, 0.8, 0.85},
                            Material = "Metal",
                            Transparency = 0,
                            CanCollide = true,
                            CastShadow = true
                        })
                    end
                end
            end
        end
    end

    return {
        Name = "Imported_OBJ",
        Author = "Blender/Studio",
        BlockCount = #blocks,
        Blocks = blocks
    }
end

Hub.CreateButton(buildTab, "🔨 Import & Construct Selected 3D Model", function()
    local path = State.AutoBuilder_File
    if not path or #path == 0 then
        Hub.Notify({ Title = "Auto Builder", Content = "Please select a model file first!", Duration = 3 })
        return
    end

    local content = nil
    pcall(function()
        if readfile then
            content = readfile(path)
        end
    end)

    if not content or #content == 0 then
        Hub.Notify({ Title = "Auto Builder", Content = "Could not read model file: " .. tostring(path), Duration = 3 })
        return
    end

    local buildData = nil
    if path:find("%.obj$") then
        buildData = parseObjModel(
            content,
            State.AutoBuilder_Resolution or 2,
            State.AutoBuilder_GreedyMeshing ~= false,
            State.AutoBuilder_Solid or false,
            State.AutoBuilder_Material or "TitaniumBlock"
        )
    else
        local ok, parsed = pcall(function() return HttpService:JSONDecode(content) end)
        if ok and parsed then
            if parsed.Blocks then
                buildData = parsed
            elseif parsed.parts or typeof(parsed) == "table" then
                local blist = {}
                local rawList = parsed.Blocks or parsed.parts or parsed
                for _, b in ipairs(rawList) do
                    if b.Name then table.insert(blist, b) end
                end
                buildData = {
                    Name = parsed.Name or "Studio_Import",
                    Author = "Roblox Studio",
                    BlockCount = #blist,
                    Blocks = blist
                }
            end
        end
    end

    if not buildData or not buildData.Blocks or #buildData.Blocks == 0 then
        Hub.Notify({ Title = "Auto Builder", Content = "Failed to parse blocks from model file!", Duration = 3 })
        return
    end

    local saveKey = "Imported_" .. (buildData.Name or "Model") .. "_" .. tostring(#buildData.Blocks) .. "blks"
    SavedBuilds[saveKey] = buildData
    State.SelectedSavedBuild = saveKey

    local missing = checkBuildMissingBlocks(buildData)
    if #missing > 0 then
        showMissingBlocksHUD(missing)
    end

    Hub.Notify({
        Title = "Model Imported!",
        Content = string.format("Imported %d blocks from %s! Constructing onto plot...", #buildData.Blocks, path:match("([^\\/]+)$") or path),
        Duration = 4
    })

    constructBuildOnMyIsland(saveKey, false)
end)

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

Hub.CreateSection(teleTab, "EXPIRED EVENTS & SECRET ROOMS")

Hub.CreateButton(teleTab, "🎄 Expired Gingerbread & Christmas Village", function()
    safeTeleport(CFrame.new(-54, 50, 4200), "Gingerbread Village")
end)

Hub.CreateButton(teleTab, "🎃 Expired Halloween Witch / Cauldron Stage", function()
    safeTeleport(CFrame.new(-54, 50, 5800), "Halloween Cauldron")
end)

Hub.CreateButton(teleTab, "⚔️ Expired RB Battles Secret Room", function()
    safeTeleport(CFrame.new(-54, -300, 9485), "RB Battles Room")
end)

Hub.CreateButton(teleTab, "🥚 Expired Egg Hunt Stage & Giant Tree", function()
    safeTeleport(CFrame.new(180, 50, 2200), "Egg Hunt Stage")
end)

Hub.CreateButton(teleTab, "⚙️ The Clock Room (GearStage Secret Door)", function()
    safeTeleport(CFrame.new(195, 45, 1420), "Clock Room")
end)

Hub.CreateButton(teleTab, "🍞 Bakery Oven Secret Room", function()
    safeTeleport(CFrame.new(-180, 40, 2800), "Bakery Oven")
end)

Hub.CreateButton(teleTab, "🤠 Wild West Secret Saloon", function()
    safeTeleport(CFrame.new(210, 45, 3400), "Wild West Saloon")
end)

Hub.CreateButton(teleTab, "🏺 Egyptian Sphinx & Pharaoh Chamber", function()
    safeTeleport(CFrame.new(-220, 50, 4900), "Egyptian Sphinx")
end)

Hub.CreateSection(teleTab, "EASTER EGGS & CLASSIC SECRETS")

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
        if hum then
            pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false) end)
            if hum.Health > 0 and hum.Health < 100 then
                hum.Health = 100
            end
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
                            if desc:IsA("BasePart") and desc.Name ~= "Trigger" and (desc.Name:find("Rock") or desc.Name:find("Spike") or desc.Name:find("Lava") or desc.Name:find("Point") or desc.Name:find("Destroy") or desc.Name:find("Water")) then
                                desc.CanTouch = false
                                desc.CanCollide = false
                                local tt = desc:FindFirstChildWhichIsA("TouchTransmitter")
                                if tt then pcall(function() tt:Destroy() end) end
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

local waterPlatform = Instance.new("Part")
waterPlatform.Name = "UnknownWaterPlatform"
waterPlatform.Size = Vector3.new(36, 2, 36)
waterPlatform.Transparency = 1
waterPlatform.Anchored = true
waterPlatform.CanCollide = true
waterPlatform.CanTouch = false

RunService.RenderStepped:Connect(function()
    if State.WalkOnWater then
        local root = getRoot()
        if root then
            waterPlatform.Parent = Workspace
            -- River water top surface is at Y = -12.9; platform center at -13.9 puts top surface flush at -12.9
            waterPlatform.CFrame = CFrame.new(root.Position.X, -13.9, root.Position.Z)
        elseif waterPlatform.Parent then
            waterPlatform.Parent = nil
        end
    elseif waterPlatform.Parent then
        waterPlatform.Parent = nil
    end
end)

Hub.CreateToggle(opTab, "🌊 Walk on Water", State.WalkOnWater, function(v)
    State.WalkOnWater = v
    if not v and waterPlatform.Parent then
        waterPlatform.Parent = nil
    end
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


Hub.CreateSection(shopTab, "🎃 EXPIRED & EVENT EXCLUSIVE PURCHASES")

local EXPIRED_SHOP_ITEMS = {
    { Name = "🐉 +5 Dragon Harpoons", Item = "+5 Dragon Harpoons" },
    { Name = "🥚 +3 Egg Cannons", Item = "+3 Egg Cannons" },
    { Name = "⚡ +5 Duel Harpoons", Item = "+5 Duel Harpoons" },
    { Name = "🍪 +4 Cookie Wheels", Item = "+4 Cookie Wheels" },
    { Name = "🎃 Jack-O-Lantern Block", Item = "JackOLantern" },
    { Name = "🕯️ Candle Block", Item = "Candle" },
    { Name = "🧸 Toy Block", Item = "ToyBlock" },
    { Name = "🍬 Mint Wheels", Item = "MintWheels" },
    { Name = "❄️ Snowball Turret", Item = "SnowballTurret" },
    { Name = "🎆 Firework A", Item = "FireworkA" },
    { Name = "🎆 Firework B", Item = "FireworkB" },
    { Name = "🎆 Firework C", Item = "FireworkC" },
    { Name = "🎆 Firework D", Item = "FireworkD" },
    { Name = "🦊 Fox Character", Item = "Fox Character" },
    { Name = "🐧 Penguin Character", Item = "Penguin Character" },
    { Name = "🌀 +4 Portals", Item = "+4 Portals" },
    { Name = "🛡️ Shield Generators", Item = "Shield Generators" },
    { Name = "🚀 +3 Ultra Jetpacks", Item = "+3 Ultra Jetpacks" },
    { Name = "⚡ +5 Ultra Thrusters", Item = "+5 Ultra Thrusters" },
    { Name = "🏎️ Legacy Car Pack", Item = "LegacyCarPack" },
    { Name = "💥 Sticks Of TNT", Item = "SticksOfTNT" }
}

for _, it in ipairs(EXPIRED_SHOP_ITEMS) do
    Hub.CreateButton(shopTab, "Buy " .. it.Name, function()
        pcall(function()
            local rf = Workspace:FindFirstChild("ItemBoughtFromShop")
            if rf then
                rf:InvokeServer(it.Item, 1)
            end
        end)
        Hub.Notify({ Title = "Shop", Content = "Sent purchase request for " .. it.Item .. "!", Duration = 2 })
    end)
end

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
