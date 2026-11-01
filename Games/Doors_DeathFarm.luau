-- =========================================================================
-- UnknownHub DOORS Autonomous Death Farm (Auto-Exec Standalone)
-- Continuous 24/7 Knobs, Revives, Streaks & Achievements Farmer
-- Safe Lobby Auto-Queue + Rapid Match Reset Pipeline
-- =========================================================================

repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
repeat task.wait() until LocalPlayer

local PLACE_LOBBY = 6516141723
local PLACE_GAME = 6839171747

-- Anti-AFK Keepalive
pcall(function()
    if getconnections then
        for _, conn in ipairs(getconnections(LocalPlayer.Idled)) do
            if conn.Disable then conn:Disable() elseif conn.Disconnect then conn:Disconnect() end
        end
    end
end)
LocalPlayer.Idled:Connect(function()
    pcall(function()
        local vu = game:GetService("VirtualUser")
        if vu then
            vu:CaptureController()
            vu:ClickButton2(Vector2.new(10, 10))
        end
    end)
end)

print("[UnknownHub] Autonomous DOORS Death Farm Active. PlaceId:", game.PlaceId)

-- =========================================================================
-- 1. LOBBY AUTOMATION: Enter Elevator Booth
-- =========================================================================
if game.PlaceId == PLACE_LOBBY then
    task.spawn(function()
        while true do
            task.wait(1.5)
            local char = LocalPlayer.Character
            local root = char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart)
            if root then
                -- Search for open elevator booth in lobby
                local elevators = Workspace:FindFirstChild("Elevators") or Workspace:FindFirstChild("LobbyElevators")
                local targetElevator = nil

                if elevators then
                    for _, el in ipairs(elevators:GetChildren()) do
                        local door = el:FindFirstChild("Door") or el:FindFirstChild("ElevatorDoor")
                        local isClosed = el:GetAttribute("Closed") or false
                        if not isClosed then
                            targetElevator = el
                            break
                        end
                    end
                end

                if targetElevator then
                    local elPart = targetElevator:FindFirstChildWhichIsA("BasePart", true)
                    if elPart then
                        root.CFrame = elPart.CFrame + Vector3.new(0, 2, 0)
                        task.wait(3.0)
                    end
                else
                    -- Fallback: Step into starter elevator trigger
                    for _, d in ipairs(Workspace:GetDescendants()) do
                        if d.Name == "EnterPrompt" and d:IsA("ProximityPrompt") then
                            pcall(function() fireproximityprompt(d) end)
                            break
                        end
                    end
                end
            end
        end
    end)
    return
end

-- =========================================================================
-- 2. GAME AUTOMATION: Instant Death & Rapid "Play Again" Loop
-- =========================================================================
if game.PlaceId == PLACE_GAME then
    task.spawn(function()
        -- Wait for character and game setup
        local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        repeat task.wait(0.5) until Workspace:FindFirstChild("CurrentRooms")

        -- Wait for elevator cutscene to conclude
        task.wait(2.5)

        local root = char:WaitForChild("HumanoidRootPart", 10) or char.PrimaryPart
        local hum = char:WaitForChild("Humanoid", 10)

        -- Trigger instant match death
        if hum and root then
            -- Drop below floor into void to trigger instant FallenParts destruction
            root.CFrame = CFrame.new(root.Position.X, -250, root.Position.Z)
            root.AssemblyLinearVelocity = Vector3.new(0, -100, 0)
            pcall(function() hum.Health = 0 end)
        end

        -- Monitor for Death Panel / Play Again button
        local pGui = LocalPlayer:WaitForChild("PlayerGui")
        local mainUI = pGui:WaitForChild("MainUI", 15)
        local deathPanel = mainUI and mainUI:WaitForChild("DeathPanel", 15)

        local playAgainBtn = deathPanel and (deathPanel:FindFirstChild("PlayAgain") or deathPanel:FindFirstChild("BattlePlayAgain"))

        local retries = 0
        while retries < 40 do
            task.wait(0.5)
            retries = retries + 1

            if playAgainBtn and playAgainBtn.Visible then
                -- Click Play Again
                pcall(function()
                    for _, c in ipairs(getconnections(playAgainBtn.MouseButton1Down)) do
                        if c.Fire then c:Fire() elseif c.Function then c.Function() end
                    end
                    for _, c in ipairs(getconnections(playAgainBtn.MouseButton1Click)) do
                        if c.Fire then c:Fire() elseif c.Function then c.Function() end
                    end
                end)
                break
            end

            -- Also check RemotesFolder PlayAgain remote
            local remotes = ReplicatedStorage:FindFirstChild("RemotesFolder")
            local playAgainRemote = remotes and remotes:FindFirstChild("PlayAgain")
            if playAgainRemote then
                pcall(function() playAgainRemote:FireServer() end)
            end
        end

        -- Fallback: Re-teleport to game if stalled
        task.wait(6.0)
        pcall(function()
            TeleportService:Teleport(PLACE_GAME, LocalPlayer)
        end)
    end)
end
