-- services
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Remotes = RS:WaitForChild("Remotes")
local Promotion = Remotes:WaitForChild("Promotion")

local PromotionHandler = {}
PromotionHandler.__index = PromotionHandler

function PromotionHandler.new()
    local self = setmetatable({}, PromotionHandler)

    self.plr = Players.LocalPlayer
    self.teamName = self.plr.Team.Name

    self.plrGUI = self.plr:WaitForChild("PlayerGui")
    self.UI = self.plrGUI.UI
    self.promotionUiFrame = self.UI.PromotionUI.PromotionFrame

    self.whitePieceOptionsFrame = self.promotionUiFrame.WhiteOptions
    self.blackPieceOptionsFrame = self.promotionUiFrame.BlackOptions

    self.buttons = {
        White = self.whitePieceOptionsFrame.Buttons:GetChildren(),
        Black = self.blackPieceOptionsFrame.Buttons:GetChildren()
    }

    return self
end

function PromotionHandler:Init()
    self.PromotionEventConnection = Promotion.OnClientEvent:Connect(function()
        self:HandlePromotion()
    end)

    --[[ TODO Create event listeners only for your team buttons (But ideally, there should be a common set of
        buttons with the pieces being loaded in based on ur current team. Should implement this later)
    ]]
    for _, teamButtons in pairs(self.buttons) do
        for _, button in pairs(teamButtons) do
            button.MouseButton1Click:Connect(function()
                self:HandlePromotionChoice(button.Name)
            end)
        end
    end
end

function PromotionHandler:HandlePromotion()
    print("Promotion")

    -- TODO implement this in a better way
    local teamName = string.lower(self.plr.Team.Name)

    -- TODO need to improve layout of ui
    self.promotionUiFrame.Visible = true
    self[teamName .. "PieceOptionsFrame"].Visible = true
    self[teamName .. "PieceOptionsFrame"]["3DRotation"].Disabled = false
end

function PromotionHandler:HandlePromotionChoice(promotedPiece)
    -- TODO implement this in a better way
    local teamName = string.lower(self.plr.Team.Name)

    Promotion:FireServer(promotedPiece)
    self.promotionUiFrame.Visible = false
    self[teamName .. "PieceOptionsFrame"].Visible = false
    self[teamName .. "PieceOptionsFrame"]["3DRotation"].Disabled = true
end

return PromotionHandler