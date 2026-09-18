local LIBRARY_LINK = "https://raw.githubusercontent.com/UnknownHQ/UnknownHub/main/UnknownLibrary"
local LIBRARY_NAME = "Unknown_TabbedHub_UI"

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
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

-- Safe Dynamic Module & Catalog Loading
local PlantTraitsData = nil
pcall(function()
    local modules = ReplicatedStorage:WaitForChild("Modules", 5)
    if modules and modules:FindFirstChild("PlantTraitsData") then
        PlantTraitsData = require(modules.PlantTraitsData)
    end
end)

local SeedData = nil
pcall(function()
    local dataFolder = ReplicatedStorage:WaitForChild("Data", 5)
    if dataFolder and dataFolder:FindFirstChild("SeedData") then
        SeedData = require(dataFolder.SeedData)
    end
end)

local MutationData = nil
pcall(function()
    local ggModules = ReplicatedStorage:WaitForChild("Modules", 5):WaitForChild("GardenGuideModules", 5):WaitForChild("DataModules", 5)
    if ggModules and ggModules:FindFirstChild("MutationData") then
        MutationData = require(ggModules.MutationData)
    end
end)

-- Remotes
local CollectRemote = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("Crops"):WaitForChild("Collect")
local SellInvRemote = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("Sell_Inventory")
local SellItemRemote = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("Sell_Item")

-- =========================================================================
-- Dynamic Self-Updating Catalogs
-- =========================================================================

-- 1. Plants Catalog (660+ plants, dynamically self-updating)
local function buildDynamicPlantCatalog()
    local plantSet = {}

    if SeedData and type(SeedData) == "table" then
        for name, _ in pairs(SeedData) do
            if type(name) == "string" and name ~= "" then
                plantSet[name] = true
            end
        end
    end

    if PlantTraitsData and type(PlantTraitsData) == "table" then
        for _, plantMap in pairs(PlantTraitsData) do
            if type(plantMap) == "table" then
                for name, _ in pairs(plantMap) do
                    if type(name) == "string" and name ~= "" then
                        plantSet[name] = true
                    end
                end
            end
        end
    end

    pcall(function()
        local farmFolder = Workspace:FindFirstChild("Farm") or Workspace
        for _, farm in ipairs(farmFolder:GetChildren()) do
            local important = farm:FindFirstChild("Important")
            local plantsFolder = important and important:FindFirstChild("Plants_Physical")
            if plantsFolder then
                for _, plant in ipairs(plantsFolder:GetChildren()) do
                    plantSet[plant.Name] = true
                end
            end
        end
    end)

    local sortedList = {"None"}
    local temp = {}
    for plantName, _ in pairs(plantSet) do
        table.insert(temp, plantName)
    end
    table.sort(temp)
    for _, name in ipairs(temp) do
        table.insert(sortedList, name)
    end
    return sortedList
end

-- 2. Mutations Catalog (230+ mutations, dynamically self-updating)
local function buildDynamicMutationCatalog()
    local mutSet = {}

    if MutationData and type(MutationData) == "table" then
        local d = MutationData.Data or (MutationData.RegatherData and MutationData.RegatherData()) or MutationData
        for k, v in pairs(d) do
            local name = type(v) == "table" and (v.Name or v.Title or k) or k
            if type(name) == "string" and name ~= "" and not name:find("Data") and not name:find("Total") and not name:find("Unlocked") then
                mutSet[name] = true
            end
        end
    end

    local fallbackMutations = {
        "Abyssal", "AncientAmber", "Astral", "Aurora", "Azure", "Beanbound", "Celestial", 
        "Chilled", "Corrupt", "CorruptFoxfireChakra", "Cute", "Dawnbound", "Disco", 
        "Drenched", "Eclipsed", "Frozen", "Glitched", "Gloom", "Gnomed", "Golden", 
        "Goldsparkle", "HarmonisedChakra", "Heartbound", "Infernal", "Jackpot", "Junkshock", 
        "Lightcycle", "Luminous", "Maelstrom", "Moonlit", "OilBoil", "Paradisal", "Pollinated", 
        "Rainbow", "Shocked", "Silver", "Sizzled", "Slashbound", "Spaghetti", "Stormcharged", 
        "Subzero", "SunScorched", "Tidal", "Tranquil", "Twisted", "Warped", "Wet"
    }
    for _, m in ipairs(fallbackMutations) do
        mutSet[m] = true
    end

    local sortedList = {"None"}
    local temp = {}
    for mutName, _ in pairs(mutSet) do
        table.insert(temp, mutName)
    end
    table.sort(temp)
    for _, name in ipairs(temp) do
        table.insert(sortedList, name)
    end
    return sortedList
