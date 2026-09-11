local LIBRARY_LINK = "https://raw.githubusercontent.com/UnknownHQ/UnknownHub/main/UnknownLibrary"
local LIBRARY_NAME = "ENI_TabbedHub_UI"

local function destroyOldGui()
    local parents = {game:GetService("CoreGui")}
    if gethui then pcall(function() table.insert(parents, gethui()) end) end
    local playerGui = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
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
    title = "OLESHKA HUB",
    parent = (gethui and gethui()) or game:GetService("CoreGui") or game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"),
    theme = Color3.fromRGB(255, 155, 0),
})

assert(type(Hub) == "table", "UnknownLibrary returned an invalid hub")
assert(type(Hub.CreateButton) == "function", "UnknownLibrary is missing CreateButton")
assert(type(Hub.CreateToggle) == "function", "UnknownLibrary is missing CreateToggle")
assert(type(Hub.CreateList) == "function", "UnknownLibrary is missing CreateList")
assert(type(Hub.createTabButton) == "function", "UnknownLibrary is missing createTabButton")

local mainPage = Hub.createTabButton("Main", "Main", "rbxassetid://10723407389", true)
local combatPage = Hub.createTabButton("Combat", "Combat", "rbxassetid://10723407390", false)
local AutoFarmState = false
local AutoDigState = false
local AutoSprinklersState = false
local CombatState = false
local SelectedMobName
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
local combatList
local combatSpawnIndex = 1
local combatTypeIndex = 1
local combatTargetSeen = false
local farmRunId = 0
local activeTween
local activeRoot
local activeHumanoid
local activeRootAnchored
local activeAutoRotate
local blockedTokens = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectorsFolder = ReplicatedStorage:WaitForChild("Collectors")
local LocalCollect = require(CollectorsFolder:WaitForChild("LocalCollect"))
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local FieldsFolder = workspace:WaitForChild("FlowerZones")
local CollectiblesFolder = workspace:WaitForChild("Collectibles")
local MonstersFolder = workspace:WaitForChild("Monsters")
local MonsterSpawnersFolder = workspace:WaitForChild("MonsterSpawners")
local HoneycombsFolder = workspace:WaitForChild("Honeycombs")
local HoneyTokenTexture = "rbxassetid://1472135114"
local Sprinklers = require(ReplicatedStorage:WaitForChild("Sprinklers"))

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
    for _, child in ipairs(tokenPart:GetChildren()) do
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

local function releaseActiveTween()
    if activeTween then
        activeTween:Cancel()
        activeTween = nil
    end

    if activeRoot and activeRoot.Parent then
        activeRoot.Anchored = activeRootAnchored == true
    end
    if activeHumanoid and activeHumanoid.Parent then
        activeHumanoid.AutoRotate = activeAutoRotate ~= false
    end

    activeRoot = nil
    activeHumanoid = nil
    activeRootAnchored = nil
    activeAutoRotate = nil
end

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

local function tweenCharacterTo(root, humanoid, destination, speedMultiplier)
    releaseActiveTween()
    if not root or not root.Parent or not humanoid or not humanoid.Parent then
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
    if not AutoFarmState or runId ~= farmRunId or not root or not root.Parent or not humanoid or not humanoid.Parent then
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
    while AutoFarmState and runId == farmRunId and root.Parent and time() < deadline and activeTween == tween do
        if MobThreatActive then
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
    for _, child in ipairs(tokenPart:GetChildren()) do
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
    for _, child in ipairs(tokenPart:GetChildren()) do
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

local function findNearestFieldTarget(field, root)
    local nearestTarget
    local nearestTargetPos
    local nearestScore = math.huge
    local now = time()

    -- 1. Auto Catch Coconuts (falling coconuts or coconut parts in field)
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

    -- 2. Collectibles (Tokens, Token Links, Fuzzy Bombs, Sprout Tokens, Abilities, Rare Drops)
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
                multiplier = 0.005 -- Highest priority: instantly rush to rare drop in field
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

    -- 3. Farm Flames (Demon mask / fire buffs)
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

    -- 4. Farm Bubbles (Tadpole / Bubble wand bubbles)
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

    -- 5. Farm Balloons (Under-balloon aura/pollen)
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
    local player = Players.LocalPlayer
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

