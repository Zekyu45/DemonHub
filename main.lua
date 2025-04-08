-- Script PS99 simplifié avec UI amélioré et draggable
-- Version optimisée avec AFK, TP Event et Auto TP Breakables - CORRIGÉ 3.0

-- Système de clé d'authentification
local keySystem = true
local correctKey = "zekyu"

-- Fonction principale pour charger le script
function loadScript()
    -- Définir les variables pour éviter les erreurs de portée
    local Library
    local Window
    local autoTpEventActive = false
    local autoTpBreakablesActive = false
    local inEventArea = false
    local showNotifications = false
    local autoTpBreakablesCoroutine
    local autoTpEventCoroutine
    
    -- Services
    local Players = game:GetService("Players")
    local StarterGui = game:GetService("StarterGui")
    local LocalPlayer = Players.LocalPlayer
    local UserInputService = game:GetService("UserInputService")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local RunService = game:GetService("RunService")
    
    -- Position du portail pour aller à l'événement
    local portalPosition = Vector3.new(174.04, 16.96, -141.07)
    
    -- Position approximative du centre de la zone d'événement
    local eventCenterPosition = Vector3.new(-24529.11, 407.52, -1514.52)
    
    -- Variables pour éviter les téléportations en boucle
    local lastPortalTpTime = 0
    local portalTpCooldown = 5 -- 5 secondes entre les téléportations au portail
    local preventInfiniteLoop = false
    
    -- Réduire la fréquence des téléportations pour plus de stabilité
    local teleportCooldown = 1 -- 1 seconde entre les téléportations
    local lastTeleportTime = 0
    
    -- Cache des breakables pour optimisation
    local breakableCache = {}
    local lastCacheUpdate = 0
    local cacheUpdateInterval = 3 -- Rafraîchir le cache toutes les 3 secondes
    
    -- Fonction notification simplifiée
    local function notify(title, text, duration)
        if not showNotifications then return end
        pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = title,
                Text = text,
                Duration = duration or 2
            })
        end)
    end
    
    -- Chargement de la bibliothèque UI avec gestion d'erreur améliorée
    local function loadUILibrary()
        local sources = {
            "https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua",
            "https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/obfuscated/source.lua",
            "https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/master/source.lua"
        }
        
        for _, source in ipairs(sources) do
            local success, result = pcall(function()
                return loadstring(game:HttpGet(source, true))()
            end)
            
            if success and result and type(result) == "table" and result.CreateLib then
                notify("UI", "Interface chargée avec succès", 2)
                return result
            end
            wait(1)
        end
        
        -- Si toutes les tentatives échouent, utiliser une bibliothèque de secours
        notify("UI", "Échec du chargement de l'interface, utilisation de l'alternative", 2)
        
        -- Fonction minimale pour simuler la bibliothèque
        local fallbackLib = {
            CreateLib = function(name, theme)
                local fakeWindow = {
                    NewTab = function(self, name)
                        return {
                            NewSection = function(self, name)
                                return {
                                    NewToggle = function(self, name, info, callback)
                                        StarterGui:SetCore("SendNotification", {
                                            Title = name,
                                            Text = info,
                                            Duration = 3
                                        })
                                        callback(true)
                                    end,
                                    NewButton = function(self, name, info, callback)
                                        StarterGui:SetCore("SendNotification", {
                                            Title = name,
                                            Text = info,
                                            Duration = 3
                                        })
                                        callback()
                                    end
                                }
                            end
                        }
                    end,
                    ToggleUI = function() end
                }
                return fakeWindow
            end
        }
        
        return fallbackLib
    end
    
    -- Fonction Anti-AFK
    local function antiAfk()
        local VirtualUser = game:GetService("VirtualUser")
        LocalPlayer.Idled:Connect(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
            notify("Anti-AFK", "Système anti-AFK activé", 2)
        end)
    end
    
    -- Vérification optimisée si une partie du jeu est chargée
    local function isAreaLoaded(position, radius)
        radius = radius or 10
        
        -- Éviter les erreurs avec une position invalide
        if not position or typeof(position) ~= "Vector3" then
            return false
        end
        
        local pcallSuccess, parts = pcall(function()
            return workspace:GetPartBoundsInRadius(position, radius)
        end)
        
        if pcallSuccess then
            return #parts > 5
        end
        
        return false
    end
    
    -- Fonction pour attendre le chargement d'une zone
    local function waitForAreaLoad(position, timeout)
        timeout = timeout or 10
        local startTime = tick()
        
        while not isAreaLoaded(position, 20) do
            if tick() - startTime > timeout then
                return false
            end
            wait(0.5)
        end
        
        return true
    end
    
    -- Fonction de téléportation améliorée et optimisée
    local function teleportTo(position)
        local character = LocalPlayer.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then 
            return false 
        end
        
        -- Position légèrement plus haute pour éviter de tomber dans le vide
        local safePosition = Vector3.new(position.X, position.Y + 5, position.Z)
        
        -- Vérifier d'abord si le joueur est déjà proche de la destination
        local currentPosition = character.HumanoidRootPart.Position
        local distanceToTarget = (currentPosition - position).Magnitude
        
        -- Si déjà à proximité (moins de 20 unités), ne pas téléporter
        if distanceToTarget < 20 then
            return true
        end
        
        -- Protection contre les erreurs de téléportation
        pcall(function()
            -- Téléportation en deux étapes
            character.HumanoidRootPart.CFrame = CFrame.new(safePosition)
            
            -- Attendre que la zone soit chargée (max 5 secondes pour plus de réactivité)
            local loaded = waitForAreaLoad(position, 5)
            
            character.HumanoidRootPart.CFrame = CFrame.new(position)
            character.HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
            
            if not loaded then
                -- Utiliser une méthode de secours - appliquer une force vers le haut
                local bodyVelocity = Instance.new("BodyVelocity")
                bodyVelocity.Velocity = Vector3.new(0, 10, 0)
                bodyVelocity.MaxForce = Vector3.new(0, 4000, 0)
                bodyVelocity.Parent = character.HumanoidRootPart
                
                game:GetService("Debris"):AddItem(bodyVelocity, 1)
            end
        end)
        
        return true
    end
    
    -- Fonction pour vérifier si le joueur est à une position spécifique (optimisée)
    local function isAtPosition(position, tolerance)
        local character = LocalPlayer.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then return false end
        
        tolerance = tolerance or 100
        local distance = (character.HumanoidRootPart.Position - position).Magnitude
        return distance <= tolerance
    end
    
    -- Fonction optimisée pour vérifier si le joueur est dans la zone d'événement
    local function checkIfInEventArea()
        local character = LocalPlayer.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then return false end
        
        -- Vérifier la proximité avec la position approximative du centre de l'événement
        local distance = (character.HumanoidRootPart.Position - eventCenterPosition).Magnitude
        if distance < 1000 then
            return true
        end
        
        -- Cache pour éviter de rechercher à chaque frame
        local eventKeywords = {"event", "arena", "stage"}
        
        -- Rechercher des structures qui pourraient être liées à l'événement
        for _, obj in pairs(workspace:GetChildren()) do
            if obj:IsA("BasePart") or obj:IsA("Model") then
                local name = obj.Name:lower()
                for _, keyword in ipairs(eventKeywords) do
                    if name:find(keyword) then
                        local objPosition
                        
                        if obj:IsA("BasePart") then
                            objPosition = obj.Position
                        elseif obj:FindFirstChild("PrimaryPart") then
                            objPosition = obj.PrimaryPart.Position
                        elseif obj:FindFirstChildWhichIsA("BasePart") then
                            objPosition = obj:FindFirstChildWhichIsA("BasePart").Position
                        end
                        
                        if objPosition then
                            local distance = (character.HumanoidRootPart.Position - objPosition).Magnitude
                            if distance < 300 then
                                return true
                            end
                        end
                    end
                end
            end
        end
        
        return false
    end

    -- Début du script principal
    Library = loadUILibrary()
    if not Library then
        notify("ERREUR", "Impossible de charger l'interface!", 5)
        return false
    end
    
    -- Création de l'interface
    Window = Library:CreateLib("PS99 Mobile Pro", "Ocean")
    
    -- Activer l'anti-AFK
    antiAfk()
    
    -- Tab principal
    local MainTab = Window:NewTab("Principal")
    local MainSection = MainTab:NewSection("Fonctionnalités")
    -- Fonction de détection de chute dans le vide (optimisée)
    local function setupVoidDetection()
        spawn(function()
            while true do
                wait(2) -- Vérification moins fréquente pour réduire la charge
                local character = LocalPlayer.Character
                if character and character:FindFirstChild("HumanoidRootPart") then
                    local position = character.HumanoidRootPart.Position
                    
                    if position.Y < -50 then
                        -- Si dans zone d'événement, téléporter au centre de l'événement
                        if inEventArea then
                            teleportTo(eventCenterPosition)
                        else
                            -- Sinon téléporter au portail d'événement avec une hauteur plus importante
                            local safePosition = Vector3.new(portalPosition.X, portalPosition.Y + 10, portalPosition.Z)
                            pcall(function()
                                character.HumanoidRootPart.CFrame = CFrame.new(safePosition)
                            end)
                        end
                        
                        wait(1)
                        pcall(function()
                            character.HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
                        end)
                    end
                end
            end
        end)
    end
    
    -- Tab Téléportation
    local TeleportTab = Window:NewTab("Téléportation")
    local TeleportSection = TeleportTab:NewSection("Zones")

    -- Tab Événements
    local EventTab = Window:NewTab("Événements")
    local EventSection = EventTab:NewSection("Événements actuels")
    
    -- Fonction pour trouver les breakables dans toutes les zones (optimisée avec cache)
    local function findNearestBreakable()
        local character = LocalPlayer.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then return nil end
        
        -- Mettre à jour le cache si nécessaire
        local currentTime = tick()
        if currentTime - lastCacheUpdate > cacheUpdateInterval then
            breakableCache = {}
            
            -- Recherche optimisée - utiliser GetChildren au lieu de GetDescendants
            for _, area in pairs(workspace:GetChildren()) do
                -- Vérifier seulement les objets qui pourraient contenir des breakables
                if typeof(area) == "Instance" and (area:IsA("Folder") or area:IsA("Model")) then
                    pcall(function()
                        for _, obj in pairs(area:GetChildren()) do
                            if obj:IsA("BasePart") and 
                               (obj.Name:lower():find("break") or 
                                obj.Name:lower():find("crystal") or 
                                obj.Name:lower():find("coin") or
                                obj.Name:lower():find("chest")) then
                                
                                table.insert(breakableCache, obj)
                            end
                        end
                    end)
                end
            end
            
            lastCacheUpdate = currentTime
        end
        
        -- Trouver le plus proche dans le cache
        local closestBreakable = nil
        local closestDistance = 2000
        local characterPosition = character.HumanoidRootPart.Position
        
        for _, obj in ipairs(breakableCache) do
            pcall(function()
                if obj and obj.Parent then -- Vérifier que l'objet existe toujours
                    local distance = (obj.Position - characterPosition).Magnitude
                    if distance <= 2000 and distance < closestDistance then
                        closestBreakable = obj
                        closestDistance = distance
                    end
                end
            end)
        end
        
        return closestBreakable
    end
    
    -- Fonction pour équiper tous les pets avec infinite speed
    local function equipAllPetsInfiniteSpeed()
        wait(1)
        
        pcall(function()
            if ReplicatedStorage:FindFirstChild("RemoteEvents") then
                if ReplicatedStorage.RemoteEvents:FindFirstChild("EquipBest") then
                    ReplicatedStorage.RemoteEvents.EquipBest:FireServer()
                    notify("Pets", "Meilleurs pets équipés", 2)
                end
                
                wait(1)
                
                if ReplicatedStorage.RemoteEvents:FindFirstChild("SetSpeed") then
                    ReplicatedStorage.RemoteEvents.SetSpeed:FireServer(999999)
                    notify("Pets", "Vitesse maximale activée", 2)
                end
            end
        end)
    end
    
    -- NOUVELLE FONCTION: Téléportation à la zone d'événement
    local function teleportToEventArea()
        local character = LocalPlayer.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then 
            return false
        end
        
        -- Ne pas se téléporter si on est déjà dans la zone d'événement
        if inEventArea then
            return true
        end
        
        -- Éviter les téléportations trop fréquentes au portail
        local currentTime = tick()
        if currentTime - lastPortalTpTime < portalTpCooldown then
            return false
        end
        
        -- Se téléporter au portail d'événement
        notify("Téléportation", "Téléportation au portail d'événement...", 2)
        teleportTo(portalPosition)
        lastPortalTpTime = currentTime
        wait(2) -- Attendre que le portail fonctionne
        
        -- Vérifier si on est maintenant dans la zone d'événement
        inEventArea = checkIfInEventArea()
        
        -- Si toujours pas dans la zone d'événement, tenter une téléportation directe
        if not inEventArea then
            notify("Téléportation", "Tentative de téléportation directe...", 2)
            teleportTo(eventCenterPosition)
            wait(1)
            inEventArea = checkIfInEventArea()
        end
        
        return inEventArea
    end
    
    -- Fonction pour cibler et casser les breakables (optimisée et corrigée)
    local function targetBreakables()
        -- Annuler toute exécution précédente si elle existe
        if autoTpBreakablesCoroutine then
            pcall(function() coroutine.close(autoTpBreakablesCoroutine) end)
            autoTpBreakablesCoroutine = nil
        end
        
        -- Démarrer une nouvelle coroutine
        autoTpBreakablesCoroutine = coroutine.create(function()
            local lastBreakableTime = tick()
            local scanForBreakablesDelay = 1  -- Délai plus long pour réduire la charge
            local failedTeleportAttempts = 0
            
            while autoTpBreakablesActive do
                -- Équiper les meilleurs pets avec une vitesse infinie
                if tick() % 30 < 1 then -- Refresh des pets toutes les 30 secondes environ
                    equipAllPetsInfiniteSpeed()
                end
                
                -- Vérifier si nous sommes dans la zone d'événement
                inEventArea = checkIfInEventArea()
                
                -- Si pas dans la zone d'événement, s'y téléporter d'abord
                if not inEventArea then
                    teleportToEventArea()
                    wait(1)
                    inEventArea = checkIfInEventArea()
                    
                    if not inEventArea then
                        failedTeleportAttempts = failedTeleportAttempts + 1
                        
                        -- Après plusieurs échecs, attendre plus longtemps
                        if failedTeleportAttempts >= 3 then
                            wait(5)
                            failedTeleportAttempts = 0
                        else
                            wait(1)
                        end
                        
                        continue
                    end
                    
                    failedTeleportAttempts = 0
                end
                
                -- Chercher le breakable le plus proche
                local nearestBreakable = findNearestBreakable()
                
                if nearestBreakable then
                    -- Limiter la fréquence des téléportations
                    local currentTime = tick()
                    if currentTime - lastTeleportTime >= teleportCooldown then
                        teleportTo(nearestBreakable.Position)
                        lastTeleportTime = currentTime
                    end
                    
                    -- Tentative d'interaction avec le breakable
                    pcall(function()
                        if ReplicatedStorage:FindFirstChild("RemoteEvents") and
                        ReplicatedStorage.RemoteEvents:FindFirstChild("TargetBreakable") then
                            ReplicatedStorage.RemoteEvents.TargetBreakable:FireServer(nearestBreakable)
                        end
                    end)
                    
                    -- Mettre à jour le temps du dernier breakable
                    lastBreakableTime = tick()
                    wait(0.5)
                else
                    -- Si aucun breakable n'est trouvé pendant 5 secondes
                    if tick() - lastBreakableTime > 5 then
                        -- Réinitialiser le cache pour forcer une nouvelle recherche
                        lastCacheUpdate = 0
                        
                        -- Si dans l'événement mais pas de breakables, déplacer au centre
                        if inEventArea then
                            teleportTo(eventCenterPosition)
                        else
                            -- Sinon, téléporter à l'événement
                            teleportToEventArea()
                        end
                        
                        lastBreakableTime = tick()
                    end
                    
                    wait(scanForBreakablesDelay)
                end
            end
        end)
        
        -- Démarrer la coroutine
        coroutine.resume(autoTpBreakablesCoroutine)
    end
    
    -- Auto Téléport à l'événement CORRIGÉ
    EventSection:NewToggle("Auto TP Event", "Téléporte automatiquement au portail de l'événement", function(state)
        autoTpEventActive = state
        
        -- Annuler toute coroutine précédente
        if autoTpEventCoroutine then
            pcall(function() coroutine.close(autoTpEventCoroutine) end)
            autoTpEventCoroutine = nil
        end
        
        if state then
            -- Créer une nouvelle coroutine pour éviter les boucles infinies
            autoTpEventCoroutine = coroutine.create(function()
                while autoTpEventActive do
                    local character = LocalPlayer.Character
                    if not character or not character:FindFirstChild("HumanoidRootPart") then 
                        wait(1)
                        continue
                    end
                    
                    -- Vérifier si déjà dans la zone d'événement
                    inEventArea = checkIfInEventArea()
                    
                    if not inEventArea then
                        -- Éviter les téléportations trop fréquentes au portail
                        local currentTime = tick()
                        if currentTime - lastPortalTpTime >= portalTpCooldown then
                            teleportTo(portalPosition)
                            lastPortalTpTime = currentTime
                            notify("Event", "Téléportation au portail d'événement", 2)
                            wait(2) -- Attendre que le portail fonctionne
                        end
                    else
                        -- Si déjà dans la zone d'événement, attendre plus longtemps
                        wait(5)
                    end
                    
                    -- Éviter la surcharge de la boucle
                    wait(1)
                end
            end)
            
            -- Démarrer la coroutine
            coroutine.resume(autoTpEventCoroutine)
        end
    end)
    
    -- Auto Téléport aux Breakables CORRIGÉ
    EventSection:NewToggle("Auto TP Breakables", "Téléporte et casse automatiquement les breakables", function(state)
        autoTpBreakablesActive = state
        
        if state then
            -- Activer le TP à l'event automatiquement si nécessaire
            if not autoTpEventActive then
                autoTpEventActive = true
                notify("Event", "Auto TP Event activé automatiquement", 2)
            end
            
            -- Équiper tous les pets avec infinite speed
            equipAllPetsInfiniteSpeed()
            
            -- Vérifier si nous sommes dans la zone d'événement
            inEventArea = checkIfInEventArea()
            
            -- Si pas dans la zone d'événement, s'y téléporter d'abord
            if not inEventArea then
                teleportToEventArea()
            end
            
            -- Démarrer le ciblage automatique des breakables (dans toutes les zones)
            targetBreakables()
        end
    end)

    -- Tab Options
    local OptionsTab = Window:NewTab("Options")
    local OptionsSection = OptionsTab:NewSection("Paramètres")
    
    -- Option pour activer/désactiver les notifications
    OptionsSection:NewToggle("Notifications", "Activer/désactiver les notifications", function(state)
        showNotifications = state
    end)
    
    -- Option pour fermer l'interface
    OptionsSection:NewButton("Fermer l'interface", "Ferme l'interface actuelle", function()
        Library:ToggleUI()
    end)
    
    -- Activer la détection du vide
    setupVoidDetection()
    
    return true
