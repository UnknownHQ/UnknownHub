-- =========================================================================
-- UNKNOWN HUB - UNTITLED UPGRADE TREE
-- Game: Untitled Upgrade Tree
-- Features: Multi-World Mathematical Auto Upgrade & Value Affordability Engine
-- =========================================================================

local LIBRARY_LINK = "https://raw.githubusercontent.com/UnknownHQ/UnknownHub/main/UnknownLibrary.luau"
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
-- Game Upgrade Modules & Mathematical Engine
-- =========================================================================
local InfMaths = nil
local UpgradesModule = nil
local BuyUpgRemote = nil

pcall(function()
    local modules = ReplicatedStorage:FindFirstChild("Modules")
    if modules then
        if modules:FindFirstChild("InfMaths") then
            InfMaths = require(modules.InfMaths)
        end
        if modules:FindFirstChild("Upgrades") then
            UpgradesModule = require(modules.Upgrades)
        end
    end
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes and remotes:FindFirstChild("BuyUpg") then
        BuyUpgRemote = remotes.BuyUpg
    end
end)

local function resolveVal(v)
    if type(v) == "function" then
        local success, res = pcall(v)
        return success and res or nil
    end
    return v
end

local failedAttempts = {}

local function isUpgradeUnlocked(data, playerData, playerUpgrades)
    local rawUnlock = resolveVal(data.Unlock)
    local rawHasUnlock = resolveVal(data.HasUnlock)

    -- Currency unlock flags check
    local currName = tostring(resolveVal(data.CurrencyCost) or "Points")
    if currName ~= "Points" and playerData then
        local unlockFlag1 = playerData:FindFirstChild("Unlocked" .. currName)
        if unlockFlag1 and unlockFlag1:IsA("BoolValue") and unlockFlag1.Value == false then
            return false
        end
        local unlockFlag2 = playerData:FindFirstChild("Unlocked" .. currName .. "s")
        if unlockFlag2 and unlockFlag2:IsA("BoolValue") and unlockFlag2.Value == false then
            return false
        end
    end

    -- Stat-based unlock requirement (e.g. Loop, Stage)
    if type(rawUnlock) == "string" and playerData and playerData:FindFirstChild(rawUnlock) then
        local statVal = tonumber(playerData[rawUnlock].Value) or 0
        local reqVal = tonumber(rawHasUnlock) or 1
        if statVal < reqVal then
            return false
        end
        return true
    end

    local unlockNum = tonumber(rawUnlock)
    local hasUnlockNum = tonumber(rawHasUnlock)

    -- Parent upgrade requirement 1
    if unlockNum and unlockNum > 0 and playerUpgrades then
        local pObj = playerUpgrades:FindFirstChild(tostring(unlockNum))
        local pLvl = pObj and tonumber(pObj.Value) or 0
        if pLvl < 1 then
            return false
        end
    end

    -- Parent upgrade requirement 2
    if hasUnlockNum and hasUnlockNum > 0 and hasUnlockNum ~= unlockNum and playerUpgrades then
        if unlockNum and unlockNum > 0 then
            -- When both Unlock and HasUnlock exist: HasUnlock == 1 denotes required level of parent (Unlock), not upgrade #1
            if hasUnlockNum > 1 then
                local pObj = playerUpgrades:FindFirstChild(tostring(hasUnlockNum))
                local pLvl = pObj and tonumber(pObj.Value) or 0
                if pLvl < 1 then
                    return false
                end
            end
        else
            local pObj = playerUpgrades:FindFirstChild(tostring(hasUnlockNum))
            local pLvl = pObj and tonumber(pObj.Value) or 0
            if pLvl < 1 then
                return false
            end
        end
    end

    return true
end

local function getPlayerBalance(currName)
    local playerData = LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("PlayerData")
    if playerData then
        local valObj = playerData:FindFirstChild(currName)
        if valObj then
            return valObj.Value
        end
    end
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    if leaderstats then
        local valObj = leaderstats:FindFirstChild(currName)
        if valObj then
            return valObj.Value
        end
    end
    return nil
end

