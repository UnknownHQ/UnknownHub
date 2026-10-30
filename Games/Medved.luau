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
    FarmMethod = "Gun", -- "Gun" or "Melee"
    SelectedBears = { ["All"] = true },
    SelectedBearTarget = "All",
    SafeZoneLowHP = true,
    LowHPThreshold = 25,

    -- Combat
    MeleeAura = false,
    MeleeAuraRange = 18,
    GunAura = false,
    GunAuraRange = 90,
    TargetPlayerBears = false, -- false: player bears are friendly/ignored; true: targetable in PvP

    -- Movement & Stamina
    InfiniteStamina = false,
    CustomSpeed = 14.1,

    -- Visuals
    CratesESP = false,
    BearsESP = false
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
    { name = "Old Statue (Lenin)", target = "Lenin Statue", fallback = Vector3.new(-399, -123, -707) },
    { name = "Signal Tower", target = "SignalTower", fallback = Vector3.new(-626, -114, 443) },
    { name = "Ruined Playground", target = "BrutalPlayground", fallback = Vector3.new(-1053, -112, 646) },
    { name = "Graveyard", target = "Graveyard", fallback = Vector3.new(12, -123, -878) },
    { name = "The Bunker", target = "Bunker", fallback = Vector3.new(-699, -112, -664) },
    { name = "The Tunnel", target = "Tunnel", fallback = Vector3.new(-1162, -112, -46) },
    { name = "The Bridge", target = "TheBridge", fallback = Vector3.new(848, -110, -592) },
    { name = "Power Grid", target = "Power Grid", fallback = Vector3.new(-556, -112, -270) },
    { name = "Main Cave Entrance", target = "Caves", fallback = Vector3.new(-28, -122, 397) },
    { name = "Bear Pillars", target = "Pillar Obby", fallback = Vector3.new(255, -123, 588) },
    { name = "Abandoned Town", target = "AbandonedTown", fallback = Vector3.new(-9, -135, 175) },
    { name = "Research Facility", target = "OutsideResearchFacility", fallback = Vector3.new(-17, -136, -396) },
    { name = "Star Lab", target = "Star Lab", fallback = Vector3.new(-300, -112, 850) },
    { name = "Hangar", target = "Hangar", fallback = Vector3.new(400, -112, 400) },
    { name = "Mineshaft", target = "Mineshaft", fallback = Vector3.new(-850, -120, -350) },
    { name = "Plane Crash", target = "Plane", fallback = Vector3.new(325, -143, -63) },
    { name = "The Maze", target = "ScaryMaze", fallback = Vector3.new(20, -130, -185) }
}

