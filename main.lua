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
        
        return currentWorld.name .. " Zone " .. zoneInWorld, zonePosition
    end
    -- Section pour la fonction d'auto-farming
    local AutoFarmTab = Window:NewTab("AutoFarm")
    local AutoFarmSection = AutoFarmTab:NewSection("Auto Farm Settings")
    
    -- Toggle pour activer l'auto-farming
    AutoFarmSection:NewToggle("Activer l'Auto-Farming", "Lance l'auto-farming", function(state)
        _G.autoFarm = state
        if state then
            -- Lancer l'auto farming
            while _G.autoFarm do
                local bestZoneName, bestZonePosition = getBestUnlockedZoneInCurrentWorld()
                print("En route vers " .. bestZoneName)
                -- Déplacer le joueur vers la zone
                local character = LocalPlayer.Character
                if character and character:FindFirstChild("HumanoidRootPart") then
                    local rootPart = character.HumanoidRootPart
                    rootPart.CFrame = CFrame.new(bestZonePosition)
                end
                wait(5) -- Attendre avant de redemander la zone la plus haute
            end
        end
    end)

    -- Paramétrage de la collecte automatique
    local CollectTab = Window:NewTab("AutoCollect")
    local CollectSection = CollectTab:NewSection("Collecte automatique")
    
    -- Toggle pour activer la collecte automatique
    CollectSection:NewToggle("Collecte automatique", "Activer ou désactiver la collecte des objets", function(state)
        _G.autoCollect = state
        if state then
            -- Activer la collecte automatique
            while _G.autoCollect do
                -- Simulation de collecte des objets dans le rayon spécifié
                local character = LocalPlayer.Character
                if character and character:FindFirstChild("HumanoidRootPart") then
                    local rootPart = character.HumanoidRootPart
                    -- Rechercher les objets collectables autour du joueur dans un rayon
                    for _, item in pairs(workspace:GetChildren()) do
                        if item:IsA("Part") and item.Name == "CollectableItem" then
                            local dist = (item.Position - rootPart.Position).Magnitude
                            if dist <= _G.farmRadius then
                                -- Simuler l'interaction avec l'objet
                                firetouchinterest(rootPart, item, 0)
                                firetouchinterest(rootPart, item, 1)
                            end
                        end
                    end
                end
                wait(1)
            end
        end
    end)
    
    -- Réglage de la distance de collecte
    CollectSection:NewSlider("Rayon de collecte", "Définir la distance de collecte autour du joueur", 50, 0, _G.farmRadius, function(val)
        _G.farmRadius = val
    end)

    -- Tab des paramètres
    local SettingsTab = Window:NewTab("Paramètres")
    local SettingsSection = SettingsTab:NewSection("Options du script")

    -- Paramètre pour choisir la clé d'authentification
    SettingsSection:NewTextBox("Clé d'authentification", "Entrez votre clé pour activer le script", true, function(val)
        if val == correctKey then
            keySystem = true
            StarterGui:SetCore("SendNotification", {Title = "Succès", Text = "Clé d'authentification correcte !", Duration = 5})
        else
            keySystem = false
            StarterGui:SetCore("SendNotification", {Title = "Erreur", Text = "Clé d'authentification incorrecte.", Duration = 5})
        end
    end)
    
    -- Fonction de déconnexion du script
    SettingsSection:NewButton("Déconnexion", "Déconnecte du script", function()
        LocalPlayer:Kick("Déconnecté du script PS99 Mobile Pro.")
    end)
    
    -- Fonction Anti-AFK déjà incluse
    local function antiAfk()
        local VirtualUser = game:GetService("VirtualUser")
        LocalPlayer.Idled:Connect(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
            StarterGui:SetCore("SendNotification", {Title = "Anti-AFK", Text = "Anti-AFK activé", Duration = 3})
        end)
    end
    antiAfk()

    -- Fonction de mise à jour des paramètres
    local function updateSettings()
        -- Mettre à jour les paramètres dans le script selon les préférences
        -- Ex: récupérer les dernières zones débloquées, positions, etc.
    end

    -- Mise à jour des paramètres régulièrement
    while true do
        updateSettings()
        wait(60)  -- Attendre 60 secondes avant de mettre à jour
    end
end

-- Lancer le script
loadScript()
