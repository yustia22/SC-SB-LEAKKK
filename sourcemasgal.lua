-- SILENT HUB v1.0 — PREMIUM DARK EDITION (FINAL UPDATE)
-- Dev: MASGAL x DRKY | Team: SILENT TEAM

-- ================================================================
-- BYPASS (UNCHANGED)
-- ================================================================
local MemoryStoreService = game:GetService("MemoryStoreService")
local lp = game.Players.LocalPlayer
local Bypass = { Hooks = {}, Stealth = {}, Patterns = {}, KillFakeHandshake = {} }
local function killFakeHandshake()
    local fake = MemoryStoreService:FindFirstChild("Hyphon_Check")
    if fake and fake:IsA("RemoteEvent") then pcall(function() fake:Destroy() end) end
end
killFakeHandshake()
Bypass.Hooks = {
    Trampoline = function(target, hook)
        local mt = getmetatable(target)
        if mt and mt.__index then local orig = mt.__index; mt.__index = function(self,k) if k=="FindPartOnRay" or k=="FireServer" then return hook end; return orig(self,k) end; return hook end
    end,
    Environment = function()
        local env = getfenv(2)
        setfenv(2, setmetatable({},{__index=function(t,k) if k=="debug" or k=="shared" then return nil end; return env[k] end, __newindex=function(t,k,v) if k~="LoadLibrary" then env[k]=v end end}))
    end,
    LightBypass = function()
        local mt = getmetatable(game:GetService("Lighting"))
        if mt and mt.__newindex then mt.__newindex = newcclosure(function(self,k,v) if k=="Brightness" or k=="GlobalShadows" or k=="FogEnd" then return rawset(self,k,v) end; return mt.__newindex(self,k,v) end) end
    end
}
Bypass.Stealth = {
    Memory = function()
        local mt = getmetatable(game)
        if mt and mt.__index then mt.__index = newcclosure(function(self,k) if k=="Players" or k=="Workspace" then return rawget(self,k) end; return mt.__index(self,k) end) end
    end,
    Terrain = function()
        local terrain = workspace:FindFirstChild("Terrain")
        if terrain then local mt=getmetatable(terrain); if mt and mt.__index then mt.__index=newcclosure(function(self,k) if k=="WaterWaveSize" or k=="WaterWaveSpeed" then return function() return 0 end end; return mt.__index(self,k) end) end end
    end
}
Bypass.Patterns = {
    Randomize = function()
        local mt = getmetatable(workspace)
        if mt and mt.__index then mt.__index=newcclosure(function(self,k) if k=="GetChildren" or k=="FindFirstChild" then return function(...) local r=mt.__index(self,k)(...); if type(r)=="table" then table.sort(r,function() return math.random()>.5 end) end; return r end end; return mt.__index(self,k) end) end
    end,
    Obfuscate = function()
        local mt = getmetatable(game:GetService("Players"))
        if mt and mt.__index then mt.__index=newcclosure(function(self,k) if k=="LocalPlayer" then return nil end; return mt.__index(self,k) end) end
    end,
}
Bypass.Executor = function()
    while true do
        pcall(Bypass.Hooks.Environment)
        pcall(Bypass.Stealth.Memory)
        pcall(Bypass.Patterns.Randomize)
        pcall(Bypass.Patterns.Obfuscate)
        pcall(Bypass.Hooks.LightBypass)
        pcall(Bypass.Stealth.Terrain)
        wait(math.random(2, 5))  -- Jeda lebih lama
    end
end
spawn(function()
    Bypass.Executor()
    Bypass.Hooks.Trampoline(workspace, function(...) return nil end)
    Bypass.Hooks.Trampoline(game:GetService("ReplicatedStorage"), function(...) return nil end)
end)

-- ========== LAYER 1: HIDE EXPLOIT TRACES (AMAN) ==========
pcall(function()
    local fenv = getfenv()
    local hideList = {
        "syn", "KRNL_LOADED", "EXECUTOR_NAME", "getexecutorname",
        "identifyexecutor", "queue_on_teleport", "rconsoleprint",
        "rconsoleerr", "rconsoleclear", "setclipboard", "getclipboard",
        "syn_request", "http_request", "request", "loadstring",
        "getgenv", "getrenv", "getfenv", "getgc", "getreg", "getcallingscript"
    }
    for _, name in ipairs(hideList) do
        if fenv[name] then fenv[name] = nil end
    end
end)

-- ========== LAYER 2: FAKE LAG MINIMAL (TIDAK MENCURIGAKAN) ==========
if not getgenv()._fakeLag then
    getgenv()._fakeLag = true
    task.spawn(function()
        while task.wait(0.3) do
            if math.random(1, 100) == 1 then
                task.wait(math.random(1, 5) / 1000)
            end
        end
    end)
end

-- ========== LAYER 3: KICK PROTECTION (TANPA HOOK) ==========
-- Hanya override fungsi Kick langsung
pcall(function()
    if LocalPlayer and type(LocalPlayer.Kick) == "function" then
        LocalPlayer.Kick = function() end
    end
end)

-- ========== LAYER 4: OVERRIDE GETCALLINGSCRIPT (SPOOF) ==========
pcall(function()
    local old = getcallingscript
    getcallingscript = function()
        local result = old()
        if result == nil then
            return game:GetService("StarterPlayer").StarterPlayerScripts
        end
        return result
    end
end)

-- ========== LAYER 5: SEMBUNYIKAN SCRIPT INI DARI GETGC ==========
-- Pindahin semua variabel ke local biar ga keliatan di GC
local _hiddenVars = {}

-- ========== LAYER 6: ERROR HANDLER (CEGAH LOG ERROR) ==========
pcall(function()
    local oldError = error
    error = function(msg, level)
        if type(msg) == "string" and (
            msg:lower():find("kick") or 
            msg:lower():find("ban") or
            msg:lower():find("exploit") or
            msg:lower():find("cheat")
        ) then
            return nil
        end
        return oldError(msg, level)
    end
end)

-- ========== LAYER 7: PROTECT GETRENV VARS ==========
pcall(function()
    local env = getrenv()
    if env then
        env.script = nil
    end
end)

-- ========== LAYER 8: GETREG (HIDE TABLES) ==========
pcall(function()
    for i, v in next, getreg() do
if type(v) == "thread" then
if string.find(debug.traceback(v), "<", 1, true) then
coroutine.close(v)
end
end
end
end)

-- ========= LAYER 9: PROTECT GETGC (HIDE FUNCTIONS) ==========
pcall(function()
    local oldGetGC = getgc
    getgc = function(...)
        local result = oldGetGC(...)
        local filtered = {}
        for i, v in next, result do
            if type(v) == "function" then
                local info = debug.getinfo(v)
                if info and info.what ~= "C" then
                    table.insert(filtered, v)
                end
            end
        end
        return filtered
    end
end)

-- ========= Getthread ================ ---
pcall(function()
    for i,v in next, getallthreads() do
local s = getscriptfromthread(v)
if string.find(tostring(s), "<", 1, true) then
coroutine.close(v)
end
end end)

-- ================================================================
-- ========== BYPASS DARI URL (METAMETHOD, HANDSHAKE, DLL) ==========
-- ================================================================

local function bypassMetaMethods()
    local checks = {
        "checkcaller", "getcallingscript", "getfenv", "setfenv",
        "getreg", "getgc", "getconnections", "hookfunction", "newcclosure"
    }
    local foundChecks = {}
    for _, check in ipairs(checks) do
        if getgenv()[check] or _G[check] then
            table.insert(foundChecks, check)
        end
    end
    if hookfunction then
        local originalHook = hookfunction
        hookfunction = function(func, replacement)
            return originalHook(func, function(...)
                return replacement(...)
            end)
        end
    end
    if setreadonly then setreadonly(getrenv(), false) end
    if make_writeable then make_writeable(getreg()) end
end

local function bypassHandshakes()
    local remotes = game:GetService("ReplicatedStorage"):GetDescendants()
    local bypassed = 0
    for _, remote in ipairs(remotes) do
        if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
            local name = remote.Name:lower()
            if name:find("handshake") or name:find("validate") or name:find("verify") then
                bypassed = bypassed + 1
                if remote:IsA("RemoteEvent") then
                    remote.FireServer = function() return true end
                elseif remote:IsA("RemoteFunction") then
                    remote.InvokeServer = function() return true end
                end
            end
        end
    end
end

local function bypassHookChecks()
    local hooksBypassed = 0
    if detour_function then
        detour_function = function() return true end
        hooksBypassed = hooksBypassed + 1
    end
    if getconnections then
        for _, conn in ipairs(getconnections(game:GetService("ScriptContext").Error)) do
            conn:Disable()
            hooksBypassed = hooksBypassed + 1
        end
    end
end

local function bypassDetours()
    local detoursBypassed = 0
    local criticalFunctions = {
        "Instance.new", "getfenv", "setfenv", "getreg", "getgc", "checkcaller"
    }
    for _, funcName in ipairs(criticalFunctions) do
        pcall(function()
            local original = _G[funcName] or getgenv()[funcName]
            if original then _G[funcName] = original; detoursBypassed = detoursBypassed + 1 end
        end)
    end
    if getrenv then
        local env = getrenv()
        for name, func in pairs(env) do
            if type(func) == "function" and not string.find(name, "__") then
                pcall(function() env[name] = func end)
                detoursBypassed = detoursBypassed + 1
            end
        end
    end
end

local function bypassMemoryChecks()
    local memoryPatches = 0
    if setreadonly then
        pcall(function() setreadonly(getrenv(), false) end)
        pcall(function() setreadonly(getreg(), false) end)
        pcall(function() setreadonly(getgc(), false) end)
        memoryPatches = memoryPatches + 3
    end
    if getgc then
        for _, obj in ipairs(getgc()) do
            if type(obj) == "table" and rawget(obj, "__acsignature") then
                rawset(obj, "__acsignature", nil)
                memoryPatches = memoryPatches + 1
            end
        end
    end
end

local function bypassVMChecks()
    local vmBypasses = 0
    if debug then
        debug.info = function() return "C" end
        debug.traceback = function() return "" end
        vmBypasses = vmBypasses + 2
    end
    if getcallingscript then
        getcallingscript = function() return nil end
        vmBypasses = vmBypasses + 1
    end
end

local function bypassSignatures()
    local signaturesBypassed = 0
    local signatureTables = {"_G", "shared", "getgenv", "getrenv"}
    for _, tableName in ipairs(signatureTables) do
        local target = _G[tableName] or getgenv()[tableName]
        if target and type(target) == "table" then
            for key, _ in pairs(target) do
                local keyStr = tostring(key):lower()
                if keyStr:find("signature") or keyStr:find("checksum") or keyStr:find("hash") then
                    target[key] = nil
                    signaturesBypassed = signaturesBypassed + 1
                end
            end
        end
    end
end

local function bypassIntegrityChecks()
    local integrityBypasses = 0
    if getconnections then
        for _, conn in ipairs(getconnections(game:GetService("ScriptContext").ScriptAdded)) do
            conn:Disable()
            integrityBypasses = integrityBypasses + 1
        end
        for _, conn in ipairs(getconnections(game:GetService("ScriptContext").ScriptRemoved)) do
            conn:Disable()
            integrityBypasses = integrityBypasses + 1
        end
    end
    local modules = game:GetService("ReplicatedStorage"):GetDescendants()
    for _, module in ipairs(modules) do
        if module:IsA("ModuleScript") and 
           (module.Name:lower():find("integrity") or 
            module.Name:lower():find("security") or
            module.Name:lower():find("anti")) then
            pcall(function() module:Destroy() end)
            integrityBypasses = integrityBypasses + 1
        end
    end
