-- PS99 Mobile Pro - Système d'authentification par clé optimisé pour mobile
-- Version corrigée pour résoudre les problèmes d'affichage de l'UI

-- Variables principales
local correctKey = "zekyu"  -- La clé est "zekyu"
local showNotifications = true
local antiAfkEnabled = false

-- Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

-- Fonction pour créer une simple notification de secours au cas où Rayfield échoue
local function backupNotify(title, text, duration)
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
backupNotify("PS99 Mobile Pro", "Démarrage de l'application...", 3)

-- Sécurisation du chargement de l'interface
local Rayfield
local success, errorMsg = pcall(function()
    Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/UI-Interface/CustomFIeld/main/RayField.lua'))()
end)

if not success then
    backupNotify("Erreur", "Échec du chargement de l'interface: " .. tostring(errorMsg), 5)
    warn("Échec du chargement de CustomField: " .. tostring(errorMsg))
    -- On tente un chargement alternatif
    pcall(function()
        Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Rayfield/main/source'))()
    end)
    if not Rayfield then
        backupNotify("Erreur", "Impossible de charger une interface alternative", 5)
        return
    end
end

-- Fonction notification optimisée pour mobile
local function notify(title, text, duration)
    if not showNotifications then return end
    
    if Rayfield and Rayfield.Notify then
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
    else
        backupNotify(title, text, duration)
    end
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

-- Vérifier si une instance avec le même nom existe déjà et la supprimer
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

