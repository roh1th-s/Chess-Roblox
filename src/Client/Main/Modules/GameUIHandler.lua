-- services
local RS = game:GetService("ReplicatedStorage")

local Remotes = RS:WaitForChild("Remotes")
local PromotionEvent = Remotes:WaitForChild("Promotion")

local UIModules = script.Parent.Parent.UIModules:GetChildren()

local GameUIHandler = {}
GameUIHandler.__index = GameUIHandler

function GameUIHandler:Init(client)
    self.Client = client
    self.Plr = client.Player
    self.PlrGui = self.Plr:WaitForChild("PlayerGui")
    self.UIContainer = self.PlrGui.UI

    self.Modules = {}

    for _, uiModule in pairs(UIModules) do
		self.Modules[uiModule.Name] = require(uiModule)
		self.Modules[uiModule.Name]:Init(self)
	end
end

function GameUIHandler:HandlePromotion()
    self.Modules.PromotionUI:Enable()
end

function GameUIHandler:HandlePromotionChoice(promotedPiece)
    PromotionEvent:FireServer(promotedPiece)

    self.Modules.PromotionUI:Disable()

    self.Client.IsPromotion = false
end

function GameUIHandler:UpdateStatus(data)
    if not data then warn("No data passed to GameUIHandler:UpdateStatus") return end
    local message = data.message
    
    --if message == "Check" then
        self.Modules.MainUI:SetStatus(message)
    --end
end

function GameUIHandler:ShowNotification(data)
    self.Modules.NotificationUI:PushNotification(data, function()
        if data.uiEvent then
            self.Client:HandleUIEvent(data.uiEvent)
        end
        
    end, function()
        -- handle notification reject
    end)
end

function GameUIHandler:ResetUI()
    for _, module in pairs(self.Modules) do
        if module.Reset then
            module:Reset()
        end
    end
end

function GameUIHandler:EndGame(endData)
    self.Modules.MainUI:ShowEndGameModal(endData)
end

function GameUIHandler:HandleUIEvent(eventName, data)
    self.Client:HandleUIEvent(eventName, data)
end

return GameUIHandler