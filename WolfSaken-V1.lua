local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local localPlayer = Players.LocalPlayer

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "WolfSaken🐺-V1",
    LoadingTitle = "Hello " .. localPlayer.Name,
    LoadingSubtitle = "Loading...",
    Theme = "DarkBlue",
    ToggleUIKeybind = "K",
    KeySystem = false,
})

local Main = Window:CreateTab("All-In-One")

local autoGenEnabled = false
local autoGenCooldown = 3
local infStaminaEnabled = false
local visualStaminaEnabled = false
local autoBlockEnabled = false
local autoParryEnabled = false -- New Auto Parry Variable
local blockRadius = 15
local blockDelay = 0
local lastBlockTime = 0
local blockCooldown = 0.35
local aimPunchEnabled = false
local punchPrediction = 4

Main:CreateSection("Generator")

Main:CreateToggle({
    Name = "Auto Generator",
    CurrentValue = false,
    Callback = function(v)
        autoGenEnabled = v
    end
})

Main:CreateSlider({
    Name = "Cooldown",
    Range = {1, 15},
    Increment = 0.5,
    Suffix = "s",
    CurrentValue = autoGenCooldown,
    Callback = function(v)
        autoGenCooldown = v
    end
})

Main:CreateSection("Stamina")
local SprintingModule = require(
    ReplicatedStorage
        :WaitForChild("Systems")
        :WaitForChild("Character")
        :WaitForChild("Game")
        :WaitForChild("Sprinting")
)

local defaultLoss = SprintingModule.StaminaLoss
local defaultGain = SprintingModule.StaminaGain

local function applyStamina()
    if infStaminaEnabled then
        SprintingModule.StaminaLoss = 0
        SprintingModule.StaminaGain = 9999
    else
        SprintingModule.StaminaLoss = defaultLoss
        SprintingModule.StaminaGain = defaultGain
    end
end

Main:CreateToggle({
    Name = "Inf Stamina",
    CurrentValue = false,
    Callback = function(v)
        infStaminaEnabled = v
        applyStamina()
    end
})

local connection

local function getModule()
    local sprinting = ReplicatedStorage
        :WaitForChild("Systems")
        :WaitForChild("Character")
        :WaitForChild("Game")
        :WaitForChild("Sprinting")
    return require(sprinting)
end

local function createDisplay()
    local character = localPlayer.Character
    if not character then return nil end

    local head = character:WaitForChild("Head")

    pcall(function()
        if head:FindFirstChild("StaminaDisplay") then
            head:FindFirstChild("StaminaDisplay"):Destroy()
        end
    end)

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "StaminaDisplay"
    billboard.Size = UDim2.new(3, 0, 1, 0)
    billboard.StudsOffset = Vector3.new(0, 3.5, 0)
    billboard.AlwaysOnTop = true
    billboard.LightInfluence = 0
    billboard.Enabled = visualStaminaEnabled
    billboard.Parent = head

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextSize = 12 
    textLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
    textLabel.TextStrokeTransparency = 0.4
    textLabel.Text = "Stamina"
    textLabel.Parent = billboard

    return textLabel
end

local function updateDisplay(textLabel)
    local module = getModule()
    local current = math.floor(module.Stamina or 0)
    local maxStam = module.MaxStamina or 100
    textLabel.Text = "Stamina " .. current .. "/" .. maxStam
end

local function setupCharacter()
    local textLabel = createDisplay()
    if not textLabel then return end

    if connection then connection:Disconnect() end

    connection = RunService.RenderStepped:Connect(function()
        if visualStaminaEnabled then
            pcall(updateDisplay, textLabel)
        end
    end)
end

Main:CreateToggle({
    Name = "Visual Stamina",
    CurrentValue = false,
    Callback = function(v)
        visualStaminaEnabled = v
        local char = localPlayer.Character
        if char then
            local head = char:FindFirstChild("Head")
            if head and head:FindFirstChild("StaminaDisplay") then
                head.StaminaDisplay.Enabled = v
            end
        end
    end
})

applyStamina()

if localPlayer.Character then
    task.wait(1)
    setupCharacter()
end

localPlayer.CharacterAdded:Connect(function()
    task.wait(2)
    applyStamina()
    setupCharacter()
end)

