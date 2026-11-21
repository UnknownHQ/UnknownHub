--[[
    ========================================================================
    UNKNOWN HUB | SELL DIRT (AI-Slop Specialist Suite)
    Features:
      - Full Auto Production Line (Dig -> Mold -> Dry -> Polish -> Sell)
      - Individual Action Farm Toggles (Auto Dig, Auto Mold, Auto Polish, Auto Crank)
      - Auto Plot Upgrader (Shovel Luck, Digger Speed, Molder)
      - Instant Plot & Vendor Teleports
      - 24/7 Anti-AFK Safeguard
    ========================================================================
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer

-- Session Cleanup Management
if _G.SELLDIRT_CLEANUP and type(_G.SELLDIRT_CLEANUP) == "function" then
    pcall(_G.SELLDIRT_CLEANUP)
end

local sessionConnections = {}
local sessionThreads = {}

local function trackConn(conn)
    if conn then table.insert(sessionConnections, conn) end
    return conn
end

local function trackThread(th)
    if th then table.insert(sessionThreads, th) end
    return th
end

_G.SELLDIRT_SESSION = tick()
local currentSession = _G.SELLDIRT_SESSION

_G.SELLDIRT_CLEANUP = function()
    _G.SELLDIRT_SESSION = tick()
    for _, conn in ipairs(sessionConnections) do
        pcall(function() if conn and conn.Disconnect then conn:Disconnect() end end)
    end
    table.clear(sessionConnections)
    for _, th in ipairs(sessionThreads) do
        pcall(function() if th and task.cancel then task.cancel(th) end end)
    end
    table.clear(sessionThreads)
    pcall(function()
        local parent = (gethui and gethui()) or game:GetService("CoreGui") or (LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui"))
        if parent then
            for _, child in ipairs(parent:GetChildren()) do
                if child.Name == "Unknown_TabbedHub_UI" or child.Name:find("Unknown_SellDirt") then
                    pcall(function() child:Destroy() end)
                end
            end
        end
    end)
end

-- =========================================================================
-- Anti-AFK
-- =========================================================================
pcall(function()
    LocalPlayer.Idled:Connect(function()
        pcall(function()
            if VirtualUser then
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.zero)
            end
        end)
    end)
end)

-- =========================================================================
-- Remotes & References
-- =========================================================================
local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes", 5)
local PerformAction = RemotesFolder and RemotesFolder:WaitForChild("PerformAction", 5)

-- =========================================================================
-- State Table
-- =========================================================================
local State = {
    MasterAutoFarm = false,
    AutoDig = false,
    AutoMold = false,
    AutoPolish = false,
    AutoCrank = false,
    AutoUpgrades = false,
    TapDelay = 0.05,
    WalkSpeed_Enabled = false,
    WalkSpeed_Value = 24,
    InfiniteJump = false
}

-- =========================================================================
-- Helper Functions
-- =========================================================================
local function getMyPlot()
    local plots = Workspace:FindFirstChild("Plots")
    if not plots then return nil end
    for _, plot in ipairs(plots:GetChildren()) do
        if plot:GetAttribute("OwnerUserId") == LocalPlayer.UserId then
            return plot
        end
    end
    for _, plot in ipairs(plots:GetChildren()) do
        local owner = plot:GetAttribute("Owner") or plot:FindFirstChild("Owner")
        if owner and (tostring(owner) == LocalPlayer.Name or tostring(owner) == tostring(LocalPlayer.UserId)) then
            return plot
        end
    end
    return nil
end

local function getMyBall()
    local balls = Workspace:FindFirstChild("Balls")
    if not balls then return nil end
    for _, b in ipairs(balls:GetChildren()) do
        if b:GetAttribute("OwnerUserId") == LocalPlayer.UserId then
            return b
        end
    end
    return nil
end

local function safeTeleport(cframe)
    local char = LocalPlayer.Character
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    hrp.CFrame = cframe
    return true
end

local function triggerPrompt(prompt)
    if not prompt or not prompt:IsA("ProximityPrompt") then return false end
    pcall(function()
        prompt.RequiresLineOfSight = false
        prompt.MaxActivationDistance = 99999
        if fireproximityprompt then
            fireproximityprompt(prompt)
        end
    end)
    return true
end

local function safeFire(actionName, a1, a2, a3)
    if not PerformAction then return end
    pcall(function()
        PerformAction:FireServer(actionName, a1, a2, a3)
    end)
end

-- =========================================================================
-- Master Production Cycle Engine
-- =========================================================================
trackThread(task.spawn(function()
    while true do
        if _G.SELLDIRT_SESSION ~= currentSession then break end
        if State.MasterAutoFarm then
            local plot = getMyPlot()
            if plot then
                local ball = getMyBall()
                if not ball then
                    -- Step 1: Dig
                    local digPad = plot:FindFirstChild("DigSite") and plot.DigSite:FindFirstChild("DigPad")
                    if digPad then
                        safeTeleport(digPad.CFrame + Vector3.new(0, 3, 0))
                        local prompt = digPad:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if prompt then triggerPrompt(prompt) end
                        for _ = 1, 15 do
                            safeFire("Dig")
                            task.wait(State.TapDelay)
                            if getMyBall() then break end
                        end
                    end
                else
                    -- Ball exists! Let's examine where it is and process it.
                    local moldPad = plot:FindFirstChild("Trough") and plot.Trough:FindFirstChild("MoldPad")
                    local dryPad = plot:FindFirstChild("Rack") and plot.Rack:FindFirstChild("DryPad")
                    local polishPad = plot:FindFirstChild("Bench") and plot.Bench:FindFirstChild("PolishPad")
                    local sellPad = plot:FindFirstChild("Vendor") and plot.Vendor:FindFirstChild("SellPad")

                    local bPos = ball.Position
                    local effect = ball:GetAttribute("Effect")
                    local bb = ball:FindFirstChild("BillboardGui")
                    local labelObj = bb and bb:FindFirstChildWhichIsA("TextLabel", true)
                    local labelText = labelObj and labelObj.Text or ""

                    if effect or (polishPad and (bPos - polishPad.Position).Magnitude > 15 and labelText == "" and dryPad and (bPos - dryPad.Position).Magnitude > 15 and moldPad and (bPos - moldPad.Position).Magnitude > 15) then
                        -- Polished or ready to sell! Step to SellPad
                        if sellPad then
                            safeTeleport(sellPad.CFrame + Vector3.new(0, 3, 0))
                            local prompt = sellPad:FindFirstChildWhichIsA("ProximityPrompt", true)
                            if prompt then triggerPrompt(prompt) end
                            safeFire("Sell")
                            task.wait(0.3)
                        end
                    elseif labelText == "DRY" then
                        -- Finished drying! Pick it up from dry rack
                        if dryPad then
                            safeTeleport(dryPad.CFrame + Vector3.new(0, 3, 0))
                            local prompt = dryPad:FindFirstChildWhichIsA("ProximityPrompt", true)
                            if prompt then triggerPrompt(prompt) end
                            task.wait(0.2)
                        end
                    elseif dryPad and (bPos - dryPad.Position).Magnitude < 10 then
                        -- Currently drying on the rack! While drying, crank generator or wait
                        safeFire("Crank")
                        task.wait(0.2)
                    elseif polishPad and (bPos - polishPad.Position).Magnitude < 10 then
                        -- On the polish bench! Fire Polish
                        safeTeleport(polishPad.CFrame + Vector3.new(0, 3, 0))
                        for _ = 1, 10 do
                            safeFire("Polish")
                            task.wait(State.TapDelay)
                        end
                    else
                        -- In hand or at mold pad!
                        -- Let's try molding if not molded yet
                        if moldPad then
                            safeTeleport(moldPad.CFrame + Vector3.new(0, 3, 0))
                            local prompt = moldPad:FindFirstChildWhichIsA("ProximityPrompt", true)
                            if prompt then triggerPrompt(prompt) end
                            for _ = 1, 12 do
                                safeFire("Mold")
                                task.wait(State.TapDelay)
                            end
                        end
                        -- Now place onto dry pad
                        if dryPad then
                            safeTeleport(dryPad.CFrame + Vector3.new(0, 3, 0))
                            local prompt = dryPad:FindFirstChildWhichIsA("ProximityPrompt", true)
                            if prompt then triggerPrompt(prompt) end
                            task.wait(0.25)
                        end
                        -- Or place onto polish pad if dry
                        if polishPad then
                            safeTeleport(polishPad.CFrame + Vector3.new(0, 3, 0))
                            local prompt = polishPad:FindFirstChildWhichIsA("ProximityPrompt", true)
                            if prompt then triggerPrompt(prompt) end
                            task.wait(0.25)
                        end
                    end
                end
            end
        end
        task.wait(0.1)
    end
end))

-- =========================================================================
-- Individual Action Loops
-- =========================================================================
trackThread(task.spawn(function()
    while true do
        if _G.SELLDIRT_SESSION ~= currentSession then break end
        if State.AutoDig and not State.MasterAutoFarm then
            safeFire("Dig")
        end
        task.wait(State.TapDelay)
    end
end))

trackThread(task.spawn(function()
    while true do
        if _G.SELLDIRT_SESSION ~= currentSession then break end
        if State.AutoMold and not State.MasterAutoFarm then
            safeFire("Mold")
        end
        task.wait(State.TapDelay)
    end
end))

trackThread(task.spawn(function()
    while true do
        if _G.SELLDIRT_SESSION ~= currentSession then break end
        if State.AutoPolish and not State.MasterAutoFarm then
            safeFire("Polish")
        end
        task.wait(State.TapDelay)
    end
end))

trackThread(task.spawn(function()
    while true do
        if _G.SELLDIRT_SESSION ~= currentSession then break end
        if State.AutoCrank then
            safeFire("Crank")
        end
        task.wait(State.TapDelay)
    end
end))

-- Auto Upgrade Loop
trackThread(task.spawn(function()
    while true do
        if _G.SELLDIRT_SESSION ~= currentSession then break end
        if State.AutoUpgrades then
            local plot = getMyPlot()
            if plot then
                local upgFolder = plot:FindFirstChild("Upgrades")
                if upgFolder then
                    for _, desc in ipairs(upgFolder:GetDescendants()) do
                        if desc:IsA("ProximityPrompt") and desc.Enabled then
                            triggerPrompt(desc)
                        end
                    end
                end
            end
        end
        task.wait(1.5)
    end
end))

-- Character Speed & Jump
trackConn(RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum and State.WalkSpeed_Enabled then
        hum.WalkSpeed = State.WalkSpeed_Value
    end
end))

-- =========================================================================
-- UnknownLibrary UI Construction
-- =========================================================================
local LIBRARY_LINK = "https://raw.githubusercontent.com/UnknownHQ/UnknownHub/main/UnknownLibrary"
local ok, result = pcall(function()
    local source
    if readfile then
        pcall(function() source = readfile("UnknownLibrary.luau") end)
        if not source or #source < 100 then
            pcall(function() source = readfile("UnknownLibrary") end)
        end
    end
    if not source or #source < 100 then
        source = game:HttpGet(LIBRARY_LINK .. "?t=" .. tostring(tick()))
    end
    local factoryChunk, err = loadstring(source)
    assert(factoryChunk, "UnknownLibrary failed to compile: " .. tostring(err))
    return factoryChunk()
end)

if not ok or type(result) ~= "function" then
    warn("[Unknown Hub] Library load failure: " .. tostring(result))
    return
end

local Hub = result({
    name = "Unknown_TabbedHub_UI",
    title = "UNKNOWN HUB",
    subTitle = "SELL DIRT",
    theme = Color3.fromRGB(245, 175, 25),
    secondaryTheme = Color3.fromRGB(0, 205, 255)
})

assert(type(Hub) == "table", "Hub instance is invalid")

-- Tabs
local farmTab = Hub.CreateTab("🌾 Auto-Farm", "🌾")
local upgradeTab = Hub.CreateTab("⚡ Plot & Upgrades", "⚡")
local playerTab = Hub.CreateTab("👤 Player & Misc", "👤")

-- Automation Tab
Hub.CreateSection(farmTab, "Master Auto-Production")
Hub.CreateToggle(farmTab, "🚀 Master Auto Production Cycle", State.MasterAutoFarm, function(v)
    State.MasterAutoFarm = v
    Hub.Notify("Auto-Farm", v and "Full Cycle Activated! Dig -> Mold -> Dry -> Polish -> Sell" or "Master Auto-Farm Stopped", 2.5)
end)

Hub.CreateSlider(farmTab, "Tap & Action Speed", 1, 20, 15, " taps/s", function(v)
    State.TapDelay = 1 / math.max(v, 1)
end)

Hub.CreateSection(farmTab, "Granular Action Loops")
Hub.CreateToggle(farmTab, "Auto Dig Loop", State.AutoDig, function(v)
    State.AutoDig = v
end)
Hub.CreateToggle(farmTab, "Auto Mold Loop", State.AutoMold, function(v)
    State.AutoMold = v
end)
Hub.CreateToggle(farmTab, "Auto Polish Loop", State.AutoPolish, function(v)
    State.AutoPolish = v
end)
Hub.CreateToggle(farmTab, "Auto Crank Generator (Infinite Power)", State.AutoCrank, function(v)
    State.AutoCrank = v
end)

-- Plot & Upgrades Tab
Hub.CreateSection(upgradeTab, "Plot Automation")
Hub.CreateToggle(upgradeTab, "Auto Buy Plot Upgrades (Luck & Speed)", State.AutoUpgrades, function(v)
    State.AutoUpgrades = v
    Hub.Notify("Upgrades", v and "Auto Upgrades: ON" or "Auto Upgrades: OFF", 2)
end)

Hub.CreateSection(upgradeTab, "Plot Navigation & Teleports")
Hub.CreateButton(upgradeTab, "Teleport to Dig Site", function()
    local plot = getMyPlot()
    local pad = plot and plot:FindFirstChild("DigSite") and plot.DigSite:FindFirstChild("DigPad")
    if pad then safeTeleport(pad.CFrame + Vector3.new(0, 3, 0)) end
end)

Hub.CreateButton(upgradeTab, "Teleport to Molder / Trough", function()
    local plot = getMyPlot()
    local pad = plot and plot:FindFirstChild("Trough") and plot.Trough:FindFirstChild("MoldPad")
    if pad then safeTeleport(pad.CFrame + Vector3.new(0, 3, 0)) end
end)

Hub.CreateButton(upgradeTab, "Teleport to Drying Rack", function()
    local plot = getMyPlot()
    local pad = plot and plot:FindFirstChild("Rack") and plot.Rack:FindFirstChild("DryPad")
    if pad then safeTeleport(pad.CFrame + Vector3.new(0, 3, 0)) end
end)

Hub.CreateButton(upgradeTab, "Teleport to Polish Bench", function()
    local plot = getMyPlot()
    local pad = plot and plot:FindFirstChild("Bench") and plot.Bench:FindFirstChild("PolishPad")
    if pad then safeTeleport(pad.CFrame + Vector3.new(0, 3, 0)) end
end)

Hub.CreateButton(upgradeTab, "Teleport to Merchant / Sell Pad", function()
    local plot = getMyPlot()
    local pad = plot and plot:FindFirstChild("Vendor") and plot.Vendor:FindFirstChild("SellPad")
    if pad then safeTeleport(pad.CFrame + Vector3.new(0, 3, 0)) end
end)

Hub.CreateButton(upgradeTab, "Teleport to Power Generator", function()
    local plot = getMyPlot()
    local pad = plot and plot:FindFirstChild("Generator") and plot.Generator:FindFirstChild("PromptAnchor")
    if pad then safeTeleport(pad.CFrame + Vector3.new(0, 3, 0)) end
end)

-- Player Tab
Hub.CreateSection(playerTab, "Movement Enhancements")
Hub.CreateToggle(playerTab, "Custom WalkSpeed", State.WalkSpeed_Enabled, function(v)
    State.WalkSpeed_Enabled = v
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum and not v then hum.WalkSpeed = 16 end
end)

Hub.CreateSlider(playerTab, "WalkSpeed Value", 16, 120, State.WalkSpeed_Value, " studs", function(v)
    State.WalkSpeed_Value = v
end)

Hub.CreateSection(playerTab, "Session")
Hub.CreateButton(playerTab, "Unload Hub & Stop All Farms", function()
    if _G.SELLDIRT_CLEANUP then _G.SELLDIRT_CLEANUP() end
end)

Hub.FinishLoading("Sell Dirt Automation Loaded!")
