--[[
    ========================================================================
    Unknown Hub - Bee Swarm Simulator
    Complete Automation Suite:
      - Multi-Field Auto Farm & Smart Token Prioritizer
      - Autonomous Sprout Detection & Rare Drop Sniping
      - Smart Hive Honey Conversion Loop
      - Intelligent Vicious Bee Hunter & Hazard Evading Combat
      - Automated Mob Rotator with Spawner Skip Timeouts
      - Collision-Free Navigation & Anti-Stuck Watchdog
      - Autonomous Memory Match Suite (Regular, Mega, Night, Extreme)
      - Ghost Memory Match Card Visualizer & Needed Items Priority Solver
      - Built-in Anti-AFK
    ========================================================================
]]

local LIBRARY_LINK = "https://raw.githubusercontent.com/UnknownHQ/UnknownHub/main/UnknownLibrary"
local LIBRARY_NAME = "Unknown_TabbedHub_UI"

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer

-- =========================================================================
-- Built-in Anti-AFK
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
-- GUI Cleanup
-- =========================================================================
local function destroyOldGui()
    local parents = {CoreGui}
    if gethui then pcall(function() table.insert(parents, gethui()) end) end
    local pGui = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
    if pGui then table.insert(parents, pGui) end
    for _, parent in ipairs(parents) do
        if parent then
            pcall(function()
                for _, child in ipairs(parent:GetChildren()) do
                    if child:IsA("ScreenGui") and (child.Name == LIBRARY_NAME or child.Name:find("Unknown_")) then
                        pcall(function() child:Destroy() end)
                    end
                end
            end)
        end
    end
end

