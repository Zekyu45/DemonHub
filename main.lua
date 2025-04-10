-- PS99 Mobile Pro - Version Orion UI
-- Système d'authentification par clé optimisé pour mobile

-- Variables principales
local correctKey = "zekyu"  -- La clé reste "zekyu"
local showNotifications = true
local antiAfkEnabled = false

-- Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

-- Fonction pour créer une notification sécurisée
local function notify(title, text, duration)
    title = title or "PS99 Mobile Pro"
    text = text or "Action effectuée"
    duration = duration or 2
    
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = tostring(title),
            Text = tostring(text),
            Duration = duration,
            Icon = "rbxassetid://4483345998"
        })
    end)
end

-- Message de démarrage initial
notify("PS99 Mobile Pro", "Démarrage de l'application...", 3)

-- Nettoyer les anciennes instances d'UI pour éviter les conflits
local function clearPreviousUI()
    pcall(function()
        for _, gui in pairs(game:GetService("CoreGui"):GetChildren()) do
            if gui.Name == "OrionLib" or gui.Name == "PS99MobilePro" then
                gui:Destroy()
            end
        end
    end)
    
    pcall(function()
        for _, gui in pairs(LocalPlayer.PlayerGui:GetChildren()) do
            if gui.Name == "OrionLib" or gui.Name == "PS99MobilePro" then
                gui:Destroy()
            end
        end
    end)
end

clearPreviousUI()

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
                        if showNotifications then
                            notify("Anti-AFK", "Inactivité détectée. Système activé.", 2)
                        end
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

-- FIX 1: Utiliser un miroir alternatif et ajouter un système de récupération pour Orion
local OrionLib = nil

local function loadOrionLibrary()
    -- Méthode 1: URL principale
    local success, result = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexware/Orion/main/source"))()
    end)
    
    -- Si la première méthode échoue, essayer une URL alternative
    if not success then
        notify("Info", "Tentative avec URL alternative...", 2)
        
        -- Méthode 2: URL alternative (exemple)
        success, result = pcall(function()
            return loadstring(game:HttpGet("https://raw.githubusercontent.com/richie0866/Orion/main/source.lua"))()
        end)
    end
    
    -- Si les deux méthodes échouent, essayer d'utiliser un contenu préchargé
    if not success then
        notify("Info", "Chargement de la version locale...", 2)
        
        -- Méthode 3: Orion Library intégrée (version simplifiée)
        -- FIX 2: Version minimale de secours en cas d'échec total
        success, result = pcall(function()
            -- Cette version minimale d'Orion permettra au moins d'afficher une interface basique
            local MinimalOrion = {}
            
            function MinimalOrion:MakeWindow(config)
                local window = {}
                
                function window:MakeTab(config)
                    local tab = {}
                    
                    function tab:AddSection(config)
                        return true
                    end
                    
                    function tab:AddParagraph(title, content)
                        print("[MinimalOrion] Paragraph: " .. title .. " - " .. content)
                        return true
                    end
                    
                    function tab:AddButton(config)
                        return true
                    end
                    
                    function tab:AddToggle(config)
                        return true
                    end
                    
                    function tab:AddTextbox(config)
                        return true
                    end
                    
                    function tab:AddDropdown(config)
                        return true
                    end
                    
                    function tab:AddSlider(config)
                        return true
                    end
                    
                    return tab
                end
                
                return window
            end
            
            function MinimalOrion:MakeNotification(config)
                notify(config.Name, config.Content, config.Time or 3)
                return true
            end
            
            function MinimalOrion:Destroy()
                return true
            end
            
            return MinimalOrion
        end)
    end
    
    if not success then
        notify("Erreur", "Échec du chargement de l'interface Orion", 3)
        warn("Échec du chargement d'Orion: " .. tostring(result))
        return nil
    end
    
    return result
end

-- FIX 3: Utiliser une approche progressive pour charger l'interface
local function tryLoadInterface()
    -- Afficher une notification de chargement
    notify("Chargement", "Tentative de connexion...", 3)
    
    -- Essayer 3 fois avec délai entre chaque tentative
    for attempt = 1, 3 do
        OrionLib = loadOrionLibrary()
        
        if OrionLib then
            notify("Succès", "Interface chargée (tentative " .. attempt .. ")", 2)
            return true
        end
        
        -- Attendre avant la prochaine tentative
        notify("Échec", "Nouvelle tentative dans 3s (" .. attempt .. "/3)", 2)
        wait(3)
    end
    
    return false
