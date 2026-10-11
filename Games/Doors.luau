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
            for _, desc in ipairs(parent:GetDescendants()) do
                if desc.Name == LIBRARY_NAME or desc.Name:find("Unknown_ESP") then
                    pcall(function() desc:Destroy() end)
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
    bb.Size = UDim2.new(0, 180, 0, 32)
    bb.StudsOffset = offset
    bb.ResetOnSpawn = false

    local label = Instance.new("TextLabel")
    label.Name = "ESPLabel"
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = color
    label.TextStrokeTransparency = 0.45
    label.TextStrokeColor3 = Color3.fromRGB(15, 15, 20)
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.Parent = bb

    local initialText = baseText
    if State.Show_Distance then
        local root = getRoot()
        if root then
            local dist = math.floor((root.Position - adorneePart.Position).Magnitude)
            initialText = string.format("%s [%dm]", baseText, dist)
        end
    end
    label.Text = initialText

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
    if not State.Master_ESP then return end
    if not adorneePart then return end

    -- Anti-flicker guard: if already registered, do NOT destroy and recreate visuals
    local existing = activeEspRecords[owner]
    if existing and existing.Adornee == adorneePart and existing.Category == category then
        if existing.BaseText ~= baseText or existing.Color ~= color then
            existing.BaseText = baseText
            existing.Color = color
            if existing.Label then
                existing.Label.TextColor3 = color
                local root = getRoot()
                if root and State.Show_Distance then
                    local dist = math.floor((root.Position - adorneePart.Position).Magnitude)
                    existing.Label.Text = string.format("%s [%dm]", baseText, dist)
                else
                    existing.Label.Text = baseText
                end
            end
        end
        return
    end

    removeEspFor(owner)

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

-- Distance Update Loop (Runs every 0.15s, smoothly updates label text without flickering)
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

-- 1. Precision Door Scanner (Highlights clean door leaf & verified padlock only)
local function processDoor(room, doorModel)
    if not doorModel or not doorModel:IsA("Model") then return end
    if not State.Doors_ESP then
        removeEspFor(doorModel)
        return
    end

    local dName = doorModel.Name:lower()
    -- Filter out decorative blocked doors with wooden planks across them
    local isBlocked = dName:find("blocked") 
        or doorModel:GetAttribute("Blocked") == true 
        or doorModel:FindFirstChild("Plank", true) ~= nil 
        or doorModel:FindFirstChild("Boards", true) ~= nil
        or doorModel:FindFirstChild("Barricade", true) ~= nil
    if isBlocked then
        removeEspFor(doorModel)
        return
    end

    -- Real playable DOORS exit doors must have 'Door' MeshPart and opening functionality
    local doorMesh = doorModel:FindFirstChild("Door")
    if not doorMesh or not doorMesh:IsA("BasePart") then
        doorMesh = doorModel:FindFirstChildWhichIsA("MeshPart") or doorModel:FindFirstChildWhichIsA("BasePart")
    end
    if not doorMesh then return end

    -- Verify door has real interactable open components (excludes fake room decor doors)
    if not (doorModel:FindFirstChild("ClientOpen") or doorModel:FindFirstChild("Hidden") or doorModel:FindFirstChild("Hinge") or doorModel:FindFirstChild("HingeConstraint")) then
        removeEspFor(doorModel)
        return
    end

    -- Precision Lock Detection:
    -- In DOORS, a door is locked IF AND ONLY IF there is an active padlock with an enabled prompt, or Locked attribute
    local isLocked = false
    local lock = doorModel:FindFirstChild("Lock")
    if lock then
        local prompt = lock:FindFirstChildWhichIsA("ProximityPrompt", true) or (lock:IsA("ProximityPrompt") and lock)
        if prompt and prompt.Enabled then
            isLocked = true
        end
    end
    if doorModel:GetAttribute("Locked") == true then
        isLocked = true
    end

    -- Check for Dupe (Fake Door)
    local isDupe = false
    if doorModel:GetAttribute("DupeRoom") or doorModel:GetAttribute("Fake") or dName:find("fake") then
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

    if isDupe then
        baseText = "Dupe Door"
        color = Color3.fromRGB(255, 35, 35)
    elseif isLocked then
        baseText = string.format("Door %s [LOCKED]", doorNumberStr)
        color = Color3.fromRGB(255, 175, 30)
    else
        baseText = string.format("Door %s", doorNumberStr)
        color = Color3.fromRGB(0, 215, 255)
    end

    -- Highlight unified door model cleanly (Full door leaf + padlock, no internal panel stencil gaps)
    registerEsp(doorModel, doorMesh, baseText, color, "Doors", doorModel, Vector3.new(0, 1.2, 0))

    -- Lifecycle listener: automatically update if lock is removed or room scripts finish loading
    if not doorModel:GetAttribute("ESP_Hooked") then
        doorModel:SetAttribute("ESP_Hooked", true)
        pcall(function()
            doorModel.ChildAdded:Connect(function()
                task.wait(0.1)
                if doorModel.Parent then processDoor(room, doorModel) end
            end)
            doorModel.ChildRemoved:Connect(function()
                task.wait(0.1)
                if doorModel.Parent then processDoor(room, doorModel) end
            end)
            doorModel.AttributeChanged:Connect(function()
                task.wait(0.1)
                if doorModel.Parent then processDoor(room, doorModel) end
            end)
        end)
    end
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
            or keyObtain:FindFirstChildWhichIsA("BasePart", true)
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

    local baseText = signText and string.format("Key [%s]", signText) or "Key"
    local color = Color3.fromRGB(255, 220, 35)

    local highlightParts = { keyMesh }
    if tagMesh and tagMesh:IsA("BasePart") then table.insert(highlightParts, tagMesh) end
    if ringMesh and ringMesh:IsA("BasePart") then table.insert(highlightParts, ringMesh) end

    registerEsp(keyObtain, keyMesh, baseText, color, "Keys", highlightParts, Vector3.new(0, 1.2, 0))
