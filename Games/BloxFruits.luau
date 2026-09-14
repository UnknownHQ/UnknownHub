local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer

local LIBRARY_LINK = "https://raw.githubusercontent.com/UnknownHQ/UnknownHub/main/UnknownLibrary"
local LIBRARY_NAME = "ENI_TabbedHub_UI"

local function destroyOldGui()
    local parents = {game:GetService("CoreGui")}
    if gethui then pcall(function() table.insert(parents, gethui()) end) end
    local playerGui = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
    if playerGui then table.insert(parents, playerGui) end
    for _, parent in ipairs(parents) do
        if parent then
            pcall(function()
                for _, child in ipairs(parent:GetChildren()) do
                    if child:IsA("ScreenGui") and (child.Name == LIBRARY_NAME or child.Name == "ENI_BloxFruits_GuiContainer" or child.Name == "ENI_MainGui") then
                        pcall(function() child:Destroy() end)
                    end
                end
            end)
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
    subTitle = "Blox Fruits",
    parent = (gethui and gethui()) or (LocalPlayer and (LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui"))) or (pcall(function() return game:GetService("CoreGui") end) and game:GetService("CoreGui")),
    theme = Color3.fromRGB(0, 195, 245),
    secondaryTheme = Color3.fromRGB(165, 95, 255)
})

assert(type(Hub) == "table", "UnknownLibrary returned an invalid hub")

-- Anti-AFK Connection
local VirtualUser = game:GetService("VirtualUser")
LocalPlayer.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    task.wait(1)
    VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
end)

local function getPlayerLevel()
    local data = LocalPlayer:FindFirstChild("Data")
    if data and data:FindFirstChild("Level") then return data.Level.Value end
    return 1
end

local lastBusoAttempt = 0
local function ensureBusoHakiActive()
    if not isAutoHakiOn then return end
    if tick() - lastBusoAttempt < 5 then return end
    pcall(function()
        local char = LocalPlayer.Character or (workspace:FindFirstChild("Characters") and workspace.Characters:FindFirstChild(LocalPlayer.Name))
        if char and not char:FindFirstChild("HasBuso") and not char:FindFirstChild("Buso") then
            local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
            if remotes and remotes:FindFirstChild("CommF_") then
                lastBusoAttempt = tick()
                remotes.CommF_:InvokeServer("Buso")
            end
        end
    end)
end

-- Enable on CharacterRespawn / Reset
LocalPlayer.CharacterAdded:Connect(function(newChar)
    newChar:WaitForChild("HumanoidRootPart", 5)
    task.wait(1.5)
    if isAutoHakiOn then
        ensureBusoHakiActive()
    end
end)

-- Clean up previous script global loops
if _G.ENI_MainFarmLoop then pcall(function() _G.ENI_MainFarmLoop:Disconnect() end) _G.ENI_MainFarmLoop = nil end
if _G.ENI_FastHitLoop then pcall(function() _G.ENI_FastHitLoop:Disconnect() end) _G.ENI_FastHitLoop = nil end
if _G.ENI_TravelTween then pcall(function() _G.ENI_TravelTween:Cancel() end) _G.ENI_TravelTween = nil end
if _G.ENI_GlobalLoop then pcall(function() _G.ENI_GlobalLoop:Disconnect() end) _G.ENI_GlobalLoop = nil end
if _G.ENI_ChestTween then pcall(function() _G.ENI_ChestTween:Cancel() end) _G.ENI_ChestTween = nil end

-- UNANCHOR PLAYER & RESTORE MOVEMENT
pcall(function()
    local char = LocalPlayer.Character
    if char then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BodyVelocity") or part:IsA("BodyGyro") then part:Destroy() end
        end
        if char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.Anchored = false
            char.HumanoidRootPart.Velocity = Vector3.zero
        end
        if char:FindFirstChildOfClass("Humanoid") then
            char.Humanoid.PlatformStand = false
        end
    end
end)

-- AUTO-ENABLED WALK ON WATER (JESUS WALK) ENGINE
local isWaterWalkOn = true
if _G.ENI_WaterWalkConn then pcall(function() _G.ENI_WaterWalkConn:Disconnect() end) end
local waterPlatform = workspace:FindFirstChild("ENI_WaterPlatform")
if not waterPlatform then
    waterPlatform = Instance.new("Part")
    waterPlatform.Name = "ENI_WaterPlatform"
    waterPlatform.Size = Vector3.new(120, 1, 120)
    waterPlatform.Anchored = true
    waterPlatform.CanCollide = true
    waterPlatform.Transparency = 1
    waterPlatform.Material = Enum.Material.SmoothPlastic
    waterPlatform.Parent = workspace
end

_G.ENI_WaterWalkConn = RunService.RenderStepped:Connect(function()
    pcall(function()
        if not isWaterWalkOn then
            waterPlatform.CanCollide = false
            return
        end
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            if hrp.Position.Y <= 2 and hrp.Position.Y >= -80 then
                waterPlatform.CFrame = CFrame.new(hrp.Position.X, -3.8, hrp.Position.Z)
                waterPlatform.CanCollide = true
            else
                waterPlatform.CanCollide = false
            end
        end
    end)
end)



local isTraveling = false
local safeTweenToIsland -- Forward declaration

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local CommF = Remotes:WaitForChild("CommF_")
local Net = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Net")
local RegisterAttack = Net:FindFirstChild("RE/RegisterAttack")
local RegisterHit = Net:FindFirstChild("RE/RegisterHit")

local currentThemeColor = Color3.fromRGB(0, 180, 220)
local themeLabels = {}
local themeStrokes = {}
local themeFrames = {}
local themeImages = {}

local function applyCorner(obj, radius)
    if not obj then return nil end
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = obj
    return c
end

local function applyStroke(obj, color, thickness, transparency)
    if not obj then return nil end
    local s = Instance.new("UIStroke")
    s.Color = color or Color3.fromRGB(42, 52, 74)
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0
    s.Parent = obj
    return s
end

local function restoreCharacterPhysics()
    pcall(function()
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = true end
            end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.PlatformStand = false
                hum.AutoRotate = true
            end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                if removeTabBV then removeTabBV(hrp) end
                hrp.Velocity = Vector3.zero
            end
        end
    end)
end

_G.ENI_CancelTween = function()
    if _G.ENI_TravelTween then
        pcall(function() _G.ENI_TravelTween:Cancel() end)
        _G.ENI_TravelTween = nil
    end
    isTraveling = false
end

local function registerThemeText(lbl)
    table.insert(themeLabels, lbl)
    lbl.TextColor3 = currentThemeColor
end

local function registerThemeStroke(stroke)
    table.insert(themeStrokes, stroke)
    stroke.Color = currentThemeColor
end

local function registerThemeFrame(frm)
    table.insert(themeFrames, frm)
    frm.BackgroundColor3 = currentThemeColor
end

local function setThemeColor(newColor)
    currentThemeColor = newColor
    for _, l in ipairs(themeLabels) do pcall(function() l.TextColor3 = newColor end) end
    for _, s in ipairs(themeStrokes) do pcall(function() s.Color = newColor end) end
    for _, f in ipairs(themeFrames) do pcall(function() f.BackgroundColor3 = newColor end) end
    for _, img in ipairs(themeImages) do pcall(function() img.ImageColor3 = newColor end) end
end

local function getTabBV(hrp)
    if not hrp then return nil end
    local bv = hrp:FindFirstChild("ENI_TabBV")
    if not bv then
        bv = Instance.new("BodyVelocity")
        bv.Name = "ENI_TabBV"
        bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
        bv.Velocity = Vector3.zero
        bv.Parent = hrp
    end
    return bv
end

local function removeTabBV(hrp)
    if hrp then
        local bv = hrp:FindFirstChild("ENI_TabBV")
        if bv then bv:Destroy() end
    end
end

local function notifyGUI(titleText, msgText, durationSec)
    Hub.notify({
        Title = titleText or "Notification",
        Content = msgText or "",
        Duration = durationSec or 3.5
    })
end

local function CreateButton(parent, text, _yPos_ignored, callback)
    return Hub.CreateButton(parent or Hub.content, text, callback)
end

local function CreateToggle(parent, text, _yPos_ignored, callback)
    return Hub.CreateToggle(parent or Hub.content, text, false, callback)
end

local function CreateSlider(parent, text, minVal, maxVal, defaultVal, _yPos_ignored, callback)
    return Hub.CreateSlider(parent or Hub.content, text, minVal, maxVal, defaultVal, "", callback)
end

local function CreateDropdown(parent, text, options, defaultVal, _yPos_ignored, callback)
    return Hub.CreateDropdown(parent or Hub.content, text, options, defaultVal, callback)
end

local function CreateSection(parent, text)
    return Hub.CreateSection(parent or Hub.content, text)
end

local function CreateList(parent, name, items)
    return Hub.CreateList(parent or Hub.content, name, items)
end

local function createCollapsibleList(parent, name, maxHeight, isCollapsed)
    return Hub.CreateList(parent or Hub.content, name, {}, maxHeight, isCollapsed)
end

local function createListItem(listObj, titleText, subtitleText, callback)
    if listObj and listObj.AddItem then
        return listObj:AddItem(titleText, subtitleText, callback)
    end
end

local function addSectionDivider(parent)
    local divider = Instance.new("Frame")
    divider.Size = UDim2.new(0.98, 0, 0, 1)
    divider.BackgroundColor3 = Color3.fromRGB(35, 42, 58)
    divider.BorderSizePixel = 0
    pcall(function() divider.Parent = parent or Hub.content end)
    return divider
end

local isAntiAfkOn = true
local isHudOn = false
local isSnipeOn = false
local startChestFarm = nil
local stopChestFarm = nil

-- Create Hub Tabs
local farmPage = Hub.createTabButton("Auto Farm", "Auto Farm", "rbxassetid://10709782497", true)
local questPage = Hub.createTabButton("Quests", "Quests", "rbxassetid://10709798226", false)
local playerPage = Hub.createTabButton("Player", "Player", "rbxassetid://10709818834", false)
local statsPage = Hub.createTabButton("Auto Stats", "Auto Stats", "rbxassetid://10709761596", false)
local bossPage = Hub.createTabButton("Auto Boss", "Auto Boss", "rbxassetid://10709810814", false)
local fruitPage = Hub.createTabButton("Fruit", "Fruit", "rbxassetid://10709781448", false)
local espPage = Hub.createTabButton("ESP", "ESP", "rbxassetid://10709775400", false)
local miscPage = Hub.createTabButton("Misc", "Misc", "rbxassetid://10709810488", false)
local serverPage = Hub.createTabButton("Server", "Server", "rbxassetid://10709809930", false)
local travelPage = Hub.createTabButton("Travel", "Travel", "rbxassetid://10709798485", false)
local shopPage = Hub.createTabButton("Shop", "Shop", "rbxassetid://10709810237", false)

