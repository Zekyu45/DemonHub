-- DemonHub for PS99 (Delta Compatible)
local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexware/Orion/main/source"))()

-- Créer la fenêtre principale avec des options compatibles pour Delta
local Window = OrionLib:MakeWindow({
    Name = "DemonHub | Pet Simulator 99",
    HidePremium = false,
    SaveConfig = true,
    ConfigFolder = "DemonHubConfig",
    IntroEnabled = true,
    IntroText = "DemonHub - PS99"
})

-- Variables globales
_G.AutoRankFarm = false
_G.AutoCollect = false
_G.AutoTap = false

-- Fonction Anti-AFK compatible avec Delta
local function AntiAFK()
    local VirtualUser = game:GetService("VirtualUser")
    game:GetService("Players").LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
    print("Anti-AFK Enabled")
end

AntiAFK()

-- Tab principal
local MainTab = Window:MakeTab({
    Name = "Main",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

-- Auto Rank Farm (corrigé pour Delta)
MainTab:AddToggle({
    Name = "Auto Farm Rank (1-33)",
    Default = false,
    Callback = function(state)
        _G.AutoRankFarm = state
        
        spawn(function()
            while wait(1.5) do
                if not _G.AutoRankFarm then break end
                
                local player = game.Players.LocalPlayer
                local leaderstats = player:FindFirstChild("leaderstats")
                
                if leaderstats then
                    local rank = leaderstats:FindFirstChild("Rank")
                    
                    if rank and tonumber(rank.Value) < 33 then
                        for _, v in pairs(workspace:GetChildren()) do
                            if v.Name == "Chest" and v:IsA("Model") and _G.AutoRankFarm then
                                pcall(function()
                                    game:GetService("ReplicatedStorage").Network:FireServer("StartFarm", v)
                                end)
                            end
                        end
                    end
                end
            end
        end)
    end
})

-- Auto Collect Loot (corrigé pour Delta)
MainTab:AddToggle({
    Name = "Auto Collect Loot",
    Default = false,
    Callback = function(state)
        _G.AutoCollect = state
        
        spawn(function()
            while wait(1) do
                if not _G.AutoCollect then break end
                
                local character = game.Players.LocalPlayer.Character
                if character and character:FindFirstChild("HumanoidRootPart") then
                    local hrp = character.HumanoidRootPart
                    
                    -- Recherche correcte des orbes
                    local orbs = workspace:FindFirstChild("Orbs")
                    if orbs then
                        for _, v in pairs(orbs:GetChildren()) do
                            if v and _G.AutoCollect then
                                pcall(function()
                                    firetouchinterest(hrp, v, 0)
                                    wait()
                                    firetouchinterest(hrp, v, 1)
                                end)
                            end
                        end
                    end
                    
                    -- Recherche correcte des lootbags
                    local lootbags = workspace:FindFirstChild("Lootbags")
                    if lootbags then
                        for _, v in pairs(lootbags:GetChildren()) do
                            if v and _G.AutoCollect then
                                pcall(function()
                                    firetouchinterest(hrp, v, 0)
                                    wait()
                                    firetouchinterest(hrp, v, 1)
                                end)
                            end
                        end
                    end
                end
            end
        end)
    end
})

-- Auto Tap (corrigé pour Delta)
MainTab:AddToggle({
    Name = "Auto Tap (spam click)",
    Default = false,
    Callback = function(state)
        _G.AutoTap = state
        
        spawn(function()
            while wait(0.1) do
                if not _G.AutoTap then break end
                
                pcall(function()
                    game:GetService("ReplicatedStorage").Network:FireServer("Click")
                end)
            end
        end)
    end
})

-- Teleport Zones
local tpTab = Window:MakeTab({
    Name = "Teleport",
    Icon = "rbxassetid://6031071053",
    PremiumOnly = false
})

local zones = {
    ["Spawn"] = Vector3.new(0, 5, 0),
    ["Fantasy"] = Vector3.new(200, 5, 0),
    ["Tech"] = Vector3.new(400, 5, 0),
    ["Void"] = Vector3.new(600, 5, 0)
}

for name, pos in pairs(zones) do
    tpTab:AddButton({
        Name = "TP to " .. name,
        Callback = function()
            pcall(function()
                local char = game.Players.LocalPlayer.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    char.HumanoidRootPart.CFrame = CFrame.new(pos)
                end
            end)
        end
    })
end

-- Améliorations pour Delta
local performanceTab = Window:MakeTab({
    Name = "Performance",
    Icon = "rbxassetid://4384401360",
    PremiumOnly = false
})

-- Amélioration des performances
performanceTab:AddButton({
    Name = "Boost FPS",
    Callback = function()
        -- Réduire la qualité graphique
        local lighting = game:GetService("Lighting")
        lighting.GlobalShadows = false
        lighting.FogEnd = 10000
        
        -- Désactiver les effets
        for _, v in pairs(lighting:GetChildren()) do
            if v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or v:IsA("BloomEffect") then
                v.Enabled = false
            end
        end
        
        -- Désactiver les particules
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("ParticleEmitter") or v:IsA("Fire") or v:IsA("Smoke") then
                v.Enabled = false
            end
        end
        
        -- Notification
        OrionLib:MakeNotification({
            Name = "Performance",
            Content = "FPS Boost activé!",
            Image = "rbxassetid://4483345998",
            Time = 5
        })
    end
})

-- Crédit
OrionLib:MakeNotification({
    Name = "DemonHub Loaded",
    Content = "Parfaitement injecté dans PS99 !",
    Image = "rbxassetid://4483345998",
    Time = 5
})

-- Fin du script
OrionLib:Init()
