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

-- Fonction pour créer une notification
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

-- Nettoyer les anciennes instances d'UI
local function clearPreviousUI()
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

clearPreviousUI()

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

-- Charger la bibliothèque Rayfield
local Rayfield = nil

local function loadRayfieldLibrary()
    local success, result = pcall(function()
        return loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Rayfield/main/source'))()
    end)
    
    if not success then
        notify("Info", "Tentative avec URL alternative...", 2)
        
        success, result = pcall(function()
            return loadstring(game:HttpGet('https://raw.githubusercontent.com/UI-Interface/CustomFIeld/main/RayField.lua'))()
        end)
    end
    
    if not success then
        notify("Erreur", "Échec du chargement de l'interface Rayfield", 3)
        warn("Échec du chargement de Rayfield: " .. tostring(result))
        return nil
    end
    
    return result
end

-- Essayer de charger l'interface
local function tryLoadInterface()
    -- Afficher une notification de chargement
    notify("Chargement", "Tentative de connexion...", 3)
    
    -- Essayer 3 fois avec délai entre chaque tentative
    for attempt = 1, 3 do
        Rayfield = loadRayfieldLibrary()
        
        if Rayfield then
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
    
    -- Interface de secours minimale
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
        msg.Text = "Impossible de charger l'interface Rayfield.\nErreur détectée: Problème de connexion au serveur."
        msg.TextSize = 16
        msg.TextWrapped = true
        msg.Parent = mainFrame
        
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

-- Système de clé avec Rayfield
local function startKeySystem()
    local Window = Rayfield:CreateWindow({
        Name = "PS99 Mobile Pro - Authentification",
        LoadingTitle = "PS99 Mobile Pro",
        LoadingSubtitle = "par zekyu",
        ConfigurationSaving = {
            Enabled = false,
            FolderName = "PS99MobilePro",
            FileName = "Config"
        },
        KeySystem = true,
        KeySettings = {
            Title = "PS99 Mobile Pro",
            Subtitle = "Système d'authentification",
            Note = "La clé est fournie par zekyu",
            FileName = "PS99Key",
            SaveKey = false,
            GrabKeyFromSite = false,
            Key = correctKey
        }
    })
    
    -- Après validation de la clé, l'interface principale se lancera automatiquement
    startMainUI(Window)
end

-- Interface principale après validation de la clé
function startMainUI(Window)
    -- Onglet Principal
    local MainTab = Window:CreateTab("Principal", 4483345998)
    
    -- Section Anti-AFK
    local AfkSection = MainTab:CreateSection("Système Anti-AFK")
    
    local toggleAfk = setupAntiAfk()
    
    local AfkToggle = MainTab:CreateToggle({
        Name = "Anti-AFK",
        CurrentValue = antiAfkEnabled,
        Flag = "AntiAfkEnabled",
        Callback = function(Value)
            antiAfkEnabled = Value
            toggleAfk(Value)
        end,
    })
    
    -- Section Notifications
    local NotifSection = MainTab:CreateSection("Configuration")
    
    local NotifToggle = MainTab:CreateToggle({
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
    
    -- Onglet Aide
    local HelpTab = Window:CreateTab("Aide", 4483345998)
    
    HelpTab:CreateParagraph({
        Title = "Aide",
        Content = "Si vous rencontrez des problèmes, veuillez contacter zekyu."
    })
    
    HelpTab:CreateButton({
        Name = "Fermer l'application",
        Callback = function()
            Rayfield:Destroy()
        end,
    })
    
    -- Notification finale
    notify("PS99 Mobile Pro", "Interface chargée avec succès!", 3)
end

-- Lancer le système de clé avec meilleure gestion d'erreurs
local success, err = pcall(startKeySystem)

if not success then
    warn("Erreur lors du démarrage: " .. tostring(err))
    notify("Erreur critique", "Impossible de démarrer l'application", 5)
end
