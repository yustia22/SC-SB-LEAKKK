-- XYLUS | INF STAMINA + SILENT AIM + NOCLIP + ESP
-- Menggunakan LinoriaLib (stabil)

-- LOAD LINORIA LIBRARY
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/refs/heads/main/Library.lua"))()

-- INISIALISASI WINDOW
local Window = Library:CreateWindow({
    Title = "Xylus | Inf Stamina + Silent Aim + Noclip + ESP",
    Center = true,
    AutoShow = true,
    TabWidth = 120,
})

-- BUAT TAB
local MainTab = Window:AddTab("Main")
local CombatTab = Window:AddTab("Combat")
local VisualsTab = Window:AddTab("Visuals")

-- ==================== VARIABEL GLOBAL ====================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- ==================== INF STAMINA ====================
local StaminaBox = MainTab:AddLeftGroupbox("Infinite Stamina")

local staminaHooked = false
local staminaConnection = nil

StaminaBox:AddToggle("InfStamina", {
    Text = "Infinite Stamina",
    Default = false,
    Callback = function(Value)
        if Value and not staminaHooked then
            for _, v in pairs(getgc(true)) do
                if type(v) == "table" then
                    for k, _ in pairs(v) do
                        if k == "Stamina" then
                            local mt = getmetatable(v)
                            if mt then
                                setreadonly(mt, false)
                                local oldIndex = mt.__index
                                local oldNewIndex = mt.__newindex
                                
                                mt.__index = function(t, k2)
                                    if k2 == "Stamina" then
                                        return 100
                                    end
                                    return oldIndex and oldIndex(t, k2)
                                end
                                
                                mt.__newindex = function(t, k2, v2)
                                    if k2 == "Stamina" then
                                        return
                                    end
                                    if oldNewIndex then
                                        oldNewIndex(t, k2, v2)
                                    end
                                end
                                
                                staminaHooked = true
                            end
                            
                            staminaConnection = RunService.Heartbeat:Connect(function()
                                if Value then
                                    v.Stamina = 100
                                    if v.createLowStamina then
                                        v.createLowStamina = function() end
                                    end
                                end
                            end)
                            break
                        end
                    end
                end
                if staminaHooked then break end
            end
            Library:Notify("Infinite Stamina Activated", 3)
        elseif not Value and staminaConnection then
            staminaConnection:Disconnect()
            staminaConnection = nil
            Library:Notify("Infinite Stamina Deactivated", 2)
        end
    end
})

-- ==================== SILENT AIM (CAST METHOD) ====================
local SilentBox = CombatTab:AddLeftGroupbox("Silent Aim (Cast)")

local SilentAim = false
local SilentAimPart = "HumanoidRootPart"
local SilentAimWallbang = false
local MaxWallbangDistance = 500

-- FOV Circle
local FovCircle = Drawing.new("Circle")
FovCircle.Radius = 150
FovCircle.NumSides = 64
FovCircle.Thickness = 1.5
FovCircle.Visible = false
FovCircle.Color = Color3.fromRGB(0, 255, 0)
FovCircle.Transparency = 0.6
FovCircle.Filled = false

RunService.RenderStepped:Connect(function()
    FovCircle.Position = UserInputService:GetMouseLocation()
    FovCircle.Visible = SilentAim
end)

local FOVSlider = SilentBox:AddSlider("FOV", {
    Text = "FOV Radius",
    Default = 150,
    Min = 10,
    Max = 500,
    Rounding = 0,
    Callback = function(v)
        FovCircle.Radius = v
    end
})

SilentBox:AddToggle("SilentAimToggle", {
    Text = "Silent Aim",
    Default = false,
    Callback = function(v)
        SilentAim = v
        Library:Notify(v and "Silent Aim ON" or "Silent Aim OFF", 3)
    end
})

SilentBox:AddToggle("WallbangToggle", {
    Text = "Wallbang",
    Default = false,
    Callback = function(v) SilentAimWallbang = v end
})

