-- ========== MAJESTY STORE v8.7.0 - FINAL COMPLETE ==========
-- All features | No NaN | Sliders work | VTeleport full | Teleport full

repeat task.wait() until game:IsLoaded()

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/sametexe001/sametlibs/refs/heads/main/Kiwisense/Library.lua"))()

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local VIM = game:GetService("VirtualInputManager")

repeat task.wait() until LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")

-- ================================================================
-- STATE VARIABLES
-- ================================================================
local AutoMS_Running = false
local autoSell_UI = false
local asSelling = false
local espEnabled = false
local espCache = {}
local boxPadding = 4
local ESP_INTERVAL = 0.05
local _espAccum = 0
local aimbotEnabled = false
local aimbotMode = "Camera"
local aimbotFOV = 250
local aimbotSmooth = 8
local aimbotTarget = "Head"
local aimbotKeybind = Enum.UserInputType.MouseButton2
local isBindingKey = false
local aimbotMaxDist = 100
local espMaxDist = 100
local aimbotStatusLbl = nil
local vFlyEnabled = false
local vFlySpeed = 60
local vFlyConn = nil
local vFlyUp = false
local vFlyDown = false
local espBoxColor = Color3.fromRGB(0, 255, 136)
local espNameColor = Color3.fromRGB(255, 255, 255)
local safeMode = false
local safeModeActive = false
local lastHealth = 100
local sellStatusLbl_ref = nil
local sellItemLbl_ref = nil

-- ================================================================
-- AUTO SELL ENGINE CONFIG
-- ================================================================
local CFG = {
    WATER_WAIT = 20,
    COOK_WAIT = 46,
    ITEM_WATER = "Water",
    ITEM_SUGAR = "Sugar Block Bag",
    ITEM_GEL = "Gelatin",
    ITEM_EMPTY = "Empty Bag",
    ITEM_MS_SMALL = "Small Marshmallow Bag",
    ITEM_MS_MEDIUM = "Medium Marshmallow Bag",
    ITEM_MS_LARGE = "Large Marshmallow Bag",
    SELL_RADIUS = 10,
}

local patRemotes = game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents", 10)
local storePurchaseRE = patRemotes and patRemotes:WaitForChild("StorePurchase", 10)
local rpcRE = patRemotes and patRemotes:WaitForChild("RPC", 10)

local isBusy = false
local isRunning = false
local patStats = {small = 0, medium = 0, large = 0}
local totalSold = 0
local rpcQueue = {}

local fullyRunning = false
local fullyTarget = 10
local fullySavedPos = nil
local NPC_MS_POS = Vector3.new(510.061, 4.476, 600.548)

local BUY_ITEMS = {
    {name = "Gelatin", display = "Gelatin"},
    {name = "Sugar Block Bag", display = "Sugar Block Bag"},
    {name = "Water", display = "Water"},
}
local buyQty = {1, 1, 1}

-- ================================================================
-- UTILITY FUNCTIONS
-- ================================================================
local function countItem(name)
    local n = 0
    for _, t in ipairs(LocalPlayer.Backpack:GetChildren()) do
        if t.Name == name then n = n + 1 end
    end
    local ch = LocalPlayer.Character
    if ch then
        for _, t in ipairs(ch:GetChildren()) do
            if t:IsA("Tool") and t.Name == name then n = n + 1 end
        end
    end
    return n
end

local function totalMS()
    return patStats.small + patStats.medium + patStats.large
end

local function countAllMS()
    return countItem(CFG.ITEM_MS_SMALL) + countItem(CFG.ITEM_MS_MEDIUM) + countItem(CFG.ITEM_MS_LARGE)
end

local function getEquippableMS()
    if countItem(CFG.ITEM_MS_SMALL) > 0 then return CFG.ITEM_MS_SMALL end
    if countItem(CFG.ITEM_MS_MEDIUM) > 0 then return CFG.ITEM_MS_MEDIUM end
    if countItem(CFG.ITEM_MS_LARGE) > 0 then return CFG.ITEM_MS_LARGE end
    return nil
end

local function hasAllIngredients()
    return countItem(CFG.ITEM_WATER) >= 1 and countItem(CFG.ITEM_SUGAR) >= 1 and countItem(CFG.ITEM_GEL) >= 1
end

local function equipTool(name)
    local ch = LocalPlayer.Character
    if not ch then return false end
    local hum = ch:FindFirstChildOfClass("Humanoid")
    local t = LocalPlayer.Backpack:FindFirstChild(name)
    if hum and t then
        hum:EquipTool(t)
        task.wait(0.2)
        return true
    end
    return false
end

local function unequipAll()
    local ch = LocalPlayer.Character
    if not ch then return end
    local hum = ch:FindFirstChildOfClass("Humanoid")
    if hum then hum:UnequipTools() end
end

local function firePromptNearby(radius)
    local ch = LocalPlayer.Character
    local root = ch and ch:FindFirstChild("HumanoidRootPart")
    if not root then return end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            local part = obj.Parent
            if part and not part:IsA("BasePart") then
                part = part:FindFirstChildOfClass("BasePart") or part
            end
            local checkPart = part
            if checkPart and checkPart:IsA("BasePart") then
                if (root.Position - checkPart.Position).Magnitude <= (radius or 8) then
                    pcall(function() fireproximityprompt(obj) end)
                end
            end
        end
    end
end

local function cookInteract(toolName, radius)
    if toolName then
        equipTool(toolName)
        task.wait(0.2)
    end
    firePromptNearby(radius or 8)
    task.wait(0.1)
    pcall(function()
        VIM:SendKeyEvent(true, Enum.KeyCode.E, false, game)
        task.wait(0.15)
        VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game)
    end)
    task.wait(0.1)
    firePromptNearby(radius or 8)
end

if rpcRE then
    rpcRE.OnClientEvent:Connect(function(_, tblArg)
        if type(tblArg) ~= "table" then return end
        local v1 = tblArg[1]
        local v2 = tblArg[2]
        local msg = tostring(v1 or ""):lower()
        if v2 == "TextLabel" and tonumber(v1) then
            table.insert(rpcQueue, {type = "timer", secs = tonumber(v1)})
            return
        end
        if msg:find("boil") or msg:find("water") then
            table.insert(rpcQueue, {type = "wait_boil"})
        elseif msg:find("sugar") then
            table.insert(rpcQueue, {type = "add_sugar"})
        elseif msg:find("gelatin") then
            table.insert(rpcQueue, {type = "add_gelatin"})
        elseif msg:find("cook") then
            table.insert(rpcQueue, {type = "wait_cook"})
        elseif msg:find("bag") then
            table.insert(rpcQueue, {type = "bag_result"})
        end
    end)
end

local function waitRPC(instrType, timeout)
    local start = tick()
    while tick() - start < timeout do
        if not isRunning then return nil end
        for i = 1, #rpcQueue do
            local inst = rpcQueue[i]
            if inst and inst.type == instrType then
                table.remove(rpcQueue, i)
                return inst
            end
        end
        task.wait(0.1)
    end
    return nil
end

local function popTimer()
    for i = 1, #rpcQueue do
        local v = rpcQueue[i]
        if v.type == "timer" then
            table.remove(rpcQueue, i)
            return v.secs
        end
    end
    return nil
end

-- ================================================================
-- AUTO SELL ENGINE
-- ================================================================
local function isNearNPC(radius)
    local ch = LocalPlayer.Character
    local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    return (hrp.Position - NPC_MS_POS).Magnitude <= (radius or CFG.SELL_RADIUS + 5)
