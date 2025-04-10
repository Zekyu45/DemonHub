-- PS99 Mobile Pro - Système d'authentification par clé optimisé pour mobile avec Rayfield UI
-- Version améliorée

-- Variables principales
local correctKey = "zekyu"  -- La clé est "zekyu" 
local showNotifications = true
local antiAfkEnabled = false

-- Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Fonction notification optimisée pour mobile
local function notify(title, text, duration)
    if not showNotifications then return end
    
    local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/jensonhirst/Rayfield/main/source'))()
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

-- Fonction pour charger l'interface principale avec Rayfield
local function createMainUI()
    local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/jensonhirst/Rayfield/main/source'))()
    
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
    
    -- Informations
    local InfoSection = MainTab:CreateSection("Informations")
    
    MainTab:CreateLabel("PS99 Mobile Pro v1.1 - Développé par zekyu")
    
    -- Onglet Options
    local OptionsTab = Window:CreateTab("Options", 4483345998)
    
    OptionsTab:CreateButton({
        Name = "Fermer l'interface",
        Callback = function()
            Rayfield:Destroy()
        end
    })
    
    notify("PS99 Mobile Pro", "Interface chargée avec succès!", 3)
end

-- Interface de clé avec Rayfield
local function createKeyUI()
    local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/jensonhirst/Rayfield/main/source'))()
    
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