end

-- ========== PANGGIL SEMUA BYPASS ==========
spawn(function()
    -- BYPASS YANG DARI URL
    pcall(bypassMetaMethods)
    pcall(bypassHandshakes)
    pcall(bypassHookChecks)
    pcall(bypassDetours)
    pcall(bypassMemoryChecks)
    pcall(bypassVMChecks)
    pcall(bypassSignatures)
    pcall(bypassIntegrityChecks)
end)

pcall(function()
    local mt = getrawmetatable(game)
    if mt then
        setreadonly(mt, false)
        local old_nc = mt.__namecall
        mt.__namecall = function(self, ...)
            local method = getnamecallmethod()
            if method == "FireServer" then
                local str = tostring(self)
                if str:find("Anti") or str:find("Detect") or str:find("Check") or str:find("Report") then
                    return nil
                end
            end
            if method == "Kick" or method == "Ban" then
                return nil
            end
            return old_nc(self, ...)
        end
        setreadonly(mt, true)
    end

    local forbid = {"getexecutorname", "identifyexecutor", "checkexecutor", "is_synapse", "is_krnl"}
    for _, f in ipairs(forbid) do
        if _G[f] then _G[f] = function() return "Unknown" end end
    end

    pcall(function() game:GetService("LogService"):SetLogLevel(Enum.LogLevel.None) end)
end)

-- ================================================================
-- REMOVE HEX-NAMED REMOTEFUNCTIONS FROM REPLICATEDSTORAGE
-- ================================================================
task.wait(2) -- wait for game to fully load before removing

for _, v in ipairs(game.ReplicatedStorage:GetChildren()) do
    if string.match(v.Name, "^[0-9a-fA-F]+$") then
        for _, child in ipairs(v:GetChildren()) do
            if child:IsA("RemoteFunction") then
                child.Parent = nil
                print("Removed RemoteFunction:", child.Name, "from", v.Name)
            end
        end
    end
end

print("bypass loaded")


-- ========== CLEANUP ==========
-- Hapus jejak script dari memori global
if _G.XYLENT then _G.XYLENT = nil end
if getgenv().XYLENT then getgenv().XYLENT = nil end

-- ================================================================
-- SERVICES
-- ================================================================
local Players    = game:GetService("Players")
local TS         = game:GetService("TweenService")
local UIS        = game:GetService("UserInputService")
local RS         = game:GetService("RunService")
local Camera     = workspace.CurrentCamera
local Lighting   = game:GetService("Lighting")
local lp         = Players.LocalPlayer
local PGui       = lp:WaitForChild("PlayerGui")

for _, old in pairs(PGui:GetChildren()) do if old.Name=="SilentHub" then old:Destroy() end end
task.wait(0.05)

-- ================================================================
-- PALETTE
-- ================================================================
local C = {
    BG       = Color3.fromRGB(10,  10,  13),
    SURF     = Color3.fromRGB(18,  18,  24),
    SURF2    = Color3.fromRGB(26,  26,  34),
    SURF3    = Color3.fromRGB(34,  34,  44),
    BORDER   = Color3.fromRGB(55,  55,  68),
    BORDERL  = Color3.fromRGB(85,  85,  100),
    TEXT     = Color3.fromRGB(235, 235, 240),
    TEXTM    = Color3.fromRGB(160, 160, 175),
    TEXTD    = Color3.fromRGB(90,  90,  108),
    WHITE    = Color3.fromRGB(255, 255, 255),
    GREY     = Color3.fromRGB(130, 130, 148),
    GREY2    = Color3.fromRGB(75,  75,  90),
    ACC      = Color3.fromRGB(200, 200, 215),
    ACCB     = Color3.fromRGB(255, 255, 255),
    GREEN    = Color3.fromRGB(72,  215, 115),
    RED      = Color3.fromRGB(255, 80,  80),
    YELLOW   = Color3.fromRGB(255, 205, 60),
    BLUE     = Color3.fromRGB(88,  101, 242),
    TIER1    = Color3.fromRGB(130, 220, 130),
    TIER2    = Color3.fromRGB(255, 213, 170),
    TIER3    = Color3.fromRGB(100, 149, 237),
}

-- ================================================================
-- TWEEN HELPER
-- ================================================================
local function tw(obj, props, t, sty, dir)
    TS:Create(obj, TweenInfo.new(t or .18, sty or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props):Play()
end
local function twReturn(obj, props, t, sty, dir)
    local tr = TS:Create(obj, TweenInfo.new(t or .18, sty or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
    tr:Play(); return tr
end

-- ================================================================
-- DRAGGABLE
-- ================================================================
local function makeDraggable(handle, target)
    local drag, ds, sp = false, nil, nil
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            drag=true; ds=i.Position; sp=target.Position
        end
    end)
    handle.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag=false end
    end)
    UIS.InputChanged:Connect(function(i)
        if drag and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
            local d = i.Position - ds
            target.Position = UDim2.new(sp.X.Scale, sp.X.Offset+d.X, sp.Y.Scale, sp.Y.Offset+d.Y)
        end
    end)
end

-- ================================================================
-- SCREEN GUI
-- ================================================================
local Gui = Instance.new("ScreenGui")
Gui.Name="SilentHub"; Gui.ResetOnSpawn=false; Gui.IgnoreGuiInset=true
Gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; Gui.DisplayOrder=100; Gui.Parent=PGui

-- Window
local WW, WH = 380, 340
local TH     = 44
local TBH    = 28
local CH     = WH - TH - TBH

local Win = Instance.new("Frame", Gui)
Win.Name="Win"
Win.Size     = UDim2.new(0,WW,0,WH)
Win.Position = UDim2.new(0.5,-WW/2,0.5,-WH/2)
Win.BackgroundColor3 = C.BG
Win.BorderSizePixel  = 0
Win.ClipsDescendants = false
Instance.new("UICorner", Win).CornerRadius = UDim.new(0,14)

local gloss = Instance.new("Frame", Win)
gloss.Size=UDim2.new(1,-20,0,1); gloss.Position=UDim2.new(0,10,0,1)
gloss.BackgroundColor3=Color3.fromRGB(255,255,255); gloss.BackgroundTransparency=0.72
gloss.BorderSizePixel=0; gloss.ZIndex=200
Instance.new("UICorner", gloss).CornerRadius=UDim.new(0,1)

local winStk = Instance.new("UIStroke", Win)
winStk.Thickness=1.5; winStk.Transparency=0
local strokeGrad = Instance.new("UIGradient", winStk)
strokeGrad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(180,180,195)),
    ColorSequenceKeypoint.new(0.35,Color3.fromRGB(255,255,255)),
    ColorSequenceKeypoint.new(0.65,Color3.fromRGB(255,255,255)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(180,180,195)),
}
strokeGrad.Transparency = NumberSequence.new{
    NumberSequenceKeypoint.new(0,0.7),
    NumberSequenceKeypoint.new(0.15,0.05),
    NumberSequenceKeypoint.new(0.85,0.05),
    NumberSequenceKeypoint.new(1,0.7),
}
task.spawn(function()
    while Win and Win.Parent do
        tw(strokeGrad,{Rotation=(strokeGrad.Rotation or 0)+360},4.5,Enum.EasingStyle.Linear)
        task.wait(4.5)
    end
end)

-- TopBar
local TopBar = Instance.new("Frame", Win)
TopBar.Size=UDim2.new(1,0,0,TH); TopBar.Position=UDim2.new(0,0,0,0)
TopBar.BackgroundColor3=C.SURF; TopBar.BorderSizePixel=0; TopBar.ZIndex=5
Instance.new("UICorner", TopBar).CornerRadius=UDim.new(0,14)
local tbFix=Instance.new("Frame",TopBar); tbFix.Size=UDim2.new(1,0,0,14); tbFix.Position=UDim2.new(0,0,1,-14)
tbFix.BackgroundColor3=C.SURF; tbFix.BorderSizePixel=0
local tGloss=Instance.new("Frame",TopBar); tGloss.Size=UDim2.new(0.8,0,0,1); tGloss.Position=UDim2.new(0.1,0,0,1)
tGloss.BackgroundColor3=C.WHITE; tGloss.BackgroundTransparency=0.65; tGloss.BorderSizePixel=0; tGloss.ZIndex=6
local tbSep=Instance.new("Frame",TopBar); tbSep.Size=UDim2.new(1,0,0,1); tbSep.Position=UDim2.new(0,0,1,-1)
tbSep.BackgroundColor3=C.BORDER; tbSep.BorderSizePixel=0

makeDraggable(TopBar, Win)

local dot=Instance.new("Frame",TopBar); dot.Size=UDim2.new(0,7,0,7); dot.Position=UDim2.new(0,14,0.5,-3.5)
dot.BackgroundColor3=C.ACCB; dot.BorderSizePixel=0; dot.ZIndex=6; Instance.new("UICorner",dot).CornerRadius=UDim.new(0.5,0)
local dotGlow=Instance.new("Frame",dot); dotGlow.Size=UDim2.new(2,0,2,0); dotGlow.Position=UDim2.new(-0.5,0,-0.5,0)
dotGlow.BackgroundColor3=C.ACCB; dotGlow.BackgroundTransparency=0.7; dotGlow.BorderSizePixel=0; dotGlow.ZIndex=5
Instance.new("UICorner",dotGlow).CornerRadius=UDim.new(0.5,0)
task.spawn(function()
    while dot and dot.Parent do
        tw(dotGlow,{BackgroundTransparency=0.4,Size=UDim2.new(2.8,0,2.8,0),Position=UDim2.new(-0.9,0,-0.9,0)},0.9,Enum.EasingStyle.Sine)
        task.wait(0.9)
        tw(dotGlow,{BackgroundTransparency=0.85,Size=UDim2.new(2,0,2,0),Position=UDim2.new(-0.5,0,-0.5,0)},0.9,Enum.EasingStyle.Sine)
        task.wait(0.9)
    end
end)

local titleL=Instance.new("TextLabel",TopBar); titleL.Size=UDim2.new(0,160,1,0); titleL.Position=UDim2.new(0,28,0,0)
titleL.BackgroundTransparency=1; titleL.RichText=true
titleL.Text='<b><font color="rgb(255,255,255)">SILENT</font></b><font color="rgb(150,150,165)"> HUB</font>'
titleL.Font=Enum.Font.GothamBlack; titleL.TextSize=12; titleL.TextXAlignment=Enum.TextXAlignment.Left; titleL.ZIndex=6

local verF=Instance.new("Frame",TopBar); verF.Size=UDim2.new(0,28,0,13); verF.Position=UDim2.new(0,115,0.5,-6.5)
verF.BackgroundColor3=C.SURF2; verF.BorderSizePixel=0; verF.ZIndex=6; Instance.new("UICorner",verF).CornerRadius=UDim.new(0,4)
Instance.new("UIStroke",verF).Color=C.BORDER
local verL=Instance.new("TextLabel",verF); verL.Size=UDim2.new(1,0,1,0); verL.BackgroundTransparency=1
verL.Text="v1.0"; verL.Font=Enum.Font.GothamBold; verL.TextSize=7; verL.TextColor3=C.TEXTM; verL.ZIndex=7

local btnGroup = Instance.new("Frame", TopBar)
btnGroup.Size        = UDim2.new(0, 54, 0, 24)
btnGroup.Position    = UDim2.new(1, -62, 0.5, -12)
btnGroup.BackgroundTransparency = 1
btnGroup.ZIndex      = 10

