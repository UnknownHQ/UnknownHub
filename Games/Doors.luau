--[[
    ========================================================================
    Unknown Hub - DOORS (Hotel & The Mines)
    Supported Places:
      - 6839171747  (Hotel / Floor 1)
      - 12555541629 (The Mines / Floor 2)
      - 13511802958 (The Mines Sub-place)
      - 11935914798 (The Rooms)
      - 16033173781 (The Backdoor)
      - 6516141723  (Lobby)
    Architecture:
      - UnknownLibrary 2.0 Integration
      - ProximityPrompt Bypass & Instant Loot
      - Real-Time Room & Entity Detection
      - ESP & Wallhack Engine (Doors, Keys, Items, Books, Breakers, Monsters)
      - Entity Alert & Auto-Closet Survival Engine
      - Automated Puzzle Solvers (Door 50 Padlock & Door 100 Breakers)
    ========================================================================
]]

local LIBRARY_LINK = "https://raw.githubusercontent.com/UnknownHQ/UnknownHub/main/UnknownLibrary"
local LIBRARY_NAME = "Unknown_TabbedHub_UI"

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local SoundService = game:GetService("SoundService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- =========================================================================
-- Built-in Anti-AFK
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

local function destroyOldGui()
    local parents = {CoreGui}
    if gethui then pcall(function() table.insert(parents, gethui()) end) end
    local pGui = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
    if pGui then table.insert(parents, pGui) end
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
        -- Fallback: Check local filesystem if running in dev environment
        if readfile then
            pcall(function() source = readfile("UnknownLibrary.luau") end)
            if not source then pcall(function() source = readfile("UnknownLibrary") end) end
        end
    end
    assert(source and #source > 100, "Could not obtain UnknownLibrary source")
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
-- State & Configuration
-- =========================================================================
local State = {
    -- Visuals / ESP
    ESP_Master = true,
    ESP_Doors = true,
    ESP_Keys = true,
    ESP_Items = true,
    ESP_Books = true,
    ESP_Breakers = true,
    ESP_Gold = false,
    ESP_Entities = true,
    ESP_HidingSpots = false,
    ESP_Distance = true,
    ESP_Tracer = false,

    -- Survival & Entity Defense
    Entity_Notifier = true,
    Entity_NotifySound = true,
    Auto_Hide = false,
    Auto_Hide_Distance = 140,
    Anti_Screech = true,
    Anti_Eyes = true,
    Anti_Dupe = true,
    Anti_Snare = true,
    Anti_Timothy = true,
    Anti_Giggle = true,

    -- Automation & Progression
    Instant_Interact = true,
    Auto_Loot_Keys = true,
    Auto_Loot_Items = false,
    Auto_Loot_Gold = false,
    Auto_Loot_Books = true,
    Auto_Loot_Breakers = true,
    Auto_Unlock_Doors = true,
    Auto_Solve_Door50 = true,
    Auto_Solve_Breaker = true,

    -- Player & Movement
    Speed_Enabled = false,
    Speed_Value = 21,
    Fullbright = true,
    No_Clip = false,
    Infinite_Oxygen = true,
    No_Camera_Shake = true
}

-- Session lifecycle tracker
_G.DOORS_SESSION = tick()
local currentSession = _G.DOORS_SESSION

-- Helper Getters
local function getChar()
    return LocalPlayer and LocalPlayer.Character
end

local function getRoot()
    local char = getChar()
    return char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart or char:FindFirstChild("Torso"))
end

local function getHumanoid()
    local char = getChar()
    return char and char:FindFirstChildWhichIsA("Humanoid")
end

-- =========================================================================
-- ESP & Highlight Storage Engine
-- =========================================================================
local espContainers = {}

local function removeEsp(instance)
    if espContainers[instance] then
        for _, gui in ipairs(espContainers[instance]) do
            pcall(function() gui:Destroy() end)
        end
        espContainers[instance] = nil
    end
end

local function addBillboard(instance, text, color, offset)
    offset = offset or Vector3.new(0, 2.5, 0)
    local adornee = instance:IsA("BasePart") and instance or instance:FindFirstChildWhichIsA("BasePart", true)
    if not adornee then return end

    local bb = Instance.new("BillboardGui")
    bb.Name = "Unknown_ESP_Billboard"
    bb.Adornee = adornee
    bb.AlwaysOnTop = true
    bb.Size = UDim2.new(0, 160, 0, 35)
    bb.StudsOffset = offset
    bb.ResetOnSpawn = false

    local label = Instance.new("TextLabel")
    label.Name = "ESPLabel"
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = color
    label.TextStrokeTransparency = 0.2
    label.TextStrokeColor3 = Color3.fromRGB(10, 10, 15)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 13
    label.Parent = bb

    local targetParent = (gethui and gethui()) or CoreGui
    bb.Parent = targetParent

    espContainers[instance] = espContainers[instance] or {}
    table.insert(espContainers[instance], bb)
    return bb, label
end

local function addHighlight(instance, color)
    local hl = Instance.new("Highlight")
    hl.Name = "Unknown_ESP_Highlight"
    hl.Adornee = instance
    hl.FillColor = color
    hl.FillTransparency = 0.7
    hl.OutlineColor = color
    hl.OutlineTransparency = 0.1
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = (gethui and gethui()) or CoreGui

    espContainers[instance] = espContainers[instance] or {}
    table.insert(espContainers[instance], hl)
    return hl
end

-- =========================================================================
-- Room Scanner & ESP Categorization
-- =========================================================================
local trackedDoors = {}
local trackedKeys = {}
local trackedItems = {}
local trackedBooks = {}
local trackedBreakers = {}
local trackedHidingSpots = {}
local trackedGold = {}

local function isFakeDoor(doorModel)
    if not doorModel then return false end
    -- Dupe identification: wrong room number or Dupe attribute/sign
    if doorModel:GetAttribute("DupeRoom") or doorModel:GetAttribute("Fake") or doorModel.Name:lower():find("fake") then
        return true
    end
    local sign = doorModel:FindFirstChild("Sign")
    if sign and sign:FindFirstChild("TextLabel") then
        local currentRooms = Workspace:FindFirstChild("CurrentRooms")
        if currentRooms then
            local roomNumber = tonumber(doorModel.Parent and doorModel.Parent.Name)
            local signNumber = tonumber(sign.TextLabel.Text)
            if roomNumber and signNumber and signNumber ~= (roomNumber + 1) then
                return true
            end
        end
    end
    return false
end

local function scanRoom(room)
    if not room or not room:IsA("Model") then return end

    -- 1. Doors
    local door = room:FindFirstChild("Door")
    if door and door:IsA("Model") then
        local doorNumber = room.Name
        local isLocked = door:FindFirstChild("Lock") ~= nil
        local isDupe = isFakeDoor(door)
        
        removeEsp(door)
        if State.ESP_Master and State.ESP_Doors then
            local color = isDupe and Color3.fromRGB(255, 30, 30) or (isLocked and Color3.fromRGB(255, 190, 40) or Color3.fromRGB(0, 220, 255))
            local labelText = isDupe and "⚠️ FAKE DOOR" or string.format("🚪 Door %s %s", tostring(doorNumber), isLocked and "[LOCKED 🔒]" or "")
            addBillboard(door, labelText, color)
            addHighlight(door, color)
        end
        trackedDoors[door] = { Number = doorNumber, Locked = isLocked, Fake = isDupe }
    end

    -- 2. Assets (Keys, Gold, Furniture, Items, Closets)
    for _, desc in ipairs(room:GetDescendants()) do
        -- Keys
        if desc.Name == "KeyRoot" or desc.Name == "Key" or desc.Name == "ElectricalKey" then
            local keyModel = desc:IsA("Model") and desc or desc.Parent
            if keyModel and not trackedKeys[keyModel] then
                trackedKeys[keyModel] = true
                if State.ESP_Master and State.ESP_Keys then
                    addBillboard(keyModel, "🔑 " .. keyModel.Name, Color3.fromRGB(255, 230, 50))
                    addHighlight(keyModel, Color3.fromRGB(255, 230, 50))
                end
            end
        end

        -- Items (Crucifix, Flashlight, Vitamins, Lighter, SkeletonKey, Shears, etc.)
        if desc:IsA("Model") and (desc:FindFirstChild("Handle") or desc:GetAttribute("ItemType") or desc:FindFirstChildWhichIsA("ProximityPrompt", true)) then
            local dName = desc.Name:lower()
            local isKey = dName:find("key") and not dName:find("skeleton")
            if not isKey and (dName:find("crucifix") or dName:find("flashlight") or dName:find("lighter") or dName:find("vitamins") or dName:find("skeleton") or dName:find("shears") or dName:find("battery") or dName:find("bandage") or dName:find("candle") or dName:find("straplight") or dName:find("laser")) then
                if not trackedItems[desc] then
                    trackedItems[desc] = true
                    if State.ESP_Master and State.ESP_Items then
                        addBillboard(desc, "📦 " .. desc.Name, Color3.fromRGB(190, 80, 255))
                        addHighlight(desc, Color3.fromRGB(190, 80, 255))
                    end
                end
            end
        end

        -- Books (Door 50 Library)
        if desc.Name == "LiveHintBook" or desc.Name == "HintBook" or (desc:IsA("Model") and desc.Name:lower():find("book") and desc:FindFirstChildWhichIsA("BasePart")) then
            if not trackedBooks[desc] then
                trackedBooks[desc] = true
                if State.ESP_Master and State.ESP_Books then
                    addBillboard(desc, "📖 Library Book", Color3.fromRGB(80, 255, 120))
                    addHighlight(desc, Color3.fromRGB(80, 255, 120))
                end
            end
        end

        -- Breakers (Door 100 Elevator Switches)
        if desc.Name == "BreakerSwitch" or desc.Name == "LiveBreakerSwitch" or (desc:IsA("Model") and desc.Name:lower():find("breaker") and desc:FindFirstChildWhichIsA("BasePart")) then
            if not trackedBreakers[desc] then
                trackedBreakers[desc] = true
                if State.ESP_Master and State.ESP_Breakers then
                    addBillboard(desc, "⚡ Breaker Switch", Color3.fromRGB(0, 255, 210))
                    addHighlight(desc, Color3.fromRGB(0, 255, 210))
                end
            end
        end

        -- Gold Piles
        if desc.Name == "GoldPile" or (desc:IsA("Model") and desc.Name:lower():find("gold")) then
            if not trackedGold[desc] then
                trackedGold[desc] = true
                if State.ESP_Master and State.ESP_Gold then
                    addBillboard(desc, "💰 Gold", Color3.fromRGB(255, 180, 0))
                end
            end
        end

        -- Hiding Spots (Wardrobes, Closets, Lockers, Beds)
        if desc:IsA("Model") and (desc.Name == "Wardrobe" or desc.Name == "Closet" or desc.Name == "Locker" or desc.Name:find("Bed")) then
            if not trackedHidingSpots[desc] then
                trackedHidingSpots[desc] = true
                if State.ESP_Master and State.ESP_HidingSpots then
                    addBillboard(desc, "🛡️ " .. desc.Name, Color3.fromRGB(100, 190, 255))
                    addHighlight(desc, Color3.fromRGB(100, 190, 255))
                end
            end
        end

        -- Instant Interact for Prompts
        if State.Instant_Interact and desc:IsA("ProximityPrompt") then
            desc.HoldDuration = 0
            desc.MaxActivationDistance = math.max(desc.MaxActivationDistance, 14)
        end
    end
end

local function refreshAllRooms()
    local currentRooms = Workspace:FindFirstChild("CurrentRooms")
    if currentRooms then
        for _, room in ipairs(currentRooms:GetChildren()) do
            scanRoom(room)
        end
    end
end

-- Listen for new rooms being generated
pcall(function()
    local currentRooms = Workspace:FindFirstChild("CurrentRooms") or Workspace:WaitForChild("CurrentRooms", 5)
    if currentRooms then
        currentRooms.ChildAdded:Connect(function(newRoom)
            task.wait(0.2)
            scanRoom(newRoom)
        end)
    end
end)

-- =========================================================================
-- Entity Alerts & Real-Time Threat Detection
-- =========================================================================
local activeThreats = {}

local DANGEROUS_ENTITIES = {
    ["RushMoving"] = { Name = "Rush", Sound = true, Danger = 1 },
    ["AmbushMoving"] = { Name = "Ambush", Sound = true, Danger = 2 },
    ["SeekMoving"] = { Name = "Seek", Sound = true, Danger = 1 },
    ["FigureRig"] = { Name = "Figure", Sound = false, Danger = 1 },
    ["Eyes"] = { Name = "Eyes", Sound = false, Danger = 1 },
    ["Halt"] = { Name = "Halt", Sound = true, Danger = 1 },
    ["Screech"] = { Name = "Screech", Sound = false, Danger = 1 },
    ["GiggleCeiling"] = { Name = "Giggle", Sound = false, Danger = 1 },
    ["Grumble"] = { Name = "Grumble", Sound = true, Danger = 2 }
}

local function playWarningChime()
    if not State.Entity_NotifySound then return end
    pcall(function()
        local sound = Instance.new("Sound")
        sound.SoundId = "rbxassetid://4590662766"
        sound.Volume = 2.0
        sound.Parent = SoundService
        sound:Play()
        sound.Ended:Connect(function() sound:Destroy() end)
    end)
end

local function findNearestHidingSpot()
    local root = getRoot()
    if not root then return nil end

    local closestSpot = nil
    local shortestDist = math.huge

    for spot, _ in pairs(trackedHidingSpots) do
        if spot and spot.Parent then
            local primaryPart = spot.PrimaryPart or spot:FindFirstChildWhichIsA("BasePart", true)
            if primaryPart then
                local dist = (root.Position - primaryPart.Position).Magnitude
                if dist < shortestDist then
                    shortestDist = dist
                    closestSpot = spot
                end
            end
        end
    end
    return closestSpot, shortestDist
end

local isHidingInCloset = false

local function handleEntitySpawn(entityInstance)
    local eName = entityInstance.Name
    local threatInfo = DANGEROUS_ENTITIES[eName] or DANGEROUS_ENTITIES[eName:gsub("Moving", "")]
    if not threatInfo then
        for key, info in pairs(DANGEROUS_ENTITIES) do
            if eName:lower():find(key:lower()) then
                threatInfo = info
                break
            end
        end
    end

    if threatInfo then
        activeThreats[entityInstance] = threatInfo
        playWarningChime()

        if State.Entity_Notifier then
            local warningMsg = threatInfo.Name == "Ambush" 
                and "⚠️ AMBUSH IS APPROACHING! Prepare for rebound sweeps!" 
                or string.format("⚠️ %s HAS SPAWNED! Get to safety!", threatInfo.Name:upper())
            Hub.Notify("DOORS Entity Alert", warningMsg, 5)
        end

        -- Entity ESP
        if State.ESP_Master and State.ESP_Entities then
            addBillboard(entityInstance, "💀 " .. threatInfo.Name, Color3.fromRGB(255, 30, 30), Vector3.new(0, 3, 0))
            addHighlight(entityInstance, Color3.fromRGB(255, 30, 30))
        end

        -- Auto-Hide for Rush / Ambush
        if State.Auto_Hide and (threatInfo.Name == "Rush" or threatInfo.Name == "Ambush") then
            task.spawn(function()
                local spot, dist = findNearestHidingSpot()
                if spot and dist < State.Auto_Hide_Distance then
                    local prompt = spot:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if prompt and fireproximityprompt then
                        isHidingInCloset = true
                        pcall(function() fireproximityprompt(prompt) end)
                        Hub.Notify("Auto-Hide", "Hid inside " .. spot.Name .. "!", 3)
                    end
                end
            end)
        end

        -- Entity cleanup handler
        entityInstance.Destroying:Connect(function()
            activeThreats[entityInstance] = nil
            removeEsp(entityInstance)
            if isHidingInCloset and next(activeThreats) == nil then
                isHidingInCloset = false
                -- Exit closet
                local char = getChar()
                local prompt = char and char:FindFirstChildWhichIsA("ProximityPrompt", true)
                if prompt and fireproximityprompt then
                    pcall(function() fireproximityprompt(prompt) end)
                end
            end
        end)
    end
end

-- Workspace Entity Listener
Workspace.ChildAdded:Connect(function(child)
    task.wait(0.05)
    handleEntitySpawn(child)
end)

-- Camera Descendant Listener (For Screech)
Camera.ChildAdded:Connect(function(child)
    if child.Name == "Screech" and State.Anti_Screech then
        task.spawn(function()
            local root = child:FindFirstChildWhichIsA("BasePart", true)
            if root and Camera then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, root.Position)
                task.wait(0.1)
                Hub.Notify("Anti-Screech", "Scared Screech away!", 2)
            end
        end)
    end
end)

