-- =========================================================================
-- UNKNOWN HUB - UNTITLED UPGRADE TREE
-- Game: Untitled Upgrade Tree
-- Features: Universal Dynamic Multi-World Mathematical Auto Upgrade Engine,
--           InfMaths Exponentiation, Upgrade #4 (Buy Max) Integration,
--           Wish Safeguard & GUI Shop Blacklist, High-Speed Network-Safe
--           Auto Clicker, Smart Auto Prestige, Auto Evil & Dark Resets
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
-- Dynamic Universal Game Modules & Remotes Engine
-- =========================================================================
local InfMaths = nil
local UpgradesModule = nil
local ReadPlayerMulti = nil
local BuyUpgRemote = nil
local ClickerRemote = nil
local PrestigeRemote = nil
local EvilRemote = nil
local DarkPrestigeRemote = nil
local DarkEvilRemote = nil
local TowerPrestigeRemote = nil

local function loadGameModules()
    pcall(function()
        local modules = ReplicatedStorage:FindFirstChild("Modules")
        if modules then
            if modules:FindFirstChild("InfMaths") then
                InfMaths = require(modules.InfMaths)
            end
            if modules:FindFirstChild("Upgrades") then
                UpgradesModule = require(modules.Upgrades)
            end
            if modules:FindFirstChild("ReadPlayerMulti") then
                ReadPlayerMulti = require(modules.ReadPlayerMulti)
            end
        end
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if remotes then
            BuyUpgRemote = remotes:FindFirstChild("BuyUpg")
            ClickerRemote = remotes:FindFirstChild("Clicker")
            PrestigeRemote = remotes:FindFirstChild("Prestige")
            EvilRemote = remotes:FindFirstChild("Evil")
            DarkPrestigeRemote = remotes:FindFirstChild("DarkPrestige")
            DarkEvilRemote = remotes:FindFirstChild("DarkEvil")
            TowerPrestigeRemote = remotes:FindFirstChild("TowerPrestige")
        end
    end)
end

loadGameModules()

local function resolveVal(v)
    if type(v) == "function" then
        local success, res = pcall(v, LocalPlayer)
        if success and res ~= nil then return res end
        local success2, res2 = pcall(v)
        return success2 and res2 or nil
    end
    return v
end

-- Universal Dynamic Balance Resolver across all game folders & statistics
local function getPlayerBalance(currName)
    if not currName or currName == "" then return nil end
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
    local dataFolder = LocalPlayer:FindFirstChild("Data")
    if dataFolder then
        local valObj = dataFolder:FindFirstChild(currName)
        if valObj then
            return valObj.Value
        end
    end
    return nil
end

-- Universal Unlock Verification Engine
local function isUpgradeUnlocked(data, playerData, playerUpgrades)
    local rawUnlock = resolveVal(data.Unlock)
    local rawHasUnlock = resolveVal(data.HasUnlock)

    -- Dynamic Currency & World Unlock Flags Check
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

    -- Stat-based unlock requirement (e.g. Loop, Stage, or custom player stats)
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

    -- Parent Upgrade Requirement 1
    if unlockNum and unlockNum > 0 and playerUpgrades then
        local pObj = playerUpgrades:FindFirstChild(tostring(unlockNum))
        local pLvl = pObj and tonumber(pObj.Value) or 0
        if pLvl < 1 then
            return false
        end
    end

    -- Parent Upgrade Requirement 2
    if hasUnlockNum and hasUnlockNum > 0 and hasUnlockNum ~= unlockNum and playerUpgrades then
        if unlockNum and unlockNum > 0 then
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

-- =========================================================================
-- State Management
-- =========================================================================
local State = {
    AutoUpgrade = false,
    UpgradeInterval = 0.2,
    IncludeWishUpgrades = false,
    AutoClick = false,
    AutoPrestige = false,
    AutoEvil = false,
    AutoDarkPrestige = false,
    AutoDarkEvil = false
}