end

local function waitCharacterStable(timeout)
    local ch = LocalPlayer.Character
    local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
    if not hrp then
        task.wait(1)
        return
    end
    local deadline = tick() + (timeout or 2.5)
    local lastPos = hrp.Position
    repeat
        task.wait(0.25)
        local delta = (hrp.Position - lastPos).Magnitude
        lastPos = hrp.Position
        if delta < 0.5 then return end
    until tick() >= deadline
end

local function equipToolWithRetry(name, maxRetry)
    for i = 1, (maxRetry or 5) do
        local ok = equipTool(name)
        if ok then
            task.wait(0.3)
            local ch = LocalPlayer.Character
            if ch then
                for _, t in ipairs(ch:GetChildren()) do
                    if t:IsA("Tool") and t.Name == name then
                        return true
                    end
                end
            end
        end
        task.wait(0.4)
    end
    return false
end

local SELL_HOLD_DURATION = 1.8
local SELL_HOLD_RETRIES = 5

local function trySellOne(msName, setStatus2)
    local bS = countItem(CFG.ITEM_MS_SMALL)
    local bM = countItem(CFG.ITEM_MS_MEDIUM)
    local bL = countItem(CFG.ITEM_MS_LARGE)

    setStatus2("Equip: " .. msName, Color3.fromRGB(100, 180, 255))
    local equipped = equipToolWithRetry(msName, 4)
    if not equipped then
        setStatus2("Gagal equip", Color3.fromRGB(210, 40, 40))
        unequipAll()
        task.wait(0.4)
        return false
    end
    task.wait(0.5)

    local sold = false
    for attempt = 1, SELL_HOLD_RETRIES do
        setStatus2("Jual: Hold E (" .. attempt .. "/" .. SELL_HOLD_RETRIES .. ")", Color3.fromRGB(50, 210, 110))
        firePromptNearby(CFG.SELL_RADIUS + 5)
        task.wait(0.1)
        pcall(function() VIM:SendKeyEvent(true, Enum.KeyCode.E, false, game) end)
        local holdElapsed = 0
        while holdElapsed < SELL_HOLD_DURATION do
            task.wait(0.1)
            holdElapsed = holdElapsed + 0.1
            local diff = (bS - countItem(CFG.ITEM_MS_SMALL)) + (bM - countItem(CFG.ITEM_MS_MEDIUM)) + (bL - countItem(CFG.ITEM_MS_LARGE))
            if diff > 0 then
                pcall(function() VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game) end)
                totalSold = totalSold + diff
                sold = true
                break
            end
        end
        pcall(function() VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game) end)
        if sold then break end
        task.wait(0.3)
        setStatus2("Retry " .. attempt, Color3.fromRGB(255, 155, 35))
        task.wait(0.4)
    end
    unequipAll()
    task.wait(0.3)
    return sold
end

local function doAutoSell(setStatus2)
    local msTotal = countAllMS()
    if msTotal == 0 then
        setStatus2("Tidak ada MS", Color3.fromRGB(160, 160, 180))
        task.wait(0.8)
        return
    end
    setStatus2("Siap jual " .. msTotal .. " MS", Color3.fromRGB(50, 210, 110))
    task.wait(0.4)

    while countAllMS() > 0 do
        local msName = getEquippableMS()
        if not msName then break end
        if not isNearNPC(CFG.SELL_RADIUS + 8) then
            setStatus2("Teleport ke NPC", Color3.fromRGB(255, 155, 35))
            fullyTeleport(NPC_MS_POS)
            task.wait(1.2)
        end
        trySellOne(msName, setStatus2)
        task.wait(0.35)
    end
    unequipAll()
    setStatus2("Selesai jual", Color3.fromRGB(50, 210, 110))
    task.wait(1)
end

-- ================================================================
-- AUTO BUY ENGINE
-- ================================================================
local function doAutoBuy(setStatus2, overrideQty)
    if not storePurchaseRE then
        pcall(function()
            local rs = game:GetService("ReplicatedStorage")
            local re = rs:WaitForChild("RemoteEvents", 8)
            if re then storePurchaseRE = re:WaitForChild("StorePurchase", 8) end
        end)
    end
    if not storePurchaseRE then
        setStatus2("Remote tidak ditemukan", Color3.fromRGB(210, 40, 40))
        return
    end

    for idx, item in ipairs(BUY_ITEMS) do
        local qty = overrideQty or buyQty[idx] or 1
        if qty > 0 then
            setStatus2("Beli " .. item.display .. " x" .. qty, Color3.fromRGB(100, 180, 255))
            for i = 1, qty do
                pcall(function() storePurchaseRE:FireServer(item.name, 1) end)
                task.wait(0.3)
            end
        end
        task.wait(0.2)
    end
    setStatus2("Selesai beli", Color3.fromRGB(80, 220, 130))
    task.wait(1)
end

-- ================================================================
-- AUTO COOK ENGINE (FIXED - TIMER DETECTION)
-- ================================================================
local statusValue, phaseValue, timerValue

local function _setStatus(msg, color)
    if statusValue then
        statusValue.Text = msg
        statusValue.TextColor3 = color or Color3.fromRGB(0, 255, 136)
    end
end

local function _setPhase(txt)
    if phaseValue then phaseValue.Text = txt end
end

local function _setTimer(txt)
    if timerValue then timerValue.Text = txt end
end

local function countdown(secs, phaseTxt, color)
    for i = secs, 1, -1 do
        if not isRunning then return false end
        if statusValue then
            statusValue.Text = phaseTxt
            statusValue.TextColor3 = color or Color3.fromRGB(0, 255, 136)
        end
        if phaseValue then phaseValue.Text = phaseTxt end
        if timerValue then timerValue.Text = i .. "s" end
        task.wait(1)
    end
    return true
end

-- Fixed timer detection using CoreGui or ScreenGui
local function getTimerFromScreen()
    local success, result = pcall(function()
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        if not playerGui then return nil end
        
        -- Cari di semua ScreenGui
        for _, gui in ipairs(playerGui:GetChildren()) do
            if gui:IsA("ScreenGui") then
                -- Cari timer label (biasanya TextLabel dengan angka)
                local timerLabels = {}
                local function searchForTimer(obj)
                    if obj:IsA("TextLabel") or obj:IsA("TextButton") then
                        local text = obj.Text or ""
                        -- Cek apakah teksnya angka (timer)
                        if text:match("^%d+$") or text:match("^%d+s$") or text:match("^%d+%.%d+$") then
                            table.insert(timerLabels, {obj = obj, text = text})
                        end
                    end
                    for _, child in ipairs(obj:GetChildren()) do
                        searchForTimer(child)
                    end
                end
                searchForTimer(gui)
                
                -- Ambil angka terbesar (kemungkinan timer)
                for _, label in ipairs(timerLabels) do
                    local num = tonumber(label.text:match("%d+"))
                    if num and num > 0 then
                        return num
                    end
                end
            end
        end
        return nil
    end)
    return success and result or nil
end

