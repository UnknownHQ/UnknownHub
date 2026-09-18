-- =========================================================================
-- Grow a Garden - Multi-Pet Sniper & Ultra-Fast Server Hopper
-- Place into your executor's Auto-Execute folder or execute directly.
-- =========================================================================

local Config = {
    -- =====================================================================
    -- TARGET PETS LIST (Option 1)
    -- Add as many pets as you want below! Just rename the values.
    -- =====================================================================
    Targets = {
        -- [Example 1] Any Bald Eagle under 50 tokens
        {
            Pet = "Bald Eagle",     -- Name of the target pet
            MaxPrice = 50,          -- Max price in Trade Tokens
            Mutations = "None",     -- "None" for any mutation, or e.g. "Rainbow", "Gold", "EV", "Ascended"
            MaxWeight = 0,          -- 0 = no weight limit, or enter max weight (e.g. 50)
            MaxAge = 0              -- 0 = no age/level limit, or enter max age (e.g. 100)
        },

        -- [Example 2] Any Koi under 31 tokens
        {
            Pet = "Koi",
            MaxPrice = 31,
            Mutations = "None",
            MaxWeight = 0,
            MaxAge = 0
        },

        -- [Example 3] Corrupted Kitsune (Rainbow mutation only)
        {
            Pet = "Corrupted Kitsune",
            MaxPrice = 150,
            Mutations = "Rainbow",
            MaxWeight = 0,
            MaxAge = 0
        },

        -- [Example 4] Empress Bee with max level/age cutoff
        {
            Pet = "Empress Bee",
            MaxPrice = 75,
            Mutations = "None",
            MaxWeight = 0,
            MaxAge = 100
        },

        -- [Example 5] Template to copy-paste for more pets:
        -- {
        --     Pet = "Pet Name Here",
        --     MaxPrice = 50,
        --     Mutations = "None",
        --     MaxWeight = 0,
        --     MaxAge = 0
        -- },
    },

    -- =====================================================================
    -- SCANNING SPEED & STABILITY SETTINGS
    -- =====================================================================
    MaxScanPasses = 5,              -- Number of replication passes per server before hopping (5 passes = ~1s)
    PassDelay = 0.20                -- Delay between replication passes in seconds (0.20s = blazing fast & stable)
}

-- =========================================================================
-- Execution Engine (Multi-Pet Detection, Sniping & Server Hop)
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
        task.wait(0.8)
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

-- Normalize configuration into structured targets
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
local function hasAcquiredNewTargetPet(targetCleanName)
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") then
                local uuid = tool:GetAttribute("PET_UUID") or tool:GetAttribute("UUID") or tool:GetAttribute("PetUUID")
                if uuid and not baselineInventoryUUIDs[tostring(uuid)] then
                    local pSpecies = tool:GetAttribute("f") or tool:GetAttribute("PetType") or tool.Name
                    if pSpecies and type(pSpecies) == "string" then
                        local clean = pSpecies:gsub("[%s%p]", ""):lower()
                        if not targetCleanName or clean == targetCleanName or clean:find(targetCleanName, 1, true) then
                            return true
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
                    local pSpecies = tool:GetAttribute("f") or tool:GetAttribute("PetType") or tool.Name
                    if pSpecies and type(pSpecies) == "string" then
                        local clean = pSpecies:gsub("[%s%p]", ""):lower()
                        if not targetCleanName or clean == targetCleanName or clean:find(targetCleanName, 1, true) then
                            return true
                        end
                    end
                end
            end
        end
    end
    return false
end

-- Teleport local player character directly in front of the target physical booth
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
                root.CFrame = pivot * CFrame.new(0, 0, 4)
            end

            local prompt = boothModel:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt then
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

local function executePurchase(ownerId, plrKey, listingUUID, listInfo, itemData, boothUUID, targetCleanName)
    local price = (type(listInfo) == "table" and listInfo.Price) or tonumber(tostring(listInfo)) or 0
    local petSpecies = itemData.PetType or (itemData.PetData and itemData.PetData.Name) or itemData.Name or "Pet"
    local itemId = (type(listInfo) == "table" and listInfo.ItemId) or listingUUID
    local petData = itemData.PetData or itemData

    print(string.format("[Sniper Debug] Executing purchase sequence for %s | SellerKey: %s | ListingUUID: %s | Price: %d", tostring(petSpecies), tostring(plrKey), tostring(listingUUID), price))

    local buyRemote = nil
    pcall(function()
        buyRemote = ReplicatedStorage:WaitForChild("GameEvents", 3)
            :WaitForChild("TradeEvents", 3)
            :WaitForChild("Booths", 3)
            :WaitForChild("BuyListing", 3)
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
            task.wait(0.04)

            local buyGui = LocalPlayer.PlayerGui:FindFirstChild("TradeBoothBuyItem")
            local yesBtn = buyGui and buyGui:FindFirstChild("Yes", true)
            if yesBtn and getconnections then
                for _, conn in ipairs(getconnections(yesBtn.Activated)) do
                    conn:Fire()
                end
            end
        end
    end)

    -- Method 2: Direct Remote invocation with string key Player_<Id>
    if buyRemote and not hasAcquiredNewTargetPet(targetCleanName) then
        local s, res = pcall(function()
            return buyRemote:InvokeServer(tostring(plrKey), tostring(listingUUID))
        end)
        print(string.format("[Sniper Debug] Direct BuyListing(string) result: success=%s, res=%s", tostring(s), tostring(res)))
    end

    -- Method 3: Direct Remote invocation with numeric UserId
    if buyRemote and not hasAcquiredNewTargetPet(targetCleanName) and ownerId then
        local s, res = pcall(function()
            return buyRemote:InvokeServer(tonumber(ownerId), tostring(listingUUID))
        end)
        print(string.format("[Sniper Debug] Direct BuyListing(number) result: success=%s, res=%s", tostring(s), tostring(res)))
    end
