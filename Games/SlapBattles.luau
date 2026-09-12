
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
    parent = (gethui and gethui()) or game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui"),
    theme = Color3.fromRGB(255, 120, 0),
    secondaryTheme = Color3.fromRGB(180, 50, 255)
})

assert(type(Hub) == "table", "UnknownLibrary returned an invalid hub")

-- =========================================================================
-- Hub Tabs
-- =========================================================================
local combatTab = Hub.createTabButton("Combat", "🥊 Combat", "rbxassetid://10723407390", true)
local badgeTab  = Hub.createTabButton("Badges", "🏆 Auto Gloves", "rbxassetid://10723407389", false)
local farmTab   = Hub.createTabButton("Farm", "⭐ General Farm", "rbxassetid://10723407389", false)
local altTab    = Hub.createTabButton("AltControl", "👥 Alt Control", "rbxassetid://10723407389", false)
local defenseTab = Hub.createTabButton("Defense", "🛡️ Defense & Safe", "rbxassetid://10723407392", false)
local visualTab = Hub.createTabButton("Visuals", "👁️ Visuals & ESP", "rbxassetid://10723407395", false)

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
    PlayerESP = false,
    GloveESP = false,
    -- Auto-Gloves Grinds
    AutoMegarock = false,
    MegarockCenterLock = false,
    AutoFish = false,
    AutoTrap = false,
    AutoVoodoo = false,
    TrapBrickCount = 0,
    -- Alt Control System
    IsAltAccount = false,
    MainUsername = "",
    AltFollowMain = false,
    AltFollowDistance = 4,
    AltFeedSlaps = false,
    AltAutoReenter = false,
    AltLoopSlapMain = false,
    AltSpamReplicaBob = false,
    AltSpamBrick = false,
    AltDiamondRock = false,
    AltAutoTPMegarock = false,
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
    local root = getRoot()
    if not root then return false end
    -- In Slap Battles, Lobby is high up around Y > 200 and X < -800
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

local ARENA_CENTER_POS = Vector3.new(0, -4, 0)

local function teleportToArenaCenter()
    local root = getRoot()
    if root then
        root.CFrame = CFrame.new(ARENA_CENTER_POS + Vector3.new(0, 3, 0))
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
        task.wait(1.5)
    end
end

local function ensureEquippedAndInArena(gloveName)
    local cur = getCurrentGlove()
    if cur:lower() ~= gloveName:lower() then
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
        task.wait(1)
    end

    -- Equip tool from Backpack if not already holding it
    local char = getCharacter()
    local tool = LocalPlayer.Backpack:FindFirstChild(gloveName) or (char and char:FindFirstChild(gloveName))
    if tool and tool.Parent == LocalPlayer.Backpack and char and char:FindFirstChildWhichIsA("Humanoid") then
        pcall(function()
            char.Humanoid:EquipTool(tool)
        end)
        task.wait(0.4)
    end

    -- Teleport to Safe Zone
    teleportToSafeZone()
    task.wait(0.5)
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
            return
        end
    end

    local bEvents = ReplicatedStorage:FindFirstChild("Events")
    if bEvents and bEvents:FindFirstChild("Ability") then
        pcall(function() bEvents.Ability:FireServer() end)
    else
        pcall(function()
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
            task.wait(0.05)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
        end)
    end
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

Hub.CreateSection(combatTab, "Slap Aura & Reach")

Hub.CreateToggle(combatTab, "Slap Aura", false, function(toggled)
    state.SlapAura = toggled
end)

Hub.CreateSlider(combatTab, "Aura Range", 10, 35, 18, "", function(val)
    state.SlapAuraDistance = val
end)

Hub.CreateToggle(combatTab, "Fast Slap Loop", false, function(toggled)
    state.FastSlap = toggled
end)

Hub.CreateSection(combatTab, "Glove Abilities & Combat")

Hub.CreateToggle(combatTab, "Auto Reverse Parry", false, function(toggled)
    state.AutoParry = toggled
end)

