-- Tropic Hub GUI setup
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Tropic Hub",
    LoadingTitle = "Loading Tropic Hub...",
    LoadingSubtitle = "by Tropical",
    Theme = "Amethyst",
    ConfigurationSaving = {
        Enabled = true,
        FileName = "Tropic Hub"
    },
    KeySystem = false
})

-- Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera

-- ESP Setup (Existing code remains the same)
local espColor = Color3.fromRGB(255, 255, 255)
local rainbowESP = false
local rainbowSpeed = 0.005
local hueESP = 0
local tick = tick

local ESP = {
    Enabled = false,
    Names = false,
    Tracers = false,
    Boxes = false,
    HealthBars = false,
    Drawings = {}
}

local function CreateESP(player)
    local box = Drawing.new("Square")
    box.Visible = false
    box.Color = espColor
    box.Thickness = 1
    box.Transparency = 1
    box.Filled = false

    local name = Drawing.new("Text")
    name.Visible = false
    name.Color = espColor
    name.Size = 16
    name.Center = true
    name.Outline = true
    name.Font = 2

    local tracer = Drawing.new("Line")
    tracer.Visible = false
    tracer.Color = espColor
    tracer.Thickness = 1

    ESP.Drawings[player] = {
        Box = box,
        Name = name,
        Tracer = tracer
    }
end

local function RemoveESP(player)
    if ESP.Drawings[player] then
        for _, drawing in pairs(ESP.Drawings[player]) do
            drawing:Remove()
        end
        ESP.Drawings[player] = nil
    end
end

Players.PlayerAdded:Connect(CreateESP)
Players.PlayerRemoving:Connect(RemoveESP)

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        CreateESP(player)
    end
end

RunService.RenderStepped:Connect(function()
    if not ESP.Enabled then
        for _, drawings in pairs(ESP.Drawings) do
            drawings.Box.Visible = false
            drawings.Name.Visible = false
            drawings.Tracer.Visible = false
        end
        return
    end

    if rainbowESP then
        hueESP = hueESP + rainbowSpeed
        if hueESP > 1 then
            hueESP = 0
        end
        espColor = Color3.fromHSV(hueESP, 1, 1)
    end

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") and player.Character:FindFirstChild("Head") then
            local char = player.Character
            local hrp = char.HumanoidRootPart
            local head = char.Head
            local humanoid = char.Humanoid

            local rootPos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(hrp.Position)

            local drawings = ESP.Drawings[player]
            if not drawings then continue end
            local box = drawings.Box
            local name = drawings.Name
            local tracer = drawings.Tracer

            if onScreen then
                local topPos = workspace.CurrentCamera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.3, 0))
                local bottomPos = workspace.CurrentCamera:WorldToViewportPoint(hrp.Position - Vector3.new(0, humanoid.HipHeight + 2, 0))

                local height = bottomPos.Y - topPos.Y
                local width = height / 2

                box.Size = Vector2.new(width, height)
                box.Position = Vector2.new(rootPos.X - width / 2, rootPos.Y - height / 2)
                box.Color = espColor
                box.Visible = ESP.Boxes

                name.Text = player.Name
                name.Position = Vector2.new(rootPos.X, rootPos.Y - height / 2 - 16)
                name.Color = espColor
                name.Visible = ESP.Names

                tracer.From = Vector2.new(workspace.CurrentCamera.ViewportSize.X / 2, workspace.CurrentCamera.ViewportSize.Y)
                tracer.To = Vector2.new(rootPos.X, rootPos.Y)
                tracer.Color = espColor
                tracer.Visible = ESP.Tracers
            else
                box.Visible = false
                name.Visible = false
                tracer.Visible = false
            end
        elseif ESP.Drawings[player] then
            ESP.Drawings[player].Box.Visible = false
            ESP.Drawings[player].Name.Visible = false
            ESP.Drawings[player].Tracer.Visible = false
        end
    end
end)

-- Main Tab (Existing code remains the same)
local MainTab = Window:CreateTab("Main", nil)
local MainSection = MainTab:CreateSection("Player Mods")

MainTab:CreateSlider({
    Name = "WalkSpeed",
    Range = {16, 100},
    Increment = 1,
    Suffix = "Speed",
    CurrentValue = 16,
    Callback = function(Value)
        if Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("Humanoid") then
            Players.LocalPlayer.Character.Humanoid.WalkSpeed = Value
        end
    end,
})

