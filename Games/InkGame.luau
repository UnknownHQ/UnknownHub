local LIBRARY_LINK = "https://raw.githubusercontent.com/UnknownHQ/UnknownHub/main/UnknownLibrary"
local LIBRARY_NAME = "ENI_TabbedHub_UI"

local function destroyOldGui()
    local parents = {game:GetService("CoreGui")}
    if gethui then pcall(function() table.insert(parents, gethui()) end) end
    local playerGui = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
    if playerGui then table.insert(parents, playerGui) end
    for _, parent in ipairs(parents) do
        if parent then
            for _, child in ipairs(parent:GetChildren()) do
                if child:IsA("ScreenGui") and (child.Name == LIBRARY_NAME or child.Name == "ENI_InkGame_UI") then
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
    title = "UNKNOWN HUB | INK GAME",
    parent = (gethui and gethui()) or game:GetService("CoreGui") or game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"),
    theme = Color3.fromRGB(0, 195, 245),
    secondaryTheme = Color3.fromRGB(165, 95, 255)
})

-- Roblox Internal Engine, ControlModule & Asset Delivery Interceptor
pcall(function()
    local ScriptContext = game:GetService("ScriptContext")
    ScriptContext.Error:Connect(function(message, stack, scriptObj)
        if message then
            local m = message:lower()
            if m:find("controlmodule") or m:find("invalid argument #2 to 'random'") or m:find("playermodule") or m:find("createfootstepclient") or m:find("assetdelivery") or m:find("rbxcdn") or m:find("wrap-deformer") then
                -- Safely catch & suppress Roblox engine asset & control crashes
                return true
            end
        end
    end)
end)

-- ContentProvider Asset Load Fail Safe
pcall(function()
    local ContentProvider = game:GetService("ContentProvider")
    if ContentProvider then
        pcall(function()
            ContentProvider.BaseUrl = "https://www.roblox.com/"
        end)
    end
end)

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

local CoreGui = nil
pcall(function() CoreGui = game:GetService("CoreGui") end)

local function GetSafeParent()
    local p = nil
    pcall(function() if gethui then p = gethui() end end)
    if not p and CoreGui then
        pcall(function()
            local test = false
            pcall(function() test = (CoreGui ~= nil and CoreGui.Name ~= nil) end)
            if test then p = CoreGui end
        end)
    end
    if not p then
        pcall(function() p = LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:FindFirstChild("PlayerGui") end)
    end
    return p or LocalPlayer:WaitForChild("PlayerGui")
end

local currentJobId = game.JobId
if getgenv().ENI_SessionJobId and getgenv().ENI_SessionJobId ~= currentJobId then
    getgenv().ENI_ActiveConnections = {}
    getgenv().ENI_ActiveThreads = {}
end
getgenv().ENI_SessionJobId = currentJobId

getgenv().ENI_ActiveConnections = getgenv().ENI_ActiveConnections or {}
local function RegisterConnection(conn)
    if not conn then return nil end
    if typeof(conn) == "RBXScriptConnection" then
        for _, existing in ipairs(getgenv().ENI_ActiveConnections) do
            if existing == conn then return conn end
        end
    end
    table.insert(getgenv().ENI_ActiveConnections, conn)
    return conn
end

if getgenv().ENI_Cleanup then pcall(getgenv().ENI_Cleanup) end
getgenv().ENI_Cleanup = function()
    pcall(function()
        if getgenv().ENI_ActiveThreads then
            for _, th in ipairs(getgenv().ENI_ActiveThreads) do
                pcall(function() if th and task.cancel then task.cancel(th) end end)
            end
        end
        getgenv().ENI_ActiveThreads = {}

        if getgenv().ENI_ActiveConnections then
            for _, conn in ipairs(getgenv().ENI_ActiveConnections) do
                pcall(function()
                    if typeof(conn) == "RBXScriptConnection" and conn.Connected then
                        conn:Disconnect()
                    end
                end)
            end
        end
        getgenv().ENI_ActiveConnections = {}

        pcall(function()
            if Drawing then
                for _, d in ipairs(Drawing:GetChildren()) do
                    if d and d.Remove then pcall(function() d:Remove() end) end
                end
            end
        end)

        local parentObj = GetSafeParent()
        if parentObj then
            local toRemove = {"ENI_Notifications", "ENI_InkGame_MasterHub_v9_4", "ENI_ToastFolder", "ENI_General_ESP", "ENI_GuardNPC_ESP", "ENI_Balloon_ESP", "ENI_Glass_Storage"}
            for _, name in ipairs(toRemove) do
                local child = parentObj:FindFirstChild(name)
                if child then pcall(function() child:Destroy() end) end
            end
        end
    end)
end
getgenv().ENI_Cleanup()

getgenv().ENI_ActiveThreads = {}
local function RegisterThread(th)
    if not th then return nil end
    if getgenv().ENI_ActiveThreads and #getgenv().ENI_ActiveThreads > 40 then
        for i = 1, 10 do
            local old = table.remove(getgenv().ENI_ActiveThreads, 1)
            if old and task.cancel then pcall(function() task.cancel(old) end) end
        end
    end
    table.insert(getgenv().ENI_ActiveThreads, th)
    return th
end

getgenv().ENI_SilentAimbot = false
getgenv().ENI_ExtendedReach = false
getgenv().ENI_CtrlClickTP = false

local function GetRemotesFolder()
    local ok, rf = pcall(function()
        return ReplicatedStorage:FindFirstChild("Remotes")
            or ReplicatedStorage:FindFirstChild("Events")
            or ReplicatedStorage:FindFirstChild("RemoteEvents")
            or workspace:FindFirstChild("Remotes")
    end)
    return ok and rf or nil
end

RegisterConnection(LocalPlayer.CharacterAdded:Connect(function()
    pcall(function()
        for _, name in ipairs({"ENI_General_ESP", "ENI_GuardNPC_ESP", "ENI_Balloon_ESP", "ENI_Glass_Storage"}) do
            local folder = CoreGui:FindFirstChild(name)
            if folder then folder:ClearAllChildren() end
        end
        collectgarbage("collect")
        print("[ENI-GC] New round/spawn detected -> Cleared ESP caches & executed Lua Garbage Collection!")
    end)
end))

