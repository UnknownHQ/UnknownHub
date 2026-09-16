--[[
    ========================================================================
    Unknown Hub - 3-Stage Universal Game Checker & Modular Loader
    Architecture:
      Stage 1: Game Checker & Fallback Dialog (Small GUI with Supported Games viewer)
      Stage 2: Core Engine & Library Loader
      Stage 3: Game-Specific Script Execution (Blox Fruits, Bee Swarm, Ink Game, etc.)
    ========================================================================
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId

local BASE_URL = "https://raw.githubusercontent.com/UnknownHQ/UnknownHub/main"
local LIBRARY_URL = BASE_URL .. "/UnknownLibrary"

-- =========================================================================
-- Supported Games Registry
-- =========================================================================
local SupportedGames = {
    {
        name = "Booga Booga",
        icon = "🏕️",
        placeIds = { 59004523, 59004524, 117296883, 117296884, 5253198075, 5928812690, 6393433504 },
        gameIds = { 59004523, 59004524, 117296883, 117296884, 5253198075 },
        scriptUrl = BASE_URL .. "/Games/BoogaBooga.luau",
        desc = "Kill & mob aura, auto harvest trees/ores, magnet loot, godmode & island TP"
    },
    {
        name = "Slap Battles",
        icon = "🥊",
        placeIds = { 6403373529, 9431156611, 11520107397, 9426795465, 124596094333302 },
        gameIds = { 2340706818 },
        scriptUrl = BASE_URL .. "/Games/SlapBattles.luau",
        desc = "Slap aura, anti-ragdoll, godmode, badges & glove farm"
    },
    {
        name = "Bee Swarm Simulator",
        icon = "🐝",
        placeIds = { 1537690962 },
        scriptUrl = BASE_URL .. "/Games/BeeSwarm.luau",
        desc = "Auto-field farm, token gatherer, sprouts & vicious bees"
    },
    {
        name = "Blox Fruits",
        icon = "⚔️",
        placeIds = { 2753915549, 4442272183, 7449423635 },
        gameIds = { 994732206, 2753915549, 4442272183, 7449423635 },
        scriptUrl = BASE_URL .. "/Games/BloxFruits.luau",
        desc = "Auto-farm levels, quest selector, auto-stats, boss & fruit sniper"
    },
    {
        name = "Ink Game / Squid Games",
        icon = "🦑",
        placeIds = { 17625359962, 17625126838 },
        scriptUrl = BASE_URL .. "/Games/InkGame.luau",
        desc = "Mini-game automation, ESP, godmode & remote triggers"
    }
}

local function findSupportedGame(pId)
    local curGameId = game.GameId
    for _, gameData in ipairs(SupportedGames) do
        for _, id in ipairs(gameData.placeIds) do
            if id == pId then
                return gameData
            end
        end
        if gameData.gameIds and curGameId and curGameId > 0 then
            for _, gId in ipairs(gameData.gameIds) do
                if gId == curGameId then
                    return gameData
                end
            end
        end
    end
    -- Universe / Experience level fallback check
    if curGameId == 994732206 or pId == 2753915549 or pId == 4442272183 or pId == 7449423635 then
        for _, gameData in ipairs(SupportedGames) do
            if gameData.name == "Blox Fruits" then
                return gameData
            end
        end
    end
    return nil
end

local function getSafeGuiParent()
    local parent = nil
    if gethui then
        pcall(function() parent = gethui() end)
    end
    if not parent and LocalPlayer then
        pcall(function() parent = LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui") end)
    end
    if not parent then
        pcall(function() parent = CoreGui end)
    end
    return parent
end

local function destroyOldCheckerGui()
    local targetName = "Unknown_GameChecker_UI"
    local parents = {CoreGui}
    if gethui then pcall(function() table.insert(parents, gethui()) end) end
    if LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui") then
        table.insert(parents, LocalPlayer.PlayerGui)
    end
    for _, p in ipairs(parents) do
        if p then
            for _, child in ipairs(p:GetChildren()) do
                if child:IsA("ScreenGui") and child.Name == targetName then
                    pcall(function() child:Destroy() end)
                end
            end
        end
    end
end

local function safeFetchScript(url)
    local cacheBuster = "?t=" .. tostring(os.time() or tick()) .. "_" .. tostring(math.random(1000, 9999))
    local ok, source = pcall(function()
        return game:HttpGet(url .. cacheBuster)
    end)
    if not ok or not source or source == "" then
        warn("[UnknownHub] Failed to fetch script from: " .. tostring(url))
        return nil, "Network download failed"
    end
    local chunk, compileErr = loadstring(source)
    if not chunk then
        warn("[UnknownHub] Compile error in script: " .. tostring(compileErr))
        return nil, compileErr
    end
    return chunk
end

-- =========================================================================
-- STAGE 1: Check Supported Game
-- =========================================================================
local detectedGame = findSupportedGame(PlaceId)

if detectedGame then
    -- Game is supported! Load the dedicated module directly
    print("[UnknownHub] Recognized game: " .. detectedGame.name .. " (PlaceId: " .. tostring(PlaceId) .. ")")
    local scriptChunk, err = safeFetchScript(detectedGame.scriptUrl)
    if scriptChunk then
        local execOk, runtimeErr = pcall(scriptChunk)
        if not execOk then
            warn("[UnknownHub] Runtime error loading " .. detectedGame.name .. ": " .. tostring(runtimeErr))
        end
    end
else
    -- =========================================================================
    -- Game is NOT supported: Render Sleek Minimalist "Not Supported" Small GUI
    -- =========================================================================
    print("[UnknownHub] PlaceId " .. tostring(PlaceId) .. " is not currently mapped. Showing Small GUI...")
    destroyOldCheckerGui()

    local sg = Instance.new("ScreenGui")
    sg.Name = "Unknown_GameChecker_UI"
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.Parent = getSafeGuiParent()

    local card = Instance.new("Frame")
    card.Name = "CheckerCard"
    card.Size = UDim2.new(0, 360, 0, 220)
    card.Position = UDim2.new(0.5, -180, 0.5, -110)
    card.BackgroundColor3 = Color3.fromRGB(14, 18, 26)
    card.BorderSizePixel = 0
    card.Active = true
    card.Parent = sg

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 10)
    cardCorner.Parent = card

    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = Color3.fromRGB(0, 195, 245)
    cardStroke.Thickness = 1.5
    cardStroke.Transparency = 0.2
    cardStroke.Parent = card

    -- Header bar
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 38)
    header.BackgroundColor3 = Color3.fromRGB(18, 24, 36)
    header.BorderSizePixel = 0
    header.Parent = card

    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 10)
    headerCorner.Parent = header

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, -70, 1, 0)
    titleLbl.Position = UDim2.new(0, 12, 0, 0)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = "🌊 UNKNOWN HUB • GAME CHECKER"
    titleLbl.TextColor3 = Color3.fromRGB(0, 210, 255)
    titleLbl.Font = Enum.Font.GothamBlack
    titleLbl.TextSize = 11
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Parent = header

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 24, 0, 24)
    closeBtn.Position = UDim2.new(1, -30, 0.5, -12)
    closeBtn.BackgroundColor3 = Color3.fromRGB(30, 38, 54)
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(240, 245, 255)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 11
    closeBtn.Parent = header

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeBtn

    closeBtn.MouseButton1Click:Connect(function()
        sg:Destroy()
    end)

    -- Message Body
    local descLbl = Instance.new("TextLabel")
    descLbl.Size = UDim2.new(1, -24, 0, 48)
    descLbl.Position = UDim2.new(0, 12, 0, 46)
    descLbl.BackgroundTransparency = 1
    descLbl.Text = "⚠️ Game Not Supported (Place ID: " .. tostring(PlaceId) .. ")\nNo tailored script module is available for this game yet."
    descLbl.TextColor3 = Color3.fromRGB(200, 212, 230)
    descLbl.Font = Enum.Font.GothamMedium
    descLbl.TextSize = 11
    descLbl.TextWrapped = true
    descLbl.TextXAlignment = Enum.TextXAlignment.Left
    descLbl.Parent = card

    -- Buttons row
    local btnViewGames = Instance.new("TextButton")
    btnViewGames.Size = UDim2.new(0.5, -16, 0, 34)
    btnViewGames.Position = UDim2.new(0, 12, 0, 102)
    btnViewGames.BackgroundColor3 = Color3.fromRGB(24, 32, 48)
    btnViewGames.Text = "📋 Supported Games"
    btnViewGames.TextColor3 = Color3.fromRGB(165, 95, 255)
    btnViewGames.Font = Enum.Font.GothamBold
    btnViewGames.TextSize = 11
    btnViewGames.Parent = card

    local bvgCorner = Instance.new("UICorner")
    bvgCorner.CornerRadius = UDim.new(0, 6)
    bvgCorner.Parent = btnViewGames

    local bvgStroke = Instance.new("UIStroke")
    bvgStroke.Color = Color3.fromRGB(165, 95, 255)
    bvgStroke.Thickness = 1
    bvgStroke.Transparency = 0.5
    bvgStroke.Parent = btnViewGames

    local btnLaunchUniversal = Instance.new("TextButton")
    btnLaunchUniversal.Size = UDim2.new(0.5, -16, 0, 34)
    btnLaunchUniversal.Position = UDim2.new(0.5, 4, 0, 102)
    btnLaunchUniversal.BackgroundColor3 = Color3.fromRGB(24, 38, 54)
    btnLaunchUniversal.Text = "🌐 Launch Universal"
    btnLaunchUniversal.TextColor3 = Color3.fromRGB(0, 210, 255)
    btnLaunchUniversal.Font = Enum.Font.GothamBold
    btnLaunchUniversal.TextSize = 11
    btnLaunchUniversal.Parent = card

    local bluCorner = Instance.new("UICorner")
    bluCorner.CornerRadius = UDim.new(0, 6)
    bluCorner.Parent = btnLaunchUniversal

    local bluStroke = Instance.new("UIStroke")
    bluStroke.Color = Color3.fromRGB(0, 210, 255)
    bluStroke.Thickness = 1
    bluStroke.Transparency = 0.5
    bluStroke.Parent = btnLaunchUniversal

    -- Expandable Supported Games List Container
    local gamesListFrame = Instance.new("ScrollingFrame")
    gamesListFrame.Size = UDim2.new(1, -24, 0, 60)
    gamesListFrame.Position = UDim2.new(0, 12, 0, 146)
    gamesListFrame.BackgroundColor3 = Color3.fromRGB(10, 14, 20)
    gamesListFrame.BorderSizePixel = 0
    gamesListFrame.ScrollBarThickness = 3
    gamesListFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    gamesListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    gamesListFrame.Parent = card

    local glCorner = Instance.new("UICorner")
    glCorner.CornerRadius = UDim.new(0, 6)
    glCorner.Parent = gamesListFrame

    local glLayout = Instance.new("UIListLayout")
    glLayout.Padding = UDim.new(0, 4)
    glLayout.SortOrder = Enum.SortOrder.LayoutOrder
    glLayout.Parent = gamesListFrame

    for _, g in ipairs(SupportedGames) do
        local row = Instance.new("TextLabel")
        row.Size = UDim2.new(1, -8, 0, 20)
        row.BackgroundTransparency = 1
        row.Text = "  " .. g.icon .. " " .. g.name .. " (PlaceIds: " .. table.concat(g.placeIds, ", ") .. ")"
        row.TextColor3 = Color3.fromRGB(180, 195, 220)
        row.Font = Enum.Font.GothamMedium
        row.TextSize = 10
        row.TextXAlignment = Enum.TextXAlignment.Left
        row.Parent = gamesListFrame
    end

    -- Launch Universal Button Action
    btnLaunchUniversal.MouseButton1Click:Connect(function()
        sg:Destroy()
        local libChunk = safeFetchScript(LIBRARY_URL)
        if libChunk then
            local libFactory = libChunk()
            if libFactory then
                libFactory({
                    title = "UNKNOWN HUB",
                    theme = Color3.fromRGB(0, 195, 245),
                    secondaryTheme = Color3.fromRGB(165, 95, 255)
                })
            end
        end
    end)

    -- Toggle View Games Button Action
    local expanded = false
    btnViewGames.MouseButton1Click:Connect(function()
        expanded = not expanded
        if expanded then
            card.Size = UDim2.new(0, 360, 0, 290)
            gamesListFrame.Size = UDim2.new(1, -24, 0, 130)
        else
            card.Size = UDim2.new(0, 360, 0, 220)
            gamesListFrame.Size = UDim2.new(1, -24, 0, 60)
        end
    end)

    -- Smooth Dragging for Small GUI Card
    local isDragging = false
    local dragStart = Vector3.new()
    local startPos = UDim2.new()

    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = true
            dragStart = input.Position
            startPos = card.Position
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            card.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end
