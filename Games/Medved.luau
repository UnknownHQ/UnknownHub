--------------------------------------------------------------------------------
-- UNKNOWN HUB: MEDVED! (Hunt & Become Bears)
-- PlaceId: 132273534230449 | GameId: 7144947546
-- Complete Suite V4:
--   • Auto Farm Crates (Single-Target Lock, Atomic In-Place Loot Sweep)
--   • Auto Collect All Pages (32 Map Pages)
--   • Combat: Melee Hit Aura, Gun Hit Aura, Infinite Ammo, No Spread, Full Auto
--   • Movement: Infinite Stamina, Undetectable WalkSpeed Modifier
--   • Visuals: Crates ESP, Bears ESP (NPCs & Player Bears with HP & Distance)
--   • Teleports: Dynamic Physical Landmark Resolver (Zero Random Landings)
-- Security: Full Packet.Write hook & zero-mover stealth architecture
--------------------------------------------------------------------------------

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local LocalPlayer = Players.LocalPlayer

--------------------------------------------------------------------------------
-- 1. TELEMETRY NEUTRALIZATION LAYER
--------------------------------------------------------------------------------
local function silenceTelemetry()
    pcall(function()
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        local clientInterface = playerGui and playerGui:FindFirstChild("ClientInterface")
        local mainScript = clientInterface and clientInterface:FindFirstChild("ClientInterface")

        if mainScript then
            local packetModule = mainScript:FindFirstChild("Packet")
            if packetModule then
                local Packet = require(packetModule)
                if not Packet.__ORIGINAL_WRITE then
                    Packet.__ORIGINAL_WRITE = Packet.Write
                    Packet.Write = function(p14, p15, p16, p17, ...)
                        if p17 and typeof(p17) == "table" and p17.Reports then
                            table.clear(p17.Reports)
                        end
                        return Packet.__ORIGINAL_WRITE(p14, p15, p16, p17, ...)
                    end
                end
            end

            local event = clientInterface:FindFirstChild("Event")
            if event and event:IsA("BindableEvent") then
                for _, conn in ipairs(getconnections(event.Event)) do
                    pcall(function() conn:Disable() end)
                end
            end
        end
    end)
end

silenceTelemetry()
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    silenceTelemetry()
end)

--------------------------------------------------------------------------------
-- 2. LIBRARY INITIALIZATION
--------------------------------------------------------------------------------
local function getValidatedLibrary()
    local lib = getgenv().UnknownLibrary
    local isValid = false
    if lib and typeof(lib) == "function" then
        pcall(function()
            local test = lib({ title = "_T", game = "_T" })
            if test and test.CreateMultiDropdown then
                isValid = true
            end
            if test and test.destroy then test.destroy() end
            if test and test.screenGui then test.screenGui:Destroy() end
        end)
    end
    if isValid then return lib end

    -- Try local file in Bunni/scripts
    pcall(function()
        if readfile then
            local localSrc = readfile("UnknownLibrary.luau") or readfile("scripts/UnknownLibrary.luau")
            if localSrc and localSrc ~= "" then
                local fn = loadstring(localSrc)
                if fn then lib = fn() end
            end
        end
    end)

    -- If still not valid, fetch fresh from GitHub
    if not lib or typeof(lib) ~= "function" then
        pcall(function()
            local webSrc = game:HttpGet("https://raw.githubusercontent.com/UnknownHQ/UnknownHub/main/UnknownLibrary.luau?t=" .. tick())
            if webSrc and webSrc ~= "" then
                local fn = loadstring(webSrc)
                if fn then lib = fn() end
            end
        end)
    end

    getgenv().UnknownLibrary = lib
    return lib
end

local UnknownLibrary = getValidatedLibrary()

if not UnknownLibrary then
    warn("[UnknownHub] Could not load UnknownLibrary! Falling back to raw execution.")
    return
end

local createHubFn = typeof(UnknownLibrary) == "function" and UnknownLibrary or (UnknownLibrary.CreateHub or UnknownLibrary.createHub)
local Hub = createHubFn({
    title = "UNKNOWN HUB",
    game = "MEDVED! 🐻",
    theme = Color3.fromRGB(0, 195, 245),
    secondaryTheme = Color3.fromRGB(165, 95, 255)
})

--------------------------------------------------------------------------------
-- 3. STATE & CONFIGURATION
--------------------------------------------------------------------------------
local Config = {
    -- Auto Farm
    AutoFarmCrates = false,
    AutoCollectPages = false,
    FarmDelay = 0.5,
    AutoServerhop = false,

    -- Auto Farm Bears Suite
    AutoFarmBears = false,
    FarmMethod = "Gun", -- "Gun", "Melee", or "Bear Attack"
    SpawnAsBear = "booboo",
    AutoFriendlyBear = true,
    SelectedBears = { ["All"] = true },
    SelectedBearTarget = "All",
    SafeZoneLowHP = true,
    LowHPThreshold = 25,

    -- Combat
    MeleeAura = false,
    MeleeAuraRange = 18,
    GunAura = false,
    GunAuraRange = 90,
    PriorityBears = { ["GrinderBear"] = true, ["Grinder"] = true },

    -- Movement & Stamina
    InfiniteStamina = false,
    CustomSpeed = 14.1,
    FlyNoclip = false,
    FlySpeed = 45,

    -- Visuals
    CratesESP = false,
    BearsESP = false,
    TurretsESP = false,

    -- Combat: Turret & Sentry Automation
    AutoHealTurrets = false,

    -- Misc & Progression
    AutoUnlockDoors = false,
    AutoPrestigeOn32 = false,
    AntiRagdoll = false
}

local activeESP = {}
local activeBearESP = {}
local crateAttempts = {}
local blacklistedCrates = {}
local openedCrates = {}

--------------------------------------------------------------------------------
-- 4. UTILITIES & TELEPORT RESOLVER
--------------------------------------------------------------------------------
local function triggerPrompt(prompt)
    if not prompt or not prompt.Enabled then return false end

    pcall(function()
        if fireproximityprompt then
            fireproximityprompt(prompt)
        end
    end)

    pcall(function()
        if getconnections then
            for _, con in ipairs(getconnections(prompt.Triggered)) do
                if con and con.Fire then
                    con:Fire()
                elseif con and con.Function then
                    con.Function()
                end
            end
        end
    end)
    return true
end

-- Dynamic Landmark Resolver: finds the real physical ground parts of every location
local locationRegistry = {
    { name = "Main Base (Spawn)", target = "TheBase", fallback = Vector3.new(52, -137, -144) },
    { name = "Old Statue (Lenin)", target = "LeninStatue", fallback = Vector3.new(-398.5, -124.0, -685.0) },
    { name = "Signal Tower", target = "SignalTower", fallback = Vector3.new(-626, -114, 443) },
    { name = "The Maze (Entrance)", target = "TheMazeEntrance", fallback = Vector3.new(20, -130, -185) },
    { name = "The Maze (End)", target = "TheMazeEnd", fallback = Vector3.new(1140.9, -144.9, 73.1) },
    { name = "Research Facility", target = "OutsideResearchFacility", fallback = Vector3.new(-17, -136, -396) },
    { name = "Star Lab", target = "Star Lab", fallback = Vector3.new(-300, -112, 850) },
    { name = "Plane Crash", target = "Plane", fallback = Vector3.new(325, -143, -63) },
    { name = "The Bunker", target = "Bunker", fallback = Vector3.new(-699, -112, -664) },
    { name = "Mineshaft", target = "Mineshaft", fallback = Vector3.new(-850, -120, -350) },
    { name = "Main Cave Entrance", target = "Caves", fallback = Vector3.new(-28, -122, 397) },
    { name = "Graveyard", target = "Graveyard", fallback = Vector3.new(12, -123, -878) }
}

local function resolveLocationPosition(item)
    if item.target == "TheMazeEntrance" then
        local poi = Workspace:FindFirstChild("TaggedAreas") and Workspace.TaggedAreas:FindFirstChild("PointsOfInterest") and Workspace.TaggedAreas.PointsOfInterest:FindFirstChild("TheMaze")
        if poi then
            return poi:GetPivot().Position + Vector3.new(0, 3.5, 0)
        end
        return item.fallback + Vector3.new(0, 3.5, 0)
    elseif item.target == "TheMazeEnd" then
        -- Final Chamber: Teleport to the end where the bells and 5 crates are located
        local chamberPos = Vector3.new(1140.9, -144.9, 73.1)
        local cratesFolder = Workspace:FindFirstChild("Crates")
        if cratesFolder then
            for _, c in ipairs(cratesFolder:GetChildren()) do
                local cp = c:FindFirstChild("Crate") or c.PrimaryPart or c:FindFirstChildWhichIsA("BasePart")
                if cp and (cp.Position - chamberPos).Magnitude < 75 then
                    return cp.Position + Vector3.new(0, 3.5, 0)
                end
            end
        end
        return chamberPos + Vector3.new(0, 3.5, 0)
    elseif item.target == "LeninStatue" then
        local poi = Workspace:FindFirstChild("TaggedAreas") and Workspace.TaggedAreas:FindFirstChild("PointsOfInterest") and Workspace.TaggedAreas.PointsOfInterest:FindFirstChild("LeninStatue")
        if poi then
            -- Position safely in open courtyard in front of statue
            return poi.Position + Vector3.new(0, 2.0, 21.5)
        end
        return item.fallback + Vector3.new(0, 2.0, 0)
    end

    local map = Workspace:FindFirstChild("Map")
    if map and item.target then
        local folder = map:FindFirstChild(item.target)
        if folder then
            if item.target == "TheBase" then
                local spawnLoc = folder:FindFirstChild("SpawnLocation", true)
                if spawnLoc then return spawnLoc.Position + Vector3.new(0, 3.5, 0) end
            end
            for _, d in ipairs(folder:GetDescendants()) do
                if d:IsA("BasePart") and d.CanCollide and d.Size.Magnitude > 3 and not d.Name:lower():find("leaves") and not d.Name:lower():find("roof") and not d.Name:lower():find("wall") then
                    return d.Position + Vector3.new(0, 3.5, 0)
                end
            end
            local anyPart = folder:FindFirstChildWhichIsA("BasePart", true)
            if anyPart then return anyPart.Position + Vector3.new(0, 3.5, 0) end
        end
    end
    return item.fallback + Vector3.new(0, 3.5, 0)
end

local isTeleporting = false

local function safeTeleport(targetPos, locationName)
    if isTeleporting then return end
    isTeleporting = true

    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not char or not root then
        isTeleporting = false
        return
    end

    silenceTelemetry()

    -- 1. Explicit Chunk Streaming Request (Crucial for remote chunks like The Maze End 1,100 studs away)
    pcall(function()
        LocalPlayer:RequestStreamAroundAsync(targetPos)
    end)

    -- 2. Spawn temporary invisible anchored safety landing pad to prevent falling into void during chunk streaming
    local pad = Instance.new("Part")
    pad.Name = "SafeLandingPad"
    pad.Size = Vector3.new(24, 2, 24)
    pad.CFrame = CFrame.new(targetPos - Vector3.new(0, 1.0, 0))
    pad.Anchored = true
    pad.Transparency = 1
    pad.CanCollide = true
    pad.Parent = Workspace

    local spawnOffset = Vector3.new(0, 2.5, 0)
    local destCFrame = CFrame.new(targetPos + spawnOffset)

    -- Anchor-Flash Protocol: Prevents 50/50 physics packet rubberband when walking or sprinting
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    root.Anchored = true
    char:PivotTo(destCFrame)

    task.spawn(function()
        -- Hold anchored across 0.75s to allow terrain and mesh streaming before unanchoring
        local startTime = tick()
        while tick() - startTime < 0.75 do
            RunService.Heartbeat:Wait()
            if root and root.Parent then
                char:PivotTo(destCFrame)
                root.AssemblyLinearVelocity = Vector3.zero
                root.AssemblyAngularVelocity = Vector3.zero
            end
        end

        if root and root.Parent then
            root.Anchored = false
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end

        -- Clean up safety landing pad after 3 seconds
        task.delay(3, function()
            if pad and pad.Parent then
                pad:Destroy()
            end
        end)

        isTeleporting = false
        if locationName then
            Hub.Notify("Teleport", "Arrived at " .. locationName, 2)
        end
    end)
end

--------------------------------------------------------------------------------
-- 5. CRATES AUTOMATION ENGINE & GHOSTBEAR DEFENSE
--------------------------------------------------------------------------------
local isCratesActivelyFarming = false

-- GhostBear Spatial Detection Radar
local function isGhostBearNearPosition(pos, radius)
    radius = radius or 34
    local wsBears = Workspace:FindFirstChild("Bears")
    if not wsBears then return false, math.huge end

    for _, b in ipairs(wsBears:GetChildren()) do
        if b.Name:lower():find("ghost") then
            local bPos = b:GetPivot().Position
            local hrp = b:FindFirstChild("HumanoidRootPart") or b.PrimaryPart
            if hrp then bPos = hrp.Position end
            local d = (bPos - pos).Magnitude
            if d < radius then
                return true, d
            end
        end
    end
    return false, math.huge
end

-- =========================================================================
-- TURRET AUTOMATION, SECURITY OVERRIDE & REMOTE PRESTIGE SUITE
-- =========================================================================

-- 1. Unlock Bunker & All Security Doors (Client Attribute Override)
local function unlockAllDoorsAndBunker()
    LocalPlayer:SetAttribute("BunkerUnlocked", true)
    LocalPlayer:SetAttribute("KeycardAccess", true)
    LocalPlayer:SetAttribute("AccessGranted", true)

    local CollectionService = game:GetService("CollectionService")
    local count = 0
    for _, d in ipairs(CollectionService:GetTagged("Door")) do
        pcall(function()
            d:SetAttribute("Locked", false)
            count = count + 1
        end)
    end
    Hub.Notify("Security Override", "Bunker & " .. count .. " security doors unlocked!", 2.5)
end

-- 2. Prestige Status & Remote Trigger
local function getPrestigeCooldownStatus()
    local pc = Workspace:FindFirstChild("Interactables") and Workspace.Interactables:FindFirstChild("PrestigeComputer")
    local screen = pc and pc:FindFirstChild("ComputerScreen")
    local sg = screen and screen:FindFirstChild("SurfaceGui")
    local tl = sg and sg:FindFirstChild("TextLabel")
    if tl and tl.Text ~= "" then
        local txt = tl.Text
        if txt:find("COOLDOWN") then
            local timeStr = txt:match("%d+:%d+") or txt:gsub("COOLDOWN%s*", "")
            return "On Cooldown: " .. timeStr .. " remaining"
        elseif txt:find("INSERT") or txt:find("UNLOCK") then
            return "READY! (Requires 32 Pages)"
        elseif txt:find("GRANTED") or txt:find("OPEN") then
            return "READY TO PRESTIGE NOW!"
        end
        return txt
    end
    return "Status Unknown (Walk near Lab to stream)"
end

local function triggerRemotePrestige()
    local pc = Workspace:FindFirstChild("Interactables") and Workspace.Interactables:FindFirstChild("PrestigeComputer")
    local pRemote = pc and pc:FindFirstChild("Prestige")
    if not pRemote then
        Hub.Notify("Prestige", "Prestige computer remote not found!", 2.5)
        return
    end

    local ok, res = pcall(function() return pRemote:InvokeServer() end)
    if ok and res == true then
        Hub.Notify("Prestige", "PRESTIGE GRANTED! Resetting with prestige rewards 🌟", 4)
    else
        local status = getPrestigeCooldownStatus()
        Hub.Notify("Prestige Locked", status, 3.5)
    end
