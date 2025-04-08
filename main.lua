-- Script PS99 simplifié avec UI amélioré et draggable
-- Version simplifiée avec AFK, TP Spawn World + Event et Auto TP Event
-- Version corrigée pour éviter les chutes dans le vide

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

    -- Position du Spawn World
    local spawnWorldPosition = Vector3.new(121.71, 25.54, -204.95)
    -- Position du portail pour aller à l'événement
    local portalPosition = Vector3.new(174.04, 16.96, -141.07)
    -- Position réelle de l'événement après le chargement
    local eventPosition = Vector3.new(-24529.11, 407.52, -1514.52)

    -- Vérification si une partie du jeu est chargée
    local function isAreaLoaded(position, radius)
        radius = radius or 10
        local parts = workspace:GetPartBoundsInRadius(position, radius)
        return #parts > 5  -- Si au moins 5 parties sont chargées
    end
    
    -- Fonction pour attendre le chargement d'une zone
    local function waitForAreaLoad(position, timeout)
        timeout = timeout or 10  -- Timeout par défaut de 10 secondes
        local startTime = tick()
        
        -- Attendre jusqu'à ce que la zone soit chargée ou que le délai soit dépassé
        while not isAreaLoaded(position, 20) do
            if tick() - startTime > timeout then
                return false  -- Échec du chargement dans le délai
            end
            wait(0.5)
        end
        
        return true  -- Zone chargée avec succès
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
        -- 1. Téléporter en hauteur pour éviter de tomber sous le sol
        character.HumanoidRootPart.CFrame = CFrame.new(safePosition)
        
        -- 2. Attendre que la zone se charge
        StarterGui:SetCore("SendNotification", {
            Title = "Téléportation",
            Text = "Attente du chargement...",
            Duration = 3
        })
        
        -- Attendre que la zone soit chargée (max 8 secondes)
        local loaded = waitForAreaLoad(position, 8)
        
        if loaded then
            -- 3. Finaliser la téléportation à la position exacte
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
            
            -- Tenter de stabiliser le personnage même si le chargement n'est pas complet
            character.HumanoidRootPart.CFrame = CFrame.new(position)
            character.HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
            
            -- Utiliser une méthode de secours - appliquer une force vers le haut
            local bodyVelocity = Instance.new("BodyVelocity")
            bodyVelocity.Velocity = Vector3.new(0, 10, 0)  -- Force vers le haut
            bodyVelocity.MaxForce = Vector3.new(0, 4000, 0)
            bodyVelocity.Parent = character.HumanoidRootPart
            
            -- Supprimer après 1 seconde
            game:GetService("Debris"):AddItem(bodyVelocity, 1)
            
            return true
        end
    end

    -- Fonction pour vérifier si le joueur est à une position spécifique
    local function isAtPosition(position, tolerance)
        local character = LocalPlayer.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then return false end
        
        tolerance = tolerance or 100 -- Tolérance par défaut de 100 studs
        local distance = (character.HumanoidRootPart.Position - position).Magnitude
        return distance <= tolerance
    end

    -- Auto Téléport au Spawn World - Version corrigée
    MainSection:NewToggle("Auto TP Spawn World", "Téléporte automatiquement au Spawn World", function(state)
        getgenv().autoTpSpawn = state
        if state then
            spawn(function()
                while getgenv().autoTpSpawn do
                    -- Essayer de téléporter
                    teleportTo(spawnWorldPosition)
                    
                    -- Vérifier si la téléportation a réussi
                    if not isAtPosition(spawnWorldPosition, 20) then
                        StarterGui:SetCore("SendNotification", {
                            Title = "Auto TP",
                            Text = "Échec de téléportation, nouvelle tentative...",
                            Duration = 2
                        })
                    end
                    
                    -- Pause plus longue pour permettre un chargement complet
                    wait(10)  -- Attendre 10 secondes entre chaque téléportation
                end
            end)
        end
    end)

    -- Fonction de détection de chute dans le vide
    local function setupVoidDetection()
        spawn(function()
            while true do
                wait(1)
                local character = LocalPlayer.Character
                if character and character:FindFirstChild("HumanoidRootPart") then
                    local position = character.HumanoidRootPart.Position
                    
                    -- Si le joueur tombe sous le niveau du sol
                    if position.Y < -50 then
                        StarterGui:SetCore("SendNotification", {
                            Title = "Protection anti-vide",
                            Text = "Détection de chute, téléportation au spawn...",
                            Duration = 3
                        })
                        
                        -- Téléporter au spawn avec une hauteur plus importante
                        local safePosition = Vector3.new(spawnWorldPosition.X, spawnWorldPosition.Y + 10, spawnWorldPosition.Z)
                        character.HumanoidRootPart.CFrame = CFrame.new(safePosition)
                        
                        -- Attendre un peu et stabiliser
                        wait(1)
                        character.HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
                    end
                end
            end
        end)
    end
    
    -- Activer la détection de chute dans le vide
    setupVoidDetection()

    -- Tab Téléportation
    local TeleportTab = Window:NewTab("Téléportation")
    local TeleportSection = TeleportTab:NewSection("Zones")

    -- Téléportation au Spawn World
    TeleportSection:NewButton("Spawn World", "Téléporte au Spawn World", function()
        local teleportSuccess = teleportTo(spawnWorldPosition)
        
        if teleportSuccess then
            StarterGui:SetCore("SendNotification", {
                Title = "Téléportation",
                Text = "Téléporté au Spawn World",
                Duration = 3
            })
        end
    end)
    
    -- Tab Événements
    local EventTab = Window:NewTab("Événements")
    local EventSection = EventTab:NewSection("Événements actuels")
    
    -- Auto Téléport à l'événement (version toggle uniquement)
    EventSection:NewToggle("Auto TP Event", "Téléporte une fois au portail de l'événement", function(state)
        if state then
            -- Vérifier si le joueur est déjà à l'une des positions
            local character = LocalPlayer.Character
            if not character or not character:FindFirstChild("HumanoidRootPart") then 
                StarterGui:SetCore("SendNotification", {
                    Title = "Auto TP Event",
                    Text = "Personnage non trouvé",
                    Duration = 3
                })
                return 
            end
            
            local currentPosition = character.HumanoidRootPart.Position
            
            -- Vérifier si nous sommes déjà à l'événement
            if isAtPosition(eventPosition, 50) then
                StarterGui:SetCore("SendNotification", {
                    Title = "Auto TP Event",
                    Text = "Vous êtes déjà à l'événement",
                    Duration = 3
                })
                return
            end
            
            -- Vérifier si nous sommes déjà au portail
            if isAtPosition(portalPosition, 10) then
                StarterGui:SetCore("SendNotification", {
                    Title = "Auto TP Event",
                    Text = "Vous êtes déjà au portail de l'événement",
                    Duration = 3
                })
                return
            end
            
            -- Nous ne sommes pas encore au portail, donc téléporter une seule fois
            teleportTo(portalPosition)
            StarterGui:SetCore("SendNotification", {
                Title = "Auto TP Event",
                Text = "Téléporté au portail de l'événement",
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
        Text = "Script simplifié chargé avec succès!",
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
    KeyUI.DisplayOrder = 999 -- S'assurer que l'interface est au premier plan
        
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
    KeyInput.ClearTextOnFocus = false -- Garde le texte lors du focus pour mobile
    
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
    
    -- Ajouter un indicateur visuel que l'interface est chargée
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
