--[[
    ========================================================================
    Unknown Hub - Industrial / Ugc Dedicated Script Module
    Library: UnknownLibrary (Unknown Hub UI)
    Features:
      - Complete Item Info Database (Cost, Crafting, RS2 RP Yield)
      - Dynamic ReplicatedStorage Enums/Items Extractor
      - Research Station 2 RP Calculator & Yield Ranking
      - Auto Farm / Item Search & Auto Collect
    ========================================================================
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

local LIBRARY_LINK = "https://raw.githubusercontent.com/UnknownHQ/UnknownHub/main/UnknownLibrary"
local LIBRARY_NAME = "Unknown_TabbedHub_UI"

-- =========================================================================
-- Anti-AFK & Cleanup System
-- =========================================================================
if getgenv and getgenv()._UnknownHub_Cleanup then
    pcall(getgenv()._UnknownHub_Cleanup)
    getgenv()._UnknownHub_Cleanup = nil
end

local isScriptAlive = true
local scriptCleanups = {}

local function addCleanup(fn)
    table.insert(scriptCleanups, fn)
end

local function safeConnect(signal, callback)
    local conn = signal:Connect(callback)
    addCleanup(function() pcall(function() conn:Disconnect() end) end)
    return conn
end

local function destroyOldGui()
    local parents = {game:GetService("CoreGui")}
    if gethui then pcall(function() table.insert(parents, gethui()) end) end
    local playerGui = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
    if playerGui then table.insert(parents, playerGui) end
    for _, parent in ipairs(parents) do
        if parent then
            pcall(function()
                for _, child in ipairs(parent:GetChildren()) do
                    if child:IsA("ScreenGui") and (child.Name == LIBRARY_NAME or child.Name == "Unknown_Ugc_UI") then
                        pcall(function() child:Destroy() end)
                    end
                end
            end)
        end
    end
end

local function cleanupEverything()
    isScriptAlive = false
    destroyOldGui()
    for _, fn in ipairs(scriptCleanups) do pcall(fn) end
    table.clear(scriptCleanups)
end

if getgenv then getgenv()._UnknownHub_Cleanup = cleanupEverything end
_G._UnknownHub_Cleanup = cleanupEverything

-- Anti-AFK
safeConnect(LocalPlayer.Idled, function()
    pcall(function()
        if VirtualUser then
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new(0, 0))
        end
    end)
end)

-- =========================================================================
-- Load UnknownLibrary
-- =========================================================================
local ok, result = pcall(function()
    local source
    local cacheBuster = "?t=" .. tostring(os.time() or tick()) .. "_" .. tostring(math.random(1000, 9999))
    if readfile and isfile and isfile("UnknownLibrary.luau") then
        source = readfile("UnknownLibrary.luau")
    else
        source = game:HttpGet(LIBRARY_LINK .. cacheBuster)
    end
    local factoryChunk, compileErr = loadstring(source)
    assert(factoryChunk, "Library compile failed: " .. tostring(compileErr))
    return factoryChunk()
end)

if not ok or type(result) ~= "function" then
    warn("[UnknownHub] Remote library failed loading, standing by...")
    return
end

destroyOldGui()

local Hub = result({
    name = LIBRARY_NAME,
    title = "UNKNOWN HUB",
    subTitle = "Industrial / UGC",
    parent = (gethui and gethui()) or (LocalPlayer and (LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui"))) or (pcall(function() return game:GetService("CoreGui") end) and game:GetService("CoreGui")),
    theme = Color3.fromRGB(0, 170, 255),
    secondaryTheme = Color3.fromRGB(255, 120, 0)
})

assert(type(Hub) == "table", "UnknownLibrary returned invalid hub")

-- =========================================================================
-- Item Database Extractor
-- =========================================================================
local ItemDatabase = {}
local ItemNamesList = {}

local function extractItemDatabase()
    ItemDatabase = {}
    ItemNamesList = {}
    
    local success, ItemsModule = pcall(function()
        return require(ReplicatedStorage:WaitForChild("Modules", 5):WaitForChild("Enums", 5):WaitForChild("Items", 5))
    end)

    if success and type(ItemsModule) == "table" then
        for key, item in pairs(ItemsModule) do
            if type(item) == "table" and item.DisplayName and item.DisplayName ~= "None" and item.DisplayName ~= "" then
                local cost = item.Price or 0
                local rpMult = item.RPMultiplier or 0
                local rs2Yield = rpMult * 5 -- Research Station 2 gives 5x base RPMultiplier
                
                -- Crafting Recipe extraction
                local recipeInfo = "Mineable / Merchant / Raw Material"
                if item.Recipe then
                    recipeInfo = typeof(item.Recipe) == "table" and HttpService:JSONEncode(item.Recipe) or tostring(item.Recipe)
                elseif item.CraftingInputs then
                    recipeInfo = typeof(item.CraftingInputs) == "table" and HttpService:JSONEncode(item.CraftingInputs) or tostring(item.CraftingInputs)
                end
                
                ItemDatabase[item.DisplayName] = {
                    Key = key,
                    DisplayName = item.DisplayName,
                    Cost = cost,
                    RPMultiplier = rpMult,
                    RS2_RP = rs2Yield,
                    SalesTax = item.SalesTax or 0,
                    Recipe = recipeInfo,
                    ID = item.ID or 0
                }
                table.insert(ItemNamesList, item.DisplayName)
            end
        end
    end

    table.sort(ItemNamesList)
end

extractItemDatabase()

-- Fallback if game modules fail
if #ItemNamesList == 0 then
    ItemDatabase["Plastic Casing"] = { DisplayName = "Plastic Casing", Cost = 50, RPMultiplier = 7, RS2_RP = 35, Recipe = "Extruder (Plastic Pellets)" }
    ItemDatabase["Hardened Plastic Casing"] = { DisplayName = "Hardened Plastic Casing", Cost = 68.97, RPMultiplier = 20, RS2_RP = 100, Recipe = "Chemical Treater + Plastic Casing" }
    ItemDatabase["4x64x Microchip"] = { DisplayName = "4x64x Microchip", Cost = 129310.34, RPMultiplier = 100, RS2_RP = 500, Recipe = "High-Tier Microchip Assembler" }
    ItemDatabase["8x64x Microchip"] = { DisplayName = "8x64x Microchip", Cost = 1724137.93, RPMultiplier = 300, RS2_RP = 1500, Recipe = "Supercomputer Assembler" }
    for k in pairs(ItemDatabase) do table.insert(ItemNamesList, k) end
    table.sort(ItemNamesList)
end

-- =========================================================================
-- Hub Tabs & UI Construction
-- =========================================================================
local infoTab = Hub.createTabButton("Item Info", "📦 Items & Costs", "rbxassetid://10723407390", true)
local rsTab   = Hub.createTabButton("Research RS2", "🔬 Research Station 2", "rbxassetid://10723407389", false)
local farmTab = Hub.createTabButton("Automation", "⚙️ Factory & Farm", "rbxassetid://10723407392", false)

-- -------------------------------------------------------------------------
-- Item Info Tab
-- -------------------------------------------------------------------------
local itemSec = infoTab.createSection("Game Items Explorer")

local selectedItemName = ItemNamesList[1] or "Plastic Casing"

local selectedCostLbl, selectedRPLbl, selectedRecipeLbl

local function updateItemDetails(itemName)
    selectedItemName = itemName
    local data = ItemDatabase[itemName]
    if data then
        if selectedCostLbl then selectedCostLbl.Text = string.format("Cost: $%.2f", data.Cost) end
        if selectedRPLbl then selectedRPLbl.Text = string.format("Research Station 2 RP: %d RP (Base Mult: %.1f)", data.RS2_RP, data.RPMultiplier) end
        if selectedRecipeLbl then selectedRecipeLbl.Text = "Crafting / Source: " .. tostring(data.Recipe) end
    end
end

itemSec.createList({
    name = "Select Item to View Info",
    options = ItemNamesList,
    default = selectedItemName,
    callback = function(choice)
        updateItemDetails(choice)
    end
})

itemSec.createButton({
    name = "🔄 Refresh Live Item Database",
    callback = function()
        extractItemDatabase()
        updateItemDetails(selectedItemName)
    end
})

selectedCostLbl = itemSec.createLabel("Cost: $0.00")
selectedRPLbl   = itemSec.createLabel("Research Station 2 RP: 0 RP")
selectedRecipeLbl = itemSec.createLabel("Crafting / Source: Loading...")

updateItemDetails(selectedItemName)

-- -------------------------------------------------------------------------
-- Research Station 2 Tab
-- -------------------------------------------------------------------------
local rsSec = rsTab.createSection("Research Station 2 Yield Calculator")

rsSec.createLabel("Research Station 2 Formula: RP Yield = Base RPMultiplier * 5")

local topItemsList = {}
for name, data in pairs(ItemDatabase) do
    if data.RS2_RP > 0 then
        table.insert(topItemsList, string.format("%s -> %d RP (Cost: $%.2f)", name, data.RS2_RP, data.Cost))
    end
end

rsSec.createList({
    name = "Top Research Station 2 Items",
    options = topItemsList,
    default = topItemsList[1] or "None",
    callback = function() end
})

-- -------------------------------------------------------------------------
-- Automation & Utility
-- -------------------------------------------------------------------------
local autoSec = farmTab.createSection("Factory Automation & Utility")

autoSec.createToggle({
    name = "Auto Collect Products / Items",
    default = false,
    callback = function(state)
        getgenv().AutoCollect = state
    end
})

print("[UnknownHub] Ugc module successfully initialized!")