task.spawn(function()
    local lastFire = 0
    while task.wait(0.1) do
        if autoGenEnabled and tick() - lastFire >= autoGenCooldown then
            pcall(function()
                local mapFolder = Workspace:FindFirstChild("Map")
                    and Workspace.Map:FindFirstChild("Ingame")
                    and Workspace.Map.Ingame:FindFirstChild("Map")

                if not mapFolder then return end

                for _, gen in pairs(mapFolder:GetChildren()) do
                    if gen.Name == "Generator"
                        and gen:FindFirstChild("Remotes")
                        and gen.Remotes:FindFirstChild("RE") then
                        gen.Remotes.RE:FireServer()
                    end
                end
            end)
            lastFire = tick()
        end
    end
end)

local ESPState = { Killers = false, Survivors = false, Generators = false, Items = false }

Main:CreateSection("ESP TAG")

Main:CreateToggle({ Name = "Killers ESP", Callback = function(v) ESPState.Killers = v end })
Main:CreateToggle({ Name = "Survivors ESP", Callback = function(v) ESPState.Survivors = v end })
Main:CreateToggle({ Name = "Generators ESP", Callback = function(v) ESPState.Generators = v end })
Main:CreateToggle({ Name = "Items ESP", Callback = function(v) ESPState.Items = v end })

local killersFolder = Workspace:WaitForChild("Players"):WaitForChild("Killers")
local survivorsFolder = Workspace:WaitForChild("Players"):WaitForChild("Survivors")
local itemsFolder = Workspace:FindFirstChild("Items")

local function getMapFolder()
    local map = Workspace:FindFirstChild("Map")
    if map and map:FindFirstChild("Ingame") then
        return map.Ingame:FindFirstChild("Map")
    end
end

local function createESP(obj, color)
    if obj:FindFirstChild("ESP_Tag") then return end

    local adornee = obj:FindFirstChild("Head")
        or obj:FindFirstChild("HumanoidRootPart")
        or obj:FindFirstChildWhichIsA("BasePart")

    if not adornee then return end

    local bb = Instance.new("BillboardGui")
    bb.Name = "ESP_Tag"
    bb.Adornee = adornee
    bb.Size = UDim2.new(0, 90, 0, 18)
    bb.StudsOffset = Vector3.new(0, 2, 0)
    bb.AlwaysOnTop = true
    bb.Enabled = false
    bb.Parent = obj

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.TextSize = 9
    label.Font = Enum.Font.GothamBold
    label.TextStrokeTransparency = 0.5
    label.TextColor3 = color
    label.Text = obj.Name
    label.Parent = bb
end

task.spawn(function()
    while task.wait(1.5) do
        if ESPState.Killers then
            for _, k in pairs(killersFolder:GetChildren()) do
                if k:IsA("Model") then createESP(k, Color3.fromRGB(255, 0, 0)) end
            end
        end
        if ESPState.Survivors then
            for _, s in pairs(survivorsFolder:GetChildren()) do
                if s:IsA("Model") then createESP(s, Color3.fromRGB(0, 170, 255)) end
            end
        end
        if ESPState.Generators then
            local mapFolder = getMapFolder()
            if mapFolder then
                for _, gen in pairs(mapFolder:GetChildren()) do
                    if gen.Name == "Generator" then createESP(gen, Color3.fromRGB(170, 0, 255)) end
                end
            end
        end
        if ESPState.Items and itemsFolder then
            for _, item in pairs(itemsFolder:GetChildren()) do
                createESP(item, Color3.fromRGB(0, 170, 255))
            end
        end
    end
end)

RunService.RenderStepped:Connect(function()
    for _, obj in pairs(killersFolder:GetChildren()) do
        local bb = obj:FindFirstChild("ESP_Tag")
        if bb then bb.Enabled = ESPState.Killers end
    end
    for _, obj in pairs(survivorsFolder:GetChildren()) do
        local bb = obj:FindFirstChild("ESP_Tag")
        if bb then bb.Enabled = ESPState.Survivors end
    end
    local mapFolder = getMapFolder()
    if mapFolder then
        for _, gen in pairs(mapFolder:GetChildren()) do
            local bb = gen:FindFirstChild("ESP_Tag")
            if bb then bb.Enabled = ESPState.Generators end
        end
    end
    if itemsFolder then
        for _, item in pairs(itemsFolder:GetChildren()) do
            local bb = item:FindFirstChild("ESP_Tag")
            if bb then bb.Enabled = ESPState.Items end
        end
    end
end)

