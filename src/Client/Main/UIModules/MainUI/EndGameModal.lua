local TweenService = game:GetService("TweenService")

local EndGameModal = {}

EndGameModal.EndGameMessages = {
    Win = {
        Text = "You won!",
        Color = Color3.fromRGB(255, 180, 74),
    },
    Loss = {
        Text = "You lost.",
        Color = Color3.fromRGB(255, 79, 67),
    },
    Draw = {
        Text = "Draw",
        Color = Color3.fromRGB(255, 255, 255),
    },
}

EndGameModal.EndGameReasons = {
    Checkmate = {
        Text = "Checkmate",
        Color = Color3.fromRGB(255, 56, 56),
    },
    Stalemate = {
        Text = "Stalemate",
        Color = Color3.fromRGB(255, 214, 147),
    },
}

function EndGameModal:Init(handler)
	self.Handler = handler
	self.Initialized = false

	local mainUI = self.Handler.MainUI

	self.ModalFrame = mainUI.Modal
	self.HeaderText = self.ModalFrame.HeaderText
	self.EndGameMessage = self.ModalFrame.EndGameMessage

    self.Buttons = self.ModalFrame.Buttons
    self.RematchBtn = self.Buttons.RematchBtn
    self.AnalyseBtn = self.Buttons.AnalyseBtn

	self.ModalEnterTween = TweenService:Create(
		self.ModalFrame,
		TweenInfo.new(0.2, Enum.EasingStyle.Quint),
		{ Position = UDim2.new(0.5, 0, 0.5, 0) }
	)
	self.ModalExitTween = TweenService:Create(
		self.ModalFrame,
		TweenInfo.new(0.2, Enum.EasingStyle.Quint),
		{ Position = UDim2.new(0.5, 0, -0.5, 0) }
	)

    self.RematchBtn.Button.MouseButton1Down:Connect(function()
        self.Handler:HandleUIEvent("Rematch")
    end)

	self.Initialized = true
	self.Hidden = true
end

function EndGameModal:Show(data)
	local reasonData = EndGameModal.EndGameReasons[data.reason]
	if reasonData then
		self.HeaderText.Text = reasonData.Text
		self.HeaderText.TextColor3 = reasonData.Color
	end

	local messageType = data.isDraw and "Draw" or (data.playerWon and "Win" or "Loss")
	local endGameMessageData = EndGameModal.EndGameMessages[messageType]

	if endGameMessageData then
		self.EndGameMessage.Text = endGameMessageData.Text
		self.EndGameMessage.TextColor3 = endGameMessageData.Color
	end

	self.ModalFrame.Visible = true
	self.ModalEnterTween:Play()
	self.Hidden = false
end

function EndGameModal:Hide()
	self.Hidden = true
	self.ModalExitTween:Play()

	self.ModalExitTween.Completed:Wait()
	self.ModalFrame.Visible = false
end

function EndGameModal:Disable()
	self.ModalFrame.Position = UDim2.new(0.5, 0, -0.5, 0)
	self.ModalFrame.Visible = false
end

return EndGameModal