SilentBox:AddSlider("WallbangDist", {
    Text = "Wallbang Distance",
    Default = 500,
    Min = 10,
    Max = 5000,
    Rounding = 0,
    Callback = function(v) MaxWallbangDistance = v end
})

SilentBox:AddDropdown("TargetPart", {
    Text = "Target Part",
    Values = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"},
    Default = 2,
    Callback = function(v) SilentAimPart = v end
})

-- GetFovTarget
local function GetFovTarget(Circle, HitPart)
    local Target = nil
    local LowestDistance = math.huge
    for _, v in ipairs(Players:GetPlayers()) do
        if v ~= LocalPlayer then
            local Char = v.Character
            if Char then
                local Part = Char:FindFirstChild(HitPart)
                local Humanoid = Char:FindFirstChild("Humanoid")
                if Part and Humanoid and Humanoid.Health > 0 then
                    local ScreenPos, OnScreen = Camera:WorldToViewportPoint(Part.Position)
                    if OnScreen then
                        local Distance = (Circle.Position - Vector2.new(ScreenPos.X, ScreenPos.Y)).Magnitude
                        if Distance < Circle.Radius and Distance < LowestDistance then
                            Target = v
                            LowestDistance = Distance
                        end
                    end
                end
            end
        end
    end
    return Target
end

-- Cari CastBlacklist
local function SearchGc(FunctionName)
    local gc = getgc(true)
    for _, v in pairs(gc) do
        if type(v) == "function" then
            local info = debug.getinfo(v)
            if info and info.name == FunctionName then
                return v
            end
        end
    end
    return nil
end

local CastBlacklist = SearchGc("CastBlacklist")
local CastWhitelist = SearchGc("CastWhitelist")

if CastBlacklist and CastWhitelist then
    local OldCastBlacklist = hookfunction(CastBlacklist, function(...)
        if SilentAim then
            local target = GetFovTarget(FovCircle, SilentAimPart)
            if target then
                local args = {...}
                local part = target.Character and target.Character:FindFirstChild(SilentAimPart)
                if part then
                    args[2] = part.Position - args[1]
                    if SilentAimWallbang then
                        if args[2].Magnitude <= MaxWallbangDistance then
                            args[3] = {target.Character}
                            return CastWhitelist(unpack(args))
                        end
                    end
                    return OldCastBlacklist(unpack(args))
                end
            end
        end
        return OldCastBlacklist(...)
    end)
    Library:Notify("Silent Aim Hooked (CastBlacklist)", 4)
else
    SilentBox:AddLabel("⚠️ CastBlacklist/Whitelist not found!")
end

-- ==================== NOCLIP ====================
local NoclipBox = MainTab:AddRightGroupbox("Noclip")

local noclipActive = false
local originalCollision = {}

local function setNoclip(state)
    local char = LocalPlayer.Character
    if not char then return end
    
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            if state then
                if originalCollision[part] == nil then
                    originalCollision[part] = part.CanCollide
                end
                part.CanCollide = false
            else
                part.CanCollide = originalCollision[part] ~= false
            end
        end
    end
end

NoclipBox:AddToggle("Noclip", {
    Text = "Noclip",
    Default = false,
    Callback = function(state)
        noclipActive = state
        setNoclip(state)
        Library:Notify(state and "Noclip ON" or "Noclip OFF", 2)
    end
})

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    if noclipActive then
        setNoclip(true)
    end
end)

-- ==================== ESP ====================
local ESPBox = VisualsTab:AddLeftGroupbox("Player ESP")

local espEnabled = false
local espMaxDist = 150
local espCache = {}

local function createESP(player)
    if espCache[player] then
        for _, o in pairs(espCache[player]) do pcall(function() o:Remove() end) end
    end

    local box = Drawing.new("Square")
    box.Thickness = 1
    box.Color = Color3.fromRGB(255, 255, 255)
    box.Filled = false
    box.Visible = false

    local nameL = Drawing.new("Text")
    nameL.Text = player.Name
    nameL.Size = 11
    nameL.Font = 1
    nameL.Color = Color3.fromRGB(255, 255, 255)
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

