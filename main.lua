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

    -- Fonction pour trouver la meilleure zone DANS LE MONDE ACTUEL
    local function getBestZoneInCurrentWorld()
        local character = LocalPlayer.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then return nil end
        
        local hrp = character.HumanoidRootPart
        local currentPosition = hrp.Position
        local playerStats = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("Main")
        local highestUnlockedZone = 1
        
        -- Essayer de trouver la zone la plus élevée débloquée par le joueur
        if playerStats and playerStats:FindFirstChild("UnlockedZones") then
            for i = 1, 99 do
                if playerStats.UnlockedZones:FindFirstChild("Zone"..i) and playerStats.UnlockedZones["Zone"..i].Value then
                    highestUnlockedZone = i
                else
                    break
                end
            end
        end
        
        -- Coordonnées des zones dans le Spawn World (zone 1-25)
        if currentPosition.X < 1000 then
            -- Retourner les coordonnées de la zone la plus élevée débloquée dans ce monde
            if highestUnlockedZone > 25 then highestUnlockedZone = 25 end
            return "Spawn Zone "..highestUnlockedZone, Vector3.new(170 + (highestUnlockedZone * 5), 130, 250 + (highestUnlockedZone * 3))
        
        -- Coordonnées des zones dans le Fantasy World (zone 26-50)
        elseif currentPosition.X > 2000 and currentPosition.X < 4000 and currentPosition.Z > 1500 then
            -- Limiter à la zone la plus élevée débloquée ou la dernière zone de ce monde
            local zoneOffset = math.min(highestUnlockedZone, 50) - 25
            if zoneOffset <= 0 then zoneOffset = 1 end
            return "Fantasy Zone "..(zoneOffset + 25), Vector3.new(3057, 130, 2130 + (zoneOffset * 3))
        
        -- Coordonnées des zones dans le Tech World (zone 51-75)
        elseif currentPosition.X > 4000 then
            -- Limiter à la zone la plus élevée débloquée ou la dernière zone de ce monde
            local zoneOffset = math.min(highestUnlockedZone, 75) - 50
            if zoneOffset <= 0 then zoneOffset = 1 end
            return "Tech Zone "..(zoneOffset + 50), Vector3.new(4325 + (zoneOffset * 3), 130, 1850)
        
        -- Coordonnées des zones dans le Void World (zone 76-99)
        elseif currentPosition.X > 3000 and currentPosition.Z < 1500 then
            -- Limiter à la zone la plus élevée débloquée
            local zoneOffset = highestUnlockedZone - 75
            if zoneOffset <= 0 then zoneOffset = 1 end
            return "Void Zone "..(zoneOffset + 75), Vector3.new(3678, 130, 1340 - (zoneOffset * 3))
        else
            -- Si on ne peut pas déterminer le monde, on reste sur place
            return "Unknown", hrp.Position + Vector3.new(0, 5, 0)
        end
    end
    -- Auto Tap amélioré
    MainSection:NewToggle("Auto Tap", "Tape automatiquement sur les breakables", function(state)
        _G.autoTap = state
        
        spawn(function()
            while _G.autoTap and wait(0.05) do  -- Réduit le délai pour un clic plus rapide
                local nearest = findNearestBreakable()
                if nearest then
                    -- Cliquer directement sur le breakable
                    game:GetService("ReplicatedStorage").Network:FireServer("Click", nearest)
                    
                    -- Essayer d'attaquer avec les pets aussi
                    pcall(function()
                        game:GetService("ReplicatedStorage").Network:FireServer("PetAttack", nearest)
                    end)
                else
                    -- Cliquer au hasard pour essayer d'atteindre quelque chose
                    game:GetService("ReplicatedStorage").Network:FireServer("Click")
                end
                
                -- Essayer de collecter les objets pendant le tap
                local character = LocalPlayer.Character
                if character and character:FindFirstChild("HumanoidRootPart") then
                    local hrp = character.HumanoidRootPart
                    
                    for _, container in pairs(workspace:GetChildren()) do
                        if container.Name == "Orbs" or container.Name == "Lootbags" or container.Name == "Drops" then
                            for _, item in pairs(container:GetChildren()) do
                                if (item.Position - hrp.Position).Magnitude <= 25 then
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

    -- Auto Collect amélioré
    MainSection:NewToggle("Auto Collect", "Collecte automatiquement tous les objets dans la zone", function(state)
        _G.autoCollect = state
        
        spawn(function()
            while _G.autoCollect and wait(0.1) do  -- Réduit le délai pour une collecte plus rapide
                local character = LocalPlayer.Character
                if character and character:FindFirstChild("HumanoidRootPart") then
                    local hrp = character.HumanoidRootPart
                    
                    -- Utiliser table pour stocker les conteneurs à vérifier
                    local containers = {"Orbs", "Lootbags", "Drops", "Coins"}
                    
                    for _, containerName in ipairs(containers) do
                        local container = workspace:FindFirstChild(containerName)
                        if container then
                            for _, item in pairs(container:GetChildren()) do
                                if (item.Position - hrp.Position).Magnitude <= 40 then  -- Augmente la portée
                                    pcall(function()
                                        -- Essayer les deux méthodes de collecte
                                        firetouchinterest(hrp, item, 0)
                                        wait()
                                        firetouchinterest(hrp, item, 1)
                                        
                                        -- Essayer plusieurs méthodes de collecte selon le type d'objet
                                        if containerName == "Orbs" then
                                            game:GetService("ReplicatedStorage").Network:FireServer("CollectOrb", item)
                                        elseif containerName == "Lootbags" then
                                            game:GetService("ReplicatedStorage").Network:FireServer("CollectLootbag", item)
                                        elseif containerName == "Drops" or containerName == "Coins" then
                                            game:GetService("ReplicatedStorage").Network:FireServer("Collect", item)
                                        end
                                    end)
                                end
                            end
                        end
                    end
                    
                    -- Déplacer légèrement pour ramasser les objets à proximité
                    if _G.autoCollect and not _G.autoFarm then  -- Ne pas interférer avec autoFarm
                        local randomOffset = Vector3.new(math.random(-5, 5), 0, math.random(-5, 5))
                        character.HumanoidRootPart.CFrame = CFrame.new(character.HumanoidRootPart.Position + randomOffset)
                    end
                end
            end
        end)
    end)

    -- Auto Farm amélioré pour rester dans le monde actuel et ne pas voler
    MainSection:NewToggle("Auto Farm", "Farm automatiquement les breakables dans la zone actuelle", function(state)
        _G.autoFarm = state
        
        spawn(function()
            while _G.autoFarm and wait(0.5) do
                -- Obtenir la meilleure zone DANS le monde actuel
                local zoneName, zonePosition = getBestZoneInCurrentWorld()
                
                -- Téléporter à la position de sécurité dans le monde actuel
                local character = LocalPlayer.Character
                if character and character:FindFirstChild("HumanoidRootPart") and character:FindFirstChild("Humanoid") then
                    -- Téléporter juste au-dessus de la zone
                    local safePosition = Vector3.new(zonePosition.X, zonePosition.Y + 5, zonePosition.Z)
                    character.HumanoidRootPart.CFrame = CFrame.new(safePosition)
                    
                    -- Attendre que le personnage atteigne le sol
                    local landed = false
                    local startTime = tick()
                    
                    -- Assurer que le personnage ne tombe pas dans le vide
                    while not landed and tick() - startTime < 5 and _G.autoFarm do
                        wait(0.1)
                        -- Si le personnage est sur le sol ou si on détecte une plateforme proche
                        if character:FindFirstChild("Humanoid") and character.Humanoid:GetState() == Enum.HumanoidStateType.Landed then
                            landed = true
                        end
                        
                        -- Vérifier si on est proche du sol
                        local rayParams = RaycastParams.new()
                        rayParams.FilterType = Enum.RaycastFilterType.Exclude
                        rayParams.FilterDescendantsInstances = {character}
                        
                        local rayResult = workspace:Raycast(character.HumanoidRootPart.Position, Vector3.new(0, -10, 0), rayParams)
                        if rayResult and rayResult.Instance then
                            landed = true
                            -- Positionner au centre de la zone
                            local finalPosition = Vector3.new(zonePosition.X, rayResult.Position.Y + 2, zonePosition.Z)
                            character.HumanoidRootPart.CFrame = CFrame.new(finalPosition)
                        end
                    end
                    
                    -- Si après 5 secondes on n'a pas atteint le sol, repositionner sur la zone
                    if not landed then
                        character.HumanoidRootPart.CFrame = CFrame.new(zonePosition)
                    end
                    
                    wait(0.5) -- Stabilisation
                    
                    -- Désactiver le vol si un script de vol est actif
                    pcall(function()
                        character.Humanoid.PlatformStand = false
                        character.Humanoid:ChangeState(Enum.HumanoidStateType.Landed)
                        
                        -- Forcer le personnage à être plus proche du sol
                        local rayResult = workspace:Raycast(character.HumanoidRootPart.Position, Vector3.new(0, -20, 0), rayParams)
                        if rayResult and rayResult.Instance then
                            character.HumanoidRootPart.CFrame = CFrame.new(Vector3.new(character.HumanoidRootPart.Position.X, rayResult.Position.Y + 2, character.HumanoidRootPart.Position.Z))
                        end
                    end)
                    
                    -- Commencer à farmer les breakables
                    local nearest = findNearestBreakable()
                    if nearest then
                        -- Se téléporter près du breakable mais pas exactement dessus
                        character.HumanoidRootPart.CFrame = nearest.PrimaryPart.CFrame * CFrame.new(0, 3, 2)
                        
                        pcall(function()
                            game:GetService("ReplicatedStorage").Network:FireServer("PetAttack", nearest)
                            game:GetService("ReplicatedStorage").Network:FireServer("Click", nearest)
                        end)
                        
                        local timeout = 0
                        while nearest and nearest:FindFirstChild("Health") and nearest.Health.Value > 0 and timeout < 10 and _G.autoFarm do
                            game:GetService("ReplicatedStorage").Network:FireServer("Click", nearest)
                            wait(0.2)
                            timeout = timeout + 0.2
                        end
                    else
                        -- Si aucun breakable n'est trouvé, explorer un peu la zone
                        local randomOffset = Vector3.new(math.random(-20, 20), 0, math.random(-20, 20))
                        if character and character:FindFirstChild("HumanoidRootPart") then
                            character.HumanoidRootPart.CFrame = CFrame.new(character.HumanoidRootPart.Position + Vector3.new(randomOffset.X, 0, randomOffset.Z))
                        end
                    end
                end
            end
        end)
    end)
    -- Tab Téléportation
    local TeleportTab = Window:NewTab("Téléportation")
    local TeleportSection = TeleportTab:NewSection("Zones")

    -- Téléportation dans le monde actuel seulement
    TeleportSection:NewButton("Meilleure zone du monde actuel", "Téléporte à la meilleure zone dans le monde actuel", function()
        local zoneName, zonePosition = getBestZoneInCurrentWorld()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            -- S'assurer d'utiliser une hauteur sécuritaire
            local safePosition = Vector3.new(zonePosition.X, zonePosition.Y + 10, zonePosition.Z)
            LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(safePosition)
            
            -- Afficher un message pour informer l'utilisateur
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "Téléportation",
                Text = "Téléporté à: " .. zoneName,
                Duration = 3
            })
        end
    end)

    -- Téléportation aléatoire sécuritaire
    TeleportSection:NewButton("Zone aléatoire sécuritaire", "Téléporte à un endroit aléatoire sécuritaire", function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local currentPos = LocalPlayer.Character.HumanoidRootPart.Position
            local randomOffset = Vector3.new(math.random(-50, 50), 0, math.random(-50, 50))
            -- Ajouter une hauteur sécuritaire
            local safePosition = Vector3.new(currentPos.X + randomOffset.X, currentPos.Y + 10, currentPos.Z + randomOffset.Z)
            LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(safePosition)
        end
    end)

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
        
        -- Message de confirmation
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Performance",
            Text = "FPS boostés avec succès!",
            Duration = 3
        })
    end)
    
    -- Ajout d'un bouton pour supprimer les textures
    PerformanceSection:NewButton("Supprimer Textures", "Supprime les textures pour augmenter les FPS", function()
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("Decal") or v:IsA("Texture") then
                v.Transparency = 1
            end
            if v:IsA("MeshPart") then
                v.TextureID = ""
            end
        end
        
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Performance",
            Text = "Textures supprimées!",
            Duration = 3
        })
    end)
    -- Fonction simplifiée pour le système de clé
local function createSimpleKeyUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "SimpleKeySystem"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 250, 0, 120)
    MainFrame.Position = UDim2.new(0.5, -125, 0.5, -60)
    MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    MainFrame.BorderSizePixel = 0
    MainFrame.Visible = true
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
