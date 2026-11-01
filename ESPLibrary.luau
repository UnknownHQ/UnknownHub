-- =========================================================================
-- UnknownHub Universal ESP Library (V2.0 Core)
-- High-Performance 2D & 3D Entity / Player / Object Spatial Rendering
-- Procedural Rounded-Corner Models for 2D Entities + Sleek Chams for 3D Rigs
-- =========================================================================

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local UnknownESP = {
    Enabled = true,
    ShowDistance = true,
    ShowTracers = false,
    ShowBoxes = true,
    ShowHighlights = true,
    MaxDistance = 500,
    Categories = {
        ["Entities"] = true,
        ["Players"] = true,
        ["Items"] = true,
        ["Doors"] = true,
        ["Objectives"] = true,
    },
    Entity2DNames = {
        ["rush"] = true,
        ["ambush"] = true,
        ["eyes"] = true,
        ["lookman"] = true,
        ["screech"] = true,
        ["halt"] = true,
        ["shade"] = true,
        ["a-60"] = true,
        ["a60"] = true,
        ["a-90"] = true,
        ["a90"] = true,
        ["a-120"] = true,
        ["a120"] = true,
        ["dread"] = true,
        ["blitz"] = true,
        ["vacuum"] = true,
        ["surge"] = true,
        ["glitch"] = true,
        ["void"] = true,
        ["shadow"] = true,
        ["depth"] = true,
        ["silence"] = true,
        ["greed"] = true,
    },
    Records = {},
    Connections = {},
}

-- Ensure container for GUI visuals exists in CoreGui or PlayerGui
local guiContainer = CoreGui:FindFirstChild("UnknownHub_ESP_Container")
if not guiContainer then
    local pcallOk = pcall(function()
        guiContainer = Instance.new("Folder")
        guiContainer.Name = "UnknownHub_ESP_Container"
        guiContainer.Parent = CoreGui
    end)
    if not pcallOk or not guiContainer then
        guiContainer = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("UnknownHub_ESP_Container")
        if not guiContainer then
            guiContainer = Instance.new("Folder")
            guiContainer.Name = "UnknownHub_ESP_Container"
            guiContainer.Parent = LocalPlayer.PlayerGui
        end
    end
end

-- =========================================================================
-- Helper: Detect if an entity is 2D (Sprite / Billboard / Flat entity)
-- =========================================================================
function UnknownESP.Is2DEntity(instance, customName)
    if not instance then return false end
    local name = (customName or instance.Name):lower()
    for k in pairs(UnknownESP.Entity2DNames) do
        if name:find(k) then return true end
    end
    -- Dynamic check: If instance has no Humanoid and no 3D humanoid limbs, treat as 2D sprite/billboard entity
    if instance:IsA("Model") then
        local hum = instance:FindFirstChildOfClass("Humanoid")
        if not hum and not instance:FindFirstChild("Head") and not instance:FindFirstChild("Torso") then
            return true
        end
    elseif instance:IsA("BasePart") then
        return true
    end
    return false
end