MainTab:CreateSlider({
    Name = "JumpPower",
    Range = {50, 200},
    Increment = 1,
    Suffix = "Power",
    CurrentValue = 50,
    Callback = function(Value)
        if Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("Humanoid") then
            Players.LocalPlayer.Character.Humanoid.JumpPower = Value
        end
    end,
})

local UserInputService = game:GetService("UserInputService")
local flying = false
local flightSpeed = 50
local bodyGyro = Instance.new("BodyGyro")
local bodyVelocity = Instance.new("BodyVelocity")

bodyGyro.MaxTorque = Vector3.new(400000, 400000, 400000)
bodyGyro.D = 9
bodyVelocity.MaxForce = Vector3.new(400000, 400000, 400000)
bodyVelocity.Velocity = Vector3.new(0, 0, 0)

local function freezeAnimations()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid:Move(Vector3.zero)
        LocalPlayer.Character.Humanoid.PlatformStand = true
    end
end

local function unfreezeAnimations()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.PlatformStand = false
    end
end

local function startFlying()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local humanoidRootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        bodyVelocity.Parent = humanoidRootPart
        bodyGyro.Parent = humanoidRootPart
        flying = true
        freezeAnimations()
        game:GetService("RunService").RenderStepped:Connect(function()
            if flying then
                local camera = workspace.CurrentCamera
                local forward = camera.CFrame.LookVector * flightSpeed
                local right = camera.CFrame.RightVector * flightSpeed
                local up = Vector3.new(0, flightSpeed, 0)

                local velocity = Vector3.new(0, 0, 0)
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                    velocity = velocity + forward
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                    velocity = velocity - forward
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                    velocity = velocity - right
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                    velocity = velocity + right
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                    velocity = velocity + up
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                    velocity = velocity - up
                end

                bodyVelocity.Velocity = velocity
                bodyGyro.CFrame = camera.CFrame
            end
        end)
    end
end

local function stopFlying()
    flying = false
    bodyVelocity.Parent = nil
    bodyGyro.Parent = nil
    unfreezeAnimations()
end

MainTab:CreateToggle({
    Name = "Enable Flight",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            startFlying()
        else
            stopFlying()
        end
    end,
})

MainTab:CreateSlider({
    Name = "Flight Speed",
    Range = {10, 200},
    Increment = 1,
    Suffix = "Speed",
    CurrentValue = flightSpeed,
    Callback = function(Value)
        flightSpeed = Value
    end,
})

local UtilitySection = MainTab:CreateSection("Utilities")

MainTab:CreateButton({
    Name = "Rejoin Server",
    Callback = function()
        local ts = game:GetService("TeleportService")
        local placeId = game.PlaceId
        ts:Teleport(placeId, Players.LocalPlayer)
    end,
})

MainTab:CreateButton({
    Name = "Server Hop",
    Callback = function()
        local HttpService = game:GetService("HttpService")
        local TeleportService = game:GetService("TeleportService")

        local function serverHop()
            local servers = {}
            local req = game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")
            local data = HttpService:JSONDecode(req)

            for _, v in pairs(data.data) do
                if v.playing < v.maxPlayers and v.id ~= game.JobId then
                    table.insert(servers, v.id)
                end
            end

            if #servers > 0 then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, servers[math.random(1, #servers)], Players.LocalPlayer)
            else
                warn("No other servers found.")
            end
        end

        pcall(serverHop)
    end,
})

MainTab:CreateButton({
    Name = "Uninject",
    Callback = function()
        Rayfield:Notify({
            Title = "Uninjecting...",
            Content = "Uninjecting Tropic Gui",
            Duration = 6.5,
            Image = 4483362458,
         })
         task.wait(3)
            Rayfield:Destroy()  
    end
})

local MainScripts = MainTab:CreateSection("Scripts")

MainTab:CreateButton({
    Name = "Inject Infinite Yield",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
    end
})

MainTab:CreateButton({
    Name = "Inject DEX (Debugging)",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/main/dex.lua"))()
    end
})

-- ESP Tab (Existing code remains the same)
local ESPTab = Window:CreateTab("ESP", nil)
local ESPSection = ESPTab:CreateSection("ESP Options")

ESPTab:CreateToggle({
    Name = "Enable ESP",
    CurrentValue = false,
    Callback = function(Value)
        ESP.Enabled = Value
    end,
})

ESPTab:CreateToggle({
    Name = "Names",
    CurrentValue = true,
    Callback = function(Value)
        ESP.Names = Value
    end,
})

