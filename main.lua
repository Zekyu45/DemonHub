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

    -- Auto Collect function (corrigé - manquait dans l'original)
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
        
        -- Démarrer l'auto-collect dans un thread séparé
        if state then
            spawn(performAutoCollect)
        end
    end)
    