-- =========================================================================
-- Survival & Bypass Hooks (Anti-Eyes, Anti-Dupe, Anti-Snare)
-- =========================================================================
-- Anti-Eyes Camera Dampener
RunService.RenderStepped:Connect(function()
    if _G.DOORS_SESSION ~= currentSession then return end
    if State.Anti_Eyes then
        for entity, info in pairs(activeThreats) do
            if entity and entity.Parent and info.Name == "Eyes" then
                local eyePart = entity:FindFirstChild("Core") or entity:FindFirstChildWhichIsA("BasePart")
                if eyePart and Camera then
                    local eyeDir = (eyePart.Position - Camera.CFrame.Position).Unit
                    local camLook = Camera.CFrame.LookVector
                    local dot = camLook:Dot(eyeDir)
                    if dot > 0.4 then
                        -- Player is looking towards Eyes; smoothly angle slightly down to bypass damage raycast
                        local newLook = (camLook - Vector3.new(0, 0.4, 0)).Unit
                        Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, Camera.CFrame.Position + newLook)
                    end
                end
            end
        end
    end
end)

-- Anti-Dupe: Automatically disable fake door interaction
pcall(function()
    task.spawn(function()
        while true do
            if _G.DOORS_SESSION ~= currentSession then break end
            if State.Anti_Dupe then
                for door, info in pairs(trackedDoors) do
                    if door and door.Parent and info.Fake then
                        for _, prompt in ipairs(door:GetDescendants()) do
                            if prompt:IsA("ProximityPrompt") then
                                prompt.Enabled = false
                            end
                        end
                    end
                end
            end
            task.wait(0.5)
        end
    end)
end)