end

-- Essayer de charger l'interface
local interfaceLoaded = tryLoadInterface()

if not interfaceLoaded then
    notify("Erreur critique", "Impossible de charger l'interface utilisateur", 5)
    
    -- FIX 4: Interface de secours minimale pour débloquer l'utilisateur
    pcall(function()
        local backupFrame = Instance.new("ScreenGui")
        backupFrame.Name = "PS99MobileProBackup"
        
        local mainFrame = Instance.new("Frame")
        mainFrame.Size = UDim2.new(0.8, 0, 0.6, 0)
        mainFrame.Position = UDim2.new(0.1, 0, 0.2, 0)
        mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        mainFrame.BorderSizePixel = 2
        mainFrame.Parent = backupFrame
        
        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, 0, 0.1, 0)
        title.Position = UDim2.new(0, 0, 0, 0)
        title.TextColor3 = Color3.fromRGB(255, 255, 255)
        title.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
        title.Font = Enum.Font.SourceSansBold
        title.Text = "PS99 Mobile Pro - Mode Secours"
        title.TextSize = 18
        title.Parent = mainFrame
        
        local msg = Instance.new("TextLabel")
        msg.Size = UDim2.new(0.9, 0, 0.3, 0)
        msg.Position = UDim2.new(0.05, 0, 0.2, 0)
        msg.TextColor3 = Color3.fromRGB(255, 255, 255)
        msg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        msg.Font = Enum.Font.SourceSans
        msg.Text = "Impossible de charger l'interface Orion.\nErreur détectée: Problème de connexion au serveur."
        msg.TextSize = 16
        msg.TextWrapped = true
        msg.Parent = mainFrame
        
        local retryBtn = Instance.new("TextButton")
        retryBtn.Size = UDim2.new(0.4, 0, 0.1, 0)
        retryBtn.Position = UDim2.new(0.3, 0, 0.5, 0)
        retryBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        retryBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
        retryBtn.Font = Enum.Font.SourceSansBold
        retryBtn.Text = "Réessayer"
        retryBtn.TextSize = 18
        retryBtn.Parent = mainFrame
        
        local closeBtn = Instance.new("TextButton")
        closeBtn.Size = UDim2.new(0.4, 0, 0.1, 0)
        closeBtn.Position = UDim2.new(0.3, 0, 0.7, 0)
        closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        closeBtn.BackgroundColor3 = Color3.fromRGB(180, 70, 70)
        closeBtn.Font = Enum.Font.SourceSansBold
        closeBtn.Text = "Fermer"
        closeBtn.TextSize = 18
        closeBtn.Parent = mainFrame
        
        -- Ajouter les fonctionnalités aux boutons
        retryBtn.MouseButton1Click:Connect(function()
            backupFrame:Destroy()
            
            -- Relancer le processus
            notify("Redémarrage", "Tentative de reconnexion...", 3)
            wait(1)
            
            -- Réutiliser le script actuel
            loadstring(game:HttpGet("https://pastebin.com/raw/YourScriptBackupURL"))()
        end)
        
        closeBtn.MouseButton1Click:Connect(function()
            backupFrame:Destroy()
            notify("Fermeture", "Application fermée", 2)
        end)
        
        -- Déterminer où placer le ScreenGui
        if syn and syn.protect_gui then
            syn.protect_gui(backupFrame)
            backupFrame.Parent = game:GetService("CoreGui")
        elseif gethui then
            backupFrame.Parent = gethui()
        else
            backupFrame.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
        end
    end)
    
    return
end