local function buyAffordableUpgrades()
    if not BuyUpgRemote then
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if remotes and remotes:FindFirstChild("BuyUpg") then
            BuyUpgRemote = remotes.BuyUpg
        end
    end
    if not BuyUpgRemote then return 0 end

    local playerData = LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("PlayerData")
    local playerUpgrades = LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("Upgrades")

    local boughtCount = 0
    local now = tick()

    -- Primary: Multi-World Mathematical Affordability Engine
    if UpgradesModule and InfMaths and playerUpgrades then
        for id, data in pairs(UpgradesModule) do
            local numId = tonumber(id)
            if numId and type(data) == "table" then
                -- Check failure backoff
                local failInfo = failedAttempts[numId]
                if not failInfo or (now - failInfo.time > 5) then
                    local upgValObj = playerUpgrades:FindFirstChild(tostring(numId))
                    local curLevel = upgValObj and tonumber(upgValObj.Value) or 0
                    local maxLevel = tonumber(resolveVal(data.Max)) or 1

                    if curLevel < maxLevel then
                        if isUpgradeUnlocked(data, playerData, playerUpgrades) then
                            local basePrice = resolveVal(data.Price)
                            if basePrice ~= nil then
                                local priceInc = tonumber(resolveVal(data.PriceInc)) or 1
                                local price = InfMaths.new(basePrice)
                                if curLevel > 0 and priceInc > 1 then
                                    price = price * (priceInc ^ curLevel)
                                end

                                local currName = tostring(resolveVal(data.CurrencyCost) or "Points")
                                local rawBal = getPlayerBalance(currName)

                                if rawBal ~= nil then
                                    local playerBal = InfMaths.new(rawBal)
                                    -- Disallow buying 0-cost if balance is 0 and currency is not Points
                                    local isZeroZero = (currName ~= "Points" and tostring(rawBal) == "0" and tostring(basePrice) == "0")
                                    if not isZeroZero and playerBal >= price then
                                        local prevLevel = curLevel
                                        pcall(function()
                                            BuyUpgRemote:FireServer(numId)
                                        end)
                                        boughtCount = boughtCount + 1

                                        -- Check if purchase went through, else backoff
                                        task.delay(0.4, function()
                                            local updatedObj = playerUpgrades:FindFirstChild(tostring(numId))
                                            local newLevel = updatedObj and tonumber(updatedObj.Value) or 0
                                            if newLevel == prevLevel then
                                                failedAttempts[numId] = { time = tick(), fails = ((failInfo and failInfo.fails or 0) + 1) }
                                            else
                                                failedAttempts[numId] = nil
                                            end
                                        end)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        return boughtCount
    end

    -- Fallback: Physical Workspace Upgrades
    local wsUpgrades = Workspace:FindFirstChild("Upgrades")
    if wsUpgrades then
        for _, upg in ipairs(wsUpgrades:GetChildren()) do
            local upgId = tonumber(upg.Name)
            if upgId then
                pcall(function()
                    BuyUpgRemote:FireServer(upgId)
                end)
                boughtCount = boughtCount + 1
            end
        end
        return boughtCount
    end

    return 0
end

-- =========================================================================
-- State Management
-- =========================================================================
local State = {
    AutoUpgrade = false,
    UpgradeInterval = 0.2
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
                pcall(buyAffordableUpgrades)
                task.wait(State.UpgradeInterval or 0.2)
            end
        end)
        Hub.SendNotification({
            Title = "Auto Upgrade",
            Content = "Auto buying all affordable tree upgrades...",
            Duration = 2
        })
    end
end)

-- Upgrade Speed / Delay Slider
Hub.CreateSlider(mainTab, "Upgrade Delay", 0.05, 2.0, 0.2, "s", function(val)
    State.UpgradeInterval = val
end)

-- 1-Click Buy All Button
Hub.CreateButton(mainTab, "Buy All Affordable (1-Click)", function()
    local bought = buyAffordableUpgrades()
    Hub.SendNotification({
        Title = "Upgrades",
        Content = string.format("Fired buy for %d affordable upgrades!", bought),
        Duration = 2
    })
end)

-- =========================================================================
-- Startup Notification
-- =========================================================================
Hub.SendNotification({
    Title = "Unknown Hub",
    Content = "Untitled Upgrade Tree loaded!",
    Duration = 3
})
