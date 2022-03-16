local ServerScriptService = game:GetService("ServerScriptService")

local Services = ServerScriptService:WaitForChild("Services")

local Server = {}

function Server:Init()
    
    self.Services = {}

    for _, serviceModule in pairs(Services:GetChildren()) do
        if serviceModule:IsA("ModuleScript") then
            local service = require(serviceModule)
            self.Services[serviceModule.Name] = service
            service:Init()
        end
    end
    
end

return Server