local function resolveLocationPosition(item)
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

    local spawnOffset = Vector3.new(0, 2.5, 0)
    local destCFrame = CFrame.new(targetPos + spawnOffset)

    -- Anchor-Flash Protocol: Prevents 50/50 physics packet rubberband when walking or sprinting
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    root.Anchored = true
    char:PivotTo(destCFrame)

    task.spawn(function()
        -- Hold anchored across 3 physics frames to force authoritative server position sync
        for _ = 1, 3 do
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
    task.wait(0.2)

    -- Dynamic GhostBear evasion check
    if isGhostBearNearPosition(root.Position, 28) then
        root.CFrame = root.CFrame + Vector3.new(0, 18, 0)
        return false
    end

    if mode == "open" then
        local openPrompt = cratePart:FindFirstChild("CratePrompt")
        local openDeadline = tick() + 1.8
        while crate:GetAttribute("Collected") ~= true and tick() < openDeadline do
            if isGhostBearNearPosition(root.Position, 28) then
                root.CFrame = root.CFrame + Vector3.new(0, 18, 0)
                return false
            end
            if openPrompt and openPrompt.Enabled then
                triggerPrompt(openPrompt)
            end
            root.CFrame = targetCFrame
            root.AssemblyLinearVelocity = Vector3.zero
            task.wait(0.18)
        end
    end

    local isOpened = (crate:GetAttribute("Collected") == true) or (mode == "loot")
    if not isOpened then
        return false
    end

    local sweepDeadline = tick() + 2.2
    local collectedAny = false
    local sweepStart = tick()

    while tick() < sweepDeadline do
        if isGhostBearNearPosition(root.Position, 28) then
            root.CFrame = root.CFrame + Vector3.new(0, 18, 0)
            return false
        end
        local activePrompts = getCrateItemPrompts(crate)
        if #activePrompts > 0 then
            for _, prompt in ipairs(activePrompts) do
                root.CFrame = targetCFrame
                root.AssemblyLinearVelocity = Vector3.zero
                triggerPrompt(prompt)
                collectedAny = true
                task.wait(0.08)
            end
        else
            if collectedAny or (tick() - sweepStart) > 0.85 then
                break
            end
        end
        task.wait(0.05)
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
local function getUncollectedPages()
    local uncollected = {}
    local pagesFolder = Workspace:FindFirstChild("Pages")
    if not pagesFolder then return uncollected end

    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")

    for _, p in ipairs(pagesFolder:GetChildren()) do
        if p:GetAttribute("Collected") ~= true then
            local prompt = p:FindFirstChildOfClass("ProximityPrompt")
            if prompt and prompt.Enabled then
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
    if not pagePart then return false end
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return false end

    local pagePos = pagePart:IsA("BasePart") and pagePart.Position or pagePart:GetPivot().Position
    local targetCFrame = CFrame.new(pagePos + Vector3.new(0, 2.0, 0))

    root.CFrame = targetCFrame
    root.AssemblyLinearVelocity = Vector3.zero
    task.wait(0.22)

    local prompt = pagePart:FindFirstChildOfClass("ProximityPrompt")
    local startWait = tick()

    while pagePart:GetAttribute("Collected") ~= true and (tick() - startWait) < 1.6 do
        if prompt and prompt.Enabled then
            triggerPrompt(prompt)
        end
        root.CFrame = targetCFrame
        root.AssemblyLinearVelocity = Vector3.zero
        task.wait(0.18)
    end

    return pagePart:GetAttribute("Collected") == true
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
                    Hub.Notify("Pages", "All pages on map collected!", 3)
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

    -- Category 0: GrinderBear & Mechanical Bosses (Crown Vault Apex Stance)
    -- Grinder is 36 studs tall, 36 studs wide, equipped with ground wheel, 31-stud claws, and forward arm cannons.
    -- Torso/ground level is a lethal contact zone. We hover directly over Hitbox_Head crown (Y ~34.5+).
    if name:find("grinder") then
        local head = bear:FindFirstChild("Hitbox_Head")
        local targetPos = head and head.Position or cf.Position
        local headH = head and (head.Size.Y * 0.5) or (sz.Y * 0.5)
        local targetY = targetPos.Y + headH + 1.8
        local distBehind = (head and (head.Size.Z * 0.5) or (sz.Z * 0.3)) + 1.8
        return targetPos, distBehind, targetY
    end

    -- Category 1: Small / Dwarf / Spherical bears (Booboo, LaserBooBoo, HypersonicBooBoo)
    -- Booboo has JumpPower: 50 which produces a 6.37-stud vertical jump arc!
    -- Solution: Elevate +8.2 studs above top bounding box, completely above peak jump reach.
    if name:find("booboo") or name:find("ball") or sz.Y < 6.5 or sz.Magnitude < 8 then
        local targetY = cf.Position.Y + (sz.Y * 0.5) + 8.2
        local distBehind = (sz.Z * 0.5) + 2.2
        return cf.Position, distBehind, targetY
    end

    -- Category 0.5: WallBear & Giant Wall Entities (Apex Stance above top edge)
    -- WallBear is 17-20 studs wide and 20 studs tall. Topples forward and spins with width 17 studs.
    -- Solution: Hover directly above upper edge (BodyTop / Ears) to stay clear of topple & ground spin.
    if name:find("wall") then
        local topPart = bear:FindFirstChild("BodyTop") or bear:FindFirstChild("Ears") or bear:FindFirstChild("Hitbox_Head")
        local targetPos = topPart and topPart.Position or cf.Position
        local targetY = cf.Position.Y + (sz.Y * 0.5) + 4.2
        local distBehind = (sz.X * 0.5) + 3.2
        return targetPos, distBehind, targetY
    end

    -- Category 2: Tall / Giant / Worm bears (TallBear, GrizzlyTallBear, WormBear)
    if name:find("tall") or name:find("worm") or sz.Y > 14 or sz.Z > 14 then
        local head = bear:FindFirstChild("Hitbox_Head") or bear:FindFirstChild("Head")
        local targetPos = head and head.Position or cf.Position
        local targetY = cf.Position.Y + (sz.Y * 0.5) + 4.0
        local distBehind = (sz.Z * 0.5) + 3.0
        return targetPos, distBehind, targetY
    end

    -- Category 3: Quadruped / standard bears (Medved, ClassicBear, Grizzly, IceBear, ThinBear, etc.)
    -- Hover above upper spine/pelvis line (+3.4 studs above top bounding box) to prevent ground bite / turn clip
    local targetY = cf.Position.Y + (sz.Y * 0.5) + 3.4
    local distBehind = (sz.Z * 0.5) + 2.4
    return cf.Position, distBehind, targetY
end

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

local function isBearTargetable(b)
    if not b or not b.Parent then return false end
    local name = b.Name:lower()

    -- 1. Never target CutieBear or GhostBear (GhostBear is invincible & deals lethal touch)
    if name:find("cutie") or name:find("ghost") then
        return false
    end

    local hum = b:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then
        return false
    end

    -- 2. Friendly Player Bears Protection
    -- When TargetPlayerBears is false, all player bears are strictly protected as friendly!
    local isPlr = Players:GetPlayerFromCharacter(b) ~= nil
    if isPlr and not Config.TargetPlayerBears then
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

    local reload = config:FindFirstChild("ReloadTime")
    if reload and reload:IsA("ValueBase") and reload.Value < 0.5 then
        reload.Value = orig.ReloadTime
    end


    if Config.MeleeAura or (Config.AutoFarmBears and Config.FarmMethod == "Melee") then
        local equipDelay = config:FindFirstChild("EquipDelay")
        if equipDelay and equipDelay:IsA("ValueBase") then equipDelay.Value = 0 end

        local windup = config:FindFirstChild("WindupTime")
        if windup and windup:IsA("ValueBase") then windup.Value = 0 end

        local cooldown = config:FindFirstChild("CooldownTime")
        if cooldown and cooldown:IsA("ValueBase") then cooldown.Value = 0.35 end

        local hitboxTime = config:FindFirstChild("HitboxTime")
        if hitboxTime and hitboxTime:IsA("ValueBase") then hitboxTime.Value = 0.8 end
    end
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

    local ammo = currentGunAmmo[tool]
    return ammo, (ammo <= 0)
end

-- Comprehensive Dual-Vector Gun Reload Trigger (Simulated Key + Server Remote + UI Trigger)
local function triggerGunReload(tool)
    if not tool or tick() < reloadEndTime or isReloading then return end
    local gunScripts = tool:FindFirstChild("GunScripts")
    local reloadRemote = gunScripts and gunScripts:FindFirstChild("Reload")

    local config = tool:FindFirstChild("Config")
    local reloadTimeVal = config and config:FindFirstChild("ReloadTime")
    local reloadDuration = (reloadTimeVal and reloadTimeVal:IsA("ValueBase") and reloadTimeVal.Value) or 2.2

    reloadEndTime = tick() + reloadDuration + 0.25
    isReloading = true
    syncAmmoToGUI(tool)

    -- 1. Native Virtual Input KeyPress simulation (invokes GunClient local reload animation & client clip reset)
    pcall(function()
        local vim = game:GetService("VirtualInputManager")
        if vim then
            vim:SendKeyEvent(true, Enum.KeyCode.R, false, game)
            task.wait(0.04)
            vim:SendKeyEvent(false, Enum.KeyCode.R, false, game)
        end
    end)

    -- 2. Direct Network Remote Dispatch as server-side authoritative backup
    if reloadRemote then
        pcall(function()
            reloadRemote:FireServer()
        end)
    end

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

    task.delay(reloadDuration + 0.25, function()
        if tick() >= reloadEndTime then
            isReloading = false
            currentGunAmmo[tool] = getToolMaxClip(tool)
            syncAmmoToGUI(tool)
        end
    end)
end

-- Server-Authoritative Shooting Dispatcher
local function shootTargetBear(tool, bear, bearPart)
    if not tool or not bear or not bearPart then return end

    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local gunScripts = tool:FindFirstChild("GunScripts")
    local fireRemote = gunScripts and gunScripts:FindFirstChild("FireBullet")
    if not fireRemote then return end

    -- Check live ammo state
    local currentAmmo, reloading = getLoadedAmmoFromGUI(tool)
    if reloading or tick() < reloadEndTime or isReloading then
        return
    end

    if currentAmmo <= 0 then
        triggerGunReload(tool)
        return
    end

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

    local hitData = {
        {
            hit = targetPart,
            hitpos = hitPos,
            normal = Vector3.new(0, 1, 0)
        }
    }

    -- Decrement authoritative clip ammo for this shot & update GUI counter in real-time
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

task.spawn(function()
    while true do
        task.wait(0.08)
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")

        if root and hum and hum.Health > 0 then
            local equippedTool = char:FindFirstChildOfClass("Tool")

            -- 1. Melee Aura Execution (Smooth 0.35s swing throttle to eliminate visual spam)
            if Config.MeleeAura then
                local bear, dist = getClosestBear(Config.MeleeAuraRange, true)
                if bear and dist then
                    local isMelee = equippedTool and equippedTool:FindFirstChild("MeleeScripts")
                    if isMelee and equippedTool then
                        applyWeaponMods(equippedTool)
                        local targetPart = getBearBottomRearPart(bear)
                        local bearRoot = bear:FindFirstChild("HumanoidRootPart") or bear:FindFirstChild("Head") or bear.PrimaryPart or bear:FindFirstChildOfClass("BasePart")
                        local aimTarget = targetPart or bearRoot
                        if aimTarget then
                            root.CFrame = CFrame.new(root.Position, Vector3.new(aimTarget.Position.X, root.Position.Y, aimTarget.Position.Z))
                            if tick() - lastMeleeSwing >= 0.35 then
                                lastMeleeSwing = tick()
                                equippedTool:Activate()
                            end
                        end
                    end
                end
            end

            -- 2. Gun Aura Execution (ONLY when gun is ALREADY equipped! Zero annoying auto-equipping!)
            if Config.GunAura then
                local isGun = equippedTool and equippedTool:FindFirstChild("GunScripts")
                if isGun and equippedTool then
                    local currentAmmo, reloading = getLoadedAmmoFromGUI(equippedTool)
                    if not reloading and currentAmmo <= 0 and tick() >= reloadEndTime then
                        triggerGunReload(equippedTool)
                    else
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

local function getBestTool(weaponType)
    local char = LocalPlayer.Character
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    local candidates = {}

    local function checkTool(tool)
        if not tool or not tool:IsA("Tool") then return end
        local isMelee = tool:FindFirstChild("MeleeScripts") ~= nil
        local isGun = tool:FindFirstChild("GunScripts") ~= nil

        if weaponType == "Melee" and isMelee then
            table.insert(candidates, tool)
        elseif weaponType == "Gun" and isGun then
            table.insert(candidates, tool)
        end
    end

    if char then
        for _, c in ipairs(char:GetChildren()) do
            checkTool(c)
        end
    end
    if backpack then
        for _, c in ipairs(backpack:GetChildren()) do
            checkTool(c)
        end
    end

    if #candidates == 0 then return nil end

    table.sort(candidates, function(a, b)
        local cfgA = a:FindFirstChild("Config")
        local cfgB = b:FindFirstChild("Config")
        local dmgA = (cfgA and cfgA:FindFirstChild("Damage") and cfgA.Damage:IsA("ValueBase") and cfgA.Damage.Value) or WEAPON_TIERS[a.Name] or 10
        local dmgB = (cfgB and cfgB:FindFirstChild("Damage") and cfgB.Damage:IsA("ValueBase") and cfgB.Damage.Value) or WEAPON_TIERS[b.Name] or 10
        return dmgA > dmgB
    end)

    return candidates[1]
end

local function ensureBestWeaponEquipped(weaponType)
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not char or not hum or hum.Health <= 0 then return nil end

    local bestTool = getBestTool(weaponType)
    if not bestTool then return nil end

    if bestTool.Parent == char then
        return bestTool
    end

    hum:EquipTool(bestTool)
    return nil
end

local bearTypeDropdown = nil

local function getAvailableBearTypes()
    local list = {"All"}
    local rs = game:GetService("ReplicatedStorage")

    -- 1. Read all 22 authoritative bear definitions from ReplicatedStorage.Data.Bears
    local dataBears = rs:FindFirstChild("Data") and rs.Data:FindFirstChild("Bears")
    if dataBears then
        for _, b in ipairs(dataBears:GetChildren()) do
            local bn = b.Name:lower()
            if not bn:find("cutie") and not bn:find("ghost") and not table.find(list, b.Name) then
                table.insert(list, b.Name)
            end
        end
    end

    -- 2. Also inspect ReplicatedStorage.Bears folder
    local rsBears = rs:FindFirstChild("Bears")
    if rsBears then
        for _, b in ipairs(rsBears:GetChildren()) do
            local bn = b.Name:lower()
            if not bn:find("cutie") and not bn:find("ghost") and not table.find(list, b.Name) then
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
            if not isPlr and not bn:find("cutie") and not bn:find("ghost") and not table.find(list, b.Name) then
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

    -- 1. Sticky Target Lock: Stay locked onto the current bear until it is completely dead!
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
    local wsBears = workspace:FindFirstChild("Bears")
    if not wsBears then return 0 end

    for _, otherBear in ipairs(wsBears:GetChildren()) do
        if otherBear ~= currentTarget and otherBear.Parent then
            local isGhost = otherBear.Name:lower():find("ghost") ~= nil
            local otherHum = otherBear:FindFirstChildOfClass("Humanoid")
            -- GhostBear has no Humanoid, but is the highest priority lethal touch threat!
            if isGhost or (otherHum and otherHum.Health > 0) then
                local otherRoot = otherBear:FindFirstChild("HumanoidRootPart") or otherBear.PrimaryPart or otherBear:FindFirstChildWhichIsA("BasePart")
                if otherRoot then
                    local xzDist = Vector2.new(otherRoot.Position.X - playerPos.X, otherRoot.Position.Z - playerPos.Z).Magnitude
                    if isGhost and xzDist < 35 then
                        -- High vault stance: hoist +18 studs over GhostBear
                        local oCf, oSz = otherBear:GetBoundingBox()
                        local ghostTopY = oCf.Position.Y + (oSz.Y * 0.5) + 18.0
                        if ghostTopY > highestThreatY then
                            highestThreatY = ghostTopY
                        end
                    elseif not isGhost and xzDist < 26 then
                        local oCf, oSz = otherBear:GetBoundingBox()
                        local realHeight = math.clamp(oSz.Y, 2, 42)
                        local otherTopY = oCf.Position.Y + (realHeight * 0.5)
                        if otherTopY > highestThreatY then
                            highestThreatY = otherTopY
                        end
                    end
                end
            end
        end
    end
    return highestThreatY
end

-- Pipeline 1: 60+ FPS Butter-Smooth Levitation Flight (RunService.Heartbeat)
-- Decoupled from combat task.wait pauses; updates every single physics frame without stutter or delay
RunService.Heartbeat:Connect(function(dt)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not char or not root or not hum or hum.Health <= 0 then return end

    -- Anti-Touch & Anti-Collision Defense: Suppress touch + disable limb physics collision across all activities
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then
            if p.CanTouch then pcall(function() p.CanTouch = false end) end
            if p ~= root and p.CanCollide then pcall(function() p.CanCollide = false end) end
        end
    end

    if not Config.AutoFarmBears or isFleeingLowHP then return end

    local bear = activeFlightBear
    if not bear or not bear.Parent then return end

    local bearHum = bear:FindFirstChildOfClass("Humanoid")
    if not bearHum or bearHum.Health <= 0 then return end

    local bearRoot = bear:FindFirstChild("HumanoidRootPart") or bear.PrimaryPart or bear:FindFirstChildWhichIsA("BasePart")
    if not bearRoot or not bearRoot.Parent then return end

    local lookVec = bearRoot.CFrame.LookVector
    local centerPos, distBehind, targetY = getBearLevitationTarget(bear)
    if not centerPos then return end

    local isBoss = bear.Name:lower():find("grinder") or bear.Name:lower():find("boss") or bear.Name:lower():find("wall")
    if Config.FarmMethod == "Melee" then
        local targetPos = centerPos - (lookVec * distBehind)
        local y = targetY
        if activeFlightEvading or (isBoss and bearRoot.AssemblyLinearVelocity.Magnitude > 18) then
            y = y + (isBoss and 7.5 or 4.8) -- High vault when bear attempts to turn or charge
        end

        -- Dynamic Threat Ceiling: elevate above any nearby giant/tall bears walking close
        local threatCeiling = getNearbyThreatCeiling(root.Position, bear)
        if threatCeiling > 0 and (threatCeiling + 2.8) > y then
            y = threatCeiling + 2.8
        end

        targetPos = Vector3.new(targetPos.X, y, targetPos.Z)
        root.CFrame = CFrame.lookAt(targetPos, centerPos)
    elseif Config.FarmMethod == "Gun" then
        local cf, bbSize = bear:GetBoundingBox()
        local distBehindGun = isBoss and 32.0 or math.max(8.5, bbSize.Z * 0.75 + 4.0)
        local heightAboveGun = isBoss and (bbSize.Y * 0.5 + 16.0) or math.max(7.5, bbSize.Y * 0.6 + 4.0)
        local hoverPos = centerPos - (lookVec * distBehindGun) + Vector3.new(0, heightAboveGun, 0)

        -- Dynamic Threat Ceiling in Gun mode
        local threatCeiling = getNearbyThreatCeiling(root.Position, bear)
        if threatCeiling > 0 and (threatCeiling + 3.0) > hoverPos.Y then
            hoverPos = Vector3.new(hoverPos.X, threatCeiling + 3.0, hoverPos.Z)
        end

        root.CFrame = CFrame.lookAt(hoverPos, centerPos)
    end

    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
end)

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

        -- 2. Equip Best Weapon for chosen FarmMethod
        local bestTool = ensureBestWeaponEquipped(Config.FarmMethod)
        if not bestTool then
            activeFlightBear = nil
            Hub.Notify("Bear Farm", "No " .. Config.FarmMethod .. " weapon found in inventory!", 2)
            task.wait(2)
            continue
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

        activeFlightBear = bear

        -- 4. Anti-Hit Predictive Check (detect bear turning)
        local lookVec = bearRoot.CFrame.LookVector
        local toPlayer = (root.Position - bearRoot.Position).Unit
        local isBearFacing = lookVec:Dot(toPlayer) > 0.25
        activeFlightEvading = isBearFacing

        -- 5. Attack Execution (Zero Stutter / Smooth Flight Preserved)
        if Config.FarmMethod == "Melee" then
            local isMelee = bestTool:FindFirstChild("MeleeScripts")
            if isMelee then
                applyWeaponMods(bestTool)
                if not isBearFacing and tick() - lastMeleeSwing >= 0.35 then
                    lastMeleeSwing = tick()
                    bestTool:Activate()

                    -- Direct authoritative network hit dispatch (Crown/Head priority)
                    local meleeRemote = isMelee:FindFirstChild("MeleeRemote")
                    local targetHitPart = bear:FindFirstChild("BodyTop") or bear:FindFirstChild("Ears") or bear:FindFirstChild("Hitbox_Head") or bear:FindFirstChild("Hitbox_Chest") or bear:FindFirstChild("Hitbox_Torso") or bearRoot
                    if meleeRemote and targetHitPart then
                        pcall(function()
                            meleeRemote:FireServer("Hit", targetHitPart)
                        end)
                    end
                end
            end
        elseif Config.FarmMethod == "Gun" then
            local isGun = bestTool:FindFirstChild("GunScripts")
            if isGun then
                applyWeaponMods(bestTool)
                local currentAmmo, reloading = getLoadedAmmoFromGUI()
                if not reloading and currentAmmo <= 0 and tick() >= reloadEndTime then
                    triggerGunReload(bestTool)
                end
                local targetPart = bear:FindFirstChild("BodyTop") or bear:FindFirstChild("Ears") or bear:FindFirstChild("Hitbox_Head") or bear:FindFirstChild("Hitbox_Chest") or bear:FindFirstChild("Hitbox_Torso") or bearRoot
                shootTargetBear(bestTool, bear, targetPart)
            end
        end
    end
end)

-- Native Undetectable Speed Modifier Engine (Using Game's SpeedModifiers Framework)
local SpeedModifiersModule = ReplicatedStorage:FindFirstChild("SpeedModifiers")
local SpeedModifiers = SpeedModifiersModule and require(SpeedModifiersModule)

local function ensureSpeedModifier(char)
    if not char then return end
    local targetMod = (Config.CustomSpeed and Config.CustomSpeed > 14.1) and ((Config.CustomSpeed / 14.1) - 1) or 0
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
        if math.abs(speedMod.Value - targetMod) > 0.005 then
            speedMod.Value = targetMod
        end
    end
end

LocalPlayer.CharacterAdded:Connect(function(newChar)
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

Hub.CreateSection(farmTab, "🛡️ Telemetry Shield: Active & Silent")
Hub.CreateSection(farmTab, "📦 Crates Automation")

Hub.CreateToggle(farmTab, "Auto Farm Crates (Teleport & Loot)", Config.AutoFarmCrates, function(val)
    Config.AutoFarmCrates = val
    if val then
        silenceTelemetry()
        table.clear(crateAttempts)
        table.clear(blacklistedCrates)
        table.clear(openedCrates)
    end
    Hub.Notify("Auto Farm", val and "Crate Farm: ACTIVE" or "Crate Farm: OFF", 2)
end)

Hub.CreateSlider(farmTab, "Teleport Delay (Seconds)", 0.2, 1.5, Config.FarmDelay, "s", function(val)
    Config.FarmDelay = val
end)

Hub.CreateToggle(farmTab, "Auto Serverhop When Crates Cleared", Config.AutoServerhop, function(val)
    Config.AutoServerhop = val
end)

Hub.CreateSection(farmTab, "📜 Pages Automation")

Hub.CreateToggle(farmTab, "Auto Collect All Pages", Config.AutoCollectPages, function(val)
    Config.AutoCollectPages = val
    if val then
        silenceTelemetry()
    end
    Hub.Notify("Pages", val and "Page Collector: ACTIVE" or "Page Collector: OFF", 2)
end)

Hub.CreateButton(farmTab, "Collect All Pages (One-Time Sweep)", function()
    task.spawn(function()
        silenceTelemetry()
        Hub.Notify("Pages", "Collecting all pages on map...", 2)
        local pages = getUncollectedPages()
        for _, p in ipairs(pages) do
            collectSinglePage(p)
            task.wait(Config.FarmDelay)
        end
        Hub.Notify("Pages", "One-time page sweep complete!", 3)
    end)
end)

-- Auto Farm Bears UI Controls & Dynamic Low HP Bounds
local initialChar = LocalPlayer.Character
local initialHum = initialChar and initialChar:FindFirstChildOfClass("Humanoid")
local initialMaxHp = (initialHum and initialHum.MaxHealth and initialHum.MaxHealth > 0) and initialHum.MaxHealth or 250
local minHpVal = math.max(1, math.floor(initialMaxHp * 0.10))
local maxHpVal = math.max(2, math.floor(initialMaxHp * 0.50))
local defaultHpVal = math.clamp(math.floor(initialMaxHp * 0.25), minHpVal, maxHpVal)
Config.LowHPThreshold = defaultHpVal

Hub.CreateSection(farmTab, "🐻 Auto Farm Bears Suite")

Hub.CreateToggle(farmTab, "Auto Farm Bears (Levitate Behind)", Config.AutoFarmBears, function(val)
    Config.AutoFarmBears = val
    if val then
        silenceTelemetry()
    end
    Hub.Notify("Bear Farm", val and "Auto Farm Bears: ACTIVE" or "Auto Farm Bears: OFF", 2)
end)

Hub.CreateDropdown(farmTab, "Attack Method", {"Gun", "Melee"}, Config.FarmMethod, function(val)
    Config.FarmMethod = val
    Hub.Notify("Bear Farm", "Method set to: " .. val, 2)
end)

bearTypeDropdown = Hub.CreateMultiDropdown(farmTab, "Target Bears (Multi-Select)", getAvailableBearTypes(), {"All"}, function(dict, arr)
    Config.SelectedBears = dict
    Config.SelectedBearTarget = dict["All"] and "All" or (arr[1] or "None")
    local desc = dict["All"] and "All Bears" or (#arr .. " Selected")
    Hub.Notify("Bear Farm", "Targeting: " .. desc, 2)
end)

Hub.CreateToggle(farmTab, "Safe Zone Retreat on Low HP", Config.SafeZoneLowHP, function(val)
    Config.SafeZoneLowHP = val
    Hub.Notify("Bear Farm", val and "Safe Zone Retreat: ON" or "Safe Zone Retreat: OFF", 2)
end)

Hub.CreateSlider(farmTab, "Low HP Retreat Threshold", minHpVal, maxHpVal, Config.LowHPThreshold, " HP", function(val)
    Config.LowHPThreshold = val
end)

-- TAB: COMBAT
local combatTab = Hub.CreateTab("Combat", {
    Icon = "⚔️",
    Size = 18,
    Color = Color3.fromRGB(255, 75, 75),
    ActiveColor = Color3.fromRGB(255, 110, 110)
})

Hub.CreateSection(combatTab, "🗡️ Melee Automation")

Hub.CreateToggle(combatTab, "Melee Hit Aura (Bat / Axe / Melee)", Config.MeleeAura, function(val)
    Config.MeleeAura = val
    Hub.Notify("Combat", val and "Melee Aura: ACTIVE" or "Melee Aura: OFF", 2)
end)

Hub.CreateSlider(combatTab, "Melee Aura Range (Studs)", 8, 30, Config.MeleeAuraRange, " studs", function(val)
    Config.MeleeAuraRange = val
end)

Hub.CreateToggle(combatTab, "Target Player Bears (PvP)", Config.TargetPlayerBears, function(val)
    Config.TargetPlayerBears = val
    Hub.Notify("Combat", val and "Player Bears: TARGETABLE (PvP Active)" or "Player Bears: FRIENDLY (Protected)", 2)
end)

Hub.CreateSection(combatTab, "🔫 Firearm Automation")

Hub.CreateToggle(combatTab, "Gun Hit Aura (Auto Shoot & Auto Reload)", Config.GunAura, function(val)
    Config.GunAura = val
    Hub.Notify("Combat", val and "Gun Aura: ACTIVE" or "Gun Aura: OFF", 2)
end)

Hub.CreateSlider(combatTab, "Gun Aura Range (Studs)", 20, 150, Config.GunAuraRange, " studs", function(val)
    Config.GunAuraRange = val
end)

Hub.CreateSection(combatTab, "⚡ Movement & Undetectable Stamina")

Hub.CreateToggle(combatTab, "Infinite Stamina (Never Deplete)", Config.InfiniteStamina, function(val)
    Config.InfiniteStamina = val
    Hub.Notify("Movement", val and "Infinite Stamina: ACTIVE" or "Infinite Stamina: OFF", 2)
end)

Hub.CreateSlider(combatTab, "WalkSpeed Modifier", 14.1, 45, Config.CustomSpeed, " spd", function(val)
    Config.CustomSpeed = val
    ensureSpeedModifier(LocalPlayer.Character)
end)

-- TAB: VISUALS
local visualTab = Hub.CreateTab("Visuals", {
    Icon = "👁️",
    Size = 18,
    Color = Color3.fromRGB(165, 95, 255),
    ActiveColor = Color3.fromRGB(190, 130, 255)
})

Hub.CreateSection(visualTab, "ESP Monitors")

Hub.CreateToggle(visualTab, "Unopened Crates ESP", Config.CratesESP, function(val)
    Config.CratesESP = val
    if val then
        updateCratesESP()
    else
        clearCrateESP()
    end
end)

Hub.CreateToggle(visualTab, "Bears ESP (NPCs & Players)", Config.BearsESP, function(val)
    Config.BearsESP = val
    if val then
        updateBearESP()
    else
        clearBearESP()
    end
end)

-- TAB: TELEPORTS
local tpTab = Hub.CreateTab("Teleports", {
    Icon = "📍",
    Size = 18,
    Color = Color3.fromRGB(255, 170, 0),
    ActiveColor = Color3.fromRGB(255, 205, 50)
})

Hub.CreateSection(tpTab, "🗺️ Verified Geographic Locations")

for _, locItem in ipairs(locationRegistry) do
    Hub.CreateButton(tpTab, "Teleport to: " .. locItem.name, function()
        local pos = resolveLocationPosition(locItem)
        safeTeleport(pos, locItem.name)
    end)
end



Hub.Notify("Medved Hub", "Medved! V4 Loaded — Combat Suite & Dynamic Teleports 🐻", 3)
