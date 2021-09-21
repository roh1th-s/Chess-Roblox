local RS = game:GetService("ReplicatedStorage")

local Modules = RS:WaitForChild("Modules")
local Move = require(Modules:WaitForChild("Move"))

local PieceModels = RS:WaitForChild("PieceModels")

local Piece = require(script.Parent)

local insert = table.insert
local char = string.char
local byte = string.byte

local Rook = {}
Rook.__index = Rook
setmetatable(Rook,Piece)

function Rook.new(...)
	local self = Piece.new(...)
	setmetatable(self,Rook)
	
	self.Type = "Rook"

	if self.isServer then
		local model = PieceModels.Rook:Clone()
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

--function Rook:MoveTo(letter,number)
	--TODO Implement
--end

function Rook:GetMoves() 
	local moves = {} --oppTeam is temporary
	local MovesBtwn = {}
	local TempMoves = {}
	local oppTeam = self:GetOppTeam()
	local Board = self.Board
	local lnum = byte(self.Letter)

	for i = self.Number + 1, 8 do
		local spot = Board:GetSpotObjectAt(self.Letter, i)
		
		if spot then
			local move = Move.new():SetInitSpot(self.Spot):SetTargetSpot(spot)
			if not spot.Piece then
				insert(moves,move)
				--insert(TempMoves,spot)
			else
				if spot.Piece.Team == oppTeam then
					insert(moves,move)
					--if occ.Name == "King" then
					--	MovesBtwn = TempMoves
					--end
				end
				break
			end
		end
	end
	
	TempMoves = {}
	
	for i = self.Number - 1, 1, -1 do
		local spot = Board:GetSpotObjectAt(self.Letter, i)
		
		if spot then
			local move = Move.new():SetInitSpot(self.Spot):SetTargetSpot(spot)
			if not spot.Piece then
				insert(moves,move)
				--insert(TempMoves,spot)
			else
				if spot.Piece.Team == oppTeam then
					insert(moves,move)
					--if occ.Name == "King" then
					--	MovesBtwn = TempMoves
					--end
				end
				break
			end
		end
	end
	
	TempMoves = {}
	
	for i = lnum - 1, 65, -1 do
		local spot = Board:GetSpotObjectAt(char(i), self.Number)
		
		if spot then
			local move = Move.new():SetInitSpot(self.Spot):SetTargetSpot(spot)
			if not spot.Piece then
				insert(moves,move)
				--insert(TempMoves,spot)
			else
				if spot.Piece.Team == oppTeam then
					insert(moves,move)
					--if occ.Name == "King" then
					--	MovesBtwn = TempMoves
					--end
				end
				break
			end
		end
	end
	
	TempMoves = {}
	
	for i = lnum + 1, 72 do
		local spot = Board:GetSpotObjectAt(char(i), self.Number)
		
		if spot then
			local move = Move.new():SetInitSpot(self.Spot):SetTargetSpot(spot)
			if not spot.Piece then
				insert(moves,move)
				--insert(TempMoves,spot)
			else
				if spot.Piece.Team == oppTeam then
					insert(moves,move)
					--if occ.Name == "King" then
					--	MovesBtwn = TempMoves
					--end
				end
				break
			end
		end
	end
	return moves    --,MovesBtwn
end

return Rook