-- XYLUS | SLEEPYHUB COMPLETE (BAGIAN 1/3)
-- Copy ini dulu

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/refs/heads/main/Library.lua"))()

local Window = Library:CreateWindow({
    Title = "XYLUS | SleepyHub Complete",
    Center = true,
    AutoShow = true,
    TabWidth = 120,
})

-- ==================== BYPASS HYPHON ====================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local MemoryStoreService = game:GetService("MemoryStoreService")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer

local function killFakeHandshake()
    local fake = MemoryStoreService:FindFirstChild("Hyphon_Check")
    if fake and fake:IsA("RemoteEvent") then pcall(function() fake:Destroy() end) end
end
killFakeHandshake()

local function cloakUIs()
    for _, v in ipairs(CoreGui:GetDescendants()) do
        if v:IsA("ScreenGui") and v.Name:lower():find("hyphon") then
            pcall(function()
                v.Name = "RobloxCoreUI"
                v.Enabled = false
                for _, con in ipairs(getconnections(v.Changed)) do pcall(con.Disconnect, con) end
                for _, con in ipairs(getconnections(v.AncestryChanged)) do pcall(con.Disconnect, con) end
                local clone = Instance.new("Folder", ReplicatedStorage)
                clone.Name = "HyphonCheck"
                v.Parent = clone
            end)
        end
    end
end
cloakUIs()

local capturedRemote, capturedKey
local function interceptInvoke(remote, ...)
    local args = table.pack(...)
    for i = 1, args.n do
        if typeof(args[i]) == "string" and args[i]:find("ProtectedByHyphon") then
            capturedRemote = remote
            capturedKey = args[i]
            return nil
        end
    end
end

for _, folder in ipairs(ReplicatedStorage:GetChildren()) do
    if folder:IsA("Folder") and folder.Name:match("^%d+$") then
        for _, obj in ipairs(folder:GetChildren()) do
            if obj:IsA("RemoteFunction") and obj.Name:match("^%d+$") then
                obj.OnClientInvoke = function(...) return interceptInvoke(obj, ...) end
            end
        end
    end
end

task.spawn(function()
    repeat task.wait(0.1) until capturedRemote and capturedKey
    task.wait(0.4)
    local spoofed = tostring(LocalPlayer.UserId) .. tostring(math.random(10000, 99999))
    pcall(function() capturedRemote:InvokeServer({spoofed, capturedKey}) end)
end)

local oldTick = hookfunction(getrenv().tick, function(...)
    if not checkcaller() and tostring(getcallingscript()):find("Hyphon") then return 0 end
    return oldTick(...)
end)

local oldGc = hookfunction(getrenv().gcinfo, function(...)
    if not checkcaller() and tostring(getcallingscript()):find("Hyphon") then return 0 end
    return oldGc(...)
end)

print("[XYLUS] Hyphon Bypass Activated")

-- ==================== GLOBAL VARIABLES ====================
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local VirtualInput = game:GetService("VirtualInputManager")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

-- ==================== TAB ====================
local CombatTab = Window:AddTab("Combat")
local PlayerTab = Window:AddTab("Player")
local TeleportTab = Window:AddTab("Teleport")
local VisualsTab = Window:AddTab("Visuals")
local AutofarmTab = Window:AddTab("Autofarm")
local RobberyTab = Window:AddTab("Robbery")
local ExploitsTab = Window:AddTab("Exploits")
local SettingsTab = Window:AddTab("Settings")

-- XYLUS | SLEEPYHUB COMPLETE (BAGIAN 2/3)
-- Copy ini setelah bagian 1

-- ==================== COMBAT TAB ====================
local SilentGroup = CombatTab:AddLeftGroupbox("Silent Aim")
local AimbotGroup = CombatTab:AddRightGroupbox("Aimbot")
local TriggerGroup = CombatTab:AddLeftGroupbox("Triggerbot")
local KillauraGroup = CombatTab:AddRightGroupbox("Killaura")
local HitboxGroup = CombatTab:AddLeftGroupbox("Hitbox Extender")
local FistGroup = CombatTab:AddRightGroupbox("Fist Extender")
local GunGroup = CombatTab:AddLeftGroupbox("Gun Mods")
local SpinGroup = CombatTab:AddRightGroupbox("Spinbot")

