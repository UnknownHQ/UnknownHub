--[[
    ========================================================================
    UNKNOWN LIBRARY — V2.0 ULTRA-CLEAN MODERN MINIMAL DARK UI
    Engineered exclusively for Unknown Hub
    Aesthetic: Refined Dark Slate & Matte Glass (Obsidian-Free, Slop-Free)
    ========================================================================
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local StatsService = game:GetService("Stats")

-- =========================================================================
-- Theme & Styling Constants
-- =========================================================================
local DEFAULT_THEME = {
    Primary = Color3.fromRGB(245, 142, 32),       -- Vibrant Electric Amber
    Secondary = Color3.fromRGB(0, 195, 245),     -- Cyber Cyan
    Background = Color3.fromRGB(14, 16, 22),     -- Deep Matte Midnight Slate
    Sidebar = Color3.fromRGB(18, 21, 28),        -- Elevated Sidebar Panel
    Card = Color3.fromRGB(23, 27, 36),           -- Control Card Surface
    CardHover = Color3.fromRGB(29, 34, 46),      -- Control Card Hover Surface
    Input = Color3.fromRGB(16, 19, 25),          -- Embedded Input Track
    Stroke = Color3.fromRGB(36, 42, 56),         -- Razor-sharp 1px Border
    StrokeActive = Color3.fromRGB(245, 142, 32), -- Focus/Active Stroke
    TextPrimary = Color3.fromRGB(245, 248, 252),  -- High-contrast Off-White
    TextSecondary = Color3.fromRGB(150, 162, 182),-- Muted Slate Gray
    TextDim = Color3.fromRGB(105, 115, 135),     -- Subtle Placeholders / Subtext
    Success = Color3.fromRGB(50, 205, 120),
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

    -- Mobile Adaptation
    local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
    local winWidth = isMobile and 580 or 660
    local winHeight = isMobile and 400 or 450

    -- =========================================================================
    -- Main Window Shell
    -- =========================================================================
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainWindow"
    mainFrame.Size = UDim2.new(0, winWidth, 0, winHeight)
    mainFrame.Position = UDim2.new(0.5, -math.floor(winWidth / 2), 0.5, -math.floor(winHeight / 2))
    mainFrame.BackgroundColor3 = DEFAULT_THEME.Background
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = false
    mainFrame.Active = true
    mainFrame.Parent = screenGui
    applyCorner(mainFrame, 12)
    local mainStroke = applyStroke(mainFrame, DEFAULT_THEME.Stroke, 1, 0.25)

    -- Soft Depth Glow Shadow
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "DropShadow"
    shadow.Size = UDim2.new(1, 40, 1, 40)
    shadow.Position = UDim2.new(0, -20, 0, -20)
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://6015897843"
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = 0.45
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(49, 49, 450, 450)
    shadow.ZIndex = -1
    shadow.Parent = mainFrame

    -- Inner Container for Clean Clipping
    local innerClip = Instance.new("Frame")
    innerClip.Name = "InnerClip"
    innerClip.Size = UDim2.new(1, 0, 1, 0)
    innerClip.BackgroundTransparency = 1
    innerClip.ClipsDescendants = true
    innerClip.Parent = mainFrame
    applyCorner(innerClip, 12)

    -- =========================================================================
    -- Sidebar (Left Navigation)
    -- =========================================================================
    local SIDEBAR_WIDTH = 180
    local sidebar = Instance.new("Frame")
    sidebar.Name = "Sidebar"
    sidebar.Size = UDim2.new(0, SIDEBAR_WIDTH, 1, 0)
    sidebar.Position = UDim2.new(0, 0, 0, 0)
    sidebar.BackgroundColor3 = DEFAULT_THEME.Sidebar
    sidebar.BorderSizePixel = 0
    sidebar.Parent = innerClip

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
    brandLogo.TextSize = 18
    brandLogo.Parent = brandFrame

    local brandTitle = Instance.new("TextLabel")
    brandTitle.Name = "Title"
    brandTitle.Size = UDim2.new(1, -44, 0, 18)
    brandTitle.Position = UDim2.new(0, 42, 0, 12)
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
    brandSubtitle.Size = UDim2.new(1, -44, 0, 14)
    brandSubtitle.Position = UDim2.new(0, 42, 0, 30)
    brandSubtitle.BackgroundTransparency = 1
    brandSubtitle.Font = Enum.Font.GothamMedium
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
    tabPadding.PaddingLeft = UDim.new(0, 10)
    tabPadding.PaddingRight = UDim.new(0, 10)
    tabPadding.PaddingTop = UDim.new(0, 4)
    tabPadding.PaddingBottom = UDim.new(0, 4)
    tabPadding.Parent = tabScroll

    -- Sidebar Footer Info (Status / FPS)
    local sidebarFooter = Instance.new("Frame")
    sidebarFooter.Name = "SidebarFooter"
    sidebarFooter.Size = UDim2.new(1, -20, 0, 32)
    sidebarFooter.Position = UDim2.new(0, 10, 1, -38)
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
    statusText.Font = Enum.Font.GothamMedium
    statusText.Text = "Connected • 60 FPS"
    statusText.TextColor3 = DEFAULT_THEME.TextSecondary
    statusText.TextSize = 10
    statusText.TextXAlignment = Enum.TextXAlignment.Left
    statusText.Parent = sidebarFooter

    -- FPS updater
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
    local HEADER_HEIGHT = 46
    local header = Instance.new("Frame")
    header.Name = "HeaderBar"
    header.Size = UDim2.new(1, -SIDEBAR_WIDTH, 0, HEADER_HEIGHT)
    header.Position = UDim2.new(0, SIDEBAR_WIDTH, 0, 0)
    header.BackgroundTransparency = 1
    header.Parent = innerClip

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
    keybindPill.Font = Enum.Font.GothamMedium
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
    contentArea.Parent = innerClip

    -- =========================================================================
    -- Dragging Mechanics (Silky Smooth)
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
    -- Minimize / Collapse & GUI Toggle Actions
    -- =========================================================================
    local isMinimized = false
    local isGuiVisible = true

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
        isGuiVisible = visible
        if visible then
            mainFrame.Visible = true
            mainFrame.Size = UDim2.new(0, math.floor(winWidth * 0.95), 0, math.floor(winHeight * 0.95))
            tween(mainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, winWidth, 0, isMinimized and HEADER_HEIGHT or winHeight)
            })
        else
            local tw = tween(mainFrame, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Size = UDim2.new(0, math.floor(winWidth * 0.95), 0, math.floor(winHeight * 0.95))
            })
            tw.Completed:Connect(function()
                if not isGuiVisible then mainFrame.Visible = false end
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
                tween(t.Button, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {BackgroundColor3 = DEFAULT_THEME.Card, TextColor3 = DEFAULT_THEME.TextPrimary})
                t.Indicator.Visible = true
                tween(t.Indicator, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {BackgroundTransparency = 0})
            else
                tween(t.Button, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {BackgroundColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 1, TextColor3 = DEFAULT_THEME.TextSecondary})
                t.Indicator.Visible = false
            end
        end
    end

    -- Forward declarations of component builders
    local createToggle, createSlider, createDropdown, createButton, createTextBox, createSection, createList

    -- Tab Builder
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
        tabBtn.Font = Enum.Font.GothamMedium
        tabBtn.Text = "     " .. tostring(tabName)
        tabBtn.TextColor3 = DEFAULT_THEME.TextSecondary
        tabBtn.TextSize = 12
        tabBtn.TextXAlignment = Enum.TextXAlignment.Left
        tabBtn.AutoButtonColor = false
        tabBtn.Parent = tabScroll
        applyCorner(tabBtn, 8)

        local iconLbl = Instance.new("TextLabel")
        iconLbl.Name = "Icon"
        iconLbl.Size = UDim2.new(0, 20, 1, 0)
        iconLbl.Position = UDim2.new(0, 10, 0, 0)
        iconLbl.BackgroundTransparency = 1
        iconLbl.Font = Enum.Font.GothamBold
        iconLbl.Text = tabIcon
        iconLbl.TextColor3 = primaryTheme
        iconLbl.TextSize = 13
        iconLbl.Parent = tabBtn

        local activeIndicator = Instance.new("Frame")
        activeIndicator.Name = "Indicator"
        activeIndicator.Size = UDim2.new(0, 3, 0, 18)
        activeIndicator.Position = UDim2.new(0, 2, 0.5, -9)
        activeIndicator.BackgroundColor3 = primaryTheme
        activeIndicator.BorderSizePixel = 0
        activeIndicator.Visible = false
        activeIndicator.Parent = tabBtn
        applyCorner(activeIndicator, 2)

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
            Indicator = activeIndicator,
            Page = pageScroll
        }
        table.insert(tabs, tabRecord)

        tabBtn.MouseEnter:Connect(function()
            if activeTab ~= tabRecord then
                tween(tabBtn, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {BackgroundColor3 = DEFAULT_THEME.CardHover, BackgroundTransparency = 0.5, TextColor3 = DEFAULT_THEME.TextPrimary})
            end
        end)
        tabBtn.MouseLeave:Connect(function()
            if activeTab ~= tabRecord then
                tween(tabBtn, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {BackgroundTransparency = 1, TextColor3 = DEFAULT_THEME.TextSecondary})
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
        tabRecord.CreateButton = function(name, callback) return createButton(pageScroll, name, callback) end
        tabRecord.CreateTextBox = function(name, placeholder, callback) return createTextBox(pageScroll, name, placeholder, callback) end
        tabRecord.CreateInput = tabRecord.CreateTextBox
        tabRecord.CreateList = function(name, items, height, expanded, selectionOptions, callback) return createList(pageScroll, name, items, height, expanded, selectionOptions, callback) end

        return pageScroll
    end

    -- =========================================================================
    -- Component 1: Section Header
    -- =========================================================================
    createSection = function(parent, titleText)
        local container = Instance.new("Frame")
        container.Name = "Section_" .. tostring(titleText)
        container.Size = UDim2.new(1, 0, 0, 24)
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
    -- Component 2: Toggle Switch
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
        titleLabel.Font = Enum.Font.GothamMedium
        titleLabel.Text = tostring(titleText)
        titleLabel.TextColor3 = DEFAULT_THEME.TextPrimary
        titleLabel.TextSize = 12
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
        titleLabel.Parent = card

        -- Switch Pill
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

        -- Trigger on track or whole card click
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
        titleLabel.Font = Enum.Font.GothamMedium
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
        valBadge.Font = Enum.Font.GothamBold
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

        local function updateSlider(alpha, skipCallback)
            alpha = math.clamp(alpha, 0, 1)
            local range = maxVal - minVal
            local rawVal = minVal + (alpha * range)

            -- Format depending on range
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

        -- Initial layout
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
        card.Font = Enum.Font.GothamMedium
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
        titleLabel.Font = Enum.Font.GothamMedium
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
        selectionPill.Font = Enum.Font.GothamMedium
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
                optBtn.Font = Enum.Font.GothamMedium
                optBtn.Text = "   " .. tostring(opt)
                optBtn.TextColor3 = (opt == currentSelection) and primaryTheme or DEFAULT_THEME.TextSecondary
                optBtn.TextSize = 11
                optBtn.TextXAlignment = Enum.TextXAlignment.Left
                optBtn.AutoButtonColor = false
                optBtn.Parent = optionsContainer
                applyCorner(optBtn, 5)

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

    -- =========================================================================
    -- Component 6: TextBox / Input Card
    -- =========================================================================
    createTextBox = function(parent, titleText, placeholderText, callback)
        local cb = type(callback) == "function" and callback or function() end

        local card = Instance.new("Frame")
        card.Name = "InputCard_" .. tostring(titleText)
        card.Size = UDim2.new(1, 0, 0, 42)
        card.BackgroundColor3 = DEFAULT_THEME.Card
        card.BorderSizePixel = 0
        card.Parent = parent
        applyCorner(card, 8)
        applyStroke(card, DEFAULT_THEME.Stroke, 1, 0.3)

        local titleLabel = Instance.new("TextLabel")
        titleLabel.Name = "Label"
        titleLabel.Size = UDim2.new(0.5, 0, 1, 0)
        titleLabel.Position = UDim2.new(0, 14, 0, 0)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Font = Enum.Font.GothamMedium
        titleLabel.Text = tostring(titleText)
        titleLabel.TextColor3 = DEFAULT_THEME.TextPrimary
        titleLabel.TextSize = 12
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.Parent = card

        local boxFrame = Instance.new("Frame")
        boxFrame.Name = "BoxFrame"
        boxFrame.Size = UDim2.new(0.5, -28, 0, 26)
        boxFrame.Position = UDim2.new(0.5, 0, 0.5, -13)
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
    -- Component 7: List & Nested Lists (BeeSwarm & BloxFruits Compatible)
    -- =========================================================================
    createList = function(parent, titleText, itemsList, maxHeight, expandedState, selectionOptions, extraCallback)
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
        titleLabel.Font = Enum.Font.GothamMedium
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
        countBadge.Font = Enum.Font.GothamBold
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
            local contentHeight = listLayout.AbsoluteContentSize.Y
            local targetH = isExpanded and math.min(contentHeight + 52, tonumber(maxHeight) or 220) or 40
            chevron.Text = isExpanded and "▴" or "▾"
            countBadge.Text = tostring(#listObj.Items)
            tween(card, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, targetH)})
        end

        headerBtn.MouseButton1Click:Connect(function()
            isExpanded = not isExpanded
            updateListVisuals()
        end)

        function listObj.AddItem(text, subtext, itemCallback)
            local itmBtn = Instance.new("TextButton")
            itmBtn.Name = "Item_" .. tostring(text)
            itmBtn.Size = UDim2.new(1, 0, 0, 28)
            itmBtn.BackgroundColor3 = Color3.fromRGB(18, 21, 28)
            itmBtn.BorderSizePixel = 0
            itmBtn.Font = Enum.Font.GothamMedium
            itmBtn.Text = "   " .. tostring(text)
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

        -- Populate initial items
        for _, itm in ipairs(items) do
            listObj.AddItem(itm)
        end

        return listObj
    end

    -- =========================================================================
    -- Component 8: Loop Toggle (Game Automation Helper)
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
    -- Component 9: Modal Warning Dialog
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
        b1.Font = Enum.Font.GothamMedium
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
        b2.Font = Enum.Font.GothamMedium
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

    -- Core GUI Elements
    Hub.screenGui = screenGui
    Hub.gui = screenGui
    Hub.mainFrame = mainFrame
    Hub.frame = mainFrame
    Hub.content = contentArea

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

    Hub.CreateButton = createButton
    Hub.createButton = createButton

    Hub.CreateTextBox = createTextBox
    Hub.createTextBox = createTextBox
    Hub.CreateInput = createTextBox
    Hub.createInput = createTextBox

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
    Hub.finishLoading = function(msg)
        if msg then sendNotification("Unknown Hub", tostring(msg), 3) end
    end
    Hub.FinishLoading = Hub.finishLoading

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

    return Hub
end
