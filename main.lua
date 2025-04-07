-- Script PS99 optimisé pour Delta avec UI amélioré et draggable
-- Version 3.5 condensée à moins de 400 lignes

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

    -- Structure des mondes et leurs limites de zones
    local worlds = {
        {name = "Spawn World", minZone = 1, maxZone = 99, basePosition = Vector3.new(121.71, 16.54, -204.95), offsetX = 5, offsetZ = 3},
        {name = "Tech World", minZone = 100, maxZone = 199, basePosition = Vector3.new(4325, 130, 1850), offsetX = 3, offsetZ = 0},
        {name = "Void World", minZone = 200, maxZone = 239, basePosition = Vector3.new(3678, 130, 1340), offsetX = 0, offsetZ = -3}
    }

    -- Fonction pour déterminer le monde actuel
    local function getCurrentWorld()
        local character = LocalPlayer.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then 
            return worlds[1]
        end
        
        local currentPosition = character.HumanoidRootPart.Position
        
        -- Logique de détection basée sur les coordonnées
        if currentPosition.Z < 0 and currentPosition.X < 1000 then
            return worlds[1] -- Spawn World
        elseif currentPosition.X > 4000 then
            return worlds[2] -- Tech World
        elseif currentPosition.X > 3000 and currentPosition.Z < 1500 then
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
        
        -- Vérifier les zones débloquées
        if playerStats and playerStats:FindFirstChild("UnlockedZones") then
            for i = 1, 239 do
                -- Vérifier si la zone est débloquée
                if playerStats.UnlockedZones:FindFirstChild("Zone"..i) and playerStats.UnlockedZones["Zone"..i].Value then
                    highestZone = i
                else
                    -- Si on trouve une zone non débloquée, on s'arrête
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
        
        -- Si le joueur n'a pas débloqué de zone dans ce monde
        if highestUnlockedZone < currentWorld.minZone then
            -- Si c'est le monde de départ, revenir à la zone 1
            if currentWorld.name == "Spawn World" then
                return "Spawn World Zone 1", currentWorld.basePosition
            else
                -- Sinon, trouver le monde précédent et utiliser sa dernière zone
                for i, world in ipairs(worlds) do
                    if world.name == currentWorld.name and i > 1 then
                        local prevWorld = worlds[i-1]
                        local zoneInWorld = math.min(highestUnlockedZone, prevWorld.maxZone)
                        
                        local offset = zoneInWorld - prevWorld.minZone + 1
                        local zonePosition = Vector3.new(
                            prevWorld.basePosition.X + (offset * prevWorld.offsetX),
                            prevWorld.basePosition.Y,
                            prevWorld.basePosition.Z + (offset * prevWorld.offsetZ)
                        )
                        
                        return prevWorld.name .. " Zone " .. zoneInWorld, zonePosition
                    end
                end
                
                -- Fallback vers la zone 1 du monde de départ
                return "Spawn World Zone 1", worlds[1].basePosition
            end
        end
        
        -- Sinon utiliser la zone la plus haute débloquée dans ce monde
        local zoneInWorld = math.min(highestUnlockedZone, currentWorld.maxZone)
        if zoneInWorld < currentWorld.minZone then
            zoneInWorld = currentWorld.minZone
        end
        
        local offset = zoneInWorld - currentWorld.minZone + 1
        
        local zonePosition = Vector3.new(
            currentWorld.basePosition.X + (offset * currentWorld.offsetX),
            currentWorld.basePosition.Y,
            currentWorld.basePosition.Z + (offset * currentWorld.offsetZ)
        )
        
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

    -- Fonction de téléportation sécurisée
    local function safelyTeleportTo(position, teleportHeight)
        local character = LocalPlayer.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then return false end
        
        -- Ajoutons un petit offset aléatoire pour éviter les obstacles
        local randomOffset = Vector3.new(math.random(-5, 5), 0, math.random(-5, 5))
        local safePosition = Vector3.new(position.X, position.Y + (teleportHeight or 20), position.Z) + randomOffset
        
        -- Téléportation
        character.HumanoidRootPart.CFrame = CFrame.new(safePosition)
        wait(0.5)
        
        -- Vérifier s'il y a un obstacle
        local rayParams = RaycastParams.new()
        rayParams.FilterType = Enum.RaycastFilterType.Blacklist
        rayParams.FilterDescendantsInstances = {character}
        
        local rayResult = workspace:Raycast(safePosition, Vector3.new(0, -50, 0), rayParams)
        if not rayResult then
            -- Si pas de sol détecté, essayer une autre position
            return safelyTeleportTo(position + Vector3.new(math.random(-10, 10), 0, math.random(-10, 10)), teleportHeight)
        end
        
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
                                    hrp.CFrame = CFrame.new(breakablePart.Position + Vector3.new(0, 3, 0))
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
                    
                    local zoneName, zonePosition = getBestUnlockedZoneInCurrentWorld()
                    safelyTeleportTo(zonePosition, 20)
                    
                    StarterGui:SetCore("SendNotification", {
                        Title = "Auto Farm",
                        Text = "Farming dans " .. zoneName,
                        Duration = 3
                    })
                    
                    local farmTime = 0
                    while _G.autoFarm and farmTime < 30 do
                        local nearest = findNearestBreakable()
                        
                        if nearest then
                            local character = LocalPlayer.Character
                            if character and character:FindFirstChild("HumanoidRootPart") then
                                local breakablePart = nearest:FindFirstChild("PrimaryPart") or nearest:FindFirstChildWhichIsA("Part")
                                
                                if breakablePart then
                                    -- Téléportation avec un petit offset aléatoire pour éviter les obstacles
                                    local randomOffset = Vector3.new(math.random(-2, 2), 0, math.random(-2, 2))
                                    character.HumanoidRootPart.CFrame = breakablePart.CFrame * CFrame.new(randomOffset.X, 3, randomOffset.Z)
                                    
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
                            local character = LocalPlayer.Character
                            if character and character:FindFirstChild("HumanoidRootPart") then
                                -- Explorer la zone avec un rayon plus grand pour trouver des breakables
                                local exploreOffset = Vector3.new(math.random(-20, 20), 0, math.random(-20, 20))
                                character.HumanoidRootPart.CFrame = CFrame.new(zonePosition + exploreOffset)
                            end
                            wait(0.3)
                        end
                        
                        farmTime = farmTime + 1
                        wait(0.1)
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

    -- Tab Téléportation
    local TeleportTab = Window:NewTab("Téléportation")
    local TeleportSection = TeleportTab:NewSection("Zones")

    -- Téléportation à la meilleure zone
    TeleportSection:NewButton("Meilleure zone", "Téléporte à la meilleure zone débloquée", function()
        local zoneName, zonePosition = getBestUnlockedZoneInCurrentWorld()
        safelyTeleportTo(zonePosition, 15)
        
        StarterGui:SetCore("SendNotification", {
            Title = "Téléportation",
            Text = "Téléporté à: " .. zoneName,
            Duration = 3
        })
    end)

    -- Téléportation aux mondes
    for i, world in ipairs(worlds) do
        TeleportSection:NewButton(world.name, "Téléporte au " .. world.name, function()
            safelyTeleportTo(world.basePosition, 15)
            
            StarterGui:SetCore("SendNotification", {
                Title = "Téléportation",
                Text = "Téléporté à: " .. world.name,
                Duration = 3
            })
        end)
    end

    -- Afficher message de bienvenue
    StarterGui:SetCore("SendNotification", {
        Title = "PS99 Mobile Pro",
        Text = "Script chargé avec succès! Version 3.5",
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
    KeyInput.Size = UDim2.new(0.8, 0, 0, 4
