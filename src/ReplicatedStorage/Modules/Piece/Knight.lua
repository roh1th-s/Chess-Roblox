local RS = game:GetService("ReplicatedStorage")

local Modules = RS:WaitForChild("Modules")
local Move = require(Modules:WaitForChild("Move"))

local PieceModels = RS:WaitForChild("PieceModels")

local Piece = require(script.Parent)

local insert = table.insert
local char = string.char
local byte = string.byte
local num = tonumber

local Knight = {}
Knight.__index = Knight
setmetatable(Knight,Piece)

function Knight.new(...)
	local self = Piece.new(...)
	setmetatable(self,Knight)
	
	self.Type = "Knight"
	
	if self.isServer then
		local model = PieceModels.Knight:Clone()
		model.Position = self.Spot.Instance.Position + Vector3.new(0,model.Size.Y/2,0)
		--TEMP
		if self.Team == "White" then
			model.CFrame = model.CFrame * CFrame.Angles(0, math.rad(180), 0)
		end
		--
		model.Color = self.Team == "White" and Color3.new(1,1,1) or Color3.new(0,0,0)
		model.Parent = workspace[self.Team]
		
		self.Instance = model
	end
	return self
end

function Knight:GetMoves()
	local moves = {}
	local oppTeam = self:GetOppTeam()
	local number = self.Number
	local Board = self.Board
	local lnum = byte(self.Letter)
	
	local q = number + 2
	
	for i = lnum - 1,lnum + 1 do
		if i ~= lnum then
			local spot = Board:GetSpotObjectAt(char(i), q)
			
			if spot then
				if not spot.Piece or (spot.Piece.Team == oppTeam) then
					local move = Move.new():SetInitSpot(self.Spot):SetTargetSpot(spot)
					insert(moves, move)
				end
			end
		end
	end
	q = number - 2
	
	for i = lnum - 1,lnum + 1 do
		if i ~= lnum then
			local spot = Board:GetSpotObjectAt(char(i), q)
			if spot then
				if not spot.Piece or (spot.Piece.Team == oppTeam) then
					local move = Move.new():SetInitSpot(self.Spot):SetTargetSpot(spot)
					insert(moves, move)
				end
			end
		end
	end
	q = lnum + 2
	
	for i = number - 1,number + 1 do
		if i ~= num(number) then
			local spot = Board:GetSpotObjectAt(char(q), i)
			if spot then
				if not spot.Piece or (spot.Piece.Team == oppTeam) then
					local move = Move.new():SetInitSpot(self.Spot):SetTargetSpot(spot)
					insert(moves, move)
				end
			end
		end
	end
	
	q = lnum - 2
	
	for i = number - 1, number + 1 do
		if i ~= num(number) then
			local spot = Board:GetSpotObjectAt(char(q), i)
			if spot then
				if not spot.Piece or (spot.Piece.Team == oppTeam) then
					local move = Move.new():SetInitSpot(self.Spot):SetTargetSpot(spot)
					insert(moves, move)
				end
			end
		end
	end

	return moves
end

return Knight