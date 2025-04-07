-- Chargement de la librairie OrionLib
local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexware/Orion/main/source"))()

-- Définition de la fenêtre principale
local Window = OrionLib:MakeWindow({
    Name = "Pet Simulator 99 | By lil_Gio", 
    HidePremium = false, 
    SaveConfig = true, 
    ConfigFolder = "OrionTest"
})

-- Téléportation automatique
local tpEnabled = false
local tpZone = "Spawn" -- par défaut

-- Table des positions de téléportation ADE
local tpZones = {
    ["Spawn"] = Vector3.new(116, 96, 350),
    ["Zone 1"] = Vector3.new(500, 100, 600),
    ["Zone 2"] = Vector3.new(950, 105, 950),
    ["Zone 3"] = Vector3.new(1450, 108, 1350),
    ["Zone ADE"] = Vector3.new(1750, 110, 1600) -- Coordonnées fictives à ajuster
}

-- Fonction de téléportation
local function teleportTo(zone)
    local player = game.Players.LocalPlayer
    if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        player.Character.HumanoidRootPart.CFrame = CFrame.new(tpZones[zone])
    end
end

-- Titre
OrionLib:MakeNotification({
    Name = "Chargement...",
    Content = "Le menu est en cours de chargement.",
    Image = "rbxassetid://4483345998",
    Time = 3
})

-- Création des onglets
local MainTab = Window:MakeTab({
    Name = "Menu",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

local FarmTab = Window:MakeTab({
    Name = "Farm",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

local TPZoneTab = Window:MakeTab({
    Name = "TP Zone ADE",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

-- Section principale
MainTab:AddParagraph("Bienvenue sur le script Pet Simulator 99", "Créé par lil_Gio")

MainTab:AddButton({
    Name = "Rejoindre le Discord",
    Callback = function()
        setclipboard("https://discord.gg/example")
        OrionLib:MakeNotification({
            Name = "Copié !",
            Content = "Le lien Discord a été copié dans ton presse-papier.",
            Time = 5
        })
    end
})

-- Auto Farm
FarmTab:AddToggle({
    Name = "Auto Farm",
    Default = false,
    Callback = function(value)
        tpEnabled = value
        while tpEnabled do
            teleportTo(tpZone)
            wait(5) -- délai entre les téléportations
        end
    end
})

-- Choix de la zone de téléportation
TPZoneTab:AddDropdown({
    Name = "Choisir une zone ADE",
    Default = "Spawn",
    Options = {"Spawn", "Zone 1", "Zone 2", "Zone 3", "Zone ADE"},
    Callback = function(zone)
        tpZone = zone
        OrionLib:MakeNotification({
            Name = "Zone sélectionnée",
            Content = "Téléportation vers : " .. zone,
            Time = 3
        })
    end
})

-- Bouton de téléportation manuelle
TPZoneTab:AddButton({
    Name = "Téléporter maintenant",
    Callback = function()
        teleportTo(tpZone)
    end
})

-- Fin
OrionLib:Init()
