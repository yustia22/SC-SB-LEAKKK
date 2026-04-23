local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function isUUID(name)
    if typeof(name) ~= "string" then return false end
    local pattern = "^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$"
    return string.match(name, pattern) ~= nil
end

local function blockRemote(remote)
    if not hookfunction then
        warn("Your executor does not support hookfunction. Cannot block remote: " .. remote.Name)
        remote:Destroy()
        return
    end
    
    local oldFireServer
    oldFireServer = hookfunction(remote.FireServer, function(self, ...)
        if self == remote then
            warn("Blocked FireServer attempt on UUID anti-cheat remote: " .. remote.Name .. " | Args: " .. tostring(...))
            return
        end
        return oldFireServer(self, ...)
    end)
    
    print("Blocked UUID remote: " .. remote.Name)
end

local function scanRemotes()
    for _, child in ipairs(ReplicatedStorage:GetChildren()) do
        if child:IsA("RemoteEvent") and isUUID(child.Name) then
            blockRemote(child)
        end
    end
end

scanRemotes()

ReplicatedStorage.ChildAdded:Connect(function(child)
    if child:IsA("RemoteEvent") and isUUID(child.Name) then
        blockRemote(child)
    end
end)

while true do
    scanRemotes()
    wait()
end
