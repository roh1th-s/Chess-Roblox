local TweenService = game:GetService("TweenService")

-- modules are under this script
local ButtonModules = script:GetChildren()

local Buttons = {}

function Buttons:Init(handler)
	self.Handler = handler
	self.Initialized = false

	local mainUI = self.Handler.MainUI

	self.Buttons = mainUI.Buttons
	self.ButtonModules = {}

	for _, buttonModule in pairs(ButtonModules) do
		self.ButtonModules[buttonModule.Name] = require(buttonModule)
		self.ButtonModules[buttonModule.Name]:Init(self)
	end

	self.Initialized = true
end

function Buttons:Enable()
	self.Buttons.Visible = true

	for _, buttonModule in pairs(self.ButtonModules) do
		buttonModule:Enable()
	end
end

function Buttons:Disable()
	self.Buttons.Visible = false

	for _, buttonModule in pairs(self.ButtonModules) do
		buttonModule:Disable()
	end
end


function Buttons:HandleUIEvent(eventName, data)
	self.Handler:HandleUIEvent(eventName, data)
end

return Buttons
