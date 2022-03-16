local SubModules = script:GetChildren()

local MainUI = {}

function MainUI:Init(handler)
	self.Handler = handler
	self.Player = handler.plr
	self.Initialized = false

	local UIContainer = self.Handler.UIContainer
	self.MainUI = UIContainer.MainUI

	self.Modules = {}

	for _, subModule in pairs(SubModules) do
		self.Modules[subModule.Name] = require(subModule)
		self.Modules[subModule.Name]:Init(self)
	end

	self:Enable()

	self.Initialized = true
end

function MainUI:Enable()
	self.MainUI.Enabled = true

	for _, subModule in pairs(self.Modules) do
		if subModule.Enable then
			subModule:Enable()
		end
	end
end

function MainUI:Disable()
	self.MainUI.Enabled = false

	for _, subModule in pairs(self.Modules) do
		if subModule.Disable then
			subModule:Disable()
		end
	end
end

function MainUI:Reset()
	self.Modules.EndGameModal:Hide()
end

function MainUI:SetStatus(...)
	self.Modules.GameStatus:SetStatus(...)
end

function MainUI:ShowEndGameModal(endData)
	self.Modules.EndGameModal:Show(endData)
end

function MainUI:HandleUIEvent(eventName, data)
	self.Handler:HandleUIEvent(eventName, data)
end

return MainUI