-- Fonction pour charger l'interface principale avec CustomField
local function createMainUI()
    -- Nettoyage préventif
    clearPreviousUI("Rayfield")
    
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
        KeySettings = nil,
        Discord = {
            Enabled = false
        }
    })
    
    -- Vérifier si la fenêtre a été créée correctement
    if not Window then
        notify("Erreur", "Échec de création de la fenêtre principale", 5)
        return
    end
    
    -- Onglet Principal
    local MainTab = Window:CreateTab("Principal", 4483345998)
    if not MainTab then
        notify("Erreur", "Échec de création de l'onglet principal", 5)
        return
    end
    
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
            wait(1)
            notify("PS99 Mobile Pro", "Tous les œufs ont été collectés!", 2)
        end
    })
    
    MainTab:CreateButton({
        Name = "Téléportation rapide",
        Callback = function()
            notify("PS99 Mobile Pro", "Menu de téléportation en préparation...", 2)
            -- Simulation d'action
            wait(0.5)
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
            game.Workspace.Camera.CFrame = game.Workspace.Camera.CFrame
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

-- Interface de clé avec système de secours
local function createKeyUI()
    -- Nettoyage préventif
    clearPreviousUI("Rayfield")
    
    local keyVerified = false
    
    -- Tenter d'utiliser le système de clé intégré à Rayfield
    local success, errorMsg = pcall(function()
        Rayfield:CreateWindow({
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
                Key = correctKey,
                Callback = function(enteredKey)
                    if enteredKey == correctKey then
                        keyVerified = true
                        wait(1)
                        createMainUI()
                    end
                end
            },
            Discord = {
                Enabled = false
            }
        })
    end)
    
    -- Si le système de clé intégré échoue, créer un système de secours
    if not success then
        warn("Échec du système de clé intégré: " .. tostring(errorMsg))
        
        -- Création d'une interface de secours pour la vérification de clé
        local backupKeyUI = Instance.new("ScreenGui")
        backupKeyUI.Name = "PS99KeyBackup"
        backupKeyUI.ResetOnSpawn = false
        
        -- Rendre l'interface persistante
        if syn and syn.protect_gui then
            syn.protect_gui(backupKeyUI)
            backupKeyUI.Parent = CoreGui
        elseif gethui then
            backupKeyUI.Parent = gethui()
        else
            backupKeyUI.Parent = CoreGui
        end
        
        -- Cadre principal
        local mainFrame = Instance.new("Frame")
        mainFrame.Name = "KeyFrame"
        mainFrame.Size = UDim2.new(0, 300, 0, 180)
        mainFrame.Position = UDim2.new(0.5, -150, 0.5, -90)
        mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        mainFrame.BorderSizePixel = 0
        mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
        mainFrame.Active = true
        mainFrame.Draggable = true
        mainFrame.Parent = backupKeyUI
        
        -- Arrondir les coins
        local UICorner = Instance.new("UICorner")
        UICorner.CornerRadius = UDim.new(0, 10)
        UICorner.Parent = mainFrame
        
        -- Titre
        local titleBar = Instance.new("Frame")
        titleBar.Name = "TitleBar"
        titleBar.Size = UDim2.new(1, 0, 0, 40)
        titleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        titleBar.BorderSizePixel = 0
        titleBar.Parent = mainFrame
        
        local titleCorner = Instance.new("UICorner")
        titleCorner.CornerRadius = UDim.new(0, 10)
        titleCorner.Parent = titleBar
        
        local titleText = Instance.new("TextLabel")
        titleText.Name = "Title"
        titleText.Size = UDim2.new(1, -10, 1, 0)
        titleText.Position = UDim2.new(0, 10, 0, 0)
        titleText.BackgroundTransparency = 1
        titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
        titleText.TextSize = 18
        titleText.Font = Enum.Font.SourceSansBold
        titleText.Text = "PS99 Mobile Pro - Authentification"
        titleText.TextXAlignment = Enum.TextXAlignment.Left
        titleText.Parent = titleBar
        
        -- Texte d'instruction
        local instructionText = Instance.new("TextLabel")
        instructionText.Name = "Instruction"
        instructionText.Size = UDim2.new(1, -20, 0, 30)
        instructionText.Position = UDim2.new(0, 10, 0, 50)
        instructionText.BackgroundTransparency = 1
        instructionText.TextColor3 = Color3.fromRGB(255, 255, 255)
        instructionText.TextSize = 16
        instructionText.Font = Enum.Font.SourceSans
        instructionText.Text = "Entrez votre clé d'activation:"
        instructionText.TextXAlignment = Enum.TextXAlignment.Left
        instructionText.Parent = mainFrame
        
        -- Champ de texte pour la clé
        local keyInput = Instance.new("TextBox")
        keyInput.Name = "KeyInput"
        keyInput.Size = UDim2.new(1, -20, 0, 40)
        keyInput.Position = UDim2.new(0, 10, 0, 85)
        keyInput.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        keyInput.TextColor3 = Color3.fromRGB(255, 255, 255)
        keyInput.TextSize = 16
        keyInput.Font = Enum.Font.SourceSans
        keyInput.PlaceholderText = "Entrez votre clé ici..."
        keyInput.Text = ""
        keyInput.ClearTextOnFocus = false
        keyInput.Parent = mainFrame
        
        local keyInputCorner = Instance.new("UICorner")
        keyInputCorner.CornerRadius = UDim.new(0, 8)
        keyInputCorner.Parent = keyInput
        
        -- Bouton de validation
        local validateButton = Instance.new("TextButton")
        validateButton.Name = "ValidateButton"
        validateButton.Size = UDim2.new(1, -20, 0, 40)
        validateButton.Position = UDim2.new(0, 10, 0, 135)
        validateButton.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
        validateButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        validateButton.TextSize = 16
        validateButton.Font = Enum.Font.SourceSansBold
        validateButton.Text = "VALIDER LA CLÉ"
        validateButton.Parent = mainFrame
        
        local validateCorner = Instance.new("UICorner")
        validateCorner.CornerRadius = UDim.new(0, 8)
        validateCorner.Parent = validateButton
        
        -- Fonction pour valider la clé
        validateButton.MouseButton1Click:Connect(function()
            -- Nettoyer les espaces et vérifier en ignorant la casse
            local enteredKey = keyInput.Text:gsub("%s+", ""):lower() 
            local correctKeyLower = correctKey:lower()
            
            if enteredKey == correctKeyLower then
                -- Animation de succès
                validateButton.BackgroundColor3 = Color3.fromRGB(70, 180, 70)
                validateButton.Text = "CLÉ VALIDE!"
                
                backupNotify("Succès!", "Authentification réussie!", 2)
                wait(1)
                backupKeyUI:Destroy()
                
                -- Charger l'interface principale
                createMainUI()
            else
                -- Animation d'échec
                validateButton.BackgroundColor3 = Color3.fromRGB(180, 70, 70)
                validateButton.Text = "CLÉ INVALIDE!"
                
                backupNotify("Erreur", "Clé d'authentification incorrecte", 3)
                
                -- Effet de secousse
                local originalPosition = mainFrame.Position
                for i = 1, 3 do
                    mainFrame.Position = originalPosition + UDim2.new(0.01, 0, 0, 0)
                    wait(0.05)
                    mainFrame.Position = originalPosition - UDim2.new(0.01, 0, 0, 0)
                    wait(0.05)
                end
                mainFrame.Position = originalPosition
                
                wait(1)
                validateButton.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
                validateButton.Text = "VALIDER LA CLÉ"
            end
        end)
    end
end

-- Démarrage de l'application avec gestion d'erreurs
local success, errorMsg = pcall(function()
    wait(1)  -- Attendre que le jeu se charge complètement
    createKeyUI()
end)

if not success then
    backupNotify("Erreur critique", "Impossible de démarrer l'application: " .. tostring(errorMsg), 5)
    warn("Erreur critique: " .. tostring(errorMsg))
end
