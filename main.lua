-- Script PS99 Mobile Pro - UI Simplifié

-- Variables principales
local autoTpEventActive = false
local showNotifications = true
local autoTpEventCoroutine
local correctKey = "zekyu"

-- Services
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- Position du portail pour aller à l'événement
local portalPosition = Vector3.new(174.04, 16.96, -141.07)
local lastPortalTpTime = 0
local portalTpCooldown = 5 -- 5 secondes entre les téléportations

-- Fonction notification
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

-- Création de l'UI
local function createUI()
    -- Supprimer l'ancienne interface si elle existe
    if game:GetService("CoreGui"):FindFirstChild("PS99MobileProUI") then
        game:GetService("CoreGui"):FindFirstChild("PS99MobileProUI"):Destroy()
    end
    
    -- Interface principale
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "PS99MobileProUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Contournement de la protection CoreGui
    pcall(function()
        ScreenGui.Parent = game:GetService("CoreGui")
    end)
    
    if not ScreenGui.Parent then
        ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
    
    -- Frame principale - MODIFIÉE POUR ÊTRE RECTANGULAIRE ET CENTRÉE
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 300, 0, 220) -- Taille rectangulaire
    MainFrame.Position = UDim2.new(0.5, -150, 0.5, -110) -- Centrée sur l'écran
    MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui
    
    -- Coins arrondis
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 8)
    UICorner.Parent = MainFrame
    
    -- Barre de titre
    local TitleBar = Instance.new("Frame")
    TitleBar.Name = "TitleBar"
    TitleBar.Size = UDim2.new(1, 0, 0, 30)
    TitleBar.BackgroundColor3 = Color3.fromRGB(40, 40, 70)
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = MainFrame
    
    local TitleCorner = Instance.new("UICorner")
    TitleCorner.CornerRadius = UDim.new(0, 8)
    TitleCorner.Parent = TitleBar
    
    -- Titre
    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Size = UDim2.new(1, -30, 1, 0)
    Title.Position = UDim2.new(0, 10, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Font = Enum.Font.GothamBold
    Title.Text = "PS99 Mobile Pro"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 14
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = TitleBar
    
    -- Bouton de fermeture
    local CloseButton = Instance.new("TextButton")
    CloseButton.Name = "CloseButton"
    CloseButton.Size = UDim2.new(0, 20, 0, 20)
    CloseButton.Position = UDim2.new(1, -25, 0, 5)
    CloseButton.BackgroundColor3 = Color3.fromRGB(255, 70, 70)
    CloseButton.BorderSizePixel = 0
    CloseButton.Font = Enum.Font.GothamBold
    CloseButton.Text = "X"
    CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseButton.TextSize = 12
    CloseButton.Parent = TitleBar
    
    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(0, 10)
    CloseCorner.Parent = CloseButton
    
    -- Fermeture de l'interface
    CloseButton.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
    end)
    
    -- Drag functionality
    local dragging = false
    local dragInput
    local dragStart
    local startPos
    
    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
        end
    end)
    
    TitleBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            dragInput = input
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    -- Conteneur principal
    local ContentFrame = Instance.new("Frame")
    ContentFrame.Name = "ContentFrame"
    ContentFrame.Size = UDim2.new(1, -20, 1, -40)
    ContentFrame.Position = UDim2.new(0, 10, 0, 35)
    ContentFrame.BackgroundTransparency = 1
    ContentFrame.Parent = MainFrame
    
    -- Layout pour organiser les éléments
    local ListLayout = Instance.new("UIListLayout")
    ListLayout.Padding = UDim.new(0, 10)
    ListLayout.Parent = ContentFrame
    -- Section fonctions principales
    local function createSection(title)
        local section = Instance.new("Frame")
        section.Name = title .. "Section"
        section.Size = UDim2.new(1, 0, 0, 20)
        section.BackgroundTransparency = 1
        section.Parent = ContentFrame
        
        local sectionTitle = Instance.new("TextLabel")
        sectionTitle.Name = "Title"
        sectionTitle.Size = UDim2.new(1, 0, 0, 20)
        sectionTitle.BackgroundTransparency = 1
        sectionTitle.Font = Enum.Font.GothamSemibold
        sectionTitle.Text = title
        sectionTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
        sectionTitle.TextSize = 12
        sectionTitle.TextXAlignment = Enum.TextXAlignment.Left
        sectionTitle.Parent = section
        
        local separator = Instance.new("Frame")
        separator.Name = "Separator"
        separator.Size = UDim2.new(1, 0, 0, 1)
        separator.Position = UDim2.new(0, 0, 1, 0)
        separator.BackgroundColor3 = Color3.fromRGB(100, 100, 150)
        separator.BorderSizePixel = 0
        separator.Parent = sectionTitle
        
        return section
    end
    
    -- Créer un toggle
    local function createToggle(parent, text, callback)
        local toggleFrame = Instance.new("Frame")
        toggleFrame.Name = text .. "Toggle"
        toggleFrame.Size = UDim2.new(1, 0, 0, 30)
        toggleFrame.BackgroundTransparency = 1
        toggleFrame.Parent = parent
        
        local toggleLabel = Instance.new("TextLabel")
        toggleLabel.Name = "Label"
        toggleLabel.Size = UDim2.new(0.7, 0, 1, 0)
        toggleLabel.BackgroundTransparency = 1
        toggleLabel.Font = Enum.Font.Gotham
        toggleLabel.Text = text
        toggleLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
        toggleLabel.TextSize = 12
        toggleLabel.TextXAlignment = Enum.TextXAlignment.Left
        toggleLabel.Parent = toggleFrame
        
        local toggleButton = Instance.new("Frame")
        toggleButton.Name = "Button"
        toggleButton.Size = UDim2.new(0, 40, 0, 20)
        toggleButton.Position = UDim2.new(1, -40, 0.5, -10)
        toggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 90)
        toggleButton.BorderSizePixel = 0
        toggleButton.Parent = toggleFrame
        
        local toggleCorner = Instance.new("UICorner")
        toggleCorner.CornerRadius = UDim.new(0, 10)
        toggleCorner.Parent = toggleButton
        
        local toggleIndicator = Instance.new("Frame")
        toggleIndicator.Name = "Indicator"
        toggleIndicator.Size = UDim2.new(0, 16, 0, 16)
        toggleIndicator.Position = UDim2.new(0, 2, 0.5, -8)
        toggleIndicator.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
        toggleIndicator.BorderSizePixel = 0
        toggleIndicator.Parent = toggleButton
        
        local indicatorCorner = Instance.new("UICorner")
        indicatorCorner.CornerRadius = UDim.new(1, 0)
        indicatorCorner.Parent = toggleIndicator
        
        local toggled = false
        
        local function updateToggle()
            if toggled then
                toggleButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
                local goal = {}
                goal.Position = UDim2.new(1, -18, 0.5, -8)
                
                local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                local tween = TweenService:Create(toggleIndicator, tweenInfo, goal)
                tween:Play()
            else
                toggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 90)
                local goal = {}
                goal.Position = UDim2.new(0, 2, 0.5, -8)
                
                local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                local tween = TweenService:Create(toggleIndicator, tweenInfo, goal)
                tween:Play()
            end
        end
        
        toggleButton.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                toggled = not toggled
                updateToggle()
                if callback then
                    callback(toggled)
                end
            end
        end)
        
        toggleFrame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                toggled = not toggled
                updateToggle()
                if callback then
                    callback(toggled)
                end
            end
        end)
        
        local toggle = {}
        function toggle:SetState(state)
            toggled = state
            updateToggle()
            if callback then
                callback(toggled)
            end
        end
        
        return toggle
    end
    
    -- Créer un bouton
    local function createButton(parent, text, callback)
        local buttonFrame = Instance.new("Frame")
        buttonFrame.Name = text .. "Frame"
        buttonFrame.Size = UDim2.new(1, 0, 0, 30)
        buttonFrame.BackgroundTransparency = 1
        buttonFrame.Parent = parent
        
        local button = Instance.new("TextButton")
        button.Name = "Button"
        button.Size = UDim2.new(1, 0, 1, 0)
        button.BackgroundColor3 = Color3.fromRGB(60, 60, 100)
        button.BorderSizePixel = 0
        button.Font = Enum.Font.Gotham
        button.Text = text
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.TextSize = 12
        button.Parent = buttonFrame
        
        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 5)
        buttonCorner.Parent = button
        
        button.MouseEnter:Connect(function()
            button.BackgroundColor3 = Color3.fromRGB(80, 80, 130)
        end)
        
        button.MouseLeave:Connect(function()
            button.BackgroundColor3 = Color3.fromRGB(60, 60, 100)
        end)
        
        button.MouseButton1Down:Connect(function()
            button.BackgroundColor3 = Color3.fromRGB(40, 40, 80)
        end)
        
        button.MouseButton1Up:Connect(function()
            button.BackgroundColor3 = Color3.fromRGB(80, 80, 130)
        end)
        
        button.MouseButton1Click:Connect(function()
            if callback then
                callback()
            end
        end)
    end
    
    -- Créer les sections
    local mainSection = createSection("Fonctionnalités")
    local eventSection = createSection("Événements")
    local optionsSection = createSection("Options")
    
    -- Setup Anti-AFK
    local toggleAfk = setupAntiAfk()
    
    -- Ajouter le toggle Anti-AFK
    createToggle(mainSection, "Anti-AFK", function(state)
        toggleAfk(state)
    end)
    
    -- TP Event toggle - MODIFIÉ POUR ÊTRE UN TOGGLE PLUTÔT QU'UN BOUTON
    createToggle(eventSection, "TP to Event", function(state)
        autoTpEventActive = state
        
        if autoTpEventCoroutine then
            pcall(function() 
                coroutine.close(autoTpEventCoroutine)
                autoTpEventCoroutine = nil
            end)
        end
        
        if state then
            autoTpEventCoroutine = coroutine.create(function()
                while autoTpEventActive do
                    local character = LocalPlayer.Character
                    if character and character:FindFirstChild("HumanoidRootPart") then
                        local currentTime = tick()
                        if currentTime - lastPortalTpTime >= portalTpCooldown then
                            teleportTo(portalPosition)
                            lastPortalTpTime = currentTime
                            notify("Event", "Téléportation au portail d'événement", 2)
                        end
                    end
                    wait(1)
                end
            end)
            
            coroutine.resume(autoTpEventCoroutine)
            notify("Event", "TP to Event activé", 2)
        else
            notify("Event", "TP to Event désactivé", 2)
        end
    end)
    
    -- Toggle pour les notifications
    createToggle(optionsSection, "Notifications", function(state)
        showNotifications = state
        if state then
            notify("Notifications", "Notifications activées", 2)
        end
    end)
    
    -- Bouton pour fermer l'interface
    createButton(optionsSection, "Fermer", function()
        ScreenGui:Destroy()
    end)
    
    return ScreenGui
