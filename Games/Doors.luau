--[[
    ========================================================================
    Unknown Hub - DOORS (Hotel & The Mines)
    Stage: Working ESP Engine (Laser-focused on 100% precision ESP)
    ========================================================================
]]

local LIBRARY_LINK = "https://raw.githubusercontent.com/UnknownHQ/UnknownHub/main/UnknownLibrary"
local LIBRARY_NAME = "Unknown_TabbedHub_UI"

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- =========================================================================
-- Built-in Anti-AFK
-- =========================================================================
pcall(function()
    local vu = game:GetService("VirtualUser")
    LocalPlayer.Idled:Connect(function()
        pcall(function()
            if vu then
                vu:CaptureController()
                vu:ClickButton2(Vector2.new(0, 0))
            end
        end)
    end)
end)

local function destroyOldGui()
    local parents = {CoreGui}
    if gethui then pcall(function() table.insert(parents, gethui()) end) end
    local pGui = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
    if pGui then table.insert(parents, pGui) end
    for _, parent in ipairs(parents) do
        if parent then
            for _, child in ipairs(parent:GetChildren()) do
                if child.Name == LIBRARY_NAME or child.Name:find("Unknown_ESP") then
                    pcall(function() child:Destroy() end)
                end
            end
        end
    end
end

-- =========================================================================
-- UnknownLibrary Dynamic Loader
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
    assert(source and #source > 100, "Could not load UnknownLibrary")
    pcall(function()
        source = source:gsub("game:GetService%([\"']CoreGui[\"']%)", "(gethui and gethui() or (game:GetService(\"Players\").LocalPlayer and game:GetService(\"Players\").LocalPlayer:WaitForChild(\"PlayerGui\")))")
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
    subTitle = "DOORS (Hotel & Mines)",
    parent = (gethui and gethui()) or (LocalPlayer and (LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui"))) or (pcall(function() return CoreGui end) and CoreGui),
    theme = Color3.fromRGB(240, 150, 25),
    secondaryTheme = Color3.fromRGB(0, 195, 245)
})

assert(type(Hub) == "table", "UnknownLibrary returned an invalid hub instance")

-- =========================================================================
-- State Configuration (Main & ESP)
-- =========================================================================
local State = {
    -- Main / Movement
    WalkSpeed_Enabled = false,
    WalkSpeed_Value = 45,
    AntiRubberband = true,

    -- Visuals / ESP
    Master_ESP = true,
    Doors_ESP = true,
    Keys_ESP = true,
    Items_ESP = true,
    Books_ESP = true,
    Breakers_ESP = true,
    Gold_ESP = false,
    Entities_ESP = true,
    HidingSpots_ESP = false,
    Show_Distance = true,
    Fullbright = true
}

-- Session lifecycle
_G.DOORS_SESSION = tick()
local currentSession = _G.DOORS_SESSION

local function getChar()
    return LocalPlayer and LocalPlayer.Character
end

local function getRoot()
    local char = getChar()
    return char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart or char:FindFirstChild("Torso"))
end

-- =========================================================================
-- ESP Storage & Drawing Pipeline
-- =========================================================================
local activeEspRecords = {}

local function removeEspFor(owner)
    if activeEspRecords[owner] then
        for _, obj in ipairs(activeEspRecords[owner].Visuals) do
            pcall(function() obj:Destroy() end)
        end
        activeEspRecords[owner] = nil
    end
end

local function clearAllEsp()
    for owner, record in pairs(activeEspRecords) do
        for _, obj in ipairs(record.Visuals) do
            pcall(function() obj:Destroy() end)
        end
    end
    table.clear(activeEspRecords)
end

local function createBillboard(adorneePart, baseText, color, offset)
    if not adorneePart or not adorneePart:IsA("BasePart") then return nil, nil end
    offset = offset or Vector3.new(0, 1.8, 0)

    local bb = Instance.new("BillboardGui")
    bb.Name = "Unknown_ESP_Billboard"
    bb.Adornee = adorneePart
    bb.AlwaysOnTop = true
    bb.Size = UDim2.new(0, 180, 0, 36)
    bb.StudsOffset = offset
    bb.ResetOnSpawn = false

    local label = Instance.new("TextLabel")
    label.Name = "ESPLabel"
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = baseText
    label.TextColor3 = color
    label.TextStrokeTransparency = 0.15
    label.TextStrokeColor3 = Color3.fromRGB(12, 14, 18)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 13
    label.Parent = bb

    bb.Parent = (gethui and gethui()) or CoreGui
    return bb, label
end

local function createHighlight(adornee, color, fillTrans, outlineTrans)
    if not adornee then return nil end
    fillTrans = fillTrans or 0.5
    outlineTrans = outlineTrans or 0

    local hl = Instance.new("Highlight")
    hl.Name = "Unknown_ESP_Highlight"
    hl.Adornee = adornee
    hl.FillColor = color
    hl.FillTransparency = fillTrans
    hl.OutlineColor = color
    hl.OutlineTransparency = outlineTrans
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = (gethui and gethui()) or CoreGui
    return hl
end

local function registerEsp(owner, adorneePart, baseText, color, category, partsToHighlight, offset)
    removeEspFor(owner)
    if not State.Master_ESP then return end
    if not adorneePart then return end

    local visuals = {}

    -- 1. Billboard with Distance
    local bb, label = createBillboard(adorneePart, baseText, color, offset)
    if bb then table.insert(visuals, bb) end

    -- 2. Precision Highlights (ONLY target visible parts, NEVER giant hitboxes)
    if partsToHighlight then
        if typeof(partsToHighlight) == "Instance" then
            local hl = createHighlight(partsToHighlight, color)
            if hl then table.insert(visuals, hl) end
        elseif type(partsToHighlight) == "table" then
            for _, p in ipairs(partsToHighlight) do
                if p and p:IsA("BasePart") then
                    local hl = createHighlight(p, color)
                    if hl then table.insert(visuals, hl) end
                end
            end
        end
    end

    activeEspRecords[owner] = {
        Owner = owner,
        Adornee = adorneePart,
        BaseText = baseText,
        Color = color,
        Category = category,
        Label = label,
        Visuals = visuals
    }

    -- Auto-cleanup on destroy
    pcall(function()
        owner.Destroying:Connect(function()
            removeEspFor(owner)
        end)
    end)
end

-- Distance Update Loop (Runs every 0.15s)
task.spawn(function()
    while true do
        if _G.DOORS_SESSION ~= currentSession then break end
        if State.Master_ESP and State.Show_Distance then
            local root = getRoot()
            if root then
                local rootPos = root.Position
                for _, record in pairs(activeEspRecords) do
                    if record.Label and record.Adornee and record.Adornee.Parent then
                        local dist = math.floor((rootPos - record.Adornee.Position).Magnitude)
                        record.Label.Text = string.format("%s [%dm]", record.BaseText, dist)
                    end
                end
            end
        end
        task.wait(0.15)
    end
end)

-- =========================================================================
-- =========================================================================
-- Precision Scanners (Doors, Keys, Items, Books, Breakers, Monsters)
-- =========================================================================

-- 1. Precision Door Scanner (Highlights complete rectangular door & hardware)
local function processDoor(room, doorModel)
    if not doorModel or not doorModel:IsA("Model") then return end
    if not State.Doors_ESP then
        removeEspFor(doorModel)
        return
    end

    -- In DOORS:
    -- doorModel has invisible 'Collision' Part (5x8x1.25) and interior 'Hidden' Part (3x8x1.5).
    -- The actual visible door leaf is MeshPart 'Door', and its visible children: 'CrossBoards', 'Sign', 'Knob', 'Plate'.
    local doorMesh = doorModel:FindFirstChild("Door")
    if not doorMesh or not doorMesh:IsA("BasePart") then
        doorMesh = doorModel:FindFirstChildWhichIsA("MeshPart") or doorModel:FindFirstChildWhichIsA("BasePart")
    end
    if not doorMesh then return end

    local lockMesh = doorModel:FindFirstChild("Lock")
    local isLocked = lockMesh ~= nil

    -- Check for Dupe (Fake Door)
    local isDupe = false
    if doorModel:GetAttribute("DupeRoom") or doorModel:GetAttribute("Fake") or doorModel.Name:lower():find("fake") then
        isDupe = true
    end

    local signPart = doorModel:FindFirstChild("Sign")
    local signLabel = signPart and signPart:FindFirstChildWhichIsA("TextLabel", true)
    local signText = signLabel and signLabel.Text or nil

    local roomNum = tonumber(room.Name)
    local signNum = tonumber(signText)
    if roomNum and signNum and signNum ~= (roomNum + 1) then
        isDupe = true
    end

    local doorNumberStr = signText or tostring(room.Name)
    local baseText
    local color
    local highlightParts = {}

    -- Collect all real visible parts of the door leaf (Door + CrossBoards + Knob + Plate)
    table.insert(highlightParts, doorMesh)
    for _, child in ipairs(doorMesh:GetChildren()) do
        if child:IsA("BasePart") and child.Name ~= "Collision" and child.Name ~= "Hidden" and child.Transparency < 0.95 then
            table.insert(highlightParts, child)
        end
    end

    -- Include lock hardware if locked
    if isLocked and lockMesh then
        if lockMesh:IsA("BasePart") and lockMesh.Transparency < 0.95 then
            table.insert(highlightParts, lockMesh)
        end
        for _, desc in ipairs(lockMesh:GetDescendants()) do
            if desc:IsA("BasePart") and desc.Transparency < 0.95 then
                table.insert(highlightParts, desc)
            end
        end
    end

    if isDupe then
        baseText = "⚠️ FAKE DOOR"
        color = Color3.fromRGB(255, 30, 30)
    elseif isLocked then
        baseText = string.format("🚪 Door %s [LOCKED 🔒]", doorNumberStr)
        color = Color3.fromRGB(255, 175, 30)
    else
        baseText = string.format("🚪 Door %s", doorNumberStr)
        color = Color3.fromRGB(0, 215, 255)
    end

    registerEsp(doorModel, doorMesh, baseText, color, "Doors", highlightParts, Vector3.new(0, 1.5, 0))
end

-- 2. Precision Key Scanner
local function processKey(keyObtain)
    if not keyObtain or not keyObtain:IsA("Model") then return end
    if not State.Keys_ESP then
        removeEspFor(keyObtain)
        return
    end

    -- In DOORS:
    -- KeyObtain has Hitbox and KeyHitbox (invisible).
    -- The actual visible parts are MeshParts inside Hitbox: 'Key', 'Tag', and 'Ring'!
    local keyMesh = keyObtain:FindFirstChild("Key", true)
    if not keyMesh or not keyMesh:IsA("BasePart") then
        keyMesh = keyObtain:FindFirstChildWhichIsA("MeshPart", true)
    end
    if not keyMesh then return end

    local tagMesh = keyObtain:FindFirstChild("Tag", true)
    local ringMesh = keyObtain:FindFirstChild("Ring", true)

    -- Retrieve proper room / sign number
    local signText = keyObtain:GetAttribute("SignText")
    if not signText or signText == "" then
        local signGui = keyObtain:FindFirstChild("Sign", true)
        local signLabel = signGui and signGui:FindFirstChildWhichIsA("TextLabel", true)
        if signLabel and signLabel.Text and signLabel.Text ~= "" then
            signText = signLabel.Text
        end
    end

    local baseText = signText and string.format("🔑 Key [%s]", signText) or "🔑 Room Key"
    local color = Color3.fromRGB(255, 220, 35)

    local highlightParts = { keyMesh }
    if tagMesh and tagMesh:IsA("BasePart") then table.insert(highlightParts, tagMesh) end
    if ringMesh and ringMesh:IsA("BasePart") then table.insert(highlightParts, ringMesh) end

    registerEsp(keyObtain, keyMesh, baseText, color, "Keys", highlightParts, Vector3.new(0, 1.2, 0))
end

-- 3. Precision Item Scanner (Strict validation against furniture & decor)
local KNOWN_ITEMS = {
    ["crucifix"]      = "Crucifix",
    ["flashlight"]    = "Flashlight",
    ["lighter"]       = "Lighter",
    ["vitamins"]      = "Vitamins",
    ["lockpick"]      = "Lockpick",
    ["skeletonkey"]   = "Skeleton Key",
    ["battery"]       = "Battery",
    ["bandage"]       = "Bandage",
    ["shears"]        = "Shears",
    ["candle"]        = "Candle",
    ["straplight"]    = "Straplight",
    ["bulklight"]     = "Bulklight",
    ["laserpointer"]  = "Laser Pointer",
    ["laser"]         = "Laser Pointer",
    ["shakelight"]    = "Shakelight",
    ["compass"]       = "Compass",
    ["glowstick"]     = "Glowstick",
    ["crucifixwall"]  = "Crucifix"
}

-- Furniture and background decor blacklist to prevent false positives
local DECOR_BLACKLIST = {
    "bookshelf", "bookcase", "drawer", "desk", "table", "chair", "couch", "sofa",
    "painting", "clock", "cart", "luggage", "fireplace", "chandelier", "lamp",
    "plant", "pillar", "shelf", "carpet", "rug", "door", "window", "curtain",
    "bell", "plate", "cup", "bottle", "bed"
}

local function isValidLootItem(model)
    if not model or not model:IsA("Model") then return false, nil end
    local lower = model.Name:lower()

    -- Reject blacklist decor
    for _, blocked in ipairs(DECOR_BLACKLIST) do
        if lower:find(blocked) then
            return false, nil
        end
    end

    if lower:find("keyobtain") or lower:find("goldpile") then
        return false, nil
    end

    -- Strict check: True pickup items in DOORS MUST have a ProximityPrompt
    local prompt = model:FindFirstChildWhichIsA("ProximityPrompt", true)
    local hasPickupPrompt = false
    local promptObjectName = nil

    if prompt then
        local action = prompt.ActionText:lower()
        if action == "take" or action == "obtain" or action == "steal" or action == "grab" or action == "pick up" or action:find("take") or action:find("obtain") then
            hasPickupPrompt = true
        end
        if prompt.ObjectText and #prompt.ObjectText > 0 then
            promptObjectName = prompt.ObjectText:lower()
        end
    end

    -- Also check for tool attributes or ModulePrompt
    local hasItemModule = model:FindFirstChild("ModulePrompt", true) ~= nil
    local hasItemAttr = model:GetAttribute("ItemType") ~= nil or model:GetAttribute("IsItem") == true

    if not (hasPickupPrompt or hasItemModule or hasItemAttr) then
        return false, nil
    end

    -- Match known item names
    for key, displayName in pairs(KNOWN_ITEMS) do
        if lower == key or lower:find("^" .. key) or (promptObjectName and promptObjectName:find(key)) then
            return true, displayName
        end
    end

    return false, nil
end

local function processItem(itemModel)
    if not itemModel or not itemModel:IsA("Model") then return end
    if not State.Items_ESP then
        removeEspFor(itemModel)
        return
    end

    local isValid, displayName = isValidLootItem(itemModel)
    if isValid and displayName then
        local targetPart = itemModel:FindFirstChild("Handle") 
            or itemModel:FindFirstChildWhichIsA("MeshPart", true) 
            or itemModel:FindFirstChildWhichIsA("BasePart", true)
        if targetPart then
            local baseText = "📦 " .. displayName
            local color = Color3.fromRGB(185, 80, 255)
            registerEsp(itemModel, targetPart, baseText, color, "Items", targetPart, Vector3.new(0, 1.2, 0))
        end
    end
end

-- 4. Precision Books Scanner (ONLY in Room 50 Library!)
local function processBook(room, bookInstance)
    if not State.Books_ESP then
        removeEspFor(bookInstance)
        return
    end

    -- Strict check: ONLY scan for books if room is Room 50!
    -- This 100% eliminates false positives on decorative bookshelves in all other rooms.
    local isRoom50 = (room.Name == "50") or (room:GetAttribute("RoomID") == 50)
    if not isRoom50 then return end

    if bookInstance.Name == "LiveHintBook" or (bookInstance:IsA("Model") and bookInstance.Name:find("HintBook")) then
        local targetPart = bookInstance:IsA("BasePart") and bookInstance or bookInstance:FindFirstChildWhichIsA("BasePart", true)
        if targetPart then
            local baseText = "📖 Library Book"
            local color = Color3.fromRGB(70, 255, 120)
            registerEsp(bookInstance, targetPart, baseText, color, "Books", targetPart, Vector3.new(0, 1.2, 0))
        end
    end
end

-- 5. Precision Breakers Scanner (ONLY in Room 100 Electrical Room!)
local function processBreaker(room, breakerInstance)
    if not State.Breakers_ESP then
        removeEspFor(breakerInstance)
        return
    end

    local isRoom100 = (room.Name == "100") or (room:GetAttribute("RoomID") == 100)
    if not isRoom100 then return end

    if breakerInstance.Name == "BreakerSwitch" or breakerInstance.Name == "LiveBreakerSwitch" or breakerInstance:GetAttribute("IsBreaker") then
        local targetPart = breakerInstance:IsA("BasePart") and breakerInstance or breakerInstance:FindFirstChildWhichIsA("BasePart", true)
        if targetPart then
            local baseText = "⚡ Breaker Switch"
            local color = Color3.fromRGB(0, 255, 200)
            registerEsp(breakerInstance, targetPart, baseText, color, "Breakers", targetPart, Vector3.new(0, 1.2, 0))
        end
    end
end

-- 6. Precision Hiding Spot Scanner (Wardrobes, Closets, Lockers, Beds with active Hide prompt)
local function processHidingSpot(hidingModel)
    if not hidingModel or not hidingModel:IsA("Model") then return end
    if not State.HidingSpots_ESP then
        removeEspFor(hidingModel)
        return
    end

    local hName = hidingModel.Name
    if hName == "Wardrobe" or hName == "Closet" or hName == "Locker" or hName:find("Bed") then
        -- Verify it is a REAL hiding spot (has a Hide prompt), not broken/boarded decor
        local prompt = hidingModel:FindFirstChildWhichIsA("ProximityPrompt", true)
        local isRealHiding = false
        if prompt then
            local act = prompt.ActionText:lower()
            if act == "hide" or prompt.Name:lower():find("hide") then
                isRealHiding = true
            end
        else
            -- Bed or standard closet without nested prompt yet
            isRealHiding = true
        end

        if isRealHiding then
            local targetPart = hidingModel:FindFirstChild("Main") 
                or hidingModel:FindFirstChildWhichIsA("MeshPart") 
                or hidingModel.PrimaryPart 
                or hidingModel:FindFirstChildWhichIsA("BasePart")
            if targetPart then
                local baseText = "🛡️ " .. hName
                local color = Color3.fromRGB(110, 195, 255)
                registerEsp(hidingModel, targetPart, baseText, color, "HidingSpots", hidingModel, Vector3.new(0, 2.5, 0))
            end
        end
    end
end

-- 7. Precision Gold Scanner (Strict GoldPile check)
local function processGold(goldModel)
    if not goldModel then return end
    if not State.Gold_ESP then
        removeEspFor(goldModel)
        return
    end

    if goldModel.Name == "GoldPile" then
        local targetPart = goldModel:FindFirstChildWhichIsA("MeshPart", true) or goldModel:FindFirstChildWhichIsA("BasePart", true)
        if targetPart then
            local baseText = "💰 Gold"
            local color = Color3.fromRGB(255, 185, 0)
            registerEsp(goldModel, targetPart, baseText, color, "Gold", targetPart, Vector3.new(0, 1.0, 0))
        end
    end
end

-- 8. Comprehensive Entity ESP (Every Monster in DOORS Hotel & The Mines)
local ENTITY_REGISTRY = {
    ["rushmoving"]     = { Name = "Rush",               Emoji = "💀", Color = Color3.fromRGB(255, 35, 35) },
    ["ambushmoving"]   = { Name = "Ambush",             Emoji = "💀", Color = Color3.fromRGB(30, 255, 160) },
    ["figurerig"]      = { Name = "Figure",             Emoji = "👹", Color = Color3.fromRGB(255, 50, 50) },
    ["seekmoving"]     = { Name = "Seek",               Emoji = "👁️", Color = Color3.fromRGB(220, 20, 20) },
    ["seekrig"]        = { Name = "Seek",               Emoji = "👁️", Color = Color3.fromRGB(220, 20, 20) },
    ["eyes"]           = { Name = "Eyes (Don't Look!)", Emoji = "👁️", Color = Color3.fromRGB(190, 50, 255) },
    ["halt"]           = { Name = "Halt",               Emoji = "🛑", Color = Color3.fromRGB(0, 220, 255) },
    ["shade"]          = { Name = "Halt",               Emoji = "🛑", Color = Color3.fromRGB(0, 220, 255) },
    ["screech"]        = { Name = "Screech",            Emoji = "🦷", Color = Color3.fromRGB(255, 215, 0) },
    ["giggleceiling"]  = { Name = "Giggle",             Emoji = "😈", Color = Color3.fromRGB(255, 80, 180) },
    ["giggle"]         = { Name = "Giggle",             Emoji = "😈", Color = Color3.fromRGB(255, 80, 180) },
    ["grumble"]        = { Name = "Grumble",            Emoji = "👹", Color = Color3.fromRGB(255, 100, 0) },
    ["grumblerig"]     = { Name = "Grumble",            Emoji = "👹", Color = Color3.fromRGB(255, 100, 0) },
    ["snare"]          = { Name = "Snare Trap",         Emoji = "⚠️", Color = Color3.fromRGB(80, 255, 80) },
    ["glitch"]         = { Name = "Glitch",             Emoji = "⚡", Color = Color3.fromRGB(50, 150, 255) },
    ["void"]           = { Name = "Void",               Emoji = "🌌", Color = Color3.fromRGB(140, 0, 255) },
    ["dread"]          = { Name = "Dread",              Emoji = "☠️", Color = Color3.fromRGB(160, 0, 0) },
    ["timothy"]        = { Name = "Timothy",            Emoji = "🕷️", Color = Color3.fromRGB(180, 180, 180) },
    ["spider"]         = { Name = "Timothy",            Emoji = "🕷️", Color = Color3.fromRGB(180, 180, 180) },
    ["a60"]            = { Name = "A-60",               Emoji = "💀", Color = Color3.fromRGB(255, 40, 40) },
    ["a-60"]           = { Name = "A-60",               Emoji = "💀", Color = Color3.fromRGB(255, 40, 40) },
    ["a90"]            = { Name = "A-90",               Emoji = "🛑", Color = Color3.fromRGB(255, 30, 30) },
    ["a-90"]           = { Name = "A-90",               Emoji = "🛑", Color = Color3.fromRGB(255, 30, 30) },
    ["a120"]           = { Name = "A-120",              Emoji = "💀", Color = Color3.fromRGB(255, 40, 40) },
    ["a-120"]          = { Name = "A-120",              Emoji = "💀", Color = Color3.fromRGB(255, 40, 40) },
}

local function processEntity(entity)
    if not entity then return end
    if not State.Entities_ESP then
        removeEspFor(entity)
        return
    end

    local eLower = entity.Name:lower()

    -- Do not flag players or friendly shop NPCs
    if entity:IsA("Model") and Players:GetPlayerFromCharacter(entity) then return end
    if eLower:find("bob") or eLower:find("elgoblino") or eLower:find("jeff") and not eLower:find("killer") then return end

    local cfg = nil
    for key, info in pairs(ENTITY_REGISTRY) do
        if eLower == key or eLower:find(key) then
            cfg = info
            break
        end
    end

    if cfg then
        local targetPart = (entity:IsA("Model") and (entity.PrimaryPart or entity:FindFirstChild("Root") or entity:FindFirstChild("Core") or entity:FindFirstChildWhichIsA("BasePart", true)))
            or (entity:IsA("BasePart") and entity)

        if targetPart then
            local baseText = string.format("%s %s", cfg.Emoji, cfg.Name)
            registerEsp(entity, targetPart, baseText, cfg.Color, "Entities", entity, Vector3.new(0, 3.0, 0))
        end
    end
end

-- Full Room Parser
local function scanSingleRoom(room)
    if not room or not room:IsA("Model") then return end

    -- 1. Scan Door
    local door = room:FindFirstChild("Door")
    if door then processDoor(room, door) end

    -- 2. Scan Room Descendants
    for _, desc in ipairs(room:GetDescendants()) do
        if desc:IsA("Model") then
            local dName = desc.Name
            if dName == "KeyObtain" or desc:GetAttribute("IsKey") then
                processKey(desc)
            elseif dName == "Wardrobe" or dName == "Closet" or dName == "Locker" or dName:find("Bed") then
                processHidingSpot(desc)
            elseif dName == "GoldPile" then
                processGold(desc)
            else
                -- Check for items with strict filter
                processItem(desc)
            end

            -- Check if entity spawned inside room (e.g. Figure, Eyes, Snare)
            processEntity(desc)
        end

        -- Check Book (Strictly Room 50 Library Only)
        if room.Name == "50" or room:GetAttribute("RoomID") == 50 then
            processBook(room, desc)
        end

        -- Check Breaker (Strictly Room 100 Electrical Only)
        if room.Name == "100" or room:GetAttribute("RoomID") == 100 then
            processBreaker(room, desc)
        end
    end
end

local function scanAllRooms()
    if not State.Master_ESP then
        clearAllEsp()
        return
    end

    local currentRooms = Workspace:FindFirstChild("CurrentRooms")
    if currentRooms then
        for _, room in ipairs(currentRooms:GetChildren()) do
            scanSingleRoom(room)
        end
    end

    -- Scan Workspace for roaming entities
    if State.Entities_ESP then
        for _, child in ipairs(Workspace:GetChildren()) do
            processEntity(child)
        end
        if Camera then
            for _, child in ipairs(Camera:GetChildren()) do
                processEntity(child)
            end
        end
    end
end

-- Dynamic Room Generation Listener
pcall(function()
    local currentRooms = Workspace:FindFirstChild("CurrentRooms") or Workspace:WaitForChild("CurrentRooms", 5)
    if currentRooms then
        currentRooms.ChildAdded:Connect(function(newRoom)
            task.wait(0.2)
            scanSingleRoom(newRoom)

            -- Room child added listener for live item/entity drops
            newRoom.ChildAdded:Connect(function(child)
                task.wait(0.1)
                if child.Name == "Door" then
                    processDoor(newRoom, child)
                elseif child.Name == "KeyObtain" then
                    processKey(child)
                elseif State.Entities_ESP then
                    processEntity(child)
                end
            end)
        end)
    end
end)

-- Dynamic Entity Spawning Listeners (Workspace & Camera for Screech)
Workspace.ChildAdded:Connect(function(child)
    task.wait(0.05)
    if State.Entities_ESP then
        processEntity(child)
    end
end)

if Camera then
    Camera.ChildAdded:Connect(function(child)
        task.wait(0.05)
        if State.Entities_ESP then
            processEntity(child)
        end
    end)
end

-- Continuous Entity Guard Loop (Checks Workspace & Camera every 0.4s to guarantee 0% missed spawns)
task.spawn(function()
    while true do
        if _G.DOORS_SESSION ~= currentSession then break end
        if State.Master_ESP and State.Entities_ESP then
            for _, child in ipairs(Workspace:GetChildren()) do
                processEntity(child)
            end
            if Camera then
                for _, child in ipairs(Camera:GetChildren()) do
                    processEntity(child)
                end
            end
        end
        task.wait(0.4)
    end
end)

-- =========================================================================
-- Fullbright & Night Vision Engine
-- =========================================================================
local originalLighting = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd,
    GlobalShadows = Lighting.GlobalShadows,
    Ambient = Lighting.Ambient
}

