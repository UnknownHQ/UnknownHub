local LIBRARY_LINK = "https://raw.githubusercontent.com/UnknownHQ/UnknownHub/main/UnknownLibrary.luau"
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

-- Safe Instant Module & Catalog Loading (Non-Blocking)
local PlantTraitsData = nil
pcall(function()
    local modules = ReplicatedStorage:FindFirstChild("Modules")
    if modules and modules:FindFirstChild("PlantTraitsData") then
        PlantTraitsData = require(modules.PlantTraitsData)
    end
end)

local SeedData = nil
pcall(function()
    local dataFolder = ReplicatedStorage:FindFirstChild("Data")
    if dataFolder and dataFolder:FindFirstChild("SeedData") then
        SeedData = require(dataFolder.SeedData)
    end
end)

local MutationData = nil
pcall(function()
    local modules = ReplicatedStorage:FindFirstChild("Modules")
    local gg = modules and modules:FindFirstChild("GardenGuideModules")
    local dm = gg and gg:FindFirstChild("DataModules")
    if dm and dm:FindFirstChild("MutationData") then
        MutationData = require(dm.MutationData)
    end
end)

local PetData = nil
pcall(function()
    local modules = ReplicatedStorage:FindFirstChild("Modules")
    local gg = modules and modules:FindFirstChild("GardenGuideModules")
    local dm = gg and gg:FindFirstChild("DataModules")
    if dm and dm:FindFirstChild("PetData") then
        PetData = require(dm.PetData)
    end
end)

local PetEggData = nil
pcall(function()
    local dataFolder = ReplicatedStorage:FindFirstChild("Data")
    if dataFolder and dataFolder:FindFirstChild("PetEggData") then
        PetEggData = require(dataFolder.PetEggData)
    end
end)

-- Remotes (Safe Non-Blocking Initialization with Dynamic Getters)
local Remotes = {}

local function resolveRemotes()
    pcall(function()
        local ge = ReplicatedStorage:FindFirstChild("GameEvents") or (ReplicatedStorage.WaitForChild and ReplicatedStorage:WaitForChild("GameEvents", 2))
        if ge then
            Remotes.Plant = ge:FindFirstChild("Plant_RE") or ge:FindFirstChild("Plant") or ge:FindFirstChild("PlantCrop") or ge:FindFirstChild("PlantSeed")
            local crops = ge:FindFirstChild("Crops") or (ge.WaitForChild and ge:WaitForChild("Crops", 2))
            if crops and not Remotes.Plant then
                Remotes.Collect = crops:FindFirstChild("Collect") or (crops.WaitForChild and crops:WaitForChild("Collect", 2))
                Remotes.Plant = crops:FindFirstChild("Plant") or crops:FindFirstChild("PlantCrop") or crops:FindFirstChild("PlantSeed") or crops:FindFirstChild("UseSeed")
            elseif crops then
                Remotes.Collect = crops:FindFirstChild("Collect") or (crops.WaitForChild and crops:WaitForChild("Collect", 2))
            end
            Remotes.SellInv = ge:FindFirstChild("Sell_Inventory") or ge:FindFirstChild("SellInventory") or ge:FindFirstChild("Sell")
            Remotes.SellItem = ge:FindFirstChild("Sell_Item") or ge:FindFirstChild("SellItem")
            Remotes.SellAllPets = ge:FindFirstChild("SellAllPets_RE") or ge:FindFirstChild("SellAllPets") or ge:FindFirstChild("SellPets")
            
            -- Shop Remotes
            Remotes.BuyPetEgg = ge:FindFirstChild("BuyPetEgg")
            Remotes.BuyGearStock = ge:FindFirstChild("BuyGearStock")
            Remotes.BuySeedStock = ge:FindFirstChild("BuySeedStock")
            Remotes.BuyDailySeedShopStock = ge:FindFirstChild("BuyDailySeedShopStock")
            Remotes.BuyCosmeticItem = ge:FindFirstChild("BuyCosmeticItem")
            Remotes.BuyCosmeticCrate = ge:FindFirstChild("BuyCosmeticCrate")

            -- Event Remotes
            local ac = ge:FindFirstChild("AcornChaos")
            if ac then
                Remotes.AcornCrack = ac:FindFirstChild("Crack")
                Remotes.AcornStart = ac:FindFirstChild("Start")
                Remotes.AcornReward = ac:FindFirstChild("Reward")
            end
            Remotes.TryAcornBell = ge:FindFirstChild("TryAcornBell")
            Remotes.TryGoldenAcorn = ge:FindFirstChild("TryGoldenAcorn")
            Remotes.TryMapleSyrup = ge:FindFirstChild("TryMapleSyrup")
            Remotes.TryHarvestBasket = ge:FindFirstChild("TryHarvestBasket")
            Remotes.ClaimChipmunkRewards = ge:FindFirstChild("ClaimChipmunkRewards")
            Remotes.SubmitChipmunkFruit = ge:FindFirstChild("SubmitChipmunkFruit")
        end
    end)
end
resolveRemotes()

local function getCollectRemote()
    if Remotes.Collect and Remotes.Collect.Parent then return Remotes.Collect end
    resolveRemotes()
    return Remotes.Collect
end

local function getPlantRemote()
    if Remotes.Plant and Remotes.Plant.Parent then return Remotes.Plant end
    resolveRemotes()
    return Remotes.Plant
end

local function getSellInvRemote()
    if Remotes.SellInv and Remotes.SellInv.Parent then return Remotes.SellInv end
    resolveRemotes()
    return Remotes.SellInv
end

local function getSellItemRemote()
    if Remotes.SellItem and Remotes.SellItem.Parent then return Remotes.SellItem end
    resolveRemotes()
    return Remotes.SellItem
end

local function getSellAllPetsRemote()
    if Remotes.SellAllPets and Remotes.SellAllPets.Parent then return Remotes.SellAllPets end
    resolveRemotes()
    return Remotes.SellAllPets
end

local function getAllPlayerTools()
    local tools = {}
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        for _, t in ipairs(backpack:GetChildren()) do
            if t:IsA("Tool") then
                table.insert(tools, t)
            end
        end
    end
    local char = LocalPlayer.Character
    if char then
        for _, t in ipairs(char:GetChildren()) do
            if t:IsA("Tool") then
                table.insert(tools, t)
            end
        end
    end
    return tools
end

-- =========================================================================
-- Dynamic Self-Updating Catalogs
-- =========================================================================

-- 1. Plants Catalog (660+ plants, dynamically self-updating)

local function getPlayerFarm()
    local farm = nil
    pcall(function()
        local getFarmAsync = require(ReplicatedStorage.Modules.GetFarmAsync)
        farm = getFarmAsync(LocalPlayer)
    end)
    if not farm then
        pcall(function()
            local getFarm = require(ReplicatedStorage.Modules.GetFarm)
            farm = getFarm(LocalPlayer)
        end)
    end
    if not farm then
        local farmFolder = Workspace:FindFirstChild("Farm")
        if farmFolder then
            for _, plot in ipairs(farmFolder:GetChildren()) do
                local imp = plot:FindFirstChild("Important")
                local ownerVal = imp and imp:FindFirstChild("Data") and imp.Data:FindFirstChild("Owner")
                if ownerVal and (tostring(ownerVal.Value) == LocalPlayer.Name or tostring(ownerVal.Value) == tostring(LocalPlayer.UserId)) then
                    farm = plot
                    break
                end
            end
        end
    end
    return farm
end

local function getPlantGrowthInfo(plant)
    if not plant or not plant.Parent then return nil end
    local maxAge = tonumber(plant:GetAttribute("MaxAge")) or 100
    local currentParts = 0
    for _, c in ipairs(plant:GetChildren()) do
        local n = tonumber(c.Name)
        if n and n > currentParts then
            currentParts = n
        end
    end
    local pct = math.clamp((currentParts / maxAge) * 100, 0, 100)
    local isGrowing = pct < 100
    local displayName = string.format("%s (%.2f%%)", plant.Name, pct)
    return {
        plant = plant,
        name = plant.Name,
        pct = pct,
        isGrowing = isGrowing,
        displayName = displayName
    }
end

local function getMyGardenPlants()
    local plants = {}
    pcall(function()
        local farm = getPlayerFarm()
        if farm then
            local plantsFolder = farm:FindFirstChild("Plants_Physical", true)
            if plantsFolder then
                for _, plant in ipairs(plantsFolder:GetChildren()) do
                    table.insert(plants, plant)
                end
            end
        end
    end)
    return plants
end

-- Dynamic list of plants currently growing in the player's garden (all plants)
local function buildPlantsInGardenCatalog()
    local plantSet = {}
    pcall(function()
        local plants = getMyGardenPlants()
        for _, plant in ipairs(plants) do
            if plant and plant.Name and plant.Name ~= "" then
                plantSet[plant.Name] = true
            end
        end
    end)
    local sortedList = {"All Garden Plants"}
    local temp = {}
    for pName, _ in pairs(plantSet) do
        table.insert(temp, pName)
    end
    table.sort(temp)
    for _, name in ipairs(temp) do
        table.insert(sortedList, name)
    end
    return sortedList
end

-- Dynamic list of ONLY GROWING plants in garden with real-time percentage
local function buildGrowingPlantsInGardenCatalog()
    local growingEntries = {}
    pcall(function()
        local plants = getMyGardenPlants()
        for _, plant in ipairs(plants) do
            local info = getPlantGrowthInfo(plant)
            if info and info.isGrowing then
                table.insert(growingEntries, info.displayName)
            end
        end
    end)
    local sortedList = {"All Growing Plants"}
    table.sort(growingEntries)
    for _, item in ipairs(growingEntries) do
        table.insert(sortedList, item)
    end
    return sortedList
end

-- Dynamic list of fruits/plants in garden with "None" as first option for specific fruit filter
local function buildGardenFruitCatalog()
    local plantSet = {}
    pcall(function()
        local plants = getMyGardenPlants()
        for _, plant in ipairs(plants) do
            if plant and plant.Name and plant.Name ~= "" then
                plantSet[plant.Name] = true
            end
        end
    end)
    local sortedList = {"None"}
    local temp = {}
    for pName, _ in pairs(plantSet) do
        table.insert(temp, pName)
    end
    table.sort(temp)
    for _, name in ipairs(temp) do
        table.insert(sortedList, name)
    end
    return sortedList
end

-- Helper to safely add an item to a Hub List without creating duplicates
local function safeAddToList(listObj, newItem)
    if not listObj or not newItem or newItem == "" then return end
    if not listObj.AddItem then return end

    local nameToAdd = type(newItem) == "table" and (newItem.Name or newItem[1] or tostring(newItem)) or tostring(newItem)
    
    if listObj.Items and type(listObj.Items) == "table" then
        for _, existing in ipairs(listObj.Items) do
            local existingName = type(existing) == "table" and (existing.Name or existing[1] or tostring(existing)) or tostring(existing)
            if existingName == nameToAdd then
                return
            end
        end
    end

    listObj.AddItem(newItem)
end

local function findWateringCanTool()
    local bp = LocalPlayer:FindFirstChild("Backpack")
    local char = LocalPlayer.Character
    local candidates = {}
    if char then
        for _, t in ipairs(char:GetChildren()) do
            if t:IsA("Tool") then
                table.insert(candidates, { tool = t, isEquipped = true })
            end
        end
    end
    if bp then
        for _, t in ipairs(bp:GetChildren()) do
            if t:IsA("Tool") then
                table.insert(candidates, { tool = t, isEquipped = false })
            end
        end
    end

    -- Priority 1: Standard "Watering Can" (strictly not "Super")
    for _, item in ipairs(candidates) do
        local n = item.tool.Name:lower()
        if n:find("watering can", 1, true) and not n:find("super", 1, true) then
            return item.tool, item.isEquipped
        end
    end

    -- Priority 2: Any tool containing "watering can" or "water"
    for _, item in ipairs(candidates) do
        local n = item.tool.Name:lower()
        if n:find("watering can", 1, true) then
            return item.tool, item.isEquipped
        end
    end

    for _, item in ipairs(candidates) do
        local n = item.tool.Name:lower()
        if (n:find("can", 1, true) or n:find("water", 1, true)) and not n:find("seed", 1, true) and not n:find("sprinkler", 1, true) and not n:find("melon", 1, true) then
            return item.tool, item.isEquipped
        end
    end

    return nil, false
end

local function findToolByNameOrClass(keyword)
    local bp = LocalPlayer:FindFirstChild("Backpack")
    local char = LocalPlayer.Character
    if char then
        for _, t in ipairs(char:GetChildren()) do
            if t:IsA("Tool") and t.Name:lower():find(keyword:lower(), 1, true) then
                return t, true
            end
        end
    end
    if bp then
        for _, t in ipairs(bp:GetChildren()) do
            if t:IsA("Tool") and t.Name:lower():find(keyword:lower(), 1, true) then
                return t, false
            end
        end
    end
    return nil, false
end

local function equipTool(tool)
    if not tool or not tool.Parent then return false end
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum and tool.Parent ~= char then
        hum:EquipTool(tool)
        task.wait(0.05)
    end
    return tool.Parent == char
end

-- =========================================================================
-- Reclaim Action
-- =========================================================================
local function executeReclaimSinglePlant(plantObj)
    if not plantObj or not plantObj.Parent then return false end
    local success = false
    pcall(function()
        local ge = ReplicatedStorage:FindFirstChild("GameEvents")
        local reclaimRemote = ge and (ge:FindFirstChild("ReclaimerService_RE") or ge:FindFirstChild("ReclaimPlant") or ge:FindFirstChild("Reclaim"))
        
        local reclaimerTool = findToolByNameOrClass("reclaim")
        if reclaimerTool then
            equipTool(reclaimerTool)
        end

        if reclaimRemote then
            if reclaimRemote.Name == "ReclaimerService_RE" then
                reclaimRemote:FireServer("TryReclaim", plantObj)
                success = true
            else
                reclaimRemote:FireServer(plantObj)
                success = true
            end
        end

        local prompt = plantObj:FindFirstChildWhichIsA("ProximityPrompt", true)
        if prompt and prompt.Enabled and prompt.ActionText:lower():find("reclaim") then
            if fireproximityprompt then
                fireproximityprompt(prompt)
                success = true
            end
        end
    end)
    return success
end

-- =========================================================================
-- Shovel Action
-- =========================================================================
local function executeShovelSinglePlant(plantObj)
    if not plantObj or not plantObj.Parent then return false end
    local pName = plantObj.Name
    pcall(function()
        local ge = ReplicatedStorage:FindFirstChild("GameEvents")
        local shovelRemote = ge and (ge:FindFirstChild("ShovelPlant") or ge:FindFirstChild("Shovel") or ge:FindFirstChild("ShovelAllPlants") or ge:FindFirstChild("DeletePlant") or ge:FindFirstChild("RemovePlant"))
        local uuid = plantObj:GetAttribute("PLANT_UUID") or plantObj:GetAttribute("UUID")

        if shovelRemote then
            if shovelRemote:IsA("RemoteEvent") then
                shovelRemote:FireServer(plantObj)
                if uuid then shovelRemote:FireServer(uuid) end
            elseif shovelRemote:IsA("RemoteFunction") then
                shovelRemote:InvokeServer(plantObj)
            end
        end

        -- Tool based shovel fallback (Golden Shovel / Standard Shovel)
        local shovelTool = findToolByNameOrClass("shovel")
        if shovelTool then
            equipTool(shovelTool)
            local pPart = plantObj:FindFirstChildWhichIsA("BasePart") or (plantObj:IsA("BasePart") and plantObj)
            if pPart then
                shovelTool:Activate()
                local toolRemote = shovelTool:FindFirstChildWhichIsA("RemoteEvent") or shovelTool:FindFirstChildWhichIsA("RemoteFunction")
                if toolRemote then
                    if toolRemote:IsA("RemoteEvent") then
                        toolRemote:FireServer(plantObj, pPart.Position)
                    else
                        toolRemote:InvokeServer(plantObj, pPart.Position)
                    end
                end
            end
        end

        local prompt = plantObj:FindFirstChildWhichIsA("ProximityPrompt", true)
        if prompt and prompt.Enabled and (prompt.ActionText:lower():find("shovel") or prompt.ActionText:lower():find("remove") or prompt.ActionText:lower():find("dig")) then
            if fireproximityprompt then
                fireproximityprompt(prompt)
            end
        end
    end)
    return true
end

-- =========================================================================
-- Water Action (with Watering Can)
-- =========================================================================
local function executeWaterSinglePlant(plantObj, repeatCount)
    if not plantObj or not plantObj.Parent then return false end
    local times = math.clamp(repeatCount or 1, 1, 20)
    pcall(function()
        local ge = ReplicatedStorage:FindFirstChild("GameEvents")
        local waterFunction = ge and ge:FindFirstChild("WaterYourGardens")
        local waterRE = ge and ge:FindFirstChild("Water_RE")
        local waterTool = findWateringCanTool()

        if waterTool then
            equipTool(waterTool)
        end

        local pPart = plantObj:FindFirstChildWhichIsA("BasePart") or (plantObj:IsA("BasePart") and plantObj)
        local targetPos = pPart and pPart.Position or Vector3.zero

        for i = 1, times do
            -- 1. Direct Infinite Distance Server Remotes (Bypasses character distance limitations)
            if waterRE and waterRE:IsA("RemoteEvent") then
                waterRE:FireServer(plantObj, targetPos)
                waterRE:FireServer(plantObj)
            end

            if waterFunction and waterFunction:IsA("RemoteFunction") then
                pcall(function()
                    waterFunction:InvokeServer(plantObj)
                end)
            elseif waterFunction and waterFunction:IsA("RemoteEvent") then
                waterFunction:FireServer(plantObj, targetPos)
            end

            -- 2. Tool Activation & Internal Tool Remote Handler
            if waterTool and waterTool.Parent == LocalPlayer.Character then
                waterTool:Activate()
                local toolRemote = waterTool:FindFirstChildWhichIsA("RemoteEvent") or waterTool:FindFirstChildWhichIsA("RemoteFunction")
                if toolRemote then
                    if toolRemote:IsA("RemoteEvent") then
                        toolRemote:FireServer(plantObj, targetPos)
                    else
                        toolRemote:InvokeServer(plantObj, targetPos)
                    end
                end
            end

            -- 3. Proximity Prompt Fallback
            local prompt = plantObj:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt and prompt.Enabled and prompt.ActionText:lower():find("water") then
                if fireproximityprompt then fireproximityprompt(prompt) end
            end

            if times > 1 then task.wait(0.04) end
        end
    end)
    return true
end

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

-- 1b. Seeds Catalog (dynamically self-updating from SeedData, inventory, and farm)
local function buildDynamicSeedCatalog()
    local seedSet = {}

    if SeedData and type(SeedData) == "table" then
        for name, _ in pairs(SeedData) do
            if type(name) == "string" and name ~= "" then
                local clean = name:gsub("%s*[sS]eed%s*", "")
                seedSet[clean] = true
                seedSet[clean .. " Seed"] = true
            end
        end
    end

    if PlantTraitsData and type(PlantTraitsData) == "table" then
        for _, plantMap in pairs(PlantTraitsData) do
            if type(plantMap) == "table" then
                for name, _ in pairs(plantMap) do
                    if type(name) == "string" and name ~= "" then
                        local clean = name:gsub("%s*[sS]eed%s*", "")
                        seedSet[clean] = true
                        seedSet[clean .. " Seed"] = true
                    end
                end
            end
        end
    end

    pcall(function()
        local allTools = getAllPlayerTools()
        for _, t in ipairs(allTools) do
            if t.Name:lower():find("seed") then
                local sName = t:GetAttribute("f") or t:GetAttribute("Seed") or t.Name
                seedSet[tostring(sName)] = true
            end
        end
    end)

    local fallbackSeeds = {
        "Carrot Seed", "Tomato Seed", "Corn Seed", "Pumpkin Seed", "Watermelon Seed",
        "Strawberry Seed", "Blueberry Seed", "Wheat Seed", "Potato Seed", "Cabbage Seed",
        "Pepper Seed", "Chili Seed", "Grape Seed", "Eggplant Seed", "Mushroom Seed",
        "Dragonfruit Seed", "Pineapple Seed", "Apple Seed", "Orange Seed", "Golden Seed"
    }
    for _, s in ipairs(fallbackSeeds) do
        seedSet[s] = true
    end

    local sortedList = {"All Seeds"}
    local temp = {}
    for sName, _ in pairs(seedSet) do
        table.insert(temp, sName)
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

    pcall(function()
        local rep = game:GetService("ReplicatedStorage")
        local data = rep:FindFirstChild("Data")
        local petReg = data and data:FindFirstChild("PetRegistry")
        if petReg then
            local res = require(petReg)
            if res and res.PetList then
                for pName, _ in pairs(res.PetList) do
                    local name = tostring(pName)
                    if name ~= "" and not name:find("Data") then
                        petSet[name] = true
                    end
                end
            end
            if res and res.PetEggs then
                for _, eggInfo in pairs(res.PetEggs) do
                    if type(eggInfo) == "table" and eggInfo.RarityData and eggInfo.RarityData.Items then
                        for pName, _ in pairs(eggInfo.RarityData.Items) do
                            local name = tostring(pName)
                            if name ~= "" then petSet[name] = true end
                        end
                    end
                end
            end
        end
    end)

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

    local sortedList = {"All Pets", "None"}
    local temp = {}
    for petName, _ in pairs(petSet) do
        if petName ~= "All Pets" and petName ~= "None" then
            table.insert(temp, petName)
        end
    end
    table.sort(temp)
    for _, name in ipairs(temp) do
        table.insert(sortedList, name)
    end
    return sortedList
end

-- 5. Products & Gamepasses Catalog (Comprehensive & Dynamically Self-Updating, Robux Only)
local function buildDynamicProductCatalog()
    local productMap = {}

    local function addProd(name, rawName, id, price, pType, category, order)
        id = tonumber(id) or 0
        price = tonumber(price) or 0
        if id <= 0 then return end
        local formattedCategory = category or pType or "Product"
        local key = string.format("[%s] %s", formattedCategory, name)
        if not productMap[key] then
            productMap[key] = {
                Name = key,
                DisplayName = name,
                RawName = rawName or name,
                Id = id,
                Price = price,
                Robux = price,
                Type = pType or "Product",
                Category = formattedCategory,
                Order = order or 999
            }
        end
    end

    -- 1. Forever Pack (All 11 Tiers in natural order)
    local foreverPrices = {
        [3483219975] = {Tier = 1, Price = 39},
        [3483220099] = {Tier = 2, Price = 79},
        [3483220200] = {Tier = 3, Price = 119},
        [3483220270] = {Tier = 4, Price = 159},
        [3483220356] = {Tier = 5, Price = 199},
        [3483220437] = {Tier = 6, Price = 279},
        [3483221023] = {Tier = 7, Price = 399},
        [3483221092] = {Tier = 8, Price = 639},
        [3483221165] = {Tier = 9, Price = 759},
        [3483221217] = {Tier = 10, Price = 959},
        [3483221290] = {Tier = 11, Price = 1199},
    }
    for pid, info in pairs(foreverPrices) do
        local name = string.format("Tier %d (%d R$)", info.Tier, info.Price)
        addProd(name, "InfinitePack_Tier_" .. info.Tier, pid, info.Price, "Product", "Forever Pack", 100 + info.Tier)
    end

    -- Also scan dynamic InfinitePackData in case prices or tiers change
    pcall(function()
        local dataFolder = ReplicatedStorage:FindFirstChild("Data")
        local infMod = dataFolder and dataFolder:FindFirstChild("InfinitePackData")
        if infMod then
            local infData = require(infMod)
            local prices = infData.FallbackPrices or {}
            local pidsMod = infMod:FindFirstChild("InfinitePackProductIds")
            if pidsMod then
                local pids = require(pidsMod)
                for _, entry in pairs(pids) do
                    if type(entry) == "table" then
                        local pid = tonumber(entry[1]) or 0
                        local tier = tonumber(entry[2]) or 0
                        local price = tonumber(prices[tostring(pid)] or prices[pid]) or 0
                        if pid > 0 and tier > 0 then
                            local name = string.format("Tier %d (%d R$)", tier, price)
                            addProd(name, "InfinitePack_Tier_" .. tier, pid, price, "Product", "Forever Pack", 100 + tier)
                        end
                    end
                end
            end
        end
    end)

    -- 2. Event Forever Pack (All 5 Tiers in natural order)
    local eventForeverPrices = {
        [3425555547] = {Tier = 1, Price = 37},
        [3425556327] = {Tier = 2, Price = 99},
        [3425557211] = {Tier = 3, Price = 175},
        [3425557487] = {Tier = 4, Price = 375},
        [3425557881] = {Tier = 5, Price = 495},
    }
    for pid, info in pairs(eventForeverPrices) do
        local name = string.format("Tier %d (%d R$)", info.Tier, info.Price)
        addProd(name, "EventInfinitePack_Tier_" .. info.Tier, pid, info.Price, "Product", "Event Forever Pack", 200 + info.Tier)
    end

    -- 3. Official Gamepasses
    local officialGamepasses = {
        {"Harvest All", 931892840, 450},
        {"Auto Harvester", 931892840, 450},
        {"Auto Planter", 931892839, 299},
        {"VIP", 931892837, 499},
        {"2x Shekels (Coins)", 931892838, 399},
        {"Infinite Backpack", 931892841, 599},
        {"2x Mutation Luck", 931892842, 799},
        {"Fast Growth / Sprinkler Pass", 931892843, 350},
        {"Extra Pet Slot (+1)", 931892844, 250},
        {"Extra Pet Slot (+3)", 931892845, 600},
        {"Extra Pet Slot (+5)", 931892847, 950},
        {"Trade Plaza Access", 931892846, 100},
        {"Instant Plant Growth", 931892848, 500},
        {"Rare Mutation Magnet", 931892849, 650},
        {"Weather Controller Pass", 931892850, 850},
        {"Double Pet XP", 931892851, 400}
    }
    for i, gp in ipairs(officialGamepasses) do
        local name = string.format("%s (%d R$)", gp[1], gp[3])
        addProd(name, gp[1], gp[2], gp[3], "Gamepass", "Gamepass", 300 + i)
    end

    -- 4. Packs & Bundles (Data.Packs)
    pcall(function()
        local dataFolder = ReplicatedStorage:FindFirstChild("Data")
        local packsFolder = dataFolder and dataFolder:FindFirstChild("Packs")
        if packsFolder then
            for i, m in ipairs(packsFolder:GetChildren()) do
                if m:IsA("ModuleScript") then
                    pcall(function()
                        local pData = require(m)
                        if type(pData) == "table" then
                            local pid = tonumber(pData.ProductId or pData.PurchaseID or pData.DevProductId) or 0
                            local price = tonumber(pData.Price or pData.Robux or pData.Cost) or 0
                            local packName = m.Name:gsub("Data$", ""):gsub("Bundle", " Bundle"):gsub("Pack", " Pack"):gsub("(%l)(%u)", "%1 %2")
                            if pid > 0 then
                                local label = price > 0 and string.format("%s (%d R$)", packName, price) or packName
                                addProd(label, m.Name, pid, price, "Product", "Packs & Bundles", 400 + i)
                            end
                            local giftId = tonumber(pData.GiftId) or 0
                            if giftId > 0 then
                                local giftLabel = price > 0 and string.format("%s (Gift) (%d R$)", packName, price) or (packName .. " (Gift)")
                                addProd(giftLabel, m.Name .. "Gift", giftId, price, "Product", "Packs & Bundles", 450 + i)
                            end
                        end
                    end)
                end
            end
        end
    end)

    -- 5. Exotic Packs, Chests & Premium Eggs (Data.ExoticPackData)
    pcall(function()
        local dataFolder = ReplicatedStorage:FindFirstChild("Data")
        local exMod = dataFolder and dataFolder:FindFirstChild("ExoticPackData")
        if exMod then
            local exData = require(exMod)
            if type(exData) == "table" then
                local i = 0
                for packKey, packInfo in pairs(exData) do
                    i = i + 1
                    if type(packInfo) == "table" then
                        local title = packInfo.Title or packKey:gsub("^PREMIUM_", "Premium "):gsub("^EXOTIC_", "Exotic "):gsub("_", " ")
                        title = title:gsub("!$", "")
                        local fallbackPrice = (type(packInfo.FallbackPrices) == "table" and tonumber(packInfo.FallbackPrices[1])) or 149
                        if type(packInfo.Products) == "table" then
                            for _, pid in ipairs(packInfo.Products) do
                                local numPid = tonumber(pid) or 0
                                if numPid > 0 then
                                    local label = string.format("%s (%d R$)", title, fallbackPrice)
                                    addProd(label, packKey, numPid, fallbackPrice, "Product", "Exotic Packs & Chests", 500 + i)
                                end
                            end
                        end
                        if type(packInfo.GiftProducts) == "table" then
                            for _, gpid in pairs(packInfo.GiftProducts) do
                                local numGpid = tonumber(gpid) or 0
                                if numGpid > 0 then
                                    local label = string.format("%s (Gift) (%d R$)", title, fallbackPrice)
                                    addProd(label, packKey .. "_Gift", numGpid, fallbackPrice, "Product", "Exotic Packs & Chests", 550 + i)
                                end
                            end
                        end
                    end
                end
            end
        end
    end)

    -- 6. Dev Products (Data.DevProductIds)
    pcall(function()
        local dataFolder = ReplicatedStorage:FindFirstChild("Data")
        local devProductMod = dataFolder and dataFolder:FindFirstChild("DevProductIds")
        if devProductMod then
            local devData = require(devProductMod)
            if type(devData) == "table" then
                local i = 0
                for prodName, prodVal in pairs(devData) do
                    i = i + 1
                    local purchaseId = 0
                    local price = 0
                    if type(prodVal) == "table" then
                        purchaseId = tonumber(prodVal.PurchaseID or prodVal.Id or prodVal.ProductId) or 0
                        price = tonumber(prodVal.Price or prodVal.Robux or prodVal.Cost) or 0
                    elseif tonumber(prodVal) then
                        purchaseId = tonumber(prodVal)
                    end

                    if purchaseId > 0 then
                        local formattedName = tostring(prodName):gsub("(%l)(%u)", "%1 %2"):gsub("(%a)(%d)", "%1 %2"):gsub("_", " ")
                        local label = price > 0 and string.format("%s (%d R$)", formattedName, price) or formattedName
                        addProd(label, tostring(prodName), purchaseId, price, "Product", "Dev Products", 600 + i)
                    end
                end
            end
        end
    end)

    local list = {}
    for _, p in pairs(productMap) do
        table.insert(list, p)
    end
    table.sort(list, function(a, b)
        if a.Order ~= b.Order then
            return a.Order < b.Order
        end
        return a.Name:lower() < b.Name:lower()
    end)

    return list
end

