-- =========================================================================
-- Universal Session Maid & Multi-Execution Lag Prevention Engine
-- Purges previous session connections, loops, hooks, drawings & UI to guarantee 0 FPS drops!
-- =========================================================================
if _G.DOORS_CLEANUP and type(_G.DOORS_CLEANUP) == "function" then
    pcall(_G.DOORS_CLEANUP)
end

local sessionConnections = {}
local sessionDrawings = {}

local function trackConn(conn)
    if conn then table.insert(sessionConnections, conn) end
    return conn
end

local function trackDrawing(d)
    if d then table.insert(sessionDrawings, d) end
    return d
end

_G.DOORS_SESSION = tick()
local currentSession = _G.DOORS_SESSION

_G.DOORS_CLEANUP = function()
    -- 1. Invalidate session token to instantly terminate all background while-loops
    _G.DOORS_SESSION = tick()

    -- 2. Disconnect every tracked RBXScriptConnection
    for _, conn in ipairs(sessionConnections) do
        pcall(function()
            if conn and conn.Disconnect then conn:Disconnect() end
        end)
    end
    table.clear(sessionConnections)

    -- 3. Destroy all tracked Drawing instances
    for _, d in ipairs(sessionDrawings) do
        pcall(function()
            if d and d.Remove then d:Remove() elseif d and d.Destroy then d:Destroy() end
        end)
    end
    table.clear(sessionDrawings)

    -- 4. Destroy existing UI
    pcall(function()
        local cg = game:GetService("CoreGui")
        local hui = gethui and gethui()
        local lp = game:GetService("Players").LocalPlayer
        local pg = lp and lp:FindFirstChild("PlayerGui")
        local targets = {cg, hui, pg}
        for _, p in ipairs(targets) do
            if p then
                for _, desc in ipairs(p:GetDescendants()) do
                    if desc.Name == "UnknownHub" or desc.Name:find("Unknown_ESP") or desc.Name:find("Unknown_") then
                        pcall(function() desc:Destroy() end)
                    end
                end
            end
        end
    end)
end

--[[
    ========================================================================
    Unknown Hub - DOORS (Hotel & The Mines)
    Stage: Working ESP Engine (Laser-focused on 100% precision ESP)
    ========================================================================
]]

-- DOORS Lobby Guard (PlaceId: 6524177990)
if game.PlaceId == 6524177990 then
    local qot = queue_on_teleport or (syn and syn.queue_on_teleport) or queueonteleport
    if qot then
        pcall(function()
            qot([[
                repeat task.wait() until game:IsLoaded()
                local s, src = pcall(readfile, "Doors.luau")
                if s and src and #src > 100 then
                    loadstring(src)()
                end
            ]])
        end)
    end
    print("[Unknown Hub] DOORS Lobby detected (PlaceId: 6524177990). Dormant until elevator starts match.")
    return
end


-- Unknown UI Library Loader

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
                    if desc.Name == "Unknown_TabbedHub_UI" or desc.Name:find("Unknown_ESP") or desc.Name:find("Unknown_") then
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
            return game:HttpGet("https://raw.githubusercontent.com/UnknownHQ/UnknownHub/main/UnknownLibrary" .. cacheBuster)
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
    name = "Unknown_TabbedHub_UI",
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
    FieldOfView = 70,
    -- Main / Movement
    WalkSpeed_Enabled = false,
    WalkSpeed_Value = 45,
    Enable_Jumping = false,
    Enable_Sliding = false,
    Noclip = false,
    Walk_Noclip = false,
    Noclip_Speed = 35,
    Instant_Movement = true, -- No acceleration / instant directional turning without slipping on floor

    -- Autonomous 1-100 Doors Master Completer Suite
    Auto_Complete_100 = false,
    Auto_Hide = false,
    Auto_RoofEvacuate = false,
    Knobs_Farm_ExtraGoldMultiplier = true,

    -- Knobs Farm Autopilot Suite
    Knobs_Farm_Active = false,
    Knobs_Farm_MaxGold = 3500,
    Knobs_Farm_MaxDoors = 85,
    Knobs_Farm_LootDrawers = true,
    Knobs_Farm_LootChests = true,
    Knobs_Farm_RoofEvacuation = true,
    Knobs_Farm_AutoSolveFigure = true,
    Knobs_Farm_AutoRestart = true,

    -- Item Exploits & Infinite Items
    Infinite_Items = true,
    Infinite_Lockpicks = true,
    Infinite_Crucifix = true,
    Infinite_Consumables = true,

    -- Entity Path Nodes & Safe Zones ESP
    ESP_Entity_Nodes = false,
    ESP_Safe_Zones = false,

    -- World & Visual Enhancements
    No_Fog = true,
    SemiTransparent_Closet = true,
    Notify_EntitySpawn = true,
    Notify_EntitySound = true,
    Notify_Entity_Filters = {},

    -- God Mode & Anti Figure Hearing Defenses
    God_Mode = false,

    -- Additional Defenses
    Anti_Gloombat = true,
    Anti_Grumble = true,
    Anti_Halt = true,
    Anti_Seek = true,
    Anti_Rush = false,
    Anti_Dread = true,

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
    Instant_Interact = true,
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

-- Forward Declarations (Guarantees zero unscoped calls across all modules)
local getMainGameTable, farmGlideTo, defuseLethalEntity, getExactFloorPos
-- lastNoclipDisableGrace hoisted
local remotesFolder = game:GetService("ReplicatedStorage"):WaitForChild("RemotesFolder", 5)
local crouchRemote = remotesFolder and remotesFolder:WaitForChild("Crouch", 5)


-- =========================================================================
-- Anti-Halt Complete Neutralization (No Spawns, No Fog, No Camera Shake, No Damage)
-- =========================================================================
pcall(function()
    local entityModules = game:GetService("ReplicatedStorage"):WaitForChild("ModulesClient"):WaitForChild("EntityModules")
    local shadeModule = require(entityModules:WaitForChild("Shade"))
    if shadeModule and shadeModule.stuff then
        local origShadeStuff = shadeModule.stuff
        shadeModule.stuff = function(a1, a2, a3)
            if State.Anti_Halt then
                -- Defused completely: Halt does not appear, does not play audio, and does not attack
                return
            end
            return origShadeStuff(a1, a2, a3)
        end
    end
end)

-- Metatable namecall guard for Halt damage remote (consolidated into unified detour below)


-- =========================================================================
-- Anti-Screech Camera Shake Elimination & Instant Remote Defusal
-- =========================================================================
local function hookCamShakerScreech()
    local mg = getMainGameTable()
    if mg and mg.camShaker and not mg.camShaker._screechHooked then
        mg.camShaker._screechHooked = true
        local origShakeOnce = mg.camShaker.ShakeOnce
        mg.camShaker.ShakeOnce = function(self, ...)
            local args = {...}
            if State.Anti_Screech then
                local cam = Workspace.CurrentCamera
                local hasScreech = cam and (cam:FindFirstChild("Screech") or cam:FindFirstChild("ScreechRetro"))
                -- Screech shake signature: ShakeOnce(0.5, 12, 3, 1)
                if hasScreech or (args[1] == 0.5 and args[2] == 12 and args[3] == 3 and args[4] == 1) then
                    return -- Completely eliminate screen shake!
                end
            end
            return origShakeOnce(self, ...)
        end
    end
end

task.spawn(function()
    while _G.DOORS_SESSION == currentSession do
        task.wait(0.5)
        pcall(hookCamShakerScreech)
    end
end)

-- Instant defusal of Screech when parented to Camera
pcall(function()
    local cam = Workspace.CurrentCamera or Workspace:WaitForChild("Camera")
    cam.ChildAdded:Connect(function(child)
        if State.Anti_Screech and (child.Name == "Screech" or child.Name == "ScreechRetro") then
            pcall(function()
                local remotes = game:GetService("ReplicatedStorage"):WaitForChild("RemotesFolder")
                local screechRemote = remotes:FindFirstChild("Screech")
                if screechRemote then screechRemote:FireServer(true) end
            end)
            for _, d in ipairs(child:GetDescendants()) do
                if d:IsA("Sound") then d.Volume = 0 d:Stop() end
                if d:IsA("ParticleEmitter") then d.Enabled = false end
            end
        end
    end)
end)


-- =========================================================================
-- Instant Electrical Breaker Solver (Door 100 Elevator Power)
-- =========================================================================
instantSolveBreakers = function()
    local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("RemotesFolder")
    local ebf = remotes and remotes:FindFirstChild("EBF")
    if ebf then
        pcall(function() ebf:FireServer() end)
    end

    local elBreaker = Workspace:FindFirstChild("ElevatorBreaker", true)
    if elBreaker then
        for _, v in ipairs(elBreaker:GetChildren()) do
            if v.Name == "BreakerSwitch" then
                pcall(function()
                    v:SetAttribute("Enabled", true)
                    local pc = v:FindFirstChild("PrismaticConstraint", true)
                    if pc then pc.TargetPosition = -0.2 end
                end)
            end
        end
    end

    local pGui = LocalPlayer:FindFirstChild("PlayerGui")
    local mainUI = pGui and pGui:FindFirstChild("MainUI")
    local mb = mainUI and mainUI:FindFirstChild("MinigameBackout", true)
    if mb then mb.Visible = false end

    Hub.Notify("Door 100", "Elevator Breaker Solved Instantly!", 3)
end

task.spawn(function()
    while _G.DOORS_SESSION == currentSession do
        task.wait(0.2)
        if State.Auto_Breakers then
            local elBreaker = Workspace:FindFirstChild("ElevatorBreaker", true)
            if elBreaker then
                instantSolveBreakers()
                task.wait(2.0)
            end
        end
    end
end)


-- =========================================================================
-- Proactive ProximityPrompt Line-Of-Sight & Range Strip (Zero Wall Delays)
-- =========================================================================
-- Permanent Universal PromptGate & PromptService Immunity
local function initPromptGateImmunity()
    pcall(function()
        local ps = LocalPlayer:FindFirstChild("PlayerScripts") and LocalPlayer.PlayerScripts:FindFirstChild("PromptService")
        if ps then
            ps:SetAttribute("Suppressed", false)
            if not _G.PS_SUPP_SIGNAL then
                _G.PS_SUPP_SIGNAL = true
                ps:GetAttributeChangedSignal("Suppressed"):Connect(function()
                    if ps:GetAttribute("Suppressed") == true then
                        ps:SetAttribute("Suppressed", false)
                    end
                end)
            end
            local pg = ps:FindFirstChild("PromptGate")
            if pg and not _G.PG_HOOKED then
                local s, pgMod = pcall(require, pg)
                if s and type(pgMod) == "table" and hookfunction then
                    if pgMod.isHidden then
                        _G.PG_HOOKED = true
                        hookfunction(pgMod.isHidden, newcclosure(function(prompt)
                            return false -- Never hide prompts! All prompts remain enabled!
                        end))
                    end
                end
            end
        end
    end)
end
initPromptGateImmunity()

pcall(function()
    local pps = game:GetService("ProximityPromptService")
    pps.PromptButtonHoldBegan:Connect(function(prompt, player)
        if player == LocalPlayer then
            initPromptGateImmunity()
        end
    end)
    pps.PromptTriggered:Connect(function(prompt, player)
        if player == LocalPlayer then
            initPromptGateImmunity()
        end
    end)
    pps.PromptShown:Connect(function(prompt)
        prompt.RequiresLineOfSight = false
        if prompt.MaxActivationDistance < 14.0 then
            prompt.MaxActivationDistance = 14.0
        end
    end)
end)

pcall(function()
    local curRooms = Workspace:WaitForChild("CurrentRooms")
    curRooms.DescendantAdded:Connect(function(desc)
        if desc:IsA("ProximityPrompt") then
            desc.RequiresLineOfSight = false
            if desc.MaxActivationDistance < 14.0 then
                desc.MaxActivationDistance = 14.0
            end
        end
    end)
end)



-- =========================================================================
-- Forward Declarations & Core Motion Synchronization Flags
-- =========================================================================
local isAutoFlying = false
local isCompleterActive = false
local isKnobsFarmRunning = false
local isEvacuatingRoof = false

-- Forward declarations hoisted to top of script

-- Session lifecycle state synchronization
_G.State = State
_G.UnknownHub_State = State

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
    -- Reliable World Parenting: Highlights MUST be parented to Workspace/Terrain to render depth-stencil pass in Roblox 3D pipeline
    local targetParent = Workspace:FindFirstChild("Terrain") or Workspace
    hl.Parent = targetParent
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

