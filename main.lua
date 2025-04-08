-- Script PS99 Mobile Pro - UI Fluent

-- Variables principales
local autoTpEventActive = false
local showNotifications = true
local correctKey = "zekyu"
local hasBeenTeleported = false -- Variable pour tracker si le téléport a déjà été effectué

-- Services
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- Position du portail pour aller à l'événement
local portalPosition = Vector3.new(174.04, 16.96, -141.07)

-- Chargement de la bibliothèque Fluent UI
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

-- Création des variables pour les fenêtres Fluent
local Window
local KeyWindow

-- Fonction notification
local function notify(title, text, duration)
    if not showNotifications then return end
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title, 
            Text = text, 
            Duration = duration or 2,
            Icon = "rbxassetid://4483345998",
            Button1 = "OK"
        })
    end)
end

-- Fonction Anti-AFK
local function setupAntiAfk()
    local connection
    local VirtualUser = game:GetService("VirtualUser")
    
    return function(state)
        if state then
            if not connection then
                connection = LocalPlayer.Idled:Connect(function()
                    VirtualUser:CaptureController()
                    VirtualUser:ClickButton2(Vector2.new())
                    notify("Anti-AFK", "Système anti-AFK activé", 2)
                end)
                notify("Anti-AFK", "Système anti-AFK démarré", 2)
            end
        else
            if connection then
                connection:Disconnect()
                connection = nil
                notify("Anti-AFK", "Système anti-AFK désactivé", 2)
            end
        end
    end
end

-- Fonction de téléportation - Modifiée pour ne téléporter qu'une seule fois
local function teleportTo(position)
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then 
        notify("Erreur", "Impossible de téléporter - personnage non trouvé", 2)
        return false 
    end
    
    local safePosition = Vector3.new(position.X, position.Y + 5, position.Z)
    local success = pcall(function()
        character:SetPrimaryPartCFrame(CFrame.new(safePosition))
        wait(0.5)
        character:SetPrimaryPartCFrame(CFrame.new(position))
        
        character.HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
        character.HumanoidRootPart.RotVelocity = Vector3.new(0, 0, 0)
    end)
    
    if not success then
        pcall(function()
            character.HumanoidRootPart.CFrame = CFrame.new(position)
        end)
    end
    
    return true
end

-- Création de l'UI avec Fluent
local function createUI()
    -- Si une fenêtre existe déjà, la détruire
    if Window then
        Window:Destroy()
    end
    
    -- Options de la fenêtre principale
    local options = {
        Title = "PS99 Mobile Pro",
        SubTitle = "par zekyu",
        TabWidth = 160,
        Size = UDim2.new(0, 550, 0, 350),
        Acrylic = true,
        Theme = "Dark",
        MinimizeKey = Enum.KeyCode.LeftControl
    }
    
    -- Création de la fenêtre
    Window = Fluent:CreateWindow(options)
    
    -- Setup Anti-AFK
    local toggleAfk = setupAntiAfk()
    
    -- Onglet Fonctionnalités
    local MainTab = Window:CreateTab("Fonctionnalités", "rbxassetid://4483362458")
    local MainSection = MainTab:CreateSection("Fonctions Principales")
    
    -- Toggle Anti-AFK
    MainTab:CreateToggle({
        Title = "Anti-AFK",
        Default = false,
        Callback = function(Value)
            toggleAfk(Value)
        end
    })
    
    -- Onglet Événements
    local EventTab = Window:CreateTab("Événements", "rbxassetid://4483364237")
    local EventSection = EventTab:CreateSection("Fonctions d'Événements")
    
    -- TP Event toggle - MODIFIÉ POUR NE TÉLÉPORTER QU'UNE FOIS
    EventTab:CreateToggle({
        Title = "TP to Event",
        Default = false,
        Callback = function(Value)
            autoTpEventActive = Value
            
            if Value and not hasBeenTeleported then
                local character = LocalPlayer.Character
                if character and character:FindFirstChild("HumanoidRootPart") then
                    teleportTo(portalPosition)
                    hasBeenTeleported = true
                    notify("Event", "Téléportation au portail d'événement", 2)
                else
                    notify("Erreur", "Personnage non disponible pour la téléportation", 2)
                end
            elseif Value and hasBeenTeleported then
                notify("Event", "Vous avez déjà été téléporté à l'événement", 2)
            elseif not Value then
                hasBeenTeleported = false
                notify("Event", "TP to Event désactivé - Réinitialisé", 2)
            end
        end
    })
    -- Onglet Options
    local SettingsTab = Window:CreateTab("Options", "rbxassetid://4483345998")
    local SettingsSection = SettingsTab:CreateSection("Paramètres")
    
    -- Toggle pour les notifications
    SettingsTab:CreateToggle({
        Title = "Notifications",
        Default = true,
        Callback = function(Value)
            showNotifications = Value
            if Value then
                notify("Notifications", "Notifications activées", 2)
            end
        end
    })
    
    -- Bouton pour fermer l'interface
    SettingsTab:CreateButton({
        Title = "Fermer l'interface",
        Callback = function()
            Window:Destroy()
        end
    })
    
    -- Créer un paragraphe d'information
    SettingsTab:CreateParagraph({
        Title = "Information",
        Content = "PS99 Mobile Pro v1.0 - Développé par zekyu"
    })
    
    return Window
