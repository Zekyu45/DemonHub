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

-- Créer une interface utilisateur simple personnalisée au lieu d'utiliser Rayfield
local function createCustomUI()
    -- Créer le ScreenGui principal
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "PS99MobilePro"
    
    -- Déterminer où placer le ScreenGui
    if syn and syn.protect_gui then
        syn.protect_gui(screenGui)
        screenGui.Parent = game:GetService("CoreGui")
    elseif gethui then
        screenGui.Parent = gethui()
    else
        screenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    end
    
    -- Créer le fond principal
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0.8, 0, 0.7, 0)
    mainFrame.Position = UDim2.new(0.1, 0, 0.15, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = screenGui
    -- Ajouter un coin arrondi
    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0, 8)
    uiCorner.Parent = mainFrame
    
    -- Créer la barre de titre
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0.08, 0)
    titleBar.Position = UDim2.new(0, 0, 0, 0)
    titleBar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    
    -- Ajouter un coin arrondi à la barre de titre
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 8)
    titleCorner.Parent = titleBar
    
    -- Créer le titre
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(0.7, 0, 1, 0)
    title.Position = UDim2.new(0.15, 0, 0, 0)
    title.BackgroundTransparency = 1
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 18
    title.Font = Enum.Font.GothamBold
    title.Text = "PS99 Mobile Pro"
    title.Parent = titleBar
    
    -- Bouton de fermeture
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0.06, 0, 0.8, 0)
    closeButton.Position = UDim2.new(0.93, 0, 0.1, 0)
    closeButton.BackgroundColor3 = Color3.fromRGB(255, 70, 70)
    closeButton.Text = "X"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextSize = 16
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Parent = titleBar
    
    -- Ajouter un coin arrondi au bouton de fermeture
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeButton
    
    -- Créer le cadre pour Event (en haut à gauche)
    local eventFrame = Instance.new("Frame")
    eventFrame.Name = "EventFrame"
    eventFrame.Size = UDim2.new(0.48, 0, 0.4, 0)
    eventFrame.Position = UDim2.new(0.01, 0, 0.1, 0)
    eventFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    eventFrame.BorderSizePixel = 0
    eventFrame.Parent = mainFrame
    
    -- Ajouter un coin arrondi au cadre Event
    local eventCorner = Instance.new("UICorner")
    eventCorner.CornerRadius = UDim.new(0, 8)
    eventCorner.Parent = eventFrame
    
    -- Titre pour Event
    local eventTitle = Instance.new("TextLabel")
    eventTitle.Name = "EventTitle"
    eventTitle.Size = UDim2.new(1, 0, 0.15, 0)
    eventTitle.Position = UDim2.new(0, 0, 0, 0)
    eventTitle.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    eventTitle.BorderSizePixel = 0
    eventTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    eventTitle.TextSize = 16
    eventTitle.Font = Enum.Font.GothamBold
    eventTitle.Text = "Event"
    eventTitle.Parent = eventFrame
    
    -- Ajouter un coin arrondi au titre Event
    local eventTitleCorner = Instance.new("UICorner")
    eventTitleCorner.CornerRadius = UDim.new(0, 8)
    eventTitleCorner.Parent = eventTitle
    
    -- Message pour Event (vide pour l'instant)
    local eventMessage = Instance.new("TextLabel")
    eventMessage.Name = "EventMessage"
    eventMessage.Size = UDim2.new(0.9, 0, 0.7, 0)
    eventMessage.Position = UDim2.new(0.05, 0, 0.25, 0)
    eventMessage.BackgroundTransparency = 1
    eventMessage.TextColor3 = Color3.fromRGB(200, 200, 200)
    eventMessage.TextSize = 14
    eventMessage.Font = Enum.Font.Gotham
    eventMessage.Text = "Aucun événement disponible pour le moment"
    eventMessage.TextWrapped = true
    eventMessage.Parent = eventFrame
    
    -- Créer le cadre pour Farm (en haut à droite)
    local farmFrame = Instance.new("Frame")
    farmFrame.Name = "FarmFrame"
    farmFrame.Size = UDim2.new(0.48, 0, 0.4, 0)
    farmFrame.Position = UDim2.new(0.51, 0, 0.1, 0)
    farmFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    farmFrame.BorderSizePixel = 0
    farmFrame.Parent = mainFrame
    
    -- Ajouter un coin arrondi au cadre Farm
    local farmCorner = Instance.new("UICorner")
    farmCorner.CornerRadius = UDim.new(0, 8)
    farmCorner.Parent = farmFrame
    
    -- Titre pour Farm
    local farmTitle = Instance.new("TextLabel")
    farmTitle.Name = "FarmTitle"
    farmTitle.Size = UDim2.new(1, 0, 0.15, 0)
    farmTitle.Position = UDim2.new(0, 0, 0, 0)
    farmTitle.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    farmTitle.BorderSizePixel = 0
    farmTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    farmTitle.TextSize = 16
    farmTitle.Font = Enum.Font.GothamBold
    farmTitle.Text = "Farm"
    farmTitle.Parent = farmFrame
    
    -- Ajouter un coin arrondi au titre Farm
    local farmTitleCorner = Instance.new("UICorner")
    farmTitleCorner.CornerRadius = UDim.new(0, 8)
    farmTitleCorner.Parent = farmTitle
    
    -- Créer le bouton Anti-AFK dans le cadre Farm
    local antiAfkButton = Instance.new("TextButton")
    antiAfkButton.Name = "AntiAfkButton"
    antiAfkButton.Size = UDim2.new(0.8, 0, 0.25, 0)
    antiAfkButton.Position = UDim2.new(0.1, 0, 0.3, 0)
    antiAfkButton.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
    antiAfkButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    antiAfkButton.TextSize = 14
    antiAfkButton.Font = Enum.Font.GothamBold
    antiAfkButton.Text = "Anti-AFK: Désactivé"
    antiAfkButton.Parent = farmFrame
    
    -- Ajouter un coin arrondi au bouton Anti-AFK
    local antiAfkCorner = Instance.new("UICorner")
    antiAfkCorner.CornerRadius = UDim.new(0, 6)
    antiAfkCorner.Parent = antiAfkButton
    
    -- Bouton Notifications
    local notifButton = Instance.new("TextButton")
    notifButton.Name = "NotifButton"
    notifButton.Size = UDim2.new(0.8, 0, 0.25, 0)
    notifButton.Position = UDim2.new(0.1, 0, 0.65, 0)
    notifButton.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
    notifButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    notifButton.TextSize = 14
    notifButton.Font = Enum.Font.GothamBold
    notifButton.Text = "Notifications: Activées"
    notifButton.Parent = farmFrame
    
    -- Ajouter un coin arrondi au bouton Notifications
    local notifCorner = Instance.new("UICorner")
    notifCorner.CornerRadius = UDim.new(0, 6)
    notifCorner.Parent = notifButton
    
    -- Créer le cadre pour la section "À propos"
    local aboutFrame = Instance.new("Frame")
    aboutFrame.Name = "AboutFrame"
    aboutFrame.Size = UDim2.new(0.98, 0, 0.4, 0)
    aboutFrame.Position = UDim2.new(0.01, 0, 0.55, 0)
    aboutFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    aboutFrame.BorderSizePixel = 0
    aboutFrame.Parent = mainFrame
    
    -- Ajouter un coin arrondi au cadre À propos
    local aboutCorner = Instance.new("UICorner")
    aboutCorner.CornerRadius = UDim.new(0, 8)
    aboutCorner.Parent = aboutFrame
    
    -- Titre pour À propos
    local aboutTitle = Instance.new("TextLabel")
    aboutTitle.Name = "AboutTitle"
    aboutTitle.Size = UDim2.new(1, 0, 0.15, 0)
    aboutTitle.Position = UDim2.new(0, 0, 0, 0)
    aboutTitle.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    aboutTitle.BorderSizePixel = 0
    aboutTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    aboutTitle.TextSize = 16
    aboutTitle.Font = Enum.Font.GothamBold
    aboutTitle.Text = "À propos"
    aboutTitle.Parent = aboutFrame
    
    -- Ajouter un coin arrondi au titre À propos
    local aboutTitleCorner = Instance.new("UICorner")
    aboutTitleCorner.CornerRadius = UDim.new(0, 8)
    aboutTitleCorner.Parent = aboutTitle
    
    -- Information À propos
    local aboutInfo = Instance.new("TextLabel")
    aboutInfo.Name = "AboutInfo"
    aboutInfo.Size = UDim2.new(0.9, 0, 0.7, 0)
    aboutInfo.Position = UDim2.new(0.05, 0, 0.25, 0)
    aboutInfo.BackgroundTransparency = 1
    aboutInfo.TextColor3 = Color3.fromRGB(200, 200, 200)
    aboutInfo.TextSize = 14
    aboutInfo.Font = Enum.Font.Gotham
    aboutInfo.Text = "PS99 Mobile Pro v1.1\nDéveloppé par zekyu\nOptimisé pour appareils mobiles\n\nMerci d'utiliser notre application!"
    aboutInfo.TextWrapped = true
    aboutInfo.TextXAlignment = Enum.TextXAlignment.Left
    aboutInfo.TextYAlignment = Enum.TextYAlignment.Top
    aboutInfo.Parent = aboutFrame
    
    -- Configuration des fonctions de boutons
    local toggleAfk = setupAntiAfk()
    
    -- Bouton Anti-AFK
    antiAfkButton.MouseButton1Click:Connect(function()
        antiAfkEnabled = not antiAfkEnabled
        toggleAfk(antiAfkEnabled)
        
        if antiAfkEnabled then
            antiAfkButton.Text = "Anti-AFK: Activé"
            antiAfkButton.BackgroundColor3 = Color3.fromRGB(50, 180, 100)
        else
            antiAfkButton.Text = "Anti-AFK: Désactivé"
            antiAfkButton.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
        end
    end)
    
    -- Bouton Notifications
    notifButton.MouseButton1Click:Connect(function()
        showNotifications = not showNotifications
        
        if showNotifications then
            notifButton.Text = "Notifications: Activées"
            notifButton.BackgroundColor3 = Color3.fromRGB(50, 180, 100)
            notify("Notifications", "Notifications activées", 2)
        else
            notifButton.Text = "Notifications: Désactivées"
            notifButton.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
        end
    end)
    
    -- Bouton de fermeture
    closeButton.MouseButton1Click:Connect(function()
        screenGui:Destroy()
        notify("PS99 Mobile Pro", "Application fermée", 2)
    end)
    
    -- État initial des boutons
    if showNotifications then
        notifButton.Text = "Notifications: Activées"
        notifButton.BackgroundColor3 = Color3.fromRGB(50, 180, 100)
    end
    
    return screenGui
end

-- Système de clé personnalisé
local function startKeySystem()
    -- Créer le ScreenGui pour la clé
    local keyGui = Instance.new("ScreenGui")
    keyGui.Name = "PS99KeySystem"
    
    -- Déterminer où placer le ScreenGui
    if syn and syn.protect_gui then
        syn.protect_gui(keyGui)
        keyGui.Parent = game:GetService("CoreGui")
    elseif gethui then
        keyGui.Parent = gethui()
    else
        keyGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    end
    
    -- Créer le cadre principal
    local keyFrame = Instance.new("Frame")
    keyFrame.Name = "KeyFrame"
    keyFrame.Size = UDim2.new(0.6, 0, 0.4, 0)
    keyFrame.Position = UDim2.new(0.2, 0, 0.3, 0)
    keyFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    keyFrame.BorderSizePixel = 0
    keyFrame.Parent = keyGui
    
    -- Ajouter un coin arrondi
    local keyCorner = Instance.new("UICorner")
    keyCorner.CornerRadius = UDim.new(0, 8)
    keyCorner.Parent = keyFrame
    
    -- Titre
    local keyTitle = Instance.new("TextLabel")
    keyTitle.Name = "KeyTitle"
    keyTitle.Size = UDim2.new(1, 0, 0.2, 0)
    keyTitle.Position = UDim2.new(0, 0, 0, 0)
    keyTitle.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    keyTitle.BorderSizePixel = 0
    keyTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    keyTitle.TextSize = 18
    keyTitle.Font = Enum.Font.GothamBold
    keyTitle.Text = "PS99 Mobile Pro - Authentification"
    keyTitle.Parent = keyFrame
    
    -- Ajouter un coin arrondi au titre
    local keyTitleCorner = Instance.new("UICorner")
    keyTitleCorner.CornerRadius = UDim.new(0, 8)
    keyTitleCorner.Parent = keyTitle
    
    -- Message d'information
    local keyInfo = Instance.new("TextLabel")
    keyInfo.Name = "KeyInfo"
    keyInfo.Size = UDim2.new(0.9, 0, 0.2, 0)
    keyInfo.Position = UDim2.new(0.05, 0, 0.25, 0)
    keyInfo.BackgroundTransparency = 1
    keyInfo.TextColor3 = Color3.fromRGB(200, 200, 200)
    keyInfo.TextSize = 14
    keyInfo.Font = Enum.Font.Gotham
    keyInfo.Text = "Veuillez entrer votre clé d'activation pour continuer"
    keyInfo.Parent = keyFrame
    
    -- Champ de saisie de la clé
    local keyInput = Instance.new("TextBox")
    keyInput.Name = "KeyInput"
    keyInput.Size = UDim2.new(0.8, 0, 0.15, 0)
    keyInput.Position = UDim2.new(0.1, 0, 0.5, 0)
    keyInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    keyInput.BorderSizePixel = 0
    keyInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    keyInput.TextSize = 14
    keyInput.Font = Enum.Font.Gotham
    keyInput.PlaceholderText = "Entrez votre clé ici..."
    keyInput.Text = ""
    keyInput.ClearTextOnFocus = false
    keyInput.Parent = keyFrame
    
    -- Ajouter un coin arrondi au champ de saisie
    local keyInputCorner = Instance.new("UICorner")
    keyInputCorner.CornerRadius = UDim.new(0, 6)
    keyInputCorner.Parent = keyInput
    
    -- Bouton de validation
    local submitButton = Instance.new("TextButton")
    submitButton.Name = "SubmitButton"
    submitButton.Size = UDim2.new(0.4, 0, 0.15, 0)
    submitButton.Position = UDim2.new(0.3, 0, 0.75, 0)
    submitButton.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
    submitButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    submitButton.TextSize = 14
    submitButton.Font = Enum.Font.GothamBold
    submitButton.Text = "Valider"
    submitButton.Parent = keyFrame
    
    -- Ajouter un coin arrondi au bouton de validation
    local submitCorner = Instance.new("UICorner")
    submitCorner.CornerRadius = UDim.new(0, 6)
    submitCorner.Parent = submitButton
    
    -- Note en bas
    local keyNote = Instance.new("TextLabel")
    keyNote.Name = "KeyNote"
    keyNote.Size = UDim2.new(0.9, 0, 0.1, 0)
    keyNote.Position = UDim2.new(0.05, 0, 0.9, 0)
    keyNote.BackgroundTransparency = 1
    keyNote.TextColor3 = Color3.fromRGB(150, 150, 150)
    keyNote.TextSize = 12
    keyNote.Font = Enum.Font.Gotham
    keyNote.Text = "La clé est fournie par zekyu"
    keyNote.Parent = keyFrame
    
    -- Fonction de validation
    submitButton.MouseButton1Click:Connect(function()
        local enteredKey = keyInput.Text:gsub("%s+", ""):lower()
        
        if enteredKey == correctKey:lower() then
            notify("Succès!", "Clé validée avec succès", 3)
            task.wait(1)
            keyGui:Destroy()
            task.wait(0.5)
            createCustomUI()
        else
            notify("Erreur!", "Clé d'activation incorrecte", 3)
            keyInput.Text = ""
        end
    end)
    
    -- Animation d'ouverture
    keyFrame.Position = UDim2.new(0.2, 0, -0.5, 0)
    local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    local tween = game:GetService("TweenService"):Create(keyFrame, tweenInfo, {Position = UDim2.new(0.2, 0, 0.3, 0)})
    tween:Play()
end

-- Lancer le système de clé avec gestion d'erreurs
local success, err = pcall(startKeySystem)

if not success then
    warn("Erreur lors du démarrage: " .. tostring(err))
    notify("Erreur critique", "Impossible de démarrer l'application", 5)
    
    -- Interface de secours minimale en cas d'erreur
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
        msg.Text = "Impossible de charger l'interface.\nErreur détectée: Problème de connexion au serveur."
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
end