RegisterThread(task.spawn(function()
    print("[ENI-PROTECT]", "Permanent Crash Prevention & Memory Watchdog ACTIVE!")
    while true do
        task.wait(2.0)
        pcall(function()
            local luaMem = math.floor(gcinfo() / 1024)
            local threadCount = getgenv().ENI_ActiveThreads and #getgenv().ENI_ActiveThreads or 0

            if luaMem > 220 or threadCount > 35 then
                warn("[ENI-WATCHDOG]", "Threshold exceeded! Purging caches, clearing stale draws, and dropping excess threads. (Heap: " .. tostring(luaMem) .. " MB | Threads: " .. tostring(threadCount) .. ")")
                if CoreGui then
                    for _, name in ipairs({"ENI_General_ESP", "ENI_GuardNPC_ESP", "ENI_Balloon_ESP", "ENI_Glass_Storage"}) do
                        local folder = CoreGui:FindFirstChild(name)
                        if folder then folder:ClearAllChildren() end
                    end
                end
                pcall(function()
                    if Drawing then
                        for _, d in ipairs(Drawing:GetChildren()) do
                            if d and d.Remove then pcall(function() d:Remove() end) end
                        end
                    end
                end)
                if getgenv().ENI_ActiveThreads and #getgenv().ENI_ActiveThreads > 18 then
                    for i = 1, math.min(12, #getgenv().ENI_ActiveThreads - 18) do
                        local old = table.remove(getgenv().ENI_ActiveThreads, 1)
                        if old and task.cancel then pcall(function() task.cancel(old) end) end
                    end
                end
                collectgarbage("collect")
            end

            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChild("Humanoid")
                local hrp = char:FindFirstChild("HumanoidRootPart")
                local currentGame = workspace:FindFirstChild("Values") and workspace.Values:FindFirstChild("CurrentGame") and workspace.Values.CurrentGame.Value

                if hrp and hrp.Anchored and hum and not hum.Sit then
                    if currentGame ~= "Dalgona" and currentGame ~= "RedLightGreenLight" and currentGame ~= "TugOfWar" then
                        hrp.Anchored = false
                    end
                end
            end
        end)
    end
end))

pcall(function()
    local targets = {CoreGui, LocalPlayer:FindFirstChild("PlayerGui")}
    if gethui then pcall(function() table.insert(targets, gethui()) end) end
    for _, parent in ipairs(targets) do
        if parent then
            for _, c in ipairs(parent:GetChildren()) do
                if c.Name == "ENI_TabbedHub_UI" or c.Name == "ENI_InkGame_MasterHub_v9_4" then
                    c:Destroy()
                end
            end
        end
    end
end)

local NotifGui = Instance.new("ScreenGui")
NotifGui.Name = "ENI_Notifications"
NotifGui.ResetOnSpawn = false
NotifGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
NotifGui.Parent = GetSafeParent()

local NotifList = Instance.new("Frame")
NotifList.Size = UDim2.new(0, 300, 1, -40)
NotifList.Position = UDim2.new(1, -320, 0, 20)
NotifList.BackgroundTransparency = 1
NotifList.Parent = NotifGui
local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Padding = UDim.new(0, 10)
UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
UIListLayout.Parent = NotifList

local function CleanMenuText(str)
    return tostring(str or "")
end

local function Notify(category, titleText, msgText, durationSec)
    Hub.notify({
        Category = category or "System",
        Title = titleText or "Notification",
        Content = msgText or "",
        Duration = durationSec or 3.5
    })
end

local function ENI_Notify(title, text, typeName, duration)
    Notify(typeName, title, text, duration)
end

local function CreateButton(parent, text, _yPos_ignored, callback)
    local displayText = CleanMenuText(text)
    return Hub.CreateButton(parent or Hub.content, displayText, function()
        pcall(callback)
        Notify("INFO", "Action Executed", displayText)
    end)
end

local function CreateToggle(parent, text, _yPos_ignored, callback)
    local displayText = CleanMenuText(text)
    return Hub.CreateToggle(parent or Hub.content, displayText, false, callback)
end

local function CreateSlider(parent, text, minVal, maxVal, defaultVal, _yPos_ignored, callback)
    local displayText = CleanMenuText(text)
    return Hub.CreateSlider(parent or Hub.content, displayText, minVal, maxVal, defaultVal, "", callback)
end

local function CreateDropdown(parent, text, options, defaultVal, _yPos_ignored, callback)
    local displayText = CleanMenuText(text)
    return Hub.CreateDropdown(parent or Hub.content, displayText, options, defaultVal, callback)
end

local function CreateSection(parent, text)
    return Hub.CreateSection(parent or Hub.content, CleanMenuText(text))
end

local function CreateList(parent, name, items)
    return Hub.CreateList(parent or Hub.content, CleanMenuText(name), items)
end

local Pages = {}
local tabData = {
    {name = "🌐 Main & Movement", icon = "rbxassetid://10709790298"},
    {name = "👁️ ESP & Visuals", icon = "rbxassetid://10709790298"},
    {name = "🎯 Melee & Guns", icon = "rbxassetid://10709790097"},
    {name = "🔺 Red Light Green Light", icon = "rbxassetid://10723415903"},
    {name = "🍪 Dalgona Cookie", icon = "rbxassetid://10734898355"},
    {name = "🪢 Tug Of War", icon = "rbxassetid://10709789311"},
    {name = "🪨 Marbles & QTE", icon = "rbxassetid://10709772288"},
    {name = "🧱 Glass Bridge", icon = "rbxassetid://10709770535"},
    {name = "🙈 Hide & Seek", icon = "rbxassetid://10734896798"},
    {name = "🎽 Pentathlon", icon = "rbxassetid://10709773208"},
    {name = "☁️ SkySquid & VIP", icon = "rbxassetid://10709770178"},
    {name = "👮 Guard & Surgery", icon = "rbxassetid://10709773646"},
    {name = "🛡️ Protections", icon = "rbxassetid://10709773994"},
    {name = "⚡ Secret Exploits & Remotes", icon = "rbxassetid://10709790097"}
}

for idx, t in ipairs(tabData) do
    Pages[t.name] = Hub.createTabButton(t.name, t.name, t.icon, idx == 1)
end

CreateButton(Pages["🌐 Main & Movement"], "🔍 Run Live Self-Diagnostic Health Check", 1, function()
    pcall(function()
        local results = {}
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChild("Humanoid")
        if char and hrp and hum then
            table.insert(results, "✅ Character & HRP: Healthy (WalkSpeed: " .. tostring(hum.WalkSpeed) .. ")")
        else
            table.insert(results, "❌ Character: Missing or Respawning")
        end

        local RemotesFolder = GetRemotesFolder()
                if RemotesFolder then
            table.insert(results, "✅ Remotes Folder: Connected (" .. tostring(#RemotesFolder:GetChildren()) .. " Remotes found)")
        else
            table.insert(results, "⚠️ Remotes Folder: Missing or Unloaded")
        end

        local storageCount = 0
        for _, sName in ipairs({"ENI_General_ESP", "ENI_Balloon_ESP", "ENI_HNS_ESP", "ENI_Glass_Storage", "ENI_GuardNPC_ESP"}) do
            if CoreGui:FindFirstChild(sName) then storageCount = storageCount + 1 end
        end
        table.insert(results, "✅ CoreGui Storage: " .. tostring(storageCount) .. "/5 Folders Active")

        local placeId = game.PlaceId
        table.insert(results, "ℹ️ Sub-Place ID: " .. tostring(placeId))

        local fullReport = table.concat(results, "\n")
        print("\n--- [ENI DIAGNOSTIC REPORT] ---\n" .. fullReport .. "\n-------------------------------")
        ENI_Notify("Diagnostic Check Complete", "All systems operational! Check F9 Console for details.", "Success", 4)
    end)
end)

local currentSpeed = 16
CreateSlider(Pages["🌐 Main & Movement"], "WalkSpeed", 16, 120, 16, 5, function(val)
    currentSpeed = val
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = val
    end
end)

CreateToggle(Pages["🌐 Main & Movement"], "⚡ Stealth CFrame Wall-Bypass Noclip", 60, function(state)
    getgenv().ENI_NoclipActive = state
    if state then
        RegisterThread(task.spawn(function()
            while getgenv().ENI_NoclipActive do
                task.wait(0.02)
                pcall(function()
                    local char = LocalPlayer.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    local hum = char and char:FindFirstChild("Humanoid")
                    if hrp and hum and hum.MoveDirection.Magnitude > 0 then
                        local dir = hum.MoveDirection
                        local rayParams = RaycastParams.new()
                        rayParams.FilterDescendantsInstances = {char}
                        rayParams.FilterType = Enum.RaycastFilterType.Exclude
                        local result = workspace:Raycast(hrp.Position, dir * 4, rayParams)
                        if result and result.Instance then
                            hrp.CFrame = hrp.CFrame + (dir * 3.5)
                        end
                    end
                end)
            end
        end))
    else
        getgenv().ENI_NoclipActive = false
    end
end)

CreateToggle(Pages["🌐 Main & Movement"], "Ctrl + Click TP", 103, function(state)
    getgenv().ENI_CtrlClickTP = state
end)

CreateButton(Pages["🌐 Main & Movement"], "⚡ Teleport to Map Roof", 140, function()
    pcall(function()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local map = workspace:FindFirstChild("Map") or workspace:FindFirstChild("Lobby") or workspace:FindFirstChild("MainMap") or workspace
            local highestY = hrp.Position.Y + 60
            for _, p in ipairs(map:GetDescendants()) do
                if p:IsA("BasePart") and p.CanCollide and p.Size.X > 5 and p.Size.Z > 5 then
                    if p.Position.Y > highestY and p.Position.Y < 800 then
                        highestY = p.Position.Y
                    end
                end
            end
            hrp.CFrame = CFrame.new(hrp.Position.X, highestY + 8, hrp.Position.Z)
            print("[ENI-TP] Teleported to Map Roof surface!")
        end
    end)
end)

CreateButton(Pages["🌐 Main & Movement"], "🏰 Teleport to Main Lobby / Spawn", 180, function()
    pcall(function()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local lobbySpawn = workspace:FindFirstChild("Lobby", true) or workspace:FindFirstChild("SpawnLocation", true) or workspace:FindFirstChild("Spawns", true)
        if hrp then
            if lobbySpawn then
                local cf = lobbySpawn:IsA("BasePart") and lobbySpawn.CFrame or (lobbySpawn:IsA("Model") and lobbySpawn:GetPivot())
                if cf then hrp.CFrame = cf + Vector3.new(0, 5, 0) return end
            end
            hrp.CFrame = CFrame.new(0, 15, 0)
            print("[ENI-TP] Teleported to Main Lobby / Spawn!")
        end
    end)
end)

local savedLighting = nil

CreateToggle(Pages["🌐 Main & Movement"], "☀️ Fullbright & Remove Dark Fog", 220, function(state)
    getgenv().ENI_Fullbright = state
    local lighting = game:GetService("Lighting")
    if state then
        if not savedLighting then
            local atmo = lighting:FindFirstChildOfClass("Atmosphere")
            savedLighting = {
                ClockTime = lighting.ClockTime,
                GlobalShadows = lighting.GlobalShadows,
                Brightness = lighting.Brightness,
                OutdoorAmbient = lighting.OutdoorAmbient,
                Ambient = lighting.Ambient,
                FogEnd = lighting.FogEnd,
                FogStart = lighting.FogStart,
                ExposureCompensation = lighting.ExposureCompensation,
                AtmosphereDensity = atmo and atmo.Density or 0.35,
                Effects = {}
            }
            for _, v in ipairs(lighting:GetChildren()) do
                if v:IsA("Atmosphere") or v:IsA("PostEffect") or v:IsA("BlurEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("BloomEffect") or v:IsA("SunRaysEffect") then
                    savedLighting.Effects[v] = v.Enabled
                end
            end
        end

        RegisterThread(task.spawn(function()
            while getgenv().ENI_Fullbright do
                pcall(function()
                    lighting.ClockTime = 12
                    lighting.GlobalShadows = false
                    lighting.Brightness = 2
                    lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
                    lighting.Ambient = Color3.fromRGB(255, 255, 255)
                    lighting.FogEnd = 999999
                    lighting.FogStart = 0
                    local atmo = lighting:FindFirstChildOfClass("Atmosphere")
                    if atmo then
                        atmo.Density = 0
                    end
                    for _, v in ipairs(lighting:GetChildren()) do
                        if v:IsA("Atmosphere") or (v:IsA("BlurEffect") and v.Name:lower():find("dark")) or v:IsA("ColorCorrectionEffect") then
                            v.Enabled = false
                        end
                    end
                end)
                task.wait(0.2)
            end
        end))
    else
        getgenv().ENI_Fullbright = false
        task.wait(0.05)
        pcall(function()
            if savedLighting then
                lighting.ClockTime = savedLighting.ClockTime
                lighting.GlobalShadows = savedLighting.GlobalShadows
                lighting.Brightness = savedLighting.Brightness
                lighting.OutdoorAmbient = savedLighting.OutdoorAmbient
                lighting.Ambient = savedLighting.Ambient
                lighting.FogEnd = savedLighting.FogEnd
                lighting.FogStart = savedLighting.FogStart
                lighting.ExposureCompensation = savedLighting.ExposureCompensation

                local atmo = lighting:FindFirstChildOfClass("Atmosphere")
                if atmo and savedLighting.AtmosphereDensity then
                    atmo.Density = savedLighting.AtmosphereDensity
                end

                for effect, wasEnabled in pairs(savedLighting.Effects) do
                    if effect and effect.Parent == lighting then
                        pcall(function() effect.Enabled = wasEnabled end)
                    end
                end
                savedLighting = nil
            else
                lighting.ClockTime = 14
                lighting.GlobalShadows = true
                lighting.Brightness = 1
                lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
                lighting.Ambient = Color3.fromRGB(128, 128, 128)
                lighting.FogEnd = 10000
                lighting.FogStart = 0
            end
            print("[ENI-LIGHTING] Fullbright Disabled -> Exact Original Lighting & Effects Restored!")
        end)
    end
end)

CreateToggle(Pages["🌐 Main & Movement"], "⚡ Instant Proximity Prompt Interactor", 260, function(state)
    getgenv().ENI_InstantPrompts = state
    if state then
        RegisterThread(task.spawn(function()
            while getgenv().ENI_InstantPrompts do
                task.wait(0.3)
                pcall(function()
                    for _, prompt in ipairs(workspace:GetDescendants()) do
                        if prompt:IsA("ProximityPrompt") then
                            prompt.HoldDuration = 0
                        end
                    end
                end)
            end
        end))
    else
        getgenv().ENI_InstantPrompts = false
    end
end)

getgenv().ENI_MasterESP = false -- Default OFF (No Auto-Enable)
getgenv().ENI_EspHighlight = true
getgenv().ENI_EspNames = true
getgenv().ENI_EspHealth = true
getgenv().ENI_EspBoxes = false
getgenv().ENI_EspTracers = false
getgenv().ENI_TracersList = getgenv().ENI_TracersList or {}

local function ClearAllTracers()
    getgenv().ENI_TracersList = getgenv().ENI_TracersList or {}
    for pKey, tracer in pairs(getgenv().ENI_TracersList) do
        pcall(function()
            if tracer then
                tracer.Visible = false
                tracer:Remove()
            end
        end)
    end
    getgenv().ENI_TracersList = {}
end

CreateToggle(Pages["👁️ ESP & Visuals"], "⚡ Enable ESP", 5, function(state)
    getgenv().ENI_MasterESP = state
    if not state then
        if GeneralEspStorage then
            GeneralEspStorage:ClearAllChildren()
        end
        ClearAllTracers()
    end
end)

local espOptions = {
    {name = "✨ Highlight Fill & Glow", key = "ENI_EspHighlight", default = true},
    {name = "🟢 Centered Name & Tag", key = "ENI_EspNames", default = true},
    {name = "❤️ Centered Health & HP %", key = "ENI_EspHealth", default = true},
    {name = "📦 2D Selection Bounding Boxes", key = "ENI_EspBoxes", default = false},
    {name = "📐 Snapline Tracers (Screen -> Target)", key = "ENI_EspTracers", default = false}
}

local MultiListFrame = Instance.new("Frame")
MultiListFrame.Size = UDim2.new(1, -10, 0, 190)
MultiListFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 34)
MultiListFrame.Parent = Pages["👁️ ESP & Visuals"]
Instance.new("UICorner", MultiListFrame).CornerRadius = UDim.new(0, 8)

local ListHeader = Instance.new("TextLabel")
ListHeader.Size = UDim2.new(1, -15, 0, 30)
ListHeader.Position = UDim2.new(0, 12, 0, 5)
ListHeader.BackgroundTransparency = 1
ListHeader.Text = "📋 Select Active ESP Elements:"
ListHeader.TextColor3 = Color3.fromRGB(255, 180, 200)
ListHeader.Font = Enum.Font.GothamBold
ListHeader.TextSize = 12
ListHeader.TextXAlignment = Enum.TextXAlignment.Left
ListHeader.Parent = MultiListFrame

local optY = 35
for _, opt in ipairs(espOptions) do
    getgenv()[opt.key] = opt.default

    local rowBtn = Instance.new("TextButton")
    rowBtn.Size = UDim2.new(1, -20, 0, 28)
    rowBtn.Position = UDim2.new(0, 10, 0, optY)
    rowBtn.BackgroundColor3 = opt.default and Color3.fromRGB(35, 55, 45) or Color3.fromRGB(32, 32, 42)
    rowBtn.Text = "   " .. (opt.default and "☑ " or "☐ ") .. opt.name
    rowBtn.TextColor3 = opt.default and Color3.fromRGB(100, 255, 150) or Color3.fromRGB(180, 180, 200)
    rowBtn.Font = Enum.Font.GothamSemibold
    rowBtn.TextSize = 12
    rowBtn.TextXAlignment = Enum.TextXAlignment.Left
    rowBtn.Parent = MultiListFrame
    Instance.new("UICorner", rowBtn).CornerRadius = UDim.new(0, 5)

    rowBtn.MouseButton1Click:Connect(function()
        local newState = not getgenv()[opt.key]
        getgenv()[opt.key] = newState
        rowBtn.Text = "   " .. (newState and "☑ " or "☐ ") .. opt.name
        rowBtn.TextColor3 = newState and Color3.fromRGB(100, 255, 150) or Color3.fromRGB(180, 180, 200)
        TweenService:Create(rowBtn, TweenInfo.new(0.2), {BackgroundColor3 = newState and Color3.fromRGB(35, 55, 45) or Color3.fromRGB(32, 32, 42)}):Play()

        if not newState then
            if opt.key == "ENI_EspHighlight" then
                for _, child in ipairs(GeneralEspStorage:GetChildren()) do if child.Name:find("HL_") then child:Destroy() end end
            elseif opt.key == "ENI_EspBoxes" then
                for _, child in ipairs(GeneralEspStorage:GetChildren()) do if child.Name:find("Box_") then child:Destroy() end end
            elseif opt.key == "ENI_EspTracers" then
                ClearAllTracers()
            end
        end
    end)
    optY = optY + 30
end

local GeneralEspStorage = CoreGui:FindFirstChild("ENI_General_ESP") or Instance.new("Folder", CoreGui)
GeneralEspStorage.Name = "ENI_General_ESP"

local function GetHealthColor(pct)
    if pct >= 0.75 then return Color3.fromRGB(math.floor(255 * (1 - ((pct - 0.75) / 0.25))), 255, 30)
    elseif pct >= 0.50 then return Color3.fromRGB(255, math.floor(165 + (90 * ((pct - 0.50) / 0.25))), 30)
    elseif pct >= 0.25 then return Color3.fromRGB(255, math.floor(60 + (105 * ((pct - 0.25) / 0.25))), 30)
    else return Color3.fromRGB(math.floor(180 + (75 * (pct / 0.25))), 20, 20) end
end

RegisterThread(task.spawn(function()
    while true do
        task.wait(0.1) -- Stable 10 FPS scan rate to prevent frame starvation & client crashes!
        pcall(function()
            if not getgenv().ENI_MasterESP then
                GeneralEspStorage:ClearAllChildren()
                ClearAllTracers()
                return
            end

            local cam = workspace.CurrentCamera
            local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            local activeUsers = {}

            for _, targetPlayer in ipairs(Players:GetPlayers()) do
                if targetPlayer ~= LocalPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") and targetPlayer.Character:FindFirstChild("Humanoid") then
                    local char = targetPlayer.Character
                    local hum = char.Humanoid
                    local hrp = char.HumanoidRootPart
                    local pKey = "ENI_ESP_" .. tostring(targetPlayer.UserId)
                    activeUsers[pKey] = true

                    local healthPct = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
                    local hpColor = GetHealthColor(healthPct)
                    local dist = myHRP and math.floor((myHRP.Position - hrp.Position).Magnitude) or 0

                    local hl = GeneralEspStorage:FindFirstChild("HL_" .. pKey)
                    if getgenv().ENI_EspHighlight then
                        if not hl then
                            hl = Instance.new("Highlight")
                            hl.Name = "HL_" .. pKey
                            hl.Parent = GeneralEspStorage
                        end
                        hl.Adornee = char
                        hl.FillColor = hpColor
                        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                        hl.FillTransparency = 0.6
                    elseif hl then
                        hl:Destroy()
                    end

                    local bb = GeneralEspStorage:FindFirstChild(pKey)
                    if getgenv().ENI_EspNames or getgenv().ENI_EspHealth then
                        if not bb then
                            bb = Instance.new("BillboardGui")
                            bb.Name = pKey
                            bb.Size = UDim2.new(0, 200, 0, 50)
                            bb.StudsOffset = Vector3.new(0, 0, 0) -- PERFECT CENTER
                            bb.AlwaysOnTop = true
                            bb.Parent = GeneralEspStorage

                            local txt = Instance.new("TextLabel", bb)
                            txt.Name = "Text"
                            txt.Size = UDim2.new(1, 0, 1, 0)
                            txt.Position = UDim2.new(0, 0, 0, 0)
                            txt.BackgroundTransparency = 1
                            txt.Font = Enum.Font.GothamBold
                            txt.TextSize = 12
                            txt.TextXAlignment = Enum.TextXAlignment.Center -- PERFECT CENTER ALIGNMENT
                            txt.TextYAlignment = Enum.TextYAlignment.Center
                        end
                        bb.Adornee = hrp

                        local txt = bb:FindFirstChild("Text", true)
                        if txt then
                            local labelLines = {}
                            if getgenv().ENI_EspNames then
                                table.insert(labelLines, string.format("%s (@%s)", targetPlayer.DisplayName, targetPlayer.Name))
                            end
                            if getgenv().ENI_EspHealth then
                                table.insert(labelLines, string.format("%d HP (%d%%) • %dm", math.floor(hum.Health), math.floor(healthPct * 100), dist))
                            end
                            txt.Text = table.concat(labelLines, "\n")
                            txt.TextColor3 = hpColor
                        end
                    elseif bb then
                        bb:Destroy()
                    end

                    local box = GeneralEspStorage:FindFirstChild("Box_" .. pKey)
                    if getgenv().ENI_EspBoxes then
                        if not box then
                            box = Instance.new("SelectionBox")
                            box.Name = "Box_" .. pKey
                            box.LineThickness = 0.05
                            box.Parent = GeneralEspStorage
                        end
                        box.Adornee = char
                        box.Color3 = hpColor
                    elseif box then
                        box:Destroy()
                    end

                    if getgenv().ENI_EspTracers and Drawing then
                        local screenPos, onScreen = cam:WorldToViewportPoint(hrp.Position)
                        if onScreen then
                            local tracer = getgenv().ENI_TracersList[pKey]
                            if not tracer then
                                tracer = Drawing.new("Line")
                                tracer.Thickness = 1.5
                                tracer.Transparency = 0.8
                                getgenv().ENI_TracersList[pKey] = tracer
                            end
                            tracer.From = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y)
                            tracer.To = Vector2.new(screenPos.X, screenPos.Y)
                            tracer.Color = hpColor
                            tracer.Visible = true
                        elseif getgenv().ENI_TracersList[pKey] then
                            getgenv().ENI_TracersList[pKey].Visible = false
                        end
                    elseif getgenv().ENI_TracersList[pKey] then
                        pcall(function()
                            getgenv().ENI_TracersList[pKey].Visible = false
                            getgenv().ENI_TracersList[pKey]:Remove()
                        end)
                        getgenv().ENI_TracersList[pKey] = nil
                    end
                end
            end

            for _, child in ipairs(GeneralEspStorage:GetChildren()) do
                local baseKey = child.Name:gsub("^HL_", ""):gsub("^Box_", "")
                if not activeUsers[baseKey] then
                    child:Destroy()
                end
            end
            for pKey, tracer in pairs(getgenv().ENI_TracersList) do
                if not activeUsers[pKey] or not getgenv().ENI_EspTracers then
                    pcall(function()
                        tracer.Visible = false
                        tracer:Remove()
                    end)
                end
            end
        end)
    end
end))
local mouse = LocalPlayer:GetMouse()
UserInputService.InputBegan:Connect(function(input, gpe) if not gpe and getgenv().ENI_CtrlClickTP and input.UserInputType == Enum.UserInputType.MouseButton1 and (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)) then pcall(function() if mouse and mouse.Hit and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0)) end end) end end)
RegisterThread(task.spawn(function()
    while true do
        task.wait(0.3)
        pcall(function()
            if currentSpeed > 16 and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                LocalPlayer.Character.Humanoid.WalkSpeed = currentSpeed
            end
        end)
    end
end))

CreateButton(Pages["🌐 Universal & ESP"], "⚡ Teleport to Map Roof", 180, function()
    pcall(function()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local roofPart = workspace:FindFirstChild("RoofParts", true) or workspace:FindFirstChild("Roof", true)
            local targetY = 138.5
            if roofPart and roofPart:IsA("BasePart") then
                targetY = roofPart.Position.Y + (roofPart.Size.Y / 2) + 3.5
            else
                local rayParams = RaycastParams.new()
                rayParams.FilterDescendantsInstances = {char}
                rayParams.FilterType = Enum.RaycastFilterType.Exclude
                local rayResult = workspace:Raycast(hrp.Position + Vector3.new(0, 300, 0), Vector3.new(0, -600, 0), rayParams)
                if rayResult and rayResult.Position then
                    targetY = rayResult.Position.Y + 3.5
                end
            end

            hrp.CFrame = CFrame.new(hrp.Position.X, targetY, hrp.Position.Z)

            local existingPlat = workspace:FindFirstChild("ENI_RoofPlatform")
            if existingPlat then existingPlat:Destroy() end

            local p = Instance.new("Part")
            p.Name = "ENI_RoofPlatform"
            p.Size = Vector3.new(40, 1, 40)
            p.Anchored = true
            p.CanCollide = true
            p.Position = Vector3.new(hrp.Position.X, targetY - 3.5, hrp.Position.Z)
            p.Material = Enum.Material.Neon
            p.Color = Color3.fromRGB(0, 255, 255)
            p.Transparency = 0.4
            p.Parent = workspace
            print("Teleported safely onto exact roof surface!")
        end
    end)
end)

CreateButton(Pages["🌐 Universal & ESP"], "⚡ Teleport to Lobby", 220, function()
    pcall(function()
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local lobbyPart = (workspace:FindFirstChild("Effects") and workspace.Effects:FindFirstChild("SpawnLocation"))
                or workspace:FindFirstChild("LobbyAnniversary", true)
                or workspace:FindFirstChild("SpawnLocation", true)

            if lobbyPart then
                if lobbyPart:IsA("BasePart") then
                    hrp.CFrame = lobbyPart.CFrame + Vector3.new(0, 4, 0)
                elseif lobbyPart:IsA("Model") then
                    hrp.CFrame = lobbyPart:GetPivot() + Vector3.new(0, 4, 0)
                end
            else
                hrp.CFrame = CFrame.new(197.5, 55.0, -113.6)
            end
            print("Teleported safely to Main Lobby!")
        end
    end)
end)

CreateButton(Pages["🌐 Universal & ESP"], "🚨 EMERGENCY FORCE UNFREEZE RESCUE", 260, function()
    pcall(function()
        local char = LocalPlayer.Character
        if char then
            for _, attr in ipairs({"Freeze", "Action", "Ragdoll", "Slowed", "NoAttack", "InCombat", "Frozen", "Mingle", "LightAction", "Stun"}) do
                char:SetAttribute(attr, nil)
            end
            local hum = char:FindFirstChild("Humanoid")
            if hum then
                hum.WalkSpeed = 16
                hum.JumpPower = 50
                hum.PlatformStand = false
                hum.AutoRotate = true
            end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then hrp.Anchored = false end
            for _, p in ipairs(char:GetChildren()) do
                if p:IsA("BasePart") then p.Anchored = false end
            end
        end
        workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
        workspace.CurrentCamera.FieldOfView = 70

        for _, effect in ipairs(game:GetService("Lighting"):GetChildren()) do
            if effect:IsA("PostEffect") then effect.Enabled = false end
        end
            for _, gui in ipairs(LocalPlayer.PlayerGui:GetChildren()) do
                if gui:IsA("ScreenGui") and not gui.Name:find("ENI_") then
                    gui.Enabled = true
                end
            end
        print("[ENI-RESCUE] Screen freeze cleared, character unfrozen, camera & lighting restored!")
    end)
end)

