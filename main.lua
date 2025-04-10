-- PS99 Mobile Pro - Version Rayfield UI
-- Système d'authentification par clé optimisé pour mobile

-- Importer le module UI
local ui = require("ui")

-- Variables principales
local correctKey = "zekyu"  -- La clé reste "zekyu"
local showNotifications = true
local antiAfkEnabled = false

-- Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local TeleportService = game:GetService("TeleportService")

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
                    ui.notify("Anti-AFK", "Système anti-AFK démarré", 2)
                end
            else
                if connection then
                    connection:Disconnect()
                    connection = nil
                    ui.notify("Anti-AFK", "Système anti-AFK désactivé", 2)
                end
            end
        end)
    end
end

-- Fonction à exécuter après l'authentification
local function onAuthSuccess()
    local toggleAfk = setupAntiAfk()
    ui.createCustomUI(toggleAfk, showNotifications, antiAfkEnabled)
end

-- Lancer le système de clé avec gestion d'erreurs
local success, err = pcall(function()
    ui.startKeySystem(correctKey, onAuthSuccess)
end)

if not success then
    warn("Erreur lors du démarrage: " .. tostring(err))
    ui.notify("Erreur critique", "Impossible de démarrer l'application", 5)
    
    -- Interface de secours minimale en cas d'erreur
    pcall(function()
        ui.createBackupUI(tostring(err))
    end)
end
