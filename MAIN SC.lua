local CalmLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/IcantAffordSynapse/calmlib/refs/heads/main/src.lua"))()

local window = CalmLib:win("sub 2 vaehz")
local section1 = window:tab("Autofarm", "rbxassetid://109121102062195")
local section2 = window:tab("Settings", "rbxassetid://99579688577014")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local plr = Players.LocalPlayer

getgenv().farming = false
getgenv().farmspeed = 1
getgenv().farmsettings = {
    purchase = true,
    upgrade = true,
    collect = true,
    cashdrop = true,
    fruit = true
}
getgenv().antiafk = true

local function getChar()
    local char = plr.Character
    if char and char:FindFirstChild("Head") and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
        return char
    end
    return nil
end

local tycoon
local function findTycoon()
    for _, v in pairs(workspace:GetChildren()) do
        if typeof(v) == "Instance" and v.Name:find("Tycoon") then
            local owner = v:FindFirstChild("Owner")
            if owner and owner.Value == plr then
                return v
            end
        end
    end
    return nil
end

task.spawn(function()
    while not tycoon do
        tycoon = findTycoon()
        if not tycoon then task.wait(1) end
    end
end)

repeat task.wait() until tycoon

local suffixes = {
    K = 1e3, M = 1e6, B = 1e9, T = 1e12,
    Qd = 1e15, Qn = 1e18, Sx = 1e21, Sxd = 1e21,
    Sp = 1e24, Oc = 1e27, No = 1e30, Dc = 1e33,
}

local function decodeValue(str)
    if typeof(str) ~= "string" then return nil end
    local clean = str:gsub("[\226\128\128-\226\128\143]", "")
    local numStr, suffix = clean:match("%$([%d%,%.]+)(%a*)")
    if not numStr then return nil end

    local num = tonumber((numStr:gsub(",", "")))
    if not num then return nil end

    if suffix == "" then return num end

    local multiplier = suffixes[suffix]
    if not multiplier then
        suffix = suffix:sub(1,1):upper() .. suffix:sub(2):lower()
        multiplier = suffixes[suffix]
    end

    return multiplier and (num * multiplier) or num
end

local PurchasesFold = tycoon:WaitForChild("Purchases", 10)

tycoon.Remotes.PhoneOffer.OnClientEvent:Connect(function()
    if not getgenv().farming then return end
    pcall(function()
        tycoon.Remotes.PhoneOffer:FireServer("Accept")
    end)
end)

-- ======================== AUTOFARM TAB ========================
section1:slider("Farm Speed", 1, 10, 1, function(val)
    getgenv().farmspeed = math.clamp(val, 1, 10)
end)

section1:toggle("Autofarm", false, function(bool)
    getgenv().farming = bool
    if not getgenv().farming then return end

    -- Collect loop (fully speed controlled)
    task.spawn(function()
        while getgenv().farming do
            if getgenv().farmsettings.collect then
                local stands = tycoon.Values and tycoon.Values.Income and tycoon.Values.Income.Streams
                if stands then
                    for _, v in pairs(stands:GetChildren()) do
                        pcall(function()
                            tycoon.Remotes.WakeIncomeStream:InvokeServer(v.Name)
                        end)
                    end
                end
            end
            task.wait(1 / getgenv().farmspeed)
        end
    end)

    -- Main farm loop (everything fires based on speed)
    task.spawn(function()
        while getgenv().farming do
            local char = getChar()
            if not char then
                task.wait(0.3)
            else
                local head = char.Head
                local delay = 1 / getgenv().farmspeed

                -- Auto Purchase
                if getgenv().farmsettings.purchase and PurchasesFold then
                    pcall(function()
                        for _, fold in pairs(PurchasesFold:GetChildren()) do
                            if fold:FindFirstChild("Buttons") then
                                for _, nFold in pairs(fold.Buttons:GetChildren()) do
                                    if nFold:IsA("Folder") then
                                        for _, btn in pairs(nFold:GetChildren()) do
                                            if btn:GetAttribute("Shown") and btn:GetAttribute("Enabled") and not btn:GetAttribute("Purchased") then
                                                local price = decodeValue(btn.Button.Gui.Price.Text)
                                                local curbalance = decodeValue(tostring(plr.leaderstats.Cash.Value))
                                                if price and curbalance and price <= curbalance then
                                                    firetouchinterest(head, btn.Button, true)
                                                    firetouchinterest(head, btn.Button, false)
                                                end
                                            end
                                        end
                                    elseif nFold:IsA("Model") then
                                        if nFold:GetAttribute("Shown") and nFold:GetAttribute("Enabled") and not nFold:GetAttribute("Purchased") then
                                            local price = decodeValue(nFold.Button.Gui.Price.Text)
                                            local curbalance = decodeValue(tostring(plr.leaderstats.Cash.Value))
                                            if price and curbalance and price <= curbalance then
                                                firetouchinterest(head, nFold.Button, true)
                                                firetouchinterest(head, nFold.Button, false)
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end)
                end

                -- Auto Upgrade
                if getgenv().farmsettings.upgrade and PurchasesFold then
                    pcall(function()
                        for _, fold in pairs(PurchasesFold:GetChildren()) do
                            local target = fold:FindFirstChild(fold.Name)
                            if target and target:GetAttribute("Enabled") then
                                local upgrade = target:FindFirstChild(fold.Name)
                                if upgrade and upgrade:FindFirstChild("Upgrade") then
                                    upgrade.Upgrade:InvokeServer(1)
                                end
                            end
                        end
                    end)
                end

                -- Auto Cash Drop
                if getgenv().farmsettings.cashdrop then
                    pcall(function()
                        for _, v in pairs(workspace.CashDrops:GetChildren()) do
                            firetouchinterest(head, v, true)
                            firetouchinterest(head, v, false)
                        end
                    end)
                end

                -- Auto Fruit
                if getgenv().farmsettings.fruit then
                    pcall(function()
                        local trees = tycoon.Constant and tycoon.Constant.Trees
                        if trees then
                            for _, tree in pairs(trees:GetChildren()) do
                                for _, lemon in pairs(tree:GetChildren()) do
                                    if lemon.Name == "Fruit" and lemon:FindFirstChild("ClickPart") then
                                        local detector = lemon.ClickPart:FindFirstChildOfClass("ClickDetector")
                                        if detector then
                                            fireclickdetector(detector)
                                        end
                                    end
                                end
                            end
                        end
                    end)
                end

                task.wait(delay)
            end
        end
    end)
end)

section1:label("Settings:")

section1:toggle("Auto Purchase", true, function(v)
    getgenv().farmsettings.purchase = v
end)
section1:toggle("Auto Collect", true, function(v)
    getgenv().farmsettings.collect = v
end)
section1:toggle("Auto Upgrade", true, function(v)
    getgenv().farmsettings.upgrade = v
end)
section1:toggle("Auto Cash Drop", true, function(v)
    getgenv().farmsettings.cashdrop = v
end)
section1:toggle("Auto Pickup Fruit", true, function(v)
    getgenv().farmsettings.fruit = v
end)

-- ======================== SETTINGS TAB ========================
section2:toggle("Disable 3D Rendering", false, function(v)
    RunService:Set3dRenderingEnabled(not v)
end)

section2:toggle("Anti AFK", true, function(v)
    getgenv().antiafk = v
end)

plr.Idled:Connect(function()
    if not getgenv().antiafk then return end
    VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
end)
