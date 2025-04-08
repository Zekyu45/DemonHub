-- PS99 Mobile Pro - Version complète avec système de clé adapté aux mobiles

-- Variables principales
local correctKey = "zekyu"
local autoTpEventActive = false
local showNotifications = true
local hasBeenTeleported = false

-- Services
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- Position du portail pour aller à l'événement
local portalPosition = Vector3.new(174.04, 16.96, -141.07)

-- Chargement des bibliothèques adaptées aux mobiles
local Material = loadstring(game:HttpGet("https://raw.githubusercontent.com/Kinlei/MaterialLua/master/Module.lua"))()

-- Fonction notification optimisée pour mobile
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

-- Création de l'interface principale (après validation de la clé)
local function createMainUI()
    -- Interface principale adaptée aux mobiles
    local UI = Material.Load({
        Title = "PS99 Mobile Pro",
        Style = 3, -- Style arrondi adapté aux mobiles
        SizeX = 320,
        SizeY = 400,
        Theme = "Dark",
        ColorOverrides = {
            MainFrame = Color3.fromRGB(35, 35, 35),
            TitleBar = Color3.fromRGB(30, 30, 30),
            AccentColor = Color3.fromRGB(70, 130, 255)
        }
    })
    
    -- Setup Anti-AFK
    local toggleAfk = setupAntiAfk()
    
    -- Onglet Fonctionnalités
    local MainTab = UI.New({
        Title = "Fonctionnalités"
    })
    
    -- Toggle Anti-AFK
    MainTab.Toggle({
        Text = "Anti-AFK",
        Enabled = false,
        Callback = function(Value)
            toggleAfk(Value)
        end
    })
    
    -- Onglet Événements
    local EventTab = UI.New({
        Title = "Événements"
    })
    
    -- TP Event toggle
    EventTab.Toggle({
        Text = "TP to Event",
        Enabled = false,
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
    local SettingsTab = UI.New({
        Title = "Options"
    })
    
    -- Toggle pour les notifications
    SettingsTab.Toggle({
        Text = "Notifications",
        Enabled = true,
        Callback = function(Value)
            showNotifications = Value
            if Value then
                notify("Notifications", "Notifications activées", 2)
            end
        end
    })
    
    -- Button pour fermer l'interface
    SettingsTab.Button({
        Text = "Fermer l'interface",
        Callback = function()
            UI:Destroy()
        end
    })
    
    -- Information
    SettingsTab.Label({
        Text = "PS99 Mobile Pro v1.0"
    })
    
    SettingsTab.Label({
        Text = "Développé par zekyu"
    })
    
    notify("PS99 Mobile Pro", "Interface chargée avec succès!", 3)
end

-- Interface d'authentification par clé mobile-friendly
local function createKeyUI()
    -- Interface d'authentification adaptée aux mobiles
    local KeyUI = Material.Load({
        Title = "PS99 Mobile Pro - Authentification",
        Style = 3, -- Style arrondi pour mobile
        SizeX = 300, -- Taille réduite pour écran mobile
        SizeY = 180,
        Theme = "Dark",
        ColorOverrides = {
            MainFrame = Color3.fromRGB(35, 35, 35),
            TitleBar = Color3.fromRGB(30, 30, 30),
            AccentColor = Color3.fromRGB(255, 70, 70)
        }
    })
    
    -- Onglet Authentification
    local KeyTab = KeyUI.New({
        Title = "Système de clé"
    })
    
    -- Texte explicatif
    KeyTab.Label({
        Text = "Entrez votre clé d'activation:"
    })
    
    -- Champ de saisie de la clé (optimisé pour mobile)
    local keyInput
    keyInput = KeyTab.TextField({
        Text = "Clé d'activation",
        Callback = function(Value)
            keyInput.Value = Value
        end,
        Menu = false
    })
    
    -- Bouton de validation (plus grand pour mobile)
    KeyTab.Button({
        Text = "VALIDER LA CLÉ",
        Callback = function()
            if keyInput.Value == correctKey then
                -- Animation et notification de succès
                notify("Succès!", "Authentification réussie!", 2)
                
                -- Fermer l'interface de clé et ouvrir l'interface principale
                KeyUI:Destroy()
                wait(1)
                
                -- Lancer l'interface principale
                local success, errorMsg = pcall(createMainUI)
                if not success then
                    wait(1)
                    notify("Erreur", "Impossible de charger le script: " .. tostring(errorMsg), 5)
                    wait(1)
                    createKeyUI() -- Recréer l'interface de clé en cas d'erreur
                end
            else
                -- Animation et notification d'échec
                notify("Erreur", "Clé invalide! Veuillez réessayer.", 2)
                
                -- Effet visuel pour indiquer l'erreur
                local originalPosition = KeyUI.GUI.MainFrame.Position
                for i = 1, 3 do
                    KeyUI.GUI.MainFrame.Position = originalPosition + UDim2.new(0.01, 0, 0, 0)
                    wait(0.05)
                    KeyUI.GUI.MainFrame.Position = originalPosition - UDim2.new(0.01, 0, 0, 0)
                    wait(0.05)
                end
                KeyUI.GUI.MainFrame.Position = originalPosition
            end
        end,
        Primary = true -- Bouton principal, plus visible
    })
    
    return KeyUI
end

-- Démarrage de l'application
pcall(function()
    -- Message de démarrage
    notify("PS99 Mobile Pro", "Chargement du système d'authentification...", 3)
    
    -- Attendre un peu pour que le jeu se charge correctement
    wait(1)
    
    -- Lancer l'interface de clé
    createKeyUI()
end)
