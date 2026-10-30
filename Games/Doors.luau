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
local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")

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
            pcall(function()
                for _, desc in ipairs(parent:GetDescendants()) do
                    if desc.Name == LIBRARY_NAME or desc.Name:find("Unknown_ESP") or desc.Name:find("Unknown_") then
                        pcall(function() desc:Destroy() end)
                    end
                end
            end)
        end
    end
end

-- =========================================================================
-- UnknownLibrary Dynamic Loader
-- =========================================================================
local ok, result = pcall(function()
    local source
    if readfile then
        pcall(function() source = readfile("UnknownLibrary.luau") end)
        if not source or #source < 100 then
            pcall(function() source = readfile("UnknownLibrary") end)
        end
    end
    if not source or #source < 100 then
        local cacheBuster = "?t=" .. tostring(os.time() or tick()) .. "_" .. tostring(math.random(1000, 9999))
        local fetchSuccess, fetchedSource = pcall(function()
            return game:HttpGet(LIBRARY_LINK .. cacheBuster)
        end)
        if fetchSuccess and fetchedSource and #fetchedSource > 100 then
            source = fetchedSource
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
    Enable_Jumping = false,
    Enable_Sliding = false,
    Noclip = false,
    Noclip_Speed = 22,
    Instant_Movement = true, -- No acceleration / instant directional turning without slipping on floor

    -- Anti-Cheat Bypass, Safe Teleports & Flight Subsystem
    Bypass_AntiCheat = true,
    Deflect_Glitch = true,
    Fly_Enabled = false,
    Fly_SafeBounds = true,
    Fly_Speed = 45,
    Fly_VerticalSpeed = 35,
    Teleport_Speed = 38,
    Safe_Roof_Station = false,
    Auto_Evacuate_Entities = false,
    ClickTP_Enabled = false,
    Target_Room_Number = 10,

    -- Main / Interactions
    Instant_Interact = false,
    Noclip_Interact = false,
    Range_Interact = false,
    Interact_MaxRange = 12,
    Auto_Interact = false,
    AutoInteract_Gold = true,
    AutoInteract_Items = true,
    AutoInteract_Keys = true,
    AutoInteract_Books = true,
    AutoInteract_Drawers = true,
    AutoInteract_Doors = true,
    AutoInteract_Levers = true,

    -- Auto Interact Dynamic Exclude List & Custom Keywords
    AutoInteract_Excludes = {
        ["Paintings & Pictures"] = true,
        ["Fake Doors (Dupe)"] = true,
        ["Wall Clocks & Bells"] = true,
        ["Light Switches & Lamps"] = true,
        ["Normal Exit Doors"] = false,
        ["Side Room Doors"] = false,
        ["Drawers & Desks"] = false,
        ["Gold & Coins"] = false,
        ["Keys & Skeleton Keys"] = false,
        ["Levers & Breakers"] = false,
        ["Books & Papers"] = false,
        ["Crucifix & Defense Items"] = false,
        ["Lighters & Flashlights"] = false,
        ["Health & Bandages"] = false,
        ["Lockpicks & Shears"] = false,
        ["Glitch Fragments"] = false,
    },
    AutoInteract_CustomKeywords = {},

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
    GlitchFragment_ESP = true,
    Auto_GetGlitchFragment = false,
    Glitch_Count = 0,
    ESP_Color_GlitchFragment = Color3.fromRGB(245, 50, 255),
    Show_Distance = true,
    Fullbright = true,

    -- ESP Customization & Appearance Configs
    ESP_TextSize = 15,
    ESP_FillTransparency = 0.5,
    ESP_OutlineTransparency = 0,
    ESP_OnlyCurrentRoom = true, -- Exclusively show doors and closets in current room only!
    ESP_RoomFilterMode = "Current Room Only",
    ESP_ColorTheme = "Default Vibrant",
    ESP_Color_Doors = Color3.fromRGB(0, 215, 255),
    ESP_Color_DoorsLocked = Color3.fromRGB(255, 175, 30),
    ESP_Color_Dupe = Color3.fromRGB(255, 35, 35),
    ESP_Color_Keys = Color3.fromRGB(255, 220, 50),
    ESP_Color_Items = Color3.fromRGB(160, 110, 255),
    ESP_Color_Entities = Color3.fromRGB(255, 35, 35),
    ESP_Color_Hiding = Color3.fromRGB(80, 220, 120),

    -- Entity Filters (Exclude/Include individual monster types)
    Entity_Show_Rush = true,
    Entity_Show_Ambush = true,
    Entity_Show_Figure = true,
    Entity_Show_Seek = true,
    Entity_Show_Eyes = true,
    Entity_Show_Halt = true,
    Entity_Show_Screech = true,
    Entity_Show_Giggle = true,
    Entity_Show_Grumble = true,
    Entity_Show_Gloombats = true,
    Entity_Show_Snare = true,
    Entity_Show_Timothy = true,
    Entity_Show_Rooms = true, -- A-60, A-90, A-120
    Entity_Show_Dread = true,
    Entity_Show_Other = true,

    -- Floor Hazards & Mechanics (Hotel, Mines & Rooms)
    Anti_Screech = true,
    Anti_Eyes = true,
    Anti_Dupe = true,
    Anti_Snare = true,
    Anti_Timothy = true,
    Anti_A90 = true,
    Anti_Giggle = true,
    Auto_Heartbeat = true,
    Auto_Library_Code = true,
    Auto_Breakers = false
}

-- Session lifecycle
_G.DOORS_SESSION = tick()
local currentSession = _G.DOORS_SESSION

-- Anti-AFK: Prevents 20-minute idle disconnects so session stays active while away
pcall(function()
    if getconnections then
        for _, conn in ipairs(getconnections(LocalPlayer.Idled)) do
            if conn.Disable then conn:Disable() elseif conn.Disconnect then conn:Disconnect() end
        end
    end
end)
LocalPlayer.Idled:Connect(function()
    pcall(function()
        local vu = game:GetService("VirtualUser")
        if vu then
            vu:CaptureController()
            vu:ClickButton2(Vector2.new(10, 10))
        end
    end)
end)

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

local function clearCategoryEsp(category)
    for owner, record in pairs(activeEspRecords) do
        if record.Category == category then
            removeEspFor(owner)
        end
    end
    if category == "Entities" then
        pcall(function()
            for _, desc in ipairs(Workspace:GetDescendants()) do
                if desc.Name == "Unknown_RoundedCube" then
                    desc:Destroy()
                end
            end
        end)
    end
end

local function clearEntitySubcategory(entityCategory)
    for owner, record in pairs(activeEspRecords) do
        if record.Category == "Entities" and record.EntityCategory == entityCategory then
            removeEspFor(owner)
        end
    end
end

local function clearAllEsp()
    for owner, record in pairs(activeEspRecords) do
        if record.Visuals then
            for _, obj in ipairs(record.Visuals) do
                pcall(function() obj:Destroy() end)
            end
        end
    end
    table.clear(activeEspRecords)

    -- Purge any orphaned Highlights and Billboards from CoreGui and gethui
    pcall(function()
        local uiContainers = { CoreGui }
        if gethui then
            local h = gethui()
            if h and h ~= CoreGui then table.insert(uiContainers, h) end
        end
        for _, container in ipairs(uiContainers) do
            for _, child in ipairs(container:GetChildren()) do
                if child.Name == "Unknown_ESP_Highlight" or child.Name == "Unknown_ESP_Billboard" then
                    child:Destroy()
                end
            end
        end
    end)

    -- Purge any orphaned rounded cubes and highlights from Workspace
    pcall(function()
        for _, desc in ipairs(Workspace:GetDescendants()) do
            if desc.Name == "Unknown_RoundedCube" or desc.Name == "Unknown_ESP_Highlight" or desc.Name == "Unknown_ESP_Billboard" then
                desc:Destroy()
            end
        end
    end)
end

local function createBillboard(adorneePart, baseText, color, offset)
    if not adorneePart or not adorneePart:IsA("BasePart") then return nil, nil end
    offset = offset or Vector3.new(0, 1.8, 0)

    local bb = Instance.new("BillboardGui")
    bb.Name = "Unknown_ESP_Billboard"
    bb.Adornee = adorneePart
    bb.AlwaysOnTop = true
    bb.Size = UDim2.new(0, 260, 0, 48)
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
    label.TextSize = State.ESP_TextSize or 15
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
    fillTrans = fillTrans or State.ESP_FillTransparency or 0.5
    outlineTrans = outlineTrans or State.ESP_OutlineTransparency or 0

    local hl = Instance.new("Highlight")
    hl.Name = "Unknown_ESP_Highlight"
    hl.Adornee = adornee
    hl.FillColor = color
    hl.FillTransparency = fillTrans
    hl.OutlineColor = color
    hl.OutlineTransparency = outlineTrans
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    -- CRITICAL: Highlight must be parented in 3D world (adornee or Camera or Workspace) to render through walls.
    -- Parenting to CoreGui causes Roblox engine to ignore it for 3D world space rendering!
    if adornee:IsA("Instance") and adornee.Parent then
        pcall(function() hl.Parent = adornee end)
    end
    if not hl.Parent then
        hl.Parent = Workspace.CurrentCamera or Workspace
    end
    return hl
end

local function createBoxAdornment(adorneePart, color)
    if not adorneePart or not adorneePart:IsA("BasePart") then return nil end
    local box = Instance.new("BoxHandleAdornment")
    box.Name = "Unknown_ESP_BoxAdornment"
    box.Adornee = adorneePart
    box.Size = adorneePart.Size + Vector3.new(0.08, 0.08, 0.08)
    box.Color3 = color
    box.Transparency = 0.45
    box.AlwaysOnTop = true
    box.ZIndex = 10
    box.Parent = adorneePart
    return box
end

local function refreshEspVisualSettings()
    for _, rec in pairs(activeEspRecords) do
        if rec.Label then
            rec.Label.TextSize = State.ESP_TextSize or 15
        end
        if rec.Visuals then
            for _, vis in ipairs(rec.Visuals) do
                if vis:IsA("Highlight") then
                    vis.FillTransparency = State.ESP_FillTransparency or 0.5
                    vis.OutlineTransparency = State.ESP_OutlineTransparency or 0
                elseif vis:IsA("BoxHandleAdornment") then
                    vis.Transparency = State.ESP_FillTransparency or 0.45
                end
            end
        end
    end
end

local function getObjectRoom(instance)
    if not instance then return nil, nil end
    local currentRooms = Workspace:FindFirstChild("CurrentRooms")
    if not currentRooms then return nil, nil end
    local cur = instance
    while cur and cur ~= Workspace and cur.Parent ~= Workspace do
        if cur.Parent == currentRooms then
            local num = tonumber(cur.Name) or cur:GetAttribute("RoomID")
            return cur, num
        end
        cur = cur.Parent
    end

    -- 2. Fallback: Spatial 3D Bounding Box match against rooms
    local instPos = instance:IsA("BasePart") and instance.Position 
        or (instance:IsA("Model") and (instance.PrimaryPart and instance.PrimaryPart.Position or instance:GetPivot().Position))
    if instPos then
        local bestRoom = nil
        local bestNum = nil
        local bestDist = math.huge
        for _, r in ipairs(currentRooms:GetChildren()) do
            local num = tonumber(r.Name)
            if num and r:IsA("Model") then
                local cf, size = r:GetBoundingBox()
                local rel = cf:PointToObjectSpace(instPos)
                if math.abs(rel.X) <= (size.X / 2 + 3) and math.abs(rel.Z) <= (size.Z / 2 + 3) and math.abs(rel.Y) <= (size.Y / 2 + 8) then
                    return r, num
                end
                local flatDist = (Vector2.new(cf.Position.X, cf.Position.Z) - Vector2.new(instPos.X, instPos.Z)).Magnitude
                if flatDist < bestDist then
                    bestDist = flatDist
                    bestRoom = r
                    bestNum = num
                end
            end
        end
        return bestRoom, bestNum
    end

    return nil, nil
end

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
    local mg = mgTable or getMainGameTable()
    if mg and (mg.hiding == true or mg.animating == true) then return true end
    return false
end

local lastKnownPlayerRoom = nil

local function getCurrentRoomNumber()
    -- 1. Real-time 3D Spatial Room Check (Room where the player is ACTUALLY physically standing!)
    local root = getRoot()
    local currentRooms = Workspace:FindFirstChild("CurrentRooms")
    if root and currentRooms then
        local rootPos = root.Position
        for _, r in ipairs(currentRooms:GetChildren()) do
            local num = tonumber(r.Name)
            if num and r:IsA("Model") then
                local cf, size = r:GetBoundingBox()
                local rel = cf:PointToObjectSpace(rootPos)
                if math.abs(rel.X) <= (size.X / 2 + 2) and math.abs(rel.Z) <= (size.Z / 2 + 2) and math.abs(rel.Y) <= (size.Y / 2 + 8) then
                    lastKnownPlayerRoom = num
                    return num
                end
            end
        end

        -- Nearest room center check (handles doorways, siderooms, and room boundary seams)
        local bestRoom = nil
        local bestDist = math.huge
        for _, r in ipairs(currentRooms:GetChildren()) do
            local num = tonumber(r.Name)
            if num and r:IsA("Model") then
                local cf = r:GetBoundingBox()
                local d = (Vector2.new(cf.Position.X, cf.Position.Z) - Vector2.new(rootPos.X, rootPos.Z)).Magnitude
                if d < bestDist then
                    bestDist = d
                    bestRoom = num
                end
            end
        end
        if bestRoom and bestDist < 150 then
            lastKnownPlayerRoom = bestRoom
            return bestRoom
        end
    end

    -- 2. Fallback to LocalPlayer attribute only when character root is unavailable
    local pAttr = LocalPlayer and LocalPlayer:GetAttribute("CurrentRoom")
    if pAttr ~= nil and tonumber(pAttr) then
        lastKnownPlayerRoom = tonumber(pAttr)
        return tonumber(pAttr)
    end

    local char = getChar()
    if char then
        local cAttr = char:GetAttribute("CurrentRoom")
        if cAttr ~= nil and tonumber(cAttr) then
            lastKnownPlayerRoom = tonumber(cAttr)
            return tonumber(cAttr)
        end
    end

    return lastKnownPlayerRoom or 0
end

local function registerEsp(owner, adorneePart, baseText, color, category, partsToHighlight, offset, roomNumber, extraVisuals, entityCategory)
    if not State.Master_ESP then return end
    if not adorneePart then return end

    -- Anti-flicker guard: if already registered, do NOT destroy and recreate visuals
    local existing = activeEspRecords[owner]
    if existing and existing.Adornee == adorneePart and existing.Category == category then
        if roomNumber then existing.RoomNumber = roomNumber end
        if entityCategory then existing.EntityCategory = entityCategory end
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
            -- Synchronize Highlight & Adornment colors immediately
            if existing.Visuals then
                for _, vis in ipairs(existing.Visuals) do
                    if vis:IsA("Highlight") then
                        vis.FillColor = color
                        vis.OutlineColor = color
                    elseif vis:IsA("SphereHandleAdornment") then
                        vis.Color3 = color
                    end
                end
            end
        end
        return
    end

    removeEspFor(owner)

    local visuals = {}
    local highlightMap = {}

    -- 1. Billboard with Distance
    local bb, label = createBillboard(adorneePart, baseText, color, offset)
    if bb then table.insert(visuals, bb) end

    -- 2. Precision Highlights (ONLY target visible parts, NEVER giant hitboxes)
    if partsToHighlight then
        if typeof(partsToHighlight) == "Instance" then
            local hl = createHighlight(partsToHighlight, color)
            if hl then
                table.insert(visuals, hl)
                highlightMap[hl] = partsToHighlight
            end
        elseif type(partsToHighlight) == "table" then
            for _, p in ipairs(partsToHighlight) do
                if p and p:IsA("BasePart") then
                    local hl = createHighlight(p, color)
                    if hl then
                        table.insert(visuals, hl)
                        highlightMap[hl] = p
                    end
                end
            end
        end
    end

    -- 3. Extra visuals (e.g. 3D SphereHandleAdornment for 2D monsters)
    if extraVisuals and type(extraVisuals) == "table" then
        for _, v in ipairs(extraVisuals) do
            table.insert(visuals, v)
        end
    end

    -- Immediate Room Visibility Initialization (Prevents 1-frame distant flash on room scan)
    local isRoomRestricted = (category == "Doors" or category == "HidingSpots")
    local curRoom = isRoomRestricted and getCurrentRoomNumber() or nil
    local initiallyVisible = true
    if isRoomRestricted then
        if State.ESP_OnlyCurrentRoom or State.ESP_RoomFilterMode == "Current Room Only" then
            initiallyVisible = (curRoom ~= nil and roomNumber ~= nil and roomNumber == curRoom)
        elseif State.ESP_RoomFilterMode == "Current & Next Room" then
            initiallyVisible = (curRoom == nil or roomNumber == nil or math.abs(roomNumber - curRoom) <= 1)
        else
            initiallyVisible = true
        end
        for _, vis in ipairs(visuals) do
            if vis:IsA("BillboardGui") or vis:IsA("SphereHandleAdornment") then
                vis.Enabled = initiallyVisible
            elseif vis:IsA("Highlight") then
                vis.Enabled = initiallyVisible
                if not initiallyVisible then
                    vis.Adornee = nil
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
        EntityCategory = entityCategory,
        Label = label,
        Visuals = visuals,
        HighlightMap = highlightMap,
        RoomNumber = roomNumber,
        CurrentlyVisible = initiallyVisible,
        LastDist = -1
    }

    -- Auto-cleanup on destroy
    pcall(function()
        owner.Destroying:Connect(function()
            removeEspFor(owner)
        end)
    end)
end