-- Fixed wait for timer using multiple methods
local function waitForTimer(maxWait, phaseName)
    local startTime = tick()
    local lastTimerValue = nil
    local stableCount = 0
    
    while tick() - startTime < maxWait do
        if not isRunning then return nil end
        
        -- Method 1: Cek dari rpcQueue (dari remote event)
        local timerSecs = popTimer()
        if timerSecs and timerSecs > 0 then
            return timerSecs
        end
        
        -- Method 2: Cek dari UI screen
        local screenTimer = getTimerFromScreen()
        if screenTimer and screenTimer > 0 then
            if lastTimerValue == screenTimer then
                stableCount = stableCount + 1
                if stableCount >= 3 then
                    return screenTimer
                end
            else
                lastTimerValue = screenTimer
                stableCount = 0
            end
        end
        
        -- Update display
        if screenTimer then
            _setTimer(screenTimer .. "s")
        end
        
        task.wait(0.5)
    end
    
    -- Fallback: pakai default wait time
    if phaseName == "boil" then return CFG.WATER_WAIT end
    if phaseName == "cook" then return CFG.COOK_WAIT end
    return nil
end

-- Fixed doOneCook dengan timer detection yang lebih baik
local function doOneCook()
    isBusy = true
    table.clear(rpcQueue)

    local snapS = countItem(CFG.ITEM_MS_SMALL)
    local snapM = countItem(CFG.ITEM_MS_MEDIUM)
    local snapL = countItem(CFG.ITEM_MS_LARGE)

    -- Step 1: Water
    _setStatus("Masukkan Water...", Color3.fromRGB(100, 180, 255))
    _setPhase("Water")
    cookInteract(CFG.ITEM_WATER)
    task.wait(1.5)
    
    _setStatus("Mendidih...", Color3.fromRGB(80, 150, 255))
    local boilSecs = waitForTimer(35, "boil")
    if not boilSecs then boilSecs = CFG.WATER_WAIT end
    
    if not countdown(boilSecs, "Mendidih", Color3.fromRGB(80, 150, 255)) then
        isBusy = false
        return false
    end

    -- Step 2: Sugar
    _setStatus("Masukkan Sugar...", Color3.fromRGB(255, 220, 100))
    _setPhase("Sugar")
    waitRPC("add_sugar", 10)
    if not isRunning then
        isBusy = false
        return false
    end
    cookInteract(CFG.ITEM_SUGAR)
    task.wait(1)
    
    -- Step 3: Gelatin
    _setStatus("Masukkan Gelatin...", Color3.fromRGB(255, 200, 50))
    _setPhase("Gelatin")
    waitRPC("add_gelatin", 10)
    if not isRunning then
        isBusy = false
        return false
    end
    cookInteract(CFG.ITEM_GEL)
    task.wait(1)

    -- Step 4: Cook
    _setStatus("Memasak...", Color3.fromRGB(80, 140, 255))
    local cookSecs = waitForTimer(55, "cook")
    if not cookSecs then cookSecs = CFG.COOK_WAIT end
    
    if not countdown(cookSecs, "Memasak", Color3.fromRGB(80, 140, 255)) then
        isBusy = false
        return false
    end

    -- Step 5: Take MS
    _setStatus("Ambil MS...", Color3.fromRGB(100, 160, 255))
    _setPhase("Ambil")
    waitRPC("bag_result", 15)

    -- Cari Empty Bag
    local bag
    local t2 = 0
    repeat
        bag = LocalPlayer.Backpack:FindFirstChild(CFG.ITEM_EMPTY)
        if not bag then
            local char = LocalPlayer.Character
            if char then
                bag = char:FindFirstChild(CFG.ITEM_EMPTY)
            end
        end
        task.wait(0.3)
        t2 = t2 + 0.3
    until bag or t2 > 10

    if not bag then
        _setStatus("No Empty Bag!", Color3.fromRGB(255, 60, 90))
        isBusy = false
        return false
    end

    cookInteract(CFG.ITEM_EMPTY)

    -- Wait for MS to appear
    local waitMS = 0
    local newS, newM, newL
    repeat
        task.wait(0.3)
        waitMS = waitMS + 0.3
        newS = countItem(CFG.ITEM_MS_SMALL) - snapS
        newM = countItem(CFG.ITEM_MS_MEDIUM) - snapM
        newL = countItem(CFG.ITEM_MS_LARGE) - snapL
    until (newS > 0 or newM > 0 or newL > 0) or waitMS > 12

    if newS > 0 then
        patStats.small = patStats.small + newS
    elseif newM > 0 then
        patStats.medium = patStats.medium + newM
    elseif newL > 0 then
        patStats.large = patStats.large + newL
    else
        patStats.small = patStats.small + 1
    end

    _setPhase("Complete #" .. totalMS())
    _setTimer("Done")
    isBusy = false
    return true
end

local function autoMSLoop()
    isRunning = true
    while isRunning do
        if not hasAllIngredients() then
            _setStatus("BAHAN HABIS!", Color3.fromRGB(255, 60, 90))
            isRunning = false
            break
        end
        local ok, err = pcall(doOneCook)
        if not ok then
            _setStatus("ERROR: " .. (err or "?"), Color3.fromRGB(255, 60, 90))
            task.wait(2)
        end
        if isRunning then task.wait(0.3) end
    end
    isRunning = false
    AutoMS_Running = false
    _setStatus("OFF", Color3.fromRGB(255, 60, 90))
    if phaseValue then phaseValue.Text = "Water" end
    if timerValue then timerValue.Text = "0s" end
    isBusy = false
end


-- ================================================================
-- TELEPORT ENGINE
-- ================================================================
function fullyTeleport(targetPos)
    local ch = LocalPlayer.Character
    if not ch then return end
    local hrp = ch:FindFirstChild("HumanoidRootPart")
    if hrp then
        pcall(function()
            hrp.CFrame = CFrame.new(targetPos + Vector3.new(0, 2, 0))
        end)
    end
    task.wait(0.5)
end

-- ================================================================
-- AUTO FULLY ENGINE
-- ================================================================
local function doAutoFully(setFullyStatus)
    fullyRunning = true

    while fullyRunning do
        setFullyStatus("Teleport ke NPC...", Color3.fromRGB(100, 180, 255))
        fullyTeleport(NPC_MS_POS)
        if not fullyRunning then break end

        setFullyStatus("Beli bahan...", Color3.fromRGB(100, 180, 255))
        doAutoBuy(setFullyStatus, fullyTarget)
        if not fullyRunning then break end
        task.wait(0.5)

        if fullySavedPos then
            setFullyStatus("Teleport ke Apart...", Color3.fromRGB(148, 80, 255))
            fullyTeleport(fullySavedPos)
        end
        if not fullyRunning then break end
        task.wait(1.5)

        unequipAll()
        table.clear(rpcQueue)
        setFullyStatus("Masak...", Color3.fromRGB(82, 130, 255))
        isRunning = true

        while fullyRunning and hasAllIngredients() do
            doOneCook()
            if fullyRunning then task.wait(0.3) end
        end

        isRunning = false
        if not fullyRunning then break end

        if countAllMS() > 0 then
            setFullyStatus("Jual MS...", Color3.fromRGB(52, 210, 110))
            fullyTeleport(NPC_MS_POS)
            task.wait(1.5)
            doAutoSell(setFullyStatus)
        end
        task.wait(0.5)
    end

    fullyRunning = false
    isRunning = false
    AutoMS_Running = false
end

-- ================================================================
-- KIWISENSE GUI SETUP
-- ================================================================
local Window = Library:Window({
    Name = "MAJESTY STORE LEAKED",
    Version = "v8.7.0",
    Logo = "135215559087473",
    FadeSpeed = 0.25,
})

local Watermark = Library:Watermark("MAJESTY STORE LEAKEDDDD", "135215559087473")

