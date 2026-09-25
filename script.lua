local MacLib = loadstring(game:HttpGet("https://github.com/biggaboy212/Maclib/releases/latest/download/maclib.txt"))()

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

local FRUIT_CYCLE_DELAY    = 5
local PHONE_OFFER_RESPONSE = "Accept"
local POWER_NAMES = { "UpgradeStack", "BuyNext", "Manage", "WalkSpeed", "ClickFruitValue" }

local INCOME_STREAMS = {
    "LemonDash", "LemonDepot", "LemonLabs",
    "LemonTrading", "LemonRepublic", "LemonRobotics",
    "LemonStand", "LemonX",
}

local ENABLED = {
    AutoBuyUpgrades   = false,
    AutoCollectFruit  = false,
    AutoCollectDrops  = false,
    AutoClick         = false,
    AutoPhoneOffer    = false,
    AutoUpgradeStands = false,
    AutoRebirth       = false,
    AutoAscend        = false,
    AutoEvolve        = false,
    AutoPowerUpgrade  = false,
    AutoOfflineCash   = false,
    AutoTimeCash      = false,
    AutoEarnerBoost   = false,
    AutoMinigameRace  = false,
    AutoMinigameTrade = false,
    AutoCashVine      = false,
    AntiAFK           = false,
    BoostFPS          = false,
}

local STATS = {
    upgradesBought = 0,
    fruitCollected = 0,
    dropsCollected = 0,
    clicks         = 0,
    phoneOffers    = 0,
    standsUpgraded = 0,
    rebirths       = 0,
    ascends        = 0,
    evolves        = 0,
    powerUpgrades  = 0,
    racesWon       = 0,
    tradesWon      = 0,
    vineCollected  = 0,
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

local function rem(name)
    local t = tycoon()
    if not t then return nil end
    local remotes = t:FindFirstChild("Remotes")
    if not remotes then return nil end
    return remotes:FindFirstChild(name)
end

local function getCash()
    local ls = player:FindFirstChild("leaderstats")
    if not ls then return 0 end
    for _, v in ipairs(ls:GetChildren()) do
        if v:IsA("NumberValue") or v:IsA("IntValue") then
            local n = v.Name:lower()
            if n:find("cash") or n:find("money") or n:find("lemon") or n:find("coin") then
                return v.Value
            end
        end
    end
    local best = 0
    for _, v in ipairs(ls:GetChildren()) do
        if (v:IsA("NumberValue") or v:IsA("IntValue")) and v.Value > best then best = v.Value end
    end
    return best
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
            if btn:GetAttribute("Purchased") == true  then continue end
            if btn:GetAttribute("Enabled") == false then continue end
            if btn:GetAttribute("Shown")     == false then continue end
            buyLock[obj] = true
            task.spawn(function()
                pcall(function() obj:InvokeServer(false) end)
                STATS.upgradesBought += 1
                task.wait(1)
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
                local ok = pcall(function() upgradeRF:InvokeServer(5) end)
                if ok then STATS.standsUpgraded += 1 end
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
            local ok = pcall(fireclickdetector, entry.cd)
            if ok then STATS.fruitCollected += 1 end
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
            local ok = pcall(function() return redeemDrop:InvokeServer(id) end)
            if ok then STATS.dropsCollected += 1 end
        end)
    end)
end)

local function runAutoCashDrops()
    while true do
        task.wait(4)
    end
end

task.spawn(runAutoUpgrades)
task.spawn(runAutoUpgradeStands)
task.spawn(runAutoFruit)
task.spawn(runAutoCashDrops)

-- ИНИЦИАЛИЗАЦИЯ ИНТЕРФЕЙСА MACLIB
local Window = MacLib:CreateWindow({
    Title = "Patch Hub",
    Subtitle = "Sell Lemons",
    Size = UDim2.fromOffset(550, 350),
    Drag = true
})

local Tab = Window:CreateTab({ Name = "Farm", Icon = "rbxassetid://4483345998" })

Tab:CreateToggle({
    Name = "Auto Buy Upgrades",
    Default = false,
    Callback = function(state) ENABLED.AutoBuyUpgrades = state end
})

Tab:CreateToggle({
    Name = "Auto Click Income",
    Default = false,
    Callback = function(state) ENABLED.AutoClick = state end
})

Tab:CreateToggle({
    Name = "Auto Upgrade Stands",
    Default = false,
    Callback = function(state) ENABLED.AutoUpgradeStands = state end
})

Tab:CreateToggle({
    Name = "Auto Collect Fruit",
    Default = false,
    Callback = function(state) ENABLED.AutoCollectFruit = state end
})

Tab:CreateToggle({
    Name = "Auto Collect Drops",
    Default = false,
    Callback = function(state) ENABLED.AutoCollectDrops = state end
})

-- ВИЗУАЛЬНАЯ ЗАМЕНА СЛАЙДЕРА НА КНОПКУ МГНОВЕННОГО ВОЗРОЖДЕНИЯ В 1 КЛИК
Tab:CreateButton({
    Name = "Instant Rebirth (Investor)",
    Callback = function()
        local rebirthRF = rem("Ascend") or rem("Evolve") or rem("Rebirth") or rem("InvestorRebirth")
        if rebirthRF then
            if rebirthRF:IsA("RemoteFunction") then
                pcall(function() rebirthRF:InvokeServer("Confirm") end)
                pcall(function() rebirthRF:InvokeServer(true) end)
            elseif rebirthRF:IsA("RemoteEvent") then
                pcall(function() rebirthRF:FireServer("Confirm") end)
                pcall(function() rebirthRF:FireServer(true) end)
            end
            STATS.rebirths += 1
        end