local function buildDynamicEggCatalog()
    local eggs = {}
    local seen = {}

    -- 1. Scan PetEggData & PetEggShopData
    pcall(function()
        local rep = game:GetService("ReplicatedStorage")
        local data = rep:FindFirstChild("Data")
        local eggData = data and (data:FindFirstChild("PetEggData") or data:FindFirstChild("PetEggShopData"))
        if eggData then
            local res = require(eggData)
            for k, v in pairs(res) do
                if type(v) == "table" and k ~= "RefreshTime" then
                    local name = tostring(v.EggName or v.Name or k)
                    local price = tonumber(v.Price) or 0
                    if not seen[name] then
                        seen[name] = true
                        table.insert(eggs, {
                            Name = name,
                            ItemName = name,
                            Price = price,
                            Type = "Egg"
                        })
                    end
                end
            end
        end
    end)

    -- 2. Scan PetRegistry.PetEggs
    pcall(function()
        local rep = game:GetService("ReplicatedStorage")
        local data = rep:FindFirstChild("Data")
        local petReg = data and data:FindFirstChild("PetRegistry")
        if petReg then
            local res = require(petReg)
            if res and res.PetEggs then
                for eggName, _ in pairs(res.PetEggs) do
                    local name = tostring(eggName)
                    if not seen[name] then
                        seen[name] = true
                        table.insert(eggs, {
                            Name = name,
                            ItemName = name,
                            Price = 0,
                            Type = "Egg"
                        })
                    end
                end
            end
        end
    end)

    -- 3. Scan Backpack for any Eggs
    pcall(function()
        local bp = LocalPlayer:FindFirstChild("Backpack")
        if bp then
            for _, t in ipairs(bp:GetChildren()) do
                if t:IsA("Tool") and t.Name:lower():find("egg") then
                    local cleanName = t.Name:gsub("%s*x%d+", ""):gsub("%s*%(.*%)", ""):gsub("^%s+", ""):gsub("%s+$", "")
                    if not seen[cleanName] then
                        seen[cleanName] = true
                        table.insert(eggs, {
                            Name = cleanName,
                            ItemName = cleanName,
                            Price = 0,
                            Type = "Egg"
                        })
                    end
                end
            end
        end
    end)

    table.sort(eggs, function(a, b) return a.ItemName < b.ItemName end)
    table.insert(eggs, 1, {Name = "All Eggs", ItemName = "All Eggs", Price = 0, Type = "Egg"})
    return eggs
end

local function buildDynamicGearCatalog()
    local gears = {}
    pcall(function()
        local rep = game:GetService("ReplicatedStorage")
        local data = rep:FindFirstChild("Data")
        local gearData = data and data:FindFirstChild("GearShopData")
        if gearData then
            local res = require(gearData)
            local gTable = res.Gear or res
            for k, v in pairs(gTable) do
                if type(v) == "table" and k ~= "RefreshTime" then
                    local name = v.GearName or v.Name or k
                    local price = tonumber(v.Price) or 0
                    table.insert(gears, {
                        Name = tostring(name) .. " (" .. formatCurrency(price) .. "¢)",
                        ItemName = tostring(name),
                        Price = price,
                        Type = "Gear"
                    })
                end
            end
        end
    end)
    table.sort(gears, function(a, b) return a.Price < b.Price end)
    return gears
end

local function buildDynamicSeedShopCatalog()
    local standardSeeds = {}
    local exclusiveSeeds = {}

    pcall(function()
        local rep = game:GetService("ReplicatedStorage")
        local data = rep:FindFirstChild("Data")
        local seedData = data and data:FindFirstChild("SeedShopData")
        if seedData then
            local res = require(seedData)
            for k, v in pairs(res) do
                if type(v) == "table" and k ~= "RefreshTime" then
                    -- Filter out special currency seeds (e.g. GardenCoins like Potato, Broccoli, Brussels Sprout, Cocomango)
                    -- and seeds with DisplayInShop == false
                    local isSpecialCurrency = (v.SpecialCurrencyType ~= nil and v.SpecialCurrencyType ~= "Sheckles")
                        or (v.CurrencyType ~= nil and v.CurrencyType ~= "Sheckles")
                    local isHidden = (v.DisplayInShop == false) or (v.HideInShop == true)

                    if not isSpecialCurrency and not isHidden then
                        local rawName = (type(v.Seed) == "table" and (v.Seed.SeedName or v.Seed.Name)) or (type(v.Seed) == "string" and v.Seed) or v.Name or tostring(k)
                        local cleanName = tostring(rawName):gsub("%s*[sS]eed%s*$", ""):gsub("^%s+", ""):gsub("%s+$", "")
                        if cleanName == "" then cleanName = tostring(k) end
                        local price = tonumber(v.Price) or 0
                        local isExclusive = (v.Exclusive == true) or (v.LayoutOrder and v.LayoutOrder >= 400)

                        local entry = {
                            Name = cleanName .. " (" .. formatCurrency(price) .. "¢)",
                            ItemName = cleanName,
                            RawKey = tostring(k),
                            Price = price,
                            LayoutOrder = tonumber(v.LayoutOrder) or 0,
                            IsExclusive = isExclusive,
                            Type = "Seed"
                        }

                        if isExclusive then
                            table.insert(exclusiveSeeds, entry)
                        else
                            table.insert(standardSeeds, entry)
                        end
                    end
                end
            end
        end
    end)

    -- Sort standard seeds by Price ascending (value)
    table.sort(standardSeeds, function(a, b)
        if a.Price ~= b.Price then
            return a.Price < b.Price
        end
        return (a.LayoutOrder or 0) < (b.LayoutOrder or 0)
    end)

    -- Sort exclusive seeds by Price / LayoutOrder ascending
    table.sort(exclusiveSeeds, function(a, b)
        if a.Price ~= b.Price then
            return a.Price < b.Price
        end
        return (a.LayoutOrder or 0) < (b.LayoutOrder or 0)
    end)

    -- Combine: Standard seeds first, Exclusive seeds at the end
    local seeds = {}
    for _, item in ipairs(standardSeeds) do
        table.insert(seeds, item)
    end
    for _, item in ipairs(exclusiveSeeds) do
        table.insert(seeds, item)
    end

    return seeds
end

local function buildDynamicCosmeticCatalog()
    local cosmetics = {}
    pcall(function()
        local rep = game:GetService("ReplicatedStorage")
        local data = rep:FindFirstChild("Data")
        local cData = data and data:FindFirstChild("CosmeticItemShopData")
        if cData then
            local res = require(cData)
            for k, v in pairs(res) do
                if type(v) == "table" then
                    local name = v.CosmeticName or v.Name or k
                    local price = tonumber(v.Price) or 0
                    table.insert(cosmetics, {
                        Name = tostring(name) .. " (" .. formatCurrency(price) .. "¢)",
                        ItemName = tostring(name),
                        Price = price,
                        Type = "Item"
                    })
                end
            end
        end
        local crateData = data and data:FindFirstChild("CosmeticCrateShopData")
        if crateData then
            local res = require(crateData)
            for k, v in pairs(res) do
                if type(v) == "table" then
                    local name = v.CrateName or v.Name or k
                    local price = tonumber(v.Price) or 0
                    table.insert(cosmetics, {
                        Name = "[Crate] " .. tostring(name) .. " (" .. formatCurrency(price) .. "¢)",
                        ItemName = tostring(name),
                        Price = price,
                        Type = "Crate"
                    })
                end
            end
        end
    end)
    table.sort(cosmetics, function(a, b) return a.Price < b.Price end)
    return cosmetics
end

local function buildDynamicSprinklerCatalog()
    local spList = {}
    local seen = {}

    local defaultSprinklers = {
        "Basic Sprinkler",
        "Advanced Sprinkler",
        "Master Sprinkler",
        "Grandmaster Sprinkler",
        "Godly Sprinkler",
        "Lush Sprinkler",
        "Berry Blusher Sprinkler",
        "Flower Froster Sprinkler",
        "Golden Sprinkler"
    }
    for _, s in ipairs(defaultSprinklers) do
        seen[s] = true
        table.insert(spList, {Name = s, ItemName = s})
    end

    -- 1. Scan ReplicatedStorage.ObjectModels
    pcall(function()
        local rep = game:GetService("ReplicatedStorage")
        local objModels = rep:FindFirstChild("ObjectModels")
        if objModels then
            for _, c in ipairs(objModels:GetChildren()) do
                if c.Name:lower():find("sprinkler") and not seen[c.Name] then
                    seen[c.Name] = true
                    table.insert(spList, {Name = c.Name, ItemName = c.Name})
                end
            end
        end
    end)

    -- 2. Scan ReplicatedStorage.Data.GearData
    pcall(function()
        local rep = game:GetService("ReplicatedStorage")
        local gearData = rep:FindFirstChild("Data") and rep.Data:FindFirstChild("GearData")
        if gearData then
            local g = require(gearData)
            for k, _ in pairs(g) do
                if tostring(k):lower():find("sprinkler") and not seen[tostring(k)] then
                    seen[tostring(k)] = true
                    table.insert(spList, {Name = tostring(k), ItemName = tostring(k)})
                end
            end
        end
    end)

    -- 3. Scan Workspace for any placed sprinklers
    pcall(function()
        for _, desc in ipairs(game:GetService("Workspace"):GetDescendants()) do
            if desc.Name:lower():find("sprinkler") and (desc:IsA("Model") or desc:IsA("BasePart")) then
                local clean = desc.Name
                if not seen[clean] then
                    seen[clean] = true
                    table.insert(spList, {Name = clean, ItemName = clean})
                end
            end
        end
    end)

    table.sort(spList, function(a, b) return a.Name < b.Name end)
    table.insert(spList, 1, {Name = "All Sprinklers", ItemName = "All Sprinklers"})
    table.insert(spList, 1, {Name = "Auto (Highest Tier)", ItemName = "Auto (Highest Tier)"})
    return spList
end

local function buildDynamicCraftCatalogs()
    local craftPlants = {}
    local craftGears = {}
    local plantSeen = {}
    local gearSeen = {}

    pcall(function()
        local dataMod = ReplicatedStorage:FindFirstChild("Data") and ReplicatedStorage.Data:FindFirstChild("CraftingData")
        if not dataMod then return end
        local craftingData = require(dataMod)
        local recipes = (craftingData.CraftingRecipeRegistry and craftingData.CraftingRecipeRegistry.ItemRecipes) or craftingData.ItemRecipes or craftingData

        -- Collect all valid/active machine types present on the map or standard workbenches
        local validMachineTypes = {
            ["SeedEventWorkbench"] = true,
            ["GearEventWorkbench"] = true,
            ["Workbench"] = true,
            ["CraftingTable"] = true,
            ["CraftingBench"] = true,
            ["SeedWorkbench"] = true,
            ["GearWorkbench"] = true
        }

        pcall(function()
            for _, b in ipairs(CollectionService:GetTagged("CraftingObject")) do
                if b:IsDescendantOf(Workspace) then
                    local mType = b:GetAttribute("CraftingObjectType")
                    if mType and type(mType) == "string" and mType ~= "" then
                        validMachineTypes[mType] = true
                    end
                end
            end
        end)

        for recipeId, recipe in pairs(recipes) do
            local mTypes = recipe.MachineTypes or {}
            local canCraftAtBench = false
            for _, mType in ipairs(mTypes) do
                if validMachineTypes[mType] then
                    canCraftAtBench = true
                    break
                end
            end

            -- Only include recipes that can actually be crafted at current craft tables / workbenches
            if canCraftAtBench then
                local out = recipe.Outputs and recipe.Outputs[1]
                local outType = out and out.ItemType or ""
                local outName = (out and out.ItemData and out.ItemData.ItemName) or tostring(recipeId)
                local displayName = outName
                if string.find(tostring(recipeId), "@") then
                    displayName = string.split(tostring(recipeId), "@")[1]
                end

                local isPlant = (outType == "Seed" or outType == "Seed Pack" or outType == "Crop" or outType == "Plant")
                local recLow = tostring(recipeId):lower()
                if not isPlant then
                    if recLow:find("seed") or recLow:find("pack") or recLow:find("sprout") or recLow:find("flower") or recLow:find("bamboo") 
                        or recLow:find("aloe") or recLow:find("dandelion") or recLow:find("lumira") or recLow:find("yarrow") 
                        or recLow:find("veinpetal") or recLow:find("mandrake") or recLow:find("honeysuckle") or recLow:find("nectar") 
                        or recLow:find("apple") or recLow:find("bean") or recLow:find("lingonberry") or recLow:find("guanabana") 
                        or recLow:find("olive") or recLow:find("suncoil") or recLow:find("manuka") or recLow:find("horsetail")
                        or recLow:find("peace lily") or recLow:find("egg melon") or recLow:find("spray") then
                        isPlant = true
                    end
                end
                if recLow:find("sprinkler") or recLow:find("crate") or recLow:find("egg") or recLow:find("toy") or recLow:find("treat") or recLow:find("statue") or recLow:find("ingot") or recLow:find("box") or recLow:find("pouch") or recLow:find("forger") or recLow:find("reclaimer") or recLow:find("anvil") or recLow:find("grinder") or recLow:find("wand") or recLow:find("radar") or recLow:find("lantern") or recLow:find("magnet") or recLow:find("rod") or recLow:find("hammer") or recLow:find("thundelbringer") or recLow:find("dog") or recLow:find("cat") or recLow:find("cheetah") or recLow:find("stone") or recLow:find("mirror") or recLow:find("table") or recLow:find("light") or recLow:find("mushroom") or recLow:find("memories") or recLow:find("rack") then
                    isPlant = false
                end

                local fullLabel = displayName

                if isPlant then
                    if not plantSeen[fullLabel] then
                        plantSeen[fullLabel] = true
                        table.insert(craftPlants, {Name = fullLabel, BaseName = displayName, RecipeId = tostring(recipeId), MachineTypes = mTypes})
                    end
                else
                    if not gearSeen[fullLabel] then
                        gearSeen[fullLabel] = true
                        table.insert(craftGears, {Name = fullLabel, BaseName = displayName, RecipeId = tostring(recipeId), MachineTypes = mTypes})
                    end
                end
            end
        end
    end)

    table.sort(craftPlants, function(a, b) return a.Name < b.Name end)
    table.sort(craftGears, function(a, b) return a.Name < b.Name end)

    table.insert(craftPlants, 1, {Name = "None", BaseName = "None", RecipeId = "None", MachineTypes = {}})
    table.insert(craftGears, 1, {Name = "None", BaseName = "None", RecipeId = "None", MachineTypes = {}})

    return craftPlants, craftGears
end

local function buildDynamicEventShopCatalogs()
    local eSeeds, eGears, ePets, eCosmetics = {}, {}, {}, {}

    pcall(function()
        local rep = game:GetService("ReplicatedStorage")
        local data = rep:FindFirstChild("Data")
        local eventsData = data and data:FindFirstChild("Events")
        local fallData = eventsData and eventsData:FindFirstChild("FallMarketEvent")
        local shopMod = fallData and fallData:FindFirstChild("FallMarketEventShopData")

        if shopMod then
            local shopTables = require(shopMod)
            if shopTables and type(shopTables) == "table" then
                if shopTables.SeedShop then
                    for name, info in pairs(shopTables.SeedShop) do
                        local price = info.Price or 0
                        local formatted = string.format("%s (%s¢)", name, tostring(price))
                        table.insert(eSeeds, {Name = formatted, ItemName = name, Price = price, ShopType = "SeedShop"})
                    end
                end
                if shopTables.GearShop then
                    for name, info in pairs(shopTables.GearShop) do
                        local price = info.Price or 0
                        local formatted = string.format("%s (%s¢)", name, tostring(price))
                        table.insert(eGears, {Name = formatted, ItemName = name, Price = price, ShopType = "GearShop"})
                    end
                end
                if shopTables.PetShop then
                    for name, info in pairs(shopTables.PetShop) do
                        local price = info.Price or 0
                        local formatted = string.format("%s (%s¢)", name, tostring(price))
                        table.insert(ePets, {Name = formatted, ItemName = name, Price = price, ShopType = "PetShop"})
                    end
                end
                if shopTables.CosmeticShop then
                    for name, info in pairs(shopTables.CosmeticShop) do
                        local price = info.Price or 0
                        local formatted = string.format("%s (%s¢)", name, tostring(price))
                        table.insert(eCosmetics, {Name = formatted, ItemName = name, Price = price, ShopType = "CosmeticShop"})
                    end
                end
            end
        end
    end)

    table.sort(eSeeds, function(a, b) return a.Price < b.Price end)
    table.sort(eGears, function(a, b) return a.Price < b.Price end)
    table.sort(ePets, function(a, b) return a.Price < b.Price end)
    table.sort(eCosmetics, function(a, b) return a.Price < b.Price end)

    table.insert(eSeeds, 1, {Name = "All Event Seeds", ItemName = "All Event Seeds"})
    table.insert(eGears, 1, {Name = "All Event Gears", ItemName = "All Event Gears"})
    table.insert(ePets, 1, {Name = "All Event Pets", ItemName = "All Event Pets"})
    table.insert(eCosmetics, 1, {Name = "All Event Cosmetics", ItemName = "All Event Cosmetics"})

    return eSeeds, eGears, ePets, eCosmetics
end

local allAvailablePlants = buildDynamicPlantCatalog()
local allAvailableSeeds = buildDynamicSeedCatalog()
local allAvailableMutations = buildDynamicMutationCatalog()
local allAvailableCategories = buildDynamicCategoryCatalog()
local allAvailablePets = buildDynamicPetCatalog()
local allAvailableProducts = buildDynamicProductCatalog()
local allAvailableEggs = buildDynamicEggCatalog()
local allAvailableGears = buildDynamicGearCatalog()
local allAvailableSeedShop = buildDynamicSeedShopCatalog()
local allAvailableCosmetics = buildDynamicCosmeticCatalog()
local allAvailableSprinklers = buildDynamicSprinklerCatalog()
local allAvailableCraftPlants, allAvailableCraftGears = buildDynamicCraftCatalogs()
local allAvailableEventSeeds, allAvailableEventGears, allAvailableEventPets, allAvailableEventCosmetics = buildDynamicEventShopCatalogs()

local function destroyOldGui()
    local parents = {game:GetService("CoreGui")}
    if gethui then pcall(function() table.insert(parents, gethui()) end) end
    local playerGui = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
    if playerGui then table.insert(parents, playerGui) end
    for _, parent in ipairs(parents) do
        if parent then
            pcall(function()
                for _, child in ipairs(parent:GetDescendants()) do
                    if child:IsA("ScreenGui") and (child.Name == LIBRARY_NAME or child.Name:find("Unknown_TabbedHub_UI")) then
                        pcall(function() child:Destroy() end)
                    end
                end
            end)
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
    InstantCollectAll = false,
    AutoCollectFiltered = false,
    Collect_Fruit = "None",
    Collect_Category = "None",
    Collect_Variant = "None",
    Collect_Mutation = "None",
    Collect_Weight = 0,
    Collect_WeightMode = "Above",
    Collect_StopWhenFull = false,

    -- Planting
    AutoPlant = false,
    AutoReclaimer = false,
    Reclaim_SelectedPlants = {},
    Reclaim_Delay = 0.5,

    AutoShovel = false,
    Shovel_SelectedPlants = {},
    Shovel_Delay = 0.5,

    AutoWatering = false,
    Water_SelectedPlants = {},
    Water_Delay = 0.5,
    Water_UsesPerDelay = 3,

    PlantInOtherPlants = false,
    Plant_SelectedSeed = "All Seeds",
    Plant_PositionMode = "Player Position",
    Plant_Delay = 0.05,

    -- Selling: Crops
    AutoSellCrops = false,
    Sell_WaitMaxBackpack = false,
    Sell_ExcludeFruit = "None",
    Sell_ExcludeCategory = "None",
    Sell_ExcludeVariant = "None",
    Sell_ExcludeMutation = "None",
    Sell_Weight = 0,
    Sell_WeightMode = "Above",

    -- Selling: Pets (Moved to Pets Tab)
    AutoSellPets = false,
    Sell_TargetPet = "All Pets", -- Whitelist / Selection: All Pets or specific species
    Sell_ExcludePetVariant = "None",
    Sell_ExcludePetMutation = "None",
    Sell_ExcludePetWeight = 0,
    Sell_ExcludePetWeightMode = "Above",
    Sell_EquipSlot = "None",
    Sell_SlotCooldown = 5.0,

    -- Pet Tab: Egg Hatching & Egg Placement
    Egg_ESP = false,
    AutoPlaceEggs = false,
    PlaceOnlyWhenNoEgg = false,
    PlaceEgg_Selected = "All Eggs",
    PlaceEgg_PositionMode = "Row Position",
    PlaceEgg_Delay = 0.1,
    PlaceEgg_MaxGarden = 15,
    PlaceEgg_EquipSlot = "None",

    AutoHatchEggs = false,
    WaitAllEggsReady = false,
    HatchEgg_Selected = "All Eggs",
    Hatch_ExcludePets = {},
    Hatch_ExcludeWeight = 0,
    Hatch_ExcludeWeightMode = "None",
    Hatch_CheckDelay = 0.1,
    HatchEgg_EquipSlot = "None",
    Hatch_SlotCooldown = 7.0,

    -- Shop Tab
    AutoBuy_SelectedEgg = false,
    AutoBuy_AllEggs = false,
    AutoBuy_SelectedGear = false,
    AutoBuy_AllGears = false,
    AutoBuy_SelectedSeed = false,
    AutoBuy_AllSeeds = false,
    AutoBuy_SelectedCosmetic = false,
    AutoBuy_AllCosmetics = false,
    Shop_BuyDelay = 0.35,

    -- Shop Tab: Auto Craft
    AutoCraft_Plants = false,
    AutoCraft_SelectedPlant = "None",
    AutoCraft_Gears = false,
    AutoCraft_SelectedGear = "None",
    AutoCraft_Delay = 0.5,

    -- Misc: Visual Optimization & Glitches
    HidePlants = false,
    HideFruits = false,
    InfiniteSprinkler = false,
    InfiniteSprinkler_Target = "All Sprinklers",

    -- Events Tab: Fall Bloom, Event Shops, Acorn Chaos & Weekly Events
    AutoCollect_FallBloomFruit = false,
    AutoSubmitFallBloom = false,
    AutoSubmitFallBloom_Delay = 1.0,

    AutoBuy_EventSeeds = false,
    AutoBuy_SelectedEventSeed = "All Event Seeds",
    AutoBuy_EventGears = false,
    AutoBuy_SelectedEventGear = "All Event Gears",
    AutoBuy_EventPets = false,
    AutoBuy_SelectedEventPet = "All Event Pets",
    AutoBuy_EventCosmetics = false,
    AutoBuy_SelectedEventCosmetic = "All Event Cosmetics",

    AutoAttackAcorns = false,
    AutoEquipShovel = true,

    -- General
    MaxBackpackCapacity = 500,
    BatchSize = 35,
    HarvestDelay = 0.1,
    SellCheckDelay = 0.25
}

-- Forward References for UI Objects
local autoCollectAllToggle
local instantCollectAllToggle
local autoCollectFilteredToggle
local collectStopWhenFullToggle
local collectFruitListObj
local collectCategoryListObj
local collectVariantListObj
local collectMutationListObj
local collectWeightModeListObj

local autoPlantToggle
local plantInOtherPlantsToggle
local plantSeedListObj
local plantPositionModeListObj

local autoSellCropsToggle
local sellWaitMaxToggle
local sellExcludeFruitListObj
local sellExcludeCategoryListObj
local sellExcludeVariantListObj
local sellExcludeMutationListObj
local sellWeightModeListObj

local autoSellPetsToggle
local sellTargetPetListObj
local sellExcludePetListObj
local sellExcludePetVariantListObj
local sellExcludePetMutationListObj
local sellExcludePetWeightModeListObj
local sellPetSlotListObj

local autoPlaceEggsToggle
local placeOnlyWhenNoEggToggle
local placeEggListObj
local placeEggPositionModeListObj
local placeEggSlotListObj

local autoHatchEggsToggle
local waitAllEggsReadyToggle
local hatchEggListObj
local hatchExcludePetListObj
local hatchExcludeWeightModeListObj
local hatchEggSlotListObj

local autoCraftPlantsToggle
local selectCraftPlantListObj
local autoCraftGearsToggle
local selectCraftGearListObj

local hidePlantsToggle
local hideFruitsToggle
local infiniteSprinklerToggle
local selectSprinklerListObj

local autoCollectFallBloomToggle
local autoSubmitFallBloomToggle
local autoBuyEventSeedsToggle
local selectEventSeedListObj
local autoBuyEventGearsToggle
local selectEventGearListObj
local autoBuyEventPetsToggle
local selectEventPetListObj
local autoBuyEventCosmeticsToggle
local selectEventCosmeticListObj

local autoAttackAcornsToggle
local autoEquipShovelToggle

-- Acorn Chaos Tracking & Execution Engine
local activeAcornIds = {}

local function getShovelTool()
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    local character = LocalPlayer.Character
    if character then
        for _, item in ipairs(character:GetChildren()) do
            if item:IsA("Tool") and (item.Name == "Shovel [Destroy Plants]" or item.Name:find("Shovel")) then
                return item
            end
        end
    end
    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA("Tool") and (item.Name == "Shovel [Destroy Plants]" or item.Name:find("Shovel")) then
                return item
            end
        end
    end
    return nil
end

local function equipShovelTool()
    local shovel = getShovelTool()
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if shovel and humanoid and shovel.Parent ~= character then
        pcall(function()
            humanoid:EquipTool(shovel)
        end)
    end
    return shovel
end

local function unequipShovelTool()
    local shovel = getShovelTool()
    local character = LocalPlayer.Character
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if shovel and character and shovel.Parent == character then
        pcall(function()
            if backpack then
                shovel.Parent = backpack
            else
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid:UnequipTools()
                end
            end
        end)
    end
end

local function hasActiveAcorns()
    if next(activeAcornIds) ~= nil then
        return true
    end
    local acl = Workspace:FindFirstChild("AcornChaosLocal")
    if acl and #acl:GetChildren() > 0 then
        return true
    end
    return false
end

local function crackAcornById(acornId, modelInstance)
    if not acornId and not modelInstance then return end
    if acornId then
        activeAcornIds[acornId] = nil
    end
    equipShovelTool()
    local crackRemote = AcornCrackRemote or (ReplicatedStorage:FindFirstChild("GameEvents") and ReplicatedStorage.GameEvents:FindFirstChild("AcornChaos") and ReplicatedStorage.GameEvents.AcornChaos:FindFirstChild("Crack"))
    if crackRemote and acornId then
        crackRemote:FireServer(acornId)
    end
    local shovel = getShovelTool()
    if shovel and shovel.Parent == LocalPlayer.Character then
        pcall(function()
            shovel:Activate()
        end)
    end
    if modelInstance and modelInstance.Parent then
        pcall(function()
            modelInstance:Destroy()
        end)
    end
end

local function crackAllActiveAcorns()
    local count = 0
    equipShovelTool()
    for id, _ in pairs(activeAcornIds) do
        crackAcornById(id)
        count = count + 1
    end
    local acl = Workspace:FindFirstChild("AcornChaosLocal")
    if acl then
        for _, child in ipairs(acl:GetChildren()) do
            local id = child:GetAttribute("Id") or child:GetAttribute("AcornId") or child.Name
            crackAcornById(id, child)
            count = count + 1
        end
    end
    task.wait(0.1)
    if not hasActiveAcorns() then
        unequipShovelTool()
    end
    return count
end

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

local function getUIListMultipleVals(listObj, defaultVal)
    local selected = {}
    if listObj then
        if listObj.SelectedItems and #listObj.SelectedItems > 0 then
            for _, item in ipairs(listObj.SelectedItems) do
                if type(item) == "table" then
                    table.insert(selected, item.Name or item[1] or tostring(item))
                elseif type(item) == "string" then
                    table.insert(selected, item)
                end
            end
        elseif listObj.SelectedItem then
            local sel = listObj.SelectedItem
            if type(sel) == "table" then
                table.insert(selected, sel.Name or sel[1] or tostring(sel))
            elseif type(sel) == "string" then
                table.insert(selected, sel)
            end
        end
    end
    if #selected == 0 and defaultVal then
        table.insert(selected, defaultVal)
    end
    return selected
end

local function isToggleActive(toggleObj, defaultState, hubTitle)
    if type(defaultState) == "boolean" and defaultState == true then
        return true
    end
    if toggleObj then
        if type(toggleObj.Get) == "function" then
            local st = toggleObj.Get()
            if st ~= nil then return st end
        elseif toggleObj.State ~= nil then
            return toggleObj.State
        elseif toggleObj.Value ~= nil then
            return toggleObj.Value
        end
    end
    return defaultState or false
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

local function getPetBackpackStatus()
    local curCount = 0
    local maxCap = 0
    pcall(function()
        local dsMod = ReplicatedStorage:FindFirstChild("Modules") and ReplicatedStorage.Modules:FindFirstChild("DataService")
        local ds = dsMod and require(dsMod)
        local data = ds and ds:GetData()
        if data and data.PetsData then
            local pets = data.PetsData
            if pets.MutableStats and pets.MutableStats.MaxPetsInInventory then
                maxCap = tonumber(pets.MutableStats.MaxPetsInInventory) or 0
            end
            if pets.PetInventory and pets.PetInventory.Data and type(pets.PetInventory.Data) == "table" then
                local count = 0
                for _, _ in pairs(pets.PetInventory.Data) do
                    count = count + 1
                end
                curCount = count
            end
        end
    end)
    if maxCap > 0 then
        return curCount, maxCap
    end

    pcall(function()
        local pGui = LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:FindFirstChild("PlayerGui")
        if pGui then
            local bpGui = pGui:FindFirstChild("BackpackGui")
            if bpGui then
                for _, l in ipairs(bpGui:GetDescendants()) do
                    if l:IsA("TextLabel") and l.Text:lower():find("pet") and l.Text:find("/") then
                        local c, m = l.Text:match("(%d+)%s*/%s*(%d+)")
                        if c and m and tonumber(m) >= 20 then
                            curCount = tonumber(c)
                            maxCap = tonumber(m)
                            return
                        end
                    end
                end
            end
            for _, l in ipairs(pGui:GetDescendants()) do
                if l:IsA("TextLabel") and (l.Text:find("Pet Items") or (l.Text:lower():find("pet") and not l.Text:lower():find("active"))) and l.Text:find("/") then
                    local c, m = l.Text:match("(%d+)%s*/%s*(%d+)")
                    if c and m and tonumber(m) >= 20 then
                        curCount = tonumber(c)
                        maxCap = tonumber(m)
                        return
                    end
                end
            end
        end
    end)
    return curCount, maxCap
end

local function getPetBackpackCount()
    local cur, cap = getPetBackpackStatus()
    if cur and cur > 0 then return cur end
    local count = 0
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        for _, item in ipairs(bp:GetChildren()) do
            if item:IsA("Tool") and (item:GetAttribute("PET_UUID") or item:GetAttribute("PetType") or item.Name:find("Age")) then
                count = count + 1
            end
        end
    end
    local char = LocalPlayer.Character
    if char then
        for _, item in ipairs(char:GetChildren()) do
            if item:IsA("Tool") and (item:GetAttribute("PET_UUID") or item:GetAttribute("PetType") or item.Name:find("Age")) then
                count = count + 1
            end
        end
    end
    return count
end