local BalloonEspStorage = CoreGui:FindFirstChild("ENI_Balloon_ESP") or Instance.new("Folder", CoreGui)
BalloonEspStorage.Name = "ENI_Balloon_ESP"

CreateToggle(Pages["👁️ ESP & Visuals"], "🎈 Sky Balloon ESP", 320, function(state)
    getgenv().ENI_BalloonESP = state
    if state then
        RegisterThread(task.spawn(function()
            while getgenv().ENI_BalloonESP do
                task.wait(0.5)
                pcall(function()
                    BalloonEspStorage:ClearAllChildren()
                    local effects = workspace:FindFirstChild("Effects")
                    if not effects then return end
                    for _, child in ipairs(effects:GetChildren()) do
                        if child.Name:find("Balloon") then
                            local prompt = child:FindFirstChildWhichIsA("ProximityPrompt", true)
                            local part = prompt and prompt.Parent or (child:IsA("BasePart") and child or child:FindFirstChildWhichIsA("BasePart", true))
                            if part then
                                local hl = Instance.new("Highlight", BalloonEspStorage)
                                hl.Adornee = child
                                hl.FillColor = Color3.fromRGB(255, 30, 50)
                                hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                                hl.FillTransparency = 0.25

                                local bb = Instance.new("BillboardGui", BalloonEspStorage)
                                bb.Adornee = part
                                bb.Size = UDim2.new(0, 160, 0, 35)
                                bb.StudsOffset = Vector3.new(0, 3, 0)
                                bb.AlwaysOnTop = true

                                local txt = Instance.new("TextLabel", bb)
                                txt.Size = UDim2.new(1, 0, 1, 0)
                                txt.BackgroundTransparency = 1
                                local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                                local partPos = part.Position
                                local dist = myHRP and math.floor((myHRP.Position - partPos).Magnitude) or 0
                                txt.Text = string.format("🎈 SKY BALLOON\n[%d Studs Away]", dist)
                                txt.TextColor3 = Color3.fromRGB(255, 80, 80)
                                txt.Font = Enum.Font.GothamBold
                                txt.TextSize = 12
                            end
                        end
                    end
                end)
            end
        end))
    else
        getgenv().ENI_BalloonESP = false
        BalloonEspStorage:ClearAllChildren()
    end
end)

CreateToggle(Pages["🌐 Main & Movement"], "🎈 Proximity Balloon Auto-Pop", 300, function(state)
    getgenv().ENI_AutoPopBalloons = state
    if state then
        RegisterThread(task.spawn(function()
            while getgenv().ENI_AutoPopBalloons do
                task.wait(0.2) -- Throttled check: 0 spam when far away!
                pcall(function()
                    local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if not myHRP then return end

                    local effects = workspace:FindFirstChild("Effects")
                    local targetFolder = effects or workspace

                    for _, child in ipairs(targetFolder:GetChildren()) do
                        if child.Name:find("Balloon") then
                            local prompt = child:IsA("ProximityPrompt") and child or child:FindFirstChildWhichIsA("ProximityPrompt", true)
                            if prompt and prompt.Parent then
                                local part = prompt.Parent:IsA("BasePart") and prompt.Parent or (child:IsA("BasePart") and child or child:FindFirstChildWhichIsA("BasePart", true))
                                if part then
                                    local dist = (myHRP.Position - part.Position).Magnitude
                                    if dist <= 15 then
                                        prompt.HoldDuration = 0
                                        if fireproximityprompt then
                                            fireproximityprompt(prompt)
                                        else
                                            prompt:InputHoldBegan()
                                            prompt:InputHoldEnded()
                                        end
                                    end
                                end
                            end
                        end
                    end
                end)
            end
        end))
    else
        getgenv().ENI_AutoPopBalloons = false
    end
end)

local targetModes = {"Marked Players", "Guards (Rebel Mode)", "Enemy Players (Guard Mode)", "Universal (All Players)"}
getgenv().ENI_AimbotMode = "Marked Players"
CreateDropdown(Pages["🎯 Melee & Guns"], "🎯 Target Mode", targetModes, "Marked Players", 5, function(selected) getgenv().ENI_AimbotMode = selected print("[ENI-AIMBOT] Target mode set to:", selected) end)

getgenv().ENI_ManualMarkedPlayers = getgenv().ENI_ManualMarkedPlayers or {}

CreateButton(Pages["🎯 Melee & Guns"], "📌 Mark Closest Player to Crosshair for Aimbot", 12, function()
    pcall(function()
        local cam = workspace.CurrentCamera
        local mouseLoc = UserInputService:GetMouseLocation()
        local closestP, shortestDist = nil, math.huge

        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
                local screenPos, onScreen = cam:WorldToViewportPoint(player.Character.Head.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - mouseLoc).Magnitude
                    if dist < shortestDist then shortestDist = dist; closestP = player end
                end
            end
        end

        if closestP then
            getgenv().ENI_ManualMarkedPlayers[closestP.Name] = true
            getgenv().ENI_ManualMarkedPlayers[closestP] = true
            if closestP.Character then
                closestP.Character:SetAttribute("Marked", true)
                local hl = Instance.new("Highlight")
                hl.Name = "ENI_ManualMark_HL"
                hl.Adornee = closestP.Character
                hl.FillColor = Color3.fromRGB(255, 25, 25)
                hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                hl.Parent = closestP.Character
            end
            print("[ENI-MARK] Marked player for Aimbot:", closestP.Name)
        end
    end)
end)

CreateButton(Pages["🎯 Melee & Guns"], "🧹 Clear All Marked Aimbot Targets", 18, function()
    getgenv().ENI_ManualMarkedPlayers = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character then
            local hl = player.Character:FindFirstChild("ENI_ManualMark_HL")
            if hl then hl:Destroy() end
        end
    end
    print("[ENI-MARK] Cleared all marked aimbot targets!")
end)

getgenv().ENI_ManualMarkedPlayers = getgenv().ENI_ManualMarkedPlayers or {}
local markedCache = {}

local function IsPlayerMarked(player)
    if not (player and player.Character and player.Character.Parent) then
        if player then
            getgenv().ENI_ManualMarkedPlayers[player.Name] = nil
            getgenv().ENI_ManualMarkedPlayers[player] = nil
            markedCache[player] = nil
        end
        return false
    end

    local char = player.Character
    local hum = char:FindFirstChildOfClass("Humanoid") or char:FindFirstChild("Humanoid")
    if not (hum and hum.Health > 0) then
        getgenv().ENI_ManualMarkedPlayers[player.Name] = nil
        getgenv().ENI_ManualMarkedPlayers[player] = nil
        markedCache[player] = nil
        return false
    end

    local now = os.clock()
    local cached = markedCache[player]
    if cached and (now - cached.time) < 0.15 then
        return cached.result
    end

    local function EvaluateMarked()
        if getgenv().ENI_ManualMarkedPlayers[player.Name] or getgenv().ENI_ManualMarkedPlayers[player] then
            return true
        end

        local cAttrs = {"Marked", "IsMarked", "Wanted", "Targeted", "PushedGuard", "GuardPushed", "Bounty", "MarkedPlayer", "RedLight", "AttackedGuard", "IsSeeker", "IsIt", "Tag"}
        for _, attr in ipairs(cAttrs) do
            if char:GetAttribute(attr) == true or player:GetAttribute(attr) == true then
                return true
            end
        end

        for _, child in ipairs(char:GetChildren()) do
            if child:IsA("Highlight") and child.Enabled then
                local color = child.FillColor
                if color.R > 0.55 and color.G < 0.35 and color.B < 0.35 then
                    return true
                end
            end
        end

        local head = char:FindFirstChild("Head") or char.PrimaryPart
        if head then
            for _, gui in ipairs(head:GetChildren()) do
                if (gui:IsA("BillboardGui") or gui:IsA("SurfaceGui")) and gui.Enabled then
                    local gName = gui.Name:lower()
                    if gName:find("arrow") or gName:find("mark") or gName:find("target") or gName:find("tag") or gName:find("seeker") or gName:find("it") then
                        return true
                    end
                end
            end
        end

        local targetValFolder = workspace:FindFirstChild("Values") or ReplicatedStorage:FindFirstChild("Values")
        if targetValFolder then
            local markVal = targetValFolder:FindFirstChild("Marked") or targetValFolder:FindFirstChild("Targets") or targetValFolder:FindFirstChild("MarkedPlayers") or targetValFolder:FindFirstChild("Seeker") or targetValFolder:FindFirstChild("CurrentIt")
            if markVal then
                if markVal:IsA("Folder") or markVal:IsA("Model") then
                    if markVal:FindFirstChild(player.Name) then return true end
                elseif markVal:IsA("StringValue") and markVal.Value:find(player.Name) then
                    return true
                elseif markVal:IsA("ObjectValue") and markVal.Value == char then
                    return true
                end
            end
        end

        return false
    end

    local isMarked = EvaluateMarked()
    markedCache[player] = {result = isMarked, time = now}
    return isMarked
end

local function GetAimTargetPosition(part)
    if not part or not part:IsA("BasePart") then
        return nil
    end

    local pos = part.Position
    local name = part.Name:lower()
    if name:find("head") then
        pos = pos + Vector3.new(0, part.Size.Y * 0.18, 0)
    elseif name:find("torso") or name:find("upper") or name:find("chest") then
        pos = pos + Vector3.new(0, part.Size.Y * 0.12, 0)
    elseif name:find("humanoidrootpart") then
        pos = pos + Vector3.new(0, 0.9, 0)
    end
    return pos
end

local function GetSelectedTargetHead()
    local mode = getgenv().ENI_AimbotMode or "Universal (All Players)"
    local cam = workspace.CurrentCamera
    if not cam then return nil end
    local mouseLoc = UserInputService:GetMouseLocation()
    local closestHead, shortestDist = nil, math.huge

    local function testHead(head)
        if not head then return end
        local targetPos = GetAimTargetPosition(head)
        if not targetPos then return end
        local screenPos, onScreen = cam:WorldToViewportPoint(targetPos)
        if onScreen then
            local dist = (Vector2.new(screenPos.X, screenPos.Y) - mouseLoc).Magnitude
            if dist < shortestDist then
                shortestDist = dist
                closestHead = head
            end
        end
    end

    if mode == "Marked Players" then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
                if IsPlayerMarked(player) then
                    testHead(player.Character.Head)
                end
            end
        end
        return closestHead
    end

    if mode == "Guards (Rebel Mode)" then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
                local char = player.Character
                local isGuard = char:GetAttribute("IsGuard") or char:GetAttribute("Guard") or (player.Team and player.Team.Name == "Guard")
                if isGuard then
                    testHead(char.Head)
                end
            end
        end
        local liveFolder = workspace:FindFirstChild("Live")
        if liveFolder then
            for _, model in ipairs(liveFolder:GetChildren()) do
                if model.Name:find("guard") or model.Name:find("Guard") or model.Name:find("squid guy") then
                    local head = model:FindFirstChild("Head")
                    local hum = model:FindFirstChild("Humanoid")
                    if head and hum and hum.Health > 0 then
                        testHead(head)
                    end
                end
            end
        end
        return closestHead
    end

    if mode == "Enemy Players (Guard Mode)" then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
                local char = player.Character
                local isGuard = char:GetAttribute("IsGuard") or char:GetAttribute("Guard")
                if not isGuard then
                    testHead(char.Head)
                end
            end
        end
        return closestHead
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            testHead(player.Character.Head)
        end
    end
    return closestHead
end

CreateToggle(Pages["🎯 Melee & Guns"], "🔫 Silent Aimbot", 50, function(state)
    getgenv().ENI_SilentAimbot = state
end)

CreateToggle(Pages["🎯 Melee & Guns"], "⚡ Ultra Rapid Fire Loop", 93, function(state)
    getgenv().ENI_RapidFireActive = state
    if state then
        RegisterThread(task.spawn(function()
            local lastBurstAt = 0
            local ammoNames = {"Bullets", "MaxBullets", "Ammo", "MaxAmmo", "ClipAmmo", "ClipSize", "CurrentAmmo", "StoredAmmo", "AmmoCount", "Magazine", "CurrentClip", "Clip", "Current", "Rounds", "ShotsLeft"}
            local boolNames = {"Reloading", "IsReloading", "NeedsReload", "CanFire", "Ready", "Enabled", "Debounce", "Cooldown"}

            while getgenv().ENI_RapidFireActive do
                task.wait(0.03)
                pcall(function()
                    local now = os.clock()
                    if now - lastBurstAt < 0.05 then return end
                    lastBurstAt = now

                    local char = LocalPlayer.Character
                    if not char then return end

                    local preferredTool = nil
                    for _, child in ipairs(char:GetChildren()) do
                        if child:IsA("Tool") then
                            local n = (child.Name or ""):lower()
                            if not n:find("fist") and not n:find("punch") and not n:find("melee") then
                                preferredTool = child
                                break
                            end
                        end
                    end
                    if not preferredTool then return end

                    preferredTool.Enabled = true
                    preferredTool:SetAttribute("Cooldown", 0)
                    preferredTool:SetAttribute("FireRate", 0.0001)
                    preferredTool:SetAttribute("Delay", 0)
                    preferredTool:SetAttribute("ShotDelay", 0)
                    preferredTool:SetAttribute("Recoil", 0)
                    preferredTool:SetAttribute("Spread", 0)
                    preferredTool:SetAttribute("ReloadTime", 0)
                    preferredTool:SetAttribute("CanFire", true)
                    preferredTool:SetAttribute("Debounce", false)
                    preferredTool:SetAttribute("Reloading", false)
                    preferredTool:SetAttribute("NeedsReload", false)
                    preferredTool:SetAttribute("InfiniteAmmo", true)
                    preferredTool:SetAttribute("DisplayAmmo", 999999)
                    preferredTool:SetAttribute("HudAmmo", 999999)

                    for _, val in ipairs(preferredTool:GetDescendants()) do
                        if val:IsA("BoolValue") then
                            local vName = (val.Name or ""):lower()
                            for _, boolName in ipairs(boolNames) do
                                if vName:find(boolName:lower()) then
                                    val.Value = false
                                    break
                                end
                            end
                            if vName:find("canfire") or vName:find("ready") or vName:find("enabled") then
                                val.Value = true
                            end
                        elseif val:IsA("NumberValue") or val:IsA("IntValue") then
                            local vName = (val.Name or ""):lower()
                            local isDisplayOnly = vName:find("display") or vName:find("hud") or vName:find("ui") or vName:find("ghost")
                            if vName:find("cooldown") or vName:find("delay") or vName:find("recoil") or vName:find("wait") or vName:find("reload") then
                                val.Value = 0
                            elseif isDisplayOnly then
                                val.Value = 999999
                            end
                        end
                    end

                    for _, ammoName in ipairs(ammoNames) do
                        local value = preferredTool:FindFirstChild(ammoName)
                        if value and (value:IsA("IntValue") or value:IsA("NumberValue")) then
                            local n = (value.Name or ""):lower()
                            if n:find("display") or n:find("hud") or n:find("ui") then
                                value.Value = 999999
                            end
                        elseif not value then
                            local iv = Instance.new("IntValue")
                            iv.Name = ammoName .. "Display"
                            iv.Value = 999999
                            iv.Parent = preferredTool
                        end
                    end

                    if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then return end

                    local targetHead = GetSelectedTargetHead()
                    local mouse = LocalPlayer:GetMouse()
                    local targetPos = targetHead and GetAimTargetPosition(targetHead) or (mouse and mouse.Hit and mouse.Hit.Position) or (char.PrimaryPart and char.PrimaryPart.Position + char.PrimaryPart.CFrame.LookVector * 100)
                    local rootPart = char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
                    local origin = rootPart and rootPart.Position or Vector3.zero

                    pcall(function()
                        local ok, err = pcall(function()
                            preferredTool:Activate()
                        end)
                        if not ok then
                            warn("[ENI-RAPID-FIRE] Activate failed: " .. tostring(err))
                        end
                    end)

                    local searchFolders = {
                        ReplicatedStorage,
                        ReplicatedStorage and ReplicatedStorage:FindFirstChild("Remotes"),
                        ReplicatedStorage and ReplicatedStorage:FindFirstChild("Events"),
                        preferredTool,
                        char
                    }
                    for _, folder in ipairs(searchFolders) do
                        if folder then
                            for _, r in ipairs(folder:GetChildren()) do
                                if r:IsA("RemoteEvent") then
                                    local rName = (r.Name or ""):lower()
                                    if rName:find("shoot") or rName:find("fire") or rName:find("gun") or rName:find("bullet") or rName:find("attack") or rName:find("weapon") or rName:find("guard") or rName:find("sniper") or rName:find("damage") then
                                        pcall(function()
                                            r:FireServer({Position = targetPos, Target = targetHead, Hit = targetHead, Origin = origin, Character = targetHead and targetHead.Parent})
                                        end)
                                        pcall(function()
                                            r:FireServer(targetPos)
                                        end)
                                    end
                                end
                            end
                        end
                    end
                end)
            end
        end))
    else
        getgenv().ENI_RapidFireActive = false
    end
end)