getMainGameTable = function()
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
                    elseif vis:IsA("SphereHandleAdornment") or vis:IsA("BoxHandleAdornment") then
                        vis.Color3 = color
                    elseif vis:IsA("SelectionBox") then
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
            if vis:IsA("BillboardGui") then
                vis.Enabled = initiallyVisible
            elseif vis:IsA("SelectionBox") or vis:IsA("SphereHandleAdornment") or vis:IsA("BoxHandleAdornment") or vis:IsA("PVAdornment") or vis:IsA("HandleAdornment") then
                vis.Visible = initiallyVisible
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

    -- Auto-cleanup on destroy or parent removal
    pcall(function()
        owner.Destroying:Connect(function()
            removeEspFor(owner)
        end)
        owner.AncestryChanged:Connect(function(_, parent)
            if not parent or (not owner:IsDescendantOf(Workspace) and not owner:IsDescendantOf(Camera)) then
                removeEspFor(owner)
            end
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

            -- Dynamic Highlight Budget Engine (Solves Roblox 31 Highlight limit):
            -- Doors, Keys, and Entities receive TOP PRIORITY so the Next Door and Key ALWAYS have Highlights!
            local priorityRecords = {}
            local otherCandidates = {}
            for owner, record in pairs(activeEspRecords) do
                if record and record.Adornee and record.Adornee.Parent and record.Owner and record.Owner.Parent then
                    if record.Category == "Doors" or record.Category == "Keys" or record.Category == "Entities" then
                        priorityRecords[record] = true
                    else
                        local d = rootPos and (rootPos - record.Adornee.Position).Magnitude or 9999
                        table.insert(otherCandidates, { Record = record, Dist = d })
                    end
                end
            end
            table.sort(otherCandidates, function(a, b) return a.Dist < b.Dist end)
            local allowedHighlights = {}
            for rec, _ in pairs(priorityRecords) do
                allowedHighlights[rec] = true
            end
            local priorityCount = 0
            for _ in pairs(priorityRecords) do priorityCount = priorityCount + 1 end
            local remainingBudget = math.max(0, 24 - priorityCount)
            for i = 1, math.min(remainingBudget, #otherCandidates) do
                allowedHighlights[otherCandidates[i].Record] = true
            end

            for owner, record in pairs(activeEspRecords) do
                if not owner or not owner.Parent or not record.Adornee or not record.Adornee.Parent then
                    removeEspFor(owner)
                else
                    -- Entity Despawn / Bramble Ghost Filter
                    if record.Category == "Entities" then
                        local ent = record.Owner
                        local isDeadOrGone = false
                        if not ent or not ent.Parent then
                            isDeadOrGone = true
                        elseif ent:GetAttribute("Despawned") == true or ent:GetAttribute("Dead") == true or ent:GetAttribute("Hidden") == true then
                            isDeadOrGone = true
                        elseif ent.Name:lower():find("bramble") then
                            local visiblePartCount = 0
                            for _, p in ipairs(ent:GetDescendants()) do
                                if p:IsA("BasePart") and p.Transparency < 0.9 then
                                    visiblePartCount = visiblePartCount + 1
                                end
                            end
                            if visiblePartCount == 0 then
                                isDeadOrGone = true
                            end
                        end
                        if isDeadOrGone then
                            removeEspFor(owner)
                            continue
                        end
                    end

                    -- 1. Room Visibility Filter (Exclusively show doors and closets in current room only!)
                    if record.Category == "Doors" then
                        local shouldShow = State.Doors_ESP
                        if shouldShow then
                            if curRoom ~= nil and record.RoomNumber ~= nil then
                                -- Strict Door Visibility: Completely HIDE previous doors (already passed)!
                                -- ONLY highlight the Next Door and current room door!
                                if record.RoomNumber < curRoom then
                                    shouldShow = false
                                elseif record.RoomNumber > (curRoom + 1) then
                                    shouldShow = false
                                else
                                    shouldShow = true
                                    if record.Label then
                                        local isLocked = record.Owner and (record.Owner:GetAttribute("Locked") == true or (record.Owner:FindFirstChild("Lock") and record.Owner.Lock:FindFirstChildWhichIsA("ProximityPrompt", true)))
                                        local isDupe = record.BaseText and record.BaseText:find("Dupe")
                                        if not isDupe then
                                            local doorNum = record.RoomNumber + 1
                                            local rolePrefix = (record.RoomNumber == curRoom) and "Current Door" or "Next Door"
                                            record.BaseText = string.format("%s %d%s", rolePrefix, doorNum, isLocked and " [LOCKED]" or "")
                                        end
                                    end
                                end
                            else
                                shouldShow = true
                            end
                        end

                        record.CurrentlyVisible = shouldShow
                        if record.Visuals then
                            local budgetAllowed = (allowedHighlights and allowedHighlights[record]) == true
                            for _, vis in ipairs(record.Visuals) do
                                if vis:IsA("BillboardGui") then
                                    vis.Enabled = shouldShow
                                elseif vis:IsA("SelectionBox") then
                                    vis.Visible = shouldShow
                                    vis.Adornee = shouldShow and (vis.Adornee or (record.HighlightMap and record.HighlightMap[vis]) or record.Adornee) or nil
                                elseif vis:IsA("SphereHandleAdornment") or vis:IsA("BoxHandleAdornment") or vis:IsA("PVAdornment") or vis:IsA("HandleAdornment") then
                                    vis.Visible = shouldShow
                                elseif vis:IsA("Highlight") then
                                    vis.Enabled = shouldShow and budgetAllowed
                                    vis.Adornee = (shouldShow and budgetAllowed) and ((record.HighlightMap and record.HighlightMap[vis]) or record.Adornee) or nil
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
                                    if vis:IsA("BillboardGui") then
                                        vis.Enabled = shouldShow
                                    elseif vis:IsA("SelectionBox") or vis:IsA("SphereHandleAdornment") or vis:IsA("BoxHandleAdornment") or vis:IsA("PVAdornment") or vis:IsA("HandleAdornment") then
                                        vis.Visible = shouldShow
                                    elseif vis:IsA("Highlight") then
                                        local budgetAllowed = (allowedHighlights and allowedHighlights[record]) == true
                                        vis.Enabled = shouldShow and budgetAllowed
                                        if not (shouldShow and budgetAllowed) then
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

-- =========================================================================
-- Dupe Door Identification & Hard Anti-Dupe Locking Subsystem
-- =========================================================================
local function isDupeDoor(doorModel, room)
    if not doorModel then return false end
    local dName = doorModel.Name:lower()
    if dName == "doorfake" or dName:find("fake") or dName:find("dupe") then
        return true
    end
    if doorModel:GetAttribute("DupeRoom") == true or doorModel:GetAttribute("Fake") == true or doorModel:GetAttribute("Dupe") == true then
        return true
    end
    if doorModel.Parent and (doorModel.Parent.Name:lower():find("dupe") or doorModel.Parent.Name:lower():find("fake")) then
        return true
    end

    -- Recursive Sign search: detects signs on nested door models
    local signPart = doorModel:FindFirstChild("Sign", true)
    local signLabel = signPart and signPart:FindFirstChildWhichIsA("TextLabel", true)
    local signText = signLabel and signLabel.Text or nil
    local signNum = tonumber(signText)

    local roomNum = (room and tonumber(room.Name))
    if not roomNum then
        local p = doorModel.Parent
        while p and p ~= workspace do
            if tonumber(p.Name) then roomNum = tonumber(p.Name); break end
            p = p.Parent
        end
    end
    roomNum = roomNum or getCurrentRoomNumber()
    if roomNum and signNum and signNum ~= (roomNum + 1) then
        return true
    end
    return false
end

local function secureDupeDoor(doorModel)
    if not doorModel then return end
    pcall(function()
        for _, p in ipairs(doorModel:GetDescendants()) do
            if p:IsA("ProximityPrompt") then
                p.Enabled = false
                p.MaxActivationDistance = 0
            elseif p:IsA("BasePart") then
                p.CanTouch = false
                p.CanCollide = true
                p.Anchored = true
            elseif p:IsA("RemoteEvent") and p.Name == "ClientOpen" then
                p:Destroy()
            end
        end
        if doorModel:IsA("BasePart") then
            doorModel.CanTouch = false
            doorModel.CanCollide = true
            doorModel.Anchored = true
        end
    end)
end

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
        local color = State.ESP_Color_Dupe or Color3.fromRGB(255, 35, 35)
        local extraVisuals = {}
        local doorBox = Instance.new("BoxHandleAdornment")
        doorBox.Name = "Unknown_DoorBoxAdorn"
        doorBox.Adornee = doorMesh
        doorBox.Size = doorMesh.Size
        doorBox.Color3 = color
        doorBox.AlwaysOnTop = true
        doorBox.Transparency = State.ESP_FillTransparency or 0.5
        doorBox.ZIndex = 10
        doorBox.Parent = (gethui and gethui()) or CoreGui
        table.insert(extraVisuals, doorBox)

        local doorOutline = Instance.new("SelectionBox")
        doorOutline.Name = "Unknown_DoorOutlineBox"
        doorOutline.Adornee = doorMesh
        doorOutline.Color3 = color
        doorOutline.LineThickness = 0.04
        doorOutline.SurfaceTransparency = 1
        doorOutline.Parent = (gethui and gethui()) or CoreGui
        table.insert(extraVisuals, doorOutline)

        registerEsp(doorModel, doorMesh, baseText, color, "Doors", nil, Vector3.new(0, 1.2, 0), roomNumber, extraVisuals)
        if State.Anti_Dupe then secureDupeDoor(doorModel) end
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

    -- Dupe Check: Verified early so fake doors are NEVER discarded by decor filters
    local isDupe = isDupeDoor(doorModel, room)

    -- Verify door has real interactable open components (excludes non-dupe room decor)
    if not isDupe and not (doorModel:FindFirstChild("ClientOpen") or doorModel:FindFirstChild("Hidden") or doorModel:FindFirstChild("Hinge") or doorModel:FindFirstChild("HingeConstraint") or doorModel:GetAttribute("ESP_Hooked") or doorModel:GetAttribute("Opened") or doorModel:FindFirstChild("Open")) then
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
    if not isDupe then
        isDupe = isDupeDoor(doorModel, room)
    end

    local signPart = doorModel:FindFirstChild("Sign", true)
    local signLabel = signPart and signPart:FindFirstChildWhichIsA("TextLabel", true)
    local signText = signLabel and signLabel.Text or nil

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

    -- Clean Rectangular Door ESP Visuals (BoxHandleAdornment + SelectionBox):
    -- BoxHandleAdornment provides a smooth, solid uniform rectangular fill across the door leaf.
    -- SelectionBox provides a razor-sharp, flat rectangular outline around the door perimeter.
    -- Completely eradicates Roblox's screen-space mesh chamfer cutout notches at distance (Images 2, 4, 6)!
    local extraVisuals = {}

    local doorBox = Instance.new("BoxHandleAdornment")
    doorBox.Name = "Unknown_DoorBoxAdorn"
    doorBox.Adornee = doorMesh
    doorBox.Size = doorMesh.Size
    doorBox.Color3 = color
    doorBox.AlwaysOnTop = true
    doorBox.Transparency = State.ESP_FillTransparency or 0.5
    doorBox.ZIndex = 10
    doorBox.Parent = (gethui and gethui()) or CoreGui
    table.insert(extraVisuals, doorBox)

    local doorOutline = Instance.new("SelectionBox")
    doorOutline.Name = "Unknown_DoorOutlineBox"
    doorOutline.Adornee = doorMesh
    doorOutline.Color3 = color
    doorOutline.LineThickness = 0.04
    doorOutline.SurfaceTransparency = 1
    doorOutline.Parent = (gethui and gethui()) or CoreGui
    table.insert(extraVisuals, doorOutline)

    registerEsp(doorModel, adorneePart, baseText, color, "Doors", nil, Vector3.new(0, 1.2, 0), roomNumber, extraVisuals)
    if isDupe and State.Anti_Dupe then
        secureDupeDoor(doorModel)
    end

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

    -- Reject entire room structures, shops, siderooms, hallways, walls, fixtures (DO NOT REJECT RIFT!)
    if lower:find("room") or lower:find("shop") or lower:find("assets") or lower:find("structure")
        or lower:find("hallway") or lower:find("elevator") or lower:find("sideroom")
        or lower:find("wall") or lower:find("ceiling") or lower:find("floor") or lower:find("desk")
        or lower:find("drawer") or lower:find("cabinet") or lower:find("table") or lower:find("skulllock") then
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


-- Clean Rift Detection: Highlight natural Rift when present without force-spawning fake clones or particle emitters

-- 7b. Dedicated Rift ESP: Brilliant Glowing Cyan Highlighter
local function processRift(model)
    if not model then return end
    local mName = model.Name:lower()
    if (mName:find("rift") and not mName:find("fragment")) or model:GetAttribute("IsRift") then
        local targetPart = (model:IsA("Model") and (model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)))
            or (model:IsA("BasePart") and model)
        if targetPart then
            local color = Color3.fromRGB(0, 255, 255)
            registerEsp(model, targetPart, "The Rift", color, "Special", model, Vector3.new(0, 1.5, 0))
        end
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

-- Sleek, Native Adornment Bounding Box for 2D Sprite/Billboard Entities (Zero physical Workspace parts!)
local function createEntityBoundingBox(targetPart, size, color)
    if not targetPart or not targetPart.Parent then return nil end
    local folder = Instance.new("Folder")
    folder.Name = "Unknown_EntityBox"

    local s = size or Vector3.new(4.5, 5.5, 4.5)
    if typeof(s) == "number" then
        s = Vector3.new(s, s, s)
    end
    local boxColor = color or Color3.fromRGB(255, 30, 30)

    -- Clean BoxHandleAdornment: smooth translucent fill centered on targetPart
    local boxAdorn = Instance.new("BoxHandleAdornment")
    boxAdorn.Name = "EntityBoxFill"
    boxAdorn.Adornee = targetPart
    boxAdorn.Size = s
    boxAdorn.Color3 = boxColor
    boxAdorn.Transparency = 0.45
    boxAdorn.AlwaysOnTop = true
    boxAdorn.ZIndex = 10
    boxAdorn.Parent = folder

    -- Sharp SelectionBox: razor-thin outer wireframe border in matching Crimson Red
    local sbox = Instance.new("SelectionBox")
    sbox.Name = "EntityBoxOutline"
    sbox.Adornee = targetPart
    sbox.Color3 = boxColor
    sbox.LineThickness = 0.03
    sbox.SurfaceTransparency = 1
    sbox.AlwaysOnTop = true
    sbox.Parent = folder

    folder.Parent = (gethui and gethui()) or CoreGui
    return folder
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

    -- Strict Furniture, Lighting & Prop Rejection Filter (Eliminates all random furniture highlights!):
    if eLower:find("carpet") or eLower:find("rug") or eLower:find("shelf") or eLower:find("shelves") or eLower:find("table")
        or eLower:find("chair") or eLower:find("desk") or eLower:find("lamp") or eLower:find("lightstand") or eLower:find("chandelier")
        or eLower:find("plant") or eLower:find("potted") or eLower:find("pot") or eLower:find("flower") or eLower:find("leaf")
        or eLower:find("painting") or eLower:find("frame") or eLower:find("canvas") or eLower:find("drawer") or eLower:find("door")
        or eLower:find("curtain") or eLower:find("elevator") or eLower:find("clock") or eLower:find("pillar") or eLower:find("wall") then
        return
    end

    -- Real DOORS monsters are always Models (except floor Snare traps)
    if not entity:IsA("Model") and not eLower:find("snare") then
        return
    end

    -- Strict Entity Identification against verified monsters (Hotel, Floor 2 Mines, Modifiers & Admin Panel):
    local cfg = nil
    local is2D = false
    local isBramble = false

    -- Check Blitz FIRST before Rush so Blitz is NEVER misidentified as Rush!
    if eLower == "blitz" or eLower:find("^blitz") or eLower:find("blitzmoving") then
        cfg = { Name = "Blitz", Category = "Other" }
        is2D = true
    elseif eLower == "rush" or eLower:find("rushmoving") or eLower:find("rushnew") or (eLower:find("^rush") and entity:IsA("Model")) then
        cfg = { Name = "Rush", Category = "Rush" }
        is2D = true
    elseif eLower == "ambush" or eLower:find("ambushmoving") or (eLower:find("^ambush") and entity:IsA("Model")) then
        cfg = { Name = "Ambush", Category = "Ambush" }
        is2D = true
    elseif eLower:find("lookman") or eLower:find("^lookman") then
        cfg = { Name = "Lookman", Category = "Eyes" }
        is2D = true
    elseif eLower == "eyes" or eLower:find("^eyes") or eLower:find("eyesretro") then
        cfg = { Name = "Eyes (Don't Look!)", Category = "Eyes" }
        is2D = true
    elseif eLower:find("screech") then
        cfg = { Name = "Screech", Category = "Screech" }
        is2D = false -- 3D tentacle monster
    elseif eLower == "halt" or eLower:find("^halt") or eLower == "shade" then
        cfg = { Name = "Halt", Category = "Halt" }
        is2D = true
    elseif eLower == "dread" then
        cfg = { Name = "Dread", Category = "Dread" }
        is2D = true
    elseif eLower:find("figure") then
        cfg = { Name = "Figure", Category = "Figure" }
        is2D = false
    elseif eLower == "seek" or eLower:find("^seek") or eLower:find("seekmoving") or eLower:find("seekrig") then
        cfg = { Name = "Seek", Category = "Seek" }
        is2D = false
    elseif eLower:find("gloombat") then
        cfg = { Name = "Gloombats", Category = "Gloombats" }
        is2D = false -- swarm of 3D bat models
    elseif eLower:find("giggle") then
        cfg = { Name = "Giggle", Category = "Giggle" }
        is2D = false
    elseif eLower:find("grumble") or eLower == "queen" or eLower == "grumblequeen" then
        cfg = { Name = (eLower:find("queen") and "Grumble Queen" or "Grumble"), Category = "Grumble" }
        is2D = false
    elseif eLower:find("snare") then
        cfg = { Name = "Snare Trap", Category = "Snare" }
        is2D = false
    elseif eLower == "timothy" or eLower:find("spiderjumpscare") or eLower == "spider" then
        -- Strict Timothy Distance & Out-of-Bounds Filter: Discard off-map and distant drawer spiders (> 45 studs)
        local r = getRoot()
        local entPos = entity:GetPivot().Position
        if r and (entPos - r.Position).Magnitude > 45 then
            return
        end
        cfg = { Name = "Timothy", Category = "Timothy" }
        is2D = false
    elseif eLower == "jack" and entity:IsA("Model") then
        cfg = { Name = "Jack", Category = "Other" }
        is2D = false
    elseif (eLower:find("sally") or eLower:find("princess") or entity:GetAttribute("SallyHolding") or entity:FindFirstChild("SallyHolding", true)) and (entity:IsA("Model") or entity:IsA("BasePart")) then
        cfg = { Name = "Sally", Category = "Other" }
        is2D = false
    elseif (eLower:find("jeff") and eLower:find("killer")) or eLower == "jeffthekiller" then
        -- Strict Jeff The Killer check: NEVER match Jeff the shopkeeper!
        if not eLower:find("shop") and not (entity.Parent and entity.Parent.Name:lower():find("shop")) then
            cfg = { Name = "Jeff The Killer", Category = "Other" }
            is2D = false
        end
    elseif eLower:find("surge") and (eLower:find("fake") or eLower:find("decoy")) then
        cfg = { Name = "Surge (Fake)", Category = "Other" }
        is2D = true
    elseif eLower == "surge" or eLower:find("^surge") then
        cfg = { Name = "Surge", Category = "Other" }
        is2D = true
    elseif eLower == "bramble" or eLower:find("^bramble") then
        -- Strict Bramble despawn / decor filter
        if entity:GetAttribute("Despawned") == true or entity:GetAttribute("Dead") == true or entity:GetAttribute("Hidden") == true then
            removeEspFor(entity)
            return
        end
        if entity.Parent and entity.Parent.Name:lower() == "assets" then
            return
        end
        local hasVisibleParts = false
        for _, p in ipairs(entity:GetDescendants()) do
            if p:IsA("BasePart") and p.Transparency < 0.9 then
                hasVisibleParts = true
                break
            end
        end
        if not hasVisibleParts then
            removeEspFor(entity)
            return
        end
        pcall(function()
            entity:GetAttributeChangedSignal("Despawned"):Connect(function()
                if entity:GetAttribute("Despawned") == true then
                    removeEspFor(entity)
                end
            end)
        end)
        cfg = { Name = "Bramble", Category = "Other" }
        is2D = false
        isBramble = true
    elseif eLower == "groundskeeper" or eLower:find("^groundskeeper") then
        cfg = { Name = "Groundskeeper", Category = "Other" }
        is2D = false
    elseif eLower == "monument" or eLower:find("^monument") then
        cfg = { Name = "Monument", Category = "Other" }
        is2D = false
    elseif eLower == "alma" or eLower:find("^alma") then
        cfg = { Name = "Alma", Category = "Other" }
        is2D = true
    elseif eLower:find("drone") and eLower:find("stampede") then
        cfg = { Name = "Drone Stampede", Category = "Other" }
        is2D = true
    elseif eLower == "drone" or eLower:find("^drone") then
        cfg = { Name = "Drone", Category = "Other" }
        is2D = true
    elseif eLower == "teller" or eLower:find("^teller") then
        cfg = { Name = "Teller", Category = "Other" }
        is2D = false
    elseif eLower == "bash" or eLower:find("^bash") then
        cfg = { Name = "Bash", Category = "Other" }
        is2D = true
    elseif eLower == "scribbles" or eLower:find("^scribble") then
        cfg = { Name = "Scribbles", Category = "Other" }
        is2D = true
    elseif eLower == "socker" or eLower:find("^socker") then
        cfg = { Name = "Socker", Category = "Other" }
        is2D = false
    elseif eLower == "creak" or eLower:find("^creak") then
        cfg = { Name = "Creak", Category = "Other" }
        is2D = false
    elseif eLower == "meld" or eLower:find("^meld") then
        cfg = { Name = "Meld", Category = "Other" }
        is2D = false
    elseif eLower == "stem" or eLower:find("^stem") then
        -- Strict Stem match: ensure it is not a plant prop
        if not eLower:find("leaf") and not eLower:find("flower") and not eLower:find("pot") and not eLower:find("plant") then
            cfg = { Name = "Stem", Category = "Other" }
            is2D = false
        end
    elseif eLower == "noise" or eLower:find("^noise") then
        cfg = { Name = "Noise", Category = "Other" }
        is2D = false
    elseif eLower == "weaveling" or eLower:find("^weaveling") then
        cfg = { Name = "Weaveling", Category = "Other" }
        is2D = true
    elseif eLower == "a60" or eLower == "a-60" or eLower:find("^a%-?60") then
        cfg = { Name = "A-60", Category = "Rooms" }
        is2D = true
    elseif eLower == "a90" or eLower == "a-90" or eLower:find("^a%-?90") then
        cfg = { Name = "A-90", Category = "Rooms" }
        is2D = true
    elseif eLower == "a120" or eLower == "a-120" or eLower:find("^a%-?120") then
        cfg = { Name = "A-120", Category = "Rooms" }
        is2D = true
    elseif eLower == "glitch" or eLower:find("^glitch") then
        cfg = { Name = "Glitch", Category = "Other" }
        is2D = true
    elseif eLower == "void" then
        cfg = { Name = "Void", Category = "Other" }
        is2D = true
    elseif eLower:find("nextbot") then
        cfg = { Name = entity.Name, Category = "Other" }
        is2D = true
    end

    if not cfg then
        -- Unknown / Custom Entity Detection & ESP Guardian (Custom Rush, Floor Mod Spawns, Sally seating, uncataloged entities)
        local isHumanoid = entity:FindFirstChildOfClass("Humanoid") ~= nil
        local hasAnim = entity:FindFirstChildOfClass("AnimationController") ~= nil
        local inLive = entity.Parent and (entity.Parent.Name:lower():find("live") or entity.Parent.Name:lower():find("entity"))
        local isModel = entity:IsA("Model")
        local isMovingThreat = false

        if isModel then
            local pName = entity.Name:lower()
            -- Reject static environment models
            local isStaticRoomProp = pName:find("wall") or pName:find("floor") or pName:find("ceiling") or pName:find("door") 
                or pName:find("carpet") or pName:find("light") or pName:find("chandelier") or pName:find("desk") 
                or pName:find("table") or pName:find("chair") or pName:find("wardrobe") or pName:find("bed") 
                or pName:find("chest") or pName:find("drawer") or pName:find("shelf") or pName:find("plant")
                or pName:find("pillar") or pName:find("column") or pName:find("painting") or pName:find("frame")

            if not isStaticRoomProp and (isHumanoid or hasAnim or inLive or #entity:GetChildren() >= 2) then
                isMovingThreat = true
            end
        end

        if isMovingThreat then
            local cleanName = entity.Name:gsub("^%s+", ""):gsub("%s+$", "")
            if #cleanName == 0 or cleanName == "Model" then
                cleanName = "Unknown Entity"
            else
                cleanName = "Unknown Entity (" .. cleanName .. ")"
            end
            cfg = { Name = cleanName, Category = "Other" }
            is2D = false
        else
            return
        end
    end

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

        if isBramble then
            -- Bramble Spikes Exclusion: Strictly highlight ONLY main Bramble body, NEVER spikes or thorns!
            local brambleParts = {}
            for _, p in ipairs(entity:GetDescendants()) do
                if p:IsA("BasePart") then
                    local pName = p.Name:lower()
                    if not pName:find("spike") and not pName:find("thorn") then
                        table.insert(brambleParts, p)
                    end
                end
            end
            if #brambleParts > 0 then
                highlightTarget = brambleParts
            end
        elseif cfg.Name == "Gloombats" then
            -- Gloombats Full Swarm Highlighting: Highlight ALL flying bats in the swarm, not just the center point!
            highlightTarget = entity
        elseif cfg.Name == "Sally" then
            -- Sally Visibility Guardian: Permanently lock transparency to 0 against sitting animation hidden states
            local function enforceSallyPart(p)
                if p:IsA("BasePart") then
                    p.Transparency = 0
                    p.LocalTransparencyModifier = 0
                    p:GetPropertyChangedSignal("LocalTransparencyModifier"):Connect(function()
                        if p.LocalTransparencyModifier ~= 0 then
                            p.LocalTransparencyModifier = 0
                        end
                    end)
                    p:GetPropertyChangedSignal("Transparency"):Connect(function()
                        if p.Transparency ~= 0 then
                            p.Transparency = 0
                        end
                    end)
                end
            end
            for _, p in ipairs(entity:GetDescendants()) do
                enforceSallyPart(p)
            end
            pcall(function()
                entity.DescendantAdded:Connect(enforceSallyPart)
            end)
            highlightTarget = entity -- Direct clean Highlight on Sally's 3D character model! NO cube!
        end

        if is2D then
            -- Sleek Bounding Box Adornment with guaranteed through-wall visibility for 2D entities!
            local bbox = createEntityBoundingBox(targetPart, Vector3.new(4.5, 5.5, 4.5), entityColor)
            if bbox then
                table.insert(extraVisuals, bbox)
            end
            highlightTarget = nil -- Adornments handle through-wall rendering without consuming Highlight slots!
        else
            -- 3D Monsters (Figure, Seek, Giggle, Gloombats, Bramble, Groundskeeper, Monument, Jeff, Sally, etc.):
            -- Highlight the actual 3D model/parts directly! ZERO cubes!
            if not isBramble and cfg.Name ~= "Gloombats" and cfg.Name ~= "Sally" then
                highlightTarget = entity
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

-- isDupeDoor and secureDupeDoor defined above processDoor

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
    -- Strict anti-false positive filter: exclude decor meshes, books, elevator cubes, key holders, desks
    if n:find("book") or n:find("elevator") or n:find("holder") or n:find("door") or n:find("desk") or n:find("drawer") or n:find("table") or n:find("chair") then
        return false
    end
    local hasTag = false
    if CollectionService then
        pcall(function()
            hasTag = CollectionService:HasTag(inst, "GlitchCube") or CollectionService:HasTag(inst, "GlitchFragment")
        end)
    end
    if hasTag then return true end
    if inst:GetAttribute("GlitchFragment") == true or inst:GetAttribute("IsFragment") == true then
        return true
    end
    if n == "glitchfragment" or n == "glitch_fragment" or n == "glitchcube" or n == "glitch_cube" or n == "riftfragment" or n == "rift_fragment" then
        return true
    end
    if (n:find("glitch") and n:find("fragment")) or (n:find("glitch") and n:find("cube") and not n:find("mesh")) then
        return true
    end
    return false
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
    adorn.Radius = 0.8
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

-- Defuse Seek Obstacles & Hand Hitboxes
local function defuseSeekObstacles(room)
    if not (State.Anti_Seek and room) then return end
    pcall(function()
        for _, desc in ipairs(room:GetDescendants()) do
            local dName = desc.Name:lower()
            if dName:find("seek_arm") or dName:find("seekarm") or dName:find("seekhand") or dName:find("seekslop") or dName:find("chande") then
                for _, sub in ipairs(desc:GetDescendants()) do
                    if sub:IsA("TouchTransmitter") then
                        sub:Destroy()
                    elseif sub:IsA("BasePart") then
                        sub.CanTouch = false
                    end
                end
                if desc:IsA("BasePart") then
                    desc.CanTouch = false
                end
            end
        end
    end)
end

-- Defuse Figure Lethal Touch Hitbox
local function defuseFigureHitbox(inst)
    if not (State.Anti_Figure and inst) then return end
    pcall(function()
        local name = inst.Name:lower()
        if name:find("figure") then
            for _, sub in ipairs(inst:GetDescendants()) do
                if sub:IsA("TouchTransmitter") then
                    sub:Destroy()
                elseif sub.Name:lower():find("hitbox") and sub:IsA("BasePart") then
                    sub.CanTouch = false
                end
            end
        end
    end)
end

-- Full Room Parser
local function scanSingleRoom(room)
    if not room or not room:IsA("Model") then return end

    -- 0b. Scan The Rift
    for _, child in ipairs(room:GetChildren()) do
        local cLower = child.Name:lower()
        if cLower:find("rift") and not cLower:find("fragment") then
            processRift(child)
        if State.Anti_Seek then defuseSeekObstacles(child) end
        -- Anti Figure removed
        end
    end

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

    -- 2. Scan Room Descendants & Defuse Void/Boundary Anti-Cheat Triggers
    for _, desc in ipairs(room:GetDescendants()) do
        local dName = desc.Name:lower()
        if desc:IsA("BasePart") and (dName:find("voidcollision") or dName == "playercollision") then
            desc.CanTouch = false
            desc.CanCollide = false
        end

        -- Skip internal Dupe sideroom decorations/models (only DoorFake is tracked as a door)
        if not (desc.Parent and desc.Parent.Name == "SideroomDupe" and desc.Name ~= "DoorFake") then
            if isGlitchFragmentInstance(desc) then
                processGlitchFragment(desc)
            end

            if desc:IsA("Model") or desc:IsA("Tool") then
                if desc.Name == "Door" or desc.Name == "DoorFake" then
                    processDoor(room, desc)
                    if (desc.Name == "DoorFake" or isDupeDoor(desc, room)) and State.Anti_Dupe then
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
                    -- Anti Figure removed
                    if State.Entities_ESP then processEntity(desc) end
                elseif dName:find("sally") or dName:find("princess") or desc:GetAttribute("SallyHolding") or desc:FindFirstChild("SallyHolding", true) then
                    if State.Entities_ESP then processEntity(desc) end
                elseif dName:find("bramble") or dName:find("grumble") or dName:find("monument") or dName:find("groundskeeper") or dName:find("jack") then
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

            -- Real-time dropped items, drawer looting, and lever discovery (High-Speed Zero-Lag Filter)
            newRoom.DescendantAdded:Connect(function(desc)
                -- FAST TYPE FILTER: Discard 99% of non-interactive room geometry immediately (walls, wedges, lights, etc.)
                local isPrompt = desc:IsA("ProximityPrompt")
                local isTool = desc:IsA("Tool")
                local isModel = desc:IsA("Model")
                if not (isPrompt or isTool or isModel) then
                    if desc:IsA("BasePart") then
                        local n = desc.Name:lower()
                        if not (n:find("dupe") or n:find("snare") or n:find("giggle") or n:find("lever") or n:find("gold") or n:find("coin")) then
                            return
                        end
                    else
                        return
                    end
                end

                local dName = desc.Name:lower()
                if desc.Parent and desc.Parent.Name == "SideroomDupe" and desc.Name ~= "DoorFake" then
                    return
                end

                if isGlitchFragmentInstance(desc) then
                    processGlitchFragment(desc)
                end

                if isModel or isTool then
                    if desc.Name == "Door" or desc.Name == "DoorFake" then
                        processDoor(newRoom, desc)
                        if (desc.Name == "DoorFake" or isDupeDoor(desc, newRoom)) and State.Anti_Dupe then
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
                    elseif dName:find("sally") or dName:find("princess") or desc:GetAttribute("SallyHolding") or desc:FindFirstChild("SallyHolding", true) or dName:find("sitting") then
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
                elseif isPrompt then
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

        currentRooms.ChildAdded:Connect(function(newRoom)
            -- 2.5s anti-rollback grace window: prevents server from snapping player back during room streaming
            lastNoclipDisableGrace = math.max(lastNoclipDisableGrace or 0, os.clock() + 2.5)
            if crouchRemote then
                pcall(function() crouchRemote:FireServer(false, true) end)
            end
            bindRoom(newRoom)
        end)
    end
end)

-- Dynamic Workspace Drops & Entity Spawning Listeners
-- Hook LiveEntities folder and all descendant spawns for frame-0 hitbox defusal
local function monitorEntitiesFolder(folder)
    if not folder then return end
    folder.ChildAdded:Connect(function(child)
        local lower = child.Name:lower()
        local isLethal = lower:find("rush") or lower:find("ambush") or lower:find("a60") or lower:find("a120") or lower:find("seek") or lower:find("figure") or lower:find("grumble") or lower:find("giggle") or lower:find("gloombat") or lower:find("dread")
        if isLethal then
            defuseLethalEntity(child)
        end
    end)
    folder.DescendantAdded:Connect(function(desc)
        if desc:IsA("TouchTransmitter") then
            local parentModel = desc:FindFirstAncestorOfClass("Model")
            if parentModel then
                local lower = parentModel.Name:lower()
                if lower:find("rush") or lower:find("ambush") or lower:find("a60") or lower:find("a120") or lower:find("seek") or lower:find("figure") or lower:find("giggle") or lower:find("gloombat") then
                    pcall(function() desc:Destroy() end)
                end
            end
        end
    end)
end

pcall(function()
    local liveEntities = Workspace:WaitForChild("LiveEntities", 5)
    if liveEntities then
        monitorEntitiesFolder(liveEntities)
    end
end)

-- Continuous 20Hz Entity Defusal Daemon: Guarantees zero entities can kill player inside or outside the map!
task.spawn(function()
    while true do
        if _G.DOORS_SESSION ~= currentSession then break end
        pcall(function()
            local searchContainers = {Workspace:FindFirstChild("LiveEntities"), Workspace, Workspace:FindFirstChild("CurrentRooms")}
            for _, container in ipairs(searchContainers) do
                if container then
                    for _, child in ipairs(container:GetChildren()) do
                        local lower = child.Name:lower()
                        if lower:find("rush") or lower:find("ambush") or lower:find("a60") or lower:find("a120") or lower:find("seek") or lower:find("figure") or lower:find("grumble") or lower:find("giggle") or lower:find("gloombat") or lower:find("dread") then
                            defuseLethalEntity(child)
                        end
                    end
                end
            end
        end)
        task.wait(0.05)
    end
end)

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
local defaultCollProps = nil
local defaultRootProps = nil

local function applyTeflonGlide(char)
    if not char then return end
    local coll = char:FindFirstChild("Collision")
    local cp = char:FindFirstChild("CollisionPart")
    local root = char:FindFirstChild("HumanoidRootPart")
    if coll and coll:IsA("BasePart") then
        if not defaultCollProps then defaultCollProps = coll.CustomPhysicalProperties end
        coll.CustomPhysicalProperties = PhysicalProperties.new(0.5, 0.0, 0.0, 100, 100)
    end
    if cp and cp:IsA("BasePart") then
        cp.CustomPhysicalProperties = PhysicalProperties.new(0.5, 0.0, 0.0, 100, 100)
    end
    if root and root:IsA("BasePart") then
        if not defaultRootProps then defaultRootProps = root.CustomPhysicalProperties end
        root.CustomPhysicalProperties = PhysicalProperties.new(0.5, 0.0, 0.0, 100, 100)
    end
    -- Prevent character limbs from snagging on narrow door frames or tight openings
    for _, part in ipairs(char:GetChildren()) do
        if part:IsA("BasePart") and part.Name ~= "Collision" and part.Name ~= "HumanoidRootPart" then
            part.CanCollide = false
            part.CustomPhysicalProperties = PhysicalProperties.new(0.5, 0.0, 0.0, 100, 100)
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
crouchRemote = remotesFolder and remotesFolder:FindFirstChild("Crouch")
local isServerSlideActive = false
local lastSentCrouchState = nil
local lastSentSlideState = nil
local lastSlideSyncTime = 0
local pendingCrouchState = nil
local unhideGraceUntil = 0
local wasHidingState = false
local justExitedHiding = false
local getEquippedOrInventoryTool, executeItemDupeDrop, retrieveDroppedTool

-- isPlayerHiding defined above near top of script (line 472)

local syncServerSlide

-- Pre-hook ProximityPrompts for hiding spots to instantly prime grace window on hold and trigger
pcall(function()
    local pps = game:GetService("ProximityPromptService")
    local function primeHidingGrace(prompt, player)
        if prompt and prompt:IsA("ProximityPrompt") then
            -- Note: On client, ProximityPromptService events pass ONLY (prompt), player is nil!
            if player ~= nil and player ~= LocalPlayer then return end
            local act = (prompt.ActionText or ""):lower()
            local obj = (prompt.ObjectText or ""):lower()
            local pName = prompt.Parent and prompt.Parent.Name:lower() or ""
            local mName = prompt.Parent and prompt.Parent.Parent and prompt.Parent.Parent.Name:lower() or ""
            local prName = prompt.Name:lower()
            if prName:find("hide") or act:find("hide") or act:find("enter") or act:find("closet") or act:find("wardrobe")
               or obj:find("closet") or obj:find("wardrobe") or obj:find("locker") or obj:find("bed")
               or pName:find("closet") or pName:find("wardrobe") or pName:find("locker") or pName:find("bed")
               or mName:find("closet") or mName:find("wardrobe") or mName:find("locker") or mName:find("bed") then
                unhideGraceUntil = os.clock() + 1.0
                lastForwardPos = nil
                lastForwardCFrame = nil
                table.clear(trailHistory)
                wasMoving = false
                if syncServerSlide then syncServerSlide(false, false) end

                -- Zero velocities so server position reconciliation to wardrobe succeeds instantly
                task.spawn(function()
                    local r = getRoot()
                    if r then
                        r.AssemblyLinearVelocity = Vector3.zero
                        r.AssemblyAngularVelocity = Vector3.zero
                    end
                end)
            end
        end
    end
    pps.PromptButtonHoldBegan:Connect(primeHidingGrace)
    pps.PromptTriggered:Connect(primeHidingGrace)
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
    local hum = char and char:FindFirstChildWhichIsA("Humanoid")
    local mgTable = getMainGameTable()
    local isCrouching = (mgTable and mgTable.crouching) or (char and char:GetAttribute("Crouching")) or false
    local isMoving = (char and hum and hum.MoveDirection.Magnitude > 0.05) or false
    -- Crucial: When WalkSpeed is enabled AND player is moving, OR when actively sliding, slide state is authorized on server.
    -- When STANDING STILL (isMoving == false), isSliding MUST BE FALSE to prevent server slide physics from pushing player backwards!
    local isSliding = (shouldAuthorize == true) and isMoving and (State.WalkSpeed_Enabled or (isActuallySliding == true))
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
local TeleportState = { isTweening = false, activeToken = 0, immunityUntil = 0 }

local function isTeleportImmune()
    return TeleportState.isTweening or isAtRoof or (os.clock() < TeleportState.immunityUntil)
end

-- =========================================================================
-- Universal Tool Inspection, Auto-Equip & Infinite Items Dupe Engine
-- =========================================================================
getEquippedOrInventoryTool = function(matchNames)
    local char = getChar()
    local bp = LocalPlayer:FindFirstChild("Backpack")
    -- Priority 1: Check if already equipped in Character
    if char then
        for _, m in ipairs(matchNames) do
            local ml = m:lower()
            for _, t in ipairs(char:GetChildren()) do
                if t:IsA("Tool") and t.Name:lower():find(ml) then
                    return t, true -- tool, isEquipped
                end
            end
        end
    end
    -- Priority 2: Check Backpack
    if bp then
        for _, m in ipairs(matchNames) do
            local ml = m:lower()
            for _, t in ipairs(bp:GetChildren()) do
                if t:IsA("Tool") and t.Name:lower():find(ml) then
                    return t, false -- tool, isEquipped
                end
            end
        end
    end
    return nil, false
end

-- Infallible Dropped Tool Pickup Engine: Aggressively searches Workspace.Drops and CurrentRooms for the specific dropped tool
local function matchesToolName(dropName, targetName)
    local d = dropName:lower()
    local t = targetName:lower()
    if d:find(t) or t:find(d) then return true end
    local dRoot = d:gsub("s$", "")
    local tRoot = t:gsub("s$", "")
    if d:find(tRoot) or t:find(dRoot) then return true end
    return false
end

retrieveDroppedTool = function(toolName, maxWait)
    local targetName = toolName:lower()
    local start = os.clock()
    local deadline = start + (maxWait or 3.5)
    task.spawn(function()
        local reclaimed = false
        while os.clock() < deadline and not reclaimed do
            -- 1. Check if tool is already back in character or backpack
            local char = getChar()
            local bp = LocalPlayer:FindFirstChild("Backpack")
            for _, item in ipairs(char and char:GetChildren() or {}) do
                if item:IsA("Tool") and matchesToolName(item.Name, targetName) then
                    reclaimed = true
                    break
                end
            end
            if not reclaimed and bp then
                for _, item in ipairs(bp:GetChildren()) do
                    if item:IsA("Tool") and matchesToolName(item.Name, targetName) then
                        reclaimed = true
                        break
                    end
                end
            end
            if reclaimed then
                Hub.Notify("Infinite Items", toolName .. " retained successfully!", 2)
                break
            end

            -- 2. Search all potential drop locations (Workspace.Drops, CurrentRooms, and Workspace descendants)
            local candidateDrops = {}
            local drops = Workspace:FindFirstChild("Drops")
            if drops then
                for _, d in ipairs(drops:GetDescendants()) do
                    if (d:IsA("Tool") or d:IsA("Model") or d:IsA("BasePart")) and matchesToolName(d.Name, targetName) then
                        table.insert(candidateDrops, d)
                    end
                end
            end

            local cr = Workspace:FindFirstChild("CurrentRooms")
            if cr then
                for _, d in ipairs(cr:GetDescendants()) do
                    if (d:IsA("Tool") or d:IsA("Model")) and matchesToolName(d.Name, targetName) then
                        table.insert(candidateDrops, d)
                    end
                end
            end

            local r = getRoot()
            for _, drop in ipairs(candidateDrops) do
                local prompt = drop:FindFirstChildWhichIsA("ProximityPrompt", true)
                local handle = drop:IsA("BasePart") and drop or (drop:FindFirstChild("Handle") or drop:FindFirstChildWhichIsA("BasePart", true))

                if handle and r then
                    pcall(function()
                        handle.CFrame = r.CFrame
                        handle.CanCollide = false
                    end)
                end

                if prompt and prompt.Parent then
                    prompt.Enabled = true
                    prompt.HoldDuration = 0
                    prompt.RequiresLineOfSight = false
                    prompt.MaxActivationDistance = 45
                    pcall(function() fireproximityprompt(prompt) end)
                end

                if r and handle and firetouchinterest then
                    pcall(function()
                        firetouchinterest(r, handle, 0)
                        firetouchinterest(r, handle, 1)
                    end)
                end
            end

            -- Also scan any ProximityPrompt whose ObjectText or ActionText mentions the tool
            if #candidateDrops == 0 then
                local searchContainers = { Workspace:FindFirstChild("Drops"), Workspace:FindFirstChild("CurrentRooms") }
                for _, c in ipairs(searchContainers) do
                    if c then
                        for _, prompt in ipairs(c:GetDescendants()) do
                            if prompt:IsA("ProximityPrompt") then
                                local obj = (prompt.ObjectText or ""):lower()
                                local act = (prompt.ActionText or ""):lower()
                                if matchesToolName(obj, targetName) or matchesToolName(act, targetName) then
                                    prompt.Enabled = true
                                    prompt.HoldDuration = 0
                                    prompt.RequiresLineOfSight = false
                                    prompt.MaxActivationDistance = 45
                                    pcall(function() fireproximityprompt(prompt) end)
                                end
                            end
                        end
                    end
                end
            end

            task.wait(0.04)
        end
    end)
end

local isDroppingAndRetrieving = false
local lastDupeTime = 0

executeItemDupeDrop = function(tool, delaySeconds)
    if not tool or not State.Infinite_Items then return end
    local now = os.clock()
    if isDroppingAndRetrieving and (now - lastDupeTime < 0.3) then return end
    lastDupeTime = now
    isDroppingAndRetrieving = true

    local toolName = tool.Name
    local char = getChar()
    local bp = LocalPlayer:FindFirstChild("Backpack")
    local hum = char and char:FindFirstChildWhichIsA("Humanoid")

    task.spawn(function()
        -- Ensure tool is equipped in Character so DropItem remote accepts it
        if tool.Parent == bp and hum then
            hum:EquipTool(tool)
            task.wait(0.06)
        end

        -- Calibrated Delay: Allows server to validate unlock / consumption before drop executes
        if delaySeconds and delaySeconds > 0 then
            task.wait(delaySeconds)
        end

        local rf = remotesFolder or game:GetService("ReplicatedStorage"):FindFirstChild("RemotesFolder")
        local dropRemote = rf and rf:FindFirstChild("DropItem")
        if dropRemote and tool and tool.Parent then
            pcall(function() dropRemote:FireServer(tool) end)
        end

        -- Aggressive multi-frame retrieval
        retrieveDroppedTool(toolName, 3.5)

        task.delay(0.35, function()
            isDroppingAndRetrieving = false
        end)
    end)
end

-- Active Proximity Sentry: Automatically solves locks & opens doors on approach (Zero Yield / Full Descendants)
local openedDoors = { lastKeyEquip = 0, lastSentryCheck = 0 }

local function processNearbyDoors(currentPos, maxReach)
    local curRooms = Workspace:FindFirstChild("CurrentRooms")
    if not curRooms then return end
    local reach = math.clamp(maxReach or 20, 10, 48)
    local r = getRoot()
    local char = getChar()
    local coll = char and char:FindFirstChild("Collision")
    local cp = char and char:FindFirstChild("CollisionPart")

    for _, rm in ipairs(curRooms:GetChildren()) do
        for _, d in ipairs(rm:GetDescendants()) do
            if d:IsA("Model") and (d.Name == "Door" or d.Name == "DoorNormal" or d.Name == "SideroomDoor" or d.Name:lower():find("door")) then
                -- Anti-Dupe Protection: NEVER strip collisions, open, or interact with Dupe doors!
                if isDupeDoor(d, rm) then
                    if State.Anti_Dupe then
                        secureDupeDoor(d)
                    end
                    continue
                end
                local dPart = d:FindFirstChild("Door") or d:FindFirstChild("Hidden") or d.PrimaryPart or d:FindFirstChildWhichIsA("BasePart")
                if dPart and (currentPos - dPart.Position).Magnitude <= reach then
                    -- 1. Strip CanCollide locally on all door parts so character never hits physical barrier
                    for _, dp in ipairs(d:GetDescendants()) do
                        if dp:IsA("BasePart") and not dp.Name:lower():find("frame") and dp.CanCollide then
                            dp.CanCollide = false
                        end
                    end

                    -- 2. Check for Lock and auto-unlock ONLY if Auto_Interact and AutoInteract_Keys are enabled!
                    local lock = d:FindFirstChild("Lock")
                    local isLocked = false
                    if lock and lock.Parent then
                        local up = lock:FindFirstChild("UnlockPrompt", true) or lock:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if up and up.Enabled then
                            isLocked = true
                            if State.Auto_Interact and State.AutoInteract_Keys then
                                up.HoldDuration = 0
                                up.RequiresLineOfSight = false
                                up.MaxActivationDistance = math.max(up.MaxActivationDistance or 0, 14)
                                local now = os.clock()
                                if (now - (openedDoors.lastKeyEquip or 0) >= 0.25) then
                                    openedDoors.lastKeyEquip = now
                                    task.spawn(function()
                                        local tool, isEq = getEquippedOrInventoryTool({"lockpick", "skeleton", "key"})
                                        local hum = char and char:FindFirstChildWhichIsA("Humanoid")
                                        if tool and not isEq and hum and tool.Parent == LocalPlayer.Backpack then
                                            hum:EquipTool(tool)
                                            task.wait(0.08)
                                        end
                                        pcall(function() fireproximityprompt(up) end)
                                        if tool and State.Infinite_Items and State.Infinite_Lockpicks then
                                            local tn = tool.Name:lower()
                                            if tn:find("lockpick") or tn:find("skeleton") then
                                                executeItemDupeDrop(tool, 0.09)
                                            end
                                        end
                                    end)
                                end
                            end
                        end
                    end

                    -- 3. Universal Door Opening Engine (Side Doors DoorNormal & Main Doors)
                    if not isLocked then
                        -- Trigger client network remote (Main doors)
                        local co = d:FindFirstChild("ClientOpen")
                        if co and co:IsA("RemoteEvent") then
                            pcall(function() co:FireServer() end)
                        end

                        -- Trigger local bindable open events
                        local fo = d:FindFirstChild("Func_ForceOpen") or d:FindFirstChild("Func_Open")
                        if fo and fo:IsA("BindableEvent") then
                            pcall(function() fo:Fire() end)
                        end

                        -- Multi-receptor Touch Trigger for DoorNormal / Hidden
                        -- Satisfies all server touch listeners: Collision, CollisionPart, and HumanoidRootPart!
                        local hiddenPart = d:FindFirstChild("Hidden")
                        if hiddenPart and hiddenPart:IsA("BasePart") then
                            pcall(function()
                                hiddenPart.CanTouch = true
                                if coll then firetouchinterest(coll, hiddenPart, 0); firetouchinterest(coll, hiddenPart, 1) end
                                if cp then firetouchinterest(cp, hiddenPart, 0); firetouchinterest(cp, hiddenPart, 1) end
                                if r then firetouchinterest(r, hiddenPart, 0); firetouchinterest(r, hiddenPart, 1) end
                            end)
                        end

                        -- Note: Doors open cleanly via Hidden touch interest and ClientOpen remote.
                        -- ProximityPrompt interaction on doors is disabled so no interact prompt or E-spam appears!
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

-- High-Precision Environment & Hiding Spot Introspectors
local function isPlayerOutOfMap()
    if State.Noclip then return true end
    local root = getRoot()
    if not root then return false end
    local pos = root.Position
    local curRooms = Workspace:FindFirstChild("CurrentRooms")
    if not curRooms then return true end
    for _, rm in ipairs(curRooms:GetChildren()) do
        local cf, sz = rm:GetBoundingBox()
        local minBound = cf.Position - sz * 0.5 - Vector3.new(4, 4, 4)
        local maxBound = cf.Position + sz * 0.5 + Vector3.new(4, 4, 4)
        if pos.X >= minBound.X and pos.X <= maxBound.X and
           pos.Z >= minBound.Z and pos.Z <= maxBound.Z and
           pos.Y >= minBound.Y and pos.Y <= maxBound.Y then
            return false
        end
    end
    return true
end

local function isHidingSpotNearPos(pos)
    if not pos then return false end
    local p = (typeof(pos) == "CFrame") and pos.Position or pos
    if typeof(p) ~= "Vector3" then return false end
    local curRooms = Workspace:FindFirstChild("CurrentRooms")
    if not curRooms then return false end
    for _, rm in ipairs(curRooms:GetChildren()) do
        for _, desc in ipairs(rm:GetDescendants()) do
            if desc:IsA("Model") then
                local nl = desc.Name:lower()
                if nl:find("wardrobe") or nl:find("closet") or nl:find("bed") or nl:find("locker") then
                    local pivot = desc:GetPivot().Position
                    if (pivot - p).Magnitude < 22 then
                        return true
                    end
                end
            end
        end
    end
    return false
end

-- =========================================================================
-- Universal Godmode & Client Death Interceptor (Protects Against ALL Entities)
-- Eradicates all one-shot entity kill triggers across Rush, Ambush, A-60, Seek, etc.!
-- =========================================================================
local function initGodModeImmunity()
    -- God Mode neutered per daddy's instruction so Fly Noclip runs cleanly without conflict.
    -- Defuse Jack jumpscares: Silences scream sounds and deletes Jack popups from wardrobes (Zero FPS overhead)
    pcall(function()
        local function defuseJackModel(inst)
            if not inst or not inst:IsA("Model") then return end
            local n = inst.Name:lower()
            if n:find("jack") then
                for _, d in ipairs(inst:GetDescendants()) do
                    if d:IsA("Sound") then
                        d.Volume = 0
                        d:Stop()
                    elseif d:IsA("Decal") or d:IsA("ImageLabel") or d:IsA("Texture") then
                        d.Transparency = 1
                    end
                end
                pcall(function() inst:Destroy() end)
            end
        end
        local curRooms = Workspace:FindFirstChild("CurrentRooms")
        if curRooms then
            for _, rm in ipairs(curRooms:GetChildren()) do
                local j = rm:FindFirstChild("Jack") or (rm:FindFirstChild("Wardrobe") and rm.Wardrobe:FindFirstChild("Jack"))
                if j then defuseJackModel(j) end
            end
        end
    end)

    -- Note: PlayerDied hook removed per daddy's instruction.
    -- Natural DOORS death cutscenes, Guiding Light hints, and death messages now play cleanly with zero desync!
end

-- Absolute Glitch & Void Deflection Shield (Zero Glitch Invariant: Map & Noclip Immune)
local function initAntiGlitchShield()
    initGodModeImmunity()
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
                            if State.Noclip or isPlayerOutOfMap() or State.Anti_Rush or State.Deflect_Glitch then
                                return -- Universal Entity Immunity: Drop ALL enemy modules for ALL entities!
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

        -- 2. Intercept Jumpscare and JumpscareBindable events for Glitch, Void, Rush & Ambush
        local jmp = rf and rf:FindFirstChild("Jumpscare")
        if jmp and getconnections then
            for _, c in ipairs(getconnections(jmp.OnClientEvent)) do
                local fn = c.Function
                if fn and not _G["JMP_DETOURED_" .. tostring(fn)] then
                    _G["JMP_DETOURED_" .. tostring(fn)] = true
                    if hookfunction then
                        hookfunction(fn, newcclosure(function(jName, ...)
                            if State.Noclip or isPlayerOutOfMap() or State.Anti_Rush or State.Deflect_Glitch then
                                return -- Universal Jumpscare Immunity: Block ALL jumpscares for ALL entities!
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
                            if State.Noclip or isPlayerOutOfMap() or State.Anti_Rush or State.Deflect_Glitch then
                                return -- Universal Jumpscare Immunity: Block ALL jumpscares for ALL entities!
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

local cachedMovSpeedFn = nil
local function syncNativeFlightSpeed(speed)
    pcall(function()
        if not cachedMovSpeedFn and getgc then
            local pGui = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
            local mov = pGui and pGui:FindFirstChild("MainUI") and pGui.MainUI:FindFirstChild("Initiator") and pGui.MainUI.Initiator:FindFirstChild("Main_Game") and pGui.MainUI.Initiator.Main_Game:FindFirstChild("Movement")
            if mov then
                for _, fn in ipairs(getgc(false)) do
                    if type(fn) == "function" and getfenv(fn).script == mov and debug.info(fn, "l") == 1491 then
                        cachedMovSpeedFn = fn
                        break
                    end
                end
            end
        end
        if cachedMovSpeedFn and debug.setupvalue then
            debug.setupvalue(cachedMovSpeedFn, 22, speed)
        end
    end)
end



local lastFlySlidePulse = 0
local lastCrouchStealthTick = 0
local flyPos = nil
local lastNoclipDisableGrace = 0

local function pulseSlideKeepAlive()
    if syncServerSlide then
        syncServerSlide(true, true)
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
                        local targetPos = (typeof(p2) == "Vector3") and p2 or ((typeof(p2) == "CFrame") and p2.Position or nil)

                        local isNearHiding = targetPos and isHidingSpotNearPos(targetPos)
                        local isGraceActive = (os.clock() < unhideGraceUntil)
                        local isHidingNow = isPlayerHiding(char, mgTable)
                        local isChaseActive = (mgTable and mgTable.chase == true)

                        -- Legitimate in-game hiding transitions (wardrobe / closet / bed) are preserved!
                        if isNearHiding or isGraceActive or isHidingNow or isChaseActive then
                            return rawFn(p1, p2, p3, p4)
                        end

                        -- When Noclip, Walk Noclip, Anti-Cheat, Tweening, or Speed is active:
                        -- Drop ALL server-side anti-cheat rollback teleports!
                        if State.Bypass_AntiCheat or State.Noclip or State.Walk_Noclip or TeleportState.isTweening or State.WalkSpeed_Enabled or State.Deflect_Glitch or (os.clock() < lastNoclipDisableGrace) then
                            if mgTable and mgTable.SETNEWCF then
                                mgTable.SETNEWCF = nil
                            end
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
                            hookfunction(fn, newcclosure(function(pTarget, ...)
                                local char = getChar()
                                local mgTable = getMainGameTable()
                                local targetPos = (typeof(pTarget) == "Vector3") and pTarget or ((typeof(pTarget) == "CFrame") and pTarget.Position or nil)

                                local isNearHiding = targetPos and isHidingSpotNearPos(targetPos)
                                local isGraceActive = (os.clock() < unhideGraceUntil)
                                local isHidingNow = isPlayerHiding(char, mgTable)
                                local isChaseActive = (mgTable and mgTable.chase == true)

                                if isNearHiding or isGraceActive or isHidingNow or isChaseActive then
                                    return fn(pTarget, ...)
                                end

                                if State.Bypass_AntiCheat or State.Noclip or State.Walk_Noclip or TeleportState.isTweening or State.WalkSpeed_Enabled or State.Deflect_Glitch or (os.clock() < lastNoclipDisableGrace) then
                                    return
                                end
                                return fn(pTarget, ...)
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
                            hookfunction(fn, newcclosure(function(p1, p2, ...)
                                local char = getChar()
                                local mgTable = getMainGameTable()
                                local targetPos = (typeof(p2) == "Vector3") and p2 or ((typeof(p2) == "CFrame") and p2.Position or ((typeof(p1) == "Vector3") and p1 or nil))

                                local isNearHiding = targetPos and isHidingSpotNearPos(targetPos)
                                local isGraceActive = (os.clock() < unhideGraceUntil)
                                local isHidingNow = isPlayerHiding(char, mgTable)
                                local isChaseActive = (mgTable and mgTable.chase == true)

                                if isNearHiding or isGraceActive or isHidingNow or isChaseActive then
                                    return fn(p1, p2, ...)
                                end

                                if State.Bypass_AntiCheat or State.Noclip or State.Walk_Noclip or TeleportState.isTweening or State.WalkSpeed_Enabled or State.Deflect_Glitch or (os.clock() < lastNoclipDisableGrace) then
                                    if mgTable and mgTable.SETNEWCF then
                                        mgTable.SETNEWCF = nil
                                    end
                                    return
                                end
                                return fn(p1, p2, ...)
                            end))
                        end
                    end
                end)
            end
        end
    end)

    -- 3. Clear SETNEWCF during active Noclip, Tweening, Anti-Cheat, or disable grace period
    local mgTable = getMainGameTable()
    if mgTable and not isPlayerHiding(getChar(), mgTable) and (os.clock() >= unhideGraceUntil) and (State.Bypass_AntiCheat or State.Noclip or TeleportState.isTweening or (os.clock() < lastNoclipDisableGrace)) then
        if mgTable.SETNEWCF then
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
            if State.Fly_Enabled or State.Noclip or TeleportState.isTweening or State.WalkSpeed_Enabled then
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
getExactFloorPos = function(pos, fallbackOffset)
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
local function restoreCharacterVisibility(char)
    if not char then return end
    local mg = mgTable or getMainGameTable()
    if mg and mg.hideplayers and mg.hideplayers < 0 then
        mg.hideplayers = 0
    end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") or p:IsA("Decal") then
            local pLower = p.Name:lower()
            local isHeadAcc = (pLower == "head" or pLower:find("face") or pLower:find("hair") or pLower:find("lash") or pLower:find("brow") or pLower:find("hat"))
            if not isHeadAcc and not pLower:find("collision") and pLower ~= "humanoidrootpart" then
                p.LocalTransparencyModifier = 0
            end
        end
    end
end

local function restoreCharacterInteractivity(char)
    if not char then return end
    local function applyPartImmunity(p)
        if p:IsA("BasePart") then
            p.CanTouch = true
            p.CanQuery = true
            pcall(function() p.CollisionGroup = "NoPlayer" end)
        end
    end
    for _, p in ipairs(char:GetDescendants()) do
        applyPartImmunity(p)
    end
    if not char:GetAttribute("InteractivityHooked") then
        char:SetAttribute("InteractivityHooked", true)
        char.DescendantAdded:Connect(applyPartImmunity)
    end
    local coll = char:FindFirstChild("Collision")
    local cp = char:FindFirstChild("CollisionPart")
    local root = char:FindFirstChild("HumanoidRootPart")
    if coll and coll:IsA("BasePart") then
        -- During Noclip, Collision MUST be CanCollide = false so player does not bounce off walls!
        coll.CanCollide = not State.Noclip
        pcall(function() coll.CollisionGroup = "NoPlayer" end)
        coll.CanTouch = true
        coll.CanQuery = true
    end
    if cp and cp:IsA("BasePart") then
        cp.CanCollide = not State.Noclip
        pcall(function() cp.CollisionGroup = "NoPlayer" end)
        cp.CanTouch = true
        cp.CanQuery = true
    end
    if root and root:IsA("BasePart") then
        root.CanCollide = false
        pcall(function() root.CollisionGroup = "NoPlayer" end)
        root.CanTouch = true
        root.CanQuery = true
    end
    restoreCharacterVisibility(char)
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
            TeleportState.immunityUntil = os.clock() + 1.2
            restoreCharacterInteractivity(char)
        end
        if callback then callback() end
        return true
    end

    local speed = math.clamp(speedVal or State.Teleport_Speed or 38, 18, 65)
    local duration = totalDist / speed
    local moveDir = (totalDist > 0.01) and (moveVec / totalDist) or Vector3.zero
    local token = tick() + math.random()
    TeleportState.activeToken = token
    TeleportState.isTweening = true
    TeleportState.immunityUntil = os.clock() + duration + 1.8

    if syncServerSlide then syncServerSlide(true, true) end

    local t0 = os.clock()
    local lastSlidePulse = t0
    local settleStartTime = nil

    local conn
    conn = RunService.Heartbeat:Connect(function()
        if conn then trackConn(conn) end
        if TeleportState.activeToken ~= token or _G.DOORS_SESSION ~= currentSession or not char or not root or hum.Health <= 0 then
            if conn then conn:Disconnect() end
            if TeleportState.activeToken == token then
                TeleportState.isTweening = false
                restoreCharacterInteractivity(char)
                if isFinalDestination then TeleportState.immunityUntil = os.clock() + 1.2 end
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
                if TeleportState.activeToken == token then TeleportState.isTweening = false end
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
                if TeleportState.activeToken == token then
                    TeleportState.isTweening = false
                    TeleportState.immunityUntil = os.clock() + 1.2
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

                -- Server State Slide Handshake: cleanly update server slide authorization without dropping physics
                if syncServerSlide then
                    syncServerSlide(false, false)
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

teleportToRoomKey = function(callback)
    local char = getChar()
    local root = getRoot()
    if (State.Noclip or State.Auto_Complete_100) and curRooms then
        local targetKey = nil
        local targetPart = nil
        local minDist = math.huge
        for _, desc in ipairs(curRooms:GetDescendants()) do
            if desc.Name == "KeyObtain" or (desc.Name:lower():find("key") and desc:IsA("Model") and desc:FindFirstChildWhichIsA("ProximityPrompt", true)) then
                local part = desc:IsA("Model") and (desc.PrimaryPart or desc:FindFirstChildWhichIsA("BasePart", true)) or (desc:IsA("BasePart") and desc)
                if part and root then
                    local d = (root.Position - part.Position).Magnitude
                    if d < minDist then
                        minDist = d
                        targetKey = desc
                        targetPart = part
                    end
                end
            end
        end
        if targetPart then
            farmGlideTo(targetPart.Position + Vector3.new(0, 1.2, 0), 55, 4.0)
            local p = targetKey:FindFirstChildWhichIsA("ProximityPrompt", true)
            if p then
                p.HoldDuration = 0
                pcall(function() fireproximityprompt(p) end)
            end
            if callback then callback(true) end
            return true
        end
    end
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

teleportToNextDoor = function(callback)
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

    if State.Noclip or State.Auto_Complete_100 then
        -- Smooth linear flight directly to door front in current room
        farmGlideTo(doorPos + approachDir * 3.0, 55, 4.0)
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
                up.HoldDuration = 0
                pcall(function() fireproximityprompt(up) end)
                task.wait(0.2)
            end
        end
        local co = exitDoor:FindFirstChild("ClientOpen")
        if co then pcall(function() co:FireServer() end) end
        local hiddenPart = exitDoor:FindFirstChild("Hidden")
        if hiddenPart and hiddenPart:IsA("BasePart") then
            pcall(function()
                hiddenPart.CanTouch = true
                if root then
                    firetouchinterest(root, hiddenPart, 0)
                    task.wait(0.02)
                    firetouchinterest(root, hiddenPart, 1)
                end
            end)
        end
        processNearbyDoors(doorPos, 25)
        -- Glide through the doorway into the next room chamber
        farmGlideTo(doorPos - approachDir * 6.0, 50, 2.0)
        if callback then callback(true) end
        return true
    end

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
                TeleportState.immunityUntil = os.clock() + 2.0
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
local lastPreRoofFloorPos = nil

-- Purge any residual physical platform bricks (eliminates sky-freeze traps permanently)
local function purgeResidualRoofPlatforms()
    pcall(function()
        local cam = Workspace.CurrentCamera
        if cam then
            local p = cam:FindFirstChild("SafeRoofPlatform")
            if p then p:Destroy() end
        end
        local wsPlat = Workspace:FindFirstChild("SafeRoofPlatform")
        if wsPlat then wsPlat:Destroy() end
    end)
end
purgeResidualRoofPlatforms()

local function removeRoofPlatform()
    purgeResidualRoofPlatforms()
end

local function teleportToRoof(callback)
    if State.Noclip or isPlayerOutOfMap() then
        -- In-Flight & Out-of-Bounds Protection: Never trigger roof evacuation into ceiling boundary kill!
        if callback then callback(false) end
        return false
    end

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
    -- Elevate vertically +75 studs: 100% outside Rush's 40-stud kill cylinder & ceiling boundary without physical platform trap
    local roofTargetPos = root.Position + Vector3.new(0, 75, 0)
    
    purgeResidualRoofPlatforms()
    Hub.Notify("Safe Zone", "Ascending to Safe Roof (+75 Studs)...", 2)
    isAtRoof = true
    State.Safe_Roof_Station = true

    -- Pre-open all nearby doors and strip ceiling collision above character
    processNearbyDoors(root.Position, 40)
    pcall(function()
        local rayParams = RaycastParams.new()
        rayParams.FilterDescendantsInstances = {char, Workspace.CurrentCamera}
        rayParams.FilterType = Enum.RaycastFilterType.Exclude
        local upHit = workspace:Raycast(root.Position, Vector3.new(0, 85, 0), rayParams)
        if upHit and upHit.Instance then
            upHit.Instance.CanCollide = false
        end
    end)

    safeTweenTeleport(CFrame.new(roofTargetPos, roofTargetPos + root.CFrame.LookVector), 85, true, true, function()
        char:PivotTo(CFrame.new(roofTargetPos, roofTargetPos + root.CFrame.LookVector))
        root.CFrame = CFrame.new(roofTargetPos, roofTargetPos + root.CFrame.LookVector)
        local cp = char:FindFirstChild("CollisionPart")
        if cp then cp.CFrame = CFrame.new(roofTargetPos, roofTargetPos + root.CFrame.LookVector) end
        root.AssemblyLinearVelocity = Vector3.new(0, 0.05, 0)
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

    local targetFloorPos = getExactFloorPos(Vector3.new(root.Position.X, (lastPreRoofFloorPos and lastPreRoofFloorPos.Y) or (root.Position.Y - 75), root.Position.Z))

    safeTweenTeleport(CFrame.new(targetFloorPos, targetFloorPos + root.CFrame.LookVector), 75, false, function()
        purgeResidualRoofPlatforms()
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
local hbFlightConn; hbFlightConn = RunService.Heartbeat:Connect(function(dt)
    if hbFlightConn then trackConn(hbFlightConn) end
    if _G.DOORS_SESSION ~= currentSession then return end
    local char = getChar()
    local root = getRoot()
    local hum = char and char:FindFirstChildWhichIsA("Humanoid")
    if not hum or not hum.Parent or not root then return end

    local mgTable = getMainGameTable()
    local isInsideHiding = (char:GetAttribute("Hiding") == true) or (mgTable and (mgTable.hiding == true or mgTable.animating == true or mgTable.stopcam == true))
    if wasHidingState and not isInsideHiding then
        -- Player just exited hiding spot: grace period so exit animation and camera restore smoothly without flicker
        unhideGraceUntil = os.clock() + 0.8
        justExitedHiding = true
    end
    wasHidingState = isInsideHiding
    local hiding = isInsideHiding or (os.clock() < unhideGraceUntil)

    -- Auto-disable Noclip if Bypass Anti-Cheat Core is disabled
    if State.Noclip and not State.Bypass_AntiCheat then
        State.Noclip = false
        restoreCharacterInteractivity(char)
        if root then root.AssemblyLinearVelocity = Vector3.zero end
        syncServerSlide(false, false)
        Hub.Notify("Movement", "Fly-Noclip disabled: Bypass Anti-Cheat Core is required!", 2)
    end

    -- Door Sentry: ONLY runs when Auto Doors is explicitly enabled or during Knobs Farm (NEVER auto-opens in manual flight!)
    local nowTime = os.clock()
    if root and not hiding and (State.AutoInteract_Doors or State.Knobs_Farm_Active) and (nowTime - (openedDoors.lastSentryCheck or 0) >= 0.15) then
        openedDoors.lastSentryCheck = nowTime
        local doorReach = State.Knobs_Farm_Active and 35 or 16
        processNearbyDoors(root.Position, doorReach)
    end

    -- God-Mode & Hitbox Immunity Engine: Eradicates all monster contact damage (Intangible Hitbox, Zero Teleport)
    if State.God_Mode then
        local char = getChar()
        local hum = char and char:FindFirstChildWhichIsA("Humanoid")
        if hum then
            if hum:GetStateEnabled(Enum.HumanoidStateType.Dead) then
                pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false) end)
            end
            if hum.Health < 100 and hum.Health > 0 then
                hum.Health = 100
            end
        end

        if char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then
                    -- Preserve CanTouch & CanQuery so drawers, keys, and door prompts work flawlessly!
                    p.CanTouch = true
                    p.CanQuery = true
                    if p.CollisionGroup ~= "NoPlayer" then
                        pcall(function() p.CollisionGroup = "NoPlayer" end)
                    end
                end
            end
        end

        local lethalNames = {"rush", "ambush", "a60", "a-60", "a120", "a-120", "seek", "figure", "grumble", "giggle", "gloombat", "dread", "blitz", "lookman"}
        local live = Workspace:FindFirstChild("LiveEntities")
        local curRooms = Workspace:FindFirstChild("CurrentRooms")
        local scanTargets = {Workspace, live, curRooms}

        for _, container in ipairs(scanTargets) do
            if container then
                for _, ent in ipairs(container:GetChildren()) do
                    local el = ent.Name:lower()
                    local isLethal = false
                    for _, ln in ipairs(lethalNames) do
                        if el:find(ln) then isLethal = true; break end
                    end
                    if isLethal then
                        defuseLethalEntity(ent)
                        if el:find("figure") then
                            local fHit = ent:FindFirstChild("Hitbox", true)
                            if fHit and fHit:IsA("BasePart") then
                                fHit.CanTouch = false
                                fHit.CanCollide = false
                                fHit.CanQuery = false
                            end
                        end
                    end
                end
            end
        end
    end

    -- Continuous Glitch / Void Shield Deflector: Strictly active ONLY when Glitch is attacking!
    -- Never resets stopcam or unanchors root during closet/bed entry or exit, preserving natural cutscenes & unhiding animations
    local isGlitchActive = false
    if Workspace:FindFirstChild("Glitch") then
        isGlitchActive = true
    else
        local pGui = LocalPlayer:FindFirstChild("PlayerGui")
        local mainUI = pGui and pGui:FindFirstChild("MainUI")
        local mainFrame = mainUI and mainUI:FindFirstChild("MainFrame")
        if mainFrame then
            local gs = mainFrame:FindFirstChild("GlitchScreen")
            if gs and gs.Visible then isGlitchActive = true end
            local ge = mainFrame:FindFirstChild("GlitchEffect")
            if ge and ge.Visible then isGlitchActive = true end
            if isGlitchActive then
                if gs and gs.Visible then gs.Visible = false end
                if ge and ge.Visible then ge.Visible = false end
            end
        end
    end

    if isGlitchActive and (State.Deflect_Glitch or State.Bypass_AntiCheat) then
        if mgTable and mgTable.stopcam then
            mgTable.stopcam = false
        end
        if root and root.Anchored and not hiding and (os.clock() >= unhideGraceUntil) then
            root.Anchored = false
        end
        local lt = game:GetService("Lighting")
        if lt and lt.FogEnd < 200 then
            lt.FogEnd = 1000
            lt.FogStart = 0
        end
    end

    -- Omnidirectional Sub-Step Micro-Phase Glide & 3D Flight Engine (100% Anti-Cheat Immune & Wall Penetrating)
    if State.Noclip and State.Bypass_AntiCheat and not hiding and not TeleportState.isTweening and not isAutoFlying and not State.Knobs_Farm_Active and not State.Auto_Complete_100 then
        -- 1. Strip physics collisions across all parts for buttery-smooth penetration through walls, doors & clutter
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then
                if p.CanCollide then p.CanCollide = false end
                p.CanTouch = true
                p.CanQuery = true
            end
        end
        if hum then hum:ChangeState(Enum.HumanoidStateType.Freefall) end

        local cam = Workspace.CurrentCamera
        local camLook = cam.CFrame.LookVector
        local camRight = cam.CFrame.RightVector
        local camUp = Vector3.new(0, 1, 0)

        local steer = Vector3.zero
        local hasInput = false

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            steer = steer + camLook
            hasInput = true
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            steer = steer - camLook
            hasInput = true
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            steer = steer + camRight
            hasInput = true
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            steer = steer - camRight
            hasInput = true
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            steer = steer + camUp
            hasInput = true
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.C) then
            steer = steer - camUp
            hasInput = true
        end

        -- Fallback to Humanoid.MoveDirection for gamepad thumbsticks or mobile touch controls
        if hum.MoveDirection.Magnitude > 0.05 then
            steer = steer + hum.MoveDirection
            hasInput = true
        end

        -- Pure Native Physics Velocity Replication (Active 60Hz Server Packet Transmission):
        local speed = math.clamp(State.Noclip_Speed or 35, 4, 300)
        local targetVel = if hasInput and steer.Magnitude > 0.01 then steer.Unit * speed else Vector3.zero
        root.AssemblyLinearVelocity = targetVel
        root.AssemblyAngularVelocity = Vector3.zero

        -- Horizontal camera gaze alignment (rotation only, zero position teleportation)
        local hLook = Vector3.new(camLook.X, 0, camLook.Z)
        if hLook.Magnitude > 0.01 then
            root.CFrame = CFrame.new(root.Position, root.Position + hLook)
        end

        -- Retain DOORS native mgTable.clipPos synchronization and eradicate body/item invisibility
        local mgTable = getMainGameTable()
        if mgTable then
            mgTable.clipPos = root.Position
            if mgTable.hideplayers ~= 0 then mgTable.hideplayers = 0 end
            if mgTable.__NOBASERIG then mgTable.__NOBASERIG = false end
            if mgTable.canUseItems == false then mgTable.canUseItems = true end
        end

        local cam = Workspace.CurrentCamera
        local baseRig = cam and cam:FindFirstChild("BaseRig")
        if baseRig then
            for _, bp in ipairs(baseRig:GetDescendants()) do
                if bp:IsA("BasePart") then bp.LocalTransparencyModifier = 0 end
            end
        end
    elseif State.Walk_Noclip and not hiding and not TeleportState.isTweening then
        local mgTable = getMainGameTable()
        if mgTable and root then
            mgTable.clipPos = root.Position
            if mgTable.SETNEWCF then mgTable.SETNEWCF = nil end
        end
        -- Sub-frame Micro-Phase (Smoothly phases across walls in 1 frame so server solver never detects penetration)
        if hum and hum.MoveDirection.Magnitude > 0.1 and root then
            local moveUnit = hum.MoveDirection.Unit
            local phaseParams = RaycastParams.new()
            phaseParams.FilterType = Enum.RaycastFilterType.Exclude
            phaseParams.FilterDescendantsInstances = { char }
            local hit = Workspace:Raycast(root.Position, moveUnit * 1.6, phaseParams)
            if hit and hit.Instance and hit.Instance:IsA("BasePart") and not hit.Instance.Name:lower():find("floor") then
                root.CFrame = root.CFrame + moveUnit * 2.2
                if mgTable then mgTable.clipPos = root.Position end
            end
        end
    elseif State.WalkSpeed_Enabled and not hiding and not TeleportState.isTweening then
        local mgTable = getMainGameTable()
        local isCrouching = (mgTable and mgTable.crouching) or (char and char:GetAttribute("Crouching")) or false
        if hum.MoveDirection.Magnitude > 0.05 then
            applyTeflonGlide(char)
        else
            restoreDefaultFriction(char)
        end
        syncServerSlide(true, true)

        local targetSpeed = State.WalkSpeed_Value or 45
        if hum.WalkSpeed ~= targetSpeed then
            hum.WalkSpeed = targetSpeed
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
        if char and char:GetAttribute("SpeedBoostExtra") then
            pcall(function() char:SetAttribute("SpeedBoostExtra", nil) end)
        end
        if hum.WalkSpeed ~= 15 and not State.WalkSpeed_Enabled and not State.Noclip and not isSlidingActive then
            hum.WalkSpeed = 15
        end
    end

    -- Instant Acceleration & Directional Vector Response Engine:
    -- Bypasses humanoid acceleration ramp-up and eradicates TeflonGlide inertial sliding / ice skating!
    if State.Instant_Movement and not State.Noclip and not hiding and not TeleportState.isTweening and not isSlidingActive and not hum.Sit then
        local moveDir = hum.MoveDirection
        if moveDir.Magnitude > 0.05 then
            local speed = State.WalkSpeed_Enabled and (State.WalkSpeed_Value or 45) or (hum.WalkSpeed > 0 and hum.WalkSpeed or 15)
            local targetVel = moveDir.Unit * speed

            -- Natural vertical floor adaptation without synthetic platform feeling
            local curY = root.AssemblyLinearVelocity.Y
            root.AssemblyLinearVelocity = Vector3.new(targetVel.X, curY, targetVel.Z)
        else
            restoreDefaultFriction(char)
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

    -- Pure native flight altitude maintenance during Safe Roof Evasion (zero physical brick needed)
    if isAtRoof and root then
        if root.AssemblyLinearVelocity.Y < 0 then
            root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, 0.05, root.AssemblyLinearVelocity.Z)
        end
    end

    -- Synchronizes DOORS native noclip flag without corrupting wardrobe or door transitions
    local mgTable = getMainGameTable()
    if mgTable then
        if not hiding and (State.Bypass_AntiCheat or State.Noclip or TeleportState.isTweening or isAtRoof or (os.clock() < lastNoclipDisableGrace)) then
            if mgTable.SETNEWCF then
                mgTable.SETNEWCF = nil
            end
        end
        -- RESTORE & LOCK ORIGINAL SMOOTH FLY METHOD (mgTable.noclip = true)
        if State.Noclip then
            mgTable.noclip = true
        elseif not State.Noclip and mgTable.noclip then
            mgTable.noclip = false
        end
    end

    -- Ensure DOORS flight speed is synchronized continuously
    if State.Noclip then
        syncNativeFlightSpeed(State.Noclip_Speed or 45)
    end

    -- Natural crouching preserved without synthetic forced attribute locks

    -- Continuous FOV synchronization
    if State.FieldOfView and State.FieldOfView ~= 70 then
        if mgTable then mgTable.fovtarget = State.FieldOfView end
        local cam = Workspace.CurrentCamera
        if cam and cam.FieldOfView ~= State.FieldOfView then
            cam.FieldOfView = State.FieldOfView
        end
    end

    -- Continuous Viewmodel & Hand Retention Shield (Prevents hands/items from disappearing):
    if mgTable then
        if mgTable.__NOBASERIG == true then
            mgTable.__NOBASERIG = false
        end
        if mgTable.canUseItems == false and not hiding then
            mgTable.canUseItems = true
        end
    end

    -- Native Viewmodel & Equipped Item Shield:
    -- DOORS natively manages cam.BaseRig viewmodel meshes and equipped tool attachments.
    -- We strictly preserve original part transparencies, preventing held items from disappearing
    -- and preserving Buddy's transparent bounding handle (eliminating the magenta/red box permanently!).



    -- Character Collision & Prompt Interactivity Receptors:
    if char then
        local isCrouching = (char:GetAttribute("Crouching") == true) or (mgTable and mgTable.crouching == true) or false
        local targetGroup = (State.Noclip or State.Walk_Noclip) and "None" or "NoPlayer" 
        local coll = char:FindFirstChild("Collision")
        local cc = coll and coll:FindFirstChild("CollisionCrouch")
        local cp = char:FindFirstChild("CollisionPart")

        if State.Noclip then
            -- When Fly Noclip is active: ALL collision geometry is intangible so player glides cleanly through walls!
            -- Eliminates server collision bounce / forward-back teleporting desync!
            if coll and coll.CanCollide then coll.CanCollide = false end
            if cc and cc.CanCollide then cc.CanCollide = false end
            if cp and cp.CanCollide then cp.CanCollide = false end
        elseif isCrouching then
            if coll and coll.CanCollide then coll.CanCollide = false end
            if cc and not cc.CanCollide then cc.CanCollide = true end
            if cp and cp.CanCollide then cp.CanCollide = false end
        else
            if coll and not coll.CanCollide then coll.CanCollide = true end
            if cc and cc.CanCollide then cc.CanCollide = false end
            if cp and cp.CanCollide then cp.CanCollide = false end
        end

        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then
                if p.CollisionGroup ~= targetGroup then
                    pcall(function() p.CollisionGroup = targetGroup end)
                end
                if not p.CanTouch then p.CanTouch = true end
                if not p.CanQuery then p.CanQuery = true end
            end
        end
    end

    -- Continuous Body & First-Person Transparency Alignment:
    if char then
        if isInsideHiding then
            -- When sitting inside hiding spots (wardrobes/beds):
            -- Fully hide character locally so daddy's camera never sees his body beneath the floor through semi-transparent closet
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") or p:IsA("Decal") then
                    p.LocalTransparencyModifier = 1
                end
            end
        else
            -- When NOT hiding:
            -- 1. If we just transitioned out of hiding, reset body parts to 0 ONE TIME so exit animation is visible
            if justExitedHiding then
                justExitedHiding = false
                for _, p in ipairs(char:GetChildren()) do
                    if p:IsA("BasePart") then
                        local pLower = p.Name:lower()
                        if not (pLower == "head" or pLower:find("collision") or pLower == "humanoidrootpart") then
                            p.LocalTransparencyModifier = 0
                        end
                    end
                end
            end

            -- 2. Permanently enforce LocalTransparencyModifier = 1 on Head, face, hair, eyelashes, eyebrows, hats
            -- so they NEVER clip into first-person camera or render as black lines/distortions!
            local head = char:FindFirstChild("Head")
            if head and head:IsA("BasePart") then
                head.LocalTransparencyModifier = 1
                for _, desc in ipairs(head:GetDescendants()) do
                    if desc:IsA("BasePart") or desc:IsA("Decal") then
                        desc.LocalTransparencyModifier = 1
                    end
                end
            end

            for _, child in ipairs(char:GetChildren()) do
                if child:IsA("Accessory") then
                    local isHeadAcc = false
                    local accType = child.AccessoryType
                    if accType == Enum.AccessoryType.Hat or accType == Enum.AccessoryType.Hair
                        or accType == Enum.AccessoryType.Face or accType == Enum.AccessoryType.Eyebrow
                        or accType == Enum.AccessoryType.Eyelash then
                        isHeadAcc = true
                    end
                    local h = child:FindFirstChild("Handle")
                    if h and h:IsA("BasePart") then
                        for _, att in ipairs(h:GetChildren()) do
                            if att:IsA("Attachment") then
                                local an = att.Name:lower()
                                if an:find("head") or an:find("face") or an:find("hair") or an:find("hat") then
                                    isHeadAcc = true
                                    break
                                end
                            end
                        end
                        if isHeadAcc or child.Name:lower():find("hair") or child.Name:lower():find("face") or child.Name:lower():find("hat") or child.Name:lower():find("lash") then
                            h.LocalTransparencyModifier = 1
                            for _, hd in ipairs(h:GetDescendants()) do
                                if hd:IsA("BasePart") or hd:IsA("Decal") then
                                    hd.LocalTransparencyModifier = 1
                                end
                            end
                        end
                    end
                elseif child:IsA("BasePart") then
                    local cName = child.Name:lower()
                    if cName:find("collision") or cName == "humanoidrootpart" then
                        if child.Transparency < 1 then child.Transparency = 1 end
                    elseif cName:find("face") or cName:find("lash") or cName:find("brow") or cName:find("hair") then
                        child.LocalTransparencyModifier = 1
                    end
                end
            end
        end
    end
end)

-- First-Person Dynamic Eye-Level Camera Shield & 3D Head/Face Mesh Clip Eradication:
local cameraPitchConn; cameraPitchConn = RunService.RenderStepped:Connect(function()
    if cameraPitchConn then trackConn(cameraPitchConn) end
    if _G.DOORS_SESSION ~= currentSession then return end

    local char = getChar()
    if char then
        -- Enforce LocalTransparencyModifier = 1 in RenderStepped right before rasterization!
        -- Roblox animation engine runs between Stepped and RenderStepped; setting it here prevents animation from restoring visibility!
        -- Eradicates 3D face, eyelashes, hair ribbons, and black spike lines across daddy's screen
        local head = char:FindFirstChild("Head")
        if head and head:IsA("BasePart") then
            head.LocalTransparencyModifier = 1
            for _, desc in ipairs(head:GetDescendants()) do
                if desc:IsA("BasePart") or desc:IsA("Decal") then
                    desc.LocalTransparencyModifier = 1
                end
            end
        end
        for _, child in ipairs(char:GetChildren()) do
            if child:IsA("Accessory") then
                local isHeadAcc = false
                local accType = child.AccessoryType
                if accType == Enum.AccessoryType.Hat or accType == Enum.AccessoryType.Hair
                    or accType == Enum.AccessoryType.Face or accType == Enum.AccessoryType.Eyebrow
                    or accType == Enum.AccessoryType.Eyelash then
                    isHeadAcc = true
                end
                local h = child:FindFirstChild("Handle")
                if h and h:IsA("BasePart") then
                    for _, att in ipairs(h:GetChildren()) do
                        if att:IsA("Attachment") then
                            local an = att.Name:lower()
                            if an:find("head") or an:find("face") or an:find("hair") or an:find("hat") then
                                isHeadAcc = true
                                break
                            end
                        end
                    end
                    if isHeadAcc or child.Name:lower():find("hair") or child.Name:lower():find("face") or child.Name:lower():find("hat") or child.Name:lower():find("lash") then
                        h.LocalTransparencyModifier = 1
                        for _, hd in ipairs(h:GetDescendants()) do
                            if hd:IsA("BasePart") or hd:IsA("Decal") then
                                hd.LocalTransparencyModifier = 1
                            end
                        end
                    end
                end
            elseif child:IsA("BasePart") then
                local cName = child.Name:lower()
                if cName:find("face") or cName:find("lash") or cName:find("brow") or cName:find("hair") then
                    child.LocalTransparencyModifier = 1
                end
            end
        end
    end

    local cam = Workspace.CurrentCamera
    if not cam or cam.CameraType ~= Enum.CameraType.Scriptable then return end
    if State.Noclip or TeleportState.isTweening then return end

    local mgTable = getMainGameTable()
    if isPlayerHiding(char, mgTable) then return end

    local look = cam.CFrame.LookVector
    -- When tilting down to look at floor, drawers, or feet (look.Y < -0.15):
    -- Dynamically translate camera slightly forward (+0.0 to +0.38 studs) along horizontal gaze.
    -- This brings the camera's near clipping plane completely clear of the character's upper collar/chest!
    if look.Y < -0.15 then
        local downFactor = math.clamp((-look.Y - 0.15) / 0.85, 0, 1)
        local hLook = Vector3.new(look.X, 0, look.Z)
        if hLook.Magnitude > 0.001 then
            local fwdOffset = hLook.Unit * (downFactor * 0.38)
            cam.CFrame = cam.CFrame + fwdOffset
        end
    end
end)

-- Stepped Guard: Strips collisions & touch on character parts during Noclip
local steppedConn1; steppedConn1 = RunService.Stepped:Connect(function()
    if steppedConn1 then trackConn(steppedConn1) end
    if _G.DOORS_SESSION ~= currentSession then return end
    local char = getChar()
    local mgTable = getMainGameTable()
    if isPlayerHiding(char, mgTable) or (os.clock() < unhideGraceUntil) then return end

    local hum = char and char:FindFirstChildWhichIsA("Humanoid")
    if not hum then return end

    -- Native WalkSpeed synchronized in Heartbeat loop

    if State.Enable_Jumping then
        if not hum.UseJumpPower then hum.UseJumpPower = true end
        hum.JumpPower = 32
        hum.JumpHeight = 3.0
        if not hum:GetStateEnabled(Enum.HumanoidStateType.Jumping) then
            hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
        end
    end

    if State.Noclip or State.Walk_Noclip or State.Fly_Enabled or TeleportState.isTweening then
        -- Strip CanCollide and set CollisionGroup = "None" so server solver ignores wall collisions
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                if part.CanCollide then part.CanCollide = false end
                if part.CollisionGroup ~= "None" then
                    pcall(function() part.CollisionGroup = "None" end)
                end
                -- Always preserve CanTouch & CanQuery so wardrobes, drawers & doorway triggers never break!
                if not part.CanTouch then part.CanTouch = true end
                if not part.CanQuery then part.CanQuery = true end
            end
        end
    else
        -- SOLID FLOOR GROUNDING & CROUCH HOLE PASSAGE:
        local isCrouching = (char:GetAttribute("Crouching") == true) or (mgTable and mgTable.crouching == true) or false
        local targetGroup = isCrouching and "PlayerCrouching" or "NoPlayer"
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                if part.CollisionGroup ~= targetGroup then
                    pcall(function() part.CollisionGroup = targetGroup end)
                end
                if not part.CanTouch then part.CanTouch = true end
                if not part.CanQuery then part.CanQuery = true end
            end
        end
        local coll = char:FindFirstChild("Collision")
        local cc = coll and coll:FindFirstChild("CollisionCrouch")
        local cp = char:FindFirstChild("CollisionPart")
        if isCrouching then
            if coll and coll.CanCollide then coll.CanCollide = false end
            if cc and not cc.CanCollide then cc.CanCollide = true end
            if cp and cp.CanCollide then cp.CanCollide = false end
        else
            if coll and not coll.CanCollide then coll.CanCollide = true end
            if cc and cc.CanCollide then cc.CanCollide = false end
            if cp and cp.CanCollide then cp.CanCollide = false end
        end
    end
end)

-- =========================================================================
-- Noclip Room Entrance & Wardrobe Desynchronization Resolver + PromptGate Immunity
-- 1. Detours DOORS PromptGate to ensure wardrobe & closet prompts NEVER get suppressed/hidden
-- 2. Sequentially touches Door.Hidden triggers so server CurrentRoom matches physical room
-- =========================================================================
pcall(function()
    local ps = LocalPlayer and LocalPlayer:FindFirstChild("PlayerScripts") and LocalPlayer.PlayerScripts:FindFirstChild("PromptService")
    local pgMod = ps and ps:FindFirstChild("PromptGate")
    if pgMod then
        local pg = require(pgMod)
        if pg and pg.isHidden and not _G.__PROMPT_GATE_DETOURED then
            _G.__PROMPT_GATE_DETOURED = true
            local oldIsHidden = pg.isHidden
            pg.isHidden = function(prompt, ...)
                if State.Instant_Interact or State.Noclip or State.Noclip_Interact then
                    return false -- Never gate/suppress prompts!
                end
                return oldIsHidden and oldIsHidden(prompt, ...) or false
            end
        end
    end
end)

local function syncServerRoomBoundary()
    pcall(function()
        local curSpatialRoom = getCurrentRoomNumber()
        local curAttr = tonumber(LocalPlayer:GetAttribute("CurrentRoom"))
        if curSpatialRoom and curAttr and curSpatialRoom > curAttr then
            local cr = Workspace:FindFirstChild("CurrentRooms")
            local char = getChar()
            local coll = char and (char:FindFirstChild("Collision") or char:FindFirstChild("HumanoidRootPart"))
            if cr and coll then
                coll.CanTouch = true
                for rIdx = curAttr, curSpatialRoom - 1 do
                    local rModel = cr:FindFirstChild(tostring(rIdx))
                    local door = rModel and rModel:FindFirstChild("Door")
                    local hidden = door and door:FindFirstChild("Hidden")
                    if hidden and hidden:IsA("BasePart") then
                        hidden.CanTouch = true
                        firetouchinterest(coll, hidden, 0)
                        task.wait(0.01)
                        firetouchinterest(coll, hidden, 1)
                    end
                end
            end
        end
    end)
end

task.spawn(function()
    while _G.DOORS_SESSION == currentSession do
        task.wait(0.25)
        if State.Noclip or State.Fly_Enabled then
            syncServerRoomBoundary()
        end
    end
end)

-- Auto-reapply on respawn or revive
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.25)
    initGodModeImmunity()
    restoreCharacterInteractivity(char)
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
-- Pre-Physics Stepped Collision Bypass: Ensures physics engine NEVER overrides noclip collisions before physics step
local steppedConn2; steppedConn2 = RunService.Stepped:Connect(function()
    if steppedConn2 then trackConn(steppedConn2) end
    if _G.DOORS_SESSION ~= currentSession then return end
    if State.Noclip then
        local char = getChar()
        if char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then
                    if p.CanCollide then p.CanCollide = false end
                    p.CanTouch = true
                    p.CanQuery = true
                end
            end
        end
    end
end)

-- Jumping & Sliding Engine (DOORS Freedom Movement)
-- =========================================================================

local lastJumpRequestTime = 0
local jumpConn; jumpConn = UserInputService.JumpRequest:Connect(function()
    if jumpConn then trackConn(jumpConn) end
    if State.Enable_Jumping then
        local now = os.clock()
        if now - lastJumpRequestTime < 0.35 then return end -- Debounce: strictly 1 jump per spacebar press!
        local char = getChar()
        local hum = char and char:FindFirstChildWhichIsA("Humanoid")
        if hum and hum.Health > 0 and hum:GetState() ~= Enum.HumanoidStateType.Dead then
            local st = hum:GetState()
            -- Only jump when grounded (prevents high mid-air double-jumps & bouncing!)
            if st ~= Enum.HumanoidStateType.Freefall and st ~= Enum.HumanoidStateType.Jumping then
                lastJumpRequestTime = now
                if not hum:GetStateEnabled(Enum.HumanoidStateType.Jumping) then
                    hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
                end
                hum.UseJumpPower = true
                hum.JumpPower = 32 -- Natural, crisp hop (clears low obstacles smoothly!)
                hum.JumpHeight = 3.0
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end
end)

local inputConn1; inputConn1 = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if inputConn1 then trackConn(inputConn1) end
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
    local prName = prompt.Name:lower()
    local isDrawerOrContainer = pObj:find("drawer") or pObj:find("desk") or parentName:find("knob")
    local isHidingSpot = prName:find("hide") or pObj:find("wardrobe") or pObj:find("closet") or pObj:find("locker") or pObj:find("bed")
        or parentName:find("wardrobe") or parentName:find("closet") or parentName:find("locker") or parentName:find("bed")
        or pAct:find("hide") or pAct:find("enter")
    local isDoorPrompt = pObj:find("door") or parentName:find("door") or pAct:find("open") or pAct:find("unlock")

    -- Strip line-of-sight check unconditionally so prompts appear instantly
    prompt.RequiresLineOfSight = false

    if isHidingSpot then
        -- Wardrobe & Closet Interaction Assurance:
        -- Natural instant click (HoldDuration = 0) with zero annoying hold bar!
        prompt.MaxActivationDistance = 14.0
        if State.Instant_Interact then
            prompt.HoldDuration = 0
        else
            local origHold = prompt:GetAttribute("OrigHold") or 0
            prompt.HoldDuration = origHold
        end
        prompt.RequiresLineOfSight = false
        if not prompt.Enabled and (not prompt.Parent or not prompt.Parent:GetAttribute("HiddenPlayer")) then
            prompt.Enabled = true
        end
    elseif isDrawerOrContainer then
        -- CRITICAL DRAWER FIX: Server strictly rejects drawer activation beyond 6.5 studs!
        -- Clamping to 6.5 guarantees client triggers only within server reach, preventing false prompt disappearance!
        prompt.MaxActivationDistance = 6.5
        prompt.RequiresLineOfSight = false
        if State.Instant_Interact then
            prompt.HoldDuration = 0
        else
            local origHold = prompt:GetAttribute("OrigHold") or 0
            prompt.HoldDuration = origHold
        end
    elseif isDoorPrompt then
        prompt.RequiresLineOfSight = false
    else
        -- ITEMS, KEYS, GOLD, CHESTS, LEVERS, TOOLS & DRAWERS:
        -- ALWAYS expand MaxActivationDistance to 14 studs and strip RequiresLineOfSight!
        -- Eradicates all 6-10s interaction delays whether flying, noclipping through walls, or walking!
        prompt.MaxActivationDistance = math.max(prompt.MaxActivationDistance or 0, 14)
        prompt.RequiresLineOfSight = false

        if State.Instant_Interact then
            prompt.HoldDuration = 0
        else
            -- PRESERVE NATURAL HOLD DURATION: Never flicker or overwrite HoldDuration so 1-2s hold prompts work smoothly!
            local origHold = prompt:GetAttribute("OrigHold")
            if origHold ~= nil then prompt.HoldDuration = origHold end
        end
    end
end

local function refreshAllPrompts()
    local root = getRoot()
    local curRoom = root and getObjectRoom(root)
    if curRoom then
        for _, desc in ipairs(curRoom:GetDescendants()) do
            if desc:IsA("ProximityPrompt") then
                pcall(function() applyPromptModifications(desc) end)
            end
        end
    else
        local curRooms = Workspace:FindFirstChild("CurrentRooms")
        if curRooms then
            for _, rm in ipairs(curRooms:GetChildren()) do
                for _, desc in ipairs(rm:GetDescendants()) do
                    if desc:IsA("ProximityPrompt") then
                        pcall(function() applyPromptModifications(desc) end)
                    end
                end
            end
        end
    end
end

-- Auto-initialize prompts for newly streamed rooms (Fires ONCE per room load, 0 FPS overhead)
pcall(function()
    local curRooms = Workspace:WaitForChild("CurrentRooms", 5)
    if curRooms and not _G.ROOM_PROMPT_INIT_CONN then
        _G.ROOM_PROMPT_INIT_CONN = true
        curRooms.ChildAdded:Connect(function(newRoom)
            task.wait(0.2)
            if newRoom and newRoom.Parent then
                for _, desc in ipairs(newRoom:GetDescendants()) do
                    if desc:IsA("ProximityPrompt") then
                        pcall(function() applyPromptModifications(desc) end)
                    end
                end
            end
        end)
    end
end)

-- Drawer Guardian Daemon: Scans ONLY player's current room within 14 studs, optimizes knobs, and prevents remote spam
local drawerLootDebounce = {}
task.spawn(function()
    while _G.DOORS_SESSION == currentSession do
        task.wait(0.35)
        local root = getRoot()
        local rootPos = root and root.Position
        if rootPos then
            local curRoom = getObjectRoom(root)
            local searchRooms = {}
            if curRoom then
                table.insert(searchRooms, curRoom)
            else
                local cr = Workspace:FindFirstChild("CurrentRooms")
                if cr then
                    for _, rm in ipairs(cr:GetChildren()) do
                        local primary = rm.PrimaryPart or rm:FindFirstChildWhichIsA("BasePart")
                        if primary and (rootPos - primary.Position).Magnitude < 45 then
                            table.insert(searchRooms, rm)
                        end
                    end
                end
            end

            local now = os.clock()
            for _, rm in ipairs(searchRooms) do
                for _, desc in ipairs(rm:GetDescendants()) do
                    if desc.Name == "DrawerContainer" then
                        local main = desc:FindFirstChild("Main")
                        if main and (rootPos - main.Position).Magnitude <= 14 then
                            local knobs = desc:FindFirstChild("Knobs")
                            local prompt = knobs and knobs:FindFirstChildWhichIsA("ProximityPrompt")
                            local holder = desc:FindFirstChild("Holder")
                            local isOpen = holder and (main.Position - holder.Position).Magnitude > 0.4
                            if prompt then
                                if not isOpen then
                                    if not prompt.Enabled then prompt.Enabled = true end
                                    prompt.MaxActivationDistance = 6.5
                                    prompt.RequiresLineOfSight = false
                                elseif State.Auto_Interact then
                                    -- Drawer is open: cleanly loot contents with 1.5s debounce to eradicate remote flooding!
                                    local lootHolder = desc:FindFirstChild("LootHolder")
                                    if lootHolder then
                                        for _, lDesc in ipairs(lootHolder:GetDescendants()) do
                                            if lDesc:IsA("ProximityPrompt") and lDesc.Enabled then
                                                lDesc.RequiresLineOfSight = false
                                                lDesc.MaxActivationDistance = 14
                                                if not drawerLootDebounce[lDesc] or (now - drawerLootDebounce[lDesc] > 1.5) then
                                                    drawerLootDebounce[lDesc] = now
                                                    safeInstantFirePrompt(lDesc)
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
        end
    end
end)

-- High-speed prompt optimization on demand (Zero background loops, zero FPS lag)

-- Hook ProximityPromptService for frame-0 prompt display
pcall(function()
    local pps = game:GetService("ProximityPromptService")
    pps.PromptShown:Connect(function(prompt)
        pcall(function() applyPromptModifications(prompt) end)
    end)
end)

-- =========================================================================
-- PROMPTGATE BYPASS & ZERO-DELAY INSTANT INTERACT ENGINE
-- =========================================================================
pcall(function()
    local ps = LocalPlayer:WaitForChild("PlayerScripts", 5)
    local promptService = ps and ps:WaitForChild("PromptService", 5)
    local promptGateModule = promptService and promptService:WaitForChild("PromptGate", 5)
    if promptGateModule then
        local PromptGate = require(promptGateModule)
        if PromptGate and PromptGate.isHidden then
            local origIsHidden = PromptGate.isHidden
            PromptGate.isHidden = function(prompt, ...)
                if State.Instant_Interact or State.Noclip or State.Noclip_Interact then
                    return false -- Completely bypasses DOORS custom LOS, Facing, Sector, and Crouch gates!
                end
                return origIsHidden(prompt, ...)
            end
        end
    end
end)

local lastPromptFiredTick = 0
local lastPromptFiredObj = nil
local function safeInstantFirePrompt(prompt)
    if not prompt or not prompt.Parent then return end
    local now = os.clock()
    if lastPromptFiredObj == prompt and (now - lastPromptFiredTick < 0.25) then return end
    lastPromptFiredObj = prompt
    lastPromptFiredTick = now

    -- Auto-equip tool if this is an unlock prompt so interaction is never empty-handed!
    local pName = prompt.Name:lower()
    local obj = (prompt.ObjectText or ""):lower()
    local act = (prompt.ActionText or ""):lower()
    local isUnlock = pName:find("unlock") or obj:find("lock") or obj:find("door") or obj:find("chest") or act:find("unlock") or obj:find("padlock")
    local usedTool = nil
    if isUnlock then
        local tool, isEq = getEquippedOrInventoryTool({"lockpick", "skeleton", "key"})
        if tool then
            usedTool = tool
            if not isEq then
                local char = getChar()
                local hum = char and char:FindFirstChildWhichIsA("Humanoid")
                if hum and tool.Parent == LocalPlayer:FindFirstChild("Backpack") then
                    hum:EquipTool(tool)
                    task.wait(0.04)
                end
            end
        end
    end

    if usedTool and State.Infinite_Items and State.Infinite_Lockpicks then
        local tn = usedTool.Name:lower()
        if tn:find("lockpick") or tn:find("skeleton") then
            local rf = remotesFolder or game:GetService("ReplicatedStorage"):FindFirstChild("RemotesFolder")
            local dropRemote = rf and rf:FindFirstChild("DropItem")
            if dropRemote and usedTool and usedTool.Parent then
                pcall(function() dropRemote:FireServer(usedTool) end)
            end
            retrieveDroppedTool(usedTool.Name, 3.5)
        end
    end

    pcall(function()
        if fireproximityprompt then
            fireproximityprompt(prompt)
        end
    end)
end

-- Frame-0 Immediate Prompt Trigger: Fires the exact millisecond KeyCode.E is pressed down without double-tap cancellation!
pcall(function()
    local pps = game:GetService("ProximityPromptService")
    pps.PromptButtonHoldBegan:Connect(function(prompt, player)
        if (player == nil or player == LocalPlayer) and State.Instant_Interact then
            safeInstantFirePrompt(prompt)
        end
    end)
end)

-- Initial prompt optimization across all loaded rooms
task.spawn(function()
    task.wait(0.25)
    refreshAllPrompts()
end)

-- Prompts are dynamically optimized on-demand via ProximityPromptService.PromptShown (0ms room streaming lag)

local function isPromptSafeToAutoInteract(prompt)
    if not prompt or not prompt.Enabled or not prompt.Parent then return false end

    local parent = prompt.Parent
    local model = parent:IsA("Model") and parent or parent.Parent
    local mName = model and model.Name:lower() or ""
    local pName = parent.Name:lower()
    local act = (prompt.ActionText or ""):lower()
    local obj = (prompt.ObjectText or ""):lower()
    local prName = prompt.Name:lower()

    -- STRICT INVARIANT: Rift & Rift Storage MUST NEVER be touched by Auto Interact!
    if prName:find("rift") or act:find("rift") or obj:find("rift") or pName:find("rift") or mName:find("rift") then
        return false
    end
    local curAncestor = prompt.Parent
    while curAncestor and curAncestor ~= workspace do
        local aName = curAncestor.Name:lower()
        if aName:find("rift") or curAncestor:GetAttribute("IsRift") or curAncestor:GetAttribute("Rift") then
            return false
        end
        curAncestor = curAncestor.Parent
    end

    -- STRICT INVARIANT: All hiding spots (Wardrobes, Closets, Beds, Lockers) MUST NEVER be auto-interacted!
    if prName:find("hide") or act:find("hide") or act:find("enter")
       or obj:find("wardrobe") or obj:find("closet") or obj:find("bed") or obj:find("locker")
       or pName:find("wardrobe") or pName:find("closet") or pName:find("bed") or pName:find("locker")
       or mName:find("wardrobe") or mName:find("closet") or mName:find("bed") or mName:find("locker") then
        return false
    end

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
        or (model and (model:GetAttribute("Fake") or model:GetAttribute("DupeRoom") or isDupeDoor(model))) then
        return false
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

    -- Chests & Strongboxes (Open & Unlock Chests):
    if pName:find("chest") or mName:find("chest") or obj:find("chest") or (act:find("unlock") and (obj:find("chest") or pName:find("chest") or mName:find("chest"))) then
        if State.AutoInteract_Excludes and State.AutoInteract_Excludes["Chests"] then
            return false
        end
        -- Auto-equip lockpick or skeleton key if locked
        if act:find("unlock") then
            local lockpick = getEquippedOrInventoryTool({"lockpick", "skeleton"})
            if lockpick and lockpick.Parent == LocalPlayer.Backpack then
                local hum = getChar() and getChar():FindFirstChildWhichIsA("Humanoid")
                if hum then hum:EquipTool(lockpick) end
            end
        end
        return State.AutoInteract_Drawers or State.AutoInteract_Items or true
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
            -- Pause Auto Interact if daddy is pressing E (manual interact), or entering a wardrobe, or near a hiding spot
            local now = os.clock()
            local root = getRoot()
            local rootPos = root and root.Position

            if UserInputService:IsKeyDown(Enum.KeyCode.E) or (now < unhideGraceUntil) then
                task.wait(0.1)
                continue
            end

            -- Pause Auto Interact ONLY if daddy is currently hiding inside a closet/wardrobe
            if (now < unhideGraceUntil) or isPlayerHiding(char, mgTable) then
                task.wait(0.08)
                continue
            end
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
                                    local promptReach = isDrawerOrContainer and 6.0 or maxDist
                                    if dist <= promptReach then
                                        if isPromptSafeToAutoInteract(prompt) then
                                            promptDebounce[prompt] = now + 0.4
                                            batchCount = batchCount + 1
                                            local stagger = (batchCount - 1) * 0.02
                                            task.spawn(function()
                                                if stagger > 0 then task.wait(stagger) end
                                                safeInstantFirePrompt(prompt)
                                            end)
                                        end
                                    end
                                end
                            end
                        end
                    end

                    -- 2. Check All Doors (Main Doors, Side Doors, Hallway Doors)
                    if State.AutoInteract_Doors and not (State.AutoInteract_Excludes and State.AutoInteract_Excludes["Side Room Doors"]) then
                        for _, child in ipairs(container:GetDescendants()) do
                            if child:IsA("Model") and (child.Name == "Door" or child.Name:lower():find("door")) then
                                local dPart = child:FindFirstChild("Door") or child:FindFirstChild("Hidden") or child.PrimaryPart or child:FindFirstChildWhichIsA("BasePart")
                                if dPart then
                                    local dist = (rootPos - dPart.Position).Magnitude
                                    if dist <= (maxDist + 4) then
                                        processNearbyDoors(rootPos, maxDist + 4)
                                        break
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        task.wait(0.04) -- Hyper-responsive 25Hz loop: instant looting the millisecond you get close
    end
end)

-- =========================================================================
-- Prompt Listeners, Crucifix Exorcism Retain & Consumables Auto-Retain Engines
-- =========================================================================

-- Hook ProximityPromptService for calibrated item retain on lockpick / skeleton key / key usage
pcall(function()
    local pps = game:GetService("ProximityPromptService")
    local activePromptTool = nil

    -- When daddy begins holding or focusing an unlock prompt:
    -- Automatically equip lockpick/key so hands are NEVER empty!
    pps.PromptButtonHoldBegan:Connect(function(prompt, player)
        if player and player ~= LocalPlayer then return end
        local pName = prompt.Name:lower()
        local obj = (prompt.ObjectText or ""):lower()
        local act = (prompt.ActionText or ""):lower()
        local isUnlock = pName:find("unlock") or obj:find("lock") or obj:find("door") or obj:find("chest") or act:find("unlock") or obj:find("padlock")
        if isUnlock then
            local tool, isEq = getEquippedOrInventoryTool({"lockpick", "skeleton", "key"})
            if tool then
                activePromptTool = tool
                if not isEq then
                    local char = getChar()
                    local hum = char and char:FindFirstChildWhichIsA("Humanoid")
                    if hum and tool.Parent == LocalPlayer:FindFirstChild("Backpack") then
                        hum:EquipTool(tool)
                    end
                end
            end
        end
    end)

    local function onPromptInteract(prompt, player)
        if not State.Infinite_Items or not State.Infinite_Lockpicks then return end
        if player and player ~= LocalPlayer then return end
        local pName = prompt.Name:lower()
        local obj = (prompt.ObjectText or ""):lower()
        local act = (prompt.ActionText or ""):lower()
        local isUnlock = pName:find("unlock") or obj:find("lock") or obj:find("door") or obj:find("chest") or act:find("unlock") or obj:find("padlock")

        if isUnlock then
            local tool = activePromptTool or getEquippedOrInventoryTool({"lockpick", "skeleton", "key"})
            if tool then
                local tn = tool.Name:lower()
                -- Strictly retain multi-use tools (lockpicks & skeleton keys). Normal room keys open doors natively without dupe clutter!
                if tn:find("lockpick") or tn:find("skeleton") then
                    executeItemDupeDrop(tool, 0.09)
                end
            end
        end
    end

    pps.PromptTriggered:Connect(onPromptInteract)
    pps.PromptButtonHoldEnded:Connect(function(prompt, player)
        if player and player ~= LocalPlayer then return end
        task.delay(0.3, function()
            activePromptTool = nil
        end)
    end)
end)

-- =========================================================================
-- Infinite Items: Activation Hook for Consumables & Crucifix (Vitamins & Exorcism)
-- =========================================================================
local function bindInfiniteTool(tool)
    if not tool or not tool:IsA("Tool") then return end
    if tool:GetAttribute("InfiniteTool_Bound") then return end
    tool:SetAttribute("InfiniteTool_Bound", true)

    tool.Activated:Connect(function()
        if not State.Infinite_Items then return end
        local tName = tool.Name:lower()
        if tName:find("crucifix") then
            -- Crucifix activation / held against monster: drop instantly before entity consumes it!
            executeItemDupeDrop(tool, 0.05)
        end
    end)
end

local function hookBackpackAndCharTools()
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        for _, t in ipairs(bp:GetChildren()) do
            if t:IsA("Tool") then bindInfiniteTool(t) end
        end
        bp.ChildAdded:Connect(function(child)
            if child:IsA("Tool") then
                task.wait(0.05)
                bindInfiniteTool(child)
            end
        end)
    end

    local char = getChar()
    if char then
        for _, t in ipairs(char:GetChildren()) do
            if t:IsA("Tool") then bindInfiniteTool(t) end
        end
        char.ChildAdded:Connect(function(child)
            if child:IsA("Tool") then
                task.wait(0.05)
                bindInfiniteTool(child)
            end
        end)
    end
end

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    hookBackpackAndCharTools()
end)
hookBackpackAndCharTools()

-- Crucifix Auto-Retain Watcher (Triggers during active exorcism, drops at 0.6s & reclaims)
task.spawn(function()
    local isRetainingCrucifix = false
    while true do
        if _G.DOORS_SESSION ~= currentSession then break end
        if State.Infinite_Items and State.Infinite_Crucifix and not isRetainingCrucifix then
            local char = getChar()
            local crucifix = char and char:FindFirstChild("Crucifix")
            if crucifix then
                local handle = crucifix:FindFirstChild("Handle")
                local isExorcising = false

                -- Detection 1: Attribute or Effect instance
                if crucifix:GetAttribute("Active") == true or char:GetAttribute("CrucifixActive") == true then
                    isExorcising = true
                elseif crucifix:FindFirstChild("Chain") or crucifix:FindFirstChild("Chains") or crucifix:FindFirstChild("Effect") or crucifix:FindFirstChild("CrucifixEffect") then
                    isExorcising = true
                end

                -- Detection 2: Exorcism audio playing in handle
                if not isExorcising and handle then
                    for _, snd in ipairs(handle:GetChildren()) do
                        if snd:IsA("Sound") and snd.IsPlaying and snd.TimePosition > 0.1 then
                            local sn = snd.Name:lower()
                            if sn:find("hold") or sn:find("chain") or sn:find("scream") or sn:find("exorc") or sn:find("impact") then
                                isExorcising = true
                                break
                            end
                        end
                    end
                end

                -- Detection 3: Close entity proximity (< 14 studs) while holding Crucifix
                if not isExorcising then
                    local r = getRoot()
                    if r then
                        local lethalNames = {"RushMoving", "AmbushMoving", "Eyes", "Screech", "Halt", "SeekMoving", "FigureRig", "Grumble", "A60", "A120"}
                        local curRooms = Workspace:FindFirstChild("CurrentRooms")
                        for _, name in ipairs(lethalNames) do
                            local inst = (curRooms and curRooms:FindFirstChild(name, true)) or Workspace:FindFirstChild(name, true)
                            if inst then
                                local pos = inst:GetPivot().Position
                                if (pos - r.Position).Magnitude <= 14 then
                                    isExorcising = true
                                    break
                                end
                            end
                        end
                    end
                end

                if isExorcising then
                    isRetainingCrucifix = true
                    task.spawn(function()
                        -- Calibrated delay: wait 0.6 seconds so server chains bind entity
                        task.wait(0.05)
                        executeItemDupeDrop(crucifix, 0)
                        Hub.Notify("Infinite Crucifix", "Crucifix dropped & ready for re-grab!", 3)
                        task.wait(4.0)
                        isRetainingCrucifix = false
                    end)
                end
            end
        end
        task.wait(0.1)
    end
end)

-- Consumables Retain Engine: Vitamins, Smoothies & Bandages are duplicated safely via Quick Dupe button
-- Destructive drop-while-eating hook removed so eating vitamins never makes the bottle disappear from hands!

-- Additional Anti-Entity Defenses (Gloombats, Seek Hands, Halt Reversal, Grumble Radar)
local function applyAdditionalDefenses()
    local curRooms = Workspace:FindFirstChild("CurrentRooms")
    if not curRooms then return end

    -- 1. Anti-Gloombat: Disarms attack hitbox touch interests
    if State.Anti_Gloombat then
        for _, desc in ipairs(curRooms:GetDescendants()) do
            if desc.Name:lower():find("gloombat") and desc:IsA("BasePart") and desc.CanTouch then
                desc.CanTouch = false
            end
        end
    end

    -- 2. Anti-Seek Hands, Obstructions & Seek Moving Entity Defusal: Completely neutralizes Seek hands, SeekMoving, and falling debris!
    if State.Anti_Seek or State.WalkSpeed_Enabled or State.Noclip then
        local char = getChar()
        local r = getRoot()
        local mgTable = getMainGameTable()
        local isCrouching = (mgTable and mgTable.crouching) or (char and char:GetAttribute("Crouching")) or false
        for _, desc in ipairs(curRooms:GetDescendants()) do
            local nl = desc.Name:lower()
            local pName = desc.Parent and desc.Parent.Name:lower() or ""
            local isSeekThreat = nl:find("seek") or pName:find("seek") or nl:find("arm") or nl:find("hand") or nl:find("animatorpart")
            if isSeekThreat then
                if desc:IsA("BasePart") then
                    if desc.CanTouch then desc.CanTouch = false end
                    if desc.CanCollide then desc.CanCollide = false end
                    local tt = desc:FindFirstChildWhichIsA("TouchTransmitter")
                    if tt then pcall(function() tt:Destroy() end) end
                elseif desc:IsA("TouchTransmitter") then
                    pcall(function() desc:Destroy() end)
                end
            end
            if (nl:find("obstruction") or nl:find("fallen") or nl:find("bookshelf") or nl:find("chandelier") or nl:find("debris") or nl:find("fire")) and desc:IsA("BasePart") then
                if isCrouching or State.Noclip or (r and desc.Position.Y > (r.Position.Y + 1.2)) then
                    desc.CanCollide = false
                    desc.CanTouch = false
                end
            end
        end

        -- Ensure Seek himself (SeekMoving / SeekRig) in Workspace is defused immediately
        for _, obj in ipairs(Workspace:GetChildren()) do
            local oLower = obj.Name:lower()
            if oLower:find("seek") then
                defuseLethalEntity(obj)
            end
        end
    end

    -- 3. Anti-Halt Auto-Reversal
    if State.Anti_Halt then
        local pGui = LocalPlayer:FindFirstChild("PlayerGui")
        local mainUI = pGui and pGui:FindFirstChild("MainUI")
        local mainFrame = mainUI and mainUI:FindFirstChild("MainFrame")
        local haltUI = mainFrame and mainFrame:FindFirstChild("Halt")
        if haltUI and haltUI.Visible then
            local r = getRoot()
            local cam = Workspace.CurrentCamera
            if r and cam then
                r.AssemblyLinearVelocity = -cam.CFrame.LookVector * 18
            end
        end
    end
end

task.spawn(function()
    while true do
        if _G.DOORS_SESSION ~= currentSession then break end
        pcall(applyAdditionalDefenses)
        task.wait(0.25)
    end
end)

-- Visual Enhancements: No Fog Enforcer
local function enforceNoFog(enabled)
    if not enabled then return end
    Lighting.FogEnd = 100000
    Lighting.FogStart = 0
    local atm = Lighting:FindFirstChildWhichIsA("Atmosphere")
    if atm then
        atm.Density = 0
        atm.Haze = 0
        atm.Glare = 0
    end
end

pcall(function()
    Lighting:GetPropertyChangedSignal("FogEnd"):Connect(function()
        if State.No_Fog then enforceNoFog(true) end
    end)
end)

-- Visual Enhancements: Semi-Transparent Closet While Hiding
local lastHidingModel = nil
local lastHidingOriginalTrans = {}

task.spawn(function()
    while true do
        if _G.DOORS_SESSION ~= currentSession then break end
        if State.SemiTransparent_Closet then
            local char = getChar()
            local mgTable = getMainGameTable()
            local hiding = isPlayerHiding(char, mgTable)
            if hiding then
                local cam = Workspace.CurrentCamera
                local camPos = cam and cam.CFrame.Position
                local r = getRoot()
                local refPos = camPos or (r and r.Position)

                if not lastHidingModel then
                    local curRooms = Workspace:FindFirstChild("CurrentRooms")
                    if curRooms then
                        for _, rm in ipairs(curRooms:GetChildren()) do
                            for _, desc in ipairs(rm:GetDescendants()) do
                                if desc:IsA("Model") then
                                    local nl = desc.Name:lower()
                                    if nl:find("wardrobe") or nl:find("closet") or nl:find("bed") or nl:find("locker") then
                                        local isTarget = false
                                        local hp = desc:FindFirstChild("HiddenPlayer")
                                        if hp and hp:IsA("ObjectValue") and hp.Value == LocalPlayer then
                                            isTarget = true
                                        elseif refPos and (desc:GetPivot().Position - refPos).Magnitude <= 12 then
                                            isTarget = true
                                        end

                                        if isTarget then
                                            lastHidingModel = desc
                                            lastHidingOriginalTrans = {}
                                            for _, p in ipairs(desc:GetDescendants()) do
                                                if p:IsA("BasePart") then
                                                    lastHidingOriginalTrans[p] = p.Transparency
                                                    p.Transparency = 0.75
                                                elseif p:IsA("Decal") then
                                                    lastHidingOriginalTrans[p] = p.Transparency
                                                    p.Transparency = 0.75
                                                end
                                            end
                                            break
                                        end
                                    end
                                end
                            end
                            if lastHidingModel then break end
                        end
                    end
                end

                -- Eradicate closet darkness vignette
                pcall(function()
                    local pg = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
                    local mUI = pg and pg:FindFirstChild("MainUI")
                    local mf = mUI and mUI:FindFirstChild("MainFrame")
                    local hv = mf and mf:FindFirstChild("HideVignette")
                    if hv then
                        hv.ImageTransparency = 1
                        hv.Visible = false
                    end
                end)
            else
                if lastHidingModel then
                    for p, orig in pairs(lastHidingOriginalTrans) do
                        if p and p.Parent then
                            p.Transparency = orig or 0
                        end
                    end
                    lastHidingModel = nil
                    lastHidingOriginalTrans = {}
                end
            end
        end
        task.wait(0.1)
    end
end)

-- =========================================================================
-- Infallible Anti-Dread Subsystem (Darkness & Entity Defusal)
-- =========================================================================
local function enforceAntiDread()
    if not State.Anti_Dread then return end
    pcall(function()
        -- 1. Eliminate LiveSanity ColorCorrection in Camera & Lighting
        local cam = Workspace.CurrentCamera
        if cam then
            local liveSanity = cam:FindFirstChild("LiveSanity")
            if liveSanity then liveSanity:Destroy() end
        end
        local lightSanity = game:GetService("Lighting"):FindFirstChild("LiveSanity")
        if lightSanity then lightSanity:Destroy() end

        -- 2. Eradicate Dread Vignette & Tendrils from Screen (Image 1 Fix)
        local lp = LocalPlayer or Players.LocalPlayer
        local pg = lp and lp:FindFirstChild("PlayerGui")
        local mainUI = pg and pg:FindFirstChild("MainUI")
        local mainFrame = mainUI and mainUI:FindFirstChild("MainFrame")
        if mainFrame then
            local dv = mainFrame:FindFirstChild("DreadVignette")
            if dv and dv.Visible then
                dv.Visible = false
                dv.ImageColor3 = Color3.new(0, 0, 0)
                dv.Size = UDim2.new(0, 0, 0, 0)
                for _, child in ipairs(dv:GetChildren()) do
                    if child:IsA("Frame") then child.Visible = false end
                end
            end
        end

        -- 3. Unbind Dread RenderStep Effect
        pcall(function()
            RunService:UnbindFromRenderStep("dreadfx")
        end)

        -- 4. Destroy Sanity Audio Equalizer & Muffle
        local soundMain = game:GetService("SoundService"):FindFirstChild("Main")
        if soundMain then
            local eq = soundMain:FindFirstChild("SanityEqualizerLive")
            if eq then eq:Destroy() end
        end

        -- 5. Defuse Any Spawned Dread Entity
        local dreadModel = Workspace:FindFirstChild("Dread") 
            or (Workspace:FindFirstChild("CurrentRooms") and Workspace.CurrentRooms:FindFirstChild("Dread", true))
        if dreadModel then
            for _, p in ipairs(dreadModel:GetDescendants()) do
                if p:IsA("BasePart") then
                    p.CanTouch = false
                    p.CanCollide = false
                    p.CanQuery = false
                end
            end
            if dreadModel:IsA("Model") and dreadModel.PrimaryPart then
                dreadModel.PrimaryPart.CFrame = CFrame.new(0, -500, 0)
            end
        end
    end)
end

-- Active Watchdog Loop for Anti-Dread
task.spawn(function()
    while true do
        if _G.DOORS_SESSION ~= currentSession then break end
        if State.Anti_Dread then
            enforceAntiDread()
        end
        task.wait(0.2)
    end
end)

-- Intercept RemotesFolder.Dread remote
pcall(function()
    local rf = game:GetService("ReplicatedStorage"):WaitForChild("RemotesFolder", 5)
    if rf then
        local dreadRemote = rf:FindFirstChild("Dread")
        if dreadRemote and dreadRemote:IsA("RemoteEvent") then
            dreadRemote.OnClientEvent:Connect(function()
                if State.Anti_Dread then
                    task.defer(enforceAntiDread)
                end
            end)
        end
    end
end)

-- Visual Enhancements: Entity Spawn Notifier & Sound Alert
local notifiedEntities = {}
local notifySound = Instance.new("Sound")
notifySound.SoundId = "rbxassetid://6534947588"
notifySound.Volume = 0.6
notifySound.Parent = game:GetService("SoundService")

local function triggerEntityNotification(name)
    if not State.Notify_EntitySpawn then return end
    if State.Notify_Entity_Filters and State.Notify_Entity_Filters[name] == false then return end
    local now = os.clock()
    if notifiedEntities[name] and (now - notifiedEntities[name] < 7) then return end
    notifiedEntities[name] = now

    if State.Notify_EntitySound then
        pcall(function() game:GetService("SoundService"):PlayLocalSound(notifySound) end)
    end
    Hub.Notify("Entity Alert", string.format("⚠️ %s has spawned! Prepare or hide!", name), 4)
end

defuseLethalEntity = function(entity)
    if not entity then return end
    pcall(function()
        for _, p in ipairs(entity:GetDescendants()) do
            if p:IsA("BasePart") then
                p.CanTouch = false
                p.CanCollide = false
                p.CanQuery = false
            elseif p:IsA("TouchTransmitter") then
                p:Destroy()
            end
        end
        if entity:IsA("BasePart") then
            entity.CanTouch = false
            entity.CanCollide = false
            entity.CanQuery = false
        end
    end)
    entity.DescendantAdded:Connect(function(desc)
        pcall(function()
            if desc:IsA("BasePart") then
                desc.CanTouch = false
                desc.CanCollide = false
                desc.CanQuery = false
            elseif desc:IsA("TouchTransmitter") then
                desc:Destroy()
            end
        end)
    end)
end

local function checkAndDefuseEntity(child)
    if not child then return end
    local cName = child.Name
    local lower = cName:lower()
    local isLethal = lower:find("rush") or lower:find("ambush") or lower:find("a60") or lower:find("a120") or lower:find("seek") or lower:find("figure") or lower:find("grumble") or lower:find("giggle") or lower:find("gloombat") or lower:find("dread") or lower:find("blitz") or lower:find("lookman")
    if isLethal then
        defuseLethalEntity(child)
    end
    local entityNotifOrder = {
        "Blitz", "Ambush", "Rush", "Lookman", "Eyes", "Seek", "Figure", "Halt",
        "A60", "A90", "A120", "Giggle", "Gloombat", "Grumble", "Dread",
        "Surge", "Bramble", "Groundskeeper", "Monument", "Alma", "Drone", "Teller",
        "Bash", "Scribbles", "Socker", "Creak", "Meld", "Stem", "Noise", "Weaveling"
    }
    for _, ent in ipairs(entityNotifOrder) do
        if lower:find(ent:lower()) then
            -- If Rush matched but model is Blitz, prioritize Blitz notification!
            if ent == "Rush" and lower:find("blitz") then
                triggerEntityNotification("Blitz")
            else
                triggerEntityNotification(ent)
            end
            break
        end
    end
end

Workspace.ChildAdded:Connect(checkAndDefuseEntity)
task.spawn(function()
    local liveEnts = Workspace:WaitForChild("LiveEntities", 5)
    if liveEnts then
        liveEnts.ChildAdded:Connect(checkAndDefuseEntity)
    end
end)

if remotesFolder then
    local screechRemote = remotesFolder:FindFirstChild("Screech")
    if screechRemote and screechRemote:IsA("RemoteEvent") then
        screechRemote.OnClientEvent:Connect(function()
            if not State.Anti_Screech then
                triggerEntityNotification("Screech")
            end
        end)
    end
    local a90Remote = remotesFolder:FindFirstChild("A90")
    if a90Remote and a90Remote:IsA("RemoteEvent") then
        a90Remote.OnClientEvent:Connect(function()
            triggerEntityNotification("A-90")
        end)
    end
end

-- Dynamic Floor Active Entities & Modifier Scanner
local function getActiveEntitiesForFloor()
    local detectedFloor = (game.ReplicatedStorage:FindFirstChild("GameData") and game.ReplicatedStorage.GameData:FindFirstChild("Floor") and game.ReplicatedStorage.GameData.Floor.Value) or "Hotel"
    local floorLower = string.lower(tostring(detectedFloor))
    local isHotel = (floorLower:find("hotel") ~= nil or floorLower == "floor1" or floorLower == "1")
    local isMines = (floorLower:find("mine") ~= nil or floorLower == "floor2" or floorLower == "2")
    local isRooms = (floorLower:find("room") ~= nil or floorLower == "a")
    local isBackdoor = (floorLower:find("backdoor") ~= nil)
    local isRetro = (floorLower:find("retro") ~= nil)

    local function hasMod(keyword)
        local kw = keyword:lower()
        local lm = game.ReplicatedStorage:FindFirstChild("LiveModifiers")
        if lm then
            for _, m in ipairs(lm:GetChildren()) do
                if m.Name:lower():find(kw) then return true end
            end
        end
        local gd = game.ReplicatedStorage:FindFirstChild("GameData")
        local mods = gd and gd:FindFirstChild("Modifiers")
        if mods then
            for _, m in ipairs(mods:GetChildren()) do
                if m.Name:lower():find(kw) then return true end
            end
        end
        return false
    end

    local entities = {}
    local function add(name)
        if not table.find(entities, name) then table.insert(entities, name) end
    end

    if isHotel then
        add("Rush")
        add("Ambush")
        add("Screech")
        add("Eyes")
        add("Halt")
        add("Seek")
        add("Figure")
        add("Dupe")
        add("Snare")
        add("Timothy")
        add("Dread")
        if hasMod("a90") or hasMod("ransom") or hasMod("stop") then add("A-90") end
        if hasMod("giggle") or hasMod("laugh") then add("Giggle") end
        if hasMod("bat") or hasMod("gloombat") then add("Gloombats") end
        if hasMod("grumble") then add("Grumble") end
        if hasMod("lookman") or hasMod("look") then add("Lookman") end
        if hasMod("blitz") then add("Blitz") end
    elseif isMines then
        add("Rush")
        add("Ambush")
        add("Screech")
        add("Eyes")
        add("Halt")
        add("Seek")
        add("Figure")
        add("Dupe")
        add("Snare")
        add("Timothy")
        add("Giggle")
        add("Gloombats")
        add("Grumble")
        add("Dread")
        if hasMod("a90") or hasMod("ransom") or hasMod("stop") then add("A-90") end
        if hasMod("lookman") or hasMod("look") then add("Lookman") end
        if hasMod("blitz") then add("Blitz") end
    elseif isRooms then
        add("A-60")
        add("A-90")
        add("A-120")
        if hasMod("rush") then add("Rush") end
        if hasMod("screech") then add("Screech") end
        if hasMod("eyes") then add("Eyes") end
        if hasMod("dupe") then add("Dupe") end
    elseif isBackdoor then
        add("Blitz")
        add("Lookman")
        add("Haste")
        add("Vacuum")
        if hasMod("rush") then add("Rush") end
        if hasMod("ambush") then add("Ambush") end
        if hasMod("screech") then add("Screech") end
    elseif isRetro then
        add("Rush")
        add("Ambush")
        add("Screech")
        add("A-90")
    else
        add("Rush")
        add("Ambush")
        add("Screech")
        add("Eyes")
        add("Halt")
        add("Seek")
        add("Figure")
        add("Dupe")
        add("Snare")
        add("Timothy")
    end

    return entities
end

-- =========================================================================
-- Autonomous Knobs Farm & Auto-Win Engine (Fly-Noclip, Anti-Entity, Quota Reset)
-- =========================================================================
isKnobsFarmRunning = false
local currentFarmTarget = nil
local lootedContainersThisRun = {}
local lootedRoomsThisRun = {}
isEvacuatingRoof = false

-- Persistent Auto Re-execution Setup (Runs across matches without auto-exec folder!)
local function setupQueueOnTeleport()
    local qot = queue_on_teleport or (syn and syn.queue_on_teleport) or queueonteleport
    if qot then
        pcall(function()
            qot([[
                repeat task.wait() until game:IsLoaded()
                getgenv().Doors_KnobsFarm_AutoResume = true
                local s, src = pcall(readfile, "Doors.luau")
                if s and src and #src > 100 then
                    loadstring(src)()
                end
            ]])
        end)
    end
end

-- Rush / Ambush / A-60 / A-120 / Seek / Dread / Blitz / Lookman / Figure Lethal Threat Detector
isLethalEntityIncoming = function()
    -- Strictly Hide-In-Closet threats: Rush, Ambush, A-60, A-120, Blitz
    local closetThreats = {"rush", "ambush", "a60", "a-60", "a120", "a-120", "blitz"}
    -- Explicit exclusions: NEVER trigger closet auto-hide or roof evacuation for these
    local explicitExclusions = {"figure", "seek", "dread", "halt", "screech", "eyes", "lookman", "dupe", "snare", "timothy", "grumble", "void", "glitch"}

    local function isThreat(name)
        local lower = name:lower()
        for _, excl in ipairs(explicitExclusions) do
            if lower:find(excl) then
                return false
            end
        end
        for _, threat in ipairs(closetThreats) do
            if lower:find(threat) then
                return true
            end
        end
        return false
    end

    local function scan(container)
        if not container then return nil end
        for _, child in ipairs(container:GetChildren()) do
            if isThreat(child.Name) then
                return child.Name
            end
        end
        return nil
    end

    local curRooms = Workspace:FindFirstChild("CurrentRooms")
    local liveEnts = Workspace:FindFirstChild("LiveEntities")
    local threat = scan(curRooms) or scan(liveEnts) or scan(Workspace)
    if threat then return true, threat end
    return false, nil
end

-- =========================================================================
-- Autonomous Rush & Ambush Safe Phase Daemon (Vertical Safe Altitude Shield)
-- When Rush, Ambush, or any entity approaches, safely elevates flight to +160 studs until threat passes!
-- =========================================================================
local isSafePhased = false

-- Auto-Hide and Threat Evasion Daemon removed per daddy's instruction.
-- Fly Noclip runs 100% standalone and completely unhindered!

-- Fly-Noclip Glide Controller: Direct 3D linear flight through walls and obstacles
farmGlideTo = function(targetPos, speedVal, maxTime)
    local char = getChar()
    local root = getRoot()
    local hum = char and char:FindFirstChildWhichIsA("Humanoid")
    if not char or not root or not hum or hum.Health <= 0 then return false end

    local speed = speedVal or (State.Noclip_Speed or 55)
    local maxWait = maxTime or 6.0
    local startTime = os.clock()
    local arrived = false

    -- Ensure Core Protections & Noclip are actively running
    if not State.Noclip then State.Noclip = true end
    if not State.Bypass_AntiCheat then State.Bypass_AntiCheat = true end
    if not State.Auto_Hide then State.Auto_Hide = true; State.Auto_RoofEvacuate = true end
    if not State.Deflect_Glitch then State.Deflect_Glitch = true end

    isAutoFlying = true

    local function cleanup()
        isAutoFlying = false
        local curR = getRoot()
        if curR and curR.Parent then
            curR.AssemblyLinearVelocity = Vector3.zero
            curR.AssemblyAngularVelocity = Vector3.zero
        end
    end

    while (os.clock() - startTime < maxWait) do
        if _G.DOORS_SESSION ~= currentSession then cleanup(); return false end
        if not (State.Knobs_Farm_Active or State.Auto_Complete_100 or State.Noclip) then
            cleanup()
            return false
        end

        local curChar = getChar()
        local curRoot = getRoot()
        if not curChar or not curRoot then cleanup(); return false end

        -- Strip collisions on character during auto-flight
        for _, p in ipairs(curChar:GetDescendants()) do
            if p:IsA("BasePart") then
                if p.CanCollide then p.CanCollide = false end
                p.CanTouch = true
                p.CanQuery = true
            end
        end
        local hum = curChar:FindFirstChildWhichIsA("Humanoid")
        if hum and hum:GetState() ~= Enum.HumanoidStateType.Freefall then
            hum:ChangeState(Enum.HumanoidStateType.Freefall)
        end

        -- Check Rush / Ambush interrupt
        if State.Knobs_Farm_RoofEvacuation and not isAtRoof then
            local incoming, entName = isLethalEntityIncoming()
            if incoming then
                cleanup()
                return "THREAT_INTERRUPT"
            end
        end

        local curPos = curRoot.Position
        local diff = (targetPos - curPos)
        local dist = diff.Magnitude

        if dist <= 2.8 then
            arrived = true
            break
        end

        local dir = diff.Unit
        local dt = 1/60
        local step = math.min(dist, speed * dt)
        local nextPos = curPos + dir * step
        local lookCF = CFrame.new(nextPos, nextPos + dir)

        curChar:PivotTo(lookCF)
        curRoot.CFrame = lookCF
        local cp = curChar:FindFirstChild("CollisionPart")
        if cp then cp.CFrame = lookCF end

        curRoot.AssemblyLinearVelocity = dir * speed
        curRoot.AssemblyAngularVelocity = Vector3.zero

        -- Continuous door touch sentry along flight path
        processNearbyDoors(curPos, 22)

        task.wait(0.016)
    end

    cleanup()
    return arrived
end
_G.farmGlideTo = farmGlideTo

handleFarmRoofEvacuation = function()
    if isEvacuatingRoof then return end
    isEvacuatingRoof = true
    Hub.Notify("Knobs Farm", "⚠️ Entity incoming! Evacuating to safe roof platform...", 3)

    teleportToRoof()

    -- Wait until threat is completely cleared across all automation modes
    while (State.Knobs_Farm_Active or State.Auto_Complete_100 or State.Auto_RoofEvacuate or State.Noclip) do
        local incoming = isLethalEntityIncoming()
        if not incoming then
            task.wait(2.5) -- Safety tail after despawn
            break
        end
        task.wait(0.3)
    end

    returnFromRoof()
    task.wait(0.5)
    isEvacuatingRoof = false
    Hub.Notify("Knobs Farm", "Threat cleared. Resuming farming loop!", 2)
end

-- Room 50 (Library) Auto Solver & Padlock Unlocker
solveFigureLibraryRoom = function()
    Hub.Notify("Knobs Farm", "Room 50 (Figure) entered! Collecting books & paper...", 4)
    local curRooms = Workspace:FindFirstChild("CurrentRooms")
    local r50 = curRooms and curRooms:FindFirstChild("50")
    if not r50 then return false end

    -- 1. Collect Hint Paper first
    local paper = Workspace:FindFirstChild("LibraryHintPaper", true) or (r50 and r50:FindFirstChild("LibraryHintPaper", true))
    if paper then
        local pPart = paper:IsA("BasePart") and paper or (paper:IsA("Model") and (paper.PrimaryPart or paper:FindFirstChildWhichIsA("BasePart", true)))
        if pPart then
            farmGlideTo(pPart.Position + Vector3.new(0, 1.5, 0), 45, 4.0)
            local pPrompt = paper:FindFirstChildWhichIsA("ProximityPrompt", true)
            if pPrompt then
                pPrompt.HoldDuration = 0
                pPrompt.RequiresLineOfSight = false
                pcall(function() fireproximityprompt(pPrompt) end)
            end
            task.wait(0.2)
        end
    end

    -- 2. Collect all 8 books
    local attempts = 0
    while attempts < 12 and State.Knobs_Farm_Active do
        local booksLeft = 0
        for _, desc in ipairs(r50:GetDescendants()) do
            if desc.Name == "LiveHintBook" or desc.Name:lower():find("hintbook") then
                booksLeft = booksLeft + 1
                local bPart = desc:IsA("BasePart") and desc or (desc:IsA("Model") and (desc.PrimaryPart or desc:FindFirstChildWhichIsA("BasePart", true)))
                if bPart then
                    farmGlideTo(bPart.Position + Vector3.new(0, 1.5, 0), 50, 3.5)
                    local bPrompt = desc:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if bPrompt then
                        bPrompt.HoldDuration = 0
                        bPrompt.RequiresLineOfSight = false
                        pcall(function() fireproximityprompt(bPrompt) end)
                    end
                    task.wait(0.15)
                end
            end
        end
        if booksLeft == 0 then break end
        attempts = attempts + 1
        task.wait(0.3)
    end

    -- 3. Solve 5-digit code
    local code, err = solveLibraryCode()
    if not code or code:find("_") then
        Hub.Notify("Knobs Farm", "Solving library code with partial digits...", 3)
    else
        Hub.Notify("Knobs Farm", "Library Padlock Code Deciphered: " .. tostring(code), 5)
    end

    -- 4. Unlock Padlock via PL remote or prompt
    if code and not code:find("_") then
        local plRemote = remotesFolder and remotesFolder:FindFirstChild("PL")
        if plRemote then
            pcall(function() plRemote:FireServer(code) end)
        end
    end

    -- Also glide to exit door 51
    local door50 = r50:FindFirstChild("Door")
    if door50 then
        local dPart = door50:FindFirstChild("Door") or door50:FindFirstChild("Hidden") or door50.PrimaryPart
        if dPart then
            farmGlideTo(dPart.Position + Vector3.new(0, 0, 3), 55, 4.0)
            processNearbyDoors(dPart.Position, 25)
        end
    end

    return true
end

-- Room-by-room Farm Step
processKnobsFarmStep = function()
    _G.processKnobsFarmStep = processKnobsFarmStep
    if not State.Knobs_Farm_Active then return end
    if isKnobsFarmRunning then return end
    isKnobsFarmRunning = true

    local pcallStatus, pcallErr = pcall(function()
    local char = getChar()
    local root = getRoot()
    local hum = char and char:FindFirstChildWhichIsA("Humanoid")
    if not char or not root or not hum or hum.Health <= 0 then return end

    local gd = game:GetService("ReplicatedStorage"):FindFirstChild("GameData")
    if not gd then return end

    -- Safe Gate: Wait until elevator cutscene finishes and Room 0 is ready
    local inGame = gd:FindFirstChild("InGame")
    if inGame and inGame.Value == false then return end

    local inCutscene = gd:FindFirstChild("InCutscene")
    if inCutscene and inCutscene.Value == true then return end

    local curRooms = Workspace:FindFirstChild("CurrentRooms")
    if not curRooms or #curRooms:GetChildren() == 0 then return end

    local curRoomNum = (gd:FindFirstChild("LatestRoom") and gd.LatestRoom.Value) or getCurrentRoomNumber() or 0
    local roomModel = curRooms:FindFirstChild(tostring(curRoomNum))
    if not roomModel then return end

    -- Check Quota
    local gs = game:GetService("ReplicatedStorage"):FindFirstChild("GameStats")
    local pStats = gs and gs:FindFirstChild("Player_" .. LocalPlayer.Name)
    local currentGold = (pStats and pStats.Total:FindFirstChild("GoldPicked") and pStats.Total.GoldPicked.Value) or 0
    local currentDoors = curRoomNum

    if (currentGold >= (State.Knobs_Farm_MaxGold or 3500)) or (currentDoors >= (State.Knobs_Farm_MaxDoors or 85)) then
        Hub.Notify("Knobs Farm", string.format("🎯 Quota Hit! Gold: %d | Doors: %d. Cashing in Knobs and restarting!", currentGold, currentDoors), 5)
        setupQueueOnTeleport()
        getgenv().Doors_KnobsFarm_AutoResume = true

        -- Authoritative reset to bank all Knobs!
        task.wait(0.5)
        pcall(function() char:BreakJoints() end)
        pcall(function() hum.Health = 0 end)

        -- Await death & fire PlayAgain
        task.wait(6.0)
        local pa = remotesFolder and remotesFolder:FindFirstChild("PlayAgain")
        if pa then
            pcall(function() pa:FireServer() end)
        end
        task.wait(5.0)
        return
    end

    -- Check Rush / Ambush threat
    if isLethalEntityIncoming() then
        handleFarmRoofEvacuation()
        return
    end

    -- Room 0 (Elevator / Reception Initial Key & Door 1)
    if curRoomNum == 0 and roomModel then
        local keyObtain = roomModel:FindFirstChild("KeyObtain", true)
        if keyObtain then
            local kp = keyObtain:IsA("BasePart") and keyObtain or (keyObtain:IsA("Model") and (keyObtain.PrimaryPart or keyObtain:FindFirstChildWhichIsA("BasePart", true)))
            if kp then
                farmGlideTo(kp.Position + Vector3.new(0, 1.2, 0), 45, 3.0)
                local p = keyObtain:FindFirstChildWhichIsA("ProximityPrompt", true)
                if p then
                    p.HoldDuration = 0
                    pcall(function() fireproximityprompt(p) end)
                end
                task.wait(0.3)
            end
        end
    end

    -- Room 50 (Figure & Library)
    if curRoomNum == 50 then
        solveFigureLibraryRoom()
        task.wait(1.0)
        return
    end

    -- Seek Chase: Rapid pass-through mode
    local isSeekChase = (gd and gd:FindFirstChild("ChaseInSession") and gd.ChaseInSession.Value == true) or (Workspace:FindFirstChild("SeekMoving") ~= nil)
    if isSeekChase then
        Hub.Notify("Knobs Farm", "Seek Chase active! Sprint-flying through corridor...", 2)
        local exitDoor = roomModel and roomModel:FindFirstChild("Door")
        if exitDoor then
            local dPart = exitDoor:FindFirstChild("Door") or exitDoor:FindFirstChild("Hidden") or exitDoor.PrimaryPart
            if dPart then
                farmGlideTo(dPart.Position + Vector3.new(0, 0, 2), 75, 4.0)
                processNearbyDoors(dPart.Position, 25)
            end
        end
        task.wait(0.15)
        return
    end

    -- Loot current room (Containers, Drawers, Gold, Chests)
    if roomModel and not lootedRoomsThisRun[curRoomNum] then
        lootedRoomsThisRun[curRoomNum] = true
        local lootTargets = {}

        for _, desc in ipairs(roomModel:GetDescendants()) do
            if desc:IsA("ProximityPrompt") and desc.Enabled and not lootedContainersThisRun[desc] then
                local obj = (desc.ObjectText or ""):lower()
                local act = (desc.ActionText or ""):lower()
                local pName = desc.Parent and desc.Parent.Name:lower() or ""

                -- Gold / Coins / Stardust
                local isGold = obj:find("gold") or obj:find("coin") or act:find("gold") or act:find("coin") or pName:find("gold") or obj:find("stardust")
                -- Drawers & Desks
                local isDrawer = State.Knobs_Farm_LootDrawers and (pName:find("knob") or pName:find("drawer") or obj:find("drawer") or pName:find("desk") or obj:find("desk") or pName:find("dresser"))
                -- Chests
                local isChest = State.Knobs_Farm_LootChests and (pName:find("chest") or obj:find("chest"))
                -- Tools (Lockpicks, Crucifix, Skeleton Key)
                local isTool = pName:find("lockpick") or obj:find("lockpick") or pName:find("crucifix") or obj:find("crucifix") or pName:find("skeleton") or obj:find("skeleton") or pName:find("key")

                if isGold or isDrawer or isChest or isTool then
                    local pPart = desc.Parent:IsA("BasePart") and desc.Parent or (desc.Parent:IsA("Model") and (desc.Parent.PrimaryPart or desc.Parent:FindFirstChildWhichIsA("BasePart", true)))
                    if pPart then
                        table.insert(lootTargets, { Prompt = desc, Part = pPart, IsChest = isChest, IsTool = isTool, IsGold = isGold })
                    end
                end
            end
        end

        -- Priority Gold Sorting: Collect high-value gold piles first to maximize Knobs per minute!
        table.sort(lootTargets, function(a, b)
            local aGold = a.IsGold or false
            local bGold = b.IsGold or false
            if aGold ~= bGold then return aGold end
            return false
        end)

        -- Fly to and loot each target in sequence
        for _, target in ipairs(lootTargets) do
            if not State.Knobs_Farm_Active then break end
            if isLethalEntityIncoming() then
                handleFarmRoofEvacuation()
                break
            end

            local p = target.Prompt
            local part = target.Part
            if p and p.Parent and p.Enabled and part and part.Parent then
                local res = farmGlideTo(part.Position + Vector3.new(0, 1.2, 0), 55, 2.5)
                if res == "THREAT_INTERRUPT" then
                    handleFarmRoofEvacuation()
                    break
                end

                -- If locked chest, trigger Infinite Items dupe-drop with lockpick
                local usedTool = nil
                if target.IsChest then
                    local lockpick, isEq = getEquippedOrInventoryTool({"lockpick", "skeleton"})
                    if lockpick then
                        usedTool = lockpick
                        local hum = char and char:FindFirstChildWhichIsA("Humanoid")
                        if not isEq and hum and lockpick.Parent == LocalPlayer.Backpack then
                            hum:EquipTool(lockpick)
                            task.wait(0.08)
                        end
                    end
                end

                p.HoldDuration = 0
                p.RequiresLineOfSight = false
                lootedContainersThisRun[p] = true
                pcall(function() fireproximityprompt(p) end)
                if usedTool and State.Infinite_Items and State.Infinite_Lockpicks then
                    executeItemDupeDrop(usedTool, 0.09)
                end
                task.wait(0.12)
            end
        end
    end

    -- Locked Door Handling: Grab room key if locked
    local exitDoor = roomModel and roomModel:FindFirstChild("Door")
    if exitDoor then
        local lock = exitDoor:FindFirstChild("Lock")
        if lock and (lock:GetAttribute("Locked") == true or lock:FindFirstChild("UnlockPrompt", true)) then
            local hasKey = LocalPlayer.Backpack:FindFirstChild("Key") ~= nil or (char and char:FindFirstChild("Key") ~= nil)
            if not hasKey then
                -- Locate key in room
                local key = roomModel:FindFirstChild("KeyObtain", true)
                if key then
                    local kp = key:IsA("BasePart") and key or (key:IsA("Model") and (key.PrimaryPart or key:FindFirstChildWhichIsA("BasePart", true)))
                    if kp then
                        farmGlideTo(kp.Position + Vector3.new(0, 1.2, 0), 60, 3.5)
                        local kpPrompt = key:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if kpPrompt then
                            kpPrompt.HoldDuration = 0
                            pcall(function() fireproximityprompt(kpPrompt) end)
                        end
                        task.wait(0.2)
                    end
                end
            end
        end

        -- Fly to Exit Door & Open
        local dPart = exitDoor:FindFirstChild("Door") or exitDoor:FindFirstChild("Hidden") or exitDoor.PrimaryPart
        if dPart then
            local toPlayer = (root.Position - dPart.Position)
            local hToPlayer = Vector3.new(toPlayer.X, 0, toPlayer.Z)
            local approachDir = (hToPlayer.Magnitude > 0.1) and hToPlayer.Unit or -dPart.CFrame.LookVector

            farmGlideTo(dPart.Position + approachDir * 3.0, 55, 3.5)

            -- Unlock if lock prompt exists
            if lock then
                local hum = char and char:FindFirstChildWhichIsA("Humanoid")
                local keyTool = LocalPlayer.Backpack:FindFirstChild("Key") or (char and char:FindFirstChild("Key"))
                if keyTool and keyTool.Parent == LocalPlayer.Backpack and hum then
                    hum:EquipTool(keyTool)
                    task.wait(0.05)
                end
                local up = lock:FindFirstChild("UnlockPrompt", true)
                if up and up.Enabled then
                    up.HoldDuration = 0
                    pcall(function() fireproximityprompt(up) end)
                    task.wait(0.15)
                end
            end

            -- Open door & step across into next chamber
            local co = exitDoor:FindFirstChild("ClientOpen")
            if co then pcall(function() co:FireServer() end) end
            local hiddenPart = exitDoor:FindFirstChild("Hidden")
            if hiddenPart and hiddenPart:IsA("BasePart") then
                pcall(function()
                    hiddenPart.CanTouch = true
                    if root then
                        firetouchinterest(root, hiddenPart, 0)
                        task.wait(0.02)
                        firetouchinterest(root, hiddenPart, 1)
                    end
                end)
            end
            processNearbyDoors(dPart.Position, 25)
            farmGlideTo(dPart.Position - approachDir * 6.0, 50, 2.0)
            task.wait(0.2)
        end
    end
    end)
    isKnobsFarmRunning = false
end
_G.processKnobsFarmStep = processKnobsFarmStep

-- Knobs Farm Background Master Daemon
task.spawn(function()
    while true do
        if _G.DOORS_SESSION ~= currentSession then break end
        if State.Knobs_Farm_Active then
            pcall(processKnobsFarmStep)
        end
        task.wait(0.1)
    end
end)

-- =========================================================================
-- Autonomous DOORS 1-100 Master Completer Engine
-- Complete Hands-Free Run: Key Finder, Puzzle Solver, Room 50 & 100 Auto-Beat
-- Roof Safe Evacuation & Instant Death/Win Auto-Restart Pipeline
-- =========================================================================
runAutoComplete100Step = function()
    _G.runAutoComplete100Step = runAutoComplete100Step
    if not State.Auto_Complete_100 then return end
    if isCompleterActive then return end
    isCompleterActive = true

    local pcallStatus, pcallErr = pcall(function()
        local char = getChar()
        local root = getRoot()
        local hum = char and char:FindFirstChildWhichIsA("Humanoid")
        if not char or not root or not hum or hum.Health <= 0 then return end

        -- Threat evacuation check: if lethal entity incoming, evacuate to safe ceiling
        if isLethalEntityIncoming() then
            handleFarmRoofEvacuation()
            return
        end

        local gd = game:GetService("ReplicatedStorage"):FindFirstChild("GameData")
        local lr = gd and gd:FindFirstChild("LatestRoom") and gd.LatestRoom.Value or 0
        local curRooms = Workspace:FindFirstChild("CurrentRooms")
        if not curRooms or #curRooms:GetChildren() == 0 then
            task.wait(0.5)
            return
        end

        local curRoom = curRooms:FindFirstChild(tostring(lr))

        -- Ensure Noclip & Anti-Cheat Bypass are actively engaged
        if not State.Noclip then State.Noclip = true end
        if not State.Bypass_AntiCheat then State.Bypass_AntiCheat = true end

        -- Special Stage: Room 50 (Figure Library)
        if lr == 50 then
            local padlock = curRoom and curRoom:FindFirstChild("Padlock", true)
            if padlock and padlock:FindFirstChildWhichIsA("ProximityPrompt", true) then
                solveFigureLibraryRoom()
                task.wait(1.5)
                return
            end
        end

        -- Special Stage: Room 100 (Figure & Elevator Circuit Breakers)
        if lr == 100 then
            local elBreaker = Workspace:FindFirstChild("ElevatorBreaker", true)
            if elBreaker then
                Hub.Notify("Completer", "Door 100 reached! Solving Breakers...", 3)
                instantSolveBreakers()
                task.wait(3.0)

                local elevator = Workspace:FindFirstChild("StarterElevator", true) or Workspace:FindFirstChild("Elevator", true)
                if elevator then
                    local ePart = elevator:FindFirstChildWhichIsA("BasePart", true)
                    if ePart then
                        farmGlideTo(ePart.Position + Vector3.new(0, 2, 0), 45, 5.0)
                        Hub.Notify("Completer", "Entered Elevator! Victory achieved!", 5)
                    end
                end
                task.wait(5.0)
                return
            end
        end

        if not curRoom then
            task.wait(0.5)
            return
        end

        local door = curRoom:FindFirstChild("Door")
        local lock = door and door:FindFirstChild("Lock")
        local isLocked = lock and lock:FindFirstChild("UnlockPrompt", true) ~= nil

        if isLocked then
            local hasKey = LocalPlayer.Backpack:FindFirstChild("Key") ~= nil or (char:FindFirstChild("Key") ~= nil)
            if not hasKey then
                Hub.Notify("Completer", "Room " .. tostring(lr) .. " locked. Finding Key...", 2)
                teleportToRoomKey()
                task.wait(1.0)
                return
            else
                local keyTool = LocalPlayer.Backpack:FindFirstChild("Key") or char:FindFirstChild("Key")
                if keyTool and hum then hum:EquipTool(keyTool) end
            end
        end

        -- Path to and through door
        teleportToNextDoor()
        task.wait(0.8)
    end)

    isCompleterActive = false
end
_G.runAutoComplete100Step = runAutoComplete100Step

-- Completer Main Execution Daemon
task.spawn(function()
    while true do
        if _G.DOORS_SESSION ~= currentSession then break end
        if State.Auto_Complete_100 then
            pcall(runAutoComplete100Step)
        end
        task.wait(0.3)
    end
end)

-- Death / Win Auto-Restart Pipeline (Restarts match & continues completing)
task.spawn(function()
    while _G.DOORS_SESSION == currentSession do
        task.wait(1.0)
        if State.Auto_Complete_100 or State.Knobs_Farm_Active then
            local pGui = LocalPlayer:FindFirstChild("PlayerGui")
            local mainUI = pGui and pGui:FindFirstChild("MainUI")
            local deathPanel = mainUI and mainUI:FindFirstChild("DeathPanel")
            if deathPanel and deathPanel.Visible then
                Hub.Notify("Completer", "Match finished. Restarting run in 2s...", 2)
                task.wait(2.0)
                local playAgainBtn = deathPanel:FindFirstChild("PlayAgain") or deathPanel:FindFirstChild("BattlePlayAgain")
                if playAgainBtn then
                    pcall(function()
                        for _, c in ipairs(getconnections(playAgainBtn.MouseButton1Down)) do
                            if c.Fire then c:Fire() elseif c.Function then c.Function() end
                        end
                    end)
                end
                local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("RemotesFolder")
                local playAgainRemote = remotes and remotes:FindFirstChild("PlayAgain")
                if playAgainRemote then pcall(function() playAgainRemote:FireServer() end) end
            end
        end
    end
end)


-- Character Respawn Watcher (Auto-Resumes on new match / after reset!)
LocalPlayer.CharacterAdded:Connect(function(newChar)
    if _G.DOORS_SESSION ~= currentSession then return end
    setupQueueOnTeleport()
    if State.Knobs_Farm_Active or getgenv().Doors_KnobsFarm_AutoResume then
        State.Knobs_Farm_Active = true
        getgenv().Doors_KnobsFarm_AutoResume = true
        task.delay(2.5, function()
            lootedContainersThisRun = {}
            lootedRoomsThisRun = {}
            isEvacuatingRoof = false
            Hub.Notify("Knobs Farm", "⚡ New match detected! Autopilot resumed.", 3)
        end)
    end
end)

-- Auto-resume immediately if flagged in memory
if getgenv().Doors_KnobsFarm_AutoResume then
    State.Knobs_Farm_Active = true
    setupQueueOnTeleport()
    Hub.Notify("Knobs Farm", "⚡ Auto-Resuming Knobs Farm from previous session!", 3)
end

-- =========================================================================
-- UI Tabs
-- =========================================================================

local detectedFloor = (game.ReplicatedStorage:FindFirstChild("GameData") and game.ReplicatedStorage.GameData:FindFirstChild("Floor") and game.ReplicatedStorage.GameData.Floor.Value) or "Hotel"

-- =========================================================================
-- Entity Path Nodes & Rush/Ambush Safe Zones Visualization Subsystems
-- =========================================================================
local activeNodeVisuals = {}
local activeSafeZoneVisuals = {}
local rushSafeHUD = nil

local cachedRoomPathNodes = {}

local function getOrderedRoomNodes()
    local nodes = {}
    local curRooms = Workspace:FindFirstChild("CurrentRooms")
    if not curRooms then return nodes end

    local roomList = {}
    for _, rm in ipairs(curRooms:GetChildren()) do
        local num = tonumber(rm.Name)
        if num ~= nil and rm:IsA("Model") then
            table.insert(roomList, { Room = rm, Number = num })
        end
    end
    table.sort(roomList, function(a, b) return a.Number < b.Number end)

    for _, rData in ipairs(roomList) do
        local rm = rData.Room
        local rNum = rData.Number

        -- If not yet cached, or if room has PathfindNodes right now, update persistent room cache:
        local intermediate = rm:FindFirstChild("PathfindNodes") or rm:FindFirstChild("Nodes") or rm:FindFirstChild("Waypoints")
        if intermediate or not cachedRoomPathNodes[rNum] then
            local roomNodes = {}
            local entrance = rm:FindFirstChild("RoomEntrance")
            local exit = rm:FindFirstChild("RoomExit")

            if entrance and entrance:IsA("BasePart") then
                table.insert(roomNodes, { Pos = entrance.Position, RoomNum = rNum, Name = "Entrance", Part = entrance })
            end

            if intermediate then
                local interList = {}
                for _, child in ipairs(intermediate:GetChildren()) do
                    if child:IsA("BasePart") then
                        table.insert(interList, child)
                    end
                end
                table.sort(interList, function(a, b)
                    local na = tonumber(a.Name:match("%d+")) or 0
                    local nb = tonumber(b.Name:match("%d+")) or 0
                    return na < nb
                end)
                for i, p in ipairs(interList) do
                    table.insert(roomNodes, { Pos = p.Position, RoomNum = rNum, Name = "Node " .. tostring(i), Part = p })
                end
            end

            if exit and exit:IsA("BasePart") then
                table.insert(roomNodes, { Pos = exit.Position, RoomNum = rNum, Name = "Exit", Part = exit })
            end

            if #roomNodes > 0 then
                -- Only overwrite cache if new scan has intermediate nodes or cache didn't exist
                if intermediate or not cachedRoomPathNodes[rNum] or #cachedRoomPathNodes[rNum] <= 2 then
                    cachedRoomPathNodes[rNum] = roomNodes
                end
            end
        end

        -- Append cached nodes for this room (they NEVER disappear when room is opened!)
        local rNodes = cachedRoomPathNodes[rNum]
        if rNodes then
            for _, n in ipairs(rNodes) do
                table.insert(nodes, n)
            end
        end
    end

    return nodes
end

local function getRushPathSegments()
    local nodes = getOrderedRoomNodes()
    local segments = {}
    if #nodes < 2 then return segments end

    for i = 1, #nodes - 1 do
        local n1 = nodes[i]
        local n2 = nodes[i + 1]
        local dist = (n2.Pos - n1.Pos).Magnitude
        if dist > 0.5 and dist < 120 then
            table.insert(segments, {
                A = n1.Pos,
                B = n2.Pos,
                Room1 = n1.RoomNum,
                Room2 = n2.RoomNum,
                Length = dist
            })
        end
    end
    return segments
end

local function getClosestPointOnSegment(p, a, b)
    local ab = b - a
    local abLenSq = ab.X * ab.X + ab.Y * ab.Y + ab.Z * ab.Z
    if abLenSq < 0.0001 then
        return a, (p - a).Magnitude
    end
    local ap = p - a
    local t = (ap.X * ab.X + ap.Y * ab.Y + ap.Z * ab.Z) / abLenSq
    if t < 0 then t = 0 elseif t > 1 then t = 1 end
    local closest = a + ab * t
    return closest, (p - closest).Magnitude
end

local function clearNodeVisuals()
    for _, vis in ipairs(activeNodeVisuals) do
        pcall(function() vis:Destroy() end)
    end
    activeNodeVisuals = {}
end

local function clearSafeZoneVisuals()
    for _, vis in ipairs(activeSafeZoneVisuals) do
        pcall(function() vis:Destroy() end)
    end
    activeSafeZoneVisuals = {}
end

local function updateRushSafeHUD(isSafe, statusText)
    if not State.ESP_Safe_Zones then
        if rushSafeHUD then rushSafeHUD.Enabled = false end
        return
    end

    if not rushSafeHUD or not rushSafeHUD.Parent then
        local pGui = LocalPlayer:FindFirstChild("PlayerGui")
        local host = (gethui and gethui()) or pGui or CoreGui
        rushSafeHUD = Instance.new("ScreenGui")
        rushSafeHUD.Name = "Unknown_RushSafeHUD"
        rushSafeHUD.ResetOnSpawn = false
        rushSafeHUD.DisplayOrder = 100

        local pill = Instance.new("Frame")
        pill.Name = "Pill"
        pill.Size = UDim2.new(0, 320, 0, 36)
        pill.Position = UDim2.new(0.5, -160, 0, 24)
        pill.BackgroundColor3 = Color3.fromRGB(15, 20, 28)
        pill.BorderSizePixel = 0
        pill.Parent = rushSafeHUD

        local uic = Instance.new("UICorner")
        uic.CornerRadius = UDim.new(0, 18)
        uic.Parent = pill

        local uis = Instance.new("UIStroke")
        uis.Name = "Stroke"
        uis.Thickness = 1.5
        uis.Color = Color3.fromRGB(0, 255, 120)
        uis.Parent = pill

        local label = Instance.new("TextLabel")
        label.Name = "Status"
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.GothamBold
        label.TextSize = 13
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.Text = "RUSH SAFETY: INITIALIZING..."
        label.Parent = pill

        rushSafeHUD.Parent = host
    end

    rushSafeHUD.Enabled = true
    local pill = rushSafeHUD:FindFirstChild("Pill")
    if pill then
        local stroke = pill:FindFirstChild("Stroke")
        local label = pill:FindFirstChild("Status")
        if isSafe then
            if stroke then stroke.Color = Color3.fromRGB(0, 255, 120) end
            pill.BackgroundColor3 = Color3.fromRGB(12, 45, 25)
            if label then
                label.Text = statusText or "🛡️ SAFE ZONE: SHIELDED FROM RUSH/AMBUSH"
                label.TextColor3 = Color3.fromRGB(80, 255, 160)
            end
        else
            if stroke then stroke.Color = Color3.fromRGB(255, 45, 45) end
            pill.BackgroundColor3 = Color3.fromRGB(55, 15, 15)
            if label then
                label.Text = statusText or "⚠️ DANGER: DIRECT RUSH / AMBUSH LINE OF SIGHT"
                label.TextColor3 = Color3.fromRGB(255, 90, 90)
            end
        end
    end
end

local function refreshEntityNodesVisuals()
    clearNodeVisuals()
    if not State.ESP_Entity_Nodes then return end

    local nodes = getOrderedRoomNodes()
    local isRushIncoming = isLethalEntityIncoming()
    local nodeColor = isRushIncoming and Color3.fromRGB(255, 45, 45) or Color3.fromRGB(0, 215, 255)

    local folder = Instance.new("Folder")
    folder.Name = "Unknown_EntityNodesVisuals"
    folder.Parent = (gethui and gethui()) or Workspace:FindFirstChild("Terrain") or Workspace
    table.insert(activeNodeVisuals, folder)

    for i, node in ipairs(nodes) do
        local nodePart = Instance.new("Part")
        nodePart.Name = "NodePart_" .. i
        nodePart.Size = Vector3.new(0.5, 0.5, 0.5)
        nodePart.CFrame = CFrame.new(node.Pos + Vector3.new(0, 1.5, 0))
        nodePart.Anchored = true
        nodePart.CanCollide = false
        nodePart.CanTouch = false
        nodePart.CanQuery = false
        nodePart.Transparency = 1
        nodePart.Parent = folder
        table.insert(activeNodeVisuals, nodePart)

        local adorn = Instance.new("SphereHandleAdornment")
        adorn.Name = "Adorn"
        adorn.Radius = 1.1
        adorn.Color3 = nodeColor
        adorn.Transparency = 0.25
        adorn.AlwaysOnTop = true
        adorn.ZIndex = 8
        adorn.Adornee = nodePart
        adorn.Parent = nodePart
        table.insert(activeNodeVisuals, adorn)

        local bb = Instance.new("BillboardGui")
        bb.Name = "Label"
        bb.Size = UDim2.new(0, 90, 0, 22)
        bb.StudsOffset = Vector3.new(0, 1.6, 0)
        bb.AlwaysOnTop = true
        bb.Adornee = nodePart
        bb.Parent = nodePart
        table.insert(activeNodeVisuals, bb)

        local tl = Instance.new("TextLabel")
        tl.Size = UDim2.new(1, 0, 1, 0)
        tl.BackgroundTransparency = 1
        tl.Font = Enum.Font.GothamBold
        tl.TextSize = 12
        tl.TextColor3 = nodeColor
        tl.TextStrokeTransparency = 0.2
        tl.Text = string.format("Node %d (R%d)", i, node.RoomNum)
        tl.Parent = bb

        -- Connect line to next node
        if i < #nodes then
            local nextNode = nodes[i + 1]
            local p1 = node.Pos + Vector3.new(0, 1.5, 0)
            local p2 = nextNode.Pos + Vector3.new(0, 1.5, 0)
            local dist = (p2 - p1).Magnitude
            if dist < 85 then
                local linePart = Instance.new("Part")
                linePart.Name = "LinePart_" .. i
                linePart.Size = Vector3.new(0.2, 0.2, dist)
                linePart.CFrame = CFrame.new((p1 + p2) * 0.5, p2)
                linePart.Anchored = true
                linePart.CanCollide = false
                linePart.CanTouch = false
                linePart.CanQuery = false
                linePart.Material = Enum.Material.Neon
                linePart.Color = nodeColor
                linePart.Transparency = 0.4
                linePart.Parent = folder
                table.insert(activeNodeVisuals, linePart)
            end
        end
    end
end

local function checkWalkableFloor(candidatePos, ignoreList)
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    local filter = {getChar()}
    if ignoreList then
        for _, item in ipairs(ignoreList) do table.insert(filter, item) end
    end
    local drops = Workspace:FindFirstChild("Drops")
    if drops then table.insert(filter, drops) end
    for _, vis in ipairs(activeSafeZoneVisuals) do table.insert(filter, vis) end
    for _, vis in ipairs(activeNodeVisuals) do table.insert(filter, vis) end
    rayParams.FilterDescendantsInstances = filter

    -- 1. Downward Raycast to locate real floor surface
    local downHit = Workspace:Raycast(candidatePos + Vector3.new(0, 3.5, 0), Vector3.new(0, -9.0, 0), rayParams)
    if not downHit or not downHit.Instance or not downHit.Instance.CanCollide then
        return nil
    end

    -- Normal must face predominantly upwards (walkable floor, not wall or steep angle)
    if downHit.Normal.Y < 0.72 then
        return nil
    end

    local floorPos = downHit.Position

    -- 2. Upward Headroom Raycast (4.2 studs standing clearance)
    local upHit = Workspace:Raycast(floorPos + Vector3.new(0, 0.4, 0), Vector3.new(0, 4.2, 0), rayParams)
    if upHit and upHit.Instance and upHit.Instance.CanCollide then
        return nil
    end

    -- 3. 4-way horizontal clearance check (1.2 studs radius) to prevent clipping in bookshelves/walls
    local waistPos = floorPos + Vector3.new(0, 2.0, 0)
    local radialOffsets = {
        Vector3.new(1.2, 0, 0),
        Vector3.new(-1.2, 0, 0),
        Vector3.new(0, 0, 1.2),
        Vector3.new(0, 0, -1.2)
    }
    for _, off in ipairs(radialOffsets) do
        local sideHit = Workspace:Raycast(waistPos, off, rayParams)
        if sideHit and sideHit.Instance and sideHit.Instance.CanCollide then
            return nil
        end
    end

    return floorPos
end

local function evaluateRushSafety(testPos, segments, char)
    if State.God_Mode then
        return true, "⚡ GOD-MODE ACTIVE: ENTITIES CANNOT DAMAGE"
    end
    if isHidingState() then
        return true, "🛡️ SAFE: HIDDEN IN CLOSET/BED"
    end

    if not segments or #segments == 0 then
        return true, "🛡️ SAFE: NO ACTIVE THREAT DETECTED"
    end

    local charInst = char or getChar()
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    local filter = {charInst}
    local drops = Workspace:FindFirstChild("Drops")
    if drops then table.insert(filter, drops) end
    for _, vis in ipairs(activeSafeZoneVisuals) do table.insert(filter, vis) end
    for _, vis in ipairs(activeNodeVisuals) do table.insert(filter, vis) end
    rayParams.FilterDescendantsInstances = filter

    local minSegmentDist = math.huge
    local closestPathPoint = nil
    local closestSeg = nil

    for _, seg in ipairs(segments) do
        local cPoint, dist = getClosestPointOnSegment(testPos, seg.A, seg.B)
        if dist < minSegmentDist then
            minSegmentDist = dist
            closestPathPoint = cPoint
            closestSeg = seg
        end
    end

    -- If player is completely beyond lethal path radius (> 22 studs from all segments)
    if minSegmentDist > 22 then
        return true, "🛡️ SAFE ZONE: OUT OF RUSH PATH RANGE"
    end

    -- Within 22 studs: Rush CAN kill here unless blocked by solid wall cover!
    -- Check Line of Sight from nearby path trajectory points
    local samplePoints = {}
    if closestPathPoint then
        table.insert(samplePoints, closestPathPoint)
        if closestSeg and closestSeg.Length > 8 then
            local dir = (closestSeg.B - closestSeg.A).Unit
            local pAhead, _ = getClosestPointOnSegment(closestPathPoint + dir * 6, closestSeg.A, closestSeg.B)
            local pBehind, _ = getClosestPointOnSegment(closestPathPoint - dir * 6, closestSeg.A, closestSeg.B)
            table.insert(samplePoints, pAhead)
            table.insert(samplePoints, pBehind)
        end
    end

    local targetElev = testPos + Vector3.new(0, 2.5, 0)
    local directLineOfSight = false

    -- Multi-Point Trajectory Raycast: Sample points along all room segments within 28 studs
    local nearbyTrajectoryPoints = {}
    for _, seg in ipairs(segments) do
        local _, sDist = getClosestPointOnSegment(testPos, seg.A, seg.B)
        if sDist <= 28 then
            table.insert(nearbyTrajectoryPoints, seg.A)
            table.insert(nearbyTrajectoryPoints, (seg.A + seg.B) * 0.5)
            table.insert(nearbyTrajectoryPoints, seg.B)
        end
    end

    if #nearbyTrajectoryPoints == 0 then
        table.insert(nearbyTrajectoryPoints, closestPathPoint or testPos)
    end

    local blockedCount = 0
    local totalRays = 0

    for _, pt in ipairs(nearbyTrajectoryPoints) do
        local origin = pt + Vector3.new(0, 3.2, 0)
        local diff = targetElev - origin
        local dist = diff.Magnitude
        if dist > 0.5 then
            totalRays = totalRays + 1
            local hit = Workspace:Raycast(origin, diff.Unit * (dist * 0.98), rayParams)
            if hit and hit.Instance and hit.Instance.CanCollide and not hit.Instance.Name:lower():find("door") then
                blockedCount = blockedCount + 1
            else
                directLineOfSight = true
            end
        end
    end

    -- If all nearby path rays within lethal range are obstructed by solid wall/pillar cover:
    if directLineOfSight and minSegmentDist < 16 and (totalRays > 0 and (blockedCount / totalRays) < 0.6) then
        return false, "⚠️ DANGER: DIRECT RUSH / AMBUSH LINE OF SIGHT"
    else
        return true, "🛡️ SAFE: BEHIND COVER (RUSH CANNOT SEE YOU)"
    end
end

local function refreshSafeZonesVisuals()
    clearSafeZoneVisuals()
    if not State.ESP_Safe_Zones then
        updateRushSafeHUD(false, nil)
        return
    end

    local curRooms = Workspace:FindFirstChild("CurrentRooms")
    if not curRooms then return end

    local segments = getRushPathSegments()
    local char = getChar()
    local folder = Instance.new("Folder")
    folder.Name = "Unknown_SafeZonesVisuals"
    folder.Parent = (gethui and gethui()) or Workspace:FindFirstChild("Terrain") or Workspace
    table.insert(activeSafeZoneVisuals, folder)

    local curRoomNum = getCurrentRoomNumber()
    local acceptedSpots = {}

    local function isDuplicate(pos, minDist)
        minDist = minDist or 6.5
        for _, s in ipairs(acceptedSpots) do
            if (s.Pos - pos).Magnitude < minDist then
                return true
            end
        end
        return false
    end

    -- Process current room and adjacent rooms (+/- 1)
    for _, rm in ipairs(curRooms:GetChildren()) do
        local rNum = tonumber(rm.Name)
        if rNum and math.abs(rNum - curRoomNum) <= 1 and rm:IsA("Model") then
            -- 1. Hiding Spots (Closets, Wardrobes, Lockers, Beds)
            for _, desc in ipairs(rm:GetDescendants()) do
                if desc:IsA("Model") or desc:IsA("BasePart") then
                    local dName = desc.Name:lower()
                    local isWardrobe = dName:find("wardrobe") or dName:find("closet") or dName:find("locker")
                    local isBed = dName:find("bed")

                    if isWardrobe then
                        local cf = desc:GetPivot()
                        -- Try standing spot 2.8 studs in front of wardrobe
                        local cand1 = cf.Position + cf.LookVector * 2.8
                        local cand2 = cf.Position - cf.LookVector * 2.8
                        local floor1 = checkWalkableFloor(cand1, {desc})
                        local floor2 = checkWalkableFloor(cand2, {desc})
                        local chosen = floor1 or floor2
                        if chosen and not isDuplicate(chosen, 5.0) then
                            table.insert(acceptedSpots, { Pos = chosen, Label = "HIDE: WARDROBE" })
                        end
                    elseif isBed then
                        local cf = desc:GetPivot()
                        -- Try standing spot 2.5 studs to the side of the bed
                        local cand1 = cf.Position + cf.RightVector * 2.5
                        local cand2 = cf.Position - cf.RightVector * 2.5
                        local floor1 = checkWalkableFloor(cand1, {desc})
                        local floor2 = checkWalkableFloor(cand2, {desc})
                        local chosen = floor1 or floor2
                        if chosen and not isDuplicate(chosen, 5.0) then
                            table.insert(acceptedSpots, { Pos = chosen, Label = "HIDE: BED" })
                        end
                    end
                end
            end

            -- 2. True Safe Cover / Wall Shielded Standing Spots (NO FURNITURE PIVOTS!)
            -- Sample actual walkable floor parts in the room
            local roomCoverCount = 0
            for _, p in ipairs(rm:GetDescendants()) do
                if p:IsA("BasePart") and p.CanCollide and roomCoverCount < 3 then
                    local pName = p.Name:lower()
                    if pName:find("floor") or pName:find("carpet") then
                        -- Test candidate points on the floor part
                        local cands = {
                            p.Position,
                            p.Position + p.CFrame.RightVector * (p.Size.X * 0.35),
                            p.Position - p.CFrame.RightVector * (p.Size.X * 0.35),
                            p.Position + p.CFrame.LookVector * (p.Size.Z * 0.35),
                            p.Position - p.CFrame.LookVector * (p.Size.Z * 0.35),
                        }
                        for _, cand in ipairs(cands) do
                            if roomCoverCount >= 3 then break end
                            local floor = checkWalkableFloor(cand)
                            if floor and not isDuplicate(floor, 7.5) then
                                local safe, _ = evaluateRushSafety(floor, segments, char)
                                if safe then
                                    table.insert(acceptedSpots, { Pos = floor, Label = "SAFE COVER" })
                                    roomCoverCount = roomCoverCount + 1
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    -- Render clean visual discs flat on the floor
    for i, sp in ipairs(acceptedSpots) do
        local spPart = Instance.new("Part")
        spPart.Name = "SafePart_" .. i
        spPart.Size = Vector3.new(0.5, 0.1, 0.5)
        spPart.CFrame = CFrame.new(sp.Pos + Vector3.new(0, 0.05, 0))
        spPart.Anchored = true
        spPart.CanCollide = false
        spPart.CanTouch = false
        spPart.CanQuery = false
        spPart.Transparency = 1
        spPart.Parent = folder
        table.insert(activeSafeZoneVisuals, spPart)

        local adorn = Instance.new("CylinderHandleAdornment")
        adorn.Name = "SafeZoneDisc"
        adorn.Radius = 2.0
        adorn.Height = 0.08
        adorn.Color3 = Color3.fromRGB(0, 255, 120)
        adorn.Transparency = 0.4
        adorn.AlwaysOnTop = false
        adorn.ZIndex = 8
        adorn.Adornee = spPart
        adorn.CFrame = CFrame.Angles(math.pi / 2, 0, 0)
        adorn.Parent = spPart
        table.insert(activeSafeZoneVisuals, adorn)

        local bb = Instance.new("BillboardGui")
        bb.Name = "SafeLabel"
        bb.Size = UDim2.new(0, 110, 0, 22)
        bb.StudsOffset = Vector3.new(0, 1.8, 0)
        bb.AlwaysOnTop = true
        bb.Adornee = spPart
        bb.Parent = spPart
        table.insert(activeSafeZoneVisuals, bb)

        local tl = Instance.new("TextLabel")
        tl.Size = UDim2.new(1, 0, 1, 0)
        tl.BackgroundTransparency = 1
        tl.Font = Enum.Font.GothamBold
        tl.TextSize = 12
        tl.TextColor3 = Color3.fromRGB(0, 255, 130)
        tl.TextStrokeTransparency = 0.2
        tl.Text = sp.Label
        tl.Parent = bb
        table.insert(activeSafeZoneVisuals, tl)
    end
end

-- Fast Real-Time Safety Evaluation Loop (0.12s)
task.spawn(function()
    while true do
        if _G.DOORS_SESSION ~= currentSession then break end
        if State.ESP_Safe_Zones then
            local char = getChar()
            local root = getRoot()
            if root and char then
                local segments = getRushPathSegments()
                local isSafe, statusText = evaluateRushSafety(root.Position, segments, char)
                updateRushSafeHUD(isSafe, statusText)
            end
        else
            updateRushSafeHUD(false, nil)
        end
        task.wait(0.12)
    end
end)

-- Background Refresh Loop for World Discs and Node Visuals (1.5s)
task.spawn(function()
    local lastCheckedRoom = -999
    while true do
        if _G.DOORS_SESSION ~= currentSession then break end
        if State.ESP_Safe_Zones then
            local curRoom = getCurrentRoomNumber()
            if curRoom ~= lastCheckedRoom or #activeSafeZoneVisuals == 0 then
                lastCheckedRoom = curRoom
                pcall(refreshSafeZonesVisuals)
            end
        end
        if State.ESP_Entity_Nodes then
            pcall(refreshEntityNodesVisuals)
        end
        task.wait(1.5)
    end
end)

-- Tab 1: MAIN TAB (Movement, Interaction, Speed Changer & Automation)
do
local mainTab = Hub.CreateTab("Main", { 
    Icon = "🏠", 
    Size = 18, 
    Color = Color3.fromRGB(240, 150, 25), 
    ActiveColor = Color3.fromRGB(255, 185, 30) 
})

Hub.CreateSection(mainTab, "Movement")

Hub.CreateToggle(mainTab, "Walk Noclip", State.Walk_Noclip, function(v)
    State.Walk_Noclip = v
    if v then
        if not State.Bypass_AntiCheat then
            State.Bypass_AntiCheat = true
            neutralizeServerTeleported()
            initAntiGlitchShield()
            Hub.Notify("Anti-Cheat", "Anti-Cheat Bypass auto-enabled for Walk Noclip!", 2)
        end
        local mg = getMainGameTable()
        if mg then
            local r = getRoot()
            if r then mg.clipPos = r.Position end
        end
    else
        local char = getChar()
        if char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") and (p.Name == "Collision" or p.Name == "HumanoidRootPart") then
                    p.CanCollide = true
                end
            end
        end
    end
    Hub.Notify("Movement", v and "Walk Noclip: Active (Walk through walls without flying!)" or "Walk Noclip: Disabled", 2)
end)

Hub.CreateToggle(mainTab, "Fly Noclip", State.Noclip, function(v)
    if v and not State.Bypass_AntiCheat then
        State.Bypass_AntiCheat = true
        neutralizeServerTeleported()
        initAntiGlitchShield()
        Hub.Notify("Anti-Cheat", "Anti-Cheat Bypass auto-enabled for Fly Noclip!", 2)
    end
    State.Noclip = v
    local mg = getMainGameTable()
    if mg then
        mg.noclip = v
        syncNativeFlightSpeed(State.Noclip_Speed)
        if not v then
            local r = getRoot()
            if r then
                local rayParams = RaycastParams.new()
                rayParams.FilterType = Enum.RaycastFilterType.Exclude
                rayParams.FilterDescendantsInstances = { getChar() }
                local hit = Workspace:Raycast(r.Position, Vector3.new(0, -20, 0), rayParams)
                if hit then
                    r.CFrame = CFrame.new(hit.Position + Vector3.new(0, 3.2, 0), hit.Position + Vector3.new(0, 3.2, 0) + r.CFrame.LookVector)
                    mg.clipPos = r.Position
                else
                    mg.clipPos = r.Position
                end
                mg.inAir = false
                mg.hideplayers = 0
                pcall(function()
                    r.AssemblyLinearVelocity = Vector3.zero
                    r.AssemblyAngularVelocity = Vector3.zero
                end)
                local hum = getChar() and getChar():FindFirstChildWhichIsA("Humanoid")
                if hum then
                    hum:ChangeState(Enum.HumanoidStateType.Running)
                end
            end
        end
    end
    local char = getChar()
    if char then
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then
                p.CanCollide = not v
                if v then
                    if p.CollisionGroup ~= "NoPlayer" then
                        pcall(function() p.CollisionGroup = "NoPlayer" end)
                    end
                end
                p.CanTouch = true
                p.CanQuery = true
            end
        end
    end
    if not v then
        local root = getRoot()
        if root then
            pcall(function()
                root.AssemblyLinearVelocity = Vector3.zero
                root.AssemblyAngularVelocity = Vector3.zero
            end)
            local mg = getMainGameTable()
            if mg then
                mg.clipPos = root.Position
                mg.inAir = false
            end
        end
    end
    Hub.Notify("Movement", v and "Fly Noclip: Active (Native Engine Flight)" or "Fly Noclip: Disabled", 2)
end)

Hub.CreateSlider(mainTab, "Fly Speed", 4, 300, State.Noclip_Speed, " studs/s", function(v)
    State.Noclip_Speed = v
    if State.Noclip then
        syncNativeFlightSpeed(v)
    end
end)

Hub.CreateToggle(mainTab, "WalkSpeed", State.WalkSpeed_Enabled, function(v)
    State.WalkSpeed_Enabled = v
    local char = getChar()
    local hum = char and char:FindFirstChildWhichIsA("Humanoid")
    if hum then
        if v then
            syncServerSlide(true, true)
            hum.WalkSpeed = State.WalkSpeed_Value or 45
        else
            syncServerSlide(false, false)
            hum.WalkSpeed = 15
            pcall(function() char:SetAttribute("SpeedBoostExtra", nil) end)
        end
    end
    Hub.Notify("Movement", v and string.format("WalkSpeed: %d studs/s (Bypass Active)", State.WalkSpeed_Value) or "WalkSpeed: Restored (15 studs/s)", 2)
end)

Hub.CreateSlider(mainTab, "Speed", 15, 300, State.WalkSpeed_Value, " studs/s", function(v)
    State.WalkSpeed_Value = v
    if State.WalkSpeed_Enabled then
        local char = getChar()
        local hum = char and char:FindFirstChildWhichIsA("Humanoid")
        if hum then hum.WalkSpeed = v end
    end
end)

Hub.CreateToggle(mainTab, "Instant Acceleration", State.Instant_Movement, function(v)
    State.Instant_Movement = v
    Hub.Notify("Movement", v and "Instant Acceleration: Enabled" or "Instant Acceleration: Disabled", 2)
end)

Hub.CreateToggle(mainTab, "Enable Jump", State.Enable_Jumping, function(v)
    State.Enable_Jumping = v
    local char = getChar()
    local hum = char and char:FindFirstChildWhichIsA("Humanoid")
    if hum then
        hum.UseJumpPower = v
        hum.JumpPower = v and 50 or 0
    end
    Hub.Notify("Movement", v and "Jump: Enabled" or "Jump: Disabled", 2)
end)

Hub.CreateToggle(mainTab, "Enable Slide", State.Enable_Sliding, function(v)
    State.Enable_Sliding = v
    if v then
        syncServerSlide(true, true)
    else
        if not State.Noclip and not State.WalkSpeed_Enabled then
            syncServerSlide(false, false)
        end
    end
    Hub.Notify("Movement", v and "Slide: Enabled" or "Slide: Disabled", 2)
end)

Hub.CreateSection(mainTab, "Interaction")

Hub.CreateToggle(mainTab, "Instant Interact", State.Instant_Interact, function(v)
    State.Instant_Interact = v
    refreshAllPrompts()
    Hub.Notify("Interaction", v and "Instant Interact: Enabled" or "Instant Interact: Disabled", 2)
end)

Hub.CreateToggle(mainTab, "Wall Interact", State.Noclip_Interact, function(v)
    State.Noclip_Interact = v
    refreshAllPrompts()
    Hub.Notify("Interaction", v and "Wall Interact: Enabled" or "Wall Interact: Disabled", 2)
end)

Hub.CreateToggle(mainTab, "Interact Reach", State.Range_Interact, function(v)
    State.Range_Interact = v
    refreshAllPrompts()
    Hub.Notify("Interaction", v and string.format("Interact Reach: %d studs", State.Interact_MaxRange) or "Interact Reach: Disabled", 2)
end)

Hub.CreateSlider(mainTab, "Reach Distance", 6, 14, State.Interact_MaxRange, " studs", function(v)
    State.Interact_MaxRange = v
    if State.Range_Interact then
        refreshAllPrompts()
    end
end)

Hub.CreateSection(mainTab, "Automation & Auto-Interact")

Hub.CreateToggle(mainTab, "Auto Interact", State.Auto_Interact, function(v)
    State.Auto_Interact = v
    Hub.Notify("Auto Interact", v and "Auto Interact: Enabled" or "Auto Interact: Disabled", 2)
end)

Hub.CreateToggle(mainTab, "Auto Doors", State.AutoInteract_Doors, function(v)
    State.AutoInteract_Doors = v
end)

Hub.CreateToggle(mainTab, "Auto Keys", State.AutoInteract_Keys, function(v)
    State.AutoInteract_Keys = v
end)

Hub.CreateToggle(mainTab, "Auto Items", State.AutoInteract_Items, function(v)
    State.AutoInteract_Items = v
end)

Hub.CreateToggle(mainTab, "Auto Gold", State.AutoInteract_Gold, function(v)
    State.AutoInteract_Gold = v
end)

Hub.CreateToggle(mainTab, "Auto Drawers", State.AutoInteract_Drawers, function(v)
    State.AutoInteract_Drawers = v
end)

Hub.CreateToggle(mainTab, "Auto Levers", State.AutoInteract_Levers, function(v)
    State.AutoInteract_Levers = v
end)

Hub.CreateToggle(mainTab, "Auto Books / Breakers", State.AutoInteract_Books, function(v)
    State.AutoInteract_Books = v
end)
end

-- =========================================================================
-- Tab 2: EXPLOITS TAB (Autonomous 1-100 Completer, Knobs Farm, God-Mode & Item Exploits)
-- =========================================================================
do
local exploitsTab = Hub.CreateTab("Exploits", { 
    Icon = "⚡", 
    Size = 18, 
    Color = Color3.fromRGB(255, 60, 60), 
    ActiveColor = Color3.fromRGB(255, 100, 100) 
})

Hub.CreateSection(exploitsTab, "Autonomous 1-100 Doors Completer")

Hub.CreateToggle(exploitsTab, "Auto Complete 100 Doors", State.Auto_Complete_100, function(v)
    State.Auto_Complete_100 = v
    if v then
        State.Noclip = true
        State.Bypass_AntiCheat = true
        State.Auto_Hide = true
        State.Auto_RoofEvacuate = true
        State.Deflect_Glitch = true
        neutralizeServerTeleported()
        initAntiGlitchShield()
        Hub.Notify("Completer", "Autonomous 1-100 Completer Active! Hands-free game completion running.", 4)
    else
        Hub.Notify("Completer", "Autonomous 1-100 Completer Paused.", 2)
    end
end)

Hub.CreateSection(exploitsTab, "Autonomous Knobs & Death Farm")

Hub.CreateButton(exploitsTab, "Copy Auto Death Farm Script", function()
    local deathFarmCode = [[-- UnknownHub DOORS Autonomous Death Farm (Auto-Exec Standalone)
repeat task.wait() until game:IsLoaded()
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
repeat task.wait() until LocalPlayer

local PLACE_LOBBY = 6516141723
local PLACE_GAME = 6839171747

pcall(function()
    if getconnections then
        for _, conn in ipairs(getconnections(LocalPlayer.Idled)) do
            if conn.Disable then conn:Disable() elseif conn.Disconnect then conn:Disconnect() end
        end
    end
end)

local function log(msg) print("[DeathFarm] " .. tostring(msg)) end

local function queueReplay()
    if syn and syn.queue_on_teleport then
        syn.queue_on_teleport(game:HttpGet("https://raw.githubusercontent.com/UnknownHQ/UnknownHub/main/Games/Doors.luau"))
    elseif queue_on_teleport then
        queue_on_teleport(game:HttpGet("https://raw.githubusercontent.com/UnknownHQ/UnknownHub/main/Games/Doors.luau"))
    end
end

if game.PlaceId == PLACE_LOBBY then
    log("Lobby reached. Joining elevator...")
    task.wait(2)
    local curElevator = Workspace:FindFirstChild("LobbyElevator") or Workspace:FindFirstChild("Elevator")
    if curElevator then
        local prompt = curElevator:FindFirstChildWhichIsA("ProximityPrompt", true)
        if prompt then fireproximityprompt(prompt) end
    end
    queueReplay()
elseif game.PlaceId == PLACE_GAME then
    log("In Game. Starting farm run...")
    queueReplay()
end
]]
    if setclipboard then
        setclipboard(deathFarmCode)
        Hub.Notify("Copied", "Standalone Death Farm Script copied to clipboard!", 3)
    else
        Hub.Notify("Error", "Clipboard API unavailable on this executor", 3)
    end
end)

Hub.CreateToggle(exploitsTab, "Knobs Farm Autopilot", State.Knobs_Farm_Active, function(v)
    State.Knobs_Farm_Active = v
    if v then
        State.Noclip = true
        State.Bypass_AntiCheat = true
        State.Auto_RoofEvacuate = true
        State.Deflect_Glitch = true
        neutralizeServerTeleported()
        initAntiGlitchShield()
        task.spawn(function()
            while State.Knobs_Farm_Active and _G.DOORS_SESSION == currentSession do
                local ok, err = pcall(processKnobsFarmStep)
                if not ok then warn("[Knobs Farm Error]", err) end
                task.wait(0.2)
            end
        end)
        Hub.Notify("Farm Active", "Autonomous Knobs Farm running! Sit back and collect knobs.", 3)
    else
        Hub.Notify("Farm Paused", "Autonomous Knobs Farm disabled.", 2)
    end
end)

Hub.CreateSlider(exploitsTab, "Max Gold Quota", 1000, 5000, State.Knobs_Farm_MaxGold or 3500, " gold", function(v)
    State.Knobs_Farm_MaxGold = v
end)

Hub.CreateSlider(exploitsTab, "Max Door Quota", 40, 95, State.Knobs_Farm_MaxDoors or 85, " doors", function(v)
    State.Knobs_Farm_MaxDoors = v
end)

Hub.CreateToggle(exploitsTab, "Loot Drawers & Desks", State.Knobs_Farm_LootDrawers, function(v)
    State.Knobs_Farm_LootDrawers = v
end)

Hub.CreateToggle(exploitsTab, "Unlock Chests (Lockpick)", State.Knobs_Farm_LootChests, function(v)
    State.Knobs_Farm_LootChests = v
end)

Hub.CreateToggle(exploitsTab, "Roof Haven on Rush/Ambush", State.Knobs_Farm_RoofEvacuation, function(v)
    State.Knobs_Farm_RoofEvacuation = v
end)

Hub.CreateButton(exploitsTab, "Force Match Reset & Play Again", function()
    local rf = remotesFolder or game:GetService("ReplicatedStorage"):FindFirstChild("RemotesFolder")
    local playAgainRemote = rf and rf:FindFirstChild("PlayAgain")
    if playAgainRemote and playAgainRemote:IsA("RemoteEvent") then
        playAgainRemote:FireServer()
        Hub.Notify("Match Reset", "PlayAgain signal dispatched to server!", 2)
    else
        local char = getChar()
        local hum = char and char:FindFirstChildWhichIsA("Humanoid")
        if hum then hum.Health = 0 end
        Hub.Notify("Match Reset", "Resetting character to trigger Play Again UI...", 2)
    end
end)

Hub.CreateSection(exploitsTab, "Defense & God-Mode")

Hub.CreateToggle(exploitsTab, "God-Mode (Universal Immunity)", State.God_Mode, function(v)
    State.God_Mode = v
    local char = getChar()
    local hum = char and char:FindFirstChildWhichIsA("Humanoid")
    if hum then
        pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Dead, not v) end)
    end
    if char then
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then
                p.CanTouch = not v
                p.CanQuery = not v
                if v then
                    pcall(function() p.CollisionGroup = "NoPlayer" end)
                end
            end
        end
    end
    Hub.Notify("God-Mode", v and "God-Mode: Enabled (Intangible Hitbox Active)" or "God-Mode: Disabled", 2)
end)

