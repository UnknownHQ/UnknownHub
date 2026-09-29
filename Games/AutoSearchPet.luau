-- =========================================================================
-- Grow a Garden - Multi-Pet Sniper & Ultra-Fast Server Hopper
-- Place into your executor's Auto-Execute folder or execute directly.
-- =========================================================================

local Config = {
    -- =====================================================================
    -- UNIVERSAL & AFK SETTINGS
    -- =====================================================================
    KeepHoppingAfterBuy = true,     -- true = Continuous AFK Hopper (never stops hopping, keeps buying & hopping)
                                    -- false = Stop and stay in server after buying target pet
    BuyAllMatchesOnServer = true,   -- true = Buys all matching pets available on current server before hopping
    HopDelayAfterBuy = 1.5,         -- Delay in seconds before hopping to next server after buying (allows inventory sync)

    -- =====================================================================
    -- TARGET PETS LIST
    -- Add as many pets as you want below! Just rename or add entries.
    -- Set Pet = "All Pets" or "Any" if you want to buy ANY pet under MaxPrice!
    -- =====================================================================
    Targets = {
        -- [Example 1] Any pet under 15 tokens (great for event egg farming & reselling)
        {
            Pet = "All Pets",       -- "All Pets" / "Any" buys ANY pet under MaxPrice
            MaxPrice = 15,          -- Max price in Trade Tokens
            Mutations = "None",     -- "None" for any mutation, or e.g. "Rainbow", "Gold", "EV", "Ascended"
            MaxWeight = 0,          -- 0 = no weight limit, or enter max weight (e.g. 50)
            MaxAge = 0              -- 0 = no age/level limit, or enter max age (e.g. 100)
        },

        -- [Example 2] Specific pet: Bald Eagle under 50 tokens
        {
            Pet = "Bald Eagle",     -- Name of the target pet
            MaxPrice = 50,          -- Max price in Trade Tokens
            Mutations = "None",     -- "None" for any mutation
            MaxWeight = 0,          -- 0 = no weight limit
            MaxAge = 0              -- 0 = no age/level limit
        },

        -- [Example 3] Specific pet: Koi under 31 tokens
        {
            Pet = "Koi",
            MaxPrice = 31,
            Mutations = "None",
            MaxWeight = 0,
            MaxAge = 0
        },

        -- [Example 4] Specific pet: Corrupted Kitsune (Rainbow mutation only)
        {
            Pet = "Corrupted Kitsune",
            MaxPrice = 150,
            Mutations = "Rainbow",
            MaxWeight = 0,
            MaxAge = 0
        },

        -- [Example 5] Specific pet: Empress Bee with max level/age cutoff
        {
            Pet = "Empress Bee",
            MaxPrice = 75,
            Mutations = "None",
            MaxWeight = 0,
            MaxAge = 100
        },
    },

    -- =====================================================================
    -- SCANNING SPEED & STABILITY SETTINGS
    -- =====================================================================
    MaxScanPasses = 6,              -- Number of replication passes per server before hopping
    PassDelay = 0.25                -- Delay between replication passes in seconds
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
while not LocalPlayer do
    LocalPlayer = Players.LocalPlayer
    task.wait(0.05)
end

local TRADING_PLAZA_PLACE_ID = 129954712878723
local httpRequest = request or http_request or (syn and syn.request) or (http and http.request) or (fluxus and fluxus.request) or (krnl and krnl.request)

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

-- Persistent visited servers memory across hops
local visitedServers = {}
pcall(function()
    if readfile and isfile and isfile("gag_visited_servers.json") then
        local content = readfile("gag_visited_servers.json")
        visitedServers = HttpService:JSONDecode(content) or {}
    end
end)
if type(visitedServers) ~= "table" then visitedServers = {} end
visitedServers[game.JobId] = tick()

-- Server Hop Implementation
local function serverHop()
    print("[Sniper] Hopping to a new server...")
    
    local now = tick()
    for jId, timestamp in pairs(visitedServers) do
        if type(timestamp) == "number" and (now - timestamp > 900) then
            visitedServers[jId] = nil
        end
    end
    visitedServers[game.JobId] = now
    pcall(function()
        if writefile then
            writefile("gag_visited_servers.json", HttpService:JSONEncode(visitedServers))
        end
    end)

    if httpRequest then
        local cursor = ""
        local validServers = {}

        for page = 1, 3 do
            local url = string.format("https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Desc&limit=100%s", 
                tostring(TRADING_PLAZA_PLACE_ID),
                (cursor ~= "" and ("&cursor=" .. cursor) or "")
            )

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
                        local id = s.id
                        if id and id ~= game.JobId and not visitedServers[id] and playing > 0 and playing <= (maxPlrs - 1) then
                            table.insert(validServers, id)
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

        if #validServers > 0 then
            local targetServer = validServers[math.random(1, #validServers)]
            print(string.format("[Sniper] Teleporting to new server %s (from %d candidates)...", tostring(targetServer), #validServers))
            
            visitedServers[targetServer] = now
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

    -- Fallback: standard matchmaking teleport
    print("[Sniper] Using standard matchmaking teleport...")
    pcall(function()
        TeleportService:Teleport(TRADING_PLAZA_PLACE_ID, LocalPlayer)
    end)
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

-- Helper to verify if a brand new target pet actually arrived in inventory
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
                        local pSpecies = tool:GetAttribute("f") or tool:GetAttribute("PetType") or tool.Name
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
                        local pSpecies = tool:GetAttribute("f") or tool:GetAttribute("PetType") or tool.Name
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

-- Teleport local player character directly in front of the target physical booth
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
            local char = LocalPlayer and (LocalPlayer.Character or (LocalPlayer.CharacterAdded and LocalPlayer.CharacterAdded:Wait()))
            local root = char and char:FindFirstChild("HumanoidRootPart")
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

-- Extract structured pet metadata from booth item data & listing info
local function extractPetInfo(itemData, listInfo)
    local pd = (type(itemData) == "table" and (itemData.PetData or itemData)) or {}
    local li = (type(listInfo) == "table" and listInfo) or {}

    local rawSpecies = pd.PetType or pd.Species or pd.Name or pd.f 
        or (type(itemData) == "table" and (itemData.PetType or itemData.ItemName or itemData.Name)) 
        or li.PetType or li.ItemName or li.Name

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

-- Purchase Routine
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

    -- Method 2: Direct Remote invocation with string plrKey
    if buyRemote and not hasAcquiredNewTargetPet(targetCleanName) then
        pcall(function()
            buyRemote:InvokeServer(tostring(plrKey), tostring(listingUUID))
        end)
    end

    -- Method 3: Direct Remote invocation with numeric ownerId
    if buyRemote and not hasAcquiredNewTargetPet(targetCleanName) and ownerId then
        pcall(function()
            buyRemote:InvokeServer(tonumber(ownerId), tostring(listingUUID))
        end)
    end

    -- Method 4: Direct Remote invocation with boothUUID
    if buyRemote and not hasAcquiredNewTargetPet(targetCleanName) and boothUUID then
        pcall(function()
            buyRemote:InvokeServer(tostring(boothUUID), tostring(listingUUID))
        end)
    end
end

-- Helper to safely acquire full Booths Data from DataService / Controller
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

    -- Build map of active claimed physical booths: playerKey -> boothUUID
    local playerToBoothUUID = {}
    if boothsData.Booths then
        for bUUID, bInfo in pairs(boothsData.Booths) do
            if type(bInfo) == "table" and bInfo.Owner then
                playerToBoothUUID[tostring(bInfo.Owner)] = tostring(bUUID)
            end
        end
    end

    local boughtInThisPass = 0

    -- Scan through all listings
    for plrKey, plrData in pairs(boothsData.Players) do
        local ownerId = tonumber((tostring(plrKey):gsub("Player_", ""):gsub("player_", "")))
        local items = plrData.Items or {}
        local listings = plrData.Listings or {}

        for listingUUID, listInfo in pairs(listings) do
            local strListingUUID = tostring(listingUUID)
            if not purchasedListings[strListingUUID] then
                local itemId = (type(listInfo) == "table" and listInfo.ItemId) or listingUUID

                -- Robust fuzzy item data lookup
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

    local maxPasses = tonumber(Config.MaxScanPasses) or 6
    local passDelay = tonumber(Config.PassDelay) or 0.25
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
            print(string.format("[Sniper] ✅ Successfully secured %d target pet(s)! Continuous AFK enabled: Hopping to next server in %.1fs...", totalBought, hopDelay))
            task.wait(hopDelay)
            serverHop()
        else
            print(string.format("[Sniper] 🎉 Successfully secured %d target pet(s)! Staying in server (Continuous AFK disabled).", totalBought))
        end
    else
        print("[Sniper] No matching target pet found on this server. Hopping to next server...")
        serverHop()
    end
end)
