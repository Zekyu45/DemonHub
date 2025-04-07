-- Script PS99 optimisé pour Delta avec UI amélioré et draggable
-- Version 2.0 avec système de clé et performance optimisée

-- Système de clé d'authentification (simplifié)
local keySystem = true -- Activer/désactiver le système de clé
local correctKey = "zekyu" -- La clé correcte

-- Fonction principale pour charger le script
function loadScript()
    -- Vérification et chargement de la bibliothèque UI
    local success, Library = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
    end)
    
    if not success then
        warn("Erreur lors du chargement de la bibliothèque UI. Réessai dans 3 secondes...")
        wait(3)
        return loadScript()
    end
    
    local Window = Library.CreateLib("PS99 Simple Mobile", "Ocean")

    -- Valeurs globales
    _G.autoTap = false
    _G.autoCollect = false
    _G.autoFarm = false
    _G.uiMinimized = false
    _G.dragginUI = false
    
    -- Services
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local StarterGui = game:GetService("StarterGui")
    local UserInputService = game:GetService("UserInputService")
    local LocalPlayer = Players.LocalPlayer
    
    -- Fonction Anti-AFK améliorée
    local function antiAfk()
        local VirtualUser = game:GetService("VirtualUser")
        LocalPlayer.Idled:Connect(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
            StarterGui:SetCore("SendNotification", {
                Title = "Anti-AFK",
                Text = "Anti-AFK activé",
                Duration = 3
            })
        end)
        print("Anti-AFK activé avec succès")
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
        
        -- Optimisation: chercher uniquement dans les modèles qui contiennent des breakables
        local containers = {"Breakables", "Breakable", "Zone"}
        
        for _, containerName in ipairs(containers) do
            local container = workspace:FindFirstChild(containerName)
            if container then
                for _, v in pairs(container:GetDescendants()) do
                    if v.Name == "Breakable" and v:IsA("Model") and v:FindFirstChild("Health") and v.Health.Value > 0 and v:FindFirstChild("PrimaryPart") then
                        local distance = (hrp.Position - v.PrimaryPart.Position).magnitude
                        if distance < minDistance and distance < 100 then
                            minDistance = distance
                            nearest = v
                        end
                    end
                end
            end
        end
        
        -- Si rien n'a été trouvé dans les conteneurs spécifiques, rechercher dans tout l'espace de travail
        if not nearest then
            for _, v in pairs(workspace:GetDescendants()) do
                if v.Name == "Breakable" and v:IsA("Model") and v:FindFirstChild("Health") and v.Health.Value > 0 and v:FindFirstChild("PrimaryPart") then
                    local distance = (hrp.Position - v.PrimaryPart.Position).magnitude
                    if distance < minDistance and distance < 100 then
                        minDistance = distance
                        nearest = v
                    end
                end
            end
        end
        
        return nearest
    end

    -- Fonction pour trouver la meilleure zone DANS LE MONDE ACTUEL (améliorée)
    local function getBestZoneInCurrentWorld()
        local character = LocalPlayer.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then 
            return "Unknown", Vector3.new(0, 100, 0) 
        end
        
        local hrp = character.HumanoidRootPart
        local currentPosition = hrp.Position
        local playerStats = LocalPlayer:WaitForChild("PlayerGui", 5):FindFirstChild("Main")
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
        
        -- Détermination du monde actuel et des coordonnées de la zone appropriée
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
            return "Zone actuelle", hrp.Position + Vector3.new(0, 5, 0)
        end
    end

    -- Auto Tap amélioré avec protection contre les erreurs
    MainSection:NewToggle("Auto Tap", "Tape automatiquement sur les breakables", function(state)
        _G.autoTap = state
        
        spawn(function()
            while _G.autoTap do
                wait(0.05)  -- Délai optimisé
                
                -- Protection contre la déconnexion
                if not game:GetService("Players").LocalPlayer then
                    _G.autoTap = false
                    break
                end
                
                local nearest = findNearestBreakable()
                if nearest then
                    -- Utiliser pcall pour éviter les erreurs
                    pcall(function()
                        -- Cliquer directement sur le breakable
                        ReplicatedStorage.Network:FireServer("Click", nearest)
                        -- Essayer d'attaquer avec les pets aussi
                        ReplicatedStorage.Network:FireServer("PetAttack", nearest)
                    end)
                else
                    -- Cliquer au hasard pour essayer d'atteindre quelque chose
                    pcall(function()
                        ReplicatedStorage.Network:FireServer("Click")
                    end)
                end
                
                -- Collecter automatiquement pendant le tap
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
                                        
                                        if container.Name == "Orbs" then
                                            ReplicatedStorage.Network:FireServer("CollectOrb", item)
                                        elseif container.Name == "Lootbags" then
                                            ReplicatedStorage.Network:FireServer("CollectLootbag", item)
                                        elseif container.Name == "Drops" then
                                            ReplicatedStorage.Network:FireServer("Collect", item)
                                        end
                                    end)
                                end
                            end
                        end
                    end
                end
            end
        end)
    end)

    -- Auto Collect amélioré avec optimisations et protection
    MainSection:NewToggle("Auto Collect", "Collecte automatiquement tous les objets dans la zone", function(state)
        _G.autoCollect = state
        
        spawn(function()
            while _G.autoCollect do
                wait(0.1)  -- Délai optimisé
                
                -- Protection contre la déconnexion
                if not game:GetService("Players").LocalPlayer then
                    _G.autoCollect = false
                    break
                end
                
                local character = LocalPlayer.Character
                if character and character:FindFirstChild("HumanoidRootPart") then
                    local hrp = character.HumanoidRootPart
                    
                    -- Utiliser table pour stocker les conteneurs à vérifier
                    local containers = {"Orbs", "Lootbags", "Drops", "Coins"}
                    
                    for _, containerName in ipairs(containers) do
                        local container = workspace:FindFirstChild(containerName)
                        if container then
                            for _, item in pairs(container:GetChildren()) do
                                if (item.Position - hrp.Position).Magnitude <= 40 then  -- Portée optimisée
                                    pcall(function()
                                        -- Essayer les deux méthodes de collecte
                                        firetouchinterest(hrp, item, 0)
                                        wait()
                                        firetouchinterest(hrp, item, 1)
                                        
                                        -- Essayer plusieurs méthodes de collecte selon le type d'objet
                                        if containerName == "Orbs" then
                                            ReplicatedStorage.Network:FireServer("CollectOrb", item)
                                        elseif containerName == "Lootbags" then
                                            ReplicatedStorage.Network:FireServer("CollectLootbag", item)
                                        elseif containerName == "Drops" or containerName == "Coins" then
                                            ReplicatedStorage.Network:FireServer("Collect", item)
                                        end
                                    end)
                                end
                            end
                        end
                    end
                    
                    -- Déplacer légèrement pour ramasser les objets à proximité
                    if _G.autoCollect and not _G.autoFarm then  -- Ne pas interférer avec autoFarm
                        pcall(function()
                            local randomOffset = Vector3.new(math.random(-5, 5), 0, math.random(-5, 5))
                            character.HumanoidRootPart.CFrame = CFrame.new(character.HumanoidRootPart.Position + randomOffset)
                        end)
                    end
                end
            end
        end)
    end)

    -- Auto Farm optimisé et sécurisé
    MainSection:NewToggle("Auto Farm", "Farm automatiquement les breakables dans la zone actuelle", function(state)
        _G.autoFarm = state
        
        spawn(function()
            while _G.autoFarm do
                wait(0.5)
                
                -- Protection contre la déconnexion
                if not game:GetService("Players").LocalPlayer then
                    _G.autoFarm = false
                    break
                end
                
                -- Obtenir la meilleure zone DANS le monde actuel
                local zoneName, zonePosition = getBestZoneInCurrentWorld()
                
                -- Téléporter à la position de sécurité dans le monde actuel
                local character = LocalPlayer.Character
                if character and character:FindFirstChild("HumanoidRootPart") and character:FindFirstChild("Humanoid") then
                    pcall(function()
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
                        character.Humanoid.PlatformStand = false
                        character.Humanoid:ChangeState(Enum.HumanoidStateType.Landed)
                        
                        -- Forcer le personnage à être plus proche du sol
                        local rayResult = workspace:Raycast(character.HumanoidRootPart.Position, Vector3.new(0, -20, 0), rayParams)
                        if rayResult and rayResult.Instance then
                            character.HumanoidRootPart.CFrame = CFrame.new(Vector3.new(
                                character.HumanoidRootPart.Position.X, 
                                rayResult.Position.Y + 2, 
                                character.HumanoidRootPart.Position.Z
                            ))
                        end
                        
                        -- Commencer à farmer les breakables
                        local nearest = findNearestBreakable()
                        if nearest then
                            -- Se téléporter près du breakable mais pas exactement dessus
                            character.HumanoidRootPart.CFrame = nearest.PrimaryPart.CFrame * CFrame.new(0, 3, 2)
                            
                            ReplicatedStorage.Network:FireServer("PetAttack", nearest)
                            ReplicatedStorage.Network:FireServer("Click", nearest)
                            
                            local timeout = 0
                            while nearest and nearest:FindFirstChild("Health") and nearest.Health.Value > 0 and timeout < 10 and _G.autoFarm do
                                ReplicatedStorage.Network:FireServer("Click", nearest)
                                wait(0.2)
                                timeout = timeout + 0.2
                            end
                        else
                            -- Si aucun breakable n'est trouvé, explorer un peu la zone
                            local randomOffset = Vector3.new(math.random(-20, 20), 0, math.random(-20, 20))
                            if character and character:FindFirstChild("HumanoidRootPart") then
                                character.HumanoidRootPart.CFrame = CFrame.new(
                                    character.HumanoidRootPart.Position + Vector3.new(randomOffset.X, 0, randomOffset.Z)
                                )
                            end
                        end
                    end)
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
        pcall(function()
            -- S'assurer d'utiliser une hauteur sécuritaire
            local safePosition = Vector3.new(zonePosition.X, zonePosition.Y + 10, zonePosition.Z)
            LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(safePosition)
            
            -- Afficher un message pour informer l'utilisateur
            StarterGui:SetCore("SendNotification", {
                Title = "Téléportation",
                Text = "Téléporté à: " .. zoneName,
                Duration = 3
            })
        end)
    end
end)

-- Téléportation aléatoire sécuritaire
TeleportSection:NewButton("Zone aléatoire sécuritaire", "Téléporte à un endroit aléatoire sécuritaire", function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        pcall(function()
            local currentPos = LocalPlayer.Character.HumanoidRootPart.Position
            local randomOffset = Vector3.new(math.random(-50, 50), 0, math.random(-50, 50))
            -- Ajouter une hauteur sécuritaire
            local safePosition = Vector3.new(currentPos.X + randomOffset.X, currentPos.Y + 10, currentPos.Z + randomOffset.Z)
            LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(safePosition)
            
            StarterGui:SetCore("SendNotification", {
                Title = "Téléportation",
                Text = "Téléporté à une zone aléatoire",
                Duration = 3
            })
        end)
    end
end)

-- Ajout d'un bouton pour se téléporter au spawn
TeleportSection:NewButton("Téléporter au Spawn", "Retourne à la zone de départ", function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        pcall(function()
            -- Coordonnées du spawn (ajustez selon le jeu)
            local spawnPosition = Vector3.new(170, 130, 250)
            LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(spawnPosition)
            
            StarterGui:SetCore("SendNotification", {
                Title = "Téléportation",
                Text = "Téléporté au Spawn",
                Duration = 3
            })
        end)
    end
end)

-- Téléportation aux autres mondes
local WorldSection = TeleportTab:NewSection("Mondes")

-- Monde Fantaisie
WorldSection:NewButton("Monde Fantaisie", "Téléporte au monde Fantaisie", function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        pcall(function()
            local fantasyPosition = Vector3.new(3057, 130, 2130)
            LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(fantasyPosition)
            
            StarterGui:SetCore("SendNotification", {
                Title = "Téléportation",
                Text = "Téléporté au Monde Fantaisie",
                Duration = 3
            })
        end)
    end
end)

-- Monde Tech
WorldSection:NewButton("Monde Tech", "Téléporte au monde Tech", function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        pcall(function()
            local techPosition = Vector3.new(4325, 130, 1850)
            LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(techPosition)
            
            StarterGui:SetCore("SendNotification", {
                Title = "Téléportation",
                Text = "Téléporté au Monde Tech",
                Duration = 3
            })
        end)
    end
end)

-- Monde Void
WorldSection:NewButton("Monde Void", "Téléporte au monde Void", function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        pcall(function()
            local voidPosition = Vector3.new(3678, 130, 1340)
            LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(voidPosition)
            
            StarterGui:SetCore("SendNotification", {
                Title = "Téléportation",
                Text = "Téléporté au Monde Void",
                Duration = 3
            })
        end)
    end
end)

-- Système anti-chute
local SafetySection = TeleportTab:NewSection("Sécurité")

-- Sauvetage en cas de chute
SafetySection:NewButton("Anti-Void", "Te sauve si tu tombes dans le vide", function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        pcall(function()
            local currentPos = LocalPlayer.Character.HumanoidRootPart.Position
            -- Si on est en train de tomber, repositionner à une hauteur sécuritaire
            if currentPos.Y < -50 then
                local safePosition = Vector3.new(currentPos.X, 130, currentPos.Z)
                LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(safePosition)
                
                StarterGui:SetCore("SendNotification", {
                    Title = "Sécurité",
                    Text = "Sauvé du vide!",
                    Duration = 3
                })
            else
                StarterGui:SetCore("SendNotification", {
                    Title = "Sécurité",
                    Text = "Vous n'êtes pas en train de tomber",
                    Duration = 3
                })
            end
        end)
    end
end)

-- Activation anti-void automatique
local autoAntiVoid = false
SafetySection:NewToggle("Auto Anti-Void", "Sauve automatiquement en cas de chute", function(state)
    autoAntiVoid = state
    
    spawn(function()
        while autoAntiVoid do
            wait(0.5)
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local currentPos = LocalPlayer.Character.HumanoidRootPart.Position
                if currentPos.Y < -50 then
                    pcall(function()
                        local safePosition = Vector3.new(currentPos.X, 130, currentPos.Z)
                        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(safePosition)
                        
                        StarterGui:SetCore("SendNotification", {
                            Title = "Sécurité",
                            Text = "Sauvé du vide automatiquement!",
                            Duration = 2
                        })
                    end)
                end
            end
        end
    end)
end)

-- Tab Performance
local PerformanceTab = Window:NewTab("Performance")
local PerformanceSection = PerformanceTab:NewSection("Améliorer FPS")

-- Boost FPS
PerformanceSection:NewButton("Boost FPS", "Améliore les performances", function()
    pcall(function()
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
        StarterGui:SetCore("SendNotification", {
            Title = "Performance",
            Text = "FPS boostés avec succès!",
            Duration = 3
        })
    end)
end)

-- Ajout d'un bouton pour supprimer les textures
PerformanceSection:NewButton("Supprimer Textures", "Supprime les textures pour augmenter les FPS", function()
    pcall(function()
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("Decal") or v:IsA("Texture") then
                v.Transparency = 1
            end
            if v:IsA("MeshPart") then
                v.TextureID = ""
            end
        end
        
        StarterGui:SetCore("SendNotification", {
            Title = "Performance",
            Text = "Textures supprimées!",
            Duration = 3
        })
    end)
end)

-- Optimiser la mémoire
PerformanceSection:NewButton("Nettoyer Mémoire", "Libère la mémoire pour plus de fluidité", function()
    pcall(function()
        for i = 1, 10 do
            game:GetService("RunService").RenderStepped:Wait()
        end
        
        game:GetService("Debris"):AddItem(script, 0)
        game:GetService("TweenService"):GetTweens()
        
        for i = 1, 5 do
            wait()
            collectgarbage("collect")
        end
        
        StarterGui:SetCore("SendNotification", {
            Title = "Performance",
            Text = "Mémoire nettoyée avec succès!",
            Duration = 3
        })
    end)
end)

-- Tab Info Supplémentaire
local InfoTab = Window:NewTab("Info")
local InfoSection = InfoTab:NewSection("Informations")

InfoSection:NewLabel("Version: 2.0")
InfoSection:NewLabel("Mobile Optimisé: Oui")
InfoSection:NewLabel("Clé: "..correctKey)

-- Ajouter un crédit
InfoSection:NewLabel("Scripté par zekyu")

-- Bouton pour copier le Discord
InfoSection:NewButton("Copier Discord", "Copie le lien Discord", function()
    pcall(function()
        setclipboard("discord.gg/zekyu")
        
        StarterGui:SetCore("SendNotification", {
            Title = "Info",
            Text = "Discord copié dans le presse-papier!",
            Duration = 3
        })
    end)
end)
    