local guestAimTargets = { "Slasher", "c00lkidd", "JohnDoe", "1x1x1x1", "Noli", "Sixer", "Nosferatu" }

local guestAutoBlockTriggerSounds = {
    ["102228729296384"] = true, ["140242176732868"] = true, ["112809109188560"] = true, ["136323728355613"] = true,
    ["115026634746636"] = true, ["84116622032112"] = true, ["108907358619313"] = true, ["127793641088496"] = true,
    ["86174610237192"] = true, ["95079963655241"] = true, ["101199185291628"] = true, ["119942598489800"] = true,
    ["84307400688050"] = true, ["113037804008732"] = true, ["105200830849301"] = true, ["75330693422988"] = true,
    ["82221759983649"] = true, ["109348678063422"] = true, ["81702359653578"] = true, ["85853080745515"] = true,
    ["108610718831698"] = true, ["112395455254818"] = true, ["109431876587852"] = true, ["12222216"] = true,
    ["79980897195554"] = true, ["119583605486352"] = true, ["71834552297085"] = true, ["116581754553533"] = true,
    ["86833981571073"] = true, ["110372418055226"] = true, ["105840448036441"] = true, ["86494585504534"] = true,
    ["80516583309685"] = true, ["131406927389838"] = true, ["89004992452376"] = true, ["117231507259853"] = true,
    ["101698569375359"] = true, ["101553872555606"] = true, ["140412278320643"] = true, ["106300477136129"] = true,
    ["117173212095661"] = true, ["104910828105172"] = true, ["140194172008986"] = true, ["85544168523099"] = true,
    ["114506382930939"] = true, ["99829427721752"] = true, ["120059928759346"] = true, ["104625283622511"] = true,
    ["105316545074913"] = true, ["126131675979001"] = true, ["82336352305186"] = true, ["93366464803829"] = true,
    ["84069821282466"] = true, ["128856426573270"] = true, ["121954639447247"] = true, ["128195973631079"] = true,
    ["124903763333174"] = true, ["94317217837143"] = true, ["98111231282218"] = true, ["119089145505438"] = true,
    ["136728245733659"] = true, ["71310583817000"] = true, ["107444859834748"] = true, ["76959687420003"] = true,
    ["72425554233832"] = true, ["96594507550917"] = true, ["139996647355899"] = true, ["107345261604889"] = true,
    ["127557531826290"] = true, ["108651070773439"] = true, ["74842815979546"] = true, ["124397369810639"] = true,
    ["76467993976301"] = true, ["118493324723683"] = true, ["78298577002481"] = true, ["116527305931161"] = true,
    ["5148302439"] = true, ["98675142200448"] = true, ["128367348686124"] = true, ["71805956520207"] = true,
    ["125213046326879"] = true, ["84353899757208"] = true, ["103684883268194"] = true,
    ["109246041199659"] = true, ["80540530406270"] = true, ["139523195429581"] = true, ["105204810054381"] = true,
}

local guestTrackedPunchAnimations = {
    ["87259391926321"] = true, ["140703210927645"] = true, ["136007065400978"] = true, ["129843313690921"] = true,
    ["86709774283672"] = true, ["108807732150251"] = true, ["138040001965654"] = true, ["86096387000557"] = true,
    ["81905101227053"] = true, ["127777649118195"] = true, ["99100240941590"] = true,
    ["92831180929659"] = true, ["112081768119093"] = true, ["117587689359268"] = true, ["91830732867282"] = true,
    ["91730605416216"] = true, ["100184164753080"] = true,
}

local remoteEvent = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Network"):WaitForChild("RemoteEvent")

-- Updated FireBlock function handles Auto-Parry counter logic smoothly
local function fireBlock()
    if tick() - lastBlockTime >= blockCooldown then
        if blockDelay > 0 then task.wait(blockDelay) end
        
        -- Fire Block Remote
        remoteEvent:FireServer("UseActorAbility", { [1] = buffer.fromstring("\3\5\0\0\0Block") })
        lastBlockTime = tick()
        
        -- Auto Parry Handler: Counter punch instantly after frame buffer registers the block
        if autoParryEnabled then
            task.spawn(function()
                task.wait(0.08) -- Perfect split-second buffer to absorb impact before punching
                remoteEvent:FireServer("UseActorAbility", { [1] = buffer.fromstring("\3\5\0\0\0Punch") })
            end)
        end
    end
