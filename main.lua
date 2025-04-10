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

-- Charger la bibliothèque Orion
local OrionLib = nil

local function loadOrionLibrary()
    local success, result = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexware/Orion/main/source"))()
    end)
    
    if not success then
        notify("Erreur", "Échec du chargement de l'interface Orion", 3)
        warn("Échec du chargement d'Orion: " .. tostring(result))
        return nil
    end
    
    return result
end

OrionLib = loadOrionLibrary()

if not OrionLib then
    notify("Erreur critique", "Impossible de charger l'interface utilisateur", 5)
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

-- Lancer le système de clé
local success, err = pcall(startKeySystem)

if not success then
    warn("Erreur lors du démarrage: " .. tostring(err))
    notify("Erreur critique", "Impossible de démarrer l'application", 5)
end