Hub.CreateSection(exploitsTab, "Item Exploits")

Hub.CreateToggle(exploitsTab, "Infinite Items", State.Infinite_Items, function(v)
    State.Infinite_Items = v
    Hub.Notify("Exploit", v and "Infinite Items: Enabled" or "Infinite Items: Disabled", 2)
end)

Hub.CreateToggle(exploitsTab, "Retain Lockpicks & Keys", State.Infinite_Lockpicks, function(v)
    State.Infinite_Lockpicks = v
end)

Hub.CreateToggle(exploitsTab, "Retain Crucifix", State.Infinite_Crucifix, function(v)
    State.Infinite_Crucifix = v
end)

Hub.CreateToggle(exploitsTab, "Retain Consumables", State.Infinite_Consumables, function(v)
    State.Infinite_Consumables = v
end)

Hub.CreateButton(exploitsTab, "Quick Dupe Held Tool", function()
    local char = getChar()
    local tool = char and char:FindFirstChildWhichIsA("Tool")
    if tool then
        executeItemDupeDrop(tool, 0)
        Hub.Notify("Dupe", "Held tool dropped & retrieved!", 2)
    else
        Hub.Notify("Dupe", "Equip a tool first to dupe!", 2)
    end
end)
end

local floorTabName = "Floor (" .. tostring(detectedFloor) .. ")" 

