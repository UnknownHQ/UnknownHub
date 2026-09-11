--[[
    ========================================================================
    Unknown Hub - Universal Smart Loader
    Auto-detects active game and initializes tailored scripts or universal suite.
    ========================================================================
]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId

local BASE_URL = "https://raw.githubusercontent.com/dontknow228xd-bot/UnknownHub/main"

local GameScripts = {
    -- Bee Swarm Simulator
    [1537690962] = BASE_URL .. "/Games/BeeSwarm.luau",
    
    -- Blox Fruits (Sea 1, Sea 2, Sea 3)
    [2753915549] = BASE_URL .. "/Games/BloxFruits.luau",
    [4442272183] = BASE_URL .. "/Games/BloxFruits.luau",
    [7449423635] = BASE_URL .. "/Games/BloxFruits.luau",
    
    -- Ink Game / Squid Games
    [17625359962] = BASE_URL .. "/Games/InkGame.luau",
    [17625126838] = BASE_URL .. "/Games/InkGame.luau",
}

local function safeLoad(url)
    local ok, source = pcall(function()
        return game:HttpGet(url .. "?t=" .. tostring(os.time()))
    end)
    if not ok or not source or source == "" then
        warn("[UnknownHub] Failed to fetch script from: " .. tostring(url))
        return false
    end
    local fn, compileErr = loadstring(source)
    if not fn then
        warn("[UnknownHub] Compile error in script: " .. tostring(compileErr))
        return false
    end
    local execOk, runtimeErr = pcall(fn)
    if not execOk then
        warn("[UnknownHub] Runtime error in script: " .. tostring(runtimeErr))
        return false
    end
    return true
end

print("[UnknownHub] Initializing Universal Loader for PlaceId: " .. tostring(PlaceId))

local targetUrl = GameScripts[PlaceId]
if targetUrl then
    print("[UnknownHub] Game-specific script detected! Loading: " .. targetUrl)
    safeLoad(targetUrl)
else
    print("[UnknownHub] No dedicated script for this game. Loading Universal Core...")
    local ok, libSource = pcall(function()
        return game:HttpGet(BASE_URL .. "/UnknownLibrary?t=" .. tostring(os.time()))
    end)
    if ok and libSource then
        local libFactory = loadstring(libSource)
        if libFactory then
            local Hub = libFactory()({
                title = "UNKNOWN HUB",
                theme = Color3.fromRGB(0, 195, 245),
                secondaryTheme = Color3.fromRGB(165, 95, 255)
            })
            print("[UnknownHub] Universal Hub loaded successfully!")
        end
    end
end