Hub.CreateButton(combatTab, "⚡ Fire Glove Ability (E)", function()
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
Hub.CreateSection(badgeTab, "One-Click Instant Badge Solvers")

local ELUDE_MAZE_PLACE_ID = 11828384869

local function isInsideEludeMaze()
    if Workspace:FindFirstChild("Lobby") or Workspace:FindFirstChild("BountyHunterRoom") then
        return false
    end
    return (game.PlaceId == ELUDE_MAZE_PLACE_ID) or (Workspace:FindFirstChild("Collectable") ~= nil) or (Workspace:FindFirstChild("Maze") ~= nil) or (Workspace:FindFirstChild("Pim") ~= nil)
end

local function solveEludeKeypad()
    -- 1. Try Direct Teleport to the exact Maze Place ID (11828384869)
    pcall(function()
        TeleportService:Teleport(ELUDE_MAZE_PLACE_ID, LocalPlayer)
    end)
    if ReplicatedStorage:FindFirstChild("TeleportElude") then
        pcall(function() ReplicatedStorage.TeleportElude:FireServer() end)
    end

    -- 2. If in Lobby, enter arena first so server registers active state for keypad
    if isInLobby() then
        Hub.notify({
            Title = "Entering Arena First",
            Content = "Stepping through arena portal before teleporting to Keypad...",
            Duration = 3
        })
        enterArena()
        task.wait(1)
    end

    local keypad = Workspace:FindFirstChild("Keypad")
    if not keypad then
        Hub.notify({
            Title = "Teleporting...",
            Content = "Teleport request sent to Elude Maze (Place 11828384869).",
            Duration = 5
        })
        return false
    end

    local buttons = keypad:FindFirstChild("Buttons")
    if not buttons then return false end

    local root = getRoot()
    if root then
        -- Teleport player directly in front of Keypad on Slapple Island
        root.CFrame = keypad:GetPivot() * CFrame.new(0, 0, -4) * CFrame.Angles(0, math.rad(180), 0)
        task.wait(0.5)
    end

    local pCount = #Players:GetPlayers()
    local code = tostring((pCount * 25) + 1100 - 7)

    Hub.notify({
        Title = "Keypad Solver",
        Content = "Entering code [" .. code .. "] for " .. tostring(pCount) .. " players...",
        Duration = 4
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
        Title = "Keypad Solved!",
        Content = "Code entered successfully. Waiting for server to teleport to Maze...",
        Duration = 6
    })
    return true
end

-- Direct Teleport Button
Hub.CreateButton(badgeTab, "🚀 Direct Teleport to Elude Maze (11828384869)", function()
    Hub.notify({
        Title = "Direct Teleport",
        Content = "Teleporting directly to Elude Maze Place (11828384869)...",
        Duration = 5
    })
    pcall(function()
        TeleportService:Teleport(ELUDE_MAZE_PLACE_ID, LocalPlayer)
    end)
    if ReplicatedStorage:FindFirstChild("TeleportElude") then
        pcall(function() ReplicatedStorage.TeleportElude:FireServer() end)
    end
end)

-- Auto-Elude Solver (Solves Keypad in Main Arena -> Fast Sweeps 4 Relics in Maze)
Hub.CreateButton(badgeTab, "🚪 Auto-Get Elude Glove (Keypad & Maze)", function()
    task.spawn(function()
        if not isInsideEludeMaze() then
            solveEludeKeypad()
            return
        end

        -- Inside Elude Maze Place (11828384869): Fast sweep all 4 relics
        Hub.notify({
            Title = "Elude Maze Active",
            Content = "Collecting 4 hidden relics instantly...",
            Duration = 4
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
            Title = "🏆 Elude Glove Done!",
            Content = "Collected relics (" .. tostring(collected) .. ") and claimed Elude Glove!",
            Duration = 8
        })
    end)
end)

-- Auto-Counter Glove Solver (Solves Keypad in Main Arena -> Pulls Secret Lever in Maze)
Hub.CreateButton(badgeTab, "🕵️ Auto-Get Counter Glove (Keypad & Lever)", function()
    task.spawn(function()
        if not isInsideEludeMaze() then
            solveEludeKeypad()
            return
        end

        -- INSIDE ELUDE MAZE: Automated Lever Pull + Safe Zone Evade + Relic Claim
        Hub.notify({
            Title = "Counter Solver (Inside Maze)",
            Content = "Searching for secret lever in maze...",
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
                Title = "Counter Lever Activated!",
                Content = "Lever pulled! Teleporting to Safe Zone to evade Pim and wait for Counter Glove spawn...",
                Duration = 5
            })
        else
            Hub.notify({
                Title = "Counter Lever",
                Content = "Lever not spawned yet or hidden. Teleporting to Safe Zone to stay safe...",
                Duration = 4
            })
        end

        -- Move to the standard unified Sky Safe Zone
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
                                    Title = "🏆 Counter Glove Claimed!",
                                    Content = "Touched Counter Relic / Pedestal!",
                                    Duration = 8
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

-- Auto-[REDACTED] Glove Solver (With Safe 5,000 Slaps Check)
Hub.CreateButton(badgeTab, "⬛ Auto-Get [REDACTED] Glove (5k Slaps Check)", function()
    task.spawn(function()
        local currentSlaps = getSlapCount()
        if currentSlaps < 5000 then
            Hub.notify({
                Title = "⚠️ [REDACTED] Locked",
                Content = "You need at least 5,000 slaps to enter! Current: " .. tostring(currentSlaps),
                Duration = 5
            })
            return
        end

        Hub.notify({
            Title = "[REDACTED] Solver",
            Content = "Slap check passed (" .. tostring(currentSlaps) .. " slaps). Searching for doorway...",
            Duration = 4
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
            Title = "[REDACTED] Solver",
            Content = "Completed door traversal sequence.",
            Duration = 4
        })
    end)
end)

Hub.CreateSection(badgeTab, "AFK Safe-Zone & Center Glove Grinds")

-- Auto-Megarock Center Lock (Teleports & anchors player to Arena Center so gloves cannot move rock)
Hub.CreateToggle(badgeTab, "🎯 Auto-Lock Megarock to Arena Center (Anti-Push)", false, function(toggled)
    state.MegarockCenterLock = toggled
    if toggled then
        task.spawn(function()
            local success = ensureEquippedAndInArena("Diamond")
            if not success then
                state.MegarockCenterLock = false
                return
            end

            teleportToArenaCenter()
            task.wait(0.4)
            activateAbility("Rockmode")

            Hub.notify({
                Title = "Center Megarock Active",
                Content = "Megarock locked to Arena Center (Anti-Push active).",
                Duration = 5
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
            Title = "Center Megarock Stopped",
            Content = "Megarock deactivated & character unlocked.",
            Duration = 3
        })
    end
end)

-- Auto-Megarock Sky Safe Zone (10 Hours AFK with Diamond Glove)
Hub.CreateToggle(badgeTab, "🪨 Auto-Megarock (Diamond -> Arena -> Sky Safe Zone)", false, function(toggled)
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
                Title = "Auto-Megarock Active",
                Content = "Diamond rock activated in Sky Safe Zone. Keep AFK for 10 hours!",
                Duration = 6
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
            Title = "Auto-Megarock Stopped",
            Content = "Megarock deactivated & character unlocked.",
            Duration = 3
        })
    end
end)

-- Auto-Fish (1 Hour AFK with ZZZZZZZ Glove)
Hub.CreateToggle(badgeTab, "🐟 Auto-Fish (ZZZZZZZ -> Arena -> Sleep Safe Zone)", false, function(toggled)
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
                Title = "Auto-Fish Active",
                Content = "ZZZZZZZ sleep mode engaged in Safe Zone. Keep AFK for 1 hour!",
                Duration = 6
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
            Title = "Auto-Fish Stopped",
            Content = "Fish farmer deactivated & character woke up.",
            Duration = 3
        })
    end
end)