end

-- Fonction pour l'interface de saisie de clé (améliorée pour tous les appareils)
function createKeyUI()
    -- Suppression des anciennes interfaces qui pourraient causer des conflits
    for _, gui in pairs(game:GetService("Players").LocalPlayer.PlayerGui:GetChildren()) do
        if gui.Name == "KeyUI" then
            gui:Destroy()
        end
    end
    
    -- Création d'une nouvelle interface GUI simplifiée pour une meilleure compatibilité mobile
    local KeyUI = Instance.new("ScreenGui")
    KeyUI.Name = "KeyUI"
    KeyUI.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    KeyUI.ResetOnSpawn = false
    KeyUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    KeyUI.DisplayOrder = 999
        
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Parent = KeyUI
    MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
    MainFrame.BorderSizePixel = 2
    MainFrame.BorderColor3 = Color3.fromRGB(0, 150, 255)
    MainFrame.Position = UDim2.new(0.5, -150, 0.5, -100)
    MainFrame.Size = UDim2.new(0, 300, 0, 200)
    MainFrame.Active = true
    MainFrame.Draggable = true
    
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 8)
    UICorner.Parent = MainFrame

    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Parent = MainFrame
    Title.BackgroundColor3 = Color3.fromRGB(20, 20, 40)
    Title.BorderSizePixel = 0
    Title.Size = UDim2.new(1, 0, 0, 30)
    Title.Font = Enum.Font.GothamBold
    Title.Text = "PS99 Mobile Pro - Authentification"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 18
    
    local UICornerTitle = Instance.new("UICorner")
    UICornerTitle.CornerRadius = UDim.new(0, 8)
    UICornerTitle.Parent = Title
    
    -- Solution pour mobile: ajouter un indicateur de clé
    local KeyLabel = Instance.new("TextLabel")
    KeyLabel.Name = "KeyLabel"
    KeyLabel.Parent = MainFrame
    KeyLabel.BackgroundTransparency = 1
    KeyLabel.Position = UDim2.new(0.1, 0, 0.17, 0)
    KeyLabel.Size = UDim2.new(0.8, 0, 0, 30)
    KeyLabel.Font = Enum.Font.GothamBold
    KeyLabel.Text = "La clé est: zekyu"
    KeyLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    KeyLabel.TextSize = 16

    local KeyInput = Instance.new("TextBox")
    KeyInput.Name = "KeyInput"
    KeyInput.Parent = MainFrame
    KeyInput.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    KeyInput.BorderSizePixel = 1
    KeyInput.Position = UDim2.new(0.1, 0, 0.4, 0)
    KeyInput.Size = UDim2.new(0.8, 0, 0, 40)
    KeyInput.Font = Enum.Font.Gotham
    KeyInput.PlaceholderText = "Entrez votre clé ici..."
    KeyInput.Text = ""
    KeyInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    KeyInput.TextSize = 16
    KeyInput.ClearTextOnFocus = false
    
    local UICornerInput = Instance.new("UICorner")
    UICornerInput.CornerRadius = UDim.new(0, 6)
    UICornerInput.Parent = KeyInput

    local SubmitButton = Instance.new("TextButton")
    SubmitButton.Name = "SubmitButton"
    SubmitButton.Parent = MainFrame
    SubmitButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
    SubmitButton.BorderSizePixel = 0
    SubmitButton.Position = UDim2.new(0.25, 0, 0.6, 0)
    SubmitButton.Size = UDim2.new(0.5, 0, 0, 40)
    SubmitButton.Font = Enum.Font.GothamBold
    SubmitButton.Text = "Valider"
    SubmitButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    SubmitButton.TextSize = 18
    
    local UICornerButton = Instance.new("UICorner")
    UICornerButton.CornerRadius = UDim.new(0, 6)
    UICornerButton.Parent = SubmitButton

    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Name = "StatusLabel"
    StatusLabel.Parent = MainFrame
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Position = UDim2.new(0, 0, 0.8, 0)
    StatusLabel.Size = UDim2.new(1, 0, 0, 30)
    StatusLabel.Font = Enum.Font.Gotham
    StatusLabel.Text = "Entrez la clé puis cliquez sur Valider"
    StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    StatusLabel.TextSize = 14
    
    -- Fonction de vérification de clé
    local function checkKey()
        if KeyInput.Text == correctKey then
            StatusLabel.Text = "Clé valide! Chargement..."
            StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
            
            wait(1)
            KeyUI:Destroy()
            loadScript()
        else
            StatusLabel.Text = "Clé invalide! Essayez à nouveau."
            StatusLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
            -- Vibrer légèrement le champ de saisie pour indiquer une erreur
            local originalPosition = KeyInput.Position
            
            for i = 1, 5 do
                KeyInput.Position = UDim2.new(originalPosition.X.Scale + (i % 2 == 0 and 0.01 or -0.01), originalPosition.X.Offset, originalPosition.Y.Scale, originalPosition.Y.Offset)
                wait(0.05)
            end
            
            KeyInput.Position = originalPosition
        end
    end
    
    -- Connexion des événements
    SubmitButton.MouseButton1Click:Connect(checkKey)
    KeyInput.FocusLost:Connect(function(enterPressed)
        if enterPressed then checkKey() end
    end)
    
    -- Pré-remplir le champ avec la clé pour faciliter l'utilisation
    KeyInput.Text = correctKey
    
    -- Rendre le bouton plus visible avec un effet de pulsation
    spawn(function()
        while wait(0.5) do
            if not SubmitButton or not SubmitButton.Parent then break end
            
            for i = 0, 10 do
                if not SubmitButton or not SubmitButton.Parent then break end
                SubmitButton.BackgroundColor3 = Color3.fromRGB(0, 120 + i*5, 215)
                wait(0.05)
            end
            
            for i = 10, 0, -1 do
                if not SubmitButton or not SubmitButton.Parent then break end
                SubmitButton.BackgroundColor3 = Color3.fromRGB(0, 120 + i*5, 215)
                wait(0.05)
            end
        end
    end)
    
    return KeyUI
end

-- Démarrage avec système de clé
if keySystem then
    local isMobile = game:GetService("UserInputService").TouchedEnabled and
                    not game:GetService("UserInputService").KeyboardEnabled
    
    -- Afficher l'interface de saisie de clé
    createKeyUI()
else
    -- Si le système de clé est désactivé, charger directement le script
    loadScript()
end
