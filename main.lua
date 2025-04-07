-- Script PS99 optimisé pour Delta avec UI amélioré et draggable
-- Version 3.0 avec système de clé et performance optimisée, bugs corrigés

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
    
    local Window = Library.CreateLib("PS99 Mobile Pro", "Ocean")

    -- Valeurs globales
    _G.autoTap = false
    _G.autoCollect = false
    _G.autoFarm = false
    _G.uiMinimized = false
    _G.dragginUI = false
    _G.lastHighestZone = 1
    _G.farmRadius = 20 -- Rayon de collecte des objets
    
    -- Services
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local StarterGui = game:GetService("StarterGui")
    local UserInputService = game:GetService("UserInputService")
    local RunService = game:GetService("RunService")
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

    -- Définition des mondes et leurs limites de zones
    local worlds = {
        {name = "Spawn World", minZone = 1, maxZone = 25, basePosition = Vector3.new(170, 130, 250), offsetX = 5, offsetZ = 3},
        {name = "Fantasy World", minZone = 26, maxZone = 50, basePosition = Vector3.new(3057, 130, 2130), offsetX = 0, offsetZ = 3},
        {name = "Tech World", minZone = 51, maxZone = 75, basePosition = Vector3.new(4325, 130, 1850), offsetX = 3, offsetZ = 0},
        {name = "Void World", minZone = 76, maxZone = 99, basePosition = Vector3.new(3678, 130, 1340), offsetX = 0, offsetZ = -3}
    }

    -- Fonction pour déterminer le monde actuel
    local function getCurrentWorld()
        local character = LocalPlayer.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then 
            return worlds[1] -- Par défaut, Spawn World
        end
        
        local currentPosition = character.HumanoidRootPart.Position
        
        if currentPosition.X < 1000 then
            return worlds[1] -- Spawn World
        elseif currentPosition.X > 2000 and currentPosition.X < 4000 and currentPosition.Z > 1500 then
            return worlds[2] -- Fantasy World
        elseif currentPosition.X > 4000 then
            return worlds[3] -- Tech World
        elseif currentPosition.X > 3000 and currentPosition.Z < 1500 then
            return worlds[4] -- Void World
        else
            return worlds[1] -- Par défaut, Spawn World
        end
    end

    -- Fonction améliorée pour obtenir la zone la plus élevée débloquée par le joueur
    local function getHighestUnlockedZone()
        -- Cacher cette valeur pour éviter de recalculer trop souvent
        if _G.lastHighestZone and _G.lastUpdateTime and tick() - _G.lastUpdateTime < 10 then
            return _G.lastHighestZone
        end
        
        local playerStats = LocalPlayer:WaitForChild("PlayerGui", 5):FindFirstChild("Main")
        local highestZone = 1
        
        if playerStats and playerStats:FindFirstChild("UnlockedZones") then
            for i = 1, 99 do
                if playerStats.UnlockedZones:FindFirstChild("Zone"..i) and playerStats.UnlockedZones["Zone"..i].Value then
                    highestZone = i
                else
                    break
                end
            end
        end
        
        -- Mettre à jour le cache
        _G.lastHighestZone = highestZone
        _G.lastUpdateTime = tick()
        
        return highestZone
    end

    -- Fonction pour obtenir la position de la zone débloquée la plus élevée dans le monde actuel
    local function getBestUnlockedZoneInCurrentWorld()
        local currentWorld = getCurrentWorld()
        local highestUnlockedZone = getHighestUnlockedZone()
        
        -- Limiter à la zone la plus élevée du monde actuel
        local zoneInWorld = math.min(highestUnlockedZone, currentWorld.maxZone)
        if zoneInWorld < currentWorld.minZone then
            zoneInWorld = currentWorld.minZone
        end
        
        -- Calculer l'offset pour la position de la zone
        local offset = zoneInWorld - currentWorld.minZone + 1
        
        -- Calculer la position de la zone
        local zonePosition = Vector3.new(
            currentWorld.basePosition.X + (offset * currentWorld.offsetX),
            currentWorld.basePosition.Y,
            currentWorld.basePosition.Z + (offset * currentWorld.offsetZ)
        )
        
        return currentWorld.name .. " Zone " .. zoneInWorld, zonePosition
    end

    -- Fonction pour trouver le breakable le plus proche avec des optimisations
    local function findNearestBreakable()
        local character = LocalPlayer.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then return nil end
        
        local hrp = character.HumanoidRootPart
        local nearest = nil
        local minDistance = math.huge
        local maxSearchRadius = 60 -- Limiter la recherche pour la performance
        
        -- Liste des conteneurs à vérifier
        local containers = {"Breakables", "Breakable", "Zone"}
        
        -- Rechercher dans les conteneurs spécifiques d'abord
        for _, containerName in ipairs(containers) do
            local container = workspace:FindFirstChild(containerName)
            if container then
                for _, v in pairs(container:GetChildren()) do
                    -- Vérifier si c'est un breakable valide
                    if (v.Name == "Breakable" or v:FindFirstChild("Breakable")) and v:IsA("Model") then
                        local breakableObj = v.Name == "Breakable" and v or v:FindFirstChild("Breakable")
                        if breakableObj and breakableObj:FindFirstChild("Health") and breakableObj.Health.Value > 0 then
                            local primaryPart = v:FindFirstChild("PrimaryPart") or v:FindFirstChildWhichIsA("Part")
                            if primaryPart then
                                local distance = (hrp.Position - primaryPart.Position).magnitude
                                if distance < minDistance and distance < maxSearchRadius then
                                    minDistance = distance
                                    nearest = breakableObj
                                end
                            end
                        end
                    end
                end
            end
        end
        
        -- Si rien n'a été trouvé, élargir la recherche
        if not nearest then
            for _, v in pairs(workspace:GetDescendants()) do
                if v.Name == "Breakable" and v:IsA("Model") and v:FindFirstChild("Health") and v.Health.Value > 0 then
                    local primaryPart = v:FindFirstChild("PrimaryPart") or v:FindFirstChildWhichIsA("Part")
                    if primaryPart then
                        local distance = (hrp.Position - primaryPart.Position).magnitude
                        if distance < minDistance and distance < maxSearchRadius then
                            minDistance = distance
                            nearest = v
                        end
                    end
                end
            end
        end
        
        return nearest
    end

    -- Fonction pour téléporter en toute sécurité
    local function safelyTeleportTo(position, teleportHeight)
        local character = LocalPlayer.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") or not character:FindFirstChild("Humanoid") then
            return false
        end
        
        -- S'assurer que la téléportation est au-dessus de la zone
        local safePosition = Vector3.new(position.X, position.Y + (teleportHeight or 20), position.Z)
        character.HumanoidRootPart.CFrame = CFrame.new(safePosition)
        
        -- Attendre que le personnage atteigne une position stable
        local startTime = tick()
        local isGrounded = false
        
        -- Boucle pour attendre que le personnage touche le sol ou qu'un délai expire
        while not isGrounded and tick() - startTime < 5 do
            wait(0.1)
            
            -- Vérifier si le personnage est sur le sol
            local rayParams = RaycastParams.new()
            rayParams.FilterType = Enum.RaycastFilterType.Exclude
            rayParams.FilterDescendantsInstances = {character}
            
            local rayResult = workspace:Raycast(character.HumanoidRootPart.Position, Vector3.new(0, -15, 0), rayParams)
            if rayResult and rayResult.Instance then
                isGrounded = true
                
                -- Positionner le personnage juste au-dessus du sol trouvé
                local groundPosition = Vector3.new(position.X, rayResult.Position.Y + 3, position.Z)
                character.HumanoidRootPart.CFrame = CFrame.new(groundPosition)
                
                -- Désactiver le vol
                character.Humanoid.PlatformStand = false
                character.Humanoid:ChangeState(Enum.HumanoidStateType.Landed)
                
                -- Réajuster la position si nécessaire
                if character.Humanoid.FloorMaterial == Enum.Material.Air then
                    character.HumanoidRootPart.CFrame = CFrame.new(groundPosition - Vector3.new(0, 1, 0))
                end
            end
        end
        
        -- Si le personnage n'a pas atteint le sol, forcer une position
        if not isGrounded then
            character.HumanoidRootPart.CFrame = CFrame.new(Vector3.new(position.X, position.Y + 2, position.Z))
            character.Humanoid.PlatformStand = false
            character.Humanoid:ChangeState(Enum.HumanoidStateType.Landed)
        end
        
        return isGrounded
    end

    -- Fonction pour collecter les objets à proximité
    local function collectNearbyItems(radius)
        local character = LocalPlayer.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then return end
        
        local hrp = character.HumanoidRootPart
        local radius = radius or _G.farmRadius
        
        -- Liste des types d'objets à collecter
        local collectibles = {
            {containerName = "Orbs", networkEvent = "CollectOrb"},
            {containerName = "Lootbags", networkEvent = "CollectLootbag"},
            {containerName = "Drops", networkEvent = "Collect"},
            {containerName = "Coins", networkEvent = "Collect"}
        }
        
        for _, collectible in ipairs(collectibles) do
            local container = workspace:FindFirstChild(collectible.containerName)
            if container then
                for _, item in pairs(container:GetChildren()) do
                    if (item.Position - hrp.Position).Magnitude <= radius then
                        pcall(function()
                            -- Essayer les deux méthodes de collecte
                            firetouchinterest(hrp, item, 0)
                            wait()
                            firetouchinterest(hrp, item, 1)
                            
                            -- Utiliser le réseau pour collecter
                            ReplicatedStorage.Network:FireServer(collectible.networkEvent, item)
                        end)
                    end
                end
            end
        end
    end

    -- Auto Tap complètement recodé pour être efficace
    MainSection:NewToggle("Auto Tap", "Tape automatiquement sur les breakables", function(state)
        _G.autoTap = state
        
        -- Fonction locale pour auto-tap
        local function performAutoTap()
            while _G.autoTap do
                if not game:GetService("Players").LocalPlayer then
                    _G.autoTap = false
                    break
                end
                
                local nearest = findNearestBreakable()
                if nearest then
                    -- Utiliser pcall pour éviter les erreurs
                    pcall(function()
                        -- S'assurer que nous sommes assez proches
                        local character = LocalPlayer.Character
                        if character and character:FindFirstChild("HumanoidRootPart") then
                            local hrp = character.HumanoidRootPart
                            local breakablePart = nearest:FindFirstChild("PrimaryPart") or nearest:FindFirstChildWhichIsA("Part")
                            
                            if breakablePart then
                                local distance = (hrp.Position - breakablePart.Position).magnitude
                                
                                if distance > 15 then
                                    -- Se téléporter près du breakable mais pas exactement dessus
                                    local offset = (hrp.Position - breakablePart.Position).Unit * 5
                                    hrp.CFrame = CFrame.new(breakablePart.Position + Vector3.new(0, 3, 0) + offset)
                                end
                                
                                -- Attaquer avec les pets et cliquer
                                ReplicatedStorage.Network:FireServer("PetAttack", nearest)
                                ReplicatedStorage.Network:FireServer("Click", nearest)
                            end
                        end
                    end)
                else
                    -- Cliquer au hasard pour essayer d'atteindre quelque chose
                    pcall(function()
                        ReplicatedStorage.Network:FireServer("Click")
                    end)
                end
                
                -- Collecter automatiquement pendant le tap
                if _G.autoTap then
                    collectNearbyItems(25)
                end
                
                wait(0.05)  -- Délai optimisé
            end
        end
        
        -- Démarrer le auto-tap dans un thread séparé
        if state then
            spawn(performAutoTap)
        end
    end)
    -- Auto Collect amélioré avec limitation de zone
    MainSection:NewToggle("Auto Collect", "Collecte automatiquement tous les objets dans la zone", function(state)
        _G.autoCollect = state
        
        -- Fonction locale pour auto-collect
        local function performAutoCollect()
            while _G.autoCollect do
                if not game:GetService("Players").LocalPlayer then
                    _G.autoCollect = false
                    break
                end
                
                -- Collecter tous les objets à proximité
                collectNearbyItems(_G.farmRadius)
                
                -- Déplacer légèrement pour ramasser les objets à proximité si pas en auto-farm
                if _G.autoCollect and not _G.autoFarm then
                    local character = LocalPlayer.Character
                    if character and character:FindFirstChild("HumanoidRootPart") and character:FindFirstChild("Humanoid") then
                        pcall(function()
                            -- Ne pas déplacer si le personnage est en train de sauter ou de tomber
                            if character.Humanoid:GetState() ~= Enum.HumanoidStateType.Jumping and
                               character.Humanoid:GetState() ~= Enum.HumanoidStateType.Freefall then
                                local randomOffset = Vector3.new(math.random(-5, 5), 0, math.random(-5, 5))
                                character.HumanoidRootPart.CFrame = CFrame.new(character.HumanoidRootPart.Position + randomOffset)
                            end
                        end)
                    end
                end
                
                wait(0.1)  -- Délai optimisé
            end
        end
        
        -- Démarrer l'auto-collect dans un thread séparé
        if state then
            spawn(performAutoCollect)
        end
    end)

    -- Auto Farm complètement recodé
    MainSection:NewToggle("Auto Farm", "Farm automatiquement les breakables dans la zone débloquée", function(state)
        _G.autoFarm = state
        
        -- Fonction locale pour auto-farm
        local function performAutoFarm()
            while _G.autoFarm do
                if not game:GetService("Players").LocalPlayer then
                    _G.autoFarm = false
                    break
                end
                
                -- Obtenir la meilleure zone débloquée dans le monde actuel
                local zoneName, zonePosition = getBestUnlockedZoneInCurrentWorld()
                
                -- Téléporter à la position de sécurité dans la zone
                local teleportSuccessful = safelyTeleportTo(zonePosition, 20)
                if teleportSuccessful then
                    -- Commencer à farmer les breakables
                    local farmStartTime = tick()
                    
                    -- Boucle de farming sur cette zone
                    while _G.autoFarm and tick() - farmStartTime < 15 do
                        local nearest = findNearestBreakable()
                        
                        if nearest then
                            local character = LocalPlayer.Character
                            if character and character:FindFirstChild("HumanoidRootPart") then
                                -- Obtenir la partie principale du breakable
                                local breakablePart = nearest:FindFirstChild("PrimaryPart") or nearest:FindFirstChildWhichIsA("Part")
                                if breakablePart then
                                    -- Se téléporter près du breakable mais pas exactement dessus
                                    local offset = Vector3.new(math.random(-2, 2), 3, math.random(-2, 2))
                                    character.HumanoidRootPart.CFrame = breakablePart.CFrame * CFrame.new(offset)
                                    
                                    -- Attaquer avec les pets et cliquer
                                    ReplicatedStorage.Network:FireServer("PetAttack", nearest)
                                    ReplicatedStorage.Network:FireServer("Click", nearest)
                                    
                                    -- Attendre jusqu'à ce que le breakable soit détruit ou timeout
                                    local breakableTimeout = tick()
                                    while nearest and nearest:FindFirstChild("Health") and nearest.Health.Value > 0 and 
                                          tick() - breakableTimeout < 5 and _G.autoFarm do
                                        
                                        ReplicatedStorage.Network:FireServer("Click", nearest)
                                        collectNearbyItems(_G.farmRadius) -- Collecter en cassant
                                        
                                        wait(0.1)
                                    end
                                end
                            end
                        else
                            -- Si aucun breakable n'est trouvé, explorer un peu la zone
                            local character = LocalPlayer.Character
                            if character and character:FindFirstChild("HumanoidRootPart") then
                                -- Explorer dans un rayon de la zone
                                local randomOffset = Vector3.new(math.random(-15, 15), 0, math.random(-15, 15))
                                safelyTeleportTo(zonePosition + randomOffset, 5)
                                
                                -- Attendre un peu avant de continuer la recherche
                                wait(1)
                            end
                        end
                        
                        -- Collecter les items
                        collectNearbyItems(_G.farmRadius)
                        
                        -- Petit délai pour éviter surcharge
                        wait(0.1)
                    end
                else
                    -- Si la téléportation échoue, attendre avant de réessayer
                    wait(3)
                end
                
                -- Délai entre les cycles complets de farming
                wait(0.5)
            end
        end
        
        -- Démarrer l'auto-farm dans un thread séparé
        if state then
            spawn(performAutoFarm)
        end
    end)

    -- Ajout d'un slider pour le rayon de collecte/farm
    MainSection:NewSlider("Rayon de Farm", "Définit la distance de collecte des objets", 50, 5, function(value)
        _G.farmRadius = value
    end)

    -- Tab Téléportation
    local TeleportTab = Window:NewTab("Téléportation")
    local TeleportSection = TeleportTab:NewSection("Zones")

    -- Téléportation à la dernière zone débloquée dans le monde actuel
    TeleportSection:NewButton("Meilleure zone du monde actuel", "Téléporte à la meilleure zone débloquée", function()
        local zoneName, zonePosition = getBestUnlockedZoneInCurrentWorld()
        safelyTeleportTo(zonePosition, 15)
        
        -- Afficher un message pour informer l'utilisateur
        StarterGui:SetCore("SendNotification", {
            Title = "Téléportation",
            Text = "Téléporté à: " .. zoneName,
            Duration = 3
        })
    end)

    -- Ajouter un bouton pour chaque monde
    for i, world in ipairs(worlds) do
        TeleportSection:NewButton(world.name, "Téléporte au " .. world.name, function()
            -- Téléporter à la première zone du monde
            safelyTeleportTo(world.basePosition, 15)
            
            StarterGui:SetCore("SendNotification", {
                Title = "Téléportation",
                Text = "Téléporté à: " .. world.name,
                Duration = 3
            })
        end)
    end

    -- Téléportation aléatoire sécuritaire
    TeleportSection:NewButton("Zone aléatoire sécuritaire", "Téléporte à un endroit aléatoire sécuritaire", function()
        local character = LocalPlayer.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            pcall(function()
                local currentPos = character.HumanoidRootPart.Position
                local randomOffset = Vector3.new(math.random(-50, 50), 0, math.random(-50, 50))
                -- Ajouter une hauteur sécuritaire
                safelyTeleportTo(currentPos + randomOffset, 10)
                
                StarterGui:SetCore("SendNotification", {
                    Title = "Téléportation",
                    Text = "Téléporté à une zone aléatoire",
                    Duration = 3
                })
            end)
        end
    end)

    -- Tab Performance
    local PerformanceTab = Window:NewTab("Performance")
    local PerformanceSection = PerformanceTab:NewSection("Améliorer FPS")

    -- Boost FPS
    PerformanceSection:NewButton("Boost FPS", "Améliore les performances", function()
        pcall(function()
            -- Désactiver les effets de Lighting
            for _, v in pairs(game:GetService("Lighting"):GetChildren()) do
                if v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or v:IsA("BloomEffect") or v:IsA("ColorCorrectionEffect") then
                    v.Enabled = false
                end
            end
            
            -- Réduire la qualité des graphiques
            settings().Rendering.QualityLevel = 1
            game:GetService("Lighting").GlobalShadows = false
            game:GetService("Lighting").FogEnd = 9e9
            
            -- Simplifier tous les matériaux
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
    
    -- Ajout d'un bouton pour supprimer les effets non essentiels
    PerformanceSection:NewButton("Supprimer Effets", "Supprime les effets visuels pour plus de FPS", function()
        pcall(function()
            for _, v in pairs(workspace:GetDescendants()) do
                if v:IsA("ParticleEmitter") or v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles") then
                    v.Enabled = false
                end
            end
            
            -- Désactiver les sons non essentiels
            for _, v in pairs(workspace:GetDescendants()) do
                if v:IsA("Sound") and v.Name ~= "HumanoidRunningSounds" then
                    v.Volume = 0
                end
            end
            
            StarterGui:SetCore("SendNotification", {
                Title = "Performance",
                Text = "Effets supprimés!",
                Duration = 3
            })
        end)
    end)
    
    -- Tab Info Supplémentaire
    local InfoTab = Window:NewTab("Info")
    local InfoSection = InfoTab:NewSection("Informations")
    
    InfoSection:NewLabel("Version: 3.0")
    InfoSection:NewLabel("Mobile Optimisé: Oui")
    InfoSection:NewLabel("Clé: "..correctKey)
    InfoSection:NewLabel("Dernière zone débloquée: Zone " .. getHighestUnlockedZone())
    
    -- Bouton pour rafraîchir les informations
    InfoSection:NewButton("Rafraîchir Infos", "Met à jour les informations du script", function()
        InfoSection:UpdateLabel("Dernière zone débloquée: Zone " .. getHighestUnlockedZone())
        
        StarterGui:SetCore("SendNotification", {
            Title = "Information",
            Text = "Informations mises à jour!",
            Duration = 3
        })
    end)

    -- Créer un gestionnaire de notification personnalisé
    local function showNotification(title, text, duration)
        pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = title,
                Text = text,
                Duration = duration or 3
            })
        end)
    end
    
    -- Afficher un message de bienvenue
    showNotification("PS99 Mobile Pro", "Script chargé avec succès!", 5)