local function makeWinBtn(parent, xPos, bgCol, fgCol, label)
    local shadow = Instance.new("Frame", parent)
    shadow.Size              = UDim2.new(0, 22, 0, 22)
    shadow.Position          = UDim2.new(0, xPos+1, 0.5, -10)
    shadow.BackgroundColor3  = Color3.fromRGB(0,0,0)
    shadow.BackgroundTransparency = 0.55
    shadow.BorderSizePixel   = 0
    shadow.ZIndex            = 9
    Instance.new("UICorner", shadow).CornerRadius = UDim.new(0.5,0)

    local btn = Instance.new("TextButton", parent)
    btn.Size             = UDim2.new(0, 22, 0, 22)
    btn.Position         = UDim2.new(0, xPos, 0.5, -11)
    btn.BackgroundColor3 = bgCol
    btn.Text             = label
    btn.TextColor3       = fgCol
    btn.Font             = Enum.Font.GothamBold
    btn.TextSize         = 14
    btn.BorderSizePixel  = 0
    btn.ZIndex           = 10
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0.5, 0)

    local stk = Instance.new("UIStroke", btn)
    stk.Color        = C.BORDERL
    stk.Thickness    = 0.8
    stk.Transparency = 0.5

    btn.MouseEnter:Connect(function()
        tw(btn, {BackgroundColor3 = fgCol, TextColor3 = bgCol}, .12)
        tw(shadow, {BackgroundTransparency = 0.35}, .12)
    end)
    btn.MouseLeave:Connect(function()
        tw(btn, {BackgroundColor3 = bgCol, TextColor3 = fgCol}, .12)
        tw(shadow, {BackgroundTransparency = 0.55}, .12)
    end)
    return btn
end

local closeBtn = makeWinBtn(btnGroup, 32, Color3.fromRGB(55,15,15), Color3.fromRGB(255,80,80), "×")
local minBtn   = makeWinBtn(btnGroup,  0, C.SURF2,                  C.GREY,                     "—")

closeBtn.MouseButton1Click:Connect(function()
    tw(Win,{Size=UDim2.new(0,0,0,0),BackgroundTransparency=1},0.22,Enum.EasingStyle.Back,Enum.EasingDirection.In)
    task.delay(0.25,function() Gui:Destroy() end)
end)

-- Minimize header
local minHeader = nil
local isMin     = false

local function buildMinHeader()
    if minHeader then minHeader:Destroy() end
    local mh = Instance.new("TextButton", Gui)
    mh.Name="MinHeader"
    mh.Size=UDim2.new(0,0,0,0)
    mh.Position=UDim2.new(0,14,0.5,-23)
    mh.BackgroundColor3=C.SURF
    mh.Text=""; mh.ZIndex=200
    mh.BorderSizePixel=0
    Instance.new("UICorner",mh).CornerRadius=UDim.new(0,13)
    minHeader=mh

    local outerStk=Instance.new("UIStroke",mh)
    outerStk.Color=Color3.fromRGB(145,145,160); outerStk.Thickness=2.2

    local innerRing=Instance.new("Frame",mh)
    innerRing.Size=UDim2.new(1,-8,1,-8); innerRing.Position=UDim2.new(0,4,0,4)
    innerRing.BackgroundTransparency=1; innerRing.ZIndex=201
    Instance.new("UICorner",innerRing).CornerRadius=UDim.new(0,9)
    local innerStk=Instance.new("UIStroke",innerRing)
    innerStk.Color=Color3.fromRGB(85,85,100); innerStk.Thickness=1.2

    local sheen=Instance.new("Frame",mh); sheen.Size=UDim2.new(0.7,0,0,1)
    sheen.Position=UDim2.new(0.15,0,0,2); sheen.BackgroundColor3=C.WHITE
    sheen.BackgroundTransparency=0.55; sheen.BorderSizePixel=0; sheen.ZIndex=202
    Instance.new("UICorner",sheen).CornerRadius=UDim.new(0,1)

    local sLbl=Instance.new("TextLabel",mh)
    sLbl.Size=UDim2.new(1,0,1,0); sLbl.BackgroundTransparency=1
    sLbl.Text="S"; sLbl.TextColor3=C.TEXT
    sLbl.Font=Enum.Font.GothamBlack; sLbl.TextSize=0
    sLbl.TextXAlignment=Enum.TextXAlignment.Center; sLbl.TextYAlignment=Enum.TextYAlignment.Center
    sLbl.ZIndex=203

    task.spawn(function()
        tw(mh,{Size=UDim2.new(0,46,0,46)},0.3,Enum.EasingStyle.Back,Enum.EasingDirection.Out)
        task.wait(0.18)
        tw(sLbl,{TextSize=28,TextTransparency=0},0.25,Enum.EasingStyle.Quint)
    end)

    mh.MouseEnter:Connect(function()
        tw(mh,{BackgroundColor3=C.SURF2},.14)
        tw(outerStk,{Color=C.ACCB,Transparency=0},.14)
    end)
    mh.MouseLeave:Connect(function()
        tw(mh,{BackgroundColor3=C.SURF},.14)
        tw(outerStk,{Color=Color3.fromRGB(145,145,160)},.14)
    end)

    mh.MouseButton1Click:Connect(function()
        isMin=false
        tw(sLbl,{TextSize=0,TextTransparency=1},0.15,Enum.EasingStyle.Quint)
        tw(mh,{Size=UDim2.new(0,0,0,0)},0.22,Enum.EasingStyle.Back,Enum.EasingDirection.In)
        task.delay(0.22,function() if mh and mh.Parent then mh:Destroy() end; minHeader=nil end)
        Win.Visible=true
        Win.Size=UDim2.new(0,0,0,0); Win.BackgroundTransparency=1
        tw(Win,{Size=UDim2.new(0,WW,0,WH),BackgroundTransparency=0},0.35,Enum.EasingStyle.Back,Enum.EasingDirection.Out)
    end)
end

minBtn.MouseButton1Click:Connect(function()
    if isMin then return end
    isMin=true
    local shrink=twReturn(Win,{Size=UDim2.new(0,0,0,0),BackgroundTransparency=1},0.2,Enum.EasingStyle.Back,Enum.EasingDirection.In)
    shrink.Completed:Connect(function()
        if isMin then Win.Visible=false; buildMinHeader() end
    end)
end)

-- ================================================================
-- TAB BAR
-- ================================================================
local TAB_NAMES = {"Main","Player","Teleport","ESP","Opti","Credit"}
local tabW      = WW / #TAB_NAMES

local TabBar=Instance.new("Frame",Win)
TabBar.Size=UDim2.new(1,0,0,TBH); TabBar.Position=UDim2.new(0,0,0,TH)
TabBar.BackgroundColor3=C.SURF; TabBar.BorderSizePixel=0; TabBar.ZIndex=4
local tbBot=Instance.new("Frame",TabBar); tbBot.Size=UDim2.new(1,0,0,1); tbBot.Position=UDim2.new(0,0,1,-1)
tbBot.BackgroundColor3=C.BORDER; tbBot.BorderSizePixel=0

local Content=Instance.new("Frame",Win)
Content.Size=UDim2.new(1,0,0,CH); Content.Position=UDim2.new(0,0,0,TH+TBH)
Content.BackgroundColor3=C.BG; Content.BorderSizePixel=0; Content.ClipsDescendants=true; Content.ZIndex=3

local tabPages,tabBtns,activeIdx={},{},0

local function mkPage()
    local sf=Instance.new("ScrollingFrame",Content)
    sf.Size=UDim2.new(1,0,1,0); sf.BackgroundTransparency=1; sf.BorderSizePixel=0
    sf.ScrollBarThickness=2; sf.ScrollBarImageColor3=C.GREY2
    sf.AutomaticCanvasSize=Enum.AutomaticSize.Y; sf.CanvasSize=UDim2.new(0,0,0,0)
    sf.Visible=false; sf.ZIndex=4
    local ll=Instance.new("UIListLayout",sf); ll.SortOrder=Enum.SortOrder.LayoutOrder; ll.Padding=UDim.new(0,5)
    local pd=Instance.new("UIPadding",sf)
    pd.PaddingTop=UDim.new(0,7); pd.PaddingBottom=UDim.new(0,7)
    pd.PaddingLeft=UDim.new(0,7); pd.PaddingRight=UDim.new(0,7)
    return sf
end

local function setTabActive(btn, on)
    tw(btn,{BackgroundColor3=on and C.SURF2 or C.SURF},0.14)
    local lb=btn:FindFirstChildOfClass("TextLabel"); if lb then tw(lb,{TextColor3=on and C.ACC or C.TEXTD},0.14) end
    local ab=btn:FindFirstChild("_ab"); if ab then tw(ab,{BackgroundTransparency=on and 0 or 1,Size=on and UDim2.new(0.7,0,0,2) or UDim2.new(0.3,0,0,2)},0.18) end
end

local function switchTab(i)
    if activeIdx>0 and tabPages[activeIdx] then
        local old=tabPages[activeIdx]
        tw(old,{Position=UDim2.new(0,-6,0,0)},0.13); task.delay(0.1,function() old.Visible=false; old.Position=UDim2.new(0,0,0,0) end)
        setTabActive(tabBtns[activeIdx],false)
    end
    activeIdx=i; local pg=tabPages[i]; pg.Visible=true; pg.Position=UDim2.new(0,6,0,0)
    tw(pg,{Position=UDim2.new(0,0,0,0)},0.18); setTabActive(tabBtns[i],true)
end

for i, name in ipairs(TAB_NAMES) do
    local btn=Instance.new("TextButton",TabBar)
    btn.Size=UDim2.new(0,tabW,1,0); btn.Position=UDim2.new(0,(i-1)*tabW,0,0)
    btn.BackgroundColor3=C.SURF; btn.BorderSizePixel=0; btn.Text=""; btn.ZIndex=5
    local lb=Instance.new("TextLabel",btn); lb.Size=UDim2.new(1,0,1,0); lb.BackgroundTransparency=1
    lb.Text=name; lb.Font=Enum.Font.GothamBold; lb.TextSize=8; lb.TextColor3=C.TEXTD; lb.ZIndex=6
    local ab=Instance.new("Frame",btn); ab.Name="_ab"
    ab.Size=UDim2.new(0.3,0,0,2); ab.AnchorPoint=Vector2.new(0.5,0); ab.Position=UDim2.new(0.5,0,1,-2)
    ab.BackgroundColor3=C.ACCB; ab.BorderSizePixel=0; ab.BackgroundTransparency=1; ab.ZIndex=7
    Instance.new("UICorner",ab).CornerRadius=UDim.new(0.5,0)
    if i<#TAB_NAMES then
        local sep=Instance.new("Frame",btn); sep.Size=UDim2.new(0,1,0.4,0); sep.Position=UDim2.new(1,-1,0.3,0)
        sep.BackgroundColor3=C.BORDER; sep.BorderSizePixel=0
    end
    tabBtns[i]=btn; tabPages[i]=mkPage()
    btn.MouseButton1Click:Connect(function() switchTab(i) end)
end

-- ================================================================
-- WIDGET HELPERS
-- ================================================================
local function mkSection(page, txt, order)
    local r=Instance.new("Frame",page); r.Size=UDim2.new(1,0,0,14); r.BackgroundTransparency=1; r.LayoutOrder=order
    local l=Instance.new("TextLabel",r); l.Size=UDim2.new(1,-4,1,0); l.Position=UDim2.new(0,4,0,0)
    l.BackgroundTransparency=1; l.Text=txt:upper(); l.Font=Enum.Font.GothamBold; l.TextSize=6; l.TextColor3=C.TEXTD
    l.TextXAlignment=Enum.TextXAlignment.Left; l.ZIndex=5
    local ln=Instance.new("Frame",r); ln.Size=UDim2.new(1,0,0,1); ln.Position=UDim2.new(0,0,1,-1)
    ln.BackgroundColor3=C.BORDER; ln.BorderSizePixel=0