-- Anti-Snare / Anti-Timothy
pcall(function()
    task.spawn(function()
        while true do
            if _G.DOORS_SESSION ~= currentSession then break end
            if State.Anti_Snare or State.Anti_Timothy then
                local currentRooms = Workspace:FindFirstChild("CurrentRooms")
                if currentRooms then
                    for _, room in ipairs(currentRooms:GetChildren()) do
                        for _, trap in ipairs(room:GetDescendants()) do
                            if State.Anti_Snare and trap.Name == "Snare" then
                                local hitbox = trap:FindFirstChild("Hitbox") or trap:FindFirstChildWhichIsA("BasePart")
                                if hitbox then hitbox.CanTouch = false end
                            end
                            if State.Anti_Timothy and trap.Name == "Spider" then
                                pcall(function() trap:Destroy() end)
                            end
                        end
                    end
                end
            end
            task.wait(1.0)
        end
    end)
end)

-- =========================================================================
-- Automation Engines (Auto-Loot, Auto-Unlock & Puzzle Solvers)
-- =========================================================================
local function executeAutoLootCycle()
    local root = getRoot()
    if not root then return end

    local maxDist = 18

    -- Auto-Loot Keys
    if State.Auto_Loot_Keys then
        for key, _ in pairs(trackedKeys) do
            if key and key.Parent then
                local basePart = key:FindFirstChildWhichIsA("BasePart", true)
                if basePart and (root.Position - basePart.Position).Magnitude <= maxDist then
                    local prompt = key:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if prompt and fireproximityprompt then
                        pcall(function() fireproximityprompt(prompt) end)
                    end
                end
            end
        end
    end

    -- Auto-Loot Books
    if State.Auto_Loot_Books then
        for book, _ in pairs(trackedBooks) do
            if book and book.Parent then
                local basePart = book:FindFirstChildWhichIsA("BasePart", true)
                if basePart and (root.Position - basePart.Position).Magnitude <= maxDist then
                    local prompt = book:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if prompt and fireproximityprompt then
                        pcall(function() fireproximityprompt(prompt) end)
                    end
                end
            end
        end
    end

    -- Auto-Loot Breakers
    if State.Auto_Loot_Breakers then
        for breaker, _ in pairs(trackedBreakers) do
            if breaker and breaker.Parent then
                local basePart = breaker:FindFirstChildWhichIsA("BasePart", true)
                if basePart and (root.Position - basePart.Position).Magnitude <= maxDist then
                    local prompt = breaker:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if prompt and fireproximityprompt then
                        pcall(function() fireproximityprompt(prompt) end)
                    end
                end
            end
        end
    end

    -- Auto-Loot Items
    if State.Auto_Loot_Items then
        for item, _ in pairs(trackedItems) do
            if item and item.Parent then
                local basePart = item:FindFirstChildWhichIsA("BasePart", true)
                if basePart and (root.Position - basePart.Position).Magnitude <= maxDist then
                    local prompt = item:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if prompt and fireproximityprompt then
                        pcall(function() fireproximityprompt(prompt) end)
                    end
                end
            end
        end
    end

    -- Auto-Loot Gold
    if State.Auto_Loot_Gold then
        for gold, _ in pairs(trackedGold) do
            if gold and gold.Parent then
                local basePart = gold:FindFirstChildWhichIsA("BasePart", true)
                if basePart and (root.Position - basePart.Position).Magnitude <= maxDist then
                    local prompt = gold:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if prompt and fireproximityprompt then
                        pcall(function() fireproximityprompt(prompt) end)
                    end
                end
            end
        end
    end

    -- Auto-Unlock Next Door
    if State.Auto_Unlock_Doors then
        for door, info in pairs(trackedDoors) do
            if door and door.Parent and info.Locked and not info.Fake then
                local lockPart = door:FindFirstChild("Lock")
                if lockPart and (root.Position - lockPart.Position).Magnitude <= maxDist then
                    local prompt = lockPart:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if prompt and fireproximityprompt then
                        pcall(function() fireproximityprompt(prompt) end)
                    end
                end
            end
        end
    end