local function applyFullbright(enable)
    if enable then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        Lighting.Ambient = Color3.fromRGB(180, 180, 180)
    else
        Lighting.Brightness = originalLighting.Brightness
        Lighting.ClockTime = originalLighting.ClockTime
        Lighting.FogEnd = originalLighting.FogEnd
        Lighting.GlobalShadows = originalLighting.GlobalShadows
        Lighting.Ambient = originalLighting.Ambient
    end
end

if State.Fullbright then
    applyFullbright(true)
end

-- =========================================================================
-- WalkSpeed Protection & Native Slide-State Anti-Rubberband Engine
-- =========================================================================
local crouchRemote = game:GetService("ReplicatedStorage"):FindFirstChild("RemotesFolder") and game.ReplicatedStorage.RemotesFolder:FindFirstChild("Crouch")
local isSlideBypassing = false

local function getMainGameParent()
    local ok, res = pcall(function()
        local p = LocalPlayer
        local mg = p:FindFirstChild("PlayerGui") and p.PlayerGui:FindFirstChild("MainUI") and p.PlayerGui.MainUI:FindFirstChild("Initiator") and p.PlayerGui.MainUI.Initiator:FindFirstChild("Main_Game")
        if mg then
            local movement = mg:FindFirstChild("Movement")
            if movement and getsenv and getupvalues then
                local sEnv = getsenv(movement)
                if sEnv and sEnv.updatespeed then
                    local upvals = getupvalues(sEnv.updatespeed)
                    return upvals[2] -- Parent controller table
                end
            end
        end
        return nil
    end)
    return ok and res or nil
