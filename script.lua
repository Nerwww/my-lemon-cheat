local Players = game:GetService("Players")
local workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")

local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local root = char:WaitForChild("HumanoidRootPart")

player.CharacterAdded:Connect(function(c)
    char = c
    root = c:WaitForChild("HumanoidRootPart")
end)

local FRUIT_CYCLE_DELAY = 3

-- ВОЗВРАЩАЕМ ВСЕ ПРОШЛЫЕ ФУНКЦИИ АВТОМАТИЗАЦИИ
local ENABLED = {
    AutoBuyUpgrades   = false,
    AutoCollectFruit  = false,
    AutoCollectDrops  = false,
    AutoUpgradeStands = false,
}

local function getMyTycoon()
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj.Name:match("^Tycoon%d+$") then
            local owner = obj:FindFirstChild("Owner", true)
            if owner and owner:IsA("ObjectValue") and owner.Value == player then
                return obj
            end
        end
    end
    return nil
end

local myTycoon = getMyTycoon()
local function tycoon()
    if not myTycoon then myTycoon = getMyTycoon() end
    return myTycoon
end

local function getTycoonRemote()
    local t = tycoon()
    if not t then return nil end
    local remotes = t:FindFirstChild("Remotes")
    if not remotes then return nil end
    return remotes:FindFirstChild("Ascend") 
        or remotes:FindFirstChild("Evolve") 
        or remotes:FindFirstChild("Rebirth")
        or remotes:FindFirstChild("InvestorRebirth")
end

-- 1. СКУПЩИК КНОПОК БАЗЫ
local buyLock = {}
RunService.Heartbeat:Connect(function()
    if not ENABLED.AutoBuyUpgrades then return end
    local t = tycoon()
    local purchases = t and t:FindFirstChild("Purchases")
    if not purchases then return end
    for _, obj in ipairs(purchases:GetDescendants()) do
        if not ENABLED.AutoBuyUpgrades then break end
        if not (obj:IsA("RemoteFunction") and obj.Name == "Purchase") then continue end
        local btn = obj.Parent
        if not btn or buyLock[obj] or btn:GetAttribute("Purchased") == true or btn:GetAttribute("Enabled") == false or btn:GetAttribute("Shown") == false then continue end
        buyLock[obj] = true
        task.spawn(function()
            pcall(function() obj:InvokeServer(false) end)
            task.wait(0.5)
            buyLock[obj] = nil
        end)
    end
end)

-- 2. ПРОКАЧКА СТЕНДОВ
local STAND_NAMES = {"LemonDash", "Lemon Depot", "Lemon Labs", "Lemon Stand", "Lemon Trading", "Lemon Republic", "Lemon Robotics", "LemonX"}
local cachedStandRFs = {}
local function buildStandRFCache()
    cachedStandRFs = {}
    local t = tycoon()
    local purchases = t and t:FindFirstChild("Purchases")
    if not purchases then return end
    for _, standName in ipairs(STAND_NAMES) do
        local standFolder = purchases:FindFirstChild(standName)
        local standModel = standFolder and standFolder:FindFirstChild(standName)
        if standModel then
            for _, obj in ipairs(standModel:GetDescendants()) do
                if obj:IsA("RemoteFunction") and obj.Name == "Upgrade" then
                    cachedStandRFs[standName] = obj
                    break
                end
            end
        end
    end
end

RunService.Heartbeat:Connect(function()
    if not ENABLED.AutoUpgradeStands then return end
    if not next(cachedStandRFs) then buildStandRFCache() return end
    for _, upgradeRF in pairs(cachedStandRFs) do
        task.spawn(function() pcall(function() upgradeRF:InvokeServer(5) end) end)
    end
end)

-- 3. АВТО-СБОР ФРУКТОВ С ТЕЛЕПОРТОМ
task.spawn(function()
    while true do
        task.wait(FRUIT_CYCLE_DELAY)
        if not ENABLED.AutoCollectFruit or not root then continue end
        local detectors = {}
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj.Name == "LemonTree" then
                for _, fruit in ipairs(obj:GetDescendants()) do
                    if fruit.Name == "Fruit" then
                        local clickPart = fruit:FindFirstChild("ClickPart")
                        local cd = clickPart and clickPart:FindFirstChildOfClass("ClickDetector")
                        if cd then table.insert(detectors, { cd = cd, part = clickPart }) end
                    end
                end
            end
        end
        if #detectors > 0 then
            local saved = root.CFrame
            for _, entry in ipairs(detectors) do
                if not ENABLED.AutoCollectFruit or not entry.part or not entry.part.Parent then break end
                pcall(function() root.CFrame = CFrame.new(entry.part.Position + Vector3.new(0, 3, 0)) end)
                task.wait(0.08)
                pcall(fireclickdetector, entry.cd)
                task.wait(0.08)
            end
            pcall(function() root.CFrame = saved end)
        end
    end
end)

-- 4. АВТО-СБОР ДРОПОВ
task.spawn(function()
    local core = RS:WaitForChild("Core", 10)
    local signal = core and core:FindFirstChild("RemoteSignal")
    local request = core and core:FindFirstChild("RemoteRequest")
    local newDrop = signal and signal:FindFirstChild("CashDropService.New")
    local redeemDrop = request and request:FindFirstChild("CashDropService.Redeem")
    if not newDrop or not redeemDrop then return end
    newDrop.OnClientEvent:Connect(function(id)
        if ENABLED.AutoCollectDrops and id ~= nil then
            task.spawn(function() pcall(function() return redeemDrop:InvokeServer(id) end) end)
        end
    end)
end)