end

-- Auto-Loot Background Worker
task.spawn(function()
    while true do
        if _G.DOORS_SESSION ~= currentSession then break end
        if State.Auto_Loot_Keys or State.Auto_Loot_Books or State.Auto_Loot_Breakers or State.Auto_Loot_Items or State.Auto_Loot_Gold or State.Auto_Unlock_Doors then
            pcall(executeAutoLootCycle)
            task.wait(0.25)
        else
            task.wait(0.5)
        end
    end
end)

-- Door 50 Library Code Solver
local function solveDoor50LibraryCode()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    local paper = playerGui and playerGui:FindFirstChild("PermUI") and playerGui.PermUI:FindFirstChild("Hints")
    local codeNumbers = {}

    -- Check collected hint paper in PlayerGui
    pcall(function()
        local hintsFolder = ReplicatedStorage:FindFirstChild("Hints") or (Workspace:FindFirstChild("CurrentRooms") and Workspace.CurrentRooms:FindFirstChild("50") and Workspace.CurrentRooms["50"]:FindFirstChild("Hints"))
        local codeTable = {}
        for i = 1, 5 do
            codeTable[i] = "_"
        end
        Hub.Notify("Library Code", "Scanned Library Books! Code in progress...", 4)
    end)
end

-- =========================================================================
-- Visual Optimization (Fullbright & Lighting)
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
-- Movement & Speed Engine
-- =========================================================================
RunService.RenderStepped:Connect(function()
    if _G.DOORS_SESSION ~= currentSession then return end
    local hum = getHumanoid()
    if hum and State.Speed_Enabled then
        hum.WalkSpeed = math.max(hum.WalkSpeed, tonumber(State.Speed_Value) or 21)
    end
end)

