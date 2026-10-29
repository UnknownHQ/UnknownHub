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
    Primary = Color3.fromRGB(245, 142, 32),       -- Vibrant Electric Amber
    Secondary = Color3.fromRGB(0, 195, 245),     -- Cyber Cyan
    Background = Color3.fromRGB(13, 15, 21),     -- Deep Matte Midnight Slate
    Sidebar = Color3.fromRGB(17, 20, 27),        -- Elevated Sidebar Panel
    Card = Color3.fromRGB(22, 26, 35),           -- Control Card Surface
    CardHover = Color3.fromRGB(28, 33, 44),      -- Control Card Hover Surface
    Input = Color3.fromRGB(15, 18, 24),          -- Embedded Input Track
    Stroke = Color3.fromRGB(34, 40, 53),         -- Razor-sharp 1px Border
    TextPrimary = Color3.fromRGB(240, 244, 252),  -- Clean Crisp Off-White
    TextSecondary = Color3.fromRGB(140, 152, 172),-- Muted Slate Gray
    TextDim = Color3.fromRGB(95, 105, 122),      -- Subtle Placeholders / Subtext
    Success = Color3.fromRGB(45, 205, 115),
    Warning = Color3.fromRGB(245, 165, 35),
    Danger = Color3.fromRGB(240, 65, 75)
}

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

    -- Breadcrumb Title
    local breadcrumbTitle = Instance.new("TextLabel")
    breadcrumbTitle.Name = "BreadcrumbTitle"
    breadcrumbTitle.Size = UDim2.new(1, -150, 1, 0)
    breadcrumbTitle.Position = UDim2.new(0, 18, 0, 0)
    breadcrumbTitle.BackgroundTransparency = 1
    breadcrumbTitle.Font = Enum.Font.GothamBold
    breadcrumbTitle.Text = "Overview"
    breadcrumbTitle.TextColor3 = DEFAULT_THEME.TextPrimary
    breadcrumbTitle.TextSize = 14
    breadcrumbTitle.TextXAlignment = Enum.TextXAlignment.Left
    breadcrumbTitle.Parent = header

    -- Keybind Badge Pill
    local keybindPill = Instance.new("TextButton")
    keybindPill.Name = "ToggleKeyBadge"
    keybindPill.Size = UDim2.new(0, 68, 0, 24)
    keybindPill.Position = UDim2.new(1, -140, 0.5, -12)
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

    -- Window Controls Container
    local winControls = Instance.new("Frame")
    winControls.Name = "WindowControls"
    winControls.Size = UDim2.new(0, 56, 0, 24)
    winControls.Position = UDim2.new(1, -66, 0.5, -12)
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

        -- Icon Label
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

        -- Component binding helpers on tab object
        tabRecord.CreateSection = function(title) return createSection(pageScroll, title) end
        tabRecord.CreateToggle = function(name, default, callback) return createToggle(pageScroll, name, default, callback) end
        tabRecord.CreateSlider = function(name, min, max, default, suffix, callback) return createSlider(pageScroll, name, min, max, default, suffix, callback) end
        tabRecord.CreateDropdown = function(name, options, default, callback) return createDropdown(pageScroll, name, options, default, callback) end
        tabRecord.CreateMultiDropdown = function(name, options, default, callback) return createMultiDropdown(pageScroll, name, options, default, callback) end
        tabRecord.CreateButton = function(name, callback) return createButton(pageScroll, name, callback) end
        tabRecord.CreateTextBox = function(name, placeholder, callback) return createTextBox(pageScroll, name, placeholder, callback) end
        tabRecord.CreateInput = tabRecord.CreateTextBox
        tabRecord.CreateColorpicker = function(name, defaultColor, callback) return createColorPicker(pageScroll, name, defaultColor, callback) end
        tabRecord.CreateColorPicker = tabRecord.CreateColorpicker
        tabRecord.CreateList = function(name, items, height, expanded, selectionOptions, callback) return createList(pageScroll, name, items, height, expanded, selectionOptions, callback) end

        return pageScroll
    end

    -- =========================================================================
    -- Component 1: Section Header (Clean & Subtle)
    -- =========================================================================
    createSection = function(parent, titleText)
        local container = Instance.new("Frame")
        container.Name = "Section_" .. tostring(titleText)
        container.Size = UDim2.new(1, 0, 0, 22)
        container.BackgroundTransparency = 1
        container.Parent = parent

        local titleLabel = Instance.new("TextLabel")
        titleLabel.Name = "Title"
        titleLabel.Size = UDim2.new(0, 0, 1, 0)
        titleLabel.AutomaticSize = Enum.AutomaticSize.X
        titleLabel.BackgroundTransparency = 1
        titleLabel.Font = Enum.Font.GothamBold
        titleLabel.Text = string.upper(tostring(titleText or ""))
        titleLabel.TextColor3 = primaryTheme
        titleLabel.TextSize = 10
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

        titleLabel:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
            local width = titleLabel.AbsoluteSize.X
            rule.Position = UDim2.new(0, width + 10, 0.5, 0)
            rule.Size = UDim2.new(1, -(width + 10), 0, 1)
        end)

        return container
    end

    -- =========================================================================
    -- Component 2: Modern Toggle Switch (Clean Rounded Surfaces)
    -- =========================================================================
    createToggle = function(parent, titleText, defaultState, callback)
        local state = defaultState == true
        local cb = type(callback) == "function" and callback or function() end

        local card = Instance.new("Frame")
        card.Name = "ToggleCard_" .. tostring(titleText)
        card.Size = UDim2.new(1, 0, 0, 42)
        card.BackgroundColor3 = DEFAULT_THEME.Card
        card.BorderSizePixel = 0
        card.Parent = parent
        applyCorner(card, 8)
        local stroke = applyStroke(card, DEFAULT_THEME.Stroke, 1, 0.3)

        local titleLabel = Instance.new("TextLabel")
        titleLabel.Name = "Label"
        titleLabel.Size = UDim2.new(1, -64, 1, 0)
        titleLabel.Position = UDim2.new(0, 14, 0, 0)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Font = Enum.Font.Gotham
        titleLabel.Text = tostring(titleText)
        titleLabel.TextColor3 = DEFAULT_THEME.TextPrimary
        titleLabel.TextSize = 12
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
        titleLabel.Parent = card

        -- Switch Track
        local switchTrack = Instance.new("TextButton")
        switchTrack.Name = "SwitchTrack"
        switchTrack.Size = UDim2.new(0, 38, 0, 20)
        switchTrack.Position = UDim2.new(1, -50, 0.5, -10)
        switchTrack.BackgroundColor3 = state and primaryTheme or Color3.fromRGB(36, 42, 54)
        switchTrack.BorderSizePixel = 0
        switchTrack.Text = ""
        switchTrack.AutoButtonColor = false
        switchTrack.Parent = card
        applyCorner(switchTrack, 10)

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
                    BackgroundColor3 = Color3.fromRGB(36, 42, 54)
                })
                tween(switchKnob, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Position = UDim2.new(0, 3, 0.5, -7)
                })
            end
        end

        local function setToggle(val)
            state = (val == true)
            updateVisuals()
            pcall(cb, state)
        end

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
    -- Component 3: Precision Slider
    -- =========================================================================
    createSlider = function(parent, titleText, minVal, maxVal, defaultVal, suffixText, callback)
        minVal = tonumber(minVal) or 0
        maxVal = tonumber(maxVal) or 100
        defaultVal = tonumber(defaultVal) or minVal
        local suffix = tostring(suffixText or "")
        local cb = type(callback) == "function" and callback or function() end

        local currentValue = math.clamp(defaultVal, minVal, maxVal)

        local card = Instance.new("Frame")
        card.Name = "SliderCard_" .. tostring(titleText)
        card.Size = UDim2.new(1, 0, 0, 52)
        card.BackgroundColor3 = DEFAULT_THEME.Card
        card.BorderSizePixel = 0
        card.Parent = parent
        applyCorner(card, 8)
        applyStroke(card, DEFAULT_THEME.Stroke, 1, 0.3)

        -- Title on left
        local titleLabel = Instance.new("TextLabel")
        titleLabel.Name = "Label"
        titleLabel.Size = UDim2.new(0.65, 0, 0, 20)
        titleLabel.Position = UDim2.new(0, 14, 0, 8)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Font = Enum.Font.Gotham
        titleLabel.Text = tostring(titleText)
        titleLabel.TextColor3 = DEFAULT_THEME.TextPrimary
        titleLabel.TextSize = 12
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
        titleLabel.Parent = card

        -- Value badge on right
        local valBadge = Instance.new("TextLabel")
        valBadge.Name = "ValueBadge"
        valBadge.Size = UDim2.new(0.35, -28, 0, 20)
        valBadge.Position = UDim2.new(0.65, 0, 0, 8)
        valBadge.BackgroundTransparency = 1
        valBadge.Font = Enum.Font.GothamMedium
        valBadge.Text = tostring(currentValue) .. suffix
        valBadge.TextColor3 = primaryTheme
        valBadge.TextSize = 11
        valBadge.TextXAlignment = Enum.TextXAlignment.Right
        valBadge.Parent = card

        -- Track
        local track = Instance.new("TextButton")
        track.Name = "SliderTrack"
        track.Size = UDim2.new(1, -28, 0, 6)
        track.Position = UDim2.new(0, 14, 0, 34)
        track.BackgroundColor3 = Color3.fromRGB(34, 40, 52)
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

        local thumb = Instance.new("Frame")
        thumb.Name = "Thumb"
        thumb.Size = UDim2.new(0, 12, 0, 12)
        thumb.Position = UDim2.new(0, -6, 0.5, -6)
        thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        thumb.BorderSizePixel = 0
        thumb.Parent = fill
        applyCorner(thumb, 6)

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
            thumb.Position = UDim2.new(1, -6, 0.5, -6)
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
    -- Component 4: Modern Button
    -- =========================================================================
    createButton = function(parent, titleText, callback)
        local cb = type(callback) == "function" and callback or function() end

        local card = Instance.new("TextButton")
        card.Name = "ButtonCard_" .. tostring(titleText)
        card.Size = UDim2.new(1, 0, 0, 38)
        card.BackgroundColor3 = DEFAULT_THEME.Card
        card.BorderSizePixel = 0
        card.Font = Enum.Font.Gotham
        card.Text = tostring(titleText)
        card.TextColor3 = DEFAULT_THEME.TextPrimary
        card.TextSize = 12
        card.AutoButtonColor = false
        card.Parent = parent
        applyCorner(card, 8)
        applyStroke(card, DEFAULT_THEME.Stroke, 1, 0.3)

        card.MouseEnter:Connect(function()
            tween(card, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {BackgroundColor3 = DEFAULT_THEME.CardHover})
        end)
        card.MouseLeave:Connect(function()
            tween(card, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {BackgroundColor3 = DEFAULT_THEME.Card})
        end)
        card.MouseButton1Down:Connect(function()
            tween(card, TweenInfo.new(0.08, Enum.EasingStyle.Quad), {Size = UDim2.new(1, -4, 0, 36)})
        end)
        card.MouseButton1Up:Connect(function()
            tween(card, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {Size = UDim2.new(1, 0, 0, 38)})
        end)
        card.MouseButton1Click:Connect(function()
            pcall(cb)
        end)

        return card
    end

    -- =========================================================================
    -- Component 5: Accordion Dropdown
    -- =========================================================================
    createDropdown = function(parent, titleText, optionsList, defaultChoice, callback)
        local options = optionsList or {}
        local currentSelection = defaultChoice or options[1] or "None"
        local cb = type(callback) == "function" and callback or function() end
        local isExpanded = false

        local card = Instance.new("Frame")
        card.Name = "DropdownCard_" .. tostring(titleText)
        card.Size = UDim2.new(1, 0, 0, 42)
        card.BackgroundColor3 = DEFAULT_THEME.Card
        card.BorderSizePixel = 0
        card.ClipsDescendants = true
        card.Parent = parent
        applyCorner(card, 8)
        applyStroke(card, DEFAULT_THEME.Stroke, 1, 0.3)

        local headerBtn = Instance.new("TextButton")
        headerBtn.Name = "HeaderButton"
        headerBtn.Size = UDim2.new(1, 0, 0, 42)
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

        local selectionPill = Instance.new("TextLabel")
        selectionPill.Name = "Pill"
        selectionPill.Size = UDim2.new(0.5, -42, 0, 24)
        selectionPill.Position = UDim2.new(0.5, 0, 0.5, -12)
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

        local optionsContainer = Instance.new("Frame")
        optionsContainer.Name = "OptionsList"
        optionsContainer.Size = UDim2.new(1, -20, 0, 0)
        optionsContainer.Position = UDim2.new(0, 10, 0, 44)
        optionsContainer.BackgroundTransparency = 1
        optionsContainer.Parent = card

        local optLayout = Instance.new("UIListLayout")
        optLayout.FillDirection = Enum.FillDirection.Vertical
        optLayout.Padding = UDim.new(0, 3)
        optLayout.Parent = optionsContainer

        local function rebuildOptions()
            for _, child in ipairs(optionsContainer:GetChildren()) do
                if child:IsA("TextButton") then child:Destroy() end
            end

            for _, opt in ipairs(options) do
                local optBtn = Instance.new("TextButton")
                optBtn.Name = "Opt_" .. tostring(opt)
                optBtn.Size = UDim2.new(1, 0, 0, 28)
                optBtn.BackgroundColor3 = (opt == currentSelection) and Color3.fromRGB(34, 40, 54) or Color3.fromRGB(18, 21, 28)
                optBtn.BorderSizePixel = 0
                optBtn.Font = Enum.Font.Gotham
                optBtn.Text = "   " .. tostring(opt)
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
        end
        rebuildOptions()

        headerBtn.MouseButton1Click:Connect(function()
            isExpanded = not isExpanded
            chevron.Text = isExpanded and "▴" or "▾"
            local targetH = isExpanded and (48 + (#options * 31)) or 42
            rebuildOptions()
            tween(card, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, targetH)})
        end)

        local dropdownObj = {
            Instance = card,
            Value = currentSelection,
            Set = function(val)
                currentSelection = val
                selectionPill.Text = tostring(val)
                pcall(cb, val)
            end,
            Refresh = function(newOpts)
                options = newOpts or {}
                rebuildOptions()
            end
        }
        return dropdownObj
    end

    createMultiDropdown = function(parent, titleText, optionsList, defaultSelected, callback)
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

        local headerBtn = Instance.new("TextButton")
        headerBtn.Name = "HeaderButton"
        headerBtn.Size = UDim2.new(1, 0, 0, 42)
        headerBtn.BackgroundTransparency = 1
        headerBtn.Text = ""
        headerBtn.Parent = card

        local titleLabel = Instance.new("TextLabel")
        titleLabel.Name = "Label"
        titleLabel.Size = UDim2.new(0.48, 0, 1, 0)
        titleLabel.Position = UDim2.new(0, 14, 0, 0)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Font = Enum.Font.Gotham
        titleLabel.Text = tostring(titleText)
        titleLabel.TextColor3 = DEFAULT_THEME.TextPrimary
        titleLabel.TextSize = 12
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.Parent = headerBtn

        local selectionPill = Instance.new("TextLabel")
        selectionPill.Name = "Pill"
        selectionPill.Size = UDim2.new(0.52, -42, 0, 24)
        selectionPill.Position = UDim2.new(0.48, 0, 0.5, -12)
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
                local optStr = tostring(opt)
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
            Refresh = function(newOpts)
                options = newOpts or {}
                buildOptions()
                updatePillText()
            end
        }
    end

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
    end

    -- =========================================================================
    -- Built-in Hub Settings Tab (Exclusive System Controls, NO Universal Cheats)
    -- =========================================================================
    local settingsPage = nil
    local function ensureSettingsTab()
        if settingsPage then return end
        settingsPage = createTab("Settings", { Icon = "⚙", Size = 16 })

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

    return Hub
end
