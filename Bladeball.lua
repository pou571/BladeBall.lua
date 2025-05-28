-- WARNING: Use at your own risk. This script is unverified.
-- Blade Ball Script with Extra Features
-- by spofty_124 (обновлено)

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name = "Blade Ball | Script",
    LoadingTitle = "Blade Ball | Script",
    LoadingSubtitle = "by spofty_124",
    ConfigurationSaving = {
        Enabled = false
    },
    Discord = {
        Enabled = false
    },
    KeySystem = false
})

-- Global toggles
getgenv().AutoParry = true
getgenv().NoClip = false
getgenv().Flying = false
getgenv().ClickTP = false
getgenv().AutoPlay = false

local localPlayer = game:GetService("Players").LocalPlayer
local mouse = localPlayer:GetMouse()
local inputManager = game:GetService("VirtualInputManager")
local runService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

-- === Tabs ===
local MainTab = Window:CreateTab("Main", 4483362458)
local MiscTab = Window:CreateTab("Utilities", 4483362458)
local AntiTab = Window:CreateTab("Anti", 4483362458)

-- === Auto Parry ===
MainTab:CreateToggle({
    Name = "Enable Auto Parry",
    CurrentValue = true,
    Callback = function(Value)
        getgenv().AutoParry = Value
    end,
})

-- === Auto Play ===
MainTab:CreateToggle({
    Name = "Auto Play (Beta)",
    CurrentValue = false,
    Callback = function(Value)
        getgenv().AutoPlay = Value
    end,
})

-- === NoClip ===
MiscTab:CreateToggle({
    Name = "NoClip (T to toggle)",
    CurrentValue = false,
    Callback = function(Value)
        getgenv().NoClip = Value
    end,
})

-- === Fly ===
MiscTab:CreateToggle({
    Name = "Fly (F to toggle)",
    CurrentValue = false,
    Callback = function(Value)
        getgenv().Flying = Value
    end,
})

-- === Speed Boost ===
MiscTab:CreateButton({
    Name = "Enable Speed Boost",
    Callback = function()
        local char = localPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.WalkSpeed = 100
        end
    end,
})

-- === Click Teleport ===
MiscTab:CreateButton({
    Name = "Enable Click TP (Click anywhere)",
    Callback = function()
        getgenv().ClickTP = true
        mouse.Button1Down:Connect(function()
            if getgenv().ClickTP and mouse.Target then
                localPlayer.Character:MoveTo(mouse.Hit.Position + Vector3.new(0, 3, 0))
            end
        end)
    end,
})

-- === Anti-AFK ===
AntiTab:CreateParagraph({Title = "Anti-AFK", Content = "Включено автоматически"})
AntiTab:CreateParagraph({Title = "Anti-Ban", Content = "В разработке"})

local virtualUser = game:GetService("VirtualUser")
game:GetService("Players").LocalPlayer.Idled:Connect(function()
    virtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    virtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
end)

-- === Auto Play Logic ===
task.spawn(function()
    local directions = {Vector3.new(10,0,0), Vector3.new(-10,0,0), Vector3.new(0,0,10), Vector3.new(0,0,-10)}
    while task.wait(0.5) do
        if getgenv().AutoPlay and localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local char = localPlayer.Character
            local hrp = char:FindFirstChild("HumanoidRootPart")

            -- Simple dodging when ball is fast or too close
            local balls = workspace:FindFirstChild("Balls")
            if balls then
                for _, ball in pairs(balls:GetChildren()) do
                    if ball:IsA("BasePart") and ball:GetAttribute("realBall") and ball:GetAttribute("target") == localPlayer.Name then
                        local velocity = ball.AssemblyLinearVelocity.Magnitude
                        if velocity > 90 then
                            hrp.CFrame = hrp.CFrame + directions[math.random(1, #directions)]
                        end
                    end
                end
            end

            -- Random strafe to simulate "tactic"
            hrp.CFrame = hrp.CFrame * CFrame.new(math.random(-5,5),0,math.random(-5,5))
        end
    end
end)

-- === NoClip logic ===
task.spawn(function()
    runService.Stepped:Connect(function()
        if getgenv().NoClip then
            for _, part in pairs(localPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end)
end)

-- === Fly logic ===
task.spawn(function()
    local flying = false
    local bodyGyro, bodyVelocity

    UIS.InputBegan:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.F then
            flying = not flying
            getgenv().Flying = flying

            if flying then
                local root = localPlayer.Character:WaitForChild("HumanoidRootPart")
                bodyGyro = Instance.new("BodyGyro", root)
                bodyGyro.P = 9e4
                bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
                bodyGyro.CFrame = root.CFrame

                bodyVelocity = Instance.new("BodyVelocity", root)
                bodyVelocity.Velocity = Vector3.new(0, 0, 0)
                bodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)

                while flying do
                    bodyGyro.CFrame = workspace.CurrentCamera.CFrame
                    bodyVelocity.Velocity = workspace.CurrentCamera.CFrame.LookVector * 80
                    wait()
                end
            else
                if bodyGyro then bodyGyro:Destroy() end
                if bodyVelocity then bodyVelocity:Destroy() end
            end
        end
    end)
end)

-- === Auto Parry logic ===
local function FindTargetBall()
    for _, ball in workspace:WaitForChild("Balls"):GetChildren() do
        if ball:IsA("BasePart") and ball:GetAttribute("realBall") then
            return ball
        end
    end
end

local function IsPlayerTarget(ball)
    return ball:GetAttribute("target") == localPlayer.Name
end

local eventTriggered = false

task.spawn(function()
    runService.PreRender:Connect(function()
        if not getgenv().AutoParry then return end

        local currentBall = FindTargetBall()
        if not currentBall then return end

        local currentBallVelocity = currentBall.AssemblyLinearVelocity
        if currentBall:FindFirstChild("zoomies") then
            currentBallVelocity = currentBall.zoomies.VectorVelocity
        end

        local currentBallPosition = currentBall.Position
        local playerCharacterPosition = localPlayer.Character.PrimaryPart.Position
        local directionFromBallToPlayer = (playerCharacterPosition - currentBallPosition).Unit
        local distanceFromPlayerToBall = localPlayer:DistanceFromCharacter(currentBallPosition)
        local dotProductValue = directionFromBallToPlayer:Dot(currentBallVelocity.Unit)
        local velocityMagnitude = currentBallVelocity.Magnitude

        if dotProductValue > 0 then
            local adjustedDistance = distanceFromPlayerToBall - 5
            local estimatedTimeToReach = adjustedDistance / velocityMagnitude

            if IsPlayerTarget(currentBall) and estimatedTimeToReach <= 0.6 and not eventTriggered then
                inputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                eventTriggered = true
            end
        else
            eventTriggered = false
        end
    end)
end)