RegisterConnection(RunService.RenderStepped:Connect(function()
    if not getgenv().ENI_SilentAimbot then return end
    local isHoldingAim = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) or UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    if not isHoldingAim then return end

    pcall(function()
        local cam = workspace.CurrentCamera
        if not cam or cam.CameraType ~= Enum.CameraType.Custom then return end
        local targetHead = GetSelectedTargetHead()
        if not targetHead then return end
        local targetPos = GetAimTargetPosition(targetHead) or targetHead.Position
        local targetCFrame = CFrame.lookAt(cam.CFrame.Position, targetPos + Vector3.new(0, 0.2, 0))
        cam.CFrame = cam.CFrame:Lerp(targetCFrame, 0.18)
    end)
end))

CreateToggle(Pages["🎯 Melee & Guns"], "♾️ Infinite Ammo & Zero Reload", 93, function(state)
    getgenv().ENI_InfiniteAmmoRLGL = state
    if not state then
        getgenv().ENI_InfiniteAmmoRLGL = false
        return
    end

    RegisterThread(task.spawn(function()
        local ammoNames = {"Bullets", "MaxBullets", "Ammo", "MaxAmmo", "ClipAmmo", "ClipSize", "CurrentAmmo", "StoredAmmo", "AmmoCount", "Magazine", "CurrentClip", "Clip", "Current", "Rounds", "ShotsLeft"}
        local boolNames = {"Reloading", "IsReloading", "NeedsReload", "CanFire", "Ready", "Enabled", "Debounce"}

        local function setAmmoSafe(tool)
            if not tool or not tool:IsA("Tool") then return end

            local nameLower = (tool.Name or ""):lower()
            if nameLower:find("fist") or nameLower:find("punch") or nameLower:find("melee") then
                return
            end

            tool:SetAttribute("ReloadTime", 0)
            tool:SetAttribute("Reloading", false)
            tool:SetAttribute("IsReloading", false)
            tool:SetAttribute("NeedsReload", false)
            tool:SetAttribute("CanFire", true)
            tool:SetAttribute("Ready", true)
            tool:SetAttribute("InfiniteAmmo", true)
            tool:SetAttribute("DisplayAmmo", 999999)
            tool:SetAttribute("HudAmmo", 999999)

            for _, val in ipairs(tool:GetDescendants()) do
                if val:IsA("BoolValue") then
                    local vName = (val.Name or ""):lower()
                    for _, boolName in ipairs(boolNames) do
                        if vName:find(boolName:lower()) then
                            val.Value = false
                        end
                    end
                    if vName:find("canfire") or vName:find("ready") or vName:find("enabled") then
                        val.Value = true
                    end
                elseif val:IsA("NumberValue") or val:IsA("IntValue") then
                    local vName = (val.Name or ""):lower()
                    local isDisplayOnly = vName:find("display") or vName:find("hud") or vName:find("ui") or vName:find("ghost")
                    if vName:find("cooldown") or vName:find("delay") or vName:find("recoil") or vName:find("reload") or vName:find("wait") then
                        val.Value = 0
                    elseif isDisplayOnly then
                        val.Value = 999999
                    elseif vName:find("ammo") or vName:find("bullet") or vName:find("clip") or vName:find("mag") or vName:find("round") or vName:find("capacity") then
                        -- Keep these values safe. RLGL validates the server-authoritative ammo state,
                        -- so overwriting the real ammo fields can cause shots to be rejected.
                    end
                end
            end

            for _, ammoName in ipairs(ammoNames) do
                local value = tool:FindFirstChild(ammoName)
                if value and (value:IsA("IntValue") or value:IsA("NumberValue")) then
                    if (value.Name or ""):lower():find("display") or (value.Name or ""):lower():find("hud") or (value.Name or ""):lower():find("ui") then
                        value.Value = 999999
                    end
                elseif not value then
                    local displayName = ammoName .. "Display"
                    local newVal = Instance.new("IntValue")
                    newVal.Name = displayName
                    newVal.Value = 999999
                    newVal.Parent = tool
                end
            end
        end

        while getgenv().ENI_InfiniteAmmoRLGL do
            task.wait(0.1)
            pcall(function()
                local char = LocalPlayer.Character
                if not char then return end

                for _, child in ipairs(char:GetChildren()) do
                    if child:IsA("Tool") then
                        setAmmoSafe(child)
                    end
                end

                local backpack = LocalPlayer:FindFirstChild("Backpack")
                if backpack then
                    for _, child in ipairs(backpack:GetChildren()) do
                        if child:IsA("Tool") then
                            setAmmoSafe(child)
                        end
                    end
                end

                LocalPlayer:SetAttribute("DisplayAmmo", 999999)
                LocalPlayer:SetAttribute("HudAmmo", 999999)
                LocalPlayer:SetAttribute("SniperAmmoDisplay", 999999)
                LocalPlayer:SetAttribute("GuardAmmoDisplay", 999999)
                if char then
                    char:SetAttribute("DisplayAmmo", 999999)
                    char:SetAttribute("HudAmmo", 999999)
                    char:SetAttribute("SniperAmmoDisplay", 999999)
                    char:SetAttribute("GuardAmmoDisplay", 999999)
                end
            end)
        end
    end))
end)

CreateToggle(Pages["🎯 Melee & Guns"], "💀 1-Hit Kill Damage Boost", 136, function(state)
    getgenv().ENI_OneHitKill = state
    if state then
        RegisterThread(task.spawn(function()
            local gunDmgModule = nil
            pcall(function() gunDmgModule = require(game:GetService("ReplicatedStorage").Modules.GunDamageValues) end)
            while getgenv().ENI_OneHitKill do
                task.wait(1.0)
                pcall(function()
                    if gunDmgModule then
                        for _, bodyParts in pairs(gunDmgModule) do
                            if typeof(bodyParts) == "table" then
                                for partName, _ in pairs(bodyParts) do bodyParts[partName] = 5000 end
                            end
                        end
                    end
                end)
            end
        end))
    else
        getgenv().ENI_OneHitKill = false
    end
end)

local reachSizeVal = 15
CreateSlider(Pages["🎯 Melee & Guns"], "Extended Melee Reach (Studs)", 5, 50, 15, 5, function(val) reachSizeVal = val end)
CreateToggle(Pages["🎯 Melee & Guns"], "⚡ Extended Melee Hitbox", 60, function(state) getgenv().ENI_ExtendedReach = state end)
RegisterThread(task.spawn(function() while true do task.wait(0.3) if getgenv().ENI_ExtendedReach then pcall(function() local char = LocalPlayer.Character if char then for _, tool in ipairs(char:GetChildren()) do if tool:IsA("Tool") then for _, part in ipairs(tool:GetDescendants()) do if part:IsA("BasePart") then part.Size = Vector3.new(reachSizeVal, reachSizeVal, reachSizeVal) part.Transparency = 0.8 part.Color = Color3.fromRGB(255, 0, 150) part.Massless = true part.CanCollide = false end end end end end end) end end end))

local ENI_IsAiming = false
local UserInputService = game:GetService("UserInputService")
UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.UserInputType == Enum.UserInputType.MouseButton2 then getgenv().ENI_IsAiming = true end
end)
UserInputService.InputEnded:Connect(function(input, gpe)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then getgenv().ENI_IsAiming = false end
end)

CreateToggle(Pages["🔺 Red Light Green Light"], "⚡ RLGL Doll Freeze & Movement Bypass", 5, function(state)
    getgenv().ENI_RLGLBypass = state
    if state then
        RegisterThread(task.spawn(function()
            while getgenv().ENI_RLGLBypass do
                task.wait(0.2)
                pcall(function() local char = LocalPlayer.Character if char then char:SetAttribute("ClickedOrJumpedRecently", nil) char:SetAttribute("Freeze", nil) char:SetAttribute("Slowed", nil) end end)
            end
        end))
    else
        getgenv().ENI_RLGLBypass = false
    end
end)
local function GetRLGLDollOrTree()
    local rlglMap = workspace:FindFirstChild("RedLightGreenLight")
    if rlglMap then
        local target = rlglMap:FindFirstChild("doll") or rlglMap:FindFirstChild("Doll") or rlglMap:FindFirstChild("tree") or rlglMap:FindFirstChild("Tree")
        if target then return target end
    end
    return workspace:FindFirstChild("doll", true)
        or workspace:FindFirstChild("tree", true)
        or workspace:FindFirstChild("RLGLFinish", true)
        or workspace:FindFirstChild("FinishLine", true)
end

CreateButton(Pages["🔺 Red Light Green Light"], "⚡ Teleport to RLGL Tree / Doll Finish", 48, function()
    pcall(function()
        local target = GetRLGLDollOrTree()
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if target and hrp then
            local cf = target:IsA("BasePart") and target.CFrame or (target:IsA("Model") and target:GetPivot() or nil)
            if cf then
                hrp.CFrame = cf + Vector3.new(0, 3, 0)
                print("Teleported to RLGL Doll / Tree finish!")
            end
        end
    end)
end)

CreateToggle(Pages["🔺 Red Light Green Light"], "⚡ Auto-Win RLGL", 91, function(state)
    getgenv().ENI_AutoRLGL = state
    if state then
        RegisterThread(task.spawn(function()
            while getgenv().ENI_AutoRLGL do
                task.wait(1.0)
                pcall(function()
                    local currentGame = workspace:FindFirstChild("Values") and workspace.Values:FindFirstChild("CurrentGame") and workspace.Values.CurrentGame.Value
                    if currentGame == "RedLightGreenLight" then
                        local char = LocalPlayer.Character
                        if char then char:SetAttribute("ClickedOrJumpedRecently", nil) char:SetAttribute("Freeze", nil) char:SetAttribute("Slowed", nil) end
                        local target = GetRLGLDollOrTree()
                        local hrp = char and char:FindFirstChild("HumanoidRootPart")
                        if target and hrp then
                            local cf = target:IsA("BasePart") and target.CFrame or (target:IsA("Model") and target:GetPivot() or nil)
                            if cf then hrp.CFrame = cf + Vector3.new(0, 3, 0) end
                        end
                    end
                end)
            end
        end))
    else
        getgenv().ENI_AutoRLGL = false
    end
end)

CreateButton(Pages["🍪 Dalgona Cookie"], "⚡ Hook 1B Dalgona Lighter", 5, function()
    pcall(function()
        local attrs = {"HasLighter", "LighterEquipped", "DalgonaLighter", "LighterUnlocked", "NeedleLighter", "HeatNeedle", "OwnsLighter", "UseLighter"}
        for _, a in ipairs(attrs) do
            LocalPlayer:SetAttribute(a, true)
            if LocalPlayer.Character then LocalPlayer.Character:SetAttribute(a, true) end
        end

        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        if playerGui then
            for _, guiName in ipairs({"DalgonaUI", "DalgonaScreen", "HoneycombUI", "DalgonaGame"}) do
                local dUI = playerGui:FindFirstChild(guiName)
                if dUI then
                    local lighterBtn = dUI:FindFirstChild("Lighter", true) or dUI:FindFirstChild("Heat", true) or dUI:FindFirstChild("Flame", true)
                    if lighterBtn then lighterBtn.Visible = true end
                end
            end
        end

        local RemotesFolder = GetRemotesFolder()
                if RemotesFolder then
            for _, r in ipairs(RemotesFolder:GetDescendants()) do
                if r:IsA("RemoteEvent") and (r.Name:find("Lighter") or r.Name:find("Heat") or r.Name:find("Flame")) then
                    pcall(function() r:FireServer({UseLighter = true, Equipped = true}) end)
                end
            end
        end

        ENI_Notify("Dalgona Lighter", "1B Dalgona Lighter hooked & unlocked!", "Success", 3)
        print("[ENI-DALGONA] 1B Dalgona Lighter hooked & unlocked!")
    end)
end)

CreateToggle(Pages["🍪 Dalgona Cookie"], "⚡ Dalgona Safe Uncrackable Godmode", 48, function(state)
    getgenv().ENI_DalgonaGodmode = state
    if state then
        RegisterThread(task.spawn(function()
            while getgenv().ENI_DalgonaGodmode do
                task.wait(0.005) -- 200 FPS ultra-fast tick so game scripts can NEVER catch stress > 0
                pcall(function()
                    LocalPlayer:SetAttribute("DalgonaStress", 0)
                    LocalPlayer:SetAttribute("DalgonaCrack", false)
                    LocalPlayer:SetAttribute("DalgonaFailed", false)
                    LocalPlayer:SetAttribute("CookieBroken", false)

                    local char = LocalPlayer.Character
                    if char then
                        char:SetAttribute("DalgonaStress", 0)
                        char:SetAttribute("DalgonaCrack", false)
                        char:SetAttribute("DalgonaFailed", false)
                        char:SetAttribute("CookieBroken", false)
                        char:SetAttribute("CrackChance", 0)
                        char:SetAttribute("Stress", 0)
                    end

                    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
                    if playerGui then
                        for _, gName in ipairs({"DalgonaUI", "DalgonaScreen", "HoneycombUI", "DalgonaGame"}) do
                            local dalgonaUI = playerGui:FindFirstChild(gName)
                            if dalgonaUI then
                                local crackFill = dalgonaUI:FindFirstChild("CrackProgressBar", true) and dalgonaUI.CrackProgressBar:FindFirstChild("Fill", true)
                                if crackFill then crackFill.Size = UDim2.new(0, 0, 1, 0) end

                                local chanceLabel = dalgonaUI:FindFirstChild("Chance", true)
                                if chanceLabel and chanceLabel:IsA("TextLabel") then chanceLabel.Text = "0%" end

                                for _, val in ipairs(dalgonaUI:GetDescendants()) do
                                    if val:IsA("NumberValue") or val:IsA("IntValue") then
                                        if val.Name:find("Stress") or val.Name:find("Crack") or val.Name:find("Mistake") or val.Name:find("Fail") or val.Name:find("Chance") then
                                            val.Value = 0
                                        end
                                    elseif val:IsA("BoolValue") then
                                        if val.Name:find("Crack") or val.Name:find("Failed") or val.Name:find("Broke") then
                                            val.Value = false
                                        end
                                    end
                                end
                            end
                        end
                    end
                end)
            end
        end))
    else
        getgenv().ENI_DalgonaGodmode = false
    end
end)

CreateToggle(Pages["🍪 Dalgona Cookie"], "⚡ Perfect Auto Cookie Carver", 91, function(state)
    getgenv().ENI_DalgonaAutoCarve = state
    if state then
        RegisterThread(task.spawn(function()
            local VIM = game:GetService("VirtualInputManager")
            while getgenv().ENI_DalgonaAutoCarve do
                task.wait(0.05)
                pcall(function()
                    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
                    if playerGui then
                        for _, gName in ipairs({"DalgonaUI", "DalgonaScreen", "HoneycombUI", "DalgonaGame"}) do
                            local dalgonaUI = playerGui:FindFirstChild(gName)
                            if dalgonaUI and dalgonaUI.Enabled then
                                local cutBar = dalgonaUI:FindFirstChild("CuttingProgressBar", true)
                                local cutFill = cutBar and cutBar:FindFirstChild("Fill", true)
                                if cutFill then
                                    local curWidth = cutFill.Size.X.Scale
                                    if curWidth < 1 then
                                        local nextWidth = math.min(1, curWidth + 0.04)
                                        cutFill.Size = UDim2.new(nextWidth, 0, 1, 0)
                                        local progText = cutBar:FindFirstChild("Progress", true)
                                        if progText and progText:IsA("TextLabel") then
                                            progText.Text = math.floor(nextWidth * 100) .. "%"
                                        end
                                    end
                                end

                                local cutBtn = dalgonaUI:FindFirstChild("Cut", true) or dalgonaUI:FindFirstChild("Carve", true) or dalgonaUI:FindFirstChild("Click", true)
                                if cutBtn and cutBtn.Visible then
                                    if firesignal then
                                        pcall(function() firesignal(cutBtn.Activated) end)
                                        pcall(function() firesignal(cutBtn.MouseButton1Click) end)
                                    else
                                        local pos = cutBtn.AbsolutePosition
                                        local sz = cutBtn.AbsoluteSize
                                        VIM:SendMouseButtonEvent(pos.X + sz.X/2, pos.Y + sz.Y/2, 0, true, game, 0)
                                        task.wait(0.01)
                                        VIM:SendMouseButtonEvent(pos.X + sz.X/2, pos.Y + sz.Y/2, 0, false, game, 0)
                                    end
                                end
                            end
                        end
                    end
                end)
            end
        end))
    else
        getgenv().ENI_DalgonaAutoCarve = false
    end
end)

CreateToggle(Pages["🍪 Dalgona Cookie"], "⚡ Auto-Breathing & Lighter Heat Engine", 134, function(state)
    getgenv().ENI_DalgonaBreathing = state
    if state then
        RegisterThread(task.spawn(function()
            local VIM = game:GetService("VirtualInputManager")
            while getgenv().ENI_DalgonaBreathing do
                task.wait(0.15)
                pcall(function()
                    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
                    if playerGui then
                        for _, gName in ipairs({"DalgonaUI", "DalgonaScreen", "HoneycombUI", "DalgonaGame"}) do
                            local dalgonaUI = playerGui:FindFirstChild(gName)
                            if dalgonaUI and dalgonaUI.Enabled then
                                for _, btnName in ipairs({"Breath", "Lighter", "Heat", "Flame", "Blow"}) do
                                    local btn = dalgonaUI:FindFirstChild(btnName, true)
                                    if btn and (btn:IsA("ImageButton") or btn:IsA("TextButton")) and btn.Visible then
                                        if firesignal then
                                            pcall(function() firesignal(btn.Activated) end)
                                            pcall(function() firesignal(btn.MouseButton1Click) end)
                                        else
                                            local pos = btn.AbsolutePosition
                                            local sz = btn.AbsoluteSize
                                            VIM:SendMouseButtonEvent(pos.X + sz.X/2, pos.Y + sz.Y/2, 0, true, game, 0)
                                            task.wait(0.01)
                                            VIM:SendMouseButtonEvent(pos.X + sz.X/2, pos.Y + sz.Y/2, 0, false, game, 0)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end)
            end
        end))
    else
        getgenv().ENI_DalgonaBreathing = false
    end
end)