end

local function checkAndSnipe(activeTargets)
    local TradeBoothListingController = nil
    pcall(function()
        local mod = ReplicatedStorage:WaitForChild("Modules", 3)
        local tbc = mod and mod:WaitForChild("TradeBoothControllers", 3)
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

                if itemData and price > 0 then
                    local isPetItem = itemData.PetType or itemData.PetData or (type(listInfo) == "table" and listInfo.ItemType == "Pet")
                    local petSpecies = itemData.PetType or (itemData.PetData and itemData.PetData.Name) or (itemData.ItemType == "Pet" and itemData.Name)

                    if isPetItem and petSpecies and type(petSpecies) == "string" and petSpecies ~= "" then
                        local cleanSpecies = petSpecies:gsub("[%s%p]", ""):lower()

                        -- Check against all configured target pet rules
                        for _, target in ipairs(activeTargets) do
                            if cleanSpecies ~= "" and (cleanSpecies == target.CleanName or cleanSpecies:find(target.CleanName, 1, true)) then
                                if price <= target.MaxPrice then
                                    local petData = itemData.PetData or itemData

                                    -- Mutation filter
                                    local passesMutation = true
                                    if target.Mutations and target.Mutations ~= "None" and target.Mutations ~= "" then
                                        local cleanMutTarget = target.Mutations:gsub("[%s%p]", ""):lower()
                                        local mut = petData.MutationType or petData.Mutation or petData.Mutations or itemData.Mutation or itemData.MutationString or ""
                                        local cleanMut = tostring(mut):gsub("[%s%p]", ""):lower()
                                        if cleanMut == "" or (cleanMut ~= cleanMutTarget and not cleanMut:find(cleanMutTarget, 1, true)) then
                                            passesMutation = false
                                        end
                                    end

                                    -- Weight filter
                                    local passesWeight = true
                                    if target.MaxWeight and target.MaxWeight > 0 then
                                        local w = tonumber(petData.BaseWeight or petData.Weight or itemData.Weight) or 0
                                        if w > target.MaxWeight then
                                            passesWeight = false
                                        end
                                    end

                                    -- Age / Level filter
                                    local passesAge = true
                                    if target.MaxAge and target.MaxAge > 0 then
                                        local age = tonumber(petData.Level or petData.Age or itemData.Age) or 0
                                        if age > target.MaxAge then
                                            passesAge = false
                                        end
                                    end

                                    if passesMutation and passesWeight and passesAge then
                                        if not Players:GetPlayerByUserId(ownerId) then
                                            print("[Sniper] Seller left before purchase. Skipping...")
                                        else
                                            print(string.format("[Sniper] 🎯 FOUND TARGET PET: %s for %d Tokens (Seller: %s, MaxAllowed: %d)! Teleporting to booth and buying...", tostring(petSpecies), price, sellerPlr.Name, target.MaxPrice))

                                            -- 1. Teleport and interact with the seller's physical booth
                                            local boothUUID = playerToBoothUUID[tostring(plrKey)]
                                            if boothUUID then
                                                interactWithBooth(boothUUID)
                                                task.wait(0.12)
                                            end

                                            -- 2. Fire comprehensive purchase routines
                                            executePurchase(ownerId, plrKey, listingUUID, listInfo, itemData, boothUUID, target.CleanName)

                                            -- 3. Verify arrival of the new pet
                                            for _ = 1, 6 do
                                                task.wait(0.20)
                                                if hasAcquiredNewTargetPet(target.CleanName) then
                                                    print(string.format("[Sniper] ✅ Purchase Confirmed! Received new %s into inventory.", tostring(petSpecies)))
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
        end
    end

    return false
end

-- Run continuous multi-pass detection on load to guarantee 100% data replication
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
    local passDelay = tonumber(Config.PassDelay) or 0.20
    local targetSecured = false

    for scanAttempt = 1, maxPasses do
        targetSecured = checkAndSnipe(targets)
        if targetSecured then
            break
        end
        task.wait(passDelay)
    end

    if not targetSecured then
        print("[Sniper] No matching target pet found on this server. Hopping to next server...")
        serverHop()
    else
        print("[Sniper] 🎉 Target pet secured! Staying in server.")
    end
end)