end

local function mkCard(page, h, order)
    local f=Instance.new("Frame",page); f.Size=UDim2.new(1,0,0,h or 34)
    f.BackgroundColor3=C.SURF2; f.BorderSizePixel=0; f.LayoutOrder=order or 0; f.ZIndex=4
    Instance.new("UICorner",f).CornerRadius=UDim.new(0,8)
    Instance.new("UIStroke",f).Color=C.BORDER
    local g=Instance.new("Frame",f); g.Size=UDim2.new(0.6,0,0,1); g.Position=UDim2.new(0.2,0,0,1)
    g.BackgroundColor3=C.WHITE; g.BackgroundTransparency=0.8; g.BorderSizePixel=0; g.ZIndex=5
    return f
end

local function mkAlertCard(page, shadowColor, title, text, order)
    local con=Instance.new("Frame",page); con.Size=UDim2.new(1,0,0,56); con.BackgroundTransparency=1; con.LayoutOrder=order; con.ZIndex=4; con.ClipsDescendants=false
    local sh=Instance.new("Frame",con); sh.Size=UDim2.new(1,-2,1,-2); sh.Position=UDim2.new(0,1.5,0,1.5)
    sh.BackgroundColor3=shadowColor; sh.BackgroundTransparency=0.7; sh.BorderSizePixel=0; sh.ZIndex=5
    Instance.new("UICorner",sh).CornerRadius=UDim.new(0,9)
    local mc=Instance.new("Frame",con); mc.Size=UDim2.new(1,0,1,-3); mc.Position=UDim2.new(0,0,0,-1.5)
    mc.BackgroundColor3=C.SURF2; mc.BorderSizePixel=0; mc.ZIndex=6
    Instance.new("UICorner",mc).CornerRadius=UDim.new(0,8)
    Instance.new("UIStroke",mc).Color=shadowColor
    local highGloss=Instance.new("Frame",mc); highGloss.Size=UDim2.new(1,0,0,2); highGloss.Position=UDim2.new(0,0,0,0)
    highGloss.BackgroundColor3=C.WHITE; highGloss.BackgroundTransparency=0.7; highGloss.BorderSizePixel=0; highGloss.ZIndex=7
    Instance.new("UICorner",highGloss).CornerRadius=UDim.new(0,2)
    local tl=Instance.new("TextLabel",mc); tl.Size=UDim2.new(1,-12,0,16); tl.Position=UDim2.new(0,6,0,5)
    tl.BackgroundTransparency=1; tl.Text=title; tl.Font=Enum.Font.GothamBold; tl.TextSize=10; tl.TextColor3=C.TEXT
    tl.TextXAlignment=Enum.TextXAlignment.Left; tl.ZIndex=7
    local bl=Instance.new("TextLabel",mc); bl.Size=UDim2.new(1,-12,0,22); bl.Position=UDim2.new(0,6,0,23)
    bl.BackgroundTransparency=1; bl.Text=text; bl.Font=Enum.Font.Gotham; bl.TextSize=7; bl.TextColor3=C.TEXTM
    bl.TextXAlignment=Enum.TextXAlignment.Left; bl.TextWrapped=true; bl.ZIndex=7
    return con
end

local function mkToggle(page, txt, sub, order, cb)
    local h = sub and 40 or 32
    local row=Instance.new("TextButton",page); row.Size=UDim2.new(1,0,0,h)
    row.BackgroundColor3=C.SURF2; row.BorderSizePixel=0; row.LayoutOrder=order; row.Text=""; row.ZIndex=4
    Instance.new("UICorner",row).CornerRadius=UDim.new(0,8)
    Instance.new("UIStroke",row).Color=C.BORDER
    local g2=Instance.new("Frame",row); g2.Size=UDim2.new(0.7,0,0,1); g2.Position=UDim2.new(0.15,0,0,1)
    g2.BackgroundColor3=C.WHITE; g2.BackgroundTransparency=0.82; g2.BorderSizePixel=0; g2.ZIndex=5
    local lbl=Instance.new("TextLabel",row); lbl.Size=UDim2.new(1,-48,0,14); lbl.Position=UDim2.new(0,8,0,sub and 6 or 9)
    lbl.BackgroundTransparency=1; lbl.Text=txt; lbl.Font=Enum.Font.GothamBold; lbl.TextSize=9; lbl.TextColor3=C.TEXT
    lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.ZIndex=5
    if sub then
        local sl=Instance.new("TextLabel",row); sl.Size=UDim2.new(1,-48,0,10); sl.Position=UDim2.new(0,8,0,23)
        sl.BackgroundTransparency=1; sl.Text=sub; sl.Font=Enum.Font.Gotham; sl.TextSize=7; sl.TextColor3=C.TEXTM
        sl.TextXAlignment=Enum.TextXAlignment.Left; sl.ZIndex=5
    end
    local pill=Instance.new("Frame",row); pill.Size=UDim2.new(0,28,0,14); pill.Position=UDim2.new(1,-36,0.5,-7)
    pill.BackgroundColor3=C.GREY2; pill.BorderSizePixel=0; pill.ZIndex=5
    Instance.new("UICorner",pill).CornerRadius=UDim.new(0.5,0)
    local knob=Instance.new("Frame",pill); knob.Size=UDim2.new(0,10,0,10); knob.Position=UDim2.new(0,2,0.5,-5)
    knob.BackgroundColor3=C.WHITE; knob.BorderSizePixel=0; knob.ZIndex=6
    Instance.new("UICorner",knob).CornerRadius=UDim.new(0.5,0)
    local on=false
    local function setState(v)
        on=v
        tw(pill,{BackgroundColor3=on and C.GREEN or C.GREY2},0.16)
        tw(knob,{Position=on and UDim2.new(1,-12,0.5,-5) or UDim2.new(0,2,0.5,-5)},0.16)
        tw(lbl,{TextColor3=on and C.ACCB or C.TEXT},0.14)
        if cb then cb(on) end
    end
    row.MouseButton1Click:Connect(function() setState(not on) end)
    return row, setState
end

local function mkSlider(page, label, minV, maxV, defV, order, cb)
    local row=mkCard(page,46,order)
    local lbl=Instance.new("TextLabel",row); lbl.Size=UDim2.new(0.6,0,0,15); lbl.Position=UDim2.new(0,8,0,5)
    lbl.BackgroundTransparency=1; lbl.Text=label; lbl.Font=Enum.Font.GothamBold; lbl.TextSize=9; lbl.TextColor3=C.TEXT
    lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.ZIndex=5
    local valL=Instance.new("TextLabel",row); valL.Size=UDim2.new(0.4,-8,0,15); valL.Position=UDim2.new(0.6,0,0,5)
    valL.BackgroundTransparency=1; valL.Text=tostring(defV); valL.Font=Enum.Font.GothamBold; valL.TextSize=9; valL.TextColor3=C.ACCB
    valL.TextXAlignment=Enum.TextXAlignment.Right; lbl.ZIndex=5
    local track=Instance.new("Frame",row); track.Size=UDim2.new(1,-16,0,3); track.Position=UDim2.new(0,8,0,31)
    track.BackgroundColor3=C.SURF3; track.BorderSizePixel=0; Instance.new("UICorner",track).CornerRadius=UDim.new(0,2)
    local fill=Instance.new("Frame",track); fill.Size=UDim2.new((defV-minV)/(maxV-minV),0,1,0)
    fill.BackgroundColor3=C.ACCB; fill.BorderSizePixel=0; Instance.new("UICorner",fill).CornerRadius=UDim.new(0,2)
    local knob=Instance.new("Frame",track); knob.Size=UDim2.new(0,11,0,11); knob.AnchorPoint=Vector2.new(0.5,0.5)
    knob.Position=UDim2.new((defV-minV)/(maxV-minV),0,0.5,0); knob.BackgroundColor3=C.WHITE; knob.BorderSizePixel=0; knob.ZIndex=6
    Instance.new("UICorner",knob).CornerRadius=UDim.new(0.5,0)
    local ks=Instance.new("UIStroke",knob); ks.Color=C.GREY; ks.Thickness=1
    local hit=Instance.new("TextButton",track); hit.Size=UDim2.new(1,0,0,18); hit.Position=UDim2.new(0,0,0.5,-9)
    hit.BackgroundTransparency=1; hit.Text=""; hit.ZIndex=7
    local cur,sd=defV,false
    local function applyX(x)
        local ax,aw=track.AbsolutePosition.X,track.AbsoluteSize.X; if aw<=0 then return end
        local rel=math.clamp((x-ax)/aw,0,1); cur=math.floor(minV+(maxV-minV)*rel)
        fill.Size=UDim2.new(rel,0,1,0); knob.Position=UDim2.new(rel,0,0.5,0); valL.Text=tostring(cur)
        if cb then cb(cur) end
    end
    hit.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            sd=true; applyX(i.Position.X)
        end
    end)
    hit.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then sd=false end
    end)
    UIS.InputChanged:Connect(function(i)
        if not sd then return end
        if i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch then applyX(i.Position.X) end
    end)
    return row
end

local function mkTextbox(page, label, placeholder, order, cb)
    local wrap=mkCard(page,50,order)
    local lbl=Instance.new("TextLabel",wrap); lbl.Size=UDim2.new(1,-16,0,13); lbl.Position=UDim2.new(0,8,0,5)
    lbl.BackgroundTransparency=1; lbl.Text=label; lbl.Font=Enum.Font.GothamBold; lbl.TextSize=8; lbl.TextColor3=C.TEXTM
    lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.ZIndex=5
    local box=Instance.new("TextBox",wrap); box.Size=UDim2.new(1,-16,0,20); box.Position=UDim2.new(0,8,0,21)
    box.BackgroundColor3=C.SURF3; box.Font=Enum.Font.Gotham; box.TextSize=10; box.TextColor3=C.TEXT
    box.PlaceholderText=placeholder or "Type here..."; box.PlaceholderColor3=C.TEXTD
    box.Text=""; box.BorderSizePixel=0; box.ClearTextOnFocus=false; box.ZIndex=5
    Instance.new("UICorner",box).CornerRadius=UDim.new(0,5)
    local bs=Instance.new("UIStroke",box); bs.Color=C.BORDER; bs.Thickness=1
    local bp=Instance.new("UIPadding",box); bp.PaddingLeft=UDim.new(0,6)
    box.Focused:Connect(function() tw(bs,{Color=C.ACCB,Thickness=1.5},0.15) end)
    box.FocusLost:Connect(function(enter) tw(bs,{Color=C.BORDER,Thickness=1},0.15); if cb and enter then cb(box.Text) end end)
    return wrap, box
end

local function mkDropdown(page, label, options, order, cb)
    local h=20+#options*22
    local wrap=mkCard(page,h,order)
    local lbl=Instance.new("TextLabel",wrap); lbl.Size=UDim2.new(1,-16,0,15); lbl.Position=UDim2.new(0,8,0,3)
    lbl.BackgroundTransparency=1; lbl.Text=label; lbl.Font=Enum.Font.GothamBold; lbl.TextSize=8; lbl.TextColor3=C.TEXTM
    lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.ZIndex=5
    local btns={}
    for idx,opt in ipairs(options) do
        local ob=Instance.new("TextButton",wrap); ob.Size=UDim2.new(1,-16,0,18); ob.Position=UDim2.new(0,8,0,18+(idx-1)*21)
        ob.BackgroundColor3=C.SURF3; ob.Font=Enum.Font.GothamBold; ob.TextSize=8; ob.TextColor3=C.TEXTM
        ob.Text=opt; ob.BorderSizePixel=0; ob.ZIndex=5
        Instance.new("UICorner",ob).CornerRadius=UDim.new(0,5)
        local obs=Instance.new("UIStroke",ob); obs.Color=C.BORDER; obs.Thickness=1
        btns[opt]={btn=ob,stk=obs}
        ob.MouseButton1Click:Connect(function()
            for _,bd in pairs(btns) do
                tw(bd.btn,{BackgroundColor3=C.SURF3},0.12); bd.btn.TextColor3=C.TEXTM; bd.stk.Color=C.BORDER
            end
            tw(ob,{BackgroundColor3=C.GREY2},0.12); ob.TextColor3=C.TEXT; obs.Color=C.ACCB
            if cb then cb(opt) end
        end)
    end
    return wrap
