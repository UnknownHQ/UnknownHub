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
    DamageMultiplier = 1,

    -- Defense & Allies
    AutoSummon = false,
    SelectedAlly = "Telescope",
    AutoSummonRate = 2.0,

    -- Sandbox & Godmode
    GodMode = false,
    CustomHealth = 1000,
    CustomResistance = 0,
    CustomSize = 1,
    AutoRegenPad = false,

    -- Auto Collect & Misc
    AutoCollectAirdrops = false,

    -- Visuals & ESP
    EnemyESP = false,
    AllyESP = false,
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

local function getSandboxRemote(prefix)
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    local sandboxUI = playerGui and playerGui:FindFirstChild("SandboxUI")
    if sandboxUI then
        local targetName = prefix .. tostring(LocalPlayer.UserId)
        local remote = sandboxUI:FindFirstChild(targetName)
        if remote then return remote end
    end
    return nil
end

local function getSandboxButton(btnName)
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    local sandboxUI = playerGui and playerGui:FindFirstChild("SandboxUI")
    if sandboxUI and sandboxUI:FindFirstChild("Frame") then
        return sandboxUI.Frame:FindFirstChild(btnName, true)
    end
    return nil
end

local function triggerButton(btn)
    if not btn then return false end
    pcall(function()
        if firesignal then
            if btn:IsA("GuiButton") and btn.Activated then
                firesignal(btn.Activated)
            end
            if btn:IsA("GuiButton") and btn.MouseButton1Click then
                firesignal(btn.MouseButton1Click)
            end
        end
    end)
    return true
end

local function summonAlly(allyName)
    local summonRemote = ReplicatedStorage:FindFirstChild("HEUGHSUMMONS")
    if summonRemote and summonRemote:IsA("RemoteEvent") then
        pcall(function()
            summonRemote:FireServer(tostring(allyName))
        end)
        return true
    end
    return false
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

local function getAllAllies()
    local allies = {}
    local myRoot = getRootPart()
    local myPos = myRoot and myRoot.Position or Vector3.new(0, 0, 0)

    local folders = {
        Workspace:FindFirstChild("Allies"),
        Workspace:FindFirstChild("Summons"),
        Workspace:FindFirstChild("Friendly")
    }

    for _, folder in ipairs(folders) do
        if folder then
            for _, model in ipairs(folder:GetChildren()) do
                if model:IsA("Model") then
                    local hum = model:FindFirstChildOfClass("Humanoid")
                    local root = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Head") or model.PrimaryPart
                    if root then
                        local dist = (root.Position - myPos).Magnitude
                        table.insert(allies, {
                            Model = model,
                            Humanoid = hum,
                            Root = root,
                            Position = root.Position,
                            Distance = dist,
                            Health = hum and hum.Health or 100,
                            MaxHealth = hum and hum.MaxHealth or 100,
                            Name = model.Name
                        })
                    end
                end
            end
        end
    end

    return allies
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
    if not State.EnemyESP and not State.AllyESP and not State.AirdropESP then
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

    if State.AllyESP then
        local allies = getAllAllies()
        for _, ally in ipairs(allies) do
            local root = ally.Root
            if root and not root:FindFirstChild("Unknown_AllyESP") then
                pcall(function()
                    local bb = Instance.new("BillboardGui")
                    bb.Name = "Unknown_AllyESP"
                    bb.Adornee = root
                    bb.Size = UDim2.new(0, 140, 0, 30)
                    bb.StudsOffset = Vector3.new(0, 3, 0)
                    bb.AlwaysOnTop = true

                    local lbl = Instance.new("TextLabel")
                    lbl.Size = UDim2.new(1, 0, 1, 0)
                    lbl.BackgroundTransparency = 1
                    lbl.Text = string.format("[ALLY] %s", ally.Name)
                    lbl.TextColor3 = Color3.fromRGB(52, 152, 219)
                    lbl.TextStrokeTransparency = 0
                    lbl.TextSize = 13
                    lbl.Font = Enum.Font.GothamBold
                    lbl.Parent = bb

                    bb.Parent = root
                    espContainers[root] = bb
                end)
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
                        lbl.Text = "AIRDROP"
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
local combatTab = Hub.createTabButton("Combat", "Combat", "rbxassetid://10723407389", true)
local defenseTab = Hub.createTabButton("Defense", "Defense", "rbxassetid://10723407389", false)
local sandboxTab = Hub.createTabButton("Sandbox", "Sandbox", "rbxassetid://10723407389", false)
local visualTab = Hub.createTabButton("Visuals", "Visuals", "rbxassetid://10723407389", false)
local playerTab = Hub.createTabButton("Player", "Player", "rbxassetid://10723407389", false)
local miscTab = Hub.createTabButton("Misc", "Misc", "rbxassetid://10723407389", false)

