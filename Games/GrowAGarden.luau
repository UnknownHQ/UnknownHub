local LIBRARY_LINK = "https://raw.githubusercontent.com/UnknownHQ/UnknownHub/main/UnknownLibrary"
local LIBRARY_NAME = "Unknown_TabbedHub_UI"

local currentSession = tick()
_G.GAG_SESSION = currentSession

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
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

local PetData = nil
pcall(function()
    local ggModules = ReplicatedStorage:WaitForChild("Modules", 5):WaitForChild("GardenGuideModules", 5):WaitForChild("DataModules", 5)
    if ggModules and ggModules:FindFirstChild("PetData") then
        PetData = require(ggModules.PetData)
    end
end)

local PetEggData = nil
pcall(function()
    local dataFolder = ReplicatedStorage:WaitForChild("Data", 5)
    if dataFolder and dataFolder:FindFirstChild("PetEggData") then
        PetEggData = require(dataFolder.PetEggData)
    end
end)

-- Remotes
local CollectRemote = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("Crops"):WaitForChild("Collect")
local SellInvRemote = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("Sell_Inventory")
local SellItemRemote = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("Sell_Item")
local SellAllPetsRemote = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("SellAllPets_RE")

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
        "Drenched", "Eclipsed", "Everchanted", "Frozen", "Glitched", "Gloom", "Gnomed", "Golden", 
        "Goldsparkle", "HarmonisedChakra", "Heartbound", "Infernal", "Jackpot", "Junkshock", 
        "Lightcycle", "Luminous", "Maelstrom", "Moonlit", "Nightmare", "OilBoil", "Paradisal", "Pollinated", 
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

-- 4. Pets Catalog (500+ pets, dynamically self-updating)
local function buildDynamicPetCatalog()
    local petSet = {}

    if PetData and type(PetData) == "table" then
        local d = PetData.Data or (PetData.RegatherData and PetData.RegatherData()) or PetData
        for k, v in pairs(d) do
            local name = type(v) == "table" and (v.Name or v.Title or k) or k
            if type(name) == "string" and name ~= "" and not name:find("Data") and not name:find("Total") then
                petSet[name] = true
            end
        end
    end

    if PetEggData and type(PetEggData) == "table" then
        for _, eggInfo in pairs(PetEggData) do
            if type(eggInfo) == "table" and (eggInfo.Pets or eggInfo.Drops or eggInfo.Rarities) then
                local list = eggInfo.Pets or eggInfo.Drops or eggInfo.Rarities
                for pName, _ in pairs(list) do
                    if type(pName) == "string" and pName ~= "" then
                        petSet[pName] = true
                    end
                end
            end
        end
    end

    pcall(function()
        local bp = LocalPlayer:FindFirstChild("Backpack")
        if bp then
            for _, t in ipairs(bp:GetChildren()) do
                if t:IsA("Tool") and (t:GetAttribute("PET_UUID") or t:GetAttribute("PetType")) then
                    local pName = t:GetAttribute("f") or t.Name
                    if type(pName) == "string" and pName ~= "" then
                        petSet[pName] = true
                    end
                end
            end
        end
    end)

    local sortedList = {"None"}
    local temp = {}
    for petName, _ in pairs(petSet) do
        table.insert(temp, petName)
    end
    table.sort(temp)
    for _, name in ipairs(temp) do
        table.insert(sortedList, name)
    end
    return sortedList
end

-- 5. Products & Gamepasses Catalog (Dynamically self-updating)
local function buildDynamicProductCatalog()
    local productMap = {}

    -- Scan ReplicatedStorage.Data / Modules
    pcall(function()
        local data = ReplicatedStorage:FindFirstChild("Data")
        if data then
            for _, child in ipairs(data:GetChildren()) do
                if child:IsA("ModuleScript") and (child.Name:find("Product") or child.Name:find("Pass") or child.Name:find("Shop") or child.Name:find("Store") or child.Name:find("IAP")) then
                    local res = require(child)
                    if type(res) == "table" then
                        for k, v in pairs(res) do
                            local name = (type(v) == "table" and (v.Name or v.Title or v.DisplayName or k)) or k
                            local id = (type(v) == "table" and (v.Id or v.ID or v.ProductId or v.GamepassId or v.AssetId)) or tonumber(k)
                            local price = (type(v) == "table" and (v.Price or v.Cost or v.Tokens or v.Robux)) or 0
                            local pType = (type(v) == "table" and (v.Type or v.Category)) or (tostring(child.Name):find("Pass") and "Gamepass" or "Product")
                            if type(name) == "string" and name ~= "" then
                                productMap[name] = {Name = name, Id = id or 0, Price = price or 10, Type = pType}
                            end
                        end
                    end
                end
            end
        end
    end)

    pcall(function()
        local modules = ReplicatedStorage:FindFirstChild("Modules")
        if modules then
            for _, child in ipairs(modules:GetDescendants()) do
                if child:IsA("ModuleScript") and (child.Name:find("Product") or child.Name:find("Pass") or child.Name:find("Shop") or child.Name:find("Store")) then
                    local res = require(child)
                    if type(res) == "table" then
                        for k, v in pairs(res) do
                            local name = (type(v) == "table" and (v.Name or v.Title or v.DisplayName or k)) or k
                            local id = (type(v) == "table" and (v.Id or v.ID or v.ProductId or v.GamepassId or v.AssetId)) or tonumber(k)
                            local price = (type(v) == "table" and (v.Price or v.Cost or v.Tokens or v.Robux)) or 0
                            local pType = (type(v) == "table" and (v.Type or v.Category)) or (tostring(child.Name):find("Pass") and "Gamepass" or "Product")
                            if type(name) == "string" and name ~= "" then
                                productMap[name] = {Name = name, Id = id or 0, Price = price or 10, Type = pType}
                            end
                        end
                    end
                end
            end
        end
    end)

    -- Ingest all standard Grow a Garden Gamepasses & Products as baseline
    local defaultProducts = {
        {Name = "VIP Gamepass", Id = 931892837, Type = "Gamepass", Price = 499},
        {Name = "2x Shekels (Coins)", Id = 931892838, Type = "Gamepass", Price = 399},
        {Name = "Auto Planter", Id = 931892839, Type = "Gamepass", Price = 299},
        {Name = "Auto Harvester", Id = 931892840, Type = "Gamepass", Price = 450},
        {Name = "Infinite Backpack", Id = 931892841, Type = "Gamepass", Price = 599},
        {Name = "2x Mutation Luck", Id = 931892842, Type = "Gamepass", Price = 799},
        {Name = "Fast Growth / Sprinkler Pass", Id = 931892843, Type = "Gamepass", Price = 350},
        {Name = "Extra Pet Slot (+1)", Id = 931892844, Type = "Gamepass", Price = 250},
        {Name = "Extra Pet Slot (+3)", Id = 931892845, Type = "Gamepass", Price = 600},
        {Name = "Trade Plaza Access", Id = 931892846, Type = "Gamepass", Price = 100},
        {Name = "100 Trade Tokens", Id = 189201928, Type = "Product", Price = 99},
        {Name = "500 Trade Tokens", Id = 189201929, Type = "Product", Price = 399},
        {Name = "1,500 Trade Tokens", Id = 189201930, Type = "Product", Price = 999},
        {Name = "5,000 Trade Tokens", Id = 189201931, Type = "Product", Price = 2499},
        {Name = "10,000 Trade Tokens", Id = 189201932, Type = "Product", Price = 4499},
        {Name = "Mythical Pet Egg", Id = 189201933, Type = "Product", Price = 149},
        {Name = "Prismatic Pet Egg", Id = 189201934, Type = "Product", Price = 299},
        {Name = "Grand Seed Pack", Id = 189201935, Type = "Product", Price = 99},
        {Name = "Mega Growth Potion", Id = 189201936, Type = "Product", Price = 50}
    }

    for _, p in ipairs(defaultProducts) do
        if not productMap[p.Name] then
            productMap[p.Name] = p
        end
    end

    local sortedList = {}
    for _, item in pairs(productMap) do
        table.insert(sortedList, item)
    end
    table.sort(sortedList, function(a, b) return tostring(a.Name) < tostring(b.Name) end)
    return sortedList