local Pages = {
    ["Auto MS"] = Window:Page({Name = "auto ms", Icon = "111178525804834", Columns = 2}),
    ["General"] = Window:Page({Name = "general", Icon = "115907015044719", Columns = 2}),
    ["Teleport"] = Window:Page({Name = "teleport", Icon = "136623465713368", Columns = 1}),
    ["VTeleport"] = Window:Page({Name = "vteleport", Icon = "109463522861706", Columns = 1}),
    ["Auto Fully"] = Window:Page({Name = "auto fully", Icon = "137300573942266", Columns = 2}),
    ["Aimbot"] = Window:Page({Name = "aimbot", Icon = "111386589037485", Columns = 1}),
    ["Settings"] = Window:Page({Name = "settings", Icon = "103863157706913", Columns = 2})
}

-- ================================================================
-- PAGE: AUTO MS
-- ================================================================
do
    local LeftSection = Pages["Auto MS"]:Section({Name = "auto marshmallow", Icon = "103174889897193", Side = 1})
    local RightSection = Pages["Auto MS"]:Section({Name = "inventory tracker", Icon = "96491224522405", Side = 2})
    local SellSection = Pages["Auto MS"]:Section({Name = "auto sell", Icon = "126028986879491", Side = 2})
    local BuySection = Pages["Auto MS"]:Section({Name = "buy bahan", Icon = "116339777575852", Side = 1})

    LeftSection:Label("Status", "Left")
    local statusLbl = LeftSection:Label("OFF", "Left")
    statusLbl.TextColor3 = Color3.fromRGB(255, 60, 90)

    LeftSection:Label("Phase", "Left")
    local phaseLbl = LeftSection:Label("Water", "Left")
    phaseLbl.TextColor3 = Color3.fromRGB(0, 196, 255)

    LeftSection:Label("Timer", "Left")
    local timerLbl = LeftSection:Label("0s", "Left")
    timerLbl.TextColor3 = Color3.fromRGB(255, 215, 0)

    statusValue = statusLbl
    phaseValue = phaseLbl
    timerValue = timerLbl

    LeftSection:Toggle({
        Name = "auto cook",
        Flag = "AutoCook",
        Default = false,
        Callback = function(Value)
            if Value then
                if not isRunning then
                    isRunning = true
                    _setStatus("STARTING", Color3.fromRGB(255, 200, 0))
                    task.spawn(autoMSLoop)
                end
            else
                isRunning = false
                AutoMS_Running = false
                _setStatus("OFF", Color3.fromRGB(255, 60, 90))
                if phaseValue then phaseValue.Text = "Water" end
                if timerValue then timerValue.Text = "0s" end
            end
        end
    })

    LeftSection:Label("Hotkey: PageUp = toggle ON/OFF", "Left")

    -- Inventory Tracker
    RightSection:Label("Water", "Left")
    local waterCountLbl = RightSection:Label("0", "Left")
    RightSection:Label("Gelatin", "Left")
    local gelatinCountLbl = RightSection:Label("0", "Left")
    RightSection:Label("Sugar Block", "Left")
    local sugarCountLbl = RightSection:Label("0", "Left")
    RightSection:Label("Empty Bag", "Left")
    local bagCountLbl = RightSection:Label("0", "Left")

    -- Auto Sell
    SellSection:Toggle({
        Name = "auto sell",
        Flag = "AutoSell",
        Default = false,
        Callback = function(Value)
            autoSell_UI = Value
        end
    })

    SellSection:Label("Sell Status", "Left")
    local sellStatLbl = SellSection:Label("OFF", "Left")
    sellStatLbl.TextColor3 = Color3.fromRGB(255, 60, 90)
    sellStatusLbl_ref = sellStatLbl

    SellSection:Label("Item", "Left")
    local sellItmLbl = SellSection:Label("-", "Left")
    sellItemLbl_ref = sellItmLbl

    -- Buy Bahan - SLIDER VERSION (FIXED NO NaN)
    local buyWater = 1
    local buyGelatin = 1
    local buySugar = 1

    BuySection:Slider({
        Name = "water qty",
        Flag = "BuyWaterQty",
        Min = 0,
        Default = 1,
        Max = 50,
        Callback = function(Value)
            buyWater = Value
            buyQty[3] = Value
        end
    })

    BuySection:Slider({
        Name = "gelatin qty",
        Flag = "BuyGelatinQty",
        Min = 0,
        Default = 1,
        Max = 50,
        Callback = function(Value)
            buyGelatin = Value
            buyQty[1] = Value
        end
    })

    BuySection:Slider({
        Name = "sugar qty",
        Flag = "BuySugarQty",
        Min = 0,
        Default = 1,
        Max = 50,
        Callback = function(Value)
            buySugar = Value
            buyQty[2] = Value
        end
    })

    BuySection:Button({
        Name = "buy items",
        Callback = function()
            buyQty[1] = buyGelatin
            buyQty[2] = buySugar
            buyQty[3] = buyWater
            task.spawn(function()
                doAutoBuy(function(msg, col)
                    Library:Notification({
                        Name = "Buy Status",
                        Description = msg,
                        Duration = 2,
                        Icon = "116339777575852"
                    })
                end, nil)
            end)
        end
    })

    -- Inventory updater
    task.spawn(function()
        while true do
            pcall(function()
                if waterCountLbl then waterCountLbl.Text = tostring(countItem("Water")) end
                if gelatinCountLbl then gelatinCountLbl.Text = tostring(countItem("Gelatin")) end
                if sugarCountLbl then sugarCountLbl.Text = tostring(countItem("Sugar Block Bag")) end
                if bagCountLbl then bagCountLbl.Text = tostring(countItem("Empty Bag")) end
            end)
            task.wait(1)
        end
    end)
end

