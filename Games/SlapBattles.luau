
local LIBRARY_LINK = "https://raw.githubusercontent.com/UnknownHQ/UnknownHub/main/UnknownLibrary"
local LIBRARY_NAME = "ENI_TabbedHub_UI"

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local VirtualUser = game:GetService("VirtualUser")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

-- =========================================================================
-- Built-in Anti-AFK (Prevents 20-minute Roblox Disconnect during AFK grinds)
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

local function destroyOldGui()
    local parents = {game:GetService("CoreGui")}
    if gethui then pcall(function() table.insert(parents, gethui()) end) end
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if playerGui then table.insert(parents, playerGui) end
    for _, parent in ipairs(parents) do
        if parent then
            for _, child in ipairs(parent:GetChildren()) do
                if child:IsA("ScreenGui") and child.Name == LIBRARY_NAME then
                    pcall(function() child:Destroy() end)
                end
            end
        end
    end
end

-- =========================================================================
-- Guide Boss Place Detection & Small GUI
-- =========================================================================
local GUIDE_BOSS_PLACE_IDS = {
    [18550498098] = true,
    [18247261893] = true,
    [17308778061] = true
}

local function isInGuideBossPlace()
    if GUIDE_BOSS_PLACE_IDS[game.PlaceId] then return true end
    if Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Components") and Workspace.Map.Components:FindFirstChild("GuideArenaCenter") then
        return true
    end
    if Workspace:FindFirstChild("ActivateStuffValues") and Workspace.ActivateStuffValues:FindFirstChild("Gate1Doors") then
        return true
    end
    return false
end

local function getCharacter(player)
    player = player or LocalPlayer
    return player and player.Character
end

local function getRoot(player)
    local char = getCharacter(player)
    return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
end

local function getHumanoid(player)
    local char = getCharacter(player)
    return char and char:FindFirstChildWhichIsA("Humanoid")
end

local function createSmallGuideBossGui()
    local guiParent = (gethui and gethui()) or (LocalPlayer and (LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui"))) or (pcall(function() return game:GetService("CoreGui") end) and game:GetService("CoreGui"))
    
    for _, old in ipairs(guiParent:GetChildren()) do
        if old.Name == "ENI_GuideBoss_UI" or old.Name == LIBRARY_NAME then
            pcall(function() old:Destroy() end)
        end
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ENI_GuideBoss_UI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = guiParent

    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 320, 0, 185)
    mainFrame.Position = UDim2.new(0.5, -160, 0.5, -92)
    mainFrame.BackgroundColor3 = Color3.fromRGB(15, 17, 24)
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = mainFrame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 120, 0)
    stroke.Thickness = 1.5
    stroke.Parent = mainFrame

    -- Header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 38)
    header.BackgroundColor3 = Color3.fromRGB(22, 25, 36)
    header.BorderSizePixel = 0
    header.Parent = mainFrame

    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 10)
    headerCorner.Parent = header

    local filler = Instance.new("Frame")
    filler.Size = UDim2.new(1, 0, 0, 10)
    filler.Position = UDim2.new(0, 0, 1, -10)
    filler.BackgroundColor3 = Color3.fromRGB(22, 25, 36)
    filler.BorderSizePixel = 0
    filler.Parent = header

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -20, 1, 0)
    title.Position = UDim2.new(0, 14, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "UNKNOWN HUB • GUIDE BOSS"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 13
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header

    local selectedOutcome = "Save"

    local selectLabel = Instance.new("TextLabel")
    selectLabel.Size = UDim2.new(1, -28, 0, 20)
    selectLabel.Position = UDim2.new(0, 14, 0, 44)
    selectLabel.BackgroundTransparency = 1
    selectLabel.Text = "SELECT OUTCOME:"
    selectLabel.TextColor3 = Color3.fromRGB(160, 170, 190)
    selectLabel.Font = Enum.Font.GothamBold
    selectLabel.TextSize = 11
    selectLabel.TextXAlignment = Enum.TextXAlignment.Left
    selectLabel.Parent = mainFrame

    local buttonContainer = Instance.new("Frame")
    buttonContainer.Size = UDim2.new(1, -28, 0, 32)
    buttonContainer.Position = UDim2.new(0, 14, 0, 64)
    buttonContainer.BackgroundColor3 = Color3.fromRGB(20, 23, 32)
    buttonContainer.BorderSizePixel = 0
    buttonContainer.Parent = mainFrame

    local bcCorner = Instance.new("UICorner")
    bcCorner.CornerRadius = UDim.new(0, 6)
    bcCorner.Parent = buttonContainer

    local saveBtn = Instance.new("TextButton")
    saveBtn.Size = UDim2.new(0.5, -3, 1, -4)
    saveBtn.Position = UDim2.new(0, 2, 0, 2)
    saveBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 90)
    saveBtn.Text = "🤝 SAVE (Relude)"
    saveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    saveBtn.Font = Enum.Font.GothamBold
    saveBtn.TextSize = 11
    saveBtn.Parent = buttonContainer

    local saveCorner = Instance.new("UICorner")
    saveCorner.CornerRadius = UDim.new(0, 5)
    saveCorner.Parent = saveBtn

    local killBtn = Instance.new("TextButton")
    killBtn.Size = UDim2.new(0.5, -3, 1, -4)
    killBtn.Position = UDim2.new(0.5, 1, 0, 2)
    killBtn.BackgroundColor3 = Color3.fromRGB(30, 34, 48)
    killBtn.Text = "💀 KILL (Hunter)"
    killBtn.TextColor3 = Color3.fromRGB(150, 160, 180)
    killBtn.Font = Enum.Font.GothamBold
    killBtn.TextSize = 11
    killBtn.Parent = buttonContainer

    local killCorner = Instance.new("UICorner")
    killCorner.CornerRadius = UDim.new(0, 5)
    killCorner.Parent = killBtn

    local function updateSelection(choice)
        selectedOutcome = choice
        if choice == "Save" then
            saveBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 90)
            saveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            killBtn.BackgroundColor3 = Color3.fromRGB(30, 34, 48)
            killBtn.TextColor3 = Color3.fromRGB(150, 160, 180)
        else
            killBtn.BackgroundColor3 = Color3.fromRGB(210, 40, 40)
            killBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            saveBtn.BackgroundColor3 = Color3.fromRGB(30, 34, 48)
            saveBtn.TextColor3 = Color3.fromRGB(150, 160, 180)
        end
    end

    saveBtn.MouseButton1Click:Connect(function() updateSelection("Save") end)
    killBtn.MouseButton1Click:Connect(function() updateSelection("Kill") end)

    local statusLbl = Instance.new("TextLabel")
    statusLbl.Size = UDim2.new(1, -28, 0, 20)
    statusLbl.Position = UDim2.new(0, 14, 0, 104)
    statusLbl.BackgroundTransparency = 1
    statusLbl.Text = "Status: Ready (Slap Aura & Reach Embedded)"
    statusLbl.TextColor3 = Color3.fromRGB(140, 150, 170)
    statusLbl.Font = Enum.Font.GothamMedium
    statusLbl.TextSize = 11
    statusLbl.TextXAlignment = Enum.TextXAlignment.Center
    statusLbl.Parent = mainFrame

    local autoBtn = Instance.new("TextButton")
    autoBtn.Size = UDim2.new(1, -28, 0, 42)
    autoBtn.Position = UDim2.new(0, 14, 0, 128)
    autoBtn.BackgroundColor3 = Color3.fromRGB(255, 120, 0)
    autoBtn.Text = "⚡ AUTO COMPLETE MAZE & BOSS"
    autoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    autoBtn.Font = Enum.Font.GothamBold
    autoBtn.TextSize = 12
    autoBtn.Parent = mainFrame

    local autoCorner = Instance.new("UICorner")
    autoCorner.CornerRadius = UDim.new(0, 7)
    autoCorner.Parent = autoBtn

    local godmodeActive = false
    local godmodeConn = nil

    local function purgeAllHazards()
        pcall(function()
            if Workspace:FindFirstChild("ChaserFog") then Workspace.ChaserFog:Destroy() end
            if Workspace:FindFirstChild("DeathBricks") then Workspace.DeathBricks:Destroy() end
            if Workspace:FindFirstChild("Gate1ChaserTerryModel") then Workspace.Gate1ChaserTerryModel:Destroy() end
            
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("BasePart") then
                    local name = obj.Name:lower()
                    if name == "bossbattledeathpart" or name == "deathbrick" or name == "deathpart" or name == "killpart" or name == "laserdeath" then
                        obj.CanTouch = false
                        obj.CanCollide = false
                        pcall(function() obj:Destroy() end)
                    end
                end
            end

            local mapComp = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Components")
            if mapComp then
                if mapComp:FindFirstChild("Lasers") then mapComp.Lasers:Destroy() end
                if mapComp:FindFirstChild("BossBattleDeathPart") then mapComp.BossBattleDeathPart:Destroy() end
                if mapComp:FindFirstChild("FallingDebris") then mapComp.FallingDebris:Destroy() end
            end
            local gEffect = Lighting:FindFirstChild("GreenTheScreenEffect")
            if gEffect then gEffect:Destroy() end
        end)
    end

    local Lighting = game:GetService("Lighting")
    Lighting.ChildAdded:Connect(function(child)
        if child.Name == "GreenTheScreenEffect" then
            task.defer(function()
                pcall(function() child:Destroy() end)
            end)
        end
    end)

    local function enableGodmode()
        godmodeActive = true
        if godmodeConn then godmodeConn:Disconnect() end

        godmodeConn = RunService.Heartbeat:Connect(function()
            if not godmodeActive then return end
            purgeAllHazards()
            local hum = getHumanoid()
            local char = getCharacter()
            if hum then
                pcall(function()
                    hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
                    hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
                    hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
                    if hum.Health < 3 and hum.Health > 0 then
                        hum.Health = 3
                    end
                end)
            end
            if char then
                for _, emitter in ipairs(char:GetDescendants()) do
                    if emitter:IsA("ParticleEmitter") or emitter:IsA("Beam") or emitter:IsA("Trail") or emitter:IsA("PointLight") or emitter:IsA("Highlight") then
                        emitter.Enabled = false
                    end
                end
            end
        end)
    end

    -- Continuous Core Slap Aura & Boss Combat Engine (Always ON Permanently)
    task.spawn(function()
        while true do
            task.wait(0.03)
            local char = getCharacter()
            local root = getRoot()
            local tool = (char and char:FindFirstChildWhichIsA("Tool")) or (LocalPlayer.Backpack:FindFirstChildWhichIsA("Tool"))
            
            if tool and char and root then
                local glove = tool:FindFirstChild("Glove")
                if glove then
                    if glove.Size.X < 80 then
                        pcall(function()
                            glove.Size = Vector3.new(100, 100, 100)
                            glove.CanCollide = false
                            glove.Massless = true
                            glove.Transparency = 1
                        end)
                    end
                    for _, effect in ipairs(glove:GetDescendants()) do
                        if effect:IsA("ParticleEmitter") or effect:IsA("Beam") or effect:IsA("Trail") or effect:IsA("PointLight") or effect:IsA("Highlight") then
                            effect.Enabled = false
                        end
                    end
                end

                local hasNetwork = tool:FindFirstChild("Network")

                -- Silent Instant Network Slap (No blinding particle bursts)
                local function hitTarget(targetPart)
                    if not targetPart or not targetPart:IsA("BasePart") then return end
                    if tool.Parent ~= char then
                        tool.Parent = char
                    end
                    pcall(function()
                        if hasNetwork then
                            tool.Network:FireServer("Hit", targetPart)
                        end
                        if glove and firetouchinterest then
                            firetouchinterest(glove, targetPart, 0)
                            firetouchinterest(glove, targetPart, 1)
                        end
                    end)
                end

                -- 1. Deflect All Flying Missiles across arena
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA("BasePart") and (obj:GetAttribute("TrackGloveMissile") == true or obj.Name == "TrackGloveMissile" or obj.Name:lower():find("missile")) then
                        local dist = (obj.Position - root.Position).Magnitude
                        if dist <= 500 then
                            hitTarget(obj)
                        end
                    end
                end

                -- 2. Slap All Hostile NPCs & Minions (ReplicaNPC, Stevem, PotatoLord, Pumpkin)
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA("Model") then
                        local oName = obj.Name
                        if oName == "ReplicaNPC" or oName == "Stevem" or oName == "PotatoLord" or oName == "Pumpkin" or oName == "Pumkin" then
                            local hum = obj:FindFirstChildWhichIsA("Humanoid")
                            local head = obj:FindFirstChild("Head") or obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChildWhichIsA("BasePart")
                            if head and (not hum or hum.Health > 0) then
                                local dist = (head.Position - root.Position).Magnitude
                                if dist <= 500 then
                                    hitTarget(head)
                                end
                            end
                        end
                    end
                end

                -- 3. Strike Dungeon Golem (All parts and limbs up to 500 studs)
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA("Model") and (obj.Name == "DungeonGolem" or obj.Name == "Golem" or obj.Name:lower():find("golem")) then
                        for _, part in ipairs(obj:GetChildren()) do
                            if part:IsA("BasePart") then
                                local dist = (part.Position - root.Position).Magnitude
                                if dist <= 500 then
                                    hitTarget(part)
                                end
                            end
                        end
                    end
                end

                -- 4. Strike Guide Boss (All parts up to 500 studs)
                local isBossActive = (Workspace:GetAttribute("GuideHealthPercent") ~= nil) or (Workspace:GetAttribute("BossName") ~= nil)
                if isBossActive then
                    for _, obj in ipairs(Workspace:GetDescendants()) do
                        if obj:IsA("Model") and (obj.Name == "GuideNPC" or obj.Name == "Guide" or obj.Name:lower():find("guidenpc")) then
                            for _, part in ipairs(obj:GetChildren()) do
                                if part:IsA("BasePart") then
                                    local dist = (part.Position - root.Position).Magnitude
                                    if dist <= 500 then
                                        hitTarget(part)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end)

    -- Infallible Multi-Method Decision Handler (Auto Spare / Kill)
    local function executeBossDecision(outcome)
        local isSave = (outcome == "Save" or outcome == "Save Guide")
        
        -- 1. Fire all candidate Decision / Cutscene remotes
        for _, remote in ipairs(ReplicatedStorage:GetDescendants()) do
            if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
                local rName = remote.Name:lower()
                if rName:find("answer") or rName:find("spare") or rName:find("eliminate") or rName:find("decision") or rName:find("cutscene") or rName:find("choice") then
                    pcall(function()
                        if remote:IsA("RemoteEvent") then
                            remote:FireServer(isSave and "Spare" or "Eliminate")
                            remote:FireServer(isSave and "Save" or "Kill")
                            remote:FireServer(isSave and "Yes" or "No")
                            remote:FireServer(isSave and true or false)
                            remote:FireServer(isSave and 1 or 2)
                        elseif remote:IsA("RemoteFunction") then
                            remote:InvokeServer(isSave and "Spare" or "Eliminate")
                            remote:InvokeServer(isSave and "Save" or "Kill")
                            remote:InvokeServer(isSave and "Yes" or "No")
                            remote:InvokeServer(isSave and true or false)
                        end
                    end)
                end
            end
        end

        -- 2. Click all buttons in PlayerGui
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        if playerGui then
            for _, btn in ipairs(playerGui:GetDescendants()) do
                if btn:IsA("TextButton") or btn:IsA("ImageButton") then
                    local bName = btn.Name:lower()
                    local bText = (btn:IsA("TextButton") and btn.Text:lower()) or ""
                    local isTarget = false

                    if isSave then
                        if bName:find("yes") or bName:find("spare") or bName:find("save") or bText:find("spare") or bText:find("save") or bText:find("yes") or bText:find("relude") then
                            isTarget = true
                        end
                    else
                        if bName:find("no") or bName:find("kill") or bName:find("eliminate") or bText:find("kill") or bText:find("eliminate") or bText:find("no") or bText:find("hunter") then
                            isTarget = true
                        end
                    end

                    if isTarget then
                        pcall(function()
                            if getconnections then
                                for _, c in ipairs(getconnections(btn.MouseButton1Click)) do c:Fire() end
                                for _, c in ipairs(getconnections(btn.Activated)) do c:Fire() end
                                for _, c in ipairs(getconnections(btn.MouseButton1Down)) do c:Fire() end
                                for _, c in ipairs(getconnections(btn.MouseButton1Up)) do c:Fire() end
                            end
                            if firesignal then
                                firesignal(btn.MouseButton1Click)
                                firesignal(btn.Activated)
                            end
                            if VirtualInputManager and btn.AbsoluteSize.X > 0 and btn.AbsoluteSize.Y > 0 then
                                local x = btn.AbsolutePosition.X + btn.AbsoluteSize.X / 2
                                local y = btn.AbsolutePosition.Y + btn.AbsoluteSize.Y / 2 + 36
                                VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 1)
                                task.wait(0.05)
                                VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 1)
                            end
                        end)
                    end
                end
            end
        end
    end

    local function executeGuideSequence()
        statusLbl.Text = "Status: Purging hazards & Solving Dungeon..."
        statusLbl.TextColor3 = Color3.fromRGB(255, 190, 0)

        enableGodmode()
        purgeAllHazards()

        local root = getRoot()
        local char = getCharacter()
        if not root or not char then
            statusLbl.Text = "Status: Character not found"
            return
        end

        root.Anchored = false
        local tool = char:FindFirstChildWhichIsA("Tool") or LocalPlayer.Backpack:FindFirstChildWhichIsA("Tool")
        if tool and tool.Parent ~= char then tool.Parent = char end

        -- Step 1: Gate 1 Lever
        local gate1Lever = Workspace:FindFirstChild("Gate1Lever")
        local g1cd = gate1Lever and gate1Lever:FindFirstChildWhichIsA("ClickDetector", true)
        local g1Part = gate1Lever and (gate1Lever:FindFirstChild("Lever", true) or gate1Lever:FindFirstChildWhichIsA("BasePart", true))
        if g1Part then root.CFrame = g1Part.CFrame end
        task.wait(0.2)
        if g1cd then pcall(function() fireclickdetector(g1cd) end) end
        if g1Part and firetouchinterest then
            pcall(function()
                firetouchinterest(root, g1Part, 0)
                firetouchinterest(root, g1Part, 1)
            end)
        end
        task.wait(0.4)

        -- Step 2: Fake Exit Lever
        local fakeExitLever = Workspace:FindFirstChild("FakeExitLever")
        local feCd = fakeExitLever and fakeExitLever:FindFirstChildWhichIsA("ClickDetector", true)
        local fePart = fakeExitLever and (fakeExitLever:FindFirstChild("Lever", true) or fakeExitLever:FindFirstChildWhichIsA("BasePart", true))
        if fePart then root.CFrame = fePart.CFrame end
        task.wait(0.2)
        if feCd then pcall(function() fireclickdetector(feCd) end) end
        if fePart and firetouchinterest then
            pcall(function()
                firetouchinterest(root, fePart, 0)
                firetouchinterest(root, fePart, 1)
            end)
        end
        task.wait(0.4)

        -- Step 3: Pressure Plate
        local pp = Workspace:FindFirstChild("pls organize") and Workspace["pls organize"]:FindFirstChild("PressurePlate")
        local ppHitbox = pp and pp:FindFirstChild("Hitbox")
        local ppPlate = pp and pp:FindFirstChild("Plate")
        if ppHitbox then
            root.CFrame = ppHitbox.CFrame + Vector3.new(0, 1.5, 0)
            if firetouchinterest then
                firetouchinterest(root, ppHitbox, 0)
                firetouchinterest(root, ppHitbox, 1)
                if ppPlate then
                    firetouchinterest(root, ppPlate, 0)
                    firetouchinterest(root, ppPlate, 1)
                end
            end
        end
        task.wait(0.4)

        -- Step 4: Train & PotatoLord Triggers
        local mapComp = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Components")
        local trainTriggers = mapComp and mapComp:FindFirstChild("TrainTriggers")
        if trainTriggers and firetouchinterest then
            for _, t in ipairs(trainTriggers:GetChildren()) do
                if t:IsA("BasePart") then
                    firetouchinterest(root, t, 0)
                    firetouchinterest(root, t, 1)
                end
            end
        end

        local potatoTrig = mapComp and mapComp:FindFirstChild("PotatoLordTrigger")
        if potatoTrig and firetouchinterest then
            firetouchinterest(root, potatoTrig, 0)
            firetouchinterest(root, potatoTrig, 1)
        end
        task.wait(0.4)

        -- Step 5: Shack Lever & Trapdoor Decontamination Room
        local shackLever = Workspace:FindFirstChild("ShackLever")
        local shackCd = shackLever and shackLever:FindFirstChildWhichIsA("ClickDetector", true)
        root.CFrame = CFrame.new(3276.26, -70.71, 822.51)
        task.wait(0.2)
        if shackCd then pcall(function() fireclickdetector(shackCd) end) end
        
        -- Stand inside the trapdoor / decontamination room
        root.CFrame = CFrame.new(3242, -70, 822.51)
        statusLbl.Text = "Status: In Shack Trapdoor Room (Waiting 11s)..."
        statusLbl.TextColor3 = Color3.fromRGB(255, 160, 0)
        task.wait(11)

        -- Step 6: Instant Teleport to Arena Floor & Trigger Cutscene
        statusLbl.Text = "Status: Teleported to Arena (Waiting 11s for Cutscene)..."
        statusLbl.TextColor3 = Color3.fromRGB(255, 120, 0)

        root.CFrame = CFrame.new(594.47, 66.5, -321.21)

        local curMapComp = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Components")
        local arenaCenter = curMapComp and curMapComp:FindFirstChild("GuideArenaCenter")
        local mainPlatform = curMapComp and curMapComp:FindFirstChild("MainPlatform")
        if arenaCenter and firetouchinterest then
            firetouchinterest(root, arenaCenter, 0)
            firetouchinterest(root, arenaCenter, 1)
        end
        if mainPlatform and firetouchinterest then
            firetouchinterest(root, mainPlatform, 0)
            firetouchinterest(root, mainPlatform, 1)
        end

        -- Step 7: Wait 11 seconds on arena floor for cutscene to complete
        task.wait(11)

        -- Step 8: Teleport to Safe Zone Platform (Y = 85)
        local arenaSkyPos = Vector3.new(594.62, 85, -321.16)
        
        -- Create elevated safe platform: white color with 75% transparency
        local existingFloor = Workspace:FindFirstChild("ENI_BossSkySafeZone")
        if existingFloor then existingFloor:Destroy() end
        local safeFloor = Instance.new("Part")
        safeFloor.Name = "ENI_BossSkySafeZone"
        safeFloor.Size = Vector3.new(100, 2, 100)
        safeFloor.CFrame = CFrame.new(arenaSkyPos.X, 84, arenaSkyPos.Z)
        safeFloor.Anchored = true
        safeFloor.Transparency = 0.75
        safeFloor.Color = Color3.fromRGB(255, 255, 255)
        safeFloor.Material = Enum.Material.SmoothPlastic
        safeFloor.CanCollide = true
        safeFloor.Parent = Workspace

        -- Stand directly on top of the safe zone surface
        local safeCFrame = CFrame.new(arenaSkyPos.X, 85 + 3.1, arenaSkyPos.Z)
        root.CFrame = safeCFrame
        root.Anchored = false

        statusLbl.Text = "Status: Boss Fight Active (Safe Zone Locked & Max Reach Aura)..."
        statusLbl.TextColor3 = Color3.fromRGB(0, 200, 255)

        local inBossFight = true

        -- Infinite Loop Safe Zone Position Keeper (Only while in Boss Fight)
        task.spawn(function()
            while inBossFight do
                task.wait()
                local curRoot = getRoot()
                if curRoot and inBossFight then
                    curRoot.CFrame = safeCFrame
                    curRoot.Velocity = Vector3.zero
                    curRoot.AssemblyLinearVelocity = Vector3.zero
                end
            end
        end)

        -- Watcher for Outcome / Cutscene / Spared Prompt & Auto Claiming
        task.spawn(function()
            for i = 1, 600 do
                task.wait(0.35)
                local hpPercent = Workspace:GetAttribute("GuideHealthPercent")
                local bName = Workspace:GetAttribute("BossName")
                if hpPercent then
                    statusLbl.Text = "Status: " .. tostring(bName or "Guide") .. " HP: " .. string.format("%.0f%%", hpPercent * 100) .. " (" .. selectedOutcome .. ")"
                end

                local hasEnded = false
                pcall(function()
                    -- Check 1: Health reached 0%
                    if hpPercent ~= nil and hpPercent <= 0.01 then
                        hasEnded = true
                    end

                    -- Check 2: PlayerGui prompt presence
                    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
                    if playerGui then
                        for _, desc in ipairs(playerGui:GetDescendants()) do
                            if desc:IsA("GuiObject") and desc.Visible then
                                local dName = desc.Name:lower()
                                if dName:find("spare") or dName:find("choice") or dName:find("decision") or dName == "spareguideprompt" then
                                    hasEnded = true
                                    break
                                end
                            end
                        end
                    end

                    -- Check 3: Reward item appeared in Workspace
                    local liveComp = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Components")
                    if Workspace:FindFirstChild("Relude", true) or (liveComp and (liveComp:FindFirstChild("Reludepoof") or liveComp:FindFirstChild("TubeBaseGlove"))) or Workspace:FindFirstChild("Hunter", true) then
                        hasEnded = true
                    end
                end)

                if hasEnded then
                    -- Execute the decision across remotes, UI connections, and VirtualInputManager
                    for _ = 1, 4 do
                        executeBossDecision(selectedOutcome)
                        task.wait(0.2)
                    end

                    inBossFight = false -- Release position lock!

                    if selectedOutcome == "Save" then
                        statusLbl.Text = "Status: Spared Guide! Claiming Relude..."
                        statusLbl.TextColor3 = Color3.fromRGB(0, 255, 120)
                    else
                        statusLbl.Text = "Status: Killed Guide! Claimed Hunter!"
                        statusLbl.TextColor3 = Color3.fromRGB(255, 70, 70)
                    end

                    task.wait(1)
                    local curRoot = getRoot()
                    if curRoot then
                        curRoot.Anchored = false
                    end

                    -- Auto-claim reward item
                    for _ = 1, 50 do
                        task.wait(0.25)
                        local curRoot2 = getRoot()
                        if not curRoot2 then break end

                        local targetReward = nil
                        local liveComp = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Components")
                        
                        if selectedOutcome == "Save" then
                            targetReward = Workspace:FindFirstChild("Relude", true)
                                or (liveComp and liveComp:FindFirstChild("Reludepoof"))
                                or (liveComp and liveComp:FindFirstChild("TubeBaseGlove"))
                        else
                            targetReward = Workspace:FindFirstChild("Hunter", true)
                                or (liveComp and liveComp:FindFirstChild("Hunter"))
                                or (liveComp and liveComp:FindFirstChild("GuideNPC"))
                        end

                        if targetReward then
                            local rPart = targetReward:IsA("BasePart") and targetReward or targetReward:FindFirstChildWhichIsA("BasePart", true)
                            if rPart then
                                curRoot2.CFrame = rPart.CFrame
                                if firetouchinterest then
                                    pcall(function()
                                        firetouchinterest(curRoot2, rPart, 0)
                                        firetouchinterest(curRoot2, rPart, 1)
                                    end)
                                end
                            end
                        end
                    end
                    break
                end
            end
        end)
    end

    autoBtn.MouseButton1Click:Connect(function()
        task.spawn(executeGuideSequence)
    end)