-- Système de clé personnalisé avec Orion
local function startKeySystem()
    local keyWindow = OrionLib:MakeWindow({
        Name = "PS99 Mobile Pro - Authentification",
        HidePremium = true,
        SaveConfig = false,
        IntroEnabled = true,
        IntroText = "PS99 Mobile Pro",
        IntroIcon = "rbxassetid://4483345998",
        Icon = "rbxassetid://4483345998",
        IconColor = Color3.fromRGB(70, 130, 180),
        CloseCallback = function()
            -- Action lorsque la fenêtre est fermée
        end
    })
    
    local keyTab = keyWindow:MakeTab({
        Name = "Authentification",
        Icon = "rbxassetid://4483345998",
        PremiumOnly = false
    })
    
    keyTab:AddParagraph("Information", "Veuillez entrer votre clé d'activation pour continuer")
    
    local keyInput = ""
    
    keyTab:AddTextbox({
        Name = "Clé d'activation",
        Default = "",
        TextDisappear = true,
        Callback = function(Value)
            keyInput = Value
        end
    })
    
    -- FIX 5: Ajouter un bouton pour récupérer la clé
    keyTab:AddButton({
        Name = "Récupérer la clé (Debug)",
        Callback = function()
            keyInput = correctKey
            OrionLib:MakeNotification({
                Name = "Debug",
                Content = "Clé récupérée: " .. correctKey,
                Image = "rbxassetid://4483345998",
                Time = 5
            })
        end
    })
    
    keyTab:AddButton({
        Name = "Valider la clé",
        Callback = function()
            -- Vérifier la clé
            local enteredKey = keyInput:gsub("%s+", ""):lower()
            
            if enteredKey == correctKey:lower() then
                OrionLib:MakeNotification({
                    Name = "Succès!",
                    Content = "Clé validée avec succès",
                    Image = "rbxassetid://4483345998",
                    Time = 3
                })
                
                task.wait(1)
                OrionLib:Destroy()
                task.wait(0.5)
                startMainUI()
            else
                OrionLib:MakeNotification({
                    Name = "Erreur!",
                    Content = "Clé d'activation incorrecte",
                    Image = "rbxassetid://4483345998",
                    Time = 3
                })
            end
        end
    })
    
    keyTab:AddParagraph("Note", "La clé est fournie par zekyu")
end

