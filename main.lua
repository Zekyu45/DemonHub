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

    -- Fonction Auto Collect
    local function performAutoCollect()
        while _G.autoCollect do
            if not game:GetService("Players").LocalPlayer then
                _G.autoCollect = false
                break
            end
            
            collectNearbyItems(_G.farmRadius)
            wait(0.1)
        end
    end

    -- Auto Tap
    MainSection:NewToggle("Auto Tap", "Tape automatiquement sur les breakables", function(state)
        _G.autoTap = state
        
        if state then
            spawn(function()
                while _G.autoTap do
                    if not game:GetService("Players").LocalPlayer then break end
                    
                    local nearest = findNearestBreakable()
                    if nearest then
                        pcall(function()
                            local character = LocalPlayer.Character
                            if character and character:FindFirstChild("HumanoidRootPart") then
                                local hrp = character.HumanoidRootPart
                                local breakablePart = nearest:FindFirstChild("PrimaryPart") or nearest:FindFirstChildWhichIsA("Part")
                                
                                if breakablePart and (hrp.Position - breakablePart.Position).magnitude > 15 then
                                    -- Téléportation améliorée vers le breakable
                                    hrp.CFrame = CFrame.new(breakablePart.Position + Vector3.new(0, 5, 0))
                                end
                                
                                ReplicatedStorage.Network:FireServer("PetAttack", nearest)
                                ReplicatedStorage.Network:FireServer("Click", nearest)
                            end
                        end)
                    else
                        pcall(function() ReplicatedStorage.Network:FireServer("Click") end)
                    end
                    
                    if _G.autoTap then collectNearbyItems(25) end
                    wait(0.05)
                end
            end)
        end
    end)

    -- Auto Collect
    MainSection:NewToggle("Auto Collect", "Collecte automatiquement tous les objets", function(state)
        _G.autoCollect = state
        if state then spawn(performAutoCollect) end
    end)

    -- Auto Farm
    MainSection:NewToggle("Auto Farm", "Farm automatiquement dans la zone débloquée", function(state)
        _G.autoFarm = state
        
        if state then
            spawn(function()
                while _G.autoFarm do
                    if not game:GetService("Players").LocalPlayer then break end
                    
                    -- Obtenir la meilleure zone débloquée dans le monde actuel
                    local zoneName, zonePosition = getBestUnlockedZoneInCurrentWorld()
                    local teleportSuccess = safelyTeleportTo(zonePosition, 60)  -- Hauteur augmentée pour éviter les obstacles
                    
                    if teleportSuccess then
                        StarterGui:SetCore("SendNotification", {
                            Title = "Auto Farm",
                            Text = "Farming dans " .. zoneName,
                            Duration = 3
                        })
                        
                        local farmTime = 0
                        local consecutiveNoBreakables = 0
                        
                        while _G.autoFarm and farmTime < 30 and consecutiveNoBreakables < 3 do
                            local nearest = findNearestBreakable()
                            
                            if nearest then
                                consecutiveNoBreakables = 0
                                local character = LocalPlayer.Character
                                if character and character:FindFirstChild("HumanoidRootPart") then
                                    local breakablePart = nearest:FindFirstChild("PrimaryPart") or nearest:FindFirstChildWhichIsA("Part")
                                    
                                    if breakablePart then
                                        -- Téléportation avec un petit offset aléatoire et hauteur ajustée
                                        local randomOffset = Vector3.new(math.random(-2, 2), 0, math.random(-2, 2))
                                        character.HumanoidRootPart.CFrame = breakablePart.CFrame * CFrame.new(randomOffset.X, 5, randomOffset.Z)
                                        
                                        -- Utiliser ancrage temporaire pour stabiliser
                                        character.HumanoidRootPart.Anchored = true
                                        wait(0.1)
                                        character.HumanoidRootPart.Anchored = false
                                        
                                        ReplicatedStorage.Network:FireServer("PetAttack", nearest)
                                        ReplicatedStorage.Network:FireServer("Click", nearest)
                                        
                                        local attackStart = tick()
                                        while nearest and nearest:FindFirstChild("Health") and 
                                              nearest.Health.Value > 0 and tick() - attackStart < 5 and _G.autoFarm do
                                            ReplicatedStorage.Network:FireServer("Click", nearest)
                                            collectNearbyItems(_G.farmRadius)
                                            wait(0.1)
                                        end
                                        
                                        collectNearbyItems(_G.farmRadius * 1.5)
                                    end
                                end
                            else
                                consecutiveNoBreakables = consecutiveNoBreakables + 1
                                local character = LocalPlayer.Character
                                if character and character:FindFirstChild("HumanoidRootPart") then
                                    -- Explorer la zone avec un rayon plus grand pour trouver des breakables
                                    local angle = farmTime * math.pi / 6
                                    local radius = 10 + (farmTime % 4) * 5
                                    local exploreOffset = Vector3.new(
                                        math.cos(angle) * radius,
                                        0,
                                        math.sin(angle) * radius
                                    )
                                    
                                    -- Téléportation avec ancrage temporaire pour stabiliser
                                    character.HumanoidRootPart.CFrame = CFrame.new(zonePosition + exploreOffset)
                                    character.HumanoidRootPart.Anchored = true
                                    wait(0.1)
                                    character.HumanoidRootPart.Anchored = false
                                end
                                wait(0.3)
                            end
                            
                            farmTime = farmTime + 1
                            wait(0.1)
                        end
                    else
                        wait(1)
                    end
                    
                    wait(0.5)
                end
            end)
        end
    end)

    -- Slider pour le rayon de farm
    MainSection:NewSlider("Rayon de Farm", "Définit la distance de collecte", 50, 5, function(value)
        _G.farmRadius = value
    end)
    
    -- Slider pour la hauteur de téléportation
    MainSection:NewSlider("Hauteur TP", "Définit la hauteur de téléportation", 100, 20, function(value)
        _G.teleportHeight = value
    end)

    -- Tab Téléportation
    local TeleportTab = Window:NewTab("Téléportation")
    local TeleportSection = TeleportTab:NewSection("Zones")

    -- Téléportation à la meilleure zone
    TeleportSection:NewButton("Meilleure zone", "Téléporte à la meilleure zone débloquée", function()
        local zoneName, zonePosition = getBestUnlockedZoneInCurrentWorld()
        local teleportSuccess = safelyTeleportTo(zonePosition, _G.teleportHeight)
        
        if teleportSuccess then
            StarterGui:SetCore("SendNotification", {
                Title = "Téléportation",
                Text = "Téléporté à: " .. zoneName,
                Duration = 3
            })
        end
    end)

    -- Téléportation aux mondes
    for i, world in ipairs(worlds) do
        TeleportSection:NewButton(world.name, "Téléporte au " .. world.name, function()
            local teleportSuccess = safelyTeleportTo(world.basePosition, _G.teleportHeight)
            
            if teleportSuccess then
                StarterGui:SetCore("SendNotification", {
                    Title = "Téléportation",
                    Text = "Téléporté à: " .. world.name,
                    Duration = 3
                })
            end
        end)
    end

    -- Tab Options
    local OptionsTab = Window:NewTab("Options")
    local OptionsSection = OptionsTab:NewSection("Paramètres")
    
    -- Bouton pour stabiliser le personnage
    OptionsSection:NewButton("Stabiliser position", "Ancre temporairement pour stabiliser", function()
        local character = LocalPlayer.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            StarterGui:SetCore("SendNotification", {
                Title = "Stabilisation",
                Text = "Stabilisation en cours...",
                Duration = 2
            })
            
            character.HumanoidRootPart.Anchored = true
            wait(1.5)
            character.HumanoidRootPart.Velocity = Vector3.new(0, 5, 0)
            character.HumanoidRootPart.Anchored = false
            
            StarterGui:SetCore("SendNotification", {
                Title = "Stabilisation",
                Text = "Position stabilisée!",
                Duration = 2
            })
        end
    end)
    
    -- Bouton pour remonter en cas de chute sous le sol
    OptionsSection:NewButton("Remonter (si sous le sol)", "Remonte en cas de chute sous le sol", function()
        local character = LocalPlayer.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            local currentPos = character.HumanoidRootPart.Position
            
            StarterGui:SetCore("SendNotification", {
                Title = "Remontée",
                Text = "Tentative de remontée...",
                Duration = 2
            })
            
            character.HumanoidRootPart.CFrame = CFrame.new(Vector3.new(currentPos.X, currentPos.Y + 50, currentPos.Z))
            character.HumanoidRootPart.Anchored = true
            wait(1)
            character.HumanoidRootPart.Velocity = Vector3.new(0, 10, 0)
            character.HumanoidRootPart.Anchored = false
        end
    end)

    -- Afficher message de bienvenue
    StarterGui:SetCore("SendNotification", {
        Title = "PS99 Mobile Pro",
        Text = "Script chargé avec succès! Version 4.0",
        Duration = 5
    })

    return true
