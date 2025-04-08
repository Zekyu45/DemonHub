-- Script PS99 Mobile Pro - UI Rayfield

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

-- Configuration de Rayfield (si pas encore chargé)
if not _G.Rayfield then
    _G.Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Rayfield/main/source'))()
end

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

-- Création de l'UI avec Rayfield
local function createUI()
    -- Suppression de l'ancienne interface Rayfield si elle existe
    if _G.Window then
        _G.Window:Destroy()
    end
    
    -- Création de la fenêtre principale
    _G.Window = _G.Rayfield:CreateWindow({
        Name = "PS99 Mobile Pro",
        LoadingTitle = "PS99 Mobile Pro",
        LoadingSubtitle = "par zekyu",
        ConfigurationSaving = {
            Enabled = true,
            FolderName = "PS99MobilePro",
            FileName = "ConfigPS99"
        },
        KeySystem = false, -- Nous gérons notre propre système de clé
        KeySettings = {
            Title = "PS99 Mobile Pro",
            Subtitle = "Système de clé",
            Note = "La clé est: zekyu",
            Key = "zekyu"
        }
    })
    
    -- Création des onglets
    local MainTab = _G.Window:CreateTab("Fonctionnalités", 4483362458) -- ID d'une icône de fonction
    local EventTab = _G.Window:CreateTab("Événements", 4483364237) -- ID d'une icône d'événement
    local SettingsTab = _G.Window:CreateTab("Options", 4483345998) -- ID d'une icône de paramètres
    
    -- Setup Anti-AFK
    local toggleAfk = setupAntiAfk()
    
    -- Section Fonctionnalités Principales
    MainTab:CreateSection("Fonctions Principales")
    
    -- Toggle Anti-AFK
    MainTab:CreateToggle({
        Name = "Anti-AFK",
        CurrentValue = false,
        Flag = "ToggleAntiAFK",
        Callback = function(Value)
            toggleAfk(Value)
        end
    })
    
    -- Section Événements
    EventTab:CreateSection("Fonctions d'Événements")
    
    -- TP Event toggle - MODIFIÉ POUR NE TÉLÉPORTER QU'UNE FOIS
    EventTab:CreateToggle({
        Name = "TP to Event",
        CurrentValue = false,
        Flag = "ToggleTPEvent",
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
-- Section Options
    SettingsTab:CreateSection("Paramètres")
    
    -- Toggle pour les notifications
    SettingsTab:CreateToggle({
        Name = "Notifications",
        CurrentValue = true,
        Flag = "ToggleNotifications",
        Callback = function(Value)
            showNotifications = Value
            if Value then
                notify("Notifications", "Notifications activées", 2)
            end
        end
    })
    
    -- Bouton pour fermer l'interface
    SettingsTab:CreateButton({
        Name = "Fermer l'interface",
        Callback = function()
            _G.Window:Destroy()
        end
    })
    
    return _G.Window
end

-- Interface de saisie de clé avec Rayfield
local function createKeyUI()
    -- Suppression des anciennes interfaces Rayfield
    if _G.KeyWindow then
        _G.KeyWindow:Destroy()
    end
    
    -- Création de la fenêtre de clé
    _G.KeyWindow = _G.Rayfield:CreateWindow({
        Name = "PS99 Mobile Pro - Authentification",
        LoadingTitle = "PS99 Mobile Pro",
        LoadingSubtitle = "Vérification de la clé...",
        ConfigurationSaving = {
            Enabled = false,
        },
        KeySystem = true, -- Utilisation du système de clé intégré de Rayfield
        KeySettings = {
            Title = "PS99 Mobile Pro - Authentification",
            Subtitle = "Authentification requise",
            Note = "La clé est: zekyu",
            Key = correctKey,
            Actions = {
                [1] = {
                    Text = "La clé est affichée dans la note ci-dessus",
                    OnPress = function()
                        setclipboard(correctKey)
                        notify("Clé", "Clé copiée dans le presse-papiers!", 2)
                    end,
                }
            }
        }
    })
    
    -- Après authentification réussie, charger l'interface principale
    _G.KeyWindow:Prompt({
        Title = "Authentification réussie",
        SubTitle = "Chargement de l'interface principale...",
        Actions = {
            Accept = {
                Name = "OK",
                Callback = function()
                    _G.KeyWindow:Destroy()
                    local success, errorMsg = pcall(createUI)
                    if not success then
                        wait(1)
                        notify("Erreur", "Impossible de charger le script: " .. tostring(errorMsg), 5)
                        createKeyUI() -- Retourner à l'interface de clé en cas d'erreur
                    end
                end
            }
        }
    })
    
    return _G.KeyWindow
end

-- Démarrage de l'application
-- Charger Rayfield si ce n'est pas déjà fait
if not _G.Rayfield then
    _G.Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Rayfield/main/source'))()
end

-- Lancer l'interface de clé
createKeyUI()

-- Message de confirmation
notify("PS99 Mobile Pro", "Script chargé avec succès!", 3)