end

if isInGuideBossPlace() then
    createSmallGuideBossGui()
    return
end

local ok, result = pcall(function()
    local source
    local cacheBuster = "?t=" .. tostring(os.time() or tick()) .. "_" .. tostring(math.random(1000, 9999))
    source = game:HttpGet(LIBRARY_LINK .. cacheBuster)
    local factoryChunk, compileErr = loadstring(source)
    assert(factoryChunk, "the linked source did not compile: " .. tostring(compileErr))
    return factoryChunk()
end)

assert(ok and type(result) == "function", "UnknownLibrary failed to load: " .. tostring(result))

destroyOldGui()

local Hub = result({
    name = LIBRARY_NAME,
    title = "UNKNOWN HUB",
    subTitle = "Slap Battles",
    parent = (gethui and gethui()) or (LocalPlayer and (LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui"))) or (pcall(function() return game:GetService("CoreGui") end) and game:GetService("CoreGui")),
    theme = Color3.fromRGB(255, 120, 0),
    secondaryTheme = Color3.fromRGB(180, 50, 255)
})

assert(type(Hub) == "table", "UnknownLibrary returned an invalid hub")

-- =========================================================================
-- Hub Tabs
-- =========================================================================
local combatTab = Hub.createTabButton("Combat", "🥊 Combat", "rbxassetid://10723407390", true)
local badgeTab  = Hub.createTabButton("Badges", "🏆 Badges", "rbxassetid://10723407389", false)
local farmTab   = Hub.createTabButton("Farm", "⭐ Farm", "rbxassetid://10723407389", false)
local altTab    = Hub.createTabButton("AltControl", "👥 Alt Control", "rbxassetid://10723407389", false)
local defenseTab = Hub.createTabButton("Defense", "🛡️ Defense", "rbxassetid://10723407392", false)
local visualTab = Hub.createTabButton("Visuals", "👁️ Visuals", "rbxassetid://10723407395", false)

-- =========================================================================
-- State Variables
-- =========================================================================
local state = {
    SlapAura = false,
    SlapAuraDistance = 18,
    FastSlap = false,
    AntiRagdoll = false,
    AntiVoid = false,
    AntiMegarock = false,
    AntiTimestop = false,
    AutoParry = false,
    AutoCandy = false,
    AutoTycoon = false,
    AutoSlapple = false,
    AutoSlappleServerHop = true,
    PlayerESP = false,
    GloveESP = false,
    -- Auto-Gloves Grinds
    AutoMegarock = false,
    MegarockCenterLock = false,
    AutoFish = false,
    AutoTrap = false,
    AutoVoodoo = false,
    GuideBossOutcome = "Save Guide",
    TrapBrickCount = 0,
    -- Alt Control System
    IsAltAccount = false,
    MainUsername = "",
    AltFollowMain = false,
    AltFollowDistance = 4,
    AltFeedSlaps = false,
    AltAutoReenter = false,
    AltLoopSlapMain = false,
    AltAutoTPMegarock = false,
    AltAutoSafeZone = false,
    AltChatCommands = true
}

-- Safe Character Helpers
local function getCharacter(player)
    player = player or LocalPlayer
    return player and player.Character
end

local function getRoot(player)
    local char = getCharacter(player)
    return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
end

local function getHumanoid(player)
    local char = getCharacter(player)
    return char and char:FindFirstChildWhichIsA("Humanoid")
end

local function getSlapCount()
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    if leaderstats and leaderstats:FindFirstChild("Slaps") then
        return leaderstats.Slaps.Value
    end
    return 0
end

local function getCurrentGlove()
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    if leaderstats and leaderstats:FindFirstChild("Glove") then
        return leaderstats.Glove.Value
    end
    local tool = getCharacter() and getCharacter():FindFirstChildWhichIsA("Tool")
    return tool and tool.Name or "None"
end

local function isInLobby()
    local char = getCharacter()
    if char then
        local inArena = char:FindFirstChild("isInArena")
        if inArena and inArena.Value == true then
            return false
        end
        local inLobby = char:FindFirstChild("InLobby")
        if inLobby and inLobby.Value == true then
            return true
        end
    end
    local root = getRoot()
    if not root then return false end
    -- In Slap Battles, Lobby is high up around Y > 200 and X < -600
    return (root.Position.Y > 150 and root.Position.X < -600)
end

-- =========================================================================
-- Sky Safe Zone System (Protected Platform far above the map)
-- =========================================================================
local SAFE_ZONE_POS = Vector3.new(0, 3500, 0)
local safeZoneModel = nil

local function getOrCreateSafeZone()
    if safeZoneModel and safeZoneModel.Parent then
        return safeZoneModel
    end

    local model = Instance.new("Model")
    model.Name = "ENI_SkySafeZone"

    local floor = Instance.new("Part")
    floor.Name = "Floor"
    floor.Size = Vector3.new(40, 2, 40)
    floor.Position = SAFE_ZONE_POS
    floor.Anchored = true
    floor.Material = Enum.Material.ForceField
    floor.Color = Color3.fromRGB(0, 195, 245)
    floor.Transparency = 0.3
    floor.Parent = model

    -- Surrounding safety walls
    local wallOffsets = {
        {Vector3.new(0, 6, 20), Vector3.new(40, 12, 1)},
        {Vector3.new(0, 6, -20), Vector3.new(40, 12, 1)},
        {Vector3.new(20, 6, 0), Vector3.new(1, 12, 40)},
        {Vector3.new(-20, 6, 0), Vector3.new(1, 12, 40)},
        {Vector3.new(0, 12, 0), Vector3.new(40, 1, 40)}
    }

    for _, wallData in ipairs(wallOffsets) do
        local wall = Instance.new("Part")
        wall.Size = wallData[2]
        wall.Position = SAFE_ZONE_POS + wallData[1]
        wall.Anchored = true
        wall.Material = Enum.Material.ForceField
        wall.Color = Color3.fromRGB(30, 144, 255)
        wall.Transparency = 0.6
        wall.Parent = model
    end

    model.Parent = Workspace
    safeZoneModel = model
    return safeZoneModel
end

local function teleportToSafeZone()
    getOrCreateSafeZone()
    local root = getRoot()
    if root then
        root.CFrame = CFrame.new(SAFE_ZONE_POS + Vector3.new(0, 4, 0))
    end
end

local function removeSafeZone()
    if safeZoneModel and safeZoneModel.Parent then
        safeZoneModel:Destroy()
        safeZoneModel = nil
    end
end

local function deactivateRockmode()
    pcall(function()
        if ReplicatedStorage:FindFirstChild("DeactivateRockmode") then
            ReplicatedStorage.DeactivateRockmode:FireServer()
        end
        if ReplicatedStorage:FindFirstChild("Rockmode") then
            ReplicatedStorage.Rockmode:FireServer()
        end
        local char = getCharacter()
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Anchored = false
                end
            end
            local hum = char:FindFirstChildWhichIsA("Humanoid")
            if hum then
                hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                hum.PlatformStand = false
            end
        end
    end)
end

-- Exact Center of Main Island in Slap Battles (Placed on the ground surface)
local ARENA_CENTER_POS = Vector3.new(-4.088, -8.923, 1.836)

local function teleportToArenaCenter()
    deactivateRockmode()
    task.wait(0.2)
    local root = getRoot()
    if root then
        -- Put character right on the ground at the center (Y = -8.923 + 2.5 studs)
        root.CFrame = CFrame.new(Vector3.new(-4.088, -6.423, 1.836))
    end
end

-- =========================================================================
-- Glove Equipping & Arena Entry Helpers
-- =========================================================================
local function resetToLobby()
    local char = getCharacter()
    local hum = getHumanoid()
    if hum and hum.Health > 0 then
        pcall(function() hum.Health = 0 end)
        task.wait(3.5)
    end
end

local function autoEquipGlove(gloveName)
    local cur = getCurrentGlove()
    if cur and cur:lower() == gloveName:lower() then
        return true
    end

    -- SAFETY CHECK: If player is in the Arena, DO NOT touch glove clickdetectors (prevents game kick!)
    if not isInLobby() then
        Hub.notify({
            Title = "Returning to Lobby",
            Content = "Resetting character to safely equip " .. gloveName .. " in Lobby...",
            Duration = 3
        })
        resetToLobby()
    end

    local lobby = Workspace:FindFirstChild("Lobby")
    if lobby then
        local stand = lobby:FindFirstChild(gloveName)
        if not stand then
            for _, child in ipairs(lobby:GetChildren()) do
                if child.Name:lower() == gloveName:lower() then
                    stand = child
                    break
                end
            end
        end
        if stand then
            local root = getRoot()
            if root then
                root.CFrame = (stand:IsA("BasePart") and stand.CFrame or stand:GetPivot()) + Vector3.new(0, 2, 0)
                task.wait(0.3)
            end
            local cd = stand:FindFirstChildWhichIsA("ClickDetector", true)
            if cd then
                fireclickdetector(cd)
                task.wait(0.5)
            end
        end
    end

    cur = getCurrentGlove()
    return (cur and cur:lower() == gloveName:lower())
end

local function enterArena()
    local portal = (Workspace:FindFirstChild("Lobby") and Workspace.Lobby:FindFirstChild("Teleport1"))
        or Workspace:FindFirstChild("Teleport1")
    local root = getRoot()
    if portal and root then
        root.CFrame = portal.CFrame
        if firetouchinterest then
            pcall(function()
                firetouchinterest(root, portal, 0)
                firetouchinterest(root, portal, 1)
            end)
        end
        -- Fast polling until registered in arena
        local startTime = tick()
        while tick() - startTime < 2.0 do
            task.wait(0.04)
            local char = getCharacter()
            if char and char:FindFirstChild("isInArena") and char.isInArena.Value == true then
                break
            end
            if tick() - startTime > 0.35 and firetouchinterest and root and portal then
                pcall(function()
                    root.CFrame = portal.CFrame
                    firetouchinterest(root, portal, 0)
                    firetouchinterest(root, portal, 1)
                end)
            end
        end
        task.wait(0.08)
    end
end

local function ensureEquippedAndInArena(gloveName, skipSafeZone)
    local cur = getCurrentGlove()
    if not cur or cur:lower() ~= gloveName:lower() then
        local equipped = autoEquipGlove(gloveName)
        if not equipped then
            Hub.notify({
                Title = "⚠️ Glove Locked / Not Equipped",
                Content = "Could not equip [" .. gloveName .. "]. Please make sure you own it!",
                Duration = 5
            })
            return false
        end
        task.wait(0.5)
    end

    -- If in lobby, step through arena portal
    if isInLobby() then
        Hub.notify({
            Title = "Entering Arena",
            Content = "Entering Arena with " .. gloveName .. "...",
            Duration = 3
        })
        enterArena()
        task.wait(0.8)
    end

    -- Equip tool from Backpack if not already holding it
    local char = getCharacter()
    local hum = char and char:FindFirstChildWhichIsA("Humanoid")
    if hum then
        for _, t in ipairs(LocalPlayer.Backpack:GetChildren()) do
            if t:IsA("Tool") then
                pcall(function() hum:EquipTool(t) end)
            end
        end
        task.wait(0.4)
    end

    -- Teleport to Safe Zone only if not explicitly skipped
    if not skipSafeZone then
        teleportToSafeZone()
        task.wait(0.5)
    end
    return true
end

-- =========================================================================
-- Glove Ability Activator Helper
-- =========================================================================
local function activateAbility(customRemoteName)
    if customRemoteName then
        local r = ReplicatedStorage:FindFirstChild(customRemoteName)
        if r and r:IsA("RemoteEvent") then
            pcall(function() r:FireServer() end)
        end
        for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
            if obj:IsA("RemoteEvent") and obj.Name:lower() == customRemoteName:lower() then
                pcall(function() obj:FireServer() end)
            end
        end
    end

    local bEvents = ReplicatedStorage:FindFirstChild("Events")
    if bEvents and bEvents:FindFirstChild("Ability") then
        pcall(function() bEvents.Ability:FireServer() end)
    end

    if ReplicatedStorage:FindFirstChild("GeneralAbility") then
        pcall(function() ReplicatedStorage.GeneralAbility:FireServer() end)
    end

    local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
    if remotesFolder and remotesFolder:FindFirstChild("UseAbility") then
        pcall(function() remotesFolder.UseAbility:FireServer() end)
    end

    -- Also send physical E keypress to trigger client glove scripts directly
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
        task.wait(0.1)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
    end)
end

-- =========================================================================
-- 1. COMBAT TAB
-- =========================================================================
local function getSlapEvent()
    local bEvents = ReplicatedStorage:FindFirstChild("Events") or ReplicatedStorage:FindFirstChild("GeneralEvents")
    if bEvents then
        local slap = bEvents:FindFirstChild("Slap") or bEvents:FindFirstChild("Hit") or bEvents:FindFirstChild("SlapEvent")
        if slap then return slap end
    end
    for _, child in ipairs(ReplicatedStorage:GetDescendants()) do
        if child:IsA("RemoteEvent") and (child.Name == "Slap" or child.Name == "Hit" or child.Name == "GeneralHit" or child.Name:find("Slap")) then
            return child
        end
    end
    return nil
end

local function slapPlayer(targetChar)
    if not targetChar then return end
    local targetRoot = targetChar:FindFirstChild("HumanoidRootPart") or targetChar:FindFirstChild("Torso")
    local myRoot = getRoot()
    if not targetRoot or not myRoot then return end

    local tool = getCharacter() and getCharacter():FindFirstChildWhichIsA("Tool")
    if tool then
        pcall(function() tool:Activate() end)
    end

    local slapEvt = getSlapEvent()
    if slapEvt then
        pcall(function() slapEvt:FireServer(targetRoot) end)
    end
end

Hub.CreateSection(combatTab, "Slap Aura")

Hub.CreateToggle(combatTab, "Slap Aura", false, function(toggled)
    state.SlapAura = toggled
end)

Hub.CreateSlider(combatTab, "Aura Range", 10, 35, 18, "", function(val)
    state.SlapAuraDistance = val
end)

Hub.CreateToggle(combatTab, "Fast Slap", false, function(toggled)
    state.FastSlap = toggled
end)

Hub.CreateSection(combatTab, "Abilities")

Hub.CreateToggle(combatTab, "Auto Reverse Parry", false, function(toggled)
    state.AutoParry = toggled
end)

Hub.CreateButton(combatTab, "⚡ Fire Ability", function()
    activateAbility()
end)

task.spawn(function()
    while true do
        task.wait(state.FastSlap and 0.03 or 0.08)
        if state.SlapAura then
            local myRoot = getRoot()
            if myRoot then
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and player.Character then
                        local tRoot = player.Character:FindFirstChild("HumanoidRootPart") or player.Character:FindFirstChild("Torso")
                        local tHum = player.Character:FindFirstChildWhichIsA("Humanoid")
                        if tRoot and tHum and tHum.Health > 0 then
                            local dist = (myRoot.Position - tRoot.Position).Magnitude
                            if dist <= state.SlapAuraDistance then
                                slapPlayer(player.Character)
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- =========================================================================
-- 2. AUTO-GLOVES (BADGES) TAB
-- =========================================================================
Hub.CreateSection(badgeTab, "Badge Solvers")

local ELUDE_MAZE_PLACE_ID = 11828384869

local function isInsideEludeMaze()
    if Workspace:FindFirstChild("Lobby") or Workspace:FindFirstChild("BountyHunterRoom") then
        return false
    end
    return (game.PlaceId == ELUDE_MAZE_PLACE_ID) or (Workspace:FindFirstChild("Collectable") ~= nil) or (Workspace:FindFirstChild("Maze") ~= nil) or (Workspace:FindFirstChild("Pim") ~= nil)
end

local function solveEludeKeypad()
    -- 1. Try Direct Teleport to the exact Maze Place ID
    pcall(function()
        TeleportService:Teleport(ELUDE_MAZE_PLACE_ID, LocalPlayer)
    end)
    if ReplicatedStorage:FindFirstChild("TeleportElude") then
        pcall(function() ReplicatedStorage.TeleportElude:FireServer() end)
    end

    -- 2. If in Lobby, enter arena first
    if isInLobby() then
        Hub.notify({
            Title = "Entering Arena",
            Content = "Stepping through arena portal...",
            Duration = 3
        })
        enterArena()
        task.wait(1)
    end

    local keypad = Workspace:FindFirstChild("Keypad")
    if not keypad then
        Hub.notify({
            Title = "Teleporting",
            Content = "Connecting to Elude Maze...",
            Duration = 4
        })
        return false
    end

    local buttons = keypad:FindFirstChild("Buttons")
    if not buttons then return false end

    local root = getRoot()
    if root then
        root.CFrame = keypad:GetPivot() * CFrame.new(0, 0, -4) * CFrame.Angles(0, math.rad(180), 0)
        task.wait(0.5)
    end

    local pCount = #Players:GetPlayers()
    local code = tostring((pCount * 25) + 1100 - 7)

    Hub.notify({
        Title = "Keypad",
        Content = "Entering code: " .. code,
        Duration = 3
    })

    local resetBtn = buttons:FindFirstChild("Reset")
    local resetCd = resetBtn and resetBtn:FindFirstChildWhichIsA("ClickDetector")
    if resetCd then
        fireclickdetector(resetCd)
        task.wait(0.3)
    end

    for i = 1, #code do
        local digit = code:sub(i, i)
        local btn = buttons:FindFirstChild(digit)
        local cd = btn and btn:FindFirstChildWhichIsA("ClickDetector")
        if cd then
            fireclickdetector(cd)
            task.wait(0.25)
        end
    end

    local enterBtn = buttons:FindFirstChild("Enter")
    local enterCd = enterBtn and enterBtn:FindFirstChildWhichIsA("ClickDetector")
    if enterCd then
        fireclickdetector(enterCd)
        task.wait(0.5)
    end

    if ReplicatedStorage:FindFirstChild("TeleportElude") then
        pcall(function() ReplicatedStorage.TeleportElude:FireServer() end)
    end

    Hub.notify({
        Title = "Keypad Solved",
        Content = "Teleporting to Maze...",
        Duration = 4
    })
    return true
end

-- Direct Teleport Button
Hub.CreateButton(badgeTab, "🚀 Teleport to Elude Maze", function()
    Hub.notify({
        Title = "Teleporting",
        Content = "Teleporting to Elude Maze...",
        Duration = 3
    })
    pcall(function()
        TeleportService:Teleport(ELUDE_MAZE_PLACE_ID, LocalPlayer)
    end)
    if ReplicatedStorage:FindFirstChild("TeleportElude") then
        pcall(function() ReplicatedStorage.TeleportElude:FireServer() end)
    end
end)

-- Auto-Elude Solver
Hub.CreateButton(badgeTab, "🚪 Auto Elude", function()
    task.spawn(function()
        if not isInsideEludeMaze() then
            solveEludeKeypad()
            return
        end

        Hub.notify({
            Title = "Elude Maze",
            Content = "Collecting hidden relics...",
            Duration = 3
        })

        local root = getRoot()
        local collected = 0
        local collectableFolder = Workspace:FindFirstChild("Collectable")
        if collectableFolder and root then
            for _, item in ipairs(collectableFolder:GetChildren()) do
                local part = item:IsA("BasePart") and item or item:FindFirstChildWhichIsA("BasePart", true)
                if part then
                    root.CFrame = part.CFrame
                    if firetouchinterest then
                        pcall(function()
                            firetouchinterest(root, part, 0)
                            firetouchinterest(root, part, 1)
                        end)
                    end
                    collected = collected + 1
                    task.wait(0.15)
                end
            end
        end

        -- Fallback check for any other relics
        for _, relic in ipairs(Workspace:GetDescendants()) do
            if relic:IsA("BasePart") and (relic.Name:lower():find("relic") or relic.Name:lower():find("key") or relic.Name == "Item") then
                local pName = relic.Parent and relic.Parent.Name or ""
                if pName ~= "Lobby" and pName ~= "BountyHunterRoom" and pName ~= "BoogieShop" then
                    if root then
                        root.CFrame = relic.CFrame
                        if firetouchinterest then
                            pcall(function()
                                firetouchinterest(root, relic, 0)
                                firetouchinterest(root, relic, 1)
                            end)
                        end
                        task.wait(0.15)
                    end
                end
            end
        end

        task.wait(0.2)

        -- Touch the Elude Glove pedestal in Ruins
        local eludeGlove = (Workspace:FindFirstChild("Ruins") and Workspace.Ruins:FindFirstChild("Elude") and Workspace.Ruins.Elude:FindFirstChild("Glove"))
            or Workspace:FindFirstChild("EludePedestal", true)
            or Workspace:FindFirstChild("EludeGlove", true)
            or Workspace:FindFirstChild("Glove", true)

        if eludeGlove and eludeGlove:IsA("BasePart") and root then
            root.CFrame = eludeGlove.CFrame
            if firetouchinterest then
                pcall(function()
                    firetouchinterest(root, eludeGlove, 0)
                    firetouchinterest(root, eludeGlove, 1)
                end)
            end
        end

        Hub.notify({
            Title = "Elude Glove",
            Content = "Relics collected: " .. tostring(collected) .. ". Claimed Elude!",
            Duration = 5
        })
    end)
end)

-- Auto-Counter Glove Solver
Hub.CreateButton(badgeTab, "🕵️ Auto Counter", function()
    task.spawn(function()
        if not isInsideEludeMaze() then
            solveEludeKeypad()
            return
        end

        Hub.notify({
            Title = "Counter",
            Content = "Searching for lever...",
            Duration = 3
        })

        local leverModel = Workspace:FindFirstChild("CounterLever")
        local leverPart = leverModel and (leverModel:IsA("BasePart") and leverModel or leverModel:FindFirstChildWhichIsA("BasePart", true))
        local leverDetector = leverModel and leverModel:FindFirstChildWhichIsA("ClickDetector", true)

        if not leverDetector then
            for _, desc in ipairs(Workspace:GetDescendants()) do
                if desc:IsA("ClickDetector") then
                    local p = desc.Parent
                    if p and (p:IsA("BasePart") or p:FindFirstChildWhichIsA("BasePart")) then
                        local pName = p.Name:lower()
                        if (pName:find("lever") or pName:find("switch") or pName:find("secretlever") or pName:find("counterlever")) 
                            and not pName:find("playercounter") and not pName:find("badgecounter") then
                            leverPart = p:IsA("BasePart") and p or p:FindFirstChildWhichIsA("BasePart")
                            leverDetector = desc
                            break
                        end
                    end
                end
            end
        end

        if leverDetector and leverPart then
            local root = getRoot()
            if root then
                root.CFrame = leverPart.CFrame + Vector3.new(0, 2, 0)
                task.wait(0.3)
                fireclickdetector(leverDetector)
                task.wait(0.1)
                fireclickdetector(leverDetector)
            end

            Hub.notify({
                Title = "Counter",
                Content = "Lever pulled! Teleporting to Safe Zone...",
                Duration = 4
            })
        else
            Hub.notify({
                Title = "Counter",
                Content = "Lever not found yet. Teleporting to Safe Zone...",
                Duration = 3
            })
        end

        teleportToSafeZone()

        -- Auto-Claim Counter Relic listener
        task.spawn(function()
            local found = false
            for i = 1, 150 do
                task.wait(0.5)
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA("BasePart") and obj.Name:lower():find("counter") and not obj.Name:lower():find("playercounter") and not obj.Name:lower():find("badgecounter") and obj.Name ~= "CounterLever" then
                        local pName = obj.Parent and obj.Parent.Name or ""
                        if pName ~= "Lobby" and pName ~= "BountyHunterRoom" and pName ~= "BoogieShop" then
                            local r = getRoot()
                            if r then
                                r.CFrame = obj.CFrame + Vector3.new(0, 2, 0)
                                if firetouchinterest then
                                    pcall(function()
                                        firetouchinterest(r, obj, 0)
                                        firetouchinterest(r, obj, 1)
                                    end)
                                end
                                Hub.notify({
                                    Title = "Counter Glove",
                                    Content = "Claimed Counter Glove!",
                                    Duration = 5
                                })
                                found = true
                                break
                            end
                        end
                    end
                end
                if found then break end
            end
        end)
    end)
end)

-- =========================================================================
-- Guide Boss & Maze Auto Solver
-- =========================================================================
local function completeMazeAndGuideBoss()
    local root = getRoot()
    local char = getCharacter()
    if not root or not char then
        Hub.notify({
            Title = "Error",
            Content = "Character not found",
            Duration = 3
        })
        return
    end

    enableGodmode()
    purgeAllHazards()

    Hub.notify({
        Title = "Solving Dungeon",
        Content = "Progressing levers and checkpoints...",
        Duration = 3
    })

    root.Anchored = false
    local tool = char:FindFirstChildWhichIsA("Tool") or LocalPlayer.Backpack:FindFirstChildWhichIsA("Tool")
    if tool and tool.Parent ~= char then tool.Parent = char end

    -- Step 1: Gate 1 Lever
    local gate1Lever = Workspace:FindFirstChild("Gate1Lever")
    local g1cd = gate1Lever and gate1Lever:FindFirstChildWhichIsA("ClickDetector", true)
    local g1Part = gate1Lever and (gate1Lever:FindFirstChild("Lever", true) or gate1Lever:FindFirstChildWhichIsA("BasePart", true))
    if g1Part then root.CFrame = g1Part.CFrame end
    task.wait(0.2)
    if g1cd then pcall(function() fireclickdetector(g1cd) end) end
    if g1Part and firetouchinterest then
        pcall(function()
            firetouchinterest(root, g1Part, 0)
            firetouchinterest(root, g1Part, 1)
        end)
    end
    task.wait(0.4)

    -- Step 2: Fake Exit Lever
    local fakeExitLever = Workspace:FindFirstChild("FakeExitLever")
    local feCd = fakeExitLever and fakeExitLever:FindFirstChildWhichIsA("ClickDetector", true)
    local fePart = fakeExitLever and (fakeExitLever:FindFirstChild("Lever", true) or fakeExitLever:FindFirstChildWhichIsA("BasePart", true))
    if fePart then root.CFrame = fePart.CFrame end
    task.wait(0.2)
    if feCd then pcall(function() fireclickdetector(feCd) end) end
    if fePart and firetouchinterest then
        pcall(function()
            firetouchinterest(root, fePart, 0)
            firetouchinterest(root, fePart, 1)
        end)
    end
    task.wait(0.4)

    -- Step 3: Pressure Plate
    local pp = Workspace:FindFirstChild("pls organize") and Workspace["pls organize"]:FindFirstChild("PressurePlate")
    local ppHitbox = pp and pp:FindFirstChild("Hitbox")
    local ppPlate = pp and pp:FindFirstChild("Plate")
    if ppHitbox then
        root.CFrame = ppHitbox.CFrame + Vector3.new(0, 1.5, 0)
        if firetouchinterest then
            firetouchinterest(root, ppHitbox, 0)
            firetouchinterest(root, ppHitbox, 1)
            if ppPlate then
                firetouchinterest(root, ppPlate, 0)
                firetouchinterest(root, ppPlate, 1)
            end
        end
    end
    task.wait(0.4)

    -- Step 4: Train & PotatoLord Triggers
    local mapComp = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Components")
    local trainTriggers = mapComp and mapComp:FindFirstChild("TrainTriggers")
    if trainTriggers and firetouchinterest then
        for _, t in ipairs(trainTriggers:GetChildren()) do
            if t:IsA("BasePart") then
                firetouchinterest(root, t, 0)
                firetouchinterest(root, t, 1)
            end
        end
    end

    local potatoTrig = mapComp and mapComp:FindFirstChild("PotatoLordTrigger")
    if potatoTrig and firetouchinterest then
        firetouchinterest(root, potatoTrig, 0)
        firetouchinterest(root, potatoTrig, 1)
    end
    task.wait(0.4)

    -- Step 5: Shack Lever & Trapdoor Decontamination Room
    local shackLever = Workspace:FindFirstChild("ShackLever")
    local shackCd = shackLever and shackLever:FindFirstChildWhichIsA("ClickDetector", true)
    root.CFrame = CFrame.new(3276.26, -70.71, 822.51)
    task.wait(0.2)
    if shackCd then pcall(function() fireclickdetector(shackCd) end) end
    
    root.CFrame = CFrame.new(3242, -70, 822.51)
    Hub.notify({
        Title = "Decontaminating",
        Content = "Waiting in Shack Chamber (11s)...",
        Duration = 4
    })
    task.wait(11)

    -- Step 6: Instant Teleport to Arena Floor & Trigger Cutscene
    Hub.notify({
        Title = "Entering Arena",
        Content = "Teleported to arena floor (Waiting 11s for Cutscene)...",
        Duration = 4
    })

    root.CFrame = CFrame.new(594.47, 66.5, -321.21)

    local curMapComp = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Components")
    local arenaCenter = curMapComp and curMapComp:FindFirstChild("GuideArenaCenter")
    local mainPlatform = curMapComp and curMapComp:FindFirstChild("MainPlatform")
    if arenaCenter and firetouchinterest then
        firetouchinterest(root, arenaCenter, 0)
        firetouchinterest(root, arenaCenter, 1)
    end
    if mainPlatform and firetouchinterest then
        firetouchinterest(root, mainPlatform, 0)
        firetouchinterest(root, mainPlatform, 1)
    end

    -- Step 7: Wait 11 seconds on arena floor for cutscene to initialize and play
    task.wait(11)

    -- Step 8: Teleport to Elevated Safe Zone Platform (Y = 85)
    local arenaSkyPos = Vector3.new(594.62, 85, -321.16)
    
    -- Create elevated safe platform: white color with 75% transparency
    local existingFloor = Workspace:FindFirstChild("ENI_BossSkySafeZone")
    if existingFloor then existingFloor:Destroy() end
    local safeFloor = Instance.new("Part")
    safeFloor.Name = "ENI_BossSkySafeZone"
    safeFloor.Size = Vector3.new(100, 2, 100)
    safeFloor.CFrame = CFrame.new(arenaSkyPos.X, 84, arenaSkyPos.Z)
    safeFloor.Anchored = true
    safeFloor.Transparency = 0.75
    safeFloor.Color = Color3.fromRGB(255, 255, 255)
    safeFloor.Material = Enum.Material.SmoothPlastic
    safeFloor.CanCollide = true
    safeFloor.Parent = Workspace

    local safeCFrame = CFrame.new(arenaSkyPos.X, 85 + 3.1, arenaSkyPos.Z)
    root.CFrame = safeCFrame
    root.Anchored = false

    Hub.notify({
        Title = "Boss Battle Active",
        Content = "Safe Zone locked & Max Reach Slap Aura active...",
        Duration = 4
    })

    local inBossFight = true

    -- Infinite Loop Safe Zone Position Lock (During Boss Fight Only)
    task.spawn(function()
        while inBossFight do
            task.wait()
            local curRoot = getRoot()
            if curRoot and inBossFight then
                curRoot.CFrame = safeCFrame
                curRoot.Velocity = Vector3.zero
                curRoot.AssemblyLinearVelocity = Vector3.zero
            end
        end
    end)

    -- Auto-Slap Boss Loop (Extreme Long Reach Hits & Missile Deflection)
    task.spawn(function()
        for _ = 1, 1200 do
            task.wait(0.03)
            local curChar = getCharacter()
            local curRoot = getRoot()
            local curTool = (curChar and curChar:FindFirstChildWhichIsA("Tool")) or (LocalPlayer.Backpack:FindFirstChildWhichIsA("Tool"))

            if curTool and curRoot then
                local glove = curTool:FindFirstChild("Glove")
                if glove then
                    if glove.Size.X < 80 then
                        pcall(function()
                            glove.Size = Vector3.new(100, 100, 100)
                            glove.CanCollide = false
                            glove.Massless = true
                            glove.Transparency = 1
                        end)
                    end
                    for _, effect in ipairs(glove:GetDescendants()) do
                        if effect:IsA("ParticleEmitter") or effect:IsA("Beam") or effect:IsA("Trail") or effect:IsA("PointLight") or effect:IsA("Highlight") then
                            effect.Enabled = false
                        end
                    end
                end

                local hasNetwork = curTool:FindFirstChild("Network")

                -- Silent Instant Network Slap
                local function hitTarget(targetPart)
                    if not targetPart or not targetPart:IsA("BasePart") then return end
                    if curTool.Parent ~= curChar then
                        curTool.Parent = curChar
                    end
                    pcall(function()
                        if hasNetwork then
                            curTool.Network:FireServer("Hit", targetPart)
                        end
                        if glove and firetouchinterest then
                            firetouchinterest(glove, targetPart, 0)
                            firetouchinterest(glove, targetPart, 1)
                        end
                    end)
                end

                -- 1. Deflect Track Glove Missiles up to 500 studs
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA("BasePart") and (obj:GetAttribute("TrackGloveMissile") == true or obj.Name == "TrackGloveMissile" or obj.Name:lower():find("missile")) then
                        local dist = (obj.Position - curRoot.Position).Magnitude
                        if dist <= 500 then
                            hitTarget(obj)
                        end
                    end
                end

                -- 2. Target Boss NPCs & Minions up to 500 studs
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA("Model") then
                        local oName = obj.Name
                        if oName == "ReplicaNPC" or oName == "Stevem" or oName == "PotatoLord" or oName == "Pumpkin" or oName == "Pumkin" then
                            local hum = obj:FindFirstChildWhichIsA("Humanoid")
                            local head = obj:FindFirstChild("Head") or obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChildWhichIsA("BasePart")
                            if head and (not hum or hum.Health > 0) then
                                local dist = (head.Position - curRoot.Position).Magnitude
                                if dist <= 500 then
                                    hitTarget(head)
                                end
                            end
                        end
                    end
                end

                -- 3. Strike Dungeon Golem (All parts up to 500 studs)
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA("Model") and (obj.Name == "DungeonGolem" or obj.Name == "Golem" or obj.Name:lower():find("golem")) then
                        for _, part in ipairs(obj:GetChildren()) do
                            if part:IsA("BasePart") then
                                local dist = (part.Position - curRoot.Position).Magnitude
                                if dist <= 500 then
                                    hitTarget(part)
                                end
                            end
                        end
                    end
                end

                -- 4. Strike Guide Boss up to 500 studs
                local isBossActive = (Workspace:GetAttribute("GuideHealthPercent") ~= nil) or (Workspace:GetAttribute("BossName") ~= nil)
                if isBossActive then
                    for _, obj in ipairs(Workspace:GetDescendants()) do
                        if obj:IsA("Model") and (obj.Name == "GuideNPC" or obj.Name == "Guide" or obj.Name:lower():find("guidenpc")) then
                            for _, part in ipairs(obj:GetChildren()) do
                                if part:IsA("BasePart") then
                                    local dist = (part.Position - curRoot.Position).Magnitude
                                    if dist <= 500 then
                                        hitTarget(part)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end)

    -- Infallible Multi-Method Decision Handler (Auto Spare / Kill)
    local function executeBossDecision(outcome)
        local isSave = (outcome == "Save" or outcome == "Save Guide")
        
        -- 1. Fire all candidate Decision / Cutscene remotes
        for _, remote in ipairs(ReplicatedStorage:GetDescendants()) do
            if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
                local rName = remote.Name:lower()
                if rName:find("answer") or rName:find("spare") or rName:find("eliminate") or rName:find("decision") or rName:find("cutscene") or rName:find("choice") then
                    pcall(function()
                        if remote:IsA("RemoteEvent") then
                            remote:FireServer(isSave and "Spare" or "Eliminate")
                            remote:FireServer(isSave and "Save" or "Kill")
                            remote:FireServer(isSave and "Yes" or "No")
                            remote:FireServer(isSave and true or false)
                            remote:FireServer(isSave and 1 or 2)
                        elseif remote:IsA("RemoteFunction") then
                            remote:InvokeServer(isSave and "Spare" or "Eliminate")
                            remote:InvokeServer(isSave and "Save" or "Kill")
                            remote:InvokeServer(isSave and "Yes" or "No")
                            remote:InvokeServer(isSave and true or false)
                        end
                    end)
                end
            end
        end

        -- 2. Click all buttons in PlayerGui
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        if playerGui then
            for _, btn in ipairs(playerGui:GetDescendants()) do
                if btn:IsA("TextButton") or btn:IsA("ImageButton") then
                    local bName = btn.Name:lower()
                    local bText = (btn:IsA("TextButton") and btn.Text:lower()) or ""
                    local isTarget = false

                    if isSave then
                        if bName:find("yes") or bName:find("spare") or bName:find("save") or bText:find("spare") or bText:find("save") or bText:find("yes") or bText:find("relude") then
                            isTarget = true
                        end
                    else
                        if bName:find("no") or bName:find("kill") or bName:find("eliminate") or bText:find("kill") or bText:find("eliminate") or bText:find("no") or bText:find("hunter") then
                            isTarget = true
                        end
                    end

                    if isTarget then
                        pcall(function()
                            if getconnections then
                                for _, c in ipairs(getconnections(btn.MouseButton1Click)) do c:Fire() end
                                for _, c in ipairs(getconnections(btn.Activated)) do c:Fire() end
                                for _, c in ipairs(getconnections(btn.MouseButton1Down)) do c:Fire() end
                                for _, c in ipairs(getconnections(btn.MouseButton1Up)) do c:Fire() end
                            end
                            if firesignal then
                                firesignal(btn.MouseButton1Click)
                                firesignal(btn.Activated)
                            end
                            if VirtualInputManager and btn.AbsoluteSize.X > 0 and btn.AbsoluteSize.Y > 0 then
                                local x = btn.AbsolutePosition.X + btn.AbsoluteSize.X / 2
                                local y = btn.AbsolutePosition.Y + btn.AbsoluteSize.Y / 2 + 36
                                VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 1)
                                task.wait(0.05)
                                VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 1)
                            end
                        end)
                    end
                end
            end
        end
    end

    -- Background Boss Watcher & Sparing Handler
    task.spawn(function()
        for i = 1, 600 do
            task.wait(0.35)
            local shouldSpare = (state.GuideBossOutcome == "Save Guide")
            local hpPercent = Workspace:GetAttribute("GuideHealthPercent")

            local hasEnded = false
            pcall(function()
                if hpPercent ~= nil and hpPercent <= 0.01 then
                    hasEnded = true
                end

                local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
                if playerGui then
                    for _, desc in ipairs(playerGui:GetDescendants()) do
                        if desc:IsA("GuiObject") and desc.Visible then
                            local dName = desc.Name:lower()
                            if dName:find("spare") or dName:find("choice") or dName:find("decision") or dName == "spareguideprompt" then
                                hasEnded = true
                                break
                            end
                        end
                    end
                end

                local liveComp = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Components")
                if Workspace:FindFirstChild("Relude", true) or (liveComp and (liveComp:FindFirstChild("Reludepoof") or liveComp:FindFirstChild("TubeBaseGlove"))) or Workspace:FindFirstChild("Hunter", true) then
                    hasEnded = true
                end
            end)

            if hasEnded then
                for _ = 1, 4 do
                    executeBossDecision(shouldSpare and "Save" or "Kill")
                    task.wait(0.2)
                end

                inBossFight = false

                if shouldSpare then
                    Hub.notify({
                        Title = "Spared Guide",
                        Content = "Saved Guide! Claiming Relude...",
                        Duration = 5
                    })
                else
                    Hub.notify({
                        Title = "Killed Guide",
                        Content = "Defeated Guide! Claiming Hunter...",
                        Duration = 5
                    })
                end

                task.wait(1)
                local curRoot = getRoot()
                if curRoot then
                    curRoot.Anchored = false
                end

                -- Auto-claim reward item
                for _ = 1, 50 do
                    task.wait(0.25)
                    local curRoot2 = getRoot()
                    if not curRoot2 then break end

                    local targetReward = nil
                    local liveComp = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Components")
                    
                    if shouldSpare then
                        targetReward = Workspace:FindFirstChild("Relude", true)
                            or (liveComp and liveComp:FindFirstChild("Reludepoof"))
                            or (liveComp and liveComp:FindFirstChild("TubeBaseGlove"))
                    else
                        targetReward = Workspace:FindFirstChild("Hunter", true)
                            or (liveComp and liveComp:FindFirstChild("Hunter"))
                            or (liveComp and liveComp:FindFirstChild("GuideNPC"))
                    end

                    if targetReward then
                        local rPart = targetReward:IsA("BasePart") and targetReward or targetReward:FindFirstChildWhichIsA("BasePart", true)
                        if rPart then
                            curRoot2.CFrame = rPart.CFrame
                            if firetouchinterest then
                                pcall(function()
                                    firetouchinterest(curRoot2, rPart, 0)
                                    firetouchinterest(curRoot2, rPart, 1)
                                end)
                            end
                        end
                    end
                end
                break
            end
        end
    end)