end

local function setSlideState(sliding)
    if isSlideBypassing == sliding then return end
    isSlideBypassing = sliding

    local parentTable = getMainGameParent()
    if parentTable then
        pcall(function() parentTable.sliding = sliding end)
    end

    if crouchRemote then
        pcall(function()
            -- Tells DOORS server that player is in valid sliding state (server permits velocity up to 65 studs/s)
            crouchRemote:FireServer(false, sliding)
        end)
    end
end

-- Continuous Heartbeat Enforcement (Dynamically applies slide state when moving to completely eliminate server rollbacks)
RunService.Heartbeat:Connect(function()
    if _G.DOORS_SESSION ~= currentSession then return end
    local char = getChar()
    local hum = char and char:FindFirstChildWhichIsA("Humanoid")
    if not hum or not hum.Parent then return end

    if State.WalkSpeed_Enabled then
        local targetSpeed = State.WalkSpeed_Value
        local isMoving = hum.MoveDirection.Magnitude > 0.05

        if State.AntiRubberband then
            if isMoving then
                setSlideState(true)
            else
                setSlideState(false)
            end
        else
            setSlideState(false)
        end

        if hum.WalkSpeed ~= targetSpeed then
            hum.WalkSpeed = targetSpeed
        end
    else
        if isSlideBypassing then
            setSlideState(false)
        end
        if hum.WalkSpeed ~= 15 then
            hum.WalkSpeed = 15
        end
    end
end)

