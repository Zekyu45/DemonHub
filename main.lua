-- PS99 Mobile Pro - Système d'authentification par clé optimisé pour mobile
-- Version avec système de secours si Rayfield ne charge pas

-- Variables principales
local correctKey = "zekyu"
local autoTpEventActive = false
local showNotifications = true
local hasBeenTeleported = false
local useBackupUI = false  -- Utilisera l'interface de secours si Rayfield échoue

-- Services
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- Position du portail pour aller à l'événement
local portalPosition = Vector3.new(174.04, 16.96, -141.07)

-- Fonction notification optimisée pour mobile
local function notify(title, text, duration)
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

-- Fonction de téléportation
local function teleportTo(position)
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then 
        notify("Erreur", "Impossible de téléporter - personnage non trouvé", 2)
        return false 
    end
    
    local safePosition = Vector3.new(position.X, position.Y + 5, position.Z)
    local success = pcall(function()
        character:SetPrimaryPartCFrame(CFrame.new(safePosition))
        wait(0.5)
        character:SetPrimaryPartCFrame(CFrame.new(position))
        character.HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
        character.HumanoidRootPart.RotVelocity = Vector3.new(0, 0, 0)
    end)
    
    if not success then
        pcall(function()
            character.HumanoidRootPart.CFrame = CFrame.new(position)
        end)
    end
    
    return true
end

-- Interface principale avec l'UI originale (en cas d'échec de Rayfield)
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
    mainFrame.Size = UDim2.new(0, 320, 0, 400)
    mainFrame.Position = UDim2.new(0.5, -160, 0.5, -200)
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
    
    -- Contenu principal
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "Content"
    contentFrame.Size = UDim2.new(1, -20, 1, -50)
    contentFrame.Position = UDim2.new(0, 10, 0, 45)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = mainFrame
    
    -- Créer un onglet simple pour Anti-AFK
    local antiAfkButton = Instance.new("TextButton")
    antiAfkButton.Name = "AntiAfkToggle"
    antiAfkButton.Size = UDim2.new(1, 0, 0, 40)
    antiAfkButton.Position = UDim2.new(0, 0, 0, 0)
    antiAfkButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    antiAfkButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    antiAfkButton.TextSize = 16
    antiAfkButton.Font = Enum.Font.SourceSansBold
    antiAfkButton.Text = "Anti-AFK: Désactivé"
    antiAfkButton.Parent = contentFrame
    
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
    
    -- Créer un onglet pour TP to Event
    local tpEventButton = Instance.new("TextButton")
    tpEventButton.Name = "TpEventToggle"
    tpEventButton.Size = UDim2.new(1, 0, 0, 40)
    tpEventButton.Position = UDim2.new(0, 0, 0, 50)
    tpEventButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    tpEventButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    tpEventButton.TextSize = 16
    tpEventButton.Font = Enum.Font.SourceSansBold
    tpEventButton.Text = "TP to Event"
    tpEventButton.Parent = contentFrame
    
    local tpEventCorner = Instance.new("UICorner")
    tpEventCorner.CornerRadius = UDim.new(0, 8)
    tpEventCorner.Parent = tpEventButton
    
    tpEventButton.MouseButton1Click:Connect(function()
        if not hasBeenTeleported then
            local character = LocalPlayer.Character
            if character and character:FindFirstChild("HumanoidRootPart") then
                teleportTo(portalPosition)
                hasBeenTeleported = true
                notify("Event", "Téléportation au portail d'événement", 2)
                tpEventButton.BackgroundColor3 = Color3.fromRGB(70, 180, 70)
                tpEventButton.Text = "TP to Event: Téléporté"
            else
                notify("Erreur", "Personnage non disponible pour la téléportation", 2)
            end
        else
            notify("Event", "Vous avez déjà été téléporté à l'événement", 2)
        end
    end)
    
    -- Créer un onglet pour Notifications
    local notifButton = Instance.new("TextButton")
    notifButton.Name = "NotifToggle"
    notifButton.Size = UDim2.new(1, 0, 0, 40)
    notifButton.Position = UDim2.new(0, 0, 0, 100)
    notifButton.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
    notifButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    notifButton.TextSize = 16
    notifButton.Font = Enum.Font.SourceSansBold
    notifButton.Text = "Notifications: Activées"
    notifButton.Parent = contentFrame
    
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
    
    -- Informations
    local infoLabel = Instance.new("TextLabel")
    infoLabel.Name = "InfoLabel"
    infoLabel.Size = UDim2.new(1, 0, 0, 40)
    infoLabel.Position = UDim2.new(0, 0, 1, -40)
    infoLabel.BackgroundTransparency = 1
    infoLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    infoLabel.TextSize = 14
    infoLabel.Font = Enum.Font.SourceSans
    infoLabel.Text = "PS99 Mobile Pro v1.0 - Développé par zekyu"
    infoLabel.Parent = contentFrame
    
    notify("PS99 Mobile Pro", "Interface chargée avec succès!", 3)
end

-- Tentative de charger Rayfield avec gestion d'erreur
local function loadRayfield()
    notify("PS99 Mobile Pro", "Tentative de chargement de Rayfield...", 2)
    
    local success, result
    success, result = pcall(function()
        return loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Rayfield/main/source'))()
    end)
    
    if success and result then
        notify("PS99 Mobile Pro", "Rayfield chargé avec succès", 2)
        return result
    else
        notify("PS99 Mobile Pro", "Échec de chargement de Rayfield, utilisation de l'interface de secours", 3)
        useBackupUI = true
        return nil
    end
