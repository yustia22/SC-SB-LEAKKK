local roadsSidewalksFolder = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Roads/Sidewalks")
local opp = {}

local function setHiddenProperty(instance, property, value)
    pcall(function() sethiddenproperty(instance, property, value) end)
end

local function exlusionssf(part)
    return (roadsSidewalksFolder and part:IsDescendantOf(roadsSidewalksFolder)) or
        (part.Name == "default") or (part.Name == "Sidewalk") or (part.Name == "Floor") or
        (part.Name == "Collision") or (part.Name == "QuaterCylinder") or
        part:IsDescendantOf(LocalPlayer.Character) or
        (part.Parent and part.Parent:IsA("Model") and Players:GetPlayerFromCharacter(part.Parent) ~= nil) or
        (part:IsA("VehicleSeat") or part:IsA("Vehicle"))
end

local function updmommy()
    local pp = Camera.CFrame.Position
    local radius = 15
    local region = Region3.new(pp - Vector3.new(radius, radius, radius), pp + Vector3.new(radius, radius, radius))
    local parts = workspace:FindPartsInRegion3(region, nil, math.huge)
    for _, part in ipairs(parts) do
        if part:IsA("BasePart") and not exlusionssf(part) then
            if not opp[part] then
                opp[part] = { CanCollide = part.CanCollide }
                setHiddenProperty(part, "CanCollide", false)
            end
        end
    end
end

local function resetNoclip()
    for part, props in pairs(opp) do
        if part:IsA("BasePart") then
            setHiddenProperty(part, "CanCollide", props.CanCollide)
        end
    end
    opp = {}
end

-- UI Noclip
visualsSection:toggle({
    name = "Noclip (Tembus Dinding)",
    def = false,
    callback = function(enabled)
        noclipEnabled = enabled
        if noclipEnabled then
            task.spawn(function()
                while noclipEnabled do
                    updmommy()
                    task.wait(0.1)
                end
            end)
        else
            resetNoclip()
        end
    end
})
