-- Script PS99 optimisé pour Delta avec UI amélioré et draggable
-- Version 3.5 avec système de clé, téléportations fixes et performance optimisée

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

    -- Structure corrigée des mondes et leurs limites de zones
    local worlds = {
        {name = "Spawn World", minZone = 1, maxZone = 99, basePosition = Vector3.new(170, 130, 250), offsetX = 5, offsetZ = 3},
        {name = "Tech World", minZone = 100, maxZone = 199, basePosition = Vector3.new(4325, 130, 1850), offsetX = 3, offsetZ = 0},
        {name = "Void World", minZone = 200, maxZone = 239, basePosition = Vector3.new(3678, 130, 1340), offsetX = 0, offsetZ = -3}
    }

    -- Fonction pour déterminer le monde actuel basé sur la position
    local function getCurrentWorld()
        local character = LocalPlayer.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then 
            return worlds[1] -- Par défaut, Spawn World
        end
        
        local currentPosition = character.HumanoidRootPart.Position
        
        -- Logic améliorée pour identifier le monde actuel
        if currentPosition.X < 3000 then
            return worlds[1] -- Spawn World
        elseif currentPosition.X > 4000 then
            return worlds[2] -- Tech World
        elseif currentPosition.X > 3000 and currentPosition.Z < 1500 then
            return worlds[3] -- Void World
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
            for i = 1, 239 do -- Augmenté à 239 pour couvrir toutes les zones possibles
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
        
        -- Calculer la position de la zone (au MILIEU de la zone)
        local zonePosition = Vector3.new(
            currentWorld.basePosition.X + (offset * currentWorld.offsetX),
            currentWorld.basePosition.Y,
            currentWorld.basePosition.Z + (offset * currentWorld.offsetZ)
        )
        
        return currentWorld.name .. " Zone " .. zoneInWorld, zonePosition
    end

    -- Fonction améliorée pour trouver le breakable le plus proche
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

    -- Fonction améliorée de téléportation sécurisée pour toujours atterrir sur une surface solide
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
        
        -- Effectuer un rayon vers le bas pour trouver une surface solide
        while not isGrounded and tick() - startTime < 5 do
            wait(0.1)
            
            -- Vérifier si le personnage est sur le sol ou peut y atterrir
            local rayParams = RaycastParams.new()
            rayParams.FilterType = Enum.RaycastFilterType.Exclude
            rayParams.FilterDescendantsInstances = {character}
            
            -- Rayon plus long pour chercher le sol
            local rayResult = workspace:Raycast(character.HumanoidRootPart.Position, Vector3.new(0, -100, 0), rayParams)
            if rayResult and rayResult.Instance then
                isGrounded = true
                
                -- Positionner le personnage juste au-dessus du sol trouvé
                local groundPosition = Vector3.new(position.X, rayResult.Position.Y + 5, position.Z)
                character.HumanoidRootPart.CFrame = CFrame.new(groundPosition)
                
                -- Désactiver le vol et stabiliser le personnage
                character.Humanoid.PlatformStand = false
                character.Humanoid:ChangeState(Enum.HumanoidStateType.Landed)
                
                -- Réajuster si nécessaire
                wait(0.2)
                if character.Humanoid.FloorMaterial == Enum.Material.Air then
                    character.HumanoidRootPart.CFrame = CFrame.new(groundPosition - Vector3.new(0, 3, 0))
                    wait(0.2)
                end
            end
        end
        
        -- Si aucun sol n'est trouvé, élargir la recherche en spirale
        if not isGrounded then
            for i = 1, 5 do
                -- Chercher un sol en spirale croissante
                for j = 1, 8 do
                    local angle = j * math.pi / 4
                    local offset = Vector3.new(math.cos(angle) * i * 5, 0, math.sin(angle) * i * 5)
                    local testPosition = position + offset
                    
                    local rayResult = workspace:Raycast(Vector3.new(testPosition.X, testPosition.Y + 50, testPosition.Z), Vector3.new(0, -100, 0), rayParams)
                    if rayResult and rayResult.Instance then
                        -- Sol trouvé, on téléporte
                        local groundPosition = Vector3.new(testPosition.X, rayResult.Position.Y + 5, testPosition.Z)
                        character.HumanoidRootPart.CFrame = CFrame.new(groundPosition)
                        character.Humanoid.PlatformStand = false
                        character.Humanoid:ChangeState(Enum.HumanoidStateType.Landed)
                        return true
                    end
                end
                wait(0.1)
            end
            
            -- Si toujours pas de sol, retourner à la position initiale
            character.HumanoidRootPart.CFrame = CFrame.new(position)
            return false
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
                spawn(performAutoCollect)
        end
    end)

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

    -- Auto Farm amélioré pour stabiliser au centre de la zone et se téléporter efficacement
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
                
                -- Téléporter au centre de la zone et stabiliser
                local teleportSuccessful = safelyTeleportTo(zonePosition, 20)
                
                -- Afficher les informations de la zone
                StarterGui:SetCore("SendNotification", {
                    Title = "Auto Farm",
                    Text = "Farming dans " .. zoneName,
                    Duration = 3
                })
                
                if teleportSuccessful then
                    -- Commencer à farmer les breakables depuis cette position centrale
                    local farmStartTime = tick()
                    local farmScanCount = 0
                    
                    -- Boucle de farming dans cette zone
                    while _G.autoFarm and tick() - farmStartTime < 30 and farmScanCount < 10 do
                        local nearestBreakable = findNearestBreakable()
                        
                        if nearestBreakable then
                            farmScanCount = 0 -- Réinitialiser le compteur si on a trouvé un breakable
                            
                            local character = LocalPlayer.Character
                            if character and character:FindFirstChild("HumanoidRootPart") then
                                -- Obtenir la partie principale du breakable
                                local breakablePart = nearestBreakable:FindFirstChild("PrimaryPart") or 
                                                      nearestBreakable:FindFirstChildWhichIsA("Part")
                                
                                if breakablePart then
                                    -- Se téléporter directement près du breakable avec un petit offset aléatoire
                                    local offset = Vector3.new(math.random(-2, 2), 3, math.random(-2, 2))
                                    character.HumanoidRootPart.CFrame = breakablePart.CFrame * CFrame.new(offset)
                                    
                                    -- Attaquer avec les pets et cliquer
                                    ReplicatedStorage.Network:FireServer("PetAttack", nearestBreakable)
                                    ReplicatedStorage.Network:FireServer("Click", nearestBreakable)
                                    
                                    -- Attaquer jusqu'à destruction ou timeout
                                    local breakableTimeout = tick()
                                    while nearestBreakable and nearestBreakable:FindFirstChild("Health") and 
                                          nearestBreakable.Health.Value > 0 and tick() - breakableTimeout < 5 and _G.autoFarm do
                                        
                                        -- Attaquer à nouveau
                                        ReplicatedStorage.Network:FireServer("Click", nearestBreakable)
                                        
                                        -- Collecter en même temps
                                        collectNearbyItems(_G.farmRadius)
                                        
                                        wait(0.1)
                                    end
                                    
                                    -- Collecter tous les objets après avoir détruit le breakable
                                    collectNearbyItems(_G.farmRadius * 1.5)
                                end
                            end
                        else
                            -- Incrémenter le compteur d'échecs de scan
                            farmScanCount = farmScanCount + 1
                            
                            -- Explorer un peu plus loin si rien n'est trouvé
                            if farmScanCount > 3 then
                                -- Essayer de regarder plus loin dans différentes directions
                                local character = LocalPlayer.Character
                                if character and character:FindFirstChild("HumanoidRootPart") then
                                    -- Explorer dans un rayon de la zone en spirale
                                    local angle = farmScanCount * math.pi / 4
                                    local radius = 10 + (farmScanCount * 5)
                                    local exploreOffset = Vector3.new(
                                        math.cos(angle) * radius,
                                        0,
                                        math.sin(angle) * radius
                                    )
                                    
                                    -- Téléportation temporaire pour explorer
                                    character.HumanoidRootPart.CFrame = CFrame.new(zonePosition + exploreOffset)
                                    wait(0.5)
                                end
                            end
                            
                            wait(0.3)
                        end
                    end
                    
                    -- Une fois que le cycle de farm est terminé, retourner au centre de la zone
                    safelyTeleportTo(zonePosition, 10)
                else
                    -- Si la téléportation échoue, attendre avant de réessayer
                    wait(3)
                end
                
                -- Petit délai entre les cycles complets de farming
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

    -- Tab Téléportation avec correction des téléportations
    local TeleportTab = Window:NewTab("Téléportation")
    local TeleportSection = TeleportTab:NewSection("Zones")

    -- Téléportation à la dernière zone débloquée dans le monde actuel
    TeleportSection:NewButton("Meilleure zone du monde actuel", "Téléporte à la meilleure zone débloquée", function()
        local zoneName, zonePosition = getBestUnlockedZoneInCurrentWorld()
        local success = safelyTeleportTo(zonePosition, 15)
        
        -- Afficher un message pour informer l'utilisateur
        if success then
            StarterGui:SetCore("SendNotification", {
                Title = "Téléportation",
                Text = "Téléporté à: " .. zoneName,
                Duration = 3
            })
        else
            StarterGui:SetCore("SendNotification", {
                Title = "Téléportation",
                Text = "Erreur: Impossible de trouver un sol solide",
                Duration = 3
            })
        end
    end)

    -- Ajouter un bouton pour chaque monde avec téléportation sécurisée
    for i, world in ipairs(worlds) do
        TeleportSection:NewButton(world.name, "Téléporte au " .. world.name, function()
            -- Points de téléportation sécurisés pour chaque monde
            local safePositions = {
                [1] = Vector3.new(170, 130, 250), -- Spawn World
                [2] = Vector3.new(4325, 130, 1850), -- Tech World
                [3] = Vector3.new(3678, 130, 1340), -- Void World
            }
            
            -- Téléporter à la position sécurisée du monde
            local success = safelyTeleportTo(safePositions[i], 15)
            
            if success then
                StarterGui:SetCore("SendNotification", {
                    Title = "Téléportation",
                    Text = "Téléporté à: " .. world.name,
                    Duration = 3
                })
            else
                -- Réessayer avec une hauteur différente si la première tentative échoue
                success = safelyTeleportTo(safePositions[i], 30)
                
                if success then
                    StarterGui:SetCore("SendNotification", {
                        Title = "Téléportation",
                        Text = "Téléporté à: " .. world.name .. " (2e essai)",
                        Duration = 3
                    })
                else
                    StarterGui:SetCore("SendNotification", {
                        Title = "Téléportation",
                        Text = "Erreur: Impossible de trouver un sol solide",
                        Duration = 3
                    })
                end
            end
        end)
    end

    -- Téléportation à des zones spécifiques
    TeleportSection:NewSection("Zones spécifiques")
    
    -- Ajouter des boutons pour des zones spécifiques dans chaque monde
    local specificZones = {
        {world = "Spawn World", zone = 50, name = "Spawn Zone 50"},
        {world = "Tech World", zone = 150, name = "Tech Zone 150"},
        {world = "Void World", zone = 220, name = "Void Zone 220"}
    }
    
    for _, zoneInfo in ipairs(specificZones) do
        TeleportSection:NewButton(zoneInfo.name, "Téléporte à " .. zoneInfo.name, function()
            -- Trouver le monde correspondant
            local worldData
            for _, world in ipairs(worlds) do
                if world.name == zoneInfo.world then
                    worldData = world
                    break
                end
            end
            
            if worldData then
                -- Calculer la position de la zone spécifique
                local offset = zoneInfo.zone - worldData.minZone + 1
                local zonePosition = Vector3.new(
                    worldData.basePosition.X + (offset * worldData.offsetX),
                    worldData.basePosition.Y,
                    worldData.basePosition.Z + (offset * worldData.offsetZ)
                )
                
                -- Téléporter à cette zone spécifique
                local success = safelyTeleportTo(zonePosition, 15)
                
                if success then
                    StarterGui:SetCore("SendNotification", {
                        Title = "Téléportation",
                        Text = "Téléporté à: " .. zoneInfo.name,
                        Duration = 3
                    })
                else
                    StarterGui:SetCore("SendNotification", {
                        Title = "Téléportation",
                        Text = "Erreur: Impossible de trouver un sol solide",
                        Duration = 3
                    })
                end
            end
        end)
    end

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
    
    InfoSection:NewLabel("Version: 3.5")
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
    
    -- UI Settings pour permettre le drag et autres options UI
    local UISettingsTab = Window:NewTab("UI Settings")
    local UISettingsSection = UISettingsTab:NewSection("Paramètres d'interface")
    
    -- Option pour minimiser l'UI
    UISettingsSection:NewToggle("Minimiser UI", "Cache/Affiche l'interface", function(state)
        _G.uiMinimized = state
        
        for _, tab in pairs(Window.Tabs) do
            if tab.Name ~= "UI Settings" then
                for _, section in pairs(tab.Sections) do
                    section.Frame.Visible = not _G.uiMinimized
                end
            end
        end
        
        StarterGui:SetCore("SendNotification", {
            Title = "UI Settings",
            Text = _G.uiMinimized and "Interface minimisée" or "Interface restaurée",
            Duration = 2
        })
    end)
    
    -- Ajouter une option pour afficher/masquer les notifications
    local notificationsEnabled = true
    UISettingsSection:NewToggle("Notifications", "Active/Désactive les notifications", function(state)
        notificationsEnabled = state
        
        -- Remplacer la fonction de notification si désactivé
        if not notificationsEnabled then
            local oldSetCore = StarterGui.SetCore
            StarterGui.SetCore = function(self, ...)
                local args = {...}
                if args[1] == "SendNotification" then
                    return -- Ne rien faire si c'est une notification
                end
                return oldSetCore(self, ...)
            end
        else
            -- Restaurer la fonction originale
            StarterGui.SetCore = game:GetService("StarterGui").SetCore
        end
        
        -- Afficher une dernière notification
        if notificationsEnabled then
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "UI Settings",
                Text = "Notifications activées",
                Duration = 2
            })
        end
    end)
    
    -- Fonction pour montrer une notification de bienvenue
    local function showWelcomeNotification()
        -- Délai pour s'assurer que l'UI est chargée
        wait(1)
        StarterGui:SetCore("SendNotification", {
            Title = "PS99 Mobile Pro",
            Text = "Script chargé avec succès! Version 3.5",
            Duration = 5
        })
    end
    
    -- Afficher le message de bienvenue
    showWelcomeNotification()
    
    -- Configuration d'anti-détection basique
    pcall(function()
        local MT = getrawmetatable(game)
        local oldNamecall = MT.__namecall
        setreadonly(MT, false)
        
        MT.__namecall = newcclosure(function(self, ...)
            local args = {...}
            local method = getnamecallmethod()
            
            -- Bloquer certaines méthodes de détection
            if method == "Kick" or method == "FireServer" and args[1] == "BanRemote" then
                return nil
            end
            
            return oldNamecall(self, ...)
        end)
        
        setreadonly(MT, true)
    end)
    
    return true -- Retourne vrai si le script a été chargé avec succès
end

-- Gérer le système de clé
if keySystem then
    -- Créer l'interface du système de clé
    local keyInterface = createSimpleKeyUI()
    
    -- Si une clé a été précédemment enregistrée et valide, charger directement le script
    local savedKey = game:GetService("Players").LocalPlayer:FindFirstChild("SavedKey")
    if savedKey and savedKey.Value == correctKey then
        loadScript()
    else
        -- Attendre l'entrée de la clé
        -- Note: Cette partie nécessiterait une implémentation d'interface utilisateur
        -- que nous simulons ici en chargeant directement le script
        print("Entrez la clé ou utilisez 'zekyu'")
        loadScript()
    end
else
    -- Si le système de clé est désactivé, charger directement le script
    loadScript()
end


        