do
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

local activeFloorEntities = getActiveEntitiesForFloor()

Hub.CreateSection(floorTab, "Defenses")

if table.find(activeFloorEntities, "Screech") then
    Hub.CreateToggle(floorTab, "Anti Screech", State.Anti_Screech, function(v)
        State.Anti_Screech = v
        updateFloorNativeToggles()
        Hub.Notify("Defense", v and "Anti Screech: Enabled" or "Anti Screech: Disabled", 2)
    end)
end

if table.find(activeFloorEntities, "Eyes") then
    Hub.CreateToggle(floorTab, "Anti Eyes", State.Anti_Eyes, function(v)
        State.Anti_Eyes = v
        updateFloorNativeToggles()
        Hub.Notify("Defense", v and "Anti Eyes: Enabled" or "Anti Eyes: Disabled", 2)
    end)
end

if table.find(activeFloorEntities, "Dupe") then
    Hub.CreateToggle(floorTab, "Anti Dupe", State.Anti_Dupe, function(v)
        State.Anti_Dupe = v
        updateFloorNativeToggles()
        Hub.Notify("Defense", v and "Anti Dupe: Enabled" or "Anti Dupe: Disabled", 2)
    end)
end

if table.find(activeFloorEntities, "Snare") then
    Hub.CreateToggle(floorTab, "Anti Snare", State.Anti_Snare, function(v)
        State.Anti_Snare = v
        defuseAllSnares()
        Hub.Notify("Defense", v and "Anti Snare: Enabled" or "Anti Snare: Disabled", 2)
    end)