-- =========================================================================
-- Procedural 3D Rounded-Corner Model (Weld-Tracked to Entity in Real-Time)
-- =========================================================================
function UnknownESP.CreateRoundedCube(targetPart, size, radius, color)
    if not targetPart or not targetPart.Parent then return nil end
    local model = Instance.new("Model")
    model.Name = "Unknown_RoundedCube"

    local s = size or 5.0
    local r = radius or 0.85
    local inner = math.max(s - 2 * r, 0.5)
    local d = 2 * r

    -- Central core block
    local core = Instance.new("Part")
    core.Name = "Core"
    core.Size = Vector3.new(inner, inner, inner)
    core.Color = color or Color3.fromRGB(255, 50, 50)
    core.Transparency = 0.45
    core.Material = Enum.Material.SmoothPlastic
    core.CanCollide = false
    core.CanTouch = false
    core.CanQuery = false
    core.Massless = true
    core.CastShadow = false
    core.Anchored = false
    core.CFrame = targetPart.CFrame
    core.Parent = model

    -- Weld Core to TargetPart so it follows entity dynamically!
    local coreWeld = Instance.new("WeldConstraint")
    coreWeld.Part0 = core
    coreWeld.Part1 = targetPart
    coreWeld.Parent = core

    local faceConfigs = {
        { size = Vector3.new(inner, inner, r), offset = Vector3.new(0, 0, inner/2 + r/2) },
        { size = Vector3.new(inner, inner, r), offset = Vector3.new(0, 0, -(inner/2 + r/2)) },
        { size = Vector3.new(inner, r, inner), offset = Vector3.new(0, inner/2 + r/2, 0) },
        { size = Vector3.new(inner, r, inner), offset = Vector3.new(0, -(inner/2 + r/2), 0) },
        { size = Vector3.new(r, inner, inner), offset = Vector3.new(inner/2 + r/2, 0, 0) },
        { size = Vector3.new(r, inner, inner), offset = Vector3.new(-(inner/2 + r/2), 0, 0) },
    }
    for i, cfg in ipairs(faceConfigs) do
        local face = Instance.new("Part")
        face.Name = "Face_" .. i
        face.Size = cfg.size
        face.Color = color or Color3.fromRGB(255, 50, 50)
        face.Transparency = 0.45
        face.Material = Enum.Material.SmoothPlastic
        face.CanCollide = false
        face.CanTouch = false
        face.CanQuery = false
        face.Massless = true
        face.CastShadow = false
        face.Anchored = false
        face.CFrame = core.CFrame * CFrame.new(cfg.offset)
        face.Parent = model

        local w = Instance.new("WeldConstraint")
        w.Part0 = face
        w.Part1 = core
        w.Parent = face
    end

    local signs = {-1, 1}
    for _, sx in ipairs(signs) do
        for _, sy in ipairs(signs) do
            for _, sz in ipairs(signs) do
                local sphere = Instance.new("Part")
                sphere.Name = "CornerSphere"
                sphere.Shape = Enum.PartType.Ball
                sphere.Size = Vector3.new(d, d, d)
                sphere.Color = color or Color3.fromRGB(255, 50, 50)
                sphere.Transparency = 0.45
                sphere.Material = Enum.Material.SmoothPlastic
                sphere.CanCollide = false
                sphere.CanTouch = false
                sphere.CanQuery = false
                sphere.Massless = true
                sphere.CastShadow = false
                sphere.Anchored = false
                sphere.CFrame = core.CFrame * CFrame.new(sx * (inner/2), sy * (inner/2), sz * (inner/2))
                sphere.Parent = model

                local w = Instance.new("WeldConstraint")
                w.Part0 = sphere
                w.Part1 = core
                w.Parent = sphere
            end
        end
    end

    -- X-axis edges
    for _, sy in ipairs(signs) do
        for _, sz in ipairs(signs) do
            local cyl = Instance.new("Part")
            cyl.Name = "Edge_X"
            cyl.Shape = Enum.PartType.Cylinder
            cyl.Size = Vector3.new(inner, d, d)
            cyl.Color = color or Color3.fromRGB(255, 50, 50)
            cyl.Transparency = 0.45
            cyl.Material = Enum.Material.SmoothPlastic
            cyl.CanCollide = false
            cyl.CanTouch = false
            cyl.CanQuery = false
            cyl.Massless = true
            cyl.CastShadow = false
            cyl.Anchored = false
            cyl.CFrame = core.CFrame * CFrame.new(0, sy * (inner/2), sz * (inner/2)) * CFrame.Angles(0, 0, math.rad(90))
            cyl.Parent = model

            local w = Instance.new("WeldConstraint")
            w.Part0 = cyl
            w.Part1 = core
            w.Parent = cyl
        end
    end

    -- Y-axis edges
    for _, sx in ipairs(signs) do
        for _, sz in ipairs(signs) do
            local cyl = Instance.new("Part")
            cyl.Name = "Edge_Y"
            cyl.Shape = Enum.PartType.Cylinder
            cyl.Size = Vector3.new(inner, d, d)
            cyl.Color = color or Color3.fromRGB(255, 50, 50)
            cyl.Transparency = 0.45
            cyl.Material = Enum.Material.SmoothPlastic
            cyl.CanCollide = false
            cyl.CanTouch = false
            cyl.CanQuery = false
            cyl.Massless = true
            cyl.CastShadow = false
            cyl.Anchored = false
            cyl.CFrame = core.CFrame * CFrame.new(sx * (inner/2), 0, sz * (inner/2))
            cyl.Parent = model

            local w = Instance.new("WeldConstraint")
            w.Part0 = cyl
            w.Part1 = core
            w.Parent = cyl
        end
    end

    -- Z-axis edges
    for _, sx in ipairs(signs) do
        for _, sy in ipairs(signs) do
            local cyl = Instance.new("Part")
            cyl.Name = "Edge_Z"
            cyl.Shape = Enum.PartType.Cylinder
            cyl.Size = Vector3.new(inner, d, d)
            cyl.Color = color or Color3.fromRGB(255, 50, 50)
            cyl.Transparency = 0.45
            cyl.Material = Enum.Material.SmoothPlastic
            cyl.CanCollide = false
            cyl.CanTouch = false
            cyl.CanQuery = false
            cyl.Massless = true
            cyl.CastShadow = false
            cyl.Anchored = false
            cyl.CFrame = core.CFrame * CFrame.new(sx * (inner/2), sy * (inner/2), 0) * CFrame.Angles(math.rad(90), 0, 0)
            cyl.Parent = model

            local w = Instance.new("WeldConstraint")
            w.Part0 = cyl
            w.Part1 = core
            w.Parent = cyl
        end
    end

    model.Parent = Workspace

    -- Backup RenderStepped pivot fallback in case physics interpolation lags
    local pivotConn
    pivotConn = RunService.RenderStepped:Connect(function()
        if not targetPart or not targetPart.Parent or not model.Parent then
            if pivotConn then pivotConn:Disconnect() end
            return
        end
        if (core.Position - targetPart.Position).Magnitude > 0.5 then
            model:PivotTo(targetPart.CFrame)
        end
    end)
    model.Destroying:Connect(function()
        if pivotConn then pivotConn:Disconnect() end
    end)

    return model