-- ================================================================
-- PAGE: GENERAL (ESP & VEHICLE FLY)
-- ================================================================
do
    local ESPSection = Pages["General"]:Section({Name = "player esp", Icon = "135799335731002", Side = 1})
    local VFlySection = Pages["General"]:Section({Name = "vehicle fly", Icon = "109463522861706", Side = 2})

    local function createESP(player)
        if espCache[player] then
            for _, o in pairs(espCache[player]) do pcall(function() o:Remove() end) end
            espCache[player] = nil
        end
        local box = Drawing.new("Square")
        box.Thickness = 1
        box.Color = espBoxColor
        box.Filled = false
        box.Visible = false
        local nameL = Drawing.new("Text")
        nameL.Text = player.Name
        nameL.Size = 10
        nameL.Font = 1
        nameL.Color = espNameColor
        nameL.Outline = true
        nameL.Center = true
        nameL.Visible = false
        local hpBg = Drawing.new("Square")
        hpBg.Thickness = 1
        hpBg.Color = Color3.fromRGB(30, 30, 30)
        hpBg.Filled = true
        hpBg.Visible = false
        local hpFl = Drawing.new("Square")
        hpFl.Thickness = 1
        hpFl.Color = Color3.fromRGB(0, 255, 80)
        hpFl.Filled = true
        hpFl.Visible = false
        local dL = Drawing.new("Text")
        dL.Size = 10
        dL.Font = 1
        dL.Color = Color3.fromRGB(180, 220, 255)
        dL.Outline = true
        dL.Center = true
        dL.Visible = false
        espCache[player] = {box, nameL, hpBg, hpFl, dL}
    end

    local function removeESP(player)
        if espCache[player] then
            for _, o in pairs(espCache[player]) do pcall(function() o:Remove() end) end
            espCache[player] = nil
        end
    end

    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then createESP(plr) end
    end

    Players.PlayerAdded:Connect(function(p)
        if p ~= LocalPlayer then
            p.CharacterAdded:Connect(function() task.wait(0.5); if espEnabled then createESP(p) end end)
            if espEnabled then createESP(p) end
        end
    end)
    Players.PlayerRemoving:Connect(removeESP)

    ESPSection:Toggle({
        Name = "player esp",
        Flag = "PlayerESP",
        Default = false,
        Callback = function(Value)
            espEnabled = Value
            if espEnabled then
                for _, plr in pairs(Players:GetPlayers()) do
                    if plr ~= LocalPlayer then createESP(plr) end
                end
            else
                for _, drawings in pairs(espCache) do
                    for _, o in pairs(drawings) do pcall(function() o.Visible = false end) end
                end
            end
        end
    })

    ESPSection:Label("Box | Username | HP Bar | Distance", "Left")

    ESPSection:Slider({
        Name = "esp max distance",
        Flag = "ESPMaxDist",
        Min = 10,
        Default = 100,
        Max = 500,
        Callback = function(Value)
            espMaxDist = Value
        end
    })

    -- ESP Render Loop (FIXED - HIDE when truly out of frame)
    RunService.Heartbeat:Connect(function(dt)
        if not espEnabled then
            for _, drawings in pairs(espCache) do
                for _, o in pairs(drawings) do
                    pcall(function() o.Visible = false end)
                end
            end
            return
        end
        _espAccum = _espAccum + dt
        if _espAccum < ESP_INTERVAL then return end
        _espAccum = 0
        local myChar = LocalPlayer.Character
        local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        local myPos = myHRP and myHRP.Position
        local camera = workspace.CurrentCamera
        local viewportX = camera.ViewportSize.X
        local viewportY = camera.ViewportSize.Y
        
        for player, drawings in pairs(espCache) do
            local box = drawings[1]
            local nameL = drawings[2]
            local hpBg = drawings[3]
            local hpFl = drawings[4]
            local dL = drawings[5]
            
            local function hideAll()
                if box then box.Visible = false end
                if nameL then nameL.Visible = false end
                if hpBg then hpBg.Visible = false end
                if hpFl then hpFl.Visible = false end
                if dL then dL.Visible = false end
            end
            
            local char = player.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local head = char and char:FindFirstChild("Head")
            
            if not (char and hum and root and head and hum.Health > 0) then
                hideAll()
            else
                local dist3D = myPos and (root.Position - myPos).Magnitude or 0
                if myPos and espMaxDist > 0 and dist3D > espMaxDist then
                    hideAll()
                else
                    -- Konversi ke posisi layar
                    local rootPos, rootOnScreen = camera:WorldToViewportPoint(root.Position)
                    local headPos, headOnScreen = camera:WorldToViewportPoint(head.Position)
                    
                    -- Hitung dimensi box
                    local height = math.abs(headPos.Y - rootPos.Y) * 1.7 + (boxPadding * 2)
                    local width = height * 0.55
                    local boxX = rootPos.X - width / 2
                    local boxY = headPos.Y - boxPadding
                    
                    -- CEK APAKAH BOX MASIH DI DALAM LAYAR
                    local isBoxVisible = (boxX + width > 0 and boxX < viewportX and boxY + height > 0 and boxY < viewportY)
                    
                    if not (rootOnScreen and headOnScreen and isBoxVisible) then
                        hideAll()
                    else
                        if box then
                            box.Color = espBoxColor
                            box.Size = Vector2.new(width, height)
                            box.Position = Vector2.new(boxX, boxY)
                            box.Visible = true
                        end
                        if nameL then
                            nameL.Text = player.Name
                            nameL.Color = espNameColor
                            nameL.Position = Vector2.new(rootPos.X, boxY - 14)
                            nameL.Visible = true
                        end
                        if hpBg then
                            local hpR = hum.MaxHealth > 0 and math.clamp(hum.Health / hum.MaxHealth, 0, 1) or 1
                            hpBg.Size = Vector2.new(4, height - 4)
                            hpBg.Position = Vector2.new(boxX - 8, boxY + 2)
                            hpBg.Visible = true
                            if hpFl then
                                hpFl.Color = Color3.fromRGB(255 * (1 - hpR), 255 * hpR, 80)
                                hpFl.Size = Vector2.new(2, (height - 6) * hpR)
                                hpFl.Position = Vector2.new(boxX - 7, boxY + 3 + (height - 6) * (1 - hpR))
                                hpFl.Visible = true
                            end
                        end
                        if dL then
                            dL.Text = math.floor(dist3D) .. "m"
                            dL.Position = Vector2.new(rootPos.X, boxY + height + 2)
                            dL.Visible = true
                        end
                    end
                end
            end
        end
    end)

    -- Vehicle Fly
    local vfStatusLbl
    VFlySection:Toggle({
        Name = "vehicle fly",
        Flag = "VehicleFly",
        Default = false,
        Callback = function(Value)
            vFlyEnabled = Value
            if vFlyEnabled then
                if vFlyConn then vFlyConn:Disconnect(); vFlyConn = nil end
                vFlyConn = RunService.RenderStepped:Connect(function(dt)
                    local char = LocalPlayer.Character
                    if not char then return end
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    local seat = hum and hum.SeatPart
                    if not seat then
                        if vfStatusLbl then vfStatusLbl.Text = "Tidak di kendaraan"; vfStatusLbl.TextColor3 = Color3.fromRGB(122, 143, 160) end
                        return
                    end
                    local model = seat:FindFirstAncestorOfClass("Model") or seat
                    local root = model.PrimaryPart or seat
                    if vfStatusLbl then vfStatusLbl.Text = "Terbang aktif"; vfStatusLbl.TextColor3 = Color3.fromRGB(0, 255, 136) end
                    local camCF = Camera.CFrame
                    local fwd = Vector3.new(camCF.LookVector.X, 0, camCF.LookVector.Z)
                    if fwd.Magnitude > 0.01 then fwd = fwd.Unit else fwd = Vector3.new(0, 0, -1) end
                    local rgt = Vector3.new(camCF.RightVector.X, 0, camCF.RightVector.Z)
                    if rgt.Magnitude > 0.01 then rgt = rgt.Unit else rgt = Vector3.new(1, 0, 0) end
                    local mv = Vector3.zero
                    if UserInputService:IsKeyDown(Enum.KeyCode.W) then mv = mv + fwd end
                    if UserInputService:IsKeyDown(Enum.KeyCode.S) then mv = mv - fwd end
                    if UserInputService:IsKeyDown(Enum.KeyCode.A) then mv = mv - rgt end
                    if UserInputService:IsKeyDown(Enum.KeyCode.D) then mv = mv + rgt end
                    if vFlyUp then mv = mv + Vector3.new(0, 1, 0) end
                    if vFlyDown then mv = mv - Vector3.new(0, 1, 0) end
                    pcall(function()
                        for _, p in pairs(model:GetDescendants()) do
                            if p:IsA("BasePart") then
                                p.AssemblyLinearVelocity = Vector3.zero
                                p.AssemblyAngularVelocity = Vector3.zero
                            end
                        end
                    end)
                    if mv.Magnitude > 0 then
                        mv = mv.Unit
                        local np = root.Position + mv * vFlySpeed * dt
                        local ld = Vector3.new(camCF.LookVector.X, 0, camCF.LookVector.Z)
                        if ld.Magnitude > 0.01 then ld = ld.Unit else ld = fwd end
                        pcall(function()
                            local cp = model:GetPivot()
                            local tcf = CFrame.new(np, np + ld)
                            local off = cp:ToObjectSpace(root.CFrame)
                            model:PivotTo(tcf * off:Inverse())
                        end)
                    end
                end)
            else
                if vFlyConn then vFlyConn:Disconnect(); vFlyConn = nil end
                vFlyUp = false
                vFlyDown = false
                if vfStatusLbl then vfStatusLbl.Text = "Tidak di kendaraan"; vfStatusLbl.TextColor3 = Color3.fromRGB(122, 143, 160) end
            end
        end
    })

    VFlySection:Label("Status", "Left")
    vfStatusLbl = VFlySection:Label("Tidak di kendaraan", "Left")
    vfStatusLbl.TextColor3 = Color3.fromRGB(122, 143, 160)

    VFlySection:Slider({
        Name = "fly speed",
        Flag = "VFlySpeed",
        Min = 10,
        Default = 60,
        Max = 300,
        Callback = function(Value)
            vFlySpeed = Value
        end
    })

    VFlySection:Label("E = Naik | Q = Turun | WASD = Steer", "Left")

    UserInputService.InputBegan:Connect(function(input, gpe)
        if not vFlyEnabled or gpe then return end
        if input.KeyCode == Enum.KeyCode.E then vFlyUp = true end
        if input.KeyCode == Enum.KeyCode.Q then vFlyDown = true end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.E then vFlyUp = false end
        if input.KeyCode == Enum.KeyCode.Q then vFlyDown = false end
    end)