-- -------------------------------------------------------------------------
-- Combat Tab
-- -------------------------------------------------------------------------
Hub.CreateSection(combatTab, "Gun Aura (Remote Gunner)")

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

Hub.CreateSection(combatTab, "Kill Aura (Melee Punch)")

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

Hub.CreateSection(combatTab, "Damage & Weapon Abilities")

Hub.CreateToggle(combatTab, "Auto Fire Gun Ability (V)", false, function(v)
    State.AutoAbility = (type(v) == "boolean") and v or not State.AutoAbility
end)

Hub.CreateSlider(combatTab, "Attack Damage Multiplier", 1, 100, 1, "x", function(val)
    State.DamageMultiplier = val
    local damnRemote = getSandboxRemote("damn")
    if damnRemote then
        pcall(function()
            damnRemote:FireServer(val)
        end)
    end
end)

Hub.CreateButton(combatTab, "Clear All Enemies (Sandbox)", function()
    local clearBtn = getSandboxButton("clear")
    if clearBtn then
        triggerButton(clearBtn)
        Hub.Notify({Title = "Combat", Content = "Enemies cleared!", Duration = 3})
    else
        Hub.Notify({Title = "Combat", Content = "Sandbox clear button not found.", Duration = 3})
    end
end)

-- -------------------------------------------------------------------------
-- Defense Tab (Allies & Summons)
-- -------------------------------------------------------------------------
Hub.CreateSection(defenseTab, "Ally Defense Units")

Hub.CreateList(defenseTab, "Select Ally to Summon", {
    {Name = "Telescope"},
    {Name = "LargeTelescope"},
    {Name = "Boombox"},
    {Name = "LargeBoombox"},
    {Name = "Teslaman"},
    {Name = "Plane"},
    {Name = "Heli"},
    {Name = "ASUNIT"},
    {Name = "ETB"}
}, 180, false, function(selected)
    local name = type(selected) == "table" and (selected.Name or selected[1]) or tostring(selected)
    State.SelectedAlly = name
end)

Hub.CreateButton(defenseTab, "Summon Selected Ally Now", function()
    local success = summonAlly(State.SelectedAlly)
    if success then
        Hub.Notify({Title = "Summon", Content = "Summoned " .. State.SelectedAlly, Duration = 2})
    end
end)

Hub.CreateToggle(defenseTab, "Auto Summon Loop", false, function(v)
    State.AutoSummon = (type(v) == "boolean") and v or not State.AutoSummon
end)

Hub.CreateSlider(defenseTab, "Auto Summon Interval", 1, 10, 2, "s", function(val)
    State.AutoSummonRate = val
end)

Hub.CreateButton(defenseTab, "Clear All Summons", function()
    local clear2Btn = getSandboxButton("clear2")
    if clear2Btn then
        triggerButton(clear2Btn)
        Hub.Notify({Title = "Defense", Content = "Summons cleared!", Duration = 3})
    end
end)

-- -------------------------------------------------------------------------
-- Sandbox Tab (God Mode & Utilities)
-- -------------------------------------------------------------------------
Hub.CreateSection(sandboxTab, "God Mode & Player Stats")