ESPTab:CreateToggle({
    Name = "Tracers",
    CurrentValue = false,
    Callback = function(Value)
        ESP.Tracers = Value
    end,
})

ESPTab:CreateToggle({
    Name = "Boxes",
    CurrentValue = false,
    Callback = function(Value)
        ESP.Boxes = Value
    end,
})

ESPTab:CreateToggle({
    Name = "Health Bars",
    CurrentValue = false,
    Callback = function(Value)
        ESP.HealthBars = Value
    end,
})

ESPTab:CreateColorPicker({
    Name = "ESP Color",
    Color = espColor,
    Callback = function(Value)
        espColor = Value
        if not rainbowESP then
            for _, v in pairs(ESP.Drawings) do
                v.Box.Color = Value
                v.Name.Color = Value
                v.Tracer.Color = Value
            end
        end
    end,
})

ESPTab:CreateToggle({
    Name = "Rainbow ESP Color",
    CurrentValue = false,
    Callback = function(Value)
        rainbowESP = Value
    end,
})

ESPTab:CreateSlider({
    Name = "ESP Thickness",
    Range = {1, 10},
    Increment = 0.1,
    Suffix = "px",
    CurrentValue = 1,
    Callback = function(Value)
        for _, v in pairs(ESP.Drawings) do
            if v.Box then v.Box.Thickness = Value end
            if v.Tracer then v.Tracer.Thickness = Value end
        end
    end,
})

-- Combat Tab (Modified)
local CombatTab = Window:CreateTab("Combat", nil)
local AimbotSection = CombatTab:CreateSection("Aimbot")

-- Aimbot Toggles and Settings
local aimbotEnabled = false
local fovEnabled = false
local fovRadius = 50 -- Default FOV radius
local targetPlayer = nil
local fovCircle = nil
local fovColor = Color3.fromRGB(255, 255, 255) -- Default FOV color is now white
local rainbowFOV = false
local hueFOV = 0
local rainbowFOVSpeed = 0.01 -- Slightly faster rainbow for FOV
local fovTransparency = 0.5
local aimbotSmoothing = 1 -- Default smoothing is 0 (instant)

-- Function to create the FOV circle
local function createFOV()
    if fovCircle then
        fovCircle:Remove()
    end
    fovCircle = Drawing.new("Circle")
    fovCircle.Visible = fovEnabled
    fovCircle.Radius = fovRadius
    fovCircle.Thickness = 2
    fovCircle.Color = fovColor
    fovCircle.Filled = false
    fovCircle.Transparency = fovTransparency
    fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    fovCircle.ZIndex = 5 -- Ensure it's on top
end

-- Function to find the closest player within the FOV
local function getClosestPlayer()
    local closestPlayer = nil
    local closestDistance = math.huge
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
            local headPos3D, onScreen = Camera:WorldToViewportPoint(player.Character.Head.Position)
            if onScreen then
                local headPos2D = Vector2.new(headPos3D.X, headPos3D.Y) -- Extract the 2D coordinates
                local distance = (headPos2D - screenCenter).Magnitude
                if distance <= fovRadius and distance < closestDistance then
                    closestDistance = distance
                    closestPlayer = player
                end
            end
        end
    end
    return closestPlayer
end

-- Function to smoothly aim at the target
local function smoothAimAt(player, smoothingFactor)
    if player and player.Character and player.Character:FindFirstChild("Head") then
        local headPosition = player.Character.Head.Position
        local currentCameraCF = Camera.CFrame
        local targetCF = CFrame.lookAt(currentCameraCF.Position, headPosition)
        Camera.CFrame = currentCameraCF:Lerp(targetCF, smoothingFactor)
    end
end

-- Update loop for aimbot and FOV
RunService.RenderStepped:Connect(function()
    if fovEnabled then
        if not fovCircle then
            createFOV()
        else
            fovCircle.Visible = true
            fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
            fovCircle.Radius = fovRadius
            fovCircle.Transparency = fovTransparency
            if rainbowFOV then
                hueFOV = hueFOV + rainbowFOVSpeed
                if hueFOV > 1 then
                    hueFOV = 0
                end
                fovCircle.Color = Color3.fromHSV(hueFOV, 1, 1)
            else
                fovCircle.Color = fovColor
            end
        end
    elseif fovCircle then
        fovCircle.Visible = false
    end

    if aimbotEnabled and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then -- Right mouse button
        targetPlayer = getClosestPlayer()
        if targetPlayer then
            if aimbotSmoothing > 0 then
                smoothAimAt(targetPlayer, aimbotSmoothing)
            else
                aimAt(targetPlayer)
				end
        end
    end
end)

