local RS = game:GetService("ReplicatedStorage")
local TS = game:GetService("TweenService")
local PieceModels = RS:WaitForChild("PieceModels")

local Modules = RS:WaitForChild("Modules")
local Config = require(Modules:WaitForChild("Config"))
local Move = require(Modules:WaitForChild("Move"))
local Piece = require(script.Parent)

local Remotes = RS:WaitForChild("Remotes")
local OnClientTween = Remotes:WaitForChild("OnClientTween")

local insert = table.insert
local char = string.char
local byte = string.byte
local num = tonumber

local Pawn = {}
Pawn.__index = Pawn
setmetatable(Pawn,Piece)

function Pawn.new(...)
	local self = Piece.new(...)
	setmetatable(self,Pawn)

	self.Type = "Pawn"
	self.CanBeKilledByEnPassant = false

	if self.isServer then
		local model = PieceModels.Pawn:Clone()
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

--function Pawn:MoveTo(letter,number)
--TODO Implement
--end

function Pawn:GetMoves(onlyAttacks)
	local moves = {}
	local factor,startn
	local oppTeam = self:getOppTeam()
	local lnum = byte(self.Letter)

	if self.Team == "Black" then
		factor = -1
		startn = 7
	else
		factor = 1
		startn = 2
	end
	
	if not onlyAttacks then
		for n = self.Number + factor, (num(self.Number) == startn) and self.Number + (factor * 2) or self.Number + factor, factor do
			local spot = self.Board:GetSpotObjectAt(self.Letter..n)
			if spot then
				if not spot.Piece then
					insert(moves,spot)
				else 
					break
				end
			end
		end
	end

	for i = lnum - factor, lnum + factor, factor do
		if i ~= lnum then
			local spot = self.Board:GetSpotObjectAt(char(i)..self.Number + factor)
			if spot then
				if onlyAttacks then
					--For pawns the attacks should be added even though there is no piece at the target
					insert(moves, spot)
					continue
				end
				if spot.Piece and (spot.Piece.Team == oppTeam) then
					insert(moves,spot)
				end
			end
		end
	end
	--En Passant
	
	local spot_s = {(char(lnum + 1)..self.Number) , (char(lnum - 1)..self.Number)}
	for _, spot_coord in pairs(spot_s) do
		local spot = self.Board:GetSpotObjectAt(spot_coord);
		if not spot then continue end
		local piece = spot.Piece
		--print(piece)
		local lastMove = self.Board:GetLastMove()
		local lastMoveTargetSpot = self.Board:GetSpotObjectAt(lastMove.targetPosLetter, lastMove.targetPosNum)
		local lastMoveWasPawnMove = (lastMoveTargetSpot == spot)
		
		if piece and piece.Type == "Pawn" and piece.CanBeKilledByEnPassant and lastMoveWasPawnMove then
			if onlyAttacks then
				insert(moves, spot)
			else
				local spotBehindEnemyPawn = self.Board:GetSpotObjectAt(spot.Letter, spot.Number + (1 * factor));
				insert(moves, spotBehindEnemyPawn)
			end		
		end
	end

	return moves
end

function Pawn:EnPassant(pawnToBeCaptured, targetSpot)
	if not pawnToBeCaptured or not targetSpot then
		warn("Error : Incorrect arguments to en passant function.")
	end
	
	local initSpot = self.Spot
	local otherPawnSpot = pawnToBeCaptured.Spot
	
	initSpot:SetPiece(nil)
	otherPawnSpot:SetPiece(nil)
	targetSpot:SetPiece(self)
	
	self.Spot = targetSpot
	self.Number = targetSpot.Number
	self.Letter = targetSpot.Letter

	self.HasMoved = true
	
	pawnToBeCaptured.Captured = true
	pawnToBeCaptured.Spot = nil			
	pawnToBeCaptured.Number = nil
	pawnToBeCaptured.Letter = nil
	
	if self.isServer then	
		pawnToBeCaptured.Instance.Parent = workspace:WaitForChild("Captured" .. pawnToBeCaptured.Team)
	else
		local tweenDuration = Config.PieceTween.Duration
		local tweenEasingStyle = Config.PieceTween.EasingStyle

		local Offset = (self.Instance.Size.Y/2) + (targetSpot.Instance.Size.Y/2)
		local Pos = targetSpot.Instance.Position + Vector3.new(0,Offset,0)
		local tween = TS:Create(self.Instance,TweenInfo.new(tweenDuration, tweenEasingStyle),{Position = Pos})
		
		task.spawn(function()
			tween:Play()
			tween.Completed:Wait(5)

			OnClientTween:FireServer(self.Instance, Pos)
		end)
		
		return true -- no need to do the rest if on client
	end

	local move = Move.new()
	:setInitPos(initSpot.Letter , initSpot.Number)
	:setTargetPos(targetSpot.Letter , targetSpot.Number)
	:setMovedPiece(self)
	:setCapturedPiece(pawnToBeCaptured)
	:setEnPassant(true)

	return move
end

return Pawn