-- Currency & ID Blacklist for GUI Menus / Wishes (Preserves player wishes & daily points)
local GUI_BLACKLIST_CURRENCIES = {
    ["WishToken"] = true,
    ["Wish"] = true,
    ["Wishes"] = true,
    ["DailyPoints"] = true
}

local GUI_BLACKLIST_IDS = {
    [58] = true, [59] = true, [60] = true, [61] = true,
    [290] = true, [291] = true, [292] = true, [293] = true, [303] = true, [304] = true
}

-- Universal Real-Time Upgrade Execution Engine with Wish Safeguard
local function buyAffordableUpgrades()
    if not BuyUpgRemote then
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if remotes and remotes:FindFirstChild("BuyUpg") then
            BuyUpgRemote = remotes.BuyUpg
        end
    end
    if not BuyUpgRemote then return 0 end

    if not UpgradesModule or not InfMaths or not ReadPlayerMulti then
        loadGameModules()
    end

    local playerData = LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("PlayerData")
    local playerUpgrades = LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("Upgrades")

    local boughtCount = 0
    local currencyBudgets = {}

    local function getTrackedBudget(cName)
        if currencyBudgets[cName] == nil then
            local raw = getPlayerBalance(cName)
            if raw ~= nil and InfMaths then
                currencyBudgets[cName] = InfMaths.new(tostring(raw))
            else
                currencyBudgets[cName] = false
            end
        end
        return currencyBudgets[cName]
    end

    local hasBuyMax = false
    if playerUpgrades then
        local u4 = playerUpgrades:FindFirstChild("4")
        if u4 and tonumber(u4.Value) and tonumber(u4.Value) >= 1 then
            hasBuyMax = true
        end
    end

    -- 1. Primary: Dynamic Multi-World Mathematical Affordability Engine
    if UpgradesModule and InfMaths and playerUpgrades then
        for id, data in pairs(UpgradesModule) do
            local numId = tonumber(id)
            if numId and type(data) == "table" then
                local currName = tostring(resolveVal(data.CurrencyCost) or "Points")

                -- Check GUI / Wish Blacklist unless user explicitly enables them
                local isGuiOrWish = GUI_BLACKLIST_CURRENCIES[currName] or GUI_BLACKLIST_IDS[numId]
                if not (isGuiOrWish and not State.IncludeWishUpgrades) then
                    local upgValObj = playerUpgrades:FindFirstChild(tostring(numId))
                    local curLevel = upgValObj and tonumber(upgValObj.Value) or 0

                    local rawMax = resolveVal(data.Max)
                    local maxLevel = rawMax and tonumber(rawMax) or nil

                    if not maxLevel or curLevel < maxLevel then
                        if isUpgradeUnlocked(data, playerData, playerUpgrades) then
                            local basePrice = resolveVal(data.Price)
                            if basePrice ~= nil then
                                local isFree = (basePrice == 0 or basePrice == "0" or tostring(basePrice) == "0")

                                if isFree then
                                    pcall(function()
                                        BuyUpgRemote:FireServer(numId)
                                    end)
                                    boughtCount = boughtCount + 1
                                else
                                    local budget = getTrackedBudget(currName)

                                    if budget and budget ~= false then
                                        local priceInc = tonumber(resolveVal(data.PriceInc)) or 1
                                        local infBase = InfMaths.new(tostring(basePrice))
                                        local infInc = InfMaths.new(tostring(priceInc))

                                        -- Calculate starting price using InfMaths power to prevent IEEE-754 overflow
                                        local price = infBase
                                        if curLevel > 0 and priceInc > 1 then
                                            price = infBase * (infInc ^ curLevel)
                                        end

                                        if hasBuyMax then
                                            -- Upgrade #4 (Buy Max) owned: 1 remote call buys max affordable tiers on server!
                                            if budget >= price then
                                                pcall(function()
                                                    BuyUpgRemote:FireServer(numId)
                                                end)
                                                boughtCount = boughtCount + 1
                                                if budget > price then
                                                    budget = budget - price
                                                    currencyBudgets[currName] = budget
                                                else
                                                    currencyBudgets[currName] = InfMaths.new(0)
                                                end
                                            end
                                        else
                                            -- Standard burst loop when Buy Max is not yet unlocked
                                            local tempLevel = curLevel
                                            local burstLimit = 25

                                            while (not maxLevel or tempLevel < maxLevel) and budget >= price and burstLimit > 0 do
                                                pcall(function()
                                                    BuyUpgRemote:FireServer(numId)
                                                end)
                                                boughtCount = boughtCount + 1
                                                budget = budget - price
                                                currencyBudgets[currName] = budget
                                                burstLimit = burstLimit - 1
                                                tempLevel = tempLevel + 1

                                                if priceInc > 1 then
                                                    price = price * infInc
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

    -- 2. Secondary Fallback: Workspace Physical Buttons Scanner
    local wsUpgrades = Workspace:FindFirstChild("Upgrades")
    if wsUpgrades then
        for _, upg in ipairs(wsUpgrades:GetChildren()) do
            local upgId = tonumber(upg.Name)
            if upgId and (not UpgradesModule or not UpgradesModule[upgId]) then
                if not GUI_BLACKLIST_IDS[upgId] then
                    pcall(function()
                        BuyUpgRemote:FireServer(upgId)
                    end)
                    boughtCount = boughtCount + 1
                end
            end
        end
    end

    return boughtCount