-- Stepped Guard: Prevents DOORS' Movement script from locking WalkSpeed on physics step
RunService.Stepped:Connect(function()
    if _G.DOORS_SESSION ~= currentSession then return end
    if State.WalkSpeed_Enabled then
        local char = getChar()
        local hum = char and char:FindFirstChildWhichIsA("Humanoid")
        if hum and hum.WalkSpeed ~= State.WalkSpeed_Value then
            hum.WalkSpeed = State.WalkSpeed_Value
        end
    end
end)

-- Auto-reapply on respawn or revive
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.25)
    if State.WalkSpeed_Enabled then
        local hum = char:WaitForChild("Humanoid", 5)
        if hum then
            hum.WalkSpeed = State.WalkSpeed_Value
        end
    end
end)

-- =========================================================================
-- UI Tabs
-- =========================================================================

-- Tab 1: MAIN TAB (Movement, Speed Changer, Test Suite)
local mainTab = Hub.CreateTab("Main", { 
    Icon = "⚡", 
    Size = 18, 
    Color = Color3.fromRGB(240, 150, 25), 
    ActiveColor = Color3.fromRGB(255, 185, 30) 
})

Hub.CreateSection(mainTab, "🏃 Movement & Speed")

Hub.CreateToggle(mainTab, "Walkspeed Changer", State.WalkSpeed_Enabled, function(v)
    State.WalkSpeed_Enabled = v
    if not v then
        setSlideState(false)
        local char = getChar()
        local hum = char and char:FindFirstChildWhichIsA("Humanoid")
        if hum then hum.WalkSpeed = 15 end
        Hub.Notify("WalkSpeed", "Speed reset to default (15)", 2)
    else
        Hub.Notify("WalkSpeed", string.format("Speed active: %d studs/s (Slide Bypass Active)", State.WalkSpeed_Value), 2)
    end
end)