local function getOwnHivePosition()
    local player = Players.LocalPlayer
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

local function isBagFull()
    local stats = Players.LocalPlayer:FindFirstChild("CoreStats")
    local pollen = stats and stats:FindFirstChild("Pollen")
    local capacity = stats and stats:FindFirstChild("Capacity")
    return pollen and capacity and pollen.Value >= capacity.Value, pollen
end

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

    local statCacheMod = ReplicatedStorage:FindFirstChild("ClientStatCache")
    local cache = statCacheMod and require(statCacheMod):Get()
    local equippedType = cache and cache.EquippedSprinkler
    local sprinklerCount = equippedType and Sprinklers.GetStat(equippedType, "Count") or 1
    local sprinklerRadius = equippedType and Sprinklers.GetStat(equippedType, "Radius") or 12
    local builderCount = cache and cache.Eggs and cache.Eggs.SprinklerBuilder or 0

    if not equippedType or equippedType == "None" or builderCount <= 0 then
        return
    end

    local PlayerActivesMod = ReplicatedStorage:FindFirstChild("PlayerActives")
    local PlayerActives = PlayerActivesMod and require(PlayerActivesMod)
    local EventsMod = ReplicatedStorage:FindFirstChild("Events")
    local Events = EventsMod and require(EventsMod)
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
        if Events and type(Events.ClientCall) == "function" then
            pcall(function() Events.ClientCall("PlayerActivesCommand", {Name = "Sprinkler Builder"}) end)
            pcall(function() Events.ClientCall("PlayerActivesCommand", {Name = "SprinklerBuilder"}) end)
        end
        if EventsFolder and EventsFolder:FindFirstChild("PlayerActivesCommand") then
            pcall(function() EventsFolder.PlayerActivesCommand:FireServer({Name = "Sprinkler Builder"}) end)
            pcall(function() EventsFolder.PlayerActivesCommand:FireServer({Name = "SprinklerBuilder"}) end)
        end
        task.wait(0.2)
    end
end

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
    SelectedMobName = selectedTypes[combatTypeIndex]
    if not SelectedMobName then
        return nil
    end
    local spawns = getSelectedMobSpawns()
    local spawn = spawns[combatSpawnIndex]
    if not spawn then
        return nil
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
        LocalCollect.StartCollection()

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
    elseif combatTargetSeen then
        combatTargetSeen = false
        if combatSpawnIndex >= #spawns then
            combatSpawnIndex = 1
            combatTypeIndex = combatTypeIndex % #selectedTypes + 1
        else
            combatSpawnIndex = combatSpawnIndex + 1
        end
        return nil
    end
    return currentMarker
end

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
    -- 1. Check workspace.Monsters
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

    -- 2. Check for sharp Thorn in fields
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

    -- Sample candidate positions in multiple rings (radii 12, 16, 20, 24) and 16 angles
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

    -- Fallback: if all immediate ring spots are dangerous, find safe position anywhere in field
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

    -- Retreat away from nearest danger
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
    if not vType or not vPart or not root or not humanoid then
        return nil
    end

    local dangerZones = getActiveDangerZones()

    -- Sharp Thorn: tween to thorn to trigger bee emergence
    if vType == "Thorn" then
        local thornPos = vPart.Position + Vector3.new(0, 3, 0)
        tweenCharacterTo(root, humanoid, thornPos)
        task.wait(0.2)
        return vField and vField.Name or "ViciousThorn"
    end

    -- Active Vicious Bee Monster
    LocalCollect.StartCollection()

    -- 1. If currently inside danger zone, evade immediately
    local inDanger = isPositionInDangerZone(root.Position, dangerZones, 6)
    if inDanger then
        local safePos = findSafeCombatPosition(vPart, vField, dangerZones, root.Position)
        tweenToFieldTarget(vField or workspace, root, humanoid, runId, safePos, nil)
        return vField and vField.Name or "ViciousBee"
    end

    -- 2. Pick safe combat tokens in field (Focus, Impale, Rage, Melody, Super Crit, Token Link) that are NOT in danger zones
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

    -- 3. Move to safe combat position around Vicious Bee avoiding danger zones
    local safeCombatPos = findSafeCombatPosition(vPart, vField, dangerZones, root.Position)
    tweenToFieldTarget(vField or workspace, root, humanoid, runId, safeCombatPos, nil)
    return vField and vField.Name or "ViciousBee"
