local LIBRARY_LINK = "https://raw.githubusercontent.com/UnknownHQ/UnknownHub/main/UnknownLibrary"
local LIBRARY_NAME = "Unknown_TabbedHub_UI"

local currentSession = tick()
_G.SBD_SESSION = currentSession

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

-- =========================================================================
-- Built-in Anti-AFK Safeguard
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
    local parents = {game:GetService("CoreGui")}
    if gethui then pcall(function() table.insert(parents, gethui()) end) end
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if playerGui then table.insert(parents, playerGui) end
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

local ok, result = pcall(function()
    local source
    local cacheBuster = "?t=" .. tostring(os.time() or tick()) .. "_" .. tostring(math.random(1000, 9999))
    source = game:HttpGet(LIBRARY_LINK .. cacheBuster)
    local factoryChunk, compileErr = loadstring(source)
    assert(factoryChunk, "the linked source did not compile: " .. tostring(compileErr))
    return factoryChunk()
end)

assert(ok and type(result) == "function", "UnknownLibrary failed to load: " .. tostring(result))

destroyOldGui()

local Hub = result({
    name = LIBRARY_NAME,
    title = "UNKNOWN HUB",
    subTitle = "Siege Box Defense",
    parent = (gethui and gethui()) or (LocalPlayer and (LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui"))) or (pcall(function() return game:GetService("CoreGui") end) and game:GetService("CoreGui")),
    theme = Color3.fromRGB(231, 76, 60),
    secondaryTheme = Color3.fromRGB(192, 57, 43)
})

assert(type(Hub) == "table", "UnknownLibrary returned an invalid hub")

-- =========================================================================
-- Script State Engine
-- =========================================================================
local State = {
    -- Combat
    GunAura = false,
    GunAura_TargetMode = "Nearest", -- "Nearest", "Lowest HP", "Highest HP", "All"
    GunAura_MaxDistance = 5000,
    GunAura_Rate = 0.05,
    AutoEquipGun = true,

    KillAura = false,
    KillAura_MaxDistance = 50,
    KillAura_Rate = 0.05,
    AutoEquipPunch = true,

    AutoAbility = false,

    -- Auto Collect & Misc
    AutoCollectAirdrops = false,
    AutoCollectDistance = 5000,

    -- Visuals & ESP
    EnemyESP = false,
    BoxESP = false,
    AirdropESP = false,

    -- Player Movement
    WalkSpeed = 16,
    JumpPower = 50,
    InfiniteJump = false,
    Noclip = false
}

-- =========================================================================
-- Target Resolvers & Remote Finders
-- =========================================================================
local function getCharacter()
    return LocalPlayer and LocalPlayer.Character
end

local function getHumanoid()
    local char = getCharacter()
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function getRootPart()
    local char = getCharacter()
    return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head") or char.PrimaryPart)
end

local function getTool(toolName)
    local char = getCharacter()
    if char and char:FindFirstChild(toolName) then
        return char[toolName]
    end
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp and bp:FindFirstChild(toolName) then
        return bp[toolName]
    end
    return nil
end

local function equipTool(toolName)
    local tool = getTool(toolName)
    local hum = getHumanoid()
    local char = getCharacter()
    if tool and hum and char and tool.Parent ~= char then
        pcall(function()
            hum:EquipTool(tool)
        end)
    end
    return tool
end

local function findGunFireRemote()
    local gun = getTool("DebugGun")
    if gun and gun:FindFirstChild("Fire") then
        return gun.Fire
    end
    if getnilinstances then
        for _, inst in ipairs(getnilinstances()) do
            if inst.Name == "Fire" and inst:IsA("RemoteFunction") then
                return inst
            end
        end
    end
    return nil
end

local function findPunchRemote()
    local punch = getTool("NormalPunch")
    if punch and punch:FindFirstChild("Remote") then
        return punch.Remote
    end
    if getnilinstances then
        for _, inst in ipairs(getnilinstances()) do
            if inst.Name == "Remote" and inst:IsA("RemoteEvent") then
                return inst
            end
        end
    end
    return nil
end

local function getAllAliveEnemies()
    local enemies = {}
    local myRoot = getRootPart()
    local myPos = myRoot and myRoot.Position or Vector3.new(0, 0, 0)

    local folders = {
        Workspace:FindFirstChild("Enemies"),
        Workspace:FindFirstChild("Elites"),
        Workspace:FindFirstChild("Zombies"),
        Workspace:FindFirstChild("Mobs"),
        Workspace:FindFirstChild("NPCs")
    }

    for _, folder in ipairs(folders) do
        if folder then
            for _, model in ipairs(folder:GetChildren()) do
                if model:IsA("Model") then
                    local hum = model:FindFirstChildOfClass("Humanoid")
                    local root = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Head") or model.PrimaryPart
                    if hum and hum.Health > 0 and root then
                        local dist = (root.Position - myPos).Magnitude
                        table.insert(enemies, {
                            Model = model,
                            Humanoid = hum,
                            Root = root,
                            Position = root.Position,
                            Distance = dist,
                            Health = hum.Health,
                            MaxHealth = hum.MaxHealth,
                            Name = model.Name
                        })
                    end
                end
            end
        end
    end

    return enemies
end

-- =========================================================================
-- Combat Execution Engines
-- =========================================================================
local function executeGunAura()
    if not State.GunAura then return end

    if State.AutoEquipGun then
        equipTool("DebugGun")
    end

    local fireRemote = findGunFireRemote()
    if not fireRemote then return end

    local enemies = getAllAliveEnemies()
    if #enemies == 0 then return end

    if State.GunAura_TargetMode == "Lowest HP" then
        table.sort(enemies, function(a, b) return a.Health < b.Health end)
    elseif State.GunAura_TargetMode == "Highest HP" then
        table.sort(enemies, function(a, b) return a.Health > b.Health end)
    else
        table.sort(enemies, function(a, b) return a.Distance < b.Distance end)
    end

    if State.GunAura_TargetMode == "All" then
        for _, enemy in ipairs(enemies) do
            if enemy.Distance <= State.GunAura_MaxDistance then
                pcall(function()
                    fireRemote:InvokeServer(enemy.Position)
                end)
            end
        end
    else
        local target = enemies[1]
        if target and target.Distance <= State.GunAura_MaxDistance then
            pcall(function()
                fireRemote:InvokeServer(target.Position)
            end)
        end
    end
end

local function executeKillAura()
    if not State.KillAura then return end

    if State.AutoEquipPunch then
        equipTool("NormalPunch")
    end

    local punchRemote = findPunchRemote()
    if not punchRemote then return end

    local enemies = getAllAliveEnemies()
    local inRangeCount = 0
    for _, enemy in ipairs(enemies) do
        if enemy.Distance <= State.KillAura_MaxDistance then
            inRangeCount = inRangeCount + 1
        end
    end

    if inRangeCount > 0 then
        pcall(function()
            punchRemote:FireServer("LeftDown")
            task.wait(0.02)
            punchRemote:FireServer("LeftUp")
        end)
    end
end

local function executeAutoAbility()
    if not State.AutoAbility then return end
    local gun = getTool("DebugGun")
    local abil = gun and gun:FindFirstChild("Abil")
    if abil then
        pcall(function()
            abil:FireServer(Enum.KeyCode.V)
        end)
    end
end

-- =========================================================================
-- ESP Engine
-- =========================================================================
local espContainers = {}

local function clearESP()
    for _, folder in pairs(espContainers) do
        if folder and folder.Parent then
            pcall(function() folder:Destroy() end)
        end
    end
    table.clear(espContainers)
end

local function updateESP()
    if not State.EnemyESP and not State.AirdropESP then
        clearESP()
        return
    end

    if State.EnemyESP then
        local enemies = getAllAliveEnemies()
        for _, enemy in ipairs(enemies) do
            local root = enemy.Root
            if root and not root:FindFirstChild("Unknown_EnemyESP") then
                pcall(function()
                    local bb = Instance.new("BillboardGui")
                    bb.Name = "Unknown_EnemyESP"
                    bb.Adornee = root
                    bb.Size = UDim2.new(0, 150, 0, 40)
                    bb.StudsOffset = Vector3.new(0, 3, 0)
                    bb.AlwaysOnTop = true

                    local nameLbl = Instance.new("TextLabel")
                    nameLbl.Size = UDim2.new(1, 0, 0.5, 0)
                    nameLbl.BackgroundTransparency = 1
                    nameLbl.Text = string.format("%s [%d studs]", enemy.Name, math.floor(enemy.Distance))
                    nameLbl.TextColor3 = Color3.fromRGB(231, 76, 60)
                    nameLbl.TextStrokeTransparency = 0
                    nameLbl.TextSize = 13
                    nameLbl.Font = Enum.Font.GothamBold
                    nameLbl.Parent = bb

                    local hpLbl = Instance.new("TextLabel")
                    hpLbl.Position = UDim2.new(0, 0, 0.5, 0)
                    hpLbl.Size = UDim2.new(1, 0, 0.5, 0)
                    hpLbl.BackgroundTransparency = 1
                    hpLbl.Text = string.format("HP: %d / %d", math.floor(enemy.Health), math.floor(enemy.MaxHealth))
                    hpLbl.TextColor3 = Color3.fromRGB(46, 204, 113)
                    hpLbl.TextStrokeTransparency = 0
                    hpLbl.TextSize = 12
                    hpLbl.Font = Enum.Font.GothamMedium
                    hpLbl.Parent = bb

                    bb.Parent = root
                    espContainers[root] = bb
                end)
            elseif root and root:FindFirstChild("Unknown_EnemyESP") then
                local bb = root.Unknown_EnemyESP
                local nameLbl = bb:FindFirstChildOfClass("TextLabel")
                if nameLbl then
                    nameLbl.Text = string.format("%s [%d studs]", enemy.Name, math.floor(enemy.Distance))
                end
                local hpLbl = bb:FindFirstChild("TextLabel", true)
                if hpLbl and hpLbl ~= nameLbl then
                    hpLbl.Text = string.format("HP: %d / %d", math.floor(enemy.Health), math.floor(enemy.MaxHealth))
                end
            end
        end
    end

    if State.AirdropESP then
        local adFolder = Workspace:FindFirstChild("Airdrops")
        if adFolder then
            for _, ad in ipairs(adFolder:GetChildren()) do
                local root = ad:IsA("Model") and (ad.PrimaryPart or ad:FindFirstChildWhichIsA("BasePart")) or ad
                if root and root:IsA("BasePart") and not root:FindFirstChild("Unknown_AirdropESP") then
                    pcall(function()
                        local bb = Instance.new("BillboardGui")
                        bb.Name = "Unknown_AirdropESP"
                        bb.Adornee = root
                        bb.Size = UDim2.new(0, 120, 0, 30)
                        bb.StudsOffset = Vector3.new(0, 2, 0)
                        bb.AlwaysOnTop = true

                        local lbl = Instance.new("TextLabel")
                        lbl.Size = UDim2.new(1, 0, 1, 0)
                        lbl.BackgroundTransparency = 1
                        lbl.Text = "🎁 AIRDROP"
                        lbl.TextColor3 = Color3.fromRGB(241, 196, 15)
                        lbl.TextStrokeTransparency = 0
                        lbl.TextSize = 14
                        lbl.Font = Enum.Font.GothamBold
                        lbl.Parent = bb

                        bb.Parent = root
                        espContainers[root] = bb
                    end)
                end
            end
        end
    end
end

-- =========================================================================
-- UI Pages & Controls
-- =========================================================================
local combatTab = Hub.createTabButton("Combat", "⚔️ Combat", "rbxassetid://10723407389", true)
local visualTab = Hub.createTabButton("Visuals", "👁️ Visuals", "rbxassetid://10723407389", false)
local playerTab = Hub.createTabButton("Player", "🏃 Player", "rbxassetid://10723407389", false)
local miscTab = Hub.createTabButton("Misc", "🔮 Misc", "rbxassetid://10723407389", false)

-- -------------------------------------------------------------------------
-- Combat Tab
-- -------------------------------------------------------------------------
Hub.CreateSection(combatTab, "🔫 Gun Aura (Remote Gunner)")

Hub.CreateToggle(combatTab, "Enable Gun Aura", false, function(v)
    State.GunAura = (type(v) == "boolean") and v or not State.GunAura
end)

Hub.CreateToggle(combatTab, "Auto Equip Gun", true, function(v)
    State.AutoEquipGun = (type(v) == "boolean") and v or not State.AutoEquipGun
end)

Hub.CreateList(combatTab, "Gun Target Mode", {
    {Name = "Nearest"},
    {Name = "Lowest HP"},
    {Name = "Highest HP"},
    {Name = "All"}
}, 140, false, function(selected)
    local name = type(selected) == "table" and (selected.Name or selected[1]) or tostring(selected)
    State.GunAura_TargetMode = name
end)

Hub.CreateTextBox(combatTab, "Gun Max Range (Studs)", "Enter max range (default: 5000)", function(text)
    local num = tonumber(text)
    if num then State.GunAura_MaxDistance = math.clamp(num, 10, 50000) end
end)

Hub.CreateTextBox(combatTab, "Gun Fire Rate (0.01 - 1.0s)", "Enter interval (default: 0.05)", function(text)
    local num = tonumber(text)
    if num then State.GunAura_Rate = math.clamp(num, 0.01, 2.0) end
end)

Hub.CreateSection(combatTab, "🥊 Kill Aura (Melee Punch)")

Hub.CreateToggle(combatTab, "Enable Kill Aura (Punch)", false, function(v)
    State.KillAura = (type(v) == "boolean") and v or not State.KillAura
end)

Hub.CreateToggle(combatTab, "Auto Equip Punch", true, function(v)
    State.AutoEquipPunch = (type(v) == "boolean") and v or not State.AutoEquipPunch
end)

Hub.CreateTextBox(combatTab, "Punch Max Range (Studs)", "Enter max range (default: 50)", function(text)
    local num = tonumber(text)
    if num then State.KillAura_MaxDistance = math.clamp(num, 5, 200) end
end)

Hub.CreateSection(combatTab, "⚡ Weapon Abilities")

Hub.CreateToggle(combatTab, "Auto Fire Gun Ability (V)", false, function(v)
    State.AutoAbility = (type(v) == "boolean") and v or not State.AutoAbility
end)

-- -------------------------------------------------------------------------
-- Visuals Tab
-- -------------------------------------------------------------------------
Hub.CreateSection(visualTab, "👁️ ESP Overlays")

Hub.CreateToggle(visualTab, "Enemy ESP (Name, HP, Distance)", false, function(v)
    State.EnemyESP = (type(v) == "boolean") and v or not State.EnemyESP
    if not State.EnemyESP then clearESP() end
end)

Hub.CreateToggle(visualTab, "Airdrop ESP", false, function(v)
    State.AirdropESP = (type(v) == "boolean") and v or not State.AirdropESP
    if not State.AirdropESP then clearESP() end
end)

-- -------------------------------------------------------------------------
-- Player Tab
-- -------------------------------------------------------------------------
Hub.CreateSection(playerTab, "🏃 Local Player Modifiers")

Hub.CreateSlider(playerTab, "WalkSpeed", 16, 200, 16, " studs/s", function(val)
    State.WalkSpeed = val
    local hum = getHumanoid()
    if hum then hum.WalkSpeed = val end
end)

Hub.CreateSlider(playerTab, "JumpPower", 50, 300, 50, " power", function(val)
    State.JumpPower = val
    local hum = getHumanoid()
    if hum then hum.JumpPower = val end
end)

Hub.CreateToggle(playerTab, "Infinite Jump", false, function(v)
    State.InfiniteJump = (type(v) == "boolean") and v or not State.InfiniteJump
end)

game:GetService("UserInputService").JumpRequest:Connect(function()
    if State.InfiniteJump then
        local hum = getHumanoid()
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

Hub.CreateToggle(playerTab, "Noclip", false, function(v)
    State.Noclip = (type(v) == "boolean") and v or not State.Noclip
end)

RunService.Stepped:Connect(function()
    if State.Noclip then
        local char = getCharacter()
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end
end)

-- -------------------------------------------------------------------------
-- Misc Tab
-- -------------------------------------------------------------------------
Hub.CreateSection(miscTab, "🔮 Game Teleports & Info")

Hub.CreateButton(miscTab, "Teleport to Spawn Area", function()
    local root = getRootPart()
    local spawnPart = Workspace:FindFirstChild("Spawn") or Workspace:FindFirstChild("areaspawn")
    if root and spawnPart then
        root.CFrame = spawnPart.CFrame + Vector3.new(0, 4, 0)
    end
end)

Hub.CreateButton(miscTab, "Teleport to Safe Sky (AFK)", function()
    local root = getRootPart()
    if root then
        root.CFrame = root.CFrame + Vector3.new(0, 150, 0)
    end
end)

-- =========================================================================
-- Background Execution Loops
-- =========================================================================

-- 1. Gun Aura Loop
task.spawn(function()
    while true do
        if _G.SBD_SESSION ~= currentSession then break end
        if State.GunAura then
            executeGunAura()
            local rate = math.clamp(tonumber(State.GunAura_Rate) or 0.05, 0.01, 2.0)
            task.wait(rate)
        else
            task.wait(0.2)
        end
    end
end)

-- 2. Kill Aura Loop
task.spawn(function()
    while true do
        if _G.SBD_SESSION ~= currentSession then break end
        if State.KillAura then
            executeKillAura()
            local rate = math.clamp(tonumber(State.KillAura_Rate) or 0.05, 0.01, 2.0)
            task.wait(rate)
        else
            task.wait(0.2)
        end
    end
end)

-- 3. Auto Ability Loop
task.spawn(function()
    while true do
        if _G.SBD_SESSION ~= currentSession then break end
        if State.AutoAbility then
            executeAutoAbility()
            task.wait(1.5)
        else
            task.wait(0.5)
        end
    end
end)

-- 4. ESP Loop
task.spawn(function()
    while true do
        if _G.SBD_SESSION ~= currentSession then break end
        if State.EnemyESP or State.AirdropESP then
            updateESP()
            task.wait(0.5)
        else
            task.wait(1.0)
        end
    end
end)

-- 5. Humanoid Persistence Loop
task.spawn(function()
    while true do
        if _G.SBD_SESSION ~= currentSession then break end
        local hum = getHumanoid()
        if hum then
            if State.WalkSpeed ~= 16 and hum.WalkSpeed ~= State.WalkSpeed then
                hum.WalkSpeed = State.WalkSpeed
            end
            if State.JumpPower ~= 50 and hum.JumpPower ~= State.JumpPower then
                hum.JumpPower = State.JumpPower
            end
        end
        task.wait(0.5)
    end
end)

print("[Unknown Hub] Siege Box Defense Loaded Successfully!")
Hub.Notify({
    Title = "Siege Box Defense",
    Content = "Unknown Hub loaded! Kill Aura & Gun Aura ready.",
    Duration = 4
})