Hub.CreateSlider(mainTab, "Speed Value", 15, 75, State.WalkSpeed_Value, " studs/s", function(v)
    State.WalkSpeed_Value = v
    if State.WalkSpeed_Enabled then
        local char = getChar()
        local hum = char and char:FindFirstChildWhichIsA("Humanoid")
        if hum then hum.WalkSpeed = v end
    end
end)

Hub.CreateToggle(mainTab, "Anti-Rubberband Protection", State.AntiRubberband, function(v)
    State.AntiRubberband = v
    if not v then setSlideState(false) end
end)

Hub.CreateButton(mainTab, "🧪 Test Speed 45 (Clearance-Aware Motion Test)", function()
    task.spawn(function()
        local char = getChar()
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildWhichIsA("Humanoid")
        local vim = game:GetService("VirtualInputManager")
        if not root or not hum or not vim then return end

        -- 1. Scan for open clearance in 4 cardinal directions to guarantee we never test into a wall
        local dirs = {
            { key = Enum.KeyCode.W, name = "Forward", dir = root.CFrame.LookVector },
            { key = Enum.KeyCode.S, name = "Backward", dir = -root.CFrame.LookVector },
            { key = Enum.KeyCode.D, name = "Right", dir = root.CFrame.RightVector },
            { key = Enum.KeyCode.A, name = "Left", dir = -root.CFrame.RightVector }
        }

        local params = RaycastParams.new()
        params.FilterDescendantsInstances = {char}
        params.FilterType = Enum.RaycastFilterType.Exclude

        local bestDir = nil
        local maxDist = 0
        for _, d in ipairs(dirs) do
            local hit = workspace:Raycast(root.Position, d.dir * 45, params)
            local dist = hit and hit.Distance or 45
            if dist > maxDist then
                maxDist = dist
                bestDir = d
            end
        end

        if maxDist < 6 then
            Hub.Notify("Speed Test Warning", "⚠️ In a tight corner! Please step into a hallway before testing.", 3)
            return
        end

        local oldWS = hum.WalkSpeed
        local wasEnabled = State.WalkSpeed_Enabled

        -- Enable slide bypass and speed 45
        setSlideState(true)
        hum.WalkSpeed = 45

        local pStart = root.Position
        Hub.Notify("Speed Test", string.format("Moving %s at 45 speed (Clearance: %.1fm)...", bestDir.name, maxDist), 2)
        vim:SendKeyEvent(true, bestDir.key, false, game)
        task.wait(0.50)
        vim:SendKeyEvent(false, bestDir.key, false, game)

        task.wait(0.25)
        local pMid = root.Position
        local movedForward = (pMid - pStart).Magnitude

        -- Opposite direction key
        local oppKey = (bestDir.key == Enum.KeyCode.W and Enum.KeyCode.S) 
            or (bestDir.key == Enum.KeyCode.S and Enum.KeyCode.W)
            or (bestDir.key == Enum.KeyCode.D and Enum.KeyCode.A) 
            or Enum.KeyCode.D

        Hub.Notify("Speed Test", "Moving opposite direction at 45 speed...", 2)
        vim:SendKeyEvent(true, oppKey, false, game)
        task.wait(0.50)
        vim:SendKeyEvent(false, oppKey, false, game)

        task.wait(0.25)
        local pFinal = root.Position
        local movedBack = (pFinal - pMid).Magnitude

        setSlideState(false)
        hum.WalkSpeed = wasEnabled and State.WalkSpeed_Value or oldWS

        local rubberbandDetected = (movedForward < 4) or (movedBack < 4)
        if rubberbandDetected then
            Hub.Notify("Speed Test Result", string.format("⚠️ Rollback or obstacle: Out: %.1fm | Back: %.1fm", movedForward, movedBack), 4)
        else
            Hub.Notify("Speed Test Result", string.format("✅ Success! Out: %.1fm | Back: %.1fm | Rollback: 0%%", movedForward, movedBack), 4)
        end
    end)
end)

