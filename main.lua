-- PS99 Mobile Pro - Version Rayfield UI
-- Système d'authentification par clé optimisé pour mobile

-- Variables principales
local correctKey = "zekyu"  -- La clé reste "zekyu"
local showNotifications = true
local antiAfkEnabled = false

-- Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local TeleportService = game:GetService("TeleportService")

-- Charger le module UI depuis GitHub
local ui
local loadSuccess, loadErr = pcall(function()
    -- Dans un cas réel, vous devrez mettre à jour le fichier ui.lua sur GitHub
    -- avec la nouvelle version qui utilise Rayfield.
    -- Pour l'instant, utilisons l'hypothèse que le module est chargé localement
    local uiUrl = "https://raw.githubusercontent.com/Zekyu45/DemonHub/main/ui.lua"
    ui = loadstring(game:HttpGet(uiUrl))()
    return ui
end)

if not loadSuccess then
    warn("Échec du chargement du module UI: " .. tostring(loadErr))
    -- Créer une notification d'erreur basique sans utiliser le module UI
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Erreur critique",
            Text = "Impossible de charger l'interface utilisateur",
            Duration = 5
        })
    end)
    return -- Arrêter l'exécution du script
end

-- Message de démarrage initial
ui.notify("PS99 Mobile Pro", "Démarrage de l'application...", 3)

-- Nettoyer les anciennes instances d'UI
ui.clearPreviousUI()

-- Fonction Anti-AFK
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
                            ui.notify("Anti-AFK", "Inactivité détectée. Système activé.", 2)
                        end
                    end)
                    if showNotifications then
                        ui.notify("Anti-AFK", "Système anti-AFK démarré", 2)
                    end
                end
            else
                if connection then
                    connection:Disconnect()
                    connection = nil
                    if showNotifications then
                        ui.notify("Anti-AFK", "Système anti-AFK désactivé", 2)
                    end
                end
            end
        end)
    end
end

-- Fonction à exécuter après l'authentification
local function onAuthSuccess()
    local toggleAfk = setupAntiAfk()
    
    -- Créer l'interface principale et passer les callbacks nécessaires
    local mainUI = ui.createCustomUI(toggleAfk, showNotifications, antiAfkEnabled)
    
    -- Récupérer l'état de l'interface si nécessaire
    task.spawn(function()
        while task.wait(1) do
            local currentState = mainUI.getState()
            showNotifications = currentState.showNotifications
            antiAfkEnabled = currentState.antiAfkEnabled
            
            -- Vérifier si l'UI existe toujours
            if not mainUI.gui then 
                break
            end
        end
    end)
    
    -- Vous pouvez ajouter d'autres fonctionnalités post-authentification ici
end

-- Lancer le système de clé avec gestion d'erreurs
local success, err = pcall(function()
    ui.startKeySystem(correctKey, onAuthSuccess)
end)

if not success then
    warn("Erreur lors du démarrage: " .. tostring(err))
    
    -- Utiliser la notification de base si ui.notify n'est pas disponible
    pcall(function()
        ui.notify("Erreur critique", "Impossible de démarrer l'application", 5)
    end)
    
    -- Interface de secours minimale en cas d'erreur
    pcall(function()
        ui.createBackupUI(tostring(err))
    end)
end
