--[[
    ========================================================================
    Unknown Hub - +1 TNT Mining [Full Automation & Target Mining Engine]
    GUI Library: UnknownLibrary (Unknown Hub UI)
    ========================================================================
]]

local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')
local TweenService = game:GetService('TweenService')
local UserInputService = game:GetService('UserInputService')
local CoreGui = game:GetService('CoreGui')
local LocalPlayer = Players.LocalPlayer

local LIBRARY_LINK = 'https://raw.githubusercontent.com/UnknownHQ/UnknownHub/main/UnknownLibrary'
local LIBRARY_NAME = 'Unknown_TabbedHub_UI'

local function destroyOldGui()
    local parents = {CoreGui}
    if gethui then pcall(function() table.insert(parents, gethui()) end) end
    local playerGui = LocalPlayer:FindFirstChild('PlayerGui')
    if playerGui then table.insert(parents, playerGui) end
    for _, parent in ipairs(parents) do
        if parent then
            for _, child in ipairs(parent:GetChildren()) do
                if child:IsA('ScreenGui') and (child.Name == LIBRARY_NAME or child.Name == 'Unknown_TNTMining_UI') then
                    pcall(function() child:Destroy() end)
                end
            end
        end
    end
end

local ok, result = pcall(function()
    local source
    local cacheBuster = '?t=' .. tostring(os.time() or tick()) .. '_' .. tostring(math.random(1000, 9999))
    source = game:HttpGet(LIBRARY_LINK .. cacheBuster)
    local factoryChunk, compileErr = loadstring(source)
    assert(factoryChunk, 'the linked source did not compile: ' .. tostring(compileErr))
    return factoryChunk()
end)

assert(ok and type(result) == 'function', 'UnknownLibrary failed to load: ' .. tostring(result))

destroyOldGui()

local Hub = result({
    name = LIBRARY_NAME,
    title = 'UNKNOWN HUB | TNT MINING',
    parent = (gethui and gethui()) or CoreGui or LocalPlayer:WaitForChild('PlayerGui'),
    theme = Color3.fromRGB(255, 95, 31),
    secondaryTheme = Color3.fromRGB(255, 195, 0)
})

local Logic = ReplicatedStorage:WaitForChild('Logic')
local Network = require(Logic:WaitForChild('Network'))
local Signals = require(Logic:WaitForChild('Signals'))
local Configs = Logic:WaitForChild('Configs')
local RebirthConfig = require(Configs:WaitForChild('RebirthConfig'))
local UpgradesConfig = require(Configs:WaitForChild('UpgradesConfig'))
local BombsConfig = require(Configs:WaitForChild('BombsConfig'))
local AreasConfig = require(Configs:WaitForChild('AreasConfig'))
local BlocksConfig = require(Configs:WaitForChild('BlocksConfig'))
local PlayerSession = require(Logic:WaitForChild('Classes'):WaitForChild('PlayerSession'))
local RenderService = require(Logic:WaitForChild('Services'):WaitForChild('RenderService'))
local AnimationUtil = require(ReplicatedStorage:WaitForChild('ClientLogic'):WaitForChild('Utilities'):WaitForChild('AnimationUtil'))
local MineStateService = require(ReplicatedStorage:WaitForChild('ClientLogic'):WaitForChild('Services'):WaitForChild('MineStateService'))
local CollectibleBlockEngine = require(ReplicatedStorage:WaitForChild('ClientLogic'):WaitForChild('Engines'):WaitForChild('CollectibleBlockEngine'))
local BlockRoot = ReplicatedStorage:WaitForChild('Assets'):WaitForChild('Models'):WaitForChild('BlockTemplate'):WaitForChild('Root')

local function getClientSession()
    return PlayerSession.GetClient()
end

-- =========================================================================
-- PRIORITY VACUUM & RARITY HOOK (Instantly Secures Mythics, Secrets & All Drops)
-- =========================================================================
_G.TNT_AutoCollectBlocks = true

local session = getClientSession()
if session then
    local oldGetUpgradeValue = session.GetUpgradeValue
    session.GetUpgradeValue = function(self, upgradeName, ...)
        if upgradeName == 'CollectionRange' and _G.TNT_AutoCollectBlocks then
            return 999999
        end
        return oldGetUpgradeValue(self, upgradeName, ...)
    end
    session.CollectionRange = 999999
end

-- Invert rarity priority in CollectibleBlockEngine so Secrets & Mythics are processed first
local collectorData = {
    collectiblesMap = nil,
    startPickup = nil,
    rarityTable = nil
}

