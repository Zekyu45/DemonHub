-- Script PS99 Mobile Pro - Version corrigée avec UI fonctionnelle

-- Système de clé d'authentification
local keySystem = true
local correctKey = "zekyu"

-- Fonction principale pour charger le script
function loadScript()
    -- Variables principales
    local autoTpEventActive = false
    local showNotifications = true
    local autoTpEventCoroutine
    
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

    -- Fonction notification améliorée
    local function notify(title, text, duration)
        if not showNotifications then return end
        pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = title, 
                Text = text, 
                Duration = duration or 2,
                Icon = "rbxassetid://4483345998", -- Icône par défaut
                Button1 = "OK"
            })
        end)
    end
    
    -- Fonction Anti-AFK
    local function setupAntiAfk()
        local connection
        local VirtualUser = game:GetService("VirtualUser")
        
        -- Fonction pour activer/désactiver l'anti-AFK
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
    
    -- Fonction de téléportation améliorée
    local function teleportTo(position)
        local character = LocalPlayer.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then 
            notify("Erreur", "Impossible de téléporter - personnage non trouvé", 2)
            return false 
        end
        
        -- Téléportation avec position légèrement plus haute et gestion des erreurs
        local safePosition = Vector3.new(position.X, position.Y + 5, position.Z)
        local success = pcall(function()
            character:SetPrimaryPartCFrame(CFrame.new(safePosition))
            wait(0.5)
            character:SetPrimaryPartCFrame(CFrame.new(position))
            
            -- Stabiliser après la téléportation
            character.HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
            character.HumanoidRootPart.RotVelocity = Vector3.new(0, 0, 0)
        end)
        
        if not success then
            -- Méthode alternative si la première échoue
            pcall(function()
                character.HumanoidRootPart.CFrame = CFrame.new(position)
            end)
        end
        
        return true
    end
    
    -- Création de l'interface utilisateur personnalisée
    local function createCustomUI()
        -- Supprimer l'ancienne interface si elle existe
        if game:GetService("CoreGui"):FindFirstChild("PS99MobileProUI") then
            game:GetService("CoreGui"):FindFirstChild("PS99MobileProUI"):Destroy()
        end
        
        -- Création de l'interface principale
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
        
        -- Frame principale
        local MainFrame = Instance.new("Frame")
        MainFrame.Name = "MainFrame"
        MainFrame.Size = UDim2.new(0, 250, 0, 300)
        MainFrame.Position = UDim2.new(0.8, 0, 0.5, -150)
        MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
        MainFrame.BorderSizePixel = 0
        MainFrame.Parent = ScreenGui
        
        -- Ajouter un coin arrondi
        local UICorner = Instance.new("UICorner")
        UICorner.CornerRadius = UDim.new(0, 10)
        UICorner.Parent = MainFrame
        
        -- Barre de titre
        local TitleBar = Instance.new("Frame")
        TitleBar.Name = "TitleBar"
        TitleBar.Size = UDim2.new(1, 0, 0, 30)
        TitleBar.BackgroundColor3 = Color3.fromRGB(40, 40, 70)
        TitleBar.BorderSizePixel = 0
        TitleBar.Parent = MainFrame
        
        local TitleCorner = Instance.new("UICorner")
        TitleCorner.CornerRadius = UDim.new(0, 10)
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
        Title.TextSize = 16
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
        CloseButton.TextSize = 14
        CloseButton.Parent = TitleBar
        
        local CloseCorner = Instance.new("UICorner")
        CloseCorner.CornerRadius = UDim.new(0, 10)
        CloseCorner.Parent = CloseButton
        
        -- Fonction pour fermer l'interface
        CloseButton.MouseButton1Click:Connect(function()
            ScreenGui:Destroy()
        end)
        
        -- Rendre la fenêtre déplaçable
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
        
        -- Conteneur d'onglets
        local TabContainer = Instance.new("Frame")
        TabContainer.Name = "TabContainer"
        TabContainer.Size = UDim2.new(1, 0, 0, 30)
        TabContainer.Position = UDim2.new(0, 0, 0, 30)
        TabContainer.BackgroundColor3 = Color3.fromRGB(50, 50, 80)
        TabContainer.BorderSizePixel = 0
        TabContainer.Parent = MainFrame
        -- Conteneur de contenu
        local ContentContainer = Instance.new("Frame")
        ContentContainer.Name = "ContentContainer"
        ContentContainer.Size = UDim2.new(1, 0, 1, -60)
        ContentContainer.Position = UDim2.new(0, 0, 0, 60)
        ContentContainer.BackgroundColor3 = Color3.fromRGB(35, 35, 60)
        ContentContainer.BorderSizePixel = 0
        ContentContainer.Parent = MainFrame
        
        -- Fonction pour créer les onglets et leur contenu
        local tabs = {}
        local selectedTab = nil
        
        local function createTab(name)
            -- Créer le bouton d'onglet
            local tabButton = Instance.new("TextButton")
            tabButton.Name = name .. "Tab"
            tabButton.Size = UDim2.new(1/#tabs+1, 0, 1, 0)
            tabButton.BackgroundTransparency = 0.5
            tabButton.BackgroundColor3 = Color3.fromRGB(50, 50, 80)
            tabButton.BorderSizePixel = 0
            tabButton.Font = Enum.Font.Gotham
            tabButton.Text = name
            tabButton.TextColor3 = Color3.fromRGB(200, 200, 200)
            tabButton.TextSize = 14
            tabButton.Parent = TabContainer
            
            -- Créer le contenu de l'onglet
            local tabContent = Instance.new("ScrollingFrame")
            tabContent.Name = name .. "Content"
            tabContent.Size = UDim2.new(1, 0, 1, 0)
            tabContent.BackgroundTransparency = 1
            tabContent.BorderSizePixel = 0
            tabContent.ScrollBarThickness = 4
            tabContent.Visible = false
            tabContent.Parent = ContentContainer
            
            -- Gestionnaire d'éléments d'interface
            local layoutOrder = 0
            local elementPadding = 10
            
            -- Configurer le layout pour les éléments
            local UIListLayout = Instance.new("UIListLayout")
            UIListLayout.Padding = UDim.new(0, elementPadding)
            UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
            UIListLayout.Parent = tabContent
            
            local UIPadding = Instance.new("UIPadding")
            UIPadding.PaddingLeft = UDim.new(0, 10)
            UIPadding.PaddingRight = UDim.new(0, 10)
            UIPadding.PaddingTop = UDim.new(0, 10)
            UIPadding.PaddingBottom = UDim.new(0, 10)
            UIPadding.Parent = tabContent
            
            -- Adapter la taille en fonction du contenu
            UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                tabContent.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + elementPadding)
            end)
            
            -- Bouton d'onglet cliqué
            tabButton.MouseButton1Click:Connect(function()
                -- Masquer tous les onglets et réinitialiser les couleurs
                for _, tab in pairs(tabs) do
                    tab.Content.Visible = false
                    tab.Button.BackgroundColor3 = Color3.fromRGB(50, 50, 80)
                    tab.Button.TextColor3 = Color3.fromRGB(200, 200, 200)
                end
                
                -- Afficher l'onglet sélectionné
                tabContent.Visible = true
                tabButton.BackgroundColor3 = Color3.fromRGB(70, 70, 120)
                tabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
                selectedTab = name
            end)
            
            -- Créer une section dans l'onglet
            local function createSection(sectionName)
                layoutOrder = layoutOrder + 1
                
                -- Titre de la section
                local sectionTitle = Instance.new("TextLabel")
                sectionTitle.Name = sectionName .. "Title"
                sectionTitle.Size = UDim2.new(1, 0, 0, 25)
                sectionTitle.BackgroundTransparency = 1
                sectionTitle.Font = Enum.Font.GothamSemibold
                sectionTitle.Text = sectionName
                sectionTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
                sectionTitle.TextSize = 14
                sectionTitle.TextXAlignment = Enum.TextXAlignment.Left
                sectionTitle.LayoutOrder = layoutOrder
                sectionTitle.Parent = tabContent
                
                -- Ligne de séparation
                layoutOrder = layoutOrder + 1
                local separator = Instance.new("Frame")
                separator.Name = "Separator"
                separator.Size = UDim2.new(1, 0, 0, 1)
                separator.BackgroundColor3 = Color3.fromRGB(100, 100, 150)
                separator.BorderSizePixel = 0
                separator.LayoutOrder = layoutOrder
                separator.Parent = tabContent
                
                -- Méthodes pour ajouter des éléments
                local section = {}
                
                -- Ajouter un toggle
                function section:AddToggle(toggleName, callback)
                    layoutOrder = layoutOrder + 1
                    
                    local toggleFrame = Instance.new("Frame")
                    toggleFrame.Name = toggleName .. "Frame"
                    toggleFrame.Size = UDim2.new(1, 0, 0, 30)
                    toggleFrame.BackgroundTransparency = 1
                    toggleFrame.LayoutOrder = layoutOrder
                    toggleFrame.Parent = tabContent
                    
                    local toggleLabel = Instance.new("TextLabel")
                    toggleLabel.Name = "Label"
                    toggleLabel.Size = UDim2.new(0.7, 0, 1, 0)
                    toggleLabel.Position = UDim2.new(0, 0, 0, 0)
                    toggleLabel.BackgroundTransparency = 1
                    toggleLabel.Font = Enum.Font.Gotham
                    toggleLabel.Text = toggleName
                    toggleLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
                    toggleLabel.TextSize = 14
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
                    
                    -- État du toggle
                    local toggled = false
                    
                    -- Fonction pour mettre à jour l'apparence
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
                    
                    -- Gérer le clic
                    toggleButton.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                            toggled = not toggled
                            updateToggle()
                            if callback then
                                callback(toggled)
                            end
                        end
                    end)
                    
                    -- Rendre l'ensemble du frame cliquable
                    toggleFrame.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                            toggled = not toggled
                            updateToggle()
                            if callback then
                                callback(toggled)
                            end
                        end
                    end)
                    
                    -- Méthode pour définir l'état
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
                
                -- Ajouter un bouton
                function section:AddButton(buttonName, callback)
                    layoutOrder = layoutOrder + 1
                    
                    local buttonFrame = Instance.new("Frame")
                    buttonFrame.Name = buttonName .. "Frame"
                    buttonFrame.Size = UDim2.new(1, 0, 0, 30)
                    buttonFrame.BackgroundTransparency = 1
                    buttonFrame.LayoutOrder = layoutOrder
                    buttonFrame.Parent = tabContent
                    
                    local button = Instance.new("TextButton")
                    button.Name = "Button"
                    button.Size = UDim2.new(1, 0, 1, 0)
                    button.BackgroundColor3 = Color3.fromRGB(60, 60, 100)
                    button.BorderSizePixel = 0
                    button.Font = Enum.Font.Gotham
                    button.Text = buttonName
                    button.TextColor3 = Color3.fromRGB(255, 255, 255)
                    button.TextSize = 14
                    button.Parent = buttonFrame
                    
                    local buttonCorner = Instance.new("UICorner")
                    buttonCorner.CornerRadius = UDim.new(0, 5)
                    buttonCorner.Parent = button
                    
                    -- Effet au survol
                    button.MouseEnter:Connect(function()
                        button.BackgroundColor3 = Color3.fromRGB(80, 80, 130)
                    end)
                    
                    button.MouseLeave:Connect(function()
                        button.BackgroundColor3 = Color3.fromRGB(60, 60, 100)
                    end)
                    
                    -- Effet au clic
                    button.MouseButton1Down:Connect(function()
                        button.BackgroundColor3 = Color3.fromRGB(40, 40, 80)
                    end)
                    
                    button.MouseButton1Up:Connect(function()
                        button.BackgroundColor3 = Color3.fromRGB(80, 80, 130)
                    end)
                    
                    -- Gérer le clic
                    button.MouseButton1Click:Connect(function()
                        if callback then
                            callback()
                        end
                    end)
                end
                
                return section
            end
            
            -- Ajouter l'onglet à la liste
            table.insert(tabs, {
                Name = name,
                Button = tabButton,
                Content = tabContent,
                CreateSection = createSection
            })
            
            -- Repositionner les boutons d'onglet
            for i, tab in ipairs(tabs) do
                tab.Button.Size = UDim2.new(1/#tabs, 0, 1, 0)
                tab.Button.Position = UDim2.new((i-1)/#tabs, 0, 0, 0)
            end
            
            return {
                Content = tabContent,
                CreateSection = createSection
            }
        end
        
        -- Créer les onglets de l'interface
        local mainTab = createTab("Principal")
        local eventTab = createTab("Événements")
        local optionsTab = createTab("Options")
        
        -- Activer le premier onglet par défaut
        tabs[1].Button.BackgroundColor3 = Color3.fromRGB(70, 70, 120)
        tabs[1].Button.TextColor3 = Color3.fromRGB(255, 255, 255)
        tabs[1].Content.Visible = true
        selectedTab = tabs[1].Name
        
        -- Créer les sections et ajouter les fonctionnalités
        local mainSection = mainTab.CreateSection("Fonctionnalités")
        local eventSection = eventTab.CreateSection("Événements actuels")
        local optionsSection = optionsTab.CreateSection("Paramètres")
        
        -- Créer la fonction anti-AFK
        local toggleAfk = setupAntiAfk()
        
        -- Ajouter le toggle Anti-AFK
        mainSection:AddToggle("Anti-AFK", function(state)
            toggleAfk(state)
        end)
        
        -- Auto Téléport à l'événement
        local autoTpToggle = eventSection:AddToggle("Auto TP Event", function(state)
            autoTpEventActive = state
            
            -- Arrêter la coroutine si elle existe
            if autoTpEventCoroutine then
                pcall(function() 
                    coroutine.close(autoTpEventCoroutine)
                    autoTpEventCoroutine = nil
                end)
            end
            
            -- Démarrer une nouvelle coroutine si activé
            if state then
                autoTpEventCoroutine = coroutine.create(function()
                    while autoTpEventActive do
                        local character = LocalPlayer.Character
                        if character and character:FindFirstChild("HumanoidRootPart") then
                            -- Éviter les téléportations trop fréquentes
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
                
                -- Démarrer la coroutine
                coroutine.resume(autoTpEventCoroutine)
                notify("Event", "Auto TP Event activé", 2)
            else
                notify("Event", "Auto TP Event désactivé", 2)
            end
        end)
        
        -- Toggle pour les notifications
        optionsSection:AddToggle("Notifications", function(state)
            showNotifications = state
            if state then
                notify("Notifications", "Notifications activées", 2)
            end
        end):SetState(true)
        
        -- Bouton pour fermer l'interface
        optionsSection:AddButton("Fermer l'interface", function()
            ScreenGui:Destroy()
        end)
        
        -- Bouton pour téléporter manuellement
        eventSection:AddButton("TP au portail", function()
            teleportTo(portalPosition)
            notify("Event", "Téléportation au portail d'événement", 2)
        end)
        
        return ScreenGui
    end

    -- Charger l'interface
    local ui = createCustomUI()
    
    -- Message de confirmation final
    notify("Succès", "Script PS99 Mobile Pro chargé avec succès!", 3)
    return true
end

-- Fonction pour l'interface de saisie de clé
function createKeyUI()
    -- Suppression des anciennes interfaces
    pcall(function()
        for _, gui in pairs(game:GetService("Players").LocalPlayer.PlayerGui:GetChildren()) do
            if gui.Name == "KeyUI" then gui:Destroy() end
        end
        
        if game:GetService("CoreGui"):FindFirstChild("KeyUI") then
            game:GetService("CoreGui"):FindFirstChild("KeyUI"):Destroy()
        end
    end)
    
    -- Création d'une nouvelle interface GUI
    local KeyUI = Instance.new("ScreenGui")
    KeyUI.Name = "KeyUI"
    KeyUI.ResetOnSpawn = false
    KeyUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    KeyUI.DisplayOrder = 999
    
    -- Essayer de contourner les restrictions de CoreGui
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

    local KeyInput.Name = "KeyInput"
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
    
    -- Effet de survol pour le bouton
    SubmitButton.MouseEnter:Connect(function()
        SubmitButton.BackgroundColor3 = Color3.fromRGB(0, 140, 240)
    end)
    
    SubmitButton.MouseLeave:Connect(function()
        SubmitButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
    end)
    
    -- Fonction de vérification de clé
    SubmitButton.MouseButton1Click:Connect(function()
        if KeyInput.Text == correctKey then
            StatusLabel.Text = "Clé valide! Chargement..."
            StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
            
            -- Créer un effet visuel de chargement
            for i = 1, 3 do
                wait(0.3)
                StatusLabel.Text = StatusLabel.Text .. "."
            end
            
            wait(0.5)
            KeyUI:Destroy()
            
            -- Protection contre les erreurs lors du chargement
            local success, errorMsg = pcall(loadScript)
            if not success then
                -- Recréer l'interface en cas d'échec
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
    
    -- Permettre aussi de valider avec la touche Entrée
    KeyInput.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            SubmitButton.MouseButton1Click:Fire()
        end
    end)
    
    return KeyUI
end

-- Démarrage avec système de clé
if keySystem then
    createKeyUI()
else
    loadScript()
end