end

task.spawn(function()
    while task.wait(0.05) do 
        if not autoBlockEnabled then continue end
        
        local char = localPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then continue end
        local myHRP = char.HumanoidRootPart

        if not killersFolder then continue end

        for _, enemy in pairs(killersFolder:GetChildren()) do
            if table.find(guestAimTargets, enemy.Name) and enemy:FindFirstChild("HumanoidRootPart") then
                local dist = (myHRP.Position - enemy.HumanoidRootPart.Position).Magnitude
                
                if dist <= blockRadius then
                    -- 1. Check Sounds
                    local head = enemy:FindFirstChild("Head")
                    if head then
                        for _, sound in pairs(head:GetChildren()) do
                            if sound:IsA("Sound") and sound.IsPlaying then
                                local soundId = string.match(sound.SoundId, "%d+")
                                if soundId and guestAutoBlockTriggerSounds[soundId] then
                                    fireBlock()
                                end
                            end
                        end
                    end
                    
                    -- 2. Check Animations
                    local enemyHum = enemy:FindFirstChild("Humanoid")
                    if enemyHum then
                        local animator = enemyHum:FindFirstChild("Animator")
                        if animator then
                            for _, track in pairs(animator:GetPlayingAnimationTracks()) do
                                local animId = string.match(track.Animation.AnimationId, "%d+")
                                if animId and guestTrackedPunchAnimations[animId] then
                                    fireBlock()
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)

Main:CreateSection("Auto-Block")

Main:CreateToggle({
    Name = "Enable Auto-Block", 
    CurrentValue = false,
    Callback = function(state) 
        autoBlockEnabled = state 
    end
})

-- NEW: Auto Parry UI Toggle
Main:CreateToggle({
    Name = "Auto Parry (After Block)", 
    CurrentValue = false,
    Callback = function(state) 
        autoParryEnabled = state 
    end
})

Main:CreateSlider({
    Name = "Detection Radius", 
    Range = {1, 30}, 
    Increment = 0.5, 
    CurrentValue = 15,
    Suffix = " studs",
    Callback = function(v) 
        blockRadius = v 
    end
})

Main:CreateSlider({
    Name = "Block Delay", 
    Range = {0, 1}, 
    Increment = 0.05, 
    CurrentValue = 0,
    Suffix = "s",
    Callback = function(v) 
        blockDelay = v 
    end
})

Main:CreateLabel("⚠️ Best Settings: Radius 13-14 | Delay 0.1")

Main:CreateToggle({
    Name = "Enable Aim Punch", 
    CurrentValue = false,
    Callback = function(state) 
        aimPunchEnabled = state 
    end
})

Main:CreateSlider({
    Name = "Punch Prediction", 
    Range = {0, 4}, 
    Increment = 1, 
    CurrentValue = 4,
    Callback = function(v) 
        punchPrediction = v 
    end
})

local function getClosestKiller()
    local char = localPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end
    local myHRP = char.HumanoidRootPart

    if not killersFolder then return nil end

    local closestTarget = nil
    local shortestDistance = 15 

    for _, enemy in pairs(killersFolder:GetChildren()) do
        if table.find(guestAimTargets, enemy.Name) and enemy:FindFirstChild("HumanoidRootPart") then
            local dist = (myHRP.Position - enemy.HumanoidRootPart.Position).Magnitude
            if dist < shortestDistance then
                shortestDistance = dist
                closestTarget = enemy
            end
        end
    end
    return closestTarget
end

RunService.RenderStepped:Connect(function()
    if not aimPunchEnabled then return end
    
    local char = localPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local myHRP = char.HumanoidRootPart

    local target = getClosestKiller()
    if target and target:FindFirstChild("HumanoidRootPart") then
        local enemyHRP = target.HumanoidRootPart
        local predictedPos = enemyHRP.Position + (enemyHRP.Velocity * (punchPrediction / 10))
        
        myHRP.CFrame = CFrame.lookAt(myHRP.Position, Vector3.new(predictedPos.X, myHRP.Position.Y, predictedPos.Z))
    end
end)