end

local function getInventoryBeanCount()
    local statCacheMod = ReplicatedStorage:FindFirstChild("ClientStatCache")
    local cache = statCacheMod and require(statCacheMod):Get()
    if cache and cache.Eggs then
        return cache.Eggs["MagicBean"] or cache.Eggs["Magic Bean"] or 0
    end
    return 0
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

-- UI Elements: Main Page (Toggles & Sliders)
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
        if not AutoDigState then
            LocalCollect.StopCollection()
        end
        releaseActiveTween()
        return
    end

    CombatState = CombatRequested
    AutoViciousBeeState = ViciousBeeRequested

    task.spawn(function()
        local currentFieldName
        local previousCombatSelection
        local sprinklersPlacedField

        while AutoFarmState do
            repeat
                local farmList = Hub.GetItemFromList and Hub.GetItemFromList("Select Farm", mainPage, false)
                local selectedItem = farmList and (farmList.SelectedItem or (farmList.BringSelected and farmList:BringSelected()))
                local selectedName = type(selectedItem) == "table" and (selectedItem.Name or selectedItem[1]) or selectedItem

                if runId ~= farmRunId then
                    return
                end

                local field = selectedName and FieldsFolder:FindFirstChild(selectedName)
                local character = game:GetService("Players").LocalPlayer.Character
                local root = character and character:FindFirstChild("HumanoidRootPart")
                local humanoid = character and character:FindFirstChildOfClass("Humanoid")

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

                local bagFull = isBagFull()
                if bagFull and root and humanoid then
                    local usedMicro = false
                    if SelectedFarmSettings["Auto Micro-Converters"] then
                        local statCacheMod = ReplicatedStorage:FindFirstChild("ClientStatCache")
                        local cache = statCacheMod and require(statCacheMod):Get()
                        local microCount = cache and cache.Eggs and cache.Eggs["Micro-Converter"] or 0
                        if microCount > 0 then
                            local PlayerActivesMod = ReplicatedStorage:FindFirstChild("PlayerActives")
                            local PlayerActives = PlayerActivesMod and require(PlayerActivesMod)
                            local active = PlayerActives and (PlayerActives.Get("Micro-Converter") or PlayerActives.Get("MicroConverter"))
                            if active and type(active.ClientActivate) == "function" then
                                pcall(function() active:ClientActivate(true) end)
                                usedMicro = true
                                task.wait(0.3)
                            end
                        end
                    end

                    if not usedMicro then
                        if currentFieldName ~= "__converting" then
                            currentFieldName = "__converting"
                            LocalCollect.StopCollection()
                            local hivePosition = getOwnHivePosition()
                            if hivePosition then
                                tweenCharacterTo(root, humanoid, hivePosition)
                            else
                                currentFieldName = nil
                            end
                        end
                        task.wait(0.2)
                        break
                    end
                elseif currentFieldName == "__converting" then
                    currentFieldName = nil
                    if AutoDigState then
                        LocalCollect.StartCollection()
                    end
                end

                -- Priority 1: Sprouts Handling (Auto Farm Sprouts)
                local activeSproutField, activeSproutPart, activeRarity
                if SelectedSproutActions["Auto Farm Sprouts"] or SelectedFarmSettings["Auto Farm Sprouts"] then
                    activeSproutField, activeSproutPart, activeRarity = getActiveSproutField()
                end

                if activeSproutField and root and humanoid then
                    if currentFieldName ~= activeSproutField.Name then
                        currentFieldName = activeSproutField.Name
                        sprinklersPlacedField = nil
                        tweenCharacterTo(root, humanoid, activeSproutField.Position + Vector3.new(0, 4, 0))
                    end
                    LocalCollect.StartCollection()
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

                -- Priority 3: Field Farming
                if field and root and humanoid and currentFieldName ~= selectedName then
                    currentFieldName = selectedName
                    sprinklersPlacedField = nil
                    tweenCharacterTo(root, humanoid, field.Position + Vector3.new(0, 4, 0))
                end

                if field and humanoid and currentFieldName == selectedName and AutoSprinklersState
                    and sprinklersPlacedField ~= selectedName then
                    sprinklersPlacedField = selectedName
                    placeSprinklersInField(field, humanoid, runId)
                end

                -- Optional: Auto Plant Sprouts (Magic Beans)
                if SelectedSproutActions["Auto Plant Sprouts"] and field and root and isPositionInField(root.Position, field, 5) then
                    if not SelectedSproutExcludedFields[field.Name] then
                        local beansLeft = getInventoryBeanCount()
                        if beansLeft > StopWhenSproutsLeft then
                            local sproutsFolder = workspace:FindFirstChild("Sprouts")
                            if not sproutsFolder or #sproutsFolder:GetChildren() == 0 then
                                local PlayerActivesMod = ReplicatedStorage:FindFirstChild("PlayerActives")
                                local PlayerActives = PlayerActivesMod and require(PlayerActivesMod)
                                local bean = PlayerActives and (PlayerActives.Get("Magic Bean") or PlayerActives.Get("MagicBean"))
                                if bean and type(bean.ClientActivate) == "function" then
                                    pcall(function() bean:ClientActivate(true) end)
                                    task.wait(0.5)
                                end
                            end
                        end
                    end
                end

                if field and root and humanoid and currentFieldName == selectedName and AutoFarmState and runId == farmRunId then
                    farmFieldTargets(field, root, humanoid, runId)
                end
            until true

            task.wait(0.02)
        end
    end)

    task.spawn(function()
        local lastJumpAt = 0

        while AutoFarmState and runId == farmRunId do
            local farmList = Hub.GetItemFromList and Hub.GetItemFromList("Select Farm", mainPage, false)
            local selectedItem = farmList and (farmList.SelectedItem or (farmList.BringSelected and farmList:BringSelected()))
            local selectedName = type(selectedItem) == "table" and (selectedItem.Name or selectedItem[1]) or selectedItem
            local field = selectedName and FieldsFolder:FindFirstChild(selectedName)
            if CombatState then
                local combatSpawn = getSelectedMobSpawns()[combatSpawnIndex]
                field = combatSpawn and getCombatField(combatSpawn) or field
            end
            local character = Players.LocalPlayer.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            local root = character and character:FindFirstChild("HumanoidRootPart")
            MobThreatActive = false

            if field and character and humanoid and root and isPositionInField(root.Position, field, 10) then
                local shouldJump = time() - lastJumpAt >= 1.5
                if jumpForOwnedFieldMob(field, character, humanoid, shouldJump) then
                    MobThreatActive = true
                    if shouldJump then
                        lastJumpAt = time()
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
        LocalCollect.StartCollection()
    else
        LocalCollect.StopCollection()
    end
end)

