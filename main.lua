-- Simple PS99 Script for Delta with draggable UI
-- Using Kavo UI with modifications for mobile
-- Au début du script, ajoutez ce code pour vérifier que le script s'exécute
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "Vérification",
    Text = "Script en cours de chargement...",
    Duration = 5
}}
-- Système de clé d'authentification
local keySystem = true -- Activer/désactiver le système de clé
local correctKey = "zekyu" -- La clé correcte

-- Fonction pour vérifier la clé
local function checkKey(inputKey)
    return inputKey == correctKey
end

-- UI du système de clé
local function createKeyUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "KeySystem"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = game:GetService("CoreGui")
    
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 300, 0, 150)
    MainFrame.Position = UDim2.new(0.5, -150, 0.5, -75)
    MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui
    
    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Size = UDim2.new(1, 0, 0, 40)
    Title.Position = UDim2.new(0, 0, 0, 0)
    Title.BackgroundColor3 = Color3.fromRGB(0, 85, 127)
    Title.BorderSizePixel = 0
    Title.Text = "PS99 Simple Mobile - Key System"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 18
    Title.Font = Enum.Font.SourceSansBold
    Title.Parent = MainFrame
    
    local KeyBox = Instance.new("TextBox")
    KeyBox.Name = "KeyBox"
    KeyBox.Size = UDim2.new(0.8, 0, 0, 30)
    KeyBox.Position = UDim2.new(0.1, 0, 0.4, 0)
    KeyBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    KeyBox.BorderColor3 = Color3.fromRGB(0, 170, 255)
    KeyBox.BorderSizePixel = 2
    KeyBox.Text = ""
    KeyBox.PlaceholderText = "Entrez la clé..."
    KeyBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    KeyBox.TextSize = 16
    KeyBox.Font = Enum.Font.SourceSans
    KeyBox.Parent = MainFrame
    
    local SubmitButton = Instance.new("TextButton")
    SubmitButton.Name = "SubmitButton"
    SubmitButton.Size = UDim2.new(0.5, 0, 0, 30)
    SubmitButton.Position = UDim2.new(0.25, 0, 0.7, 0)
    SubmitButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
    SubmitButton.BorderSizePixel = 0
    SubmitButton.Text = "Valider"
    SubmitButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    SubmitButton.TextSize = 16
    SubmitButton.Font = Enum.Font.SourceSansBold
    SubmitButton.Parent = MainFrame
    
    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Name = "StatusLabel"
    StatusLabel.Size = UDim2.new(1, 0, 0, 20)
    StatusLabel.Position = UDim2.new(0, 0, 0.9, 0)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Text = ""
    StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    StatusLabel.TextSize = 14
    StatusLabel.Font = Enum.Font.SourceSans
    StatusLabel.Parent = MainFrame
    
    -- Vérification de la clé
    local keySuccess = false
    
    SubmitButton.MouseButton1Click:Connect(function()
        if checkKey(KeyBox.Text) then
            StatusLabel.Text = "Clé valide! Chargement du script..."
            StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
            keySuccess = true
            wait(1)
            ScreenGui:Destroy()
            loadScript() -- Charge le script principal si la clé est correcte
        else
            StatusLabel.Text = "Clé invalide! Veuillez réessayer."
            StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
            KeyBox.Text = ""
        end
    end)
    
    -- Permettre d'utiliser Enter pour valider
    KeyBox.FocusLost:Connect(function(enterPressed)
        if enterPressed and not keySuccess then
            if checkKey(KeyBox.Text) then
                StatusLabel.Text = "Clé valide! Chargement du script..."
                StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
                keySuccess = true
                wait(1)
                ScreenGui:Destroy()
                loadScript() -- Charge le script principal si la clé est correcte
            else
                StatusLabel.Text = "Clé invalide! Veuillez réessayer."
                StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
                KeyBox.Text = ""
            end
        end
    end)
    
    return keySuccess
