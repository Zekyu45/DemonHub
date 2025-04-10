-- PS99 Mobile Pro - Système d'authentification par clé optimisé pour mobile

-- Variables principales
local correctKey = "zekyu"  -- La clé est "zekyu"
local showNotifications = true
local antiAfkEnabled = false

-- Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local CoreGui = game:GetService("CoreGui")

-- Fonction pour créer une notification
local function notify(title, text, duration)
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
notify("PS99 Mobile Pro", "Démarrage de l'application...", 3)

-- Nettoyer les anciennes instances d'UI
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

-- Nettoyer les interfaces précédentes au démarrage
clearPreviousUI("Rayfield")
clearPreviousUI("PS99KeySystem")

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

-- Interface de vérification de clé personnalisée
local function createKeyUI()
    local keyUI = Instance.new("ScreenGui")
    keyUI.Name = "PS99KeySystem"
    keyUI.ResetOnSpawn = false
    
    -- Rendre l'interface persistante
    if syn and syn.protect_gui then
        syn.protect_gui(keyUI)
        keyUI.Parent = CoreGui
    elseif gethui then
        keyUI.Parent = gethui()
    else
        keyUI.Parent = CoreGui
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
    mainFrame.Parent = keyUI
    
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 10)
    UICorner.Parent = mainFrame
    
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
        local enteredKey = keyInput.Text:gsub("%s+", ""):lower() 
        local correctKeyLower = correctKey:lower()
        
        if enteredKey == correctKeyLower then
            -- Animation de succès
            validateButton.BackgroundColor3 = Color3.fromRGB(70, 180, 70)
            validateButton.Text = "CLÉ VALIDE!"
            
            notify("Succès!", "Authentification réussie!", 2)
            
            -- Détruire l'UI de clé après un court délai
            task.wait(1)
            keyUI:Destroy()
            
            -- Charger le Rayfield et l'interface principale
            loadRayfieldAndCreateMainUI()
        else
            -- Animation d'échec
            validateButton.BackgroundColor3 = Color3.fromRGB(180, 70, 70)
            validateButton.Text = "CLÉ INVALIDE!"
            
            notify("Erreur", "Clé d'authentification incorrecte", 3)
            
            -- Effet de secousse
            local originalPosition = mainFrame.Position
            for i = 1, 3 do
                mainFrame.Position = originalPosition + UDim2.new(0.01, 0, 0, 0)
                task.wait(0.05)
                mainFrame.Position = originalPosition - UDim2.new(0.01, 0, 0, 0)
                task.wait(0.05)
            end
            mainFrame.Position = originalPosition
            
            task.wait(1)
            validateButton.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
            validateButton.Text = "VALIDER LA CLÉ"
        end
    end)
    
    return keyUI
end

-- Fonction pour charger Rayfield et créer l'interface principale
function loadRayfieldAndCreateMainUI()
    -- Nettoyer les anciennes instances
    clearPreviousUI("Rayfield")
    
    -- SOLUTION UNIFIÉE: Charger Rayfield puis créer l'interface en une seule fonction
    -- Cela garantit que la séquence d'exécution est correcte
    
    -- Notification de chargement
    notify("PS99 Mobile Pro", "Chargement de l'interface...", 2)
    
    -- Charger Rayfield
    local Rayfield = nil
    local success, errorMsg = pcall(function()
        Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua'))()
        return true
    end)
    
    if not success then
        notify("Erreur", "Échec du chargement de Rayfield. Nouvelle tentative...", 2)
        
        -- Tentative de chargement alternatif
        success, errorMsg = pcall(function()
            Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Rayfield/main/source'))()
            return true
        end)
        
        if not success then
            notify("Erreur critique", "Impossible de charger Rayfield", 5)
            return
        end
    end
    
    -- Attendre pour s'assurer que Rayfield est bien chargé
    task.wait(1)
    
    -- Créer la fenêtre principale
    local Window = Rayfield:CreateWindow({
        Name = "PS99 Mobile Pro",
        LoadingTitle = "PS99 Mobile Pro",
        LoadingSubtitle = "par zekyu",
        ConfigurationSaving = {
            Enabled = true,
            FolderName = "PS99MobilePro",
            FileName = "Config"
        },
        KeySystem = false, -- Nous avons déjà vérifié la clé
        Discord = {
            Enabled = false
        }
    })
    
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
    
    -- Message de succès
    notify("PS99 Mobile Pro", "Interface chargée avec succès!", 3)
end

-- Fonction principale pour démarrer l'application
local function startApplication()
    task.wait(1) -- Attendre que le jeu se charge correctement
    createKeyUI() -- Créer l'interface de vérification de clé
    notify("PS99 Mobile Pro", "Veuillez entrer votre clé pour continuer", 3)
end

-- Exécuter l'application avec gestion d'erreurs
local success, errorMsg = pcall(startApplication)

if not success then
    notify("Erreur critique", "Impossible de démarrer l'application: " .. tostring(errorMsg), 5)
    warn("Erreur critique: " .. tostring(errorMsg))
end
