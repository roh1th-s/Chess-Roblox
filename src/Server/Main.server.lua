local RS = game:GetService("ReplicatedStorage")

local Modules = RS:WaitForChild("Modules")
local ChessGame = require(Modules:WaitForChild("ChessGame"))

local runningGame = ChessGame.new()