end

-- 3. Plant Categories Catalog (33 categories)
local function buildDynamicCategoryCatalog()
    local catSet = {
        ["Fruit"] = true,
        ["Prickly"] = true,
        ["Leafy"] = true,
        ["Berry"] = true,
        ["Flower"] = true,
        ["Vegetable"] = true,
        ["Apple"] = true,
        ["Stalky"] = true,
        ["Magical"] = true,
        ["Nutty"] = true,
        ["Toxic"] = true,
        ["Zen"] = true,
        ["Night"] = true,
        ["Honey"] = true,
        ["Spicy"] = true,
        ["Sweet"] = true,
        ["Root"] = true,
        ["Fungus"] = true,
        ["Tropical"] = true
    }

    if PlantTraitsData and type(PlantTraitsData) == "table" then
        for cat, val in pairs(PlantTraitsData) do
            if type(val) == "table" and not cat:find("Color") and not cat:find("Name") and not cat:find("Trait") then
                catSet[cat] = true
            end
        end
    end

    local sortedList = {"None"}
    local temp = {}
    for catName, _ in pairs(catSet) do
        table.insert(temp, catName)
    end
    table.sort(temp)
    for _, name in ipairs(temp) do
        table.insert(sortedList, name)
    end
    return sortedList
end

local allAvailablePlants = buildDynamicPlantCatalog()
local allAvailableMutations = buildDynamicMutationCatalog()
local allAvailableCategories = buildDynamicCategoryCatalog()

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
    subTitle = "Grow a Garden",
    parent = (gethui and gethui()) or (LocalPlayer and (LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui"))) or (pcall(function() return game:GetService("CoreGui") end) and game:GetService("CoreGui")),
    theme = Color3.fromRGB(46, 204, 113),
    secondaryTheme = Color3.fromRGB(39, 174, 96)
})

assert(type(Hub) == "table", "UnknownLibrary returned an invalid hub")

-- =========================================================================
-- State Management & Filtering Configurations
-- =========================================================================
local State = {
    -- Collection
    AutoCollectAll = false,
    AutoCollectFiltered = false,
    Collect_Fruit = "None",
    Collect_Category = "None",
    Collect_Variant = "None",
    Collect_Mutation = "None",
    Collect_Weight = 0,
    Collect_WeightMode = "Above",
    Collect_StopWhenFull = false,

    -- Selling
    AutoSell = false,
    Sell_WaitMaxBackpack = false,
    Sell_ExcludeFruit = "None",
    Sell_ExcludeCategory = "None",
    Sell_ExcludeVariant = "None",
    Sell_ExcludeMutation = "None",
    Sell_Weight = 0,
    Sell_WeightMode = "Above",

    -- General
    MaxBackpackCapacity = 500,
    BatchSize = 25,
    HarvestDelay = 0.15,
    SellCheckDelay = 1.0
}

-- Forward References for UI Objects
local autoCollectAllToggle
local autoCollectFilteredToggle
local collectStopWhenFullToggle
local collectFruitListObj
local collectCategoryListObj
local collectVariantListObj
local collectMutationListObj
local collectWeightModeListObj