end

-- 2b. Precision Lever Scanner (Highlights gate levers under Keys ESP)
local function processLever(leverInstance)
    if not leverInstance then return end
    if not State.Keys_ESP then
        removeEspFor(leverInstance)
        return
    end

    local targetPart = (leverInstance:IsA("Model") and (leverInstance:FindFirstChild("Lever") or leverInstance:FindFirstChild("Handle") or leverInstance.PrimaryPart or leverInstance:FindFirstChildWhichIsA("BasePart", true)))
        or (leverInstance:IsA("BasePart") and leverInstance)
    if not targetPart then return end

    local baseText = "Lever"
    local color = Color3.fromRGB(255, 215, 0)
    registerEsp(leverInstance, targetPart, baseText, color, "Keys", leverInstance, Vector3.new(0, 1.4, 0))
end

-- 3. Precision Item Scanner (Strict validation against furniture & decor)
local KNOWN_ITEMS = {
    ["candle"]          = "Candle",
    ["crucifix"]        = "Crucifix",
    ["flashlight"]      = "Flashlight",
    ["lighter"]         = "Lighter",
    ["smoothie"]        = "Smoothie",
    ["shake"]           = "Smoothie",
    ["starsmoothie"]    = "Star Smoothie",
    ["herb"]            = "Herb",
    ["starlight"]       = "Starlight",
    ["starjug"]         = "Star Jug",
    ["vitamins"]        = "Vitamins",
    ["lockpick"]        = "Lockpick",
    ["skeletonkey"]     = "Skeleton Key",
    ["battery"]         = "Battery",
    ["bandage"]         = "Bandage",
    ["bandaid"]         = "Bandage",
    ["bread"]           = "Bread",
    ["gummy"]           = "Gummy",
    ["candy"]           = "Candy",
    ["shears"]          = "Shears",
    ["straplight"]      = "Straplight",
    ["bulklight"]       = "Bulklight",
    ["laserpointer"]    = "Laser Pointer",
    ["laser"]           = "Laser Pointer",
    ["shakelight"]      = "Shakelight",
    ["compass"]         = "Compass",
    ["glowstick"]       = "Glowstick",
    ["crucifixwall"]    = "Crucifix"
}

-- Furniture and background decor blacklist to prevent false positives (bottle removed to allow drinks)
local DECOR_BLACKLIST = {
    "bookshelf", "bookcase", "drawer", "desk", "table", "chair", "couch", "sofa",
    "painting", "clock", "cart", "luggage", "fireplace", "chandelier", "lamp",
    "plant", "pillar", "shelf", "carpet", "rug", "door", "window", "curtain",
    "bell", "plate", "cup", "bed", "lightstand", "light_fixture",
    "lightfixture", "sconce", "hook", "fixture", "helpfullight", "wire", "pipe", "crate"
}