end

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
    _G.bestZone = "Fantasy" -- Zone par défaut, à modifier selon votre meilleure zone

    -- Fonction Anti-AFK simplifiée
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
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

    -- Fonction pour trouver le breakable le plus proche
    local function findNearestBreakable()
        local character = LocalPlayer.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then return nil end
        
        local hrp = character.HumanoidRootPart
        local nearest = nil
        local minDistance = math.huge
        
        -- Chercher tous les breakables dans le workspace
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
            wait(0.5) -- Attendre que la téléportation soit effectuée
        end
    end

    -- Auto Tap amélioré
    MainSection:NewToggle("Auto Tap", "Tape automatiquement sur les breakables", function(state)
        _G.autoTap = state
        
        spawn(function()
            while _G.autoTap and wait(0.1) do
                local nearest = findNearestBreakable()
                if nearest then
                    -- Simuler un tap sur le breakable
                    game:GetService("ReplicatedStorage").Network:FireServer("Click", nearest)
                    
                    -- Méthode alternative si la première ne fonctionne pas
                    pcall(function()
                        game:GetService("ReplicatedStorage").Events.DamageBreakable:FireServer(nearest)
                    end)
                else
                    -- Si aucun breakable trouvé, juste cliquer
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
                    
                    -- Chercher tous les types d'objets collectables
                    for _, container in pairs(workspace:GetChildren()) do
                        if container.Name == "Orbs" or container.Name == "Lootbags" or container.Name == "Drops" then
                            for _, item in pairs(container:GetChildren()) do
                                if (item.Position - hrp.Position).Magnitude <= 50 then -- Collecter dans un rayon de 50 studs
                                    pcall(function()
                                        -- Méthode 1: TouchInterest
                                        firetouchinterest(hrp, item, 0)
                                        wait()
                                        firetouchinterest(hrp, item, 1)
                                        
                                        -- Méthode 2: Collecte par réseau
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

    -- Auto Farm amélioré - téléportation à la dernière zone et farm des breakables
    MainSection:NewToggle("Auto Farm", "Farm automatiquement les breakables dans la meilleure zone", function(state)
        _G.autoFarm = state
        
        spawn(function()
            while _G.autoFarm and wait(0.5) do
                -- Se téléporter à la meilleure zone
                teleportToBestZone()
                
                local nearest = findNearestBreakable()
                if nearest then
                    -- Se téléporter près du breakable
                    local character = LocalPlayer.Character
                    if character and character:FindFirstChild("HumanoidRootPart") then
                        -- Se téléporter à une petite distance du breakable pour éviter la détection
                        character.HumanoidRootPart.CFrame = nearest.PrimaryPart.CFrame * CFrame.new(0, 5, 0)
                        
                        -- Faire attaquer le breakable par les pets
                        pcall(function()
                            game:GetService("ReplicatedStorage").Network:FireServer("PetAttack", nearest)
                            -- Méthode alternative
                            game:GetService("ReplicatedStorage").Events.PetAttack:FireServer(nearest)
                        end)
                        
                        -- Taper aussi sur le breakable
                        pcall(function()
                            game:GetService("ReplicatedStorage").Network:FireServer("Click", nearest)
                        end)
                        
                        -- Attendre que le breakable soit cassé ou un délai maximum
                        local timeout = 0
                        while nearest and nearest:FindFirstChild("Health") and nearest.Health.Value > 0 and timeout < 10 and _G.autoFarm do
                            wait(0.5)
                            timeout = timeout + 0.5
                        end
                    end
                else
                    -- Si aucun breakable trouvé, explorer la zone
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
        -- Désactiver les effets
        for _, v in pairs(game:GetService("Lighting"):GetChildren()) do
            if v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or v:IsA("BloomEffect") or v:IsA("ColorCorrectionEffect") then
                v.Enabled = false
            end
        end
        
        -- Réduire la qualité
        settings().Rendering.QualityLevel = 1
        
        -- Autres optimisations
        game:GetService("Lighting").GlobalShadows = false
        game:GetService("Lighting").FogEnd = 9e9
        
        -- Réduire la distance de rendu
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

    -- Créer le GUI pour le déplacement et le bouton de minimisation
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "PS99MobileControls"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = game:GetService("CoreGui")

    -- Créer le bouton P (minimisé)
    local PButton = Instance.new("TextButton")
    PButton.Name = "PButton"
    PButton.Size = UDim2.new(0, 40, 0, 40)
    PButton.Position = UDim2.new(0.05, 0, 0.5, 0)
    PButton.BackgroundColor3 = Color3.fromRGB(0, 85, 127)
    PButton.BorderSizePixel = 2
    PButton.BorderColor3 = Color3.fromRGB(0, 170, 255)
    PButton.Text = "P"
    PButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    PButton.TextScaled = true
    PButton.Font = Enum.Font.SourceSansBold
    PButton.Visible = false
    PButton.Parent = ScreenGui

    -- Créer le handle de déplacement
    local MoveHandle = Instance.new("TextButton")
    MoveHandle.Name = "MoveHandle"
    MoveHandle.Size = UDim2.new(0, 30, 0, 30)
    MoveHandle.Position = UDim2.new(0, 0, 0, 0)
    MoveHandle.BackgroundColor3 = Color3.fromRGB(0, 170, 127)
    MoveHandle.BorderSizePixel = 0
    MoveHandle.Text = "≡"
    MoveHandle.TextColor3 = Color3.fromRGB(255, 255, 255)
    MoveHandle.TextScaled = true
    MoveHandle.Font = Enum.Font.SourceSansBold
    MoveHandle.ZIndex = 10
    MoveHandle.Parent = ScreenGui

    -- Créer le bouton de fermeture X
    local CloseButton = Instance.new("TextButton")
    CloseButton.Name = "CloseButton"
    CloseButton.Size = UDim2.new(0, 30, 0, 30)
    CloseButton.Position = UDim2.new(1, -30, 0, 0)
    CloseButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    CloseButton.BorderSizePixel = 0
    CloseButton.Text = "X"
    CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseButton.TextScaled = true
    CloseButton.Font = Enum.Font.SourceSansBold
    CloseButton.ZIndex = 10

    -- Modifier le Kavo UI pour ajouter nos contrôles personnalisés
    local function setupCustomControls()
        -- Identifier le conteneur principal du Kavo UI
        local kavoUI = nil
        for _, v in pairs(game:GetService("CoreGui"):GetChildren()) do
            if v:IsA("ScreenGui") and v:FindFirstChild("Main") then
                kavoUI = v
                break
            end
        end
        
        if kavoUI and kavoUI:FindFirstChild("Main") then
            local mainFrame = kavoUI.Main
            
            -- Ajouter le bouton de fermeture au frame principal
            CloseButton.Parent = mainFrame
            
            -- Déplacer le handle à la position du mainFrame
            MoveHandle.Position = UDim2.new(0, mainFrame.AbsolutePosition.X, 0, mainFrame.AbsolutePosition.Y)
            
            -- Position initiale du UI
            local uiPos = mainFrame.Position
            
            -- Fonction pour minimiser/maximiser l'UI
            local function toggleUI()
                _G.uiMinimized = not _G.uiMinimized
                
                if _G.uiMinimized then
                    -- Sauvegarder la position actuelle
                    uiPos = mainFrame.Position
                    
                    -- Cacher le Kavo UI
                    mainFrame.Visible = false
                    MoveHandle.Visible = false
                    
                    -- Montrer le bouton P
                    PButton.Visible = true
                else
                    -- Restaurer le Kavo UI
                    mainFrame.Position = uiPos
                    mainFrame.Visible = true
                    MoveHandle.Visible = true
                    
                    -- Cacher le bouton P
                    PButton.Visible = false
                end
            end
            
            -- Gérer le clic sur le bouton X
            CloseButton.MouseButton1Click:Connect(toggleUI)
            
            -- Gérer le clic sur le bouton P
            PButton.MouseButton1Click:Connect(toggleUI)
            
            -- Rendre le UI déplaçable
            local dragging = false
            local dragInput
            local dragStart
            local startPos
            
            local function updateInput(input)
                local delta = input.Position - dragStart
                local newPosition = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
                
                -- Mettre à jour la position du frame principal
                mainFrame.Position = newPosition
                
                -- Mettre à jour la position du handle
                MoveHandle.Position = UDim2.new(0, mainFrame.AbsolutePosition.X, 0, mainFrame.AbsolutePosition.Y)
            end
            
            MoveHandle.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    dragStart = input.Position
                    startPos = mainFrame.Position
                    
                    input.Changed:Connect(function()
                        if input.UserIn