local autoSellToggle
local sellWaitMaxToggle
local sellExcludeFruitListObj
local sellExcludeCategoryListObj
local sellExcludeVariantListObj
local sellExcludeMutationListObj
local sellWeightModeListObj

-- Helper Getters for UI State
local function getUIListVal(listObj, defaultVal)
    if listObj then
        local sel = listObj.SelectedItem or (listObj.BringSelected and listObj:BringSelected()) or (listObj.SelectedItems and listObj.SelectedItems[1])
        if type(sel) == "table" then
            return sel.Name or sel[1] or defaultVal
        elseif type(sel) == "string" then
            return sel
        end
    end
    return defaultVal
end

local function isToggleActive(toggleObj, defaultState, hubTitle)
    if toggleObj and toggleObj.Get then
        local st = toggleObj.Get()
        if st ~= nil then return st end
    end
    if Hub.IsActive and hubTitle then
        local act = Hub.IsActive(hubTitle)
        if act ~= nil then return act end
    end
    return defaultState
end

local function getBackpackCount()
    local count = 0
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        count = count + #backpack:GetChildren()
    end
    local char = LocalPlayer.Character
    if char then
        for _, item in ipairs(char:GetChildren()) do
            if item:IsA("Tool") then
                count = count + 1
            end
        end
    end
    return count
end

local function isBackpackFull()
    return getBackpackCount() >= State.MaxBackpackCapacity
end

-- =========================================================================
-- Metadata Extractors
-- =========================================================================

-- Extract info from fruit model in Workspace (for Harvesting)
local function getFruitGroupInfo(plantInstance, fruitGroupInstance)
    if not fruitGroupInstance then return nil end
    local plantName = plantInstance and plantInstance.Name or "Unknown"
    local weight = 1
    local variant = "Basic"
    local mutationsFound = {}

    local attrs = fruitGroupInstance:GetAttributes()
    local plantAttrs = plantInstance and plantInstance:GetAttributes() or {}

    if attrs["WeightMulti"] then
        weight = tonumber(attrs["WeightMulti"]) or 1
    elseif plantAttrs["WeightMulti"] then
        weight = tonumber(plantAttrs["WeightMulti"]) or 1
    end

    if attrs["Variant"] then
        variant = tostring(attrs["Variant"])
    elseif attrs["Goldsparkle"] or attrs["Gold"] then
        variant = "Gold"
    elseif attrs["RainbowShine"] or attrs["Rainbow"] then
        variant = "Rainbow"
    elseif attrs["Diamond"] then
        variant = "Diamond"
    elseif attrs["Silver"] then
        variant = "Silver"
    end

    for k, v in pairs(attrs) do
        if v == true or type(v) == "string" or type(v) == "number" then
            mutationsFound[tostring(k):lower()] = true
        end
    end
    for k, v in pairs(plantAttrs) do
        if v == true then
            mutationsFound[tostring(k):lower()] = true
        end
    end

    for _, desc in ipairs(fruitGroupInstance:GetDescendants()) do
        local cName = tostring(desc.Name):lower()
        mutationsFound[cName] = true
        if cName:find("rainbow") then
            variant = "Rainbow"
        elseif cName:find("gold") or cName:find("shine") then
            if variant == "Basic" then variant = "Gold" end
        elseif cName:find("sparkle") then
            if variant == "Basic" then variant = "Silver" end
        elseif cName:find("diamond") then
            variant = "Diamond"
        end
    end

    return {
        PlantName = plantName,
        Variant = variant,
        Weight = weight,
        Mutations = mutationsFound,
        FruitGroup = fruitGroupInstance,
        Plant = plantInstance
    }
end