end

-- Fonction pour l'interface de saisie de clé
function createKeyUI()
    local KeyUI = Instance.new("ScreenGui")
    local MainFrame = Instance.new("Frame")
    local Title = Instance.new("TextLabel")
    local KeyInput = Instance.new("TextBox")
    local SubmitButton = Instance.new("TextButton")
    local StatusLabel = Instance.new("TextLabel")
    
    KeyUI.Name = "KeyUI"
    KeyUI.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    KeyUI.ResetOnSpawn = false
    
    MainFrame.Name = "MainFrame"
    MainFrame.Parent = KeyUI
    MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
    MainFrame.BorderSizePixel = 2
    MainFrame.BorderColor3 = Color3.fromRGB(0, 150, 255)
    MainFrame.Position = UDim2.new(0.5, -150, 0.5, -100)
    MainFrame.Size = UDim2.new(0, 300, 0, 200)
    MainFrame.Active = true
    MainFrame.Draggable = true
    
    Title.Name = "Title"
    Title.Parent = MainFrame
    Title.BackgroundColor3 = Color3.fromRGB(20, 20, 40)
    Title.BorderSizePixel = 0
    Title.Size = UDim2.new(1, 0, 0, 30)
    Title.Font = Enum.Font.GothamBold
    Title.Text = "PS99 Mobile Pro - Authentification"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 18.000
    
    KeyInput.Name = "KeyInput"
    KeyInput.Parent = MainFrame
    KeyInput.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    KeyInput.BorderSizePixel = 1
    KeyInput.BorderColor3 = Color3.fromRGB(0, 120, 215)
    KeyInput.Position = UDim2.new(0.1, 0, 0.3, 0)
    KeyInput.Size = UDim2.new(0.8, 0, 0, 40)
    KeyInput.Font = Enum.Font.Gotham
    KeyInput.PlaceholderText = "Entrez votre clé ici..."
    KeyInput.Text = ""
    KeyInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    KeyInput.TextSize = 16.000
    
    SubmitButton.Name = "SubmitButton"
    SubmitButton.Parent = MainFrame
    SubmitButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
    SubmitButton.BorderSizePixel = 0
    SubmitButton.Position = UDim2.new(0.25, 0, 0.6, 0)
    SubmitButton.Size = UDim2.new(0.5, 0, 0, 35)
    SubmitButton.Font = Enum.Font.GothamBold
    SubmitButton.Text = "Valider"
    SubmitButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    SubmitButton.TextSize = 16.000
    
    StatusLabel.Name = "StatusLabel"
    StatusLabel.Parent = MainFrame
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Position = UDim2.new(0, 0, 0.8, 0)
    StatusLabel.Size = UDim2.new(1, 0, 0, 30)
    StatusLabel.Font = Enum.Font.Gotham
    StatusLabel.Text = "Entrez la clé: zekyu"
    StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    StatusLabel.TextSize = 14.000
    
    -- Fonction de vérification de clé
    local function checkKey()
        if KeyInput.Text == correctKey then
            StatusLabel.Text = "Clé valide! Chargement..."
            StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
            wait(1)
            KeyUI:Destroy()
            loadScript()
        else
            StatusLabel.Text = "Clé invalide! Essayez 'zekyu'"
            StatusLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
        end
    end
    
    SubmitButton.MouseButton1Click:Connect(checkKey)
    KeyInput.FocusLost:Connect(function(enterPressed)
        if enterPressed then checkKey() end
    end)
    
    return KeyUI