local function getPetBackpackCapacity()
    local cur, cap = getPetBackpackStatus()
    if cap and cap > 0 then return cap end
    local maxCap = 50
    pcall(function()
        local dsMod = ReplicatedStorage:FindFirstChild("Modules") and ReplicatedStorage.Modules:FindFirstChild("DataService")
        local ds = dsMod and require(dsMod)
        local data = ds and ds:GetData()
        if data then
            local pets = data.PetsData
            local purchased = (pets and tonumber(pets.PurchasedPetInventorySlots)) or tonumber(data.PurchasedInventorySlots) or 0
            local pLife = data.GardenCoinShopStats and data.GardenCoinShopStats.LifetimePurchases
            local coinSlots = 0
            if pLife then
                coinSlots = (tonumber(pLife["Pet Inventory Capacity"]) or 0) * 10
                          + (tonumber(pLife["Pet Inventory Capacity +"]) or 0) * 10
                          + (tonumber(pLife["Pet Inventory Capacity ++"]) or 0) * 10
                          + (tonumber(pLife["Pet Inventory Capacity Deluxe"]) or 0) * 5
            end
            maxCap = 50 + (purchased * 10) + coinSlots
        end
    end)
    return maxCap
end

local function isPetBackpackFull()
    local cur, cap = getPetBackpackStatus()
    if cur and cap and cap > 0 then
        return cur >= cap
    end
    local c = getPetBackpackCount()
    local m = getPetBackpackCapacity()
    return c >= m
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
    local uuid = tool:GetAttribute("PET_UUID") or tool:GetAttribute("UUID") or tool:GetAttribute("Id") or tool.Name:match("%b{}")
    if not uuid and not tool:GetAttribute("PetType") and not tool.Name:find("Age") then
        return nil
    end

    local toolName = tostring(tool.Name)
    local petSpecies = tool:GetAttribute("f") or toolName
    petSpecies = tostring(petSpecies)
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
        if type(petName) == "string" and petName ~= "None" and petName ~= "All Pets" and nameLower:find(petName:lower()) then
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

-- Comprehensive & Impenetrable Pet Protection Function (Favorite, Locked, Loadouts 1-6)
local function isPetProtected(tool, petInfo)
    if not tool then return true end

    -- 1. Direct Tool Attribute Checks (Favorite / Locked / Equipped)
    if tool:GetAttribute("d") == true then return true end
    if tool:GetAttribute("Favorite") == true or tool:GetAttribute("IsFavorite") == true or tool:GetAttribute("Favorited") == true then return true end
    if tool:GetAttribute("Locked") == true or tool:GetAttribute("Lock") == true or tool:GetAttribute("IsLocked") == true then return true end
    if tool:GetAttribute("Equipped") == true or tool:GetAttribute("IsEquipped") == true then return true end

    local uuid = (petInfo and petInfo.UUID) or tool:GetAttribute("PET_UUID") or tool:GetAttribute("UUID") or tool:GetAttribute("Id") or tool.Name:match("%b{}")
    local cleanUuid = nil
    if uuid and type(uuid) == "string" then
        cleanUuid = uuid:gsub("[{}]", "")
    end

    -- 2. DataService Deep Verification (Inventory Flags & All Loadout Slots 1-6)
    pcall(function()
        local dsMod = ReplicatedStorage:FindFirstChild("Modules") and ReplicatedStorage.Modules:FindFirstChild("DataService")
        local ds = dsMod and require(dsMod)
        local data = ds and ds:GetData()
        if data and data.PetsData then
            local pets = data.PetsData

            -- Check all Loadout Slots (1 to 6) - ANY pet in ANY team is 100% protected
            local loadouts = pets.PetLoadouts or pets.Loadouts or pets.Teams
            if loadouts and type(loadouts) == "table" and cleanUuid then
                for _, loadout in pairs(loadouts) do
                    if type(loadout) == "table" then
                        for _, petId in pairs(loadout) do
                            local strId = tostring(petId):gsub("[{}]", "")
                            if strId == cleanUuid then
                                return true
                            end
                        end
                    end
                end
            end

            -- Check EquippedPets
            if pets.EquippedPets and type(pets.EquippedPets) == "table" and cleanUuid then
                for _, petId in pairs(pets.EquippedPets) do
                    local strId = tostring(petId):gsub("[{}]", "")
                    if strId == cleanUuid then
                        return true
                    end
                end
            end

            -- Check PetInventory Data for Favorite / Locked flags
            if pets.PetInventory and pets.PetInventory.Data and cleanUuid then
                local petEntry = pets.PetInventory.Data[cleanUuid] or pets.PetInventory.Data["{" .. cleanUuid .. "}"] or pets.PetInventory.Data[uuid]
                if petEntry and petEntry.PetData then
                    local pd = petEntry.PetData
                    if pd.IsFavorite == true or pd.Favorite == true or pd.d == true or pd.Locked == true or pd.Lock == true then
                        return true
                    end
                end
            end
        end
    end)

    return false
end

