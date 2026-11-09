--[[
    ========================================================================
    UNKNOWN LIBRARY — V2.2 REFINED MINIMAL DARK UI (Obsidian-Free, Slop-Free)
    Engineered exclusively for Unknown Hub
    Precision Glass CanvasGroup, Custom RGB Selector & Silky Animations
    ========================================================================
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

-- =========================================================================
-- Theme & Styling Constants
-- =========================================================================
local DEFAULT_THEME = {
    Primary = Color3.fromRGB(250, 190, 25),       -- Vibrant Blox Fruits Amber Gold
    Secondary = Color3.fromRGB(0, 205, 255),      -- Cyber Cyan
    Background = Color3.fromRGB(15, 14, 18),      -- Deep Obsidian/Charcoal Slate
    Sidebar = Color3.fromRGB(19, 17, 23),         -- Elevated Sidebar Panel
    Card = Color3.fromRGB(20, 19, 25),            -- Control Row Base
    CardTop = Color3.fromRGB(28, 26, 33),         -- Dual-stop Row Top Gloss
    CardBottom = Color3.fromRGB(16, 15, 20),      -- Dual-stop Row Bottom Base
    CardHover = Color3.fromRGB(32, 29, 39),       -- Smooth Hover Highlight
    Input = Color3.fromRGB(14, 13, 17),           -- Embedded Input Track
    Stroke = Color3.fromRGB(42, 38, 50),          -- Razor-sharp 1px Bevel Border
    GoldTop = Color3.fromRGB(255, 220, 45),       -- Iconic BF Gold Button Top Highlight
    GoldBottom = Color3.fromRGB(230, 165, 10),    -- Iconic BF Gold Button Bottom
    GoldStroke = Color3.fromRGB(65, 45, 5),       -- Deep Dark Golden Outline
    GoldText = Color3.fromRGB(22, 16, 0),         -- Bold Dark Text on Gold Button
    TextPrimary = Color3.fromRGB(245, 246, 250),  -- Clean Crisp Off-White
    TextSecondary = Color3.fromRGB(150, 155, 170),-- Muted Slate Gray
    TextDim = Color3.fromRGB(100, 105, 120),      -- Subtle Placeholders / Subtext
    Success = Color3.fromRGB(45, 215, 120),
    Warning = Color3.fromRGB(255, 175, 30),
    Danger = Color3.fromRGB(245, 65, 80)
}

local function applyCardGradient(obj, topColor, bottomColor)
    if not obj then return nil end
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, topColor or DEFAULT_THEME.CardTop),
        ColorSequenceKeypoint.new(1, bottomColor or DEFAULT_THEME.CardBottom)
    })
    g.Rotation = 90
    pcall(function() g.Parent = obj end)
    return g
end

-- Automatic Category / Keyword Style Matcher (Blox Fruits Themed Icons & Colors)
local function getCategoryStyle(rawTitle)
    local t = string.lower(tostring(rawTitle or ""))
    if t:find("melee") or t:find("fist") or t:find("punch") or t:find("combat") or t:find("attack") then
        return "🥊", Color3.fromRGB(255, 160, 160) -- Peach/Salmon
    elseif t:find("defense") or t:find("shield") or t:find("armor") or t:find("god") or t:find("immune") or t:find("protect") then
        return "🛡️", Color3.fromRGB(96, 176, 255)  -- Sky Blue
    elseif t:find("sword") or t:find("blade") or t:find("katana") or t:find("slash") then
        return "⚔️", Color3.fromRGB(124, 255, 86)  -- Lime Green
    elseif t:find("gun") or t:find("flintlock") or t:find("cannon") or t:find("turret") or t:find("shoot") then
        return "🔫", Color3.fromRGB(255, 215, 60)  -- Warm Gold
    elseif t:find("fruit") or t:find("blox") or t:find("devil") or t:find("ability") or t:find("magic") then
        return "🍎", Color3.fromRGB(216, 168, 255) -- Lavender Purple
    elseif t:find("farm") or t:find("gold") or t:find("chest") or t:find("coin") or t:find("money") then
        return "🍯", Color3.fromRGB(250, 190, 30)  -- Golden Amber
    elseif t:find("speed") or t:find("fly") or t:find("noclip") or t:find("teleport") or t:find("walk") then
        return "⚡", Color3.fromRGB(0, 220, 255)   -- Electric Cyan
    elseif t:find("esp") or t:find("visual") or t:find("wallhack") or t:find("tracer") or t:find("chams") then
        return "👁️", Color3.fromRGB(255, 130, 210) -- Radiant Rose
    elseif t:find("build") or t:find("stealer") or t:find("save") or t:find("slot") then
        return "🏗️", Color3.fromRGB(250, 155, 45)  -- Amber Orange
    elseif t:find("player") or t:find("kill") or t:find("target") or t:find("aim") then
        return "🎯", Color3.fromRGB(255, 90, 90)   -- Crimson
    elseif t:find("setting") or t:find("config") or t:find("key") then
        return "⚙️", Color3.fromRGB(175, 185, 205) -- Silver Slate
    end
    return "◆", Color3.fromRGB(245, 246, 250)
end

-- =========================================================================
-- Core Utility Helpers
-- =========================================================================
local function applyCorner(obj, radius)
    if not obj then return nil end
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    pcall(function() c.Parent = obj end)
    return c
end

local function applyStroke(obj, color, thickness, transparency)
    if not obj then return nil end
    local s = Instance.new("UIStroke")
    s.Color = color or DEFAULT_THEME.Stroke
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    pcall(function() s.Parent = obj end)
    return s
end

local function tween(obj, info, props)
    if not obj then return nil end
    local tw = TweenService:Create(obj, info, props)
    tw:Play()
    return tw
end

local function colorToHex(color)
    local r = math.clamp(math.floor(color.R * 255), 0, 255)
    local g = math.clamp(math.floor(color.G * 255), 0, 255)
    local b = math.clamp(math.floor(color.B * 255), 0, 255)
    return string.format("#%02X%02X%02X", r, g, b)
end