end

-- ================================================================
-- BLINK TP (Kiwisense Version - Tampilan Sama Persis dengan Asli)
-- ================================================================
do
    local BlinkSection = Pages["General"]:Section({Name = "BLINK TP", Icon = "136623465713368", Side = 2})
    
    -- Info card (mirip blinkInfoCard asli)
    BlinkSection:Label("Tekan [T] untuk maju 6 studs saat blink aktif", "Left")
    
    -- Toggle dengan efek visual (mirip toggle switch asli)
    local blinkEnabled = false
    
    local blinkToggle = BlinkSection:Toggle({
        Name = "⚡ Blink TP  [T]",
        Flag = "BlinkTP",
        Default = false,
        Callback = function(Value)
            blinkEnabled = Value
        end
    })
    
    -- BLINK FUNCTION (SAME AS ORIGINAL)
    local function doBlink()
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if root then
            root.CFrame = root.CFrame + (root.CFrame.LookVector * 6)
        end
    end
    
    -- Keybind T (SAME AS ORIGINAL)
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode.T and blinkEnabled then
            doBlink()
        end
    end)
    
    -- Catatan tambahan
    BlinkSection:Label("Aktifkan toggle di atas, lalu tekan T untuk blink 6 studs", "Left")
end

-- ================================================================
-- PAGE: TELEPORT (FIXED - WAIT FOR RESPAWN)
-- ================================================================
do
    local TPSection = Pages["Teleport"]:Section({Name = "teleport locations", Icon = "136623465713368", Side = 1})

    local tpLocs = {
        {name="Dealership", x=753.20, y=4.63, z=437.04},
        {name="Jual/Beli Marshmellow", x=510.9961853027344, y=3.5872106552124023, z=598.3929443359375},
        {name="Tier", x=1094.7406005859375, y=3.188796043395996, z=158.09230041503906},
        {name="Casino", x=1154.863525390625, y=4.289375305175781, z=-46.8486328125},
        {name="Jual Casino", x=1017.5814819335938, y=4.545021533966064, z=-321.7923889160156},
        {name="GS Ujung", x=-465.51, y=4.79, z=360.47},
        {name="GS Mid", x=218.57, y=4.65, z=-173.54},
        {name="Apart 1 (Kompor)", x=1141.8009033203125, y=11.041934967041016, z=450.3515319824219},
        {name="Apart 2 (Kompor)", x=1142.488525390625, y=11.0384630731506348, z=421.6380920410156},
        {name="Apart 3 (Kompor)", x=984.08892822265620, y=11.029658317565918, z=248.8081359863281},
        {name="Apart 4 (Kompor)", x=984.09442138671880, y=11.064784049987793, z=220.2919158935547},
        {name="Apart 5 (Kompor)", x=925.53119628906250, y=11.016752243041992, z=39.36603775024414},
        {name="Apart 6 (Kompor)", x=896.86053466796880, y=11.042763710021973, z=38.65096664428711},
    }

    local tpDestination = nil
    local isRespawning = false

    -- Tunggu karakter respawn dan teleport
    local function onCharacterAdded(char)
        if not tpDestination then return end
        
        task.spawn(function()
            -- Tunggu karakter benar-benar stabil
            local hrp = char:WaitForChild("HumanoidRootPart", 15)
            local hum = char:WaitForChild("Humanoid", 15)
            
            if not hrp or not hum then
                tpDestination = nil
                return
            end
            
            -- Tunggu health penuh dan karakter tidak dalam keadaan mati
            repeat
                task.wait(0.1)
            until hum.Health > 0 and hum.Health == hum.MaxHealth
            
            -- Tunggu sedikit agar server sinkron
            task.wait(0.5)
            
            -- Teleport ke tujuan
            local success, err = pcall(function()
                hrp.CFrame = CFrame.new(tpDestination.x, tpDestination.y + 3, tpDestination.z)
            end)
            
            if success then
                if tpStatusValue then
                    tpStatusValue.Text = "ARRIVED"
                    tpStatusValue.TextColor3 = Color3.fromRGB(0, 255, 136)
                end
                task.wait(2)
                if tpStatusValue then
                    tpStatusValue.Text = "STANDBY"
                    tpStatusValue.TextColor3 = Color3.fromRGB(255, 215, 0)
                end
            else
                if tpStatusValue then
                    tpStatusValue.Text = "TP FAILED"
                    tpStatusValue.TextColor3 = Color3.fromRGB(255, 60, 90)
                end
            end
            
            tpDestination = nil
            isRespawning = false
        end)
    end

    -- Hook ke karakter
    if LocalPlayer.Character then
        onCharacterAdded(LocalPlayer.Character)
    end
    LocalPlayer.CharacterAdded:Connect(onCharacterAdded)

    -- Fungsi teleport utama
    local function tpTo(x, y, z)
        if isRespawning then
            Library:Notification({
                Name = "Teleport",
                Description = "Tunggu teleport sebelumnya selesai",
                Duration = 2,
                Icon = "97118059177470"
            })
            return
        end
        
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        
        if not char or not hum then
            -- Jika belum ada karakter, langsung set destination
            tpDestination = {x = x, y = y, z = z}
            return
        end
        
        -- Set destination dan bunuh karakter
        tpDestination = {x = x, y = y, z = z}
        isRespawning = true
        
        if tpStatusValue then
            tpStatusValue.Text = "KILL-RESPAWN-TP"
            tpStatusValue.TextColor3 = Color3.fromRGB(255, 215, 0)
        end
        
        -- Bunuh karakter
        if hum.Health > 0 then
            hum.Health = 0
        end
    end

    -- Status display
    TPSection:Label("Status", "Left")
    local tpStatLbl = TPSection:Label("STANDBY", "Left")
    tpStatLbl.TextColor3 = Color3.fromRGB(255, 215, 0)
    tpStatusValue = tpStatLbl

    TPSection:Label("Kill -> Respawn -> TP otomatis ke tujuan", "Left")
    TPSection:Label("Butuh 3-5 detik sampai karakter stabil", "Left")

    -- Location Buttons
    for i, loc in ipairs(tpLocs) do
        TPSection:Button({
            Name = loc.name,
            Callback = function()
                tpTo(loc.x, loc.y, loc.z)
            end
        })
    end