Hub.CreateToggle(sandboxTab, "God Mode (Max Health & Resistance)", false, function(v)
    State.GodMode = (type(v) == "boolean") and v or not State.GodMode
    local hiRemote = getSandboxRemote("hi")
    local iriRemote = getSandboxRemote("iri")
    if State.GodMode then
        if hiRemote then pcall(function() hiRemote:FireServer(9999999) end) end
        if iriRemote then pcall(function() iriRemote:FireServer(999999) end) end
        local godBtn = getSandboxButton("god")
        if godBtn then triggerButton(godBtn) end
        Hub.Notify({Title = "God Mode", Content = "God Mode Enabled!", Duration = 3})
    else
        if hiRemote then pcall(function() hiRemote:FireServer(450) end) end
        if iriRemote then pcall(function() iriRemote:FireServer(0) end) end
    end
end)

Hub.CreateSlider(sandboxTab, "Custom Health", 100, 10000, 1000, " HP", function(val)
    State.CustomHealth = val
    local hiRemote = getSandboxRemote("hi")
    if hiRemote then
        pcall(function() hiRemote:FireServer(val) end)
    end
end)

Hub.CreateSlider(sandboxTab, "Damage Resistance", 0, 100, 0, "%", function(val)
    State.CustomResistance = val
    local iriRemote = getSandboxRemote("iri")
    if iriRemote then
        pcall(function() iriRemote:FireServer(val) end)
    end
end)

Hub.CreateSlider(sandboxTab, "Player Character Scale", 1, 10, 1, "x", function(val)
    State.CustomSize = val
    local hiriRemote = getSandboxRemote("hiri")
    if hiriRemote then
        pcall(function() hiriRemote:FireServer(val) end)
    end
end)

Hub.CreateSection(sandboxTab, "Sandbox Actions")

Hub.CreateButton(sandboxTab, "Give Sandbox Cash", function()
    local cashBtn = getSandboxButton("cash")
    if cashBtn then
        triggerButton(cashBtn)
        Hub.Notify({Title = "Sandbox", Content = "Cash trigger fired!", Duration = 3})
    end
end)

Hub.CreateButton(sandboxTab, "Get Toolgun", function()
    local toolgunBtn = getSandboxButton("toolgun")
    if toolgunBtn then
        triggerButton(toolgunBtn)
        Hub.Notify({Title = "Sandbox", Content = "Toolgun trigger fired!", Duration = 3})
    end
end)

Hub.CreateToggle(sandboxTab, "Auto Regeneration Pad Prompt", false, function(v)
    State.AutoRegenPad = (type(v) == "boolean") and v or not State.AutoRegenPad
end)

-- -------------------------------------------------------------------------
-- Visuals Tab
-- -------------------------------------------------------------------------
Hub.CreateSection(visualTab, "ESP Overlays")

Hub.CreateToggle(visualTab, "Enemy ESP (Name, HP, Distance)", false, function(v)
    State.EnemyESP = (type(v) == "boolean") and v or not State.EnemyESP
    if not State.EnemyESP then clearESP() end
end)

Hub.CreateToggle(visualTab, "Ally ESP", false, function(v)
    State.AllyESP = (type(v) == "boolean") and v or not State.AllyESP
    if not State.AllyESP then clearESP() end
end)

Hub.CreateToggle(visualTab, "Airdrop ESP", false, function(v)
    State.AirdropESP = (type(v) == "boolean") and v or not State.AirdropESP
    if not State.AirdropESP then clearESP() end
end)

-- -------------------------------------------------------------------------
-- Player Tab
-- -------------------------------------------------------------------------
Hub.CreateSection(playerTab, "Local Player Modifiers")

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
Hub.CreateSection(miscTab, "Game Teleports & Info")

Hub.CreateButton(miscTab, "Teleport to Spawn Area", function()
    local root = getRootPart()
    local spawnPart = Workspace:FindFirstChild("Spawn") or Workspace:FindFirstChild("areaspawn")
    if root and spawnPart then
        root.CFrame = spawnPart.CFrame + Vector3.new(0, 4, 0)
    end
end)

