if getgenv().valary_loaded then
    return
end

getgenv().valary_loaded = true


-- ================================================================
-- HYPHON EMULATOR BYPASS (FIXED)
-- ================================================================

if LPH_OBFUSCATED == nil then
    local assert = assert
    local type = type
    local setfenv = setfenv
    
    LPH_ENCNUM = function(toEncrypt, ...)
        assert(type(toEncrypt) == "number" and #{...} == 0, "LPH_ENCNUM only accepts a single constant double or integer as an argument.")
        return toEncrypt
    end
    LPH_NUMENC = LPH_ENCNUM
    
    LPH_ENCSTR = function(toEncrypt, ...)
        assert(type(toEncrypt) == "string" and #{...} == 0, "LPH_ENCSTR only accepts a single constant string as an argument.")
        return toEncrypt
    end
    LPH_STRENC = LPH_ENCSTR
    
    LPH_ENCFUNC = function(toEncrypt, encKey, decKey, ...)
        assert(type(toEncrypt) == "function" and type(encKey) == "string" and #{...} == 0, "LPH_ENCFUNC accepts a constant function, constant string, and string variable as arguments.")
        return toEncrypt
    end
    LPH_FUNCENC = LPH_ENCFUNC
    
    LPH_JIT = function(f, ...)
        assert(type(f) == "function" and #{...} == 0, "LPH_JIT only accepts a single constant function as an argument.")
        return f
    end
    LPH_JIT_MAX = LPH_JIT
    
    LPH_NO_VIRTUALIZE = function(f, ...)
        assert(type(f) == "function" and #{...} == 0, "LPH_NO_VIRTUALIZE only accepts a single constant function as an argument.")
        return f
    end
    
    LRM_INIT_SCRIPT = function(f)
        return f()
    end
    
    LPH_NO_UPVALUES = function(f, ...)
        assert(type(setfenv) == "function", "LPH_NO_UPVALUES can only be used on Lua versions with getfenv & setfenv")
        assert(type(f) == "function" and #{...} == 0, "LPH_NO_UPVALUES only accepts a single constant function as an argument.")
        local env = getrenv()
        return setfenv(
            LPH_NO_VIRTUALIZE(function(...)
                return f(...)
            end),
            setmetatable(
                {
                    func = f
                },
                {
                    __index = env,
                    __newindex = env
                }
            )
        )
    end
    
    LPH_CRASH = function(...)
        assert(#{...} == 0, "LPH_CRASH does not accept any arguments.")
        game:Shutdown()
        while true do end
    end
    
    LRM_IsUserPremium = false
    LRM_LinkedDiscordID = "1096603799159832636"
    LRM_ScriptName = "valary"
    LRM_TotalExecutions = 0
    LRM_SecondsLeft = math.huge
    LRM_UserNote = "Developer"
end

-- ========== INIT SCRIPT ==========
LRM_INIT_SCRIPT(function()
    task.wait(1)

    if not game:IsLoaded() then
        game.Loaded:Wait()
    end

    local LocalPlayer = game:GetService("Players").LocalPlayer
    
    if not LocalPlayer.Character then 
        LocalPlayer.CharacterAdded:Wait()
    end

    -- Skip IntroUI check untuk rejoiner
    if not getgenv().rejoined_and_farming then
        local introUI = LocalPlayer.PlayerGui:FindFirstChild("IntroUI")
        if introUI then
            repeat task.wait(0.1) until introUI == nil
        end
    else
        task.wait(60)
    end

    -- Hyphon bypass untuk game yang bukan main game
    if game.PlaceId ~= 15124180230 then
        local RunService = game:GetService("RunService")
        local Function = nil

        -- Method 1: Cari berdasarkan nama function (lebih reliable)
        for _, v in ipairs(getgc()) do
            if type(v) == "function" and not iscclosure(v) then
                local info = debug.getinfo(v)
                -- Cari function yang panggil kick atau shutdown
                if info and info.name and (info.name:lower():find("kick") or info.name:lower():find("shutdown")) then
                    Function = v
                    break
                end
            end
        end

        -- Method 2: Kalo ga ketemu, cari berdasarkan upvalue yang mencurigakan
        if not Function then
            for _, v in ipairs(getgc()) do
                if type(v) == "function" and not iscclosure(v) then
                    local upvalues = {debug.getupvalues(v)}
                    for _, uv in ipairs(upvalues) do
                        if type(uv) == "number" and uv ~= uv then -- NaN check
                            Function = v
                            break
                        end
                    end
                end
            end
        end

        -- Method 3: Cari function yang ada di script anti-cheat (berdasarkan source)
        if not Function then
            for _, v in ipairs(getgc()) do
                if type(v) == "function" and not iscclosure(v) then
                    local info = debug.getinfo(v)
                    if info and info.source and info.source:find("AntiCheat") then
                        Function = v
                        break
                    end
                end
            end
        end

        if not Function or type(Function) ~= "function" then
            print("[WARNING] Anti-cheat function not found, bypass skipped")
        else
            -- Set upvalue ke NaN
            pcall(function()
                local upvalues = {debug.getupvalues(Function)}
                for i = 1, #upvalues do
                    if type(upvalues[i]) == "number" then
                        debug.setupvalue(Function, i, 0/0)
                        break
                    end
                end
            end)

            -- Loop untuk menjaga nilai
            task.spawn(function()
                while RunService.Stepped:Wait() do
                    pcall(function()
                        local upvalues = {debug.getupvalues(Function)}
                        for i = 1, #upvalues do
                            if type(upvalues[i]) == "number" then
                                debug.setupvalue(Function, i, 0/0)
                                break
                            end
                        end
                    end)
                end
            end)
        end
    end

    -- Handle rejoiner
    if getgenv().rejoined_and_farming then
        local introUI = LocalPlayer.PlayerGui:FindFirstChild("IntroUI")
        if introUI and introUI.SurfaceGui and introUI.SurfaceGui.Frame and introUI.SurfaceGui.Frame.Play then
            local connections = getconnections(introUI.SurfaceGui.Frame.Play.MouseButton1Click)
            if connections and connections[1] then
                connections[1]:Fire()
            end
        end
        task.wait(10)
    end
end)  -- <-- INI KURUNG TUTUP YANG BENER

-- ========== SETTINGS FILE ==========
if not isfile('ValaryGG_RejoinerSettings.txt') then
    writefile('ValaryGG_RejoinerSettings.txt', '')
end

local LoadingTick = os.clock()
local LocalPlayer = game:GetService("Players").LocalPlayer
local Console_Server = (game.PlaceId == 15124180230)

-- ========== HYPHON EMULATION ==========
do
    local OWpCsbCTXfeDG = filtergc('function', {IgnoreExecutor = true, Name = "OWpCsbCTXfeDG"}, true)

    if not OWpCsbCTXfeDG then
        return
    end

    local source = debug.info(OWpCsbCTXfeDG, "s")

    -- Safe upvalue getter
    local function getUpval(func, idx)
        local ok, v = pcall(debug.getupvalue, func, idx)
        if ok then return v end
        return nil
    end

    -- Safe upvalue dump
    local function safeGetUpvalues(func)
        local ok, result = pcall(debug.getupvalues, func)
        if ok then return result end
        return {}
    end

    -- Find Function_2247
    local Function_2247 = nil
    local idx_Remote = nil

    for _, Value in filtergc("function", {Source = source, IgnoreExecutor = true}) do
        if not iscclosure(Value) then
            local upvals = safeGetUpvalues(Value)
            for i, v in upvals do
                local ok, isInst = pcall(function()
                    return typeof(v) == "Instance" and v:IsA("RemoteFunction")
                end)
                if ok and isInst then
                    Function_2247 = Value
                    idx_Remote = i
                    break
                end
            end
        end
        if Function_2247 then break end
        task.wait()
    end

    if not Function_2247 then
        return
    end

    -- Find V5_Function
    local V5_Function = nil
    local idx_V5Handshake = nil

    for _, Value in filtergc("function", {Source = source, IgnoreExecutor = true}) do
        if not iscclosure(Value) and Value ~= Function_2247 then
            local upvals = safeGetUpvalues(Value)
            for i, v in upvals do
                local ok, isShortStr = pcall(function()
                    return typeof(v) == "string" and #v <= 4 and #v >= 1
                end)
                if ok and isShortStr then
                    V5_Function = Value
                    idx_V5Handshake = i
                    break
                end
            end
        end
        if V5_Function then break end
        task.wait()
    end

    local SecondArgument_Token = nil
    local Last_RemoteFunction_Call = nil
    local Last_Hyphon_Check = nil

    _InvokeServer = nil
    _InvokeServer = hookfunction(Instance.new("RemoteFunction", nil).InvokeServer, newcclosure(function(Self, ...)
        if Self.Name:len() == 3 then
            Last_RemoteFunction_Call = tick()
            SecondArgument_Token = select(1, ...)[2]
        else
            return _InvokeServer(Self, ...)
        end
        return _InvokeServer(Self, ...)
    end))

    _FireServer = nil
    _FireServer = hookfunction(Instance.new("RemoteEvent", nil).FireServer, newcclosure(function(Self, ...)
        if Self and Self.Name == "Hyphon_Check" then
            Last_Hyphon_Check = tick()
        else
            return _FireServer(Self, ...)
        end
        return _FireServer(Self, ...)
    end))

    repeat task.wait() until Last_RemoteFunction_Call ~= nil and Last_Hyphon_Check ~= nil

    -- Scan Function_2247 upvalues
    local idx_FirstToken, idx_SecondToken, idx_SixthKey = nil, nil, nil
    local idx_EleventhToken, idx_CurrentNumber = nil, nil
    local TenthArgument_Table = nil
    local stringCount = 0

    local upvals2247 = safeGetUpvalues(Function_2247)
    for i, v in upvals2247 do
        local t = typeof(v)
        if t == "string" then
            stringCount = stringCount + 1
            if stringCount == 1 then idx_FirstToken = i
            elseif stringCount == 2 then idx_SecondToken = i
            elseif stringCount == 6 then idx_SixthKey = i
            elseif stringCount == 11 then idx_EleventhToken = i
            end
        elseif t == "number" and not idx_CurrentNumber then
            idx_CurrentNumber = i
        elseif t == "userdata" and not TenthArgument_Table then
            local nextVal = getUpval(Function_2247, i + 1)
            if nextVal ~= nil then
                local ok, tbl = pcall(function() return v[nextVal] end)
                if ok and typeof(tbl) == "table" then
                    TenthArgument_Table = tbl
                end
            end
        end
    end

    if not TenthArgument_Table then
        for i, v in upvals2247 do
            if typeof(v) == "table" then
                TenthArgument_Table = v
                break
            end
        end
    end

    local Emulator = setmetatable({
        Encode   = function(s) return s end,
        Decode   = function(s) return s end,

        fake_dec = getfenv(OWpCsbCTXfeDG).fake_dec,

        Tablets = {[1] = nil, [2] = nil, [3] = nil, [4] = nil, [5] = nil, [6] = nil},
        SSL = 192429429429 - game.PlaceVersion / LocalPlayer.UserId + game.PlaceVersion,

        Handshake_V5 = V5_Function and tostring(getUpval(V5_Function, idx_V5Handshake)) or "V5",

        Remote               = getUpval(Function_2247, idx_Remote),
        FirstArgument_Token  = getUpval(Function_2247, idx_FirstToken),
        SecondArgument_Token = getUpval(Function_2247, idx_SecondToken),
        SixthArgument_Key    = getUpval(Function_2247, idx_SixthKey),
        TenthArgument_Table  = TenthArgument_Table,
        Eleventh_Token       = getUpval(Function_2247, idx_EleventhToken),
        Current_Number       = getUpval(Function_2247, idx_CurrentNumber),

        Hyphon_Script = (function()
            for _, Value in pairs(getnilinstances()) do
                if Value:IsA("Script") and Value.Name:len() == 32 then
                    return Value
                end
            end
        end)(),

        Hyphon_Check = (function()
            return cloneref(game:GetService("MemoryStoreService")):FindFirstChild("Hyphon_Check")
        end)(),

        Last_RemoteFunction_Call = Last_RemoteFunction_Call,
        Last_Hyphon_Check = Last_Hyphon_Check,

        Logs = {
            Enabled = false,
            Method = "Print"
        }
    }, {})

    local _Script_ = nil
    for _, Value in pairs(getnilinstances()) do
        if Value:IsA("Script") and Value.Name:len() == 32 then
            _Script_ = Value
        end
    end
    if not _Script_ then return end
    local Bit_32; Bit_32 = hookfunction(bit32.bxor, function(a, b, c, d, e)
        local Caller_Script = getcallingscript()
        if not checkcaller() and Caller_Script == _Script_ then
            return task.wait(9e9)
        end
        return Bit_32(a, b, c, d, e)
    end)

    local Get_Tablets = function()
        local Cache = {}
        for Index, Value in Emulator.Tablets do
            table.insert(Cache, Value)
        end
        return Cache
    end

    for i, v in upvals2247 do
        if i == 24 then Emulator.Tablets[1] = v
        elseif i == 25 then Emulator.Tablets[2] = v
        elseif i == 26 then Emulator.Tablets[3] = v
        elseif i == 27 then Emulator.Tablets[4] = v
        elseif i == 28 then Emulator.Tablets[5] = v
        elseif i == 29 then Emulator.Tablets[6] = v
        end
    end

    task.spawn(function() while task.wait(9) do Emulator.Tablets[1] = tick() end end)
    task.spawn(function() while task.wait(9) do Emulator.Tablets[2] = tick() end end)
    task.spawn(function() while task.wait(10) do Emulator.Tablets[3] = tick() end end)
    task.spawn(function() while task.wait(4) do Emulator.Tablets[4] = tick() end end)

    local v3020 = nil
    for _, Value in filtergc("function", {Upvalues = {LocalPlayer}, Source = source, IgnoreExecutor = true}) do
        if not iscclosure(Value) then
            local ok1, t1 = pcall(debug.getupvalue, Value, 1)
            local ok3, t3 = pcall(debug.getupvalue, Value, 3)
            if ok1 and type(t1) == 'function' and ok3 and type(t3) == 'table' then
                v3020 = Value
                break
            end
        end
        task.wait()
    end

    local _2102 = filtergc("function", {StartLine = 2102, IgnoreExecutor = true}, true)

    if not v3020 then return end
    if not _2102 then return end

    if typeof(Emulator.Remote) ~= "Instance" then
        return
    end

    Emulator.Remote.OnClientInvoke = function(a1, a2, a3, a4, a5, a6)
        Emulator.SecondArgument_Token = a1

        local v297 = math.floor(workspace:GetServerTimeNow() / 8) % 87 / 78
        local v298 = math.floor(math.noise(Emulator.SSL + v297, LocalPlayer.UserId, 0) * 628)

        local fake_dec_result = ""
        pcall(function()
            fake_dec_result = Emulator.fake_dec(a3, tostring(LocalPlayer.UserId))
        end)

        return unpack({
            debug.getupvalue(_2102, 26),
            tostring(math.random(242, 789)),
            fake_dec_result,
            v3020(v298),
            tostring(workspace:GetServerTimeNow()),
            {
                CI = tostring(tick()),
                TL = Get_Tablets(),
                GL = nil,
                LS = 3 + game.PlaceVersion
            }
        })
    end

    task.spawn(function()
        task.wait(tick() - Emulator.Last_Hyphon_Check)
        while true do
            Emulator.Hyphon_Check:FireServer(tick(), Emulator.Handshake_V5 .. "Handshake_V5")
            task.wait(0.1)
            Emulator.Hyphon_Check:FireServer()
            task.wait(9)
        end
    end)

    task.spawn(function()
        while task.wait(35) do
            Emulator.Tablets[5] = tick() - 0.5
            Emulator.Tablets[6] = tick()

            if tostring(Emulator.Current_Number) == "0" then
                Emulator.Current_Number = "1"
            elseif tostring(Emulator.Current_Number) == "1" then
                Emulator.Current_Number = "2"
            elseif tostring(Emulator.Current_Number) == "2" then
                Emulator.Current_Number = "0"
            end

            if not Emulator.SecondArgument_Token or typeof(Emulator.SecondArgument_Token) ~= "string" then
                Emulator.SecondArgument_Token = getUpval(Function_2247, idx_SecondToken)
            end

            Emulator.Remote:InvokeServer({
                Emulator.FirstArgument_Token,
                Emulator.SecondArgument_Token,
                nil,
                tostring(Emulator.Current_Number),
                "Hooks detected: _1__index",
                Emulator.SixthArgument_Key,
                "Hooked",
                tostring(os.time()),
                tick(),
                Emulator.TenthArgument_Table,
                Emulator.Eleventh_Token,
                {
                    CurrentTick = tostring(tick()),
                    Tablets = Get_Tablets()
                },
                {
                    LuaFunction = {
                        true,
                        function() end,
                        string.format("Players.%s.PlayerGui.%s", LocalPlayer.Name, Emulator.Hyphon_Script.Name),
                        2266,
                        "",
                        0,
                        true
                    },
                    SSL = Emulator.SSL,
                    ["Metatable code"] = "nil",
                }
            })
        end
    end)

    getgenv().Hyphon_Emulator = Emulator
end

-- ========== SERVICES ==========
local Services = setmetatable({}, {
    __index = function(self, service)
        return cloneref(game:GetService(service))
    end
})

print("[BYPASS] Loaded successfully")

local fireproximityprompt = fireproximityprompt

if string.find(getexecutorname(), "Bunni") then
    fireproximityprompt = LPH_JIT_MAX(function(Prompt)
        local prompt_settings = {["HoldDuration"] = Prompt.HoldDuration; ["RequiresLineOfSight"] = Prompt.RequiresLineOfSight};

        Prompt.HoldDuration = 0; Prompt.RequiresLineOfSight = false;

        Prompt:InputHoldBegin()

        task.wait(Prompt.HoldDuration)

        Prompt:InputHoldEnd()

        for Index, Value in prompt_settings do
            Prompt[Index] = Value
        end
    end)
end

local Library = {Friendly_Players = {}, Priority_Players = {}, Selected_Player = nil}

local Volcano = string.find(getexecutorname():lower(), "volcano") ~= nil

pcall(function()
    for Index, Value in getconnections(gethui().ChildRemoved) do
        Value:Disable()
    end
end)

local Config = {
    ["Fake_Part"] = nil;
    ["Gun_Handle"] = nil;
    ["Valary_Users"] = {};
    ["Whitelisted_People"] = {};

    ["Spread"] = {Enabled = false; Reduce = 100};
    ["Fire_Rate"] = {Enabled = false; Increase = 2;};
    ["One Tap"] = {Enabled = false;};
    ["Recoil"] = {Enabled = false; Reduce = 100;};
    ["No Jam"] = {Enabled = false};
    ["Instant Reload"] = {Enabled = false;};
    ["Instant Bullet"] = {Enabled = false;};
    ["Force Auto"] = {Enabled = false};
    ["Infinite Ammo"] = {Enabled = false;};
    ["Instant Equip"] = {Enabled = false;};

    ["VehicleModifications"] = {
        ["SpeedEnabled"] = false;
        ["SpeedValue"] = 10/1000;
        ["BreakEnabled"] = false;
        ["BreakValue"] = 50/1000;
        ["InstantStop"] = false;
        ["InstantStopBind"] = Enum.KeyCode.V;
    };

    ["Rejoiner"] = {
        ['Enabled'] = false;
        ['KillAura'] = false;
        ['AutoBuyGun'] = false;
    };

    ["ATM_BALANCE"] = 'N/A';

    ["Tracers"] = {
        ["Enabled"] = false;
        ["Duration"] = 3;
        ["StartColor"] = Color3.fromRGB(255, 85, 0);
        ["EndColor"] = Color3.fromRGB(0, 0, 0);
        ["Rainbow"] = false;
    };

    ["Hit_Sounds"] = {
        ["Neverlose"] = "rbxassetid://8726881116",
        ["Hitmarker"] = "rbxassetid://160432334",
        ["Gamesense"] = "rbxassetid://4817809188",
        ["Rust"] = "rbxassetid://1255040462",
        ["TF2"] = "rbxassetid://2868331684",
        ["Among Us"] = "rbxassetid://5700183626",
        ["Minecraft"] = "rbxassetid://4018616850",
        ["CS:GO"] = "rbxassetid://6937353691",
        ["Call Of Duty"] = "rbxassetid://5952120301",
        ["Pop"] = "rbxassetid://198598793",
        ["Bruh"] = "rbxassetid://4275842574",
        ["Bamboo"] = "rbxassetid://3769434519",
        ["Steve"] = "rbxassetid://4965083997"
    };

    ["Hit_Sounds_Settings"] = {
        ["Enabled"] = false;
        ["Volume"] = 5;
        ["Selected"] = "Neverlose";
        ["HideNormalSounds"] = false;
    };

    ["Hitbox_Expander"] = {
        ["Enabled"] = false;
        ["Multiplier"] = 15;
        ["SafeZoneCheck"] = false;
        ["Color"] = Color3.new(1,1,1);
        ["Transparency"] = 0.5;
        ["Type"] = "Block";
        ["Material"] = "ForceField";
        ["Part"] = "Head";
    };

    ["WorldVisuals"] = {
        ["SaturationEnabled"] = false;
        ["Saturation_Value"] = 1;

        ["StretchEnabled"] = false;
        ["StretchValue"] = 0.7;

        ["FogColorEnabled"] = false;
        ["FogColor"] = Color3.new(1,1,1);

        ["AmbientEnabled"] = false;
        ["AmbientColor"] = Color3.new(1,1,1);

        ["FieldOfViewEnabled"] = false;
        ["FieldOfViewValue"] = 70;

        ["Fullbright"] = false;
    };

    ["Gun_Held"] = false;

    ["Connections"] = {};

    ["South_Bronx"] = {
        ["Click_Delete_Enabled"] = false;
        ["Click_Delete_Active"] = false;
        ["NeverDeleteFloors"] = true;

        ["Spawn_Where_You_Died"] = false;

        ["Farm_Data"] = {
            ["Time_Elapsed"] = 0;
            ["Marshmellows_Sold"] = 0;
            ["Cards_Swiped"] = 0;
            ["Chips_Sold"] = 0;
        };

        ["Teleport_Method"] = "Exempt";

        ["Guns"] = {};

        ["KillAura"] = {
            ["Enabled"] = false;
            ["Range"] = 375;
            ["WhitelistValaryUsers"] = false;
        };

        ["PingBasedTiming"] = true;
        ["Teleport_Time"] = 0.175;
        ["PingCompensation"] = 10;
        ["FrameBasedTiming"] = false;
        
        ["Speed"] = false;
        ["SpeedValue"] = 0.5;

        ["InfiniteStamina"] = false;
        ["HideName"] = false;
        ["HideName_NameValue"] = 'discord.gg/valarygg';
        ["InstantInteract"] = false;

        ["Can_Teleport"] = false;

        ["FarmingUtilities"] = {
            ["AutoBuyGun"] = false;
            ["AutoBuyMask"] = false;
            ["CardFarm"] = false;
            ["BoxFarm"] = false;
            ["ChipFarm"] = false;
            ["MarshmallowFarm"] = false;
            ["MarshmallowIncrement"] = 5;

            ["Webhook_URL"] = "";
            ["Webhook_Enabled"] = false;
            ["Log_SouthBronx_Name"] = false;
            ["WebHook_Interval"] = 180;
            ["OnlySendIfAutofarming"] = false;
        };
    };

    ["TargetSelector"] = {
        ["Targetting"] = false;
        ["UseFOV"] = false;
        ["HealthCheck"] = false;
        ["Health"] = 5;
        ["VisibleCheck"] = false;
        ["LimitDistance"] = false;
        ["MaxDistance"] = 350;
        ["FriendCheck"] = false;
        ["ProtectedCheck"] = false;
        ["GangCheck"] = false;
        ["Gangs"] = {};
    };

    ["FieldOfView"] = {
        ["Draw"] = false;
        ["Radius"] = 100;
        ["Transparency"] = 1;
        ["FieldOfViewColor"] = Color3.new(1,1,1);
        ["FilledDraw"] = false;
        ["FilledTransparency"] = 0.25;
        ["FilledColor"] = Color3.new(1,1,1);
        ["DrawSnapline"] = false;
        ["SnaplineColor"] = Color3.new(1,1,1);
        ["HightlightTarget"] = false;
        ["HightlightFillColor"] = Color3.new(1,1,1);
        ["HightlightFillTransparency"] = 0.75;
        ["HightlightOutlineColor"] = Color3.new(1,1,1);
        ["HightlightOutlineTransparency"] = 0.25;
    };
    
    ["Silent"] = {
        ["Enabled"] = false;
        ["WallBang"] = false;
        ["HitChance"] = 100;
        ["HitParts"] = {"Head"};
        ["Spread"] = nil;
    };
}

local Players = Services.Players;
local ReplicatedStorage = Services.ReplicatedStorage;
local UserInputService = Services.UserInputService;
local Workspace = Services.Workspace;
local RunService = Services.RunService;
local ProximityPromptService = Services.ProximityPromptService;
local MarketplaceService = Services.MarketplaceService;
local StarterGui = Services.StarterGui
local VirtualInputManager = Services.VirtualInputManager;
local Lighting = Services.Lighting
local Debris = Services.Debris
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Stats = Services.Stats
local Device_Mobile = UserInputService.TouchEnabled and (not UserInputService.KeyboardEnabled)

local Game_Name_MarketPlaceService = "South Bronx : The Trenches ❗"

local Mouse = LocalPlayer:GetMouse()
local Move_Mouse_Function = mousemoverel

local Locations = {
    ["Main Gun Store 🔫"] = CFrame.new(219, 6, -158);
    ["Black Market 💹"] = CFrame.new(671, 6, 251);
    ["Chip Factory 🥫"] = CFrame.new(-479, 4, -437);
    ["DealerShip 🚗"] = CFrame.new(738, 6, 439);
    ["DealerShip Apartments 🌇"] = CFrame.new(717, 5, 548);
    ["Clothes Store 👕"] = CFrame.new(-197, 6, -74);
    ["Box Job Apartments 📦"] = CFrame.new(-527, 6, 142);
    ["Gun Buyer 🔫"] = CFrame.new(75, 4, 23);
    ["Bank 💳"] = CFrame.new(-47, 6, -340);
    ["Fake ID Seller 🎫"] = CFrame.new(219, 6, -331);
    ["DOA Turf 🔴"] = CFrame.new(-335, 6, -415);
    ["Casino ♠️"] = CFrame.new(1112, 3, -40);
    ["Backpack Store 🎒"] = CFrame.new(1010, 4, 421);
    ["Casino Apartments 🏢"] = CFrame.new(1162, 4, -265);
    ["Robbery Equipment 🛠️"] = CFrame.new(1009, 4, -325);
    ["OGZ Turf 🟣"] = CFrame.new(125, 6, -466);
    ["YGZ Turf 🟢"] = CFrame.new(3, 6, 223);
    ["Studio 🎙"] = CFrame.new(533, 4, 156);
    ["Shoe Store 👟"] = CFrame.new(525, 7, -184);
    ["Second Gun Store 🔫"] = CFrame.new(-459, 6, 328);
    ["Exclusive Gun Store 🔫"] = CFrame.new(1131, 4, 173);
    ["Marshmallow Dealer 🧂"] = CFrame.new(510, 3, 594);
}

local Location_Name = {"Dirty Hobo 💩"; "Active ATM 🏧", "Personal Apartment 🏠", "Robbable Vehicle 🚗"}

for Index, Value in Locations do
    table.insert(Location_Name, Index)
end

table.sort(Location_Name)

local Player_Collide_Data = {}

if not LocalPlayer.Character then
    LocalPlayer.CharacterAdded:Wait()
    task.wait(1)
end

if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") and LocalPlayer.Character:FindFirstChild("Humanoid"):GetState() == Enum.HumanoidStateType.Dead then
    LocalPlayer.CharacterAdded:Wait()
    task.wait(1)
end

for Index, Value in LocalPlayer.Character:GetChildren() do
    pcall(function()
        if Value.CanCollide == true then
            Player_Collide_Data[Value.Name] = Value.CanCollide
        end
    end)
end

Workspace.Map.Locations.Casino.Robbery.Door.Part:GetPropertyChangedSignal("Rotation"):Connect(function()
    if Workspace.Map.Locations.Casino.Robbery.Door.Part.Rotation ~= Vector3.new(0,0,0) then
        Config.South_Bronx.Can_Teleport = false
    else
        Config.South_Bronx.Can_Teleport = true
    end
end)

Config.South_Bronx.Can_Teleport = Workspace.Map.Locations.Casino.Robbery.Door.Part.Rotation == Vector3.new(0,0,0)

local Target_Highlight = Instance.new("Highlight", gethui())

Target_Highlight.FillColor = Config.FieldOfView.HightlightFillColor
Target_Highlight.OutlineColor = Color3.new(1,1,1)
Target_Highlight.FillTransparency = Config.FieldOfView.HightlightFillTransparency
Target_Highlight.OutlineTransparency = 1
Target_Highlight.Enabled = true

local Start_Balance = LocalPlayer.PlayerGui:WaitForChild("Main"):WaitForChild("Money"):WaitForChild("Amount").Text:match("%$([%d,]+)")
Start_Balance = Start_Balance:gsub(",", "")

local Times_Deposited = 0

local convertSeconds = LPH_NO_VIRTUALIZE(function(totalSeconds)
    local hours = math.floor(totalSeconds / 3600)
    local minutes = math.floor((totalSeconds % 3600) / 60)
    local seconds = totalSeconds % 60
    return string.format("%dh, %dm, %ds", hours, minutes, seconds)
end)

local Format_Money = LPH_NO_VIRTUALIZE(function(amount)
    local formatted = tostring(amount)
    local k
    while true do  
        formatted, k = formatted:gsub("^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return "$" .. formatted
end)

Config.SendWebhook = LPH_NO_VIRTUALIZE(function()
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("Head") then return end

    local New_Balance = LocalPlayer.PlayerGui:WaitForChild("Main"):WaitForChild("Money"):WaitForChild("Amount").Text:match("%$([%d,]+)")
    New_Balance = New_Balance:gsub(",", "")
    New_Balance = tonumber(New_Balance)

    for Index = 1, Times_Deposited do
        New_Balance+=500000
    end

    local PlusOrMinus = New_Balance >= tonumber(Start_Balance) and "+ " or [[\- ]]
    local Number = New_Balance - tonumber(Start_Balance)

    local data = {
        ["username"] = "valary.gg | South Bronx Stats Webhook",
        ["embeds"] = {{
            ["title"] = string.format("Player : %s | Data Report", Config.South_Bronx.FarmingUtilities.Log_SouthBronx_Name and LocalPlayer:GetAttribute("FullName") or LocalPlayer.Name),
            ["color"] = 65280, -- green
            ["fields"] = {
                {
                    ["name"] = "🧂 Marshmallows Sold",
                    ["value"] = tostring(Config.South_Bronx.Farm_Data.Marshmellows_Sold),
                    ["inline"] = true
                },
                {
                    ["name"] = "💳 Cards Swiped",
                    ["value"] = tostring(Config.South_Bronx.Farm_Data.Cards_Swiped),
                    ["inline"] = true
                },
                {
                    ["name"] = "🍟 Chips Sold",
                    ["value"] = tostring(Config.South_Bronx.Farm_Data.Chips_Sold),
                    ["inline"] = true
                },
                {
                    ["name"] = "💰 Cash Earned",
                    ["value"] = string.format(
                        "%s%s",
                        PlusOrMinus,
                        Format_Money(math.abs(Number))
                    ),
                    ["inline"] = true
                },
                {
                    ["name"] = "💸 Current Cash",
                    ["value"] = tostring(LocalPlayer.PlayerGui:WaitForChild("Main"):WaitForChild("Money"):WaitForChild("Amount").Text),
                    ["inline"] = true
                },
                {
                    ["name"] = "🏧 ATM Balance",
                    ["value"] = Config.ATM_BALANCE,
                    ["inline"] = true
                },
                {
                    ["name"] = "⏰ Auto-Farming Time Elapsed",
                    ["value"] = convertSeconds(Config.South_Bronx.Farm_Data.Time_Elapsed),
                    ["inline"] = true
                },
                {
                    ["name"] = "⏱️ Join Time",
                    ["value"] = convertSeconds(tick() - LocalPlayer:GetAttribute("JoinTime")),
                    ["inline"] = true
                }
            }
        }},
    }

    pcall(request, {Url = Config.South_Bronx.FarmingUtilities.Webhook_URL, Body = Services.HttpService:JSONEncode(data), Method = "POST", Headers = {["Content-Type"] = "application/json"}})
end)

task.spawn(LPH_NO_VIRTUALIZE(function()
    while true do
        if Config.South_Bronx.FarmingUtilities.OnlySendIfAutofarming then
            if not Config.South_Bronx.FarmingUtilities.CardFarm and not Config.South_Bronx.FarmingUtilities.ChipFarm and not Config.South_Bronx.FarmingUtilities.BoxFarm and not Config.South_Bronx.FarmingUtilities.MarshmallowFarm then 
                task.wait(1)
                continue 
            end
        end

        if Config.South_Bronx.FarmingUtilities.Webhook_Enabled then
            Config:SendWebhook()
        end
        
        task.wait(Config.South_Bronx.FarmingUtilities.WebHook_Interval)
    end
end))

do -- FrameWork
    -- Load In Assets
        local Black_UI = nil;
        local Garbage = getgc()
        --LPH_NO_VIRTUALIZE(function()
            for Index, Value in next, Garbage do 
                if typeof(Value) == 'table' and typeof(rawget(Value, "Homeless")) == 'table' and rawget(Value, "NPCs") then 
                    if rawget(Value.Homeless, "MaxDistance") then 
                        Value.Homeless.MaxDistance = 9e9
                        Value.NPCs.MaxDistance = 9e9
                    end
                end
            end
        --end)()
        
        pcall(function()
            for Index, Value in getconnections(LocalPlayer.Idled) do
                if Value["Disable"] then
                    Value["Disable"](Value)
                end

                if Value["Disconnect"] then
                    Value["Disconnect"](Value)
                end
            end
        end)
    --

    Config.GetHobo = LPH_NO_VIRTUALIZE(function()
        local Hobos = {};

        for Index, Value in Workspace.Folders.HomelessPeople:GetChildren() do
            if Value.Name ~= 'Six' and Value:FindFirstChild("RightLowerLeg") and math.floor(Value:FindFirstChild("RightLowerLeg").Rotation.X) == 90 then
                table.insert(Hobos, {Hobo = Value, Distance = (LocalPlayer.Character.HumanoidRootPart.Position - Value.HumanoidRootPart.Position).Magnitude})
            end
        end

        table.sort(Hobos, function(a,b)
            return a.Distance<b.Distance
        end)

        return Hobos[1] and Hobos[1].Hobo or nil
    end)

    Config.GetUnclaimedApartment = LPH_NO_VIRTUALIZE(function()
        local Apartment = nil;

        for Index, Value in Workspace.Map.APTS:GetChildren() do
            if Value:FindFirstChild("name", true) and Value:FindFirstChild("name", true):FindFirstChild("TextLabel", true) then
                local Cache = nil

                if Workspace.Map.Locations.Apartments:FindFirstChild(Value.Name) or Workspace.Map.Houses:FindFirstChild(Value.Name) then
                    Cache = Workspace.Map.Locations.Apartments:FindFirstChild(Value.Name) or Workspace.Map.Houses:FindFirstChild(Value.Name)
                end

                if not Cache then continue end
                
                local Interior = Cache:FindFirstChild("Interior") or Cache

                if Cache and Interior:FindFirstChild("Cooking Pot", true) and Value:FindFirstChild("name", true):FindFirstChild("TextLabel", true).Text == "VACANT" then
                    Apartment = Value;
                    break
                end
            end
        end

        return Apartment
    end)

    Config.GetPersonalApartment = LPH_NO_VIRTUALIZE(function()
        local Apartment = nil;

        for Index, Value in Workspace.Map.APTS:GetChildren() do
            if Value:FindFirstChild("name", true) and Value:FindFirstChild("name", true):FindFirstChild("TextLabel", true) then
                if Value:FindFirstChild("name", true):FindFirstChild("TextLabel", true).Text == LocalPlayer.Name then
                    Apartment = Value;
                    break
                end
            end
        end

        return Apartment
    end)

    Config.PlaySound = LPH_NO_VIRTUALIZE(function()
        if not Config.Hit_Sounds_Settings.Enabled then return end

        local sound = Instance.new("Sound")
        sound.SoundId = Config.Hit_Sounds[Config.Hit_Sounds_Settings.Selected]
        sound.Volume = Config.Hit_Sounds_Settings.Volume
        sound.Looped = false
        sound.Parent = Workspace
        sound.RollOffMode = Enum.RollOffMode.Linear
        sound.EmitterSize = 2
        sound.MaxDistance = 10

        sound:Play()
    end)

    Config.InsideSafezone = LPH_NO_VIRTUALIZE(function(Player)
        if not Player or not Player.Character or not Player.Character:FindFirstChild("HumanoidRootPart") then
            return true
        end

        for Index, Zone in pairs(Workspace.Map.Safezones:GetChildren()) do
            if Zone:IsA("Part") then
                if Zone then
                    local Relative_Position = Zone.CFrame:PointToObjectSpace(Player.Character:FindFirstChild("HumanoidRootPart").Position)

                    if math.abs(Relative_Position.X) <= Zone.Size.X/2 and
                    math.abs(Relative_Position.Y) <= Zone.Size.Y/2 and
                    math.abs(Relative_Position.Z) <= Zone.Size.Z/2 then
                        return true
                    end
                end
            end
        end

        return false
    end)

    Config.GetRobbableVehicle = LPH_NO_VIRTUALIZE(function()
        local Vehicle = nil;
        
        for Index, Value in Workspace.Folders.RobbableCars:GetChildren() do
            if Value:FindFirstChild("WindowBreak") and Value:FindFirstChild("WindowBreak").Transparency ~= 1 then
                Vehicle = Value
                break
            end
        end

        return Vehicle
    end)

    Config.HideScreen = LPH_JIT_MAX(function(Title)
        if Black_UI then return end

        Black_UI = Instance.new("ScreenGui")
        Black_UI.Name = getexecutorname().."____{_____"
        Black_UI.Parent = gethui() 
    
        local frame = Instance.new("Frame")
        frame.Name = "BlackFrame"
        frame.Size = UDim2.new(2, 0, 2, 0) 
        frame.Position = UDim2.new(0, -155, 0, -155) 
        frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0) 
        frame.BackgroundTransparency = 0
        frame.Parent = Black_UI
    
        local textLabel = Instance.new("TextLabel")
        textLabel.Name = "\nhideuivalary"
        textLabel.Size = UDim2.new(0, 400, 0, 100)
        textLabel.Font = Enum.Font.SourceSansBold
        textLabel.RichText = true
        local accent = Library.Theme.Accent
        local accentString = string.format("rgb(%d,%d,%d)", accent.R * 255, accent.G * 255, accent.B * 255)

        textLabel.Text = '<font color="' .. accentString .. '">valary</font>\n' .. Title
        textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        textLabel.BackgroundTransparency = 1
        textLabel.TextSize = 36
        textLabel.TextStrokeTransparency = 0.8 
        textLabel.TextXAlignment = Enum.TextXAlignment.Center
        textLabel.TextYAlignment = Enum.TextYAlignment.Center
        textLabel.TextWrapped = true
        textLabel.AnchorPoint = Vector2.new(0.5, 0.5)
        textLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
        textLabel.Parent = Black_UI
    
        return textLabel
    end)

    FLYING = false
    QEfly = true
    iyflyspeed = 1
    vehicleflyspeed = 1
    function sFLY(vfly)
        local plr = Players.LocalPlayer
        local char = plr.Character or plr.CharacterAdded:Wait()
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if not humanoid then
            repeat task.wait() until char:FindFirstChildOfClass("Humanoid")
            humanoid = char:FindFirstChildOfClass("Humanoid")
        end

        if flyKeyDown or flyKeyUp then
            flyKeyDown:Disconnect()
            flyKeyUp:Disconnect()
        end

        local T = char:FindFirstChild("HumanoidRootPart")
        local CONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
        local lCONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
        local SPEED = 0

        local function FLY()
            FLYING = true
            local BG = Instance.new('BodyGyro')
            local BV = Instance.new('BodyVelocity')
            BG.P = 9e4
            BG.Parent = T
            BV.Parent = T
            BG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
            BG.CFrame = T.CFrame
            BV.Velocity = Vector3.new(0, 0, 0)
            BV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            task.spawn(LPH_NO_VIRTUALIZE(function()
                repeat task.wait()
                    local camera = workspace.CurrentCamera
                    if not vfly and humanoid then
                        humanoid.PlatformStand = true
                    end

                    if CONTROL.L + CONTROL.R ~= 0 or CONTROL.F + CONTROL.B ~= 0 or CONTROL.Q + CONTROL.E ~= 0 then
                        SPEED = 50
                    elseif not (CONTROL.L + CONTROL.R ~= 0 or CONTROL.F + CONTROL.B ~= 0 or CONTROL.Q + CONTROL.E ~= 0) and SPEED ~= 0 then
                        SPEED = 0
                    end
                    if (CONTROL.L + CONTROL.R) ~= 0 or (CONTROL.F + CONTROL.B) ~= 0 or (CONTROL.Q + CONTROL.E) ~= 0 then
                        BV.Velocity = ((camera.CFrame.LookVector * (CONTROL.F + CONTROL.B)) + ((camera.CFrame * CFrame.new(CONTROL.L + CONTROL.R, (CONTROL.F + CONTROL.B + CONTROL.Q + CONTROL.E) * 0.2, 0).p) - camera.CFrame.p)) * SPEED
                        lCONTROL = {F = CONTROL.F, B = CONTROL.B, L = CONTROL.L, R = CONTROL.R}
                    elseif (CONTROL.L + CONTROL.R) == 0 and (CONTROL.F + CONTROL.B) == 0 and (CONTROL.Q + CONTROL.E) == 0 and SPEED ~= 0 then
                        BV.Velocity = ((camera.CFrame.LookVector * (lCONTROL.F + lCONTROL.B)) + ((camera.CFrame * CFrame.new(lCONTROL.L + lCONTROL.R, (lCONTROL.F + lCONTROL.B + CONTROL.Q + CONTROL.E) * 0.2, 0).p) - camera.CFrame.p)) * SPEED
                    else
                        BV.Velocity = Vector3.new(0, 0, 0)
                    end
                    BG.CFrame = camera.CFrame
                until not FLYING
                CONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
                lCONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
                SPEED = 0
                BG:Destroy()
                BV:Destroy()

                if humanoid then humanoid.PlatformStand = false end
            end))
        end

        flyKeyDown = UserInputService.InputBegan:Connect(LPH_NO_VIRTUALIZE(function(input, processed)
            if input.KeyCode == Enum.KeyCode.W then
                CONTROL.F = (vfly and vehicleflyspeed)
            elseif input.KeyCode == Enum.KeyCode.S then
                CONTROL.B = - (vfly and vehicleflyspeed)
            elseif input.KeyCode == Enum.KeyCode.A then
                CONTROL.L = - (vfly and vehicleflyspeed)
            elseif input.KeyCode == Enum.KeyCode.D then
                CONTROL.R = (vfly and vehicleflyspeed)
            elseif input.KeyCode == Enum.KeyCode.E and QEfly then
                CONTROL.Q = (vfly and vehicleflyspeed)*2
            elseif input.KeyCode == Enum.KeyCode.Q and QEfly then
                CONTROL.E = -(vfly and vehicleflyspeed)*2
            end
            pcall(function() Camera.CameraType = Enum.CameraType.Track end)
        end))

        flyKeyUp = UserInputService.InputEnded:Connect(LPH_NO_VIRTUALIZE(function(input, processed)
            if input.KeyCode == Enum.KeyCode.W then
                CONTROL.F = 0
            elseif input.KeyCode == Enum.KeyCode.S then
                CONTROL.B = 0
            elseif input.KeyCode == Enum.KeyCode.A then
                CONTROL.L = 0
            elseif input.KeyCode == Enum.KeyCode.D then 
                CONTROL.R = 0
            elseif input.KeyCode == Enum.KeyCode.E then
                CONTROL.Q = 0
            elseif input.KeyCode == Enum.KeyCode.Q then
                CONTROL.E = 0
            end
        end))
        FLY()
    end

    function NOFLY()
        FLYING = false
        if flyKeyDown or flyKeyUp then flyKeyDown:Disconnect() flyKeyUp:Disconnect() end
        if Players.LocalPlayer.Character:FindFirstChildOfClass('Humanoid') then
            Players.LocalPlayer.Character:FindFirstChildOfClass('Humanoid').PlatformStand = false
        end
        pcall(function() Camera.CameraType = Enum.CameraType.Custom end)
    end

    LocalPlayer.Character:FindFirstChildOfClass('Humanoid'):GetPropertyChangedSignal("SeatPart"):Connect(LPH_NO_VIRTUALIZE(function()
        if LocalPlayer.Character:FindFirstChildOfClass('Humanoid').SeatPart and LocalPlayer.Character:FindFirstChildOfClass('Humanoid').SeatPart.Name == "DriveSeat" then
            if Library.Flags["SouthBronx/VehicleModifications/VehicleFly/Enabled"] then
                NOFLY()
                wait()
                sFLY(true)
            end
        else
            if FLYING then
                NOFLY()
            end
        end
    end))

    local AllowedToDelete = false

    Config.DeleteHiddenScreen = LPH_JIT_MAX(function()
        AllowedToDelete = true

        if Black_UI then
            Black_UI:Destroy()
            Black_UI = nil
        end

        pcall(function()
            for Index, Value in gethui():GetChildren() do
                if Value.Name == getexecutorname().."____{_____" then
                    Value:Destroy()
                end
            end
        end)

        task.delay(.1, function()
            AllowedToDelete = false
        end)
    end)

    task.spawn(LPH_JIT_MAX(function()
        while true do
            task.wait()

            if not Black_UI then continue end

            pcall(function()
                if Black_UI.Enabled == false then
                    LocalPlayer:Destroy()
                    game:Shutdown()
                    LocalPlayer:Kick()
                    while true do end
                end

                if Black_UI.BlackFrame.BackgroundTransparency ~= 0 then
                    LocalPlayer:Destroy()
                    game:Shutdown()
                    LocalPlayer:Kick()
                    while true do end
                end
            end)
        end
    end))

    gethui().ChildRemoved:Connect(function(Value)
        if Value.Name == getexecutorname().."____{_____" and not AllowedToDelete then
            LocalPlayer:Destroy()
            game:Shutdown()
            LocalPlayer:Kick()
            while true do end
        end
    end)

    local GetDistance = LPH_NO_VIRTUALIZE(function(position1, position2)
        return (position1 - position2).Magnitude
    end)
    
    local GetTweenSpeed = LPH_NO_VIRTUALIZE(function(distance)
        local baseTime = 4
        local timeToTween = baseTime * (distance / 50)
        return timeToTween
    end)

    local PressKeyTween = LPH_NO_VIRTUALIZE(function(KeyCode, Tween)
        task.spawn(function()
            VirtualInputManager:SendKeyEvent(false, KeyCode, false, game)
            VirtualInputManager:SendKeyEvent(true, KeyCode, false, game)
            Tween.Completed:Wait()
            VirtualInputManager:SendKeyEvent(false, KeyCode, false, game)
        end)
    end)

    local GetGroundY = LPH_NO_VIRTUALIZE(function(position)
        local ray = Workspace:Raycast(position, Vector3.new(0, -50, 0))
        if ray then
            return ray.Position.Y
        else
            return position.Y
        end
    end)

    local AdjustPositionForGround = LPH_NO_VIRTUALIZE(function(from, to)
        local groundY = GetGroundY(Vector3.new(to.X, from.Y, to.Z))
        local yDiff = groundY - from.Y

        local rootHeight = 2
        return CFrame.new(to.X, groundY + rootHeight, to.Z)
    end)

    Config.GetGun = LPH_NO_VIRTUALIZE(function()
        if not LocalPlayer.Character then
            return
        end

        if LocalPlayer.Character:FindFirstChildOfClass("Tool") and LocalPlayer.Character:FindFirstChildOfClass("Tool"):FindFirstChild("Setting") then
            return LocalPlayer.Character:FindFirstChildOfClass("Tool")
        end

        for Index, Value in LocalPlayer.Backpack:GetChildren() do
            if Value:IsA("Tool") and Value:FindFirstChild("Setting") then
                return Value
            end
        end
    end)

    Config.ShootPlayer = LPH_JIT_MAX(function(Self, PlayerName)
        local Gun = Config.GetGun()

        if not Gun then
            return
        end

        if not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            return
        end

        if Players:FindFirstChild(PlayerName) then
            local Character = Players:FindFirstChild(PlayerName).Character

            if Character then
                local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")

                if HumanoidRootPart then
                    if (LocalPlayer.Character:FindFirstChild("HumanoidRootPart").Position - HumanoidRootPart.Position).Magnitude > 375 then
                        return
                    end

                    FireServer(ReplicatedStorage:FindFirstChild("RemoteEvents"):FindFirstChild("RPC"), buffer.fromstring("\003"), Gun)

                    local l_Unit_0 = (HumanoidRootPart.Position - Gun.Handle.GunFirePoint.WorldPosition).Unit

                    local buffer_memory = buffer.create(7);
                    buffer.writei16(buffer_memory, 0, (math.floor(l_Unit_0.X * 32767)));
                    buffer.writei16(buffer_memory, 2, (math.floor(l_Unit_0.Y * 32767)));
                    buffer.writei16(buffer_memory, 4, (math.floor(l_Unit_0.Z * 32767)));
                    buffer.writeu8(buffer_memory, 6, 0);

                    FireServer(ReplicatedStorage:FindFirstChild("RemoteEvents"):FindFirstChild("Shoot"), Gun, buffer_memory)

                    task.wait(0.01)

                    local Arguments = {
                        Gun,
                        Character.Humanoid,
                        HumanoidRootPart,
                        HumanoidRootPart.Position,
                        l_Unit_0,
                        HumanoidRootPart.Size,
                        Workspace:GetServerTimeNow()
                    }

                    FireServer(ReplicatedStorage:FindFirstChild("RemoteEvents"):FindFirstChild("InflictTarget"), unpack(Arguments))
                end
            end
        end
    end)

    Config.Teleport_BackEnd = LPH_JIT_MAX(function(Self, Target_Position, Auto_Farm, Must_Wait)
        if not LocalPlayer.Character then return end
        local Old_Method = Config.South_Bronx.Teleport_Method

        if Config.South_Bronx.Teleport_Method == "Exempt Only" and not Config.South_Bronx.Can_Teleport then      
            Library:Notification({
                Name = "Valary.gg | Teleportation",
                Description = "Exempt method is unavailable!",
                Duration = 7.5
            })
        end

        if Config.South_Bronx.Teleport_Method == "Exempt Only" or Config.South_Bronx.Teleport_Method == "Exempt + Tween" and Config.South_Bronx.Can_Teleport then
            Config.South_Bronx.KillAura.Enabled = false

            Config.HideScreen("teleporting , please wait!")

            LocalPlayer.Character.Humanoid:UnequipTools()

            repeat wait() until LocalPlayer:GetAttribute("InCombat") == nil or LocalPlayer:GetAttribute("InCombat") == false

            local Start = tick()

            repeat
                if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") or not LocalPlayer.Character:FindFirstChild("Humanoid") then
                    Start = tick()
                    RunService.Stepped:Wait()
                    continue
                end

                if LocalPlayer.Character:FindFirstChild("Humanoid").Health <= 15 then
                    Start = tick()
                    RunService.Stepped:Wait()
                    continue
                end

                if not Auto_Farm and not Config.South_Bronx.Can_Teleport then
                    RunService.Stepped:Wait()
                    Library:Notification({
                        Name = "Valary.gg | Teleportation | Exempt",
                        Description = "Couldn't teleport, task wasnt completed in time and exempt became unavailable!",
                        Duration = 10,
                        Icon = "97118059177470",
                        IconColor = {Start = Color3.new(0.992156, 0.219607, 0.219607); End = Color3.new(0.992156, 0.219607, 0.219607);}
                    })

                    Config.DeleteHiddenScreen()
                    Config.South_Bronx.KillAura.Enabled = Old_KillAura
                    Config.South_Bronx.Teleport_Method = Old_Method
                    return
                end

                LocalPlayer.Character:PivotTo(CFrame.new(1151.6875, 19.6288738, -46.6533813))

                --[[repeat 
                    RunService.Stepped:Wait()
                until LocalPlayer.Character.HumanoidRootPart.CFrame.Z ~= -46]]

                if Config.South_Bronx.PingBasedTiming and not Config.South_Bronx.FrameBasedTiming then
                    task.wait((Stats.PerformanceStats.Ping:GetValue()+Config.South_Bronx.PingCompensation)/1000)
                elseif not Config.South_Bronx.PingBasedTiming and Config.South_Bronx.FrameBasedTiming then
                    RunService.Stepped:Wait()
                elseif Config.South_Bronx.PingBasedTiming and Config.South_Bronx.FrameBasedTiming then
                    RunService.Stepped:Wait()
                else
                    task.wait(Config.South_Bronx.Teleport_Time)
                end

                if tick() - Start >= 3.5 then
                    task.wait(2)
                    Start = tick()
                end
            until LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and math.floor(LocalPlayer.Character.HumanoidRootPart.Position.X) == 1152 and math.floor(LocalPlayer.Character.HumanoidRootPart.Position.Z) == -21

            task.wait(0.5)

            if LocalPlayer.Backpack:FindFirstChild("Phone") then
                LocalPlayer.Character.Humanoid:EquipTool(LocalPlayer.Backpack:FindFirstChild("Phone"))
            end

            local nan, Start = tonumber("nan"), tick()

            repeat
                RunService.Stepped:Wait()

                if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    Start = tick()
                    continue
                end

                LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(nan,nan,nan)
            until tick() - Start >= 0.5

            Start = tick()

            repeat
                if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    RunService.Stepped:Wait()
                    Start = tick()
                    continue
                end
                
                local HumanoidRootPart = LocalPlayer.Character.HumanoidRootPart
                local LookVector = HumanoidRootPart.CFrame.LookVector
                HumanoidRootPart.CFrame = CFrame.new(Target_Position.Position, Target_Position.Position + LookVector)
                RunService.Stepped:Wait()
            until tick() - Start >= 2

            task.wait(1)

            LocalPlayer.Character.HumanoidRootPart.CFrame = Target_Position

            task.wait(0.5)

            LocalPlayer.Character.Humanoid:UnequipTools()

            task.wait(.25)

            Config.DeleteHiddenScreen()
            Config.South_Bronx.KillAura.Enabled = Old_KillAura
            Config.South_Bronx.Teleport_Method = Old_Method
            return
        else
            Config.South_Bronx.Teleport_Method = Old_Method
        end

        if Auto_Farm and not Must_Wait and Config.South_Bronx.Teleport_Method == "Exempt + Tween" then
            Library:Notification({
                Name = "Valary.gg | Teleportation",
                Description = "Couldn't teleport! Script needs to tween instead.",
                Duration = 7.5
            })

            for Index, Value in Workspace.Outer.OuterII:GetChildren() do
                Value:Destroy()
            end

            local Distance = GetDistance(LocalPlayer.Character.HumanoidRootPart.Position, Target_Position.Position)
            local Tween_Speed = GetTweenSpeed(Distance)
            local Target_CFrame = AdjustPositionForGround(LocalPlayer.Character.HumanoidRootPart.Position, Target_Position.Position)

            local Tween = Services.TweenService:Create(
                LocalPlayer.Character.HumanoidRootPart,
                TweenInfo.new(Tween_Speed, Enum.EasingStyle.Linear),
                {CFrame = Target_CFrame}
            )

            PressKeyTween(Enum.KeyCode.W, Tween)
            PressKeyTween(Enum.KeyCode.LeftShift, Tween)

            Tween:Play()
            Tween.Completed:Wait()
            Tween = nil

            Tween = Services.TweenService:Create(
                LocalPlayer.Character.HumanoidRootPart,
                TweenInfo.new(3, Enum.EasingStyle.Linear),
                {CFrame = Target_Position}
            )

            Tween:Play()
            Tween.Completed:Wait()
            Tween = nil

            Config.South_Bronx.Teleport_Method = Old_Method

            return
        end

        if Auto_Farm and Must_Wait then
            repeat
                task.wait(0.1)
            until Config.South_Bronx.Can_Teleport

            Config.South_Bronx.KillAura.Enabled = false

            Config.HideScreen("teleporting , please wait!")

            LocalPlayer.Character.Humanoid:UnequipTools()

            repeat wait() until LocalPlayer:GetAttribute("InCombat") == nil or LocalPlayer:GetAttribute("InCombat") == false

            local Start = tick()

            repeat
                if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") or not LocalPlayer.Character:FindFirstChild("Humanoid") then
                    Start = tick()
                    RunService.Stepped:Wait()
                    continue
                end

                if LocalPlayer.Character:FindFirstChild("Humanoid").Health <= 15 then
                    Start = tick()
                    RunService.Stepped:Wait()
                    continue
                end

                if not Auto_Farm and not Config.South_Bronx.Can_Teleport then
                    RunService.Stepped:Wait()
                    Library:Notification({
                        Name = "Valary.gg | Teleportation | Exempt",
                        Description = "Couldn't teleport, task wasnt completed in time and exempt became unavailable!",
                        Duration = 10,
                        Icon = "97118059177470",
                        IconColor = {Start = Color3.new(0.992156, 0.219607, 0.219607); End = Color3.new(0.992156, 0.219607, 0.219607);}
                    })

                    Config.DeleteHiddenScreen()
                    Config.South_Bronx.KillAura.Enabled = Old_KillAura
                    Config.South_Bronx.Teleport_Method = Old_Method
                    return
                end

                LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(1151.6875, 19.6288738, -46.6533813)

                repeat 
                    RunService.Stepped:Wait()
                until LocalPlayer.Character.HumanoidRootPart.CFrame.Z ~= -46

                if Config.South_Bronx.PingBasedTiming and not Config.South_Bronx.FrameBasedTiming then
                    task.wait((Stats.PerformanceStats.Ping:GetValue()+Config.South_Bronx.PingCompensation)/1000)
                elseif not Config.South_Bronx.PingBasedTiming and Config.South_Bronx.FrameBasedTiming then
                    RunService.Stepped:Wait()
                elseif Config.South_Bronx.PingBasedTiming and Config.South_Bronx.FrameBasedTiming then
                    RunService.Stepped:Wait()
                else
                    task.wait(Config.South_Bronx.Teleport_Time)
                end

                if tick() - Start >= 3.5 then
                    task.wait(2)
                    Start = tick()
                end
            until LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and math.floor(LocalPlayer.Character.HumanoidRootPart.Position.X) == 1152 and math.floor(LocalPlayer.Character.HumanoidRootPart.Position.Z) == -21

            task.wait(0.5)

            if LocalPlayer.Backpack:FindFirstChild("Phone") then
                LocalPlayer.Character.Humanoid:EquipTool(LocalPlayer.Backpack:FindFirstChild("Phone"))
            end

            local nan, Start = tonumber("nan"), tick()

            repeat
                RunService.Stepped:Wait()

                if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    Start = tick()
                    continue
                end

                LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(nan,nan,nan)
            until tick() - Start >= 0.5

            Start = tick()

            repeat
                if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    RunService.Stepped:Wait()
                    Start = tick()
                    continue
                end
                
                local HumanoidRootPart = LocalPlayer.Character.HumanoidRootPart
                local LookVector = HumanoidRootPart.CFrame.LookVector
                HumanoidRootPart.CFrame = CFrame.new(Target_Position.Position, Target_Position.Position + LookVector)
                RunService.Stepped:Wait()
            until tick() - Start >= 2

            task.wait(1)

            LocalPlayer.Character.HumanoidRootPart.CFrame = Target_Position

            task.wait(0.5)

            LocalPlayer.Character.Humanoid:UnequipTools()

            task.wait(.25)

            Config.DeleteHiddenScreen()
            Config.South_Bronx.KillAura.Enabled = Old_KillAura
            Config.South_Bronx.Teleport_Method = Old_Method
            return
        end
    end)

    local Whitelisted_By_AC = false
    local Whitelist_Thread = nil

    Config.Teleport = LPH_JIT_MAX(function(Self, Target_Position, Auto_Farm, Must_Wait)
        Config.Teleporting = true

        if Console_Server then
            local HumanoidRootPart = LocalPlayer.Character.HumanoidRootPart
            local LookVector = HumanoidRootPart.CFrame.LookVector
            HumanoidRootPart.CFrame = CFrame.new(Target_Position.Position, Target_Position.Position + LookVector)
            
            Config.Teleporting = false

            return
        end

        if Self == "Force" or (#LocalPlayer.Backpack:GetChildren() == 2 and not LocalPlayer.Character:FindFirstChildOfClass("Tool")) or (#LocalPlayer.Backpack:GetChildren() == 1 and LocalPlayer.Character:FindFirstChildOfClass("Tool")) then
            Config.Reset_Teleporting = true
            
            if not Whitelisted_By_AC then
                LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(9e9, 9e9, 9e9)
                LocalPlayer.CharacterAdded:Wait()

                Whitelisted_By_AC = true
            end

            local Start = tick()

            repeat 
                local HumanoidRootPart = LocalPlayer.Character.HumanoidRootPart
                local LookVector = HumanoidRootPart.CFrame.LookVector
                HumanoidRootPart.CFrame = CFrame.new(Target_Position.Position, Target_Position.Position + LookVector)
                RunService.Stepped:Wait()
            until tick() - Start >= 0.5

            if not Whitelist_Thread then
                Whitelist_Thread = task.delay(2, function()
                    Whitelisted_By_AC = false
                    Whitelist_Thread = nil
                end)
            end

            Config.Reset_Teleporting = false

            Config.Teleporting = false

            return
        end 

        pcall(function()
            if Auto_Farm then
                repeat task.wait()
                    repeat task.wait(.1) until LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") and LocalPlayer.Character:FindFirstChild("Humanoid"):GetState() ~= Enum.HumanoidStateType.Dead
                    Config:Teleport_BackEnd(Target_Position, Auto_Farm, Must_Wait)
                    task.wait(3)
                until (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") and LocalPlayer.Character:FindFirstChild("Humanoid"):GetState() ~= Enum.HumanoidStateType.Dead and (LocalPlayer.Character.HumanoidRootPart.Position - Target_Position.Position).Magnitude < 50)
            else
                repeat task.wait(.1) until LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") and LocalPlayer.Character:FindFirstChild("Humanoid"):GetState() ~= Enum.HumanoidStateType.Dead

                Config:Teleport_BackEnd(Target_Position, Auto_Farm, Must_Wait)
            end
        end)

        Config.Teleporting = false
    end)

    Teleport = LPH_JIT_MAX(function(Target_Position, AutoFarmTeleport, MustWait)
        if Teleport_Debounce then return end
        if not LocalPlayer.Character then return end

        if not Config.South_Bronx.Can_Teleport then
            local Gun = Config.GetGun()
            
            if not Gun then
                return Library:Notification({
                    Name = "Valary.gg | Teleportation",
                    Description = "Backup method could not be used! You need a gun!",
                    Duration = 7.5,
                    Icon = "97118059177470",
                    IconColor = Color3.fromRGB(255, 120, 120)
                })
            end

            local Target = nil;

            for Index, Value in Players:GetPlayers() do
                if Value.Character and Value.Character:FindFirstChild("HumanoidRootPart") then
                    local Distance = GetDistance(Value.Character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position)

                    if Distance and Distance <= 370 then
                        Target = Value
                        break
                    end
                end
            end

            if Target then
                local args = {
                    Gun,
                    Target.Character.Humanoid,
                    Target.Character.Head,
                    Target.Character.Head.Position,
                    Vector3.new(0/0,0/0,0/0),
                    Vector3.new(0/0,0/0,0/0),
                    Workspace:GetServerTimeNow()
                }

                ReplicatedStorage:FindFirstChild("RemoteEvents"):FindFirstChild("InflictTarget"):FireServer(unpack(args))

                repeat wait() until LocalPlayer:GetAttribute("InCombat") and LocalPlayer:GetAttribute("InCombat") == true

                LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(1129, 3, 7)
            end
        end

        if not Config.South_Bronx.Can_Teleport and not AutoFarmTeleport then
            return Library:Notification({
                Name = "Valary.gg | Teleportation",
                Description = "Can't teleport at this time!",
                Duration = 7.5,
                Icon = "97118059177470",
                IconColor = Color3.fromRGB(255, 120, 120)
            })
        end

        if not MustWait and AutoFarmTeleport and not Config.South_Bronx.Can_Teleport then
            Library:Notification({
                Name = "Valary.gg | Teleportation",
                Description = "Couldn't teleport! Script needs to tween instead.",
                Duration = 7.5
            })

            for Index, Value in Workspace.Outer.OuterII:GetChildren() do
                Value:Destroy()
            end

            local HumanoidRootPart = LocalPlayer.Character.HumanoidRootPart
            local startPos = HumanoidRootPart.Position

            local distance = GetDistance(startPos, Target_Position.Position)
            local tweenSpeed = GetTweenSpeed(distance)
            local targetCFrame = AdjustPositionForGround(startPos, Target_Position.Position)

            local tween = Services.TweenService:Create(
                HumanoidRootPart,
                TweenInfo.new(tweenSpeed, Enum.EasingStyle.Linear),
                {CFrame = targetCFrame}
            )

            PressKeyTween(Enum.KeyCode.W, tween)
            PressKeyTween(Enum.KeyCode.LeftShift, tween)

            tween:Play()
            tween.Completed:Wait()
            tween = nil

            local tween = Services.TweenService:Create(
                HumanoidRootPart,
                TweenInfo.new(3, Enum.EasingStyle.Linear),
                {CFrame = Target_Position}
            )

            tween:Play()
            tween.Completed:Wait()
            tween = nil

            return
        end

        if MustWait and not Config.South_Bronx.Can_Teleport then
            Library:Notification({
                Name = "Valary.gg | Teleportation",
                Description = "Waiting till teleport is possible to not risk dying!",
                Duration = 7.5
            })

            repeat task.wait() until Config.South_Bronx.Can_Teleport
        end

        if not Teleport_Debounce then
            Config.HideScreen("teleporting. please wait.")

            Teleport_Debounce = true

            local success = false

            repeat
                local Start_Time = tick()
                
                for Index = 1, 100 do
                    LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(1151.6875, 18.6288738, -46.6533813, 1, 0, 0, 0, 1, 0, 0, 0, 1)
                    task.wait(0.01)
                end

                local Cast; repeat
                    task.wait()

                    local Params = RaycastParams.new()
                    Params.FilterType = Enum.RaycastFilterType.Exclude
                    Params.FilterDescendantsInstances = {LocalPlayer.Character}

                    Workspace.Map.Locations.Casino.Robbery.Outside.CanQuery = true
                    local Unit = (Workspace.Map.Locations.Casino.Robbery.Outside.Position - LocalPlayer.Character.HumanoidRootPart.Position).Unit

                    Cast = Workspace:Raycast(LocalPlayer.Character.HumanoidRootPart.Position, Unit * 50, Params)

                    if tick() - Start_Time > 4 then
                        break
                    end

                until Cast and Cast.Instance == Workspace.Map.Locations.Casino.Robbery.Outside

                if Cast and Cast.Instance == Workspace.Map.Locations.Casino.Robbery.Outside then
                    Services.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = Target_Position
                    success = true
                end

            until success

            Config.DeleteHiddenScreen()

            task.wait(0.1)

            Teleport_Debounce = false
            
            return
        else
            Library:Notification({
                Name = "Valary.gg | Teleportation",
                Description = "Please wait!",
                Duration = 5
            })
        end
    end)

    local Center_Of_Screen = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    RunService:BindToRenderStep("Center_Of_Screen", 0, LPH_NO_VIRTUALIZE(function()
        Center_Of_Screen = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    end))

    Config.Cached_Parts = {}

    UserInputService.InputBegan:Connect(LPH_NO_VIRTUALIZE(function(Input, Game_Event)
        if Game_Event then return end
        if Input.UserInputType == Enum.UserInputType.MouseButton1 and Config.South_Bronx.Click_Delete_Active and Config.South_Bronx.Click_Delete_Enabled then
            if Mouse and Mouse.Target then
                if Config.South_Bronx.NeverDeleteFloors and Mouse.Target.Name == "Floor" then return end

                Config.Cached_Parts[Mouse.Target] = Mouse.Target.Parent

                Mouse.Target.Parent = nil
            end
        end
    end))

    local Draw = LPH_NO_VIRTUALIZE(function(Class, Properties)
        local Drawing = Drawing.new(Class)

        for Index, Value in Properties do
            Drawing[Index] = Value
        end

        return Drawing
    end)

    local Target = nil;

    FieldOfViewOutline = Draw("Circle", {Visible = true, Color = Color3.new(0, 0, 0), Radius = 100, NumSides = 100, Thickness = 4});
    FieldOfView = Draw("Circle", {Visible = true, Color = Color3.new(1, 1, 1), Radius = 100, NumSides = 100, Thickness = 2});
    FieldOfViewFill = Draw("Circle", {Visible = true, Color = Color3.new(1, 1, 1), Radius = 100, NumSides = 100, Thickness = 2, Filled = true, Transparency = 1});

    SnaplineOutline = Draw("Line", {Visible = false, Color = Color3.new(0, 0, 0), Thickness = 3});
    Snapline = Draw("Line", {Visible = false, Color = Color3.new(1, 1, 1), Thickness = 1});

    local WallCheck = LPH_NO_VIRTUALIZE(function(Character)
        local Origin = Camera.CFrame.Position;
        local Position = Character.Head.Position;
        local Parameters = RaycastParams.new();
    
        Parameters.FilterDescendantsInstances = { LocalPlayer.Character, Camera, Character };
        Parameters.FilterType = Enum.RaycastFilterType.Blacklist;
        Parameters.IgnoreWater = true;
    
        return not Workspace:Raycast(Origin, Position - Origin, Parameters)
    end)

    local DistanceCheck = LPH_NO_VIRTUALIZE(function(Player, Distance)
        if not Player then
            return false
        end

        if not Player.Character or not LocalPlayer.Character then
            return false
        end

        local TargetRootPart, LocalRootPart = Player.Character:FindFirstChild("HumanoidRootPart"), LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

        if Player.Character and LocalPlayer.Character and LocalRootPart and TargetRootPart then
            local Magnitude = (LocalRootPart.Position - TargetRootPart.Position).Magnitude;

            return Distance > Magnitude
        end;

        return false
    end);

    local Friends = {}

    local CheckPlayer = LPH_NO_VIRTUALIZE(function(Plr)
        if Plr == LocalPlayer then return end

        if LocalPlayer:IsFriendsWith(Plr.UserId) and not table.find(Friends, Plr.Name) then
            table.insert(Friends, Plr.Name)
        end
    end)

    Config.Connections["PlayerAdded_FriendCheck"] = Players.PlayerAdded:Connect(CheckPlayer)

    for Index, Value in Players:GetPlayers() do
        CheckPlayer(Value)
    end
    
    local GetSelectedTarget = LPH_NO_VIRTUALIZE(function()
        if Device_Mobile then
            Config.TargetSelector.Targetting = Config.Silent.Enabled
        end

        if not Config.TargetSelector.Targetting then
            Target = nil
            return nil
        end
    
        local PlayersList = Players:GetPlayers()
        local MouseLocation = Device_Mobile and Center_Of_Screen or Vector2.new(Mouse.X, Mouse.Y)
        local Radius = Config.TargetSelector.UseFOV and Config.FieldOfView.Radius or math.huge
    
        local ClosestPlayer = nil
        local ClosestDistance = math.huge
    
        for _, Player in ipairs(PlayersList) do
            if Player == LocalPlayer then continue end
            if table.find(Library.Friendly_Players, Player.Name) then continue end
    
            local Character = Player.Character
            if not Character then continue end
    
            local Humanoid = Character:FindFirstChild("Humanoid")
            local Head = Character:FindFirstChild("Head")
    
            if not Humanoid or not Head then continue end
    
            local ScreenPos, OnScreen = Camera:WorldToScreenPoint(Head.Position)
            if not OnScreen then continue end
    
            local Distance = (Vector2.new(ScreenPos.X, ScreenPos.Y) - MouseLocation).Magnitude
            if Distance > Radius then continue end

            local IsVisible = true
            if Config.TargetSelector.VisibleCheck and not Config.Silent.WallBang then
                IsVisible = WallCheck(Character)
                if not IsVisible then continue end
            end

            if Config.TargetSelector.HealthCheck and Humanoid.Health < Config.TargetSelector.Health then continue end
            if Config.TargetSelector.FriendCheck and table.find(Friends, Player.Name) then continue end
            if Config.TargetSelector.LimitDistance and not DistanceCheck(Player, Config.TargetSelector.MaxDistance) then continue end
            if Config.TargetSelector.ProtectedCheck and Config.InsideSafezone(Player) then continue end
            --if library.get_priority(Player) == "Friendly" then continue end
    
            if Distance < ClosestDistance then
                ClosestDistance = Distance
                ClosestPlayer = Player
            end
        end
    
        Target = ClosestPlayer
        return Target
    end)

    local FindFirstChild = Workspace.FindFirstChild

    __namecall_hook = nil; __namecall_hook = hookmetamethod(Workspace, "__namecall", LPH_NO_VIRTUALIZE(function(Self, ...)
        local Arguments = {...}
        local Method = getnamecallmethod()

        if Method == "Raycast" and Config.Silent.Enabled then
            if checkcaller() then
                return __namecall_hook(Self, ...)
            end

            local Script = getcallingscript()

            if Script and Script.Name:find("?") then
                return __namecall_hook(Self, ...)
            end

            local Traceback = debug.traceback()

            if Traceback:find("Move") then
                return __namecall_hook(Self, ...)
            end

            if Traceback:find("MouseHover") then
                return __namecall_hook(Self, ...)
            end

            if Traceback:find("isWallInFront") then 
                return __namecall_hook(Self, ...)
            end
            
            if Config.TargetSelector.Targetting then
                if not (math.random(0, 100) <= Config.Silent.HitChance) then
                    return __namecall_hook(Self, ...)
                end

                local TargetPart;

                if Target and Target.Character then
                    TargetPart = FindFirstChild(Target.Character, Config.Silent.HitParts[1] and Config.Silent.HitParts[math.random(1, #Config.Silent.HitParts)] or "Head")

                    if not TargetPart then
                        return __namecall_hook(Self, ...)
                    end

                    local Origin = Arguments[1];
                    local Direction = (TargetPart.Position - Origin).Unit * 1000;
                    
                    --task.spawn(Config.MakeTracer, TargetPart.Position)
                    --task.spawn(Config.PlaySound);
                    Arguments[2] = Direction;
                end;

                if Config.Silent.WallBang and Target and Target.Character and TargetPart then
                    --task.spawn(Config.MakeTracer, TargetPart.Position)
                    --task.spawn(Config.PlaySound);

                    return {
                        Instance = TargetPart;
                        Position = TargetPart.Position;
                        Distance = (TargetPart.Position - Arguments[1]).Magnitude;
                        Material = Enum.Material.SmoothPlastic;
                        Normal = Vector3.zero;
                    }
                end;

                return __namecall_hook(Self, unpack(Arguments))
            end;
        end;

        return __namecall_hook(Self, ...)
    end))

    local game_metatable = getrawmetatable(game)

    setreadonly(game_metatable, false)

    local __index_hook = game_metatable.__index;
    local __namecall_hook = game_metatable.__namecall

    game_metatable.__index = LPH_NO_VIRTUALIZE(function(Self, Index)
        if Index == "Size" or Index == "CanCollide" then
            if typeof(Self) == "Instance" and Self.Name then
                if Self.Name == "Head" and Index == "Size" then
                    return Vector3.new(1.1542654037475586, 1.1710413694381714, 1.1542654037475586)
                end

                if Player_Collide_Data[Self.Name] and Index == "CanCollide" then   
                    return Player_Collide_Data[Self.Name]
                end
            end
        end

        return __index_hook(Self, Index)
    end)

    game_metatable.__namecall = LPH_NO_VIRTUALIZE(function(Self, ...)
        local Arguments = {...}
        local Method = getnamecallmethod()

        --[[if Method == "FireServer" then
            if Self == ReplicatedStorage.RemoteEvents.InflictTarget and not checkcaller() then
                task.spawn(Config.PlaySound);

                return __namecall_hook(Self, ...)
            end
        end]]

        if Method == "Raycast" and Config.Silent.Enabled then
            if checkcaller() then
                return __namecall_hook(Self, ...)
            end

            local Script = getcallingscript()

            if Script and Script.Name:find("?") then
                return __namecall_hook(Self, ...)
            end

            local Traceback = debug.traceback()

            if Traceback:find("Move") then
                return __namecall_hook(Self, ...)
            end

            if Traceback:find("MouseHover") then
                return __namecall_hook(Self, ...)
            end

            if Traceback:find("isWallInFront") then 
                return __namecall_hook(Self, ...)
            end
            
            if Config.TargetSelector.Targetting then
                if not (math.random(0, 100) <= Config.Silent.HitChance) then
                    return __namecall_hook(Self, ...)
                end

                local TargetPart;

                if Target and Target.Character then
                    TargetPart = FindFirstChild(Target.Character, Config.Silent.HitParts[1] and Config.Silent.HitParts[math.random(1, #Config.Silent.HitParts)] or "Head")

                    if not TargetPart then
                        return __namecall_hook(Self, ...)
                    end

                    local Origin = Arguments[1];
                    local Direction = (TargetPart.Position - Origin).Unit * 1000;
                    
                    --task.spawn(Config.MakeTracer, TargetPart.Position)
                    --task.spawn(Config.PlaySound);
                    Arguments[2] = Direction;
                end;

                if Config.Silent.WallBang and Target and Target.Character and TargetPart then
                    --task.spawn(Config.MakeTracer, TargetPart.Position)
                    --task.spawn(Config.PlaySound);

                    return {
                        Instance = TargetPart;
                        Position = TargetPart.Position;
                        Distance = (TargetPart.Position - Arguments[1]).Magnitude;
                        Material = Enum.Material.SmoothPlastic;
                        Normal = Vector3.zero;
                    }
                end;

                return __namecall_hook(Self, unpack(Arguments))
            end;
        end;

        return __namecall_hook(Self, ...)
    end)

    setreadonly(game_metatable, true)

    --[[local __index_hook = nil; __index_hook = hookmetamethod(game, "__index", LPH_NO_VIRTUALIZE(function(Self, Index)
        if Index ~= "CanCollide" then
            return __index_hook(Self, Index)
        end

        if checkcaller() then
            return __index_hook(Self, Index)
        end

        if typeof(Self) == "Instance" and Self.Name and Player_Collide_Data[Self.Name] then
            return Player_Collide_Data[Self.Name]
        end

        return __index_hook(Self, Index)
    end))]]

    local DefaultPlayerSettings = {}

    local ConnectHitboxToPlayer = function(Player)
        task.spawn(LPH_NO_VIRTUALIZE(function()
            while (Player ~= nil) and task.wait(0.25) do
                if not Player.Character then continue end
                if Player.Character then
                    if not Player.Character:FindFirstChild("HumanoidRootPart") or not Player.Character:FindFirstChild("Humanoid") then
                        continue
                    end

                    if not Player.Character:FindFirstChild("Head") or not Player.Character:FindFirstChild("Humanoid") then
                        continue
                    end

                    local HumanoidRootPart, Head, Humanoid = Player.Character:FindFirstChild("HumanoidRootPart"), Player.Character:FindFirstChild("Head"), Player.Character:FindFirstChild("Humanoid")

                    if Humanoid.Sit and not DefaultPlayerSettings[Player.Name] then continue end

                    if not DefaultPlayerSettings[Player.Name] then
                        DefaultPlayerSettings[Player.Name] = {}
                        DefaultPlayerSettings[Player.Name].HeadSettings = {}

                        DefaultPlayerSettings[Player.Name].HeadSettings.Size = Head.Size
                        DefaultPlayerSettings[Player.Name].HeadSettings.Color = Head.Color
                        DefaultPlayerSettings[Player.Name].HeadSettings.Transparency = Head.Transparency
                        DefaultPlayerSettings[Player.Name].HeadSettings.Material = Head.Material
                    end

                    if not Config.Hitbox_Expander.Enabled or Humanoid.Sit or Humanoid.Health == 0 or table.find(Library.Friendly_Players, Player.Name) then
                        Head.Massless = true
                        Head.CanCollide = true

                        for Index, Value in DefaultPlayerSettings[Player.Name].HeadSettings do
                            Head[Index] = Value
                        end

                        continue
                    end

                    if not Config.Hitbox_Expander.Enabled and not Humanoid.Sit then
                        Head.Massless = false
                        Head.CanCollide = true

                        for Index, Value in DefaultPlayerSettings[Player.Name].HeadSettings do
                            Head[Index] = Value
                        end

                        continue
                    end

                    if Config.Hitbox_Expander.SafeZoneCheck and Config.InsideSafezone(Player) then
                        Head.Massless = true
                        Head.CanCollide = true

                        for Index, Value in DefaultPlayerSettings[Player.Name].HeadSettings do
                            Head[Index] = Value
                        end

                        continue
                    end

                    if Config.Hitbox_Expander.Enabled and Humanoid.Health ~= 0 then
                        Head.Size = Vector3.new(Config.Hitbox_Expander.Multiplier, Config.Hitbox_Expander.Multiplier, Config.Hitbox_Expander.Multiplier)
                        Head.Transparency = Config.Hitbox_Expander.Transparency
                        Head.Material = Enum.Material[Config.Hitbox_Expander.Material]
                        Head.Color = Config.Hitbox_Expander.Color
                        Head.CanCollide = false
                        Head.Massless = true
                    end
                end
            end
        end))
    end

    for Index, Value in Players:GetPlayers() do
        if Value == LocalPlayer then continue end
        ConnectHitboxToPlayer(Value)
    end

    Players.PlayerAdded:Connect(function(Value)
        ConnectHitboxToPlayer(Value)
    end)

    local Tracer_Folder = Instance.new("Folder", Workspace)

    local Tracer_Delay = false;

    Config.RainbowTracer = LPH_NO_VIRTUALIZE(function(Tracer)
        task.spawn(function()
            while Tracer and Tracer.Parent do
                local Hue = tick() % 5 / 5
                local NextHue = (Hue + 0.1) % 1

                Tracer.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromHSV(Hue, 1, 1)),
                    ColorSequenceKeypoint.new(1, Color3.fromHSV(NextHue, 1, 1))
                })

                task.wait(0.05)
            end
        end)
    end)

    Config.MakeTracer = LPH_NO_VIRTUALIZE(function(EndPos)
        if Tracer_Delay then return end
        
        Tracer_Delay = true

        pcall(function()
            local StartPart = Instance.new("Part")
            StartPart.Anchored = true
            StartPart.Transparency = 1
            StartPart.Position = Config.Gun_Handle.GunMuzzlePoint.WorldCFrame.Position
            StartPart.Parent = Tracer_Folder
            StartPart.CanCollide = false
            StartPart.CanQuery = false
            StartPart.CanTouch = false

            local EndPart = Instance.new("Part")
            EndPart.Anchored = true
            EndPart.CanCollide = false
            EndPart.Transparency = 1
            EndPart.Position = EndPos -- (Config.Silent.Enabled == true and TargetPart~=nil) and TargetPart.Position or Mouse.Hit.Position
            EndPart.Parent = Tracer_Folder
            EndPart.CanQuery = false
            EndPart.CanTouch = false

            local Attachment0 = Instance.new("Attachment", StartPart)
            local Attachment1 = Instance.new("Attachment", EndPart)

            local Beam = Instance.new("Beam")
            Beam.Attachment0 = Attachment0
            Beam.Attachment1 = Attachment1
            Beam.FaceCamera = true
            Beam.LightEmission = 1
            Beam.Width0 = 0.1
            Beam.Width1 = 0.05
            Beam.Parent = StartPart

            if Config.Tracers.Rainbow then
                task.spawn(Config.RainbowTracer, Beam)
            else
                Beam.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Config.Tracers.StartColor),
                    ColorSequenceKeypoint.new(1, Config.Tracers.EndColor)
                })
            end

            task.delay(Config.Tracers.Duration, function()
                StartPart:Destroy()
                EndPart:Destroy()
            end)
        end)

        task.delay(0.01, function()
            Tracer_Delay = false;
        end)
    end)

    local Network_FireServer = require(LocalPlayer.PlayerScripts["Client.Initializer"].SharedModules.Network).FireServer

    local Old_Network_FireServer; Old_Network_FireServer = hookfunction(Network_FireServer, newcclosure(function(Self, ...)
        local Arguments = {...}
        local Name = Self.Name
        
        if Mouse.Target and Mouse.Target.Name == "Head" and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local Gun = Config.GetGun()

            if Gun then
                if Name == "InflictTarget" then
                    local l_Unit_0 = (LocalPlayer.Character.HumanoidRootPart.Position - Gun.Handle.GunFirePoint.WorldPosition).Unit

                    Arguments[3] = Mouse.Target
                    Arguments[4] = Mouse.Target.Position
                    Arguments[5] = l_Unit_0
                    Arguments[6] = Vector3.new(1.1542654037475586, 1.1710413694381714, 1.1542654037475586)
                end
            else
                return Old_Network_FireServer(Self, unpack(Arguments))
            end
        else
            return Old_Network_FireServer(Self, unpack(Arguments))
        end

        return Old_Network_FireServer(Self, unpack(Arguments))
    end))

    local OnRayHit_Sub2, aa, Get3DPosition
    local MainCastFireNoPhys_Table = {}

    for Index, Value in next, Garbage do
        if typeof(Value) == 'function' and not iscclosure(Value) then 
            local Function_Info = debug.getinfo(Value)
            if tostring(Function_Info.source):find("BulletVisualizerClient") and Function_Info.name == "OnRayHit_Sub2" and Function_Info.nups == 3 then
                OnRayHit_Sub2 = Value
            end

            if Function_Info.name == "aa" and Function_Info.source:find("GunScript_Local") then
                aa = Value
            end

            if Function_Info.name == "MainCastFireNoPhys" then
                if Function_Info.source:find("FastCast") then
                    table.insert(MainCastFireNoPhys_Table, Value)
                end
            end

            if Function_Info.name == "Get3DPosition" and Function_Info.source:find("GunScript_Local") then
                Get3DPosition = Value
            end
        end 
    end 

    LPH_JIT_MAX(function()
        local Old_Get3DPosition; Old_Get3DPosition = hookfunction(Get3DPosition, newcclosure(function(...)
            local Arguments = {...}

            if Config.Hitbox_Expander.Enabled and Mouse.Target and Mouse.Target.Name == "Head" then
                local Head = Mouse.Target

                local Result, OnScreen = Camera:WorldToScreenPoint(Head.Position);

                if OnScreen then
                    Arguments[1] = {X = Result.X, Y = Result.Y}
                end

                return Old_Get3DPosition(unpack(Arguments))
            elseif Config.Silent.Enabled and Target and Target.Character then
                local HumanoidRootPart = FindFirstChild(Target.Character, "HumanoidRootPart")

                local Result, OnScreen = Camera:WorldToScreenPoint(HumanoidRootPart.Position);

                if OnScreen then
                    Arguments[1] = {X = Result.X, Y = Result.Y}
                end
            else
                return Old_Get3DPosition(unpack(Arguments))
            end

            return Old_Get3DPosition(unpack(Arguments))
        end))
    end)()

    --[[LPH_JIT_MAX(function()
        for Index, MainCastFireNoPhys in MainCastFireNoPhys_Table do
            local Old_MainCastFireNoPhys; Old_MainCastFireNoPhys = hookfunction(MainCastFireNoPhys, newcclosure(function(...)
                local Arguments = {...}

                warn(Arguments[6][2], Arguments[6][2].Parent)

                if Arguments[6] and Arguments[6][2] ~= LocalPlayer.Character and (math.random(0, 100) <= Config.Silent.HitChance) then
                    warn(Arguments[6][2] == LocalPlayer.Character)
                    if Config.Silent.Enabled and (not Config.Silent.WallBang) and Target and Target.Character then
                        local TargetPart = FindFirstChild(Target.Character, Config.Silent.HitParts[1] and Config.Silent.HitParts[math.random(1, #Config.Silent.HitParts)] or "Head")

                        if TargetPart then
                            local Origin = Arguments[1];
                            local Direction = (TargetPart.Position - Origin).Unit * 9e17;

                            warn("MainCast Direction:", Direction)

                            Arguments[3] = Direction;
                        end

                        return Old_MainCastFireNoPhys(unpack(Arguments))
                    end
                else
                    return Old_MainCastFireNoPhys(unpack(Arguments))
                end

                return Old_MainCastFireNoPhys(unpack(Arguments))
            end))
        end
    end)()]]

    LPH_JIT_MAX(function()
        local Old_OnRayHit_Sub2; Old_OnRayHit_Sub2 = hookfunction(OnRayHit_Sub2, newcclosure(function(...)
            local Args = {...}

            if Args[1] and typeof(Args[1]) == "Instance" and Args[1].Parent then
                if Config.Tracers.Enabled then
                    task.spawn(Config.MakeTracer, Args[2])
                end

                if Config.Hit_Sounds_Settings.Enabled and Players:GetPlayerFromCharacter(Args[1].Parent) then                            
                    task.spawn(Config.PlaySound)
                end
            else
                return Old_OnRayHit_Sub2(unpack(Args))
            end

            return Old_OnRayHit_Sub2(unpack(Args))
        end))
    end)()

    local CustomExplosion = string.rep("A", 55) .. "Q3VzdG9tRXhwbG9zaW9u"
    local Auto = "SWvMILoJOrNpYpHcGjZvFSisRwRZlFPxuIwWTivPnnSfEWeKlNabBSCQXV0bw=="

    LPH_JIT_MAX(function()
        local Old_aa; Old_aa = hookfunction(aa, newcclosure(function(String)
            if String == Auto then
                String = CustomExplosion
            else
                return Old_aa(String)
            end

            return Old_aa(String)
        end))
    end)()
    
    local OldLightingSettings = {}

    OldLightingSettings["Brightness"] = Lighting.Brightness
    OldLightingSettings["ClockTime"] = Lighting.ClockTime
    OldLightingSettings["FogEnd"] = Lighting.FogEnd
    OldLightingSettings["GlobalShadows"] = Lighting.GlobalShadows
    OldLightingSettings["OutdoorAmbient"] = Lighting.OutdoorAmbient

    local Tint = Instance.new("ColorCorrectionEffect", Lighting)
    local OldSaturation = Lighting.ColorCorrection.Saturation
    local OldFogColor = Lighting.FogColor
    local Set_Fog, Set_Fov, Set_FullBright = true, true, true
    RunService:BindToRenderStep("World_Visuals", Enum.RenderPriority.Camera.Value+1, LPH_NO_VIRTUALIZE(function()
        if Config.WorldVisuals.StretchEnabled then
            Camera.CFrame = Camera.CFrame * CFrame.new(0, 0, 0, 1, 0, 0, 0, Config.WorldVisuals.StretchValue, 0, 0, 0, 1)
        end 

        if Config.WorldVisuals.FieldOfViewEnabled then
            Set_Fov = false
            Camera.FieldOfView = Config.WorldVisuals.FieldOfViewValue
        else
            if not Set_Fov then 
                Set_Fov = true
                Camera.FieldOfView = 70
            end
        end

        if Config.WorldVisuals.SaturationEnabled then
            Lighting.ColorCorrection.Saturation = Config.WorldVisuals.Saturation_Value
        else
            Lighting.ColorCorrection.Saturation = OldSaturation
        end

        if Config.WorldVisuals.Fullbright then
            Set_FullBright = false
            Lighting.Brightness = 2
            Lighting.ClockTime = 14
            Lighting.FogEnd = 100000
            Lighting.GlobalShadows = false
            Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
        else
            if not Set_FullBright then
                Set_FullBright = true
                
                Lighting.Brightness = OldLightingSettings.Brightness
                Lighting.FogEnd = OldLightingSettings.FogEnd
                Lighting.GlobalShadows = OldLightingSettings.GlobalShadows
                Lighting.OutdoorAmbient = OldLightingSettings.OutdoorAmbient
            end
        end

        if Config.WorldVisuals.AmbientEnabled then
            Tint.TintColor = Config.WorldVisuals.AmbientColor
        else
            Tint.TintColor = Color3.new(1,1,1)
        end

        if Config.WorldVisuals.FogColorEnabled then
            Set_Fog = false
            Lighting.FogColor = Config.WorldVisuals.FogColor
        else
            if not Set_Fog then
                Set_Fog = true

                Lighting.FogColor = OldFogColor
            end
        end
    end))

    TargetFetcherConnection = RunService.RenderStepped:Connect(GetSelectedTarget)

    FieldOfViewConnection = RunService.RenderStepped:Connect(LPH_NO_VIRTUALIZE(function()
        local ClientPosition = Device_Mobile and Center_Of_Screen or UserInputService:GetMouseLocation()

        FieldOfView.Position = ClientPosition
        FieldOfViewOutline.Position = FieldOfView.Position
        FieldOfView.Visible = Config.FieldOfView.Draw
        FieldOfViewOutline.Visible = FieldOfView.Visible
        FieldOfViewFill.Position = FieldOfView.Position
        FieldOfViewFill.Visible = FieldOfView.Visible and Config.FieldOfView.FilledDraw

        if Target and Target.Character and Target.Character:FindFirstChild("Head") then
            local PlayerPosition, OnScreen = Camera:WorldToViewportPoint(Target.Character:FindFirstChild("Head").Position)

            Snapline.Visible = (Config.FieldOfView.DrawSnapline and Target and OnScreen)
            SnaplineOutline.Visible = Snapline.Visible

            if (Snapline.Visible and OnScreen) then
                Snapline.From = ClientPosition
                SnaplineOutline.From = Snapline.From

                Snapline.To = Vector2.new(PlayerPosition.X, PlayerPosition.Y)
                SnaplineOutline.To = Snapline.To
            end;

            if Config.FieldOfView.HightlightTarget then
                Target_Highlight.Adornee = Target.Character
            else
                Target_Highlight.Adornee = nil
            end
        else
            Snapline.Visible = false
            SnaplineOutline.Visible = false
            Target_Highlight.Adornee = nil
        end
    end))

    --[[if Workspace:FindFirstChild(("Guns"):upper()) then
        for Index, Value in Workspace:FindFirstChild(("Guns"):upper()):GetChildren() do
            if not Value:IsA("Model") then continue end;
            local Price = Value:FindFirstChild("Price", true).Value;
            if Price == 0 then continue end;
            if Price > 100000 then continue end;
            if Price < 10 then continue end;
            
            if not table.find(Config.The_Bronx.Guns, Value.Name.." - $"..tostring(Price)) then
                table.insert(Config.The_Bronx.Guns, Value.Name.." - $"..tostring(Price));
            end;
        end
    end

    table.sort(Config.The_Bronx.Guns)]]

    if Workspace.Folders:FindFirstChild("PromptPurchases") then
        Gun_Locations = {}

        for i, v in ReplicatedStorage.Workspace:GetChildren() do
            if v.Name == "PromptPurchases" then
                for Index, Value in v:GetChildren() do
                    if Value:IsA("Model") and not Workspace.Folders:FindFirstChild("PromptPurchases"):FindFirstChild(Value.Name) then
                        Value.Parent = Workspace.Folders:FindFirstChild("PromptPurchases")
                    end
                end
            end
        end

        for i,v in Workspace.Folders:GetChildren() do
            if v.Name == "PromptPurchases" then
                for Index, Value in v:GetChildren() do
                    if not Value:FindFirstChild("Price") then continue end
                    if not Value:FindFirstChild("proxprompt") then continue end
                    if not Value:FindFirstChild("proxprompt"):FindFirstChildOfClass("ProximityPrompt") then continue end

                    local GunWithPrice = string.format("%s - $%s", tostring(Value), tostring(Value.Price.Value))
                    if not table.find(Config.South_Bronx.Guns, GunWithPrice) then
                        table.insert(Config.South_Bronx.Guns, GunWithPrice)

                        Gun_Locations[Value.Name] = Value.proxprompt.CFrame
                    end
                end
            end
        end

        table.sort(Config.South_Bronx.Guns)
    end

    local Gun_Module = require(LocalPlayer.PlayerScripts["Client.Initializer"].Modules.Tools.GunScript_Local)

    do -- Render Stepped Functions
        local Movement_Controller = require(LocalPlayer.PlayerScripts["Client.Initializer"].Modules.MovementController)

        RunService:BindToRenderStep("Render Stepped Functions", 0, LPH_NO_VIRTUALIZE(function()
            if Config.South_Bronx.InfiniteStamina then
                Movement_Controller.Stamina = 100
            end

            local Character = LocalPlayer.Character
            local Head = nil;

            if Character and Character:FindFirstChild("Head") then
                Head = Character.Head
            end

            --if Config.South_Bronx.HideName then
               if Head and Head:FindFirstChild("RankTag") then
                    if (not Character:FindFirstChild("Mask")) or (Character:FindFirstChild("Mask") and Character:FindFirstChild("Mask").Handle.Transparency == 1) then
                        Head:FindFirstChild("RankTag").MainFrame.NameLabel.Text = Config.South_Bronx.HideName and Config.South_Bronx.HideName_NameValue or LocalPlayer.Name
                    else
                        Head:FindFirstChild("RankTag").MainFrame.NameLabel.Text = Config.South_Bronx.HideName and Config.South_Bronx.HideName_NameValue or LocalPlayer.UserId
                    end
                end
            --end
        end))

        local string_match ; string_match = hookfunction(getrenv().string.match, function(...)
            if not checkcaller() and getcallingscript().Parent == nil then
                local Text = select(1, ...)

                if Text == LocalPlayer.Name or Text == Config.South_Bronx.HideName_NameValue or Text == tostring(LocalPlayer.UserId) then
                    return true
                else
                    return string_match(...)
                end
            else
                return string_match(...)
            end

            return string_match(...)
        end)

        ProximityPromptService.PromptButtonHoldBegan:Connect(LPH_NO_VIRTUALIZE(function(Prompt, Player)
            if Player == LocalPlayer and Prompt and Prompt.HoldDuration ~= 0 and Config.South_Bronx.InstantInteract then
                fireproximityprompt(Prompt)
            end
        end))

        task.spawn(LPH_NO_VIRTUALIZE(function()
            while true do
                task.wait(0)
                if Config.VehicleModifications.SpeedEnabled and UserInputService:IsKeyDown(Enum.KeyCode.W) then
                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                        if LocalPlayer.Character and typeof(LocalPlayer.Character) == "Instance" then
                            local Humanoid = LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid")
                            if Humanoid and typeof(Humanoid) == "Instance" then
                                local SeatPart = Humanoid.SeatPart
                                if SeatPart and typeof(SeatPart) == "Instance" and SeatPart:IsA("VehicleSeat") then
                                    SeatPart.AssemblyLinearVelocity *= Vector3.new(1 + Config.VehicleModifications.SpeedValue, 1, 1 + Config.VehicleModifications.SpeedValue)
                                end
                            end
                        end
                    end
                end
            end
        end))

        task.spawn(LPH_NO_VIRTUALIZE(function()
            while true do
                task.wait(0)
                if Config.VehicleModifications.BreakEnabled and UserInputService:IsKeyDown(Enum.KeyCode.S) then
                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                        if LocalPlayer.Character and typeof(LocalPlayer.Character) == "Instance" then
                            local Humanoid = LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid")
                            if Humanoid and typeof(Humanoid) == "Instance" then
                                local SeatPart = Humanoid.SeatPart
                                if SeatPart and typeof(SeatPart) == "Instance" and SeatPart:IsA("VehicleSeat") then
                                    SeatPart.AssemblyLinearVelocity *= Vector3.new(1 - Config.VehicleModifications.BreakValue, 1, 1 - Config.VehicleModifications.BreakValue)
                                end
                            end
                        end
                    end
                end
            end
        end))

        task.spawn(LPH_NO_VIRTUALIZE(function()
            while true do
                local Delta = RunService.Heartbeat:Wait()

                if not Config.South_Bronx.Speed then continue end

                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                    local Humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")

                    if Humanoid.MoveDirection.Magnitude > 0 then
                        local SpeedFactor = (Humanoid.WalkSpeed >= 10) and 1 or 0.54
                        LocalPlayer.Character:TranslateBy(
                            Humanoid.MoveDirection * Config.South_Bronx.SpeedValue 
                            * Delta * 10 * SpeedFactor
                        )
                    end
                end
            end
        end))

        task.spawn(LPH_NO_VIRTUALIZE(function()
            while true do
                task.wait(0)
                if Config.VehicleModifications.InstantStop and UserInputService:IsKeyDown(Config.VehicleModifications.InstantStopBind) then
                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                        if LocalPlayer.Character and typeof(LocalPlayer.Character) == "Instance" then
                            local Humanoid = LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid")
                            if Humanoid and typeof(Humanoid) == "Instance" then
                                local SeatPart = Humanoid.SeatPart
                                if SeatPart and typeof(SeatPart) == "Instance" and SeatPart:IsA("VehicleSeat") then
                                    SeatPart.AssemblyLinearVelocity *= Vector3.new(0, 0, 0)
                                    SeatPart.AssemblyAngularVelocity *= Vector3.new(0, 0, 0)
                                end
                            end
                        end
                    end
                end
            end
        end))
    end

    do -- Auto Farms
        local GetCuttingBoard, GetBowl, GetPot, GetHouse = LPH_NO_VIRTUALIZE(function()
            for Index, Value in Workspace.Map.Locations["The Laboratory"]["Cutting Boards"]:GetChildren() do
                local Prompt = Value:FindFirstChildWhichIsA("ProximityPrompt", true)

                if Prompt and Prompt.Enabled then
                    return Value
                end
            end
        end), LPH_NO_VIRTUALIZE(function()
            for Index, Value in Workspace.Map.Locations["The Laboratory"].Bowls:GetChildren() do
                local Prompt = Value:FindFirstChildWhichIsA("ProximityPrompt", true)

                if Prompt and Prompt.Enabled then
                    return Value
                end
            end
        end), LPH_NO_VIRTUALIZE(function()
            for Index, Value in Workspace.Map.Locations["The Laboratory"].Extra:GetChildren() do
                if Value.Name == "Table" then
                    Value.CanCollide = false
                end
            end

            for Index, Value in Workspace.Map.Locations["The Laboratory"].Pots:GetChildren() do
                local Prompt = Value:FindFirstChildWhichIsA("ProximityPrompt", true)

                if Prompt and Prompt.Enabled then
                    return Value
                end
            end
        end), LPH_NO_VIRTUALIZE(function()
            for Index, Value in Workspace.Map.APTS:GetChildren() do
                if Value:FindFirstChild("Board") then
                    local Name = Value:FindFirstChild("Board").name.SurfaceGui.TextLabel.Text

                    if Name == LocalPlayer.Name then
                        return Workspace.Map.Houses:FindFirstChild(Value.Name) or Workspace.Map.Locations.Apartments:FindFirstChild(Value.Name)
                    end
                end
            end

            return nil
        end)

        local ATMPositions = {
            ATM1 = CFrame.new(-30, 4, -300);
            ATM2 = CFrame.new(539, 4, -353);
            ATM3 = CFrame.new(497, 4, 403);
            ATM4 = CFrame.new(236, 4, -158);
            ATM5 = CFrame.new(525, -8, -92);
            ATM6 = CFrame.new(-450, 4, 370);
            ATM7 = CFrame.new(-266, 4, -209);
            ATM8 = CFrame.new(-11, 4, 231);
            ATM9 = CFrame.new(717, 4, 410);
            ATM10 = CFrame.new(-532, 3, -21);
            ATM11 = CFrame.new(-646, 4, 155);
            ATM12 = CFrame.new(698, 3, -241);
            ATM13 = CFrame.new(-315, 4, 142);
            ATM14 = CFrame.new(-378, 4, -365);
            ATM15 = CFrame.new(360, 4, -364);
            ATM16 = CFrame.new(870, 3, -346);
            ATM17 = CFrame.new(904, 3, -99);
            ATM18 = CFrame.new(1095, 3, 178);
            ATM19 = CFrame.new(1054, 4, 585);
            ATM20 = CFrame.new(895, 4, 142);
            ATM21 = CFrame.new(1021, 3, -229);
        };

        local PressKey = function(KeyCode, Duration)
            task.spawn(LPH_NO_VIRTUALIZE(function()
                Services.VirtualInputManager:SendKeyEvent(false, KeyCode, false, game)
                Services.VirtualInputManager:SendKeyEvent(true, KeyCode, false, game)
                task.wait(Duration)
                Services.VirtualInputManager:SendKeyEvent(false, KeyCode, false, game)
            end))
        end

        local boxfarm_thread

        Start_BoxFarm = function()
            boxfarm_thread = task.spawn(LPH_NO_VIRTUALIZE(function()
                while task.wait() do
                    if not LocalPlayer.Character then continue end
                    if not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then continue end
                    if not Config.South_Bronx.FarmingUtilities.BoxFarm then continue end

                    if (LocalPlayer.Character.HumanoidRootPart.Position - Vector3.new(-549, 3, -82)).Magnitude >= 150 then
                        Config:Teleport(CFrame.new(-549, 3, -82), true)
                    end

                    if not LocalPlayer.Backpack:FindFirstChild("Crate") and not LocalPlayer.Character:FindFirstChild("Crate") then
                        local DistanceFromBox = GetDistance(LocalPlayer.Character.HumanoidRootPart.Position, Vector3.new(-549, 3, -82))

                        local Tween = Services.TweenService:Create(LocalPlayer.Character.HumanoidRootPart, TweenInfo.new(GetTweenSpeed(DistanceFromBox), Enum.EasingStyle.Linear), {CFrame = CFrame.new(-549.1292724609375, 3.5371456146240234, -82.9239501953125)})

                        --PressKeyTween(Enum.KeyCode.W, Tween) ; PressKeyTween(Enum.KeyCode.LeftShift, Tween)

                        Tween:Play() ; Tween.Completed:Wait() ; Tween = nil

                        fireproximityprompt(Workspace.PlaceHere.Attachment.ProximityPrompt)

                        task.wait(1)

                        repeat task.wait() until LocalPlayer.Backpack:FindFirstChild("Crate")

                        LocalPlayer.Character.Humanoid:EquipTool(LocalPlayer.Backpack.Crate)

                        task.wait(1)
                    end

                    if not LocalPlayer.Character:FindFirstChild("Crate") then
                        LocalPlayer.Character.Humanoid:EquipTool(LocalPlayer.Backpack:FindFirstChild("Crate"))
                        task.wait(1)
                    end

                    if not LocalPlayer.Backpack:FindFirstChild("Crate") and not LocalPlayer.Character:FindFirstChild("Crate") then
                        continue
                    end

                    local DistanceFromTruck = GetDistance(LocalPlayer.Character.HumanoidRootPart.Position, Vector3.new(-401.04364013671875, 3.3621325492858887, -72.07713317871094))

                    local Tween = Services.TweenService:Create(LocalPlayer.Character.HumanoidRootPart, TweenInfo.new(GetTweenSpeed(DistanceFromTruck), Enum.EasingStyle.Linear), {CFrame = CFrame.new(-401.04364013671875, 3.3621325492858887, -72.07713317871094)})

                   -- PressKeyTween(Enum.KeyCode.W, Tween) ; PressKeyTween(Enum.KeyCode.LeftShift, Tween)

                    Tween:Play() ; Tween.Completed:Wait() ; Tween = nil

                    fireproximityprompt(Workspace.cratetruck2.Model.ClickBox.Attachment.ProximityPrompt)

                    task.wait(0.9)
                end
            end))
        end

        Stop_BoxFarm = LPH_NO_VIRTUALIZE(function()
            if not boxfarm_thread then return end

            if coroutine.status(boxfarm_thread) == "suspended" then
                task.cancel(boxfarm_thread)
            end
        end)

        task.spawn(LPH_NO_VIRTUALIZE(function()
            while task.wait(.01) do
                if not Config.South_Bronx.FarmingUtilities.CardFarm then continue end
                if not LocalPlayer.Character then continue end
                if not LocalPlayer.Character:FindFirstChild("Humanoid") then continue end

                if LocalPlayer.Character:FindFirstChild("Humanoid").Sit then
                LocalPlayer.Character:FindFirstChild("Humanoid").Sit = false ; LocalPlayer.Character:FindFirstChild("Humanoid").Jump = true
                end
            end
        end))

        task.spawn(LPH_NO_VIRTUALIZE(function()
            while task.wait(3) do
                if not Config.South_Bronx.FarmingUtilities.CardFarm then continue end
                if not LocalPlayer.Character then continue end
                if not LocalPlayer.Character:FindFirstChild("Humanoid") then continue end

                if LocalPlayer.Character:FindFirstChild("Humanoid").Sit then
                LocalPlayer.Character:FindFirstChild("Humanoid").Sit = false ; LocalPlayer.Character:FindFirstChild("Humanoid").Jump = true
                end

                for Index, Value in Workspace.Map.Locations["Community Bank"]:GetDescendants() do
                    pcall(function()
                        Value.CanCollide = false
                    end)
                end
            end
        end))

        task.spawn(LPH_NO_VIRTUALIZE(function()
            while task.wait(.1) do
                if not Config.South_Bronx.FarmingUtilities.MarshmallowFarm then continue end
                if not LocalPlayer.Character then continue end
                if not LocalPlayer.Character:FindFirstChild("Humanoid") then continue end

                if LocalPlayer.Character:FindFirstChild("Humanoid").Sit then
                LocalPlayer.Character:FindFirstChild("Humanoid").Sit = false ; LocalPlayer.Character:FindFirstChild("Humanoid").Jump = true
                end
            end
        end))
    
        task.spawn(LPH_JIT_MAX(function()
            while task.wait(.1) do
                if not Config.South_Bronx.FarmingUtilities.CardFarm then continue end
                
                pcall(function()
                    Workspace.Map.Decor:FindFirstChild("rail thing"):Destroy()
                end)

                if not Workspace.Map.Decor:FindFirstChild("rail thing") then
                    break
                end
            end
        end))

        local MarshmallowFarm_Thread

        local MarshMallowStep = "Water";

        local GetNumberOfItemsInBackpack = LPH_NO_VIRTUALIZE(function(Name)
            local Amount = 0

            for Index, Value in LocalPlayer.Backpack:GetChildren() do
                if Value.Name == Name then
                    Amount+=1
                end
            end

            return Amount
        end)

        Start_MarshmallowFarm = function()
            MarshmallowFarm_Thread = task.spawn(LPH_JIT_MAX(function()
                while wait(1) do
                    if not Config.South_Bronx.FarmingUtilities.MarshmallowFarm then continue end
                    
                    local Marshmellow_Increment = Config.South_Bronx.FarmingUtilities.MarshmallowIncrement

                    local Items = {"Gelatin", "Sugar Block Bag", "Water"}

                    Config.Teleport("Force", CFrame.new(510, 4, 602))
                    
                    for Index, Value in Items do
                        for _ = 1, Marshmellow_Increment do
                            if GetNumberOfItemsInBackpack(Value) == Marshmellow_Increment then
                                continue
                            end

                            local Added = false;
                            local Child_Added; Child_Added = LocalPlayer.Backpack.ChildAdded:Connect(function(Child)
                                if Child.Name == Value then
                                    Added = true
                                    Child_Added:Disconnect()
                                end
                            end)

                            repeat task.wait(.1)
                                ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("StorePurchase"):FireServer(Value)
                            until Added == true
                        end
                    end

                    task.wait(2.5)

                    local House = GetHouse();

                    if not House then
                        local HouseToBuy = Config.GetUnclaimedApartment()

                        if not HouseToBuy then repeat task.wait(1)
                            Library:Notification({
                                Name = "Valary.gg | Info",
                                Description = "House not found, waiting until a house is available. or consider hopping server.",
                                Duration = 1,
                            })
                        HouseToBuy = Config.GetUnclaimedApartment() until HouseToBuy end

                        Config:Teleport(HouseToBuy.Board.backboard.CFrame, true)

                        task.wait(1)

                        fireproximityprompt(HouseToBuy.Board:FindFirstChildWhichIsA("ProximityPrompt", true))

                        task.wait(1)

                        House = GetHouse()
                    end 

                    local Personal_Apartment = Config.GetPersonalApartment()

                    if Personal_Apartment.Door.Interact.Rotation ~= Vector3.new(0,90,0) and Personal_Apartment.Door.Interact.Rotation ~= Vector3.new(0,- 90,0) and Personal_Apartment.Door.Interact.Rotation ~= Vector3.new(180, 0,180) then
                        local Tween = Services.TweenService:Create(LocalPlayer.Character.HumanoidRootPart, TweenInfo.new(2, Enum.EasingStyle.Linear), {CFrame = Personal_Apartment.Door.Interact.CFrame})

                        Tween:Play() ; Tween.Completed:Wait() ; Tween = nil

                        task.wait(.5)

                        fireproximityprompt(Personal_Apartment.Door.Interact.Attachment.ProximityPrompt)

                        task.wait(1)
                    end

                    if Personal_Apartment.Door.DoorLock.Part.Rotation ~= Vector3.new(90,0,0) then
                        local Tween = Services.TweenService:Create(LocalPlayer.Character.HumanoidRootPart, TweenInfo.new(2, Enum.EasingStyle.Linear), {CFrame = Personal_Apartment.Door.Interact.CFrame})

                        Tween:Play() ; Tween.Completed:Wait() ; Tween = nil

                        task.wait(.5)

                        fireproximityprompt(Personal_Apartment.Door.DoorLock.Part.ProximityPrompt)

                        task.wait(.5)
                    end

                    local Interior = House:FindFirstChild("Interior") or House

                    for Index, Value in Interior:GetChildren() do
                        if Value.Name == "Floor" then
                            Value.CanCollide = false
                        end
                    end

                    local Pot = Interior["Cooking Pot"]

                    Config:Teleport(Pot.CFrame, true)

                    local tween_and_prompt = function(Prompt)
                        if not Console_Server then
                            if (House.Parent.Name == "Apartments") then
                                local Tween = Services.TweenService:Create(LocalPlayer.Character.HumanoidRootPart, TweenInfo.new(1, Enum.EasingStyle.Linear), {CFrame = Pot.CFrame + Vector3.new(0, 7, 0)})

                                Tween:Play() ; Tween.Completed:Wait() ; Tween = nil

                                task.wait(0.5)

                                fireproximityprompt(Prompt)

                                task.wait(2.5)

                                Tween = Services.TweenService:Create(LocalPlayer.Character.HumanoidRootPart, TweenInfo.new(1, Enum.EasingStyle.Linear), {CFrame = Pot.CFrame + Vector3.new(0, 16, 0)})

                                Tween:Play() ; Tween.Completed:Wait() ; Tween = nil
                            else
                                fireproximityprompt(Prompt)
                            end
                        else
                            if (House.Parent.Name == "Apartments") then
                                Config:Teleport(Pot.CFrame + Vector3.new(0, 7, 0))

                                task.wait(1.5)

                                fireproximityprompt(Prompt)

                                task.wait(2.5)

                                Config:Teleport(CFrame.new(-746 + math.random(-25, 25), 53, 588 + math.random(-25, 25)))
                            else
                                Config:Teleport(Pot.CFrame + Vector3.new(0, 7, 0))

                                task.wait(1.5)

                                fireproximityprompt(Prompt)

                                task.wait(2.5)

                                Config:Teleport(CFrame.new(-746 + math.random(-25, 25), 53, 588 + math.random(-25, 25)))
                            end    
                        end
                    end

                    if not (House.Parent.Name == "Apartments") then
                        local Tween = Services.TweenService:Create(LocalPlayer.Character.HumanoidRootPart, TweenInfo.new(1, Enum.EasingStyle.Linear), {CFrame = Pot.CFrame - Vector3.new(0, 7, 0)})

                        Tween:Play() ; Tween.Completed:Wait() ; Tween = nil
                    end

                    --[[LocalPlayer.Character:FindFirstChild("Humanoid"):UnequipTools()

                    task.wait();

                    local Gun = Config.GetGun()

                    if Gun then
                        if Gun.Parent == LocalPlayer.Backpack then
                            LocalPlayer.Character:FindFirstChild("Humanoid"):EquipTool(Gun)

                            repeat RunService.Stepped:Wait() until Gun.Parent == LocalPlayer.Character
                        end

                        LocalPlayer.Character:FindFirstChild("Humanoid"):UnequipTools()

                        task.wait();
                    end]]
                    
                    if MarshMallowStep == "Sugar Block Bag" then
                        repeat task.wait() until Pot.Timer.TextLabel.Text == "0"
                        if not LocalPlayer.Character:FindFirstChild("Sugar Block Bag") then
                            LocalPlayer.Character.Humanoid:EquipTool(LocalPlayer.Backpack:FindFirstChild("Sugar Block Bag"))
                        end

                        task.wait(1)

                        --LocalPlayer.Character.HumanoidRootPart.CFrame = Pot.CFrame

                        --task.wait(.5)

                        tween_and_prompt(Pot.Attachment.ProximityPrompt)

                        if not (House.Parent.Name == "Apartments") then
                            task.wait(2.5)
                        end

                        --LocalPlayer.Character.HumanoidRootPart.CFrame = Pot.CFrame - Vector3.new(0, 7, 0)

                        LocalPlayer.Character.Humanoid:UnequipTools()
                        MarshMallowStep = "Gelatin"
                    end

                    if MarshMallowStep == "Gelatin" then
                        LocalPlayer.Character.Humanoid:UnequipTools()

                        task.wait(1)

                        if not LocalPlayer.Character:FindFirstChild("Gelatin") then
                            LocalPlayer.Character.Humanoid:EquipTool(LocalPlayer.Backpack:FindFirstChild("Gelatin"))
                        end

                        --LocalPlayer.Character.HumanoidRootPart.CFrame = Pot.CFrame

                        --task.wait(.5)

                        tween_and_prompt(Pot.Attachment.ProximityPrompt)

                        if not (House.Parent.Name == "Apartments") then
                            task.wait(2.5)
                        end

                        --LocalPlayer.Character.HumanoidRootPart.CFrame = Pot.CFrame - Vector3.new(0, 7, 0)

                        MarshMallowStep = "Collect"
                    end

                    if MarshMallowStep == "Collect" then
                        repeat task.wait() until Pot.Timer.TextLabel.Text == "0"

                        if not LocalPlayer.Character:FindFirstChild("Empty Bag") then
                            LocalPlayer.Character.Humanoid:EquipTool(LocalPlayer.Backpack:FindFirstChild("Empty Bag"))
                        end

                        --LocalPlayer.Character.HumanoidRootPart.CFrame = Pot.CFrame

                        task.wait(1)

                        tween_and_prompt(Pot.Attachment.ProximityPrompt)

                        if not (House.Parent.Name == "Apartments") then
                            task.wait(2.5)
                        end
                        --LocalPlayer.Character.HumanoidRootPart.CFrame = Pot.CFrame - Vector3.new(0, 7, 0)

                        LocalPlayer.Character.Humanoid:UnequipTools()
                        
                        MarshMallowStep = "Water"
                    end

                    if MarshMallowStep ~= "Sell" then
                        local Water, Gel, Sug = {}, {}, {}

                        for _, Value in ipairs(LocalPlayer.Backpack:GetChildren()) do
                            if Value.Name == "Sugar Block Bag" then
                                table.insert(Sug, Value)
                            elseif Value.Name == "Gelatin" then
                                table.insert(Gel, Value)
                            elseif Value.Name == "Water" then
                                table.insert(Water, Value)
                            end
                        end

                        local highestCommon = math.min(#Water, #Gel, #Sug)

                        for _ = 1, highestCommon do
                            if MarshMallowStep == "Water" then
                                if not LocalPlayer.Character:FindFirstChild("Water") then
                                    LocalPlayer.Character.Humanoid:EquipTool(LocalPlayer.Backpack:FindFirstChild("Water"))
                                end

                                --LocalPlayer.Character.HumanoidRootPart.CFrame = Pot.CFrame

                                task.wait(1)

                                tween_and_prompt(Pot.Attachment.ProximityPrompt)

                                if not (House.Parent.Name == "Apartments") then
                                    task.wait(2.5)
                                end     

                                MarshMallowStep = "Sugar Block Bag"
                            end

                            if MarshMallowStep == "Sugar Block Bag" then
                                repeat task.wait() until Pot.Timer.TextLabel.Text == "0"

                                if not LocalPlayer.Character:FindFirstChild("Sugar Block Bag") then
                                    LocalPlayer.Character.Humanoid:EquipTool(LocalPlayer.Backpack:FindFirstChild("Sugar Block Bag"))
                                end

                                task.wait(1)

                                tween_and_prompt(Pot.Attachment.ProximityPrompt)

                                if not (House.Parent.Name == "Apartments") then
                                    task.wait(2.5)
                                end

                                LocalPlayer.Character.Humanoid:UnequipTools()
                                MarshMallowStep = "Gelatin"
                            end

                            if MarshMallowStep == "Gelatin" then
                                repeat task.wait() until Pot.Timer.TextLabel.Text == "0"

                                local HumanoidConnection; HumanoidConnection = LocalPlayer.Character.Humanoid.Died:Connect(function()
                                    MarshMallowStep = "Water"
                                    HumanoidConnection:Disconnect()
                                end)

                                LocalPlayer.Character.Humanoid:UnequipTools()

                                task.wait(1)

                                if not LocalPlayer.Character:FindFirstChild("Gelatin") then
                                    LocalPlayer.Character.Humanoid:EquipTool(LocalPlayer.Backpack:FindFirstChild("Gelatin"))
                                end

                                tween_and_prompt(Pot.Attachment.ProximityPrompt)

                                if not (House.Parent.Name == "Apartments") then
                                    task.wait(2.5)
                                end

                                MarshMallowStep = "Collect"

                                HumanoidConnection:Disconnect()
                            end

                            if MarshMallowStep == "Collect" then
                                repeat task.wait() until Pot.Timer.TextLabel.Text == "0"

                                local HumanoidConnection; HumanoidConnection = LocalPlayer.Character.Humanoid.Died:Connect(function()
                                    MarshMallowStep = "Water"
                                    HumanoidConnection:Disconnect()
                                end)
                                
                                if not LocalPlayer.Character:FindFirstChild("Empty Bag") then
                                    LocalPlayer.Character.Humanoid:EquipTool(LocalPlayer.Backpack:FindFirstChild("Empty Bag"))
                                end

                                task.wait(1)

                                tween_and_prompt(Pot.Attachment.ProximityPrompt)

                                task.wait(1)

                                LocalPlayer.Character.Humanoid:UnequipTools()
                                
                                if _ == Marshmellow_Increment --[[MarshmallowIncrement]] then
                                    MarshMallowStep = "Sell"
                                else
                                    MarshMallowStep = "Water"
                                end

                                HumanoidConnection:Disconnect()
                            end
                        end
                    end

                    if MarshMallowStep == "Sell" then
                        Config:Teleport(CFrame.new(510, 4, 602), true, true)

                        repeat task.wait() until Workspace.Folders.NPCs:FindFirstChild('Lamont Bell')

                        task.wait(1)

                        local Tween = Services.TweenService:Create(LocalPlayer.Character.HumanoidRootPart, TweenInfo.new(2.5, Enum.EasingStyle.Linear), {CFrame = CFrame.new(511, 4, 598)})

                        Tween:Play() ; Tween.Completed:Wait() ; Tween = nil

                        for Index, Value in LocalPlayer.Backpack:GetChildren() do
                            if Value:IsA("Tool") and Value.Name:find("Marshmallow") then
                                LocalPlayer.Character.Humanoid:EquipTool(Value)
                                fireproximityprompt(Workspace.Folders.NPCs["Lamont Bell"].UpperTorso.ProximityPrompt)
                                Config.South_Bronx.Farm_Data.Marshmellows_Sold+=1

                                task.wait(0.25)
                            end
                        end

                        MarshMallowStep = "Water"
                    end
                end
            end))
        end

        Stop_MarshmallowFarm = LPH_NO_VIRTUALIZE(function()
            if not MarshmallowFarm_Thread then return end
            if coroutine.status(MarshmallowFarm_Thread) == "suspended" then
                task.cancel(MarshmallowFarm_Thread)
            end
            Teleport_Debounce = false
            Config.DeleteHiddenScreen()
        end)

        local Last_TaskUpdate_Text

        task.spawn(LPH_NO_VIRTUALIZE(function()
            while task.wait(.1) do
                local Main = LocalPlayer.PlayerGui:FindFirstChild("Main")
                
                if Main then
                    local TaskUpdate = Main:FindFirstChild("TaskUpdate") 

                    if TaskUpdate then
                        if TaskUpdate:FindFirstChild("TextLabel") then
                            Last_TaskUpdate_Text = TaskUpdate:FindFirstChild("TextLabel").Text
                        end
                    end
                end
            end
        end))

        LocalPlayer.Character.Humanoid.Died:Connect(function()
            if Last_TaskUpdate_Text == "Let the solution cook for 45 seconds." or Last_TaskUpdate_Text == "Bag the solution into the empty bag." then
                Stop_MarshmallowFarm()

                if not Config.Rejoiner.Enabled then
                    LocalPlayer:Kick("Valary.gg | Died during empty bag step, aborting autofarm.")
                else
                    local src = [[
                        repeat wait() until game:IsLoaded()

                        if game.PlaceId == 13643807539 or game.PlaceId == 14413475235 or game.PlaceId == 15124180230 then
                            getgenv().rejoined_and_farming = true
                            
                            script_key = readfile('valarygg_key.txt')

                            loadstring(game:HttpGet("https://api.luarmor.net/files/v3/loaders/da9311f3c94e11c2dccd036885309e28.lua"))()
                        end
                    ]]

                    writefile('valary_gg_sb_rejoiner_loadstring_DONT_EDIT.txt', src)

                    queue_on_teleport([[
                        queue_on_teleport("loadstring(readfile('valary_gg_sb_rejoiner_loadstring_DONT_EDIT.txt'))()")
                    ]])

                    if Console_Server then
                        queue_on_teleport([[
                            __namecall = nil
                            __namecall = hookmetamethod(game, '__namecall', newcclosure(function(Self, ...)
                                if getnamecallmethod() == 'IsTenFootInterface' then
                                    return true
                                end

                                return __namecall(Self, ...)
                            end))
                        ]])
                    end 

                    game:GetService("TeleportService"):Teleport(10179538382)
                end
            end
        end)

        LocalPlayer.CharacterAdded:Connect(function(Character)
            Character:WaitForChild("Humanoid").Died:Connect(function()
                if Last_TaskUpdate_Text == "Let the solution cook for 45 seconds." or Last_TaskUpdate_Text == "Bag the solution into the empty bag." then
                    Stop_MarshmallowFarm()

                    if not Config.Rejoiner.Enabled then
                        LocalPlayer:Kick("Valary.gg | Died during empty bag step, aborting autofarm.")
                    else
                        local src = [[
                            repeat wait() until game:IsLoaded()

                            if game.PlaceId == 13643807539 or game.PlaceId == 14413475235 or game.PlaceId == 15124180230 then
                                getgenv().rejoined_and_farming = true
                                
                                script_key = readfile('valarygg_key.txt')

                                loadstring(game:HttpGet("https://api.luarmor.net/files/v3/loaders/da9311f3c94e11c2dccd036885309e28.lua"))()
                            end
                        ]]

                        writefile('valary_gg_sb_rejoiner_loadstring_DONT_EDIT.txt', src)

                        queue_on_teleport([[
                            queue_on_teleport("loadstring(readfile('valary_gg_sb_rejoiner_loadstring_DONT_EDIT.txt'))()")
                        ]])

                        if Console_Server then
                            queue_on_teleport([[
                                __namecall = nil
                                __namecall = hookmetamethod(game, '__namecall', newcclosure(function(Self, ...)
                                    if getnamecallmethod() == 'IsTenFootInterface' then
                                        return true
                                    end

                                    return __namecall(Self, ...)
                                end))
                            ]])
                        end 

                        game:GetService("TeleportService"):Teleport(10179538382)
                    end
                end
            end)
        end)

        local ChipFarm_Thread

        Start_ChipFarm = function()
            ChipFarm_Thread = task.spawn(LPH_JIT_MAX(function()
                while task.wait(1) do
                    if not Config.South_Bronx.FarmingUtilities.ChipFarm then continue end

                    if not LocalPlayer.Backpack:FindFirstChild("Flour") or not LocalPlayer.Backpack:FindFirstChild("Potato") then
                        Config.Teleport("Force", CFrame.new(-773, 4, -197))
                                    
                        if not LocalPlayer.Backpack:FindFirstChild("Flour") then
                            repeat
                            ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("StorePurchase"):FireServer("Flour")
                            task.wait(.1)
                            until LocalPlayer.Backpack:FindFirstChild("Flour")
                        end
                
                        if not LocalPlayer.Backpack:FindFirstChild("Potato") then
                            repeat
                            ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("StorePurchase"):FireServer("Potato")
                            task.wait(.1)
                            until LocalPlayer.Backpack:FindFirstChild("Potato")
                        end
                    end
                
                    repeat task.wait() until LocalPlayer.Backpack:FindFirstChild("Potato") and LocalPlayer.Backpack:FindFirstChild("Flour")
                                
                    Config.Teleport("Force", CFrame.new(-479, 4, -437))

                    task.wait(3)
                                    
                    local Tween = Services.TweenService:Create(LocalPlayer.Character.HumanoidRootPart, TweenInfo.new(2.5, Enum.EasingStyle.Linear), {CFrame = CFrame.new(-479, 4, -437)})

                    Tween:Play() ; Tween.Completed:Wait() ; Tween = nil
                
                    xpcall(function()
                        replicatesignal(Workspace.Map.Locations["The Laboratory"].Prompts.Clipboard.ProximityPrompt.TriggeredActionReplicated, LocalPlayer)
                    end, function()
                        Workspace.Map.Locations["The Laboratory"].Prompts.Clipboard.ProximityPrompt:InputHoldBegin()

                        task.wait(Workspace.Map.Locations["The Laboratory"].Prompts.Clipboard.ProximityPrompt.HoldDuration)

                        Workspace.Map.Locations["The Laboratory"].Prompts.Clipboard.ProximityPrompt:InputHoldEnd()
                    end)
                
                    task.wait(2)
                
                    local CookingBoard = GetCuttingBoard()

                    local Tween = Services.TweenService:Create(LocalPlayer.Character.HumanoidRootPart, TweenInfo.new(7.5, Enum.EasingStyle.Linear), {CFrame = CookingBoard.Part.CFrame})

                    Tween:Play() ; Tween.Completed:Wait() ; Tween = nil
                
                    if not LocalPlayer.Character:FindFirstChild("Potato") then
                        LocalPlayer.Character.Humanoid:EquipTool(LocalPlayer.Backpack:FindFirstChild("Potato"))
                    end
                
                    task.wait(2)
                                
                    xpcall(function()
                        replicatesignal(CookingBoard:FindFirstChildWhichIsA("ProximityPrompt", true).TriggeredActionReplicated, LocalPlayer)
                    end, function()
                        CookingBoard:FindFirstChildWhichIsA("ProximityPrompt", true):InputHoldBegin()

                        task.wait(CookingBoard:FindFirstChildWhichIsA("ProximityPrompt", true).HoldDuration)

                        CookingBoard:FindFirstChildWhichIsA("ProximityPrompt", true):InputHoldEnd()
                    end)

                    task.wait(3)

                    local Tween = Services.TweenService:Create(LocalPlayer.Character.HumanoidRootPart, TweenInfo.new(2.5, Enum.EasingStyle.Linear), {CFrame = CFrame.new(-463, 4, -473)})

                    Tween:Play() ; Tween.Completed:Wait() ; Tween = nil
                
                    xpcall(function()
                        replicatesignal(Workspace.Map.Locations["The Laboratory"].Prompts["Plastic Bag"].Attachment.ProximityPrompt.TriggeredActionReplicated, LocalPlayer)
                    end, function()
                        Workspace.Map.Locations["The Laboratory"].Prompts["Plastic Bag"].Attachment.ProximityPrompt:InputHoldBegin()

                        task.wait(Workspace.Map.Locations["The Laboratory"].Prompts["Plastic Bag"].Attachment.ProximityPrompt.HoldDuration)

                        Workspace.Map.Locations["The Laboratory"].Prompts["Plastic Bag"].Attachment.ProximityPrompt:InputHoldEnd()
                    end)
                
                    task.wait(1.5)

                    local Tween = Services.TweenService:Create(LocalPlayer.Character.HumanoidRootPart, TweenInfo.new(4, Enum.EasingStyle.Linear), {CFrame = CFrame.new(-466, 4, -522)})

                    Tween:Play() ; Tween.Completed:Wait() ; Tween = nil
                
                    local Tween = Services.TweenService:Create(LocalPlayer.Character.HumanoidRootPart, TweenInfo.new(7.5, Enum.EasingStyle.Linear), {CFrame = CFrame.new(-466, 4, -474)})

                    Tween:Play() ; Tween.Completed:Wait() ; Tween = nil
                
                    local Bowl = GetBowl()

                    local Tween = Services.TweenService:Create(LocalPlayer.Character.HumanoidRootPart, TweenInfo.new(5, Enum.EasingStyle.Linear), {CFrame = Bowl.CamPart.CFrame})

                    Tween:Play() ; Tween.Completed:Wait() ; Tween = nil
                
                    if not LocalPlayer.Character:FindFirstChild("Flour") then
                        LocalPlayer.Character.Humanoid:EquipTool(LocalPlayer.Backpack:FindFirstChild("Flour"))
                    end
                
                    task.wait(1)

                    xpcall(function()
                        replicatesignal(Bowl.ProximityPrompt.TriggeredActionReplicated, LocalPlayer)
                    end, function()
                        Bowl.ProximityPrompt:InputHoldBegin()

                        task.wait(Bowl.ProximityPrompt.HoldDuration)

                        Bowl.ProximityPrompt:InputHoldEnd()
                    end)
                                
                    task.wait(5)
                
                    local Tween = Services.TweenService:Create(LocalPlayer.Character.HumanoidRootPart, TweenInfo.new(2.5, Enum.EasingStyle.Linear), {CFrame = CFrame.new(-466, 4, -518)})

                    Tween:Play() ; Tween.Completed:Wait() ; Tween = nil

                    local Tween = Services.TweenService:Create(LocalPlayer.Character.HumanoidRootPart, TweenInfo.new(7.5, Enum.EasingStyle.Linear), {CFrame = CFrame.new(-467, 4, -470)})

                    Tween:Play() ; Tween.Completed:Wait() ; Tween = nil
                
                    local Pot = GetPot()
                
                    LocalPlayer.Character.Humanoid:MoveTo(Pot.Position)

                    LocalPlayer.Character.Humanoid.MoveToFinished:Wait()

                    task.wait(1)
                
                    xpcall(function()
                        replicatesignal(Pot.ProximityPrompt.TriggeredActionReplicated, LocalPlayer)
                    end, function()
                        Pot.ProximityPrompt:InputHoldBegin()

                        task.wait(Pot.ProximityPrompt.HoldDuration)

                        Pot.ProximityPrompt:InputHoldEnd()
                    end)

                    task.wait(70)
                    
                    local Hobo = Config.GetHobo()

                    if not Hobo then
                        repeat wait(1)
                            Hobo = Config.GetHobo()
                        until Hobo ~= nil
                    end 

                    Config.Teleport("Force", Pot.CFrame)

                    xpcall(function()
                        replicatesignal(Pot.ProximityPrompt.TriggeredActionReplicated, LocalPlayer)
                    end, function()
                        Pot.ProximityPrompt:InputHoldBegin()

                        task.wait(Pot.ProximityPrompt.HoldDuration)

                        Pot.ProximityPrompt:InputHoldEnd()
                    end)
                
                    repeat task.wait() until LocalPlayer.Backpack:FindFirstChild("Potato Chips")

                    Config.Teleport("Force", Workspace.Folders.NPCs:FindFirstChild("Poor Guy").Head.CFrame)

                    task.wait(0.1)

                    fireproximityprompt(Workspace.Folders.NPCs["Poor Guy"].UpperTorso.ProximityPrompt)

                    task.wait(0.1)

                    Config.Teleport("Force", Hobo.Head.CFrame)

                    task.wait(1)

                    PressKey(Enum.KeyCode.W, .25) task.wait(.25)
                    PressKey(Enum.KeyCode.S, .25) task.wait(.25)
                    PressKey(Enum.KeyCode.A, .25) task.wait(.25)
                    PressKey(Enum.KeyCode.D, .25) task.wait(.25)
                        
                    task.wait(1.25)

                    if not LocalPlayer.Character:FindFirstChild("Hot Chips") then
                        LocalPlayer.Character.Humanoid:EquipTool(LocalPlayer.Backpack:FindFirstChild("Hot Chips"))
                    end
    
                    --[[LocalPlayer.Character.Humanoid:MoveTo(Hobo:FindFirstChild("RightLowerLeg", true).Position)

                    LocalPlayer.Character.Humanoid.MoveToFinished:Wait()]]

                    task.wait(4)
                
                    local prompt = Hobo:FindFirstChildWhichIsA("ProximityPrompt", true)

                    fireproximityprompt(prompt)

                    Config.South_Bronx.Farm_Data.Chips_Sold+=1
                end
            end))
        end
        
        Stop_ChipFarm = LPH_NO_VIRTUALIZE(function()
            if not ChipFarm_Thread then return end
            if coroutine.status(ChipFarm_Thread) == "suspended" then
                task.cancel(ChipFarm_Thread)
            end
            Teleport_Debounce = false
            Config.DeleteHiddenScreen()
        end)

        Config.TriggerButton = LPH_JIT_MAX(function(Self, Button, Event)
            if not Device_Mobile then
                if not Event then
                    Event = "MouseButton1Down"
                end

                replicatesignal(Button[Event], 1, 1)
            else
                replicatesignal(Button.TouchTap)
            end
        end)

        local CardFarm_Thread

        Start_CardFarm = function()
            CardFarm_Thread = task.spawn(LPH_JIT_MAX(function()
                while task.wait(1) do
                    if not Config.South_Bronx.FarmingUtilities.CardFarm then continue end
                    if not LocalPlayer.Character then continue end

                    --if not LocalPlayer.Backpack:FindFirstChild("Fake ID") and not LocalPlayer.Character:FindFirstChild("Fake ID") and not LocalPlayer.Backpack:FindFirstChild("Card") and not LocalPlayer.Character:FindFirstChild("Card") then
                        Config.Teleport("Force", CFrame.new(219, 4, -332))
                        
                        repeat task.wait(0.1) fireproximityprompt(Workspace.Folders.NPCs.FakeIDSeller.UpperTorso.Attachment:FindFirstChild("ProximityPrompt")) until LocalPlayer.Backpack:FindFirstChild("Fake ID") or LocalPlayer.Character:FindFirstChild("Fake ID")
                    
                        task.wait(1.25)
                    --end

                    --if not LocalPlayer.Backpack:FindFirstChild("Card") and not LocalPlayer.Character:FindFirstChild("Card") then
                        Config.Teleport("Force", CFrame.new(-49, 4, -321), true)
                        
                        task.wait(3)

                        if not LocalPlayer.Backpack:FindFirstChild("Fake ID") and not LocalPlayer.Character:FindFirstChild("Fake ID") then
                            continue
                        end
            
                        local Application_Successful = false
                        local Old ; Old = LocalPlayer.PlayerGui.Main.BasicNotification:GetPropertyChangedSignal("Text"):Connect(function()
                            if not LocalPlayer.PlayerGui.Main.BasicNotification.Text:find("application") then return end
            
                            if LocalPlayer.PlayerGui.Main.BasicNotification.Text == "Your application was successful. Please allow 30 seconds for the bank to prepare your card." then
                                Application_Successful = true
                            else
                                Application_Successful = false
                            end
                        end)

                        repeat task.wait() 
                            if LocalPlayer.Backpack:FindFirstChild("Fake ID") then
                                pcall(function()
                                    LocalPlayer.Character.Humanoid:EquipTool(LocalPlayer.Backpack:FindFirstChild("Fake ID"))
                                end)
                            end

                        until LocalPlayer.Character:FindFirstChild("Fake ID")

                        repeat fireproximityprompt(Workspace.Folders.NPCs:FindFirstChild("Bank Teller").UpperTorso.Attachment:FindFirstChild("ProximityPrompt")) task.wait(1) until not LocalPlayer.Character:FindFirstChild("Fake ID")
        
                        task.wait(1)
        
                        LocalPlayer.PlayerGui.Main.BasicNotification:GetPropertyChangedSignal("Text"):Wait()
        
                        task.delay(3, function()
                            Old:Disconnect()
                        end)
        
                        task.wait(.5)
        
                        if Application_Successful == false then
                            continue
                        end
        
                        task.wait(31)
                    --end

                    local ATM;
                        
                    for Index, Value in Workspace.Map.ATMS:GetChildren() do
                        if Value.ATMScreen.Transparency == 0 then
                            ATM = Value
                            break
                        end
                    end
    
                    if ATM == nil then
                        repeat task.wait(1)
    
                        for Index, Value in Workspace.Map.ATMS:GetChildren() do
                            if Value.ATMScreen.Transparency == 0 then
                                ATM = Value
                                break
                            end
                        end
                        
                        until ATM ~= nil
                    end

                    Config.Teleport("Force", CFrame.new(-43, 4, -332))

                    repeat task.wait() fireproximityprompt(Workspace.CardPickup.Attachment.ProximityPrompt) until LocalPlayer.Backpack:FindFirstChild("Card") or LocalPlayer.Character:FindFirstChild("Card")
        
                    local Teleport_Status = Config.Teleport("Force", ATMPositions[tostring(ATM)])
        
                    LocalPlayer.Character.Humanoid:EquipTool(LocalPlayer.Backpack:FindFirstChild("Card"))
                    
                    --PressKey(Enum.KeyCode.LeftShift, .25) task.wait(.25)
                    PressKey(Enum.KeyCode.W, .1) task.wait(.251)
                    PressKey(Enum.KeyCode.S, .1) task.wait(.25)
                    PressKey(Enum.KeyCode.A, .1) task.wait(.25)
                    PressKey(Enum.KeyCode.D, .1) task.wait(.25)
                    
                    task.wait(0.5)
    
                    LocalPlayer.Character.Humanoid:MoveTo(ATM.Position)

                    LocalPlayer.Character.Humanoid.MoveToFinished:Wait()
    
                    fireproximityprompt(ATM.Attachment.ProximityPrompt)
                    
                    if ATM.ATMScreen.Transparency == 1 then
                        continue
                    end
    
                    repeat RunService.RenderStepped:Wait() until LocalPlayer.PlayerGui:FindFirstChild("ATM")

                    Config:TriggerButton(LocalPlayer.PlayerGui.ATM.Frame.Swipe, "MouseButton1Click")

                    Config.South_Bronx.Farm_Data.Cards_Swiped+=1
    
                    task.wait(1)
                end
            end))
        end

        Stop_CardFarm = LPH_NO_VIRTUALIZE(function()
            if not CardFarm_Thread then return end
            if coroutine.status(CardFarm_Thread) == "suspended" then
                task.cancel(CardFarm_Thread)
            end
            Teleport_Debounce = false
            Config.DeleteHiddenScreen()
        end)

        local Humanoid = LocalPlayer.Character:WaitForChild("Humanoid")

        Death_CFrame = nil;

        Humanoid.Died:Connect(function()
            Teleport_Debounce = false

            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                Death_CFrame = LocalPlayer.Character:WaitForChild("HumanoidRootPart").CFrame
            end

            if Config.South_Bronx.FarmingUtilities.CardFarm then
                Stop_CardFarm()
            end

            if Config.South_Bronx.FarmingUtilities.BoxFarm then
                Stop_BoxFarm()
            end

            if Config.South_Bronx.FarmingUtilities.ChipFarm then
                Stop_ChipFarm()
            end 

            if Config.South_Bronx.FarmingUtilities.MarshmallowFarm then
                Stop_MarshmallowFarm()
            end
        end)

        Buy_Gun = LPH_JIT_MAX(function()
            if not Config.South_Bronx.FarmingUtilities.AutoBuyGun then return end

            local Success, Error = pcall(function()
                local Prompt_CFrame, Old_CFrame = Gun_Locations['Glock 43'], LocalPlayer.Character.HumanoidRootPart.CFrame

                local ChildAdded_Check; ChildAdded_Check = LocalPlayer.Backpack.ChildAdded:Connect(function(Child)
                    if Child.Name == 'Glock 43' then
                        ItemReceieved = true
                        DidntBuy = false

                        ChildAdded_Check:Disconnect();
                    end
                end)

                Config:Teleport(Prompt_CFrame, true)

                task.wait(2.5)

                task.delay(3, function()
                    if not ItemReceieved then
                        ItemReceieved = true
                        DidntBuy = true
                    end
                end)

                fireproximityprompt(Workspace.Folders:FindFirstChild("PromptPurchases")['Glock 43'].proxprompt:FindFirstChildOfClass("ProximityPrompt"))

                repeat RunService.RenderStepped:Wait() until ItemReceieved == true

                task.wait(0.5)
            end)

            if Error then
                warn("AUTO-BUY-GUN ERROR:", Error)
            end
        end)
                
        local Buy_Mask = LPH_JIT_MAX(function()
            if not Config.South_Bronx.FarmingUtilities.AutoBuyMask then return end

            local Success, Error = pcall(function()
                local Prompt_CFrame, Old_CFrame = Gun_Locations['Mask'], LocalPlayer.Character.HumanoidRootPart.CFrame

                local ChildAdded_Check; ChildAdded_Check = LocalPlayer.Backpack.ChildAdded:Connect(function(Child)
                    if Child.Name == 'Mask' then
                        ItemReceieved = true
                        DidntBuy = false

                        ChildAdded_Check:Disconnect();
                    end
                end)

                Config:Teleport(Prompt_CFrame, true)

                task.wait(2.5)

                task.delay(3, function()
                    if not ItemReceieved then
                        ItemReceieved = true
                        DidntBuy = true
                    end
                end)

                fireproximityprompt(Workspace.Folders:FindFirstChild("PromptPurchases")['Mask'].proxprompt:FindFirstChildOfClass("ProximityPrompt"))

                repeat RunService.RenderStepped:Wait() until ItemReceieved == true

                task.wait(0.5)
            end)

            if Error then
                warn("AUTO-BUY-MASK ERROR:", Error)
            end
        end)

        LocalPlayer.CharacterAdded:Connect(function(Character)
            local Teleport_Reset = Config.Reset_Teleporting
            Humanoid = Character:WaitForChild("Humanoid")

            if Library then
                local Method = Library.Flags["SouthBronx/Teleport/Method"]

                if Method == "Instant (Requires Gun)" then
                    Method = "Instant"
                end
                
                Config.South_Bronx.Teleport_Method = Method
            end

            -- Config.South_Bronx.KillAura.Enabled = 

            if Library and Config.South_Bronx.Spawn_Where_You_Died and Death_CFrame and not Config.Reset_Teleporting then
                Death_CFrame = Death_CFrame + Vector3.new(0,3,0)

                local Start = tick()

                repeat RunService.Stepped:Wait()
                    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        Start = tick()
                        continue
                    end
                    
                    local HumanoidRootPart = Character.HumanoidRootPart
                    local LookVector = HumanoidRootPart.CFrame.LookVector
                    HumanoidRootPart.CFrame = CFrame.new(Death_CFrame.Position, Death_CFrame.Position + LookVector)
                until tick() - Start >= 2
            end

            task.wait(3)

            if not Config.Reset_Teleporting and Config.South_Bronx.FarmingUtilities.AutoBuyGun and (Config.South_Bronx.FarmingUtilities.CardFarm or Config.South_Bronx.FarmingUtilities.BoxFarm or Config.South_Bronx.FarmingUtilities.ChipFarm or Config.South_Bronx.FarmingUtilities.MarshmallowFarm) then
                repeat
                    Buy_Gun()
                    task.wait(1)
                until LocalPlayer.Backpack:FindFirstChild("Glock 43") or LocalPlayer.Character:FindFirstChild("Glock 43")

                task.wait(3)
            end

            if not Config.Reset_Teleporting and Config.South_Bronx.FarmingUtilities.AutoBuyMask and (Config.South_Bronx.FarmingUtilities.CardFarm or Config.South_Bronx.FarmingUtilities.BoxFarm or Config.South_Bronx.FarmingUtilities.ChipFarm or Config.South_Bronx.FarmingUtilities.MarshmallowFarm) then
                repeat
                    Buy_Mask()
                    task.wait(1)
                until LocalPlayer.Backpack:FindFirstChild("Mask") or LocalPlayer.Character:FindFirstChild("Mask")
                
                task.wait(3)

                Humanoid:UnequipTools()

                Humanoid:EquipTool(LocalPlayer.Backpack:FindFirstChild("Mask"))

                task.wait(0.5)

                LocalPlayer.Character:FindFirstChild("Mask")

                local args = {
                    buffer.fromstring("\005"),
                    LocalPlayer.Character:FindFirstChild("Mask")
                }

                ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("RPC"):FireServer(unpack(args))

                Humanoid:UnequipTools()

                task.wait(1)
            end

            if not Teleport_Reset then
                if Config.South_Bronx.FarmingUtilities.CardFarm then
                    Stop_CardFarm()
                    task.wait(5)
                    Start_CardFarm()
                end

                if Config.South_Bronx.FarmingUtilities.BoxFarm then
                    Stop_BoxFarm()
                    task.wait(5)
                    Start_BoxFarm()
                end

                if Config.South_Bronx.FarmingUtilities.ChipFarm then
                    Stop_ChipFarm()
                    task.wait(5)
                    Start_ChipFarm()
                end

                if Config.South_Bronx.FarmingUtilities.MarshmallowFarm then
                    Stop_MarshmallowFarm()
                    task.wait(5)
                    if Config.South_Bronx.FarmingUtilities.MarshmallowFarm  then

                        --[[if Config.GetPersonalApartment() then
                            Config:Teleport(Config.GetPersonalApartment().Board.backboard.CFrame, true)

                            task.wait(1.5)

                            fireproximityprompt(Config.GetPersonalApartment().Board.backboard.ProximityPrompt)

                            repeat task.wait(.1) until not Config.GetPersonalApartment() 
                            MarshMallowStep = "Water"
                        end]]

                        MarshMallowStep = "Water"

                        Start_MarshmallowFarm()
                    end
                end
            end

            Humanoid.Died:Connect(function()
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    Death_CFrame = LocalPlayer.Character:WaitForChild("HumanoidRootPart").CFrame
                end

                if not Teleport_Reset then
                    if Config.South_Bronx.FarmingUtilities.CardFarm then
                        Stop_CardFarm()
                    end

                    if Config.South_Bronx.FarmingUtilities.BoxFarm then
                        Stop_BoxFarm()
                    end

                    if Config.South_Bronx.FarmingUtilities.ChipFarm then
                        Stop_ChipFarm()
                    end

                    if Config.South_Bronx.FarmingUtilities.MarshmallowFarm then
                        Stop_MarshmallowFarm()
                    end
                end
            end)
        end)

        local StartingAmount = nil;

        task.spawn(LPH_NO_VIRTUALIZE(function()
            while task.wait(1) do
                if not Config.South_Bronx.FarmingUtilities.CardFarm and not Config.South_Bronx.FarmingUtilities.ChipFarm and not Config.South_Bronx.FarmingUtilities.BoxFarm and not Config.South_Bronx.FarmingUtilities.MarshmallowFarm then continue end

                if LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui") then
                    if LocalPlayer:FindFirstChild("PlayerGui"):FindFirstChild("Main") then
                        local Main = LocalPlayer:FindFirstChild("PlayerGui"):FindFirstChild("Main")

                        if Main:FindFirstChild("Money") then
                            if Main:FindFirstChild("Money"):FindFirstChild("Amount") then
                                local Balance = LocalPlayer.PlayerGui.Main.Money.Amount.Text:match("%$([%d,]+)")
                                Balance = Balance:gsub(",", "")

                                if StartingAmount == nil then StartingAmount = Balance end

                                if (tonumber(Balance) - tonumber(StartingAmount)) > 500000 then
                                    if Config.South_Bronx.FarmingUtilities.CardFarm then
                                        Stop_CardFarm()
                                    end

                                    if Config.South_Bronx.FarmingUtilities.BoxFarm then
                                        Stop_BoxFarm()
                                    end

                                    if Config.South_Bronx.FarmingUtilities.ChipFarm then
                                        Stop_ChipFarm()
                                    end

                                    if Config.South_Bronx.FarmingUtilities.MarshmallowFarm then
                                        Stop_MarshmallowFarm()
                                    end

                                    local ATM;

                                    for Index, Value in Workspace.Map.ATMS:GetChildren() do
                                        if Value.ATMScreen.Transparency == 0 then
                                            ATM = Value
                                            break
                                        end
                                    end

                                    if not ATM then
                                        repeat task.wait(1)
                                            for Index, Value in Workspace.Map.ATMS:GetChildren() do
                                                if Value.ATMScreen.Transparency == 0 then
                                                    ATM = Value
                                                    break
                                                end
                                            end
                                        until ATM ~= nil
                                    end

                                    Config:Teleport(ATMPositions[ATM.Name], true, true)

                                    task.wait(.5)

                                    LocalPlayer.Character.Humanoid:MoveTo(ATM.Position)

                                    LocalPlayer.Character.Humanoid.MoveToFinished:Wait()

                                    task.wait(1)

                                    fireproximityprompt(ATM.Attachment.ProximityPrompt)

                                    local Arguments = {
                                        "Deposit",
                                        {
                                            Amount = '500000'
                                        }
                                    }

                                    Times_Deposited+=1

                                    LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("ATM"):WaitForChild("Frame"):WaitForChild("UIController"):WaitForChild("RemoteFunction"):InvokeServer(unpack(Arguments))

                                    task.wait(2.5)

                                    if tostring(LocalPlayer.PlayerGui:FindFirstChild("ATM").Frame["Balance"].Text) == "Account Balance: $1750000" then
                                        LocalPlayer:Kick("Valary.gg | AUTO-FARMING Stopped. You have $1,750,000 in the ATM.")
                                        return
                                    end

                                    LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("ATM"):WaitForChild("Frame"):WaitForChild("UIController"):WaitForChild("RemoteFunction"):InvokeServer("Exit")

                                    task.wait(3)

                                    if Config.South_Bronx.FarmingUtilities.CardFarm then
                                        Start_CardFarm()
                                    end

                                    if Config.South_Bronx.FarmingUtilities.BoxFarm then
                                        Start_BoxFarm()
                                    end

                                    if Config.South_Bronx.FarmingUtilities.ChipFarm then
                                        Start_ChipFarm()
                                    end

                                    if Config.South_Bronx.FarmingUtilities.MarshmallowFarm then
                                        Start_MarshmallowFarm()
                                    end
                                end
                            end
                        end
                    end
                end
            end 
        end))
    end

    task.spawn(LPH_NO_VIRTUALIZE(function()
        while true do
            task.wait(0.1)

            if LocalPlayer.PlayerGui:FindFirstChild("ATM") then
                pcall(function()
                    Config.ATM_BALANCE = tostring(LocalPlayer.PlayerGui:FindFirstChild("ATM").Frame["Balance"].Text:gsub("Account Balance: ", ""))
                end)
            end
        end
    end))

    do -- Weapon Modifications
        local Old_States = {}
        Config.Mod_Table = {}

        Config.Mod = LPH_NO_VIRTUALIZE(function(Stat, Value)
            local Old_Thread = getthreadidentity()

            setthreadidentity(3)
            for _, Upvalue in pairs(debug.getupvalues(Gun_Module.Jammed)) do
                if typeof(Upvalue) == "table" then
                    for _, Mod in pairs(Upvalue) do

                        if typeof(Mod) == "table" and Mod.Module then
                            Config.Mod_Table = Mod
                            setreadonly(Mod.Module, false)
                            Mod.Module[Stat] = Value
                        end
                    end
                end
            end

            setthreadidentity(Old_Thread)
        end)

        Config.Slide = LPH_NO_VIRTUALIZE(function()
            local Old_Thread = getthreadidentity()

            setthreadidentity(3)
            for _, Upvalue in pairs(debug.getupvalues(Gun_Module.Jammed)) do
                if typeof(Upvalue) == "table" then
                    for _, Mod in pairs(Upvalue) do
                        if typeof(Mod) == "table" and Mod.Canshoot ~= nil then
                            Mod.Canshoot = true
                        end
                    end
                end
            end

            setthreadidentity(Old_Thread)
        end)

        Config.Get = function(DefaultValue, NewValue)
            NewValue = math.max(0, math.min(100, NewValue))
        
            local new_value = DefaultValue * (NewValue / 100)
        
            return new_value
        end

        --[[ local RPC_Event; RPC_Event = hookmetamethod(ReplicatedStorage.RemoteEvents.ChangeMagAndAmmo, "__namecall", newcclosure(LPH_NO_VIRTUALIZE(function(Self, ...)
            local Arguments = {...}
            local Buffer = Arguments[1]

            if getnamecallmethod() == "FireServer" and tostring(Self) == "ChangeMagAndAmmo" and Config["Infinite Ammo"] and #Arguments == 2 and typeof(Buffer) == "buffer" and typeof(Arguments[2]) == "Instance" and Arguments[2].ClassName == "Tool" then
    
                print(debug.traceback())
                Arguments[2] = require(Arguments[2].Setting).AmmoPerMag
    
                return RPC_Event(Self, unpack(Arguments))
            end
    
            return RPC_Event(Self, ...)
        end))) ]]

        local HideGunSoundsConnection;

        Config.Modify = LPH_NO_VIRTUALIZE(function(Child)
            if Child and Child:IsA("Tool") and Child:FindFirstChild("Setting") and require(Child.Setting).MaxAmmo then 
                Config.Gun_Held = true

                if HideGunSoundsConnection then
                    HideGunSoundsConnection:Disconnect()
                    HideGunSoundsConnection = nil
                end

                Config.Gun_Handle = Child:WaitForChild("Handle", 1)

                HideGunSoundsConnection = Child.Handle.ChildAdded:Connect(function(_Child)
                    task.wait();

                    if _Child:IsA("Sound") and Config.Hit_Sounds_Settings.HideNormalSounds then
                        _Child:Destroy()
                    end
                end)

                if Config["Instant Equip"].Enabled then 
                    task.delay(.1, Config.Slide)
                end

                local Old_Module = Old_States[tostring(Child)] 

                if not Old_States[tostring(Child)] then
                    Old_States[tostring(Child)] = table.clone(require(Child.Setting))

                    Old_Module = Old_States[tostring(Child)]
                end

                if Config.Recoil.Enabled then 
                    Config.Mod("Recoil", Config.Get(Old_Module.Recoil, Config.Recoil.Reduce))
                else
                    Config.Mod("Recoil", Old_Module.Recoil)
                end

                if Config.Spread.Enabled then 
                    Config.Mod("SpreadX", Config.Get(Old_Module.SpreadX, Config.Recoil.Reduce))
                    Config.Mod("SpreadY", Config.Get(Old_Module.SpreadY, Config.Recoil.Reduce))
                else
                    Config.Mod("SpreadX", Old_Module.SpreadX)
                    Config.Mod("SpreadY", Old_Module.SpreadY)
                end 

                if Config["Force Auto"].Enabled then 
                    Config.Mod("Auto", true)
                else
                    Config.Mod("Auto", Old_Module.Auto)
                end

                if Config["One Tap"].Enabled then
                    Config.Mod("ShotgunEnabled", true)
                else
                    Config.Mod("ShotgunEnabled", Old_Module.ShotgunEnabled)
                end

                if Config["No Jam"].Enabled then 
                    Config.Mod("JamChance", 0)
                else
                    Config.Mod("JamChance", Old_Module.JamChance)
                end

                if Config.Fire_Rate.Enabled then 
                    Config.Mod("FireRate", Config.Get(Old_Module.FireRate, Config.Fire_Rate.Increase))
                else
                    Config.Mod("FireRate", Old_Module.FireRate)
                end

                if Config["Instant Bullet"].Enabled then 
                    Config.Mod("BulletSpeed", 9e9)
                else
                    Config.Mod("BulletSpeed", Old_Module.BulletSpeed)
                end 

                if Config["Instant Reload"].Enabled then 
                    Config.Mod("ReloadTime", 0)
                else
                    Config.Mod("ReloadTime", Old_Module.ReloadTime)
                end

                if Config["Instant Equip"].Enabled then 
                    Config.Mod("EquippingTime", 0)
                else
                    Config.Mod("EquippingTime", Old_Module.EquippingTime)
                end
            end
        end)

        local ChildRemoved = LPH_NO_VIRTUALIZE(function(Child)
            if Child:IsA("Tool") then
                Config.Gun_Held = false
            end
        end)

        Config.Set_Up = LPH_NO_VIRTUALIZE(function(Character)
            Character.ChildAdded:Connect(Config.Modify)
            Character.ChildRemoved:Connect(ChildRemoved)
        end)

        if LocalPlayer.Character then
            Config.Set_Up(LocalPlayer.Character)
        end

        LocalPlayer.CharacterAdded:Connect(Config.Set_Up)

        -- Kill Aura Loop
            --[[task.spawn(LPH_NO_VIRTUALIZE(function()
                while true do task.wait(.1)
                    if Config.South_Bronx.KillAura.Enabled and LocalPlayer.Character then
                        local Gun = Config.GetGun()

                        if not Gun then continue end

                        if Gun and Gun.Parent == LocalPlayer.Backpack or Gun.Parent == LocalPlayer.Character then
                            for Index, Value in Players:GetPlayers() do
                                if Value~=LocalPlayer then
                                    if Config.Valary_Users[Value.Name] then continue end
                                    if not Value.Character then continue end
                                    if not LocalPlayer.Character then continue end
                                    if table.find(Library.Friendly_Players, Value.Name) then continue end

                                    local Head, Humanoid, HumanoidRootPart = Value.Character:FindFirstChild("Head"), Value.Character:FindFirstChild("Humanoid"), Value.Character:FindFirstChild("HumanoidRootPart") 
                                
                                    if not Head or not Humanoid or Humanoid.Health == 0 then
                                        continue
                                    end

                                    if Config.InsideSafezone(Value) then
                                        continue
                                    end

                                    if (LocalPlayer.Character.HumanoidRootPart.Position - HumanoidRootPart.Position).Magnitude <= Config.South_Bronx.KillAura.Range then
                                        Config:ShootPlayer(Value.Name)
                                    end
                                end
                            end
                        end
                    end
                end
            end))]]
        --
    end
end

if getgenv().Library then
    getgenv().Library:Unload()
end

local ESPFonts = { }
local SelectedESPFont

local Options, MiscOptions do
    if getgenv().Esp then 
        getgenv().Esp.Unload()
    end 

    local Workspace = cloneref(game:GetService("Workspace"))
    local RunService = cloneref(game:GetService("RunService"))
    local HttpService = cloneref(game:GetService("HttpService"))
    local Players = cloneref(game:GetService("Players"))
    local TweenService = cloneref(game:GetService("TweenService"))

    local vec2 = Vector2.new
    local vec3 = Vector3.new
    local dim2 = UDim2.new
    local dim = UDim.new 
    local rect = Rect.new
    local cfr = CFrame.new
    local empty_cfr = cfr()
    local angle = CFrame.Angles
    local dim_offset = UDim2.fromOffset

    local rgb = Color3.fromRGB
    local hex = Color3.fromHex
    local hsv = Color3.fromHSV
    local rgbseq = ColorSequence.new
    local rgbkey = ColorSequenceKeypoint.new
    local numseq = NumberSequence.new
    local numkey = NumberSequenceKeypoint.new
    local camera = Workspace.CurrentCamera

    local Bones = {
        {"Head", "UpperTorso"},
        {"UpperTorso", "LowerTorso"},
        {"UpperTorso", "LeftUpperArm"},
        {"UpperTorso", "RightUpperArm"},
        {"LeftUpperArm", "LeftLowerArm"},
        {"RightUpperArm", "RightLowerArm"},
        {"LowerTorso", "LeftUpperLeg"},
        {"LowerTorso", "RightUpperLeg"},
        {"LeftUpperLeg", "LeftLowerLeg"},
        {"RightUpperLeg", "RightLowerLeg"},
    }

    -- Esp is mainly hardcoded because having to make a library for everything is very useless considering we're working with not more than 10 elements at once. 
    --[[
        PlayersTab.AddBar({Name = "Healthbar"})
        PlayersTab.AddText({Name = "Name"})
        PlayersTab.AddText({Name = "Distance"})
        PlayersTab.AddText({Name = "Weapon"})
        PlayersTab.AddText({Name = "Flags", Color1 = rgb(225, 255, 0)})
        PlayersTab.AddBox({Name = "Box"})

        Each element will have its own concat for their flag <-- this means that if you make a text called name itll make the flags
        ["Name"] = true; 
        ["Name_Color"] = { Color = rgb(255, 255, 255) };
        ["Name_Position"] = "Left";
        which will be overwritten in the table down below. 

        All elements will be updated with a metatable, look for the new index and there will be a refresh function.

        I labelled the main code with important tags because some people dont know how to find my code...
    ]]

    MiscOptions = {
        ["Enabled"] = false;
        ["Render_Distance"] = 500;

        -- Boxes
        ["Boxes"] = false;
        ["BoxType"] = "Corner";
        ["Box Gradient 1"] = { Color = rgb(255, 255, 255), Transparency = 0.9 };
        ["Box Gradient 2"] = { Color = rgb(255, 255, 255), Transparency = 0.4 };
        ["Box Gradient Rotation"] = 90;
        ["Box Fill"] = false; 
        ["Box Fill 1"] = { Color = rgb(255, 255, 255), Transparency = 0.9 };
        ["Box Fill 2"] = { Color = rgb(255, 255, 255), Transparency = 0.9 };
        ["Box Fill Rotation"] = 0;

        ["Healthbar"] = false;
        ["Healthbar_Position"] = "Left";
        ["Healthbar_Number"] = false;
        ["Healthbar_Low"] = { Color = rgb(255, 0, 0), Transparency = 1};
        ["Healthbar_Medium"] = { Color = rgb(255, 255, 0), Transparency = 1};
        ["Healthbar_Animations"] = false; 
        ["Healthbar_High"] = { Color = rgb(0, 255, 0), Transparency = 1};
        ["Healthbar_Font"] = "Verdana";
        ["Healthbar_Text_Size"] = 11;
        ["Healthbar_Thickness"] = 1;
        ["Healthbar_Tween"] = false;
        ["Healthbar_EasingStyle"] = "Circular";
        ["Healthbar_EasingDirection"] = "InOut";
        ["Healthbar_Easing_Speed"] = 1;

        ["Ammobar"] = false;
        ["Ammobar_Position"] = "Right";
        ["Ammobar_Number"] = false;
        ["Ammobar_Low"] = { Color = rgb(0, 98, 255), Transparency = 1 };
        ["Ammobar_Medium"] = { Color = rgb(0, 130, 255), Transparency = 1 };
        ["Ammobar_Animations"] = false;
        ["Ammobar_High"] = { Color = rgb(0, 162, 255), Transparency = 1 };
        ["Ammobar_Font"] = "Verdana";
        ["Ammobar_Text_Size"] = 11;
        ["Ammobar_Text_Color"] = rgb(255,255,255);
        ["Ammobar_Thickness"] = 1;
        ["Ammobar_Tween"] = false;
        ["Ammobar_EasingStyle"] = "Circular";
        ["Ammobar_EasingDirection"] = "InOut";
        ["Ammobar_Easing_Speed"] = 1;

        -- Text Based Elements
        ["Name_Text"] = false; 
        ["Name_Text_Color"] = { Color = rgb(255, 255, 255) };
        ["Name_Text_Position"] = "Top";
        ["Name_Text_Font"] = "Verdana";
        ["Name_Text_Size"] = 11;
        
        ["Distance_Text"] = false; 
        ["Distance_Text_Color"] = { Color = rgb(255, 255, 255) };
        ["Distance_Text_Position"] = "Bottom";
        ["Distance_Text_Font"] = "Verdana";
        ["Distance_Text_Size"] = 11;

        ["Weapon_Text"] = false; 
        ["Weapon_Text_Color"] = { Color = rgb(255, 255, 255) };
        ["Weapon_Text_Position"] = "Bottom";
        ["Weapon_Text_Font"] = "Verdana";
        ["Weapon_Text_Size"] = 11;
    };  

    Options = setmetatable({}, {__index = MiscOptions, __newindex = function(self, key, value) Esp.RefreshElements(key, value) end});

    local Fonts = {}; do
        local function RegisterFont(Name, Weight, Style, Asset)
            writefile(Asset.Id, Asset.Font)

            local Data = {
                name = Name,
                faces = {
                    {
                        name = "Normal",
                        weight = Weight,
                        style = Style,
                        assetId = getcustomasset(Asset.Id),
                    },
                },
            }

            writefile(Name .. ".font", HttpService:JSONEncode(Data))

            return getcustomasset(Name .. ".font");
        end

        local FontNames = {
            ["ProggyClean"] = "ProggyClean.ttf",
            ["Tahoma"] = "fs-tahoma-8px.ttf",
            ["Verdana"] = "Verdana-Font.ttf",
            ["SmallestPixel"] = "smallest_pixel-7.ttf",
            ["ProggyTiny"] = "ProggyTiny.ttf",
            ["Minecraftia"] = "Minecraftia-Regular.ttf",
            ["Tahoma Bold"] = "tahoma_bold.ttf"
        }

        for name, suffix in FontNames do 
            local RegisteredFont = RegisterFont(name, 400, "Normal", {
                Id = suffix,
                Font = game:HttpGet("https://github.com/i77lhm/storage/raw/refs/heads/main/fonts/" .. suffix),
            }) 

            Fonts[name] = Font.new(RegisteredFont, Enum.FontWeight.Regular, Enum.FontStyle.Normal)
            ESPFonts[name] = Font.new(RegisteredFont, Enum.FontWeight.Regular, Enum.FontStyle.Normal)
        end
    end

    getgenv().Esp = { 
        Players = {}, 
        ScreenGui = Instance.new("ScreenGui", gethui()), 
        Cache = Instance.new("ScreenGui", gethui()), 
        Connections = {}, 
    }; do 
        Esp.ScreenGui.IgnoreGuiInset = true
        Esp.ScreenGui.Name = "EspObject"

        Esp.Cache.Enabled = false   

        function Esp:Create(instance, options)
            local Ins = Instance.new(instance) 
            
            for prop, value in options do 
                Ins[prop] = value
            end
            
            return Ins 
        end

        function Esp:Connection(signal, callback)
            local Connection = signal:Connect(callback)
            Esp.Connections[#Esp.Connections + 1] = Connection
            
            return Connection 
        end

        Esp.ConvertScreenPoint = LPH_NO_VIRTUALIZE(function(self, world_position)
            local ViewportSize = camera.ViewportSize
            local LocalPos = camera.CFrame:pointToObjectSpace(world_position) 

            local AspectRatio = ViewportSize.X / ViewportSize.Y
            local HalfY = -LocalPos.Z * math.tan(math.rad(camera.FieldOfView / 2))
            local HalfX = AspectRatio * HalfY
            
            local FarPlaneCorner = Vector3.new(-HalfX, HalfY, LocalPos.Z)
            local RelativePos = LocalPos - FarPlaneCorner
        
            local ScreenX = RelativePos.X / (HalfX * 2)
            local ScreenY = -RelativePos.Y / (HalfY * 2)
            
            local OnScreen = -LocalPos.Z > 0 and ScreenX >= 0 and ScreenX <= 1 and ScreenY >= 0 and ScreenY <= 1
            
            -- returns in pixels as opposed to scale
            return Vector3.new(ScreenX * ViewportSize.X, ScreenY * ViewportSize.Y, -LocalPos.Z), OnScreen
        end)

        Esp.BoxSolve = LPH_NO_VIRTUALIZE(function(self, torso)
            if not torso then
                return nil, nil, nil
            end 

            local ViewportTop = torso.Position + (torso.CFrame.UpVector * 1.8) + camera.CFrame.UpVector
            local ViewportBottom = torso.Position - (torso.CFrame.UpVector * 2.5) - camera.CFrame.UpVector
            local Distance = (torso.Position - camera.CFrame.p).Magnitude

            local Top, TopIsRendered = Esp:ConvertScreenPoint(ViewportTop)
            local Bottom, BottomIsRendered = Esp:ConvertScreenPoint(ViewportBottom)

            local Width = math.max(math.floor(math.abs(Top.X - Bottom.X)), 3)
            local Height = math.max(math.floor(math.max(math.abs(Bottom.Y - Top.Y), Width / 2)), 3)
            local BoxSize = Vector2.new(math.floor(math.max(Height / 1.5, Width)), Height)
            local BoxPosition = Vector2.new(math.floor(Top.X * 0.5 + Bottom.X * 0.5 - BoxSize.X * 0.5), math.floor(math.min(Top.Y, Bottom.Y)))
            
            return BoxSize, BoxPosition, TopIsRendered, Distance 
        end)

        function Esp:Lerp(start, finish, t)
            t = t or 1 / 8

            return start * (1 - t) + finish * t
        end

        function Esp:Tween(Object, Properties, Info)
            local tween = TweenService:Create(Object, Info, Properties)
            tween:Play()
            
            return tween
        end

        function Esp.CreateObject( player, typechar ) -- IMPORTANT!
            local Data = { 
                Items = { }, 
                Info = {Character; Humanoid; Health = 0; Ammo = 0}; 
                Drawings = { }, 
                Type = typechar or "player";
                Connections = {};
            } 

            function Data:Connection(signal, callback)
                local conn = signal:Connect(callback)
                table.insert(self.Connections, conn)
                return conn
            end

            local Items = Data.Items; do
                -- Holder
                    Items.Holder = Esp:Create( "Frame" , {
                        Parent = Esp.ScreenGui;
                        Name = "\0";
                        BackgroundTransparency = 1;
                        Position = dim2(0.4332570433616638, 0, 0.3255814015865326, 0);
                        BorderColor3 = rgb(0, 0, 0);
                        Size = dim2(0, 211, 0, 240);
                        BorderSizePixel = 0;
                        BackgroundColor3 = rgb(255, 255, 255)
                    });

                    Items.HolderGradient = Esp:Create( "UIGradient" , {
                        Rotation = 0;
                        Name = "\0";
                        Color = rgbseq{rgbkey(0, rgb(255, 255, 255)), rgbkey(1, rgb(255, 255, 255))};
                        Parent = Items.Holder;
                        Enabled = true
                    });

                    -- All directions have a set default parent of Items.Holder 

                    -- Directions 
                        Items.Left = Esp:Create( "Frame" , {
                            Parent = Items.Holder;
                            Size = dim2(0, 0, 1, 0);
                            Name = "\0";
                            BackgroundTransparency = 1;
                            Position = dim2(0, -1, 0, 0);
                            BorderColor3 = rgb(0, 0, 0);
                            ZIndex = 2;
                            BorderSizePixel = 0;
                            BackgroundColor3 = rgb(255, 255, 255)
                        });

                        Items.HealthbarTextsLeft = Esp:Create( "Frame", {
                            Visible = true;
                            BorderColor3 = rgb(0, 0, 0);
                            Parent = Esp.Cache;
                            Name = "\0";
                            BackgroundTransparency = 1;
                            LayoutOrder = -100;
                            BorderSizePixel = 0;
                            ZIndex = 0;
                            AutomaticSize = Enum.AutomaticSize.X;
                            BackgroundColor3 = rgb(255, 255, 255)
                        });

                        Esp:Create( "UIListLayout" , {
                            FillDirection = Enum.FillDirection.Horizontal;
                            HorizontalAlignment = Enum.HorizontalAlignment.Right;
                            VerticalFlex = Enum.UIFlexAlignment.Fill;
                            Parent = Items.Left;
                            Padding = dim(0, 1);
                            SortOrder = Enum.SortOrder.LayoutOrder
                        });

                        Items.LeftTexts = Esp:Create( "Frame" , {
                            LayoutOrder = -100;
                            Parent = Items.Left;
                            BackgroundTransparency = 1;
                            Name = "\0";
                            BorderColor3 = rgb(0, 0, 0);
                            BorderSizePixel = 0;
                            AutomaticSize = Enum.AutomaticSize.X;
                            BackgroundColor3 = rgb(255, 255, 255)
                        });

                        Esp:Create( "UIListLayout" , {
                            Parent = Items.LeftTexts;
                            Padding = dim(0, 1);
                            SortOrder = Enum.SortOrder.LayoutOrder
                        });

                        Items.Bottom = Esp:Create( "Frame" , {
                            Parent = Items.Holder;
                            Size = dim2(1, 0, 0, 0);
                            Name = "\0";
                            BackgroundTransparency = 1;
                            Position = dim2(0, 0, 1, 1);
                            BorderColor3 = rgb(0, 0, 0);
                            ZIndex = 2;
                            BorderSizePixel = 0;
                            BackgroundColor3 = rgb(255, 255, 255)
                        });

                        Esp:Create( "UIListLayout" , {
                            SortOrder = Enum.SortOrder.LayoutOrder;
                            HorizontalAlignment = Enum.HorizontalAlignment.Center;
                            HorizontalFlex = Enum.UIFlexAlignment.Fill;
                            Parent = Items.Bottom;
                            Padding = dim(0, 1)
                        });

                        Items.BottomTexts = Esp:Create( "Frame", {
                            LayoutOrder = 1;
                            Parent = Items.Bottom;
                            BackgroundTransparency = 1;
                            Name = "\0";
                            BorderColor3 = rgb(0, 0, 0);
                            BorderSizePixel = 0;
                            AutomaticSize = Enum.AutomaticSize.XY;
                            BackgroundColor3 = rgb(255, 255, 255)
                        });

                        Esp:Create( "UIListLayout", {
                            Parent = Items.BottomTexts;
                            Padding = dim(0, 1);
                            SortOrder = Enum.SortOrder.LayoutOrder
                        });

                        Items.Top = Esp:Create( "Frame" , {
                            Parent = Items.Holder;
                            Size = dim2(1, 0, 0, 0);
                            Name = "\0";
                            BackgroundTransparency = 1;
                            Position = dim2(0, 0, 0, -1);
                            BorderColor3 = rgb(0, 0, 0);
                            ZIndex = 2;
                            BorderSizePixel = 0;
                            BackgroundColor3 = rgb(255, 255, 255)
                        });

                        Esp:Create( "UIListLayout" , {
                            VerticalAlignment = Enum.VerticalAlignment.Bottom;
                            SortOrder = Enum.SortOrder.LayoutOrder;
                            HorizontalAlignment = Enum.HorizontalAlignment.Center;
                            HorizontalFlex = Enum.UIFlexAlignment.Fill;
                            Parent = Items.Top;
                            Padding = dim(0, 1)
                        });

                        Items.TopTexts = Esp:Create( "Frame", {
                            LayoutOrder = -100;
                            Parent = Items.Top;
                            BackgroundTransparency = 1;
                            Name = "\0";
                            BorderColor3 = rgb(0, 0, 0);
                            BorderSizePixel = 0;
                            AutomaticSize = Enum.AutomaticSize.XY;
                            BackgroundColor3 = rgb(255, 255, 255)
                        });

                        Esp:Create( "UIListLayout", {
                            Parent = Items.TopTexts;
                            Padding = dim(0, 1);
                            SortOrder = Enum.SortOrder.LayoutOrder
                        });

                        Items.Right = Esp:Create( "Frame" , {
                            Parent = Esp.Cache;
                            Size = dim2(0, 0, 1, 0);
                            Name = "\0";
                            BackgroundTransparency = 1;
                            Position = dim2(1, 1, 0, 0);
                            BorderColor3 = rgb(0, 0, 0);
                            ZIndex = 2;
                            BorderSizePixel = 0;
                            BackgroundColor3 = rgb(255, 255, 255)
                        });

                        Esp:Create( "UIListLayout" , {
                            FillDirection = Enum.FillDirection.Horizontal;
                            VerticalFlex = Enum.UIFlexAlignment.Fill;
                            Parent = Items.Right;
                            Padding = dim(0, 1);
                            SortOrder = Enum.SortOrder.LayoutOrder
                        });
                        
                        Items.RightTexts = Esp:Create( "Frame" , {
                            LayoutOrder = 100;
                            Parent = Items.Right;
                            BackgroundTransparency = 1;
                            Name = "\0";
                            BorderColor3 = rgb(0, 0, 0);
                            BorderSizePixel = 0;
                            AutomaticSize = Enum.AutomaticSize.X;
                            BackgroundColor3 = rgb(255, 255, 255)
                        });
                        
                        Esp:Create( "UIListLayout" , {
                            Parent = Items.RightTexts;
                            Padding = dim(0, 1);
                            SortOrder = Enum.SortOrder.LayoutOrder
                        });

                        Items.HealthbarTextsRight = Esp:Create( "Frame", {
                            Visible = true;
                            BorderColor3 = rgb(0, 0, 0);
                            Parent = Esp.Cache;
                            Name = "\0";
                            BackgroundTransparency = 1;
                            LayoutOrder = 99;
                            BorderSizePixel = 0;
                            ZIndex = 0;
                            AutomaticSize = Enum.AutomaticSize.X;
                            BackgroundColor3 = rgb(255, 255, 255)
                        });

                        Items.AmmobarTextsRight = Esp:Create( "Frame", {
                            Visible = true;
                            BorderColor3 = rgb(0, 0, 0);
                            Parent = Esp.Cache;
                            Name = "\0";
                            BackgroundTransparency = 1;
                            LayoutOrder = 99;
                            BorderSizePixel = 0;
                            ZIndex = 0;
                            AutomaticSize = Enum.AutomaticSize.X;
                            BackgroundColor3 = rgb(255, 255, 255)
                        });

                        Items.AmmobarTextsLeft = Esp:Create( "Frame", {
                            Visible = true;
                            BorderColor3 = rgb(0, 0, 0);
                            Parent = Esp.Cache;
                            Name = "\0";
                            BackgroundTransparency = 1;
                            LayoutOrder = -100;
                            BorderSizePixel = 0;
                            ZIndex = 0;
                            AutomaticSize = Enum.AutomaticSize.X;
                            BackgroundColor3 = rgb(255, 255, 255)
                        });
                    --
                -- 

                -- Corner Boxes
                    Items.Corners = Esp:Create( "Frame", {
                        Parent = Esp.Cache; -- Items.Holder
                        Name = "\0";
                        BackgroundTransparency = 1;
                        BorderColor3 = rgb(0, 0, 0);
                        Size = dim2(1, 0, 1, 0);
                        BorderSizePixel = 0;
                        BackgroundColor3 = rgb(255, 255, 255)
                    });

                    Items.BottomLeftX = Esp:Create( "ImageLabel", {
                        ScaleType = Enum.ScaleType.Slice;
                        Parent = Items.Corners;
                        BorderColor3 = rgb(0, 0, 0);
                        Name = "\0";
                        BackgroundColor3 = rgb(255, 255, 255);
                        Size = dim2(0.4, 0, 0, 3);
                        AnchorPoint = vec2(0, 1);
                        Image = "rbxassetid://83548615999411";
                        BackgroundTransparency = 1;
                        Position = dim2(0, 0, 1, 0);
                        ZIndex = 2;
                        BorderSizePixel = 0;
                        SliceCenter = rect(vec2(1, 1), vec2(99, 2))
                    });

                    Esp:Create( "UIGradient", {
                        Parent = Items.BottomLeftX
                    });

                    Items.BottomLeftY = Esp:Create( "ImageLabel", {
                        ScaleType = Enum.ScaleType.Slice;
                        Parent = Items.Corners;
                        BorderColor3 = rgb(0, 0, 0);
                        Name = "\0";
                        BackgroundColor3 = rgb(255, 255, 255);
                        Size = dim2(0, 3, 0.25, 0);
                        AnchorPoint = vec2(0, 1);
                        Image = "rbxassetid://101715268403902";
                        BackgroundTransparency = 1;
                        Position = dim2(0, 0, 1, -2);
                        ZIndex = 500;
                        BorderSizePixel = 0;
                        SliceCenter = rect(vec2(1, 0), vec2(2, 96))
                    });

                    Esp:Create( "UIGradient", {
                        Rotation = -90;
                        Parent = Items.BottomLeftY
                    });

                    Items.BottomRighX = Esp:Create( "ImageLabel", {
                        ScaleType = Enum.ScaleType.Slice;
                        Parent = Items.Corners;
                        BorderColor3 = rgb(0, 0, 0);
                        Name = "\0";
                        BackgroundColor3 = rgb(255, 255, 255);
                        Size = dim2(0.4, 0, 0, 3);
                        AnchorPoint = vec2(1, 1);
                        Image = "rbxassetid://83548615999411";
                        BackgroundTransparency = 1;
                        Position = dim2(1, 0, 1, 0);
                        ZIndex = 2;
                        BorderSizePixel = 0;
                        SliceCenter = rect(vec2(1, 1), vec2(99, 2))
                    });

                    Esp:Create( "UIGradient", {
                        Parent = Items.BottomRighX
                    });

                    Items.BottomLeftY = Esp:Create( "ImageLabel", {
                        ScaleType = Enum.ScaleType.Slice;
                        Parent = Items.Corners;
                        BorderColor3 = rgb(0, 0, 0);
                        Name = "\0";
                        BackgroundColor3 = rgb(255, 255, 255);
                        Size = dim2(0, 3, 0.25, 0);
                        AnchorPoint = vec2(1, 1);
                        Image = "rbxassetid://101715268403902";
                        BackgroundTransparency = 1;
                        Position = dim2(1, 0, 1, -2);
                        ZIndex = 500;
                        BorderSizePixel = 0;
                        SliceCenter = rect(vec2(1, 0), vec2(2, 96))
                    });

                    Esp:Create( "UIGradient", {
                        Rotation = 90;
                        Parent = Items.BottomLeftY
                    });

                    Items.TopLeftY = Esp:Create( "ImageLabel", {
                        ScaleType = Enum.ScaleType.Slice;
                        BorderColor3 = rgb(0, 0, 0);
                        Parent = Items.Corners;
                        Name = "\0";
                        BackgroundColor3 = rgb(255, 255, 255);
                        Size = dim2(0, 3, 0.25, 0);
                        Image = "rbxassetid://102467475629368";
                        BackgroundTransparency = 1;
                        Position = dim2(0, 0, 0, 2);
                        ZIndex = 500;
                        BorderSizePixel = 0;
                        SliceCenter = rect(vec2(1, 0), vec2(2, 98))
                    });

                    Esp:Create( "UIGradient", {
                        Rotation = 90;
                        Parent = Items.TopLeftY
                    });

                    Items.TopRightY = Esp:Create( "ImageLabel", {
                        ScaleType = Enum.ScaleType.Slice;
                        Parent = Items.Corners;
                        BorderColor3 = rgb(0, 0, 0);
                        Name = "\0";
                        BackgroundColor3 = rgb(255, 255, 255);
                        Size = dim2(0, 3, 0.25, 0);
                        AnchorPoint = vec2(1, 0);
                        Image = "rbxassetid://102467475629368";
                        BackgroundTransparency = 1;
                        Position = dim2(1, 0, 0, 2);
                        ZIndex = 500;
                        BorderSizePixel = 0;
                        SliceCenter = rect(vec2(1, 0), vec2(2, 98))
                    });

                    Esp:Create( "UIGradient", {
                        Rotation = -90;
                        Parent = Items.TopRightY
                    });

                    Items.TopRightX = Esp:Create( "ImageLabel", {
                        ScaleType = Enum.ScaleType.Slice;
                        Parent = Items.Corners;
                        BorderColor3 = rgb(0, 0, 0);
                        Name = "\0";
                        BackgroundColor3 = rgb(255, 255, 255);
                        Size = dim2(0.4, 0, 0, 3);
                        AnchorPoint = vec2(1, 0);
                        Image = "rbxassetid://83548615999411";
                        BackgroundTransparency = 1;
                        Position = dim2(1, 0, 0, 0);
                        ZIndex = 2;
                        BorderSizePixel = 0;
                        SliceCenter = rect(vec2(1, 1), vec2(99, 2))
                    });

                    Esp:Create( "UIGradient", {
                        Parent = Items.TopRightX
                    });

                    Items.TopLeftX = Esp:Create( "ImageLabel", {
                        ScaleType = Enum.ScaleType.Slice;
                        BorderColor3 = rgb(0, 0, 0);
                        Parent = Items.Corners;
                        Name = "\0";
                        BackgroundColor3 = rgb(255, 255, 255);
                        Image = "rbxassetid://83548615999411";
                        BackgroundTransparency = 1;
                        Size = dim2(0.4, 0, 0, 3);
                        ZIndex = 2;
                        BorderSizePixel = 0;
                        SliceCenter = rect(vec2(1, 1), vec2(99, 2))
                    });

                    Esp:Create( "UIGradient", {
                        Parent = Items.TopLeftX
                    });
                -- 

                -- Normal Box 
                    Items.Box = Esp:Create( "Frame" , {
                        Parent = Esp.Cache; -- Items.Holder
                        Name = "\0";
                        BackgroundTransparency = 1;
                        Position = dim2(0, 1, 0, 1);
                        BorderColor3 = rgb(0, 0, 0);
                        Size = dim2(1, -2, 1, -2);
                        BorderSizePixel = 0;
                        BackgroundColor3 = rgb(255, 255, 255)
                    });

                    Esp:Create( "UIStroke" , {  
                        Parent = Items.Box;
                        LineJoinMode = Enum.LineJoinMode.Miter
                    });

                    Items.Inner = Esp:Create( "Frame" , {
                        Parent = Items.Box;
                        Name = "\0";
                        BackgroundTransparency = 1;
                        Position = dim2(0, 1, 0, 1);
                        BorderColor3 = rgb(0, 0, 0);
                        Size = dim2(1, -2, 1, -2);
                        BorderSizePixel = 0;
                        BackgroundColor3 = rgb(255, 255, 255)
                    });

                    Items.UIStroke = Esp:Create( "UIStroke" , {
                        Color = rgb(255, 255, 255);
                        LineJoinMode = Enum.LineJoinMode.Miter;
                        Parent = Items.Inner
                    });

                    Items.BoxGradient = Esp:Create( "UIGradient" , {
                        Parent = Items.UIStroke
                    });

                    Items.Inner2 = Esp:Create( "Frame" , {
                        Parent = Items.Inner;
                        Name = "\0";
                        BackgroundTransparency = 1;
                        Position = dim2(0, 1, 0, 1);
                        BorderColor3 = rgb(0, 0, 0);
                        Size = dim2(1, -2, 1, -2);
                        BorderSizePixel = 0;
                        BackgroundColor3 = rgb(255, 255, 255)
                    });

                    Esp:Create( "UIStroke" , {
                        Parent = Items.Inner2;
                        LineJoinMode = Enum.LineJoinMode.Miter
                    });
                -- 
                
                -- Healthbar
                    Items.Healthbar = Esp:Create( "Frame" , {
                        Name = "Left";
                        Parent = Esp.Cache;
                        BorderColor3 = rgb(0, 0, 0);
                        Size = dim2(0, 3, 0, 3);
                        BorderSizePixel = 0;
                        BackgroundColor3 = rgb(0, 0, 0)
                    });

                    Items.HealthbarAccent = Esp:Create( "Frame" , {
                        Parent = Items.Healthbar;
                        Name = "\0";
                        Position = dim2(0, 1, 0, 1);
                        BorderColor3 = rgb(0, 0, 0);
                        Size = dim2(1, -2, 1, -2);
                        BorderSizePixel = 0;
                        BackgroundColor3 = rgb(255, 255, 255)
                    });

                    Items.HealthbarFade = Esp:Create( "Frame" , {
                        Parent = Items.Healthbar;
                        Name = "\0";
                        Position = dim2(0, 1, 0, 1);
                        BorderColor3 = rgb(0, 0, 0);
                        Size = dim2(1, -2, 1, -2);
                        BorderSizePixel = 0;
                        BackgroundColor3 = rgb(0, 0, 0)
                    });

                    Items.HealthbarGradient = Esp:Create( "UIGradient" , {
                        Enabled = true;
                        Parent = Items.HealthbarAccent;
                        Rotation = 90;
                        Color = rgbseq{rgbkey(0, rgb(0, 255, 0)), rgbkey(0.5, rgb(255, 125, 0)), rgbkey(1, rgb(255, 0, 0))}
                    });

                    Items.HealthbarText = Esp:Create( "TextLabel", {
                        FontFace = Fonts.Verdana;
                        TextColor3 = rgb(255, 255, 255);
                        BorderColor3 = rgb(0, 0, 0);
                        Parent = Esp.Cache; -- Items.HealthbarTextsLeft
                        Name = "\0";
                        BackgroundTransparency = 1;
                        Size = dim2(0, 0, 0, 0);
                        BorderSizePixel = 0;
                        AutomaticSize = Enum.AutomaticSize.XY;
                        TextSize = 11;
                        BackgroundColor3 = rgb(255, 255, 255)
                    });

                    Esp:Create( "UIStroke", {
                        Parent = Items.HealthbarText;
                        LineJoinMode = Enum.LineJoinMode.Miter
                    });
                -- 

                -- Ammo Bar
                    Items.Ammobar = Esp:Create( "Frame" , {
                        Name = "Right";
                        Parent = Esp.Cache;
                        BorderColor3 = rgb(0, 0, 0);
                        Size = dim2(0, 3, 0, 3);
                        BorderSizePixel = 0;
                        BackgroundColor3 = rgb(0, 0, 0)
                    });

                    Items.AmmobarAccent = Esp:Create( "Frame" , {
                        Parent = Items.Ammobar;
                        Name = "\0";
                        Position = dim2(0, 1, 0, 1);
                        BorderColor3 = rgb(0, 0, 0);
                        Size = dim2(1, -2, 1, -2);
                        BorderSizePixel = 0;
                        BackgroundColor3 = rgb(255, 255, 255)
                    });

                    Items.AmmobarFade = Esp:Create( "Frame" , {
                        Parent = Items.Ammobar;
                        Name = "\0";
                        Position = dim2(0, 1, 0, 1);
                        BorderColor3 = rgb(0, 0, 0);
                        Size = dim2(1, -2, 1, -2);
                        BorderSizePixel = 0;
                        BackgroundColor3 = rgb(0, 0, 0)
                    });

                    Items.AmmobarGradient = Esp:Create( "UIGradient" , {
                        Enabled = true;
                        Parent = Items.AmmobarAccent;
                        Rotation = 90;
                        Color = rgbseq{rgbkey(0, rgb(0, 255, 0)), rgbkey(0.5, rgb(255, 125, 0)), rgbkey(1, rgb(255, 0, 0))}
                    });

                    Items.AmmobarText = Esp:Create( "TextLabel", {
                        FontFace = Fonts.Verdana;
                        TextColor3 = rgb(255, 255, 255);
                        BorderColor3 = rgb(0, 0, 0);
                        Parent = Esp.Cache; -- Items.AmmobarTextsLeft
                        Name = "\0";
                        BackgroundTransparency = 1;
                        Size = dim2(0, 0, 0, 0);
                        BorderSizePixel = 0;
                        AutomaticSize = Enum.AutomaticSize.XY;
                        TextSize = 11;
                        BackgroundColor3 = rgb(255, 255, 255)
                    });

                    Esp:Create( "UIStroke", {
                        Parent = Items.AmmobarText;
                        LineJoinMode = Enum.LineJoinMode.Miter
                    });
                --

                -- Texts
                    Items.Text = Esp:Create( "TextLabel", {
                        FontFace = Fonts.Verdana;
                        TextColor3 = rgb(255, 255, 255);
                        BorderColor3 = rgb(0, 0, 0);
                        Parent = Esp.Cache;
                        Name = "Left";
                        Text = player.Name;
                        BackgroundTransparency = 1;
                        Size = dim2(1, 0, 0, 0);
                        BorderSizePixel = 0;
                        AutomaticSize = Enum.AutomaticSize.XY;
                        TextSize = 11;
                        BackgroundColor3 = rgb(255, 255, 255)
                    });

                    Esp:Create( "UIStroke", {
                        Parent = Items.Text;
                        LineJoinMode = Enum.LineJoinMode.Miter
                    });

                    Items.Distance = Esp:Create( "TextLabel", {
                        LayoutOrder = 5,
                        FontFace = Fonts.Verdana;
                        TextColor3 = rgb(255, 255, 255);
                        BorderColor3 = rgb(0, 0, 0);
                        Parent = Esp.Cache;
                        Name = "Left";
                        BackgroundTransparency = 1;
                        Size = dim2(1, 0, 0, 0);
                        BorderSizePixel = 0;
                        AutomaticSize = Enum.AutomaticSize.XY;
                        TextSize = 11;
                        BackgroundColor3 = rgb(255, 255, 255)
                    });

                    Esp:Create( "UIStroke", {
                        Parent = Items.Distance;
                        LineJoinMode = Enum.LineJoinMode.Miter
                    });

                    Items.Weapon = Esp:Create( "TextLabel", {
                        LayoutOrder = -5,
                        FontFace = Fonts.Verdana;
                        TextColor3 = rgb(255, 255, 255);
                        BorderColor3 = rgb(0, 0, 0);
                        Parent = Esp.Cache;
                        Name = "Left";
                        BackgroundTransparency = 1;
                        Size = dim2(1, 0, 0, 0);
                        BorderSizePixel = 0;
                        AutomaticSize = Enum.AutomaticSize.XY;
                        TextSize = 11;
                        Text = "[" .. tostring(Data.Info.Character and Data.Info.Character:FindFirstChildOfClass("Tool") or "None") .. "]",
                        BackgroundColor3 = rgb(255, 255, 255)
                    });

                    Esp:Create( "UIStroke", {
                        Parent = Items.Weapon;
                        LineJoinMode = Enum.LineJoinMode.Miter
                    });
                -- 
            end
            
            local AmmoConnection, MagConnection = nil, nil
            local Ammo_Debounce = false;
            local Mag_Debounce = false;

            Data.ToolAdded = LPH_NO_VIRTUALIZE(function(item)
                if not item or not item:IsA("Tool") then 
                    if AmmoConnection then
                        AmmoConnection:Disconnect()
                        AmmoConnection = nil
                    end

                    if MagConnection then
                        MagConnection:Disconnect()
                        MagConnection = nil
                    end

                    return 
                end 

                local exists = Data.Info.Character:FindFirstChild(item.Name) 
                if not exists then
                    exists = "None"
                end
                Items["Weapon"].Text = "[" .. tostring(exists) .. "]"
                
                if item:FindFirstChild("Setting") then
                    if AmmoConnection then
                        AmmoConnection:Disconnect()
                        AmmoConnection = nil
                    end

                    if MagConnection then
                        MagConnection:Disconnect()
                        MagConnection = nil
                    end

                    local mag, ammo = item:WaitForChild("Mag", 1), item:WaitForChild("Ammo", 1)

                    if mag and ammo then
                        MagConnection = item.Mag:GetPropertyChangedSignal("Value"):Connect(function()
                            if Mag_Debounce then return end
                            Mag_Debounce = true
                            Data.AmmoChanged(item)
                            task.delay(.1, function()
                                Mag_Debounce = false
                            end)
                        end)

                        AmmoConnection = item.Ammo:GetPropertyChangedSignal("Value"):Connect(function()            
                            if Ammo_Debounce then return end
                            Ammo_Debounce = true
                            Data.AmmoChanged(item)
                            task.delay(.1, function()
                                Ammo_Debounce = false
                            end)
                        end)
                    end
                end

                --[[pcall(function()
                    Items["Weapon"].Parent = exists and Items["Holder"] or Esp.Cache
                end)]]

                -- Refresh
            end)

            Data.HealthChanged = LPH_NO_VIRTUALIZE(function(Value)
                if not MiscOptions.Healthbar then 
                    return 
                end 

                local Humanoid = Data.Info.Humanoid
                local Multiplier = Value / Data.Info.Humanoid.MaxHealth
                local isHorizontal = MiscOptions.Healthbar_Position == "Top" or MiscOptions.Healthbar_Position == "Bottom"

                local Color = MiscOptions.Healthbar_Low.Color:Lerp(MiscOptions.Healthbar_Medium.Color, Multiplier)
                local Color_2 = Color:Lerp(MiscOptions.Healthbar_High.Color, Multiplier)

                if MiscOptions.Healthbar_Number then 
                    if Items.HealthbarText.Parent == Esp.Cache then 
                        Options.Healthbar = MiscOptions.Healthbar_Position 
                        Options.Healthbar_Number = true
                    end
                end 

                if Multiplier>=1 then
                    Items.HealthbarFade.Visible = false
                else
                    Items.HealthbarFade.Visible = true
                end

                if MiscOptions.Healthbar_Tween then  
                    local Health = Data.Info.Health
                    
                    Esp:Tween(Items.HealthbarFade, {
                        Size = dim2(isHorizontal and 1 - Multiplier or 1, isHorizontal and -2 or -2, isHorizontal and 1 or 1 - Multiplier, -2),
                        Position = dim2(isHorizontal and Multiplier or 0, 1, 0, 1)
                    }, TweenInfo.new(MiscOptions.Healthbar_Easing_Speed, Enum.EasingStyle[MiscOptions.Healthbar_EasingStyle], Enum.EasingDirection[MiscOptions.Healthbar_EasingDirection], 0, false, 0))
                    Esp:Tween(Items.HealthbarText, {
                        Position = dim2(isHorizontal and Multiplier or 0, isHorizontal and -(Items.HealthbarText.TextBounds.X / 2) or 0, isHorizontal and 0 or 1 - Multiplier, 0), 
                        TextColor3 = Color_2
                    }, TweenInfo.new(MiscOptions.Healthbar_Easing_Speed, Enum.EasingStyle[MiscOptions.Healthbar_EasingStyle], Enum.EasingDirection[MiscOptions.Healthbar_EasingDirection], 0, false, 0))

                    task.spawn(function()
                        local Start = tick()
                        
                        while true do
                            if not Esp then 
                                break 
                            end 

                            local Elapsed = tick() - Start
                            local Alpha = math.clamp(Elapsed, 0, 1)

                            local Value = Esp:Lerp(
                                Data.Info.Health, 
                                Value, 
                                TweenService:GetValue(
                                    Alpha, 
                                    Enum.EasingStyle[MiscOptions.Healthbar_EasingStyle], 
                                    Enum.EasingDirection[MiscOptions.Healthbar_EasingDirection]
                                )
                            )   

                            Items.HealthbarText.Text = math.floor(Value)

                            if Elapsed >= MiscOptions.Healthbar_Easing_Speed then 
                                Data.Info.Health = Value 
                                break
                            end

                            task.wait()
                        end                            
                    end)
                else 
                    Items.HealthbarFade.Size = dim2(isHorizontal and 1 - Multiplier or 1, isHorizontal and -2 or -2, isHorizontal and 1 or 1 - Multiplier, -2)
                    Items.HealthbarFade.Position = dim2(isHorizontal and Multiplier or 0, 1, 0, 1)
                    
                    Items.HealthbarText.Text = math.floor(Value)
                    Items.HealthbarText.Position = dim2(isHorizontal and Multiplier or 0, isHorizontal and -(Items.HealthbarText.TextBounds.X / 2) or 0, isHorizontal and 0 or 1 - Multiplier, 0)
                    Items.HealthbarText.TextColor3 = Color_2
                end 
            end)

            Data.AmmoChanged = LPH_NO_VIRTUALIZE(function(Tool)
                if not MiscOptions.Ammobar then 
                    return 
                end 

                local AmmoPerMag, CurrentAmmo = 0, 0

                local Character = Data.Info.Character

                local IsGun = false;

                if Tool and Character:FindFirstChild(Tool.Name) and Tool:GetAttribute("Ammo") then
                    IsGun = true
                    AmmoPerMag = require(Tool:WaitForChild("Setting")).AmmoPerMag
                    CurrentAmmo = Tool:WaitForChild("Mag").Value
                end

                local Multiplier = CurrentAmmo / AmmoPerMag

                if AmmoPerMag == 0 and CurrentAmmo == 0 then
                    Multiplier = 1
                end

                local isHorizontal = MiscOptions.Ammobar_Position == "Top" or MiscOptions.Ammobar_Position == "Bottom"

                local Color = MiscOptions.Ammobar_Low.Color:Lerp(MiscOptions.Ammobar_Medium.Color, Multiplier)
                local Color_2 = Color:Lerp(MiscOptions.Ammobar_High.Color, Multiplier)

                if MiscOptions.Ammobar_Number then 
                    if Items.AmmobarText.Parent == Esp.Cache then 
                        Options.Ammobar = MiscOptions.Ammobar_Position 
                        Options.Ammobar_Number = true
                    end
                end 

                if Multiplier>=1 then
                    Items.AmmobarFade.Visible = false
                else
                    Items.AmmobarFade.Visible = true
                end

                if MiscOptions.Ammobar_Tween then  
                    local Ammo = Data.Info.Ammo
                    
                    Esp:Tween(Items.AmmobarFade, {
                        Size = dim2(isHorizontal and 1 - Multiplier or 1, isHorizontal and -2 or -2, isHorizontal and 1 or 1 - Multiplier, -2),
                        Position = dim2(isHorizontal and Multiplier or 0, 1, 0, 1)
                    }, TweenInfo.new(MiscOptions.Ammobar_Easing_Speed, Enum.EasingStyle[MiscOptions.Ammobar_EasingStyle], Enum.EasingDirection[MiscOptions.Ammobar_EasingDirection], 0, false, 0))
                    Esp:Tween(Items.AmmobarText, {
                        Position = dim2(isHorizontal and Multiplier or 0, isHorizontal and -(Items.AmmobarText.TextBounds.X / 2) or 0, isHorizontal and 0 or 1 - Multiplier, 0)
                    }, TweenInfo.new(MiscOptions.Ammobar_Easing_Speed, Enum.EasingStyle[MiscOptions.Ammobar_EasingStyle], Enum.EasingDirection[MiscOptions.Ammobar_EasingDirection], 0, false, 0))

                    task.spawn(function()
                        local Start = tick()
                        
                        while true do
                            if not Esp then 
                                break 
                            end 

                            local Elapsed = tick() - Start
                            local Alpha = math.clamp(Elapsed, 0, 1)

                            local Value = Esp:Lerp(
                                Data.Info.Ammo, 
                                CurrentAmmo, 
                                TweenService:GetValue(
                                    Alpha, 
                                    Enum.EasingStyle[MiscOptions.Ammobar_EasingStyle], 
                                    Enum.EasingDirection[MiscOptions.Ammobar_EasingDirection]
                                )
                            )   

                            Items.AmmobarText.Text = math.floor(Value) .. "/" .. AmmoPerMag

                            if Elapsed >= MiscOptions.Ammobar_Easing_Speed then 
                                Data.Info.Ammo = CurrentAmmo 
                                break
                            end

                            task.wait()
                        end                            
                    end)
                else 
                    Items.AmmobarFade.Size = dim2(isHorizontal and 1 - Multiplier or 1, isHorizontal and -2 or -2, isHorizontal and 1 or 1 - Multiplier, -2)
                    Items.AmmobarFade.Position = dim2(isHorizontal and Multiplier or 0, 1, 0, 1)
                    
                    Items.AmmobarText.Text = IsGun and CurrentAmmo .. "/".. AmmoPerMag or "N/A"
                    Items.AmmobarText.Position = dim2(isHorizontal and Multiplier or 0, isHorizontal and -(Items.AmmobarText.TextBounds.X / 2) or 0, isHorizontal and 0 or 1 - Multiplier, 0)
                    --Items.AmmobarText.TextColor3 = Color_2
                end 
            end)

            Data.RefreshDescendants = LPH_NO_VIRTUALIZE(function() 
                local Character = (typechar and player) or player.Character or player.CharacterAdded:Wait()
                local Humanoid = Character:FindFirstChild("Humanoid") or Character:WaitForChild( "Humanoid" )
                
                Data.Info.Character = typechar and player or Character
                Data.Info.Humanoid = Humanoid
                Data.Info.rootpart = Humanoid.RootPart

                Data:Connection(Humanoid.HealthChanged, Data.HealthChanged)
                Data:Connection(Character.ChildAdded, Data.ToolAdded)
                Data:Connection(Character.ChildAdded, function(v)
                    task.wait(0.1)
                    Data.AmmoChanged(v)
                end)
                Data:Connection(Character.ChildRemoved, Data.ToolAdded)
                Data:Connection(Character.ChildRemoved, Data.AmmoChanged)

                Data.ToolAdded(Character:FindFirstChildOfClass("Tool"))
                Data.AmmoChanged(Character:FindFirstChildOfClass("Tool"))
                Data.HealthChanged(Data.Info.Humanoid.Health)
            end)

            function Data:Destroy()
                if self.Connections then
                    for _, conn in ipairs(self.Connections) do
                        conn:Disconnect()
                    end
                    self.Connections = nil
                end

                pcall(function()
                    for i,v in self.Items do
                        v:Destroy()
                    end
                end)

                if Esp.Players[player] then 
                    Esp.Players[player] = nil
                end

                self.Info = nil
                self.Items = nil
                self.Drawings = nil
            end

            Data.RefreshDescendants()
            --[[Esp:Connection(Data.Info.Humanoid.HealthChanged, Data.HealthChanged)
            Data.HealthChanged(Data.Info.Humanoid.Health)
            Esp:Connection(Data.Info.Character.ChildAdded, Data.ToolAdded)
            Esp:Connection(Data.Info.Character.ChildRemoved, Data.ToolAdded)]]
            Data.CharacterAdded = Data:Connection(player.CharacterAdded, Data.RefreshDescendants)
            
            -- Recaching element holders that arent neccessary <- roblox calculates math for them even if they have no objects in them or invisible ;(
            for _,ItemParentor in {Items.Left, Items.Right, Items.Top, Items.Bottom} do  
                Data:Connection(ItemParentor.ChildAdded, function(child)
                    task.wait(0.1)

                    if ItemParentor.Parent == nil then 
                        return 
                    end

                    ItemParentor.Parent = Items.Holder
                end)

                Data:Connection(ItemParentor.ChildRemoved, function()
                    task.wait(.1)
                    if #ItemParentor:GetChildren() == 0 then
                        if ItemParentor.Parent == nil then 
                            return 
                        end 

                        ItemParentor.Parent = Esp.Cache
                    end 
                end)
            end     

            for _,HealthHolder in {"Right", "Left"} do
                local Parent = Items["HealthbarTexts" .. HealthHolder]

                Data:Connection(Parent.ChildAdded, function()
                    task.wait(.1)

                    if Parent.Parent == nil then 
                        return 
                    end

                    Parent.Parent = Items[HealthHolder]
                end)    

                Data:Connection(Parent.ChildRemoved, function()
                    task.wait(.1)
                    if #Parent:GetChildren() == 0 then
                        if Parent.Parent == nil then 
                            return 
                        end 

                        Parent.Parent = Esp.Cache
                    end 
                end)
            end 

            for _,AmmoHolder in {"Right", "Left"} do
                local Parent = Items["AmmobarTexts" .. AmmoHolder]

                Data:Connection(Parent.ChildAdded, function()
                    task.wait(.1)

                    if Parent.Parent == nil then 
                        return 
                    end

                    Parent.Parent = Items[AmmoHolder]
                end)    

                Data:Connection(Parent.ChildRemoved, function()
                    task.wait(.1)
                    if #Parent:GetChildren() == 0 then
                        if Parent.Parent == nil then 
                            return 
                        end 

                        Parent.Parent = Esp.Cache
                    end 
                end)
            end 

            Esp.Players[ player.Name ] = Data

            return Data
        end

        Esp.Update = LPH_NO_VIRTUALIZE(function() -- IMPORTANT! 
            if not Esp then 
                return 
            end 

            if Options.Enabled == false then
                return 
            end 

            for _,Data in Esp.Players do
                if not Data.Info then
                    continue 
                end 
            
                local Character = Data.Info.Character

                if not Character then 
                    continue 
                end 

                local Humanoid = Data.Info.Humanoid 

                if not Humanoid then
                    continue 
                end 

                if not (Character or Humanoid) then 
                    continue 
                end 
                
                local Items = Data and Data.Items 

                if not Items then 
                    continue 
                end 

                local BoxSize, BoxPos, OnScreen, Distance = Esp:BoxSolve(Humanoid.RootPart)
                local Holder = Items["Holder"]

                if Holder.Visible ~= OnScreen then 
                    Holder.Visible = OnScreen
                end 

                if not OnScreen then
                    continue
                end 

                if Distance > MiscOptions["Render_Distance"] and Holder.Visible then 
                    Holder.Visible = false 
                    continue 
                end 

                local Pos = dim_offset(BoxPos.X, BoxPos.Y)
                if Pos ~= Holder.Position then 
                    Holder.Position = Pos
                end 
                
                local Size = dim2(0, BoxSize.X, 0, BoxSize.Y)
                if Size ~= Holder.Size then 
                    Holder.Size = Size
                end 

                local DistanceLabel = Items.Distance
                local Text = tostring( math.round(Distance) )  .. "m"
                if DistanceLabel.Text ~= Text then 
                    DistanceLabel.Text = Text
                end 
                
                -- if Options["Box Fill"] and Options["Box Spin"] then 
                --     Items["Holder_gradient"].Rotation += Options["Box Spin Speed"] / 100
                -- end

                -- if Options["Box Gradient"] and Options["Box Gradient Spin"] then 
                --     Items["box_outline_gradient"].Rotation += Options["Box Gradient Spin Speed"] / 100
                -- end
            end
        end)
        
        Esp.RefreshElements = LPH_NO_VIRTUALIZE(function(key, value) -- IMPORTANT!
            for _,Data in Esp.Players do
                local Items = Data and Data.Items 

                -- These checks are so annoying
                if not Items then 
                    continue  
                end 

                if not Items.Holder then 
                    continue 
                end 

                if Items.Holder.Parent == nil then 
                    continue 
                end 

                if key == "Enabled" then
                    Items.Holder.Visible = value
                end 

                -- Boxes
                    if key == "BoxType" then
                        if not (Items.Box.Parent == Items.Holder or Items.Corners.Parent == Items.Holder) then 
                            continue
                        end 

                        local isCorner = value == "Corner"
                        Items.Box.Parent = isCorner and Esp.Cache or Items.Holder
                        Items.Corners.Parent = isCorner and Items.Holder or Esp.Cache
                    end 

                    if key == "Boxes" then 
                        local isCorner = Items.Corners.Parent == Items.Holder and true or false
                        local Enabled = value and Items.Holder or Esp.Cache

                        if isCorner then 
                            Items.Corners.Parent = Enabled
                        else 
                            Items.Box.Parent = Enabled
                        end
                    end 

                    if key == "Box Gradient 1" then 
                        local Color = rgbseq{
                            Items.BoxGradient.Color.Keypoints[1], 
                            rgbkey(1, value.Color)
                        }

                        for _,corner in Items.Corners:GetChildren() do 
                            corner:FindFirstChildOfClass("UIGradient").Color = Color
                        end     

                        Items.BoxGradient.Color = Color
                    end 
                    
                    if key == "Box Gradient 2" then 
                        local Color = rgbseq{
                            rgbkey(0, value.Color), 
                            Items.BoxGradient.Color.Keypoints[2]
                        }
                        
                        for _,corner in Items.Corners:GetChildren() do 
                            corner:FindFirstChildOfClass("UIGradient").Color = Color
                        end

                        Items.BoxGradient.Color = Color
                    end 

                    if key == "Box Gradient Rotation" then 
                        Items.BoxGradient.Rotation = value
                    end 

                    if key == "Box Fill" then 
                        Items.Holder.BackgroundTransparency = value and 0 or 1
                    end

                    if key == "Box Fill 1" then 
                        local Path = Items.HolderGradient
                        Path.Transparency = numseq{
                            numkey(0, 1 - value.Transparency), 
                            Path.Transparency.Keypoints[2]
                        };

                        Path.Color = rgbseq{
                            rgbkey(0, value.Color), 
                            Path.Color.Keypoints[2]
                        }
                    end 

                    if key == "Box Fill 2" then 
                        local Path = Items.HolderGradient
                        Path.Transparency = numseq{
                            Path.Transparency.Keypoints[1],
                            numkey(1, 1 - value.Transparency)
                        };

                        Path.Color = rgbseq{
                            Path.Color.Keypoints[1],
                            rgbkey(1, value.Color)
                        };
                    end 

                    if key == "Box Fill Rotation" then 
                        Items.HolderGradient.Rotation = value
                    end 
                -- 

                -- Bars 
                    if key == "Healthbar" then 
                        if Items.Healthbar.Parent == nil then 
                            continue
                        end 

                        Items.Healthbar.Parent = value and Items[Items.Healthbar.Name] or Esp.Cache  
                        Items.HealthbarText.Parent = (Items.HealthbarText.Parent ~= Esp.Cache and value) and Items["HealthbarTexts" .. Items.Healthbar.Name] or Esp.Cache  
                    end 

                    if key == "Healthbar_Position" then 
                        local isEnabled = not (Items.Healthbar.Parent == Esp.Cache)

                        if Items.Healthbar.Parent == nil then 
                            return 
                        end 

                        Items.Healthbar.Parent = isEnabled and Items[value] or Esp.Cache
                        Items.Healthbar.Name = value -- This is super gay
                        Items.HealthbarText.Parent = isEnabled and value and Items.HealthbarText.Parent ~= Esp.Cache and Items["HealthbarTexts" .. Items.Healthbar.Name] or Esp.Cache

                        if value == "Bottom" or value == "Top" then 
                            Items.HealthbarGradient.Rotation = 0 
                        else 
                            Items.HealthbarGradient.Rotation = 90
                        end 

                        Data.HealthChanged(Data.Info.Humanoid.Health)
                    end 
                    
                    if key == "Healthbar_Number" then  
                        if Items.Healthbar.Parent == Esp.Cache then 
                            continue
                        end 

                        local Parent = Items["HealthbarTexts" .. Items.Healthbar.Name]
                        
                        Items.HealthbarText.Parent = value and Parent or Esp.Cache
                    end

                    if key == "Healthbar_Low" then 
                        local Color = rgbseq{
                            Items.HealthbarGradient.Color.Keypoints[1], 
                            Items.HealthbarGradient.Color.Keypoints[2], 
                            rgbkey(1, value.Color)
                        }

                        Items.HealthbarGradient.Color = Color
                    end 

                    if key == "Healthbar_Medium" then 
                        local Color = rgbseq{
                            Items.HealthbarGradient.Color.Keypoints[1], 
                            rgbkey(0.5, value.Color), 
                            Items.HealthbarGradient.Color.Keypoints[3]
                        }

                        Items.HealthbarGradient.Color = Color
                    end

                    if key == "Healthbar_High" then 
                        local Color = rgbseq{
                            rgbkey(0, value.Color), 
                            Items.HealthbarGradient.Color.Keypoints[2], 
                            Items.HealthbarGradient.Color.Keypoints[3]
                        }

                        Items.HealthbarGradient.Color = Color
                    end

                    if key == "Healthbar_Thickness" then 
                        local Bar = Items.Healthbar
                        local isHorizontal = Bar.Parent == Items.Bottom or Bar.Parent == Items.Top

                        Bar.Size = dim2(0, value + 2, 0, value + 2)
                    end

                    if key == "Healthbar_Text_Size" then 
                        Items.HealthbarText.TextSize = value
                    end

                    if key == "Healthbar_Font" then 
                        Items.HealthbarText.FontFace = ESPFonts[value]
                    end
                -- 

                -- Ammo Bar
                    if key == "Ammobar" then 
                        if Items.Ammobar.Parent == nil then 
                            continue
                        end 

                        Items.Ammobar.Parent = value and Items[Items.Ammobar.Name] or Esp.Cache  
                        Items.AmmobarText.Parent = (Items.AmmobarText.Parent ~= Esp.Cache and value) and Items["AmmobarTexts" .. Items.Ammobar.Name] or Esp.Cache  
                    end 

                    if key == "Ammobar_Position" then 
                        local isEnabled = not (Items.Ammobar.Parent == Esp.Cache)

                        if Items.Ammobar.Parent == nil then 
                            return 
                        end 

                        Items.Ammobar.Parent = isEnabled and Items[value] or Esp.Cache
                        Items.Ammobar.Name = value -- This is super gay
                        Items.AmmobarText.Parent = isEnabled and value and Items.AmmobarText.Parent ~= Esp.Cache and Items["AmmobarTexts" .. Items.Ammobar.Name] or Esp.Cache

                        if value == "Bottom" or value == "Top" then 
                            Items.AmmobarGradient.Rotation = 0 
                        else 
                            Items.AmmobarGradient.Rotation = 90
                        end 

                        if Data.Info.Character then
                            Data.AmmoChanged(Data.Info.Character:FindFirstChild("Tool"))
                        end
                    end 
                    
                    if key == "Ammobar_Number" then  
                        if Items.Ammobar.Parent == Esp.Cache then 
                            continue
                        end 

                        local Parent = Items["AmmobarTexts" .. Items.Ammobar.Name]
                        
                        Items.AmmobarText.Parent = value and Parent or Esp.Cache
                    end

                    if key == "Ammobar_Low" then 
                        local Color = rgbseq{
                            Items.AmmobarGradient.Color.Keypoints[1], 
                            Items.AmmobarGradient.Color.Keypoints[2], 
                            rgbkey(1, value.Color)
                        }

                        Items.AmmobarGradient.Color = Color
                    end 

                    if key == "Ammobar_Medium" then 
                        local Color = rgbseq{
                            Items.AmmobarGradient.Color.Keypoints[1], 
                            rgbkey(0.5, value.Color), 
                            Items.AmmobarGradient.Color.Keypoints[3]
                        }

                        Items.AmmobarGradient.Color = Color
                    end

                    if key == "Ammobar_High" then 
                        local Color = rgbseq{
                            rgbkey(0, value.Color), 
                            Items.AmmobarGradient.Color.Keypoints[2], 
                            Items.AmmobarGradient.Color.Keypoints[3]
                        }

                        Items.AmmobarGradient.Color = Color
                    end

                    if key == "Ammobar_Thickness" then 
                        local Bar = Items.Ammobar
                        local isHorizontal = Bar.Parent == Items.Bottom or Bar.Parent == Items.Top

                        Bar.Size = dim2(0, value + 2, 0, value + 2)
                    end

                    if key == "Ammobar_Text_Size" then 
                        Items.AmmobarText.TextSize = value
                    end

                    if key == "Ammobar_Text_Color" then 
                        Items.AmmobarText.TextColor3 = value
                    end

                    if key == "Ammobar_Font" then 
                        Items.AmmobarText.FontFace = ESPFonts[value]
                    end
                --
                
                -- Texts
                    local Text;
                    local Match;
                    if string.match(key, "Name") then 
                        Text = Items.Text
                        Match = "Name"
                    elseif string.match(key, "Distance") then 
                        Text = Items.Distance
                        Match = "Distance"
                    elseif string.match(key, "Weapon") then 
                        Text = Items.Weapon
                        Match = "Weapon"
                    end 

                    if Text then 
                        if key == Match .. "_Text" then  
                            if Text.Parent == nil then 
                                continue
                            end

                            Text.Parent = value and Items[Text.Name .. "Texts"] or Esp.Cache
                        end 

                        if key == Match .. "_Text_Position" then 
                            local isEnabled = not (Text.Parent == Esp.Cache)

                            if Text.Parent == nil then 
                                return 
                            end 

                            Text.Parent = isEnabled and Items[value .. "Texts"] or Esp.Cache
                            Text.Name = tostring(value) -- This is super gay

                            if value == "Top" or value == "Bottom" then 
                                Text.AutomaticSize = Enum.AutomaticSize.Y 
                                Text.TextXAlignment = Enum.TextXAlignment.Center
                            else 
                                Text.AutomaticSize = Enum.AutomaticSize.XY 
                                Text.TextXAlignment = Enum.TextXAlignment[value == "Right" and "Left" or "Right"]
                            end     
                        end 

                        if key == Match .. "_Text_Color" then 
                            Text.TextColor3 = value.Color
                        end 

                        if key == Match .. "_Text_Font" then 
                            Text.FontFace = ESPFonts[value]
                        end 

                        if key == Match .. "_Text_Size" then 
                            Text.TextSize = value
                        end
                    end 
                -- 
            end 
        end);  
        
        function Esp.Unload() 
            for _,player in Players:GetPlayers() do 
                Esp.RemovePlayer(player)
            end

            for _,connection in Esp.Connections do 
                connection:Disconnect() 
                connection = nil
            end 
            
            if Esp.Loop then 
                RunService:UnbindFromRenderStep("Run Loop")
                Esp.Loop = nil
            end 

            Esp.Cache:Destroy() 
            Esp.ScreenGui:Destroy()

            getgenv().Esp = nil
        end 

        function Esp.RemovePlayer(player)
            local Path = Esp.Players[player.Name]
            
            if Path then
                Path:Destroy()
            end
        end 
    end

    for _,player in Players:GetPlayers() do 
        if player == Players.LocalPlayer then continue end
        Esp.CreateObject(player)
    end 

    Esp:Connection(Players.PlayerRemoving, Esp.RemovePlayer)
    Esp:Connection(Players.PlayerAdded, function(player)
        Esp.CreateObject(player)
        for index,value in MiscOptions do 
            Options[index] = value -- gotta trigger that new index
        end 
    end)

    Esp.Loop = RunService:BindToRenderStep("Run Loop", 0, Esp.Update)

    for index,value in MiscOptions do 
        Options[index] = value -- gotta trigger that new index
    end
end

-- beware of somewhat horrible code
do -- Library
    -- Services
    local Players = cloneref(game:GetService("Players"))
    local UserInputService = cloneref(game:GetService("UserInputService"))
    local HttpService = cloneref(game:GetService("HttpService"))
    local TweenService = cloneref(game:GetService("TweenService"))
    local RunService = cloneref(game:GetService("RunService"))
    local Workspace = cloneref(game:GetService("Workspace"))
    
    -- Variables
    local LocalPlayer = Players.LocalPlayer
    local Camera = Workspace.CurrentCamera
    local Mouse = LocalPlayer:GetMouse()

    -- Globals
    local FromRGB = Color3.fromRGB
    local FromHSV = Color3.fromHSV
    local FromHex = Color3.fromHex

    local RGBSequence = ColorSequence.new
    local RGBSequenceKeypoint = ColorSequenceKeypoint.new

    local NumSequence = NumberSequence.new
    local NumSequenceKeypoint = NumberSequenceKeypoint.new

    local UDim2New = UDim2.new
    local UDimNew = UDim.new
    local UDim2FromScale = UDim2.fromScale
    local Vector2New = Vector2.new

    local InstanceNew = Instance.new

    local MathClamp = math.clamp
    local MathFloor = math.floor
    local MathAbs = math.abs
    local MathSin = math.sin
    local MathRad = math.rad
    local MathMax = math.max
    local MathMin = math.min

    local TableInsert = table.insert
    local TableFind = table.find
    local TableUnpack = table.unpack
    local TableRemove = table.remove
    local TableConcat = table.concat
    local TableClone = table.clone

    local StringFormat = string.format
    local StringFind = string.find
    local StringGSub = string.gsub
    local StringLower = string.lower

    local CFrameNew = CFrame.new
    local CFrameAngles = CFrame.Angles
    local Vector3New = Vector3.new

    local RectNew = Rect.new

    local IsMobile = UserInputService.TouchEnabled and (not UserInputService.KeyboardEnabled) or false

    getgenv().Options = { }

    -- Library
    Library = {
        Theme = nil,

        MenuKeybind = tostring(Enum.KeyCode.Z), 
        Flags = { },

        Tween = {
            Time = 0.3,
            Style = Enum.EasingStyle.Cubic,
            Direction = Enum.EasingDirection.Out
        },

        Folders = {
            Directory = "valary",
            Configs = "valary/SouthBronxConfigs",
            Assets = "valary/Assets",
            Themes = "valary/Themes"
        },

        Images = { -- you're welcome to reupload the images and replace it with your own links
            ["Saturation"] = {"Saturation.png", "https://github.com/sametexe001/images/blob/main/saturation.png?raw=true" },
            ["Value"] = { "Value.png", "https://github.com/sametexe001/images/blob/main/value.png?raw=true" },
            ["Hue"] = { "Hue.png", "https://github.com/sametexe001/images/blob/main/horizontalhue.png?raw=true" },
            ["Checkers"] = { "Checkers.png", "https://github.com/sametexe001/images/blob/main/checkers.png?raw=true" },
            ["Radar"] = {"Radar.png", "https://raw.githubusercontent.com/ValarySoftworks/Assets/refs/heads/main/Radar.png?raw=true"},
            ["DiagonalLine"] = {"DiagonalLine.png", "https://raw.githubusercontent.com/ValarySoftworks/Assets/refs/heads/main/DiagonalLine.png?raw=true"},
            ["AdsClick"] = {"AdsClick.png", "https://raw.githubusercontent.com/ValarySoftworks/Assets/refs/heads/main/AdsClick.png?raw=true"},
            ["Forward"] = {"Forward.png", "https://raw.githubusercontent.com/ValarySoftworks/Assets/refs/heads/main/Forward.png?raw=true"},
            ["Skull"] = {"Skull.png", "https://raw.githubusercontent.com/ValarySoftworks/Assets/refs/heads/main/Skull.png?raw=true"},
            ["MultipleCogs"] = {"MultipleCogs.png", "https://raw.githubusercontent.com/ValarySoftworks/Assets/refs/heads/main/MultipleCogs.png?raw=true"},
            ["Tune"] = {"Tune.png", "https://raw.githubusercontent.com/ValarySoftworks/Assets/refs/heads/main/Tune.png?raw=true"},
            ["Wrench"] = {"Wrench.png", "https://raw.githubusercontent.com/ValarySoftworks/Assets/refs/heads/main/Wrench.png?raw=true"},
            ["IdCard"] = {"IdCard.png", "https://raw.githubusercontent.com/ValarySoftworks/Assets/refs/heads/main/IdCard.png?raw=true"},
            ["AccountCircle"] = {"AccountCircle.png", "https://raw.githubusercontent.com/ValarySoftworks/Assets/refs/heads/main/AccountCircle.png?raw=true"},
            ["GroupSearch"] = {"GroupSearch.png", "https://raw.githubusercontent.com/ValarySoftworks/Assets/refs/heads/main/GroupSearch.png?raw=true"},
            ["USDChip"] = {"USDChip.png", "https://raw.githubusercontent.com/ValarySoftworks/Assets/refs/heads/main/USDChip.png?raw=true"},
            ["Wrist"] = {"Wrist.png", "https://raw.githubusercontent.com/ValarySoftworks/Assets/refs/heads/main/Wrist.png?raw=true"},
            ["PlayerUtilties"] = {"PlayerUtilties.png", "https://raw.githubusercontent.com/ValarySoftworks/Assets/refs/heads/main/PlayerUtilties.png?raw=true"},
            ["CreditCard"] = {"CreditCard.png", "https://raw.githubusercontent.com/ValarySoftworks/Assets/refs/heads/main/CreditCard.png?raw=true"},
            ["JumpToElement"] = {"JumpToElement.png", "https://raw.githubusercontent.com/ValarySoftworks/Assets/refs/heads/main/JumpToElement.png?raw=true"},
            ["Apartment"] = {"Apartment.png", "https://raw.githubusercontent.com/ValarySoftworks/Assets/refs/heads/main/Apartment.png?raw=true"},
            ["MoneySymbol"] = {"MoneySymbol.png", "https://raw.githubusercontent.com/ValarySoftworks/Assets/refs/heads/main/MoneySymbol.png?raw=true"},
            ["TravelExplore"] = {"TravelExplore.png", "https://raw.githubusercontent.com/ValarySoftworks/Assets/refs/heads/main/TravelExplore.png?raw=true"},
            ["Scrambler"] = {"Scrambler.png", "https://raw.githubusercontent.com/ValarySoftworks/Assets/refs/heads/main/Scrambler.png?raw=true"},
            ["Info"] = {"Info.png", "https://raw.githubusercontent.com/ValarySoftworks/Assets/refs/heads/main/Info.png?raw=true"},
            ["CarInfo"] = {"CarInfo.png", "https://raw.githubusercontent.com/ValarySoftworks/Assets/refs/heads/main/CarInfo.png?raw=true"},
            ["AutoManifacturing"] = {"AutoManifacturing.png", "https://raw.githubusercontent.com/ValarySoftworks/Assets/refs/heads/main/AutoManifacturing.png?raw=true"},
            ["MoneyBag"] = {"MoneyBag.png", "https://raw.githubusercontent.com/ValarySoftworks/Assets/refs/heads/main/MoneyBag.png?raw=true"},
            ["Bolt"] = {"Bolt.png", "https://raw.githubusercontent.com/ValarySoftworks/Assets/refs/heads/main/Bolt.png?raw=true"},
            ["RetroController"] = {"RetroController.png", "https://raw.githubusercontent.com/ValarySoftworks/Assets/refs/heads/main/RetroController.png?raw=true"},
            ["NewController30px"] = {"NewController30px.png", "https://raw.githubusercontent.com/ValarySoftworks/Assets/refs/heads/main/NewController30px.png?raw=true"},
            ["Home"] = {"Home.png", "https://raw.githubusercontent.com/ValarySoftworks/Assets/refs/heads/main/Home.png?raw=true"},
            ["Lock"] = {"Lock.png", "https://raw.githubusercontent.com/ValarySoftworks/Assets/refs/heads/main/Lock.png?raw=true"},
            ["EncryptedOff"] = {"EncryptedOff.png", "https://raw.githubusercontent.com/ValarySoftworks/Assets/refs/heads/main/EncryptedOff.png?raw=true"},
            ["DeployedCodeAccount"] = {"DeployedCodeAccount.png", "https://raw.githubusercontent.com/ValarySoftworks/Assets/refs/heads/main/DeployedCodeAccount.png?raw=true"},
            ["IdentityPlatform"] = {"IdentityPlatform.png", "https://raw.githubusercontent.com/ValarySoftworks/Assets/refs/heads/main/IdentityPlatform.png?raw=true"},
            ["DataLossPrevention"] = {"DataLossPrevention.png", "https://raw.githubusercontent.com/ValarySoftworks/Assets/refs/heads/main/DataLossPrevention.png?raw=true"},
            ["CarGear"] = {"CarGear.png", "https://raw.githubusercontent.com/ValarySoftworks/Assets/refs/heads/main/CarGear.png?raw=true"},
            ["Groups"] = {"Groups.png", "https://raw.githubusercontent.com/ValarySoftworks/Assets/refs/heads/main/Groups.png?raw=true"},
            ["FolderEye"] = {"FolderEye.png", "https://raw.githubusercontent.com/ValarySoftworks/Assets/refs/heads/main/FolderEye.png?raw=true"},
            ["ZonePersonUrgent"] = {"ZonePersonUrgent.png", "https://raw.githubusercontent.com/ValarySoftworks/Assets/refs/heads/main/ZonePersonUrgent.png?raw=true"},
            ["HourglassEmpty"] = {"HourglassEmpty.png", "https://raw.githubusercontent.com/ValarySoftworks/Assets/refs/heads/main/HourglassEmpty.png?raw=true"},
            ["Bomb"] = {"Bomb.png", "https://raw.githubusercontent.com/ValarySoftworks/Assets/refs/heads/main/Bomb.png?raw=true"},
            ["Cyclone"] = {"Cyclone.png", "https://raw.githubusercontent.com/ValarySoftworks/Assets/refs/heads/main/Cyclone.png?raw=true"},
            ["GlobePublic"] = {"GlobePublic.png", "https://raw.githubusercontent.com/ValarySoftworks/Assets/refs/heads/main/GlobePublic.png?raw=true"},
            ["LightBulb"] = {"LightBulb.png", "https://raw.githubusercontent.com/ValarySoftworks/Assets/refs/heads/main/LightBulb.png?raw=true"},
            ["Cloud"] = {"Cloud.png", "https://raw.githubusercontent.com/ValarySoftworks/Assets/refs/heads/main/Cloud.png?raw=true"},
            ["Contrast"] = {"Contrast.png", "https://raw.githubusercontent.com/ValarySoftworks/Assets/refs/heads/main/Contrast.png?raw=true"},
            ["TrailShort"] = {"TrailShort.png", "https://raw.githubusercontent.com/ValarySoftworks/Assets/refs/heads/main/TrailShort.png?raw=true"},
            ["EyeTracking"] = {"EyeTracking.png", "https://raw.githubusercontent.com/ValarySoftworks/Assets/refs/heads/main/EyeTracking.png?raw=true"},
            ["ScreenRotation"] = {"ScreenRotation.png", "https://raw.githubusercontent.com/ValarySoftworks/Assets/refs/heads/main/ScreenRotation.png?raw=true"},
            ["QueryStats"] = {"QueryStats.png", "https://raw.githubusercontent.com/ValarySoftworks/Assets/refs/heads/main/QueryStats.png?raw=true"},
            ["CellTower"] = {"CellTower.png", "https://raw.githubusercontent.com/ValarySoftworks/Assets/refs/heads/main/CellTower.png?raw=true"},
            ["Battery"] = {"Battery.png", "https://raw.githubusercontent.com/ValarySoftworks/Assets/refs/heads/main/Battery.png?raw=true"},
            ["Servers"] = {"Servers.png", "https://raw.githubusercontent.com/ValarySoftworks/Assets/refs/heads/main/Servers.png?raw=true"},
            ["ShoppingCart"] = {"ShoppingCart.png", "https://raw.githubusercontent.com/ValarySoftworks/Assets/refs/heads/main/ShoppingCart.png?raw=true"},
            ["expand-arrows"] = {"expand-arrows.png", "https://raw.githubusercontent.com/ValarySoftworks/Assets/refs/heads/main/expand-arrows.png?raw=true"},
        },

        Friendly_Players = {}, Priority_Players = {}, Selected_Player = nil,

        -- Ignore below
        Pages = { },
        Sections = { },

        Connections = { },
        Threads = { },

        Themes = { },
        ThemeMap = { },
        ThemeItems = { },
        ThemeColorpickers = { },

        OpenFrames = { },

        CurrentPage = nil,

        SearchItems = { },

        SetFlags = { },

        UnnamedConnections = 0,
        UnnamedFlags = 0,

        Holder = nil,
        NotifHolder = nil,
        UnusedHolder = nil,
        MainFrame = nil,
        Font = nil,
        KeyList = nil,
    }

    local Keys = {
        ["Unknown"]           = "Unknown",
        ["Backspace"]         = "Back",
        ["Tab"]               = "Tab",
        ["Clear"]             = "Clear",
        ["Return"]            = "Return",
        ["Pause"]             = "Pause",
        ["Escape"]            = "Escape",
        ["Space"]             = "Space",
        ["QuotedDouble"]      = '"',
        ["Hash"]              = "#",
        ["Dollar"]            = "$",
        ["Percent"]           = "%",
        ["Ampersand"]         = "&",
        ["Quote"]             = "'",
        ["LeftParenthesis"]   = "(",
        ["RightParenthesis"]  = " )",
        ["Asterisk"]          = "*",
        ["Plus"]              = "+",
        ["Comma"]             = ",",
        ["Minus"]             = "-",
        ["Period"]            = ".",
        ["Slash"]             = "`",
        ["Three"]             = "3",
        ["Seven"]             = "7",
        ["Eight"]             = "8",
        ["Colon"]             = ":",
        ["Semicolon"]         = ";",
        ["LessThan"]          = "<",
        ["GreaterThan"]       = ">",
        ["Question"]          = "?",
        ["Equals"]            = "=",
        ["At"]                = "@",
        ["LeftBracket"]       = "LeftBracket",
        ["RightBracket"]      = "RightBracked",
        ["BackSlash"]         = "BackSlash",
        ["Caret"]             = "^",
        ["Underscore"]        = "_",
        ["Backquote"]         = "`",
        ["LeftCurly"]         = "{",
        ["Pipe"]              = "|",
        ["RightCurly"]        = "}",
        ["Tilde"]             = "~",
        ["Delete"]            = "Delete",
        ["End"]               = "End",
        ["KeypadZero"]        = "Keypad0",
        ["KeypadOne"]         = "Keypad1",
        ["KeypadTwo"]         = "Keypad2",
        ["KeypadThree"]       = "Keypad3",
        ["KeypadFour"]        = "Keypad4",
        ["KeypadFive"]        = "Keypad5",
        ["KeypadSix"]         = "Keypad6",
        ["KeypadSeven"]       = "Keypad7",
        ["KeypadEight"]       = "Keypad8",
        ["KeypadNine"]        = "Keypad9",
        ["KeypadPeriod"]      = "KeypadP",
        ["KeypadDivide"]      = "KeypadD",
        ["KeypadMultiply"]    = "KeypadM",
        ["KeypadMinus"]       = "KeypadM",
        ["KeypadPlus"]        = "KeypadP",
        ["KeypadEnter"]       = "KeypadE",
        ["KeypadEquals"]      = "KeypadE",
        ["Insert"]            = "Insert",
        ["Home"]              = "Home",
        ["PageUp"]            = "PageUp",
        ["PageDown"]          = "PageDown",
        ["RightShift"]        = "RightShift",
        ["LeftShift"]         = "LeftShift",
        ["RightControl"]      = "RightControl",
        ["LeftControl"]       = "LeftControl",
        ["LeftAlt"]           = "LeftAlt",
        ["RightAlt"]          = "RightAlt"
    }

    Library.__index = Library

    Library.Sections.__index = Library.Sections
    Library.Pages.__index = Library.Pages

    for Index, Value in Library.Folders do 
        if not isfolder(Value) then
            makefolder(Value)
        end
    end

    for Index, Value in Library.Images do 
        local ImageData = Value

        local ImageName = ImageData[1]
        local ImageLink = ImageData[2]
        
        if not isfile(Library.Folders.Assets .. "/" .. ImageName) then
            writefile(Library.Folders.Assets .. "/" .. ImageName, game:HttpGet(ImageLink))
        end
    end

    local Tween = { } do
        Tween.__index = Tween

        Tween.Create = LPH_NO_VIRTUALIZE(function(self, Item, Info, Goal, IsRawItem)
            Item = IsRawItem and Item or Item.Instance
            Info = Info or TweenInfo.new(Library.Tween.Time, Library.Tween.Style, Library.Tween.Direction)

            local NewTween = {
                Tween = TweenService:Create(Item, Info, Goal),
                Info = Info,
                Goal = Goal,
                Item = Item
            }

            NewTween.Tween:Play()

            setmetatable(NewTween, Tween)

            return NewTween
        end)

        Tween.GetProperty = LPH_NO_VIRTUALIZE(function(self, Item)
            Item = Item or self.Item 

            if Item:IsA("Frame") then
                return { "BackgroundTransparency" }
            elseif Item:IsA("TextLabel") or Item:IsA("TextButton") then
                return { "TextTransparency", "BackgroundTransparency" }
            elseif Item:IsA("ImageLabel") or Item:IsA("ImageButton") then
                return { "BackgroundTransparency", "ImageTransparency" }
            elseif Item:IsA("ScrollingFrame") then
                return { "BackgroundTransparency", "ScrollBarImageTransparency" }
            elseif Item:IsA("TextBox") then
                return { "TextTransparency", "BackgroundTransparency" }
            elseif Item:IsA("UIStroke") then 
                return { "Transparency" }
            end
        end)

        Tween.FadeItem = LPH_NO_VIRTUALIZE(function(self, Item, Property, Visibility, Speed)
            local Item = Item or self.Item 

            local OldTransparency = Item[Property]
            Item[Property] = Visibility and 1 or OldTransparency

            local NewTween = Tween:Create(Item, TweenInfo.new(Speed or Library.Tween.Time, Library.Tween.Style, Library.Tween.Direction), {
                [Property] = Visibility and OldTransparency or 1
            }, true)

            local Connection; Connection = Library:Connect(NewTween.Tween.Completed, function()
                if not Visibility then 
                    task.wait()
                    Item[Property] = OldTransparency
                    Connection["Connection"]:Disconnect(); Connection = nil
                end
            end)

            return NewTween
        end)

        Tween.Get = function(self)
            if not self.Tween then 
                return
            end

            return self.Tween, self.Info, self.Goal
        end

        Tween.Pause = function(self)
            if not self.Tween then 
                return
            end

            self.Tween:Pause()
        end

        Tween.Play = function(self)
            if not self.Tween then 
                return
            end

            self.Tween:Play()
        end

        Tween.Clean = function(self)
            if not self.Tween then 
                return
            end

            Tween:Pause()
            self = nil
        end
    end

    local Instances = { } do
        Instances.__index = Instances

        Instances.Create = function(self, Class, Properties)
            local NewItem = {
                Instance = InstanceNew(Class),
                Properties = Properties,
                Class = Class
            }

            setmetatable(NewItem, Instances)

            for Property, Value in NewItem.Properties do
                NewItem.Instance[Property] = Value
            end

            return NewItem
        end

        Instances.Border = function(self)
            if not self.Instance then 
                return
            end

            local Item = self.Instance
            local UIStroke = Instances:Create("UIStroke", {
                Parent = Item,
                Color = Library.Theme.Border,
                Thickness = 1,
                LineJoinMode = Enum.LineJoinMode.Miter
            })

            UIStroke:AddToTheme({Color = "Border"})

            return UIStroke
        end

        Instances.FadeItem = LPH_NO_VIRTUALIZE(function(self, Visibility, Speed)
            local Item = self.Instance

            if Visibility == true then 
                Item.Visible = true
            end

            local Descendants = Item:GetDescendants()
            TableInsert(Descendants, Item)

            local NewTween

            for Index, Value in Descendants do 
                local TransparencyProperty = Tween:GetProperty(Value)

                if not TransparencyProperty then 
                    continue
                end

                if type(TransparencyProperty) == "table" then 
                    for _, Property in TransparencyProperty do 
                        NewTween = Tween:FadeItem(Value, Property, not Visibility, Speed)
                    end
                else
                    NewTween = Tween:FadeItem(Value, TransparencyProperty, not Visibility, Speed)
                end
            end
        end)

        Instances.AddToTheme = function(self, Properties)
            if not self.Instance then 
                return
            end

            Library:AddToTheme(self, Properties)
        end

        Instances.ChangeItemTheme = function(self, Properties)
            if not self.Instance then 
                return
            end

            Library:ChangeItemTheme(self, Properties)
        end

        Instances.Connect = function(self, Event, Callback, Name)
            if not self.Instance then 
                return
            end

            if not self.Instance[Event] then 
                return
            end

            if Event == "MouseButton1Down" or Event == "MouseButton1Click" then 
                if IsMobile then 
                    Event = "TouchTap"
                end
            elseif Event == "MouseButton2Down" or Event == "MouseButton2Click" then 
                if IsMobile then
                    Event = "TouchLongPress"
                end
            end

            return Library:Connect(self.Instance[Event], Callback, Name)
        end

        Instances.Tween = function(self, Info, Goal)
            if not self.Instance then 
                return
            end

            return Tween:Create(self, Info, Goal)
        end

        Instances.Disconnect = function(self, Name)
            if not self.Instance then 
                return
            end

            return Library:Disconnect(Name)
        end

        Instances.Clean = function(self)
            if not self.Instance then 
                return
            end

            self.Instance:Destroy()
            self = nil
        end

        Instances.Tooltip = function(self, Text)
            if Text == nil or type(Text) ~= "string" then
                return
            end

            if not self.Instance then 
                return
            end

            local Gui = self.Instance

            local MouseLocation = UserInputService:GetMouseLocation()
            local RenderStepped

            local Newtooltip = Instances:Create("Frame", {
                Parent = Library.Holder.Instance,
                Name = "\0",
                BorderColor3 = FromRGB(0, 0, 0),
                BackgroundTransparency = 1,
                Position = UDim2New(0, MouseLocation.X, 0, MouseLocation.Y - 38),
                BorderSizePixel = 0,
                ZIndex = 2,
                AutomaticSize = Enum.AutomaticSize.XY,
                BackgroundColor3 = FromRGB(16, 18, 21)
            })  Newtooltip:AddToTheme({BackgroundColor3 = "Background"})

            local UIStroke = Instances:Create("UIStroke", {
                Parent = Newtooltip.Instance,
                Name = "\0",
                Color = FromRGB(32, 36, 42),
                Transparency = 1,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            })  UIStroke:AddToTheme({Color = "Border"})

            Instances:Create("UIPadding", {
                Parent = Newtooltip.Instance,
                Name = "\0",
                PaddingTop = UDimNew(0, 5),
                PaddingBottom = UDimNew(0, 5),
                PaddingRight = UDimNew(0, 5),
                PaddingLeft = UDimNew(0, 5)
            })

            local TooltipText = Instances:Create("TextLabel", {
                Parent = Newtooltip.Instance,
                Name = "\0",
                FontFace = Library.Font,
                TextColor3 = FromRGB(255, 255, 255),
                BorderColor3 = FromRGB(0, 0, 0),
                Text = Text,
                AutomaticSize = Enum.AutomaticSize.XY,
                BackgroundTransparency = 1,
                TextXAlignment = Enum.TextXAlignment.Left,
                BorderSizePixel = 0,
                ZIndex = 2,
                TextTransparency = 1,
                TextSize = 14,
                BackgroundColor3 = FromRGB(255, 255, 255)
            })

            Instances:Create("UICorner", {
                Parent = Newtooltip.Instance,
                Name = "\0",
                CornerRadius = UDimNew(0, 5)
            })

            Library:Connect(Gui.MouseEnter, function()
                Newtooltip:Tween(nil, {BackgroundTransparency = 0.15})
                TooltipText:Tween(nil, {TextTransparency = 0})
                UIStroke:Tween(nil, {Transparency = 0.4})

                RenderStepped = RunService.RenderStepped:Connect(LPH_NO_VIRTUALIZE(function()
                    MouseLocation = UserInputService:GetMouseLocation()
                    Newtooltip:Tween(nil, {Position = UDim2New(0, MouseLocation.X, 0, MouseLocation.Y - 38)})
                end))
            end)

            Library:Connect(Gui.MouseLeave, LPH_NO_VIRTUALIZE(function()
                Newtooltip:Tween(nil, {BackgroundTransparency = 1})
                TooltipText:Tween(nil, {TextTransparency = 1})
                UIStroke:Tween(nil, {Transparency = 1})

                if RenderStepped then 
                    RenderStepped:Disconnect()
                    RenderStepped = nil
                end
            end))
        end

        Instances.MakeDraggable = function(self)
            if not self.Instance then 
                return
            end

            local Gui = self.Instance

            local Dragging = false 
            local DragStart
            local StartPosition 

            local InputChanged

            local Set = function(Input)
                local DragDelta = Input.Position - DragStart
                self:Tween(TweenInfo.new(0.16, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2New(StartPosition.X.Scale, StartPosition.X.Offset + DragDelta.X, StartPosition.Y.Scale, StartPosition.Y.Offset + DragDelta.Y)})
            end

            self:Connect("InputBegan", LPH_NO_VIRTUALIZE(function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                    Dragging = true

                    DragStart = Input.Position
                    StartPosition = Gui.Position

                    if InputChanged then
                        return
                    end

                    InputChanged = Input.Changed:Connect(function()
                        if Input.UserInputState == Enum.UserInputState.End then
                            Dragging = false

                            InputChanged:Disconnect()
                            InputChanged = nil
                        end
                    end)
                end
            end))

            Library:Connect(UserInputService.InputChanged, LPH_NO_VIRTUALIZE(function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then
                    if Dragging then
                        Set(Input)
                    end
                end
            end))

            return Dragging
        end

        Instances.MakeResizeable = function(self, Minimum, Maximum)
            if not self.Instance then 
                return
            end

            local Gui = self.Instance

            local Resizing = false 
            local Start = UDim2New()
            local Delta = UDim2New()
            local ResizeMax = Gui.Parent.AbsoluteSize - Gui.AbsoluteSize

            local ResizeButton = Instances:Create("ImageButton", {
				Parent = Gui,
                Image = "rbxassetid://7368471234",
				AnchorPoint = Vector2New(1, 1),
				BorderColor3 = FromRGB(0, 0, 0),
				Size = UDim2New(0, 9, 0, 9),
				Position = UDim2New(1, -4, 1, -4),
                Name = "\0",
				BorderSizePixel = 0,
				BackgroundTransparency = 1,
                ZIndex = 5,
				AutoButtonColor = false,
                Visible = true,
			})  ResizeButton:AddToTheme({ImageColor3 = "Accent"})

            local InputChanged

            ResizeButton:Connect("InputBegan", function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then

                    Resizing = true

                    Start = Gui.Size - UDim2New(0, Input.Position.X, 0, Input.Position.Y)

                    if InputChanged then
                        return
                    end

                    InputChanged = Input.Changed:Connect(function()
                        if Input.UserInputState == Enum.UserInputState.End then
                            Resizing = false

                            InputChanged:Disconnect()
                            InputChanged = nil
                        end
                    end)
                end
            end)

            Library:Connect(UserInputService.InputChanged, function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then
                    if Resizing then
                        ResizeMax = Maximum or Gui.Parent.AbsoluteSize - Gui.AbsoluteSize

                        Delta = Start + UDim2New(0, Input.Position.X, 0, Input.Position.Y)
                        Delta = UDim2New(0, math.clamp(Delta.X.Offset, Minimum.X, ResizeMax.X), 0, math.clamp(Delta.Y.Offset, Minimum.Y, ResizeMax.Y))

                        Tween:Create(Gui, TweenInfo.new(0.17, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = Delta}, true)
                    end
                end
            end)

            return Resizing
        end

        Instances.OnHover = function(self, Function)
            if not self.Instance then 
                return
            end
            
            return Library:Connect(self.Instance.MouseEnter, Function)
        end

        Instances.OnHoverLeave = function(self, Function)
            if not self.Instance then 
                return
            end
            
            return Library:Connect(self.Instance.MouseLeave, Function)
        end
    end

    local CustomFont = { } do
        function CustomFont:New(Name, Weight, Style, Data)
            --[[if isfile(Library.Folders.Assets .. "/" .. Name .. ".json") then
                return Font.new(getcustomasset(Library.Folders.Assets .. "/" .. Name .. ".json"))
            end]]

            if not isfile(Library.Folders.Assets .. "/" .. Name .. ".ttf") then 
                writefile(Library.Folders.Assets .. "/" .. Name .. ".ttf", game:HttpGet(Data.Url))
            end

            local FontData = {
                name = Name,
                faces = { {
                    name = "Regular",
                    weight = Weight,
                    style = Style,
                    assetId = getcustomasset(Library.Folders.Assets .. "/" .. Name .. ".ttf")
                } }
            }

            writefile(Library.Folders.Assets .. "/" .. Name .. ".json", HttpService:JSONEncode(FontData))
            return Font.new(getcustomasset(Library.Folders.Assets .. "/" .. Name .. ".json"))
        end

        function CustomFont:Get(Name)
            if isfile(Library.Folders.Assets .. "/" .. Name .. ".json") then
                return Font.new(getcustomasset(Library.Folders.Assets .. "/" .. Name .. ".json"))
            end
        end

        CustomFont:New("Inter", 200, "Regular", {
            Url = "https://github.com/sametexe001/luas/raw/refs/heads/main/fonts/InterSemibold.ttf"
        })

        Library.Font = CustomFont:Get("Inter")
    end

    local Themes = {
        ["Old Default"] = {
            ["Background"] = FromRGB(16, 18, 21),
            ["Inline"] = FromRGB(22, 25, 29),
            ["Shadow"] = FromRGB(0, 0, 0),
            ["Text"] = FromRGB(255, 255, 255),
            ["Image"] = FromRGB(255, 255, 255),
            ["Dark Gradient"] = FromRGB(211, 211, 211),
            ["Inactive Text"] = FromRGB(185, 185, 185),
            ["Element"] = FromRGB(34, 39, 45),
            ["Accent"] = FromRGB(196, 231, 255),
            ["Border"] = FromRGB(32, 36, 42)
        },

        ["Preset"] = {
            ["Background"] = FromRGB(14, 14, 16),       -- Darker background
            ["Inline"] = FromRGB(22, 22, 24),           -- Slightly lighter inline panels
            ["Shadow"] = FromRGB(0, 0, 0),              -- Keep strong shadow
            ["Text"] = FromRGB(255, 255, 255),          -- Bright white text
            ["Image"] = FromRGB(255, 255, 255),         -- White icons/images
            ["Dark Gradient"] = FromRGB(211, 211, 211),    -- Subtle dark gradient
            ["Inactive Text"] = FromRGB(150, 150, 150), -- Softer gray for inactive text
            ["Element"] = FromRGB(33, 32, 35),          -- Element background matches panel
            ["Accent"] = FromRGB(236,23,23),          -- Blue accent (like "bronx")
            ["Border"] = FromRGB(40, 44, 52)            -- Slightly lighter border for contrast
        },

        ["Bitch Bot"] = {
            ["Background"] = FromRGB(42, 42, 42),      -- from #2a2a2a
            ["Inline"] = FromRGB(30, 30, 30),          -- from #1e1e1e
            ["Shadow"] = FromRGB(20, 20, 20),          -- from #141414
            ["Text"] = FromRGB(255, 255, 255),         -- from #ffffff
            ["Image"] = FromRGB(255, 255, 255),         -- from #7e48a3
            ["Dark Gradient"] = FromRGB(195, 195, 195),-- from #c3c3c3
            ["Inactive Text"] = FromRGB(180, 180, 180),-- from #b4b4b4
            ["Element"] = FromRGB(52, 52, 52),         -- from #343434
            ["Accent"] = FromRGB(126, 72, 163),        -- from #7e48a3
            ["Border"] = FromRGB(20, 20, 20)           -- from #141414
        },

        ["Roobet"] = {
            ["Background"] = Color3.fromRGB(18, 20, 32),      -- Dark purple base
            ["Inline"] = Color3.fromRGB(32, 34, 54),          -- Slightly lighter panel purple
            ["Shadow"] = Color3.fromRGB(0, 0, 0),             -- Black shadow
            ["Text"] = Color3.fromRGB(255, 255, 255),         -- White text
            ["Image"] = Color3.fromRGB(255, 255, 255),        -- White icons
            ["Dark Gradient"] = Color3.fromRGB(211, 211, 211),   -- Deeper gradient shade
            ["Inactive Text"] = Color3.fromRGB(160, 160, 180),-- Muted gray-purple text
            ["Element"] = Color3.fromRGB(40, 42, 70),         -- Button/element background
            ["Accent"] = Color3.fromRGB(255, 204, 0),         -- Roobet yellow accent (#FFCC00)
            ["Border"] = Color3.fromRGB(50, 52, 80)           -- Subtle purple borders
        };

        ["Twitch"] = {
            ["Background"] = Color3.fromRGB(20, 20, 25),
            ["Inline"] = Color3.fromRGB(30, 30, 40),
            ["Shadow"] = Color3.fromRGB(0, 0, 0),
            ["Text"] = Color3.fromRGB(255, 255, 255),
            ["Image"] = Color3.fromRGB(255, 255, 255),
            ["Dark Gradient"] = Color3.fromRGB(211, 211, 211),
            ["Inactive Text"] = Color3.fromRGB(170, 170, 180),
            ["Element"] = Color3.fromRGB(40, 40, 60),
            ["Accent"] = Color3.fromRGB(142, 91, 218), -- Twitch purple
            ["Border"] = Color3.fromRGB(60, 60, 90)
        },

        ["Halloween"] = {
            ["Background"] = FromRGB(11, 10, 9),
            ["Inline"] = FromRGB(23, 18, 16),
            ["Shadow"] = FromRGB(253, 133, 21),
            ["Text"] = FromRGB(198, 198, 198),
            ["Image"] = FromRGB(201, 201, 201),
            ["Dark Gradient"] = FromRGB(211, 202, 195),
            ["Inactive Text"] = FromRGB(179, 179, 179),
            ["Element"] = FromRGB(42, 32, 26),
            ["Accent"] = FromRGB(253, 133, 21),
            ["Border"] = FromRGB(42, 35, 32)
        },

        ["Aqua"] = {
            ["Background"] = FromRGB(19, 21, 23),
            ["Inline"] = FromRGB(31, 35, 39),
            ["Shadow"] = FromRGB(0, 0, 0),
            ["Text"] = FromRGB(245, 245, 245),
            ["Image"] = FromRGB(255, 255, 255),
            ["Dark Gradient"] = FromRGB(211, 211, 211),
            ["Inactive Text"] = FromRGB(185, 185, 185),
            ["Element"] = FromRGB(58, 66, 77),
            ["Accent"] = FromRGB(31, 106, 181),
            ["Border"] = FromRGB(48, 56, 63)
        },

        ["One Tap"] = {
            ["Background"] = FromRGB(49, 49, 49),      -- from #313131
            ["Inline"] = FromRGB(30, 30, 30),          -- from #1e1e1e
            ["Shadow"] = FromRGB(0, 0, 0),             -- from #000000
            ["Text"] = FromRGB(245, 245, 245),         -- from #f5f5f5
            ["Image"] = FromRGB(255, 255, 255),        -- from #ffffff
            ["Dark Gradient"] = FromRGB(211, 211, 211),-- from #d3d3d3
            ["Inactive Text"] = FromRGB(185, 185, 185),-- from #b9b9b9
            ["Element"] = FromRGB(24, 24, 24),         -- from #181818
            ["Accent"] = FromRGB(237, 170, 0),         -- from #edaa00
            ["Border"] = FromRGB(62, 62, 62)           -- from #3e3e3e
        },
    }

    Library.Theme = TableClone(Themes["Preset"])
    Library.Themes = Themes

    if not isfile(Library.Folders.Directory .. "/AutoLoadConfig (do not modify this).json") then
        writefile(Library.Folders.Directory .. "/AutoLoadConfig (do not modify this).json", "")
    end

    if not isfile(Library.Folders.Directory .. "/AutoLoadTheme (do not modify this).json") then
        writefile(Library.Folders.Directory .. "/AutoLoadTheme (do not modify this).json", "")
    end

    Library.Holder = Instances:Create("ScreenGui", {
        Parent = gethui(),
        Name = "\0",
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        DisplayOrder = 2,
        ResetOnSpawn = false
    })

    Library.UnusedHolder = Instances:Create("ScreenGui", {
        Parent = gethui(),
        Name = "\0",
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        Enabled = false,
        ResetOnSpawn = false
    })

    Library.NotifHolder = Instances:Create("Frame", {
        Parent = Library.Holder.Instance,
        Name = "\0",
        BorderColor3 = FromRGB(0, 0, 0),
        AnchorPoint = Vector2New(1, 0),
        BackgroundTransparency = 1,
        Position = UDim2New(1, 0, 0, 0),
        Size = UDim2New(0, 0, 1, 0),
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundColor3 = FromRGB(255, 255, 255)
    })

    Instances:Create("UIPadding", {
        Parent = Library.NotifHolder.Instance,
        Name = "\0",
        PaddingBottom = UDimNew(0, 15),
        PaddingTop = UDimNew(0, 15),
        PaddingRight = UDimNew(0, 15)
    })

    Instances:Create("UIListLayout", {
        Parent = Library.NotifHolder.Instance,
        Name = "\0",
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        Padding = UDimNew(0, 10)
    })

    Library.Unload = function(self)
        for Index, Value in self.Connections do 
            Value.Connection:Disconnect()
        end

        for Index, Value in self.Threads do 
            coroutine.close(Value)
        end

        if self.Holder then 
            self.Holder:Clean()
        end

        Library = nil 
        getgenv().Library = nil
    end

    Library.GetImage = function(self, Image)
        local ImageData = self.Images[Image]

        if not ImageData then 
            return
        end

        return getcustomasset(self.Folders.Assets .. "/" .. ImageData[1])
    end

    Library.Round = function(self, Number, Float)
        local Multiplier = 1 / (Float or 1)
        return MathFloor(Number * Multiplier) / Multiplier
    end

    Library.Thread = function(self, Function)
        local NewThread = coroutine.create(Function)
        
        coroutine.wrap(function()
            coroutine.resume(NewThread)
        end)()

        TableInsert(self.Threads, NewThread)

        return NewThread
    end
    
    Library.SafeCall = function(self, Function, ...)
        local Arguements = { ... }
        local Success, Result = false, nil

        task.spawn(function()
            Success, Result = pcall(Function, TableUnpack(Arguements))

            if not Success then
                Library:Notification({
                    Name = "Valary.gg | Error",
                    Description = "Error caught, please report it in the discord.\n"..Result,
                    Duration = 10,
                })

                return false
            end
        end)

        return Success
    end

    Library.Connect = function(self, Event, Callback, Name)
        Name = Name or StringFormat("Connection%s%s", self.UnnamedConnections + 1, HttpService:GenerateGUID(false))

        local NewConnection = {
            Event = Event,
            Callback = Callback,
            Name = Name,
            Connection = nil
        }

        Library:Thread(function()
            NewConnection.Connection = Event:Connect(Callback)
        end)

        TableInsert(self.Connections, NewConnection)
        return NewConnection
    end

    Library.Disconnect = function(self, Name)
        for _, Connection in self.Connections do 
            if Connection.Name == Name then
                Connection.Connection:Disconnect()
                break
            end
        end
    end

    Library.NextFlag = function(self)
        local FlagNumber = self.UnnamedFlags + 1
        return StringFormat("Flag Number %s %s", FlagNumber, HttpService:GenerateGUID(false))
    end

    Library.AddToTheme = function(self, Item, Properties)
        Item = Item.Instance or Item 

        local ThemeData = {
            Item = Item,
            Properties = Properties,
        }

        for Property, Value in ThemeData.Properties do
            if type(Value) == "string" then
                Item[Property] = self.Theme[Value]
            else
                Item[Property] = Value()
            end
        end

        TableInsert(self.ThemeItems, ThemeData)
        self.ThemeMap[Item] = ThemeData
    end

    Library.GetConfig = function(self)
        local Config = { } 

        local Success, Result = Library:SafeCall(function()
            for Index, Value in Library.Flags do 
                if type(Value) == "table" and Value.Key then
                    Config[Index] = {Key = tostring(Value.Key), Mode = Value.Mode}
                elseif type(Value) == "table" and Value.Color then
                    Config[Index] = {Color = "#" .. Value.Color, Alpha = Value.Alpha}
                else
                    Config[Index] = Value
                end
            end
        end)

        return HttpService:JSONEncode(Config)
    end

    Library.LoadConfig = function(self, Config)
        local Decoded = HttpService:JSONDecode(Config)

        local Success, Result = Library:SafeCall(function()
            for Index, Value in Decoded do 
                local SetFunction = Library.SetFlags[Index]

                if not SetFunction then
                    continue
                end

                if type(Value) == "table" and Value.Key then 
                    SetFunction(Value)
                elseif type(Value) == "table" and Value.Color then
                    SetFunction(Value.Color, Value.Alpha)
                else
                    SetFunction(Value)
                end
            end
        end)

        return Success, Result
    end

    Library.GetDarkerColor = function(self, Color)
        local Hue, Saturation, Value = Color:ToHSV()
        return FromHSV(Hue, Saturation, Value / 1.35)
    end

    Library.DeleteConfig = function(self, Config)
        if isfile(Library.Folders.Configs .. "/" .. Config) then 
            delfile(Library.Folders.Configs .. "/" .. Config)
            Library:Notification({
                Name = "Success",
                Description = "Succesfully deleted config: ".. Config .. ".json",
                Duration = 5,
                Icon = "116339777575852",
                IconColor = FromRGB(52, 255, 164)
            })
        end
    end

    Library.SaveConfig = function(self, Config)
        if isfile(Library.Folders.Configs .. "/" .. Config .. ".json") then
            writefile(Library.Folders.Configs .. "/" .. Config .. ".json", Library:GetConfig())
            Library:Notification({
                Name = "Success",
                Description = "Succesfully saved config: ".. Config .. ".json",
                Duration = 5,
                Icon = "116339777575852",
                IconColor = FromRGB(52, 255, 164)
            })
        end
    end

    Library.RefreshConfigsList = function(self, Element)
        local CurrentList = { }
        local List = { }

        local ConfigFolderName = StringGSub(Library.Folders.Configs, Library.Folders.Directory .. "/", "")

        for Index, Value in listfiles(Library.Folders.Configs) do
            local FileName = StringGSub(Value, Library.Folders.Directory .. "\\" .. ConfigFolderName .. "\\", "")
            List[Index] = FileName
        end

        local IsNew = #List ~= CurrentList

        if not IsNew then
            for Index = 1, #List do
                if List[Index] ~= CurrentList[Index] then
                    IsNew = true
                    break
                end
            end
        else
            CurrentList = List
            Element:Refresh(CurrentList)
        end
    end

    Library.ChangeItemTheme = LPH_NO_VIRTUALIZE(function(self, Item, Properties)
        Item = Item.Instance or Item

        if not self.ThemeMap[Item] then 
            return
        end

        self.ThemeMap[Item].Properties = Properties
        self.ThemeMap[Item] = self.ThemeMap[Item]
    end)

    Library.ChangeTheme = LPH_NO_VIRTUALIZE(function(self, Theme, Color)
        self.Theme[Theme] = Color

        if Theme == "Accent" and Window then
            Window:SetText(string.format(
                '<font color="rgb(255,255,255)">valary.</font><font color="rgb(%d,%d,%d)">gg</font> | %s',
                Color.R*255,
                Color.G*255,
                Color.B*255,
                Game_Name_MarketPlaceService
            ))

            Watermark:SetText(string.format('<font color="rgb(255,255,255)">valary.</font><font color="rgb(%d,%d,%d)">gg</font> - %s - %s',Color.R*255,Color.G*255,Color.B*255, Game_Name_MarketPlaceService, os.date("%b. %d %Y, %X")))
        end

        for _, Item in self.ThemeItems do
            for Property, Value in Item.Properties do
                if type(Value) == "string" and Value == Theme then
                    Item.Item[Property] = Color
                elseif type(Value) == "function" then
                    Item.Item[Property] = Value()
                end
            end
        end
    end)

    Library.IsMouseOverFrame = LPH_NO_VIRTUALIZE(function(self, Frame, XOffset, YOffset)
        Frame = Frame.Instance
        XOffset = XOffset or 0 
        YOffset = YOffset or 0

        local MousePosition = Vector2New(Mouse.X + XOffset, Mouse.Y + YOffset)

        return MousePosition.X >= Frame.AbsolutePosition.X and MousePosition.X <= Frame.AbsolutePosition.X + Frame.AbsoluteSize.X 
        and MousePosition.Y >= Frame.AbsolutePosition.Y and MousePosition.Y <= Frame.AbsolutePosition.Y + Frame.AbsoluteSize.Y
    end)

    Library.GetTheme = LPH_NO_VIRTUALIZE(function(self)
        local Config = { } 

        local Success, Result = Library:SafeCall(function()
            for Index, Value in Library.Flags do 
                if type(Value) == "table" and Value.Color and StringFind(Index, "Theme") then
                    Config[Index] = {Color = "#" .. Value.Color, Alpha = Value.Alpha}
                end
            end
        end)

        return HttpService:JSONEncode(Config)
    end)

    Library.LoadTheme = LPH_NO_VIRTUALIZE(function(self, Config)
        local Decoded = HttpService:JSONDecode(Config)

        local Success, Result = Library:SafeCall(function()
            for Index, Value in Decoded do 
                local SetFunction = Library.SetFlags[Index]

                if not SetFunction then
                    continue
                end

                if type(Value) == "table" and Value.Color and StringFind(Index, "Theme") then
                    SetFunction(Value.Color, Value.Alpha)
                end
            end
        end)

        return Success, Result
    end)

    Library.DeleteTheme = function(self, Config)
        if isfile(Library.Folders.Themes .. "/" .. Config) then 
            delfile(Library.Folders.Themes .. "/" .. Config)
            Library:Notification({
                Name = "Success",
                Description = "Succesfully deleted config: ".. Config .. ".json",
                Duration = 5,
                Icon = "116339777575852",
                IconColor = FromRGB(52, 255, 164)
            })
        end
    end

    Library.SaveTheme = function(self, Config)
        if isfile(Library.Folders.Themes .. "/" .. Config .. ".json") then
            writefile(Library.Folders.Themes .. "/" .. Config .. ".json", Library:GetTheme())
            Library:Notification({
                Name = "Success",
                Description = "Succesfully saved config: ".. Config .. ".json",
                Duration = 5,
                Icon = "116339777575852",
                IconColor = FromRGB(52, 255, 164)
            })
        end
    end

    Library.RefreshThemesList = function(self, Element)
        local CurrentList = { }
        local List = { }

        local ConfigFolderName = StringGSub(Library.Folders.Themes, Library.Folders.Directory .. "/", "")

        for Index, Value in listfiles(Library.Folders.Themes) do
            local FileName = StringGSub(Value, Library.Folders.Directory .. "\\" .. ConfigFolderName .. "\\", "")
            List[Index] = FileName
        end

        local IsNew = #List ~= CurrentList

        if not IsNew then
            for Index = 1, #List do
                if List[Index] ~= CurrentList[Index] then
                    IsNew = true
                    break
                end
            end
        else
            CurrentList = List
            Element:Refresh(CurrentList)
        end
    end

    Library.GetLighterColor = LPH_NO_VIRTUALIZE(function(self, Color, Increment)
        local Hue, Saturation, Value = Color:ToHSV()
        return FromHSV(Hue, Saturation, Value * Increment)
    end)

    local Components = { } do
        Components.Toggle = function(Data)
            local Toggle = { 
                Value = false,
                Flag = Data.Flag
            }

            local Items = { } do
                Items["Toggle"] = Instances:Create("TextButton", {
                    Parent = Data.Parent.Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    AutoButtonColor = false,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Size = UDim2New(1, 0, 0, 20),
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                local Color = Data.Color or Color3.new(1,1,1)

                Items["Text"] = Instances:Create("TextLabel", {
                    Parent = Items["Toggle"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = Color,
                    TextTransparency = 0.5,
                    Text = Data.Name,
                    AutomaticSize = Enum.AutomaticSize.X,
                    Size = UDim2New(0, 0, 0, 15),
                    AnchorPoint = Vector2New(0, 0.5),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 0, 0.5, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  if not Data.Color then Items["Text"]:AddToTheme({TextColor3 = "Text"}) end

                Items["Indicator"] = Instances:Create("Frame", {
                    Parent = Items["Toggle"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(1, 0.5),
                    Position = UDim2New(1, 0, 0.5, 0),
                    Size = UDim2New(0, 20, 0, 20),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(34, 39, 45)
                })  Items["Indicator"]:AddToTheme({BackgroundColor3 = "Element"})

                Instances:Create("UICorner", {
                    Parent = Items["Indicator"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })

                Items["Inline"] = Instances:Create("Frame", {
                    Parent = Items["Indicator"].Instance,
                    Name = "\0",
                    Size = UDim2New(1, -4, 1, -4),
                    Position = UDim2New(0, 2, 0, 2),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(34, 39, 45)
                })  Items["Inline"]:AddToTheme({BackgroundColor3 = "Element"})

                Instances:Create("UICorner", {
                    Parent = Items["Inline"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })

                Instances:Create("UIGradient", {
                    Parent = Items["Inline"].Instance,
                    Name = "\0",
                    Rotation = 84,
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(211, 211, 211))}
                }):AddToTheme({Color = function()
                    return RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, Library.Theme["Dark Gradient"])}
                end})

                Items["Check"] = Instances:Create("ImageLabel", {
                    Parent = Items["Inline"].Instance,
                    Name = "\0",
                    Visible = true,
                    ScaleType = Enum.ScaleType.Fit,
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, -2, 1, -2),
                    AnchorPoint = Vector2New(0.5, 0.5),
                    Image = "rbxassetid://116339777575852",
                    BackgroundTransparency = 1,
                    Position = UDim2New(0.5, 0, 0.5, 0),
                    ImageTransparency = 1,
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255),
                    ImageColor3 = FromRGB(0, 0, 0)
                })

                Items["SubElements"] = Instances:Create("Frame", {
                    Parent = Items["Toggle"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(1, 0),
                    BackgroundTransparency = 1,
                    Position = UDim2New(1, -24, 0, 0),
                    Size = UDim2New(0, 0, 1, 0),
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.X,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Instances:Create("UIListLayout", {
                    Parent = Items["SubElements"].Instance,
                    Name = "\0",
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Enum.HorizontalAlignment.Right,
                    Padding = UDimNew(0, 6),
                    SortOrder = Enum.SortOrder.LayoutOrder
                })
            end

            function Toggle:Get()
                return Toggle.Value
            end

            function Toggle:Set(Bool)
                Toggle.Value = Bool 
                Library.Flags[Toggle.Flag] = Bool

                if Bool then
                    Items["Indicator"]:ChangeItemTheme({BackgroundColor3 = "Accent"})
                    Items["Inline"]:ChangeItemTheme({BackgroundColor3 = "Accent"})

                    Items["Indicator"]:Tween(nil, {BackgroundColor3 = Library.Theme.Accent})
                    Items["Inline"]:Tween(nil, {BackgroundColor3 = Library.Theme.Accent})

                    Items["Check"]:Tween(nil, {ImageTransparency = 0})
                    Items["Text"]:Tween(nil, {TextTransparency = 0})
                else
                    Items["Indicator"]:ChangeItemTheme({BackgroundColor3 = "Element"})
                    Items["Inline"]:ChangeItemTheme({BackgroundColor3 = "Element"})

                    Items["Indicator"]:Tween(nil, {BackgroundColor3 = Library.Theme.Element})
                    Items["Inline"]:Tween(nil, {BackgroundColor3 = Library.Theme.Element})

                    Items["Check"]:Tween(nil, {ImageTransparency = 1})
                    Items["Text"]:Tween(nil, {TextTransparency = 0.5})
                end

                if Data.Callback then 
                    Library:SafeCall(Data.Callback, Bool)
                end
            end

            function Toggle:SetVisibility(Bool)
                Items["Toggle"].Instance.Visible = Bool
            end

            Items["Toggle"]:OnHover(function()
                if not Toggle.Value then
                    Items["Indicator"]:Tween(nil, {BackgroundColor3 = Library:GetLighterColor(Library.Theme.Element, 1.45)})
                    Items["Inline"]:Tween(nil, {BackgroundColor3 = Library:GetLighterColor(Library.Theme.Element, 1.45)})
                --[[else
                    Items["Indicator"]:Tween(nil, {BackgroundColor3 = Library:GetLighterColor(Library.Theme.Accent, 1.45)})
                    Items["Inline"]:Tween(nil, {BackgroundColor3 = Library:GetLighterColor(Library.Theme.Accent, 1.45)})]]
                end
            end)

            Items["Toggle"]:OnHoverLeave(function()
                if not Toggle.Value then
                    Items["Indicator"]:Tween(nil, {BackgroundColor3 = Library.Theme.Element})
                    Items["Inline"]:Tween(nil, {BackgroundColor3 = Library.Theme.Element})
                else
                    Items["Indicator"]:Tween(nil, {BackgroundColor3 = Library.Theme.Accent})
                    Items["Inline"]:Tween(nil, {BackgroundColor3 = Library.Theme.Accent})
                end
            end)

            getgenv().Options[Toggle.Flag] = Toggle

            local SearchData = {
                Name = Data.Name,
                Item = Items["Toggle"]
            }

            local PageSearchData = Library.SearchItems[Data.Page]

            if not PageSearchData then 
                return 
            end

            TableInsert(PageSearchData, SearchData)

            Items["Toggle"]:Connect("MouseButton1Down", function()
                Toggle:Set(not Toggle.Value)
            end)

            if Data.Default then 
                Toggle:Set(Data.Default)
            end

            Library.SetFlags[Toggle.Flag] = function(Value)
                Toggle:Set(Value)
            end

            return Toggle, Items 
        end

        Components.Dropdown = function(Data)
            local Dropdown = {
                Value = { },
                Flag = Data.Flag,
                Type = "Dropdown",
                Name = Data.Name,
                IsOpen = false,
                Options = { }
            }

            local Items = { } do
                Items["Dropdown"] = Instances:Create("Frame", {
                    Parent = Data.Parent.Instance,
                    Name = "\0",
                    BackgroundTransparency = 1,
                    Size = UDim2New(1, 0, 0, 47),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Items["Text"] = Instances:Create("TextLabel", {
                    Parent = Items["Dropdown"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(255, 255, 255),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = Data.Name,
                    AutomaticSize = Enum.AutomaticSize.X,
                    BackgroundTransparency = 1,
                    Size = UDim2New(0, 0, 0, 15),
                    BorderSizePixel = 0,
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Text"]:AddToTheme({TextColor3 = "Text"})

                Items["RealDropdown"] = Instances:Create("TextButton", {
                    Parent = Items["Dropdown"].Instance,
                    Text = "", 
                    AutoButtonColor = false,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(0, 1),
                    Position = UDim2New(0, 0, 1, 0),
                    Size = UDim2New(1, 0, 0, 25),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(34, 39, 45)
                })  Items["RealDropdown"]:AddToTheme({BackgroundColor3 = "Element"})

                Instances:Create("UIGradient", {
                    Parent = Items["RealDropdown"].Instance,
                    Name = "\0",
                    Rotation = 84,
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(211, 211, 211))}
                }):AddToTheme({Color = function()
                    return RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, Library.Theme["Dark Gradient"])}
                end})

                Instances:Create("UICorner", {
                    Parent = Items["RealDropdown"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })

                Items["Value"] = Instances:Create("TextLabel", {
                    Parent = Items["RealDropdown"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(255, 255, 255),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "--",
                    AutomaticSize = Enum.AutomaticSize.X,
                    Size = UDim2New(0, 0, 0, 15),
                    AnchorPoint = Vector2New(0, 0.5),
                    Position = UDim2New(0, 8, 0.5, 0),
                    BackgroundTransparency = 1,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    BorderSizePixel = 0,
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Value"]:AddToTheme({TextColor3 = "Text"})

                Items["OpenIcon"] = Instances:Create("ImageLabel", {
                    Parent = Items["RealDropdown"].Instance,
                    Name = "\0",
                    ImageColor3 = FromRGB(196, 231, 255),
                    ScaleType = Enum.ScaleType.Fit,
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 20, 0, 20),
                    AnchorPoint = Vector2New(1, 0.5),
                    Image = "rbxassetid://114252321536924",
                    BackgroundTransparency = 1,
                    Position = UDim2New(1, -3, 0.5, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["OpenIcon"]:AddToTheme({ImageColor3 = "Accent"})

                Items["OptionHolder"] = Instances:Create("TextButton", {
                    Parent = Library.UnusedHolder.Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    AutoButtonColor = false,
                    Size = UDim2New(1, 0, 0, 125),
                    AutomaticSize = Enum.AutomaticSize.None,
                    Position = UDim2New(0, 0, 0, 0),
                    Visible = false,
                    BorderSizePixel = 0,
                    ZIndex = 5,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(22, 25, 29)
                })  Items["OptionHolder"]:AddToTheme({BackgroundColor3 = "Inline"})

                Instances:Create("UIGradient", {
                    Parent = Items["OptionHolder"].Instance,
                    Name = "\0",
                    Rotation = 84,
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(211, 211, 211))}
                }):AddToTheme({Color = function()
                    return RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, Library.Theme["Dark Gradient"])}
                end})

                Instances:Create("UIStroke", {
                    Parent = Items["OptionHolder"].Instance,
                    Name = "\0",
                    Color = FromRGB(32, 36, 42),
                    Transparency = 0.4000000059604645,
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                }):AddToTheme({Color = "Border"})

                Instances:Create("UICorner", {
                    Parent = Items["OptionHolder"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 5)
                })

                Items["Holder"] = Instances:Create("ScrollingFrame", {
                    Parent = Items["OptionHolder"].Instance,
                    Name = "\0",
                    Active = true,
                    AutomaticCanvasSize = Enum.AutomaticSize.Y,
                    ScrollBarThickness = 2,
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, -8, 1, -46),
                    CanvasSize = UDim2New(0, 0, 0, 0),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 0, 0, 38),
                    BorderSizePixel = 0,
                    ScrollBarImageColor3 = Library.Theme.Border,
                    BottomImage = "rbxassetid://123813291349824",
                    TopImage = "rbxassetid://123813291349824",
                    MidImage = "rbxassetid://123813291349824",
                    ZIndex = 5,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Holder"]:AddToTheme({ScrollBarImageColor3 = "Border"})

                Instances:Create("UIListLayout", {
                    Parent = Items["Holder"].Instance,
                    Name = "\0",
                    Padding = UDimNew(0, 2),
                    SortOrder = Enum.SortOrder.LayoutOrder
                })

                Instances:Create("UIPadding", {
                    Parent = Items["Holder"].Instance,
                    Name = "\0",
                    PaddingTop = UDimNew(0, 8),
                    PaddingBottom = UDimNew(0, 8),
                    PaddingRight = UDimNew(0, 8),
                    PaddingLeft = UDimNew(0, 8)
                })

                Items["Search"] = Instances:Create("Frame", {
                    Parent = Items["OptionHolder"].Instance,
                    Name = "\0",
                    Size = UDim2New(1, -16, 0, 25),
                    Position = UDim2New(0, 8, 0, 8),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 5,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(22, 25, 29)
                })  Items["Search"]:AddToTheme({BackgroundColor3 = "Inline"})

                Instances:Create("UIGradient", {
                    Parent = Items["Search"].Instance,
                    Name = "\0",
                    Rotation = 84,
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(211, 211, 211))}
                }):AddToTheme({Color = function()
                    return RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, Library.Theme["Dark Gradient"])}
                end})

                Instances:Create("UICorner", {
                    Parent = Items["Search"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 5)
                })

                Instances:Create("UIStroke", {
                    Parent = Items["Search"].Instance,
                    Name = "\0",
                    Color = FromRGB(32, 36, 42),
                    Transparency = 0.4000000059604645,
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                }):AddToTheme({Color = "Border"})

                Items["SearchIcon"] = Instances:Create("ImageLabel", {
                    Parent = Items["Search"].Instance,
                    Name = "\0",
                    ScaleType = Enum.ScaleType.Fit,
                    ImageTransparency = 0.5,
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 20, 0, 20),
                    AnchorPoint = Vector2New(0, 0.5),
                    Image = "rbxassetid://71924825350727",
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 8, 0.5, 0),
                    ZIndex = 5,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["SearchIcon"]:AddToTheme({ImageColor3 = "Image"})

                Items["Input"] = Instances:Create("TextBox", {
                    Parent = Items["Search"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    AnchorPoint = Vector2New(0, 0.5),
                    PlaceholderColor3 = FromRGB(185, 185, 185),
                    PlaceholderText = "search",
                    TextSize = 14,
                    Size = UDim2New(1, -45, 0, 15),
                    ClipsDescendants = true,
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    ZIndex = 5,
                    Position = UDim2New(0, 35, 0.5, 0),
                    BackgroundTransparency = 1,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextColor3 = FromRGB(255, 255, 255),
                    ClearTextOnFocus = false,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
            end

            Items["RealDropdown"]:OnHover(function()
                Items["RealDropdown"]:Tween(nil, {BackgroundColor3 = Library:GetLighterColor(Library.Theme.Element, 1.45)})
            end)

            Items["RealDropdown"]:OnHoverLeave(function()
                Items["RealDropdown"]:Tween(nil, {BackgroundColor3 = Library.Theme.Element})
            end)

            function Dropdown:Get()
                return Dropdown.Value
            end

            function Dropdown:Set(Option)
                if Data.Multi then
                    if type(Option) ~= "table" then
                        return
                    end

                    Dropdown.Value = Option
                    Library.Flags[Dropdown.Flag] = Option

                    for Index, Value in Option do 
                        local OptionData = Dropdown.Options[Value]
                        
                        if not OptionData then 
                            return
                        end

                        OptionData.Selected = true
                        OptionData:Toggle("Active")
                    end

                    Items["Value"].Instance.Text = TableConcat(Option, ", ")
                else
                    if not Dropdown.Options[Option] then 
                        return
                    end

                    local OptionData = Dropdown.Options[Option]

                    Dropdown.Value = OptionData.Name
                    Library.Flags[Dropdown.Flag] = OptionData.Name

                    for Index, Value in Dropdown.Options do 
                        if Value ~= OptionData then
                            Value.Selected = false 
                            Value:Toggle("Inactive")
                        else
                            Value.Selected = true 
                            Value:Toggle("Active")
                        end
                    end

                    Items["Value"].Instance.Text = OptionData.Name
                end

                if Data.Callback then 
                    Library:SafeCall(Data.Callback, Dropdown.Value)
                end
            end

            function Dropdown:AddOption(Option)
                local OptionButton = Instances:Create("TextButton", {
                    Parent = Items["Holder"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    AutoButtonColor = false,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Size = UDim2New(1, -5, 0, 25),
                    ZIndex = 5,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(16, 18, 21)
                })  OptionButton:AddToTheme({BackgroundColor3 = "Background"})

                local CheckImage = Instances:Create("ImageLabel", {
                    Parent = OptionButton.Instance,
                    Name = "\0",
                    ImageColor3 = FromRGB(196, 231, 255),
                    ScaleType = Enum.ScaleType.Fit,
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 18, 0, 18),
                    Visible = true,
                    AnchorPoint = Vector2New(0, 0.5),
                    Image = "rbxassetid://116339777575852",
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 3, 0.5, 0),
                    ImageTransparency = 1,
                    ZIndex = 5,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  CheckImage:AddToTheme({ImageColor3 = "Accent"})

                Instances:Create("UICorner", {
                    Parent = OptionButton.Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 5)
                })

                local OptionText = Instances:Create("TextLabel", {
                    Parent = OptionButton.Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextTransparency = 0.5,
                    AnchorPoint = Vector2New(0, 0.5),
                    ZIndex = 5,
                    TextSize = 14,
                    Size = UDim2New(0, 0, 0, 15),
                    TextColor3 = FromRGB(255, 255, 255),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = Option,
                    BackgroundTransparency = 1,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    AutomaticSize = Enum.AutomaticSize.X,
                    Position = UDim2New(0, 7, 0.5, 0),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  OptionText:AddToTheme({TextColor3 = "Text"})

                local OptionData = {
                    Selected = false,
                    Name = Option,
                    Text = OptionText,
                    Button = OptionButton,
                    Check = CheckImage
                }

                local RealOptionIndex

                if Dropdown.Options[OptionData.Name] then 
                    RealOptionIndex = OptionData.Name.." "..#Dropdown.Options
                else
                    RealOptionIndex = OptionData.Name
                end

                function OptionData:Toggle(Status)
                    if Status == "Active" then 
                        OptionData.Button:Tween(nil, {BackgroundTransparency = 0})
                        OptionData.Text:Tween(nil, {TextTransparency = 0, Position = UDim2New(0, 27, 0.5, 0)})
                        OptionData.Check:Tween(nil, {ImageTransparency = 0})
                    elseif Status == "Inactive" then
                        OptionData.Button:Tween(nil, {BackgroundTransparency = 1})
                        OptionData.Text:Tween(nil, {TextTransparency = 0.5, Position = UDim2New(0, 7, 0.5, 0)})
                        OptionData.Check:Tween(nil, {ImageTransparency = 1})
                    end
                end

                function OptionData:Set()
                    OptionData.Selected = not OptionData.Selected

                    if Data.Multi then 
                        local Index = TableFind(Dropdown.Value, OptionData.Name)

                        if Index then 
                            TableRemove(Dropdown.Value, Index)
                        else
                            TableInsert(Dropdown.Value, OptionData.Name)
                        end

                        Library.Flags[Dropdown.Flag] = Dropdown.Value

                        OptionData:Toggle(Index and "Inactive" or "Active")

                        local TextFormat = #Dropdown.Value > 0 and TableConcat(Dropdown.Value, ", ") or "--"

                        Items["Value"].Instance.Text = TextFormat
                    else
                        if OptionData.Selected then 
                            Dropdown.Value = OptionData.Name
                            Library.Flags[Dropdown.Flag] = OptionData.Name

                            OptionData:Toggle("Active")

                            for Index, Value in Dropdown.Options do 
                                if Value ~= OptionData then
                                    Value.Selected = false 
                                    Value:Toggle("Inactive")
                                end
                            end

                            Items["Value"].Instance.Text = OptionData.Name 
                        else
                            Dropdown.Value = nil
                            Library.Flags[Dropdown.Flag] = nil

                            OptionData:Toggle("Inactive")
                            Items["Value"].Instance.Text = "--"
                        end
                    end

                    if Data.Callback then 
                        Library:SafeCall(Data.Callback, Dropdown.Value)
                    end
                end

                OptionData.Button:Connect("MouseButton1Down", function()
                    OptionData:Set()
                end)

                Dropdown.Options[RealOptionIndex] = OptionData
                return OptionData
            end

            function Dropdown:RemoveOption(Name)
                if Dropdown.Options[Name] then
                    Dropdown.Options[Name].Button:Clean()
                    Dropdown.Options[Name] = nil
                end
            end

            function Dropdown:Refresh(List)
                for Index, Value in Dropdown.Options do 
                    Dropdown:RemoveOption(Value.Name)
                end

                for Index, Value in List do 
                    Dropdown:AddOption(Value)
                end
            end

            local Debounce = false 
            local RenderStepped 

            function Dropdown:SetOpen(Bool)
                if Debounce then 
                    return 
                end

                Dropdown.IsOpen = Bool
                Items["OptionHolder"].Instance.Parent = Bool and Library.Holder.Instance or Library.UnusedHolder.Instance

                Debounce = true

                if Bool then 
                    Items["OptionHolder"].Instance.Visible = true
                    Items["Holder"].Instance.ZIndex = 11

                    RenderStepped = RunService.RenderStepped:Connect(function()
                        Items["OptionHolder"].Instance.Position = UDim2New(0, Items["RealDropdown"].Instance.AbsolutePosition.X, 0, Items["RealDropdown"].Instance.AbsolutePosition.Y + 30)
                        Items["OptionHolder"].Instance.Size = UDim2New(0, Items["RealDropdown"].Instance.AbsoluteSize.X, 0, Data.MaxSize or 165)
                    end)

                    for Index, Value in Library.OpenFrames do 
                        if Value.Name ~= Data.Name then 
                            Value:SetOpen(false)
                        end
                    end

                    Library.OpenFrames[Data.Name] = Dropdown
                else
                    if Library.OpenFrames[Data.Name] then 
                        Library.OpenFrames[Data.Name] = nil
                    end

                    if RenderStepped then
                        RenderStepped:Disconnect()
                        RenderStepped = nil
                    end
                end

                local Descendants = Items["OptionHolder"].Instance:GetDescendants()
                TableInsert(Descendants, Items["OptionHolder"].Instance)

                local NewTween

                for Index, Value in Descendants do 
                    local TransparencyProperty = Tween:GetProperty(Value)

                    if not TransparencyProperty then 
                        continue
                    end

                    if StringFind(Value.ClassName, "UI") then
                        continue
                    end

                    Value.ZIndex = Bool and 10 or 0

                    if type(TransparencyProperty) == "table" then 
                        for _, Property in TransparencyProperty do 
                            NewTween = Tween:FadeItem(Value, Property, Bool, Data.Window.FadeSpeed)
                        end
                    else
                        NewTween = Tween:FadeItem(Value, TransparencyProperty, Bool, Data.Window.FadeSpeed)
                    end
                end

                Library:Connect(NewTween.Tween.Completed, function()
                    Debounce = false
                    Items["OptionHolder"].Instance.Visible = Bool
                end)
            end

            function Dropdown:SetVisibility(Bool)
                Items["Dropdown"].Instance.Visible = Bool
            end

            getgenv().Options[Dropdown.Flag] = Dropdown

            Library:Connect(UserInputService.InputBegan, function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                    if Library:IsMouseOverFrame(Items["OptionHolder"]) then
                        return
                    end

                    if Debounce then 
                        return 
                    end

                    if not Dropdown.IsOpen then
                        return
                    end

                    Dropdown:SetOpen(false)
                end
            end)

            local SearchStepped

            Items["Input"]:Connect("Focused", function()
                if SearchStepped then
                    return
                end

                SearchStepped = RunService.RenderStepped:Connect(LPH_NO_VIRTUALIZE(function()
                    for Index, Value in Dropdown.Options do 
                        if StringFind(Value.Name:lower(), Items["Input"].Instance.Text:lower()) then 
                            Value.Button.Instance.Visible = true
                        else
                            Value.Button.Instance.Visible = false
                        end
                    end
                end))
            end)

            Items["Input"]:Connect("FocusLost", function()
                if SearchStepped then
                    SearchStepped:Disconnect()
                    SearchStepped = nil
                end
            end)

            local SearchData = {
                Name = Data.Name,
                Item = Items["Dropdown"]
            }

            local PageSearchData = Library.SearchItems[Data.Page]

            if not PageSearchData then 
                return 
            end

            TableInsert(PageSearchData, SearchData)

            Items["RealDropdown"]:Connect("MouseButton1Down", function()
                Dropdown:SetOpen(not Dropdown.IsOpen)
            end)

            for Index, Value in Data.Items do 
                Dropdown:AddOption(Value)
            end

            if Data.Default then 
                Dropdown:Set(Data.Default)
            end

            Library.SetFlags[Dropdown.Flag] = function(Value)
                Dropdown:Set(Value)
            end

            return Dropdown, Items
        end

        Components.Colorpicker = function(Data)
            local Colorpicker = {
                IsOpen = false,
                
                Color = FromRGB(0, 0, 0),
                HexValue = "000000",
                Alpha = 0,

                Name = Data.Name,
                Type = "Colorpicker",

                Hue = 0,
                Saturation = 0,
                Value = 0,
            }

            local AnimationsDropdown 
            local AnimationsDropdownItems

            Library.Flags[Data.Flag] = { }

            local Items = { } do
                Items["ColorpickerButton"] = Instances:Create("TextButton", {
                    Parent = Data.Parent.Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    AutoButtonColor = false,
                    AnchorPoint = Vector2New(1, 0.5),
                    BorderSizePixel = 0,
                    Position = UDim2New(1, -25, 0, 0),
                    Size = UDim2New(0, 20, 0, 20),
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 125, 32)
                })

                local CalculateCount = function(Index)
                    local MaxButtonsAdded = 5

                    local Column = Index % MaxButtonsAdded
                
                    local ButtonSize = Items["ColorpickerButton"].Instance.AbsoluteSize
                    local Spacing = 4
                
                    local XPosition = (ButtonSize.X + Spacing) * Column - Spacing - ButtonSize.X
                
                    Items["ColorpickerButton"].Instance.Position = UDim2New(1, Data.IsToggle and XPosition - 24 or -XPosition, 0.5, 0)
                end

                CalculateCount(Data.Count)

                Instances:Create("UICorner", {
                    Parent = Items["ColorpickerButton"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })

                Items["Inline"] = Instances:Create("Frame", {
                    Parent = Items["ColorpickerButton"].Instance,
                    Name = "\0",
                    Size = UDim2New(1, -4, 1, -4),
                    Position = UDim2New(0, 2, 0, 2),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 125, 32)
                })

                Instances:Create("UICorner", {
                    Parent = Items["Inline"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })

                Instances:Create("UIGradient", {
                    Parent = Items["Inline"].Instance,
                    Name = "\0",
                    Rotation = 84,
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(211, 211, 211))}
                }):AddToTheme({Color = function()
                    return RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, Library.Theme["Dark Gradient"])}
                end})

                Items["ColorpickerWindow"] = Instances:Create("TextButton", {
                    Parent = Library.UnusedHolder.Instance,
                    Text = "",
                    AutoButtonColor = false,
                    Name = "\0",
                    Active = false,
                    Selectable = false,
                    Size = UDim2New(0, 219, 0, 282),
                    Position = UDim2New(0, Items["ColorpickerButton"].Instance.AbsolutePosition.X, 0, Items["ColorpickerButton"].Instance.AbsolutePosition.Y + 25),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    Visible = false,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(16, 18, 21)
                })  Items["ColorpickerWindow"]:AddToTheme({BackgroundColor3 = "Background"})

                Items["ColorpickerWindow"]:MakeDraggable()
                Items["ColorpickerWindow"]:MakeResizeable(Vector2New(219, 282), Vector2New(9999, 9999))

                Instances:Create("UIStroke", {
                    Parent = Items["ColorpickerWindow"].Instance,
                    Name = "\0",
                    Color = FromRGB(32, 36, 42),
                    Transparency = 0.4000000059604645,
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                }):AddToTheme({Color = "Border"})

                Instances:Create("UICorner", {
                    Parent = Items["ColorpickerWindow"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 5)
                })

                Items["Shadow"] = Instances:Create("ImageLabel", {
                    Parent = Items["ColorpickerWindow"].Instance,
                    Name = "\0",
                    ImageColor3 = FromRGB(0, 0, 0),
                    ScaleType = Enum.ScaleType.Slice,
                    ImageTransparency = 0.8999999761581421,
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, 25, 1, 25),
                    AnchorPoint = Vector2New(0.5, 0.5),
                    Image = "http://www.roblox.com/asset/?id=18245826428",
                    BackgroundTransparency = 1,
                    Position = UDim2New(0.5, 0, 0.5, 0),
                    BackgroundColor3 = FromRGB(255, 255, 255),
                    BorderSizePixel = 0,
                    SliceCenter = RectNew(Vector2New(21, 21), Vector2New(79, 79))
                })  Items["Shadow"]:AddToTheme({ImageColor3 = "Shadow"})

                Items["Palette"] = Instances:Create("TextButton", {
                    Parent = Items["ColorpickerWindow"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    AutoButtonColor = false,
                    BorderSizePixel = 0,
                    Position = UDim2New(0, 8, 0, 8),
                    Size = UDim2New(1, -16, 1, -125),
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 125, 32)
                })

                Instances:Create("UICorner", {
                    Parent = Items["Palette"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 5)
                })

                Items["Saturation"] = Instances:Create("ImageLabel", {
                    Parent = Items["Palette"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    Image = Library:GetImage("Saturation"),
                    BackgroundTransparency = 1,
                    Size = UDim2New(1, 0, 1, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Instances:Create("UICorner", {
                    Parent = Items["Saturation"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 5)
                })

                Items["Value"] = Instances:Create("ImageLabel", {
                    Parent = Items["Palette"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, 2, 1, 0),
                    Image = Library:GetImage("Value"),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, -1, 0, 0),
                    ZIndex = 3,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Instances:Create("UICorner", {
                    Parent = Items["Value"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 5)
                })

                Items["PaletteDragger"] = Instances:Create("Frame", {
                    Parent = Items["Palette"].Instance,
                    Name = "\0",
                    Size = UDim2New(0, 4, 0, 4),
                    Position = UDim2New(0, 5, 0, 5),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 3,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Instances:Create("UICorner", {
                    Parent = Items["PaletteDragger"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(1, 0)
                })

                Instances:Create("UIStroke", {
                    Parent = Items["PaletteDragger"].Instance,
                    Name = "\0",
                    Thickness = 1.2000000476837158,
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                })

                Items["Hue"] = Instances:Create("TextButton", {
                    Parent = Items["ColorpickerWindow"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, -16, 0, 18),
                    AutoButtonColor = false,
                    AnchorPoint = Vector2New(0, 1),
                    Position = UDim2New(0, 8, 1, -90),
                    Text = "",
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Instances:Create("UICorner", {
                    Parent = Items["Hue"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 5)
                })

                Instances:Create("UIGradient", {
                    Parent = Items["Hue"].Instance,
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 0, 0)), RGBSequenceKeypoint(0.17, FromRGB(255, 255, 0)), RGBSequenceKeypoint(0.33, FromRGB(0, 255, 0)), RGBSequenceKeypoint(0.5, FromRGB(0, 255, 255)), RGBSequenceKeypoint(0.67, FromRGB(0, 0, 255)), RGBSequenceKeypoint(0.83, FromRGB(255, 0, 255)), RGBSequenceKeypoint(1, FromRGB(255, 0, 0))}
                }) 

                Items["HueDragger"] = Instances:Create("Frame", {
                    Parent = Items["Hue"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(0, 0.5),
                    Position = UDim2New(0, 12, 0.5, 0),
                    Size = UDim2New(0, 3, 1, -8),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Instances:Create("UIStroke", {
                    Parent = Items["HueDragger"].Instance,
                    Name = "\0",
                    Thickness = 1.2000000476837158,
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                })

                Instances:Create("UICorner", {
                    Parent = Items["HueDragger"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(1, 0)
                })

                Items["Alpha"] = Instances:Create("TextButton", {
                    Parent = Items["ColorpickerWindow"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    AutoButtonColor = false,
                    TextColor3 = FromRGB(0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    AnchorPoint = Vector2New(0, 1),
                    BorderSizePixel = 0,
                    Position = UDim2New(0, 8, 1, -63),
                    Size = UDim2New(1, -16, 0, 18),
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 125, 32)
                })

                Instances:Create("UICorner", {
                    Parent = Items["Alpha"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 5)
                })

                Items["AlphaDragger"] = Instances:Create("Frame", {
                    Parent = Items["Alpha"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(0, 0.5),
                    Position = UDim2New(0, 3, 0.5, 0),
                    Size = UDim2New(0, 3, 1, -8),
                    ZIndex = 3,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Instances:Create("UIStroke", {
                    Parent = Items["AlphaDragger"].Instance,
                    Name = "\0",
                    Thickness = 1.2000000476837158,
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                })

                Instances:Create("UICorner", {
                    Parent = Items["AlphaDragger"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(1, 0)
                })

                Items["Checkers"] = Instances:Create("ImageLabel", {
                    Parent = Items["Alpha"].Instance,
                    Name = "\0",
                    ScaleType = Enum.ScaleType.Tile,
                    BorderColor3 = FromRGB(0, 0, 0),
                    TileSize = UDim2New(0, 6, 0, 6),
                    Image = Library:GetImage("Checkers"),
                    BackgroundTransparency = 1,
                    Size = UDim2New(1, 0, 1, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Instances:Create("UIGradient", {
                    Parent = Items["Checkers"].Instance,
                    Name = "\0",
                    Transparency = NumSequence{NumSequenceKeypoint(0, 1), NumSequenceKeypoint(0.37, 0.5), NumSequenceKeypoint(1, 0)}
                })

                Instances:Create("UICorner", {
                    Parent = Items["Checkers"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 5)
                })

                local DropdownItems = { } do
                    DropdownItems["Dropdown"] = Instances:Create("Frame", {
                        Parent = Items["ColorpickerWindow"].Instance,
                        Name = "\0",
                        BackgroundTransparency = 1,
                        AnchorPoint = Vector2New(0, 1),
                        Size = UDim2New(1, -16, 0, 47),
                        Position = UDim2New(0, 8, 1, -8),
                        BorderColor3 = FromRGB(0, 0, 0),
                        ZIndex = 2,
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })

                    DropdownItems["Text"] = Instances:Create("TextLabel", {
                        Parent = DropdownItems["Dropdown"].Instance,
                        Name = "\0",
                        FontFace = Library.Font,
                        TextColor3 = FromRGB(255, 255, 255),
                        BorderColor3 = FromRGB(0, 0, 0),
                        Text = "animations",
                        AutomaticSize = Enum.AutomaticSize.X,
                        BackgroundTransparency = 1,
                        Size = UDim2New(0, 0, 0, 15),
                        BorderSizePixel = 0,
                        ZIndex = 2,
                        TextSize = 14,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })  DropdownItems["Text"]:AddToTheme({TextColor3 = "Text"})

                    DropdownItems["RealDropdown"] = Instances:Create("TextButton", {
                        Parent = DropdownItems["Dropdown"].Instance,
                        Text = "", 
                        AutoButtonColor = false,
                        Name = "\0",
                        BorderColor3 = FromRGB(0, 0, 0),
                        AnchorPoint = Vector2New(0, 1),
                        Position = UDim2New(0, 0, 1, 0),
                        Size = UDim2New(1, 0, 0, 25),
                        ZIndex = 2,
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(34, 39, 45)
                    })  DropdownItems["RealDropdown"]:AddToTheme({BackgroundColor3 = "Element"})

                    Instances:Create("UIGradient", {
                        Parent = DropdownItems["RealDropdown"].Instance,
                        Name = "\0",
                        Rotation = 84,
                        Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(211, 211, 211))}
                    }):AddToTheme({Color = function()
                        return RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, Library.Theme["Dark Gradient"])}
                    end})

                    Instances:Create("UICorner", {
                        Parent = DropdownItems["RealDropdown"].Instance,
                        Name = "\0",
                        CornerRadius = UDimNew(0, 4)
                    })

                    DropdownItems["Value"] = Instances:Create("TextLabel", {
                        Parent = DropdownItems["RealDropdown"].Instance,
                        Name = "\0",
                        FontFace = Library.Font,
                        TextColor3 = FromRGB(255, 255, 255),
                        BorderColor3 = FromRGB(0, 0, 0),
                        Text = "--",
                        AutomaticSize = Enum.AutomaticSize.X,
                        Size = UDim2New(0, 0, 0, 15),
                        AnchorPoint = Vector2New(0, 0.5),
                        Position = UDim2New(0, 8, 0.5, 0),
                        BackgroundTransparency = 1,
                        TextTruncate = Enum.TextTruncate.AtEnd,
                        BorderSizePixel = 0,
                        ZIndex = 2,
                        TextSize = 14,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })  DropdownItems["Value"]:AddToTheme({TextColor3 = "Text"})

                    DropdownItems["OpenIcon"] = Instances:Create("ImageLabel", {
                        Parent = DropdownItems["RealDropdown"].Instance,
                        Name = "\0",
                        ImageColor3 = FromRGB(196, 231, 255),
                        ScaleType = Enum.ScaleType.Fit,
                        BorderColor3 = FromRGB(0, 0, 0),
                        Size = UDim2New(0, 20, 0, 20),
                        AnchorPoint = Vector2New(1, 0.5),
                        Image = "rbxassetid://114252321536924",
                        BackgroundTransparency = 1,
                        Position = UDim2New(1, -3, 0.5, 0),
                        ZIndex = 2,
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })  DropdownItems["OpenIcon"]:AddToTheme({ImageColor3 = "Accent"})

                    DropdownItems["OptionHolder"] = Instances:Create("TextButton", {
                        Parent = DropdownItems["Dropdown"].Instance,
                        Name = "\0",
                        FontFace = Library.Font,
                        TextColor3 = FromRGB(0, 0, 0),
                        BorderColor3 = FromRGB(0, 0, 0),
                        Text = "",
                        Visible = false,
                        AutoButtonColor = false,
                        Size = UDim2New(1, 0, 0, 50),
                        AutomaticSize = Enum.AutomaticSize.Y,
                        Position = UDim2New(0, 0, 1, 5),
                        BorderSizePixel = 0,
                        ZIndex = 5,
                        TextSize = 14,
                        BackgroundColor3 = FromRGB(22, 25, 29)
                    })  DropdownItems["OptionHolder"]:AddToTheme({BackgroundColor3 = "Inline"})

                    Instances:Create("UIGradient", {
                        Parent = DropdownItems["OptionHolder"].Instance,
                        Name = "\0",
                        Rotation = 84,
                        Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(211, 211, 211))}
                    }):AddToTheme({Color = function()
                        return RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, Library.Theme["Dark Gradient"])}
                    end})

                    Instances:Create("UIStroke", {
                        Parent = DropdownItems["OptionHolder"].Instance,
                        Name = "\0",
                        Color = FromRGB(32, 36, 42),
                        Transparency = 0.4000000059604645,
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                    }):AddToTheme({Color = "Border"})

                    Instances:Create("UICorner", {
                        Parent = DropdownItems["OptionHolder"].Instance,
                        Name = "\0",
                        CornerRadius = UDimNew(0, 5)
                    })

                    Instances:Create("UIListLayout", {
                        Parent = DropdownItems["OptionHolder"].Instance,
                        Name = "\0",
                        Padding = UDimNew(0, 2),
                        SortOrder = Enum.SortOrder.LayoutOrder
                    })

                    Instances:Create("UIPadding", {
                        Parent = DropdownItems["OptionHolder"].Instance,
                        Name = "\0",
                        PaddingTop = UDimNew(0, 8),
                        PaddingBottom = UDimNew(0, 8),
                        PaddingRight = UDimNew(0, 8),
                        PaddingLeft = UDimNew(0, 8)
                    })
                end

                local Dropdown = { 
                    IsOpen = false,
                    Value = { },
                    Options = { },
                    Flag = Data.Flag .. "AnimationDropdown",
                    Multi = true
                }

                function Dropdown:AddOption(Option)
                    local OptionButton = Instances:Create("TextButton", {
                        Parent = DropdownItems["OptionHolder"].Instance,
                        Name = "\0",
                        FontFace = Library.Font,
                        TextColor3 = FromRGB(0, 0, 0),
                        BorderColor3 = FromRGB(0, 0, 0),
                        Text = "",
                        AutoButtonColor = false,
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
                        Size = UDim2New(1, 0, 0, 25),
                        ZIndex = 5,
                        TextSize = 14,
                        BackgroundColor3 = FromRGB(16, 18, 21)
                    })  OptionButton:AddToTheme({BackgroundColor3 = "Background"})

                    local CheckImage = Instances:Create("ImageLabel", {
                        Parent = OptionButton.Instance,
                        Name = "\0",
                        ImageColor3 = FromRGB(196, 231, 255),
                        ScaleType = Enum.ScaleType.Fit,
                        BorderColor3 = FromRGB(0, 0, 0),
                        Size = UDim2New(0, 18, 0, 18),
                        Visible = true,
                        AnchorPoint = Vector2New(0, 0.5),
                        Image = "rbxassetid://116339777575852",
                        BackgroundTransparency = 1,
                        Position = UDim2New(0, 3, 0.5, 0),
                        ImageTransparency = 1,
                        ZIndex = 5,
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })  CheckImage:AddToTheme({ImageColor3 = "Accent"})

                    Instances:Create("UICorner", {
                        Parent = OptionButton.Instance,
                        Name = "\0",
                        CornerRadius = UDimNew(0, 5)
                    })

                    local OptionText = Instances:Create("TextLabel", {
                        Parent = OptionButton.Instance,
                        Name = "\0",
                        FontFace = Library.Font,
                        TextTransparency = 0.5,
                        AnchorPoint = Vector2New(0, 0.5),
                        ZIndex = 5,
                        TextSize = 14,
                        Size = UDim2New(0, 0, 0, 15),
                        TextColor3 = FromRGB(255, 255, 255),
                        BorderColor3 = FromRGB(0, 0, 0),
                        Text = Option,
                        BackgroundTransparency = 1,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        AutomaticSize = Enum.AutomaticSize.X,
                        Position = UDim2New(0, 7, 0.5, 0),
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })  OptionText:AddToTheme({TextColor3 = "Text"})

                    local OptionData = {
                        Selected = false,
                        Name = Option,
                        Text = OptionText,
                        Button = OptionButton,
                        Check = CheckImage
                    }

                    function OptionData:Toggle(Status)
                        if Status == "Active" then 
                            OptionData.Button:Tween(nil, {BackgroundTransparency = 0})
                            OptionData.Text:Tween(nil, {TextTransparency = 0, Position = UDim2New(0, 27, 0.5, 0)})
                            OptionData.Check:Tween(nil, {ImageTransparency = 0})
                        elseif Status == "Inactive" then
                            OptionData.Button:Tween(nil, {BackgroundTransparency = 1})
                            OptionData.Text:Tween(nil, {TextTransparency = 0.5, Position = UDim2New(0, 7, 0.5, 0)})
                            OptionData.Check:Tween(nil, {ImageTransparency = 1})
                        end
                    end

                    function OptionData:Set()
                        OptionData.Selected = not OptionData.Selected

                        if Dropdown.Multi then 
                            local Index = TableFind(Dropdown.Value, OptionData.Name)

                            if Index then 
                                TableRemove(Dropdown.Value, Index)
                            else
                                TableInsert(Dropdown.Value, OptionData.Name)
                            end

                            Library.Flags[Dropdown.Flag] = Dropdown.Value

                            OptionData:Toggle(Index and "Inactive" or "Active")

                            local TextFormat = #Dropdown.Value > 0 and TableConcat(Dropdown.Value, ", ") or "--"

                            DropdownItems["Value"].Instance.Text = TextFormat
                        else
                            if OptionData.Selected then 
                                Dropdown.Value = OptionData.Name
                                Library.Flags[Dropdown.Flag] = OptionData.Name

                                OptionData:Toggle("Active")

                                for Index, Value in Dropdown.Options do 
                                    if Value ~= OptionData then
                                        Value.Selected = false 
                                        Value:Toggle("Inactive")
                                    end
                                end

                                DropdownItems["Value"].Instance.Text = OptionData.Name 
                            else
                                Dropdown.Value = nil
                                Library.Flags[Dropdown.Flag] = nil

                                OptionData:Toggle("Inactive")
                                DropdownItems["Value"].Instance.Text = "--"
                            end
                        end

                        if Dropdown.Callback then 
                            Library:SafeCall(Dropdown.Callback, Dropdown.Value)
                        end
                    end

                    OptionData.Button:Connect("MouseButton1Down", function()
                        OptionData:Set()
                    end)

                    Dropdown.Options[Option] = OptionData
                    return OptionData
                end

                local Debounce = false 

                function Dropdown:SetOpen(Bool)
                    if Debounce then 
                        return 
                    end

                    Dropdown.IsOpen = Bool
                    DropdownItems["OptionHolder"].Instance.Parent = Bool and Library.Holder.Instance or Library.UnusedHolder.Instance

                    Debounce = true

                    if Bool then 
                        DropdownItems["OptionHolder"].Instance.Visible = true

                        RenderStepped = RunService.RenderStepped:Connect(function()
                            DropdownItems["OptionHolder"].Instance.Position = UDim2New(0, DropdownItems["RealDropdown"].Instance.AbsolutePosition.X, 0,  DropdownItems["RealDropdown"].Instance.AbsolutePosition.Y + DropdownItems["RealDropdown"].Instance.AbsoluteSize.Y + 5)
                            DropdownItems["OptionHolder"].Instance.Size = UDim2New(0, DropdownItems["RealDropdown"].Instance.AbsoluteSize.X, 0, 85)
                        end)
                    else
                        if RenderStepped then
                            RenderStepped:Disconnect()
                            RenderStepped = nil
                        end
                    end

                    local Descendants = DropdownItems["OptionHolder"].Instance:GetDescendants()
                    TableInsert(Descendants, DropdownItems["OptionHolder"].Instance)

                    local NewTween

                    for Index, Value in Descendants do 
                        local TransparencyProperty = Tween:GetProperty(Value)

                        if not TransparencyProperty then 
                            continue
                        end

                        if StringFind(Value.ClassName, "UI") then
                            continue
                        end

                        Value.ZIndex = Bool and 10 or 0

                        if type(TransparencyProperty) == "table" then 
                            for _, Property in TransparencyProperty do 
                                NewTween = Tween:FadeItem(Value, Property, Bool, Data.Window.FadeSpeed)
                            end
                        else
                            NewTween = Tween:FadeItem(Value, TransparencyProperty, Bool, Data.Window.FadeSpeed)
                        end
                    end

                    Library:Connect(NewTween.Tween.Completed, function()
                        Debounce = false
                        DropdownItems["OptionHolder"].Instance.Visible = Bool
                    end)
                end

                function Dropdown:Set(Option)
                    if Dropdown.Multi then
                        if type(Option) ~= "table" then
                            return
                        end

                        Dropdown.Value = Option
                        Library.Flags[Dropdown.Flag] = Option

                        for Index, Value in Option do 
                            local OptionData = Dropdown.Options[Value]
                                
                            if not OptionData then 
                                return
                            end

                            OptionData.Selected = true
                            OptionData:Toggle("Active")
                        end

                        DropdownItems["Value"].Instance.Text = TableConcat(Option, ", ")
                    else
                        if not Dropdown.Options[Option] then 
                            return
                        end

                        local OptionData = Dropdown.Options[Option]

                        Dropdown.Value = OptionData.Name
                        Library.Flags[Dropdown.Flag] = OptionData.Name

                        for Index, Value in Dropdown.Options do 
                            if Value ~= OptionData then
                                Value.Selected = false 
                                Value:Toggle("Inactive")
                            else
                                Value.Selected = true 
                                Value:Toggle("Active")
                            end
                        end

                        DropdownItems["Value"].Instance.Text = OptionData.Name
                    end

                    if Dropdown.Callback then 
                        Library:SafeCall(Dropdown.Callback, Dropdown.Value)
                    end
                end

                Library.SetFlags[Dropdown.Flag] = function(Value)
                    Dropdown:Set(Value)
                end

                DropdownItems["RealDropdown"]:Connect("MouseButton1Down", function()
                    Dropdown:SetOpen(not Dropdown.IsOpen)
                end)

                Dropdown:AddOption("rainbow")
                Dropdown:AddOption("breathing")

                local OldColor = Colorpicker.Color
                local OldAlpha = Colorpicker.Alpha
                
                Dropdown.Callback = function(Value)
                    if TableFind(Value, "rainbow") then 
                        OldColor = Colorpicker.Color

                        Library:Thread(function()
                            while task.wait() do 
                                local RainbowHue = MathAbs(MathSin(tick() * 0.32))
                                local Color = FromHSV(RainbowHue, 1, 1)

                                Colorpicker:Set(Color, Colorpicker.Alpha)

                                if not TableFind(Value, "rainbow") then
                                    Colorpicker:Set(OldColor, Colorpicker.Alpha)
                                    break
                                end
                            end
                        end)
                    end

                    if TableFind(Value, "breathing") then 
                        Library:Thread(function()
                            OldAlpha = Colorpicker.Alpha
                            while task.wait() do 
                                local AlphaValue = MathAbs(MathSin(tick() * 0.8))

                                Colorpicker:Set(Colorpicker.Color, AlphaValue)

                                if not TableFind(Value, "breathing") then
                                    Colorpicker:Set(Colorpicker.Color, OldAlpha)
                                    break
                                end
                            end
                        end)
                    end
                end

                getgenv().Options[Dropdown.Flag] = Dropdown

                AnimationsDropdown = Dropdown 
                AnimationsDropdownItems = DropdownItems
            end

            local Debounce = false 

            local SlidingPalette = false 
            local SlidingHue = false 
            local SlidingAlpha = false

            function Colorpicker:SetOpen(Bool)
                if Debounce then 
                    return 
                end

                Colorpicker.IsOpen = Bool

                Debounce = true
                Items["ColorpickerWindow"].Instance.Parent = Bool and Library.Holder.Instance or Library.UnusedHolder.Instance

                if Bool then 
                    Items["ColorpickerWindow"].Instance.Visible = true
                    Items["ColorpickerWindow"].Instance.Position = UDim2New(0, Items["ColorpickerButton"].Instance.AbsolutePosition.X, 0, Items["ColorpickerButton"].Instance.AbsolutePosition.Y + 25)
                    
                    for Index, Value in Library.OpenFrames do 
                        if Value.Type == "Colorpicker" then 
                            Value:SetOpen(false)
                        end
                    end

                    Library.OpenFrames[Data.Name] = Colorpicker
                else
                    if Library.OpenFrames[Data.Name] then 
                        Library.OpenFrames[Data.Name] = nil
                    end
                end

                local Descendants = Items["ColorpickerWindow"].Instance:GetDescendants()
                TableInsert(Descendants, Items["ColorpickerWindow"].Instance)

                local NewTween

                for Index, Value in Descendants do 
                    local TransparencyProperty = Tween:GetProperty(Value)

                    if not TransparencyProperty then 
                        continue
                    end

                    if type(TransparencyProperty) == "table" then 
                        for _, Property in TransparencyProperty do 
                            NewTween = Tween:FadeItem(Value, Property, Bool, Data.Window.FadeSpeed)
                        end
                    else
                        NewTween = Tween:FadeItem(Value, TransparencyProperty, Bool, Data.Window.FadeSpeed)
                    end
                end

                Library:Connect(NewTween.Tween.Completed, function()
                    Debounce = false
                    Items["ColorpickerWindow"].Instance.Visible = Bool
                end)                
            end

            function Colorpicker:Get()
                return Colorpicker.Color, Colorpicker.Alpha
            end

            function Colorpicker:Update(IsFromAlpha)
                local Hue, Saturation, Value = Colorpicker.Hue, Colorpicker.Saturation, Colorpicker.Value
                local Color = FromHSV(Hue, Saturation, Value)

                Colorpicker.Color = Color
                Colorpicker.HexValue = Color:ToHex()

                Library.Flags[Data.Flag] = {
                    Alpha = Colorpicker.Alpha,
                    Color = Colorpicker.HexValue
                }

                Items["ColorpickerButton"]:Tween(nil, {BackgroundColor3 = Color})
                Items["Inline"]:Tween(nil, {BackgroundColor3 = Color})
                Items["Palette"]:Tween(nil, {BackgroundColor3 = FromHSV(Hue, 1, 1)})

                if not IsFromAlpha then 
                    Items["Alpha"]:Tween(nil, {BackgroundColor3 = Color})
                end

                if Data.Callback then 
                    Library:SafeCall(Data.Callback, Color, Colorpicker.Alpha)
                end
            end

            function Colorpicker:SlidePalette(Input)
                if not SlidingPalette then 
                    return
                end

                if not Input then
                    return
                end

                local ValueX = MathClamp(1 - (Input.Position.X - Items["Palette"].Instance.AbsolutePosition.X) / Items["Palette"].Instance.AbsoluteSize.X, 0, 1)
                local ValueY = MathClamp(1 - (Input.Position.Y - Items["Palette"].Instance.AbsolutePosition.Y) / Items["Palette"].Instance.AbsoluteSize.Y, 0, 1)

                Colorpicker.Saturation = ValueX
                Colorpicker.Value = ValueY

                local SlideX = MathClamp((Input.Position.X - Items["Palette"].Instance.AbsolutePosition.X) / Items["Palette"].Instance.AbsoluteSize.X, 0, 0.98)
                local SlideY = MathClamp((Input.Position.Y - Items["Palette"].Instance.AbsolutePosition.Y) / Items["Palette"].Instance.AbsoluteSize.Y, 0, 0.97)

                Items["PaletteDragger"]:Tween(TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2New(SlideX, 0, SlideY, 0)})
                Colorpicker:Update()
            end

            function Colorpicker:SlideHue(Input)
                if not SlidingHue then 
                    return
                end

                if not Input then
                    return
                end
                
                local ValueX = MathClamp((Input.Position.X - Items["Hue"].Instance.AbsolutePosition.X) / Items["Hue"].Instance.AbsoluteSize.X, 0, 1)
                
                Colorpicker.Hue = ValueX

                local SlideX = MathClamp((Input.Position.X - Items["Hue"].Instance.AbsolutePosition.X) / Items["Hue"].Instance.AbsoluteSize.X, 0, 0.98)

                Items["HueDragger"]:Tween(TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2New(SlideX, 0, 0.5, 0)})
                Colorpicker:Update()
            end

            function Colorpicker:SlideAlpha(Input)
                if not SlidingAlpha then 
                    return
                end

                if not Input then
                    return
                end
                
                local ValueX = MathClamp((Input.Position.X - Items["Alpha"].Instance.AbsolutePosition.X) / Items["Alpha"].Instance.AbsoluteSize.X, 0, 1)
                
                Colorpicker.Alpha = ValueX

                local SlideX = MathClamp((Input.Position.X - Items["Alpha"].Instance.AbsolutePosition.X) / Items["Alpha"].Instance.AbsoluteSize.X, 0, 0.98)

                Items["AlphaDragger"]:Tween(TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2New(SlideX, 0, 0.5, 0)})
                Colorpicker:Update(true)
            end

            function Colorpicker:Set(Color, Alpha)
                if type(Color) == "table" then
                    Color = FromRGB(Color[1], Color[2], Color[3])
                    Alpha = Color[4]
                elseif type(Color) == "string" then
                    Color = FromHex(Color)
                end 

                Colorpicker.Hue, Colorpicker.Saturation, Colorpicker.Value = Color:ToHSV()
                Colorpicker.Alpha = Alpha or 0

                local ColorPositionX = MathClamp(1 - Colorpicker.Saturation, 0, 0.98)
                local ColorPositionY = MathClamp(1 - Colorpicker.Value, 0, 0.97)

                local AlphaPositionX = MathClamp(Colorpicker.Alpha, 0, 0.98)

                local HuePositionX = MathClamp(Colorpicker.Hue, 0, 0.98)

                Items["PaletteDragger"]:Tween(TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2New(ColorPositionX, 0, ColorPositionY, 0)})
                Items["HueDragger"]:Tween(TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2New(HuePositionX, 0, 0.5, 0)})
                Items["AlphaDragger"]:Tween(TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2New(AlphaPositionX, 0, 0.5, 0)})
                Colorpicker:Update()
            end

            getgenv().Options[Data.Flag] = Colorpicker

            Items["ColorpickerButton"]:Connect("MouseButton1Down", function()
                Colorpicker:SetOpen(not Colorpicker.IsOpen)
            end)

            local InputChanged1

            Items["Palette"]:Connect("InputBegan", function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then 
                    SlidingPalette = true
                    Colorpicker:SlidePalette(Input)

                    if InputChanged1 then
                        return
                    end

                    InputChanged1 = Input.Changed:Connect(function()
                        if Input.UserInputState == Enum.UserInputState.End then 
                            SlidingPalette = false

                            InputChanged1:Disconnect()
                            InputChanged1 = nil
                        end
                    end)
                end
            end)

            local InputChanged2

            Items["Hue"]:Connect("InputBegan", function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then 
                    SlidingHue = true
                    Colorpicker:SlideHue(Input)
                    
                    if InputChanged2 then
                        return
                    end

                    InputChanged2 = Input.Changed:Connect(function()
                        if Input.UserInputState == Enum.UserInputState.End then
                            SlidingHue = false

                            InputChanged2:Disconnect()
                            InputChanged2 = nil
                        end
                    end)
                end
            end)

            local InputChanged3

            Items["Alpha"]:Connect("InputBegan", function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then 
                    SlidingAlpha = true
                    Colorpicker:SlideAlpha(Input)

                    if InputChanged3 then
                        return
                    end

                    InputChanged3 = Input.Changed:Connect(function()
                        if Input.UserInputState == Enum.UserInputState.End then
                            SlidingAlpha = false

                            InputChanged3:Disconnect()
                            InputChanged3 = nil
                        end
                    end)
                end
            end)

            Library:Connect(UserInputService.InputChanged, function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then
                    if SlidingPalette then
                        Colorpicker:SlidePalette(Input)
                    end

                    if SlidingHue then
                        Colorpicker:SlideHue(Input)
                    end

                    if SlidingAlpha then
                        Colorpicker:SlideAlpha(Input)
                    end
                end
            end)

            Library:Connect(UserInputService.InputBegan, function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                    if not Colorpicker.IsOpen then
                        return
                    end

                    if Library:IsMouseOverFrame(Items["ColorpickerWindow"]) or Library:IsMouseOverFrame(AnimationsDropdownItems["OptionHolder"]) then
                        return 
                    end

                    if Debounce then 
                        return 
                    end

                    Colorpicker:SetOpen(false)
                end
            end)

            if Data.Default then
                Colorpicker:Set(Data.Default, Data.Alpha)
            end

            Library.SetFlags[Data.Flag] = function(Color, Alpha)
                Colorpicker:Set(Color, Alpha)
            end

            return Colorpicker, Items 
        end

        Components.Keybind = function(Data)
            local Keybind = {
                Type = "Keybind",
                IsOpen = false,

                Key = nil,
                Value = "",
                Mode = "",

                Toggled = false 
            }

            local Modes = { }
            Library.Flags[Data.Flag] = { }
            local ModesDropdown
            local ModesDropdownItems 
            local KeylistItem 

            if Library.KeyList and not Data.NoKeyBindList then 
                KeylistItem = Library.KeyList:Add("", "")
            end

            local Items = { } do
                Items["KeyButton"] = Instances:Create("TextButton", {
                    Parent = Data.Parent.Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(255, 255, 255),
                    TextTransparency = 0.5,
                    Text = "None",
                    AutomaticSize = Enum.AutomaticSize.X,
                    AutoButtonColor = false,
                    AnchorPoint = Vector2New(1, 0.5),
                    Size = UDim2New(0, 0, 0, 15),
                    BackgroundTransparency = 1,
                    Position = UDim2New(1, Data.IsToggle and -25 or 0, 0.5, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["KeyButton"]:AddToTheme({TextColor3 = "Text"})

                Instances:Create("UIPadding", {
                    Parent = Items["KeyButton"].Instance,
                    Name = "\0",
                    PaddingRight = UDimNew(0, 2),
                    PaddingLeft = UDimNew(0, 2)
                })

                Items["KeybindWindow"] = Instances:Create("Frame", {
                    Parent = Library.Holder.Instance,
                    Name = "\0",
                    Position = UDim2New(0, Items["KeyButton"].Instance.AbsolutePosition.X, 0, Items["KeyButton"].Instance.AbsolutePosition.Y + 25),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Visible = false,
                    Size = UDim2New(0, 195, 0, 93),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(16, 18, 21)
                })  Items["KeybindWindow"]:AddToTheme({BackgroundColor3 = "Background"})

                Instances:Create("UIStroke", {
                    Parent = Items["KeybindWindow"].Instance,
                    Name = "\0",
                    Color = FromRGB(32, 36, 42),
                    Transparency = 0.4000000059604645,
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                }):AddToTheme({Color = "Border"})

                Instances:Create("UICorner", {
                    Parent = Items["KeybindWindow"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 5)
                })

                Items["KeybindWindow"]:MakeDraggable()
                Items["KeybindWindow"]:MakeResizeable(Vector2New(155, 93), Vector2New(9999, 9999))

                local DropdownItems = { } do
                    DropdownItems["Dropdown"] = Instances:Create("Frame", {
                        Parent = Items["KeybindWindow"].Instance,
                        Name = "\0",
                        BackgroundTransparency = 1,
                        AnchorPoint = Vector2New(0, 0),
                        Size = UDim2New(1, -16, 0, 47),
                        Position = UDim2New(0, 8, 0, 8),
                        BorderColor3 = FromRGB(0, 0, 0),
                        ZIndex = 2,
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })

                    DropdownItems["Text"] = Instances:Create("TextLabel", {
                        Parent = DropdownItems["Dropdown"].Instance,
                        Name = "\0",
                        FontFace = Library.Font,
                        TextColor3 = FromRGB(255, 255, 255),
                        BorderColor3 = FromRGB(0, 0, 0),
                        Text = "mode",
                        AutomaticSize = Enum.AutomaticSize.X,
                        BackgroundTransparency = 1,
                        Size = UDim2New(0, 0, 0, 15),
                        BorderSizePixel = 0,
                        ZIndex = 2,
                        TextSize = 14,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })  DropdownItems["Text"]:AddToTheme({TextColor3 = "Text"})

                    DropdownItems["RealDropdown"] = Instances:Create("TextButton", {
                        Parent = DropdownItems["Dropdown"].Instance,
                        Text = "", 
                        AutoButtonColor = false,
                        Name = "\0",
                        BorderColor3 = FromRGB(0, 0, 0),
                        AnchorPoint = Vector2New(0, 1),
                        Position = UDim2New(0, 0, 1, 0),
                        Size = UDim2New(1, 0, 0, 25),
                        ZIndex = 2,
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(34, 39, 45)
                    })  DropdownItems["RealDropdown"]:AddToTheme({BackgroundColor3 = "Element"})

                    Instances:Create("UIGradient", {
                        Parent = DropdownItems["RealDropdown"].Instance,
                        Name = "\0",
                        Rotation = 84,
                        Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(211, 211, 211))}
                    }):AddToTheme({Color = function()
                        return RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, Library.Theme["Dark Gradient"])}
                    end})

                    Instances:Create("UICorner", {
                        Parent = DropdownItems["RealDropdown"].Instance,
                        Name = "\0",
                        CornerRadius = UDimNew(0, 4)
                    })

                    DropdownItems["Value"] = Instances:Create("TextLabel", {
                        Parent = DropdownItems["RealDropdown"].Instance,
                        Name = "\0",
                        FontFace = Library.Font,
                        TextColor3 = FromRGB(255, 255, 255),
                        BorderColor3 = FromRGB(0, 0, 0),
                        Text = "--",
                        AutomaticSize = Enum.AutomaticSize.X,
                        Size = UDim2New(0, 0, 0, 15),
                        AnchorPoint = Vector2New(0, 0.5),
                        Position = UDim2New(0, 8, 0.5, 0),
                        BackgroundTransparency = 1,
                        TextTruncate = Enum.TextTruncate.AtEnd,
                        BorderSizePixel = 0,
                        ZIndex = 2,
                        TextSize = 14,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })  DropdownItems["Value"]:AddToTheme({TextColor3 = "Text"})

                    DropdownItems["OpenIcon"] = Instances:Create("ImageLabel", {
                        Parent = DropdownItems["RealDropdown"].Instance,
                        Name = "\0",
                        ImageColor3 = FromRGB(196, 231, 255),
                        ScaleType = Enum.ScaleType.Fit,
                        BorderColor3 = FromRGB(0, 0, 0),
                        Size = UDim2New(0, 20, 0, 20),
                        AnchorPoint = Vector2New(1, 0.5),
                        Image = "rbxassetid://114252321536924",
                        BackgroundTransparency = 1,
                        Position = UDim2New(1, -3, 0.5, 0),
                        ZIndex = 2,
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })  DropdownItems["OpenIcon"]:AddToTheme({ImageColor3 = "Accent"})

                    DropdownItems["OptionHolder"] = Instances:Create("TextButton", {
                        Parent = DropdownItems["Dropdown"].Instance,
                        Name = "\0",
                        FontFace = Library.Font,
                        TextColor3 = FromRGB(0, 0, 0),
                        BorderColor3 = FromRGB(0, 0, 0),
                        Text = "",
                        Visible = false,
                        AutoButtonColor = false,
                        Size = UDim2New(1, 0, 0, 50),
                        AutomaticSize = Enum.AutomaticSize.Y,
                        Position = UDim2New(0, 0, 1, 5),
                        BorderSizePixel = 0,
                        ZIndex = 5,
                        TextSize = 14,
                        BackgroundColor3 = FromRGB(22, 25, 29)
                    })  DropdownItems["OptionHolder"]:AddToTheme({BackgroundColor3 = "Inline"})

                    Instances:Create("UIGradient", {
                        Parent = DropdownItems["OptionHolder"].Instance,
                        Name = "\0",
                        Rotation = 84,
                        Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(211, 211, 211))}
                    }):AddToTheme({Color = function()
                        return RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, Library.Theme["Dark Gradient"])}
                    end})

                    Instances:Create("UIStroke", {
                        Parent = DropdownItems["OptionHolder"].Instance,
                        Name = "\0",
                        Color = FromRGB(32, 36, 42),
                        Transparency = 0.4000000059604645,
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                    }):AddToTheme({Color = "Border"})

                    Instances:Create("UICorner", {
                        Parent = DropdownItems["OptionHolder"].Instance,
                        Name = "\0",
                        CornerRadius = UDimNew(0, 5)
                    })

                    Instances:Create("UIListLayout", {
                        Parent = DropdownItems["OptionHolder"].Instance,
                        Name = "\0",
                        Padding = UDimNew(0, 2),
                        SortOrder = Enum.SortOrder.LayoutOrder
                    })

                    Instances:Create("UIPadding", {
                        Parent = DropdownItems["OptionHolder"].Instance,
                        Name = "\0",
                        PaddingTop = UDimNew(0, 8),
                        PaddingBottom = UDimNew(0, 8),
                        PaddingRight = UDimNew(0, 8),
                        PaddingLeft = UDimNew(0, 8)
                    })
                end

                local Dropdown = { 
                    IsOpen = false,
                    Value = { },
                    Options = { },
                    Flag = Data.Flag .. "ModeDropdown",
                    Multi = false
                }

                function Dropdown:AddOption(Option)
                    local OptionButton = Instances:Create("TextButton", {
                        Parent = DropdownItems["OptionHolder"].Instance,
                        Name = "\0",
                        FontFace = Library.Font,
                        TextColor3 = FromRGB(0, 0, 0),
                        BorderColor3 = FromRGB(0, 0, 0),
                        Text = "",
                        AutoButtonColor = false,
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
                        Size = UDim2New(1, 0, 0, 25),
                        ZIndex = 5,
                        TextSize = 14,
                        BackgroundColor3 = FromRGB(16, 18, 21)
                    })  OptionButton:AddToTheme({BackgroundColor3 = "Background"})

                    local CheckImage = Instances:Create("ImageLabel", {
                        Parent = OptionButton.Instance,
                        Name = "\0",
                        ImageColor3 = FromRGB(196, 231, 255),
                        ScaleType = Enum.ScaleType.Fit,
                        BorderColor3 = FromRGB(0, 0, 0),
                        Size = UDim2New(0, 18, 0, 18),
                        Visible = true,
                        AnchorPoint = Vector2New(0, 0.5),
                        Image = "rbxassetid://116339777575852",
                        BackgroundTransparency = 1,
                        Position = UDim2New(0, 3, 0.5, 0),
                        ImageTransparency = 1,
                        ZIndex = 5,
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })  CheckImage:AddToTheme({ImageColor3 = "Accent"})

                    Instances:Create("UICorner", {
                        Parent = OptionButton.Instance,
                        Name = "\0",
                        CornerRadius = UDimNew(0, 5)
                    })

                    local OptionText = Instances:Create("TextLabel", {
                        Parent = OptionButton.Instance,
                        Name = "\0",
                        FontFace = Library.Font,
                        TextTransparency = 0.5,
                        AnchorPoint = Vector2New(0, 0.5),
                        ZIndex = 5,
                        TextSize = 14,
                        Size = UDim2New(0, 0, 0, 15),
                        TextColor3 = FromRGB(255, 255, 255),
                        BorderColor3 = FromRGB(0, 0, 0),
                        Text = Option,
                        BackgroundTransparency = 1,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        AutomaticSize = Enum.AutomaticSize.X,
                        Position = UDim2New(0, 7, 0.5, 0),
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })  OptionText:AddToTheme({TextColor3 = "Text"})

                    local OptionData = {
                        Selected = false,
                        Name = Option,
                        Text = OptionText,
                        Button = OptionButton,
                        Check = CheckImage
                    }

                    function OptionData:Toggle(Status)
                        if Status == "Active" then 
                            OptionData.Button:Tween(nil, {BackgroundTransparency = 0})
                            OptionData.Text:Tween(nil, {TextTransparency = 0, Position = UDim2New(0, 27, 0.5, 0)})
                            OptionData.Check:Tween(nil, {ImageTransparency = 0})
                        elseif Status == "Inactive" then
                            OptionData.Button:Tween(nil, {BackgroundTransparency = 1})
                            OptionData.Text:Tween(nil, {TextTransparency = 0.5, Position = UDim2New(0, 7, 0.5, 0)})
                            OptionData.Check:Tween(nil, {ImageTransparency = 1})
                        end
                    end

                    function OptionData:Set()
                        OptionData.Selected = not OptionData.Selected

                        if Dropdown.Multi then 
                            local Index = TableFind(Dropdown.Value, OptionData.Name)

                            if Index then 
                                TableRemove(Dropdown.Value, Index)
                            else
                                TableInsert(Dropdown.Value, OptionData.Name)
                            end

                            Library.Flags[Dropdown.Flag] = Dropdown.Value

                            OptionData:Toggle(Index and "Inactive" or "Active")

                            local TextFormat = #Dropdown.Value > 0 and TableConcat(Dropdown.Value, ", ") or "--"

                            DropdownItems["Value"].Instance.Text = TextFormat
                        else
                            if OptionData.Selected then 
                                Dropdown.Value = OptionData.Name
                                Library.Flags[Dropdown.Flag] = OptionData.Name

                                OptionData:Toggle("Active")

                                for Index, Value in Dropdown.Options do 
                                    if Value ~= OptionData then
                                        Value.Selected = false 
                                        Value:Toggle("Inactive")
                                    end
                                end

                                DropdownItems["Value"].Instance.Text = OptionData.Name 
                            else
                                Dropdown.Value = nil
                                Library.Flags[Dropdown.Flag] = nil

                                OptionData:Toggle("Inactive")
                                DropdownItems["Value"].Instance.Text = "--"
                            end
                        end

                        if Dropdown.Callback then 
                            Library:SafeCall(Dropdown.Callback, Dropdown.Value)
                        end
                    end

                    OptionData.Button:Connect("MouseButton1Down", function()
                        OptionData:Set()
                    end)

                    Dropdown.Options[Option] = OptionData
                    return OptionData
                end

                function Dropdown:Set(Option)
                    if Dropdown.Multi then
                        if type(Option) ~= "table" then
                            return
                        end

                        Dropdown.Value = Option
                        Library.Flags[Dropdown.Flag] = Option

                        for Index, Value in Option do 
                            local OptionData = Dropdown.Options[Value]
                            
                            if not OptionData then 
                                return
                            end

                            OptionData.Selected = true
                            OptionData:Toggle("Active")
                        end

                        DropdownItems["Value"].Instance.Text = TableConcat(Option, ", ")
                    else
                        if not Dropdown.Options[Option] then 
                            return
                        end

                        local OptionData = Dropdown.Options[Option]

                        Dropdown.Value = OptionData.Name
                        Library.Flags[Dropdown.Flag] = OptionData.Name

                        for Index, Value in Dropdown.Options do 
                            if Value ~= OptionData then
                                Value.Selected = false 
                                Value:Toggle("Inactive")
                            else
                                Value.Selected = true 
                                Value:Toggle("Active")
                            end
                        end

                        DropdownItems["Value"].Instance.Text = OptionData.Name
                    end

                    if Dropdown.Callback then 
                        Library:SafeCall(Dropdown.Callback, Dropdown.Value)
                    end

                    Library.SetFlags[Dropdown.Flag] = function(Value)
                        Dropdown:Set(Value)
                    end
                end

                local _1 = Dropdown:AddOption("toggle")
                local _2 = Dropdown:AddOption("hold")
                local _3 = Dropdown:AddOption("always")

                Modes = {
                    ["toggle"] = _1,
                    ["hold"] = _2,
                    ["always"] = _3
                }

                local Debounce = false 
                local RenderStepped

                function Dropdown:SetOpen(Bool)
                    if Debounce then 
                        return 
                    end

                    Dropdown.IsOpen = Bool
                    DropdownItems["OptionHolder"].Instance.Parent = Bool and Library.Holder.Instance or Library.UnusedHolder.Instance

                    Debounce = true

                    if Bool then 
                        DropdownItems["OptionHolder"].Instance.Visible = true

                        RenderStepped = RunService.RenderStepped:Connect(function()
                            DropdownItems["OptionHolder"].Instance.Position = UDim2New(0, DropdownItems["RealDropdown"].Instance.AbsolutePosition.X, 0,  DropdownItems["RealDropdown"].Instance.AbsolutePosition.Y + DropdownItems["RealDropdown"].Instance.AbsoluteSize.Y + 5)
                            DropdownItems["OptionHolder"].Instance.Size = UDim2New(0, DropdownItems["RealDropdown"].Instance.AbsoluteSize.X, 0, 85)
                        end)
                    else
                        if RenderStepped then
                            RenderStepped:Disconnect()
                            RenderStepped = nil
                        end
                    end

                    local Descendants = DropdownItems["OptionHolder"].Instance:GetDescendants()
                    TableInsert(Descendants, DropdownItems["OptionHolder"].Instance)

                    local NewTween

                    for Index, Value in Descendants do 
                        local TransparencyProperty = Tween:GetProperty(Value)

                        if not TransparencyProperty then 
                            continue
                        end

                        if StringFind(Value.ClassName, "UI") then
                            continue
                        end

                        Value.ZIndex = Bool and 10 or 0

                        if type(TransparencyProperty) == "table" then 
                            for _, Property in TransparencyProperty do 
                                NewTween = Tween:FadeItem(Value, Property, Bool, Data.Window.FadeSpeed)
                            end
                        else
                            NewTween = Tween:FadeItem(Value, TransparencyProperty, Bool, Data.Window.FadeSpeed)
                        end
                    end

                    Library:Connect(NewTween.Tween.Completed, function()
                        Debounce = false
                        DropdownItems["OptionHolder"].Instance.Visible = Bool
                    end)
                end

                DropdownItems["RealDropdown"]:Connect("MouseButton1Down", function()
                    Dropdown:SetOpen(not Dropdown.IsOpen)
                end)

                ModesDropdown = Dropdown
                ModesDropdownItems = DropdownItems

                local ToggleItems = { } do
                    ToggleItems["Toggle"] = Instances:Create("TextButton", {
                        Parent = Items["KeybindWindow"].Instance,
                        Name = "\0",
                        FontFace = Library.Font,
                        TextColor3 = FromRGB(0, 0, 0),
                        BorderColor3 = FromRGB(0, 0, 0),
                        Text = "",
                        AutoButtonColor = false,
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
                        Position = UDim2New(0, 8, 0, 65),
                        Size = UDim2New(1, -16, 0, 20),
                        ZIndex = 2,
                        TextSize = 14,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })

                    ToggleItems["Text"] = Instances:Create("TextLabel", {
                        Parent = ToggleItems["Toggle"].Instance,
                        Name = "\0",
                        FontFace = Library.Font,
                        TextColor3 = FromRGB(255, 255, 255),
                        TextTransparency = 0.5,
                        Text = "show in keybind list",
                        AutomaticSize = Enum.AutomaticSize.X,
                        Size = UDim2New(0, 0, 0, 15),
                        AnchorPoint = Vector2New(0, 0.5),
                        BorderSizePixel = 0,
                        BackgroundTransparency = 1,
                        Position = UDim2New(0, 0, 0.5, 0),
                        BorderColor3 = FromRGB(0, 0, 0),
                        ZIndex = 2,
                        TextSize = 14,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })  ToggleItems["Text"]:AddToTheme({TextColor3 = "Text"})

                    ToggleItems["Indicator"] = Instances:Create("Frame", {
                        Parent = ToggleItems["Toggle"].Instance,
                        Name = "\0",
                        BorderColor3 = FromRGB(0, 0, 0),
                        AnchorPoint = Vector2New(1, 0.5),
                        Position = UDim2New(1, 0, 0.5, 0),
                        Size = UDim2New(0, 20, 0, 20),
                        ZIndex = 2,
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(34, 39, 45)
                    })  ToggleItems["Indicator"]:AddToTheme({BackgroundColor3 = "Element"})

                    Instances:Create("UICorner", {
                        Parent = ToggleItems["Indicator"].Instance,
                        Name = "\0",
                        CornerRadius = UDimNew(0, 4)
                    })

                    ToggleItems["Inline"] = Instances:Create("Frame", {
                        Parent = ToggleItems["Indicator"].Instance,
                        Name = "\0",
                        Size = UDim2New(1, -4, 1, -4),
                        Position = UDim2New(0, 2, 0, 2),
                        BorderColor3 = FromRGB(0, 0, 0),
                        ZIndex = 2,
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(34, 39, 45)
                    })  ToggleItems["Inline"]:AddToTheme({BackgroundColor3 = "Element"})

                    Instances:Create("UICorner", {
                        Parent = ToggleItems["Inline"].Instance,
                        Name = "\0",
                        CornerRadius = UDimNew(0, 4)
                    })

                    Instances:Create("UIGradient", {
                        Parent = ToggleItems["Inline"].Instance,
                        Name = "\0",
                        Rotation = 84,
                        Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(211, 211, 211))}
                    }):AddToTheme({Color = function()
                        return RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, Library.Theme["Dark Gradient"])}
                    end})

                    ToggleItems["Check"] = Instances:Create("ImageLabel", {
                        Parent = ToggleItems["Inline"].Instance,
                        Name = "\0",
                        Visible = true,
                        ScaleType = Enum.ScaleType.Fit,
                        BorderColor3 = FromRGB(0, 0, 0),
                        Size = UDim2New(1, -2, 1, -2),
                        AnchorPoint = Vector2New(0.5, 0.5),
                        Image = "rbxassetid://116339777575852",
                        BackgroundTransparency = 1,
                        Position = UDim2New(0.5, 0, 0.5, 0),
                        ImageTransparency = 1,
                        ZIndex = 2,
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(255, 255, 255),
                        ImageColor3 = FromRGB(0, 0, 0)
                    })
                end

                getgenv().Options[Dropdown.Flag] = Dropdown

                local Toggle = { 
                    Value = false,
                    Flag = Data.Flag .. "keybindToggle",
                    Callback = nil,
                }

                function Toggle:Set(Bool)
                    Toggle.Value = Bool 
                    Library.Flags[Toggle.Flag] = Bool

                    if Bool then
                        ToggleItems["Indicator"]:ChangeItemTheme({BackgroundColor3 = "Accent"})
                        ToggleItems["Inline"]:ChangeItemTheme({BackgroundColor3 = "Accent"})

                        ToggleItems["Indicator"]:Tween(nil, {BackgroundColor3 = Library.Theme.Accent})
                        ToggleItems["Inline"]:Tween(nil, {BackgroundColor3 = Library.Theme.Accent})

                        ToggleItems["Check"]:Tween(nil, {ImageTransparency = 0})
                        ToggleItems["Text"]:Tween(nil, {TextTransparency = 0})
                    else
                        ToggleItems["Indicator"]:ChangeItemTheme({BackgroundColor3 = "Element"})
                        ToggleItems["Inline"]:ChangeItemTheme({BackgroundColor3 = "Element"})

                        ToggleItems["Indicator"]:Tween(nil, {BackgroundColor3 = Library.Theme.Element})
                        ToggleItems["Inline"]:Tween(nil, {BackgroundColor3 = Library.Theme.Element})

                        ToggleItems["Check"]:Tween(nil, {ImageTransparency = 1})
                        ToggleItems["Text"]:Tween(nil, {TextTransparency = 0.5})
                    end

                    if Toggle.Callback then 
                        Library:SafeCall(Toggle.Callback, Bool)
                    end
                end

                Toggle.Callback = function(Value)
                    if KeylistItem then 
                        KeylistItem:SetVisibility(Value)
                    end
                end

                ToggleItems["Toggle"]:Connect("MouseButton1Down", function()
                    Toggle:Set(not Toggle.Value)
                end)

                Toggle:Set(true)

                Dropdown.Callback = function(Value)
                    Keybind.Mode = Value

                    Library.Flags[Data.Flag] = {
                        Mode = Keybind.Mode,
                        Key = Keybind.Key,
                        Toggled = Keybind.Toggled
                    }
                end 

                getgenv().Options[Toggle.Flag] = Toggle
            end

            local Update = function()
                if not KeylistItem then 
                    return 
                end

                KeylistItem:SetText(Keybind.Value, Data.Name)
                
                if Keybind.Mode == "hold" then 
                    KeylistItem:SetStatus(Keybind.Toggled and "holding" or "off")
                else
                    KeylistItem:SetStatus(Keybind.Toggled and "on" or "off")
                end

                KeylistItem:Set(Keybind.Toggled)
            end

            local Debounce = false

            function Keybind:SetOpen(Bool)
                if Debounce then 
                    return 
                end

                Keybind.IsOpen = Bool

                Debounce = true
                Items["KeybindWindow"].Instance.Parent = Bool and Library.Holder.Instance or Library.UnusedHolder.Instance

                if Bool then 
                    Items["KeybindWindow"].Instance.Visible = true
                    Items["KeybindWindow"].Instance.Position = UDim2New(0, Items["KeyButton"].Instance.AbsolutePosition.X, 0, Items["KeyButton"].Instance.AbsolutePosition.Y + 25)

                    for Index, Value in Library.OpenFrames do 
                        if Value.Type == "Keybind" then 
                            Value:SetOpen(false)
                        end
                    end

                    Library.OpenFrames[Data.Name] = Keybind
                else
                    ModesDropdown:SetOpen(false)

                    if Library.OpenFrames[Data.Name] then 
                        Library.OpenFrames[Data.Name] = nil
                    end
                end

                local Descendants = Items["KeybindWindow"].Instance:GetDescendants()
                TableInsert(Descendants, Items["KeybindWindow"].Instance)

                local NewTween

                for Index, Value in Descendants do 
                    local TransparencyProperty = Tween:GetProperty(Value)

                    if not TransparencyProperty then 
                        continue
                    end

                    if StringFind(Value.ClassName, "UI") then
                        continue
                    end

                    Value.ZIndex = Bool and 15 or 0

                    if type(TransparencyProperty) == "table" then 
                        for _, Property in TransparencyProperty do 
                            NewTween = Tween:FadeItem(Value, Property, Bool, Data.Window.FadeSpeed)
                        end
                    else
                        NewTween = Tween:FadeItem(Value, TransparencyProperty, Bool, Data.Window.FadeSpeed)
                    end
                end

                Library:Connect(NewTween.Tween.Completed, function()
                    Debounce = false
                    Items["KeybindWindow"].Instance.Visible = Bool
                end)
            end

            function Keybind:SetMode(Mode)
                ModesDropdown:Set(Mode)
                
                Library.Flags[Data.Flag] = {
                    Mode = Keybind.Mode,
                    Key = Keybind.Key,
                    Toggled = Keybind.Toggled
                }

                Update()
            end

            function Keybind:Get()
                return Keybind.Toggled, Keybind.Key
            end

            function Keybind:Set(Key)
                if StringFind(tostring(Key), "Enum") then 
                    Keybind.Key = tostring(Key)

                    Key = Key.Name == "Backspace" and "None" or Key.Name

                    local KeyString = Keys[Keybind.Key] or StringGSub(Key, "Enum.", "") or "None"
                    local TextToDisplay = StringGSub(StringGSub(KeyString, "KeyCode.", ""), "UserInputType.", "") or "None"

                    Keybind.Value = TextToDisplay
                    Items["KeyButton"].Instance.Text = TextToDisplay

                    Library.Flags[Data.Flag] = {
                        Mode = Keybind.Mode,
                        Key = Keybind.Key,
                        Toggled = Keybind.Toggled
                    }

                    if Data.Callback then 
                        Library:SafeCall(Data.Callback, Keybind.Toggled)
                    end

                    Update()
                elseif type(Key) == "table" then
                    local RealKey = Key.Key == "Backspace" and "None" or Key.Key
                    Keybind.Key = tostring(Key.Key)

                    if Key.Mode then
                        Keybind.Mode = Key.Mode
                        Keybind:SetMode(Key.Mode)
                    else
                        Keybind.Mode = "toggle"
                        Keybind:SetMode("toggle")
                    end

                    local KeyString = Keys[Keybind.Key] or StringGSub(tostring(RealKey), "Enum.", "") or RealKey
                    local TextToDisplay = KeyString and StringGSub(StringGSub(KeyString, "KeyCode.", ""), "UserInputType.", "") or "None"

                    TextToDisplay = StringGSub(StringGSub(KeyString, "KeyCode.", ""), "UserInputType.", "")

                    Keybind.Value = TextToDisplay
                    Items["KeyButton"].Instance.Text = TextToDisplay

                    if Data.Callback then 
                        Library:SafeCall(Data.Callback, Keybind.Toggled)
                    end

                    Update()
                elseif TableFind({"toggle", "hold", "always"}, Key) then
                    Keybind.Mode = Key
                    Keybind:SetMode(Keybind.Mode)

                    if Data.Callback then 
                        Library:SafeCall(Data.Callback, Keybind.Toggled)
                    end

                    Update()
                end

                Items["KeyButton"]:Tween(nil, {TextTransparency = 0.5})
                Keybind.Picking = false
            end

            function Keybind:Press(Bool)
                if Keybind.Mode == "toggle" then 
                    Keybind.Toggled = not Keybind.Toggled
                elseif Keybind.Mode == "hold" then 
                    Keybind.Toggled = Bool
                elseif Keybind.Mode == "always" then 
                    Keybind.Toggled = true
                end

                Library.Flags[Data.Flag] = {
                    Mode = Keybind.Mode,
                    Key = Keybind.Key,
                    Toggled = Keybind.Toggled
                }

                if Data.Callback then 
                    Library:SafeCall(Data.Callback, Keybind.Toggled)
                end

                Update()
            end

            getgenv().Options[Data.Flag] = Keybind

            Items["KeyButton"]:Connect("MouseButton1Click", function()
                if Keybind.Picking then 
                    return
                end

                Keybind.Picking = true

                Items["KeyButton"]:Tween(nil, {TextTransparency = 0})

                local InputBegan 
                InputBegan = UserInputService.InputBegan:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.Keyboard then 
                        Keybind:Set(Input.KeyCode)
                    else
                        Keybind:Set(Input.UserInputType)
                    end

                    InputBegan:Disconnect()
                    InputBegan = nil
                end)
            end)

            Library:Connect(UserInputService.InputBegan, function(Input, Typing)
                if Typing then return end
                if tostring(Input.KeyCode) == Keybind.Key or tostring(Input.UserInputType) == Keybind.Key and not Keybind.Value == "None" then
                    if Keybind.Mode == "toggle" then 
                        Keybind:Press()
                    elseif Keybind.Mode == "hold" then 
                        Keybind:Press(true)
                    end
                end

                if Input.UserInputType == Enum.UserInputType.MouseButton1 then 
                    if Library:IsMouseOverFrame(Items["KeybindWindow"]) or Library:IsMouseOverFrame(ModesDropdownItems["OptionHolder"]) then 
                        return
                    end

                    if Debounce then 
                        return 
                    end

                    Keybind:SetOpen(false)
                end
            end)

            Library:Connect(UserInputService.InputEnded, function(Input, Typing)
                if Typing then return end

                if tostring(Input.KeyCode) == Keybind.Key or tostring(Input.UserInputType) == Keybind.Key and not Keybind.Value == "None" then
                    if Keybind.Mode == "hold" then 
                        Keybind:Press(false)
                    end
                end
            end)

            Items["KeyButton"]:Connect("MouseButton2Down", function()
                Keybind:SetOpen(not Keybind.IsOpen)
            end)

            if Data.Default then
               Keybind.Mode = Data.Mode or "toggle"
               Modes[Keybind.Mode]:Set()
               Keybind:Set({Key = Data.Default, Mode = Data.Mode})
            end

            Library.SetFlags[Data.Flag] = function(Value)
                Keybind:Set(Value)
            end

            return Keybind, Items 
        end
    end

    do -- Element functions
        Library.ESPPreview = function(self, Data)
            local ESPPreview = { 
                Player = nil,
                Items = { },
            }

            local Items = { } do
                Items["EspPreview"] = Instances:Create("TextButton", {
                    Parent = Data.MainFrame.Instance,
                    Name = "\0",
                    Position = UDim2New(1, 10, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    AutoButtonColor = false,
                    Size = UDim2New(0, 265, 0, 355),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(16, 18, 21)
                })  Items["EspPreview"]:AddToTheme({BackgroundColor3 = "Background"})

                Items["EspPreview"]:MakeDraggable()

                Items["Topbar"] = Instances:Create("Frame", {
                    Parent = Items["EspPreview"].Instance,
                    Name = "\0",
                    Size = UDim2New(1, 0, 0, 35),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(22, 25, 29)
                })  Items["Topbar"]:AddToTheme({BackgroundColor3 = "Inline"})

                Instances:Create("UIStroke", {
                    Parent = Items["EspPreview"].Instance,
                    Name = "\0",
                    Color = FromRGB(32, 36, 42),
                    Transparency = 0.4000000059604645,
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                }):AddToTheme({Color = "Border"})

                Instances:Create("UICorner", {
                    Parent = Items["Topbar"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 5)
                })

                Instances:Create("Frame", {
                    Parent = Items["Topbar"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(0, 1),
                    Position = UDim2New(0, 0, 1, 0),
                    Size = UDim2New(1, 0, 0, 3),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(22, 25, 29)
                }):AddToTheme({BackgroundColor3 = "Inline"})

                Instances:Create("Frame", {
                    Parent = Items["Topbar"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(0, 1),
                    BackgroundTransparency = 0.4000000059604645,
                    Position = UDim2New(0, 0, 1, 0),
                    Size = UDim2New(1, 0, 0, 1),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(32, 36, 42)
                }):AddToTheme({BackgroundColor3 = "Border"})

                Instances:Create("UIGradient", {
                    Parent = Items["Topbar"].Instance,
                    Name = "\0",
                    Rotation = 84,
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(211, 211, 211))}
                }):AddToTheme({Color = function()
                    return RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, Library.Theme["Dark Gradient"])}
                end})

                Items["Title"] = Instances:Create("TextLabel", {
                    Parent = Items["Topbar"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    AnchorPoint = Vector2New(0, 0.5),
                    ZIndex = 2,
                    TextSize = 14,
                    Size = UDim2New(0, 0, 0, 15),
                    RichText = true,
                    TextColor3 = FromRGB(255, 255, 255),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "ESP Preview",
                    BackgroundTransparency = 1,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Position = UDim2New(0, 8, 0.5, 0),
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.X,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Title"]:AddToTheme({TextColor3 = "Text"})

                Items["CloseButton"] = Instances:Create("ImageButton", {
                    Parent = Items["Topbar"].Instance,
                    Name = "\0",
                    ScaleType = Enum.ScaleType.Fit,
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 17, 0, 17),
                    AutoButtonColor = false,
                    AnchorPoint = Vector2New(1, 0.5),
                    Image = "rbxassetid://76001605964586",
                    BackgroundTransparency = 1,
                    Position = UDim2New(1, -7, 0.5, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["CloseButton"]:AddToTheme({ImageColor3 = "Image"})

                Instances:Create("UICorner", {
                    Parent = Items["EspPreview"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 5)
                })

                Items["CharacterViewportBackground"] = Instances:Create("TextButton", {
                    Parent = Items["EspPreview"].Instance,
                    Text = "",
                    AutoButtonColor = false,
                    Name = "\0",
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 8, 0, 45),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, -14, 1, -50),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Items["CharacterViewport"] = Instances:Create("ViewportFrame", {
                    Parent = Items["EspPreview"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 8, 0, 45),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, -16, 1, -53),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                -- Box
                    Items.Box = Instances:Create( "Frame" , {
                        BackgroundTransparency = 1;
                        Parent = Items.CharacterViewport.Instance;
                        BorderColor3 = FromRGB(0, 0, 0);
                        Name = "\0";
                        BorderSizePixel = 0;
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    });

                    Items.Left = Instances:Create( "Frame" , {
                        Parent = Items.Box.Instance;
                        Size = UDim2New(0, 100, 1, 0);
                        BackgroundTransparency = 1;
                        Name = "\0";
                        AnchorPoint = Vector2New(1, 0);
                        Position = UDim2New(0, -5, 0, 0);
                        BorderColor3 = FromRGB(0, 0, 0);
                        ZIndex = 2;
                        BorderSizePixel = 0;
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    });

                    Instances:Create( "UIListLayout" , {
                        FillDirection = Enum.FillDirection.Horizontal;
                        HorizontalAlignment = Enum.HorizontalAlignment.Right;
                        VerticalFlex = Enum.UIFlexAlignment.Fill;
                        Parent = Items.Left.Instance;
                        Padding = UDimNew(0, 1);
                        SortOrder = Enum.SortOrder.LayoutOrder
                    });
                    
                    Items.LeftTexts = Instances:Create( "Frame" , {
                        Parent = Items.Left.Instance;
                        Size = UDim2New(0, 0, 1, 0);
                        Name = "\0";
                        BackgroundTransparency = 1;
                        Position = UDim2New(1, 1, 0, 0);
                        BorderColor3 = FromRGB(0, 0, 0);
                        LayoutOrder = 9999;
                        ZIndex = 2;
                        AutomaticSize = Enum.AutomaticSize.X;
                        BorderSizePixel = 0;
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    });

                    Instances:Create( "UIListLayout" , {
                        FillDirection = Enum.FillDirection.Vertical;
                        Parent = Items.LeftTexts.Instance;
                        Padding = UDimNew(0, 1);
                        SortOrder = Enum.SortOrder.LayoutOrder
                    });

                    Items.Top = Instances:Create( "Frame" , {
                        Parent = Items.Box.Instance;
                        Size = UDim2New(1, 0, 0, 100);
                        BackgroundTransparency = 1;
                        Name = "\0";
                        AnchorPoint = Vector2New(0, 1);
                        Position = UDim2New(0, 0, 0, -5);
                        BorderColor3 = FromRGB(0, 0, 0);
                        ZIndex = 2;
                        BorderSizePixel = 0;
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    });

                    Items.TopTexts = Instances:Create( "Frame", {
                        LayoutOrder = -1;
                        Parent = Items.Top.Instance;
                        BackgroundTransparency = 1;
                        Name = "\0";
                        BorderColor3 = FromRGB(0, 0, 0);
                        BorderSizePixel = 0;
                        AutomaticSize = Enum.AutomaticSize.XY;
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    });

                    Instances:Create( "UIListLayout" , {
                        VerticalAlignment = Enum.VerticalAlignment.Bottom;
                        SortOrder = Enum.SortOrder.LayoutOrder;
                        HorizontalAlignment = Enum.HorizontalAlignment.Center;
                        HorizontalFlex = Enum.UIFlexAlignment.Fill;
                        Parent = Items.Top.Instance;
                        Padding = UDimNew(0, 1)
                    });

                    Items.Right = Instances:Create( "Frame" , {
                        Parent = Items.Box.Instance;
                        Size = UDim2New(0, 100, 1, 0);
                        Name = "\0";
                        BackgroundTransparency = 1;
                        Position = UDim2New(1, 5, 0, 0);
                        BorderColor3 = FromRGB(0, 0, 0);
                        ZIndex = 2;
                        BorderSizePixel = 0;
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    });

                    Items.RightTexts = Instances:Create( "Frame" , {
                        Parent = Items.Right.Instance;
                        Size = UDim2New(0, 0, 1, 0);
                        Name = "\0";
                        BackgroundTransparency = 1;
                        Position = UDim2New(0, 0, 0, 0);
                        BorderColor3 = FromRGB(0, 0, 0);
                        LayoutOrder = 9999;
                        ZIndex = 2;
                        AutomaticSize = Enum.AutomaticSize.X;
                        BorderSizePixel = 0;
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    });

                    Instances:Create( "UIListLayout" , {
                        Parent = Items.RightTexts.Instance;
                        Padding = UDimNew(0, 1);
                        SortOrder = Enum.SortOrder.LayoutOrder
                    });
                    
                    Instances:Create( "UIListLayout" , {
                        FillDirection = Enum.FillDirection.Horizontal;
                        VerticalFlex = Enum.UIFlexAlignment.Fill;
                        Parent = Items.Right.Instance;
                        Padding = UDimNew(0, 1);
                        SortOrder = Enum.SortOrder.LayoutOrder
                    });

                    Items.Bottom = Instances:Create( "Frame" , {
                        Parent = Items.Box.Instance;
                        Size = UDim2New(1, 0, 0, 100);
                        Name = "\0";
                        BackgroundTransparency = 1;
                        Position = UDim2New(0, 0, 1, 5);
                        BorderColor3 = FromRGB(0, 0, 0);
                        AutomaticSize = Enum.AutomaticSize.Y;
                        ZIndex = 2;
                        BorderSizePixel = 0;
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    });
                    
                    Items.BottomTexts = Instances:Create( "Frame", {
                        LayoutOrder = 1;
                        Parent = Items.Bottom.Instance;
                        BackgroundTransparency = 1;
                        Name = "\0";
                        BorderColor3 = FromRGB(0, 0, 0);
                        Size = UDim2New(1, 0, 0, 0);
                        BorderSizePixel = 0;
                        AutomaticSize = Enum.AutomaticSize.XY;
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    });

                    Instances:Create( "UIListLayout", {
                        Parent = Items.BottomTexts.Instance;
                        Padding = UDimNew(0, 1);
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        HorizontalAlignment = Enum.HorizontalAlignment.Center
                    });

                    Instances:Create( "UIListLayout" , {
                        SortOrder = Enum.SortOrder.LayoutOrder;
                        HorizontalAlignment = Enum.HorizontalAlignment.Center;
                        HorizontalFlex = Enum.UIFlexAlignment.Fill;
                        Parent = Items.Bottom.Instance;
                        Padding = UDimNew(0, 1)
                    });

                        Items.BoxHolder = Instances:Create( "Frame" , {
                            Visible = false;
                            Size = UDim2New(1, -2, 1, -2);
                            BorderColor3 = FromRGB(0, 0, 0);
                            Parent = Items.Box.Instance;
                            BackgroundTransparency = 0.8500000238418579;
                            Position = UDim2New(0, 1, 0, 1);
                            Name = "\0";
                            BorderSizePixel = 0;
                            BackgroundColor3 = FromRGB(255, 255, 255)
                        });

                        Items.BoxHolderGradient = Instances:Create( "UIGradient" , {
                            Rotation = 0;
                            Name = "\0";
                            Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(255, 255, 255))};
                            Parent = Items.BoxHolder.Instance;
                            Enabled = true
                        }); 

                        Instances:Create( "UIStroke" , {
                            Parent = Items.BoxHolder.Instance;
                            LineJoinMode = Enum.LineJoinMode.Miter
                        });
                        
                        Items.Inner = Instances:Create( "Frame" , {
                            Parent = Items.BoxHolder.Instance;
                            Name = "\0";
                            BackgroundTransparency = 1;
                            Position = UDim2New(0, 1, 0, 1);
                            BorderColor3 = FromRGB(0, 0, 0);
                            Size = UDim2New(1, -2, 1, -2);
                            BorderSizePixel = 0;
                            BackgroundColor3 = FromRGB(255, 255, 255)
                        });

                        Items.UIStroke = Instances:Create( "UIStroke" , {
                            Color = FromRGB(255, 255, 255);
                            LineJoinMode = Enum.LineJoinMode.Miter;
                            Parent = Items.Inner.Instance
                        });
                        
                        Items.BoxGradient = Instances:Create( "UIGradient" , {
                            Rotation = 0;
                            Name = "\0";
                            Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(255, 255, 255))};
                            Parent = Items.UIStroke.Instance;
                            Enabled = true
                        });
                        
                        Items.Inner2 = Instances:Create( "Frame" , {
                            Parent = Items.BoxHolder.Instance;
                            Name = "\0";
                            BackgroundTransparency = 1;
                            Position = UDim2New(0, 2, 0, 2);
                            BorderColor3 = FromRGB(0, 0, 0);
                            Size = UDim2New(1, -4, 1, -4);
                            BorderSizePixel = 0;
                            BackgroundColor3 = FromRGB(255, 255, 255)
                        });

                        Instances:Create( "UIStroke" , {
                            Parent = Items.Inner2.Instance;
                            LineJoinMode = Enum.LineJoinMode.Miter
                        });
                -- Healthbar
                    Items.HealthBar = Instances:Create( "Frame" , {
                        Name = "\0";
                        Parent = Items.Left.Instance;
                        BorderColor3 = FromRGB(0, 0, 0);
                        Size = UDim2New(0, 3, 0, 0);
                        BorderSizePixel = 0;
                        BackgroundColor3 = FromRGB(0, 0, 0)
                    });

                    Items.Bar = Instances:Create( "Frame" , {
                        Parent = Items.HealthBar.Instance;
                        Name = "\0";
                        Position = UDim2New(0, 1, 0, 1);
                        BorderColor3 = FromRGB(0, 0, 0);
                        Size = UDim2New(1, -2, 1, -2);
                        BorderSizePixel = 0;
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    });

                    Items.BarGradient = Instances:Create( "UIGradient" , {
                        Rotation = 90;
                        Parent = Items.Bar.Instance;
                        Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(0, 255, 0)), RGBSequenceKeypoint(0.5, FromRGB(255, 125, 0)), RGBSequenceKeypoint(1, FromRGB(255, 0, 0))}
                    });

                    Items.HealthBarText = Instances:Create( "TextLabel" , {
                        FontFace = ESPFonts["Verdana"];
                        Parent = Items.HealthBar.Instance;
                        TextColor3 = FromRGB(0, 255, 0);
                        Text = "100";
                        Name = "\0";
                        AutomaticSize = Enum.AutomaticSize.XY;
                        Position = UDim2New(0, 1, 0, 0);
                        BorderSizePixel = 0;
                        BackgroundTransparency = 1;
                        AnchorPoint = Vector2New(1, 0),
                        TextXAlignment = Enum.TextXAlignment.Left;
                        BorderColor3 = FromRGB(0, 0, 0);
                        ZIndex = 2;
                        TextSize = 11;
                    })

                    Instances:Create( "UIStroke", {
                        Parent = Items.HealthBarText.Instance;
                        LineJoinMode = Enum.LineJoinMode.Miter
                    });

                -- Name
                        Items.Name = Instances:Create( "TextLabel" , {
                            FontFace = ESPFonts["Verdana"];
                            Parent = Items.TopTexts.Instance;
                            TextColor3 = FromRGB(255, 255, 255);
                            TextStrokeColor3 = FromRGB(255, 255, 255);
                            Text = LocalPlayer.Name;
                            Name = "\0";
                            AutomaticSize = Enum.AutomaticSize.XY;
                            Position = UDim2New(0.5, 1, 0, 0);
                            BorderSizePixel = 0;
                            AnchorPoint = Vector2New(0.5, 0);
                            BackgroundTransparency = 1;
                            TextXAlignment = Enum.TextXAlignment.Center;
                            BorderColor3 = FromRGB(0, 0, 0);
                            ZIndex = 2;
                            TextSize = 11;
                        });

                        Instances:Create( "UIStroke", {
                            Parent = Items.Name.Instance;
                            LineJoinMode = Enum.LineJoinMode.Miter
                        });

                        Items.WeaponText = Instances:Create( "TextLabel" , {
                            FontFace = ESPFonts["Verdana"];
                            Parent = Items.RightTexts.Instance;
                            TextColor3 = FromRGB(255, 255, 255);
                            TextStrokeColor3 = FromRGB(255, 255, 255);
                            Text = "Weapon";
                            Name = "\0";
                            AutomaticSize = Enum.AutomaticSize.XY;
                            Position = UDim2New(0, 1, 0, 0);
                            BorderSizePixel = 0;
                            BackgroundTransparency = 1;
                            TextXAlignment = Enum.TextXAlignment.Center;
                            BorderColor3 = FromRGB(0, 0, 0);
                            ZIndex = 2;
                            TextSize = 11;
                        });

                        Instances:Create( "UIStroke", {
                            Parent = Items.WeaponText.Instance;
                            LineJoinMode = Enum.LineJoinMode.Miter
                        });

                        Items.Distance = Instances:Create( "TextLabel" , {
                            FontFace = ESPFonts["Verdana"];
                            Parent = Items.BottomTexts.Instance;
                            TextColor3 = FromRGB(255, 255, 255);
                            TextStrokeColor3 = FromRGB(255, 255, 255);
                            Text = "Distance";
                            Name = "\0";
                            AutomaticSize = Enum.AutomaticSize.XY;
                            Position = UDim2New(0, 1, 0, 0);
                            BorderSizePixel = 0;
                            BackgroundTransparency = 1;
                            TextXAlignment = Enum.TextXAlignment.Center;
                            BorderColor3 = FromRGB(0, 0, 0);
                            ZIndex = 2;
                            TextSize = 11;
                        });

                        Instances:Create( "UIStroke", {
                            Parent = Items.Distance.Instance;
                            LineJoinMode = Enum.LineJoinMode.Miter
                        });

                -- Corner boxes
                        Items.Corners = Instances:Create( "Frame" , {
                            Parent = Items.Box.Instance;
                            Name = "\0";
                            ClipsDescendants = true;
                            BorderColor3 = FromRGB(0, 0, 0);
                            Size = UDim2New(1, 0, 1, 0);
                            BackgroundTransparency = 1,
                            BorderSizePixel = 0;
                            BackgroundColor3 = FromRGB(255, 255, 255)
                        });

                        Items.CornersGradient = Instances:Create( "UIGradient" , {
                            Parent = Items.Corners.Instance;
                        });

                        Items.BottomLeftX = Instances:Create( "ImageLabel" , {
                            ScaleType = Enum.ScaleType.Slice;
                            Parent = Items.Corners.Instance;
                            BorderColor3 = FromRGB(0, 0, 0);
                            Name = "\0";
                            BackgroundColor3 = FromRGB(255, 255, 255);
                            Size = UDim2New(0.25, 0, 0, 3);
                            AnchorPoint = Vector2New(0, 1);
                            Image = "rbxassetid://83548615999411";
                            BackgroundTransparency = 1;
                            Position = UDim2New(0, 0, 1, 0);
                            ZIndex = 2;
                            BorderSizePixel = 0;
                            SliceCenter = RectNew(Vector2New(1, 1), Vector2New(99, 2))
                        });

                        Instances:Create( "UIGradient" , {
                            Parent = Items.BottomLeftX.Instance
                        });

                        Items.BottomLeftY = Instances:Create( "ImageLabel" , {
                            ScaleType = Enum.ScaleType.Slice;
                            Parent = Items.Corners.Instance;
                            BorderColor3 = FromRGB(0, 0, 0);
                            Name = "\0";
                            BackgroundColor3 = FromRGB(255, 255, 255);
                            Size = UDim2New(0, 3, 0.25, -9);
                            AnchorPoint = Vector2New(0, 1);
                            Image = "rbxassetid://101715268403902";
                            BackgroundTransparency = 1;
                            Position = UDim2New(0, 0, 1, -2);
                            ZIndex = 500;
                            BorderSizePixel = 0;
                            SliceCenter = RectNew(Vector2New(1, 0), Vector2New(2, 96))
                        });

                        Instances:Create( "UIGradient" , {
                            Rotation = -90;
                            Parent = Items.BottomLeftY.Instance
                        });

                        Items.BottomLeftX = Instances:Create( "ImageLabel" , {
                            ScaleType = Enum.ScaleType.Slice;
                            Parent = Items.Corners.Instance;
                            BorderColor3 = FromRGB(0, 0, 0);
                            Name = "\0";
                            BackgroundColor3 = FromRGB(255, 255, 255);
                            Size = UDim2New(0.25, 0, 0, 3);
                            AnchorPoint = Vector2New(1, 1);
                            Image = "rbxassetid://83548615999411";
                            BackgroundTransparency = 1;
                            Position = UDim2New(1, 0, 1, 0);
                            ZIndex = 2;
                            BorderSizePixel = 0;
                            SliceCenter = RectNew(Vector2New(1, 1), Vector2New(99, 2))
                        });

                        Instances:Create( "UIGradient" , {
                            Parent = Items.BottomLeftX.Instance
                        });

                        Items.BottomLeftY = Instances:Create( "ImageLabel" , {
                            ScaleType = Enum.ScaleType.Slice;
                            Parent = Items.Corners.Instance;
                            BorderColor3 = FromRGB(0, 0, 0);
                            Name = "\0";
                            BackgroundColor3 = FromRGB(255, 255, 255);
                            Size = UDim2New(0, 3, 0.25, -9);
                            AnchorPoint = Vector2New(1, 1);
                            Image = "rbxassetid://101715268403902";
                            BackgroundTransparency = 1;
                            Position = UDim2New(1, 0, 1, -2);
                            ZIndex = 500;
                            BorderSizePixel = 0;
                            SliceCenter = RectNew(Vector2New(1, 0), Vector2New(2, 96))
                        });

                        Instances:Create( "UIGradient" , {
                            Rotation = 90;
                            Parent = Items.BottomLeftY.Instance
                        });

                        Items.TopLeftY = Instances:Create( "ImageLabel" , {
                            ScaleType = Enum.ScaleType.Slice;
                            BorderColor3 = FromRGB(0, 0, 0);
                            Parent = Items.Corners.Instance;
                            Name = "\0";
                            BackgroundColor3 = FromRGB(255, 255, 255);
                            Size = UDim2New(0, 3, 0.25, -9);
                            Image = "rbxassetid://102467475629368";
                            BackgroundTransparency = 1;
                            Position = UDim2New(0, 0, 0, 2);
                            ZIndex = 500;
                            BorderSizePixel = 0;
                            SliceCenter = RectNew(Vector2New(1, 0), Vector2New(2, 98))
                        });

                        Instances:Create( "UIGradient" , {
                            Rotation = 90;
                            Parent = Items.TopLeftY.Instance
                        });

                        Items.TopRightY = Instances:Create( "ImageLabel" , {
                            ScaleType = Enum.ScaleType.Slice;
                            Parent = Items.Corners.Instance;
                            BorderColor3 = FromRGB(0, 0, 0);
                            Name = "\0";
                            BackgroundColor3 = FromRGB(255, 255, 255);
                            Size = UDim2New(0, 3, 0.25, -9);
                            AnchorPoint = Vector2New(1, 0);
                            Image = "rbxassetid://102467475629368";
                            BackgroundTransparency = 1;
                            Position = UDim2New(1, 0, 0, 2);
                            ZIndex = 500;
                            BorderSizePixel = 0;
                            SliceCenter = RectNew(Vector2New(1, 0), Vector2New(2, 98))
                        });

                        Instances:Create( "UIGradient" , {
                            Rotation = -90;
                            Parent = Items.TopRightY.Instance
                        });

                        Items.TopRightX = Instances:Create( "ImageLabel" , {
                            ScaleType = Enum.ScaleType.Slice;
                            Parent = Items.Corners.Instance;
                            BorderColor3 = FromRGB(0, 0, 0);
                            Name = "\0";
                            BackgroundColor3 = FromRGB(255, 255, 255);
                            Size = UDim2New(0.25, 0, 0, 3);
                            AnchorPoint = Vector2New(1, 0);
                            Image = "rbxassetid://83548615999411";
                            BackgroundTransparency = 1;
                            Position = UDim2New(1, 0, 0, 0);
                            ZIndex = 2;
                            BorderSizePixel = 0;
                            SliceCenter = RectNew(Vector2New(1, 1), Vector2New(99, 2))
                        });

                        Instances:Create( "UIGradient" , {
                            Parent = Items.TopRightX.Instance
                        });

                        Items.TopLeftX = Instances:Create( "ImageLabel" , {
                            ScaleType = Enum.ScaleType.Slice;
                            BorderColor3 = FromRGB(0, 0, 0);
                            Parent = Items.Corners.Instance;
                            Name = "\0";
                            BackgroundColor3 = FromRGB(255, 255, 255);
                            Image = "rbxassetid://83548615999411";
                            BackgroundTransparency = 1;
                            Size = UDim2New(0.25, 0, 0, 3);
                            ZIndex = 2;
                            BorderSizePixel = 0;
                            SliceCenter = RectNew(Vector2New(1, 1), Vector2New(99, 2))
                        });

                        Instances:Create( "UIGradient" , {
                            Parent = Items.TopLeftX.Instance
                        });

                ESPPreview.Items = Items
            end

            function ESPPreview:Set(Item, Property, Value)
                Items[Item].Instance[Property] = Value
            end

            local Math = {} do
                local inf = math.huge
                local negative_inf = -math.huge

                Math.GetBoundingBox = LPH_NO_VIRTUALIZE(function(self, model, camera, ViewportFrame)
                    model = type(model) ~= 'table' and model:GetDescendants() or model
                    local Min, Max = Vector2New(inf, inf), Vector2New(negative_inf, negative_inf)
                    
                    for _,v in model do
                        if not v:IsA("BasePart") then
                            continue
                        end

                        local Size, cFrame = v.Size, v.CFrame

                        local Corners = {
                            Vector3New( 0.5,  0.5,  0.5),
                            Vector3New(-0.5,  0.5,  0.5),
                            Vector3New( 0.5, -0.5,  0.5),
                            Vector3New(-0.5, -0.5,  0.5),
                            Vector3New( 0.5,  0.5, -0.5),
                            Vector3New(-0.5,  0.5, -0.5),
                            Vector3New( 0.5, -0.5, -0.5),
                            Vector3New(-0.5, -0.5, -0.5),
                        }

                        for _,corner in Corners do
                            local Point = cFrame:PointToWorldSpace(Vector3New(
                                corner.X * Size.X,
                                corner.Y * Size.Y,
                                corner.Z * Size.Z
                            ))

                            local Viewport, Visible = camera:WorldToViewportPoint(Point)

                            if Visible then
                                Min = Vector2New(MathMin(Min.X, Viewport.X), MathMin(Min.Y, Viewport.Y))
                                Max = Vector2New(MathMax(Max.X, Viewport.X), MathMax(Max.Y, Viewport.Y))
                            end
                        end
                    end

                    local AbsoluteSize = ViewportFrame.AbsoluteSize

                    local Size2D = Max - Min

                    local Position = Vector2New(Min.X - 0.05, Min.Y)
                    local Size = Vector2New(Size2D.X + 0.1, Size2D.Y)

                    return UDim2FromScale(Position.X, Position.Y), UDim2FromScale(Size.X, Size.Y)
                end)
            end

            function ESPPreview:SetVisibility(Bool)
                Items["EspPreview"].Instance.Visible = Bool
            end
            
            Items["CloseButton"]:Connect("MouseButton1Down", function()
                ESPPreview:SetVisibility(false)
            end)

            local LocalCharacter = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

            local ViewportCamera = InstanceNew("Camera")
            Items["CharacterViewport"].Instance.CurrentCamera = ViewportCamera
            ViewportCamera.CameraType = Enum.CameraType.Track
            ViewportCamera.Focus = CFrameNew(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1)
            ViewportCamera.CFrame = CFrameNew(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1)

            Library:Connect(RunService.RenderStepped, LPH_NO_VIRTUALIZE(function()	
                local Pos, Size = Math:GetBoundingBox(ESPPreview.Player, ViewportCamera, Items.CharacterViewport.Instance)
                Items.Box.Instance.Position = Pos
                Items.Box.Instance.Size = Size
            end))

            local ViewportModel

            if LocalCharacter then
                LocalCharacter.Archivable = true
                ViewportModel = LocalCharacter:Clone()

                --ViewportModel.chatpart:Destroy()
                ViewportModel.PrimaryPart.Anchored = true
                ViewportModel.Parent = Items["CharacterViewport"].Instance

                for Index, Value in ViewportModel:GetDescendants() do
                    if Value:IsA("LocalScript") then
                        Value:Destroy()
                    end
                end

                local HumanoidRootPart = ViewportModel:FindFirstChild("HumanoidRootPart")

                if HumanoidRootPart then
                    if not ViewportModel.PrimaryPart then
                        ViewportModel.PrimaryPart = HumanoidRootPart
                    end

                    ViewportModel:SetPrimaryPartCFrame(CFrameAngles(0, MathRad(180), 0) + Vector3New(0, 1.5, 0))
                    ViewportCamera.CFrame = CFrameNew(Vector3New(0, 2, 6), Vector3New(0, 1, 0))
                end

                ESPPreview.Player = ViewportModel
            end

            ViewportCamera.CameraSubject = ViewportModel

            local LastPosition 
            local IsRotating = false

            local Sensitivity = 0.7

            local Yaw = MathRad(180)
            local Roll = 0
            local Pitch = 0

            local ClampPitch = function(PitchValue)
                return MathClamp(PitchValue, MathRad(-80), MathRad(80))
            end

            local ViewportInputChanged
            Items["CharacterViewport"]:Connect("InputBegan", LPH_NO_VIRTUALIZE(function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                    IsRotating = true
                    LastPosition = Input.Position

                    if ViewportInputChanged then 
                        return
                    end
                    
                    ViewportInputChanged = Input.Changed:Connect(function()
                        if Input.UserInputState == Enum.UserInputState.End then
                            IsRotating = false

                            ViewportInputChanged:Disconnect()
                            ViewportInputChanged = nil
                        end
                    end)
                end
            end))

            Items["CharacterViewport"]:Connect("InputChanged", LPH_NO_VIRTUALIZE(function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then
                    if not LastPosition then 
                        return
                    end

                    if not IsRotating then
                        return
                    end
                    
                    local RotationDelta = Input.Position - LastPosition

                    Yaw = Yaw - MathRad(RotationDelta.X * Sensitivity)
                    Pitch = ClampPitch(Pitch - MathRad(RotationDelta.Y * Sensitivity))

                    LastPosition = Input.Position

                    if ViewportModel and ViewportModel.PrimaryPart then
                        local Rotation = CFrameAngles(Pitch, Yaw, Roll)
                        ViewportModel:SetPrimaryPartCFrame(Rotation + Vector3.new(0, 1.5, 0))
                    end
                end
            end))

            return ESPPreview
        end
        
        Library.ChatSystem = function(self, Data)
            local GlobalChat = { }

            local Items = { } do 
                Items["Chat_System"] = Instances:Create("Frame", {
                    Parent = Data.MainFrame.Instance,
                    Name = "\0",
                    AnchorPoint = Vector2New(1, 0),
                    Position = UDim2New(0, -15, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 378, 0, 511),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(16, 18, 21)
                })  Items["Chat_System"]:AddToTheme({BackgroundColor3 = "Background"})

                Items["Chat_System"]:MakeDraggable()

                Instances:Create("UICorner", {
                    Parent = Items["Chat_System"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 5)
                })

                Instances:Create("UIStroke", {
                    Parent = Items["Chat_System"].Instance,
                    Name = "\0",
                    Color = FromRGB(32, 36, 42),
                    Transparency = 0.4000000059604645,
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                }):AddToTheme({Color = "Border"})

                Items["Topbar"] = Instances:Create("Frame", {
                    Parent = Items["Chat_System"].Instance,
                    Name = "\0",
                    Size = UDim2New(1, 0, 0, 35),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(22, 25, 29)
                })  Items["Topbar"]:AddToTheme({BackgroundColor3 = "Inline"})

                Instances:Create("UICorner", {
                    Parent = Items["Topbar"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 5)
                })

                Instances:Create("Frame", {
                    Parent = Items["Topbar"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(0, 1),
                    Position = UDim2New(0, 0, 1, 0),
                    Size = UDim2New(1, 0, 0, 3),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(22, 25, 29)
                }):AddToTheme({BackgroundColor3 = "Inline"})

                Instances:Create("Frame", {
                    Parent = Items["Topbar"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(0, 1),
                    BackgroundTransparency = 0.4000000059604645,
                    Position = UDim2New(0, 0, 1, 0),
                    Size = UDim2New(1, 0, 0, 1),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(32, 36, 42)
                }):AddToTheme({BackgroundColor3 = "Border"})

                Instances:Create("UIGradient", {
                    Parent = Items["Topbar"].Instance,
                    Name = "\0",
                    Rotation = 84,
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(211, 211, 211))}
                }):AddToTheme({Color = function()
                    return RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, Library.Theme["Dark Gradient"])}
                end})

                Items["Logo"] = Instances:Create("ImageLabel", {
                    Parent = Items["Topbar"].Instance,
                    Name = "\0",
                    ImageColor3 = FromRGB(196, 231, 255),
                    ScaleType = Enum.ScaleType.Fit,
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 16, 0, 16),
                    AnchorPoint = Vector2New(0, 0.5),
                    Image = "rbxassetid://103982381939732",
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 10, 0.5, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Logo"]:AddToTheme({ImageColor3 = "Accent"})

                Items["Title"] = Instances:Create("TextLabel", {
                    Parent = Items["Topbar"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    AnchorPoint = Vector2New(0, 0.5),
                    ZIndex = 2,
                    TextSize = 14,
                    Size = UDim2New(0, 0, 0, 15),
                    RichText = true,
                    TextColor3 = FromRGB(255, 255, 255),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "Global Chat",
                    BackgroundTransparency = 1,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Position = UDim2New(0, 37, 0.5, 0),
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.X,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Title"]:AddToTheme({TextColor3 = "Text"})

                Items["CloseButton"] = Instances:Create("ImageButton", {
                    Parent = Items["Topbar"].Instance,
                    Name = "\0",
                    ScaleType = Enum.ScaleType.Fit,
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 17, 0, 17),
                    AutoButtonColor = false,
                    AnchorPoint = Vector2New(1, 0.5),
                    Image = "rbxassetid://76001605964586",
                    BackgroundTransparency = 1,
                    Position = UDim2New(1, -7, 0.5, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["CloseButton"]:AddToTheme({ImageColor3 = "Image"})

                Items["StatusCircle"] = Instances:Create("Frame", {
                    Parent = Items["Topbar"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(1, 0.5),
                    Position = UDim2New(1, -33, 0.5, 0),
                    Size = UDim2New(0, 12, 0, 12),
                    ZIndex = 3,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 210, 62)
                })

                Instances:Create("UICorner", {
                    Parent = Items["StatusCircle"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(1, 0)
                })

                Instances:Create("UIGradient", {
                    Parent = Items["StatusCircle"].Instance,
                    Name = "\0",
                    Rotation = 90,
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(211, 211, 211))}
                }):AddToTheme({Color = function()
                    return RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, Library.Theme["Dark Gradient"])}
                end})

                Items["StatusText"] = Instances:Create("TextLabel", {
                    Parent = Items["Topbar"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(255, 210, 62),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "Connecting...",
                    AutomaticSize = Enum.AutomaticSize.X,
                    Size = UDim2New(0, 0, 0, 15),
                    AnchorPoint = Vector2New(1, 0.5),
                    Position = UDim2New(1, -50, 0.5, 0),
                    BackgroundTransparency = 1,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    BorderSizePixel = 0,
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Items["Glow"] = Instances:Create("ImageLabel", {
                    Parent = Items["StatusCircle"].Instance,
                    Name = "\0",
                    ImageColor3 = FromRGB(255, 210, 62),
                    ScaleType = Enum.ScaleType.Slice,
                    ImageTransparency = 0.30000001192092896,
                    BorderColor3 = FromRGB(0, 0, 0),
                    BackgroundColor3 = FromRGB(255, 255, 255),
                    Size = UDim2New(1, 8, 1, 8),
                    AnchorPoint = Vector2New(0.5, 0.5),
                    Image = "http://www.roblox.com/asset/?id=18245826428",
                    BackgroundTransparency = 1,
                    Position = UDim2New(0.5, 0, 0.5, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    SliceCenter = RectNew(Vector2New(21, 21), Vector2New(79, 79))
                })

                Items["SendMessage"] = Instances:Create("Frame", {
                    Parent = Items["Chat_System"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(0, 1),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 8, 1, -8),
                    Size = UDim2New(1, -16, 0, 35),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  

                Items["Input"] = Instances:Create("TextBox", {
                    Parent = Items["SendMessage"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    MultiLine = true,
                    CursorPosition = -1,
                    PlaceholderColor3 = FromRGB(185, 185, 185),
                    PlaceholderText = "PLEASE WAIT, CURRENTLY LOADING...",
                    TextSize = 14,
                    Size = UDim2New(1, -45, 1, 0),
                    TextColor3 = FromRGB(255, 255, 255),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextWrapped = true,
                    ClearTextOnFocus = false,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(34, 39, 45)
                })  Items["Input"]:AddToTheme({BackgroundColor3 = "Element"})

                getgenv().SendMessage_Input = Items["Input"]

                Instances:Create("UICorner", {
                    Parent = Items["Input"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })

                Instances:Create("UIPadding", {
                    Parent = Items["Input"].Instance,
                    Name = "\0",
                    PaddingLeft = UDimNew(0, 8)
                })

                Items["SendMessageButton"] = Instances:Create("TextButton", {
                    Parent = Items["SendMessage"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    AutoButtonColor = false,
                    AnchorPoint = Vector2New(1, 0),
                    Position = UDim2New(1, 0, 0, 0),
                    Size = UDim2New(0, 35, 1, 0),
                    BorderSizePixel = 0,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(34, 39, 45)
                })  Items["SendMessageButton"]:AddToTheme({BackgroundColor3 = "Element"})

                Instances:Create("UICorner", {
                    Parent = Items["SendMessageButton"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })

                Items["SendImageLabel"] = Instances:Create("ImageLabel", {
                    Parent = Items["SendMessageButton"].Instance,
                    Name = "\0",
                    ImageColor3 = FromRGB(196, 231, 255),
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(0.5, 0.5),
                    Image = "rbxassetid://93681479181206",
                    BackgroundTransparency = 1,
                    Position = UDim2New(0.5, 0, 0.5, 0),
                    Size = UDim2New(0, 16, 0, 16),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["SendImageLabel"]:AddToTheme({ImageColor3 = "Accent"})

                Items["Messages"] = Instances:Create("ScrollingFrame", {
                    Parent = Items["Chat_System"].Instance,
                    Name = "\0",
                    AutomaticCanvasSize = Enum.AutomaticSize.Y,
                    BorderSizePixel = 0,
                    CanvasSize = UDim2New(0, 0, 0, 0),
                    ScrollBarImageColor3 = FromRGB(196, 231, 255),
                    MidImage = "rbxassetid://76010408336709",
                    BorderColor3 = FromRGB(0, 0, 0),
                    ScrollBarThickness = 2,
                    Size = UDim2New(1, 0, 1, -80),
                    Selectable = false,
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 0, 0, 35),
                    BottomImage = "rbxassetid://76010408336709",
                    TopImage = "rbxassetid://76010408336709",
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Messages"]:AddToTheme({ScrollBarImageColor3 = "Accent"})

                Instances:Create("UIListLayout", {
                    Parent = Items["Messages"].Instance,
                    Name = "\0",
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Archivable = false,
                    Padding = UDimNew(0, 8)
                })

                Instances:Create("UIPadding", {
                    Parent = Items["Messages"].Instance,
                    Name = "\0",
                    PaddingTop = UDimNew(0, 8),
                    PaddingBottom = UDimNew(0, 8),
                    PaddingRight = UDimNew(0, 12),
                    PaddingLeft = UDimNew(0, 8)
                })
            end

            function GlobalChat:SetVisibility(Bool)
                Items["Chat_System"].Instance.Visible = Bool
                
                pcall(function()
                    Items["Chat_System"].Instance.Parent = Bool and Data.MainFrame.Instance or Library.UnusedHolder
                end)
            end

            local Done = false

            function GlobalChat:SetStatusText(Text)
                if not Done then
                    Items["StatusText"].Instance.TextColor3 = FromRGB(62, 255, 91)
                    Items["Glow"].Instance.ImageColor3 = FromRGB(62, 255, 91)
                    Items["StatusCircle"].Instance.BackgroundColor3 = FromRGB(62, 255, 91)
                    Done = true
                end
                Items["StatusText"].Instance.Text = Text
            end

            local OnMessagePressed            

            function GlobalChat:OnMessageSendPressed(Func)
                OnMessagePressed = Func
            end

            function GlobalChat:GetTypedMessage()
                return Items["Input"].Instance.Text
            end

            function GlobalChat:ClearText()
                Items["Input"].Instance.Text = ""
            end

            function GlobalChat:SendMessage(Avatar, Username, Message, IsLocalPlayer)
                local SubItems = { } do
                    if not IsLocalPlayer then
                        SubItems["Message1"] = Instances:Create("Frame", {
                            Parent = Items["Messages"].Instance,
                            Name = "\0",
                            BackgroundTransparency = 1,
                            Size = UDim2New(1, 0, 0, 45),
                            BorderColor3 = FromRGB(0, 0, 0),
                            BorderSizePixel = 0,
                            AutomaticSize = Enum.AutomaticSize.Y,
                            BackgroundColor3 = FromRGB(255, 255, 255)
                        })

                        SubItems["PlayerName"] = Instances:Create("TextLabel", {
                            Parent = SubItems["Message1"].Instance,
                            Name = "\0",
                            FontFace = Library.Font,
                            TextColor3 = FromRGB(255, 255, 255),
                            BorderColor3 = FromRGB(0, 0, 0),
                            Text = Username,
                            Size = UDim2New(0, 0, 0, 15),
                            RichText = true,
                            BackgroundTransparency = 1,
                            Position = UDim2New(0, 38, 0, 0),
                            BorderSizePixel = 0,
                            AutomaticSize = Enum.AutomaticSize.X,
                            TextSize = 14,
                            BackgroundColor3 = FromRGB(255, 255, 255)
                        })  SubItems["PlayerName"]:AddToTheme({TextColor3 = "Text"})

                        SubItems["RealMessage"] = Instances:Create("Frame", {
                            Parent = SubItems["Message1"].Instance,
                            Name = "\0",
                            Position = UDim2New(0, 38, 0, 20),
                            BorderColor3 = FromRGB(0, 0, 0),
                            BorderSizePixel = 0,
                            AutomaticSize = Enum.AutomaticSize.XY,
                            BackgroundColor3 = FromRGB(22, 25, 29)
                        })  SubItems["RealMessage"]:AddToTheme({BackgroundColor3 = "Inline"})

                        Instances:Create("UISizeConstraint", {
                            Parent = SubItems["RealMessage"].Instance,
                            Name = "\0",
                            MaxSize = Vector2New(370, 75)
                        })

                        Instances:Create("UICorner", {
                            Parent = SubItems["RealMessage"].Instance,
                            Name = "\0",
                            CornerRadius = UDimNew(0, 4)
                        })

                        SubItems["MessageText"] = Instances:Create("TextLabel", {
                            Parent = SubItems["RealMessage"].Instance,
                            Name = "\0",
                            FontFace = Library.Font,
                            TextColor3 = FromRGB(255, 255, 255),
                            BorderColor3 = FromRGB(0, 0, 0),
                            Text = Message,
                            BackgroundTransparency = 1,
                            TextWrapped = true,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            BorderSizePixel = 0,
                            TextWrapped = true,
                            AutomaticSize = Enum.AutomaticSize.XY,
                            TextSize = 14,
                            BackgroundColor3 = FromRGB(255, 255, 255)
                        })  SubItems["MessageText"]:AddToTheme({TextColor3 = "Text"})

                        Instances:Create("UIPadding", {
                            Parent = SubItems["RealMessage"].Instance,
                            Name = "\0",
                            PaddingTop = UDimNew(0, 8),
                            PaddingBottom = UDimNew(0, 8),
                            PaddingRight = UDimNew(0, 8),
                            PaddingLeft = UDimNew(0, 8)
                        })

                        SubItems["Avatar"] = Instances:Create("ImageLabel", {
                            Parent = SubItems["Message1"].Instance,
                            Name = "\0",
                            BorderColor3 = FromRGB(0, 0, 0),
                            AnchorPoint = Vector2New(0, 0.5),
                            Image = Avatar,
                            BackgroundTransparency = 1,
                            Position = UDim2New(0, 0, 0.5, 0),
                            Size = UDim2New(0, 30, 0, 30),
                            BorderSizePixel = 0,
                            BackgroundColor3 = FromRGB(255, 255, 255)
                        })

                        Instances:Create("UICorner", {
                            Parent = SubItems["Avatar"].Instance,
                            Name = "\0",
                            CornerRadius = UDimNew(0, 4)
                        })
                    else
                        SubItems["Message1"] = Instances:Create("Frame", {
                            Parent = Items["Messages"].Instance,
                            Name = "\0",
                            BackgroundTransparency = 1,
                            Size = UDim2New(1, 0, 0, 45),
                            BorderColor3 = FromRGB(0, 0, 0),
                            BorderSizePixel = 0,
                            AutomaticSize = Enum.AutomaticSize.Y,
                            BackgroundColor3 = FromRGB(255, 255, 255)
                        })

                        SubItems["PlayerName"] = Instances:Create("TextLabel", {
                            Parent = SubItems["Message1"].Instance,
                            Name = "\0",
                            FontFace = Library.Font,
                            TextColor3 = FromRGB(255, 255, 255),
                            BorderColor3 = FromRGB(0, 0, 0),
                            Text = Username,
                            RichText = true,
                            AnchorPoint = Vector2New(1, 0),
                            Size = UDim2New(0, 0, 0, 15),
                            BackgroundTransparency = 1,
                            Position = UDim2New(1, -38, 0, 0),
                            BorderSizePixel = 0,
                            AutomaticSize = Enum.AutomaticSize.X,
                            TextSize = 14,
                            BackgroundColor3 = FromRGB(255, 255, 255)
                        })  SubItems["PlayerName"]:AddToTheme({TextColor3 = "Text"})

                        SubItems["RealMessage"] = Instances:Create("Frame", {
                            Parent = SubItems["Message1"].Instance,
                            Name = "\0",
                            AnchorPoint = Vector2New(1, 0),
                            Position = UDim2New(1, -38, 0, 20),
                            BorderColor3 = FromRGB(0, 0, 0),
                            BorderSizePixel = 0,
                            AutomaticSize = Enum.AutomaticSize.XY,
                            BackgroundColor3 = FromRGB(22, 25, 29)
                        })  SubItems["RealMessage"]:AddToTheme({BackgroundColor3 = "Inline"})

                        Instances:Create("UISizeConstraint", {
                            Parent = SubItems["RealMessage"].Instance,
                            Name = "\0",
                            MaxSize = Vector2New(370, 75)
                        })

                        Instances:Create("UICorner", {
                            Parent = SubItems["RealMessage"].Instance,
                            Name = "\0",
                            CornerRadius = UDimNew(0, 4)
                        })

                        SubItems["MessageText"] = Instances:Create("TextLabel", {
                            Parent = SubItems["RealMessage"].Instance,
                            Name = "\0",
                            FontFace = Library.Font,
                            TextColor3 = FromRGB(255, 255, 255),
                            BorderColor3 = FromRGB(0, 0, 0),
                            Text = Message,
                            BackgroundTransparency = 1,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            BorderSizePixel = 0,
                            AutomaticSize = Enum.AutomaticSize.XY,
                            TextWrapped = true,
                            TextSize = 14,
                            BackgroundColor3 = FromRGB(255, 255, 255)
                        })  SubItems["MessageText"]:AddToTheme({TextColor3 = "Text"})

                        Instances:Create("UIPadding", {
                            Parent = SubItems["RealMessage"].Instance,
                            Name = "\0",
                            PaddingTop = UDimNew(0, 8),
                            PaddingBottom = UDimNew(0, 8),
                            PaddingRight = UDimNew(0, 8),
                            PaddingLeft = UDimNew(0, 8)
                        })

                        SubItems["Avatar"] = Instances:Create("ImageLabel", {
                            Parent = SubItems["Message1"].Instance,
                            Name = "\0",
                            BorderColor3 = FromRGB(0, 0, 0),
                            AnchorPoint = Vector2New(1, 0.5),
                            Image = Avatar,
                            BackgroundTransparency = 1,
                            Position = UDim2New(1, 0, 0.5, 0),
                            Size = UDim2New(0, 30, 0, 30),
                            BorderSizePixel = 0,
                            BackgroundColor3 = FromRGB(255, 255, 255)
                        })

                        Instances:Create("UICorner", {
                            Parent = SubItems["Avatar"].Instance,
                            Name = "\0",
                            CornerRadius = UDimNew(0, 4)
                        })
                    end
                end
            end

            Items["CloseButton"]:Connect("MouseButton1Down", function()
                GlobalChat:SetVisibility(false)

                if GlobalChat_Toggle then
                    GlobalChat_Toggle:Set(false)
                end
            end)
            
            Items["SendMessageButton"]:Connect("MouseButton1Down", function()
                if GlobalChat:GetTypedMessage() == "" then
                    return
                end
                
                task.spawn(OnMessagePressed)
                Items["SendMessageButton"]:Tween(nil, {BackgroundColor3 = Library:GetDarkerColor(Library.Theme.Accent)})
                task.wait(0.1)
                Items["SendMessageButton"]:Tween(nil, {BackgroundColor3 = Library.Theme.Element})
            end)

            Items["SendMessageButton"]:Connect("MouseEnter", function()
                Items["SendMessageButton"]:Tween(nil, {BackgroundColor3 = Library:GetDarkerColor(Library.Theme.Element)})
            end)

            Items["SendMessageButton"]:Connect("MouseLeave", function()
                Items["SendMessageButton"]:Tween(nil, {BackgroundColor3 = Library.Theme.Element})
            end)

            Items["Input"]:Connect("MouseEnter", function()
                Items["Input"]:Tween(nil, {BackgroundColor3 = Library:GetDarkerColor(Library.Theme.Element)})
            end)

            Items["Input"]:Connect("MouseLeave", function()
                Items["Input"]:Tween(nil, {BackgroundColor3 = Library.Theme.Element})
            end)

            Items["Messages"]:Connect("ChildAdded", function()
                wait() -- wait so we ensure the child is added
                Items["Messages"]:Tween(nil, {CanvasPosition = Vector2New(0, Items["Messages"].Instance.AbsoluteCanvasSize.Y - Items["Messages"].Instance.AbsoluteSize.Y)})
            end)

            return GlobalChat 
        end
        
        Library.Notification = function(self, Data)
            Data = Data or { }

            local Notification = {
                Name = Data.Name or Data.name or "Title",
                Description = Data.Description or Data.description or "Description",
                Duration = Data.Duration or Data.duration or 5,
                Icon = Data.Icon or Data.icon or "9080568477801",
                IconColor = Data.IconColor ~= nil and (type(Data.IconColor) == "table" and Data.IconColor.Start or type(Data.IconColor) == "userdata" and Data.IconColor) or Color3.new(1,1,1),
            }

            if type(Notification.Icon) == "string" and not string.find(Notification.Icon, not Volcano and ".png" or "rbxasset://") then
                Notification.Icon = "rbxassetid://"..Notification.Icon
            end

            local Items = { } do
                Items["Notification"] = Instances:Create("Frame", {
                    Parent = Library.NotifHolder.Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.XY,
                    BackgroundColor3 = FromRGB(16, 18, 21)
                })  Items["Notification"]:AddToTheme({BackgroundColor3 = "Background"})

                Instances:Create("UIStroke", {
                    Parent = Items["Notification"].Instance,
                    Name = "\0",
                    Color = FromRGB(32, 36, 42),
                    Transparency = 0.4000000059604645,
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                }):AddToTheme({Color = "Border"})

                Instances:Create("UICorner", {
                    Parent = Items["Notification"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 5)
                })

                Instances:Create("UIPadding", {
                    Parent = Items["Notification"].Instance,
                    Name = "\0",
                    PaddingTop = UDimNew(0, 8),
                    PaddingBottom = UDimNew(0, 8),
                    PaddingRight = UDimNew(0, 8),
                    PaddingLeft = UDimNew(0, 8)
                })

                if Notification.Icon then 
                    Items["Icon"] = Instances:Create("ImageLabel", {
                        Parent = Items["Notification"].Instance,
                        Name = "\0",
                        ImageColor3 = Notification.IconColor,
                        BorderColor3 = FromRGB(0, 0, 0),
                        AnchorPoint = Vector2New(1, 0),
                        Image = "rbxassetid://"..Notification.Icon,
                        BackgroundTransparency = 1,
                        Position = UDim2New(1, 5, 0, 0),
                        Size = UDim2New(0, 22, 0, 22),
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })
                end

                Items["Title"] = Instances:Create("TextLabel", {
                    Parent = Items["Notification"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(255, 255, 255),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = Notification.Name,
                    Size = UDim2New(0, 0, 0, 15),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 0, 0, 2),
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.X,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Title"]:AddToTheme({TextColor3 = "Text"})

                Items["Description"] = Instances:Create("TextLabel", {
                    Parent = Items["Notification"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(255, 255, 255),
                    TextTransparency = 0.5,
                    Text = Notification.Description,
                    Size = UDim2New(0, 0, 0, 15),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 0, 0, 24),
                    BorderColor3 = FromRGB(0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.X,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Description"]:AddToTheme({TextColor3 = "Inactive Text"})
            end

            local OldSize = Items["Notification"].Instance.AbsoluteSize
            Items["Notification"].Instance.BackgroundTransparency = 1
            Items["Notification"].Instance.Size = UDim2New(0, 0, 0, 0)

            for Index, Value in Items["Notification"].Instance:GetDescendants() do
                if Value:IsA("UIStroke") then 
                    Value.Transparency = 1
                elseif Value:IsA("TextLabel") then 
                    Value.TextTransparency = 1
                elseif Value:IsA("ImageLabel") then 
                    Value.ImageTransparency = 1
                elseif Value:IsA("Frame") then 
                    Value.BackgroundTransparency = 1
                end
            end
            
            task.wait(0.2)

            Items["Notification"].Instance.AutomaticSize = Enum.AutomaticSize.None

            Library:Thread(function()
                Items["Notification"]:Tween(nil, {BackgroundTransparency = 0, Size = UDim2New(0,  OldSize.X, 0, OldSize.Y)})
                
                task.wait(0.06)

                for Index, Value in Items["Notification"].Instance:GetDescendants() do
                    if Value:IsA("UIStroke") then
                        Tween:Create(Value, nil, {Transparency = 0}, true)
                    elseif Value:IsA("TextLabel") then
                        Tween:Create(Value, nil, {TextTransparency = 0}, true)
                    elseif Value:IsA("ImageLabel") then
                        Tween:Create(Value, nil, {ImageTransparency = 0}, true)
                    elseif Value:IsA("Frame") then
                        Tween:Create(Value, nil, {BackgroundTransparency = 0}, true)
                    end
                end

                task.delay(Data.Duration, function()
                    for Index, Value in Items["Notification"].Instance:GetDescendants() do
                        if Value:IsA("UIStroke") then
                            Tween:Create(Value, nil, {Transparency = 1}, true)
                        elseif Value:IsA("TextLabel") then
                            Tween:Create(Value, nil, {TextTransparency = 1}, true)
                        elseif Value:IsA("ImageLabel") then
                            Tween:Create(Value, nil, {ImageTransparency = 1}, true)
                        elseif Value:IsA("Frame") then
                            Tween:Create(Value, nil, {BackgroundTransparency = 1}, true)
                        end
                    end

                    task.wait(0.06)

                    Items["Notification"]:Tween(nil, {BackgroundTransparency = 1, Size = UDim2New(0, 0, 0, 0)})

                    task.wait(0.5)
                    Items["Notification"]:Clean()
                end)
            end)

            return Notification
        end

        Library.Watermark = function(self, Text, Logo)
            local Watermark = { }

            local Items = { } do
                Items["Watermark"] = Instances:Create("Frame", {
                    Parent = Library.Holder.Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(0.5, 0),
                    Position = UDim2New(0.5, 0, 0, 15),
                    Size = UDim2New(0, 100, 0, 35),
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.X,
                    BackgroundColor3 = FromRGB(16, 18, 21)
                })  Items["Watermark"]:AddToTheme({BackgroundColor3 = "Background"})

                Items["Watermark"]:MakeDraggable()

                Instances:Create("UIGradient", {
                    Parent = Items["Watermark"].Instance,
                    Name = "\0",
                    Rotation = 84,
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(211, 211, 211))}
                }):AddToTheme({Color = function()
                    return RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, Library.Theme["Dark Gradient"])}
                end})

                Instances:Create("UICorner", {
                    Parent = Items["Watermark"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 5)
                })

                --[[Items["Logo"] = Instances:Create("ImageLabel", {
                    Parent = Items["Watermark"].Instance,
                    Name = "\0",
                    ImageColor3 = FromRGB(196, 231, 255),
                    ScaleType = Enum.ScaleType.Fit,
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 22, 0, 22),
                    AnchorPoint = Vector2New(0, 0.5),
                    Image = "rbxassetid://"..Logo,
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 7, 0.5, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Logo"]:AddToTheme({ImageColor3 = "Accent"})]]

                Items["Text"] = Instances:Create("TextLabel", {
                    Parent = Items["Watermark"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(255, 255, 255),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = Text,
                    RichText = true,
                    AnchorPoint = Vector2New(0, 0.5),
                    Size = UDim2New(0, 0, 0, 15),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 8, 0.5, 0),
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.X,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Text"]:AddToTheme({TextColor3 = "Text"})

                Instances:Create("UIPadding", {
                    Parent = Items["Watermark"].Instance,
                    Name = "\0",
                    PaddingRight = UDimNew(0, 7)
                })
            end

            function Watermark:SetVisibility(Bool)
                Items["Watermark"].Instance.Visible = Bool
            end

            function Watermark:SetText(Text)
                Items["Text"].Instance.Text = Text
            end

            return Watermark 
        end

        Library.KeybindsList = function(self)
            local KeybindList = { }
            self.KeyList = KeybindList

            local Items = { } do
                Items["KeybindsList"] = Instances:Create("Frame", {
                    Parent = Library.Holder.Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(0, 0.5),
                    Position = UDim2New(0, 15, 0.5, 85),
                    Size = UDim2New(0, 100, 0, 100),
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.XY,
                    BackgroundColor3 = FromRGB(16, 18, 21)
                })  Items["KeybindsList"]:AddToTheme({BackgroundColor3 = "Background"})

                Items["KeybindsList"]:MakeDraggable()

                Instances:Create("UICorner", {
                    Parent = Items["KeybindsList"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 5)
                })

                Instances:Create("UIGradient", {
                    Parent = Items["KeybindsList"].Instance,
                    Name = "\0",
                    Rotation = 84,
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(211, 211, 211))}
                }):AddToTheme({Color = function()
                    return RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, Library.Theme["Dark Gradient"])}
                end})

                Items["Icon"] = Instances:Create("ImageLabel", {
                    Parent = Items["KeybindsList"].Instance,
                    Name = "\0",
                    ImageColor3 = FromRGB(196, 231, 255),
                    ScaleType = Enum.ScaleType.Fit,
                    BorderColor3 = FromRGB(0, 0, 0),
                    Image = "rbxassetid://89224403789635",
                    BackgroundTransparency = 1,
                    Size = UDim2New(0, 22, 0, 22),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Icon"]:AddToTheme({ImageColor3 = "Accent"})  

                Items["Text"] = Instances:Create("TextLabel", {
                    Parent = Items["KeybindsList"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(255, 255, 255),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "keybinds",
                    Size = UDim2New(0, 0, 0, 15),
                    Position = UDim2New(0, 28, 0, 3),
                    BackgroundTransparency = 1,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.X,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Text"]:AddToTheme({TextColor3 = "Text"})

                Instances:Create("UIPadding", {
                    Parent = Items["KeybindsList"].Instance,
                    Name = "\0",
                    PaddingTop = UDimNew(0, 8),
                    PaddingBottom = UDimNew(0, 8),
                    PaddingRight = UDimNew(0, 8),
                    PaddingLeft = UDimNew(0, 8)
                })

                Items["Content"] = Instances:Create("Frame", {
                    Parent = Items["KeybindsList"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 0, 0, 28),
                    BorderColor3 = FromRGB(0, 0, 0),
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.XY,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Instances:Create("UIListLayout", {
                    Parent = Items["Content"].Instance,
                    Name = "\0",
                    SortOrder = Enum.SortOrder.LayoutOrder
                })
            end

            function KeybindList:Add(Key, Name)
                local NewKey = Instances:Create("TextLabel", {
                    Parent = Items["Content"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(255, 255, 255),
                    TextTransparency = 0.5,
                    Text = "(" .. Key .. ") - ".. Name .. "",
                    Size = UDim2New(1, 0, 0, 20),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BorderColor3 = FromRGB(0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.X,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  NewKey:AddToTheme({TextColor3 = "Text"})

                local NewKeyStatus = Instances:Create("TextLabel", {
                    Parent = NewKey.Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(255, 255, 255),
                    TextTransparency = 0.5,
                    Text = "off",
                    Size = UDim2New(0, 0, 0, 20),
                    AnchorPoint = Vector2New(1, 0),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1,
                    Position = UDim2New(1, 50, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.X,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  NewKeyStatus:AddToTheme({TextColor3 = "Text"})

                Instances:Create("UIPadding", {
                    Parent = NewKey.Instance,
                    Name = "\0",
                    PaddingRight = UDimNew(0, 50)
                })

                function NewKey:SetText(Key, Name)
                    NewKey.Instance.Text =  "(" .. Key .. ") - ".. Name .. ""
                end

                function NewKey:SetStatus(Status)
                    NewKeyStatus.Instance.Text = Status
                end

                function NewKey:Remove()
                    NewKey:Clean()
                end

                function NewKey:SetVisibility(Bool)
                    NewKey.Instance.Visible = Bool
                end

                function NewKey:Set(Bool)
                    if Bool then 
                        NewKey:Tween(nil, {TextTransparency = 0})
                        NewKeyStatus:Tween(nil, {TextTransparency = 0})
                    else 
                        NewKey:Tween(nil, {TextTransparency = 0.5})
                        NewKeyStatus:Tween(nil, {TextTransparency = 0.5})
                    end
                end

                return NewKey
            end

            function KeybindList:SetVisibility(Bool)
                Items["KeybindsList"].Instance.Visible = Bool
            end

            return KeybindList
        end 

        Library.Window = function(self, Data)
            Data = Data or { }

            local Window = {
                Name = Data.Name or Data.name or "kiwisense",
                Logo = Data.Logo or Data.logo or "135215559087473",
                FadeSpeed = Data.FadeSpeed or Data.fadespeed or 0.2,
                Version = Data.Version or Data.version or "v1.0.0 alpha",
                Size = not IsMobile and UDim2New(0, 659, 0, 511) or UDim2New(0, 511, 0, 459),

                Pages = { },
                SubPages = { },

                Items = { },
                IsOpen = false
            }

            local Items = { } do
                Items["MainFrame"] = Instances:Create("Frame", {
                    Parent = Library.Holder.Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(0, 0),
                    Position = UDim2New(0, Camera.ViewportSize.X / 3.5, 0, Camera.ViewportSize.Y / 3.5),
                    Size = Window.Size,
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    Visible = false,
                    BackgroundColor3 = FromRGB(16, 18, 21)
                })  Items["MainFrame"]:AddToTheme({BackgroundColor3 = "Background"})

                Items["MainFrame"]:MakeDraggable()
                Items["MainFrame"]:MakeResizeable(Vector2New(Window.Size.X.Offset, Window.Size.Y.Offset), Vector2New(9999, 9999))

                Instances:Create("UICorner", {
                    Parent = Items["MainFrame"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 5)
                })

                Items["Pages"] = Instances:Create("Frame", {
                    Parent = Items["MainFrame"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(0.5, 0),
                    BorderSizePixel = 0,
                    Position = UDim2New(0.5, 0, 1, 8),
                    Size = UDim2New(0, 0, 0, 45),
                    ZIndex = 2,
                    AutomaticSize = Enum.AutomaticSize.X,
                    BackgroundColor3 = FromRGB(16, 18, 21)
                })  Items["Pages"]:AddToTheme({BackgroundColor3 = "Background"})

                Instances:Create("UICorner", {
                    Parent = Items["Pages"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(1, 0)
                })

                Items["Holder"] = Instances:Create("Frame", {
                    Parent = Items["Pages"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 1,
                    Size = UDim2New(0, 0, 1, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.X,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Instances:Create("UIPadding", {
                    Parent = Items["Holder"].Instance,
                    Name = "\0",
                    PaddingRight = UDimNew(0, 8),
                    PaddingLeft = UDimNew(0, 8)
                })

                Instances:Create("UIListLayout", {
                    Parent = Items["Holder"].Instance,
                    Name = "\0",
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    FillDirection = Enum.FillDirection.Horizontal,
                    Padding = UDimNew(0, 5),
                    SortOrder = Enum.SortOrder.LayoutOrder
                })

                Items["Shadow"] = Instances:Create("ImageLabel", {
                    Parent = Items["MainFrame"].Instance,
                    Name = "\0",
                    ImageColor3 = FromRGB(0, 0, 0),
                    ScaleType = Enum.ScaleType.Slice,
                    ImageTransparency = 0.8999999761581421,
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, 25, 1, 25),
                    AnchorPoint = Vector2New(0.5, 0.5),
                    Image = "http://www.roblox.com/asset/?id=18245826428",
                    BackgroundTransparency = 1,
                    Position = UDim2New(0.5, 0, 0.5, 0),
                    BackgroundColor3 = FromRGB(255, 255, 255),
                    BorderSizePixel = 0,
                    SliceCenter = RectNew(Vector2New(21, 21), Vector2New(79, 79))
                })  Items["Shadow"]:AddToTheme({ImageColor3 = "Shadow"})

                Items["Topbar"] = Instances:Create("Frame", {
                    Parent = Items["MainFrame"].Instance,
                    Name = "\0",
                    Size = UDim2New(1, 0, 0, 35),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(22, 25, 29)
                })  Items["Topbar"]:AddToTheme({BackgroundColor3 = "Inline"})

                Instances:Create("UICorner", {
                    Parent = Items["Topbar"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 5)
                })

                Instances:Create("Frame", {
                    Parent = Items["Topbar"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(0, 1),
                    Position = UDim2New(0, 0, 1, 0),
                    Size = UDim2New(1, 0, 0, 3),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(22, 25, 29)
                }):AddToTheme({BackgroundColor3 = "Inline"})

                Instances:Create("Frame", {
                    Parent = Items["Topbar"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(0, 1),
                    BackgroundTransparency = 0.4,
                    Position = UDim2New(0, 0, 1, 0),
                    Size = UDim2New(1, 0, 0, 1),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(32, 36, 42)
                }):AddToTheme({BackgroundColor3 = "Border"})

                Instances:Create("UIGradient", {
                    Parent = Items["Topbar"].Instance,
                    Name = "\0",
                    Rotation = 84,
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(211, 211, 211))}
                }):AddToTheme({Color = function()
                    return RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, Library.Theme["Dark Gradient"])}
                end})

                --[[Items["Logo"] = Instances:Create("ImageLabel", {
                    Parent = Items["Topbar"].Instance,
                    Name = "\0",
                    ImageColor3 = FromRGB(196, 231, 255),
                    ScaleType = Enum.ScaleType.Fit,
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 22, 0, 22),
                    AnchorPoint = Vector2New(0, 0.5),
                    Image = "rbxassetid://"..Window.Logo,
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 7, 0.5, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Logo"]:AddToTheme({ImageColor3 = "Accent"})]]

                Items["Title"] = Instances:Create("TextLabel", {
                    Parent = Items["Topbar"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    AnchorPoint = Vector2New(0, 0.5),
                    ZIndex = 2,
                    TextSize = 14,
                    Size = UDim2New(0, 0, 0, 15),
                    RichText = true,
                    TextColor3 = FromRGB(255, 255, 255),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = Window.Name,
                    BackgroundTransparency = 1,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Position = UDim2New(0, 10, 0.5, 0),
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.X,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Title"]:AddToTheme({TextColor3 = "Text"})

                Items["Version"] = Instances:Create("Frame", {
                    Parent = Items["Title"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 0, 0, 15),
                    Position = UDim2New(1, 5, 0, 1),
                    BorderSizePixel = 0,
                    ZIndex = 2,
                    AutomaticSize = Enum.AutomaticSize.X,
                    BackgroundColor3 = FromRGB(16, 18, 21)
                })  Items["Version"]:AddToTheme({BackgroundColor3 = "Background"})

                Instances:Create("UIPadding", {
                    Parent = Items["Version"].Instance,
                    Name = "\0",
                    PaddingRight = UDimNew(0, 5),
                    PaddingLeft = UDimNew(0, 6)
                })

                Items["VersionText"] = Instances:Create("TextLabel", {
                    Parent = Items["Version"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(255, 255, 255),
                    TextTransparency = 0.5,
                    Text = Window.Version,
                    AutomaticSize = Enum.AutomaticSize.X,
                    Size = UDim2New(0, 0, 0, 15),
                    Position = UDim2New(0, -2, 0, 0),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    TextSize = 12,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["VersionText"]:AddToTheme({TextColor3 = "Text"})

                Instances:Create("UICorner", {
                    Parent = Items["Version"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 5)
                })

                Instances:Create("UIStroke", {
                    Parent = Items["Version"].Instance,
                    Name = "\0",
                    Color = FromRGB(32, 36, 42),
                    Transparency = 0.4000000059604645,
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                }):AddToTheme({Color = "Border"})

                Instances:Create("UIPadding", {
                    Parent = Items["Title"].Instance,
                    Name = "\0",
                    PaddingRight = UDimNew(0, 0)
                })

                Items["CloseButton"] = Instances:Create("ImageButton", {
                    Parent = Items["Topbar"].Instance,
                    Name = "\0",
                    ScaleType = Enum.ScaleType.Fit,
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 17, 0, 17),
                    AutoButtonColor = false,
                    AnchorPoint = Vector2New(1, 0.5),
                    Image = "rbxassetid://76001605964586",
                    BackgroundTransparency = 1,
                    Position = UDim2New(1, -7, 0.5, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["CloseButton"]:AddToTheme({ImageColor3 = "Image"})

                Items["MinimizeButton"] = Instances:Create("ImageButton", {
                    Parent = Items["Topbar"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 17, 0, 17),
                    AutoButtonColor = false,
                    AnchorPoint = Vector2New(1, 0.5),
                    Image = "rbxassetid://94817928404736",
                    BackgroundTransparency = 1,
                    Position = UDim2New(1, -27, 0.5, -5),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["MinimizeButton"]:AddToTheme({ImageColor3 = "Image"})

                Items["UnMinimizeButton"] = Instances:Create("ImageButton", {
                    Parent = Items["Topbar"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 17, 0, 17),
                    ImageTransparency = 1,
                    AutoButtonColor = false,
                    AnchorPoint = Vector2New(1, 0.5),
                    Image = "rbxassetid://77419631183448",
                    BackgroundTransparency = 1,
                    Position = UDim2New(1, -27, 0.5, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["UnMinimizeButton"]:AddToTheme({ImageColor3 = "Image"})

                Instances:Create("UIStroke", {
                    Parent = Items["MainFrame"].Instance,
                    Name = "\0",
                    Color = FromRGB(32, 36, 42),
                    Transparency = 0.4000000059604645,
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                }):AddToTheme({Color = "Border"})

                Items["Content"] = Instances:Create("Frame", {
                    Parent = Items["MainFrame"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 0, 0, 35),
                    Size = UDim2New(1, 0, 1, -35),
                    ClipsDescendants = true,
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Items["Search"] = Instances:Create("Frame", {
                    Parent = Items["Content"].Instance,
                    Name = "\0",
                    Size = UDim2New(0, 250, 0, 32),
                    Position = UDim2New(0, 8, 0, 8),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(22, 25, 29)
                })  Items["Search"]:AddToTheme({BackgroundColor3 = "Inline"})

                Instances:Create("UIGradient", {
                    Parent = Items["Search"].Instance,
                    Name = "\0",
                    Rotation = 84,
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(211, 211, 211))}
                }):AddToTheme({Color = function()
                    return RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, Library.Theme["Dark Gradient"])}
                end})

                Instances:Create("UICorner", {
                    Parent = Items["Search"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 5)
                })

                Instances:Create("UIStroke", {
                    Parent = Items["Search"].Instance,
                    Name = "\0",
                    Color = FromRGB(32, 36, 42),
                    Transparency = 0.4000000059604645,
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                }):AddToTheme({Color = "Border"})

                Items["SearchIcon"] = Instances:Create("ImageLabel", {
                    Parent = Items["Search"].Instance,
                    Name = "\0",
                    ScaleType = Enum.ScaleType.Fit,
                    ImageTransparency = 0.5,
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 20, 0, 20),
                    AnchorPoint = Vector2New(0, 0.5),
                    Image = "rbxassetid://71924825350727",
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 8, 0.5, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["SearchIcon"]:AddToTheme({ImageColor3 = "Image"})

                Items["Input"] = Instances:Create("TextBox", {
                    Parent = Items["Search"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    AnchorPoint = Vector2New(0, 0.5),
                    PlaceholderColor3 = FromRGB(185, 185, 185),
                    PlaceholderText = "search",
                    TextSize = 14,
                    Size = UDim2New(1, -45, 0, 15),
                    ClipsDescendants = true,
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    ZIndex = 2,
                    Position = UDim2New(0, 35, 0.5, -2),
                    BackgroundTransparency = 1,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextColor3 = FromRGB(255, 255, 255),
                    ClearTextOnFocus = false,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Input"]:AddToTheme({TextColor3 = "Text", PlaceholderColor3 = "Inactive Text"})

                if IsMobile then 
                    Items["FloatingButton"] = Instances:Create("TextButton", {
                        Parent = Library.Holder.Instance,
                        Text = "",
                        AutoButtonColor = false,
                        Name = "\0",
                        Position = UDim2New(0, 125, 0, 125),
                        BorderColor3 = FromRGB(0, 0, 0),
                        Size = UDim2New(0, 50, 0, 50),
                        BorderSizePixel = 0,
                        ZIndex = 127,
                        BackgroundColor3 = Library.Theme.Background
                    })  Items["FloatingButton"]:AddToTheme({BackgroundColor3 = "Background"})

                    Items["FloatingButton"]:MakeDraggable()

                    Instances:Create("ImageLabel", {
                        Parent = Items["FloatingButton"].Instance,
                        BorderColor3 = FromRGB(0, 0, 0),
                        Name = "\0",
                        Image = "rbxassetid://" .. Window.Logo,
                        BackgroundTransparency = 1,
                        AnchorPoint = Vector2New(0.5, 0.5),
                        Position = UDim2New(0.5, 0, 0.5, 0),
                        ZIndex = 127,
                        Size = UDim2New(1, -25, 1, -25),
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })

                    Instances:Create("UICorner", {
                        Parent = Items["FloatingButton"].Instance,
                        CornerRadius = UDimNew(1, 0)
                    }) 

                    Items["FloatingButton"]:Connect("InputBegan", function(Input)
                        if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                            Window:SetOpen(not Window.IsOpen)
                        end
                    end)
                end
            end

            local Debounce = false 
            local OldSizes = { }

            function Window:AddToOldSizes(Item, Size)
                if not OldSizes[Item] then
                    OldSizes[Item] = Size
                end
            end

            function Window:GetOldSize(Item)
                if OldSizes[Item] then
                    return OldSizes[Item]
                end
            end

            Window.SetOpen = LPH_NO_VIRTUALIZE(function(Self, Bool)
                if Debounce then 
                    return 
                end

                Window.IsOpen = Bool

                Debounce = true

                if Bool then 
                    Items["MainFrame"].Instance.Visible = true
                end

                local Descendants = Items["MainFrame"].Instance:GetDescendants()
                TableInsert(Descendants, Items["MainFrame"].Instance)

                local NewTween

                for Index, Value in Descendants do 
                    local TransparencyProperty = Tween:GetProperty(Value)

                    if not TransparencyProperty then 
                        continue
                    end

                    if type(TransparencyProperty) == "table" then 
                        for _, Property in TransparencyProperty do 
                            NewTween = Tween:FadeItem(Value, Property, Bool, Window.FadeSpeed)
                        end
                    else
                        NewTween = Tween:FadeItem(Value, TransparencyProperty, Bool, Window.FadeSpeed)
                    end
                end

                Library:Connect(NewTween.Tween.Completed, function()
                    Debounce = false
                    Items["MainFrame"].Instance.Visible = Bool
                end)
            end)

            function Window:SetText(Text)
                Items["Title"].Instance.Text = Text
            end

            Library:Connect(UserInputService.InputBegan, LPH_NO_VIRTUALIZE(function(Input, GameProcessedEvent)
                if GameProcessedEvent then 
                    return 
                end

                if tostring(Input.KeyCode) == Library.MenuKeybind 
                or tostring(Input.UserInputType) == Library.MenuKeybind then
                    Window:SetOpen(not Window.IsOpen)
                end
            end))

            local RenderStepped

            Items["Input"]:Connect("Focused", LPH_NO_VIRTUALIZE(function()
                local PageSearchData = Library.SearchItems[Library.CurrentPage]

                if not PageSearchData then
                    return 
                end

                RenderStepped = RunService.RenderStepped:Connect(function()
                    for Index, Value in PageSearchData do 
                        local Name = Value.Name
                        local Element = Value.Item

                        if StringFind(StringLower(Name), StringLower(Items["Input"].Instance.Text)) then
                            if Items["Input"].Instance.Text ~= "" then 
                                Element.Instance.Visible  = true 
                                Element:Tween(nil, {Size = Window:GetOldSize(Element)})
                            else
                                Element.Instance.Visible  = true 
                                Element:Tween(nil, {Size = Window:GetOldSize(Element)})
                            end
                        else
                            Window:AddToOldSizes(Element, Element.Instance.Size)
                            Element:Tween(nil, {Size = UDim2New(Window:GetOldSize(Element).X.Scale, Window:GetOldSize(Element).X.Offset, 0, 0)})
                            task.wait(0.1)
                            Element.Instance.Visible = false
                        end
                    end
                end)
            end))

            Items["Input"]:Connect("FocusLost", LPH_NO_VIRTUALIZE(function()
                if RenderStepped then 
                    RenderStepped:Disconnect()
                    RenderStepped = nil
                end
            end))
            
            local IsMinimized = false
            local OldSize = Items["MainFrame"].Instance.AbsoluteSize

            Items["MinimizeButton"]:Connect("MouseButton1Down", LPH_NO_VIRTUALIZE(function()
                IsMinimized = not IsMinimized

                if IsMinimized then
                    OldSize = Items["MainFrame"].Instance.AbsoluteSize
                    Items["MainFrame"]:Tween(nil, {Size = UDim2New(0, Items["MainFrame"].Instance.Size.X.Offset, 0, 35)})
                    Items["MinimizeButton"]:Tween(nil, {ImageTransparency = 1})
                    Items["UnMinimizeButton"]:Tween(nil, {ImageTransparency = 0})
                else
                    Items["MainFrame"]:Tween(nil, {Size = UDim2New(0, Items["MainFrame"].Instance.Size.X.Offset, 0, OldSize.Y)})
                    Items["MinimizeButton"]:Tween(nil, {ImageTransparency = 0})
                    Items["UnMinimizeButton"]:Tween(nil, {ImageTransparency = 1})
                end
            end))

            Items["CloseButton"]:Connect("MouseButton1Down", function()
                Window:SetOpen(false)
                task.wait(0.1)
                Library:Unload()
            end)

            Window.Items = Items

            Window:SetOpen(true)
            return setmetatable(Window, self)
        end

        Library.Page = function(self, Data)
            Data = Data or { }

            local Page = {
                Window = self,

                Name = Data.Name or Data.name or "combat",
                Icon = Data.Icon or Data.icon or "111178525804834",
                Columns = Data.Columns or Data.columns or 2,
                SubPages = Data.SubPages or Data.subpages or false,

                Active = false,

                Items = { },
                ColumnsData =  { },

                SubPagesStack = { }
            }

            if type(Page.Icon) == "string" and not string.find(Page.Icon, not Volcano and ".png" or "rbxasset://") then
                Page.Icon = "rbxassetid://"..Page.Icon
            end

            Library.SearchItems[Page] = { }

            local Items = { } do
                Items["PageContent"] = Instances:Create("Frame", {
                    Parent = Page.Window.Items["Content"].Instance,
                    Name = "\0",
                    Visible = false,
                    BackgroundTransparency = 1,
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, 0, 1, 0),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Items["Columns"] = Instances:Create("Frame", {
                    Parent = Items["PageContent"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 7, 0, 48),
                    Size = UDim2New(1, -14, 1, -55),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Instances:Create("UIListLayout", {
                    Parent = Items["Columns"].Instance,
                    Name = "\0",
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalFlex = Enum.UIFlexAlignment.Fill,
                    Padding = UDimNew(0, 14),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    VerticalFlex = Enum.UIFlexAlignment.Fill
                })

                Items["Inactive"] = Instances:Create("TextButton", {
                    Parent = Page.Window.Items["Holder"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    AutoButtonColor = false,
                    BackgroundTransparency = 1,
                    Size = UDim2New(0, 0, 0, 32),
                    BorderSizePixel = 0,
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(23, 26, 30)
                })  Items["Inactive"]:AddToTheme({BackgroundColor3 = "Inline"})

                Instances:Create("UICorner", {
                    Parent = Items["Inactive"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(1, 0)
                })

                Items["Icon"] = Instances:Create("ImageLabel", {
                    Parent = Items["Inactive"].Instance,
                    Name = "\0",
                    ImageTransparency = 0.5,
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 22, 0, 22),
                    AnchorPoint = Vector2New(0, 0.5),
                    Image = Page.Icon,
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 5, 0.5, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Icon"]:AddToTheme({ImageColor3 = "Image"})

                Items["Text"] = Instances:Create("TextLabel", {
                    Parent = Items["Inactive"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    Visible = false,
                    Active = true,
                    AnchorPoint = Vector2New(0, 0.5),
                    ZIndex = 2,
                    TextSize = 14,
                    Size = UDim2New(0, 0, 0, 15),
                    TextColor3 = FromRGB(255, 255, 255),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = Page.Name,
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 32, 0.5, 0),
                    AutomaticSize = Enum.AutomaticSize.X,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Text"]:AddToTheme({TextColor3 = "Text"})

                Instances:Create("UIPadding", {
                    Parent = Items["Inactive"].Instance,
                    Name = "\0",
                    PaddingRight = UDimNew(0, 7)
                })

                if not Page.SubPages then
                    for Index = 1, Page.Columns do 
                        local NewColumn = Instances:Create("ScrollingFrame", {
                            Parent = Items["Columns"].Instance,
                            Name = "\0",
                            ScrollBarImageColor3 = FromRGB(0, 0, 0),
                            Active = true,
                            AutomaticCanvasSize = Enum.AutomaticSize.Y,
                            ScrollBarThickness = 0,
                            BorderColor3 = FromRGB(0, 0, 0),
                            BackgroundTransparency = 1,
                            Size = UDim2New(0, 100, 0, 100),
                            BackgroundColor3 = FromRGB(255, 255, 255),
                            ZIndex = 2,
                            BorderSizePixel = 0,
                            CanvasSize = UDim2New(0, 0, 0, 0)
                        })

                        Instances:Create("UIPadding", {
                            Parent = NewColumn.Instance,
                            Name = "\0",
                            PaddingBottom = UDimNew(0, 8)
                        })

                        Instances:Create("UIListLayout", {
                            Parent = NewColumn.Instance,
                            Name = "\0",
                            Padding = UDimNew(0, 14),
                            SortOrder = Enum.SortOrder.LayoutOrder
                        })
                        
                        Page.ColumnsData[Index] = NewColumn
                    end
                end

                if Page.SubPages then 
                    Items["Columns"].Instance.Size = UDim2New(1, -14, 1, -108)

                    Items["SubPages"] = Instances:Create("Frame", {
                        Parent = Items["PageContent"].Instance,
                        Name = "\0",
                        BorderColor3 = FromRGB(0, 0, 0),
                        AnchorPoint = Vector2New(0.5, 1),
                        BorderSizePixel = 0,
                        Position = UDim2New(0.5, 0, 1, -8),
                        Size = UDim2New(0, 0, 0, 45),
                        ZIndex = 2,
                        AutomaticSize = Enum.AutomaticSize.X,
                        BackgroundColor3 = FromRGB(22, 25, 29)
                    })  Items["SubPages"]:AddToTheme({BackgroundColor3 = "Inline"})

                    Instances:Create("UICorner", {
                        Parent = Items["SubPages"].Instance,
                        Name = "\0",
                        CornerRadius = UDimNew(1, 0)
                    })

                    Items["Holder"] = Instances:Create("Frame", {
                        Parent = Items["SubPages"].Instance,
                        Name = "\0",
                        BackgroundTransparency = 1,
                        Size = UDim2New(0, 0, 1, 0),
                        BorderColor3 = FromRGB(0, 0, 0),
                        BorderSizePixel = 0,
                        AutomaticSize = Enum.AutomaticSize.X,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })

                    Instances:Create("UIPadding", {
                        Parent = Items["Holder"].Instance,
                        Name = "\0",
                        PaddingRight = UDimNew(0, 8),
                        PaddingLeft = UDimNew(0, 8)
                    })

                    Instances:Create("UIListLayout", {
                        Parent = Items["Holder"].Instance,
                        Name = "\0",
                        VerticalAlignment = Enum.VerticalAlignment.Center,
                        FillDirection = Enum.FillDirection.Horizontal,
                        Padding = UDimNew(0, 5),
                        SortOrder = Enum.SortOrder.LayoutOrder
                    })
                end

                Items["Inactive"].Instance.Size = UDim2New(0, 25, 0, 32)
            end

            local Debounce = false

            Page.Switch = LPH_NO_VIRTUALIZE(function(Self, Bool)
                if Debounce then 
                    return 
                end

                Page.Active = Bool
                Items["PageContent"].Instance.Visible = Bool
                Items["PageContent"].Instance.Parent = Bool and Page.Window.Items["Content"].Instance or Library.UnusedHolder.Instance
                
                Debounce = true 

                if Bool then
                    Items["Text"].Instance.Visible = true 
                    Items["Inactive"]:Tween(nil, {BackgroundTransparency = 0, Size = UDim2New(0, Items["Text"].Instance.TextBounds.X + 38, 0, 32)})
                    Items["Icon"]:ChangeItemTheme({ImageColor3 = "Accent"})
                    Items["Icon"]:Tween(nil, {ImageColor3 = Library.Theme.Accent, ImageTransparency = 0})

                    Library.CurrentPage = Page
                else
                    Items["Text"].Instance.Visible = false 
                    Items["Inactive"]:Tween(nil, {BackgroundTransparency = 1, Size = UDim2New(0, 25, 0, 32)})
                    Items["Icon"]:ChangeItemTheme({ImageColor3 = "Image"})
                    Items["Icon"]:Tween(nil, {ImageColor3 = Library.Theme.Image, ImageTransparency = 0.5}) 
                end

                local Descendants = Items["PageContent"].Instance:GetChildren()
                TableInsert(Descendants, Items["PageContent"].Instance)

                local NewTween

                for Index, Value in Descendants do 
                    local TransparencyProperty = Tween:GetProperty(Value)

                    if not TransparencyProperty then 
                        continue
                    end

                    if type(TransparencyProperty) == "table" then 
                        for _, Property in TransparencyProperty do 
                            NewTween = Tween:FadeItem(Value, Property, Bool, Page.Window.FadeSpeed)
                        end
                    else
                        NewTween = Tween:FadeItem(Value, TransparencyProperty, Bool, Page.Window.FadeSpeed)
                    end
                end

                Library:Connect(NewTween.Tween.Completed, function()
                    Debounce = false
                end)
            end)

            Items["Inactive"]:Connect("MouseButton1Down", LPH_NO_VIRTUALIZE(function()
                for Index, Value in Page.Window.Pages do
                    Value:Switch(Value == Page)
                end
            end))

            if #Page.Window.Pages == 0 then 
                Page:Switch(true)
            end

            Page.Items = Items
            TableInsert(Page.Window.Pages, Page)
            return setmetatable(Page, Library.Pages)
        end

        Library.Pages.SubPage = function(self, Data)
            Data = Data or { }

            local SubPage = {
                Window = self.Window,
                Page = self,

                Name = Data.Name or Data.name or "SubPage",
                Icon = Data.Icon or Data.icon or "9080568477801",
                Columns = Data.Columns or Data.columns or 2,
                
                Items = { },
                ColumnsData = { }
            }

            Library.SearchItems[SubPage] = { }

            if type(SubPage.Icon) == "string" and not string.find(SubPage.Icon, not Volcano and ".png" or "rbxasset://") then
                SubPage.Icon = "rbxassetid://"..SubPage.Icon
            end

            local Items = { } do
                Items["PageContent"] = Instances:Create("Frame", {
                    Parent = SubPage.Page.Items["Columns"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 2,
                    Size = UDim2New(1, 0, 1, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    Visible = false,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Instances:Create("UIListLayout", {
                    Parent = Items["PageContent"].Instance,
                    Name = "\0",
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalFlex = Enum.UIFlexAlignment.Fill,
                    Padding = UDimNew(0, 14),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    VerticalFlex = Enum.UIFlexAlignment.Fill
                })

                Items["Inactive"] = Instances:Create("TextButton", {
                    Parent = SubPage.Page.Items["Holder"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    AutoButtonColor = false,
                    AutomaticSize = Enum.AutomaticSize.X,
                    BackgroundTransparency = 1,
                    Size = UDim2New(0, 0, 0, 32),
                    BorderSizePixel = 0,
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(16, 18, 21)
                })  Items["Inactive"]:AddToTheme({BackgroundColor3 = "Background"})

                Instances:Create("UICorner", {
                    Parent = Items["Inactive"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(1, 0)
                })

                Items["Icon"] = Instances:Create("ImageLabel", {
                    Parent = Items["Inactive"].Instance,
                    Name = "\0",
                    ImageTransparency = 0.5,
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 22, 0, 22),
                    AnchorPoint = Vector2New(0, 0.5),
                    Image = SubPage.Icon,
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 5, 0.5, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Icon"]:AddToTheme({ImageColor3 = "Image"})

                Items["Text"] = Instances:Create("TextLabel", {
                    Parent = Items["Inactive"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    Visible = false,
                    Active = true,
                    AnchorPoint = Vector2New(0, 0.5),
                    ZIndex = 2,
                    TextSize = 14,
                    Size = UDim2New(0, 0, 0, 15),
                    TextColor3 = FromRGB(255, 255, 255),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = SubPage.Name,
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 32, 0.5, 0),
                    AutomaticSize = Enum.AutomaticSize.X,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Text"]:AddToTheme({TextColor3 = "Text"})

                Instances:Create("UIPadding", {
                    Parent = Items["Inactive"].Instance,
                    Name = "\0",
                    PaddingRight = UDimNew(0, 7)
                })

                for Index = 1, SubPage.Columns do 
                    local NewColumn = Instances:Create("ScrollingFrame", {
                        Parent = Items["PageContent"].Instance,
                        Name = "\0",
                        ScrollBarImageColor3 = FromRGB(0, 0, 0),
                        Active = true,
                        AutomaticCanvasSize = Enum.AutomaticSize.Y,
                        ScrollBarThickness = 0,
                        BorderColor3 = FromRGB(0, 0, 0),
                        BackgroundTransparency = 1,
                        Size = UDim2New(0, 100, 0, 100),
                        BackgroundColor3 = FromRGB(255, 255, 255),
                        ZIndex = 2,
                        BorderSizePixel = 0,
                        CanvasSize = UDim2New(0, 0, 0, 0)
                    })

                    Instances:Create("UIPadding", {
                        Parent = NewColumn.Instance,
                        Name = "\0",
                        PaddingBottom = UDimNew(0, 8)
                    })

                    Instances:Create("UIListLayout", {
                        Parent = NewColumn.Instance,
                        Name = "\0",
                        Padding = UDimNew(0, 14),
                        SortOrder = Enum.SortOrder.LayoutOrder
                    })
                    
                    SubPage.ColumnsData[Index] = NewColumn
                end
            end

            local Debounce = false

            SubPage.Switch = LPH_NO_VIRTUALIZE(function(Self, Bool)
                if Debounce then 
                    return 
                end

                SubPage.Active = Bool
                Items["PageContent"].Instance.Visible = Bool
                Items["PageContent"].Instance.Parent = Bool and SubPage.Page.Items["Columns"].Instance or Library.UnusedHolder.Instance
                
                Debounce = true 

                if Bool then
                    Items["Text"].Instance.Visible = true 
                    Items["Inactive"]:Tween(nil, {BackgroundTransparency = 0, Size = UDim2New(0, Items["Text"].Instance.TextBounds.X + 38, 0, 32)})
                    Items["Icon"]:ChangeItemTheme({ImageColor3 = "Accent"})
                    Items["Icon"]:Tween(nil, {ImageColor3 = Library.Theme.Accent, ImageTransparency = 0}) 

                    Library.CurrentPage = SubPage
                else
                    Items["Text"].Instance.Visible = false 
                    Items["Inactive"]:Tween(nil, {BackgroundTransparency = 1, Size = UDim2New(0, 25, 0, 32)})
                    Items["Icon"]:ChangeItemTheme({ImageColor3 = "Image"})
                    Items["Icon"]:Tween(nil, {ImageColor3 = Library.Theme.Image, ImageTransparency = 0.5}) 
                end

                local Descendants = Items["PageContent"].Instance:GetDescendants()
                TableInsert(Descendants, Items["PageContent"].Instance)

                local NewTween

                for Index, Value in Descendants do 
                    local TransparencyProperty = Tween:GetProperty(Value)

                    if not TransparencyProperty then 
                        continue
                    end

                    if type(TransparencyProperty) == "table" then 
                        for _, Property in TransparencyProperty do 
                            NewTween = Tween:FadeItem(Value, Property, Bool, SubPage.Window.FadeSpeed)
                        end
                    else
                        NewTween = Tween:FadeItem(Value, TransparencyProperty, Bool, SubPage.Window.FadeSpeed)
                    end
                end

                Library:Connect(NewTween.Tween.Completed, function()
                    Debounce = false
                end)
            end)

            Items["Inactive"]:Connect("MouseButton1Down", function()
                for Index, Value in SubPage.Page.SubPagesStack do
                    Value:Switch(Value == SubPage)
                end
            end)

            if #SubPage.Page.SubPagesStack == 0 then 
                SubPage:Switch(true)
            end

            SubPage.Items = Items
            TableInsert(SubPage.Page.SubPagesStack, SubPage)
            return setmetatable(SubPage, Library.Pages)
        end

        Library.Pages.Playerlist = function(self, Data)
            local Playerlist = {
                Window = self.Window,
                Page = self,

                CurrentPlayer = nil,

                Players = { }
            }

            local Dropdown

            local Items = { } do
                Playerlist.Page.Items.Columns.Instance:FindFirstChildOfClass("UIListLayout"):Destroy()

                Items["Playerlist"] = Instances:Create("Frame", {
                    Parent = Playerlist.Page.Items["PageContent"].Instance,
                    Name = "\0",
                    Size = UDim2New(1, 0, 1, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(22, 25, 29)
                })  Items["Playerlist"]:AddToTheme({BackgroundColor3 = "Inline"})

                Instances:Create("UICorner", {
                    Parent = Items["Playerlist"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 5)
                })

                Items["PlayerlistInline"] = Instances:Create("Frame", {
                    Parent = Items["Playerlist"].Instance,
                    Name = "\0",
                    Size = UDim2New(1, -16, 1, -90),
                    Position = UDim2New(0, 8, 0, 8),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(16, 18, 21)
                })  Items["PlayerlistInline"]:AddToTheme({BackgroundColor3 = "Background"})

                Instances:Create("UICorner", {
                    Parent = Items["PlayerlistInline"].Instance,
                    Name = "\0",    
                    CornerRadius = UDimNew(0, 5)
                })

                Items["PlayerHolder"] = Instances:Create("ScrollingFrame", {
                    Parent = Items["PlayerlistInline"].Instance,
                    Name = "\0",
                    Active = true,
                    AutomaticCanvasSize = Enum.AutomaticSize.Y,
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    CanvasSize = UDim2New(0, 0, 0, 0),
                    ScrollBarImageColor3 = FromRGB(32, 36, 42),
                    MidImage = "rbxassetid://107505658214891",
                    BorderColor3 = FromRGB(0, 0, 0),
                    ScrollBarThickness = 2,
                    Size = UDim2New(1, -8, 1, 0),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 4, 0, 4),
                    BottomImage = "rbxassetid://107505658214891",
                    TopImage = "rbxassetid://107505658214891",
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["PlayerHolder"]:AddToTheme({ScrollBarImageColor3 = "Border"})

                Instances:Create("UIListLayout", {
                    Parent = Items["PlayerHolder"].Instance,
                    Name = "\0",
                    Padding = UDimNew(0, 4),
                    SortOrder = Enum.SortOrder.LayoutOrder
                })

                Instances:Create("UIPadding", {
                    Parent = Items["PlayerHolder"].Instance,
                    Name = "\0",
                    PaddingTop = UDimNew(0, 4),
                    PaddingBottom = UDimNew(0, 8),
                    PaddingRight = UDimNew(0, 8),
                    PaddingLeft = UDimNew(0, 4)
                })

                Items["PlayerAvatar"] = Instances:Create("ImageLabel", {
                    Parent = Items["Playerlist"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 50, 0, 50),
                    AnchorPoint = Vector2New(0, 1),
                    Image = "rbxasset://textures/ui/GuiImagePlaceholder.png",
                    Position = UDim2New(0, 8, 1, -15),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(16, 18, 21)
                })  Items["PlayerAvatar"]:AddToTheme({BackgroundColor3 = "Background"})

                Instances:Create("UICorner", {
                    Parent = Items["PlayerAvatar"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 5)
                })

                Items["PlayerUsername"] = Instances:Create("TextLabel", {
                    Parent = Items["Playerlist"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(255, 255, 255),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "?",
                    AutomaticSize = Enum.AutomaticSize.X,
                    Size = UDim2New(0, 0, 0, 15),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 65, 1, -65),
                    BorderSizePixel = 0,
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["PlayerUsername"]:AddToTheme({TextColor3 = "Text"})

                Items["PlayerUserID"] = Instances:Create("TextLabel", {
                    Parent = Items["Playerlist"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(255, 255, 255),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "?",
                    AutomaticSize = Enum.AutomaticSize.X,
                    Size = UDim2New(0, 0, 0, 15),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 65, 1, -50),
                    BorderSizePixel = 0,
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["PlayerUserID"]:AddToTheme({TextColor3 = "Text"})

                Items["PlayerAccountAge"] = Instances:Create("TextLabel", {
                    Parent = Items["Playerlist"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(255, 255, 255),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "?",
                    AutomaticSize = Enum.AutomaticSize.X,
                    Size = UDim2New(0, 0, 0, 15),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 65, 1, -35),
                    BorderSizePixel = 0,
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["PlayerAccountAge"]:AddToTheme({TextColor3 = "Text"})
            end

            do
                local DropdownItems = { } do
                    DropdownItems["Dropdown"] = Instances:Create("Frame", {
                        Parent = Items["Playerlist"].Instance,
                        Name = "\0",
                        BackgroundTransparency = 1,
                        AnchorPoint = Vector2New(1, 1),
                        Size = UDim2New(0, 235, 0, 47),
                        Position = UDim2New(1, -8, 1, -20),
                        BorderColor3 = FromRGB(0, 0, 0),
                        ZIndex = 2,
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })

                    DropdownItems["Text"] = Instances:Create("TextLabel", {
                        Parent = DropdownItems["Dropdown"].Instance,
                        Name = "\0",
                        FontFace = Library.Font,
                        TextColor3 = FromRGB(255, 255, 255),
                        BorderColor3 = FromRGB(0, 0, 0),
                        Text = "Status",
                        AutomaticSize = Enum.AutomaticSize.X,
                        BackgroundTransparency = 1,
                        Size = UDim2New(0, 0, 0, 15),
                        BorderSizePixel = 0,
                        ZIndex = 2,
                        TextSize = 14,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })  DropdownItems["Text"]:AddToTheme({TextColor3 = "Text"})

                    DropdownItems["RealDropdown"] = Instances:Create("TextButton", {
                        Parent = DropdownItems["Dropdown"].Instance,
                        Text = "", 
                        AutoButtonColor = false,
                        Name = "\0",
                        BorderColor3 = FromRGB(0, 0, 0),
                        AnchorPoint = Vector2New(0, 1),
                        Position = UDim2New(0, 0, 1, 0),
                        Size = UDim2New(1, 0, 0, 25),
                        ZIndex = 2,
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(34, 39, 45)
                    })  DropdownItems["RealDropdown"]:AddToTheme({BackgroundColor3 = "Element"})

                    Instances:Create("UIGradient", {
                        Parent = DropdownItems["RealDropdown"].Instance,
                        Name = "\0",
                        Rotation = 84,
                        Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(211, 211, 211))}
                    }):AddToTheme({Color = function()
                        return RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, Library.Theme["Dark Gradient"])}
                    end})

                    Instances:Create("UICorner", {
                        Parent = DropdownItems["RealDropdown"].Instance,
                        Name = "\0",
                        CornerRadius = UDimNew(0, 4)
                    })

                    DropdownItems["Value"] = Instances:Create("TextLabel", {
                        Parent = DropdownItems["RealDropdown"].Instance,
                        Name = "\0",
                        FontFace = Library.Font,
                        TextColor3 = FromRGB(255, 255, 255),
                        BorderColor3 = FromRGB(0, 0, 0),
                        Text = "--",
                        AutomaticSize = Enum.AutomaticSize.X,
                        Size = UDim2New(0, 0, 0, 15),
                        AnchorPoint = Vector2New(0, 0.5),
                        Position = UDim2New(0, 8, 0.5, 0),
                        BackgroundTransparency = 1,
                        TextTruncate = Enum.TextTruncate.AtEnd,
                        BorderSizePixel = 0,
                        ZIndex = 2,
                        TextSize = 14,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })  DropdownItems["Value"]:AddToTheme({TextColor3 = "Text"})

                    DropdownItems["OpenIcon"] = Instances:Create("ImageLabel", {
                        Parent = DropdownItems["RealDropdown"].Instance,
                        Name = "\0",
                        ImageColor3 = FromRGB(196, 231, 255),
                        ScaleType = Enum.ScaleType.Fit,
                        BorderColor3 = FromRGB(0, 0, 0),
                        Size = UDim2New(0, 20, 0, 20),
                        AnchorPoint = Vector2New(1, 0.5),
                        Image = "rbxassetid://114252321536924",
                        BackgroundTransparency = 1,
                        Position = UDim2New(1, -3, 0.5, 0),
                        ZIndex = 2,
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })  DropdownItems["OpenIcon"]:AddToTheme({ImageColor3 = "Accent"})

                    DropdownItems["OptionHolder"] = Instances:Create("TextButton", {
                        Parent = Library.Holder.Instance,
                        Name = "\0",
                        FontFace = Library.Font,
                        TextColor3 = FromRGB(0, 0, 0),
                        BorderColor3 = FromRGB(0, 0, 0),
                        Text = "",
                        Visible = false,
                        AutoButtonColor = false,
                        Size = UDim2New(1, 0, 0, 50),
                        AutomaticSize = Enum.AutomaticSize.Y,
                        Position = UDim2New(0, 0, 1, 5),
                        BorderSizePixel = 0,
                        ZIndex = 5,
                        TextSize = 14,
                        BackgroundColor3 = FromRGB(22, 25, 29)
                    })  DropdownItems["OptionHolder"]:AddToTheme({BackgroundColor3 = "Inline"})

                    Instances:Create("UIGradient", {
                        Parent = DropdownItems["OptionHolder"].Instance,
                        Name = "\0",
                        Rotation = 84,
                        Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(211, 211, 211))}
                    }):AddToTheme({Color = function()
                        return RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, Library.Theme["Dark Gradient"])}
                    end})

                    Instances:Create("UIStroke", {
                        Parent = DropdownItems["OptionHolder"].Instance,
                        Name = "\0",
                        Color = FromRGB(32, 36, 42),
                        Transparency = 0.4000000059604645,
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                    }):AddToTheme({Color = "Border"})

                    Instances:Create("UICorner", {
                        Parent = DropdownItems["OptionHolder"].Instance,
                        Name = "\0",
                        CornerRadius = UDimNew(0, 5)
                    })

                    Instances:Create("UIListLayout", {
                        Parent = DropdownItems["OptionHolder"].Instance,
                        Name = "\0",
                        Padding = UDimNew(0, 2),
                        SortOrder = Enum.SortOrder.LayoutOrder
                    })

                    Instances:Create("UIPadding", {
                        Parent = DropdownItems["OptionHolder"].Instance,
                        Name = "\0",
                        PaddingTop = UDimNew(0, 8),
                        PaddingBottom = UDimNew(0, 8),
                        PaddingRight = UDimNew(0, 8),
                        PaddingLeft = UDimNew(0, 8)
                    })

                    DropdownItems["RealDropdown"]:OnHover(function()
                        DropdownItems["RealDropdown"]:Tween(nil, {BackgroundColor3 = Library:GetLighterColor(Library.Theme.Element, 1.45)})
                    end)
        
                    DropdownItems["RealDropdown"]:OnHoverLeave(function()
                        DropdownItems["RealDropdown"]:Tween(nil, {BackgroundColor3 = Library.Theme.Element})
                    end)
                end

                Dropdown = { 
                    IsOpen = false,
                    Value = { },
                    Options = { },
                    Multi = false
                }

                function Dropdown:AddOption(Option)
                    local OptionButton = Instances:Create("TextButton", {
                        Parent = DropdownItems["OptionHolder"].Instance,
                        Name = "\0",
                        FontFace = Library.Font,
                        TextColor3 = FromRGB(0, 0, 0),
                        BorderColor3 = FromRGB(0, 0, 0),
                        Text = "",
                        AutoButtonColor = false,
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
                        Size = UDim2New(1, 0, 0, 25),
                        ZIndex = 5,
                        TextSize = 14,
                        BackgroundColor3 = FromRGB(16, 18, 21)
                    })  OptionButton:AddToTheme({BackgroundColor3 = "Background"})

                    local CheckImage = Instances:Create("ImageLabel", {
                        Parent = OptionButton.Instance,
                        Name = "\0",
                        ImageColor3 = FromRGB(196, 231, 255),
                        ScaleType = Enum.ScaleType.Fit,
                        BorderColor3 = FromRGB(0, 0, 0),
                        Size = UDim2New(0, 18, 0, 18),
                        Visible = true,
                        AnchorPoint = Vector2New(0, 0.5),
                        Image = "rbxassetid://116339777575852",
                        BackgroundTransparency = 1,
                        Position = UDim2New(0, 3, 0.5, 0),
                        ImageTransparency = 1,
                        ZIndex = 5,
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })  CheckImage:AddToTheme({ImageColor3 = "Accent"})

                    Instances:Create("UICorner", {
                        Parent = OptionButton.Instance,
                        Name = "\0",
                        CornerRadius = UDimNew(0, 5)
                    })

                    local OptionText = Instances:Create("TextLabel", {
                        Parent = OptionButton.Instance,
                        Name = "\0",
                        FontFace = Library.Font,
                        TextTransparency = 0.5,
                        AnchorPoint = Vector2New(0, 0.5),
                        ZIndex = 5,
                        TextSize = 14,
                        Size = UDim2New(0, 0, 0, 15),
                        TextColor3 = FromRGB(255, 255, 255),
                        BorderColor3 = FromRGB(0, 0, 0),
                        Text = Option,
                        BackgroundTransparency = 1,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        AutomaticSize = Enum.AutomaticSize.X,
                        Position = UDim2New(0, 7, 0.5, 0),
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })  OptionText:AddToTheme({TextColor3 = "Text"})

                    local OptionData = {
                        Selected = false,
                        Name = Option,
                        Text = OptionText,
                        Button = OptionButton,
                        Check = CheckImage
                    }

                    function OptionData:Toggle(Status)
                        if Status == "Active" then 
                            OptionData.Button:Tween(nil, {BackgroundTransparency = 0})
                            OptionData.Text:Tween(nil, {TextTransparency = 0, Position = UDim2New(0, 27, 0.5, 0)})
                            OptionData.Check:Tween(nil, {ImageTransparency = 0})
                        elseif Status == "Inactive" then
                            OptionData.Button:Tween(nil, {BackgroundTransparency = 1})
                            OptionData.Text:Tween(nil, {TextTransparency = 0.5, Position = UDim2New(0, 7, 0.5, 0)})
                            OptionData.Check:Tween(nil, {ImageTransparency = 1})
                        end
                    end

                    function OptionData:Set()
                        OptionData.Selected = not OptionData.Selected

                        if Dropdown.Multi then 
                            local Index = TableFind(Dropdown.Value, OptionData.Name)

                            if Index then 
                                TableRemove(Dropdown.Value, Index)
                            else
                                TableInsert(Dropdown.Value, OptionData.Name)
                            end

                            OptionData:Toggle(Index and "Inactive" or "Active")

                            local TextFormat = #Dropdown.Value > 0 and TableConcat(Dropdown.Value, ", ") or "--"

                            DropdownItems["Value"].Instance.Text = TextFormat
                        else
                            if OptionData.Selected then 
                                Dropdown.Value = OptionData.Name

                                OptionData:Toggle("Active")

                                for Index, Value in Dropdown.Options do 
                                    if Value ~= OptionData then
                                        Value.Selected = false 
                                        Value:Toggle("Inactive")
                                    end
                                end

                                DropdownItems["Value"].Instance.Text = OptionData.Name 
                            else
                                Dropdown.Value = nil

                                OptionData:Toggle("Inactive")
                                DropdownItems["Value"].Instance.Text = "--"
                            end
                        end

                        if Dropdown.Callback then 
                            Library:SafeCall(Dropdown.Callback, Dropdown.Value)
                        end
                    end

                    OptionData.Button:Connect("MouseButton1Down", function()
                        OptionData:Set()
                    end)

                    Dropdown.Options[Option] = OptionData
                    return OptionData
                end

                local Debounce = false 
                local RenderStepped

                function Dropdown:SetOpen(Bool)
                    if Debounce then 
                        return 
                    end

                    Dropdown.IsOpen = Bool

                    Debounce = true

                    if Bool then 
                        DropdownItems["OptionHolder"].Instance.Visible = true

                        RenderStepped = RunService.RenderStepped:Connect(function()
                            DropdownItems["OptionHolder"].Instance.Position = UDim2New(0, DropdownItems["RealDropdown"].Instance.AbsolutePosition.X, 0,  DropdownItems["RealDropdown"].Instance.AbsolutePosition.Y + DropdownItems["RealDropdown"].Instance.AbsoluteSize.Y + 5)
                            DropdownItems["OptionHolder"].Instance.Size = UDim2New(0, DropdownItems["RealDropdown"].Instance.AbsoluteSize.X, 0, 85)
                        end)
                    else
                        if RenderStepped then
                            RenderStepped:Disconnect()
                            RenderStepped = nil
                        end
                    end

                    local Descendants = DropdownItems["OptionHolder"].Instance:GetDescendants()
                    TableInsert(Descendants, DropdownItems["OptionHolder"].Instance)

                    local NewTween

                    for Index, Value in Descendants do 
                        local TransparencyProperty = Tween:GetProperty(Value)

                        if not TransparencyProperty then 
                            continue
                        end

                        if StringFind(Value.ClassName, "UI") then
                            continue
                        end

                        Value.ZIndex = Bool and 10 or 0

                        if type(TransparencyProperty) == "table" then 
                            for _, Property in TransparencyProperty do 
                                NewTween = Tween:FadeItem(Value, Property, Bool, Playerlist.Window.FadeSpeed)
                            end
                        else
                            NewTween = Tween:FadeItem(Value, TransparencyProperty, Bool, Playerlist.Window.FadeSpeed)
                        end
                    end

                    Library:Connect(NewTween.Tween.Completed, function()
                        Debounce = false
                        DropdownItems["OptionHolder"].Instance.Visible = Bool
                    end)
                end

                function Dropdown:Set(Option)
                    if Dropdown.Multi then
                        if type(Option) ~= "table" then
                            return
                        end

                        Dropdown.Value = Option
                        Library.Flags[Dropdown.Flag] = Option

                        for Index, Value in Option do 
                            local OptionData = Dropdown.Options[Value]
                                
                            if not OptionData then 
                                return
                            end

                            OptionData.Selected = true
                            OptionData:Toggle("Active")
                        end

                        DropdownItems["Value"].Instance.Text = TableConcat(Option, ", ")
                    else
                        if not Dropdown.Options[Option] then 
                            return
                        end

                        local OptionData = Dropdown.Options[Option]

                        Dropdown.Value = OptionData.Name
                        Library.Flags[Dropdown.Flag] = OptionData.Name

                        for Index, Value in Dropdown.Options do 
                            if Value ~= OptionData then
                                Value.Selected = false 
                                Value:Toggle("Inactive")
                            else
                                Value.Selected = true 
                                Value:Toggle("Active")
                            end
                        end

                        DropdownItems["Value"].Instance.Text = OptionData.Name
                    end

                    if Dropdown.Callback then 
                        Library:SafeCall(Dropdown.Callback, Dropdown.Value)
                    end
                end

                DropdownItems["RealDropdown"]:Connect("MouseButton1Down", function()
                    Dropdown:SetOpen(not Dropdown.IsOpen)
                end)

                Dropdown:AddOption("Neutral")
                Dropdown:AddOption("Priority")
                Dropdown:AddOption("Friendly")
            end

            function Playerlist:Add(Player)
                local PlayerItems = { }

                PlayerItems["NewPlayer"] = Instances:Create("TextButton", {
                    Parent = Items["PlayerHolder"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    AutoButtonColor = false,
                    BackgroundTransparency = 1,
                    ZIndex = 2,
                    Size = UDim2New(1, 0, 0, 25),
                    BorderSizePixel = 0,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(22, 25, 24)
                })  PlayerItems["NewPlayer"]:AddToTheme({BackgroundColor3 = "Inline"})

                Instances:Create("UICorner", {
                    Parent = PlayerItems["NewPlayer"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 6)
                })

                PlayerItems["Name"] = Instances:Create("TextLabel", {
                    Parent = PlayerItems["NewPlayer"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(255, 255, 255),
                    TextTransparency = 0.4000000059604645,
                                        ZIndex = 2,
                    Text = Player.Name,
                    Size = UDim2New(0.3499999940395355, 0, 0, 15),
                    Position = UDim2New(0, 10, 0.5, 0),
                    AnchorPoint = Vector2New(0, 0.5),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BorderColor3 = FromRGB(0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.X,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                PlayerItems["Status"] = Instances:Create("TextLabel", {
                    Parent = PlayerItems["NewPlayer"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(255, 255, 255),
                                        ZIndex = 2,
                    TextTransparency = 0.4000000059604645,
                    Text = "Neutral",
                    Size = UDim2New(0.3499999940395355, 0, 0, 15),
                    Position = UDim2New(0.699999988079071, 10, 0.5, 0),
                    AnchorPoint = Vector2New(0, 0.5),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BorderColor3 = FromRGB(0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.X,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                local Team = Player.Team ~= nil and Player.Team.Name or "None"
                local TeamColor = Player.TeamColor ~= nil and Player.TeamColor.Color or Color3.new(1, 1, 1)

                PlayerItems["Team"] = Instances:Create("TextLabel", {
                    Parent = PlayerItems["NewPlayer"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = TeamColor,
                    TextTransparency = 0.4000000059604645,
                    Text = Team,
                    Size = UDim2New(0.3499999940395355, 0, 0, 15),
                    Position = UDim2New(0.3499999940395355, 10, 0.5, 0),
                                        ZIndex = 2,
                    AnchorPoint = Vector2New(0, 0.5),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BorderColor3 = FromRGB(0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.X,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                if Player == LocalPlayer then
                    PlayerItems["Status"].Instance.TextColor3 = Library.Theme.Accent
                    PlayerItems["Status"].Instance.Text = "LocalPlayer"
                    PlayerItems["Status"]:AddToTheme({TextColor3 = "Accent"})
                end

                local PlayerData = {
                    Name = Player.Name,
                    Selected = false,
                    PlayerButton = PlayerItems["NewPlayer"],
                    PlayerName = PlayerItems["Name"],
                    PlayerTeam = PlayerItems["Team"],
                    PlayerStatus = PlayerItems["Status"],
                    Player = Player
                }

                function PlayerData:Toggle(Status)
                    if Status == "Active" then
                        PlayerItems["Name"]:Tween(nil, {TextTransparency = 0})
                        PlayerItems["Status"]:Tween(nil, {TextTransparency = 0})
                        PlayerItems["Team"]:Tween(nil, {TextTransparency = 0})
                        PlayerItems["NewPlayer"]:Tween(nil, {BackgroundTransparency = 0})
                    else
                        PlayerItems["Name"]:Tween(nil, {TextTransparency = 0.4})
                        PlayerItems["Status"]:Tween(nil, {TextTransparency = 0.4})
                        PlayerItems["Team"]:Tween(nil, {TextTransparency = 0.4})
                        PlayerItems["NewPlayer"]:Tween(nil, {BackgroundTransparency = 1})
                    end
                end

                function PlayerData:Set()
                    PlayerData.Selected = not PlayerData.Selected

                    if PlayerData.Selected then
                        Playerlist.Player = PlayerData.Player

                        for Index, Value in Playerlist.Players do 
                            Value.Selected = false
                            Value:Toggle("Inactive")
                        end

                        PlayerData:Toggle("Active")

                        local PlayerAvatar = Players:GetUserThumbnailAsync(Playerlist.Player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
                        Items["PlayerAvatar"].Instance.Image = PlayerAvatar
                        Items["PlayerUsername"].Instance.Text = Playerlist.Player.DisplayName .. " (@" .. Playerlist.Player.Name .. ")"
                        Items["PlayerUserID"].Instance.Text = tostring(Playerlist.Player.UserId)
                        Items["PlayerAccountAge"].Instance.Text = tostring(Playerlist.Player.AccountAge) .. " days old"
                    else
                        --print("this shit rigged")
                        Playerlist.Player = nil
                        PlayerData:Toggle("Inactive")
                        Items["PlayerAvatar"].Instance.Image = "rbxassetid://98200387761744"
                        Items["PlayerUsername"].Instance.Text = "None"
                        Items["PlayerUserID"].Instance.Text = "None"
                        Items["PlayerAccountAge"].Instance.Text = "None"
                    end

                    if Data.Callback then 
                        Library:SafeCall(Data.Callback, Playerlist.Player, PlayerData.PlayerStatus.Instance.Text, PlayerData.PlayerTeam.Instance.Text)
                    end
                end

                PlayerItems["NewPlayer"]:Connect("MouseButton1Down", function()
                    PlayerData:Set()
                end)

                PlayerItems["NewPlayer"]:OnHover(function()
                end)

                Playerlist.Players[Player.Name] = PlayerData
                return PlayerData
            end

            function Playerlist:Remove(Name)
                if Playerlist.Players[Name] then
                    Playerlist.Players[Name].PlayerButton:Clean()
                end
                
                Playerlist.Players[Name] = nil
            end

            Dropdown.Callback = function(Value) -- horrible code ik
                if Playerlist.Player then
                    if Playerlist.Player == LocalPlayer then
                        return
                    end

                    if Value == "Neutral" then
                        Playerlist.Players[Playerlist.Player.Name].PlayerStatus:Tween(nil, {
                            TextColor3 = Library.Theme["Inactive Text"]
                        })

                        Playerlist.Players[Playerlist.Player.Name].PlayerStatus.Instance.Text = "Neutral"
                        if table.find(Library.Friendly_Players, Playerlist.Player.Name) then
                            table.remove(Library.Friendly_Players, table.find(Library.Friendly_Players, Playerlist.Player.Name))
                        end
                    elseif Value == "Priority" then
                        Playerlist.Players[Playerlist.Player.Name].PlayerStatus:Tween(nil, {
                            TextColor3 = FromRGB(255, 50, 50)
                        })

                        Playerlist.Players[Playerlist.Player.Name].PlayerStatus.Instance.Text = "Priority"
                        if table.find(Library.Friendly_Players, Playerlist.Player.Name) then
                            table.remove(Library.Friendly_Players, table.find(Library.Friendly_Players, Playerlist.Player.Name))
                        end
                    elseif Value == "Friendly" then
                        Playerlist.Players[Playerlist.Player.Name].PlayerStatus:Tween(nil, {
                            TextColor3 = FromRGB(83, 255, 83)
                        })

                        Playerlist.Players[Playerlist.Player.Name].PlayerStatus.Instance.Text = "Friendly"
                        if not table.find(Library.Friendly_Players, Playerlist.Player.Name) then
                            table.insert(Library.Friendly_Players, Playerlist.Player.Name)
                        end
                    else
                        Playerlist.Players[Playerlist.Player.Name].PlayerStatus:Tween(nil, {
                            TextColor3 = Library.Theme["Inactive Text"]
                        })

                        Playerlist.Players[Playerlist.Player.Name].PlayerStatus.Instance.Text = "Neutral"
                        if table.find(Library.Friendly_Players, Playerlist.Player.Name) then
                            table.remove(Library.Friendly_Players, table.find(Library.Friendly_Players, Playerlist.Player.Name))
                        end
                    end
                end
            end

            for Index, Value in Players:GetPlayers() do 
                Playerlist:Add(Value)
            end

            Library:Connect(Players.PlayerRemoving, function(Player)
                if Playerlist.Players[Player.Name] then 
                    Playerlist:Remove(Player.Name)
                end
            end)

            Library:Connect(Players.PlayerAdded, function(Player)
                Playerlist:Add(Player)
            end)

            return Playerlist
        end

        Library.Pages.Section = function(self, Data)
            Data = Data or { }

            local Section = {
                Window = self.Window,
                Page = self,

                Name = Data.Name or Data.name or "Section",
                Side = Data.Side or Data.side or 1,
                Icon = Data.Icon or Data.icon or "9080568477801",

                Items = { }
            }

            if type(Section.Icon) == "string" and not string.find(Section.Icon, not Volcano and ".png" or "rbxasset://") then
                Section.Icon = "rbxassetid://"..Section.Icon
            end

            local Items = { } do
                Items["Section"] = Instances:Create("Frame", {
                    Parent = Section.Page.ColumnsData[Section.Side].Instance,
                    Name = "\0",
                    BorderSizePixel = 0,
                    Size = UDim2New(1, 0, 0, 55),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundColor3 = FromRGB(22, 25, 29)
                })  Items["Section"]:AddToTheme({BackgroundColor3 = "Inline"})

                Instances:Create("UICorner", {
                    Parent = Items["Section"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 5)
                })

                Items["Topbar"] = Instances:Create("Frame", {
                    Parent = Items["Section"].Instance,
                    Name = "\0",
                    Size = UDim2New(1, 0, 0, 35),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(22, 25, 29)
                })  Items["Topbar"]:AddToTheme({BackgroundColor3 = "Inline"})

                Instances:Create("UICorner", {
                    Parent = Items["Topbar"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 5)
                })

                Instances:Create("UIGradient", {
                    Parent = Items["Topbar"].Instance,
                    Name = "\0",
                    Rotation = 84,
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(211, 211, 211))}
                }):AddToTheme({Color = function()
                    return RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, Library.Theme["Dark Gradient"])}
                end})

                Instances:Create("Frame", {
                    Parent = Items["Topbar"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(0, 1),
                    Position = UDim2New(0, 0, 1, 0),
                    Size = UDim2New(1, 0, 0, 3),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(22, 25, 29)
                }):AddToTheme({BackgroundColor3 = "Inline"})

                Items["Title"] = Instances:Create("TextLabel", {
                    Parent = Items["Topbar"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(255, 255, 255),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = Section.Name,
                    BorderSizePixel = 0,
                    AnchorPoint = Vector2New(0, 0.5),
                    Size = UDim2New(1, -125, 0, 15),
                    BackgroundTransparency = 1,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Position = UDim2New(0, 8, 0.5, 0),
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Title"]:AddToTheme({TextColor3 = "Text"})

                Items["Icon"] = Instances:Create("ImageLabel", {
                    Parent = Items["Topbar"].Instance,
                    Name = "\0",
                    ImageColor3 = FromRGB(196, 231, 255),
                    ScaleType = Enum.ScaleType.Fit,
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 18, 0, 18),
                    AnchorPoint = Vector2New(1, 0.5),
                    Image = Section.Icon,
                    BackgroundTransparency = 1,
                    Position = UDim2New(1, -7, 0.5, -1),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Icon"]:AddToTheme({ImageColor3 = "Accent"})

                Instances:Create("Frame", {
                    Parent = Items["Topbar"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(0, 1),
                    BackgroundTransparency = 0.4000000059604645,
                    Position = UDim2New(0, 0, 1, 0),
                    Size = UDim2New(1, 0, 0, 1),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(32, 36, 42)
                }):AddToTheme({BackgroundColor3 = "Border"})

                Instances:Create("UIPadding", {
                    Parent = Items["Section"].Instance,
                    Name = "\0",
                    PaddingBottom = UDimNew(0, 8)
                })

                Items["Content"] = Instances:Create("Frame", {
                    Parent = Items["Section"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 8, 0, 45),
                    Size = UDim2New(1, -16, 0, 0),
                    ZIndex = 2,
                    AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Instances:Create("UIListLayout", {
                    Parent = Items["Content"].Instance,
                    Name = "\0",
                    Padding = UDimNew(0, 8),
                    SortOrder = Enum.SortOrder.LayoutOrder
                })
            end

            Section.Items = Items
            return setmetatable(Section, Library.Sections)
        end

        Library.Sections.Toggle = function(self, Data)
            Data = Data or { }

            local Toggle = {
                Window = self.Window,
                Page = self.Page,
                Section = self,
                
                Name = Data.Name or Data.name or "Toggle",
                Flag = Data.Flag or Data.flag or Library:NextFlag(),
                Default = Data.Default or Data.default or false,
                Callback = Data.Callback or Data.callback or function() end,
                Color = Data.Color or nil,
                Tooltip = Data.Tooltip or Data.tooltip or nil,

                Count = 0
            }

            local NewToggle, ToggleItems = Components.Toggle({
                Name = Toggle.Name,
                Parent = Toggle.Section.Items["Content"],
                Flag = Toggle.Flag,
                Default = Toggle.Default,
                Page = Toggle.Page,
                Callback = Toggle.Callback,
                Color = Toggle.Color,
                Tooltip = Toggle.Tooltip,

            })

            ToggleItems["Toggle"]:Tooltip(Toggle.Tooltip)

            function Toggle:Set(Bool)
                NewToggle:Set(Bool)
            end

            function Toggle:Get()
                return NewToggle:Get()
            end

            function Toggle:SetVisibility(Bool)
                NewToggle:SetVisibility(Bool)
            end

            function Toggle:Colorpicker(Data)
                local Colorpicker = {
                    Window = self.Window,
                    Page = self.Page,
                    Section = self,

                    Name = Data.Name or Data.name,
                    Default = Data.Default or Data.default,
                    Alpha = Data.Alpha or Data.alpha or 0,
                    Flag = Data.Flag or Data.flag or Library:NextFlag(),
                    Callback = Data.Callback or Data.callback or function() end,
                    
                    Count = Toggle.Count
                }
                
                Toggle.Count += 1
                Colorpicker.Count = Toggle.Count

                local NewColorpicker, ColorpickerItems = Components.Colorpicker({
                    Window = Colorpicker.Window,
                    Page = Colorpicker.Page,
                    Parent = ToggleItems["SubElements"],
                    Name = Colorpicker.Name,
                    Flag = Colorpicker.Flag,
                    IsToggle = true,
                    Default = Colorpicker.Default,
                    Alpha = Colorpicker.Alpha,
                    Callback = Colorpicker.Callback,
                    Count = Colorpicker.Count
                })

                return NewColorpicker
            end

            function Toggle:Keybind(Data)
                Data = Data or { }

                local Keybind = {
                    Window = self.Window,
                    Page = self.Page,
                    Section = self,

                    Name = Data.Name or Data.name or "Keybind",
                    Flag = Data.Flag or Data.flag or Library:NextFlag(),
                    Default = Data.Default or Data.default or Enum.KeyCode.RightShift,
                    Callback = Data.Callback or Data.callback or function() end,
                    Mode = Data.Mode or Data.mode or "Toggle",
                    NoKeyBindList = Data.NoKeyBindList or false;
                }

                local NewKeybind, KeybindItems = Components.Keybind({
                    Name = Keybind.Name,
                    Parent = ToggleItems["Toggle"],
                    Window = Toggle.Window,
                    Flag = Keybind.Flag,
                    Default = Keybind.Default,
                    IsToggle = true,
                    Mode = Keybind.Mode,
                    Callback = Keybind.Callback,
                    NoKeyBindList = Keybind.NoKeyBindList
                })

                return NewKeybind
            end

            return Toggle
        end

        Library.Sections.Button = function(self, Data)
            Data = Data or { }

            local Button = {
                Window = self.Window,
                Page = self.Page,
                Section = self,

                Name = Data.Name or Data.name or "Button",
                Callback = Data.Callback or Data.callback or function() end,
                Tooltip = Data.Tooltip or Data.tooltip or nil
            }

            local Items = { } do
                Items["Button"] = Instances:Create("TextButton", {
                    Parent = Button.Section.Items["Content"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    AutoButtonColor = false,
                    BorderSizePixel = 0,
                    Size = UDim2New(1, 0, 0, 30),
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(34, 39, 45)
                })  Items["Button"]:AddToTheme({BackgroundColor3 = "Element"})

                Items["Button"]:Tooltip(Button.Tooltip)

                Items["Button"]:OnHover(function()
                    Items["Button"]:Tween(nil, {BackgroundColor3 = Library:GetLighterColor(Library.Theme.Element, 1.45)})
                end)
    
                Items["Button"]:OnHoverLeave(function()
                    Items["Button"]:Tween(nil, {BackgroundColor3 = Library.Theme.Element})
                end)    

                Instances:Create("UICorner", {
                    Parent = Items["Button"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })

                Instances:Create("UIGradient", {
                    Parent = Items["Button"].Instance,
                    Name = "\0",
                    Rotation = 84,
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(211, 211, 211))}
                }):AddToTheme({Color = function()
                    return RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, Library.Theme["Dark Gradient"])}
                end})

                Items["Text"] = Instances:Create("TextLabel", {
                    Parent = Items["Button"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(255, 255, 255),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = Button.Name,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Size = UDim2New(1, 0, 1, 0),
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Text"]:AddToTheme({TextColor3 = "Text"})
            end

            function Button:Press()
                Items["Button"]:ChangeItemTheme({BackgroundColor3 = "Accent"})
                Items["Button"]:Tween(nil, {BackgroundColor3 = Library.Theme.Accent})

                task.wait(0.1)
                Library:SafeCall(Button.Callback)

                Items["Button"]:ChangeItemTheme({BackgroundColor3 = "Element"})
                Items["Button"]:Tween(nil, {BackgroundColor3 = Library.Theme.Element})
            end

            function Button:SetVisibility(Bool)
                Items["Button"].Instance.Visible = Bool
            end

            function Button:SetText(Text)
                Items["Text"].Instance.Text = Text
            end

            local SearchData = {
                Name = Button.Name,
                Item = Items["Button"]
            }

            local PageSearchData = Library.SearchItems[Button.Page]

            if not PageSearchData then
                return
            end

            TableInsert(PageSearchData, SearchData)

            Items["Button"]:Connect("MouseButton1Down", function()
                Button:Press()
            end)

            return Button
        end

        Library.Sections.Slider = function(self, Data)
            local Slider = { 
                Window = self.Window,
                Page = self.Page,
                Section = self,

                Name = Data.Name or Data.name or "Slider",
                Min = Data.Min or Data.min or 0,
                Max = Data.Max or Data.max or 100,
                Suffix = Data.Suffix or Data.suffix or "",
                Flag = Data.Flag or Data.flag or Library:NextFlag(),
                Default = Data.Default or Data.default or 0,
                Decimals = Data.Decimals or Data.decimals or 1,
                Tooltip = Data.Tooltip or Data.tooltip or nil,
                Callback = Data.Callback or Data.callback or function() end,

                Sliding = false,
                Value = 0
            }

            local Items = { } do
                Items["Slider"] = Instances:Create("Frame", {
                    Parent = Slider.Section.Items["Content"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 1,
                    Size = UDim2New(1, 0, 0, 38),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Items["Slider"]:Tooltip(Slider.Tooltip)

                Items["Text"] = Instances:Create("TextLabel", {
                    Parent = Items["Slider"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(255, 255, 255),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = Slider.Name,
                    AutomaticSize = Enum.AutomaticSize.X,
                    BackgroundTransparency = 1,
                    Size = UDim2New(0, 0, 0, 15),
                    BorderSizePixel = 0,
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Text"]:AddToTheme({TextColor3 = "Text"})

                Items["RealSlider"] = Instances:Create("TextButton", {
                    Parent = Items["Slider"].Instance,
                    AutoButtonColor = false,
                    Text = "",
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(0, 1),
                    Position = UDim2New(0, 0, 1, 0),
                    Size = UDim2New(1, 0, 0, 15),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(34, 39, 45)
                })  Items["RealSlider"]:AddToTheme({BackgroundColor3 = "Element"})

                Items["RealSlider"]:OnHover(function()
                    Items["RealSlider"]:Tween(nil, {BackgroundColor3 = Library:GetLighterColor(Library.Theme.Element, 1.45)})
                end)
    
                Items["RealSlider"]:OnHoverLeave(function()
                    Items["RealSlider"]:Tween(nil, {BackgroundColor3 = Library.Theme.Element})
                end)   

                Instances:Create("UICorner", {
                    Parent = Items["RealSlider"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })

                Instances:Create("UIGradient", {
                    Parent = Items["RealSlider"].Instance,
                    Name = "\0",
                    Rotation = 84,
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(211, 211, 211))}
                }):AddToTheme({Color = function()
                    return RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, Library.Theme["Dark Gradient"])}
                end})

                Items["Accent"] = Instances:Create("Frame", {
                    Parent = Items["RealSlider"].Instance,
                    Name = "\0",
                    Size = UDim2New(0.5, 0, 1, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(196, 231, 255)
                })  Items["Accent"]:AddToTheme({BackgroundColor3 = "Accent"})

                Instances:Create("UICorner", {
                    Parent = Items["Accent"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })

                Instances:Create("UIGradient", {
                    Parent = Items["Accent"].Instance,
                    Name = "\0",
                    Rotation = 84,
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(211, 211, 211))}
                }):AddToTheme({Color = function()
                    return RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, Library.Theme["Dark Gradient"])}
                end})

                Items["Value"] = Instances:Create("TextLabel", {
                    Parent = Items["Slider"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(255, 255, 255),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    AutomaticSize = Enum.AutomaticSize.X,
                    AnchorPoint = Vector2New(1, 0),
                    Size = UDim2New(0, 0, 0, 15),
                    BackgroundTransparency = 1,
                    Position = UDim2New(1, 0, 0, 0),
                    BorderSizePixel = 0,
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Value"]:AddToTheme({TextColor3 = "Text"})
            end

            function Slider:Get()
                return Slider.Value
            end

            function Slider:ChangeText(Text)
                Items["Text"].Instance.Text = tostring(Text)
            end

            function Slider:Set(Value)
                Slider.Value = Library:Round(MathClamp(Value, Slider.Min, Slider.Max), Slider.Decimals)

                Library.Flags[Slider.Flag] = Slider.Value

                Items["Accent"]:Tween(TweenInfo.new(0.21, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2New((Slider.Value - Slider.Min) / (Slider.Max - Slider.Min), 0, 1, 0)})
                Items["Value"].Instance.Text = StringFormat("%s%s", tostring(Slider.Value), Slider.Suffix)

                if Slider.Callback then 
                    Library:SafeCall(Slider.Callback, Slider.Value)
                end
            end

            function Slider:SetVisibility(Bool)
                Items["Slider"].Instance.Visible = Bool
            end

            getgenv().Options[Slider.Flag] = Slider

            local SearchData = {
                Name = Slider.Name,
                Item = Items["Slider"]
            }

            local PageSearchData = Library.SearchItems[Slider.Page]

            if not PageSearchData then 
                return 
            end

            TableInsert(PageSearchData, SearchData)

            local InputChanged

            Items["RealSlider"]:Connect("InputBegan", function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                    Slider.Sliding = true 

                    local SizeX = (Input.Position.X - Items["RealSlider"].Instance.AbsolutePosition.X) / Items["RealSlider"].Instance.AbsoluteSize.X
                    local Value = ((Slider.Max - Slider.Min) * SizeX) + Slider.Min

                    Slider:Set(Value)

                    if InputChanged then
                        return
                    end

                    InputChanged = Input.Changed:Connect(function()
                        if Input.UserInputState == Enum.UserInputState.End then
                            Slider.Sliding = false

                            InputChanged:Disconnect()
                            InputChanged = nil
                        end
                    end)
                end
            end)

            Library:Connect(UserInputService.InputChanged, function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then
                    if Slider.Sliding then
                        local SizeX = (Input.Position.X - Items["RealSlider"].Instance.AbsolutePosition.X) / Items["RealSlider"].Instance.AbsoluteSize.X
                        local Value = ((Slider.Max - Slider.Min) * SizeX) + Slider.Min

                        Slider:Set(Value)
                    end
                end
            end)

            if Slider.Default then 
                Slider:Set(Slider.Default)
            end

            Library.SetFlags[Slider.Flag] = function(Value)
                Slider:Set(Value)
            end

            return Slider
        end

        Library.Sections.Dropdown = function(self, Data)
            Data = Data or { }

            local Dropdown = {
                Window = self.Window,
                Page = self.Page,
                Section = self,

                Name = Data.Name or Data.name or "Dropdown",
                Flag = Data.Flag or Data.flag or Library:NextFlag(),
                Default = Data.Default or Data.default or nil,
                Items = Data.Items or Data.items or { "One", "Two", "Three" },
                Callback = Data.Callback or Data.callback or function() end,
                Multi = Data.Multi or Data.multi or false,
                MaxSize = Data.MaxSize or Data.maxsize or 85,
                Tooltip = Data.Tooltip or Data.tooltip or nil
            }

            local NewDropdown, DropdownItems = Components.Dropdown({
                Window = Dropdown.Window,
                Page = Dropdown.Page,
                Parent = Dropdown.Section.Items["Content"],
                Callback = Dropdown.Callback,
                Name = Dropdown.Name,
                Flag = Dropdown.Flag,
                Items = Dropdown.Items,
                Default = Dropdown.Default,
                Multi = Dropdown.Multi,
                MaxSize = Dropdown.MaxSize or 65
            })  

            DropdownItems["Dropdown"]:Tooltip(Dropdown.Tooltip)

            function Dropdown:Set(Value)
                NewDropdown:Set(Value)
            end

            function Dropdown:Get()
                return NewDropdown:Get()
            end

            function Dropdown:AddOption(Option)
                return NewDropdown:AddOption(Option)
            end

            function Dropdown:RemoveOption(Option)
                return NewDropdown:RemoveOption(Option)
            end

            function Dropdown:Refresh(List)
                return NewDropdown:Refresh(List)
            end

            function Dropdown:SetVisibility(Bool)
                NewDropdown:SetVisibility(Bool)
            end

            return Dropdown
        end

        Library.Sections.Label = function(self, Text, Big, Alignment, Tooltip)
            local Label = {
                Window = self.Window,
                Page = self.Page,
                Section = self,

                Name = Text or "Label",
                Alignment = Alignment or "Left", 
                
                Count = 0
            }

            local Items = { } do
                Items["Label"] = Instances:Create("Frame", {
                    Parent = Label.Section.Items["Content"].Instance,
                    BackgroundTransparency = 1,
                    ZIndex = 2,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, 0, 0, 20),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                }) 

                Items["Label"]:Tooltip(Tooltip)
                if Big == true then
                    Items["Text"] = Instances:Create("TextLabel", {
                        Parent = Items["Label"].Instance,
                        FontFace = Library.Font,
                        TextColor3 = FromRGB(255, 255, 255),
                        BorderColor3 = FromRGB(0, 0, 0),
                        ZIndex = 2,
                        Text = Label.Name,
                        Name = "\0",
                        AnchorPoint = Vector2New(0, 0), -- 🔥 top-left anchor
                        Position = UDim2New(0, 0, 0, 0), -- 🔥 start from top-left
                        Size = UDim2New(1, -16, 0, 0), -- 🔥 auto height
                        AutomaticSize = Enum.AutomaticSize.Y,
                        TextWrapped = true,
                        RichText = true,
                        BackgroundTransparency = 1,
                        TextXAlignment = Enum.TextXAlignment[Label.Alignment],
                        TextYAlignment = Enum.TextYAlignment.Top, -- 🔥 aligns multi-line text nicely
                        BorderSizePixel = 0,
                        TextSize = 14,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })
                    Items["Text"]:AddToTheme({TextColor3 = "Text"})
                else
                    Items["Text"] = Instances:Create("TextLabel", {
                        Parent = Items["Label"].Instance,
                        RichText = true,
                        FontFace = Library.Font,
                        TextColor3 = FromRGB(255, 255, 255),
                        BorderColor3 = FromRGB(0, 0, 0),
                        ZIndex = 2,
                        Text = Label.Name,
                        Name = "\0",
                        AnchorPoint = Vector2New(0, 0.5),
                        Size = UDim2New(1, -16, 0, 15),
                        TextWrapped = true,
                        AutomaticSize = Enum.AutomaticSize.Y,
                        BackgroundTransparency = 1,
                        TextXAlignment = Enum.TextXAlignment[Label.Alignment],
                        Position = UDim2New(0, 0, 0.5, 0),
                        BorderSizePixel = 0,
                        TextSize = 14,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })

                    Items["Text"]:AddToTheme({
                        TextColor3 = "Text"
                    })
                end

                Instances:Create("UIPadding", {
                    Parent = Items["Label"].Instance,
                    Name = "\0",
                    PaddingTop = UDimNew(0, string.find(Label.Name, "'exempt' teleport") and 12 or 9),
                    PaddingBottom = UDimNew(0, string.find(Label.Name, "'exempt' teleport") and 12 or 9),
                })

                Items["SubElements"] = Instances:Create("Frame", {
                    Parent = Items["Label"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(1, 0.5),
                    BackgroundTransparency = 1,
                    Position = UDim2New(1, 0, 0.5, 0),
                    Size = UDim2New(0, 0, 1, 0),
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.X,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Instances:Create("UIListLayout", {
                    Parent = Items["SubElements"].Instance,
                    Name = "\0",
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Enum.HorizontalAlignment.Right,
                    Padding = UDimNew(0, 6),
                    SortOrder = Enum.SortOrder.LayoutOrder
                })
            end

            function Label:SetText(Text)
                Items["Text"].Instance.Text = tostring(Text)
            end

            function Label:SetVisibility(Bool)
                Items["Label"].Instance.Visible = Bool
            end

            function Label:Colorpicker(Data)
                local Colorpicker = {
                    Window = self.Window,
                    Page = self.Page,
                    Section = self,

                    Name = Data.Name or Data.name,
                    Default = Data.Default or Data.default,
                    Alpha = Data.Alpha or Data.alpha or 0,
                    Flag = Data.Flag or Data.flag or Library:NextFlag(),
                    Callback = Data.Callback or Data.callback or function() end,
                    
                    Count = Label.Count
                }
                
                Label.Count += 1
                Colorpicker.Count = Label.Count

                local NewColorpicker, ColorpickerItems = Components.Colorpicker({
                    Window = Colorpicker.Window,
                    Page = Colorpicker.Page,
                    Parent = Items["SubElements"],
                    Name = Colorpicker.Name,
                    Flag = Colorpicker.Flag,
                    Default = Colorpicker.Default,
                    Alpha = Colorpicker.Alpha,
                    Callback = Colorpicker.Callback,
                    Count = Colorpicker.Count
                })

                return NewColorpicker
            end

            function Label:Keybind(Data)
                Data = Data or { }

                local Keybind = {
                    Window = self.Window,
                    Page = self.Page,
                    Section = self,

                    Name = Data.Name or Data.name or "Keybind",
                    Flag = Data.Flag or Data.flag or Library:NextFlag(),
                    Default = Data.Default or Data.default or Enum.KeyCode.RightShift,
                    Callback = Data.Callback or Data.callback or function() end,
                    Mode = Data.Mode or Data.mode or "Toggle",
                    NoKeyBindList = Data.NoKeyBindList or false;
                }

                local NewKeybind, KeybindItems = Components.Keybind({
                    Name = Keybind.Name,
                    Parent = Items["Label"],
                    Window = Label.Window,
                    Flag = Keybind.Flag,
                    Default = Keybind.Default,
                    Mode = Keybind.Mode,
                    Callback = Keybind.Callback,
                    NoKeyBindList = Keybind.NoKeyBindList
                })

                return NewKeybind
            end

            local SearchData = {
                Name = Label.Name,
                Item = Items["Label"]
            }

            local PageSearchData = Library.SearchItems[Label.Page]

            if not PageSearchData then 
                return 
            end

            TableInsert(PageSearchData, SearchData)

            return Label 
        end

        Library.Sections.Textbox = function(self, Data)
            Data = Data or { }

            local Textbox = {
                Window = self.Window,
                Page = self.Page,
                Section = self,

                Name = Data.Name or Data.name or "Textbox",
                Placeholder = Data.Placeholder or Data.placeholder or "...",
                Flag = Data.Flag or Data.flag or Library:NextFlag(),
                Default = Data.Default or Data.default or "",
                Callback = Data.Callback or Data.callback or function() end,
                Tooltip = Data.Tooltip or Data.tooltip or nil,

                Value = "",
            }

            local Items = { } do
                Items["Textbox"] = Instances:Create("Frame", {
                    Parent = Textbox.Section.Items["Content"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 1,
                    Size = UDim2New(1, 0, 0, 47),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Items["Textbox"]:Tooltip(Textbox.Tooltip)

                Items["Text"] = Instances:Create("TextLabel", {
                    Parent = Items["Textbox"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(255, 255, 255),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = Textbox.Name,
                    AutomaticSize = Enum.AutomaticSize.X,
                    BackgroundTransparency = 1,
                    Size = UDim2New(0, 0, 0, 15),
                    BorderSizePixel = 0,
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Text"]:AddToTheme({TextColor3 = "Text"})

                Items["Background"] = Instances:Create("Frame", {
                    Parent = Items["Textbox"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(0, 1),
                    Position = UDim2New(0, 0, 1, 0),
                    Size = UDim2New(1, 0, 0, 25),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(34, 39, 45)
                })  Items["Background"]:AddToTheme({BackgroundColor3 = "Element"})

                Items["Background"]:OnHover(function()
                    Items["Background"]:Tween(nil, {BackgroundColor3 = Library:GetLighterColor(Library.Theme.Element, 1.45)})
                end)
    
                Items["Background"]:OnHoverLeave(function()
                    Items["Background"]:Tween(nil, {BackgroundColor3 = Library.Theme.Element})
                end)   

                Instances:Create("UICorner", {
                    Parent = Items["Background"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })

                Instances:Create("UIGradient", {
                    Parent = Items["Background"].Instance,
                    Name = "\0",
                    Rotation = 84,
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(211, 211, 211))}
                })

                Items["Input"] = Instances:Create("TextBox", {
                    Parent = Items["Background"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    CursorPosition = -1,
                    TextColor3 = FromRGB(255, 255, 255),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    ZIndex = 2,
                    Size = UDim2New(1, 0, 1, 0),
                    ClipsDescendants = true,
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1,
                    PlaceholderColor3 = FromRGB(185, 185, 185),
                    ClearTextOnFocus = false,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    PlaceholderText = Textbox.Placeholder,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Input"]:AddToTheme({TextColor3 = "Text", PlaceholderColor3 = "Inactive Text"})

                Instances:Create("UIPadding", {
                    Parent = Items["Input"].Instance,
                    Name = "\0",
                    PaddingLeft = UDimNew(0, 8)
                })
            end

            function Textbox:Set(Value)
                Items["Input"].Instance.Text = tostring(Value)
                Textbox.Value = Value
                Library.Flags[Textbox.Flag] = Value

                Items["Input"]:ChangeItemTheme({TextColor3 = "Text", PlaceholderColor3 = "Text Inactive"})
                Items["Input"]:Tween(nil, {TextColor3 = Library.Theme.Text})

                if Textbox.Callback then
                    Library:SafeCall(Textbox.Callback, Value)
                end
            end

            function Textbox:Get()
                return Textbox.Value
            end

            function Textbox:SetVisibility(Bool)
                Items["Textbox"].Instance.Visible = Bool
            end

            getgenv().Options[Textbox.Flag] = Textbox

            local SearchData = {
                Name = Textbox.Name,
                Item = Items["Textbox"]
            }

            local PageSearchData = Library.SearchItems[Textbox.Page]

            if not PageSearchData then 
                return 
            end

            TableInsert(PageSearchData, SearchData)

            Items["Input"]:Connect("Focused", function()
                Items["Input"]:ChangeItemTheme({TextColor3 = "Accent", PlaceholderColor3 = "Text Inactive"})
                Items["Input"]:Tween(nil, {TextColor3 = Library.Theme.Accent})
            end)

            Items["Input"]:Connect("FocusLost", function()
                Textbox:Set(Items["Input"].Instance.Text)
            end)

            if Textbox.Default then 
                Textbox:Set(Textbox.Default)
            end

            Library.SetFlags[Textbox.Flag] = function(Value)
                Textbox:Set(Value)
            end

            return Textbox
        end
    end

    Library.Init = function(self)
        local AutoloadConfig = readfile(Library.Folders.Directory .. "/AutoLoadConfig (do not modify this).json")
        local AutoloadTheme = readfile(Library.Folders.Directory .. "/AutoLoadTheme (do not modify this).json")
        
        if AutoloadConfig ~= "" then
            local Success, Result = Library:LoadConfig(AutoloadConfig)

            if Success then     
                Library:Notification({
                    Name = "Success",
                    Description = "Successfully loaded autoload config",
                    Duration = 5,
                    Icon = "116339777575852",
                    IconColor = Color3.fromRGB(52, 255, 164)
                })
            else
                Library:Notification({
                    Name = "Error!",
                    Description = "Failed to load autoload config, error:\n" .. Result,
                    Duration = 5,
                    Icon = "97118059177470",
                    IconColor = Color3.fromRGB(255, 120, 120)
                })
            end
        end

        if AutoloadTheme ~= "" then
            local Success, Result = Library:LoadTheme(AutoloadTheme)

            if Success then 
                Library:Notification({
                    Name = "Success",
                    Description = "Successfully loaded autoload theme",
                    Duration = 5,
                    Icon = "116339777575852",
                    IconColor = Color3.fromRGB(52, 255, 164)
                })
            else
                Library:Notification({
                    Name = "Error!",
                    Description = "Failed to load autoload theme, error:\n" .. Result,
                    Duration = 5,
                    Icon = "97118059177470",
                    IconColor = Color3.fromRGB(255, 120, 120)
                })
            end
        end
    end
end

-- Example
do
    Window = Library:Window({
        Name = '<font color="rgb(255,255,255)">valary.</font><font color="rgb(236,23,23)">gg</font> | '..Game_Name_MarketPlaceService,
        Version = "v1.1.0",
        Logo = "135215559087473",
        FadeSpeed = 0.25,
        --Size = UDim2.new(0, 659, 0, 511)
    })

    local ESPPreview = Library:ESPPreview({
        MainFrame = Window.Items["MainFrame"] -- keep this
    })

    local ChatSystem = Library:ChatSystem({
        MainFrame = Window.Items["MainFrame"] -- keep this
    })

    local Chat_API = {}

    Chat_API.URL = "https://yellow-band-8a75.oblockjoycesohiorizz.workers.dev/"

    local HttpService = Services.HttpService

    function Chat_API.SendMessage(UserId, Message)
        local Response = game:HttpGet(string.format(
            "%s?format=json&event=chat&message=%s&userid=%s",
            Chat_API.URL,
            HttpService:UrlEncode(Message),
            HttpService:UrlEncode(UserId)
        ))

        return HttpService:JSONDecode(Response)
    end

    function Chat_API.Heartbeat(UserId)
        local Response = game:HttpGet(string.format(
            "%s?format=json&event=heartbeat&userid=%s",
            Chat_API.URL,
            HttpService:UrlEncode(UserId)
        ))
        return HttpService:JSONDecode(Response)
    end

    function Chat_API.GetMessages()
        local Response = game:HttpGet(Chat_API.URL.."?format=json")

        return HttpService:JSONDecode(Response)
    end

    local Cached_Data = {}

    local Special_DiscordIDS = {
        ["1096603799159832636"] = ' - <font color="#EC1717">Owner</font>'
    }

    if not isfolder("valary/Assets/Profiles") then
        makefolder("valary/Assets/Profiles")
    end

    function Chat_API.GetDiscordProfile(Discord_ID)
        if not Cached_Data[Discord_ID] then
            local Response = game:HttpGet("https://discord-lookup-api-neon.vercel.app/v1/user/" .. Discord_ID)
            repeat wait() until Response
            task.wait(0.1)
            Cached_Data[Discord_ID] = HttpService:JSONDecode(Response)
        end
            
        local avatar = Cached_Data[Discord_ID].avatar
        local ext = avatar.is_animated and ".gif" or ".png"

        if not isfile("valary/Assets/Profiles/"..Discord_ID..ext) then
            if not avatar.link then
                writefile("valary/Assets/Profiles/"..Discord_ID..ext, game:HttpGet('https://raw.githubusercontent.com/ValarySoftworks/Assets/refs/heads/main/download.png'))
            else
                writefile("valary/Assets/Profiles/"..Discord_ID..ext, game:HttpGet(avatar.link))
            end
        end

        local Name = Cached_Data[Discord_ID].global_name

        if Special_DiscordIDS[Discord_ID] then
            Name..=Special_DiscordIDS[Discord_ID]
        end

        return getcustomasset("valary/Assets/Profiles/"..Discord_ID..ext), Name
    end

    task.spawn(function()
        do -- Add User
            pcall(function()
                local encodedID = HttpService:UrlEncode(LRM_LinkedDiscordID)
                local base64_name = string.reverse(base64.encode(LocalPlayer.Name))

                local encodedName = HttpService:UrlEncode(base64_name)

                request({
                    Url = "https://yellow-band-8a75.oblockjoycesohiorizz.workers.dev/?event=add_user&userid=" 
                        .. encodedID .. "&username=" .. encodedName,
                    Method = "GET"
                })
            end)
        end

        -- Refresh hearbeat
            task.spawn(LPH_JIT_MAX(function()
                while task.wait(90) do
                    pcall(Chat_API.Heartbeat, LRM_LinkedDiscordID)
                    --local encodedID = HttpService:UrlEncode(LRM_LinkedDiscordID)
                    --request({Url = "https://yellow-band-8a75.oblockjoycesohiorizz.workers.dev/?event=heartbeat&userid="..encodedID, Method = "GET"})
                end
            end))
        --

        -- Refresh Status
            do
                pcall(function()
                    local Users = Chat_API.GetMessages().users.value

                    ChatSystem:SetStatusText(string.format('%s Active | Connected', tostring(Users)))
                end)
            end
        --
            
        ChatSystem:OnMessageSendPressed(function()
            local Profile, Username = Chat_API.GetDiscordProfile(LRM_LinkedDiscordID)

            local Text = ChatSystem:GetTypedMessage()

            ChatSystem:ClearText()
            
            ChatSystem:SendMessage(Profile, Username, Text, true)

            pcall(Chat_API.SendMessage, LRM_LinkedDiscordID, Text)
        end)

        task.spawn(LPH_JIT_MAX(function()
            local data_to_send = {}
            local Already_Sent = {}

            --[[pcall(function()
                for i,v in Chat_API.GetMessages().messages do
                    if not Already_Sent[v.message.."_"..v.userid.."_"..v.timestamp] then
                        Already_Sent[v.message.."_"..v.userid.."_"..v.timestamp] = true
                    end
                end
            end)]]

            local function formatNameWithTime(username, time)
                return string.format(
                    '%s <font color="#72767D"> %s</font>',
                    username,
                    os.date("%H:%M", time)
                )
            end

            while task.wait(1) do
                local Success, Error = pcall(function()
                    local Messages = Chat_API.GetMessages()

                    ChatSystem:SetStatusText(string.format('%s Active | Connected', tostring(Messages.users.value)))

                    if not Messages.users.stored[LRM_LinkedDiscordID] then
                        local encodedID = HttpService:UrlEncode(LRM_LinkedDiscordID)
                        local base64_name = string.reverse(base64.encode(LocalPlayer.Name))

                        local encodedName = HttpService:UrlEncode(base64_name)

                        request({
                            Url = "https://yellow-band-8a75.oblockjoycesohiorizz.workers.dev/?event=add_user&userid=" 
                                .. encodedID .. "&username=" .. encodedName,
                            Method = "GET"
                        })
                    end

                    for i, v in pairs(Messages.users.stored) do
                        if v.usernames then
                            for _, username in ipairs(v.usernames) do
                                pcall(function()
                                    local decoded_user = base64.decode(string.reverse(username))

                                    if not Config.Valary_Users[decoded_user] then
                                        Config.Valary_Users[decoded_user] = i
                                    end
                                end)
                            end
                        end
                    end

                    local toRemove = {}

                    for username, id in Config.Valary_Users do
                        if not Messages.users.stored[id] then
                            table.insert(toRemove, username)
                        end
                    end

                    for _, username in toRemove do
                        Config.Valary_Users[username] = nil
                    end

                    for _, v in pairs(Messages.messages) do
                        --if v.userid ~= LRM_LinkedDiscordID then
                            if not Already_Sent[v.userid.."_"..v.timestamp.."_"..v.message] then
                                local Profile, Username = Chat_API.GetDiscordProfile(v.userid)

                                Username = tostring(Username or "Unknown")
                                local Timestamp = tonumber(v.timestamp) or os.time()

                                data_to_send[v.userid] = data_to_send[v.userid] or {}

                                table.insert(data_to_send[v.userid], {
                                    UserId = v.userid,
                                    Profile = Profile,
                                    Username = Username,
                                    Message = tostring(v.message or "ERROR"),
                                    Timestamp = Timestamp
                                })
                            end
                        --end
                    end

                    local flat = {}

                    for _, msgs in pairs(data_to_send) do
                        for _, msg in ipairs(msgs) do
                            table.insert(flat, msg)
                        end
                    end

                    table.sort(flat, function(a, b)
                        return a.Timestamp < b.Timestamp
                    end)

                    for _, v in ipairs(flat) do
                        local msgKey = v.UserId .. "_" .. v.Timestamp .. "_" .. v.Message

                        local Check = v.UserId ~= LRM_LinkedDiscordID

                        if not dfihjdsiufodsaiuojdfdsjauidfsdad then
                            Check = true
                        end

                        if not Already_Sent[msgKey] and Check then
                            ChatSystem:SendMessage(
                                v.Profile,
                                formatNameWithTime(v.Username, v.Timestamp),
                                v.Message,
                                v.UserId == LRM_LinkedDiscordID
                            )

                            Already_Sent[msgKey] = true
                        end
                    end

                    table.clear(data_to_send)

                    --[[for i,v in Messages.messages do
                        if v.userid ~= LRM_LinkedDiscordID and not Already_Sent[v.message.."_"..v.userid.."_"..v.timestamp] then
                            local Profile, Username = Chat_API.GetDiscordProfile(v.userid)

                            ChatSystem:SendMessage(Profile, formatNameWithTime(Username, v.timestamp), v.message, false)
                            Already_Sent[v.message.."_"..v.userid.."_"..v.timestamp] = true
                        end
                    end]]

                    if not dfihjdsiufodsaiuojdfdsjauidfsdad then
                        getgenv().SendMessage_Input.Instance.PlaceholderText = "Send message"
                        dfihjdsiufodsaiuojdfdsjauidfsdad = true
                    end
                end)

                if not Success then
                    --warn("GLOBAL CHAT ERROR :",Error)
                end
            end
        end))
    end)
    
    Watermark = Library:Watermark("This is a watermark", "135215559087473")
    Watermark:SetVisibility(false)
    local KeybindList = Library:KeybindsList()
    KeybindList:SetVisibility(false)

    task.spawn(LPH_NO_VIRTUALIZE(function()
        while task.wait(1) do
            Watermark:SetText(string.format('<font color="rgb(255,255,255)">valary.</font><font color="rgb(%d,%d,%d)">gg</font> - %s - %s',Library.Theme.Accent.R*255,Library.Theme.Accent.G*255,Library.Theme.Accent.B*255, Game_Name_MarketPlaceService, os.date("%b. %d %Y, %X")))
        end
    end))

    do
        local Pages = {
            ["Combat"] = Window:Page({
                Name = "Combat", 
                Icon = "111386589037485",
                SubPages = true,
            }),
            
            ["Visuals"] = Window:Page({
                Name = "Visuals", 
                Icon = "115907015044719", 
                SubPages = true,
            }),

            ["Main"] = Window:Page({
                Name = "Main", 
                Icon = "136623465713368", 
                SubPages = true,
            }),

            ["Misc"] = Window:Page({
                Name = "Player List", 
                Icon = Library:GetImage("GroupSearch"), 
                Columns = 2
            }),

            ["Settings"] = Window:Page({
                Name = "Settings", 
                Icon = "137300573942266", 
                Columns = 2,
                SubPages = true
            })
        }

        do -- Misc
            local Playerlist = Pages["Misc"]:Playerlist({
                Callback = function(...)
                    local Args = {...}

                    Library.Selected_Player = Args[1]
                end
            })
        end

        do -- Combat
            local Subpages = {
                ["Selector"] = Pages["Combat"]:SubPage({
                    Name = "Selector", 
                    Icon = "126028986879491", 
                    Columns = 2
                }),
                ["Aimbot"] = Pages["Combat"]:SubPage({
                    Name = "Aimbot", 
                    Icon = Library:GetImage("Forward"), 
                    Columns = 2
                }),
                ["Weapon_Mods"] = Pages["Combat"]:SubPage({
                    Name = "Modifications", 
                    Icon = Library:GetImage("Tune"), 
                    Columns = 2
                }),
            }

            do -- Selector
                local Field_OfView_Section = Subpages["Selector"]:Section({Name = "Field Of View Settings", Icon = Library:GetImage("Radar"), Side = 1})
                
                local SelectedTarget_Settings = Subpages["Selector"]:Section({Name = "Selected Target Settings", Icon = Library:GetImage("DiagonalLine"), Side = 1})

                local TargetSelector_Section = Subpages["Selector"]:Section({Name = "Target Selector Settings", Icon = Library:GetImage("AdsClick"), Side = 2})

                --local GeneralSection2 = Subpages["Aimbot"]:Section({Name = "general2", Icon = "103174889897193", Side = 1})

                do
                    Field_OfView_Section:Toggle({Name="Use Field Of View",Flag="FieldOfView_Enabled",Default=false,Callback=function(State) Config.TargetSelector.UseFOV=State end})

                    Field_OfView_Section:Slider({Name="Field Of View Radius",Flag="FieldOfView_Radius",Default=25, Suffix = "°", Min=0,Max=100,Decimals=1,Callback=function(State)
                        Config.FieldOfView.Radius=State*10
                        FieldOfView.Radius=State*10
                        FieldOfViewOutline.Radius=State*10
                        FieldOfViewFill.Radius=State*10
                    end})

                    Field_OfView_Section:Slider({Name="Field Of View Sides",Flag="FieldOfView_Sides", Suffix = "°", Default=50,Min=3,Max=100,Callback=function(State)
                        FieldOfView.NumSides=State
                        FieldOfViewOutline.NumSides=State
                        FieldOfViewFill.NumSides=State
                    end})

                    Field_OfView_Section:Toggle({Name="Draw Field Of View",Flag="FieldOfView_Drawed",Default=false,Callback=function(State) Config.FieldOfView.Draw=State end}):Colorpicker({Name="Field Of View Color",Default=Color3.new(1,1,1),Alpha=0,Callback=function(Color,Transparency)
                        Config.FieldOfView.FieldOfViewColor=Color
                        FieldOfView.Color=Color
                        Config.FieldOfView.Transparency=1-Transparency
                        FieldOfView.Transparency=1-Transparency
                        FieldOfViewOutline.Transparency=1-Transparency
                    end})

                    SelectedTarget_Settings:Toggle({Name="Draw Snapline",Flag="Draw_Snapline",Default=false,Callback=function(State) Config.FieldOfView.DrawSnapline=State end}):Colorpicker({Name="Snapline Color",Default = Color3.new(1,1,1), Alpha=0,Callback=function(Color,Transparency)
                        Snapline.Color=Color
                        Snapline.Transparency=1-Transparency
                        SnaplineOutline.Transparency=1-Transparency
                    end})

                    SelectedTarget_Settings:Slider({Name="Snapline Thickness",Flag="Snapline_Thickness",Default=1,Min=1,Max=5,Callback=function(State)
                        SnaplineOutline.Thickness=State+2
                        Snapline.Thickness=State
                    end})

                    local _Toggle=SelectedTarget_Settings:Toggle({Name="Highlight Target",Flag="Highlight_Target",Callback=function(State) Config.FieldOfView.HightlightTarget=State end})
                    _Toggle:Colorpicker({Name="Highlight Filled Color", Default = Color3.fromRGB(255,0,0), Alpha=0.6,Callback=function(Color,Transparency)
                        Config.FieldOfView.HightlightFillColor=Color

                        Config.FieldOfView.HightlightFillTransparency=Transparency

                        Target_Highlight.FillColor = Config.FieldOfView.HightlightFillColor
                        Target_Highlight.FillTransparency = Config.FieldOfView.HightlightFillTransparency
                    end})
                    
                    TargetSelector_Section:Label("Select Player Keybind","Left"):Keybind({Name="Select Player",Flag="selectplayerbind",Default=Enum.KeyCode.Q,Mode="toggle",Callback=function(State) Config.TargetSelector.Targetting=State end})

                    TargetSelector_Section:Toggle({Name="Health Check",Flag="Target_Health_Check",Default=false,Callback=function(value) Config.TargetSelector.HealthCheck=value end})

                    TargetSelector_Section:Slider({Name="Minimum Health",Flag="Target_Minimum_Health",Default=5,Min=0,Max=100,Decimals=1,Suffix="%",Callback=function(value) Config.TargetSelector.Health=value end})

                    TargetSelector_Section:Toggle({Name="Distance Check",Flag="Target_Distance_Check",Default=false,Callback=function(value) Config.TargetSelector.LimitDistance=value end})

                    TargetSelector_Section:Slider({Name="Maximum Distance",Flag="Target_Max_Distance",Default=350,Min=0,Max=350,Decimals=1,Suffix="m",Callback=function(value) Config.TargetSelector.MaxDistance=value end})

                    TargetSelector_Section:Toggle({Name="Visible Check",Flag="Target_Visible_Check",Default=false,Callback=function(value) Config.TargetSelector.VisibleCheck=value end})

                    TargetSelector_Section:Toggle({Name="Friend Check",Flag="Target_Friend_Check",Default=false,Callback=function(value) Config.TargetSelector.FriendCheck=value end})

                    TargetSelector_Section:Toggle({Name="Safe Check",Flag="Target_Safe_Check",Default=false,Callback=function(value) Config.TargetSelector.ProtectedCheck=value end})
                end
            end

            do -- Aimbot
                local SilentAim_Section = Subpages["Aimbot"]:Section({Name = "Silent Aimbot", Icon = Library:GetImage("Bolt"), Side = 1})
            
                SilentAim_Section:Toggle({Name = "Enabled", Flag = "SilentAim_Enabled", Default = false, Callback = function(State)
                    Config.Silent.Enabled = State
                end})
                            
                --[[SilentAim_Section:Toggle({Name = "Wall Bang", Flag = "SilentAim_Wallbang", Default = false, Callback = function(State)
                    Config.Silent.WallBang = State
                end})]]

                SilentAim_Section:Slider({Name="Silent Aim Hit Chance",Suffix = "%",Flag="SilentAim_HitChance",Default=100,Min=0,Max=100,Callback=function(State)
                    Config.Silent.HitChance = State
                end})

                SilentAim_Section:Dropdown({
                    Name = "Select Hit Parts",
                    Flag = "SilentAim_HitParts",
                    Items = {
                        "Head",
                        "UpperTorso",
                        "LowerTorso",
                        "LeftUpperArm",
                        "LeftLowerArm",
                        "RightUpperArm",
                        "RightLowerArm",
                        "LeftUpperLeg",
                        "LeftLowerLeg",
                        "RightUpperLeg",
                        "RightLowerLeg",
                        "HumanoidRootPart"
                    },
                    Default = {"Head", "HumanoidRootPart", "LeftUpperLeg", "RightUpperLeg"},
                    Multi = true,
                    MaxSize = 200,
                    Callback = function(State)
                        table.clear(Config.Silent.HitParts)
                        
                        for Index, Value in State do
                            table.insert(Config.Silent.HitParts, Value)
                        end
                    end
                })

                local HitSound_Section = Subpages["Aimbot"]:Section({Name = "Hit Sounds", Icon = Library:GetImage("Bomb"), Side = 2})

                local Sound_Names = {}

                for Index, Value in Config.Hit_Sounds do
                    table.insert(Sound_Names, Index)
                end

                table.sort(Sound_Names)

                HitSound_Section:Toggle({Name = "Enabled", Flag = "SouthBronx/Silent/HitSoundsEnabled", Callback = function(State)
                    Config.Hit_Sounds_Settings.Enabled = State
                end})

                HitSound_Section:Toggle({Name = "Hide Normal Gun Sound", Tooltip = "If enabled, this will make the normal gunshot sound silent.", Flag = "SouthBronx/Silent/HideNormalGunSound", Callback = function(State)
                    Config.Hit_Sounds_Settings.HideNormalSounds = State
                end})

                HitSound_Section:Dropdown({Name = "Select Sound", Items = Sound_Names, MaxSize = 175, Default = "Neverlose", Flag = "SouthBronx/Silent/SelectHitSound", Callback = function(State)
                    if Config.Hit_Sounds[State] then
                        Config.Hit_Sounds_Settings.Selected = State

                        local sound = Instance.new("Sound")
                        sound.SoundId = Config.Hit_Sounds[State]
                        sound.Volume = Config.Hit_Sounds_Settings.Volume
                        sound.Looped = false
                        sound.Parent = Workspace
                        sound.RollOffMode = Enum.RollOffMode.Linear
                        sound.EmitterSize = 2
                        sound.MaxDistance = 10

                        sound:Play()
                    end
                end})

                HitSound_Section:Slider({Name = "Select Volume", Flag = "SouthBronx/Silent/SelectVolume", Max = 10, Min = 1, Default = 5, Decimals = 1, Callback = function(State)
                    Config.Hit_Sounds_Settings.Volume = State
                end})

                local HitBoxExpander_Section = Subpages["Aimbot"]:Section({Name = "Head Hit-Box Expanders", Icon = Library:GetImage("expand-arrows"), Side = 1})

                HitBoxExpander_Section:Toggle({Name = "Enabled", Flag = "SouthBronx/HitBoxes/Enabled", Default = false, Callback = function(State)
                    Config.Hitbox_Expander.Enabled = State
                end})

                HitBoxExpander_Section:Toggle({Name = "Safe-Zone Check", Flag = "SouthBronx/HitBoxes/Safe-ZoneCheck", Default = false, Callback = function(State)
                    Config.Hitbox_Expander.SafeZoneCheck = State
                end})

                HitBoxExpander_Section:Slider({Name = "Multiplier", Flag = "SouthBronx/HitBoxes/Multiplier", Max = 50, Min = 1, Default = 5, Suffix = "x", Callback = function(State)
                    Config.Hitbox_Expander.Multiplier = State
                end})

                HitBoxExpander_Section = Subpages["Aimbot"]:Section({Name = "Hit-Box Customization", Icon = "103863157706913", Side = 2})

                HitBoxExpander_Section:Label("Hit-Box Color"):Colorpicker({
                    Name = "Hit-Box Color",
                    Flag = "SouthBronx/HitBoxes/Color",
                    Default = Color3.new(1,1,1),
                    Alpha = 0,
                    Callback = function(Value)
                        Config.Hitbox_Expander.Color = Value
                    end
                })

                HitBoxExpander_Section:Slider({Name = "Hit-Box Transparency", Flag = "SouthBronx/HitBoxes/Transparency", Min = 0, Max = 100, Default = 75, Suffix = "%", Callback = function(State)
                    Config.Hitbox_Expander.Transparency = State/100
                end})
            end

            do -- Modifications
                local Section_Ok = Subpages["Weapon_Mods"]:Section({Name = "Modification Information", Icon = Library:GetImage("Info"), Side = 1})
                
                Section_Ok:Label("Beware of modifications that have warnings, they can be detected by the server!", "Left")

                local Weapon_Modifications_Enabled = Subpages["Weapon_Mods"]:Section({Name = "Weapon Modifications", Icon = Library:GetImage("Wrench"), Side = 1})

                --[[Weapon_Modifications_Enabled:Toggle({Name='Infinite Ammo ⚠', Color = Color3.fromRGB(255,255,60), Flag="InfiniteAmmo_Enabled",Default=false,Callback=function(State) 
                    Config["Infinite Ammo"].Enabled = State

                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool") and LocalPlayer.Character:FindFirstChildOfClass("Tool"):FindFirstChild("Setting") then
                        Config.Modify(LocalPlayer.Character:FindFirstChildOfClass("Tool"))
                    end
                end})]]

                Weapon_Modifications_Enabled:Toggle({Name='Instant Bullet', Flag="InstantBullet_Enabled",Default=false,Callback=function(State) 
                    Config["Instant Bullet"].Enabled = State

                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool") and LocalPlayer.Character:FindFirstChildOfClass("Tool"):FindFirstChild("Setting") then
                        Config.Modify(LocalPlayer.Character:FindFirstChildOfClass("Tool"))
                    end
                end})

                Weapon_Modifications_Enabled:Toggle({Name='Instant Reload', Flag="InstantReload_Enabled",Default=false,Callback=function(State) 
                    Config["Instant Reload"].Enabled = State

                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool") and LocalPlayer.Character:FindFirstChildOfClass("Tool"):FindFirstChild("Setting") then
                        Config.Modify(LocalPlayer.Character:FindFirstChildOfClass("Tool"))
                    end
                end})

                Weapon_Modifications_Enabled:Toggle({Name='Instant Equip', Flag="InstantEquip_Enabled",Default=false,Callback=function(State) 
                    Config["Instant Equip"].Enabled = State

                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool") and LocalPlayer.Character:FindFirstChildOfClass("Tool"):FindFirstChild("Setting") then
                        Config.Modify(LocalPlayer.Character:FindFirstChildOfClass("Tool"))
                    end
                end})

                --[[Weapon_Modifications_Enabled:Toggle({Name='Instant Kill ⚠', Color = Color3.fromRGB(255,255,60), Flag="InstantKill_Enabled",Default=false,Callback=function(State) 
                    Config["One Tap"].Enabled = State

                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool") and LocalPlayer.Character:FindFirstChildOfClass("Tool"):FindFirstChild("Setting") then
                        Config.Modify(LocalPlayer.Character:FindFirstChildOfClass("Tool"))
                    end
                end})]]

                Weapon_Modifications_Enabled:Toggle({Name='Automatic Mode', Flag="Automatic_Mode_Enabled",Default=false,Callback=function(State) 
                    Config["Force Auto"].Enabled = State

                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool") and LocalPlayer.Character:FindFirstChildOfClass("Tool"):FindFirstChild("Setting") then
                        Config.Modify(LocalPlayer.Character:FindFirstChildOfClass("Tool"))
                    end
                end})

                Weapon_Modifications_Enabled:Toggle({Name='Modify Fire Rate ⚠', Color = Color3.fromRGB(255,255,60), Flag="IncreaseFire-Rate_Enabled",Default=false,Callback=function(State) 
                    Config["Fire_Rate"].Enabled = State

                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool") and LocalPlayer.Character:FindFirstChildOfClass("Tool"):FindFirstChild("Setting") then
                        Config.Modify(LocalPlayer.Character:FindFirstChildOfClass("Tool"))
                    end
                end})

                Weapon_Modifications_Enabled:Toggle({Name='Modify Recoil', Flag="ModifyRecoil_Enabled",Default=false,Callback=function(State) 
                    Config["Recoil"].Enabled = State

                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool") and LocalPlayer.Character:FindFirstChildOfClass("Tool"):FindFirstChild("Setting") then
                        Config.Modify(LocalPlayer.Character:FindFirstChildOfClass("Tool"))
                    end
                end})

                Weapon_Modifications_Enabled:Toggle({Name='Modify Spread', Flag="ModifySpread_Enabled",Default=false,Callback=function(State) 
                    Config["Spread"].Enabled = State

                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool") and LocalPlayer.Character:FindFirstChildOfClass("Tool"):FindFirstChild("Setting") then
                        Config.Modify(LocalPlayer.Character:FindFirstChildOfClass("Tool"))
                    end
                end})

                Weapon_Modifications_Enabled:Toggle({Name='No Jamming', Flag="NoJamming_Enabled",Default=false,Callback=function(State) 
                    Config["No Jam"].Enabled = State

                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool") and LocalPlayer.Character:FindFirstChildOfClass("Tool"):FindFirstChild("Setting") then
                        Config.Modify(LocalPlayer.Character:FindFirstChildOfClass("Tool"))
                    end
                end})

                Weapon_Modifications_Enabled = Subpages["Weapon_Mods"]:Section({Name = "Weapon Modification Settings", Icon = Library:GetImage("MultipleCogs"), Side = 2})

                Weapon_Modifications_Enabled:Label("100% is the default percentage.")

                Weapon_Modifications_Enabled:Slider({
                    Name = "Fire-Rate Percentage",
                    Default = 50,
                    Max = 100,
                    Min = 15,
                    Decimals = 1,
                    Suffix = "%",
                    Flag = "Fire_Rate_Percentage",
                    Callback = function(Value)
                        Config.Fire_Rate.Increase = Value

                        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool") and LocalPlayer.Character:FindFirstChildOfClass("Tool"):FindFirstChild("Setting") then
                            Config.Modify(LocalPlayer.Character:FindFirstChildOfClass("Tool"))
                        end
                    end
                })

                Weapon_Modifications_Enabled:Slider({
                    Name = "Spread Percentage",
                    Default = 50,
                    Max = 100,
                    Min = 0,
                    Decimals = 1,
                    Suffix = "%",
                    Flag = "Spread_Percentage",
                    Callback = function(Value)
                        Config.Spread.Reduce = Value

                        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool") and LocalPlayer.Character:FindFirstChildOfClass("Tool"):FindFirstChild("Setting") then
                            Config.Modify(LocalPlayer.Character:FindFirstChildOfClass("Tool"))
                        end
                    end
                })

                Weapon_Modifications_Enabled:Slider({
                    Name = "Recoil Percentage",
                    Default = 50,
                    Max = 100,
                    Min = 0,
                    Decimals = 1,
                    Suffix = "%",
                    Flag = "Recoil_Percentage",
                    Callback = function(Value)
                        Config.Recoil.Reduce = Value

                        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool") and LocalPlayer.Character:FindFirstChildOfClass("Tool"):FindFirstChild("Setting") then
                            Config.Modify(LocalPlayer.Character:FindFirstChildOfClass("Tool"))
                        end
                    end
                })

                --[[Weapon_Modifications_Enabled = Subpages["Weapon_Mods"]:Section({Name = "Kill Aura Settings", Icon = Library:GetImage("Skull"), Side = 2})

                KillAura_Toggle = Weapon_Modifications_Enabled:Toggle({Name='Enabled - Hold Gun ⚠', Color = Color3.fromRGB(255,255,60), Flag="KillAura_Enabled",Default=false,Callback=function(State) 
                    Config.South_Bronx.KillAura.Enabled = State
                end})

                KillAura_Range = Weapon_Modifications_Enabled:Slider({
                    Name = "Kill Aura Range",
                    Default = 375,
                    Max = 375,
                    Minimum = 1,
                    Decimals = 1,
                    Suffix = "m",
                    Flag = "Kill_Aura_Range",
                    Callback = function(Value)
                        Config.South_Bronx.KillAura.Range = Value
                    end
                })

                -- Infinite Ammo Loop
                local Index = 0
                    RunService.RenderStepped:Connect(LPH_NO_VIRTUALIZE(function() 
                        local Character = LocalPlayer.Character
                        local Tool = Character and Character:FindFirstChildOfClass("Tool")

                        if Character and Tool and Tool:FindFirstChild("Setting") then
                            if Config["Infinite Ammo"].Enabled and Index >= 3 then
                                ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("RPC"):FireServer(buffer.fromstring("\003"), Tool)
                                Index=0
                            end

                            Index+=1

                            local ModuleSettings = require(Tool.Setting)

                            local Mag_Val = ModuleSettings.AmmoPerMag

                            local Max_Ammo = math.clamp(Mag_Val*2, 0, 50)

                            if Tool:FindFirstChild("Ammo") and Tool:FindFirstChild("Mag") and Mag_Val then
                                if Config["Infinite Ammo"].Enabled then
                                    Tool.Ammo.Value = Max_Ammo
                                    Tool.Mag.Value = Mag_Val
                                end
                            end
                        end
                    end))
                --]]
            end
        end

        do -- Visuals
            local Subpages = {
                ["Player ESP"] = Pages["Visuals"]:SubPage({
                    Name = "Players", 
                    Icon = "111178525804834", 
                    Columns = 2
                }),
                ["World"] = Pages["Visuals"]:SubPage({
                    Name = "World", 
                    Icon = Library:GetImage("GlobePublic"), 
                    Columns = 2
                }),
            }


            local PlayersSection = Subpages["Player ESP"]:Section({Name = "Players - Main Settings", Side = 1, Icon = "135799335731002"})

            ESPPreview:SetVisibility(false)

            ESPPreview:Set("BoxHolder", "BackgroundTransparency", 1)
            ESPPreview:Set("BoxHolder", "Visible", false)
            ESPPreview:Set("Corners", "Visible", false)
            ESPPreview:Set("WeaponText", "Visible", false)
            ESPPreview:Set("Distance", "Visible", false)
            ESPPreview:Set("Name", "Visible", false)
            ESPPreview:Set("HealthBar", "Visible", false)
            ESPPreview:Set("HealthBarText", "Visible", false)
            ESPPreview:Set("HealthBarText", "Position", UDim2.new(0, -5, 0, 0))

            PlayersSection:Toggle({
                Name = "Enabled",
                Flag = "Visuals/ESP/MasterSwitch",
                Default = false,
                Callback = function(Value)
                    Options["Enabled"] = Value
                    MiscOptions["Enabled"] = Value

                    ESPPreview:SetVisibility(Value)
                end
            })

            local BoxesToggle = PlayersSection:Toggle({
                Name = "Boxes",
                Flag = "Visuals/ESP/Boxes",
                Default = false,
                Callback = function(Value)
                    MiscOptions["Boxes"] = Value
                    Options["Boxes"] = Value

                    ESPPreview:Set("BoxHolder", "Visible", Value)

                    for index,value in MiscOptions do 
                        Options[index] = value -- gotta trigger that new index
                    end 

                    if Options["BoxType"] == "Corner" then
                        if Options["Boxes"] then
                            ESPPreview:Set("BoxHolder", "Visible", false)
                            ESPPreview:Set("Corners", "Visible", true)
                        else
                            ESPPreview:Set("BoxHolder", "Visible", false)
                            ESPPreview:Set("Corners", "Visible", Value)
                        end
                    else
                        if Options["Boxes"] then
                            ESPPreview:Set("BoxHolder", "Visible", true)
                            ESPPreview:Set("Corners", "Visible", false)
                        else
                            ESPPreview:Set("BoxHolder", "Visible", Value)
                            ESPPreview:Set("Corners", "Visible", false)
                        end
                    end
                end
            })

            BoxesToggle:Colorpicker({
                Name = "Gradient 1",
                Flag = "Visuals/ESP/Boxes/Gradient 1",
                Default = Options["Box Gradient 1"].Color,
                Alpha = 0,
                Callback = function(Value)
                    Options["Box Gradient 1"] = {Color = Value, Transparency = Alpha}
                    MiscOptions["Box Gradient 1"] = {Color = Value, Transparency = Alpha}
                    ESPPreview:Set("BoxGradient", "Color", ColorSequence.new{ColorSequenceKeypoint.new(0, Value), ColorSequenceKeypoint.new(1, Options["Box Gradient 2"]["Color"])})
                    
                    if Options["BoxType"] == "Corner" then
                        for _, descendant in ESPPreview.Items.Corners.Instance:GetDescendants() do
                            if descendant:IsA("UIGradient") then
                                descendant.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Value), ColorSequenceKeypoint.new(1, Options["Box Gradient 2"]["Color"])}
                            end
                        end
                    end
                end
            })

            BoxesToggle:Colorpicker({
                Name = "Gradient 2",
                Flag = "Visuals/ESP/Boxes/Gradient 2",
                Default = Options["Box Gradient 2"].Color,
                Alpha = 0,
                Callback = function(Value, Alpha)
                    Options["Box Gradient 2"] = {Color = Value, Transparency = Alpha}
                    MiscOptions["Box Gradient 2"] = {Color = Value, Transparency = Alpha}
                    ESPPreview:Set("BoxGradient", "Color", ColorSequence.new{ColorSequenceKeypoint.new(0, Options["Box Gradient 1"]["Color"]), ColorSequenceKeypoint.new(1, Value)})
                
                    if Options["BoxType"] == "Corner" then
                        for _, descendant in ESPPreview.Items.Corners.Instance:GetDescendants() do
                            if descendant:IsA("UIGradient") then
                                descendant.Color =  ColorSequence.new{ColorSequenceKeypoint.new(0, Options["Box Gradient 1"]["Color"]), ColorSequenceKeypoint.new(1, Value)}
                            end
                        end
                    end
                end
            })

            PlayersSection:Dropdown({
                Name = "Type",
                Flag = "Visuals/ESP/BoxType",
                Items = {"Normal", "Corner"},
                Default = "Corner",
                MaxSize = 100,
                Callback = function(Value)
                    MiscOptions["BoxType"] = Value
                    Options["BoxType"] = Value

                    --if not Options["Boxes"] then return end
                    
                    if Options["Boxes"] then
                        if Value == "Corner" then
                            ESPPreview:Set("BoxHolder", "Visible", false)
                            ESPPreview:Set("Corners", "Visible", true)
                        else
                            ESPPreview:Set("BoxHolder", "Visible", true)
                            ESPPreview:Set("Corners", "Visible", false)
                        end
                    end

                    for index,value in MiscOptions do 
                        Options[index] = value -- gotta trigger that new index
                    end 
                end
            })
            
            PlayersSection:Slider({
                Name = "Rotation",
                Flag = "Visuals/ESP/BoxGradientRotation",
                Default = 90,
                Suffix = "°",
                Min = -180,
                Max = 180,
                Decimals = 1,
                Callback = function(Value)
                    Options["Box Gradient Rotation"] = Value
                    MiscOptions["Box Gradient Rotation"] = Value

                    ESPPreview:Set("BoxGradient", "Rotation", Value)
                end
            })

            local BoxesFilledToggle = PlayersSection:Toggle({
                Name = "Filled",
                Flag = "Visuals/ESP/BoxesFilled",
                Default = false,
                Callback = function(Value)
                    Options["Box Fill"] = Value
                    MiscOptions["Box Fill"] = Value

                    ESPPreview:Set("BoxHolder", "BackgroundTransparency", Value and 0 or 1)
                end
            })

            BoxesFilledToggle:Colorpicker({
                Name = "Gradient 1",
                Flag = "Visuals/ESP/Boxes/FilledGradient 1",
                Default = Options["Box Fill 1"].Color,
                Alpha = 0.3,
                Callback = function(Value, Alpha)
                    Options["Box Fill 1"] = {Color = Value, Transparency = Alpha}
                    MiscOptions["Box Fill 1"] = {Color = Value, Transparency = Alpha}

                    local Path = ESPPreview.Items.CornersGradient.Instance
                    Path.Transparency = NumberSequence.new{
                        NumberSequenceKeypoint.new(0, 1 - Alpha), 
                        Path.Transparency.Keypoints[2]
                    }

                    Path.Color = ColorSequence.new{
                        ColorSequenceKeypoint.new(0, Value), 
                        Path.Color.Keypoints[2]
                    }

                    local Path = ESPPreview.Items.BoxHolderGradient.Instance
                    Path.Transparency = NumberSequence.new{
                        Path.Transparency.Keypoints[1],
                            NumberSequenceKeypoint.new(1, 1 - Alpha)
                        }

                    Path.Color = ColorSequence.new{
                        Path.Color.Keypoints[1],
                            ColorSequenceKeypoint.new(1, Value)
                        }
                end
            })

            BoxesFilledToggle:Colorpicker({
                Name = "Gradient 2",
                Flag = "Visuals/ESP/Boxes/FilledGradient 2",
                Default = Options["Box Fill 2"].Color,
                Alpha = 0.3,
                Callback = function(Value, Alpha)
                    Options["Box Fill 2"] = {Color = Value, Transparency = Alpha}
                    MiscOptions["Box Fill 2"] = {Color = Value, Transparency = Alpha}

                    local Path = ESPPreview.Items.CornersGradient.Instance
                    Path.Transparency = NumberSequence.new{
                        Path.Transparency.Keypoints[1],
                        NumberSequenceKeypoint.new(1, Alpha)
                    };

                    Path.Color = ColorSequence.new{
                        Path.Color.Keypoints[1],
                        ColorSequenceKeypoint.new(1, Value)
                    };

                    local Path = ESPPreview.Items.BoxHolderGradient.Instance
                    Path.Transparency = NumberSequence.new{
                        NumberSequenceKeypoint.new(0, Alpha), 
                        Path.Transparency.Keypoints[2]
                    }

                    Path.Color = ColorSequence.new{
                        ColorSequenceKeypoint.new(0, Value), 
                        Path.Color.Keypoints[2]
                    }
                end
            })

            PlayersSection:Slider({
                Name = "Rotation",
                Flag = "Visuals/ESP/BoxFillGradientRotation",
                Default = 90,
                Suffix = "°",
                Min = -180,
                Max = 180,
                Decimals = 1,
                Callback = function(Value)
                    MiscOptions["Box Fill Rotation"] = Value
                    Options["Box Fill Rotation"] = Value

                    ESPPreview:Set("BoxHolderGradient", "Rotation", Value)
                    ESPPreview:Set("CornersGradient", "Rotation", Value)

                    for index,value in MiscOptions do 
                        Options[index] = value -- gotta trigger that new index
                    end 
                end
            })

            local HealthBarToggle = PlayersSection:Toggle({
                Name = "Healthbar",
                Flag = "Visuals/ESP/Healthbar",
                Default = false,
                Callback = function(Value)
                    MiscOptions["Healthbar"] = Value
                    Options["Healthbar"] = Value

                    ESPPreview:Set("HealthBar", "Visible", Value)

                    for index,value in MiscOptions do 
                        Options[index] = value -- gotta trigger that new index
                    end 
                end
            })

            PlayersSection:Dropdown({
                Name = "Healthbar side",
                Flag = "Visuals/ESP/HealthbarSide",
                MaxSize = 145,
                Default = "Left",
                Items = {"Left", "Bottom", "Top", "Right"},
                Callback = function(Value)
                    Value = Value or "Left"
                    MiscOptions["Healthbar_Position"] = Value
                    Options["Healthbar_Position"] = Value

                    ESPPreview:Set("HealthBar", "Parent", ESPPreview.Items[Value].Instance or ESPPreview.Items.Left.Instance)

                    if Options["Healthbar_Position"] == "Right" then
                        ESPPreview:Set("HealthBarText", "Visible", Options["Healthbar_Number"])
                        ESPPreview:Set("HealthBarText", "AnchorPoint", Vector2.new(0, 0))
                        ESPPreview:Set("HealthBarText", "Position", UDim2.new(1, 5, 0, 0))
                    else
                        ESPPreview:Set("HealthBarText", "Visible", Options["Healthbar_Number"])
                        ESPPreview:Set("HealthBarText", "AnchorPoint", Vector2.new(1, 0))
                        ESPPreview:Set("HealthBarText", "Position", UDim2.new(0, -5, 0, 0))
                    end

                    if Options["Healthbar_Position"] == "Top" or Options["Healthbar_Position"] == "Bottom" then
                        ESPPreview:Set("HealthBarText", "Visible", false)
                    end

                    for _,newparent in {ESPPreview.Items.Left, ESPPreview.Items.Top, ESPPreview.Items.Right, ESPPreview.Items.Bottom} do 
                        if newparent.Instance == ESPPreview.Items.HealthBar.Instance.Parent then 
                            local isVertical =  _ % 2 == 1
                            ESPPreview.Items.HealthBar.Instance.Size = isVertical and UDim2.new(0, Options["Healthbar_Thickness"], 1, 0) or UDim2.new(1, 0, 0, Options["Healthbar_Thickness"])
                            ESPPreview.Items.Bar.Instance.Position = isVertical and UDim2.new(0, 1, 0, 1) or UDim2.new(0, 1, 0, 1)
                            ESPPreview.Items.Bar.Instance.Size = isVertical and UDim2.new(0, Options["Healthbar_Thickness"], 1, -2) or UDim2.new(1, -2, 0, Options["Healthbar_Thickness"])
                            ESPPreview.Items.BarGradient.Instance.Rotation = isVertical and -90 or 180
                             
                            return
                        end
                    end

                    for index,value in MiscOptions do 
                        Options[index] = value -- gotta trigger that new index
                    end
                end
            })

            HealthBarToggle:Colorpicker({
                Name = "Low",
                Default = Options["Healthbar_Low"].Color,
                Flag = "Visuals/ESP/HealthbarLow",
                Alpha = 0,
                Callback = function(Value, Alpha)
                    MiscOptions["Healthbar_Low"] = {Color = Value, Transparency = Alpha}

                    Options["Healthbar_Low"] = {Color = Value, Transparency = Alpha}

                    ESPPreview:Set("BarGradient", "Color", ColorSequence.new{ColorSequenceKeypoint.new(0, Value), ColorSequenceKeypoint.new(0.5, Options["Healthbar_Medium"].Color), ColorSequenceKeypoint.new(1, Options["Healthbar_High"].Color)})
                end
            })

            HealthBarToggle:Colorpicker({
                Name = "Medium",
                Default = Options["Healthbar_Medium"].Color,
                Flag = "Visuals/ESP/HealthbarMedium",
                Alpha = 0,
                Callback = function(Value, Alpha)
                    MiscOptions["Healthbar_Medium"] = {Color = Value, Transparency = Alpha}
                    Options["Healthbar_Medium"] = {Color = Value, Transparency = Alpha}
                    ESPPreview:Set("BarGradient", "Color", ColorSequence.new{ColorSequenceKeypoint.new(0, Options["Healthbar_Low"].Color), ColorSequenceKeypoint.new(0.5, Value), ColorSequenceKeypoint.new(1, Options["Healthbar_High"].Color)})
                end
            })

            HealthBarToggle:Colorpicker({
                Name = "High",
                Default = Options["Healthbar_High"].Color,
                Flag = "Visuals/ESP/HealthbarHigh",
                Alpha = 0,
                Callback = function(Value, Alpha)
                    MiscOptions["Healthbar_High"] = {Color = Value, Transparency = Alpha}
                    Options["Healthbar_High"] = {Color = Value, Transparency = Alpha}
                    ESPPreview:Set("BarGradient", "Color", ColorSequence.new{ColorSequenceKeypoint.new(0, Options["Healthbar_Low"].Color), ColorSequenceKeypoint.new(0.5, Options["Healthbar_Medium"].Color), ColorSequenceKeypoint.new(1, Value)})
                end
            })

            PlayersSection:Toggle({
                Name = "Healthbar Tween",
                Flag = "Visuals/ESP/HealthbarTween",
                Default = false,
                Callback = function(Value)
                    MiscOptions["Healthbar_Tween"] = Value
                    Options["Healthbar_Tween"] = Value
                end
            })

            PlayersSection:Dropdown({
                Name = "Tweening style",
                Flag = "Visuals/ESP/HealthbarTweenStyle",
                Default = "Linear",
                Items = {"Linear", "Sine", "Quad", "Cubic", "Quart", "Quint", "Exponential", "Circular", "Back", "Elastic", "Bounce"},
                MaxSize = 150,
                Callback = function(Value)
                    MiscOptions["Healthbar_EasingStyle"] = Value
                    Options["Healthbar_EasingStyle"] = Value
                end
            })

            PlayersSection:Dropdown({
                Name = "Tweening direction",
                Flag = "Visuals/ESP/HealthbarTweenDirection",
                MaxSize = 55,
                Default = "Out",
                Items = {"In", "Out", "InOut"},
                Callback = function(Value)
                    MiscOptions["Healthbar_EasingDirection"] = Value
                    Options["Healthbar_EasingDirection"] = Value
                end
            })

            PlayersSection:Slider({
                Name = "Tweening speed",
                Default = 1,
                Max = 10,
                Minimum = 0,
                Decimals = 0.01,
                Suffix = "s",
                Flag = "Visuals/ESP/HealthbarTweenSpeed",
                Callback = function(Value)
                    MiscOptions["Healthbar_Easing_Speed"] = Value
                    Options["Healthbar_Easing_Speed"] = Value
                end
            })

            PlayersSection:Toggle({
                Name = "Healthbar Number",
                Flag = "Visuals/ESP/HealthbarNumber",
                Default = false,
                Callback = function(Value)
                    MiscOptions["Healthbar_Number"] = Value

                    Options["Healthbar_Number"] = Value

                    for index,value in MiscOptions do 
                        Options[index] = value -- gotta trigger that new index
                    end 

                    ESPPreview:Set("HealthBarText", "Visible", Value)
                end
            })

            PlayersSection:Slider({
                Name = "Healthbar Text Size",
                Flag = "Visuals/ESP/HealthbarTextSize",
                Max = 14,
                Min = 1,
                Default = 11,
                Suffix = "px",
                Decimals = 1,
                Callback = function(Value)
                    MiscOptions["Healthbar_Text_Size"] = Value

                    Options["Healthbar_Text_Size"] = Value

                    ESPPreview:Set("HealthBarText", "TextSize", Value)

                    for index,value in MiscOptions do 
                        Options[index] = value -- gotta trigger that new index
                    end
                end
            })

            PlayersSection:Slider({
                Name = "Healthbar Thickness",
                Flag = "Visuals/ESP/HealthbarThickness",
                Max = 10,
                Min = 1,
                Default = 1,
                Suffix = "px",
                Decimals = 1,
                Callback = function(Value)
                    MiscOptions["Healthbar_Thickness"] = Value

                    Options["Healthbar_Thickness"] = Value

                    ESPPreview:Set("HealthBar", "Size", UDim2.new(0, Value, 1, 0))

                    for _,newparent in {ESPPreview.Items.Left, ESPPreview.Items.Top, ESPPreview.Items.Right, ESPPreview.Items.Bottom} do 
                        if newparent.Instance == ESPPreview.Items.HealthBar.Instance.Parent then 
                            local isVertical =  _ % 2 == 1
                            ESPPreview.Items.HealthBar.Instance.Size = isVertical and UDim2.new(0, Options["Healthbar_Thickness"], 1, 0) or UDim2.new(1, 0, 0, Options["Healthbar_Thickness"])
                            ESPPreview.Items.Bar.Instance.Position = isVertical and UDim2.new(0, 1, 0, 1) or UDim2.new(0, 1, 0, 1)
                            ESPPreview.Items.Bar.Instance.Size = isVertical and UDim2.new(0, Options["Healthbar_Thickness"], 1, -2) or UDim2.new(1, -2, 0, Options["Healthbar_Thickness"])
                            ESPPreview.Items.BarGradient.Instance.Rotation = isVertical and -90 or 180
                             
                            return
                        end
                    end

                    for index,value in MiscOptions do 
                        Options[index] = value -- gotta trigger that new index
                    end 
                end
            })

            PlayersSection:Dropdown({
                Name = "Healthbar Text Font",
                Items = {"ProggyClean", "Tahoma", "Verdana", "SmallestPixel", "ProggyTiny", "Minecraftia", "Tahoma Bold"},
                MaxSize = 200,
                Flag = "Visuals/ESP/HealthbarTextFont",
                Default = "Verdana",
                Multi = false,
                Callback = function(Value)
                    if not Value then Value = "ProggyClean" end
                    MiscOptions["Healthbar_Font"] = Value

                    Options["Healthbar_Font"] = Value

                    ESPPreview:Set("HealthBarText", "FontFace", ESPFonts[Value])

                    for index,value in MiscOptions do 
                        Options[index] = value -- gotta trigger that new index
                    end 
                end
            })

            PlayersSection = Subpages["Player ESP"]:Section({Name = "Players - Info Labels", Side = 2, Icon = Library:GetImage("IdCard")})

            PlayersSection:Toggle({
                Name = "Name",
                Flag = "Visuals/ESP/NameText",
                Default = false,
                Callback = function(Value)
                    MiscOptions["Name_Text"] = Value

                    Options["Name_Text"] = Value

                    ESPPreview:Set("Name", "Visible", Value)

                    for index,value in MiscOptions do 
                        Options[index] = value -- gotta trigger that new index
                    end 
                end
            }):Colorpicker({
                Name = "Name Color",
                Flag = "Visuals/ESP/NameTextColor",
                Default = Color3.fromRGB(255, 255, 255),
                Alpha = 0,
                Callback = function(Value)
                    MiscOptions["Name_Text_Color"] = {Color = Value}
                    Options["Name_Text_Color"] = {Color = Value}

                    ESPPreview:Set("Name", "TextColor3", Value)

                     for index,value in MiscOptions do 
                        Options[index] = value -- gotta trigger that new index
                    end 
                end
            })

            PlayersSection:Dropdown({
                Name = "Name Text Font",
                Items = {"ProggyClean", "Tahoma", "Verdana", "SmallestPixel", "ProggyTiny", "Minecraftia", "Tahoma Bold"},
                MaxSize = 200,
                Flag = "Visuals/ESP/NameTextFont",
                Default = "Verdana",
                Multi = false,
                Callback = function(Value)
                    if not Value then Value = "ProggyClean" end

                    MiscOptions["Name_Text_Font"] = Value
                    Options["Name_Text_Font"] = Value

                    ESPPreview:Set("Name", "FontFace", ESPFonts[Value])

                    for index,value in MiscOptions do 
                        Options[index] = value -- gotta trigger that new index
                    end 
                end
            })

            PlayersSection:Slider({
                Name = "Name Text Size",
                Flag = "Visuals/ESP/NameTextSize",
                Max = 14,
                Min = 1,
                Default = 11,
                Suffix = "px",
                Decimals = 1,
                Callback = function(Value)
                    MiscOptions["Name_Text_Size"] = Value

                    Options["Name_Text_Size"] = Value

                    ESPPreview:Set("Name", "TextSize", Value)

                    for index,value in MiscOptions do 
                        Options[index] = value -- gotta trigger that new index
                    end 
                end
            })

            PlayersSection:Toggle({
                Name = 'Weapon',
                Flag = 'Visuals/ESP/WeaponText',
                Default = false,
                Callback = function(Value)
                    MiscOptions['Weapon_Text'] = Value

                    Options['Weapon_Text'] = Value

                    ESPPreview:Set('WeaponText', 'Visible', Value)

                    for index, value in MiscOptions do
                        Options[index] = value -- gotta trigger that new index
                    end
                end,
            }):Colorpicker({
                Name = 'Weapon Color',
                Flag = 'Visuals/ESP/WeaponTextColor',
                Default = Color3.fromRGB(255, 255, 255),
                Alpha = 0,
                Callback = function(Value)
                    MiscOptions['Weapon_Text_Color'] = { Color = Value }

                    Options['Weapon_Text_Color'] = { Color = Value }

                    ESPPreview:Set('WeaponText', 'TextColor3', Value)
                end,
            })

            PlayersSection:Dropdown({
                Name = 'Weapon Text Font',
                Items = {
                    'ProggyClean',
                    'Tahoma',
                    'Verdana',
                    'SmallestPixel',
                    'ProggyTiny',
                    'Minecraftia',
                    'Tahoma Bold',
                },
                MaxSize = 200,
                Flag = 'Visuals/ESP/WeaponTextFont',
                Default = 'Verdana',
                Multi = false,
                Callback = function(Value)
                    if not Value then
                        Value = 'ProggyClean'
                    end

                    MiscOptions['Weapon_Text_Font'] = Value

                    Options['Weapon_Text_Font'] = Value

                    ESPPreview:Set('WeaponText', 'FontFace', ESPFonts[Value])

                    for index, value in MiscOptions do
                        Options[index] = value -- gotta trigger that new index
                    end
                end,
            })

            PlayersSection:Slider({
                Name = 'Weapon Text Size',
                Flag = 'Visuals/ESP/WeaponTextSize',
                Max = 14,
                Min = 1,
                Default = 11,
                Suffix = 'px',
                Decimals = 1,
                Callback = function(Value)
                    MiscOptions['Weapon_Text_Size'] = Value

                    Options['Weapon_Text_Size'] = Value

                    ESPPreview:Set('WeaponText', 'TextSize', Value)

                    for index, value in MiscOptions do
                        Options[index] = value -- gotta trigger that new index
                    end
                end,
            })

            PlayersSection:Dropdown({
                Name = 'Weapon Side',
                Items = { 'Top', 'Bottom', 'Left', 'Right' },
                MaxSize = 200,
                Flag = 'Visuals/ESP/WeaponTextSide',
                Default = 'Bottom',
                Multi = false,
                Callback = function(Value)
                    if not Value then
                        Value = 'Left'
                    end

                    MiscOptions['Weapon_Text_Position'] = Value
                    Options['Weapon_Text_Position'] = Value

                    ESPPreview:Set('WeaponText', 'Parent', ESPPreview.Items[Value].Instance)

                    for index, value in MiscOptions do
                        Options[index] = value -- gotta trigger that new index
                    end
                end,
            })

            PlayersSection:Toggle({
                Name = "Distance",
                Flag = "Visuals/ESP/DistanceText",
                Default = false,
                Callback = function(Value)
                    MiscOptions["Distance_Text"] = Value

                    Options["Distance_Text"] = Value

                    ESPPreview:Set("Distance", "Visible", Value)

                    for index,value in MiscOptions do 
                        Options[index] = value -- gotta trigger that new index
                    end 
                end
            }):Colorpicker({
                Name = "Distance Color",
                Flag = "Visuals/ESP/DistanceTextColor",
                Default = Color3.fromRGB(255, 255, 255),
                Alpha = 0,
                Callback = function(Value)
                    MiscOptions["Distance_Text_Color"] = {Color = Value}

                    Options["Distance_Text_Color"] = {Color = Value}

                    ESPPreview:Set("Distance", "TextColor3", Value)
                end
            })

            PlayersSection:Dropdown({
                Name = "Distance Text Font",
                Items = {"ProggyClean", "Tahoma", "Verdana", "SmallestPixel", "ProggyTiny", "Minecraftia", "Tahoma Bold"},
                MaxSize = 200,
                Flag = "Visuals/ESP/DistanceTextFont",
                Default = "Verdana",
                Multi = false,
                Callback = function(Value)
                    if not Value then Value = "ProggyClean" end

                    MiscOptions["Distance_Text_Font"] = Value

                    Options["Distance_Text_Font"] = Value

                    ESPPreview:Set("Distance", "FontFace", ESPFonts[Value])

                    for index,value in MiscOptions do 
                        Options[index] = value -- gotta trigger that new index
                    end 
                end
            })

            PlayersSection:Slider({
                Name = "Distance Text Size",
                Flag = "Visuals/ESP/DistanceTextSize",
                Max = 14,
                Min = 1,
                Default = 11,
                Suffix = "px",
                Decimals = 1,
                Callback = function(Value)
                    MiscOptions["Distance_Text_Size"] = Value

                    Options["Distance_Text_Size"] = Value

                    ESPPreview:Set("Distance", "TextSize", Value)

                    for index,value in MiscOptions do 
                        Options[index] = value -- gotta trigger that new index
                    end 
                end
            })

            PlayersSection:Dropdown({
                Name = "Distance Side",
                Items = {"Top", "Bottom", "Left", "Right"},
                MaxSize = 200,
                Flag = "Visuals/ESP/DistanceTextSide",
                Default = "Bottom",
                Multi = false,
                Callback = function(Value)
                    if not Value then Value = "Left" end

                    MiscOptions["Distance_Text_Position"] = Value
                    Options["Distance_Text_Position"] = Value

                    ESPPreview:Set("Distance", "Parent", ESPPreview.Items[Value].Instance)
                    
                    for index,value in MiscOptions do 
                        Options[index] = value -- gotta trigger that new index
                    end 
                end
            })

            PlayersSection:Slider({
                Name = "Max Render Distance",
                Flag = "Visuals/ESP/MaxRenderDistance",
                Max = 5000,
                Min = 50,
                Default = 500,
                Suffix = "m",
                Decimals = 1,
                Callback = function(Value)
                    MiscOptions["Render_Distance"] = Value
                end
            })

            local Ambient_Section = Subpages["World"]:Section({Name = "Ambient Utilities", Side = 1, Icon = Library:GetImage("Cloud")})

            Ambient_Section:Toggle({Name = "Enabled", Flag = "SouthBronx/Visuals/Ambient/Enabled", Callback = function(State)
                Config.WorldVisuals.AmbientEnabled = State
            end})

            Ambient_Section:Label("Color"):Colorpicker({
                Name = "Ambient Color",
                Flag = "SouthBronx/Visuals/Ambient/Color",
                Default = Color3.fromRGB(255, 255, 255),
                Alpha = 0,
                Callback = function(Value)
                    Config.WorldVisuals.AmbientColor = Value
                end
            })

            local Saturation_Section = Subpages["World"]:Section({Name = "Saturation Utilities", Side = 1, Icon = Library:GetImage("Contrast")})

            Saturation_Section:Toggle({Name = "Enabled", Flag = "SouthBronx/Visuals/Saturation/Enabled", Callback = function(State)
                Config.WorldVisuals.SaturationEnabled = State
            end})
            
            Saturation_Section:Slider({
                Name = "Saturation Increase Value",
                Flag = "SouthBronx/Visuals/Saturation/Value",
                Max = 200,
                Min = 0,
                Default = 50,
                Suffix = "%",
                Decimals = 1,
                Callback = function(Value)
                    Config.WorldVisuals.Saturation_Value = Value/100
                end
            })
    
            local FieldOfView_Section = Subpages["World"]:Section({Name = "Field Of View Utilities", Side = 1, Icon = Library:GetImage("EyeTracking")})

            FieldOfView_Section:Toggle({Name = "Enabled", Flag = "SouthBronx/Visuals/FieldOfView/Enabled", Callback = function(State)
                Config.WorldVisuals.FieldOfViewEnabled = State
            end})
            
            FieldOfView_Section:Slider({
                Name = "Field Of View Value",
                Flag = "SouthBronx/Visuals/FieldOfView/Value",
                Max = 120,
                Min = 0,
                Default = 70,
                Suffix = "°",
                Decimals = 1,
                Callback = function(Value)
                    Config.WorldVisuals.FieldOfViewValue = Value
                end
            })

            local Tracers_Section = Subpages["World"]:Section({Name = "Tracer Utilities", Side = 2, Icon = Library:GetImage("TrailShort")})

            Tracers_Section:Toggle({Name = "Enabled", Flag = "SouthBronx/Tracers/Enabled", Callback = function(State)
                Config.Tracers.Enabled = State
            end})

            local Tracer_Label = Tracers_Section:Label("Tracer Colors")

            Tracer_Label:Colorpicker({
                Name = "Start Color",
                Flag = "Visuals/Tracers/Color1",
                Default = Color3.fromRGB(255, 85, 0),
                Alpha = 0,
                Callback = function(Value)
                    Config.Tracers.StartColor = Value
                end
            })

            Tracer_Label:Colorpicker({
                Name = "End Color",
                Flag = "Visuals/Tracers/Color2",
                Default = Color3.fromRGB(0, 0, 0),
                Alpha = 0,
                Callback = function(Value)
                    Config.Tracers.EndColor = Value
                end
            })

            Tracers_Section:Slider({
                Name = "Tracer Duration",
                Flag = "Visuals/Tracers/Duration",
                Max = 10,
                Min = 0,
                Default = 3,
                Suffix = "s",
                Decimals = 0.1,
                Callback = function(Value)
                    Config.Tracers.Duration = Value
                end
            })

            Tracers_Section:Toggle({Name = "Rainbow", Flag = "SouthBronx/Tracers/Rainbow", Callback = function(State)
                Config.Tracers.Rainbow = State
            end})

            local Stretched_Res_Section = Subpages["World"]:Section({Name = "Stretched Resolution Utilities", Side = 2, Icon = Library:GetImage("ScreenRotation")})

            Stretched_Res_Section:Toggle({Name = "Enabled", Flag = "SouthBronx/Stretch/Enabled", Tooltip = "This will mess with south bronx's aiming system.", Callback = function(State)
                Config.WorldVisuals.StretchEnabled = State
            end})

            Stretched_Res_Section:Slider({
                Name = "Stretch Value",
                Flag = "Visuals/Stretch/Value",
                Max = 1,
                Min = 0,
                Default = 0.7,
                Suffix = "",
                Decimals = 0.01,
                Callback = function(Value)
                    Config.WorldVisuals.StretchValue = Value
                end
            })

            local Fullbright_Section = Subpages["World"]:Section({Name = "Fullbright Utilities", Side = 2, Icon = Library:GetImage("LightBulb")})

            Fullbright_Section:Toggle({Name = "Enabled", Flag = "SouthBronx/Fullbright/Enabled", Callback = function(State)
                Config.WorldVisuals.Fullbright = State
            end})
        end

        do -- Main
            local Subpages = {
                ["Player"] = Pages["Main"]:SubPage({
                    Name = "Player", 
                    Icon = Library:GetImage("AccountCircle"), 
                    Columns = 2
                }),
                ["Players"] = Pages["Main"]:SubPage({
                    Name = "Other Players", 
                    Icon = Library:GetImage("DeployedCodeAccount"), 
                    Columns = 2
                }),
                ["Teleports"] = Pages["Main"]:SubPage({
                    Name = "Teleports", 
                    Icon = Library:GetImage("TravelExplore"), 
                    Columns = 2
                }),
                ["Money"] = Pages["Main"]:SubPage({
                    Name = "Money", 
                    Icon = Library:GetImage("MoneySymbol"), 
                    Columns = 2
                }),
                ["Vehicles"] = Pages["Main"]:SubPage({
                    Name = "Vehicles", 
                    Icon = Library:GetImage("Scrambler"), 
                    Columns = 2
                }),
            }

            do -- Player
                do -- Teleportation
                    local Teleportation_Utilites_Section = Subpages.Teleports:Section({Name = "Teleportation Utilities", Icon = Library:GetImage("JumpToElement"), Side = 1})

                    Teleportation_Utilites_Section:Dropdown({Name = "Select Location", Items = Location_Name, MaxSize = 200, Flag = "Select_Location_Teleport", Multi = false})

                    Teleportation_Utilites_Section:Button({Name = "Teleport To Selected Location", Callback = function()
                        if not Library.Flags.Select_Location_Teleport then return end

                        if Library.Flags.Select_Location_Teleport ~= "Dirty Hobo 💩" and Library.Flags.Select_Location_Teleport ~= "Active ATM 🏧" and Library.Flags.Select_Location_Teleport ~= "Personal Apartment 🏠" and Library.Flags.Select_Location_Teleport ~= "Robbable Vehicle 🚗" then
                            Config:Teleport(Locations[Library.Flags.Select_Location_Teleport])
                        elseif Library.Flags.Select_Location_Teleport == "Robbable Vehicle 🚗" then
                            local Robbable_Vehicle = Config.GetRobbableVehicle()

                            if not Robbable_Vehicle then
                                return Library:Notification({
                                    Name = "Valary.gg | Teleportation",
                                    Description = "Couldn't find robbable vehicle!",
                                    Duration = 7.5
                                })
                            end
                            
                            if Robbable_Vehicle then
                                Config:Teleport(Robbable_Vehicle.WindowBreak.CFrame)
                            end
                        elseif Library.Flags.Select_Location_Teleport == "Personal Apartment 🏠" then
                            local Apartment = Config.GetPersonalApartment()

                            if not Apartment then
                                return Library:Notification({
                                    Name = "Valary.gg | Teleportation",
                                    Description = "Couldn't find your apartment!",
                                    Duration = 7.5
                                })
                            end

                            if Apartment then
                                Config:Teleport(Apartment.Board.backboard.CFrame)
                            end
                        elseif Library.Flags.Select_Location_Teleport == "Dirty Hobo 💩" then
                            local _Hobo = Config.GetHobo()
                            if not _Hobo then
                                return Library:Notification({
                                    Name = "Valary.gg | Teleportation",
                                    Description = "Couldn't find a hobo!",
                                    Duration = 7.5
                                })
                            end
                            Config:Teleport(_Hobo.HumanoidRootPart.CFrame)
                        elseif Library.Flags.Select_Location_Teleport == "Active ATM 🏧" then
                            local ATMPositions = {
                                ATM1 = CFrame.new(-30, 4, -300);
                                ATM2 = CFrame.new(539, 4, -353);
                                ATM3 = CFrame.new(497, 4, 403);
                                ATM4 = CFrame.new(236, 4, -158);
                                ATM5 = CFrame.new(525, -8, -92);
                                ATM6 = CFrame.new(-450, 4, 370);
                                ATM7 = CFrame.new(-266, 4, -209);
                                ATM8 = CFrame.new(-11, 4, 231);
                                ATM9 = CFrame.new(717, 4, 410);
                                ATM10 = CFrame.new(-532, 3, -21);
                                ATM11 = CFrame.new(-646, 4, 155);
                                ATM12 = CFrame.new(698, 3, -241);
                                ATM13 = CFrame.new(-315, 4, 142);
                                ATM14 = CFrame.new(-378, 4, -365);
                                ATM15 = CFrame.new(360, 4, -364);
                                ATM16 = CFrame.new(870, 3, -346);
                                ATM17 = CFrame.new(904, 3, -99);
                                ATM18 = CFrame.new(1095, 3, 178);
                                ATM19 = CFrame.new(1054, 4, 585);
                                ATM20 = CFrame.new(895, 4, 142);
                                ATM21 = CFrame.new(1021, 3, -229);
                            };

                            local ATM;

                            for Index, Value in Workspace.Map.ATMS:GetChildren() do
                                if Value.ATMScreen.Transparency == 0 then
                                    ATM = Value
                                    break
                                end
                            end

                            Config:Teleport(ATMPositions[tostring(ATM)])
                        end
                    end})
                end

                do -- Purchasing
                    local Purchasing_Utilites_Section = Subpages.Teleports:Section({Name = "Purchasing Utilities", Icon = Library:GetImage("CreditCard"), Side = 2})

                    Purchasing_Utilites_Section:Dropdown({Name = "Select Item", Items = Config.South_Bronx.Guns, MaxSize = 200, Flag = "Select_Item_To_Buy", Multi = false})
                
                    Purchasing_Utilites_Section:Slider({
                        Name = "Amount To Purchase",
                        Flag = "Amount_To_Purchase",
                        Max = 30,
                        Min = 1,
                        Default = 1,
                        Suffix = "",
                        Decimals = 1
                    })

                    Purchasing_Utilites_Section:Button({Name = "Purchase Selected Item", Callback = function()
                        if not Library.Flags.Select_Item_To_Buy then return end

                        local self = string.match(Library.Flags.Select_Item_To_Buy, "^(.*) %-");

                        local DidntBuy = false
                            
                        local Success, Error = pcall(function()
                            self = self:match("^%s*(.-)%s*$");

                            local PromptCFrame = Gun_Locations[self];
                            local OldCFrame = LocalPlayer.Character.HumanoidRootPart.CFrame

                            local ChildAdded_Check; ChildAdded_Check = LocalPlayer.Backpack.ChildAdded:Connect(function(Child)
                                if Child.Name == self then
                                    ItemReceieved = true
                                    DidntBuy = false

                                    ChildAdded_Check:Disconnect();
                                end
                            end)

                            Config:Teleport(PromptCFrame)

                            task.wait(1.5)

                            task.delay(3, function()
                                if not ItemReceieved then
                                    ItemReceieved = true
                                    DidntBuy = true
                                end
                            end)

                            for Index = 1, Library.Flags.Amount_To_Purchase do
                                fireproximityprompt(Workspace.Folders:FindFirstChild("PromptPurchases")[self].proxprompt:FindFirstChildOfClass("ProximityPrompt"))
                            end

                            repeat RunService.RenderStepped:Wait() until ItemReceieved == true

                            task.wait(0.5)

                            Config:Teleport(OldCFrame)
                        end)

                        if not LocalPlayer.Backpack:FindFirstChild(self) and not LocalPlayer.Character:FindFirstChild(self) then
                            Library:Notification({
                                Name = "Valary.gg | Bug",
                                Description = string.format("Failed to purchase item %s", self),
                                Duration = 7.5
                            })

                            return
                        end

                        if DidntBuy then
                            if Success then
                                Library:Notification({
                                    Name = "Valary.gg | Bug",
                                    Description = string.format("Failed to purchase item %s", self),
                                    Duration = 7.5
                                })
                            else
                                Library:Notification({
                                    Name = "Valary.gg | Error",
                                    Description = string.format("Failed to purchase item %s . error : %s", self, Error),
                                    Duration = 10
                                })
                            end
                        else
                            if Library.Flags.Amount_To_Purchase > 1 then
                                self..="s"
                            end

                            Library:Notification({
                                Name = "Valary.gg | Purchasing",
                                Description = string.format('Successfully purchased %s %s!', tostring(Library.Flags.Amount_To_Purchase), self),
                                Duration = 5
                            })
                        end
                    end})
                end

                do -- Apartment Teleports
                    local Apartment_Teleports_Section = Subpages.Teleports:Section({Name = "Apartment Teleports", Icon = Library:GetImage("Apartment"), Side = 2})

                    local SelectApartment_Dropdown = Apartment_Teleports_Section:Dropdown({Name = "Select Apartment", Flag = "Select_Apartment_Teleport", Items = {}, Multi = false, MaxSize = 150})

                    Apartment_Teleports_Section:Button({Name = "Teleport To Selected Apartment", Callback = function()
                        if not Library.Flags.Select_Apartment_Teleport then
                            return
                        end

                        for Index, Value in Workspace.Map.APTS:GetChildren() do
                            if Value.Board.name.SurfaceGui.TextLabel.Text == tostring(Library.Flags.Select_Apartment_Teleport:gsub("'s Apartment", "")) then
                                Config:Teleport(Value.Board.backboard.CFrame)

                                break
                            end
                        end
                    end})

                    --[[Apartment_Teleports_Section:Button({Name = "Refresh List", Callback = function()
                        local Apartments = {}

                        for Index, Value in Workspace.Map.APTS:GetChildren() do
                            if Value.Board.name.SurfaceGui.TextLabel.Text ~= "VACANT" then
                                table.insert(Apartments, Value.Board.name.SurfaceGui.TextLabel.Text.."'s Apartment")
                            end
                        end

                        SelectApartment_Dropdown:Refresh(Apartments)
                    end})]]

                    do -- Refresh
                        local Apartments = {}

                        for Index, Value in Workspace.Map.APTS:GetChildren() do
                            if Value.Board.name.SurfaceGui.TextLabel.Text ~= "VACANT" then
                                table.insert(Apartments, Value.Board.name.SurfaceGui.TextLabel.Text.."'s Apartment")
                            end
                        end

                        SelectApartment_Dropdown:Refresh(Apartments)

                        for Index, Value in Workspace.Map.APTS:GetChildren() do
                            Value.Board.name.SurfaceGui.TextLabel:GetPropertyChangedSignal("Text"):Connect(LPH_NO_VIRTUALIZE(function()
                                task.wait(.1)
                                
                                local Apartments = {}

                                for Index, Value in Workspace.Map.APTS:GetChildren() do
                                    if Value.Board.name.SurfaceGui.TextLabel.Text ~= "VACANT" then
                                        table.insert(Apartments, Value.Board.name.SurfaceGui.TextLabel.Text.."'s Apartment")
                                    end
                                end

                                SelectApartment_Dropdown:Refresh(Apartments)
                            end))
                        end
                    end
                end

                do -- Waypoint Teleports
                    if not isfolder("valary/Waypoints") then
                        makefolder("valary/Waypoints")
                    end

                    Config.ToVector3 = LPH_NO_VIRTUALIZE(function(Self, String)                    
                        local axes = {}
                    
                        for axis in String:gmatch('[^'..','..']+') do
                            axes[#axes + 1] = axis
                        end
                    
                        return Vector3.new(axes[1], axes[2], axes[3])
                    end)

                    local WayPoint_Teleport_Section = Subpages.Teleports:Section({Name = "Waypoint Teleports", Icon = Library:GetImage("Cyclone"), Side = 1})

                    local WaypointDropdown = WayPoint_Teleport_Section:Dropdown({Name = "Select Waypoint", Items = {}, MaxSize = 165, Flag = "SouthBronx/SelectWaypoint"})
                    WayPoint_Teleport_Section:Textbox({Name = "Waypoint Name", Placeholder = "type here...", Flag = "SouthBronx/WaypointName"})

                    WayPoint_Teleport_Section:Button({Name = "Go-To Waypoint", Callback = function()
                        if Library.Flags['SouthBronx/SelectWaypoint'] then
                            if readfile("valary/Waypoints/"..Library.Flags['SouthBronx/SelectWaypoint']..".txt") then
                                Config:Teleport(CFrame.new( Config:ToVector3( readfile("valary/Waypoints/"..Library.Flags['SouthBronx/SelectWaypoint']..".txt") ) ))
                            end
                        end
                    end})

                    WayPoint_Teleport_Section:Button({Name = "Save Waypoint", Tooltip = "Stand wherever you want the waypoint to be.", Callback = function()
                        if Library.Flags["SouthBronx/WaypointName"] and Library.Flags["SouthBronx/WaypointName"] ~= "" then
                            writefile("valary/Waypoints/"..Library.Flags["SouthBronx/WaypointName"]..".txt", tostring(LocalPlayer.Character.HumanoidRootPart.CFrame))
                        end
                    end})

                    WayPoint_Teleport_Section:Button({Name = "Delete Waypoint", Callback = function()
                        if Library.Flags['SouthBronx/SelectWaypoint'] then
                            if readfile("valary/Waypoints/"..Library.Flags['SouthBronx/SelectWaypoint']..".txt") then
                                delfile("valary/Waypoints/"..Library.Flags['SouthBronx/SelectWaypoint']..".txt")
                            end
                        end
                    end})

                    Config.RefreshWaypoints = LPH_NO_VIRTUALIZE(function()
                        local files = listfiles("valary/Waypoints")

                        local names = {}

                        for _, file in ipairs(files) do
                            local name = file:match("([^/\\]+)%.txt$")

                            if file then
                                table.insert(names, name)
                            end
                        end

                        WaypointDropdown:Refresh(names)
                    end)

                    Config:RefreshWaypoints()

                    task.spawn(LPH_NO_VIRTUALIZE(function()
                        local lastFiles = {}

                        while task.wait(0.1) do
                            local files = listfiles("valary/Waypoints")

                            if #files ~= #lastFiles then
                                Config:RefreshWaypoints()
                            end

                            lastFiles = files
                        end
                    end))
                end

                do -- Other Players
                    local Get_Children_String = LPH_NO_VIRTUALIZE(function(Object, Type)
                        local _table = {}

                        for Index, Value in Object:GetChildren() do
                            if not Type then
                                table.insert(_table, Value.Name)
                            else
                                if not Value:IsA(Type) then continue end

                                table.insert(_table, Value.Name)
                            end
                        end

                        table.sort(_table)

                        return _table
                    end)

                    local SelectedPlayer_Section = Subpages["Players"]:Section({Name = "Selected Player Info", Icon = Library:GetImage("DataLossPrevention"), Side = 2})
                    
                    local NameLabel = SelectedPlayer_Section:Label("Selected Player : None")
                    --local UserId_Label = SelectedPlayer_Section:Label("User Id : None")
                    local Inventory_Label = SelectedPlayer_Section:Label("Inventory : N/A", true)

                    task.spawn(LPH_NO_VIRTUALIZE(function()
                        while task.wait(.1) do
                            if Library.Selected_Player then
                                NameLabel:SetText(string.format("Selected Player : @%s", Library.Selected_Player.Name))
                                --UserId_Label:SetText(string.format("User Id : %s", Library.Selected_Player.UserId))

                                if Library.Selected_Player:FindFirstChild("Backpack") then
                                    local Items = Get_Children_String(Library.Selected_Player:FindFirstChild("Backpack"), "Tool")

                                    if Items then
                                        Inventory_Label:SetText(string.format("Inventory : %s", table.concat(Items, ", ")))
                                    else
                                        Inventory_Label:SetText("Inventory : N/A")
                                    end
                                else
                                    Inventory_Label:SetText("Inventory : N/A")
                                end
                            else
                                NameLabel:SetText("Selected Player : None")
                                --UserId_Label:SetText("User Id : None")
                                Inventory_Label:SetText("Inventory : N/A")
                            end
                        end
                    end))

                    local SelectedPlayer_Section = Subpages["Players"]:Section({Name = "Selected Player Utilities", Icon = Library:GetImage("IdentityPlatform"), Side = 1})

                    SelectedPlayer_Section:Button({Name = "Teleport To Selected Player", Callback = function()
                        if Library.Selected_Player and Library.Selected_Player.Character and Library.Selected_Player.Character:FindFirstChild("HumanoidRootPart") then
                            Config:Teleport(Library.Selected_Player.Character:FindFirstChild("HumanoidRootPart").CFrame)
                        end
                    end})

                    SelectedPlayer_Section:Button({Name = "Teleport To Selected Player's Vehicle", Callback = function()
                        if Library.Selected_Player and Workspace:FindFirstChild(string.format("%s's Car", Library.Selected_Player.Name)) then
                            local Car = Workspace:FindFirstChild(string.format("%s's Car", Library.Selected_Player.Name))
                            
                            if not Car:FindFirstChildWhichIsA("Part", true) then
                                return Library:Notification({
                                    Name = "Valary.gg | Teleportation",
                                    Description = "Car could not be teleported to!",
                                    Duration = 7.5,
                                    Icon = "97118059177470",
                                    IconColor = Color3.fromRGB(255, 120, 120)
                                })
                            end

                            Config:Teleport(Car:FindFirstChildWhichIsA("Part", true).CFrame + Vector3.new(0,5,0))
                        else
                            return Library:Notification({
                                Name = "Valary.gg | Error",
                                Description = "This player or their car was not found!",
                                Duration = 7.5,
                                Icon = "97118059177470",
                                IconColor = Color3.fromRGB(255, 120, 120)
                            })
                        end
                    end})

                    SelectedPlayer_Section:Button({Name = "Kill Selected Player - Hold Gun", Callback = function()
                        if not Library.Selected_Player or not Library.Selected_Player.Character or not Library.Selected_Player.Character:FindFirstChild("HumanoidRootPart") then
                            return
                        end

                        if (LocalPlayer.Character.HumanoidRootPart.Position - Library.Selected_Player.Character:FindFirstChild("HumanoidRootPart").Position).Magnitude > 374 then
                            return Library:Notification({
                                Name = "Valary.gg | Error",
                                Description = 'Player must be within 375 studs!',
                                Duration = 7.5
                            })
                        end
                        
                        local Gun =  Config.GetGun()

                        if Config.InsideSafezone(Library.Selected_Player) then
                            return Library:Notification({
                                Name = "Valary.gg | Error",
                                Description = 'Player is inside a safezone!',
                                Duration = 7.5
                            })
                        end
                        
                        if Library.Selected_Player and Library.Selected_Player.Character and Library.Selected_Player.Character:FindFirstChild("HumanoidRootPart") then
                            local Start = tick()

                            repeat task.wait(0.01)
                                Config:ShootPlayer(Library.Selected_Player.Name)
                            until (tick() - Start) >= 3 or not Library.Selected_Player or not Library.Selected_Player.Character or not Library.Selected_Player.Character:FindFirstChild("Humanoid") or Library.Selected_Player.Character:FindFirstChild("Humanoid").Health == 0
                            
                            if (tick() - Start) >= 3 then
                                return Library:Notification({
                                    Name = "Valary.gg | Error",
                                    Description = "Couldn't kill player, most likely behind walls!",
                                    Duration = 7.5
                                })
                            end
                        end
                    end})

                    SelectedPlayer_Section:Dropdown({
                        Name = "Select Body Parts",
                        Flag = "Select_BodyParts_Modifications",
                        Items = {
                            "Head",
                            "Hair",
                            "UpperTorso",
                            "LowerTorso",
                            "LeftUpperArm",
                            "LeftLowerArm",
                            "RightUpperArm",
                            "RightLowerArm",
                            "LeftUpperLeg",
                            "LeftLowerLeg",
                            "RightUpperLeg",
                            "RightLowerLeg",
                            --"HumanoidRootPart"
                        },
                        Default = {"Head", "Hair"},
                        Multi = true,
                        MaxSize = 200
                    })

                    SelectedPlayer_Section:Slider({Name = "Transparency Value", Min = 0, Max = 1, Default = 0.5, Flag = "Transparency_Value_Modification", Decimals = 0.01})

                    SelectedPlayer_Section:Button({Name = "Apply Transparency", Callback = function()
                        if not Library.Selected_Player then
                            return Library:Notification({
                                Name = "Valary.gg | Error",
                                Description = "Could not find target!",
                                Duration = 7.5,
                            })
                        end

                        if not Library.Selected_Player.Character then
                            return Library:Notification({
                                Name = "Valary.gg | Error",
                                Description = "Could not find targets character!",
                                Duration = 7.5,
                            })
                        end

                        if not Workspace:FindFirstChild(string.format("%s's Car", LocalPlayer.Name)) then
                            return Library:Notification({
                                Name = "Valary.gg | Error",
                                Description = "Could not find your car! (Need Nissan GTR)",
                                Duration = 7.5,
                            })
                        end

                        if Workspace:FindFirstChild(string.format("%s's Car", LocalPlayer.Name)):GetAttribute("Car") ~= "Nissan GTR" then
                            return Library:Notification({
                                Name = "Valary.gg | Error",
                                Description = "Your car must be a Nissan GTR for this to work!",
                                Duration = 7.5,
                            })
                        end

                        for Index, Value in Library.Selected_Player.Character:GetChildren() do
                            if table.find(Library.Flags.Select_BodyParts_Modifications, Value.Name) or (Value.Name == "Ears" and table.find(Library.Flags.Select_BodyParts_Modifications, "Head")) then
                                pcall(function()
                                    FireServer(Workspace:FindFirstChild(string.format("%s's Car", LocalPlayer.Name)):FindFirstChild("Lights_FE"),
                                        "UpdateLight",
                                        Value,
                                        Value.Material,
                                        Value.BrickColor,
                                        Library.Flags.Transparency_Value_Modification,
                                        false,
                                        15
                                    )
                                end)
                            end
                        end
                    end})

                    SelectedPlayer_Section:Button({Name = "Fully Apply Transparency", Callback = function()
                        if not Library.Selected_Player then
                            return Library:Notification({
                                Name = "Valary.gg | Error",
                                Description = "Could not find target!",
                                Duration = 7.5,
                            })
                        end

                        if not Library.Selected_Player.Character then
                            return Library:Notification({
                                Name = "Valary.gg | Error",
                                Description = "Could not find targets character!",
                                Duration = 7.5,
                            })
                        end

                        if not Workspace:FindFirstChild(string.format("%s's Car", LocalPlayer.Name)) then
                            return Library:Notification({
                                Name = "Valary.gg | Error",
                                Description = "Could not find your car!",
                                Duration = 7.5,
                            })
                        end

                        if Workspace:FindFirstChild(string.format("%s's Car", LocalPlayer.Name)):GetAttribute("Car") ~= "Nissan GTR" then
                            return Library:Notification({
                                Name = "Valary.gg | Error",
                                Description = "Your car must be a GTR for this to work!",
                                Duration = 7.5,
                            })
                        end

                        for Index, Value in Library.Selected_Player.Character:GetDescendants() do
                            if Value.Name ~= "HumanoidRootPart" then
                                pcall(function()
                                    FireServer(Workspace:FindFirstChild(string.format("%s's Car", LocalPlayer.Name)):FindFirstChild("Lights_FE"),
                                        "UpdateLight",
                                        Value,
                                        Value.Material,
                                        Value.BrickColor,
                                        Library.Flags.Transparency_Value_Modification,
                                        false,
                                        15
                                    )
                                end)
                            end
                        end
                    end})

                    SelectedPlayer_Section:Dropdown({
                        Name = "Select Material",
                        Flag = "Select_Materials_Modifications",
                        Items = {
                            "Fabric",       -- cloth-like look
                            "ForceField",   -- glowing forcefield effect
                            "Glass",        -- transparent / shiny
                            "Ice",          -- frosty, semi-transparent
                            "Marble",       -- polished stone
                            "Metal",        -- shiny and reflective
                            "Neon",         -- glowing neon
                            "Plastic",      -- smooth base
                            "Slate",        -- rough stone
                            "SmoothPlastic",-- very clean/smooth
                            "Wood",         -- natural wood
                            "WoodPlanks"    -- wooden panel look
                        },
                        Default = "ForceField",
                        Multi = false,
                        MaxSize = 200
                    })

                    SelectedPlayer_Section:Button({Name = "Apply Material", Callback = function()
                        if not Library.Selected_Player then
                            return Library:Notification({
                                Name = "Valary.gg | Error",
                                Description = "Could not find target!",
                                Duration = 7.5,
                            })
                        end

                        if not Library.Selected_Player.Character then
                            return Library:Notification({
                                Name = "Valary.gg | Error",
                                Description = "Could not find targets character!",
                                Duration = 7.5,
                            })
                        end

                        if not Workspace:FindFirstChild(string.format("%s's Car", LocalPlayer.Name)) then
                            return Library:Notification({
                                Name = "Valary.gg | Error",
                                Description = "Could not find your car! (Need Nissan GTR)",
                                Duration = 7.5,
                            })
                        end

                        if Workspace:FindFirstChild(string.format("%s's Car", LocalPlayer.Name)):GetAttribute("Car") ~= "Nissan GTR" then
                            return Library:Notification({
                                Name = "Valary.gg | Error",
                                Description = "Your car must be a Nissan GTR for this to work!",
                                Duration = 7.5,
                            })
                        end

                        for Index, Value in Library.Selected_Player.Character:GetChildren() do
                            if table.find(Library.Flags.Select_BodyParts_Modifications, Value.Name) or (Value.Name == "Ears" and table.find(Library.Flags.Select_BodyParts_Modifications, "Head")) then
                                pcall(function()
                                    FireServer(Workspace:FindFirstChild(string.format("%s's Car", LocalPlayer.Name)):FindFirstChild("Lights_FE"),
                                        "UpdateLight",
                                        Value,
                                        Enum.Material[Library.Flags.Select_Materials_Modifications],
                                        Value.BrickColor,
                                        Value.Transparency,
                                        false,
                                        15
                                    )
                                end)
                            end
                        end
                    end})

                    SelectedPlayer_Section:Button({Name = "Fully Apply Material", Callback = function()
                        if not Library.Selected_Player then
                            return Library:Notification({
                                Name = "Valary.gg | Error",
                                Description = "Could not find target!",
                                Duration = 7.5,
                            })
                        end

                        if not Library.Selected_Player.Character then
                            return Library:Notification({
                                Name = "Valary.gg | Error",
                                Description = "Could not find targets character!",
                                Duration = 7.5,
                            })
                        end

                        if not Workspace:FindFirstChild(string.format("%s's Car", LocalPlayer.Name)) then
                            return Library:Notification({
                                Name = "Valary.gg | Error",
                                Description = "Could not find your car!",
                                Duration = 7.5,
                            })
                        end

                        if Workspace:FindFirstChild(string.format("%s's Car", LocalPlayer.Name)):GetAttribute("Car") ~= "Nissan GTR" then
                            return Library:Notification({
                                Name = "Valary.gg | Error",
                                Description = "Your car must be a GTR for this to work!",
                                Duration = 7.5,
                            })
                        end

                        for Index, Value in Library.Selected_Player.Character:GetDescendants() do
                            if Value.Name ~= "HumanoidRootPart" then
                                pcall(function()
                                    FireServer(Workspace:FindFirstChild(string.format("%s's Car", LocalPlayer.Name)):FindFirstChild("Lights_FE"),
                                        "UpdateLight",
                                        Value,
                                        Enum.Material[Library.Flags.Select_Materials_Modifications],
                                        Value.BrickColor,
                                        Value.Transparency,
                                        false,
                                        15
                                    )
                                end)
                            end
                        end
                    end})

                    local SkinChanging_Utility = Subpages.Players:Section({Name = "Skin Changing Utilities", Icon = Library:GetImage("Wrist"), Side = 2})

                    local BrickColors = {
                        "Institutional white",  -- Very pale
                        "Pastel brown",         -- Fair skin
                        "Light orange",         -- Light skin
                        "Brick yellow",         -- Beige
                        "Earth orange",         -- Light tan
                        "Medium yellowish brown", -- Tan
                        "Dark orange",          -- Medium brown
                        "Reddish brown",        -- Dark brown
                        "Brown",                -- Deep brown
                        "Black",

                        -- Basic custom colors
                        "Bright red",
                        "Bright blue",
                        "Bright green",
                        "Bright yellow",
                        "Bright orange",
                        "Bright violet",
                        "Pink"
                    }

                    if not table.find(BrickColors, tostring(LocalPlayer.Character.Head.BrickColor)) then
                        table.insert(BrickColors, tostring(LocalPlayer.Character.Head.BrickColor))
                    end

                    table.sort(BrickColors)

                    SkinChanging_Utility:Dropdown({
                        Name = "Select Skin Color",
                        Flag = "Select_SkinColor_Modifications",
                        Items = BrickColors,
                        Default = tostring(LocalPlayer.Character.Head.BrickColor),
                        Multi = false,
                        MaxSize = 200
                    })
                    
                    SkinChanging_Utility:Button({Name = "Apply Skin Color", Callback = function()
                        if not Library.Selected_Player then
                            return Library:Notification({
                                Name = "Valary.gg | Error",
                                Description = "Could not find target!",
                                Duration = 7.5,
                            })
                        end

                        if not Library.Selected_Player.Character then
                            return Library:Notification({
                                Name = "Valary.gg | Error",
                                Description = "Could not find targets character!",
                                Duration = 7.5,
                            })
                        end

                        if not Workspace:FindFirstChild(string.format("%s's Car", LocalPlayer.Name)) then
                            return Library:Notification({
                                Name = "Valary.gg | Error",
                                Description = "Could not find your car!",
                                Duration = 7.5,
                            })
                        end

                        if Workspace:FindFirstChild(string.format("%s's Car", LocalPlayer.Name)):GetAttribute("Car") ~= "Nissan GTR" then
                            return Library:Notification({
                                Name = "Valary.gg | Error",
                                Description = "Your car must be a GTR for this to work!",
                                Duration = 7.5,
                            })
                        end

                        for Index, Value in Library.Selected_Player.Character:GetChildren() do
                            if table.find(Library.Flags.Select_BodyParts_Modifications, Value.Name) or (Value.Name == "Ears" and table.find(Library.Flags.Select_BodyParts_Modifications, "Head")) then
                                pcall(function()
                                    FireServer(Workspace:FindFirstChild(string.format("%s's Car", LocalPlayer.Name)):FindFirstChild("Lights_FE"),
                                        "UpdateLight",
                                        Value,
                                        Value.Material,
                                        BrickColor.new(Library.Flags.Select_SkinColor_Modifications),
                                        Value.Transparency,
                                        false,
                                        15
                                    )
                                end)
                            end
                        end
                    end})

                    SkinChanging_Utility:Button({Name = "Fully Apply Skin Color", Callback = function()
                        if not Library.Selected_Player then
                            return Library:Notification({
                                Name = "Valary.gg | Error",
                                Description = "Could not find target!",
                                Duration = 7.5,
                            })
                        end

                        if not Library.Selected_Player.Character then
                            return Library:Notification({
                                Name = "Valary.gg | Error",
                                Description = "Could not find targets character!",
                                Duration = 7.5,
                            })
                        end

                        if not Workspace:FindFirstChild(string.format("%s's Car", LocalPlayer.Name)) then
                            return Library:Notification({
                                Name = "Valary.gg | Error",
                                Description = "Could not find your car!",
                                Duration = 7.5,
                            })
                        end

                        if Workspace:FindFirstChild(string.format("%s's Car", LocalPlayer.Name)):GetAttribute("Car") ~= "Nissan GTR" then
                            return Library:Notification({
                                Name = "Valary.gg | Error",
                                Description = "Your car must be a GTR for this to work!",
                                Duration = 7.5,
                            })
                        end

                        for Index, Value in Library.Selected_Player.Character:GetDescendants() do
                            if Value.Parent == Library.Selected_Player.Character then
                                if not Value:IsA("MeshPart") then
                                    continue
                                end
                            end

                            if Value.Parent.Name == "HoodieDown" or Value.Parent.Name == "HoodieUp" then
                                continue
                            end

                            if Value.Name ~= "HumanoidRootPart" then
                                pcall(function()
                                    FireServer(Workspace:FindFirstChild(string.format("%s's Car", LocalPlayer.Name)):FindFirstChild("Lights_FE"),
                                        "UpdateLight",
                                        Value,
                                        Value.Material,
                                        BrickColor.new(Library.Flags.Select_SkinColor_Modifications),
                                        Value.Transparency,
                                        false,
                                        15
                                    )
                                end)
                            end
                        end
                    end})
                end

                do -- Local Player Utilities
                    local Local_Player_Utilites_Section = Subpages.Player:Section({Name = "Local Player Utilities", Icon = Library:GetImage("NewController30px"), Side = 1})

                    Local_Player_Utilites_Section:Toggle({Name = "Infinite Stamina", Flag = "Infinite_Stamina", Default = false, Callback = function(State)
                        Config.South_Bronx.InfiniteStamina = State
                    end})

                    Local_Player_Utilites_Section:Toggle({Name = "Instant Interact", Flag = "Instant_Interact", Default = false, Callback = function(State)
                        Config.South_Bronx.InstantInteract = State
                    end})

                    Local_Player_Utilites_Section:Toggle({Name = "Respawn Where You Died", Flag = "Respawn_Where_You_Died", Default = false, Callback = function(State)
                        Config.South_Bronx.Spawn_Where_You_Died = State
                    end})

                    Local_Player_Utilites_Section:Toggle({Name = "Hide Name - Client Only", Flag = "Hide_Name", Default = false, Callback = function(State)
                        Config.South_Bronx.HideName = State
                    end})

                    local Actively_NoClipping = false;
                    local _NoClipBind = nil;
                    local _NoClipToggle = Local_Player_Utilites_Section:Toggle({Name = "No-Clip", Flag = "No_Clip", Default = false, Callback = function(State)
                        if State and _NoClipBind and _NoClipBind.Toggled == false then
                            _NoClipBind:Press(true)
                        end

                        if not State and _NoClipBind and _NoClipBind.Toggled == true then
                            _NoClipBind:Press(false)
                        end

                        if State then
                            if not Actively_NoClipping then
                                Actively_NoClipping = true
                                RunService:BindToRenderStep("No_Clip", 400, function()
                                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                                        if not Config.Teleporting and LocalPlayer.Character.Humanoid.Health ~= 0 then
                                            for Index, Value in LocalPlayer.Character:GetDescendants() do
                                                if Player_Collide_Data[Value.Name] then
                                                    pcall(function()
                                                        Value.CanCollide = false
                                                    end)
                                                end
                                            end
                                        else
                                            for Index, Value in LocalPlayer.Character:GetDescendants() do
                                                if Player_Collide_Data[Value.Name] then
                                                    pcall(function()
                                                        Value.CanCollide = true
                                                    end)
                                                end
                                            end
                                        end
                                    end
                                end)
                            end
                        else
                            RunService:UnbindFromRenderStep("No_Clip")
                            Actively_NoClipping = false

                            for Index, Value in LocalPlayer.Character:GetDescendants() do
                                if Player_Collide_Data[Value.Name] then
                                    pcall(function()
                                        Value.CanCollide = true
                                    end)
                                end
                            end
                        end
                    end})
                    
                    _NoClipBind = _NoClipToggle:Keybind({Name = "No-Clip", Flag="NoClipBind",Default=Enum.KeyCode.X,Mode="toggle",Callback=function(State)
                        _NoClipToggle:Set(State)
                    end})

                    Local_Player_Utilites_Section:Slider({Name = "Speed Value", Min = 0, Max = 100, Default = 50, Flag = "SpeedEnabled_Value", Suffix = "s/ps", Decimals = 0.1, Callback = function(State)
                        Config.South_Bronx.SpeedValue = State/(Console_Server and 10 or 200)
                    end})

                    local _SpeedBind = nil;
                    local _SpeedToggle = Local_Player_Utilites_Section:Toggle({Name = "Speed Enabled", Flag = "Speed_Enabled", Default = false, Callback = function(State)
                        if State and _SpeedBind and _SpeedBind.Toggled == false then
                            _SpeedBind:Press(true)
                        end

                        if not State and _SpeedBind and _SpeedBind.Toggled == true then
                            _SpeedBind:Press(false)
                        end

                        Config.South_Bronx.Speed = State
                    end})
                    
                    _SpeedBind = _SpeedToggle:Keybind({Name = "Speed Enabled", Flag="SpeedBind",Default=Enum.KeyCode.G,Mode="toggle",Callback=function(State)
                        _SpeedToggle:Set(State)
                    end})

                    local Teleport_Timing = Subpages.Player:Section({Name = "Teleportation Timing", Icon = Library:GetImage("HourglassEmpty"), Side = 2})

                    if not Console_Server then
                        local Teleport_Method = Subpages.Player:Section({Name = "Teleportation Method", Icon = Library:GetImage("Wrench"), Side = 1})

                        --[[Teleport_Method:Toggle({Name = "Use Frame Based Timing", Flag = "SouthBronx/Teleport/FrameBased", Default = true, Callback = function(State)
                            Config.South_Bronx.FrameBasedTiming=State
                        end})

                        Teleport_Method:Toggle({Name = "Use Ping Based Timing", Flag = "SouthBronx/Teleport/PingBased", Default = false, Callback = function(State)
                            Config.South_Bronx.PingBasedTiming=State
                        end})

                        Teleport_Method:Slider({Name = "Ping Compensation",Flag = "SouthBronx/Teleport/PingCompensation", Min = -50, Suffix = "ping", Max = 50, Default = 20, Decimals = 0.1, Callback = function(State)
                            Config.South_Bronx.PingCompensation = State
                        end})]]

                        Teleport_Method:Dropdown({Name = "Select Method", Flag = "SouthBronx/Teleport/Method", Items = {"Exempt + Tween", "Exempt Only"}, MaxSize = 125, Default = "Exempt + Tween", Callback = function(State)
                            Config.South_Bronx.Teleport_Method = State
                        end})

                        Teleport_Timing:Toggle({Name = "Use Frame Based Timing", Flag = "SouthBronx/Teleport/FrameBased", Default = true, Callback = function(State)
                            Config.South_Bronx.FrameBasedTiming=State
                        end})

                        Teleport_Timing:Toggle({Name = "Use Ping Based Timing", Flag = "SouthBronx/Teleport/PingBased", Default = false, Callback = function(State)
                            Config.South_Bronx.PingBasedTiming=State
                        end})

                        Teleport_Timing:Slider({Name = "Ping Compensation",Flag = "SouthBronx/Teleport/PingCompensation", Min = -50, Suffix = "ping", Max = 50, Default = 20, Decimals = 0.1, Callback = function(State)
                            Config.South_Bronx.PingCompensation = State
                        end})
                    else
                        Teleport_Timing:Label("You are in a console server, where the anticheat is completely disabled, all teleports are instant!")
                    end

                    local Inventory_Searcher = Subpages.Player:Section({Name = "Inventory Searcher", Icon = Library:GetImage("FolderEye"), Side = 2})

                    local Inventory_Items = nil

                    Inventory_Searcher:Textbox({
                        Name = "Items To Search For",
                        Default = "", 
                        Tooltip = "All player's with items matching the text here\nwill be displayed on the label below.",
                        Flag = "SouthBronx/InventorySearch/Text", 
                        Placeholder = "search here...", 
                        Callback = LPH_NO_VIRTUALIZE(function(State)
                            if Inventory_Items then
                                local Data = {}

                                for Index, Value in Players:GetPlayers() do
                                    if Value == LocalPlayer then continue end

                                    for _Index, _Value in Value.Backpack:GetChildren() do
                                        if string.find(_Value.Name:lower(), tostring(State):lower()) then
                                            table.insert(Data, string.format("%s (%s)", Value.Name , _Value.Name))
                                        end
                                    end
                                end

                                local Info = "None"

                                if #Data >= 1 then
                                    Info = table.concat(Data, ", ")                                    
                                end

                                Inventory_Items:SetText(string.format("Player's with items matching the text : %s", Info))
                            end
                        end)
                    })

                    Inventory_Items = Inventory_Searcher:Label("Player's with items matching the text : N/A", true)

                    --[[if LPH_OBFUSCATED == nil or tostring(LRM_LinkedDiscordID) == "734358389936881775" then
                        local Purchase_Items = Subpages.Player:Section({Name = "Purchase Items", Icon = Library:GetImage("ShoppingCart"), Side = 2})

                        Purchase_Items:Dropdown({Name = "Select Items", Flag = "SelectItems_ToPurchase", Items = {"Chains", "Cars", "Clothes", "Watches", "Shoes", "Hats", "Glasses"}, MaxSize = 150, Multi = true, Default = {"Clothes", "Shoes"}})

                        Purchase_Items:Button({Name = "Purchase Items", Callback = function()
                            if table.find(Library.Flags.SelectItems_ToPurchase, 'Chains') then
                                for Index, Value in ReplicatedStorage.Customization.Chains:GetChildren() do
                                    ReplicatedStorage:WaitForChild('RemoteEvents'):WaitForChild('VehicleCustomization'):FireServer('Window Tint', 9e9)

                                    task.wait(.1)

                                    local Event = ReplicatedStorage.RemoteEvents.PurchaseItem
                                    
                                    Event:FireServer(
                                        "Chains",
                                        Value.Name
                                    )
                                end
                            end

                            if table.find(Library.Flags.SelectItems_ToPurchase, 'Cars') then
                                for Index, Value in LocalPlayer.PlayerScripts["Client.Initializer"].Assets.UI.DealershipUI.Selector.Tabs.ScrollingFrame:GetChildren() do
                                    ReplicatedStorage:WaitForChild('RemoteEvents'):WaitForChild('VehicleCustomization'):FireServer('Window Tint', 9e9)

                                    task.wait(.1)

                                    ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("RPC"):FireServer(buffer.fromstring("\001"), "Purchase", Value.Name)
                                end
                            end

                            if table.find(Library.Flags.SelectItems_ToPurchase, 'Watches') then
                                for Index, Value in ReplicatedStorage.Customization.Watches:GetChildren() do
                                    ReplicatedStorage:WaitForChild('RemoteEvents'):WaitForChild('VehicleCustomization'):FireServer('Window Tint', 9e9)

                                    task.wait(.1)

                                    local Event = ReplicatedStorage.RemoteEvents.PurchaseItem
                                    
                                    Event:FireServer(
                                        "Watches",
                                        Value.Name
                                    )
                                end
                            end

                            if table.find(Library.Flags.SelectItems_ToPurchase, 'Clothes') then
                                for Index, Value in getgc(true) do
                                    if type(Value) == 'table' then
                                        if rawget(Value, "BlackTee") or rawget(Value, "BlackCottonWreathJoggers") then
                                            for Index, _ in Value do
                                                local Event = ReplicatedStorage.RemoteEvents.PurchaseItem
                                            
                                                Event:FireServer(
                                                    rawget(Value, "BlackTee") and "Shirts" or "Pants",
                                                    Index
                                                )

                                                task.wait(0.05)
                                            end
                                        end
                                    end
                                end
                            end

                            if table.find(Library.Flags.SelectItems_ToPurchase, 'Glasses') then
                                for Index, Value in getgc(true) do
                                    if type(Value) == 'table' then
                                        if rawget(Value, "Gold Cartier Shades") then
                                            table.foreach(Value, function(Index, _)
                                                local Event = ReplicatedStorage.RemoteEvents.PurchaseItem
                                            
                                                Event:FireServer(
                                                    'Glasses',
                                                    Index
                                                )
                                            end)
                                        end
                                    end
                                end
                            end

                            if table.find(Library.Flags.SelectItems_ToPurchase, 'Hats') then
                                for Index, Value in getgc(true) do
                                    if type(Value) == 'table' then
                                        if rawget(Value, "Beanie") then
                                            table.foreach(Value, function(Index, _)
                                                local Event = ReplicatedStorage.RemoteEvents.PurchaseItem
                                            
                                                Event:FireServer(
                                                    'Hats',
                                                    Index
                                                )
                                            end)
                                        end
                                    end
                                end
                            end

                            if table.find(Library.Flags.SelectItems_ToPurchase, 'Shoes') then
                                for Index, Value in getgc(true) do
                                    if type(Value) == 'table' then
                                        if rawget(Value, "AF1s") then
                                            for _Index, _Value in Value do
                                                for i,v in _Value do
                                                    if type(v) == 'table' then
                                                        for x,d in v do
                                                            if not string.find(d, "rbx") then
                                                                ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("PurchaseItem"):FireServer("Shoes", _Index, d)
                                                                task.wait(.05)
                                                            end
                                                        end
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end})
                    end]]
                end

                --[[do -- Teleport Settings
                    local Teleport_Timing_Settings = Subpages.Player:Section({Name = "Teleportation Timing Settings", Icon = Library:GetImage("HourglassEmpty"), Side = 2})

                    Teleport_Timing_Settings:Slider({Name = "Select Teleport Timing", Suffix = "s", Min = 0.1, Max = 0.3, Default = 0.2, Decimals = 0.01, Callback = function(State)
                        Config.South_Bronx.Teleport_Time = State
                    end})

                    Teleport_Timing_Settings:Label("This will only effect the 'exempt' teleport method, you don't have to change this but if you are having slow teleports, consider changing it and see what value works best for that ping.")
                end]]
            end

            do -- Vehicle
                local Information_Section = Subpages.Vehicles:Section({Name = "Information", Icon = Library:GetImage("Info"), Side = 1})

                Information_Section:Label("These mods can be VERY powerful and make your car break / go through the map.")

                local VehicleSection = Subpages.Vehicles:Section({Name = "Vehicle Modifications", Icon = Library:GetImage("Tune"), Side = 1})

                VehicleSection:Toggle({Name = "Vehicle Fly Enabled", Flag = "SouthBronx/VehicleModifications/VehicleFly/Enabled", Callback = function(State)
                    if State and LocalPlayer.Character.Humanoid.SeatPart and LocalPlayer.Character.Humanoid.SeatPart.Name == "DriveSeat" then
                        if FLYING then
                            NOFLY()
                        end

                        sFLY(true)
                    else
                        if FLYING then
                            NOFLY()
                        end
                    end
                end})

                VehicleSection:Slider({Name = "Vehicly Fly Speed", Min = 10, Max = 500, Default = 50, Flag = "SouthBronx/VehicleModifications/VehicleFly/Value", Suffix = "s/ps", Decimals = 1, Callback = function(State)
                    vehicleflyspeed = State/50
                end})

                VehicleSection:Toggle({Name = "Velocity Speed Enabled", Flag = "VelocitySpeed_Enabled", Default = false, Callback = function(State)
                    Config.VehicleModifications.SpeedEnabled = State
                end})

                VehicleSection:Slider({Name = "Speed Value", Min = 1, Max = 25, Default = 5, Flag = "VelocitySpeed_Value", Suffix = "s/ps", Decimals = 1, Callback = function(State)
                    Config.VehicleModifications.SpeedValue = State/1000
                end})

                VehicleSection:Toggle({Name = "Break Velocity Enabled", Flag = "BreakVelocity_Enabled", Default = false, Callback = function(State)
                    Config.VehicleModifications.BreakEnabled = State
                end})

                VehicleSection:Slider({Name = "Break Value", Min = 10, Max = 300, Default = 50, Suffix = "s/ps", Flag = "BreakVelocity_Value", Decimals = 1, Callback = function(State)
                    Config.VehicleModifications.BreakValue = State/1000
                end})

                VehicleSection:Toggle({Name = "Instant Break Enabled", Flag = "InstantBreak_Enabled", Default = false, Callback = function(State)
                    Config.VehicleModifications.InstantStop = State
                end})

                local Label = VehicleSection:Label("Instant Break Key")
                
                local Key; Key = Label:Keybind({Name = "Instant Break", Flag = "InstantBreak_Bind", Default = Enum.KeyCode.V, Mode = "hold", Callback = LPH_NO_VIRTUALIZE(function()
                    if Key then 
                        Config.VehicleModifications.InstantStopBind = Enum.KeyCode[tostring(select(2, Key:Get()):gsub("Enum.KeyCode.", ""))]
                    end
                end)})

                local Vehicle_Spawner = Subpages.Vehicles:Section({Name = "Vehicle Spawner", Icon = Library:GetImage("CarInfo"), Side = 2})

                local SelectVehicleDropdown = Vehicle_Spawner:Dropdown({Name = "Select Vehicle", Flag = "SelectVehicle_Spawner", Items = {}, Multi = false, MaxSize = 200})

                Vehicle_Spawner:Button({Name = "Spawn Vehicle", Callback = function()
                    if Library.Flags.SelectVehicle_Spawner then
                        ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("RPC"):FireServer(buffer.fromstring("\001"), "Spawn", Library.Flags.SelectVehicle_Spawner)

                        local Old_CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame

                        local MyCar;

                        local Abort = false
                        
                        if Library.Flags["SouthBronx/VehicleSpawner/GetIntoVehicle"] then
                            local Cars_ChildAdded; Cars_ChildAdded = Workspace.ChildAdded:Connect(LPH_NO_VIRTUALIZE(function(Child)
                                task.wait(.1)

                                if Child.Name:find(LocalPlayer.Name) then
                                    Child:WaitForChild("DriveSeat");task.wait(.5)

                                    Config:Teleport(Workspace:FindFirstChild(string.format("%s's Car", LocalPlayer.Name)).DriveSeat.CFrame + Vector3.new(0,5,0))

                                    task.wait(2.5)

                                    if (LocalPlayer.Character.HumanoidRootPart.Position - Workspace:FindFirstChild(string.format("%s's Car", LocalPlayer.Name)):FindFirstChildWhichIsA("Part", true).Position).Magnitude > 25 then
                                        Abort = true

                                        Library:Notification({
                                            Name = "Valary.gg | Vehicle Error!",
                                            Description = "Failed to teleport to your vehicle!",
                                            Duration = 5,
                                            Icon = "97118059177470",
                                            IconColor = Color3.fromRGB(255, 120, 120)
                                        })
                                    end

                                    if not Abort then
                                        fireproximityprompt(Child:WaitForChild("DriveSeat"):FindFirstChildWhichIsA("ProximityPrompt", true))
                                        MyCar = Child
                                        Cars_ChildAdded:Disconnect()
                                        Cars_ChildAdded = nil
                                    end

                                    task.wait(.1)
                                end
                            end))
                        end

                        if Library.Flags["SouthBronx/VehicleSpawner/GetIntoVehicle"] and Library.Flags["SouthBronx/VehicleSpawner/BringVehicle"] and not Abort then
                            repeat RunService.Heartbeat:Wait() until LocalPlayer.Character.Humanoid.SeatPart and MyCar

                            task.wait(1)

                            if not MyCar.PrimaryPart then
                                MyCar.PrimaryPart = MyCar.Body:FindFirstChild("#Weight", true)
                            end

                            if not MyCar.PrimaryPart then
                                MyCar.PrimaryPart = MyCar.Body:FindFirstChildWhichIsA("Part", true)
                            end

                            MyCar:SetPrimaryPartCFrame(Old_CFrame+Vector3.new(0,5,0))
                        end
                    end
                end})

                Vehicle_Spawner:Button({Name = "Teleport To Vehicle", Callback = function()
                    if Workspace:FindFirstChild(string.format("%s's Car", LocalPlayer.Name)) then
                        Config:Teleport(Workspace:FindFirstChild(string.format("%s's Car", LocalPlayer.Name)):FindFirstChildWhichIsA("Part", true).CFrame + Vector3.new(0,5,0))
                    else
                        Library:Notification({
                            Name = "Valary.gg | Error",
                            Description = "Could not find your car!",
                            Duration = 7.5,
                        })
                    end
                end})

                Vehicle_Spawner:Button({Name = "Refresh List", Callback = function()
                    local _Cars = {}

                    for Index, Value in LocalPlayer.PlayerScripts["Client.Initializer"].Assets.UI.DealershipUI.Selector.Tabs.ScrollingFrame:GetChildren() do
                        if not Value:IsA("TextButton") or Value.Name == "Template" then
                            continue
                        end
                        
                        --do
                            local Data = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("GetStat"):InvokeServer("Vehicles", Value.Name)

                            if Data then
                                table.insert(_Cars, Value.Name)

                                --break;
                            end
                        --end
                    end

                    SelectVehicleDropdown:Refresh(_Cars)
                end})

                Vehicle_Spawner = Subpages.Vehicles:Section({Name = "Vehicle Spawner Settings", Icon = Library:GetImage("CarGear"), Side = 2})

                Vehicle_Spawner:Toggle({Name = "Automatically Get Into Vehicle", Flag = "SouthBronx/VehicleSpawner/GetIntoVehicle", Tooltip = "This make you automatically get in the driver seat."})

                Vehicle_Spawner:Toggle({Name = "Automatically Bring Vehicle", Flag = "SouthBronx/VehicleSpawner/BringVehicle", Tooltip = "You must have get into vehicle enabled for this to work."})

                -- Refresh Vehicles
                    local _Cars = {}

                    for Index, Value in LocalPlayer.PlayerScripts["Client.Initializer"].Assets.UI.DealershipUI.Selector.Tabs.ScrollingFrame:GetChildren() do
                        if not Value:IsA("TextButton") or Value.Name == "Template" then
                            continue
                        end
                        
                        --do
                            local Data = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("GetStat"):InvokeServer("Vehicles", Value.Name)

                            if Data then
                                table.insert(_Cars, Value.Name)

                                --break;
                            end
                        --end
                    end

                    SelectVehicleDropdown:Refresh(_Cars)

                    --[[task.spawn(LPH_NO_VIRTUALIZE(function()
                        while task.wait(1) do
                            --pcall(function()
                                for Index, Value in LocalPlayer.PlayerScripts["Client.Initializer"].Assets.UI.DealershipUI.Selector.Tabs.ScrollingFrame:GetChildren() do
                                    if not Value:IsA("TextButton") or Value.Name == "Template" then
                                        continue
                                    end
                                    
                                    --do
                                        local Data = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("GetStat"):InvokeServer("Vehicles", Value.Name)

                                        if Data and not table.find(_Cars, Value.Name) then
                                            print(Value.Name)
                                            Vehicle_Spawner:AddOption(Value.Name)
                                            table.insert(_Cars, Value.Name)

                                            --break;
                                        end
                                    --end
                                end
                            --end)
                        end 
                    end))]]
                --
            end

            do -- Money
                local Information_Section = Subpages.Money:Section({Name = "Information", Icon = Library:GetImage("Info"), Side = 1})

                Information_Section:Label("If you gain more than $500,000 in one session, the script will deposit $500,000 into your ATM for security reasons.", "Left")

                local Automatic_Farming_Utilites = Subpages.Money:Section({Name = "Automated Utilities", Icon =  Library:GetImage("MoneyBag"), Side = 1})

                local FarmCards_Toggle, FarmChips_Toggle, FarmBoxes_Toggle

                FarmCards_Toggle = Automatic_Farming_Utilites:Toggle({Name = "Auto-Farm Cards", Flag = "Auto_Farm_Cards", Default = false, Callback = function(State)
                    if FarmChips_Toggle and FarmChips_Toggle:Get() then
                        FarmChips_Toggle:Set(false)
                    end

                    if FarmMarshmallows_Toggle and FarmMarshmallows_Toggle:Get() then
                        FarmMarshmallows_Toggle:Set(false)
                    end

                    if FarmBoxes_Toggle and FarmBoxes_Toggle:Get() then
                        FarmBoxes_Toggle:Set(false)
                    end

                    Config.South_Bronx.FarmingUtilities.CardFarm = State
                    if State then Start_CardFarm() else Stop_CardFarm() end
                end})

                FarmChips_Toggle = Automatic_Farming_Utilites:Toggle({Name = "Auto-Farm Chips", Flag = "Auto_Farm_Chips", Default = false, Callback = function(State)
                    if FarmCards_Toggle and FarmCards_Toggle:Get() then
                        FarmCards_Toggle:Set(false)
                    end

                    if FarmMarshmallows_Toggle and FarmMarshmallows_Toggle:Get() then
                        FarmMarshmallows_Toggle:Set(false)
                    end

                    if FarmBoxes_Toggle and FarmBoxes_Toggle:Get() then
                        FarmBoxes_Toggle:Set(false)
                    end

                    Config.South_Bronx.FarmingUtilities.ChipFarm = State
                    if State then Start_ChipFarm() else Stop_ChipFarm() end
                end})

                FarmMarshmallows_Toggle = nil; FarmMarshmallows_Toggle = Automatic_Farming_Utilites:Toggle({Name = "Auto-Farm Marshmallows", Flag = "Auto_Farm_Marshmallows", Default = false, Callback = function(State)
                    if FarmCards_Toggle and FarmCards_Toggle:Get() then
                        FarmCards_Toggle:Set(false)
                    end

                    if FarmChips_Toggle and FarmChips_Toggle:Get() then
                        FarmChips_Toggle:Set(false)
                    end

                    if FarmBoxes_Toggle and FarmBoxes_Toggle:Get() then
                        FarmBoxes_Toggle:Set(false)
                    end

                    Config.South_Bronx.FarmingUtilities.MarshmallowFarm = State
                    if State then Start_MarshmallowFarm() else Stop_MarshmallowFarm() end
                end})

                local MarshmallowSlider; MarshmallowSlider = Automatic_Farming_Utilites:Slider({Name = "Marshmallow Amount - $4750", Min = 1, Max = 50, Default = 25, Flag = "Marshmallow_Amount_AutoFarm", Decimals = 1, Callback = function(State)
                    if MarshmallowSlider then MarshmallowSlider:ChangeText(string.format("Marshmallow Amount - $%s", (State * 190))) end
                    Config.South_Bronx.FarmingUtilities.MarshmallowIncrement = State
                end})

                FarmBoxes_Toggle = Automatic_Farming_Utilites:Toggle({Name = "Auto-Farm Boxes", Tooltip = "Make sure to have the j*b before enabling this.", Flag = "Auto_Farm_Boxes", Default = false, Callback = function(State)
                    if FarmCards_Toggle and FarmCards_Toggle:Get() then
                        FarmCards_Toggle:Set(false)
                    end

                    if FarmChips_Toggle and FarmChips_Toggle:Get() then
                        FarmChips_Toggle:Set(false)
                    end

                    if FarmMarshmallows_Toggle and FarmMarshmallows_Toggle:Get() then
                        FarmMarshmallows_Toggle:Set(false)
                    end

                    Config.South_Bronx.FarmingUtilities.BoxFarm = State
                    if State then Start_BoxFarm() else Stop_BoxFarm() end
                end})

                local AutoFarm_Webhook = Subpages.Money:Section({Name = "Auto Farm Webhook", Icon = Library:GetImage("CellTower"), Side = 1})

                AutoFarm_Webhook:Toggle({Name = "Enabled", Flags = "SouthBronx/AutoFarm/SendWebhook", Callback = function(State)
                    Config.South_Bronx.FarmingUtilities.Webhook_Enabled = State
                end})

                AutoFarm_Webhook:Toggle({Name = "Log South Bronx Name Instead", Flags = "SouthBronx/AutoFarm/LogSbName", Tooltip = "This won't log your user, but log your south bronx name.", Callback = function(State)
                    Config.South_Bronx.FarmingUtilities.Log_SouthBronx_Name = State
                end})

                AutoFarm_Webhook:Textbox({Name = "Enter Webhook Link", Placeholder = "https://discord.com/api/webhooks/1408953037527060571/1TOvjUGQlzKOM8GB2LlEi2OusGmscVBB-fjB82GJDKvHlA1yBF_mK71V5hKC-_zgPdpO", Flag = "SouthBronx/AutoFarm/Webhook", Callback = function(State)
                    Config.South_Bronx.FarmingUtilities.Webhook_URL = State
                end})

                AutoFarm_Webhook:Button({Name = "Test Webhook", Callback = function(State)
                    local Success, Error = pcall(function()
                        return game:HttpGet(Config.South_Bronx.FarmingUtilities.Webhook_URL)
                    end)

                    if not Success then
                        Library:Notification({
                            Name = "Valary.gg | Webhook",
                            Description = "This link is invalid. Please fix it.",
                            Duration = 10,
                            Icon = "97118059177470",
                            IconColor = Color3.fromRGB(255, 120, 120)
                        })

                        return
                    end

                    Config:SendWebhook()
                end})

                local Manual_Farming_Utilities = Subpages.Money:Section({Name = "Manual Utilities", Icon = Library:GetImage("AutoManifacturing"), Side = 2})

                Manual_Farming_Utilities:Slider({Name = "Amount Of Vehicles To Rob", Min = 1, Max = 5, Default = 2, Flag = "Amount_OfVehicles", Decimals = 1})

                local StartRobbing, HumanoidDied;

                local Button; Button = Manual_Farming_Utilities:Button({Name = "Start - Manually Steal Loot From Vehicles", Callback = function()
                    if StartRobbing then
                        if coroutine.status(StartRobbing) == "suspended" then
                            task.cancel(StartRobbing)
                            StartRobbing = nil
                        end

                        Button:SetText("Start - Manually Steal Loot From Vehicles")

                        return Library:Notification({
                            Name = "Valary.gg | Robbing",
                            Description = "Cancelled Operation!",
                            Duration = 7.5,
                        })
                    end

                    if not LocalPlayer.Character:FindFirstChild("Backpack") then
                        return Library:Notification({
                            Name = "Valary.gg | Robbing",
                            Description = "You don't have a backpack!",
                            Duration = 7.5,
                        })
                    end

                    local Amount = Library.Flags.Amount_OfVehicles

                    local Cars = {}

                    for Index, Value in Workspace.Folders.RobbableCars:GetChildren() do
                        if Value.WindowBreak.Transparency == 0.550000011920929 then
                            if #Cars >= Amount then continue end
                            table.insert(Cars, Value)
                        end
                    end

                    if #Cars == 0 then
                        return Library:Notification({
                            Name = "Valary.gg | Robbing",
                            Description = "No cars are able to be robbed.",
                            Duration = 5,
                        })
                    end

                    if #Cars<tonumber(Amount) then
                        Library:Notification({
                            Name = "Valary.gg | Robbing",
                            Description = string.format("%s Cars can't be robbed, defaulting to %s", tostring(Amount), tostring(#Cars)),
                            Duration = 5,
                        })
                    end

                    HumanoidDied = LocalPlayer.Character.Humanoid.Died:Connect(function()
                        if StartRobbing then
                            if coroutine.status(StartRobbing) == "suspended" then
                                task.cancel(StartRobbing)
                                Button:SetText("Start - Manually Steal Loot From Vehicles")
                            end
                        end

                        HumanoidDied:Disconnect()
                        HumanoidDied = nil
                    end)

                    StartRobbing = task.spawn(function()
                        Button:SetText("Stop - Manually Steal Loot From Vehicles")

                        if not LocalPlayer.Backpack:FindFirstChild("Crowbar") and not LocalPlayer.Character:FindFirstChild("Crowbar") then
                            Config:Teleport(Gun_Locations["Crowbar"], true)

                            repeat task.wait() until Workspace.Folders.PromptPurchases:FindFirstChild("Crowbar")

                            task.wait(1)

                            fireproximityprompt(Workspace.Folders:FindFirstChild("PromptPurchases")["Crowbar"].proxprompt:FindFirstChildOfClass("ProximityPrompt"))

                            task.wait(1)

                            if not LocalPlayer.Backpack:FindFirstChild("Crowbar") and not LocalPlayer.Character:FindFirstChild("Crowbar") then
                                return Library:Notification({
                                    Name = "Valary.gg | Error",
                                    Description = "Couldn't get a crowbar!",
                                    Duration = 7.5,
                                })
                            end
                        end

                        for Index, Value in Cars do
                            Config:Teleport(Value.WindowBreak.CFrame, true)

                            if not LocalPlayer.Character:FindFirstChild("Crowbar") then
                                LocalPlayer.Character.Humanoid:UnequipTools()
                                task.wait(0.25)
                                LocalPlayer.Character.Humanoid:EquipTool(LocalPlayer.Backpack:FindFirstChild("Crowbar"))
                            end

                            repeat task.wait(.1) fireproximityprompt(Value.WindowBreak.Attachment.ProximityPrompt) until
                            LocalPlayer.PlayerGui:FindFirstChild("SearchCarUI")

                            repeat task.wait() until not LocalPlayer.PlayerGui:FindFirstChild("SearchCarUI")

                            Config:Teleport(CFrame.new(1014, 4, -348), true)

                            task.wait(.5)

                            Workspace.Folders.NPCs.RobberyManager.UpperTorso.ProximityPrompt.HoldDuration = 0
                            fireproximityprompt(Workspace.Folders.NPCs.RobberyManager.UpperTorso.ProximityPrompt)
                            task.wait(.25)

                            if Index == #Cars then
                                Button:SetText("Start - Manually Steal Loot From Vehicles")
                                Library:Notification({
                                    Name = "Valary.gg | Robbing",
                                    Description = "Finished Robbing Vehicles!",
                                    Duration = 7.5,
                                })
                            end
                        end

                        HumanoidDied:Disconnect()

                        StartRobbing = nil
                        HumanoidDied = nil
                    end)
                end})

                local Anti_Idle_Section = Subpages.Money:Section({Name = "Anti-Idle Information", Icon = Library:GetImage("ZonePersonUrgent"), Side = 2})

                Anti_Idle_Section:Label("Don't worry, valary has already bypassed idle checks for you!")

                --[[AutoBuyGunToggle = Anti_Idle_Section:Toggle({Name = "Auto-Buy Gun If Death While Auto-Farming", Flag = "SouthBronx/FarmingUtilities/Auto-Buy-Gun", Callback = function(State)
                    Config.South_Bronx.FarmingUtilities.AutoBuyGun = State
                end})]]

                Anti_Idle_Section:Toggle({Name = "Auto-Buy Mask If Death While Auto-Farming", Flag = "SouthBronx/FarmingUtilities/Auto-Buy-Mask", Callback = function(State)
                    Config.South_Bronx.FarmingUtilities.AutoBuyMask = State
                end})

                local AutoFarm_Stats = Subpages.Money:Section({Name = "Auto Farm Stats Information", Icon = Library:GetImage("QueryStats"), Side = 2})

                local AutoFarm_TimeElapsed = AutoFarm_Stats:Label("Auto Farm Time Elapsed | 0h, 0m, 0s")

                local Money_Gained_Label = AutoFarm_Stats:Label("Money Gained | $0")
                
                task.spawn(LPH_NO_VIRTUALIZE(function()
                    while task.wait(1) do
                        if Config.South_Bronx.FarmingUtilities.MarshmallowFarm or Config.South_Bronx.FarmingUtilities.CardFarm or Config.South_Bronx.FarmingUtilities.ChipFarm or Config.South_Bronx.FarmingUtilities.BoxFarm then
                            Config.South_Bronx.Farm_Data.Time_Elapsed += 1
                        end

                        AutoFarm_TimeElapsed:SetText("Auto Farm Time Elapsed | "..convertSeconds(Config.South_Bronx.Farm_Data.Time_Elapsed))

                        pcall(function()
                            local New_Balance = LocalPlayer.PlayerGui.Main.Money.Amount.Text:match("%$([%d,]+)")
                            New_Balance = New_Balance:gsub(",", "")
                            New_Balance = tonumber(New_Balance)

                            for Index = 1, Times_Deposited do
                                New_Balance+=500000
                            end

                            local PlusOrMinus = New_Balance >= tonumber(Start_Balance) and "+ " or "- "
                            local Number = New_Balance - tonumber(Start_Balance)

                            local Color = Number >= 0 and "#4CAF50" or "#F44336"

                            Money_Gained_Label:SetText(string.format(
                                "Money Gained | <font color='%s'>%s%s</font>",
                                Color,
                                PlusOrMinus,
                                Format_Money(math.abs(Number))
                            ))
                        end)
                    end
                end))

                local Rejoin_Section = Subpages.Money:Section({Name = "Rejoiner Settings", Icon = '137623872962804', Side = 2})

                Rejoin_Section:Label("This will rejoin if you die while farming marshmallows, everything is recommended on.")

                local Rejoin_Enabled = string.find(readfile("ValaryGG_RejoinerSettings.txt"), ' enabled ') ~= nil
                local KillAura_Enabled = string.find(readfile("ValaryGG_RejoinerSettings.txt"), ' killaura ') ~= nil
                local AutoBuyGun_Enabled = string.find(readfile("ValaryGG_RejoinerSettings.txt"), ' autobuygun ') ~= nil
                    
                Rejoin_Section:Toggle({Name = "Enabled", Flag = tostring(math.random(1, 9e8)), Default = Rejoin_Enabled, Callback = function(State)
                    Config.Rejoiner.Enabled = State
                    
                    if State then
                        if not string.find(readfile("ValaryGG_RejoinerSettings.txt"), ' enabled ') then
                            local file_data = readfile("ValaryGG_RejoinerSettings.txt")
                            writefile('ValaryGG_RejoinerSettings.txt', file_data..' enabled ')
                        end
                    else
                        if string.find(readfile("ValaryGG_RejoinerSettings.txt"), ' enabled ') then
                            local file_data = readfile("ValaryGG_RejoinerSettings.txt")
                            file_data = file_data:gsub(' enabled ', '')

                            writefile('ValaryGG_RejoinerSettings.txt', file_data)
                        end
                    end
                end})

                --[[Rejoin_Section:Toggle({Name = "Auto-Buy Guns", Flag = tostring(math.random(1, 9e8)), Default = AutoBuyGun_Enabled, Callback = function(State)
                    Config.Rejoiner.AutoBuyGun = State

                    if State then
                        if not string.find(readfile("ValaryGG_RejoinerSettings.txt"), ' autobuygun ') then
                            local file_data = readfile("ValaryGG_RejoinerSettings.txt")
                            writefile('ValaryGG_RejoinerSettings.txt', file_data..' autobuygun ')
                        end
                    else
                        if string.find(readfile("ValaryGG_RejoinerSettings.txt"), ' autobuygun ') then
                            local file_data = readfile("ValaryGG_RejoinerSettings.txt")
                            file_data = file_data:gsub(' autobuygun ', '')

                            writefile('ValaryGG_RejoinerSettings.txt', file_data)
                        end
                    end
                end})

                Rejoin_Section:Toggle({Name = "Auto-Enable Kill Aura", Flag = tostring(math.random(1, 9e8)), Default = KillAura_Enabled, Tooltip = "This will be set to 150 studs.", Callback = function(State)
                    Config.Rejoiner.KillAura = State

                    if State then
                        if not string.find(readfile("ValaryGG_RejoinerSettings.txt"), ' killaura ') then
                            local file_data = readfile("ValaryGG_RejoinerSettings.txt")
                            writefile('ValaryGG_RejoinerSettings.txt', file_data..' killaura ')
                        end
                    else
                        if string.find(readfile("ValaryGG_RejoinerSettings.txt"), ' killaura ') then
                            local file_data = readfile("ValaryGG_RejoinerSettings.txt")
                            file_data = file_data:gsub(' killaura ', '')

                            writefile('ValaryGG_RejoinerSettings.txt', file_data)
                        end
                    end
                end})]]

                local Battery_Saver = Subpages.Money:Section({Name = "Performance Saver", Icon = Library:GetImage("Battery"), Side = 2})

                local BatteryToggle_Loaded = false;

                Battery_Saver:Toggle({Name = "Enabled", Flag = "SouthBronx/BatterySaver", Tooltip = "This will disable 3D rendering and cap your frames per second to 15.\nUseful if your trying to play other games / run multiple clients.", Callback = function(State)
                    if not BatteryToggle_Loaded then return end

                    if not State then
                        setfpscap(1000)
                        RunService:Set3dRenderingEnabled(true)
                    end
                end})

                task.spawn(LPH_NO_VIRTUALIZE(function()
                    while true do
                        task.wait(1)

                        if Library.Flags["SouthBronx/BatterySaver"] then
                            setfpscap(15)
                            RunService:Set3dRenderingEnabled(false)
                        end
                    end
                end))

                BatteryToggle_Loaded = true
            end
        end

        do -- Settings
            local Subpages = {
                ["Configs"] = Pages["Settings"]:SubPage({
                    Name = "Configs", 
                    Icon = "96491224522405", 
                    Columns = 2
                }),

                ["Theming"] = Pages["Settings"]:SubPage({
                    Name = "Theming", 
                    Icon = "103863157706913", 
                    Columns = 2
                }),

                ["Configuration"] = Pages["Settings"]:SubPage({
                    Name = "Configuration", 
                    Icon = "137300573942266", 
                    Columns = 2
                })
            }

            do -- Theming
                local ThemingSection = Subpages["Theming"]:Section({Name = "theming", Icon = "103863157706913", Side = 1})
                local ThemingProfiles = Subpages["Theming"]:Section({Name = "profiles", Icon = "96491224522405", Side = 2})
                local AutoloadSection = Subpages["Theming"]:Section({Name = "autoload", Icon = "137623872962804", Side = 2})

                for Index, Value in Library.Theme do 
                    Library.ThemeColorpickers[Index] = ThemingSection:Label(Index, "Left"):Colorpicker({
                        Name = "Colorpicker",
                        Flag = "ColorpickerTheme" .. Index,
                        Default = Value,
                        Alpha = 0,
                        Callback = function(Color, Alpha)
                            Library.Theme[Index] = Color
                            Library:ChangeTheme(Index, Color)
                        end
                    })
                end

                local ThemeData = {}

                for Index, Value in Library.Themes do
                    table.insert(ThemeData, Index)
                end

                ThemingProfiles:Dropdown({
                    Name = "preset themes",
                    Items = ThemeData,
                    MaxSize = 200,
                    Default = "Preset",
                    Multi = false,
                    Callback = function(Value)
                        local ThemeData = Library.Themes[Value]

                        if not ThemeData then 
                            return
                        end

                        for Index, Value in Library.Theme do 
                            Library.Theme[Index] = ThemeData[Index]
                            Library:ChangeTheme(Index, ThemeData[Index])

                            Library.ThemeColorpickers[Index]:Set(ThemeData[Index])
                        end

                        task.wait(0.3)

                        Library:Thread(function() -- i do this because sometimes the themes dont update
                            for Index, Value in Library.Theme do 
                                Library.Theme[Index] = Library.Flags["ColorpickerTheme" .. Index].Color
                                Library:ChangeTheme(Index, Library.Flags["ColorpickerTheme" .. Index].Color)
                            end    
                        end)
                    end
                })

                local ThemeSelected 
                local ThemeName

                do
                    local ThemesDropdown = ThemingProfiles:Dropdown({
                        Name = "themes", 
                        Flag = "ThemesList", 
                        Items = { }, 
                        Multi = false,
                        Callback = function(Value)
                            ThemeSelected = Value
                        end
                    })

                    ThemingProfiles:Textbox({
                        Name = "theme name", 
                        Default = "", 
                        Flag = "ThemeName", 
                        Placeholder = "enter text", 
                        Callback = function(Value)
                            ThemeName = Value
                        end
                    })

                    ThemingProfiles:Button({
                        Name = "save",
                        Callback = function()
                            if ThemeName and ThemeName ~= "" then
                                writefile(Library.Folders.Themes .. "/" .. ThemeName .. ".json", Library:GetTheme())
                                Library:RefreshThemesList(ThemesDropdown)
                            end
                        end
                    })

                    ThemingProfiles:Button({
                        Name = "load",
                        Callback = function()
                            if ThemeSelected then
                                local Success, Result = Library:LoadTheme(readfile(Library.Folders.Themes .. "/" .. ThemeSelected))

                                if Success then 
                                    Library:Notification({
                                        Name = "Success",
                                        Description = "Succesfully loaded theme: ".. ThemeSelected,
                                        Duration = 5,
                                        Icon = "116339777575852",
                                        IconColor = Color3.fromRGB(52, 255, 164)
                                    })

                                    task.wait(0.3)

                                    Library:Thread(function() -- i do this because sometimes the themes dont update
                                        for Index, Value in Library.Theme do 
                                            Library.Theme[Index] = Library.Flags["ColorpickerTheme" .. Index].Color
                                            Library:ChangeTheme(Index, Library.Flags["ColorpickerTheme" .. Index].Color)
                                        end    
                                    end)
                                else
                                    Library:Notification({
                                        Name = "Error!",
                                        Description = "Failed to load theme, error:\n",
                                        Duration = 5,
                                        Icon = "97118059177470",
                                        IconColor = Color3.fromRGB(255, 120, 120)
                                    })
                                end
                            end
                        end
                    })

                    AutoloadSection:Button({
                        Name = "set selected theme as autoload",
                        Callback = function()
                            if ThemeSelected then 
                                writefile(Library.Folders.Directory .. "/AutoLoadTheme (do not modify this).json", readfile(Library.Folders.Themes .. "/" .. ThemeSelected))
                            end
                        end
                    })

                    AutoloadSection:Button({
                        Name = "set current theme as autoload",
                        Callback = function()
                            if ThemeSelected then 
                                writefile(Library.Folders.Directory .. "/AutoLoadTheme (do not modify this).json", Library:GetTheme())
                            end
                        end
                    })

                    AutoloadSection:Button({
                        Name = "remove autoload theme",
                        Callback = function()
                            writefile(Library.Folders.Directory .. "/AutoLoadTheme (do not modify this).json", "")
                        end
                    })

                    Library:RefreshThemesList(ThemesDropdown)
                end
            end

            do -- Configs
                local ConfigsSection = Subpages["Configs"]:Section({Name = "profiles", Icon = "96491224522405", Side = 1})
                local AutoloadSection = Subpages["Configs"]:Section({Name = "autoload", Icon = "137623872962804", Side = 2})
                local Server_Section = Subpages["Configs"]:Section({Name = "server hopper", Icon = "93007870315593", Side = 2})

                local ConfigSelected 
                local ConfigName

                do
                    local ConfigsDropdown = ConfigsSection:Dropdown({
                        Name = "configs", 
                        Flag = "ConfigsList", 
                        Items = { }, 
                        Multi = false,
                        Callback = function(Value)
                            ConfigSelected = Value
                        end
                    })

                    ConfigsSection:Textbox({
                        Name = "config name", 
                        Default = "", 
                        Flag = "ConfigName", 
                        Placeholder = "enter text", 
                        Callback = function(Value)
                            ConfigName = Value
                        end
                    })

                    ConfigsSection:Button({
                        Name = "create",
                        Callback = function()
                            if ConfigName and ConfigName ~= "" then
                                writefile(Library.Folders.Configs .. "/" .. ConfigName .. ".json", Library:GetConfig())
                                Library:RefreshConfigsList(ConfigsDropdown)
                            end
                        end
                    })

                    ConfigsSection:Button({
                        Name = "delete",
                        Callback = function()
                            if ConfigSelected then
                                Library:DeleteConfig(ConfigSelected)
                                Library:RefreshConfigsList(ConfigsDropdown)
                            end
                        end
                    })

                    ConfigsSection:Button({
                        Name = "load",
                        Callback = function()
                            if ConfigSelected then
                                local Success, Result = Library:LoadConfig(readfile(Library.Folders.Configs .. "/" .. ConfigSelected))

                                if Success then 
                                    Library:Notification({
                                        Name = "Success",
                                        Description = "Succesfully loaded config: ".. ConfigSelected,
                                        Duration = 5,
                                        Icon = "116339777575852",
                                        IconColor = Color3.fromRGB(52, 255, 164)
                                    })

                                    task.wait(0.3)

                                    Library:Thread(function() -- i do this because sometimes the themes dont update
                                        for Index, Value in Library.Theme do 
                                            Library.Theme[Index] = Library.Flags["ColorpickerTheme" .. Index].Color
                                            Library:ChangeTheme(Index, Library.Flags["ColorpickerTheme" .. Index].Color)
                                        end    
                                    end)
                                else
                                    Library:Notification({
                                        Name = "Error!",
                                        Description = "Failed to load config, error:\n",
                                        Duration = 5,
                                        Icon = "97118059177470",
                                        IconColor = Color3.fromRGB(255, 120, 120)
                                    })
                                end
                            end
                        end
                    })

                    ConfigsSection:Button({
                        Name = "save",
                        Callback = function()
                            if ConfigSelected then
                                Library:SaveConfig(ConfigSelected)
                            end
                        end
                    })

                    ConfigsSection:Button({
                        Name = "refresh list",
                        Callback = function()
                            Library:RefreshConfigsList(ConfigsDropdown)
                        end
                    })

                    Library:RefreshConfigsList(ConfigsDropdown)
                end

                do
                    AutoloadSection:Button({
                        Name = "set current config as autoload",
                        Callback = function()
                            if ConfigSelected then 
                                writefile(Library.Folders.Directory .. "/AutoLoadConfig (do not modify this).json", Library:GetConfig())
                            end
                        end
                    })

                    AutoloadSection:Button({
                        Name = "remove autoload config",
                        Callback = function()
                            writefile(Library.Folders.Directory .. "/AutoLoadConfig (do not modify this).json", "")
                        end
                    })
                end

                if not isfile("ValaryGG_ServerAmount.txt") then
                    writefile("ValaryGG_ServerAmount.txt", "5")
                end

                Server_Section:Label("note : this hops servers to try find one with low players, this can take up to 10 minutes.")

                Server_Section:Slider({
                    Name = "max amount of players in server",
                    Flag = "SouthBronx/ServerHopper/MaxPlayers",
                    Default = tonumber(readfile("ValaryGG_ServerAmount.txt")),
                    Min = 1,
                    Max = 25,
                    Decimals = 1,
                    Callback = function(Value)
                        writefile("ValaryGG_ServerAmount.txt", tostring(Value))
                    end
                })

                Server_Section:Button({Name = "start server hopping", Callback = function()
                    local Source = [[
                        queue_on_teleport(readfile("Valary_ServerHop.txt"))

                        game.Loaded:Wait()
                        task.wait(1)

                        if game.PlaceId == 10179538382 then return end

                        if #game.Players:GetPlayers() <= tonumber(readfile("ValaryGG_ServerAmount.txt")) then 
                            if isfile("Valary_ServerHop.txt") then
                                delfile("Valary_ServerHop.txt")
                            end

                            writefile("valary/Assets/ServerFound.mp3", game:HttpGet("https://raw.githubusercontent.com/ValarySoftworks/Assets/refs/heads/main/ServerFound.mp3?raw=true"))
                            local Sound = Instance.new("Sound", workspace)
                            Sound.SoundId = getcustomasset("valary/Assets/ServerFound.mp3")
                            Sound.Volume = 10000
                            Sound:Play()

                            return 
                        end

                        task.wait(2)

                        local VirtualInputManager = Instance.new("VirtualInputManager", nil)

                        for Index, Value in game:GetService("Players"):GetPlayers() do
                            if Value ~= game:GetService("Players").LocalPlayer then
                                game:GetService("StarterGui"):SetCore("PromptBlockPlayer", Value)

                                local Start = tick()

                                repeat 
                                    task.wait()
                                until game:GetService("CoreGui"):FindFirstChild("BlockingModalScreen") or tick() - Start >= 1.5

                                if tick() - Start < 1.5 then
                                    break
                                end
                            end
                        end

                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Up, false, game)
                        task.wait(0.5)
                        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Up, false, game)

                        task.wait(1)

                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
                        task.wait(0.5)
                        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)

                        task.wait(1)

                        if #game:GetService("StarterGui"):GetCore("GetBlockedUserIds") == 0 then
                            repeat task.wait(10)
                                for Index, Value in game:GetService("Players"):GetPlayers() do
                                    if Value ~= game:GetService("Players").LocalPlayer then
                                        game:GetService("StarterGui"):SetCore("PromptBlockPlayer", Value)

                                        local Start = tick()

                                        repeat 
                                            task.wait()
                                        until game:GetService("CoreGui"):FindFirstChild("BlockingModalScreen") or tick() - Start >= 1.5

                                        if tick() - Start < 1.5 then
                                            break
                                        end
                                    end
                                end

                                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Up, false, game)
                                task.wait(0.5)
                                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Up, false, game)

                                task.wait(1)

                                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
                                task.wait(0.5)
                                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)

                                task.wait(1)
                            until #game:GetService("StarterGui"):GetCore("GetBlockedUserIds") > 0
                        end

                        game:GetService("TeleportService"):Teleport(10179538382, game:GetService("Players").LocalPlayer)
                    ]]

                    writefile("Valary_ServerHop.txt", Source)

                    queue_on_teleport(Source)

                    game:GetService("TeleportService"):Teleport(10179538382)
                end})
   
                local queue_on_teleport = queue_on_teleport or function(func)
                    if type(func) == "function" then
                        func = string.dump(func)
                    end

                    if type(func) == "string" then
                        writefile("Valary_ServerHop.txt", func)
                    end
                end
                Server_Section:Button({
    Name = "join console server", 
    Callback = function()
        local teleportScript = 
    -- Reset existing hook biar ga double
    __namecall == nil
    
    -- Hook IsTenFootInterface biar dianggap console
    __namecall = hookmetamethod(game, '__namecall', newcclosure(function(Self, ...)
        if getnamecallmethod() == 'IsTenFootInterface' then
            return true
        end
        return __namecall(Self, ...)
    end))
    
    print("Console server mode activated!")


queue_on_teleport(teleportScript)
        game:GetService('TeleportService'):Teleport(10179538382)
    end, 
    Tooltip = "These servers have no anti-cheat, making farming incredibly fast!"
})

            do -- Configuration
                local MenuSection = Subpages["Configuration"]:Section({Name = "menu", Icon = "93007870315593", Side = 1})
                local TweeningSection = Subpages["Configuration"]:Section({Name = "tweening", Icon = "130045183204879", Side = 2})

                do
                    MenuSection:Label("menu keybind", "Left"):Keybind({
                        Name = "MenuKeybind",
                        Flag = "MenuKeybind",
                        NoKeyBindList = true,
                        Mode = "toggle",
                        Default = Library.MenuKeybind,
                        HideKeyFromUI = true,
                        Callback = function()
                            Library.MenuKeybind = Library.Flags["MenuKeybind"].Key
                        end
                    })

                    MenuSection:Toggle({
                        Name = "keybind list",
                        Flag = "keybind list",
                        Default = true,
                        Callback = function(Value)
                            KeybindList:SetVisibility(Value)
                        end
                    })
                    
                    MenuSection:Toggle({
                        Name = "watermark",
                        Flag = "watermark",
                        Default = false,
                        Callback = function(Value)
                            Watermark:SetVisibility(Value)
                        end
                    })
                
                    GlobalChat_Toggle = MenuSection:Toggle({
                        Name = "global chat",
                        Flag = "global chat",
                        Default = true,
                        Callback = function(Value)
                            ChatSystem:SetVisibility(Value)
                        end
                    })

                    MenuSection:Button({
                        Name = "unload",
                        Callback = function()
                            Library:Unload()
                        end
                    })
                end

                do
                    TweeningSection:Slider({
                        Name = "time",
                        Flag = "TweenTime",
                        Default = Library.Tween.Time,
                        Min = 0,
                        Max = 5,
                        Decimals = 0.01,
                        Callback = function(Value)
                            Library.Tween.Time = Value
                        end
                    })

                    TweeningSection:Dropdown({
                        Name = "style",
                        Flag = "TweenStyle",
                        Default = "Cubic",
                        Items = {"Linear", "Sine", "Quad", "Cubic", "Quart", "Quint", "Exponential", "Circular", "Back", "Elastic", "Bounce"},
                        MaxSize = 150,
                        Callback = function(Value)
                            Library.Tween.Style = Enum.EasingStyle[Value]
                        end
                    })

                    TweeningSection:Dropdown({
                        Name = "direction",
                        Flag = "TweenDirection",
                        MaxSize = 55,
                        Default = "Out",
                        Items = {"In", "Out", "InOut"},
                        Callback = function(Value)
                            Library.Tween.Direction = Enum.EasingDirection[Value]
                        end
                    })
                end
            end
        end
    end
end

if hookfunction then
    local _FireServer;
    local Lights_FE;
    local InflictTarget;

    _FireServer = hookfunction(Instance.new("RemoteEvent", nil).FireServer, LPH_NO_UPVALUES(function(self, ...)
        local Arguments = {...}

        if tostring(self) == "Lights_FE" then
            local f, s = debug.getinfo(2, "fs")
            if not Lights_FE then
                Lights_FE = f.func
            end

            if Lights_FE ~= f.func then
                while true do end
                return
            end
        elseif tostring(self) == "InflictTarget" then
            local f, s = debug.getinfo(2, "fs")
            if not InflictTarget then
                InflictTarget = f.func
            end

            if InflictTarget ~= f.func then
                while true do end
                return
            end
        else
            return _FireServer(self, ...)
        end

        return _FireServer(self, ...)
    end))
end

if LPH_OBFUSCATED then
    task.spawn(LPH_JIT_MAX(function()
        while true do
            task.wait(.1)
            if getgenv().SimpleSpyExecuted ~= nil then
                LocalPlayer:Destroy()
                game:Shutdown()
                LocalPlayer:Kick()
                while true do end
            end
        end
    end))
end

if not Device_Mobile then
    RunService:BindToRenderStep("UI_Mouse_Fixer", 400, LPH_NO_VIRTUALIZE(function()
        if Window.IsOpen and not UserInputService.MouseIconEnabled then
            UserInputService.MouseIconEnabled = true
        end

        if not Window.IsOpen and Config.Gun_Held and UserInputService.MouseIconEnabled then
            UserInputService.MouseIconEnabled = false
        end
    end))
end

Library:Notification({
    Name = "Valary.gg | Loader",
    Description = "loaded in: " .. string.sub(tostring(os.clock() - LoadingTick), 1, 4).. "s",
    Duration = 10
})

Library:Init() -- put this at the end of ur script or the autoload will not work

if getgenv().rejoined_and_farming then
    local Rejoin_Enabled = string.find(readfile("ValaryGG_RejoinerSettings.txt"), ' enabled ') ~= nil
    local KillAura_Enabled = string.find(readfile("ValaryGG_RejoinerSettings.txt"), ' killaura ') ~= nil
    local AutoBuyGun_Enabled = string.find(readfile("ValaryGG_RejoinerSettings.txt"), ' autobuygun ') ~= nil

    --[[if KillAura_Enabled then
        KillAura_Range:Set(150)
        KillAura_Toggle:Set(true)
    end

    if AutoBuyGun_Enabled then
        AutoBuyGunToggle:Set(true)
        task.wait(.1)
        Buy_Gun()
    end]]

    task.wait(3)

    FarmMarshmallows_Toggle:Set(true)
end

getgenv().Library = Library 
return Library
end