pcall(function()
    local engineUpvals = debug.getupvalues(CollectibleBlockEngine.Init)
    if engineUpvals then
        -- Upvalue 27: Rarity Priority Table
        local rarityTable = engineUpvals[27]
        if type(rarityTable) == 'table' then
            collectorData.rarityTable = rarityTable
            rarityTable.Secret = 1
            rarityTable.Mythic = 2
            rarityTable.Legendary = 3
            rarityTable.EggShard = 4
            rarityTable.Rare = 5
            rarityTable.Uncommon = 6
            rarityTable.Common = 7
        end

        -- Upvalue 18: spawnCollectible -> Upvalue 1 is active collectibles map
        local spawnFn = engineUpvals[18]
        if type(spawnFn) == 'function' then
            local spawnUpvals = debug.getupvalues(spawnFn)
            if spawnUpvals and type(spawnUpvals[1]) == 'table' then
                collectorData.collectiblesMap = spawnUpvals[1]
            end
        end

        -- Upvalue 29: startPickup(session, collectibleItem)
        local startPickupFn = engineUpvals[29]
        if type(startPickupFn) == 'function' then
            collectorData.startPickup = startPickupFn
        end
    end
end)

-- Dedicated Rapid Priority Vacuum Background Engine
task.spawn(function()
    while true do
        if _G.TNT_AutoCollectBlocks then
            pcall(function()
                local sess = getClientSession()
                if sess and collectorData.collectiblesMap then
                    local map = collectorData.collectiblesMap
                    local queue = {}
                    for id, item in pairs(map) do
                        if item and not item.isCollecting and not item.isPickedUp then
                            local rarity = 'Common'
                            if item.name and BlocksConfig[item.name] then
                                rarity = BlocksConfig[item.name].Rarity or 'Common'
                            elseif item.isEggShard then
                                rarity = 'EggShard'
                            end
                            local prio = (collectorData.rarityTable and collectorData.rarityTable[rarity]) or 99
                            table.insert(queue, {item = item, prio = prio})
                        end
                    end

                    -- Sort drops by highest priority (Secrets = 1, Mythics = 2, ...)
                    if #queue > 1 then
                        table.sort(queue, function(a, b)
                            return a.prio < b.prio
                        end)
                    end

                    -- Collect items in batch
                    for _, entry in ipairs(queue) do
                        local item = entry.item
                        if collectorData.startPickup then
                            collectorData.startPickup(sess, item)
                        elseif item.ids and #item.ids > 0 then
                            sess:CollectBlocks(item.ids)
                        end
                    end
                end
            end)
        end
        task.wait(0.04)
    end
end)

-- =========================================================================
-- UI TABS SETUP
-- =========================================================================
local mainPage = Hub.createTabButton('Main', 'Main', 'rbxassetid://10723407389', true)
local miningPage = Hub.createTabButton('Mining', 'Mining', 'rbxassetid://10723415903', false)
local upgradesPage = Hub.createTabButton('Upgrades', 'Upgrades', 'rbxassetid://10709761596', false)
local teleportPage = Hub.createTabButton('Teleport', 'Teleport', 'rbxassetid://10709798485', false)
local miscPage = Hub.createTabButton('Misc', 'Misc', 'rbxassetid://10709810488', false)

-- Global Feature States
local InfiniteStrengthState = false
local AutoClickBatchSize = 10
local AutoClickSpeed = 0.03
local AutoMineTargetBlocksState = false
local AutoMineAllBlocksState = false
local AutoPlantAndFlintState = false
local AutoFlintOnlyState = false
local AutoSellBlocksState = false
local AutoCollectBlocksState = true
local AutoPlantDelay = 0.15
local AutoRebirthState = false
local AutoBuyUpgradesState = false
local AutoUpgradeMineLuckState = false
local AutoEquipBestPetsState = false
local AutoTrainState = false
local SelectedTrainingPlot = 'Dirt'
local WalkSpeedValue = 16
local InfiniteJumpState = false

-- Target Block Selection Filter
local SelectedTargetArea = 'Forest'
local SelectedTargetBlock = 'All Blocks'

local areaNames = {'Forest', 'Desert', 'Arctic', 'Ocean', 'Jungle'}

-- Organize Blocks by Area from Config
local AreaBlocksMap = {}
for blockName, cfg in pairs(BlocksConfig) do
    local a = cfg.Area or 'Forest'
    if not AreaBlocksMap[a] then
        AreaBlocksMap[a] = {}
    end
    table.insert(AreaBlocksMap[a], {
        Name = blockName,
        Rarity = cfg.Rarity or 'Common',
        Health = cfg.Health or 0
    })