Hub.CreateToggle(mainPage, "Auto Sprinklers", false, function(state)
    AutoSprinklersState = state
end)

-- UI Elements: Main Page (Lists - Nested Hierarchies & Sorted A-Z)

-- 1. Select Farm (Sorted A-Z)
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

local farmList = Hub.CreateList(mainPage, "Select Farm", fieldNames, 170, true)

-- 2. Token Customization (Parent list containing Prioritize List and Exclude List)
local tokenCustomizationList = Hub.CreateList(mainPage, "Token Customization", {}, 340, true)

-- 2a. Prioritize List (Sub-list with every single ability token, custom rank typing & click cycling)
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

-- 2b. Exclude List (Sub-list, Sorted A-Z)
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

-- 3. Farm Features & Automation (Parent list)
local farmAutomationList = Hub.CreateList(mainPage, "Farm Features & Automation", {}, 330, true)

-- 3a. Farm Settings (Sub-list, Sorted A-Z)
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

-- 4. Sprouts Automation (Parent list containing Sprout Actions, Rarity Selector, and Field Exclusions)
local sproutsAutomationList = Hub.CreateList(mainPage, "Sprouts Automation", {}, 350, true)

-- 4a. Sprout Actions (Sub-list, Sorted A-Z)
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

-- 4b. Select Sprout Rarity (Sub-list, Sorted A-Z)
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