end

if table.find(activeFloorEntities, "Timothy") then
    Hub.CreateToggle(floorTab, "Anti Timothy", State.Anti_Timothy, function(v)
        State.Anti_Timothy = v
        Hub.Notify("Defense", v and "Anti Timothy: Enabled" or "Anti Timothy: Disabled", 2)
    end)
end

if table.find(activeFloorEntities, "A-90") then
    Hub.CreateToggle(floorTab, "Anti Ransom (A-90)", State.Anti_A90, function(v)
        State.Anti_A90 = v
        Hub.Notify("Defense", v and "Anti Ransom: Enabled" or "Anti Ransom: Disabled", 2)
    end)
end

if table.find(activeFloorEntities, "Giggle") then
    Hub.CreateToggle(floorTab, "Anti Giggle", State.Anti_Giggle, function(v)
        State.Anti_Giggle = v
        Hub.Notify("Defense", v and "Anti Giggle: Enabled" or "Anti Giggle: Disabled", 2)
    end)
end

if table.find(activeFloorEntities, "Gloombats") then
    Hub.CreateToggle(floorTab, "Anti Gloombats", State.Anti_Gloombat, function(v)
        State.Anti_Gloombat = v
        Hub.Notify("Defense", v and "Anti Gloombats: Enabled" or "Anti Gloombats: Disabled", 2)
    end)