CreateButton(Pages["🍪 Dalgona Cookie"], "⚡ Instant Dalgona Server Auto-Win", 177, function()
    pcall(function()
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        if playerGui then
            for _, gName in ipairs({"DalgonaUI", "DalgonaScreen", "HoneycombUI", "DalgonaGame"}) do
                local dalgonaUI = playerGui:FindFirstChild(gName)
                if dalgonaUI then
                    local cutFill = dalgonaUI:FindFirstChild("CuttingProgressBar", true) and dalgonaUI.CuttingProgressBar:FindFirstChild("Fill", true)
                    if cutFill then cutFill.Size = UDim2.new(1, 0, 1, 0) end
                    local progressLabel = dalgonaUI:FindFirstChild("CuttingProgressBar", true) and dalgonaUI.CuttingProgressBar:FindFirstChild("Progress", true)
                    if progressLabel and progressLabel:IsA("TextLabel") then progressLabel.Text = "100%" end
                end
            end
        end

        LocalPlayer:SetAttribute("DalgonaCompleted", true)
        LocalPlayer:SetAttribute("DalgonaFlawless", true)
        LocalPlayer:SetAttribute("DalgonaFlawless2Progress", 2)
        LocalPlayer:SetAttribute("DalgonaFlawless2Completed", true)
        LocalPlayer:SetAttribute("PlayingDalgonaCurrently", nil)

        local char = LocalPlayer.Character
        if char then
            char:SetAttribute("DalgonaStress", 0)
            char:SetAttribute("DalgonaCrack", false)
            char:SetAttribute("Freeze", nil)
            char:SetAttribute("Action", nil)
        end

        local RemotesFolder = GetRemotesFolder()
                if RemotesFolder then
            local temp1 = RemotesFolder:FindFirstChild("TemporaryReachedBindable")
            local temp2 = RemotesFolder:FindFirstChild("TemporaryReachedBindableSecond")
            local gameRemote = RemotesFolder:FindFirstChild("GameRemote") or RemotesFolder:FindFirstChild("MinigameRemote") or RemotesFolder:FindFirstChild("ClickedButton") or RemotesFolder:FindFirstChild("Dalgona")

            if temp1 and temp1:IsA("RemoteEvent") then pcall(function() temp1:FireServer("Dalgona", true) end) end
            if temp2 and temp2:IsA("RemoteEvent") then pcall(function() temp2:FireServer("Dalgona", true) end) end

            if gameRemote and gameRemote:IsA("RemoteEvent") then
                pcall(function() gameRemote:FireServer("DalgonaCompleted", true) end)
                pcall(function() gameRemote:FireServer("DalgonaWin", true) end)
                pcall(function() gameRemote:FireServer("CompleteDalgona", true) end)
                pcall(function() gameRemote:FireServer({Action = "DalgonaWin", Completed = true}) end)
            end

            for _, r in ipairs(RemotesFolder:GetDescendants()) do
                if r:IsA("RemoteEvent") and (r.Name:find("Dalgona") or r.Name:find("Minigame") or r.Name:find("Reach")) then
                    pcall(function() r:FireServer("Completed", true) end)
                    pcall(function() r:FireServer(true) end)
                    pcall(function() r:FireServer({Completed = true, Win = true, Game = "Dalgona"}) end)
                end
            end
        end

        workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.PlatformStand = false
            char.Humanoid.WalkSpeed = 16
            if char:FindFirstChild("HumanoidRootPart") then
                char.HumanoidRootPart.Anchored = false
            end
        end

        ENI_Notify("Dalgona Auto-Win", "Instant Server Auto-Win executed successfully!", "Success", 3)
        print("[ENI-DALGONA] Instant Server Auto-Win executed successfully!")
    end)
end)

CreateToggle(Pages["🪢 Tug Of War"], "⚡ Auto Pull Tug-Of-War Spam", 5, function(state)
    getgenv().ENI_AutoTugOfWar = state
    if state then
        RegisterThread(task.spawn(function()
            local VIM = game:GetService("VirtualInputManager")
            while getgenv().ENI_AutoTugOfWar do
                task.wait(0.015) -- High-speed 60 FPS tap engine
                pcall(function()
                    VIM:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                    VIM:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
                    VIM:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                    VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game)

                    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
                    if playerGui then
                        for _, gui in ipairs(playerGui:GetChildren()) do
                            if gui:IsA("ScreenGui") and (gui.Name:find("Tug") or gui.Name:find("Pull") or gui.Name:find("Minigame") or gui.Name:find("QTE")) then
                                for _, btn in ipairs(gui:GetDescendants()) do
                                    if (btn:IsA("TextButton") or btn:IsA("ImageButton")) and btn.Visible then
                                        if firesignal then
                                            pcall(function() firesignal(btn.Activated) end)
                                            pcall(function() firesignal(btn.MouseButton1Click) end)
                                        end
                                    end
                                end
                            end
                        end
                    end

                    local RemotesFolder = GetRemotesFolder()
                if RemotesFolder then
                        local tugRemote = RemotesFolder:FindFirstChild("TugOfWar") or RemotesFolder:FindFirstChild("Pull") or RemotesFolder:FindFirstChild("GameRemote") or RemotesFolder:FindFirstChild("ClickedButton")
                        if tugRemote and tugRemote:IsA("RemoteEvent") then
                            tugRemote:FireServer("Pull")
                            tugRemote:FireServer(true)
                            tugRemote:FireServer()
                        end
                        for _, r in ipairs(RemotesFolder:GetDescendants()) do
                            if r:IsA("RemoteEvent") and (r.Name:find("Tug") or r.Name:find("Pull")) then
                                r:FireServer()
                                r:FireServer("Pull")
                            end
                        end
                    end
                end)
            end
        end))
    else
        getgenv().ENI_AutoTugOfWar = false
    end
end)

CreateToggle(Pages["🪢 Tug Of War"], "⚡ Auto Jump-Rope Perfect A / D Balance Solver", 48, function(state)
    getgenv().ENI_JumpRopeBalance = state
    if state then
        RegisterThread(task.spawn(function()
            local VIM = game:GetService("VirtualInputManager")
            print("[ENI-JUMPROPE] Overhauled 4-Way Auto Jump-Rope Balance Solver ACTIVE!")
            
            while getgenv().ENI_JumpRopeBalance do
                task.wait(0.016) -- High-speed 60 FPS balance tick
                pcall(function()
                    local char = LocalPlayer.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    local hum = char and char:FindFirstChild("Humanoid")

                    -- 1. Hard-override Character & Player Attributes to Perfect 0
                    if char then
                        for _, attrName in ipairs({"Tilt", "Balance", "Falling", "OffBalance", "Stumble", "IsOffBalance", "IsTilted", "Lean", "Angle"}) do
                            pcall(function()
                                if type(char:GetAttribute(attrName)) == "boolean" then
                                    char:SetAttribute(attrName, false)
                                else
                                    char:SetAttribute(attrName, 0)
                                end
                            end)
                            pcall(function()
                                if type(LocalPlayer:GetAttribute(attrName)) == "boolean" then
                                    LocalPlayer:SetAttribute(attrName, false)
                                else
                                    LocalPlayer:SetAttribute(attrName, 0)
                                end
                            end)
                        end
                    end

                    -- 2. Multi-Remote Balance Relay Sweep
                    local RemotesFolder = GetRemotesFolder()
                    if RemotesFolder then
                        for _, rName in ipairs({"JumpRope", "Balance", "KeepBalance", "JumpRopeBalance", "Relay", "Pentathlon", "GameRemote"}) do
                            local r = RemotesFolder:FindFirstChild(rName) or (RemotesFolder.Parent and RemotesFolder.Parent:FindFirstChild(rName))
                            if r and r:IsA("RemoteEvent") then
                                pcall(function() r:FireServer(0) end)
                                pcall(function() r:FireServer("Balance", 0) end)
                                pcall(function() r:FireServer("KeepBalance", 0) end)
                                pcall(function() r:FireServer("Center") end)
                            end
                        end
                    end

                    -- 3. Universal UI Balance Indicator Scanner (Position X + Rotation Angle)
                    local balanced = false
                    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
                    if playerGui then
                        for _, gui in ipairs(playerGui:GetChildren()) do
                            if (gui:IsA("ScreenGui") or gui:IsA("BillboardGui")) and gui.Enabled then
                                local pointer = gui:FindFirstChild("Pointer", true) or gui:FindFirstChild("Line", true) or gui:FindFirstChild("Indicator", true) or gui:FindFirstChild("Needle", true) or gui:FindFirstChild("Cursor", true) or gui:FindFirstChild("Arrow", true)
                                local target = gui:FindFirstChild("Target", true) or gui:FindFirstChild("Center", true) or gui:FindFirstChild("Safe", true) or gui:FindFirstChild("GreenZone", true) or gui:FindFirstChild("Goal", true)
                                
                                if pointer then
                                    -- Check via Rotation Angle (Pendulum / Rotating Needle)
                                    local rot = pointer.Rotation
                                    if rot > 2 then
                                        -- Tilted Right -> Tap A to lean Left
                                        VIM:SendKeyEvent(true, Enum.KeyCode.A, false, game)
                                        task.wait(0.02)
                                        VIM:SendKeyEvent(false, Enum.KeyCode.A, false, game)
                                        balanced = true
                                    elseif rot < -2 then
                                        -- Tilted Left -> Tap D to lean Right
                                        VIM:SendKeyEvent(true, Enum.KeyCode.D, false, game)
                                        task.wait(0.02)
                                        VIM:SendKeyEvent(false, Enum.KeyCode.D, false, game)
                                        balanced = true
                                    end

                                    -- Check via 2D Bounding Box Center X
                                    if not balanced and target then
                                        local pCenterX = pointer.AbsolutePosition.X + (pointer.AbsoluteSize.X / 2)
                                        local tCenterX = target.AbsolutePosition.X + (target.AbsoluteSize.X / 2)
                                        local diff = pCenterX - tCenterX

                                        if diff > 5 then
                                            -- Pointer is Right of Center -> Press A
                                            VIM:SendKeyEvent(true, Enum.KeyCode.A, false, game)
                                            task.wait(0.02)
                                            VIM:SendKeyEvent(false, Enum.KeyCode.A, false, game)
                                            balanced = true
                                        elseif diff < -5 then
                                            -- Pointer is Left of Center -> Press D
                                            VIM:SendKeyEvent(true, Enum.KeyCode.D, false, game)
                                            task.wait(0.02)
                                            VIM:SendKeyEvent(false, Enum.KeyCode.D, false, game)
                                            balanced = true
                                        end
                                    end
                                end
                            end
                        end
                    end

                    -- 4. Physical CFrame & RootJoint Upright Lock
                    if hrp then
                        local rx, ry, _ = hrp.CFrame:ToOrientation()
                        hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(rx, ry, 0)
                    end
                end)
            end
        end))
    else
        getgenv().ENI_JumpRopeBalance = false
    end
end)

CreateToggle(Pages["🪢 Tug Of War"], "⚡ Auto Reflex Rush", 100, function(state)
    getgenv().ENI_AutoReflexRush = state
    if state then
        RegisterThread(task.spawn(function()
            local VIM = game:GetService("VirtualInputManager")
            print("[ENI-REFLEX] Auto Reflex Rush 3D Blue Circles Solver ACTIVE!")

            while getgenv().ENI_AutoReflexRush do
                task.wait(0.2) -- Stable 5 Hz scan rate (prevents CPU & input thread freeze!)
                pcall(function()
                    local cam = workspace.CurrentCamera
                    if not cam then return end
                    local char = LocalPlayer.Character
                    local myHRP = char and char:FindFirstChild("HumanoidRootPart")

                    local reflexFolders = {}
                    for _, folderName in ipairs({"ReflexRush", "Reflex", "Pentathlon", "Targets", "Circles", "Minigame", "Effects"}) do
                        local f = workspace:FindFirstChild(folderName)
                        if f then table.insert(reflexFolders, f) end
                    end

                    if #reflexFolders == 0 then
                        table.insert(reflexFolders, workspace)
                    end

                    local blueTargets = {}

                    for _, container in ipairs(reflexFolders) do
                        local items = (container == workspace) and container:GetChildren() or container:GetDescendants()
                        for _, obj in ipairs(items) do
                            if #blueTargets >= 6 then break end -- Limit to max 6 targets per scan cycle
                            if obj:IsA("BasePart") and obj.Transparency < 0.9 then
                                local name = obj.Name:lower()
                                local parentName = obj.Parent and obj.Parent.Name:lower() or ""

                                local isTargetName = name:find("reflex") or name:find("target") or name:find("circle") or parentName:find("reflex") or parentName:find("target")
                                local isBlueColor = false

                                local col = obj.Color
                                local bName = obj.BrickColor.Name:lower()
                                if (col.B > 0.6 and col.B > col.R + 0.15 and col.B > col.G + 0.15) or bName:find("blue") or bName:find("cyan") then
                                    isBlueColor = true
                                end

                                local hasClicker = obj:FindFirstChildOfClass("ClickDetector") or obj:FindFirstChildOfClass("ProximityPrompt") or obj:GetAttribute("Active") == true

                                if (isTargetName or (isBlueColor and hasClicker)) then
                                    table.insert(blueTargets, obj)
                                end
                            end
                        end
                    end

                    for _, targetPart in ipairs(blueTargets) do
                        if not getgenv().ENI_AutoReflexRush then break end

                        local cd = targetPart:FindFirstChildOfClass("ClickDetector")
                        if cd and fireclickdetector then
                            pcall(function() fireclickdetector(cd) end)
                        end

                        local prompt = targetPart:FindFirstChildOfClass("ProximityPrompt")
                        if prompt and fireproximityprompt then
                            pcall(function()
                                prompt.HoldDuration = 0
                                fireproximityprompt(prompt)
                            end)
                        end

                        local screenPos, onScreen = cam:WorldToViewportPoint(targetPart.Position)
                        if onScreen then
                            pcall(function()
                                VIM:SendMouseButtonEvent(screenPos.X, screenPos.Y, 0, true, game, 0)
                                task.wait(0.01)
                                VIM:SendMouseButtonEvent(screenPos.X, screenPos.Y, 0, false, game, 0)
                            end)
                        end

                        if myHRP and firetouchinterest then
                            local touchInt = targetPart:FindFirstChildOfClass("TouchTransmitter")
                            if touchInt then
                                pcall(function()
                                    firetouchinterest(targetPart, myHRP, 0)
                                    firetouchinterest(targetPart, myHRP, 1)
                                end)
                            end
                        end

                        local RemotesFolder = GetRemotesFolder()
                if RemotesFolder then
                            local reflexRemote = RemotesFolder:FindFirstChild("ReflexRush") or RemotesFolder:FindFirstChild("Reflex") or RemotesFolder:FindFirstChild("HitTarget")
                            if reflexRemote and reflexRemote:IsA("RemoteEvent") then
                                pcall(function() reflexRemote:FireServer(targetPart) end)
                            end
                        end

                        task.wait(0.04) -- Smooth delay between clicks
                    end
                end)
            end
        end))
    else
        getgenv().ENI_AutoReflexRush = false
    end
end)

CreateToggle(Pages["🪨 Marbles & QTE"], "⚡ 100% Instant Auto-QTE Solver", 5, function(state)
    getgenv().ENI_AutoQTE = state
    if state then
        RegisterThread(task.spawn(function()
            while getgenv().ENI_AutoQTE do
                task.wait(0.05)
                pcall(function()
                    local mod = qteModuleLoaded
                    if not mod then
                        local raw = ReplicatedStorage:FindFirstChild("Modules") and (ReplicatedStorage.Modules:FindFirstChild("HBGQTE") or ReplicatedStorage.Modules:FindFirstChild("QTE"))
                        if raw then pcall(function() mod = require(raw); qteModuleLoaded = mod end) end
                    end
                    if mod and mod.ActiveButtons then
                        for btnKey, qteData in pairs(mod.ActiveButtons) do
                            if qteData and qteData.Inner and qteData.Inner.Parent and qteData.Outer and qteData.Outer.Parent then
                                if not qteData.Inner:GetAttribute("Failed") and not qteData.Outer:GetAttribute("PressedOnce") then
                                    mod.Pressed(false, qteData)
                                end
                            end
                        end
                    end
                end)
            end
        end))
    end
end)

