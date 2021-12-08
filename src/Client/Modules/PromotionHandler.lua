-- services
local RS = game:GetService("ReplicatedStorage")

local Remotes = RS:WaitForChild("Remotes")
local Promotion = Remotes:WaitForChild("Promotion")

local UIModules = script.Parent.Parent.UIModules
local PromotionUI = require(UIModules:WaitForChild("PromotionUI"))

local PromotionHandler = {}
PromotionHandler.__index = PromotionHandler

function PromotionHandler.new(client)
    local self = setmetatable({}, PromotionHandler)

    self.client = client
    self.plr = client.Player

    return self
end

function PromotionHandler:Init()
    self.PromotionEventConnection = Promotion.OnClientEvent:Connect(function()
        self:HandlePromotion()
    end)

    PromotionUI:Init(self)
end

function PromotionHandler:HandlePromotion()
    print("Promotion")
    self.client.IsPromotion = true

    PromotionUI:Enable()
end

function PromotionHandler:HandlePromotionChoice(promotedPiece)
    Promotion:FireServer(promotedPiece)

    PromotionUI:Disable()

    self.client.IsPromotion = false
end

return PromotionHandler