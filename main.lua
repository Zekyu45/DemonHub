-- Script PS99 simplifié avec UI amélioré et draggable
-- Version simplifiée avec AFK, TP Spawn World + Event et Auto TP Event

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
    
    -- Services
    local Players = game:GetService("Players")
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
        
        tolerance = tolerance or 100 -- Tolérance par défaut de 10 studs
        local distance = (character.HumanoidRootPart.Position - position).Magnitude
        return distance <= tolerance
    end

    -- Auto Téléport au Spawn World
    MainSection:NewToggle("Auto TP Spawn World", "Téléporte automatiquement au Spawn World", function(state)
        _G.autoTpSpawn = state
        if state then
            spawn(function()
                while _G.autoTpSpawn do
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
        _G.autoTpEvent = state
        if state then
            spawn(function()
                while _G.autoTpEvent do
                    -- Vérifier si le joueur est déjà à la position de l'événement
                    if isAtPosition(eventPosition, 5) then
                        StarterGui:SetCore("SendNotification", {
                            Title = "Auto TP Event",
                            Text = "Vous êtes déjà à l'événement",
                            Duration = 3
                        })
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
    StatusLabel.Text = "Entrez la clé: ""
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
            StatusLabel.Text = "Clé invalide!"
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