-- Auto-Trap (1,000 Bricks with Brick Glove)
Hub.CreateToggle(badgeTab, "🧱 Auto-Trap (Brick -> Arena -> Spam 1k Bricks)", false, function(toggled)
    state.AutoTrap = toggled
    if toggled then
        task.spawn(function()
            local success = ensureEquippedAndInArena("Brick")
            if not success then
                state.AutoTrap = false
                return
            end

            Hub.notify({
                Title = "Auto-Trap Active",
                Content = "Spamming bricks in Safe Zone. Target: 1,000 bricks.",
                Duration = 5
            })
        end)
    else
        Hub.notify({
            Title = "Auto-Trap Stopped",
            Content = "Placed " .. tostring(state.TrapBrickCount) .. " bricks total.",
            Duration = 4
        })
    end
end)

-- Auto-Voodoo (1 Hour Invisibility with Ghost Glove)
Hub.CreateToggle(badgeTab, "👻 Auto-Voodoo (Ghost -> Arena -> Invisibility Safe Zone)", false, function(toggled)
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
                Title = "Auto-Voodoo Active",
                Content = "Ghost invisibility active in Safe Zone. Keep AFK for 1 hour!",
                Duration = 6
            })
        end)
    else
        pcall(function()
            if ReplicatedStorage:FindFirstChild("Ghostinvisibilitydeactivated") then
                ReplicatedStorage.Ghostinvisibilitydeactivated:FireServer()
            end
        end)
        Hub.notify({
            Title = "Auto-Voodoo Stopped",
            Content = "Ghost farm deactivated.",
            Duration = 3
        })
    end