end

-- Fonction améliorée pour le système de clé avec gestion d'erreurs
local function createSimpleKeyUI()
    -- Supprimer l'ancien système de clé s'il existe
    for _, ui in pairs(game.Players.LocalPlayer.PlayerGui:GetChildren()) do
        if ui.Name == "SimpleKeySystem" then
            ui:Destroy()
        end
    end
    
    -- Créer une nouvelle interface
    pcall(function()
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
        Title.Text = "PS99 Mobile Pro - Clé"
        Title.TextColor3 = Color3.fromRGB(255, 255, 255)
        Title.Font = Enum.Font.SourceSansBold
        Title.TextSize = 18
        Title.Parent = MainFrame
        
        local KeyInput = Instance.new("TextBox")
        KeyInput.Name = "KeyInput"
        KeyInput.Size = UDim2.new(0.8, 0, 0, 30)
        KeyInput.Position = UDim2.new(0.1, 0, 0.4, 0)
        KeyInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        KeyInput.BorderSizePixel = 0
        KeyInput.PlaceholderText = "Entrez la clé ici..."
        KeyInput.Text = ""
        KeyInput.TextColor3 = Color3.fromRGB(255, 255, 255)
        KeyInput.Font = Enum.Font.SourceSans
        KeyInput.TextSize = 16
        KeyInput.Parent = MainFrame
        
        local SubmitButton = Instance.new("TextButton")
        SubmitButton.Name = "SubmitButton"
        SubmitButton.Size = UDim2.new(0.6, 0, 0, 25)
        SubmitButton.Position = UDim2.new(0.2, 0, 0.7, 0)
        SubmitButton.BackgroundColor3 = Color3.fromRGB(0, 120, 180)
        SubmitButton.BorderSizePixel = 0
        SubmitButton.Text = "Valider"
        SubmitButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        SubmitButton.Font = Enum.Font.SourceSansBold
        SubmitButton.TextSize = 16
        SubmitButton.Parent = MainFrame
        
        -- Fonction de validation de la clé
        local function validateKey()
            local inputKey = KeyInput.Text
            
            if inputKey == correctKey then
                ScreenGui:Destroy()
                loadScript()
            else
                Title.Text = "Clé incorrecte!"
                Title.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
                wait(1.5)
                Title.Text = "PS99 Mobile Pro - Clé"
                Title.BackgroundColor3 = Color3.fromRGB(0, 85, 127)
            end
        end
        
        -- Connecter le bouton à la fonction de validation
        SubmitButton.MouseButton1Click:Connect(validateKey)
        
        -- Aussi valider quand on appuie sur Entrée
        KeyInput.FocusLost:Connect(function(enterPressed)
            if enterPressed then
                validateKey()
            end
        end)
    end)
end

-- Fonction pour démarrer le script avec le système de clé
local function startScript()
    -- Vérifier si le système de clé est activé
    if keySystem then
        createSimpleKeyUI()
    else
        -- Sinon charger directement le script
        loadScript()
    end
end

-- Démarrer le script après un petit délai pour s'assurer que tout est chargé
wait(1)
startScript()