end

-- ================================================================
-- PAGE: VTELEPORT (FULL LOCATIONS + KOMPOR)
-- ================================================================
do
    local VehSection = Pages["VTeleport"]:Section({Name = "vehicle teleport", Icon = "109463522861706", Side = 1})
    local KomporSection = Pages["VTeleport"]:Section({Name = "kompor apartment", Icon = "103174889897193", Side = 1})

    local cachedSeat = nil

    local function updateSeatCache()
        local char = LocalPlayer.Character
        if not char then cachedSeat = nil return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        cachedSeat = hum and hum.SeatPart or nil
    end

    local function hookCharacter(char)
        local hum = char:WaitForChild("Humanoid", 10)
        if hum then
            hum:GetPropertyChangedSignal("SeatPart"):Connect(updateSeatCache)
            updateSeatCache()
        end
    end

    if LocalPlayer.Character then task.spawn(hookCharacter, LocalPlayer.Character) end
    LocalPlayer.CharacterAdded:Connect(hookCharacter)

    VehSection:Label("Tidak perlu mati | Bisa dipakai saat naik motor", "Left")
    
    VehSection:Label("Kendaraan", "Left")
    local vehStatusLbl = VehSection:Label("Tidak ditemukan", "Left")
    vehStatusLbl.TextColor3 = Color3.fromRGB(255, 60, 90)

    task.spawn(function()
        while true do
            task.wait(1)
            if cachedSeat then
                local vehModel = cachedSeat:FindFirstAncestorWhichIsA("Model")
                vehStatusLbl.Text = vehModel and vehModel.Name or cachedSeat.Name
                vehStatusLbl.TextColor3 = Color3.fromRGB(0, 220, 100)
            else
                vehStatusLbl.Text = "Tidak ditemukan"
                vehStatusLbl.TextColor3 = Color3.fromRGB(255, 60, 90)
            end
        end
    end)

    local function tpVehicle(x, y, z)
        if not cachedSeat then
            Library:Notification({Name = "Error", Description = "Tidak di kendaraan", Duration = 2, Icon = "97118059177470"})
            return
        end
        local vehModel = cachedSeat:FindFirstAncestorWhichIsA("Model")
        if vehModel and vehModel.PrimaryPart then
            vehModel:SetPrimaryPartCFrame(CFrame.new(x, y + 2, z))
        elseif cachedSeat then
            cachedSeat.CFrame = CFrame.new(x, y + 2, z)
        end
    end

    local vtpLocs = {
        {name="Dealership", x=753.20, y=4.63, z=437.04},
        {name="Jual/Beli Marshmellow", x=510.9961853027344, y=3.5872106552124023, z=598.3929443359375},
        {name="Tier", x=1094.7406005859375, y=3.188796043395996, z=158.09230041503906},
        {name="Casino", x=1154.863525390625, y=4.289375305175781, z=-46.8486328125},
        {name="Jual Casino", x=1017.5814819335938, y=4.545021533966064, z=-321.7923889160156},
        {name="GS Ujung", x=-465.51, y=4.79, z=360.47},
        {name="GS Mid", x=218.57, y=4.65, z=-173.54},
        {name="Safe", x=120.85433197021484, y=4.297231197357178, z=-587.6337280273438},
        {name="Apart 1 (rs 1)", x=1108.93, y=11.03, z=455.77},
        {name="Apart 2 (rs 2)", x=1109.15, y=11.04, z=427.29},
        {name="Apart 3 (gs tier 1)", x=1017.93, y=11.01, z=243.27},
        {name="Apart 4 (gs tier 2)", x=1018.19, y=11.03, z=214.68},
        {name="Apart 5 (job sampah 1)", x=931.02, y=11.05, z=72.18},
        {name="Apart 6 (job sampah 2)", x=902.45, y=11.01, z=72.21},
        {name="Box", x=-492.35, y=4.29, z=-38.15},
        {name="Pabrik Kentang", x=-493.88, y=4.67, z=-437.11},
        {name="Bank", x=-43.01, y=4.66, z=-353.96},
        {name="Cukur", x=67.62, y=4.67, z=-96.48},
        {name="Labas", x=-767.21, y=4.30, z=-13.43},
        {name="Doa Turf", x=-331.58, y=18.79, z=-462.96},
        {name="Gedung Tinggi", x=3.08, y=5.36, z=256.11},
        {name="YGZ Turf", x=8.30, y=17.82, z=288.99},
        {name="OGZ Turf", x=113.04, y=20.32, z=-509.80},
        {name="Donat", x=578.52, y=4.67, z=-352.95},
        {name="GS Binary", x=-280.05, y=4.68, z=257.84},
        {name="GS Drum", x=670.51, y=4.80, z=244.05},
        {name="RS", x=1065.33, y=4.29, z=547.58},
        {name="Jual Senjata", x=80.45, y=4.72, z=37.38},
        {name="Mall", x=-748.86, y=4.69, z=549.09},
    }
    

    for i, loc in ipairs(vtpLocs) do
        VehSection:Button({
            Name = loc.name,
            Callback = function()
                tpVehicle(loc.x, loc.y, loc.z)
            end
        })
    end

    local kompors = {
        {name="Kompor Apart 1", x=1141.8009033203125, y=11.041934967041016, z=450.3515319824219},
        {name="Kompor Apart 2", x=1142.488525390625, y=11.0384630731506348, z=421.6380920410156},
        {name="Kompor Apart 3", x=984.08892822265620, y=11.029658317565918, z=248.8081359863281},
        {name="Kompor Apart 4", x=984.09442138671880, y=11.064784049987793, z=220.2919158935547},
        {name="Kompor Apart 5", x=925.53119628906250, y=11.016752243041992, z=39.36603775024414},
        {name="Kompor Apart 6", x=896.86053466796880, y=11.042763710021973, z=38.65096664428711},
    }

    for i, k in ipairs(kompors) do
        KomporSection:Button({
            Name = k.name,
            Callback = function()
                tpVehicle(k.x, k.y, k.z)
            end
        })
    end
end

