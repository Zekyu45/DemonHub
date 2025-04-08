-- PS99 Mobile Pro - Système d'authentification par clé optimisé pour mobile
-- Version avec système de secours si l'UI ne charge pas

-- Variables principales
local correctKey = "zekyu"  -- La clé est "zekyu" 
local autoTpEventActive = false
local autoTakeChestActive = false
local showNotifications = true
local hasBeenTeleported = false
local useBackupUI = false  -- Utilisera l'interface de secours si l'UI principale échoue
local isInEventZone = false
local lastChestCollectTime = 0
local chestCooldown = 120  -- 2 minutes en secondes

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
-- Centre approximatif de la zone d'événement (après la téléportation)
local eventZoneCenter = Vector3.new(174.04, 16.96, -141.07)  -- À ajuster selon la position réelle

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

-- Fonction pour vérifier si le joueur est dans la zone d'événement
local function checkIfInEventZone()
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        return false
    end
    
    local rootPart = character.HumanoidRootPart
    local distance = (rootPart.Position - eventZoneCenter).Magnitude
    
    -- Considérer dans la zone si à moins de 100 studs du centre
    return distance <= 100
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
    
    -- Marquer comme étant dans la zone d'événement après téléportation
    isInEventZone = true
    
    return true
end

-- Fonction pour collecter les coffres à proximité
local function collectNearbyChests()
    if not isInEventZone then
        if showNotifications then
            notify("Auto Chest", "Vous devez être dans la zone d'événement", 2)
        end
        return
    end
    
    local currentTime = os.time()
    if currentTime - lastChestCollectTime < chestCooldown then
        return  -- Attendre le cooldown
    end
    
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        return
    end
    
    local rootPart = character.HumanoidRootPart
    local chestCount = 0
    
    -- Trouver tous les coffres à proximité (200 studs)
    local chestsFound = {}
    for _, obj in pairs(workspace:GetDescendants()) do
        if (obj:IsA("Model") or obj:IsA("Part") or obj:IsA("MeshPart")) and 
           (obj.Name:lower():find("chest") or obj.Name:lower():find("coffre") or obj.Name:lower():find("box")) then
            if obj:FindFirstChild("PrimaryPart") then
                local distance = (obj.PrimaryPart.Position - rootPart.Position).Magnitude
                if distance <= 200 then
                    table.insert(chestsFound, obj)
                end
            elseif obj:IsA("BasePart") then
                local distance = (obj.Position - rootPart.Position).Magnitude
                if distance <= 200 then
                    table.insert(chestsFound, obj)
                end
            end
        end
    end
    
    -- Essayer d'interagir avec chaque coffre
    for _, chest in pairs(chestsFound) do
        local chestPosition
        if chest:FindFirstChild("PrimaryPart") then
            chestPosition = chest.PrimaryPart.Position
        elseif chest:IsA("BasePart") then
            chestPosition = chest.Position
        end
        
        if chestPosition then
            -- Méthode 1: Simuler une téléportation rapide pour collecter
            local originalPosition = rootPart.Position
            local originalCFrame = rootPart.CFrame
            
            -- Téléportation rapide au coffre
            rootPart.CFrame = CFrame.new(chestPosition)
            
            -- Simuler l'appui sur E ou toucher l'écran
            local VirtualUser = game:GetService("VirtualUser")
            VirtualUser:SetKeyDown("e")
            wait(0.1)
            VirtualUser:SetKeyUp("e")
            
            -- Méthode 2: Essayer de déclencher les événements du coffre directement
            for _, v in pairs(chest:GetDescendants()) do
                if v:IsA("ClickDetector") then
                    pcall(function() v:Click() end)
                elseif v:IsA("ProximityPrompt") then
                    pcall(function() v:InputHoldBegin() wait(0.1) v:InputHoldEnd() end)
                end
            end
            
            -- Revenir à la position originale
            rootPart.CFrame = originalCFrame
            
            chestCount = chestCount + 1
        end
    end
    
    -- Mettre à jour le temps de dernière collecte
    lastChestCollectTime = currentTime
    
    if chestCount > 0 and showNotifications then
        notify("Auto Chest", "Tentative de collecte de " .. chestCount .. " coffres", 2)
    elseif chestCount == 0 and showNotifications then
        notify("Auto Chest", "Aucun coffre trouvé à proximité", 2)
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
    mainFrame.Size = UDim2.new(0, 480, 0, 400)  -- Élargi pour accommoder 3 colonnes
    mainFrame.Position = UDim2.new(0.5, -240, 0.5, -200)
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
    
    -- Création des trois colonnes
    -- Colonne 1: Autres
    local column1 = Instance.new("Frame")
    column1.Name = "AutresColumn"
    column1.Size = UDim2.new(0, 150, 1, -50)
    column1.Position = UDim2.new(0, 10, 0, 45)
    column1.BackgroundTransparency = 1
    column1.Parent = mainFrame
    
    local column1Title = Instance.new("TextLabel")
    column1Title.Name = "Title"
    column1Title.Size = UDim2.new(1, 0, 0, 30)
    column1Title.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    column1Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    column1Title.TextSize = 16
    column1Title.Font = Enum.Font.SourceSansBold
    column1Title.Text = "Autres"
    column1Title.Parent = column1
    
    local titleCorner1 = Instance.new("UICorner")
    titleCorner1.CornerRadius = UDim.new(0, 8)
    titleCorner1.Parent = column1Title
    
    -- Colonne 2: Event actuelle
    local column2 = Instance.new("Frame")
    column2.Name = "EventColumn"
    column2.Size = UDim2.new(0, 150, 1, -50)
    column2.Position = UDim2.new(0, 170, 0, 45)
    column2.BackgroundTransparency = 1
    column2.Parent = mainFrame
    
    local column2Title = Instance.new("TextLabel")
    column2Title.Name = "Title"
    column2Title.Size = UDim2.new(1, 0, 0, 30)
    column2Title.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    column2Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    column2Title.TextSize = 16
    column2Title.Font = Enum.Font.SourceSansBold
    column2Title.Text = "Event actuelle"
    column2Title.Parent = column2
    
    local titleCorner2 = Instance.new("UICorner")
    titleCorner2.CornerRadius = UDim.new(0, 8)
    titleCorner2.Parent = column2Title
    
    -- Colonne 3: Farm
    local column3 = Instance.new("Frame")
    column3.Name = "FarmColumn"
    column3.Size = UDim2.new(0, 150, 1, -50)
    column3.Position = UDim2.new(0, 330, 0, 45)
    column3.BackgroundTransparency = 1
    column3.Parent = mainFrame
    
    local column3Title = Instance.new("TextLabel")
    column3Title.Name = "Title"
    column3Title.Size = UDim2.new(1, 0, 0, 30)
    column3Title.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    column3Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    column3Title.TextSize = 16
    column3Title.Font = Enum.Font.SourceSansBold
    column3Title.Text = "Farm"
    column3Title.Parent = column3
    
    local titleCorner3 = Instance.new("UICorner")
    titleCorner3.CornerRadius = UDim.new(0, 8)
    titleCorner3.Parent = column3Title
    
    -- Contenu de la colonne 1 (Autres)
    -- Anti-AFK Toggle
    local antiAfkButton = Instance.new("TextButton")
    antiAfkButton.Name = "AntiAfkToggle"
    antiAfkButton.Size = UDim2.new(1, 0, 0, 40)
    antiAfkButton.Position = UDim2.new(0, 0, 0, 40)
    antiAfkButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    antiAfkButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    antiAfkButton.TextSize = 16
    antiAfkButton.Font = Enum.Font.SourceSansBold
    antiAfkButton.Text = "Anti-AFK: Désactivé"
    antiAfkButton.Parent = column1
    
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
    notifButton.Size = UDim2.new(1, 0, 0, 40)
    notifButton.Position = UDim2.new(0, 0, 0, 90)
    notifButton.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
    notifButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    notifButton.TextSize = 16
    notifButton.Font = Enum.Font.SourceSansBold
    notifButton.Text = "Notifications: Activées"
    notifButton.Parent = column1
    
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
    
    -- Contenu de la colonne 2 (Event actuelle)
    -- Auto TP to Event Toggle
    local tpEventButton = Instance.new("TextButton")
    tpEventButton.Name = "TpEventToggle"
    tpEventButton.Size = UDim2.new(1, 0, 0, 40)
    tpEventButton.Position = UDim2.new(0, 0, 0, 40)
    tpEventButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    tpEventButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    tpEventButton.TextSize = 16
    tpEventButton.Font = Enum.Font.SourceSansBold
    tpEventButton.Text = "Auto TP to Event: Off"
    tpEventButton.Parent = column2
    
    local tpEventCorner = Instance.new("UICorner")
    tpEventCorner.CornerRadius = UDim.new(0, 8)
    tpEventCorner.Parent = tpEventButton
    
    tpEventButton.MouseButton1Click:Connect(function()
        autoTpEventActive = not autoTpEventActive
        tpEventButton.Text = "Auto TP to Event: " .. (autoTpEventActive and "On" or "Off")
        tpEventButton.BackgroundColor3 = autoTpEventActive and Color3.fromRGB(70, 130, 180) or Color3.fromRGB(45, 45, 45)
        
        if autoTpEventActive and not isInEventZone then
            local character = LocalPlayer.Character
            if character and character:FindFirstChild("HumanoidRootPart") then
                teleportTo(portalPosition)
                notify("Event", "Téléportation au portail d'événement", 2)
            else
                notify("Erreur", "Personnage non disponible pour la téléportation", 2)
            end
        elseif autoTpEventActive and isInEventZone then
            notify("Event", "Vous êtes déjà dans la zone d'événement", 2)
        end
    end)
    
    -- Auto Take Chest Toggle
    local autoChestButton = Instance.new("TextButton")
    autoChestButton.Name = "AutoChestToggle"
    autoChestButton.Size = UDim2.new(1, 0, 0, 40)
    autoChestButton.Position = UDim2.new(0, 0, 0, 90)
    autoChestButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    autoChestButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    autoChestButton.TextSize = 16
    autoChestButton.Font = Enum.Font.SourceSansBold
    autoChestButton.Text = "Auto Take Chest: Off"
    autoChestButton.Parent = column2
    
    local autoChestCorner = Instance.new("UICorner")
    autoChestCorner.CornerRadius = UDim.new(0, 8)
    autoChestCorner.Parent = autoChestButton
    
    autoChestButton.MouseButton1Click:Connect(function()
        autoTakeChestActive = not autoTakeChestActive
        autoChestButton.Text = "Auto Take Chest: " .. (autoTakeChestActive and "On" or "Off")
        autoChestButton.BackgroundColor3 = autoTakeChestActive and Color3.fromRGB(70, 130, 180) or Color3.fromRGB(45, 45, 45)
        
        if autoTakeChestActive then
            if isInEventZone then
                notify("Auto Chest", "Collection des coffres activée", 2)
                collectNearbyChests()  -- Collecter immédiatement
            else
                notify("Auto Chest", "Vous devez être dans la zone d'événement", 2)
            end
        else
            notify("Auto Chest", "Collection des coffres désactivée", 2)
        end
    end)
    
    -- Contenu de la colonne 3 (Farm) - Vide pour l'instant
    local farmLabel = Instance.new("TextLabel")
    farmLabel.Name = "FarmLabel"
    farmLabel.Size = UDim2.new(1, 0, 0, 40)
    farmLabel.Position = UDim2.new(0, 0, 0, 40)
    farmLabel.BackgroundTransparency = 1
    farmLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    farmLabel.TextSize = 14
    farmLabel.Font = Enum.Font.SourceSans
    farmLabel.Text = "À venir prochainement..."
    farmLabel.Parent = column3
    
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
    
    -- Configuration de la boucle pour vérifier l'état de la zone et collecter les coffres
    task.spawn(function()
        while wait(1) do
            if not mainGui or not mainGui.Parent then break end
            
            -- Vérifier périodiquement si le joueur est dans la zone d'événement
            isInEventZone = checkIfInEventZone()
            
            -- Gestion de l'auto téléportation si activée et que le joueur n'est pas dans la zone
            if autoTpEventActive and not isInEventZone then
                local character = LocalPlayer.Character
                if character and character:FindFirstChild("HumanoidRootPart") then
                    teleportTo(portalPosition)
                    notify("Event", "Retéléportation au portail d'événement", 2)
                end
            end
            
            -- Gestion de la collecte automatique des coffres
            if autoTakeChestActive and isInEventZone then
                collectNearbyChests()
            end
        end
    end)
    
    notify("PS99 Mobile Pro", "Interface chargée avec succès!", 3)
