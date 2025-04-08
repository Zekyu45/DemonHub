-- Script PS99 Mobile Pro - Mobile Edition
-- Utilise Orion Library pour une meilleure compatibilité mobile

-- Variables principales
local autoTpEventActive = false
local showNotifications = true
local correctKey = "zekyu"
local hasBeenTeleported = false

-- Services
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- Position du portail pour aller à l'événement
local portalPosition = Vector3.new(174.04, 16.96, -141.07)

-- Chargement de la bibliothèque Orion UI (compatible mobile)
local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexware/Orion/main/source')))()

-- Création des variables pour les fenêtres
local MainWindow
local KeyWindow

-- Fonction notification
local function notify(title, text, duration)
    if not showNotifications then return end
    OrionLib:MakeNotification({
        Name = title,
        Content = text,
        Image = "rbxassetid://4483345998",
        Time = duration or 3
    })
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

-- Fonction de téléportation
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

-- Création de l'UI principale
local function createMainUI()
    if MainWindow then
        OrionLib:Destroy()
    end
    
    -- Création de la fenêtre principale
    MainWindow = OrionLib:MakeWindow({
        Name = "PS99 Mobile Pro",
        HidePremium = true,
        SaveConfig = false,
        IntroEnabled = true,
        IntroText = "PS99 Mobile Pro",
        IntroIcon = "rbxassetid://4483345998",
        Icon = "rbxassetid://4483345998",
        ConfigFolder = "PS99MobilePro"
    })
    
    -- Setup Anti-AFK
    local toggleAfk = setupAntiAfk()
    
    -- Onglet Fonctionnalités
    local MainTab = MainWindow:MakeTab({
        Name = "Fonctionnalités",
        Icon = "rbxassetid://4483362458",
        PremiumOnly = false
    })
    
    MainTab:AddSection({
        Name = "Fonctions Principales"
    })
    
    -- Toggle Anti-AFK
    MainTab:AddToggle({
        Name = "Anti-AFK",
        Default = false,
        Callback = function(Value)
            toggleAfk(Value)
        end
    })
    
    -- Onglet Événements
    local EventTab = MainWindow:MakeTab({
        Name = "Événements",
        Icon = "rbxassetid://4483364237",
        PremiumOnly = false
    })
    
    EventTab:AddSection({
        Name = "Fonctions d'Événements"
    })
    
    -- TP Event toggle
    EventTab:AddToggle({
        Name = "TP to Event",
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
    local SettingsTab = MainWindow:MakeTab({
        Name = "Options",
        Icon = "rbxassetid://4483345998",
        PremiumOnly = false
    })
    
    SettingsTab:AddSection({
        Name = "Paramètres"
    })
    
    -- Toggle pour les notifications
    SettingsTab:AddToggle({
        Name = "Notifications",
        Default = true,
        Callback = function(Value)
            showNotifications = Value
            if Value then
                notify("Notifications", "Notifications activées", 2)
            end
        end
    })
    
    -- Bouton pour fermer l'interface
    SettingsTab:AddButton({
        Name = "Fermer l'interface",
        Callback = function()
            OrionLib:Destroy()
        end
    })
    
    -- Paragraphe d'information
    SettingsTab:AddParagraph("Information", "PS99 Mobile Pro v1.0 - Développé par zekyu")
end

-- Interface de saisie de clé
local function createKeyUI()
    OrionLib:MakeWindow({
        Name = "PS99 Mobile Pro - Authentification",
        HidePremium = true,
        SaveConfig = false,
        IntroEnabled = false,
        Icon = "rbxassetid://4483345998",
        ConfigFolder = "PS99MobilePro"
    })
    
    -- Onglet Authentification
    local KeyTab = OrionLib:MakeTab({
        Name = "Clé",
        Icon = "rbxassetid://4483345998",
        PremiumOnly = false
    })
    
    KeyTab:AddSection({
        Name = "Entrez votre clé"
    })
    
    -- Variable pour stocker la clé saisie
    local keyInput = ""
    
    -- Input pour la clé
    KeyTab:AddTextbox({
        Name = "Clé d'activation",
        Default = "",
        TextDisappear = false,
        Callback = function(Value)
            keyInput = Value
        end
    })
    
    -- Bouton pour vérifier la clé
    KeyTab:AddButton({
        Name = "Valider la clé",
        Callback = function()
            if keyInput == correctKey then
                OrionLib:MakeNotification({
                    Name = "Authentification réussie",
                    Content = "Chargement de l'interface principale...",
                    Image = "rbxassetid://4483345998",
                    Time = 3
                })
                
                -- Petit délai avant de charger l'interface principale
                task.spawn(function()
                    wait(1)
                    OrionLib:Destroy()
                    wait(0.5)
                    local success, errorMsg = pcall(createMainUI)
                    if not success then
                        wait(1)
                        notify("Erreur", "Impossible de charger le script: " .. tostring(errorMsg), 5)
                        wait(1)
                        createKeyUI() -- Recréer l'interface de clé en cas d'erreur
                    end
                end)
            else
                OrionLib:MakeNotification({
                    Name = "Clé invalide",
                    Content = "Veuillez réessayer avec la bonne clé",
                    Image = "rbxassetid://4483345998",
                    Time = 2
                })
            end
        end
    })
end

-- Démarrage de l'application
pcall(function()
    -- Message de démarrage
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "PS99 Mobile Pro", 
        Text = "Chargement du système d'authentification...",
        Duration = 3
    })
    
    -- Charger l'interface de clé
    wait(1)
    createKeyUI()
end)
