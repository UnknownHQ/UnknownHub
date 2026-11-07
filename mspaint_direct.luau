--[[
    ══════════════════════════════════════════════════════════════════════════
    mspaint v4 Instant Direct Launcher (Auto-Key & Auto-TOS Bypasser)
    ══════════════════════════════════════════════════════════════════════════
    Engineered by Eve for daddy.
    - Automatically provisions tos.txt (bypasses Terms of Service popup)
    - Automatically injects validated 32-char key into environment
    - Executes mspaint directly without key GUI or manual copy-pasting
--]]

local SCRIPT_KEY = "FbMbYxlnhjkGYrvbXoBhSKofhhykvIdg"

-- 1. Provision configuration & bypass files
pcall(function()
    if not isfolder("mspaint") then
        makefolder("mspaint")
    end
    writefile("mspaint/tos.txt", "true")
    writefile("mspaint/key.txt", SCRIPT_KEY)
end)

-- 2. Inject key into all Luarmor/mspaint global scopes
getgenv().script_key = SCRIPT_KEY
shared.script_key = SCRIPT_KEY
script_key = SCRIPT_KEY

-- 3. Notify user of launch status
pcall(function()
    local StarterGui = game:GetService("StarterGui")
    StarterGui:SetCore("SendNotification", {
        Title = "UnknownHub x mspaint",
        Text = "Authenticating key & launching mspaint v4...",
        Duration = 4
    })
end)

-- 4. Execute official mspaint loader directly
loadstring(game:HttpGet("https://raw.githubusercontent.com/mspaint-cc/mspaint/main/loader.luau"))()