end
-- Tentative de charger RayField UI
local function loadRayField()
    notify("PS99 Mobile Pro", "Tentative de chargement de l'interface RayField...", 2)
    
    local success, result
    success, result = pcall(function()
        return loadstring(game:HttpGet('https://raw.githubusercontent.com/UI-Interface/CustomFIeld/main/RayField.lua'))()
    end)
    
    if success and result then
        notify("PS99 Mobile Pro", "Interface RayField chargée avec succès", 2)
        return result
    else
        notify("PS99 Mobile Pro", "Échec de chargement de l'interface RayField, utilisation de l'interface de secours", 3)
        useBackupUI = true
        return nil
    end
end

-- Interface principale avec RayField UI
local function createMainInterface()
    if useBackupUI then
        createBackupMainUI()
        return
    end
    
    local Rayfield = loadRayField()
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
            Invite = "",
            RememberJoins = false
        },
        KeySystem = false
    })
    
    -- Onglet Autres
    local AutresTab = Window:CreateTab("Autres", 4483362458)
    
    -- Anti-AFK Toggle
    local antiAfkEnabled = false
    local toggleAfk = setupAntiAfk()
    
    AutresTab:CreateToggle({
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
        end
    })
    
    -- Notifications Toggle
    AutresTab:CreateToggle({
        Name = "Notifications",
        CurrentValue = showNotifications,
        Flag = "Notifications",
        Callback = function(Value)
            showNotifications = Value
            
            if showNotifications then
                notify("Notifications", "Notifications activées", 2)
            end
        end
    })
    
    -- Onglet Event
    local EventTab = Window:CreateTab("Event actuelle", 4483345998)
    
    -- Auto TP to Event Toggle
    EventTab:CreateToggle({
        Name = "Auto TP to Event",
        CurrentValue = autoTpEventActive,
        Flag = "AutoTpEvent",
        Callback = function(Value)
            autoTpEventActive = Value
            
            if autoTpEventActive and not isInEventZone then
                local character = LocalPlayer.Character
                if character and character:FindFirstChild("HumanoidRootPart") then
                    teleportTo(portalPosition)
                    notify("Event", "Téléportation au portail d'événement", 2)
                else
                    notify("Erreur", "Personnage non disponible pour la téléportation", 2)
                end
            elseif autoTpEventActive and isInEventZone then
                notify("Event", "Vous êtes déjà dans la zone d'événement", 2)
            else
                notify("Event", "Auto TP désactivé", 2)
            end
        end
    })
    
    -- Auto Take Chest Toggle
    EventTab:CreateToggle({
        Name = "Auto Take Chest",
        CurrentValue = autoTakeChestActive,
        Flag = "AutoChest",
        Callback = function(Value)
            autoTakeChestActive = Value
            
            if autoTakeChestActive then
                if isInEventZone then
                    notify("Auto Chest", "Collection des coffres activée", 2)
                    collectNearbyChests()  -- Collecter immédiatement
                else
                    notify("Auto Chest", "Vous devez être dans la zone d'événement", 2)
                end
            else
                notify("Auto Chest", "Collection des coffres désactivée", 2)
            end
        end
    })
    
    -- Onglet Farm (vide pour l'instant)
    local FarmTab = Window:CreateTab("Farm", 4483345998)
    
    FarmTab:CreateSection("À venir")
    
    FarmTab:CreateLabel("Les fonctionnalités de farm seront disponibles prochainement...")
    
    -- Onglet Options
    local OptionsTab = Window:CreateTab("Options", 4483345998)
    
    OptionsTab:CreateSection("À propos")
    
    OptionsTab:CreateLabel("PS99 Mobile Pro v1.1")
    OptionsTab:CreateLabel("Développé par zekyu")
    
    OptionsTab:CreateButton({
        Name = "Fermer l'interface",
        Callback = function()
            Rayfield:Destroy()
        end
    })
    
    -- Configuration de la boucle pour vérifier l'état de la zone et collecter les coffres
    task.spawn(function()
        while wait(1) do
            -- Vérifier si l'interface existe toujours
            if not Rayfield or not Window then break end
            
            -- Vérifier périodiquement si le joueur est dans la zone d'événement
            isInEventZone = checkIfInEventZone()
            
            -- Gestion de l'auto téléportation si activée et que le joueur n'est pas dans la zone
            if autoTpEventActive and not isInEventZone then
                local character = LocalPlayer.Character
                if character and character:FindFirstChild("HumanoidRootPart") then
                    teleportTo(portalPosition)
                    notify("Event", "Retéléportation au portail d'événement", 2)
                end
            end
            
            -- Gestion de la collecte automatique des coffres
            if autoTakeChestActive and isInEventZone then
                collectNearbyChests()
            end
        end
    end)
    
    notify("PS99 Mobile Pro", "Interface RayField chargée avec succès!", 3)
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
        -- Nettoyer les espaces éventuels et vérifier en ignorant la casse
        local enteredKey = keyInput.Text:gsub("%s+", ""):lower() 
        local correctKeyLower = correctKey:lower()
        
        -- Vérification directe avec la clé correcte
        if enteredKey == correctKeyLower then
            -- Animation de succès
            validateButton.BackgroundColor3 = Color3.fromRGB(70, 180, 70)
            validateButton.Text = "CLÉ VALIDE!"
            
            -- Notification de succès
            notify("Succès!", "Authentification réussie!", 2)
            
            -- Attendre un peu avant de fermer l'interface de clé
            wait(1)
            keyGui:Destroy()
            
            -- Charger l'interface principale
            createMainInterface()
        else
            -- Animation d'échec
            validateButton.BackgroundColor3 = Color3.fromRGB(180, 70, 70)
            validateButton.Text = "CLÉ INVALIDE!"
            
            -- Notification d'erreur sans afficher la clé
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
            
            -- Réinitialiser le bouton après un délai
            wait(1)
            validateButton.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
            validateButton.Text = "VALIDER LA CLÉ"
        end
    end)
    
    return keyGui
