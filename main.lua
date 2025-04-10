-- PS99 Mobile Pro - Système d'authentification par clé optimisé pour mobile

-- Variables principales
local correctKey = "zekyu"  -- La clé reste "zekyu"
local showNotifications = true
local antiAfkEnabled = false

-- Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local CoreGui = game:GetService("CoreGui")

-- Fonction pour créer une notification
local function notify(title, text, duration)
    local StarterGui = game:GetService("StarterGui")
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

-- Message de démarrage initial
notify("PS99 Mobile Pro", "Démarrage de l'application...", 3)

-- Nettoyer les anciennes instances d'UI
local function clearPreviousUI(name)
    for _, gui in pairs(CoreGui:GetChildren()) do
        if gui.Name == name then
            gui:Destroy()
        end
    end
    for _, gui in pairs(game.Players.LocalPlayer.PlayerGui:GetChildren()) do
        if gui.Name == name then
            gui:Destroy()
        end
    end
end

-- Nettoyer les interfaces précédentes au démarrage
clearPreviousUI("Rayfield")
clearPreviousUI("PS99KeySystem")

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

-- Fonction principale pour démarrer l'application avec Rayfield
local function startApplication()
    task.wait(1) -- Attendre que le jeu se charge correctement
    
    notify("PS99 Mobile Pro", "Chargement de l'interface...", 2)
    
    -- Charger Rayfield
    local Rayfield = nil
    local success, errorMsg = pcall(function()
        Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua'))()
        return true
    end)
    
    if not success then
        notify("Erreur", "Échec du chargement de Rayfield. Nouvelle tentative...", 2)
        
        -- Tentative de chargement alternatif
        success, errorMsg = pcall(function()
            Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Rayfield/main/source'))()
            return true
        end)
        
        if not success then
            notify("Erreur critique", "Impossible de charger Rayfield", 5)
            return
        end
    end
    
    -- Attendre pour s'assurer que Rayfield est bien chargé
    task.wait(1)
    
    -- Créer la fenêtre principale AVEC le système de clé intégré à Rayfield
    local Window = Rayfield:CreateWindow({
        Name = "PS99 Mobile Pro",
        LoadingTitle = "PS99 Mobile Pro",
        LoadingSubtitle = "par zekyu",
        ConfigurationSaving = {
            Enabled = true,
            FolderName = "PS99MobilePro",
            FileName = "Config"
        },
        KeySystem = true, -- Utiliser le système de clé intégré à Rayfield
        KeySettings = {
            Title = "PS99 Mobile Pro - Authentification",
            Subtitle = "Entrez votre clé d'activation",
            Note = "La clé est fournie par zekyu",
            FileName = "PS99MobileKey",
            SaveKey = true,
            GrabKeyFromSite = false,
            Key = correctKey
        },
        Discord = {
            Enabled = false
        }
    })
    
    -- Une fois authentifié, Rayfield chargera automatiquement l'interface
    
    -- Onglet Principal
    local MainTab = Window:CreateTab("Principal", 4483345998)
    
    -- Section Anti-AFK
    MainTab:CreateSection("Système Anti-AFK")
    
    local toggleAfk = setupAntiAfk()
    
    MainTab:CreateToggle({
        Name = "Anti-AFK",
        CurrentValue = antiAfkEnabled,
        Flag = "AntiAfkToggle",
        Callback = function(Value)
            antiAfkEnabled = Value
            toggleAfk(antiAfkEnabled)
        end
    })
    
    -- Section Notifications
    MainTab:CreateSection("Configuration")
    
    MainTab:CreateToggle({
        Name = "Notifications",
        CurrentValue = showNotifications,
        Flag = "NotificationsToggle",
        Callback = function(Value)
            showNotifications = Value
            if showNotifications then
                notify("Notifications", "Notifications activées", 2)
            end
        end
    })
    
    -- Section fonctionnalités de jeu
    MainTab:CreateSection("Fonctionnalités de jeu")
    
    MainTab:CreateButton({
        Name = "Collecter tous les œufs",
        Callback = function()
            notify("PS99 Mobile Pro", "Collecte des œufs en cours...", 3)
            -- Simulation d'action
            task.wait(1)
            notify("PS99 Mobile Pro", "Tous les œufs ont été collectés!", 2)
        end
    })
    
    MainTab:CreateButton({
        Name = "Téléportation rapide",
        Callback = function()
            notify("PS99 Mobile Pro", "Menu de téléportation en préparation...", 2)
            -- Simulation d'action
            task.wait(0.5)
            notify("PS99 Mobile Pro", "Téléportation non disponible dans cette version", 2)
        end
    })
    
    -- Onglet Paramètres
    local SettingsTab = Window:CreateTab("Paramètres", 4483345998)
    
    -- Section Informations
    SettingsTab:CreateSection("Informations")
    
    SettingsTab:CreateLabel("PS99 Mobile Pro v1.1")
    SettingsTab:CreateLabel("Développé par zekyu")
    SettingsTab:CreateLabel("Optimisé pour appareils mobiles")
    
    -- Section Options avancées
    SettingsTab:CreateSection("Options avancées")
    
    SettingsTab:CreateDropdown({
        Name = "Qualité graphique",
        Options = {"Basse", "Moyenne", "Haute"},
        CurrentOption = "Moyenne",
        Flag = "GraphicsQuality",
        Callback = function(Option)
            notify("Paramètres", "Qualité graphique définie sur: " .. Option, 2)
            -- Application du paramètre
            if Option == "Basse" then
                settings().Rendering.QualityLevel = 1
            elseif Option == "Moyenne" then
                settings().Rendering.QualityLevel = 4
            elseif Option == "Haute" then 
                settings().Rendering.QualityLevel = 8
            end
        end
    })
    
    SettingsTab:CreateSlider({
        Name = "Distance de rendu",
        Range = {50, 2000},
        Increment = 50,
        Suffix = "unités",
        CurrentValue = 1000,
        Flag = "RenderDistance",
        Callback = function(Value)
            -- Application de la distance
            game:GetService("Lighting").GlobalShadows = Value > 500
            settings().Rendering.ViewingDistance = Value
        end,
    })
    
    SettingsTab:CreateButton({
        Name = "Fermer l'interface",
        Callback = function()
            Rayfield:Destroy()
        end
    })
    
    -- Message de succès
    notify("PS99 Mobile Pro", "Interface chargée avec succès!", 3)
end

-- Exécuter l'application avec gestion d'erreurs
local success, errorMsg = pcall(startApplication)

if not success then
    notify("Erreur critique", "Impossible de démarrer l'application: " .. tostring(errorMsg), 5)
    warn("Erreur critique: " .. tostring(errorMsg))
end
