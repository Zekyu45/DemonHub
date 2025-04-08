-- Script PS99 simplifié avec UI amélioré et draggable
-- Version simplifiée avec AFK, TP Spawn World + Event et Auto TP Event

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
    -- Position de l'événement
    local eventPosition = Vector3.new(174.04, 16.96, -141.07)

    -- Fonction de téléportation modifiée (téléportation directe)
    local function teleportTo(position)
        local character = LocalPlayer.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then return false end
        
        -- Téléportation directe à la position exacte
        character.HumanoidRootPart.CFrame = CFrame.new(position)
        
        -- Stabilisation
        character.HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
        
        return true
    end

    -- Fonction pour vérifier si le joueur est à une position spécifique
    local function isAtPosition(position, tolerance)
        local character = LocalPlayer.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then return false end
        
        tolerance = tolerance or 100 -- Tolérance par défaut de 100 studs
        local distance = (character.HumanoidRootPart.Position - position).Magnitude
        return distance <= tolerance
    end

    -- Auto Téléport au Spawn World
    MainSection:NewToggle("Auto TP Spawn World", "Téléporte automatiquement au Spawn World", function(state)
        getgenv().autoTpSpawn = state
        if state then
            spawn(function()
                while getgenv().autoTpSpawn do
                    teleportTo(spawnWorldPosition)
                    wait(5)  -- Attendre 5 secondes entre chaque téléportation
                end
            end)
        end
    end)

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
    
    -- Téléportation à l'événement
    EventSection:NewButton("Téléport to Event", "Téléporte à l'événement actuel", function()
        local teleportSuccess = teleportTo(eventPosition)
        
        if teleportSuccess then
            StarterGui:SetCore("SendNotification", {
                Title = "Téléportation",
                Text = "Téléporté à l'événement",
                Duration = 3
            })
        end
    end)
    
    -- Auto Téléport à l'événement (version toggle)
    EventSection:NewToggle("Auto TP Event", "Téléporte automatiquement à l'événement jusqu'à l'atteindre", function(state)
        getgenv().autoTpEvent = state
        if state then
            spawn(function()
                while getgenv().autoTpEvent do
                    -- Vérifier si le joueur est déjà à la position de l'événement
                    if isAtPosition(eventPosition, 5) then
                        StarterGui:SetCore("SendNotification", {
                            Title = "Auto TP Event",
                            Text = "Vous êtes déjà à l'événement",
                            Duration = 3
                        })
                        getgenv().autoTpEvent = false
                        break -- Sortir de la boucle si on est déjà à l'événement
                    else
                        -- Téléporter le joueur à l'événement
                        teleportTo(eventPosition)
                        wait(3) -- Attendre 3 secondes avant de vérifier à nouveau
                    end
                end
            end)
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
