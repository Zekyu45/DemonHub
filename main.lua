-- Simple PS99 Script pour Delta avec UI amélioré et draggable
-- Version simplifiée du système de clé

-- Système de clé d'authentification (simplifié)
local keySystem = true -- Activer/désactiver le système de clé
local correctKey = "zekyu" -- La clé correcte

-- Fonction principale pour charger le script
function loadScript()
    local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
    local Window = Library.CreateLib("PS99 Simple Mobile", "Ocean")

    -- Valeurs
    _G.autoTap = false
    _G.autoCollect = false
    _G.autoFarm = false
    _G.uiMinimized = false
    _G.dragginUI = false
    _G.bestZone = "Fantasy" -- Zone par défaut

    -- Fonction Anti-AFK simplifiée
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    
    local function antiAfk()
        LocalPlayer.Idled:Connect(function()
            local VirtualUser = game:GetService("VirtualUser")
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end
    antiAfk()

    -- Tab principal
    local MainTab = Window:NewTab("Principal")
    local MainSection = MainTab:NewSection("Farming")

    -- Fonction pour trouver le breakable le plus proche
    local function findNearestBreakable()
        local character = LocalPlayer.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then return nil end
        
        local hrp = character.HumanoidRootPart
        local nearest = nil
        local minDistance = math.huge
        
        for _, v in pairs(workspace:GetDescendants()) do
            if v.Name == "Breakable" and v:IsA("Model") and v:FindFirstChild("Health") and v.Health.Value > 0 then
                local distance = (hrp.Position - v.PrimaryPart.Position).magnitude
                if distance < minDistance then
                    minDistance = distance
                    nearest = v
                end
            end
        end
        
        return nearest
    end

    -- Fonction pour se téléporter à la meilleure zone
    local function teleportToBestZone()
        local zones = {
            ["Spawn"] = Vector3.new(170, 130, 250),
            ["Fantasy"] = Vector3.new(3057, 130, 2130),
            ["Tech"] = Vector3.new(4325, 130, 1850),
            ["Void"] = Vector3.new(3678, 130, 1340)
        }
        
        if zones[_G.bestZone] and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(zones[_G.bestZone])
            wait(0.5)
        end
    end

    -- Auto Tap amélioré
    MainSection:NewToggle("Auto Tap", "Tape automatiquement sur les breakables", function(state)
        _G.autoTap = state
        
        spawn(function()
            while _G.autoTap and wait(0.1) do
                local nearest = findNearestBreakable()
                if nearest then
                    game:GetService("ReplicatedStorage").Network:FireServer("Click", nearest)
                else
                    game:GetService("ReplicatedStorage").Network:FireServer("Click")
                end
            end
        end)
    end)

    -- Auto Collect amélioré
    MainSection:NewToggle("Auto Collect", "Collecte automatiquement tous les objets dans la zone", function(state)
        _G.autoCollect = state
        
        spawn(function()
            while _G.autoCollect and wait(0.2) do
                local character = LocalPlayer.Character
                if character and character:FindFirstChild("HumanoidRootPart") then
                    local hrp = character.HumanoidRootPart
                    
                    for _, container in pairs(workspace:GetChildren()) do
                        if container.Name == "Orbs" or container.Name == "Lootbags" or container.Name == "Drops" then
                            for _, item in pairs(container:GetChildren()) do
                                if (item.Position - hrp.Position).Magnitude <= 50 then
                                    pcall(function()
                                        firetouchinterest(hrp, item, 0)
                                        wait()
                                        firetouchinterest(hrp, item, 1)
                                        
                                        game:GetService("ReplicatedStorage").Network:FireServer("CollectOrb", item)
                                        game:GetService("ReplicatedStorage").Network:FireServer("CollectLootbag", item)
                                    end)
                                end
                            end
                        end
                    end
                end
            end
        end)
    end)

    -- Auto Farm amélioré
    MainSection:NewToggle("Auto Farm", "Farm automatiquement les breakables dans la meilleure zone", function(state)
        _G.autoFarm = state
        
        spawn(function()
            while _G.autoFarm and wait(0.5) do
                teleportToBestZone()
                
                local nearest = findNearestBreakable()
                if nearest then
                    local character = LocalPlayer.Character
                    if character and character:FindFirstChild("HumanoidRootPart") then
                        character.HumanoidRootPart.CFrame = nearest.PrimaryPart.CFrame * CFrame.new(0, 5, 0)
                        
                        pcall(function()
                            game:GetService("ReplicatedStorage").Network:FireServer("PetAttack", nearest)
                            game:GetService("ReplicatedStorage").Network:FireServer("Click", nearest)
                        end)
                        
                        local timeout = 0
                        while nearest and nearest:FindFirstChild("Health") and nearest.Health.Value > 0 and timeout < 10 and _G.autoFarm do
                            wait(0.5)
                            timeout = timeout + 0.5
                        end
                    end
                else
                    local randomOffset = Vector3.new(math.random(-30, 30), 0, math.random(-30, 30))
                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(LocalPlayer.Character.HumanoidRootPart.Position + randomOffset)
                    end
                end
            end
        end)
    end)

    -- Sélection de la meilleure zone
    local zoneDropdown = MainSection:NewDropdown("Meilleure Zone", "Sélectionner votre meilleure zone pour le farming", {"Spawn", "Fantasy", "Tech", "Void"}, function(selected)
        _G.bestZone = selected
    end)

    -- Tab Téléportation
    local TeleportTab = Window:NewTab("Téléportation")
    local TeleportSection = TeleportTab:NewSection("Zones")

    -- Zones (coordonnées améliorées)
    local zones = {
        ["Spawn"] = Vector3.new(170, 130, 250),
        ["Fantasy"] = Vector3.new(3057, 130, 2130),
        ["Tech"] = Vector3.new(4325, 130, 1850),
        ["Void"] = Vector3.new(3678, 130, 1340)
    }

    for name, pos in pairs(zones) do
        TeleportSection:NewButton(name, "Téléporte à " .. name, function()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(pos)
            end
        end)
    end

    -- Tab Performance
    local PerformanceTab = Window:NewTab("Performance")
    local PerformanceSection = PerformanceTab:NewSection("Améliorer FPS")

    -- Boost FPS
    PerformanceSection:NewButton("Boost FPS", "Améliore les performances", function()
        for _, v in pairs(game:GetService("Lighting"):GetChildren()) do
            if v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or v:IsA("BloomEffect") or v:IsA("ColorCorrectionEffect") then
                v.Enabled = false
            end
        end
        
        settings().Rendering.QualityLevel = 1
        game:GetService("Lighting").GlobalShadows = false
        game:GetService("Lighting").FogEnd = 9e9
        
        settings().Rendering.QualityLevel = "Level01"
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("Part") or v:IsA("UnionOperation") or v:IsA("MeshPart") then
                v.Material = Enum.Material.Plastic
                v.Reflectance = 0
            elseif v:IsA("Decal") and v.Name ~= "face" then
                v.Transparency = 1
            elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
                v.Lifetime = NumberRange.new(0)
            elseif v:IsA("Explosion") then
                v.BlastPressure = 0
                v.BlastRadius = 0
            end
        end
    end)

    -- Système de contrôle mobile
    local UserInputService = game:GetService("UserInputService")
    
    -- Créer le GUI pour les contrôles mobiles
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "PS99MobileControls"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = game:GetService("CoreGui")

    -- Créer le bouton pour minimiser/maximiser
    local toggleButton = Instance.new("TextButton")
    toggleButton.Name = "ToggleButton"
    toggleButton.Size = UDim2.new(0, 50, 0, 50)
    toggleButton.Position = UDim2.new(0.05, 0, 0.5, 0)
    toggleButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
    toggleButton.BorderSizePixel = 2
    toggleButton.Text = "PS99"
    toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleButton.TextScaled = true
    toggleButton.Font = Enum.Font.SourceSansBold
    toggleButton.Parent = ScreenGui
    
    -- Attendre que Kavo UI soit chargé
    spawn(function()
        wait(1)
        local kavoUI = nil
        for _, v in pairs(game:GetService("CoreGui"):GetChildren()) do
            if v:IsA("ScreenGui") and v:FindFirstChild("Main") then
                kavoUI = v
                break
            end
        end
        
        if kavoUI and kavoUI:FindFirstChild("Main") then
            local mainFrame = kavoUI.Main
            local originalPosition = mainFrame.Position
            local isMinimized = false
            
            -- Fonction pour basculer l'UI
            toggleButton.MouseButton1Click:Connect(function()
                isMinimized = not isMinimized
                mainFrame.Visible = not isMinimized
            end)
            
            -- Rendre l'UI déplaçable pour mobile
            local isDragging = false
            local dragStart = nil
            local startPos = nil
            
            toggleButton.InputBegan:Connect(function(input)
                if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and not isDragging then
                    isDragging = true
                    dragStart = input.Position
                    startPos = toggleButton.Position
                end
            end)
            
            toggleButton.InputChanged:Connect(function(input)
                if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) and isDragging then
                    local delta = input.Position - dragStart
                    toggleButton.Position = UDim2.new(
                        startPos.X.Scale, 
                        startPos.X.Offset + delta.X,
                        startPos.Y.Scale, 
                        startPos.Y.Offset + delta.Y
                    )
                end
            end)
            
            toggleButton.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    isDragging = false
                end
            end)
            
            -- Rendre le mainFrame déplaçable aussi
            local draggingMain = false
            local mainDragStart = nil
            local mainStartPos = nil
            
            mainFrame.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    draggingMain = true
                    mainDragStart = input.Position
                    mainStartPos = mainFrame.Position
                end
            end)
            
            UserInputService.InputChanged:Connect(function(input)
                if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) and draggingMain then
                    local delta = input.Position - mainDragStart
                    mainFrame.Position = UDim2.new(
                        mainStartPos.X.Scale, 
                        mainStartPos.X.Offset + delta.X,
                        mainStartPos.Y.Scale, 
                        mainStartPos.Y.Offset + delta.Y
                    )
                end
            end)
            
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    draggingMain = false
                end
            end)
        end
    end)