end)

-- Background Routine for AFK Glove Farming
task.spawn(function()
    while true do
        task.wait(1.5)

        -- Megarock Center Lock Enforcement (Keeps rock at exact center, counteracting Swapper/Pusher/Peshkov)
        if state.MegarockCenterLock then
            local root = getRoot()
            if root and not isInLobby() then
                local dist = (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(ARENA_CENTER_POS.X, 0, ARENA_CENTER_POS.Z)).Magnitude
                if dist > 3.5 then
                    root.CFrame = CFrame.new(ARENA_CENTER_POS + Vector3.new(0, 3, 0))
                end
                local char = getCharacter()
                if char then
                    for _, p in ipairs(char:GetDescendants()) do
                        if p:IsA("BasePart") then
                            p.Anchored = true
                        end
                    end
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
Hub.CreateSection(farmTab, "Slap & Event Farming")

Hub.CreateToggle(farmTab, "Auto Collect Candy / Orbs", false, function(toggled)
    state.AutoCandy = toggled
end)

Hub.CreateToggle(farmTab, "Auto Click Tycoon Plate", false, function(toggled)
    state.AutoTycoon = toggled
end)

Hub.CreateButton(farmTab, "🏆 Claim Daily & Free Badges", function()
    for _, desc in ipairs(ReplicatedStorage:GetDescendants()) do
        if desc:IsA("RemoteEvent") and desc.Name:lower():find("badge") then
            pcall(function() desc:FireServer() end)
        end
    end
    Hub.notify({
        Title = "Badge Collector",
        Content = "Dispatched badge reward checks.",
        Duration = 3
    })
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
-- 4. ALT CONTROL TAB (Multi-Account & Farming Helper)
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

Hub.CreateSection(altTab, "Alt Account Setup & Main Target")

local mainTargetDropdown = nil
mainTargetDropdown = Hub.CreateDropdown(altTab, "Select Main Account", getPlayerNamesList(), getPlayerNamesList()[1], function(selected)
    if selected and selected ~= "No Other Players" then
        state.MainUsername = selected
        Hub.notify({
            Title = "Target Main Set",
            Content = "Alt assigned to Master: @" .. selected,
            Duration = 3
        })
    end
end)

Hub.CreateButton(altTab, "🔄 Refresh Players in Server", function()
    local updated = getPlayerNamesList()
    if mainTargetDropdown and mainTargetDropdown.Refresh then
        mainTargetDropdown.Refresh(updated)
    end
    Hub.notify({
        Title = "Players Refreshed",
        Content = "Player list refreshed (" .. tostring(#updated) .. " found)",
        Duration = 2
    })
end)

-- Custom Username Text Input helper (Allows typing exact username of Main)
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
    lbl.Text = "Type Main User:"
    lbl.TextColor3 = Color3.fromRGB(230, 235, 245)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = inputFrame

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0.55, -14, 0, 28)
    box.Position = UDim2.new(0.45, 0, 0.5, -14)
    box.BackgroundColor3 = Color3.fromRGB(12, 15, 22)
    box.PlaceholderText = "Username here..."
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
                Title = "Main Username Set",
                Content = "Target set to: @" .. state.MainUsername,
                Duration = 3
            })
        end
    end)