end

Hub.CreateSection(badgeTab, "Guide Boss & Maze")

Hub.CreateDropdown(badgeTab, "Outcome: Save or Kill Guide", {"Save Guide (Relude)", "Kill Guide (Hunter)"}, "Save Guide (Relude)", function(selected)
    if selected:find("Save") then
        state.GuideBossOutcome = "Save Guide"
    else
        state.GuideBossOutcome = "Kill Guide"
    end
    Hub.notify({
        Title = "Guide Decision",
        Content = "Outcome set to: " .. state.GuideBossOutcome,
        Duration = 2
    })
end)

Hub.CreateButton(badgeTab, "⚡ Auto Complete Maze & Boss", function()
    completeMazeAndGuideBoss()
end)

Hub.CreateButton(badgeTab, "🤝 Spare Guide (Save)", function()
    local answerRemote = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("Data") and ReplicatedStorage.Remotes.Data:FindFirstChild("AnswerInCutscene")
    if answerRemote then
        pcall(function() answerRemote:FireServer(true) end)
    end
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    local sparePrompt = playerGui and playerGui:FindFirstChild("Component") and playerGui.Component:FindFirstChild("SpareGuidePrompt")
    local yesBtn = sparePrompt and sparePrompt:FindFirstChild("Yes", true)
    if yesBtn and getconnections then
        for _, c in ipairs(getconnections(yesBtn.MouseButton1Click)) do c:Fire() end
        for _, c in ipairs(getconnections(yesBtn.Activated)) do c:Fire() end
    end
    Hub.notify({
        Title = "Spare Guide",
        Content = "Sent Save / Spare decision.",
        Duration = 3
    })
end)