-- =========================================================================
-- UnknownLibrary Dynamic Loader (Online with Local Storage Fallback)
-- =========================================================================
local ok, result = pcall(function()
    local source
    local cacheBuster = "?t=" .. tostring(os.time() or tick()) .. "_" .. tostring(math.random(1000, 9999))
    local fetchSuccess, fetchedSource = pcall(function()
        return game:HttpGet(LIBRARY_LINK .. cacheBuster)
    end)
    if fetchSuccess and fetchedSource and #fetchedSource > 100 then
        source = fetchedSource
    else
        if readfile then
            pcall(function() source = readfile("UnknownLibrary.luau") end)
            if not source then pcall(function() source = readfile("UnknownLibrary") end) end
        end
    end
    assert(source and #source > 100, "Could not load UnknownLibrary from remote or local storage")
    pcall(function()
        source = source:gsub('game:GetService%([\"\'CoreGui\"\'%]%)', "(gethui and gethui() or (game:GetService('Players').LocalPlayer and game:GetService('Players').LocalPlayer:WaitForChild('PlayerGui')))")
    end)
    local factoryChunk, compileErr = loadstring(source)
    assert(factoryChunk, "UnknownLibrary compilation failed: " .. tostring(compileErr))
    return factoryChunk()
end)

assert(ok and type(result) == "function", "UnknownLibrary failed to load: " .. tostring(result))

destroyOldGui()

local Hub = result({
    name = LIBRARY_NAME,
    title = "UNKNOWN HUB",
    subTitle = "Bee Swarm Simulator",
    parent = (gethui and gethui()) or (LocalPlayer and (LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui"))) or (pcall(function() return CoreGui end) and CoreGui),
    theme = Color3.fromRGB(255, 175, 20),
})

assert(type(Hub) == "table", "UnknownLibrary returned an invalid hub")
assert(type(Hub.CreateButton) == "function", "UnknownLibrary is missing CreateButton")
assert(type(Hub.CreateToggle) == "function", "UnknownLibrary is missing CreateToggle")
assert(type(Hub.CreateList) == "function", "UnknownLibrary is missing CreateList")
assert(type(Hub.createTabButton) == "function", "UnknownLibrary is missing createTabButton")

-- =========================================================================
-- Tabs & State Variables
-- =========================================================================
local mainPage = Hub.CreateTab("Main", { Icon = "🐝", Size = 18, Color = Color3.fromRGB(170, 185, 210), ActiveColor = Color3.fromRGB(255, 200, 50) })
local combatPage = Hub.CreateTab("Combat", { Icon = "⚔️", Size = 18, Color = Color3.fromRGB(170, 185, 210), ActiveColor = Color3.fromRGB(255, 80, 80) })
local itemsPage = Hub.CreateTab("Items", { Icon = "🎒", Size = 18, Color = Color3.fromRGB(170, 185, 210), ActiveColor = Color3.fromRGB(120, 220, 150) })

local AutoFarmState = false
local AutoDigState = false
local AutoSprinklersState = false
local CombatState = false
local SelectedMobName = nil
local SelectedMobTypes = {}
local SelectedTokenExclusions = {}
local SelectedFarmSettings = {
    ["Auto Catch Coconuts"] = true,
    ["Auto Farm Sprouts"] = true,
    ["Auto Micro-Converters"] = true,
    ["Farm Balloons"] = true,
    ["Farm Bubbles"] = true,
    ["Farm Flames"] = true,
    ["Farm Fuzzy Bombs"] = true,
}
local StopWhenSproutsLeft = 0
local SelectedSproutActions = {
    ["Auto Farm Sprouts"] = true,
    ["Auto Plant Sprouts"] = false,
    ["Auto Tween to Rare Drops"] = true,
}
local SelectedSproutRarities = {
    ["Common"] = true,
    ["Epic"] = true,
    ["Festive"] = true,
    ["Gummy"] = true,
    ["Legendary"] = true,
    ["Moon"] = true,
    ["Rare"] = true,
    ["Supreme"] = true,
}
local SelectedSproutExcludedFields = {}
local PriorityRanks = {
    ["Token Link"] = 1,
    ["Fuzzy Bomb"] = 2,
    ["Baby Love"] = 3,
    ["Melody"] = 4,
}
local AutoViciousBeeState = false
local ViciousBeeRequested = false
local MinViciousLevel = 1
local MaxViciousLevel = 20
local SelectedViciousExcludedFields = {}
local CombatRequested = false
local MobThreatActive = false
local TweenSpeed = 6
local combatList = nil
local combatSpawnIndex = 1
local combatTypeIndex = 1
local combatTargetSeen = false
local combatStayStartTime = 0
local lastCombatSpawnKey = ""
local farmRunId = 0
local activeTween = nil
local activeRoot = nil
local activeHumanoid = nil
local activeRootAnchored = nil
local activeAutoRotate = nil
local blockedTokens = {}
local isConvertingAtHive = false
local convertStartTime = 0
local SelectedFarmField = nil

-- Memory Match States
local AutoMemoryMatchState = false
local GhostMemoryMatchState = true
local isRunningMemoryMatch = false
local knownTiles = {}
local matchedTiles = {}
local isMemoryMatchActive = false

local SelectedMemoryMatches = {
    ["Memory Match"] = true,
    ["Mega Memory Match"] = true,
    ["Night Memory Match"] = true,
    ["Extreme Memory Match"] = true,
}

local SelectedNeededItems = {
    ["Mythic Egg"] = true,
    ["Star Treat"] = true,
    ["Atomic Treat"] = true,
    ["Star Jelly"] = true,
    ["Super Smoothie"] = true,
    ["Festive Bean"] = true,
    ["Night Bell"] = true,
    ["Diamond Egg"] = true,
    ["Gold Egg"] = true,
    ["Silver Egg"] = true,
    ["Hard Wax"] = true,
    ["Swirled Wax"] = true,
    ["Soft Wax"] = true,
    ["Smooth Dice"] = true,
    ["Cloud Vial"] = true,
    ["Glitter"] = true,
    ["Glue"] = true,
    ["Oil"] = true,
    ["Enzymes"] = true,
    ["Red Extract"] = true,
    ["Blue Extract"] = true,
    ["Tropical Drink"] = true,
    ["Neonberry"] = true,
    ["Magic Bean"] = true,
    ["Micro-Converter"] = true,
    ["Field Dice"] = true,
    ["Ticket"] = true,
    ["Moon Charm"] = true,
    ["Royal Jelly"] = true,
}

local MemoryMatchToys = {
    ["Memory Match"] = {
        name = "Memory Match",
        cost = 25000,
        cooldown = 7200,
        pos = Vector3.new(136.9, 65.4, -95.7),
        desc = "Regular (10 Bee Zone, near Pro Bear)"
    },
    ["Mega Memory Match"] = {
        name = "Mega Memory Match",
        cost = 500000,
        cooldown = 14400,
        pos = Vector3.new(-429.9, 77.3, -55.0),
        desc = "Mega (15 Bee Zone, near Mountain Top)"
    },
    ["Night Memory Match"] = {
        name = "Night Memory Match",
        cost = 5000000,
        cooldown = 28800,
        pos = Vector3.new(-18.3, 317.5, -269.0),
        desc = "Night (30 Bee Zone, Moon Room)"
    },
    ["Extreme Memory Match"] = {
        name = "Extreme Memory Match",
        cost = 25000000,
        cooldown = 28800,
        pos = Vector3.new(-405.4, 126.3, 548.1),
        desc = "Extreme (35 Bee Zone, near Spirit Bear)"
    },
}

local RemoteOnlyMemoryMatch = false
local toyCooldownEndTimes = {}
local toyAttemptBackoffs = {}

-- =========================================================================
-- Workspace Folders & Modules
-- =========================================================================
local FieldsFolder = workspace:WaitForChild("FlowerZones")
local CollectiblesFolder = workspace:WaitForChild("Collectibles")
local MonstersFolder = workspace:WaitForChild("Monsters")
local MonsterSpawnersFolder = workspace:WaitForChild("MonsterSpawners")
local HoneycombsFolder = workspace:WaitForChild("Honeycombs")
local HoneyTokenTexture = "rbxassetid://1472135114"

local CollectorsFolder = ReplicatedStorage:WaitForChild("Collectors")
local LocalCollect = nil
pcall(function()
    LocalCollect = require(CollectorsFolder:WaitForChild("LocalCollect"))
end)

local Sprinklers = nil
pcall(function()
    Sprinklers = require(ReplicatedStorage:WaitForChild("Sprinklers"))
end)

local function safeStartCollection()
    pcall(function()
        if LocalCollect and type(LocalCollect.StartCollection) == "function" then
            LocalCollect.StartCollection()
        end
    end)
end

local function safeStopCollection()
    pcall(function()
        if LocalCollect and type(LocalCollect.StopCollection) == "function" then
            LocalCollect.StopCollection()
        end
    end)
end

local function getCharacter()
    local char = LocalPlayer.Character
    if not char then return nil, nil, nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not hum or not root or hum.Health <= 0 then return nil, nil, nil end
    return char, root, hum
end

-- =========================================================================
-- Token Texture Mappings
-- =========================================================================
local tokenTextureMap = {
    ["Token Link"] = {"2584584968"},
    ["Blue Boost"] = {"2542899798", "2011980087"},
    ["Red Boost"] = {"2542899798", "2011980302"},
    ["Focus"] = {"1952682401", "2011980606"},
    ["Melody"] = {"3036899811"},
    ["Rage"] = {"1952796032"},
    ["Haste"] = {"3080740120"},
    ["Baby Love"] = {"2504978518"},
    ["Impale"] = {"3012679515"},
    ["Fuzzy Bomb"] = {"8054996680", "8055428094", "8058047989", "8277901755"},
    ["Bomb"] = {"1471882621", "2011980203"},
    ["Bomb+"] = {"2011980203"},
    ["Buzz Bomb"] = {"1471882621"},
    ["Scratch"] = {"3030569073", "2011980606"},
    ["Tornado"] = {"3080740120", "2028574353"},
    ["Beam"] = {"2504978518", "65867881"},
    ["Triangulate"] = {"2584584968", "8054996680"},
    ["Target Mark"] = {"1952682401", "2011980606"},
    ["Tabby Love"] = {"3030569073"},
    ["Honey Gift"] = {"1472135114", "3030569073"},
    ["Pollen Haze"] = {"8054996680"},
    ["Flame"] = {"1471849394"},
    ["Bubble"] = {"1674871631"},
    ["Inspire"] = {"3036899811"},
    ["Surprise Party"] = {"2319943273"},
    ["Super Crit"] = {"1952682401"},
    ["Tree"] = {"2028574353"},
    ["Coconut"] = {"102919124614648", "13369738621"},
    ["Sprout Loot"] = {"2319943273", "1952740625", "1471850677"},
    ["Micro-Converter"] = {"2584584968"},
}

local rareTokenKeywords = {
    "enzyme",
    "oil",
    "glitter",
    "glue",
    "starjelly",
    "star_jelly",
    "magicbean",
    "bean",
    "mooncharm",
    "charm",
    "extract",
    "dice",
    "wax",
    "bell",
    "egg",
    "nightbell",
    "ticket",
}

local function isRareCollectibleToken(tokenPart)
    if not tokenPart then return false end
    local parentName = string.lower(tokenPart.Parent and tokenPart.Parent.Name or "")
    local partName = string.lower(tokenPart.Name)
    for _, kw in ipairs(rareTokenKeywords) do
        if string.find(parentName, kw) or string.find(partName, kw) then
            return true
        end
    end
    for _, child in ipairs(tokenPart:GetDescendants()) do
        if child:IsA("Decal") or child:IsA("Texture") then
            local tex = string.lower(tostring(child.Texture))
            for _, kw in ipairs(rareTokenKeywords) do
                if string.find(tex, kw) then
                    return true
                end
            end
        elseif child:IsA("BillboardGui") then
            for _, lbl in ipairs(child:GetDescendants()) do
                if lbl:IsA("TextLabel") then
                    local txt = string.lower(lbl.Text)
                    for _, kw in ipairs(rareTokenKeywords) do
                        if string.find(txt, kw) then
                            return true
                        end
                    end
                end
            end
        end
    end
    return false
end

-- =========================================================================
-- Noclip & Collision Management
-- =========================================================================
local noclipConnection = nil
local function setNoclip(enabled)
    if enabled then
        if not noclipConnection then
            noclipConnection = RunService.Stepped:Connect(function()
                local char = LocalPlayer.Character
                if char then
                    for _, part in ipairs(char:GetDescendants()) do
                        if part:IsA("BasePart") and part.CanCollide then
                            part.CanCollide = false
                        end
                    end
                end
            end)
        end
    else
        if noclipConnection then
            noclipConnection:Disconnect()
            noclipConnection = nil
        end
    end
end

local function releaseActiveTween()
    if activeTween then
        activeTween:Cancel()
        activeTween = nil
    end

    setNoclip(false)

    if activeRoot and activeRoot.Parent then
        pcall(function()
            activeRoot.Anchored = activeRootAnchored == true
            activeRoot.AssemblyLinearVelocity = Vector3.zero
            activeRoot.AssemblyAngularVelocity = Vector3.zero
        end)
    end
    if activeHumanoid and activeHumanoid.Parent then
        pcall(function()
            activeHumanoid.AutoRotate = activeAutoRotate ~= false
        end)
    end

    activeRoot = nil
    activeHumanoid = nil
    activeRootAnchored = nil
    activeAutoRotate = nil
end

LocalPlayer.CharacterAdded:Connect(function()
    releaseActiveTween()
    isConvertingAtHive = false
    isRunningMemoryMatch = false
    task.wait(1)
    if AutoDigState or AutoFarmState then
        safeStartCollection()
    end
end)

-- =========================================================================
-- Danger Zone & Hazard Detection
-- =========================================================================
local function getActiveDangerZones()
    local dangerZones = {}

    local particles = workspace:FindFirstChild("Particles")
    if particles then
        for _, part in ipairs(particles:GetChildren()) do
            if part:IsA("BasePart") then
                local name = string.lower(part.Name)
                local isDanger = false
                local radius = math.max(part.Size.X, part.Size.Z) / 2

                if string.find(name, "warn") or string.find(name, "circle") or string.find(name, "stinger")
                    or string.find(name, "target") or string.find(name, "spike") or string.find(name, "red") then
                    isDanger = true
                elseif part.Color.R > 0.65 and part.Color.G < 0.35 and part.Color.B < 0.35 then
                    isDanger = true
                else
                    for _, child in ipairs(part:GetChildren()) do
                        if child:IsA("Decal") or child:IsA("Texture") then
                            local tex = string.lower(tostring(child.Texture))
                            if string.find(tex, "circle") or string.find(tex, "target") or string.find(tex, "warn") or string.find(tex, "red") then
                                isDanger = true
                                break
                            end
                        end
                    end
                end

                if isDanger then
                    table.insert(dangerZones, {
                        Position = part.Position,
                        Radius = math.max(radius, 6),
                    })
                end
            end
        end
    end

    local spikes = workspace:FindFirstChild("Spikes")
    if spikes then
        for _, spike in ipairs(spikes:GetChildren()) do
            local spikePart = spike:IsA("BasePart") and spike or spike:FindFirstChildWhichIsA("BasePart", true)
            if spikePart then
                table.insert(dangerZones, {
                    Position = spikePart.Position,
                    Radius = 7,
                })
            end
        end
    end

    return dangerZones
end

local function isPositionInDangerZone(position, dangerZones, margin)
    margin = margin or 5
    for _, zone in ipairs(dangerZones) do
        local dist = (Vector2.new(position.X, position.Z) - Vector2.new(zone.Position.X, zone.Position.Z)).Magnitude
        if dist <= (zone.Radius + margin) then
            return true, zone
        end
    end
    return false, nil
end

-- =========================================================================
-- Motion & Tween Engine
-- =========================================================================
local function tweenCharacterTo(root, humanoid, destination, speedMultiplier)
    releaseActiveTween()
    if not root or not root.Parent or not humanoid or not humanoid.Parent or humanoid.Health <= 0 then
        return
    end

    activeRoot = root
    activeHumanoid = humanoid
    activeRootAnchored = root.Anchored
    activeAutoRotate = humanoid.AutoRotate
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    root.Anchored = true
    humanoid.AutoRotate = false

    setNoclip(true)

    local speed = (TweenSpeed * 4) * (speedMultiplier or 1)
    local distance = (root.Position - destination).Magnitude
    local duration = math.max(distance / speed, 0.05)

    activeTween = TweenService:Create(
        root,
        TweenInfo.new(duration, Enum.EasingStyle.Linear),
        {CFrame = CFrame.new(destination)}
    )
    local tween = activeTween
    tween:Play()
    tween.Completed:Wait()
    if activeTween == tween then
        releaseActiveTween()
    end
end

local function tweenToFieldTarget(field, root, humanoid, runId, targetPosition, targetObject)
    if not AutoFarmState or runId ~= farmRunId or not root or not root.Parent or not humanoid or not humanoid.Parent or humanoid.Health <= 0 then
        return
    end

    releaseActiveTween()
    activeRoot = root
    activeHumanoid = humanoid
    activeRootAnchored = root.Anchored
    activeAutoRotate = humanoid.AutoRotate
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    root.Anchored = true
    humanoid.AutoRotate = false

    setNoclip(true)

    local speed = TweenSpeed * 4
    local distance = (root.Position - targetPosition).Magnitude
    local duration = math.max(distance / speed, 0.05)

    activeTween = TweenService:Create(
        root,
        TweenInfo.new(duration, Enum.EasingStyle.Linear),
        {CFrame = CFrame.new(targetPosition)}
    )
    local tween = activeTween
    tween:Play()

    local deadline = time() + duration + 0.15
    while AutoFarmState and runId == farmRunId and root.Parent and humanoid.Health > 0 and time() < deadline and activeTween == tween do
        if MobThreatActive then
            break
        end
        if isRunningMemoryMatch then
            break
        end
        if AutoViciousBeeState then
            local dangerZones = getActiveDangerZones()
            if isPositionInDangerZone(root.Position, dangerZones, 5) then
                break
            end
            if targetPosition and isPositionInDangerZone(targetPosition, dangerZones, 5) then
                break
            end
        end
        if targetObject and (not targetObject.Parent or (targetObject:IsA("BasePart") and targetObject.Transparency >= 0.8)) then
            break
        end
        if (root.Position - targetPosition).Magnitude <= 2.5 then
            break
        end
        task.wait(0.02)
    end

    if activeTween == tween then
        releaseActiveTween()
    end

    if targetObject then
        blockedTokens[targetObject] = time() + 0.5
    end
end

local function getTokenPart(token)
    if token:IsA("BasePart") then
        return token
    end
    return token:FindFirstChildWhichIsA("BasePart", true)
end

local tokenTextureTypes = {
    ["Treat"] = {"rbxassetid://1471850677"},
    ["Blueberries"] = {"rbxassetid://1674871631"},
    ["Honey"] = {"rbxassetid://1472135114", "rbxassetid://3030569073"},
    ["Strawberries"] = {"rbxassetid://1838129169"},
    ["Sunflower Seeds"] = {"rbxassetid://2060626811"},
    ["Gumdrops"] = {"rbxassetid://1952740625"},
    ["Royal Jelly"] = {"rbxassetid://2319943273"},
}

local function isExcludedToken(tokenPart)
    local textures = {}
    for _, child in ipairs(tokenPart:GetDescendants()) do
        if child:IsA("Decal") or child:IsA("Texture") then
            textures[child.Texture] = true
        end
    end
    for tokenType, enabled in pairs(SelectedTokenExclusions) do
        if enabled then
            for _, texture in ipairs(tokenTextureTypes[tokenType] or {}) do
                if textures[texture] then
                    return true
                end
            end
        end
    end
    return false
end

local function getTokenPriorityMultiplier(tokenPart)
    local textures = {}
    for _, child in ipairs(tokenPart:GetDescendants()) do
        if child:IsA("Decal") or child:IsA("Texture") then
            local tex = string.lower(tostring(child.Texture))
            textures[tex] = true
        end
    end

    local highestRank = nil
    for tokenName, rank in pairs(PriorityRanks) do
        if rank and rank > 0 then
            local patterns = tokenTextureMap[tokenName] or {}
            for _, pattern in ipairs(patterns) do
                for tex in pairs(textures) do
                    if string.find(tex, pattern) then
                        if not highestRank or rank < highestRank then
                            highestRank = rank
                        end
                        break
                    end
                end
            end
        end
    end

    if highestRank then
        local multipliers = {
            [1] = 0.02,
            [2] = 0.05,
            [3] = 0.10,
            [4] = 0.20,
            [5] = 0.35,
        }
        return multipliers[highestRank] or math.clamp(0.06 * highestRank, 0.02, 0.75)
    end

    return 1.0
end

local function isTokenInField(tokenPart, field)
    if not tokenPart or not field then return false end
    local localPosition = field.CFrame:PointToObjectSpace(tokenPart.Position)
    return math.abs(localPosition.X) <= (field.Size.X / 2 + 6)
        and math.abs(localPosition.Z) <= (field.Size.Z / 2 + 6)
end

local function isPositionInField(position, field, margin)
    if not position or not field then return false end
    local localPosition = field.CFrame:PointToObjectSpace(position)
    return math.abs(localPosition.X) <= field.Size.X / 2 + (margin or 0)
        and math.abs(localPosition.Z) <= field.Size.Z / 2 + (margin or 0)
end

-- =========================================================================
-- Field Target Selection
-- =========================================================================
local function findNearestFieldTarget(field, root)
    local nearestTarget = nil
    local nearestTargetPos = nil
    local nearestScore = math.huge
    local now = time()

    if SelectedFarmSettings["Auto Catch Coconuts"] and workspace:FindFirstChild("Particles") then
        for _, particle in ipairs(workspace.Particles:GetChildren()) do
            if particle:IsA("BasePart") and (string.find(string.lower(particle.Name), "coco") or string.find(string.lower(particle.Name), "nut"))
                and isPositionInField(particle.Position, field, 4) then
                local dist = (Vector3.new(particle.Position.X, root.Position.Y, particle.Position.Z) - root.Position).Magnitude
                local rank = PriorityRanks["Coconut"]
                local multiplier = rank and math.clamp(0.05 * rank, 0.02, 0.8) or 0.15
                local score = dist * multiplier
                if score < nearestScore then
                    nearestTarget = particle
                    nearestTargetPos = particle.Position
                    nearestScore = score
                end
            end
        end
    end

    for _, collectible in ipairs(CollectiblesFolder:GetChildren()) do
        local tokenPart = getTokenPart(collectible)
        local blockedUntil = tokenPart and blockedTokens[tokenPart]
        if blockedUntil and now >= blockedUntil then
            blockedTokens[tokenPart] = nil
            blockedUntil = nil
        end
        if tokenPart and tokenPart.Parent and tokenPart.Transparency < 0.8 and not blockedUntil
            and not isExcludedToken(tokenPart)
            and isTokenInField(tokenPart, field) then
            local dist = (Vector3.new(tokenPart.Position.X, root.Position.Y, tokenPart.Position.Z) - root.Position).Magnitude
            local isRare = SelectedSproutActions["Auto Tween to Rare Drops"] and isRareCollectibleToken(tokenPart)
            local multiplier = getTokenPriorityMultiplier(tokenPart)

            if isRare then
                multiplier = 0.005
            elseif SelectedFarmSettings["Auto Farm Sprouts"] or SelectedSproutActions["Auto Farm Sprouts"] then
                local sproutsFolder = workspace:FindFirstChild("Sprouts")
                if sproutsFolder and #sproutsFolder:GetChildren() > 0 then
                    multiplier = multiplier * 0.4
                end
            end

            local score = dist * multiplier
            if score < nearestScore then
                nearestTarget = tokenPart
                nearestTargetPos = tokenPart.Position
                nearestScore = score
            end
        end
    end

    if SelectedFarmSettings["Farm Flames"] and workspace:FindFirstChild("PlayerFlames") then
        for _, flame in ipairs(workspace.PlayerFlames:GetChildren()) do
            if flame:IsA("BasePart") and isPositionInField(flame.Position, field, 0) then
                local dist = (Vector3.new(flame.Position.X, root.Position.Y, flame.Position.Z) - root.Position).Magnitude
                local rank = PriorityRanks["Flame"]
                local multiplier = rank and math.clamp(0.05 * rank, 0.02, 0.8) or 0.4
                local score = dist * multiplier
                if score < nearestScore then
                    nearestTarget = flame
                    nearestTargetPos = flame.Position
                    nearestScore = score
                end
            end
        end
    end

    if SelectedFarmSettings["Farm Bubbles"] and workspace:FindFirstChild("Particles") then
        for _, particle in ipairs(workspace.Particles:GetChildren()) do
            if particle:IsA("BasePart") and (particle.Name == "Ripple" or particle.Name == "Orb" or particle.Name == "Part")
                and isPositionInField(particle.Position, field, 0) then
                local dist = (Vector3.new(particle.Position.X, root.Position.Y, particle.Position.Z) - root.Position).Magnitude
                local rank = PriorityRanks["Bubble"]
                local multiplier = rank and math.clamp(0.05 * rank, 0.02, 0.8) or 0.5
                local score = dist * multiplier
                if score < nearestScore then
                    nearestTarget = particle
                    nearestTargetPos = particle.Position
                    nearestScore = score
                end
            end
        end
    end

    if SelectedFarmSettings["Farm Balloons"] and workspace:FindFirstChild("Balloons") then
        for _, balloon in ipairs(workspace.Balloons:GetChildren()) do
            local balloonPart = balloon:IsA("BasePart") and balloon or balloon:FindFirstChildWhichIsA("BasePart", true)
            if balloonPart and isPositionInField(balloonPart.Position, field, 5) then
                local dist = (Vector3.new(balloonPart.Position.X, root.Position.Y, balloonPart.Position.Z) - root.Position).Magnitude
                local score = dist * 0.6
                if score < nearestScore then
                    nearestTarget = balloonPart
                    nearestTargetPos = balloonPart.Position
                    nearestScore = score
                end
            end
        end
    end

    return nearestTarget, nearestTargetPos
end

local function farmFieldTargets(field, root, humanoid, runId)
    local targetObject, targetPosition = findNearestFieldTarget(field, root)
    if targetObject and targetPosition then
        local targetPos = Vector3.new(targetPosition.X, field.Position.Y + 3.5, targetPosition.Z)
        tweenToFieldTarget(field, root, humanoid, runId, targetPos, targetObject)
        return false
    end

    local fieldPosition = field.Position
    local fieldSize = field.Size
    local roamPosition = Vector3.new(
        fieldPosition.X + (math.random() - 0.5) * fieldSize.X * 0.7,
        fieldPosition.Y + 3.5,
        fieldPosition.Z + (math.random() - 0.5) * fieldSize.Z * 0.7
    )
    tweenToFieldTarget(field, root, humanoid, runId, roamPosition, nil)
    return false
end

local function jumpForOwnedFieldMob(field, character, humanoid, shouldJump)
    local player = LocalPlayer
    for _, monster in ipairs(MonstersFolder:GetChildren()) do
        local monsterRoot = monster:FindFirstChild("HumanoidRootPart")
        local monsterHumanoid = monster:FindFirstChildOfClass("Humanoid")
        local target = monster:FindFirstChild("Target")
        local targetValue = target and target:IsA("ObjectValue") and target.Value

        if monsterRoot and monsterHumanoid and monsterHumanoid.Health > 0
            and (targetValue == character or targetValue == player)
            and isTokenInField(monsterRoot, field) then
            if shouldJump then
                humanoid.Jump = true
            end
            return true
        end
    end
    return false
end

-- =========================================================================
-- Hive Detection & Honey Conversion
-- =========================================================================
local function getOwnHivePosition()
    local player = LocalPlayer
    if not player then return nil end

    local hiveObj = player:FindFirstChild("Honeycomb")
    if hiveObj and hiveObj:IsA("ObjectValue") and hiveObj.Value then
        local hive = hiveObj.Value
        local spawnPos = hive:FindFirstChild("SpawnPos")
        if spawnPos and spawnPos:IsA("CFrameValue") then
            return spawnPos.Value.Position + Vector3.new(0, 4, 0)
        end
        local platform = hive:FindFirstChild("Platform")
        local platPart = platform and platform:IsA("ObjectValue") and platform.Value
        if platPart and platPart:IsA("BasePart") then
            return platPart.Position + Vector3.new(0, 4, 0)
        end
    end

    local pSpawn = player:FindFirstChild("SpawnPos")
    if pSpawn and pSpawn:IsA("CFrameValue") then
        return pSpawn.Value.Position + Vector3.new(0, 4, 0)
    end

    for _, hive in ipairs(HoneycombsFolder:GetChildren()) do
        local owner = hive:FindFirstChild("Owner")
        local spawnPosition = hive:FindFirstChild("SpawnPos")
        if owner and owner:IsA("ObjectValue") and owner.Value == player
            and spawnPosition and spawnPosition:IsA("CFrameValue") then
            return spawnPosition.Value.Position + Vector3.new(0, 4, 0)
        end
    end

    return nil
end

local function getBagStats()
    local stats = LocalPlayer:FindFirstChild("CoreStats")
    local pollen = stats and stats:FindFirstChild("Pollen")
    local capacity = stats and stats:FindFirstChild("Capacity")
    local pVal = pollen and pollen.Value or 0
    local cVal = capacity and capacity.Value or 1
    return pVal, cVal, (pVal >= cVal)
end

-- =========================================================================
-- Sprinkler Management
-- =========================================================================
local function getSprinklerPlacementPoints(field, radius, count)
    local points = {}
    if count == 1 then
        table.insert(points, field.Position + Vector3.new(0, 4, 0))
        return points
    end

    local spacing = math.max(radius * 1.5, 10)
    local columns = math.max(1, math.floor(field.Size.X / spacing))
    local rows = math.max(1, math.floor(field.Size.Z / spacing))

    for x = 1, columns do
        for z = 1, rows do
            if #points >= count then
                return points
            end
            local xOffset = (x - (columns + 1) / 2) * spacing
            local zOffset = (z - (rows + 1) / 2) * spacing
            table.insert(points, field.CFrame:PointToWorldSpace(Vector3.new(xOffset, 4, zOffset)))
        end
    end

    if #points == 0 then
        table.insert(points, field.Position + Vector3.new(0, 4, 0))
    end
    return points
end

local function placeSprinklersInField(field, humanoid, runId)
    if not AutoSprinklersState or not AutoFarmState or runId ~= farmRunId then
        return
    end

    local equippedType = nil
    local builderCount = 0
    pcall(function()
        local statCacheMod = ReplicatedStorage:FindFirstChild("ClientStatCache")
        local cache = statCacheMod and require(statCacheMod):Get()
        equippedType = cache and cache.EquippedSprinkler
        builderCount = cache and cache.Eggs and cache.Eggs.SprinklerBuilder or 0
    end)

    local sprinklerCount = 1
    local sprinklerRadius = 12
    if Sprinklers and equippedType then
        pcall(function()
            sprinklerCount = Sprinklers.GetStat(equippedType, "Count") or 1
            sprinklerRadius = Sprinklers.GetStat(equippedType, "Radius") or 12
        end)
    end

    if not equippedType or equippedType == "None" or builderCount <= 0 then
        return
    end

    local PlayerActivesMod = ReplicatedStorage:FindFirstChild("PlayerActives")
    local PlayerActives = nil
    pcall(function() PlayerActives = PlayerActivesMod and require(PlayerActivesMod) end)

    local EventsFolder = ReplicatedStorage:FindFirstChild("Events")
    local points = getSprinklerPlacementPoints(field, sprinklerRadius, sprinklerCount)
    local root = humanoid.Parent and humanoid.Parent:FindFirstChild("HumanoidRootPart")

    for _, point in ipairs(points) do
        if not AutoSprinklersState or not AutoFarmState or runId ~= farmRunId then
            return
        end

        if root then
            tweenCharacterTo(root, humanoid, point)
            humanoid.Jump = true
        end
        task.wait(0.08)

        local active = PlayerActives and (PlayerActives.Get("Sprinkler Builder") or PlayerActives.Get("SprinklerBuilder"))
        if active and type(active.ClientActivate) == "function" then
            pcall(function() active:ClientActivate(true) end)
        end
        if EventsFolder and EventsFolder:FindFirstChild("PlayerActivesCommand") then
            pcall(function() EventsFolder.PlayerActivesCommand:FireServer({Name = "Sprinkler Builder"}) end)
            pcall(function() EventsFolder.PlayerActivesCommand:FireServer({Name = "SprinklerBuilder"}) end)
        end
        task.wait(0.2)
    end
end

-- =========================================================================
-- Combat Mobs & Mob Rotation
-- =========================================================================
local function getSelectedMobSpawns()
    local spawns = {}
    if not SelectedMobName then
        return spawns
    end
    for _, spawn in ipairs(MonsterSpawnersFolder:GetChildren()) do
        local monsterType = spawn:FindFirstChild("MonsterType")
        if monsterType and monsterType:IsA("StringValue") and monsterType.Value == SelectedMobName then
            table.insert(spawns, spawn)
        end
    end
    return spawns
end

local function getSelectedMobTypes()
    local types = {}
    for mobType, enabled in pairs(SelectedMobTypes) do
        if enabled then
            table.insert(types, mobType)
        end
    end
    table.sort(types)
    return types
end

local function getCombatField(spawn)
    local territory = spawn:FindFirstChild("Zone") or spawn:FindFirstChild("Territory")
    if territory and territory:IsA("StringValue") then
        local field = FieldsFolder:FindFirstChild(territory.Value)
        if field then
            return field
        end
        local aliases = {
            MushroomZone = "Mushroom Field",
            WerewolfPlateau = "Werewolf Plateau",
            InsideCave = "Spider Field",
            KingBeetleCave = "Clover Field",
        }
        return aliases[territory.Value] and FieldsFolder:FindFirstChild(aliases[territory.Value])
    end
    return nil
end

local function runCombatStep(root, humanoid, currentMarker, runId)
    local selectedTypes = getSelectedMobTypes()
    if #selectedTypes == 0 then return nil end

    if combatTypeIndex > #selectedTypes then
        combatTypeIndex = 1
    end
    SelectedMobName = selectedTypes[combatTypeIndex]
    if not SelectedMobName then
        return nil
    end

    local spawns = getSelectedMobSpawns()
    if #spawns == 0 then
        combatTypeIndex = combatTypeIndex % #selectedTypes + 1
        combatSpawnIndex = 1
        return nil
    end

    if combatSpawnIndex > #spawns then
        combatSpawnIndex = 1
    end
    local spawn = spawns[combatSpawnIndex]
    if not spawn then
        combatSpawnIndex = 1
        return nil
    end

    local spawnKey = tostring(SelectedMobName) .. "_" .. tostring(spawn.Name)
    if spawnKey ~= lastCombatSpawnKey then
        lastCombatSpawnKey = spawnKey
        combatStayStartTime = os.time()
        combatTargetSeen = false
    end

    local combatField = getCombatField(spawn)
    local liveMonster
    local liveMonsterRoot
    for _, monster in ipairs(MonstersFolder:GetChildren()) do
        local liveType = monster:FindFirstChild("MonsterType")
        local monsterHumanoid = monster:FindFirstChildOfClass("Humanoid")
        local monsterRoot = monster:FindFirstChild("HumanoidRootPart") or monster:FindFirstChild("Torso") or monster:FindFirstChildWhichIsA("BasePart", true)
        if liveType and liveType:IsA("StringValue") and liveType.Value == SelectedMobName
            and monsterHumanoid and monsterHumanoid.Health > 0 and monsterRoot then
            liveMonster = monster
            liveMonsterRoot = monsterRoot
            break
        end
    end

    local targetCenter
    if combatField then
        targetCenter = combatField.Position + Vector3.new(0, 4, 0)
    else
        targetCenter = spawn.Position + Vector3.new(0, 4, 0)
    end

    local combatMarker = "__combat:" .. spawn.Name .. ":" .. (combatField and combatField.Name or "center")
    if currentMarker ~= combatMarker then
        tweenCharacterTo(root, humanoid, targetCenter)
        currentMarker = combatMarker
    end

    if liveMonster and liveMonsterRoot then
        combatTargetSeen = true
        combatStayStartTime = os.time()
        safeStartCollection()

        local angle = tick() * 2.5
        local orbitRadius = 14
        local baseY = (combatField and combatField.Position.Y or liveMonsterRoot.Position.Y) + 4.5
        local orbitPos = Vector3.new(
            liveMonsterRoot.Position.X + math.cos(angle) * orbitRadius,
            baseY,
            liveMonsterRoot.Position.Z + math.sin(angle) * orbitRadius
        )

        if combatField and not isPositionInField(orbitPos, combatField, 0) then
            orbitPos = combatField.Position + Vector3.new(0, 4.5, 0)
        end

        tweenToFieldTarget(combatField or workspace, root, humanoid, runId, orbitPos, nil)
    else
        if combatTargetSeen then
            combatTargetSeen = false
            if combatSpawnIndex >= #spawns then
                combatSpawnIndex = 1
                combatTypeIndex = combatTypeIndex % #selectedTypes + 1
            else
                combatSpawnIndex = combatSpawnIndex + 1
            end
            return nil
        end

        if os.time() - combatStayStartTime >= 3 then
            if combatSpawnIndex >= #spawns then
                combatSpawnIndex = 1
                combatTypeIndex = combatTypeIndex % #selectedTypes + 1
            else
                combatSpawnIndex = combatSpawnIndex + 1
            end
            return nil
        end
    end
    return currentMarker
end

-- =========================================================================
-- Vicious Bee Hunter
-- =========================================================================
local function getViciousBeeLevel(monster)
    local lvl = monster:GetAttribute("Level") or (monster:FindFirstChild("Level") and monster.Level.Value)
    if lvl and type(lvl) == "number" then
        return lvl
    end

    for _, desc in ipairs(monster:GetDescendants()) do
        if desc:IsA("TextLabel") then
            local num = string.match(desc.Text, "%[Lvl%s*(%d+)%]") or string.match(desc.Text, "Lvl%s*(%d+)") or string.match(desc.Text, "Level%s*(%d+)")
            if num then
                return tonumber(num) or 8
            end
        end
    end

    local nameNum = string.match(monster.Name, "%d+")
    if nameNum then
        return tonumber(nameNum) or 8
    end

    return 8
end

local function findActiveViciousBee()
    for _, monster in ipairs(MonstersFolder:GetChildren()) do
        local monsterType = monster:FindFirstChild("MonsterType")
        local typeName = monsterType and monsterType:IsA("StringValue") and monsterType.Value or monster.Name
        local monsterRoot = monster:FindFirstChild("HumanoidRootPart") or monster:FindFirstChild("Torso") or monster:FindFirstChildWhichIsA("BasePart", true)
        local monsterHumanoid = monster:FindFirstChildOfClass("Humanoid")

        if (typeName == "Vicious Bee" or typeName == "Gifted Vicious Bee" or string.find(string.lower(monster.Name), "vicious"))
            and monsterRoot and (not monsterHumanoid or monsterHumanoid.Health > 0) then

            local level = getViciousBeeLevel(monster)
            if level >= MinViciousLevel and level <= MaxViciousLevel then
                for _, field in ipairs(FieldsFolder:GetChildren()) do
                    if isPositionInField(monsterRoot.Position, field, 20) then
                        if not SelectedViciousExcludedFields[field.Name] then
                            return "Monster", monster, monsterRoot, field, level
                        end
                    end
                end
                return "Monster", monster, monsterRoot, nil, level
            end
        end
    end

    local possibleFolders = {
        workspace:FindFirstChild("Particles"),
        workspace:FindFirstChild("Spikes"),
        workspace:FindFirstChild("NPCBees"),
        MonstersFolder,
        FieldsFolder,
    }

    for _, folder in ipairs(possibleFolders) do
        if folder then
            for _, item in ipairs(folder:GetDescendants()) do
                if item:IsA("BasePart") then
                    local name = string.lower(item.Name)
                    local isThorn = false

                    if name == "thorn" or name == "vicious_thorn" or name == "viciousthorn" or name == "sharp" then
                        isThorn = true
                    elseif item:FindFirstChildWhichIsA("SpecialMesh") then
                        local sm = item:FindFirstChildWhichIsA("SpecialMesh")
                        if string.find(tostring(sm.MeshId), "1033714") then
                            isThorn = true
                        end
                    end

                    if isThorn then
                        for _, field in ipairs(FieldsFolder:GetChildren()) do
                            if isPositionInField(item.Position, field, 10) then
                                if not SelectedViciousExcludedFields[field.Name] then
                                    return "Thorn", item, item, field, 1
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return nil, nil, nil, nil, 0
end

local function findSafeCombatPosition(vPart, vField, dangerZones, currentPos)
    local bestPos = nil
    local bestSafetyScore = -math.huge
    local baseY = (vField and vField.Position.Y or vPart.Position.Y) + 4

    for radius = 12, 24, 4 do
        for i = 0, 15 do
            local angle = (i / 16) * math.pi * 2
            local candPos = Vector3.new(
                vPart.Position.X + math.cos(angle) * radius,
                baseY,
                vPart.Position.Z + math.sin(angle) * radius
            )

            local inFieldBounds = not vField or isPositionInField(candPos, vField, 0)
            if inFieldBounds then
                local minClearance = 9999
                for _, zone in ipairs(dangerZones) do
                    local d = (Vector2.new(candPos.X, candPos.Z) - Vector2.new(zone.Position.X, zone.Position.Z)).Magnitude - zone.Radius
                    if d < minClearance then
                        minClearance = d
                    end
                end

                if minClearance > 6 then
                    local distToMe = (candPos - currentPos).Magnitude
                    local safetyScore = minClearance * 10 - distToMe
                    if safetyScore > bestSafetyScore then
                        bestSafetyScore = safetyScore
                        bestPos = candPos
                    end
                end
            end
        end
    end

    if bestPos then
        return bestPos
    end

    if vField then
        local fieldPos = vField.Position
        local fieldSize = vField.Size
        for _ = 1, 20 do
            local candPos = Vector3.new(
                fieldPos.X + (math.random() - 0.5) * fieldSize.X * 0.8,
                baseY,
                fieldPos.Z + (math.random() - 0.5) * fieldSize.Z * 0.8
            )
            local inDanger = isPositionInDangerZone(candPos, dangerZones, 6)
            if not inDanger then
                return candPos
            end
        end
    end

    local awayDir = Vector2.new(1, 0)
    if #dangerZones > 0 then
        local nearestZone = dangerZones[1]
        awayDir = (Vector2.new(currentPos.X, currentPos.Z) - Vector2.new(nearestZone.Position.X, nearestZone.Position.Z)).Unit
        if awayDir.Magnitude == 0 then awayDir = Vector2.new(1, 0) end
    end
    return Vector3.new(
        currentPos.X + awayDir.X * 25,
        baseY,
        currentPos.Z + awayDir.Y * 25
    )
end

local function runViciousBeeCombatStep(root, humanoid, runId)
    local vType, vObj, vPart, vField, vLevel = findActiveViciousBee()
    if not vType or not vPart or not root or not humanoid or humanoid.Health <= 0 then
        return nil
    end

    if humanoid.Health < 35 and vField then
        local retreatPos = vField.Position + Vector3.new(0, 18, 0)
        tweenToFieldTarget(vField, root, humanoid, runId, retreatPos, nil)
        return vField.Name
    end

    local dangerZones = getActiveDangerZones()

    if vType == "Thorn" then
        local thornPos = vPart.Position + Vector3.new(0, 3, 0)
        tweenCharacterTo(root, humanoid, thornPos)
        task.wait(0.2)
        return vField and vField.Name or "ViciousThorn"
    end

    safeStartCollection()

    local inDanger = isPositionInDangerZone(root.Position, dangerZones, 6)
    if inDanger then
        local safePos = findSafeCombatPosition(vPart, vField, dangerZones, root.Position)
        tweenToFieldTarget(vField or workspace, root, humanoid, runId, safePos, nil)
        return vField and vField.Name or "ViciousBee"
    end

    local bestToken = nil
    local bestScore = math.huge
    if vField then
        for _, collectible in ipairs(CollectiblesFolder:GetChildren()) do
            local tokenPart = getTokenPart(collectible)
            if tokenPart and tokenPart.Parent and tokenPart.Transparency < 0.8
                and isTokenInField(tokenPart, vField) then
                local inD = isPositionInDangerZone(tokenPart.Position, dangerZones, 6)
                if not inD then
                    local dist = (tokenPart.Position - root.Position).Magnitude
                    local mult = getTokenPriorityMultiplier(tokenPart)
                    local score = dist * mult
                    if score < bestScore then
                        bestToken = tokenPart
                        bestScore = score
                    end
                end
            end
        end
    end

    if bestToken then
        local targetPos = Vector3.new(bestToken.Position.X, (vField and vField.Position.Y or bestToken.Position.Y) + 3.5, bestToken.Position.Z)
        tweenToFieldTarget(vField or workspace, root, humanoid, runId, targetPos, bestToken)
        return vField and vField.Name or "ViciousBee"
    end

    local safeCombatPos = findSafeCombatPosition(vPart, vField, dangerZones, root.Position)
    tweenToFieldTarget(vField or workspace, root, humanoid, runId, safeCombatPos, nil)
    return vField and vField.Name or "ViciousBee"
end

-- =========================================================================
-- Sprouts System
-- =========================================================================
local function getInventoryBeanCount()
    local count = 0
    pcall(function()
        local statCacheMod = ReplicatedStorage:FindFirstChild("ClientStatCache")
        local cache = statCacheMod and require(statCacheMod):Get()
        if cache and cache.Eggs then
            count = cache.Eggs["MagicBean"] or cache.Eggs["Magic Bean"] or 0
        end
    end)
    return count
end

local function getSproutInfo(sprout)
    local sproutPart = sprout:IsA("BasePart") and sprout or sprout:FindFirstChildWhichIsA("BasePart", true)
    local rarity = "Common"

    local typeVal = sprout:GetAttribute("Type") or sprout:GetAttribute("Rarity") or (sprout:FindFirstChild("Type") and sprout.Type.Value)
    if typeVal then
        rarity = tostring(typeVal)
    else
        for _, desc in ipairs(sprout:GetDescendants()) do
            if desc:IsA("TextLabel") or desc:IsA("TextButton") then
                local txt = string.lower(desc.Text)
                if string.find(txt, "supreme") then rarity = "Supreme"; break
                elseif string.find(txt, "gummy") then rarity = "Gummy"; break
                elseif string.find(txt, "moon") then rarity = "Moon"; break
                elseif string.find(txt, "festive") then rarity = "Festive"; break
                elseif string.find(txt, "legendary") then rarity = "Legendary"; break
                elseif string.find(txt, "epic") then rarity = "Epic"; break
                elseif string.find(txt, "rare") then rarity = "Rare"; break
                elseif string.find(txt, "common") then rarity = "Common"; break
                end
            end
        end
    end

    local lowerName = string.lower(sprout.Name)
    if string.find(lowerName, "supreme") then rarity = "Supreme"
    elseif string.find(lowerName, "gummy") then rarity = "Gummy"
    elseif string.find(lowerName, "moon") then rarity = "Moon"
    elseif string.find(lowerName, "festive") then rarity = "Festive"
    elseif string.find(lowerName, "legendary") then rarity = "Legendary"
    elseif string.find(lowerName, "epic") then rarity = "Epic"
    elseif string.find(lowerName, "rare") then rarity = "Rare"
    end

    local matchedField = nil
    if sproutPart then
        for _, field in ipairs(FieldsFolder:GetChildren()) do
            if isPositionInField(sproutPart.Position, field, 12) then
                matchedField = field
                break
            end
        end
    end

    return matchedField, sproutPart, rarity
end

local function getActiveSproutField()
    local sproutsFolder = workspace:FindFirstChild("Sprouts")
    if not sproutsFolder or #sproutsFolder:GetChildren() == 0 then
        return nil, nil, nil
    end

    for _, sprout in ipairs(sproutsFolder:GetChildren()) do
        local field, sproutPart, rarity = getSproutInfo(sprout)
        if field and sproutPart then
            if not SelectedSproutExcludedFields[field.Name] and SelectedSproutRarities[rarity] ~= false then
                return field, sproutPart, rarity
            end
        elseif sproutPart and SelectedSproutRarities[rarity] ~= false then
            return nil, sproutPart, rarity
        end
    end
    return nil, nil, nil
end

-- =========================================================================
-- Field Fallback / Selection Resolver
-- =========================================================================
local fieldNames = {}
local excludedFields = {
    ["Red Brick Field"] = true,
    ["White Brick Field"] = true,
    ["Blue Brick Field"] = true,
}

for _, field in ipairs(FieldsFolder:GetChildren()) do
    if not excludedFields[field.Name] then
        table.insert(fieldNames, {Name = field.Name})
    end
end
table.sort(fieldNames, function(a, b) return a.Name < b.Name end)

local function resolveFarmField()
    if SelectedFarmField and FieldsFolder:FindFirstChild(SelectedFarmField) then
        return FieldsFolder:FindFirstChild(SelectedFarmField)
    end
    local farmListObj = Hub.GetItemFromList and Hub.GetItemFromList("Select Farm", mainPage, false)
    local selectedItem = farmListObj and (farmListObj.SelectedItem or (farmListObj.BringSelected and farmListObj:BringSelected()))
    local selectedName = type(selectedItem) == "table" and (selectedItem.Name or selectedItem[1]) or selectedItem
    if selectedName and FieldsFolder:FindFirstChild(selectedName) then
        SelectedFarmField = selectedName
        return FieldsFolder:FindFirstChild(selectedName)
    end
    if #fieldNames > 0 and FieldsFolder:FindFirstChild(fieldNames[1].Name) then
        SelectedFarmField = fieldNames[1].Name
        return FieldsFolder:FindFirstChild(fieldNames[1].Name)
    end
    return nil
end

-- =========================================================================
-- Memory Match Engine (Ghost Memory Match, Needed Items & Auto Solver)
-- =========================================================================
local function normalizePrizeName(data)
    if not data then return "Unknown" end
    if type(data) == "string" then return data end
    if type(data) == "table" then
        if data.Name then return tostring(data.Name) end
        if data.Type then return tostring(data.Type) end
        if data.Prize then
            if type(data.Prize) == "string" then return data.Prize end
            if type(data.Prize) == "table" then
                return tostring(data.Prize.Type or data.Prize.Name or "Unknown")
            end
        end
    end
    return "Unknown"
end

local function isNeededItem(prizeName)
    if not prizeName then return false end
    local clean = string.lower(tostring(prizeName)):gsub("%s+", ""):gsub("%d+", "")
    for neededName, enabled in pairs(SelectedNeededItems) do
        if enabled then
            local cleanNeeded = string.lower(neededName):gsub("%s+", ""):gsub("%d+", "")
            if string.find(clean, cleanNeeded) or string.find(cleanNeeded, clean) then
                return true
            end
        end
    end
    return false
end

local function isMemoryMatchReady(toyName)
    local toyData = MemoryMatchToys[toyName]
    local defaultCd = toyData and toyData.cooldown or 7200
    local now = os.time()

    -- 1. Session cooldowns & failure backoffs
    if toyCooldownEndTimes[toyName] and now < toyCooldownEndTimes[toyName] then
        return false
    end
    if toyAttemptBackoffs[toyName] and now < toyAttemptBackoffs[toyName] then
        return false
    end

    -- 2. Check ClientStatCache.ToyTimes (BSS native cooldown tracking)
    local onCooldown = false
    pcall(function()
        local statCacheMod = ReplicatedStorage:FindFirstChild("ClientStatCache")
        if not statCacheMod then return end
        local cache = require(statCacheMod):Get()
        if not cache then return end

        local toyTimes = cache.ToyTimes or {}
        local lastTime = toyTimes[toyName] or 0

        local osTime = now
        local OsTimeMod = ReplicatedStorage:FindFirstChild("OsTime")
        if OsTimeMod then
            pcall(function() osTime = math.floor(require(OsTimeMod)()) end)
        end

        local toyModel = workspace:FindFirstChild("Toys") and workspace.Toys:FindFirstChild(toyName)
        local cdVal = (toyModel and toyModel:FindFirstChild("Cooldown") and toyModel.Cooldown.Value) or defaultCd

        local elapsed = osTime - lastTime
        if elapsed < cdVal then
            local left = cdVal - elapsed
            toyCooldownEndTimes[toyName] = now + left
            onCooldown = true
        end
    end)
    if onCooldown then
        return false
    end

    -- 3. Check 3D SurfaceGui text if available (countdown timer has colons like 01:23:45 or 45:20)
    local toyModel = workspace:FindFirstChild("Toys") and workspace.Toys:FindFirstChild(toyName)
    if toyModel then
        local circle = toyModel:FindFirstChild("Platform") and toyModel.Platform:FindFirstChild("Circle")
        local textLabel = circle and circle:FindFirstChild("SurfaceGui") and circle.SurfaceGui:FindFirstChild("TextLabel")
        if textLabel and textLabel.Text then
            local txt = textLabel.Text
            if string.find(txt, ":") then
                local secLeft = 0
                for part in string.gmatch(txt, "%d+") do
                    secLeft = (secLeft * 60) + (tonumber(part) or 0)
                end
                toyCooldownEndTimes[toyName] = now + (secLeft > 0 and secLeft or 60)
                return false
            end
        end
    end

    return true
end

local function getToyPlatformPosition(toyName)
    local toy = workspace:FindFirstChild("Toys") and workspace.Toys:FindFirstChild(toyName)
    if toy then
        local platform = toy:FindFirstChild("Platform")
        if platform then
            local circle = platform:FindFirstChild("Circle")
            if circle then
                return circle.Position + Vector3.new(0, 4, 0)
            end
            return platform.Position + Vector3.new(0, 4, 0)
        end
        local pivot = toy:GetPivot()
        return pivot.Position + Vector3.new(0, 4, 0)
    end
    return MemoryMatchToys[toyName] and MemoryMatchToys[toyName].pos
end

local function activateMemoryMatchToy(toyName)
    pcall(function()
        local Events = ReplicatedStorage:FindFirstChild("Events")
        if Events and Events:FindFirstChild("ToyEvent") then
            Events.ToyEvent:FireServer(toyName)
        end
    end)
    pcall(function()
        local pGui = LocalPlayer:FindFirstChild("PlayerGui")
        local actBtn = pGui and pGui:FindFirstChild("ScreenGui") and pGui.ScreenGui:FindFirstChild("ActivateButton")
        if actBtn and actBtn.Visible then
            for _, conn in ipairs(getconnections and getconnections(actBtn.MouseButton1Click) or {}) do
                conn:Fire()
            end
        end
    end)
end

local function getActiveMemoryMatchGrid()
    local pGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not pGui then return nil, nil end
    local screenGui = pGui:FindFirstChild("ScreenGui")
    if not screenGui then return nil, nil end

    local minigameLayer = screenGui:FindFirstChild("MinigameLayer")
    if not minigameLayer or not minigameLayer.Visible then
        return nil, nil
    end

    local activeFrame = nil
    for _, child in ipairs(minigameLayer:GetChildren()) do
        if child.Name == "MemoryMatchFrame" and child:IsA("GuiObject") then
            if child.Visible and child.Position.Y.Scale < 0.9 then
                activeFrame = child
                break
            end
        end
    end

    if not activeFrame then
        return nil, nil
    end

    local slots = {}
    local guiGrid = activeFrame:FindFirstChild("GuiGrid")
    local innerGrid = guiGrid and (guiGrid:FindFirstChild("GuiGrid") or guiGrid)
    if innerGrid then
        for _, child in ipairs(innerGrid:GetChildren()) do
            if child.Name == "MemoryMatchGuiSlot" and child:IsA("GuiObject") then
                table.insert(slots, child)
            end
        end
    end

    return activeFrame, slots
end

local function applyGhostOverlay(tileIndex, prizeInfo)
    if not GhostMemoryMatchState or not prizeInfo then return end
    local activeFrame, slots = getActiveMemoryMatchGrid()
    local slotFrame = slots and slots[tileIndex]
    if slotFrame and slotFrame.Parent then
        local card = slotFrame:FindFirstChild("ObjCard", true)
        if card then
            local ghost = card:FindFirstChild("GhostPreview")
            if not ghost then
                ghost = Instance.new("ImageLabel")
                ghost.Name = "GhostPreview"
                ghost.Size = UDim2.new(0.75, 0, 0.75, 0)
                ghost.Position = UDim2.new(0.125, 0, 0.125, 0)
                ghost.BackgroundTransparency = 1
                ghost.ZIndex = (card.ZIndex or 1) + 5
                ghost.Parent = card
            end
            if prizeInfo.Image then
                ghost.Image = tostring(prizeInfo.Image)
                ghost.ImageTransparency = 0.35
                ghost.Visible = true
            end

            if isNeededItem(prizeInfo.Name) then
                local stroke = card:FindFirstChild("GhostStroke")
                if not stroke then
                    stroke = Instance.new("UIStroke")
                    stroke.Name = "GhostStroke"
                    stroke.Thickness = 2.5
                    stroke.Parent = card
                end
                stroke.Color = Color3.fromRGB(255, 205, 50)
                stroke.Transparency = 0.1
            end
        end
    end
end

local function clickMemoryMatchSlot(slotIndex, slotFrame)
    if not slotFrame or not slotFrame.Parent then return end

    local btn = slotFrame:FindFirstChild("ObjButton", true) or slotFrame:FindFirstChild("ObjCard", true)
    if btn then
        pcall(function()
            for _, conn in ipairs(getconnections and getconnections(btn.MouseButton1Click) or {}) do
                conn:Fire()
            end
        end)
    end

    pcall(function()
        local Events = ReplicatedStorage:FindFirstChild("Events")
        if Events and Events:FindFirstChild("MemoryMatchEvent") then
            Events.MemoryMatchEvent:FireServer({
                Action = "SelectTile",
                TileIndex = slotIndex
            })
        end
    end)
end

-- Hook MemoryMatchEvent
pcall(function()
    local Events = ReplicatedStorage:FindFirstChild("Events")
    local mmEvent = Events and Events:FindFirstChild("MemoryMatchEvent")
    if mmEvent then
        mmEvent.OnClientEvent:Connect(function(data)
            if type(data) ~= "table" then return end
            local action = data.Action

            if action == "Start" or action == "Init" then
                knownTiles = {}
                matchedTiles = {}
                isMemoryMatchActive = true
            elseif action == "RevealTile" then
                local idx = data.TileIndex
                if idx then
                    local pName = normalizePrizeName(data)
                    local img = data.Image or (data.Prize and data.Prize.Image)
                    knownTiles[idx] = {
                        Name = pName,
                        Image = img,
                        Prize = data.Prize
                    }
                    applyGhostOverlay(idx, knownTiles[idx])
                end
            elseif action == "Match" or action == "Matched" then
                if data.Tile1 then matchedTiles[data.Tile1] = true end
                if data.Tile2 then matchedTiles[data.Tile2] = true end
            elseif action == "RevealAll" or action == "EndGame" or action == "Finish" then
                isMemoryMatchActive = false
                task.delay(1.5, function()
                    knownTiles = {}
                    matchedTiles = {}
                end)
            end
        end)
    end
end)

local function playMemoryMatchTurn(pick1, pick2, slots)
    clickMemoryMatchSlot(pick1, slots[pick1])

    local t1 = time()
    while time() - t1 < 1.0 do
        if knownTiles[pick1] then break end
        task.wait(0.05)
    end
    task.wait(0.65)

    local actualPick2 = pick2
    local item1 = knownTiles[pick1]
    if item1 then
        for j = 1, #slots do
            if j ~= pick1 and knownTiles[j] and not matchedTiles[j] then
                local itemJ = knownTiles[j]
                if (item1.Image and itemJ.Image and item1.Image == itemJ.Image)
                    or (item1.Name and itemJ.Name and item1.Name == itemJ.Name and item1.Name ~= "Unknown") then
                    actualPick2 = j
                    break
                end
            end
        end
    end

    clickMemoryMatchSlot(actualPick2, slots[actualPick2])

    local t2 = time()
    while time() - t2 < 1.0 do
        if knownTiles[actualPick2] then break end
        task.wait(0.05)
    end
    task.wait(0.65)

    local item2 = knownTiles[actualPick2]
    local isMatch = false
    if item1 and item2 then
        if (item1.Image and item2.Image and item1.Image == item2.Image)
            or (item1.Name and item2.Name and item1.Name == item2.Name and item1.Name ~= "Unknown") then
            isMatch = true
        end
    end

    if isMatch then
        matchedTiles[pick1] = true
        matchedTiles[actualPick2] = true
        task.wait(1.2)
    else
        task.wait(1.8)
    end
end

local function solveActiveMemoryMatch()
    local startTime = os.time()

    local activeFrame, slots = nil, nil
    for _ = 1, 10 do
        activeFrame, slots = getActiveMemoryMatchGrid()
        if activeFrame and #slots >= 16 then break end
        task.wait(0.5)
    end

    if not activeFrame or #slots < 16 then
        return
    end

    local totalTiles = #slots

    while (os.time() - startTime) < 120 do
        activeFrame, slots = getActiveMemoryMatchGrid()
        if not activeFrame or not activeFrame.Parent or not activeFrame.Visible or activeFrame.Position.Y.Scale > 0.9 then
            break
        end

        local chancesLbl = activeFrame:FindFirstChild("ChancesFrame") and activeFrame.ChancesFrame:FindFirstChild("CountLabel")
        if chancesLbl and chancesLbl.Text == "0" then
            task.wait(2)
            break
        end

        local pairA, pairB = nil, nil
        local pairIsNeeded = false

        for i = 1, totalTiles do
            if knownTiles[i] and not matchedTiles[i] then
                local itemA = knownTiles[i]
                for j = i + 1, totalTiles do
                    if knownTiles[j] and not matchedTiles[j] then
                        local itemB = knownTiles[j]
                        local matches = false
                        if itemA.Image and itemB.Image and itemA.Image == itemB.Image then
                            matches = true
                        elseif itemA.Name and itemB.Name and itemA.Name == itemB.Name and itemA.Name ~= "Unknown" then
                            matches = true
                        end

                        if matches then
                            if isNeededItem(itemA.Name) then
                                pairA = i
                                pairB = j
                                pairIsNeeded = true
                                break
                            elseif not pairA then
                                pairA = i
                                pairB = j
                            end
                        end
                    end
                end
                if pairIsNeeded then break end
            end
        end

        if pairA and pairB then
            playMemoryMatchTurn(pairA, pairB, slots)
        else
            local pick1 = nil
            for i = 1, totalTiles do
                if not knownTiles[i] and not matchedTiles[i] then
                    pick1 = i
                    break
                end
            end

            if not pick1 then
                for i = 1, totalTiles do
                    if not matchedTiles[i] then
                        pick1 = i
                        break
                    end
                end
            end

            if not pick1 then
                break
            end

            local pick2 = nil
            for j = 1, totalTiles do
                if j ~= pick1 and not knownTiles[j] and not matchedTiles[j] then
                    pick2 = j
                    break
                end
            end

            if not pick2 then
                for j = 1, totalTiles do
                    if j ~= pick1 and not matchedTiles[j] then
                        pick2 = j
                        break
                    end
                end
            end

            if not pick2 then
                break
            end

            playMemoryMatchTurn(pick1, pick2, slots)
        end

        task.wait(0.3)
    end
end

-- Auto Memory Match Background Supervisor
task.spawn(function()
    while true do
        task.wait(8)
        if AutoMemoryMatchState and not isRunningMemoryMatch and not isConvertingAtHive then
            local char, root, humanoid = getCharacter()
            if root and humanoid and humanoid.Health > 0 then
                local honeyVal = 0
                pcall(function()
                    local stats = LocalPlayer:FindFirstChild("CoreStats")
                    honeyVal = stats and stats:FindFirstChild("Honey") and stats.Honey.Value or 0
                end)

                for toyName, enabled in pairs(SelectedMemoryMatches) do
                    if enabled and AutoMemoryMatchState and not isConvertingAtHive then
                        local toyData = MemoryMatchToys[toyName]
                        if toyData and honeyVal >= toyData.cost then
                            if isMemoryMatchReady(toyName) then
                                local openedRemotely = false

                                -- Attempt 1: Remote Activation (Zero movement)
                                activateMemoryMatchToy(toyName)
                                task.wait(1.5)

                                local activeFrame, slots = getActiveMemoryMatchGrid()
                                if activeFrame and #slots >= 16 then
                                    openedRemotely = true
                                    isRunningMemoryMatch = true
                                    solveActiveMemoryMatch()
                                    task.wait(1.0)
                                    toyCooldownEndTimes[toyName] = os.time() + (toyData.cooldown or 7200)
                                    isRunningMemoryMatch = false
                                    task.wait(5)
                                    break
                                end

                                -- Attempt 2: If remote failed and not remote-only, travel to platform
                                if not openedRemotely and not RemoteOnlyMemoryMatch then
                                    local toyPos = getToyPlatformPosition(toyName)
                                    if toyPos then
                                        isRunningMemoryMatch = true
                                        local savedPos = root.Position

                                        tweenCharacterTo(root, humanoid, toyPos)
                                        task.wait(0.6)

                                        activateMemoryMatchToy(toyName)
                                        task.wait(1.8)

                                        local frameOnSite, siteSlots = getActiveMemoryMatchGrid()
                                        if frameOnSite and #siteSlots >= 16 then
                                            solveActiveMemoryMatch()
                                            task.wait(1.0)
                                            toyCooldownEndTimes[toyName] = os.time() + (toyData.cooldown or 7200)
                                        else
                                            -- Did not open on site; backoff 10 minutes to prevent repeat visits
                                            toyAttemptBackoffs[toyName] = os.time() + 600
                                        end

                                        -- Return safely to original farming position
                                        local c, r, h = getCharacter()
                                        if r and h then
                                            tweenCharacterTo(r, h, savedPos)
                                        end

                                        isRunningMemoryMatch = false
                                        task.wait(5)
                                        break
                                    end
                                else
                                    -- Remote attempt did not open and RemoteOnly is enabled
                                    toyAttemptBackoffs[toyName] = os.time() + 300
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- =========================================================================
-- UI Elements: Main Page Toggles & Sliders
-- =========================================================================
Hub.CreateSlider(mainPage, "Tween Speed", 4, 16, TweenSpeed, "x", function(value)
    TweenSpeed = value
end)

Hub.CreateToggle(mainPage, "Auto Farm", false, function(state)
    AutoFarmState = state
    farmRunId = farmRunId + 1
    local runId = farmRunId

    if not state then
        CombatState = false
        AutoViciousBeeState = false
        isConvertingAtHive = false
        if not AutoDigState then
            safeStopCollection()
        end
        releaseActiveTween()
        return
    end

    CombatState = CombatRequested
    AutoViciousBeeState = ViciousBeeRequested

    task.spawn(function()
        local currentFieldName = nil
        local previousCombatSelection = nil
        local sprinklersPlacedField = nil

        while AutoFarmState and runId == farmRunId do
            repeat
                if isRunningMemoryMatch then
                    task.wait(0.5)
                    break
                end

                local char, root, humanoid = getCharacter()
                if not char or not root or not humanoid then
                    task.wait(0.5)
                    break
                end

                local field = resolveFarmField()
                local selectedTypes = getSelectedMobTypes()
                local combatSelectionKey = table.concat(selectedTypes, "|")
                if combatSelectionKey ~= previousCombatSelection then
                    previousCombatSelection = combatSelectionKey
                    combatSpawnIndex = 1
                    combatTypeIndex = 1
                    combatTargetSeen = false
                    if CombatState then
                        currentFieldName = nil
                    end
                end

                local pollenVal, capVal, bagFull = getBagStats()

                if bagFull and not isConvertingAtHive then
                    local usedMicro = false
                    if SelectedFarmSettings["Auto Micro-Converters"] then
                        pcall(function()
                            local statCacheMod = ReplicatedStorage:FindFirstChild("ClientStatCache")
                            local cache = statCacheMod and require(statCacheMod):Get()
                            local microCount = cache and cache.Eggs and cache.Eggs["Micro-Converter"] or 0
                            if microCount > 0 then
                                local PlayerActivesMod = ReplicatedStorage:FindFirstChild("PlayerActives")
                                local PlayerActives = PlayerActivesMod and require(PlayerActivesMod)
                                local active = PlayerActives and (PlayerActives.Get("Micro-Converter") or PlayerActives.Get("MicroConverter"))
                                if active and type(active.ClientActivate) == "function" then
                                    active:ClientActivate(true)
                                    usedMicro = true
                                    task.wait(0.3)
                                end
                            end
                        end)
                    end

                    if not usedMicro then
                        isConvertingAtHive = true
                        convertStartTime = os.time()
                        safeStopCollection()
                        releaseActiveTween()
                    end
                end

                if isConvertingAtHive then
                    if pollenVal <= 0 or (os.time() - convertStartTime > 180) then
                        isConvertingAtHive = false
                        currentFieldName = nil
                        if AutoDigState then
                            safeStartCollection()
                        end
                    else
                        local hivePosition = getOwnHivePosition()
                        if hivePosition then
                            if currentFieldName ~= "__converting" or (root.Position - hivePosition).Magnitude > 8 then
                                currentFieldName = "__converting"
                                tweenCharacterTo(root, humanoid, hivePosition)
                            end
                            pcall(function()
                                local events = ReplicatedStorage:FindFirstChild("Events")
                                if events and events:FindFirstChild("PlayerHiveCommand") then
                                    events.PlayerHiveCommand:FireServer({Command = "MakeHoney"})
                                end
                            end)
                        else
                            isConvertingAtHive = false
                            currentFieldName = nil
                        end
                        task.wait(0.3)
                        break
                    end
                end

                -- Priority 1: Sprouts Handling
                local activeSproutField, activeSproutPart, activeRarity = nil, nil, nil
                if SelectedSproutActions["Auto Farm Sprouts"] or SelectedFarmSettings["Auto Farm Sprouts"] then
                    activeSproutField, activeSproutPart, activeRarity = getActiveSproutField()
                end

                if activeSproutField and root and humanoid then
                    if currentFieldName ~= activeSproutField.Name then
                        currentFieldName = activeSproutField.Name
                        sprinklersPlacedField = nil
                        tweenCharacterTo(root, humanoid, activeSproutField.Position + Vector3.new(0, 4, 0))
                    end
                    safeStartCollection()
                    farmFieldTargets(activeSproutField, root, humanoid, runId)
                    task.wait(0.02)
                    break
                end

                -- Priority 2: Vicious Bee Handling
                if AutoViciousBeeState and root and humanoid then
                    local vMarker = runViciousBeeCombatStep(root, humanoid, runId)
                    if vMarker then
                        currentFieldName = vMarker
                        task.wait(0.02)
                        break
                    end
                end

                -- Priority 3: Combat Mobs
                CombatState = CombatRequested and AutoFarmState
                if CombatState and #selectedTypes > 0 and root and humanoid then
                    currentFieldName = runCombatStep(root, humanoid, currentFieldName, runId)
                    task.wait(0.05)
                    break
                end

                -- Priority 4: Field Farming
                if field and root and humanoid and currentFieldName ~= field.Name then
                    currentFieldName = field.Name
                    sprinklersPlacedField = nil
                    tweenCharacterTo(root, humanoid, field.Position + Vector3.new(0, 4, 0))
                end

                if field and humanoid and currentFieldName == field.Name and AutoSprinklersState
                    and sprinklersPlacedField ~= field.Name then
                    sprinklersPlacedField = field.Name
                    placeSprinklersInField(field, humanoid, runId)
                end

                if SelectedSproutActions["Auto Plant Sprouts"] and field and root and isPositionInField(root.Position, field, 5) then
                    if not SelectedSproutExcludedFields[field.Name] then
                        local beansLeft = getInventoryBeanCount()
                        if beansLeft > StopWhenSproutsLeft then
                            local sproutsFolder = workspace:FindFirstChild("Sprouts")
                            if not sproutsFolder or #sproutsFolder:GetChildren() == 0 then
                                pcall(function()
                                    local PlayerActivesMod = ReplicatedStorage:FindFirstChild("PlayerActives")
                                    local PlayerActives = PlayerActivesMod and require(PlayerActivesMod)
                                    local bean = PlayerActives and (PlayerActives.Get("Magic Bean") or PlayerActives.Get("MagicBean"))
                                    if bean and type(bean.ClientActivate) == "function" then
                                        bean:ClientActivate(true)
                                        task.wait(0.5)
                                    end
                                end)
                            end
                        end
                    end
                end

                if field and root and humanoid and currentFieldName == field.Name and AutoFarmState and runId == farmRunId then
                    farmFieldTargets(field, root, humanoid, runId)
                end
            until true

            task.wait(0.02)
        end
    end)

    task.spawn(function()
        local lastJumpAt = 0

        while AutoFarmState and runId == farmRunId do
            if not isRunningMemoryMatch then
                local field = resolveFarmField()
                if CombatState then
                    local combatSpawn = getSelectedMobSpawns()[combatSpawnIndex]
                    field = combatSpawn and getCombatField(combatSpawn) or field
                end
                local char, root, humanoid = getCharacter()
                MobThreatActive = false

                if field and char and humanoid and root and isPositionInField(root.Position, field, 10) then
                    local shouldJump = time() - lastJumpAt >= 1.5
                    if jumpForOwnedFieldMob(field, char, humanoid, shouldJump) then
                        MobThreatActive = true
                        if shouldJump then
                            lastJumpAt = time()
                        end
                    end
                end
            end
            task.wait(0.15)
        end
    end)
end)

Hub.CreateToggle(mainPage, "Auto Dig", false, function(state)
    AutoDigState = state
    if state then
        safeStartCollection()
    else
        if not AutoFarmState then
            safeStopCollection()
        end
    end
end)

Hub.CreateToggle(mainPage, "Auto Sprinklers", false, function(state)
    AutoSprinklersState = state
end)

-- =========================================================================
-- Anti-Stuck & Void Recovery Watchdog
-- =========================================================================
task.spawn(function()
    local lastPos = nil
    local stuckCounter = 0

    while true do
        task.wait(2)
        if AutoFarmState and not isConvertingAtHive and not isRunningMemoryMatch then
            local char, root, hum = getCharacter()
            if root and hum then
                if root.Position.Y < -40 then
                    releaseActiveTween()
                    local hivePos = getOwnHivePosition()
                    local recoverPos = hivePos or Vector3.new(0, 20, 0)
                    root.CFrame = CFrame.new(recoverPos)
                    root.AssemblyLinearVelocity = Vector3.zero
                    task.wait(0.5)
                else
                    if lastPos and (root.Position - lastPos).Magnitude < 2.0 then
                        stuckCounter = stuckCounter + 1
                        if stuckCounter >= 6 then
                            stuckCounter = 0
                            releaseActiveTween()
                            hum.Jump = true
                            root.CFrame = root.CFrame + Vector3.new(0, 5, 0)
                            root.AssemblyLinearVelocity = Vector3.zero
                        end
                    else
                        stuckCounter = 0
                        lastPos = root.Position
                    end
                end
            end
        else
            stuckCounter = 0
            lastPos = nil
        end
    end
end)

-- =========================================================================
-- UI Elements: Main Page Lists & Hierarchies
-- =========================================================================

-- 1. Select Farm
local farmList = Hub.CreateList(mainPage, "Select Farm", fieldNames, 170, true)

-- 2. Token Customization
local tokenCustomizationList = Hub.CreateList(mainPage, "Token Customization", {}, 340, true)

-- 2a. Prioritize List
local prioritizeTokenNames = {
    "Baby Love",
    "Beam",
    "Blue Boost",
    "Bomb",
    "Bomb+",
    "Bubble",
    "Buzz Bomb",
    "Coconut",
    "Flame",
    "Focus",
    "Fuzzy Bomb",
    "Haste",
    "Honey Gift",
    "Impale",
    "Inspire",
    "Melody",
    "Micro-Converter",
    "Pollen Haze",
    "Rage",
    "Red Boost",
    "Scratch",
    "Sprout Loot",
    "Super Crit",
    "Surprise Party",
    "Tabby Love",
    "Target Mark",
    "Token Link",
    "Tornado",
    "Tree",
    "Triangulate",
}
table.sort(prioritizeTokenNames)

local prioritizeListItems = {}
for _, tokenName in ipairs(prioritizeTokenNames) do
    table.insert(prioritizeListItems, {Name = tokenName})
end
local prioritizeList = Hub.CreateList(tokenCustomizationList, "Prioritize List", prioritizeListItems, 210, true)

-- 2b. Exclude List
local tokenExclusionNames = {
    "Blueberries",
    "Gumdrops",
    "Honey",
    "Royal Jelly",
    "Strawberries",
    "Sunflower Seeds",
    "Treat",
}
table.sort(tokenExclusionNames)

local tokenExclusionItems = {}
for _, tokenName in ipairs(tokenExclusionNames) do
    table.insert(tokenExclusionItems, {Name = tokenName})
end
local farmConfigurationList = Hub.CreateList(tokenCustomizationList, "Exclude List", tokenExclusionItems, 140, true)

-- 3. Farm Features & Automation
local farmAutomationList = Hub.CreateList(mainPage, "Farm Features & Automation", {}, 330, true)

local farmSettingsNames = {
    "Auto Catch Coconuts",
    "Auto Farm Sprouts",
    "Auto Micro-Converters",
    "Farm Balloons",
    "Farm Bubbles",
    "Farm Flames",
    "Farm Fuzzy Bombs",
}
table.sort(farmSettingsNames)

local farmSettingsItems = {}
for _, settingName in ipairs(farmSettingsNames) do
    table.insert(farmSettingsItems, {Name = settingName})
end
local farmSettingsList = Hub.CreateList(farmAutomationList, "Farm Settings", farmSettingsItems, 170, true)

-- 4. Sprouts Automation
local sproutsAutomationList = Hub.CreateList(mainPage, "Sprouts Automation", {}, 350, true)

local sproutActionsNames = {
    "Auto Farm Sprouts",
    "Auto Plant Sprouts",
    "Auto Tween to Rare Drops",
    "Stop When Sprouts Left",
}
table.sort(sproutActionsNames)

local sproutActionsItems = {}
for _, actionName in ipairs(sproutActionsNames) do
    table.insert(sproutActionsItems, {Name = actionName})
end
local sproutActionsList = Hub.CreateList(sproutsAutomationList, "Sprout Actions", sproutActionsItems, 150, true)

local sproutRarityNames = {
    "Common",
    "Epic",
    "Festive",
    "Gummy",
    "Legendary",
    "Moon",
    "Rare",
    "Supreme",
}
table.sort(sproutRarityNames)

local sproutRarityItems = {}
for _, rarityName in ipairs(sproutRarityNames) do
    table.insert(sproutRarityItems, {Name = rarityName})
end
local sproutRaritiesList = Hub.CreateList(sproutsAutomationList, "Select Sprout Rarity", sproutRarityItems, 140, true)

local sproutExcludedFieldItems = {}
for _, field in ipairs(fieldNames) do
    table.insert(sproutExcludedFieldItems, {Name = field.Name})
end
table.sort(sproutExcludedFieldItems, function(a, b) return a.Name < b.Name end)
local sproutExcludedFieldsList = Hub.CreateList(sproutsAutomationList, "Excluded Fields", sproutExcludedFieldItems, 140, false)

-- =========================================================================
-- UI Elements: Combat Page
-- =========================================================================
Hub.CreateToggle(combatPage, "Kill Selected Mob", false, function(state)
    CombatRequested = state
    CombatState = state and AutoFarmState
    if not CombatState and not AutoDigState then
        safeStopCollection()
    end
end)

Hub.CreateToggle(combatPage, "Auto Vicious Bee", false, function(state)
    ViciousBeeRequested = state
    AutoViciousBeeState = state and AutoFarmState
end)

local viciousSettingsList = Hub.CreateList(combatPage, "Vicious Bee Settings", {}, 340, true)

Hub.CreateSlider(viciousSettingsList.List, "Min Level", 1, 20, MinViciousLevel, " Lvl", function(value)
    MinViciousLevel = math.floor(value)
end)

Hub.CreateSlider(viciousSettingsList.List, "Max Level", 1, 20, MaxViciousLevel, " Lvl", function(value)
    MaxViciousLevel = math.floor(value)
end)

local viciousExcludedFieldItems = {}
for _, field in ipairs(fieldNames) do
    table.insert(viciousExcludedFieldItems, {Name = field.Name})
end
table.sort(viciousExcludedFieldItems, function(a, b) return a.Name < b.Name end)
local viciousExcludedFieldsList = Hub.CreateList(viciousSettingsList, "Excluded Fields", viciousExcludedFieldItems, 160, false)

local mobNames = {}
local excludedMobTypes = {
    ["Cave Monster"] = true,
    ["Coconut Crab"] = true,
    ["Commando Chick"] = true,
    ["King Beetle"] = true,
    ["Stump Snail"] = true,
    ["Tunnel Bear"] = true,
}
local seenMobTypes = {}
for _, spawn in ipairs(MonsterSpawnersFolder:GetChildren()) do
    local monsterType = spawn:FindFirstChild("MonsterType")
    if monsterType and monsterType:IsA("StringValue") and not excludedMobTypes[monsterType.Value]
        and not seenMobTypes[monsterType.Value] then
        seenMobTypes[monsterType.Value] = true
        table.insert(mobNames, {Name = monsterType.Value})
    end
end
table.sort(mobNames, function(a, b) return a.Name < b.Name end)

combatList = Hub.CreateList(combatPage, "Select Mobs", mobNames, 180, true)

-- =========================================================================
-- UI Elements: Items Page (Memory Match Suite)
-- =========================================================================
Hub.CreateToggle(itemsPage, "Auto Memory Match", false, function(state)
    AutoMemoryMatchState = state
end)

Hub.CreateToggle(itemsPage, "Ghost Memory Match", true, function(state)
    GhostMemoryMatchState = state
end)

Hub.CreateToggle(itemsPage, "Remote Match Only", false, function(state)
    RemoteOnlyMemoryMatch = state
end)

local memoryMatchOptions = {
    "Memory Match",
    "Mega Memory Match",
    "Night Memory Match",
    "Extreme Memory Match",
}
local memoryMatchListItems = {}
for _, name in ipairs(memoryMatchOptions) do
    table.insert(memoryMatchListItems, {Name = name})
end
local memoryMatchList = Hub.CreateList(itemsPage, "Select Memory Matches", memoryMatchListItems, 160, true)

local neededItemOptions = {
    "Atomic Treat",
    "Bitterberry",
    "Blue Extract",
    "Cloud Vial",
    "Diamond Egg",
    "Enzymes",
    "Festive Bean",
    "Field Dice",
    "Glitter",
    "Glue",
    "Gold Egg",
    "Hard Wax",
    "Magic Bean",
    "Micro-Converter",
    "Moon Charm",
    "Mythic Egg",
    "Neonberry",
    "Night Bell",
    "Oil",
    "Red Extract",
    "Royal Jelly",
    "Silver Egg",
    "Smooth Dice",
    "Soft Wax",
    "Star Jelly",
    "Star Treat",
    "Super Smoothie",
    "Swirled Wax",
    "Ticket",
    "Tropical Drink",
}
table.sort(neededItemOptions)

local neededItemListItems = {}
for _, name in ipairs(neededItemOptions) do
    table.insert(neededItemListItems, {Name = name})
end
local neededItemsList = Hub.CreateList(itemsPage, "Needed Items (Priority)", neededItemListItems, 260, true)

-- =========================================================================
-- List Row Click & Input Event Bindings
-- =========================================================================
local selectedFarmRow = nil
local normalFarmColor = Color3.fromRGB(24, 28, 40)
local selectedFarmColor = Color3.fromRGB(42, 100, 60)

for _, entry in ipairs(farmList.Items or {}) do
    local row = entry.Row
    local fieldName = entry.Name or (entry.Data and entry.Data.Name)
    if row and row:IsA("TextButton") and fieldName then
        row.MouseButton1Click:Connect(function()
            if selectedFarmRow and selectedFarmRow.Parent then
                selectedFarmRow.BackgroundColor3 = normalFarmColor
            end
            selectedFarmRow = row
            row.BackgroundColor3 = selectedFarmColor
            SelectedFarmField = fieldName
        end)

        row.MouseLeave:Connect(function()
            if row == selectedFarmRow then
                row.BackgroundColor3 = selectedFarmColor
            end
        end)
    end
end

for _, entry in ipairs(prioritizeList.Items or {}) do
    local row = entry.Row
    local tokenName = entry.Name or (entry.Data and entry.Data.Name)
    if row and row:IsA("TextButton") and tokenName then
        local cb = row:FindFirstChild("Checkbox", true)
        if cb then
            cb.Visible = false
        end

        local currentRank = PriorityRanks[tokenName]
        row.BackgroundColor3 = currentRank and selectedFarmColor or normalFarmColor

        local input = Instance.new("TextBox")
        input.Name = "RankInput"
        input.AnchorPoint = Vector2.new(1, 0.5)
        input.Size = UDim2.new(0, 44, 0, 24)
        input.Position = UDim2.new(1, -10, 0.5, 0)
        input.BackgroundColor3 = Color3.fromRGB(14, 18, 28)
        input.TextColor3 = currentRank and Color3.fromRGB(255, 205, 50) or Color3.fromRGB(160, 175, 200)
        input.Font = Enum.Font.GothamBold
        input.TextSize = 12
        input.Text = currentRank and ("#" .. tostring(currentRank)) or "-"
        input.PlaceholderText = "#"
        input.PlaceholderColor3 = Color3.fromRGB(90, 105, 130)
        input.ClearTextOnFocus = false
        input.Parent = row

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = input

        local stroke = Instance.new("UIStroke")
        stroke.Color = currentRank and Color3.fromRGB(255, 180, 0) or Color3.fromRGB(44, 54, 76)
        stroke.Thickness = 1.2
        stroke.Parent = input

        local function updateRank(newRank)
            if newRank and newRank > 0 then
                PriorityRanks[tokenName] = newRank
                input.Text = "#" .. tostring(newRank)
                input.TextColor3 = Color3.fromRGB(255, 205, 50)
                stroke.Color = Color3.fromRGB(255, 180, 0)
                row.BackgroundColor3 = selectedFarmColor
            else
                PriorityRanks[tokenName] = nil
                input.Text = "-"
                input.TextColor3 = Color3.fromRGB(160, 175, 200)
                stroke.Color = Color3.fromRGB(44, 54, 76)
                row.BackgroundColor3 = normalFarmColor
            end
        end

        input.FocusLost:Connect(function()
            local text = input.Text
            local digits = string.match(text, "%d+")
            local num = tonumber(digits)
            if num and num > 0 then
                updateRank(num)
            else
                updateRank(nil)
            end
        end)

        row.MouseButton1Click:Connect(function()
            local r = PriorityRanks[tokenName]
            if not r then
                updateRank(1)
            elseif r < 5 then
                updateRank(r + 1)
            else
                updateRank(nil)
            end
        end)
    end
end

for _, entry in ipairs(farmSettingsList.Items or {}) do
    local row = entry.Row
    local settingName = entry.Name or (entry.Data and entry.Data.Name)
    if row and row:IsA("TextButton") and settingName then
        row.BackgroundColor3 = SelectedFarmSettings[settingName] and selectedFarmColor or normalFarmColor
        row.MouseButton1Click:Connect(function()
            SelectedFarmSettings[settingName] = not SelectedFarmSettings[settingName]
            if settingName == "Auto Farm Sprouts" then
                SelectedSproutActions["Auto Farm Sprouts"] = SelectedFarmSettings["Auto Farm Sprouts"]
                for _, actEntry in ipairs(sproutActionsList.Items or {}) do
                    if (actEntry.Name or (actEntry.Data and actEntry.Data.Name)) == "Auto Farm Sprouts" and actEntry.Row then
                        actEntry.Row.BackgroundColor3 = SelectedFarmSettings["Auto Farm Sprouts"] and selectedFarmColor or normalFarmColor
                    end
                end
            end
            row.BackgroundColor3 = SelectedFarmSettings[settingName] and selectedFarmColor or normalFarmColor
        end)
    end
end

for _, entry in ipairs(sproutActionsList.Items or {}) do
    local row = entry.Row
    local actionName = entry.Name or (entry.Data and entry.Data.Name)
    if row and row:IsA("TextButton") and actionName then
        if actionName == "Stop When Sprouts Left" then
            local cb = row:FindFirstChild("Checkbox", true)
            if cb then cb.Visible = false end

            local input = Instance.new("TextBox")
            input.Name = "ReserveInput"
            input.AnchorPoint = Vector2.new(1, 0.5)
            input.Size = UDim2.new(0, 48, 0, 24)
            input.Position = UDim2.new(1, -10, 0.5, 0)
            input.BackgroundColor3 = Color3.fromRGB(14, 18, 28)
            input.TextColor3 = Color3.fromRGB(255, 205, 50)
            input.Font = Enum.Font.GothamBold
            input.TextSize = 12
            input.Text = tostring(StopWhenSproutsLeft)
            input.PlaceholderText = "0"
            input.PlaceholderColor3 = Color3.fromRGB(90, 105, 130)
            input.ClearTextOnFocus = false
            input.Parent = row

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 6)
            corner.Parent = input

            local stroke = Instance.new("UIStroke")
            stroke.Color = Color3.fromRGB(44, 54, 76)
            stroke.Thickness = 1.2
            stroke.Parent = input

            input.FocusLost:Connect(function()
                local text = input.Text
                local digits = string.match(text, "%d+")
                local num = tonumber(digits) or 0
                StopWhenSproutsLeft = num
                input.Text = tostring(num)
            end)
        else
            row.BackgroundColor3 = SelectedSproutActions[actionName] and selectedFarmColor or normalFarmColor
            row.MouseButton1Click:Connect(function()
                SelectedSproutActions[actionName] = not SelectedSproutActions[actionName]
                if actionName == "Auto Farm Sprouts" then
                    SelectedFarmSettings["Auto Farm Sprouts"] = SelectedSproutActions["Auto Farm Sprouts"]
                    for _, farmEntry in ipairs(farmSettingsList.Items or {}) do
                        if (farmEntry.Name or (farmEntry.Data and farmEntry.Data.Name)) == "Auto Farm Sprouts" and farmEntry.Row then
                            farmEntry.Row.BackgroundColor3 = SelectedSproutActions["Auto Farm Sprouts"] and selectedFarmColor or normalFarmColor
                        end
                    end
                end
                row.BackgroundColor3 = SelectedSproutActions[actionName] and selectedFarmColor or normalFarmColor
            end)
        end
    end
end

for _, entry in ipairs(sproutRaritiesList.Items or {}) do
    local row = entry.Row
    local rarityName = entry.Name or (entry.Data and entry.Data.Name)
    if row and row:IsA("TextButton") and rarityName then
        row.BackgroundColor3 = SelectedSproutRarities[rarityName] and selectedFarmColor or normalFarmColor
        row.MouseButton1Click:Connect(function()
            SelectedSproutRarities[rarityName] = not SelectedSproutRarities[rarityName]
            row.BackgroundColor3 = SelectedSproutRarities[rarityName] and selectedFarmColor or normalFarmColor
        end)
    end
end

for _, entry in ipairs(sproutExcludedFieldsList.Items or {}) do
    local row = entry.Row
    local fieldName = entry.Name or (entry.Data and entry.Data.Name)
    if row and row:IsA("TextButton") and fieldName then
        row.BackgroundColor3 = SelectedSproutExcludedFields[fieldName] and selectedFarmColor or normalFarmColor
        row.MouseButton1Click:Connect(function()
            SelectedSproutExcludedFields[fieldName] = not SelectedSproutExcludedFields[fieldName]
            row.BackgroundColor3 = SelectedSproutExcludedFields[fieldName] and selectedFarmColor or normalFarmColor
        end)
    end
end

for _, entry in ipairs(farmConfigurationList.Items or {}) do
    local row = entry.Row
    local tokenName = entry.Name or (entry.Data and entry.Data.Name)
    if row and row:IsA("TextButton") and tokenName then
        row.MouseButton1Click:Connect(function()
            SelectedTokenExclusions[tokenName] = not SelectedTokenExclusions[tokenName]
            row.BackgroundColor3 = SelectedTokenExclusions[tokenName] and selectedFarmColor or normalFarmColor
        end)
    end
end

for _, entry in ipairs(combatList.Items or {}) do
    local row = entry.Row
    local mobName = entry.Name or (entry.Data and entry.Data.Name)
    if row and row:IsA("TextButton") and mobName then
        row.MouseButton1Click:Connect(function()
            SelectedMobTypes[mobName] = not SelectedMobTypes[mobName]
            row.BackgroundColor3 = SelectedMobTypes[mobName] and selectedFarmColor or normalFarmColor
        end)
    end
end

for _, entry in ipairs(viciousExcludedFieldsList.Items or {}) do
    local row = entry.Row
    local fieldName = entry.Name or (entry.Data and entry.Data.Name)
    if row and row:IsA("TextButton") and fieldName then
        row.BackgroundColor3 = SelectedViciousExcludedFields[fieldName] and selectedFarmColor or normalFarmColor
        row.MouseButton1Click:Connect(function()
            SelectedViciousExcludedFields[fieldName] = not SelectedViciousExcludedFields[fieldName]
            row.BackgroundColor3 = SelectedViciousExcludedFields[fieldName] and selectedFarmColor or normalFarmColor
        end)
    end
end

-- Memory Match & Needed Items row click handlers
for _, entry in ipairs(memoryMatchList.Items or {}) do
    local row = entry.Row
    local mmName = entry.Name or (entry.Data and entry.Data.Name)
    if row and row:IsA("TextButton") and mmName then
        row.BackgroundColor3 = SelectedMemoryMatches[mmName] and selectedFarmColor or normalFarmColor
        row.MouseButton1Click:Connect(function()
            SelectedMemoryMatches[mmName] = not SelectedMemoryMatches[mmName]
            row.BackgroundColor3 = SelectedMemoryMatches[mmName] and selectedFarmColor or normalFarmColor
        end)
    end
end

for _, entry in ipairs(neededItemsList.Items or {}) do
    local row = entry.Row
    local itemName = entry.Name or (entry.Data and entry.Data.Name)
    if row and row:IsA("TextButton") and itemName then
        row.BackgroundColor3 = SelectedNeededItems[itemName] and selectedFarmColor or normalFarmColor
        row.MouseButton1Click:Connect(function()
            SelectedNeededItems[itemName] = not SelectedNeededItems[itemName]
            row.BackgroundColor3 = SelectedNeededItems[itemName] and selectedFarmColor or normalFarmColor
        end)
    end
end
