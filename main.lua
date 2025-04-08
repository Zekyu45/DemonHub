-- Script PS99 simplifié avec UI amélioré et draggable
-- Version optimisée avec AFK, TP Event et Auto TP Breakables - CORRIGÉ

-- Système de clé d'authentification
local keySystem = true
local correctKey = "zekyu"

-- Fonction principale pour charger le script
function loadScript()
    -- Chargement de la bibliothèque UI avec méthode fiable pour mobile
    local Library
    
    -- Utiliser un pcall pour éviter les erreurs et utiliser une source directe et fiable
    local success, result = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua", true))()
    end)
    
    if success then
        Library = result
    else
        -- Nouvelle tentative avec une URL de secours
        success, result = pcall(function()
            return loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/obfuscated/source.lua", true))()
        end)
        
        if success then
            Library = result
        else
            -- Dernière tentative avec une solution de repli locale
            wait(3)
            
            success, result = pcall(function()
                return loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/master/source.lua", true))()
            end)
            
            if success then
                Library = result
            else
                return false
            end
        end
    end
    
    -- Vérifier si la bibliothèque est chargée correctement
    if not Library or type(Library) ~= "table" or not Library.CreateLib then
        wait(2)
        return loadScript()
    end
    
    -- Services
    local Players = game:GetService("Players")
    local StarterGui = game:GetService("StarterGui")
    local LocalPlayer = Players.LocalPlayer
    local UserInputService = game:GetService("UserInputService")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local RunService = game:GetService("RunService")
    
    -- Désactiver les notifications excessives
    local showNotifications = false
    
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
    
    -- Créer l'interface avec un thème compatible mobile
    local Window = Library.CreateLib("PS99 Mobile Pro", "Ocean")
    
    -- Fonction Anti-AFK
    local function antiAfk()
        local VirtualUser = game:GetService("VirtualUser")
        LocalPlayer.Idled:Connect(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end
    antiAfk()

    -- Tab principal
    local MainTab = Window:NewTab("Principal")
    local MainSection = MainTab:NewSection("Fonctionnalités")

    -- Position du portail pour aller à l'événement
    local portalPosition = Vector3.new(174.04, 16.96, -141.07)
    
    -- Variables de contrôle pour les toggles
    local autoTpEventActive = false
    local autoTpBreakablesActive = false
    local inEventArea = false -- Variable pour suivre si le joueur est dans la zone d'événement

    -- Vérification optimisée si une partie du jeu est chargée
    local function isAreaLoaded(position, radius)
        radius = radius or 10
        local parts = workspace:GetPartBoundsInRadius(position, radius)
        return #parts > 5
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
        
        -- Cache pour éviter de rechercher à chaque frame
        local eventKeywords = {"event", "arena", "stage"}
        
        -- Rechercher des structures qui pourraient être liées à l'événement
        for _, obj in pairs(workspace:GetChildren()) do
            if obj:IsA("BasePart") or obj:IsA("Model") then
                local name = obj.Name:lower()
                for _, keyword in ipairs(eventKeywords) do
                    if name:find(keyword) then
                        local distance = (character.HumanoidRootPart.Position - 
                            (obj:IsA("BasePart") and obj.Position or obj:GetPrimaryPartCFrame().Position)).Magnitude
                        if distance < 300 then
                            return true
                        end
                    end
                end
            end
        end
        
        return false
    end

    -- Fonction de détection de chute dans le vide (optimisée)
    local function setupVoidDetection()
        spawn(function()
            while true do
                wait(2) -- Vérification moins fréquente pour réduire la charge
                local character = LocalPlayer.Character
                if character and character:FindFirstChild("HumanoidRootPart") then
                    local position = character.HumanoidRootPart.Position
                    
                    if position.Y < -50 then
                        -- Téléporter au portail d'événement avec une hauteur plus importante
                        local safePosition = Vector3.new(portalPosition.X, portalPosition.Y + 10, portalPosition.Z)
                        character.HumanoidRootPart.CFrame = CFrame.new(safePosition)
                        
                        wait(1)
                        character.HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
                    end
                end
            end
        end)
    end
    
    setupVoidDetection()
-- Tab Téléportation
    local TeleportTab = Window:NewTab("Téléportation")
    local TeleportSection = TeleportTab:NewSection("Zones")

    -- Tab Événements
    local EventTab = Window:NewTab("Événements")
    local EventSection = EventTab:NewSection("Événements actuels")
    
    -- Cache des breakables pour optimisation
    local breakableCache = {}
    local lastCacheUpdate = 0
    local cacheUpdateInterval = 3 -- Rafraîchir le cache toutes les 3 secondes
    
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
                    for _, obj in pairs(area:GetChildren()) do
                        if obj:IsA("BasePart") and 
                           (obj.Name:lower():find("break") or 
                            obj.Name:lower():find("crystal") or 
                            obj.Name:lower():find("coin") or
                            obj.Name:lower():find("chest")) then
                            
                            table.insert(breakableCache, obj)
                        end
                    end
                end
            end
            
            lastCacheUpdate = currentTime
        end
        
        -- Trouver le plus proche dans le cache
        local closestBreakable = nil
        local closestDistance = 2000
        local characterPosition = character.HumanoidRootPart.Position
        
        for _, obj in ipairs(breakableCache) do
            if obj and obj.Parent then -- Vérifier que l'objet existe toujours
                local distance = (obj.Position - characterPosition).Magnitude
                if distance <= 2000 and distance < closestDistance then
                    closestBreakable = obj
                    closestDistance = distance
                end
            end
        end
        
        return closestBreakable
    end
    
    -- Fonction pour trouver le centre de la zone actuelle (optimisée)
    local function findCurrentAreaCenter()
        local character = LocalPlayer.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then 
            return character.HumanoidRootPart.Position
        end
        
        -- Si on est dans l'événement, approximer le centre
        if inEventArea then
            -- Approximation simplifée basée sur la position actuelle
            return character.HumanoidRootPart.Position
        end
        
        -- Si pas d'événement, renvoyer la position actuelle
        return character.HumanoidRootPart.Position
    end
    
    -- Fonction pour équiper tous les pets avec infinite speed
    local function equipAllPetsInfiniteSpeed()
        wait(1)
        
        pcall(function()
            if ReplicatedStorage:FindFirstChild("RemoteEvents") then
                if ReplicatedStorage.RemoteEvents:FindFirstChild("EquipBest") then
                    ReplicatedStorage.RemoteEvents.EquipBest:FireServer()
                end
                
                wait(1)
                
                if ReplicatedStorage.RemoteEvents:FindFirstChild("SetSpeed") then
                    ReplicatedStorage.RemoteEvents.SetSpeed:FireServer(999999)
                end
            end
        end)
    end
    
    -- Réduire la fréquence des téléportations pour plus de stabilité
    local teleportCooldown = 1 -- 1 seconde entre les téléportations
    local lastTeleportTime = 0
    
    -- Fonction pour cibler et casser les breakables (optimisée)
    local function targetBreakables()
        spawn(function()
            local lastBreakableTime = tick()
            local scanForBreakablesDelay = 1  -- Délai plus long pour réduire la charge
            
            while autoTpBreakablesActive do
                -- Vérifier si nous sommes dans la zone d'événement (moins fréquemment)
                if tick() % 10 < 1 then -- Vérifier environ toutes les 10 secondes
                    inEventArea = checkIfInEventArea()
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
                    if ReplicatedStorage:FindFirstChild("RemoteEvents") and
                       ReplicatedStorage.RemoteEvents:FindFirstChild("TargetBreakable") then
                        ReplicatedStorage.RemoteEvents.TargetBreakable:FireServer(nearestBreakable)
                    end
                    
                    -- Mettre à jour le temps du dernier breakable
                    lastBreakableTime = tick()
                    wait(0.5)
                else
                    -- Si aucun breakable n'est trouvé pendant 10 secondes, chercher dans une autre zone
                    if tick() - lastBreakableTime > 10 then
                        -- Tenter d'aller dans la zone d'événement si pas déjà dedans
                        if not inEventArea then
                            -- Téléporter au portail pour accéder à l'événement
                            if tick() - lastTeleportTime >= teleportCooldown then
                                teleportTo(portalPosition)
                                lastTeleportTime = tick()
                                wait(2) -- Attendre que le portail fonctionne
                            end
                        end
                        
                        lastBreakableTime = tick()
                    end
                    
                    wait(scanForBreakablesDelay)
                end
            end
        end)
    end
    
    -- Auto Téléport à l'événement
    EventSection:NewToggle("Auto TP Event", "Téléporte automatiquement au portail de l'événement", function(state)
        autoTpEventActive = state
        
        if state then
            local character = LocalPlayer.Character
            if not character or not character:FindFirstChild("HumanoidRootPart") then 
                return 
            end
            
            -- Vérifier si déjà dans la zone d'événement
            inEventArea = checkIfInEventArea()
            
            if not inEventArea then
                -- Téléporter uniquement au portail d'événement
                teleportTo(portalPosition)
            end
        end
    end)
    
    -- Auto Téléport aux Breakables
    EventSection:NewToggle("Auto TP Breakables", "Téléporte et casse automatiquement les breakables", function(state)
        autoTpBreakablesActive = state
        
        if state then
            local character = LocalPlayer.Character
            if not character or not character:FindFirstChild("HumanoidRootPart") then
                return
            end
                
            -- Équiper tous les pets avec infinite speed
            equipAllPetsInfiniteSpeed()
            
            -- Vérifier si nous sommes dans la zone d'événement
            inEventArea = checkIfInEventArea()
            
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

    return true
end

-- Fonction pour l'interface de saisie de clé
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

    local KeyInput = Instance.new("TextBox")
    KeyInput.Name = "KeyInput"
    KeyInput.Parent = MainFrame
    KeyInput.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    KeyInput.BorderSizePixel = 1
    KeyInput.Position = UDim2.new(0.1, 0, 0.3, 0)
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
    StatusLabel.Text = "Entrez la clé:"
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
            StatusLabel.Text = "Clé invalide!"
            StatusLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
        end
    end
    
    -- Connexion des événements
    SubmitButton.MouseButton1Click:Connect(checkKey)
    KeyInput.FocusLost:Connect(function(enterPressed)
        if enterPressed then checkKey() end
    end)
    
    return KeyUI
end

-- Démarrage avec système de clé
if keySystem then
    -- Vérifier si le joueur est sur mobile
    local isMobile = game:GetService("UserInputService").TouchEnabled and 
                    not game:GetService("UserInputService").KeyboardEnabled
    
    -- Créer l'interface de clé
    createKeyUI()
else
    loadScript()
end