-- Extract info from Tool in Backpack (for Selling)
local function getToolInfo(tool)
    if not tool or not tool:IsA("Tool") then return nil end
    local toolName = tostring(tool.Name)
    local plantName = tool:GetAttribute("f") or tool:GetAttribute("Fruit") or toolName
    plantName = tostring(plantName)
    local weight = tonumber(tool:GetAttribute("WeightMulti")) or 1
    local variant = tostring(tool:GetAttribute("Variant") or "Basic")
    local mutationsFound = {}

    -- Parse weight from tool name if present (e.g. "[2.42kg]")
    local kgMatch = toolName:match("%[([%d%.]+)%s*[kK][gG]%]")
    if kgMatch then
        weight = tonumber(kgMatch) or weight
    end

    -- Parse variant from tool name
    local nameLower = toolName:lower()
    if nameLower:find("rainbow") then variant = "Rainbow"
    elseif nameLower:find("gold") then variant = "Gold"
    elseif nameLower:find("diamond") then variant = "Diamond"
    elseif nameLower:find("silver") then variant = "Silver"
    end

    for k, v in pairs(tool:GetAttributes()) do
        if v == true or type(v) == "string" or type(v) == "number" then
            mutationsFound[tostring(k):lower()] = true
        end
    end

    -- Clean extracted plant name from tags by iterating through list values
    for _, plant in ipairs(allAvailablePlants) do
        if type(plant) == "string" and plant ~= "None" and nameLower:find(plant:lower()) then
            plantName = plant
            break
        end
    end

    return {
        Tool = tool,
        ToolName = toolName,
        PlantName = plantName,
        Variant = variant,
        Weight = weight,
        Mutations = mutationsFound
    }
end

-- =========================================================================
-- Match & Exclusion Evaluators
-- =========================================================================

-- Evaluator for Harvesting
local function matchesCollectFilters(info)
    if not info then return false end

    local activeFruit = tostring(getUIListVal(collectFruitListObj, State.Collect_Fruit))
    local activeCat = tostring(getUIListVal(collectCategoryListObj, State.Collect_Category))
    local activeVar = tostring(getUIListVal(collectVariantListObj, State.Collect_Variant))
    local activeMut = tostring(getUIListVal(collectMutationListObj, State.Collect_Mutation))
    local weightThreshold = State.Collect_Weight or 0
    local weightMode = tostring(getUIListVal(collectWeightModeListObj, State.Collect_WeightMode))

    local anyFilterActive = (activeFruit ~= "None") or (activeCat ~= "None") or (activeVar ~= "None") or (activeMut ~= "None") or (weightThreshold > 0)
    if not anyFilterActive then
        return false
    end

    -- Variant Filter
    if activeVar ~= "None" then
        if info.Variant:lower() ~= activeVar:lower() then return false end
    end

    -- Specific Fruit Filter
    if activeFruit ~= "None" then
        if info.PlantName:lower() ~= activeFruit:lower() and not info.PlantName:lower():find(activeFruit:lower()) then return false end
    end

    -- Mutation Filter
    if activeMut ~= "None" then
        local mutKey = activeMut:lower()
        local hasMut = info.Mutations[mutKey] or false
        if not hasMut and info.FruitGroup then hasMut = (info.FruitGroup:GetAttribute(activeMut) == true) end
        if not hasMut and info.Plant then hasMut = (info.Plant:GetAttribute(activeMut) == true) end
        if not hasMut and CollectionService:HasTag(info.FruitGroup, activeMut .. "Visual") then hasMut = true end
        if not hasMut then return false end
    end

    -- Category Filter
    if activeCat ~= "None" then
        local matchedCategory = false
        if PlantTraitsData then
            pcall(function()
                if PlantTraitsData.HasTrait and PlantTraitsData.HasTrait(info.PlantName, activeCat) then
                    matchedCategory = true
                elseif PlantTraitsData[activeCat] and PlantTraitsData[activeCat][info.PlantName] then
                    matchedCategory = true
                end
            end)
        end
        if not matchedCategory and info.PlantName:lower():find(activeCat:lower()) then matchedCategory = true end
        if not matchedCategory then return false end
    end

    -- Weight Filter (Above or Lower)
    if weightThreshold > 0 then
        if weightMode == "Above" and info.Weight < weightThreshold then return false end
        if weightMode == "Lower" and info.Weight > weightThreshold then return false end
    end

    return true