-- =========================================================================
-- UnknownLibrary Entry Constructor
-- =========================================================================
return function(opts)
    opts = opts or {}
    local LocalPlayer = Players.LocalPlayer

    -- Themes & Customization
    local primaryTheme = opts.theme or opts.primaryTheme or DEFAULT_THEME.Primary
    local secondaryTheme = opts.secondaryTheme or DEFAULT_THEME.Secondary
    local toggleKeyCode = opts.toggleKey or Enum.KeyCode.RightControl
    if type(toggleKeyCode) == "string" and Enum.KeyCode[toggleKeyCode] then
        toggleKeyCode = Enum.KeyCode[toggleKeyCode]
    end

    local LIBRARY_GUI_NAME = opts.name or "Unknown_TabbedHub_UI"
    local HUB_TITLE = opts.title or "UNKNOWN HUB"
    local HUB_SUBTITLE = opts.subTitle or "UNIVERSAL"

    -- Theme Updater Registry (Live color switching)
    local themeUpdaters = {}
    local function registerThemeUpdater(fn)
        if type(fn) == "function" then
            table.insert(themeUpdaters, fn)
            pcall(fn, primaryTheme)
        end
    end

    local function setAccentColor(newColor)
        primaryTheme = newColor
        for _, fn in ipairs(themeUpdaters) do
            pcall(fn, primaryTheme)
        end
    end

    -- Target Parent Determination (Safe Context)
    local targetParent = opts.parent
    if not targetParent then
        local okHui, hui = pcall(function() return gethui and gethui() end)
        if okHui and hui then
            targetParent = hui
        elseif LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui") then
            targetParent = LocalPlayer.PlayerGui
        else
            pcall(function() targetParent = CoreGui end)
        end
    end

    -- 0. Universal Teardown Protocol: Stop ALL previous hub functions and disconnect previous listeners!
    if _G.UNKNOWN_ACTIVE_HUB and type(_G.UNKNOWN_ACTIVE_HUB.destroy) == "function" then
        pcall(function()
            _G.UNKNOWN_ACTIVE_HUB.destroy()
        end)
        _G.UNKNOWN_ACTIVE_HUB = nil
    end

    -- Clean up any previous instances
    local cleanupContainers = {targetParent, CoreGui, LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")}
    for _, container in ipairs(cleanupContainers) do
        if container then
            pcall(function()
                for _, child in ipairs(container:GetChildren()) do
                    if child.Name == LIBRARY_GUI_NAME or child.Name:find("Unknown_TabbedHub") then
                        pcall(function() child:Destroy() end)
                    end
                end
            end)
        end
    end

    -- =========================================================================
    -- Root ScreenGui Creation
    -- =========================================================================
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = LIBRARY_GUI_NAME
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    pcall(function() screenGui.Parent = targetParent end)

    -- Window Dimensions
    local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
    local winWidth = isMobile and 600 or 700
    local winHeight = isMobile and 410 or 460
    local SIDEBAR_WIDTH = 195
    local HEADER_HEIGHT = 46

    -- =========================================================================
    -- Main Window Shell (CanvasGroup for 100% Flawless Rounded Corner Clipping)
    -- =========================================================================
    local registeredElements = {}
    local registeredFlags = {}
    local registeredSections = {}
    local mainFrame = Instance.new("CanvasGroup")
    mainFrame.Name = "MainWindow"
    mainFrame.Size = UDim2.new(0, winWidth, 0, winHeight)
    mainFrame.Position = UDim2.new(0.5, -math.floor(winWidth / 2), 0.5, -math.floor(winHeight / 2))
    mainFrame.BackgroundColor3 = DEFAULT_THEME.Background
    mainFrame.BorderSizePixel = 0
    mainFrame.GroupTransparency = 0
    mainFrame.Active = true
    mainFrame.Parent = screenGui
    applyCorner(mainFrame, 12)
    local mainStroke = applyStroke(mainFrame, DEFAULT_THEME.Stroke, 1, 0.25)

    -- Soft Depth Glow Shadow (Behind MainWindow)
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "DropShadow"
    shadow.Size = UDim2.new(0, winWidth + 44, 0, winHeight + 44)
    shadow.Position = UDim2.new(0.5, -math.floor(winWidth / 2) - 22, 0.5, -math.floor(winHeight / 2) - 22)
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://6015897843"
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = 0.45
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(49, 49, 450, 450)
    shadow.ZIndex = -1
    shadow.Parent = screenGui

    -- Keep shadow in sync with mainFrame movement
    mainFrame:GetPropertyChangedSignal("Position"):Connect(function()
        shadow.Position = UDim2.new(mainFrame.Position.X.Scale, mainFrame.Position.X.Offset - 22, mainFrame.Position.Y.Scale, mainFrame.Position.Y.Offset - 22)
    end)
    mainFrame:GetPropertyChangedSignal("Size"):Connect(function()
        shadow.Size = UDim2.new(0, mainFrame.AbsoluteSize.X + 44, 0, mainFrame.AbsoluteSize.Y + 44)
    end)
    mainFrame:GetPropertyChangedSignal("Visible"):Connect(function()
        shadow.Visible = mainFrame.Visible
    end)

    -- =========================================================================
    -- Sidebar (Left Navigation)
    -- =========================================================================
    local sidebar = Instance.new("Frame")
    sidebar.Name = "Sidebar"
    sidebar.Size = UDim2.new(0, SIDEBAR_WIDTH, 1, 0)
    sidebar.Position = UDim2.new(0, 0, 0, 0)
    sidebar.BackgroundColor3 = DEFAULT_THEME.Sidebar
    sidebar.BorderSizePixel = 0
    sidebar.Parent = mainFrame
    applyCorner(sidebar, 12)

    -- Sidebar Right Border Divider
    local sidebarBorder = Instance.new("Frame")
    sidebarBorder.Name = "SidebarBorder"
    sidebarBorder.Size = UDim2.new(0, 1, 1, 0)
    sidebarBorder.Position = UDim2.new(1, -1, 0, 0)
    sidebarBorder.BackgroundColor3 = DEFAULT_THEME.Stroke
    sidebarBorder.BorderSizePixel = 0
    sidebarBorder.Parent = sidebar

    -- Hub Brand Header
    local brandFrame = Instance.new("Frame")
    brandFrame.Name = "BrandHeader"
    brandFrame.Size = UDim2.new(1, 0, 0, 56)
    brandFrame.BackgroundTransparency = 1
    brandFrame.Parent = sidebar

    local brandLogo = Instance.new("TextLabel")
    brandLogo.Name = "LogoIcon"
    brandLogo.Size = UDim2.new(0, 24, 0, 24)
    brandLogo.Position = UDim2.new(0, 14, 0, 16)
    brandLogo.BackgroundTransparency = 1
    brandLogo.Font = Enum.Font.GothamBold
    brandLogo.Text = "⚡"
    brandLogo.TextColor3 = primaryTheme
    brandLogo.TextSize = 17
    brandLogo.Parent = brandFrame
    registerThemeUpdater(function(c) brandLogo.TextColor3 = c end)

    local brandTitle = Instance.new("TextLabel")
    brandTitle.Name = "Title"
    brandTitle.Size = UDim2.new(1, -46, 0, 18)
    brandTitle.Position = UDim2.new(0, 42, 0, 13)
    brandTitle.BackgroundTransparency = 1
    brandTitle.Font = Enum.Font.GothamBold
    brandTitle.Text = HUB_TITLE
    brandTitle.TextColor3 = DEFAULT_THEME.TextPrimary
    brandTitle.TextSize = 13
    brandTitle.TextXAlignment = Enum.TextXAlignment.Left
    brandTitle.TextTruncate = Enum.TextTruncate.AtEnd
    brandTitle.Parent = brandFrame

    local brandSubtitle = Instance.new("TextLabel")
    brandSubtitle.Name = "Subtitle"
    brandSubtitle.Size = UDim2.new(1, -46, 0, 14)
    brandSubtitle.Position = UDim2.new(0, 42, 0, 29)
    brandSubtitle.BackgroundTransparency = 1
    brandSubtitle.Font = Enum.Font.Gotham
    brandSubtitle.Text = HUB_SUBTITLE
    brandSubtitle.TextColor3 = DEFAULT_THEME.TextSecondary
    brandSubtitle.TextSize = 10
    brandSubtitle.TextXAlignment = Enum.TextXAlignment.Left
    brandSubtitle.TextTruncate = Enum.TextTruncate.AtEnd
    brandSubtitle.Parent = brandFrame

    -- Tab Navigation Container (Scrollable)
    local tabScroll = Instance.new("ScrollingFrame")
    tabScroll.Name = "TabList"
    tabScroll.Size = UDim2.new(1, 0, 1, -100)
    tabScroll.Position = UDim2.new(0, 0, 0, 58)
    tabScroll.BackgroundTransparency = 1
    tabScroll.BorderSizePixel = 0
    tabScroll.ScrollBarThickness = 0
    tabScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    tabScroll.Parent = sidebar

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Vertical
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Padding = UDim.new(0, 4)
    tabLayout.Parent = tabScroll

    local tabPadding = Instance.new("UIPadding")
    tabPadding.PaddingLeft = UDim.new(0, 8)
    tabPadding.PaddingRight = UDim.new(0, 8)
    tabPadding.PaddingTop = UDim.new(0, 4)
    tabPadding.PaddingBottom = UDim.new(0, 4)
    tabPadding.Parent = tabScroll

    -- Sidebar Footer Info (Status / FPS)
    local sidebarFooter = Instance.new("Frame")
    sidebarFooter.Name = "SidebarFooter"
    sidebarFooter.Size = UDim2.new(1, -16, 0, 32)
    sidebarFooter.Position = UDim2.new(0, 8, 1, -38)
    sidebarFooter.BackgroundColor3 = Color3.fromRGB(14, 16, 22)
    sidebarFooter.BorderSizePixel = 0
    sidebarFooter.Parent = sidebar
    applyCorner(sidebarFooter, 6)
    applyStroke(sidebarFooter, DEFAULT_THEME.Stroke, 1, 0.4)

    local statusDot = Instance.new("Frame")
    statusDot.Name = "StatusDot"
    statusDot.Size = UDim2.new(0, 6, 0, 6)
    statusDot.Position = UDim2.new(0, 10, 0.5, -3)
    statusDot.BackgroundColor3 = DEFAULT_THEME.Success
    statusDot.BorderSizePixel = 0
    statusDot.Parent = sidebarFooter
    applyCorner(statusDot, 3)

    local statusText = Instance.new("TextLabel")
    statusText.Name = "StatusLabel"
    statusText.Size = UDim2.new(1, -24, 1, 0)
    statusText.Position = UDim2.new(0, 22, 0, 0)
    statusText.BackgroundTransparency = 1
    statusText.Font = Enum.Font.Gotham
    statusText.Text = "Connected • 60 FPS"
    statusText.TextColor3 = DEFAULT_THEME.TextSecondary
    statusText.TextSize = 10
    statusText.TextXAlignment = Enum.TextXAlignment.Left
    statusText.Parent = sidebarFooter

    -- FPS Counter
    task.spawn(function()
        local lastTime = tick()
        local frameCount = 0
        RunService.RenderStepped:Connect(function()
            frameCount = frameCount + 1
            local now = tick()
            if now - lastTime >= 1 then
                local fps = math.floor(frameCount / (now - lastTime))
                frameCount = 0
                lastTime = now
                pcall(function()
                    if statusText and statusText.Parent then
                        statusText.Text = "Connected • " .. tostring(fps) .. " FPS"
                    end
                end)
            end
        end)
    end)

    -- =========================================================================
    -- Top Header Bar (Right of Sidebar)
    -- =========================================================================
    local header = Instance.new("Frame")
    header.Name = "HeaderBar"
    header.Size = UDim2.new(1, -SIDEBAR_WIDTH, 0, HEADER_HEIGHT)
    header.Position = UDim2.new(0, SIDEBAR_WIDTH, 0, 0)
    header.BackgroundTransparency = 1
    header.Parent = mainFrame

    local headerDivider = Instance.new("Frame")
    headerDivider.Name = "HeaderDivider"
    headerDivider.Size = UDim2.new(1, 0, 0, 1)
    headerDivider.Position = UDim2.new(0, 0, 1, -1)
    headerDivider.BackgroundColor3 = DEFAULT_THEME.Stroke
    headerDivider.BorderSizePixel = 0
    headerDivider.Parent = header

    -- Search Bar & Live Control Filter (Anti-Collision Spaced Layout)
    local searchContainer = Instance.new("Frame")
    searchContainer.Name = "SearchContainer"
    searchContainer.Size = UDim2.new(0, 154, 0, 26)
    searchContainer.Position = UDim2.new(1, -360, 0.5, -13)
    searchContainer.BackgroundColor3 = DEFAULT_THEME.Input
    searchContainer.BorderSizePixel = 0
    searchContainer.Parent = header
    applyCorner(searchContainer, 6)
    applyStroke(searchContainer, DEFAULT_THEME.Stroke, 1, 0.3)

    local searchIcon = Instance.new("TextLabel")
    searchIcon.Size = UDim2.new(0, 20, 1, 0)
    searchIcon.Position = UDim2.new(0, 6, 0, 0)
    searchIcon.BackgroundTransparency = 1
    searchIcon.Font = Enum.Font.Gotham
    searchIcon.Text = "?"
    searchIcon.TextColor3 = DEFAULT_THEME.TextDim
    searchIcon.TextSize = 11
    searchIcon.Parent = searchContainer

    local searchInput = Instance.new("TextBox")
    searchInput.Name = "SearchBox"
    searchInput.Size = UDim2.new(1, -32, 1, 0)
    searchInput.Position = UDim2.new(0, 26, 0, 0)
    searchInput.BackgroundTransparency = 1
    searchInput.Font = Enum.Font.Gotham
    searchInput.PlaceholderText = "Search..."
    searchInput.PlaceholderColor3 = DEFAULT_THEME.TextDim
    searchInput.Text = ""
    searchInput.TextColor3 = DEFAULT_THEME.TextPrimary
    searchInput.TextSize = 11
    searchInput.TextXAlignment = Enum.TextXAlignment.Left
    searchInput.ClearTextOnFocus = false
    searchInput.Parent = searchContainer

    -- Universal Changelog & Update Log Modal Viewer
    local function showUpdateLogModal()
        local modalOverlay = Instance.new("TextButton")
        modalOverlay.Name = "Unknown_UpdateLogModal"
        modalOverlay.Size = UDim2.new(1, 0, 1, 0)
        modalOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        modalOverlay.BackgroundTransparency = 0.45
        modalOverlay.BorderSizePixel = 0
        modalOverlay.Text = ""
        modalOverlay.AutoButtonColor = false
        modalOverlay.ZIndex = 99999
        modalOverlay.Parent = screenGui

        local mBox = Instance.new("Frame")
        mBox.Size = UDim2.new(0, 480, 0, 360)
        mBox.Position = UDim2.new(0.5, -240, 0.5, -180)
        mBox.BackgroundColor3 = DEFAULT_THEME.Background
        mBox.BorderSizePixel = 0
        mBox.Parent = modalOverlay
        applyCorner(mBox, 12)
        applyStroke(mBox, DEFAULT_THEME.Stroke, 1, 0.2)

        local mHead = Instance.new("Frame")
        mHead.Size = UDim2.new(1, 0, 0, 44)
        mHead.BackgroundTransparency = 1
        mHead.Parent = mBox

        local mTitle = Instance.new("TextLabel")
        mTitle.Size = UDim2.new(1, -50, 1, 0)
        mTitle.Position = UDim2.new(0, 18, 0, 0)
        mTitle.BackgroundTransparency = 1
        mTitle.Font = Enum.Font.GothamBold
        mTitle.Text = "Unknown Hub ? Global Update Log"
        mTitle.TextColor3 = primaryTheme
        mTitle.TextSize = 14
        mTitle.TextXAlignment = Enum.TextXAlignment.Left
        mTitle.Parent = mHead

        local mClose = Instance.new("TextButton")
        mClose.Size = UDim2.new(0, 28, 0, 28)
        mClose.Position = UDim2.new(1, -38, 0.5, -14)
        mClose.BackgroundColor3 = DEFAULT_THEME.Card
        mClose.Text = "?"
        mClose.TextColor3 = DEFAULT_THEME.TextSecondary
        mClose.Font = Enum.Font.GothamBold
        mClose.TextSize = 14
        mClose.Parent = mHead
        applyCorner(mClose, 6)
        mClose.MouseButton1Click:Connect(function() modalOverlay:Destroy() end)

        local logScroll = Instance.new("ScrollingFrame")
        logScroll.Size = UDim2.new(1, -24, 1, -56)
        logScroll.Position = UDim2.new(0, 12, 0, 46)
        logScroll.BackgroundTransparency = 1
        logScroll.BorderSizePixel = 0
        logScroll.ScrollBarThickness = 4
        logScroll.ScrollBarImageColor3 = primaryTheme
        logScroll.Parent = mBox

        local logLayout = Instance.new("UIListLayout")
        logLayout.Padding = UDim.new(0, 10)
        logLayout.Parent = logScroll
        logLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            logScroll.CanvasSize = UDim2.new(0, 0, 0, logLayout.AbsoluteContentSize.Y + 20)
        end)

        local function addLogCard(ver, date, bulletList)
            local card = Instance.new("Frame")
            card.Size = UDim2.new(1, 0, 0, 30 + (#bulletList * 20))
            card.BackgroundColor3 = DEFAULT_THEME.Card
            card.BorderSizePixel = 0
            card.Parent = logScroll
            applyCorner(card, 8)
            applyStroke(card, DEFAULT_THEME.Stroke, 1, 0.3)

            local vLabel = Instance.new("TextLabel")
            vLabel.Size = UDim2.new(1, -16, 0, 22)
            vLabel.Position = UDim2.new(0, 12, 0, 6)
            vLabel.BackgroundTransparency = 1
            vLabel.Font = Enum.Font.GothamBold
            vLabel.Text = ver .. "  ?  " .. date
            vLabel.TextColor3 = primaryTheme
            vLabel.TextSize = 12
            vLabel.TextXAlignment = Enum.TextXAlignment.Left
            vLabel.Parent = card

            for idx, text in ipairs(bulletList) do
                local b = Instance.new("TextLabel")
                b.Size = UDim2.new(1, -24, 0, 18)
                b.Position = UDim2.new(0, 16, 0, 26 + (idx - 1) * 20)
                b.BackgroundTransparency = 1
                b.Font = Enum.Font.Gotham
                b.Text = "? " .. text
                b.TextColor3 = DEFAULT_THEME.TextSecondary
                b.TextSize = 11
                b.TextXAlignment = Enum.TextXAlignment.Left
                b.Parent = card
            end
        end

        addLogCard("V2.5.0", "November 2026", {
            "Autonomous 1-100 DOORS Completer with Room 50 & 100 auto-solvers",
            "Universal Configuration System: Save/Load profiles to disk",
            "Real-Time Header Search Bar across all categories",
            "Universal 2D Entity Rounded Corner ESP Library with C++ physics welds",
            "Anti-Halt full neutralization & Anti-Screech camera shake filter",
            "Autonomous Rush & Entity Altitude Safe Phase (+35 studs)"
        })

        addLogCard("V2.4.0", "October 2026", {
            "Autonomous Knobs Farm integrated with native Fly Noclip",
            "Auto Death Farm 24/7 background worker added",
            "First-Person camera & head alignment fix (zero body clipping)"
        })
    end

    -- Updates / Changelog Header Button (Clean Spacing)
    local updatesBtn = Instance.new("TextButton")
    updatesBtn.Name = "UpdatesButton"
    updatesBtn.Size = UDim2.new(0, 62, 0, 24)
    updatesBtn.Position = UDim2.new(1, -134, 0.5, -12)
    updatesBtn.BackgroundColor3 = DEFAULT_THEME.Card
    updatesBtn.BorderSizePixel = 0
    updatesBtn.Font = Enum.Font.GothamBold
    updatesBtn.Text = "? Logs"
    updatesBtn.TextColor3 = primaryTheme
    updatesBtn.TextSize = 11
    updatesBtn.Parent = header
    applyCorner(updatesBtn, 6)
    applyStroke(updatesBtn, primaryTheme, 1, 0.4)

    updatesBtn.MouseButton1Click:Connect(showUpdateLogModal)
    -- Hub.ShowUpdateLog assigned below after Hub table creation

    local function applyGlobalFilter()
        local q = searchInput.Text:lower():gsub("^%s*(.-)%s*$", "%1")
        if q == "" then
            for _, elem in ipairs(registeredElements) do
                if elem.Card and elem.Card.Parent then
                    elem.Card.Visible = true
                end
            end
            for _, sec in ipairs(registeredSections) do
                if sec.Container and sec.Container.Parent then
                    sec.Container.Visible = true
                end
            end
            return
        end

        local visibleCountByParent = {}
        for _, elem in ipairs(registeredElements) do
            if elem.Card and elem.Card.Parent then
                local matches = (elem.Title:lower():find(q, 1, true) ~= nil)
                elem.Card.Visible = matches
                if matches then
                    local p = elem.Card.Parent
                    visibleCountByParent[p] = (visibleCountByParent[p] or 0) + 1
                end
            end
        end

        for _, sec in ipairs(registeredSections) do
            if sec.Container and sec.Container.Parent then
                local secTitleMatches = (sec.Title:lower():find(q, 1, true) ~= nil)
                local p = sec.Container.Parent
                if secTitleMatches then
                    sec.Container.Visible = true
                else
                    sec.Container.Visible = (visibleCountByParent[p] ~= nil and visibleCountByParent[p] > 0)
                end
            end
        end
    end

    searchInput:GetPropertyChangedSignal("Text"):Connect(applyGlobalFilter)

    -- Breadcrumb Title (Truncated dynamically so it never bleeds into search box)
    local breadcrumbTitle = Instance.new("TextLabel")
    breadcrumbTitle.Name = "BreadcrumbTitle"
    breadcrumbTitle.Size = UDim2.new(1, -384, 1, 0)
    breadcrumbTitle.Position = UDim2.new(0, 18, 0, 0)
    breadcrumbTitle.BackgroundTransparency = 1
    breadcrumbTitle.Font = Enum.Font.GothamBold
    breadcrumbTitle.Text = "Overview"
    breadcrumbTitle.TextColor3 = DEFAULT_THEME.TextPrimary
    breadcrumbTitle.TextSize = 14
    breadcrumbTitle.TextXAlignment = Enum.TextXAlignment.Left
    breadcrumbTitle.TextTruncate = Enum.TextTruncate.AtEnd
    breadcrumbTitle.Parent = header

    -- Keybind Badge Pill (No overlap with Updates or Search)
    local keybindPill = Instance.new("TextButton")
    keybindPill.Name = "ToggleKeyBadge"
    keybindPill.Size = UDim2.new(0, 56, 0, 24)
    keybindPill.Position = UDim2.new(1, -198, 0.5, -12)
    keybindPill.BackgroundColor3 = DEFAULT_THEME.Card
    keybindPill.BorderSizePixel = 0
    keybindPill.Font = Enum.Font.Gotham
    keybindPill.Text = "[" .. toggleKeyCode.Name .. "]"
    keybindPill.TextColor3 = DEFAULT_THEME.TextSecondary
    keybindPill.TextSize = 10
    keybindPill.AutoButtonColor = false
    keybindPill.Parent = header
    applyCorner(keybindPill, 6)
    applyStroke(keybindPill, DEFAULT_THEME.Stroke, 1, 0.3)

    -- Window Controls Container (Minimize & Close pinned on right)
    local winControls = Instance.new("Frame")
    winControls.Name = "WindowControls"
    winControls.Size = UDim2.new(0, 52, 0, 24)
    winControls.Position = UDim2.new(1, -64, 0.5, -12)
    winControls.BackgroundTransparency = 1
    winControls.Parent = header

    local minimizeBtn = Instance.new("TextButton")
    minimizeBtn.Name = "MinimizeButton"
    minimizeBtn.Size = UDim2.new(0, 24, 0, 24)
    minimizeBtn.Position = UDim2.new(0, 0, 0, 0)
    minimizeBtn.BackgroundColor3 = DEFAULT_THEME.Card
    minimizeBtn.BorderSizePixel = 0
    minimizeBtn.Font = Enum.Font.GothamBold
    minimizeBtn.Text = "—"
    minimizeBtn.TextColor3 = DEFAULT_THEME.TextSecondary
    minimizeBtn.TextSize = 11
    minimizeBtn.AutoButtonColor = false
    minimizeBtn.Parent = winControls
    applyCorner(minimizeBtn, 6)

    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseButton"
    closeBtn.Size = UDim2.new(0, 24, 0, 24)
    closeBtn.Position = UDim2.new(0, 28, 0, 0)
    closeBtn.BackgroundColor3 = DEFAULT_THEME.Card
    closeBtn.BorderSizePixel = 0
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = DEFAULT_THEME.TextSecondary
    closeBtn.TextSize = 11
    closeBtn.AutoButtonColor = false
    closeBtn.Parent = winControls
    applyCorner(closeBtn, 6)

    -- Hover effects on header buttons
    for _, btn in ipairs({minimizeBtn, closeBtn, keybindPill}) do
        btn.MouseEnter:Connect(function()
            tween(btn, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {BackgroundColor3 = DEFAULT_THEME.CardHover, TextColor3 = DEFAULT_THEME.TextPrimary})
        end)
        btn.MouseLeave:Connect(function()
            tween(btn, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {BackgroundColor3 = DEFAULT_THEME.Card, TextColor3 = DEFAULT_THEME.TextSecondary})
        end)
    end

    -- =========================================================================
    -- Content Pages Container (Right of Sidebar, Below Header)
    -- =========================================================================
    local contentArea = Instance.new("Frame")
    contentArea.Name = "ContentArea"
    contentArea.Size = UDim2.new(1, -SIDEBAR_WIDTH, 1, -HEADER_HEIGHT)
    contentArea.Position = UDim2.new(0, SIDEBAR_WIDTH, 0, HEADER_HEIGHT)
    contentArea.BackgroundTransparency = 1
    contentArea.ClipsDescendants = true
    contentArea.Parent = mainFrame

    -- =========================================================================
    -- Dragging Mechanics
    -- =========================================================================
    local isDragging = false
    local dragInput = nil
    local dragStart = nil
    local startPos = nil

    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    isDragging = false
                end
            end)
        end
    end)

    header.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and isDragging then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    -- =========================================================================
    -- Silky-Smooth UI Hide / Reveal Animation Engine (Zero Glitch)
    -- =========================================================================
    local isMinimized = false
    local isGuiVisible = true
    local animToken = 0

    minimizeBtn.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized
        if isMinimized then
            minimizeBtn.Text = "□"
            tween(mainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, winWidth, 0, HEADER_HEIGHT)})
            contentArea.Visible = false
            tabScroll.Visible = false
            sidebarFooter.Visible = false
        else
            minimizeBtn.Text = "—"
            contentArea.Visible = true
            tabScroll.Visible = true
            sidebarFooter.Visible = true
            tween(mainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, winWidth, 0, winHeight)})
        end
    end)

    local function setGuiVisible(visible)
        if isGuiVisible == visible then return end
        isGuiVisible = visible
        animToken = animToken + 1
        local myToken = animToken

        local targetH = isMinimized and HEADER_HEIGHT or winHeight

        if visible then
            mainFrame.Visible = true
            shadow.Visible = true
            mainFrame.GroupTransparency = 1
            mainFrame.Size = UDim2.new(0, winWidth - 18, 0, targetH - 14)

            tween(mainFrame, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                GroupTransparency = 0,
                Size = UDim2.new(0, winWidth, 0, targetH)
            })
            tween(shadow, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                ImageTransparency = 0.45
            })
        else
            local tw = tween(mainFrame, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                GroupTransparency = 1,
                Size = UDim2.new(0, winWidth - 18, 0, targetH - 14)
            })
            tween(shadow, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                ImageTransparency = 1
            })
            tw.Completed:Connect(function()
                if myToken == animToken and not isGuiVisible then
                    mainFrame.Visible = false
                    shadow.Visible = false
                end
            end)
        end
    end

    closeBtn.MouseButton1Click:Connect(function()
        setGuiVisible(false)
    end)

    -- Keybind rebinding
    local listeningForRebind = false
    keybindPill.MouseButton1Click:Connect(function()
        if listeningForRebind then return end
        listeningForRebind = true
        keybindPill.Text = "[...]"
        keybindPill.TextColor3 = primaryTheme
    end)

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if listeningForRebind and input.UserInputType == Enum.UserInputType.Keyboard then
            toggleKeyCode = input.KeyCode
            keybindPill.Text = "[" .. toggleKeyCode.Name .. "]"
            keybindPill.TextColor3 = DEFAULT_THEME.TextSecondary
            listeningForRebind = false
            return
        end

        if not gameProcessed and input.KeyCode == toggleKeyCode then
            setGuiVisible(not isGuiVisible)
        end
    end)

    -- =========================================================================
    -- Notification Toast Engine
    -- =========================================================================
    local notifContainer = Instance.new("Frame")
    notifContainer.Name = "NotificationStack"
    notifContainer.Size = UDim2.new(0, 280, 1, -40)
    notifContainer.Position = UDim2.new(1, -295, 0, 20)
    notifContainer.BackgroundTransparency = 1
    notifContainer.Parent = screenGui

    local notifLayout = Instance.new("UIListLayout")
    notifLayout.FillDirection = Enum.FillDirection.Vertical
    notifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    notifLayout.SortOrder = Enum.SortOrder.LayoutOrder
    notifLayout.Padding = UDim.new(0, 8)
    notifLayout.Parent = notifContainer

    local function sendNotification(titleOrOpts, messageText, duration)
        local nTitle = "Notification"
        local nDesc = ""
        local nDur = duration or 3.5

        if type(titleOrOpts) == "table" then
            nTitle = titleOrOpts.Title or titleOrOpts.title or nTitle
            nDesc = titleOrOpts.Content or titleOrOpts.Text or titleOrOpts.message or titleOrOpts.description or nDesc
            nDur = titleOrOpts.Duration or titleOrOpts.duration or nDur
        else
            nTitle = tostring(titleOrOpts or nTitle)
            nDesc = tostring(messageText or "")
        end

        local card = Instance.new("Frame")
        card.Name = "Toast"
        card.Size = UDim2.new(1, 0, 0, 60)
        card.Position = UDim2.new(1, 50, 0, 0)
        card.BackgroundColor3 = DEFAULT_THEME.Card
        card.BorderSizePixel = 0
        card.ClipsDescendants = true
        card.Parent = notifContainer
        applyCorner(card, 8)
        applyStroke(card, DEFAULT_THEME.Stroke, 1, 0.2)

        local accentBar = Instance.new("Frame")
        accentBar.Name = "AccentBar"
        accentBar.Size = UDim2.new(0, 3, 1, 0)
        accentBar.BackgroundColor3 = primaryTheme
        accentBar.BorderSizePixel = 0
        accentBar.Parent = card
        applyCorner(accentBar, 2)

        local tLabel = Instance.new("TextLabel")
        tLabel.Name = "Title"
        tLabel.Size = UDim2.new(1, -20, 0, 18)
        tLabel.Position = UDim2.new(0, 12, 0, 8)
        tLabel.BackgroundTransparency = 1
        tLabel.Font = Enum.Font.GothamBold
        tLabel.Text = nTitle
        tLabel.TextColor3 = DEFAULT_THEME.TextPrimary
        tLabel.TextSize = 13
        tLabel.TextXAlignment = Enum.TextXAlignment.Left
        tLabel.Parent = card

        local dLabel = Instance.new("TextLabel")
        dLabel.Name = "Desc"
        dLabel.Size = UDim2.new(1, -20, 0, 24)
        dLabel.Position = UDim2.new(0, 12, 0, 26)
        dLabel.BackgroundTransparency = 1
        dLabel.Font = Enum.Font.Gotham
        dLabel.Text = nDesc
        dLabel.TextColor3 = DEFAULT_THEME.TextSecondary
        dLabel.TextSize = 11
        dLabel.TextWrapped = true
        dLabel.TextXAlignment = Enum.TextXAlignment.Left
        dLabel.Parent = card

        local pBar = Instance.new("Frame")
        pBar.Name = "ProgressBar"
        pBar.Size = UDim2.new(1, 0, 0, 2)
        pBar.Position = UDim2.new(0, 0, 1, -2)
        pBar.BackgroundColor3 = primaryTheme
        pBar.BorderSizePixel = 0
        pBar.Parent = card

        -- Slide in
        card.BackgroundTransparency = 1
        tLabel.TextTransparency = 1
        dLabel.TextTransparency = 1
        accentBar.BackgroundTransparency = 1
        pBar.BackgroundTransparency = 1

        tween(card, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0})
        tween(tLabel, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0})
        tween(dLabel, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0})
        tween(accentBar, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0})
        tween(pBar, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0})

        -- Deplete progress
        tween(pBar, TweenInfo.new(nDur, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 0, 2)})

        task.delay(nDur, function()
            if card and card.Parent then
                local twOut = tween(card, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                    BackgroundTransparency = 1
                })
                tween(tLabel, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {TextTransparency = 1})
                tween(dLabel, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {TextTransparency = 1})
                tween(accentBar, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {BackgroundTransparency = 1})
                tween(pBar, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {BackgroundTransparency = 1})
                twOut.Completed:Connect(function()
                    pcall(function() card:Destroy() end)
                end)
            end
        end)
    end

    -- =========================================================================
    -- Tab & Page Registry
    -- =========================================================================
    local tabs = {}
    local activeTab = nil
    local featureStoppers = {}

    local function selectTab(tabRecord)
        if activeTab == tabRecord then return end
        activeTab = tabRecord

        breadcrumbTitle.Text = tabRecord.Name

        for _, t in ipairs(tabs) do
            local isCurrent = (t == tabRecord)
            t.Page.Visible = isCurrent
            if isCurrent then
                t.Page.Position = UDim2.new(0, 0, 0, 4)
                tween(t.Page, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0)})
                tween(t.Button, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {BackgroundColor3 = DEFAULT_THEME.Card, BackgroundTransparency = 0})
                tween(t.Title, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {TextColor3 = DEFAULT_THEME.TextPrimary})
                tween(t.Icon, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {TextColor3 = primaryTheme})
                t.Indicator.Visible = true
                tween(t.Indicator, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {BackgroundTransparency = 0})
            else
                tween(t.Button, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {BackgroundColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 1})
                tween(t.Title, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {TextColor3 = DEFAULT_THEME.TextSecondary})
                tween(t.Icon, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {TextColor3 = DEFAULT_THEME.TextDim})
                t.Indicator.Visible = false
            end
        end
    end

    -- Forward declarations of component builders
    local createToggle, createSlider, createDropdown, createMultiDropdown, createButton, createTextBox, createSection, createList, createColorPicker

    -- Tab Builder (Completely Rounded & Glitch-Free)
    local function createTab(tabName, tabOpts)
        tabOpts = tabOpts or {}
        local tabIcon = tabOpts.Icon or "✦"

        -- Sidebar Tab Button
        local tabBtn = Instance.new("TextButton")
        tabBtn.Name = "Tab_" .. tostring(tabName)
        tabBtn.Size = UDim2.new(1, 0, 0, 36)
        tabBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        tabBtn.BackgroundTransparency = 1
        tabBtn.BorderSizePixel = 0
        tabBtn.Text = ""
        tabBtn.AutoButtonColor = false
        tabBtn.Parent = tabScroll
        applyCorner(tabBtn, 8)

        -- Set LayoutOrder so Settings can be pinned to the bottom
        tabBtn.LayoutOrder = (tabName == "Settings") and 9999 or #tabs
        local iconLbl = Instance.new("TextLabel")
        iconLbl.Name = "Icon"
        iconLbl.Size = UDim2.new(0, 22, 1, 0)
        iconLbl.Position = UDim2.new(0, 10, 0, 0)
        iconLbl.BackgroundTransparency = 1
        iconLbl.Font = Enum.Font.GothamBold
        iconLbl.Text = tabIcon
        iconLbl.TextColor3 = DEFAULT_THEME.TextDim
        iconLbl.TextSize = 13
        iconLbl.TextXAlignment = Enum.TextXAlignment.Center
        iconLbl.Parent = tabBtn

        -- Title Label
        local tabTitle = Instance.new("TextLabel")
        tabTitle.Name = "Title"
        tabTitle.Size = UDim2.new(1, -40, 1, 0)
        tabTitle.Position = UDim2.new(0, 36, 0, 0)
        tabTitle.BackgroundTransparency = 1
        tabTitle.Font = Enum.Font.Gotham
        tabTitle.Text = tostring(tabName)
        tabTitle.TextColor3 = DEFAULT_THEME.TextSecondary
        tabTitle.TextSize = 12
        tabTitle.TextXAlignment = Enum.TextXAlignment.Left
        tabTitle.TextTruncate = Enum.TextTruncate.AtEnd
        tabTitle.Parent = tabBtn

        -- Active Indicator Pill
        local activeIndicator = Instance.new("Frame")
        activeIndicator.Name = "Indicator"
        activeIndicator.Size = UDim2.new(0, 3, 0, 18)
        activeIndicator.Position = UDim2.new(0, 2, 0.5, -9)
        activeIndicator.BackgroundColor3 = primaryTheme
        activeIndicator.BorderSizePixel = 0
        activeIndicator.Visible = false
        activeIndicator.Parent = tabBtn
        applyCorner(activeIndicator, 2)

        registerThemeUpdater(function(c)
            activeIndicator.BackgroundColor3 = c
            if activeTab and activeTab.Button == tabBtn then
                iconLbl.TextColor3 = c
            end
        end)

        -- Page Scrolling Container
        local pageScroll = Instance.new("ScrollingFrame")
        pageScroll.Name = "Page_" .. tostring(tabName)
        pageScroll.Size = UDim2.new(1, 0, 1, 0)
        pageScroll.Position = UDim2.new(0, 0, 0, 0)
        pageScroll.BackgroundTransparency = 1
        pageScroll.BorderSizePixel = 0
        pageScroll.ScrollBarThickness = 3
        pageScroll.ScrollBarImageColor3 = Color3.fromRGB(50, 60, 78)
        pageScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        pageScroll.Visible = false
        pageScroll.Parent = contentArea

        local pageLayout = Instance.new("UIListLayout")
        pageLayout.FillDirection = Enum.FillDirection.Vertical
        pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        pageLayout.Padding = UDim.new(0, 8)
        pageLayout.Parent = pageScroll

        local pagePadding = Instance.new("UIPadding")
        pagePadding.PaddingLeft = UDim.new(0, 16)
        pagePadding.PaddingRight = UDim.new(0, 16)
        pagePadding.PaddingTop = UDim.new(0, 14)
        pagePadding.PaddingBottom = UDim.new(0, 14)
        pagePadding.Parent = pageScroll

        local tabRecord = {
            Name = tabName,
            Button = tabBtn,
            Icon = iconLbl,
            Title = tabTitle,
            Indicator = activeIndicator,
            Page = pageScroll
        }
        table.insert(tabs, tabRecord)

        tabBtn.MouseEnter:Connect(function()
            if activeTab ~= tabRecord then
                tween(tabBtn, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {BackgroundColor3 = DEFAULT_THEME.CardHover, BackgroundTransparency = 0.5})
                tween(tabTitle, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {TextColor3 = DEFAULT_THEME.TextPrimary})
            end
        end)
        tabBtn.MouseLeave:Connect(function()
            if activeTab ~= tabRecord then
                tween(tabBtn, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {BackgroundTransparency = 1})
                tween(tabTitle, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {TextColor3 = DEFAULT_THEME.TextSecondary})
            end
        end)
        tabBtn.MouseButton1Click:Connect(function()
            selectTab(tabRecord)
        end)

        -- Auto-select the first tab
        if #tabs == 1 then
            selectTab(tabRecord)
        end

        local tabObj = {}
        tabObj.Page = pageScroll
        tabObj.Record = tabRecord
        tabObj.Name = tabName
        tabObj.Button = tabBtn
        tabObj.Icon = iconLbl
        tabObj.Title = tabTitle
        tabObj.Indicator = activeIndicator

        tabObj.CreateSection = function(self, title)
            local t = (type(self) == "string" and self) or title
            return createSection(pageScroll, t)
        end
        tabObj.createSection = tabObj.CreateSection
        tabObj.addSection = tabObj.CreateSection

        tabObj.CreateToggle = function(self, ...)
            local a = { ... }
            if type(self) == "string" then table.insert(a, 1, self) end
            return createToggle(pageScroll, unpack(a))
        end
        tabObj.createToggle = tabObj.CreateToggle

        tabObj.CreateSlider = function(self, ...)
            local a = { ... }
            if type(self) == "string" then table.insert(a, 1, self) end
            return createSlider(pageScroll, unpack(a))
        end
        tabObj.createSlider = tabObj.CreateSlider

        tabObj.CreateDropdown = function(self, ...)
            local a = { ... }
            if type(self) == "string" then table.insert(a, 1, self) end
            return createDropdown(pageScroll, unpack(a))
        end
        tabObj.createDropdown = tabObj.CreateDropdown

        tabObj.CreateMultiDropdown = function(self, ...)
            local a = { ... }
            if type(self) == "string" then table.insert(a, 1, self) end
            return createMultiDropdown(pageScroll, unpack(a))
        end
        tabObj.createMultiDropdown = tabObj.CreateMultiDropdown

        tabObj.CreateButton = function(self, ...)
            local a = { ... }
            if type(self) == "string" then table.insert(a, 1, self) end
            return createButton(pageScroll, unpack(a))
        end
        tabObj.createButton = tabObj.CreateButton

        tabObj.CreateTextBox = function(self, ...)
            local a = { ... }
            if type(self) == "string" then table.insert(a, 1, self) end
            return createTextBox(pageScroll, unpack(a))
        end
        tabObj.createTextBox = tabObj.CreateTextBox
        tabObj.CreateInput = tabObj.CreateTextBox
        tabObj.createInput = tabObj.CreateTextBox

        tabObj.CreateColorPicker = function(self, ...)
            local a = { ... }
            if type(self) == "string" then table.insert(a, 1, self) end
            return createColorPicker(pageScroll, unpack(a))
        end
        tabObj.createColorPicker = tabObj.CreateColorPicker
        tabObj.CreateColorpicker = tabObj.CreateColorPicker
        tabObj.createColorpicker = tabObj.CreateColorPicker

        tabObj.CreateList = function(self, ...)
            local a = { ... }
            if type(self) == "string" then table.insert(a, 1, self) end
            return createList(pageScroll, unpack(a))
        end
        tabObj.createList = tabObj.CreateList

        tabObj.CreateStatRow = function(self, ...)
            local a = { ... }
            if type(self) == "string" or type(self) == "table" then table.insert(a, 1, self) end
            return createStatRow(pageScroll, unpack(a))
        end
        tabObj.createStatRow = tabObj.CreateStatRow

        setmetatable(tabObj, {
            __index = function(_, k)
                return pageScroll[k]
            end,
            __newindex = function(_, k, v)
                pageScroll[k] = v
            end
        })

        return tabObj
    end

    -- =========================================================================
    -- Component 1: Section Header (Blox Fruits MMORPG Banner Style)
    -- =========================================================================
    createSection = function(parent, titleText)
        if typeof(parent) == "table" and parent.Page then parent = parent.Page end
        if typeof(parent) == "string" then
            titleText = parent
            parent = activeTab and activeTab.Page or nil
        end

        local container = Instance.new("Frame")
        container.Name = "Section_" .. tostring(titleText)
        container.Size = UDim2.new(1, 0, 0, 26)
        container.BackgroundTransparency = 1
        container.Parent = parent

        table.insert(registeredSections, { Container = container, Title = tostring(titleText), Parent = parent })

        local titleLabel = Instance.new("TextLabel")
        titleLabel.Name = "Title"
        titleLabel.Size = UDim2.new(0, 0, 1, 0)
        titleLabel.AutomaticSize = Enum.AutomaticSize.X
        titleLabel.BackgroundTransparency = 1
        titleLabel.Font = Enum.Font.GothamBold
        titleLabel.Text = "◆  " .. string.upper(tostring(titleText or ""))
        titleLabel.TextColor3 = primaryTheme
        titleLabel.TextSize = 11
        titleLabel.TextStrokeTransparency = 0.7
        titleLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.Parent = container

        registerThemeUpdater(function(c) titleLabel.TextColor3 = c end)

        local rule = Instance.new("Frame")
        rule.Name = "Divider"
        rule.Size = UDim2.new(1, -12, 0, 1)
        rule.Position = UDim2.new(0, 6, 0.5, 0)
        rule.BackgroundColor3 = DEFAULT_THEME.Stroke
        rule.BorderSizePixel = 0
        rule.Parent = container

        local ruleGrad = Instance.new("UIGradient")
        ruleGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, primaryTheme),
            ColorSequenceKeypoint.new(0.35, DEFAULT_THEME.Stroke),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 18, 25))
        })
        ruleGrad.Parent = rule

        titleLabel:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
            local width = titleLabel.AbsoluteSize.X
            rule.Position = UDim2.new(0, width + 10, 0.5, 0)
            rule.Size = UDim2.new(1, -(width + 10), 0, 1)
        end)

        return container
    end

    -- =========================================================================
    -- Component 2: Blox Fruits Styled Toggle Switch (Dual-stop Row Card & Badges)
    -- =========================================================================
    createToggle = function(parent, titleText, defaultState, callback)
        if typeof(parent) == "table" and parent.Page then parent = parent.Page end
        if typeof(parent) == "string" then
            callback = defaultState
            defaultState = titleText
            titleText = parent
            parent = activeTab and activeTab.Page or nil
        end
        local state = defaultState == true
        local cb = type(callback) == "function" and callback or function() end
        local setToggle

        local iconChar, titleColor = getCategoryStyle(titleText)

        local card = Instance.new("Frame")
        card.Name = "ToggleCard_" .. tostring(titleText)
        card.Size = UDim2.new(1, 0, 0, 42)
        card.BackgroundColor3 = DEFAULT_THEME.Card
        card.BorderSizePixel = 0
        card.Parent = parent
        applyCorner(card, 8)
        applyCardGradient(card)
        local stroke = applyStroke(card, DEFAULT_THEME.Stroke, 1, 0.2)

        table.insert(registeredElements, { Card = card, Title = tostring(titleText), Type = "Toggle" })
        registeredFlags[tostring(titleText)] = {
            Type = "Toggle",
            Get = function() return state end,
            Set = function(newVal)
                if state ~= newVal then
                    setToggle(newVal)
                end
            end
        }

        -- Left Icon Badge Container (Blox Fruits Stat Style)
        local iconBox = Instance.new("Frame")
        iconBox.Name = "IconBox"
        iconBox.Size = UDim2.new(0, 26, 0, 26)
        iconBox.Position = UDim2.new(0, 8, 0.5, -13)
        iconBox.BackgroundColor3 = Color3.fromRGB(13, 12, 16)
        iconBox.BorderSizePixel = 0
        iconBox.Parent = card
        applyCorner(iconBox, 6)
        applyStroke(iconBox, DEFAULT_THEME.Stroke, 1, 0.3)

        local iconLbl = Instance.new("TextLabel")
        iconLbl.Name = "Icon"
        iconLbl.Size = UDim2.new(1, 0, 1, 0)
        iconLbl.BackgroundTransparency = 1
        iconLbl.Font = Enum.Font.GothamBold
        iconLbl.Text = iconChar
        iconLbl.TextColor3 = titleColor
        iconLbl.TextSize = 14
        iconLbl.Parent = iconBox

        local titleLabel = Instance.new("TextLabel")
        titleLabel.Name = "Label"
        titleLabel.Size = UDim2.new(1, -98, 1, 0)
        titleLabel.Position = UDim2.new(0, 42, 0, 0)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Font = Enum.Font.GothamBold
        titleLabel.Text = tostring(titleText)
        titleLabel.TextColor3 = titleColor
        titleLabel.TextSize = 12
        titleLabel.TextStrokeTransparency = 0.75
        titleLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
        titleLabel.Parent = card

        -- Switch Track
        local switchTrack = Instance.new("TextButton")
        switchTrack.Name = "SwitchTrack"
        switchTrack.Size = UDim2.new(0, 38, 0, 20)
        switchTrack.Position = UDim2.new(1, -48, 0.5, -10)
        switchTrack.BackgroundColor3 = state and primaryTheme or Color3.fromRGB(32, 29, 38)
        switchTrack.BorderSizePixel = 0
        switchTrack.Text = ""
        switchTrack.AutoButtonColor = false
        switchTrack.Parent = card
        applyCorner(switchTrack, 10)
        applyStroke(switchTrack, state and primaryTheme or DEFAULT_THEME.Stroke, 1, 0.3)

        local switchKnob = Instance.new("Frame")
        switchKnob.Name = "Knob"
        switchKnob.Size = UDim2.new(0, 14, 0, 14)
        switchKnob.Position = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
        switchKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        switchKnob.BorderSizePixel = 0
        switchKnob.Parent = switchTrack
        applyCorner(switchKnob, 7)

        registerThemeUpdater(function(c)
            if state then switchTrack.BackgroundColor3 = c end
        end)

        local function updateVisuals()
            if state then
                tween(switchTrack, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    BackgroundColor3 = primaryTheme
                })
                tween(switchKnob, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Position = UDim2.new(1, -17, 0.5, -7)
                })
            else
                tween(switchTrack, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    BackgroundColor3 = Color3.fromRGB(32, 29, 38)
                })
                tween(switchKnob, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Position = UDim2.new(0, 3, 0.5, -7)
                })
            end
        end

        setToggle = function(val)
            state = (val == true)
            updateVisuals()
            pcall(cb, state)
        end

        table.insert(featureStoppers, function()
            if state == true then
                setToggle(false)
            end
        end)

        -- Trigger on whole card click
        local hitTrigger = Instance.new("TextButton")
        hitTrigger.Name = "Hitbox"
        hitTrigger.Size = UDim2.new(1, 0, 1, 0)
        hitTrigger.BackgroundTransparency = 1
        hitTrigger.Text = ""
        hitTrigger.Parent = card

        hitTrigger.MouseEnter:Connect(function()
            tween(card, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {BackgroundColor3 = DEFAULT_THEME.CardHover})
        end)
        hitTrigger.MouseLeave:Connect(function()
            tween(card, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {BackgroundColor3 = DEFAULT_THEME.Card})
        end)
        hitTrigger.MouseButton1Click:Connect(function()
            setToggle(not state)
        end)

        local toggleObj = {
            Instance = card,
            Value = state,
            Set = setToggle,
            SetValue = setToggle
        }
        return toggleObj
    end

    -- =========================================================================
    -- Component 3: Blox Fruits Precision Slider (Elevated Stat Badge Display)
    -- =========================================================================
    createSlider = function(parent, titleText, minVal, maxVal, defaultVal, suffixText, callback)
        if typeof(parent) == "table" and parent.Page then parent = parent.Page end
        if typeof(parent) == "string" then
            callback = suffixText
            suffixText = defaultVal
            defaultVal = maxVal
            maxVal = minVal
            minVal = tonumber(titleText) or 0
            titleText = parent
            parent = activeTab and activeTab.Page or nil
        end
        if type(suffixText) == "function" and callback == nil then
            callback = suffixText
            suffixText = ""
        end
        minVal = tonumber(minVal) or 0
        maxVal = tonumber(maxVal) or 100
        defaultVal = tonumber(defaultVal) or minVal
        local suffix = tostring(suffixText or "")
        local cb = type(callback) == "function" and callback or function() end

        local currentValue = math.clamp(defaultVal, minVal, maxVal)
        local iconChar, titleColor = getCategoryStyle(titleText)

        local card = Instance.new("Frame")
        card.Name = "SliderCard_" .. tostring(titleText)
        card.Size = UDim2.new(1, 0, 0, 54)
        card.BackgroundColor3 = DEFAULT_THEME.Card
        card.BorderSizePixel = 0
        card.Parent = parent
        applyCorner(card, 8)
        applyCardGradient(card)
        applyStroke(card, DEFAULT_THEME.Stroke, 1, 0.2)

        table.insert(registeredElements, { Card = card, Title = tostring(titleText), Type = "Slider" })

        -- Left Icon Badge Container
        local iconBox = Instance.new("Frame")
        iconBox.Name = "IconBox"
        iconBox.Size = UDim2.new(0, 24, 0, 24)
        iconBox.Position = UDim2.new(0, 8, 0, 6)
        iconBox.BackgroundColor3 = Color3.fromRGB(13, 12, 16)
        iconBox.BorderSizePixel = 0
        iconBox.Parent = card
        applyCorner(iconBox, 6)
        applyStroke(iconBox, DEFAULT_THEME.Stroke, 1, 0.3)

        local iconLbl = Instance.new("TextLabel")
        iconLbl.Name = "Icon"
        iconLbl.Size = UDim2.new(1, 0, 1, 0)
        iconLbl.BackgroundTransparency = 1
        iconLbl.Font = Enum.Font.GothamBold
        iconLbl.Text = iconChar
        iconLbl.TextColor3 = titleColor
        iconLbl.TextSize = 13
        iconLbl.Parent = iconBox

        -- Title Label
        local titleLabel = Instance.new("TextLabel")
        titleLabel.Name = "Label"
        titleLabel.Size = UDim2.new(1, -125, 0, 24)
        titleLabel.Position = UDim2.new(0, 38, 0, 6)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Font = Enum.Font.GothamBold
        titleLabel.Text = tostring(titleText)
        titleLabel.TextColor3 = titleColor
        titleLabel.TextSize = 12
        titleLabel.TextStrokeTransparency = 0.75
        titleLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
        titleLabel.Parent = card

        -- Value badge on right (Styled like Blox Fruits Stat Level Display)
        local valContainer = Instance.new("Frame")
        valContainer.Name = "ValContainer"
        valContainer.Size = UDim2.new(0, 72, 0, 22)
        valContainer.Position = UDim2.new(1, -82, 0, 7)
        valContainer.BackgroundColor3 = Color3.fromRGB(13, 12, 16)
        valContainer.BorderSizePixel = 0
        valContainer.Parent = card
        applyCorner(valContainer, 5)
        applyStroke(valContainer, DEFAULT_THEME.Stroke, 1, 0.3)

        local valBadge = Instance.new("TextLabel")
        valBadge.Name = "ValueBadge"
        valBadge.Size = UDim2.new(1, 0, 1, 0)
        valBadge.BackgroundTransparency = 1
        valBadge.Font = Enum.Font.GothamBold
        valBadge.Text = tostring(currentValue) .. suffix
        valBadge.TextColor3 = primaryTheme
        valBadge.TextSize = 11
        valBadge.TextStrokeTransparency = 0.8
        valBadge.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        valBadge.TextXAlignment = Enum.TextXAlignment.Center
        valBadge.Parent = valContainer

        -- Track
        local track = Instance.new("TextButton")
        track.Name = "SliderTrack"
        track.Size = UDim2.new(1, -24, 0, 6)
        track.Position = UDim2.new(0, 12, 0, 38)
        track.BackgroundColor3 = Color3.fromRGB(28, 25, 33)
        track.BorderSizePixel = 0
        track.Text = ""
        track.AutoButtonColor = false
        track.Parent = card
        applyCorner(track, 3)

        local fill = Instance.new("Frame")
        fill.Name = "Fill"
        fill.Size = UDim2.new(0, 0, 1, 0)
        fill.BackgroundColor3 = primaryTheme
        fill.BorderSizePixel = 0
        fill.Parent = track
        applyCorner(fill, 3)

        local fillGrad = Instance.new("UIGradient")
        fillGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, DEFAULT_THEME.GoldTop),
            ColorSequenceKeypoint.new(1, primaryTheme)
        })
        fillGrad.Parent = fill

        local thumb = Instance.new("Frame")
        thumb.Name = "Thumb"
        thumb.Size = UDim2.new(0, 14, 0, 14)
        thumb.Position = UDim2.new(0, -7, 0.5, -7)
        thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        thumb.BorderSizePixel = 0
        thumb.Parent = fill
        applyCorner(thumb, 7)
        applyStroke(thumb, primaryTheme, 1.5, 0)

        registerThemeUpdater(function(c)
            fill.BackgroundColor3 = c
            valBadge.TextColor3 = c
        end)

        local function updateSlider(alpha, skipCallback)
            alpha = math.clamp(alpha, 0, 1)
            local range = maxVal - minVal
            local rawVal = minVal + (alpha * range)

            if range <= 20 and range ~= math.floor(range) then
                currentValue = math.floor(rawVal * 10 + 0.5) / 10
            else
                currentValue = math.floor(rawVal + 0.5)
            end

            local pct = (currentValue - minVal) / (maxVal - minVal)
            fill.Size = UDim2.new(pct, 0, 1, 0)
            thumb.Position = UDim2.new(1, -7, 0.5, -7)
            valBadge.Text = tostring(currentValue) .. suffix

            if not skipCallback then
                pcall(cb, currentValue)
            end
        end

        local initialAlpha = (defaultVal - minVal) / (maxVal - minVal)
        updateSlider(initialAlpha, true)

        -- Drag Handling
        local dragging = false
        track.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                local trackX = track.AbsolutePosition.X
                local trackW = track.AbsoluteSize.X
                local alpha = (input.Position.X - trackX) / trackW
                updateSlider(alpha, false)
            end
        end)

        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local trackX = track.AbsolutePosition.X
                local trackW = track.AbsoluteSize.X
                local alpha = (input.Position.X - trackX) / trackW
                updateSlider(alpha, false)
            end
        end)

        local sliderObj = {
            Instance = card,
            Value = currentValue,
            Set = function(val)
                local a = (tonumber(val or minVal) - minVal) / (maxVal - minVal)
                updateSlider(a, false)
            end
        }
        return sliderObj
    end

    -- =========================================================================
    -- Component 4: Blox Fruits Golden Action Button (The Iconic +1 Bevel Aesthetic)
    -- =========================================================================
    createButton = function(parent, titleText, callback, opts)
        if typeof(parent) == "table" and parent.Page then parent = parent.Page end
        if typeof(parent) == "string" then
            callback = titleText
            titleText = parent
            parent = activeTab and activeTab.Page or nil
        end
        opts = opts or {}
        local cb = type(callback) == "function" and callback or function() end

        local iconChar, titleColor = getCategoryStyle(titleText)
        local isGold = opts.Gold ~= false and opts.style ~= "dark"

        local card = Instance.new("TextButton")
        card.Name = "ButtonCard_" .. tostring(titleText)
        card.Size = UDim2.new(1, 0, 0, 38)
        card.BorderSizePixel = 0
        card.Font = Enum.Font.GothamBold
        card.Text = ""
        card.AutoButtonColor = false
        card.Parent = parent
        applyCorner(card, 8)

        local stroke
        local btnGrad
        if isGold then
            -- Iconic Blox Fruits Golden Bevel Action Button
            card.BackgroundColor3 = DEFAULT_THEME.GoldBottom
            stroke = applyStroke(card, DEFAULT_THEME.GoldStroke, 1.5, 0)
            btnGrad = Instance.new("UIGradient")
            btnGrad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, DEFAULT_THEME.GoldTop),
                ColorSequenceKeypoint.new(1, DEFAULT_THEME.GoldBottom)
            })
            btnGrad.Rotation = 90
            btnGrad.Parent = card
        else
            card.BackgroundColor3 = DEFAULT_THEME.Card
            applyCardGradient(card)
            stroke = applyStroke(card, DEFAULT_THEME.Stroke, 1, 0.2)
        end

        table.insert(registeredElements, { Card = card, Title = tostring(titleText), Type = "Button" })

        -- Content row
        local iconLbl = Instance.new("TextLabel")
        iconLbl.Name = "BtnIcon"
        iconLbl.Size = UDim2.new(0, 24, 1, 0)
        iconLbl.Position = UDim2.new(0, 12, 0, 0)
        iconLbl.BackgroundTransparency = 1
        iconLbl.Font = Enum.Font.GothamBold
        iconLbl.Text = opts.Icon or iconChar
        iconLbl.TextColor3 = isGold and DEFAULT_THEME.GoldText or titleColor
        iconLbl.TextSize = 14
        iconLbl.Parent = card

        local label = Instance.new("TextLabel")
        label.Name = "BtnLabel"
        label.Size = UDim2.new(1, -44, 1, 0)
        label.Position = UDim2.new(0, 36, 0, 0)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.GothamBold
        label.Text = tostring(titleText)
        label.TextColor3 = isGold and DEFAULT_THEME.GoldText or DEFAULT_THEME.TextPrimary
        label.TextSize = 13
        label.TextStrokeTransparency = isGold and 0.9 or 0.75
        label.TextStrokeColor3 = isGold and Color3.fromRGB(255, 230, 100) or Color3.fromRGB(0, 0, 0)
        label.TextXAlignment = Enum.TextXAlignment.Center
        label.TextTruncate = Enum.TextTruncate.AtEnd
        label.Parent = card

        card.MouseEnter:Connect(function()
            if isGold then
                tween(card, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {BackgroundColor3 = Color3.fromRGB(255, 225, 45)})
            else
                tween(card, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {BackgroundColor3 = DEFAULT_THEME.CardHover})
            end
        end)
        card.MouseLeave:Connect(function()
            if isGold then
                tween(card, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {BackgroundColor3 = DEFAULT_THEME.GoldBottom})
            else
                tween(card, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {BackgroundColor3 = DEFAULT_THEME.Card})
            end
        end)
        card.MouseButton1Down:Connect(function()
            tween(card, TweenInfo.new(0.06, Enum.EasingStyle.Quad), {Position = card.Position + UDim2.new(0, 0, 0, 2)})
        end)
        card.MouseButton1Up:Connect(function()
            tween(card, TweenInfo.new(0.08, Enum.EasingStyle.Quad), {Position = card.Position - UDim2.new(0, 0, 0, 2)})
        end)
        card.MouseButton1Click:Connect(function()
            pcall(cb)
        end)

        return card
    end

    -- =========================================================================
    -- Component 4B: Exact 1:1 Blox Fruits Stat Row Component
    -- =========================================================================
    createStatRow = function(parent, titleText, levelVal, subText, onAddCallback, isLocked, customIcon, customColor)
        if typeof(parent) == "table" and parent.Page then parent = parent.Page end
        if typeof(titleText) == "table" then
            local cfg = titleText
            customIcon = cfg.Icon
            customColor = cfg.TitleColor or cfg.Color
            isLocked = cfg.IsLocked or cfg.Locked
            onAddCallback = cfg.Callback or cfg.OnAction or cfg.OnClick
            subText = cfg.SubText or cfg.Mastery or ""
            levelVal = cfg.Level or cfg.Value or 1
            titleText = cfg.Title or cfg.Name or "Stat"
        end

        local iconChar, titleColor = getCategoryStyle(titleText)
        if customIcon then iconChar = customIcon end
        if customColor then titleColor = customColor end

        local card = Instance.new("Frame")
        card.Name = "StatRow_" .. tostring(titleText)
        card.Size = UDim2.new(1, 0, 0, 44)
        card.BackgroundColor3 = DEFAULT_THEME.Card
        card.BorderSizePixel = 0
        card.Parent = parent
        applyCorner(card, 8)
        applyCardGradient(card)
        applyStroke(card, DEFAULT_THEME.Stroke, 1, 0.2)

        -- Left Icon Badge Container
        local iconBox = Instance.new("Frame")
        iconBox.Name = "IconBox"
        iconBox.Size = UDim2.new(0, 28, 0, 28)
        iconBox.Position = UDim2.new(0, 8, 0.5, -14)
        iconBox.BackgroundColor3 = Color3.fromRGB(13, 12, 16)
        iconBox.BorderSizePixel = 0
        iconBox.Parent = card
        applyCorner(iconBox, 6)
        applyStroke(iconBox, DEFAULT_THEME.Stroke, 1, 0.3)

        local iconLbl = Instance.new("TextLabel")
        iconLbl.Name = "Icon"
        iconLbl.Size = UDim2.new(1, 0, 1, 0)
        iconLbl.BackgroundTransparency = 1
        iconLbl.Font = Enum.Font.GothamBold
        iconLbl.Text = iconChar
        iconLbl.TextColor3 = titleColor
        iconLbl.TextSize = 15
        iconLbl.Parent = iconBox

        -- Title Label
        local titleLabel = Instance.new("TextLabel")
        titleLabel.Name = "Label"
        titleLabel.Size = UDim2.new(0, 110, 1, 0)
        titleLabel.Position = UDim2.new(0, 44, 0, 0)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Font = Enum.Font.GothamBold
        titleLabel.Text = tostring(titleText)
        titleLabel.TextColor3 = titleColor
        titleLabel.TextSize = 13
        titleLabel.TextStrokeTransparency = 0.75
        titleLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.Parent = card

        -- Level & Mastery Text (Middle)
        local levelLabel = Instance.new("TextLabel")
        levelLabel.Name = "LevelLabel"
        levelLabel.Size = UDim2.new(1, -210, 1, 0)
        levelLabel.Position = UDim2.new(0, 150, 0, 0)
        levelLabel.BackgroundTransparency = 1
        levelLabel.Font = Enum.Font.Gotham
        local sub = (subText and subText ~= "") and (" (" .. tostring(subText) .. ")") or ""
        levelLabel.Text = "Lv. " .. tostring(levelVal or 1) .. sub
        levelLabel.TextColor3 = DEFAULT_THEME.TextPrimary
        levelLabel.TextSize = 12
        levelLabel.TextXAlignment = Enum.TextXAlignment.Right
        levelLabel.Parent = card

        -- Right Action (Golden +1 Button OR Lock Icon)
        local actionObj
        if isLocked then
            local lockLbl = Instance.new("TextLabel")
            lockLbl.Name = "LockIcon"
            lockLbl.Size = UDim2.new(0, 44, 0, 28)
            lockLbl.Position = UDim2.new(1, -52, 0.5, -14)
            lockLbl.BackgroundTransparency = 1
            lockLbl.Font = Enum.Font.GothamBold
            lockLbl.Text = "🔒"
            lockLbl.TextColor3 = DEFAULT_THEME.TextDim
            lockLbl.TextSize = 14
            lockLbl.Parent = card
            actionObj = lockLbl
        else
            local addBtn = Instance.new("TextButton")
            addBtn.Name = "AddButton"
            addBtn.Size = UDim2.new(0, 46, 0, 28)
            addBtn.Position = UDim2.new(1, -54, 0.5, -14)
            addBtn.BackgroundColor3 = DEFAULT_THEME.GoldBottom
            addBtn.BorderSizePixel = 0
            addBtn.Font = Enum.Font.GothamBold
            addBtn.Text = "+1"
            addBtn.TextColor3 = DEFAULT_THEME.GoldText
            addBtn.TextSize = 13
            addBtn.AutoButtonColor = false
            addBtn.Parent = card
            applyCorner(addBtn, 5)
            applyStroke(addBtn, DEFAULT_THEME.GoldStroke, 1.5, 0)

            local btnGrad = Instance.new("UIGradient")
            btnGrad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, DEFAULT_THEME.GoldTop),
                ColorSequenceKeypoint.new(1, DEFAULT_THEME.GoldBottom)
            })
            btnGrad.Rotation = 90
            btnGrad.Parent = addBtn

            addBtn.MouseEnter:Connect(function()
                tween(addBtn, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {BackgroundColor3 = Color3.fromRGB(255, 225, 45)})
            end)
            addBtn.MouseLeave:Connect(function()
                tween(addBtn, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {BackgroundColor3 = DEFAULT_THEME.GoldBottom})
            end)
            addBtn.MouseButton1Down:Connect(function()
                tween(addBtn, TweenInfo.new(0.06, Enum.EasingStyle.Quad), {Size = UDim2.new(0, 44, 0, 26), Position = UDim2.new(1, -53, 0.5, -13)})
            end)
            addBtn.MouseButton1Up:Connect(function()
                tween(addBtn, TweenInfo.new(0.08, Enum.EasingStyle.Quad), {Size = UDim2.new(0, 46, 0, 28), Position = UDim2.new(1, -54, 0.5, -14)})
            end)
            addBtn.MouseButton1Click:Connect(function()
                if type(onAddCallback) == "function" then
                    pcall(onAddCallback)
                end
            end)
            actionObj = addBtn
        end

        local rowObj = {
            Instance = card,
            SetLevel = function(newLv, newSub)
                levelVal = newLv or levelVal
                if newSub ~= nil then subText = newSub end
                local s = (subText and subText ~= "") and (" (" .. tostring(subText) .. ")") or ""
                levelLabel.Text = "Lv. " .. tostring(levelVal) .. s
            end,
            SetLocked = function(locked)
                isLocked = locked
            end
        }
        return rowObj
    end

    -- =========================================================================
    -- Component 5: Accordion Dropdown
    -- =========================================================================
    createDropdown = function(parent, titleText, optionsList, defaultChoice, callback)
        -- Table / TabObj parent unwrapping
        if typeof(parent) == "table" and parent.Page then
            parent = parent.Page
        end
        -- Omitted parent: called as createDropdown(title, options, default, cb)
        if typeof(parent) == "string" then
            callback = defaultChoice
            defaultChoice = optionsList
            optionsList = titleText
            titleText = parent
            parent = activeTab and activeTab.Page or nil
        end
        -- Dictionary argument: { Name = "...", Options = {...} }
        if typeof(titleText) == "table" then
            local cfg = titleText
            titleText = cfg.Name or cfg.Title or "Dropdown"
            optionsList = cfg.Options or cfg.options or {}
            defaultChoice = cfg.Default or cfg.default or cfg.CurrentOption or optionsList[1]
            callback = cfg.Callback or cfg.callback
        end

        local options = (type(optionsList) == "table" and optionsList) or {}
        local currentSelection = defaultChoice or options[1] or "None"
        local cb = type(callback) == "function" and callback or function() end
        local isExpanded = false
        local currentQuery = ""

        local card = Instance.new("Frame")
        card.Name = "DropdownCard_" .. tostring(titleText)
        card.Size = UDim2.new(1, 0, 0, 42)
        card.BackgroundColor3 = DEFAULT_THEME.Card
        card.BorderSizePixel = 0
        card.ClipsDescendants = true
        card.Parent = parent
        applyCorner(card, 8)
        applyStroke(card, DEFAULT_THEME.Stroke, 1, 0.3)

        table.insert(registeredElements, { Card = card, Title = tostring(titleText), Type = "Dropdown" })

        local headerBtn = Instance.new("TextButton")
        headerBtn.Name = "HeaderButton"
        headerBtn.Size = UDim2.new(1, 0, 0, 42)
        headerBtn.BackgroundTransparency = 1
        headerBtn.Text = ""
        headerBtn.Parent = card

        local titleLabel = Instance.new("TextLabel")
        titleLabel.Name = "Label"
        titleLabel.Size = UDim2.new(1, -170, 1, 0)
        titleLabel.Position = UDim2.new(0, 14, 0, 0)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Font = Enum.Font.Gotham
        titleLabel.Text = tostring(titleText)
        titleLabel.TextColor3 = DEFAULT_THEME.TextPrimary
        titleLabel.TextSize = 12
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
        titleLabel.Parent = headerBtn

        local selectionPill = Instance.new("TextLabel")
        selectionPill.Name = "Pill"
        selectionPill.Size = UDim2.new(0, 120, 0, 24)
        selectionPill.Position = UDim2.new(1, -158, 0.5, -12)
        selectionPill.BackgroundColor3 = Color3.fromRGB(18, 21, 28)
        selectionPill.BorderSizePixel = 0
        selectionPill.Font = Enum.Font.Gotham
        selectionPill.Text = tostring(currentSelection)
        selectionPill.TextColor3 = DEFAULT_THEME.TextSecondary
        selectionPill.TextSize = 11
        selectionPill.TextTruncate = Enum.TextTruncate.AtEnd
        selectionPill.Parent = headerBtn
        applyCorner(selectionPill, 6)

        local chevron = Instance.new("TextLabel")
        chevron.Name = "Chevron"
        chevron.Size = UDim2.new(0, 24, 0, 24)
        chevron.Position = UDim2.new(1, -34, 0.5, -12)
        chevron.BackgroundTransparency = 1
        chevron.Font = Enum.Font.GothamBold
        chevron.Text = "▾"
        chevron.TextColor3 = DEFAULT_THEME.TextSecondary
        chevron.TextSize = 14
        chevron.Parent = headerBtn

        -- Search Bar (Dynamic visibility)
        local searchBar = Instance.new("TextBox")
        searchBar.Name = "SearchBox"
        searchBar.Size = UDim2.new(1, -20, 0, 26)
        searchBar.Position = UDim2.new(0, 10, 0, 44)
        searchBar.BackgroundColor3 = Color3.fromRGB(18, 21, 28)
        searchBar.BorderSizePixel = 0
        searchBar.PlaceholderText = "Search..."
        searchBar.PlaceholderColor3 = Color3.fromRGB(110, 120, 140)
        searchBar.Text = ""
        searchBar.TextColor3 = DEFAULT_THEME.TextPrimary
        searchBar.Font = Enum.Font.Gotham
        searchBar.TextSize = 11
        searchBar.ClearTextOnFocus = false
        searchBar.Visible = false
        searchBar.Parent = card
        applyCorner(searchBar, 6)
        applyStroke(searchBar, DEFAULT_THEME.Stroke, 1, 0.3)

        local optionsContainer = Instance.new("ScrollingFrame")
        optionsContainer.Name = "OptionsList"
        optionsContainer.Size = UDim2.new(1, -20, 0, 150)
        optionsContainer.Position = UDim2.new(0, 10, 0, 44)
        optionsContainer.BackgroundTransparency = 1
        optionsContainer.BorderSizePixel = 0
        optionsContainer.ScrollBarThickness = 3
        optionsContainer.ScrollBarImageColor3 = Color3.fromRGB(60, 75, 105)
        optionsContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
        optionsContainer.Parent = card

        local optLayout = Instance.new("UIListLayout")
        optLayout.FillDirection = Enum.FillDirection.Vertical
        optLayout.Padding = UDim.new(0, 3)
        optLayout.Parent = optionsContainer

        local function getFilteredOptions(query)
            if not query or query == "" then return options end
            local filtered = {}
            local lowerQuery = string.lower(query)
            for _, opt in ipairs(options) do
                if string.find(string.lower(tostring(opt)), lowerQuery, 1, true) then
                    table.insert(filtered, opt)
                end
            end
            return filtered
        end

        local function rebuildOptions(query)
            for _, child in ipairs(optionsContainer:GetChildren()) do
                if child:IsA("TextButton") or child:IsA("TextLabel") then child:Destroy() end
            end

            local filtered = getFilteredOptions(query)
            if #filtered == 0 then
                local emptyLbl = Instance.new("TextLabel")
                emptyLbl.Name = "EmptyLabel"
                emptyLbl.Size = UDim2.new(1, 0, 0, 26)
                emptyLbl.BackgroundTransparency = 1
                emptyLbl.Font = Enum.Font.Gotham
                emptyLbl.Text = "No matching results"
                emptyLbl.TextColor3 = DEFAULT_THEME.TextSecondary
                emptyLbl.TextSize = 11
                emptyLbl.Parent = optionsContainer
                return 0
            end

            for _, opt in ipairs(filtered) do
                local optBtn = Instance.new("TextButton")
                local optLabel = (type(opt) == "table" and (opt.Display or opt.Name or opt.Title or opt.ExactName or opt.Text or opt.text or opt[1])) or tostring(opt)
                optBtn.Name = "Opt_" .. optLabel
                optBtn.Size = UDim2.new(1, 0, 0, 28)
                optBtn.BackgroundColor3 = (opt == currentSelection) and Color3.fromRGB(34, 40, 54) or Color3.fromRGB(18, 21, 28)
                optBtn.BorderSizePixel = 0
                optBtn.Font = Enum.Font.Gotham
                optBtn.Text = "   " .. optLabel
                optBtn.TextColor3 = (opt == currentSelection) and primaryTheme or DEFAULT_THEME.TextSecondary
                optBtn.TextSize = 11
                optBtn.TextXAlignment = Enum.TextXAlignment.Left
                optBtn.AutoButtonColor = false
                optBtn.Parent = optionsContainer
                applyCorner(optBtn, 6)

                optBtn.MouseEnter:Connect(function()
                    tween(optBtn, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {BackgroundColor3 = DEFAULT_THEME.CardHover, TextColor3 = DEFAULT_THEME.TextPrimary})
                end)
                optBtn.MouseLeave:Connect(function()
                    tween(optBtn, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {
                        BackgroundColor3 = (opt == currentSelection) and Color3.fromRGB(34, 40, 54) or Color3.fromRGB(18, 21, 28),
                        TextColor3 = (opt == currentSelection) and primaryTheme or DEFAULT_THEME.TextSecondary
                    })
                end)
                optBtn.MouseButton1Click:Connect(function()
                    currentSelection = opt
                    selectionPill.Text = tostring(opt)
                    pcall(cb, opt)
                    isExpanded = false
                    chevron.Text = "▾"
                    tween(card, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, 42)})
                end)
            end
            return #filtered
        end

        local function updateDropdownVisuals()
            local hasSearch = (#options >= 5)
            searchBar.Visible = isExpanded and hasSearch
            if hasSearch then
                optionsContainer.Position = UDim2.new(0, 10, 0, 76)
            else
                optionsContainer.Position = UDim2.new(0, 10, 0, 44)
            end

            local count = rebuildOptions(currentQuery)
            chevron.Text = isExpanded and "▴" or "▾"
            local targetH = 42
            if isExpanded then
                local scrollH = math.min(160, math.max(34, count * 31))
                optionsContainer.Size = UDim2.new(1, -20, 0, scrollH)
                targetH = (hasSearch and 76 or 44) + scrollH + 8
            end
            tween(card, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, targetH)})
        end

        searchBar:GetPropertyChangedSignal("Text"):Connect(function()
            currentQuery = searchBar.Text
            updateDropdownVisuals()
        end)

        rebuildOptions("")

        headerBtn.MouseButton1Click:Connect(function()
            isExpanded = not isExpanded
            currentQuery = ""
            searchBar.Text = ""
            updateDropdownVisuals()
        end)

        local dropdownObj = {
            Instance = card,
            Value = currentSelection,
            Set = function(val)
                currentSelection = val
                selectionPill.Text = tostring(val)
                pcall(cb, val)
            end,
            Refresh = function(selfOrOpts, maybeOpts)
                local newOpts = (type(selfOrOpts) == "table" and selfOrOpts.Instance and maybeOpts) or selfOrOpts or {}
                options = newOpts or {}
                currentQuery = ""
                if searchBar then searchBar.Text = "" end
                rebuildOptions("")
                if isExpanded then updateDropdownVisuals() end
            end
        }
        return dropdownObj
    end

    createMultiDropdown = function(parent, titleText, optionsList, defaultSelected, callback)
        if typeof(parent) == "table" and parent.Page then parent = parent.Page end
        if typeof(parent) == "string" then
            callback = defaultSelected
            defaultSelected = optionsList
            optionsList = titleText
            titleText = parent
            parent = activeTab and activeTab.Page or nil
        end
        local options = optionsList or {}
        local selected = {}
        if type(defaultSelected) == "table" then
            for k, v in pairs(defaultSelected) do
                if type(k) == "number" then selected[tostring(v)] = true
                elseif v == true then selected[tostring(k)] = true end
            end
        elseif defaultSelected then
            selected[tostring(defaultSelected)] = true
        end
        if next(selected) == nil and #options > 0 then
            selected["All"] = true
        end

        local cb = type(callback) == "function" and callback or function() end
        local isExpanded = false

        local card = Instance.new("Frame")
        card.Name = "MultiDropdownCard_" .. tostring(titleText)
        card.Size = UDim2.new(1, 0, 0, 42)
        card.BackgroundColor3 = DEFAULT_THEME.Card
        card.BorderSizePixel = 0
        card.ClipsDescendants = true
        card.Parent = parent
        applyCorner(card, 8)
        applyStroke(card, DEFAULT_THEME.Stroke, 1, 0.3)

        table.insert(registeredElements, { Card = card, Title = tostring(titleText), Type = "MultiDropdown" })

        local headerBtn = Instance.new("TextButton")
        headerBtn.Name = "HeaderButton"
        headerBtn.Size = UDim2.new(1, 0, 0, 42)
        headerBtn.BackgroundTransparency = 1
        headerBtn.Text = ""
        headerBtn.Parent = card

        local titleLabel = Instance.new("TextLabel")
        titleLabel.Name = "Label"
        titleLabel.Size = UDim2.new(1, -180, 1, 0)
        titleLabel.Position = UDim2.new(0, 14, 0, 0)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Font = Enum.Font.Gotham
        titleLabel.Text = tostring(titleText)
        titleLabel.TextColor3 = DEFAULT_THEME.TextPrimary
        titleLabel.TextSize = 12
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
        titleLabel.Parent = headerBtn

        local selectionPill = Instance.new("TextLabel")
        selectionPill.Name = "Pill"
        selectionPill.Size = UDim2.new(0, 130, 0, 24)
        selectionPill.Position = UDim2.new(1, -168, 0.5, -12)
        selectionPill.BackgroundColor3 = Color3.fromRGB(18, 21, 28)
        selectionPill.BorderSizePixel = 0
        selectionPill.Font = Enum.Font.Gotham
        selectionPill.Text = "All Bears"
        selectionPill.TextColor3 = DEFAULT_THEME.TextSecondary
        selectionPill.TextSize = 11
        selectionPill.TextTruncate = Enum.TextTruncate.AtEnd
        selectionPill.Parent = headerBtn
        applyCorner(selectionPill, 6)

        local chevron = Instance.new("TextLabel")
        chevron.Name = "Chevron"
        chevron.Size = UDim2.new(0, 24, 0, 24)
        chevron.Position = UDim2.new(1, -34, 0.5, -12)
        chevron.BackgroundTransparency = 1
        chevron.Font = Enum.Font.GothamBold
        chevron.Text = "▾"
        chevron.TextColor3 = DEFAULT_THEME.TextSecondary
        chevron.TextSize = 14
        chevron.Parent = headerBtn

        local optionsContainer = Instance.new("ScrollingFrame")
        optionsContainer.Name = "OptionsList"
        optionsContainer.Size = UDim2.new(1, -20, 0, 0)
        optionsContainer.Position = UDim2.new(0, 10, 0, 44)
        optionsContainer.BackgroundTransparency = 1
        optionsContainer.BorderSizePixel = 0
        optionsContainer.ScrollBarThickness = 3
        optionsContainer.ScrollBarImageColor3 = Color3.fromRGB(60, 75, 105)
        optionsContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
        optionsContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
        optionsContainer.Parent = card

        local optLayout = Instance.new("UIListLayout")
        optLayout.FillDirection = Enum.FillDirection.Vertical
        optLayout.Padding = UDim.new(0, 3)
        optLayout.Parent = optionsContainer

        local function updatePillText()
            if selected["All"] then
                selectionPill.Text = "All Bears"
                return
            end
            local count = 0
            local first = nil
            for k, v in pairs(selected) do
                if v then
                    count = count + 1
                    if not first then first = k end
                end
            end
            if count == 0 then
                selectionPill.Text = "None Selected"
            elseif count == 1 then
                selectionPill.Text = tostring(first)
            else
                selectionPill.Text = tostring(count) .. " Selected"
            end
        end

        local function refreshOptionVisuals()
            for _, child in ipairs(optionsContainer:GetChildren()) do
                if child:IsA("TextButton") and child.Name:sub(1, 4) == "Opt_" then
                    local optStr = child.Name:sub(5)
                    local isChecked = (selected[optStr] == true)
                    child.BackgroundColor3 = isChecked and Color3.fromRGB(34, 40, 54) or Color3.fromRGB(18, 21, 28)
                    child.Text = (isChecked and "  [✓] " or "  [  ] ") .. optStr
                    child.TextColor3 = isChecked and primaryTheme or DEFAULT_THEME.TextSecondary
                    child.Font = isChecked and Enum.Font.GothamBold or Enum.Font.Gotham
                end
            end
        end

        local function buildOptions()
            for _, child in ipairs(optionsContainer:GetChildren()) do
                if child:IsA("TextButton") then child:Destroy() end
            end

            for _, opt in ipairs(options) do
                local optStr = (type(opt) == "table" and (opt.Display or opt.Name or opt.Title or opt.ExactName or opt.Text or opt.text or opt[1])) or tostring(opt)
                local isChecked = (selected[optStr] == true)
                local optBtn = Instance.new("TextButton")
                optBtn.Name = "Opt_" .. optStr
                optBtn.Size = UDim2.new(1, -6, 0, 28)
                optBtn.BackgroundColor3 = isChecked and Color3.fromRGB(34, 40, 54) or Color3.fromRGB(18, 21, 28)
                optBtn.BorderSizePixel = 0
                optBtn.Font = isChecked and Enum.Font.GothamBold or Enum.Font.Gotham
                optBtn.Text = (isChecked and "  [✓] " or "  [  ] ") .. optStr
                optBtn.TextColor3 = isChecked and primaryTheme or DEFAULT_THEME.TextSecondary
                optBtn.TextSize = 11
                optBtn.TextXAlignment = Enum.TextXAlignment.Left
                optBtn.AutoButtonColor = false
                optBtn.Parent = optionsContainer
                applyCorner(optBtn, 6)

                optBtn.MouseButton1Click:Connect(function()
                    if optStr == "All" then
                        table.clear(selected)
                        selected["All"] = true
                    else
                        selected["All"] = nil
                        if selected[optStr] then
                            selected[optStr] = nil
                        else
                            selected[optStr] = true
                        end
                        local any = false
                        for _, v in pairs(selected) do if v then any = true break end end
                        if not any then selected["All"] = true end
                    end
                    updatePillText()
                    refreshOptionVisuals()
                    local arr = {}
                    for k, v in pairs(selected) do if v then table.insert(arr, k) end end
                    pcall(cb, selected, arr)
                end)
            end
        end
        buildOptions()
        updatePillText()

        headerBtn.MouseButton1Click:Connect(function()
            isExpanded = not isExpanded
            chevron.Text = isExpanded and "▴" or "▾"
            local maxScrollHeight = math.clamp(#options * 31, 30, 210)
            local targetH = isExpanded and (54 + maxScrollHeight) or 42
            optionsContainer.Size = UDim2.new(1, -20, 0, isExpanded and maxScrollHeight or 0)
            refreshOptionVisuals()
            tween(card, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, targetH)})
        end)

        return {
            Instance = card,
            Value = selected,
            Set = function(list)
                table.clear(selected)
                if type(list) == "table" then
                    for k, v in pairs(list) do
                        if type(k) == "number" then selected[tostring(v)] = true
                        elseif v == true then selected[tostring(k)] = true end
                    end
                elseif list then
                    selected[tostring(list)] = true
                end
                updatePillText()
                refreshOptionVisuals()
            end,
            Refresh = function(selfOrOpts, maybeOpts)
                local newOpts = (type(selfOrOpts) == "table" and selfOrOpts.Instance and maybeOpts) or selfOrOpts or {}
                options = newOpts or {}
                buildOptions()
                updatePillText()
            end
        }
    end

    -- =========================================================================
    -- Component 6: Full Custom RGB Palette & ColorPicker
    -- =========================================================================
    createColorPicker = function(parent, titleText, defaultColor, callback)
        if typeof(parent) == "table" and parent.Page then parent = parent.Page end
        if typeof(parent) == "string" then
            callback = defaultColor
            defaultColor = titleText
            titleText = parent
            parent = activeTab and activeTab.Page or nil
        end
        local curColor = defaultColor or primaryTheme
        local cb = type(callback) == "function" and callback or function() end
        local isExpanded = false

        local rVal = math.clamp(math.floor(curColor.R * 255), 0, 255)
        local gVal = math.clamp(math.floor(curColor.G * 255), 0, 255)
        local bVal = math.clamp(math.floor(curColor.B * 255), 0, 255)

        local card = Instance.new("Frame")
        card.Name = "ColorPickerCard_" .. tostring(titleText)
        card.Size = UDim2.new(1, 0, 0, 44)
        card.BackgroundColor3 = DEFAULT_THEME.Card
        card.BorderSizePixel = 0
        card.ClipsDescendants = true
        card.Parent = parent
        applyCorner(card, 8)
        applyStroke(card, DEFAULT_THEME.Stroke, 1, 0.3)

        table.insert(registeredElements, { Card = card, Title = tostring(titleText), Type = "ColorPicker" })

        local headerBtn = Instance.new("TextButton")
        headerBtn.Name = "Header"
        headerBtn.Size = UDim2.new(1, 0, 0, 44)
        headerBtn.BackgroundTransparency = 1
        headerBtn.Text = ""
        headerBtn.Parent = card

        local titleLabel = Instance.new("TextLabel")
        titleLabel.Name = "Label"
        titleLabel.Size = UDim2.new(0.5, 0, 1, 0)
        titleLabel.Position = UDim2.new(0, 14, 0, 0)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Font = Enum.Font.Gotham
        titleLabel.Text = tostring(titleText)
        titleLabel.TextColor3 = DEFAULT_THEME.TextPrimary
        titleLabel.TextSize = 12
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.Parent = headerBtn

        local hexBadge = Instance.new("TextLabel")
        hexBadge.Name = "HexBadge"
        hexBadge.Size = UDim2.new(0, 70, 0, 24)
        hexBadge.Position = UDim2.new(1, -112, 0.5, -12)
        hexBadge.BackgroundColor3 = Color3.fromRGB(18, 21, 28)
        hexBadge.BorderSizePixel = 0
        hexBadge.Font = Enum.Font.GothamMedium
        hexBadge.Text = colorToHex(curColor)
        hexBadge.TextColor3 = DEFAULT_THEME.TextSecondary
        hexBadge.TextSize = 11
        hexBadge.Parent = headerBtn
        applyCorner(hexBadge, 6)
        applyStroke(hexBadge, DEFAULT_THEME.Stroke, 1, 0.4)

        local swatch = Instance.new("Frame")
        swatch.Name = "ColorSwatch"
        swatch.Size = UDim2.new(0, 26, 0, 24)
        swatch.Position = UDim2.new(1, -38, 0.5, -12)
        swatch.BackgroundColor3 = curColor
        swatch.BorderSizePixel = 0
        swatch.Parent = headerBtn
        applyCorner(swatch, 6)
        local swatchStroke = applyStroke(swatch, Color3.fromRGB(255, 255, 255), 1, 0.6)

        -- Expanded Color Suite Body
        local colorBody = Instance.new("Frame")
        colorBody.Name = "ColorPickerBody"
        colorBody.Size = UDim2.new(1, -24, 0, 142)
        colorBody.Position = UDim2.new(0, 12, 0, 48)
        colorBody.BackgroundTransparency = 1
        colorBody.Parent = card

        -- Preset quick pills
        local presetRow = Instance.new("Frame")
        presetRow.Name = "PresetRow"
        presetRow.Size = UDim2.new(1, 0, 0, 22)
        presetRow.Position = UDim2.new(0, 0, 0, 0)
        presetRow.BackgroundTransparency = 1
        presetRow.Parent = colorBody

        local presetLayout = Instance.new("UIListLayout")
        presetLayout.FillDirection = Enum.FillDirection.Horizontal
        presetLayout.Padding = UDim.new(0, 6)
        presetLayout.Parent = presetRow

        local quickColors = {
            Color3.fromRGB(245, 142, 32), -- Amber
            Color3.fromRGB(0, 195, 245),  -- Cyan
            Color3.fromRGB(165, 95, 255), -- Violet
            Color3.fromRGB(45, 215, 135), -- Mint
            Color3.fromRGB(245, 65, 95),  -- Rose
            Color3.fromRGB(235, 240, 255),-- White
            Color3.fromRGB(255, 205, 50), -- Gold
            Color3.fromRGB(230, 45, 45)   -- Crimson
        }

        local updateAllRgbSliders

        for _, pc in ipairs(quickColors) do
            local pBtn = Instance.new("TextButton")
            pBtn.Name = "Preset"
            pBtn.Size = UDim2.new(0, 22, 0, 22)
            pBtn.BackgroundColor3 = pc
            pBtn.BorderSizePixel = 0
            pBtn.Text = ""
            pBtn.AutoButtonColor = false
            pBtn.Parent = presetRow
            applyCorner(pBtn, 5)
            applyStroke(pBtn, Color3.fromRGB(0, 0, 0), 1, 0.5)

            pBtn.MouseButton1Click:Connect(function()
                curColor = pc
                rVal = math.floor(pc.R * 255)
                gVal = math.floor(pc.G * 255)
                bVal = math.floor(pc.B * 255)
                swatch.BackgroundColor3 = curColor
                hexBadge.Text = colorToHex(curColor)
                if updateAllRgbSliders then updateAllRgbSliders() end
                pcall(cb, curColor)
            end)
        end

        -- RGB Slider Builder Helper
        local function makeChannelSlider(labelStr, initVal, yPos, accentColor, onUpdate)
            local sRow = Instance.new("Frame")
            sRow.Name = "Row_" .. labelStr
            sRow.Size = UDim2.new(1, 0, 0, 32)
            sRow.Position = UDim2.new(0, 0, 0, yPos)
            sRow.BackgroundTransparency = 1
            sRow.Parent = colorBody

            local sLbl = Instance.new("TextLabel")
            sLbl.Name = "Channel"
            sLbl.Size = UDim2.new(0, 20, 1, 0)
            sLbl.Position = UDim2.new(0, 2, 0, 0)
            sLbl.BackgroundTransparency = 1
            sLbl.Font = Enum.Font.GothamBold
            sLbl.Text = labelStr
            sLbl.TextColor3 = accentColor
            sLbl.TextSize = 11
            sLbl.Parent = sRow

            local numBadge = Instance.new("TextLabel")
            numBadge.Name = "Num"
            numBadge.Size = UDim2.new(0, 32, 1, 0)
            numBadge.Position = UDim2.new(1, -34, 0, 0)
            numBadge.BackgroundTransparency = 1
            numBadge.Font = Enum.Font.Gotham
            numBadge.Text = tostring(initVal)
            numBadge.TextColor3 = DEFAULT_THEME.TextSecondary
            numBadge.TextSize = 11
            numBadge.TextXAlignment = Enum.TextXAlignment.Right
            numBadge.Parent = sRow

            local track = Instance.new("TextButton")
            track.Name = "Track"
            track.Size = UDim2.new(1, -68, 0, 6)
            track.Position = UDim2.new(0, 26, 0.5, -3)
            track.BackgroundColor3 = Color3.fromRGB(34, 40, 52)
            track.BorderSizePixel = 0
            track.Text = ""
            track.AutoButtonColor = false
            track.Parent = sRow
            applyCorner(track, 3)

            local fill = Instance.new("Frame")
            fill.Name = "Fill"
            fill.Size = UDim2.new(initVal / 255, 0, 1, 0)
            fill.BackgroundColor3 = accentColor
            fill.BorderSizePixel = 0
            fill.Parent = track
            applyCorner(fill, 3)

            local thumb = Instance.new("Frame")
            thumb.Name = "Thumb"
            thumb.Size = UDim2.new(0, 12, 0, 12)
            thumb.Position = UDim2.new(1, -6, 0.5, -6)
            thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            thumb.BorderSizePixel = 0
            thumb.Parent = fill
            applyCorner(thumb, 6)

            local function setVal(v, skipCallback)
                v = math.clamp(math.floor(v + 0.5), 0, 255)
                numBadge.Text = tostring(v)
                fill.Size = UDim2.new(v / 255, 0, 1, 0)
                if not skipCallback then onUpdate(v) end
            end

            local isDragging = false
            track.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    isDragging = true
                    local alpha = (input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X
                    setVal(alpha * 255, false)
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    isDragging = false
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    local alpha = (input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X
                    setVal(alpha * 255, false)
                end
            end)

            return { Set = setVal }
        end

        local rSlider = makeChannelSlider("R", rVal, 28, Color3.fromRGB(245, 75, 75), function(v)
            rVal = v
            curColor = Color3.fromRGB(rVal, gVal, bVal)
            swatch.BackgroundColor3 = curColor
            hexBadge.Text = colorToHex(curColor)
            pcall(cb, curColor)
        end)

        local gSlider = makeChannelSlider("G", gVal, 64, Color3.fromRGB(60, 220, 120), function(v)
            gVal = v
            curColor = Color3.fromRGB(rVal, gVal, bVal)
            swatch.BackgroundColor3 = curColor
            hexBadge.Text = colorToHex(curColor)
            pcall(cb, curColor)
        end)

        local bSlider = makeChannelSlider("B", bVal, 100, Color3.fromRGB(65, 150, 255), function(v)
            bVal = v
            curColor = Color3.fromRGB(rVal, gVal, bVal)
            swatch.BackgroundColor3 = curColor
            hexBadge.Text = colorToHex(curColor)
            pcall(cb, curColor)
        end)

        updateAllRgbSliders = function()
            rSlider.Set(rVal, true)
            gSlider.Set(gVal, true)
            bSlider.Set(bVal, true)
        end

        headerBtn.MouseButton1Click:Connect(function()
            isExpanded = not isExpanded
            local targetH = isExpanded and 196 or 44
            tween(card, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, targetH)})
        end)

        local pickerObj = {
            Instance = card,
            Value = curColor,
            Set = function(c)
                curColor = c or curColor
                rVal = math.floor(curColor.R * 255)
                gVal = math.floor(curColor.G * 255)
                bVal = math.floor(curColor.B * 255)
                swatch.BackgroundColor3 = curColor
                hexBadge.Text = colorToHex(curColor)
                updateAllRgbSliders()
                pcall(cb, curColor)
            end
        }
        return pickerObj
    end

    -- =========================================================================
    -- Component 7: TextBox / Input Card
    -- =========================================================================
    createTextBox = function(parent, titleText, placeholderText, callback)
        if typeof(parent) == "table" and parent.Page then parent = parent.Page end
        if typeof(parent) == "string" then
            callback = placeholderText
            placeholderText = titleText
            titleText = parent
            parent = activeTab and activeTab.Page or nil
        end
        local cb = type(callback) == "function" and callback or function() end

        local card = Instance.new("Frame")
        card.Name = "InputCard_" .. tostring(titleText)
        card.Size = UDim2.new(1, 0, 0, 42)
        card.BackgroundColor3 = DEFAULT_THEME.Card
        card.BorderSizePixel = 0
        card.Parent = parent
        applyCorner(card, 8)
        applyStroke(card, DEFAULT_THEME.Stroke, 1, 0.3)

        table.insert(registeredElements, { Card = card, Title = tostring(titleText), Type = "TextBox" })

        local titleLabel = Instance.new("TextLabel")
        titleLabel.Name = "Label"
        titleLabel.Size = UDim2.new(1, -165, 1, 0)
        titleLabel.Position = UDim2.new(0, 14, 0, 0)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Font = Enum.Font.Gotham
        titleLabel.Text = tostring(titleText)
        titleLabel.TextColor3 = DEFAULT_THEME.TextPrimary
        titleLabel.TextSize = 12
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
        titleLabel.Parent = card

        local boxFrame = Instance.new("Frame")
        boxFrame.Name = "BoxFrame"
        boxFrame.Size = UDim2.new(0, 140, 0, 26)
        boxFrame.Position = UDim2.new(1, -154, 0.5, -13)
        boxFrame.BackgroundColor3 = Color3.fromRGB(16, 19, 26)
        boxFrame.BorderSizePixel = 0
        boxFrame.Parent = card
        applyCorner(boxFrame, 6)
        local boxStroke = applyStroke(boxFrame, DEFAULT_THEME.Stroke, 1, 0.3)

        local box = Instance.new("TextBox")
        box.Name = "Input"
        box.Size = UDim2.new(1, -12, 1, 0)
        box.Position = UDim2.new(0, 6, 0, 0)
        box.BackgroundTransparency = 1
        box.Font = Enum.Font.Gotham
        box.PlaceholderText = tostring(placeholderText or "Type here...")
        box.PlaceholderColor3 = DEFAULT_THEME.TextDim
        box.Text = ""
        box.TextColor3 = DEFAULT_THEME.TextPrimary
        box.TextSize = 11
        box.TextXAlignment = Enum.TextXAlignment.Left
        box.ClearTextOnFocus = false
        box.Parent = boxFrame

        box.Focused:Connect(function()
            tween(boxStroke, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {Color = primaryTheme})
        end)
        box.FocusLost:Connect(function(enterPressed)
            tween(boxStroke, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {Color = DEFAULT_THEME.Stroke})
            pcall(cb, box.Text, enterPressed)
        end)

        return {
            Instance = card,
            GetText = function() return box.Text end,
            Set = function(t) box.Text = tostring(t or "") end
        }
    end

    -- =========================================================================
    -- Component 8: List & Nested Lists (BeeSwarm & BloxFruits Compatible)
    -- =========================================================================
    createList = function(parent, titleText, itemsList, maxHeight, expandedState, selectionOptions, extraCallback)
        if typeof(parent) == "table" and parent.Page then parent = parent.Page end
        if typeof(parent) == "string" then
            extraCallback = selectionOptions
            selectionOptions = expandedState
            expandedState = maxHeight
            maxHeight = itemsList
            itemsList = titleText
            titleText = parent
            parent = activeTab and activeTab.Page or nil
        end

        local items = itemsList or {}
        local isExpanded = (expandedState == true)
        local cb = type(extraCallback) == "function" and extraCallback or (type(selectionOptions) == "function" and selectionOptions or function() end)

        local card = Instance.new("Frame")
        card.Name = "ListCard_" .. tostring(titleText)
        card.Size = UDim2.new(1, 0, 0, 40)
        card.BackgroundColor3 = DEFAULT_THEME.Card
        card.BorderSizePixel = 0
        card.ClipsDescendants = true
        card.Parent = parent
        applyCorner(card, 8)
        applyStroke(card, DEFAULT_THEME.Stroke, 1, 0.3)

        table.insert(registeredElements, { Card = card, Title = tostring(titleText), Type = "List" })

        local headerBtn = Instance.new("TextButton")
        headerBtn.Name = "Header"
        headerBtn.Size = UDim2.new(1, 0, 0, 40)
        headerBtn.BackgroundTransparency = 1
        headerBtn.Text = ""
        headerBtn.Parent = card

        local titleLabel = Instance.new("TextLabel")
        titleLabel.Name = "Title"
        titleLabel.Size = UDim2.new(1, -70, 1, 0)
        titleLabel.Position = UDim2.new(0, 14, 0, 0)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Font = Enum.Font.Gotham
        titleLabel.Text = tostring(titleText or "List")
        titleLabel.TextColor3 = DEFAULT_THEME.TextPrimary
        titleLabel.TextSize = 12
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.Parent = headerBtn

        local countBadge = Instance.new("TextLabel")
        countBadge.Name = "CountBadge"
        countBadge.Size = UDim2.new(0, 24, 0, 18)
        countBadge.Position = UDim2.new(1, -64, 0.5, -9)
        countBadge.BackgroundColor3 = Color3.fromRGB(18, 21, 28)
        countBadge.BorderSizePixel = 0
        countBadge.Font = Enum.Font.GothamMedium
        countBadge.Text = tostring(#items)
        countBadge.TextColor3 = primaryTheme
        countBadge.TextSize = 10
        countBadge.Parent = headerBtn
        applyCorner(countBadge, 4)

        local chevron = Instance.new("TextLabel")
        chevron.Name = "Chevron"
        chevron.Size = UDim2.new(0, 24, 0, 24)
        chevron.Position = UDim2.new(1, -34, 0.5, -12)
        chevron.BackgroundTransparency = 1
        chevron.Font = Enum.Font.GothamBold
        chevron.Text = "▾"
        chevron.TextColor3 = DEFAULT_THEME.TextSecondary
        chevron.TextSize = 14
        chevron.Parent = headerBtn

        -- Search Bar (Visible when list is large)
        local searchBar = Instance.new("TextBox")
        searchBar.Name = "SearchBox"
        searchBar.Size = UDim2.new(1, -20, 0, 26)
        searchBar.Position = UDim2.new(0, 10, 0, 44)
        searchBar.BackgroundColor3 = Color3.fromRGB(18, 21, 28)
        searchBar.BorderSizePixel = 0
        searchBar.PlaceholderText = "Search list..."
        searchBar.PlaceholderColor3 = Color3.fromRGB(110, 120, 140)
        searchBar.Text = ""
        searchBar.TextColor3 = DEFAULT_THEME.TextPrimary
        searchBar.Font = Enum.Font.Gotham
        searchBar.TextSize = 11
        searchBar.ClearTextOnFocus = false
        searchBar.Visible = false
        searchBar.Parent = card
        applyCorner(searchBar, 6)
        applyStroke(searchBar, DEFAULT_THEME.Stroke, 1, 0.3)

        local listScroll = Instance.new("ScrollingFrame")
        listScroll.Name = "ScrollItems"
        listScroll.Size = UDim2.new(1, -20, 0, tonumber(maxHeight) or 160)
        listScroll.Position = UDim2.new(0, 10, 0, 42)
        listScroll.BackgroundTransparency = 1
        listScroll.BorderSizePixel = 0
        listScroll.ScrollBarThickness = 3
        listScroll.ScrollBarImageColor3 = Color3.fromRGB(50, 60, 78)
        listScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        listScroll.Parent = card

        local listLayout = Instance.new("UIListLayout")
        listLayout.FillDirection = Enum.FillDirection.Vertical
        listLayout.Padding = UDim.new(0, 4)
        listLayout.Parent = listScroll

        local listObj = {
            Instance = card,
            List = listScroll,
            Items = {},
            SelectedItem = nil
        }

        local function updateListVisuals()
            local showSearch = (#listObj.Items >= 5)
            searchBar.Visible = isExpanded and showSearch
            if showSearch then
                listScroll.Position = UDim2.new(0, 10, 0, 76)
            else
                listScroll.Position = UDim2.new(0, 10, 0, 42)
            end

            local visibleCount = 0
            for _, child in ipairs(listScroll:GetChildren()) do
                if child:IsA("TextButton") and child.Visible then
                    visibleCount = visibleCount + 1
                end
            end

            local maxH = tonumber(maxHeight) or 160
            local scrollHeight = math.min(visibleCount * 32, maxH)
            listScroll.Size = UDim2.new(1, -20, 0, scrollHeight)

            local baseH = showSearch and 76 or 44
            local targetH = isExpanded and (baseH + scrollHeight + 8) or 40
            chevron.Text = isExpanded and "▴" or "▾"
            countBadge.Text = tostring(#listObj.Items)
            tween(card, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, targetH)})
        end

        searchBar:GetPropertyChangedSignal("Text"):Connect(function()
            local q = searchBar.Text:lower():gsub("^%s*(.-)%s*$", "%1")
            for _, child in ipairs(listScroll:GetChildren()) do
                if child:IsA("TextButton") then
                    local txt = child.Text:lower():gsub("^%s*", "")
                    child.Visible = (q == "" or txt:find(q, 1, true) ~= nil)
                end
            end
            updateListVisuals()
        end)

        headerBtn.MouseButton1Click:Connect(function()
            isExpanded = not isExpanded
            searchBar.Text = ""
            for _, child in ipairs(listScroll:GetChildren()) do
                if child:IsA("TextButton") then child.Visible = true end
            end
            updateListVisuals()
        end)

        function listObj.AddItem(text, subtext, itemCallback)
            local label = (type(text) == "table" and (text.Display or text.Name or text.Title or text.ExactName or text.Text or text.text or text[1])) or tostring(text)
            local itmBtn = Instance.new("TextButton")
            itmBtn.Name = "Item_" .. label
            itmBtn.Size = UDim2.new(1, 0, 0, 28)
            itmBtn.BackgroundColor3 = Color3.fromRGB(18, 21, 28)
            itmBtn.BorderSizePixel = 0
            itmBtn.Font = Enum.Font.Gotham
            itmBtn.Text = "   " .. label
            itmBtn.TextColor3 = DEFAULT_THEME.TextSecondary
            itmBtn.TextSize = 11
            itmBtn.TextXAlignment = Enum.TextXAlignment.Left
            itmBtn.AutoButtonColor = false
            itmBtn.Parent = listScroll
            applyCorner(itmBtn, 5)

            table.insert(listObj.Items, text)
            countBadge.Text = tostring(#listObj.Items)

            itmBtn.MouseEnter:Connect(function()
                tween(itmBtn, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {BackgroundColor3 = DEFAULT_THEME.CardHover, TextColor3 = DEFAULT_THEME.TextPrimary})
            end)
            itmBtn.MouseLeave:Connect(function()
                if listObj.SelectedItem ~= text then
                    tween(itmBtn, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {BackgroundColor3 = Color3.fromRGB(18, 21, 28), TextColor3 = DEFAULT_THEME.TextSecondary})
                end
            end)
            itmBtn.MouseButton1Click:Connect(function()
                listObj.SelectedItem = text
                pcall(cb, text)
                if type(itemCallback) == "function" then pcall(itemCallback, text) end
            end)
            return itmBtn
        end

        function listObj.SetSelected(self, selectedText)
            local target = (type(selectedText) == "table" and (selectedText.Display or selectedText.Name or selectedText.Title or selectedText.ExactName or selectedText.Text or selectedText.text or selectedText[1])) or tostring(selectedText)
            listObj.SelectedItem = selectedText
            for _, child in ipairs(listScroll:GetChildren()) do
                if child:IsA("TextButton") then
                    local cleanName = child.Name:gsub("^Item_", "")
                    local isMatch = (cleanName == target or child.Text:gsub("^%s*", "") == target)
                    if isMatch then
                        tween(child, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {BackgroundColor3 = DEFAULT_THEME.CardHover or Color3.fromRGB(30, 36, 48), TextColor3 = primaryTheme})
                    else
                        tween(child, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {BackgroundColor3 = Color3.fromRGB(18, 21, 28), TextColor3 = DEFAULT_THEME.TextSecondary})
                    end
                end
            end
            if type(listObj.OnSelect) == "function" then
                pcall(listObj.OnSelect, selectedText)
            end
        end
        listObj.setSelected = listObj.SetSelected

        function listObj.SetSelectedItems(self, itemsArray)
            listObj.SelectedItems = itemsArray or {}
            local lookup = {}
            for _, itm in ipairs(listObj.SelectedItems) do
                local val = (type(itm) == "table" and (itm.Display or itm.Name or itm.Title or itm.ExactName or itm.Text or itm.text or itm[1])) or tostring(itm)
                lookup[val] = true
            end
            for _, child in ipairs(listScroll:GetChildren()) do
                if child:IsA("TextButton") then
                    local cleanName = child.Name:gsub("^Item_", "")
                    local isMatch = lookup[cleanName] or lookup[child.Text:gsub("^%s*", "")]
                    if isMatch then
                        tween(child, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {BackgroundColor3 = DEFAULT_THEME.CardHover or Color3.fromRGB(30, 36, 48), TextColor3 = primaryTheme})
                    else
                        tween(child, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {BackgroundColor3 = Color3.fromRGB(18, 21, 28), TextColor3 = DEFAULT_THEME.TextSecondary})
                    end
                end
            end
        end
        listObj.setSelectedItems = listObj.SetSelectedItems

        for _, itm in ipairs(items) do
            listObj.AddItem(itm)
        end

        return listObj
    end

    -- =========================================================================
    -- Component 9: Loop Toggle (Game Automation Helper)
    -- =========================================================================
    local function createLoopToggle(parent, titleText, defaultState, loopFunc, loopInterval)
        local interval = loopInterval or 0.1
        local running = false
        local loopThread = nil

        local t = createToggle(parent, titleText, defaultState, function(enabled)
            running = enabled
            if running then
                loopThread = task.spawn(function()
                    while running do
                        pcall(loopFunc)
                        task.wait(interval)
                    end
                end)
            else
                if loopThread then
                    pcall(function() task.cancel(loopThread) end)
                    loopThread = nil
                end
            end
        end)

        table.insert(featureStoppers, function()
            running = false
            if loopThread then pcall(function() task.cancel(loopThread) end) end
        end)

        return t
    end

    -- =========================================================================
    -- Component 10: Modal Warning Dialog
    -- =========================================================================
    local function showWarning(title, desc, btn1, btn2, onBtn1, onBtn2)
        local modalOverlay = Instance.new("Frame")
        modalOverlay.Name = "ModalOverlay"
        modalOverlay.Size = UDim2.new(1, 0, 1, 0)
        modalOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        modalOverlay.BackgroundTransparency = 0.5
        modalOverlay.BorderSizePixel = 0
        modalOverlay.ZIndex = 100
        modalOverlay.Parent = screenGui

        local modalBox = Instance.new("Frame")
        modalBox.Name = "ModalBox"
        modalBox.Size = UDim2.new(0, 360, 0, 180)
        modalBox.Position = UDim2.new(0.5, -180, 0.5, -90)
        modalBox.BackgroundColor3 = DEFAULT_THEME.Background
        modalBox.BorderSizePixel = 0
        modalBox.Parent = modalOverlay
        applyCorner(modalBox, 10)
        applyStroke(modalBox, DEFAULT_THEME.Stroke, 1, 0.2)

        local mTitle = Instance.new("TextLabel")
        mTitle.Size = UDim2.new(1, -28, 0, 24)
        mTitle.Position = UDim2.new(0, 14, 0, 14)
        mTitle.BackgroundTransparency = 1
        mTitle.Font = Enum.Font.GothamBold
        mTitle.Text = tostring(title or "Notice")
        mTitle.TextColor3 = primaryTheme
        mTitle.TextSize = 14
        mTitle.TextXAlignment = Enum.TextXAlignment.Left
        mTitle.Parent = modalBox

        local mDesc = Instance.new("TextLabel")
        mDesc.Size = UDim2.new(1, -28, 0, 60)
        mDesc.Position = UDim2.new(0, 14, 0, 42)
        mDesc.BackgroundTransparency = 1
        mDesc.Font = Enum.Font.Gotham
        mDesc.Text = tostring(desc or "")
        mDesc.TextColor3 = DEFAULT_THEME.TextSecondary
        mDesc.TextSize = 12
        mDesc.TextWrapped = true
        mDesc.TextXAlignment = Enum.TextXAlignment.Left
        mDesc.Parent = modalBox

        local b1 = Instance.new("TextButton")
        b1.Size = UDim2.new(0.5, -18, 0, 32)
        b1.Position = UDim2.new(0, 14, 1, -44)
        b1.BackgroundColor3 = primaryTheme
        b1.BorderSizePixel = 0
        b1.Font = Enum.Font.Gotham
        b1.Text = tostring(btn1 or "Confirm")
        b1.TextColor3 = Color3.fromRGB(255, 255, 255)
        b1.TextSize = 12
        b1.Parent = modalBox
        applyCorner(b1, 6)

        local b2 = Instance.new("TextButton")
        b2.Size = UDim2.new(0.5, -18, 0, 32)
        b2.Position = UDim2.new(0.5, 4, 1, -44)
        b2.BackgroundColor3 = DEFAULT_THEME.Card
        b2.BorderSizePixel = 0
        b2.Font = Enum.Font.Gotham
        b2.Text = tostring(btn2 or "Cancel")
        b2.TextColor3 = DEFAULT_THEME.TextSecondary
        b2.TextSize = 12
        b2.Parent = modalBox
        applyCorner(b2, 6)

        b1.MouseButton1Click:Connect(function()
            pcall(onBtn1 or function() end)
            modalOverlay:Destroy()
        end)
        b2.MouseButton1Click:Connect(function()
            pcall(onBtn2 or function() end)
            modalOverlay:Destroy()
        end)
    end

    -- =========================================================================
    -- Black Screen Performance Mode
    -- =========================================================================
    local blackScreenOverlay = nil
    local function setBlackScreen(enabled)
        pcall(function()
            RunService:Set3dRenderingEnabled(not enabled)
        end)
        if enabled then
            if not blackScreenOverlay or not blackScreenOverlay.Parent then
                blackScreenOverlay = Instance.new("Frame")
                blackScreenOverlay.Name = "Unknown_BlackScreenOverlay"
                blackScreenOverlay.Size = UDim2.new(1, 0, 1, 0)
                blackScreenOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                blackScreenOverlay.BorderSizePixel = 0
                blackScreenOverlay.ZIndex = 999999
                blackScreenOverlay.Parent = screenGui
            end
            blackScreenOverlay.Visible = true
        else
            if blackScreenOverlay and blackScreenOverlay.Parent then
                blackScreenOverlay.Visible = false
            end
        end
    end


    -- =========================================================================
    -- Public API Hub Interface
    -- =========================================================================
    local Hub = {}
    Hub.ShowUpdateLog = showUpdateLogModal

    -- Core GUI Elements
    Hub.screenGui = screenGui
    Hub.gui = screenGui
    Hub.mainFrame = mainFrame
    Hub.frame = mainFrame
    Hub.content = contentArea

    -- Config System & Control Registry
    Hub.RegisteredFlags = registeredFlags
    Hub.RegisteredElements = registeredElements

    -- Universal Configuration Serializer (Profiles, Auto-Save & Auto-Load)
    Hub.SaveConfig = function(configName)
        configName = (configName and configName ~= "") and configName or "default"
        local gameName = tostring(game.PlaceId)
        local folder = "UnknownHub/Configs/" .. gameName
        pcall(function()
            if not isfolder("UnknownHub") then makefolder("UnknownHub") end
            if not isfolder("UnknownHub/Configs") then makefolder("UnknownHub/Configs") end
            if not isfolder(folder) then makefolder(folder) end
        end)
        local data = {}
        for flagName, flagObj in pairs(registeredFlags) do
            local ok, val = pcall(flagObj.Get)
            if ok and val ~= nil then
                data[flagName] = val
            end
        end
        local encoded = HttpService:JSONEncode(data)
        local path = folder .. "/" .. configName .. ".json"
        local ok, err = pcall(function() writefile(path, encoded) end)
        if ok then
            sendNotification("Configuration", "Saved config '" .. configName .. "' successfully!", 2.5)
        else
            sendNotification("Config Error", "Failed to save: " .. tostring(err), 3)
        end
    end

    Hub.LoadConfig = function(configName)
        configName = (configName and configName ~= "") and configName or "default"
        local gameName = tostring(game.PlaceId)
        local path = "UnknownHub/Configs/" .. gameName .. "/" .. configName .. ".json"
        local exists = false
        pcall(function() exists = isfile(path) end)
        if not exists then
            sendNotification("Configuration", "Config '" .. configName .. "' not found.", 2.5)
            return false
        end
        local content = readfile(path)
        local ok, decoded = pcall(function() return HttpService:JSONDecode(content) end)
        if not ok or type(decoded) ~= "table" then
            sendNotification("Config Error", "Corrupt config file.", 2.5)
            return false
        end
        for flagName, val in pairs(decoded) do
            local flagObj = registeredFlags[flagName]
            if flagObj and flagObj.Set then
                pcall(flagObj.Set, val)
            end
        end
        sendNotification("Configuration", "Loaded config '" .. configName .. "'!", 2.5)
        return true
    end

    Hub.ListConfigs = function()
        local gameName = tostring(game.PlaceId)
        local folder = "UnknownHub/Configs/" .. gameName
        local list = {}
        pcall(function()
            if isfolder(folder) then
                for _, f in ipairs(listfiles(folder)) do
                    local name = f:match("([^/\\]+)%.json$")
                    if name then table.insert(list, name) end
                end
            end
        end)
        return list
    end

    -- Tab & Component Factories
    Hub.CreateTab = createTab
    Hub.createTab = createTab
    Hub.CreatePage = createTab
    Hub.createPage = createTab

    Hub.CreateSection = createSection
    Hub.createSection = createSection
    Hub.addSection = createSection

    Hub.CreateToggle = createToggle
    Hub.createToggle = createToggle
    Hub.CreateLoopToggle = createLoopToggle
    Hub.createLoopToggle = createLoopToggle

    Hub.CreateSlider = createSlider
    Hub.createSlider = createSlider

    Hub.CreateDropdown = createDropdown
    Hub.createDropdown = createDropdown
    Hub.CreateMultiDropdown = createMultiDropdown
    Hub.createMultiDropdown = createMultiDropdown

    Hub.CreateButton = createButton
    Hub.createButton = createButton

    Hub.CreateTextBox = createTextBox
    Hub.createTextBox = createTextBox
    Hub.CreateInput = createTextBox
    Hub.createInput = createTextBox

    Hub.CreateColorpicker = createColorPicker
    Hub.createColorpicker = createColorPicker
    Hub.CreateColorPicker = createColorPicker
    Hub.createColorPicker = createColorPicker

    Hub.CreateList = createList
    Hub.createList = createList

    Hub.CreateStatRow = createStatRow
    Hub.createStatRow = createStatRow
    Hub.addItem = function(titleText, subtitleText, callback)
        if activeTab and activeTab.Page then
            return createButton(activeTab.Page, titleText, callback)
        end
    end
    Hub.GetItemFromList = function(list)
        return list and list.SelectedItem
    end

    -- Notifications & Modals
    Hub.Notify = sendNotification
    Hub.notify = sendNotification
    Hub.SendNotification = sendNotification
    Hub.sendNotification = sendNotification
    Hub.ShowWarning = showWarning
    Hub.showWarning = showWarning
    Hub.SetBlackScreen = setBlackScreen
    Hub.setBlackScreen = setBlackScreen

    -- Lifecycle & Teardown
    Hub.registerFeatureStopper = function(stopper)
        if type(stopper) == "function" then table.insert(featureStoppers, stopper) end
    end
    Hub.RegisterFeatureStopper = Hub.registerFeatureStopper

    Hub.OnUnload = function(fn)
        if type(fn) == "function" then
            table.insert(featureStoppers, fn)
        end
    end
    Hub.RegisterTeardown = Hub.OnUnload
    Hub.onUnload = Hub.OnUnload

    Hub.disableAll = function()
        for _, stopper in ipairs(featureStoppers) do
            pcall(stopper)
        end
    end

    Hub.destroy = function()
        Hub.disableAll()
        if screenGui and screenGui.Parent then
            screenGui:Destroy()
        end
        if _G.UNKNOWN_ACTIVE_HUB == Hub then
            _G.UNKNOWN_ACTIVE_HUB = nil
        end
    end

    -- =========================================================================
    -- Built-in Hub Settings Tab (Exclusive System Controls, NO Universal Cheats)
    -- =========================================================================
    local settingsPage = nil
    local function ensureSettingsTab()
        if settingsPage then return end
        settingsPage = createTab("Settings", { Icon = "⚙", Size = 16 })

        -- Section 0: Configuration Profiles Manager
        createSection(settingsPage, "Configuration Profiles")

        local configNameInput = "default"
        createTextBox(settingsPage, "Config Profile Name", "default", function(text)
            if text and text ~= "" then configNameInput = text end
        end)

        createButton(settingsPage, "Save Current Configuration", function()
            Hub.SaveConfig(configNameInput)
        end)

        createButton(settingsPage, "Load Selected Configuration", function()
            Hub.LoadConfig(configNameInput)
        end)

        -- Section 1: Appearance & UI
        createSection(settingsPage, "🎨 UI & Theme Customization")

        -- Fully Customizable RGB Palette & ColorPicker
        createColorPicker(settingsPage, "Custom Theme Color (RGB Palette)", primaryTheme, function(chosenColor)
            setAccentColor(chosenColor)
        end)

        createButton(settingsPage, "Reset Window Position", function()
            mainFrame.Position = UDim2.new(0.5, -math.floor(winWidth / 2), 0.5, -math.floor(winHeight / 2))
            sendNotification("Settings", "Window position centered.", 2)
        end)

        createSlider(settingsPage, "Background Transparency", 0, 50, 0, "%", function(pct)
            local trans = pct / 100
            mainFrame.BackgroundTransparency = trans
            sidebar.BackgroundTransparency = trans
        end)

        -- Section 2: Session & Connectivity
        createSection(settingsPage, "🌐 Session Management")

        createButton(settingsPage, "Rejoin Current Server", function()
            pcall(function()
                if #Players:GetPlayers() <= 1 then
                    LocalPlayer:Kick("\n[Unknown Hub] Rejoining server...")
                    task.wait()
                    TeleportService:Teleport(game.PlaceId, LocalPlayer)
                else
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
                end
            end)
        end)

        createButton(settingsPage, "Server Hop (Next Public Server)", function()
            sendNotification("Server Hop", "Searching for an active server...", 2.5)
            task.spawn(function()
                local placeId = game.PlaceId
                local ok, res = pcall(function()
                    return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100"))
                end)
                if ok and res and res.data then
                    for _, srv in ipairs(res.data) do
                        if srv.playing and srv.maxPlayers and srv.playing < srv.maxPlayers and srv.id ~= game.JobId then
                            pcall(function()
                                TeleportService:TeleportToPlaceInstance(placeId, srv.id, LocalPlayer)
                            end)
                            return
                        end
                    end
                end
                pcall(function() TeleportService:Teleport(placeId, LocalPlayer) end)
            end)
        end)

        createButton(settingsPage, "Copy Community Invite Link", function()
            local link = "https://discord.gg/unknownhub"
            local copier = type(setclipboard) == "function" and setclipboard or (type(toclipboard) == "function" and toclipboard or nil)
            if copier then
                pcall(copier, link)
                sendNotification("Copied", "Discord invite copied to clipboard!", 2)
            else
                sendNotification("Notice", link, 4)
            end
        end)

        createButton(settingsPage, "Safe Unload & Teardown Hub", function()
            showWarning("Unload Unknown Hub", "Are you sure you want to unload the hub and stop all active features?", "Unload", "Cancel", function()
                Hub.destroy()
            end)
        end)
    end

    -- Automatically attach Settings tab when loading completes or on deferral
    Hub.finishLoading = function(msg)
        ensureSettingsTab()
        if msg then sendNotification("Unknown Hub", tostring(msg), 3) end
    end
    Hub.FinishLoading = Hub.finishLoading

    -- Fallback deferral to ensure Settings is always present
    task.defer(function()
        task.wait(0.2)
        ensureSettingsTab()
    end)

    _G.UNKNOWN_ACTIVE_HUB = Hub
    return Hub
end