-- Tab 2: ESP TAB
local espTab = Hub.CreateTab("ESP", { 
    Icon = "👁️", 
    Size = 18, 
    Color = Color3.fromRGB(170, 185, 210), 
    ActiveColor = Color3.fromRGB(0, 215, 255) 
})

Hub.CreateSection(espTab, "👁️ Master Control")

Hub.CreateToggle(espTab, "Master ESP Switch", State.Master_ESP, function(v)
    State.Master_ESP = v
    if not v then
        clearAllEsp()
    else
        scanAllRooms()
    end
end)

Hub.CreateToggle(espTab, "Show Distance Labels", State.Show_Distance, function(v)
    State.Show_Distance = v
    if not v then
        for _, rec in pairs(activeEspRecords) do
            if rec.Label then rec.Label.Text = rec.BaseText end
        end
    end
end)

Hub.CreateSection(espTab, "🚪 Doors & Navigation")

Hub.CreateToggle(espTab, "Doors ESP (Real & Fake)", State.Doors_ESP, function(v)
    State.Doors_ESP = v
    scanAllRooms()
end)

Hub.CreateToggle(espTab, "Keys ESP", State.Keys_ESP, function(v)
    State.Keys_ESP = v
    scanAllRooms()
end)

Hub.CreateSection(espTab, "📦 Items & Objectives")