-- Evaluator for Auto Selling Pets (Strict Whitelist + Exclusions + Impenetrable Protection)
local function shouldSellPetTool(toolOrInfo)
    local tool = nil
    local petInfo = nil

    if typeof(toolOrInfo) == "Instance" and toolOrInfo:IsA("Tool") then
        tool = toolOrInfo
        petInfo = getPetToolInfo(tool)
    elseif type(toolOrInfo) == "table" and toolOrInfo.Tool and typeof(toolOrInfo.Tool) == "Instance" and toolOrInfo.Tool:IsA("Tool") then
        tool = toolOrInfo.Tool
        petInfo = toolOrInfo
    else
        return false
    end

    if not tool or not tool.Parent then return false end

    -- 1. ABSOLUTE BULLETPROOF SAFETY: Check if pet is Favorited, Locked, or in ANY Loadout (1-6)
    if isPetProtected(tool, petInfo) then
        return false -- NEVER SELL PROTECTED PETS!
    end

    local petSpecies = (petInfo and petInfo.PetSpecies) or tool:GetAttribute("f") or tool.Name
    local toolName = (petInfo and petInfo.ToolName) or tool.Name
    local cleanSpecies = tostring(petSpecies):lower():gsub("[%s%p]", "")
    local cleanName = tostring(toolName):lower():gsub("[%s%p]", "")

    -- 2. Exclusion: Specific Pet Exclusions (Multi-Select)
    local excludedPets = getUIListMultipleVals(sellExcludePetListObj, State.Sell_ExcludePets or {})
    for _, exPet in ipairs(excludedPets) do
        local exLower = tostring(exPet):lower():gsub("[%s%p]", "")
        if exLower ~= "none" and exLower ~= "" then
            if cleanSpecies:find(exLower, 1, true) or exLower:find(cleanSpecies, 1, true) or cleanName:find(exLower, 1, true) then
                return false -- Excluded from selling!
            end
        end
    end

    -- 3. Exclusion: Variant Exclusions
    local exVariant = tostring(getUIListVal(sellExcludePetVariantListObj, State.Sell_ExcludePetVariant or "None"))
    if exVariant ~= "None" and exVariant ~= "" and petInfo and petInfo.Variant then
        if petInfo.Variant:lower() == exVariant:lower() then
            return false
        end
    end

    -- 4. Exclusion: Mutation Exclusions
    local exMutation = tostring(getUIListVal(sellExcludePetMutationListObj, State.Sell_ExcludePetMutation or "None"))
    if exMutation ~= "None" and exMutation ~= "" then
        local mutKey = exMutation:lower()
        if petInfo and petInfo.Mutations and petInfo.Mutations[mutKey] then
            return false
        end
        if tool:GetAttribute(exMutation) == true or cleanName:find(mutKey, 1, true) then
            return false
        end
    end

    -- 5. Exclusion: Weight Filter
    local exWeightMode = tostring(getUIListVal(sellExcludePetWeightModeListObj, State.Sell_ExcludePetWeightMode or "None"))
    local exWeightThreshold = tonumber(State.Sell_ExcludePetWeight) or 0
    if exWeightThreshold > 0 and petInfo and petInfo.Weight then
        if exWeightMode == "Above" and petInfo.Weight >= exWeightThreshold then
            return false
        elseif exWeightMode == "Lower" and petInfo.Weight <= exWeightThreshold then
            return false
        end
    end

    -- 6. Target Pet Whitelist Check (Multi-Select or Single-Select)
    local targetPets = getUIListMultipleVals(sellTargetPetListObj, {State.Sell_TargetPet or "All Pets"})
    local isAllPets = (#targetPets == 0)
    if not isAllPets then
        for _, tp in ipairs(targetPets) do
            local clean = tostring(tp):lower():gsub("[%s%p]", "")
            if clean == "allpets" or clean == "all" or clean == "" then
                isAllPets = true
                break
            end
        end
    end

    if not isAllPets then
        local matchedTarget = false
        for _, tp in ipairs(targetPets) do
            local targetLower = tostring(tp):lower():gsub("[%s%p]", "")
            if targetLower ~= "none" and targetLower ~= "" then
                if cleanSpecies:find(targetLower, 1, true) or targetLower:find(cleanSpecies, 1, true) or cleanName:find(targetLower, 1, true) then
                    matchedTarget = true
                    break
                end
            end
        end
        if not matchedTarget then
            return false
        end
    end

    return true -- Eligible to sell!
end

-- =========================================================================
-- =========================================================================
-- True Remote Harvest Engine (Instant Burst Flood & Filtered Vacuum)
-- =========================================================================
task.spawn(function()
    while true do
        if _G.GAG_SESSION ~= currentSession then break end

        local collectAll = isToggleActive(autoCollectAllToggle, State.AutoCollectAll, "⚡ Auto Collect ALL (No Filter)")
        local instantAll = isToggleActive(instantCollectAllToggle, State.InstantCollectAll, "⚡ Instant Collect ALL")
        local collectFiltered = isToggleActive(autoCollectFilteredToggle, State.AutoCollectFiltered, "🌱 Auto Collect (Filtered)")
        local stopFull = isToggleActive(collectStopWhenFullToggle, State.Collect_StopWhenFull)

        if collectAll or instantAll or collectFiltered then
            task.wait(State.HarvestDelay or 0.08)
            pcall(function()
                local colRemote = getCollectRemote()
                if not colRemote then return end

                local farmFolder = Workspace:FindFirstChild("Farm") or Workspace

                -- 1) HIGH-CONCURRENCY 2-3 SECOND NETWORK BURST ENGINE (Instant Collect ALL Only)
                if instantAll then
                    local burstDuration = 2.5
                    local burstStart = tick()

                    while (tick() - burstStart < burstDuration) and isToggleActive(instantCollectAllToggle, State.InstantCollectAll) do
                        local allFruits = {}

                        for _, farm in ipairs(farmFolder:GetChildren()) do
                            local important = farm:FindFirstChild("Important")
                            local plantsFolder = important and important:FindFirstChild("Plants_Physical")
                            if plantsFolder then
                                for _, plant in ipairs(plantsFolder:GetChildren()) do
                                    local fruitsFolder = plant:FindFirstChild("Fruits")
                                    if fruitsFolder then
                                        for _, fg in ipairs(fruitsFolder:GetChildren()) do
                                            table.insert(allFruits, fg)
                                        end
                                    end
                                end
                            end
                        end

                        if #allFruits == 0 then break end

                        -- Rapid parallel batch dispatch to saturate packet pipeline and bypass backpack checks
                        local batchSize = 35
                        for i = 1, #allFruits, batchSize do
                            local subBatch = {}
                            for j = i, math.min(i + batchSize - 1, #allFruits) do
                                table.insert(subBatch, allFruits[j])
                            end
                            task.spawn(function()
                                pcall(function()
                                    colRemote:FireServer(subBatch)
                                end)
                            end)
                        end

                        task.wait(0.03) -- Micro-yield maintains high network throughput without freezing VM
                    end

                    -- Brief cooldown between multi-second burst waves
                    if isToggleActive(instantCollectAllToggle, State.InstantCollectAll) then
                        task.wait(0.35)
                    end
                    return
                end

                -- 2) STANDARD CONTROLLED HARVEST ENGINE (Auto Collect ALL & Filtered)
                if stopFull and isBackpackFull() then
                    task.wait(0.3)
                    return
                end

                local batch = {}
                for _, farm in ipairs(farmFolder:GetChildren()) do
                    if not isToggleActive(autoCollectAllToggle, State.AutoCollectAll) 
                       and not isToggleActive(autoCollectFilteredToggle, State.AutoCollectFiltered) then 
                        break 
                    end
                    if stopFull and isBackpackFull() then break end

                    local important = farm:FindFirstChild("Important")
                    local plantsFolder = important and important:FindFirstChild("Plants_Physical")
                    if plantsFolder then
                        for _, plant in ipairs(plantsFolder:GetChildren()) do
                            if not isToggleActive(autoCollectAllToggle, State.AutoCollectAll) 
                               and not isToggleActive(autoCollectFilteredToggle, State.AutoCollectFiltered) then 
                                break 
                            end
                            if stopFull and isBackpackFull() then break end

                            local fruitsFolder = plant:FindFirstChild("Fruits")
                            if fruitsFolder then
                                for _, fg in ipairs(fruitsFolder:GetChildren()) do
                                    if not isToggleActive(autoCollectAllToggle, State.AutoCollectAll) 
                                       and not isToggleActive(autoCollectFilteredToggle, State.AutoCollectFiltered) then 
                                        break 
                                    end
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
                                        local maxBatch = State.BatchSize or 35
                                        if #batch >= maxBatch then
                                            pcall(function()
                                                colRemote:FireServer(batch)
                                            end)
                                            batch = {}
                                            task.wait(0.04)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end

                if #batch > 0 and (isToggleActive(autoCollectAllToggle, State.AutoCollectAll) or isToggleActive(autoCollectFilteredToggle, State.AutoCollectFiltered)) then
                    pcall(function()
                        colRemote:FireServer(batch)
                    end)
                    batch = {}
                end
            end)
        else
            task.wait(0.5)
        end
    end
end)
-- Auto-Plant Engine (Player Position, Random Position, Existing Plant)
-- =========================================================================
task.spawn(function()
    while true do
        if _G.GAG_SESSION ~= currentSession then break end

        local autoPlant = isToggleActive(autoPlantToggle, State.AutoPlant, "🌱 Auto Plant")
        if autoPlant then
            local delayTime = math.clamp(tonumber(State.Plant_Delay) or 0.05, 0.01, 1.0)
            task.wait(delayTime)

            pcall(function()
                local selectedSeed = tostring(getUIListVal(plantSeedListObj, State.Plant_SelectedSeed or "All Seeds"))
                local posMode = tostring(getUIListVal(plantPositionModeListObj, State.Plant_PositionMode or "Player Position"))

            -- Find candidate seed tools in Backpack or Character
            local allTools = getAllPlayerTools()
            local seedTool = nil
            local seedName = nil

            for _, tool in ipairs(allTools) do
                if tool.Parent and tool:IsA("Tool") and not tool:GetAttribute("PET_UUID") then
                    local tName = tool.Name
                    local lowerName = tName:lower()
                    local sAttr = tool:GetAttribute("Seed") or tool:GetAttribute("f")
                    local sAttrStr = sAttr and tostring(sAttr):lower() or ""

                    if lowerName:find("seed") or sAttrStr:find("seed") or (sAttr ~= nil and sAttr ~= "") then
                        local derivedSeed = sAttr and tostring(sAttr) or tName:gsub("%s*[sS]eed.*", ""):gsub("%[.*%]", ""):gsub("^%s+", ""):gsub("%s+$", "")
                        
                        if selectedSeed == "All Seeds" or selectedSeed == "None" or selectedSeed == "" then
                            seedTool = tool
                            seedName = derivedSeed
                            break
                        else
                            local cleanSelected = selectedSeed:lower():gsub("%s*[sS]eed%s*", ""):gsub("%[.*%]", ""):gsub("^%s+", ""):gsub("%s+$", "")
                            if lowerName:find(cleanSelected, 1, true) or sAttrStr:find(cleanSelected, 1, true) or derivedSeed:lower():find(cleanSelected, 1, true) then
                                seedTool = tool
                                seedName = derivedSeed
                                break
                            end
                        end
                    end
                end
            end

            if not seedTool or not seedName then return end

            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local targetPos = nil

            local function getMyFarmPlot()
                local farmFolder = Workspace:FindFirstChild("Farm")
                if not farmFolder then return nil end
                for _, f in ipairs(farmFolder:GetChildren()) do
                    local imp = f:FindFirstChild("Important")
                    local data = imp and imp:FindFirstChild("Data")
                    local ownerVal = (data and data:FindFirstChild("Owner") and data.Owner.Value) or f:GetAttribute("Owner")
                    if ownerVal == LocalPlayer.Name or ownerVal == tostring(LocalPlayer.UserId) then
                        return f
                    end
                end
                return nil
            end

            if posMode == "Player Position" then
                if root then
                    targetPos = root.Position - Vector3.new(0, 2.5, 0)
                end
            elseif posMode == "Random Position" then
                local myFarm = getMyFarmPlot()
                if myFarm and myFarm:FindFirstChild("Important") then
                    local locs = myFarm.Important:FindFirstChild("Plant_Locations")
                    if locs and #locs:GetChildren() > 0 then
                        local spots = locs:GetChildren()
                        local spot = spots[math.random(1, #spots)]
                        if spot:IsA("BasePart") then
                            local hx = spot.Size.X * 0.45
                            local hz = spot.Size.Z * 0.45
                            targetPos = spot.Position + Vector3.new((math.random() - 0.5) * 2 * hx, 0.1, (math.random() - 0.5) * 2 * hz)
                        end
                    end
                end
                if not targetPos and root then
                    targetPos = root.Position + Vector3.new(math.random(-15, 15), -2.5, math.random(-15, 15))
                end
            elseif posMode == "Existing Plant" then
                local seedLower = seedName:lower()
                local myFarm = getMyFarmPlot()
                local farmFolder = Workspace:FindFirstChild("Farm") or Workspace
                local searchFarms = myFarm and {myFarm} or farmFolder:GetChildren()
                local matchedPlantPart = nil

                for _, farm in ipairs(searchFarms) do
                    local imp = farm:FindFirstChild("Important")
                    local plants = imp and imp:FindFirstChild("Plants_Physical")
                    if plants then
                        for _, plant in ipairs(plants:GetChildren()) do
                            local pNameLower = plant.Name:lower()
                            if pNameLower:find(seedLower, 1, true) or seedLower:find(pNameLower, 1, true) then
                                local pPart = plant:FindFirstChildWhichIsA("BasePart", true)
                                if pPart then
                                    matchedPlantPart = pPart
                                    break
                                end
                            end
                        end
                    end
                    if matchedPlantPart then break end
                end

                if matchedPlantPart then
                    targetPos = matchedPlantPart.Position + Vector3.new((math.random() - 0.5) * 0.2, 0, (math.random() - 0.5) * 0.2)
                elseif root then
                    targetPos = root.Position - Vector3.new(0, 2.5, 0)
                end
            elseif posMode == "Inside Other Plant" or posMode == "Inside Any Plant" then
                local myFarm = getMyFarmPlot()
                local farmFolder = Workspace:FindFirstChild("Farm") or Workspace
                local searchFarms = myFarm and {myFarm} or farmFolder:GetChildren()
                local allPlants = {}
                for _, farm in ipairs(searchFarms) do
                    local imp = farm:FindFirstChild("Important")
                    local plants = imp and imp:FindFirstChild("Plants_Physical")
                    if plants then
                        for _, plant in ipairs(plants:GetChildren()) do
                            local pPart = plant:FindFirstChildWhichIsA("BasePart", true)
                            if pPart then
                                table.insert(allPlants, pPart)
                            end
                        end
                    end
                end
                if #allPlants > 0 then
                    local chosen = allPlants[math.random(1, #allPlants)]
                    targetPos = chosen.Position + Vector3.new((math.random() - 0.5) * 0.2, 0, (math.random() - 0.5) * 0.2)
                elseif root then
                    targetPos = root.Position - Vector3.new(0, 2.5, 0)
                end
            elseif posMode == "In Mid-Air (Above Player)" or posMode == "In Mid-Air (Floating)" or posMode == "In Mid-Air" then
                if root then
                    local airHeight = tonumber(State.AirPlantHeight) or 15
                    targetPos = root.Position + Vector3.new(0, airHeight, 0)
                end
            elseif posMode == "Out of Garden" then
                if root then
                    local angle = math.random() * math.pi * 2
                    local dist = math.random(90, 220)
                    targetPos = root.Position + Vector3.new(math.cos(angle) * dist, -2.5, math.sin(angle) * dist)
                end
            elseif posMode == "Anywhere (Free Spatial)" or posMode == "Anywhere" then
                if root then
                    targetPos = root.Position + Vector3.new(math.random(-150, 150), math.random(-5, 60), math.random(-150, 150))
                end
            end

            if not targetPos and root then
                targetPos = root.Position - Vector3.new(0, 2.5, 0)
            end

            if targetPos and seedName then
                local pRemote = getPlantRemote()
                if pRemote then
                    pcall(function()
                        if seedTool.Parent ~= char and char:FindFirstChild("Humanoid") then
                            char.Humanoid:EquipTool(seedTool)
                        end
                    end)
                    pcall(function()
                        pRemote:FireServer(targetPos, seedName)
                    end)
                    pcall(function()
                        seedTool:Activate()
                    end)
                end
            end
        end)
    else
        task.wait(0.5)
    end
    end
end)

-- =========================================================================
-- Manual Plant in Other Plants / Seeds Engine
-- =========================================================================
local lastManualPlantTime = 0
local UserInputService = game:GetService("UserInputService")

local function triggerManualPlant(customTargetPos)
    local isPlantInOthersActive = isToggleActive(plantInOtherPlantsToggle, State.PlantInOtherPlants, "🌱 Plant In Other Plants")
    if not isPlantInOthersActive then return end

    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    -- Check if player has a Seed tool equipped in Character
    local seedTool = nil
    for _, item in ipairs(char:GetChildren()) do
        if item:IsA("Tool") and not item:GetAttribute("PET_UUID") then
            local tName = item.Name:lower()
            local seedAttr = tostring(item:GetAttribute("Seed") or item:GetAttribute("f") or ""):lower()
            if tName:find("seed") or seedAttr:find("seed") or item:GetAttribute("Seed") ~= nil then
                seedTool = item
                break
            end
        end
    end

    if not seedTool then return end
    local seedName = seedTool:GetAttribute("Seed") or seedTool:GetAttribute("f") or seedTool.Name:gsub("%s*[sS]eed.*", ""):gsub("%[.*%]", ""):gsub("^%s+", ""):gsub("%s+$", "")

    local now = tick()
    if now - lastManualPlantTime < 0.04 then return end
    lastManualPlantTime = now

    local targetPos = customTargetPos

    if not targetPos then
        local mouse = LocalPlayer:GetMouse()
        local mouseTarget = mouse and mouse.Target
        local mouseHit = mouse and mouse.Hit

        local foundPlantPart = nil
        if mouseTarget then
            local current = mouseTarget
            while current and current ~= Workspace do
                if current.Parent and (current.Parent.Name == "Plants_Physical" or current.Parent.Name == "Plant_Locations" or current.Name:find("Plant") or current.Name:find("Crop")) then
                    foundPlantPart = mouseTarget:IsA("BasePart") and mouseTarget or current:FindFirstChildWhichIsA("BasePart", true)
                    break
                end
                current = current.Parent
            end
        end

        if foundPlantPart then
            targetPos = foundPlantPart.Position + Vector3.new((math.random() - 0.5) * 0.2, 0, (math.random() - 0.5) * 0.2)
        elseif mouseHit then
            local farmFolder = Workspace:FindFirstChild("Farm") or Workspace
            local closestPart = nil
            local minDist = 35
            for _, farm in ipairs(farmFolder:GetChildren()) do
                local imp = farm:FindFirstChild("Important")
                local plants = imp and imp:FindFirstChild("Plants_Physical")
                if plants then
                    for _, plant in ipairs(plants:GetChildren()) do
                        local pPart = plant:FindFirstChildWhichIsA("BasePart", true)
                        if pPart then
                            local d = (pPart.Position - mouseHit.Position).Magnitude
                            if d < minDist then
                                minDist = d
                                closestPart = pPart
                            end
                        end
                    end
                end
            end
            if closestPart then
                targetPos = closestPart.Position + Vector3.new((math.random() - 0.5) * 0.2, 0, (math.random() - 0.5) * 0.2)
            else
                targetPos = mouseHit.Position
            end
        else
            targetPos = root.Position - Vector3.new(0, 2.5, 0)
        end
    end

    if targetPos and seedName then
        local pRemote = getPlantRemote()
        if pRemote then
            pcall(function() pRemote:FireServer(targetPos, seedName) end)
        end
    end
end

-- Hook UserInputService for direct manual clicks / screen taps with equipped seed
pcall(function()
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            triggerManualPlant()
        end
    end)
end)

-- Tool activation hook on character
local function hookToolActivation(tool)
    if not tool or not tool:IsA("Tool") then return end
    pcall(function()
        tool.Activated:Connect(function()
            triggerManualPlant()
        end)
    end)
end

local function hookCharacterTools(char)
    if not char then return end
    for _, item in ipairs(char:GetChildren()) do
        if item:IsA("Tool") then
            hookToolActivation(item)
        end
    end
    char.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            hookToolActivation(child)
        end
    end)
end

pcall(function()
    if LocalPlayer.Character then
        hookCharacterTools(LocalPlayer.Character)
    end
    LocalPlayer.CharacterAdded:Connect(function(char)
        task.wait(0.2)
        hookCharacterTools(char)
    end)
end)

-- =========================================================================
-- Smart Auto-Sell Engine (Fast Crops & Pets) - Dedicated Independent Loops
-- =========================================================================

-- 1. Dedicated Auto Sell Pets Loop
task.spawn(function()
    while true do
        if _G.GAG_SESSION ~= currentSession then break end

        local autoSellPets = isToggleActive(autoSellPetsToggle, State.AutoSellPets, "🐾 Auto Sell Pets")
        if autoSellPets then
            local ok, err = pcall(function()
                local allTools = getAllPlayerTools()
                local sellSlot = getUIListVal(sellPetSlotListObj, State.Sell_EquipSlot or "None")
                local hasSlotSelected = (sellSlot ~= "None" and sellSlot ~= "")

                local petToolBatch = {}
                for _, tool in ipairs(allTools) do
                    if tool.Parent and tool:IsA("Tool") and (tool:GetAttribute("PET_UUID") or tool:GetAttribute("PetType") or tool.Name:find("Age") or tool:GetAttribute("f")) then
                        if shouldSellPetTool(tool) then
                            table.insert(petToolBatch, tool)
                        end
                    end
                end

                if #petToolBatch > 0 then
                    _G._gag_selling_pets = true
                    if hasSlotSelected then
                        local sellSlotNum = tonumber(tostring(sellSlot):match("%d+"))
                        if sellSlotNum then
                            local sellCooldown = math.max(3.0, tonumber(State.Sell_SlotCooldown) or 5.0)
                            equipPetSlot(sellSlot, true, sellCooldown)
                        end
                    end

                    local ge = ReplicatedStorage:FindFirstChild("GameEvents")
                    local sellShop = ge and ge:FindFirstChild("SellPetShopSelected")
                    local sellOne = ge and ge:FindFirstChild("SellPet_RE")

                    if sellShop then
                        for _, toolItem in ipairs(petToolBatch) do
                            if toolItem and toolItem.Parent and shouldSellPetTool(toolItem) then
                                pcall(function()
                                    sellShop:FireServer(toolItem)
                                end)
                                if sellOne then
                                    pcall(function()
                                        sellOne:FireServer(toolItem)
                                    end)
                                end
                                task.wait(0.015)
                            end
                        end
                    end
                    task.wait(0.2)
                    _G._gag_selling_pets = false
                else
                    _G._gag_selling_pets = false
                end
            end)

            if not ok then _G._gag_selling_pets = false end
            task.wait(0.2)
        else
            _G._gag_selling_pets = false
            task.wait(0.5)
        end
    end
end)

-- 2. Dedicated Auto Sell Crops Loop
task.spawn(function()
    while true do
        if _G.GAG_SESSION ~= currentSession then break end

        local autoSellCrops = isToggleActive(autoSellCropsToggle, State.AutoSellCrops, "💰 Auto Sell (Crops)")
        if autoSellCrops then
            task.wait(State.SellCheckDelay or 0.25)

            local ok, err = pcall(function()
                local waitMax = isToggleActive(sellWaitMaxToggle, State.Sell_WaitMaxBackpack)
                local shouldRunCropSell = not waitMax or isBackpackFull()

                if shouldRunCropSell then
                    local allTools = getAllPlayerTools()
                    if #allTools == 0 then return end

                    local sellInv = getSellInvRemote()
                    local sellItem = getSellItemRemote()

                    local hasExclusions = (getUIListVal(sellExcludeFruitListObj, "None") ~= "None")
                        or (getUIListVal(sellExcludeCategoryListObj, "None") ~= "None")
                        or (getUIListVal(sellExcludeVariantListObj, "None") ~= "None")
                        or (getUIListVal(sellExcludeMutationListObj, "None") ~= "None")
                        or ((State.Sell_Weight or 0) > 0)

                    if not hasExclusions then
                        if sellInv then
                            pcall(function()
                                sellInv:FireServer()
                            end)
                        end
                    else
                        local foundSellable = false
                        for _, tool in ipairs(allTools) do
                            if tool.Parent and tool:IsA("Tool") and not tool:GetAttribute("PET_UUID") then
                                local info = getCropToolInfo(tool)
                                if shouldSellCropTool(info) then
                                    foundSellable = true
                                    if sellItem then
                                        pcall(function()
                                            sellItem:FireServer(tool)
                                        end)
                                    end
                                end
                            end
                        end
                        if foundSellable and sellInv then
                            pcall(function()
                                sellInv:FireServer()
                            end)
                        end
                    end
                end
            end)

            if not ok and err then
                task.wait(0.2)
            end
        else
            task.wait(0.5)
        end
    end
end)

-- =========================================================================
-- Pet Egg Engine: Auto Place Eggs & Auto Hatch Eggs
-- =========================================================================



local function getPlacedEggsInGarden()
    local eggs = {}
    local seen = {}
    local farm = getPlayerFarm()
    if farm then
        local imp = farm:FindFirstChild("Important")
        local objFolder = imp and imp:FindFirstChild("Objects_Physical")
        if objFolder then
            for _, obj in ipairs(objFolder:GetChildren()) do
                local isEgg = obj.Name:lower():find("egg") or obj:GetAttribute("EggName") or obj:GetAttribute("TimeToHatch") or (obj:GetAttribute("READY") ~= nil)
                if isEgg and not seen[obj] then
                    seen[obj] = true
                    table.insert(eggs, obj)
                end
            end
        end
    end

    local objPhy = Workspace:FindFirstChild("Objects_Physical")
    if objPhy then
        for _, obj in ipairs(objPhy:GetChildren()) do
            local owner = obj:GetAttribute("OWNER") or obj:GetAttribute("Owner")
            local isMyEgg = (not owner) or (tostring(owner) == tostring(LocalPlayer.UserId)) or (tostring(owner) == LocalPlayer.Name)
            if isMyEgg and (obj.Name:lower():find("egg") or obj:GetAttribute("EggName") or obj:GetAttribute("TimeToHatch")) and not seen[obj] then
                seen[obj] = true
                table.insert(eggs, obj)
            end
        end
    end

    return eggs
end

local function getNextEggRowPosition()
    local farm = getPlayerFarm()
    local canPlantParts = {}
    if farm and farm:FindFirstChild("Important") then
        local locs = farm.Important:FindFirstChild("Plant_Locations")
        if locs then
            for _, ch in ipairs(locs:GetChildren()) do
                if ch:IsA("BasePart") then
                    table.insert(canPlantParts, ch)
                end
            end
        end
    end

    if #canPlantParts == 0 then
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        return root and (root.Position - Vector3.new(0, 2.5, 0)) or Vector3.new(0, 0, 0)
    end

    table.sort(canPlantParts, function(a, b) return a.Position.X < b.Position.X end)

    local occupiedPositions = {}

    -- 1. Placed eggs
    local placedEggs = getPlacedEggsInGarden()
    for _, eggObj in ipairs(placedEggs) do
        local pos = (eggObj:IsA("Model") and eggObj:GetPivot().Position) or (eggObj:FindFirstChildWhichIsA("BasePart", true) and eggObj:FindFirstChildWhichIsA("BasePart", true).Position)
        if pos then
            table.insert(occupiedPositions, pos)
        end
    end

    -- 2. Physical plants & physical objects in farm
    if farm and farm:FindFirstChild("Important") then
        local plantsFolder = farm.Important:FindFirstChild("Plants_Physical")
        if plantsFolder then
            for _, plant in ipairs(plantsFolder:GetChildren()) do
                local pos = (plant:IsA("Model") and plant:GetPivot().Position) or (plant:FindFirstChildWhichIsA("BasePart", true) and plant:FindFirstChildWhichIsA("BasePart", true).Position)
                if pos then
                    table.insert(occupiedPositions, pos)
                end
            end
        end
        local objFolder = farm.Important:FindFirstChild("Objects_Physical")
        if objFolder then
            for _, obj in ipairs(objFolder:GetChildren()) do
                local pos = (obj:IsA("Model") and obj:GetPivot().Position) or (obj:FindFirstChildWhichIsA("BasePart", true) and obj:FindFirstChildWhichIsA("BasePart", true).Position)
                if pos then
                    table.insert(occupiedPositions, pos)
                end
            end
        end
    end

    -- Robust spacing & clearance to prevent "Too close to another object"
    local spacingX = 3.8
    local spacingZ = 3.8
    local marginX = 1.8
    local marginZ = 1.8
    local minClearance = 3.4

    local slots = {}

    for _, cp in ipairs(canPlantParts) do
        local cf = cp.CFrame
        local sz = cp.Size
        local minX = -(sz.X / 2) + marginX
        local maxX = (sz.X / 2) - marginX
        local minZ = -(sz.Z / 2) + marginZ
        local maxZ = (sz.Z / 2) - marginZ

        local cols = math.max(1, math.floor((maxX - minX) / spacingX) + 1)
        local rows = math.max(1, math.floor((maxZ - minZ) / spacingZ) + 1)

        -- Align down furrows (column by column along Z)
        for c = 0, cols - 1 do
            local lx = minX + (c * spacingX)
            for r = 0, rows - 1 do
                local lz = minZ + (r * spacingZ)
                local worldPos = cf:PointToWorldSpace(Vector3.new(lx, 0.25, lz))
                table.insert(slots, worldPos)
            end
        end
    end

    for _, slotPos in ipairs(slots) do
        local isOccupied = false
        for _, occPos in ipairs(occupiedPositions) do
            local dist2D = (Vector3.new(slotPos.X, 0, slotPos.Z) - Vector3.new(occPos.X, 0, occPos.Z)).Magnitude
            if dist2D < minClearance then
                isOccupied = true
                break
            end
        end
        if not isOccupied then
            return slotPos
        end
    end

    if #slots > 0 then
        return slots[1] + Vector3.new((math.random() - 0.5) * 0.5, 0, (math.random() - 0.5) * 0.5)
    end

    return canPlantParts[1].Position + Vector3.new(0, 0.25, 0)
end

local function findEggToolInBackpack(selectedEggNames)
    local bp = LocalPlayer:FindFirstChild("Backpack")
    local char = LocalPlayer.Character
    if not bp and not char then return nil, nil end

    local eggList = {}
    if type(selectedEggNames) == "table" then
        for _, e in ipairs(selectedEggNames) do
            local eStr = type(e) == "table" and (e.Name or e[1]) or tostring(e or "")
            if eStr ~= "" then table.insert(eggList, eStr) end
        end
    elseif type(selectedEggNames) == "string" and selectedEggNames ~= "" then
        table.insert(eggList, selectedEggNames)
    end

    local isAll = false
    if #eggList == 0 then
        isAll = true
    else
        for _, eggName in ipairs(eggList) do
            local clean = tostring(eggName):lower():gsub("%s*x%d+", ""):gsub("[%s%p]", "")
            if clean == "alleggs" or clean == "all" or clean == "" or clean == "none" then
                isAll = true
                break
            end
        end
    end

    if isAll then
        if char then
            for _, tool in ipairs(char:GetChildren()) do
                if tool:IsA("Tool") then
                    local eggAttr = tool:GetAttribute("h") or tool:GetAttribute("B") or tool:GetAttribute("EggName") or tool.Name
                    if tostring(eggAttr):lower():find("egg") or tool.Name:lower():find("egg") or tool:GetAttribute("h") or tool:GetAttribute("B") then
                        return tool, tostring(eggAttr or tool.Name)
                    end
                end
            end
        end
        if bp then
            for _, tool in ipairs(bp:GetChildren()) do
                if tool:IsA("Tool") then
                    local eggAttr = tool:GetAttribute("h") or tool:GetAttribute("B") or tool:GetAttribute("EggName") or tool.Name
                    if tostring(eggAttr):lower():find("egg") or tool.Name:lower():find("egg") or tool:GetAttribute("h") or tool:GetAttribute("B") then
                        return tool, tostring(eggAttr or tool.Name)
                    end
                end
            end
        end
        return nil, nil
    end

    -- Sequential Priority Check:
    -- Check each selected egg in order. The first egg in the list that exists in inventory is chosen.
    for _, targetEgg in ipairs(eggList) do
        local cleanTarget = tostring(targetEgg):lower():gsub("%s*x%d+", ""):gsub("[%s%p]", "")
        if cleanTarget ~= "" and cleanTarget ~= "none" then
            if char then
                for _, tool in ipairs(char:GetChildren()) do
                    if tool:IsA("Tool") then
                        local eggAttr = tool:GetAttribute("h") or tool:GetAttribute("B") or tool:GetAttribute("EggName") or tool.Name
                        local cName = tostring(eggAttr):lower():gsub("%s*x%d+", ""):gsub("[%s%p]", "")
                        if cName:find(cleanTarget, 1, true) or cleanTarget:find(cName, 1, true) then
                            return tool, targetEgg
                        end
                    end
                end
            end
            if bp then
                for _, tool in ipairs(bp:GetChildren()) do
                    if tool:IsA("Tool") then
                        local eggAttr = tool:GetAttribute("h") or tool:GetAttribute("B") or tool:GetAttribute("EggName") or tool.Name
                        local cName = tostring(eggAttr):lower():gsub("%s*x%d+", ""):gsub("[%s%p]", "")
                        if cName:find(cleanTarget, 1, true) or cleanTarget:find(cName, 1, true) then
                            return tool, targetEgg
                        end
                    end
                end
            end
        end
    end

    return nil, nil
end

local function getMaxEggCapacity()
    local maxCap = 3
    pcall(function()
        local dsMod = ReplicatedStorage:FindFirstChild("Modules") and ReplicatedStorage.Modules:FindFirstChild("DataService")
        local ds = dsMod and require(dsMod)
        local data = ds and ds:GetData()
        if data then
            local pets = data.PetsData
            local pEggSlots = (pets and tonumber(pets.PurchasedEggSlots)) or tonumber(data.PurchasedEggSlots) or 0
            local pLife = data.GardenCoinShopStats and data.GardenCoinShopStats.LifetimePurchases
            local coinEggSlots = pLife and tonumber(pLife["Egg Capacity"]) or 0
            maxCap = 3 + pEggSlots + coinEggSlots
        end
    end)
    return maxCap
end

local function placeEggAt(targetPos, eggTool)
    if not eggTool or not targetPos then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local backpack = LocalPlayer:FindFirstChild("Backpack")

    -- 1. Unequip any non-egg tools (especially newly hatched pets that auto-equipped into character)
    for _, item in ipairs(char:GetChildren()) do
        if item:IsA("Tool") and item ~= eggTool then
            if backpack then
                item.Parent = backpack
            end
        end
    end

    -- 2. Equip egg tool cleanly
    if hum then
        if eggTool.Parent ~= char then
            hum:UnequipTools()
            hum:EquipTool(eggTool)
        end
    end
    if eggTool.Parent ~= char then
        eggTool.Parent = char
    end

    -- 3. Fire server remote to place egg at exact coordinates
    local ge = ReplicatedStorage:FindFirstChild("GameEvents")
    local petEggService = ge and ge:FindFirstChild("PetEggService")

    if petEggService then
        pcall(function()
            petEggService:FireServer("CreateEgg", targetPos)
        end)
    end
end

local function isEggReadyToHatch(eggObj)
    if not eggObj or not eggObj.Parent then return false end
    
    -- 1. Check direct TimeToHatch attribute (0 or negative means timer finished)
    local timeToHatch = tonumber(eggObj:GetAttribute("TimeToHatch"))
    if timeToHatch and timeToHatch <= 0 then
        return true
    end

    -- 2. Check if explicit Hatch! ProximityPrompt exists and is enabled
    local petEgg = eggObj:FindFirstChild("PetEgg") or eggObj
    local promptAtt = petEgg:FindFirstChild("ProximityPromptAtt") or eggObj:FindFirstChild("ProximityPromptAtt")
    local hatchPrompt = promptAtt and promptAtt:FindFirstChild("ProximityPrompt")
    if hatchPrompt and hatchPrompt.Enabled and hatchPrompt.ActionText:lower():find("hatch") then
        return true
    end

    local directPrompt = eggObj:FindFirstChild("ProximityPrompt")
    if directPrompt and directPrompt.Enabled and directPrompt.ActionText:lower():find("hatch") then
        return true
    end

    -- 3. If READY is true but TimeToHatch is absent, consider ready
    if eggObj:GetAttribute("READY") == true and timeToHatch == nil then
        return true
    end

    return false
end

local function hatchSingleEgg(eggObj)
    if not eggObj or not eggObj.Parent then return end
    if not isEggReadyToHatch(eggObj) then return end

    local ge = ReplicatedStorage:FindFirstChild("GameEvents")
    local petEggService = ge and ge:FindFirstChild("PetEggService")
    local eggReadyRE = ge and ge:FindFirstChild("EggReadyToHatch_RE")
    local uuid = eggObj:GetAttribute("OBJECT_UUID") or eggObj:GetAttribute("UUID")

    -- 1. Fire Remote Events for hatching
    pcall(function()
        if petEggService then
            petEggService:FireServer("HatchPet", eggObj)
            if uuid then petEggService:FireServer("HatchPet", uuid) end
        end
    end)

    pcall(function()
        if eggReadyRE then
            eggReadyRE:FireServer(eggObj)
            if uuid then eggReadyRE:FireServer(uuid) end
        end
    end)

    -- 2. ONLY Trigger the Hatch ProximityPrompt (NEVER trigger SkipPrompt / SkipAllPrompt)
    pcall(function()
        local petEgg = eggObj:FindFirstChild("PetEgg") or eggObj
        local promptAtt = petEgg:FindFirstChild("ProximityPromptAtt") or eggObj:FindFirstChild("ProximityPromptAtt")
        local hatchPrompt = (promptAtt and promptAtt:FindFirstChild("ProximityPrompt")) or eggObj:FindFirstChild("ProximityPrompt")
        
        if hatchPrompt and hatchPrompt.Enabled and hatchPrompt.ActionText:lower():find("hatch") then
            if fireproximityprompt then
                fireproximityprompt(hatchPrompt)
            elseif getconnections then
                for _, conn in ipairs(getconnections(hatchPrompt.Triggered)) do
                    if conn.Fire then conn:Fire(LocalPlayer) end
                end
            end
        end
    end)

    -- 3. Trigger PetEggRenderer hatch animation if available
    pcall(function()
        local rep = ReplicatedStorage:FindFirstChild("Modules")
        local ps = rep and rep:FindFirstChild("PetServices")
        local eggRenderer = ps and ps:FindFirstChild("PetEggRenderer")
        if eggRenderer then
            local rMod = require(eggRenderer)
            if rMod and rMod.ActivateEgg then
                rMod.ActivateEgg(eggObj)
            end
        end
    end)
end

local lastEquippedSlotNumber = nil
local lastSlotEquipTick = 0

local function hatchAllReadyEggsNow()
    local hatchSlot = getUIListVal(hatchEggSlotListObj, State.HatchEgg_EquipSlot or "None")
    if hatchSlot ~= "None" then
        equipPetSlot(hatchSlot, true)
    end
    local placed = getPlacedEggsInGarden()
    for _, egg in ipairs(placed) do
        if isEggReadyToHatch(egg) then
            hatchSingleEgg(egg)
        end
    end
end

-- =========================================================================
-- Pet Egg Placement & Hatching Background Loops
-- =========================================================================

local function isPetSlotLoaded(slotNum)
    if not slotNum then return true end
    local num = tonumber(slotNum)
    if not num then return true end
    local isLoaded = false
    pcall(function()
        local dsMod = ReplicatedStorage:FindFirstChild("Modules") and ReplicatedStorage.Modules:FindFirstChild("DataService")
        local ds = dsMod and require(dsMod)
        local data = ds and ds:GetData()
        local currentSlot = data and data.PetsData and tonumber(data.PetsData.SelectedPetLoadout)
        if currentSlot and currentSlot == num then
            isLoaded = true
        end
    end)
    return isLoaded
end

local function equipPetSlot(slotVal, waitForLoad, minCooldown)
    if not slotVal or slotVal == "None" or slotVal == "" then return true end
    local slotNum = tonumber(tostring(slotVal):match("%d+"))
    if not slotNum then return true end

    local isCurrent = isPetSlotLoaded(slotNum)
    local isNewSlot = (lastEquippedSlotNumber ~= slotNum) or not isCurrent

    if isNewSlot or (tick() - lastSlotEquipTick > 10) then
        lastEquippedSlotNumber = slotNum
        lastSlotEquipTick = tick()

        pcall(function()
            local ge = ReplicatedStorage:FindFirstChild("GameEvents")
            local petsService = ge and (ge:FindFirstChild("PetsService") or ge:FindFirstChild("PetServices") or ge:FindFirstChild("PetTeamService"))
            if petsService then
                petsService:FireServer("SwapPetLoadout", slotNum)
                petsService:FireServer("EquipTeam", slotNum)
            end

            local pGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
            local activePetUI = pGui and pGui:FindFirstChild("ActivePetUI")
            if activePetUI then
                local btn = activePetUI:FindFirstChild("PET_LOADOUT_" .. tostring(slotNum), true)
                local sensor = btn and (btn:FindFirstChild("SENSOR") or btn:FindFirstChildWhichIsA("GuiButton", true))
                if sensor then
                    if firesignal then firesignal(sensor.MouseButton1Click) firesignal(sensor.Activated) end
                    if getconnections then
                        for _, conn in ipairs(getconnections(sensor.MouseButton1Click)) do if conn.Fire then conn:Fire() end end
                    end
                end
            end
        end)
    end

    if waitForLoad then
        local targetCooldown = minCooldown or math.max(3.0, tonumber(State.Hatch_SlotCooldown) or 5.0)
        local startWait = tick()
        while (not isPetSlotLoaded(slotNum) or (tick() - lastSlotEquipTick < targetCooldown)) and (tick() - startWait < targetCooldown + 1.5) do
            task.wait(0.15)
        end
        return isPetSlotLoaded(slotNum)
    end
    return isPetSlotLoaded(slotNum)
end

-- 1. Auto Place Eggs Loop (Cycle Step 1: Equip Slot, Place Eggs, Wait For Hatch)
task.spawn(function()
    while true do
        if _G.GAG_SESSION ~= currentSession then break end

        local autoPlace = isToggleActive(autoPlaceEggsToggle, State.AutoPlaceEggs, "🥚 Auto Place Eggs")
        if autoPlace then
            local ok, err = pcall(function()
                if _G._gag_selling_pets or isPetBackpackFull() then
                    task.wait(0.35)
                    return
                end

                local onlyNoEgg = isToggleActive(placeOnlyWhenNoEggToggle, State.PlaceOnlyWhenNoEgg)
                local placedEggs = getPlacedEggsInGarden()
                local currentPlacedCount = #placedEggs

                if onlyNoEgg and currentPlacedCount > 0 then
                    task.wait(0.2)
                    return
                end

                local maxCapacity = getMaxEggCapacity()
                if currentPlacedCount >= maxCapacity then
                    task.wait(0.25)
                    return
                end

                local selectedEggs = getUIListMultipleVals(placeEggListObj, nil)
                local eggTool = findEggToolInBackpack(selectedEggs)
                if not eggTool then
                    task.wait(0.3)
                    return
                end

                -- Unequip any pet currently held in hand before placing
                unequipHatchedPetTool()

                -- Always equip Place Egg Slot before placing eggs to maximize hatch speed / reduce egg growth time
                local placeSlot = getUIListVal(placeEggSlotListObj, State.PlaceEgg_EquipSlot or "None")
                if placeSlot ~= "None" and not _G._gag_selling_pets then
                    equipPetSlot(placeSlot, true, 2.0)
                end

                local posMode = getUIListVal(placeEggPositionModeListObj, State.PlaceEgg_PositionMode or "Row Position")
                local targetPos
                if posMode == "Player Position" then
                    local char = LocalPlayer.Character
                    local root = char and char:FindFirstChild("HumanoidRootPart")
                    if root then
                        targetPos = root.Position - Vector3.new(0, 2.5, 0)
                    else
                        targetPos = getNextEggRowPosition()
                    end
                else
                    targetPos = getNextEggRowPosition()
                end

                placeEggAt(targetPos, eggTool)
                task.wait(0.18)
            end)

            if not ok and err then
                task.wait(0.2)
            end
        else
            task.wait(0.4)
        end
    end
end)

-- 2. Auto Hatch Eggs Loop (Cycle Step 2: Equip Hatch Slot, Hatch Eggs When Ready)
task.spawn(function()
    while true do
        if _G.GAG_SESSION ~= currentSession then break end

        local autoHatch = isToggleActive(autoHatchEggsToggle, State.AutoHatchEggs, "🐣 Auto Hatch Eggs")
        if autoHatch then
            local ok, err = pcall(function()
                if _G._gag_selling_pets or isPetBackpackFull() then
                    task.wait(0.35)
                    return
                end

                local placedEggs = getPlacedEggsInGarden()
                if #placedEggs == 0 then
                    task.wait(0.25)
                    return
                end

                local waitAll = isToggleActive(waitAllEggsReadyToggle, State.WaitAllEggsReady)
                if waitAll then
                    local allReady = true
                    for _, egg in ipairs(placedEggs) do
                        if not isEggReadyToHatch(egg) then
                            allReady = false
                            break
                        end
                    end
                    if not allReady then
                        task.wait(0.2)
                        return
                    end
                end

                -- Equip Hatch Slot when eggs are ready to hatch
                local hasReadyEggs = false
                for _, egg in ipairs(placedEggs) do
                    if isEggReadyToHatch(egg) then
                        hasReadyEggs = true
                        break
                    end
                end

                if hasReadyEggs and not _G._gag_selling_pets then
                    local hatchSlot = getUIListVal(hatchEggSlotListObj, State.HatchEgg_EquipSlot or "None")
                    if hatchSlot ~= "None" then
                        local hatchSlotNum = tonumber(tostring(hatchSlot):match("%d+"))
                        if hatchSlotNum then
                            if lastEquippedSlotNumber ~= hatchSlotNum or not isPetSlotLoaded(hatchSlotNum) then
                                local loaded = equipPetSlot(hatchSlot, true)
                                if not loaded then
                                    task.wait(0.25)
                                    return
                                end
                            end
                            local targetCooldown = math.max(5.0, tonumber(State.Hatch_SlotCooldown) or 7.0)
                            if (tick() - lastSlotEquipTick) < targetCooldown then
                                task.wait(0.25)
                                return
                            end
                        end
                    end
                end

                local selectedHatchEggs = getUIListMultipleVals(hatchEggListObj, nil)
                local isAllEggs = (#selectedHatchEggs == 0)
                if not isAllEggs then
                    for _, sEgg in ipairs(selectedHatchEggs) do
                        local clean = tostring(sEgg):lower():gsub("[%s%p]", "")
                        if clean == "alleggs" or clean == "all" or clean == "" or clean == "none" then
                            isAllEggs = true
                            break
                        end
                    end
                end

                local excludedPetsList = getUIListMultipleVals(hatchExcludePetListObj, nil)
                local excludedPetsMap = {}
                for _, petName in ipairs(excludedPetsList) do
                    local cName = tostring(petName):lower():gsub("[%s%p]", "")
                    if cName ~= "" and cName ~= "none" then
                        excludedPetsMap[cName] = true
                    end
                end

                if isAllEggs then
                    for _, egg in ipairs(placedEggs) do
                        if isEggReadyToHatch(egg) then
                            hatchSingleEgg(egg)
                        end
                    end
                else
                    -- Hatch in priority sequence of selected eggs:
                    for _, targetEggName in ipairs(selectedHatchEggs) do
                        local cleanTarget = tostring(targetEggName):lower():gsub("[%s%p]", "")
                        if cleanTarget ~= "" and cleanTarget ~= "none" then
                            for _, egg in ipairs(placedEggs) do
                                if isEggReadyToHatch(egg) then
                                    local eggName = egg:GetAttribute("EggName") or egg.Name
                                    local cleanEggName = tostring(eggName):lower():gsub("[%s%p]", "")
                                    if cleanEggName:find(cleanTarget, 1, true) or cleanTarget:find(cleanEggName, 1, true) then
                                        hatchSingleEgg(egg)
                                    end
                                end
                            end
                        end
                    end
                end

                local checkDelay = math.clamp(tonumber(State.Hatch_CheckDelay) or 0.1, 0.05, 1.0)
                task.wait(checkDelay)
            end)

            if not ok and err then
                task.wait(0.25)
            end
        else
            task.wait(0.5)
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
        if _G.GAG_SESSION ~= currentSession then break end
        local hf = isToggleActive(hideFruitsToggle, State.HideFruits, "🍎 Hide Fruits")
        local hp = isToggleActive(hidePlantsToggle, State.HidePlants, "🌾 Hide Plants")
        if hf then
            pcall(updateFruitVisibility)
        end
        if hp then
            pcall(updatePlantVisibility)
        end
        if hf or hp then
            task.wait(1.0)
        else
            task.wait(2.0)
        end
    end
end)

-- =========================================================================
-- Infinite Sprinkler Engine (Shovels Placed Sprinklers for Glitch & Desync)
-- =========================================================================
local lastSprinklerShovelMap = {}

local function getAllPlacedSprinklers()
    local candidates = {}
    local seen = {}

    local farmFolder = Workspace:FindFirstChild("Farm") or Workspace
    for _, farm in ipairs(farmFolder:GetChildren()) do
        local imp = farm:FindFirstChild("Important")
        if imp then
            for _, folderName in ipairs({"Objects_Physical", "Plants_Physical", "Cosmetic_Physical"}) do
                local folder = imp:FindFirstChild(folderName)
                if folder then
                    for _, obj in ipairs(folder:GetChildren()) do
                        if obj.Name:lower():find("sprinkler") and not seen[obj] then
                            seen[obj] = true
                            table.insert(candidates, obj)
                        end
                    end
                end
            end
        end
    end

    local spFolder = Workspace:FindFirstChild("Sprinklers")
    if spFolder then
        for _, obj in ipairs(spFolder:GetChildren()) do
            if obj.Name:lower():find("sprinkler") and not seen[obj] then
                seen[obj] = true
                table.insert(candidates, obj)
            end
        end
    end

    for _, desc in ipairs(Workspace:GetChildren()) do
        if desc.Name:lower():find("sprinkler") and (desc:IsA("Model") or desc:IsA("BasePart")) and not seen[desc] then
            seen[desc] = true
            table.insert(candidates, desc)
        end
    end

    return candidates
end

local function shovelSingleSprinkler(sp)
    if not sp or not sp.Parent then return end
    pcall(function()
        local ge = ReplicatedStorage:FindFirstChild("GameEvents")
        local deleteRemote = ge and ge:FindFirstChild("DeleteObject")
        local deleteItemRemote = ge and ge:FindFirstChild("Remove_Item")
        local sprinklerService = ge and ge:FindFirstChild("SprinklerService")
        local uuid = sp:GetAttribute("OBJECT_UUID")

        if deleteRemote then
            deleteRemote:FireServer(sp)
            if uuid then
                deleteRemote:FireServer(uuid)
                deleteRemote:FireServer(tostring(sp.Name), uuid)
            end
        end
        if deleteItemRemote then
            deleteItemRemote:FireServer(sp)
            if uuid then deleteItemRemote:FireServer(uuid) end
        end
        if sprinklerService then
            sprinklerService:FireServer("Remove", sp)
            sprinklerService:FireServer("Delete", sp)
            sprinklerService:FireServer("Destroy", sp)
            sprinklerService:FireServer(sp)
            if uuid then
                sprinklerService:FireServer("Remove", uuid)
                sprinklerService:FireServer("Delete", uuid)
            end
        end

        for _, desc in ipairs(sp:GetDescendants()) do
            if desc:IsA("BasePart") then
                desc.LocalTransparencyModifier = 1
                desc.CanCollide = false
            elseif desc:IsA("ParticleEmitter") or desc:IsA("BillboardGui") or desc:IsA("SurfaceGui") or desc:IsA("Highlight") then
                desc.Enabled = false
            end
        end
    end)
end

local function applyInfiniteSprinklerShovel()
    pcall(function()
        if not State.InfiniteSprinkler then return end
        local selectedList = getUIListMultipleVals(selectSprinklerListObj, "All Sprinklers")
        local isAll = false
        local allowedMap = {}

        for _, item in ipairs(selectedList) do
            local clean = tostring(item):lower():gsub("[%s%p]", "")
            if clean == "allsprinklers" or clean == "all" or clean == "" or clean == "none" then
                isAll = true
            else
                allowedMap[clean] = true
            end
        end

        local placed = getAllPlacedSprinklers()
        local now = tick()

        for _, sp in ipairs(placed) do
            if sp and sp.Parent then
                local spName = sp.Name
                local cleanName = spName:lower():gsub("[%s%p]", "")
                local matches = isAll or allowedMap[cleanName]

                if not matches and not isAll then
                    for selKey, _ in pairs(allowedMap) do
                        if cleanName:find(selKey, 1, true) or selKey:find(cleanName, 1, true) then
                            matches = true
                            break
                        end
                    end
                end

                if matches then
                    local lastTime = lastSprinklerShovelMap[sp] or 0
                    if (now - lastTime) >= 0.1 then
                        lastSprinklerShovelMap[sp] = now
                        shovelSingleSprinkler(sp)
                    end
                end
            end
        end
    end)
end

local function shovelActiveSprinklers()
    pcall(function()
        local placed = getAllPlacedSprinklers()
        for _, sp in ipairs(placed) do
            shovelSingleSprinkler(sp)
        end
    end)
end

-- Continuous Infinite Sprinkler background loop
task.spawn(function()
    while true do
        if _G.GAG_SESSION ~= currentSession then break end
        if State.InfiniteSprinkler then
            pcall(applyInfiniteSprinklerShovel)
            task.wait(0.08)
        else
            task.wait(0.5)
        end
    end
end)

-- =========================================================================
-- Ultra-Fast / Instant Auto-Buy Engine (Eggs, Gears, Seeds, Cosmetics)
-- =========================================================================
local function getItemFromCatalog(catalog, selectedDisplayName)
    if not selectedDisplayName or selectedDisplayName == "" or selectedDisplayName == "None" then
        return catalog[1]
    end
    for _, item in ipairs(catalog) do
        if item.Name == selectedDisplayName or item.ItemName == selectedDisplayName then
            return item
        end
    end
    local clean = selectedDisplayName:lower():gsub("%s*%([%d%.]+%a*¢%)", ""):gsub("[%s%p]", "")
    for _, item in ipairs(catalog) do
        local cItem = item.ItemName:lower():gsub("[%s%p]", "")
        if cItem == clean or cItem:find(clean, 1, true) or clean:find(cItem, 1, true) then
            return item
        end
    end
    return catalog[1]
end

local function purchaseSingleShopItem(shopType, item)
    if not item then return end
    local name = item.ItemName or item.Name
    local rawKey = item.RawKey or name

    -- 1. Direct Remote Invocations with Verified Signatures
    pcall(function()
        if shopType == "Seed" then
            if BuySeedStockRemote then
                BuySeedStockRemote:FireServer("Shop", rawKey)
                BuySeedStockRemote:FireServer("Shop", name)
                BuySeedStockRemote:FireServer(rawKey)
            end
            if BuyDailySeedShopStockRemote then
                BuyDailySeedShopStockRemote:FireServer("Shop", rawKey)
            end
        elseif shopType == "Gear" then
            if BuyGearStockRemote then
                BuyGearStockRemote:FireServer(name)
                BuyGearStockRemote:FireServer("Shop", name)
            end
        elseif shopType == "Egg" then
            if BuyPetEggRemote then
                BuyPetEggRemote:FireServer(name)
                BuyPetEggRemote:FireServer("Shop", name)
            end
        elseif shopType == "Cosmetic" then
            if item.Type == "Crate" and BuyCosmeticCrateRemote then
                BuyCosmeticCrateRemote:FireServer(name, "Cosmetics")
                BuyCosmeticCrateRemote:FireServer(name)
            elseif BuyCosmeticItemRemote then
                BuyCosmeticItemRemote:FireServer(name, "Cosmetics")
                BuyCosmeticItemRemote:FireServer(name)
            end
        end
    end)

    -- 2. Fallback: Trigger matching GUI button activation in PlayerGui
    pcall(function()
        local pGui = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
        if not pGui then return end

        local targetGuiName = (shopType == "Seed" and "Seed_Shop")
            or (shopType == "Gear" and "Gear_Shop")
            or (shopType == "Egg" and "PetShop_UI")
            or (shopType == "Cosmetic" and "CosmeticShop_UI")

        local shopGui = targetGuiName and pGui:FindFirstChild(targetGuiName)
        if shopGui then
            local cleanTarget = tostring(name):lower():gsub("[%s%p]", "")
            for _, desc in ipairs(shopGui:GetDescendants()) do
                if desc:IsA("GuiObject") then
                    local dName = desc.Name:lower():gsub("[%s%p]", "")
                    if dName == cleanTarget or dName:find(cleanTarget, 1, true) or cleanTarget:find(dName, 1, true) then
                        local buyBtn = desc:FindFirstChild("Sheckles_Buy", true) or desc:FindFirstChild("CashBuy", true)
                        if buyBtn then
                            if getconnections then
                                for _, conn in ipairs(getconnections(buyBtn.Activated)) do
                                    if conn.Fire then conn:Fire() end
                                end
                                for _, conn in ipairs(getconnections(buyBtn.MouseButton1Click)) do
                                    if conn.Fire then conn:Fire() end
                                end
                            end
                            if firesignal then
                                firesignal(buyBtn.Activated)
                                firesignal(buyBtn.MouseButton1Click)
                            end
                            break
                        end
                    end
                end
            end
        end
    end)
end

local function executeInstantShopPurchases()
    pcall(function()
        local dsMod = ReplicatedStorage:FindFirstChild("Modules") and ReplicatedStorage.Modules:FindFirstChild("DataService")
        local ds = dsMod and require(dsMod)
        local data = ds and ds:GetData()
        local currentSheckles = getPlayerSheckles()
        local pGui = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")

        -- 1. Egg Shop
        local buySelEgg = State.AutoBuy_SelectedEgg
        local buyAllEgg = State.AutoBuy_AllEggs
        if buySelEgg or buyAllEgg then
            if buyAllEgg then
                if data and data.PetEggStock and data.PetEggStock.Stocks then
                    for _, info in pairs(data.PetEggStock.Stocks) do
                        local eggName = info.EggName or info.Name
                        local stock = tonumber(info.Stock) or 0
                        if eggName and stock > 0 then
                            if BuyPetEggRemote then
                                BuyPetEggRemote:FireServer(tostring(eggName))
                            end
                            pcall(function()
                                local pShop = pGui and pGui:FindFirstChild("PetShop_UI")
                                local eggFrame = pShop and pShop.Frame.ScrollingFrame:FindFirstChild(tostring(eggName))
                                local btn = eggFrame and eggFrame:FindFirstChild("Sheckles_Buy", true)
                                if btn and getconnections then
                                    for _, c in ipairs(getconnections(btn.Activated)) do c:Fire() end
                                end
                            end)
                        end
                    end
                end
            elseif buySelEgg then
                local selVal = tostring(getUIListVal(selectEggListObj, (allAvailableEggs[1] and allAvailableEggs[1].Name) or "None"))
                local cleanName = selVal:gsub("%s*%([%d%.]+%a*¢%)", ""):gsub("^%s+", ""):gsub("%s+$", "")
                if cleanName ~= "" and cleanName ~= "None" then
                    if BuyPetEggRemote then
                        BuyPetEggRemote:FireServer(cleanName)
                    end
                    pcall(function()
                        local pShop = pGui and pGui:FindFirstChild("PetShop_UI")
                        local eggFrame = pShop and pShop.Frame.ScrollingFrame:FindFirstChild(cleanName)
                        local btn = eggFrame and eggFrame:FindFirstChild("Sheckles_Buy", true)
                        if btn and getconnections then
                            for _, c in ipairs(getconnections(btn.Activated)) do c:Fire() end
                        end
                    end)
                end
            end
        end

        -- 2. Gear Shop
        local buySelGear = State.AutoBuy_SelectedGear
        local buyAllGear = State.AutoBuy_AllGears
        if buySelGear or buyAllGear then
            if buyAllGear then
                if data and data.GearStock and data.GearStock.Stocks then
                    for gearName, info in pairs(data.GearStock.Stocks) do
                        local stock = tonumber(info.Stock) or 0
                        if stock > 0 then
                            if BuyGearStockRemote then
                                BuyGearStockRemote:FireServer(tostring(gearName))
                            end
                            pcall(function()
                                local gShop = pGui and pGui:FindFirstChild("Gear_Shop")
                                local gFrame = gShop and gShop.Frame.ScrollingFrame:FindFirstChild(tostring(gearName))
                                local btn = gFrame and gFrame:FindFirstChild("Sheckles_Buy", true)
                                if btn and getconnections then
                                    for _, c in ipairs(getconnections(btn.Activated)) do c:Fire() end
                                end
                            end)
                        end
                    end
                end
            elseif buySelGear then
                local selVal = tostring(getUIListVal(selectGearListObj, (allAvailableGears[1] and allAvailableGears[1].Name) or "None"))
                local cleanName = selVal:gsub("%s*%([%d%.]+%a*¢%)", ""):gsub("^%s+", ""):gsub("%s+$", "")
                if cleanName ~= "" and cleanName ~= "None" then
                    if BuyGearStockRemote then
                        BuyGearStockRemote:FireServer(cleanName)
                    end
                    pcall(function()
                        local gShop = pGui and pGui:FindFirstChild("Gear_Shop")
                        local gFrame = gShop and gShop.Frame.ScrollingFrame:FindFirstChild(cleanName)
                        local btn = gFrame and gFrame:FindFirstChild("Sheckles_Buy", true)
                        if btn and getconnections then
                            for _, c in ipairs(getconnections(btn.Activated)) do c:Fire() end
                        end
                    end)
                end
            end
        end

        -- 3. Seed Shop
        local buySelSeed = State.AutoBuy_SelectedSeed
        local buyAllSeed = State.AutoBuy_AllSeeds
        if buySelSeed or buyAllSeed then
            if buyAllSeed then
                if data and data.SeedStocks then
                    if data.SeedStocks.Shop and data.SeedStocks.Shop.Stocks then
                        for seedName, info in pairs(data.SeedStocks.Shop.Stocks) do
                            local stock = tonumber(info.Stock) or 0
                            if stock > 0 then
                                if BuySeedStockRemote then
                                    BuySeedStockRemote:FireServer("Shop", tostring(seedName))
                                end
                                pcall(function()
                                    local sShop = pGui and pGui:FindFirstChild("Seed_Shop")
                                    local sFrame = sShop and sShop.Frame.ScrollingFrame:FindFirstChild(tostring(seedName))
                                    local btn = sFrame and sFrame:FindFirstChild("Sheckles_Buy", true)
                                    if btn and getconnections then
                                        for _, c in ipairs(getconnections(btn.Activated)) do c:Fire() end
                                    end
                                end)
                            end
                        end
                    end
                    if data.SeedStocks["Daily Deals"] and data.SeedStocks["Daily Deals"].Stocks then
                        for seedName, info in pairs(data.SeedStocks["Daily Deals"].Stocks) do
                            local stock = tonumber(info.Stock) or 0
                            if stock > 0 then
                                if BuySeedStockRemote then
                                    BuySeedStockRemote:FireServer("Shop", tostring(seedName))
                                end
                                if BuyDailySeedShopStockRemote then
                                    BuyDailySeedShopStockRemote:FireServer("Shop", tostring(seedName))
                                end
                                pcall(function()
                                    local sShop = pGui and pGui:FindFirstChild("Seed_Shop")
                                    local sFrame = sShop and sShop.Frame.ScrollingFrame:FindFirstChild(tostring(seedName))
                                    local btn = sFrame and sFrame:FindFirstChild("Sheckles_Buy", true)
                                    if btn and getconnections then
                                        for _, c in ipairs(getconnections(btn.Activated)) do c:Fire() end
                                    end
                                end)
                            end
                        end
                    end
                end
            elseif buySelSeed then
                local selVal = tostring(getUIListVal(selectSeedShopListObj, (allAvailableSeedShop[1] and allAvailableSeedShop[1].Name) or "None"))
                local cleanName = selVal:gsub("%s*%([%d%.]+%a*¢%)", ""):gsub("^%s+", ""):gsub("%s+$", "")
                if cleanName ~= "" and cleanName ~= "None" then
                    if BuySeedStockRemote then
                        BuySeedStockRemote:FireServer("Shop", cleanName)
                    end
                    if BuyDailySeedShopStockRemote then
                        BuyDailySeedShopStockRemote:FireServer("Shop", cleanName)
                    end
                    pcall(function()
                        local sShop = pGui and pGui:FindFirstChild("Seed_Shop")
                        local sFrame = sShop and sShop.Frame.ScrollingFrame:FindFirstChild(cleanName)
                        local btn = sFrame and sFrame:FindFirstChild("Sheckles_Buy", true)
                        if btn and getconnections then
                            for _, c in ipairs(getconnections(btn.Activated)) do c:Fire() end
                        end
                    end)
                end
            end
        end

        -- 4. Cosmetics Shop
        local buySelCosmetic = State.AutoBuy_SelectedCosmetic
        local buyAllCosmetic = State.AutoBuy_AllCosmetics
        if buySelCosmetic or buyAllCosmetic then
            if buyAllCosmetic then
                if data and data.CosmeticStock and data.CosmeticStock.TabStocks then
                    local cTab = data.CosmeticStock.TabStocks.Cosmetics
                    if cTab then
                        if cTab.ItemStocks and BuyCosmeticItemRemote then
                            for itemName, info in pairs(cTab.ItemStocks) do
                                local stock = tonumber(info.Stock) or 0
                                if stock > 0 then
                                    BuyCosmeticItemRemote:FireServer(tostring(itemName), "Cosmetics")
                                    pcall(function()
                                        local cShop = pGui and pGui:FindFirstChild("CosmeticShop_UI")
                                        if cShop then
                                            for _, desc in ipairs(cShop:GetDescendants()) do
                                                if desc:IsA("GuiObject") and desc.Name == tostring(itemName) then
                                                    local btn = desc:FindFirstChild("CashBuy", true)
                                                    if btn and getconnections then
                                                        for _, c in ipairs(getconnections(btn.Activated)) do c:Fire() end
                                                    end
                                                end
                                            end
                                        end
                                    end)
                                end
                            end
                        end
                        if cTab.CrateStocks and BuyCosmeticCrateRemote then
                            for crateName, info in pairs(cTab.CrateStocks) do
                                local stock = tonumber(info.Stock) or 0
                                if stock > 0 then
                                    BuyCosmeticCrateRemote:FireServer(tostring(crateName), "Cosmetics")
                                    pcall(function()
                                        local cShop = pGui and pGui:FindFirstChild("CosmeticShop_UI")
                                        if cShop then
                                            for _, desc in ipairs(cShop:GetDescendants()) do
                                                if desc:IsA("GuiObject") and desc.Name == tostring(crateName) then
                                                    local btn = desc:FindFirstChild("CashBuy", true)
                                                    if btn and getconnections then
                                                        for _, c in ipairs(getconnections(btn.Activated)) do c:Fire() end
                                                    end
                                                end
                                            end
                                        end
                                    end)
                                end
                            end
                        end
                    end
                end
            elseif buySelCosmetic then
                local selVal = tostring(getUIListVal(selectCosmeticListObj, (allAvailableCosmetics[1] and allAvailableCosmetics[1].Name) or "None"))
                local cleanName = selVal:gsub("%s*%([%d%.]+%a*¢%)", ""):gsub("^%s+", ""):gsub("%s+$", "")
                if cleanName ~= "" and cleanName ~= "None" then
                    local isCrate = cleanName:lower():find("crate")
                    if isCrate and BuyCosmeticCrateRemote then
                        BuyCosmeticCrateRemote:FireServer(cleanName, "Cosmetics")
                    elseif BuyCosmeticItemRemote then
                        BuyCosmeticItemRemote:FireServer(cleanName, "Cosmetics")
                    end
                    pcall(function()
                        local cShop = pGui and pGui:FindFirstChild("CosmeticShop_UI")
                        if cShop then
                            for _, desc in ipairs(cShop:GetDescendants()) do
                                if desc:IsA("GuiObject") and desc.Name == cleanName then
                                    local btn = desc:FindFirstChild("CashBuy", true)
                                    if btn and getconnections then
                                        for _, c in ipairs(getconnections(btn.Activated)) do c:Fire() end
                                    end
                                end
                            end
                        end
                    end)
                end
            end
        end
    end)
end

task.spawn(function()
    while true do
        if _G.GAG_SESSION ~= currentSession then break end
        local isAnyShopActive = State.AutoBuy_SelectedEgg or State.AutoBuy_AllEggs
            or State.AutoBuy_SelectedGear or State.AutoBuy_AllGears
            or State.AutoBuy_SelectedSeed or State.AutoBuy_AllSeeds
            or State.AutoBuy_SelectedCosmetic or State.AutoBuy_AllCosmetics

        if isAnyShopActive then
            local delay = math.clamp(tonumber(State.Shop_BuyDelay) or 0.01, 0.005, 1.0)
            task.wait(delay)
            executeInstantShopPurchases()
        else
            task.wait(0.5)
        end
    end
end)

local function executeAutoCraftCycle()
    local autoPlants = isToggleActive(autoCraftPlantsToggle, State.AutoCraft_Plants)
    local autoGears = isToggleActive(autoCraftGearsToggle, State.AutoCraft_Gears)
    if not autoPlants and not autoGears then return end

    pcall(function()
        local cgosMod = ReplicatedStorage:FindFirstChild("Modules") and ReplicatedStorage.Modules:FindFirstChild("CraftingService") and ReplicatedStorage.Modules.CraftingService:FindFirstChild("CraftingGlobalObjectService")
        local cgos = cgosMod and require(cgosMod)
        local cshMod = ReplicatedStorage:FindFirstChild("Modules") and ReplicatedStorage.Modules:FindFirstChild("CraftingStationHandler")
        local csh = cshMod and require(cshMod)
        local craftRemote = ReplicatedStorage:FindFirstChild("GameEvents") and ReplicatedStorage.GameEvents:FindFirstChild("CraftingGlobalObjectService")

        local function getBench(prefType)
            for _, b in ipairs(CollectionService:GetTagged("CraftingObject")) do
                if b:IsDescendantOf(Workspace) and b:GetAttribute("CraftingObjectType") == prefType then
                    return b, prefType
                end
            end
            for _, b in ipairs(CollectionService:GetTagged("CraftingObject")) do
                if b:IsDescendantOf(Workspace) then
                    return b, b:GetAttribute("CraftingObjectType")
                end
            end
            return nil, nil
        end

        local function processBenchCraft(fallbackBenchType, listObj, defaultSel)
            local chosenName = tostring(getUIListVal(listObj, defaultSel or "None"))
            if chosenName == "None" or chosenName == "" then return end

            local targetRecipeId = chosenName
            local targetMachines = {}
            for _, item in ipairs(allAvailableCraftPlants) do
                if item.Name == chosenName or item.BaseName == chosenName then
                    targetRecipeId = item.RecipeId
                    targetMachines = item.MachineTypes or {}
                    break
                end
            end
            if targetRecipeId == chosenName then
                for _, item in ipairs(allAvailableCraftGears) do
                    if item.Name == chosenName or item.BaseName == chosenName then
                        targetRecipeId = item.RecipeId
                        targetMachines = item.MachineTypes or {}
                        break
                    end
                end
            end

            local prefType = targetMachines[1] or fallbackBenchType
            local bench, slotKey = getBench(prefType)
            if not bench or not slotKey then
                bench, slotKey = getBench(fallbackBenchType)
            end
            if not bench or not slotKey then return end

            local mData = nil
            if cgos then
                pcall(function() mData = cgos:GetIndividualCraftingMachineData(bench, slotKey) end)
            end

            -- 1. Check if crafted item is ready to claim
            if mData and mData.CraftingItems and #mData.CraftingItems > 0 then
                local firstCraft = mData.CraftingItems[1]
                if firstCraft and firstCraft.IsDone then
                    if cgos then
                        pcall(function() cgos:Claim(bench, slotKey, 1) end)
                    elseif craftRemote then
                        pcall(function() craftRemote:FireServer("Claim", bench, slotKey, 1) end)
                    end
                    task.wait(0.15)
                else
                    if cgos then
                        pcall(function() cgos:Skip(bench, slotKey, 1) end)
                    elseif craftRemote then
                        pcall(function() craftRemote:FireServer("AuthoriseSkip", bench, slotKey, 1) end)
                    end
                end
                return
            end

            -- 2. If recipe is mismatched or unset, switch recipe
            local currentRecipeId = mData and mData.RecipeId
            if currentRecipeId ~= targetRecipeId then
                if currentRecipeId ~= nil then
                    if csh then
                        pcall(function() csh:CancelRecipe(bench) end)
                    elseif cgos then
                        pcall(function() cgos:Cancel(bench, slotKey) end)
                    elseif craftRemote then
                        pcall(function() craftRemote:FireServer("Cancel", bench, slotKey) end)
                    end
                    task.wait(0.15)
                end

                if cgos then
                    pcall(function() cgos:SetRecipe(bench, slotKey, targetRecipeId) end)
                elseif craftRemote then
                    pcall(function() craftRemote:FireServer("SetRecipe", bench, slotKey, targetRecipeId) end)
                end
                task.wait(0.2)
            end

            -- 3. Submit all required items from inventory
            if csh then
                pcall(function() csh:SubmitAllRequiredItems(bench) end)
            elseif craftRemote then
                pcall(function() craftRemote:FireServer("SubmitAllRequiredItems", bench) end)
            end
            task.wait(0.15)

            -- 4. Trigger Craft start
            if cgos then
                pcall(function() cgos:Craft(bench, slotKey) end)
            elseif craftRemote then
                pcall(function() craftRemote:FireServer("Craft", bench, slotKey) end)
            end
        end

        if autoPlants then
            processBenchCraft("SeedEventWorkbench", selectCraftPlantListObj, State.AutoCraft_SelectedPlant)
        end

        if autoGears then
            processBenchCraft("GearEventWorkbench", selectCraftGearListObj, State.AutoCraft_SelectedGear)
        end
    end)
end

task.spawn(function()
    while true do
        if _G.GAG_SESSION ~= currentSession then break end
        if State.AutoCraft_Plants or State.AutoCraft_Gears then
            local delayVal = math.clamp(tonumber(State.AutoCraft_Delay) or 0.5, 0.05, 5.0)
            executeAutoCraftCycle()
            task.wait(delayVal)
        else
            task.wait(0.5)
        end
    end
end)

-- =========================================================================
-- Fall Bloom Automator & Craving Engine (Anti-Spam & Auto-Submit)
-- =========================================================================
local function getCurrentFallCravingInfo()
    local currentTrait = "None"
    local slot = 0
    local elapsedInSlot = 0
    local isBloomActive = false
    local bloomDuration = 300
    local refreshInterval = 1800

    -- Layer 1: HarvestSpiritBillboard Tagged BillboardGui (100% ground-truth live in-game text)
    pcall(function()
        local bbs = CollectionService:GetTagged("HarvestSpiritBillboard")
        for _, bb in ipairs(bbs) do
            local bg = bb:FindFirstChild("BG")
            local tl = bg and bg:FindFirstChild("TextLabel")
            if tl and tl.Text and #tl.Text > 0 then
                local matched = tl.Text:match("<font.-%>(.-)</font>") or tl.Text:match("needs%s+<b>%s*(.-)%s*</b>")
                if matched and #matched > 0 then
                    local clean = matched:gsub("<.->", ""):gsub("%s+", "")
                    if clean and clean ~= "" and clean ~= "None" then
                        currentTrait = clean
                        return
                    end
                end
            end
        end
    end)

    -- Layer 2: Official CravingDisplayController
    if currentTrait == "None" then
        pcall(function()
            local cdcMod = ReplicatedStorage:FindFirstChild("Modules") and ReplicatedStorage.Modules:FindFirstChild("CravingControllers") and ReplicatedStorage.Modules.CravingControllers:FindFirstChild("CravingDisplayController")
            local configMod = ReplicatedStorage:FindFirstChild("Data") and ReplicatedStorage.Data:FindFirstChild("Events") and ReplicatedStorage.Data.Events:FindFirstChild("FallMarketEvent") and ReplicatedStorage.Data.Events.FallMarketEvent:FindFirstChild("FallMarketEventConfig")
            if cdcMod and configMod then
                local cdc = require(cdcMod)
                local config = require(configMod)
                local trait = cdc:GetTrait(config)
                if trait and trait ~= "" and trait ~= "None" then
                    currentTrait = trait
                end
            end
        end)
    end

    -- Layer 3: Official CravingUtils
    if currentTrait == "None" then
        pcall(function()
            local cuMod = ReplicatedStorage:FindFirstChild("Modules") and ReplicatedStorage.Modules:FindFirstChild("CravingUtils")
            local configMod = ReplicatedStorage:FindFirstChild("Data") and ReplicatedStorage.Data:FindFirstChild("Events") and ReplicatedStorage.Data.Events:FindFirstChild("FallMarketEvent") and ReplicatedStorage.Data.Events.FallMarketEvent:FindFirstChild("FallMarketEventConfig")
            if cuMod and configMod then
                local cu = require(cuMod)
                local config = require(configMod)
                local trait = cu:GetCurrentCraving({
                    Options = config.Traits or {"Berry", "Fruit", "Flower", "Vegetable", "Tropical", "Prickly", "Woody"},
                    Interval = config.CravingRefresh or 1800,
                    HashNum = config.RANDOM_SEED_VALUE or 8143
                })
                if trait and trait ~= "" and trait ~= "None" then
                    currentTrait = trait
                end
            end
        end)
    end

    pcall(function()
        local configMod = ReplicatedStorage:FindFirstChild("Data") and ReplicatedStorage.Data:FindFirstChild("Events") and ReplicatedStorage.Data.Events:FindFirstChild("FallMarketEvent") and ReplicatedStorage.Data.Events.FallMarketEvent:FindFirstChild("FallMarketEventConfig")
        if configMod then
            local config = require(configMod)
            refreshInterval = config.CravingRefresh or 1800
            bloomDuration = config.FallBloomDuration or 300
            local now = workspace:GetServerTimeNow()
            slot = math.floor(now / refreshInterval)
            elapsedInSlot = now % refreshInterval
            isBloomActive = (elapsedInSlot < bloomDuration)
        end
    end)

    pcall(function()
        local dsMod = ReplicatedStorage:FindFirstChild("Modules") and ReplicatedStorage.Modules:FindFirstChild("DataService")
        if dsMod then
            local ds = require(dsMod)
            local pData = ds:GetData()
            if pData and pData.FallMarket and pData.FallMarket.FallEnergyRewardClaimable then
                isBloomActive = true
            end
        end
    end)

    return {
        Trait = currentTrait,
        Slot = slot,
        ElapsedInSlot = elapsedInSlot,
        IsBloomActive = isBloomActive,
        BloomDuration = bloomDuration,
        RefreshInterval = refreshInterval
    }
end

local function isFruitTool(tool)
    if not tool or not tool:IsA("Tool") then return false end
    if tool:GetAttribute("PET_UUID") or tool:GetAttribute("PetType") or tool:GetAttribute("ItemType") == "Pet" then return false end
    if tool:GetAttribute("Seed") or tool:GetAttribute("ItemType") == "Seed" or tool:GetAttribute("ItemType") == "Packaged Seed" then return false end
    if tool:GetAttribute("Gear") or tool:GetAttribute("ItemType") == "Gear" then return false end
    local name = tool.Name:lower()
    if name:find("seed") or name:find("pack") or name:find("shovel") or name:find("can") or name:find("potion") or name:find("fertilizer") or name:find("sprinkler") then
        return false
    end
    return true
end

local function cleanPlantName(name)
    local s = tostring(name or "")
    s = s:gsub("^%s*%[.-%]%s*", "")
    s = s:gsub("%s*%[.-%]%s*$", "")
    s = s:gsub("_%w%w%w%w+$", "")
    s = s:gsub("^%s+", ""):gsub("%s+$", "")
    return s
end

local function checkPlantMatchesTrait(rawName, targetTrait)
    if not rawName or rawName == "" or not targetTrait or targetTrait == "" or targetTrait == "None" then
        return false
    end

    local base = cleanPlantName(rawName)
    if base == "" then return false end

    local baseLower = base:lower()
    if baseLower:find("seed") or baseLower:find("pack") or baseLower:find("shovel") or baseLower:find("sprinkler") or baseLower:find("fertilizer") or baseLower:find("potion") then
        return false
    end

    if PlantTraitsData and type(PlantTraitsData) == "table" then
        local matched = false
        pcall(function()
            -- 1. Direct HasTrait
            if type(PlantTraitsData.HasTrait) == "function" then
                if PlantTraitsData.HasTrait(base, targetTrait) then
                    matched = true
                    return
                end
            end

            -- 2. Direct dictionary lookup
            if PlantTraitsData[targetTrait] and PlantTraitsData[targetTrait][base] then
                matched = true
                return
            end

            -- 3. Strip suffixes (" Tree", " Bush", " Plant", " Crop", " Vine")
            local strippedSuffix = base:gsub("%s+[Tt]ree$", ""):gsub("%s+[Bb]ush$", ""):gsub("%s+[Pp]lant$", ""):gsub("%s+[Cc]rop$", ""):gsub("%s+[Vv]ine$", ""):gsub("%s+[Ss]eed$", "")
            if strippedSuffix ~= base then
                if type(PlantTraitsData.HasTrait) == "function" and PlantTraitsData.HasTrait(strippedSuffix, targetTrait) then
                    matched = true
                    return
                end
                if PlantTraitsData[targetTrait] and PlantTraitsData[targetTrait][strippedSuffix] then
                    matched = true
                    return
                end
            end

            -- 4. Strip variant prefixes ("Golden ", "Diamond ", "Rainbow ", etc.)
            local variants = {"Golden ", "Gold ", "Diamond ", "Rainbow ", "Silver ", "Shocked ", "Frozen ", "Chilled ", "Radioactive ", "Bloom ", "Mutated ", "Giant ", "Jumbo ", "Tiny "}
            local strippedPrefix = strippedSuffix
            for _, v in ipairs(variants) do
                if strippedPrefix:sub(1, #v):lower() == v:lower() then
                    strippedPrefix = strippedPrefix:sub(#v + 1):gsub("^%s+", "")
                end
            end
            if strippedPrefix ~= strippedSuffix then
                if type(PlantTraitsData.HasTrait) == "function" and PlantTraitsData.HasTrait(strippedPrefix, targetTrait) then
                    matched = true
                    return
                end
                if PlantTraitsData[targetTrait] and PlantTraitsData[targetTrait][strippedPrefix] then
                    matched = true
                    return
                end
            end

            -- 5. Exact match against plants in PlantTraitsData[targetTrait]
            if PlantTraitsData[targetTrait] and type(PlantTraitsData[targetTrait]) == "table" then
                local lowBase = base:lower()
                local lowStrip = strippedPrefix:lower()
                for pName, _ in pairs(PlantTraitsData[targetTrait]) do
                    local pLow = tostring(pName):lower()
                    if pLow == lowBase or pLow == lowStrip or lowBase:find(pLow, 1, true) or lowStrip:find(pLow, 1, true) then
                        matched = true
                        return
                    end
                end
            end
        end)
        if matched then return true end
    end

    return false
end

local function getMatchingCravingFruits(targetTrait)
    local matching = {}
    if not targetTrait or targetTrait == "None" then return matching end

    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            if isFruitTool(tool) then
                local pName = tool:GetAttribute("f") or tool:GetAttribute("Fruit") or tool:GetAttribute("Plant") or tool.Name
                if checkPlantMatchesTrait(pName, targetTrait) then
                    table.insert(matching, {Tool = tool, Name = pName})
                end
            end
        end
    end

    local char = LocalPlayer.Character
    if char then
        for _, tool in ipairs(char:GetChildren()) do
            if isFruitTool(tool) then
                local pName = tool:GetAttribute("f") or tool:GetAttribute("Fruit") or tool:GetAttribute("Plant") or tool.Name
                if checkPlantMatchesTrait(pName, targetTrait) then
                    table.insert(matching, {Tool = tool, Name = pName})
                end
            end
        end
    end

    return matching
end

local function sellStaleFallFruits(targetTrait)
    if not targetTrait or targetTrait == "None" then return end
    pcall(function()
        local ge = ReplicatedStorage:FindFirstChild("GameEvents")
        local sellItemRem = (ge and ge:FindFirstChild("Sell_Item")) or getSellItemRemote()

        local allTools = getAllPlayerTools()
        for _, tool in ipairs(allTools) do
            if tool and tool.Parent and isFruitTool(tool) then
                local pName = tool:GetAttribute("f") or tool:GetAttribute("Fruit") or tool:GetAttribute("Plant") or tool.Name
                if not checkPlantMatchesTrait(pName, targetTrait) then
                    if sellItemRem then
                        pcall(function()
                            sellItemRem:FireServer(tool)
                        end)
                    end
                end
            end
        end
    end)
end

local function executeFallBloomSubmissionCycle()
    pcall(function()
        local cravingInfo = getCurrentFallCravingInfo()
        if not cravingInfo or cravingInfo.Trait == "None" then return end

        -- Only submit if the player actually has matching plants in inventory
        local matching = getMatchingCravingFruits(cravingInfo.Trait)
        if #matching == 0 then return end

        local ge = ReplicatedStorage:FindFirstChild("GameEvents")
        local ev = ge and ge:FindFirstChild("Events")
        local fm = ev and ev:FindFirstChild("FallMarketEvent")
        local submitAllRem = fm and fm:FindFirstChild("SubmitAllPlants")
        local claimEnergyRem = fm and fm:FindFirstChild("ClaimFallEnergyRewards")

        -- Official Developer remote batch submit (Direct remote call, 0 NPC dialogue popups)
        if submitAllRem then
            submitAllRem:FireServer()
        end

        -- Auto-claim fall energy rewards
        if claimEnergyRem then
            claimEnergyRem:FireServer()
        end
    end)
end

local function executeFallBloomCollectCycle()
    local cravingInfo = getCurrentFallCravingInfo()
    if not cravingInfo or cravingInfo.Trait == "None" then return end
    local targetTrait = cravingInfo.Trait

    -- If backpack is full, auto-sell stale non-matching fruits to make room for new category
    if isBackpackFull() then
        sellStaleFallFruits(targetTrait)
        task.wait(0.15)
        if isBackpackFull() then return end
    end

    local colRemote = getCollectRemote()
    if not colRemote then return end

    local farmFolder = Workspace:FindFirstChild("Farm") or Workspace
    local myFarm = getPlayerFarm()
    local farmList = (myFarm and {myFarm}) or farmFolder:GetChildren()

    local matchingFruitGroups = {}
    local function scanFarms(list)
        for _, farm in ipairs(list) do
            local important = farm:FindFirstChild("Important")
            local plantsFolder = important and important:FindFirstChild("Plants_Physical")
            if plantsFolder then
                for _, plant in ipairs(plantsFolder:GetChildren()) do
                    if checkPlantMatchesTrait(plant.Name, targetTrait) then
                        local fruitsFolder = plant:FindFirstChild("Fruits")
                        if fruitsFolder then
                            for _, fruitGroup in ipairs(fruitsFolder:GetChildren()) do
                                table.insert(matchingFruitGroups, fruitGroup)
                            end
                        else
                            for _, child in ipairs(plant:GetChildren()) do
                                if child.Name:lower():find("fruit") or child:FindFirstChildWhichIsA("ProximityPrompt", true) then
                                    table.insert(matchingFruitGroups, child)
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    scanFarms(farmList)
    if #matchingFruitGroups == 0 and myFarm and farmFolder ~= Workspace then
        scanFarms(farmFolder:GetChildren())
    end

    if #matchingFruitGroups > 0 then
        local batch = {}
        local maxBatch = State.BatchSize or 35
        for _, fg in ipairs(matchingFruitGroups) do
            if not isToggleActive(autoCollectFallBloomToggle, State.AutoCollect_FallBloomFruit, "Auto Collect Needed Fruit (Fall Bloom)") then break end
            table.insert(batch, fg)
            if #batch >= maxBatch then
                pcall(function()
                    colRemote:FireServer(batch)
                end)
                batch = {}
                task.wait(0.04)
            end
        end
        if #batch > 0 and isToggleActive(autoCollectFallBloomToggle, State.AutoCollect_FallBloomFruit, "Auto Collect Needed Fruit (Fall Bloom)") then
            pcall(function()
                colRemote:FireServer(batch)
            end)
        end
    end
end

-- Fall Bloom Auto-Collect Background Worker
local lastCravingTrait = nil
task.spawn(function()
    while true do
        if _G.GAG_SESSION ~= currentSession then break end
        if isToggleActive(autoCollectFallBloomToggle, State.AutoCollect_FallBloomFruit, "Auto Collect Needed Fruit (Fall Bloom)") 
           or State.AutoSubmitFallBloom then
            pcall(function()
                local cInfo = getCurrentFallCravingInfo()
                if cInfo and cInfo.Trait ~= "None" then
                    -- When the craving rotates to a new category, immediately sell old stale fruits from the previous category
                    if lastCravingTrait and lastCravingTrait ~= cInfo.Trait then
                        sellStaleFallFruits(cInfo.Trait)
                    end
                    lastCravingTrait = cInfo.Trait
                end

                if isToggleActive(autoCollectFallBloomToggle, State.AutoCollect_FallBloomFruit, "Auto Collect Needed Fruit (Fall Bloom)") then
                    executeFallBloomCollectCycle()
                end
            end)
            task.wait(State.HarvestDelay or 0.1)
        else
            task.wait(0.5)
        end
    end
end)

-- Fall Bloom Auto-Submit Background Worker
task.spawn(function()
    while true do
        if _G.GAG_SESSION ~= currentSession then break end
        if State.AutoSubmitFallBloom then
            local delayVal = math.clamp(tonumber(State.AutoSubmitFallBloom_Delay) or 1.0, 0.25, 10.0)
            executeFallBloomSubmissionCycle()
            task.wait(delayVal)
        else
            task.wait(0.5)
        end
    end
end)

-- Fall Event Shops Auto-Buy Engine
-- =========================================================================
local function executeEventShopPurchases()
    pcall(function()
        local dsMod = ReplicatedStorage:FindFirstChild("Modules") and ReplicatedStorage.Modules:FindFirstChild("DataService")
        local ds = dsMod and require(dsMod)
        local data = ds and ds:GetData()
        local eventShopStock = data and data.EventShopStock or {}

        local ge = ReplicatedStorage:FindFirstChild("GameEvents")
        local buyEventRem = ge and ge:FindFirstChild("BuyEventShopStock")
        local buyGardenCoinRem = ge and ge:FindFirstChild("BuyGardenCoinShopStock")

        local pGui = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
        local eventShopGui = pGui and (pGui:FindFirstChild("EventShop_UI") or pGui:FindFirstChild("FallMarketEventShop_UI"))

        local function triggerShopBuy(itemName, shopKey)
            if not itemName or itemName == "" then return end
            if buyEventRem then
                buyEventRem:FireServer(tostring(itemName), tostring(shopKey))
            end
            if buyGardenCoinRem then
                buyGardenCoinRem:FireServer(tostring(itemName))
            end
            pcall(function()
                if eventShopGui and eventShopGui.Enabled then
                    for _, desc in ipairs(eventShopGui:GetDescendants()) do
                        if desc:IsA("GuiObject") and desc.Name == tostring(itemName) then
                            local btn = desc:FindFirstChild("Sheckles_Buy", true) or desc:FindFirstChild("CashBuy", true)
                            if btn and getconnections then
                                for _, c in ipairs(getconnections(btn.Activated)) do c:Fire() end
                            end
                            if btn and firesignal then firesignal(btn.Activated) end
                        end
                    end
                end
            end)
        end

        -- 1. Event Seeds
        if State.AutoBuy_EventSeeds then
            local seedShopStock = eventShopStock["Fall Market Seed Shop"] and eventShopStock["Fall Market Seed Shop"].Stocks or {}
            local selectedSeed = tostring(getUIListVal(selectEventSeedListObj, State.AutoBuy_SelectedEventSeed or "All Event Seeds"))
            local cleanTarget = selectedSeed:gsub("%s*%([%d%.]+%a*¢%)", ""):gsub("^%s+", ""):gsub("%s+$", "")

            if cleanTarget == "All Event Seeds" or cleanTarget == "None" or cleanTarget == "" then
                for itemName, info in pairs(seedShopStock) do
                    local stock = tonumber(info.Stock) or 0
                    if stock > 0 then
                        triggerShopBuy(itemName, "Fall Market Seed Shop")
                    end
                end
            else
                for itemName, info in pairs(seedShopStock) do
                    if itemName:lower() == cleanTarget:lower() or itemName:lower():find(cleanTarget:lower(), 1, true) or cleanTarget:lower():find(itemName:lower(), 1, true) then
                        local stock = tonumber(info.Stock) or 0
                        if stock > 0 then
                            triggerShopBuy(itemName, "Fall Market Seed Shop")
                        end
                    end
                end
            end
        end

        -- 2. Event Gears
        if State.AutoBuy_EventGears then
            local gearShopStock = eventShopStock["Fall Market Gear Shop"] and eventShopStock["Fall Market Gear Shop"].Stocks or {}
            local selectedGear = tostring(getUIListVal(selectEventGearListObj, State.AutoBuy_SelectedEventGear or "All Event Gears"))
            local cleanTarget = selectedGear:gsub("%s*%([%d%.]+%a*¢%)", ""):gsub("^%s+", ""):gsub("%s+$", "")

            if cleanTarget == "All Event Gears" or cleanTarget == "None" or cleanTarget == "" then
                for itemName, info in pairs(gearShopStock) do
                    local stock = tonumber(info.Stock) or 0
                    if stock > 0 then
                        triggerShopBuy(itemName, "Fall Market Gear Shop")
                    end
                end
            else
                for itemName, info in pairs(gearShopStock) do
                    if itemName:lower() == cleanTarget:lower() or itemName:lower():find(cleanTarget:lower(), 1, true) or cleanTarget:lower():find(itemName:lower(), 1, true) then
                        local stock = tonumber(info.Stock) or 0
                        if stock > 0 then
                            triggerShopBuy(itemName, "Fall Market Gear Shop")
                        end
                    end
                end
            end
        end

        -- 3. Event Pets
        if State.AutoBuy_EventPets then
            local petShopStock = eventShopStock["Fall Market Pet Shop"] and eventShopStock["Fall Market Pet Shop"].Stocks or {}
            local selectedPet = tostring(getUIListVal(selectEventPetListObj, State.AutoBuy_SelectedEventPet or "All Event Pets"))
            local cleanTarget = selectedPet:gsub("%s*%([%d%.]+%a*¢%)", ""):gsub("^%s+", ""):gsub("%s+$", "")

            if cleanTarget == "All Event Pets" or cleanTarget == "None" or cleanTarget == "" then
                for itemName, info in pairs(petShopStock) do
                    local stock = tonumber(info.Stock) or 0
                    if stock > 0 then
                        triggerShopBuy(itemName, "Fall Market Pet Shop")
                    end
                end
            else
                for itemName, info in pairs(petShopStock) do
                    if itemName:lower() == cleanTarget:lower() or itemName:lower():find(cleanTarget:lower(), 1, true) or cleanTarget:lower():find(itemName:lower(), 1, true) then
                        local stock = tonumber(info.Stock) or 0
                        if stock > 0 then
                            triggerShopBuy(itemName, "Fall Market Pet Shop")
                        end
                    end
                end
            end
        end

        -- 4. Event Cosmetics
        if State.AutoBuy_EventCosmetics then
            local cosmeticShopStock = eventShopStock["Fall Market Cosmetic Shop"] and eventShopStock["Fall Market Cosmetic Shop"].Stocks or {}
            local selectedCosmetic = tostring(getUIListVal(selectEventCosmeticListObj, State.AutoBuy_SelectedEventCosmetic or "All Event Cosmetics"))
            local cleanTarget = selectedCosmetic:gsub("%s*%([%d%.]+%a*¢%)", ""):gsub("^%s+", ""):gsub("%s+$", "")

            if cleanTarget == "All Event Cosmetics" or cleanTarget == "None" or cleanTarget == "" then
                for itemName, info in pairs(cosmeticShopStock) do
                    local stock = tonumber(info.Stock) or 0
                    if stock > 0 then
                        triggerShopBuy(itemName, "Fall Market Cosmetic Shop")
                    end
                end
            else
                for itemName, info in pairs(cosmeticShopStock) do
                    if itemName:lower() == cleanTarget:lower() or itemName:lower():find(cleanTarget:lower(), 1, true) or cleanTarget:lower():find(itemName:lower(), 1, true) then
                        local stock = tonumber(info.Stock) or 0
                        if stock > 0 then
                            triggerShopBuy(itemName, "Fall Market Cosmetic Shop")
                        end
                    end
                end
            end
        end
    end)
end

-- Fall Event Shops Auto-Buy Background Worker
task.spawn(function()
    while true do
        if _G.GAG_SESSION ~= currentSession then break end
        local isAnyEventBuyActive = State.AutoBuy_EventSeeds or State.AutoBuy_EventGears or State.AutoBuy_EventPets or State.AutoBuy_EventCosmetics
        if isAnyEventBuyActive then
            local delayVal = math.clamp(tonumber(State.EventShop_BuyDelay) or 0.25, 0.05, 5.0)
            executeEventShopPurchases()
            task.wait(delayVal)
        else
            task.wait(0.5)
        end
    end
end)

-- =========================================================================
-- UI Tabs & Control Layout
-- =========================================================================
local function buildAllUI()
local variantNames = {"None", "Silver", "Gold", "Diamond", "Rainbow", "Basic"}
local variantItems = {}
for _, name in ipairs(variantNames) do table.insert(variantItems, {Name = name}) end

local mutationItems = {}
for _, name in ipairs(allAvailableMutations) do table.insert(mutationItems, {Name = name}) end

local specificFruitItems = {}
for _, name in ipairs(allAvailablePlants) do table.insert(specificFruitItems, {Name = name}) end

local seedListItems = {}
for _, name in ipairs(allAvailableSeeds) do table.insert(seedListItems, {Name = name}) end

local categoryItems = {}
for _, name in ipairs(allAvailableCategories) do table.insert(categoryItems, {Name = name}) end

local petListItems = {}
for _, name in ipairs(allAvailablePets) do table.insert(petListItems, {Name = name}) end

local productListItems = {}
for _, item in ipairs(allAvailableProducts) do table.insert(productListItems, {Name = item.Name}) end

local eggListItems = {}
for _, item in ipairs(allAvailableEggs) do table.insert(eggListItems, {Name = item.Name}) end

local gearListItems = {}
for _, item in ipairs(allAvailableGears) do table.insert(gearListItems, {Name = item.Name}) end

local seedShopListItems = {}
for _, item in ipairs(allAvailableSeedShop) do table.insert(seedShopListItems, {Name = item.Name}) end

local cosmeticListItems = {}
for _, item in ipairs(allAvailableCosmetics) do table.insert(cosmeticListItems, {Name = item.Name}) end

local sprinklerListItems = {}
for _, item in ipairs(allAvailableSprinklers) do table.insert(sprinklerListItems, {Name = item.Name}) end

local craftablePlantsListItems = {}
for _, item in ipairs(allAvailableCraftPlants) do table.insert(craftablePlantsListItems, {Name = item.Name}) end

local craftableGearsListItems = {}
for _, item in ipairs(allAvailableCraftGears) do table.insert(craftableGearsListItems, {Name = item.Name}) end

local eventSeedListItems = {}
for _, item in ipairs(allAvailableEventSeeds) do table.insert(eventSeedListItems, {Name = item.Name}) end

local eventGearListItems = {}
for _, item in ipairs(allAvailableEventGears) do table.insert(eventGearListItems, {Name = item.Name}) end

local eventPetListItems = {}
for _, item in ipairs(allAvailableEventPets) do table.insert(eventPetListItems, {Name = item.Name}) end

local eventCosmeticListItems = {}
for _, item in ipairs(allAvailableEventCosmetics) do table.insert(eventCosmeticListItems, {Name = item.Name}) end

local slotListItems = {
    {Name = "None"},
    {Name = "Slot 1"},
    {Name = "Slot 2"},
    {Name = "Slot 3"},
    {Name = "Slot 4"},
    {Name = "Slot 5"},
    {Name = "Slot 6"}
}

local farmTab = Hub.CreateTab("Farm", { Icon = "🌱", Size = 18, Color = Color3.fromRGB(170, 185, 210), ActiveColor = Color3.fromRGB(50, 220, 120) })
local petTab = Hub.CreateTab("Pets", { Icon = "🐾", Size = 18, Color = Color3.fromRGB(170, 185, 210), ActiveColor = Color3.fromRGB(255, 180, 50) })
local shopTab = Hub.CreateTab("Shop", { Icon = "🛒", Size = 18, Color = Color3.fromRGB(170, 185, 210), ActiveColor = Color3.fromRGB(0, 215, 255) })
local eventTab = Hub.CreateTab("Events", { Icon = "🎪", Size = 18, Color = Color3.fromRGB(170, 185, 210), ActiveColor = Color3.fromRGB(240, 100, 200) })
local tradeTab = Hub.CreateTab("Trade", { Icon = "🔄", Size = 18, Color = Color3.fromRGB(170, 185, 210), ActiveColor = Color3.fromRGB(100, 200, 255) })
local miscTab = Hub.CreateTab("Misc", { Icon = "🔮", Size = 18, Color = Color3.fromRGB(170, 185, 210), ActiveColor = Color3.fromRGB(180, 140, 255) })

-- ==========================================
-- Section: Trade Plaza Sniper
-- ==========================================
Hub.CreateSection(tradeTab, "🚀 Auto Search Pet (Standalone Script)")

Hub.CreateButton(tradeTab, "📋 Copy Auto Search Pet Script", function()
    local scriptSource = [=[
local Config = {
    KeepHoppingAfterBuy = true,
    BuyAllMatchesOnServer = true,
    HopDelayAfterBuy = 1.5,
    UseFindSellers = true,

    Targets = {
        {
            Pet = "Bagel Bunny",
            MaxPrice = 10,
            Mutations = "None",
            MaxWeight = 0,
            MaxAge = 0
        },
        {
            Pet = "Pancake Mole",
            MaxPrice = 10,
            Mutations = "None",
            MaxWeight = 0,
            MaxAge = 0
        }
    },

    MaxScanPasses = 5,
    PassDelay = 0.15
}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")

local LocalPlayer = Players.LocalPlayer
while not LocalPlayer do
    LocalPlayer = Players.LocalPlayer
    task.wait(0.05)
end

local TRADING_PLAZA_PLACE_ID = 129954712878723
local httpRequest = request or http_request or (syn and syn.request) or (http and http.request) or (fluxus and fluxus.request) or (krnl and krnl.request)

pcall(function()
    TeleportService.TeleportInitFailed:Connect(function(plr, result, msg)
        print(string.format("[Sniper] Teleport failed (%s: %s). Auto-dismissing error dialog and retrying...", tostring(result), tostring(msg)))
        pcall(function()
            if GuiService and GuiService.ClearError then
                GuiService:ClearError()
            end
        end)
        task.wait(0.8)
        pcall(function()
            TeleportService:Teleport(TRADING_PLAZA_PLACE_ID, LocalPlayer)
        end)
    end)
end)

if game.PlaceId ~= TRADING_PLAZA_PLACE_ID then
    print("[Sniper] Not in Trading Plaza. Teleporting to Trading Plaza...")
    TeleportService:Teleport(TRADING_PLAZA_PLACE_ID, LocalPlayer)
    return
end

local visitedServers = {}
pcall(function()
    if readfile and isfile and isfile("gag_visited_servers.json") then
        local content = readfile("gag_visited_servers.json")
        visitedServers = HttpService:JSONDecode(content) or {}
    end
end)
if type(visitedServers) ~= "table" then visitedServers = {} end
visitedServers[tostring(game.JobId)] = tick()

local cachedServers = {}
local serverInfoMap = {}
local isFetchingServers = false

local function refreshServerListAsync()
    if isFetchingServers or not httpRequest then return end
    isFetchingServers = true
    task.spawn(function()
        pcall(function()
            local cursor = ""
            local newServers = {}
            local newMap = {}
            
            for page = 1, 3 do
                local url = string.format("https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Desc&limit=100%s", 
                    tostring(TRADING_PLAZA_PLACE_ID),
                    (cursor ~= "" and ("&cursor=" .. cursor) or "")
                )
                local res = httpRequest({Url = url, Method = "GET"})
                if res and res.Body then
                    local body = HttpService:JSONDecode(res.Body)
                    if body and body.data then
                        for _, s in ipairs(body.data) do
                            local id = tostring(s.id)
                            local maxPlrs = tonumber(s.maxPlayers) or 20
                            local playing = tonumber(s.playing) or 0
                            newMap[id] = { playing = playing, maxPlayers = maxPlrs }
                            if id ~= tostring(game.JobId) and not visitedServers[id] and playing > 0 and playing <= (maxPlrs - 2) then
                                table.insert(newServers, id)
                            end
                        end
                        if body.nextPageCursor and body.nextPageCursor ~= "" then
                            cursor = body.nextPageCursor
                        else
                            break
                        end
                    else
                        break
                    end
                else
                    break
                end
            end
            if #newServers > 0 then
                cachedServers = newServers
            end
            for k, v in pairs(newMap) do
                serverInfoMap[k] = v
            end
        end)
        isFetchingServers = false
    end)
end

refreshServerListAsync()

local function tryFindSellersDirectHop(targets)
    if not Config.UseFindSellers then return false end

    local TokenRAPUtil = nil
    pcall(function()
        local mod = ReplicatedStorage:FindFirstChild("Modules")
        local tt = mod and mod:FindFirstChild("TradeTokens")
        if tt and tt:FindFirstChild("TokenRAPUtil") then
            TokenRAPUtil = require(tt.TokenRAPUtil)
        end
    end)

    local findSellersRemote = nil
    pcall(function()
        findSellersRemote = ReplicatedStorage:FindFirstChild("GameEvents")
            and ReplicatedStorage.GameEvents:FindFirstChild("TradeEvents")
            and ReplicatedStorage.GameEvents.TradeEvents:FindFirstChild("TokenRAPs")
            and ReplicatedStorage.GameEvents.TradeEvents.TokenRAPs:FindFirstChild("FindSellers")
    end)

    if not findSellersRemote or not TokenRAPUtil then return false end

    local sellerCandidates = {}

    for _, target in ipairs(targets) do
        local cleanTarget = target.CleanName
        if cleanTarget ~= "all" and cleanTarget ~= "allpets" and cleanTarget ~= "any" and cleanTarget ~= "*" then
            local petName = target.Name
            local itemData = TokenRAPUtil.GetDefaultItemData("Pet", petName)
            if itemData then
                local success, hasSeller, listingJobId = pcall(function()
                    return findSellersRemote:InvokeServer("Pet", itemData)
                end)

                if success and hasSeller and listingJobId and type(listingJobId) == "string" and listingJobId ~= "" then
                    local strJobId = tostring(listingJobId)
                    if strJobId ~= tostring(game.JobId) and not visitedServers[strJobId] then
                        local sInfo = serverInfoMap[strJobId]
                        local isFull = sInfo and sInfo.playing and sInfo.maxPlayers and (sInfo.playing >= sInfo.maxPlayers)
                        if not isFull then
                            table.insert(sellerCandidates, {
                                Pet = petName,
                                JobId = strJobId,
                                Playing = sInfo and sInfo.playing or 10,
                                MaxPlayers = sInfo and sInfo.maxPlayers or 20
                            })
                        else
                            print(string.format("[Sniper] ⚠️ FindSellers found seller for '%s', but server %s is full (%d/%d). Skipping.", petName, strJobId, sInfo.playing, sInfo.maxPlayers))
                        end
                    end
                end
            end
        end
    end

    if #sellerCandidates > 0 then
        table.sort(sellerCandidates, function(a, b)
            return a.Playing < b.Playing
        end)

        local chosen = sellerCandidates[1]
        print(string.format("[Sniper] 🎯 FindSellers matched [%d] seller candidate(s)! Teleporting for '%s' to server %s (%d/%d players)...", #sellerCandidates, chosen.Pet, chosen.JobId, chosen.Playing, chosen.MaxPlayers))

        visitedServers[chosen.JobId] = tick()
        pcall(function()
            if writefile then
                writefile("gag_visited_servers.json", HttpService:JSONEncode(visitedServers))
            end
        end)

        local teleported = false
        pcall(function()
            local tListing = ReplicatedStorage.GameEvents.TradeEvents.TokenRAPs:FindFirstChild("TeleportToListing")
            if tListing then
                teleported = tListing:InvokeServer(chosen.JobId, true)
            end
        end)

        if not teleported then
            pcall(function()
                TeleportService:TeleportToPlaceInstance(TRADING_PLAZA_PLACE_ID, chosen.JobId, LocalPlayer)
            end)
        end
        return true
    end

    return false
end

local function serverHop(targets)
    print("[Sniper] Initiating hop...")
    
    if targets and #targets > 0 then
        local jumped = tryFindSellersDirectHop(targets)
        if jumped then return end
    end

    local now = tick()
    for jId, timestamp in pairs(visitedServers) do
        if type(timestamp) == "number" and (now - timestamp > 900) then
            visitedServers[jId] = nil
        end
    end
    visitedServers[tostring(game.JobId)] = now
    pcall(function()
        if writefile then
            writefile("gag_visited_servers.json", HttpService:JSONEncode(visitedServers))
        end
    end)

    if #cachedServers > 0 then
        local targetServer = cachedServers[math.random(1, #cachedServers)]
        print(string.format("[Sniper] Teleporting to pre-fetched server %s (from %d non-full candidates)...", tostring(targetServer), #cachedServers))
        
        visitedServers[tostring(targetServer)] = now
        pcall(function()
            if writefile then
                writefile("gag_visited_servers.json", HttpService:JSONEncode(visitedServers))
            end
        end)

        local s, e = pcall(function()
            TeleportService:TeleportToPlaceInstance(TRADING_PLAZA_PLACE_ID, targetServer, LocalPlayer)
        end)
        if s then return end
    end

    if httpRequest then
        local validServers = {}
        local url = string.format("https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Desc&limit=100", tostring(TRADING_PLAZA_PLACE_ID))
        local res = nil
        pcall(function()
            res = httpRequest({Url = url, Method = "GET"})
        end)

        if res and res.Body then
            local ok, body = pcall(function() return HttpService:JSONDecode(res.Body) end)
            if ok and body and body.data then
                for _, s in ipairs(body.data) do
                    local maxPlrs = tonumber(s.maxPlayers) or 20
                    local playing = tonumber(s.playing) or 0
                    local id = tostring(s.id)
                    if id ~= tostring(game.JobId) and not visitedServers[id] and playing > 0 and playing <= (maxPlrs - 2) then
                        table.insert(validServers, id)
                    end
                end
            end
        end

        if #validServers > 0 then
            local targetServer = validServers[math.random(1, #validServers)]
            print(string.format("[Sniper] Teleporting to server %s (from %d candidates)...", tostring(targetServer), #validServers))
            
            visitedServers[tostring(targetServer)] = now
            pcall(function()
                if writefile then
                    writefile("gag_visited_servers.json", HttpService:JSONEncode(visitedServers))
                end
            end)

            local s, e = pcall(function()
                TeleportService:TeleportToPlaceInstance(TRADING_PLAZA_PLACE_ID, targetServer, LocalPlayer)
            end)
            if s then return end
        end
    end

    print("[Sniper] Using standard matchmaking teleport...")
    pcall(function()
        TeleportService:Teleport(TRADING_PLAZA_PLACE_ID, LocalPlayer)
    end)
end

local function normalizeTargets(cfg)
    local targets = {}

    if cfg.Targets and type(cfg.Targets) == "table" and #cfg.Targets > 0 then
        for _, t in ipairs(cfg.Targets) do
            if type(t) == "table" then
                local name = t.Pet or t.Name or t[1]
                if name and type(name) == "string" and name ~= "" then
                    table.insert(targets, {
                        Name = name,
                        CleanName = name:gsub("[%s%p]", ""):lower(),
                        MaxPrice = tonumber(t.MaxPrice or t.Price or cfg.MaxPrice) or 50,
                        Mutations = tostring(t.Mutations or t.Mutation or cfg.Mutations or cfg.Mutation or "None"),
                        MaxWeight = tonumber(t.MaxWeight or t.Weight or cfg.MaxWeight or cfg.Weight) or 0,
                        MaxAge = tonumber(t.MaxAge or t.Age or t.Level or cfg.MaxAge or cfg.Age) or 0
                    })
                end
            elseif type(t) == "string" and t ~= "" then
                table.insert(targets, {
                    Name = t,
                    CleanName = t:gsub("[%s%p]", ""):lower(),
                    MaxPrice = tonumber(cfg.MaxPrice) or 50,
                    Mutations = tostring(cfg.Mutations or cfg.Mutation or "None"),
                    MaxWeight = tonumber(cfg.MaxWeight or cfg.Weight) or 0,
                    MaxAge = tonumber(cfg.MaxAge or cfg.Age) or 0
                })
            end
        end
    else
        local petList = cfg.Pets or cfg.Pet
        if type(petList) == "table" then
            for idx, pItem in ipairs(petList) do
                if type(pItem) == "string" and pItem ~= "" then
                    local pName = pItem
                    local pPrice = (type(cfg.MaxPrice) == "table" and (cfg.MaxPrice[idx] or cfg.MaxPrice[pName])) or (type(cfg.Price) == "table" and (cfg.Price[idx] or cfg.Price[pName])) or tonumber(cfg.MaxPrice or cfg.Price) or 50
                    local pMut = (type(cfg.Mutations) == "table" and (cfg.Mutations[idx] or cfg.Mutations[pName])) or (type(cfg.Mutation) == "table" and (cfg.Mutation[idx] or cfg.Mutation[pName])) or tostring(cfg.Mutations or cfg.Mutation or "None")
                    local pWeight = (type(cfg.MaxWeight) == "table" and (cfg.MaxWeight[idx] or cfg.MaxWeight[pName])) or (type(cfg.Weight) == "table" and (cfg.Weight[idx] or cfg.Weight[pName])) or tonumber(cfg.MaxWeight or cfg.Weight) or 0
                    local pAge = (type(cfg.MaxAge) == "table" and (cfg.MaxAge[idx] or cfg.MaxAge[pName])) or (type(cfg.Age) == "table" and (cfg.Age[idx] or cfg.Age[pName])) or tonumber(cfg.MaxAge or cfg.Age) or 0

                    table.insert(targets, {
                        Name = pName,
                        CleanName = pName:gsub("[%s%p]", ""):lower(),
                        MaxPrice = tonumber(pPrice) or 50,
                        Mutations = tostring(pMut or "None"),
                        MaxWeight = tonumber(pWeight) or 0,
                        MaxAge = tonumber(pAge) or 0
                    })
                elseif type(pItem) == "table" then
                    local name = pItem.Pet or pItem.Name or pItem[1]
                    if name and type(name) == "string" and name ~= "" then
                        table.insert(targets, {
                            Name = name,
                            CleanName = name:gsub("[%s%p]", ""):lower(),
                            MaxPrice = tonumber(pItem.MaxPrice or pItem.Price or cfg.MaxPrice) or 50,
                            Mutations = tostring(pItem.Mutations or pItem.Mutation or cfg.Mutations or "None"),
                            MaxWeight = tonumber(pItem.MaxWeight or pItem.Weight or cfg.MaxWeight) or 0,
                            MaxAge = tonumber(pItem.MaxAge or pItem.Age or cfg.MaxAge) or 0
                        })
                    end
                end
            end
        elseif type(petList) == "string" and petList ~= "" then
            table.insert(targets, {
                Name = petList,
                CleanName = petList:gsub("[%s%p]", ""):lower(),
                MaxPrice = tonumber(cfg.MaxPrice or cfg.Price) or 50,
                Mutations = tostring(cfg.Mutations or cfg.Mutation or "None"),
                MaxWeight = tonumber(cfg.MaxWeight or cfg.Weight) or 0,
                MaxAge = tonumber(cfg.MaxAge or cfg.Age) or 0
            })
        end
    end

    return targets
end

local baselineInventoryUUIDs = {}
local function snapshotExistingPets()
    pcall(function()
        if not LocalPlayer then
            LocalPlayer = Players.LocalPlayer
        end
        if not LocalPlayer then return end

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
    end)
end
snapshotExistingPets()

local function hasAcquiredNewTargetPet(targetCleanName)
    local acquired = false
    pcall(function()
        if not LocalPlayer then
            LocalPlayer = Players.LocalPlayer
        end
        if not LocalPlayer then return end

        local isWildcard = (not targetCleanName or targetCleanName == "all" or targetCleanName == "allpets" or targetCleanName == "any" or targetCleanName == "*")
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        if backpack then
            for _, tool in ipairs(backpack:GetChildren()) do
                if tool:IsA("Tool") then
                    local uuid = tool:GetAttribute("PET_UUID") or tool:GetAttribute("UUID") or tool:GetAttribute("PetUUID")
                    if uuid and not baselineInventoryUUIDs[tostring(uuid)] then
                        local pSpecies = tool:GetAttribute("f") or tool:GetAttribute("PetType") or tool:GetAttribute("Species") or tool:GetAttribute("Name") or tool.Name
                        if pSpecies and type(pSpecies) == "string" then
                            local clean = pSpecies:gsub("[%s%p]", ""):lower()
                            if isWildcard or clean == targetCleanName or clean:find(targetCleanName, 1, true) then
                                baselineInventoryUUIDs[tostring(uuid)] = true
                                acquired = true
                                return
                            end
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
                        local pSpecies = tool:GetAttribute("f") or tool:GetAttribute("PetType") or tool:GetAttribute("Species") or tool:GetAttribute("Name") or tool.Name
                        if pSpecies and type(pSpecies) == "string" then
                            local clean = pSpecies:gsub("[%s%p]", ""):lower()
                            if isWildcard or clean == targetCleanName or clean:find(targetCleanName, 1, true) then
                                baselineInventoryUUIDs[tostring(uuid)] = true
                                acquired = true
                                return
                            end
                        end
                    end
                end
            end
        end
    end)
    return acquired
end

local function interactWithBooth(boothUUID)
    pcall(function()
        if not LocalPlayer then
            LocalPlayer = Players.LocalPlayer
        end
        local tw = workspace:FindFirstChild("TradeWorld")
        local booths = tw and tw:FindFirstChild("Booths")
        local boothModel = booths and booths:FindFirstChild(boothUUID)
        if boothModel then
            local pivot = boothModel:GetPivot()
            local char = LocalPlayer and (LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait())
            local root = char and (char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart", 2))
            if root then
                root.CFrame = pivot * CFrame.new(0, 0, 4)
            end

            local prompt = boothModel:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt then
                if fireproximityprompt then
                    fireproximityprompt(prompt)
                elseif getconnections and LocalPlayer then
                    for _, conn in ipairs(getconnections(prompt.Triggered)) do
                        conn:Fire(LocalPlayer)
                    end
                end
            end
        end
    end)

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

local function extractPetInfo(itemData, listInfo)
    local pd = (type(itemData) == "table" and (itemData.PetData or itemData)) or {}
    local li = (type(listInfo) == "table" and listInfo) or {}

    local rawSpecies = pd.PetType or pd.Species or pd.Name or pd.f or pd.ItemName
        or (type(itemData) == "table" and (itemData.PetType or itemData.ItemName or itemData.Species or itemData.Name)) 
        or li.PetType or li.ItemName or li.Species or li.Name

    if not rawSpecies or type(rawSpecies) ~= "string" or rawSpecies == "" then
        return nil
    end

    local speciesName = tostring(rawSpecies):gsub("%s*%[.*%]", ""):gsub("^%s+", ""):gsub("%s+$", "")
    local cleanSpecies = speciesName:gsub("[%s%p]", ""):lower()
    local mut = pd.MutationType or pd.Mutation or pd.Mutations or (type(itemData) == "table" and (itemData.Mutation or itemData.MutationString)) or ""
    local cleanMut = tostring(mut):gsub("[%s%p]", ""):lower()
    local weight = tonumber(pd.BaseWeight or pd.Weight or (type(itemData) == "table" and itemData.Weight)) or 0
    local age = tonumber(pd.Level or pd.Age or (type(itemData) == "table" and itemData.Age)) or 0
    local price = tonumber(li.Price) or tonumber(li.price) or tonumber(li.listingPrice) or tonumber(tostring(listInfo)) or 0

    return {
        Species = speciesName,
        CleanSpecies = cleanSpecies,
        Mutation = tostring(mut),
        CleanMutation = cleanMut,
        Weight = weight,
        Age = age,
        Price = price,
        PetData = pd
    }
end

local function executePurchase(ownerId, plrKey, listingUUID, listInfo, itemData, boothUUID, targetCleanName)
    local petInfo = extractPetInfo(itemData, listInfo)
    local price = petInfo and petInfo.Price or ((type(listInfo) == "table" and listInfo.Price) or tonumber(tostring(listInfo)) or 0)
    local petSpecies = petInfo and petInfo.Species or (itemData.PetType or (itemData.PetData and itemData.PetData.Name) or itemData.Name or "Pet")
    local itemId = (type(listInfo) == "table" and listInfo.ItemId) or listingUUID
    local petData = (petInfo and petInfo.PetData) or itemData.PetData or itemData

    print(string.format("[Sniper] 🛒 BUYING: %s | Price: %d Tokens | Seller: %s | Listing: %s", tostring(petSpecies), price, tostring(plrKey), tostring(listingUUID)))

    local buyRemote = nil
    pcall(function()
        buyRemote = ReplicatedStorage:WaitForChild("GameEvents", 3)
            :WaitForChild("TradeEvents", 3)
            :WaitForChild("Booths", 3)
            :WaitForChild("BuyListing", 3)
    end)

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
            task.wait(0.05)

            local playerGui = LocalPlayer and (LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 2))
            local buyGui = playerGui and playerGui:FindFirstChild("TradeBoothBuyItem")
            local yesBtn = buyGui and (buyGui:FindFirstChild("Yes", true) or buyGui:FindFirstChild("Confirm", true) or buyGui:FindFirstChild("Buy", true))
            if yesBtn then
                if firesignal then
                    firesignal(yesBtn.MouseButton1Click)
                    firesignal(yesBtn.Activated)
                end
                if getconnections then
                    for _, conn in ipairs(getconnections(yesBtn.MouseButton1Click)) do if conn.Fire then conn:Fire() end end
                    for _, conn in ipairs(getconnections(yesBtn.Activated)) do if conn.Fire then conn:Fire() end end
                end
            end
        end
    end)

    if buyRemote and not hasAcquiredNewTargetPet(targetCleanName) then
        pcall(function()
            buyRemote:InvokeServer(tostring(plrKey), tostring(listingUUID))
        end)
    end

    if buyRemote and not hasAcquiredNewTargetPet(targetCleanName) and ownerId then
        pcall(function()
            buyRemote:InvokeServer(tonumber(ownerId), tostring(listingUUID))
        end)
    end

    if buyRemote and not hasAcquiredNewTargetPet(targetCleanName) and boothUUID then
        pcall(function()
            buyRemote:InvokeServer(tostring(boothUUID), tostring(listingUUID))
        end)
    end
end

local function getBoothsData()
    local boothsData = nil

    pcall(function()
        local mod = ReplicatedStorage:FindFirstChild("Modules")
        local tbc = mod and mod:FindFirstChild("TradeBoothControllers")
        if tbc and tbc:FindFirstChild("TradeBoothListingController") then
            local listingCtrl = require(tbc.TradeBoothListingController)
            local dataService = debug.getupvalues(listingCtrl.GetInventory)[1]
            if dataService then
                boothsData = (dataService.GetDataAsync and dataService:GetDataAsync("Booths")) 
                          or (dataService.GetData and dataService:GetData("Booths")) 
                          or (dataService.GetData and dataService:GetData() and dataService:GetData().Booths)
            end
        end
    end)

    if not boothsData or not boothsData.Players then
        pcall(function()
            local dsMod = ReplicatedStorage:FindFirstChild("Modules") and ReplicatedStorage.Modules:FindFirstChild("DataService")
            if dsMod then
                local ds = require(dsMod)
                local fullData = ds and ds:GetData()
                if fullData and fullData.Booths then
                    boothsData = fullData.Booths
                elseif fullData and fullData.Players then
                    boothsData = fullData
                end
            end
        end)
    end

    return boothsData
end

local purchasedListings = {}

local function checkAndSnipe(activeTargets)
    local boothsData = getBoothsData()
    if not boothsData or not boothsData.Players then
        return false, 0
    end

    local playerToBoothUUID = {}
    if boothsData.Booths then
        for bUUID, bInfo in pairs(boothsData.Booths) do
            if type(bInfo) == "table" and bInfo.Owner then
                playerToBoothUUID[tostring(bInfo.Owner)] = tostring(bUUID)
            end
        end
    end

    local boughtInThisPass = 0

    for plrKey, plrData in pairs(boothsData.Players) do
        local ownerId = tonumber((tostring(plrKey):gsub("Player_", ""):gsub("player_", "")))
        local items = plrData.Items or {}
        local listings = plrData.Listings or {}

        for listingUUID, listInfo in pairs(listings) do
            local strListingUUID = tostring(listingUUID)
            if not purchasedListings[strListingUUID] then
                local itemId = (type(listInfo) == "table" and listInfo.ItemId) or listingUUID

                local itemData = items[itemId] or items[listingUUID]
                if not itemData then
                    local cleanItemId = tostring(itemId):gsub("[{}]", ""):lower()
                    for k, v in pairs(items) do
                        if tostring(k):gsub("[{}]", ""):lower() == cleanItemId then
                            itemData = v
                            break
                        end
                    end
                end

                local petInfo = extractPetInfo(itemData, listInfo)
                if petInfo and petInfo.Price > 0 then
                    for _, target in ipairs(activeTargets) do
                        local cleanTarget = target.CleanName
                        local isWildcard = (cleanTarget == "all" or cleanTarget == "allpets" or cleanTarget == "any" or cleanTarget == "*")
                        local isMatchingSpecies = isWildcard or (petInfo.CleanSpecies == cleanTarget) or (petInfo.CleanSpecies:find(cleanTarget, 1, true) ~= nil) or (cleanTarget:find(petInfo.CleanSpecies, 1, true) ~= nil)

                        if isMatchingSpecies and petInfo.Price <= target.MaxPrice then
                            local passesMutation = true
                            if target.Mutations and target.Mutations ~= "None" and target.Mutations ~= "" then
                                local cleanMutTarget = target.Mutations:gsub("[%s%p]", ""):lower()
                                if petInfo.CleanMutation == "" or (petInfo.CleanMutation ~= cleanMutTarget and not petInfo.CleanMutation:find(cleanMutTarget, 1, true)) then
                                    passesMutation = false
                                end
                            end

                            local passesWeight = true
                            if target.MaxWeight and target.MaxWeight > 0 then
                                if petInfo.Weight > target.MaxWeight then
                                    passesWeight = false
                                end
                            end

                            local passesAge = true
                            if target.MaxAge and target.MaxAge > 0 then
                                if petInfo.Age > target.MaxAge then
                                    passesAge = false
                                end
                            end

                            if passesMutation and passesWeight and passesAge then
                                print(string.format("[Sniper] 🎯 FOUND TARGET PET: %s for %d Tokens (MaxAllowed: %d)! Teleporting to booth and buying...", petInfo.Species, petInfo.Price, target.MaxPrice))

                                local boothUUID = playerToBoothUUID[tostring(plrKey)]
                                if boothUUID then
                                    interactWithBooth(boothUUID)
                                    task.wait(0.12)
                                end

                                executePurchase(ownerId, plrKey, listingUUID, listInfo, itemData or petInfo.PetData, boothUUID, target.CleanName)

                                local verified = false
                                for _ = 1, 6 do
                                    task.wait(0.20)
                                    if hasAcquiredNewTargetPet(target.CleanName) then
                                        print(string.format("[Sniper] ✅ Purchase Confirmed! Received new %s into inventory.", petInfo.Species))
                                        purchasedListings[strListingUUID] = true
                                        boughtInThisPass = boughtInThisPass + 1
                                        verified = true
                                        break
                                    end
                                end

                                if not verified then
                                    print("[Sniper] ⚠️ Purchase could not be verified on this listing. Continuing search...")
                                    purchasedListings[strListingUUID] = true
                                end

                                if not Config.BuyAllMatchesOnServer and verified then
                                    return true, boughtInThisPass
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return (boughtInThisPass > 0), boughtInThisPass
end

task.spawn(function()
    local targets = normalizeTargets(Config)
    if #targets == 0 then
        print("[Sniper] ⚠️ No valid target pets configured! Please check your Config.")
        return
    end

    local targetSummary = {}
    for _, t in ipairs(targets) do
        table.insert(targetSummary, string.format("%s (<= %dT, Mut: %s, Age: %d)", t.Name, t.MaxPrice, t.Mutations, t.MaxAge))
    end
    print(string.format("[Sniper] 🚀 Connected to server. Scanning for [%d] target(s): %s", #targets, table.concat(targetSummary, " | ")))

    local maxPasses = tonumber(Config.MaxScanPasses) or 5
    local passDelay = tonumber(Config.PassDelay) or 0.15
    local totalBought = 0

    for scanAttempt = 1, maxPasses do
        local ok, count = checkAndSnipe(targets)
        if count and count > 0 then
            totalBought = totalBought + count
            if not Config.BuyAllMatchesOnServer then
                break
            end
        end
        task.wait(passDelay)
    end

    local keepHopping = (Config.KeepHoppingAfterBuy == true) or (Config.ContinuousAFK == true) or (Config.InfiniteHop == true)

    if totalBought > 0 then
        if keepHopping then
            local hopDelay = tonumber(Config.HopDelayAfterBuy) or 1.5
            print(string.format("[Sniper] ✅ Successfully secured %d target pet(s)! Continuous AFK enabled: Hopping in %.1fs...", totalBought, hopDelay))
            task.wait(hopDelay)
            serverHop(targets)
        else
            print(string.format("[Sniper] 🎉 Successfully secured %d target pet(s)! Staying in server (Continuous AFK disabled).", totalBought))
        end
    else
        print("[Sniper] No matching target pet on current server. Finding next server...")
        serverHop(targets)
    end
end)
]=]

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

autoCollectAllToggle = Hub.CreateToggle(farmTab, "⚡ Auto Collect ALL", false, function(v)
    if type(v) == "boolean" then State.AutoCollectAll = v else State.AutoCollectAll = not State.AutoCollectAll end
end)

instantCollectAllToggle = Hub.CreateToggle(farmTab, "⚡ Instant Collect ALL", false, function(v)
    if type(v) == "boolean" then State.InstantCollectAll = v else State.InstantCollectAll = not State.InstantCollectAll end
end)

autoCollectFilteredToggle = Hub.CreateToggle(farmTab, "🌱 Auto Collect (Filtered)", false, function(v)
    if type(v) == "boolean" then State.AutoCollectFiltered = v else State.AutoCollectFiltered = not State.AutoCollectFiltered end
end)

collectStopWhenFullToggle = Hub.CreateToggle(farmTab, "Stop When Backpack Full", false, function(v)
    if type(v) == "boolean" then State.Collect_StopWhenFull = v else State.Collect_StopWhenFull = not State.Collect_StopWhenFull end
end)

collectVariantListObj = Hub.CreateList(farmTab, "Collect: Target Variant", variantItems, 160, false)
collectMutationListObj = Hub.CreateList(farmTab, "Collect: Target Mutation", mutationItems, 220, false)
collectFruitListObj = Hub.CreateList(farmTab, "Collect: Specific Fruit", buildGardenFruitCatalog(), 220, false)
collectCategoryListObj = Hub.CreateList(farmTab, "Collect: Fruit Category", categoryItems, 180, false)

collectWeightModeListObj = Hub.CreateList(farmTab, "Collect: Weight Mode", {
    {Name = "Above"},
    {Name = "Lower"}
}, 110, false)

Hub.CreateTextBox(farmTab, "Collect: Weight Multiplier", "Enter weight threshold (0 = inactive)", function(text)
    local num = tonumber(text)
    State.Collect_Weight = num or 0
end)

-- ==========================================
-- Section: Auto Plant
-- ==========================================

-- ==========================================
-- Section: Auto Reclaimer
-- ==========================================
Hub.CreateSection(farmTab, "🔄 Auto Reclaimer")

autoReclaimerToggle = Hub.CreateToggle(farmTab, "🔄 Auto Reclaimer", false, function(v)
    if type(v) == "boolean" then State.AutoReclaimer = v else State.AutoReclaimer = not State.AutoReclaimer end
end)

reclaimerPlantListObj = Hub.CreateList(farmTab, "Reclaimer: Target Plants (In Garden)", buildPlantsInGardenCatalog(), nil, false, true)

Hub.CreateButton(farmTab, "🔄 Refresh Garden Plants List", function()
    if reclaimerPlantListObj then
        local gardenPlants = buildPlantsInGardenCatalog()
        for _, entry in ipairs(gardenPlants) do
            safeAddToList(reclaimerPlantListObj, entry)
        end
    end
end)

Hub.CreateInput(farmTab, "Reclaimer Delay (s)", "0.5", "e.g. 0.5", function(text)
    local num = tonumber(text)
    if num and num > 0 then State.Reclaim_Delay = num end
end)

Hub.CreateButton(farmTab, "⚡ Reclaim One Selected Plant", function()
    local selectedNames = getUIListMultipleVals(reclaimerPlantListObj, "All Garden Plants")
    local plants = getMyGardenPlants()
    for _, plant in ipairs(plants) do
        local isMatch = false
        for _, sName in ipairs(selectedNames) do
            if sName == "All Garden Plants" or sName == plant.Name then
                isMatch = true
                break
            end
        end
        if isMatch then
            executeReclaimSinglePlant(plant)
            Hub.Notify({ Title = "Reclaimer", Content = "Reclaimed: " .. plant.Name, Duration = 2 })
            break
        end
    end
end)

-- ==========================================
-- Section: Auto Shovel
-- ==========================================
Hub.CreateSection(farmTab, "⛏️ Auto Shovel")

autoShovelToggle = Hub.CreateToggle(farmTab, "⛏️ Auto Shovel", false, function(v)
    if type(v) == "boolean" then State.AutoShovel = v else State.AutoShovel = not State.AutoShovel end
end)

shovelPlantListObj = Hub.CreateList(farmTab, "Shovel: Target Plants (In Garden)", buildPlantsInGardenCatalog(), nil, false, true)

Hub.CreateInput(farmTab, "Shovel Delay (s)", "0.5", "e.g. 0.5", function(text)
    local num = tonumber(text)
    if num and num > 0 then State.Shovel_Delay = num end
end)

Hub.CreateButton(farmTab, "⚡ Shovel One Selected Plant", function()
    local selectedNames = getUIListMultipleVals(shovelPlantListObj, "All Garden Plants")
    local plants = getMyGardenPlants()
    for _, plant in ipairs(plants) do
        local isMatch = false
        for _, sName in ipairs(selectedNames) do
            if sName == "All Garden Plants" or sName == plant.Name then
                isMatch = true
                break
            end
        end
        if isMatch then
            executeShovelSinglePlant(plant)
            Hub.Notify({ Title = "Auto Shovel", Content = "Shoveled: " .. plant.Name, Duration = 2 })
            break
        end
    end
end)

-- ==========================================
-- Section: Auto Watering
-- ==========================================
Hub.CreateSection(farmTab, "💧 Auto Watering (Watering Can)")

autoWateringToggle = Hub.CreateToggle(farmTab, "💧 Auto Watering", false, function(v)
    if type(v) == "boolean" then State.AutoWatering = v else State.AutoWatering = not State.AutoWatering end
end)

wateringPlantListObj = Hub.CreateList(farmTab, "Watering: Target Plants (Growing Only)", buildGrowingPlantsInGardenCatalog(), nil, false, true)

Hub.CreateButton(farmTab, "🔄 Refresh Growing Plants List", function()
    if wateringPlantListObj then
        local growingPlants = buildGrowingPlantsInGardenCatalog()
        for _, entry in ipairs(growingPlants) do
            safeAddToList(wateringPlantListObj, entry)
        end
    end
end)

Hub.CreateInput(farmTab, "Watering Delay (s)", "0.5", "e.g. 0.5", function(text)
    local num = tonumber(text)
    if num and num > 0 then State.Water_Delay = num end
end)

Hub.CreateSlider(farmTab, "Uses Per Delay", 1, 10, 3, " uses", function(val)
    State.Water_UsesPerDelay = val
end)

Hub.CreateButton(farmTab, "⚡ Water One Selected Plant (1-Use)", function()
    local selectedNames = getUIListMultipleVals(wateringPlantListObj, "All Growing Plants")
    local plants = getMyGardenPlants()
    for _, plant in ipairs(plants) do
        local info = getPlantGrowthInfo(plant)
        local isMatch = false
        for _, sName in ipairs(selectedNames) do
            if sName == "All Growing Plants" or sName == "All Garden Plants" or (info and sName == info.displayName) or sName == plant.Name then
                isMatch = true
                break
            end
        end
        if isMatch then
            executeWaterSinglePlant(plant, 1)
            Hub.Notify({ Title = "Watering", Content = "Watered: " .. (info and info.displayName or plant.Name), Duration = 2 })
            break
        end
    end
end)

Hub.CreateButton(farmTab, "⚡ Water All Garden Plants (1-Use)", function()
    local selectedNames = getUIListMultipleVals(wateringPlantListObj, "All Growing Plants")
    local plants = getMyGardenPlants()
    local wateredCount = 0
    for _, plant in ipairs(plants) do
        local info = getPlantGrowthInfo(plant)
        local isMatch = false
        for _, sName in ipairs(selectedNames) do
            if sName == "All Growing Plants" or sName == "All Garden Plants" or (info and sName == info.displayName) or sName == plant.Name then
                isMatch = true
                break
            end
        end
        if isMatch then
            executeWaterSinglePlant(plant, 1)
            wateredCount = wateredCount + 1
        end
    end
    Hub.Notify({ Title = "Watering", Content = "Watered " .. tostring(wateredCount) .. " plants!", Duration = 2 })
end)

Hub.CreateSection(farmTab, "🌱 Auto Plant")

autoPlantToggle = Hub.CreateToggle(farmTab, "🌱 Auto Plant", false, function(v)
    if type(v) == "boolean" then State.AutoPlant = v else State.AutoPlant = not State.AutoPlant end
end)

plantInOtherPlantsToggle = Hub.CreateToggle(farmTab, "🌱 Plant In Other Plants", false, function(v)
    if type(v) == "boolean" then State.PlantInOtherPlants = v else State.PlantInOtherPlants = not State.PlantInOtherPlants end
end)

plantSeedListObj = Hub.CreateList(farmTab, "Select Seed", seedListItems, 220, false)

plantPositionModeListObj = Hub.CreateList(farmTab, "Plant Position Mode", {
    {Name = "Player Position"},
    {Name = "Random Position"},
    {Name = "Existing Plant"},
    {Name = "Inside Other Plant"},
    {Name = "In Mid-Air (Above Player)"},
    {Name = "Out of Garden"},
    {Name = "Anywhere (Free Spatial)"}
}, 180, false)

Hub.CreateTextBox(farmTab, "Plant Delay (0.01 - 1.0s)", "Enter planting delay (default: 0.05)", function(text)
    local num = tonumber(text)
    if num then
        State.Plant_Delay = math.clamp(num, 0.01, 1.0)
    end
end)

-- ==========================================
-- Section: Sell Crops
-- ==========================================
Hub.CreateSection(farmTab, "💰 Sell Crops")

autoSellCropsToggle = Hub.CreateToggle(farmTab, "💰 Auto Sell (Crops)", false, function(v)
    if type(v) == "boolean" then State.AutoSellCrops = v else State.AutoSellCrops = not State.AutoSellCrops end
end)

sellWaitMaxToggle = Hub.CreateToggle(farmTab, "Wait Until Max Backpack", false, function(v)
    if type(v) == "boolean" then State.Sell_WaitMaxBackpack = v else State.Sell_WaitMaxBackpack = not State.Sell_WaitMaxBackpack end
end)

sellExcludeVariantListObj = Hub.CreateList(farmTab, "Sell: Exclude Variant", variantItems, 160, false)
sellExcludeMutationListObj = Hub.CreateList(farmTab, "Sell: Exclude Mutation", mutationItems, 220, false)
sellExcludeFruitListObj = Hub.CreateList(farmTab, "Sell: Exclude Specific Fruit", specificFruitItems, 220, false)
sellExcludeCategoryListObj = Hub.CreateList(farmTab, "Sell: Exclude Category", categoryItems, 180, false)

sellWeightModeListObj = Hub.CreateList(farmTab, "Sell: Exclude Weight Mode", {
    {Name = "Above"},
    {Name = "Lower"}
}, 110, false)

Hub.CreateTextBox(farmTab, "Sell: Exclude Weight Multiplier", "Enter weight threshold (0 = none)", function(text)
    local num = tonumber(text)
    State.Sell_Weight = num or 0
end)

-- ==========================================
-- Section: Pets Tab
-- ==========================================



-- 1. 🥚 Auto Place Eggs
Hub.CreateSection(petTab, "🥚 Auto Place Eggs")

autoPlaceEggsToggle = Hub.CreateToggle(petTab, "🥚 Auto Place Eggs", false, function(v)
    if type(v) == "boolean" then State.AutoPlaceEggs = v else State.AutoPlaceEggs = not State.AutoPlaceEggs end
end)

placeOnlyWhenNoEggToggle = Hub.CreateToggle(petTab, "Place Only When No Egg at Garden", false, function(v)
    if type(v) == "boolean" then State.PlaceOnlyWhenNoEgg = v else State.PlaceOnlyWhenNoEgg = not State.PlaceOnlyWhenNoEgg end
end)

placeEggSlotListObj = Hub.CreateList(petTab, "Auto Equip Slot (Place / Reduce Time)", slotListItems, 160, false, function(selected)
    local name = type(selected) == "table" and (selected.Name or selected[1]) or tostring(selected)
    State.PlaceEgg_EquipSlot = name
end)

placeEggListObj = Hub.CreateList(petTab, "Select Egg to Place", eggListItems, 220, false, { MultiSelect = true })

placeEggPositionModeListObj = Hub.CreateList(petTab, "Place Position Mode", {
    {Name = "Row Position"},
    {Name = "Player Position"}
}, 150, false, function(selected)
    local name = type(selected) == "table" and (selected.Name or selected[1]) or tostring(selected)
    State.PlaceEgg_PositionMode = name
end)

-- 2. 🐣 Auto Hatch Eggs
Hub.CreateSection(petTab, "🐣 Auto Hatch Eggs")

autoHatchEggsToggle = Hub.CreateToggle(petTab, "🐣 Auto Hatch Eggs", false, function(v)
    if type(v) == "boolean" then State.AutoHatchEggs = v else State.AutoHatchEggs = not State.AutoHatchEggs end
end)

waitAllEggsReadyToggle = Hub.CreateToggle(petTab, "Wait Until All Eggs Ready", false, function(v)
    if type(v) == "boolean" then State.WaitAllEggsReady = v else State.WaitAllEggsReady = not State.WaitAllEggsReady end
end)

hatchEggSlotListObj = Hub.CreateList(petTab, "Auto Equip Slot (Hatching Boost)", slotListItems, 160, false, function(selected)
    local name = type(selected) == "table" and (selected.Name or selected[1]) or tostring(selected)
    State.HatchEgg_EquipSlot = name
end)

Hub.CreateTextBox(petTab, "Hatch Slot Cooldown (s, min: 5)", "Cooldown after equipping slot (min: 5, default: 7.0)", function(text)
    local num = tonumber(text)
    if num then
        State.Hatch_SlotCooldown = math.clamp(math.max(5.0, num), 5.0, 60.0)
    else
        State.Hatch_SlotCooldown = 5.0
    end
end)

hatchEggListObj = Hub.CreateList(petTab, "Select Egg to Hatch", eggListItems, 220, false, { MultiSelect = true })

hatchExcludePetListObj = Hub.CreateList(petTab, "Exclude Pet if in Egg", petListItems, 220, false, true)

hatchExcludeWeightModeListObj = Hub.CreateList(petTab, "Hatch: Exclude Weight Mode", {
    {Name = "None"},
    {Name = "Above"},
    {Name = "Lower"}
}, 110, false, function(selected)
    local name = type(selected) == "table" and (selected.Name or selected[1]) or tostring(selected)
    State.Hatch_ExcludeWeightMode = name
end)

Hub.CreateTextBox(petTab, "Hatch: Exclude Weight (KG)", "Enter KG threshold (0 = none)", function(text)
    local num = tonumber(text)
    State.Hatch_ExcludeWeight = num or 0
end)

Hub.CreateButton(petTab, "🐣 Hatch All Ready Eggs Now", function()
    pcall(hatchAllReadyEggsNow)
end)

-- 3. 🐾 Auto Sell Pets
Hub.CreateSection(petTab, "🐾 Auto Sell Pets")

autoSellPetsToggle = Hub.CreateToggle(petTab, "🐾 Auto Sell Pets", false, function(v)
    if type(v) == "boolean" then State.AutoSellPets = v else State.AutoSellPets = not State.AutoSellPets end
end)

sellPetSlotListObj = Hub.CreateList(petTab, "Auto Equip Slot (Selling Boost)", slotListItems, 160, false, function(selected)
    local name = type(selected) == "table" and (selected.Name or selected[1]) or tostring(selected)
    State.Sell_EquipSlot = name
end)

Hub.CreateTextBox(petTab, "Sell Slot Cooldown (s, min: 3)", "Cooldown after equipping slot (min: 3, default: 5.0)", function(text)
    local num = tonumber(text)
    if num then
        State.Sell_SlotCooldown = math.clamp(math.max(3.0, num), 3.0, 60.0)
    else
        State.Sell_SlotCooldown = 5.0
    end
end)

sellTargetPetListObj = Hub.CreateList(petTab, "Pet: Select Pet to Sell", petListItems, 220, false, { MultiSelect = true })

sellExcludePetListObj = Hub.CreateList(petTab, "Pet: Exclude Pet from Selling", petListItems, 220, false, { MultiSelect = true })

sellExcludePetVariantListObj = Hub.CreateList(petTab, "Pet: Exclude Variant", variantItems, 160, false, function(selected)
    local name = type(selected) == "table" and (selected.Name or selected[1]) or tostring(selected)
    State.Sell_ExcludePetVariant = name
end)

sellExcludePetMutationListObj = Hub.CreateList(petTab, "Pet: Exclude Mutation", mutationItems, 220, false, function(selected)
    local name = type(selected) == "table" and (selected.Name or selected[1]) or tostring(selected)
    State.Sell_ExcludePetMutation = name
end)

sellExcludePetWeightModeListObj = Hub.CreateList(petTab, "Pet: Exclude Weight Mode", {
    {Name = "Above"},
    {Name = "Lower"}
}, 110, false, function(selected)
    local name = type(selected) == "table" and (selected.Name or selected[1]) or tostring(selected)
    State.Sell_ExcludePetWeightMode = name
end)

Hub.CreateTextBox(petTab, "Pet: Exclude Weight (KG)", "Enter KG cutoff (0 = none)", function(text)
    local num = tonumber(text)
    State.Sell_ExcludePetWeight = num or 0
end)

-- ==========================================
-- Section: Shop Tab (Eggs, Gears, Seeds, Cosmetics)
-- ==========================================

-- 1. 🥚 Egg Shop
Hub.CreateSection(shopTab, "🥚 Egg Shop")

autoBuySelectedEggToggle = Hub.CreateToggle(shopTab, "Auto Buy Selected (Egg)", false, function(v)
    if type(v) == "boolean" then State.AutoBuy_SelectedEgg = v else State.AutoBuy_SelectedEgg = not State.AutoBuy_SelectedEgg end
    if State.AutoBuy_SelectedEgg then task.spawn(executeInstantShopPurchases) end
end)

autoBuyAllEggsToggle = Hub.CreateToggle(shopTab, "Auto Buy ALL (Eggs)", false, function(v)
    if type(v) == "boolean" then State.AutoBuy_AllEggs = v else State.AutoBuy_AllEggs = not State.AutoBuy_AllEggs end
    if State.AutoBuy_AllEggs then task.spawn(executeInstantShopPurchases) end
end)

selectEggListObj = Hub.CreateList(shopTab, "Select Egg", eggListItems, 220, false)

-- 2. ⚙️ Gear Shop
Hub.CreateSection(shopTab, "⚙️ Gear Shop")

autoBuySelectedGearToggle = Hub.CreateToggle(shopTab, "Auto Buy Selected (Gear)", false, function(v)
    if type(v) == "boolean" then State.AutoBuy_SelectedGear = v else State.AutoBuy_SelectedGear = not State.AutoBuy_SelectedGear end
    if State.AutoBuy_SelectedGear then task.spawn(executeInstantShopPurchases) end
end)

autoBuyAllGearsToggle = Hub.CreateToggle(shopTab, "Auto Buy ALL (Gear)", false, function(v)
    if type(v) == "boolean" then State.AutoBuy_AllGears = v else State.AutoBuy_AllGears = not State.AutoBuy_AllGears end
    if State.AutoBuy_AllGears then task.spawn(executeInstantShopPurchases) end
end)

selectGearListObj = Hub.CreateList(shopTab, "Select Gear", gearListItems, 220, false)

-- 3. 🌱 Seed Shop
Hub.CreateSection(shopTab, "🌱 Seed Shop")

autoBuySelectedSeedToggle = Hub.CreateToggle(shopTab, "Auto Buy Selected (Seeds)", false, function(v)
    if type(v) == "boolean" then State.AutoBuy_SelectedSeed = v else State.AutoBuy_SelectedSeed = not State.AutoBuy_SelectedSeed end
    if State.AutoBuy_SelectedSeed then task.spawn(executeInstantShopPurchases) end
end)

autoBuyAllSeedsToggle = Hub.CreateToggle(shopTab, "Auto Buy ALL (Seeds)", false, function(v)
    if type(v) == "boolean" then State.AutoBuy_AllSeeds = v else State.AutoBuy_AllSeeds = not State.AutoBuy_AllSeeds end
    if State.AutoBuy_AllSeeds then task.spawn(executeInstantShopPurchases) end
end)

selectSeedShopListObj = Hub.CreateList(shopTab, "Select Seed", seedShopListItems, 220, false)

-- 4. 🎨 Cosmetics Shop
Hub.CreateSection(shopTab, "🎨 Cosmetics Shop")

autoBuySelectedCosmeticToggle = Hub.CreateToggle(shopTab, "Auto Buy Selected (Cosmetics)", false, function(v)
    if type(v) == "boolean" then State.AutoBuy_SelectedCosmetic = v else State.AutoBuy_SelectedCosmetic = not State.AutoBuy_SelectedCosmetic end
    if State.AutoBuy_SelectedCosmetic then task.spawn(executeInstantShopPurchases) end
end)

autoBuyAllCosmeticsToggle = Hub.CreateToggle(shopTab, "Auto Buy ALL (Cosmetics)", false, function(v)
    if type(v) == "boolean" then State.AutoBuy_AllCosmetics = v else State.AutoBuy_AllCosmetics = not State.AutoBuy_AllCosmetics end
    if State.AutoBuy_AllCosmetics then task.spawn(executeInstantShopPurchases) end
end)

selectCosmeticListObj = Hub.CreateList(shopTab, "Select Cosmetic", cosmeticListItems, 220, false)

-- 5. ⚙️ Auto Buy Speed Setting
Hub.CreateTextBox(shopTab, "Auto Buy Delay (0.01 - 1.0s)", "Enter loop interval (default: 0.01)", function(text)
    local num = tonumber(text)
    if num then
        State.Shop_BuyDelay = math.clamp(num, 0.005, 1.0)
    end
end)

-- 6. 🔨 Auto Crafting
Hub.CreateSection(shopTab, "🔨 Auto Crafting")

autoCraftPlantsToggle = Hub.CreateToggle(shopTab, "Auto Craft (Plants)", false, function(v)
    if type(v) == "boolean" then State.AutoCraft_Plants = v else State.AutoCraft_Plants = not State.AutoCraft_Plants end
    if State.AutoCraft_Plants then task.spawn(executeAutoCraftCycle) end
end)

selectCraftPlantListObj = Hub.CreateList(shopTab, "Select Plant to Craft", craftablePlantsListItems, 220, false, function(selected)
    local name = type(selected) == "table" and (selected.Name or selected[1]) or tostring(selected)
    State.AutoCraft_SelectedPlant = name
end)

autoCraftGearsToggle = Hub.CreateToggle(shopTab, "Auto Craft (Gears)", false, function(v)
    if type(v) == "boolean" then State.AutoCraft_Gears = v else State.AutoCraft_Gears = not State.AutoCraft_Gears end
    if State.AutoCraft_Gears then task.spawn(executeAutoCraftCycle) end
end)

selectCraftGearListObj = Hub.CreateList(shopTab, "Select Gear to Craft", craftableGearsListItems, 220, false, function(selected)
    local name = type(selected) == "table" and (selected.Name or selected[1]) or tostring(selected)
    State.AutoCraft_SelectedGear = name
end)

Hub.CreateTextBox(shopTab, "Craft Delay (0.05 - 5.0s)", "Enter loop interval (default: 0.5)", function(text)
    local num = tonumber(text)
    if num then
        State.AutoCraft_Delay = math.clamp(num, 0.05, 5.0)
    end
end)

Hub.CreateButton(shopTab, "📋 View Recipe Ingredients & Craft Status", function()
    pcall(function()
        local RS = game:GetService("ReplicatedStorage")
        local CraftingData = require(RS.Data.CraftingData)
        local ItemRecipes = (CraftingData.CraftingRecipeRegistry and CraftingData.CraftingRecipeRegistry.ItemRecipes) or CraftingData.ItemRecipes or CraftingData
        local DataService = require(RS.Modules.DataService)
        local playerData = DataService:GetData()
        local inv = playerData and playerData.InventoryData or {}

        local invCounts = {}
        for _, item in pairs(inv) do
            local name = item.ItemName or (item.ItemData and (item.ItemData.ItemName or item.ItemData.EggName)) or item.Name or "Unknown"
            local count = item.Quantity or (item.ItemData and item.ItemData.Uses) or 1
            invCounts[name] = (invCounts[name] or 0) + count
        end

        local chosenPlant = tostring(getUIListVal(selectCraftPlantListObj, State.AutoCraft_SelectedPlant))
        local chosenGear = tostring(getUIListVal(selectCraftGearListObj, State.AutoCraft_SelectedGear))

        local targetRecipeId = "None"
        local targetDisplayName = "None"

        if chosenPlant ~= "None" and chosenPlant ~= "" then
            targetDisplayName = chosenPlant
            for _, item in ipairs(allAvailableCraftPlants) do
                if item.Name == chosenPlant or item.BaseName == chosenPlant then
                    targetRecipeId = item.RecipeId
                    break
                end
            end
        elseif chosenGear ~= "None" and chosenGear ~= "" then
            targetDisplayName = chosenGear
            for _, item in ipairs(allAvailableCraftGears) do
                if item.Name == chosenGear or item.BaseName == chosenGear then
                    targetRecipeId = item.RecipeId
                    break
                end
            end
        end

        if targetRecipeId == "None" then
            Hub.Notify({ Title = "Craft Inspector", Content = "Please select a Plant or Gear recipe first!", Duration = 3 })
            return
        end

        local rec = ItemRecipes[targetRecipeId]
        if not rec then
            Hub.Notify({ Title = "Craft Inspector", Content = "Recipe data not found for " .. targetDisplayName, Duration = 3 })
            return
        end

        local missing = {}
        local ownedList = {}
        local canCraft = true

        for _, inp in ipairs(rec.Inputs or {}) do
            local reqName = inp.ItemData and inp.ItemData.ItemName or "Unknown"
            local reqAmount = inp.Quantity or (inp.ItemData and inp.ItemData.Quantity) or 1
            local owned = invCounts[reqName] or 0
            if owned < reqAmount then
                canCraft = false
                table.insert(missing, string.format("%s (Have: %d/%d)", reqName, owned, reqAmount))
            else
                table.insert(ownedList, string.format("%s (Have: %d/%d)", reqName, owned, reqAmount))
            end
        end

        local msg = ""
        if canCraft then
            msg = string.format("✅ Ready to Craft! All %d ingredients owned! Time: %ds", #(rec.Inputs or {}), rec.TimeToCraft or 0)
        else
            msg = string.format("❌ Missing: %s", table.concat(missing, ", "))
        end

        print(string.format("[Unknown Hub Craft Inspector] Recipe: %s | Status: %s | Ingredients: %s", targetRecipeId, canCraft and "READY" or "INCOMPLETE", table.concat(ownedList, ", ")))
        Hub.Notify({ Title = targetDisplayName, Content = msg, Duration = 6 })
    end)
end)

Hub.CreateButton(shopTab, "📖 Open Game Recipe Selection UI", function()
    pcall(function()
        local csh = require(ReplicatedStorage.Modules.CraftingStationHandler)
        local baseBench = Workspace.NPCS.CraftingTables:FindFirstChild("EventCraftingWorkBench") or Workspace.NPCS.CraftingTables:FindFirstChild("SeedEventCraftingWorkBench")
        if baseBench then
            local prompt = baseBench:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt and fireproximityprompt then
                fireproximityprompt(prompt)
            else
                local pGui = LocalPlayer.PlayerGui
                local rUi = pGui:FindFirstChild("RecipeSelection_UI")
                if rUi then rUi.Enabled = true end
            end
        end
    end)
end)

Hub.CreateButton(shopTab, "🛠️ Spawn Event Crafting Tables (Dino, Fairy, Smith, Bean)", function()
    pcall(function()
        local csh = require(ReplicatedStorage.Modules.CraftingStationHandler)
        local baseBench = Workspace.NPCS.CraftingTables:FindFirstChild("EventCraftingWorkBench") or Workspace.NPCS.CraftingTables:FindFirstChild("SeedEventCraftingWorkBench")
        if not baseBench then return end

        local eventBenches = {
            {name = "DinoEventCraftingWorkBench", cot = "DinoEventWorkbench", cid = "DinoEventWorkbench", offset = Vector3.new(6, 0, 0)},
            {name = "FairyEventCraftingWorkBench", cot = "FairyWorldCraftingWorkBench", cid = "FairyWorldCraftingWorkBench", offset = Vector3.new(12, 0, 0)},
            {name = "SmithingEventCraftingWorkBench", cot = "SmithingEventGearWorkbench", cid = "SmithingEventGearWorkbench", offset = Vector3.new(18, 0, 0)},
            {name = "GiantBeanstalkEventCraftingWorkBench", cot = "GiantBeanstalkEventWorkbench", cid = "GiantBeanstalkEventWorkbench", offset = Vector3.new(24, 0, 0)}
        }

        local count = 0
        for _, info in ipairs(eventBenches) do
            local existing = Workspace.NPCS.CraftingTables:FindFirstChild(info.name)
            if not existing then
                local clone = baseBench:Clone()
                clone.Name = info.name
                clone:SetAttribute("CraftingObjectType", info.cot)
                clone:SetAttribute("CraftingObjectId", info.cid)
                clone.Parent = Workspace.NPCS.CraftingTables
                clone:PivotTo(baseBench:GetPivot() * CFrame.new(info.offset))
                CollectionService:AddTag(clone, "CraftingObject")
                pcall(function() csh:SetupProximityPromptForCraftingStation(clone) end)
                count = count + 1
            end
        end
        Hub.Notify({ Title = "Crafting Tables", Content = "Spawned " .. tostring(count) .. " event workbenches!", Duration = 3 })
    end)
end)

-- ==========================================
-- Section: Events Tab (Fall Bloom, Event Shops, Acorn Chaos & Weekly Events)
-- ==========================================

-- 1. 🌸 Fall Bloom Automator
Hub.CreateSection(eventTab, "🌸 Fall Bloom Automator")

autoCollectFallBloomToggle = Hub.CreateToggle(eventTab, "Auto Collect Needed Fruit (Fall Bloom)", false, function(v)
    if type(v) == "boolean" then State.AutoCollect_FallBloomFruit = v else State.AutoCollect_FallBloomFruit = not State.AutoCollect_FallBloomFruit end
    if State.AutoCollect_FallBloomFruit then
        task.spawn(executeFallBloomCollectCycle)
    end
end)

autoSubmitFallBloomToggle = Hub.CreateToggle(eventTab, "Auto Submit Fruit to Fall Bloom", false, function(v)
    if type(v) == "boolean" then State.AutoSubmitFallBloom = v else State.AutoSubmitFallBloom = not State.AutoSubmitFallBloom end
    if State.AutoSubmitFallBloom then
        task.spawn(executeFallBloomSubmissionCycle)
    end
end)

Hub.CreateTextBox(eventTab, "Check Delay (0.25 - 10.0s)", "Enter check delay (default: 1.0)", function(text)
    local num = tonumber(text)
    if num then
        State.AutoSubmitFallBloom_Delay = math.clamp(num, 0.25, 10.0)
    end
end)







-- 2. 🍂 Fall Event Shops Auto-Buy
Hub.CreateSection(eventTab, "🍂 Fall Event Shops Auto-Buy")

autoBuyEventSeedsToggle = Hub.CreateToggle(eventTab, "Auto Buy Event Seeds", false, function(v)
    if type(v) == "boolean" then State.AutoBuy_EventSeeds = v else State.AutoBuy_EventSeeds = not State.AutoBuy_EventSeeds end
    if State.AutoBuy_EventSeeds then task.spawn(executeEventShopPurchases) end
end)

selectEventSeedListObj = Hub.CreateList(eventTab, "Select Event Seed", eventSeedListItems, 220, false, function(selected)
    local name = type(selected) == "table" and (selected.Name or selected[1]) or tostring(selected)
    State.AutoBuy_SelectedEventSeed = name
end)

autoBuyEventGearsToggle = Hub.CreateToggle(eventTab, "Auto Buy Event Gears", false, function(v)
    if type(v) == "boolean" then State.AutoBuy_EventGears = v else State.AutoBuy_EventGears = not State.AutoBuy_EventGears end
    if State.AutoBuy_EventGears then task.spawn(executeEventShopPurchases) end
end)

selectEventGearListObj = Hub.CreateList(eventTab, "Select Event Gear", eventGearListItems, 220, false, function(selected)
    local name = type(selected) == "table" and (selected.Name or selected[1]) or tostring(selected)
    State.AutoBuy_SelectedEventGear = name
end)

autoBuyEventPetsToggle = Hub.CreateToggle(eventTab, "Auto Buy Event Pets", false, function(v)
    if type(v) == "boolean" then State.AutoBuy_EventPets = v else State.AutoBuy_EventPets = not State.AutoBuy_EventPets end
    if State.AutoBuy_EventPets then task.spawn(executeEventShopPurchases) end
end)

selectEventPetListObj = Hub.CreateList(eventTab, "Select Event Pet", eventPetListItems, 220, false, function(selected)
    local name = type(selected) == "table" and (selected.Name or selected[1]) or tostring(selected)
    State.AutoBuy_SelectedEventPet = name
end)

autoBuyEventCosmeticsToggle = Hub.CreateToggle(eventTab, "Auto Buy Event Cosmetics", false, function(v)
    if type(v) == "boolean" then State.AutoBuy_EventCosmetics = v else State.AutoBuy_EventCosmetics = not State.AutoBuy_EventCosmetics end
    if State.AutoBuy_EventCosmetics then task.spawn(executeEventShopPurchases) end
end)

selectEventCosmeticListObj = Hub.CreateList(eventTab, "Select Event Cosmetic", eventCosmeticListItems, 220, false, function(selected)
    local name = type(selected) == "table" and (selected.Name or selected[1]) or tostring(selected)
    State.AutoBuy_SelectedEventCosmetic = name
end)

Hub.CreateTextBox(eventTab, "Event Shop Buy Delay (0.05 - 5.0s)", "Enter delay (default: 0.25)", function(text)
    local num = tonumber(text)
    if num then
        State.EventShop_BuyDelay = math.clamp(num, 0.05, 5.0)
    end
end)



-- 3. 🌰 Acorn Chaos (Weekly Event)
Hub.CreateSection(eventTab, "🌰 Acorn Chaos (Weekly Event)")

autoAttackAcornsToggle = Hub.CreateToggle(eventTab, "Auto Attack Acorns (Instant Crack)", false, function(v)
    if type(v) == "boolean" then State.AutoAttackAcorns = v else State.AutoAttackAcorns = not State.AutoAttackAcorns end
    if State.AutoAttackAcorns then
        if hasActiveAcorns() then
            equipShovelTool()
            task.spawn(crackAllActiveAcorns)
        end
    else
        unequipShovelTool()
    end
end)





-- ==========================================
-- Section: Misc Tab
-- ==========================================
Hub.CreateSection(miscTab, "🌿 Visual Optimization")

hidePlantsToggle = Hub.CreateToggle(miscTab, "🌾 Hide Plants", false, function(v)
    if type(v) == "boolean" then State.HidePlants = v else State.HidePlants = not State.HidePlants end
    pcall(updatePlantVisibility)
end)

hideFruitsToggle = Hub.CreateToggle(miscTab, "🍎 Hide Fruits", false, function(v)
    if type(v) == "boolean" then State.HideFruits = v else State.HideFruits = not State.HideFruits end
    pcall(updateFruitVisibility)
end)

-- ==========================================
-- Section: Infinite Sprinkler
-- ==========================================
Hub.CreateSection(miscTab, "💧 Infinite Sprinkler")

infiniteSprinklerToggle = Hub.CreateToggle(miscTab, "💧 Infinite Sprinkler", false, function(v)
    if type(v) == "boolean" then State.InfiniteSprinkler = v else State.InfiniteSprinkler = not State.InfiniteSprinkler end
    if State.InfiniteSprinkler then
        task.spawn(applyInfiniteSprinklerShovel)
    end
end)

selectSprinklerListObj = Hub.CreateList(miscTab, "Select Sprinkler to Shovel", sprinklerListItems, 220, false, true)

Hub.CreateButton(miscTab, "🧹 Shovel Active Sprinklers Now", function()
    pcall(shovelActiveSprinklers)
end)

-- ==========================================
-- Section: In-Game Products & Gamepasses
-- ==========================================
Hub.CreateSection(miscTab, "💎 Prompt Purchase (Dev Products & Gamepasses)")

-- Proactive screen blur clearing helper
local function clearScreenBlur()
    pcall(function()
        local mcMod = ReplicatedStorage:FindFirstChild("Modules") and ReplicatedStorage.Modules:FindFirstChild("MarketController")
        if mcMod then
            local mc = require(mcMod)
            if mc.ToggleScreenBlur then mc:ToggleScreenBlur(false) end
            if mc.ScreenBlur then
                mc.ScreenBlur.Enabled = false
                mc.ScreenBlur.Size = 0
            end
            if mc.CoverFrame then
                mc.CoverFrame.Visible = false
                mc.CoverFrame.BackgroundTransparency = 1
            end
            if mc.ScreenCover then
                mc.ScreenCover.Enabled = false
            end
        end
        local lighting = game:GetService("Lighting")
        for _, c in ipairs(lighting:GetChildren()) do
            if c:IsA("BlurEffect") then
                c.Enabled = false
                c.Size = 0
            end
        end
    end)
end

pcall(function()
    MarketplaceService.PromptProductPurchaseFinished:Connect(function() clearScreenBlur() end)
    MarketplaceService.PromptGamePassPurchaseFinished:Connect(function() clearScreenBlur() end)
    MarketplaceService.PromptPurchaseFinished:Connect(function() clearScreenBlur() end)
    MarketplaceService.PromptBundlePurchaseFinished:Connect(function() clearScreenBlur() end)
end)

local selectProductListObj = Hub.CreateList(miscTab, "Select Product / Gamepass", productListItems, 220, false)

-- Exact 1:1 product lookup table to prevent any product mismatch
local productExactMap = {}
for _, item in ipairs(allAvailableProducts) do
    if item.Name then
        productExactMap[item.Name] = item
        productExactMap[item.Name:lower()] = item
    end
    if item.RawName then
        productExactMap[item.RawName] = item
        productExactMap[item.RawName:lower()] = item
    end
    if item.DisplayName then
        productExactMap[item.DisplayName] = item
        productExactMap[item.DisplayName:lower()] = item
    end
end

-- Helper to find exact product details
local function findProductDetails(targetName)
    if not targetName or targetName == "" or targetName == "None" then
        return allAvailableProducts[1] or {Name = "[Gamepass] Harvest All", Id = 931892840, Price = 450, Robux = 450, Type = "Gamepass", Category = "Gamepass"}
    end
    if productExactMap[targetName] then
        return productExactMap[targetName]
    end
    if productExactMap[targetName:lower()] then
        return productExactMap[targetName:lower()]
    end
    for _, item in ipairs(allAvailableProducts) do
        if item.Name == targetName or item.Name:lower() == targetName:lower() then
            return item
        end
    end
    return allAvailableProducts[1]
end

-- Direct Prompt Purchase Action
Hub.CreateButton(miscTab, "💎 Prompt Purchase", function()
    local defaultName = (allAvailableProducts[1] and allAvailableProducts[1].Name) or "[Forever Pack] Tier 1 (39 R$)"
    local chosenProductName = tostring(getUIListVal(selectProductListObj, defaultName))
    local prodObj = findProductDetails(chosenProductName)

    local prodName = prodObj.Name or chosenProductName
    local prodId = tonumber(prodObj.Id) or 0
    local rawPrice = tonumber(prodObj.Price) or 0
    local prodPrice = rawPrice > 0 and rawPrice or 50
    local robuxPrice = tonumber(prodObj.Robux) or prodPrice
    local itemType = tostring(prodObj.Type or "Product")
    local itemCategory = tostring(prodObj.Category or "Product")
    local infoType = (itemType == "Gamepass" and Enum.InfoType.GamePass)
        or (itemType == "Bundle" and Enum.InfoType.Bundle)
        or (itemType == "Asset" and Enum.InfoType.Asset)
        or Enum.InfoType.Product

    if prodId <= 0 then
        if Hub.Notify then
            Hub.Notify({
                Title = "💎 Prompt Purchase",
                Content = string.format("Invalid Product ID for '%s'", prodName),
                Duration = 3
            })
        end
        return
    end

    print(string.format("[Unknown Hub] Prompting purchase for '%s' (ID: %d, Category: %s, Price: %d R$)...", prodName, prodId, itemCategory, robuxPrice))

    -- Trigger GAG's native MarketController:PromptPurchase
    -- 1. If tokens >= cost, GAG natively opens the payment selection dialog (Tokens vs Robux).
    -- 2. If tokens < cost, GAG natively opens the official Roblox purchase prompt.
    task.spawn(function()
        local executed = false
        pcall(function()
            local mcMod = ReplicatedStorage:FindFirstChild("Modules") and ReplicatedStorage.Modules:FindFirstChild("MarketController")
            if mcMod then
                local mc = require(mcMod)
                if mc.PromptPurchase then
                    mc:PromptPurchase(prodId, infoType)
                    executed = true
                elseif mc.PromptPurchaseRobux then
                    mc:PromptPurchaseRobux(prodId, infoType)
                    executed = true
                end
            end
        end)

        if not executed then
            pcall(function()
                if itemType == "Gamepass" then
                    MarketplaceService:PromptGamePassPurchase(LocalPlayer, prodId)
                elseif itemType == "Bundle" then
                    MarketplaceService:PromptBundlePurchase(LocalPlayer, prodId)
                elseif itemType == "Product" then
                    MarketplaceService:PromptProductPurchase(LocalPlayer, prodId)
                else
                    MarketplaceService:PromptPurchase(LocalPlayer, prodId)
                end
            end)
        end
    end)

    pcall(function()
        if Hub.Notify then
            Hub.Notify({
                Title = "💎 Prompt Purchase",
                Content = string.format("Prompting purchase for %s", prodName),
                Duration = 2.5
            })
        end
    end)
end)

Hub.CreateButton(miscTab, "🧹 Clear Screen Blur / Overlay", function()
    clearScreenBlur()
end)

end
buildAllUI()

print("[Unknown Hub] Grow a Garden (Auto Sell Pets & Complete Module) Loaded Successfully!")


-- =========================================================================
-- Auto Reclaimer Background Loop
-- =========================================================================
task.spawn(function()
    while true do
        if _G.GAG_SESSION ~= currentSession then break end
        if isToggleActive(autoReclaimerToggle, State.AutoReclaimer) then
            local delayTime = math.max(tonumber(State.Reclaim_Delay) or 0.5, 0.05)
            pcall(function()
                local selectedNames = getUIListMultipleVals(reclaimerPlantListObj, "All Garden Plants")
                local plants = getMyGardenPlants()
                for _, plant in ipairs(plants) do
                    if not isToggleActive(autoReclaimerToggle, State.AutoReclaimer) then break end
                    local isMatch = false
                    for _, sName in ipairs(selectedNames) do
                        if sName == "All Garden Plants" or sName == plant.Name then
                            isMatch = true
                            break
                        end
                    end
                    if isMatch then
                        executeReclaimSinglePlant(plant)
                        task.wait(delayTime)
                    end
                end
            end)
            task.wait(delayTime)
        else
            task.wait(0.5)
        end
    end
end)

-- =========================================================================
-- Auto Shovel Background Loop
-- =========================================================================
task.spawn(function()
    while true do
        if _G.GAG_SESSION ~= currentSession then break end
        if isToggleActive(autoShovelToggle, State.AutoShovel) then
            local delayTime = math.max(tonumber(State.Shovel_Delay) or 0.5, 0.05)
            pcall(function()
                local selectedNames = getUIListMultipleVals(shovelPlantListObj, "All Garden Plants")
                local plants = getMyGardenPlants()
                for _, plant in ipairs(plants) do
                    if not isToggleActive(autoShovelToggle, State.AutoShovel) then break end
                    local isMatch = false
                    for _, sName in ipairs(selectedNames) do
                        if sName == "All Garden Plants" or sName == plant.Name then
                            isMatch = true
                            break
                        end
                    end
                    if isMatch then
                        executeShovelSinglePlant(plant)
                        task.wait(delayTime)
                    end
                end
            end)
            task.wait(delayTime)
        else
            task.wait(0.5)
        end
    end
end)

-- =========================================================================
-- Auto Watering Background Loop
-- =========================================================================
task.spawn(function()
    while true do
        if _G.GAG_SESSION ~= currentSession then break end
        if isToggleActive(autoWateringToggle, State.AutoWatering) then
            local delayTime = math.max(tonumber(State.Water_Delay) or 0.5, 0.05)
            local uses = math.clamp(tonumber(State.Water_UsesPerDelay) or 3, 1, 20)
            pcall(function()
                local selectedNames = getUIListMultipleVals(wateringPlantListObj, "All Growing Plants")
                local plants = getMyGardenPlants()
                for _, plant in ipairs(plants) do
                    if not isToggleActive(autoWateringToggle, State.AutoWatering) then break end
                    local info = getPlantGrowthInfo(plant)
                    local isMatch = false
                    for _, sName in ipairs(selectedNames) do
                        if sName == "All Growing Plants" or sName == "All Garden Plants" then
                            if info and info.isGrowing then
                                isMatch = true
                                break
                            end
                        elseif info and sName == info.displayName then
                            isMatch = true
                            break
                        elseif sName == plant.Name then
                            isMatch = true
                            break
                        end
                    end
                    if isMatch then
                        executeWaterSinglePlant(plant, uses)
                        task.wait(delayTime)
                    end
                end
            end)
            task.wait(delayTime)
        else
            task.wait(0.5)
        end
    end
end)

-- =========================================================================
-- Dynamic Garden Listener & List Auto-Updater
-- =========================================================================
task.spawn(function()
    local isSyncing = false
    local lastSyncTick = 0

    local function syncGardenPlantLists()
        if isSyncing then return end
        if not (reclaimerPlantListObj or shovelPlantListObj or wateringPlantListObj or collectFruitListObj) then return end
        isSyncing = true

        pcall(function()
            local allPlants = buildPlantsInGardenCatalog()
            if reclaimerPlantListObj then
                for _, entry in ipairs(allPlants) do
                    safeAddToList(reclaimerPlantListObj, entry)
                end
            end
            if shovelPlantListObj then
                for _, entry in ipairs(allPlants) do
                    safeAddToList(shovelPlantListObj, entry)
                end
            end
            if collectFruitListObj then
                for _, entry in ipairs(allPlants) do
                    if entry ~= "All Garden Plants" then
                        safeAddToList(collectFruitListObj, entry)
                    end
                end
            end
            if wateringPlantListObj then
                local growingPlants = buildGrowingPlantsInGardenCatalog()
                for _, entry in ipairs(growingPlants) do
                    safeAddToList(wateringPlantListObj, entry)
                end
            end
        end)
        isSyncing = false
        lastSyncTick = tick()
    end

    local function debouncedSync()
        task.delay(0.5, function()
            if tick() - lastSyncTick >= 0.5 then
                syncGardenPlantLists()
            end
        end)
    end

    local hookedFolders = {}
    local function ensureFarmHooked()
        pcall(function()
            local farm = getPlayerFarm()
            local pPhys = farm and farm:FindFirstChild("Plants_Physical", true)
            if pPhys and not hookedFolders[pPhys] then
                hookedFolders[pPhys] = true
                pPhys.ChildAdded:Connect(function(child)
                    debouncedSync()
                end)
                pPhys.ChildRemoved:Connect(function(child)
                    debouncedSync()
                end)
                debouncedSync()
            end
        end)
    end

    ensureFarmHooked()

    -- Background Periodic Refresh every 20 seconds (lightweight fallback)
    while true do
        if _G.GAG_SESSION ~= currentSession then break end
        task.wait(20)
        ensureFarmHooked()
        syncGardenPlantLists()
    end
end)

-- =========================================================================
-- Acorn Chaos Event Listener & Background Auto Attack Engine
-- =========================================================================
task.spawn(function()
    local function hookAcornFolder(folder)
        if not folder then return end
        folder.ChildAdded:Connect(function(child)
            if isToggleActive(autoAttackAcornsToggle, State.AutoAttackAcorns) then
                task.spawn(function()
                    local id = child:GetAttribute("Id") or child:GetAttribute("AcornId") or child.Name
                    crackAcornById(id, child)
                    task.wait(0.05)
                    if not hasActiveAcorns() then
                        unequipShovelTool()
                    end
                end)
            end
        end)
    end

    local function bindAcornRemotes()
        local ge = ReplicatedStorage:FindFirstChild("GameEvents")
        local ac = ge and ge:FindFirstChild("AcornChaos")
        local startRem = ac and ac:FindFirstChild("Start")
        if startRem then
            startRem.OnClientEvent:Connect(function(data)
                if typeof(data) == "table" then
                    for _, entry in ipairs(data) do
                        if entry and entry.Id then
                            activeAcornIds[entry.Id] = entry
                            if isToggleActive(autoAttackAcornsToggle, State.AutoAttackAcorns) then
                                task.spawn(function()
                                    crackAcornById(entry.Id)
                                end)
                            end
                        end
                    end
                end
            end)
        end
        local rewardRem = ac and ac:FindFirstChild("Reward")
        if rewardRem then
            rewardRem.OnClientEvent:Connect(function(data)
                if typeof(data) == "table" and data.Id then
                    activeAcornIds[data.Id] = nil
                end
                if not hasActiveAcorns() then
                    unequipShovelTool()
                end
            end)
        end

        local acl = Workspace:FindFirstChild("AcornChaosLocal")
        if acl then
            hookAcornFolder(acl)
        end
        Workspace.ChildAdded:Connect(function(child)
            if child.Name == "AcornChaosLocal" then
                hookAcornFolder(child)
            end
        end)
    end
    pcall(bindAcornRemotes)

    while true do
        if _G.GAG_SESSION ~= currentSession then break end
        if isToggleActive(autoAttackAcornsToggle, State.AutoAttackAcorns) then
            pcall(function()
                if hasActiveAcorns() then
                    equipShovelTool()

                    for id, _ in pairs(activeAcornIds) do
                        if not isToggleActive(autoAttackAcornsToggle, State.AutoAttackAcorns) then break end
                        crackAcornById(id)
                    end

                    local acl = Workspace:FindFirstChild("AcornChaosLocal")
                    if acl then
                        for _, child in ipairs(acl:GetChildren()) do
                            if not isToggleActive(autoAttackAcornsToggle, State.AutoAttackAcorns) then break end
                            local id = child:GetAttribute("Id") or child:GetAttribute("AcornId") or child.Name
                            crackAcornById(id, child)
                        end
                    end
                else
                    unequipShovelTool()
                end
            end)
            task.wait(0.05)
        else
            task.wait(0.5)
        end
    end
end)
