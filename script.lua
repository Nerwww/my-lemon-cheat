local Players    = game:GetService("Players")
local workspace  = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local RS         = game:GetService("ReplicatedStorage")
local VirtualUser= game:GetService("VirtualUser")

local player = Players.LocalPlayer
local char   = player.Character or player.CharacterAdded:Wait()
local root   = char:WaitForChild("HumanoidRootPart")

player.CharacterAdded:Connect(function(c)
    char = c
    root = c:WaitForChild("HumanoidRootPart")
end)

local FRUIT_CYCLE_DELAY = 4

-- ВСЕ ФУНКЦИИ АВТОМАТИЧЕСКИ ВКЛЮЧЕНЫ
local ENABLED = {
    AutoBuyUpgrades   = true,
    AutoCollectFruit  = true,
    AutoCollectDrops  = true,
    AutoUpgradeStands = true,
    AutoRebirth       = true,
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

local myTycoon = nil
task.spawn(function()
    for _ = 1, 20 do
        myTycoon = getMyTycoon()
        if myTycoon then break end
        task.wait(0.5)
    end
end)

local function tycoon()
    if not myTycoon then myTycoon = getMyTycoon() end
    return myTycoon
end

local buyLock = {}

local function runAutoUpgrades()
    while not myTycoon do task.wait(0.5) end
    RunService.Heartbeat:Connect(function()
        if not ENABLED.AutoBuyUpgrades then return end
        local t = tycoon()
        if not t then return end
        local purchases = t:FindFirstChild("Purchases")
        if not purchases then return end
        for _, obj in ipairs(purchases:GetDescendants()) do
            if not ENABLED.AutoBuyUpgrades then break end
            if not (obj:IsA("RemoteFunction") and obj.Name == "Purchase") then continue end
            local btn = obj.Parent
            if not btn then continue end
            if buyLock[obj] then continue end
            if btn:GetAttribute("Purchased") == true then continue end
            if btn:GetAttribute("Enabled") == false then continue end
            if btn:GetAttribute("Shown") == false then continue end
            buyLock[obj] = true
            task.spawn(function()
                pcall(function() obj:InvokeServer(false) end)
                task.wait(0.5)
                buyLock[obj] = nil
            end)
        end
    end)
end

local STAND_NAMES = {
    "LemonDash", "Lemon Depot", "Lemon Labs",
    "Lemon Stand", "Lemon Trading", "Lemon Republic",
    "Lemon Robotics", "LemonX",
}

local cachedStandRFs = {}

local function buildStandRFCache()
    cachedStandRFs = {}
    local t = tycoon()
    if not t then return end
    local purchases = t:FindFirstChild("Purchases")
    if not purchases then return end
    for _, standName in ipairs(STAND_NAMES) do
        local standFolder = purchases:FindFirstChild(standName)
        if not standFolder then continue end
        local standModel = standFolder:FindFirstChild(standName)
        if not standModel then continue end
        for _, obj in ipairs(standModel:GetDescendants()) do
            if obj:IsA("RemoteFunction") and obj.Name == "Upgrade" then
                cachedStandRFs[standName] = obj
                break
            end
        end
    end
end

local function runAutoUpgradeStands()
    while not myTycoon do task.wait(0.5) end
    buildStandRFCache()
    RunService.Heartbeat:Connect(function()
        if not ENABLED.AutoUpgradeStands then return end
        if not next(cachedStandRFs) then buildStandRFCache() return end
        for _, upgradeRF in pairs(cachedStandRFs) do
            task.spawn(function()
                pcall(function() upgradeRF:InvokeServer(5) end)
            end)
        end
    end)
end

local function runAutoFruit()
    while true do
        task.wait(FRUIT_CYCLE_DELAY)
        if not ENABLED.AutoCollectFruit then continue end
        local detectors = {}
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj.Name == "LemonTree" then
                for _, fruit in ipairs(obj:GetDescendants()) do
                    if fruit.Name == "Fruit" then
                        local clickPart = fruit:FindFirstChild("ClickPart")
                        if clickPart then
                            local cd = clickPart:FindFirstChildOfClass("ClickDetector")
                            if cd then table.insert(detectors, { cd = cd, part = clickPart }) end
                        end
                    end
                end
            end
        end
        if #detectors == 0 then continue end
        local saved = root.CFrame
        for _, entry in ipairs(detectors) do
            if not ENABLED.AutoCollectFruit then break end
            if not entry.part or not entry.part.Parent then continue end
            pcall(function() root.CFrame = CFrame.new(entry.part.Position + Vector3.new(0, 3, 0)) end)
            task.wait(0.1)
            pcall(fireclickdetector, entry.cd)
            task.wait(0.15)
        end
        pcall(function() root.CFrame = saved end)
    end
end

task.spawn(function()
    local core = RS:WaitForChild("Core", 10)
    if not core then return end
    local signal  = core:FindFirstChild("RemoteSignal")
    local request = core:FindFirstChild("RemoteRequest")
    if not signal or not request then return end
    local newDrop    = signal:FindFirstChild("CashDropService.New")
    local redeemDrop = request:FindFirstChild("CashDropService.Redeem")
    if not newDrop or not redeemDrop then return end
    newDrop.OnClientEvent:Connect(function(id)
        if not ENABLED.AutoCollectDrops then return end
        if id == nil then return end
        task.spawn(function()
            pcall(function() return redeemDrop:InvokeServer(id) end)
        end)
    end)
end)

-- ХИТРЫЙ ТАЙМЕР НА КЛИК ПО КООРДИНАТАМ ЭКРАНА (РАЗ В 30 СЕКУНД)
task.spawn(function()
    while true do
        task.wait(30)
        if ENABLED.AutoRebirth then
            local t = tycoon()
            if t then
                local remotes = t:FindFirstChild("Remotes")
                if remotes then
                    -- Шаг 1: Активируем открытие окна через стандартные сетевые ивенты
                    local targetRemote = remotes:FindFirstChild("Ascend") or remotes:FindFirstChild("Evolve") or remotes:FindFirstChild("Rebirth") or remotes:FindFirstChild("InvestorRebirth")
                    if targetRemote then
                        pcall(function() targetRemote:FireServer() end)
                    end
                    
                    -- Шаг 2: Ждем, пока окно появится, и эмулируем аппаратный клик мыши по UI
                    task.wait(0.6)
                    pcall(function()
                        local pGui = player:FindFirstChild("PlayerGui")
                        if pGui then
                            for _, gui in ipairs(pGui:GetDescendants()) do
                                -- Ищем именно ту зеленую кнопку подтверждения из вашего скриншота
                                if gui:IsA("TextButton") and (gui.Text:find("Возрождение") or gui.Text:find("Ascend") or gui.Name:lower():find("confirm")) then
                                    if gui.IsVisible or (gui.Parent:IsA("GuiObject") and gui.Parent.Visible) then
                                        -- Вычисляем её центр на вашем мониторе/экране
                                        local absPos = gui.AbsolutePosition
                                        local absSize = gui.AbsoluteSize
                                        local clickX = absPos.X + (absSize.X / 2)
                                        local clickY = absPos.Y + (absSize.Y / 2) + 50 -- Учитываем смещение верхней панели Roblox
                                        
                                        -- Физический виртуальный клик мышкой по кнопке
                                        VirtualUser:CaptureController()
                                        VirtualUser:ClickButton1(Vector2.new(clickX, clickY))
                                    end
                                end
                            end
                        end
                    end)
                end
            end
        end
    end
end)

task.spawn(runAutoUpgrades)
task.spawn(runAutoUpgradeStands)
task.spawn(runAutoFruit)

print("[-] Скрипт с аппаратным обходом кликов GUI запущен!")
