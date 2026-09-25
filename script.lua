local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Автоматический поиск вашего тайкуна и сетевой кнопки игры
local function getTycoonRemote()
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj.Name:match("^Tycoon%d+$") then
            local owner = obj:FindFirstChild("Owner", true)
            if owner and owner:IsA("ObjectValue") and owner.Value == player then
                local remotes = obj:FindFirstChild("Remotes")
                if remotes then
                    return remotes:FindFirstChild("Ascend") 
                        or remotes:FindFirstChild("Evolve") 
                        or remotes:FindFirstChild("Rebirth")
                        or remotes:FindFirstChild("InvestorRebirth")
                end
            end
        end
    end
    return nil
end

-- Создаем аккуратную кнопку прямо на вашем экране
local ScreenGui = Instance.new("ScreenGui")
local Frame = Instance.new("Frame")
local TextButton = Instance.new("TextButton")
local UICorner = Instance.new("UICorner")

ScreenGui.Parent = game:GetService("CoreGui") or player:WaitForChild("PlayerGui")

Frame.Parent = ScreenGui
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Frame.Position = UDim2.new(0.4, 0, 0.1, 0) -- Кнопка появится вверху по центру экрана
Frame.Size = UDim2.new(0, 200, 0, 45)
Frame.Active = true
Frame.Draggable = true -- Кнопку можно двигать мышкой куда угодно!

TextButton.Parent = Frame
TextButton.BackgroundColor3 = Color3.fromRGB(46, 204, 113) -- Яркий зеленый цвет
TextButton.Size = UDim2.new(1, 0, 1, 0)
TextButton.Font = Enum.Font.SourceSansBold
TextButton.Text = "МГНОВЕННОЕ ВОЗРОЖДЕНИЕ"
TextButton.TextColor3 = Color3.fromRGB(255, 255, 255)
TextButton.TextSize = 14

UICorner.Parent = TextButton
UICorner.CornerRadius = UDim.new(0, 8)

-- Действие при одиночном клике на кнопку
TextButton.MouseButton1Click:Connect(function()
    local remote = getTycoonRemote()
    if remote then
        if remote:IsA("RemoteFunction") then
            pcall(function() remote:InvokeServer("Confirm") end)
            pcall(function() remote:InvokeServer(true) end)
        elseif remote:IsA("RemoteEvent") then
            pcall(function() remote:FireServer("Confirm") end)
            pcall(function() remote:FireServer(true) end)
        end
    end
end)

print("[-] Автономная кнопка Возрождения успешно создана!")