do
    Hub.CreateSection(serverPage, "🌐 Smart Server Hopper & Management")

    _G.ENI_SmartServerHop = function(mode)

        -- Anti-Spam Debounce Guard (Prevents notification spam and repeating teleport attempts)
        if _G.ENI_LastServerHopTick and (tick() - _G.ENI_LastServerHopTick) < 8 then
            return
        end
        _G.ENI_LastServerHopTick = tick()

        local HttpService = game:GetService("HttpService")
        local TeleportService = game:GetService("TeleportService")
        local currentJob = game.JobId
        local pId = game.PlaceId

        -- Normalize PlaceId to Blox Fruits Sea Root PlaceId to prevent Restricted Place errors
        local mainPlaceId = 2753915549 -- 1st Sea Default
        if pId == 4442272183 or (workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Cafe")) then
            mainPlaceId = 4442272183 -- 2nd Sea
        elseif pId == 7449423635 or (workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Mansion")) then
            mainPlaceId = 7449423635 -- 3rd Sea
        else
            mainPlaceId = 2753915549 -- 1st Sea
        end

        if mode == "rejoin" then
            notifyGUI("SERVER", "Rejoining Blox Fruits...", 4)
            task.spawn(function()
                pcall(function()
                    TeleportService:Teleport(mainPlaceId, LocalPlayer)
                end)
            end)
            return
        end

        notifyGUI("SERVER", "Fetching " .. mode .. " server list...", 3)

        task.spawn(function()
            local success, err = pcall(function()
                local sortOrder = (mode == "freshest") and "Desc" or "Asc"
                local url = "https://games.roblox.com/v1/games/" .. mainPlaceId .. "/servers/Public?sortOrder=" .. sortOrder .. "&limit=100"
                local raw = game:HttpGet(url)
                local parsed = HttpService:JSONDecode(raw)

                if not parsed or not parsed.data or #parsed.data == 0 then
                    notifyGUI("SERVER", "Matchmaking server hop...", 3)
                    TeleportService:Teleport(mainPlaceId, LocalPlayer)
                    return
                end

                local validServers = {}
                for _, s in ipairs(parsed.data) do
                    if type(s) == "table" and s.id ~= currentJob and s.playing and s.maxPlayers and s.playing > 0 and s.playing < s.maxPlayers then
                        table.insert(validServers, s)
                    end
                end

                if #validServers == 0 then
                    notifyGUI("SERVER", "Matchmaking server hop...", 3)
                    TeleportService:Teleport(mainPlaceId, LocalPlayer)
                    return
                end

                if mode == "lowest" then
                    table.sort(validServers, function(a, b) return a.playing < b.playing end)
                elseif mode == "oldest" then
                    table.sort(validServers, function(a, b) return a.playing > b.playing end)
                elseif mode == "freshest" then
                    table.sort(validServers, function(a, b) return a.playing < b.playing end)
                end

                local targetServer = validServers[math.random(1, math.min(3, #validServers))]
                notifyGUI("SERVER", string.format("Joining server (%d/%d players)...", targetServer.playing, targetServer.maxPlayers), 4)
                
                TeleportService:TeleportToPlaceInstance(mainPlaceId, targetServer.id, LocalPlayer)
            end)

            if not success then
                notifyGUI("SERVER", "Matchmaking server hop...", 3)
                pcall(function() TeleportService:Teleport(mainPlaceId, LocalPlayer) end)
            end
        end)
    end

    CreateButton(serverPage, "🔄 Rejoin Same Server", nil, function() _G.ENI_SmartServerHop("rejoin") end)
    CreateButton(serverPage, "📉 Hop to Lowest Player Server", nil, function() _G.ENI_SmartServerHop("lowest") end)
    CreateButton(serverPage, "⏳ Hop to Oldest Server", nil, function() _G.ENI_SmartServerHop("oldest") end)
    CreateButton(serverPage, "⚡ Hop to Freshest Server", nil, function() _G.ENI_SmartServerHop("freshest") end)

    -- Job ID Box & Controls
    local enteredJobId = ""
    local jobIdBox = Hub.CreateTextBox(serverPage, "Paste Job ID here...", "", function(txt)
        enteredJobId = txt
    end)

    Hub.CreateButton(serverPage, "🎯 Join by Job ID", nil, function()
        local targetJobId = enteredJobId
        if (not targetJobId or targetJobId == "") and jobIdBox and jobIdBox.Text then
            targetJobId = jobIdBox.Text
        end
        if targetJobId and targetJobId ~= "" then
            notifyGUI("SERVER", "Joining Job ID...", 3)
            game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, targetJobId, LocalPlayer)
        else
            notifyGUI("ERROR", "Please enter a valid Job ID!", 3)
        end
    end)

    Hub.CreateButton(serverPage, "📋 Copy Current Job ID", nil, function()
        if setclipboard then
            setclipboard(tostring(game.JobId))
            notifyGUI("COPIED", "Server Job ID copied to clipboard!", 3)
        elseif toclipboard then
            toclipboard(tostring(game.JobId))
            notifyGUI("COPIED", "Server Job ID copied to clipboard!", 3)
        else
            notifyGUI("ERROR", "Clipboard function not supported by executor!", 3)
        end
    end)
end

local toggleSetters = {}
local allToggleSetters = {}
local activeToggleTracks = {}

-- UNKNOWN LIBRARY TOGGLE INTEGRATION
local function createSliderToggle(parent, titleText, defaultState, callback, keyName)
    local toggleObj = Hub.CreateToggle(parent or Hub.content, titleText, defaultState, callback)
    local getFn = (type(toggleObj) == "table" and toggleObj.Get) or function() return false end
    local setFn = (type(toggleObj) == "table" and toggleObj.Set) or function(v) end
    if keyName then
        toggleSetters[keyName] = setFn
    end
    return getFn, setFn, toggleObj
end

_G.ENI_FarmDistance = math.max(_G.ENI_FarmDistance or 10.0, 10.0)

-- UNKNOWN LIBRARY SLIDER INTEGRATION
local function createValueSlider(parent, titleText, minVal, maxVal, defaultVal, unitText, callback)
    return Hub.CreateSlider(parent or Hub.content, titleText, minVal, maxVal, defaultVal, unitText or "", callback)
end

-- UNKNOWN LIBRARY COLLAPSIBLE LIST INTEGRATION
local function createCollapsibleList(parent, titleText, heightPx, defaultOpen)
    local targetHeight = heightPx or 180
    local listObj = Hub.CreateList(parent or Hub.content, titleText, {}, targetHeight, defaultOpen ~= false)
    local scroll = (type(listObj) == "table" and listObj.List) or parent
    local titleProxy = {
        _raw = listObj,
        Text = titleText
    }
    setmetatable(titleProxy, {
        __index = function(t, k)
            if k == "Text" then
                return (type(listObj) == "table" and listObj.Title) or rawget(t, "_text") or titleText
            end
            return rawget(t, k)
        end,
        __newindex = function(t, k, v)
            if k == "Text" then
                rawset(t, "_text", tostring(v))
                if type(listObj) == "table" then
                    listObj.Title = tostring(v)
                    pcall(function()
                        if listObj.Frame then
                            local btn = listObj.Frame:FindFirstChildOfClass("TextButton")
                            if btn then
                                local isNested = listObj.Frame.Name:find("Sub%-List")
                                btn.Text = (isNested and "  › " or "  ") .. tostring(v)
                            end
                        end
                    end)
                end
            else
                rawset(t, k, v)
            end
        end
    })
    return scroll, titleProxy, listObj
end

-- UNKNOWN LIBRARY LIST ITEM INTEGRATION
local function createListItem(parent, titleText, subtitleText, callback)
    if type(parent) == "table" and parent.AddItem then
        return parent:AddItem(titleText, subtitleText, callback)
    elseif typeof(parent) == "Instance" then
        return Hub.addItem(titleText, subtitleText, callback)
    end
    return Hub.addItem(titleText, subtitleText, callback)
end

-- WEAPON & FARM GLOBALS
local selectedWeaponType = "Melee" -- "Melee", "Blox Fruit", "Sword", "Gun"
local selectedMasteryWeapon = "Sword"
local selectedSkillsWeapon = "Blox Fruit"
local selectedCustomMobName = "Bandit"
local activeSkills = {Z = true, X = true, C = true, V = true}

local isFarmOn = false
local isAutoSelectMobOn = false
local isAutoMaterialOn = false
local selectedMaterial = "Leather"
local isAutoQuestOn = true
local isAuraHitOn = true
local selectedFastAttackTarget = "NPCs" -- "NPCs", "Players", "Everyone"
local isAutoHakiOn = false
local isAutoSkillsOn = false
local isAutoMasteryOn = false
local isInfEnergyOn = false
local isAutoChestOn = false
local isAutoRollOn = false
local selectedSnipeFruit = "Kitsune"
local isStatsOn = false
local selectedStats = {["Melee"] = true, ["Defense"] = true, ["Sword"] = false, ["Gun"] = false, ["Demon Fruit"] = false}
local pointsPerUpgrade = 3
local activeTravelIsland = nil

local MaterialData = {
    ["Leather"] = {MobName = "Pirate", IslandCFrame = CFrame.new(-1100, 4, 3900)},
    ["Scrap Metal"] = {MobName = "Brute", IslandCFrame = CFrame.new(-1150, 15, 4300)},
    ["Angel Wings"] = {MobName = "Sky Bandit", IslandCFrame = CFrame.new(-4800, 715, -2600)},
    ["Magma Ore"] = {MobName = "Military Soldier", IslandCFrame = CFrame.new(-5400, 15, 8600)},
    ["Fish Tail"] = {MobName = "Fishman Warrior", IslandCFrame = CFrame.new(61000, 18, 1500)},
    ["Radioactive Material"] = {MobName = "Factory Staff", IslandCFrame = CFrame.new(295, 73, -60)},
    ["Vampire Fang"] = {MobName = "Vampire", IslandCFrame = CFrame.new(-6000, 15, -4800)},
    ["Ectoplasm"] = {MobName = "Ship Deckhand", IslandCFrame = CFrame.new(900, 130, 32800)},
    ["Mystic Droplet"] = {MobName = "Water Fighter", IslandCFrame = CFrame.new(-3300, 10, -10200)},
    ["Dragon Scale"] = {MobName = "Dragon Crew Warrior", IslandCFrame = CFrame.new(-2200, 73, -4400)},
    ["Gunpowder"] = {MobName = "Pistol Billionaire", IslandCFrame = CFrame.new(-1050, 40, 6700)},
    ["Mini Tusk"] = {MobName = "Mythological Pirate", IslandCFrame = CFrame.new(-13400, 330, -8400)},
    ["Bones"] = {MobName = "Reborn Skeleton", IslandCFrame = CFrame.new(-9500, 140, 5500)},
    ["Demonic Soul"] = {MobName = "Demonic Soul", IslandCFrame = CFrame.new(-9500, 140, 6000)},
    ["Conjured Cocoa"] = {MobName = "Chocolate Bar Battler", IslandCFrame = CFrame.new(6500, 70, 1200)}
}

local farmStatusLabel -- Global reference for status updates

local weaponTypes = {"Melee", "Blox Fruit", "Sword", "Gun"}
local fastAttackTargets = {"NPCs", "Players", "Everyone"}

-- FARM PAGE LAYOUT & CONTROLS
do
    -- 1. Master Auto Farm Engine
    local getFarmState, setFarmState = createSliderToggle(farmPage, "Auto Farm Engine", false, function(newState)
        isFarmOn = newState
        if isFarmOn then
            _G.startENIFarm()
        else
            _G.stopENIFarm()
        end
    end, "AutoFarm")
    _G.ENI_setFarmState = setFarmState

    -- 1b. Auto Farm Distance Slider (Positioned directly below Auto Farm Engine)
    createValueSlider(farmPage, "📏 Auto Farm Distance", 10.0, 30.0, math.max(_G.ENI_FarmDistance or 10.0, 10.0), "studs", function(newDist)
        _G.ENI_FarmDistance = math.max(newDist, 10.0)
    end)

    -- 2. Farm Weapon Selection Mode
    local weaponList = Hub.CreateList(farmPage, "🗡️ Farm Weapon Mode", weaponTypes, function(wName)
        selectedWeaponType = wName
    end, false)
    weaponList:SetSelected(selectedWeaponType)

    -- 3. Auto Quest Mode
    createSliderToggle(farmPage, "Auto Take Quest", true, function(newState)
        isAutoQuestOn = newState
    end, "AutoQuest")

    -- 4. Fast Attack / Hit Stream & Target Mode Selector
    createSliderToggle(farmPage, "Fast Attack / Fast Hit Stream", true, function(newState)
        isAuraHitOn = newState
    end, "AuraHit")

    local faList = Hub.CreateList(farmPage, "⚡ Fast Attack Target", fastAttackTargets, function(tName)
        selectedFastAttackTarget = tName
    end, false)
    faList:SetSelected(selectedFastAttackTarget)

    -- 5. Auto Buso Haki
    createSliderToggle(farmPage, "Auto Buso Haki", true, function(newState)
        isAutoHakiOn = newState
        if newState then ensureBusoHakiActive() end
    end, "AutoHaki")

    -- 5b. Auto Ken Haki (Observation Haki / Instinct EXP Leveler)
    local isAutoKenOn = false
    local hasKenHaki = LocalPlayer:FindFirstChild("Ken") or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Ken"))
    local kenTitle = hasKenHaki and "👁️ Auto Ken Haki" or "👁️ Ken Haki"

    createSliderToggle(farmPage, kenTitle, false, function(newState)
        if not hasKenHaki and newState then
            notifyGUI("KEN HAKI", "You don't own Ken Haki yet! Buy it at Skylands Upper Yard for $750,000.", 5)
            return
        end
        isAutoKenOn = newState
        if isAutoKenOn then
            notifyGUI("KEN HAKI", "Ken Haki Leveler active! Auto dodging attacks...", 3)
        end
    end)

    -- 6. Custom Mob Selection
    createSliderToggle(farmPage, "Auto Farm Selected NPC", false, function(newState)
        isAutoSelectMobOn = newState
    end)

    local mobNamesList = {
        "Bandit", "Monkey", "Gorilla", "Pirate", "Brute", "Desert Bandit", "Snow Bandit",
        "Snowman", "Chief Petty Officer", "Sky Bandit", "Dark Master", "Toga Warrior",
        "Military Soldier", "Fishman Warrior", "God's Guard", "Shandora Warrior", "Galley Pirate",
        "Raider", "Mercenary", "Swan Pirate", "Factory Staff", "Marine Lieutenant", "Marine Captain",
        "Giant Gladiator", "Military Spy", "Dragon Crew Warrior", "Dragon Crew Archer",
        "Lab Subordinate", "Horned Warrior", "Magma Ninja", "Lava Pirate", "Ship Deckhand",
        "Ice Soldier", "Arctic Warrior", "Sea Soldier", "Water Fighter"
    }
    local mobList = Hub.CreateList(farmPage, "🎯 Select Custom NPC", mobNamesList, function(mName)
        selectedCustomMobName = mName
    end, false)
    mobList:SetSelected(selectedCustomMobName)

    -- 6b. Auto Farm Material
    createSliderToggle(farmPage, "Auto Farm Material", false, function(newState)
        isAutoMaterialOn = newState
    end)

    local materialNamesList = {
        "Leather", "Scrap Metal", "Angel Wings", "Magma Ore", "Fish Tail",
        "Radioactive Material", "Vampire Fang", "Ectoplasm", "Mystic Droplet",
        "Dragon Scale", "Gunpowder", "Mini Tusk", "Bones", "Demonic Soul", "Conjured Cocoa"
    }
    local matList = Hub.CreateList(farmPage, "📦 Select Material", materialNamesList, function(matName)
        selectedMaterial = matName
    end, false)
    matList:SetSelected(selectedMaterial)

    -- 7. Auto Mastery Selection
    createSliderToggle(farmPage, "Auto Mastery", false, function(newState)
        isAutoMasteryOn = newState
    end)

    local masteryList = Hub.CreateList(farmPage, "🎯 Mastery Finish Weapon", weaponTypes, function(wName)
        selectedMasteryWeapon = wName
    end, false)
    masteryList:SetSelected(selectedMasteryWeapon)

    -- 8. Auto Abilities Execution & Skill Selector
    createSliderToggle(farmPage, "Auto Abilities", false, function(newState)
        isAutoSkillsOn = newState
    end)

    local skillsWList = Hub.CreateList(farmPage, "🔥 Auto Skills Weapon", weaponTypes, function(wName)
        selectedSkillsWeapon = wName
    end, false)
    skillsWList:SetSelected(selectedSkillsWeapon)

    local skillsList = Hub.CreateList(farmPage, "✨ Select Combat Skills", {
        {Name = "Skill [Z]", Desc = "Activate Z skill in battle"},
        {Name = "Skill [X]", Desc = "Activate X skill in battle"},
        {Name = "Skill [C]", Desc = "Activate C skill in battle"},
        {Name = "Skill [V]", Desc = "Activate V skill in battle"},
        {Name = "Skill [F]", Desc = "Activate F skill in battle"}
    }, function(sName, entry)
        local key = sName:match("%[(%w+)%]")
        if key then
            activeSkills[key] = not not (skillsList.SelectedItems and (table.find(skillsList.SelectedItems, entry) or table.find(skillsList.SelectedItems, sName)))
        end
    end, false, {MultiSelect = true})
    skillsList:SetSelectedItems({"Skill [Z]", "Skill [X]", "Skill [C]", "Skill [V]", "Skill [F]"})

    -- 9. Auto Farm Chests
    createSliderToggle(farmPage, "Auto Farm Chests", false, function(newState)
        isAutoChestOn = newState
        if isAutoChestOn then
            if type(startChestFarm) == "function" then startChestFarm() end
        else
            if type(stopChestFarm) == "function" then stopChestFarm() end
        end
    end)

    -- 10. Status Label
    farmStatusLabel = Instance.new("TextLabel")
    farmStatusLabel.Name = "Status"
    farmStatusLabel.Size = UDim2.new(0.98, 0, 0, 24)
    farmStatusLabel.BackgroundTransparency = 1
    farmStatusLabel.Text = "Status: Use the Slider Switch to Toggle Auto Farm."
    farmStatusLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    farmStatusLabel.Font = Enum.Font.Gotham
    farmStatusLabel.TextSize = 13
    pcall(function() farmStatusLabel.Parent = farmPage end)
end

-- QUESTS PAGE SETUP
do
    -- =========================================================================
    -- [1ST SEA] AUTOMATED SPECIAL QUESTS
    -- =========================================================================
    Hub.CreateSection(questPage, "🌊 1st Sea Special Quests")

local isSaberQuestOn = false
    local saberThread = nil

    createSliderToggle(questPage, "[1st Sea] 🗡️ Auto Saber Quest", false, function(newState)
        isSaberQuestOn = newState
        if isSaberQuestOn then
            notifyGUI("Saber Quest", "Auto Saber Quest started.", 4)
            saberThread = task.spawn(function()

                local lastNotifyMsg = ""
                local function debugLog(msg)
                    print("[ENI SABER] " .. msg)
                end
                local function debugNotify(msg)
                    if msg ~= lastNotifyMsg then
                        lastNotifyMsg = msg
                        notifyGUI("Saber", msg, 3)
                    end
                end

                local activeSaberTween = nil

                -- Uses the same safeTweenToIsland as auto farm for travel, then holds position
                local function warpTo(targetCF, label)
                    if not isSaberQuestOn then return false end
                    debugLog("Traveling to: " .. label)

                    -- Pause auto farm while saber quest is running
                    if _G.ENI_MainFarmLoop then
                        pcall(function() _G.ENI_MainFarmLoop:Disconnect() end)
                        _G.ENI_MainFarmLoop = nil
                    end

                    local char = LocalPlayer.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if not hrp then return false end

                    local dist = (targetCF.Position - hrp.Position).Magnitude
                    if dist <= 15 then
                        -- Already close — just set CFrame directly
                        hrp.CFrame = targetCF
                        task.wait(0.2)
                        return isSaberQuestOn
                    end

                    -- Use safeTweenToIsland (same as auto farm) for long-distance travel
                    local arrived = false
                    safeTweenToIsland(targetCF, function()
                        arrived = true
                    end)

                    -- Wait for tween to finish (same pattern as auto farm uses isTraveling)
                    local timeout = tick() + 30
                    while not arrived and isSaberQuestOn and tick() < timeout do
                        -- While traveling, keep noclip + zero velocity (like auto farm Heartbeat)
                        pcall(function()
                            local c = LocalPlayer.Character
                            local h = c and c:FindFirstChild("HumanoidRootPart")
                            if h then
                                local bv = getTabBV(h)
                                if bv then bv.Velocity = Vector3.zero end
                                for _, part in ipairs(c:GetChildren()) do
                                    if part:IsA("BasePart") then part.CanCollide = false end
                                end
                            end
                        end)
                        task.wait(0.05)
                    end

                    -- After arrival, hold position tightly (like auto farm's hover loop)
                    for i = 1, 15 do
                        pcall(function()
                            local c = LocalPlayer.Character
                            local h = c and c:FindFirstChild("HumanoidRootPart")
                            if h then
                                h.CFrame = targetCF
                                h.Velocity = Vector3.zero
                                local bv = getTabBV(h)
                                if bv then bv.Velocity = Vector3.zero end
                            end
                        end)
                        task.wait(0.03)
                    end

                    isTraveling = false
                    return isSaberQuestOn
                end

                -- Touch a plate by direct workspace path or verified CFrame. Smoothly tweens player and fires touch.
                local function touchPlate(plateData)
                    if not isSaberQuestOn then return end
                    local char = LocalPlayer.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end

                    -- Direct path lookup in Workspace.Map.Jungle.QuestPlates
                    local plateObj = nil
                    pcall(function()
                        local qp = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Jungle") and workspace.Map.Jungle:FindFirstChild("QuestPlates")
                        if qp then
                            local pModel = qp:FindFirstChild(plateData.pathName)
                            if pModel then
                                plateObj = pModel:FindFirstChild("Button") or pModel:FindFirstChildOfClass("TouchTransmitter") or pModel:FindFirstChildOfClass("Part")
                            end
                        end
                    end)

                    local targetCF = plateObj and (plateObj.CFrame * CFrame.new(0, 3, 0)) or (plateData.cf * CFrame.new(0, 3, 0))
                    warpTo(targetCF, plateData.name)
                    task.wait(0.2)

                    if firetouchinterest and plateObj then
                        pcall(function() firetouchinterest(hrp, plateObj, 0) end)
                        task.wait(0.05)
                        pcall(function() firetouchinterest(hrp, plateObj, 1) end)
                    end

                    task.wait(0.5)
                end

                -- Find a live enemy by name match in workspace.Enemies
                local function findEnemy(namePattern)
                    local enemyFolder = workspace:FindFirstChild("Enemies")
                    if not enemyFolder then return nil end
                    for _, e in ipairs(enemyFolder:GetChildren()) do
                        if string.find(e.Name, namePattern)
                            and e:FindFirstChild("HumanoidRootPart")
                            and e:FindFirstChildOfClass("Humanoid")
                            and e.Humanoid.Health > 0
                        then
                            return e
                        end
                    end
                    return nil
                end

                -- Kill an enemy by hovering above it and auto-equipping melee weapon.
                -- Uses encrypted WrappedHit for reliable damage. Returns true if killed.
                local function killEnemy(enemy, timeoutSec)
                    if not enemy then return false end
                    timeoutSec = timeoutSec or 30
                    local char = LocalPlayer.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if not hrp then return false end

                    -- Auto-equip melee weapon for boss fight
                    local function equipMelee()
                        local c = LocalPlayer.Character
                        if not c then return end
                        local held = c:FindFirstChildOfClass("Tool")
                        if held and (held.ToolTip == "Melee" or held.ToolTip == "Sword" or held.Name == "Combat") then return end
                        -- Unequip quest items (Cup, Torch, etc)
                        if held then
                            local bp = LocalPlayer:FindFirstChild("Backpack")
                            if bp then held.Parent = bp end
                        end
                        local bp = LocalPlayer:FindFirstChild("Backpack")
                        if bp then
                            for _, t in ipairs(bp:GetChildren()) do
                                if t:IsA("Tool") and (t.ToolTip == "Melee" or t.ToolTip == "Sword" or t.Name == "Combat") then
                                    local hum = c:FindFirstChildOfClass("Humanoid")
                                    if hum then hum:EquipTool(t) end
                                    task.wait(0.2)
                                    return
                                end
                            end
                        end
                    end

                    equipMelee()

                    local deadline = tick() + timeoutSec
                    local lastEquipCheck = 0
                    while isSaberQuestOn and tick() < deadline do
                        char = LocalPlayer.Character
                        hrp = char and char:FindFirstChild("HumanoidRootPart")
                        if not char or not hrp then return false end

                        local hum = enemy:FindFirstChildOfClass("Humanoid")
                        if not hum or hum.Health <= 0 then return true end

                        -- Stay above the enemy
                        local enemyHRP = enemy:FindFirstChild("HumanoidRootPart")
                        if not enemyHRP then return true end
                        hrp.CFrame = enemyHRP.CFrame * CFrame.new(0, 12, 0)

                        -- Re-check melee every 2 seconds
                        if tick() - lastEquipCheck > 2 then
                            equipMelee()
                            lastEquipCheck = tick()
                        end

                        -- Fire equipped tool
                        local tool = char:FindFirstChildOfClass("Tool")
                        if tool then pcall(function() tool:Activate() end) end

                        -- Use encrypted hit wrapper if available
                        pcall(function()
                            if _G.ENI_WrappedHit and enemyHRP then
                                _G.ENI_WrappedHit.FireServer(_G.ENI_WrappedHit, enemyHRP, {{enemy, enemyHRP}})
                            end
                        end)

                        task.wait(0.1)
                    end
                    local hum = enemy:FindFirstChildOfClass("Humanoid")
                    return not hum or hum.Health <= 0
                end

                -- Main quest loop — retries from top if anything goes wrong mid-run
                while isSaberQuestOn do
                    local ok, err = pcall(function()
                        local level = getPlayerLevel()
                        debugLog("Level " .. tostring(level) .. " — starting saber quest sequence")
                        debugNotify("Saber quest running (Lv" .. tostring(level) .. ")")

                        if level < 200 then
                            debugLog("Level 200 required. Currently " .. tostring(level) .. ". Waiting...")
                            task.wait(5)
                            return
                        end

                        local char = LocalPlayer.Character
                        local hrp = char and char:FindFirstChild("HumanoidRootPart")
                        if not hrp then return end

                        -- Helper to check inventory items (Backpack & Character)
                        local function hasQuestItem(itemName)
                            local char = LocalPlayer.Character
                            local bp = LocalPlayer:FindFirstChild("Backpack")
                            if char then
                                for _, t in ipairs(char:GetChildren()) do
                                    if t:IsA("Tool") and string.find(string.lower(t.Name), string.lower(itemName)) then return true end
                                end
                            end
                            if bp then
                                for _, t in ipairs(bp:GetChildren()) do
                                    if t:IsA("Tool") and string.find(string.lower(t.Name), string.lower(itemName)) then return true end
                                end
                            end
                            return false
                        end

                        local hasSaber = hasQuestItem("Saber")
                        local hasRelic = hasQuestItem("Relic")
                        local hasFullCup = hasQuestItem("Full Cup") or hasQuestItem("Cup (Full)")
                        local hasCup = hasQuestItem("Cup")
                        local hasTorch = hasQuestItem("Torch")

                        -- Cup is full if it's named Full Cup OR if it's a regular Cup but has Drop1 inside it
                        pcall(function()
                            local char = LocalPlayer.Character
                            local bp = LocalPlayer:FindFirstChild("Backpack")
                            local function isFilled(c)
                                return c and c:IsA("Tool") and (c.Name:find("Cup") or c.Name:find("cup")) and c:FindFirstChild("Drop1", true)
                            end
                            if char then
                                for _, v in ipairs(char:GetChildren()) do if isFilled(v) then hasFullCup = true end end
                            end
                            if bp then
                                for _, v in ipairs(bp:GetChildren()) do if isFilled(v) then hasFullCup = true end end
                            end
                        end)

                        if hasSaber then
                            debugLog("Saber already unlocked! Quest finished!")
                            notifyGUI("Saber Quest", "Saber is already in your inventory!", 5)
                            isSaberQuestOn = false
                            return
                        end

                        if hasRelic then
                            debugLog("⚡ Relic detected! Auto-skipping directly to Step 8 (Shanks Secret Room)")
                        elseif hasFullCup then
                            debugLog("⚡ Full Cup detected! Auto-skipping directly to Step 5 (Sick Man & Rich Man)")
                        elseif hasCup then
                            debugLog("⚡ Cup detected! Auto-skipping directly to Step 4 (Frozen Cave Cup Fill)")
                        elseif hasTorch then
                            debugLog("⚡ Torch detected! Auto-skipping directly to Step 2.5 (Burn Desert Cellar Door)")
                        end

                        -- ── STEP 1: Five Jungle Secret Plates ──────────────────────────────
                        if not (hasTorch or hasCup or hasFullCup or hasRelic) then
                            debugLog("Step 1/8: Jungle secret plates")
                            local junglePlates = {
                                { name = "Plate 1 (Main Grass)",     pathName = "Plate1", cf = CFrame.new(-1180.89, 21.00, 187.86) },
                                { name = "Plate 2 (Stone Pillar)",   pathName = "Plate2", cf = CFrame.new(-1421.20, 44.50, 21.60)   },
                                { name = "Plate 3 (Gorilla Tree)",  pathName = "Plate3", cf = CFrame.new(-1648.50, 19.50, 437.80)  },
                                { name = "Plate 4 (Gorilla Wall)",  pathName = "Plate4", cf = CFrame.new(-1324.10, 31.45, -461.40) },
                                { name = "Plate 5 (Small Island)",  pathName = "Plate5", cf = CFrame.new(-1152.16, -1.21, -700.43) }
                            }
                            for i, plate in ipairs(junglePlates) do
                                if not isSaberQuestOn then return end
                                debugLog("Activating " .. plate.name)
                                touchPlate(plate)
                            end

                            -- ── STEP 2: Torch from Jungle Ruins ────────────────────────────────
                            if not isSaberQuestOn then return end
                            debugLog("Step 2/8: Jungle ruins torch")
                            
                            local torchTargetCF = CFrame.new(-1610, 12, 164)
                            pcall(function()
                                local torchObj = workspace:FindFirstChild("Torch", true)
                                if torchObj and torchObj:IsA("BasePart") then
                                    torchTargetCF = torchObj.CFrame
                                elseif torchObj then
                                    local p = torchObj:FindFirstChildWhichIsA("BasePart", true)
                                    if p then torchTargetCF = p.CFrame end
                                end
                            end)

                            if not warpTo(torchTargetCF, "Jungle Ruins Torch") then return end
                            pcall(function() CommF:InvokeServer("GetTorch") end)
                            pcall(function()
                                local torchObj = workspace:FindFirstChild("Torch", true)
                                local char = LocalPlayer.Character
                                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                                if torchObj and hrp then
                                    local touchable = torchObj:IsA("BasePart") and torchObj or torchObj:FindFirstChildWhichIsA("BasePart", true)
                                    if touchable and firetouchinterest then
                                        firetouchinterest(hrp, touchable, 0)
                                        task.wait(0.05)
                                        firetouchinterest(hrp, touchable, 1)
                                    end
                                end
                            end)
                            task.wait(1.2)
                            hasTorch = hasQuestItem("Torch")
                        end

                        -- ── STEP 2.5 & STEP 3: Burn Desert Door & Grab Cup ──────────────
                        if not (hasCup or hasFullCup or hasRelic) then
                            if not isSaberQuestOn then return end
                            debugLog("Step 2.5/8: Burning Desert Cellar Door with Torch")
                            
                            local burnTargetCF = CFrame.new(1113, 5, 4351)
                            pcall(function()
                                local burnModel = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Desert") and workspace.Map.Desert:FindFirstChild("Burn")
                                if burnModel then
                                    local p = burnModel:FindFirstChildWhichIsA("BasePart")
                                    if p then burnTargetCF = p.CFrame end
                                end
                            end)

                            if not warpTo(burnTargetCF, "Desert Cellar Door") then return end

                            -- Equip Torch tool
                            pcall(function()
                                local char = LocalPlayer.Character
                                if char then
                                    local torchTool = char:FindFirstChild("Torch") or (LocalPlayer:FindFirstChild("Backpack") and LocalPlayer.Backpack:FindFirstChild("Torch"))
                                    if torchTool then torchTool.Parent = char end
                                end
                            end)

                            -- Touch burn door & wait for door to burn down
                            pcall(function()
                                local burnModel = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Desert") and workspace.Map.Desert:FindFirstChild("Burn")
                                local char = LocalPlayer.Character
                                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                                if burnModel and hrp and firetouchinterest then
                                    for _, part in ipairs(burnModel:GetChildren()) do
                                        if part:IsA("BasePart") then
                                            firetouchinterest(hrp, part, 0)
                                            task.wait(0.05)
                                            firetouchinterest(hrp, part, 1)
                                        end
                                    end
                                end
                            end)
                            task.wait(3.5) -- Wait for door burn animation & unlock

                            -- ── STEP 3: Desert Cellar — grab cup ───────────────────────────────
                            if not isSaberQuestOn then return end
                            debugLog("Step 3/8: Desert cellar cup")
                            
                            local cupTargetCF = CFrame.new(1114, 4, 4366)
                            pcall(function()
                                local cupObj = workspace:FindFirstChild("Cup", true)
                                if cupObj and cupObj:IsA("BasePart") then
                                    cupTargetCF = cupObj.CFrame
                                elseif cupObj then
                                    local p = cupObj:FindFirstChildWhichIsA("BasePart", true)
                                    if p then cupTargetCF = p.CFrame end
                                end
                            end)

                            if not warpTo(cupTargetCF, "Desert Cellar Cup") then return end
                            pcall(function() CommF:InvokeServer("GetCup") end)
                            pcall(function()
                                local cupObj = workspace:FindFirstChild("Cup", true)
                                local char = LocalPlayer.Character
                                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                                if cupObj and hrp then
                                    local touchable = cupObj:IsA("BasePart") and cupObj or cupObj:FindFirstChildWhichIsA("BasePart", true)
                                    if touchable and firetouchinterest then
                                        firetouchinterest(hrp, touchable, 0)
                                        task.wait(0.05)
                                        firetouchinterest(hrp, touchable, 1)
                                    end
                                    local prompt = cupObj:FindFirstChildWhichIsA("ProximityPrompt", true)
                                    if prompt and fireproximityprompt then fireproximityprompt(prompt) end
                                end
                            end)
                            task.wait(1)
                            hasCup = hasQuestItem("Cup")
                        end

                        -- Helper function to equip Cup tool from Backpack
                        local function equipCupTool()
                            pcall(function()
                                local char = LocalPlayer.Character
                                if not char then return end
                                local hum = char:FindFirstChildOfClass("Humanoid")
                                if not hum then return end

                                -- Already holding a cup? done
                                for _, t in ipairs(char:GetChildren()) do
                                    if t:IsA("Tool") and (t.Name:find("Cup") or t.Name:find("cup")) then return end
                                end

                                -- Unequip whatever we're currently holding first
                                local held = char:FindFirstChildOfClass("Tool")
                                if held then
                                    local bp = LocalPlayer:FindFirstChild("Backpack")
                                    if bp then held.Parent = bp end
                                    task.wait(0.1)
                                end

                                -- Find cup in backpack and equip it
                                local bp = LocalPlayer:FindFirstChild("Backpack")
                                if bp then
                                    for _, t in ipairs(bp:GetChildren()) do
                                        if t:IsA("Tool") and (t.Name:find("Cup") or t.Name:find("cup")) then
                                            hum:EquipTool(t)
                                            task.wait(0.3)
                                            return
                                        end
                                    end
                                end
                            end)
                        end

                        -- ── STEP 4: Frozen Village cave — fill cup ─────────────────────────
                        if not (hasFullCup or hasRelic) then
                            if not isSaberQuestOn then return end
                            debugLog("Step 4/8: Traveling to Frozen Cave Icicle Drip")

                            -- Exact icicle drip location in cave
                            local dripCFrame = CFrame.new(1394.9, 37.5, -1321.9)

                            if not warpTo(dripCFrame, "Cave Icicle Drip") then return end

                            -- Automatically equip Cup in hand
                            equipCupTool()
                            task.wait(0.5)

                            debugLog("Filling Cup under icicle drip...")
                            pcall(function() CommF:InvokeServer("FillCup") end)

                            -- Give full 6 seconds for water drop to drip into held cup
                            local fillEnd = tick() + 6.0
                            while isSaberQuestOn and tick() < fillEnd do
                                equipCupTool()
                                local char = LocalPlayer.Character
                                local heldCup = char and (char:FindFirstChild("Cup") or char:FindFirstChild("Full Cup"))
                                if heldCup then
                                    pcall(function() heldCup:Activate() end)
                                end
                                task.wait(0.5)
                            end
                            hasFullCup = hasQuestItem("Full Cup") or hasQuestItem("Cup (Full)")
                        end

                        -- ── STEP 5, 6, 7: Sick Man → Rich Man → Mob Leader → Claim Relic ──
                        if not hasRelic then
                            if not isSaberQuestOn then return end
                            debugLog("Step 5/8: Traveling to Sick Man NPC")

                            -- Exact solid-ground location for Sick Man house (Safely elevated to Y=120 to prevent clipping)
                            local sickManCFrame = CFrame.new(1394, 120, -1298)
                            if not warpTo(sickManCFrame, "Sick Man NPC") then return end
                            task.wait(0.5)
                            pcall(function() CommF:InvokeServer("SickMan") end)
                            task.wait(1)

                            debugLog("Step 5/8: Traveling to Rich Man NPC — Pirate Village")
                            -- Exact solid-ground location for Rich Man at Pirate Village (Elevated to Y=50)
                            local richManCFrame = CFrame.new(676, 50, 1545)
                            if not warpTo(richManCFrame, "Pirate Village Rich Man") then return end
                            task.wait(0.5)
                            pcall(function() CommF:InvokeServer("RichMan") end)
                            task.wait(1)

                            -- ── STEP 6: Mob Leader boss kill ───────────────────────────────────
                            if not isSaberQuestOn then return end
                            debugLog("Step 6/8: Mob Leader arena")
                            if not warpTo(CFrame.new(-2850, 80, 5300), "Mob Island Arena") then return end
                            task.wait(0.5)

                            -- Scan enemies AFTER arriving, not before
                            local mobLeader = findEnemy("Mob Leader")
                            if mobLeader then
                                debugLog("Killing Mob Leader")
                                local killed = killEnemy(mobLeader, 45)
                                if not killed then
                                    debugLog("Mob Leader kill timed out — retrying cycle")
                                    return
                                end
                            else
                                debugLog("Mob Leader not found at arena — retrying cycle")
                                task.wait(3)
                                return
                            end

                            -- ── STEP 7: Rich Man relic claim ───────────────────────────────────
                            if not isSaberQuestOn then return end
                            debugLog("Step 7/8: Relic from Rich Man")
                            if not warpTo(CFrame.new(676, 50, 1545), "Rich Man Relic") then return end
                            pcall(function() CommF:InvokeServer("RichMan", "1") end)
                            task.wait(1)
                        end

                        -- ── STEP 8: Shanks fight ───────────────────────────────────────────
                        if not isSaberQuestOn then return end
                        debugLog("Step 8/8: Opening relic door — Shanks room")
                        if not warpTo(CFrame.new(-1430, 10, -200), "Shanks Secret Room") then return end
                        task.wait(1)

                        -- Open the relic door via CommF
                        pcall(function() CommF:InvokeServer("OpenRelicDoor") end)
                        task.wait(1.5)

                        -- Scan live — Shanks may not be up yet
                        local shanks = findEnemy("Shanks") or findEnemy("Saber Expert")
                        if shanks then
                            debugLog("Shanks found — fighting")
                            local killed = killEnemy(shanks, 90)
                            if killed then
                                debugLog("Shanks defeated. Saber quest complete!")
                                -- Claim saber reward
                                pcall(function() CommF:InvokeServer("ClaimSaber") end)
                                task.wait(2)
                            else
                                debugLog("Shanks kill timed out — retrying cycle")
                            end
                        else
                            debugLog("Shanks not spawned yet — waiting 5s then retrying")
                            task.wait(5)
                        end
                    end)

                    if not ok then
                        debugLog("Error: " .. tostring(err))
                    end
                    task.wait(2)
                end
            end)
        else
            isTraveling = false
            if _G.ENI_TravelTween then
                pcall(function() _G.ENI_TravelTween:Cancel() end)
                _G.ENI_TravelTween = nil
            end
            if saberThread then pcall(function() task.cancel(saberThread) end) saberThread = nil end
            pcall(function()
                local char = LocalPlayer.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    removeTabBV(char.HumanoidRootPart)
                    char.HumanoidRootPart.Velocity = Vector3.zero
                end
            end)
            notifyGUI("Saber Quest", "Saber Quest stopped.", 3)
        end
    end)

    local isPoleQuestOn = false
    local poleThread = nil

    createSliderToggle(questPage, "[1st Sea] ⚡ Auto Pole V1 Quest", false, function(newState)
        isPoleQuestOn = newState
        if isPoleQuestOn then
            ensureBusoHakiActive()
            if _G.ENI_setBusoState then _G.ENI_setBusoState(true) end
            notifyGUI("Pole V1 Quest", "Starting Auto Thunder God Boss Hunter & Auto Buso Haki...", 5)
            poleThread = task.spawn(function()
                local poleState = "" -- track state to avoid notification spam
                local poleTweening = false

                while isPoleQuestOn do
                    pcall(function()
                        ensureBusoHakiActive()
                        local char = LocalPlayer.Character
                        local hrp = char and char:FindFirstChild("HumanoidRootPart")
                        if not hrp then return end

                        local enemies = workspace:FindFirstChild("Enemies") and workspace.Enemies:GetChildren() or {}
                        local thunderGod = nil
                        for _, e in ipairs(enemies) do
                            if (e.Name == "Thunder God" or string.find(e.Name, "Thunder God")) and e:FindFirstChild("HumanoidRootPart") and e:FindFirstChildOfClass("Humanoid") and e.Humanoid.Health > 0 then
                                thunderGod = e
                                break
                            end
                        end

                        if thunderGod then
                            if poleState ~= "fighting" then
                                poleState = "fighting"
                                notifyGUI("Pole V1", "Targeting Thunder God! Attacking...", 4)
                            end
                            local bHrp = thunderGod.HumanoidRootPart
                            local dist = (hrp.Position - bHrp.Position).Magnitude

                            if dist > 150 and not poleTweening then
                                -- Far away — use smooth tween to approach
                                poleTweening = true
                                local bv = getTabBV(hrp)
                                if bv then bv.Velocity = Vector3.zero end

                                local tDist = (bHrp.CFrame.Position + Vector3.new(0, 14, 0) - hrp.Position).Magnitude
                                local tDur = math.clamp(tDist / 350, 0.2, 15)

                                if _G.ENI_TravelTween then pcall(function() _G.ENI_TravelTween:Cancel() end) end
                                local tw = TweenService:Create(hrp, TweenInfo.new(tDur, Enum.EasingStyle.Linear), {CFrame = bHrp.CFrame * CFrame.new(0, 14, 0)})
                                _G.ENI_TravelTween = tw

                                local noclipConn = RunService.Stepped:Connect(function()
                                    if char and isPoleQuestOn then
                                        local b = getTabBV(hrp)
                                        if b then b.Velocity = Vector3.zero end
                                        for _, part in ipairs(char:GetChildren()) do
                                            if part:IsA("BasePart") then part.CanCollide = false end
                                        end
                                    end
                                end)

                                tw:Play()
                                tw.Completed:Wait()
                                pcall(function() noclipConn:Disconnect() end)
                                poleTweening = false
                            else
                                -- Close enough — hover above and attack
                                hrp.CFrame = bHrp.CFrame * CFrame.new(0, 14, 0)
                            end

                            -- Disable hitboxes so boss can't hit back
                            for _, p in ipairs(thunderGod:GetChildren()) do
                                if p:IsA("BasePart") then p.CanTouch = false end
                            end

                            -- Auto equip melee/sword weapon
                            local tool = char:FindFirstChildOfClass("Tool")
                            if not tool or (tool.ToolTip ~= "Sword" and tool.ToolTip ~= "Melee" and tool.Name ~= "Combat") then
                                -- Unequip non-weapon tool
                                if tool then
                                    local bp = LocalPlayer:FindFirstChild("Backpack")
                                    if bp then tool.Parent = bp end
                                end
                                local bp = LocalPlayer:FindFirstChild("Backpack")
                                if bp then
                                    for _, t in ipairs(bp:GetChildren()) do
                                        if t:IsA("Tool") and (t.ToolTip == "Sword" or t.ToolTip == "Melee" or t.Name == "Combat") then
                                            local hum = char:FindFirstChildOfClass("Humanoid")
                                            if hum then hum:EquipTool(t) end
                                            break
                                        end
                                    end
                                end
                            end

                            -- Fire tool attack
                            tool = char:FindFirstChildOfClass("Tool")
                            if tool then pcall(function() tool:Activate() end) end

                            -- Encrypted hit stream for reliable damage
                            pcall(function()
                                if bHrp and thunderGod then
                                    if _G.ENI_PerformFastAttack then
                                        _G.ENI_PerformFastAttack({{thunderGod, bHrp}}, bHrp)
                                    end
                                end
                            end)
                        else
                            if poleState ~= "waiting" then
                                poleState = "waiting"
                                notifyGUI("Pole V1", "Thunder God not spawned. Hovering at Arena...", 4)
                            end
                            -- Travel to arena and wait for spawn
                            local arenaPos = CFrame.new(-7900, 5600, -2250)
                            local aDist = (hrp.Position - arenaPos.Position).Magnitude
                            if aDist > 100 and not poleTweening then
                                poleTweening = true
                                local bv = getTabBV(hrp)
                                if bv then bv.Velocity = Vector3.zero end

                                local tDur = math.clamp(aDist / 350, 0.2, 20)
                                if _G.ENI_TravelTween then pcall(function() _G.ENI_TravelTween:Cancel() end) end
                                local tw = TweenService:Create(hrp, TweenInfo.new(tDur, Enum.EasingStyle.Linear), {CFrame = arenaPos})
                                _G.ENI_TravelTween = tw

                                local noclipConn = RunService.Stepped:Connect(function()
                                    if char and isPoleQuestOn then
                                        local b = getTabBV(hrp)
                                        if b then b.Velocity = Vector3.zero end
                                        for _, part in ipairs(char:GetChildren()) do
                                            if part:IsA("BasePart") then part.CanCollide = false end
                                        end
                                    end
                                end)

                                tw:Play()
                                tw.Completed:Wait()
                                pcall(function() noclipConn:Disconnect() end)
                                poleTweening = false
                            end
                            task.wait(1)
                        end
                    end)
                    task.wait(0.1)
                end
            end)
        else
            if _G.ENI_TravelTween then pcall(function() _G.ENI_TravelTween:Cancel() end) _G.ENI_TravelTween = nil end
            isTraveling = false
            if poleThread then pcall(function() task.cancel(poleThread) end) poleThread = nil end
            notifyGUI("Pole V1", "Pole V1 Automation Stopped.", 3)
        end
    end)

    -- =========================================================================
    -- [2ND SEA] AUTOMATED SPECIAL QUESTS
    -- =========================================================================
    Hub.CreateSection(questPage, "🌊 2nd Sea Special Quests")

    createSliderToggle(questPage, "[2nd Sea] 🍷 Auto Bartilo Quest", false, function(newState)
        if newState then
            notifyGUI("Bartilo Quest", "Starting Bartilo Quest progression...", 4)
            task.spawn(function()
                pcall(function()
                    CommF:InvokeServer("BartiloNPC", "1")
                    task.wait(1)
                    CommF:InvokeServer("BartiloNPC", "2")
                    notifyGUI("Bartilo Quest", "Bartilo Quest initialized! Step 1: Swan Pirates, Step 2: Jeremy, Step 3: Colosseum Code.", 5)
                end)
            end)
        end
    end)

    createSliderToggle(questPage, "[2nd Sea] 🧬 Auto Race V2 Quest", false, function(newState)
        if newState then
            notifyGUI("Race V2", "Searching for Alchemist Flowers (Red, Blue, Yellow)...", 4)
            task.spawn(function()
                pcall(function()
                    CommF:InvokeServer("Alchemist", "1")
                    notifyGUI("Race V2", "Talked to Alchemist! Searching map for flowers...", 4)
                end)
            end)
        end
    end)

    createSliderToggle(questPage, "[2nd Sea] 🏭 Auto Factory Raid", false, function(newState)
        if newState then
            notifyGUI("Factory Raid", "Factory Core Auto-Attack engine enabled!", 4)
        end
    end)

    -- =========================================================================
    -- [3RD SEA] AUTOMATED SPECIAL QUESTS
    -- =========================================================================
    Hub.CreateSection(questPage, "🌊 3rd Sea Special Quests")

    createSliderToggle(questPage, "[3rd Sea] 🧬 Auto Race V3 Quest", false, function(newState)
        if newState then
            notifyGUI("Race V3", "Starting Race V3 Arowana Quest Trial...", 4)
            task.spawn(function()
                pcall(function()
                    CommF:InvokeServer("Wenlocktoad", "1")
                    notifyGUI("Race V3", "Talked to Arowana NPC!", 3)
                end)
            end)
        end
    end)

    createSliderToggle(questPage, "[3rd Sea] 🎸 Auto Soul Guitar Quest", false, function(newState)
        if newState then
            notifyGUI("Soul Guitar", "Checking Haunted Castle Full Moon & Soul Guitar Puzzle...", 4)
            task.spawn(function()
                pcall(function()
                    CommF:InvokeServer("Gravestone", "1")
                    notifyGUI("Soul Guitar", "Interacted with Gravestone!", 3)
                end)
            end)
        end
    end)
end

-- PLAYER PAGE SETUP
do
    Hub.CreateSection(playerPage, "🏃 Player Utilities & Movement")

    local potatoSaved = {}
    createSliderToggle(playerPage, "Potato Mode", false, function(newState)
        pcall(function()
            if newState then
                potatoSaved = { materials = {}, decals = {}, emitters = {} }
                local terrain = workspace:FindFirstChildOfClass("Terrain")
                if terrain then
                    terrain.WaterWaveSize = 0
                    terrain.WaterWaveSpeed = 0
                end
                game:GetService("Lighting").GlobalShadows = false
                for _, v in ipairs(workspace:GetDescendants()) do
                    if v:IsA("BasePart") and not v:IsA("MeshPart") and not v:IsA("Terrain") then
                        potatoSaved.materials[v] = v.Material
                        v.Material = Enum.Material.SmoothPlastic
                    elseif v:IsA("Decal") or v:IsA("Texture") then
                        potatoSaved.decals[v] = v.Transparency
                        v.Transparency = 1
                    elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
                        if v.Enabled then
                            potatoSaved.emitters[v] = true
                            v.Enabled = false
                        end
                    end
                end
            else
                local terrain = workspace:FindFirstChildOfClass("Terrain")
                if terrain then
                    terrain.WaterWaveSize = 0.15
                    terrain.WaterWaveSpeed = 10
                end
                game:GetService("Lighting").GlobalShadows = true
                if potatoSaved.materials then
                    for part, mat in pairs(potatoSaved.materials) do
                        if part and part.Parent then part.Material = mat end
                    end
                end
                if potatoSaved.decals then
                    for decal, trans in pairs(potatoSaved.decals) do
                        if decal and decal.Parent then decal.Transparency = trans end
                    end
                end
                if potatoSaved.emitters then
                    for emitter, _ in pairs(potatoSaved.emitters) do
                        if emitter and emitter.Parent then emitter.Enabled = true end
                    end
                end
                potatoSaved = {}
            end
        end)
        notifyGUI("PERFORMANCE", newState and "Potato Mode Active (Textures OFF)" or "Potato Mode Disabled.", 3)
    end)

    addSectionDivider(playerPage)

    createSliderToggle(playerPage, "Walk on Water", true, function(newState)
        isWaterWalkOn = newState
    end, "WaterWalk")

    createSliderToggle(playerPage, "Infinite Energy", false, function(newState)
        isInfEnergyOn = newState
    end, "InfEnergy")

    addSectionDivider(playerPage)

    local isNoclipOn = false
    local noclipConn = nil
    createSliderToggle(playerPage, "Player Noclip", false, function(newState)
        isNoclipOn = newState
        if isNoclipOn then
            if not noclipConn then
                noclipConn = RunService.Stepped:Connect(function()
                    pcall(function()
                        local char = LocalPlayer.Character
                        if char then
                            for _, p in ipairs(char:GetChildren()) do
                                if p:IsA("BasePart") then p.CanCollide = false end
                            end
                        end
                    end)
                end)
            end
        else
            if noclipConn then noclipConn:Disconnect() noclipConn = nil end
        end
    end)

    local isInfJumpOn = false
    createSliderToggle(playerPage, "Infinite Jump", false, function(newState)
        isInfJumpOn = newState
    end)

    addSectionDivider(playerPage)

    createSliderToggle(playerPage, "Anti-AFK Protection", true, function(newState)
        isAntiAfkOn = newState
        _G.ENI_AntiAfkOn = newState
    end, "AntiAFK")

    createSliderToggle(playerPage, "Floating Stats HUD", false, function(newState)
        isHudOn = newState
        _G.ENI_HudOn = isHudOn
        if _G.ENI_HudFrame then _G.ENI_HudFrame.Visible = isHudOn end
    end)

    _G.ENI_AntiAfkOn = true
    LocalPlayer.Idled:Connect(function()
        if _G.ENI_AntiAfkOn then
            pcall(function()
                local vu = game:GetService("VirtualUser")
                vu:CaptureController()
                vu:ClickButton2(Vector2.new())
            end)
        end
    end)

    game:GetService("UserInputService").JumpRequest:Connect(function()
        if isInfJumpOn then
            pcall(function()
                local char = LocalPlayer.Character
                if char and char:FindFirstChildOfClass("Humanoid") then
                    char:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end)
        end
    end)
end





-- STATS PAGE SETUP
do
    Hub.CreateSection(statsPage, "📊 Auto Stats Allocation")
    
    createSliderToggle(statsPage, "Enable Auto Stats Allocation", false, function(newState)
        isStatsOn = newState
    end, "AutoStats")

    Hub.CreateSlider(statsPage, "Points per Upgrade Step", 1, 100, pointsPerUpgrade or 3, "pts", function(val)
        pointsPerUpgrade = val
    end)
    
    local statTypes = {"Melee", "Defense", "Sword", "Gun", "DemonFruit"}
    for _, sName in ipairs(statTypes) do
        createSliderToggle(statsPage, "Allocate " .. sName, false, function(newState)
            selectedStats[sName] = newState
        end)
    end
end

-- SHOP PAGE SETUP
do
    Hub.CreateSection(shopPage, "🛍️ Blox Fruit Shop & Gacha")
    local selectedSnipeFruit = "Kitsune"
    local allFruits = {
        "Rocket", "Spin", "Blade", "Spring", "Bomb", "Smoke", "Spike", 
        "Flame", "Falcon", "Ice", "Sand", "Dark", "Diamond", "Light", 
        "Rubber", "Barrier", "Magma", "Ghost", "Quake", "Buddha", "Love", 
        "Spider", "Sound", "Phoenix", "Portal", "Rumble", "Pain", "Blizzard", 
        "Gravity", "Mammoth", "T-Rex", "Dough", "Shadow", "Venom", "Control", 
        "Spirit", "Dragon", "Leopard", "Kitsune"
    }

    createSliderToggle(shopPage, "Auto Roll Random Fruit", false, function(newState)
        isAutoRollOn = newState
    end)

    createSliderToggle(shopPage, "Snipe Dealer Fruit", false, function(newState)
        isSnipeOn = newState
    end)

    local fruitList = Hub.CreateList(shopPage, "🎯 Target Snipe Fruit", allFruits, function(fName)
        selectedSnipeFruit = fName
    end, false)
    fruitList:SetSelected(selectedSnipeFruit)
end

-- LIVE DEALER STOCK & BUY SECTION
Hub.CreateButton(shopPage, "🔄 Refresh Dealer Stock", function()
    if refreshDealerStockUI then refreshDealerStockUI() end
    notifyGUI("SHOP", "Refreshed Live Dealer Stock!", 3)
end)

local stockList = Hub.CreateList(shopPage, "🛒 Live Dealer Stock", {}, 200, true)

local function refreshDealerStockUI()
    if not stockList or not stockList.List then return end
    for _, child in ipairs(stockList.List:GetChildren()) do
        if child:IsA("GuiObject") and not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
            child:Destroy()
        end
    end
    stockList.Items = {}
    pcall(function()
        local stock = CommF:InvokeServer("GetFruits")
        if stock and type(stock) == "table" then
            local count = 0
            for _, f in pairs(stock) do
                if f.OnSale then
                    count = count + 1
                    local displayName = string.match(f.Name, "^[^-]+") or f.Name
                    stockList:AddItem(displayName, "$" .. tostring(f.Price or 0), function()
                        pcall(function()
                            CommF:InvokeServer("PurchaseRawFruit", f.Name)
                            notifyGUI("SHOP", "Purchased " .. displayName .. "!", 4)
                        end)
                    end, "Buy", function()
                        pcall(function()
                            CommF:InvokeServer("PurchaseRawFruit", f.Name)
                            notifyGUI("SHOP", "Purchased " .. displayName .. "!", 4)
                        end)
                    end)
                end
            end
            if count == 0 then
                stockList:AddItem("No fruits currently on sale", "Check back soon", nil)
            end
            if stockList.UpdateHeight then stockList.UpdateHeight(false) end
        end
    end)
end

task.delay(1, function()
    refreshDealerStockUI()
end)

-- REUSABLE SHOP CATALOG BUILDER
local function buildShopCatalogSection(parentPage, titleText, itemList)
    local catList = Hub.CreateList(parentPage, titleText, {}, 180, false)
    for _, item in ipairs(itemList) do
        catList:AddItem(item.Name, item.Price or "$0", function()
            pcall(function()
                CommF:InvokeServer(unpack(item.Args))
                notifyGUI("SHOP", "Purchased " .. item.Name .. "!", 4)
            end)
        end, "Buy", function()
            pcall(function()
                CommF:InvokeServer(unpack(item.Args))
                notifyGUI("SHOP", "Purchased " .. item.Name .. "!", 4)
            end)
        end)
    end
    return catList
end

buildShopCatalogSection(shopPage, "✨ Abilities & Haki Shop", {
    {Name = "Buso Haki (Aura)", Price = "$25,000", Args = {"BuyHaki", "Buso"}},
    {Name = "Geppo (Skyjump)", Price = "$10,000", Args = {"BuyHaki", "Geppo"}},
    {Name = "Sori (Flash Step)", Price = "$100,000", Args = {"BuyHaki", "Soru"}},
    {Name = "Observation Haki (Ken)", Price = "$750,000", Args = {"KenHaki", "Buy"}},
    {Name = "Observation V2", Price = "$5,000,000", Args = {"KenHaki", "BuyV2"}}
})

buildShopCatalogSection(shopPage, "🥊 Fighting Styles Shop", {
    {Name = "Black Leg (Dark Step)", Price = "$150,000", Args = {"BuyBlackLeg"}},
    {Name = "Electro", Price = "$500,000", Args = {"BuyElectro"}},
    {Name = "Fishman Karate", Price = "$750,000", Args = {"BuyFishmanKarate"}},
    {Name = "Dragon Claw", Price = "1,500 Frags", Args = {"BlackbeardReward", "DragonClaw", "1"}},
    {Name = "Superhuman", Price = "$3,000,000", Args = {"BuySuperhuman"}},
    {Name = "Death Step", Price = "$2.5M + 5k Frags", Args = {"BuyDeathStep"}},
    {Name = "Sharkman Karate", Price = "$2.5M + 5k Frags", Args = {"BuySharkmanKarate"}},
    {Name = "Electric Claw", Price = "$3M + 5k Frags", Args = {"BuyElectricClaw"}},
    {Name = "Godhuman", Price = "$5M + 5k Frags", Args = {"BuyGodhuman"}}
})

buildShopCatalogSection(shopPage, "⚔️ Swords & Weapons Shop", {
    {Name = "Katana", Price = "$5,000", Args = {"BuyItem", "Katana"}},
    {Name = "Cutlass", Price = "$5,000", Args = {"BuyItem", "Cutlass"}},
    {Name = "Dual Katana", Price = "$12,000", Args = {"BuyItem", "Dual Katana"}},
    {Name = "Iron Mace", Price = "$25,000", Args = {"BuyItem", "Iron Mace"}},
    {Name = "Triple Katana", Price = "$60,000", Args = {"BuyItem", "Triple Katana"}},
    {Name = "Pipe", Price = "$100,000", Args = {"BuyItem", "Pipe"}},
    {Name = "Dual Headed Blade", Price = "$400,000", Args = {"BuyItem", "Dual Headed Blade"}},
    {Name = "Soul Cane", Price = "$750,000", Args = {"BuyItem", "Soul Cane"}},
    {Name = "Bizen", Price = "$1,000,000", Args = {"BuyItem", "Bizen"}}
})

buildShopCatalogSection(shopPage, "🔫 Guns & Ranged Weapons Shop", {
    {Name = "Slingshot", Price = "$5,000", Args = {"BuyItem", "Slingshot"}},
    {Name = "Musket", Price = "$8,000", Args = {"BuyItem", "Musket"}},
    {Name = "Flintlock", Price = "$10,500", Args = {"BuyItem", "Flintlock"}},
    {Name = "Refined Slingshot", Price = "$30,000", Args = {"BuyItem", "Refined Slingshot"}},
    {Name = "Cannon", Price = "$100,000", Args = {"BuyItem", "Cannon"}},
    {Name = "Kabucha", Price = "1,500 Frags", Args = {"BlackbeardReward", "Slingshot", "1"}}
})

-- GLOBAL BACKGROUND LOOP (Infinite Energy, Fruit Snipe & Auto Chest)
if _G.ENI_GlobalLoop then pcall(function() _G.ENI_GlobalLoop:Disconnect() end) end
local lastSnipeTime = 0
local isChestFarming = false

-- ROBUST SAFE CHEST FARMING ENGINE
local activeChestTarget = nil
local chestNoclipConn = nil

local function enableChestNoclip()
    if chestNoclipConn then return end
    chestNoclipConn = RunService.Stepped:Connect(function()
        if isAutoChestOn then
            pcall(function()
                local char = LocalPlayer.Character
                if char then
                    for _, part in ipairs(char:GetChildren()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end
                end
            end)
        end
    end)
end

local function disableChestNoclip()
    if chestNoclipConn then
        chestNoclipConn:Disconnect()
        chestNoclipConn = nil
    end
    pcall(function()
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetChildren()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end)
end

stopChestFarm = function()
    disableChestNoclip()
    if _G.ENI_ChestTween then
        pcall(function() _G.ENI_ChestTween:Cancel() end)
        _G.ENI_ChestTween = nil
    end
    activeChestTarget = nil
    pcall(function()
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            removeTabBV(char.HumanoidRootPart)
            char.HumanoidRootPart.Velocity = Vector3.zero
        end
    end)
    farmStatusLabel.Text = "Status: Auto Chest OFF. Grounded."
end

local chestThread = nil
startChestFarm = function()
    if chestThread then return end
    enableChestNoclip()
    
    chestThread = task.spawn(function()
        while isAutoChestOn do
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            
            if hrp and not isTraveling and not isFarmOn then
                local chests = {}
                pcall(function()
                    local searchRoot = workspace:FindFirstChild("Map") or workspace
                    for _, obj in ipairs(searchRoot:GetDescendants()) do
                        if obj:IsA("BasePart") and (string.find(obj.Name, "Chest") or (obj.Parent and string.find(obj.Parent.Name, "Chest"))) then
                            if obj:FindFirstChildOfClass("TouchTransmitter") or obj:FindFirstChild("TouchInterest") then
                                table.insert(chests, obj)
                            end
                        end
                    end
                end)

                if #chests > 0 then
                    table.sort(chests, function(a, b)
                        return (hrp.Position - a.Position).Magnitude < (hrp.Position - b.Position).Magnitude
                    end)

                    local targetChest = chests[1]
                    if targetChest and targetChest.Parent then
                        activeChestTarget = targetChest
                        farmStatusLabel.Text = "Status: Farming Chest (" .. #chests .. " remaining)"
                        
                        local bv = getTabBV(hrp)
                        if bv then bv.Velocity = Vector3.zero end
                        
                        local chestPos = targetChest.Position
                        local speed = 280
                        local chestCollected = false
                        local startTime = tick()
                        local lastHrpPos = hrp.Position
                        local stuckTime = tick()

                        -- Continuous Tween loop until chest collected or timed out
                        if _G.ENI_ChestTween then pcall(function() _G.ENI_ChestTween:Cancel() end) _G.ENI_ChestTween = nil end
                        while isAutoChestOn and targetChest and targetChest.Parent and (targetChest:FindFirstChildOfClass("TouchTransmitter") or targetChest:FindFirstChild("TouchInterest")) do
                            if not char or not char:FindFirstChild("HumanoidRootPart") then break end
                            
                            local currHrp = char.HumanoidRootPart
                            local dist = (currHrp.Position - chestPos).Magnitude

                            if dist <= 6 then
                                if _G.ENI_ChestTween then pcall(function() _G.ENI_ChestTween:Cancel() end) end
                                currHrp.CFrame = CFrame.new(chestPos)
                                if firetouchinterest then
                                    firetouchinterest(currHrp, targetChest, 0)
                                    task.wait(0.05)
                                    firetouchinterest(currHrp, targetChest, 1)
                                end
                                task.wait(0.15)
                                chestCollected = true
                                break
                            end

                            -- Stuck Recovery Check: if position hasn't changed for > 2 seconds, force teleport slightly closer
                            if (currHrp.Position - lastHrpPos).Magnitude < 2 then
                                if tick() - stuckTime > 2 then
                                    currHrp.CFrame = currHrp.CFrame + (chestPos - currHrp.Position).Unit * 15
                                    stuckTime = tick()
                                    if _G.ENI_ChestTween then pcall(function() _G.ENI_ChestTween:Cancel() end) _G.ENI_ChestTween = nil end
                                end
                            else
                                lastHrpPos = currHrp.Position
                                stuckTime = tick()
                            end

                            if not _G.ENI_ChestTween or _G.ENI_ChestTween.PlaybackState ~= Enum.PlaybackState.Playing then
                                local tDur = dist / speed
                                _G.ENI_ChestTween = TweenService:Create(currHrp, TweenInfo.new(tDur, Enum.EasingStyle.Linear), {CFrame = CFrame.new(chestPos)})
                                _G.ENI_ChestTween:Play()
                            end
                            
                            if tick() - startTime > 10 then break end
                            task.wait(0.1)
                        end
                        if _G.ENI_ChestTween then pcall(function() _G.ENI_ChestTween:Cancel() end) _G.ENI_ChestTween = nil end
                    end
                else
                    farmStatusLabel.Text = "Status: No chests currently available."
                    task.wait(1.5)
                end
            else
                task.wait(0.5)
            end
            task.wait(0.1)
        end
        
        stopChestFarm()
        chestThread = nil
    end)
end

-- GLOBAL BACKGROUND LOOP (Infinite Energy, Fruit Snipe & Live Stats Refresh)
if _G.ENI_GlobalLoop then pcall(function() _G.ENI_GlobalLoop:Disconnect() end) end
local lastSnipeTime = 0
local lastStatsUpdate = 0

_G.ENI_GlobalLoop = RunService.Heartbeat:Connect(function()
    if tick() - lastStatsUpdate > 0.5 then
        lastStatsUpdate = tick()
        pcall(function()
            local ping = 0
            local stats = game:GetService("Stats")
            if stats and stats:FindFirstChild("Network") and stats.Network:FindFirstChild("ServerStatsItem") and stats.Network.ServerStatsItem:FindFirstChild("Data Ping") then
                ping = math.floor(stats.Network.ServerStatsItem["Data Ping"]:GetValue())
            end
            local fps = math.floor(workspace:GetRealPhysicsFPS())
            local level = getPlayerLevel()
            local playerNum = #Players:GetPlayers()

            if fpsPingLabel then fpsPingLabel.Text = "FPS: " .. fps .. " | Ping: " .. ping .. "ms" end
            if playerStatsLabel then playerStatsLabel.Text = "Lvl: " .. level .. " | Players: " .. playerNum end
            if weaponStatLabel then weaponStatLabel.Text = "Weapon: " .. selectedWeaponType end

            -- RGB Rainbow Animated Glow Engine
            if _G.ENI_RgbGlowOn then
                local hue = (tick() * 0.4) % 1
                local rgbColor = Color3.fromHSV(hue, 0.85, 1)
                setThemeColor(rgbColor)
            end

            -- Live Floating HUD Data Refresh
            if _G.ENI_HudOn and _G.ENI_HudContent then
                pcall(function()
                    local mem = math.floor(stats:GetTotalMemoryUsageMb())
                    local lighting = game:GetService("Lighting")
                    local sky = lighting and (lighting:FindFirstChildOfClass("Sky") or lighting:FindFirstChild("Sky"))
                    local clockTime = lighting and lighting.ClockTime or 12
                    local isNight = (clockTime >= 18 or clockTime <= 5)
                    local moonPhase = lighting and lighting:GetAttribute("MoonPhase") or 0
                    local isFullMoon = (moonPhase == 5) or (lighting and lighting:GetAttribute("IsFullMoon") == true) or (sky and sky.MoonTextureId and (sky.MoonTextureId:find("9709149468") or sky.MoonTextureId:find("9709149025")))
                    
                    local moonStr = "☀️ Day Time"
                    if isNight then
                        if isFullMoon then
                            moonStr = "🌕 Full Moon!"
                        else
                            moonStr = string.format("🌙 Night Time (%d/5)", moonPhase)
                        end
                    end
                    
                    local fruitCount = 0
                    for _, obj in ipairs(workspace:GetChildren()) do
                        if obj:IsA("Tool") and string.find(string.lower(obj.Name), "fruit") then 
                            fruitCount = fruitCount + 1 
                        end
                    end

                    local data = LocalPlayer:FindFirstChild("Data")
                    local beli = data and data:FindFirstChild("Beli") and data.Beli.Value or 0
                    local frags = data and data:FindFirstChild("Fragments") and data.Fragments.Value or 0

                    _G.ENI_HudContent.Text = string.format("⚡ FPS: %d | Ping: %dms | RAM: %dMB\n%s\n⭐ Level: %d | 💵 $%s | 🍇 %s\n🍎 Fruits: %d | 👥 Players: %d/12\n⌛ Hub Uptime: %ds",
                        fps, ping, mem, moonStr, level, tostring(beli), tostring(frags), fruitCount, playerNum, math.floor(workspace.DistributedGameTime)
                    )
                end)
            end
        end)
    end

    if isInfEnergyOn then
        pcall(function()
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("Energy") then
                char.Energy.Value = 99999
            end
        end)
    end
    
    if isSnipeOn and tick() - lastSnipeTime > 20 then
        lastSnipeTime = tick()
        task.spawn(function()
            pcall(function()
                local Rem = ReplicatedStorage:WaitForChild("Remotes")
                local Comm = Rem:WaitForChild("CommF_")
                local stock = Comm:InvokeServer("GetFruits")
                if stock and type(stock) == "table" then
                    local targetList = {"Dragon", "Kitsune", "Leopard"}
                    if selectedSnipeFruit and selectedSnipeFruit ~= "" then
                        table.insert(targetList, selectedSnipeFruit)
                    end
                    for _, f in pairs(stock) do
                        if f.OnSale then
                            for _, targetName in ipairs(targetList) do
                                if string.find(string.lower(f.Name), string.lower(targetName)) then
                                    local res = Comm:InvokeServer("PurchaseRawFruit", f.Name)
                                    if res then
                                        notifyGUI("Fruit Sniper", "🎉 Sniped Mythic Fruit: " .. f.Name .. "!", 8)
                                    end
                                    break
                                end
                            end
                        end
                    end
                end
            end)
        end)
    end
end)

-- ROBUST MULTI-LAYER FAST ATTACK ENGINE (Blox Fruits Net / CombatFramework / Remotes)
if _G.ENI_FastHitThread then 
    pcall(function() task.cancel(_G.ENI_FastHitThread) end)
    _G.ENI_FastHitThread = nil
end
if _G.ENI_FastHitLoop then pcall(function() _G.ENI_FastHitLoop:Disconnect() end) end
if _G.ENI_InputBeganConn then pcall(function() _G.ENI_InputBeganConn:Disconnect() end) end
if _G.ENI_InputEndedConn then pcall(function() _G.ENI_InputEndedConn:Disconnect() end) end

-- Attempt to retrieve CombatFramework and Net module safely
pcall(function()
    _G.ENI_CombatFramework = require(LocalPlayer.PlayerScripts:WaitForChild("CombatFramework", 2))
end)
pcall(function()
    _G.ENI_NetModule = require(ReplicatedStorage.Modules:WaitForChild("Net", 2))
    _G.ENI_WrappedAtk = _G.ENI_NetModule:RemoteEvent("RegisterAttack")
    _G.ENI_WrappedHit = _G.ENI_NetModule:RemoteEvent("RegisterHit")
end)

_G.ENI_LastHitTime = 0
_G.ENI_IsManualAttacking = false

-- Global performFastAttack function callable anywhere (Auto Farm, Bosses, Raids, Fast Attack)
_G.ENI_PerformFastAttack = function(nearbyHits, primaryPart)
    if not nearbyHits or #nearbyHits == 0 then return end
    primaryPart = primaryPart or (nearbyHits[1] and nearbyHits[1][2]) or (nearbyHits[1] and (nearbyHits[1][1]:FindFirstChild("Head") or nearbyHits[1][1]:FindFirstChild("HumanoidRootPart")))
    if not primaryPart then return end

    -- 1. Net Module (Wrapped Remote Events)
    pcall(function()
        if not _G.ENI_WrappedAtk or not _G.ENI_WrappedHit then
            local netM = require(ReplicatedStorage.Modules.Net)
            _G.ENI_WrappedAtk = netM:RemoteEvent("RegisterAttack")
            _G.ENI_WrappedHit = netM:RemoteEvent("RegisterHit")
        end
        if _G.ENI_WrappedAtk then
            if typeof(_G.ENI_WrappedAtk) == "Instance" then
                _G.ENI_WrappedAtk:FireServer(0)
            elseif type(_G.ENI_WrappedAtk) == "table" and _G.ENI_WrappedAtk.FireServer then
                _G.ENI_WrappedAtk:FireServer(0)
            end
        end
        if _G.ENI_WrappedHit then
            if typeof(_G.ENI_WrappedHit) == "Instance" then
                _G.ENI_WrappedHit:FireServer(primaryPart, nearbyHits)
            elseif type(_G.ENI_WrappedHit) == "table" and _G.ENI_WrappedHit.FireServer then
                _G.ENI_WrappedHit:FireServer(primaryPart, nearbyHits)
            end
        end
    end)

    -- 2. Direct RE child instances fallback
    pcall(function()
        local netFolder = ReplicatedStorage:FindFirstChild("Modules") and ReplicatedStorage.Modules:FindFirstChild("Net")
        if netFolder then
            local rAtk = netFolder:FindFirstChild("RE/RegisterAttack") or netFolder:FindFirstChild("RegisterAttack")
            local rHit = netFolder:FindFirstChild("RE/RegisterHit") or netFolder:FindFirstChild("RegisterHit")
            if rAtk then rAtk:FireServer(0) end
            if rHit then rHit:FireServer(primaryPart, nearbyHits) end
        end
    end)

    -- 3. CommE / Remotes fallback
    pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        local commE = remotes and remotes:FindFirstChild("CommE")
        if commE then
            commE:FireServer("RegisterAttack", 0)
            commE:FireServer("RegisterHit", primaryPart, nearbyHits)
        end
    end)

    -- 4. CombatFramework controller bypass
    pcall(function()
        if _G.ENI_CombatFramework and _G.ENI_CombatFramework.activeController then
            local ac = _G.ENI_CombatFramework.activeController
            ac.timeToNextAttack = 0
            ac.attacking = false
            ac.blocking = false
            if ac.hitboxMagnitude and ac.hitboxMagnitude < 60 then
                ac.hitboxMagnitude = 60
            end
        end
    end)
end

-- Fast Attack Input detection (Mouse click, Touch screen on mobile, Tool activation)
_G.ENI_InputBeganConn = UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        _G.ENI_IsManualAttacking = true
    end
end)

_G.ENI_InputEndedConn = UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        _G.ENI_IsManualAttacking = false
    end
end)

local hookedTools = {}
local function hookToolFastAttack(tool)
    if not tool or not tool:IsA("Tool") then return end
    if hookedTools[tool] then return end
    hookedTools[tool] = true

    tool.Activated:Connect(function()
        if not isAuraHitOn then return end
        task.spawn(function()
            local char = LocalPlayer.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then return end
            local hrp = char.HumanoidRootPart
            local hits = {}
            local primaryHRP = nil
            
            if selectedFastAttackTarget == "NPCs" or selectedFastAttackTarget == "Everyone" then
                local enemies = workspace:FindFirstChild("Enemies") and workspace.Enemies:GetChildren() or {}
                for i = 1, #enemies do
                    local mob = enemies[i]
                    local mHrp = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChild("Head")
                    local mHum = mob:FindFirstChildOfClass("Humanoid")
                    if mHrp and mHum and mHum.Health > 0 and (mHrp.Position - hrp.Position).Magnitude <= 60 then
                        if not primaryHRP then primaryHRP = mHrp end
                        table.insert(hits, {mob, mHrp})
                    end
                end
            end
            if selectedFastAttackTarget == "Players" or selectedFastAttackTarget == "Everyone" then
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and plr.Character:FindFirstChildOfClass("Humanoid") and plr.Character.Humanoid.Health > 0 then
                        local pHrp = plr.Character.HumanoidRootPart
                        if (pHrp.Position - hrp.Position).Magnitude <= 60 then
                            if not primaryHRP then primaryHRP = pHrp end
                            table.insert(hits, {plr.Character, pHrp})
                        end
                    end
                end
            end
            if primaryHRP and #hits > 0 then
                _G.ENI_PerformFastAttack(hits, primaryHRP)
            end
        end)
    end)
end

if LocalPlayer.Character then
    for _, child in ipairs(LocalPlayer.Character:GetChildren()) do
        if child:IsA("Tool") then hookToolFastAttack(child) end
    end
    LocalPlayer.Character.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then hookToolFastAttack(child) end
    end)
end
LocalPlayer.CharacterAdded:Connect(function(newChar)
    newChar.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then hookToolFastAttack(child) end
    end)
end)

-- CALIBRATED FAST ATTACK HEARTBEAT STREAM
_G.ENI_FastHitLoop = RunService.Heartbeat:Connect(function()
    pcall(function()
        if not isAuraHitOn then return end

        local isClicking = _G.ENI_IsManualAttacking or UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
        local shouldAttack = isFarmOn or isClicking
        if not shouldAttack then return end

        local now = tick()
        if now - _G.ENI_LastHitTime < 0.08 then return end
        _G.ENI_LastHitTime = now

        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return end
        local hrp = char.HumanoidRootPart

        local tool = char:FindFirstChildOfClass("Tool")
        if not tool then return end

        local nearbyHits = {}
        local primaryHRP = nil

        if selectedFastAttackTarget == "NPCs" or selectedFastAttackTarget == "Everyone" then
            local enemies = workspace:FindFirstChild("Enemies") and workspace.Enemies:GetChildren() or {}
            for i = 1, #enemies do
                local mob = enemies[i]
                local mHrp = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChild("Head")
                local mHum = mob:FindFirstChildOfClass("Humanoid")
                if mHrp and mHum and mHum.Health > 0 then
                    local dist = (mHrp.Position - hrp.Position).Magnitude
                    if dist <= 60 then
                        if not primaryHRP then primaryHRP = mHrp end
                        table.insert(nearbyHits, {mob, mHrp})
                    end
                end
            end
        end

        if selectedFastAttackTarget == "Players" or selectedFastAttackTarget == "Everyone" then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and plr.Character:FindFirstChildOfClass("Humanoid") then
                    if plr.Character.Humanoid.Health > 0 then
                        local pHrp = plr.Character.HumanoidRootPart
                        local dist = (pHrp.Position - hrp.Position).Magnitude
                        if dist <= 60 then
                            if not primaryHRP then primaryHRP = pHrp end
                            table.insert(nearbyHits, {plr.Character, pHrp})
                        end
                    end
                end
            end
        end

        if primaryHRP and #nearbyHits > 0 then
            _G.ENI_PerformFastAttack(nearbyHits, primaryHRP)
        end
    end)
end)

-- TRAVEL PAGE SETUP
local travelStatusLabel = Instance.new("TextLabel")
travelStatusLabel.Size = UDim2.new(0.98, 0, 0, 24)
travelStatusLabel.BackgroundTransparency = 1
travelStatusLabel.Text = "Status: Idle"
travelStatusLabel.TextColor3 = Color3.fromRGB(0, 230, 255)
travelStatusLabel.Font = Enum.Font.GothamBold
travelStatusLabel.TextSize = 12
travelStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
pcall(function() travelStatusLabel.Parent = travelPage end)
registerThemeText(travelStatusLabel)

-- GLOBAL CANCEL TWEEN HELPER
local function restoreCharacterPhysics()
    pcall(function()
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.PlatformStand = false
                hum.AutoRotate = true
            end
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then
                    if p.Name == "HumanoidRootPart" then
                        p.CanCollide = false
                    else
                        p.CanCollide = true
                    end
                end
            end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                removeTabBV(hrp)
                hrp.Velocity = Vector3.zero
                if hrp:IsA("BasePart") then
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                end
            end
        end
    end)
end

_G.ENI_CancelTween = function()
    isTraveling = false
    if _G.ENI_TravelTween then
        pcall(function() _G.ENI_TravelTween:Cancel() end)
        _G.ENI_TravelTween = nil
    end
    _G.ENI_TravelTweenID = nil
    restoreCharacterPhysics()
    if travelStatusLabel then
        travelStatusLabel.Text = "Status: Travel Canceled. Idle."
    end
end

do
    local travelButtons = {}
    local activeTravelIsland = nil

    -- Detect current Sea using PlaceId & Workspace Fallback
    local pId = game.PlaceId
    local isSea1 = (pId == 2753915549)
    local isSea2 = (pId == 4442272183)
    local isSea3 = (pId == 7449423635)

    if not isSea1 and not isSea2 and not isSea3 then
        if workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Cafe") then
            isSea2 = true
        elseif workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Mansion") then
            isSea3 = true
        else
            isSea1 = true
        end
    end

    local islands = {}
    local seaTitle = "1st Sea"

    if isSea2 then
        seaTitle = "2nd Sea"
        islands = {
            {Name = "Kingdom of Rose (Cafe) [Lv. 700]", CFrame = CFrame.new(-380, 73, 300)},
            {Name = "Green Zone [Lv. 875]", CFrame = CFrame.new(-2400, 73, -3100)},
            {Name = "Graveyard Island [Lv. 950]", CFrame = CFrame.new(1350, 87, -1300)},
            {Name = "Snow Mountain [Lv. 1000]", CFrame = CFrame.new(-2200, 73, -4400)},
            {Name = "Hot & Cold [Lv. 1100]", CFrame = CFrame.new(-6000, 15, -4800)},
            {Name = "Cursed Ship [Lv. 1250]", CFrame = CFrame.new(900, 130, 32800)},
            {Name = "Ice Castle [Lv. 1350]", CFrame = CFrame.new(5800, 28, -6200)},
            {Name = "Forgotten Island [Lv. 1425]", CFrame = CFrame.new(-3000, 10, -9800)}
        }
    elseif isSea3 then
        seaTitle = "3rd Sea"
        islands = {
            {Name = "Port Town [Lv. 1500]", CFrame = CFrame.new(-2900, 15, 5300)},
            {Name = "Hydra Island [Lv. 1575]", CFrame = CFrame.new(5700, 600, 200)},
            {Name = "Great Tree [Lv. 1700]", CFrame = CFrame.new(2250, 15, -7100)},
            {Name = "Castle on the Sea [Lv. 1775]", CFrame = CFrame.new(-5000, 300, -3000)},
            {Name = "Floating Turtle [Lv. 1875]", CFrame = CFrame.new(-13200, 330, -7900)},
            {Name = "Haunted Castle [Lv. 1975]", CFrame = CFrame.new(-9500, 140, 5500)},
            {Name = "Sea of Treats [Lv. 2075]", CFrame = CFrame.new(600, 25, -12400)},
            {Name = "Tiki Outpost [Lv. 2450]", CFrame = CFrame.new(-16200, 10, 400)}
        }
    else
        seaTitle = "1st Sea"
        islands = {
            {Name = "Starter Island [Lv. 1]", CFrame = CFrame.new(1050, 16, 1400)},
            {Name = "Jungle [Lv. 15]", CFrame = CFrame.new(-1240, 6, -500)},
            {Name = "Pirate Village [Lv. 30]", CFrame = CFrame.new(-1150, 15, 4300)},
            {Name = "Desert [Lv. 60]", CFrame = CFrame.new(900, 6, 4400)},
            {Name = "Snow Village [Lv. 90]", CFrame = CFrame.new(1300, 87, -1300)},
            {Name = "Marine Fortress [Lv. 120]", CFrame = CFrame.new(-4900, 20, 4300)},
            {Name = "Skylands (Lower) [Lv. 150]", CFrame = CFrame.new(-4800, 715, -2600)},
            {Name = "Skylands (Upper) [Lv. 450]", CFrame = CFrame.new(-7700, 5600, -1450)},
            {Name = "Colosseum [Lv. 225]", CFrame = CFrame.new(-1300, 8, -3300)},
            {Name = "Prison [Lv. 190]", CFrame = CFrame.new(5300, 4, 700)},
            {Name = "Magma Village [Lv. 300]", CFrame = CFrame.new(-5400, 15, 8600)},
            {Name = "Fishman Island [Lv. 375]", CFrame = CFrame.new(61000, 18, 1500)},
            {Name = "Fountain City [Lv. 625]", CFrame = CFrame.new(5600, 38, 4800)}
        }
    end

    -- 2. Clean Island Teleports List (Filtered for Current Sea)
    local travelList = Hub.CreateList(travelPage, "🗺️ Island Teleports (" .. seaTitle .. ")", {}, 220, true)
    for i, island in ipairs(islands) do
        travelList:AddItem(island.Name, "Click to start flight", function()
            if activeTravelIsland == island.Name then
                _G.ENI_CancelTween()
                activeTravelIsland = nil
                travelStatusLabel.Text = "Status: Idle"
            else
                activeTravelIsland = island.Name
                if _G.ENI_setFarmState then _G.ENI_setFarmState(false) end
                if _G.ENI_setAutoBossState then _G.ENI_setAutoBossState(false) end
                travelStatusLabel.Text = "Status: Traveling to " .. island.Name .. "..."
                safeTweenToIsland(island.CFrame + Vector3.new(0, 15, 0), function()
                    if activeTravelIsland == island.Name then
                        activeTravelIsland = nil
                        travelStatusLabel.Text = "Status: Arrived at " .. island.Name
                    end
                end)
            end
        end, "Teleport", function()
            activeTravelIsland = island.Name
            if _G.ENI_setFarmState then _G.ENI_setFarmState(false) end
            if _G.ENI_setAutoBossState then _G.ENI_setAutoBossState(false) end
            travelStatusLabel.Text = "Status: Traveling to " .. island.Name .. "..."
            safeTweenToIsland(island.CFrame + Vector3.new(0, 15, 0), function()
                if activeTravelIsland == island.Name then
                    activeTravelIsland = nil
                    travelStatusLabel.Text = "Status: Arrived at " .. island.Name
                end
            end)
        end)
    end
end

-- AUTO STATS CONFIGURATION
local selectedStats = {Melee = true, Defense = true, Sword = false, Gun = false, DemonFruit = false}
local pointsPerUpgrade = 1
local isStatsOn = false

-- AUTO BOSS DATA & UI (FILTERED BY CURRENT SEA WITH LIVE READY/DEAD STATUS)
do
    local pId = game.PlaceId
    local isSea1 = (pId == 2753915549)
    local isSea2 = (pId == 4442272183)
    local isSea3 = (pId == 7449423635)

    if not isSea1 and not isSea2 and not isSea3 then
        if workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Cafe") then
            isSea2 = true
        elseif workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Mansion") then
            isSea3 = true
        else
            isSea1 = true
        end
    end

    local allBossData = {
        Sea1 = {
            {ExactName = "Gorilla King", Display = "Gorilla King [Lv. 25]", IslandCFrame = CFrame.new(-1120, 6, -500), RespawnTime = 120, QuestName = "JungleQuest", QuestLevel = 3},
            {ExactName = "Bobby", Display = "Bobby [Lv. 55]", IslandCFrame = CFrame.new(-1150, 15, 4300), RespawnTime = 180, QuestName = "BuggyQuest1", QuestLevel = 3},
            {ExactName = "Yeti", Display = "Yeti [Lv. 110]", IslandCFrame = CFrame.new(1200, 106, -1500), RespawnTime = 300, QuestName = "SnowQuest", QuestLevel = 3},
            {ExactName = "Vice Admiral", Display = "Vice Admiral [Lv. 130]", IslandCFrame = CFrame.new(-4800, 20, 4300), RespawnTime = 600, QuestName = "MarineQuest2", QuestLevel = 2},
            {ExactName = "Warden", Display = "Warden [Lv. 175]", IslandCFrame = CFrame.new(5300, 4, 700), RespawnTime = 300, QuestName = "ImpelQuest", QuestLevel = 1},
            {ExactName = "Chief Warden", Display = "Chief Warden [Lv. 200]", IslandCFrame = CFrame.new(5300, 4, 700), RespawnTime = 300, QuestName = "ImpelQuest", QuestLevel = 2},
            {ExactName = "Swan", Display = "Swan [Lv. 225]", IslandCFrame = CFrame.new(5300, 4, 700), RespawnTime = 1800, QuestName = "ImpelQuest", QuestLevel = 3},
            {ExactName = "Saber Expert", Display = "Saber Expert [Lv. 200]", IslandCFrame = CFrame.new(-1400, 30, 200), RespawnTime = 1800},
            {ExactName = "Magma Admiral", Display = "Magma Admiral [Lv. 350]", IslandCFrame = CFrame.new(-5400, 15, 8600), RespawnTime = 1200, QuestName = "MagmaQuest", QuestLevel = 3},
            {ExactName = "Fishman Lord", Display = "Fishman Lord [Lv. 425]", IslandCFrame = CFrame.new(61000, 18, 1500), RespawnTime = 1200, QuestName = "FishmanQuest", QuestLevel = 2},
            {ExactName = "Wysper", Display = "Wysper [Lv. 500]", IslandCFrame = CFrame.new(-7900, 5550, -320), RespawnTime = 1200, QuestName = "SkyExp2Quest", QuestLevel = 2},
            {ExactName = "Thunder God", Display = "Thunder God [Lv. 575]", IslandCFrame = CFrame.new(-7700, 5600, -2300), RespawnTime = 1200, QuestName = "SkyExp2Quest", QuestLevel = 3},
            {ExactName = "Cyborg", Display = "Cyborg [Lv. 675]", IslandCFrame = CFrame.new(6100, 10, 4000), RespawnTime = 1800, QuestName = "FountainQuest", QuestLevel = 2}
        },
        Sea2 = {
            {ExactName = "Diamond", Display = "Diamond [Lv. 750]", IslandCFrame = CFrame.new(-1550, 195, -200), RespawnTime = 1200, QuestName = "Area1Quest", QuestLevel = 3},
            {ExactName = "Jeremy", Display = "Jeremy [Lv. 850]", IslandCFrame = CFrame.new(2100, 448, 700), RespawnTime = 1200, QuestName = "Area2Quest", QuestLevel = 3},
            {ExactName = "Fajita", Display = "Fajita [Lv. 925]", IslandCFrame = CFrame.new(-2100, 73, -3200), RespawnTime = 1200, QuestName = "MarineQuest3", QuestLevel = 3},
            {ExactName = "Don Swan", Display = "Don Swan [Lv. 1000]", IslandCFrame = CFrame.new(2290, 15, 800), RespawnTime = 1800, QuestName = "Area3Quest", QuestLevel = 3},
            {ExactName = "Smoke Admiral", Display = "Smoke Admiral [Lv. 1150]", IslandCFrame = CFrame.new(-5050, 15, -5350), RespawnTime = 1200, QuestName = "IceQuest1", QuestLevel = 3},
            {ExactName = "Tide Keeper", Display = "Tide Keeper [Lv. 1400]", IslandCFrame = CFrame.new(-3700, 70, -10700), RespawnTime = 1800, QuestName = "ForgottenQuest", QuestLevel = 3}
        },
        Sea3 = {
            {ExactName = "Stone", Display = "Stone [Lv. 1550]", IslandCFrame = CFrame.new(-1050, 40, 6700), RespawnTime = 1200, QuestName = "Area1Quest", QuestLevel = 3},
            {ExactName = "Island Empress", Display = "Island Empress [Lv. 1675]", IslandCFrame = CFrame.new(5700, 600, 200), RespawnTime = 1200, QuestName = "Area2Quest", QuestLevel = 3},
            {ExactName = "Kilo Admiral", Display = "Kilo Admiral [Lv. 1750]", IslandCFrame = CFrame.new(2850, 70, -7200), RespawnTime = 1200, QuestName = "Area3Quest", QuestLevel = 3},
            {ExactName = "Captain Elephant", Display = "Captain Elephant [Lv. 1875]", IslandCFrame = CFrame.new(-13400, 330, -8400), RespawnTime = 1200, QuestName = "FloatingTurtleQuest", QuestLevel = 1},
            {ExactName = "Beautiful Pirate", Display = "Beautiful Pirate [Lv. 1950]", IslandCFrame = CFrame.new(-12000, 330, -8800), RespawnTime = 1800, QuestName = "FloatingTurtleQuest", QuestLevel = 2},
            {ExactName = "Longma", Display = "Longma [Lv. 2000]", IslandCFrame = CFrame.new(-10200, 330, -9400), RespawnTime = 1800}
        }
    }

    _G.ENI_BossData = isSea2 and allBossData.Sea2 or (isSea3 and allBossData.Sea3 or allBossData.Sea1)
end

local BossData = _G.ENI_BossData
local bossCooldowns = {}
local bossKillTimes = {}
local bossCheckState = {
    CheckingBoss = nil,
    ArrivalTime = 0
}

-- AUTO BOSS CONFIGURATION
local selectedBosses = {}
local isAutoBossOn = false

local getBossState, setBossState = createSliderToggle(bossPage, "Enable Auto Boss", false, function(newState)
    isAutoBossOn = newState
end)
_G.ENI_setAutoBossState = setBossState

local isAutoBossHopOn = false
createSliderToggle(bossPage, "Auto Server Hop when Bosses Dead", false, function(newState)
    isAutoBossHopOn = newState
end)

local bossList = Hub.CreateList(bossPage, "💀 Current Sea Bosses", {}, 220, true, {MultiSelect = true})
local bossStatusBadges = {}

for i, boss in ipairs(BossData) do
    selectedBosses[boss.ExactName] = false
    local bossTitle = tostring(boss.Display or boss.ExactName or ("Boss #" .. tostring(i)))
    local row, entryData = bossList:AddItem(bossTitle, "[READY / UNCHECKED]", function()
        selectedBosses[boss.ExactName] = not selectedBosses[boss.ExactName]
    end)
    if row then
        local badge = row:FindFirstChild("ItemSubtitle")
        if badge then
            bossStatusBadges[boss.ExactName] = badge
        end
    end
end

-- Live Auto Boss List Status Updater Task (Updates [READY], [DEAD (MM:SS)], and [READY / UNCHECKED] badges)
task.spawn(function()
    while task.wait(1) do
        pcall(function()
            local enemies = workspace:FindFirstChild("Enemies")
            local liveBosses = {}
            if enemies then
                for _, mob in ipairs(enemies:GetChildren()) do
                    local mHum = mob:FindFirstChildOfClass("Humanoid")
                    if mHum and mHum.Health > 0 then
                        for _, boss in ipairs(BossData) do
                            if string.find(string.lower(mob.Name), string.lower(boss.ExactName)) then
                                liveBosses[boss.ExactName] = true
                            end
                        end
                    end
                end
            end

            local now = tick()
            for _, boss in ipairs(BossData) do
                local badge = bossStatusBadges[boss.ExactName]
                if badge then
                    if liveBosses[boss.ExactName] then
                        badge.Text = "[READY]"
                        badge.TextColor3 = Color3.fromRGB(0, 230, 120)
                    else
                        local killTime = bossKillTimes[boss.ExactName] or bossCooldowns[boss.ExactName] or 0
                        if killTime > now then
                            local cdSec = math.ceil(killTime - now)
                            local mins = math.floor(cdSec / 60)
                            local secs = cdSec % 60
                            badge.Text = string.format("[DEAD] (%02d:%02d)", mins, secs)
                            badge.TextColor3 = Color3.fromRGB(255, 60, 60)
                        else
                            bossKillTimes[boss.ExactName] = nil
                            bossCooldowns[boss.ExactName] = nil
                            badge.Text = "[READY / UNCHECKED]"
                            badge.TextColor3 = Color3.fromRGB(255, 200, 50)
                        end
                    end
                end
            end
        end)
    end
end)

-- ESP, FRUIT & MISC PAGE STATE FLAGS
local isChestEspOn = false
local isPlayerEspOn = false
local isBossEspOn = false
local isFruitEspOn = false
local isAutoFruitSniperOn = false
local isAutoStoreFruitOn = true
local isAutoFruitHopOn = false
local isPotatoModeOn = false

-- ESP PAGE (VISUAL TRACKERS)
do
    Hub.CreateSection(espPage, "👁️ Visual ESP Trackers")

    createSliderToggle(espPage, "Chest ESP Tracker", false, function(newState)
        isChestEspOn = newState
    end)

    createSliderToggle(espPage, "Player ESP & Health Tracker", false, function(newState)
        isPlayerEspOn = newState
    end)

    createSliderToggle(espPage, "Boss ESP & Level Tracker", false, function(newState)
        isBossEspOn = newState
    end)
end

-- FRUIT PAGE SETUP (DEVIL FRUIT SUITE)
do
    Hub.CreateSection(fruitPage, "🍎 Devil Fruit Suite & Auto Sniper")

    Hub.CreateButton(fruitPage, "🎁 Collect All Spawned Fruits", function()
        task.spawn(function()
            pcall(function()
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if not hrp then return end

                local found = 0
                for _, obj in ipairs(workspace:GetChildren()) do
                    if obj:IsA("Tool") and (string.find(obj.Name, "Fruit") or obj:FindFirstChild("Handle")) then
                        local handle = obj:FindFirstChild("Handle") or obj:FindFirstChildOfClass("BasePart")
                        if handle then
                            found = found + 1
                            safeTweenToIsland(handle.CFrame)
                            task.wait(1.5)
                        end
                    end
                end
                
                if found == 0 then
                    notifyGUI("Fruit Collector", "No spawned fruits found in server.", 4)
                else
                    notifyGUI("Fruit Collector", "Collected " .. found .. " fruit(s)!", 4)
                end
            end)
        end)
    end)

    createSliderToggle(fruitPage, "Fruit ESP & Distance Tracker", false, function(newState)
        isFruitEspOn = newState
    end)

    createSliderToggle(fruitPage, "Auto Fruit Sniper", false, function(newState)
        isAutoFruitSniperOn = newState
    end)

    createSliderToggle(fruitPage, "Auto Store Fruit", true, function(newState)
        isAutoStoreFruitOn = newState
    end)

    createSliderToggle(fruitPage, "Auto Server Hop if No Fruit Spawned", false, function(newState)
        isAutoFruitHopOn = newState
    end)
end

-- MISC PAGE SETUP (POTATO MODE & PERFORMANCE)
do
    Hub.CreateSection(miscPage, "⚙️ Misc & Performance Settings")

    local miscPotatoSaved = {}
    createSliderToggle(miscPage, "⚡ Potato Mode", false, function(newState)
        isPotatoModeOn = newState
        pcall(function()
            if newState then
                miscPotatoSaved = { materials = {}, decals = {}, emitters = {} }
                local terrain = workspace:FindFirstChildOfClass("Terrain")
                if terrain then
                    terrain.WaterWaveSize = 0
                    terrain.WaterWaveSpeed = 0
                end
                game:GetService("Lighting").GlobalShadows = false
                for _, v in ipairs(workspace:GetDescendants()) do
                    if v:IsA("BasePart") and not v:IsA("MeshPart") and not v:IsA("Terrain") then
                        miscPotatoSaved.materials[v] = v.Material
                        v.Material = Enum.Material.SmoothPlastic
                    elseif v:IsA("Decal") or v:IsA("Texture") then
                        miscPotatoSaved.decals[v] = v.Transparency
                        v.Transparency = 1
                    elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
                        if v.Enabled then
                            miscPotatoSaved.emitters[v] = true
                            v.Enabled = false
                        end
                    end
                end
            else
                local terrain = workspace:FindFirstChildOfClass("Terrain")
                if terrain then
                    terrain.WaterWaveSize = 0.15
                    terrain.WaterWaveSpeed = 10
                end
                game:GetService("Lighting").GlobalShadows = true
                if miscPotatoSaved.materials then
                    for part, mat in pairs(miscPotatoSaved.materials) do
                        if part and part.Parent then part.Material = mat end
                    end
                end
                if miscPotatoSaved.decals then
                    for decal, trans in pairs(miscPotatoSaved.decals) do
                        if decal and decal.Parent then decal.Transparency = trans end
                    end
                end
                if miscPotatoSaved.emitters then
                    for emitter, _ in pairs(miscPotatoSaved.emitters) do
                        if emitter and emitter.Parent then emitter.Enabled = true end
                    end
                end
                miscPotatoSaved = {}
            end
        end)
        notifyGUI("PERFORMANCE", newState and "Potato Mode ENABLED! ⚡ (Textures & Particles OFF)" or "Potato Mode Disabled.", 3)
    end)
end



    -- AUTO-REJOIN PROTECTION (INTERCEPT DISCONNECTIONS)
    pcall(function()
        local GuiService = game:GetService("GuiService")
        GuiService.ErrorMessageChanged:Connect(function()
            task.wait(0.5)
            pcall(function()
                if _G.ENI_SmartServerHop then
                    _G.ENI_SmartServerHop("rejoin")
                else
                    game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
                end
            end)
        end)
    end)

-- ESP BACKGROUND RENDERER LOOP
if _G.ENI_EspLoop then pcall(function() _G.ENI_EspLoop:Disconnect() end) end
if _G.ENI_EspThread then pcall(function() task.cancel(_G.ENI_EspThread) end) end
if _G.ENI_FastEspRender then pcall(function() _G.ENI_FastEspRender:Disconnect() end) end

local espGuiParent = nil
pcall(function()
    local targetParent = (gethui and gethui()) or game:GetService("CoreGui") or (LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui"))
    espGuiParent = targetParent and targetParent:FindFirstChild("ENI_ESP_GuiContainer")
    if not espGuiParent and targetParent then
        espGuiParent = Instance.new("ScreenGui")
        espGuiParent.Name = "ENI_ESP_GuiContainer"
        espGuiParent.ResetOnSpawn = false
        espGuiParent.Parent = targetParent
    end
end)
local espFolder = espGuiParent

local knownBossNames = {
    ["Gorilla King"] = true, ["Bobby"] = true, ["Yeti"] = true, ["Mob Leader"] = true,
    ["Vice Admiral"] = true, ["Warden"] = true, ["Chief Warden"] = true, ["Swan"] = true,
    ["Magma Admiral"] = true, ["Fishman Lord"] = true, ["Wysper"] = true, ["Thunder God"] = true,
    ["Cyborg"] = true, ["Saber Expert"] = true, ["The Saw"] = true, ["Greybeard"] = true
}

local function createEspTag(targetPos, textStr, color3Val, tagKey)
    local existing = espFolder:FindFirstChild(tagKey)
    if not existing then
        existing = Instance.new("TextLabel")
        existing.Name = tagKey
        existing.Size = UDim2.new(0, 260, 0, 24)
        existing.AnchorPoint = Vector2.new(0.5, 0.5)
        existing.BackgroundTransparency = 1
        existing.Font = Enum.Font.GothamBold
        existing.TextSize = 13
        existing.TextStrokeTransparency = 0.2
        existing.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        existing.Parent = espFolder
    end
    
    existing.Text = textStr
    existing.TextColor3 = color3Val
    return existing
end

local cachedEspObjects = {}

-- Layer 1: Background Object Scanner (Scans All Chests, Fruits, Players, Bosses)
_G.ENI_EspThread = task.spawn(function()
    while true do
        task.wait(0.5)
        pcall(function()
            if not isFruitEspOn and not isChestEspOn and not isPlayerEspOn and not isBossEspOn then
                cachedEspObjects = {}
                espFolder:ClearAllChildren()
                return
            end

            local newPool = {}

            -- 1. All Chest Scanner
            if isChestEspOn then
                pcall(function()
                    local searchRoots = {workspace:FindFirstChild("Map") or workspace, workspace}
                    for _, root in ipairs(searchRoots) do
                        for _, obj in ipairs(root:GetDescendants()) do
                            local nameLower = string.lower(obj.Name)
                            local isChest = string.find(nameLower, "chest") or ((obj:FindFirstChildOfClass("TouchTransmitter") or obj:FindFirstChild("TouchInterest")) and string.find(string.lower(obj.Parent.Name), "chest"))
                            
                            if isChest then
                                local part = obj:IsA("BasePart") and obj or obj:FindFirstChildOfClass("BasePart") or obj:FindFirstChild("Handle")
                                if part then
                                    local id = "Chest_" .. obj:GetFullName()
                                    if not newPool[id] then
                                        newPool[id] = {Part = part, Name = "📦 " .. (obj.Name ~= "" and obj.Name or "Chest"), Color = Color3.fromRGB(255, 200, 50)}
                                    end
                                end
                            end
                        end
                    end
                end)
            end

            -- 2. Fruit Scanner
            if isFruitEspOn then
                pcall(function()
                    for _, obj in ipairs(workspace:GetChildren()) do
                        if obj:IsA("Tool") and (string.find(string.lower(obj.Name), "fruit") or obj:FindFirstChild("Handle")) then
                            local handle = obj:FindFirstChild("Handle") or obj:FindFirstChildOfClass("BasePart")
                            if handle then
                                local id = "Fruit_" .. obj:GetFullName()
                                newPool[id] = {Part = handle, Name = "🍎 " .. obj.Name, Color = Color3.fromRGB(40, 220, 100)}
                            end
                        end
                    end
                end)
            end

            -- 3. Player Scanner
            if isPlayerEspOn then
                pcall(function()
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChildOfClass("Humanoid") then
                            local pHrp = p.Character.HumanoidRootPart
                            local pHum = p.Character.Humanoid
                            if pHum.Health > 0 then
                                local id = "Player_" .. p.UserId
                                newPool[id] = {Part = pHrp, Name = "👤 " .. p.DisplayName, Color = Color3.fromRGB(0, 220, 255), Hum = pHum}
                            end
                        end
                    end
                end)
            end

            -- 4. Boss Scanner (Global 100% Coverage with Live MM:SS Respawn Timers)
            if isBossEspOn then
                pcall(function()
                    local spawnedBosses = {}
                    local enemies = workspace:FindFirstChild("Enemies")
                    
                    if enemies then
                        for _, mob in ipairs(enemies:GetChildren()) do
                            local mHrp = mob:FindFirstChild("HumanoidRootPart")
                            local mHum = mob:FindFirstChildOfClass("Humanoid")
                            if mHrp and mHum then
                                for _, bData in ipairs(BossData) do
                                    if string.find(string.lower(mob.Name), string.lower(bData.ExactName)) then
                                        if mHum.Health > 0 then
                                            spawnedBosses[bData.ExactName] = true
                                            local id = "BossLive_" .. bData.ExactName
                                            local rName, rLvl = string.match(bData.Display, "^(.-) %[(Lv%. %d+)%]$")
                                            newPool[id] = {
                                                Part = mHrp,
                                                Name = rName or bData.ExactName,
                                                Level = rLvl or "Lv. ?",
                                                IsAliveBoss = true,
                                                Color = Color3.fromRGB(0, 230, 120),
                                                Hum = mHum
                                            }
                                        end
                                    end
                                end
                            end
                        end
                    end

                    -- Verified Death Detection: Only register death if player was near mob AND witnessed health <= 0 or spawner empty!
                    local char = LocalPlayer.Character
                    local playerHRP = char and char:FindFirstChild("HumanoidRootPart")
                    _G.ENI_LastBossHP = _G.ENI_LastBossHP or {}

                    for _, bData in ipairs(BossData) do
                        local bName = bData.ExactName
                        local wasAlive = _G.ENI_LastSpawnedBosses and _G.ENI_LastSpawnedBosses[bName]
                        local isAliveNow = spawnedBosses[bName]

                        if wasAlive and not isAliveNow then
                            -- Only register death if player was in combat range (< 100 studs) when mob disappeared!
                            if playerHRP then
                                local distToSpawner = (playerHRP.Position - bData.IslandCFrame.Position).Magnitude
                                local lastHP = _G.ENI_LastBossHP[bName] or 100
                                
                                if distToSpawner <= 100 or lastHP <= 5 then
                                    -- Confirmed Kill!
                                    bossKillTimes[bName] = tick() + (bData.RespawnTime or 900)
                                    bossCooldowns[bName] = bossKillTimes[bName]
                                else
                                    -- Player simply moved away / unstreamed model! Do NOT set death timer!
                                    bossKillTimes[bName] = nil
                                    bossCooldowns[bName] = nil
                                end
                            end
                        end
                    end
                    _G.ENI_LastSpawnedBosses = spawnedBosses

                    -- Render ALL Bosses globally in current sea (even if unspawned or despawned due to distance)
                    local now = tick()
                    for _, bData in ipairs(BossData) do
                        if not spawnedBosses[bData.ExactName] then
                            local id = "BossSpawn_" .. bData.ExactName
                            local rName, rLvl = string.match(bData.Display, "^(.-) %[(Lv%. %d+)%]$")
                            rName = rName or bData.ExactName
                            rLvl = rLvl or "Lv. ?"
                            
                            -- Calculate live respawn timer (only if an actual death/cooldown was registered)
                            local targetTime = bossKillTimes[bData.ExactName] or bossCooldowns[bData.ExactName] or 0
                            
                            if targetTime > now then
                                local cdSec = math.ceil(targetTime - now)
                                local mins = math.floor(cdSec / 60)
                                local secs = cdSec % 60
                                local timerStr = string.format("%02d:%02d", mins, secs)

                                newPool[id] = {
                                    Position = bData.IslandCFrame.Position,
                                    IsDeadBoss = true,
                                    BossName = rName,
                                    Level = rLvl,
                                    TimerStr = timerStr,
                                    Color = Color3.fromRGB(255, 60, 60)
                                }
                            else
                                bossKillTimes[bData.ExactName] = nil
                                bossCooldowns[bData.ExactName] = nil

                                newPool[id] = {
                                    Position = bData.IslandCFrame.Position,
                                    IsUncheckedBoss = true,
                                    BossName = rName,
                                    Level = rLvl,
                                    Color = Color3.fromRGB(255, 200, 50)
                                }
                            end
                        end
                    end
                end)
            end

            cachedEspObjects = newPool
        end)
    end
end)

-- Layer 2: 2D Screen-Space Instant Projection Renderer (Infinite Distance 100% Guaranteed)
_G.ENI_FastEspRender = RunService.RenderStepped:Connect(function()
    pcall(function()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local cam = workspace.CurrentCamera
        if not cam then return end

        local activeKeys = {}
        for id, data in pairs(cachedEspObjects) do
            if data and (data.Position or (data.Part and data.Part.Parent)) then
                pcall(function()
                    local worldPos = data.Position or data.Part.Position
                    local screenPos, onScreen = cam:WorldToViewportPoint(worldPos)
                    
                    if screenPos.Z > 0 then
                        activeKeys[id] = true
                        local dist = math.floor((hrp.Position - worldPos).Magnitude)
                        local textStr = ""
                        
                        if data.IsAliveBoss and data.Hum then
                            local hp = math.floor(data.Hum.Health)
                            textStr = "🟢 [READY] " .. (data.Name or "Boss") .. " [" .. (data.Level or "Lv. ?") .. "] | " .. hp .. " HP (" .. dist .. "m)"
                        elseif data.IsDeadBoss then
                            textStr = "🔴 [DEAD] " .. (data.BossName or data.Name or "Boss") .. " [" .. (data.Level or "Lv. ?") .. "] (" .. (data.TimerStr or "CD") .. ") (" .. dist .. "m)"
                        elseif data.IsUncheckedBoss then
                            textStr = "🟡 [READY / UNCHECKED] " .. (data.BossName or data.Name or "Boss") .. " [" .. (data.Level or "Lv. ?") .. "] (" .. dist .. "m)"
                        else
                            textStr = data.Name .. " [" .. dist .. "m]"
                            if data.Hum then
                                local hpPct = math.floor((data.Hum.Health / data.Hum.MaxHealth) * 100)
                                textStr = data.Name .. " [" .. math.floor(data.Hum.Health) .. " HP (" .. hpPct .. "%) | " .. dist .. "m]"
                            end
                        end
                        
                        local tag = createEspTag(worldPos, textStr, data.Color, id)
                        tag.Position = UDim2.new(0, screenPos.X, 0, screenPos.Y)
                        tag.Visible = true
                    end
                end)
            end
        end

        for _, tag in ipairs(espFolder:GetChildren()) do
            if not activeKeys[tag.Name] then
                tag:Destroy()
            end
        end
    end)
end)

-- SERVER & STATS ANALYTICS PAGE
do
    Hub.CreateSection(serverPage, "📊 Server & Live Player Analytics")

    local pStatsCard = Instance.new("Frame")
    pStatsCard.Size = UDim2.new(0.98, 0, 0, 95)
    pStatsCard.BackgroundColor3 = Color3.fromRGB(20, 25, 36)
    pStatsCard.BorderSizePixel = 0
    pcall(function() pStatsCard.Parent = serverPage end)
    applyCorner(pStatsCard)

    local pStatsLbl = Instance.new("TextLabel")
    pStatsLbl.Size = UDim2.new(0.94, 0, 0.9, 0)
    pStatsLbl.Position = UDim2.new(0.03, 0, 0.05, 0)
    pStatsLbl.BackgroundTransparency = 1
    pStatsLbl.Text = "Loading Account Stats..."
    pStatsLbl.TextColor3 = Color3.fromRGB(220, 230, 255)
    pStatsLbl.Font = Enum.Font.GothamMedium
    pStatsLbl.TextSize = 11
    pStatsLbl.TextXAlignment = Enum.TextXAlignment.Left
    pStatsLbl.TextYAlignment = Enum.TextYAlignment.Top
    pcall(function() pStatsLbl.Parent = pStatsCard end)

    local sStatsCard = Instance.new("Frame")
    sStatsCard.Size = UDim2.new(0.98, 0, 0, 95)
    sStatsCard.BackgroundColor3 = Color3.fromRGB(20, 25, 36)
    sStatsCard.BorderSizePixel = 0
    pcall(function() sStatsCard.Parent = serverPage end)
    applyCorner(sStatsCard)

    local sStatsLbl = Instance.new("TextLabel")
    sStatsLbl.Size = UDim2.new(0.94, 0, 0.9, 0)
    sStatsLbl.Position = UDim2.new(0.03, 0, 0.05, 0)
    sStatsLbl.BackgroundTransparency = 1
    sStatsLbl.Text = "Loading Server Info..."
    sStatsLbl.TextColor3 = Color3.fromRGB(200, 210, 230)
    sStatsLbl.Font = Enum.Font.GothamMedium
    sStatsLbl.TextSize = 11
    sStatsLbl.TextXAlignment = Enum.TextXAlignment.Left
    sStatsLbl.TextYAlignment = Enum.TextYAlignment.Top
    pcall(function() sStatsLbl.Parent = sStatsCard end)

    -- Live World & Client Memory Card
    local wStatsCard = Instance.new("Frame")
    wStatsCard.Size = UDim2.new(0.98, 0, 0, 75)
    wStatsCard.BackgroundColor3 = Color3.fromRGB(20, 25, 36)
    wStatsCard.BorderSizePixel = 0
    pcall(function() wStatsCard.Parent = serverPage end)
    applyCorner(wStatsCard)

    local wStatsLbl = Instance.new("TextLabel")
    wStatsLbl.Size = UDim2.new(0.94, 0, 0.9, 0)
    wStatsLbl.Position = UDim2.new(0.03, 0, 0.05, 0)
    wStatsLbl.BackgroundTransparency = 1
    wStatsLbl.Text = "Loading World Analytics..."
    wStatsLbl.TextColor3 = Color3.fromRGB(180, 230, 200)
    wStatsLbl.Font = Enum.Font.GothamMedium
    wStatsLbl.TextSize = 11
    wStatsLbl.TextXAlignment = Enum.TextXAlignment.Left
    wStatsLbl.TextYAlignment = Enum.TextYAlignment.Top
    pcall(function() wStatsLbl.Parent = wStatsCard end)

    -- Analytics Auto-Update Thread
    task.spawn(function()
        local startTime = tick()
        while true do
            pcall(function()
                local data = LocalPlayer:FindFirstChild("Data")
                local beli = data and data:FindFirstChild("Beli") and data.Beli.Value or 0
                local frags = data and data:FindFirstChild("Fragments") and data.Fragments.Value or 0
                local lvl = data and data:FindFirstChild("Level") and data.Level.Value or 0
                local race = data and data:FindFirstChild("Race") and data.Race.Value or "Human"
                local bounty = LocalPlayer:FindFirstChild("leaderstats") and LocalPlayer.leaderstats:FindFirstChild("Bounty/Honor") and LocalPlayer.leaderstats["Bounty/Honor"].Value or 0

                pStatsLbl.Text = string.format("👤 Player: %s (@%s)\n💵 Beli: $%s  |  🍇 Frags: %s\n⭐ Level: %s  |  🧬 Race: %s\n🏴‍☠️ Bounty/Honor: %s",
                    LocalPlayer.DisplayName, LocalPlayer.Name,
                    tostring(beli), tostring(frags), tostring(lvl), tostring(race), tostring(bounty)
                )

                local uptime = math.floor(tick() - startTime)
                local hrs = math.floor(uptime / 3600)
                local mins = math.floor((uptime % 3600) / 60)
                local secs = uptime % 60
                local playersCount = #Players:GetPlayers()

                sStatsLbl.Text = string.format("🌐 Server JobID: %s\n🎮 PlaceID: %s\n👥 Players: %d/12  |  ⏱️ Hub Uptime: %02d:%02d:%02d",
                    string.sub(game.JobId, 1, 18) .. "...", tostring(game.PlaceId), playersCount, hrs, mins, secs
                )

                -- World & Memory Analytics
                local memUsage = math.floor(game:GetService("Stats"):GetTotalMemoryUsageMb())
                local wTime = math.floor(workspace.DistributedGameTime)
                local wHrs = math.floor(wTime / 3600)
                local wMins = math.floor((wTime % 3600) / 60)
                local wSecs = wTime % 60

                local fruitCount = 0
                for _, obj in ipairs(workspace:GetChildren()) do
                    if obj:IsA("Tool") and string.find(string.lower(obj.Name), "fruit") then fruitCount = fruitCount + 1 end
                end

                local chestCount = 0
                local searchRoots = {workspace:FindFirstChild("Map") or workspace, workspace}
                for _, root in ipairs(searchRoots) do
                    for _, obj in ipairs(root:GetDescendants()) do
                        if string.find(string.lower(obj.Name), "chest") then chestCount = chestCount + 1 end
                    end
                end

                wStatsLbl.Text = string.format("🧠 Client Memory: %d MB  |  ⌛ Server Age: %02d:%02d:%02d\n🍎 Spawned Fruits: %d  |  📦 Active Chests: %d",
                    memUsage, wHrs, wMins, wSecs, fruitCount, chestCount
                )
            end)
            task.wait(1)
        end
    end)
end

-- TAB NAVIGATION MANAGED AUTOMATICALLY BY UNKNOWN LIBRARY

-- CONFIGURATION & THEME MANAGED BY UNKNOWN LIBRARY

if Hub.registerFeatureStopper then
    Hub.registerFeatureStopper(function()
        if _G.ENI_MainFarmLoop then pcall(function() _G.ENI_MainFarmLoop:Disconnect() end) _G.ENI_MainFarmLoop = nil end
        if _G.ENI_FastHitLoop then pcall(function() _G.ENI_FastHitLoop:Disconnect() end) _G.ENI_FastHitLoop = nil end
        if _G.ENI_TravelTween then pcall(function() _G.ENI_TravelTween:Cancel() end) _G.ENI_TravelTween = nil end
        if _G.ENI_GlobalLoop then pcall(function() _G.ENI_GlobalLoop:Disconnect() end) _G.ENI_GlobalLoop = nil end
        if _G.ENI_WaterWalkConn then pcall(function() _G.ENI_WaterWalkConn:Disconnect() end) end
        if _G.ENI_EspLoop then pcall(function() _G.ENI_EspLoop:Disconnect() end) end
        if _G.ENI_EspThread then pcall(function() task.cancel(_G.ENI_EspThread) end) end
        if _G.ENI_FastEspRender then pcall(function() _G.ENI_FastEspRender:Disconnect() end) end
    end)
end

-- STRICT LEVEL DATA MAPPING (BLOX FRUITS 1ST & 2ND SEA PROGRESSION)
local LevelData = {
    -- 1ST SEA
    {MinLevel = 1, MaxLevel = 9, ExactName = "Bandit", Display = "Bandit [Lv. 5]", QuestName = "BanditQuest1", QuestLevel = 1, IslandCFrame = CFrame.new(1050, 16, 1400)},
    {MinLevel = 10, MaxLevel = 14, ExactName = "Monkey", Display = "Monkey [Lv. 14]", QuestName = "JungleQuest", QuestLevel = 1, IslandCFrame = CFrame.new(-1600, 37, 100)},
    {MinLevel = 15, MaxLevel = 29, ExactName = "Gorilla", Display = "Gorilla [Lv. 20]", QuestName = "JungleQuest", QuestLevel = 2, IslandCFrame = CFrame.new(-1240, 6, -500)},
    {MinLevel = 30, MaxLevel = 39, ExactName = "Pirate", Display = "Pirate [Lv. 35]", QuestName = "BuggyQuest1", QuestLevel = 1, IslandCFrame = CFrame.new(-1100, 4, 3900)},
    {MinLevel = 40, MaxLevel = 59, ExactName = "Brute", Display = "Brute [Lv. 45]", QuestName = "BuggyQuest1", QuestLevel = 2, IslandCFrame = CFrame.new(-1150, 15, 4300)},
    {MinLevel = 60, MaxLevel = 89, ExactName = "Desert Bandit", Display = "Desert Bandit [Lv. 60]", QuestName = "DesertQuest", QuestLevel = 1, IslandCFrame = CFrame.new(900, 6, 4400)},
    {MinLevel = 90, MaxLevel = 99, ExactName = "Snow Bandit", Display = "Snow Bandit [Lv. 90]", QuestName = "SnowQuest", QuestLevel = 1, IslandCFrame = CFrame.new(1300, 87, -1300)},
    {MinLevel = 100, MaxLevel = 119, ExactName = "Snowman", Display = "Snowman [Lv. 100]", QuestName = "SnowQuest", QuestLevel = 2, IslandCFrame = CFrame.new(1350, 87, -1400)},
    {MinLevel = 120, MaxLevel = 149, ExactName = "Chief Petty Officer", Display = "Chief Petty Officer [Lv. 120]", QuestName = "MarineQuest2", QuestLevel = 1, IslandCFrame = CFrame.new(-4900, 20, 4300)},
    {MinLevel = 150, MaxLevel = 174, ExactName = "Sky Bandit", Display = "Sky Bandit [Lv. 150]", QuestName = "SkyQuest", QuestLevel = 1, IslandCFrame = CFrame.new(-4800, 715, -2600)},
    {MinLevel = 175, MaxLevel = 224, ExactName = "Dark Master", Display = "Dark Master [Lv. 175]", QuestName = "SkyQuest", QuestLevel = 2, IslandCFrame = CFrame.new(-5200, 715, -2200)},
    {MinLevel = 225, MaxLevel = 274, ExactName = "Toga Warrior", Display = "Toga Warrior [Lv. 225]", QuestName = "ColosseumQuest", QuestLevel = 1, IslandCFrame = CFrame.new(-1800, 8, -2800)},
    {MinLevel = 275, MaxLevel = 299, ExactName = "Gladiator", Display = "Gladiator [Lv. 275]", QuestName = "ColosseumQuest", QuestLevel = 2, IslandCFrame = CFrame.new(-1370, 8, -3377)},
    {MinLevel = 300, MaxLevel = 324, ExactName = "Military Soldier", Display = "Military Soldier [Lv. 300]", QuestName = "MagmaQuest", QuestLevel = 1, IslandCFrame = CFrame.new(-5400, 15, 8600)},
    {MinLevel = 325, MaxLevel = 349, ExactName = "Military Spy", Display = "Military Spy [Lv. 325]", QuestName = "MagmaQuest", QuestLevel = 2, IslandCFrame = CFrame.new(-5800, 80, 8750)},
    {MinLevel = 350, MaxLevel = 374, ExactName = "Magma Admiral", Display = "Magma Admiral [Lv. 350]", QuestName = "MagmaQuest", QuestLevel = 3, IslandCFrame = CFrame.new(-5500, 80, 8850)},
    {MinLevel = 375, MaxLevel = 449, ExactName = "Fishman Warrior", Display = "Fishman Warrior [Lv. 375]", QuestName = "FishmanQuest", QuestLevel = 1, IslandCFrame = CFrame.new(61000, 18, 1500)},
    {MinLevel = 450, MaxLevel = 524, ExactName = "God's Guard", Display = "God's Guard [Lv. 450]", QuestName = "SkyExp1Quest", QuestLevel = 1, IslandCFrame = CFrame.new(-4600, 845, -1900)},
    {MinLevel = 525, MaxLevel = 624, ExactName = "Shandora Warrior", Display = "Shandora Warrior [Lv. 525]", QuestName = "SkyExp2Quest", QuestLevel = 1, IslandCFrame = CFrame.new(-7700, 5600, -1450)},
    {MinLevel = 625, MaxLevel = 699, ExactName = "Galley Pirate", Display = "Galley Pirate [Lv. 625]", QuestName = "FountainQuest", QuestLevel = 1, IslandCFrame = CFrame.new(5600, 38, 4800)},
    
    -- 2ND SEA (LEVEL 700 - 1500+)
    {MinLevel = 700, MaxLevel = 724, ExactName = "Raider", Display = "Raider [Lv. 700]", QuestName = "Area1Quest", QuestLevel = 1, IslandCFrame = CFrame.new(-760, 55, 2380)},
    {MinLevel = 725, MaxLevel = 749, ExactName = "Mercenary", Display = "Mercenary [Lv. 725]", QuestName = "Area1Quest", QuestLevel = 2, IslandCFrame = CFrame.new(-930, 85, 140)},
    {MinLevel = 750, MaxLevel = 774, ExactName = "Swan Pirate", Display = "Swan Pirate [Lv. 775]", QuestName = "Area2Quest", QuestLevel = 1, IslandCFrame = CFrame.new(875, 122, 1230)},
    {MinLevel = 775, MaxLevel = 799, ExactName = "Factory Staff", Display = "Factory Staff [Lv. 800]", QuestName = "Area2Quest", QuestLevel = 2, IslandCFrame = CFrame.new(295, 73, -60)},
    {MinLevel = 800, MaxLevel = 874, ExactName = "Marine Lieutenant", Display = "Marine Lieutenant [Lv. 875]", QuestName = "MarineQuest3", QuestLevel = 1, IslandCFrame = CFrame.new(-2850, 73, -3000)},
    {MinLevel = 875, MaxLevel = 899, ExactName = "Marine Captain", Display = "Marine Captain [Lv. 900]", QuestName = "MarineQuest3", QuestLevel = 2, IslandCFrame = CFrame.new(-2580, 73, -3150)},
    {MinLevel = 900, MaxLevel = 949, ExactName = "Giant Gladiator", Display = "Giant Gladiator [Lv. 900]", QuestName = "ColosseumQuest2", QuestLevel = 1, IslandCFrame = CFrame.new(-1800, 73, -3100)},
    {MinLevel = 950, MaxLevel = 974, ExactName = "Military Soldier", Display = "Military Soldier [Lv. 950]", QuestName = "IceQuest1", QuestLevel = 1, IslandCFrame = CFrame.new(1350, 87, -1300)},
    {MinLevel = 975, MaxLevel = 999, ExactName = "Military Spy", Display = "Military Spy [Lv. 975]", QuestName = "IceQuest1", QuestLevel = 2, IslandCFrame = CFrame.new(1500, 87, -1450)},
    {MinLevel = 1000, MaxLevel = 1024, ExactName = "Dragon Crew Warrior", Display = "Dragon Crew Warrior [Lv. 1000]", QuestName = "Area3Quest", QuestLevel = 1, IslandCFrame = CFrame.new(-2200, 73, -4400)},
    {MinLevel = 1025, MaxLevel = 1099, ExactName = "Dragon Crew Archer", Display = "Dragon Crew Archer [Lv. 1025]", QuestName = "Area3Quest", QuestLevel = 2, IslandCFrame = CFrame.new(-2400, 73, -4600)},
    {MinLevel = 1100, MaxLevel = 1124, ExactName = "Lab Subordinate", Display = "Lab Subordinate [Lv. 1100]", QuestName = "FireQuest1", QuestLevel = 1, IslandCFrame = CFrame.new(-6000, 15, -4800)},
    {MinLevel = 1125, MaxLevel = 1199, ExactName = "Horned Warrior", Display = "Horned Warrior [Lv. 1125]", QuestName = "FireQuest1", QuestLevel = 2, IslandCFrame = CFrame.new(-6400, 15, -5100)},
    {MinLevel = 1200, MaxLevel = 1249, ExactName = "Magma Ninja", Display = "Magma Ninja [Lv. 1250]", QuestName = "FireQuest2", QuestLevel = 1, IslandCFrame = CFrame.new(-5400, 15, -5800)},
    {MinLevel = 1250, MaxLevel = 1274, ExactName = "Lava Pirate", Display = "Lava Pirate [Lv. 1275]", QuestName = "FireQuest2", QuestLevel = 2, IslandCFrame = CFrame.new(-5200, 15, -6000)},
    {MinLevel = 1275, MaxLevel = 1349, ExactName = "Ship Deckhand", Display = "Ship Deckhand [Lv. 1250]", QuestName = "ShipQuest1", QuestLevel = 1, IslandCFrame = CFrame.new(900, 130, 32800)},
    {MinLevel = 1350, MaxLevel = 1374, ExactName = "Ice Soldier", Display = "Ice Soldier [Lv. 1350]", QuestName = "FrostQuest", QuestLevel = 1, IslandCFrame = CFrame.new(5800, 28, -6200)},
    {MinLevel = 1375, MaxLevel = 1424, ExactName = "Arctic Warrior", Display = "Arctic Warrior [Lv. 1375]", QuestName = "FrostQuest", QuestLevel = 2, IslandCFrame = CFrame.new(6200, 28, -6400)},
    {MinLevel = 1425, MaxLevel = 1449, ExactName = "Sea Soldier", Display = "Sea Soldier [Lv. 1425]", QuestName = "ForgottenQuest", QuestLevel = 1, IslandCFrame = CFrame.new(-3000, 10, -9800)},
    {MinLevel = 1450, MaxLevel = 2600, ExactName = "Water Fighter", Display = "Water Fighter [Lv. 1450]", QuestName = "ForgottenQuest", QuestLevel = 2, IslandCFrame = CFrame.new(-3300, 10, -10200)}
}

local function getDynamicIslandCFrame(targetEntry)
    if not targetEntry then return CFrame.new(0, 50, 0) end
    
    -- 1. Try exact enemy spawner part CFrame from workspace._WorldOrigin.EnemySpawns / EnemySpawns
    local spCFrame = nil
    pcall(function()
        local mobSpawners = getSpawnersForMob(targetEntry.ExactName)
        if #mobSpawners > 0 then
            spCFrame = mobSpawners[1]
        end
    end)
    if spCFrame then return spCFrame end

    -- 2. Direct exact mob spawn CFrame
    return targetEntry.IslandCFrame
end

local function getTargetData()
    local lvl = getPlayerLevel()
    local matchedEntry = nil
    local matchedIndex = 1
    for i = 1, #LevelData do
        local entry = LevelData[i]
        if lvl >= entry.MinLevel and lvl <= entry.MaxLevel then
            matchedEntry = entry
            matchedIndex = i
            break
        end
    end

    if not matchedEntry then return LevelData[1] end

    -- Smart Boss Fallback for Level Quests (e.g. Magma Admiral at Lv 350-374)
    if matchedEntry.ExactName == "Magma Admiral" then
        local bossAlive = false
        pcall(function()
            local enemies = workspace:FindFirstChild("Enemies") and workspace.Enemies:GetChildren() or {}
            for _, mob in ipairs(enemies) do
                if string.find(mob.Name, "Magma Admiral") and mob:FindFirstChild("HumanoidRootPart") and mob:FindFirstChildOfClass("Humanoid") and mob.Humanoid.Health > 0 then
                    bossAlive = true
                    break
                end
            end
        end)
        if not bossAlive and matchedIndex > 1 then
            return LevelData[matchedIndex - 1] -- Fallback to Military Spy [Lv. 325]
        end
    end

    return matchedEntry
end

local function getAutoProgressionBossTarget(currentLevel)
    local bestBoss = nil
    local bestBossMob = nil
    local bestBossLevel = -1

    for i = 1, #BossData do
        local b = BossData[i]
        local lvlStr = string.match(b.Display or "", "%[Lv%. (%d+)%]")
        local bLvl = lvlStr and tonumber(lvlStr) or 0
        
        if currentLevel >= bLvl and (currentLevel - bLvl) <= 100 then
            local enemies = workspace:FindFirstChild("Enemies")
            if enemies then
                for _, mob in ipairs(enemies:GetChildren()) do
                    if string.find(mob.Name, b.ExactName) and mob:FindFirstChild("HumanoidRootPart") and mob:FindFirstChildOfClass("Humanoid") and mob.Humanoid.Health > 0 then
                        if bLvl > bestBossLevel then
                            bestBoss = b
                            bestBossMob = mob
                            bestBossLevel = bLvl
                        end
                    end
                end
            end
        end
    end
    
    return bestBoss, bestBossMob
end

local function getBossTarget()
    if not isAutoBossOn then return nil, nil end

    local enemies = workspace.Enemies:GetChildren()
    for i = 1, #enemies do
        local mob = enemies[i]
        if mob:FindFirstChild("HumanoidRootPart") and mob:FindFirstChildOfClass("Humanoid") and mob.Humanoid.Health > 0 then
            for j = 1, #BossData do
                local bName = BossData[j].ExactName
                if selectedBosses[bName] and string.find(mob.Name, bName) then
                    bossCheckState.CheckingBoss = nil
                    return BossData[j], mob
                end
            end
        end
    end

    -- Smart Spawner Probe for UNCHECKED / Expired Bosses
    local now = tick()
    local playerHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

    for j = 1, #BossData do
        local b = BossData[j]
        if selectedBosses[b.ExactName] then
            local killTime = bossKillTimes[b.ExactName] or bossCooldowns[b.ExactName] or 0
            if killTime <= now then
                -- Check if player is near spawner to verify if model spawned
                if playerHRP then
                    local distToSpawner = (playerHRP.Position - b.IslandCFrame.Position).Magnitude
                    if distToSpawner <= 60 then
                        -- Player is at spawner, but boss model wasn't found in Enemies ➔ set death cooldown!
                        bossCheckState[b.ExactName] = bossCheckState[b.ExactName] or now
                        if now - bossCheckState[b.ExactName] > 2 then
                            bossKillTimes[b.ExactName] = now + (b.RespawnTime or 900)
                            bossCooldowns[b.ExactName] = bossKillTimes[b.ExactName]
                            bossCheckState[b.ExactName] = nil
                        end
                    else
                        bossCheckState[b.ExactName] = nil
                        return b, "CHECKING"
                    end
                else
                    return b, "CHECKING"
                end
            end
        end
    end

    local hasSelected = false
    for k, v in pairs(selectedBosses) do
        if v then hasSelected = true break end
    end
    
    if hasSelected and isAutoBossHopOn then
        if not _G.ENI_BossHopCooldown or tick() - _G.ENI_BossHopCooldown > 15 then
            _G.ENI_BossHopCooldown = tick()
            notifyGUI("Auto Boss", "All bosses dead/cooldown! Auto Hopping...", 5)
            if _G.ENI_SmartServerHop then
                _G.ENI_SmartServerHop("lowest")
            else
                pcall(function() game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer) end)
            end
        end
    end

    return nil, nil
end



local function autoClaimQuest(questName, questLevel)
    pcall(function()
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        local mainUI = playerGui and playerGui:FindFirstChild("Main")
        local questFrame = mainUI and mainUI:FindFirstChild("Quest")

        if not questFrame or not questFrame.Visible then
            CommF:InvokeServer("StartQuest", questName, questLevel)
        end
    end)
end

_G.ENI_TravelNoclip = game:GetService("RunService").Stepped:Connect(function()
    if isTraveling or isFarmOn then
        pcall(function()
            local char = LocalPlayer.Character
            if char then
                for _, p in ipairs(char:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = false end
                end
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum.PlatformStand = true
                    hum.AutoRotate = false
                end
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local bv = getTabBV(hrp)
                    if bv then
                        bv.Velocity = Vector3.zero
                        bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
                    end
                    hrp.Velocity = Vector3.zero
                    if hrp:IsA("BasePart") then
                        hrp.AssemblyLinearVelocity = Vector3.zero
                        hrp.AssemblyAngularVelocity = Vector3.zero
                    end
                end
            end
        end)
    end
end)

local function customDistributeStats()
    if not isStatsOn then return end
    pcall(function()
        local data = LocalPlayer:FindFirstChild("Data")
        local pointsObj = data and data:FindFirstChild("Points")
        if pointsObj and pointsObj.Value > 0 then
            local available = pointsObj.Value
            local step = math.min(available, pointsPerUpgrade)

            for statKey, isSelected in pairs(selectedStats) do
                if isSelected and available >= step then
                    CommF:InvokeServer("AddPoint", statKey, step)
                    available = available - step
                end
            end
        end
    end)
end

safeTweenToIsland = function(targetCFrame, callback)
    if isTraveling then
        return
    end

    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then 
        isTraveling = false
        return 
    end
    local hrp = char.HumanoidRootPart

    local farmDist = math.max(_G.ENI_FarmDistance or 10.0, 10.0)
    local targetCF
    if typeof(targetCFrame) == "CFrame" then
        targetCF = targetCFrame
    elseif typeof(targetCFrame) == "Vector3" then
        targetCF = CFrame.new(targetCFrame + Vector3.new(0, farmDist, 0))
    else
        isTraveling = false
        return
    end

    -- Ensure anti-gravity is firmly active before initiating flight
    local bv = getTabBV(hrp)
    if bv then
        bv.Velocity = Vector3.zero
        bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    end

    local currentPos = hrp.Position
    local targetPos = targetCF.Position

    -- BLOX FRUITS DIMENSIONAL PORTAL TELEPORT SOLVER (FISHMAN ISLAND & SKYLANDS)
    local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
    local commF = remotes and remotes:FindFirstChild("CommF_")

    -- 1. Enter Fishman Island (Target inside Fishman City X > 50000, Player in Main Sea)
    if targetPos.X > 50000 and currentPos.X < 50000 then
        isTraveling = true
        task.spawn(function()
            pcall(function()
                if commF then
                    commF:InvokeServer("requestEntrance", Vector3.new(61163.8515625, 11.6796875, 1819.7841796875))
                    task.wait(1)
                end
                isTraveling = false
                safeTweenToIsland(targetCF, callback)
            end)
        end)
        return
    end

    -- 2. Exit Fishman Island (Player inside Fishman City X > 50000, Target in Main Sea)
    if currentPos.X > 50000 and targetPos.X < 50000 then
        isTraveling = true
        task.spawn(function()
            pcall(function()
                if commF then
                    commF:InvokeServer("requestEntrance", Vector3.new(3864.68, 6.66, -1926.34))
                    task.wait(1)
                end
                isTraveling = false
                safeTweenToIsland(targetCF, callback)
            end)
        end)
        return
    end

    -- 3. Enter Upper Skylands (Target in Upper Skylands Y > 4000, Player below)
    if targetPos.Y > 4000 and currentPos.Y < 4000 then
        isTraveling = true
        task.spawn(function()
            pcall(function()
                if commF then
                    commF:InvokeServer("requestEntrance", Vector3.new(-7894.62, 5547.14, -380.29))
                    task.wait(1)
                end
                isTraveling = false
                safeTweenToIsland(targetCF, callback)
            end)
        end)
        return
    end

    -- 4. Exit Upper Skylands (Player in Upper Skylands Y > 4000, Target below)
    if currentPos.Y > 4000 and targetPos.Y < 4000 then
        isTraveling = true
        task.spawn(function()
            pcall(function()
                if commF then
                    commF:InvokeServer("requestEntrance", Vector3.new(-4607.82, 872.54, -1667.56))
                    task.wait(1)
                end
                isTraveling = false
                safeTweenToIsland(targetCF, callback)
            end)
        end)
        return
    end

    local dist = (hrp.Position - targetCF.Position).Magnitude

    if dist <= 12 then
        if _G.ENI_TravelTween then pcall(function() _G.ENI_TravelTween:Cancel() end) _G.ENI_TravelTween = nil end
        isTraveling = false
        hrp.CFrame = targetCF
        if callback then callback() end
        return
    end

    isTraveling = true
    if _G.ENI_TravelTween then pcall(function() _G.ENI_TravelTween:Cancel() end) _G.ENI_TravelTween = nil end
    
    local currentTweenID = tick()
    _G.ENI_TravelTweenID = currentTweenID

    -- Smooth high-speed travel (300 studs/sec)
    local speed = 300
    local travelTime = math.clamp(dist / speed, 0.1, 45)
    local tweenInfo = TweenInfo.new(travelTime, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)

    _G.ENI_TravelTween = TweenService:Create(hrp, tweenInfo, {CFrame = targetCF})
    _G.ENI_TravelTween.Completed:Connect(function()
        if _G.ENI_TravelTweenID ~= currentTweenID then return end
        isTraveling = false
        if callback then callback() end
    end)
    _G.ENI_TravelTween:Play()
end

local function autoEquipSelectedWeapon(forceType)
    local char = LocalPlayer.Character
    if not char then return nil end
    local typeToUse = forceType or selectedWeaponType

    local function isMatching(tool)
        if not tool or not tool:IsA("Tool") then return false end
        if typeToUse == "Melee" then
            return tool.ToolTip == "Melee" or tool.Name == "Combat" or tool.Name == "Dark Step" or tool.Name == "Electric" or tool.Name == "Water Kung Fu" or tool.Name == "Superhuman" or tool.Name == "Death Step" or tool.Name == "Sharkman Karate" or tool.Name == "Electric Claw" or tool.Name == "Dragon Talon" or tool.Name == "Godhuman" or tool.Name == "Sanguine Art"
        elseif typeToUse == "Blox Fruit" then
            return tool.ToolTip == "Blox Fruit" or tool.ToolTip == "Demon Fruit" or string.find(tool.Name, "Fruit")
        elseif typeToUse == "Sword" then
            return tool.ToolTip == "Sword"
        elseif typeToUse == "Gun" then
            return tool.ToolTip == "Gun"
        end
        return false
    end

    local heldTool = char:FindFirstChildOfClass("Tool")
    if isMatching(heldTool) then return heldTool end

    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        for _, tool in ipairs(bp:GetChildren()) do
            if isMatching(tool) then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then hum:UnequipTools() end
                tool.Parent = char
                return tool
            end
        end
    end
    return heldTool
end

local function getSpawnersForMob(mobName)
    local spawners = {}
    local searched = {}

    local function addSpawn(s)
        if s:IsA("BasePart") and string.find(string.lower(s.Name), string.lower(mobName)) and not searched[s] then
            searched[s] = true
            table.insert(spawners, s.CFrame)
        end
    end

    local enemySpawns = workspace:FindFirstChild("_WorldOrigin") and workspace._WorldOrigin:FindFirstChild("EnemySpawns")
    if enemySpawns then
        for _, s in ipairs(enemySpawns:GetChildren()) do addSpawn(s) end
    end

    local rootSpawns = workspace:FindFirstChild("EnemySpawns")
    if rootSpawns then
        for _, s in ipairs(rootSpawns:GetChildren()) do addSpawn(s) end
    end

    return spawners
end

_G.stopENIFarm = function()
    isFarmOn = false
    _G.ENI_CancelTween()
    
    if _G.ENI_MainFarmLoop then 
        _G.ENI_MainFarmLoop:Disconnect() 
        _G.ENI_MainFarmLoop = nil 
    end

    pcall(function()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            removeTabBV(hrp)
            hrp.Velocity = Vector3.zero
            if hrp:IsA("BasePart") then
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
            end
        end
    end)

    -- Restore NPC physics & collision so they don't fall out of the map
    pcall(function()
        local enemies = workspace:FindFirstChild("Enemies") and workspace.Enemies:GetChildren() or {}
        for _, mob in ipairs(enemies) do
            local hum = mob:FindFirstChildOfClass("Humanoid")
            if hum then hum.PlatformStand = false end
            for _, part in ipairs(mob:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = true end
            end
        end
    end)

    if farmStatusLabel then farmStatusLabel.Text = "Status: Auto Farm OFF." end
end

_G.startENIFarm = function()
    if _G.ENI_MainFarmLoop then _G.ENI_MainFarmLoop:Disconnect() _G.ENI_MainFarmLoop = nil end
    if _G.ENI_TravelTween then pcall(function() _G.ENI_TravelTween:Cancel() end) _G.ENI_TravelTween = nil end
    isTraveling = false
    farmStatusLabel.Text = "Status: Auto Farm Engine Active..."

    local lastQuestClaim = 0
    local lastToolRefresh = 0
    local lastStatAlloc = 0
    local lastRollTime = 0
    local groundCFrame = nil
    local currentTargetName = nil
    local lastSkillTime = 0
    local lastMasterySkillTime = 0
    local spawnerSweepIdx = 1
    local lastSweepTime = 0
    local isWaitingAtSpawner = false
    local hasArrivedAtSpawner = false

    _G.ENI_MainFarmLoop = RunService.Heartbeat:Connect(function()
        if not isFarmOn then return end
        pcall(function()
            local currentLevel = getPlayerLevel()
            local targetData = getTargetData()
            local bossData, bossMob = getBossTarget()

            if not bossData and not isAutoMaterialOn and not isAutoSelectMobOn then
                bossData, bossMob = getAutoProgressionBossTarget(currentLevel)
            end
            
            local exactMobName, displayName, islandCFrame
            if bossData then
                exactMobName = bossData.ExactName
                displayName = bossData.Display
                islandCFrame = getDynamicIslandCFrame(bossData)
            elseif isAutoMaterialOn and MaterialData[selectedMaterial] then
                local matInfo = MaterialData[selectedMaterial]
                exactMobName = matInfo.MobName
                displayName = matInfo.MobName .. " [" .. selectedMaterial .. "]"
                islandCFrame = matInfo.IslandCFrame
                for _, ld in ipairs(LevelData) do
                    if string.find(string.lower(ld.ExactName), string.lower(matInfo.MobName)) then
                        islandCFrame = getDynamicIslandCFrame(ld)
                        targetData = ld
                        break
                    end
                end
            elseif isAutoSelectMobOn then
                exactMobName = selectedCustomMobName
                displayName = selectedCustomMobName
                islandCFrame = getDynamicIslandCFrame(targetData)
                for _, ld in ipairs(LevelData) do
                    if string.find(string.lower(ld.ExactName), string.lower(selectedCustomMobName)) then
                        islandCFrame = getDynamicIslandCFrame(ld)
                        targetData = ld
                        break
                    end
                end
            else
                exactMobName = targetData.ExactName
                displayName = targetData.Display
                islandCFrame = getDynamicIslandCFrame(targetData)
            end

            if currentTargetName ~= exactMobName then
                currentTargetName = exactMobName
                groundCFrame = nil
                spawnerSweepIdx = 1
                lastSweepTime = 0
                isWaitingAtSpawner = false
                hasArrivedAtSpawner = false
                if _G.ENI_TravelTween then pcall(function() _G.ENI_TravelTween:Cancel() end) end
                isTraveling = false
            end

            if isAutoQuestOn and tick() - lastQuestClaim > 3 then
                lastQuestClaim = tick()
                task.spawn(function()
                    if bossData and bossData.QuestName and bossData.QuestLevel then
                        autoClaimQuest(bossData.QuestName, bossData.QuestLevel)
                    elseif targetData and targetData.QuestName and targetData.QuestLevel then
                        autoClaimQuest(targetData.QuestName, targetData.QuestLevel)
                    end
                end)
            end

            if isStatsOn and tick() - lastStatAlloc > 3 then
                lastStatAlloc = tick()
                task.spawn(function()
                    customDistributeStats()
                end)
            end
            
            if isAutoRollOn and tick() - lastRollTime > 30 then
                lastRollTime = tick()
                task.spawn(function()
                    pcall(function()
                        CommF:InvokeServer("Cousin", "Buy")
                        CommF:InvokeServer("Cousin", "DLCBoxData")
                        task.wait(1.5)
                        
                        local function storeTool(tool)
                            local orig = tool:GetAttribute("OriginalName")
                            if orig then
                                CommF:InvokeServer("StoreFruit", orig, tool)
                                 notifyGUI("FRUIT", "Auto-Stored: " .. tostring(orig), 4)
                            end
                        end
                        
                        local char = LocalPlayer.Character
                        if char then
                            local tool = char:FindFirstChildOfClass("Tool")
                            if tool and (string.find(tool.Name, "Fruit") or tool:GetAttribute("OriginalName")) then
                                storeTool(tool)
                            end
                        end
                        
                        local bp = LocalPlayer:FindFirstChild("Backpack")
                        if bp then
                            for _, t in ipairs(bp:GetChildren()) do
                                if t:IsA("Tool") and (string.find(t.Name, "Fruit") or t:GetAttribute("OriginalName")) then
                                    storeTool(t)
                                end
                            end
                        end
                    end)
                end)
            end

            if tick() - lastToolRefresh > 15 then
                lastToolRefresh = tick()
                autoEquipSelectedWeapon()
            end

            if isAutoHakiOn then
                local char = LocalPlayer.Character
                if char and not char:FindFirstChild("HasBuso") and not char:FindFirstChild("Buso") then
                    pcall(function()
                        ensureBusoHakiActive()
                    end)
                end
            end

            if isAutoSkillsOn and tick() - lastSkillTime > 3 and not (isAutoMasteryOn and lowestHealthPercent <= 10) then
                lastSkillTime = tick()
                task.spawn(function()
                    pcall(function()
                        local vim = game:GetService("VirtualInputManager")
                        local origTool = char:FindFirstChildOfClass("Tool")
                        
                        -- Equip the auto skills weapon
                        local skillsTool = autoEquipSelectedWeapon(selectedSkillsWeapon)
                        task.wait(0.5)
                        
                        if activeSkills.Z then
                            vim:SendKeyEvent(true, Enum.KeyCode.Z, false, game)
                            task.wait(0.15)
                            vim:SendKeyEvent(false, Enum.KeyCode.Z, false, game)
                            task.wait(0.2)
                        end
                        if activeSkills.X then
                            vim:SendKeyEvent(true, Enum.KeyCode.X, false, game)
                            task.wait(0.15)
                            vim:SendKeyEvent(false, Enum.KeyCode.X, false, game)
                            task.wait(0.2)
                        end
                        if activeSkills.C then
                            vim:SendKeyEvent(true, Enum.KeyCode.C, false, game)
                            task.wait(0.15)
                            vim:SendKeyEvent(false, Enum.KeyCode.C, false, game)
                            task.wait(0.2)
                        end
                        if activeSkills.V then
                            vim:SendKeyEvent(true, Enum.KeyCode.V, false, game)
                            task.wait(0.15)
                            vim:SendKeyEvent(false, Enum.KeyCode.V, false, game)
                            task.wait(0.2)
                        end
                        
                        task.wait(1.5)
                        -- Re-equip original tool
                        if origTool and origTool.Parent ~= char then
                            local hum = char:FindFirstChildOfClass("Humanoid")
                            if hum then hum:UnequipTools() end
                            origTool.Parent = char
                        end
                    end)
                end)
            end

            local char = LocalPlayer.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then return end
            local playerHRP = char.HumanoidRootPart

            local targetMobs = {}
            if bossMob ~= "CHECKING" then
                if bossData and typeof(bossMob) == "Instance" then
                    table.insert(targetMobs, bossMob)
                else
                    local enemies = workspace:FindFirstChild("Enemies") and workspace.Enemies:GetChildren() or {}
                    
                    -- Detect target mobs map-wide so player directly tweens to live NPCs
                    for i = 1, #enemies do
                        local mob = enemies[i]
                        if mob:FindFirstChild("HumanoidRootPart") and mob:FindFirstChildOfClass("Humanoid") and mob.Humanoid.Health > 0 then
                            if mob.Name == exactMobName or string.find(mob.Name, "^" .. exactMobName .. " ") then
                                table.insert(targetMobs, mob)
                            end
                        end
                    end
                end
            end

            local lowestHealthPercent = 100
            for i = 1, #targetMobs do
                local m = targetMobs[i]
                if m:FindFirstChild("Humanoid") then
                    local hpPct = (m.Humanoid.Health / m.Humanoid.MaxHealth) * 100
                    if hpPct < lowestHealthPercent then lowestHealthPercent = hpPct end
                end
            end

            local weaponToEquip = selectedWeaponType
            if isAutoMasteryOn then
                if lowestHealthPercent > 10 then
                    weaponToEquip = "Melee"
                else
                    weaponToEquip = selectedMasteryWeapon
                    
                    if tick() - lastMasterySkillTime > 2 then
                        lastMasterySkillTime = tick()
                        task.spawn(function()
                            pcall(function()
                                local vim = game:GetService("VirtualInputManager")
                                vim:SendKeyEvent(true, Enum.KeyCode.Z, false, game) task.wait(0.15) vim:SendKeyEvent(false, Enum.KeyCode.Z, false, game) task.wait(0.2)
                                vim:SendKeyEvent(true, Enum.KeyCode.X, false, game) task.wait(0.15) vim:SendKeyEvent(false, Enum.KeyCode.X, false, game) task.wait(0.2)
                                vim:SendKeyEvent(true, Enum.KeyCode.C, false, game) task.wait(0.15) vim:SendKeyEvent(false, Enum.KeyCode.C, false, game) task.wait(0.2)
                                vim:SendKeyEvent(true, Enum.KeyCode.V, false, game) task.wait(0.15) vim:SendKeyEvent(false, Enum.KeyCode.V, false, game)
                            end)
                        end)
                    end
                end
            end

            if tick() - lastToolRefresh > 5 then
                lastToolRefresh = tick()
                autoEquipSelectedWeapon(weaponToEquip)
            end

            local activeTool = autoEquipSelectedWeapon(weaponToEquip)

            local bv = getTabBV(playerHRP)
            bv.Velocity = Vector3.zero

            local bv = getTabBV(playerHRP)
            bv.Velocity = Vector3.zero

            -- COMBAT MODE & MOB SPAWNER DIRECT TARGETING (ZERO ISLAND CENTER TWEENS AT ALL LEVELS)
            local mobSpawners = getSpawnersForMob(exactMobName)
            local spawnerCF = (#mobSpawners > 0) and mobSpawners[1] or nil
            local farmDist = math.max(_G.ENI_FarmDistance or 10.0, 10.0)

            if #targetMobs > 0 then
                local firstMobHRP = targetMobs[1]:FindFirstChild("HumanoidRootPart")
                if firstMobHRP then
                    local targetMobCF = CFrame.new(firstMobHRP.Position + Vector3.new(0, farmDist, 0))
                    local distToMob = (playerHRP.Position - targetMobCF.Position).Magnitude

                    -- If > 12 studs away, fly smoothly directly to target NPC model!
                    if distToMob > 12 then
                        farmStatusLabel.Text = string.format("Lvl %d | Flying to %s NPC...", currentLevel, displayName)
                        if not isTraveling then
                            safeTweenToIsland(targetMobCF)
                        end
                        return
                    else
                        -- Arrived within combat range: cancel travel tween immediately and snap into exact distance position
                        if isTraveling or (_G.ENI_TravelTween and _G.ENI_TravelTween.PlaybackState == Enum.PlaybackState.Playing) then
                            if _G.ENI_TravelTween then pcall(function() _G.ENI_TravelTween:Cancel() end) _G.ENI_TravelTween = nil end
                            isTraveling = false
                        end
                        playerHRP.CFrame = playerHRP.CFrame:Lerp(targetMobCF, 0.12)
                    end
                end

                -- Bring all target mobs to stack point (gentle slerp bringing to prevent server desync & freeze)
                local bringCF = playerHRP.CFrame * CFrame.new(0, -farmDist, 0)
                local now = tick()

                for i = 1, #targetMobs do
                    local mob = targetMobs[i]
                    local mobHRP = mob:FindFirstChild("HumanoidRootPart")
                    local mobHum = mob:FindFirstChildOfClass("Humanoid")
                    
                    if mobHRP and mobHum and mobHum.Health > 0 then
                        pcall(function()
                            local distToStack = (mobHRP.Position - bringCF.Position).Magnitude
                            
                            -- Skip bringing if mob is too far away to prevent physics freeze and network desync
                            if distToStack > 350 then
                                return
                            end
                            
                            -- Anti-Lock Watchdog: Track if mob is stuck/unhittable for > 3 seconds
                            local bringStart = mob:GetAttribute("ENI_BringStart") or now
                            if not mob:GetAttribute("ENI_BringStart") then
                                mob:SetAttribute("ENI_BringStart", now)
                            end

                            local lastHealth = mob:GetAttribute("ENI_LastHP") or mobHum.Health
                            if mobHum.Health < lastHealth then
                                mob:SetAttribute("ENI_LastHP", mobHum.Health)
                                mob:SetAttribute("ENI_BringStart", now) -- Reset timer when damage is taking place!
                            end

                            -- If mob is frozen/unhittable for > 3.0s, momentarily release it so physics syncs!
                            if now - bringStart > 3.0 then
                                mob:SetAttribute("ENI_BringStart", now)
                                for _, part in ipairs(mob:GetChildren()) do
                                    if part:IsA("BasePart") then part.CanCollide = true end
                                end
                                mobHum.PlatformStand = false
                                mobHum.WalkSpeed = 16
                                mobHum.JumpPower = 50
                            else
                                -- Normal Bring: Smoothly lerp HRP position to stack point
                                if distToStack > 2.5 then
                                    mobHRP.CFrame = mobHRP.CFrame:Lerp(bringCF, 0.35)
                                end

                                mobHRP.Velocity = Vector3.zero
                                mobHRP.RotVelocity = Vector3.zero
                                if mobHRP:IsA("BasePart") then
                                    mobHRP.AssemblyLinearVelocity = Vector3.zero
                                    mobHRP.AssemblyAngularVelocity = Vector3.zero
                                end
                                
                                -- Disable collision so mobs stack neatly without clipping
                                for _, part in ipairs(mob:GetChildren()) do
                                    if part:IsA("BasePart") then
                                        part.CanCollide = false
                                    end
                                end

                                mobHum.PlatformStand = true
                                mobHum.WalkSpeed = 0
                                mobHum.JumpPower = 0
                            end
                        end)
                    end
                end

                farmStatusLabel.Text = string.format("Lvl %d | Farming %d %s (Multi-NPC Fast Hit Engine)", currentLevel, #targetMobs, targetMobs[1].Name)

                -- BLOX FRUIT & WEAPON PURE MULTI-TARGET FAST ATTACK ENGINE
                if activeTool then
                    pcall(function()
                        local hitList = {}
                        local now = tick()

                        for i = 1, math.min(#targetMobs, 15) do
                            local mob = targetMobs[i]
                            local mHrp = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChild("Head")
                            local mHum = mob:FindFirstChildOfClass("Humanoid")
                            
                            if mHrp and mHum and mHum.Health > 0 then
                                local distFromPlayer = (mHrp.Position - playerHRP.Position).Magnitude
                                if distFromPlayer <= (farmDist + 18) then
                                    table.insert(hitList, {mob, mHrp})
                                end
                            end
                        end
                        
                        if #hitList > 0 and (now - (lastFarmHit or 0) >= 0.08) then
                            lastFarmHit = now
                            local primaryHRP = hitList[1][2]
                            _G.ENI_PerformFastAttack(hitList, primaryHRP)
                        end
                    end)
                end
            else
                -- ZERO MOBS ALIVE: Stay stationary at current spawner node. ZERO island center tweens!
                groundCFrame = nil
                
                if spawnerCF then
                    local spawnerTargetCF = spawnerCF * CFrame.new(0, farmDist, 0)
                    local distToSpawner = (playerHRP.Position - spawnerTargetCF.Position).Magnitude

                    if distToSpawner > 15 then
                        farmStatusLabel.Text = "Lvl " .. currentLevel .. " | Flying smoothly to " .. displayName .. " spawner..."
                        if not isTraveling then
                            safeTweenToIsland(spawnerTargetCF)
                        end
                    else
                        if isTraveling or (_G.ENI_TravelTween and _G.ENI_TravelTween.PlaybackState == Enum.PlaybackState.Playing) then
                            if _G.ENI_TravelTween then pcall(function() _G.ENI_TravelTween:Cancel() end) _G.ENI_TravelTween = nil end
                            isTraveling = false
                        end
                        farmStatusLabel.Text = "Lvl " .. currentLevel .. " | Hovering at " .. displayName .. " spawner... Waiting for spawns."
                        playerHRP.CFrame = playerHRP.CFrame:Lerp(spawnerTargetCF, 0.12)
                    end
                else
                    -- If spawner part unstreamed, hold player stationary in place! ZERO TELEPORTING TO ISLAND CENTER!
                    farmStatusLabel.Text = "Lvl " .. currentLevel .. " | Waiting for " .. displayName .. " spawns..."
                end
            end
        end)
    end)
end

-- INDEPENDENT STANDALONE AUTO ROLL RANDOM FRUIT ENGINE (RUNS EVEN IF AUTO FARM IS OFF)
task.spawn(function()
    local lastStandaloneRollTime = 0
    while task.wait(3) do
        if isAutoRollOn and tick() - lastStandaloneRollTime > 30 then
            lastStandaloneRollTime = tick()
            pcall(function()
                local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
                local commF = remotes and remotes:FindFirstChild("CommF_")
                if commF then
                    commF:InvokeServer("Cousin", "Buy")
                    commF:InvokeServer("Cousin", "DLCBoxData")
                    task.wait(1.5)

                    local function storeFruitTool(tool)
                        if not tool then return end
                        local origName = tool:GetAttribute("OriginalName") or tool.Name
                        if origName then
                            commF:InvokeServer("StoreFruit", origName, tool)
                            notifyGUI("FRUIT", "Auto-Stored: " .. tostring(origName), 4)
                        end
                    end

                    local char = LocalPlayer.Character
                    if char then
                        for _, t in ipairs(char:GetChildren()) do
                            if t:IsA("Tool") and (string.find(t.Name, "Fruit") or t:GetAttribute("OriginalName")) then
                                storeFruitTool(t)
                            end
                        end
                    end

                    local bp = LocalPlayer:FindFirstChild("Backpack")
                    if bp then
                        for _, t in ipairs(bp:GetChildren()) do
                            if t:IsA("Tool") and (string.find(t.Name, "Fruit") or t:GetAttribute("OriginalName")) then
                                storeFruitTool(t)
                            end
                        end
                    end
                end
            end)
        end
    end
end)

if Hub and Hub.finishLoading then
    Hub.finishLoading("Loaded")
end

print("[UNKNOWN-HUB] Blox Fruits loaded successfully!")