end)

Hub.CreateToggle(altTab, "🤖 Mode: This is an Alt Account", false, function(toggled)
    state.IsAltAccount = toggled
    if toggled then
        Hub.notify({
            Title = "Alt Mode Enabled",
            Content = "This client is now set as an active Alt assistant.",
            Duration = 4
        })
    end
end)

Hub.CreateToggle(altTab, "💬 Listen to Main Chat Commands", true, function(toggled)
    state.AltChatCommands = toggled
end)

Hub.CreateSection(altTab, "Alt Movement & Slap Feeding")

-- Auto TP to Megarock of Main Account
local function getMegarockOfPlayer(targetPlr)
    if not targetPlr then return nil end
    local char = targetPlr.Character
    if char then
        for _, part in ipairs(char:GetChildren()) do
            local pName = part.Name:lower()
            if (pName:find("rock") or pName:find("megarock") or pName:find("diamond")) and part:IsA("BasePart") then
                return part
            end
        end
    end
    -- Also search workspace models/custom rocks
    for _, obj in ipairs(Workspace:GetChildren()) do
        local oName = obj.Name:lower()
        if (oName:find("megarock") or oName:find("customrock") or oName == "rock") and obj:IsA("BasePart") then
            local dist = (char and getRoot(targetPlr)) and (obj.Position - getRoot(targetPlr).Position).Magnitude or 999
            if dist < 30 then
                return obj
            end
        end
    end
    return nil
end

Hub.CreateToggle(altTab, "🪨 Auto TP to Main's Megarock (Arena -> Rock)", false, function(toggled)
    state.AltAutoTPMegarock = toggled
    if toggled then
        state.IsAltAccount = true
        task.spawn(function()
            if isInLobby() then
                Hub.notify({
                    Title = "Entering Arena",
                    Content = "Alt entering arena to teleport to Main's Megarock...",
                    Duration = 3
                })
                enterArena()
                task.wait(1)
            end

            local mainPlr = getMainPlayer()
            if not mainPlr then
                Hub.notify({
                    Title = "⚠️ Main Not Found",
                    Content = "Please select or type your Main account username first!",
                    Duration = 5
                })
                return
            end

            local rockPart = getMegarockOfPlayer(mainPlr)
            local root = getRoot()
            if root then
                if rockPart then
                    root.CFrame = rockPart.CFrame + Vector3.new(0, rockPart.Size.Y / 2 + 3, 0)
                elseif getRoot(mainPlr) then
                    root.CFrame = getRoot(mainPlr).CFrame + Vector3.new(0, 5, 0)
                end
                Hub.notify({
                    Title = "🪨 Teleported to Megarock!",
                    Content = "Alt is positioned on Main's Megarock.",
                    Duration = 4
                })
            end
        end)
    end
end)

Hub.CreateToggle(altTab, "🎯 Alt Follow & Lock to Main", false, function(toggled)
    state.AltFollowMain = toggled
end)

Hub.CreateSlider(altTab, "Follow Distance", 2, 12, 4, " studs", function(val)
    state.AltFollowDistance = val
end)

