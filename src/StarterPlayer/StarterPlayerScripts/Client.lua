local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local SharedModules = RS:WaitForChild("Modules")
local Board = require(SharedModules:WaitForChild("Board"))

local ClientModules = script.Parent:WaitForChild("Modules")

local Remotes = RS:WaitForChild("Remotes")
local GameEvent = Remotes:WaitForChild("GameEvent")
local ClientUpdate = Remotes:WaitForChild("ClientUpdate")

local Client = {}

function Client.new()
	local self = setmetatable({}, Client)

	self.PlayerObject = Players.LocalPlayer
	self.IsUpdating = false

	GameEvent.OnClientEvent:Connect(function()
		print("Client initializing..")

		--Load board object first
		self.BoardObject = Board.new(true)
		self.BoardObject:Init(workspace.Board)

		--Dynamic module loading
		for _, module in pairs (ClientModules:GetChildren()) do
			if not module:IsA("ModuleScript") then continue end
			
			local moduleName = module.Name

			module = require(module).new()
			self[moduleName] = module
			module:Init(self)
		end
 
 	end)

	ClientUpdate.OnClientEvent:Connect(function(move)
		self.IsUpdating = true

		self.BoardObject:Update(move)

		self.IsUpdating = false
	end)
end

return Client
