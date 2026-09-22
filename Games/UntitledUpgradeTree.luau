-- =========================================================================
-- UNKNOWN HUB - UNTITLED UPGRADE TREE
-- Game: Untitled Upgrade Tree
-- Features: Auto Upgrade (Auto Buy Buttons)
-- =========================================================================

local LIBRARY_LINK = "https://raw.githubusercontent.com/UnknownHQ/UnknownHub/main/UnknownLibrary"
local LIBRARY_NAME = "Unknown_TabbedHub_UI"

local currentSession = tick()
_G.UUT_SESSION = currentSession

-- =========================================================================
-- Core Roblox Services
-- =========================================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- =========================================================================
-- Anti-AFK Safeguard
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

-- =========================================================================
-- Universal UI Cleanup Handler
-- =========================================================================
local function destroyOldGui()
    local parents = {game:GetService("CoreGui")}
    if gethui then pcall(function() table.insert(parents, gethui()) end) end
    local playerGui = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
    if playerGui then table.insert(parents, playerGui) end
    for _, parent in ipairs(parents) do
        if parent then
            pcall(function()
                for _, child in ipairs(parent:GetChildren()) do
                    if child:IsA("ScreenGui") and (child.Name == LIBRARY_NAME or child.Name == "Unknown_MainGui") then
                        pcall(function() child:Destroy() end)
                    end
                end
            end)
        end
    end
end

-- =========================================================================
-- Load Unknown Hub Library Factory
-- =========================================================================
local ok, factory = pcall(function()
    local cacheBuster = "?t=" .. tostring(os.time() or tick()) .. "_" .. tostring(math.random(1000, 9999))
    local source = game:HttpGet(LIBRARY_LINK .. cacheBuster)
    pcall(function()
        source = source:gsub("game:GetService%([\"']CoreGui[\"']%)", "(gethui and gethui() or (game:GetService(\"Players\").LocalPlayer and game:GetService(\"Players\").LocalPlayer:WaitForChild(\"PlayerGui\")))")
    end)
    local factoryChunk = loadstring(source)
    return factoryChunk()
end)

if not ok or not factory then
    warn("[Unknown Hub] Failed to load library factory: " .. tostring(factory))
    return
end

destroyOldGui()

-- =========================================================================
-- Remotes & Upgrade Logic
-- =========================================================================
local BuyUpgRemote = nil
pcall(function()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes and remotes:FindFirstChild("BuyUpg") then
        BuyUpgRemote = remotes.BuyUpg
    end
end)

local function buyAllAvailableUpgrades()
    if not BuyUpgRemote then
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if remotes and remotes:FindFirstChild("BuyUpg") then
            BuyUpgRemote = remotes.BuyUpg
        end
    end
    if not BuyUpgRemote then return 0 end

    local wsUpgrades = Workspace:FindFirstChild("Upgrades")
    if not wsUpgrades then return 0 end

    local count = 0
    for _, upg in ipairs(wsUpgrades:GetChildren()) do
        local upgId = tonumber(upg.Name)
        if upgId then
            pcall(function()
                BuyUpgRemote:FireServer(upgId)
            end)
            count = count + 1
        end
    end
    return count
end

-- =========================================================================
-- State Management
-- =========================================================================
local State = {
    AutoUpgrade = false,
    UpgradeInterval = 0.1
}

-- =========================================================================
-- Initialize Unknown Hub Instance
-- =========================================================================
local Hub = factory({
    name = LIBRARY_NAME,
    title = "UNTITLED UPGRADE TREE",
    subTitle = "Auto Upgrade",
    theme = Color3.fromRGB(0, 215, 255),
    secondaryTheme = Color3.fromRGB(165, 95, 255),
    onClose = function()
        _G.UUT_SESSION = nil
        State.AutoUpgrade = false
    end
})

-- =========================================================================
-- Main Tab: Automation
-- =========================================================================
local mainTab = Hub.createPage("🏠 Main")

Hub.CreateSection(mainTab, "UPGRADE AUTOMATION")

-- Auto Upgrade Loop Toggle
Hub.CreateToggle(mainTab, "Auto Buy Upgrades", false, function(enabled)
    State.AutoUpgrade = enabled
    if enabled then
        task.spawn(function()
            while State.AutoUpgrade and _G.UUT_SESSION == currentSession do
                buyAllAvailableUpgrades()
                task.wait(State.UpgradeInterval or 0.1)
            end
        end)
        Hub.Notify({
            Title = "Auto Upgrade",
            Content = "Auto buying all tree upgrades...",
            Duration = 2
        })
    end
end)

-- Upgrade Speed / Delay Slider
Hub.CreateSlider(mainTab, "Upgrade Delay", 0.05, 1.0, 0.1, "s", function(val)
    State.UpgradeInterval = val
end)

-- 1-Click Buy All Button
Hub.CreateButton(mainTab, "Buy All Upgrades (1-Click)", function()
    local bought = buyAllAvailableUpgrades()
    Hub.Notify({
        Title = "Upgrades",
        Content = string.format("Fired buy for %d available upgrades!", bought),
        Duration = 2
    })
end)

-- =========================================================================
-- Startup Notification
-- =========================================================================
Hub.Notify({
    Title = "Unknown Hub",
    Content = "Untitled Upgrade Tree loaded!",
    Duration = 3
})