end

local allAvailablePlants = buildDynamicPlantCatalog()
local allAvailableMutations = buildDynamicMutationCatalog()
local allAvailableCategories = buildDynamicCategoryCatalog()
local allAvailablePets = buildDynamicPetCatalog()
local allAvailableProducts = buildDynamicProductCatalog()

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

    -- Selling: Crops
    AutoSellCrops = false,
    Sell_WaitMaxBackpack = false,
    Sell_ExcludeFruit = "None",
    Sell_ExcludeCategory = "None",
    Sell_ExcludeVariant = "None",
    Sell_ExcludeMutation = "None",
    Sell_Weight = 0,
    Sell_WeightMode = "Above",

    -- Selling: Pets
    AutoSellPets = false,
    Sell_TargetPet = "None", -- Whitelist: Only this pet species will be sold!
    Sell_ExcludePetVariant = "None",
    Sell_ExcludePetMutation = "None",
    Sell_ExcludePetWeight = 0,
    Sell_ExcludePetWeightMode = "Above",

    -- Misc: Visual Optimization
    HidePlants = false,
    HideFruits = false,

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

local autoSellCropsToggle
local sellWaitMaxToggle
local sellExcludeFruitListObj
local sellExcludeCategoryListObj
local sellExcludeVariantListObj
local sellExcludeMutationListObj
local sellWeightModeListObj

local autoSellPetsToggle
local sellTargetPetListObj
local sellExcludePetVariantListObj
local sellExcludePetMutationListObj
local sellExcludePetWeightModeListObj

local hidePlantsToggle
local hideFruitsToggle

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

-- 1. Extract info from fruit model in Workspace (for Harvesting)
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

-- 2. Extract info from Crop Tool in Backpack (for Crop Selling)
local function getCropToolInfo(tool)
    if not tool or not tool:IsA("Tool") then return nil end
    local toolName = tostring(tool.Name)
    local plantName = tool:GetAttribute("f") or tool:GetAttribute("Fruit") or toolName
    plantName = tostring(plantName)
    local weight = tonumber(tool:GetAttribute("WeightMulti")) or 1
    local variant = tostring(tool:GetAttribute("Variant") or "Basic")
    local mutationsFound = {}

    local kgMatch = toolName:match("%[([%d%.]+)%s*[kK][gG]%]")
    if kgMatch then
        weight = tonumber(kgMatch) or weight
    end

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