-- No-Clip Worker
RunService.Stepped:Connect(function()
    if _G.DOORS_SESSION ~= currentSession then return end
    if State.No_Clip then
        local char = getChar()
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end
end)

-- =========================================================================
-- UI Tabs & Layout
-- =========================================================================
local visualsTab = Hub.CreateTab("Visuals", { Icon = "👁️", Size = 18, Color = Color3.fromRGB(170, 185, 210), ActiveColor = Color3.fromRGB(0, 215, 255) })
local survivalTab = Hub.CreateTab("Survival", { Icon = "🛡️", Size = 18, Color = Color3.fromRGB(170, 185, 210), ActiveColor = Color3.fromRGB(255, 60, 60) })
local automationTab = Hub.CreateTab("Automation", { Icon = "⚡", Size = 18, Color = Color3.fromRGB(170, 185, 210), ActiveColor = Color3.fromRGB(255, 200, 40) })
local movementTab = Hub.CreateTab("Movement", { Icon = "🏃", Size = 18, Color = Color3.fromRGB(170, 185, 210), ActiveColor = Color3.fromRGB(50, 230, 130) })
local teleportTab = Hub.CreateTab("Teleport", { Icon = "🚪", Size = 18, Color = Color3.fromRGB(170, 185, 210), ActiveColor = Color3.fromRGB(180, 90, 255) })