end

-- Evaluator for Auto Selling (Returns true if tool should be sold, false if excluded)
local function shouldSellTool(info)
    if not info or not info.Tool then return false end

    -- Exclude non-fruit items (Pets, Seeds, Chews, Shovels, Potions)
    local tName = info.ToolName:lower()
    if info.Tool:GetAttribute("PET_UUID") or tName:find("seed") or tName:find("chew") or tName:find("shovel") or tName:find("potion") or tName:find("egg") or tName:find("rod") then
        return false
    end

    local exFruit = tostring(getUIListVal(sellExcludeFruitListObj, State.Sell_ExcludeFruit))
    local exCat = tostring(getUIListVal(sellExcludeCategoryListObj, State.Sell_ExcludeCategory))
    local exVar = tostring(getUIListVal(sellExcludeVariantListObj, State.Sell_ExcludeVariant))
    local exMut = tostring(getUIListVal(sellExcludeMutationListObj, State.Sell_ExcludeMutation))
    local weightThreshold = State.Sell_Weight or 0
    local weightMode = tostring(getUIListVal(sellWeightModeListObj, State.Sell_WeightMode))

    -- Exclude by Variant
    if exVar ~= "None" and info.Variant:lower() == exVar:lower() then
        return false
    end

    -- Exclude by Specific Fruit
    if exFruit ~= "None" and (info.PlantName:lower() == exFruit:lower() or info.PlantName:lower():find(exFruit:lower())) then
        return false
    end

    -- Exclude by Mutation
    if exMut ~= "None" then
        local mutKey = exMut:lower()
        if info.Mutations[mutKey] or info.Tool:GetAttribute(exMut) == true or info.ToolName:lower():find(mutKey) then
            return false
        end
    end

    -- Exclude by Category
    if exCat ~= "None" then
        local inCat = false
        if PlantTraitsData then
            pcall(function()
                if PlantTraitsData.HasTrait and PlantTraitsData.HasTrait(info.PlantName, exCat) then inCat = true
                elseif PlantTraitsData[exCat] and PlantTraitsData[exCat][info.PlantName] then inCat = true end
            end)
        end
        if not inCat and info.PlantName:lower():find(exCat:lower()) then inCat = true end
        if inCat then return false end
    end

    -- Exclude by Weight (Above or Lower)
    if weightThreshold > 0 then
        if weightMode == "Above" and info.Weight >= weightThreshold then return false end
        if weightMode == "Lower" and info.Weight <= weightThreshold then return false end
    end

    return true
end

-- =========================================================================
-- True Remote Harvest Engine
-- =========================================================================
task.spawn(function()
    while true do
        task.wait(State.HarvestDelay)
        local collectAll = isToggleActive(autoCollectAllToggle, State.AutoCollectAll, "⚡ Auto Collect ALL (No Filter)")
        local collectFiltered = isToggleActive(autoCollectFilteredToggle, State.AutoCollectFiltered, "🌱 Auto Collect (Filtered)")
        local stopFull = isToggleActive(collectStopWhenFullToggle, State.Collect_StopWhenFull)

        if (collectAll or collectFiltered) then
            if stopFull and isBackpackFull() then
                task.wait(1)
            else
                local batch = {}
                local farmFolder = Workspace:FindFirstChild("Farm") or Workspace

                for _, farm in ipairs(farmFolder:GetChildren()) do
                    if not (collectAll or collectFiltered) then break end
                    if stopFull and isBackpackFull() then break end

                    local important = farm:FindFirstChild("Important")
                    local plantsFolder = important and important:FindFirstChild("Plants_Physical")
                    if plantsFolder then
                        for _, plant in ipairs(plantsFolder:GetChildren()) do
                            if not (collectAll or collectFiltered) then break end
                            if stopFull and isBackpackFull() then break end

                            local fruitsFolder = plant:FindFirstChild("Fruits")
                            if fruitsFolder then
                                for _, fg in ipairs(fruitsFolder:GetChildren()) do
                                    if not (collectAll or collectFiltered) then break end
                                    if stopFull and isBackpackFull() then break end

                                    local shouldCollect = false
                                    if collectAll then
                                        shouldCollect = true
                                    elseif collectFiltered then
                                        local info = getFruitGroupInfo(plant, fg)
                                        if matchesCollectFilters(info) then
                                            shouldCollect = true
                                        end
                                    end

                                    if shouldCollect then
                                        table.insert(batch, fg)
                                        if #batch >= State.BatchSize then
                                            pcall(function()
                                                CollectRemote:FireServer(batch)
                                            end)
                                            batch = {}
                                            task.wait(0.06)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end

                if #batch > 0 and (collectAll or collectFiltered) then
                    pcall(function()
                        CollectRemote:FireServer(batch)
                    end)
                    batch = {}
                end
            end
        end
    end
end)