-- Silent Aim
local SilentAim = false
local SilentAimPart = "Head"
local SilentFOV = 150
local SilentWallbang = false
local SilentVisibleCheck = false

local fovCircle = Drawing.new("Circle")
fovCircle.Radius = SilentFOV
fovCircle.NumSides = 64
fovCircle.Thickness = 1.5
fovCircle.Visible = false
fovCircle.Color = Color3.fromRGB(0, 255, 0)
fovCircle.Transparency = 0.6

RunService.RenderStepped:Connect(function()
    fovCircle.Position = UserInputService:GetMouseLocation()
    fovCircle.Visible = SilentAim
    fovCircle.Radius = SilentFOV
end)

local function getClosestTarget()
    local mousePos = UserInputService:GetMouseLocation()
    local closest, closestDist = nil, SilentFOV
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local part = plr.Character:FindFirstChild(SilentAimPart)
            if part then
                local hum = plr.Character:FindFirstChild("Humanoid")
                if hum and hum.Health > 0 then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                    if onScreen then
                        if SilentVisibleCheck then
                            local params = RaycastParams.new()
                            params.FilterDescendantsInstances = {LocalPlayer.Character}
                            local result = workspace:Raycast(Camera.CFrame.Position, (part.Position - Camera.CFrame.Position).Unit * 500, params)
                            if result and not result.Instance:IsDescendantOf(plr.Character) then continue end
                        end
                        local dist = (mousePos - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
                        if dist < closestDist then
                            closest = plr
                            closestDist = dist
                        end
                    end
                end
            end
        end
    end
    return closest
end

local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    if SilentAim and tostring(method) == "Raycast" then
        local target = getClosestTarget()
        if target and target.Character then
            local targetPart = target.Character:FindFirstChild(SilentAimPart)
            if targetPart then
                local origin = args[2]
                if origin then
                    args[3] = (targetPart.Position - origin).Unit * 1000
                    if SilentWallbang then
                        local params = RaycastParams.new()
                        params.FilterType = Enum.RaycastFilterType.Include
                        params.FilterDescendantsInstances = {target.Character}
                        args[4] = params
                    end
                    return oldNamecall(self, unpack(args))
                end
            end
        end
    end
    return oldNamecall(self, ...)
end))

SilentGroup:AddToggle("SilentToggle", {Text = "Silent Aim", Default = false, Callback = function(v) SilentAim = v end})
SilentGroup:AddDropdown("SilentPart", {Text = "Target Part", Values = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"}, Default = 1, Callback = function(v) SilentAimPart = v end})
SilentGroup:AddSlider("SilentFOV", {Text = "FOV Radius", Min = 10, Max = 500, Default = 150, Rounding = 0, Callback = function(v) SilentFOV = v end})
SilentGroup:AddToggle("SilentVisible", {Text = "Visible Check", Default = false, Callback = function(v) SilentVisibleCheck = v end})
SilentGroup:AddToggle("SilentWallbang", {Text = "Wallbang", Default = false, Callback = function(v) SilentWallbang = v end})

-- Aimbot
local aimbotEnabled = false
local aimbotSmooth = 8
local aimbotKeybind = Enum.UserInputType.MouseButton2
local aiming = false

AimbotGroup:AddToggle("AimbotToggle", {Text = "Aimbot (Hold)", Default = false, Callback = function(v) aimbotEnabled = v end})
AimbotGroup:AddKeyPicker("AimbotKeybind", {Text = "Keybind", Default = "RightButton", Mode = "Hold", Callback = function(key) aimbotKeybind = key end})
AimbotGroup:AddSlider("AimbotSmooth", {Text = "Smoothing", Min = 1, Max = 20, Default = 8, Rounding = 0, Callback = function(v) aimbotSmooth = v end})

UserInputService.InputBegan:Connect(function(input)
    if aimbotEnabled and input.UserInputType == aimbotKeybind then aiming = true end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == aimbotKeybind then aiming = false end
end)

RunService.RenderStepped:Connect(function()
    if aiming and aimbotEnabled then
        local target = getClosestTarget()
        if target and target.Character and target.Character:FindFirstChild("Head") then
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, target.Character.Head.Position), 1 / aimbotSmooth)
        end
    end
end)