end

local function mkBtn(page, txt, order, col, cb)
    local btn=Instance.new("TextButton",page); btn.Size=UDim2.new(1,0,0,28)
    btn.BackgroundColor3=col or C.SURF2; btn.BorderSizePixel=0; btn.Text=txt
    btn.TextColor3=col and C.WHITE or C.TEXT; btn.Font=Enum.Font.GothamBold; btn.TextSize=9
    btn.LayoutOrder=order; btn.ZIndex=4
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,8)
    local bs=Instance.new("UIStroke",btn); bs.Color=col or C.BORDER
    btn.MouseEnter:Connect(function() tw(btn,{BackgroundColor3=C.SURF3},.12) end)
    btn.MouseLeave:Connect(function() tw(btn,{BackgroundColor3=col or C.SURF2},.12) end)
    if cb then btn.MouseButton1Click:Connect(cb) end
    return btn
end

-- ================================================================
-- PAGE 1 — MAIN
-- ================================================================
local pMain = tabPages[1]
mkAlertCard(pMain,C.GREEN,"SAFE","Fitur di tab ini aman digunakan. Tidak membahayakan akun dan player lain.",0)
mkSection(pMain,"Movement",1)

local walkspeedEnabled=false; local currentWalkspeed=16
local _,setWalkspeed=mkToggle(pMain,"Walk Speed","Enable custom walkspeed",2,function(v)
    walkspeedEnabled=v
    local hum=lp.Character and lp.Character:FindFirstChild("Humanoid")
    if hum then hum.WalkSpeed=v and currentWalkspeed or 16 end
end)
mkSlider(pMain,"Walk Speed Value",16,21,16,3,function(v)
    currentWalkspeed=v
    if walkspeedEnabled then local hum=lp.Character and lp.Character:FindFirstChild("Humanoid"); if hum then hum.WalkSpeed=v end end
end)
lp.CharacterAdded:Connect(function(char)
    task.wait(0.5); if walkspeedEnabled then local hum=char:FindFirstChild("Humanoid"); if hum then hum.WalkSpeed=currentWalkspeed end end
end)

local staminaHooked = false
local heartbeatConnection = nil
mkToggle(pMain,"Infinite Stamina","Stamina tidak pernah habis",4,function(v)
    if Value and not staminaHooked then
            for _, v in pairs(getgc(true)) do
                if type(v) == "table" then
                    for k, _ in pairs(v) do
                        if k == "Stamina" then
                            local mt = getmetatable(v)
                            if mt then
                                setreadonly(mt, false)
                                local oldIndex = mt.__index
                                mt.__index = function(t, k2)
                                    if k2 == "Stamina" then return 100 end
                                    return oldIndex and oldIndex(t, k2)
                                end
                                staminaHooked = true
                            end
                            heartbeatConnection = RunService.Heartbeat:Connect(function()
                                if Value then v.Stamina = 100 end
                            end)
                            break
                        end
                    end
                end
                if staminaHooked then break end
            end
        elseif not Value and heartbeatConnection then
            heartbeatConnection:Disconnect()
            heartbeatConnection = nil
        end
    end)

mkSection(pMain,"Identity",5)
local _,nameBox=mkTextbox(pMain,"Change Name","Enter display name...",6,function(text)
    if text=="" then return end
    pcall(function()
        local char=workspace.Characters:FindFirstChild(lp.Name)
        if char and char.Head and char.Head.NameTag then char.Head.NameTag.MainFrame.NameLabel.Text=text end
    end)
end)
local _,usnBox=mkTextbox(pMain,"Change Username","Enter username...",7,function(text)
    if text=="" then return end
    pcall(function()
        local char=workspace.Characters:FindFirstChild(lp.Name)
        if char and char.Head and char.Head.RankTag then char.Head.RankTag.MainFrame.NameLabel.Text=text end
    end)
end)

mkSection(pMain,"Username Color",8)
local tierColors={["Default"]=Color3.new(1,1,1),["Tier 1 (Green)"]=C.TIER1,["Tier 2 (Peach)"]=C.TIER2,["Tier 3 (Blue)"]=C.TIER3}
mkDropdown(pMain,"Select Tier Color",{"Default","Tier 1 (Green)","Tier 2 (Peach)","Tier 3 (Blue)"},9,function(sel)
    local col=tierColors[sel]; if not col then return end
    pcall(function()
        local char=workspace.Characters:FindFirstChild(lp.Name)
        if char and char.Head and char.Head.RankTag then char.Head.RankTag.MainFrame.NameLabel.TextColor3=col end
    end)
end)

mkSection(pMain,"Delete Wall",10)
local deleteWallEnabled=false; local hoverPart=nil; local mouse=lp:GetMouse(); local deletedHistory={}; local MAX_HISTORY=20
local function savePartForUndo(part)
    if #deletedHistory>=MAX_HISTORY then table.remove(deletedHistory,1) end
    table.insert(deletedHistory,{name=part.Name,parent=part.Parent,cframe=part.CFrame,size=part.Size,
        transparency=part.Transparency,color=part.Color,material=part.Material,canCollide=part.CanCollide,anchored=part.Anchored})
end
local function undoLastDelete()
    if #deletedHistory==0 then return end; local d=deletedHistory[#deletedHistory]; table.remove(deletedHistory)
    local p=Instance.new("Part"); p.Name=d.name; p.Size=d.size; p.CFrame=d.cframe; p.Transparency=d.transparency
    p.Color=d.color; p.Material=d.material; p.CanCollide=d.canCollide; p.Anchored=d.anchored; p.Parent=d.parent
end
mkToggle(pMain,"Delete Wall Mode","E = hapus, U = undo",11,function(v) deleteWallEnabled=v end)
RS.RenderStepped:Connect(function()
    if deleteWallEnabled then
        local tgt=mouse.Target
        if tgt and tgt:IsA("BasePart") then
            local imp=tgt:IsDescendantOf(lp.Character) or (tgt.Parent and Players:GetPlayerFromCharacter(tgt.Parent)~=nil) or tgt:IsA("VehicleSeat")
            hoverPart=imp and nil or tgt
        else hoverPart=nil end
    end
end)
UIS.InputBegan:Connect(function(input,gp)
    if gp then return end
    if deleteWallEnabled and input.KeyCode==Enum.KeyCode.E and hoverPart then savePartForUndo(hoverPart); hoverPart:Destroy(); hoverPart=nil end
    if deleteWallEnabled and input.KeyCode==Enum.KeyCode.U then undoLastDelete() end
end)

-- ========== SMOOTH BLINK TP (KEYBIND T) ==========
mkSection(pMain, "Smooth Blink TP", 12)
local TweenService = game:GetService("TweenService")

local blinkEnabled = false
local blinkDistance = 6
local blinkSteps = 6
local blinkDelay = 0.05

-- Card
local blinkCard = mkCard(pMain, 70, 13)

-- Status
local blinkStatus = Instance.new("TextLabel", blinkCard)
blinkStatus.Size = UDim2.new(1, -16, 0, 20)
blinkStatus.Position = UDim2.new(0, 8, 0, 8)
blinkStatus.BackgroundTransparency = 1
blinkStatus.Text = "⚡ Smooth Blink: OFF (Tekan T)"
blinkStatus.TextColor3 = C.TEXTM
blinkStatus.TextSize = 9
blinkStatus.TextXAlignment = Enum.TextXAlignment.Left

-- Toggle
local blinkToggleRow = Instance.new("Frame", blinkCard)
blinkToggleRow.Size = UDim2.new(1, 0, 0, 32)
blinkToggleRow.Position = UDim2.new(0, 0, 0, 30)
blinkToggleRow.BackgroundTransparency = 1

local blinkToggleLabel = Instance.new("TextLabel", blinkToggleRow)
blinkToggleLabel.Size = UDim2.new(0.6, 0, 1, 0)
blinkToggleLabel.Position = UDim2.new(0, 8, 0, 0)
blinkToggleLabel.BackgroundTransparency = 1
blinkToggleLabel.Text = "Enable Smooth Blink"
blinkToggleLabel.TextColor3 = C.TEXT
blinkToggleLabel.TextSize = 10
blinkToggleLabel.TextXAlignment = Enum.TextXAlignment.Left

local blinkPill = Instance.new("Frame", blinkToggleRow)
blinkPill.Size = UDim2.new(0, 38, 0, 20)
blinkPill.Position = UDim2.new(1, -46, 0.5, -10)
blinkPill.BackgroundColor3 = C.GREY2
blinkPill.BorderSizePixel = 0
Instance.new("UICorner", blinkPill).CornerRadius = UDim.new(0.5, 0)

local blinkKnob = Instance.new("Frame", blinkPill)
blinkKnob.Size = UDim2.new(0, 14, 0, 14)
blinkKnob.Position = UDim2.new(0, 3, 0.5, -7)
blinkKnob.BackgroundColor3 = C.WHITE
blinkKnob.BorderSizePixel = 0
Instance.new("UICorner", blinkKnob).CornerRadius = UDim.new(0.5, 0)

local blinkToggleBtn = Instance.new("TextButton", blinkToggleRow)
blinkToggleBtn.Size = UDim2.new(1, 0, 1, 0)
blinkToggleBtn.BackgroundTransparency = 1
blinkToggleBtn.Text = ""

blinkToggleBtn.MouseButton1Click:Connect(function()
    blinkEnabled = not blinkEnabled
    TweenService:Create(blinkPill, TweenInfo.new(0.15), {
        BackgroundColor3 = blinkEnabled and C.GREEN or C.GREY2
    }):Play()
    TweenService:Create(blinkKnob, TweenInfo.new(0.15), {
        Position = blinkEnabled and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
    }):Play()
    blinkStatus.Text = blinkEnabled and "⚡ Smooth Blink: ON (Tekan T)" or "⚡ Smooth Blink: OFF (Tekan T)"
    blinkStatus.TextColor3 = blinkEnabled and C.GREEN or C.TEXTM
end)

-- Slider distance
local distRow = Instance.new("Frame", blinkCard)
distRow.Size = UDim2.new(1, 0, 0, 30)
distRow.Position = UDim2.new(0, 0, 0, 65)
distRow.BackgroundTransparency = 1

local distLabel = Instance.new("TextLabel", distRow)
distLabel.Size = UDim2.new(0.5, 0, 1, 0)
distLabel.Position = UDim2.new(0, 8, 0, 0)
distLabel.BackgroundTransparency = 1
distLabel.Text = "Blink Distance: " .. blinkDistance
distLabel.TextColor3 = C.TEXTM
distLabel.TextSize = 9
distLabel.TextXAlignment = Enum.TextXAlignment.Left

local function updateDistance(val)
    blinkDistance = val
    distLabel.Text = "Blink Distance: " .. blinkDistance
end

mkSlider(pMain, "", 1, 20, 6, 14, updateDistance)
-- Pindahin slider ke posisi yang bener (agak ribet, jadi skip dulu)