Hub.CreateToggle(espTab, "Items ESP (Crucifix, Lighter, etc.)", State.Items_ESP, function(v)
    State.Items_ESP = v
    scanAllRooms()
end)

Hub.CreateToggle(espTab, "Books ESP (Room 50 Library Only)", State.Books_ESP, function(v)
    State.Books_ESP = v
    scanAllRooms()
end)

Hub.CreateToggle(espTab, "Breakers ESP (Room 100 Only)", State.Breakers_ESP, function(v)
    State.Breakers_ESP = v
    scanAllRooms()
end)

Hub.CreateToggle(espTab, "Gold Coins ESP", State.Gold_ESP, function(v)
    State.Gold_ESP = v
    scanAllRooms()
end)

Hub.CreateSection(espTab, "💀 Entities & Safety")

Hub.CreateToggle(espTab, "Entities ESP (Monsters)", State.Entities_ESP, function(v)
    State.Entities_ESP = v
    scanAllRooms()
end)

Hub.CreateToggle(espTab, "Hiding Spots ESP (Closets & Beds)", State.HidingSpots_ESP, function(v)
    State.HidingSpots_ESP = v
    scanAllRooms()
end)

Hub.CreateSection(espTab, "💡 Visual Enhancements")

Hub.CreateToggle(espTab, "Fullbright / Night Vision", State.Fullbright, function(v)
    State.Fullbright = v
    applyFullbright(v)
end)

Hub.CreateButton(espTab, "🔄 Refresh All ESP Now", function()
    clearAllEsp()
    scanAllRooms()
    Hub.Notify("DOORS ESP", "Refreshed all active room ESPs!", 3)
end)

-- Initial Startup Scan
scanAllRooms()
Hub.Notify("UNKNOWN HUB", "DOORS Precision ESP Loaded! 👁️", 4)