Hub.CreateButton(badgeTab, "💀 Kill Guide (Bounty)", function()
    local answerRemote = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("Data") and ReplicatedStorage.Remotes.Data:FindFirstChild("AnswerInCutscene")
    if answerRemote then
        pcall(function() answerRemote:FireServer(false) end)
    end
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    local sparePrompt = playerGui and playerGui:FindFirstChild("Component") and playerGui.Component:FindFirstChild("SpareGuidePrompt")
    local noBtn = sparePrompt and sparePrompt:FindFirstChild("No", true)
    if noBtn and getconnections then
        for _, c in ipairs(getconnections(noBtn.MouseButton1Click)) do c:Fire() end
        for _, c in ipairs(getconnections(noBtn.Activated)) do c:Fire() end
    end
    Hub.notify({
        Title = "Kill Guide",
        Content = "Sent Kill / Bounty decision.",
        Duration = 3
    })
end)

-- Auto-[REDACTED] Glove Solver
Hub.CreateButton(badgeTab, "⬛ Auto [REDACTED]", function()
    task.spawn(function()
        local currentSlaps = getSlapCount()
        if currentSlaps < 5000 then
            Hub.notify({
                Title = "[REDACTED]",
                Content = "Requires 5,000 slaps! Current: " .. tostring(currentSlaps),
                Duration = 4
            })
            return
        end

        Hub.notify({
            Title = "[REDACTED]",
            Content = "Searching for doorway...",
            Duration = 3
        })

        local redactedDoor = Workspace:FindFirstChild("PocketDimension", true) 
            or Workspace:FindFirstChild("RedactedDoor", true)
            or Workspace:FindFirstChild("Door", true)

        local root = getRoot()
        if root and redactedDoor then
            local doorPart = redactedDoor:IsA("BasePart") and redactedDoor or redactedDoor:FindFirstChildWhichIsA("BasePart")
            if doorPart then
                root.CFrame = doorPart.CFrame + Vector3.new(0, 2, 0)
                task.wait(1)
            end
        end

        for i = 1, 10 do
            local safeDoor = Workspace:FindFirstChild("SafeDoor" .. tostring(i), true) or Workspace:FindFirstChild("Door" .. tostring(i), true)
            if safeDoor and safeDoor:IsA("BasePart") and root then
                root.CFrame = safeDoor.CFrame
                task.wait(0.8)
            end
        end

        Hub.notify({
            Title = "[REDACTED]",
            Content = "Completed door traversal.",
            Duration = 3
        })
    end)
end)