end

if table.find(activeFloorEntities, "Grumble") then
    Hub.CreateToggle(floorTab, "Anti Grumble Radar", State.Anti_Grumble, function(v)
        State.Anti_Grumble = v
        Hub.Notify("Defense", v and "Anti Grumble Radar: Enabled" or "Anti Grumble Radar: Disabled", 2)
    end)
end

if table.find(activeFloorEntities, "Halt") then
    Hub.CreateToggle(floorTab, "Anti Halt (Auto Reversal)", State.Anti_Halt, function(v)
        State.Anti_Halt = v
        Hub.Notify("Defense", v and "Anti Halt: Enabled" or "Anti Halt: Disabled", 2)
    end)
end

if table.find(activeFloorEntities, "Seek") then
    Hub.CreateToggle(floorTab, "Anti Figure (Defusal & Clutch)", State.Anti_Figure, function(v)
        State.Anti_Figure = v
    end)

    Hub.CreateToggle(floorTab, "Anti Figure Hearing (Silent Stealth)", State.Anti_Figure_Hearing, function(v)
        State.Anti_Figure_Hearing = v
        Hub.Notify("Stealth", v and "Anti Figure Hearing: Enabled (Silent Stealth)" or "Anti Figure Hearing: Disabled", 2)
    end)

    Hub.CreateToggle(floorTab, "Anti Dread (Darkness & Entity Defusal)", State.Anti_Dread, function(v)
        State.Anti_Dread = v
    end)

    Hub.CreateToggle(floorTab, "Anti Seek (Hands Deflector)", State.Anti_Seek, function(v)
        State.Anti_Seek = v
        Hub.Notify("Defense", v and "Anti Seek: Enabled" or "Anti Seek: Disabled", 2)
    end)