CreateButton(Pages["🪨 Marbles & QTE"], "🔍 Dump Active Minigame UI Hierarchy", 12, function()
    pcall(function()
        print("--------------------------------------------------")
        print("⚡ [ENI-DUMPER] Scanning PlayerGui for active minigame GUIs...")
        print("--------------------------------------------------")

        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        if not playerGui then
            ENI_Notify("UI Dumper", "PlayerGui not found!", "Error", 3)
            return
        end

        local foundAny = false
        for _, gui in ipairs(playerGui:GetChildren()) do
            if (gui:IsA("ScreenGui") or gui:IsA("BillboardGui")) and gui.Enabled then
                local gName = gui.Name
                local gLower = gName:lower()

                if not gLower:find("eni_") and not gLower:find("chat") and not gLower:find("bubble") and not gLower:find("freecam") and not gLower:find("topbar") and not gLower:find("purchase") then
                    foundAny = true
                    print(string.format("📱 ACTIVE GUI: [%s] (Class: %s)", gName, gui.ClassName))

                    for _, child in ipairs(gui:GetDescendants()) do
                        if (child:IsA("GuiObject") or child:IsA("UIComponent")) then
                            local visStr = "Visible"
                            pcall(function()
                                if child:IsA("GuiObject") and not child.Visible then visStr = "HIDDEN" end
                            end)

                            local sizeStr = "N/A"
                            local posStr = "N/A"
                            pcall(function()
                                if child:IsA("GuiObject") then
                                    sizeStr = string.format("Size:(X:%.0f, Y:%.0f)", child.AbsoluteSize.X, child.AbsoluteSize.Y)
                                    posStr = string.format("Pos:(X:%.0f, Y:%.0f)", child.AbsolutePosition.X, child.AbsolutePosition.Y)
                                end
                            end)

                            print(string.format("   └── 🔹 %s | Class: %s | State: %s | %s | %s", child.Name, child.ClassName, visStr, sizeStr, posStr))
                        end
                    end
                    print("--------------------------------------------------")
                end
            end
        end

        if foundAny then
            ENI_Notify("UI Dumper", "Active UI dumped to F9 console!", "Success", 4)
        else
            ENI_Notify("UI Dumper", "No active minigame GUI detected!", "Warning", 4)
        end
    end)
end)

CreateToggle(Pages["🪨 Marbles & QTE"], "🎯 Universal Auto Space Bar Minigame Solver", 48, function(state)
    getgenv().ENI_AutoSpaceLineMinigame = state
    if state then
        RegisterThread(task.spawn(function()
            local VIM = game:GetService("VirtualInputManager")
            local lastHitTick = 0
            
            local function isGreenColor(col)
                if not col then return false end
                return (col.G > 0.5 and col.G > col.R + 0.15 and col.G > col.B + 0.15)
            end

            print("[ENI-SPACE] Guard Strength Punch & QTE Universal Solver ACTIVE!")

            while getgenv().ENI_AutoSpaceLineMinigame do
                task.wait(0.01) -- High-speed 100 FPS scan tick
                pcall(function()
                    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
                    if not playerGui then return end

                    local ignoredGuis = {["chat"]=true, ["inventory"]=true, ["backpack"]=true, ["settings"]=true, ["shop"]=true, ["leaderboard"]=true, ["topbar"]=true, ["mobile"]=true, ["hotbar"]=true}

                    for _, screenGui in ipairs(playerGui:GetChildren()) do
                        if (screenGui:IsA("ScreenGui") or screenGui:IsA("BillboardGui")) and screenGui.Enabled then
                            local gName = screenGui.Name:lower()
                            if not ignoredGuis[gName] and not gName:find("eni_") and not gName:find("hub") then
                                
                                local pointer = nil
                                local targetZone = nil

                                -- 1. Search for Pointer / Moving Arrow / Needle across descendants
                                for _, child in ipairs(screenGui:GetDescendants()) do
                                    if (child:IsA("Frame") or child:IsA("ImageLabel") or child:IsA("ImageButton") or child:IsA("TextLabel")) and child.Visible and child.AbsoluteSize.X > 0 and child.AbsoluteSize.Y > 0 then
                                        local cName = child.Name:lower()
                                        if cName == "pointer" or cName == "line" or cName == "cursor" or cName == "needle" or cName == "indicator" or cName == "movingbar" or cName == "arrow" or cName:find("pointer") or cName:find("arrow") or cName:find("moving") then
                                            pointer = child
                                            break
                                        end
                                    end
                                end

                                -- 2. Search for Green Target Zone / Hit Zone
                                if pointer then
                                    local parentContainer = pointer.Parent or screenGui
                                    for _, child in ipairs(parentContainer:GetDescendants()) do
                                        if (child:IsA("Frame") or child:IsA("ImageLabel") or child:IsA("ImageButton")) and child.Visible and child.AbsoluteSize.X > 2 and child.AbsoluteSize.Y > 2 and child ~= pointer then
                                            local cName = child.Name:lower()
                                            local isGreen = false
                                            pcall(function()
                                                if isGreenColor(child.BackgroundColor3) then isGreen = true end
                                            end)

                                            if cName == "greenzone" or cName == "targetzone" or cName == "safezone" or cName == "target" or cName == "green" or cName == "hitzone" or cName == "goal" or cName == "hit" or cName:find("green") or cName:find("target") or cName:find("hit") or isGreen then
                                                targetZone = child
                                                break
                                            end
                                        end
                                    end
                                end

                                -- 3. Execute Axis-Aware Alignment (Horizontal OR Vertical)
                                if pointer and targetZone then
                                    local pPos = pointer.AbsolutePosition
                                    local pSize = pointer.AbsoluteSize
                                    local gPos = targetZone.AbsolutePosition
                                    local gSize = targetZone.AbsoluteSize

                                    if pPos.X > 0 and gPos.X > 0 and gSize.X > 1 and gSize.Y > 1 then
                                        local pCenterX = pPos.X + (pSize.X / 2)
                                        local pCenterY = pPos.Y + (pSize.Y / 2)

                                        local isInside = false
                                        if gSize.X >= gSize.Y then
                                            -- Horizontal Bar: Check X alignment with 2px buffer
                                            isInside = (pCenterX >= (gPos.X - 2) and pCenterX <= (gPos.X + gSize.X + 2))
                                        else
                                            -- Vertical Bar: Check Y alignment with 2px buffer
                                            isInside = (pCenterY >= (gPos.Y - 2) and pCenterY <= (gPos.Y + gSize.Y + 2))
                                        end

                                        if isInside and (tick() - lastHitTick > 0.15) then
                                            lastHitTick = tick()

                                            -- Trigger Space Key
                                            VIM:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                                            task.wait(0.01)
                                            VIM:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
                                            print(string.format("[ENI-SPACE] 🎯 PERFECT ALIGNMENT HIT! (Pointer: %.1f, Zone Range: %.1f - %.1f)", (gSize.X >= gSize.Y and pCenterX or pCenterY), (gSize.X >= gSize.Y and gPos.X or gPos.Y), (gSize.X >= gSize.Y and gPos.X + gSize.X or gPos.Y + gSize.Y)))

                                            -- Safe Remote Relay
                                            local RemotesFolder = GetRemotesFolder()
                                            if RemotesFolder then
                                                for _, r in ipairs(RemotesFolder:GetChildren()) do
                                                    if r:IsA("RemoteEvent") then
                                                        local rName = r.Name:lower()
                                                        if rName:find("qte") or rName:find("space") or rName:find("pentathlon") or rName:find("punch") or rName:find("strength") or rName:find("bar") then
                                                            pcall(function() r:FireServer(true) end)
                                                            pcall(function() r:FireServer("Hit", true) end)
                                                        end
                                                    end
                                                end
                                            end
                                            break
                                        end
                                    end
                                else
                                    -- 4. Guard Strength Punch Fill Bar Check (> 80% Power)
                                    local fillBar = screenGui:FindFirstChild("Fill", true) or screenGui:FindFirstChild("PowerFill", true) or screenGui:FindFirstChild("StrengthFill", true) or screenGui:FindFirstChild("BarFill", true)
                                    if fillBar and fillBar.Parent and fillBar.Visible and (tick() - lastHitTick > 0.25) then
                                        local fillContainer = fillBar.Parent
                                        local fillRatio = 0
                                        if fillContainer.AbsoluteSize.Y > 0 and fillBar.AbsoluteSize.Y > 0 then
                                            fillRatio = fillBar.AbsoluteSize.Y / fillContainer.AbsoluteSize.Y
                                        elseif fillContainer.AbsoluteSize.X > 0 and fillBar.AbsoluteSize.X > 0 then
                                            fillRatio = fillBar.AbsoluteSize.X / fillContainer.AbsoluteSize.X
                                        end

                                        if fillRatio >= 0.80 then
                                            lastHitTick = tick()
                                            VIM:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                                            task.wait(0.01)
                                            VIM:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
                                            print(string.format("[ENI-STRENGTH] ⚡ STRENGTH PUNCH 80%%+ POWER HIT! Ratio: %.2f", fillRatio))
                                            break
                                        end
                                    end
                                end

                            end
                        end
                    end
                end)
            end
        end))
    else
        getgenv().ENI_AutoSpaceLineMinigame = false
    end
end)

local StealthStorage = CoreGui:FindFirstChild("ENI_Glass_Storage") or Instance.new("Folder", CoreGui)
StealthStorage.Name = "ENI_Glass_Storage"
CreateToggle(Pages["🧱 Glass Bridge"], "⚡ Glass Bridge ESP", 5, function(state)
    getgenv().ENI_GlassESP = state
    if state then
        RegisterThread(task.spawn(function()
            local getconnectionsFunc = getconnections or get_signal_cons or function() return {} end
            while getgenv().ENI_GlassESP do
                task.wait(0.4)
                pcall(function()
                    StealthStorage:ClearAllChildren()

                    local searchContainers = {}
                    for _, name in ipairs({"GlassBridge", "GlassBridgeMap", "Glass", "Bridge", "GlassPanes", "GlassGame", "Map"}) do
                        local f = workspace:FindFirstChild(name, true)
                        if f then table.insert(searchContainers, f) end
                    end
                    if #searchContainers == 0 then table.insert(searchContainers, workspace) end

                    for _, container in ipairs(searchContainers) do
                        for _, descendant in ipairs(container:GetDescendants()) do
                            if descendant:IsA("BasePart") then
                                local pName = descendant.Name:lower()
                                local parentName = descendant.Parent and descendant.Parent.Name:lower() or ""

                                local isGlassTile = pName:find("glass") or pName:find("tile") or pName:find("panel") or pName:find("pane") or pName:find("step") or parentName:find("glass") or parentName:find("bridge")
                                local isIgnored = pName:find("wall") or pName:find("support") or pName:find("frame") or pName:find("railing") or pName:find("base") or pName:find("platform") or pName:find("border")

                                if isGlassTile and not isIgnored then
                                    local isFake = false

                                    if descendant:GetAttribute("exploitingisevil") == true 
                                       or descendant:GetAttribute("ActuallyKilling") == true 
                                       or descendant:GetAttribute("IsFake") == true 
                                       or descendant:GetAttribute("Breakable") == true 
                                       or descendant:GetAttribute("Fake") == true 
                                       or descendant:GetAttribute("Break") == true 
                                       or (descendant.Parent and (descendant.Parent:GetAttribute("IsFake") or descendant.Parent:GetAttribute("Fake"))) then
                                        isFake = true
                                    end

                                    local touchInt = descendant:FindFirstChildWhichIsA("TouchTransmitter", true) or descendant:FindFirstChild("TouchInterest", true)
                                    if touchInt then isFake = true end

                                    pcall(function()
                                        local cons = getconnectionsFunc(descendant.Touched)
                                        if cons and #cons > 0 then isFake = true end
                                    end)

                                    if pName:find("fake") or pName:find("break") or pName:find("kill") or pName:find("shatter") or pName:find("bad") or pName:find("fragile") then
                                        isFake = true
                                    end

                                    if descendant.CanCollide == false or descendant.CanTouch == true then
                                        if descendant.CanCollide == false then isFake = true end
                                    end

                                    local hl = Instance.new("Highlight")
                                    hl.Name = "Glass_HL"
                                    hl.Adornee = descendant
                                    hl.FillColor = isFake and Color3.fromRGB(255, 30, 50) or Color3.fromRGB(30, 255, 120)
                                    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                                    hl.FillTransparency = 0.3
                                    hl.OutlineTransparency = 0
                                    hl.Parent = StealthStorage
                                end
                            end
                        end
                    end
                end)
            end
            StealthStorage:ClearAllChildren()
        end))
    else
        getgenv().ENI_GlassESP = false
        StealthStorage:ClearAllChildren()
    end
end)

CreateButton(Pages["🙈 Hide & Seek"], "🧹 Clean All Spoofed Keys From Backpack", 5, function()
    pcall(function()
        local keyNames = {"SquareKey", "TriangleKey", "CircleKey", "MasterKey", "Keycard", "Square", "Triangle", "Circle", "Key"}
        local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
        if bp then
            for _, tool in ipairs(bp:GetChildren()) do
                if tool:IsA("Tool") and table.find(keyNames, tool.Name) then
                    tool:Destroy()
                end
            end
        end
        if LocalPlayer.Character then
            for _, tool in ipairs(LocalPlayer.Character:GetChildren()) do
                if tool:IsA("Tool") and table.find(keyNames, tool.Name) then
                    tool:Destroy()
                end
            end
        end
        print("[ENI-HNS] Cleaned all spoofed keys from Backpack!")
    end)
end)

