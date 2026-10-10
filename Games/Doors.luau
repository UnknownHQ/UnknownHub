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
-- State Configuration (ESP Only)
-- =========================================================================
local State = {
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
-- Precision Scanners (Doors, Keys, Items, Books, Breakers, Monsters)
-- =========================================================================

-- 1. Precision Door Scanner
local function processDoor(room, doorModel)
    if not doorModel or not doorModel:IsA("Model") then return end
    if not State.Doors_ESP then
        removeEspFor(doorModel)
        return
    end

    -- In DOORS:
    -- doorModel has invisible 'Collision' Part (5x8x1.25) that stretches wide and creates the giant box.
    -- The visible door leaf is MeshPart 'Door'!
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

    if isDupe then
        baseText = "⚠️ FAKE DOOR"
        color = Color3.fromRGB(255, 30, 30)
        table.insert(highlightParts, doorMesh)
    elseif isLocked then
        baseText = string.format("🚪 Door %s [LOCKED 🔒]", doorNumberStr)
        color = Color3.fromRGB(255, 175, 30)
        table.insert(highlightParts, doorMesh)
        if lockMesh and lockMesh:IsA("BasePart") then
            table.insert(highlightParts, lockMesh)
        end
    else
        baseText = string.format("🚪 Door %s", doorNumberStr)
        color = Color3.fromRGB(0, 215, 255)
        table.insert(highlightParts, doorMesh)
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
    -- KeyObtain has Hitbox (invisible 5.5x5.5x5.5 Part) and KeyHitbox (invisible 1.38x1.38x1.38 Part).
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

-- 3. Precision Item Scanner (Crucifix, Flashlight, Vitamins, etc.)
local KNOWN_ITEMS = {
    ["crucifix"] = "Crucifix",
    ["flashlight"] = "Flashlight",
    ["lighter"] = "Lighter",
    ["vitamins"] = "Vitamins",
    ["lockpick"] = "Lockpick",
    ["skeletonkey"] = "Skeleton Key",
    ["battery"] = "Battery",
    ["bandage"] = "Bandage",
    ["shears"] = "Shears",
    ["candle"] = "Candle",
    ["straplight"] = "Straplight",
    ["bulklight"] = "Bulklight",
    ["laser"] = "Laser Pointer"
}

local function processItem(itemModel)
    if not itemModel or not itemModel:IsA("Model") then return end
    if not State.Items_ESP then
        removeEspFor(itemModel)
        return
    end

    local iName = itemModel.Name:lower()
    local matchedName = nil
    for pattern, displayName in pairs(KNOWN_ITEMS) do
        if iName:find(pattern) and not iName:find("keyobtain") then
            matchedName = displayName
            break
        end
    end

    if matchedName then
        local targetPart = itemModel:FindFirstChild("Handle") or itemModel:FindFirstChildWhichIsA("MeshPart", true) or itemModel:FindFirstChildWhichIsA("BasePart", true)
        if targetPart then
            local baseText = "📦 " .. matchedName
            local color = Color3.fromRGB(185, 80, 255)
            registerEsp(itemModel, targetPart, baseText, color, "Items", targetPart, Vector3.new(0, 1.2, 0))
        end
    end
end

-- 4. Precision Books Scanner (ONLY in Room 50!)
local function processBook(room, bookInstance)
    if not State.Books_ESP then
        removeEspFor(bookInstance)
        return
    end

    -- Strict check: ONLY scan for hint books if we are in Room 50!
    -- This completely avoids false positives on decorative bookshelves in normal rooms!
    if room.Name ~= "50" and room:GetAttribute("RoomID") ~= 50 then
        return
    end

    if bookInstance.Name == "LiveHintBook" or bookInstance.Name == "HintBook" or bookInstance:GetAttribute("IsHintBook") then
        local targetPart = bookInstance:IsA("BasePart") and bookInstance or bookInstance:FindFirstChildWhichIsA("BasePart", true)
        if targetPart then
            local baseText = "📖 Library Book"
            local color = Color3.fromRGB(70, 255, 120)
            registerEsp(bookInstance, targetPart, baseText, color, "Books", targetPart, Vector3.new(0, 1.2, 0))
        end
    end
end

-- 5. Precision Breakers Scanner (ONLY in Room 100!)
local function processBreaker(room, breakerInstance)
    if not State.Breakers_ESP then
        removeEspFor(breakerInstance)
        return
    end

    if room.Name ~= "100" and room:GetAttribute("RoomID") ~= 100 then
        return
    end

    if breakerInstance.Name == "BreakerSwitch" or breakerInstance.Name == "LiveBreakerSwitch" or breakerInstance:GetAttribute("IsBreaker") then
        local targetPart = breakerInstance:IsA("BasePart") and breakerInstance or breakerInstance:FindFirstChildWhichIsA("BasePart", true)
        if targetPart then
            local baseText = "⚡ Breaker Switch"
            local color = Color3.fromRGB(0, 255, 200)
            registerEsp(breakerInstance, targetPart, baseText, color, "Breakers", targetPart, Vector3.new(0, 1.2, 0))
        end
    end
end

-- 6. Precision Hiding Spot Scanner (Wardrobes, Closets, Lockers, Beds)
local function processHidingSpot(hidingModel)
    if not hidingModel or not hidingModel:IsA("Model") then return end
    if not State.HidingSpots_ESP then
        removeEspFor(hidingModel)
        return
    end

    local hName = hidingModel.Name
    if hName == "Wardrobe" or hName == "Closet" or hName == "Locker" or hName:find("Bed") then
        local targetPart = hidingModel:FindFirstChild("Main") or hidingModel:FindFirstChildWhichIsA("MeshPart") or hidingModel.PrimaryPart or hidingModel:FindFirstChildWhichIsA("BasePart")
        if targetPart then
            local baseText = "🛡️ " .. hName
            local color = Color3.fromRGB(110, 195, 255)
            registerEsp(hidingModel, targetPart, baseText, color, "HidingSpots", hidingModel, Vector3.new(0, 2.5, 0))
        end
    end
end

-- 7. Precision Gold Scanner
local function processGold(goldModel)
    if not goldModel then return end
    if not State.Gold_ESP then
        removeEspFor(goldModel)
        return
    end

    if goldModel.Name == "GoldPile" or (goldModel:IsA("Model") and goldModel.Name:lower():find("gold")) then
        local targetPart = goldModel:FindFirstChildWhichIsA("MeshPart", true) or goldModel:FindFirstChildWhichIsA("BasePart", true)
        if targetPart then
            local baseText = "💰 Gold"
            local color = Color3.fromRGB(255, 185, 0)
            registerEsp(goldModel, targetPart, baseText, color, "Gold", targetPart, Vector3.new(0, 1.0, 0))
        end
    end
end

-- 8. Precision Entity Scanner (Rush, Ambush, Figure, Seek, Eyes, Halt, etc.)
local ENTITY_NAMES = {
    ["rushmoving"] = "Rush",
    ["ambushmoving"] = "Ambush",
    ["figurerig"] = "Figure",
    ["seekmoving"] = "Seek",
    ["eyes"] = "Eyes",
    ["halt"] = "Halt",
    ["screech"] = "Screech",
    ["giggleceiling"] = "Giggle",
    ["grumble"] = "Grumble"
}

local function processEntity(entityModel)
    if not entityModel or not entityModel:IsA("Model") then return end
    if not State.Entities_ESP then
        removeEspFor(entityModel)
        return
    end

    local eLower = entityModel.Name:lower()
    local matchedEntity = nil
    for key, name in pairs(ENTITY_NAMES) do
        if eLower:find(key) then
            matchedEntity = name
            break
        end
    end

    if matchedEntity then
        local targetPart = entityModel.PrimaryPart or entityModel:FindFirstChild("Root") or entityModel:FindFirstChild("Core") or entityModel:FindFirstChildWhichIsA("BasePart", true)
        if targetPart then
            local baseText = "💀 " .. matchedEntity
            local color = Color3.fromRGB(255, 30, 30)
            registerEsp(entityModel, targetPart, baseText, color, "Entities", entityModel, Vector3.new(0, 3.0, 0))
        end
    end
end

-- Full Room Parser
local function scanSingleRoom(room)
    if not room or not room:IsA("Model") then return end

    -- Door
    local door = room:FindFirstChild("Door")
    if door then processDoor(room, door) end

    -- Search room descendants
    for _, desc in ipairs(room:GetDescendants()) do
        if desc:IsA("Model") then
            if desc.Name == "KeyObtain" or desc:GetAttribute("IsKey") then
                processKey(desc)
            elseif desc.Name == "Wardrobe" or desc.Name == "Closet" or desc.Name == "Locker" or desc.Name:find("Bed") then
                processHidingSpot(desc)
            elseif desc.Name == "GoldPile" then
                processGold(desc)
            else
                processItem(desc)
            end
        end

        -- Check Book (Only in Room 50)
        if room.Name == "50" then
            processBook(room, desc)
        end

        -- Check Breaker (Only in Room 100)
        if room.Name == "100" then
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
    end
end

-- Listen for new rooms being generated dynamically
pcall(function()
    local currentRooms = Workspace:FindFirstChild("CurrentRooms") or Workspace:WaitForChild("CurrentRooms", 5)
    if currentRooms then
        currentRooms.ChildAdded:Connect(function(newRoom)
            task.wait(0.2)
            scanSingleRoom(newRoom)
        end)
    end
end)

-- Listen for entities entering Workspace
Workspace.ChildAdded:Connect(function(child)
    task.wait(0.05)
    if State.Entities_ESP then
        processEntity(child)
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
-- UI Tabs (ONLY ESP TAB AS REQUESTED)
-- =========================================================================
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