end

-- Fonction simplifiée pour le système de clé
local function createSimpleKeyUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "SimpleKeySystem"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = game:GetService("CoreGui")
    
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 250, 0, 120)
    MainFrame.Position = UDim2.new(0.5, -125, 0.5, -60)
    MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui
    
    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Size = UDim2.new(1, 0, 0, 30)
    Title.Position = UDim2.new(0, 0, 0, 0)
    Title.BackgroundColor3 = Color3.fromRGB(0, 85, 127)
    Title.BorderSizePixel = 0
    Title.Text = "PS99 Mobile - Clé"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 18
    Title.Font = Enum.Font.SourceSansBold
    Title.Parent = MainFrame
    
    local KeyBox = Instance.new("TextBox")
    KeyBox.Name = "KeyBox"
    KeyBox.Size = UDim2.new(0.8, 0, 0, 30)
    KeyBox.Position = UDim2.new(0.1, 0, 0.35, 0)
    KeyBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    KeyBox.BorderColor3 = Color3.fromRGB(0, 170, 255)
    KeyBox.BorderSizePixel = 2
    KeyBox.Text = ""
    KeyBox.PlaceholderText = "Entrez la clé..."
    KeyBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    KeyBox.TextSize = 16
    KeyBox.Font = Enum.Font.SourceSans
    KeyBox.Parent = MainFrame
    
    local LoginButton = Instance.new("TextButton")
    LoginButton.Name = "LoginButton"
    LoginButton.Size = UDim2.new(0.8, 0, 0, 30)
    LoginButton.Position = UDim2.new(0.1, 0, 0.7, 0)
    LoginButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
    LoginButton.BorderSizePixel = 0
    LoginButton.Text = "Connexion"
    LoginButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    LoginButton.TextSize = 16
    LoginButton.Font = Enum.Font.SourceSansBold
    LoginButton.Parent = MainFrame
    
    -- Vérification de la clé
    LoginButton.MouseButton1Click:Connect(function()
        if KeyBox.Text == correctKey then
            ScreenGui:Destroy()
            loadScript()
        else
            KeyBox.Text = ""
            KeyBox.PlaceholderText = "Clé incorrecte!"
            KeyBox.PlaceholderColor3 = Color3.fromRGB(255, 100, 100)
            wait(1)
            KeyBox.PlaceholderText = "Entrez la clé..."
            KeyBox.PlaceholderColor3 = Color3.fromRGB(178, 178, 178)
        end
    end)
    
    -- Permettre d'utiliser Enter pour se connecter
    KeyBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            if KeyBox.Text == correctKey then
                ScreenGui:Destroy()
                loadScript()
            else
                KeyBox.Text = ""
                KeyBox.PlaceholderText = "Clé incorrecte!"
                KeyBox.PlaceholderColor3 = Color3.fromRGB(255, 100, 100)
                wait(1)
                KeyBox.PlaceholderText = "Entrez la clé..."
                KeyBox.PlaceholderColor3 = Color3.fromRGB(178, 178, 178)
            end
        end
    end)
    
    -- Rendre l'interface déplaçable pour mobile
    local UserInputService = game:GetService("UserInputService")
    local dragging = false
    local dragInput
    local dragStart
    local startPos
    
    Title.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) and dragging then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(
                startPos.X.Scale, 
                startPos.X.Offset + delta.X,
                startPos.Y.Scale, 
                startPos.Y.Offset + delta.Y
            )
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- Démarrer le script
if keySystem then
    createSimpleKeyUI()
else
    loadScript()
end