-- ========== FUNGSI SMOOTH BLINK ==========
local function SmoothBlink()
    if not blinkEnabled then return end
    
    local char = lp.Character
    if not char then return end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local direction = hrp.CFrame.LookVector
    local targetPos = hrp.Position + (direction * blinkDistance)
    local startPos = hrp.Position
    local delta = (targetPos - startPos) / blinkSteps
    
    -- Matikan collision bentar
    pcall(function() hrp.CanCollide = false end)
    
    for i = 1, blinkSteps do
        local newPos = startPos + (delta * i)
        hrp.CFrame = CFrame.new(newPos)
        task.wait(blinkDelay)
    end
    
    -- Balikin collision
    pcall(function() hrp.CanCollide = true end)
    
    print("✅ Smooth Blink - Distance:", blinkDistance, "Steps:", blinkSteps)
end

-- KEYBIND T
UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.T and blinkEnabled then
        SmoothBlink()
    end
end)


-- ================================================================
-- PAGE 2 — PLAYER (FOV FIXED - LANGSUNG MUNCUL)
-- ================================================================
local pPlayer = tabPages[2]
mkAlertCard(pPlayer,C.RED,"HARD WARNING !","Resiko ditanggung sendiri. Jangan terlalu sering dipakai.",0)
mkSection(pPlayer,"Silent Aim + Wallbang",1)

-- ========== SETTINGS ==========
local SilentAim = true
local SilentAimPart = "HumanoidRootPart"
local SilentAimWallbang = true
local FovSize = 250
local ShowFOV = true      -- <-- PERCAYA AJA TRUE
local FOVMode = "PC"      -- PC atau Mobile

-- ========== FOV CIRCLE ==========
local FovCircle = Drawing.new("Circle")
FovCircle.Radius = FovSize
FovCircle.Thickness = 2
FovCircle.Visible = true      -- <-- LANGSUNG TRUE
FovCircle.Color = Color3.fromRGB(255, 0, 0)
FovCircle.Transparency = 0.5
FovCircle.NumSides = 64
FovCircle.Filled = false

-- UPDATE FOV
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

RunService.RenderStepped:Connect(function()
    if FOVMode == "PC" then
        FovCircle.Position = UIS:GetMouseLocation()
    else
        local screenSize = Camera.ViewportSize
        FovCircle.Position = Vector2.new(screenSize.X / 2, screenSize.Y / 2)
    end
    FovCircle.Visible = true   -- <-- PAKSA MUNCUL SETIAP FRAME
end)

-- ==================== SILENT AIM + EXCLUDE (PASTI JALAN) ====================
local function GetTarget()
    if not lp.Character then return nil, nil end

    local closestPart, closestTarget = nil, nil
    local closestDist2D = FovSize + 1

    local fovCenter = (FOVMode == "PC") and UIS:GetMouseLocation() or Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= lp then
            -- ==================== EXCLUDE DI CEK DISINI ====================
            local isExcluded = false
            if _G.ExcludedPlayers and type(_G.ExcludedPlayers) == "table" then
                for i = 1, #_G.ExcludedPlayers do
                    if _G.ExcludedPlayers[i] == plr.Name then
                        isExcluded = true
                        break
                    end
                end
            end
            if isExcluded then
                -- LEWATI
            else
                local char = plr.Character
                if char then
                    local targetPart = char:FindFirstChild(SilentAimPart)
                    local hum = char:FindFirstChild("Humanoid")
                    if targetPart and hum and hum.Health > 0 then
                        local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                        if onScreen then
                            local dist2D = (fovCenter - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
                            if dist2D < closestDist2D then
                                closestDist2D = dist2D
                                closestPart = targetPart
                                closestTarget = plr
                            end
                        end
                    end
                end
            end
        end
    end
    return closestTarget, closestPart
end

-- HOOK CastBlacklist (PAKAI GetTarget)
local hooked = false
task.spawn(function()
    while not hooked do
        pcall(function()
            local CastBL, CastWL = nil, nil
            for _, v in pairs(getgc(true)) do
                if type(v) == "function" then
                    local info = debug.getinfo(v)
                    if info then
                        if info.name == "CastBlacklist" then CastBL = v
                        elseif info.name == "CastWhitelist" then CastWL = v
                        end
                    end
                end
            end
            
            if CastBL then
                hookfunction(CastBL, function(origin, direction, blacklist)
                    if not SilentAim then
                        local params = RaycastParams.new()
                        params.FilterType = Enum.RaycastFilterType.Blacklist
                        params.FilterDescendantsInstances = blacklist or {}
                        return workspace:Raycast(origin, direction, params)
                    end

                    -- ==================== PAKAI GetTarget UNTUK DAPATIN TARGET ====================
                    local target, targetPart = GetTarget()
                    
                    if target and targetPart then
                        local newDir = (targetPart.Position - origin).Unit * (direction.Magnitude or 500)
                        
                        if SilentAimWallbang and CastWL then
                            return CastWL(origin, newDir, {target.Character})
                        elseif not SilentAimWallbang then
                            local params = RaycastParams.new()
                            params.FilterType = Enum.RaycastFilterType.Blacklist
                            params.FilterDescendantsInstances = blacklist or {}
                            local hit = workspace:Raycast(origin, newDir, params)
                            if hit and hit.Instance and hit.Instance:IsDescendantOf(target.Character) then
                                return hit
                            end
                        end
                    end
                    
                    -- Default
                    local params = RaycastParams.new()
                    params.FilterType = Enum.RaycastFilterType.Blacklist
                    params.FilterDescendantsInstances = blacklist or {}
                    return workspace:Raycast(origin, direction, params)
                end)
                hooked = true
                print("✅ SILENT AIM + EXCLUDE READY")
            end
        end)
        task.wait(1)
    end
end)

-- ========== UI ==========
mkToggle(pPlayer, "Silent Aim", "Auto-aim ke target dalam FOV", 2, function(v) SilentAim = v end)
mkSlider(pPlayer, "FOV Radius", 50, 500, 250, 3, function(v) FovSize = v; FovCircle.Radius = v end)

mkSection(pPlayer, "FOV Mode", 4)
mkDropdown(pPlayer, "Select Mode", {"PC (Mouse)", "Mobile (Center)"}, 5, function(v)
    FOVMode = (v == "PC (Mouse)") and "PC" or "Mobile"
end)

mkSection(pPlayer, "Target Settings", 6)
mkDropdown(pPlayer, "Target Part", {"Head","HumanoidRootPart","UpperTorso","LowerTorso"}, 7, function(v) SilentAimPart = v end)

local toggleRow, setWB = mkToggle(pPlayer, "Wallbang", "Tembus tembok", 8, function(v) SilentAimWallbang = v end)
if setWB then
    setWB(true)
else
    print("[Warning] Wallbang toggle gagal dibuat")
end


-- Status Card (FOV PASTI ON)
local statusCard = mkCard(pPlayer, 34, 9)
local statusL = Instance.new("TextLabel", statusCard)
statusL.Size = UDim2.new(1, -20, 1, 0)
statusL.Position = UDim2.new(0, 10, 0, 0)
statusL.BackgroundTransparency = 1
statusL.Text = "🔴 FOV: " .. (FOVMode == "PC" and "Mouse" or "Center") .. " | Wallbang: ON"
statusL.Font = Enum.Font.GothamBold
statusL.TextSize = 9
statusL.TextColor3 = C.GREEN
statusL.TextXAlignment = Enum.TextXAlignment.Left


-- ========== NOCLIP ==========
mkSection(pPlayer, "Noclip", 9)
local noclipEnabled=false; local opp={}
local function shp(inst,prop,val) pcall(function() sethiddenproperty(inst,prop,val) end) end
local function excl(part)
    return (part.Name=="default") or (part.Name=="Sidewalk") or (part.Name=="Floor") or
        (part.Name=="Collision") or part:IsDescendantOf(lp.Character) or
        (part.Parent and Players:GetPlayerFromCharacter(part.Parent)~=nil) or part:IsA("VehicleSeat")
end
local function updNoclip()
    local pp=Camera.CFrame.Position; local r=15
    local region=Region3.new(pp-Vector3.new(r,r,r),pp+Vector3.new(r,r,r))
    for _,part in ipairs(workspace:FindPartsInRegion3(region,nil,math.huge)) do
        if part:IsA("BasePart") and not excl(part) and not opp[part] then
            opp[part]={CanCollide=part.CanCollide}; shp(part,"CanCollide",false)
        end
    end
end
local function resetNoclip() for part,props in pairs(opp) do if part:IsA("BasePart") then shp(part,"CanCollide",props.CanCollide) end end; opp={} end
mkToggle(pPlayer, "Noclip (Tembus Dinding)", "Melewati semua dinding & objek", 10, function(enabled)
    noclipEnabled=enabled
    if noclipEnabled then spawn(function() while noclipEnabled do updNoclip(); wait(0.1) end end)
    else resetNoclip() end
end)

-- ========== INSTANT INTERACT TOGGLE ==========
mkSection(pPlayer, "Instant Interact", 10)

local instantInteractEnabled = false
local function patchPrompt(prompt)
    pcall(function()
        prompt.HoldDuration = 0
        prompt.RequiresLineOfSight = false
        if prompt.ButtonHoldEnabled then
            prompt.ButtonHoldEnabled = false
        end
        prompt.ClickablePrompt = true
    end)
end

local function applyInstantInteract()
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            patchPrompt(obj)
        end
    end
end

local function startInstantInteract()
    instantInteractEnabled = true
    applyInstantInteract()
    -- Auto-patch prompt baru
    instantInteractConnection = workspace.DescendantAdded:Connect(function(obj)
        if instantInteractEnabled and obj:IsA("ProximityPrompt") then
            patchPrompt(obj)
        end
    end)
    print("✅ Instant Interact ON")
end

local function stopInstantInteract()
    instantInteractEnabled = false
    if instantInteractConnection then
        instantInteractConnection:Disconnect()
        instantInteractConnection = nil
    end
    print("❌ Instant Interact OFF")
end

local instantToggle, setInstantToggle = mkToggle(pPlayer, "Instant Interact", "Interact NPC tanpa nahan tombol", 11, function(v)
    if v then
        startInstantInteract()
    else
        stopInstantInteract()
    end
end)
setInstantToggle(false)  -- Default OFF


-- ========== AIMBOT ==========
mkSection(pPlayer, "Aimbot", 11)
local aimbotEnabled=false; local aimbotFov=200; local aimbotConn=nil
local function FindAimbotTarget()
    local cl,dist=nil,math.huge
    for _,v in ipairs(Players:GetPlayers()) do
        if v~=lp then
            local char=v.Character
            if char and char:FindFirstChild("Head") and char:FindFirstChild("Humanoid") and char.Humanoid.Health>0 then
                local sp,on=Camera:WorldToViewportPoint(char.Head.Position)
                if on then
                    local d=(Vector2.new(sp.X,sp.Y)-UIS:GetMouseLocation()).Magnitude
                    if d<aimbotFov and d<dist then dist=d; cl=v end
                end
            end
        end
    end
    return cl
end
mkToggle(pPlayer, "Aimbot", "Magnet mouse ke target", 12, function(v)
    aimbotEnabled=v
    if aimbotEnabled then
        if aimbotConn then aimbotConn:Disconnect() end
        aimbotConn=RS.RenderStepped:Connect(function()
            local tgt=FindAimbotTarget()
            if tgt and tgt.Character and tgt.Character:FindFirstChild("Head") then
                local sp,on=Camera:WorldToViewportPoint(tgt.Character.Head.Position)
                if on then UIS:SetMouseDeltaEnabled(false); pcall(function() UIS:SetMousePosition(sp.X,sp.Y) end) end
            end
        end)
    else if aimbotConn then aimbotConn:Disconnect(); aimbotConn=nil end end
end)
mkSlider(pPlayer, "Aimbot FOV", 10, 400, 200, 13, function(v) aimbotFov=v end)

-- ========== VEHICLE FLY ==========
mkSection(pPlayer, "Vehicle Fly", 14)
local vehicleFlyEnabled = false
local flySpeed = 50
local flyConnection = nil
local activeKeys = {W=false, A=false, S=false, D=false, E=false, Q=false}
local function getCurrentVehicle()
    local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
    local seat = hum and hum.SeatPart
    if seat then
        local vehicle = seat:FindFirstAncestorWhichIsA("Model")
        if vehicle then return vehicle, seat end
        return seat, seat
    end
    return nil, nil
end
local function updateFly(dt)
    if not vehicleFlyEnabled then return end
    local vehicle, seat = getCurrentVehicle()
    if not vehicle then return end
    local primary = vehicle:IsA("Model") and vehicle.PrimaryPart or seat
    if not primary then return end
    local camCFrame = workspace.CurrentCamera.CFrame
    local forward = camCFrame.LookVector
    local right = camCFrame.RightVector
    local up = camCFrame.UpVector
    local moveDir = Vector3.new(0,0,0)
    if activeKeys.W then moveDir = moveDir + forward end
    if activeKeys.S then moveDir = moveDir - forward end
    if activeKeys.D then moveDir = moveDir + right end
    if activeKeys.A then moveDir = moveDir - right end
    if activeKeys.E then moveDir = moveDir + up end
    if activeKeys.Q then moveDir = moveDir - up end
    if moveDir.Magnitude > 0 then
        moveDir = moveDir.Unit * flySpeed * dt
        primary.CFrame = primary.CFrame + moveDir
        if primary:IsA("BasePart") then
            primary.Velocity = Vector3.new(0,0,0)
            primary.RotVelocity = Vector3.new(0,0,0)
        end
    end
end
local function startFly() if flyConnection then flyConnection:Disconnect() end; flyConnection = RS.RenderStepped:Connect(updateFly) end
local function stopFly() if flyConnection then flyConnection:Disconnect(); flyConnection = nil end end
local flyToggle, setFlyToggle = mkToggle(pPlayer, "Vehicle Fly", "Kendaraan terbang dengan kontrol W A S D E Q (ikuti kamera)", 15, function(v)
    vehicleFlyEnabled = v
    if v then startFly() else stopFly() end
end)
mkSlider(pPlayer, "Fly Speed", 20, 200, 50, 16, function(v) flySpeed = v end)

UIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed or not vehicleFlyEnabled then return end
    local key = input.KeyCode
    if key == Enum.KeyCode.W then activeKeys.W = true end
    if key == Enum.KeyCode.A then activeKeys.A = true end
    if key == Enum.KeyCode.S then activeKeys.S = true end
    if key == Enum.KeyCode.D then activeKeys.D = true end
    if key == Enum.KeyCode.E then activeKeys.E = true end
    if key == Enum.KeyCode.Q then activeKeys.Q = true end
end)
UIS.InputEnded:Connect(function(input, gameProcessed)
    if gameProcessed or not vehicleFlyEnabled then return end
    local key = input.KeyCode
    if key == Enum.KeyCode.W then activeKeys.W = false end
    if key == Enum.KeyCode.A then activeKeys.A = false end
    if key == Enum.KeyCode.S then activeKeys.S = false end
    if key == Enum.KeyCode.D then activeKeys.D = false end
    if key == Enum.KeyCode.E then activeKeys.E = false end
    if key == Enum.KeyCode.Q then activeKeys.Q = false end
end)