end

-- Fonction pour créer un tableau de bord avec les informations de debug
function createDebugDashboard()
    local DebugUI = Instance.new("ScreenGui")
    local InfoFrame = Instance.new("Frame")
    local TitleLabel = Instance.new("TextLabel")
    local InfoList = Instance.new("Frame")
    local WorldInfo = Instance.new("TextLabel")
    local ZoneInfo = Instance.new("TextLabel")
    local PositionInfo = Instance.new("TextLabel")
    local StatusInfo = Instance.new("TextLabel")
    local CloseButton = Instance.new("TextButton")
    
    DebugUI.Name = "DebugDashboard"
    DebugUI.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    DebugUI.ResetOnSpawn = false
    
    InfoFrame.Name = "InfoFrame"
    InfoFrame.Parent = DebugUI
    InfoFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
    InfoFrame.BorderSizePixel = 2
    InfoFrame.BorderColor3 = Color3.fromRGB(0, 150, 255)
    InfoFrame.Position = UDim2.new(0, 10, 0.5, -100)
    InfoFrame.Size = UDim2.new(0, 250, 0, 200)
    InfoFrame.Active = true
    InfoFrame.Draggable = true
    
    TitleLabel.Name = "TitleLabel"
    TitleLabel.Parent = InfoFrame
    TitleLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 40)
    TitleLabel.BorderSizePixel = 0
    TitleLabel.Size = UDim2.new(1, 0, 0, 30)
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.Text = "Informations de Debug"
    TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleLabel.TextSize = 16.000
    
    InfoList.Name = "InfoList"
    InfoList.Parent = InfoFrame
    InfoList.BackgroundTransparency = 1
    InfoList.Position = UDim2.new(0, 0, 0, 30)
    InfoList.Size = UDim2.new(1, 0, 1, -30)
    
    WorldInfo.Name = "WorldInfo"
    WorldInfo.Parent = InfoList
    WorldInfo.BackgroundTransparency = 1
    WorldInfo.Position = UDim2.new(0, 10, 0, 10)
    WorldInfo.Size = UDim2.new(1, -20, 0, 25)
    WorldInfo.Font = Enum.Font.Gotham
    WorldInfo.Text = "Monde: ---"
    WorldInfo.TextColor3 = Color3.fromRGB(255, 255, 255)
    WorldInfo.TextSize = 14.000
    WorldInfo.TextXAlignment = Enum.TextXAlignment.Left
    
    ZoneInfo.Name = "ZoneInfo"
    ZoneInfo.Parent = InfoList
    ZoneInfo.BackgroundTransparency = 1
    ZoneInfo.Position = UDim2.new(0, 10, 0, 40)
    ZoneInfo.Size = UDim2.new(1, -20, 0, 25)
    ZoneInfo.Font = Enum.Font.Gotham
    ZoneInfo.Text = "Zone: ---"
    ZoneInfo.TextColor3 = Color3.fromRGB(255, 255, 255)
    ZoneInfo.TextSize = 14.000
    ZoneInfo.TextXAlignment = Enum.TextXAlignment.Left
    
    PositionInfo.Name = "PositionInfo"
    PositionInfo.Parent = InfoList
    PositionInfo.BackgroundTransparency = 1
    PositionInfo.Position = UDim2.new(0, 10, 0, 70)
    PositionInfo.Size = UDim2.new(1, -20, 0, 25)
    PositionInfo.Font = Enum.Font.Gotham
    PositionInfo.Text = "Position: ---"
    PositionInfo.TextColor3 = Color3.fromRGB(255, 255, 255)
    PositionInfo.TextSize = 14.000
    PositionInfo.TextXAlignment = Enum.TextXAlignment.Left
    
    StatusInfo.Name = "StatusInfo"
    StatusInfo.Parent = InfoList
    StatusInfo.BackgroundTransparency = 1
    StatusInfo.Position = UDim2.new(0, 10, 0, 100)
    StatusInfo.Size = UDim2.new(1, -20, 0, 25)
    StatusInfo.Font = Enum.Font.Gotham
    StatusInfo.Text = "Statut: OK"
    StatusInfo.TextColor3 = Color3.fromRGB(0, 255, 0)
    StatusInfo.TextSize = 14.000
    StatusInfo.TextXAlignment = Enum.TextXAlignment.Left
    
    CloseButton.Name = "CloseButton"
    CloseButton.Parent = InfoFrame
    CloseButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    CloseButton.BorderSizePixel = 0
    CloseButton.Position = UDim2.new(1, -25, 0, 5)
    CloseButton.Size = UDim2.new(0, 20, 0, 20)
    CloseButton.Font = Enum.Font.GothamBold
    CloseButton.Text = "X"
    CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseButton.TextSize = 14.000
    
    CloseButton.MouseButton1Click:Connect(function()
        DebugUI:Destroy()
    end)
    
    -- Mettre à jour les informations périodiquement
    spawn(function()
        while DebugUI.Parent ~= nil do
            local player = game:GetService("Players").LocalPlayer
            if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local position = player.Character.HumanoidRootPart.Position
                local currentWorld = ""
                local zone = ""
                
                -- Déterminer le monde actuel
                if position.Z < 0 and position.X > -1000 and position.X < 1000 then
                    currentWorld = "Spawn World"
                elseif position.X < -9000 and position.Z > -1000 then
                    currentWorld = "Tech World"
                elseif position.X < -9000 and position.Z < -7000 then
                    currentWorld = "Void World"
                else
                    currentWorld = "Zone inconnue"
                end
                
                -- Actualiser les informations
                WorldInfo.Text = "Monde: " .. currentWorld
                PositionInfo.Text = "Position: X:" .. math.floor(position.X) .. 
                                  " Y:" .. math.floor(position.Y) .. 
                                  " Z:" .. math.floor(position.Z)
                
                -- Déterminer si sous le sol
                if position.Y < 0 then
                    StatusInfo.Text = "Statut: SOUS LE SOL!"
                    StatusInfo.TextColor3 = Color3.fromRGB(255, 0, 0)
                else
                    StatusInfo.Text = "Statut: OK"
                    StatusInfo.TextColor3 = Color3.fromRGB(0, 255, 0)
                end
            end
            wait(0.5)
        end
    end)
    
    return DebugUI
end

-- Démarrage avec système de clé
if keySystem then
    createKeyUI()
else
    loadScript()
end