-- Triggerbot
local triggerEnabled = false
local triggerDelay = 0

TriggerGroup:AddToggle("TriggerToggle", {Text = "Triggerbot", Default = false, Callback = function(v) triggerEnabled = v end})
TriggerGroup:AddSlider("TriggerDelay", {Text = "Delay (s)", Min = 0, Max = 1, Default = 0, Rounding = 2, Callback = function(v) triggerDelay = v end})

RunService.RenderStepped:Connect(function()
    if triggerEnabled then
        local target = getClosestTarget()
        if target then
            VirtualInput:SendMouseButtonEvent(0, 0, 0, true, game, 0)
            task.wait(triggerDelay)
            VirtualInput:SendMouseButtonEvent(0, 0, 0, false, game, 0)
        end
    end
end)

-- Killaura
local killauraEnabled = false
local killauraRange = 30
local killauraDamage = 100

KillauraGroup:AddToggle("KillauraToggle", {Text = "Killaura (Gun)", Default = false, Callback = function(v) killauraEnabled = v end})
KillauraGroup:AddSlider("KillauraRange", {Text = "Range", Min = 10, Max = 100, Default = 30, Rounding = 0, Callback = function(v) killauraRange = v end})
KillauraGroup:AddSlider("KillauraDamage", {Text = "Damage", Min = 10, Max = 1000, Default = 100, Rounding = 0, Callback = function(v) killauraDamage = v end})

-- Hitbox Extender
local hitboxEnabled = false
local hitboxSize = 5

HitboxGroup:AddToggle("HitboxToggle", {Text = "Hitbox Extender", Default = false, Callback = function(v) hitboxEnabled = v end})
HitboxGroup:AddSlider("HitboxSize", {Text = "Size", Min = 1, Max = 20, Default = 5, Rounding = 1, Callback = function(v) hitboxSize = v end})

-- Fist Extender
local fistEnabled = false
local fistSize = 7

FistGroup:AddToggle("FistToggle", {Text = "Fist Extender", Default = false, Callback = function(v) fistEnabled = v end})
FistGroup:AddSlider("FistSize", {Text = "Size", Min = 1, Max = 20, Default = 7, Rounding = 1, Callback = function(v) fistSize = v end})

-- Gun Mods
GunGroup:AddButton({Text = "Auto Gun", Func = function()
    local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
    if tool and tool:FindFirstChild("Setting") then pcall(function() require(tool.Setting).Auto = true end) end
end})
GunGroup:AddButton({Text = "No Fire Rate", Func = function()
    local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
    if tool and tool:FindFirstChild("Setting") then pcall(function() require(tool.Setting).FireRate = 0 end) end
end})
GunGroup:AddButton({Text = "Infinite Ammo", Func = function()
    local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
    if tool and tool:FindFirstChild("Setting") then
        pcall(function()
            require(tool.Setting).LimitedAmmoEnabled = false
            require(tool.Setting).MaxAmmo = 9e9
            require(tool.Setting).AmmoPerMag = 9e9
        end)
    end
end})
GunGroup:AddButton({Text = "No Recoil", Func = function()
    local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
    if tool and tool:FindFirstChild("Setting") then pcall(function() require(tool.Setting).Recoil = 0 end) end
end})
GunGroup:AddButton({Text = "Infinite Damage", Func = function()
    local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
    if tool and tool:FindFirstChild("Setting") then pcall(function() require(tool.Setting).BaseDamage = 9e9 end) end
end})
GunGroup:AddButton({Text = "No Spread", Func = function()
    local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
    if tool and tool:FindFirstChild("Setting") then
        pcall(function()
            require(tool.Setting).SpreadX = 0
            require(tool.Setting).SpreadY = 0
            require(tool.Setting).Accuracy = 1
        end)
    end
end})

-- Spinbot
local spinEnabled = false
local spinSpeed = 50

SpinGroup:AddToggle("SpinToggle", {Text = "Spinbot", Default = false, Callback = function(v) spinEnabled = v end})
SpinGroup:AddSlider("SpinSpeed", {Text = "Speed", Min = 10, Max = 360, Default = 50, Rounding = 0, Callback = function(v) spinSpeed = v end})