-- ================================================================
-- PAGE: AUTO FULLY
-- ================================================================
do
    local InfoSection = Pages["Auto Fully"]:Section({Name = "info", Icon = "137300573942266", Side = 1})
    local ApartSection = Pages["Auto Fully"]:Section({Name = "apart settings", Icon = "103174889897193", Side = 2})
    local TargetSection = Pages["Auto Fully"]:Section({Name = "target settings", Icon = "96491224522405", Side = 1})
    local ControlSection = Pages["Auto Fully"]:Section({Name = "controls", Icon = "116339777575852", Side = 2})

    local fullyStatusLbl = InfoSection:Label("Belum dimulai", "Left")
    fullyStatusLbl.TextColor3 = Color3.fromRGB(122, 143, 160)

    local apartList = {
        {name = "Apart 1", x = 1141.801, y = 11.042, z = 450.352},
        {name = "Apart 2", x = 1142.489, y = 11.038, z = 421.638},
        {name = "Apart 3", x = 984.089, y = 11.030, z = 248.808},
        {name = "Apart 4", x = 984.094, y = 11.064, z = 220.291},
    }
    fullySavedPos = Vector3.new(1141.801, 11.042, 450.352)

    ApartSection:Dropdown({
        Name = "pilih apart",
        Flag = "ApartSelect",
        Items = {"Apart 1", "Apart 2", "Apart 3", "Apart 4"},
        Default = "Apart 1",
        Callback = function(Value)
            for _, apart in ipairs(apartList) do
                if apart.name == Value then
                    fullySavedPos = Vector3.new(apart.x, apart.y, apart.z)
                    break
                end
            end
        end
    })

    TargetSection:Slider({
        Name = "target ms per loop",
        Flag = "FullyTarget",
        Min = 1,
        Default = 10,
        Max = 50,
        Callback = function(Value)
            fullyTarget = Value
        end
    })

    ControlSection:Button({
        Name = "start fully",
        Callback = function()
            if fullyRunning then return end
            fullyStatusLbl.Text = "Berjalan..."
            fullyStatusLbl.TextColor3 = Color3.fromRGB(0, 255, 136)
            task.spawn(function()
                doAutoFully(function(msg, col)
                    fullyStatusLbl.Text = msg
                    fullyStatusLbl.TextColor3 = col or Color3.fromRGB(122, 143, 160)
                end)
                fullyStatusLbl.Text = "Berhenti"
                fullyStatusLbl.TextColor3 = Color3.fromRGB(255, 60, 90)
            end)
        end
    })

    ControlSection:Button({
        Name = "stop fully",
        Callback = function()
            fullyRunning = false
            isRunning = false
            fullyStatusLbl.Text = "Dihentikan"
            fullyStatusLbl.TextColor3 = Color3.fromRGB(255, 215, 0)
        end
    })
end

-- ================================================================
-- PAGE: AIMBOT
-- ================================================================
do
    local MainSection = Pages["Aimbot"]:Section({Name = "aimbot settings", Icon = "111386589037485", Side = 1})

    MainSection:Toggle({
        Name = "enable aimbot",
        Flag = "AimbotEnabled",
        Default = false,
        Callback = function(Value)
            aimbotEnabled = Value
            if aimbotStatusLbl then
                aimbotStatusLbl.Text = Value and "ON" or "OFF"
                aimbotStatusLbl.TextColor3 = Value and Color3.fromRGB(0, 255, 136) or Color3.fromRGB(255, 60, 90)
            end
        end
    })

    MainSection:Label("Status", "Left")
    local aimStatLbl = MainSection:Label("OFF", "Left")
    aimStatLbl.TextColor3 = Color3.fromRGB(255, 60, 90)
    aimbotStatusLbl = aimStatLbl

    MainSection:Dropdown({
        Name = "target part",
        Flag = "AimbotTarget",
        Items = {"Head", "UpperTorso", "HumanoidRootPart"},
        Default = "Head",
        Callback = function(Value)
            aimbotTarget = Value
        end
    })

    MainSection:Slider({
        Name = "fov radius",
        Flag = "AimbotFOV",
        Min = 20,
        Default = 250,
        Max = 500,
        Callback = function(Value)
            aimbotFOV = Value
        end
    })

    MainSection:Slider({
        Name = "smooth",
        Flag = "AimbotSmooth",
        Min = 1,
        Default = 8,
        Max = 20,
        Callback = function(Value)
            aimbotSmooth = Value
        end
    })

    MainSection:Slider({
        Name = "max distance",
        Flag = "AimbotMaxDist",
        Min = 10,
        Default = 100,
        Max = 500,
        Callback = function(Value)
            aimbotMaxDist = Value
        end
    })

    MainSection:Label("Hold RMB to aimbot", "Left")

    local function getClosestTarget()
        local myChar = LocalPlayer.Character
        local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myHRP then return nil end
        local closest = nil
        local closestDist = aimbotFOV
        local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                local char = plr.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                local targetPart = char and char:FindFirstChild(aimbotTarget)
                if hum and targetPart and hum.Health > 0 then
                    local dist3D = (targetPart.Position - myHRP.Position).Magnitude
                    if dist3D <= aimbotMaxDist then
                        local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                        if onScreen then
                            local dist2D = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                            if dist2D < closestDist then
                                closestDist = dist2D
                                closest = targetPart
                            end
                        end
                    end
                end
            end
        end
        return closest
    end

    RunService.RenderStepped:Connect(function()
        if not aimbotEnabled then return end
        if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then return end
        local target = getClosestTarget()
        if target then
            local cf = CFrame.new(Camera.CFrame.Position, target.Position)
            Camera.CFrame = Camera.CFrame:Lerp(cf, 1 / aimbotSmooth)
        end
    end)
end

-- ================================================================
-- PAGE: SETTINGS (with Keybind for GUI Toggle)
-- ================================================================
do
    local SettingsSection = Pages["Settings"]:Section({Name = "gui settings", Icon = "103863157706913", Side = 1})

    local guiVisible = true
    local toggleKey = Enum.KeyCode.Z

    SettingsSection:Label("GUI Toggle Keybind", "Left")
    SettingsSection:Label("Default: Z", "Left")

    SettingsSection:Button({
        Name = "set custom keybind",
        Callback = function()
            SettingsSection:Label("Tekan sembarang tombol...", "Left")
            local connection
            connection = UserInputService.InputBegan:Connect(function(input, gpe)
                if gpe then return end
                if input.KeyCode ~= Enum.KeyCode.Unknown then
                    toggleKey = input.KeyCode
                    connection:Disconnect()
                    Library:Notification({
                        Name = "Keybind Set",
                        Description = "GUI toggle key: " .. tostring(toggleKey),
                        Duration = 3,
                        Icon = "116339777575852"
                    })
                end
            end)
            task.wait(5)
            if connection and connection.Connected then
                connection:Disconnect()
            end
        end
    })

    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == toggleKey then
            guiVisible = not guiVisible
            local mainFrame = Window.Items["MainFrame"]
            if mainFrame and mainFrame.Instance then
                mainFrame.Instance.Visible = guiVisible
            end
            if Watermark and Watermark.Instance then
                Watermark.Instance.Visible = guiVisible
            end
        end
    end)

    SettingsSection:Label("Tekan Z (atau keybind yang diset) untuk hide/show GUI", "Left")
end

-- ================================================================
-- AUTO SELL LOOP
-- ================================================================
task.spawn(function()
    while true do
        task.wait(0.5)
        if autoSell_UI and not asSelling then
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if char and hum and hum.Health > 0 and countAllMS() > 0 then
                asSelling = true
                doAutoSell(function(msg, col)
                    if sellStatusLbl_ref then
                        sellStatusLbl_ref.Text = msg
                        sellStatusLbl_ref.TextColor3 = col or Color3.fromRGB(0, 255, 136)
                    end
                    if sellItemLbl_ref then sellItemLbl_ref.Text = msg end
                end)
                asSelling = false
            end
        end
    end
end)

-- ================================================================
-- NOTIFICATION
-- ================================================================
Library:Notification({
    Name = "MAJESTY STORE LEAK",
    Description = "FULL COMPLETE | All Features | Press Z to hide GUI",
    Duration = 5,
    Icon = "116339777575852",
    IconColor = Color3.fromRGB(0, 255, 136)
})

print("MAJESTY STORE LEAKED BY DRKY")