-- СОЗДАНИЕ НЕЗАВИСИМОГО ГРАФИЧЕСКОГО МЕНЮ PATCH HUB
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = game:GetService("CoreGui") or player:WaitForChild("PlayerGui")

local Frame = Instance.new("Frame")
Frame.Parent = ScreenGui
Frame.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
Frame.Position = UDim2.new(0.3, 0, 0.25, 0)
Frame.Size = UDim2.new(0, 520, 0, 340)
Frame.Active = true
Frame.Draggable = true

local UICorner = Instance.new("UICorner")
UICorner.Parent = Frame
UICorner.CornerRadius = UDim.new(0, 10)

local LeftPanel = Instance.new("Frame")
LeftPanel.Parent = Frame
LeftPanel.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
LeftPanel.Size = UDim2.new(0, 140, 1, 0)
local Corner2 = Instance.new("UICorner") Corner2.Parent = LeftPanel

local Title = Instance.new("TextLabel")
Title.Parent = LeftPanel
Title.Text = "Patch Hub"
Title.Font = Enum.Font.SourceSansBold
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 22
Title.Position = UDim2.new(0, 15, 0, 15)
Title.Size = UDim2.new(0, 110, 0, 30)

local TabBtn = Instance.new("TextButton")
TabBtn.Parent = LeftPanel
TabBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
TabBtn.Position = UDim2.new(0, 10, 0, 60)
TabBtn.Size = UDim2.new(0, 120, 0, 35)
TabBtn.Text = "Farm"
TabBtn.Font = Enum.Font.SourceSansBold
TabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
TabBtn.TextSize = 16
local Corner3 = Instance.new("UICorner") Corner3.Parent = TabBtn

local Container = Instance.new("ScrollingFrame")
Container.Parent = Frame
Container.BackgroundTransparency = 1
Container.Position = UDim2.new(0, 155, 0, 20)
Container.Size = UDim2.new(0, 350, 0, 300)
Container.CanvasSize = UDim2.new(0, 0, 0, 450)
Container.ScrollBarThickness = 4

local function createToggle(name, key)
    local tFrame = Instance.new("Frame")
    tFrame.Parent = Container
    tFrame.Size = UDim2.new(1, -10, 0, 40)
    tFrame.BackgroundTransparency = 1
    tFrame.Position = UDim2.new(0, 0, 0, (#Container:GetChildren() - 1) * 45)
    
    local label = Instance.new("TextLabel")
    label.Parent = tFrame
    label.Text = name
    label.Font = Enum.Font.SourceSans
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.TextSize = 16
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Size = UDim2.new(0, 200, 1, 0)
    label.BackgroundTransparency = 1
    
    local btn = Instance.new("TextButton")
    btn.Parent = tFrame
    btn.Size = UDim2.new(0, 45, 0, 22)
    btn.Position = UDim2.new(1, -55, 0, 9)
    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    btn.Text = ""
    local c = Instance.new("UICorner") c.Parent = btn c.CornerRadius = UDim.new(0, 11)
    
    btn.MouseButton1Click:Connect(function()
        ENABLED[key] = not ENABLED[key]
        btn.BackgroundColor3 = ENABLED[key] and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(60, 60, 60)
    end)
end

-- СОЗДАЕМ ТУМБЛЕРЫ ДЛЯ ВСЕХ ФУНКЦИЙ
createToggle("Auto Buy Upgrades", "AutoBuyUpgrades")
createToggle("Auto Upgrade Stands", "AutoUpgradeStands")
createToggle("Auto Collect Fruit", "AutoCollectFruit")
createToggle("Auto Collect Drops", "AutoCollectDrops")

-- СОЗДАЕМ НАШУ НАДЕЖНУЮ АППАРАТНУЮ КНОПКУ МГНОВЕННОГО ВОЗРОЖДЕНИЯ
local btnFrame = Instance.new("Frame")
btnFrame.Parent = Container
btnFrame.Size = UDim2.new(1, -10, 0, 50)
btnFrame.BackgroundTransparency = 1
btnFrame.Position = UDim2.new(0, 0, 0, 185)

local rebBtn = Instance.new("TextButton")
rebBtn.Parent = btnFrame
rebBtn.Size = UDim2.new(1, 0, 0, 40)
rebBtn.Position = UDim2.new(0, 0, 0, 5)
rebBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
rebBtn.Font = Enum.Font.SourceSansBold
rebBtn.Text = "Instant Rebirth (Investor)"
rebBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
rebBtn.TextSize = 16
local cBtn = Instance.new("UICorner") cBtn.Parent = rebBtn cBtn.CornerRadius = UDim.new(0, 8)

rebBtn.MouseButton1Click:Connect(function()
    pcall(function()
        local remote = getTycoonRemote()
        if remote then
            if remote:IsA("RemoteFunction") then task.spawn(function() remote:InvokeServer() end)
            elseif remote:IsA("RemoteEvent") then remote:FireServer() end
        end
        task.wait(0.4)
        local pGui = player:FindFirstChild("PlayerGui")
        if pGui then
            VirtualUser:CaptureController()
            for step = 1, 2 do
                for _, gui in ipairs(pGui:GetDescendants()) do