end

-- Interface principale avec Rayfield
local function createMainInterface()
    if useBackupUI then
        createBackupMainUI()
        return
    end
    
    local Rayfield = loadRayfield()
    if not Rayfield then
        createBackupMainUI()
        return
    end
    
    local Window = Rayfield:CreateWindow({
        Name = "PS99 Mobile Pro",
        LoadingTitle = "PS99 Mobile Pro",
        LoadingSubtitle = "par zekyu",
        ConfigurationSaving = {
            Enabled = false,
            FolderName = nil,
            FileName = nil
        },
        Discord = {
            Enabled = false,
            Invite = nil,
            RememberJoins = false
        },
        KeySystem = false
    })
    
    -- Onglet Principal
    local MainTab = Window:CreateTab("Fonctionnalités", 4483362458)
    
    -- Anti-AFK Toggle
    local antiAfkEnabled = false
    local toggleAfk = setupAntiAfk()
    
    MainTab:CreateToggle({
        Name = "Anti-AFK",
        CurrentValue = antiAfkEnabled,
        Flag = "AntiAFK",
        Callback = function(Value)
            antiAfkEnabled = Value
            toggleAfk(antiAfkEnabled)
            
            if antiAfkEnabled then
                notify("Anti-AFK", "Système anti-AFK activé", 2)
            else
                notify("Anti-AFK", "Système anti-AFK désactivé", 2)
            end
        end,
    })
    
    -- TP to Event Button
    MainTab:CreateButton({
        Name = "TP to Event",
        Callback = function()
            if not hasBeenTeleported then
                local character = LocalPlayer.Character
                if character and character:FindFirstChild("HumanoidRootPart") then
                    teleportTo(portalPosition)
                    hasBeenTeleported = true
                    notify("Event", "Téléportation au portail d'événement", 2)
                else
                    notify("Erreur", "Personnage non disponible pour la téléportation", 2)
                end
            else
                notify("Event", "Vous avez déjà été téléporté à l'événement", 2)
            end
        end,
    })
    
    -- Notifications Toggle
    MainTab:CreateToggle({
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
    
    -- Onglet Options
    local OptionsTab = Window:CreateTab("Options", 4483345998)
    
    OptionsTab:CreateSection("À propos")
    
    OptionsTab:CreateLabel("PS99 Mobile Pro v1.0")
    OptionsTab:CreateLabel("Développé par zekyu")
    
    OptionsTab:CreateButton({
        Name = "Fermer l'interface",
        Callback = function()
            Rayfield:Destroy()
        end,
    })
    
    notify("PS99 Mobile Pro", "Interface Rayfield chargée avec succès!", 3)
end

-- Interface de saisie de clé (ScreenGui de base pour compatibilité maximale)
local function createKeyUI()
    notify("PS99 Mobile Pro", "Création de l'interface de clé...", 2)
    
    -- Créer ScreenGui pour le système de clé
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
        local enteredKey = keyInput.Text
        
        if enteredKey == correctKey then
            -- Animation de succès
            validateButton.BackgroundColor3 = Color3.fromRGB(70, 180, 70)
            validateButton.Text = "CLÉ VALIDE!"
            
            -- Notification de succès
            notify("Succès!", "Authentification réussie!", 2)
            
            -- Attendre un peu avant de fermer l'interface de clé
            wait(1)
            keyGui:Destroy()
            
            -- Charger l'interface principale
            local success, errorMsg = pcall(createMainInterface)
            if not success then
                warn("Erreur lors du chargement de l'interface principale:", errorMsg)
                notify("Erreur", "Impossible de charger l'interface principale", 3)
                wait(1)
                createBackupMainUI() -- Utiliser l'interface de secours en cas d'erreur
            end
        else
            -- Animation d'échec
            validateButton.BackgroundColor3 = Color3.fromRGB(180, 70, 70)
            validateButton.Text = "CLÉ INVALIDE!"
            
            -- Notification d'échec
            notify("Erreur", "Clé invalide! Veuillez réessayer.", 2)
            
            -- Effet de secousse
            local originalPosition = mainFrame.Position
            for i = 1, 3 do
                mainFrame.Position = originalPosition + UDim2.new(0.01, 0, 0, 0)
                wait(0.05)
                mainFrame.Position = originalPosition - UDim2.new(0.01, 0, 0, 0)
                wait(0.05)
            end
            mainFrame.Position = originalPosition
            
            -- Réinitialiser le bouton après un délai
            wait(1)
            validateButton.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
            validateButton.Text = "VALIDER LA CLÉ"
        end
    end)
    
    -- Centrer l'interface sur l'écran
    mainFrame.Position = UDim2.new(0.5, -150, 0.5, -90)
    
    notify("PS99 Mobile Pro", "Interface de clé créée, en attente de validation...", 2)

    return KeyGui
end


pcall(function()

    notify("PS99 Mobile Pro",  "Démarrage de l'application...", 3)


    wait(1)



    local KeyUISuccess = pcall(createKeyUI)

    
    if not keyUISuccess then
            notify"Erreur Critique", "Impossible de créer l'interface de saisie de clé", 5)
    end
end)
            