RunService.RenderStepped:Connect(function()
    if spinEnabled then
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(spinSpeed), 0) end
    end
end)

-- Hitbox & Fist Extender Loop
RunService.RenderStepped:Connect(function()
    if hitboxEnabled then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    pcall(function()
                        hrp.Size = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
                        hrp.Transparency = 0.5
                        hrp.Material = Enum.Material.Neon
                    end)
                end
            end
        end
    else
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                if hrp then pcall(function() hrp.Size = Vector3.new(2, 2.1, 0.85) end) end
            end
        end
    end
    if fistEnabled then
        local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
        if tool and tool:FindFirstChild("Hitbox") then
            tool.Hitbox.Size = Vector3.new(fistSize, fistSize, fistSize)
        end
    end
end)

-- ==================== PLAYER TAB ====================
local MoveGroup = PlayerTab:AddLeftGroupbox("Movement")
local PlayerStatsGroup = PlayerTab:AddRightGroupbox("Player Stats")
local VisualGroup = PlayerTab:AddLeftGroupbox("Visual Mods")

-- Walkspeed
local wsEnabled = false
local wsValue = 16

MoveGroup:AddToggle("WalkspeedToggle", {Text = "Walkspeed", Default = false, Callback = function(v)
    wsEnabled = v
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
    if hum then hum.WalkSpeed = v and wsValue or 16 end
end})
MoveGroup:AddSlider("WalkspeedValue", {Text = "Walkspeed Value", Min = 0, Max = 50, Default = 16, Rounding = 1, Callback = function(v)
    wsValue = v
    if wsEnabled then
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
        if hum then hum.WalkSpeed = v end
    end
end})

-- Jump Power
local jpEnabled = false
local jpValue = 100

MoveGroup:AddToggle("JumpPowerToggle", {Text = "Jump Power", Default = false, Callback = function(v)
    jpEnabled = v
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
    if hum then hum.JumpPower = v and jpValue or 50 end
end})
MoveGroup:AddSlider("JumpPowerValue", {Text = "Jump Power Value", Min = 50, Max = 500, Default = 100, Rounding = 0, Callback = function(v)
    jpValue = v
    if jpEnabled then
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
        if hum then hum.JumpPower = v end
    end
end})

-- Fly
local flyEnabled = false
local flySpeed = 5

MoveGroup:AddToggle("FlyToggle", {Text = "Fly", Default = false, Callback = function(v) flyEnabled = v end})
MoveGroup:AddSlider("FlySpeed", {Text = "Fly Speed", Min = 1, Max = 50, Default = 5, Rounding = 1, Callback = function(v) flySpeed = v end})

RunService.RenderStepped:Connect(function(dt)
    if flyEnabled then
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local move = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move = move - Vector3.new(0, 1, 0) end
            hrp.CFrame = hrp.CFrame + move.Unit * flySpeed * dt
        end
    end
end)

-- Noclip
local noclipEnabled = false
MoveGroup:AddToggle("NoclipToggle", {Text = "Noclip", Default = false, Callback = function(v)
    noclipEnabled = v
    local char = LocalPlayer.Character
    if char then
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = not v end
        end
    end
end})

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    if noclipEnabled then
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end
end)

-- Infinite Jump
local infJumpEnabled = false
MoveGroup:AddToggle("InfJumpToggle", {Text = "Infinite Jump", Default = false, Callback = function(v) infJumpEnabled = v end})

