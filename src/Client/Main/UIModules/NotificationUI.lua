local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local NotificationUI = {}

function NotificationUI:Init(handler)
	self.Handler = handler
	self.Player = handler.Plr
	self.Initialized = false

	self.NotificationUI = self.Handler.UIContainer.NotificationUI
	self.NotificationContainer = self.NotificationUI.Container
	self.NotificationSkeleton = self.NotificationUI.NotificationSkeleton
end

function NotificationUI:Enable()
	self.NotificationContainer.Visible = true
end

function NotificationUI:Disable()
	self.NotificationContainer.Visible = false

	for _, notif in pairs(self.NotificationContainer:GetChildren()) do
		if notif:IsA("Frame") then
			notif:Destroy()
		end
	end
end

function NotificationUI:Reset()
	self:Disable()
	self:Enable()
end

function NotificationUI:PushNotification(data, accept, reject)
	if not data or not data.message then
		return
	end

	local notif = self.NotificationSkeleton:Clone()

	notif.Message.Text = data.message
	notif.Visible = true
	notif.Parent = self.NotificationContainer

	TweenService:Create(notif, TweenInfo.new(0.4), { Size = UDim2.new(1, 0, 1, 0) }):Play()

	local function closeNotif()
		local closeTween = TweenService:Create(notif, TweenInfo.new(0.4), { Size = UDim2.new(1, 0, 0, 0) })
		closeTween:Play()

		closeTween.Completed:Connect(function()
			notif:Destroy()
		end)
	end

	local acceptConn
	local rejectConn

	acceptConn = notif.Buttons.AcceptBtn.Button.MouseButton1Down:Connect(function()
		accept(notif)
		acceptConn:Disconnect()
		closeNotif()
	end)

	rejectConn = notif.Buttons.RejectBtn.Button.MouseButton1Down:Connect(function()
		reject(notif)
		rejectConn:Disconnect()
		closeNotif()
	end)

	task.delay(10, function()
		--auto close notification after 10 seconds
		if notif and notif.Parent then
			if acceptConn then
				acceptConn:Disconnect()
			end
			if rejectConn then
				rejectConn:Disconnect()
			end

			closeNotif()
		end
	end)

	return notif
end

return NotificationUI