end



-- 4. Turret Proximity Auto-Heal Engine
task.spawn(function()
    while true do
        task.wait(0.6)
        if Config.AutoHealTurrets then
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if root and hum and hum.Health > 0 then
                local CollectionService = game:GetService("CollectionService")
                for _, t in ipairs(CollectionService:GetTagged("Turret")) do
                    if t:IsA("Model") and t:IsDescendantOf(Workspace) then
                        local hp = t:GetAttribute("Health")
                        local maxHp = t:GetAttribute("MaxHealth") or 150
                        if hp and maxHp and hp < maxHp then
                            local tPos = t:GetPivot().Position
                            local dist = (root.Position - tPos).Magnitude
                            -- If within proximity repair zone (14 studs), zero velocity to keep steady healing contact
                            if dist <= 14 then
                                root.AssemblyLinearVelocity = Vector3.zero
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- Active GhostBear Neutralization & Visualizer Protocol
task.spawn(function()
    while true do
        task.wait(0.12)
        local wsBears = Workspace:FindFirstChild("Bears")
        if wsBears then
            for _, b in ipairs(wsBears:GetChildren()) do
                if b.Name:lower():find("ghost") then
                    for _, p in ipairs(b:GetDescendants()) do
                        if p:IsA("BasePart") then
                            if p.CanTouch then pcall(function() p.CanTouch = false end) end
                            if p.CanCollide then pcall(function() p.CanCollide = false end) end
                            if p.CanQuery then pcall(function() p.CanQuery = false end) end
                        elseif p:IsA("TouchTransmitter") then
                            pcall(function() p:Destroy() end)
                        end
                    end
                    local sphere = b:FindFirstChild("Sphere") or b:FindFirstChildWhichIsA("BasePart")
                    if sphere and sphere.Transparency >= 0.95 then
                        pcall(function()
                            sphere.Transparency = 0.5
                            sphere.Material = Enum.Material.Neon
                            sphere.Color = Color3.fromRGB(0, 255, 255)
                        end)
                    end
                end
            end
        end
    end
end)

-- Direct Network Remote Invocations for Instant Crate Looting (Zero Identity Demotion)
local sharedEvents = ReplicatedStorage:FindFirstChild("SharedEvents")
local worldEvents = sharedEvents and sharedEvents:FindFirstChild("World")
local openCrateRemote = worldEvents and worldEvents:FindFirstChild("OpenCrate")
local collectItemRemote = worldEvents and worldEvents:FindFirstChild("CollectItem")

local function getCrateItemPrompts(crateModel)
    local prompts = {}
    if not crateModel then return prompts end
    local cratePart = crateModel:FindFirstChild("Crate")
    if not cratePart then return prompts end

    for _, spotName in ipairs({"ItemSpot1", "ItemSpot2", "ItemSpot3"}) do
        local spot = cratePart:FindFirstChild(spotName)
        local prompt = spot and spot:FindFirstChildOfClass("ProximityPrompt")
        if prompt and prompt.Enabled then
            table.insert(prompts, prompt)
        end
    end
    return prompts
end

local function processCrateComplete(crate, mode)
    local cratePart = crate:FindFirstChild("Crate")
    if not cratePart then return false end

    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return false end

    -- GhostBear Pre-Flight Safety Radar: abort if GhostBear is guarding this crate!
    local ghostNear, gDist = isGhostBearNearPosition(cratePart.Position, 32)
    if ghostNear then
        return false
    end

    -- Elevated Hover Stance (+4.0 studs above cratePart) to prevent any lethal ground touch triggers
    local targetCFrame = cratePart.CFrame + Vector3.new(0, 4.0, 0)
    root.CFrame = targetCFrame
    root.AssemblyLinearVelocity = Vector3.zero
    task.wait(0.12)

    -- Dynamic GhostBear evasion check
    if isGhostBearNearPosition(root.Position, 28) then
        root.CFrame = root.CFrame + Vector3.new(0, 18, 0)
        return false
    end

    -- 1. Direct Network Fast-Open Invocation
    if mode == "open" and crate:GetAttribute("Collected") ~= true then
        if openCrateRemote then
            pcall(function()
                openCrateRemote:InvokeServer(crate.Name)
            end)
        end

        local openPrompt = cratePart:FindFirstChild("CratePrompt")
        if openPrompt and openPrompt.Enabled then
            triggerPrompt(openPrompt)
        end
        task.wait(0.08)
    end

    -- 2. Direct Network Fast-Loot Invocations for Slots 1, 2, 3
    if collectItemRemote then
        for slot = 1, 3 do
            pcall(function()
                collectItemRemote:InvokeServer(crate.Name, slot)
            end)
        end
    end

    -- 3. Prompt Fallback Sweep for any stubborn items
    local activePrompts = getCrateItemPrompts(crate)
    if #activePrompts > 0 then
        for _, prompt in ipairs(activePrompts) do
            if isGhostBearNearPosition(root.Position, 28) then
                root.CFrame = root.CFrame + Vector3.new(0, 18, 0)
                return false
            end
            root.CFrame = targetCFrame
            root.AssemblyLinearVelocity = Vector3.zero
            triggerPrompt(prompt)
            task.wait(0.04)
        end
    end

    return true
end

local function getNextCrateTarget()
    local interactables = Workspace:FindFirstChild("Interactables")
    local cratesFolder = interactables and interactables:FindFirstChild("Crates")
    if not cratesFolder then return nil end

    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local bestTarget = nil
    local bestDist = math.huge
    local bestMode = "open"

    -- Pass 1: Loot already-opened crates (item pickups), skipping crates near GhostBear
    for _, c in ipairs(cratesFolder:GetChildren()) do
        local name = c.Name
        if not blacklistedCrates[name] then
            local cPos = c:GetPivot().Position
            if not isGhostBearNearPosition(cPos, 32) then
                local itemPrompts = getCrateItemPrompts(c)
                if #itemPrompts > 0 then
                    local dist = (cPos - root.Position).Magnitude
                    if dist < bestDist then
                        bestDist = dist
                        bestTarget = c
                        bestMode = "loot"
                    end
                end
            end
        end
    end

    if bestTarget then
        return { crate = bestTarget, mode = bestMode }
    end

    -- Pass 2: Open unopened crates, skipping crates near GhostBear
    bestDist = math.huge
    for _, c in ipairs(cratesFolder:GetChildren()) do
        local name = c.Name
        if not blacklistedCrates[name] and not openedCrates[name] then
            local cPos = c:GetPivot().Position
            if not isGhostBearNearPosition(cPos, 32) then
                local cratePart = c:FindFirstChild("Crate")
                local openPrompt = cratePart and cratePart:FindFirstChild("CratePrompt")
                local collected = c:GetAttribute("Collected")
                if collected ~= true and openPrompt and openPrompt.Enabled then
                    local dist = (cPos - root.Position).Magnitude
                    if dist < bestDist then
                        bestDist = dist
                        bestTarget = c
                        bestMode = "open"
                    end
                end
            end
        end
    end

    if bestTarget then
        return { crate = bestTarget, mode = bestMode }
    end

    return nil
end

local currentFarmSession = tick()
_G.MedvedFarmSession = currentFarmSession

task.spawn(function()
    local mySession = currentFarmSession
    while _G.MedvedFarmSession == mySession do
        task.wait(0.08)
        if Config.AutoFarmCrates then
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")

            if root and hum and hum.Health > 0 then
                silenceTelemetry()

                local target = getNextCrateTarget()
                if target then
                    isCratesActivelyFarming = true
                    local crate = target.crate
                    local name = crate.Name

                    crateAttempts[name] = (crateAttempts[name] or 0) + 1
                    local success = processCrateComplete(crate, target.mode)

                    if success or crateAttempts[name] >= 2 then
                        openedCrates[name] = true
                        blacklistedCrates[name] = true
                    end

                    task.wait(Config.FarmDelay)
                else
                    isCratesActivelyFarming = false
                    if Config.AutoServerhop then
                        Hub.Notify("Medved", "All crates & loot collected! Serverhopping...", 3)
                        task.wait(1)
                        if getgenv().serverhop then
                            getgenv().serverhop()
                        else
                            TeleportService:Teleport(game.PlaceId, LocalPlayer)
                        end
                        task.wait(5)
                    else
                        task.wait(0.35)
                    end
                end
            else
                isCratesActivelyFarming = false
            end
        else
            isCratesActivelyFarming = false
        end
    end
end)

--------------------------------------------------------------------------------
-- 6. PAGES AUTOMATION ENGINE
--------------------------------------------------------------------------------
local cachedServerCollectedPages = {}
local sessionCollectedPages = {}
local pageAttempts = {}
local blacklistedPages = {}
local lastServerPagesQuery = 0

local function syncServerCollectedPages(force)
    if not force and (tick() - lastServerPagesQuery) < 6 then
        return
    end
    lastServerPagesQuery = tick()
    pcall(function()
        local rf = ReplicatedStorage:FindFirstChild("SharedEvents") and ReplicatedStorage.SharedEvents:FindFirstChild("World") and ReplicatedStorage.SharedEvents.World:FindFirstChild("RequestCollectedPages")
        if rf and rf:IsA("RemoteFunction") then
            local list = rf:InvokeServer()
            if type(list) == "table" then
                for _, name in ipairs(list) do
                    cachedServerCollectedPages[name] = true
                end
            end
        end
    end)
end

local function isPageAlreadyCollected(p)
    if not p or not p.Parent then return true end
    local name = p.Name
    if blacklistedPages[name] == true then return true end
    if sessionCollectedPages[name] == true then return true end
    if cachedServerCollectedPages[name] == true then return true end
    if p:GetAttribute("Collected") == true then return true end

    -- Visual & Prompt state checks: Game sets Transparency = 0.8 and disables prompt on collected pages
    if p:IsA("BasePart") and p.Transparency >= 0.5 then
        cachedServerCollectedPages[name] = true
        return true
    end
    local prompt = p:FindFirstChildOfClass("ProximityPrompt")
    if prompt and not prompt.Enabled then
        cachedServerCollectedPages[name] = true
        return true
    end

    return false
end

local function getUncollectedPages()
    local uncollected = {}
    local pagesFolder = Workspace:FindFirstChild("Pages")
    if not pagesFolder then return uncollected end

    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")

    syncServerCollectedPages(false)

    for _, p in ipairs(pagesFolder:GetChildren()) do
        if p:IsA("BasePart") or p:IsA("Model") then
            if not isPageAlreadyCollected(p) then
                table.insert(uncollected, p)
            end
        end
    end

    if root then
        table.sort(uncollected, function(a, b)
            local posA = a:IsA("BasePart") and a.Position or a:GetPivot().Position
            local posB = b:IsA("BasePart") and b.Position or b:GetPivot().Position
            return (posA - root.Position).Magnitude < (posB - root.Position).Magnitude
        end)
    end

    return uncollected
end

local function collectSinglePage(pagePart)
    if not pagePart or not pagePart.Parent then return false end
    local name = pagePart.Name
    if isPageAlreadyCollected(pagePart) then
        return true
    end

    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return false end

    pageAttempts[name] = (pageAttempts[name] or 0) + 1
    if pageAttempts[name] > 2 then
        blacklistedPages[name] = true
        return false
    end

    local pagePos = pagePart:IsA("BasePart") and pagePart.Position or pagePart:GetPivot().Position
    local targetCFrame = CFrame.new(pagePos + Vector3.new(0, 1.8, 0))

    root.CFrame = targetCFrame
    root.AssemblyLinearVelocity = Vector3.zero
    task.wait(0.2)

    local prompt = pagePart:FindFirstChildOfClass("ProximityPrompt")
    if prompt and not prompt.Enabled then
        sessionCollectedPages[name] = true
        cachedServerCollectedPages[name] = true
        return true
    end

    if prompt then
        prompt.RequiresLineOfSight = false
        prompt.MaxActivationDistance = 25
    end

    -- Look for CollectedPage2 RemoteFunction inside PlayerScripts.World.Pages
    local worldPages = LocalPlayer:FindFirstChild("PlayerScripts") and LocalPlayer.PlayerScripts:FindFirstChild("World") and LocalPlayer.PlayerScripts.World:FindFirstChild("Pages")
    local collectedPageRemote = worldPages and worldPages:FindFirstChild("CollectedPage2")

    local startWait = tick()
    local confirmed = false

    while (tick() - startWait) < 2.0 do
        root.CFrame = targetCFrame
        root.AssemblyLinearVelocity = Vector3.zero

        if prompt and prompt.Enabled then
            if fireproximityprompt then
                pcall(function() fireproximityprompt(prompt) end)
            end
        end

        if collectedPageRemote and collectedPageRemote:IsA("RemoteFunction") then
            pcall(function()
                collectedPageRemote:InvokeServer(name)
            end)
        end

        task.wait(0.18)

        if pagePart:GetAttribute("Collected") == true or (prompt and not prompt.Enabled) or (pagePart:IsA("BasePart") and pagePart.Transparency >= 0.5) then
            confirmed = true
            sessionCollectedPages[name] = true
            cachedServerCollectedPages[name] = true
            break
        end
    end

    if confirmed then
        sessionCollectedPages[name] = true
        cachedServerCollectedPages[name] = true
    end

    task.wait(0.25)
    return confirmed or isPageAlreadyCollected(pagePart)
end

task.spawn(function()
    while true do
        task.wait(0.2)
        if Config.AutoCollectPages then
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")

            if root and hum and hum.Health > 0 then
                silenceTelemetry()

                local pages = getUncollectedPages()
                if #pages > 0 then
                    local targetPage = pages[1]
                    collectSinglePage(targetPage)
                    task.wait(Config.FarmDelay)
                else
                    Hub.Notify("Pages", "All pages on map collected! (32/32)", 3)
                    if Config.AutoPrestigeOn32 then
                        task.wait(0.5)
                        triggerRemotePrestige()
                    end
                    Config.AutoCollectPages = false
                    task.wait(2)
                end
            end
        end
    end
end)

--------------------------------------------------------------------------------
-- 7. COMBAT & MOVEMENT ENGINE (MELEE AURA, GUN AURA, INFINITE STAMINA)
--------------------------------------------------------------------------------
local function ensureBearQueryable(bear)
    if not bear then return end
    for _, part in ipairs(bear:GetDescendants()) do
        if part:IsA("BasePart") and not part.CanQuery then
            pcall(function() part.CanQuery = true end)
        end
    end
end

local function getBearLevitationTarget(bear)
    if not bear then return nil, 2.2, 1.8 end
    ensureBearQueryable(bear)
    local cf, sz = bear:GetBoundingBox()
    local name = bear.Name:lower()

    -- Category 0: GrinderBear (Robo Bear) & Heavy Mechanical Titans (Crown Apex Blindspot)
    -- Grinder is 36 studs tall, equipped with shoulder cannons (Minigun, Rockets, Shotgun, Flamethrower).
    -- Shoulder cannons are mounted at Y ~18-24 with limited upward elevation pitch (cannot aim behind/straight up).
    -- Solution: True Apex Blindspot (+14.5 studs above head, -8.5 studs behind). Completely avoids all bullet/rocket trajectories!
    if name:find("grinder") or name:find("robo") then
        local head = bear:FindFirstChild("Hitbox_Head")
        local targetPos = head and head.Position or cf.Position
        if Config.FarmMethod == "Melee" or Config.FarmMethod == "Bear Attack" then
            local targetY = cf.Position.Y + (sz.Y * 0.5) + 3.5
            local distBehind = (sz.Z * 0.5) + 3.0
            return targetPos, distBehind, targetY
        else
            local targetY = cf.Position.Y + (sz.Y * 0.5) + 14.5
            local distBehind = (sz.Z * 0.5) + 8.5
            return targetPos, distBehind, targetY
        end
    end

    -- Category 0.2: RangedBear & GrizzlyRangedBear (Spike Bear Blindspot)
    -- RangedBear shoots horizontal spike projectiles and performs ground slam shockwaves.
    -- In Melee mode: must be within 5.2 studs reach of Hitbox_Head to connect hits safely above spike trajectory.
    if name:find("ranged") or name:find("spike") then
        local head = bear:FindFirstChild("Hitbox_Head") or bear:FindFirstChild("Head")
        local targetPos = head and head.Position or cf.Position
        if Config.FarmMethod == "Melee" or Config.FarmMethod == "Bear Attack" then
            local targetY = targetPos.Y + 2.8
            local distBehind = 3.2
            return targetPos, distBehind, targetY
        else
            local targetY = cf.Position.Y + (sz.Y * 0.5) + 12.0
            local distBehind = (sz.Z * 0.5) + 8.0
            return targetPos, distBehind, targetY
        end
    end

    -- Category 1.1: Laser BooBoo / Roboo-800 (Deadly Eye Lasers, Balefire & DeathRay Boss)
    -- Roboo shoots forward eye lasers & DeathRay. Hover safely above its spine blindspot (+4.5 studs above head)
    if name:find("laser") or name:find("roboo") or name:find("robo") then
        local targetPos = cf.Position
        if Config.FarmMethod == "Melee" or Config.FarmMethod == "Bear Attack" then
            local targetY = cf.Position.Y + (sz.Y * 0.5) + 4.5
            local distBehind = 3.4
            return targetPos, distBehind, targetY
        else
            local targetY = cf.Position.Y + (sz.Y * 0.5) + 26.0
            local distBehind = 34.0
            return targetPos, distBehind, targetY
        end
    end

    -- Category 1: Ball Bear (ballbear, BooBoo, HypersonicBooBoo)
    -- In Melee / Bear Attack: Hover tightly behind spine so claw swipes and bite hitboxes connect 100%!
    if name:find("booboo") or name:find("ball") or sz.Y < 6.5 or sz.Magnitude < 8 then
        local targetPos = cf.Position
        if Config.FarmMethod == "Melee" or Config.FarmMethod == "Bear Attack" then
            local targetY = cf.Position.Y + (sz.Y * 0.5) + 2.2
            local distBehind = 2.4
            return targetPos, distBehind, targetY
        else
            local targetY = cf.Position.Y + (sz.Y * 0.5) + 22.0
            local distBehind = 28.0
            return targetPos, distBehind, targetY
        end
    end

    -- Category 0.5: WallBear & Giant Wall Entities (Apex Stance above top edge)
    -- WallBear topples forward and falls flat on its front face during attack.
    -- Solution: Anchor directly behind its horizontal heading at safe apex elevation (+7.2 above top edge in Melee, +34.0 in Gun).
    if name:find("wall") then
        local topPart = bear:FindFirstChild("BodyTop") or bear:FindFirstChild("Ears") or bear:FindFirstChild("Hitbox_Head")
        local targetPos = topPart and topPart.Position or cf.Position
        if Config.FarmMethod == "Melee" or Config.FarmMethod == "Bear Attack" then
            local targetY = cf.Position.Y + (sz.Y * 0.5) + 5.5
            local distBehind = 6.0
            return targetPos, distBehind, targetY
        else
            local targetY = cf.Position.Y + (sz.Y * 0.5) + 34.0
            local distBehind = 44.0
            return targetPos, distBehind, targetY
        end
    end

    -- Category 2: Tall / Giant / Worm bears (TallBear, GrizzlyTallBear, WormBear)
    if name:find("tall") or name:find("worm") or sz.Y > 14 or sz.Z > 14 then
        local head = bear:FindFirstChild("Hitbox_Head") or bear:FindFirstChild("Head")
        local targetPos = head and head.Position or cf.Position
        local targetY = cf.Position.Y + (sz.Y * 0.5) + 3.2
        local distBehind = (sz.Z * 0.5) + 2.4
        return targetPos, distBehind, targetY
    end

    -- Category 3: Quadruped / standard bears (Medved, ClassicBear, Grizzly, IceBear, ThinBear, etc.)
    -- In Melee / Bear Attack: hover closely above spine (+1.2 studs) and tight behind (2.4 studs) so attacks connect 100%
    local targetY = (Config.FarmMethod == "Melee" or Config.FarmMethod == "Bear Attack") and (cf.Position.Y + (sz.Y * 0.5) + 1.2) or (cf.Position.Y + (sz.Y * 0.5) + 3.4)
    local distBehind = (Config.FarmMethod == "Melee" or Config.FarmMethod == "Bear Attack") and math.min((sz.Z * 0.5) + 1.5, 2.6) or ((sz.Z * 0.5) + 2.4)

    -- Building / Shop Wall Anti-Obstruction Guard:
    -- If bear is backed against a shop or building wall, hover directly above the bear so walls never block attacks!
    pcall(function()
        local rayParams = RaycastParams.new()
        local char = LocalPlayer.Character
        rayParams.FilterDescendantsInstances = {bear, char, Workspace.CurrentCamera}
        rayParams.FilterType = Enum.RaycastFilterType.Exclude
        local testHit = workspace:Raycast(cf.Position, -bear.PrimaryPart.CFrame.LookVector * (distBehind + 2.0), rayParams)
        if testHit and testHit.Instance and not testHit.Instance:IsDescendantOf(bear) then
            distBehind = 0.5
            targetY = math.max(targetY, cf.Position.Y + (sz.Y * 0.5) + ((Config.FarmMethod == "Melee" or Config.FarmMethod == "Bear Attack") and 2.2 or 14.0))
        end
    end)

    return cf.Position, distBehind, targetY
end

local getBearSafeFlightPosition = getBearLevitationTarget

local function getBearBottomRearPart(bear)
    if not bear then return nil end
    ensureBearQueryable(bear)
    local bottomRearPriority = {
        "Hitbox_RightFoot", "Hitbox_LeftFoot",
        "Hitbox_RightThigh", "Hitbox_LeftThigh",
        "Hitbox_RightShin", "Hitbox_LeftShin",
        "Hitbox_RightLeg", "Hitbox_LeftLeg",
        "Hitbox_Pelvis", "Hitbox_Hips",
        "BodyBottom", "BodyTop", "body", "Body",
        "Hitbox_Body", "Hitbox_Chest", "Hitbox_Head", "Hitbox"
    }
    for _, name in ipairs(bottomRearPriority) do
        local part = bear:FindFirstChild(name)
        if part and part:IsA("BasePart") and part.CanQuery then
            return part
        end
    end
    for _, child in ipairs(bear:GetChildren()) do
        if child:IsA("BasePart") and (child.Name:find("Foot") or child.Name:find("Leg") or child.Name:find("Shin") or child.Name:find("Thigh")) and child.CanQuery then
            return child
        end
    end
    local hrp = bear:FindFirstChild("HumanoidRootPart")
    if hrp and hrp:IsA("BasePart") and hrp.CanQuery then
        return hrp
    end
    return hrp or bear.PrimaryPart or bear:FindFirstChildWhichIsA("BasePart")
end

local function isFriendlyBearOrPlayer(b)
    if not b or not b.Parent then return true end
    if b == LocalPlayer.Character or b.Name == LocalPlayer.Name then return true end
    if Players:FindFirstChild(b.Name) ~= nil or Players:GetPlayerFromCharacter(b) ~= nil then return true end
    local name = b.Name:lower()

    -- Cutie bears are strictly friendly and peaceful
    if name:find("cutie") or name:find("cute") or name:find("baby") then
        return true
    end

    -- Explicit friendly stance flag
    if b:GetAttribute("Stance") == "Friendly" then
        return true
    end

    -- Player bears with friendly / peaceful mode active
    local plr = Players:GetPlayerFromCharacter(b)
    if plr then
        if plr:GetAttribute("Friendly") == true or plr:GetAttribute("FriendlyMode") == true
            or plr:GetAttribute("Peaceful") == true or plr:GetAttribute("Peace") == true
            or plr:GetAttribute("PvP") == false or plr:GetAttribute("PVP") == false
            or b:GetAttribute("Friendly") == true or b:GetAttribute("FriendlyMode") == true
            or b:GetAttribute("Peaceful") == true or b:GetAttribute("Peace") == true
            or b:GetAttribute("PvP") == false or b:GetAttribute("PVP") == false then
            return true
        end

        local head = b:FindFirstChild("Head") or b:FindFirstChildWhichIsA("BasePart")
        if head then
            for _, gui in ipairs(head:GetChildren()) do
                if gui:IsA("BillboardGui") then
                    for _, desc in ipairs(gui:GetDescendants()) do
                        if desc:IsA("TextLabel") then
                            local txt = desc.Text:lower()
                            if txt:find("friendly") or txt:find("peaceful") or txt:find("passive") then
                                return true
                            end
                        end
                    end
                end
            end
        end
    end

    return false
end

local function isBearTargetable(b)
    if not b or not b.Parent then return false end
    if b == LocalPlayer.Character or b.Name == LocalPlayer.Name then return false end
    if Players:FindFirstChild(b.Name) ~= nil or Players:GetPlayerFromCharacter(b) ~= nil then return false end
    local name = b.Name:lower()

    -- 1. Never target Cutie bears, Ghost bears, Worm bears, Classic bears, or DEMON BEARS!
    if name:find("cutie") or name:find("cute") or name:find("ghost") or name:find("demon") or name:find("devil") or name:find("satan") or name:find("worm") or name:find("classic") then
        return false
    end
    if b:GetAttribute("IsDemon") == true or b:GetAttribute("Demon") == true then
        return false
    end

    -- 1.5. ThinBear Sitting Phase Protection (invulnerable while sitting/dormant until enraged)
    if name:find("thin") then
        local brainMode = b:GetAttribute("BrainMode")
        local brainAnger = b:GetAttribute("BrainAnger")
        if brainMode == "Sit" or (brainAnger and brainAnger <= 0) then
            return false
        end
    end

    local hum = b:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then
        return false
    end

    -- Demon Bear & Invulnerable Boss Immunity: Do NOT target 50,000+ HP entities
    if (hum.MaxHealth and hum.MaxHealth >= 50000) or hum.Health >= 50000 then
        return false
    end

    -- 2. Friendly Bear / Player in Friendly Mode Protection:
    -- Attacks ALL hostile wild bears & non-friendly player bears, but STRICTLY protects friendly ones!
    if isFriendlyBearOrPlayer(b) then
        return false
    end

    -- 3. Filter out zero-size dead or despawned ghost models
    local cf, sz = b:GetBoundingBox()
    if sz.Magnitude <= 3 then
        return false
    end

    return true
end

-- Authoritative Bear Multi-Selection Validator
local function isBearTargetSelected(b)
    if not b or not isBearTargetable(b) then return false end

    -- Check Multi-Select state dict
    if Config.SelectedBears and type(Config.SelectedBears) == "table" then
        if Config.SelectedBears["All"] then
            return true
        end
        return Config.SelectedBears[b.Name] == true
    end

    -- Legacy single dropdown fallback
    if Config.SelectedBearTarget then
        if Config.SelectedBearTarget == "All" then
            return true
        end
        return Config.SelectedBearTarget == b.Name
    end

    return true
end

local function getClosestBear(maxDist, filterSelected)
    local bearsFolder = Workspace:FindFirstChild("Bears")
    if not bearsFolder then return nil end

    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local closest = nil
    local bestDist = maxDist or math.huge

    for _, b in ipairs(bearsFolder:GetChildren()) do
        local eligible = filterSelected and isBearTargetSelected(b) or isBearTargetable(b)
        if b ~= char and eligible then
            local bearRoot = b:FindFirstChild("HumanoidRootPart") or b:FindFirstChild("Head") or b.PrimaryPart or b:FindFirstChildWhichIsA("BasePart")
            if bearRoot then
                local dist = (bearRoot.Position - root.Position).Magnitude
                if dist < bestDist then
                    bestDist = dist
                    closest = b
                end
            end
        end
    end
    return closest, bestDist
end

-- Cache original weapon defaults to avoid corrupting game state
local originalGunConfigs = {}

local function applyWeaponMods(tool)
    if not tool or not tool:IsA("Tool") then return end
    local config = tool:FindFirstChild("Config")
    if not config then return end

    local toolId = tool.Name
    if not originalGunConfigs[toolId] then
        local clip = config:FindFirstChild("ClipSize")
        local reload = config:FindFirstChild("ReloadTime")
        local fireRate = config:FindFirstChild("FireRate")
        originalGunConfigs[toolId] = {
            ClipSize = (clip and clip:IsA("ValueBase")) and clip.Value or 10,
            ReloadTime = (reload and reload:IsA("ValueBase")) and reload.Value or 2.5,
            FireRate = (fireRate and fireRate:IsA("ValueBase")) and fireRate.Value or 0.3
        }
    end

    local orig = originalGunConfigs[toolId]

    -- Always guarantee clean clip and reload sync with server (no desync!)
    local clip = config:FindFirstChild("ClipSize")
    if clip and clip:IsA("ValueBase") and clip.Value >= 99999 then
        clip.Value = orig.ClipSize
    end

    -- Clean up any desyncing client-only NoReload/NoPump folders (server enforces ammo!)
    local nr = config:FindFirstChild("NoReload")
    if nr then nr:Destroy() end
    local shotgunCfg = config:FindFirstChild("Shotgun")
    local np = shotgunCfg and shotgunCfg:FindFirstChild("NoPump")
    if np then np:Destroy() end

    -- Flamethrower Configuration Enhancements
    if tool.Name == "Flamethrower" or tool:FindFirstChild("FlameRemote") then
        local range = config:FindFirstChild("Range")
        if range and range:IsA("ValueBase") and range.Value < 80 then range.Value = 85 end

        local cone = config:FindFirstChild("ConeAngle")
        if cone and cone:IsA("ValueBase") and cone.Value < 35 then cone.Value = 40 end

        local refuelDelay = config:FindFirstChild("RefuelDelay")
        if refuelDelay and refuelDelay:IsA("ValueBase") then refuelDelay.Value = 0 end

        local refuelTime = config:FindFirstChild("RefuelTime")
        if refuelTime and refuelTime:IsA("ValueBase") then refuelTime.Value = 0.5 end

        local equipDelay = config:FindFirstChild("EquipDelay")
        if equipDelay and equipDelay:IsA("ValueBase") then equipDelay.Value = 0 end
    end

    if Config.MeleeAura or (Config.AutoFarmBears and Config.FarmMethod == "Melee") then
        local equipDelay = config:FindFirstChild("EquipDelay")
        if equipDelay and equipDelay:IsA("ValueBase") then equipDelay.Value = 0 end

        local windup = config:FindFirstChild("WindupTime")
        if windup and windup:IsA("ValueBase") then windup.Value = 0 end

        local cooldown = config:FindFirstChild("CooldownTime")
        if cooldown and cooldown:IsA("ValueBase") then cooldown.Value = 0.20 end

        local hitboxTime = config:FindFirstChild("HitboxTime")
        if hitboxTime and hitboxTime:IsA("ValueBase") then hitboxTime.Value = 0.8 end
    end
end

-- =========================================================================
-- Native Anti-Ragdoll Recovery Protocol
-- =========================================================================
local function recoverFromRagdoll()
    local char = LocalPlayer.Character
    if not char then return end

    -- 1. Strip client/server RagdollTag instance
    local tag = char:FindFirstChild("RagdollTag")
    if tag then
        pcall(function() tag:Destroy() end)
    end

    -- 2. Strip bone ragdoll and jumpscare attributes
    if char:GetAttribute("BoneRagdolled") then
        pcall(function() char:SetAttribute("BoneRagdolled", nil) end)
    end

    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health > 0 then
        if hum:GetAttribute("BeingJumpscared") then
            pcall(function() hum:SetAttribute("BeingJumpscared", nil) end)
        end

        hum.PlatformStand = false
        hum.AutoRotate = true

        local state = hum:GetState()
        if state == Enum.HumanoidStateType.Physics
            or state == Enum.HumanoidStateType.Ragdoll
            or state == Enum.HumanoidStateType.FallingDown
            or state == Enum.HumanoidStateType.PlatformStanding then
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            task.defer(function()
                if hum and hum.Health > 0 then
                    hum:ChangeState(Enum.HumanoidStateType.Running)
                end
            end)
        end
    end

    -- 3. Restore all Motor6D joints
    for _, m in ipairs(char:GetDescendants()) do
        if m:IsA("Motor6D") and not m.Enabled then
            m.Enabled = true
        end
    end

    -- 4. Guarantee solid ground collision on root and torso only (never limbs, to prevent walk freeze)
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then root.CanCollide = true end
    local ut = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
    if ut then ut.CanCollide = true end
    local lt = char:FindFirstChild("LowerTorso")
    if lt then lt.CanCollide = true end
end

-- Server-Synchronized Gun Reload & Live Ammo State Machine
local isReloading = false
local reloadEndTime = 0

-- Authoritative Ammo State Tracker & Synchronizer
local currentGunAmmo = {} -- [tool] = currentLoadedAmmo

local function getToolMaxClip(tool)
    if not tool then return 30 end
    local config = tool:FindFirstChild("Config")
    local clipVal = config and config:FindFirstChild("ClipSize")
    return (clipVal and clipVal:IsA("ValueBase") and clipVal.Value) or 30
end

local function syncAmmoToGUI(tool)
    if not tool then return end
    local maxClip = getToolMaxClip(tool)
    local curAmmo = currentGunAmmo[tool] or maxClip
    local str = isReloading and "RELOAD" or (curAmmo .. " / " .. maxClip)

    pcall(function()
        local pgui = LocalPlayer:FindFirstChild("PlayerGui")
        local hud = pgui and pgui:FindFirstChild("GameplayInterface") and pgui.GameplayInterface:FindFirstChild("Hud")
        local gunHud = hud and hud:FindFirstChild("Gun")
        if gunHud then
            if gunHud:FindFirstChild("MobileButtons") and gunHud.MobileButtons:FindFirstChild("Ammo") then
                gunHud.MobileButtons.Ammo.Text = str
            end
            if gunHud:FindFirstChild("Crosshair") and gunHud.Crosshair:FindFirstChild("AmmoCount") then
                gunHud.Crosshair.AmmoCount.Text = str
            end
            local reloadBtn = gunHud:FindFirstChild("MobileButtons") and gunHud.MobileButtons:FindFirstChild("Reload")
            if reloadBtn then
                reloadBtn.Visible = true
            end
        end
    end)
end

local function getLoadedAmmoFromGUI(tool)
    if tick() < reloadEndTime or isReloading then
        return 0, true
    end

    if not tool then
        local char = LocalPlayer.Character
        tool = char and char:FindFirstChildOfClass("Tool")
    end
    if not tool or not tool:FindFirstChild("GunScripts") then
        return 0, false
    end

    local maxClip = getToolMaxClip(tool)
    if currentGunAmmo[tool] == nil then
        currentGunAmmo[tool] = maxClip
    end

    -- 1. Check Reload cooldown indicator in MobileButtons
    local pgui = LocalPlayer:FindFirstChild("PlayerGui")
    local hud = pgui and pgui:FindFirstChild("GameplayInterface") and pgui.GameplayInterface:FindFirstChild("Hud")
    local gunHud = hud and hud:FindFirstChild("Gun")

    local reloadCooldown = gunHud and gunHud:FindFirstChild("MobileButtons") and gunHud.MobileButtons:FindFirstChild("Reload") and gunHud.MobileButtons.Reload:FindFirstChild("Cooldown")
    if reloadCooldown and reloadCooldown.Visible then
        return 0, true
    end

    -- 2. If player shot manually, sync down to the GUI's lower value
    local ammoLabel = (gunHud and gunHud:FindFirstChild("MobileButtons") and gunHud.MobileButtons:FindFirstChild("Ammo"))
        or (gunHud and gunHud:FindFirstChild("Crosshair") and gunHud.Crosshair:FindFirstChild("AmmoCount"))

    if ammoLabel and ammoLabel.Text ~= "" then
        local text = ammoLabel.Text
        if string.find(text, "RELOAD") or string.find(text, "%-%-") then
            return 0, true
        end
        local current = string.match(text, "^(%d+)")
        if current then
            local guiAmmo = tonumber(current) or 0
            if guiAmmo < currentGunAmmo[tool] then
                currentGunAmmo[tool] = guiAmmo
            end
        end
    end

    local ammo = currentGunAmmo[tool] or 0
    local isActivelyReloading = isReloading or (tick() < reloadEndTime)
    return ammo, isActivelyReloading
end

-- Comprehensive Authoritative Gun Reload Trigger (Simulated Key + Server Remote + UI Trigger)
local function triggerGunReload(tool)
    if not tool then return end
    if tick() < reloadEndTime or isReloading then return end

    local gunScripts = tool:FindFirstChild("GunScripts")
    local reloadRemote = gunScripts and gunScripts:FindFirstChild("Reload")

    local config = tool:FindFirstChild("Config")
    local reloadTimeVal = config and config:FindFirstChild("ReloadTime")
    local reloadDuration = (reloadTimeVal and reloadTimeVal:IsA("ValueBase") and reloadTimeVal.Value) or 2.2

    reloadEndTime = tick() + reloadDuration + 0.15
    isReloading = true
    syncAmmoToGUI(tool)

    -- 1. Direct Network Remote Dispatch to server
    if reloadRemote then
        pcall(function()
            reloadRemote:FireServer()
        end)
    end

    -- 2. Native Virtual Input KeyPress simulation (invokes GunClient local reload animation & client clip reset)
    pcall(function()
        local vim = game:GetService("VirtualInputManager")
        if vim then
            vim:SendKeyEvent(true, Enum.KeyCode.R, false, game)
            task.wait(0.04)
            vim:SendKeyEvent(false, Enum.KeyCode.R, false, game)
        end
    end)

    -- 3. Click MobileButtons Reload button if visible
    pcall(function()
        local pgui = LocalPlayer:FindFirstChild("PlayerGui")
        local hud = pgui and pgui:FindFirstChild("GameplayInterface") and pgui.GameplayInterface:FindFirstChild("Hud")
        local reloadBtn = hud and hud:FindFirstChild("Gun") and hud.Gun:FindFirstChild("MobileButtons") and hud.Gun.MobileButtons:FindFirstChild("Reload")
        if reloadBtn and reloadBtn:IsA("GuiButton") then
            for _, conn in ipairs(getconnections(reloadBtn.MouseButton1Click)) do
                conn:Fire()
            end
        end
    end)

    task.delay(reloadDuration + 0.15, function()
        if tick() >= reloadEndTime then
            isReloading = false
            currentGunAmmo[tool] = getToolMaxClip(tool)
            syncAmmoToGUI(tool)
        end
    end)
end

local lastGunShotTime = {}

local function getToolFireRate(tool)
    if not tool then return 0.20 end
    local isShotgun = tool.Name:lower():find("shotgun") ~= nil
    if isShotgun then
        local cfg = tool:FindFirstChild("Config")
        local fr = cfg and cfg:FindFirstChild("FireRate")
        local val = fr and fr:IsA("ValueBase") and tonumber(fr.Value)
        return math.max(val or 0.70, 0.65) -- Authentic shotgun pump action cycle time
    end
    local cfg = tool:FindFirstChild("Config")
    local fr = cfg and cfg:FindFirstChild("FireRate")
    if fr and fr:IsA("ValueBase") then
        return math.max(0.12, tonumber(fr.Value) or 0.18)
    end
    return 0.18
end

-- Server-Authoritative Shooting Dispatcher (Prevents 0-Damage Soft-Locks & Ghost Shots)
local function shootTargetBear(tool, bear, bearPart)
    if not tool or not bear or not bearPart then return end

    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local gunScripts = tool:FindFirstChild("GunScripts")
    local fireRemote = gunScripts and gunScripts:FindFirstChild("FireBullet")
    if not fireRemote then return end

    -- 0. Gun Cycle / Fire Rate Debounce:
    -- Shotguns require authentic pump action cycle time (0.70s).
    -- Spamming shots every frame like an AK-47 causes server to drop packets and deal 0 damage!
    local fireRate = getToolFireRate(tool)
    local now = tick()
    if now - (lastGunShotTime[tool] or 0) < fireRate then
        return
    end

    -- Authoritative Ammo & Reload Gate: NEVER shoot while reloading or with 0 ammo!
    local currentAmmo, reloading = getLoadedAmmoFromGUI(tool)
    if reloading or now < reloadEndTime or isReloading then
        return
    end
    if currentAmmo <= 0 then
        triggerGunReload(tool)
        return
    end

    lastGunShotTime[tool] = now

    local muzzle = tool:FindFirstChild("Handle") and tool.Handle:FindFirstChild("Muzzle")
    local muzzlePos = muzzle and muzzle.WorldCFrame.Position or (root.Position + Vector3.new(0, 1.5, 0))

    -- Target verified hitbox part (head or chest/torso) for 100% damage registration
    local targetPart = bear:FindFirstChild("BodyTop") or bear:FindFirstChild("Ears") or bear:FindFirstChild("Hitbox_Head") or bear:FindFirstChild("Hitbox_Chest") or bear:FindFirstChild("Hitbox_Torso") or bearPart
    local hitPos = targetPart.Position

    -- Check if target is alive
    local bearHum = bear:FindFirstChildOfClass("Humanoid")
    if bearHum and bearHum.Health <= 0 then
        return
    end

    ensureBearQueryable(bear)

    -- Multi-Pellet & Shotgun Full Damage Multiplier:
    -- Shotguns and scatter weapons fire multiple pellets per shell (typically 8).
    -- Dispatching all pellets simultaneously with realistic ballistics spread guarantees full damage!
    local isShotgun = tool.Name:lower():find("shotgun") ~= nil
    local numBullets = 1
    local cfg = tool:FindFirstChild("Config")
    if cfg then
        local bVal = cfg:FindFirstChild("Bullets") or cfg:FindFirstChild("NumBullets") or cfg:FindFirstChild("Pellets") or cfg:FindFirstChild("ShotCount")
        if bVal and bVal:IsA("ValueBase") then
            numBullets = math.max(1, tonumber(bVal.Value) or 1)
        elseif isShotgun then
            numBullets = 8
        end
    elseif isShotgun then
        numBullets = 8
    end

    local hitData = {}
    if isShotgun or numBullets > 1 then
        -- Target verified critical hitboxes (Head, Chest, Crown, Torso, BodyTop)
        local targetParts = {
            bear:FindFirstChild("Hitbox_Head") or bear:FindFirstChild("Head"),
            bear:FindFirstChild("Hitbox_Chest") or bear:FindFirstChild("Hitbox_Torso"),
            bear:FindFirstChild("Hitbox_Crown") or bear:FindFirstChild("BodyTop") or bear:FindFirstChild("Ears"),
            targetPart,
            bearPart
        }
        local validParts = {}
        for _, p in ipairs(targetParts) do
            if p and p:IsA("BasePart") then
                table.insert(validParts, p)
            end
        end
        if #validParts == 0 then table.insert(validParts, targetPart) end

        -- Scatter pellets realistically across target hitboxes with micro-spread offsets
        for i = 1, numBullets do
            local chosenPart = validParts[((i - 1) % #validParts) + 1]
            local angle = (i / numBullets) * math.pi * 2
            local spreadRadius = (i == 1) and 0 or (0.25 + (i % 3) * 0.15)
            local spreadOffset = (i == 1) and Vector3.zero or Vector3.new(math.cos(angle) * spreadRadius, math.sin(angle) * spreadRadius, math.sin(angle * 2) * 0.2)

            table.insert(hitData, {
                hit = chosenPart,
                hitpos = chosenPart.Position + spreadOffset,
                normal = Vector3.new(0, 1, 0)
            })
        end
    else
        table.insert(hitData, {
            hit = targetPart,
            hitpos = hitPos,
            normal = Vector3.new(0, 1, 0)
        })
    end

    -- Clip Management & Shot Dispatch:
    currentGunAmmo[tool] = math.max(0, currentAmmo - 1)
    syncAmmoToGUI(tool)

    fireRemote:FireServer(hitData)

    -- If clip is now empty, immediately trigger reload
    if currentGunAmmo[tool] <= 0 then
        triggerGunReload(tool)
    end

    -- Local auditory & visual feedback
    pcall(function()
        if muzzle then
            local fireSound = muzzle:FindFirstChild("Fire") or muzzle:FindFirstChild("Fire_client")
            if fireSound and fireSound:IsA("Sound") then
                fireSound:Play()
            end
            local flash = muzzle:FindFirstChild("Flash")
            if flash and flash:IsA("ParticleEmitter") then
                flash:Emit(1)
            end
        end

        local sharedEvents = ReplicatedStorage:FindFirstChild("SharedEvents")
        local combatEvents = sharedEvents and sharedEvents:FindFirstChild("Combat")
        local clientBulletShot = combatEvents and combatEvents:FindFirstChild("ClientBulletShot")
        if clientBulletShot and clientBulletShot:IsA("BindableEvent") then
            clientBulletShot:Fire(muzzlePos, hitPos, Vector3.new(0, 1, 0), targetPart)
        end
    end)

    -- Tool recoil swing
    pcall(function()
        tool:Activate()
    end)
end

-- Active Combat Loop: Melee Aura, Gun Aura & Weapon Enhancements
local lastMeleeSwing = 0
local lastBearAttack = 0

task.spawn(function()
    while true do
        task.wait(0.08)
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")

        if root and hum and hum.Health > 0 then
            local equippedTool = char:FindFirstChildOfClass("Tool")

            -- 1. Melee Aura Execution (Smooth 0.35s swing throttle + Authoritative Hit Remote Dispatch)
            if Config.MeleeAura then
                local bear, dist = getClosestBear(Config.MeleeAuraRange, true)
                if bear and dist then
                    local isMelee = equippedTool and equippedTool:FindFirstChild("MeleeScripts")
                    if isMelee and equippedTool then
                        applyWeaponMods(equippedTool)
                        local targetHitPart = bear:FindFirstChild("Hitbox_Crown")
                            or bear:FindFirstChild("Hitbox_Head")
                            or bear:FindFirstChild("Head")
                            or bear:FindFirstChild("BodyTop")
                            or bear:FindFirstChild("Hitbox_Chest")
                            or bear:FindFirstChild("Hitbox_Torso")
                            or getBearBottomRearPart(bear)
                            or bear.PrimaryPart
                            or bear:FindFirstChild("HumanoidRootPart")
                        if targetHitPart then
                            root.CFrame = CFrame.new(root.Position, Vector3.new(targetHitPart.Position.X, root.Position.Y, targetHitPart.Position.Z))
                            if tick() - lastMeleeSwing >= 0.35 then
                                lastMeleeSwing = tick()
                                equippedTool:Activate()

                                -- Direct authoritative network hit dispatch (Crown/Head priority)
                                local meleeRemote = isMelee:FindFirstChild("MeleeRemote")
                                if meleeRemote then
                                    pcall(function()
                                        meleeRemote:FireServer("Hit", targetHitPart)
                                    end)
                                end
                            end
                        end
                    end
                end
            end

            -- 2. Gun Aura Execution (Supports standard firearms & Flamethrower!)
            if Config.GunAura then
                local isFlame = equippedTool and (equippedTool:FindFirstChild("FlameRemote") or equippedTool.Name == "Flamethrower")
                local isGun = equippedTool and equippedTool:FindFirstChild("GunScripts")
                if isFlame and equippedTool then
                    applyWeaponMods(equippedTool)
                    local flameRemote = equippedTool:FindFirstChild("FlameRemote")
                    local fuel = equippedTool:GetAttribute("Fuel") or 1
                    local bear, dist = getClosestBear(Config.GunAuraRange, true)
                    if bear and dist and fuel > 0.05 and flameRemote then
                        local bearRoot = bear:FindFirstChild("Hitbox_Head") or bear:FindFirstChild("Head") or bear:FindFirstChild("BodyTop") or bear.PrimaryPart or bear:FindFirstChild("HumanoidRootPart")
                        if bearRoot then
                            root.CFrame = CFrame.new(root.Position, Vector3.new(bearRoot.Position.X, root.Position.Y, bearRoot.Position.Z))
                            flameRemote:FireServer("Aim", bearRoot.Position)
                            flameRemote:FireServer("Start")
                        end
                    elseif flameRemote then
                        flameRemote:FireServer("Stop")
                    end
                elseif isGun and equippedTool then
                    local currentAmmo, reloading = getLoadedAmmoFromGUI(equippedTool)
                    if not reloading and currentAmmo <= 0 and tick() >= reloadEndTime then
                        triggerGunReload(equippedTool)
                    elseif not reloading and currentAmmo > 0 then
                        local bear, dist = getClosestBear(Config.GunAuraRange, true)
                        if bear and dist then
                            applyWeaponMods(equippedTool)
                            local bearRoot = bear:FindFirstChild("HumanoidRootPart") or bear:FindFirstChild("Head") or bear.PrimaryPart or bear:FindFirstChildOfClass("BasePart")
                            if bearRoot then
                                -- Aim character at target bear
                                root.CFrame = CFrame.new(root.Position, Vector3.new(bearRoot.Position.X, root.Position.Y, bearRoot.Position.Z))
                                shootTargetBear(equippedTool, bear, bearRoot)
                            end
                        end
                    end
                end
            end
        end
    end
end)

--------------------------------------------------------------------------------
-- 7.5. AUTO FARM BEARS ENGINE (LEVITATION IMMUNITY, AUTO-EQUIP, AUTO-RELOAD)
--------------------------------------------------------------------------------
local WEAPON_TIERS = {
    -- Melee hierarchy
    Chainsaw = 100,
    Sledgehammer = 80,
    FireAxe = 60,
    Crowbar = 40,
    Axe = 35,
    BaseballBat = 20,
    Knife = 15,

    -- Gun hierarchy
    GoldenMinigun = 220,
    Flamethrower = 210,
    Minigun = 200,
    RPG = 180,
    Sniper = 150,
    HuntingRifle = 120,
    Rifle = 100,
    Shotgun = 85,
    SMG = 65,
    Revolver = 50,
    Pistol = 30
}

local function getToolDamage(tool)
    if not tool then return 0 end
    local cfg = tool:FindFirstChild("Config")
    if cfg then
        local dmgVal = cfg:FindFirstChild("Damage") or cfg:FindFirstChild("DPS")
        if dmgVal and dmgVal:IsA("ValueBase") and tonumber(dmgVal.Value) then
            return tonumber(dmgVal.Value)
        end
    end
    return WEAPON_TIERS[tool.Name] or 10
end

local function isToolMatchingType(tool, weaponType)
    if not tool or not tool:IsA("Tool") then return false end
    local isGun = (tool:FindFirstChild("GunScripts") ~= nil) or (tool:FindFirstChild("FlameRemote") ~= nil) or (tool.Name:lower():find("flame") ~= nil)
    local isMelee = (tool:FindFirstChild("MeleeScripts") ~= nil) or (tool:FindFirstChild("MeleeRemote", true) ~= nil) or (not isGun and (tool:FindFirstChild("Damage") ~= nil or tool:FindFirstChild("Handle") ~= nil))
    if weaponType == "Melee" then
        return isMelee and not isGun
    elseif weaponType == "Gun" then
        return isGun
    end
    return false
end

local function getBestTool(weaponType)
    local char = LocalPlayer.Character
    local backpack = LocalPlayer:FindFirstChild("Backpack")

    -- 1. If player ALREADY has a matching weapon equipped in character, USE IT IMMEDIATELY!
    local equipped = char and char:FindFirstChildOfClass("Tool")
    if equipped and isToolMatchingType(equipped, weaponType) then
        return equipped
    end

    local candidates = {}
    local function checkTool(tool)
        if isToolMatchingType(tool, weaponType) then
            table.insert(candidates, tool)
        end
    end

    if char then
        for _, c in ipairs(char:GetChildren()) do checkTool(c) end
    end
    if backpack then
        for _, c in ipairs(backpack:GetChildren()) do checkTool(c) end
    end

    if #candidates == 0 then return nil end

    table.sort(candidates, function(a, b)
        return getToolDamage(a) > getToolDamage(b)
    end)

    return candidates[1]
end

local function ensureBestWeaponEquipped(weaponType)
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not char or not hum or hum.Health <= 0 then return nil end

    -- Check if already held in hand
    local equipped = char:FindFirstChildOfClass("Tool")
    if equipped and isToolMatchingType(equipped, weaponType) then
        return equipped
    end

    local bestTool = getBestTool(weaponType)
    if not bestTool then return nil end

    if bestTool.Parent == char then
        return bestTool
    end

    hum:EquipTool(bestTool)
    task.wait(0.08)
    return bestTool
end

local bearTypeDropdown = nil

local function getAvailableBearTypes()
    local list = {"All"}
    local rs = game:GetService("ReplicatedStorage")

    -- 1. Read all authoritative bear definitions from ReplicatedStorage.Data.Bears (excluding nonexistent ClassicBear)
    local dataBears = rs:FindFirstChild("Data") and rs.Data:FindFirstChild("Bears")
    if dataBears then
        for _, b in ipairs(dataBears:GetChildren()) do
            local bn = b.Name:lower()
            if not bn:find("cutie") and not bn:find("ghost") and not bn:find("classic") and not bn:find("demon") and not bn:find("worm") and not table.find(list, b.Name) then
                table.insert(list, b.Name)
            end
        end
    end

    -- 2. Also inspect ReplicatedStorage.Bears folder
    local rsBears = rs:FindFirstChild("Bears")
    if rsBears then
        for _, b in ipairs(rsBears:GetChildren()) do
            local bn = b.Name:lower()
            if not bn:find("cutie") and not bn:find("ghost") and not bn:find("classic") and not bn:find("demon") and not bn:find("worm") and not table.find(list, b.Name) then
                table.insert(list, b.Name)
            end
        end
    end

    -- 3. Also dynamically inspect active workspace bears
    local wsBears = workspace:FindFirstChild("Bears")
    if wsBears then
        for _, b in ipairs(wsBears:GetChildren()) do
            local isPlr = Players:GetPlayerFromCharacter(b) ~= nil
            local bn = b.Name:lower()
            if not isPlr and not bn:find("cutie") and not bn:find("cute") and not bn:find("ghost") and not bn:find("classic") and not bn:find("demon") and not bn:find("devil") and not bn:find("satan") and not table.find(list, b.Name) then
                table.insert(list, b.Name)
            end
        end
    end

    table.sort(list, function(a, b)
        if a == "All" then return true end
        if b == "All" then return false end
        return a < b
    end)
    return list
end

local function onBearAdded(child)
    if not child or Players:GetPlayerFromCharacter(child) then return end
    local cName = child.Name:lower()
    if cName:find("classic") or cName:find("demon") or cName:find("worm") or cName:find("ghost") or cName:find("cutie") then return end
    task.delay(0.5, function()
        if bearTypeDropdown and bearTypeDropdown.Refresh then
            bearTypeDropdown.Refresh(getAvailableBearTypes())
        end
    end)
end

pcall(function()
    local wsBears = workspace:FindFirstChild("Bears")
    if wsBears then
        wsBears.ChildAdded:Connect(onBearAdded)
    end

    local rsBears = ReplicatedStorage:FindFirstChild("Bears")
    if rsBears then
        rsBears.ChildAdded:Connect(onBearAdded)
    end
end)

local lockedFarmTarget = nil

local function getFarmBearTarget()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then
        lockedFarmTarget = nil
        return nil, nil
    end

    local wsBears = workspace:FindFirstChild("Bears")
    if not wsBears then
        lockedFarmTarget = nil
        return nil, nil
    end

    local function isPriorityBear(bear)
        if not bear or not bear.Parent then return false end
        local bName = bear.Name:lower()
        if Config.PriorityBears and type(Config.PriorityBears) == "table" then
            if Config.PriorityBears[bear.Name] == true or Config.PriorityBears["All"] == true then
                return true
            end
            for pName, isEnabled in pairs(Config.PriorityBears) do
                if isEnabled and (bName:find(pName:lower()) or pName:lower():find(bName)) then
                    return true
                end
            end
        end
        return bName:find("grinder") ~= nil
    end

    -- PRIORITY PIPELINE: If any priority bear (e.g. Grinder Bear) exists, kill it FIRST!
    local bestPriorityBear = nil
    local bestPriorityDist = math.huge
    for _, bear in ipairs(wsBears:GetChildren()) do
        if isBearTargetable(bear) and isPriorityBear(bear) then
            local bearHum = bear:FindFirstChildOfClass("Humanoid")
            if bearHum and bearHum.Health > 0 then
                local bearRoot = bear:FindFirstChild("HumanoidRootPart") or bear.PrimaryPart or bear:FindFirstChildWhichIsA("BasePart")
                if bearRoot then
                    local dist = (bearRoot.Position - root.Position).Magnitude
                    if dist < bestPriorityDist then
                        bestPriorityDist = dist
                        bestPriorityBear = bear
                    end
                end
            end
        end
    end

    if bestPriorityBear then
        lockedFarmTarget = bestPriorityBear
        return bestPriorityBear, bestPriorityDist
    end

    -- 1. Sticky Target Lock: Stay locked onto the current bear until it is completely dead!
    if lockedFarmTarget and lockedFarmTarget.Parent and isBearTargetSelected(lockedFarmTarget) then
        if lockedFarmTarget == LocalPlayer.Character or lockedFarmTarget.Name == LocalPlayer.Name or Players:FindFirstChild(lockedFarmTarget.Name) then
            lockedFarmTarget = nil
        end
    end
    if lockedFarmTarget and lockedFarmTarget.Parent and isBearTargetSelected(lockedFarmTarget) then
        local lockedHum = lockedFarmTarget:FindFirstChildOfClass("Humanoid")
        local lockedRoot = lockedFarmTarget:FindFirstChild("HumanoidRootPart") or lockedFarmTarget.PrimaryPart or lockedFarmTarget:FindFirstChildWhichIsA("BasePart")
        if lockedHum and lockedHum.Health > 0 and lockedRoot and lockedRoot.Parent then
            local dist = (lockedRoot.Position - root.Position).Magnitude
            return lockedFarmTarget, dist
        end
    end

    -- 2. Target died, despawned, or unselected: unlock and acquire next closest selected bear
    lockedFarmTarget = nil

    local bestBear = nil
    local bestDist = math.huge

    for _, bear in ipairs(wsBears:GetChildren()) do
        if isBearTargetSelected(bear) then
            local bearHum = bear:FindFirstChildOfClass("Humanoid")
            if bearHum and bearHum.Health > 0 then
                local bearRoot = bear:FindFirstChild("HumanoidRootPart") or bear.PrimaryPart or bear:FindFirstChildWhichIsA("BasePart")
                if bearRoot then
                    local dist = (bearRoot.Position - root.Position).Magnitude
                    if dist < bestDist then
                        bestDist = dist
                        bestBear = bear
                    end
                end
            end
        end
    end

    if bestBear then
        lockedFarmTarget = bestBear
    end

    return bestBear, bestDist
end

local isFleeingLowHP = false
local activeFlightBear = nil
local activeFlightEvading = false

-- Sky Sanctuary Safe Zone Baseplate Engine
local skySanctuaryPart = nil
local SKY_SANCTUARY_POS = Vector3.new(52, 140, -144)
local lastSanctuaryNotify = 0

local function ensureSkySanctuary()
    if skySanctuaryPart and skySanctuaryPart.Parent then
        return skySanctuaryPart
    end
    local existing = Workspace:FindFirstChild("UnknownHub_SkySanctuary")
    if existing then
        skySanctuaryPart = existing
        return existing
    end

    local plate = Instance.new("Part")
    plate.Name = "UnknownHub_SkySanctuary"
    plate.Size = Vector3.new(50, 3, 50)
    plate.CFrame = CFrame.new(SKY_SANCTUARY_POS.X, SKY_SANCTUARY_POS.Y - 2.5, SKY_SANCTUARY_POS.Z)
    plate.Anchored = true
    plate.CanCollide = true
    plate.Material = Enum.Material.SmoothPlastic
    plate.Color = Color3.fromRGB(15, 20, 30)
    plate.CastShadow = false
    plate.Parent = Workspace

    local border = Instance.new("SelectionBox")
    border.Adornee = plate
    border.Color3 = Color3.fromRGB(0, 220, 255)
    border.LineThickness = 0.08
    border.Parent = plate

    skySanctuaryPart = plate
    return plate
end

local function teleportToSkySanctuary()
    ensureSkySanctuary()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then
        root.CFrame = CFrame.new(SKY_SANCTUARY_POS)
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end
end

-- Dynamic Proximity Threat Ceiling Engine
-- Detects nearby tall/giant entities (WallBear, TallBear, Grinder) AND lethal phantoms (GhostBear)
local function getNearbyThreatCeiling(playerPos, currentTarget)
    local highestThreatY = 0
    local pushRepelVector = Vector3.zero
    local wsBears = workspace:FindFirstChild("Bears")
    if not wsBears then return highestThreatY, pushRepelVector end

    for _, otherBear in ipairs(wsBears:GetChildren()) do
        if otherBear ~= currentTarget and otherBear.Parent then
            local isGhost = otherBear.Name:lower():find("ghost") ~= nil
            local otherHum = otherBear:FindFirstChildOfClass("Humanoid")
            if isGhost or (otherHum and otherHum.Health > 0) then
                local otherRoot = otherBear:FindFirstChild("HumanoidRootPart") or otherBear.PrimaryPart or otherBear:FindFirstChildWhichIsA("BasePart")
                if otherRoot then
                    local xzDist = Vector2.new(otherRoot.Position.X - playerPos.X, otherRoot.Position.Z - playerPos.Z).Magnitude
                    if isGhost and xzDist < 42 then
                        local oCf, oSz = otherBear:GetBoundingBox()
                        local ghostTopY = oCf.Position.Y + (oSz.Y * 0.5) + 24.0
                        if ghostTopY > highestThreatY then
                            highestThreatY = ghostTopY
                        end
                        local fromThreat = Vector3.new(playerPos.X - otherRoot.Position.X, 0, playerPos.Z - otherRoot.Position.Z)
                        if fromThreat.Magnitude > 0.1 then
                            pushRepelVector = pushRepelVector + (fromThreat.Unit * 12.0)
                        end
                    elseif not isGhost and xzDist < 48 then
                        -- Broad danger zone for hostile third-party bears (AOE slams, spikes, rockets, lunges)
                        local oCf, oSz = otherBear:GetBoundingBox()
                        local realHeight = math.clamp(oSz.Y, 2, 42)
                        -- Hoist at least 14 studs above other bear to be completely clear of all AOE radius
                        local otherTopY = oCf.Position.Y + (realHeight * 0.5) + 14.0
                        if otherTopY > highestThreatY then
                            highestThreatY = otherTopY
                        end
                        -- If dangerously close (within 24 studs), push horizontally away to evade point-blank AOE
                        if xzDist < 24 then
                            local fromThreat = Vector3.new(playerPos.X - otherRoot.Position.X, 0, playerPos.Z - otherRoot.Position.Z)
                            if fromThreat.Magnitude > 0.1 then
                                pushRepelVector = pushRepelVector + (fromThreat.Unit * 8.0)
                            end
                        end
                    end
                end
            end
        end
    end
    return highestThreatY, pushRepelVector
end

-- Pipeline 1: 60+ FPS Butter-Smooth Levitation Flight (RunService.Heartbeat)
-- Decoupled from combat task.wait pauses; updates every single physics frame without stutter or delay
RunService.Heartbeat:Connect(function(dt)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not char or not root or not hum or hum.Health <= 0 then return end

    -- Anti-Void Failsafe: Catch character before dropping into void below map floor
    if root.Position.Y < -170 then
        root.AssemblyLinearVelocity = Vector3.zero
        root.CFrame = CFrame.new(root.Position.X, -132, root.Position.Z)
    end

    -- Ragdoll Safety Guard & Anti-Ragdoll Recovery Engine
    local isRagdolled = char:FindFirstChild("RagdollTag") ~= nil
        or hum:GetState() == Enum.HumanoidStateType.Physics
        or hum:GetState() == Enum.HumanoidStateType.Ragdoll
        or hum.PlatformStanding
        or char:GetAttribute("BoneRagdolled") ~= nil

    if isRagdolled then
        if Config.AntiRagdoll then
            recoverFromRagdoll()
        else
            if not root.CanCollide then root.CanCollide = true end
            return
        end
    end

    if not Config.FlyNoclip and not root.CanCollide then
        root.CanCollide = true
    end
end)

-- =========================================================================
-- Intelligent Multi-Variant Ability Rotator & Dynamic Cooldown Tracker
-- =========================================================================
local abilityCooldowns = {}
local bearVariantIndex = 0
local lastBearAttack = 0

-- Connect to server ability cooldown broadcasts
pcall(function()
    local RS = game:GetService("ReplicatedStorage")
    local pb = RS:FindFirstChild("SharedEvents") and RS.SharedEvents:FindFirstChild("PlayerBears")
    local bearAbility = pb and pb:FindFirstChild("BearAbility")
    if bearAbility and bearAbility:IsA("RemoteEvent") then
        bearAbility.OnClientEvent:Connect(function(action, slot, cooldownTimestamp)
            if action == "Cooldown" and cooldownTimestamp then
                abilityCooldowns[tostring(slot)] = cooldownTimestamp
            end
        end)
    end
end)

local function isAbilityReady(slot)
    local cd = abilityCooldowns[tostring(slot)]
    if not cd then return true end
    return workspace:GetServerTimeNow() >= (cd - 0.05)
end

-- Universal Bear Ability Variant Discovery: Returns ordered list of active/unlocked abilities
local function getBearAttackVariants(char)
    if not char then return {"Default"} end
    local transformedBear = char:GetAttribute("TransformedToBear") or ""
    local bearLevel = char:GetAttribute("BearLevel") or 1
    
    local RS = game:GetService("ReplicatedStorage")
    local bearIconsMod = RS:FindFirstChild("BearIcons")
    local iconData = nil
    if bearIconsMod then
        pcall(function()
            local bi = require(bearIconsMod)
            if bi and bi.PlayerBear then
                iconData = bi.PlayerBear(transformedBear)
            end
        end)
    end

    local variants = {}
    table.insert(variants, "Default")

    local unlockStr = char:GetAttribute("BearHotbarUnlock") or ""
    local unlockLevels = {}
    for seg in string.gmatch(unlockStr, "[^,]+") do
        table.insert(unlockLevels, tonumber(seg) or 1)
    end

    local numHotbarSlots = 0
    if iconData and iconData.Hotbar then
        numHotbarSlots = #iconData.Hotbar
    else
        local tbLower = transformedBear:lower()
        numHotbarSlots = (tbLower:find("grinder") or tbLower:find("ice")) and 6 or 2
    end

    for slotIdx = 1, numHotbarSlots do
        local requiredLvl = unlockLevels[slotIdx] or 1
        if bearLevel >= requiredLvl then
            table.insert(variants, slotIdx)
        end
    end

    return variants
end

-- Pipeline 2: Autonomous Combat & Target Acquisition Loop
task.spawn(function()
    while true do
        task.wait(0.06)
        if not Config.AutoFarmBears then
            isFleeingLowHP = false
            activeFlightBear = nil
            activeFlightEvading = false
            task.wait(0.3)
            continue
        end

        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")

        if not char or not root or not hum or hum.Health <= 0 then
            activeFlightBear = nil
            task.wait(0.5)
            continue
        end

        -- =========================================================================
        -- CRATE PRIORITY PIPELINE SCHEDULER:
        -- If AutoFarmCrates is enabled and there are crates to collect:
        -- - If currently fighting a locked target bear: finish killing it first!
        -- - As soon as that bear dies (or if no bear is currently engaged):
        --   immediately yield bear farm, clear active flight target, and let crate farm run!
        -- =========================================================================
        if Config.AutoFarmCrates then
            local crateTarget = getNextCrateTarget()
            if crateTarget ~= nil or isCratesActivelyFarming then
                local canFinishCurrentLocked = false
                if lockedFarmTarget and lockedFarmTarget.Parent and isBearTargetSelected(lockedFarmTarget) then
                    local lockedHum = lockedFarmTarget:FindFirstChildOfClass("Humanoid")
                    if lockedHum and lockedHum.Health > 0 then
                        canFinishCurrentLocked = true
                    end
                end

                if not canFinishCurrentLocked then
                    lockedFarmTarget = nil
                    activeFlightBear = nil
                    activeFlightEvading = false
                    task.wait(0.25)
                    continue
                end
            end
        end

        local maxHp = (hum.MaxHealth and hum.MaxHealth > 0) and hum.MaxHealth or 250

        -- 1. Low HP Safety Check & Safe Zone Retreat
        if Config.SafeZoneLowHP then
            if hum.Health <= Config.LowHPThreshold then
                isFleeingLowHP = true
            end

            if isFleeingLowHP then
                activeFlightBear = nil
                if (root.Position - SKY_SANCTUARY_POS).Magnitude > 15 then
                    teleportToSkySanctuary()
                    Hub.Notify("Bear Farm", "Low HP (" .. math.floor(hum.Health) .. " HP)! Retreated to Sky Sanctuary...", 2)
                end

                -- Stay in safe zone until healed back to 85%+
                if hum.Health >= math.floor(maxHp * 0.85) then
                    isFleeingLowHP = false
                    Hub.Notify("Bear Farm", "HP Restored (" .. math.floor(hum.Health) .. " HP)! Resuming Bear Farm...", 2)
                else
                    task.wait(0.5)
                    continue
                end
            end
        end

        -- 2. Equip Best Weapon for chosen FarmMethod / Autonomous Bear Transform
        local bestTool = nil
        if Config.FarmMethod ~= "Bear Attack" then
            bestTool = ensureBestWeaponEquipped(Config.FarmMethod)
            if not bestTool then
                activeFlightBear = nil
                Hub.Notify("Bear Farm", "No " .. Config.FarmMethod .. " weapon found in inventory!", 2)
                task.wait(2)
                continue
            end
        else
            -- Bear Attack Mode: Ensure player is transformed into a bear!
            local transformedBear = char:GetAttribute("TransformedToBear") or char:GetAttribute("Stance")
            if not transformedBear then
                pcall(function()
                    local RS = game:GetService("ReplicatedStorage")
                    local becomeRemote = RS:FindFirstChild("SharedEvents") and RS.SharedEvents:FindFirstChild("PlayerBears") and RS.SharedEvents.PlayerBears:FindFirstChild("BecomeBear")
                    if becomeRemote then
                        local chosenBear = Config.SpawnAsBear or "booboo"
                        local s, err = becomeRemote:InvokeServer(chosenBear, "Become")
                        if not s then
                            becomeRemote:InvokeServer(chosenBear, "OneTime")
                        end
                    end
                end)
            end
            -- Autonomous Friendly Stance Enforcement: Attacks wild bears & player/turrets cannot damage user
            if char:GetAttribute("Stance") ~= "Friendly" then
                pcall(function()
                    local RS = game:GetService("ReplicatedStorage")
                    local bearAbility = RS:FindFirstChild("SharedEvents") and RS.SharedEvents:FindFirstChild("PlayerBears") and RS.SharedEvents.PlayerBears:FindFirstChild("BearAbility")
                    if bearAbility then
                        bearAbility:FireServer("Stance")
                    end
                end)
            end
        end

        -- 3. Acquire Target Bear
        local bear, dist = getFarmBearTarget()
        if not bear then
            activeFlightBear = nil
            ensureSkySanctuary()
            if (root.Position - SKY_SANCTUARY_POS).Magnitude > 15 then
                teleportToSkySanctuary()
                if tick() - lastSanctuaryNotify >= 8 then
                    lastSanctuaryNotify = tick()
                    Hub.Notify("Safe Zone", "All target bears cleared! Resting in Sky Sanctuary...", 2.5)
                end
            end
            task.wait(0.4)
            continue
        end

        local bearRoot = bear:FindFirstChild("HumanoidRootPart") or bear.PrimaryPart or bear:FindFirstChildWhichIsA("BasePart")
        local bearHum = bear:FindFirstChildOfClass("Humanoid")
        if not bearRoot or not bearHum or bearHum.Health <= 0 then
            activeFlightBear = nil
            task.wait(0.1)
            continue
        end

        -- Safe Blindspot Positioning (Tight & Elevated: 100% Reach for Melee & Bear Attack while evading front swipes)
        local cf, sz = bear:GetBoundingBox()
        local bearCF = bearRoot.CFrame
        local flatLook = Vector3.new(bearCF.LookVector.X, 0, bearCF.LookVector.Z)
        if flatLook.Magnitude < 0.05 then flatLook = Vector3.new(0, 0, -1) else flatLook = flatLook.Unit end

        local bName = bear.Name:lower()
        local isBooBoo = bName:find("boo") ~= nil or bName:find("ball") ~= nil or sz.Y < 6.5 or sz.Magnitude < 8
        local isTallBear = bName:find("tall") ~= nil or sz.Y > 16
        local isRangedBear = bName:find("ranged") or bName:find("spike")
        local isWallBear = bName:find("wall") ~= nil
        local isGrinderBear = bName:find("grinder") or bName:find("robo")

        local targetPos, distBehind, elevY
        if Config.FarmMethod == "Melee" or Config.FarmMethod == "Bear Attack" then
            if isBooBoo then
                distBehind = 2.2
                elevY = 1.6
            elseif isTallBear then
                distBehind = 3.2
                elevY = 3.6
            elseif isGrinderBear then
                distBehind = 3.6
                elevY = 3.5
            elseif isWallBear then
                distBehind = 3.5
                elevY = 3.0
            elseif isRangedBear then
                distBehind = 3.0
                elevY = 2.2
            else
                -- Medved, GrizzlyMedved, ThinBear, IceBear, WormBear, ClassicBear, etc.
                distBehind = 3.0
                elevY = 2.2
            end

            targetPos = bearRoot.Position - (flatLook * distBehind) + Vector3.new(0, elevY, 0)
        else
            -- Gun Mode: Safe standoff distance & elevation
            distBehind = 9.0
            elevY = 6.0
            targetPos = bearRoot.Position - (flatLook * distBehind) + Vector3.new(0, elevY, 0)
        end

        -- Dynamically resolve the CLOSEST hitbox part to the player so server distance checks ALWAYS pass!
        local targetHitPart = nil
        local bestPartDist = math.huge
        local candidatePartNames = {
            "Hitbox_Hips", "Hitbox_Pelvis", "Hitbox_Chest", "Hitbox_Torso",
            "Hitbox_Head", "Hitbox_Crown", "Head", "BodyTop", "Ears",
            "Hitbox_Body", "RootPart", "HumanoidRootPart"
        }
        for _, pName in ipairs(candidatePartNames) do
            local p = bear:FindFirstChild(pName)
            if p and p:IsA("BasePart") then
                local d = (p.Position - targetPos).Magnitude
                if d < bestPartDist then
                    bestPartDist = d
                    targetHitPart = p
                end
            end
        end
        if not targetHitPart then
            targetHitPart = bearRoot
        end

        -- Aim and orient character directly facing the closest hit part
        local aimPos = targetHitPart.Position
        root.CFrame = CFrame.lookAt(targetPos, aimPos)
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero

        -- 5. Attack Execution (Zero Stutter / Smooth Flight Preserved, Melee Reach Guaranteed & Flamethrower)
        if Config.FarmMethod == "Melee" then
            if bestTool then
                applyWeaponMods(bestTool)
                -- Execute melee swing from tight blindspot with dual network dispatch
                if tick() - lastMeleeSwing >= 0.16 then
                    lastMeleeSwing = tick()
                    pcall(function()
                        bestTool:Activate()
                    end)

                    local meleeRemote = bestTool:FindFirstChild("MeleeRemote", true)
                        or (bestTool:FindFirstChild("MeleeScripts") and bestTool.MeleeScripts:FindFirstChild("MeleeRemote"))
                    if meleeRemote and targetHitPart then
                        pcall(function()
                            meleeRemote:FireServer("Hit", targetHitPart)
                        end)
                        if bearRoot and bearRoot ~= targetHitPart then
                            pcall(function()
                                meleeRemote:FireServer("Hit", bearRoot)
                            end)
                        end
                    end
                end
            end
        elseif Config.FarmMethod == "Gun" then
            local isFlame = bestTool:FindFirstChild("FlameRemote") or bestTool.Name == "Flamethrower"
            if isFlame and bestTool then
                applyWeaponMods(bestTool)
                local flameRemote = bestTool:FindFirstChild("FlameRemote")
                local fuel = bestTool:GetAttribute("Fuel") or 1
                local targetPart = bear:FindFirstChild("BodyTop") or bear:FindFirstChild("Hitbox_Head") or bear:FindFirstChild("Hitbox_Chest") or bearRoot
                if fuel > 0.05 and targetPart and flameRemote then
                    flameRemote:FireServer("Aim", targetPart.Position)
                    flameRemote:FireServer("Start")
                elseif flameRemote then
                    flameRemote:FireServer("Stop")
                end
            elseif bestTool then
                applyWeaponMods(bestTool)
                local currentAmmo, reloading = getLoadedAmmoFromGUI(bestTool)
                if not reloading and currentAmmo <= 0 and tick() >= reloadEndTime then
                    triggerGunReload(bestTool)
                elseif not reloading and currentAmmo > 0 then
                    local targetPart = bear:FindFirstChild("BodyTop") or bear:FindFirstChild("Ears") or bear:FindFirstChild("Hitbox_Head") or bear:FindFirstChild("Hitbox_Chest") or bear:FindFirstChild("Hitbox_Torso") or bearRoot
                    shootTargetBear(bestTool, bear, targetPart)
                elseif not reloading and currentAmmo <= 0 then
                    triggerGunReload(bestTool)
                end
            end
        elseif Config.FarmMethod == "Bear Attack" then
            local RS = game:GetService("ReplicatedStorage")
            local pb = RS:FindFirstChild("SharedEvents") and RS.SharedEvents:FindFirstChild("PlayerBears")
            local bearAbility = pb and pb:FindFirstChild("BearAbility")

            -- Authoritative Remote Ability Variant Dispatch (Seamless Grinder & Multi-Skill Rotation)
            if tick() - lastBearAttack >= 0.12 then
                lastBearAttack = tick()
                
                if bearAbility then
                    local variants = getBearAttackVariants(char)
                    if #variants > 0 then
                        local fired = false
                        for step = 1, #variants do
                            bearVariantIndex = (bearVariantIndex % #variants) + 1
                            local candidateVariant = variants[bearVariantIndex]
                            if isAbilityReady(candidateVariant) then
                                pcall(function()
                                    bearAbility:FireServer("Use", candidateVariant, aimPos)
                                end)
                                abilityCooldowns[tostring(candidateVariant)] = workspace:GetServerTimeNow() + 0.35
                                fired = true
                                break
                            end
                        end
                        if not fired then
                            pcall(function()
                                bearAbility:FireServer("Use", "Default", aimPos)
                            end)
                        end
                    else
                        pcall(function()
                            bearAbility:FireServer("Use", "Default", aimPos)
                        end)
                    end
                end

                local bearTool = char:FindFirstChildOfClass("Tool")
                if bearTool then
                    pcall(function()
                        bearTool:Activate()
                    end)
                end
            end
        end
    end
end)

-- =========================================================================
-- Autonomous Bear Friendly Stance Daemon
-- Ensures player bear remains in Friendly stance at all times (attacks wild bears & immune to players/turrets)
-- =========================================================================
task.spawn(function()
    while true do
        task.wait(0.4)
        if Config.AutoFriendlyBear or (Config.AutoFarmBears and Config.FarmMethod == "Bear Attack") then
            local char = LocalPlayer.Character
            if char and char:GetAttribute("TransformedToBear") then
                local stance = char:GetAttribute("Stance")
                if stance ~= "Friendly" then
                    pcall(function()
                        local RS = game:GetService("ReplicatedStorage")
                        local bearAbility = RS:FindFirstChild("SharedEvents") and RS.SharedEvents:FindFirstChild("PlayerBears") and RS.SharedEvents.PlayerBears:FindFirstChild("BearAbility")
                        if bearAbility then
                            bearAbility:FireServer("Stance")
                        end
                    end)
                end
            end
        end
    end
end)

-- =========================================================================
-- Native Fly-Noclip Engine (Bypass Physics Collisions & Anti-Cheat Safe)
-- =========================================================================
local flyConnection = nil
local noclipConnection = nil

local function startFlyNoclip()
    if flyConnection then return end
    local UserInputService = game:GetService("UserInputService")

    -- 1. Continuous Pre-Physics Collision Neutralization on Stepped (Eliminates wall pushback & collision bounce)
    if not noclipConnection then
        noclipConnection = RunService.Stepped:Connect(function()
            if not Config.FlyNoclip then return end
            local char = LocalPlayer.Character
            if not char then return end
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") and p.CanCollide then
                    p.CanCollide = false
                end
            end
        end)
    end

    -- 2. Butter-Smooth Flight Engine with Damped Inertia & Camera Alignment
    local flyVelocity = Vector3.zero
    flyConnection = RunService.RenderStepped:Connect(function(dt)
        if not Config.FlyNoclip then return end
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not char or not root or not hum or hum.Health <= 0 then return end

        -- Lock Humanoid state to Freefall so Roblox's internal ground raycast doesn't fight our flight vector
        if hum:GetState() ~= Enum.HumanoidStateType.Freefall and hum:GetState() ~= Enum.HumanoidStateType.Physics then
            hum:ChangeState(Enum.HumanoidStateType.Freefall)
        end

        local camera = Workspace.CurrentCamera
        if not camera then return end

        local targetDir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then targetDir = targetDir + camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then targetDir = targetDir - camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then targetDir = targetDir + camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then targetDir = targetDir - camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then targetDir = targetDir + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            targetDir = targetDir - Vector3.new(0, 1, 0)
        end

        local speed = Config.FlySpeed or 45
        local targetVelocity = (targetDir.Magnitude > 0) and (targetDir.Unit * speed) or Vector3.zero
        flyVelocity = flyVelocity:Lerp(targetVelocity, math.clamp(dt * 14, 0.15, 0.6))

        if flyVelocity.Magnitude > 0.05 then
            root.CFrame = root.CFrame + (flyVelocity * dt)
        end

        local camLook = camera.CFrame.LookVector
        local flatCamLook = Vector3.new(camLook.X, 0, camLook.Z)
        if flatCamLook.Magnitude > 0.05 then
            local targetCF = CFrame.lookAt(root.Position, root.Position + flatCamLook)
            root.CFrame = root.CFrame:Lerp(targetCF, math.clamp(dt * 16, 0.2, 0.7))
        end

        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end)
end

local function stopFlyNoclip()
    if flyConnection then
        flyConnection:Disconnect()
        flyConnection = nil
    end
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if root then
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        root.CanCollide = true
    end
    if hum and hum.Health > 0 then
        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
    end
end

-- Native Undetectable Speed Modifier Engine (Using Game's SpeedModifiers Framework)
local SpeedModifiersModule = ReplicatedStorage:FindFirstChild("SpeedModifiers")
local SpeedModifiers = SpeedModifiersModule and require(SpeedModifiersModule)

local currentAppliedSpeedMod = nil
local function ensureSpeedModifier(char)
    if not char then return end
    local targetMod = (Config.CustomSpeed and Config.CustomSpeed > 14.1) and ((Config.CustomSpeed / 14.1) - 1) or 0
    if targetMod == currentAppliedSpeedMod then return end
    currentAppliedSpeedMod = targetMod

    if targetMod <= 0 then
        if SpeedModifiers then
            pcall(function() SpeedModifiers.Remove(char, "UnknownSpeedMod") end)
        else
            local speedFolder = char:FindFirstChild("SpeedModifiers")
            local speedMod = speedFolder and speedFolder:FindFirstChild("UnknownSpeedMod")
            if speedMod then pcall(function() speedMod:Destroy() end) end
        end
        return
    end

    if SpeedModifiers then
        pcall(function()
            SpeedModifiers.Set(char, "UnknownSpeedMod", targetMod)
        end)
    else
        local speedFolder = char:FindFirstChild("SpeedModifiers")
        if not speedFolder then
            speedFolder = Instance.new("Folder")
            speedFolder.Name = "SpeedModifiers"
            speedFolder.Parent = char
        end
        local speedMod = speedFolder:FindFirstChild("UnknownSpeedMod")
        if not speedMod then
            speedMod = Instance.new("NumberValue")
            speedMod.Name = "UnknownSpeedMod"
            speedMod.Parent = speedFolder
        end
        speedMod.Value = targetMod
    end
end

LocalPlayer.CharacterAdded:Connect(function(newChar)
    currentAppliedSpeedMod = nil
    task.wait(0.1)
    ensureSpeedModifier(newChar)
    local hum = newChar:WaitForChild("Humanoid", 3)
    if hum then
        local maxHp = hum.MaxHealth > 0 and hum.MaxHealth or 250
        local minAllowed = math.max(1, math.floor(maxHp * 0.10))
        local maxAllowed = math.max(2, math.floor(maxHp * 0.50))
        Config.LowHPThreshold = math.clamp(Config.LowHPThreshold, minAllowed, maxAllowed)
    end
end)

RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end

    -- 1. Infinite Stamina
    local sprintScript = char:FindFirstChild("Sprinting")
    if sprintScript and Config.InfiniteStamina then
        sprintScript:SetAttribute("Stamina", 1)
    end

    -- 2. WalkSpeed & SprintingSpeed Multiplier via Game's SpeedModifiers
    ensureSpeedModifier(char)

    -- 3. Auto Unlock Bunker & Security Doors
    if Config.AutoUnlockDoors then
        LocalPlayer:SetAttribute("BunkerUnlocked", true)
        LocalPlayer:SetAttribute("KeycardAccess", true)
        LocalPlayer:SetAttribute("AccessGranted", true)
        local CollectionService = game:GetService("CollectionService")
        for _, d in ipairs(CollectionService:GetTagged("Door")) do
            if d:GetAttribute("Locked") == true then
                d:SetAttribute("Locked", false)
            end
        end
    end
end)

--------------------------------------------------------------------------------
-- 8. ESP SYSTEMS (CRATES & BEARS)
--------------------------------------------------------------------------------
local function clearCrateESP()
    for _, obj in pairs(activeESP) do
        if obj and obj.Parent then
            pcall(function() obj:Destroy() end)
        end
    end
    table.clear(activeESP)
end

local activeTurretESP = {}

local function clearTurretESP()
    for _, obj in pairs(activeTurretESP) do
        if obj and obj.Parent then pcall(function() obj:Destroy() end) end
    end
    table.clear(activeTurretESP)
end

local function updateTurretsESP()
    clearTurretESP()
    if not Config.TurretsESP then return end

    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local CollectionService = game:GetService("CollectionService")

    for _, t in ipairs(CollectionService:GetTagged("Turret")) do
        if t:IsA("Model") and t:IsDescendantOf(Workspace) then
            local head = t:FindFirstChild("Head") or t.PrimaryPart or t:FindFirstChildWhichIsA("BasePart")
            if head then
                local hp = t:GetAttribute("Health") or 150
                local maxHp = t:GetAttribute("MaxHealth") or 150
                local breached = t:GetAttribute("Breached")
                local dist = root and math.floor((root.Position - head.Position).Magnitude) or 0

                local bb = Instance.new("BillboardGui")
                bb.Name = "TurretESP"
                bb.Adornee = head
                bb.Size = UDim2.new(0, 130, 0, 30)
                bb.StudsOffset = Vector3.new(0, 2.8, 0)
                bb.AlwaysOnTop = true

                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(1, 0, 1, 0)
                lbl.BackgroundTransparency = 1
                lbl.Font = Enum.Font.GothamBold
                lbl.TextSize = 12
                lbl.TextStrokeTransparency = 0.2
                lbl.TextColor3 = (hp < maxHp * 0.4 or breached) and Color3.fromRGB(255, 60, 60) or Color3.fromRGB(80, 255, 120)
                lbl.Text = string.format("🔫 Sentry [%d/%d]\n[%d studs]%s", hp, maxHp, dist, breached and " [BREACHED]" or "")
                lbl.Parent = bb
                bb.Parent = head
                table.insert(activeTurretESP, bb)
            end
        end
    end
end

local function updateCratesESP()
    clearCrateESP()
    if not Config.CratesESP then return end

    local interactables = Workspace:FindFirstChild("Interactables")
    local cratesFolder = interactables and interactables:FindFirstChild("Crates")
    if not cratesFolder then return end

    for _, c in ipairs(cratesFolder:GetChildren()) do
        local cratePart = c:FindFirstChild("Crate")
        if cratePart then
            local itemPrompts = getCrateItemPrompts(c)
            local collected = c:GetAttribute("Collected")
            local openPrompt = cratePart:FindFirstChild("CratePrompt")
            local isUnopened = (collected ~= true and openPrompt and openPrompt.Enabled)
            local hasLoot = (#itemPrompts > 0)

            if isUnopened or hasLoot then
                local bb = Instance.new("BillboardGui")
                bb.Name = "CrateESP"
                bb.Adornee = cratePart
                bb.Size = UDim2.new(0, 110, 0, 30)
                bb.AlwaysOnTop = true
                bb.StudsOffset = Vector3.new(0, 2.2, 0)

                local label = Instance.new("TextLabel")
                label.Size = UDim2.new(1, 0, 1, 0)
                label.BackgroundTransparency = 1
                if hasLoot then
                    label.Text = "💰 [LOOT] " .. c.Name
                    label.TextColor3 = Color3.fromRGB(255, 220, 60)
                else
                    label.Text = "📦 " .. c.Name
                    label.TextColor3 = Color3.fromRGB(0, 240, 255)
                end
                label.Font = Enum.Font.GothamBold
                label.TextSize = 11
                label.Parent = bb

                bb.Parent = CoreGui
                table.insert(activeESP, bb)
            end
        end
    end
end

local function clearBearESP()
    for _, obj in pairs(activeBearESP) do
        if obj and obj.Parent then
            pcall(function() obj:Destroy() end)
        end
    end
    table.clear(activeBearESP)
end

local function updateBearESP()
    clearBearESP()
    if not Config.BearsESP then return end

    local bearsFolder = Workspace:FindFirstChild("Bears")
    if not bearsFolder then return end

    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")

    for _, b in ipairs(bearsFolder:GetChildren()) do
        if b ~= myChar then
            local hum = b:FindFirstChildOfClass("Humanoid")
            -- Filter out dead bears and corpses (health <= 0 or missing humanoid)
            if hum and hum.Health > 0 then
                local adorneePart = b:FindFirstChild("HumanoidRootPart") or b:FindFirstChild("Head") or b.PrimaryPart or b:FindFirstChildOfClass("BasePart")
                if adorneePart then
                    local bearName = b:GetAttribute("BearID") or b.Name
                    local isPlayer = false
                    if Players:GetPlayerFromCharacter(b) or b:GetAttribute("IsPlayer") then
                        isPlayer = true
                    end

                    local distStr = ""
                    if myRoot then
                        local d = math.floor((adorneePart.Position - myRoot.Position).Magnitude)
                        distStr = " [" .. d .. "m]"
                    end

                    local hpStr = " [" .. math.floor(hum.Health) .. " HP]"

                    local bb = Instance.new("BillboardGui")
                    bb.Name = "BearESP"
                    bb.Adornee = adorneePart
                    bb.Size = UDim2.new(0, 140, 0, 32)
                    bb.AlwaysOnTop = true
                    bb.StudsOffset = Vector3.new(0, 3.5, 0)

                    local label = Instance.new("TextLabel")
                    label.Size = UDim2.new(1, 0, 1, 0)
                    label.BackgroundTransparency = 1
                    label.Text = "🐻 " .. bearName .. hpStr .. distStr
                    if isPlayer then
                        label.TextColor3 = Color3.fromRGB(255, 60, 180)
                    else
                        label.TextColor3 = Color3.fromRGB(255, 75, 75)
                    end
                    label.Font = Enum.Font.GothamBold
                    label.TextSize = 11
                    label.Parent = bb

                    bb.Parent = CoreGui
                    table.insert(activeBearESP, bb)
                end
            end
        end
    end
end

task.spawn(function()
    while true do
        task.wait(2.0)
        if Config.CratesESP then updateCratesESP() end
        if Config.BearsESP then updateBearESP() end
        if Config.TurretsESP then updateTurretsESP() end
    end
end)

--------------------------------------------------------------------------------
-- 9. UI TABS & CONTROLS
--------------------------------------------------------------------------------

-- TAB: AUTO FARM
local farmTab = Hub.CreateTab("Auto Farm", {
    Icon = "🌾",
    Size = 18,
    Color = Color3.fromRGB(0, 195, 245),
    ActiveColor = Color3.fromRGB(0, 230, 255)
})

Hub.CreateSection(farmTab, "Crates")

Hub.CreateToggle(farmTab, "Auto Farm Crates", Config.AutoFarmCrates, function(val)
    Config.AutoFarmCrates = val
    if val then
        silenceTelemetry()
        table.clear(crateAttempts)
        table.clear(blacklistedCrates)
        table.clear(openedCrates)
    end
    Hub.Notify("Auto Farm", val and "Crate Farm: ACTIVE" or "Crate Farm: OFF", 2)
end)

Hub.CreateSlider(farmTab, "Farm Delay", 0.2, 1.5, Config.FarmDelay, "s", function(val)
    Config.FarmDelay = val
end)

Hub.CreateToggle(farmTab, "Auto Serverhop", Config.AutoServerhop, function(val)
    Config.AutoServerhop = val
end)

Hub.CreateSection(farmTab, "Pages")

Hub.CreateToggle(farmTab, "Auto Collect Pages", Config.AutoCollectPages, function(val)
    Config.AutoCollectPages = val
    if val then
        silenceTelemetry()
    end
    Hub.Notify("Pages", val and "Page Collector: ACTIVE" or "Page Collector: OFF", 2)
end)



-- Auto Farm Bears UI Controls & Dynamic Low HP Bounds
local initialChar = LocalPlayer.Character
local initialHum = initialChar and initialChar:FindFirstChildOfClass("Humanoid")
local initialMaxHp = (initialHum and initialHum.MaxHealth and initialHum.MaxHealth > 0) and initialHum.MaxHealth or 250
local minHpVal = math.max(1, math.floor(initialMaxHp * 0.10))
local maxHpVal = math.max(2, math.floor(initialMaxHp * 0.50))
local defaultHpVal = math.clamp(math.floor(initialMaxHp * 0.25), minHpVal, maxHpVal)
Config.LowHPThreshold = defaultHpVal

Hub.CreateSection(farmTab, "Bears")

Hub.CreateToggle(farmTab, "Auto Farm Bears", Config.AutoFarmBears, function(val)
    Config.AutoFarmBears = val
    if val then
        silenceTelemetry()
    end
    Hub.Notify("Bear Farm", val and "Auto Farm Bears: ACTIVE" or "Auto Farm Bears: OFF", 2)
end)

local function getPlayableBearsList()
    local list = {
        "booboo", "ClassicBear", "CutieBear", "DemonBear", "GhostBear",
        "GoldenMedved", "GrinderBear", "GrizzlyMedved", "GrizzlyRangedBear",
        "GrizzlyTallBear", "HypersonicBooBoo", "IceBear", "LaserBooBoo",
        "Medved", "RadioactiveMedved", "RangedBear", "TallBear",
        "ThinBear", "WallBear", "WormBear", "ballbear"
    }
    pcall(function()
        local rs = game:GetService("ReplicatedStorage")
        local bearsFolder = rs:FindFirstChild("Bears")
        if bearsFolder then
            for _, b in ipairs(bearsFolder:GetChildren()) do
                if not table.find(list, b.Name) then
                    table.insert(list, b.Name)
                end
            end
        end
    end)
    table.sort(list)
    return list
end

Hub.CreateDropdown(farmTab, "Attack Method", {"Gun", "Melee", "Bear Attack"}, Config.FarmMethod, function(val)
    Config.FarmMethod = val
    Hub.Notify("Bear Farm", "Method set to: " .. val, 2)
end)

Hub.CreateDropdown(farmTab, "Spawn as", getPlayableBearsList(), Config.SpawnAsBear, function(val)
    Config.SpawnAsBear = val
    task.spawn(function()
        local RS = game:GetService("ReplicatedStorage")
        local becomeRemote = RS:FindFirstChild("SharedEvents") and RS.SharedEvents:FindFirstChild("PlayerBears") and RS.SharedEvents.PlayerBears:FindFirstChild("BecomeBear")
        if becomeRemote then
            local s, err = becomeRemote:InvokeServer(val, "Become")
            if not s then
                s, err = becomeRemote:InvokeServer(val, "OneTime")
            end
            if s then
                Hub.Notify("Bear Spawn", "Spawned as " .. val .. "!", 3)
                task.wait(0.25)
                local bearAbility = RS:FindFirstChild("SharedEvents") and RS.SharedEvents:FindFirstChild("PlayerBears") and RS.SharedEvents.PlayerBears:FindFirstChild("BearAbility")
                if bearAbility then
                    bearAbility:FireServer("Stance")
                end
            else
                Hub.Notify("Bear Spawn", "Could not spawn as " .. val .. ": " .. tostring(err), 3)
            end
        end
    end)
end)

Hub.CreateToggle(farmTab, "Auto Friendly Bear", Config.AutoFriendlyBear, function(val)
    Config.AutoFriendlyBear = val
    if val then
        local char = LocalPlayer.Character
        if char and char:GetAttribute("TransformedToBear") and char:GetAttribute("Stance") ~= "Friendly" then
            pcall(function()
                local RS = game:GetService("ReplicatedStorage")
                local bearAbility = RS:FindFirstChild("SharedEvents") and RS.SharedEvents:FindFirstChild("PlayerBears") and RS.SharedEvents.PlayerBears:FindFirstChild("BearAbility")
                if bearAbility then
                    bearAbility:FireServer("Stance")
                end
            end)
        end
    end
    Hub.Notify("Bear", val and "Auto Friendly Bear: ACTIVE" or "Auto Friendly Bear: OFF", 2)
end)

bearTypeDropdown = Hub.CreateMultiDropdown(farmTab, "Target Bears", getAvailableBearTypes(), {"All"}, function(dict, arr)
    Config.SelectedBears = dict
    Config.SelectedBearTarget = dict["All"] and "All" or (arr[1] or "None")
    local desc = dict["All"] and "All Bears" or (#arr .. " Selected")
    Hub.Notify("Bear Farm", "Targeting: " .. desc, 2)
end)

priorityBearDropdown = Hub.CreateMultiDropdown(farmTab, "Priority Bears (Kill First)", getAvailableBearTypes(), {"GrinderBear"}, function(dict, arr)
    Config.PriorityBears = dict
    local desc = dict["All"] and "All Bears" or (#arr > 0 and table.concat(arr, ", ") or "None")
    Hub.Notify("Bear Farm", "Priority Targets: " .. desc, 2)
end)

Hub.CreateToggle(farmTab, "Safe Zone Retreat", Config.SafeZoneLowHP, function(val)
    Config.SafeZoneLowHP = val
    Hub.Notify("Bear Farm", val and "Safe Zone Retreat: ON" or "Safe Zone Retreat: OFF", 2)
end)

Hub.CreateSlider(farmTab, "Low HP Threshold", minHpVal, maxHpVal, Config.LowHPThreshold, " HP", function(val)
    Config.LowHPThreshold = val
end)

-- TAB: COMBAT
local combatTab = Hub.CreateTab("Combat", {
    Icon = "⚔️",
    Size = 18,
    Color = Color3.fromRGB(255, 75, 75),
    ActiveColor = Color3.fromRGB(255, 110, 110)
})

Hub.CreateSection(combatTab, "Melee")

Hub.CreateToggle(combatTab, "Melee Aura", Config.MeleeAura, function(val)
    Config.MeleeAura = val
    Hub.Notify("Combat", val and "Melee Aura: ACTIVE" or "Melee Aura: OFF", 2)
end)

Hub.CreateSlider(combatTab, "Melee Range", 8, 30, Config.MeleeAuraRange, " studs", function(val)
    Config.MeleeAuraRange = val
end)



Hub.CreateSection(combatTab, "Firearms")

Hub.CreateToggle(combatTab, "Gun Aura", Config.GunAura, function(val)
    Config.GunAura = val
    Hub.Notify("Combat", val and "Gun Aura: ACTIVE" or "Gun Aura: OFF", 2)
end)

Hub.CreateSlider(combatTab, "Gun Range", 20, 150, Config.GunAuraRange, " studs", function(val)
    Config.GunAuraRange = val
end)



Hub.CreateSection(combatTab, "Movement")

Hub.CreateToggle(combatTab, "Fly Noclip", Config.FlyNoclip, function(val)
    Config.FlyNoclip = val
    if val then
        startFlyNoclip()
        Hub.Notify("Movement", "Fly Noclip: ACTIVE (WASD + Space/Shift)", 2.5)
    else
        stopFlyNoclip()
        Hub.Notify("Movement", "Fly Noclip: OFF", 2)
    end
end)

Hub.CreateSlider(combatTab, "Fly Speed", 15, 120, Config.FlySpeed, " spd", function(val)
    Config.FlySpeed = val
end)

Hub.CreateToggle(combatTab, "Infinite Stamina", Config.InfiniteStamina, function(val)
    Config.InfiniteStamina = val
    Hub.Notify("Movement", val and "Infinite Stamina: ACTIVE" or "Infinite Stamina: OFF", 2)
end)

Hub.CreateSlider(combatTab, "Speed Modifier", 14.1, 45, Config.CustomSpeed, " spd", function(val)
    Config.CustomSpeed = val
    ensureSpeedModifier(LocalPlayer.Character)
end)

Hub.CreateSection(combatTab, "Turrets & Sentries")

Hub.CreateToggle(combatTab, "Auto Heal Turrets", Config.AutoHealTurrets, function(val)
    Config.AutoHealTurrets = val
    Hub.Notify("Turrets", val and "Auto Heal Turrets: ACTIVE (Proximity Repair)" or "Auto Heal Turrets: OFF", 2)
end)

-- TAB: VISUALS
local visualTab = Hub.CreateTab("Visuals", {
    Icon = "👁️",
    Size = 18,
    Color = Color3.fromRGB(165, 95, 255),
    ActiveColor = Color3.fromRGB(190, 130, 255)
})

Hub.CreateSection(visualTab, "ESP")

Hub.CreateToggle(visualTab, "Crates ESP", Config.CratesESP, function(val)
    Config.CratesESP = val
    if val then
        updateCratesESP()
    else
        clearCrateESP()
    end
end)

Hub.CreateToggle(visualTab, "Bears ESP", Config.BearsESP, function(val)
    Config.BearsESP = val
    if val then
        updateBearESP()
    else
        clearBearESP()
    end
end)

Hub.CreateToggle(visualTab, "Turrets ESP", Config.TurretsESP, function(val)
    Config.TurretsESP = val
    if val then
        updateTurretsESP()
    else
        clearTurretESP()
    end
end)

-- TAB: TELEPORTS
local tpTab = Hub.CreateTab("Teleports", {
    Icon = "📍",
    Size = 18,
    Color = Color3.fromRGB(255, 170, 0),
    ActiveColor = Color3.fromRGB(255, 205, 50)
})


Hub.CreateSection(tpTab, "Landmarks")

for _, locItem in ipairs(locationRegistry) do
    Hub.CreateButton(tpTab, locItem.name, function()
        local pos = resolveLocationPosition(locItem)
        safeTeleport(pos, locItem.name)
    end)
end



-- =========================================================================
-- TAB: MISC & PROGRESSION SUITE
-- =========================================================================
local miscTab = Hub.CreateTab("Misc", {
    Icon = "⚡",
    Size = 18,
    Color = Color3.fromRGB(180, 100, 255),
    ActiveColor = Color3.fromRGB(205, 130, 255)
})

Hub.CreateSection(miscTab, "Prestige & Progression")

Hub.CreateButton(miscTab, "Remote Prestige (Instant Server Trigger)", function()
    triggerRemotePrestige()
end)

Hub.CreateButton(miscTab, "Check Prestige Cooldown", function()
    local status = getPrestigeCooldownStatus()
    Hub.Notify("Prestige Status", status, 3.5)
end)

Hub.CreateToggle(miscTab, "Auto Prestige on 32 Pages", Config.AutoPrestigeOn32, function(val)
    Config.AutoPrestigeOn32 = val
    Hub.Notify("Misc", val and "Auto Prestige: ACTIVE" or "Auto Prestige: OFF", 2)
end)

Hub.CreateSection(miscTab, "Security & Doors Override")

Hub.CreateButton(miscTab, "Unlock Bunker & All Security Doors", function()
    unlockAllDoorsAndBunker()
end)

Hub.CreateToggle(miscTab, "Auto Unlock All Doors", Config.AutoUnlockDoors, function(val)
    Config.AutoUnlockDoors = val
    if val then unlockAllDoorsAndBunker() end
    Hub.Notify("Misc", val and "Auto Unlock Doors: ACTIVE" or "Auto Unlock Doors: OFF", 2)
end)

Hub.CreateSection(miscTab, "Character & Combat Recovery")

Hub.CreateToggle(miscTab, "Anti Ragdoll", Config.AntiRagdoll, function(val)
    Config.AntiRagdoll = val
    if val then
        recoverFromRagdoll()
    end
    Hub.Notify("Misc", val and "Anti Ragdoll: ACTIVE (Instant Standup)" or "Anti Ragdoll: OFF", 2)
end)

-- Automatic Tool Sanitizer (Ensures authentic reload and cleans fake client folders)
local function setupToolSanitizers()
    local function watchContainer(container)
        if not container then return end
        container.ChildAdded:Connect(function(child)
            if child:IsA("Tool") then
                task.wait(0.05)
                applyWeaponMods(child)
            end
        end)
        for _, child in ipairs(container:GetChildren()) do
            if child:IsA("Tool") then
                applyWeaponMods(child)
            end
        end
    end

    local bp = LocalPlayer:WaitForChild("Backpack", 5)
    if bp then watchContainer(bp) end

    LocalPlayer.CharacterAdded:Connect(function(newChar)
        watchContainer(newChar)
        local newBp = LocalPlayer:WaitForChild("Backpack", 5)
        if newBp then watchContainer(newBp) end
        newChar.ChildAdded:Connect(function(child)
            if Config.AntiRagdoll and child.Name == "RagdollTag" then
                task.defer(recoverFromRagdoll)
            end
        end)
    end)
    if LocalPlayer.Character then
        watchContainer(LocalPlayer.Character)
        LocalPlayer.Character.ChildAdded:Connect(function(child)
            if Config.AntiRagdoll and child.Name == "RagdollTag" then
                task.defer(recoverFromRagdoll)
            end
        end)
    end
end
task.spawn(setupToolSanitizers)

Hub.Notify("Medved Hub", "Medved! V5 Loaded — Turrets Suite & Clean Misc Tab 🐻⚡", 3)