for _, plr in ipairs(Players:GetPlayers()) do
    if plr ~= LocalPlayer then createESP(plr) end
end

Players.PlayerAdded:Connect(function(p)
    if p ~= LocalPlayer then createESP(p) end
end)

Players.PlayerRemoving:Connect(removeESP)

ESPBox:AddToggle("ESP", {
    Text = "Player ESP",
    Default = false,
    Callback = function(v) espEnabled = v end
})

ESPBox:AddSlider("MaxDist", {
    Text = "Max Distance",
    Default = 150,
    Min = 10,
    Max = 500,
    Rounding = 0,
    Callback = function(v) espMaxDist = v end
})

-- ESP Render
RunService.RenderStepped:Connect(function()
    if not espEnabled then return end
    
    local myChar = LocalPlayer.Character
    local myPos = myChar and myChar:FindFirstChild("HumanoidRootPart") and myChar.HumanoidRootPart.Position
    
    for player, drawings in pairs(espCache) do
        local box, nameL, hpBg, hpFl, dL = unpack(drawings)
        
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local head = char and char:FindFirstChild("Head")
        
        if not (char and hum and root and head and hum.Health > 0) then
            box.Visible = false
            nameL.Visible = false
            hpBg.Visible = false
            hpFl.Visible = false
            dL.Visible = false
        else
            local dist = myPos and (root.Position - myPos).Magnitude or 9999
            if dist > espMaxDist then
                box.Visible = false
                nameL.Visible = false
                hpBg.Visible = false
                hpFl.Visible = false
                dL.Visible = false
            else
                local rootPos, rootOn = Camera:WorldToViewportPoint(root.Position)
                local headPos, headOn = Camera:WorldToViewportPoint(head.Position)
                
                if rootOn and headOn then
                    local height = math.abs(headPos.Y - rootPos.Y) * 1.7
                    local width = height * 0.55
                    local boxX = rootPos.X - width / 2
                    local boxY = headPos.Y - 4
                    
                    box.Size = Vector2.new(width, height)
                    box.Position = Vector2.new(boxX, boxY)
                    box.Visible = true
                    
                    nameL.Text = player.Name
                    nameL.Position = Vector2.new(rootPos.X, boxY - 14)
                    nameL.Visible = true
                    
                    local hpPercent = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                    hpBg.Size = Vector2.new(4, height - 4)
                    hpBg.Position = Vector2.new(boxX - 8, boxY + 2)
                    hpBg.Visible = true
                    
                    hpFl.Color = Color3.fromRGB(255 * (1 - hpPercent), 255 * hpPercent, 80)
                    hpFl.Size = Vector2.new(2, (height - 6) * hpPercent)
                    hpFl.Position = Vector2.new(boxX - 7, boxY + 3 + (height - 6) * (1 - hpPercent))
                    hpFl.Visible = true
                    
                    dL.Text = math.floor(dist) .. "m"
                    dL.Position = Vector2.new(rootPos.X, boxY + height + 2)
                    dL.Visible = true
                else
                    box.Visible = false
                    nameL.Visible = false
                    hpBg.Visible = false
                    hpFl.Visible = false
                    dL.Visible = false
                end
            end
        end
    end
end)

-- ==================== CLEANUP ====================
Library:OnUnload(function()
    FovCircle:Remove()
    for _, drawings in pairs(espCache) do
        for _, o in pairs(drawings) do pcall(function() o:Remove() end) end
    end
    if noclipActive then setNoclip(false) end
    if staminaConnection then staminaConnection:Disconnect() end
end)

-- ==================== NOTIFIKASI ====================
Library:Notify("Xylus | Inf Stamina + Silent Aim + Noclip + ESP Loaded!", 4)
print("✅ Xylus Loaded - 4 fitur siap pakai (LinoriaLib)")