Hub.CreateSection(badgeTab, "AFK Farm")

-- Megarock Center Lock
Hub.CreateToggle(badgeTab, "🎯 Megarock Center Lock", false, function(toggled)
    state.MegarockCenterLock = toggled
    if toggled then
        task.spawn(function()
            local success = ensureEquippedAndInArena("MEGAROCK", true)
            if not success then
                state.MegarockCenterLock = false
                return
            end

            local char = getCharacter()
            if char then
                for _, p in ipairs(char:GetDescendants()) do
                    if p:IsA("BasePart") then
                        p.Anchored = false
                    end
                end
            end

            teleportToArenaCenter()
            task.wait(0.4)

            char = getCharacter()
            local hum = char and char:FindFirstChildWhichIsA("Humanoid")
            if hum then
                for _, t in ipairs(LocalPlayer.Backpack:GetChildren()) do
                    if t:IsA("Tool") then
                        pcall(function() hum:EquipTool(t) end)
                    end
                end
            end
            task.wait(0.3)

            if ReplicatedStorage:FindFirstChild("Rockmode") then
                ReplicatedStorage.Rockmode:FireServer()
            end
            activateAbility("Rockmode")
            task.wait(0.6)

            char = getCharacter()
            if char and not char:FindFirstChild("rock") then
                if ReplicatedStorage:FindFirstChild("Rockmode") then
                    ReplicatedStorage.Rockmode:FireServer()
                end
                activateAbility("Rockmode")
            end

            Hub.notify({
                Title = "Megarock",
                Content = "Locked to center.",
                Duration = 3
            })
        end)
    else
        deactivateRockmode()
        Hub.notify({
            Title = "Megarock",
            Content = "Megarock deactivated.",
            Duration = 3
        })
    end
end)

-- Auto-Megarock Sky Safe Zone
Hub.CreateToggle(badgeTab, "🪨 Auto Megarock", false, function(toggled)
    state.AutoMegarock = toggled
    if toggled then
        task.spawn(function()
            local success = ensureEquippedAndInArena("Diamond")
            if not success then
                state.AutoMegarock = false
                return
            end

            task.wait(0.5)
            activateAbility("Rockmode")
            Hub.notify({
                Title = "Megarock Farm",
                Content = "Active in Safe Zone.",
                Duration = 4
            })
        end)
    else
        pcall(function()
            if ReplicatedStorage:FindFirstChild("DeactivateRockmode") then
                ReplicatedStorage.DeactivateRockmode:FireServer()
            end
            if ReplicatedStorage:FindFirstChild("Rockmode") then
                ReplicatedStorage.Rockmode:FireServer()
            end
            local char = getCharacter()
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.Anchored = false
                    end
                end
                local hum = char:FindFirstChildWhichIsA("Humanoid")
                if hum then
                    hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                    hum.PlatformStand = false
                end
            end
        end)
        Hub.notify({
            Title = "Megarock Farm",
            Content = "Stopped.",
            Duration = 3
        })
    end
end)

-- Auto-Fish
Hub.CreateToggle(badgeTab, "🐟 Auto Fish", false, function(toggled)
    state.AutoFish = toggled
    if toggled then
        task.spawn(function()
            local success = ensureEquippedAndInArena("ZZZZZZZ")
            if not success then
                state.AutoFish = false
                return
            end

            task.wait(0.5)
            activateAbility("ZZZZZZZSleep")
            Hub.notify({
                Title = "Auto Fish",
                Content = "Sleeping in Safe Zone.",
                Duration = 4
            })
        end)
    else
        pcall(function()
            local char = getCharacter()
            local hum = char and char:FindFirstChildWhichIsA("Humanoid")
            if hum then
                hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                hum.PlatformStand = false
            end
        end)
        Hub.notify({
            Title = "Auto Fish",
            Content = "Stopped.",
            Duration = 3
        })
    end
end)

-- Auto-Trap
Hub.CreateToggle(badgeTab, "🧱 Auto Trap", false, function(toggled)
    state.AutoTrap = toggled
    if toggled then
        task.spawn(function()
            local success = ensureEquippedAndInArena("Brick")
            if not success then
                state.AutoTrap = false
                return
            end

            Hub.notify({
                Title = "Auto Trap",
                Content = "Placing bricks in Safe Zone.",
                Duration = 4
            })
        end)
    else
        Hub.notify({
            Title = "Auto Trap",
            Content = "Placed " .. tostring(state.TrapBrickCount) .. " bricks.",
            Duration = 3
        })
    end
end)

-- Auto-Voodoo
Hub.CreateToggle(badgeTab, "👻 Auto Voodoo", false, function(toggled)
    state.AutoVoodoo = toggled
    if toggled then
        task.spawn(function()
            local success = ensureEquippedAndInArena("Ghost")
            if not success then
                state.AutoVoodoo = false
                return
            end

            task.wait(0.5)
            activateAbility("Ghostinvisibilityactivated")
            Hub.notify({
                Title = "Auto Voodoo",
                Content = "Invisible in Safe Zone.",
                Duration = 4
            })
        end)
    else
        pcall(function()
            if ReplicatedStorage:FindFirstChild("Ghostinvisibilitydeactivated") then
                ReplicatedStorage.Ghostinvisibilitydeactivated:FireServer()
            end
        end)
        Hub.notify({
            Title = "Auto Voodoo",
            Content = "Stopped.",
            Duration = 3
        })
    end
end)

