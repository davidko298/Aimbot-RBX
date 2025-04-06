-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- Settings
local AimbotActive = false
local HoldingAlt = false
local AimbotKeybind = Enum.KeyCode.LeftAlt
local AimbotFOV = 150
local SilentAimEnabled = true
local CurrentTarget = nil

-- Target modes
local TargetOptions = {"Head", "Torso", "Legs", "Under"}
local TargetIndex = 1
local function GetTargetMode() return TargetOptions[TargetIndex] end

-- GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AimbotGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

local ToggleButton = Instance.new("TextButton")
ToggleButton.Size = UDim2.new(0, 150, 0, 40)
ToggleButton.Position = UDim2.new(0, 20, 0, 20)
ToggleButton.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
ToggleButton.TextColor3 = Color3.new(1, 1, 1)
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.TextSize = 20
ToggleButton.Text = "Aimbot: OFF"
ToggleButton.Parent = ScreenGui

local PartSwitchButton = Instance.new("TextButton")
PartSwitchButton.Size = UDim2.new(0, 150, 0, 40)
PartSwitchButton.Position = UDim2.new(0, 20, 0, 70)
PartSwitchButton.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
PartSwitchButton.TextColor3 = Color3.new(1, 1, 1)
PartSwitchButton.Font = Enum.Font.SourceSansBold
PartSwitchButton.TextSize = 20
PartSwitchButton.Text = "Target: Head"
PartSwitchButton.Parent = ScreenGui

-- Update GUI Text
local function UpdateGUI()
    ToggleButton.Text = "Aimbot: " .. (AimbotActive and "ON" or "OFF")
    PartSwitchButton.Text = "Target: " .. GetTargetMode()
end

-- GUI Button Handlers
ToggleButton.MouseButton1Click:Connect(function()
    AimbotActive = not AimbotActive
    UpdateGUI()
end)

PartSwitchButton.MouseButton1Click:Connect(function()
    TargetIndex = (TargetIndex % #TargetOptions) + 1
    UpdateGUI()
end)

-- Get closest target to crosshair
local function GetClosestTarget()
    local closestDist = AimbotFOV
    local target = nil
    local mode = GetTargetMode()

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local part = nil

            if mode == "Head" then
                part = player.Character:FindFirstChild("Head")
            elseif mode == "Torso" then
                part = player.Character:FindFirstChild("UpperTorso") or player.Character:FindFirstChild("Torso")
            elseif mode == "Legs" then
                part = player.Character:FindFirstChild("LeftLeg") or player.Character:FindFirstChild("RightLeg")
            elseif mode == "Under" then
                local root = player.Character:FindFirstChild("HumanoidRootPart")
                if root then
                    local underPos = root.Position - Vector3.new(0, 3, 0)
                    part = {
                        Position = underPos,
                        CFrame = CFrame.new(underPos)
                    }
                end
            end

            if part then
                local screenPos, onScreen = Camera:WorldToScreenPoint(part.Position)
                if onScreen then
                    local mousePos = UserInputService:GetMouseLocation()
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude

                    if dist < closestDist then
                        closestDist = dist
                        target = part
                    end
                end
            end
        end
    end

    return target
end

-- Aim at a part
local function AimAt(target)
    if target then
        local direction = (target.Position - Camera.CFrame.Position).Unit
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + direction)
    end
end

-- Main aimbot loop
RunService.RenderStepped:Connect(function()
    if AimbotActive and HoldingAlt then
        CurrentTarget = GetClosestTarget()
        AimAt(CurrentTarget)
    end
end)

-- Input handling
UserInputService.InputBegan:Connect(function(input, isProcessed)
    if isProcessed then return end
    if input.KeyCode == AimbotKeybind then
        HoldingAlt = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == AimbotKeybind then
        HoldingAlt = false
        CurrentTarget = nil
    end
end)

-- Silent Aim Hook
local oldIndex
oldIndex = hookmetamethod(game, "__index", function(self, key)
    if SilentAimEnabled and AimbotActive and HoldingAlt and self == Mouse and key == "Hit" and CurrentTarget then
        return CurrentTarget.CFrame
    end
    return oldIndex(self, key)
end)

print("✅ Aimbot loaded with persistent GUI, silent aim, and full target switching.")
