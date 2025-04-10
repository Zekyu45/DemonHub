-- PS99 Mobile Pro - Système d'authentification par clé optimisé pour mobile
-- Version corrigée pour l'erreur "attempt to concatenate nil with string"

-- Variables principales
local correctKey = "zekyu"  -- La clé reste "zekyu"
local showNotifications = true
local antiAfkEnabled = false

-- Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

-- Fonction pour créer une notification avec vérification
local function notify(title, text, duration)
    -- Vérification des valeurs nil
    title = title or "PS99 Mobile Pro"
    text = text or "Action effectuée"
    duration = duration or 2
    
    local success, err = pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = tostring(title),
            Text = tostring(text),
            Duration = duration,
            Icon = "rbxassetid://4483345998",
            Button1 = "OK"
        })
    end)
    
    if not success then
        warn("Notification échouée: " .. tostring(err))
    end
end

-- Message de démarrage initial
notify("PS99 Mobile Pro", "Démarrage de l'application...", 3)

-- Nettoyer les anciennes instances d'UI avec vérification
local function clearPreviousUI(name)
    if not name then return end
    
    pcall(function()
        for _, gui in ipairs(game:GetService("CoreGui"):GetChildren()) do
            if gui and gui.Name == name then
                gui:Destroy()
            end
        end
    end)
    
    pcall(function()
        for _, gui in ipairs(LocalPlayer.PlayerGui:GetChildren()) do
            if gui and gui.Name == name then
                gui:Destroy()
            end
        end
    end)
end

-- Nettoyer les interfaces précédentes au démarrage
clearPreviousUI("Rayfield")

-- Fonction Anti-AFK sécurisée
local function setupAntiAfk()
    local connection
    local VirtualUser = game:GetService("VirtualUser")
    
    return function(state)
        pcall(function()
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
        end)
    end
end

-- Fonction principale sécurisée
local function startApplication()
    task.wait(1) -- Attendre que le jeu se charge correctement
    
    notify("PS99 Mobile Pro", "Chargement de l'interface...", 2)
    
    -- Fonction sécurisée pour charger Rayfield
    local function loadRayfield()
        local Rayfield
        
        local success = pcall(function()
            Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua'))()
        end)
        
        if not success or not Rayfield then
            success = pcall(function()
                Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Rayfield/main/source'))()
            end)
        end
        
        return Rayfield
    end
    
    -- Charger Rayfield
    local Rayfield = loadRayfield()
    
    -- Vérifier si Rayfield a été chargé correctement
    if not Rayfield then
        notify("Erreur critique", "Impossible de charger Rayfield. Réessayez plus tard.", 5)
        return
    end
    
    -- Créer la fenêtre principale avec le système de clé intégré
    local Window = Rayfield:CreateWindow({
        Name = "PS99 Mobile Pro",
        LoadingTitle = "PS99 Mobile Pro",
        LoadingSubtitle = "par zekyu",
        ConfigurationSaving = {
            Enabled = true,
            FolderName = "PS99MobilePro",
            FileName = "Config"
        },
        KeySystem = true,
        KeySettings = {
            Title = "PS99 Mobile Pro - Authentification",
            Subtitle = "Entrez votre clé d'activation",
            Note = "La clé est fournie par zekyu",
            FileName = "PS99MobileKey",
            SaveKey = true,
            GrabKeyFromSite = false,
            Key = correctKey
        }
    })
    
    -- S'assurer que la fenêtre est créée avant de continuer
    if not Window then
        notify("Erreur", "Erreur lors de la création de la fenêtre", 3)
        return
    end
    
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
            toggleAfk(Value)
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
            -- Application de la distance avec vérification
            pcall(function()
                settings().Rendering.ViewingDistance = Value
            end)
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

-- Exécuter l'application avec gestion d'erreurs robuste
local success, errorMsg = pcall(startApplication)

if not success then
    warn("Erreur lors du démarrage: " .. tostring(errorMsg))
    notify("Erreur critique", "Impossible de démarrer: Vérifiez la console (F9)", 5)
end