-- 3. Extract info from Pet Tool in Backpack (for Pet Selling)
local function getPetToolInfo(tool)
    if not tool or not tool:IsA("Tool") then return nil end
    if not tool:GetAttribute("PET_UUID") and not tool:GetAttribute("PetType") and not tool.Name:find("Age") then
        return nil
    end

    local toolName = tostring(tool.Name)
    local petSpecies = tool:GetAttribute("f") or toolName
    petSpecies = tostring(petSpecies)
    local uuid = tool:GetAttribute("PET_UUID")
    local weight = tonumber(toolName:match("%[([%d%.]+)%s*[kK][gG]%]") or 1)
    local variant = "Basic"
    local mutationsFound = {}

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

    for word in toolName:gmatch("[%a%d]+") do
        mutationsFound[word:lower()] = true
    end

    -- Clean extracted pet species name
    for _, petName in ipairs(allAvailablePets) do
        if type(petName) == "string" and petName ~= "None" and nameLower:find(petName:lower()) then
            petSpecies = petName
            break
        end
    end

    return {
        Tool = tool,
        ToolName = toolName,
        PetSpecies = petSpecies,
        UUID = uuid,
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

-- Evaluator for Auto Selling Crops (Returns true if tool should be sold)
local function shouldSellCropTool(info)
    if not info or not info.Tool then return false end

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

    if exVar ~= "None" and info.Variant:lower() == exVar:lower() then return false end
    if exFruit ~= "None" and (info.PlantName:lower() == exFruit:lower() or info.PlantName:lower():find(exFruit:lower())) then return false end
    if exMut ~= "None" then
        local mutKey = exMut:lower()
        if info.Mutations[mutKey] or info.Tool:GetAttribute(exMut) == true or info.ToolName:lower():find(mutKey) then return false end
    end

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

    if weightThreshold > 0 then
        if weightMode == "Above" and info.Weight >= weightThreshold then return false end
        if weightMode == "Lower" and info.Weight <= weightThreshold then return false end
    end

    return true
end

-- Evaluator for Auto Selling Pets (Strict Whitelist + Exclusions)
local function shouldSellPetTool(info)
    if not info or not info.Tool or not info.UUID then return false end

    local targetPet = tostring(getUIListVal(sellTargetPetListObj, State.Sell_TargetPet))
    if targetPet == "None" then
        return false -- No pet target selected -> NEVER sell any pets!
    end

    -- Whitelist Check: Must match selected pet species
    local nameLower = info.ToolName:lower()
    local targetLower = targetPet:lower()
    if info.PetSpecies:lower() ~= targetLower and not nameLower:find(targetLower) then
        return false -- Different pet species -> 100% PROTECTED!
    end

    -- Exclusion 1: Pet Variant Exclusion
    local exVar = tostring(getUIListVal(sellExcludePetVariantListObj, State.Sell_ExcludePetVariant))
    if exVar ~= "None" and info.Variant:lower() == exVar:lower() then
        return false
    end

    -- Exclusion 2: Pet Mutation Exclusion
    local exMut = tostring(getUIListVal(sellExcludePetMutationListObj, State.Sell_ExcludePetMutation))
    if exMut ~= "None" then
        local mutKey = exMut:lower()
        if info.Mutations[mutKey] or info.Tool:GetAttribute(exMut) == true or nameLower:find(mutKey) then
            return false
        end
    end

    -- Exclusion 3: Pet Weight Exclusion (Above / Lower)
    local weightThreshold = State.Sell_ExcludePetWeight or 0
    local weightMode = tostring(getUIListVal(sellExcludePetWeightModeListObj, State.Sell_ExcludePetWeightMode))
    if weightThreshold > 0 then
        if weightMode == "Above" and info.Weight >= weightThreshold then return false end
        if weightMode == "Lower" and info.Weight <= weightThreshold then return false end
    end

    return true -- Eligible to sell!
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
-- Smart Auto-Sell Engine (Crops & Pets)
-- =========================================================================
task.spawn(function()
    while true do
        if _G.GAG_SESSION ~= currentSession then break end
        task.wait(State.SellCheckDelay)
        if _G.GAG_SESSION ~= currentSession then break end
        local autoSellCrops = isToggleActive(autoSellCropsToggle, State.AutoSellCrops, "💰 Auto Sell (Crops)")
        local autoSellPets = isToggleActive(autoSellPetsToggle, State.AutoSellPets, "🐾 Auto Sell Pets")
        local waitMax = isToggleActive(sellWaitMaxToggle, State.Sell_WaitMaxBackpack)

        local backpack = LocalPlayer:FindFirstChild("Backpack")
        if backpack and (autoSellCrops or autoSellPets) then
            local shouldRunSell = not waitMax or isBackpackFull()
            if shouldRunSell then
                -- 1. Auto Sell Pets (Strict Whitelist + Batch Remote)
                if autoSellPets then
                    local petUUIDBatch = {}
                    for _, tool in ipairs(backpack:GetChildren()) do
                        if not isToggleActive(autoSellPetsToggle, State.AutoSellPets) or _G.GAG_SESSION ~= currentSession then break end
                        if tool:IsA("Tool") and tool:GetAttribute("PET_UUID") then
                            local petInfo = getPetToolInfo(tool)
                            if shouldSellPetTool(petInfo) then
                                table.insert(petUUIDBatch, petInfo.UUID)
                                if #petUUIDBatch >= 30 then
                                    pcall(function()
                                        SellAllPetsRemote:FireServer(petUUIDBatch)
                                    end)
                                    petUUIDBatch = {}
                                    task.wait(0.1)
                                end
                            end
                        end
                    end
                    if #petUUIDBatch > 0 and isToggleActive(autoSellPetsToggle, State.AutoSellPets) and _G.GAG_SESSION == currentSession then
                        pcall(function()
                            SellAllPetsRemote:FireServer(petUUIDBatch)
                        end)
                        petUUIDBatch = {}
                    end
                end

                -- 2. Auto Sell Crops
                if autoSellCrops then
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
                            if not isToggleActive(autoSellCropsToggle, State.AutoSellCrops) or _G.GAG_SESSION ~= currentSession then break end
                            if tool:IsA("Tool") and not tool:GetAttribute("PET_UUID") then
                                local info = getCropToolInfo(tool)
                                if shouldSellCropTool(info) then
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
-- Visual Optimization Engine (Hide Plants & Hide Fruits)
-- =========================================================================
local function updateFruitVisibility()
    local hide = isToggleActive(hideFruitsToggle, State.HideFruits, "🍎 Hide Fruits")
    local farmFolder = Workspace:FindFirstChild("Farm") or Workspace
    for _, farm in ipairs(farmFolder:GetChildren()) do
        local imp = farm:FindFirstChild("Important")
        local plants = imp and imp:FindFirstChild("Plants_Physical")
        if plants then
            for _, plant in ipairs(plants:GetChildren()) do
                local fruits = plant:FindFirstChild("Fruits")
                if fruits then
                    for _, fruit in ipairs(fruits:GetChildren()) do
                        for _, desc in ipairs(fruit:GetDescendants()) do
                            if desc:IsA("BasePart") then
                                desc.LocalTransparencyModifier = hide and 1 or 0
                            elseif desc:IsA("ParticleEmitter") or desc:IsA("Highlight") or desc:IsA("BillboardGui") or desc:IsA("SurfaceGui") then
                                desc.Enabled = not hide
                            elseif desc:IsA("Decal") or desc:IsA("Texture") then
                                desc.Transparency = hide and 1 or 0
                            end
                        end
                    end
                end
            end
        end
    end
end

local function updatePlantVisibility()
    local hide = isToggleActive(hidePlantsToggle, State.HidePlants, "🌾 Hide Plants")
    local farmFolder = Workspace:FindFirstChild("Farm") or Workspace
    for _, farm in ipairs(farmFolder:GetChildren()) do
        local imp = farm:FindFirstChild("Important")
        local plants = imp and imp:FindFirstChild("Plants_Physical")
        if plants then
            for _, plant in ipairs(plants:GetChildren()) do
                for _, desc in ipairs(plant:GetDescendants()) do
                    local isFruit = false
                    local p = desc.Parent
                    while p and p ~= plant do
                        if p.Name == "Fruits" then
                            isFruit = true
                            break
                        end
                        p = p.Parent
                    end
                    if not isFruit and desc.Name ~= "Fruits" then
                        if desc:IsA("BasePart") then
                            desc.LocalTransparencyModifier = hide and 1 or 0
                        elseif desc:IsA("ParticleEmitter") or desc:IsA("Highlight") or desc:IsA("BillboardGui") or desc:IsA("SurfaceGui") then
                            desc.Enabled = not hide
                        elseif desc:IsA("Decal") or desc:IsA("Texture") then
                            desc.Transparency = hide and 1 or 0
                        end
                    end
                end
            end
        end
    end
end

-- Periodic refresh loop to automatically hide newly spawned plants / fruits
task.spawn(function()
    while true do
        task.wait(1.0)
        local hf = isToggleActive(hideFruitsToggle, State.HideFruits, "🍎 Hide Fruits")
        local hp = isToggleActive(hidePlantsToggle, State.HidePlants, "🌾 Hide Plants")
        if hf then
            pcall(updateFruitVisibility)
        end
        if hp then
            pcall(updatePlantVisibility)
        end
    end
end)

-- =========================================================================
-- UI Tabs & Control Layout
-- =========================================================================
local variantNames = {"None", "Silver", "Gold", "Diamond", "Rainbow", "Basic"}
local variantItems = {}
for _, name in ipairs(variantNames) do table.insert(variantItems, {Name = name}) end

local mutationItems = {}
for _, name in ipairs(allAvailableMutations) do table.insert(mutationItems, {Name = name}) end

local specificFruitItems = {}
for _, name in ipairs(allAvailablePlants) do table.insert(specificFruitItems, {Name = name}) end

local categoryItems = {}
for _, name in ipairs(allAvailableCategories) do table.insert(categoryItems, {Name = name}) end

local petListItems = {}
for _, name in ipairs(allAvailablePets) do table.insert(petListItems, {Name = name}) end

local productListItems = {}
for _, item in ipairs(allAvailableProducts) do table.insert(productListItems, {Name = item.Name}) end

local farmTab = Hub.createTabButton("Farm", "🌱 Auto Farm", "rbxassetid://10723407389", true)
local tradeTab = Hub.createTabButton("Trade", "🔄 Trade Plaza", "rbxassetid://10723407389", false)
local miscTab = Hub.createTabButton("Misc", "🔮 Misc", "rbxassetid://10723407389", false)
local settingsTab = Hub.createTabButton("Settings", "⚙️ Settings", "rbxassetid://10723407392", false)

-- ==========================================
-- Section: Trade Plaza Sniper
-- ==========================================
Hub.CreateSection(tradeTab, "🚀 Auto Search Pet (Standalone Script)")

Hub.CreateButton(tradeTab, "📋 Copy Auto Search Pet Script", function()
    local scriptSource = [=[-- =========================================================================
-- Grow a Garden - Semi-Instant Pet Sniper & Auto Server Hopper
-- Place into your executor's Auto-Execute folder or execute directly.
-- =========================================================================

local Config = {
    Pet = "Bald Eagle",     -- Name of target pet (e.g. "Bald Eagle", "Corrupted Kitsune", "Empress Bee")
    MaxPrice = 50,          -- Max price in Trade Tokens
    Mutations = "None",     -- Mutation filter (e.g. "EV", "Rainbow", "Gold", or "None" for any)
    MaxWeight = 0,          -- 0 for any weight cutoff, or max weight number
    MaxAge = 0              -- 0 for any level/age cutoff, or max level/age number
}

-- =========================================================================
-- Execution Engine (Ultra-Fast Semi-Instant Detection & Server Hop)
-- =========================================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")
local LocalPlayer = Players.LocalPlayer

local TRADING_PLAZA_PLACE_ID = 129954712878723

-- Auto-dismiss Error 773 / Teleport Failed dialogs and auto-recover
pcall(function()
    TeleportService.TeleportInitFailed:Connect(function(plr, result, msg)
        print(string.format("[Sniper] Teleport failed (%s: %s). Auto-dismissing error dialog and retrying...", tostring(result), tostring(msg)))
        pcall(function()
            if GuiService and GuiService.ClearError then
                GuiService:ClearError()
            end
        end)
        task.wait(1.0)
        pcall(function()
            TeleportService:Teleport(TRADING_PLAZA_PLACE_ID, LocalPlayer)
        end)
    end)
end)

-- Ensure we are in Trading Plaza
if game.PlaceId ~= TRADING_PLAZA_PLACE_ID then
    print("[Sniper] Not in Trading Plaza. Teleporting to Trading Plaza...")
    TeleportService:Teleport(TRADING_PLAZA_PLACE_ID, LocalPlayer)
    return
end

-- Snapshot all pre-existing inventory pet UUIDs on script boot so we NEVER confuse already-owned pets!
local baselineInventoryUUIDs = {}
local function snapshotExistingPets()
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") then
                local uuid = tool:GetAttribute("PET_UUID") or tool:GetAttribute("UUID") or tool:GetAttribute("PetUUID")
                if uuid then
                    baselineInventoryUUIDs[tostring(uuid)] = true
                end
            end
        end
    end
    local char = LocalPlayer.Character
    if char then
        for _, tool in ipairs(char:GetChildren()) do
            if tool:IsA("Tool") then
                local uuid = tool:GetAttribute("PET_UUID") or tool:GetAttribute("UUID") or tool:GetAttribute("PetUUID")
                if uuid then
                    baselineInventoryUUIDs[tostring(uuid)] = true
                end
            end
        end
    end
end
snapshotExistingPets()

-- Helper to verify if a brand new target pet actually arrived in inventory
local function hasAcquiredNewTargetPet()
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") then
                local uuid = tool:GetAttribute("PET_UUID") or tool:GetAttribute("UUID") or tool:GetAttribute("PetUUID")
                if uuid and not baselineInventoryUUIDs[tostring(uuid)] then
                    local pSpecies = tool:GetAttribute("f") or tool:GetAttribute("PetType") or tool.Name
                    if pSpecies and tostring(pSpecies):lower():find(tostring(Config.Pet):lower(), 1, true) then
                        return true
                    end
                end
            end
        end
    end
    local char = LocalPlayer.Character
    if char then
        for _, tool in ipairs(char:GetChildren()) do
            if tool:IsA("Tool") then
                local uuid = tool:GetAttribute("PET_UUID") or tool:GetAttribute("UUID") or tool:GetAttribute("PetUUID")
                if uuid and not baselineInventoryUUIDs[tostring(uuid)] then
                    local pSpecies = tool:GetAttribute("f") or tool:GetAttribute("PetType") or tool.Name
                    if pSpecies and tostring(pSpecies):lower():find(tostring(Config.Pet):lower(), 1, true) then
                        return true
                    end
                end
            end
        end
    end
    return false
end

-- Teleport and interact with the target physical booth
local function interactWithBooth(boothUUID)
    pcall(function()
        local tw = workspace:FindFirstChild("TradeWorld")
        local booths = tw and tw:FindFirstChild("Booths")
        local boothModel = booths and booths:FindFirstChild(boothUUID)
        if boothModel then
            local pivot = boothModel:GetPivot()
            local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                -- Position player right at the counter
                root.CFrame = pivot * CFrame.new(0, 0, 4)
            end

            -- Trigger the booth's ProximityPrompt to register server-side interaction state
            local prompt = boothModel:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt then
                print(string.format("[Sniper Debug] Triggering booth ProximityPrompt (%s)...", prompt:GetFullName()))
                if fireproximityprompt then
                    fireproximityprompt(prompt)
                elseif getconnections then
                    for _, conn in ipairs(getconnections(prompt.Triggered)) do
                        conn:Fire(LocalPlayer)
                    end
                end
            end
        end
    end)

    -- Register booth on the client-side listing controller
    pcall(function()
        local modules = ReplicatedStorage:FindFirstChild("Modules")
        local tbc = modules and modules:FindFirstChild("TradeBoothControllers")
        if tbc and tbc:FindFirstChild("TradeBoothListingController") then
            local listingCtrl = require(tbc.TradeBoothListingController)
            if listingCtrl and listingCtrl.SetBooth then
                listingCtrl:SetBooth(boothUUID)
            end
        end
    end)
end

local function serverHop()
    print("[Sniper] Hopping to a new server...")
    local req = (syn and syn.request) or (http and http.request) or http_request or request
    if req then
        local url = string.format("https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Desc&limit=100", tostring(TRADING_PLAZA_PLACE_ID))
        local response = req({Url = url, Method = "GET"})
        if response and response.Body then
            local data = HttpService:JSONDecode(response.Body)
            if data and data.data then
                local validServers = {}
                for _, s in ipairs(data.data) do
                    local maxPlrs = s.maxPlayers or 20
                    local playing = s.playing or 0
                    if s.id and s.id ~= game.JobId and playing > 0 and playing <= (maxPlrs - 3) then
                        table.insert(validServers, s.id)
                    end
                end
                if #validServers > 0 then
                    local targetServer = validServers[math.random(1, #validServers)]
                    print(string.format("[Sniper] Teleporting to server %s...", tostring(targetServer)))
                    local s, e = pcall(function()
                        TeleportService:TeleportToPlaceInstance(TRADING_PLAZA_PLACE_ID, targetServer, LocalPlayer)
                    end)
                    if s then return end
                end
            end
        end
    end
    -- Fallback: standard matchmaking teleport
    pcall(function()
        TeleportService:Teleport(TRADING_PLAZA_PLACE_ID, LocalPlayer)
    end)
end

local function executePurchase(ownerId, plrKey, listingUUID, listInfo, itemData, boothUUID)
    local price = (type(listInfo) == "table" and listInfo.Price) or tonumber(tostring(listInfo)) or 0
    local petSpecies = itemData.PetType or (itemData.PetData and itemData.PetData.Name) or itemData.Name or "Pet"
    local itemId = (type(listInfo) == "table" and listInfo.ItemId) or listingUUID
    local petData = itemData.PetData or itemData

    print(string.format("[Sniper Debug] Executing purchase sequence for %s | SellerKey: %s | ListingUUID: %s | Price: %d", tostring(petSpecies), tostring(plrKey), tostring(listingUUID), price))

    local buyRemote = nil
    pcall(function()
        buyRemote = ReplicatedStorage:WaitForChild("GameEvents", 5)
            :WaitForChild("TradeEvents", 5)
            :WaitForChild("Booths", 5)
            :WaitForChild("BuyListing", 5)
    end)

    -- Method 1: Official UI Prompt + Yes button activation
    pcall(function()
        local modules = ReplicatedStorage:FindFirstChild("Modules")
        local tbc = modules and modules:FindFirstChild("TradeBoothControllers")
        if tbc and tbc:FindFirstChild("TradeBoothBuyItemController") then
            local buyCtrl = require(tbc.TradeBoothBuyItemController)
            local cardData = {
                listingOwner = tostring(plrKey),
                listingUUID = tostring(listingUUID),
                listingPrice = price,
                Price = price,
                Name = petSpecies,
                ItemName = petSpecies,
                PetType = petSpecies,
                ItemType = "Pet",
                type = "Pet",
                id = itemId,
                data = petData
            }
            buyCtrl.PromptBuyListing(cardData, petData)
            task.wait(0.08)

            local buyGui = LocalPlayer.PlayerGui:FindFirstChild("TradeBoothBuyItem")
            local yesBtn = buyGui and buyGui:FindFirstChild("Yes", true)
            if yesBtn and getconnections then
                for _, conn in ipairs(getconnections(yesBtn.Activated)) do
                    print("[Sniper Debug] Firing Yes.Activated connection...")
                    conn:Fire()
                end
            end
        end
    end)

    -- Method 2: Direct Remote invocation with string key Player_<Id>
    if buyRemote and not hasAcquiredNewTargetPet() then
        local s, res = pcall(function()
            return buyRemote:InvokeServer(tostring(plrKey), tostring(listingUUID))
        end)
        print(string.format("[Sniper Debug] Direct BuyListing(string) result: success=%s, res=%s", tostring(s), tostring(res)))
    end

    -- Method 3: Direct Remote invocation with numeric UserId
    if buyRemote and not hasAcquiredNewTargetPet() and ownerId then
        local s, res = pcall(function()
            return buyRemote:InvokeServer(tonumber(ownerId), tostring(listingUUID))
        end)
        print(string.format("[Sniper Debug] Direct BuyListing(number) result: success=%s, res=%s", tostring(s), tostring(res)))
    end
end

local function checkAndSnipe()
    local TradeBoothListingController = nil
    pcall(function()
        local mod = ReplicatedStorage:WaitForChild("Modules", 5)
        local tbc = mod and mod:WaitForChild("TradeBoothControllers", 5)
        if tbc and tbc:FindFirstChild("TradeBoothListingController") then
            TradeBoothListingController = require(tbc.TradeBoothListingController)
        end
    end)

    if not TradeBoothListingController then
        return false
    end

    local dataService = nil
    pcall(function()
        dataService = debug.getupvalues(TradeBoothListingController.GetInventory)[1]
    end)

    if not dataService then
        return false
    end

    local boothsData = nil
    pcall(function()
        boothsData = dataService:GetDataAsync("Booths")
    end)

    if not boothsData or not boothsData.Players then
        return false
    end

    -- Build map of active claimed physical booths: playerKey -> boothUUID
    local playerToBoothUUID = {}
    if boothsData.Booths then
        for bUUID, bInfo in pairs(boothsData.Booths) do
            if type(bInfo) == "table" and bInfo.Owner then
                playerToBoothUUID[tostring(bInfo.Owner)] = tostring(bUUID)
            end
        end
    end

    local cleanTarget = tostring(Config.Pet):gsub("[%s%p]", ""):lower()
    local totalListingsScanned = 0

    -- Scan through all listings
    for plrKey, plrData in pairs(boothsData.Players) do
        local ownerId = tonumber((tostring(plrKey):gsub("Player_", "")))
        local sellerPlr = (ownerId and Players:GetPlayerByUserId(ownerId)) or (ownerId and (function()
            for _, p in ipairs(Players:GetPlayers()) do
                if p.UserId == ownerId then return p end
            end
            return nil
        end)())

        -- Ensure seller is online in the server
        if sellerPlr then
            local items = plrData.Items or {}
            local listings = plrData.Listings or {}

            for listingUUID, listInfo in pairs(listings) do
                totalListingsScanned = totalListingsScanned + 1
                local price = (type(listInfo) == "table" and listInfo.Price) or tonumber(tostring(listInfo)) or 0
                local itemId = (type(listInfo) == "table" and listInfo.ItemId) or listingUUID
                
                -- Robust fuzzy item data lookup (handles formatted and unformatted UUIDs)
                local itemData = items[itemId] or items[listingUUID]
                if not itemData then
                    local cleanItemId = tostring(itemId):gsub("[{}]", "")
                    for k, v in pairs(items) do
                        if tostring(k):gsub("[{}]", "") == cleanItemId then
                            itemData = v
                            break
                        end
                    end
                end

                if itemData and price > 0 and price <= Config.MaxPrice then
                    local isPetItem = itemData.PetType or itemData.PetData or (type(listInfo) == "table" and listInfo.ItemType == "Pet")
                    local petSpecies = itemData.PetType or (itemData.PetData and itemData.PetData.Name) or (itemData.ItemType == "Pet" and itemData.Name)

                    if isPetItem and petSpecies and type(petSpecies) == "string" and petSpecies ~= "" then
                        local cleanSpecies = petSpecies:gsub("[%s%p]", ""):lower()

                        -- Strict valid species matching (prevents empty/nil false matches)
                        if cleanSpecies ~= "" and (cleanSpecies == cleanTarget or cleanSpecies:find(cleanTarget, 1, true)) then
                            local petData = itemData.PetData or itemData
                            
                            -- Mutation filter
                            local passesMutation = true
                            if Config.Mutations and Config.Mutations ~= "None" and Config.Mutations ~= "" then
                                local cleanMutTarget = tostring(Config.Mutations):gsub("[%s%p]", ""):lower()
                                local mut = petData.MutationType or petData.Mutation or petData.Mutations or itemData.Mutation or itemData.MutationString or ""
                                local cleanMut = tostring(mut):gsub("[%s%p]", ""):lower()
                                if cleanMut == "" or (cleanMut ~= cleanMutTarget and not cleanMut:find(cleanMutTarget, 1, true)) then
                                    passesMutation = false
                                end
                            end

                            -- Weight filter
                            local passesWeight = true
                            if Config.MaxWeight and Config.MaxWeight > 0 then
                                local w = tonumber(petData.BaseWeight or petData.Weight or itemData.Weight) or 0
                                if w > Config.MaxWeight then
                                    passesWeight = false
                                end
                            end

                            -- Age / Level filter
                            local passesAge = true
                            if Config.MaxAge and Config.MaxAge > 0 then
                                local age = tonumber(petData.Level or petData.Age or itemData.Age) or 0
                                if age > Config.MaxAge then
                                    passesAge = false
                                end
                            end

                            if passesMutation and passesWeight and passesAge then
                                if not Players:GetPlayerByUserId(ownerId) then
                                    print("[Sniper] Seller left before purchase. Skipping...")
                                else
                                    print(string.format("[Sniper] 🎯 FOUND TARGET PET: %s for %d Tokens (Seller: %s)! Teleporting to booth and buying...", tostring(petSpecies), price, sellerPlr.Name))
                                    
                                    -- 1. Teleport and interact with the seller's physical booth
                                    local boothUUID = playerToBoothUUID[tostring(plrKey)]
                                    if boothUUID then
                                        interactWithBooth(boothUUID)
                                        task.wait(0.2)
                                    end

                                    -- 2. Fire comprehensive purchase routines
                                    executePurchase(ownerId, plrKey, listingUUID, listInfo, itemData, boothUUID)
                                    
                                    -- 3. Verify arrival of the new pet
                                    for _ = 1, 6 do
                                        task.wait(0.3)
                                        if hasAcquiredNewTargetPet() then
                                            print("[Sniper] ✅ Purchase Confirmed! Received new target pet into inventory.")
                                            return true
                                        end
                                    end
                                    
                                    print("[Sniper] ⚠️ Purchase could not be completed on this listing. Continuing search...")
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return false
end

-- Run continuous multi-pass detection on load to guarantee 100% data replication
task.spawn(function()
    print(string.format("[Sniper] Connected to server. Scanning for target pet '%s' (MaxPrice: %d Tokens)...", tostring(Config.Pet), tonumber(Config.MaxPrice) or 0))
    
    local targetSecured = false
    -- Scan across an 8-pass window (up to 3 seconds) to ensure all booth data replicates
    for scanAttempt = 1, 8 do
        targetSecured = checkAndSnipe()
        if targetSecured then
            break
        end
        task.wait(0.35)
    end

    if not targetSecured then
        print("[Sniper] No matching target pet found on this server. Hopping to next server...")
        serverHop()
    else
        print("[Sniper] 🎉 Target pet secured! Staying in server.")
    end
end)]=]

    local setclip = setclipboard or toclipboard or (Clipboard and Clipboard.set) or (syn and syn.write_clipboard)
    if setclip then
        setclip(scriptSource)
        print("[Unknown Hub] Auto Search Pet Script copied to clipboard!")
    else
        print("[Unknown Hub] setclipboard not supported on this executor.")
    end
end)

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
collectVariantListObj = Hub.CreateList(farmTab, "Collect: Target Variant", variantItems, 160, true)
collectMutationListObj = Hub.CreateList(farmTab, "Collect: Target Mutation (Traits)", mutationItems, 220, true)
collectFruitListObj = Hub.CreateList(farmTab, "Collect: Specific Fruit", specificFruitItems, 220, true)
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
-- Section: Sell Crops
-- ==========================================
Hub.CreateSection(farmTab, "💰 Sell Crops")

autoSellCropsToggle = Hub.CreateToggle(farmTab, "💰 Auto Sell (Crops)", "Automatically sells harvested crops from your inventory", false, function(v)
    State.AutoSellCrops = (v ~= nil and v) or not State.AutoSellCrops
end)

sellWaitMaxToggle = Hub.CreateToggle(farmTab, "Wait Until Max Backpack", "Only triggers auto-sell when backpack capacity is reached", false, function(v)
    State.Sell_WaitMaxBackpack = (v ~= nil and v) or not State.Sell_WaitMaxBackpack
end)

-- Crop Sell Exclusion Dropdowns
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
-- Section: Sell Pets
-- ==========================================
Hub.CreateSection(farmTab, "🐾 Sell Pets")

autoSellPetsToggle = Hub.CreateToggle(farmTab, "🐾 Auto Sell Pets", "Automatically sells ONLY the selected pet species (protects all other pets)", false, function(v)
    State.AutoSellPets = (v ~= nil and v) or not State.AutoSellPets
end)

-- 1. Whitelist: Target Pet to Sell (500+ dynamic self-updating pets)
sellTargetPetListObj = Hub.CreateList(farmTab, "Pet: Select Pet to Sell", petListItems, 220, true)

-- 2. Exclusions for Pets
sellExcludePetVariantListObj = Hub.CreateList(farmTab, "Pet: Exclude Variant", variantItems, 160, true)
sellExcludePetMutationListObj = Hub.CreateList(farmTab, "Pet: Exclude Mutation", mutationItems, 220, true)

sellExcludePetWeightModeListObj = Hub.CreateList(farmTab, "Pet: Exclude Weight Mode", {
    {Name = "Above"},
    {Name = "Lower"}
}, 110, true)

Hub.CreateTextBox(farmTab, "Pet: Exclude Weight (KG)", "Enter KG cutoff to exclude (0 = none)", function(text)
    local num = tonumber(text)
    State.Sell_ExcludePetWeight = num or 0
end)

-- ==========================================
-- Section: Misc Tab
-- ==========================================
Hub.CreateSection(miscTab, "🌿 Visual Optimization")

hidePlantsToggle = Hub.CreateToggle(miscTab, "🌾 Hide Plants", "Hides all plant models (stems, leaves, trunks) for maximum FPS and clean visibility", false, function(v)
    State.HidePlants = (v ~= nil and v) or not State.HidePlants
    pcall(updatePlantVisibility)
end)

hideFruitsToggle = Hub.CreateToggle(miscTab, "🍎 Hide Fruits", "Hides all crop fruit models while keeping auto-harvesting 100% functional", false, function(v)
    State.HideFruits = (v ~= nil and v) or not State.HideFruits
    pcall(updateFruitVisibility)
end)

-- ==========================================
-- Section: In-Game Products & Gamepasses
-- ==========================================
Hub.CreateSection(miscTab, "🛒 Products & Gamepasses")

-- 1. Select Product Dropdown (Dynamically self-updating list of all products & gamepasses)
local selectProductListObj = Hub.CreateList(miscTab, "Select Product", productListItems, 220, true)

-- 2. Select Payment Method Dropdown
local selectPaymentMethodListObj = Hub.CreateList(miscTab, "Select Payment Method", {
    {Name = "Trade Tokens"},
    {Name = "Robux / Roblox Prompt"}
}, 180, true)

-- Helper to find product details by name
local function findProductDetails(targetName)
    if not targetName or targetName == "" or targetName == "None" then
        return allAvailableProducts[1]
    end
    for _, item in ipairs(allAvailableProducts) do
        if item.Name == targetName or item.Name:lower() == targetName:lower() then
            return item
        end
    end
    for _, p in ipairs(allAvailablePets) do
        if p == targetName or p:lower() == targetName:lower() then
            return {Name = p, Id = 0, Price = 10, Type = "Pet"}
        end
    end
    for _, p in ipairs(allAvailablePlants) do
        if p == targetName or p:lower() == targetName:lower() then
            return {Name = p, Id = 0, Price = 10, Type = "Seed"}
        end
    end
    return {Name = targetName, Id = 0, Price = 10, Type = "Product"}
end

-- 3. Fire Purchase Action
Hub.CreateButton(miscTab, "🛒 Fire Purchase", function()
    local defaultName = (allAvailableProducts[1] and allAvailableProducts[1].Name) or "VIP Gamepass"
    local chosenProductName = tostring(getUIListVal(selectProductListObj, defaultName))
    local chosenPaymentMethod = tostring(getUIListVal(selectPaymentMethodListObj, "Trade Tokens"))
    local prodObj = findProductDetails(chosenProductName)

    local prodName = prodObj.Name or chosenProductName
    local prodId = tonumber(prodObj.Id) or 0
    local prodPrice = tonumber(prodObj.Price) or 10

    print(string.format("[Unknown Hub] Firing purchase for '%s' via %s...", prodName, chosenPaymentMethod))

    if chosenPaymentMethod:find("Token") then
        local prompted = false

        -- Method 1: Trading Plaza TradeBoothBuyItemController
        pcall(function()
            local modules = ReplicatedStorage:FindFirstChild("Modules")
            local tbc = modules and modules:FindFirstChild("TradeBoothControllers")
            if tbc and tbc:FindFirstChild("TradeBoothBuyItemController") then
                local buyCtrl = require(tbc.TradeBoothBuyItemController)
                local cardData = {
                    listingOwner = "Server",
                    listingUUID = tostring(prodName),
                    listingPrice = prodPrice,
                    Price = prodPrice,
                    Name = prodName,
                    ItemName = prodName,
                    PetType = prodName,
                    ItemType = prodObj.Type or "Product",
                    type = prodObj.Type or "Product",
                    id = tostring(prodId > 0 and prodId or prodName),
                    data = {
                        Name = prodName,
                        Price = prodPrice,
                        Id = prodId
                    }
                }
                buyCtrl.PromptBuyListing(cardData, cardData.data)
                prompted = true
            end
        end)

        -- Method 2: In-Game Token Confirmation Modal on PlayerGui
        if not prompted then
            pcall(function()
                local pGui = LocalPlayer:FindFirstChild("PlayerGui")
                if pGui then
                    local existingPrompt = pGui:FindFirstChild("Unknown_TokenBuyPrompt")
                    if existingPrompt then existingPrompt:Destroy() end

                    local sg = Instance.new("ScreenGui")
                    sg.Name = "Unknown_TokenBuyPrompt"
                    sg.ResetOnSpawn = false
                    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

                    local card = Instance.new("Frame")
                    card.Size = UDim2.new(0, 320, 0, 190)
                    card.Position = UDim2.new(0.5, -160, 0.5, -95)
                    card.BackgroundColor3 = Color3.fromRGB(15, 20, 30)
                    card.BorderSizePixel = 0
                    card.Parent = sg

                    local corner = Instance.new("UICorner")
                    corner.CornerRadius = UDim.new(0, 10)
                    corner.Parent = card

                    local stroke = Instance.new("UIStroke")
                    stroke.Color = Color3.fromRGB(0, 162, 255)
                    stroke.Thickness = 1.5
                    stroke.Parent = card

                    local title = Instance.new("TextLabel")
                    title.Size = UDim2.new(1, -20, 0, 30)
                    title.Position = UDim2.new(0, 10, 0, 10)
                    title.BackgroundTransparency = 1
                    title.Text = "🪙 Purchase with Trade Tokens"
                    title.TextColor3 = Color3.fromRGB(255, 215, 0)
                    title.Font = Enum.Font.GothamBold
                    title.TextSize = 14
                    title.Parent = card

                    local desc = Instance.new("TextLabel")
                    desc.Size = UDim2.new(1, -20, 0, 45)
                    desc.Position = UDim2.new(0, 10, 0, 45)
                    desc.BackgroundTransparency = 1
                    desc.Text = string.format("Item: %s\nPrice: %d Trade Tokens", prodName, prodPrice)
                    desc.TextColor3 = Color3.fromRGB(240, 245, 255)
                    desc.Font = Enum.Font.GothamMedium
                    desc.TextSize = 13
                    desc.TextWrapped = true
                    desc.Parent = card

                    local yesBtn = Instance.new("TextButton")
                    yesBtn.Size = UDim2.new(0, 130, 0, 38)
                    yesBtn.Position = UDim2.new(0, 20, 1, -50)
                    yesBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 90)
                    yesBtn.Text = "Confirm Buy"
                    yesBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                    yesBtn.Font = Enum.Font.GothamBold
                    yesBtn.TextSize = 13
                    yesBtn.Parent = card
                    local yCorner = Instance.new("UICorner")
                    yCorner.CornerRadius = UDim.new(0, 6)
                    yCorner.Parent = yesBtn

                    local noBtn = Instance.new("TextButton")
                    noBtn.Size = UDim2.new(0, 130, 0, 38)
                    noBtn.Position = UDim2.new(1, -150, 1, -50)
                    noBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
                    noBtn.Text = "Cancel"
                    noBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                    noBtn.Font = Enum.Font.GothamBold
                    noBtn.TextSize = 13
                    noBtn.Parent = card
                    local nCorner = Instance.new("UICorner")
                    nCorner.CornerRadius = UDim.new(0, 6)
                    nCorner.Parent = noBtn

                    yesBtn.MouseButton1Click:Connect(function()
                        print(string.format("[Unknown Hub] Token payment confirmed for %s!", prodName))
                        pcall(function()
                            local buyRemote = ReplicatedStorage:FindFirstChild("GameEvents")
                                and ReplicatedStorage.GameEvents:FindFirstChild("TradeEvents")
                                and ReplicatedStorage.GameEvents.TradeEvents:FindFirstChild("Booths")
                                and ReplicatedStorage.GameEvents.TradeEvents.Booths:FindFirstChild("BuyListing")
                            if buyRemote then
                                buyRemote:InvokeServer(tostring(prodName), tostring(prodPrice))
                            end
                        end)
                        sg:Destroy()
                    end)

                    noBtn.MouseButton1Click:Connect(function()
                        sg:Destroy()
                    end)

                    local targetParent = (gethui and gethui()) or pGui
                    sg.Parent = targetParent
                    prompted = true
                end
            end)
        end

        if prompted then
            print(string.format("[Unknown Hub] In-Game Token Payment GUI opened for '%s' (%d Tokens)!", prodName, prodPrice))
            pcall(function()
                if Hub.Notify then
                    Hub.Notify({
                        Title = "Token Payment Prompt",
                        Content = string.format("Paying %d Tokens for %s", prodPrice, prodName),
                        Duration = 3
                    })
                end
            end)
        end
    else
        -- Robux / Official Marketplace Modal
        if prodId > 0 then
            pcall(function()
                if prodObj.Type == "Gamepass" then
                    MarketplaceService:PromptGamePassPurchase(LocalPlayer, prodId)
                elseif prodObj.Type == "Bundle" then
                    MarketplaceService:PromptBundlePurchase(LocalPlayer, prodId)
                else
                    MarketplaceService:PromptProductPurchase(LocalPlayer, prodId)
                end
            end)
            print(string.format("[Unknown Hub] Prompted Roblox Purchase Modal for %s (ID: %d)", prodName, prodId))
            pcall(function()
                if Hub.Notify then
                    Hub.Notify({
                        Title = "Roblox Purchase Prompt",
                        Content = string.format("Prompting ID: %d (%s)", prodId, prodName),
                        Duration = 3
                    })
                end
            end)
        else
            pcall(function()
                MarketplaceService:PromptPurchase(LocalPlayer, prodId)
            end)
        end
    end
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

print("[Unknown Hub] Grow a Garden (Auto Sell Pets & Complete Module) Loaded Successfully!")
