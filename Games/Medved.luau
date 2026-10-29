--[[
    ========================================================================
    Unknown Hub - Medved! Game Module
    Target: Medved!
    Architecture: UnknownLibrary Modular Interface
    Status: Clean Shell Initialized (Awaiting feature specifications from daddy)
    ========================================================================
]]

local LIBRARY_LINK = "https://raw.githubusercontent.com/UnknownHQ/UnknownHub/main/UnknownLibrary"

local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Anti-AFK Safeguard
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

-- Fetch UnknownLibrary
local function loadLibrary()
    local ok, res = pcall(function()
        return game:HttpGet(LIBRARY_LINK .. "?t=" .. tostring(os.time()))
    end)
    if ok and res and res ~= "" then
        local fn, err = loadstring(res)
        if fn then return fn() end
        warn("[UnknownHub] Library compile error: " .. tostring(err))
    end
    return nil
end

local library = loadLibrary()
if not library then
    warn("[UnknownHub] Failed to load UnknownLibrary for Medved!")
    return
end

-- Initialize Window
local window = library({
    title = "UNKNOWN HUB • MEDVED!",
    theme = Color3.fromRGB(0, 195, 245),
    secondaryTheme = Color3.fromRGB(165, 95, 255)
})

-- Main Tab (Clean shell ready for farming/game mechanics)
local mainTab = window:CreateTab("Main", "🐻")
mainTab:CreateSection("Module Info")
mainTab:CreateParagraph({
    Title = "Medved! Framework Loaded",
    Content = "Clean shell initialized and mapped to Unknown Hub loader. Awaiting feature specifications from daddy."
})

-- Settings / Misc Tab
local miscTab = window:CreateTab("Misc", "⚙️")
miscTab:CreateSection("Utilities")
miscTab:CreateButton({
    Name = "Rejoin Server",
    Callback = function()
        if getgenv().rejoin then
            getgenv().rejoin()
        else
            game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
        end
    end
})