Hub.CreateButton(miscTab, "Teleport to Regeneration Pad", function()
    local root = getRootPart()
    local regen = Workspace:FindFirstChild("Upgrades") and Workspace.Upgrades:FindFirstChild("Regeneration")
    if root and regen then
        root.CFrame = regen.CFrame + Vector3.new(0, 4, 0)
    end
end)

Hub.CreateButton(miscTab, "Teleport to Safe Sky (AFK)", function()
    local root = getRootPart()
    if root then
        root.CFrame = root.CFrame + Vector3.new(0, 150, 0)
    end
end)

Hub.CreateToggle(miscTab, "Auto Collect Airdrops (TP)", false, function(v)
    State.AutoCollectAirdrops = (type(v) == "boolean") and v or not State.AutoCollectAirdrops
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

-- 4. Auto Summon Loop
task.spawn(function()
    while true do
        if _G.SBD_SESSION ~= currentSession then break end
        if State.AutoSummon then
            summonAlly(State.SelectedAlly)
            local rate = math.clamp(tonumber(State.AutoSummonRate) or 2.0, 0.5, 30.0)
            task.wait(rate)
        else
            task.wait(0.5)
        end
    end
end)

-- 5. Auto Regen Pad Loop
task.spawn(function()
    while true do
        if _G.SBD_SESSION ~= currentSession then break end
        if State.AutoRegenPad then
            local hum = getHumanoid()
            if hum and hum.Health < hum.MaxHealth then
                local regen = Workspace:FindFirstChild("Upgrades") and Workspace.Upgrades:FindFirstChild("Regeneration")
                local prompt = regen and regen:FindFirstChildOfClass("ProximityPrompt")
                if prompt and fireproximityprompt then
                    pcall(function()
                        fireproximityprompt(prompt)
                    end)
                end
            end
            task.wait(1.0)
        else
            task.wait(1.0)
        end
    end
end)

-- 6. Auto Collect Airdrops Loop
task.spawn(function()
    while true do
        if _G.SBD_SESSION ~= currentSession then break end
        if State.AutoCollectAirdrops then
            local adFolder = Workspace:FindFirstChild("Airdrops")
            local root = getRootPart()
            if adFolder and root then
                for _, ad in ipairs(adFolder:GetChildren()) do
                    local adPart = ad:IsA("Model") and (ad.PrimaryPart or ad:FindFirstChildWhichIsA("BasePart")) or ad
                    if adPart and adPart:IsA("BasePart") then
                        local oldCf = root.CFrame
                        root.CFrame = adPart.CFrame + Vector3.new(0, 2, 0)
                        task.wait(0.2)
                        for _, p in ipairs(ad:GetDescendants()) do
                            if p:IsA("ProximityPrompt") and fireproximityprompt then
                                pcall(function() fireproximityprompt(p) end)
                            end
                        end
                        task.wait(0.3)
                        root.CFrame = oldCf
                    end
                end
            end
            task.wait(2.0)
        else
            task.wait(1.0)
        end
    end
end)

-- 7. ESP Loop
task.spawn(function()
    while true do
        if _G.SBD_SESSION ~= currentSession then break end
        if State.EnemyESP or State.AllyESP or State.AirdropESP then
            updateESP()
            task.wait(0.5)
        else
            task.wait(1.0)
        end
    end
end)

-- 8. Humanoid & Godmode Persistence Loop
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
            if State.GodMode then
                local hiRemote = getSandboxRemote("hi")
                if hiRemote and hum.Health < 100000 then
                    pcall(function() hiRemote:FireServer(9999999) end)
                end
            end
        end
        task.wait(0.5)
    end
end)

print("[Unknown Hub] Siege Box Defense Expanded Script Loaded Successfully!")
Hub.Notify({
    Title = "Siege Box Defense",
    Content = "Unknown Hub loaded! Combat, Defense & Sandbox ready.",
    Duration = 4
})
