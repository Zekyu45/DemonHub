-- DemonHub for PS99 (by ChatGPT x toi)
local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexware/Orion/main/source"))()

local Window = OrionLib:MakeWindow({
    Name = "DemonHub | Pet Simulator 99",
    HidePremium = false,
    SaveConfig = false,
    IntroEnabled = true,
    IntroText = "DemonHub - PS99"
})

-- Variables globales
getgenv().AutoRankFarm = false
getgenv().AutoCollect = false
getgenv().AutoTap = false

-- Fonction Anti-AFK
local function AntiAFK()
    local vu = game:GetService("VirtualUser")
    game:GetService("Players").LocalPlayer.Idled:Connect(function()
        vu:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        wait(1)
        vu:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end)
end

AntiAFK()

-- Tab principal
local MainTab = Window:MakeTab({
    Name = "Main",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

-- Auto Rank Farm
MainTab:AddToggle({
    Name = "Auto Farm Rank (1-33)",
    Default = false,
    Callback = function(state)
        getgenv().AutoRankFarm = state
        while getgenv().AutoRankFarm do
            local player = game.Players.LocalPlayer
            local rank = player:WaitForChild("leaderstats"):FindFirstChild("Rank")

            if rank and tonumber(rank.Value) < 33 then
                for _, v in pairs(workspace:GetDescendants()) do
                    if v.Name == "Chest" and v:IsA("Model") then
                        pcall(function()
                            game:GetService("ReplicatedStorage").Network:FireServer("StartFarm", v)
                        end)
                    end
                end
            else
                break
            end
            task.wait(1.5)
        end
    end
})

-- Auto Collect Loot
MainTab:AddToggle({
    Name = "Auto Collect Loot",
    Default = false,
    Callback = function(state)
        getgenv().AutoCollect = state
        while getgenv().AutoCollect do
            for _, v in pairs(workspace:GetDescendants()) do
                if v.Name == "Orbs" or v.Name == "Lootbag" then
                    firetouchinterest(game.Players.LocalPlayer.Character.HumanoidRootPart, v, 0)
                    firetouchinterest(game.Players.LocalPlayer.Character.HumanoidRootPart, v, 1)
                end
            end
            task.wait(1)
        end
    end
})

-- Auto Tap
MainTab:AddToggle({
    Name = "Auto Tap (spam click)",
    Default = false,
    Callback = function(state)
        getgenv().AutoTap = state
        while getgenv().AutoTap do
            game:GetService("ReplicatedStorage").Network:FireServer("Click")
            task.wait(0.1)
        end
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
            game.Players.LocalPlayer.Character:MoveTo(pos)
        end
    })
end

-- Crédit
Window:MakeNotification({
    Name = "DemonHub Loaded",
    Content = "Parfaitement injecté dans PS99 !",
    Image = "rbxassetid://4483345998",
    Time = 5
})

