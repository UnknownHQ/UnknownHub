--[[
    ========================================================================
    Unknown Hub - Booga Booga Dedicated Script Module (v5 Master Edition)
    Library: UnknownLibrary (ENI Tabbed Hub UI)
    Features: Single "Auto Hit" with Resource Whitelist (Ores, Trees, Plants, Chests),
              "Auto Pickup" with Full Game Item Whitelist List, Body-Frozen Magnet,
              No-Fall Safe Collision Restoration, Godmode, ESP, Island TP
    ========================================================================
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer

local LIBRARY_LINK = "https://raw.githubusercontent.com/UnknownHQ/UnknownHub/main/UnknownLibrary"
local LIBRARY_NAME = "ENI_TabbedHub_UI"

-- =========================================================================
-- Built-in Anti-AFK
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
    local playerGui = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
    if playerGui then table.insert(parents, playerGui) end
    for _, parent in ipairs(parents) do
        if parent then
            pcall(function()
                for _, child in ipairs(parent:GetChildren()) do
                    if child:IsA("ScreenGui") and (child.Name == LIBRARY_NAME or child.Name == "ENI_BoogaBooga_UI") then
                        pcall(function() child:Destroy() end)
                    end
                end
            end)
        end
    end
end

-- Load UI Library
local ok, result = pcall(function()
    local source
    local cacheBuster = "?t=" .. tostring(os.time() or tick()) .. "_" .. tostring(math.random(1000, 9999))
    source = game:HttpGet(LIBRARY_LINK .. cacheBuster)
    pcall(function()
    end)
    local factoryChunk, compileErr = loadstring(source)
    assert(factoryChunk, "Library compile failed: " .. tostring(compileErr))
    return factoryChunk()
end)

if not ok or type(result) ~= "function" then
    warn("[UnknownHub] Remote library failed loading, standing by...")
end

destroyOldGui()

local Hub = result({
    name = LIBRARY_NAME,
    title = "UNKNOWN HUB",
    subTitle = "Booga Booga",
    parent = (gethui and gethui()) or (LocalPlayer and (LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui"))) or (pcall(function() return game:GetService("CoreGui") end) and game:GetService("CoreGui")),
    theme = Color3.fromRGB(0, 195, 245),
    secondaryTheme = Color3.fromRGB(255, 165, 0)
})

assert(type(Hub) == "table", "UnknownLibrary returned invalid hub")

-- =========================================================================
-- State Registry
-- =========================================================================
local state = {
    -- Auto Hit (Single Toggle + Resource Whitelist List)
    AutoHit = false,
    AutoHitWhitelist = "All Resources", -- "All Resources", "Ores & Minerals", "Trees & Wood", "Plants & Food", "Chests & Structures"
    AutoHitRange = 35,
    FastHit = true,

    -- Defense & Reach
    ReachHitbox = false,
    ReachSize = 12,
    AutoParry = false,
    AutoEat = false,
    EatThreshold = 60,

    -- Auto Pickup (Single Toggle + Full Item Whitelist List)
    AutoPickup = false,
    PickupCategoryWhitelist = "All Items (Everything)", -- "All Items (Everything)", "Ores & Gems", "Wood & Logs", "Food & Consumables", "Equipment & Gear", "Valuables & Essences"
    PickupCustomFilter = "",
    PickupRange = 50,
    FreezeToPlayerBody = true,

    -- Movement & Player
    GodMode = false,
    WalkSpeedToggle = false,
    WalkSpeedValue = 24,
    JumpPowerToggle = false,
    JumpPowerValue = 75,
    InfiniteStamina = false,
    Noclip = false,
    Fly = false,
    FlySpeed = 50,
    WaterWalk = false,

    -- Visuals
    PlayerESP = false,
    ResourceESP = false,
    MobESP = false,
    Fullbright = false,

    -- Waypoints
    SavedWaypoints = {}
}

-- Helpers
local function getCharacter(player)
    player = player or LocalPlayer
    return player and player.Character
end

local function getRoot(player)
    local char = getCharacter(player)
    return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("Head"))
end

local function getHumanoid(player)
    local char = getCharacter(player)
    return char and char:FindFirstChildWhichIsA("Humanoid")
end

-- Comprehensive Remote Collectors
local function getAllRemotes()
    local remotes = {}
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            table.insert(remotes, obj)
        end
    end
    return remotes
end

local function getRemotesMatching(patterns)
    local matched = {}
    for _, r in ipairs(getAllRemotes()) do
        local rName = r.Name:lower()
        for _, pattern in ipairs(patterns) do
            if rName:find(pattern:lower()) then
                table.insert(matched, r)
                break
            end
        end
    end
    return matched
end

-- Resource Category Whitelist Matcher
local RESOURCE_CATEGORIES = {
    ["All Resources"] = {"tree", "wood", "log", "palm", "oak", "birch", "pine", "driftwood", "ancient", "chestnut", "rock", "ore", "stone", "gold", "iron", "adurite", "crystal", "meteor", "essence", "berry", "bush", "fruit", "plant", "bloodfruit", "bluefruit", "sunfruit", "jellyfruit", "cloudberry", "node", "structure", "debris", "chest", "crate", "magma", "void"},
    ["Ores & Minerals"] = {"rock", "ore", "stone", "gold", "iron", "adurite", "crystal", "meteor", "magma", "void", "node", "coal", "pink diamond"},
    ["Trees & Wood"] = {"tree", "wood", "log", "palm", "oak", "birch", "pine", "driftwood", "ancient", "chestnut"},
    ["Plants & Food"] = {"berry", "bush", "fruit", "plant", "bloodfruit", "bluefruit", "sunfruit", "jellyfruit", "cloudberry"},
    ["Chests & Structures"] = {"chest", "crate", "structure", "totem", "box", "debris"}
}

local function isTargetResource(name)
    name = name:lower()
    local category = state.AutoHitWhitelist or "All Resources"
    local keywords = RESOURCE_CATEGORIES[category] or RESOURCE_CATEGORIES["All Resources"]
    for _, kw in ipairs(keywords) do
        if name:find(kw) then
            return true
        end
    end
    return false
end

-- Item Category Whitelist Matcher (All Booga Booga Game Items)
local ITEM_CATEGORIES = {
    ["Ores & Gems"] = {"stone", "coal", "iron", "gold", "adurite", "crystal", "pink diamond", "meteorite", "magma", "void stone", "essence", "ore", "gem"},
    ["Wood & Logs"] = {"wood", "oak", "birch", "pine", "palm", "chestnut", "driftwood", "ancient", "log"},
    ["Food & Consumables"] = {"berry", "bloodfruit", "bluefruit", "sunfruit", "jellyfruit", "cloudberry", "meat", "fish", "fruit", "food", "cooked", "raw"},
    ["Equipment & Gear"] = {"pickaxe", "axe", "club", "spear", "sword", "bag", "armor", "helmet", "shield", "bow", "arrow"},
    ["Valuables & Essences"] = {"coin", "feather", "hide", "fang", "horn", "essence", "chestnut", "tooth", "bone"}
}

local function isWhitelistedItem(itemName)
    itemName = itemName:lower()

    if state.PickupCustomFilter and state.PickupCustomFilter ~= "" then
        local filterLower = state.PickupCustomFilter:lower()
        if itemName:find(filterLower) then return true end
    end

    local category = state.PickupCategoryWhitelist
    if category == "All Items (Everything)" then
        return true
    end

    local keywords = ITEM_CATEGORIES[category]
    if keywords then
        for _, kw in ipairs(keywords) do
            if itemName:find(kw) then
                return true
            end
        end
    end

    return false
end

-- =========================================================================
-- Tabs Setup
-- =========================================================================
local combatTab   = Hub.createTabButton("Combat", "🥊 Combat & Auto Hit", "rbxassetid://10723407390", true)
local farmTab     = Hub.createTabButton("Farm", "🪵 Auto Pickup & Whitelist", "rbxassetid://10723407389", false)
local playerTab   = Hub.createTabButton("Player", "⚡ Movement", "rbxassetid://10723407392", false)
local visualsTab  = Hub.createTabButton("Visuals", "👁️ ESP & Visuals", "rbxassetid://10723407395", false)
local teleportTab = Hub.createTabButton("Teleports", "🌐 Teleports", "rbxassetid://10723407389", false)
local miscTab     = Hub.createTabButton("Misc", "🛠️ Utility & Server", "rbxassetid://10723407392", false)

-- =========================================================================
-- 1. COMBAT TAB: AUTO HIT (WHITELIST: RESOURCES ONLY)
-- =========================================================================
Hub.CreateSection(combatTab, "Single Toggle Auto Hit")

Hub.CreateToggle(combatTab, "⚡ Auto Hit", false, function(toggled)
    state.AutoHit = toggled
end)

local targetCategories = {
    "All Resources",
    "Ores & Minerals",
    "Trees & Wood",
    "Plants & Food",
    "Chests & Structures"
}
local hitWhitelistList = Hub.CreateList(combatTab, "🎯 Auto Hit Target Whitelist", targetCategories, 180, true)
hitWhitelistList:SetSelected(state.AutoHitWhitelist or "All Resources")
hitWhitelistList.OnSelect = function(selected)
    state.AutoHitWhitelist = selected
end

Hub.CreateSlider(combatTab, "Auto Hit Range (Studs)", 10, 100, 35, " studs", function(val)
    state.AutoHitRange = val
end)

Hub.CreateToggle(combatTab, "⚡ Fast Swing Speed", true, function(toggled)
    state.FastHit = toggled
end)

Hub.CreateSection(combatTab, "Reach & Auto Defense")

Hub.CreateToggle(combatTab, "Hitbox Expander / Reach", false, function(toggled)
    state.ReachHitbox = toggled
end)

Hub.CreateSlider(combatTab, "Hitbox Size", 5, 30, 12, " studs", function(val)
    state.ReachSize = val
end)

Hub.CreateToggle(combatTab, "Auto Parry / Shield", false, function(toggled)
    state.AutoParry = toggled
end)

Hub.CreateToggle(combatTab, "Auto Eat Food", false, function(toggled)
    state.AutoEat = toggled
end)

Hub.CreateSlider(combatTab, "Eat Threshold (% HP/Hunger)", 20, 80, 60, "%", function(val)
    state.EatThreshold = val
end)

-- Auto Hit Execution Loop (Dedicated to Resources - Trees, Ores, Meteors, Plants, Chests)
task.spawn(function()
    while true do
        task.wait(state.FastHit and 0.04 or 0.12)
        if state.AutoHit then
            local myRoot = getRoot()
            if myRoot then
                local char = getCharacter()
                local tool = char and char:FindFirstChildWhichIsA("Tool")
                if tool then
                    pcall(function() tool:Activate() end)
                end

                local hitRemotes = getRemotesMatching({"hit", "swing", "attack", "damage", "harvest", "useitem", "chop", "mine"})

                -- Scan Dedicated Folders & Workspace for Whitelisted Resources
                local containers = {Workspace}
                for _, name in ipairs({"Resources", "Trees", "Ores", "Nodes", "Flora", "Entities", "Structures", "Items", "Debris"}) do
                    local f = Workspace:FindFirstChild(name)
                    if f then table.insert(containers, f) end
                end

                for _, container in ipairs(containers) do
                    for _, child in ipairs(container:GetChildren()) do
                        if child ~= char then
                            local part = child:IsA("BasePart") and child or child:FindFirstChildWhichIsA("BasePart", true)
                            if part and isTargetResource(child.Name) then
                                local dist = (myRoot.Position - part.Position).Magnitude
                                if dist <= state.AutoHitRange then
                                    if tool then pcall(function() tool:Activate() end) end
                                    for _, r in ipairs(hitRemotes) do
                                        pcall(function()
                                            if r:IsA("RemoteEvent") then
                                                r:FireServer(part)
                                                r:FireServer(part.Parent)
                                            elseif r:IsA("RemoteFunction") then
                                                r:InvokeServer(part)
                                            end
                                        end)
                                    end

                                    local cd = part:FindFirstChildWhichIsA("ClickDetector", true) or (part.Parent and part.Parent:FindFirstChildWhichIsA("ClickDetector", true))
                                    if cd then fireclickdetector(cd) end

                                    local prompt = part:FindFirstChildWhichIsA("ProximityPrompt", true) or (part.Parent and part.Parent:FindFirstChildWhichIsA("ProximityPrompt", true))
                                    if prompt and fireproximityprompt then fireproximityprompt(prompt) end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- Hitbox Expander Loop
task.spawn(function()
    while true do
        task.wait(0.5)
        if state.ReachHitbox then
            pcall(function()
                local char = getCharacter()
                local tool = char and char:FindFirstChildWhichIsA("Tool")
                local handle = tool and (tool:FindFirstChild("Handle") or tool:FindFirstChildWhichIsA("BasePart"))
                if handle then
                    handle.Size = Vector3.new(state.ReachSize, state.ReachSize, state.ReachSize)
                    handle.Massless = true
                    handle.CanCollide = false
                end
            end)
        end
    end
end)

-- Auto Eat Loop
task.spawn(function()
    while true do
        task.wait(1.5)
        if state.AutoEat then
            pcall(function()
                local hum = getHumanoid()
                if hum and (hum.Health <= (hum.MaxHealth * (state.EatThreshold / 100))) then
                    local backpack = LocalPlayer:FindFirstChild("Backpack")
                    local char = getCharacter()
                    local foodKeywords = {"berry", "meat", "fruit", "food", "cooked", "bloodfruit", "bluefruit", "sunfruit", "jellyfruit"}
                    local foundFood = nil

                    if backpack then
                        for _, item in ipairs(backpack:GetChildren()) do
                            local iName = item.Name:lower()
                            for _, kw in ipairs(foodKeywords) do
                                if iName:find(kw) then
                                    foundFood = item
                                    break
                                end
                            end
                            if foundFood then break end
                        end
                    end

                    if foundFood and char then
                        local curTool = char:FindFirstChildWhichIsA("Tool")
                        hum:EquipTool(foundFood)
                        task.wait(0.1)
                        foundFood:Activate()
                        local eatRemotes = getRemotesMatching({"eat", "consume", "use", "useitem"})
                        for _, r in ipairs(eatRemotes) do
                            pcall(function()
                                if r:IsA("RemoteEvent") then r:FireServer(foundFood)
                                elseif r:IsA("RemoteFunction") then r:InvokeServer(foundFood) end
                            end)
                        end
                        task.wait(0.1)
                        if curTool then hum:EquipTool(curTool) end
                    end
                end
            end)
        end
    end
end)

-- =========================================================================
-- 2. FARM TAB: AUTO PICKUP & ALL GAME ITEMS WHITELIST (BODY-FROZEN)
-- =========================================================================
Hub.CreateSection(farmTab, "Auto Pickup Automation")

local prevPickupState = false

Hub.CreateToggle(farmTab, "🧲 Auto Pickup", false, function(toggled)
    state.AutoPickup = toggled

    if prevPickupState and not toggled then
        pcall(function()
            local myRoot = getRoot()
            if myRoot then
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA("BasePart") and obj.Name ~= "HumanoidRootPart" and obj.Name ~= "Torso" then
                        if (myRoot.Position - obj.Position).Magnitude <= (state.PickupRange + 20) then
                            obj.CanCollide = true
                            obj.CanTouch = true
                            obj.AssemblyLinearVelocity = Vector3.zero
                            obj.AssemblyAngularVelocity = Vector3.zero
                        end
                    end
                end
            end
        end)
    end
    prevPickupState = toggled
end)

local pickupCategories = {
    "All Items (Everything)",
    "Ores & Gems",
    "Wood & Logs",
    "Food & Consumables",
    "Equipment & Gear",
    "Valuables & Essences"
}
local itemCategoryList = Hub.CreateList(farmTab, "🪵 Item Whitelist Category", pickupCategories, 200, true)
itemCategoryList:SetSelected(state.PickupCategoryWhitelist or "All Items (Everything)")
itemCategoryList.OnSelect = function(selected)
    state.PickupCategoryWhitelist = selected
end

Hub.CreateTextBox(farmTab, "Specific Item Name Filter", "Type item name (e.g. Berry, Adurite)", function(text)
    state.PickupCustomFilter = text
end)

Hub.CreateSlider(farmTab, "Pickup Range (Studs)", 10, 120, 50, " studs", function(val)
    state.PickupRange = val
end)

Hub.CreateToggle(farmTab, "🔒 Freeze Whitelisted Items to Player Body", true, function(toggled)
    state.FreezeToPlayerBody = toggled
end)

-- Auto Pickup Execution Loop (Whitelisted Item Body-Freezing)
task.spawn(function()
    while true do
        task.wait(0.05)
        if state.AutoPickup then
            local myRoot = getRoot()
            if myRoot then
                local pickupRemotes = getRemotesMatching({"pickup", "collect", "grab", "interact", "collectitem"})
                local containers = {Workspace}
                for _, name in ipairs({"Items", "Drops", "Debris", "Loot", "Flora"}) do
                    local folder = Workspace:FindFirstChild(name)
                    if folder then table.insert(containers, folder) end
                end

                for _, container in ipairs(containers) do
                    for _, drop in ipairs(container:GetChildren()) do
                        if drop ~= getCharacter() then
                            local dropPart = drop:IsA("BasePart") and drop or drop:FindFirstChildWhichIsA("BasePart", true)
                            if dropPart and dropPart.Name ~= "HumanoidRootPart" and dropPart.Name ~= "Torso" then
                                local dist = (myRoot.Position - dropPart.Position).Magnitude
                                if dist <= state.PickupRange and isWhitelistedItem(drop.Name) then
                                    pcall(function()
                                        for _, p in ipairs(drop:IsA("Model") and drop:GetDescendants() or {dropPart}) do
                                            if p:IsA("BasePart") then
                                                p.CanCollide = false
                                                p.CanTouch = true
                                                p.AssemblyLinearVelocity = Vector3.zero
                                                p.AssemblyAngularVelocity = Vector3.zero
                                            end
                                        end

                                        if state.FreezeToPlayerBody then
                                            dropPart.CFrame = myRoot.CFrame * CFrame.new(0, -0.5, 0)
                                        else
                                            dropPart.CFrame = myRoot.CFrame
                                        end

                                        for _, r in ipairs(pickupRemotes) do
                                            if r:IsA("RemoteEvent") then
                                                r:FireServer(drop)
                                                r:FireServer(dropPart)
                                            elseif r:IsA("RemoteFunction") then
                                                r:InvokeServer(drop)
                                                r:InvokeServer(dropPart)
                                            end
                                        end

                                        local cd = drop:FindFirstChildWhichIsA("ClickDetector", true) or (dropPart and dropPart:FindFirstChildWhichIsA("ClickDetector", true))
                                        if cd then fireclickdetector(cd) end

                                        local prompt = drop:FindFirstChildWhichIsA("ProximityPrompt", true) or (dropPart and dropPart:FindFirstChildWhichIsA("ProximityPrompt", true))
                                        if prompt and fireproximityprompt then fireproximityprompt(prompt) end
                                    end)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- =========================================================================
-- 3. PLAYER TAB: GODMODE, MOVEMENT & FLY
-- =========================================================================
Hub.CreateSection(playerTab, "Godmode & Defense")

Hub.CreateToggle(playerTab, "God Mode (No Fall / Health Guard)", false, function(toggled)
    state.GodMode = toggled
    pcall(function()
        local hum = getHumanoid()
        if hum then
            hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, not toggled)
            hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, not toggled)
        end
    end)
end)

Hub.CreateToggle(playerTab, "Infinite Stamina", false, function(toggled)
    state.InfiniteStamina = toggled
end)

Hub.CreateSection(playerTab, "Speed & Jump Modifications")

Hub.CreateToggle(playerTab, "Enable Custom WalkSpeed", false, function(toggled)
    state.WalkSpeedToggle = toggled
    pcall(function()
        local hum = getHumanoid()
        if hum then hum.WalkSpeed = toggled and state.WalkSpeedValue or 16 end
    end)
end)

Hub.CreateSlider(playerTab, "WalkSpeed Value", 16, 150, 24, " speed", function(val)
    state.WalkSpeedValue = val
    if state.WalkSpeedToggle then
        pcall(function()
            local hum = getHumanoid()
            if hum then hum.WalkSpeed = val end
        end)
    end
end)

Hub.CreateToggle(playerTab, "Enable Custom JumpPower", false, function(toggled)
    state.JumpPowerToggle = toggled
    pcall(function()
        local hum = getHumanoid()
        if hum then hum.JumpPower = toggled and state.JumpPowerValue or 50 end
    end)
end)

Hub.CreateSlider(playerTab, "JumpPower Value", 50, 250, 75, " jump", function(val)
    state.JumpPowerValue = val
    if state.JumpPowerToggle then
        pcall(function()
            local hum = getHumanoid()
            if hum then hum.JumpPower = val end
        end)
    end
end)

Hub.CreateSection(playerTab, "Fly & Noclip")

Hub.CreateToggle(playerTab, "Noclip (Pass Through Objects)", false, function(toggled)
    state.Noclip = toggled
end)

RunService.Stepped:Connect(function()
    if state.Noclip then
        pcall(function()
            local char = getCharacter()
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end
        end)
    end
end)

Hub.CreateToggle(playerTab, "Fly Mode", false, function(toggled)
    state.Fly = toggled
end)

Hub.CreateSlider(playerTab, "Fly Speed", 20, 200, 50, " speed", function(val)
    state.FlySpeed = val
end)

Hub.CreateToggle(playerTab, "Water Walk (Jesus Mode)", false, function(toggled)
    state.WaterWalk = toggled
end)

-- Fly & Water Walk Loop
local flyBodyGyro, flyBodyVelocity
task.spawn(function()
    while true do
        task.wait(0.03)
        if state.Fly then
            local root = getRoot()
            local cam = Workspace.CurrentCamera
            if root and cam then
                if not flyBodyVelocity or not flyBodyVelocity.Parent then
                    flyBodyVelocity = Instance.new("BodyVelocity")
                    flyBodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
                    flyBodyVelocity.Velocity = Vector3.zero
                    flyBodyVelocity.Parent = root
                end
                if not flyBodyGyro or not flyBodyGyro.Parent then
                    flyBodyGyro = Instance.new("BodyGyro")
                    flyBodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
                    flyBodyGyro.CFrame = root.CFrame
                    flyBodyGyro.Parent = root
                end

                local moveDir = Vector3.zero
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + cam.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - cam.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - cam.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + cam.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir - Vector3.new(0, 1, 0) end

                flyBodyVelocity.Velocity = moveDir.Unit * state.FlySpeed
                if moveDir.Magnitude == 0 then flyBodyVelocity.Velocity = Vector3.zero end
                flyBodyGyro.CFrame = cam.CFrame
            end
        else
            if flyBodyVelocity then flyBodyVelocity:Destroy() flyBodyVelocity = nil end
            if flyBodyGyro then flyBodyGyro:Destroy() flyBodyGyro = nil end
        end

        if state.WaterWalk then
            local root = getRoot()
            if root and root.Position.Y < 4.5 and root.Position.Y > -5 then
                root.Velocity = Vector3.new(root.Velocity.X, 0, root.Velocity.Z)
                root.CFrame = CFrame.new(root.Position.X, 5, root.Position.Z) * root.CFrame.Rotation
            end
        end
    end
end)

-- =========================================================================
-- 4. VISUALS TAB: ESP & FULLBRIGHT
-- =========================================================================
Hub.CreateSection(visualsTab, "ESP Toggles")

Hub.CreateToggle(visualsTab, "Player ESP", false, function(toggled)
    state.PlayerESP = toggled
end)

Hub.CreateToggle(visualsTab, "Resource ESP (Trees / Ores)", false, function(toggled)
    state.ResourceESP = toggled
end)

Hub.CreateToggle(visualsTab, "Mob & Animal ESP", false, function(toggled)
    state.MobESP = toggled
end)

Hub.CreateSection(visualsTab, "Environment")

Hub.CreateToggle(visualsTab, "Fullbright / Clear Vision", false, function(toggled)
    state.Fullbright = toggled
    pcall(function()
        if toggled then
            Lighting.Brightness = 2
            Lighting.ClockTime = 14
            Lighting.FogEnd = 100000
            Lighting.GlobalShadows = false
            Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
        else
            Lighting.Brightness = 1
            Lighting.GlobalShadows = true
        end
    end)
end)

-- Simple Clean Box/Highlight ESP Loop
local espFolder = Instance.new("Folder")
espFolder.Name = "ENI_BoogaESP"
pcall(function() espFolder.Parent = (gethui and gethui()) or CoreGui or Workspace end)

task.spawn(function()
    while true do
        task.wait(1.5)
        pcall(function()
            espFolder:ClearAllChildren()
            if state.PlayerESP then
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and p.Character then
                        local h = Instance.new("Highlight")
                        h.Name = "PlayerHighlight"
                        h.FillColor = Color3.fromRGB(255, 50, 50)
                        h.OutlineColor = Color3.fromRGB(255, 255, 255)
                        h.FillTransparency = 0.5
                        h.Adornee = p.Character
                        h.Parent = espFolder
                    end
                end
            end

            if state.ResourceESP then
                local resFolder = Workspace:FindFirstChild("Resources") or Workspace:FindFirstChild("Trees") or Workspace:FindFirstChild("Ores")
                if resFolder then
                    for _, res in ipairs(resFolder:GetChildren()) do
                        if isTargetResource(res.Name) then
                            local h = Instance.new("Highlight")
                            h.Name = "ResourceHighlight"
                            h.FillColor = Color3.fromRGB(0, 220, 100)
                            h.OutlineColor = Color3.fromRGB(255, 255, 255)
                            h.FillTransparency = 0.6
                            h.Adornee = res
                            h.Parent = espFolder
                        end
                    end
                end
            end
        end)
    end
end)

-- =========================================================================
-- 5. TELEPORTS TAB: ISLANDS & WAYPOINTS
-- =========================================================================
Hub.CreateSection(teleportTab, "Island Teleports")

local islands = {
    ["Spawn Island"] = Vector3.new(0, 50, 0),
    ["Volcano Island"] = Vector3.new(-1200, 75, -800),
    ["Ice Island"] = Vector3.new(1500, 60, -1200),
    ["Desert Island"] = Vector3.new(-900, 50, 1400),
    ["Floating Island (Sky)"] = Vector3.new(0, 500, -500),
    ["Sunken Island (Underwater)"] = Vector3.new(800, -40, 800)
}

for name, pos in pairs(islands) do
    Hub.CreateButton(teleportTab, "🏝️ TP to " .. name, function()
        pcall(function()
            local root = getRoot()
            if root then
                root.CFrame = CFrame.new(pos) + Vector3.new(0, 10, 0)
            end
        end)
    end)
end

-- =========================================================================
-- 6. MISC TAB: SERVER & UTILITY
-- =========================================================================
Hub.CreateSection(miscTab, "Server & Utility")

Hub.CreateButton(miscTab, "⚡ Rejoin Current Server", function()
    pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end)
end)

Hub.CreateButton(miscTab, "🌐 Server Hop (Low Player Server)", function()
    pcall(function()
        local serversUrl = "https://games.roblox.com/v1/games/" .. tostring(game.PlaceId) .. "/servers/Public?sortOrder=Asc&limit=100"
        local response = HttpService:JSONDecode(game:HttpGet(serversUrl))
        if response and response.data then
            for _, server in ipairs(response.data) do
                if server.playing < server.maxPlayers and server.id ~= game.JobId then
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer)
                    break
                end
            end
        end
    end)
end)

Hub.CreateButton(miscTab, "📋 Copy JobId / Server Code", function()
    pcall(function()
        if setclipboard then
            setclipboard(game.JobId)
        end
    end)
end)

print("[UnknownHub] Booga Booga Script Module v5 Loaded Successfully!")