Hub.CreateToggle(altTab, "🥩 Auto Feed Slaps (Stand Still & Lock to Main)", false, function(toggled)
    state.AltFeedSlaps = toggled
end)

Hub.CreateToggle(altTab, "🔄 Auto Re-enter Arena on Respawn", false, function(toggled)
    state.AltAutoReenter = toggled
end)

Hub.CreateSection(altTab, "Co-op Glove & Badge Assistance")

Hub.CreateToggle(altTab, "👥 Alt Spam Bob (Replica Glove Spam)", false, function(toggled)
    state.AltSpamReplicaBob = toggled
    if toggled then
        task.spawn(function()
            if isInLobby() then
                autoEquipGlove("Replica")
                task.wait(0.5)
                enterArena()
            end
        end)
    end
end)

Hub.CreateToggle(altTab, "🧱 Alt Spam Bricks (Brick Feeder)", false, function(toggled)
    state.AltSpamBrick = toggled
    if toggled then
        task.spawn(function()
            if isInLobby() then
                autoEquipGlove("Brick")
                task.wait(0.5)
                enterArena()
            end
        end)
    end
end)

Hub.CreateToggle(altTab, "🪨 Alt Diamond Rock Mode (Cult/AFK)", false, function(toggled)
    state.AltDiamondRock = toggled
    if toggled then
        task.spawn(function()
            ensureEquippedAndInArena("Diamond")
            task.wait(0.5)
            activateAbility("Rockmode")
        end)
    else
        pcall(function()
            if ReplicatedStorage:FindFirstChild("DeactivateRockmode") then
                ReplicatedStorage.DeactivateRockmode:FireServer()
            end
        end)
    end
end)

Hub.CreateButton(altTab, "👋 Alt Slap Main (1-Tap Hit)", function()
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
            Content = "Please select your Main account from the dropdown!",
            Duration = 3
        })
    end
end)

Hub.CreateToggle(altTab, "🔁 Loop Slap Main (Every 1.5s)", false, function(toggled)
    state.AltLoopSlapMain = toggled
end)

Hub.CreateSection(altTab, "Quick Glove Equip for Alt")

local altGloves = {
    {"🥊 Default", "Default"},
    {"💎 Diamond", "Diamond"},
    {"👥 Replica (Bob)", "Replica"},
    {"🧱 Brick", "Brick"},
    {"👻 Ghost", "Ghost"},
    {"💤 ZZZZZZZ", "ZZZZZZZ"},
    {"🔄 Reverse", "Reverse"},
    {"🛡️ Extended", "Extended"},
}

for _, gData in ipairs(altGloves) do
    Hub.CreateButton(altTab, "Equip " .. gData[1], function()
        task.spawn(function()
            autoEquipGlove(gData[2])
            Hub.notify({
                Title = "Alt Glove",
                Content = "Equipped [" .. gData[2] .. "]",
                Duration = 2
            })
        end)
    end)
