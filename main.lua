-- Script PS99 optimisé pour Delta avec UI amélioré et draggable
-- Version 4.0 avec coordonnées corrigées et téléportation améliorée

-- Système de clé d'authentification
local keySystem = true
local correctKey = "zekyu"

-- Fonction principale pour charger le script
function loadScript()
    -- Chargement de la bibliothèque UI
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
    _G.farmRadius = 20
    _G.teleportInProgress = false
    _G.teleportHeight = 50  -- Hauteur de téléportation augmentée
    _G.infinitePetsSpeed = false
    
    -- Services
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local StarterGui = game:GetService("StarterGui")
    local LocalPlayer = Players.LocalPlayer
    
    -- Fonction Anti-AFK
    local function antiAfk()
        local VirtualUser = game:GetService("VirtualUser")
        LocalPlayer.Idled:Connect(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
            StarterGui:SetCore("SendNotification", {Title = "Anti-AFK", Text = "Anti-AFK activé", Duration = 3})
        end)
    end
    antiAfk()

    -- Tab principal
    local MainTab = Window:NewTab("Principal")
    local MainSection = MainTab:NewSection("Farming")
    
    -- Tab Event Actuel
    local EventTab = Window:NewTab("Event Actuel")
    local EventSection = EventTab:NewSection("Téléportation & Farming")
    
    -- Ajout d'un ScrollingFrame pour le défilement
    local function createScrollableSection(section)
        -- Cette fonction simule un comportement de défilement en réorganisant les éléments
        -- Comme la Kavo UI n'a pas de scrolling natif, cette fonction est juste préparatoire
        -- Les éléments s'ajouteront verticalement avec un espacement automatique
        return section
    end
    
    -- Appliquer le défilement à notre section Event
    EventSection = createScrollableSection(EventSection)

    -- Structure des mondes et leurs limites de zones avec les coordonnées ajustées
    local worlds = {
        {name = "Spawn World", minZone = 1, maxZone = 99, basePosition = Vector3.new(121.71, 25.54, -204.95), offsetX = 5, offsetZ = 3},
        {name = "Tech World", minZone = 100, maxZone = 199, basePosition = Vector3.new(-9987.57, 25.5, -358.72), offsetX = 3, offsetZ = 0},
        {name = "Void World", minZone = 200, maxZone = 239, basePosition = Vector3.new(-10266.83, 15.17, -7358.04), offsetX = 0, offsetZ = -3}
    }

    -- Fonction pour déterminer le monde actuel
    local function getCurrentWorld()
        local character = LocalPlayer.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then 
            return worlds[1]
        end
        
        local currentPosition = character.HumanoidRootPart.Position
        
        -- Logique de détection basée sur les coordonnées ajustées
        if currentPosition.Z < 0 and currentPosition.X > -1000 and currentPosition.X < 1000 then
            return worlds[1] -- Spawn World
        elseif currentPosition.X < -9000 and currentPosition.Z > -1000 then
            return worlds[2] -- Tech World
        elseif currentPosition.X < -9000 and currentPosition.Z < -7000 then
            return worlds[3] -- Void World
        else
            return worlds[1]
        end
    end

    -- Fonction pour obtenir la zone débloquée la plus élevée
    local function getHighestUnlockedZone()
        if _G.lastHighestZone and _G.lastUpdateTime and tick() - _G.lastUpdateTime < 10 then
            return _G.lastHighestZone
        end
        
        local playerStats = LocalPlayer:WaitForChild("PlayerGui", 5):FindFirstChild("Main")
        local highestZone = 1
        
        -- Vérifier les zones débloquées dans l'interface
        if playerStats and playerStats:FindFirstChild("UnlockedZones") then
            for i = 1, 239 do
                if playerStats.UnlockedZones:FindFirstChild("Zone"..i) and playerStats.UnlockedZones["Zone"..i].Value then
                    highestZone = i
                else
                    break
                end
            end
        end
        
        -- Vérifier dans les variables de jeu si disponible
        pcall(function()
            local gameData = LocalPlayer:FindFirstChild("GameData")
            if gameData and gameData:FindFirstChild("UnlockedZones") then
                for i = 1, 239 do
                    local zoneValue = gameData.UnlockedZones:FindFirstChild("Zone"..i)
                    if zoneValue and zoneValue.Value then
                        highestZone = i
                    else
                        break
                    end
                end
            end
        end)
        
        _G.lastHighestZone = highestZone
        _G.lastUpdateTime = tick()
        
        return highestZone
    end

    -- Fonction pour obtenir la position de la meilleure zone débloquée
    local function getBestUnlockedZoneInCurrentWorld()
        local currentWorld = getCurrentWorld()
        local highestUnlockedZone = getHighestUnlockedZone()
        
        -- S'assurer que nous utilisons la zone la plus élevée possible dans le monde actuel
        local zoneInWorld = highestUnlockedZone
        
        -- Si la zone la plus élevée est supérieure au maximum du monde actuel, utiliser le maximum du monde
        if zoneInWorld > currentWorld.maxZone then
            zoneInWorld = currentWorld.maxZone
        end
        
        -- Si la zone la plus élevée est inférieure au minimum du monde actuel, utiliser le minimum du monde
        if zoneInWorld < currentWorld.minZone then
            -- Cas où nous sommes dans un monde plus avancé mais n'avons pas encore débloqué de zones
            -- Retourner au monde précédent où nous avons des zones débloquées
            if currentWorld.name ~= "Spawn World" then
                for i, world in ipairs(worlds) do
                    if world.name == currentWorld.name then
                        -- Trouver le monde précédent
                        if i > 1 then
                            local prevWorld = worlds[i-1]
                            local bestZoneInPrevWorld = math.min(highestUnlockedZone, prevWorld.maxZone)
                            
                            -- Calculer la position dans le monde précédent
                            local offset = bestZoneInPrevWorld - prevWorld.minZone + 1
                            local zonePosition = Vector3.new(
                                prevWorld.basePosition.X + (offset * prevWorld.offsetX),
                                prevWorld.basePosition.Y,
                                prevWorld.basePosition.Z + (offset * prevWorld.offsetZ)
                            )
                            
                            return prevWorld.name .. " Zone " .. bestZoneInPrevWorld, zonePosition
                        end
                        break
                    end
                end
            end
            
            -- Si nous sommes dans le monde de départ ou si aucun monde précédent n'est trouvé
            zoneInWorld = currentWorld.minZone
        end
        
        -- Calculer la position de la zone
        local offset = zoneInWorld - currentWorld.minZone + 1
        local zonePosition = Vector3.new(
            currentWorld.basePosition.X + (offset * currentWorld.offsetX),
            currentWorld.basePosition.Y,
            currentWorld.basePosition.Z + (offset * currentWorld.offsetZ)
        )
        
        -- Correction spéciale pour la best zone
        if currentWorld.name == "Void World" and zoneInWorld == currentWorld.maxZone then
            zonePosition = Vector3.new(-61.88, 165.54, 6424.32)  -- Hauteur augmentée
        end
        
        return currentWorld.name .. " Zone " .. zoneInWorld, zonePosition
    end

    -- Fonction pour trouver le breakable le plus proche
    local function findNearestBreakable()
        local character = LocalPlayer.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then return nil end
        
        local hrp = character.HumanoidRootPart
        local nearest = nil
        local minDistance = math.huge
        local maxSearchRadius = 60
        
        -- Recherche dans les conteneurs spécifiques
        for _, containerName in ipairs({"Breakables", "Breakable", "Zone"}) do
            local container = workspace:FindFirstChild(containerName)
            if container then
                for _, v in pairs(container:GetChildren()) do
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
        
        return nearest
    end

    -- Fonction améliorée de téléportation sécurisée avec écran de chargement et stabilisation
    local function safelyTeleportTo(position, customHeight)
        local character = LocalPlayer.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then return false end
        
        if _G.teleportInProgress then return false end
        _G.teleportInProgress = true
        
        -- Créer écran de chargement
        local loadingScreen = Instance.new("ScreenGui")
        local loadingFrame = Instance.new("Frame")
        local loadingText = Instance.new("TextLabel")
        local loadingBar = Instance.new("Frame")
        local loadingFill = Instance.new("Frame")
        
        loadingScreen.Name = "TeleportLoadingScreen"
        loadingScreen.Parent = LocalPlayer:WaitForChild("PlayerGui")
        loadingScreen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        
        loadingFrame.Name = "LoadingFrame"
        loadingFrame.Parent = loadingScreen
        loadingFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
        loadingFrame.BorderSizePixel = 0
        loadingFrame.Position = UDim2.new(0.5, -150, 0.5, -50)
        loadingFrame.Size = UDim2.new(0, 300, 0, 100)
        
        loadingText.Name = "LoadingText"
        loadingText.Parent = loadingFrame
        loadingText.BackgroundTransparency = 1
        loadingText.Position = UDim2.new(0, 0, 0, 10)
        loadingText.Size = UDim2.new(1, 0, 0, 30)
        loadingText.Font = Enum.Font.GothamBold
        loadingText.Text = "Téléportation en cours..."
        loadingText.TextColor3 = Color3.fromRGB(255, 255, 255)
        loadingText.TextSize = 18
        
        loadingBar.Name = "LoadingBar"
        loadingBar.Parent = loadingFrame
        loadingBar.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
        loadingBar.BorderSizePixel = 0
        loadingBar.Position = UDim2.new(0.1, 0, 0.6, 0)
        loadingBar.Size = UDim2.new(0.8, 0, 0, 20)
        
        loadingFill.Name = "LoadingFill"
        loadingFill.Parent = loadingBar
        loadingFill.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
        loadingFill.BorderSizePixel = 0
        loadingFill.Size = UDim2.new(0, 0, 1, 0)
        
        -- Animation de la barre de chargement
        spawn(function()
            for i = 0, 10 do
                loadingFill.Size = UDim2.new(i/10, 0, 1, 0)
                wait(0.1)
            end
        end)
        
        -- Hauteur de téléportation augmentée
        local teleportHeight = customHeight or _G.teleportHeight
        
        -- Ajout d'un offset aléatoire pour éviter les obstacles
        local randomOffset = Vector3.new(math.random(-5, 5), 0, math.random(-5, 5))
        local safePosition = Vector3.new(position.X, position.Y + teleportHeight, position.Z) + randomOffset
        
        -- Téléportation avec ancrage temporaire pour stabilisation
        character.HumanoidRootPart.CFrame = CFrame.new(safePosition)
        character.HumanoidRootPart.Anchored = true
        
        -- Attendre que le sol charge
        loadingText.Text = "Chargement du sol..."
        wait(1.5)
        -- Recherche du sol par raycast en descendant progressivement
        local rayParams = RaycastParams.new()
        rayParams.FilterType = Enum.RaycastFilterType.Blacklist
        rayParams.FilterDescendantsInstances = {character}
        
        -- Tentative de détection du sol avec un rayon plus long
        local rayResult = workspace:Raycast(safePosition, Vector3.new(0, -100, 0), rayParams)
        
        if rayResult then
            -- Sol trouvé, se téléporter juste au-dessus
            loadingText.Text = "Sol trouvé!"
            local floorPosition = rayResult.Position + Vector3.new(0, 5, 0)  -- 5 unités au-dessus du sol
            character.HumanoidRootPart.CFrame = CFrame.new(floorPosition)
            wait(0.5)
        else
            -- Descente progressive pour trouver le sol
            loadingText.Text = "Recherche du sol..."
            local foundGround = false
            
            -- Descendre par paliers de 10 unités
            for height = 0, -200, -10 do
                local testPosition = Vector3.new(safePosition.X, safePosition.Y + height, safePosition.Z)
                character.HumanoidRootPart.CFrame = CFrame.new(testPosition)
                wait(0.2)
                
                -- Vérifier s'il y a un sol en dessous
                local rayResult = workspace:Raycast(testPosition, Vector3.new(0, -20, 0), rayParams)
                if rayResult then
                    -- Sol trouvé
                    local floorPosition = rayResult.Position + Vector3.new(0, 5, 0)
                    character.HumanoidRootPart.CFrame = CFrame.new(floorPosition)
                    foundGround = true
                    loadingText.Text = "Sol trouvé à " .. math.floor(floorPosition.Y) .. " unités!"
                    break
                end
            end
            
            -- Si aucun sol n'est trouvé, utiliser une position sécurisée par défaut
            if not foundGround then
                loadingText.Text = "Sol non trouvé, utilisation de position par défaut..."
                local defaultY = position.Y + 10  -- Position Y par défaut
                character.HumanoidRootPart.CFrame = CFrame.new(Vector3.new(position.X, defaultY, position.Z))
            end
        end
        
        -- Stabiliser en restant ancré pendant un moment
        wait(1)
        
        -- Désancrer progressivement pour éviter les chutes brutales
        loadingText.Text = "Stabilisation..."
        
        -- Appliquer une vélocité vers le haut pour contrer la gravité lors du désancrage
        character.HumanoidRootPart.Velocity = Vector3.new(0, 5, 0)
        character.HumanoidRootPart.Anchored = false
        
        -- Vérifier si le personnage est bien positionné après le désancrage
        wait(0.5)
        
        -- Retirer l'écran de chargement
        loadingScreen:Destroy()
        _G.teleportInProgress = false
        return true
    end

    -- Fonction pour collecter les objets à proximité
    local function collectNearbyItems(radius)
        local character = LocalPlayer.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then return end
        
        local hrp = character.HumanoidRootPart
        local radius = radius or _G.farmRadius
        
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
                            firetouchinterest(hrp, item, 0)
                            wait()
                            firetouchinterest(hrp, item, 1)
                            ReplicatedStorage.Network:FireServer(collectible.networkEvent, item)
                        end)
                    end
                end
            end
        end
    end
