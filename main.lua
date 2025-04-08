-- Script PS99 simplifié - Version optimisée avec UI, AFK et Auto TP Event

-- Système de clé d'authentification
local keySystem = true
local correctKey = "zekyu"

-- Fonction principale pour charger le script
function loadScript()
    -- Variables principales
    local Library
    local Window
    local autoTpEventActive = false
    local showNotifications = false
    local autoTpEventCoroutine
    
    -- Services
    local Players = game:GetService("Players")
    local StarterGui = game:GetService("StarterGui")
    local LocalPlayer = Players.LocalPlayer
    
    -- Position du portail pour aller à l'événement
    local portalPosition = Vector3.new(174.04, 16.96, -141.07)
    local lastPortalTpTime = 0
    local portalTpCooldown = 5 -- 5 secondes entre les téléportations

    -- Fonction notification simplifiée
    local function notify(title, text, duration)
        if not showNotifications then return end
        pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = title, Text = text, Duration = duration or 2
            })
        end)
    end
    
    -- Chargement de la bibliothèque UI avec gestion d'erreur
    local function loadUILibrary()
        local source = "https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"
        local success, result = pcall(function()
            return loadstring(game:HttpGet(source, true))()
        end)
        
        if success and result then
            notify("UI", "Interface chargée avec succès", 2)
            return result
        end
        
        notify("ERREUR", "Échec du chargement de l'interface", 2)
        return nil
    end
    
    -- Fonction Anti-AFK
    local function antiAfk()
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
    
    -- Fonction de téléportation simplifiée
    local function teleportTo(position)
        local character = LocalPlayer.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then 
            return false 
        end
        
        -- Téléportation avec position légèrement plus haute
        local safePosition = Vector3.new(position.X, position.Y + 5, position.Z)
        pcall(function()
            character.HumanoidRootPart.CFrame = CFrame.new(safePosition)
            wait(0.5)
            character.HumanoidRootPart.CFrame = CFrame.new(position)
            character.HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
        end)
        
        return true
    end

    -- Début du script principal
    Library = loadUILibrary()
    if not Library then
        notify("ERREUR", "Impossible de charger l'interface!", 5)
        return false
    end
    
    -- Création de l'interface
    Window = Library:CreateLib("PS99 Mobile Pro", "Ocean")
    
    -- Créer la fonction anti-AFK qui peut être activée/désactivée
    local toggleAfk = antiAfk()
    
    -- Tab principal
    local MainTab = Window:NewTab("Principal")
    local MainSection = MainTab:NewSection("Fonctionnalités")
    
    -- Toggle Anti-AFK
    MainSection:NewToggle("Anti-AFK", "Empêche d'être déconnecté pour inactivité", function(state)
        toggleAfk(state)
    end)
    
    -- Tab Événements
    local EventTab = Window:NewTab("Événements")
    local EventSection = EventTab:NewSection("Événements actuels")
    
    -- Auto Téléport à l'événement
    EventSection:NewToggle("Auto TP Event", "Téléporte automatiquement au portail de l'événement", function(state)
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

    -- Tab Options
    local OptionsTab = Window:NewTab("Options")
    local OptionsSection = OptionsTab:NewSection("Paramètres")
    
    -- Option pour activer/désactiver les notifications
    OptionsSection:NewToggle("Notifications", "Activer/désactiver les notifications", function(state)
        showNotifications = state
        if state then
            notify("Notifications", "Notifications activées", 2)
        end
    end)
    
    -- Option pour fermer l'interface
    OptionsSection:NewButton("Fermer l'interface", "Ferme l'interface actuelle", function()
        Library:ToggleUI()
    end)
    
    return true
end

-- Fonction pour l'interface de saisie de clé
function createKeyUI()
    -- Suppression des anciennes interfaces
    for _, gui in pairs(game:GetService("Players").LocalPlayer.PlayerGui:GetChildren()) do
        if gui.Name == "KeyUI" then gui:Destroy() end
    end
    
    -- Création d'une nouvelle interface GUI
    local KeyUI = Instance.new("ScreenGui")
    KeyUI.Name = "KeyUI"
    KeyUI.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    KeyUI.ResetOnSpawn = false
    KeyUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    KeyUI.DisplayOrder = 999
        
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
    
    -- Fonction de vérification de clé
    SubmitButton.MouseButton1Click:Connect(function()
        if KeyInput.Text == correctKey then
            StatusLabel.Text = "Clé valide! Chargement..."
            StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
            wait(1)
            KeyUI:Destroy()
            loadScript()
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