end

for aName, list in pairs(AreaBlocksMap) do
    table.sort(list, function(a, b)
        return (a.Health or 0) < (b.Health or 0)
    end)
end

-- =========================================================================
-- TNT MINING & IGNITION CORE
-- =========================================================================
local function sellAllBlocks()
    local sess = getClientSession()
    if sess and sess.SellAllBlocks then
        pcall(function() sess:SellAllBlocks() end)
    end
end

local function getActiveBombsCount(sess)
    local count = 0
    for _ in pairs(sess.ActiveBombs or {}) do
        count = count + 1
    end
    return count
end

local function buyMineLuckUpgrades()
    local sess = getClientSession()
    if not sess then return end
    for aName, owned in pairs(sess.OwnedAreas or {}) do
        if owned then
            pcall(function()
                sess:BuyUpgrade('MineLuck', aName)
            end)
        end
    end
end

local function plantAndFlintBombAt(plantCf)
    local sess = getClientSession()
    local char = LocalPlayer.Character
    if not sess or not plantCf then return false end
    if not sess:IsInMineArea() then return false end

    -- Check if player has bombs available
    if not sess:CanPlaceBomb() or sess.HeldBombs <= 0 then
        return false
    end

    -- Strictly respect server active bombs limit
    local activeCount = getActiveBombsCount(sess)
    local maxActive = sess.MaxActiveBombs or 3
    if activeCount >= maxActive then
        return false
    end

    local equippedBomb = sess.EquippedBomb or 'Classic'
    local isEnchanted = (sess.EnchantedBombs or 0) > 0

    local res = sess:PlaceBomb(plantCf, nil, equippedBomb)
    if res and res.Success and res.Id then
        local bombModel = RenderService.Bomb.Place({
            Name = equippedBomb,
            Cframe = plantCf,
            Config = sess:GetBombConfig(),
            IsEnchanted = isEnchanted
        })

        if bombModel then
            bombModel.Name = res.Id
            bombModel:SetAttribute('Name', equippedBomb)
        end

        local ignRes = sess:IgniteBomb(res.Id, 1.0)
        local bombObj = sess.ActiveBombs and sess.ActiveBombs[res.Id]
        
        if bombObj and bombModel then
            local expRadius = sess:GetBombExplosionRadius(bombObj.Name, bombObj.IsEnchanted)
            local mult = isEnchanted and (sess:GetEnchantedBombDamageMultiplier() or 1) or 1

            RenderService.PlayEvent('Bomb.Ignite', {
                Id = res.Id,
                Name = bombObj.Name,
                FuseTime = 1.0,
                ExplosionRadius = expRadius,
                MineRadius = expRadius * BlockRoot.Size.X,
                IsEnchanted = bombObj.IsEnchanted,
                Damage = sess.Damage * mult,
                DamagePerClick = sess:GetBombDamagePerClick(bombObj.Name),
                Session = sess,
                ActiveBomb = bombObj
            })
            pcall(function() AnimationUtil.Play(char, 'UseLighter', {PauseAtEnd = true}) end)
        end
        return true
    end
    return false
end

local function plantAndFlintAroundPlayer()
    local sess = getClientSession()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild('HumanoidRootPart')
    if not sess or not hrp then return false end
    if not sess:IsInMineArea() then return false end

    local activeCount = getActiveBombsCount(sess)
    local maxActive = sess.MaxActiveBombs or 3
    if activeCount >= maxActive then return false end

    local angle = (os.clock() * 4) % (math.pi * 2)
    local radius = (activeCount == 0) and 0 or 2.2
    local offset = Vector3.new(math.cos(angle) * radius, -2, math.sin(angle) * radius)
    local plantPos = hrp.Position + offset
    return plantAndFlintBombAt(CFrame.new(plantPos))
end