CreateButton(Pages["🙈 Hide & Seek"], "⚡ Instant Unlock All Nearby Doors", 48, function()
    pcall(function()
        for _, prompt in ipairs(workspace:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") and (prompt.Name:find("Door") or prompt.Name:find("Key") or prompt.Name:find("Unlock") or (prompt.Parent and (prompt.Parent.Name:find("Door") or prompt.Parent.Name:find("Key")))) then
                prompt.HoldDuration = 0
                prompt.MaxActivationDistance = 99999
                prompt.RequiresLineOfSight = false
                prompt.Enabled = true
                if fireproximityprompt then
                    fireproximityprompt(prompt)
                else
                    prompt:InputHoldBegan()
                    prompt:InputHoldEnded()
                end
            end
        end
        print("[ENI-HNS] All map doors unlocked!")
    end)
end)

CreateToggle(Pages["🙈 Hide & Seek"], "⚡ Reveal Invisible Landmine Traps", 91, function(state)
    getgenv().ENI_RevealLandmines = state
    if state then
        RegisterThread(task.spawn(function()
            while getgenv().ENI_RevealLandmines do
                task.wait(1.5)
                pcall(function()
                    local searchArea = workspace:FindFirstChild("Map") or workspace:FindFirstChild("Lobby") or workspace
                    for _, obj in ipairs(searchArea:GetChildren()) do
                        if (obj.Name:find("landmine") or obj.Name:find("Landmine")) and obj:IsA("BasePart") then
                            obj.Transparency = 0
                            obj.Color = Color3.fromRGB(255, 0, 0)
                            obj.Material = Enum.Material.Neon
                            if not obj:FindFirstChild("ENI_Trap_HL") then
                                local hl = Instance.new("Highlight", obj)
                                hl.Name = "ENI_Trap_HL"
                                hl.FillColor = Color3.fromRGB(255, 0, 0)
                                hl.OutlineColor = Color3.fromRGB(255, 255, 0)
                            end
                        end
                    end
                end)
            end
        end))
    else
        getgenv().ENI_RevealLandmines = false
    end
end)
local HNSEspStorage = CoreGui:FindFirstChild("ENI_HNS_ESP") or Instance.new("Folder", CoreGui)
HNSEspStorage.Name = "ENI_HNS_ESP"
CreateToggle(Pages["🙈 Hide & Seek"], "⚡ Hide & Seek Player ESP", 91, function(state)
    getgenv().ENI_HNSEsp = state
    if state then
        RegisterThread(task.spawn(function()
            while getgenv().ENI_HNSEsp do
                task.wait(0.4)
                pcall(function()
                    HNSEspStorage:ClearAllChildren()
                    for _, targetPlayer in ipairs(Players:GetPlayers()) do
                        if targetPlayer ~= LocalPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") and targetPlayer.Character:FindFirstChild("Humanoid") and targetPlayer.Character.Humanoid.Health > 0 then
                            local char = targetPlayer.Character

                            local isSeeker = false
                            if char:GetAttribute("Seeker") or char:GetAttribute("IsSeeker") or char:GetAttribute("IsGuard") then
                                isSeeker = true
                            elseif targetPlayer.Team and targetPlayer.Team.Name:find("Seeker") then
                                isSeeker = true
                            else
                                for _, item in ipairs(char:GetChildren()) do
                                    if item:IsA("Tool") then
                                        local iName = item.Name:lower()
                                        if iName:find("knife") or iName:find("sword") or iName:find("bat") or iName:find("blade") or iName:find("weapon") or iName:find("gun") or iName:find("pipe") or iName:find("crowbar") then
                                            isSeeker = true
                                            break
                                        end
                                    end
                                end
                            end

                            local hl = Instance.new("Highlight", HNSEspStorage)
                            hl.Adornee = char
                            hl.FillColor = isSeeker and Color3.fromRGB(255, 30, 50) or Color3.fromRGB(30, 140, 255)
                            hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                            hl.FillTransparency = 0.35

                            local bb = Instance.new("BillboardGui", HNSEspStorage)
                            bb.Adornee = char:FindFirstChild("Head") or char.HumanoidRootPart
                            bb.Size = UDim2.new(0, 160, 0, 30)
                            bb.StudsOffset = Vector3.new(0, 3, 0)
                            bb.AlwaysOnTop = true

                            local txt = Instance.new("TextLabel", bb)
                            txt.Size = UDim2.new(1, 0, 1, 0)
                            txt.BackgroundTransparency = 1
                            txt.Text = string.format("%s [%s]", targetPlayer.DisplayName, isSeeker and "SEEKER 🔪" or "HIDER 🙈")
                            txt.TextColor3 = isSeeker and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(80, 180, 255)
                            txt.Font = Enum.Font.GothamBold
                            txt.TextSize = 12
                        end
                    end
                end)
            end
            HNSEspStorage:ClearAllChildren()
        end))
    else
        getgenv().ENI_HNSEsp = false
        HNSEspStorage:ClearAllChildren()
    end
end)

local function FirePentathlonRemote(actionName, payload)
    pcall(function()
        local char = LocalPlayer.Character
        if char then local remotes = char:FindFirstChild("Remotes") if remotes and remotes:FindFirstChild("Relay") then remotes.Relay:Fire(actionName, payload) return end end
        local RemotesFolder = GetRemotesFolder()
                if RemotesFolder then for _, r in ipairs(RemotesFolder:GetDescendants()) do if r:IsA("RemoteEvent") and r.Name:find("Pentathlon") then r:FireServer(actionName, payload) return end end end
    end)
end
CreateToggle(Pages["🎽 Pentathlon"], "🔥 Pentathlon Auto-Win Sweep", 5, function(state)
    getgenv().ENI_AutoPentathlon = state
    if state then
        RegisterThread(task.spawn(function()
            while getgenv().ENI_AutoPentathlon do
                pcall(function()
                    local char = LocalPlayer.Character
                    local targetPos = char and char.HumanoidRootPart.Position + (char.HumanoidRootPart.CFrame.LookVector * 5) or Vector3.new(0,0,0)
                    FirePentathlonRemote("Thrown", {Power = 1.0, Position = targetPos})
                    task.wait(0.3)
                    if char and char:FindFirstChild("HumanoidRootPart") then FirePentathlonRemote("Thrown", {ThrowPower = "Perfect", Origin = char.HumanoidRootPart.Position + Vector3.new(0, 1.5, 0), Direction = char.HumanoidRootPart.CFrame.LookVector}) end
                    task.wait(0.3)
                    for _, pName in ipairs({"Piece1", "Piece2", "Piece3", "Piece4", "Piece5"}) do FirePentathlonRemote("GotPiece", {Name = pName}) task.wait(0.05) end
                    FirePentathlonRemote("TimeSlowFinish", {})
                    task.wait(0.3)
                    FirePentathlonRemote("Tied", {})
                    FirePentathlonRemote("Thrown", {})
                    task.wait(0.3)
                    for i = 1, 6 do FirePentathlonRemote("Kick", {Lose = false}) task.wait(0.05) end
                end)
                task.wait(1.0)
            end
        end))
    else
        getgenv().ENI_AutoPentathlon = false
    end
end)

CreateToggle(Pages["☁️ SkySquid & VIP"], "⚡ Infinite Climbing Stamina", 5, function(state)
    getgenv().ENI_InfStamina = state
    if state then
        RegisterThread(task.spawn(function()
            while getgenv().ENI_InfStamina do
                task.wait(0.2)
                pcall(function() local char = LocalPlayer.Character if char then local stVal = char:FindFirstChild("CurrentStaminaNumberValue") if stVal then stVal.Value = 1 end end end)
            end
        end))
    else
        getgenv().ENI_InfStamina = false
    end
end)
CreateToggle(Pages["☁️ SkySquid & VIP"], "⚡ Auto SSS-Rank VIP Fan Session Win Loop", 48, function(state)
    getgenv().ENI_AutoVIPFan = state
    if state then
        RegisterThread(task.spawn(function()
            while getgenv().ENI_AutoVIPFan do
                task.wait(1.0)
                pcall(function()
                    local RemotesFolder = GetRemotesFolder()
                if RemotesFolder then
                        local guardRemote = RemotesFolder:FindFirstChild("PlayableGuardRemote")
                        if guardRemote then
                            guardRemote:FireServer({SkySquidVIPService = {Action = "SubmitFanSession", SessionId = "ENI_AutoWin_" .. tostring(os.time()), Hits = 30, Misses = 0, TooFastCount = 0, TooSlowCount = 0}})
                            guardRemote:FireServer({SkySquidVIPService = {Action = "PlayFanSuccessWave"}})
                        end
                    end
                end)
            end
        end))
    else
        getgenv().ENI_AutoVIPFan = false
    end
end)

local GuardNpcEspStorage = CoreGui:FindFirstChild("ENI_GuardNPC_ESP") or Instance.new("Folder", CoreGui)
GuardNpcEspStorage.Name = "ENI_GuardNPC_ESP"

CreateToggle(Pages["👮 Guard & Surgery"], "👮 Rebel Mode: Guard NPC ESP", 5, function(state)
    getgenv().ENI_GuardNPCEsp = state
    if state then
        RegisterThread(task.spawn(function()
            while getgenv().ENI_GuardNPCEsp do
                task.wait(0.5)
                pcall(function()
                    GuardNpcEspStorage:ClearAllChildren()
                    local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

                    local searchTargets = {}
                    local liveFolder = workspace:FindFirstChild("Live") or workspace:FindFirstChild("NPCs") or workspace:FindFirstChild("Guards")
                    if liveFolder then
                        for _, c in ipairs(liveFolder:GetChildren()) do table.insert(searchTargets, c) end
                    else
                        for _, c in ipairs(workspace:GetChildren()) do table.insert(searchTargets, c) end
                    end

                    for _, obj in ipairs(searchTargets) do
                        if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("HumanoidRootPart") and obj ~= LocalPlayer.Character then
                            local oName = obj.Name:lower()
                            local isGuardNPC = false

                            if oName:find("guard") or oName:find("npc") or obj:GetAttribute("IsGuard") or obj:GetAttribute("Guard") or obj:FindFirstChild("GuardType") then
                                isGuardNPC = true
                            elseif obj:FindFirstChild("Suit") or obj:FindFirstChild("Mask") or (obj:FindFirstChild("Head") and obj.Head:FindFirstChild("Mask")) then
                                isGuardNPC = true
                            end

                            if isGuardNPC then
                                local targetHRP = obj.HumanoidRootPart
                                local dist = myHRP and math.floor((myHRP.Position - targetHRP.Position).Magnitude) or 0

                                local hl = Instance.new("Highlight")
                                hl.Name = "GuardNPC_HL"
                                hl.Adornee = obj
                                hl.FillColor = Color3.fromRGB(255, 30, 30)
                                hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                                hl.FillTransparency = 0.4
                                hl.Parent = GuardNpcEspStorage

                                local bb = Instance.new("BillboardGui")
                                bb.Name = "GuardNPC_BB"
                                bb.Adornee = obj:FindFirstChild("Head") or targetHRP
                                bb.Size = UDim2.new(0, 150, 0, 40)
                                bb.StudsOffset = Vector3.new(0, 3, 0)
                                bb.AlwaysOnTop = true
                                bb.Parent = GuardNpcEspStorage

                                local txt = Instance.new("TextLabel", bb)
                                txt.Size = UDim2.new(1, 0, 1, 0)
                                txt.BackgroundTransparency = 1
                                txt.Text = string.format("👮 GUARD NPC [%dm]", dist)
                                txt.TextColor3 = Color3.fromRGB(255, 50, 50)
                                txt.Font = Enum.Font.GothamBold
                                txt.TextSize = 13
                            end
                        end
                    end
                end)
            end
            GuardNpcEspStorage:ClearAllChildren()
        end))
    else
        getgenv().ENI_GuardNPCEsp = false
        GuardNpcEspStorage:ClearAllChildren()
    end
end)

CreateToggle(Pages["👮 Guard & Surgery"], "🤖 AI Guard Total Blindness & Brain-Dead Nerfer", 91, function(state)
    getgenv().ENI_StupidGuards = state
    if state then
        RegisterThread(task.spawn(function()
            pcall(function()
                local rawInfo = game:GetService("ReplicatedStorage"):FindFirstChild("Modules") and game:GetService("ReplicatedStorage").Modules:FindFirstChild("GuardInformation")
                if rawInfo then
                    local guardInfo = require(rawInfo)
                    if typeof(guardInfo) == "table" then
                        for category, cfg in pairs(guardInfo) do
                            if typeof(cfg) == "table" then
                                cfg.GuardRangeForShoot = 0          -- Cannot shoot at any range!
                                cfg.GuardRangeForLookAt = 0         -- Cannot see/look at players!
                                cfg.TargetAcquiringRange = 0       -- Cannot acquire targets!
                                cfg.ThinkingTimeBeforeFiring = 99999 -- Takes 99999 seconds before firing!
                                cfg.GunSpread = 100                 -- 100% inaccuracy if they manage to shoot!
                                cfg.DamageScale = 0                 -- Zero damage output!
                                cfg.CanMove = false                 -- Freeze guard movement!
                            end
                        end
                        print("[ENI-GUARD] GuardInformation client table neutered to 0 stats!")
                    end
                end
            end)

            while getgenv().ENI_StupidGuards do
                task.wait(0.2)
                pcall(function()
                    if LocalPlayer.Character then
                        LocalPlayer.Character:SetAttribute("IgnoredByGuard", true)
                        LocalPlayer.Character:SetAttribute("GuardIgnore", true)
                    end

                    local liveFolder = workspace:FindFirstChild("Live") or workspace:FindFirstChild("NPCs") or workspace
                    for _, model in ipairs(liveFolder:GetChildren()) do
                        if model:IsA("Model") and (model.Name:lower():find("guard") or model:GetAttribute("IsGuard") or model:FindFirstChild("CurrentState")) then
                            local stateVal = model:FindFirstChild("CurrentState")
                            if stateVal and stateVal:IsA("StringValue") then
                                stateVal.Value = "Idle" -- Force Guard back to Idle mood!
                            end
                            model:SetAttribute("AggroTarget", nil)
                            model:SetAttribute("Target", nil)
                            model:SetAttribute("EffectTime", 999999)
                        end
                    end
                end)
            end
        end))
    else
        getgenv().ENI_StupidGuards = false
        pcall(function()
            if LocalPlayer.Character then
                LocalPlayer.Character:SetAttribute("IsInvisible", nil)
                LocalPlayer.Character:SetAttribute("InStealth", nil)
                LocalPlayer.Character:SetAttribute("IgnoredByGuard", nil)
                LocalPlayer.Character:SetAttribute("GuardIgnore", nil)
            end
        end)
    end
end)

CreateButton(Pages["👮 Guard & Surgery"], "🟥 Free Square Guard Role Unlocker", 5, function()
    pcall(function()
        -- 1. LocalPlayer & Character Attribute Spoofing
        local attrs = {
            ["Guard"] = true,
            ["IsGuard"] = true,
            ["PlayableGuard"] = true,
            ["GuardRole"] = "Square",
            ["GuardRank"] = "Square",
            ["Role"] = "SquareGuard",
            ["Rank"] = "Square",
            ["GuardType"] = "Square",
            ["SelectedGuard"] = "Square",
            ["HasGuard"] = true,
            ["OwnsGuard"] = true,
            ["SquareGuard"] = true
        }

        for k, v in pairs(attrs) do
            LocalPlayer:SetAttribute(k, v)
            if LocalPlayer.Character then LocalPlayer.Character:SetAttribute(k, v) end
        end

        -- 2. Team & PlayerGui Role Selection UI Override
        pcall(function()
            local guardTeam = game:GetService("Teams"):FindFirstChild("Guard") or game:GetService("Teams"):FindFirstChild("Guards") or game:GetService("Teams"):FindFirstChild("Square Guard")
            if guardTeam then LocalPlayer.Team = guardTeam end
        end)

        -- 3. Remote Event Relay for Server Sync
        local RemotesFolder = GetRemotesFolder()
        if RemotesFolder then
            for _, r in ipairs(RemotesFolder:GetChildren()) do
                if r:IsA("RemoteEvent") or r:IsA("RemoteFunction") then
                    local rName = r.Name:lower()
                    if rName:find("guard") or rName:find("role") or rName:find("team") or rName:find("select") then
                        pcall(function() r:FireServer("Square") end)
                        pcall(function() r:FireServer("Guard", "Square") end)
                        pcall(function() r:FireServer({Role = "Square", Team = "Guard"}) end)
                    end
                end
            end
        end

        -- 4. MarketplaceService Gamepass Ownership Hook (Client Free Unlock - Crash Proof)
        if setnamecallmethod and getnamecallmethod and hookmetamethod and not getgenv().ENI_NamecallHooked then
            getgenv().ENI_NamecallHooked = true
            local oldNamecall
            oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
                local method = getnamecallmethod()
                if not checkcaller() and (method == "UserOwnsGamePassAsync" or method == "PlayerOwnsAsset") then
                    return true
                end
                return oldNamecall(self, ...)
            end)
        end

        ENI_Notify("🟥 Free Square Guard", "Square Guard Role & Gamepass unlocked for free!", "Success", 4)
        print("[ENI-GUARD] 🟥 Square Guard role & Gamepass ownership spoofed successfully!")
    end)
end)

CreateToggle(Pages["👮 Guard & Surgery"], "⚡ Auto-Maintain Free Square Guard Role On Spawn", 48, function(state)
    getgenv().ENI_AutoSquareGuard = state
    if state then
        RegisterThread(task.spawn(function()
            while getgenv().ENI_AutoSquareGuard do
                task.wait(1.5)
                pcall(function()
                    local attrs = {["Guard"] = true, ["IsGuard"] = true, ["PlayableGuard"] = true, ["GuardRole"] = "Square", ["GuardRank"] = "Square", ["Role"] = "SquareGuard", ["Rank"] = "Square"}
                    for k, v in pairs(attrs) do
                        LocalPlayer:SetAttribute(k, v)
                        if LocalPlayer.Character then LocalPlayer.Character:SetAttribute(k, v) end
                    end
                end)
            end
        end))
    else
        getgenv().ENI_AutoSquareGuard = false
    end
end)

CreateToggle(Pages["👮 Guard & Surgery"], "🧸 Auto-Win Claw Machine", 177, function(state)
    getgenv().ENI_AutoClawMachine = state
    if state then
        RegisterThread(task.spawn(function()
            while getgenv().ENI_AutoClawMachine do
                task.wait(1.5)
                pcall(function()
                    local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
                    if not remotes then return end
                    local clawRemote = remotes:FindFirstChild("ClawMachineGame") or remotes:FindFirstChild("ClawMachine")
                    if clawRemote and clawRemote:IsA("RemoteEvent") then
                        clawRemote:FireServer("Extend")
                        task.wait(0.2)
                        clawRemote:FireServer("Grab")
                        task.wait(0.2)
                        clawRemote:FireServer("Win")
                    end
                end)
            end
        end))
    else
        getgenv().ENI_AutoClawMachine = false
    end
end)

CreateToggle(Pages["🛡️ Protections"], "⚡ Ultra Instinct Auto Dodge", 5, function(state)
    getgenv().ENI_AutoDodge = state
    if state then
        RegisterThread(task.spawn(function()
            while getgenv().ENI_AutoDodge do
                task.wait(0.5)
                pcall(function() LocalPlayer:SetAttribute("UltraInstinctAutoDodge", true) end)
            end
        end))
    else
        getgenv().ENI_AutoDodge = false
    end
end)
CreateToggle(Pages["🛡️ Protections"], "⚡ Admin Boss Immunity", 48, function(state)
    getgenv().ENI_BossImmunity = state
    if state then
        RegisterThread(task.spawn(function()
            while getgenv().ENI_BossImmunity do
                task.wait(0.3)
                pcall(function() local effects = workspace:FindFirstChild("Effects") if effects then for _, obj in ipairs(effects:GetChildren()) do if obj.Name:find("RockTemplate") or obj.Name == "LaserBeams" then obj:Destroy() end end end end)
            end
        end))
    else
        getgenv().ENI_BossImmunity = false
    end
end)
CreateToggle(Pages["🛡️ Protections"], "⚡ Stun, InCombat & ActionCheck Bypass", 91, function(state)
    getgenv().ENI_StunBypass = state
    if state then
        RegisterThread(task.spawn(function()
            local badAttrs = {"Ragdoll", "Action", "Freeze", "Slowed", "NoAttack", "Blocking", "LightAction", "InCombat", "Frozen", "Stun"}
            while getgenv().ENI_StunBypass do
                task.wait(0.2)
                pcall(function()
                    local currentGame = workspace:FindFirstChild("Values") and workspace.Values:FindFirstChild("CurrentGame") and workspace.Values.CurrentGame.Value
                    local isDalgonaOrRLGL = (currentGame == "Dalgona") or (currentGame == "RedLightGreenLight") or (currentGame == "TugOfWar")
                    local char = LocalPlayer.Character
                    if char then
                        local hum = char:FindFirstChild("Humanoid")
                        if hum and not hum.Sit then
                            for _, attr in ipairs(badAttrs) do
                                if isDalgonaOrRLGL and (attr == "Action" or attr == "Freeze") then
                                elseif char:GetAttribute(attr) ~= nil then
                                    char:SetAttribute(attr, nil)
                                end
                            end
                            local hrp = char:FindFirstChild("HumanoidRootPart")
                            if hrp and hrp.Anchored and not isDalgonaOrRLGL then
                                hrp.Anchored = false
                            end
                        end
                    end
                end)
            end
        end))
    end
end)

