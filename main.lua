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
        {name = "Spawn World", minZone = 1, maxZone = 99, basePosition = Vector3.new(170, 130, 250), offsetX = 5, offsetZ = 3},
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
        
        if currentPosition.X < 3000 then
            return worlds[1]
        elseif currentPosition.X > 4000 then
            return worlds[2]
        elseif currentPosition.X > 3000 and currentPosition.Z < 1500 then
            return worlds[3]
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
        
        if playerStats and playerStats:FindFirstChild("UnlockedZones") then
            for i = 1, 239 do
                if playerStats.UnlockedZones:FindFirstChild("Zone"..i) and playerStats.UnlockedZones["Zone"..i].Value then
                    highestZone = i
                else
                    break
                end
            end
        end
        
        _G.lastHighestZone = highestZone
        _G.lastUpdateTime = tick()
        
        return highestZone
    end

    -- Fonction pour obtenir la position de la meilleure zone débloquée
    local function getBestUnlockedZoneInCurrentWorld()
        local currentWorld = getCurrentWorld()
        local highestUnlockedZone = getHighestUnlockedZone()
        
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
        
        local safePosition = Vector3.new(position.X, position.Y + (teleportHeight or 20), position.Z)
        character.HumanoidRootPart.CFrame = CFrame.new(safePosition)
        wait(0.5)
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
                                    character.HumanoidRootPart.CFrame = breakablePart.CFrame * CFrame.new(0, 3, 0)
                                    
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

-- Démarrage avec système de clé
if keySystem then
    createKeyUI()
else
    loadScript()
end