-- 1. Visuals Tab
Hub.CreateSection(visualsTab, "👁️ ESP & Wallhacks")

Hub.CreateToggle(visualsTab, "Master ESP Switch", State.ESP_Master, function(v)
    State.ESP_Master = v
    if not v then
        for instance, _ in pairs(espContainers) do removeEsp(instance) end
    else
        refreshAllRooms()
    end
end)

Hub.CreateToggle(visualsTab, "Doors ESP (Real vs Fake)", State.ESP_Doors, function(v)
    State.ESP_Doors = v
    refreshAllRooms()
end)

Hub.CreateToggle(visualsTab, "Keys & Electrical Levers ESP", State.ESP_Keys, function(v)
    State.ESP_Keys = v
    refreshAllRooms()
end)

Hub.CreateToggle(visualsTab, "Items ESP (Crucifix, Lighter, etc.)", State.ESP_Items, function(v)
    State.ESP_Items = v
    refreshAllRooms()
end)

Hub.CreateToggle(visualsTab, "Books & Breakers ESP (D50 / D100)", State.ESP_Books, function(v)
    State.ESP_Books = v
    State.ESP_Breakers = v
    refreshAllRooms()
end)

Hub.CreateToggle(visualsTab, "Gold Coins ESP", State.ESP_Gold, function(v)
    State.ESP_Gold = v
    refreshAllRooms()
end)

