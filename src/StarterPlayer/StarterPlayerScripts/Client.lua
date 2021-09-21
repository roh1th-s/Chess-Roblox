local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local SharedModules = RS:WaitForChild("Modules")
local Board = require(SharedModules:WaitForChild("Board"))

local ClientModules = script.Parent:WaitForChild("Modules")
local InputHandler = require(ClientModules:WaitForChild("InputHandler"))
local ChessCamera = require(ClientModules:WaitForChild("ChessCamera"))

local Remotes = RS:WaitForChild("Remotes")
local GameEvent = Remotes:WaitForChild("GameEvent")
local ClientUpdate = Remotes:WaitForChild("ClientUpdate")

local Client = {}

function Client.new()
	local self = setmetatable({}, Client)

	self.PlayerObject = Players.LocalPlayer
	self.IsUpdating = false

	ChessCamera.new():Init()

	GameEvent.OnClientEvent:Connect(function()
		print("Client initializing..")
		self.BoardObject = Board.new(true)
		self.BoardObject:Init(workspace.Board)

		self.InputHandler = InputHandler.new()
		self.InputHandler:Initialize(self)
	end)

	ClientUpdate.OnClientEvent:Connect(function(move)
		self.IsUpdating = true

		self.BoardObject:Update(move)

		self.IsUpdating = false
	end)
end

return Client