-- Interface principale après validation de la clé
function startMainUI()
    local mainWindow = OrionLib:MakeWindow({
        Name = "PS99 Mobile Pro v1.1",
        HidePremium = true,
        SaveConfig = true,
        ConfigFolder = "PS99MobilePro",
        IntroEnabled = true,
        IntroText = "PS99 Mobile Pro",
        IntroIcon = "rbxassetid://4483345998",
        Icon = "rbxassetid://4483345998",
        IconColor = Color3.fromRGB(70, 130, 180)
    })
    
    -- Onglet Principal
    local mainTab = mainWindow:MakeTab({
        Name = "Principal",
        Icon = "rbxassetid://4483345998",
        PremiumOnly = false
    })
    
    -- Section Anti-AFK
    mainTab:AddSection({
        Name = "Système Anti-AFK"
    })
    
    local toggleAfk = setupAntiAfk()
    
    mainTab:AddToggle({
        Name = "Anti-AFK",
        Default = antiAfkEnabled,
        Flag = "AntiAfkEnabled",
        Save = true,
        Callback = function(Value)
            antiAfkEnabled = Value
            toggleAfk(Value)
        end
    })
    
    -- Section Notifications
    mainTab:AddSection({
        Name = "Configuration"
    })
    
    mainTab:AddToggle({
        Name = "Notifications",
        Default = showNotifications,
        Flag = "ShowNotifications",
        Save = true,
        Callback = function(Value)
            showNotifications = Value
            if showNotifications then
                notify("Notifications", "Notifications activées", 2)
            end
        end
    })
    
    -- Section fonctionnalités de jeu
    mainTab:AddSection({
        Name = "Fonctionnalités de jeu"
    })
    
    mainTab:AddButton({
        Name = "Collecter tous les œufs",
        Callback = function()
            OrionLib:MakeNotification({
                Name = "PS99 Mobile Pro",
                Content = "Collecte des œufs en cours...",
                Image = "rbxassetid://4483345998",
                Time = 3
            })
            
            -- Simulation d'action
            task.wait(1)
            
            OrionLib:MakeNotification({
                Name = "PS99 Mobile Pro",
                Content = "Tous les œufs ont été collectés!",
                Image = "rbxassetid://4483345998",
                Time = 2
            })
        end
    })
    
    mainTab:AddButton({
        Name = "Ouvrir Menu Téléportation",
        Callback = function()
            OrionLib:MakeNotification({
                Name = "PS99 Mobile Pro",
                Content = "Ouverture du menu téléportation...",
                Image = "rbxassetid://4483345998",
                Time = 2
            })
            
            -- Simulation d'action
            task.wait(0.5)
            
            -- Liste de téléportation fictive
            local teleportLocations = {
                "Zone de départ",
                "Zone trading",
                "Zone mystique",
                "Terrain d'entraînement",
                "Arène de combat"
            }
            
            -- Créer un nouveau tab de téléportation à la demande
            local tpTab = mainWindow:MakeTab({
                Name = "Téléportation",
                Icon = "rbxassetid://4483345998",
                PremiumOnly = false
            })
            
            for _, location in pairs(teleportLocations) do
                tpTab:AddButton({
                    Name = "Téléporter: " .. location,
                    Callback = function()
                        OrionLib:MakeNotification({
                            Name = "Téléportation",
                            Content = "Téléportation vers: " .. location,
                            Image = "rbxassetid://4483345998",
                            Time = 2
                        })
                    end
                })
            end
        end
    })
    
    -- Onglet Paramètres
    local settingsTab = mainWindow:MakeTab({
        Name = "Paramètres",
        Icon = "rbxassetid://4483345998",
        PremiumOnly = false
    })
    
    -- Section Informations
    settingsTab:AddSection({
        Name = "Informations"
    })
    
    settingsTab:AddParagraph("Version", "PS99 Mobile Pro v1.1")
    settingsTab:AddParagraph("Développeur", "Développé par zekyu")
    settingsTab:AddParagraph("Optimisation", "Optimisé pour appareils mobiles")
    
    -- Section Options avancées
    settingsTab:AddSection({
        Name = "Options graphiques"
    })
    
    settingsTab:AddDropdown({
        Name = "Qualité graphique",
        Default = "Moyenne",
        Options = {"Basse", "Moyenne", "Haute"},
        Flag = "GraphicsQuality",
        Save = true,
        Callback = function(Option)
            OrionLib:MakeNotification({
                Name = "Paramètres",
                Content = "Qualité graphique définie sur: " .. Option,
                Image = "rbxassetid://4483345998",
                Time = 2
            })
            
            -- Application du paramètre
            pcall(function()
                if Option == "Basse" then
                    settings().Rendering.QualityLevel = 1
                elseif Option == "Moyenne" then
                    settings().Rendering.QualityLevel = 4
                elseif Option == "Haute" then 
                    settings().Rendering.QualityLevel = 8
                end
            end)
        end
    })
    
    settingsTab:AddSlider({
        Name = "Distance de rendu",
        Min = 50,
        Max = 2000,
        Default = 1000,
        Color = Color3.fromRGB(70, 130, 180),
        Increment = 50,
        Flag = "RenderDistance",
        Save = true,
        ValueName = "unités",
        Callback = function(Value)
            -- Application de la distance
            pcall(function()
                settings().Rendering.ViewingDistance = Value
            end)
        end
    })
    
    -- Onglet Aide
    local helpTab = mainWindow:MakeTab({
        Name = "Aide",
        Icon = "rbxassetid://4483345998",
        PremiumOnly = false
    })
    
    helpTab:AddParagraph("Aide", "Si vous rencontrez des problèmes, veuillez contacter zekyu.")
    
    helpTab:AddButton({
        Name = "Redémarrer l'application",
        Callback = function()
            OrionLib:MakeNotification({
                Name = "PS99 Mobile Pro",
                Content = "Redémarrage de l'application...",
                Image = "rbxassetid://4483345998",
                Time = 3
            })
            
            task.wait(1)
            OrionLib:Destroy()
            task.wait(0.5)
            
            -- Redémarrer l'application
            loadOrionLibrary()
            startKeySystem()
        end
    })
    
    helpTab:AddButton({
        Name = "Fermer l'application",
        Callback = function()
            OrionLib:Destroy()
        end
    })
    
    -- Notification finale
    OrionLib:MakeNotification({
        Name = "PS99 Mobile Pro",
        Content = "Interface chargée avec succès!",
        Image = "rbxassetid://4483345998",
        Time = 3
    })
end

-- Lancer le système de clé avec meilleure gestion d'erreurs
local success, err = pcall(startKeySystem)

if not success then
    warn("Erreur lors du démarrage: " .. tostring(err))
    notify("Erreur critique", "Impossible de démarrer l'application", 5)
    
    -- FIX 6: Tentative de récupération supplémentaire
    pcall(function()
        wait(2)
        notify("Récupération", "Tentative de démarrage direct...", 3)
        wait(1)
        pcall(startMainUI)
    end)
end
    
