--[[
    ========================================================================
    UNKNOWN HUB - YOUR BIZARRE ADVENTURE (YBA)
    ========================================================================
    Game: Your Bizarre Adventure (YBA)
    Place IDs: 2809202155 (Main), 4643697430 (SBR), 5290796989, 5290908008, 5818059480, 5818061503, 12807820316, 12807832128
    Universe ID: 1016936714
    Features:
      - ⚔️ Combat: Mob Aura, Fast Attack, Auto Heavy, Auto Barrage, Anti-Ragdoll & Stand Defense
      - 📜 Quests & Farm: Auto Quest Claim & Mob Farmer, Safe Overhead Attack, Auto Skill Tree
      - 💎 Items & Farm: Auto Item Collector (Arrows, Rokas, Rib Cages, Lucky Arrows), Item ESP & Radar
      - 🐎 Steel Ball Run: Horse Speed Boost, Anti-Sandstorm, Stage Checkpoints & Finish Line Teleports
      - 🎰 Stand Roller: Auto Arrow + Rokakaka Stand Rolling Bot, Target Stand Whitelist & Stop on Shiny
      - 📍 Teleports: Merchant, Arcade, Train Station, Colosseum, Jesus, Fangio, Bosses & Story NPCs
      - 👁️ Visuals / ESP: Item ESP with distance & rarity colors, Player ESP, Boss ESP
      - 👤 Player & Misc: Infinite Stamina, Speed/Jump modifiers, Noclip, Fly, Server Hop & Rejoin
    ========================================================================
]]

local LIBRARY_LINK = "https://raw.githubusercontent.com/UnknownHQ/UnknownHub/main/UnknownLibrary"
local LIBRARY_NAME = "Unknown_TabbedHub_UI"

local currentSession = tick()
_G.YBA_SESSION = currentSession

-- =========================================================================
-- Core Roblox Services
-- =========================================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- =========================================================================
-- Anti-AFK Safeguard
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
-- Universal UI Cleanup Handler
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
                    if child:IsA("ScreenGui") and (child.Name == LIBRARY_NAME or child.Name:find("Unknown_TabbedHub_UI")) then
                        pcall(function() child:Destroy() end)
                    end
                end
            end)
        end
    end
end

-- =========================================================================
-- Load Unknown Hub Library Factory
-- =========================================================================
local ok, factoryResult = pcall(function()
    local source
    local cacheBuster = "?t=" .. tostring(os.time() or tick()) .. "_" .. tostring(math.random(1000, 9999))
    source = game:HttpGet(LIBRARY_LINK .. cacheBuster)
    local factoryChunk, compileErr = loadstring(source)
    assert(factoryChunk, "UnknownLibrary failed to compile: " .. tostring(compileErr))
    return factoryChunk()
end)

assert(ok and type(factoryResult) == "function", "UnknownLibrary failed to load: " .. tostring(factoryResult))

destroyOldGui()