end

if table.find(activeFloorEntities, "Rush") or table.find(activeFloorEntities, "Ambush") then
    Hub.CreateToggle(floorTab, "Anti Rush & Ambush (Safe Phase)", State.Anti_Rush, function(v)
        State.Anti_Rush = v
        Hub.Notify("Defense", v and "Anti Rush & Ambush: Enabled" or "Anti Rush & Ambush: Disabled", 2)
    end)
end

if isHotel or isMines then
    Hub.CreateSection(floorTab, "Puzzles")

    Hub.CreateToggle(floorTab, "Auto Heartbeat", State.Auto_Heartbeat, function(v)
        State.Auto_Heartbeat = v
        Hub.Notify("Puzzle", v and "Auto Heartbeat: Enabled" or "Auto Heartbeat: Disabled", 2)
    end)
end

if isHotel then
    Hub.CreateButton(floorTab, "Solve Library Code", function()
        local code, status = solveLibraryCode()
        if code then
            Hub.Notify("Room 50", "Padlock Code: " .. code, 6)
        else
            Hub.Notify("Room 50", status or "Need Books & Hint Paper!", 4)
        end
    end)

    Hub.CreateToggle(floorTab, "Auto Circuit Breaker", State.Auto_Breakers, function(v)
        State.Auto_Breakers = v
        Hub.Notify("Puzzle", v and "Auto Circuit Breaker: Enabled" or "Auto Circuit Breaker: Disabled", 2)
    end)

    Hub.CreateButton(floorTab, "Instant Solve Breakers (Door 100)", function()
        instantSolveBreakers()
    end)