-- =========================================================================
-- Smart Auto-Sell Engine
-- =========================================================================
task.spawn(function()
    while true do
        task.wait(State.SellCheckDelay)
        local autoSell = isToggleActive(autoSellToggle, State.AutoSell, "💰 Auto Sell")
        local waitMax = isToggleActive(sellWaitMaxToggle, State.Sell_WaitMaxBackpack)

        if autoSell then
            local shouldRunSell = not waitMax or isBackpackFull()
            if shouldRunSell then
                local backpack = LocalPlayer:FindFirstChild("Backpack")
                if backpack then
                    local hasExclusions = (getUIListVal(sellExcludeFruitListObj, "None") ~= "None")
                        or (getUIListVal(sellExcludeCategoryListObj, "None") ~= "None")
                        or (getUIListVal(sellExcludeVariantListObj, "None") ~= "None")
                        or (getUIListVal(sellExcludeMutationListObj, "None") ~= "None")
                        or ((State.Sell_Weight or 0) > 0)

                    if not hasExclusions then
                        pcall(function()
                            SellInvRemote:FireServer()
                        end)
                    else
                        for _, tool in ipairs(backpack:GetChildren()) do
                            if not isToggleActive(autoSellToggle, State.AutoSell) then break end
                            if tool:IsA("Tool") then
                                local info = getToolInfo(tool)
                                if shouldSellTool(info) then
                                    pcall(function()
                                        SellInvRemote:FireServer()
                                    end)
                                    task.wait(0.2)
                                    break
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
-- UI Tabs & Control Layout
-- =========================================================================
local farmTab = Hub.createTabButton("Farm", "🌱 Auto Farm", "rbxassetid://10723407389", true)
local settingsTab = Hub.createTabButton("Settings", "⚙️ Settings", "rbxassetid://10723407392", false)

-- ==========================================
-- Section: Collection
-- ==========================================
Hub.CreateSection(farmTab, "📦 Collection")

autoCollectAllToggle = Hub.CreateToggle(farmTab, "⚡ Auto Collect ALL (No Filter)", "Instantly vacuums EVERY fruit on the farm without applying any filters", false, function(v)
    State.AutoCollectAll = (v ~= nil and v) or not State.AutoCollectAll
end)

autoCollectFilteredToggle = Hub.CreateToggle(farmTab, "🌱 Auto Collect (Filtered)", "Collects fruits matching your selected filters (if none selected, does nothing)", false, function(v)
    State.AutoCollectFiltered = (v ~= nil and v) or not State.AutoCollectFiltered
end)

collectStopWhenFullToggle = Hub.CreateToggle(farmTab, "Stop When Backpack Full", "Halts collection automatically when your backpack reaches capacity", false, function(v)
    State.Collect_StopWhenFull = (v ~= nil and v) or not State.Collect_StopWhenFull
end)

-- Collection Dropdowns
local variantNames = {"None", "Silver", "Gold", "Diamond", "Rainbow", "Basic"}
local variantItems = {}
for _, name in ipairs(variantNames) do table.insert(variantItems, {Name = name}) end
collectVariantListObj = Hub.CreateList(farmTab, "Collect: Target Variant", variantItems, 160, true)

local mutationItems = {}
for _, name in ipairs(allAvailableMutations) do table.insert(mutationItems, {Name = name}) end
collectMutationListObj = Hub.CreateList(farmTab, "Collect: Target Mutation (Traits)", mutationItems, 220, true)

local specificFruitItems = {}
for _, name in ipairs(allAvailablePlants) do table.insert(specificFruitItems, {Name = name}) end
collectFruitListObj = Hub.CreateList(farmTab, "Collect: Specific Fruit", specificFruitItems, 220, true)

local categoryItems = {}
for _, name in ipairs(allAvailableCategories) do table.insert(categoryItems, {Name = name}) end
collectCategoryListObj = Hub.CreateList(farmTab, "Collect: Fruit Category", categoryItems, 180, true)

collectWeightModeListObj = Hub.CreateList(farmTab, "Collect: Weight Mode", {
    {Name = "Above"},
    {Name = "Lower"}
}, 110, true)

Hub.CreateTextBox(farmTab, "Collect: Weight Multiplier", "Enter weight threshold (0 = inactive)", function(text)
    local num = tonumber(text)
    State.Collect_Weight = num or 0
end)

-- ==========================================
-- Section: Sell
-- ==========================================
Hub.CreateSection(farmTab, "💰 Sell")

autoSellToggle = Hub.CreateToggle(farmTab, "💰 Auto Sell", "Automatically sells fruits from your inventory", false, function(v)
    State.AutoSell = (v ~= nil and v) or not State.AutoSell
end)

sellWaitMaxToggle = Hub.CreateToggle(farmTab, "Wait Until Max Backpack", "Only triggers auto-sell when backpack capacity is reached", false, function(v)
    State.Sell_WaitMaxBackpack = (v ~= nil and v) or not State.Sell_WaitMaxBackpack
end)

-- Sell Exclusion Dropdowns
sellExcludeVariantListObj = Hub.CreateList(farmTab, "Sell: Exclude Variant", variantItems, 160, true)
sellExcludeMutationListObj = Hub.CreateList(farmTab, "Sell: Exclude Mutation", mutationItems, 220, true)
sellExcludeFruitListObj = Hub.CreateList(farmTab, "Sell: Exclude Specific Fruit", specificFruitItems, 220, true)
sellExcludeCategoryListObj = Hub.CreateList(farmTab, "Sell: Exclude Category", categoryItems, 180, true)

sellWeightModeListObj = Hub.CreateList(farmTab, "Sell: Exclude Weight Mode", {
    {Name = "Above"},
    {Name = "Lower"}
}, 110, true)

Hub.CreateTextBox(farmTab, "Sell: Exclude Weight Multiplier", "Enter weight threshold to exclude (0 = none)", function(text)
    local num = tonumber(text)
    State.Sell_Weight = num or 0
end)

-- ==========================================
-- Settings Tab
-- ==========================================
Hub.CreateList(settingsTab, "Batch Collection Size", {
    {Name = "15 per batch"},
    {Name = "25 per batch"},
    {Name = "50 per batch"},
    {Name = "100 per batch"}
}, 140, true)

Hub.CreateList(settingsTab, "Harvest Speed / Delay", {
    {Name = "Ultra Fast (0.05s)"},
    {Name = "Fast (0.1s)"},
    {Name = "Normal (0.15s)"},
    {Name = "Safe (0.3s)"}
}, 140, true)

Hub.CreateList(settingsTab, "Max Backpack Threshold", {
    {Name = "250 Tools"},
    {Name = "500 Tools"},
    {Name = "1000 Tools"},
    {Name = "2000 Tools"},
    {Name = "5000 Tools"}
}, 140, true)

print("[Unknown Hub] Grow a Garden Module (Bug Fixes & Continuous Selling) Loaded Successfully!")
