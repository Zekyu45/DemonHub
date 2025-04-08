-- Script PS99 simplifié avec UI amélioré et draggable
-- Version modifiée avec AFK, TP Event et Auto TP Breakables

-- Système de clé d'authentification
local keySystem = true
local correctKey = "zekyu"

-- Fonction principale pour charger le script
function loadScript()
    -- Chargement de la bibliothèque UI avec méthode fiable pour mobile
    local Library
    
    -- Utiliser un pcall pour éviter les erreurs et utiliser une source alternative si nécessaire
    local success, result = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
    end)
    
    if success then
        Library = result
    else
        -- Message d'erreur et nouvelle tentative avec une URL de secours
        warn("Erreur lors du chargement de la bibliothèque UI. Tentative avec source alternative...")
        
        -- Utiliser une source alternative connue pour fonctionner sur mobile
        success, result = pcall(function()
            return loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/obfuscated/source.lua"))()
        end)
        
        if success then
            Library = result
        else
            warn("Échec du chargement de l'interface. Nouvelle tentative dans 3 secondes...")
            wait(3)
            return loadScript()
        end
    end
    
    -- Vérifier si la bibliothèque est chargée correctement
    if not Library or type(Library) ~= "table" or not Library.CreateLib then
        warn("Bibliothèque UI mal chargée. Nouvelle tentative...")
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
    
    -- Afficher un message de débogage
    StarterGui:SetCore("SendNotification", {
        Title = "Débogage",
        Text = "Chargement de l'interface en cours...",
        Duration = 3
    })
    
    -- Créer l'interface avec un thème compatible mobile
    local Window = Library.CreateLib("PS99 Mobile Pro", "Ocean")
    
    -- Afficher un message de confirmation après la création de l'interface
    StarterGui:SetCore("SendNotification", {
        Title = "UI Status",
        Text = "Interface créée avec succès!",
        Duration = 3
    })
    
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
    local MainSection = MainTab:NewSection("Fonctionnalités")

    -- Position du portail pour aller à l'événement
    local portalPosition = Vector3.new(174.04, 16.96, -141.07)
    
    -- Variables de contrôle pour les toggles
    local autoTpEventActive = false
    local autoTpBreakablesActive = false

    -- Vérification si une partie du jeu est chargée
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

    -- Fonction de téléportation améliorée
    local function teleportTo(position)
        local character = LocalPlayer.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then 
            StarterGui:SetCore("SendNotification", {
                Title = "Erreur",
                Text = "Personnage non trouvé",
                Duration = 3
            })
            return false 
        end
        
        -- Position légèrement plus haute pour éviter de tomber dans le vide
        local safePosition = Vector3.new(position.X, position.Y + 5, position.Z)
        
        -- Téléportation en deux étapes
        character.HumanoidRootPart.CFrame = CFrame.new(safePosition)
        
        StarterGui:SetCore("SendNotification", {
            Title = "Téléportation",
            Text = "Attente du chargement...",
            Duration = 3
        })
        
        -- Attendre que la zone soit chargée (max 8 secondes)
        local loaded = waitForAreaLoad(position, 8)
        if loaded then
            character.HumanoidRootPart.CFrame = CFrame.new(position)
            character.HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
            
            StarterGui:SetCore("SendNotification", {
                Title = "Téléportation",
                Text = "Zone chargée avec succès",
                Duration = 2
            })
            return true
        else
            StarterGui:SetCore("SendNotification", {
                Title = "Avertissement",
                Text = "Chargement incomplet, tentative de stabilisation",
                Duration = 3
            })
            
            character.HumanoidRootPart.CFrame = CFrame.new(position)
            character.HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
            
            -- Utiliser une méthode de secours - appliquer une force vers le haut
            local bodyVelocity = Instance.new("BodyVelocity")
            bodyVelocity.Velocity = Vector3.new(0, 10, 0)
            bodyVelocity.MaxForce = Vector3.new(0, 4000, 0)
            bodyVelocity.Parent = character.HumanoidRootPart
            
            game:GetService("Debris"):AddItem(bodyVelocity, 1)
            
            return true
        end
    end

    -- Fonction pour vérifier si le joueur est à une position spécifique
    local function isAtPosition(position, tolerance)
        local character = LocalPlayer.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then return false end
        
        tolerance = tolerance or 100
        local distance = (character.HumanoidRootPart.Position - position).Magnitude
        return distance <= tolerance
    end

    -- Fonction de détection de chute dans le vide
    local function setupVoidDetection()
        spawn(function()
            while true do
                wait(1)
                local character = LocalPlayer.Character
                if character and character:FindFirstChild("HumanoidRootPart") then
                    local position = character.HumanoidRootPart.Position
                    
                    if position.Y < -50 then
                        StarterGui:SetCore("SendNotification", {
                            Title = "Protection anti-vide",
                            Text = "Détection de chute, téléportation...",
                            Duration = 3
                        })
                        
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
    
    -- Fonction pour trouver les breakables les plus proches
    local function findNearestBreakable()
        local character = LocalPlayer.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then return nil end
        
        local closestBreakable = nil
        local closestDistance = 1000
        
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and 
               (obj.Name:lower():find("break") or 
                obj.Name:lower():find("crystal") or 
                obj.Name:lower():find("coin") or
                obj.Name:lower():find("chest")) then
                
                local distance = (obj.Position - character.HumanoidRootPart.Position).Magnitude
                if distance <= 1000 and distance < closestDistance then
                    closestBreakable = obj
                    closestDistance = distance
                end
            end
        end
        
        return closestBreakable
    end
    
    -- Fonction pour téléporter au centre de la zone d'événement
    local function teleportToCenterOfEvent()
        -- Trouver le centre de la zone d'événement actuelle
        local character = LocalPlayer.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then return end
        
        -- Chercher si des structures d'événement sont visibles autour du joueur
        local eventStructures = {}
        local minX, minY, minZ = math.huge, math.huge, math.huge
        local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge
        
        -- Rechercher des structures qui pourraient être liées à l'événement
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and 
               (obj.Name:lower():find("event") or 
                obj.Name:lower():find("arena") or 
                obj.Name:lower():find("stage")) then
                
                table.insert(eventStructures, obj)
                
                -- Mettre à jour les limites de la zone
                minX = math.min(minX, obj.Position.X)
                minY = math.min(minY, obj.Position.Y)
                maxX = math.max(maxX, obj.Position.X)
                maxY = math.max(maxY, obj.Position.Y)
                minZ = math.min(minZ, obj.Position.Z)
                maxZ = math.max(maxZ, obj.Position.Z)
            end
        end
        
        -- Si des structures ont été trouvées, calculer le centre
        if #eventStructures > 0 then
            local centerX = (minX + maxX) / 2
            local centerY = (minY + maxY) / 2 + 5  -- Ajouter une hauteur pour éviter d'être sous le sol
            local centerZ = (minZ + maxZ) / 2
            
            local centerPosition = Vector3.new(centerX, centerY, centerZ)
            teleportTo(centerPosition)
            return centerPosition
        else
            -- Si aucune structure n'est trouvée, utiliser la position actuelle comme centre
            return character.HumanoidRootPart.Position
        end
    end
    
    -- Fonction pour équiper tous les pets avec infinite speed
    local function equipAllPetsInfiniteSpeed()
        wait(1)
        
        local success, err = pcall(function()
            if ReplicatedStorage:FindFirstChild("RemoteEvents") then
                if ReplicatedStorage.RemoteEvents:FindFirstChild("EquipBest") then
                    ReplicatedStorage.RemoteEvents.EquipBest:FireServer()
                    StarterGui:SetCore("SendNotification", {
                        Title = "Pets",
                        Text = "Équipement des meilleurs pets...",
                        Duration = 2
                    })
                end
                
                wait(1)
                
                if ReplicatedStorage.RemoteEvents:FindFirstChild("SetSpeed") then
                    ReplicatedStorage.RemoteEvents.SetSpeed:FireServer(999999)
                    StarterGui:SetCore("SendNotification", {
                        Title = "Pets",
                        Text = "Vitesse infinie activée pour les pets",
                        Duration = 2
                    })
                end
            end
        end)
        
        if not success then
            StarterGui:SetCore("SendNotification", {
                Title = "Erreur Pets",
                Text = "Impossible d'équiper les pets: " .. tostring(err):sub(1, 50),
                Duration = 3
            })
        end
    end
    
    -- Fonction pour cibler et casser les breakables à proximité
    local function targetBreakables()
        spawn(function()
            local eventCenterPosition = nil
            
            while autoTpBreakablesActive do
                -- S'assurer que nous sommes dans la zone d'événement
                if not eventCenterPosition then
                    eventCenterPosition = teleportToCenterOfEvent()
                end
                
                -- Chercher le breakable le plus proche
                local nearestBreakable = findNearestBreakable()
                
                if nearestBreakable then
                    -- Téléporter au breakable
                    teleportTo(nearestBreakable.Position)
                    
                    -- Tentative d'interaction avec le breakable
                    if ReplicatedStorage:FindFirstChild("RemoteEvents") and
                       ReplicatedStorage.RemoteEvents:FindFirstChild("TargetBreakable") then
                        ReplicatedStorage.RemoteEvents.TargetBreakable:FireServer(nearestBreakable)
                    end
                    
                    wait(0.5)
                else
                    -- Si aucun breakable n'est trouvé, retourner au centre de l'événement
                    if eventCenterPosition then
                        teleportTo(eventCenterPosition)
                    end
                    wait(1)
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
                StarterGui:SetCore("SendNotification", {
                    Title = "Auto TP Event",
                    Text = "Personnage non trouvé",
                    Duration = 3
                })
                return 
            end
            
            -- Téléporter uniquement au portail d'événement
            teleportTo(portalPosition)
            StarterGui:SetCore("SendNotification", {
                Title = "Auto TP Event",
                Text = "Téléporté au portail de l'événement",
                Duration = 3
            })
        end
    end)
    
    -- Auto Téléport aux Breakables
    EventSection:NewToggle("Auto TP Breakables", "Téléporte et casse automatiquement les breakables", function(state)
        autoTpBreakablesActive = state
        if state then
            local character = LocalPlayer.Character
            if not character or not character:FindFirstChild("HumanoidRootPart") then
                StarterGui:SetCore("SendNotification", {
                    Title = "Auto TP Breakables",
                    Text = "Personnage non trouvé",
                    Duration = 3
                })
                return
            }
                
            -- Équiper tous les pets avec infinite speed
            equipAllPetsInfiniteSpeed()
            
            -- Trouver le centre de l'événement et commencer à cibler les breakables
            teleportToCenterOfEvent()
            
            StarterGui:SetCore("SendNotification", {
                Title = "Auto TP Breakables",
                Text = "Recherche et ciblage des breakables activés",
                Duration = 3
            })
            
            -- Démarrer le ciblage automatique des breakables
            targetBreakables()
        else
            StarterGui:SetCore("SendNotification", {
                Title = "Auto TP Breakables",
                Text = "Auto TP Breakables désactivé",
                Duration = 3
            })
        end
    end)

    -- Tab Options
    local OptionsTab = Window:NewTab("Options")
    local OptionsSection = OptionsTab:NewSection("Paramètres")
    
    -- Option pour fermer l'interface
    OptionsSection:NewButton("Fermer l'interface", "Ferme l'interface actuelle", function()
        Library:ToggleUI()
    end)

    -- Afficher message de bienvenue
    StarterGui:SetCore("SendNotification", {
        Title = "PS99 Mobile Pro",
        Text = "Script modifié chargé avec succès!",
        Duration = 5
    })

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
    
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Interface de clé",
        Text = "Interface de clé chargée",
        Duration = 3
    })
    
    -- Fonction de vérification de clé
    local function checkKey()
        if KeyInput.Text == correctKey then
            StatusLabel.Text = "Clé valide! Chargement..."
            StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
            
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "Validation de clé",
                Text = "Clé correcte, chargement du script...",
                Duration = 3
            })
            
            wait(1)
            KeyUI:Destroy()
            loadScript()
        else
            StatusLabel.Text = "Clé invalide!"
            StatusLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
            
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "Erreur",
                Text = "Clé invalide!",
                Duration = 3
            })
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
    
    -- Notification de démarrage
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "PS99 Mobile Pro",
        Text = isMobile and "Mode mobile détecté" or "Mode PC détecté",
        Duration = 3
    })
    
    -- Créer l'interface de clé
    createKeyUI()
else
    loadScript()
end