local function isValidLootItem(model)
    if not model or not (model:IsA("Model") or model:IsA("Tool")) then return false, nil end
    local lower = model.Name:lower()

    -- Reject blacklist decor & furniture
    for _, blocked in ipairs(DECOR_BLACKLIST) do
        if lower:find(blocked) then
            return false, nil
        end
    end

    if lower:find("keyobtain") or lower:find("goldpile") or lower:find("door") or lower:find("lever") then
        return false, nil
    end

    -- Strict check: Must have an enabled ProximityPrompt with a pickup action, OR be a dropped Tool
    local prompt = model:FindFirstChildWhichIsA("ProximityPrompt", true)
    if not prompt or not prompt.Enabled then
        if model:IsA("Tool") and model:FindFirstChild("Handle") then
            local tName = model.Name
            for key, displayName in pairs(KNOWN_ITEMS) do
                if tName:lower():find(key) then return true, displayName end
            end
            return true, tName
        end
        return false, nil
    end

    local action = (prompt.ActionText or ""):lower()
    local isPickup = action:find("take") or action:find("obtain") or action:find("steal") 
        or action:find("grab") or action:find("pick") or action:find("equip") or action:find("collect") or action:find("get") or action:find("use")
    if not isPickup then
        return false, nil
    end

    local promptObjectName = (prompt.ObjectText and #prompt.ObjectText > 0) and prompt.ObjectText:lower() or ""

    -- Priority 1: Check if prompt explicitly indicates Candle or Crucifix (Fixes Candle displaying as Crucifix)
    if promptObjectName:find("candle") or lower:find("candle") then
        return true, "Candle"
    end
    if promptObjectName:find("crucifix") or lower:find("crucifix") then
        return true, "Crucifix"
    end

    -- Priority 2: Check if prompt explicitly indicates Smoothie or drink (Fixes Smoothie displaying as Vitamins)
    if promptObjectName:find("smoothie") or lower:find("smoothie") or promptObjectName:find("shake") or lower:find("shake") then
        return true, "Smoothie"
    end
    if promptObjectName:find("herb") or lower:find("herb") then
        return true, "Herb"
    end
    if promptObjectName:find("starlight") or lower:find("starlight") or promptObjectName:find("starjug") or lower:find("starjug") then
        return true, "Starlight"
    end

    -- Match known item names (prefer prompt object name first, then model name)
    for key, displayName in pairs(KNOWN_ITEMS) do
        if promptObjectName == key or promptObjectName:find(key) then
            return true, displayName
        end
    end

    for key, displayName in pairs(KNOWN_ITEMS) do
        if lower == key or lower:find("^" .. key) or lower:find(key) then
            return true, displayName
        end
    end

    -- Fallback for custom or dropped items with clean prompt object name
    if prompt.ObjectText and #prompt.ObjectText > 1 then
        return true, prompt.ObjectText
    end

    return false, nil
end

local function processItem(itemModel)
    if not itemModel or not (itemModel:IsA("Model") or itemModel:IsA("Tool")) then return end
    if not State.Items_ESP then
        removeEspFor(itemModel)
        return
    end

    local isValid, displayName = isValidLootItem(itemModel)
    if isValid and displayName then
        local targetPart = itemModel:FindFirstChild("Handle") 
            or itemModel:FindFirstChildWhichIsA("MeshPart", true) 
            or itemModel:FindFirstChildWhichIsA("BasePart", true)
            or (itemModel:IsA("BasePart") and itemModel)
        if targetPart then
            local baseText = displayName
            local color = Color3.fromRGB(185, 80, 255)
            registerEsp(itemModel, targetPart, baseText, color, "Items", itemModel, Vector3.new(0, 1.2, 0))
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
            local baseText = "Library Book"
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
            local baseText = "Breaker Switch"
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
                local baseText = hName
                local color = Color3.fromRGB(110, 195, 255)
                registerEsp(hidingModel, targetPart, baseText, color, "HidingSpots", hidingModel, Vector3.new(0, 2.5, 0))
            end
        end
    end
end

-- 7. Precision Gold & Coins Scanner (Works inside Drawers, Dressers, Tables, LootHolders, and Floor)
local function processGold(goldInstance)
    if not goldInstance then return end
    if not State.Gold_ESP then
        removeEspFor(goldInstance)
        return
    end

    -- Normalize owner to avoid duplicate ESP on both Model and child BasePart
    local owner = goldInstance
    if owner:IsA("BasePart") and owner.Parent and owner.Parent:IsA("Model") then
        local pName = owner.Parent.Name:lower()
        if pName == "goldpile" or pName:find("^gold") or pName:find("coin") then
            owner = owner.Parent
        end
    end

    local gName = owner.Name:lower()
    local isGold = gName == "goldpile" or gName:find("^gold") or gName:find("coin")

    local prompt = owner:FindFirstChildWhichIsA("ProximityPrompt", true)
    local displayName = "Gold"

    if prompt and prompt.Enabled then
        local pObj = (prompt.ObjectText or ""):lower()
        local pAct = (prompt.ActionText or ""):lower()
        if pObj:find("gold") or pAct:find("gold") then
            isGold = true
            displayName = "Gold"
        elseif pObj:find("coin") or pAct:find("coin") then
            isGold = true
            displayName = "Coins"
        end
    end

    if not isGold then return end

    local targetPart = (owner:IsA("Model") and (owner:FindFirstChildWhichIsA("MeshPart", true) or owner:FindFirstChildWhichIsA("BasePart", true)))
        or (owner:IsA("BasePart") and owner)
        or (prompt and prompt.Parent and prompt.Parent:IsA("BasePart") and prompt.Parent)

    if targetPart then
        local baseText = displayName
        local color = Color3.fromRGB(255, 195, 0)
        registerEsp(owner, targetPart, baseText, color, "Gold", owner, Vector3.new(0, 0.8, 0))
    end
end

-- 8. Comprehensive Entity ESP (Every Monster in DOORS Hotel & The Mines - All Red, No Emojis)
local ENTITY_RED = Color3.fromRGB(255, 35, 35)

local ENTITY_REGISTRY = {
    ["rushmoving"]     = { Name = "Rush",               Color = ENTITY_RED },
    ["ambushmoving"]   = { Name = "Ambush",             Color = ENTITY_RED },
    ["figurerig"]      = { Name = "Figure",             Color = ENTITY_RED },
    ["seekmoving"]     = { Name = "Seek",               Color = ENTITY_RED },
    ["seekrig"]        = { Name = "Seek",               Color = ENTITY_RED },
    ["eyes"]           = { Name = "Eyes (Don't Look!)", Color = ENTITY_RED },
    ["halt"]           = { Name = "Halt",               Color = ENTITY_RED },
    ["shade"]          = { Name = "Halt",               Color = ENTITY_RED },
    ["screech"]        = { Name = "Screech",            Color = ENTITY_RED },
    ["giggleceiling"]  = { Name = "Giggle",             Color = ENTITY_RED },
    ["giggle"]         = { Name = "Giggle",             Color = ENTITY_RED },
    ["grumble"]        = { Name = "Grumble",            Color = ENTITY_RED },
    ["grumblerig"]     = { Name = "Grumble",            Color = ENTITY_RED },
    ["snare"]          = { Name = "Snare Trap",         Color = ENTITY_RED },
    ["glitch"]         = { Name = "Glitch",             Color = ENTITY_RED },
    ["dupe"]           = { Name = "Dupe",               Color = ENTITY_RED },
    ["doorfake"]       = { Name = "Dupe",               Color = ENTITY_RED },
    ["sideroomdupe"]   = { Name = "Dupe",               Color = ENTITY_RED },
    ["dread"]          = { Name = "Dread",              Color = ENTITY_RED },
    ["timothy"]        = { Name = "Timothy",            Color = ENTITY_RED },
    ["spider"]         = { Name = "Timothy",            Color = ENTITY_RED },
    ["a60"]            = { Name = "A-60",               Color = ENTITY_RED },
    ["a-60"]           = { Name = "A-60",               Color = ENTITY_RED },
    ["a90"]            = { Name = "A-90",               Color = ENTITY_RED },
    ["a-90"]           = { Name = "A-90",               Color = ENTITY_RED },
    ["a120"]           = { Name = "A-120",              Color = ENTITY_RED },
    ["a-120"]          = { Name = "A-120",              Color = ENTITY_RED },
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
    if eLower:find("bob") or eLower:find("elgoblino") or (eLower:find("jeff") and not eLower:find("killer")) then return end

    -- Check if inside Dupe room or Dupe entity
    local isDupe = eLower:find("dupe") or eLower:find("doorfake") or (entity.Parent and entity.Parent.Name:lower():find("dupe"))
    local cfg = nil

    if isDupe then
        cfg = { Name = "Dupe", Color = ENTITY_RED }
    else
        for key, info in pairs(ENTITY_REGISTRY) do
            if eLower == key or eLower:find(key) then
                cfg = info
                break
            end
        end
    end

    if cfg then
        local targetPart = (entity:IsA("Model") and (entity.PrimaryPart or entity:FindFirstChild("Root") or entity:FindFirstChild("Core") or entity:FindFirstChildWhichIsA("BasePart", true)))
            or (entity:IsA("BasePart") and entity)

        if targetPart then
            local highlightTarget = entity

            -- For 2D entities without a multi-part 3D rig (like nextbots, A-60, A-90, Rush sprites), attach a clean rounded neon sphere
            local is2D = entity:IsA("BasePart") or (entity:IsA("Model") and not entity:FindFirstChildWhichIsA("Humanoid") and #entity:GetChildren() <= 3)
            if is2D then
                local sphere = entity:FindFirstChild("Unknown_EntitySphere")
                if not sphere or not sphere:IsA("BasePart") then
                    sphere = Instance.new("Part")
                    sphere.Name = "Unknown_EntitySphere"
                    sphere.Shape = Enum.PartType.Ball
                    sphere.Size = Vector3.new(3.5, 3.5, 3.5)
                    sphere.CFrame = targetPart.CFrame
                    sphere.Transparency = 0.55
                    sphere.Color = ENTITY_RED
                    sphere.Material = Enum.Material.Neon
                    sphere.CanCollide = false
                    sphere.CanTouch = false
                    sphere.CanQuery = false
                    sphere.Massless = true
                    sphere.Anchored = false
                    local weld = Instance.new("WeldConstraint")
                    weld.Part0 = sphere
                    weld.Part1 = targetPart
                    weld.Parent = sphere
                    sphere.Parent = entity
                end
                highlightTarget = sphere
            end

            local baseText = cfg.Name
            registerEsp(entity, targetPart, baseText, ENTITY_RED, "Entities", highlightTarget, Vector3.new(0, 3.0, 0))
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
        local dName = desc.Name:lower()

        if desc:IsA("Model") or desc:IsA("Tool") then
            if desc.Name == "Door" then
                processDoor(room, desc)
            elseif desc.Name == "KeyObtain" or desc:GetAttribute("IsKey") then
                processKey(desc)
            elseif dName:find("lever") then
                processLever(desc)
            elseif desc.Name == "Wardrobe" or desc.Name == "Closet" or desc.Name == "Locker" or desc.Name:find("Bed") then
                processHidingSpot(desc)
            elseif dName == "goldpile" or dName:find("^gold") or dName:find("coin") then
                processGold(desc)
            else
                processItem(desc)
                processEntity(desc)
            end
        elseif desc:IsA("BasePart") then
            local p = desc.Parent
            local isParentGold = p and p:IsA("Model") and (p.Name:lower():find("gold") or p.Name:lower():find("coin"))
            if not isParentGold then
                if dName == "goldpile" or dName:find("^gold") or dName:find("coin") then
                    processGold(desc)
                end
            end
            if dName:find("lever") then
                processLever(desc)
            end
        elseif desc:IsA("ProximityPrompt") then
            local obj = (desc.ObjectText or ""):lower()
            local act = (desc.ActionText or ""):lower()
            if obj:find("gold") or obj:find("coin") or act:find("gold") or act:find("coin") then
                processGold(desc.Parent)
            elseif obj:find("lever") or act:find("pull") then
                processLever(desc.Parent)
            elseif act:find("take") or act:find("pick") or act:find("grab") then
                if desc.Parent and (desc.Parent:IsA("Model") or desc.Parent:IsA("Tool")) then
                    processItem(desc.Parent)
                end
            end
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

    -- Scan Workspace for roaming entities and dropped items
    for _, child in ipairs(Workspace:GetChildren()) do
        if child:IsA("Model") or child:IsA("Tool") then
            if State.Entities_ESP then processEntity(child) end
            if State.Items_ESP then processItem(child) end
        end
    end
    if Camera and State.Entities_ESP then
        for _, child in ipairs(Camera:GetChildren()) do
            processEntity(child)
        end
    end
end

-- Dynamic Room Generation & Descendant Drop Listener
pcall(function()
    local currentRooms = Workspace:FindFirstChild("CurrentRooms") or Workspace:WaitForChild("CurrentRooms", 5)
    if currentRooms then
        local function bindRoom(newRoom)
            task.wait(0.2)
            scanSingleRoom(newRoom)

            -- Delayed door verification passes: DOORS room scripts remove default template padlocks 0.3-0.8s later
            task.delay(0.6, function()
                if newRoom.Parent then
                    local door = newRoom:FindFirstChild("Door")
                    if door then processDoor(newRoom, door) end
                end
            end)
            task.delay(1.2, function()
                if newRoom.Parent then
                    local door = newRoom:FindFirstChild("Door")
                    if door then processDoor(newRoom, door) end
                end
            end)

            -- Real-time dropped items, drawer looting, and lever discovery
            newRoom.DescendantAdded:Connect(function(desc)
                task.wait(0.05)
                local dName = desc.Name:lower()
                if desc:IsA("Model") or desc:IsA("Tool") then
                    if desc.Name == "Door" then
                        processDoor(newRoom, desc)
                    elseif desc.Name == "KeyObtain" or desc:GetAttribute("IsKey") then
                        processKey(desc)
                    elseif dName:find("lever") then
                        processLever(desc)
                    elseif dName == "goldpile" or dName:find("^gold") or dName:find("coin") then
                        processGold(desc)
                    else
                        processItem(desc)
                        if State.Entities_ESP then processEntity(desc) end
                    end
                elseif desc:IsA("BasePart") then
                    local p = desc.Parent
                    local isParentGold = p and p:IsA("Model") and (p.Name:lower():find("gold") or p.Name:lower():find("coin"))
                    if not isParentGold then
                        if dName == "goldpile" or dName:find("^gold") or dName:find("coin") then
                            processGold(desc)
                        end
                    end
                    if dName:find("lever") then
                        processLever(desc)
                    end
                elseif desc:IsA("ProximityPrompt") then
                    local obj = (desc.ObjectText or ""):lower()
                    local act = (desc.ActionText or ""):lower()
                    if obj:find("gold") or obj:find("coin") or act:find("gold") or act:find("coin") then
                        processGold(desc.Parent)
                    elseif obj:find("lever") or act:find("pull") then
                        processLever(desc.Parent)
                    elseif act:find("take") or act:find("pick") or act:find("grab") then
                        if desc.Parent and (desc.Parent:IsA("Model") or desc.Parent:IsA("Tool")) then
                            processItem(desc.Parent)
                        end
                    end
                end
            end)
        end

        for _, r in ipairs(currentRooms:GetChildren()) do
            bindRoom(r)
        end

        currentRooms.ChildAdded:Connect(bindRoom)
    end
end)

-- Dynamic Workspace Drops & Entity Spawning Listeners
Workspace.ChildAdded:Connect(function(child)
    task.wait(0.05)
    if child:IsA("Model") or child:IsA("Tool") then
        local cName = child.Name:lower()
        if cName == "keyobtain" or child:GetAttribute("IsKey") then
            processKey(child)
        elseif cName:find("lever") then
            processLever(child)
        elseif cName == "goldpile" or cName:find("^gold") or cName:find("coin") then
            processGold(child)
        else
            processItem(child)
            if State.Entities_ESP then processEntity(child) end
        end
    end
end)

local dropsFolder = Workspace:FindFirstChild("Drops")
if dropsFolder then
    dropsFolder.ChildAdded:Connect(function(child)
        task.wait(0.05)
        processItem(child)
    end)
end

if Camera then
    Camera.ChildAdded:Connect(function(child)
        task.wait(0.05)
        if State.Entities_ESP then
            processEntity(child)
        end
    end)
end

-- Continuous Guard Loop (Guarantees live entity tracking and periodic sweeps)
task.spawn(function()
    while true do
        if _G.DOORS_SESSION ~= currentSession then break end
        if State.Master_ESP then
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
-- Teflon-Glide & Omnidirectional Anti-Rollback Engine
-- 1. Zero Wall Friction: Collision and HumanoidRootPart friction set to 0,
--    eliminating rotational snagging and kinetic stops when grazing side objects.
-- 2. Omnidirectional Trail Tracking: Maintains a recent trajectory buffer.
--    Detects server rollbacks independently of turning angle or move direction.
-- 3. Collision-Safe Restoration: Projects restoration vector along obstacles,
--    preserving current camera rotation and preventing wall penetration.
-- 4. Micro-Smooth Braking & Resting Anchor: 150ms cosinusoidal deceleration
--    when keys are released, eliminating the 0.1s twitch.
-- =========================================================================
local zeroFriction = PhysicalProperties.new(0.5, 0.0, 0.0, 100, 100)
local defaultCollProps = nil
local defaultRootProps = nil

local function applyTeflonGlide(char)
    if not char then return end
    local coll = char:FindFirstChild("Collision")
    local cp = char:FindFirstChild("CollisionPart")
    local root = char:FindFirstChild("HumanoidRootPart")
    if coll and coll:IsA("BasePart") then
        if not defaultCollProps then defaultCollProps = coll.CustomPhysicalProperties end
        coll.CustomPhysicalProperties = zeroFriction
    end
    if cp and cp:IsA("BasePart") then
        cp.CustomPhysicalProperties = zeroFriction
    end
    if root and root:IsA("BasePart") then
        if not defaultRootProps then defaultRootProps = root.CustomPhysicalProperties end
        root.CustomPhysicalProperties = zeroFriction
    end
end

local function restoreDefaultFriction(char)
    if not char then return end
    local coll = char:FindFirstChild("Collision")
    local root = char:FindFirstChild("HumanoidRootPart")
    if coll and coll:IsA("BasePart") and defaultCollProps then
        coll.CustomPhysicalProperties = defaultCollProps
    end
    if root and root:IsA("BasePart") and defaultRootProps then
        root.CustomPhysicalProperties = defaultRootProps
    end
end

local trailHistory = {} -- Ring buffer of { pos = Vector3, cf = CFrame, time = number }
local lastForwardCFrame = nil
local lastForwardPos = nil
local lastMoveVector = Vector3.new(0, 0, 0)
local wasMoving = false
local crouchRemote = nil
local isServerSlideActive = false
local lastSentCrouchState = nil
local unhideGraceUntil = 0
local wasHidingState = false

local function getMainGameTable()
    local pGui = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
    local mg = pGui and pGui:FindFirstChild("MainUI") and pGui.MainUI:FindFirstChild("Initiator") and pGui.MainUI.Initiator:FindFirstChild("Main_Game")
    if mg then
        local s, res = pcall(require, mg)
        if s and type(res) == "table" then
            return res
        end
    end
    return nil
end

local function isPlayerHiding(char, mgTable)
    if not char then return false end
    if char:GetAttribute("Hiding") == true then return true end
    if char:GetAttribute("AnimatingClient") == true then return true end
    if char:GetAttribute("ForceOut") == true then return true end
    if char:GetAttribute("SkipExit") == true then return true end
    if mgTable and (mgTable.hiding == true or mgTable.animating == true) then return true end
    return false
end

-- Pre-hook ProximityPrompts for hiding spots to instantly prime grace window
pcall(function()
    local pps = game:GetService("ProximityPromptService")
    pps.PromptTriggered:Connect(function(prompt, playerWhoTriggered)
        if playerWhoTriggered == LocalPlayer then
            local action = (prompt.ActionText or ""):lower()
            local name = (prompt.Name or ""):lower()
            if action:find("hide") or name:find("hide") or action:find("closet") or action:find("wardrobe") then
                unhideGraceUntil = os.clock() + 1.2
                lastForwardPos = nil
                lastForwardCFrame = nil
                table.clear(trailHistory)
                wasMoving = false
                syncServerSlide(false)
            end
        end
    end)
end)

local function syncServerSlide(shouldAuthorize)
    if not crouchRemote then
        pcall(function()
            local rf = game:GetService("ReplicatedStorage"):FindFirstChild("RemotesFolder")
            crouchRemote = rf and rf:FindFirstChild("Crouch")
        end)
    end
    if not crouchRemote then return end

    local char = getChar()
    local mgTable = getMainGameTable()
    local isCrouching = (mgTable and mgTable.crouching) or (char and char:GetAttribute("Crouching")) or false

    if shouldAuthorize then
        -- Never authorize slide while hidden or exiting closet
        if isPlayerHiding(char, mgTable) or (os.clock() < unhideGraceUntil) then
            if isServerSlideActive then
                isServerSlideActive = false
                pcall(function()
                    crouchRemote:FireServer(false, false)
                end)
            end
            return
        end

        -- Keep slide authorized continuously on server while WalkSpeed is active
        -- Never revoke authorization on stop, preventing slide-end door snapbacks
        if not isServerSlideActive or isCrouching ~= lastSentCrouchState then
            isServerSlideActive = true
            lastSentCrouchState = isCrouching
            pcall(function()
                crouchRemote:FireServer(isCrouching, true)
            end)
        end
    else
        if isServerSlideActive then
            isServerSlideActive = false
            lastSentCrouchState = isCrouching
            pcall(function()
                crouchRemote:FireServer(isCrouching, false)
            end)
        end
    end
end

local wallRayParams = RaycastParams.new()
wallRayParams.FilterType = Enum.RaycastFilterType.Exclude
wallRayParams.RespectCanCollide = true

local BIND_NAME = "Unknown_AntiRollback_" .. tostring(currentSession)

local function updateMotion(dt)
    if _G.DOORS_SESSION ~= currentSession then 
        pcall(function() RunService:UnbindFromRenderStep(BIND_NAME) end)
        return 
    end

    if not State.WalkSpeed_Enabled or not State.AntiRubberband then 
        lastForwardPos = nil
        lastForwardCFrame = nil
        wasMoving = false
        table.clear(trailHistory)
        syncServerSlide(false)
        return 
    end

    local char = getChar()
    local root = getRoot()
    local hum = char and char:FindFirstChildWhichIsA("Humanoid")
    if not root or not hum or not hum.Parent then return end

    local mgTable = getMainGameTable()
    local hidden = isPlayerHiding(char, mgTable)

    -- Detect closet enter/exit state transitions
    if hidden then
        wasHidingState = true
        unhideGraceUntil = os.clock() + 0.85
        lastForwardPos = nil
        lastForwardCFrame = nil
        table.clear(trailHistory)
        wasMoving = false
        syncServerSlide(false)
        return
    elseif wasHidingState then
        wasHidingState = false
        unhideGraceUntil = os.clock() + 0.85
    end

    -- During closet unhide transition, permit natural teleport/cutscene out into the room
    if os.clock() < unhideGraceUntil then
        lastForwardPos = root.Position
        lastForwardCFrame = root.CFrame
        table.clear(trailHistory)
        wasMoving = false
        syncServerSlide(false)
        return
    end

    -- Keep server high-speed authorization continuously active while WalkSpeed is enabled
    syncServerSlide(true)

    -- Keep teflon glide active
    local coll = char:FindFirstChild("Collision")
    if coll and coll.CustomPhysicalProperties ~= zeroFriction then
        applyTeflonGlide(char)
    end

    local currentPos = root.Position
    local moveDir = hum.MoveDirection
    local isMoving = moveDir.Magnitude > 0.05
    local now = os.clock()

    if isMoving then
        wasMoving = true
        lastMoveVector = moveDir

        if lastForwardPos then
            local frameDelta = currentPos - lastForwardPos
            local dist = frameDelta.Magnitude
            local progression = frameDelta:Dot(moveDir)
            local expectedStep = hum.WalkSpeed * dt
            local maxNaturalStep = math.max(expectedStep * 1.5, 1.4)
            local isRollback = false

            -- In-flight rollback check: only triggers if snapped backwards against moveDir or towards past history
            if dist > maxNaturalStep then
                for i = #trailHistory, 1, -1 do
                    local entry = trailHistory[i]
                    local age = now - entry.time
                    if age > 0.03 and age < 0.45 then
                        local distToHistory = (currentPos - entry.pos).Magnitude
                        if distToHistory < 2.0 then
                            isRollback = true
                            break
                        end
                    end
                end
                if not isRollback and progression < -0.25 then
                    isRollback = true
                end
            end

            if isRollback then
                wallRayParams.FilterDescendantsInstances = {char}
                local safeDir = moveDir
                
                -- Check if moving into a wall/obstacle:
                local ray = Workspace:Raycast(lastForwardPos, moveDir * 1.5, wallRayParams)
                if ray and ray.Normal then
                    local normal = ray.Normal
                    local projected = moveDir - normal * moveDir:Dot(normal)
                    if projected.Magnitude > 0.1 then
                        safeDir = projected.Unit
                    else
                        safeDir = Vector3.new(0, 0, 0)
                    end
                end

                local advanceStep = safeDir * (hum.WalkSpeed * math.clamp(dt, 0.01, 0.033))
                local restoredPos = lastForwardPos + advanceStep
                local restoredCF = CFrame.new(restoredPos) * root.CFrame.Rotation

                root.CFrame = restoredCF
                root.AssemblyLinearVelocity = safeDir * hum.WalkSpeed

                lastForwardPos = restoredPos
                lastForwardCFrame = restoredCF

                table.insert(trailHistory, { pos = restoredPos, cf = restoredCF, time = now })
                if #trailHistory > 35 then table.remove(trailHistory, 1) end
                return
            end
        end

        -- Record legitimate position to trail
        table.insert(trailHistory, { pos = currentPos, cf = root.CFrame, time = now })
        while #trailHistory > 0 and (now - trailHistory[1].time) > 0.5 do
            table.remove(trailHistory, 1)
        end

        lastForwardPos = currentPos
        lastForwardCFrame = root.CFrame
    else
        -- Movement keys released: natural physics stop
        -- Slide authorization remains ACTIVE on server so no slide-end boundary check is ever fired
        table.clear(trailHistory)
        wasMoving = false
        lastForwardPos = root.Position
        lastForwardCFrame = root.CFrame
    end
end

-- Bind prior to camera evaluation (CameraPriority - 20) to guarantee zero camera twitch/shake
pcall(function()
    RunService:BindToRenderStep(BIND_NAME, Enum.RenderPriority.Camera.Value - 20, updateMotion)
end)

-- Continuous Heartbeat Enforcement (Ensures target speed with smooth crouch support & hiding safety)
RunService.Heartbeat:Connect(function()
    if _G.DOORS_SESSION ~= currentSession then return end
    local char = getChar()
    local root = getRoot()
    local hum = char and char:FindFirstChildWhichIsA("Humanoid")
    if not hum or not hum.Parent or not root then return end

    local mgTable = getMainGameTable()
    local hiding = isPlayerHiding(char, mgTable) or (os.clock() < unhideGraceUntil)

    if State.WalkSpeed_Enabled and not hiding then
        local isCrouching = (mgTable and mgTable.crouching) or (char and char:GetAttribute("Crouching")) or false
        local targetSpeed = isCrouching and math.max(math.floor(State.WalkSpeed_Value * 0.65), 18) or State.WalkSpeed_Value
        if hum.WalkSpeed ~= targetSpeed then
            hum.WalkSpeed = targetSpeed
        end
    else
        if hum.WalkSpeed ~= 15 and not State.WalkSpeed_Enabled then
            hum.WalkSpeed = 15
        end
    end
end)

-- Stepped Guard: Ensures WalkSpeed is maintained across DOORS physics steps
RunService.Stepped:Connect(function()
    if _G.DOORS_SESSION ~= currentSession then return end
    if State.WalkSpeed_Enabled then
        local char = getChar()
        local mgTable = getMainGameTable()
        if isPlayerHiding(char, mgTable) or (os.clock() < unhideGraceUntil) then return end

        local hum = char and char:FindFirstChildWhichIsA("Humanoid")
        if hum then
            local isCrouching = (mgTable and mgTable.crouching) or (char and char:GetAttribute("Crouching")) or false
            local targetSpeed = isCrouching and math.max(math.floor(State.WalkSpeed_Value * 0.65), 18) or State.WalkSpeed_Value
            if hum.WalkSpeed ~= targetSpeed then
                hum.WalkSpeed = targetSpeed
            end
        end
    end
end)

-- Auto-reapply on respawn or revive
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.25)
    if State.WalkSpeed_Enabled then
        applyTeflonGlide(char)
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
    local char = getChar()
    if not v then
        syncServerSlide(false)
        restoreDefaultFriction(char)
        local hum = char and char:FindFirstChildWhichIsA("Humanoid")
        if hum then hum.WalkSpeed = 15 end
        Hub.Notify("WalkSpeed", "Speed reset to default (15)", 2)
    else
        syncServerSlide(true)
        applyTeflonGlide(char)
        Hub.Notify("WalkSpeed", string.format("Speed active: %d studs/s (Teflon + Anti-Rollback Active)", State.WalkSpeed_Value), 2)
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