-- Continuous Room & Distance Update Loop (0.15s, Jitter-Free & Hardware-Slot Efficient)
task.spawn(function()
    while true do
        if _G.DOORS_SESSION ~= currentSession then break end
        if State.Master_ESP then
            local root = getRoot()
            local rootPos = root and root.Position or nil
            local curRoom = getCurrentRoomNumber()

            for owner, record in pairs(activeEspRecords) do
                if not owner or not owner.Parent or not record.Adornee or not record.Adornee.Parent then
                    removeEspFor(owner)
                else
                    -- 1. Room Visibility Filter (Exclusively show doors and closets in current room only!)
                    if record.Category == "Doors" then
                        local shouldShow = State.Doors_ESP
                        if shouldShow then
                            if State.ESP_OnlyCurrentRoom or State.ESP_RoomFilterMode == "Current Room Only" then
                                shouldShow = (curRoom ~= nil and record.RoomNumber ~= nil and record.RoomNumber == curRoom)
                            elseif State.ESP_RoomFilterMode == "Current & Next Room" then
                                shouldShow = (curRoom == nil or record.RoomNumber == nil or math.abs(record.RoomNumber - curRoom) <= 1)
                            else -- "All Rooms (Full Vision)"
                                shouldShow = true
                            end
                        end

                        if record.CurrentlyVisible ~= shouldShow then
                            record.CurrentlyVisible = shouldShow
                            if record.Visuals then
                                for _, vis in ipairs(record.Visuals) do
                                    if vis:IsA("BillboardGui") or vis:IsA("SphereHandleAdornment") then
                                        vis.Enabled = shouldShow
                                    elseif vis:IsA("Highlight") then
                                        vis.Enabled = shouldShow
                                        if not shouldShow then
                                            vis.Adornee = nil
                                        else
                                            vis.Adornee = (record.HighlightMap and record.HighlightMap[vis]) or record.Owner
                                        end
                                    end
                                end
                            end
                        end
                    elseif record.Category == "HidingSpots" then
                        local shouldShow = State.HidingSpots_ESP
                        if shouldShow then
                            if State.ESP_OnlyCurrentRoom or State.ESP_RoomFilterMode == "Current Room Only" then
                                shouldShow = (curRoom ~= nil and record.RoomNumber ~= nil and record.RoomNumber == curRoom)
                            elseif State.ESP_RoomFilterMode == "Current & Next Room" then
                                shouldShow = (curRoom == nil or record.RoomNumber == nil or math.abs(record.RoomNumber - curRoom) <= 1)
                            else -- "All Rooms (Full Vision)"
                                shouldShow = true
                            end
                            -- Proximity safety: ALWAYS show closets in the immediate vicinity (<= 55 studs) of the player
                            if not shouldShow and rootPos and record.Adornee and record.Adornee.Parent then
                                local dist = (rootPos - record.Adornee.Position).Magnitude
                                if dist <= 55 then
                                    shouldShow = true
                                end
                            end
                        end

                        -- Only perform visual property & highlight adornee updates on actual state transitions (eliminates jitter and highlight slot churn!)
                        if record.CurrentlyVisible ~= shouldShow then
                            record.CurrentlyVisible = shouldShow
                            if record.Visuals then
                                for _, vis in ipairs(record.Visuals) do
                                    if vis:IsA("BillboardGui") or vis:IsA("SphereHandleAdornment") then
                                        vis.Enabled = shouldShow
                                    elseif vis:IsA("Highlight") then
                                        vis.Enabled = shouldShow
                                        if not shouldShow then
                                            vis.Adornee = nil
                                        else
                                            vis.Adornee = (record.HighlightMap and record.HighlightMap[vis]) or record.Owner
                                        end
                                    end
                                end
                            end
                        end
                    end

                    -- 2. Distance Text Update (Only updates visible records when integer distance changes)
                    local isVisible = (record.Category ~= "Doors" and record.Category ~= "HidingSpots") or (record.CurrentlyVisible == true)
                    if isVisible and State.Show_Distance and rootPos and record.Label and record.Adornee and record.Adornee.Parent then
                        local dist = math.floor((rootPos - record.Adornee.Position).Magnitude)
                        if dist ~= record.LastDist then
                            record.LastDist = dist
                            record.Label.Text = string.format("%s [%dm]", record.BaseText, dist)
                        end
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

-- 1. Precision Door Scanner (Highlights clean door leaf & verified padlock only)
local function processDoor(room, doorModel)
    if not doorModel then return end
    if not State.Doors_ESP then
        removeEspFor(doorModel)
        return
    end

    local roomNumber = tonumber(room.Name)

    -- Case 1: Standalone dupeDoor BasePart / MeshPart
    if doorModel:IsA("BasePart") then
        local doorMesh = doorModel
        local baseText = "Dupe Door"
        local color = Color3.fromRGB(255, 35, 35)
        registerEsp(doorModel, doorMesh, baseText, color, "Doors", doorMesh, Vector3.new(0, 1.2, 0), roomNumber)
        return
    end

    if not doorModel:IsA("Model") then return end

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

    -- Real playable DOORS exit doors must have 'Door' MeshPart
    local doorMesh = doorModel:FindFirstChild("Door")
    if not doorMesh or not doorMesh:IsA("BasePart") then
        doorMesh = doorModel:FindFirstChildWhichIsA("MeshPart") or doorModel:FindFirstChildWhichIsA("BasePart")
    end
    if not doorMesh then return end

    -- Verify door has real interactable open components (excludes fake room decor doors)
    local isFake = doorModel.Name == "DoorFake" or dName:find("fake") or (doorModel.Parent and doorModel.Parent.Name:lower():find("dupe"))
    if not isFake and not (doorModel:FindFirstChild("ClientOpen") or doorModel:FindFirstChild("Hidden") or doorModel:FindFirstChild("Hinge") or doorModel:FindFirstChild("HingeConstraint") or doorModel:GetAttribute("ESP_Hooked") or doorModel:GetAttribute("Opened") or doorModel:FindFirstChild("Open")) then
        removeEspFor(doorModel)
        return
    end

    -- Precision Lock Detection:
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
    local isDupe = isFake or doorModel:GetAttribute("DupeRoom") or doorModel:GetAttribute("Fake") or dName:find("fake") or dName:find("dupe")

    local signPart = doorModel:FindFirstChild("Sign")
    local signLabel = signPart and signPart:FindFirstChildWhichIsA("TextLabel", true)
    local signText = signLabel and signLabel.Text or nil

    local roomNum = tonumber(room.Name)
    local signNum = tonumber(signText)
    if roomNum and signNum and signNum ~= (roomNum + 1) then
        isDupe = true
    end

    -- Door Passability & Collision Smoothing:
    -- When a door opens or is unlocked, disable collisions on the swinging door leaf and collision barrier
    -- so high-speed walking never clips the door edge or frame and causes physics rebound snaps.
    local isOpened = doorModel:GetAttribute("Opened") == true 
        or doorModel:FindFirstChild("ClientOpen") ~= nil
        or doorModel:GetAttribute("Open") == true

    for _, ch in ipairs(doorModel:GetDescendants()) do
        if ch:IsA("BasePart") then
            local chName = ch.Name:lower()
            if chName == "hidden" or chName == "collision" then
                ch.Transparency = 1
            end
            if isOpened and not chName:find("frame") then
                ch.CanCollide = false
            end
        end
    end

    local doorNumberStr = signText or tostring(room.Name)
    local baseText
    local color

    if isDupe then
        baseText = "Dupe Door"
        color = State.ESP_Color_Dupe
    elseif isLocked then
        baseText = string.format("Door %s [LOCKED]", doorNumberStr)
        color = State.ESP_Color_DoorsLocked
    else
        baseText = string.format("Door %s", doorNumberStr)
        color = State.ESP_Color_Doors
    end

    local adorneePart = doorModel:FindFirstChild("SignPhysical") 
        or (doorModel:FindFirstChild("Sign") and doorModel.Sign:IsA("BasePart") and doorModel.Sign)
        or doorMesh

    -- Clean Unified Door Highlight: Highlighting the Model outlines the complete solid door leaf, sign, and padlock without internal wireframe cuts
    registerEsp(doorModel, adorneePart, baseText, color, "Doors", doorModel, Vector3.new(0, 1.2, 0), roomNumber)

    -- Lifecycle listener: automatically update if lock is removed or room scripts finish loading
    if not doorModel:GetAttribute("ESP_Hooked") then
        doorModel:SetAttribute("ESP_Hooked", true)
        pcall(function()
            local function onDoorStateChanged()
                task.wait(0.05)
                if doorModel.Parent then
                    local nowOpened = doorModel:GetAttribute("Opened") == true 
                        or doorModel:FindFirstChild("ClientOpen") ~= nil
                        or doorModel:GetAttribute("Open") == true
                    if nowOpened then
                        for _, ch in ipairs(doorModel:GetDescendants()) do
                            if ch:IsA("BasePart") and not ch.Name:lower():find("frame") then
                                ch.CanCollide = false
                            end
                        end
                    end
                    processDoor(room, doorModel)
                end
            end
            doorModel.ChildAdded:Connect(onDoorStateChanged)
            doorModel.ChildRemoved:Connect(onDoorStateChanged)
            doorModel.AttributeChanged:Connect(onDoorStateChanged)
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
    "lightfixture", "sconce", "hook", "fixture", "helpfullight", "wire", "pipe", "crate",
    "shadow", "node", "spawn", "point", "waypoint", "decor", "dresser", "wardrobe",
    "closet", "locker", "frame", "railing", "trim", "support", "beam", "plank"
}

local function isValidLootItem(model)
    if not model or not (model:IsA("Model") or model:IsA("Tool")) then return false, nil end
    local lower = model.Name:lower()

    -- Reject entire room structures, shops, siderooms, hallways, walls, fixtures
    if lower:find("room") or lower:find("shop") or lower:find("assets") or lower:find("structure")
        or lower:find("hallway") or lower:find("elevator") or lower:find("sideroom") or lower:find("rift")
        or lower:find("wall") or lower:find("ceiling") or lower:find("floor") or lower:find("desk")
        or lower:find("drawer") or lower:find("cabinet") or lower:find("table") or lower:find("skulllock")
        or lower:find("riftdoor") or lower:find("riftspawn") then
        return false, nil
    end

    -- Physical Size Check: In DOORS, loot items are small props (strictly < 8 studs on every axis)
    if model:IsA("Model") then
        local cf, sz = model:GetBoundingBox()
        if sz.X > 8 or sz.Y > 8 or sz.Z > 8 then
            return false, nil
        end
    end

    -- Reject blacklist decor & furniture
    for _, blocked in ipairs(DECOR_BLACKLIST) do
        if lower:find(blocked) then
            return false, nil
        end
    end

    if lower:find("keyobtain") or lower:find("gold") or lower:find("coin") or lower:find("door") or lower:find("lever")
        or lower:find("painting") or lower:find("picture") or lower:find("canvas") or lower:find("frame") or lower:find("portrait") or lower:find("photo") then
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

    -- Guard against parent models adopting prompts belonging to deep nested child models
    if prompt.Parent and prompt.Parent.Parent and prompt.Parent.Parent:IsA("Model") and prompt.Parent.Parent ~= model then
        return false, nil
    end

    local action = (prompt.ActionText or ""):lower()
    local isPickup = action:find("take") or action:find("obtain") or action:find("steal") 
        or action:find("grab") or action:find("pick") or action:find("equip") or action:find("collect")
    if not isPickup then
        return false, nil
    end

    local promptObjectName = (prompt.ObjectText and #prompt.ObjectText > 0) and prompt.ObjectText:lower() or ""

    -- Strictly reject containers, furniture, mechanisms, doors, lights, paintings, and decor
    local forbiddenPromptWords = {
        "gold", "coin", "painting", "picture", "canvas", "frame", "portrait", "photo",
        "drawer", "knob", "desk", "table", "dresser", "container", "chest", "shelf",
        "closet", "wardrobe", "locker", "bed", "door", "gate", "lever", "switch",
        "button", "wheel", "valve", "lock", "padlock", "keyhole", "window", "curtain",
        "lamp", "light", "bell", "clock", "breaker"
    }
    for _, bad in ipairs(forbiddenPromptWords) do
        if promptObjectName == bad or promptObjectName:find(bad) or lower:find(bad) then
            return false, nil
        end
    end

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

    -- Priority 3: Check Paper (Clean simple name "Paper" instead of "An Inconspicious Piece Of Paper")
    if promptObjectName:find("paper") or lower:find("paper") or lower:find("hintpaper") then
        return true, "Paper"
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

    -- Fallback exclusively for Tool instances with non-decor pickup prompts
    if model:IsA("Tool") and #promptObjectName > 1 then
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

-- 4. Precision Books Scanner (ONLY in Room 50 Library - Named cleanly as "Book")
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
            local baseText = "Book"
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

-- 6. Precision Hiding Spot Scanner (Wardrobes, Closets, Lockers, Beds with active Hide prompt - Room Restricted!)
local function processHidingSpot(hidingModel, room)
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

                local roomNumber = (room and tonumber(room.Name)) or select(2, getObjectRoom(hidingModel))
                registerEsp(hidingModel, targetPart, baseText, color, "HidingSpots", hidingModel, Vector3.new(0, 2.5, 0), roomNumber)
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

    if goldInstance:IsA("ProximityPrompt") then
        goldInstance = goldInstance.Parent
    end
    if not goldInstance then return end

    -- Normalize owner to top-level Gold model if nested inside one
    local owner = goldInstance
    local cur = goldInstance
    while cur and cur.Parent and cur.Parent ~= Workspace and cur.Parent.Name ~= "CurrentRooms" and not cur.Parent.Name:find("Assets") do
        local pName = cur.Parent.Name:lower()
        if cur.Parent:IsA("Model") and (pName:find("gold") or pName:find("coin")) then
            owner = cur.Parent
            break
        end
        cur = cur.Parent
    end

    local gName = owner.Name:lower()
    local isGold = gName == "goldpile" or gName:find("gold") or gName:find("coin")

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
        -- Strict Spatial Deduplication: Prevent any second "Gold" text within 2.5 studs!
        for otherOwner, rec in pairs(activeEspRecords) do
            if rec.Category == "Gold" and otherOwner ~= owner and rec.AdorneePart then
                if (rec.AdorneePart.Position - targetPart.Position).Magnitude < 2.5 then
                    return
                end
            end
        end

        local baseText = displayName
        local color = Color3.fromRGB(255, 195, 0)
        registerEsp(owner, targetPart, baseText, color, "Gold", owner, Vector3.new(0, 0.8, 0))
    end
end

-- 8. Comprehensive Entity ESP (Every Monster in DOORS Hotel, The Mines & The Rooms)
local ENTITY_REGISTRY = {
    -- Hotel Main Roster
    ["rushmoving"]     = { Name = "Rush",               Category = "Rush" },
    ["rushnew"]        = { Name = "Rush",               Category = "Rush" },
    ["rush"]           = { Name = "Rush",               Category = "Rush" },
    ["ambushmoving"]   = { Name = "Ambush",             Category = "Ambush" },
    ["ambush"]         = { Name = "Ambush",             Category = "Ambush" },
    ["figurerig"]      = { Name = "Figure",             Category = "Figure" },
    ["figure"]         = { Name = "Figure",             Category = "Figure" },
    ["seekmoving"]     = { Name = "Seek",               Category = "Seek" },
    ["seekrig"]        = { Name = "Seek",               Category = "Seek" },
    ["seekarm"]        = { Name = "Seek Arm",           Category = "Seek" },
    ["eyes"]           = { Name = "Eyes (Don't Look!)", Category = "Eyes" },
    ["lookman"]        = { Name = "Lookman",            Category = "Eyes" },
    ["eyesretro"]      = { Name = "Retro Eyes",         Category = "Eyes" },
    ["halt"]           = { Name = "Halt",               Category = "Halt" },
    ["shade"]          = { Name = "Halt",               Category = "Halt" },
    ["screech"]        = { Name = "Screech",            Category = "Screech" },
    ["screechretro"]   = { Name = "Retro Screech",      Category = "Screech" },
    ["dread"]          = { Name = "Dread",              Category = "Dread" },
    ["timothy"]        = { Name = "Timothy",            Category = "Timothy" },
    ["spider"]         = { Name = "Timothy",            Category = "Timothy" },
    ["spiderjumpscare"]= { Name = "Timothy",            Category = "Timothy" },
    ["snare"]          = { Name = "Snare Trap",         Category = "Snare" },
    ["snaretrap"]      = { Name = "Snare Trap",         Category = "Snare" },

    -- Floor 2: The Mines
    ["giggleceiling"]  = { Name = "Giggle",             Category = "Giggle" },
    ["giggle"]         = { Name = "Giggle",             Category = "Giggle" },
    ["gigglerig"]      = { Name = "Giggle",             Category = "Giggle" },
    ["grumble"]        = { Name = "Grumble",            Category = "Grumble" },
    ["grumblerig"]     = { Name = "Grumble",            Category = "Grumble" },
    ["queen"]          = { Name = "Grumble Queen",      Category = "Grumble" },
    ["gloombats"]      = { Name = "Gloombats",          Category = "Gloombats" },
    ["gloombat"]       = { Name = "Gloombats",          Category = "Gloombats" },

    -- The Rooms (A-1000)
    ["a60"]            = { Name = "A-60",               Category = "Rooms" },
    ["a-60"]           = { Name = "A-60",               Category = "Rooms" },
    ["a90"]            = { Name = "A-90",               Category = "Rooms" },
    ["a-90"]           = { Name = "A-90",               Category = "Rooms" },
    ["a120"]           = { Name = "A-120",              Category = "Rooms" },
    ["a-120"]          = { Name = "A-120",              Category = "Rooms" },

    -- Special & Rare / Modifiers
    ["glitch"]         = { Name = "Glitch",             Category = "Other" },
    ["void"]           = { Name = "Void",               Category = "Other" },
    ["shadow"]         = { Name = "Shadow",             Category = "Other" },
    ["sally"]          = { Name = "Sally",              Category = "Other" },
    ["jack"]           = { Name = "Jack",               Category = "Other" },
    ["blitz"]          = { Name = "Blitz",              Category = "Other" },
    ["depth"]          = { Name = "Depth",              Category = "Other" },
    ["silence"]        = { Name = "Silence",            Category = "Other" },
    ["greed"]          = { Name = "Greed",              Category = "Other" },
}

local function createRoundedCubeModel(targetPart, size, radius, color)
    if not targetPart or not targetPart.Parent then return nil end
    local model = Instance.new("Model")
    model.Name = "Unknown_RoundedCube"

    local s = size or 5.0
    local r = radius or 0.85
    local inner = math.max(s - 2 * r, 0.5)
    local d = 2 * r

    -- Central core block
    local core = Instance.new("Part")
    core.Name = "Core"
    core.Size = Vector3.new(inner, inner, inner)
    core.Color = color
    core.Transparency = 0.45
    core.Material = Enum.Material.SmoothPlastic
    core.CanCollide = false
    core.CanTouch = false
    core.CanQuery = false
    core.Massless = true
    core.CastShadow = false
    core.Anchored = true
    core.CFrame = targetPart.CFrame
    core.Parent = model

    -- 6 Face slabs: extending from inner core to outer faces
    local faceConfigs = {
        { size = Vector3.new(inner, inner, r), offset = Vector3.new(0, 0, inner/2 + r/2) },
        { size = Vector3.new(inner, inner, r), offset = Vector3.new(0, 0, -(inner/2 + r/2)) },
        { size = Vector3.new(inner, r, inner), offset = Vector3.new(0, inner/2 + r/2, 0) },
        { size = Vector3.new(inner, r, inner), offset = Vector3.new(0, -(inner/2 + r/2), 0) },
        { size = Vector3.new(r, inner, inner), offset = Vector3.new(inner/2 + r/2, 0, 0) },
        { size = Vector3.new(r, inner, inner), offset = Vector3.new(-(inner/2 + r/2), 0, 0) },
    }
    for i, cfg in ipairs(faceConfigs) do
        local face = Instance.new("Part")
        face.Name = "Face_" .. i
        face.Size = cfg.size
        face.Color = color
        face.Transparency = 0.45
        face.Material = Enum.Material.SmoothPlastic
        face.CanCollide = false
        face.CanTouch = false
        face.CanQuery = false
        face.Massless = true
        face.CastShadow = false
        face.Anchored = true
        face.CFrame = core.CFrame * CFrame.new(cfg.offset)
        face.Parent = model
    end

    -- 8 Corner Spheres
    local signs = {-1, 1}
    for _, sx in ipairs(signs) do
        for _, sy in ipairs(signs) do
            for _, sz in ipairs(signs) do
                local sphere = Instance.new("Part")
                sphere.Name = "CornerSphere"
                sphere.Shape = Enum.PartType.Ball
                sphere.Size = Vector3.new(d, d, d)
                sphere.Color = color
                sphere.Transparency = 0.45
                sphere.Material = Enum.Material.SmoothPlastic
                sphere.CanCollide = false
                sphere.CanTouch = false
                sphere.CanQuery = false
                sphere.Massless = true
                sphere.CastShadow = false
                sphere.Anchored = true
                sphere.CFrame = core.CFrame * CFrame.new(sx * (inner/2), sy * (inner/2), sz * (inner/2))
                sphere.Parent = model
            end
        end
    end

    -- 12 Edge Cylinders
    -- X-axis edges (4): length along X
    for _, sy in ipairs(signs) do
        for _, sz in ipairs(signs) do
            local cyl = Instance.new("Part")
            cyl.Name = "EdgeCyl_X"
            cyl.Shape = Enum.PartType.Cylinder
            cyl.Size = Vector3.new(inner, d, d)
            cyl.Color = color
            cyl.Transparency = 0.45
            cyl.Material = Enum.Material.SmoothPlastic
            cyl.CanCollide = false
            cyl.CanTouch = false
            cyl.CanQuery = false
            cyl.Massless = true
            cyl.CastShadow = false
            cyl.Anchored = true
            cyl.CFrame = core.CFrame * CFrame.new(0, sy * (inner/2), sz * (inner/2))
            cyl.Parent = model
        end
    end
    -- Y-axis edges (4): length along Y (Cylinder X rotated to Y)
    for _, sx in ipairs(signs) do
        for _, sz in ipairs(signs) do
            local cyl = Instance.new("Part")
            cyl.Name = "EdgeCyl_Y"
            cyl.Shape = Enum.PartType.Cylinder
            cyl.Size = Vector3.new(inner, d, d)
            cyl.Color = color
            cyl.Transparency = 0.45
            cyl.Material = Enum.Material.SmoothPlastic
            cyl.CanCollide = false
            cyl.CanTouch = false
            cyl.CanQuery = false
            cyl.Massless = true
            cyl.CastShadow = false
            cyl.Anchored = true
            cyl.CFrame = core.CFrame * CFrame.new(sx * (inner/2), 0, sz * (inner/2)) * CFrame.Angles(0, 0, math.pi / 2)
            cyl.Parent = model
        end
    end
    -- Z-axis edges (4): length along Z (Cylinder X rotated to Z)
    for _, sx in ipairs(signs) do
        for _, sy in ipairs(signs) do
            local cyl = Instance.new("Part")
            cyl.Name = "EdgeCyl_Z"
            cyl.Shape = Enum.PartType.Cylinder
            cyl.Size = Vector3.new(inner, d, d)
            cyl.Color = color
            cyl.Transparency = 0.45
            cyl.Material = Enum.Material.SmoothPlastic
            cyl.CanCollide = false
            cyl.CanTouch = false
            cyl.CanQuery = false
            cyl.Massless = true
            cyl.CastShadow = false
            cyl.Anchored = true
            cyl.CFrame = core.CFrame * CFrame.new(sx * (inner/2), sy * (inner/2), 0) * CFrame.Angles(0, math.pi / 2, 0)
            cyl.Parent = model
        end
    end

    model.PrimaryPart = core
    model.Parent = Workspace

    -- Active RenderStepped tracking: continuously synchronizes rounded cube to the moving 2D entity
    local followConn
    followConn = RunService.RenderStepped:Connect(function()
        if not targetPart or not targetPart.Parent or not model.Parent then
            if followConn then followConn:Disconnect() end
            return
        end
        model:PivotTo(targetPart.CFrame)
    end)
    model.Destroying:Connect(function()
        if followConn then followConn:Disconnect() end
    end)

    return model
end

local function processEntity(entity)
    if not entity or not entity.Parent then return end
    if not State.Entities_ESP or not State.Master_ESP then
        removeEspFor(entity)
        return
    end

    local eLower = entity.Name:lower()

    -- 1. Anti-Player & Anti-Character Check
    if entity:IsA("Model") and Players:GetPlayerFromCharacter(entity) then return end
    local char = getChar()
    if char and (entity == char or entity:IsDescendantOf(char)) then return end

    -- 2. Reject Camera viewmodel parts (arms, items, baserig, clothing)
    -- In DOORS, Camera contains the first-person viewmodel ("baserig") and held tool models.
    -- ONLY Screech and jumpscare spiders are valid entities inside Camera.
    if Camera and (entity.Parent == Camera or entity:IsDescendantOf(Camera)) then
        local isCameraMonster = eLower:find("screech") or eLower:find("spider") or eLower:find("timothy")
        if not isCameraMonster then
            return
        end
    end

    -- 3. Reject Viewmodel, Shop NPCs, and harmless entities
    if eLower == "baserig" or eLower:find("viewmodel") or eLower:find("bob") or eLower:find("elgoblino") or (eLower:find("jeff") and not eLower:find("killer")) then
        return
    end

    -- 4. Strictly ignore Dupe & SideroomDupe in entity scanner (Dupe is ONLY shown as a Door!)
    if eLower:find("dupe") or eLower:find("doorfake") or (entity.Parent and entity.Parent.Name:lower():find("dupe")) or eLower:find("sideroom") then
        return
    end

    -- 5. Strictly reject any furniture, decor, room structure, fixtures, lights, or beds
    for _, blocked in ipairs(DECOR_BLACKLIST) do
        if eLower == blocked or eLower:find("^" .. blocked) or eLower:find("_" .. blocked) or eLower:find(blocked .. "$") or eLower:find(blocked) then
            return
        end
    end

    -- 6. CurrentRooms Descendant Check:
    -- Roaming monsters in DOORS do NOT spawn as static children of room furniture or rooms.
    -- If an object is inside CurrentRooms, it can ONLY be an entity if it is explicitly Snare, Giggle, FigureRig, Grumble, Seek, or Sally.
    local currentRooms = Workspace:FindFirstChild("CurrentRooms")
    if currentRooms and entity:IsDescendantOf(currentRooms) then
        local isRoomMonster = eLower:find("snare") or eLower:find("giggle") or eLower:find("figure") or eLower:find("grumble") or eLower:find("seek") or eLower:find("sally")
        if not isRoomMonster then
            return
        end
    end

    -- Real DOORS monsters are always Models (except floor Snare traps)
    if not entity:IsA("Model") and not eLower:find("snare") then
        return
    end

    -- 7. Strict Entity Identification against verified monsters only
    local cfg = nil
    if eLower == "rush" or eLower:find("rushmoving") or eLower:find("rushnew") or (eLower:find("rush") and entity:IsA("Model")) then
        cfg = { Name = "Rush", Category = "Rush" }
    elseif eLower == "ambush" or eLower:find("ambushmoving") or (eLower:find("ambush") and entity:IsA("Model")) then
        cfg = { Name = "Ambush", Category = "Ambush" }
    elseif eLower:find("figure") then
        cfg = { Name = "Figure", Category = "Figure" }
    elseif eLower == "seek" or eLower:find("^seek") or eLower:find("seekmoving") or eLower:find("seekrig") then
        cfg = { Name = "Seek", Category = "Seek" }
    elseif eLower == "eyes" or eLower:find("^eyes") or eLower:find("lookman") or eLower:find("eyesretro") then
        cfg = { Name = "Eyes (Don't Look!)", Category = "Eyes" }
    elseif eLower == "halt" or eLower:find("^halt") or eLower == "shade" then
        cfg = { Name = "Halt", Category = "Halt" }
    elseif eLower:find("screech") then
        cfg = { Name = "Screech", Category = "Screech" }
    elseif eLower == "dread" then
        cfg = { Name = "Dread", Category = "Dread" }
    elseif eLower == "timothy" or eLower:find("spiderjumpscare") or eLower == "spider" then
        cfg = { Name = "Timothy", Category = "Timothy" }
    elseif eLower:find("snare") then
        cfg = { Name = "Snare Trap", Category = "Snare" }
    elseif eLower:find("giggle") then
        cfg = { Name = "Giggle", Category = "Giggle" }
    elseif eLower:find("grumble") or eLower == "queen" or eLower == "grumblequeen" then
        cfg = { Name = (eLower:find("queen") and "Grumble Queen" or "Grumble"), Category = "Grumble" }
    elseif eLower:find("gloombat") then
        cfg = { Name = "Gloombats", Category = "Gloombats" }
    elseif eLower == "a60" or eLower == "a-60" or eLower:find("^a%-?60") then
        cfg = { Name = "A-60", Category = "Rooms" }
    elseif eLower == "a90" or eLower == "a-90" or eLower:find("^a%-?90") then
        cfg = { Name = "A-90", Category = "Rooms" }
    elseif eLower == "a120" or eLower == "a-120" or eLower:find("^a%-?120") then
        cfg = { Name = "A-120", Category = "Rooms" }
    elseif eLower == "glitch" or eLower:find("^glitch") then
        cfg = { Name = "Glitch", Category = "Other" }
    elseif eLower == "void" then
        cfg = { Name = "Void", Category = "Other" }
    elseif (eLower == "sally" or eLower == "sallyrig" or eLower:find("^sally")) and entity:IsA("Model") then
        cfg = { Name = "Sally", Category = "Other" }
    elseif eLower == "jack" and entity:IsA("Model") then
        cfg = { Name = "Jack", Category = "Other" }
    elseif eLower:find("nextbot") then
        cfg = { Name = entity.Name, Category = "Other" }
    end

    if not cfg then
        return
    end

    -- [Auto-Evacuate / Auto-Hide Completely Eradicated per Daddy's Orders]

    -- 8. Check Entity Filter / Exclude List (Multi-Choice Dynamic Filter)
    if State.Entity_ESP_Filters and cfg.Category and State.Entity_ESP_Filters[cfg.Category] == false then
        removeEspFor(entity)
        return
    end

    -- Anti-Leak Guard: If already actively registered, do not recreate rounded cubes or reallocate models!
    if activeEspRecords[entity] and activeEspRecords[entity].Category == "Entities" then
        return
    end

    local targetPart = (entity:IsA("Model") and (entity.PrimaryPart or entity:FindFirstChild("RushNew") or entity:FindFirstChild("Root") or entity:FindFirstChild("Core") or entity:FindFirstChildWhichIsA("BasePart", true)))
        or (entity:IsA("BasePart") and entity)

    if targetPart then
        local highlightTarget = entity
        local extraVisuals = {}
        local entityColor = State.ESP_Color_Entities or Color3.fromRGB(255, 35, 35)

        -- Exclusively target verified 2D sprite entities (A-60, A-90, A-120, Rush, Ambush, Nextbots, Dread, Glitch)
        local is2D = (cfg.Category == "Rooms")
            or (cfg.Category == "Rush")
            or (cfg.Category == "Ambush")
            or (cfg.Category == "Dread")
            or (cfg.Name == "Glitch")
            or eLower:find("nextbot")

        if is2D then
            -- Procedural 3D Cube with smooth rounded corners and rounded edges
            local roundedCube = createRoundedCubeModel(targetPart, 5.0, 0.85, entityColor)
            if roundedCube then
                table.insert(extraVisuals, roundedCube)
                highlightTarget = roundedCube
            end
        else
            -- 3D / BasePart Entity: Add guaranteed AlwaysOnTop BoxHandleAdornment so it shines through walls even on single parts
            if targetPart:IsA("BasePart") then
                local box = createBoxAdornment(targetPart, entityColor)
                if box then
                    table.insert(extraVisuals, box)
                end
            end
        end

        local baseText = cfg.Name
        registerEsp(entity, targetPart, baseText, entityColor, "Entities", highlightTarget, Vector3.new(0, 3.0, 0), nil, extraVisuals, cfg.Category)
    end
end

-- Snare Trap Defusal (Greenhouse / Flooded Rooms)
local function defuseSnare(instance)
    if not instance then return end
    local iName = instance.Name:lower()
    if not iName:find("snare") then return end
    pcall(function()
        for _, p in ipairs(instance:GetDescendants()) do
            if p:IsA("BasePart") then
                p.CanTouch = false
            end
        end
        if instance:IsA("BasePart") then
            instance.CanTouch = false
        end
    end)
end

local function defuseAllSnares()
    if not State.Anti_Snare then return end
    local currentRooms = Workspace:FindFirstChild("CurrentRooms")
    if currentRooms then
        for _, desc in ipairs(currentRooms:GetDescendants()) do
            if desc.Name:lower():find("snare") then
                defuseSnare(desc)
            end
        end
    end
end

local function secureDupeDoor(doorModel)
    if not doorModel then return end
    pcall(function()
        for _, p in ipairs(doorModel:GetDescendants()) do
            if p:IsA("ProximityPrompt") then
                p.Enabled = false
            elseif p:IsA("BasePart") then
                p.CanTouch = false
            end
        end
        if doorModel:IsA("BasePart") then
            doorModel.CanTouch = false
        end
    end)
end

local function defuseGiggle(giggleModel)
    if not giggleModel then return end
    pcall(function()
        for _, p in ipairs(giggleModel:GetDescendants()) do
            if p:IsA("BasePart") then
                p.CanTouch = false
            end
        end
        if giggleModel:IsA("BasePart") then
            giggleModel.CanTouch = false
        end
    end)
end

-- =========================================================================
-- Glitch Fragment Engine (ESP & Auto Collection)
-- =========================================================================

local function isGlitchFragmentInstance(inst)
    if not inst then return false end
    local n = inst.Name:lower()
    local hasTag = false
    if CollectionService then
        pcall(function()
            hasTag = CollectionService:HasTag(inst, "GlitchCube")
        end)
    end
    return hasTag
        or n:find("glitchfragment")
        or n:find("glitch_fragment")
        or n:find("glitchcube")
        or (n:find("glitch") and n:find("fragment"))
        or (n:find("glitch") and n:find("cube"))
        or n:find("riftfragment")
        or inst:GetAttribute("GlitchFragment") == true
        or inst:GetAttribute("IsFragment") == true
        or (n:find("fragment") and (inst:IsA("Model") or inst:IsA("BasePart")) and not n:find("debug"))
end

local function collectGlitchFragment(inst)
    if not inst or not inst.Parent then return false end
    local root = getRoot()
    if not root then return false end

    local targetPart = (inst:IsA("Model") and (inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart", true)))
        or (inst:IsA("BasePart") and inst)
    if not targetPart then return false end

    -- 1. Check ProximityPrompt
    local prompt = inst:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt and prompt.Enabled then
        pcall(function()
            fireproximityprompt(prompt, 0)
        end)
    end

    -- 2. Physical touch interest
    pcall(function()
        firetouchinterest(root, targetPart, 0)
        task.wait(0.04)
        firetouchinterest(root, targetPart, 1)
    end)

    return true
end

local function getGlitchFragmentNow()
    local root = getRoot()
    if not root then
        Hub.Notify("Glitch Fragment", "Character not spawned!", 3)
        return false
    end

    local found = nil
    local currentRooms = Workspace:FindFirstChild("CurrentRooms")
    if currentRooms then
        for _, desc in ipairs(currentRooms:GetDescendants()) do
            if isGlitchFragmentInstance(desc) then
                found = desc
                break
            end
        end
    end

    if not found then
        for _, desc in ipairs(Workspace:GetChildren()) do
            if isGlitchFragmentInstance(desc) then
                found = desc
                break
            end
        end
    end

    if not found then
        local drops = Workspace:FindFirstChild("Drops")
        if drops then
            for _, desc in ipairs(drops:GetDescendants()) do
                if isGlitchFragmentInstance(desc) then
                    found = desc
                    break
                end
            end
        end
    end

    if not found then
        Hub.Notify("Glitch Fragment", "🔍 No Glitch Fragment currently spawned!", 3)
        return false
    end

    local targetPart = (found:IsA("Model") and (found.PrimaryPart or found:FindFirstChildWhichIsA("BasePart", true)))
        or (found:IsA("BasePart") and found)
    if not targetPart then return false end

    local oldPos = root.CFrame
    root.CFrame = targetPart.CFrame + Vector3.new(0, 2, 0)
    task.wait(0.12)
    collectGlitchFragment(found)
    task.wait(0.12)
    root.CFrame = oldPos

    Hub.Notify("Glitch Fragment", "🌀 Glitch Fragment collected!", 3)
    return true
end

local function processGlitchFragment(inst)
    if not inst then return end
    if not isGlitchFragmentInstance(inst) then return end
    if not State.GlitchFragment_ESP then
        removeEspFor(inst)
        return
    end

    local targetPart = (inst:IsA("Model") and (inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart", true)))
        or (inst:IsA("BasePart") and inst)
    if not targetPart then return end

    local color = State.ESP_Color_GlitchFragment or Color3.fromRGB(245, 50, 255)
    local baseText = "🌀 Glitch Fragment"
    
    local extraVisuals = {}
    local adorn = Instance.new("SphereHandleAdornment")
    adorn.Name = "Unknown_GlitchSphereAdorn"
    adorn.Radius = 2.5
    adorn.Color3 = color
    adorn.AlwaysOnTop = true
    adorn.Transparency = 0.35
    adorn.ZIndex = 12
    adorn.Adornee = targetPart
    adorn.Parent = (gethui and gethui()) or CoreGui
    table.insert(extraVisuals, adorn)

    registerEsp(inst, targetPart, baseText, color, "Items", inst, Vector3.new(0, 1.5, 0), nil, extraVisuals)

    if State.Auto_GetGlitchFragment then
        task.spawn(function()
            collectGlitchFragment(inst)
        end)
    end
end

-- =========================================================================
-- Glitch Strike Detection & 5x Trigger Engine
-- =========================================================================

local lastGlitchNotification = 0
local function recordGlitchStrike()
    local now = os.clock()
    if now - lastGlitchNotification < 1.5 then return end -- Debounce duplicate audio/remote events
    lastGlitchNotification = now

    State.Glitch_Count = (State.Glitch_Count or 0) + 1
    if State.Glitch_Count >= 5 then
        Hub.Notify("Glitch Secret", string.format("🎉 5/5 Glitches completed! The Glitch Fragment will spawn in the next room!", State.Glitch_Count), 6)
    else
        Hub.Notify("Glitch Secret", string.format("⚡ Glitch struck! [%d/5] (Need %d more to spawn Fragment)", State.Glitch_Count, 5 - State.Glitch_Count), 4)
    end
end

-- 1. Hook UseEnemyModule remote for server-confirmed Glitch attacks
pcall(function()
    local remotes = game:GetService("ReplicatedStorage"):WaitForChild("RemotesFolder", 5)
    local uem = remotes and remotes:FindFirstChild("UseEnemyModule")
    if uem then
        uem.OnClientEvent:Connect(function(enemyName, ...)
            if tostring(enemyName):lower():find("glitch") then
                recordGlitchStrike()
            end
        end)
    end
end)

-- 2. Hook Camera Glitch Screen VFX
if Camera then
    Camera.ChildAdded:Connect(function(child)
        if child.Name:lower():find("glitch") then
            recordGlitchStrike()
        end
    end)
end

-- Passive Background Scanner for Glitch Fragment
task.spawn(function()
    while true do
        if _G.DOORS_SESSION ~= currentSession then break end
        if State.Auto_GetGlitchFragment then
            local found = nil
            local currentRooms = Workspace:FindFirstChild("CurrentRooms")
            if currentRooms then
                for _, desc in ipairs(currentRooms:GetDescendants()) do
                    if isGlitchFragmentInstance(desc) then
                        found = desc
                        break
                    end
                end
            end
            if not found then
                for _, desc in ipairs(Workspace:GetChildren()) do
                    if isGlitchFragmentInstance(desc) then
                        found = desc
                        break
                    end
                end
            end
            local drops = Workspace:FindFirstChild("Drops")
            if not found and drops then
                for _, desc in ipairs(drops:GetDescendants()) do
                    if isGlitchFragmentInstance(desc) then
                        found = desc
                        break
                    end
                end
            end

            if found then
                collectGlitchFragment(found)
            end
        end
        task.wait(1.5)
    end
end)

-- Full Room Parser
local function scanSingleRoom(room)
    if not room or not room:IsA("Model") then return end

    -- 1. Scan Door
    local door = room:FindFirstChild("Door")
    if door then processDoor(room, door) end

    -- 1b. Scan Dupe fake door in SideroomDupe
    local sideDupe = room:FindFirstChild("SideroomDupe")
    if sideDupe then
        local fakeDoor = sideDupe:FindFirstChild("DoorFake")
        if fakeDoor then
            processDoor(room, fakeDoor)
        end
    end

    -- 2. Scan Room Descendants
    for _, desc in ipairs(room:GetDescendants()) do
        local dName = desc.Name:lower()

        -- Skip internal Dupe sideroom decorations/models (only DoorFake is tracked as a door)
        if not (desc.Parent and desc.Parent.Name == "SideroomDupe" and desc.Name ~= "DoorFake") then
            if isGlitchFragmentInstance(desc) then
                processGlitchFragment(desc)
            end

            if desc:IsA("Model") or desc:IsA("Tool") then
                if desc.Name == "Door" or desc.Name == "DoorFake" then
                    processDoor(room, desc)
                    if desc.Name == "DoorFake" and State.Anti_Dupe then
                        secureDupeDoor(desc)
                    end
                elseif desc.Name == "KeyObtain" or desc:GetAttribute("IsKey") then
                    processKey(desc)
                elseif dName:find("lever") then
                    processLever(desc)
                elseif desc.Name == "Wardrobe" or desc.Name == "Closet" or desc.Name == "Locker" or desc.Name:find("Bed") then
                    processHidingSpot(desc, room)
                elseif dName == "goldpile" or dName:find("gold") or dName:find("coin") then
                    processGold(desc)
                elseif dName:find("snare") then
                    if State.Anti_Snare then defuseSnare(desc) end
                    if State.Entities_ESP then processEntity(desc) end
                elseif dName:find("giggle") then
                    if State.Anti_Giggle then defuseGiggle(desc) end
                    if State.Entities_ESP then processEntity(desc) end
                elseif dName:find("figure") then
                    if State.Entities_ESP then processEntity(desc) end
                else
                    processItem(desc)
                end
            elseif desc:IsA("BasePart") then
                if desc.Name == "dupeDoor" then
                    processDoor(room, desc)
                    if State.Anti_Dupe then secureDupeDoor(desc) end
                elseif dName:find("snare") then
                    if State.Anti_Snare then defuseSnare(desc) end
                elseif dName:find("giggle") then
                    if State.Anti_Giggle then defuseGiggle(desc) end
                else
                    local p = desc.Parent
                    local isParentGold = p and p:IsA("Model") and (p.Name:lower():find("gold") or p.Name:lower():find("coin"))
                    if not isParentGold then
                        if dName == "goldpile" or dName:find("gold") or dName:find("coin") then
                            processGold(desc)
                        end
                    end
                    if dName:find("lever") then
                        processLever(desc)
                    end
                end
            elseif desc:IsA("ProximityPrompt") then
                local obj = (desc.ObjectText or ""):lower()
                local act = (desc.ActionText or ""):lower()
                if obj:find("lever") or act:find("pull") then
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
        if isGlitchFragmentInstance(child) then
            processGlitchFragment(child)
        end
    end

    local drops = Workspace:FindFirstChild("Drops")
    if drops then
        for _, child in ipairs(drops:GetDescendants()) do
            if isGlitchFragmentInstance(child) then
                processGlitchFragment(child)
            end
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
            -- Wait for DOORS room generation scripts to finish (DOORS removes placeholder levers & template padlocks at 0.5-0.9s)
            task.wait(1.0)
            if not newRoom.Parent then return end
            scanSingleRoom(newRoom)

            -- Late verification pass to ensure 100% accuracy on doors and late-spawning assets
            task.delay(0.8, function()
                if newRoom.Parent then
                    local door = newRoom:FindFirstChild("Door")
                    if door then processDoor(newRoom, door) end
                end
            end)

            -- Real-time dropped items, drawer looting, and lever discovery
            newRoom.DescendantAdded:Connect(function(desc)
                task.wait(0.05)
                local dName = desc.Name:lower()

                if desc.Parent and desc.Parent.Name == "SideroomDupe" and desc.Name ~= "DoorFake" then
                    return
                end

                if isGlitchFragmentInstance(desc) then
                    processGlitchFragment(desc)
                end

                if desc:IsA("Model") or desc:IsA("Tool") then
                    if desc.Name == "Door" or desc.Name == "DoorFake" then
                        processDoor(newRoom, desc)
                        if desc.Name == "DoorFake" and State.Anti_Dupe then
                            secureDupeDoor(desc)
                        end
                    elseif desc.Name == "KeyObtain" or desc:GetAttribute("IsKey") then
                        processKey(desc)
                    elseif dName:find("lever") then
                        processLever(desc)
                    elseif desc.Name == "Wardrobe" or desc.Name == "Closet" or desc.Name == "Locker" or desc.Name:find("Bed") then
                        processHidingSpot(desc, newRoom)
                    elseif dName == "goldpile" or dName:find("gold") or dName:find("coin") then
                        processGold(desc)
                    elseif dName:find("snare") then
                        if State.Anti_Snare then defuseSnare(desc) end
                        if State.Entities_ESP then processEntity(desc) end
                    elseif dName:find("giggle") then
                        if State.Anti_Giggle then defuseGiggle(desc) end
                        if State.Entities_ESP then processEntity(desc) end
                    elseif dName:find("figure") then
                        if State.Entities_ESP then processEntity(desc) end
                    else
                        processItem(desc)
                    end
                elseif desc:IsA("BasePart") then
                    if desc.Name == "dupeDoor" then
                        processDoor(newRoom, desc)
                        if State.Anti_Dupe then secureDupeDoor(desc) end
                    elseif dName:find("snare") then
                        if State.Anti_Snare then defuseSnare(desc) end
                    elseif dName:find("giggle") then
                        if State.Anti_Giggle then defuseGiggle(desc) end
                    else
                        local p = desc.Parent
                        local isParentGold = p and p:IsA("Model") and (p.Name:lower():find("gold") or p.Name:lower():find("coin"))
                        if not isParentGold then
                            if dName == "goldpile" or dName:find("gold") or dName:find("coin") then
                                processGold(desc)
                            end
                        end
                        if dName:find("lever") then
                            processLever(desc)
                        end
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
        pcall(function()
            if State.Entities_ESP and child and child.Parent then
                local cName = child.Name:lower()
                if cName:find("screech") or cName:find("spider") or cName:find("timothy") then
                    processEntity(child)
                end
            end
        end)
    end)
end

-- Continuous Guard Loop (Guarantees live entity tracking and periodic sweeps)
task.spawn(function()
    while true do
        if _G.DOORS_SESSION ~= currentSession then break end
        if State.Master_ESP then
            if State.Entities_ESP then
                for _, child in ipairs(Workspace:GetChildren()) do
                    pcall(function() processEntity(child) end)
                end
                if Camera then
                    for _, child in ipairs(Camera:GetChildren()) do
                        local cName = child.Name:lower()
                        if cName:find("screech") or cName:find("spider") or cName:find("timothy") then
                            pcall(function() processEntity(child) end)
                        end
                    end
                end
            end
        end
        task.wait(0.5)
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
    -- Prevent character limbs from snagging on narrow door frames or tight openings
    for _, part in ipairs(char:GetChildren()) do
        if part:IsA("BasePart") and part.Name ~= "Collision" and part.Name ~= "HumanoidRootPart" then
            part.CanCollide = false
            part.CustomPhysicalProperties = zeroFriction
        end
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
local lastSentSlideState = nil
local lastSlideSyncTime = 0
local pendingCrouchState = nil
local unhideGraceUntil = 0
local wasHidingState = false

-- isPlayerHiding defined above near top of script (line 472)

local syncServerSlide

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
                if syncServerSlide then syncServerSlide(false) end
            end
        end
    end)
end)

local isSlidingActive = false
local slideStartTime = 0
local slideDirection = Vector3.zero

syncServerSlide = function(shouldAuthorize, isActuallySliding)
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
    -- Crucial: When WalkSpeed is enabled OR when the player is actively sliding, sliding MUST be authorized on the DOORS server (arg 2 = true).
    -- This raises the server's anti-cheat speed threshold and eliminates door/room transition rubberbanding!
    local isSliding = (shouldAuthorize == true) and (State.WalkSpeed_Enabled or (isActuallySliding == true) or isCrouching)
    local now = os.clock()

    if isPlayerHiding(char, mgTable) or (now < unhideGraceUntil) then
        if lastSentCrouchState ~= false or lastSentSlideState ~= false then
            lastSentCrouchState = false
            lastSentSlideState = false
            pendingCrouchState = nil
            lastSlideSyncTime = now
            pcall(function() crouchRemote:FireServer(false, false) end)
        end
        return
    end

    if shouldAuthorize then
        local crouchChanged = (isCrouching ~= lastSentCrouchState)
        local slideChanged = (isSliding ~= lastSentSlideState)

        if crouchChanged or slideChanged then
            -- Rate-limit rapid crouch toggles to prevent server packet drop / anti-cheat desync
            if (now - lastSlideSyncTime < 0.12) then
                pendingCrouchState = isCrouching
                return
            end
            pendingCrouchState = nil
            lastSentCrouchState = isCrouching
            lastSentSlideState = isSliding
            lastSlideSyncTime = now
            pcall(function()
                crouchRemote:FireServer(isCrouching, isSliding)
            end)
        elseif pendingCrouchState ~= nil and (now - lastSlideSyncTime >= 0.12) then
            local toSend = pendingCrouchState
            pendingCrouchState = nil
            lastSentCrouchState = toSend
            lastSentSlideState = isSliding
            lastSlideSyncTime = now
            pcall(function()
                crouchRemote:FireServer(toSend, isSliding)
            end)
        elseif isSliding and (now - lastSlideSyncTime >= 0.45) then
            -- Heartbeat keep-alive every 0.45s to prevent server-side slide token expiration
            lastSlideSyncTime = now
            pcall(function()
                crouchRemote:FireServer(isCrouching, isSliding)
            end)
        end
    else
        if lastSentSlideState == true or (lastSentCrouchState ~= isCrouching and now - lastSlideSyncTime >= 0.12) then
            lastSentCrouchState = isCrouching
            lastSentSlideState = false
            pendingCrouchState = nil
            lastSlideSyncTime = now
            pcall(function()
                crouchRemote:FireServer(isCrouching, false)
            end)
        end
    end
end

local function startSlide()
    if not State.Enable_Sliding then return end
    if isSlidingActive then return end

    local char = getChar()
    local root = getRoot()
    local hum = char and char:FindFirstChildWhichIsA("Humanoid")
    if not char or not root or not hum or hum.Health <= 0 then return end

    local moveDir = hum.MoveDirection
    if moveDir.Magnitude < 0.05 then return end

    isSlidingActive = true
    slideStartTime = os.clock()
    slideDirection = moveDir.Unit

    local mgTable = getMainGameTable()
    if mgTable then
        mgTable.sliding = true
        if mgTable.animations and mgTable.animations.Slide then
            pcall(function() mgTable.animations.Slide:Play(0.1, 1, 1.25) end)
        end
    end

    syncServerSlide(true, true)
    applyTeflonGlide(char)

    local targetSpeed = math.max(State.WalkSpeed_Value or 35, 42)
    root.AssemblyLinearVelocity = Vector3.new(slideDirection.X * targetSpeed, root.AssemblyLinearVelocity.Y, slideDirection.Z * targetSpeed)
end

local function stopSlide()
    if not isSlidingActive then return end
    isSlidingActive = false

    local mgTable = getMainGameTable()
    if mgTable then
        mgTable.sliding = false
        if mgTable.animations and mgTable.animations.Slide then
            pcall(function() mgTable.animations.Slide:Stop(0.25) end)
        end
    end

    syncServerSlide(true, false)
end

-- =========================================================================
-- DOORS Anti-Cheat Bypass Core & Safe Sub-Step Teleport/Flight Engine
-- =========================================================================
local isTeleportTweening = false
local activeTweenToken = 0
local teleportImmunityUntil = 0

local function isTeleportImmune()
    return isTeleportTweening or isAtRoof or (os.clock() < teleportImmunityUntil)
end

-- Active Proximity Sentry: Automatically solves locks & opens doors on approach (Zero Yield / Full Descendants)
local openedDoors = {}
local lastDoorKeyEquip = 0

local function processNearbyDoors(currentPos, maxReach)
    local curRooms = Workspace:FindFirstChild("CurrentRooms")
    if not curRooms then return end
    local reach = maxReach or 30
    local r = getRoot()
    local char = getChar()

    for _, rm in ipairs(curRooms:GetChildren()) do
        for _, d in ipairs(rm:GetDescendants()) do
            if d:IsA("Model") and (d.Name == "Door" or d.Name == "DoorNormal" or d.Name == "SideroomDoor" or d.Name:find("Door")) then
                local dPart = d:FindFirstChild("Door") or d:FindFirstChild("Hidden") or d.PrimaryPart or d:FindFirstChildWhichIsA("BasePart")
                if dPart and (currentPos - dPart.Position).Magnitude <= reach then
                    -- 1. Strip CanCollide locally on all door parts so character never hits physical barrier
                    for _, dp in ipairs(d:GetDescendants()) do
                        if dp:IsA("BasePart") and not dp.Name:lower():find("frame") and dp.CanCollide then
                            dp.CanCollide = false
                        end
                    end

                    -- 2. Check for Lock and auto-unlock if Key available (0s hold, no line of sight needed)
                    local lock = d:FindFirstChild("Lock")
                    if lock then
                        local up = lock:FindFirstChild("UnlockPrompt", true) or lock:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if up and up.Enabled then
                            up.HoldDuration = 0
                            up.RequiresLineOfSight = false
                            up.MaxActivationDistance = math.max(up.MaxActivationDistance or 0, 15)
                            local now = os.clock()
                            if (now - lastDoorKeyEquip >= 0.25) then
                                lastDoorKeyEquip = now
                                task.spawn(function()
                                    local keyTool = LocalPlayer.Backpack:FindFirstChild("Key") or (char and char:FindFirstChild("Key"))
                                    local hum = char and char:FindFirstChildWhichIsA("Humanoid")
                                    if keyTool and keyTool.Parent == LocalPlayer.Backpack and hum then
                                        hum:EquipTool(keyTool)
                                        task.wait(0.04)
                                    end
                                    pcall(function() fireproximityprompt(up) end)
                                end)
                            end
                        end
                    end

                    -- 3. Instant Door Opening (Debounced per door instance to eliminate network flood & delay)
                    local lastOpened = openedDoors[d]
                    local now = os.clock()
                    if not lastOpened or (now - lastOpened >= 1.2) then
                        openedDoors[d] = now

                        -- Trigger client network remote
                        local co = d:FindFirstChild("ClientOpen")
                        if co and co:IsA("RemoteEvent") then
                            pcall(function() co:FireServer() end)
                        end

                        -- Trigger local bindable open events
                        local fo = d:FindFirstChild("Func_ForceOpen") or d:FindFirstChild("Func_Open")
                        if fo and fo:IsA("BindableEvent") then
                            pcall(function() fo:Fire() end)
                        end

                        -- Touch-based swing open for DoorNormal / Hidden
                        local hiddenPart = d:FindFirstChild("Hidden")
                        if hiddenPart and hiddenPart:IsA("BasePart") then
                            pcall(function()
                                hiddenPart.CanTouch = true
                                if r then
                                    firetouchinterest(r, hiddenPart, 0)
                                    task.spawn(function()
                                        task.wait(0.03)
                                        if r and hiddenPart and hiddenPart.Parent then
                                            firetouchinterest(r, hiddenPart, 1)
                                        end
                                    end)
                                end
                            end)
                        end

                        -- Trigger ManualOpenPrompt or any door proximity prompt
                        for _, prompt in ipairs(d:GetDescendants()) do
                            if prompt:IsA("ProximityPrompt") and prompt.Enabled and prompt.Name ~= "UnlockPrompt" then
                                pcall(function()
                                    prompt.HoldDuration = 0
                                    prompt.RequiresLineOfSight = false
                                    prompt.MaxActivationDistance = math.max(prompt.MaxActivationDistance or 0, 15)
                                    fireproximityprompt(prompt)
                                end)
                            end
                        end
                    end
                end
            end
        end
    end
end

-- Room Bounds Sentry: Calculates valid room corridor height to prevent Void/Glitch triggers
local function getSafeFlightY(desiredPos)
    if not State.Fly_SafeBounds then return desiredPos.Y end
    local curRooms = Workspace:FindFirstChild("CurrentRooms")
    if not curRooms then return desiredPos.Y end

    local bestRoom = nil
    local bestDist = math.huge
    for _, rm in ipairs(curRooms:GetChildren()) do
        local cf, sz = rm:GetBoundingBox()
        local d = (desiredPos - cf.Position).Magnitude
        if d < bestDist then
            bestDist = d
            bestRoom = rm
        end
    end

    if bestRoom then
        local cf, sz = bestRoom:GetBoundingBox()
        local minY = cf.Position.Y - sz.Y / 2
        local maxY = cf.Position.Y + sz.Y / 2
        local numPart = bestRoom:FindFirstChild(bestRoom.Name)
        if numPart and numPart:IsA("BasePart") then
            minY = math.max(minY, numPart.Position.Y - 0.5)
        end
        local safeMinY = minY + 0.8
        local safeMaxY = maxY - 1.2
        if safeMaxY > safeMinY then
            return math.clamp(desiredPos.Y, safeMinY, safeMaxY)
        end
    end
    return desiredPos.Y
end

-- Absolute Glitch & Void Deflection Shield (Zero Glitch Invariant: Map & Noclip Immune)
local function initAntiGlitchShield()
    if not State.Deflect_Glitch then return end

    -- 1. Intercept UseEnemyModule: Drop Glitch & Void triggers before they ever reach client logic
    pcall(function()
        local rf = game:GetService("ReplicatedStorage"):FindFirstChild("RemotesFolder")
        local uem = rf and rf:FindFirstChild("UseEnemyModule")
        if uem and getconnections then
            for _, c in ipairs(getconnections(uem.OnClientEvent)) do
                local fn = c.Function
                if fn and not _G["UEM_DETOURED_" .. tostring(fn)] then
                    _G["UEM_DETOURED_" .. tostring(fn)] = true
                    if hookfunction then
                        hookfunction(fn, newcclosure(function(enemyName, method, ...)
                            if enemyName == "Glitch" or enemyName == "Void" then
                                return -- Drop Glitch and Void calls from server dead in their tracks!
                            end
                            return fn(enemyName, method, ...)
                        end))
                    end
                end
            end

            -- Direct Upvalue Inoculation: Replace cached module instances in RemoteListener
            if getupvalues and #getconnections(uem.OnClientEvent) > 0 then
                local upvals = getupvalues(getconnections(uem.OnClientEvent)[1].Function)
                if upvals and upvals[2] and type(upvals[2]) == "table" then
                    local dummy = setmetatable({}, { __index = function() return function() end end })
                    upvals[2]["Glitch"] = dummy
                    upvals[2]["Void"] = dummy
                end
            end
        end

        -- 2. Intercept Jumpscare and JumpscareBindable events for Glitch & Void
        local jmp = rf and rf:FindFirstChild("Jumpscare")
        if jmp and getconnections then
            for _, c in ipairs(getconnections(jmp.OnClientEvent)) do
                local fn = c.Function
                if fn and not _G["JMP_DETOURED_" .. tostring(fn)] then
                    _G["JMP_DETOURED_" .. tostring(fn)] = true
                    if hookfunction then
                        hookfunction(fn, newcclosure(function(jName, ...)
                            if jName == "Glitch" or jName == "Void" then
                                return
                            end
                            return fn(jName, ...)
                        end))
                    end
                end
            end
        end

        local jb = rf and rf:FindFirstChild("JumpscareBindable")
        if jb and getconnections then
            for _, c in ipairs(getconnections(jb.Event)) do
                local fn = c.Function
                if fn and not _G["JB_DETOURED_" .. tostring(fn)] then
                    _G["JB_DETOURED_" .. tostring(fn)] = true
                    if hookfunction then
                        hookfunction(fn, newcclosure(function(jName, ...)
                            if jName == "Glitch" or jName == "Void" then
                                return
                            end
                            return fn(jName, ...)
                        end))
                    end
                end
            end
        end
    end)

    -- 3. Neutralize EntityModules Glitch and Void implementations
    pcall(function()
        local mc = game:GetService("ReplicatedStorage"):WaitForChild("ModulesClient", 3)
        local em = mc and mc:WaitForChild("EntityModules", 3)
        if em then
            local gm = em:FindFirstChild("Glitch")
            if gm then
                local gTable = require(gm)
                if gTable then
                    gTable.stuff = function(p1, ...)
                        if p1 then
                            p1.stopcam = false
                            p1.hideplayers = 0
                        end
                        local c = getChar()
                        if c and c.PrimaryPart then c.PrimaryPart.Anchored = false end
                        pcall(function()
                            local lt = game:GetService("Lighting")
                            lt.FogEnd = 1000
                            lt.FogStart = 0
                            local pGui = LocalPlayer:FindFirstChild("PlayerGui")
                            local gs = pGui and pGui:FindFirstChild("MainUI") and pGui.MainUI:FindFirstChild("MainFrame") and pGui.MainUI.MainFrame:FindFirstChild("GlitchScreen")
                            if gs then gs.Visible = false end
                        end)
                        return
                    end
                end
            end

            local vm = em:FindFirstChild("Void")
            if vm then
                local vTable = require(vm)
                if vTable then
                    vTable.stuff = function(p1, ...)
                        if p1 then
                            p1.stopcam = false
                            p1.hideplayers = 0
                        end
                        local c = getChar()
                        if c and c.PrimaryPart then c.PrimaryPart.Anchored = false end
                        pcall(function()
                            local lt = game:GetService("Lighting")
                            lt.FogEnd = 1000
                            lt.FogStart = 0
                        end)
                        return
                    end
                end
            end
        end
    end)

    -- 4. Strip model assets and establish instant destroy interceptors
    pcall(function()
        local ent = game:GetService("ReplicatedStorage"):FindFirstChild("Entities")
        local gm = ent and ent:FindFirstChild("Glitch")
        if gm then gm:ClearAllChildren() end

        local cam = Workspace.CurrentCamera
        if cam and not _G.GLITCH_CAM_HOOKED then
            _G.GLITCH_CAM_HOOKED = true
            cam.ChildAdded:Connect(function(c)
                local name = c.Name:lower()
                if name:find("glitch") or name:find("void") or name == "livevoidreaction" or name == "ambience_glitch" then
                    pcall(function() c:Destroy() end)
                end
            end)
        end

        local pGui = LocalPlayer:FindFirstChild("PlayerGui")
        local mUI = pGui and pGui:FindFirstChild("MainUI")
        if mUI and not _G.GLITCH_UI_HOOKED then
            _G.GLITCH_UI_HOOKED = true
            mUI.ChildAdded:Connect(function(c)
                local name = c.Name:lower()
                if name:find("glitch") or name == "fakeglitchlive" then
                    pcall(function() c:Destroy() end)
                end
            end)
        end

        local mf = mUI and mUI:FindFirstChild("MainFrame")
        if mf then
            local gs = mf:FindFirstChild("GlitchScreen")
            if gs then
                gs.Visible = false
                if not _G.GLITCH_SCREEN_HOOKED then
                    _G.GLITCH_SCREEN_HOOKED = true
                    gs:GetPropertyChangedSignal("Visible"):Connect(function()
                        if gs.Visible then gs.Visible = false end
                    end)
                end
            end
            local ge = mf:FindFirstChild("GlitchEffect")
            if ge then
                ge.Visible = false
                if not _G.GLITCH_EFFECT_HOOKED then
                    _G.GLITCH_EFFECT_HOOKED = true
                    ge:GetPropertyChangedSignal("Visible"):Connect(function()
                        if ge.Visible then ge.Visible = false end
                    end)
                end
            end
            local gt = mf:FindFirstChild("GlitchTrial")
            if gt then
                gt.Visible = false
                if not _G.GLITCH_TRIAL_HOOKED then
                    _G.GLITCH_TRIAL_HOOKED = true
                    gt:GetPropertyChangedSignal("Visible"):Connect(function()
                        if gt.Visible then gt.Visible = false end
                    end)
                end
            end
        end

        local ss = game:GetService("SoundService"):FindFirstChild("Main")
        if ss and not _G.GLITCH_SS_HOOKED then
            _G.GLITCH_SS_HOOKED = true
            ss.ChildAdded:Connect(function(c)
                if c.Name == "SanityEqualizerLive" or c.Name:lower():find("glitch") then
                    pcall(function() c:Destroy() end)
                end
            end)
        end
    end)
end

local lastFlySlidePulse = 0
local flyPos = nil

local function pulseSlideKeepAlive()
    if not crouchRemote then
        pcall(function()
            local rf = game:GetService("ReplicatedStorage"):FindFirstChild("RemotesFolder")
            crouchRemote = rf and rf:FindFirstChild("Crouch")
        end)
    end
    if crouchRemote then
        pcall(function()
            crouchRemote:FireServer(false, false)
            task.wait(0.02)
            crouchRemote:FireServer(false, true)
        end)
    end
end

local function neutralizeServerTeleported()
    if not State.Bypass_AntiCheat then return end

    -- 1. Detour Client RemoteListener ServerTeleported Module (Allows wardrobe hiding; blocks void / anticheat pullbacks)
    pcall(function()
        local pGui = LocalPlayer:FindFirstChild("PlayerGui")
        local rl = pGui and pGui:FindFirstChild("MainUI") and pGui.MainUI:FindFirstChild("Initiator") and pGui.MainUI.Initiator:FindFirstChild("Main_Game") and pGui.MainUI.Initiator.Main_Game:FindFirstChild("RemoteListener")
        if rl and rl:FindFirstChild("Modules") then
            local stMod = rl.Modules:FindFirstChild("ServerTeleported", true)
            if stMod and not _G.ST_FN_HOOKED then
                _G.ST_FN_HOOKED = true
                local rawFn = require(stMod)
                if type(rawFn) == "function" and hookfunction then
                    hookfunction(rawFn, newcclosure(function(p1, p2, p3, p4)
                        local char = getChar()
                        local mgTable = getMainGameTable()
                        local hiding = isPlayerHiding(char, mgTable) or (os.clock() < unhideGraceUntil)
                        if not hiding and (isTeleportTweening or State.Noclip or isAtRoof or State.Bypass_AntiCheat) then
                            return
                        end
                        return rawFn(p1, p2, p3, p4)
                    end))
                end
            end
        end
    end)

    -- 2. Detour listeners on RemotesFolder.ServerTeleported & Teleport
    pcall(function()
        local rf = game:GetService("ReplicatedStorage"):FindFirstChild("RemotesFolder")
        if not rf or not getconnections then return end

        local tp = rf:FindFirstChild("Teleport")
        if tp and tp:IsA("RemoteEvent") then
            for _, c in ipairs(getconnections(tp.OnClientEvent)) do
                pcall(function()
                    c:Disable()
                    local fn = c.Function
                    if fn and not _G["TP_DETOURED_" .. tostring(fn)] then
                        _G["TP_DETOURED_" .. tostring(fn)] = true
                        if hookfunction then
                            hookfunction(fn, newcclosure(function(...)
                                local char = getChar()
                                local mgTable = getMainGameTable()
                                local hiding = isPlayerHiding(char, mgTable) or (os.clock() < unhideGraceUntil)
                                if not hiding and (isTeleportTweening or State.Noclip or isAtRoof or State.Bypass_AntiCheat) then
                                    return
                                end
                                return fn(...)
                            end))
                        end
                    end
                end)
            end
        end

        local st = rf:FindFirstChild("ServerTeleported")
        if st and st:IsA("RemoteEvent") then
            for _, c in ipairs(getconnections(st.OnClientEvent)) do
                pcall(function()
                    c:Disable()
                    local fn = c.Function
                    if fn and not _G["ST_DETOURED_" .. tostring(fn)] then
                        _G["ST_DETOURED_" .. tostring(fn)] = true
                        if hookfunction then
                            hookfunction(fn, newcclosure(function(...)
                                local char = getChar()
                                local mgTable = getMainGameTable()
                                local hiding = isPlayerHiding(char, mgTable) or (os.clock() < unhideGraceUntil)
                                if not hiding and (isTeleportTweening or State.Noclip or isAtRoof or State.Bypass_AntiCheat) then
                                    return
                                end
                                return fn(...)
                            end))
                        end
                    end
                end)
            end
        end
    end)

    -- 3. Only clear pending Main_Game SETNEWCF if actively tweening between waypoints
    if isTeleportTweening then
        local mgTable = getMainGameTable()
        if mgTable and mgTable.SETNEWCF then
            mgTable.SETNEWCF = nil
        end
    end
end

-- Initialize Glitch & Anti-Cheat Shields
initAntiGlitchShield()

-- Continuous Anti-Cheat Neutralization & Slide Token Refresh Loop
task.spawn(function()
    while true do
        if _G.DOORS_SESSION ~= currentSession then break end
        if State.Bypass_AntiCheat then
            neutralizeServerTeleported()
            if State.Deflect_Glitch then
                initAntiGlitchShield()
            end
            if State.Fly_Enabled or State.Noclip or isTeleportTweening or State.WalkSpeed_Enabled then
                if syncServerSlide then
                    syncServerSlide(true, true)
                end
            end
        end
        task.wait(0.25)
    end
end)

-- Safe Room Landing Calculator: Determines valid floor coordinates inside active rooms
local function getSafeLandingPosition()
    local char = getChar()
    local root = getRoot()
    if not root then return nil end

    -- 1. Check if there is already a solid walkable floor directly below root
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {char, Workspace.CurrentCamera}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude

    local floorHit = workspace:Raycast(root.Position + Vector3.new(0, 2, 0), Vector3.new(0, -12, 0), rayParams)
    if floorHit and floorHit.Instance and floorHit.Instance.CanCollide then
        local hum = char:FindFirstChildWhichIsA("Humanoid")
        local rootOffset = (hum and hum.HipHeight or 2.0) + 1.0
        return Vector3.new(root.Position.X, floorHit.Position.Y + rootOffset, root.Position.Z)
    end

    -- 2. If out of bounds or in mid-air/void, snap to nearest room entrance floor
    local curRooms = Workspace:FindFirstChild("CurrentRooms")
    if curRooms then
        local targetRoom = nil
        local bestDist = math.huge
        for _, rm in ipairs(curRooms:GetChildren()) do
            local cf, sz = rm:GetBoundingBox()
            local d = (root.Position - cf.Position).Magnitude
            if d < bestDist then
                bestDist = d
                targetRoom = rm
            end
        end

        if targetRoom then
            local roomEnt = targetRoom:FindFirstChild("RoomEntrance") or targetRoom:FindFirstChild("RoomExit") or targetRoom:FindFirstChildWhichIsA("BasePart")
            if roomEnt then
                return getExactFloorPos(roomEnt.Position + Vector3.new(0, 1, 0))
            end
        end
    end

    return nil
end

-- Floor Raycast Snapping: Guaranteed placement on walkable floor surface (eliminates mid-air drops & gravity physics spikes)
local function getExactFloorPos(pos, fallbackOffset)
    local char = getChar()
    local hum = char and char:FindFirstChildWhichIsA("Humanoid")
    local hipHeight = hum and hum.HipHeight or 2.0
    local rootOffset = hipHeight + 1.0

    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {char, Workspace.CurrentCamera}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude

    -- Raycast downward from 8 studs above pos
    local origin = Vector3.new(pos.X, pos.Y + 8.0, pos.Z)
    local hit = workspace:Raycast(origin, Vector3.new(0, -35, 0), rayParams)
    if hit then
        return Vector3.new(pos.X, hit.Position.Y + rootOffset, pos.Z)
    end
    return Vector3.new(pos.X, pos.Y + (fallbackOffset or 0), pos.Z)
end

-- Character Interactivity & Collision Re-enabler: Restores full ProximityPrompt raycasting and room triggers
local function restoreCharacterInteractivity(char)
    if not char then return end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then
            p.CanTouch = true
            p.CanQuery = true
        end
    end
    local coll = char:FindFirstChild("Collision")
    local cp = char:FindFirstChild("CollisionPart")
    local root = char:FindFirstChild("HumanoidRootPart")
    if coll and coll:IsA("BasePart") then
        coll.CanCollide = true
        coll.CanTouch = true
        coll.CanQuery = true
    end
    if cp and cp:IsA("BasePart") then
        cp.CanCollide = false
        cp.CanTouch = true
        cp.CanQuery = true
    end
    if root and root:IsA("BasePart") then
        root.CanCollide = false
        root.CanTouch = true
        root.CanQuery = true
    end
end

-- Safe Overhead Clearance Calculator: Stays strictly BELOW the room ceiling to prevent out-of-bounds void Glitch!
local function getOverheadClearanceY(posA, posB)
    local char = getChar()
    local startY = math.max(posA.Y, posB.Y)
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {char, Workspace.CurrentCamera}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude

    local ceilA = workspace:Raycast(posA + Vector3.new(0, 1.5, 0), Vector3.new(0, 25, 0), rayParams)
    local ceilB = workspace:Raycast(posB + Vector3.new(0, 1.5, 0), Vector3.new(0, 25, 0), rayParams)
    local minCeilY = math.min(ceilA and ceilA.Position.Y or (startY + 12), ceilB and ceilB.Position.Y or (startY + 12))

    -- Safe clearance: at least 1.5 studs BELOW ceiling, clearing tables/beds at ~5.5-8.5 studs
    local safeY = math.clamp(minCeilY - 1.5, startY + 5.0, startY + 8.5)
    return safeY
end

-- Upgraded Waypoint Router: Detects wall collisions, tests hallway routes, and activates overhead sky-corridor bypass to eliminate wall rollbacks!
local function getNavigationWaypoints(startPos, endPos)
    local char = getChar()
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {char, Workspace.CurrentCamera}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude

    -- Check direct line-of-sight at torso height (+1.5 studs)
    local s = startPos + Vector3.new(0, 1.5, 0)
    local e = endPos + Vector3.new(0, 1.5, 0)

    local rawWaypoints = {}
    local hit = workspace:Raycast(s, e - s, rayParams)

    if not hit then
        table.insert(rawWaypoints, { pos = endPos, isElevated = false })
    else
        -- Direct path hits a wall/obstacle. Test Manhattan L-corner hallway routes
        local c1 = Vector3.new(endPos.X, startPos.Y, startPos.Z)
        local c1_ray = c1 + Vector3.new(0, 1.5, 0)
        local hit1_a = workspace:Raycast(s, c1_ray - s, rayParams)
        local hit1_b = workspace:Raycast(c1_ray, e - c1_ray, rayParams)

        if not hit1_a and not hit1_b then
            table.insert(rawWaypoints, { pos = getExactFloorPos(c1), isElevated = false })
            table.insert(rawWaypoints, { pos = endPos, isElevated = false })
        else
            local c2 = Vector3.new(startPos.X, startPos.Y, endPos.Z)
            local c2_ray = c2 + Vector3.new(0, 1.5, 0)
            local hit2_a = workspace:Raycast(s, c2_ray - s, rayParams)
            local hit2_b = workspace:Raycast(c2_ray, e - c2_ray, rayParams)

            if not hit2_a and not hit2_b then
                table.insert(rawWaypoints, { pos = getExactFloorPos(c2), isElevated = false })
                table.insert(rawWaypoints, { pos = endPos, isElevated = false })
            else
                -- UPGRADED OVERHEAD ARC BYPASS:
                -- Both direct line and floor Manhattan L-corners are obstructed by walls/doors!
                -- Route through the Upper Corridor / Overhead Arc so character travels cleanly above walls with ZERO collisions!
                local overheadY = getOverheadClearanceY(startPos, endPos)
                local wpLift = Vector3.new(startPos.X, overheadY, startPos.Z)
                local wpCruise = Vector3.new(endPos.X, overheadY, endPos.Z)

                table.insert(rawWaypoints, { pos = wpLift, isElevated = true })
                table.insert(rawWaypoints, { pos = wpCruise, isElevated = true })
                table.insert(rawWaypoints, { pos = endPos, isElevated = false })
            end
        end
    end

    -- Subdivide any segments longer than 36 studs into micro-bursts to keep server slide timers fresh (< 1.0s per burst)
    local finalWaypoints = {}
    local prev = startPos
    for _, wpData in ipairs(rawWaypoints) do
        local wp = wpData.pos
        local isElevated = wpData.isElevated
        local segDist = (wp - prev).Magnitude
        if segDist > 36 then
            local steps = math.ceil(segDist / 30)
            for step = 1, steps do
                local subPos = prev:Lerp(wp, step / steps)
                if not isElevated and (step == steps) then
                    table.insert(finalWaypoints, getExactFloorPos(subPos))
                else
                    table.insert(finalWaypoints, subPos)
                end
            end
        else
            table.insert(finalWaypoints, wp)
        end
        prev = wp
    end

    return finalWaypoints
end

local function safeTweenTeleport(targetCF, speedVal, autoDoorOpen, isFinalDestination, callback)
    if type(isFinalDestination) == "function" then
        callback = isFinalDestination
        isFinalDestination = true
    elseif isFinalDestination == nil then
        isFinalDestination = true
    end

    local char = getChar()
    local root = getRoot()
    local hum = char and char:FindFirstChildWhichIsA("Humanoid")
    if not char or not root or not hum or hum.Health <= 0 then return false end

    local targetCFrame = (typeof(targetCF) == "Vector3") and CFrame.new(targetCF) or targetCF
    local targetPos = targetCFrame.Position
    local targetRot = targetCFrame - targetPos
    local startPos = root.Position
    local moveVec = (targetPos - startPos)
    local totalDist = moveVec.Magnitude
    if totalDist < 0.5 then
        if isFinalDestination then
            teleportImmunityUntil = os.clock() + 1.2
            restoreCharacterInteractivity(char)
        end
        if callback then callback() end
        return true
    end

    local speed = math.clamp(speedVal or State.Teleport_Speed or 38, 18, 65)
    local duration = totalDist / speed
    local moveDir = (totalDist > 0.01) and (moveVec / totalDist) or Vector3.zero
    local token = tick() + math.random()
    activeTweenToken = token
    isTeleportTweening = true
    teleportImmunityUntil = os.clock() + duration + 1.8

    if syncServerSlide then syncServerSlide(true, true) end

    local t0 = os.clock()
    local lastSlidePulse = t0
    local settleStartTime = nil

    local conn
    conn = RunService.Heartbeat:Connect(function()
        if activeTweenToken ~= token or _G.DOORS_SESSION ~= currentSession or not char or not root or hum.Health <= 0 then
            if conn then conn:Disconnect() end
            if activeTweenToken == token then
                isTeleportTweening = false
                restoreCharacterInteractivity(char)
                if isFinalDestination then teleportImmunityUntil = os.clock() + 1.2 end
            end
            return
        end

        local now = os.clock()
        local elapsed = now - t0
        local alpha = math.clamp(elapsed / duration, 0, 1)

        -- Only strip CanCollide during active penetration; preserve CanTouch & CanQuery so prompts and doors work
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") and p.CanCollide then
                p.CanCollide = false
            end
        end

        if alpha < 1 then
            -- Active Flight Phase: interpolate sub-positions with synchronized root, collision part, and Main_Game SETNEWCF
            local currentSubPos = startPos:Lerp(targetPos, alpha)
            local currentCF = CFrame.new(currentSubPos) * targetRot

            char:PivotTo(currentCF)
            root.CFrame = currentCF
            local cp = char:FindFirstChild("CollisionPart")
            if cp then cp.CFrame = currentCF end
            local mgTable = getMainGameTable()
            if mgTable then mgTable.SETNEWCF = currentCF end

            root.AssemblyLinearVelocity = moveDir * speed
            root.AssemblyAngularVelocity = Vector3.zero

            -- Continuous slide timer refresh every 0.60s to keep server-side slide authorizer perpetually active
            if (now - lastSlidePulse >= 0.60) then
                lastSlidePulse = now
                task.spawn(pulseSlideKeepAlive)
            end

            -- Auto-open doors encountered along flight path
            if autoDoorOpen ~= false then
                processNearbyDoors(currentSubPos, 22)
            end
        else
            -- Intermediate waypoints advance immediately without stopping in mid-air
            if not isFinalDestination then
                if conn then conn:Disconnect() end
                if activeTweenToken == token then isTeleportTweening = false end
                local nextCF = CFrame.new(targetPos) * targetRot
                char:PivotTo(nextCF)
                root.CFrame = nextCF
                local cp = char:FindFirstChild("CollisionPart")
                if cp then cp.CFrame = nextCF end
                local mgTable = getMainGameTable()
                if mgTable then mgTable.SETNEWCF = nextCF end
                if callback then callback() end
                return
            end

            -- Server Acceptance Phase (Arrival Landing Handshake):
            -- Clamps all character master parts, restores interactivity, and triggers physics wake packet
            if not settleStartTime then
                settleStartTime = now
                local finalCF = CFrame.new(targetPos) * targetRot
                char:PivotTo(finalCF)
                root.CFrame = finalCF
                local cp = char:FindFirstChild("CollisionPart")
                if cp then cp.CFrame = finalCF end
                local mgTable = getMainGameTable()
                if mgTable then mgTable.SETNEWCF = finalCF end
                restoreCharacterInteractivity(char)
            end

            local finalCF = CFrame.new(targetPos) * targetRot
            char:PivotTo(finalCF)
            root.CFrame = finalCF
            local cp = char:FindFirstChild("CollisionPart")
            if cp then cp.CFrame = finalCF end
            local mgTable = getMainGameTable()
            if mgTable then mgTable.SETNEWCF = finalCF end

            if now - settleStartTime >= 0.15 then
                if conn then conn:Disconnect() end
                if activeTweenToken == token then
                    isTeleportTweening = false
                    teleportImmunityUntil = os.clock() + 1.2
                end

                restoreCharacterInteractivity(char)

                -- Physics Replication Wake Pulse: micro velocity impulse forces Roblox network pipeline to transmit position packet!
                root.AssemblyLinearVelocity = Vector3.new(0, 0.12, 0)
                task.defer(function()
                    if root and root.Parent then
                        root.AssemblyLinearVelocity = Vector3.new(0, -0.12, 0)
                        task.wait(0.02)
                        root.AssemblyLinearVelocity = Vector3.zero
                        root.AssemblyAngularVelocity = Vector3.zero
                    end
                end)

                -- Server State Slide Handshake: cycles Crouch remote to force server to register position at new coordinates!
                if crouchRemote then
                    pcall(function()
                        crouchRemote:FireServer(false, false)
                        task.wait(0.02)
                        crouchRemote:FireServer(false, true)
                        task.wait(0.02)
                        crouchRemote:FireServer(false, false)
                    end)
                end

                if callback then callback() end
            end
        end
    end)

    return true
end

-- Multi-Segment Waypoint Traverser: Follows clear hallway waypoints and pulses slide state on each segment
local function safeMultiSegmentTeleport(targetCF, speedVal, autoDoorOpen, callback)
    local char = getChar()
    local root = getRoot()
    if not char or not root then return false end

    local targetCFrame = (typeof(targetCF) == "Vector3") and CFrame.new(targetCF) or targetCF
    local targetPos = targetCFrame.Position
    local targetRot = targetCFrame - targetPos
    local startPos = root.Position

    local waypoints = getNavigationWaypoints(startPos, targetPos)

    local function runSegment(idx)
        if idx > #waypoints then
            if callback then callback() end
            return
        end
        local wp = waypoints[idx]
        local isLast = (idx == #waypoints)
        local cf = isLast and (CFrame.new(wp) * targetRot) or CFrame.new(wp, isLast and targetPos or (waypoints[idx+1] or targetPos))
        
        -- Pulse slide refresh before each micro-burst segment
        if idx > 1 then
            pulseSlideKeepAlive()
            task.wait(0.04)
        end

        safeTweenTeleport(cf, speedVal, autoDoorOpen, isLast, function()
            runSegment(idx + 1)
        end)
    end

    runSegment(1)
    return true
end

local function teleportToRoomKey(callback)
    local char = getChar()
    local root = getRoot()
    if not char or not root then
        if callback then callback(false) end
        return false
    end

    local curRooms = Workspace:FindFirstChild("CurrentRooms")
    if not curRooms then
        if callback then callback(false) end
        return false
    end

    local targetKey = nil
    local targetPart = nil
    local minDist = math.huge

    for _, desc in ipairs(curRooms:GetDescendants()) do
        if desc.Name == "KeyObtain" or (desc.Name:lower():find("key") and desc:IsA("Model") and desc:FindFirstChildWhichIsA("ProximityPrompt", true)) then
            local part = desc:IsA("Model") and (desc.PrimaryPart or desc:FindFirstChildWhichIsA("BasePart", true)) or (desc:IsA("BasePart") and desc)
            if part then
                local d = (root.Position - part.Position).Magnitude
                if d < minDist then
                    minDist = d
                    targetKey = desc
                    targetPart = part
                end
            end
        end
    end

    if not targetKey or not targetPart then
        Hub.Notify("Teleport", "No Key / Objective found in active rooms!", 2)
        if callback then callback(false) end
        return false
    end

    Hub.Notify("Teleport", "Navigating to " .. targetKey.Name .. "...", 2)
    local toPlayer = (root.Position - targetPart.Position)
    local hDir = Vector3.new(toPlayer.X, 0, toPlayer.Z)
    local standDir = (hDir.Magnitude > 0.1) and hDir.Unit or Vector3.new(0, 0, 1)
    local rawTargetPos = targetPart.Position + standDir * 3.2
    local targetPos = getExactFloorPos(rawTargetPos)
    local lookTarget = Vector3.new(targetPart.Position.X, targetPos.Y, targetPart.Position.Z)

    safeMultiSegmentTeleport(CFrame.new(targetPos, lookTarget), State.Teleport_Speed, true, function()
        task.wait(0.1)
        -- Container check: If key is inside a drawer/container, unlock/open the container first
        local parentModel = targetKey.Parent
        if parentModel and parentModel:IsA("Model") and parentModel ~= curRooms then
            for _, dPrompt in ipairs(parentModel:GetDescendants()) do
                if dPrompt:IsA("ProximityPrompt") and dPrompt.Parent ~= targetKey and dPrompt.Enabled then
                    pcall(function()
                        dPrompt.HoldDuration = 0
                        fireproximityprompt(dPrompt)
                    end)
                    task.wait(0.2)
                    break
                end
            end
        end

        local prompt = targetKey:FindFirstChildWhichIsA("ProximityPrompt", true)
        if prompt then
            pcall(function()
                prompt.Enabled = true
                prompt.HoldDuration = 0
                fireproximityprompt(prompt)
            end)
        end
        local hum = char:FindFirstChildWhichIsA("Humanoid")
        task.wait(0.3)
        local keyTool = LocalPlayer.Backpack:FindFirstChild("Key") or (getChar() and getChar():FindFirstChild("Key"))
        if keyTool and hum then hum:EquipTool(keyTool) end
        Hub.Notify("Teleport", "Collected " .. targetKey.Name .. "!", 2)
        if callback then callback(true) end
    end)
    return true
end

local function teleportToNextDoor(callback)
    local char = getChar()
    local root = getRoot()
    if not char or not root then
        Hub.Notify("Teleport", "Character not found!", 2)
        if callback then callback(false) end
        return false
    end

    local curRooms = Workspace:FindFirstChild("CurrentRooms")
    local gd = game:GetService("ReplicatedStorage"):FindFirstChild("GameData")
    local lrVal = gd and gd:FindFirstChild("LatestRoom") and gd.LatestRoom.Value or 0
    local curRoom = curRooms and curRooms:FindFirstChild(tostring(lrVal))
    if not curRoom then
        Hub.Notify("Teleport", "Room " .. tostring(lrVal) .. " not loaded!", 2)
        if callback then callback(false) end
        return false
    end

    local exitDoor = curRoom:FindFirstChild("Door")
    if not exitDoor then
        Hub.Notify("Teleport", "Exit Door for Room " .. tostring(lrVal) .. " not found!", 2)
        if callback then callback(false) end
        return false
    end

    local doorPart = exitDoor:FindFirstChild("Hidden") or exitDoor:FindFirstChild("Door") or exitDoor.PrimaryPart or exitDoor:FindFirstChildWhichIsA("BasePart")
    if not doorPart then
        Hub.Notify("Teleport", "Door part not resolved!", 2)
        if callback then callback(false) end
        return false
    end

    -- Pre-flight Lock Check: If door has a lock and player has no key, fetch key first
    local lock = exitDoor:FindFirstChild("Lock")
    if lock then
        local keyTool = LocalPlayer.Backpack:FindFirstChild("Key") or char:FindFirstChild("Key")
        if not keyTool then
            Hub.Notify("Teleport", "Door is locked! Auto-retrieving room key...", 2)
            teleportToRoomKey(function(success)
                if success then
                    task.wait(0.3)
                    teleportToNextDoor(callback)
                else
                    Hub.Notify("Teleport", "Key not found in room! Teleport aborted.", 2)
                    if callback then callback(false) end
                end
            end)
            return true
        end
    end

    local playerPos = root.Position
    local doorPos = doorPart.Position
    local doorCF = doorPart.CFrame

    -- Approach Vector Invariant: Vector pointing from door back towards player's position
    local toPlayer = (playerPos - doorPos)
    local hToPlayer = Vector3.new(toPlayer.X, 0, toPlayer.Z)
    local approachDir = (hToPlayer.Magnitude > 0.1) and hToPlayer.Unit or -doorCF.LookVector

    -- Target: 3.5 studs in front of door strictly inside CURRENT room at exact floor height
    local rawTargetPos = Vector3.new(doorPos.X + approachDir.X * 3.5, doorPos.Y, doorPos.Z + approachDir.Z * 3.5)
    local targetPos = getExactFloorPos(rawTargetPos)
    local lookTarget = Vector3.new(doorPos.X, targetPos.Y, doorPos.Z)

    Hub.Notify("Teleport", "Navigating to Door " .. tostring(lrVal) .. "...", 2)

    safeMultiSegmentTeleport(CFrame.new(targetPos, lookTarget), State.Teleport_Speed, true, function()
        task.wait(0.1)

        -- 1. Auto-unlock if lock exists and key held
        local currentLock = exitDoor:FindFirstChild("Lock")
        if currentLock then
            local keyTool = LocalPlayer.Backpack:FindFirstChild("Key") or char:FindFirstChild("Key")
            local hum = char:FindFirstChildWhichIsA("Humanoid")
            if keyTool and keyTool.Parent == LocalPlayer.Backpack and hum then
                hum:EquipTool(keyTool)
                task.wait(0.15)
            end
            local up = currentLock:FindFirstChild("UnlockPrompt", true)
            if up and up.Enabled then
                pcall(function()
                    up.HoldDuration = 0
                    fireproximityprompt(up)
                end)
                task.wait(0.25)
            end
        end

        -- 2. Open door via ClientOpen, Touch interest & ProximityPrompt
        local co = exitDoor:FindFirstChild("ClientOpen")
        if co then
            pcall(function() co:FireServer() end)
        end

        local hiddenPart = exitDoor:FindFirstChild("Hidden")
        if hiddenPart and hiddenPart:IsA("BasePart") then
            pcall(function()
                hiddenPart.CanTouch = true
                if root then
                    firetouchinterest(root, hiddenPart, 0)
                    task.wait()
                    firetouchinterest(root, hiddenPart, 1)
                end
            end)
        end

        local mop = exitDoor:FindFirstChildWhichIsA("ProximityPrompt", true)
        if mop and mop.Enabled then
            pcall(function()
                mop.HoldDuration = 0
                fireproximityprompt(mop)
            end)
        end

        -- Strip collisions on all door parts so threshold crossing never trips geometry
        for _, dp in ipairs(exitDoor:GetDescendants()) do
            if dp:IsA("BasePart") and not dp.Name:lower():find("frame") then
                dp.CanCollide = false
            end
        end

        -- 3. Await server room confirmation before stepping across threshold
        local confirmed = false
        for _ = 1, 25 do
            if gd and gd.LatestRoom and gd.LatestRoom.Value > lrVal then
                confirmed = true
                break
            end
            task.wait(0.06)
        end

        -- 4. Step through door into next room ONLY if opened/confirmed
        if confirmed then
            task.wait(0.12)
            local rawThroughPos = Vector3.new(doorPos.X - approachDir.X * 3.5, doorPos.Y, doorPos.Z - approachDir.Z * 3.5)
            local throughPos = getExactFloorPos(rawThroughPos)
            local throughLook = throughPos - approachDir * 5
            safeTweenTeleport(CFrame.new(throughPos, throughLook), State.Teleport_Speed, false, true, function()
                teleportImmunityUntil = os.clock() + 2.0
                local nextVal = gd and gd.LatestRoom and gd.LatestRoom.Value or (lrVal + 1)
                Hub.Notify("Teleport", "Entered Room " .. tostring(nextVal) .. "!", 2)
                if callback then callback(true) end
            end)
        else
            -- If not confirmed, do not cross threshold into unspawned/unopened room!
            Hub.Notify("Teleport", "Door opened. Step through manually or retry.", 2)
            if callback then callback(false) end
        end
    end)
    return true
end

_G.TeleportToNextDoor = teleportToNextDoor
_G.TeleportToRoomKey = teleportToRoomKey
if getgenv then
    getgenv().TeleportToNextDoor = teleportToNextDoor
    getgenv().TeleportToRoomKey = teleportToRoomKey
end

local isAtRoof = false
local roofPlatform = nil
local lastPreRoofFloorPos = nil

local function getOrCreateRoofPlatform(targetPos)
    if roofPlatform and roofPlatform.Parent then
        roofPlatform.CFrame = CFrame.new(targetPos - Vector3.new(0, 3.2, 0))
        return roofPlatform
    end
    local plat = Instance.new("Part")
    plat.Name = "SafeRoofPlatform"
    plat.Size = Vector3.new(24, 1.2, 24)
    plat.Anchored = true
    plat.CanCollide = true
    plat.Transparency = 0.5
    plat.Material = Enum.Material.Neon
    plat.Color = Color3.fromRGB(0, 220, 255)
    plat.CFrame = CFrame.new(targetPos - Vector3.new(0, 3.2, 0))
    plat.Parent = Workspace.CurrentCamera
    roofPlatform = plat
    return plat
end

local function removeRoofPlatform()
    if roofPlatform then
        pcall(function() roofPlatform:Destroy() end)
        roofPlatform = nil
    end
end

local function teleportToRoof(callback)
    local char = getChar()
    local root = getRoot()
    local hum = char and char:FindFirstChildWhichIsA("Humanoid")
    if not char or not root or not hum or hum.Health <= 0 then return false end

    if isAtRoof then
        Hub.Notify("Safe Zone", "Already stationed on Safe Roof!", 2)
        if callback then callback(true) end
        return true
    end

    lastPreRoofFloorPos = root.Position
    local roofTargetPos = root.Position + Vector3.new(0, 35, 0)
    
    getOrCreateRoofPlatform(roofTargetPos)
    Hub.Notify("Safe Zone", "Ascending to Safe Roof (+35 Studs)...", 2)
    isAtRoof = true
    State.Safe_Roof_Station = true

    -- Pre-open all nearby doors and strip ceiling collision above character
    processNearbyDoors(root.Position, 40)
    pcall(function()
        local rayParams = RaycastParams.new()
        rayParams.FilterDescendantsInstances = {char, Workspace.CurrentCamera}
        rayParams.FilterType = Enum.RaycastFilterType.Exclude
        local upHit = workspace:Raycast(root.Position, Vector3.new(0, 45, 0), rayParams)
        if upHit and upHit.Instance then
            upHit.Instance.CanCollide = false
        end
    end)

    safeTweenTeleport(CFrame.new(roofTargetPos, roofTargetPos + root.CFrame.LookVector), 65, true, true, function()
        char:PivotTo(CFrame.new(roofTargetPos, roofTargetPos + root.CFrame.LookVector))
        root.CFrame = CFrame.new(roofTargetPos, roofTargetPos + root.CFrame.LookVector)
        local cp = char:FindFirstChild("CollisionPart")
        if cp then cp.CFrame = CFrame.new(roofTargetPos, roofTargetPos + root.CFrame.LookVector) end
        root.AssemblyLinearVelocity = Vector3.zero
        Hub.Notify("Safe Zone", "Secure on Safe Roof! Rush & entities deflected.", 3)
        if callback then callback(true) end
    end)
    return true
end

local function returnFromRoof(callback)
    local char = getChar()
    local root = getRoot()
    local hum = char and char:FindFirstChildWhichIsA("Humanoid")
    if not char or not root or not hum or hum.Health <= 0 then return false end

    if not isAtRoof and root.Position.Y < 25 then
        Hub.Notify("Safe Zone", "Not currently on roof!", 2)
        if callback then callback(false) end
        return false
    end

    Hub.Notify("Safe Zone", "Safely descending from roof...", 2)

    local targetFloorPos = getExactFloorPos(Vector3.new(root.Position.X, (lastPreRoofFloorPos and lastPreRoofFloorPos.Y) or (root.Position.Y - 35), root.Position.Z))

    safeTweenTeleport(CFrame.new(targetFloorPos, targetFloorPos + root.CFrame.LookVector), 55, false, function()
        removeRoofPlatform()
        isAtRoof = false
        State.Safe_Roof_Station = false
        lastPreRoofFloorPos = nil
        restoreCharacterInteractivity(char)
        Hub.Notify("Safe Zone", "Landed safely on room floor!", 2)
        if callback then callback(true) end
    end)
    return true
end

-- Teleport to Nearest Safe Closet / Wardrobe / Bed with Auto-Hide Prompt (100% Server Validated & Rush Immune)
local function teleportToNearestSafeSpot(callback)
    local char = getChar()
    local root = getRoot()
    local hum = char and char:FindFirstChildWhichIsA("Humanoid")
    if not char or not root or not hum or hum.Health <= 0 then return false end

    local curRooms = Workspace:FindFirstChild("CurrentRooms")
    if not curRooms then return false end

    local nearestSpot = nil
    local nearestPrompt = nil
    local nearestPart = nil
    local minDist = math.huge

    for _, desc in ipairs(curRooms:GetDescendants()) do
        if desc:IsA("Model") then
            local n = desc.Name:lower()
            if n:find("wardrobe") or n:find("closet") or n:find("bed") or n:find("locker") then
                local prompt = desc:FindFirstChildWhichIsA("ProximityPrompt", true)
                local part = desc.PrimaryPart or desc:FindFirstChildWhichIsA("BasePart", true)
                if part and prompt and prompt.Enabled then
                    local d = (root.Position - part.Position).Magnitude
                    if d < minDist then
                        minDist = d
                        nearestSpot = desc
                        nearestPrompt = prompt
                        nearestPart = part
                    end
                end
            end
        end
    end

    if not nearestSpot or not nearestPart then
        Hub.Notify("Safe Spot", "No accessible closet/wardrobe found nearby!", 3)
        if callback then callback(false) end
        return false
    end

    Hub.Notify("Safe Spot", "Evacuating to " .. nearestSpot.Name .. "...", 2)

    local forward = nearestPart.CFrame.LookVector
    local rawStandPos = nearestPart.Position + forward * 2.8
    local standPos = getExactFloorPos(rawStandPos)
    local lookTarget = Vector3.new(nearestPart.Position.X, standPos.Y, nearestPart.Position.Z)

    safeMultiSegmentTeleport(CFrame.new(standPos, lookTarget), State.Teleport_Speed, true, function()
        task.wait(0.08)
        if nearestPrompt and nearestPrompt.Enabled then
            pcall(function()
                nearestPrompt.HoldDuration = 0
                fireproximityprompt(nearestPrompt)
            end)
        end
        Hub.Notify("Safe Spot", "Secure inside " .. nearestSpot.Name .. "! Rush & entities cannot harm you.", 3)
        if callback then callback(true) end
    end)
    return true
end

_G.TeleportToRoof = teleportToRoof
_G.ReturnFromRoof = returnFromRoof
_G.TeleportToNearestSafeSpot = teleportToNearestSafeSpot
if getgenv then
    getgenv().TeleportToRoof = teleportToRoof
    getgenv().ReturnFromRoof = returnFromRoof
    getgenv().TeleportToNearestSafeSpot = teleportToNearestSafeSpot
    getgenv().TeleportToNearestHidingSpot = teleportToNearestSafeSpot
end

local isAutoNavigatingRooms = false
local function autoNavigateToRoom(targetRoom)
    if isAutoNavigatingRooms then
        isAutoNavigatingRooms = false
        Hub.Notify("Room Navigator", "Navigation cancelled.", 2)
        return
    end

    isAutoNavigatingRooms = true
    Hub.Notify("Room Navigator", "Auto-advancing to Room " .. tostring(targetRoom) .. "...", 3)

    task.spawn(function()
        while isAutoNavigatingRooms do
            if _G.DOORS_SESSION ~= currentSession then break end
            local gd = game:GetService("ReplicatedStorage"):FindFirstChild("GameData")
            local lr = gd and gd:FindFirstChild("LatestRoom") and gd.LatestRoom.Value or 0
            if lr >= targetRoom then
                Hub.Notify("Room Navigator", "Target Room " .. tostring(targetRoom) .. " Reached!", 4)
                break
            end

            -- 1. Grab Key if door locked
            local curRooms = Workspace:FindFirstChild("CurrentRooms")
            local cRoom = curRooms and curRooms:FindFirstChild(tostring(lr))
            local door = cRoom and cRoom:FindFirstChild("Door")
            local lock = door and door:FindFirstChild("Lock")
            if lock and lock:FindFirstChild("UnlockPrompt", true) then
                local hasKey = LocalPlayer.Backpack:FindFirstChild("Key") ~= nil or (getChar() and getChar():FindFirstChild("Key") ~= nil)
                if not hasKey then
                    teleportToRoomKey()
                    task.wait(1.5)
                end
            end

            -- 2. Teleport to Exit Door
            teleportToNextDoor()
            task.wait(1.2)

            -- Wait for next room to spawn
            local attempts = 0
            while isAutoNavigatingRooms and attempts < 15 do
                local curLr = gd and gd:FindFirstChild("LatestRoom") and gd.LatestRoom.Value or 0
                if curLr > lr then break end
                task.wait(0.2)
                attempts = attempts + 1
            end
        end
        isAutoNavigatingRooms = false
    end)
end

-- =========================================================================
-- Continuous Heartbeat Enforcement & Omnidirectional Phase Noclip Engine
-- =========================================================================
RunService.Heartbeat:Connect(function(dt)
    if _G.DOORS_SESSION ~= currentSession then return end
    local char = getChar()
    local root = getRoot()
    local hum = char and char:FindFirstChildWhichIsA("Humanoid")
    if not hum or not hum.Parent or not root then return end

    local mgTable = getMainGameTable()
    local hiding = isPlayerHiding(char, mgTable) or (os.clock() < unhideGraceUntil)

    -- Auto-disable Noclip if Bypass Anti-Cheat Core is disabled
    if State.Noclip and not State.Bypass_AntiCheat then
        State.Noclip = false
        restoreCharacterInteractivity(char)
        if root then root.AssemblyLinearVelocity = Vector3.zero end
        syncServerSlide(false, false)
        Hub.Notify("Movement", "Fly-Noclip disabled: Bypass Anti-Cheat Core is required!", 2)
    end

    -- Continuous Door Sentry: Always opens doors and removes collisions smoothly on approach
    if root and not hiding then
        processNearbyDoors(root.Position, 30)
    end

    -- Continuous Glitch / Void Shield Deflector: Eradicates all screen freezes, camera locks & fog spikes
    if not hiding and (State.Noclip or State.Deflect_Glitch or State.Bypass_AntiCheat) then
        if mgTable then
            if mgTable.stopcam then mgTable.stopcam = false end
            if mgTable.hideplayers and mgTable.hideplayers ~= 0 then mgTable.hideplayers = 0 end
        end
        if root and root.Anchored then
            root.Anchored = false
        end
        local pGui = LocalPlayer:FindFirstChild("PlayerGui")
        local mainUI = pGui and pGui:FindFirstChild("MainUI")
        local mainFrame = mainUI and mainUI:FindFirstChild("MainFrame")
        if mainFrame then
            local gs = mainFrame:FindFirstChild("GlitchScreen")
            if gs and gs.Visible then gs.Visible = false end
            local ge = mainFrame:FindFirstChild("GlitchEffect")
            if ge and ge.Visible then ge.Visible = false end
        end
        local lt = game:GetService("Lighting")
        if lt and lt.FogEnd < 200 then
            lt.FogEnd = 1000
            lt.FogStart = 0
        end
    end

    -- True DOORS Native 3D Flight & Noclip Engine (100% Butter-Smooth, Zero-Jitter, Zero-Lag)
    if State.Noclip and State.Bypass_AntiCheat and not hiding and not isTeleportTweening then
        _G.__BLOCK_EQ_NOCLIP = true

        -- Cloak player on server as 'Hiding' so Rush, Ambush, and entities out-of-bounds treat player as protected in closet
        if not char:GetAttribute("Hiding") then
            char:SetAttribute("Hiding", true)
        end

        local mg = getMainGameTable()
        if mg then
            if not mg.noclip then
                mg.noclip = true
            end
            if mg.crouching then
                mg.crouching = false
            end
        end

        -- Synchronize root CFrame to CollisionPart for pixel-perfect physics and camera alignment
        local cp = char:FindFirstChild("CollisionPart")
        if cp and root then
            root.CFrame = cp.CFrame
        end

        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero

        -- Anti-Void Floor Safeguard: If falling into void, smoothly restore to safe room floor (ONLY when not hiding!)
        if not hiding and root.Position.Y < -5 then
            local safeLanding = getSafeLandingPosition()
            if safeLanding then
                local safeCF = CFrame.new(safeLanding, safeLanding + root.CFrame.LookVector)
                char:PivotTo(safeCF)
                root.CFrame = safeCF
                if mg then mg.clipPos = safeLanding end
            else
                local safeCF = CFrame.new(root.Position.X, 3.5, root.Position.Z) * root.CFrame.Rotation
                char:PivotTo(safeCF)
                root.CFrame = safeCF
                if mg then mg.clipPos = Vector3.new(root.Position.X, 3.5, root.Position.Z) end
            end
        end
    elseif State.WalkSpeed_Enabled and not hiding and not isTeleportTweening then
        _G.__BLOCK_EQ_NOCLIP = false
        applyTeflonGlide(char)
        syncServerSlide(true, isSlidingActive)

        local targetSpeed = State.WalkSpeed_Value
        if hum.WalkSpeed ~= targetSpeed then
            hum.WalkSpeed = targetSpeed
        end

        -- Instant Responsive Movement (No Slip / Zero Acceleration Drift):
        -- Horizontal velocity is immediately redirected into the current MoveDirection without slipping
        if State.Instant_Movement and not isSlidingActive then
            local moveDir = hum.MoveDirection
            local curY = root.AssemblyLinearVelocity.Y
            if moveDir.Magnitude > 0.05 then
                local rayParams = RaycastParams.new()
                rayParams.FilterDescendantsInstances = {char, Workspace.CurrentCamera}
                rayParams.FilterType = Enum.RaycastFilterType.Exclude
                rayParams.RespectCanCollide = true

                local rayOrigin = root.Position + Vector3.new(0, 0.4, 0)
                local hit = workspace:Raycast(rayOrigin, moveDir * 1.5, rayParams)
                if hit and hit.Instance and hit.Instance.CanCollide then
                    local n = hit.Normal
                    local hNormal = Vector3.new(n.X, 0, n.Z)
                    if hNormal.Magnitude > 0.1 then
                        hNormal = hNormal.Unit
                        local dot = moveDir:Dot(hNormal)
                        if dot < 0 then
                            local deflected = (moveDir - hNormal * dot)
                            if deflected.Magnitude > 0.05 then
                                moveDir = deflected.Unit
                            end
                        end
                    end
                end

                root.AssemblyLinearVelocity = Vector3.new(moveDir.X * targetSpeed, curY, moveDir.Z * targetSpeed)
            else
                root.AssemblyLinearVelocity = Vector3.new(0, curY, 0)
            end
        end

        -- Ensure opened doors across all active rooms remain 100% collision-free
        local currentRooms = Workspace:FindFirstChild("CurrentRooms")
        if currentRooms then
            for _, r in ipairs(currentRooms:GetChildren()) do
                local d = r:FindFirstChild("Door")
                if d and (d:GetAttribute("Opened") == true or d:FindFirstChild("ClientOpen") ~= nil or d:GetAttribute("Open") == true) then
                    for _, part in ipairs(d:GetDescendants()) do
                        if part:IsA("BasePart") and part.CanCollide and not part.Name:lower():find("frame") then
                            part.CanCollide = false
                        end
                    end
                end
            end
        end
    else
        if not State.Noclip and not State.Enable_Sliding and not isTeleportImmune() then
            syncServerSlide(false, false)
        end
        if hum.WalkSpeed ~= 15 and not State.WalkSpeed_Enabled then
            hum.WalkSpeed = 15
        end
    end

    -- Sliding Velocity Maintenance (Smooth forward momentum with natural deceleration)
    if isSlidingActive and not hiding then
        local elapsed = os.clock() - slideStartTime
        if elapsed > 1.25 or hum.MoveDirection.Magnitude < 0.05 then
            stopSlide()
        else
            local targetSpeed = math.max(State.WalkSpeed_Value or 35, 42)
            local slideSpeed = targetSpeed * math.clamp(1 - (elapsed / 1.35) * 0.45, 0.5, 1.0)
            root.AssemblyLinearVelocity = Vector3.new(slideDirection.X * slideSpeed, root.AssemblyLinearVelocity.Y, slideDirection.Z * slideSpeed)
        end
    end

    -- Keep Safe Roof Platform dynamically centered under daddy horizontally
    if isAtRoof and roofPlatform and roofPlatform.Parent and root then
        roofPlatform.CFrame = CFrame.new(root.Position.X, roofPlatform.Position.Y, root.Position.Z)
    end

    -- Synchronizes DOORS native noclip flag without corrupting wardrobe or door transitions
    local mgTable = getMainGameTable()
    if mgTable then
        if isTeleportTweening then
            if mgTable.SETNEWCF then
                mgTable.SETNEWCF = nil
            end
        end
        if State.Noclip then
            mgTable.noclip = true
        elseif mgTable.noclip then
            mgTable.noclip = false
        end
    end
end)

-- Stepped Guard: Strips collisions & touch on character parts during Noclip
RunService.Stepped:Connect(function()
    if _G.DOORS_SESSION ~= currentSession then return end
    local char = getChar()
    local mgTable = getMainGameTable()
    if isPlayerHiding(char, mgTable) or (os.clock() < unhideGraceUntil) then return end

    local hum = char and char:FindFirstChildWhichIsA("Humanoid")
    if not hum then return end

    if State.WalkSpeed_Enabled and not State.Noclip then
        local targetSpeed = State.WalkSpeed_Value
        if hum.WalkSpeed ~= targetSpeed then
            hum.WalkSpeed = targetSpeed
        end
    end

    if State.Enable_Jumping then
        if not hum.UseJumpPower then hum.UseJumpPower = true end
        if hum.JumpPower < 50 then hum.JumpPower = 52 end
        if hum.JumpHeight < 5 then hum.JumpHeight = 7.5 end
        if not hum:GetStateEnabled(Enum.HumanoidStateType.Jumping) then
            hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
        end
    end

    if State.Noclip or State.Fly_Enabled or isTeleportTweening then
        -- Strip CanCollide only during active movement, preserving CanTouch and CanQuery so doors & proximity prompts work flawlessly!
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                if part.CanCollide then part.CanCollide = false end
                if not part.CanTouch then part.CanTouch = true end
                if not part.CanQuery then part.CanQuery = true end
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
    if State.Enable_Jumping then
        local hum = char:WaitForChild("Humanoid", 5)
        if hum then
            hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
            hum.UseJumpPower = true
            hum.JumpPower = 52
            hum.JumpHeight = 7.5
        end
    end
    if State.Enable_Sliding then
        applyTeflonGlide(char)
    end
end)

-- =========================================================================
-- Jumping & Sliding Engine (DOORS Freedom Movement)
-- =========================================================================

UserInputService.JumpRequest:Connect(function()
    if State.Enable_Jumping then
        local char = getChar()
        local root = getRoot()
        local hum = char and char:FindFirstChildWhichIsA("Humanoid")
        if hum and hum.Health > 0 and hum:GetState() ~= Enum.HumanoidStateType.Dead then
            if not hum:GetStateEnabled(Enum.HumanoidStateType.Jumping) then
                hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
            end
            hum.UseJumpPower = true
            hum.JumpPower = 52
            hum.JumpHeight = 7.5
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
            if root and math.abs(root.AssemblyLinearVelocity.Y) < 2.0 then
                root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, 52, root.AssemblyLinearVelocity.Z)
            end
        end
    end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    -- Click to Teleport (Ctrl + Left Click)
    if State.ClickTP_Enabled and input.UserInputType == Enum.UserInputType.MouseButton1 and not gameProcessed then
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl) then
            local mouse = LocalPlayer:GetMouse()
            if mouse and mouse.Hit then
                safeMultiSegmentTeleport(CFrame.new(mouse.Hit.Position + Vector3.new(0, 2.5, 0)), State.Teleport_Speed, true)
            end
        end
    end

    if input.KeyCode == Enum.KeyCode.C or input.KeyCode == Enum.KeyCode.LeftControl then
        if State.Enable_Sliding then
            local char = getChar()
            local hum = char and char:FindFirstChildWhichIsA("Humanoid")
            if hum and hum.MoveDirection.Magnitude > 0.1 then
                startSlide()
            end
        end
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.C or input.KeyCode == Enum.KeyCode.LeftControl then
        if isSlidingActive then
            stopSlide()
        end
    end
end)

-- Mobile Crouch Button Slide Support
pcall(function()
    local pGui = LocalPlayer:FindFirstChild("PlayerGui")
    local crBtn = pGui and pGui:FindFirstChild("MainUI") and pGui.MainUI:FindFirstChild("MainFrame")
        and pGui.MainUI.MainFrame:FindFirstChild("MobileButtons")
        and pGui.MainUI.MainFrame.MobileButtons:FindFirstChild("CrouchButton")
    if crBtn then
        crBtn.InputBegan:Connect(function()
            if State.Enable_Sliding then
                local char = getChar()
                local hum = char and char:FindFirstChildWhichIsA("Humanoid")
                if hum and hum.MoveDirection.Magnitude > 0.15 then
                    startSlide()
                end
            end
        end)
        crBtn.InputEnded:Connect(function()
            if isSlidingActive then stopSlide() end
        end)
    end
end)

-- =========================================================================
-- Interaction Engine (Instant Interact, Noclip Interact, Range Interact, Auto Interact)
-- =========================================================================
local function applyPromptModifications(prompt)
    if not prompt or not prompt:IsA("ProximityPrompt") then return end

    if not prompt:GetAttribute("OrigHold") then
        prompt:SetAttribute("OrigHold", prompt.HoldDuration)
    end
    if not prompt:GetAttribute("OrigLOS") then
        prompt:SetAttribute("OrigLOS", prompt.RequiresLineOfSight)
    end
    if not prompt:GetAttribute("OrigMaxDist") then
        prompt:SetAttribute("OrigMaxDist", prompt.MaxActivationDistance)
    end

    local pObj = (prompt.ObjectText or ""):lower()
    local pAct = (prompt.ActionText or ""):lower()
    local parentName = prompt.Parent and prompt.Parent.Name:lower() or ""
    local isDrawerOrContainer = pObj:find("drawer") or pObj:find("desk") or parentName:find("knob")
    local isHidingSpot = pObj:find("wardrobe") or pObj:find("closet") or pObj:find("locker") or pObj:find("bed") or parentName:find("wardrobe") or parentName:find("closet") or parentName:find("locker") or parentName:find("bed") or pAct:find("hide")
    local isDoorPrompt = pObj:find("door") or parentName:find("door") or pAct:find("open") or pAct:find("unlock")

    if State.Instant_Interact or isHidingSpot then
        prompt.HoldDuration = 0
    else
        local orig = prompt:GetAttribute("OrigHold")
        if orig ~= nil then prompt.HoldDuration = orig end
    end

    -- Wardrobes and doors NEVER require LineOfSight, eliminating angle occlusion and geometry blocks!
    if isHidingSpot or isDoorPrompt or State.Noclip_Interact then
        prompt.RequiresLineOfSight = false
    else
        local orig = prompt:GetAttribute("OrigLOS")
        if orig ~= nil then prompt.RequiresLineOfSight = orig end
    end

    if isHidingSpot or isDoorPrompt or State.Range_Interact then
        local baseDist = isHidingSpot and 12 or (isDoorPrompt and 12 or (isDrawerOrContainer and 10 or State.Interact_MaxRange))
        prompt.MaxActivationDistance = math.max(prompt.MaxActivationDistance or 0, baseDist)
    else
        local orig = prompt:GetAttribute("OrigMaxDist")
        if orig ~= nil then prompt.MaxActivationDistance = orig end
    end
end

local function refreshAllPrompts()
    for _, desc in ipairs(Workspace:GetDescendants()) do
        if desc:IsA("ProximityPrompt") then
            pcall(function() applyPromptModifications(desc) end)
        end
    end
end

-- Hook new prompts dynamically and ensure immediate optimization on load & room transition
Workspace.DescendantAdded:Connect(function(desc)
    if desc:IsA("ProximityPrompt") then
        task.wait(0.05)
        pcall(function() applyPromptModifications(desc) end)
    end
end)

-- Initial prompt optimization across all loaded rooms
task.spawn(function()
    task.wait(0.25)
    refreshAllPrompts()
end)

-- Auto-refresh prompts whenever new rooms stream in
task.spawn(function()
    local curRooms = Workspace:WaitForChild("CurrentRooms", 5)
    if curRooms then
        curRooms.ChildAdded:Connect(function()
            task.wait(0.2)
            refreshAllPrompts()
        end)
    end
end)

local function isPromptSafeToAutoInteract(prompt)
    if not prompt or not prompt.Enabled or not prompt.Parent then return false end

    local parent = prompt.Parent
    local model = parent:IsA("Model") and parent or parent.Parent
    local mName = model and model.Name:lower() or ""
    local pName = parent.Name:lower()
    local act = (prompt.ActionText or ""):lower()
    local obj = (prompt.ObjectText or ""):lower()

    -- 0. USER CUSTOM KEYWORD EXCLUSIONS
    if State.AutoInteract_CustomKeywords then
        for _, kw in ipairs(State.AutoInteract_CustomKeywords) do
            if kw and #kw > 0 then
                local lkw = kw:lower()
                if pName:find(lkw, 1, true) or mName:find(lkw, 1, true) or obj:find(lkw, 1, true) or act:find(lkw, 1, true) then
                    return false
                end
            end
        end
    end

    -- 1. GLITCH FRAGMENTS (Instant Auto Collect Priority)
    if isGlitchFragmentInstance(model) or isGlitchFragmentInstance(parent) then
        if State.AutoInteract_Excludes and State.AutoInteract_Excludes["Glitch Fragments"] then
            return false
        end
        return true
    end

    -- 2. HARD SAFETY GUARDS (Never close containers or hide in closets accidentally)
    if act:find("close") then
        return false
    end

    if act:find("hide") or pName:find("closet") or pName:find("wardrobe") or pName:find("locker") or mName:find("closet") or mName:find("wardrobe") or mName:find("locker") or mName:find("bed") then
        return false
    end

    -- 3. CATEGORY EXCLUSION LIST CHECKS
    -- Paintings & Pictures
    if pName:find("paint") or pName:find("canvas") or pName:find("frame") or pName:find("picture") or pName:find("portrait")
        or mName:find("paint") or mName:find("canvas") or mName:find("frame") or mName:find("picture") or mName:find("portrait")
        or obj:find("paint") or obj:find("picture") or obj:find("canvas") or obj:find("frame") or obj:find("portrait") then
        if State.AutoInteract_Excludes and State.AutoInteract_Excludes["Paintings & Pictures"] ~= false then
            return false
        end
    end

    -- Fake Doors / Dupe
    if mName:find("fake") or mName:find("dupe") or pName:find("fake") or pName:find("dupe")
        or (model and (model:GetAttribute("Fake") or model:GetAttribute("DupeRoom"))) then
        if State.AutoInteract_Excludes and State.AutoInteract_Excludes["Fake Doors (Dupe)"] ~= false then
            return false
        end
    end

    -- Wall Clocks & Bells
    if obj:find("bell") or act == "ring" or pName:find("bell") or pName:find("clock") or obj:find("clock") then
        if State.AutoInteract_Excludes and State.AutoInteract_Excludes["Wall Clocks & Bells"] ~= false then
            return false
        end
    end

    -- Light Switches & Lamps
    if act == "inspect" or act == "examine" or obj:find("lamp") or obj:find("light") or pName:find("light") or obj:find("switch") then
        if State.AutoInteract_Excludes and State.AutoInteract_Excludes["Light Switches & Lamps"] ~= false then
            return false
        end
    end

    -- 4. FUNCTIONAL PROMPT FILTERS
    -- Normal Exit Doors:
    if mName == "door" or pName == "door" or obj:find("door") or act:find("open door") then
        if State.AutoInteract_Excludes and State.AutoInteract_Excludes["Normal Exit Doors"] then
            return false
        end
        if not State.AutoInteract_Doors then return false end
        if model and model:GetAttribute("Locked") and not State.AutoInteract_Keys then
            return false
        end
        return true
    end

    -- Side Room Doors:
    if (pName:find("sideroom") or mName:find("sideroom") or pName:find("sidedoor") or mName:find("sidedoor")) and (pName:find("door") or mName:find("door")) then
        if State.AutoInteract_Excludes and State.AutoInteract_Excludes["Side Room Doors"] then
            return false
        end
    end

    -- Drawers & Desks (Containers & Drawer Knobs):
    if pName:find("drawer") or mName:find("drawer") or pName:find("desk") or mName:find("desk") or pName:find("dresser") or mName:find("dresser") or pName:find("container") or obj:find("drawer") or pName:find("knob") then
        if State.AutoInteract_Excludes and State.AutoInteract_Excludes["Drawers & Desks"] then
            return false
        end
        if not State.AutoInteract_Drawers then return false end
        if act:find("close") then return false end
        return true
    end

    -- Stardust & Starlight Pickups:
    if obj:find("stardust") or obj:find("starlight") or obj:find("star") or act:find("stardust") or act:find("starlight") or pName:find("stardust") or pName:find("starlight") or mName:find("stardust") or mName:find("starlight") then
        if State.AutoInteract_Excludes and State.AutoInteract_Excludes["Gold & Coins"] then
            return false
        end
        return State.AutoInteract_Items or State.AutoInteract_Gold
    end

    -- Gold / Coins:
    if obj:find("gold") or obj:find("coin") or act:find("gold") or act:find("coin") or pName:find("gold") or mName:find("gold") then
        if State.AutoInteract_Excludes and State.AutoInteract_Excludes["Gold & Coins"] then
            return false
        end
        return State.AutoInteract_Gold
    end

    -- Keys & Skeleton Keys:
    if obj:find("key") or act:find("unlock") or pName:find("key") or mName:find("key") or (model and model:GetAttribute("IsKey")) then
        if State.AutoInteract_Excludes and State.AutoInteract_Excludes["Keys & Skeleton Keys"] then
            return false
        end
        return State.AutoInteract_Keys
    end

    -- Levers & Breakers:
    if obj:find("lever") or act:find("pull") or pName:find("lever") or mName:find("lever") then
        if State.AutoInteract_Excludes and State.AutoInteract_Excludes["Levers & Breakers"] then
            return false
        end
        return State.AutoInteract_Levers
    end
    if pName:find("breaker") or mName:find("breaker") or obj:find("breaker") then
        if State.AutoInteract_Excludes and State.AutoInteract_Excludes["Levers & Breakers"] then
            return false
        end
        return State.AutoInteract_Books
    end

    -- Books & Papers:
    if pName:find("book") or mName:find("book") or obj:find("book") or obj:find("paper") or pName:find("paper") then
        if State.AutoInteract_Excludes and State.AutoInteract_Excludes["Books & Papers"] then
            return false
        end
        return State.AutoInteract_Books
    end

    -- Crucifix & Defense Items:
    if obj:find("crucifix") or obj:find("candle") or pName:find("crucifix") or mName:find("crucifix") then
        if State.AutoInteract_Excludes and State.AutoInteract_Excludes["Crucifix & Defense Items"] then
            return false
        end
        return State.AutoInteract_Items
    end

    -- Lighters & Flashlights:
    if obj:find("lighter") or obj:find("flashlight") or obj:find("battery") or obj:find("bulk") or pName:find("lighter") or pName:find("flashlight") then
        if State.AutoInteract_Excludes and State.AutoInteract_Excludes["Lighters & Flashlights"] then
            return false
        end
        return State.AutoInteract_Items
    end

    -- Health & Bandages:
    if obj:find("bandage") or obj:find("vitamin") or obj:find("herb") or obj:find("plant") or act:find("heal") or act:find("consume") then
        if State.AutoInteract_Excludes and State.AutoInteract_Excludes["Health & Bandages"] then
            return false
        end
        return State.AutoInteract_Items
    end

    -- Lockpicks & Shears:
    if obj:find("lockpick") or obj:find("shears") or obj:find("skeleton") or pName:find("lockpick") or pName:find("shears") then
        if State.AutoInteract_Excludes and State.AutoInteract_Excludes["Lockpicks & Shears"] then
            return false
        end
        return State.AutoInteract_Items
    end

    -- General Items / Pickups:
    if act:find("take") or act:find("pick") or act:find("grab") or act:find("collect") or act:find("obtain") or act:find("use") or act:find("equip") or act:find("claim") or act:find("harvest")
        or obj:find("gummy") or obj:find("shake") or obj:find("pack") or obj:find("barrel") or obj:find("fuse") or obj:find("wrench") or obj:find("anchor") or obj:find("scanner") or obj:find("laser") then
        return State.AutoInteract_Items
    end

    return false
end

-- Auto Interact Worker Thread (Hyper-Fast, Non-Blocking, Debounced & Lag-Free)
local promptDebounce = {}
local lastCleanup = 0

task.spawn(function()
    while true do
        if _G.DOORS_SESSION ~= currentSession then break end
        if State.Auto_Interact then
            local root = getRoot()
            if root then
                local rootPos = root.Position
                local maxDist = State.Range_Interact and math.clamp(State.Interact_MaxRange, 6, 14) or 12
                local now = os.clock()

                -- Clean expired cooldowns periodically (every 5 seconds)
                if now - lastCleanup > 5 then
                    lastCleanup = now
                    for obj, expire in pairs(promptDebounce) do
                        if now >= expire then
                            promptDebounce[obj] = nil
                        end
                    end
                end

                -- High-Performance Proximity Scope: Scans ONLY current room, next room, and Drops (zero FPS lag)
                local curRoom, curNum = getObjectRoom(root)
                local searchContainers = {}
                if curRoom then
                    table.insert(searchContainers, curRoom)
                    if curNum and Workspace:FindFirstChild("CurrentRooms") then
                        local nextRoom = Workspace.CurrentRooms:FindFirstChild(tostring(curNum + 1))
                        if nextRoom then table.insert(searchContainers, nextRoom) end
                    end
                else
                    local cr = Workspace:FindFirstChild("CurrentRooms")
                    if cr then table.insert(searchContainers, cr) end
                end

                local drops = Workspace:FindFirstChild("Drops")
                if drops then table.insert(searchContainers, drops) end

                local batchCount = 0
                for _, container in ipairs(searchContainers) do
                    -- 1. Check ProximityPrompts (Drawers, Items, Keys, Books, Levers, Gold)
                    for _, prompt in ipairs(container:GetDescendants()) do
                        if prompt:IsA("ProximityPrompt") and prompt.Enabled and prompt.Parent then
                            if not promptDebounce[prompt] or now >= promptDebounce[prompt] then
                                local pPart = prompt.Parent:IsA("BasePart") and prompt.Parent or prompt.Parent:FindFirstChildWhichIsA("BasePart")
                                if pPart then
                                    local dist = (rootPos - pPart.Position).Magnitude
                                    local pObj = (prompt.ObjectText or ""):lower()
                                    local isDrawerOrContainer = pObj:find("drawer") or pObj:find("desk") or (prompt.Parent and prompt.Parent.Name:lower():find("knob"))
                                    local promptReach = isDrawerOrContainer and math.clamp(maxDist, 9, 12) or maxDist
                                    if dist <= promptReach then
                                        if isPromptSafeToAutoInteract(prompt) then
                                            promptDebounce[prompt] = now + 0.4
                                            batchCount = batchCount + 1
                                            local stagger = (batchCount - 1) * 0.02
                                            task.spawn(function()
                                                if stagger > 0 then task.wait(stagger) end
                                                pcall(function()
                                                    fireproximityprompt(prompt)
                                                end)
                                            end)
                                        end
                                    end
                                end
                            end
                        end
                    end

                    -- 2. Check Side Doors (Touch-based swing open for DoorNormal)
                    if State.AutoInteract_Doors and not (State.AutoInteract_Excludes and State.AutoInteract_Excludes["Side Room Doors"]) then
                        for _, child in ipairs(container:GetChildren()) do
                            local cName = child.Name:lower()
                            if cName:find("doornormal") or cName:find("sidedoor") then
                                local hidden = child:FindFirstChild("Hidden")
                                if hidden and hidden:IsA("BasePart") then
                                    local dist = (rootPos - hidden.Position).Magnitude
                                    if dist <= maxDist then
                                        if not promptDebounce[hidden] or now >= promptDebounce[hidden] then
                                            promptDebounce[hidden] = now + 0.8
                                            task.spawn(function()
                                                pcall(function()
                                                    hidden.CanTouch = true
                                                    firetouchinterest(root, hidden, 0)
                                                    task.wait()
                                                    firetouchinterest(root, hidden, 1)
                                                end)
                                            end)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        task.wait(0.03) -- Ultra-fast 33Hz loop: rapid multi-prompt interaction, zero stutter
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

Hub.CreateToggle(mainTab, "Change Walkspeed", State.WalkSpeed_Enabled, function(v)
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

Hub.CreateToggle(mainTab, "No Acceleration", State.Instant_Movement, function(v)
    State.Instant_Movement = v
    Hub.Notify("Movement", v and "No Acceleration: ON (Instant turning & stopping)" or "No Acceleration: OFF", 2)
end)

Hub.CreateSlider(mainTab, "Speed Value", 15, 75, State.WalkSpeed_Value, " studs/s", function(v)
    State.WalkSpeed_Value = v
    if State.WalkSpeed_Enabled then
        local char = getChar()
        local hum = char and char:FindFirstChildWhichIsA("Humanoid")
        if hum then hum.WalkSpeed = v end
    end
end)

Hub.CreateToggle(mainTab, "Enable Jumping", State.Enable_Jumping, function(v)
    State.Enable_Jumping = v
    local char = getChar()
    local hum = char and char:FindFirstChildWhichIsA("Humanoid")
    if hum then
        hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, v)
        hum.UseJumpPower = true
        hum.JumpPower = v and 52 or 0
        hum.JumpHeight = v and 7.5 or 0
    end
    Hub.Notify("Movement", v and "Jumping: ENABLED (Space to jump)" or "Jumping: DISABLED", 2)
end)

Hub.CreateToggle(mainTab, "Enable Sliding", State.Enable_Sliding, function(v)
    State.Enable_Sliding = v
    if not v and isSlidingActive then
        stopSlide()
    end
    local char = getChar()
    if v then
        applyTeflonGlide(char)
        syncServerSlide(true, false)
    else
        if not State.WalkSpeed_Enabled and not State.Noclip then
            restoreDefaultFriction(char)
            syncServerSlide(false, false)
        end
    end
    Hub.Notify("Movement", v and "Sliding: ENABLED (C / Ctrl to slide)" or "Sliding: DISABLED", 2)
end)

Hub.CreateToggle(mainTab, "Fly-Noclip (Phase Glide / 3D Steering)", State.Noclip, function(v)
    if v and not State.Bypass_AntiCheat then
        State.Bypass_AntiCheat = true
        neutralizeServerTeleported()
        initAntiGlitchShield()
        Hub.Notify("Anti-Cheat", "Anti-Cheat Bypass auto-enabled for Fly-Noclip!", 2)
    end
    State.Noclip = v
    local char = getChar()
    local r = getRoot()
    local hum = char and char:FindFirstChildWhichIsA("Humanoid")

    pcall(function()
        local pGui = LocalPlayer:FindFirstChild("PlayerGui")
        local rl = pGui and pGui:FindFirstChild("MainUI") and pGui.MainUI:FindFirstChild("Initiator") and pGui.MainUI.Initiator:FindFirstChild("Main_Game") and pGui.MainUI.Initiator.Main_Game:FindFirstChild("RemoteListener")
        if rl and rl:FindFirstChild("Modules") then
            local stMod = rl.Modules:FindFirstChild("ServerTeleported", true)
            if stMod then
                stMod:SetAttribute("Static", v == true)
            end
        end
    end)

    if v then
        _G.__BLOCK_EQ_NOCLIP = true
        local mg = getMainGameTable()
        if mg then
            mg.noclip = true
            mg.crouching = false
            if r then mg.clipPos = r.Position end
        end
    else
        _G.__BLOCK_EQ_NOCLIP = false
        local mg = getMainGameTable()
        if mg then
            mg.noclip = false
        end

        if char and char:GetAttribute("Hiding") then
            char:SetAttribute("Hiding", nil)
        end

        -- Exact Vertical Floor Landing: Drops player straight down to floor at current (X, Z) coordinates
        if r and char then
            local rayParams = RaycastParams.new()
            rayParams.FilterDescendantsInstances = {char, Workspace.CurrentCamera}
            rayParams.FilterType = Enum.RaycastFilterType.Exclude

            -- Vertical raycast directly downwards from above current position
            local floorRay = workspace:Raycast(Vector3.new(r.Position.X, math.max(r.Position.Y, 20), r.Position.Z), Vector3.new(0, -350, 0), rayParams)
            if floorRay and floorRay.Instance and floorRay.Instance.CanCollide then
                local rootOffset = (hum and hum.HipHeight or 2.0) + 1.0
                local targetY = floorRay.Position.Y + rootOffset
                local landedCF = CFrame.new(r.Position.X, targetY, r.Position.Z) * r.CFrame.Rotation
                char:PivotTo(landedCF)
                r.CFrame = landedCF
                r.AssemblyLinearVelocity = Vector3.zero
                teleportImmunityUntil = os.clock() + 1.5
                Hub.Notify("Safe Landing", "Safely dropped to floor directly below!", 2)
            end
        end

        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                if part.Name == "Collision" or part.Name == "CollisionPart" or part.Name == "CollisionCrouch" then
                    part.CanCollide = true
                    part.CanTouch = true
                elseif part.Name ~= "HumanoidRootPart" and not part.Parent:IsA("Accessory") then
                    part.CanCollide = true
                    part.CanTouch = true
                end
            end
        end
        if not State.WalkSpeed_Enabled and not State.Enable_Sliding then
            syncServerSlide(false, false)
        end
        if r then r.AssemblyLinearVelocity = Vector3.zero end
    end
    Hub.Notify("Movement", v and "Fly-Noclip: ON (Smooth 3D Flight)" or "Fly-Noclip: OFF", 2)
end)

Hub.CreateSlider(mainTab, "Fly-Noclip Speed", 5, 75, State.Noclip_Speed, " studs/s", function(v)
    State.Noclip_Speed = v
end)

-- [Teleport & Roof Buttons Removed for Clean Fly-Noclip Focus]

Hub.CreateToggle(mainTab, "Bypass Anti-Cheat Core", State.Bypass_AntiCheat, function(v)
    State.Bypass_AntiCheat = v
    if not v then
        if State.Noclip then
            State.Noclip = false
            local char = getChar()
            if char then restoreCharacterInteractivity(char) end
            local r = getRoot()
            if r then r.AssemblyLinearVelocity = Vector3.zero end
            syncServerSlide(false, false)
            Hub.Notify("Movement", "Fly-Noclip disabled: Bypass Anti-Cheat Core is required!", 2)
        end
    else
        neutralizeServerTeleported()
        if syncServerSlide then syncServerSlide(true, true) end
    end
    Hub.Notify("Anti-Cheat", v and "Anti-Cheat Bypass: ACTIVE (Slide Token Spoofer & Rollback Nullifier)" or "Anti-Cheat Bypass: OFF", 2)
end)

Hub.CreateToggle(mainTab, "Deflect Glitch & Void Shield", State.Deflect_Glitch, function(v)
    State.Deflect_Glitch = v
    if v then initAntiGlitchShield() end
    Hub.Notify("Shield", v and "Glitch Shield: ACTIVE (Rejects freeze, blindness & screen glitched)" or "Glitch Shield: OFF", 2)
end)

Hub.CreateSection(mainTab, "🖐️ Interaction Power")

Hub.CreateToggle(mainTab, "Instant Interact (0s Hold)", State.Instant_Interact, function(v)
    State.Instant_Interact = v
    refreshAllPrompts()
    Hub.Notify("Interaction", v and "Instant Interact: ON (Hold duration = 0s)" or "Instant Interact: OFF", 2)
end)

Hub.CreateToggle(mainTab, "Noclip Interact (Through Walls)", State.Noclip_Interact, function(v)
    State.Noclip_Interact = v
    refreshAllPrompts()
    Hub.Notify("Interaction", v and "Noclip Interact: ON (No line of sight needed)" or "Noclip Interact: OFF", 2)
end)

Hub.CreateToggle(mainTab, "Range Interact (Extended Reach)", State.Range_Interact, function(v)
    State.Range_Interact = v
    refreshAllPrompts()
    Hub.Notify("Interaction", v and string.format("Range Interact: ON (%d studs safe max)", State.Interact_MaxRange) or "Range Interact: OFF", 2)
end)

Hub.CreateSlider(mainTab, "Max Interact Range", 6, 14, State.Interact_MaxRange, " studs", function(v)
    State.Interact_MaxRange = v
    if State.Range_Interact then
        refreshAllPrompts()
    end
end)

Hub.CreateSection(mainTab, "🤖 Auto Interact (Safe Exclude List)")

Hub.CreateToggle(mainTab, "Auto Interact Master", State.Auto_Interact, function(v)
    State.Auto_Interact = v
    Hub.Notify("Auto Interact", v and "Auto Interact: ACTIVE" or "Auto Interact: OFF", 2)
end)

local excludeCategories = {
    { Name = "Paintings & Pictures", Desc = "Wall canvas, portraits & frames" },
    { Name = "Fake Doors (Dupe)", Desc = "Dupe traps & wrong numbered doors" },
    { Name = "Wall Clocks & Bells", Desc = "Decorative bells and desk bells" },
    { Name = "Light Switches & Lamps", Desc = "Table lamps & light toggles" },
    { Name = "Normal Exit Doors", Desc = "Main progression numbered doors" },
    { Name = "Side Room Doors", Desc = "Side closet/room touch doors" },
    { Name = "Drawers & Desks", Desc = "Dressers, tables & loot drawers" },
    { Name = "Gold & Coins", Desc = "Gold piles, coin stacks & starlight" },
    { Name = "Keys & Skeleton Keys", Desc = "Room keys & skeleton keys" },
    { Name = "Levers & Breakers", Desc = "Gate levers & circuit switches" },
    { Name = "Books & Papers", Desc = "Room 50 library hint books" },
    { Name = "Crucifix & Defense Items", Desc = "Crucifix, candles & holy items" },
    { Name = "Lighters & Flashlights", Desc = "Light sources & batteries" },
    { Name = "Health & Bandages", Desc = "Bandages, vitamins & herbs" },
    { Name = "Lockpicks & Shears", Desc = "Lockpicks, shears & tool pickups" },
    { Name = "Glitch Fragments", Desc = "Glitch cubes & rift fragments" },
}

local excludeList = Hub.CreateList(mainTab, "Auto Interact Exclude List", excludeCategories, 180, false, { MultiSelect = true })

-- Set initially excluded items
local defaultExcluded = {}
for name, isExcluded in pairs(State.AutoInteract_Excludes) do
    if isExcluded then
        table.insert(defaultExcluded, name)
    end
end
if excludeList and excludeList.SetSelectedItems then
    excludeList.SetSelectedItems(defaultExcluded)
end

if excludeList then
    excludeList.OnSelect = function(name, entryData)
        local isSelected = false
        for _, item in ipairs(excludeList.SelectedItems) do
            if item == entryData or item.Name == name or item == name then
                isSelected = true
                break
            end
        end
        State.AutoInteract_Excludes[name] = isSelected
        Hub.Notify("Exclude Filter", (isSelected and "❌ Excluded: " or "✅ Allowed: ") .. tostring(name), 2)
    end
end

Hub.CreateInput(mainTab, "Add Custom Exclude Keyword", "", "Type keyword to exclude...", function(text)
    if text and #text > 0 then
        local trimmed = text:match("^%s*(.-)%s*$")
        if #trimmed > 0 then
            table.insert(State.AutoInteract_CustomKeywords, trimmed)
            if excludeList and excludeList.AddItem then
                local row, entryData = excludeList.AddItem({ Name = trimmed, Desc = "Custom Keyword Exclude" })
                if excludeList.ToggleSelected then
                    excludeList.ToggleSelected(entryData)
                end
            end
            Hub.Notify("Custom Exclude", "Added keyword: " .. trimmed, 3)
        end
    end
end)

Hub.CreateToggle(mainTab, "Auto Loot Gold & Coins", State.AutoInteract_Gold, function(v)
    State.AutoInteract_Gold = v
end)

Hub.CreateToggle(mainTab, "Auto Grab Items", State.AutoInteract_Items, function(v)
    State.AutoInteract_Items = v
end)

Hub.CreateToggle(mainTab, "Auto Grab Keys", State.AutoInteract_Keys, function(v)
    State.AutoInteract_Keys = v
end)

Hub.CreateToggle(mainTab, "Auto Books & Breakers", State.AutoInteract_Books, function(v)
    State.AutoInteract_Books = v
end)

Hub.CreateToggle(mainTab, "Auto Open Drawers & Desks", State.AutoInteract_Drawers, function(v)
    State.AutoInteract_Drawers = v
end)

Hub.CreateToggle(mainTab, "Auto Open Normal Doors", State.AutoInteract_Doors, function(v)
    State.AutoInteract_Doors = v
end)

Hub.CreateToggle(mainTab, "Auto Pull Levers", State.AutoInteract_Levers, function(v)
    State.AutoInteract_Levers = v
end)

-- =========================================================================
-- Floor Mechanics & Hazard Defenses (Floor 1: Hotel & Floor 2: Mines)
-- =========================================================================

local function updateFloorNativeToggles()
    local gd = game:GetService("ReplicatedStorage"):FindFirstChild("GameData")
    if gd then
        if gd:FindFirstChild("EntityDisableScreech") then
            gd.EntityDisableScreech.Value = State.Anti_Screech
        end
        if gd:FindFirstChild("EntityDisableEyes") then
            gd.EntityDisableEyes.Value = State.Anti_Eyes
        end
        if gd:FindFirstChild("EntityDisableDupe") then
            gd.EntityDisableDupe.Value = State.Anti_Dupe
        end
    end
end

-- Eyes detection helper (returns active Eyes model if present in workspace)
local function isEyesPresent()
    local e = Workspace:FindFirstChild("Eyes") or Workspace:FindFirstChild("Lookman")
    if e and e:IsA("Model") then return e end
    local currentRooms = Workspace:FindFirstChild("CurrentRooms")
    if currentRooms then
        for _, r in ipairs(currentRooms:GetChildren()) do
            local eyesInRoom = r:FindFirstChild("Eyes") or r:FindFirstChild("Lookman")
            if eyesInRoom and eyesInRoom:IsA("Model") then
                return eyesInRoom
            end
        end
    end
    for _, child in ipairs(Workspace:GetChildren()) do
        local n = child.Name:lower()
        if (n:find("eyes") or n:find("lookman")) and child:IsA("Model") then
            return child
        end
    end
    return nil
end

-- Hook Remotes for Eyes pitch spoofing (-899 = looking straight down) and A90 movement spoofing
local remotesFolder = game:GetService("ReplicatedStorage"):WaitForChild("RemotesFolder", 5)
local motorRemote = remotesFolder and remotesFolder:FindFirstChild("MotorReplication")
local a90Remote = remotesFolder and remotesFolder:FindFirstChild("A90")

-- Pre-hook UserInputService.IsKeyDown to prevent DOORS native dev noclip from capturing KeyCode.E & Q
if hookfunction and UserInputService.IsKeyDown and not _G.__ISKEYDOWN_HOOKED then
    _G.__ISKEYDOWN_HOOKED = true
    local rawIsKeyDown
    rawIsKeyDown = hookfunction(UserInputService.IsKeyDown, newcclosure(function(self, kc)
        if not checkcaller() and _G.__BLOCK_EQ_NOCLIP then
            if kc == Enum.KeyCode.E or kc == Enum.KeyCode.Q then
                return false
            end
        end
        return rawIsKeyDown(self, kc)
    end))
end

if hookmetamethod then
    local rawNamecall
    rawNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if not checkcaller() then
            if (method == "PivotTo" or method == "pivotTo") then
                local char = getChar()
                local mgTable = getMainGameTable()
                local hiding = isPlayerHiding(char, mgTable) or (os.clock() < unhideGraceUntil)
                if not hiding and (isTeleportTweening or State.Noclip or isAtRoof) then
                    local isLocalChar = (self == char) or (char and (self == char.PrimaryPart or self:IsDescendantOf(char))) or (self.Name == LocalPlayer.Name)
                    if isLocalChar then
                        return -- Block anticheat rollback PivotTo dead in its tracks; allow wardrobe hiding and door entry!
                    end
                end
            end
            if method == "FireServer" then
                if self == motorRemote and State.Anti_Eyes and isEyesPresent() then
                    local args = {...}
                    args[1] = -899
                    return rawNamecall(self, unpack(args))
                elseif self == a90Remote and State.Anti_A90 then
                    local args = {...}
                    if args[1] == "moved" then
                        args[1] = "didnt"
                    end
                    return rawNamecall(self, unpack(args))
                end
            end
        end
        return rawNamecall(self, ...)
    end))
end

if hookfunction then
    if motorRemote and motorRemote.FireServer then
        local rawMotorFire
        rawMotorFire = hookfunction(motorRemote.FireServer, newcclosure(function(self, pitch, room, ...)
            if not checkcaller() and State.Anti_Eyes and isEyesPresent() then
                pitch = -899
            end
            return rawMotorFire(self, pitch, room, ...)
        end))
    end
    if a90Remote and a90Remote.FireServer then
        local rawA90Fire
        rawA90Fire = hookfunction(a90Remote.FireServer, newcclosure(function(self, action, ...)
            if not checkcaller() and State.Anti_A90 and action == "moved" then
                action = "didnt"
            end
            return rawA90Fire(self, action, ...)
        end))
    end
end

-- Intercept server rollback teleports while Noclip is active
local teleRemote = remotesFolder and remotesFolder:FindFirstChild("Teleport")
local servTeleRemote = remotesFolder and remotesFolder:FindFirstChild("ServerTeleported")

if getconnections then
    if teleRemote and teleRemote:IsA("RemoteEvent") then
        for _, conn in ipairs(getconnections(teleRemote.OnClientEvent)) do
            local oldTele = conn.Function
            if oldTele and hookfunction and not _G["CONN_TP_" .. tostring(oldTele)] then
                _G["CONN_TP_" .. tostring(oldTele)] = true
                hookfunction(oldTele, newcclosure(function(...)
                    local char = getChar()
                    local mgTable = getMainGameTable()
                    local hiding = isPlayerHiding(char, mgTable) or (os.clock() < unhideGraceUntil)
                    if not hiding and (State.Noclip or isTeleportTweening or State.Bypass_AntiCheat or isAtRoof) then
                        return
                    end
                    return oldTele(...)
                end))
            end
        end
    end
    if servTeleRemote and servTeleRemote:IsA("RemoteEvent") then
        for _, conn in ipairs(getconnections(servTeleRemote.OnClientEvent)) do
            local oldServTele = conn.Function
            if oldServTele and hookfunction and not _G["CONN_ST_" .. tostring(oldServTele)] then
                _G["CONN_ST_" .. tostring(oldServTele)] = true
                hookfunction(oldServTele, newcclosure(function(...)
                    local char = getChar()
                    local mgTable = getMainGameTable()
                    local hiding = isPlayerHiding(char, mgTable) or (os.clock() < unhideGraceUntil)
                    if not hiding and (State.Noclip or isTeleportTweening or State.Bypass_AntiCheat or isAtRoof) then
                        return
                    end
                    return oldServTele(...)
                end))
            end
        end
    end
end

-- Camera listener: Instant Silent Defusal for Screech (0 Camera Movement, 0 Damage) & Timothy
local cam = Workspace.CurrentCamera
if cam then
    cam.ChildAdded:Connect(function(child)
        local cName = child.Name:lower()
        if State.Anti_Screech and (cName:find("screech") or cName == "screechretro") then
            -- 1. Synchronously register caught on server so player takes 0 bite damage
            local remote = remotesFolder and remotesFolder:FindFirstChild("Screech")
            if remote then
                pcall(function() remote:FireServer(true) end)
            end

            -- 2. Immediately mute all screech audio on frame 0
            pcall(function()
                for _, desc in ipairs(child:GetDescendants()) do
                    if desc:IsA("Sound") then
                        desc.Volume = 0
                        desc:Stop()
                    end
                end
            end)

            -- 3. Instantly unparent and destroy Screech from Camera so DOORS Main_Game cannot swivel camera or play jumpscare
            child.Parent = nil
            pcall(function() child:Destroy() end)

            -- 4. Clean up any active screech state in DOORS Main_Game table
            pcall(function()
                local mg = getMainGameTable()
                if mg and mg.screech then
                    mg.screech = nil
                end
            end)

            Hub.Notify("Anti-Screech", "🦇 Screech defused silently! (0 damage, camera undisturbed)", 2)
        elseif State.Anti_Timothy and (cName:find("spider") or cName == "spiderjumpscare") then
            pcall(function()
                for _, desc in ipairs(child:GetDescendants()) do
                    if desc:IsA("Sound") then
                        desc.Volume = 0
                        desc:Stop()
                    elseif desc:IsA("BasePart") then
                        desc.Transparency = 1
                    elseif desc:IsA("Decal") or desc:IsA("ImageLabel") then
                        desc.Transparency = 1
                    end
                end
            end)
            Hub.Notify("Anti-Timothy", "🕷️ Timothy spider silenced & hidden!", 1.5)
        end
    end)
end

-- Background watchdog for continuous Eyes pitch keep-alive, muting, A90 GUI, and Giggle
task.spawn(function()
    while true do
        if _G.DOORS_SESSION ~= currentSession then break end

        -- Anti-Eyes Active Pitch Keep-Alive & Volume Silence (leaves model completely intact!)
        if State.Anti_Eyes then
            local eyes = isEyesPresent()
            if eyes then
                pcall(function()
                    if motorRemote then
                        motorRemote:FireServer(-899, getCurrentRoomNumber() or 0)
                    end
                    for _, desc in ipairs(eyes:GetDescendants()) do
                        if desc:IsA("Sound") and desc.Volume > 0 then
                            desc.Volume = 0
                        end
                    end
                end)
            end
        end

        -- Anti-A90 GUI Auto-Dismiss
        if State.Anti_A90 then
            pcall(function()
                local pGui = LocalPlayer:FindFirstChild("PlayerGui")
                local mainUI = pGui and pGui:FindFirstChild("MainUI")
                local jumpscare = mainUI and mainUI:FindFirstChild("Jumpscare")
                local a90Gui = jumpscare and jumpscare:FindFirstChild("Jumpscare_A90")
                if a90Gui and a90Gui.Visible then
                    a90Gui.Visible = false
                end
            end)
        end

        -- Anti-Giggle Auto-Detach
        if State.Anti_Giggle then
            pcall(function()
                local char = getChar()
                if char and char:GetAttribute("Giggled") then
                    char:SetAttribute("Giggled", nil)
                end
            end)
        end

        task.wait(0.2)
    end
end)

-- Auto Heartbeat Minigame Solver
task.spawn(function()
    while true do
        if _G.DOORS_SESSION ~= currentSession then break end
        if State.Auto_Heartbeat then
            pcall(function()
                local pGui = LocalPlayer:FindFirstChild("PlayerGui")
                local mainUI = pGui and pGui:FindFirstChild("MainUI")
                local heart = mainUI and mainUI:FindFirstChild("MainFrame") and mainUI.MainFrame:FindFirstChild("Heartbeat") and mainUI.MainFrame.Heartbeat:FindFirstChild("Heart")
                if heart and heart.Parent and heart.Parent.Visible then
                    local liveHalf = heart:FindFirstChild("LiveHalf")
                    if liveHalf and liveHalf.Visible then
                        local vim = game:GetService("VirtualInputManager")
                        if vim then
                            vim:SendKeyEvent(true, Enum.KeyCode.Q, false, game)
                            task.wait(0.02)
                            vim:SendKeyEvent(false, Enum.KeyCode.Q, false, game)
                            vim:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                            task.wait(0.02)
                            vim:SendKeyEvent(false, Enum.KeyCode.E, false, game)
                        end
                    end
                end
            end)
        end
        task.wait(0.08)
    end
end)

-- Room 50 Library Padlock Code Solver
local function solveLibraryCode()
    local pGui = LocalPlayer:FindFirstChild("PlayerGui")
    local hints = pGui and pGui:FindFirstChild("PermUI") and pGui.PermUI:FindFirstChild("Hints")
    
    local currentRooms = Workspace:FindFirstChild("CurrentRooms")
    local room50 = currentRooms and currentRooms:FindFirstChild("50")
    if not room50 then
        return nil, "Room 50 not yet generated!"
    end

    local paper = Workspace:FindFirstChild("LibraryHintPaper", true)
        or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("LibraryHintPaper"))
        or (LocalPlayer.Backpack and LocalPlayer.Backpack:FindFirstChild("LibraryHintPaper"))

    -- Gather collected books from Hints GUI
    local bookDigits = {}
    if hints then
        for _, hint in ipairs(hints:GetChildren()) do
            if hint:IsA("ImageLabel") and hint.Name ~= "Template" then
                local textLabel = hint:FindFirstChildWhichIsA("TextLabel")
                local icon = hint.Image
                if textLabel and textLabel.Text ~= "" then
                    bookDigits[icon] = textLabel.Text
                end
            end
        end
    end

    -- Also inspect Room 50 books directly
    for _, item in ipairs(room50:GetDescendants()) do
        if item.Name == "LiveHintBook" or item.Name:lower():find("hintbook") then
            local num = item:GetAttribute("Number") or item:GetAttribute("Digit")
            local shape = item:GetAttribute("Shape")
            if num and shape then
                bookDigits[tostring(shape)] = tostring(num)
            end
        end
    end

    if not paper then
        return nil, "Pick up the Hint Paper in Room 50 first!"
    end

    local code = {}
    local paperGui = paper:FindFirstChildWhichIsA("SurfaceGui", true)
    if paperGui then
        local frames = {}
        for _, desc in ipairs(paperGui:GetDescendants()) do
            if desc:IsA("ImageLabel") and desc.Name ~= "Background" then
                table.insert(frames, desc)
            end
        end
        table.sort(frames, function(a, b) return (a.LayoutOrder or 0) < (b.LayoutOrder or 0) end)
        for _, img in ipairs(frames) do
            local digit = bookDigits[img.Image] or "_"
            table.insert(code, digit)
        end
    end

    if #code > 0 then
        return table.concat(code, " "), "Solved"
    end

    return nil, "Gather more books in the Library!"
end

-- Maintain native values & snares
task.spawn(function()
    while true do
        if _G.DOORS_SESSION ~= currentSession then break end
        updateFloorNativeToggles()
        if State.Anti_Snare then defuseAllSnares() end
        task.wait(1)
    end
end)

-- =========================================================================
-- Tab 2: TELEPORT & MOVEMENT TAB (Anti-Cheat Safe Teleports & 3D Flight)
-- =========================================================================
-- Tab 2: FLOOR SPECIFIC TAB (Floor 1: Hotel / Floor 2: Mines)
-- =========================================================================
local detectedFloor = (game.ReplicatedStorage:FindFirstChild("GameData") and game.ReplicatedStorage.GameData:FindFirstChild("Floor") and game.ReplicatedStorage.GameData.Floor.Value) or "Hotel"
local floorTabName = "Floor (" .. detectedFloor .. ")"

local floorTab = Hub.CreateTab(floorTabName, { 
    Icon = "🏨", 
    Size = 18, 
    Color = Color3.fromRGB(255, 120, 50), 
    ActiveColor = Color3.fromRGB(255, 180, 70) 
})

local floorLower = string.lower(tostring(detectedFloor))
local isHotel = (floorLower:find("hotel") ~= nil or floorLower == "floor1" or floorLower == "1")
local isMines = (floorLower:find("mine") ~= nil or floorLower == "floor2" or floorLower == "2")
local isRooms = (floorLower:find("room") ~= nil or floorLower == "a")
local isBackdoor = (floorLower:find("backdoor") ~= nil)
local isRetro = (floorLower:find("retro") ~= nil)
if not isHotel and not isMines and not isRooms and not isBackdoor and not isRetro then
    isHotel = true
end

Hub.CreateSection(floorTab, "🦇 Entity Defenses")

-- Common defenses (Hotel & Mines)
if isHotel or isMines or isRetro then
    Hub.CreateToggle(floorTab, "Anti-Screech (Auto-Catch & Banish)", State.Anti_Screech, function(v)
        State.Anti_Screech = v
        updateFloorNativeToggles()
        Hub.Notify("Anti-Screech", v and "Anti-Screech: ACTIVE (Zero bite & jumpscare)" or "Anti-Screech: OFF", 2)
    end)

    Hub.CreateToggle(floorTab, "Anti-Eyes (Look Immunity)", State.Anti_Eyes, function(v)
        State.Anti_Eyes = v
        updateFloorNativeToggles()
        Hub.Notify("Anti-Eyes", v and "Anti-Eyes: ACTIVE (Look-damage immune)" or "Anti-Eyes: OFF", 2)
    end)

    Hub.CreateToggle(floorTab, "Anti-Dupe (Fake Door Protection)", State.Anti_Dupe, function(v)
        State.Anti_Dupe = v
        updateFloorNativeToggles()
        Hub.Notify("Anti-Dupe", v and "Anti-Dupe: ACTIVE" or "Anti-Dupe: OFF", 2)
    end)

    Hub.CreateToggle(floorTab, "Anti-Snare Traps (Greenhouse & Mines)", State.Anti_Snare, function(v)
        State.Anti_Snare = v
        defuseAllSnares()
        Hub.Notify("Anti-Snare", v and "Anti-Snare: ACTIVE (Walk through snares safely)" or "Anti-Snare: OFF", 2)
    end)

    Hub.CreateToggle(floorTab, "Anti-Timothy (Spider Jumpscare Mute)", State.Anti_Timothy, function(v)
        State.Anti_Timothy = v
        Hub.Notify("Anti-Timothy", v and "Anti-Timothy: ACTIVE (Drawer spiders silenced & hidden)" or "Anti-Timothy: OFF", 2)
    end)
end

-- Rooms / Backdoor / Retro only defenses
if isRooms or isBackdoor or isRetro then
    Hub.CreateToggle(floorTab, "Anti-A-90 (Instant Attack Immunity)", State.Anti_A90, function(v)
        State.Anti_A90 = v
        Hub.Notify("Anti-A-90", v and "Anti-A-90: ACTIVE (A-90 attacks neutralized)" or "Anti-A-90: OFF", 2)
    end)
end

-- Mines (Floor 2) only defenses
if isMines then
    Hub.CreateToggle(floorTab, "Anti-Giggle (Ceiling Snatcher Defusal)", State.Anti_Giggle, function(v)
        State.Anti_Giggle = v
        Hub.Notify("Anti-Giggle", v and "Anti-Giggle: ACTIVE (Mines giggles disarmed)" or "Anti-Giggle: OFF", 2)
    end)
end

-- Shared Minigames (Hotel & Mines)
if isHotel or isMines then
    Hub.CreateSection(floorTab, "🎮 Minigames & Puzzles")

    Hub.CreateToggle(floorTab, "Auto Heartbeat Minigame (Auto-Win)", State.Auto_Heartbeat, function(v)
        State.Auto_Heartbeat = v
        Hub.Notify("Heartbeat Minigame", v and "Auto Heartbeat: ACTIVE (100% win rate)" or "Auto Heartbeat: OFF", 2)
    end)
end

-- Hotel (Floor 1) specific Puzzles
if isHotel then
    Hub.CreateButton(floorTab, "🔍 Solve Library Code (Room 50 Padlock)", function()
        local code, status = solveLibraryCode()
        if code then
            Hub.Notify("Room 50 Code", "Padlock Code: " .. code, 6)
        else
            Hub.Notify("Room 50 Code", status or "Need Books & Hint Paper!", 4)
        end
    end)

    Hub.CreateToggle(floorTab, "Auto Solve Circuit Breaker (Room 100)", State.Auto_Breakers, function(v)
        State.Auto_Breakers = v
        Hub.Notify("Room 100 Breaker", v and "Auto Breaker: ACTIVE" or "Auto Breaker: OFF", 2)
    end)
end

-- Tab 3: ESP TAB
local espTab = Hub.CreateTab("ESP", { 
    Icon = "👁️", 
    Size = 18, 
    Color = Color3.fromRGB(170, 185, 210), 
    ActiveColor = Color3.fromRGB(0, 215, 255) 
})

Hub.CreateSection(espTab, "👁️ Master Control & Display Mode")

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

Hub.CreateDropdown(espTab, "Doors & Closets Vision Mode", { "Current & Next Room", "Current Room Only", "All Rooms (Full Vision)" }, State.ESP_RoomFilterMode, function(mode)
    State.ESP_RoomFilterMode = mode
    Hub.Notify("ESP Display Mode", "Set to: " .. mode, 2)
end)

Hub.CreateSlider(espTab, "ESP Text Font Size", 11, 24, State.ESP_TextSize, " px", function(v)
    State.ESP_TextSize = v
    refreshEspVisualSettings()
end)

Hub.CreateSlider(espTab, "Highlight Fill Opacity", 10, 90, math.floor((1 - State.ESP_FillTransparency) * 100), "%", function(v)
    State.ESP_FillTransparency = 1 - (v / 100)
    refreshEspVisualSettings()
end)

Hub.CreateSection(espTab, "🎨 Color Themes & Customization")

Hub.CreateDropdown(espTab, "ESP Color Palette", { "Default Vibrant", "Neon Cyber", "Monochrome Glow", "Pastel Soft" }, State.ESP_ColorTheme, function(theme)
    State.ESP_ColorTheme = theme
    if theme == "Default Vibrant" then
        State.ESP_Color_Doors = Color3.fromRGB(0, 215, 255)
        State.ESP_Color_DoorsLocked = Color3.fromRGB(255, 175, 30)
        State.ESP_Color_Keys = Color3.fromRGB(255, 220, 50)
        State.ESP_Color_Items = Color3.fromRGB(160, 110, 255)
        State.ESP_Color_Entities = Color3.fromRGB(255, 35, 35)
        State.ESP_Color_Hiding = Color3.fromRGB(80, 220, 120)
    elseif theme == "Neon Cyber" then
        State.ESP_Color_Doors = Color3.fromRGB(0, 255, 136)
        State.ESP_Color_DoorsLocked = Color3.fromRGB(255, 230, 0)
        State.ESP_Color_Keys = Color3.fromRGB(0, 238, 255)
        State.ESP_Color_Items = Color3.fromRGB(255, 0, 128)
        State.ESP_Color_Entities = Color3.fromRGB(255, 20, 50)
        State.ESP_Color_Hiding = Color3.fromRGB(50, 255, 180)
    elseif theme == "Monochrome Glow" then
        State.ESP_Color_Doors = Color3.fromRGB(240, 240, 255)
        State.ESP_Color_DoorsLocked = Color3.fromRGB(255, 160, 40)
        State.ESP_Color_Keys = Color3.fromRGB(255, 240, 100)
        State.ESP_Color_Items = Color3.fromRGB(200, 200, 255)
        State.ESP_Color_Entities = Color3.fromRGB(255, 50, 50)
        State.ESP_Color_Hiding = Color3.fromRGB(180, 230, 200)
    elseif theme == "Pastel Soft" then
        State.ESP_Color_Doors = Color3.fromRGB(120, 200, 255)
        State.ESP_Color_DoorsLocked = Color3.fromRGB(255, 200, 120)
        State.ESP_Color_Keys = Color3.fromRGB(255, 245, 140)
        State.ESP_Color_Items = Color3.fromRGB(200, 160, 255)
        State.ESP_Color_Entities = Color3.fromRGB(255, 100, 100)
        State.ESP_Color_Hiding = Color3.fromRGB(140, 230, 180)
    end
    clearAllEsp()
    scanAllRooms()
    Hub.Notify("Color Theme", "Applied: " .. theme, 2)
end)

Hub.CreateSection(espTab, "🚪 Doors & Navigation")

Hub.CreateToggle(espTab, "Doors ESP (Real & Fake)", State.Doors_ESP, function(v)
    State.Doors_ESP = v
    if not v then
        clearCategoryEsp("Doors")
    else
        scanAllRooms()
    end
end)

Hub.CreateToggle(espTab, "Keys ESP", State.Keys_ESP, function(v)
    State.Keys_ESP = v
    if not v then
        clearCategoryEsp("Keys")
    else
        scanAllRooms()
    end
end)

Hub.CreateSection(espTab, "📦 Items & Objectives")

Hub.CreateToggle(espTab, "Glitch Fragment ESP (GlitchCube)", State.GlitchFragment_ESP, function(v)
    State.GlitchFragment_ESP = v
    if not v then
        clearCategoryEsp("GlitchFragment")
    else
        scanAllRooms()
    end
end)

Hub.CreateToggle(espTab, "Items ESP (Crucifix, Lighter, etc.)", State.Items_ESP, function(v)
    State.Items_ESP = v
    if not v then
        clearCategoryEsp("Items")
    else
        scanAllRooms()
    end
end)

Hub.CreateToggle(espTab, "Books ESP (Room 50 Library Only)", State.Books_ESP, function(v)
    State.Books_ESP = v
    if not v then
        clearCategoryEsp("Books")
    else
        scanAllRooms()
    end
end)

Hub.CreateToggle(espTab, "Breakers ESP (Room 100 Only)", State.Breakers_ESP, function(v)
    State.Breakers_ESP = v
    if not v then
        clearCategoryEsp("Breakers")
    else
        scanAllRooms()
    end
end)

Hub.CreateToggle(espTab, "Gold Coins ESP", State.Gold_ESP, function(v)
    State.Gold_ESP = v
    if not v then
        clearCategoryEsp("Gold")
    else
        scanAllRooms()
    end
end)

Hub.CreateSection(espTab, "💀 Entities & Safety")

Hub.CreateToggle(espTab, "Entities ESP (Monsters Master)", State.Entities_ESP, function(v)
    State.Entities_ESP = v
    if not v then
        clearCategoryEsp("Entities")
    else
        scanAllRooms()
    end
end)

Hub.CreateToggle(espTab, "Hiding Spots ESP (Closets & Beds)", State.HidingSpots_ESP, function(v)
    State.HidingSpots_ESP = v
    if not v then
        clearCategoryEsp("HidingSpots")
    else
        scanAllRooms()
    end
end)

Hub.CreateSection(espTab, "👾 Entity Filter (Multi-Choice)")

local allMonsterOptions = {
    "Rush", "Ambush", "Figure", "Seek", "Eyes", "Halt",
    "Screech", "Giggle", "Grumble", "Gloombats", "Snare",
    "Timothy", "Rooms", "Dread", "Other"
}

Hub.CreateMultiDropdown(espTab, "Monsters Filter List", allMonsterOptions, allMonsterOptions, function(selectedMonsters)
    local filterMap = {}
    for _, opt in ipairs(allMonsterOptions) do
        filterMap[opt] = false
    end
    for _, name in ipairs(selectedMonsters) do
        filterMap[name] = true
    end
    State.Entity_ESP_Filters = filterMap
    clearCategoryEsp("Entities")
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
pcall(function()
    local rooms = Workspace:FindFirstChild("CurrentRooms")
    if rooms then
        for _, desc in ipairs(rooms:GetDescendants()) do
            if desc:IsA("BasePart") and not desc.Name:lower():find("snare") and not desc.CanTouch then
                desc.CanTouch = true
            end
        end
    end
end)
scanAllRooms()
Hub.Notify("UNKNOWN HUB", "DOORS Precision ESP Loaded! 👁️", 4)