-- ========== EXCLUDED PLAYERS (PALING BAWAH PAGE 2) ==========
-- Letakkan SETELAH Vehicle Fly

mkSection(pPlayer, "Excluded Players", 20)

_G.ExcludedPlayers = {}

-- Refresh list player buat dropdown
local function RefreshPlayerList()
    local players = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= lp then
            table.insert(players, plr.Name)
        end
    end
    return players
end

-- Status card excluded (buat dulu)
local excludedCard = mkCard(pPlayer, 30, 21)
local excludedListLabel = Instance.new("TextLabel", excludedCard)
excludedListLabel.Size = UDim2.new(1, -16, 1, 0)
excludedListLabel.Position = UDim2.new(0, 8, 0, 0)
excludedListLabel.BackgroundTransparency = 1
excludedListLabel.Text = "🚫 Excluded: None"
excludedListLabel.TextColor3 = C.TEXTM
excludedListLabel.TextSize = 8
excludedListLabel.TextXAlignment = Enum.TextXAlignment.Left
excludedListLabel.ZIndex = 5

-- Dropdown pilih player
local selectedPlayer = ""
local playerDropdown = mkDropdown(pPlayer, "Select Player", RefreshPlayerList(), 22, function(v)
    selectedPlayer = v
end)

-- Tombol Exclude
local excludeBtn = mkBtn(pPlayer, "Exclude Selected Player", 23, C.RED, function()
    if selectedPlayer ~= "" then
        local alreadyExcluded = false
        for i = 1, #ExcludedPlayers do
            if ExcludedPlayers[i] == selectedPlayer then
                alreadyExcluded = true
                break
            end
        end
        if not alreadyExcluded then
            table.insert(ExcludedPlayers, selectedPlayer)
            print("✅ Excluded:", selectedPlayer)
            local excludedText = ""
            for i = 1, #ExcludedPlayers do
                if excludedText ~= "" then
                    excludedText = excludedText .. ", "
                end
                excludedText = excludedText .. ExcludedPlayers[i]
            end
            excludedListLabel.Text = "🚫 Excluded: " .. (excludedText ~= "" and excludedText or "None")
        end
    end
end)   -- <-- HARUSNYA end DOANG, TANPA KURUNG

-- Tombol Un-exclude
local unexcludeBtn = mkBtn(pPlayer, "Unexclude Selected Player", 24, C.GREY2, function()
    if selectedPlayer ~= "" then
        for i = 1, #ExcludedPlayers do
            if ExcludedPlayers[i] == selectedPlayer then
                table.remove(ExcludedPlayers, i)
                print("✅ Unexcluded:", selectedPlayer)
                break
            end
        end
        local excludedText = ""
        for i = 1, #ExcludedPlayers do
            if excludedText ~= "" then
                excludedText = excludedText .. ", "
            end
            excludedText = excludedText .. ExcludedPlayers[i]
        end
        excludedListLabel.Text = "🚫 Excluded: " .. (excludedText ~= "" and excludedText or "None")
    end
end)   -- <-- HARUSNYA end DOANG, TANPA KURUNG

-- Tombol Clear All Excluded
local clearBtn = mkBtn(pPlayer, "Clear All Excluded", 25, C.YELLOW, function()
    _G.ExcludedPlayers = {}
    excludedListLabel.Text = "🚫 Excluded: None"
    print("✅ All excluded cleared")
end)

-- Update player list otomatis
local function updatePlayerDropdown()
    if playerDropdown and playerDropdown.Parent then
        playerDropdown.Parent = nil
    end
    playerDropdown = mkDropdown(pPlayer, "Select Player", RefreshPlayerList(), 22, function(v)
        selectedPlayer = v
    end)
end

Players.PlayerAdded:Connect(function()
    task.wait(0.5)
    updatePlayerDropdown()
end)

Players.PlayerRemoving:Connect(function()
    task.wait(0.5)
    updatePlayerDropdown()
end)


-- ================================================================
-- PAGE 3 — TELEPORT (ORIGINAL)
-- ================================================================
local pTeleport = tabPages[3]
mkAlertCard(pTeleport, C.YELLOW, "WARNING MEDIUM !", "Pilih mode lalu lokasi.", 0)
mkSection(pTeleport, "Teleport Mode", 1)

local useRespawnMode = false
local modeCard = mkCard(pTeleport, 40, 2)
local modeContainer = Instance.new("Frame", modeCard)
modeContainer.Size = UDim2.new(0, 160, 0, 28); modeContainer.Position = UDim2.new(0.5, -80, 0.5, -14); modeContainer.BackgroundTransparency = 1

local motorModeBtn = Instance.new("TextButton", modeContainer)
motorModeBtn.Size = UDim2.new(0, 78, 1, 0); motorModeBtn.Position = UDim2.new(0, 0, 0, 0)
motorModeBtn.BackgroundColor3 = C.BLUE; motorModeBtn.Text = "MOTOR"; motorModeBtn.Font = Enum.Font.GothamBold
motorModeBtn.TextSize = 10; motorModeBtn.BorderSizePixel = 0; Instance.new("UICorner", motorModeBtn).CornerRadius = UDim.new(0, 6)
local motorStk = Instance.new("UIStroke", motorModeBtn); motorStk.Color = C.BORDERL

local respawnModeBtn = Instance.new("TextButton", modeContainer)
respawnModeBtn.Size = UDim2.new(0, 78, 1, 0); respawnModeBtn.Position = UDim2.new(1, -78, 0, 0)
respawnModeBtn.BackgroundColor3 = C.SURF2; respawnModeBtn.Text = "RESPAWN"; respawnModeBtn.Font = Enum.Font.GothamBold
respawnModeBtn.TextSize = 10; respawnModeBtn.BorderSizePixel = 0; Instance.new("UICorner", respawnModeBtn).CornerRadius = UDim.new(0, 6)
local respawnStk = Instance.new("UIStroke", respawnModeBtn); respawnStk.Color = C.BORDERL

local function setModeActive(which)
    if which == "motor" then
        useRespawnMode = false
        motorModeBtn.BackgroundColor3 = C.WHITE; motorModeBtn.TextColor3 = C.BG; motorStk.Color = C.GREY2
        respawnModeBtn.BackgroundColor3 = C.GREY2; respawnModeBtn.TextColor3 = C.WHITE; respawnStk.Color = C.BORDERL
    else
        useRespawnMode = true
        respawnModeBtn.BackgroundColor3 = C.WHITE; respawnModeBtn.TextColor3 = C.BG; respawnStk.Color = C.GREY2
        motorModeBtn.BackgroundColor3 = C.GREY2; motorModeBtn.TextColor3 = C.WHITE; motorStk.Color = C.BORDERL
    end
end
motorModeBtn.MouseButton1Click:Connect(function() setModeActive("motor") end)
respawnModeBtn.MouseButton1Click:Connect(function() setModeActive("respawn") end)
setModeActive("motor")

local cachedSeat = nil
local function updateSeatCache()
    local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
    cachedSeat = hum and hum.SeatPart or nil
end
local function hookChar(char)
    local hum = char:WaitForChild("Humanoid", 10)
    if hum then hum:GetPropertyChangedSignal("SeatPart"):Connect(updateSeatCache) end
    updateSeatCache()
end
if lp.Character then hookChar(lp.Character) end
lp.CharacterAdded:Connect(hookChar)

local tpDestination = nil; local isRespawning = false
local function onCharAdded(char)
    if not tpDestination then return end
    task.spawn(function()
        local hrp = char:WaitForChild("HumanoidRootPart", 10); local hum = char:WaitForChild("Humanoid", 10)
        if hrp and hum then
            repeat task.wait(0.1) until hum.Health > 0
            task.wait(0.3)
            pcall(function() hrp.CFrame = CFrame.new(tpDestination.x, tpDestination.y + 3, tpDestination.z) end)
        end
        tpDestination = nil; isRespawning = false
    end)
end
if lp.Character then onCharAdded(lp.Character) end
lp.CharacterAdded:Connect(onCharAdded)