-- Background Routine for AFK Glove Farming
task.spawn(function()
    while true do
        task.wait(1.5)

        -- Megarock Center Lock Enforcement (Keeps rock on ground at exact X/Z center)
        if state.MegarockCenterLock then
            local root = getRoot()
            if root and not isInLobby() then
                local distXZ = (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(ARENA_CENTER_POS.X, 0, ARENA_CENTER_POS.Z)).Magnitude
                -- Only correct if pushed away horizontally on X/Z (prevents rapid CFrame changes that cancel rock)
                if distXZ > 6 then
                    teleportToArenaCenter()
                    task.wait(0.4)
                    if ReplicatedStorage:FindFirstChild("Rockmode") then
                        ReplicatedStorage.Rockmode:FireServer()
                    end
                    activateAbility("Rockmode")
                    task.wait(0.5)
                end
                local char = getCharacter()
                if char and char:FindFirstChild("rock") then
                    for _, p in ipairs(char:GetDescendants()) do
                        if p:IsA("BasePart") then
                            p.Anchored = true
                        end
                    end
                elseif char and not char:FindFirstChild("rock") then
                    if ReplicatedStorage:FindFirstChild("Rockmode") then
                        ReplicatedStorage.Rockmode:FireServer()
                    end
                    activateAbility("Rockmode")
                end
            end
        end

        -- Trap Brick Spamming (Cooldown ~1.5s)
        if state.AutoTrap then
            activateAbility("lbrick")
            state.TrapBrickCount = state.TrapBrickCount + 1
            if state.TrapBrickCount % 50 == 0 then
                Hub.notify({
                    Title = "Brick Master Progress",
                    Content = "Bricks placed: " .. tostring(state.TrapBrickCount) .. "/1000",
                    Duration = 3
                })
            end
            if state.TrapBrickCount >= 1000 then
                Hub.notify({
                    Title = "🏆 Trap Glove Unlocked!",
                    Content = "Reached 1,000 bricks! Badge awarded.",
                    Duration = 8
                })
            end
        end
    end
end)

-- =========================================================================
-- 3. GENERAL FARM TAB
-- =========================================================================
local function copyToClipboard(text)
    local fn = setclipboard or toclipboard or (syn and syn.write_clipboard) or (Clipboard and Clipboard.set)
    if fn then
        pcall(function() fn(text) end)
        return true
    end
    return false
end

local SLAPPLE_AUTOEXEC_SOURCE = [====[--[[
    ╔═══════════════════════════════════════════════════════════════╗
    ║       UNKNOWN HUB • FAST SLAPPLE FARM (AUTOEXEC VARIANT)      ║
    ║   Instructions: Put this file into your executor's 'autoexec' ║
    ║   folder. It will run automatically on every server join.     ║
    ╚═══════════════════════════════════════════════════════════════╝
]]

repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

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

local guiParent = (gethui and gethui()) or (LocalPlayer and (LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui"))) or (pcall(function() return game:GetService("CoreGui") end) and game:GetService("CoreGui"))
pcall(function()
    if guiParent:FindFirstChild("ENI_SlappleAutoExec_UI") then
        guiParent.ENI_SlappleAutoExec_UI:Destroy()
    end
end)

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ENI_SlappleAutoExec_UI"
screenGui.ResetOnSpawn = false
screenGui.Parent = guiParent

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 260, 0, 110)
mainFrame.Position = UDim2.new(1, -275, 0, 20)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 17, 24)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = mainFrame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 120, 0)
stroke.Thickness = 1.5
stroke.Parent = mainFrame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -16, 0, 24)
title.Position = UDim2.new(0, 8, 0, 4)
title.BackgroundTransparency = 1
title.Text = "🍎 SLAPPLE FARM (AUTOEXEC)"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 12
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = mainFrame

local statusLbl = Instance.new("TextLabel")
statusLbl.Size = UDim2.new(1, -16, 0, 22)
statusLbl.Position = UDim2.new(0, 8, 0, 30)
statusLbl.BackgroundTransparency = 1
statusLbl.Text = "Status: Initializing..."
statusLbl.TextColor3 = Color3.fromRGB(255, 190, 60)
statusLbl.Font = Enum.Font.GothamMedium
statusLbl.TextSize = 11
statusLbl.TextXAlignment = Enum.TextXAlignment.Left
statusLbl.Parent = mainFrame

local slapsLbl = Instance.new("TextLabel")
slapsLbl.Size = UDim2.new(1, -16, 0, 20)
slapsLbl.Position = UDim2.new(0, 8, 0, 52)
slapsLbl.BackgroundTransparency = 1
slapsLbl.Text = "Current Slaps: ..."
slapsLbl.TextColor3 = Color3.fromRGB(180, 190, 210)
slapsLbl.Font = Enum.Font.Gotham
slapsLbl.TextSize = 11
slapsLbl.TextXAlignment = Enum.TextXAlignment.Left
slapsLbl.Parent = mainFrame

local stopBtn = Instance.new("TextButton")
stopBtn.Size = UDim2.new(1, -16, 0, 24)
stopBtn.Position = UDim2.new(0, 8, 1, -28)
stopBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
stopBtn.Text = "STOP FARM"
stopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
stopBtn.Font = Enum.Font.GothamBold
stopBtn.TextSize = 11
stopBtn.Parent = mainFrame

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 5)
btnCorner.Parent = stopBtn

local isStopped = false
stopBtn.MouseButton1Click:Connect(function()
    isStopped = true
    statusLbl.Text = "Status: Stopped by user."
    statusLbl.TextColor3 = Color3.fromRGB(255, 80, 80)
    stopBtn.Text = "FARM STOPPED"
    stopBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
end)

local function updateSlapCounter()
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    local slapsVal = leaderstats and leaderstats:FindFirstChild("Slaps")
    if slapsVal then
        slapsLbl.Text = "Current Slaps: " .. tostring(slapsVal.Value)
    end
end

local function getRoot()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
end

local function enterArenaFast()
    local portal = (Workspace:FindFirstChild("Lobby") and Workspace.Lobby:FindFirstChild("Teleport1"))
        or Workspace:FindFirstChild("Teleport1")
    local root = getRoot()
    if portal and root then
        root.CFrame = portal.CFrame
        if firetouchinterest then
            pcall(function()
                firetouchinterest(root, portal, 0)
                firetouchinterest(root, portal, 1)
            end)
        end
        local s = tick()
        while tick() - s < 0.4 do
            RunService.Heartbeat:Wait()
            local c = LocalPlayer.Character
            if c and c:FindFirstChild("isInArena") and c.isInArena.Value == true then
                break
            end
        end
    end
end

