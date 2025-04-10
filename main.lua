-- PS99 Mobile Pro - Système d'authentification par clé optimisé pour mobile
-- Version simplifiée

-- Variables principales
local correctKey = "zekyu"  -- La clé est "zekyu" 
local showNotifications = true
local useBackupUI = false  -- Utilisera l'interface de secours si l'UI principale échoue

-- Services
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- Fonction notification optimisée pour mobile
local function notify(title, text, duration)
    if not showNotifications then return end
    
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

-- Interface principale avec l'UI de secours
local function createBackupMainUI()
    notify("PS99 Mobile Pro", "Chargement de l'interface de secours...", 2)
    
    -- Créer une interface simple avec ScreenGui
    local mainGui = Instance.new("ScreenGui")
    mainGui.Name = "PS99MobilePro"
    mainGui.ResetOnSpawn = false
    
    -- Rendre l'interface persistante
    if syn and syn.protect_gui then
        syn.protect_gui(mainGui)
        mainGui.Parent = CoreGui
    elseif gethui then
        mainGui.Parent = gethui()
    else
        mainGui.Parent = CoreGui
    end
    
    -- Créer le cadre principal
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 300, 0, 250)  -- Réduit pour enlever les colonnes
    mainFrame.Position = UDim2.new(0.5, -150, 0.5, -125)
    mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    mainFrame.BorderSizePixel = 0
    mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = mainGui
    
    -- Arrondir les coins
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 10)
    UICorner.Parent = mainFrame
    
    -- Titre de l'application
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
    titleText.Text = "PS99 Mobile Pro"
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Parent = titleBar
    
    -- Bouton de fermeture
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -35, 0, 5)
    closeButton.BackgroundColor3 = Color3.fromRGB(255, 70, 70)
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextSize = 18
    closeButton.Font = Enum.Font.SourceSansBold
    closeButton.Text = "X"
    closeButton.Parent = titleBar
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 10)
    closeCorner.Parent = closeButton
    
    closeButton.MouseButton1Click:Connect(function()
        mainGui:Destroy()
    end)
    
    -- Anti-AFK Toggle
    local antiAfkButton = Instance.new("TextButton")
    antiAfkButton.Name = "AntiAfkToggle"
    antiAfkButton.Size = UDim2.new(0.9, 0, 0, 40)
    antiAfkButton.Position = UDim2.new(0.05, 0, 0, 60)
    antiAfkButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    antiAfkButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    antiAfkButton.TextSize = 16
    antiAfkButton.Font = Enum.Font.SourceSansBold
    antiAfkButton.Text = "Anti-AFK: Désactivé"
    antiAfkButton.Parent = mainFrame
    
    local antiAfkCorner = Instance.new("UICorner")
    antiAfkCorner.CornerRadius = UDim.new(0, 8)
    antiAfkCorner.Parent = antiAfkButton
    
    local antiAfkEnabled = false
    local toggleAfk = setupAntiAfk()
    
    antiAfkButton.MouseButton1Click:Connect(function()
        antiAfkEnabled = not antiAfkEnabled
        toggleAfk(antiAfkEnabled)
        antiAfkButton.Text = "Anti-AFK: " .. (antiAfkEnabled and "Activé" or "Désactivé")
        antiAfkButton.BackgroundColor3 = antiAfkEnabled and Color3.fromRGB(70, 130, 180) or Color3.fromRGB(45, 45, 45)
    end)
    
    -- Notifications Toggle
    local notifButton = Instance.new("TextButton")
    notifButton.Name = "NotifToggle"
    notifButton.Size = UDim2.new(0.9, 0, 0, 40)
    notifButton.Position = UDim2.new(0.05, 0, 0, 110)
    notifButton.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
    notifButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    notifButton.TextSize = 16
    notifButton.Font = Enum.Font.SourceSansBold
    notifButton.Text = "Notifications: Activées"
    notifButton.Parent = mainFrame
    
    local notifCorner = Instance.new("UICorner")
    notifCorner.CornerRadius = UDim.new(0, 8)
    notifCorner.Parent = notifButton
    
    notifButton.MouseButton1Click:Connect(function()
        showNotifications = not showNotifications
        notifButton.Text = "Notifications: " .. (showNotifications and "Activées" or "Désactivées")
        notifButton.BackgroundColor3 = showNotifications and Color3.fromRGB(70, 130, 180) or Color3.fromRGB(45, 45, 45)
        
        if showNotifications then
            notify("Notifications", "Notifications activées", 2)
        end
    end)
    
    -- Informations en bas de l'interface
    local infoLabel = Instance.new("TextLabel")
    infoLabel.Name = "InfoLabel"
    infoLabel.Size = UDim2.new(1, -20, 0, 30)
    infoLabel.Position = UDim2.new(0, 10, 1, -35)
    infoLabel.BackgroundTransparency = 1
    infoLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    infoLabel.TextSize = 14
    infoLabel.Font = Enum.Font.SourceSans
    infoLabel.Text = "PS99 Mobile Pro v1.1 - Développé par zekyu"
    infoLabel.Parent = mainFrame
    
    notify("PS99 Mobile Pro", "Interface chargée avec succès!", 3)
end

-- Interface de clé de secours
local function createBackupKeyUI()
    local keyGui = Instance.new("ScreenGui")
    keyGui.Name = "PS99KeySystem"
    keyGui.ResetOnSpawn = false
    
    -- Rendre l'interface persistante
    if syn and syn.protect_gui then
        syn.protect_gui(keyGui)
        keyGui.Parent = CoreGui
    elseif gethui then
        keyGui.Parent = gethui()
    else
        keyGui.Parent = CoreGui
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
    mainFrame.Parent = keyGui
    
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
    
    -- Champ de texte pour la clé (TextBox fonctionnelle sur mobile)
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
            
            notify("Succès!", "Authentification réussie!", 2)
            wait(1)
            keyGui:Destroy()
            
            -- Charger l'interface principale
            createBackupMainUI()
        else
            -- Animation d'échec
            validateButton.BackgroundColor3 = Color3.fromRGB(180, 70, 70)
            validateButton.Text = "CLÉ INVALIDE!"
            
            notify("Erreur", "Clé d'authentification incorrecte", 3)
            
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
    
    return keyGui
end

-- Démarrage de l'application
pcall(function()
    notify("PS99 Mobile Pro", "Démarrage de l'application...", 3)
    wait(1)
    createBackupKeyUI()
end)
