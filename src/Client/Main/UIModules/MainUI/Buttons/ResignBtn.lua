local TweenService = game:GetService("TweenService")

local ResignBtn = {}

function ResignBtn:Init(handler)
	self.Handler = handler
	self.Initialized = false

	local buttons = self.Handler.Buttons

	self.ButtonFrame = buttons.ResignBtn
    self.ImageButton = self.ButtonFrame.Button
    self.Icon = self.ButtonFrame.Icon

    self.FlagTipForwardTween = TweenService:Create(self.Icon, TweenInfo.new(0.2), {Rotation = 12})
    self.FlagTipBackTween = TweenService:Create(self.Icon, TweenInfo.new(0.2), {Rotation = -10})
    
    self.IconReddenTween = TweenService:Create(self.Icon, TweenInfo.new(0.2), {ImageColor3 = Color3.fromRGB(255, 92, 92)})
    self.IconWhitenTween = TweenService:Create(self.Icon, TweenInfo.new(0.2), {ImageColor3 = Color3.new(1,1,1)})

    self.FlagTipped = false

	self.Initialized = true
end

function ResignBtn:Enable()
	self.ButtonFrame.Visible = true

    self.MouseEnterConnection = self.ImageButton.MouseEnter:Connect(function()
        self.FlagTipped = true
        
        self.FlagTipBackTween:Pause()
        self.IconWhitenTween:Pause()
        self.IconReddenTween:Play()
        self.FlagTipForwardTween:Play()
    end)
    
    self.MouseLeaveConnection = self.ImageButton.MouseLeave:Connect(function()
        self.FlagTipped = false
        
        self.FlagTipForwardTween:Pause()
        self.IconReddenTween:Pause()
        self.IconWhitenTween:Play()
        self.FlagTipBackTween:Play()
    end)
end

function ResignBtn:Disable()
	self.ButtonFrame.Visible = false

    self.MouseEnterConnection:Disconnect()
    self.MouseLeaveConnection:Disconnect()
end

return ResignBtn