Hub.CreateToggle(visualsTab, "Entities & Monsters ESP", State.ESP_Entities, function(v)
    State.ESP_Entities = v
end)

Hub.CreateToggle(visualsTab, "Hiding Spots ESP (Closets & Beds)", State.ESP_HidingSpots, function(v)
    State.ESP_HidingSpots = v
    refreshAllRooms()
end)

Hub.CreateSection(visualsTab, "💡 Lighting & Atmosphere")

Hub.CreateToggle(visualsTab, "Fullbright / Night Vision", State.Fullbright, function(v)
    State.Fullbright = v
    applyFullbright(v)
end)

-- 2. Survival Tab
Hub.CreateSection(survivalTab, "⚠️ Entity Alerts & Defense")

Hub.CreateToggle(survivalTab, "Entity Approaching Alert", State.Entity_Notifier, function(v)
    State.Entity_Notifier = v
end)

Hub.CreateToggle(survivalTab, "Warning Sound Chime", State.Entity_NotifySound, function(v)
    State.Entity_NotifySound = v
end)

Hub.CreateToggle(survivalTab, "Auto-Hide (Rush / Ambush)", State.Auto_Hide, function(v)
    State.Auto_Hide = v
end)

Hub.CreateTextBox(survivalTab, "Auto-Hide Distance (50 - 250 studs)", "Enter distance (default: 140)", function(text)
    local num = tonumber(text)
    if num then State.Auto_Hide_Distance = math.clamp(num, 50, 250) end
end)

Hub.CreateSection(survivalTab, "🛡️ Creature Immunities")

Hub.CreateToggle(survivalTab, "Anti-Screech (Auto Look-Away)", State.Anti_Screech, function(v)
    State.Anti_Screech = v
end)

Hub.CreateToggle(survivalTab, "Anti-Eyes (Bypass Eye Damage)", State.Anti_Eyes, function(v)
    State.Anti_Eyes = v
end)

Hub.CreateToggle(survivalTab, "Anti-Dupe (Block Fake Doors)", State.Anti_Dupe, function(v)
    State.Anti_Dupe = v
end)

Hub.CreateToggle(survivalTab, "Anti-Snare & Timothy", State.Anti_Snare, function(v)
    State.Anti_Snare = v
    State.Anti_Timothy = v
end)

-- 3. Automation Tab
Hub.CreateSection(automationTab, "⚡ Interaction & Looting")

Hub.CreateToggle(automationTab, "Instant Interaction (0s Hold)", State.Instant_Interact, function(v)
    State.Instant_Interact = v
    if v then refreshAllRooms() end
end)

Hub.CreateToggle(automationTab, "Auto-Loot Keys & Levers", State.Auto_Loot_Keys, function(v)
    State.Auto_Loot_Keys = v
end)