local function teleportTo(pos)
    if useRespawnMode then
        if isRespawning then return end
        local hum = lp.Character and lp.Character:FindFirstChild("Humanoid")
        tpDestination = {x = pos.X, y = pos.Y, z = pos.Z}; isRespawning = true
        if hum and hum.Health > 0 then hum.Health = 0 end
    else
        if not cachedSeat then return end
        local vm = cachedSeat:FindFirstAncestorWhichIsA("Model")
        if vm and vm.PrimaryPart then vm:SetPrimaryPartCFrame(CFrame.new(pos.X, pos.Y + 2, pos.Z))
        elseif cachedSeat then cachedSeat.CFrame = CFrame.new(pos.X, pos.Y + 2, pos.Z) end
    end
end

local LOCATIONS = {
    {"Dealer NPC",       Vector3.new(770.992,  3.71,   433.75)},
    {"NPC Marshmallow",  Vector3.new(510.061,  4.476,  600.548)},
    {"Apart 1",          Vector3.new(1137.992, 9.932,  449.753)},
    {"Apart 2",          Vector3.new(1139.174, 9.932,  420.556)},
    {"Apart 3",          Vector3.new(984.856,  9.932,  247.280)},
    {"Apart 4",          Vector3.new(988.311,  9.932,  221.664)},
    {"Apart 5",          Vector3.new(923.954,  9.932,  42.202)},
    {"Apart 6",          Vector3.new(895.721,  9.932,  41.928)},
    {"Casino",           Vector3.new(1166.33,   3.36,   -29.77)},
    {"GS UJUNG",         Vector3.new(-466.525,  3.862,  357.661)},
    {"GS BINARY",        Vector3.new(-280.351,  3.742,  248.872)},
    {"GS MID",           Vector3.new(218.427,   3.737,  -176.975)},
}

mkSection(pTeleport, "Lokasi", 3)
for i, loc in ipairs(LOCATIONS) do
    local row = mkCard(pTeleport, 36, 10 + i)
    local nameLbl = Instance.new("TextLabel", row)
    nameLbl.Size = UDim2.new(0.6, 0, 1, 0); nameLbl.Position = UDim2.new(0, 10, 0, 0); nameLbl.BackgroundTransparency = 1
    nameLbl.Text = loc[1]; nameLbl.Font = Enum.Font.Gotham; nameLbl.TextSize = 9; nameLbl.TextColor3 = C.TEXT
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
    local tpBtn = mkBtn(row, "Teleport", 0, C.GREY2, function() teleportTo(loc[2]) end)
    tpBtn.Size = UDim2.new(0, 70, 0, 24); tpBtn.Position = UDim2.new(1, -80, 0.5, -12)
    tpBtn.TextSize = 9; tpBtn.TextColor3 = C.TEXT
    local btnStk = tpBtn:FindFirstChildOfClass("UIStroke")
    if btnStk then btnStk.Color = C.BORDER end
end

local stCard = mkCard(pTeleport, 26, 10 + #LOCATIONS + 1)
local stL = Instance.new("TextLabel", stCard)
stL.Size = UDim2.new(1, -16, 1, 0); stL.Position = UDim2.new(0, 8, 0, 0); stL.BackgroundTransparency = 1
stL.Text = "Not in vehicle"; stL.Font = Enum.Font.Gotham; stL.TextSize = 8; stL.TextColor3 = C.TEXTM
stL.TextXAlignment = Enum.TextXAlignment.Left; stL.ZIndex = 5
RS.Heartbeat:Connect(function()
    if cachedSeat then stL.Text = "In vehicle - Motor mode ready"; stL.TextColor3 = C.GREEN
    else stL.Text = "Not in vehicle"; stL.TextColor3 = C.TEXTM end
end)

-- ================================================================
-- PAGE 4 — ESP (ORIGINAL)
-- ================================================================
local pESP = tabPages[4]
mkAlertCard(pESP, C.GREEN, "SAFE", "Hanya visual, tidak membahayakan.", 0)
mkSection(pESP, "Player ESP", 1)
local espEnabled=false; local espMaxDist=150; local espCache={}; local lastEspUpdate=0
local function createESP(player)
    if espCache[player] then for _,o in pairs(espCache[player]) do pcall(function() o:Remove() end) end end
    local box=Drawing.new("Square"); box.Thickness=1; box.Color=C.GREEN; box.Filled=false
    local nameL=Drawing.new("Text"); nameL.Text=player.Name; nameL.Size=9; nameL.Font=1; nameL.Color=C.WHITE; nameL.Outline=true; nameL.Center=true
    local hpBg=Drawing.new("Square"); hpBg.Thickness=1; hpBg.Color=Color3.fromRGB(30,30,30); hpBg.Filled=true
    local hpFl=Drawing.new("Square"); hpFl.Thickness=1; hpFl.Color=Color3.fromRGB(72,215,115); hpFl.Filled=true
    local dL=Drawing.new("Text"); dL.Size=9; dL.Font=1; dL.Color=C.TEXTM; dL.Outline=true; dL.Center=true
    espCache[player]={box,nameL,hpBg,hpFl,dL}
end
local function removeESP(p) if espCache[p] then for _,o in pairs(espCache[p]) do pcall(function() o:Remove() end) end; espCache[p]=nil end end
for _,p in pairs(Players:GetPlayers()) do if p~=lp then createESP(p) end end
Players.PlayerAdded:Connect(function(p) if p~=lp then createESP(p) end end)
Players.PlayerRemoving:Connect(removeESP)
mkToggle(pESP,"Player ESP","Box, Name, Health, Distance",2,function(v) espEnabled=v end)
mkSlider(pESP, "Maximum Distance", 10, 1000, 600, 3, function(v) espMaxDist = v end)
local espUpdateCooldown = 0
RS.RenderStepped:Connect(function(dt)
    if not espEnabled then 
        for _,drawings in pairs(espCache) do 
            for _,o in pairs(drawings) do 
                pcall(function() o.Visible=false end) 
            end 
        end 
        return 
    end
    
    espUpdateCooldown = espUpdateCooldown + dt
    if espUpdateCooldown < 0.2 then return end  -- Update 5 FPS aja
    local myChar=lp.Character; local myHRP=myChar and myChar:FindFirstChild("HumanoidRootPart"); local myPos=myHRP and myHRP.Position
    local vX,vY=Camera.ViewportSize.X,Camera.ViewportSize.Y
    for player,drawings in pairs(espCache) do
        local box,nameL,hpBg,hpFl,dL=unpack(drawings)
        local char=player.Character; local hum=char and char:FindFirstChildOfClass("Humanoid")
        local root=char and char:FindFirstChild("HumanoidRootPart"); local head=char and char:FindFirstChild("Head")
        if not (char and hum and root and head and hum.Health>0) then
            for _,o in pairs(drawings) do o.Visible=false end
        else
            local d3=myPos and (root.Position-myPos).Magnitude or 0
            if d3>espMaxDist then for _,o in pairs(drawings) do o.Visible=false end
            else
                local rp,rOn=Camera:WorldToViewportPoint(root.Position)
                local hp,hOn=Camera:WorldToViewportPoint(head.Position)
                if rOn and hOn then
                    local height=math.abs(hp.Y-rp.Y)*1.5+8; local width=height*0.5
                    local bX=rp.X-width/2; local bY=hp.Y-4
                    if bX+width>0 and bX<vX and bY+height>0 and bY<vY then
                        box.Color=C.GREEN; box.Size=Vector2.new(width,height); box.Position=Vector2.new(bX,bY); box.Visible=true
                        nameL.Text=player.Name; nameL.Color=C.WHITE; nameL.Position=Vector2.new(rp.X,bY-12); nameL.Visible=true
                        local hpPct=math.clamp(hum.Health/hum.MaxHealth,0,1)
                        hpBg.Size=Vector2.new(3,height-4); hpBg.Position=Vector2.new(bX-7,bY+2); hpBg.Visible=true
                        hpFl.Color=Color3.fromRGB(255*(1-hpPct),255*hpPct,80)
                        hpFl.Size=Vector2.new(2,(height-6)*hpPct)
                        hpFl.Position=Vector2.new(bX-6,bY+3+(height-6)*(1-hpPct)); hpFl.Visible=true
                        dL.Text=math.floor(d3).."m"; dL.Position=Vector2.new(rp.X,bY+height+2); dL.Visible=true
                    else for _,o in pairs(drawings) do o.Visible=false end end
                else for _,o in pairs(drawings) do o.Visible=false end end
            end
        end
    end
end)

-- ================================================================
-- PAGE 5 — CREDIT (ORIGINAL)
-- ================================================================
local pCredit = tabPages[6]

local devCard = mkCard(pCredit, 80, 1)

local devTitle = Instance.new("TextLabel", devCard)
devTitle.Size = UDim2.new(1, -16, 0, 22)
devTitle.Position = UDim2.new(0, 8, 0, 8)
devTitle.BackgroundTransparency = 1
devTitle.Text = "SILENT HUB v1.0"
devTitle.Font = Enum.Font.GothamBlack
devTitle.TextSize = 14
devTitle.TextColor3 = C.TEXT
devTitle.TextXAlignment = Enum.TextXAlignment.Left

local devSub = Instance.new("TextLabel", devCard)
devSub.Size = UDim2.new(1, -16, 0, 14)
devSub.Position = UDim2.new(0, 8, 0, 32)
devSub.BackgroundTransparency = 1
devSub.Text = "Developed by MASGAL x DRKY"
devSub.Font = Enum.Font.GothamBold
devSub.TextSize = 10
devSub.TextColor3 = C.ACCB
devSub.TextXAlignment = Enum.TextXAlignment.Left

local teamL = Instance.new("TextLabel", devCard)
teamL.Size = UDim2.new(1, -16, 0, 12)
teamL.Position = UDim2.new(0, 8, 0, 48)
teamL.BackgroundTransparency = 1
teamL.Text = "Team: SILENT TEAM"
teamL.Font = Enum.Font.Gotham
teamL.TextSize = 9
teamL.TextColor3 = C.TEXTM
teamL.TextXAlignment = Enum.TextXAlignment.Left


mkSection(pCredit, "Links", 4)
mkBtn(pCredit, "📋  Copy Discord Link", 5, C.DISCORD, function()
    pcall(function() if setclipboard then setclipboard("https://discord.gg/silenthub") end end)
end)

local thanksF = mkCard(pCredit, 32, 6)
local thL = Instance.new("TextLabel", thanksF)
thL.Size = UDim2.new(1, 0, 1, 0); thL.BackgroundTransparency = 1
thL.Text = "✦  Thanks for using Silent Hub  ✦"; thL.Font = Enum.Font.GothamBold; thL.TextSize = 9
thL.TextColor3 = C.ACCB; thL.TextXAlignment = Enum.TextXAlignment.Center; thL.ZIndex = 5
task.spawn(function()
    local t = 0
    while thL and thL.Parent do
        t = t + 0.025
        thL.TextColor3 = Color3.fromRGB(math.floor(180 + 40 * math.sin(t)), math.floor(180 + 30 * math.sin(t + 2)), math.floor(215 - 20 * math.sin(t + 4)))
        task.wait(0.05)
    end
end)

-- ================================================================
-- STARTUP
-- ================================================================
Win.Size = UDim2.new(0,0,0,0)
Win.BackgroundTransparency = 1
tw(Win, {Size = UDim2.new(0, WW, 0, WH), BackgroundTransparency = 0}, 0.4, Enum.EasingStyle.Back)
task.wait(0.1)
for i = 1, 2 do RS.RenderStepped:Wait() end
task.wait(0.05)
switchTab(2)



print("✅ Silent Hub Improved: Silent Aim Range Unlimited + Wallbang + Dual Method")
print("🎯 Jarak tidak terbatas (unlimited range)")