end

-- Interface de clé avec RayField
local function createKeyUI()
    notify("PS99 Mobile Pro", "Création de l'interface de clé...", 2)

    -- Vérifier d'abord si on doit utiliser l'interface de secours
    if useBackupUI then
        return createBackupKeyUI()
    end
    
    local Rayfield = loadRayField()
    if not Rayfield then
        -- Si RayField ne charge pas, créer une interface de clé de secours
        return createBackupKeyUI()
    else
        -- Utiliser RayField pour l'interface de clé
        local Window = Rayfield:CreateWindow({
            Name = "PS99 Mobile Pro",
            LoadingTitle = "PS99 Mobile Pro - Système d'authentification",
            LoadingSubtitle = "par zekyu",
            ConfigurationSaving = {
                Enabled = false,
                FolderName = nil,
                FileName = nil
            },
            Discord = {
                Enabled = false,
                Invite = "",
                RememberJoins = false
            },
            KeySystem = true,
            KeySettings = {
                Title = "PS99 Mobile Pro - Authentification",
                Subtitle = "Entrez votre clé d'activation",
                Note = "La clé vous a été fournie par le développeur",
                FileName = "PS99Key",
                SaveKey = false,
                GrabKeyFromSite = false,
                Key = correctKey  -- Utiliser correctKey directement
            }
        })
        
        -- Vérifier si la fenêtre a été créée avec succès
        if Window then
            -- Créer un onglet temporaire pour le chargement
            local LoadingTab = Window:CreateTab("Chargement...", 4483345998)
            LoadingTab:CreateLabel("Authentification réussie!")
            LoadingTab:CreateLabel("Chargement de l'interface principale...")
            
            -- Attendre un moment avant de charger l'interface principale
            task.spawn(function()
                wait(1)
                Rayfield:Destroy() -- Fermer cette fenêtre
                
                -- Charger l'interface principale
                createMainInterface()
            end)
        else
            -- Si la création de la fenêtre échoue, revenir à l'interface de secours
            useBackupUI = true
            return createBackupKeyUI()
        end
    end
end

-- Démarrage de l'application
pcall(function()
    notify("PS99 Mobile Pro", "Démarrage de l'application...", 3)
    wait(1)

    local keyUISuccess, keyUI = pcall(createKeyUI)
    
    if not keyUISuccess then
        notify("Erreur Critique", "Impossible de créer l'interface de saisie de clé", 5)
        useBackupUI = true
        wait(1)
        createBackupMainUI()
    end
end)