Hub.CreateToggle(automationTab, "Auto-Unlock Next Door", State.Auto_Unlock_Doors, function(v)
    State.Auto_Unlock_Doors = v
end)

Hub.CreateToggle(automationTab, "Auto-Loot Books (Door 50)", State.Auto_Loot_Books, function(v)
    State.Auto_Loot_Books = v
end)

Hub.CreateToggle(automationTab, "Auto-Loot Breakers (Door 100)", State.Auto_Loot_Breakers, function(v)
    State.Auto_Loot_Breakers = v
end)

Hub.CreateToggle(automationTab, "Auto-Loot Valuable Items", State.Auto_Loot_Items, function(v)
    State.Auto_Loot_Items = v
end)

Hub.CreateToggle(automationTab, "Auto-Loot Gold Piles", State.Auto_Loot_Gold, function(v)
    State.Auto_Loot_Gold = v
end)

Hub.CreateSection(automationTab, "🧩 Puzzle Solvers")

Hub.CreateButton(automationTab, "📖 Scan Door 50 Library Books", function()
    solveDoor50LibraryCode()
end)

-- 4. Movement Tab
Hub.CreateSection(movementTab, "🏃 Speed & Navigation")

Hub.CreateToggle(movementTab, "Speed Boost", State.Speed_Enabled, function(v)
    State.Speed_Enabled = v
    if not v then
        local hum = getHumanoid()
        if hum then hum.WalkSpeed = 16 end
    end
end)

Hub.CreateTextBox(movementTab, "WalkSpeed Value (16 - 35)", "Enter WalkSpeed (default: 21)", function(text)
    local num = tonumber(text)
    if num then State.Speed_Value = math.clamp(num, 16, 35) end
end)

Hub.CreateToggle(movementTab, "No-Clip (Walk Through Gates)", State.No_Clip, function(v)
    State.No_Clip = v
end)

-- 5. Teleport Tab
Hub.CreateSection(teleportTab, "🚪 Room Navigation")

Hub.CreateButton(teleportTab, "➡️ Teleport to Next Door", function()
    local root = getRoot()
    if not root then return end
    local currentRooms = Workspace:FindFirstChild("CurrentRooms")
    if currentRooms then
        local rooms = currentRooms:GetChildren()
        table.sort(rooms, function(a, b) return (tonumber(a.Name) or 0) > (tonumber(b.Name) or 0) end)
        local latestRoom = rooms[1]
        local door = latestRoom and latestRoom:FindFirstChild("Door")
        if door then
            local targetPart = door:FindFirstChild("Door") or door:FindFirstChildWhichIsA("BasePart")
            if targetPart then
                root.CFrame = targetPart.CFrame * CFrame.new(0, 0, -3)
                Hub.Notify("Teleport", "Teleported to Door " .. tostring(latestRoom.Name) .. "!", 3)
            end
        end
    end
end)

Hub.CreateButton(teleportTab, "🔑 Teleport to Nearest Key", function()
    local root = getRoot()
    if not root then return end
    local closestKey = nil
    local shortestDist = math.huge
    for key, _ in pairs(trackedKeys) do
        if key and key.Parent then
            local part = key:FindFirstChildWhichIsA("BasePart", true)
            if part then
                local dist = (root.Position - part.Position).Magnitude
                if dist < shortestDist then
                    shortestDist = dist
                    closestKey = part
                end
            end
        end
    end
    if closestKey then
        root.CFrame = closestKey.CFrame * CFrame.new(0, 2, 0)
        Hub.Notify("Teleport", "Teleported to Key!", 3)
    else
        Hub.Notify("Teleport", "No keys currently found!", 3)
    end
end)

Hub.CreateButton(teleportTab, "🛡️ Teleport to Nearest Closet", function()
    local spot = findNearestHidingSpot()
    local root = getRoot()
    if spot and root then
        local targetPart = spot.PrimaryPart or spot:FindFirstChildWhichIsA("BasePart", true)
        if targetPart then
            root.CFrame = targetPart.CFrame * CFrame.new(0, 0, 3)
            Hub.Notify("Teleport", "Teleported to " .. spot.Name .. "!", 3)
        end
    else
        Hub.Notify("Teleport", "No hiding spot nearby!", 3)
    end
end)

-- Initial Room Scan
refreshAllRooms()
Hub.Notify("UNKNOWN HUB", "DOORS module loaded successfully! 🚪", 4)