-- Mines blocks matching the selected Target Block Filter (or all if filter is empty)
local lastBlockIndex = 0
local function mineTargetBlocks()
    local sess = getClientSession()
    if not sess or not sess:IsInMineArea() then return false end

    local activeCount = getActiveBombsCount(sess)
    local maxActive = sess.MaxActiveBombs or 3
    if activeCount >= maxActive then return false end
    if not sess:CanPlaceBomb() or sess.HeldBombs <= 0 then return false end

    local exposed = MineStateService.GetExposedBlocks and MineStateService.GetExposedBlocks() or {}
    if #exposed == 0 then return false end

    -- Filter blocks if a target block is selected
    local candidates = {}
    local useFilter = (SelectedTargetBlock ~= 'All Blocks' and SelectedTargetBlock ~= '')
    for _, block in ipairs(exposed) do
        if block and block.Alive and block.Position then
            local bName = block.BlockType or block.ModelName or block.Name
            if not useFilter or bName == SelectedTargetBlock then
                table.insert(candidates, block)
            end
        end
    end

    if #candidates == 0 then return false end

    local placedAny = false
    local needed = maxActive - activeCount
    for _ = 1, math.min(needed, #candidates) do
        lastBlockIndex = (lastBlockIndex % #candidates) + 1
        local target = candidates[lastBlockIndex]
        if target and target.Alive and target.Position then
            local plantPos = target.Position + Vector3.new(0, 2, 0)
            local ok = plantAndFlintBombAt(CFrame.new(plantPos))
            if ok then
                placedAny = true
            end
        end
    end
    return placedAny
end

local function flintAllActiveBombs()
    local sess = getClientSession()
    local char = LocalPlayer.Character
    if not sess or not sess.ActiveBombs then return end

    local ignitedAny = false
    for id, bombObj in pairs(sess.ActiveBombs) do
        if bombObj and not bombObj.IsFused then
            local ignRes = sess:IgniteBomb(id, 1.0)
            if ignRes and ignRes.Success then
                ignitedAny = true
                pcall(function()
                    local bombModel = workspace.ActiveBombs:FindFirstChild(id)
                    if bombModel then
                        local expRadius = sess:GetBombExplosionRadius(bombObj.Name, bombObj.IsEnchanted)
                        local mult = bombObj.IsEnchanted and (sess:GetEnchantedBombDamageMultiplier() or 1) or 1

                        RenderService.PlayEvent('Bomb.Ignite', {
                            Id = id,
                            Name = bombObj.Name,
                            FuseTime = 1.0,
                            ExplosionRadius = expRadius,
                            MineRadius = expRadius * BlockRoot.Size.X,
                            IsEnchanted = bombObj.IsEnchanted,
                            Damage = sess.Damage * mult,
                            DamagePerClick = sess:GetBombDamagePerClick(bombObj.Name),
                            Session = sess,
                            ActiveBomb = bombObj
                        })
                    end
                end)
            end
        end
    end
    if ignitedAny and char then
        pcall(function() AnimationUtil.Play(char, 'UseLighter', {PauseAtEnd = true}) end)
    end
end

-- =========================================================================
-- PERSISTENT BACKGROUND ROUTINES
-- =========================================================================
-- Auto Mine Target Blocks / Selected Blocks Loop
task.spawn(function()
    while true do
        if AutoMineTargetBlocksState or AutoMineAllBlocksState then
            local sess = getClientSession()
            if sess and sess:CanPlaceBomb() and sess.HeldBombs > 0 then
                pcall(mineTargetBlocks)
            end
        end
        task.wait(AutoPlantDelay)
    end
end)

-- Auto Plant & Flint (Player Radius) Loop
task.spawn(function()
    while true do
        if AutoPlantAndFlintState and not AutoMineTargetBlocksState and not AutoMineAllBlocksState then
            local sess = getClientSession()
            if sess and sess:CanPlaceBomb() and sess.HeldBombs > 0 then
                local activeCount = getActiveBombsCount(sess)
                if activeCount < (sess.MaxActiveBombs or 3) then
                    pcall(plantAndFlintAroundPlayer)
                end
            end
        end
        task.wait(AutoPlantDelay)
    end
end)

-- Auto Flint Only Loop
task.spawn(function()
    while true do
        if AutoFlintOnlyState then
            pcall(flintAllActiveBombs)
        end
        task.wait(0.15)
    end
end)

-- Auto Sell Blocks Loop
task.spawn(function()
    while true do
        if AutoSellBlocksState then
            pcall(sellAllBlocks)
        end
        task.wait(2.0)
    end
end)

-- Server-Verified Infinite Strength Engine
task.spawn(function()
    while true do
        if InfiniteStrengthState then
            pcall(function()
                local sess = getClientSession()
                if sess then
                    local dpc = sess:GetDamagePerClick() or 10
                    local batch = AutoClickBatchSize
                    sess:_ApplyPredictedDamage(dpc * batch)
                    local res = Network.ClientAction.Invoke({'ApplyClicks', {batch}})
                    if res and res.DamageGained then
                        Signals.Fire('TrainingDamageGained', res.DamageGained)
                    end
                end
            end)
        end
        task.wait(AutoClickSpeed)
    end
end)

-- Auto Rebirth Loop
task.spawn(function()
    while true do
        if AutoRebirthState then
            pcall(function()
                local sess = getClientSession()
                if sess then
                    local reqLevel = RebirthConfig.GetRebirthLevelRequirement(sess.Rebirths + 1)
                    if sess.Level >= reqLevel then
                        Network.ClientAction.Invoke({'PerformRebirth'})
                    end
                end
            end)
        end
        task.wait(1.5)
    end
end)

-- Auto Equip Best Pets Loop
task.spawn(function()
    while true do
        if AutoEquipBestPetsState then
            pcall(function()
                local sess = getClientSession()
                if sess and sess.EquipBestPets then
                    sess:EquipBestPets()
                end
            end)
        end
        task.wait(5)
    end
end)

-- Auto Train Loop
task.spawn(function()
    while true do
        if AutoTrainState then
            pcall(function()
                local plots = workspace:FindFirstChild('Map') and workspace.Map:FindFirstChild('Lobby') and workspace.Map.Lobby:FindFirstChild('TrainingArea') and workspace.Map.Lobby.TrainingArea:FindFirstChild('Plots')
                local targetPlot = plots and plots:FindFirstChild(SelectedTrainingPlot)
                local plate = targetPlot and targetPlot:FindFirstChild('TrainingPlotPlate')
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild('HumanoidRootPart')
                if hrp and plate then
                    if (hrp.Position - plate.Position).Magnitude > 6 then
                        hrp.CFrame = plate.CFrame + Vector3.new(0, 3, 0)
                    end
                end
            end)
        end
        task.wait(0.5)
    end
end)

-- Auto Buy Upgrades Loop
local standardUpgradeTypes = {
    'WalkSpeed',
    'MaxActiveBombs',
    'MaxHeldBombs',
    'CollectionRange'
}

task.spawn(function()
    while true do
        if AutoBuyUpgradesState then
            pcall(function()
                local sess = getClientSession()
                if sess then
                    for _, upgName in ipairs(standardUpgradeTypes) do
                        pcall(function()
                            sess:BuyUpgrade(upgName)
                        end)
                    end
                    buyMineLuckUpgrades()
                end
            end)
        end
        if AutoUpgradeMineLuckState and not AutoBuyUpgradesState then
            pcall(buyMineLuckUpgrades)
        end
        task.wait(1.5)
    end
end)

-- =========================================================================
-- TAB 1: MAIN PAGE (Infinite Strength & Training)
-- =========================================================================
Hub.CreateToggle(mainPage, 'Infinite Strength (Rapid Auto Click)', false, function(state)
    InfiniteStrengthState = (state == true)
    Hub.notify({
        Title = 'Infinite Strength',
        Content = InfiniteStrengthState and 'Infinite Strength Generator Activated!' or 'Infinite Strength Deactivated.',
        Duration = 2
    })
end)

Hub.CreateSlider(mainPage, 'Strength Click Batch Size', 1, 25, 10, ' clicks', function(val)
    AutoClickBatchSize = math.floor(val)
end)

Hub.CreateSlider(mainPage, 'Strength Click Interval Delay', 0.01, 0.5, 0.03, 's', function(val)
    AutoClickSpeed = val
end)

Hub.CreateToggle(mainPage, 'Auto Rebirth', false, function(state)
    AutoRebirthState = (state == true)
end)

Hub.CreateToggle(mainPage, 'Auto Equip Best Pets', false, function(state)
    AutoEquipBestPetsState = (state == true)
end)

local availablePlots = {'Dirt', 'Stone', 'Silver', 'Cactus', 'Amethyst', 'Magma', 'Ruby', 'Gold', 'Void'}
local plotItems = {}
for _, pName in ipairs(availablePlots) do
    table.insert(plotItems, {Name = pName})
end

local trainingList = Hub.CreateList(mainPage, 'Select Training Plot', plotItems, 160, true)
for _, item in ipairs(trainingList.Items or {}) do
    local row = item.Row
    local name = item.Name or (item.Data and item.Data.Name)
    if row and row:IsA('TextButton') and name then
        row.MouseButton1Click:Connect(function()
            SelectedTrainingPlot = name
            Hub.notify({
                Title = 'Training Plot Selected',
                Content = 'Target: ' .. name .. ' Plot',
                Duration = 2
            })
        end)
    end
end

Hub.CreateToggle(mainPage, 'Auto Train at Selected Plot', false, function(state)
    AutoTrainState = (state == true)
end)

-- =========================================================================
-- TAB 2: MINING & TNT AUTOMATION (Nested Lists: List of Areas -> Blocks per Area)
-- =========================================================================
Hub.CreateToggle(miningPage, 'Auto Mine Target Block (Auto Place TNT)', false, function(state)
    AutoMineTargetBlocksState = (state == true)
    local sess = getClientSession()
    if AutoMineTargetBlocksState and sess and not sess:IsInMineArea() then
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild('HumanoidRootPart')
        local aName = SelectedTargetArea or 'Forest'
        local blocksArea = workspace:FindFirstChild('Map') and workspace.Map:FindFirstChild('Areas') and workspace.Map.Areas:FindFirstChild(aName) and workspace.Map.Areas[aName]:FindFirstChild('Mine') and workspace.Map.Areas[aName].Mine:FindFirstChild('BlocksArea')
        if hrp and blocksArea then
            hrp.CFrame = blocksArea.CFrame + Vector3.new(0, 48, 0)
        end
    end
    Hub.notify({
        Title = 'Auto Mine Target Block',
        Content = AutoMineTargetBlocksState and ('Auto Mining target: ' .. SelectedTargetBlock .. ' (' .. SelectedTargetArea .. ')') or 'Auto Mine Stopped.',
        Duration = 2.5
    })
end)

Hub.CreateToggle(miningPage, 'Auto Mine All Blocks (Grid Wiper)', false, function(state)
    AutoMineAllBlocksState = (state == true)
    local sess = getClientSession()
    if AutoMineAllBlocksState and sess and not sess:IsInMineArea() then
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild('HumanoidRootPart')
        local blocksArea = workspace:FindFirstChild('Map') and workspace.Map:FindFirstChild('Areas') and workspace.Map.Areas:FindFirstChild('Forest') and workspace.Map.Areas.Forest:FindFirstChild('Mine') and workspace.Map.Areas.Forest.Mine:FindFirstChild('BlocksArea')
        if hrp and blocksArea then
            hrp.CFrame = blocksArea.CFrame + Vector3.new(0, 48, 0)
        end
    end
    Hub.notify({
        Title = 'Auto Mine All Blocks',
        Content = AutoMineAllBlocksState and 'Auto Mining all blocks across mine pit!' or 'Auto Mine All Blocks Stopped.',
        Duration = 2.5
    })
end)

-- MASTER LIST: List of Areas
local masterAreaList = Hub.CreateList(miningPage, 'List of Areas (Click to Expand)', {}, 320, true)

-- For each area, create a nested sub-list directly inside masterAreaList
for _, aName in ipairs(areaNames) do
    local blockItems = {{Name = 'All Blocks (Mine Everything)'}}
    local rawList = AreaBlocksMap[aName] or {}
    for _, b in ipairs(rawList) do
        table.insert(blockItems, {Name = b.Name .. ' [' .. b.Rarity .. ']'})
    end

    -- Create sub-list inside masterAreaList (nested list)
    local subList = Hub.CreateList(masterAreaList, aName .. ' Area Blocks', blockItems, 160, false)
    
    for _, item in ipairs(subList.Items or {}) do
        local row = item.Row
        local rawText = item.Name or (item.Data and item.Data.Name) or ''
        if row and row:IsA('TextButton') and rawText ~= '' then
            row.MouseButton1Click:Connect(function()
                SelectedTargetArea = aName
                if rawText:find('All Blocks') then
                    SelectedTargetBlock = 'All Blocks'
                else
                    local cleanName = rawText:match('^([^%[]+)')
                    SelectedTargetBlock = cleanName and cleanName:gsub('%s+$', '') or rawText
                end
                Hub.notify({
                    Title = 'Target Block Selected',
                    Content = 'Area: ' .. aName .. ' | Target: ' .. SelectedTargetBlock,
                    Duration = 2.5
                })
            end)
        end
    end
end

Hub.CreateToggle(miningPage, 'Auto Collect Blocks (Priority Vacuum)', true, function(state)
    AutoCollectBlocksState = (state == true)
    _G.TNT_AutoCollectBlocks = AutoCollectBlocksState
    local sess = getClientSession()
    if sess then
        sess.CollectionRange = AutoCollectBlocksState and 999999 or (sess:GetUpgradeValue('CollectionRange') or 18)
    end
    Hub.notify({
        Title = 'Priority Vacuum',
        Content = AutoCollectBlocksState and 'Priority Vacuum Active (Mythics & Secrets prioritized)!' or 'Auto Collect Deactivated.',
        Duration = 2
    })
end)

Hub.CreateToggle(miningPage, 'Auto Plant & Flint (Player Radius)', false, function(state)
    AutoPlantAndFlintState = (state == true)
    Hub.notify({
        Title = 'Auto Plant & Flint',
        Content = AutoPlantAndFlintState and 'Plant & Flint around player active!' or 'Plant & Flint Deactivated.',
        Duration = 2
    })
end)

Hub.CreateSlider(miningPage, 'Plant Delay Interval', 0.05, 1.5, 0.15, 's', function(val)
    AutoPlantDelay = val
end)

Hub.CreateToggle(miningPage, 'Auto Flint / Ignite All (Only)', false, function(state)
    AutoFlintOnlyState = (state == true)
end)

Hub.CreateToggle(miningPage, 'Auto Sell Mined Blocks', false, function(state)
    AutoSellBlocksState = (state == true)
    Hub.notify({
        Title = 'Auto Sell',
        Content = AutoSellBlocksState and 'Auto Sell Blocks Active (Money mode)!' or 'Auto Sell Disabled (Keeping blocks in inventory)!',
        Duration = 2.5
    })
end)

Hub.CreateButton(miningPage, 'Instant Plant & Flint on Block', function()
    local ok = mineTargetBlocks()
    Hub.notify({
        Title = 'Manual Mine Block',
        Content = ok and 'Placed and ignited TNT on block!' or 'Failed: Must be inside Mine Area with bombs and free active slots!',
        Duration = 2.5
    })
end)

Hub.CreateButton(miningPage, 'Flint / Ignite All Active Bombs', function()
    flintAllActiveBombs()
    Hub.notify({
        Title = 'Flint All',
        Content = 'Ignited all active placed bombs!',
        Duration = 2
    })
end)

Hub.CreateButton(miningPage, 'Sell All Blocks Now', function()
    sellAllBlocks()
    Hub.notify({
        Title = 'Sell Blocks',
        Content = 'Sold all blocks in inventory!',
        Duration = 2
    })
end)

-- =========================================================================
-- TAB 3: UPGRADES
-- =========================================================================
Hub.CreateToggle(upgradesPage, 'Auto Buy All Upgrades', false, function(state)
    AutoBuyUpgradesState = (state == true)
    Hub.notify({
        Title = 'Auto Upgrades',
        Content = AutoBuyUpgradesState and 'Auto Upgrading All Stats & Mine Luck!' or 'Auto Upgrades Deactivated.',
        Duration = 2
    })
end)

Hub.CreateToggle(upgradesPage, 'Auto Upgrade Mine Luck (All Areas)', false, function(state)
    AutoUpgradeMineLuckState = (state == true)
    Hub.notify({
        Title = 'Auto Mine Luck',
        Content = AutoUpgradeMineLuckState and 'Auto Upgrading Mine Luck across all owned areas!' or 'Auto Mine Luck Deactivated.',
        Duration = 2
    })
end)

Hub.CreateButton(upgradesPage, 'Upgrade Mine Luck (All Owned Areas)', function()
    local sess = getClientSession()
    if sess then
        buyMineLuckUpgrades()
        Hub.notify({
            Title = 'Mine Luck',
            Content = 'Attempted Mine Luck upgrades across all owned areas!',
            Duration = 2.5
        })
    end
end)

for _, upgName in ipairs(standardUpgradeTypes) do
    Hub.CreateButton(upgradesPage, 'Upgrade ' .. upgName, function()
        local sess = getClientSession()
        if sess then
            sess:BuyUpgrade(upgName)
        end
    end)
end

for _, aName in ipairs(areaNames) do
    Hub.CreateButton(upgradesPage, 'Upgrade Mine Luck (' .. aName .. ')', function()
        local sess = getClientSession()
        if sess then
            local res = sess:BuyUpgrade('MineLuck', aName)
            Hub.notify({
                Title = 'Mine Luck: ' .. aName,
                Content = (res and res.Success) and 'Upgraded Mine Luck in ' .. aName .. '!' or 'Failed: ' .. tostring(res and res.Reason or 'insufficient balance'),
                Duration = 2.5
            })
        end
    end)
end

-- =========================================================================
-- TAB 4: TELEPORT
-- =========================================================================
local function teleportTo(cf)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild('HumanoidRootPart')
    if hrp and cf then
        hrp.CFrame = cf
    end
end

Hub.CreateButton(teleportPage, 'Lobby Spawn', function()
    local spawn = workspace:FindFirstChild('Map') and workspace.Map:FindFirstChild('Lobby') and workspace.Map.Lobby:FindFirstChild('SpawnLocation')
    if spawn then
        teleportTo(spawn.CFrame + Vector3.new(0, 4, 0))
    end
end)

Hub.CreateButton(teleportPage, 'Bomb Shop', function()
    local shop = workspace:FindFirstChild('Map') and workspace.Map:FindFirstChild('Lobby') and workspace.Map.Lobby:FindFirstChild('BombShop') and workspace.Map.Lobby.BombShop:FindFirstChild('PromptPart')
    if shop then
        teleportTo(shop.CFrame + Vector3.new(0, 3, 0))
    end
end)

Hub.CreateButton(teleportPage, 'Upgrade Shop', function()
    local shop = workspace:FindFirstChild('Map') and workspace.Map:FindFirstChild('Lobby') and workspace.Map.Lobby:FindFirstChild('UpgradeShop') and workspace.Map.Lobby.UpgradeShop:FindFirstChild('PromptPart')
    if shop then
        teleportTo(shop.CFrame + Vector3.new(0, 3, 0))
    end
end)

Hub.CreateButton(teleportPage, 'Sell Stand', function()
    local stand = workspace:FindFirstChild('Map') and workspace.Map:FindFirstChild('Lobby') and workspace.Map.Lobby:FindFirstChild('SellStand') and workspace.Map.Lobby.SellStand:FindFirstChild('PromptPart')
    if stand then
        teleportTo(stand.CFrame + Vector3.new(0, 3, 0))
    end
end)

Hub.CreateButton(teleportPage, 'Training Area', function()
    local plots = workspace:FindFirstChild('Map') and workspace.Map:FindFirstChild('Lobby') and workspace.Map.Lobby:FindFirstChild('TrainingArea') and workspace.Map.Lobby.TrainingArea:FindFirstChild('Plots')
    local dirt = plots and plots:FindFirstChild('Dirt') and plots.Dirt:FindFirstChild('TrainingPlotPlate')
    if dirt then
        teleportTo(dirt.CFrame + Vector3.new(0, 4, 0))
    end
end)

for _, aName in ipairs(areaNames) do
    Hub.CreateButton(teleportPage, 'Mine: ' .. aName, function()
        local areaPart = workspace:FindFirstChild('Map') and workspace.Map:FindFirstChild('Areas') and workspace.Map.Areas:FindFirstChild(aName)
        if areaPart then
            teleportTo(areaPart:GetPivot() + Vector3.new(0, 4, 0))
        else
            Hub.notify({
                Title = 'Area Not Loaded',
                Content = aName .. ' area not currently accessible in workspace',
                Duration = 2.5
            })
        end
    end)
end

-- =========================================================================
-- TAB 5: MISC & PLAYER MODS
-- =========================================================================
Hub.CreateSlider(miscPage, 'WalkSpeed Modifier', 16, 120, 16, '', function(val)
    WalkSpeedValue = val
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass('Humanoid') then
        LocalPlayer.Character:FindFirstChildOfClass('Humanoid').WalkSpeed = val
    end
end)

RunService.RenderStepped:Connect(function()
    if WalkSpeedValue > 16 and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass('Humanoid') then
        LocalPlayer.Character:FindFirstChildOfClass('Humanoid').WalkSpeed = WalkSpeedValue
    end
end)

Hub.CreateToggle(miscPage, 'Infinite Jump', false, function(state)
    InfiniteJumpState = (state == true)
end)

UserInputService.JumpRequest:Connect(function()
    if InfiniteJumpState and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass('Humanoid') then
        LocalPlayer.Character:FindFirstChildOfClass('Humanoid'):ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

Hub.CreateButton(miscPage, 'Claim Daily / Group Reward', function()
    pcall(function()
        local sess = getClientSession()
        if sess then
            if sess.ClaimDailyReward then sess:ClaimDailyReward() end
            if sess.ClaimGroupReward then sess:ClaimGroupReward() end
        end
        Hub.notify({
            Title = 'Rewards',
            Content = 'Daily and Group rewards claimed if available!',
            Duration = 3
        })
    end)
end)

Hub.notify({
    Title = 'Unknown Hub Loaded',
    Content = 'TNT Mining Automation with Nested Area & Block Lists!',
    Duration = 4
})