end

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
        elseif cmd == "!alt rock" or cmd == "!alt megarock" then
            task.spawn(function()
                ensureEquippedAndInArena("Diamond")
                task.wait(0.5)
                activateAbility("Rockmode")
            end)
        elseif cmd == "!alt unrock" then
            pcall(function()
                if ReplicatedStorage:FindFirstChild("DeactivateRockmode") then
                    ReplicatedStorage.DeactivateRockmode:FireServer()
                end
            end)
        elseif cmd == "!alt bob" then
            state.AltSpamReplicaBob = not state.AltSpamReplicaBob
        elseif cmd == "!alt brick" then
            state.AltSpamBrick = not state.AltSpamBrick
        elseif cmd == "!alt safe" then
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
        task.wait(0.08)
        if state.IsAltAccount then
            local mainPlr = getMainPlayer()
            local mainRoot = mainPlr and getRoot(mainPlr)
            local altRoot = getRoot()
            local altChar = getCharacter()

            -- Auto Re-enter Arena if in lobby
            if (state.AltAutoReenter or state.AltFeedSlaps or state.AltFollowMain or state.AltAutoTPMegarock) and isInLobby() then
                enterArena()
                task.wait(0.8)
            end

            -- Alt Auto TP & Lock to Main's Megarock
            if state.AltAutoTPMegarock and mainPlr then
                local rockPart = getMegarockOfPlayer(mainPlr)
                if altRoot then
                    if rockPart then
                        altRoot.CFrame = rockPart.CFrame + Vector3.new(0, rockPart.Size.Y / 2 + 3, 0)
                    elseif mainRoot then
                        altRoot.CFrame = mainRoot.CFrame + Vector3.new(0, 5, 0)
                    end
                end
            end

            -- Alt Follow Main / Feed Target
            if (state.AltFollowMain or state.AltFeedSlaps) and mainRoot and altRoot then
                local targetCFrame = mainRoot.CFrame * CFrame.new(0, 0, -state.AltFollowDistance) * CFrame.Angles(0, math.rad(180), 0)
                altRoot.CFrame = targetCFrame

                if altChar then
                    for _, p in ipairs(altChar:GetDescendants()) do
                        if p:IsA("BasePart") then
                            p.CanCollide = false
                        end
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

-- Alt Background Ability Spam & Loop Slap
task.spawn(function()
    while true do
        task.wait(1.5)
        if state.IsAltAccount then
            local mainPlr = getMainPlayer()

            -- Loop Slap Main (For badges requiring getting slapped)
            if state.AltLoopSlapMain and mainPlr and mainPlr.Character then
                slapPlayer(mainPlr.Character)
            end

            -- Alt Spam Bob (Replica ability spam until Bob spawns)
            if state.AltSpamReplicaBob then
                local cur = getCurrentGlove()
                if cur:lower() ~= "replica" and isInLobby() then
                    autoEquipGlove("Replica")
                    task.wait(0.5)
                    enterArena()
                end
                activateAbility("Duplicate")
            end

            -- Alt Spam Brick
            if state.AltSpamBrick then
                local cur = getCurrentGlove()
                if cur:lower() ~= "brick" and isInLobby() then
                    autoEquipGlove("Brick")
                    task.wait(0.5)
                    enterArena()
                end
                activateAbility("lbrick")
            end
        end
    end
end)

-- =========================================================================
-- 5. DEFENSE & MISC TAB
-- =========================================================================
Hub.CreateSection(defenseTab, "Anti-Ragdoll & Safety Plate")

local voidPlate = nil

Hub.CreateToggle(defenseTab, "Anti-Ragdoll", false, function(toggled)
    state.AntiRagdoll = toggled
end)

Hub.CreateToggle(defenseTab, "Anti-Void Safe Plate", false, function(toggled)
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

Hub.CreateButton(defenseTab, "🚀 Teleport to Sky Safe Zone", function()
    teleportToSafeZone()
    Hub.notify({
        Title = "Safe Zone",
        Content = "Teleported to Sky Safe Platform (Y: 3500).",
        Duration = 3
    })
end)

Hub.CreateButton(defenseTab, "🧹 Remove Sky Safe Zone", function()
    removeSafeZone()
    Hub.notify({
        Title = "Safe Zone",
        Content = "Sky Safe Platform removed.",
        Duration = 3
    })
end)

Hub.CreateSection(defenseTab, "Glove Immunities")

Hub.CreateToggle(defenseTab, "Anti-Megarock", false, function(toggled)
    state.AntiMegarock = toggled
end)

Hub.CreateToggle(defenseTab, "Anti-Timestop", false, function(toggled)
    state.AntiTimestop = toggled
end)

RunService.Stepped:Connect(function()
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
end)

-- =========================================================================
-- 5. VISUALS & ESP TAB
-- =========================================================================
Hub.CreateSection(visualTab, "Player & Glove ESP")

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
    Title = "Slap Battles Loaded",
    Content = "Unknown Hub Slap Battles (Badge Master) is active!",
    Duration = 4
})

