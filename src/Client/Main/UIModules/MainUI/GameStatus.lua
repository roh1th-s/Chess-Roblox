local TweenService = game:GetService("TweenService")

local GameStatus = {}

GameStatus.Formattings = {
    Check = {
        Color = Color3.fromRGB(255, 115, 73)
    },
    Checkmate = {
        Color = Color3.fromRGB(255, 56, 17)
    },
    Stalemate = {
        Color = Color3.fromRGB(255, 222, 57)
    },
}

function GameStatus:Init(handler)
	self.Handler = handler
	self.Initialized = false

	local mainUI = self.Handler.MainUI

    self.StatusFrame = mainUI.Status
    self.StatusText = self.StatusFrame.Text

	self.Initialized = true
end

function GameStatus:Show()
	self.StatusFrame.Visible = true
end

function GameStatus:Hide()
	self.StatusFrame.Visible = false
end

function GameStatus:SetStatus(status)
    local formatting = self.Formattings[status]

    self.StatusText.Text = status
    self.StatusText.TextColor3 = formatting and formatting.Color or Color3.fromRGB(255, 255, 255)
end

return GameStatus