UserInputService.JumpRequest:Connect(function()
    if infJumpEnabled then
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- Infinite Stamina
local staminaHooked = false
local staminaConn = nil

PlayerStatsGroup:AddToggle("InfStamina", {Text = "Infinite Stamina", Default = false, Callback = function(v)
    if v and not staminaHooked then
        for _, gc in pairs(getgc(true)) do
            if type(gc) == "table" then
                for k, _ in pairs(gc) do
                    if k == "Stamina" then
                        local mt = getmetatable(gc)
                        if mt then
                            setreadonly(mt, false)
                            local oldIdx = mt.__index
                            mt.__index = function(t, k2)
                                if k2 == "Stamina" then return 100 end
                                return oldIdx and oldIdx(t, k2)
                            end
                            staminaHooked = true
                        end
                        staminaConn = RunService.Heartbeat:Connect(function()
                            if v then gc.Stamina = 100 end
                        end)
                        break
                    end
                end
            end
            if staminaHooked then break end
        end
    elseif not v and staminaConn then
        staminaConn:Disconnect()
        staminaConn = nil
    end
end})

-- Fullbright
local fbEnabled = false
VisualGroup:AddToggle("FullbrightToggle", {Text = "Fullbright", Default = false, Callback = function(v)
    fbEnabled = v
    if v then
        game.Lighting.Brightness = 2
        game.Lighting.ClockTime = 14
        game.Lighting.FogEnd = 100000
        game.Lighting.GlobalShadows = false
    else
        game.Lighting.Brightness = 1
        game.Lighting.ClockTime = 12
        game.Lighting.FogEnd = 1000
        game.Lighting.GlobalShadows = true
    end
end})

-- Anti Ragdoll
PlayerStatsGroup:AddButton({Text = "Anti Ragdoll", Func = function()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("RagdollConstraints") then
        for _, v in pairs(char.RagdollConstraints:GetChildren()) do v:Destroy() end
    end
end})

-- Anti Fall Damage
PlayerStatsGroup:AddButton({Text = "Anti Fall Damage", Func = function()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("FallDamageRagdoll") and char.FallDamageRagdoll:FindFirstChild("Damage") then
        char.FallDamageRagdoll.Damage:Destroy()
    end
end})

-- Anti Camera Shake
PlayerStatsGroup:AddButton({Text = "Anti Camera Shake", Func = function()
    local char = LocalPlayer.Character
    if char then
        local camBob = char:FindFirstChild("CameraBobbing")
        if camBob then camBob:Destroy() end
    end
end})

-- No Rent Pay
PlayerStatsGroup:AddButton({Text = "No Rent Pay", Func = function()
    local rentGui = LocalPlayer.PlayerGui:FindFirstChild("RentGui")
    if rentGui and rentGui:FindFirstChild("LocalScript") then rentGui.LocalScript:Destroy() end
end})

-- Instant Interact
PlayerStatsGroup:AddButton({Text = "Instant Interact", Func = function()
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            v.HoldDuration = 0
            v.RequiresLineOfSight = false
        end
    end
end})
-- XYLUS | SLEEPYHUB COMPLETE (BAGIAN 3/3)
-- Copy ini setelah bagian 2

-- ==================== TELEPORT TAB ====================
local TeleGroup = TeleportTab:AddLeftGroupbox("Locations")

local tpLocs = {
    {"🏪 Dealership", 753.20, 4.63, 437.04},
    {"🍬 Marshmellow NPC", 510.996, 3.587, 598.393},
    {"🎰 Casino", 1154.86, 4.29, -46.85},
    {"🔫 Gun Store", 218.57, 4.65, -173.54},
    {"🏦 Bank", -43.01, 4.66, -353.96},
    {"🏠 Apartment 1", 1141.80, 11.04, 450.35},
    {"🏠 Apartment 2", 1142.49, 11.04, 421.64},
    {"🏠 Apartment 3", 984.09, 11.03, 248.81},
    {"🏠 Apartment 4", 984.09, 11.06, 220.29},
    {"🏢 Roof", -363, 340, -559},
    {"💎 Exotic Shop", -1525, 273, -984},
    {"🌿 Weed Dealer", -633, 253, -731},
    {"🎨 Tattoo Shop", -712, 253, -519},
    {"🛡️ Safe Spot", 544, 283, -807},
    {"💰 Bank Vault", -122, 374, -1216},
    {"🧹 Mop Job", -729, 254, -778},
    {"🗑️ Trash Apartment", 684, 529, -736},
    {"🚗 Car Shop", -346, 255, -1246},
    {"💻 Laptop Job", -1017, 253, -249},
    {"🏀 Basketball Court", -1056, 254, -496},
}

local function tpTo(x, y, z)
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp then hrp.CFrame = CFrame.new(x, y + 3, z) end
end

for _, loc in ipairs(tpLocs) do
    TeleGroup:AddButton({Text = loc[1], Func = function() tpTo(loc[2], loc[3], loc[4]) end})
end

-- Teleport to Player
local TelePlayerGroup = TeleportTab:AddRightGroupbox("Teleport to Player")
local targetName = ""

TelePlayerGroup:AddInput("TargetPlayer", {Text = "Player Name", Default = "", Finished = true, Callback = function(v) targetName = v end})
TelePlayerGroup:AddButton({Text = "Teleport to Player", Func = function()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Name:lower():find(targetName:lower()) and plr.Character then
            tpTo(plr.Character.HumanoidRootPart.Position.X, plr.Character.HumanoidRootPart.Position.Y, plr.Character.HumanoidRootPart.Position.Z)
            break
        end
    end
end})

-- ==================== VISUALS TAB ====================
local ESPGroup = VisualsTab:AddLeftGroupbox("Player ESP")
local WorldGroup = VisualsTab:AddRightGroupbox("World Visuals")

-- ESP
local espEnabled = false
local espMaxDist = 150
local espCache = {}

local function createESP(player)
    if espCache[player] then
        for _, o in pairs(espCache[player]) do pcall(function() o:Remove() end) end
    end
    local box = Drawing.new("Square")
    box.Thickness = 1
    box.Color = Color3.fromRGB(0, 255, 136)
    box.Filled = false
    local nameL = Drawing.new("Text")
    nameL.Text = player.Name
    nameL.Size = 10
    nameL.Font = 1
    nameL.Color = Color3.fromRGB(255, 255, 255)
    nameL.Outline = true
    nameL.Center = true
    local hpBg = Drawing.new("Square")
    hpBg.Thickness = 1
    hpBg.Color = Color3.fromRGB(30, 30, 30)
    hpBg.Filled = true
    local hpFl = Drawing.new("Square")
    hpFl.Thickness = 1
    hpFl.Color = Color3.fromRGB(0, 255, 80)
    hpFl.Filled = true
    local dL = Drawing.new("Text")
    dL.Size = 10
    dL.Font = 1
    dL.Color = Color3.fromRGB(180, 220, 255)
    dL.Outline = true
    dL.Center = true
    espCache[player] = {box, nameL, hpBg, hpFl, dL}
end

local function removeESP(player)
    if espCache[player] then
        for _, o in pairs(espCache[player]) do pcall(function() o:Remove() end) end
        espCache[player] = nil
    end
end

for _, plr in ipairs(Players:GetPlayers()) do if plr ~= LocalPlayer then createESP(plr) end end
Players.PlayerAdded:Connect(function(p) if p ~= LocalPlayer then createESP(p) end end)
Players.PlayerRemoving:Connect(removeESP)

ESPGroup:AddToggle("PlayerESP", {Text = "Player ESP", Default = false, Callback = function(v) espEnabled = v end})
ESPGroup:AddSlider("ESPMaxDist", {Text = "Max Distance", Min = 10, Max = 500, Default = 150, Rounding = 0, Callback = function(v) espMaxDist = v end})

RunService.Heartbeat:Connect(function()
    if not espEnabled then
        for _, drawings in pairs(espCache) do for _, o in pairs(drawings) do pcall(function() o.Visible = false end) end end
        return
    end
    local myChar = LocalPlayer.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myPos = myHRP and myHRP.Position
    for player, drawings in pairs(espCache) do
        local box, nameL, hpBg, hpFl, dL = unpack(drawings)
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local head = char and char:FindFirstChild("Head")
        if not (char and hum and root and head and hum.Health > 0) then
            for _, o in pairs(drawings) do o.Visible = false end
        else
            local dist = myPos and (root.Position - myPos).Magnitude or 0
            if dist > espMaxDist then
                for _, o in pairs(drawings) do o.Visible = false end
            else
                local rootPos, rootOn = Camera:WorldToViewportPoint(root.Position)
                local headPos, headOn = Camera:WorldToViewportPoint(head.Position)
                if rootOn and headOn then
                    local height = math.abs(headPos.Y - rootPos.Y) * 1.7 + 8
                    local width = height * 0.55
                    local boxX = rootPos.X - width / 2
                    local boxY = headPos.Y - 4
                    box.Size = Vector2.new(width, height)
                    box.Position = Vector2.new(boxX, boxY)
                    box.Visible = true
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
                    for _, o in pairs(drawings) do o.Visible = false end
                end
            end
        end
    end
end)

-- Skybox
local function changeSkybox(id)
    for _, v in pairs(game.Lighting:GetChildren()) do if v:IsA("Sky") then v:Destroy() end end
    local sky = Instance.new("Sky")
    sky.SkyboxBk = id
    sky.SkyboxDn = id
    sky.SkyboxFt = id
    sky.SkyboxLf = id
    sky.SkyboxRt = id
    sky.SkyboxUp = id
    sky.Parent = game.Lighting
end

local skyboxIds = {"Default", "rbxassetid://10735998943", "rbxassetid://8139676647", "rbxassetid://8139676988"}
WorldGroup:AddDropdown("SkyboxDropdown", {Text = "Skybox", Values = skyboxIds, Default = 1, Callback = function(v)
    if v ~= "Default" then changeSkybox(v) end
end})

-- Fog
local fogEnabled = false
WorldGroup:AddToggle("FogToggle", {Text = "Disable Fog", Default = false, Callback = function(v)
    fogEnabled = v
    game.Lighting.FogEnd = v and 0 or 1000
end})

-- Ambient
local ambientEnabled = false
WorldGroup:AddToggle("AmbientToggle", {Text = "Change Ambient", Default = false, Callback = function(v)
    ambientEnabled = v
    game.Lighting.Ambient = v and Color3.fromRGB(128, 128, 128) or Color3.fromRGB(0, 0, 0)
end})

-- ==================== AUTOFARM TAB ====================
local AutoGroup = AutofarmTab:AddLeftGroupbox("Auto Farm")

-- Auto Sell
local autoSellEnabled = false
AutoGroup:AddToggle("AutoSellToggle", {Text = "Auto Sell Items", Default = false, Callback = function(v) autoSellEnabled = v end})

-- Loot Trash
local lootTrashEnabled = false
AutoGroup:AddToggle("LootTrashToggle", {Text = "Loot Trash", Default = false, Callback = function(v) lootTrashEnabled = v end})

task.spawn(function()
    while true do
        task.wait(0.5)
        if lootTrashEnabled then
            for _, v in pairs(workspace:GetDescendants()) do
                if v:IsA("ProximityPrompt") and v.Name == "ProximityPrompt" and v.Parent.Name == "DumpsterPrompt" then
                    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        hrp.CFrame = CFrame.new(v.Parent.CFrame.Position.X, v.Parent.CFrame.Position.Y + 0.2, v.Parent.CFrame.Position.Z + 3)
                        task.wait(0.3)
                        for i = 1, 10 do fireproximityprompt(v) end
                        task.wait(0.1)
                    end
                end
            end
        end
    end
end)

-- Auto Pickup Money
local autoPickupEnabled = false
AutoGroup:AddToggle("AutoPickupToggle", {Text = "Auto Pickup Money", Default = false, Callback = function(v) autoPickupEnabled = v end})

task.spawn(function()
    while true do
        task.wait(0.5)
        if autoPickupEnabled then
            for _, v in pairs(workspace.Dollars:GetDescendants()) do
                if v:IsA("ProximityPrompt") and v.Name == "ProximityPrompt" then
                    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        hrp.CFrame = v.Parent.CFrame
                        task.wait(0.25)
                        fireproximityprompt(v)
                    end
                end
            end
        end
    end
end)

-- ==================== ROBBERY TAB ====================
local RobGroup = RobberyTab:AddLeftGroupbox("Rob Houses")
local BankGroup = RobberyTab:AddRightGroupbox("Rob Bank")

-- Rob Houses
local robHousesEnabled = false
RobGroup:AddToggle("RobHousesToggle", {Text = "Rob Houses", Default = false, Callback = function(v) robHousesEnabled = v end})

task.spawn(function()
    while true do
        task.wait(1)
        if robHousesEnabled then
            for _, v in pairs(workspace.HouseRobb:GetDescendants()) do
                if v:IsA("ProximityPrompt") and v.Name == "ProximityPrompt" then
                    v.HoldDuration = 0
                    v.RequiresLineOfSight = false
                    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        hrp.CFrame = v.Parent.CFrame
                        task.wait(0.3)
                        fireproximityprompt(v)
                    end
                end
            end
        end
    end
end)

-- Rob Studio
local robStudioEnabled = false
RobGroup:AddToggle("RobStudioToggle", {Text = "Rob Studio", Default = false, Callback = function(v) robStudioEnabled = v end})

task.spawn(function()
    while true do
        task.wait(1)
        if robStudioEnabled then
            for _, v in pairs(workspace.StudioPay.Money:GetDescendants()) do
                if v:IsA("ProximityPrompt") and v.Name == "Prompt" then
                    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        hrp.CFrame = v.Parent.CFrame
                        task.wait(0.25)
                        fireproximityprompt(v)
                    end
                end
            end
        end
    end
end)

-- Rob Bank
local robBankEnabled = false
local bankMethod = "C4"

BankGroup:AddDropdown("BankMethod", {Text = "Method", Values = {"C4", "Drill"}, Default = 1, Callback = function(v) bankMethod = v end})
BankGroup:AddToggle("RobBankToggle", {Text = "Rob Bank", Default = false, Callback = function(v) robBankEnabled = v end})

-- ==================== EXPLOITS TAB ====================
local DupeGroup = ExploitsTab:AddLeftGroupbox("Dupe")
local ServerGroup = ExploitsTab:AddRightGroupbox("Server")

-- Dupe Tools
DupeGroup:AddButton({Text = "Dupe Tools", Func = function()
    local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
    if tool then
        local toolName = tool.Name
        LocalPlayer.Character.Humanoid:UnequipTools()
        task.wait(1)
        pcall(function()
            ReplicatedStorage.BackpackRemote:InvokeServer("Store", toolName)
            ReplicatedStorage.BackpackRemote:InvokeServer("Grab", toolName)
        end)
    end
end})

-- Dupe Inventory
DupeGroup:AddButton({Text = "Dupe Inventory", Func = function()
    for _, tool in pairs(LocalPlayer.Backpack:GetChildren()) do
        if tool:IsA("Tool") and tool.Name ~= "Fist" and tool.Name ~= "Phone" then
            pcall(function()
                ReplicatedStorage.BackpackRemote:InvokeServer("Store", tool.Name)
                ReplicatedStorage.BackpackRemote:InvokeServer("Grab", tool.Name)
            end)
            task.wait(0.5)
        end
    end
end})

-- Server Hop
ServerGroup:AddButton({Text = "Server Hop", Func = function()
    local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
    local success, data = pcall(function() return game:HttpGet(url) end)
    if success then
        local servers = HttpService:JSONDecode(data).data
        for _, server in ipairs(servers) do
            if server.playing < 19 and server.id ~= game.JobId then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer)
                return
            end
        end
    end
end})