local function serverHopFast()
    if isStopped then return end
    statusLbl.Text = "Status: Hopping server..."
    statusLbl.TextColor3 = Color3.fromRGB(120, 200, 255)

    local placeId = game.PlaceId or 6403373529
    local currentJobId = game.JobId

    task.spawn(function()
        local url = "https://games.roblox.com/v1/games/" .. tostring(placeId) .. "/servers/Public?sortOrder=Asc&limit=100"
        local success, res = pcall(function()
            if game.HttpGet then return game:HttpGet(url)
            elseif request then return request({Url = url, Method = "GET"}).Body
            elseif http_request then return http_request({Url = url, Method = "GET"}).Body end
            return nil
        end)
        local candidates = {}
        if success and res then
            local decOk, data = pcall(function() return HttpService:JSONDecode(res) end)
            if decOk and data and data.data then
                for _, s in ipairs(data.data) do
                    local count = s.playing or 0
                    if s.id ~= currentJobId and count >= 2 and count < (s.maxPlayers or 14) then
                        table.insert(candidates, s)
                    end
                end
            end
        end

        if #candidates > 0 then
            local chosen = candidates[math.random(1, #candidates)]
            TeleportService:TeleportToPlaceInstance(placeId, chosen.id, LocalPlayer)
            task.delay(4.5, function()
                if not isStopped then TeleportService:Teleport(placeId, LocalPlayer) end
            end)
        else
            TeleportService:Teleport(placeId, LocalPlayer)
        end
    end)
end

task.spawn(function()
    updateSlapCounter()
    local root = getRoot()
    local sWait = tick()
    while not root and not isStopped and (tick() - sWait < 5) do task.wait(0.04) root = getRoot() end
    if isStopped then return end

    local char = LocalPlayer.Character
    local inArena = char and char:FindFirstChild("isInArena")
    if not (inArena and inArena.Value == true) then enterArenaFast() end
    if isStopped then return end

    local slapplesFolder = Workspace:FindFirstChild("Arena")
        and Workspace.Arena:FindFirstChild("island5")
        and Workspace.Arena.island5:FindFirstChild("Slapples")
    if not slapplesFolder then slapplesFolder = Workspace:FindFirstChild("Slapples", true) end

    if slapplesFolder then
        root = getRoot()
        local activeSlapples = {}
        for _, s in ipairs(slapplesFolder:GetChildren()) do
            local glove = s:FindFirstChild("Glove")
            if glove and glove:IsA("BasePart") and glove.Transparency < 0.5 then
                table.insert(activeSlapples, glove)
            end
        end

        if #activeSlapples > 0 then
            statusLbl.Text = "Status: Harvesting " .. tostring(#activeSlapples) .. " Slapples..."
            statusLbl.TextColor3 = Color3.fromRGB(0, 255, 140)
            for _, glove in ipairs(activeSlapples) do
                if isStopped then break end
                if root and glove and glove.Parent and glove.Transparency < 0.5 then
                    root.AssemblyLinearVelocity = Vector3.zero
                    root.AssemblyAngularVelocity = Vector3.zero
                    root.CFrame = glove.CFrame
                    if firetouchinterest then
                        pcall(function()
                            firetouchinterest(root, glove, 0)
                            firetouchinterest(root, glove, 1)
                        end)
                    end
                    local charParts = (LocalPlayer.Character and LocalPlayer.Character:GetChildren()) or {}
                    for _, p in ipairs(charParts) do
                        if p:IsA("BasePart") and firetouchinterest then
                            pcall(function()
                                firetouchinterest(p, glove, 0)
                                firetouchinterest(p, glove, 1)
                            end)
                        end
                    end
                    task.wait(0.04)
                end
            end
        else
            statusLbl.Text = "Status: Island empty."
            statusLbl.TextColor3 = Color3.fromRGB(255, 140, 140)
        end
    end

    updateSlapCounter()
    task.wait(0.05)
    if not isStopped then serverHopFast() end
end)
]====]

local _SLAPPLE_SOURCE = [===[
repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

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

local function getQueueFunc()
    return (syn and syn.queue_on_teleport) or queue_on_teleport or (fluxus and fluxus.queue_on_teleport) or (getgenv and getgenv().queue_on_teleport)
end

local isStopped = false

local function queueSelf()
    if isStopped then return end
    local q = getQueueFunc()
    local src = _G._SLAPPLE_FARM_SRC or (getgenv and getgenv()._SLAPPLE_FARM_SRC)
    if q and src then
        pcall(function()
            local payload = "_G._SLAPPLE_FARM_SRC = " .. string.format("%q", src) .. "; loadstring(_G._SLAPPLE_FARM_SRC)();"
            q(payload)
        end)
    end
end

-- Ensure queueSelf is queued immediately on load and on teleport events
queueSelf()
pcall(function()
    if TeleportService.TeleportInit then
        TeleportService.TeleportInit:Connect(queueSelf)
    end
end)

if getgenv then
    getgenv()._SlappleFarmStats = getgenv()._SlappleFarmStats or {totalHarvested = 0, totalHops = 0}
end
if not _G._SlappleFarmStats then
    _G._SlappleFarmStats = {totalHarvested = 0, totalHops = 0}
end

local function getStats()
    return (getgenv and getgenv()._SlappleFarmStats) or _G._SlappleFarmStats
end

local guiParent = (gethui and gethui()) or (LocalPlayer and (LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui"))) or (pcall(function() return game:GetService("CoreGui") end) and game:GetService("CoreGui"))
pcall(function()
    if guiParent:FindFirstChild("ENI_SlappleQueue_UI") then
        guiParent.ENI_SlappleQueue_UI:Destroy()
    end
end)

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ENI_SlappleQueue_UI"
screenGui.ResetOnSpawn = false
screenGui.Parent = guiParent

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 270, 0, 125)
mainFrame.Position = UDim2.new(1, -285, 0, 20)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 17, 24)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = mainFrame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(0, 210, 255)
stroke.Thickness = 1.5
stroke.Parent = mainFrame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -16, 0, 24)
title.Position = UDim2.new(0, 8, 0, 4)
title.BackgroundTransparency = 1
title.Text = "🍎 AUTO SLAPPLE (QUEUE-HOP)"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 12
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = mainFrame

local statusLbl = Instance.new("TextLabel")
statusLbl.Size = UDim2.new(1, -16, 0, 20)
statusLbl.Position = UDim2.new(0, 8, 0, 28)
statusLbl.BackgroundTransparency = 1
statusLbl.Text = "Status: Initializing..."
statusLbl.TextColor3 = Color3.fromRGB(0, 220, 255)
statusLbl.Font = Enum.Font.GothamMedium
statusLbl.TextSize = 11
statusLbl.TextXAlignment = Enum.TextXAlignment.Left
statusLbl.Parent = mainFrame

local slapsLbl = Instance.new("TextLabel")
slapsLbl.Size = UDim2.new(1, -16, 0, 18)
slapsLbl.Position = UDim2.new(0, 8, 0, 48)
slapsLbl.BackgroundTransparency = 1
slapsLbl.Text = "Current Slaps: ..."
slapsLbl.TextColor3 = Color3.fromRGB(180, 190, 210)
slapsLbl.Font = Enum.Font.Gotham
slapsLbl.TextSize = 11
slapsLbl.TextXAlignment = Enum.TextXAlignment.Left
slapsLbl.Parent = mainFrame

local sessionLbl = Instance.new("TextLabel")
sessionLbl.Size = UDim2.new(1, -16, 0, 18)
sessionLbl.Position = UDim2.new(0, 8, 0, 68)
sessionLbl.BackgroundTransparency = 1
local curStats = getStats()
sessionLbl.Text = "Session: " .. tostring(curStats.totalHarvested) .. " slapples | " .. tostring(curStats.totalHops) .. " hops"
sessionLbl.TextColor3 = Color3.fromRGB(140, 230, 140)
sessionLbl.Font = Enum.Font.Gotham
sessionLbl.TextSize = 10
sessionLbl.TextXAlignment = Enum.TextXAlignment.Left
sessionLbl.Parent = mainFrame

local stopBtn = Instance.new("TextButton")
stopBtn.Size = UDim2.new(1, -16, 0, 24)
stopBtn.Position = UDim2.new(0, 8, 1, -28)
stopBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
stopBtn.Text = "STOP AUTO-FARM"
stopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
stopBtn.Font = Enum.Font.GothamBold
stopBtn.TextSize = 11
stopBtn.Parent = mainFrame

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 5)
btnCorner.Parent = stopBtn

stopBtn.MouseButton1Click:Connect(function()
    isStopped = true
    _G._SLAPPLE_FARM_SRC = nil
    if getgenv then getgenv()._SLAPPLE_FARM_SRC = nil end
    statusLbl.Text = "Status: Stopped by user."
    statusLbl.TextColor3 = Color3.fromRGB(255, 80, 80)
    stopBtn.Text = "FARM STOPPED"
    stopBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
end)

local function updateSlapCounter()
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    local slapsVal = leaderstats and leaderstats:FindFirstChild("Slaps")
    if slapsVal then
        slapsLbl.Text = "Current Slaps: " .. tostring(slapsVal.Value)
    end
end

local function getRoot()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
end

local function enterArenaFast()
    local portal = (Workspace:FindFirstChild("Lobby") and Workspace.Lobby:FindFirstChild("Teleport1"))
        or Workspace:FindFirstChild("Teleport1")
    local root = getRoot()
    if portal and root then
        root.CFrame = portal.CFrame
        if firetouchinterest then
            pcall(function()
                firetouchinterest(root, portal, 0)
                firetouchinterest(root, portal, 1)
            end)
        end
        local s = tick()
        while tick() - s < 0.4 do
            RunService.Heartbeat:Wait()
            local c = LocalPlayer.Character
            if c and c:FindFirstChild("isInArena") and c.isInArena.Value == true then
                break
            end
        end
    end
end

local function serverHopFast()
    if isStopped then return end
    statusLbl.Text = "Status: Hopping server..."
    statusLbl.TextColor3 = Color3.fromRGB(120, 200, 255)

    queueSelf()
    local statsObj = getStats()
    statsObj.totalHops = statsObj.totalHops + 1

    local placeId = game.PlaceId or 6403373529
    local currentJobId = game.JobId

    task.spawn(function()
        local url = "https://games.roblox.com/v1/games/" .. tostring(placeId) .. "/servers/Public?sortOrder=Asc&limit=100"
        local success, res = pcall(function()
            if game.HttpGet then return game:HttpGet(url)
            elseif request then return request({Url = url, Method = "GET"}).Body
            elseif http_request then return http_request({Url = url, Method = "GET"}).Body end
            return nil
        end)
        local candidates = {}
        if success and res then
            local decOk, data = pcall(function() return HttpService:JSONDecode(res) end)
            if decOk and data and data.data then
                for _, s in ipairs(data.data) do
                    local count = s.playing or 0
                    if s.id ~= currentJobId and count >= 2 and count < (s.maxPlayers or 14) then
                        table.insert(candidates, s)
                    end
                end
            end
        end

        if #candidates > 0 then
            local chosen = candidates[math.random(1, #candidates)]
            queueSelf()
            TeleportService:TeleportToPlaceInstance(placeId, chosen.id, LocalPlayer)
            task.delay(4.5, function()
                if not isStopped then
                    queueSelf()
                    TeleportService:Teleport(placeId, LocalPlayer)
                end
            end)
        else
            queueSelf()
            TeleportService:Teleport(placeId, LocalPlayer)
        end
    end)
end

task.spawn(function()
    updateSlapCounter()
    local root = getRoot()
    local sWait = tick()
    while not root and not isStopped and (tick() - sWait < 5) do task.wait(0.04) root = getRoot() end
    if isStopped then return end

    local char = LocalPlayer.Character
    local inArena = char and char:FindFirstChild("isInArena")
    if not (inArena and inArena.Value == true) then enterArenaFast() end
    if isStopped then return end

    local slapplesFolder = Workspace:FindFirstChild("Arena")
        and Workspace.Arena:FindFirstChild("island5")
        and Workspace.Arena.island5:FindFirstChild("Slapples")
    if not slapplesFolder then slapplesFolder = Workspace:FindFirstChild("Slapples", true) end

    if slapplesFolder then
        root = getRoot()
        local activeSlapples = {}
        for _, s in ipairs(slapplesFolder:GetChildren()) do
            local glove = s:FindFirstChild("Glove")
            if glove and glove:IsA("BasePart") and glove.Transparency < 0.5 then
                table.insert(activeSlapples, glove)
            end
        end

        if #activeSlapples > 0 then
            statusLbl.Text = "Status: Harvesting " .. tostring(#activeSlapples) .. " Slapples..."
            statusLbl.TextColor3 = Color3.fromRGB(0, 255, 140)
            local collectedCount = 0
            for _, glove in ipairs(activeSlapples) do
                if isStopped then break end
                if root and glove and glove.Parent and glove.Transparency < 0.5 then
                    root.AssemblyLinearVelocity = Vector3.zero
                    root.AssemblyAngularVelocity = Vector3.zero
                    root.CFrame = glove.CFrame
                    if firetouchinterest then
                        pcall(function()
                            firetouchinterest(root, glove, 0)
                            firetouchinterest(root, glove, 1)
                        end)
                    end
                    local charParts = (LocalPlayer.Character and LocalPlayer.Character:GetChildren()) or {}
                    for _, p in ipairs(charParts) do
                        if p:IsA("BasePart") and firetouchinterest then
                            pcall(function()
                                firetouchinterest(p, glove, 0)
                                firetouchinterest(p, glove, 1)
                            end)
                        end
                    end
                    collectedCount = collectedCount + 1
                    task.wait(0.04)
                end
            end
            local statsObj = getStats()
            statsObj.totalHarvested = statsObj.totalHarvested + collectedCount
        else
            statusLbl.Text = "Status: Island empty."
            statusLbl.TextColor3 = Color3.fromRGB(255, 140, 140)
        end
    end

    updateSlapCounter()
    task.wait(0.05)
    if not isStopped then serverHopFast() end
end)
]===]

local function queueSlappleNextHop()
    local q = (syn and syn.queue_on_teleport) or queue_on_teleport or (fluxus and fluxus.queue_on_teleport) or (getgenv and getgenv().queue_on_teleport)
    if q and _SLAPPLE_SOURCE then
        pcall(function()
            local payload = "_G._SLAPPLE_FARM_SRC = " .. string.format("%q", _SLAPPLE_SOURCE) .. "; loadstring(_G._SLAPPLE_FARM_SRC)();"
            q(payload)
        end)
    end
end

local function serverHop()
    local placeId = game.PlaceId or 6403373529
    local currentJobId = game.JobId
    
    Hub.notify({
        Title = "Server Hop",
        Content = "Searching for optimal server...",
        Duration = 3
    })

    if state.AutoSlapple then
        queueSlappleNextHop()
    end

    task.spawn(function()
        local function fetchServers(cursor)
            local url = "https://games.roblox.com/v1/games/" .. tostring(placeId) .. "/servers/Public?sortOrder=Asc&limit=100"
            if cursor then url = url .. "&cursor=" .. tostring(cursor) end
            local success, res = pcall(function()
                if game.HttpGet then return game:HttpGet(url)
                elseif request then return request({Url = url, Method = "GET"}).Body
                elseif http_request then return http_request({Url = url, Method = "GET"}).Body end
                return nil
            end)
            if success and res then
                local decOk, data = pcall(function() return HttpService:JSONDecode(res) end)
                if decOk and data and data.data then
                    return data.data, data.nextPageCursor
                end
            end
            return nil, nil
        end

        local candidateServers = {}
        local cursor = nil
        for _ = 1, 3 do
            local servers, nextCursor = fetchServers(cursor)
            if servers then
                for _, s in ipairs(servers) do
                    local count = s.playing or 0
                    if s.id ~= currentJobId and count >= 2 and count <= 10 and count < (s.maxPlayers or 14) then
                        table.insert(candidateServers, s)
                    end
                end
            end
            if #candidateServers >= 6 or not nextCursor then break end
            cursor = nextCursor
        end

        if #candidateServers > 0 then
            local chosen = candidateServers[math.random(1, #candidateServers)]
            Hub.notify({
                Title = "Server Hop",
                Content = "Teleporting to server (" .. tostring(chosen.playing) .. "/" .. tostring(chosen.maxPlayers) .. " players)...",
                Duration = 4
            })
            if state.AutoSlapple then queueSlappleNextHop() end
            TeleportService:TeleportToPlaceInstance(placeId, chosen.id, LocalPlayer)
            task.delay(4.5, function()
                if state.AutoSlapple then
                    queueSlappleNextHop()
                    TeleportService:Teleport(placeId, LocalPlayer)
                end
            end)
        else
            Hub.notify({
                Title = "Server Hop",
                Content = "Rejoining...",
                Duration = 3
            })
            if state.AutoSlapple then queueSlappleNextHop() end
            TeleportService:Teleport(placeId, LocalPlayer)
        end
    end)
end

local function fastHarvestSlapples()
    local char = getCharacter()
    local inArena = char and char:FindFirstChild("isInArena")
    if isInLobby() or not (inArena and inArena.Value == true) then
        enterArena()
        task.wait(0.1)
    end

    local slapplesFolder = Workspace:FindFirstChild("Arena")
        and Workspace.Arena:FindFirstChild("island5")
        and Workspace.Arena.island5:FindFirstChild("Slapples")

    if not slapplesFolder then
        slapplesFolder = Workspace:FindFirstChild("Slapples", true)
    end

    if not slapplesFolder then return 0 end

    local root = getRoot()
    if not root then return 0 end
    local hum = char and char:FindFirstChildWhichIsA("Humanoid")

    local function getActive()
        local list = {}
        for _, s in ipairs(slapplesFolder:GetChildren()) do
            local glove = s:FindFirstChild("Glove")
            if glove and glove:IsA("BasePart") and glove.Transparency < 0.5 then
                table.insert(list, glove)
            end
        end
        return list
    end

    local totalHarvested = 0
    for pass = 1, 2 do
        local active = getActive()
        if #active == 0 then break end

        for _, glove in ipairs(active) do
            if glove and glove.Parent and glove.Transparency < 0.5 then
                if hum then hum.PlatformStand = false end
                root.AssemblyLinearVelocity = Vector3.zero
                root.AssemblyAngularVelocity = Vector3.zero
                root.CFrame = glove.CFrame
                if firetouchinterest then
                    pcall(function()
                        firetouchinterest(root, glove, 0)
                        firetouchinterest(root, glove, 1)
                    end)
                    local charParts = (char and char:GetChildren()) or {}
                    for _, p in ipairs(charParts) do
                        if p:IsA("BasePart") then
                            pcall(function()
                                firetouchinterest(p, glove, 0)
                                firetouchinterest(p, glove, 1)
                            end)
                        end
                    end
                end
                totalHarvested = totalHarvested + 1
                task.wait(0.04)
            end
        end
        task.wait(0.02)
    end

    return totalHarvested
end


Hub.CreateSection(farmTab, "Slapple Farming")

Hub.CreateToggle(farmTab, "🍎 Fast Auto Slapple (Queue-Hop)", false, function(toggled)
    state.AutoSlapple = toggled
    if toggled then
        Hub.notify({
            Title = "Auto Slapple",
            Content = "Fast Auto-Slapple with persistent Queue-Hop activated!",
            Duration = 4
        })
    end
end)

Hub.CreateToggle(farmTab, "🌐 Auto Server-Hop", true, function(toggled)
    state.AutoSlappleServerHop = toggled
end)

Hub.CreateButton(farmTab, "⚡ Harvest Slapples (Once)", function()
    local count = fastHarvestSlapples()
    Hub.notify({
        Title = "Slapple Harvest",
        Content = "Harvested " .. tostring(count) .. " active slapples.",
        Duration = 3
    })
end)

Hub.CreateButton(farmTab, "🚀 Server Hop Now", function()
    serverHop()
end)

Hub.CreateButton(farmTab, "📋 Copy Auto-Exec Script", function()
    local success = copyToClipboard(SLAPPLE_AUTOEXEC_SOURCE)
    if success then
        Hub.notify({
            Title = "📋 Copied to Clipboard",
            Content = "Auto-exec script copied! Paste it into your executor's autoexec folder.",
            Duration = 5
        })
    else
        Hub.notify({
            Title = "Clipboard Error",
            Content = "Your executor does not support clipboard copying.",
            Duration = 4
        })
    end
end)

Hub.CreateSection(farmTab, "General Farming")

Hub.CreateToggle(farmTab, "Auto Candy", false, function(toggled)
    state.AutoCandy = toggled
end)

Hub.CreateToggle(farmTab, "Auto Tycoon", false, function(toggled)
    state.AutoTycoon = toggled
end)

Hub.CreateButton(farmTab, "🏆 Claim Badges", function()
    for _, desc in ipairs(ReplicatedStorage:GetDescendants()) do
        if desc:IsA("RemoteEvent") and desc.Name:lower():find("badge") then
            pcall(function() desc:FireServer() end)
        end
    end
    Hub.notify({
        Title = "Badges",
        Content = "Claimed available badges.",
        Duration = 3
    })
end)

-- Farm Background Loops
task.spawn(function()
    while true do
        task.wait(0.1)
        if state.AutoSlapple then
            local count = fastHarvestSlapples()
            if count > 0 then
                Hub.notify({
                    Title = "🍎 Slapples Collected",
                    Content = "Harvested " .. tostring(count) .. " slapples!",
                    Duration = 2
                })
            end

            if state.AutoSlappleServerHop then
                task.wait(0.1)
                serverHop()
                task.wait(5)
            else
                task.wait(1.5)
            end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(0.5)
        if state.AutoCandy then
            for _, item in ipairs(Workspace:GetChildren()) do
                if item.Name == "CandyCorn" or item.Name == "Candy" or item.Name == "Orb" then
                    local myRoot = getRoot()
                    local itemPart = item:IsA("BasePart") and item or item:FindFirstChildWhichIsA("BasePart")
                    if myRoot and itemPart then
                        myRoot.CFrame = itemPart.CFrame
                        task.wait(0.1)
                    end
                end
            end
        end

        if state.AutoTycoon then
            for _, tycoon in ipairs(Workspace:GetChildren()) do
                if tycoon.Name:find("Tycoon") then
                    local clicker = tycoon:FindFirstChild("Click", true) or tycoon:FindFirstChild("Clicker", true)
                    if clicker and clicker:IsA("BasePart") then
                        pcall(function()
                            fireclickdetector(clicker:FindFirstChildWhichIsA("ClickDetector"))
                        end)
                    end
                end
            end
        end
    end
end)

-- =========================================================================
-- 4. ALT CONTROL TAB
-- =========================================================================
local function getMainPlayer()
    if state.MainUsername and state.MainUsername ~= "" then
        local p = Players:FindFirstChild(state.MainUsername)
        if p then return p end
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.Name:lower():find(state.MainUsername:lower()) or plr.DisplayName:lower():find(state.MainUsername:lower()) then
                return plr
            end
        end
    end
    return nil
end

local function getPlayerNamesList()
    local names = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(names, p.Name)
        end
    end
    if #names == 0 then table.insert(names, "No Other Players") end
    return names
end

Hub.CreateSection(altTab, "Main Target")

local mainTargetDropdown = nil
mainTargetDropdown = Hub.CreateDropdown(altTab, "Select Main Account", getPlayerNamesList(), getPlayerNamesList()[1], function(selected)
    if selected and selected ~= "No Other Players" then
        state.MainUsername = selected
        Hub.notify({
            Title = "Target Set",
            Content = "Target: @" .. selected,
            Duration = 2
        })
    end
end)

Hub.CreateButton(altTab, "🔄 Refresh Players", function()
    local updated = getPlayerNamesList()
    if mainTargetDropdown and mainTargetDropdown.Refresh then
        mainTargetDropdown.Refresh(updated)
    end
    Hub.notify({
        Title = "Players Refreshed",
        Content = tostring(#updated) .. " players found.",
        Duration = 2
    })
end)

-- Custom Username Text Input helper
pcall(function()
    local inputFrame = Instance.new("Frame")
    inputFrame.Size = UDim2.new(1, -6, 0, 42)
    inputFrame.BackgroundColor3 = Color3.fromRGB(18, 22, 32)
    inputFrame.BorderSizePixel = 0
    inputFrame.Parent = altTab

    local uic = Instance.new("UICorner")
    uic.CornerRadius = UDim.new(0, 7)
    uic.Parent = inputFrame

    local uis = Instance.new("UIStroke")
    uis.Color = Color3.fromRGB(34, 42, 58)
    uis.Thickness = 1
    uis.Parent = inputFrame

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.4, 0, 1, 0)
    lbl.Position = UDim2.new(0, 14, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = "Main User:"
    lbl.TextColor3 = Color3.fromRGB(230, 235, 245)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = inputFrame

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0.55, -14, 0, 28)
    box.Position = UDim2.new(0.45, 0, 0.5, -14)
    box.BackgroundColor3 = Color3.fromRGB(12, 15, 22)
    box.PlaceholderText = "Username..."
    box.PlaceholderColor3 = Color3.fromRGB(110, 120, 145)
    box.Text = state.MainUsername or ""
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.Font = Enum.Font.GothamBold
    box.TextSize = 11
    box.ClearTextOnFocus = false
    box.Parent = inputFrame

    local buic = Instance.new("UICorner")
    buic.CornerRadius = UDim.new(0, 5)
    buic.Parent = box

    box.FocusLost:Connect(function()
        if box.Text and box.Text ~= "" then
            state.MainUsername = box.Text:gsub("^%s*(.-)%s*$", "%1")
            Hub.notify({
                Title = "Target Set",
                Content = "Target: @" .. state.MainUsername,
                Duration = 2
            })
        end
    end)
end)

Hub.CreateToggle(altTab, "🤖 Alt Mode", false, function(toggled)
    state.IsAltAccount = toggled
    if toggled then
        Hub.notify({
            Title = "Alt Mode",
            Content = "Alt mode enabled.",
            Duration = 3
        })
    end
end)

Hub.CreateToggle(altTab, "💬 Chat Commands", true, function(toggled)
    state.AltChatCommands = toggled
end)

Hub.CreateSection(altTab, "Alt Movement")

---- Auto TP to Megarock of Main Account
local function getMegarockOfPlayer(targetPlr)
    if not targetPlr then return nil end
    local char = targetPlr.Character
    if char then
        local directRock = char:FindFirstChild("rock") or char:FindFirstChild("Rock") or char:FindFirstChild("Megarock") or char:FindFirstChild("Diamond")
        if directRock and directRock:IsA("BasePart") then
            return directRock
        end
        for _, part in ipairs(char:GetChildren()) do
            local pName = part.Name:lower()
            if (pName:find("rock") or pName:find("megarock") or pName:find("diamond")) and part:IsA("BasePart") then
                return part
            end
        end
    end
    local targetRoot = getRoot(targetPlr)
    if targetRoot then
        for _, obj in ipairs(Workspace:GetChildren()) do
            local oName = obj.Name:lower()
            if (oName:find("rock") or oName:find("megarock") or oName == "customrock") then
                local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
                if part and (part.Position - targetRoot.Position).Magnitude < 35 then
                    return part
                end
            end
        end
        return targetRoot
    end
    return nil
end

Hub.CreateToggle(altTab, "🚀 Auto Safe Zone", false, function(toggled)
    state.AltAutoSafeZone = toggled
    if toggled then
        state.IsAltAccount = true
        task.spawn(function()
            if isInLobby() then
                Hub.notify({
                    Title = "Entering Arena",
                    Content = "Entering arena...",
                    Duration = 2
                })
                enterArena()
            end
            teleportToSafeZone()
            Hub.notify({
                Title = "Safe Zone",
                Content = "Teleported to Safe Zone.",
                Duration = 2
            })
        end)
    end
end)

Hub.CreateToggle(altTab, "🪨 Auto TP to Megarock", false, function(toggled)
    state.AltAutoTPMegarock = toggled
    if toggled then
        state.IsAltAccount = true
        task.spawn(function()
            if isInLobby() then
                Hub.notify({
                    Title = "Entering Arena",
                    Content = "Entering arena...",
                    Duration = 2
                })
                enterArena()
            end

            local mainPlr = getMainPlayer()
            if not mainPlr then
                Hub.notify({
                    Title = "Main Not Found",
                    Content = "Select or enter Main username first!",
                    Duration = 3
                })
                return
            end

            local rockPart = getMegarockOfPlayer(mainPlr)
            local root = getRoot()
            if root and rockPart then
                root.CFrame = CFrame.new(rockPart.Position + Vector3.new(0, (rockPart.Size.Y / 2) + 2.5, 0))
                Hub.notify({
                    Title = "Teleported",
                    Content = "Positioned on Main Megarock.",
                    Duration = 2
                })
            end
        end)
    end
end)

Hub.CreateToggle(altTab, "🎯 Follow Main", false, function(toggled)
    state.AltFollowMain = toggled
end)

Hub.CreateSlider(altTab, "Follow Distance", 2, 12, 4, "", function(val)
    state.AltFollowDistance = val
end)

Hub.CreateToggle(altTab, "🥩 Feed Slaps", false, function(toggled)
    state.AltFeedSlaps = toggled
end)

Hub.CreateToggle(altTab, "🔄 Auto Re-enter Arena", false, function(toggled)
    state.AltAutoReenter = toggled
end)

Hub.CreateSection(altTab, "Slap Assistance")

Hub.CreateButton(altTab, "👋 Slap Main", function()
    local mainPlr = getMainPlayer()
    if mainPlr and mainPlr.Character then
        slapPlayer(mainPlr.Character)
        Hub.notify({
            Title = "Alt Slap",
            Content = "Slapped @" .. mainPlr.Name,
            Duration = 2
        })
    else
        Hub.notify({
            Title = "Main Not Found",
            Content = "Select Main account from dropdown!",
            Duration = 3
        })
    end
end)

Hub.CreateToggle(altTab, "🔁 Loop Slap Main", false, function(toggled)
    state.AltLoopSlapMain = toggled
end)

-- Alt Chat Commands Listener
local function bindChatCommands(player)
    player.Chatted:Connect(function(msg)
        if not state.IsAltAccount or not state.AltChatCommands then return end
        local mainPlr = getMainPlayer()
        if mainPlr and player ~= mainPlr then return end

        local cmd = msg:lower():gsub("^%s*(.-)%s*$", "%1")
        if cmd == "!alt come" or cmd == "!alt here" then
            local mRoot = getRoot(mainPlr or player)
            local aRoot = getRoot()
            if mRoot and aRoot then
                aRoot.CFrame = mRoot.CFrame * CFrame.new(0, 0, -state.AltFollowDistance) * CFrame.Angles(0, math.rad(180), 0)
            end
        elseif cmd == "!alt follow on" or cmd == "!alt follow" then
            state.AltFollowMain = true
        elseif cmd == "!alt follow off" or cmd == "!alt stay" or cmd == "!alt stop" then
            state.AltFollowMain = false
            state.AltFeedSlaps = false
        elseif cmd == "!alt feed" then
            state.AltFeedSlaps = true
        elseif cmd == "!alt slap" or cmd == "!alt hit" then
            if (mainPlr or player).Character then
                slapPlayer((mainPlr or player).Character)
            end
        elseif cmd == "!alt reset" or cmd == "!alt die" then
            resetToLobby()
        elseif cmd == "!alt safe" then
            if isInLobby() then
                enterArena()
            end
            teleportToSafeZone()
        end
    end)
end

for _, p in ipairs(Players:GetPlayers()) do
    bindChatCommands(p)
end
Players.PlayerAdded:Connect(bindChatCommands)

-- Alt Background Follow & Feed Loop
task.spawn(function()
    while true do
        task.wait(0.04)
        if state.IsAltAccount then
            local mainPlr = getMainPlayer()
            local mainRoot = mainPlr and getRoot(mainPlr)
            local altRoot = getRoot()
            local altChar = getCharacter()

            if (state.AltAutoReenter or state.AltFeedSlaps or state.AltFollowMain or state.AltAutoTPMegarock or state.AltAutoSafeZone) and isInLobby() then
                enterArena()
            end

            if state.AltAutoSafeZone and not isInLobby() then
                if altRoot and (altRoot.Position - SAFE_ZONE_POS).Magnitude > 60 then
                    teleportToSafeZone()
                end
            end

            if state.AltAutoTPMegarock and mainPlr and not isInLobby() then
                local rockPart = getMegarockOfPlayer(mainPlr)
                if altRoot and rockPart then
                    local targetPos = rockPart.Position + Vector3.new(0, (rockPart.Size.Y / 2) + 2.5, 0)
                    altRoot.CFrame = CFrame.new(targetPos)
                    if altChar then
                        for _, p in ipairs(altChar:GetDescendants()) do
                            if p:IsA("BasePart") then p.CanCollide = false end
                        end
                    end
                end
            end

            if (state.AltFollowMain or state.AltFeedSlaps) and mainRoot and altRoot and not isInLobby() then
                local targetCFrame = mainRoot.CFrame * CFrame.new(0, 0, -state.AltFollowDistance) * CFrame.Angles(0, math.rad(180), 0)
                altRoot.CFrame = targetCFrame
                if altChar then
                    for _, p in ipairs(altChar:GetDescendants()) do
                        if p:IsA("BasePart") then p.CanCollide = false end
                    end
                end
                local hum = getHumanoid()
                if hum and hum:GetState() == Enum.HumanoidStateType.Ragdoll then
                    hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                end
            end
        end
    end
end)

-- Loop Slap Main Background Worker
task.spawn(function()
    while true do
        task.wait(1.5)
        if state.IsAltAccount then
            local mainPlr = getMainPlayer()
            if state.AltLoopSlapMain and mainPlr and mainPlr.Character then
                slapPlayer(mainPlr.Character)
            end
        end
    end
end)

-- =========================================================================
-- 5. DEFENSE TAB
-- =========================================================================
Hub.CreateSection(defenseTab, "Defense")
local voidPlate = nil

Hub.CreateToggle(defenseTab, "Anti-Ragdoll", false, function(toggled)
    state.AntiRagdoll = toggled
end)

Hub.CreateToggle(defenseTab, "Anti-Void Plate", false, function(toggled)
    state.AntiVoid = toggled
    if toggled then
        if not voidPlate or not voidPlate.Parent then
            voidPlate = Instance.new("Part")
            voidPlate.Name = "ENI_AntiVoidPlate"
            voidPlate.Size = Vector3.new(2048, 4, 2048)
            voidPlate.Position = Vector3.new(0, -15, 0)
            voidPlate.Anchored = true
            voidPlate.Transparency = 0.5
            voidPlate.Material = Enum.Material.ForceField
            voidPlate.Color = Color3.fromRGB(0, 195, 245)
            voidPlate.Parent = Workspace
        end
    else
        if voidPlate and voidPlate.Parent then
            voidPlate:Destroy()
            voidPlate = nil
        end
    end
end)

Hub.CreateButton(defenseTab, "🚀 Teleport to Safe Zone", function()
    teleportToSafeZone()
    Hub.notify({
        Title = "Safe Zone",
        Content = "Teleported to Safe Zone.",
        Duration = 3
    })
end)

Hub.CreateSection(defenseTab, "Immunities")

Hub.CreateToggle(defenseTab, "Anti-Megarock", false, function(toggled)
    state.AntiMegarock = toggled
end)

Hub.CreateToggle(defenseTab, "Anti-Timestop", false, function(toggled)
    state.AntiTimestop = toggled
end)

-- Defense Background Loop
task.spawn(function()
    while true do
        task.wait(0.1)
        if state.AntiRagdoll then
            local char = getCharacter()
            if char then
                local ragdollVal = char:FindFirstChild("Ragdolled") or char:FindFirstChild("Ragdoll")
                if ragdollVal and ragdollVal:IsA("ValueBase") then
                    pcall(function() ragdollVal.Value = false end)
                end
                local hum = char:FindFirstChildWhichIsA("Humanoid")
                if hum and hum:GetState() == Enum.HumanoidStateType.Ragdoll then
                    hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                end
            end
        end

        if state.AntiMegarock then
            for _, obj in ipairs(Workspace:GetChildren()) do
                if obj.Name:find("Rock") or obj.Name:find("Megarock") or obj.Name == "CustomRock" then
                    if obj:IsA("BasePart") then
                        obj.CanTouch = false
                    end
                end
            end
        end

        if state.AntiTimestop then
            local char = getCharacter()
            if char then
                local ts = char:FindFirstChild("TS") or char:FindFirstChild("Timestop")
                if ts then
                    pcall(function() ts:Destroy() end)
                end
                local hrp = getRoot()
                if hrp and hrp.Anchored and not state.MegarockCenterLock then
                    hrp.Anchored = false
                end
            end
        end
    end
end)

-- =========================================================================
-- 6. VISUALS TAB
-- =========================================================================
Hub.CreateSection(visualTab, "ESP")

local espFolder = Instance.new("Folder")
espFolder.Name = "ENI_SlapESP"
espFolder.Parent = (gethui and gethui()) or game:GetService("CoreGui") or LocalPlayer:FindFirstChild("PlayerGui")

local function updateESP()
    espFolder:ClearAllChildren()
    if not state.PlayerESP and not state.GloveESP then return end

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local root = p.Character:FindFirstChild("HumanoidRootPart") or p.Character:FindFirstChild("Torso")
            if root then
                local bg = Instance.new("BillboardGui")
                bg.Name = "ESP_" .. p.Name
                bg.Adornee = root
                bg.Size = UDim2.new(0, 160, 0, 40)
                bg.StudsOffset = Vector3.new(0, 3, 0)
                bg.AlwaysOnTop = true
                bg.Parent = espFolder

                local nameLbl = Instance.new("TextLabel")
                nameLbl.Size = UDim2.new(1, 0, 0.5, 0)
                nameLbl.BackgroundTransparency = 1
                nameLbl.Text = p.DisplayName .. " (@" .. p.Name .. ")"
                nameLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
                nameLbl.Font = Enum.Font.GothamBold
                nameLbl.TextSize = 11
                nameLbl.Parent = bg

                if state.GloveESP then
                    local tool = p.Character:FindFirstChildWhichIsA("Tool")
                    local gloveName = tool and tool.Name or "Default"
                    local gloveLbl = Instance.new("TextLabel")
                    gloveLbl.Size = UDim2.new(1, 0, 0.5, 0)
                    gloveLbl.Position = UDim2.new(0, 0, 0.5, 0)
                    gloveLbl.BackgroundTransparency = 1
                    gloveLbl.Text = "🥊 Glove: [" .. gloveName .. "]"
                    gloveLbl.TextColor3 = Color3.fromRGB(255, 180, 0)
                    gloveLbl.Font = Enum.Font.GothamBold
                    gloveLbl.TextSize = 10
                    gloveLbl.Parent = bg
                end
            end
        end
    end
end

Hub.CreateToggle(visualTab, "Player ESP", false, function(toggled)
    state.PlayerESP = toggled
    updateESP()
end)

Hub.CreateToggle(visualTab, "Glove ESP", false, function(toggled)
    state.GloveESP = toggled
    updateESP()
end)

task.spawn(function()
    while true do
        task.wait(2)
        if state.PlayerESP or state.GloveESP then
            updateESP()
        end
    end
end)

Hub.notify({
    Title = "Slap Battles",
    Content = "Unknown Hub loaded.",
    Duration = 3
})