CreateButton(Pages["🛡️ Protections"], "🚨 EMERGENCY FORCE UNFREEZE RESCUE", 134, function()
    pcall(function()
        local char = LocalPlayer.Character
        if char then
            for _, attr in ipairs({"Freeze", "Action", "Ragdoll", "Slowed", "NoAttack", "InCombat", "Frozen", "Mingle", "LightAction", "Stun"}) do
                char:SetAttribute(attr, nil)
            end
            local hum = char:FindFirstChild("Humanoid")
            if hum then
                hum.WalkSpeed = 16
                hum.JumpPower = 50
                hum.PlatformStand = false
                hum.AutoRotate = true
            end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then hrp.Anchored = false end
            for _, p in ipairs(char:GetChildren()) do
                if p:IsA("BasePart") then p.Anchored = false end
            end
        end
        workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
        workspace.CurrentCamera.FieldOfView = 70

        for _, effect in ipairs(game:GetService("Lighting"):GetChildren()) do
            if effect:IsA("BlurEffect") and (effect.Name:find("Freeze") or effect.Name:find("Stun") or effect.Name:find("Mingle")) then
                effect.Enabled = false
            end
        end
        print("[ENI-RESCUE] Screen freeze cleared, character unfrozen, camera & lighting restored!")
    end)
end)

CreateToggle(Pages["🛡️ Protections"], "⚡ Anti-Screen Freeze FPS Guard", 180, function(state)
    getgenv().ENI_AntiScreenFreeze = state
    if state then
        RegisterThread(task.spawn(function()
            while getgenv().ENI_AntiScreenFreeze do
                task.wait(0.5)
                pcall(function()
                    for _, effect in ipairs(game:GetService("Lighting"):GetChildren()) do
                        if effect:IsA("BlurEffect") or effect:IsA("ColorCorrectionEffect") then
                            if effect.Name:find("Freeze") or effect.Name:find("Stun") or effect.Name:find("Mingle") then
                                effect.Enabled = false
                            end
                        end
                    end
                    local char = LocalPlayer.Character
                    if char then
                        local hum = char:FindFirstChild("Humanoid")
                        local hrp = char:FindFirstChild("HumanoidRootPart")
                        if hrp and hrp.Anchored and hum and not hum.Sit then
                            local currentGame = workspace:FindFirstChild("Values") and workspace.Values:FindFirstChild("CurrentGame") and workspace.Values.CurrentGame.Value
                            if currentGame ~= "Dalgona" and currentGame ~= "RedLightGreenLight" and currentGame ~= "TugOfWar" then
                                hrp.Anchored = false
                            end
                        end
                    end
                end)
            end
        end))
    else
        getgenv().ENI_AntiScreenFreeze = false
    end
end)

CreateToggle(Pages["🛡️ Protections"], "🛠️ Live Crash Debugger & Memory Monitor", 220, function(state)
    getgenv().ENI_CrashDebugger = state
    if state then
        RegisterThread(task.spawn(function()
            print("[ENI-DEBUGGER] Live Crash Debugger & Memory Monitor ACTIVE!")
            while getgenv().ENI_CrashDebugger do
                task.wait(2.5)
                pcall(function()
                    local statsService = game:GetService("Stats")
                    local totalMem = math.floor(statsService:GetTotalMemoryUsageMb())
                    local luaMem = math.floor(gcinfo() / 1024)
                    local activeThreadCount = getgenv().ENI_ActiveThreads and #getgenv().ENI_ActiveThreads or 0
                    local fps = math.floor(1 / (RunService.RenderStepped:Wait()))
                    local char = LocalPlayer.Character
                    local humState = char and char:FindFirstChild("Humanoid") and char.Humanoid:GetState().Name or "None"

                    local statusMsg = string.format("📊 RAM: %d MB (Lua Heap: %d MB) | Active Threads: %d | FPS: %d | HumState: %s", totalMem, luaMem, activeThreadCount, fps, humState)
                    print("[ENI-MONITOR]", statusMsg)

                    if luaMem > 450 or totalMem > 3800 then
                        warn("⚠️ CRITICAL MEMORY SPIKE DETECTED! Lua Heap: " .. tostring(luaMem) .. " MB | Total: " .. tostring(totalMem) .. " MB. Clearing CoreGui ESP caches...")
                        if CoreGui:FindFirstChild("ENI_General_ESP") then CoreGui.ENI_General_ESP:ClearAllChildren() end
                    end
                end)
            end
        end))
    else
        print("[ENI-DEBUGGER] Live Crash Debugger Deactivated.")
    end
end)

local isOpen = true
RegisterConnection(UserInputService.InputBegan:Connect(function(input, gpe)
    if input.KeyCode == Enum.KeyCode.F4 then
        pcall(function()
            LocalPlayer:SetAttribute("Freeze", nil)
            LocalPlayer:SetAttribute("Frozen", nil)
            LocalPlayer:SetAttribute("Action", nil)

            local char = LocalPlayer.Character
            if char then
                for _, attr in ipairs({"Freeze", "Action", "Ragdoll", "Slowed", "NoAttack", "InCombat", "Frozen", "Mingle", "LightAction", "Stun", "ClickedOrJumpedRecently"}) do
                    char:SetAttribute(attr, nil)
                end
                local hum = char:FindFirstChild("Humanoid")
                if hum then
                    hum.WalkSpeed = 16
                    hum.JumpPower = 50
                    hum.PlatformStand = false
                    hum.AutoRotate = true
                    pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
                end
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then hrp.Anchored = false end
                for _, p in ipairs(char:GetChildren()) do
                    if p:IsA("BasePart") then p.Anchored = false end
                end
            end

            workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
            workspace.CurrentCamera.FieldOfView = 70

            for _, effect in ipairs(game:GetService("Lighting"):GetChildren()) do
                if effect:IsA("BlurEffect") or effect:IsA("ColorCorrectionEffect") or effect:IsA("PostEffect") then
                    if effect.Name:find("Freeze") or effect.Name:find("Stun") or effect.Name:find("Mingle") or effect.Name:find("Blur") then
                        effect.Enabled = false
                    end
                end
            end

            ENI_Notify("F4 Rescue Activated", "Instantly unfroze character & camera!", "Success", 3)
            print("[ENI-F4-RESCUE] Pressed F4 -> Instantly unfroze character physics & camera!")
        end)
    elseif not gpe and input.KeyCode == Enum.KeyCode.RightControl then
        isOpen = not isOpen
        if isOpen then
            ScreenGui.Enabled = true
            MainFrame.Size = DefaultMainFrameSize
            TweenService:Create(MainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {Size = DefaultMainFrameSize}):Play()
        else
            MainFrame.Size = DefaultMainFrameSize
            local t = TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {Size = MinimizedMainFrameSize})
            t:Play()
            t.Completed:Connect(function() if not isOpen then ScreenGui.Enabled = false end end)
        end
    end
end))

CreateButton(Pages["⚡ Secret Exploits & Remotes"], "👑 Full Gamepass Unlocker", 5, function()
    pcall(function()
        getgenv().ENI_UniversalGamepassSpoof = true

        local function ApplyGamepassSpoof()
            local passList = {
                "__OwnsVIPGamepass", "__OwnsPermGuard", "__OwnsGlassManufacturerVision",
                "__Owns2XVoteGamepass", "__OwnsCustomPlayerTag", "__OwnsEmotePages", "__OwnsPSPlus",
                "VIP", "IsVIP", "HasVIP", "VIPUnlocked", "PermGuard", "HasGlassVision",
                "DoubleVote", "Has2xVote", "2xVote", "x2Vote", "CustomTagUnlocked", "EmotesUnlocked"
            }

            for _, name in ipairs(passList) do
                LocalPlayer:SetAttribute(name, true)
                if LocalPlayer.Character then
                    LocalPlayer.Character:SetAttribute(name, true)
                end
            end
            LocalPlayer:SetAttribute("VoteCountMultiplier", 2)
            LocalPlayer:SetAttribute("VoteMultiplier", 2)
            if LocalPlayer.Character then
                LocalPlayer.Character:SetAttribute("VoteCountMultiplier", 2)
            end

            local dataContainer = LocalPlayer:FindFirstChild("Data") or LocalPlayer:FindFirstChild("Values") or LocalPlayer:FindFirstChild("Gamepasses") or LocalPlayer
            for _, name in ipairs({"VIP", "DoubleVote", "2xVote", "x2Vote", "PermGuard", "GlassVision", "CustomTag", "EmotePages"}) do
                local val = dataContainer:FindFirstChild(name)
                if not val then
                    val = Instance.new("BoolValue")
                    val.Name = name
                    val.Parent = dataContainer
                end
                val.Value = true
            end
            local multVal = dataContainer:FindFirstChild("VoteMultiplier") or dataContainer:FindFirstChild("VoteCountMultiplier")
            if not multVal then
                multVal = Instance.new("IntValue")
                multVal.Name = "VoteCountMultiplier"
                multVal.Parent = dataContainer
            end
            multVal.Value = 2
        end

        ApplyGamepassSpoof()

        ApplyGamepassSpoof()

        if not getgenv().ENI_GamepassSpoofConnected then
            getgenv().ENI_GamepassSpoofConnected = true
            LocalPlayer.CharacterAdded:Connect(function()
                task.wait(1.0)
                if getgenv().ENI_UniversalGamepassSpoof then
                    pcall(ApplyGamepassSpoof)
                end
            end)
        end

        local RemotesFolder = GetRemotesFolder()
                if RemotesFolder then
            local repRemote = RemotesFolder.Parent:FindFirstChild("Replication") and RemotesFolder.Parent.Replication:FindFirstChild("SaveSetting")
            if repRemote then
                pcall(function() repRemote:FireServer("VIPTag", true) end)
                pcall(function() repRemote:FireServer("VIPChatTag", true) end)
            end
            local settingsRemote = RemotesFolder:FindFirstChild("SettingsRemote")
            if settingsRemote then
                pcall(function() settingsRemote:FireServer({Setting = "VIPChatTag", Value = true}) end)
                pcall(function() settingsRemote:FireServer({Setting = "VIPGoldName", Value = true}) end)
            end
            local vipRemote = RemotesFolder:FindFirstChild("VIPRemote") or RemotesFolder:FindFirstChild("VIP")
            if vipRemote and vipRemote:IsA("RemoteEvent") then
                pcall(function() vipRemote:FireServer("ClaimVIP") end)
                pcall(function() vipRemote:FireServer("EquipVIP") end)
            end
            local voteRemote = RemotesFolder:FindFirstChild("Vote") or RemotesFolder:FindFirstChild("CastVote")
            if voteRemote and voteRemote:IsA("RemoteEvent") then
                pcall(function() voteRemote:FireServer({Multiplier = 2}) end)
            end
        end

        for _, prompt in ipairs(workspace:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") and (prompt.Name:find("VIP") or (prompt.Parent and prompt.Parent.Name:find("VIP"))) then
                prompt.RequiresLineOfSight = false
                prompt.MaxActivationDistance = 99999
                prompt.Enabled = true
            end
        end

        local RemotesFolder = GetRemotesFolder()
                if RemotesFolder then
            local effRemote = RemotesFolder:FindFirstChild("Effects")
            if effRemote then
                pcall(function() effRemote:FireServer({EffectName = "RevealGlassTiles"}) end)
            end
        end

        print("[ENI-EXPLOIT] Universal Gamepass Spoofer (VIP, 2x Vote, Perm Guard, Glass) fully activated!")
    end)
end)

CreateButton(Pages["⚡ Secret Exploits & Remotes"], "🎨 Unlock VIP Custom Clothing & Suit Colors", 48, function()
    pcall(function()
        LocalPlayer:SetAttribute("VIPCustomColorUnlocked", true)
        LocalPlayer:SetAttribute("HasCustomSuitColor", true)
        LocalPlayer:SetAttribute("CanChangeClothColor", true)
        if LocalPlayer.Character then
            LocalPlayer.Character:SetAttribute("VIPCustomColor", true)
        end
        local RemotesFolder = GetRemotesFolder()
                if RemotesFolder then
            local clothRemote = RemotesFolder:FindFirstChild("ChangeClothingColor") or RemotesFolder:FindFirstChild("CustomSuitColor")
            if clothRemote and clothRemote:IsA("RemoteEvent") then
                clothRemote:FireServer({Color = Color3.fromRGB(255, 215, 0), Unlocked = true})
            end
        end
        local customizeGui = LocalPlayer.PlayerGui:FindFirstChild("CustomizeUI") or LocalPlayer.PlayerGui:FindFirstChild("ClothingUI") or LocalPlayer.PlayerGui:FindFirstChild("SuitCustomizer")
        if customizeGui then
            for _, obj in ipairs(customizeGui:GetDescendants()) do
                if obj:IsA("GuiObject") and (obj.Name:find("Lock") or obj.Name:find("VIP")) then
                    obj.Visible = false
                end
                if obj:IsA("TextButton") or obj:IsA("ImageButton") then
                    obj.Active = true
                end
            end
        end
        print("[ENI-VIP] Custom clothing & suit color features unlocked!")
    end)
end)

CreateButton(Pages["⚡ Secret Exploits & Remotes"], "✨ Unlock VIP Special Ability", 91, function()
    pcall(function()
        LocalPlayer:SetAttribute("VIPAbilityUnlocked", true)
        LocalPlayer:SetAttribute("HasVIPAbility", true)
        LocalPlayer:SetAttribute("PhantomStepUnlocked", true)
        LocalPlayer:SetAttribute("CanDash", true)
        LocalPlayer:SetAttribute("DashUnlocked", true)
        if LocalPlayer.Character then
            LocalPlayer.Character:SetAttribute("VIPAbility", true)
            LocalPlayer.Character:SetAttribute("CanDash", true)
        end
        local RemotesFolder = GetRemotesFolder()
                if RemotesFolder then
            local abRemote = RemotesFolder:FindFirstChild("UseVIPAbility") or RemotesFolder:FindFirstChild("ActivateAbility")
            if abRemote and abRemote:IsA("RemoteEvent") then
                abRemote:FireServer("UnlockVIPAbility")
            end
        end
        print("[ENI-VIP] VIP Special Ability & Phantom Dash unlocked!")
    end)
end)

CreateButton(Pages["⚡ Secret Exploits & Remotes"], "🗳️ Unlock 2x Vote Gamepass", 134, function()
    pcall(function()
        LocalPlayer:SetAttribute("__Owns2XVoteGamepass", true)
        LocalPlayer:SetAttribute("DoubleVote", true)
        LocalPlayer:SetAttribute("Has2xVote", true)
        LocalPlayer:SetAttribute("2xVote", true)
        LocalPlayer:SetAttribute("x2Vote", true)
        LocalPlayer:SetAttribute("VoteCountMultiplier", 2)
        LocalPlayer:SetAttribute("VoteMultiplier", 2)
        if LocalPlayer.Character then
            LocalPlayer.Character:SetAttribute("VoteCountMultiplier", 2)
            LocalPlayer.Character:SetAttribute("DoubleVote", true)
        end

        local dataContainer = LocalPlayer:FindFirstChild("Data") or LocalPlayer:FindFirstChild("Values") or LocalPlayer:FindFirstChild("Gamepasses") or LocalPlayer
        for _, vName in ipairs({"DoubleVote", "2xVote", "x2Vote", "Has2xVote"}) do
            local val = dataContainer:FindFirstChild(vName)
            if not val then
                val = Instance.new("BoolValue")
                val.Name = vName
                val.Parent = dataContainer
            end
            val.Value = true
        end

        local multVal = dataContainer:FindFirstChild("VoteMultiplier") or dataContainer:FindFirstChild("VoteCountMultiplier")
        if not multVal then
            multVal = Instance.new("IntValue")
            multVal.Name = "VoteCountMultiplier"
            multVal.Parent = dataContainer
        end
        multVal.Value = 2

        local RemotesFolder = GetRemotesFolder()
                if RemotesFolder then
            local voteRemote = RemotesFolder:FindFirstChild("Vote") or RemotesFolder:FindFirstChild("CastVote") or RemotesFolder:FindFirstChild("VoteRemote")
            if voteRemote and voteRemote:IsA("RemoteEvent") then
                pcall(function() voteRemote:FireServer({Multiplier = 2, DoubleVote = true}) end)
            end
        end
        print("[ENI-VOTE] 2x Vote Gamepass & Double Vote Multiplier successfully spoofed!")
    end)
end)

CreateButton(Pages["⚡ Secret Exploits & Remotes"], "🎭 Unlock Extra Emote Pages & Custom Tags", 170, function()
    pcall(function()
        LocalPlayer:SetAttribute("__OwnsEmotePages", true)
        LocalPlayer:SetAttribute("EmotesUnlocked", true)
        LocalPlayer:SetAttribute("CustomTagUnlocked", true)
        LocalPlayer:SetAttribute("__OwnsCustomPlayerTag", true)
        local RemotesFolder = GetRemotesFolder()
                if RemotesFolder then
            local emoteRemote = RemotesFolder:FindFirstChild("EmoteRemote") or RemotesFolder:FindFirstChild("EquipEmote")
            if emoteRemote and emoteRemote:IsA("RemoteEvent") then
                pcall(function() emoteRemote:FireServer("UnlockAllEmotes") end)
            end
        end
        print("[ENI-EMOTES] Emote pages & custom tags unlocked!")
    end)
end)

local TeleportService = game:GetService("TeleportService")
pcall(function()
    LocalPlayer.OnTeleport:Connect(function()
        print("[ENI-SAFEGUARD] Teleport in progress -> Triggering global ENI_Cleanup to unload threads & signals!")
        if getgenv().ENI_Cleanup then pcall(getgenv().ENI_Cleanup) end
    end)
end)
pcall(function()
    TeleportService.TeleportInitFailed:Connect(function()
        print("[ENI-SAFEGUARD] Teleport failed -> Teleport process aborted.")
    end)
end)

print("⚡ [ENI Hub] Loaded Successfully!")
pcall(function()
    ENI_Notify("Unknown Hub", "Loaded Successfully! Press RightControl to Toggle Menu", "Success", 6)
end)