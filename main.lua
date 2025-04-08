-- PS99 Mobile Pro - Système d'authentification par clé optimisé pour mobile
-- Version avec Rayfield UI

-- Variables principales
local correctKey = "zekyu"
local autoTpEventActive = false
local showNotifications = true
local hasBeenTeleported = false

-- Services
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- Position du portail pour aller à l'événement
local portalPosition = Vector3.new(174.04, 16.96, -141.07)

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

-- Chargement de Rayfield
local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Rayfield/main/source'))()

-- Système de vérification de clé
local function createKeySystem()
    local Window = Rayfield:CreateWindow({
        Name = "PS99 Mobile Pro - Authentification",
        LoadingTitle = "PS99 Mobile Pro",
        LoadingSubtitle = "par zekyu",
        ConfigurationSaving = {
            Enabled = false,
            FolderName = nil,
            FileName = nil
        },
        Discord = {
            Enabled = false,
            Invite = nil,
            RememberJoins = false
        },
        KeySystem = true,
        KeySettings = {
            Title = "PS99 Mobile Pro - Système de Clé",
            Subtitle = "Entrez votre clé d'activation",
            Note = "La clé vous a été fournie par le développeur",
            FileName = "PS99MobileKey",
            SaveKey = false,
            GrabKeyFromSite = false,
            Key = correctKey
        }
    })
    
    -- Si la clé est correcte, charger l'interface principale
    createMainInterface()
end

-- Interface principale avec Rayfield
local function createMainInterface()
    local Window = Rayfield:CreateWindow({
        Name = "PS99 Mobile Pro",
        LoadingTitle = "PS99 Mobile Pro",
        LoadingSubtitle = "par zekyu",
        ConfigurationSaving = {
            Enabled = true,
            FolderName = "PS99MobilePro",
            FileName = "Config"
        },
        Discord = {
            Enabled = false,
            Invite = nil,
            RememberJoins = false
        },
        KeySystem = false
    })
    
    -- Onglet Principal
    local MainTab = Window:CreateTab("Fonctionnalités", 4483362458)
    
    -- Anti-AFK Toggle
    local antiAfkEnabled = false
    local toggleAfk = setupAntiAfk()
    
    MainTab:CreateToggle({
        Name = "Anti-AFK",
        CurrentValue = antiAfkEnabled,
        Flag = "AntiAFK",
        Callback = function(Value)
            antiAfkEnabled = Value
            toggleAfk(antiAfkEnabled)
            
            if antiAfkEnabled then
                notify("Anti-AFK", "Système anti-AFK activé", 2)
            else
                notify("Anti-AFK", "Système anti-AFK désactivé", 2)
            end
        end,
    })
    
    -- TP to Event Button
    MainTab:CreateButton({
        Name = "TP to Event",
        Callback = function()
            if not hasBeenTeleported then
                local character = LocalPlayer.Character
                if character and character:FindFirstChild("HumanoidRootPart") then
                    teleportTo(portalPosition)
                    hasBeenTeleported = true
                    notify("Event", "Téléportation au portail d'événement", 2)
                else
                    notify("Erreur", "Personnage non disponible pour la téléportation", 2)
                end
            else
                notify("Event", "Vous avez déjà été téléporté à l'événement", 2)
            end
        end,
    })
    
    -- Notifications Toggle
    MainTab:CreateToggle({
        Name = "Notifications",
        CurrentValue = showNotifications,
        Flag = "ShowNotifications",
        Callback = function(Value)
            showNotifications = Value
            
            if showNotifications then
                notify("Notifications", "Notifications activées", 2)
            end
        end,
    })
    
    -- Onglet Options
    local OptionsTab = Window:CreateTab("Options", 4483345998)
    
    OptionsTab:CreateSection("À propos")
    
    OptionsTab:CreateLabel("PS99 Mobile Pro v1.0")
    OptionsTab:CreateLabel("Développé par zekyu")
    
    OptionsTab:CreateButton({
        Name = "Fermer l'interface",
        Callback = function()
            Rayfield:Destroy()
        end,
    })
    
    notify("PS99 Mobile Pro", "Interface chargée avec succès!", 3)
end

-- Démarrage de l'application
pcall(function()
    -- Message de démarrage
    notify("PS99 Mobile Pro", "Chargement du système d'authentification...", 3)
    
    -- Attendre un peu pour que le jeu se charge correctement
    wait(1)
    
    -- Lancer l'interface de clé
    createKeySystem()
end)
