# 🌊 Unknown Hub & UI Library

<div align="center">

![Unknown Hub Banner](https://raw.githubusercontent.com/UnknownHQ/UnknownHub/main/unknown_hub_avatar.jpg)

**Next-Generation Responsive Ocean UI Library & Universal Game Automation Framework for Roblox**

[![Lua 5.1 / Luau](https://img.shields.io/badge/Language-Luau%20%7C%20Lua%205.1-00A2FF?style=for-the-badge&logo=lua)](https://luau-lang.org/)
[![Platform](https://img.shields.io/badge/Platform-PC%20%2F%20Mobile-7B2CBF?style=for-the-badge)](https://roblox.com)
[![Status](https://img.shields.io/badge/Status-Active%20%26%20Protected-38EF7D?style=for-the-badge)](https://github.com/UnknownHQ/UnknownHub)
[![License](https://img.shields.io/badge/License-MIT-FFB703?style=for-the-badge)](LICENSE)

</div>

---

## ⚡ Quick Start & Loadstrings

### 🌐 1. Universal Smart Loader (Auto Game Detection)
Loads game-tailored scripts if supported (e.g. *Bee Swarm Simulator*), otherwise launches the **Universal Core Suite**:
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/UnknownHQ/UnknownHub/main/Loader.luau"))()
```

### 📦 2. Raw UI Library (For Developers)
Use Unknown Hub as a high-performance UI library in your own custom scripts:
```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/UnknownHQ/UnknownHub/main/UnknownLibrary"))()
```

---

## ✨ Key Features

### 🎨 Visuals & Aesthetics
- **🌊 Responsive Ocean Wave Engine:** Dual animated sine waves with phase offset, depth shading, and star twinkle effects.
- **🌈 Live Theme Palette Editor:** 16 dual-tone split gradient presets + HSV saturation/value color picker with instant real-time live preview.
- **🔊 Sound Packs:** Modern chime, Mechanical click, Cyberpunk beep, Bubble pop, or Mute.
- **📱 Full Mobile Support:** Draggable quick action floating bubble (⚡), touch-optimized slider and drag interactions.

### 🛡️ Session & AFK Protection
- **🛡️ 24/7 Anti-AFK Engine:** Intercepts `LocalPlayer.Idled` and simulates controller heartbeats to neutralize Roblox's 20-minute idle disconnect kick.
- **🔄 Persistent Auto-Rejoin:** Intercepts Error 277/268, disconnected prompts, and bad internet, continuously retrying teleportation until you're back in the server.
- **🥔 Potato Mode:** Strips heavy lighting post-processing, removes shadows, fog, and particle emitters for max FPS.
- **🖥️ 3D Rendering Disabler:** Drops GPU usage to ~0% for heavy background overnight farming.

### 🪝 Developer Tools & Discord Webhook
- **🪝 First-Class Webhook API (`createWebhook`):** Send simple messages, rich embeds, or automated live progression reports every X seconds.
- **💻 Built-in Luau Console:** Execute code snippets live and view instant output and error traces.
- **⭐ Favorites System:** Pin frequently used toggles/actions to a dedicated Favorites tab with right-click or hold.
- **📁 Configuration Manager:** Save, load, overwrite, and auto-apply named configuration profiles to disk.

---

## 📖 Developer API Reference

### 1. Creating the Window
```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/UnknownHQ/UnknownHub/main/UnknownLibrary"))()

local Hub = Library({
    name = "MyCustomHub",
    title = "UNKNOWN HUB",
    theme = Color3.fromRGB(0, 195, 245),
    secondaryTheme = Color3.fromRGB(165, 95, 255),
    toggleKey = Enum.KeyCode.RightControl
})
```

### 2. Tabs & Sections
```lua
local MainTab = Hub.createTabButton("Main", "Main", "rbxassetid://10723407389", true)
Hub.createSection(MainTab, "Farming & Automation")
```

### 3. Interactive UI Elements
```lua
-- Toggle
Hub.createToggle(MainTab, "Auto Farm", false, function(state)
    print("Auto Farm is now:", state)
end)

-- Button
Hub.createButton(MainTab, "Teleport to Safezone", function()
    print("Teleported!")
end)

-- Slider
Hub.createSlider(MainTab, "Speed Multiplier", 1, 100, 16, " studs/s", function(val)
    print("New Speed:", val)
end)

-- Dropdown
Hub.createDropdown(MainTab, "Select Area", {"Sunflower", "Dandelion", "Pine Tree", "Cactus"}, "Sunflower", function(selected)
    print("Area selected:", selected)
end)

-- Text Box
local input = Hub.createTextBox(MainTab, "Enter Target Name", "DefaultPlayer", function(text)
    print("Target updated to:", text)
end)
```

### 4. Discord Webhook & Live Progression API
```lua
local hook = Hub.createWebhook({
    Url = "https://discord.com/api/webhooks/YOUR_WEBHOOK_URL",
    BotName = "Unknown Hub",
    BotAvatar = "https://i.imgur.com/8Q5Fq7f.png"
})

-- Send custom embed
hook:Send("🍯 Farm Session Update", "Player has collected 500M Honey", {
    { name = "Player", value = game.Players.LocalPlayer.Name, inline = true },
    { name = "Uptime", value = math.floor(workspace.DistributedGameTime) .. "s", inline = true }
}, 0x00A2FF)

-- Automated background progression report every 60 seconds
hook:StartAutoReport(60, function()
    return {
        Title = "📊 Auto Farm Stats",
        Description = "Live stats from client",
        Fields = {
            { name = "Pollen Bag", value = "80%", inline = true },
            { name = "Current Honey", value = "1,500,000,000", inline = true }
        },
        Color = 0x38EF7D
    }
end)
```

### 5. Toast Notifications
```lua
Hub.notify({
    Title = "Farm Alert",
    Content = "Inventory is full! Converting honey...",
    Duration = 5,
    Color = Color3.fromRGB(0, 210, 255)
})
```

---

## 📜 Supported Games
- **[Bee Swarm Simulator](https://www.roblox.com/games/1537690962/)** (`PlaceId: 1537690962`)
- **Universal Engine** (Works in **any** Roblox game)

---

## 📄 License
This project is open source and available under the [MIT License](LICENSE).