end

-- Interface de saisie de clé
local function createKeyUI()
    -- Suppression des anciennes interfaces
    pcall(function()
        for _, gui in pairs(game:GetService("Players").LocalPlayer.PlayerGui:GetChildren()) do
            if gui.Name == "KeyUI" then gui:Destroy() end
        end
        
        if game:GetService("CoreGui"):FindFirstChild("KeyUI") then
            game:GetService("CoreGui"):FindFirstChild("KeyUI"):Destroy()
        end
    end)
    
    -- Création de l'interface GUI
    local KeyUI = Instance.new("ScreenGui")
    KeyUI.Name = "KeyUI"
    KeyUI.ResetOnSpawn = false
    KeyUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    KeyUI.DisplayOrder = 999
    
    pcall(function()
        KeyUI.Parent = game:GetService("CoreGui")
    end)
    
    if not KeyUI.Parent then
        KeyUI.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    end
        
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Parent = KeyUI
    MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
    MainFrame.BorderSizePixel = 2
    MainFrame.BorderColor3 = Color3.fromRGB(0, 150, 255)
    MainFrame.Position = UDim2.new(0.5, -150, 0.5, -100)
    MainFrame.Size = UDim2.new(0, 300, 0, 200)
    MainFrame.Active = true
    MainFrame.Draggable = true
    
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 8)
    UICorner.Parent = MainFrame

    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Parent = MainFrame
    Title.BackgroundColor3 = Color3.fromRGB(20, 20, 40)
    Title.BorderSizePixel = 0
    Title.Size = UDim2.new(1, 0, 0, 30)
    Title.Font = Enum.Font.GothamBold
    Title.Text = "PS99 Mobile Pro - Authentification"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 18
    
    local UICornerTitle = Instance.new("UICorner")
    UICornerTitle.CornerRadius = UDim.new(0, 8)
    UICornerTitle.Parent = Title
    
    local KeyLabel = Instance.new("TextLabel")
    KeyLabel.Name = "KeyLabel"
    KeyLabel.Parent = MainFrame
    KeyLabel.BackgroundTransparency = 1
    KeyLabel.Position = UDim2.new(0.1, 0, 0.17, 0)
    KeyLabel.Size = UDim2.new(0.8, 0, 0, 30)
    KeyLabel.Font = Enum.Font.GothamBold
    KeyLabel.Text = "La clé est: zekyu"
    KeyLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    KeyLabel.TextSize = 16

    local KeyInput = Instance.new("TextBox")
    KeyInput.Name = "KeyInput"
    KeyInput.Parent = MainFrame
    KeyInput.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    KeyInput.BorderSizePixel = 1
    KeyInput.Position = UDim2.new(0.1, 0, 0.4, 0)
    KeyInput.Size = UDim2.new(0.8, 0, 0, 40)
    KeyInput.Font = Enum.Font.Gotham
    KeyInput.PlaceholderText = "Entrez votre clé ici..."
    KeyInput.Text = correctKey -- Pré-remplir avec la clé correcte
    KeyInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    KeyInput.TextSize = 16
    KeyInput.ClearTextOnFocus = false
    
    local UICornerInput = Instance.new("UICorner")
    UICornerInput.CornerRadius = UDim.new(0, 6)
    UICornerInput.Parent = KeyInput

    local SubmitButton = Instance.new("TextButton")
    SubmitButton.Name = "SubmitButton"
    SubmitButton.Parent = MainFrame
    SubmitButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
    SubmitButton.BorderSizePixel = 0
    SubmitButton.Position = UDim2.new(0.25, 0, 0.6, 0)
    SubmitButton.Size = UDim2.new(0.5, 0, 0, 40)
    SubmitButton.Font = Enum.Font.GothamBold
    SubmitButton.Text = "Valider"
    SubmitButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    SubmitButton.TextSize = 18
    
    local UICornerButton = Instance.new("UICorner")
    UICornerButton.CornerRadius = UDim.new(0, 6)
    UICornerButton.Parent = SubmitButton

    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Name = "StatusLabel"
    StatusLabel.Parent = MainFrame
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Position = UDim2.new(0, 0, 0.8, 0)
    StatusLabel.Size = UDim2.new(1, 0, 0, 30)
    StatusLabel.Font = Enum.Font.Gotham
    StatusLabel.Text = "Entrez la clé puis cliquez sur Valider"
    StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    StatusLabel.TextSize = 14
    
    SubmitButton.MouseEnter:Connect(function()
        SubmitButton.BackgroundColor3 = Color3.fromRGB(0, 140, 240)
    end)
    
    SubmitButton.MouseLeave:Connect(function()
        SubmitButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
    end)
    
    SubmitButton.MouseButton1Click:Connect(function()
        if KeyInput.Text == correctKey then
            StatusLabel.Text = "Clé valide! Chargement..."
            StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
            
            for i = 1, 3 do
                wait(0.3)
                StatusLabel.Text = StatusLabel.Text .. "."
            end
            
            wait(0.5)
            KeyUI:Destroy()
            
            local success, errorMsg = pcall(createUI)
            if not success then
                wait(1)
                local errorUI = createKeyUI()
                local statusLabel = errorUI.MainFrame.StatusLabel
                statusLabel.Text = "ERREUR: Impossible de charger le script"
                statusLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
                wait(3)
                statusLabel.Text = "Erreur: " .. tostring(errorMsg)
            end
        else
            StatusLabel.Text = "Clé invalide! Essayez à nouveau."
            StatusLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
        end
    end)
    
    KeyInput.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            SubmitButton.MouseButton1Click:Fire()
        end
    end)
    
    return KeyUI
end

-- Démarrage de l'application
createKeyUI()

-- Message de confirmation
notify("PS99 Mobile Pro", "Script chargé avec succès!", 3)