-- Aimbot Enable Toggle
CombatTab:CreateToggle({
    Name = "Enable Aimbot",
    CurrentValue = false,
    Callback = function(Value)
        aimbotEnabled = Value
        targetPlayer = nil -- Reset target when toggling
    end,
})

-- Aimbot Smoothing Slider
CombatTab:CreateSlider({
    Name = "Aimbot Smoothing",
    Range = {0, 1},
    Increment = 0.01,
    Suffix = "",
    CurrentValue = aimbotSmoothing,
    Callback = function(Value)
        aimbotSmoothing = Value
    end,
})

-- FOV Circle Enable Toggle
CombatTab:CreateToggle({
    Name = "Enable FOV Circle",
    CurrentValue = false,
    Callback = function(Value)
        fovEnabled = Value
        createFOV()
    end,
})

-- Rainbow FOV Toggle
CombatTab:CreateToggle({
    Name = "Rainbow FOV",
    CurrentValue = false,
    Callback = function(Value)
        rainbowFOV = Value
    end,
})

-- FOV Radius Slider
CombatTab:CreateSlider({
    Name = "FOV Radius",
    Range = {25, 200},
    Increment = 5,
    Suffix = " px",
    CurrentValue = fovRadius,
    Callback = function(Value)
        fovRadius = Value
        if fovCircle then
            fovCircle.Radius = Value
        end
    end,
})

-- FOV Color Picker
CombatTab:CreateColorPicker({
    Name = "FOV Color",
    Color = fovColor,
    Callback = function(Value)
        fovColor = Value
        if fovCircle and not rainbowFOV then
            fovCircle.Color = Value
        end
    end,
})

-- FOV Transparency Slider
CombatTab:CreateSlider({
    Name = "FOV Transparency",
    Range = {0, 1},
    Increment = 0.1,
    Suffix = "",
    CurrentValue = fovTransparency,
    Callback = function(Value)
        fovTransparency = Value
        if fovCircle then
            fovCircle.Transparency = Value
        end
    end,
})

-- Teleport Tab (Modified)
local TeleportTab = Window:CreateTab("Teleport", nil)
local TeleportSection = TeleportTab:CreateSection("Teleport")

-- Dropdown for players
local PlayersList = {}
for _, player in pairs(game.Players:GetPlayers()) do
    table.insert(PlayersList, player.Name)
end
-- Initialize variable for selected player
local selectedPlayer = nil

-- Create Dropdown for player selection
TeleportTab:CreateDropdown({
    Name = "Select Player",
    Options = PlayersList,  -- Assuming PlayersList is already populated with player names
    Callback = function(playerName)
        -- Update selected player when one is chosen from the dropdown
        selectedPlayer = game.Players:FindFirstChild(playerName)
    end
})

-- Create Button to teleport to selected player
TeleportTab:CreateButton({
    Name = "TP to Selected Player",
    Callback = function()
        -- Check if a player is selected and their character exists
        if selectedPlayer and selectedPlayer.Character and selectedPlayer.Character:FindFirstChild("HumanoidRootPart") then
            -- Teleport the local player to the selected player's position
            game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = selectedPlayer.Character.HumanoidRootPart.CFrame
        else
            -- Output error message if no player is selected or if the character is invalid
            print("No valid player selected or player not found!")
        end
    end
})


-- TP to Random button
TeleportTab:CreateButton({
    Name = "TP to Random Player",
    Callback = function()
        local randomPlayer = game.Players:GetPlayers()
        table.remove(randomPlayer, table.find(randomPlayer, game.Players.LocalPlayer)) -- Remove the local player from the list
        local randomTarget = randomPlayer[math.random(1, #randomPlayer)] -- Select a random player
        if randomTarget and randomTarget.Character and randomTarget.Character:FindFirstChild("HumanoidRootPart") then
            game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = randomTarget.Character.HumanoidRootPart.CFrame
        end
    end
})



-- Troll Tab (Modified)
local TrollTab = Window:CreateTab("Troll", nil)

TrollTab:CreateButton({
    Name = "Fling All",
    Callback = function()
        local flingall = loadstring(game:HttpGet('https://pastebin.com/raw/zqyDSUWX'))()
        Rayfield:Notify({
            Title = "Flinging All",
            Content = "This takes a few second.",
            Duration = 6.5,
            Image = 4483362458,
         })
    end
})