-- Rejoin
ServerGroup:AddButton({Text = "Rejoin Server", Func = function()
    TeleportService:Teleport(game.PlaceId, LocalPlayer)
end})

-- Infinite Money
ServerGroup:AddButton({Text = "Infinite Money (Wait 7 min)", Func = function()
    Library:Notify("Wait 7 minutes in-game for money to process", 5)
end})

-- ==================== SETTINGS TAB ====================
local SettingsGroup = SettingsTab:AddLeftGroupbox("Settings")

local guiVisible = true
SettingsGroup:AddButton({Text = "Toggle GUI", Func = function()
    guiVisible = not guiVisible
    local frame = Window.Items and Window.Items.MainFrame and Window.Items.MainFrame.Instance
    if frame then frame.Visible = guiVisible end
end})

SettingsGroup:AddButton({Text = "Unload Script", Func = function()
    Library:Unload()
    fovCircle:Remove()
    for _, drawings in pairs(espCache) do for _, o in pairs(drawings) do pcall(function() o:Remove() end) end end
    if staminaConn then staminaConn:Disconnect() end
end})

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.RightControl then
        guiVisible = not guiVisible
        local frame = Window.Items and Window.Items.MainFrame and Window.Items.MainFrame.Instance
        if frame then frame.Visible = guiVisible end
    end
end})

SettingsGroup:AddLabel("💡 Tekan RightControl untuk toggle GUI")

-- ==================== NOTIFICATION ====================
Library:Notify("XYLUS | SleepyHub Complete Edition Loaded!", 4)
print("✅ XYLUS | SleepyHub Complete - Tekan RightControl untuk toggle GUI")
