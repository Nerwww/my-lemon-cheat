local MacLib = loadstring(game:HttpGet("https://github.com"))()

local Players    = game:GetService("Players")
local workspace  = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local RS         = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local char   = player.Character or player.CharacterAdded:Wait()
local root   = char:WaitForChild("HumanoidRootPart")

local ENABLED = {
    AutoBuyUpgrades   = false,
    AutoCollectFruit  = false,
    AutoCollectDrops  = false,
    AutoClick         = false,
    AutoUpgradeStands = false,
    AutoAscend        = false,
    AutoEvolve        = false,
    AutoPowerUpgrade  = false,
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

local function rem(name)
    local t = tycoon()
    if not t then return nil end
    local remotes = t:FindFirstChild("Remotes")
    if not remotes then return nil end
    return remotes:FindFirstChild(name)
end

-- ИНИЦИАЛИЗАЦИЯ ИНТЕРФЕЙСА PATCH HUB
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

-- НАША НОВАЯ ОДИНОЧНАЯ КНОПКА МГНОВЕННОГО ВОЗРОЖДЕНИЯ В ОДИН КЛИК
Tab:CreateButton({
    Name = "Instant Rebirth (Investor)",
    Callback = function()
        local rebirthRF = rem("Ascend") or rem("Evolve") or rem("Rebirth") or remotes:FindFirstChild("InvestorRebirth")
        if rebirthRF then
            if rebirthRF:IsA("RemoteFunction") then
                pcall(function() rebirthRF:InvokeServer("Confirm") end)
                pcall(function() rebirthRF:InvokeServer(true) end)
            elseif rebirthRF:IsA("RemoteEvent") then
                pcall(function() rebirthRF:FireServer("Confirm") end)
                pcall(function() rebirthRF:FireServer(true) end)
            end
        end
    end
})

Tab:CreateToggle({
    Name = "Auto Ascend",
    Default = false,
    Callback = function(state) ENABLED.AutoAscend = state end
})

Tab:CreateToggle({
    Name = "Auto Evolve",
    Default = false,
    Callback = function(state) ENABLED.AutoEvolve = state end
})
