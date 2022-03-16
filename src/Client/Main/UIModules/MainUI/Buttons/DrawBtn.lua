local TweenService = game:GetService("TweenService")

local DrawBtn = {}

function DrawBtn:Init(handler)
	self.Handler = handler
	self.Initialized = false

	local buttons = self.Handler.Buttons

	self.ButtonFrame = buttons.DrawBtn
    self.ImageButton = self.ButtonFrame.Button
    self.Icon = self.ButtonFrame.Icon

	self.Initialized = true
end

function DrawBtn:Enable()
	self.ButtonFrame.Visible = true

    self.MouseEnterConnection = self.ImageButton.MouseEnter:Connect(function()
      
    end)
    
    self.MouseLeaveConnection = self.ImageButton.MouseLeave:Connect(function()
       
    end)
end

function DrawBtn:Disable()
	self.ButtonFrame.Visible = false

    self.MouseEnterConnection:Disconnect()
    self.MouseLeaveConnection:Disconnect()
end

return DrawBtn