end

-- =========================================================================
-- Initialize Unknown Hub Instance
-- =========================================================================
local Hub = factory({
    name = LIBRARY_NAME,
    title = "UNTITLED UPGRADE TREE",
    subTitle = "Auto Farm & Upgrade",
    theme = Color3.fromRGB(0, 215, 255),
    secondaryTheme = Color3.fromRGB(165, 95, 255),
    onClose = function()
        _G.UUT_SESSION = nil
        State.AutoUpgrade = false
        State.AutoClick = false
        State.AutoPrestige = false
        State.AutoEvil = false
        State.AutoDarkPrestige = false
        State.AutoDarkEvil = false
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

-- Safeguard Toggle: Include Wishes & GUI Shop Upgrades
Hub.CreateToggle(mainTab, "Include Wishes & GUI Menus", false, function(enabled)
    State.IncludeWishUpgrades = enabled
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

Hub.CreateSection(mainTab, "CLICKER & RESET AUTOMATION")

-- Auto Click Toggle (High-Speed Network-Safe Click Engine)
Hub.CreateToggle(mainTab, "Auto Click (Instant)", false, function(enabled)
    State.AutoClick = enabled
    if enabled then
        task.spawn(function()
            while State.AutoClick and _G.UUT_SESSION == currentSession do
                if not ClickerRemote then
                    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                    if remotes then ClickerRemote = remotes:FindFirstChild("Clicker") end
                end
                if ClickerRemote then
                    for _ = 1, 3 do
                        pcall(function()
                            ClickerRemote:FireServer()
                        end)
                    end
                end
                task.wait(0.06)
            end
        end)
    end
end)

-- Smart Auto Prestige Toggle
Hub.CreateToggle(mainTab, "Auto Prestige", false, function(enabled)
    State.AutoPrestige = enabled
    if enabled then
        task.spawn(function()
            while State.AutoPrestige and _G.UUT_SESSION == currentSession do
                if not PrestigeRemote then
                    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                    if remotes then PrestigeRemote = remotes:FindFirstChild("Prestige") end
                end
                local playerData = LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("PlayerData")
                local isUnlocked = (not playerData or not playerData:FindFirstChild("UnlockedPrestiges")) or (playerData.UnlockedPrestiges.Value == true)
                
                if PrestigeRemote and isUnlocked then
                    local shouldPrestige = true
                    if ReadPlayerMulti and InfMaths then
                        pcall(function()
                            local gain = ReadPlayerMulti.PlayerPrestigeCount(LocalPlayer)
                            if gain and InfMaths.new(gain) <= InfMaths.new(0) then
                                shouldPrestige = false
                            end
                        end)
                    end
                    if shouldPrestige then
                        pcall(function()
                            PrestigeRemote:FireServer()
                        end)
                    end
                end
                task.wait(0.25)
            end
        end)
    end
end)

-- Smart Auto Evil Reset Toggle
Hub.CreateToggle(mainTab, "Auto Evil Reset", false, function(enabled)
    State.AutoEvil = enabled
    if enabled then
        task.spawn(function()
            while State.AutoEvil and _G.UUT_SESSION == currentSession do
                if not EvilRemote then
                    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                    if remotes then EvilRemote = remotes:FindFirstChild("Evil") end
                end
                local playerData = LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("PlayerData")
                local isUnlocked = (playerData and playerData:FindFirstChild("UnlockedEvil") and playerData.UnlockedEvil.Value == true)
                
                if EvilRemote and isUnlocked then
                    local shouldEvil = true
                    if ReadPlayerMulti and InfMaths then
                        pcall(function()
                            local gain = ReadPlayerMulti.PlayerEvilCount(LocalPlayer)
                            if gain and InfMaths.new(gain) <= InfMaths.new(0) then
                                shouldEvil = false
                            end
                        end)
                    end
                    if shouldEvil then
                        pcall(function()
                            EvilRemote:FireServer()
                        end)
                    end
                end
                task.wait(0.3)
            end
        end)
    end
end)

-- Smart Auto Dark Prestige Toggle
Hub.CreateToggle(mainTab, "Auto Dark Prestige", false, function(enabled)
    State.AutoDarkPrestige = enabled
    if enabled then
        task.spawn(function()
            while State.AutoDarkPrestige and _G.UUT_SESSION == currentSession do
                if not DarkPrestigeRemote then
                    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                    if remotes then DarkPrestigeRemote = remotes:FindFirstChild("DarkPrestige") end
                end
                local playerData = LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("PlayerData")
                local isUnlocked = (playerData and playerData:FindFirstChild("UnlockedDarkPrestiges") and playerData.UnlockedDarkPrestiges.Value == true)
                
                if DarkPrestigeRemote and isUnlocked then
                    local shouldDarkPrestige = true
                    if ReadPlayerMulti and InfMaths then
                        pcall(function()
                            local gain = ReadPlayerMulti.PlayerDarkPrestigeEnergieCount(LocalPlayer)
                            if gain and InfMaths.new(gain) <= InfMaths.new(0) then
                                shouldDarkPrestige = false
                            end
                        end)
                    end
                    if shouldDarkPrestige then
                        pcall(function()
                            DarkPrestigeRemote:FireServer()
                        end)
                    end
                end
                task.wait(0.3)
            end
        end)
    end
end)

-- Smart Auto Dark Evil Toggle
Hub.CreateToggle(mainTab, "Auto Dark Evil", false, function(enabled)
    State.AutoDarkEvil = enabled
    if enabled then
        task.spawn(function()
            while State.AutoDarkEvil and _G.UUT_SESSION == currentSession do
                if not DarkEvilRemote then
                    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                    if remotes then DarkEvilRemote = remotes:FindFirstChild("DarkEvil") end
                end
                local playerData = LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("PlayerData")
                local isUnlocked = (playerData and playerData:FindFirstChild("UnlockedDarkEvil") and playerData.UnlockedDarkEvil.Value == true)
                
                if DarkEvilRemote and isUnlocked then
                    local shouldDarkEvil = true
                    if ReadPlayerMulti and InfMaths then
                        pcall(function()
                            local gain = ReadPlayerMulti.PlayerDarkEvilEnergieCount(LocalPlayer)
                            if gain and InfMaths.new(gain) <= InfMaths.new(0) then
                                shouldDarkEvil = false
                            end
                        end)
                    end
                    if shouldDarkEvil then
                        pcall(function()
                            DarkEvilRemote:FireServer()
                        end)
                    end
                end
                task.wait(0.3)
            end
        end)
    end
end)

-- =========================================================================
-- Startup Notification
-- =========================================================================
Hub.SendNotification({
    Title = "Unknown Hub",
    Content = "Untitled Upgrade Tree loaded!",
    Duration = 3
})