end

-- Interface de saisie de clé avec Fluent
local function createKeyUI()
    -- Si une fenêtre de clé existe déjà, la détruire
    if KeyWindow then
        KeyWindow:Destroy()
    end
    
    -- Options de la fenêtre de clé
    local keyOptions = {
        Title = "PS99 Mobile Pro - Authentification",
        SubTitle = "Système de clé",
        TabWidth = 160,
        Size = UDim2.new(0, 450, 0, 230),
        Acrylic = true,
        Theme = "Dark"
    }
    
    -- Création de la fenêtre de clé
    KeyWindow = Fluent:CreateWindow(keyOptions)
    
    -- Onglet Authentification
    local AuthTab = KeyWindow:CreateTab("Authentification", "rbxassetid://4483345998")
    
    -- Section pour la clé
    local KeySection = AuthTab:CreateSection("Entrez votre clé")
    
    -- Afficher la clé (pour démo)
    AuthTab:CreateParagraph({
        Title = "Clé de vérification",
        Content = "La clé est: " .. correctKey
    })
    
    -- Input pour la clé
    local keyInput
    keyInput = AuthTab:CreateInput({
        Title = "Clé d'activation",
        Default = correctKey, -- Pré-remplir avec la clé correcte
        Placeholder = "Entrez votre clé ici...",
        Callback = function(Text)
            if Text == correctKey then
                Fluent:Notify({
                    Title = "Authentification réussie",
                    Content = "Chargement de l'interface principale...",
                    Duration = 3
                })
                
                -- Attendre un peu avant de charger l'interface principale
                task.spawn(function()
                    wait(1.5)
                    KeyWindow:Destroy()
                    
                    local success, errorMsg = pcall(createUI)
                    if not success then
                        wait(1)
                        notify("Erreur", "Impossible de charger le script: " .. tostring(errorMsg), 5)
                        createKeyUI() -- Retourner à l'interface de clé en cas d'erreur
                    end
                end)
            else
                Fluent:Notify({
                    Title = "Clé invalide",
                    Content = "Veuillez réessayer avec la bonne clé",
                    Duration = 2
                })
            end
        end
    })
    
    -- Bouton pour vérifier la clé
    AuthTab:CreateButton({
        Title = "Valider la clé",
        Callback = function()
            if keyInput.Value == correctKey then
                Fluent:Notify({
                    Title = "Authentification réussie",
                    Content = "Chargement de l'interface principale...",
                    Duration = 3
                })
                
                -- Attendre un peu avant de charger l'interface principale
                task.spawn(function()
                    wait(1.5)
                    KeyWindow:Destroy()
                    
                    local success, errorMsg = pcall(createUI)
                    if not success then
                        wait(1)
                        notify("Erreur", "Impossible de charger le script: " .. tostring(errorMsg), 5)
                        createKeyUI() -- Retourner à l'interface de clé en cas d'erreur
                    end
                end)
            else
                Fluent:Notify({
                    Title = "Clé invalide",
                    Content = "Veuillez réessayer avec la bonne clé",
                    Duration = 2
                })
            end
        end
    })
    
    return KeyWindow
end

-- Démarrage de l'application
pcall(function()
    -- Essayer de charger Fluent UI et l'interface
    createKeyUI()
    
    -- Message de confirmation
    notify("PS99 Mobile Pro", "Script chargé avec succès!", 3)
end)
    
