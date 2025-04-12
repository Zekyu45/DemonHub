-- PS99 Mobile Pro - UI Module
-- Ce fichier contient uniquement l'interface utilisateur avec Rayfield

local ui = {}

-- Fonction pour créer une notification
function ui.notify(title, text, duration)
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

-- Nettoyer les anciennes instances d'UI
function ui.clearPreviousUI()
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
    
    pcall(function()
        for _, gui in pairs(game:GetService("CoreGui"):GetChildren()) do
            if gui.Name == "Rayfield" or gui.Name == "PS99MobilePro" then
                gui:Destroy()
            end
        end
    end)
    
    pcall(function()
        for _, gui in pairs(LocalPlayer.PlayerGui:GetChildren()) do
            if gui.Name == "Rayfield" or gui.Name == "PS99MobilePro" then
                gui:Destroy()
            end
        end
    end)
end

-- Créer l'interface utilisateur Rayfield
function ui.createCustomUI(toggleAfk, showNotifications, antiAfkEnabled)
    local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
    
    -- État initial
    local uiState = {
        showNotifications = showNotifications,
        antiAfkEnabled = antiAfkEnabled
    }
    
    -- Créer la fenêtre principale
    local Window = Rayfield:CreateWindow({
        Name = "PS99 Mobile Pro",
        LoadingTitle = "PS99 Mobile Pro",
        LoadingSubtitle = "par zekyu",
        ConfigurationSaving = {
            Enabled = false,
            FolderName = nil,
            FileName = nil
        }
    })
    
    -- Créer l'onglet des événements
    local EventTab = Window:CreateTab("Événement", 4483345998)
    
    -- Ajouter un paragraphe d'information sur les événements
    EventTab:CreateParagraph({
        Title = "Information sur les événements",
        Content = "Aucun événement disponible pour le moment"
    })
    
    -- Créer l'onglet de Farm
    local FarmTab = Window:CreateTab("Farm", 4483345998)
    
    -- Ajouter un toggle pour Anti-AFK
    FarmTab:CreateToggle({
        Name = "Anti-AFK",
        CurrentValue = uiState.antiAfkEnabled,
        Flag = "AntiAFK",
        Callback = function(Value)
            uiState.antiAfkEnabled = Value
            toggleAfk(Value)
            
            if uiState.showNotifications then
                if Value then
                    ui.notify("Anti-AFK", "Anti-AFK activé", 2)
                else
                    ui.notify("Anti-AFK", "Anti-AFK désactivé", 2)
                end
            end
        end
    })
    
    -- Ajouter un toggle pour les notifications
    FarmTab:CreateToggle({
        Name = "Notifications",
        CurrentValue = uiState.showNotifications,
        Flag = "Notifications",
        Callback = function(Value)
            uiState.showNotifications = Value
            
            if Value then
                ui.notify("Notifications", "Notifications activées", 2)
            end
        end
    })
    
    -- Créer l'onglet À propos
    local AboutTab = Window:CreateTab("À propos", 4483345998)
    
    -- Ajouter des informations sur l'application
    AboutTab:CreateParagraph({
        Title = "PS99 Mobile Pro v1.1",
        Content = "Développé par zekyu\nOptimisé pour appareils mobiles\n\nMerci d'utiliser notre application!"
    })
    
    -- Bouton pour fermer l'application
    AboutTab:CreateButton({
        Name = "Fermer l'application",
        Callback = function()
            Rayfield:Destroy()
            ui.notify("PS99 Mobile Pro", "Application fermée", 2)
        end
    })
    
    return {
        gui = Rayfield,
        getState = function() return uiState end
    }
end

-- Système de clé personnalisé avec Rayfield
function ui.startKeySystem(correctKey, onSuccess)
    local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
    
    local KeySystem = Rayfield:CreateWindow({
        Name = "PS99 Mobile Pro - Authentification",
        LoadingTitle = "PS99 Mobile Pro - Authentification",
        LoadingSubtitle = "par zekyu",
        ConfigurationSaving = {
            Enabled = false,
            FolderName = nil,
            FileName = nil
        },
        KeySystem = true,
        KeySettings = {
            Title = "PS99 Mobile Pro - Authentification",
            Subtitle = "La clé est fournie par zekyu",
            Note = "Veuillez entrer votre clé d'activation pour continuer",
            FileName = "PS99Key",
            SaveKey = false,
            GrabKeyFromSite = false,
            Key = correctKey
        }
    })
    
    -- Si l'authentification réussit, lancer la fonction onSuccess
    if KeySystem then
        task.wait(0.5)
        if onSuccess then
            onSuccess()
        end
    end
    
    return KeySystem
end

-- Interface de secours en cas d'erreur
function ui.createBackupUI(errorMsg)
    errorMsg = errorMsg or "Problème de connexion au serveur."
    
    local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
    
    local Window = Rayfield:CreateWindow({
        Name = "PS99 Mobile Pro - Mode Secours",
        LoadingTitle = "PS99 Mobile Pro - Mode Secours",
        LoadingSubtitle = "Une erreur s'est produite",
        ConfigurationSaving = {
            Enabled = false,
            FolderName = nil,
            FileName = nil
        }
    })
    
    local ErrorTab = Window:CreateTab("Erreur", 4483345998)
    
    ErrorTab:CreateParagraph({
        Title = "Erreur détectée",
        Content = "Impossible de charger l'interface.\nErreur détectée: " .. errorMsg
    })
    
    ErrorTab:CreateButton({
        Name = "Fermer",
        Callback = function()
            Rayfield:Destroy()
            ui.notify("Fermeture", "Application fermée", 2)
        end
    })
    
    return Window
end

return ui
