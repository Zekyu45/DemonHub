-- Simple PS99 Script for Delta
-- Using Kavo UI (Known to work better on mobile)

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("PS99 Simple Mobile", "Ocean")

-- Valeurs
_G.autoTap = false
_G.autoCollect = false
_G.autoFarm = false

-- Fonction Anti-AFK simplifiée
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local connections = {}

local function antiAfk()
    connections.afk = LocalPlayer.Idled:Connect(function()
        local VirtualUser = game:GetService("VirtualUser")
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end
antiAfk()

-- Tab principal
local MainTab = Window:NewTab("Principal")
local MainSection = MainTab:NewSection("Farming")

-- Auto Tap
MainSection:NewToggle("Auto Tap", "Clique automatiquement", function(state)
    _G.autoTap = state
    
    while _G.autoTap and wait(0.1) do
        game:GetService("ReplicatedStorage").Network:FireServer("Click")
    end
end)

-- Auto Collect
MainSection:NewToggle("Auto Collect", "Collecte automatiquement les objets", function(state)
    _G.autoCollect = state
    
    while _G.autoCollect and wait(0.5) do
        local character = LocalPlayer.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            local hrp = character.HumanoidRootPart
            
            -- Chercher les orbes
            for _, container in pairs(workspace:GetChildren()) do
                if container.Name == "Orbs" or container.Name == "Lootbags" then
                    for _, item in pairs(container:GetChildren()) do
                        pcall(function()
                            firetouchinterest(hrp, item, 0)
                            wait()
                            firetouchinterest(hrp, item, 1)
                        end)
                    end
                end
            end
        end
    end
end)

-- Auto Farm
MainSection:NewToggle("Auto Farm", "Farm automatiquement les coffres", function(state)
    _G.autoFarm = state
    
    while _G.autoFarm and wait(1) do
        for _, v in pairs(workspace:GetChildren()) do
            if v.Name == "Chest" and v:IsA("Model") and _G.autoFarm then
                pcall(function()
                    game:GetService("ReplicatedStorage").Network:FireServer("StartFarm", v)
                end)
            end
        end
    end
end)

-- Tab Téléportation
local TeleportTab = Window:NewTab("Téléportation")
local TeleportSection = TeleportTab:NewSection("Zones")

-- Zones
local zones = {
    ["Spawn"] = Vector3.new(0, 5, 0),
    ["Fantasy"] = Vector3.new(200, 5, 0),
    ["Tech"] = Vector3.new(400, 5, 0),
    ["Void"] = Vector3.new(600, 5, 0)
}

for name, pos in pairs(zones) do
    TeleportSection:NewButton(name, "Téléporte à " .. name, function()
        if LocalPlayer.Character then
            LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(pos)
        end
    end)
end

-- Tab Performance
local PerformanceTab = Window:NewTab("Performance")
local PerformanceSection = PerformanceTab:NewSection("Améliorer FPS")

-- Boost FPS
PerformanceSection:NewButton("Boost FPS", "Améliore les performances", function()
    -- Désactiver les effets
    for _, v in pairs(game:GetService("Lighting"):GetChildren()) do
        if v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or v:IsA("BloomEffect") then
            v.Enabled = false
        end
    end
    
    -- Réduire la qualité
    settings().Rendering.QualityLevel = 1
end)