local Hub = factoryResult({
    name = LIBRARY_NAME,
    title = "UNKNOWN HUB",
    subTitle = "Your Bizarre Adventure",
    parent = (gethui and gethui()) or (LocalPlayer and (LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui"))) or (pcall(function() return game:GetService("CoreGui") end) and game:GetService("CoreGui")),
    theme = Color3.fromRGB(155, 89, 182),          -- JoJo Purple
    secondaryTheme = Color3.fromRGB(241, 196, 15)   -- Golden Experience Yellow
})

assert(type(Hub) == "table", "UnknownLibrary returned an invalid hub instance")

-- =========================================================================
-- Data Catalogs & Dictionaries
-- =========================================================================
local ybaItemsCatalog = {
    "All Items",
    "Lucky Arrow",
    "Lucky Stone Mask",
    "Pure Rokakaka",
    "Rokakaka",
    "Mysterious Arrow",
    "Requiem Arrow",
    "Rib Cage of the Saint's Corpse",
    "DIO's Diary",
    "Steel Ball",
    "Quinton's Glove",
    "Ancient Scroll",
    "Stone Mask",
    "Gold Coin",
    "Diamond",
    "Caesar's Headband",
    "Zeppeli's Hat",
    "Clackers",
    "Yellow Candy",
    "Red Candy",
    "Green Candy",
    "Blue Candy"
}

local ybaStandsCatalog = {
    "Star Platinum",
    "Star Platinum: The World",
    "The World",
    "The World Over Heaven",
    "King Crimson",
    "King Crimson Requiem",
    "Killer Queen",
    "Killer Queen: Bites the Dust",
    "Gold Experience",
    "Gold Experience Requiem",
    "Silver Chariot",
    "Silver Chariot Requiem",
    "Crazy Diamond",
    "Whitesnake",
    "C-Moon",
    "Made in Heaven",
    "D4C",
    "D4C: Love Train",
    "Tusk Act 1",
    "Tusk Act 2",
    "Tusk Act 3",
    "Tusk Act 4",
    "Scary Monsters",
    "The Hand",
    "Sticky Fingers",
    "Purple Haze",
    "Hierophant Green",
    "Magician's Red",
    "Hermit Purple",
    "Anubis",
    "Red Hot Chili Pepper",
    "Soft & Wet"
}

local ybaNPCsCatalog = {
    "Thug [Lvl. 1+]",
    "Security Guard [Lvl. 1+]",
    "Corrupt Police [Lvl. 5+]",
    "Alpha Thug [Lvl. 5+]",
    "Zombie Henchman [Lvl. 10+]",
    "Vampire [Lvl. 15+]",
    "Leaky Eye Luca [Lvl. 20+ Boss]",
    "Bucciarati [Lvl. 20+ Boss]",
    "Fugo [Lvl. 25+ Boss]",
    "Pesci [Lvl. 30+ Boss]",
    "Ghiaccio [Lvl. 35+ Boss]",
    "Diavolo [Lvl. 40+ Boss]",
    "DIO [Lvl. 45+ Boss]",
    "Jotaro [Lvl. 50+ Boss]",
    "Anasui [Lvl. 50+ Boss]",
    "Yoshikage Kira [Boss]",
    "Jotaro Kujo [Heaven Boss]",
    "Heaven Ascension DIO [Heaven Boss]"
}

local function detectAvailableAbilities()
    local abilities = {
        "Punch / M1",
        "Heavy Punch (M2)"
    }
    local seen = {
        ["Punch / M1"] = true,
        ["Heavy Punch (M2)"] = true
    }

    -- Common default Stand keybinds
    local defaultKeybinds = {
        "Stand Barrage (E)",
        "Barrage Finisher (R)",
        "Heavy Strike (T)",
        "Special Ability (Y)",
        "Movement Ability (Z)",
        "Ultimate Ability (X)",
        "Stand Ability (C)",
        "Fighting Style (V)",
        "Fighting Style (B)",
        "Fighting Style (G)"
    }
    for _, k in ipairs(defaultKeybinds) do
        if not seen[k] then
            seen[k] = true
            table.insert(abilities, k)
        end
    end

    -- Dynamic scan from HUD for player's specific skills and fighting style keybinds
    pcall(function()
        local pGui = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
        local hud = pGui and (pGui:FindFirstChild("HUD") or pGui:FindFirstChild("MainGui") or pGui:FindFirstChild("Skills"))
        if hud then
            for _, desc in ipairs(hud:GetDescendants()) do
                if desc:IsA("TextLabel") and desc.Text ~= "" then
                    local parent = desc.Parent
                    local text = desc.Text:gsub("^%s*(.-)%s*$", "%1")
                    if desc.Name == "SkillName" or desc.Name == "Key" or (parent and (parent.Name:find("Skill") or parent.Name:find("Slot"))) then
                        -- Check if text looks like a skill or keybind
                        if #text >= 1 and #text <= 30 and not text:find("\n") then
                            local formatted = text
                            if desc.Name == "Key" and #text <= 3 then
                                formatted = "Skill Key (" .. text:upper() .. ")"
                            end
                            if not seen[formatted] then
                                seen[formatted] = true
                                table.insert(abilities, formatted)
                            end
                        end
                    end
                end
            end
        end
    end)
    return abilities
end

local ybaLocations = {
    ["Merchant (ShiftPlox)"] = Vector3.new(-709, -25, -332),
    ["Arcade"] = Vector3.new(233, 1, -269),
    ["Train Station"] = Vector3.new(-352, 4, 75),
    ["Item Machine"] = Vector3.new(277, 6, -241),
    ["Suno the Arrowsmith"] = Vector3.new(-667, 17, -299),
    ["Cafe"] = Vector3.new(-530, -21, -192),
    ["Pizzeria"] = Vector3.new(216, 1, 45),
    ["Parking Garage"] = Vector3.new(-102, 9, -718),
    ["Sewers Entrance"] = Vector3.new(-164, -18, -497),
    ["Prison"] = Vector3.new(1003, 46, -219),
    ["Prestige Master Rin"] = Vector3.new(-454, 1, 27),
    ["Quinton (Boxing)"] = Vector3.new(281, 1, 105),
    ["William Zeppeli (Hamon)"] = Vector3.new(-139, -30, 36),
    ["Lisa Lisa (Hamon Master)"] = Vector3.new(426, 8, -283),
    ["Elder Vampire Roomy"] = Vector3.new(388, -27, -143),
    ["Fang the Negotiator"] = Vector3.new(512, 3, -34),
    ["Jotaro (Tallest Peak)"] = Vector3.new(-241, 274, 296),
    ["Jotaro (Heaven)"] = Vector3.new(8553, -479, 8154),
    ["DIO [Lvl. 35+ Quest]"] = Vector3.new(314, -25, 484),
    ["Darius, The Executioner"] = Vector3.new(249, 47, -593),
    ["Doppio [Lvl. 30+]"] = Vector3.new(-40, 1, -990),
    ["Halloween Area"] = Vector3.new(-260, 21, -1102)
}

-- =========================================================================
-- State Configuration
-- =========================================================================
local State = {
    -- Combat & NPC Auto Farm
    AutoFarmNPC = false,
    SelectedNPC = "Thug",
    SafeFarmDistance = 7,
    AutoFarmBosses = false,
    SelectedBosses = {},
    WhitelistAbilities = {
        ["Punch / M1"] = true,
        ["Heavy Punch (M2)"] = true,
        ["Stand Barrage (E)"] = true,
        ["Barrage Finisher (R)"] = true
    },

    -- Auto Quest & Farm
    AutoFarmQuests = false,
    SelectedQuest = "Thugs (Level 1+)",
    AutoClaimQuest = true,
    AutoSkillPoints = false,

    -- Items & Farm
    AutoCollectItems = false,
    CollectItemDelay = 0.5,
    PrioritizeRareItems = true,
    ItemWhitelist = { ["All Items"] = true },

    -- SBR
    SBR_SpeedBoost = false,
    SBR_HorseSpeed = 45,
    SBR_AntiSandstorm = false,
    SBR_AutoFinish = false,

    -- Stand Roller
    AutoStandRoll = false,
    TargetStands = {},
    StopOnShiny = true,
    AutoArcade = false,

    -- Player & Movement
    WalkSpeed = 16,
    JumpPower = 50,
    InfiniteStamina = false,
    Noclip = false,
    FlyEnabled = false,
    FlySpeed = 50,

    -- Visuals / ESP
    ItemESP = false,
    PlayerESP = false,
    NPCESP = false,

    -- Teleport & Anti-Kick Safety
    SafeTeleportMode = true,
    SafeTravelSpeed = 600,
    AutoTravelToTarget = false,
    SelectedTravelTarget = nil,
    TravelTargetType = "Location"
}

-- =========================================================================
-- Helper Functions
-- =========================================================================
local function getCharacter()
    return LocalPlayer and LocalPlayer.Character
end

local function getRoot()
    local char = getCharacter()
    return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso"))
end

local function getHumanoid()
    local char = getCharacter()
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function getPlayerStand()
    local char = getCharacter()
    if not char then return nil end
    for _, child in ipairs(char:GetChildren()) do
        if child:IsA("Model") and (child:FindFirstChild("StandMorph") or child:FindFirstChild("StandRoot") or (child.Name ~= char.Name and child:FindFirstChild("Head") and child:FindFirstChild("HumanoidRootPart"))) then
            return child
        end
    end
    return nil
end

local function hasStand()
    -- Check if player owns a stand in stats or character
    if getPlayerStand() then return true end
    local pStats = LocalPlayer and (LocalPlayer:FindFirstChild("PlayerStats") or LocalPlayer:FindFirstChild("Stats"))
    if pStats then
        local standVal = pStats:FindFirstChild("Stand")
        if standVal and standVal:IsA("StringValue") and standVal.Value ~= "" and standVal.Value ~= "None" and standVal.Value ~= "Standless" then
            return true, standVal.Value
        end
    end
    local char = getCharacter()
    if char then
        local standVal = char:FindFirstChild("Stand")
        if standVal and standVal:IsA("StringValue") and standVal.Value ~= "" and standVal.Value ~= "None" and standVal.Value ~= "Standless" then
            return true, standVal.Value
        end
    end
    return false, nil
end

local function getPlayerStyle()
    local pStats = LocalPlayer and (LocalPlayer:FindFirstChild("PlayerStats") or LocalPlayer:FindFirstChild("Stats"))
    if pStats then
        local styleVal = pStats:FindFirstChild("Spec") or pStats:FindFirstChild("Style") or pStats:FindFirstChild("FightingStyle")
        if styleVal and styleVal:IsA("StringValue") and styleVal.Value ~= "" and styleVal.Value ~= "None" then
            return styleVal.Value
        end
    end
    local char = getCharacter()
    if char then
        local styleVal = char:FindFirstChild("Spec") or char:FindFirstChild("Style") or char:FindFirstChild("FightingStyle")
        if styleVal and styleVal:IsA("StringValue") and styleVal.Value ~= "" and styleVal.Value ~= "None" then
            return styleVal.Value
        end
    end
    return nil
end

local function getRemoteEvent()
    local char = getCharacter()
    if char and char:FindFirstChild("RemoteEvent") then
        return char.RemoteEvent
    end
    local rep = ReplicatedStorage:FindFirstChild("ItemSpawn") or ReplicatedStorage
    return rep:FindFirstChild("RemoteEvent")
end

local function getRemoteFunction()
    local char = getCharacter()
    if char and char:FindFirstChild("RemoteFunction") then
        return char.RemoteFunction
    end
    return ReplicatedStorage:FindFirstChild("RemoteFunction")
end

local function getLivingFolder()
    return Workspace:FindFirstChild("Living") or Workspace:FindFirstChild("NPCs") or Workspace
end

local function getSpawnedItems()
    local items = {}
    local seen = {}

    -- 1. Primary method: Read exact spawned items and coordinates from ReplicatedFirst.ItemSpawn closures
    pcall(function()
        local itemSpawnScript = game:GetService("ReplicatedFirst"):FindFirstChild("ItemSpawn")
        if itemSpawnScript then
            for _, fn in ipairs(getgc()) do
                if type(fn) == "function" and islclosure(fn) and rawget(getfenv(fn), "script") == itemSpawnScript then
                    local info = debug.getinfo(fn)
                    if info.linedefined == 82 then
                        local ups = getupvalues(fn)
                        local cd = ups[4]
                        local cf = ups[5]
                        if typeof(cd) == "Instance" and cd.Parent and typeof(cf) == "CFrame" then
                            local itemName = (cd.ObjectText ~= "" and cd.ObjectText) or cd.Name
                            if not seen[cd] then
                                seen[cd] = true
                                table.insert(items, {
                                    name = itemName,
                                    prompt = cd,
                                    part = cd:FindFirstAncestorWhichIsA("BasePart"),
                                    cf = cf,
                                    pos = cf.Position
                                })
                            end
                        end
                    end
                end
            end
        end
    end)

    -- 2. Secondary fallback: ProximityPrompts under Workspace or Item_Spawns
    if #items == 0 then
        for _, obj in ipairs(Workspace:GetChildren()) do
            if obj:IsA("ProximityPrompt") and obj.ActionText == "Pick Up" and not seen[obj] then
                seen[obj] = true
                local name = (obj.ObjectText ~= "" and obj.ObjectText) or obj.Name
                table.insert(items, {
                    name = name,
                    prompt = obj,
                    part = nil,
                    pos = Vector3.zero
                })
            end
        end
    end

    return items
end

-- =========================================================================
-- Anti-Kick Teleport & Travel Engine
-- =========================================================================
local currentTravelNoclip = nil
local currentTravelBV = nil
local isTraveling = false
local cancelTravelFlag = false

local function cancelCurrentTravel()
    cancelTravelFlag = true
    if currentTravelNoclip then
        pcall(function() currentTravelNoclip:Disconnect() end)
        currentTravelNoclip = nil
    end
    if currentTravelBV then
        pcall(function() currentTravelBV:Destroy() end)
        currentTravelBV = nil
    end
    local root = getRoot()
    if root then
        pcall(function()
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end)
    end
    isTraveling = false
end

local function safeTeleportTo(targetCF, callback)
    local root = getRoot()
    local char = getCharacter()
    local hum = getHumanoid()
    if not root or not char then return end

    if typeof(targetCF) == "Vector3" then
        targetCF = CFrame.new(targetCF)
    end

    local dist = (root.Position - targetCF.Position).Magnitude

    -- Cancel any active travel before starting new one
    cancelCurrentTravel()

    -- 1. If very close (< 6 studs) or safe mode disabled, direct micro-teleport is completely safe
    if dist <= 6 or not State.SafeTeleportMode then
        root.CFrame = targetCF
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        if callback then callback() end
        return
    end

    -- 2. Anti-Rubberband High-Velocity Heartbeat Micro-Stepper with Adaptive Physics S-Curve
    -- Starts at safe cruise speed (120 studs/s), ramps up smoothly to 500-600 studs/s,
    -- and smoothly decelerates into the target so server physics buffers never spike.
    isTraveling = true
    cancelTravelFlag = false

    local maxConfigSpeed = math.clamp(tonumber(State.SafeTravelSpeed) or 500, 40, 600)
    local minStartSpeed = 120
    local accelRate = 450 -- studs/s^2 smooth ramping

    -- Anchor-free zero-gravity float
    local bv = Instance.new("BodyVelocity")
    bv.Name = "Unknown_SafeTravel_BV"
    bv.MaxForce = Vector3.new(1e6, 1e6, 1e6)
    bv.Velocity = Vector3.zero
    bv.Parent = root
    currentTravelBV = bv

    -- Full collision bypass so character doesn't bump into geometry (which causes server rollback)
    local noclipConn = RunService.Stepped:Connect(function()
        if char and char.Parent then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then
                    p.CanCollide = false
                end
            end
        end
    end)
    currentTravelNoclip = noclipConn

    task.spawn(function()
        local currentSpeed = minStartSpeed

        while isTraveling and not cancelTravelFlag do
            local currentRoot = getRoot()
            if not currentRoot then break end

            local toTarget = targetCF.Position - currentRoot.Position
            local remDist = toTarget.Magnitude
            if remDist <= 2.5 then
                currentRoot.CFrame = targetCF
                break
            end

            -- Delta time between frames
            local dt = RunService.Heartbeat:Wait()
            if cancelTravelFlag or not isTraveling then break end

            -- Adaptive Speed Profile:
            -- Smoothly accelerates from 120 studs/s up to maxConfigSpeed (500-600 studs/s)
            -- Gently decelerates within the last 50 studs for a soft, undetectable stop
            if remDist < 50 then
                currentSpeed = math.max(minStartSpeed, maxConfigSpeed * (remDist / 50))
            else
                currentSpeed = math.min(maxConfigSpeed, currentSpeed + (accelRate * dt))
            end

            -- Step size calculated per frame
            local maxStep = math.clamp(currentSpeed * dt, 1.0, 18.0)
            local stepDist = math.min(remDist, maxStep)
            local dir = toTarget.Unit

            -- Update position smoothly per Heartbeat
            currentRoot.CFrame = CFrame.new(currentRoot.Position + (dir * stepDist), currentRoot.Position + (dir * stepDist) + dir)

            -- Keep AssemblyLinearVelocity aligned to prevent server detecting stationary desync
            currentRoot.AssemblyLinearVelocity = dir * (stepDist / math.max(dt, 0.001))
            currentRoot.AssemblyAngularVelocity = Vector3.zero
        end

        -- Finish travel and settle character
        local endRoot = getRoot()
        if endRoot and not cancelTravelFlag then
            endRoot.CFrame = targetCF
            endRoot.AssemblyLinearVelocity = Vector3.zero
            endRoot.AssemblyAngularVelocity = Vector3.zero
        end

        if currentTravelNoclip == noclipConn then
            noclipConn:Disconnect()
            currentTravelNoclip = nil
        end
        if currentTravelBV == bv then
            bv:Destroy()
            currentTravelBV = nil
        end
        isTraveling = false

        if not cancelTravelFlag and callback then
            callback()
        end
    end)
end

local function executeAutoCollectItems()
    local root = getRoot()
    if not root then return end

    local items = getSpawnedItems()
    local isAllSelected = State.ItemWhitelist["All Items"] == true
    local candidateItems = {}

    for _, item in ipairs(items) do
        local shouldCollect = isAllSelected or State.ItemWhitelist[item.name] == true
        if not shouldCollect then
            for key, _ in pairs(State.ItemWhitelist) do
                if item.name:lower():find(key:lower(), 1, true) then
                    shouldCollect = true
                    break
                end
            end
        end
        if shouldCollect and item.prompt and item.prompt.Parent then
            table.insert(candidateItems, item)
        end
    end

    local function isRareItem(name)
        local n = name:lower()
        return n:find("lucky", 1, true) or n:find("requiem", 1, true) or n:find("pure", 1, true) or n:find("rib", 1, true) or n:find("diary", 1, true)
    end

    -- Sort candidates: Prioritize rare items first if enabled, then sort by distance
    table.sort(candidateItems, function(a, b)
        local currRoot = getRoot()
        local pos = currRoot and currRoot.Position or Vector3.zero
        if State.PrioritizeRareItems then
            local aRare = isRareItem(a.name)
            local bRare = isRareItem(b.name)
            if aRare and not bRare then return true end
            if bRare and not aRare then return false end
        end
        return (pos - a.pos).Magnitude < (pos - b.pos).Magnitude
    end)

    for _, item in ipairs(candidateItems) do
        if not State.AutoCollectItems then break end
        if _G.YBA_SESSION ~= currentSession then break end
        local currRoot = getRoot()
        if currRoot and item.prompt and item.prompt.Parent then
            if isRareItem(item.name) then
                Hub.Notify("⭐ RARE ITEM DETECTED!", "Sniping " .. item.name .. "...", 3)
            end

            local targetCF = (item.cf and item.cf + Vector3.new(0, 1.0, 0)) or (item.pos and CFrame.new(item.pos + Vector3.new(0, 1.0, 0))) or item.prompt.Parent.CFrame
            local dist = (currRoot.Position - targetCF.Position).Magnitude

            local arrived = false
            if dist > 6 and State.SafeTeleportMode then
                safeTeleportTo(targetCF, function() arrived = true end)
                local waitTimeout = (dist / 120) + 3.0
                local startT = tick()
                while not arrived and (tick() - startT < waitTimeout) do
                    -- Immediate abort if item was picked up by someone else
                    if not item.prompt or not item.prompt.Parent then
                        cancelCurrentTravel()
                        break
                    end
                    if not State.AutoCollectItems or _G.YBA_SESSION ~= currentSession then
                        cancelCurrentTravel()
                        break
                    end
                    task.wait(0.04)
                end
            else
                currRoot.CFrame = targetCF
                arrived = true
            end

            -- Ensure we arrived and item is still present
            if not item.prompt or not item.prompt.Parent then
                cancelCurrentTravel()
            else
                -- Physics stabilization pause so server syncs client position
                task.wait(0.15)

                currRoot = getRoot()
                if currRoot and item.prompt and item.prompt.Parent then
                    pcall(function()
                        local currentDist = (currRoot.Position - targetCF.Position).Magnitude
                        if currentDist <= 14 then
                            -- Poll briefly (up to 0.4s) for ItemSpawn to clone the live replica prompt
                            local realPrompt = nil
                            local pollStart = tick()
                            while (tick() - pollStart < 0.4) do
                                if not State.AutoCollectItems or _G.YBA_SESSION ~= currentSession then break end
                                local itemSpawns = Workspace:FindFirstChild("Item_Spawns")
                                local itemsFolder = itemSpawns and itemSpawns:FindFirstChild("Items")
                                if itemsFolder then
                                    for _, itm in ipairs(itemsFolder:GetChildren()) do
                                        local p = itm:FindFirstChildOfClass("ProximityPrompt")
                                        if p and p.Enabled and p.MaxActivationDistance > 0 then
                                            local part = itm:IsA("BasePart") and itm or itm:FindFirstChildWhichIsA("BasePart")
                                            if part and (part.Position - targetCF.Position).Magnitude <= 12 then
                                                realPrompt = p
                                                break
                                            end
                                        end
                                    end
                                end
                                if realPrompt then break end
                                task.wait(0.05)
                            end

                            -- Fallback to item.prompt ONLY if it is an active enabled prompt with distance
                            if not realPrompt and item.prompt and item.prompt.Parent and item.prompt.Enabled and item.prompt.MaxActivationDistance > 0 then
                                realPrompt = item.prompt
                            end

                            -- Trigger prompt cleanly via fireproximityprompt only if valid
                            if realPrompt and realPrompt.Parent and fireproximityprompt then
                                fireproximityprompt(realPrompt, 0)
                            end
                        end
                    end)
                end
            end

            -- Safe pause between consecutive item travels to allow server item-spawner to register pickup
            task.wait(math.clamp(tonumber(State.CollectItemDelay) or 0.8, 0.4, 3.0))
        end
    end
end

-- =========================================================================
-- Background Worker Loops
-- =========================================================================
-- 1. Intelligent NPC & Boss Auto Farm Worker Loop
task.spawn(function()
    local lastM1 = 0
    local lastM2 = 0
    local abilityTimers = {}

    local function getTargetNPC()
        local living = getLivingFolder()
        local char = getCharacter()
        local myRoot = getRoot()
        if not living or not char or not myRoot then return nil end

        local bossNames = {
            ["Leaky Eye Luca"] = true,
            ["Bucciarati"] = true,
            ["Fugo"] = true,
            ["Pesci"] = true,
            ["Ghiaccio"] = true,
            ["Diavolo"] = true,
            ["DIO"] = true,
            ["Jotaro"] = true,
            ["Anasui"] = true,
            ["Yoshikage Kira"] = true,
            ["Jotaro Kujo"] = true,
            ["Heaven Ascension DIO"] = true
        }

        -- Priority 1: If AutoFarmBosses is on, hunt selected bosses first
        if State.AutoFarmBosses and State.SelectedBosses then
            for _, entity in ipairs(living:GetChildren()) do
                if entity ~= char and entity:IsA("Model") and not Players:GetPlayerFromCharacter(entity) then
                    local eHum = entity:FindFirstChildOfClass("Humanoid")
                    local eRoot = entity:FindFirstChild("HumanoidRootPart") or entity:FindFirstChild("Torso")
                    if eHum and eHum.Health > 0 and eRoot then
                        for bossName, enabled in pairs(State.SelectedBosses) do
                            if enabled and entity.Name:lower():find(bossName:lower(), 1, true) then
                                return entity, eRoot, eHum, true
                            end
                        end
                    end
                end
            end
        end

        -- Priority 2: Standard selected NPC farm
        local targetName = State.SelectedNPC or "Thug"
        local cleanTarget = targetName:gsub("%s*%[.*%]", ""):gsub("^%s*(.-)%s*$", "%1")

        local closestEntity = nil
        local closestDist = math.huge
        local closestRoot = nil
        local closestHum = nil

        for _, entity in ipairs(living:GetChildren()) do
            if entity ~= char and entity:IsA("Model") and not Players:GetPlayerFromCharacter(entity) then
                local eHum = entity:FindFirstChildOfClass("Humanoid")
                local eRoot = entity:FindFirstChild("HumanoidRootPart") or entity:FindFirstChild("Torso")
                if eHum and eHum.Health > 0 and eRoot then
                    if entity.Name:lower():find(cleanTarget:lower(), 1, true) then
                        local dist = (myRoot.Position - eRoot.Position).Magnitude
                        if dist < closestDist then
                            closestDist = dist
                            closestEntity = entity
                            closestRoot = eRoot
                            closestHum = eHum
                        end
                    end
                end
            end
        end

        return closestEntity, closestRoot, closestHum, false
    end

    while true do
        if _G.YBA_SESSION ~= currentSession then break end
        if State.AutoFarmNPC then
            local targetEntity, eRoot, eHum, isBoss = getTargetNPC()
            local root = getRoot()
            local char = getCharacter()
            local hum = getHumanoid()

            if targetEntity and eRoot and eHum and eHum.Health > 0 and root and char and hum and hum.Health > 0 then
                -- Pin directly behind NPC at exact target ground level
                -- Offset slightly back (3 studs), 0 vertical lift, facing the target
                local rearOffset = -(eRoot.CFrame.LookVector * 3.0)
                local safeCF = CFrame.new(eRoot.Position + rearOffset, eRoot.Position)

                local distToSafe = (root.Position - safeCF.Position).Magnitude
                if distToSafe > 25 and not isTraveling then
                    safeTeleportTo(safeCF)
                elseif not isTraveling then
                    -- Immediate ground lock
                    root.CFrame = safeCF
                    root.AssemblyLinearVelocity = Vector3.zero
                    root.AssemblyAngularVelocity = Vector3.zero

                    -- Cancel any stray travel body velocity if present
                    if currentTravelBV then
                        pcall(function() currentTravelBV:Destroy() end)
                        currentTravelBV = nil
                    end

                    -- Force Running humanoid state so game registers M1/M2/E/R hits
                    pcall(function()
                        hum:ChangeState(Enum.HumanoidStateType.Running)
                    end)
                end

                -- Ensure Stand is summoned if player has one
                local rem = getRemoteEvent()
                if rem then
                    local playerHasStand = hasStand()
                    local stand = getPlayerStand()
                    -- If player actually owns a stand but it's not manifested, summon it (Q)
                    if playerHasStand and not stand then
                        pcall(function()
                            rem:FireServer("InputBegan", { ["Input"] = Enum.KeyCode.Q })
                        end)
                    end

                    -- Dynamic Ability Key Map & Timers Table
                    local abilityCooldowns = {
                        ["Stand Barrage (E)"] = { key = Enum.KeyCode.E, cd = 6.0, standOnly = true },
                        ["Barrage Finisher (R)"] = { key = Enum.KeyCode.R, cd = 7.0, standOnly = true },
                        ["Heavy Strike (T)"] = { key = Enum.KeyCode.T, cd = 8.0, standOnly = true },
                        ["Special Ability (Y)"] = { key = Enum.KeyCode.Y, cd = 9.0, standOnly = false },
                        ["Movement Ability (Z)"] = { key = Enum.KeyCode.Z, cd = 12.0, standOnly = false },
                        ["Ultimate Ability (X)"] = { key = Enum.KeyCode.X, cd = 15.0, standOnly = false },
                        ["Stand Ability (C)"] = { key = Enum.KeyCode.C, cd = 8.0, standOnly = true },
                        ["Fighting Style (V)"] = { key = Enum.KeyCode.V, cd = 5.0, standOnly = false },
                        ["Fighting Style (B)"] = { key = Enum.KeyCode.B, cd = 7.0, standOnly = false },
                        ["Fighting Style (G)"] = { key = Enum.KeyCode.G, cd = 10.0, standOnly = false }
                    }

                    local now = tick()
                    local didSpecial = false

                    -- 1. Check user-whitelisted abilities & fighting style specials
                    for abName, abInfo in pairs(abilityCooldowns) do
                        if State.WhitelistAbilities[abName] then
                            -- Only use stand-locked moves if player has an active Stand
                            if not abInfo.standOnly or (playerHasStand and stand) then
                                local lastUsed = abilityTimers[abName] or 0
                                if (now - lastUsed >= abInfo.cd) then
                                    pcall(function()
                                        rem:FireServer("InputBegan", { ["Input"] = abInfo.key })
                                    end)
                                    abilityTimers[abName] = now
                                    didSpecial = true
                                    break
                                end
                            end
                        end
                    end

                    -- 2. Heavy Punch (M2) — available to both Stand and Standless (fighting style/boxing)
                    if not didSpecial and State.WhitelistAbilities["Heavy Punch (M2)"] and (now - lastM2 >= 2.5) then
                        pcall(function()
                            rem:FireServer("InputBegan", { ["Input"] = Enum.UserInputType.MouseButton2 })
                            rem:FireServer("Attack", "M2")
                        end)
                        lastM2 = now
                        didSpecial = true
                    end

                    -- 3. Standard Light Attack (M1 / Classic Punch / Standless Fist)
                    -- Falls back directly to classic punches if Standless or abilities on cooldown
                    if not didSpecial or State.WhitelistAbilities["Punch / M1"] then
                        if (now - lastM1 >= 0.28) then
                            pcall(function()
                                rem:FireServer("InputBegan", { ["Input"] = Enum.UserInputType.MouseButton1 })
                                rem:FireServer("Punch", "Light")
                                rem:FireServer("Attack", "M1")
                            end)
                            lastM1 = now
                        end
                    end
                end

                task.wait(0.08)
            else
                task.wait(0.5)
            end
        else
            task.wait(0.5)
        end
    end
end)

-- 2. Item Farm Loop
task.spawn(function()
    while true do
        if _G.YBA_SESSION ~= currentSession then break end
        if State.AutoCollectItems then
            pcall(executeAutoCollectItems)
            task.wait(1.0)
        else
            task.wait(0.5)
        end
    end
end)

-- 3. Stamina & Character Modifiers Loop
task.spawn(function()
    while true do
        if _G.YBA_SESSION ~= currentSession then break end
        pcall(function()
            local char = getCharacter()
            local hum = getHumanoid()
            if hum and State.WalkSpeed and State.WalkSpeed > 16 then
                hum.WalkSpeed = State.WalkSpeed
            end
            if hum and State.JumpPower and State.JumpPower > 50 then
                hum.JumpPower = State.JumpPower
            end
            if State.InfiniteStamina and char then
                local staminaVal = char:FindFirstChild("Stamina") or (LocalPlayer:FindFirstChild("PlayerStats") and LocalPlayer.PlayerStats:FindFirstChild("Stamina"))
                if staminaVal and staminaVal:IsA("ValueBase") then
                    staminaVal.Value = 100
                end
            end
        end)
        task.wait(0.5)
    end
end)

-- =========================================================================
-- UI Tabs & Control Layout
-- =========================================================================
local combatTab = Hub.CreateTab("Combat", { Icon = "⚔️", Size = 18, Color = Color3.fromRGB(170, 185, 210), ActiveColor = Color3.fromRGB(255, 75, 75) })
local questTab  = Hub.CreateTab("Quests", { Icon = "📜", Size = 18, Color = Color3.fromRGB(170, 185, 210), ActiveColor = Color3.fromRGB(255, 200, 50) })
local itemsTab  = Hub.CreateTab("Items", { Icon = "💎", Size = 18, Color = Color3.fromRGB(170, 185, 210), ActiveColor = Color3.fromRGB(0, 215, 255) })
local sbrTab    = Hub.CreateTab("SBR", { Icon = "🐎", Size = 18, Color = Color3.fromRGB(170, 185, 210), ActiveColor = Color3.fromRGB(255, 140, 50) })
local standsTab = Hub.CreateTab("Stands", { Icon = "🎰", Size = 18, Color = Color3.fromRGB(170, 185, 210), ActiveColor = Color3.fromRGB(180, 100, 255) })
local tpTab     = Hub.CreateTab("Teleports", { Icon = "📍", Size = 18, Color = Color3.fromRGB(170, 185, 210), ActiveColor = Color3.fromRGB(50, 220, 140) })
local espTab    = Hub.CreateTab("Visuals", { Icon = "👁️", Size = 18, Color = Color3.fromRGB(170, 185, 210), ActiveColor = Color3.fromRGB(155, 89, 182) })
local playerTab = Hub.CreateTab("Player", { Icon = "👤", Size = 18, Color = Color3.fromRGB(170, 185, 210), ActiveColor = Color3.fromRGB(241, 196, 15) })

-- -------------------------------------------------------------------------
-- 1. ⚔️ Combat & Auto Farm Tab
-- -------------------------------------------------------------------------
Hub.CreateSection(combatTab, "⚔️ NPC Auto Farm")

Hub.CreateToggle(combatTab, "⚔️ Auto Farm Selected NPC", false, function(v)
    State.AutoFarmNPC = v
    if v then
        Hub.Notify("⚔️ Auto Farm", "Auto Farm started! Gliding safely behind targets overhead.", 3)
    end
end)

Hub.CreateDropdown(combatTab, "Target NPC", ybaNPCsCatalog, 1, function(selected)
    State.SelectedNPC = selected
end)

Hub.CreateSlider(combatTab, "Safe Overhead Farm Height", 4, 20, 7, " studs", function(val)
    State.SafeFarmDistance = val
end)

Hub.CreateSection(combatTab, "👹 Boss Prioritizer / Auto Farm Bosses")

Hub.CreateToggle(combatTab, "👹 Auto Farm Bosses (Pauses NPC farm until dead)", false, function(v)
    State.AutoFarmBosses = v
    if v then
        Hub.Notify("👹 Boss Hunter", "Priority locked onto selected spawned bosses!", 3)
    end
end)

local bossCatalogItems = {
    {Name = "Leaky Eye Luca"},
    {Name = "Bucciarati"},
    {Name = "Fugo"},
    {Name = "Pesci"},
    {Name = "Ghiaccio"},
    {Name = "Diavolo"},
    {Name = "DIO"},
    {Name = "Jotaro"},
    {Name = "Anasui"},
    {Name = "Yoshikage Kira"},
    {Name = "Jotaro Kujo"},
    {Name = "Heaven Ascension DIO"}
}
Hub.CreateList(combatTab, "Target Bosses (Multi-Select)", bossCatalogItems, 160, false, true)

Hub.CreateSection(combatTab, "🥋 Ability & Keybind Whitelist")

local detectedAbilities = detectAvailableAbilities()
local abilityCatalogItems = {}
for _, ab in ipairs(detectedAbilities) do
    table.insert(abilityCatalogItems, {Name = ab})
end

local abilityListObj = Hub.CreateList(combatTab, "Allowed Attacks / Keybinds (Multi-Select)", abilityCatalogItems, 180, false, true, function(selectedName, entryData)
    if selectedName then
        -- Toggle selection in State.WhitelistAbilities
        State.WhitelistAbilities[selectedName] = not State.WhitelistAbilities[selectedName]
    end
end)

-- Initialize defaults into listObject
if abilityListObj and abilityListObj.SetSelectedItems then
    local defaultSelected = {}
    for abName, enabled in pairs(State.WhitelistAbilities) do
        if enabled then table.insert(defaultSelected, abName) end
    end
    pcall(function() abilityListObj.SetSelectedItems(defaultSelected) end)
end

Hub.CreateButton(combatTab, "🔄 Refresh Detected Keybinds & Skills", function()
    local updated = detectAvailableAbilities()
    local updatedCatalog = {}
    for _, ab in ipairs(updated) do
        table.insert(updatedCatalog, {Name = ab})
    end
    if abilityListObj and abilityListObj.Items then
        for _, itm in ipairs(updatedCatalog) do
            local exists = false
            for _, ex in ipairs(abilityListObj.Items) do
                if ex.Name == itm.Name then exists = true; break end
            end
            if not exists and abilityListObj.AddListItem then
                abilityListObj.AddListItem(itm.Name, "")
            end
        end
    end
    Hub.Notify("🥋 Skills Refreshed", "Scanned player skills, styles, and available keybinds!", 2)
end)

-- -------------------------------------------------------------------------
-- 2. 📜 Quests & Farm Tab
-- -------------------------------------------------------------------------
Hub.CreateSection(questTab, "📜 Auto Quest & Level Farm")

Hub.CreateToggle(questTab, "📜 Auto Farm Selected Quest", false, function(v)
    State.AutoFarmQuests = v
end)

Hub.CreateDropdown(questTab, "Target Quest", ybaNPCsCatalog, 1, function(selected)
    State.SelectedQuest = selected
end)

Hub.CreateSlider(questTab, "Safe Farm Overhead Distance", 3, 15, 7, " studs", function(val)
    State.SafeFarmDistance = val
end)

Hub.CreateToggle(questTab, "⭐ Auto Allocate Skill Points", false, function(v)
    State.AutoSkillPoints = v
end)

-- -------------------------------------------------------------------------
-- 3. 💎 Items & Farm Tab
-- -------------------------------------------------------------------------
Hub.CreateSection(itemsTab, "💎 Auto Collect Spawned Items")

Hub.CreateToggle(itemsTab, "💎 Auto Collect Items (Arrows / Rokas)", false, function(v)
    State.AutoCollectItems = v
end)

Hub.CreateSlider(itemsTab, "Item Collection Delay", 0.1, 2.0, 0.5, "s", function(val)
    State.CollectItemDelay = val
end)

Hub.CreateToggle(itemsTab, "🌟 Prioritize Rare Items (Lucky Arrow, Diary, Ribs)", true, function(v)
    State.PrioritizeRareItems = v
end)

local itemCatalogItems = {}
for _, it in ipairs(ybaItemsCatalog) do table.insert(itemCatalogItems, {Name = it}) end
Hub.CreateList(itemsTab, "Item Whitelist (Multi-Select)", itemCatalogItems, 180, false, true)

-- -------------------------------------------------------------------------
-- 4. 🐎 Steel Ball Run (SBR) Tab
-- -------------------------------------------------------------------------
Hub.CreateSection(sbrTab, "🐎 Steel Ball Run Automations")

Hub.CreateToggle(sbrTab, "🐎 Horse Speed Multiplier", false, function(v)
    State.SBR_SpeedBoost = v
end)

Hub.CreateSlider(sbrTab, "Horse Speed Limit", 30, 100, 50, " studs/s", function(val)
    State.SBR_HorseSpeed = val
end)

Hub.CreateToggle(sbrTab, "🌪️ Anti-Sandstorm / Zone Damage", false, function(v)
    State.SBR_AntiSandstorm = v
end)

Hub.CreateButton(sbrTab, "🏁 Teleport to Stage 1 Finish", function()
    local targetCF = CFrame.new(220, 25, -2350)
    local root = getRoot()
    local dist = root and (root.Position - targetCF.Position).Magnitude or 0
    if State.SafeTeleportMode and dist > 15 then
        local estTime = dist / math.clamp(tonumber(State.SafeTravelSpeed) or 300, 40, 600)
        Hub.Notify("🐎 SBR Safe Travel", string.format("Gliding safely to Stage 1 (%.1fs)...", estTime), 3)
    end
    safeTeleportTo(targetCF, function()
        Hub.Notify("🐎 SBR", "Arrived at Stage 1 Finish line safely!", 3)
    end)
end)

Hub.CreateButton(sbrTab, "🏆 Teleport to Final Finish Line", function()
    local targetCF = CFrame.new(350, 40, -5600)
    local root = getRoot()
    local dist = root and (root.Position - targetCF.Position).Magnitude or 0
    if State.SafeTeleportMode and dist > 15 then
        local estTime = dist / math.clamp(tonumber(State.SafeTravelSpeed) or 300, 40, 600)
        Hub.Notify("🐎 SBR Safe Travel", string.format("Gliding safely to Final Finish Line (%.1fs)...", estTime), 3)
    end
    safeTeleportTo(targetCF, function()
        Hub.Notify("🐎 SBR", "Arrived at Final Finish Line safely!", 3)
    end)
end)

-- -------------------------------------------------------------------------
-- 5. 🎰 Stand Roller Tab
-- -------------------------------------------------------------------------
Hub.CreateSection(standsTab, "🎰 Stand Rolling & Arcade Automation")

Hub.CreateToggle(standsTab, "🎰 Auto Stand Roll (Arrow + Roka)", false, function(v)
    State.AutoStandRoll = v
    if v then
        Hub.Notify("🎰 Stand Roller", "Ensure you have Mysterious Arrows & Rokakakas in your backpack!", 4)
    end
end)

Hub.CreateToggle(standsTab, "✨ Stop on Shiny / Skin Stand", true, function(v)
    State.StopOnShiny = v
end)

Hub.CreateToggle(standsTab, "🕹️ Auto Arcade Spinner", false, function(v)
    State.AutoArcade = v
end)

local standCatalogItems = {}
for _, st in ipairs(ybaStandsCatalog) do table.insert(standCatalogItems, {Name = st}) end
Hub.CreateList(standsTab, "Target Desired Stands (Multi-Select)", standCatalogItems, 200, false, true)

-- -------------------------------------------------------------------------
-- 6. 📍 Teleports Tab
-- -------------------------------------------------------------------------
Hub.CreateSection(tpTab, "📍 Quick Travel Controls")

local function resolveTargetCFrame()
    local targetType = State.TravelTargetType or "Location"
    local targetName = State.SelectedTravelTarget
    if not targetName then return nil end

    if targetType == "Location" then
        local pos = ybaLocations[targetName]
        if pos then
            return CFrame.new(pos + Vector3.new(0, 3, 0))
        end
    elseif targetType == "Boss" then
        local cleanName = targetName:gsub("%s*%b()", ""):gsub("^%s*(.-)%s*$", "%1")
        local living = getLivingFolder()
        if living and cleanName ~= "" and not cleanName:find("No active") then
            for _, ch in ipairs(living:GetChildren()) do
                if ch:IsA("Model") and ch.Name:lower():find(cleanName:lower(), 1, true) then
                    local root = ch:FindFirstChild("HumanoidRootPart") or ch:FindFirstChild("Torso")
                    if root then
                        return CFrame.new(root.Position + Vector3.new(0, 3, 0))
                    end
                end
            end
        end
    elseif targetType == "NPC" then
        local living = getLivingFolder()
        if living and targetName ~= "" then
            for _, ch in ipairs(living:GetChildren()) do
                if ch:IsA("Model") and ch.Name:lower():find(targetName:lower(), 1, true) then
                    local root = ch:FindFirstChild("HumanoidRootPart") or ch:FindFirstChild("Torso")
                    if root then
                        return CFrame.new(root.Position + Vector3.new(0, 3, 0))
                    end
                end
            end
        end
    elseif targetType == "Player" then
        local username = targetName:match("@([%w_]+)") or targetName
        local targetPlr = Players:FindFirstChild(username)
        local tChar = targetPlr and targetPlr.Character
        local tRoot = tChar and (tChar:FindFirstChild("HumanoidRootPart") or tChar:FindFirstChild("Torso"))
        if tRoot then
            return CFrame.new(tRoot.Position + Vector3.new(0, 3, 0))
        end
    end

    return nil
end

local travelToggleRef = nil

local function triggerTravelToSelected()
    if not State.AutoTravelToTarget then return end
    local targetCF = resolveTargetCFrame()
    if not targetCF then
        Hub.Notify("⚠️ Travel Notice", "Selected target not found or alive. Please select a valid target.", 3)
        State.AutoTravelToTarget = false
        return
    end

    local root = getRoot()
    local dist = root and (root.Position - targetCF.Position).Magnitude or 0
    local estTime = dist / math.clamp(tonumber(State.SafeTravelSpeed) or 500, 40, 600)
    Hub.Notify("📍 Safe Travel", string.format("Gliding to %s (approx %.1fs)...", tostring(State.SelectedTravelTarget), estTime), 2)

    safeTeleportTo(targetCF, function()
        Hub.Notify("📍 Arrived", "Arrived at destination safely!", 2)
        -- Auto reset toggle once arrived so player doesn't continuously loop
        State.AutoTravelToTarget = false
    end)
end

travelToggleRef = Hub.CreateToggle(tpTab, "🚀 Enable Travel to Selected Target", false, function(v)
    State.AutoTravelToTarget = v
    if v then
        if not State.SelectedTravelTarget then
            Hub.Notify("⚠️ Select Target", "Choose a Location, Boss, NPC, or Player below first!", 3)
            State.AutoTravelToTarget = false
            return
        end
        triggerTravelToSelected()
    else
        cancelCurrentTravel()
        Hub.Notify("🛑 Travel", "Travel disabled. Stopped cleanly in place.", 2)
    end
end)

-- 1. Locations Category
Hub.CreateSection(tpTab, "📍 Verified Map Locations")

local locationCatalogItems = {}
local sortedLocNames = {}
for name, _ in pairs(ybaLocations) do table.insert(sortedLocNames, name) end
table.sort(sortedLocNames)
for _, name in ipairs(sortedLocNames) do table.insert(locationCatalogItems, {Name = name}) end

Hub.CreateList(tpTab, "Select Location", locationCatalogItems, 160, false, false, function(selectedItem)
    local locName = selectedItem and (selectedItem.Name or selectedItem)
    if locName then
        State.SelectedTravelTarget = locName
        State.TravelTargetType = "Location"
        Hub.Notify("🎯 Target Selected", "Location: " .. locName .. " (Toggle Travel above to go!)", 2)
        if State.AutoTravelToTarget then
            triggerTravelToSelected()
        end
    end
end)

-- 2. Bosses Category
Hub.CreateSection(tpTab, "👹 Active Spawned Bosses")

local function getLiveBossItems()
    local living = getLivingFolder()
    local bossNames = {
        ["Leaky Eye Luca"] = true,
        ["Bucciarati"] = true,
        ["Fugo"] = true,
        ["Pesci"] = true,
        ["Ghiaccio"] = true,
        ["Diavolo"] = true,
        ["DIO"] = true,
        ["Jotaro"] = true,
        ["Anasui"] = true,
        ["Yoshikage Kira"] = true,
        ["Jotaro Kujo"] = true,
        ["Heaven Ascension DIO"] = true
    }
    local items = {}
    if living then
        for _, ch in ipairs(living:GetChildren()) do
            if ch:IsA("Model") and not Players:GetPlayerFromCharacter(ch) then
                local hum = ch:FindFirstChildOfClass("Humanoid")
                local root = ch:FindFirstChild("HumanoidRootPart") or ch:FindFirstChild("Torso")
                if hum and hum.Health > 0 and root then
                    for bName, _ in pairs(bossNames) do
                        if ch.Name:lower():find(bName:lower(), 1, true) then
                            table.insert(items, {Name = ch.Name .. " (" .. math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth) .. " HP)"})
                            break
                        end
                    end
                end
            end
        end
    end
    if #items == 0 then
        table.insert(items, {Name = "No active bosses alive right now"})
    end
    return items
end

local liveBossList = getLiveBossItems()
Hub.CreateList(tpTab, "Select Boss", liveBossList, 140, false, false, function(selectedItem)
    local rawName = selectedItem and (selectedItem.Name or selectedItem) or ""
    if rawName ~= "" and not rawName:find("No active") then
        local cleanName = rawName:gsub("%s*%b()", ""):gsub("^%s*(.-)%s*$", "%1")
        State.SelectedTravelTarget = cleanName
        State.TravelTargetType = "Boss"
        Hub.Notify("🎯 Target Selected", "Boss: " .. cleanName .. " (Toggle Travel above to go!)", 2)
        if State.AutoTravelToTarget then
            triggerTravelToSelected()
        end
    end
end)

-- 3. Regular NPCs Category
Hub.CreateSection(tpTab, "👤 Spawned NPCs & Dialogue Questgivers")

local function getLiveNPCItems()
    local living = getLivingFolder()
    local items = {}
    local seen = {}
    if living then
        for _, ch in ipairs(living:GetChildren()) do
            if ch:IsA("Model") and not Players:GetPlayerFromCharacter(ch) then
                local hum = ch:FindFirstChildOfClass("Humanoid")
                local root = ch:FindFirstChild("HumanoidRootPart") or ch:FindFirstChild("Torso")
                if hum and hum.Health > 0 and root and not seen[ch.Name] then
                    seen[ch.Name] = true
                    table.insert(items, {Name = ch.Name})
                end
            end
        end
    end
    return items
end

local liveNPCList = getLiveNPCItems()
Hub.CreateList(tpTab, "Select NPC", liveNPCList, 140, false, false, function(selectedItem)
    local rawName = selectedItem and (selectedItem.Name or selectedItem) or ""
    if rawName ~= "" then
        State.SelectedTravelTarget = rawName
        State.TravelTargetType = "NPC"
        Hub.Notify("🎯 Target Selected", "NPC: " .. rawName .. " (Toggle Travel above to go!)", 2)
        if State.AutoTravelToTarget then
            triggerTravelToSelected()
        end
    end
end)

-- 4. Players Category
Hub.CreateSection(tpTab, "🎮 Online Players")

local function getOnlinePlayerItems()
    local items = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(items, {Name = p.DisplayName .. " (@" .. p.Name .. ")"})
        end
    end
    if #items == 0 then
        table.insert(items, {Name = "No other players in server"})
    end
    return items
end

local onlinePlayerList = getOnlinePlayerItems()
Hub.CreateList(tpTab, "Select Player", onlinePlayerList, 140, false, false, function(selectedItem)
    local rawName = selectedItem and (selectedItem.Name or selectedItem) or ""
    if rawName ~= "" and not rawName:find("No other players") then
        State.SelectedTravelTarget = rawName
        State.TravelTargetType = "Player"
        Hub.Notify("🎯 Target Selected", "Player: " .. rawName .. " (Toggle Travel above to go!)", 2)
        if State.AutoTravelToTarget then
            triggerTravelToSelected()
        end
    end
end)

-- -------------------------------------------------------------------------
-- 7. 👁️ Visuals / ESP Tab
-- -------------------------------------------------------------------------
Hub.CreateSection(espTab, "👁️ Item & Entity Radar")

Hub.CreateToggle(espTab, "💎 Item ESP (Arrows, Rokas, Ribs)", false, function(v)
    State.ItemESP = v
    if not v then
        local pGui = (gethui and gethui()) or LocalPlayer:FindFirstChild("PlayerGui") or game:GetService("CoreGui")
        local old = pGui and pGui:FindFirstChild("YBA_Item_ESP")
        if old then pcall(function() old:Destroy() end) end
    end
end)

Hub.CreateToggle(espTab, "👤 Player ESP", false, function(v)
    State.PlayerESP = v
end)

Hub.CreateToggle(espTab, "👹 NPC & Boss ESP", false, function(v)
    State.NPCESP = v
end)

-- -------------------------------------------------------------------------
-- 8. 👤 Player & Misc Tab
-- -------------------------------------------------------------------------
Hub.CreateSection(playerTab, "👤 Character Speed & Stamina")

Hub.CreateSlider(playerTab, "WalkSpeed Modifier", 16, 120, 16, " studs/s", function(val)
    State.WalkSpeed = val
    local hum = getHumanoid()
    if hum then hum.WalkSpeed = val end
end)

Hub.CreateSlider(playerTab, "JumpPower Modifier", 50, 200, 50, " power", function(val)
    State.JumpPower = val
    local hum = getHumanoid()
    if hum then hum.JumpPower = val end
end)

Hub.CreateToggle(playerTab, "⚡ Infinite Stamina", false, function(v)
    State.InfiniteStamina = v
end)

Hub.CreateToggle(playerTab, "🧱 Noclip", false, function(v)
    State.Noclip = v
end)

Hub.CreateSection(playerTab, "🌐 Server Utilities")

Hub.CreateButton(playerTab, "🔄 Server Hop (Smallest Server)", function()
    pcall(function()
        local serversUrl = "https://games.roblox.com/v1/games/" .. tostring(game.PlaceId) .. "/servers/Public?sortOrder=Asc&limit=100"
        local res = game:HttpGet(serversUrl)
        local data = HttpService:JSONDecode(res)
        if data and data.data then
            for _, s in ipairs(data.data) do
                if s.playing and s.playing < s.maxPlayers and s.id ~= game.JobId then
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LocalPlayer)
                    return
                end
            end
        end
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end)
end)

Hub.CreateButton(playerTab, "🔁 Rejoin Current Server", function()
    pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end)
end)

Hub.Notify("⭐ UNKNOWN HUB", "Your Bizarre Adventure module loaded successfully!", 4)