-- 4c. Excluded Fields for Sprouts (Sub-list, Sorted A-Z)
local sproutExcludedFieldItems = {}
for _, field in ipairs(fieldNames) do
    table.insert(sproutExcludedFieldItems, {Name = field.Name})
end
table.sort(sproutExcludedFieldItems, function(a, b) return a.Name < b.Name end)
local sproutExcludedFieldsList = Hub.CreateList(sproutsAutomationList, "Excluded Fields", sproutExcludedFieldItems, 140, false)

-- UI Elements: Combat Page (Toggles first, then Lists)

Hub.CreateToggle(combatPage, "Kill Selected Mob", false, function(state)
    CombatRequested = state
    CombatState = state and AutoFarmState
    if not CombatState and not AutoDigState then
        LocalCollect.StopCollection()
    end
end)

Hub.CreateToggle(combatPage, "Auto Vicious Bee", false, function(state)
    ViciousBeeRequested = state
    AutoViciousBeeState = state and AutoFarmState
end)

-- Vicious Bee Settings (Parent List)
local viciousSettingsList = Hub.CreateList(combatPage, "Vicious Bee Settings", {}, 340, true)

-- ↳ Min & Max Level Sliders inside Vicious Bee Settings
Hub.CreateSlider(viciousSettingsList.List, "Min Level", 1, 20, MinViciousLevel, " Lvl", function(value)
    MinViciousLevel = math.floor(value)
end)

Hub.CreateSlider(viciousSettingsList.List, "Max Level", 1, 20, MaxViciousLevel, " Lvl", function(value)
    MaxViciousLevel = math.floor(value)
end)

-- ↳ Excluded Fields for Vicious Bee (Sub-list, Sorted A-Z)
local viciousExcludedFieldItems = {}
for _, field in ipairs(fieldNames) do
    table.insert(viciousExcludedFieldItems, {Name = field.Name})
end
table.sort(viciousExcludedFieldItems, function(a, b) return a.Name < b.Name end)
local viciousExcludedFieldsList = Hub.CreateList(viciousSettingsList, "Excluded Fields", viciousExcludedFieldItems, 160, false)

-- Select Mobs (Sorted A-Z)
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

-- List Row Click & Input Event Bindings

local selectedFarmRow
local normalFarmColor = Color3.fromRGB(24, 28, 40)
local selectedFarmColor = Color3.fromRGB(42, 100, 60)

for _, entry in ipairs(farmList.Items or {}) do
    local row = entry.Row
    if row and row:IsA("TextButton") then
        row.MouseButton1Click:Connect(function()
            if selectedFarmRow and selectedFarmRow.Parent then
                selectedFarmRow.BackgroundColor3 = normalFarmColor
            end
            selectedFarmRow = row
            row.BackgroundColor3 = selectedFarmColor
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
        -- Hide default checkbox to prevent overlapping bug
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

-- Sprout Actions row click & textbox handlers
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

-- Sprout Rarities row click handlers
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

-- Sprout Excluded Fields row click handlers
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

-- Vicious Bee Excluded Fields click handlers
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