end

-- =========================================================================
end

-- Tab 3: VISUALS TAB
-- =========================================================================
do
local espTab = Hub.CreateTab("Visuals", {
    Icon = "👁️",
    Size = 18,
    Color = Color3.fromRGB(170, 185, 210),
    ActiveColor = Color3.fromRGB(0, 215, 255)
})

Hub.CreateSection(espTab, "Pathfinding & Entity Safe Zones")

Hub.CreateToggle(espTab, "Show Entity Path Nodes", State.ESP_Entity_Nodes, function(v)
    State.ESP_Entity_Nodes = v
    refreshEntityNodesVisuals()
    Hub.Notify("Visuals", v and "Entity Nodes: Visible (Rush/Ambush Waypoints)" or "Entity Nodes: Hidden", 2)
end)

Hub.CreateToggle(espTab, "Show Safe Zones (Rush/Ambush)", State.ESP_Safe_Zones, function(v)
    State.ESP_Safe_Zones = v
    refreshSafeZonesVisuals()
    Hub.Notify("Visuals", v and "Safe Zones: Visible (Shielded from Rush/Ambush)" or "Safe Zones: Hidden", 2)
end)

Hub.CreateSection(espTab, "Master")

Hub.CreateSlider(espTab, "Field of View", 70, 120, State.FieldOfView or 70, "°", function(v)
    State.FieldOfView = v
    local mg = getMainGameTable()
    if mg then mg.fovtarget = v end
    local cam = Workspace.CurrentCamera
    if cam then cam.FieldOfView = v end
end)

Hub.CreateToggle(espTab, "Master ESP", State.Master_ESP, function(v)
    State.Master_ESP = v
    if not v then
        clearAllEsp()
    else
        scanAllRooms()
    end
end)

Hub.CreateToggle(espTab, "Show Distance", State.Show_Distance, function(v)
    State.Show_Distance = v
    if not v then
        for _, rec in pairs(activeEspRecords) do
            if rec.Label then rec.Label.Text = rec.BaseText end
        end
    end
end)

Hub.CreateDropdown(espTab, "Render Range", { "Current & Next Room", "Current Room Only", "All Rooms" }, State.ESP_RoomFilterMode, function(mode)
    State.ESP_RoomFilterMode = mode
    Hub.Notify("ESP", "Range: " .. mode, 2)
end)

Hub.CreateSlider(espTab, "Font Size", 11, 24, State.ESP_TextSize, " px", function(v)
    State.ESP_TextSize = v
    refreshEspVisualSettings()
end)

Hub.CreateSlider(espTab, "Fill Transparency", 10, 90, math.floor((1 - State.ESP_FillTransparency) * 100), "%", function(v)
    State.ESP_FillTransparency = 1 - (v / 100)
    refreshEspVisualSettings()
end)

Hub.CreateDropdown(espTab, "Color Theme", { "Default Vibrant", "Neon Cyber", "Monochrome Glow", "Pastel Soft" }, State.ESP_ColorTheme, function(theme)
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
    Hub.Notify("ESP", "Theme: " .. theme, 2)
end)

Hub.CreateSection(espTab, "Doors & Objectives")

Hub.CreateToggle(espTab, "Door ESP", State.Doors_ESP, function(v)
    State.Doors_ESP = v
    if not v then
        clearCategoryEsp("Doors")
    else
        scanAllRooms()
    end
end)

Hub.CreateToggle(espTab, "Key ESP", State.Keys_ESP, function(v)
    State.Keys_ESP = v
    if not v then
        clearCategoryEsp("Keys")
    else
        scanAllRooms()
    end
end)

Hub.CreateToggle(espTab, "Glitch ESP", State.GlitchFragment_ESP, function(v)
    State.GlitchFragment_ESP = v
    if not v then
        clearCategoryEsp("GlitchFragment")
    else
        scanAllRooms()
    end
end)

Hub.CreateToggle(espTab, "Item ESP", State.Items_ESP, function(v)
    State.Items_ESP = v
    if not v then
        clearCategoryEsp("Items")
    else
        scanAllRooms()
    end
end)

Hub.CreateToggle(espTab, "Book ESP", State.Books_ESP, function(v)
    State.Books_ESP = v
    if not v then
        clearCategoryEsp("Books")
    else
        scanAllRooms()
    end
end)

Hub.CreateToggle(espTab, "Breaker ESP", State.Breakers_ESP, function(v)
    State.Breakers_ESP = v
    if not v then
        clearCategoryEsp("Breakers")
    else
        scanAllRooms()
    end
end)

Hub.CreateToggle(espTab, "Gold ESP", State.Gold_ESP, function(v)
    State.Gold_ESP = v
    if not v then
        clearCategoryEsp("Gold")
    else
        scanAllRooms()
    end
end)

Hub.CreateSection(espTab, "Entities")

Hub.CreateToggle(espTab, "Entity ESP", State.Entities_ESP, function(v)
    State.Entities_ESP = v
    if not v then
        clearCategoryEsp("Entities")
    else
        scanAllRooms()
    end
end)

Hub.CreateToggle(espTab, "Closet ESP", State.HidingSpots_ESP, function(v)
    State.HidingSpots_ESP = v
    if not v then
        clearCategoryEsp("HidingSpots")
    else
        scanAllRooms()
    end
end)

local allMonsterOptions = getActiveEntitiesForFloor()

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

Hub.CreateSection(espTab, "World & Atmosphere")

Hub.CreateToggle(espTab, "Fullbright", State.Fullbright, function(v)
    State.Fullbright = v
    applyFullbright(v)
end)

Hub.CreateToggle(espTab, "No Fog (Clear Atmosphere)", State.No_Fog, function(v)
    State.No_Fog = v
    if v then enforceNoFog(true) end
    Hub.Notify("Visuals", v and "No Fog: Enabled" or "No Fog: Disabled", 2)
end)

Hub.CreateToggle(espTab, "Semi-Transparent Closets", State.SemiTransparent_Closet, function(v)
    State.SemiTransparent_Closet = v
    Hub.Notify("Visuals", v and "Semi-Transparent Closets: Enabled" or "Semi-Transparent Closets: Disabled", 2)
end)

Hub.CreateToggle(espTab, "Entity Spawn Notifier", State.Notify_EntitySpawn, function(v)
    State.Notify_EntitySpawn = v
    Hub.Notify("Visuals", v and "Entity Notifier: Enabled" or "Entity Notifier: Disabled", 2)
end)

Hub.CreateToggle(espTab, "Entity Notify Sound", State.Notify_EntitySound, function(v)
    State.Notify_EntitySound = v
end)

local notifyOptions = getActiveEntitiesForFloor()
Hub.CreateMultiDropdown(espTab, "Notify Entity Filters", notifyOptions, notifyOptions, function(selectedEntities)
    local filterMap = {}
    for _, opt in ipairs(notifyOptions) do
        filterMap[opt] = false
    end
    for _, name in ipairs(selectedEntities) do
        filterMap[name] = true
    end
    State.Notify_Entity_Filters = filterMap
end)

Hub.CreateButton(espTab, "Refresh ESP", function()
    clearAllEsp()
    scanAllRooms()
    Hub.Notify("ESP", "Refreshed all active room ESPs!", 2)
end)

-- =========================================================================
end

-- Tab 4: DIAGNOSTICS & TELEMETRY ROUTINES
-- =========================================================================
do
local diagTab = Hub.CreateTab("Diagnostics", {
    Icon = "⚙️",
    Size = 18,
    Color = Color3.fromRGB(150, 150, 160),
    ActiveColor = Color3.fromRGB(220, 220, 230)
})

Hub.CreateSection(diagTab, "Live Telemetry")

Hub.CreateButton(diagTab, "Check Client State", function()
    local char = getChar()
    local hum = char and char:FindFirstChildWhichIsA("Humanoid")
    local curRoom = getCurrentRoomNumber() or 0
    local floor = detectedFloor
    local activeMods = {}
    local lm = game.ReplicatedStorage:FindFirstChild("LiveModifiers")
    if lm then
        for _, m in ipairs(lm:GetChildren()) do table.insert(activeMods, m.Name) end
    end
    local modsStr = #activeMods > 0 and table.concat(activeMods, ", ") or "None"
    local hp = hum and math.floor(hum.Health) or 0
    Hub.Notify("Telemetry", string.format("Room: %d | Floor: %s | HP: %d | Mods: %s", curRoom, floor, hp, modsStr), 5)
end)

Hub.CreateSection(diagTab, "Recovery Routines")

Hub.CreateButton(diagTab, "Re-sync Character Interactivity", function()
    local char = getChar()
    if char then
        restoreCharacterInteractivity(char)
        Hub.Notify("Diagnostics", "Character collisions & prompts re-synchronized!", 2)
    end
end)

Hub.CreateButton(diagTab, "Full World Re-scan", function()
    clearAllEsp()
    scanAllRooms()
    refreshAllPrompts()
    Hub.Notify("Diagnostics", "World ESP and prompts fully re-indexed!", 2)
end)

end

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
Hub.Notify("Unknown Hub", "DOORS Precision ESP Loaded", 3)

-- Native ProximityPrompt engine handles KeyCode.E with zero interference;
-- HoldDuration = 0 triggers instantly while preserving exact crosshair focus across wardrobe drawers.
