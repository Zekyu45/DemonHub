-- PS99 Mobile Pro - Système d'authentification par clé optimisé pour mobile avec CustomField UI
-- Version améliorée

-- Variables principales
local correctKey = "zekyu"  -- La clé est "zekyu" 
local showNotifications = true
local antiAfkEnabled = false

-- Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Chargement de CustomField UI
local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/UI-Interface/CustomFIeld/main/RayField.lua'))()

-- Fonction notification optimisée pour mobile
local function notify(title, text, duration)
    if not showNotifications then return end
    
    Rayfield:Notify({
        Title = title,
        Content = text,
        Duration = duration or 2,
        Image = 4483345998,
        Actions = {
            Ignore = {
                Name = "OK",
                Callback = function() end
            }
        }
    })
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

-- Fonction pour charger l'interface principale avec CustomField
local function createMainUI()
    local Window = Rayfield:CreateWindow({
        Name = "PS99 Mobile Pro",
        LoadingTitle = "PS99 Mobile Pro",
        LoadingSubtitle = "par zekyu",
        ConfigurationSaving = {
            Enabled = true,
            FolderName = "PS99MobilePro",
            FileName = "Config"
        },
        KeySystem = false,
        Discord = {
            Enabled = false
        }
    })
    
    -- Onglet Principal
    local MainTab = Window:CreateTab("Principal", 4483345998)
    
    -- Section Anti-AFK
    local AfkSection = MainTab:CreateSection("Système Anti-AFK")
    
    local toggleAfk = setupAntiAfk()
    
    local AfkToggle = MainTab:CreateToggle({
        Name = "Anti-AFK",
        CurrentValue = antiAfkEnabled,
        Flag = "AntiAfkToggle",
        Callback = function(Value)
            antiAfkEnabled = Value
            toggleAfk(antiAfkEnabled)
            if antiAfkEnabled then
                notify("Anti-AFK", "Système anti-AFK activé", 2)
            else
                notify("Anti-AFK", "Système anti-AFK désactivé", 2)
            end
        end
    })
    
    -- Section Notifications
    local NotifSection = MainTab:CreateSection("Configuration")
    
    local NotifToggle = MainTab:CreateToggle({
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
    local GameSection = MainTab:CreateSection("Fonctionnalités de jeu")
    
    MainTab:CreateButton({
        Name = "Collecter tous les œufs",
        Callback = function()
            notify("PS99 Mobile Pro", "Collecte des œufs en cours...", 3)
            -- Code de collecte des œufs irait ici
            notify("PS99 Mobile Pro", "Tous les œufs ont été collectés!", 2)
        end
    })
    
    MainTab:CreateButton({
        Name = "Téléportation rapide",
        Callback = function()
            notify("PS99 Mobile Pro", "Menu de téléportation en préparation...", 2)
            -- Code de téléportation irait ici
        end
    })
    
    -- Onglet Paramètres
    local SettingsTab = Window:CreateTab("Paramètres", 4483345998)
    
    -- Section Informations
    local InfoSection = SettingsTab:CreateSection("Informations")
    
    SettingsTab:CreateLabel("PS99 Mobile Pro v1.1")
    SettingsTab:CreateLabel("Développé par zekyu")
    SettingsTab:CreateLabel("Optimisé pour appareils mobiles")
    
    -- Section Options avancées
    local AdvancedSection = SettingsTab:CreateSection("Options avancées")
    
    SettingsTab:CreateDropdown({
        Name = "Qualité graphique",
        Options = {"Basse", "Moyenne", "Haute"},
        CurrentOption = "Moyenne",
        Flag = "GraphicsQuality",
        Callback = function(Option)
            notify("Paramètres", "Qualité graphique définie sur: " .. Option, 2)
            -- Code pour changer la qualité graphique irait ici
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
            -- Code pour ajuster la distance de rendu irait ici
        end,
    })
    
    SettingsTab:CreateButton({
        Name = "Fermer l'interface",
        Callback = function()
            Rayfield:Destroy()
        end
    })
    
    notify("PS99 Mobile Pro", "Interface chargée avec succès!", 3)
end

-- Interface de clé avec CustomField
local function createKeyUI()
    local Window = Rayfield:CreateWindow({
        Name = "PS99 Mobile Pro - Authentification",
        LoadingTitle = "PS99 Mobile Pro",
        LoadingSubtitle = "Chargement de l'authentification...",
        ConfigurationSaving = {
            Enabled = false
        },
        KeySystem = true,
        KeySettings = {
            Title = "PS99 Mobile Pro - Authentification",
            Subtitle = "Entrez votre clé d'activation",
            Note = "La clé est sensible à la casse",
            FileName = "PS99Key",
            SaveKey = false,
            GrabKeyFromSite = false,
            Key = correctKey
        },
        Discord = {
            Enabled = false
        }
    })
    
    -- Callback pour la validation de la clé
    Rayfield.Initialized = function()
        createMainUI()
    end
end

-- Démarrage de l'application
pcall(function()
    notify("PS99 Mobile Pro", "Démarrage de l'application...", 3)
    wait(1)
    createKeyUI()
end)