end

-- =========================================================================
-- Sleek Modern Billboard with Rounded Corners & Distance Badge
-- =========================================================================
function UnknownESP.CreateBillboard(adorneePart, name, color, offset)
    if not adorneePart or not adorneePart:IsA("BasePart") then return nil end

    local bb = Instance.new("BillboardGui")
    bb.Name = "Unknown_ESP_Billboard"
    bb.Adornee = adorneePart
    bb.Size = UDim2.new(0, 160, 0, 32)
    bb.StudsOffset = offset or Vector3.new(0, 2.8, 0)
    bb.AlwaysOnTop = true
    bb.LightInfluence = 0
    bb.ResetOnSpawn = false
    bb.MaxDistance = UnknownESP.MaxDistance

    -- Rounded Badge Container
    local container = Instance.new("Frame")
    container.Name = "Badge"
    container.Size = UDim2.new(1, 0, 1, 0)
    container.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    container.BackgroundTransparency = 0.35
    container.BorderSizePixel = 0
    container.Parent = bb

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 7)
    corner.Parent = container

    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Color3.fromRGB(0, 220, 255)
    stroke.Thickness = 1.2
    stroke.Transparency = 0.2
    stroke.Parent = container

    local label = Instance.new("TextLabel")
    label.Name = "Text"
    label.Size = UDim2.new(1, -8, 1, 0)
    label.Position = UDim2.new(0, 4, 0, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextSize = 13
    label.TextColor3 = color or Color3.fromRGB(255, 255, 255)
    label.TextStrokeTransparency = 0.4
    label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    label.Text = name or ""
    label.Parent = container

    bb.Parent = guiContainer
    return bb, label
end

-- =========================================================================
-- Sleek 3D Highlight / Chams
-- =========================================================================
function UnknownESP.CreateHighlight(targetInstance, color)
    if not targetInstance then return nil end
    local hl = Instance.new("Highlight")
    hl.Name = "Unknown_ESP_Highlight"
    hl.FillColor = color or Color3.fromRGB(255, 50, 50)
    hl.FillTransparency = 0.65
    hl.OutlineColor = color or Color3.fromRGB(255, 255, 255)
    hl.OutlineTransparency = 0.05
    hl.Adornee = targetInstance
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = guiContainer
    return hl
end

-- =========================================================================
-- Main API: Add Instance to ESP
-- =========================================================================
function UnknownESP.Add(instance, options)
    if not instance then return end
    options = options or {}

    local category = options.Category or "Entities"
    local name = options.Name or instance.Name
    local color = options.Color or Color3.fromRGB(255, 255, 255)
    local offset = options.Offset or Vector3.new(0, 2.5, 0)
    local is2D = options.Is2D
    if is2D == nil then
        is2D = UnknownESP.Is2DEntity(instance, name)
    end

    local targetPart = options.TargetPart
    if not targetPart then
        if instance:IsA("BasePart") then
            targetPart = instance
        elseif instance:IsA("Model") then
            targetPart = instance.PrimaryPart or instance:FindFirstChildWhichIsA("BasePart", true)
        end
    end

    if not targetPart then return end

    -- Clean up any previous registration for this instance
    UnknownESP.Remove(instance)

    local visuals = {}
    local highlightTarget = instance

    -- 2D Entities receive the custom 3D Rounded Cube Model!
    if is2D and (category == "Entities" or category == "Hazards") then
        local roundedCube = UnknownESP.CreateRoundedCube(targetPart, options.CubeSize or 5.2, options.CornerRadius or 0.85, color)
        if roundedCube then
            table.insert(visuals, roundedCube)
            highlightTarget = roundedCube
        end
    end

    -- Create Highlight
    if UnknownESP.ShowHighlights and (options.ShowHighlight ~= false) then
        local hl = UnknownESP.CreateHighlight(highlightTarget, color)
        if hl then table.insert(visuals, hl) end
    end

    -- Create Billboard
    local bb, textLabel
    if options.ShowBillboard ~= false then
        bb, textLabel = UnknownESP.CreateBillboard(targetPart, name, color, offset)
        if bb then table.insert(visuals, bb) end
    end

    local record = {
        Instance = instance,
        TargetPart = targetPart,
        BaseText = name,
        Category = category,
        Color = color,
        Visuals = visuals,
        TextLabel = textLabel,
        Billboard = bb,
        Is2D = is2D,
    }

    UnknownESP.Records[instance] = record
    return record
end

-- =========================================================================
-- Removal & Cleanup
-- =========================================================================
function UnknownESP.Remove(instance)
    if not instance then return end
    local rec = UnknownESP.Records[instance]
    if rec then
        for _, v in ipairs(rec.Visuals) do
            pcall(function() v:Destroy() end)
        end
        UnknownESP.Records[instance] = nil
    end
end

function UnknownESP.Clear(category)
    for inst, rec in pairs(UnknownESP.Records) do
        if not category or rec.Category == category then
            UnknownESP.Remove(inst)
        end
    end
end

-- =========================================================================
-- Continuous Distance & Visibility Updater Loop
-- =========================================================================
if UnknownESP.UpdaterConn then
    UnknownESP.UpdaterConn:Disconnect()
end

UnknownESP.UpdaterConn = RunService.RenderStepped:Connect(function()
    if not UnknownESP.Enabled then return end
    local cam = Workspace.CurrentCamera
    local camPos = cam and cam.CFrame.Position
    if not camPos then return end

    for inst, rec in pairs(UnknownESP.Records) do
        if not inst or not inst.Parent or not rec.TargetPart or not rec.TargetPart.Parent then
            UnknownESP.Remove(inst)
        else
            local catEnabled = UnknownESP.Categories[rec.Category] ~= false
            if rec.Billboard then
                rec.Billboard.Enabled = catEnabled and UnknownESP.Enabled
            end

            if catEnabled and UnknownESP.ShowDistance and rec.TextLabel then
                local dist = math.floor((rec.TargetPart.Position - camPos).Magnitude)
                rec.TextLabel.Text = string.format("%s [%dm]", rec.BaseText, dist)
            elseif rec.TextLabel then
                rec.TextLabel.Text = rec.BaseText
            end
        end
    end
end)

-- Global exposure
getgenv().UnknownESP = UnknownESP
_G.UnknownESP = UnknownESP

return UnknownESP
