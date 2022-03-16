local RS = game:GetService("ReplicatedStorage")
local TS = game:GetService("TweenService")
local PieceModels = RS:WaitForChild("PieceModels")

local Modules = RS:WaitForChild("Modules")
local PieceTween = require(Modules:WaitForChild("PieceTween"))
local Move = require(Modules:WaitForChild("Move"))
local Piece = require(script.Parent)

local PieceClasses = {
	Rook = require(script.Parent.Rook),
	Knight = require(script.Parent.Knight),
	Bishop = require(script.Parent.Bishop),
	Queen = require(script.Parent.Queen),
}

local insert = table.insert
local remove = table.remove
local char = string.char
local byte = string.byte
local num = tonumber

local Pieces = {
	Black = workspace.Black,
	White = workspace.White,
}

local Pawn = {}
Pawn.__index = Pawn
setmetatable(Pawn, Piece)

function Pawn.new(...)
	local self = Piece.new(...)
	setmetatable(self, Pawn)

	self.Type = "Pawn"
	self.CanBeKilledByEnPassant = false

	if self.isServer then
		local model = PieceModels.Pawn:Clone()
		model.Position = self.Spot.Instance.Position + Vector3.new(0, model.Size.Y / 2, 0)
		--TEMP
		if self.Team == "White" then
			model.CFrame = model.CFrame * CFrame.Angles(0, math.rad(180), 0)
		end
		--
		model.Color = self.Team == "White" and Color3.new(1, 1, 1) or Color3.new(0, 0, 0)
		model.Parent = workspace[self.Team]

		self.Instance = model
	end

	return self
end

--function Pawn:MoveTo(letter,number)
--TODO Implement
--end

function Pawn:GetMoves(options)
	local moves = {}
	local factor, startn
	local oppTeam = self:GetOppTeam()
	local lnum = byte(self.Letter)

	local onlyAttacks, bypassCheckCondition
	if options then
		onlyAttacks = options.onlyAttacks or false
		bypassCheckCondition = options.bypassCheckCondition or false
	end

	if self.Team == "Black" then
		factor = -1
		startn = 7
	else
		factor = 1
		startn = 2
	end

	if not onlyAttacks then
		for n = self.Number + factor, (num(self.Number) == startn) and self.Number + (factor * 2) or self.Number + factor, factor do
			local spot = self.Board:GetSpotObjectAt(self.Letter .. n)
			if spot then
				if not spot.Piece then
					local move = Move.new():SetInitSpot(self.Spot):SetTargetSpot(spot)
					insert(moves, move)
				else
					break
				end
			end
		end
	end

	for i = lnum - factor, lnum + factor, factor * 2 do
		local spot = self.Board:GetSpotObjectAt(char(i) .. self.Number + factor)

		if spot then
			local move = Move.new():SetInitSpot(self.Spot):SetTargetSpot(spot)
			if onlyAttacks then
				--For pawns the attacks should be added even though there is no piece at the target
				insert(moves, move)
				continue
			end

			if spot.Piece and (spot.Piece.Team == oppTeam) then
				insert(moves, move)
			else
				--En Passant
				local spotOnSide = self.Board:GetSpotObjectAt(char(i) .. self.Number)
				local pieceOnSide = spotOnSide.Piece

				local lastMove = self.Board:GetLastMove()
				local lastMoveTargetSpot = self.Board:GetSpotObjectAt(
					lastMove.TargetPosLetter,
					lastMove.TargetPosNumber
				)
				local lastMoveWasPawnMove = (lastMoveTargetSpot == spotOnSide)

				if
					pieceOnSide
					and (pieceOnSide.Team == oppTeam)
					and pieceOnSide.Type == "Pawn"
					and pieceOnSide.CanBeKilledByEnPassant
					and lastMoveWasPawnMove
				then
					move:SetEnPassant(true, spotOnSide)
					insert(moves, move)
				end
			end
		end
	end

	if not bypassCheckCondition then
		self:FilterLegalMoves(moves)
	end

	return moves
end

function Pawn:EnPassant(pawnToBeCaptured, targetSpot, options)
	local simulatedMove = options and options.simulatedMove or false

	if not pawnToBeCaptured or not targetSpot then
		warn("Error : Incorrect arguments to en passant function.")
	end

	local initSpot = self.Spot
	local otherPawnSpot = pawnToBeCaptured.Spot

	initSpot:SetPiece(nil)
	otherPawnSpot:SetPiece(nil)
	targetSpot:SetPiece(self)

	self:SetSpot(targetSpot)

	self.MovesMade += 1

	pawnToBeCaptured.Captured = true
	pawnToBeCaptured:SetSpot(nil)

	if not simulatedMove then
		if self.isServer then
			pawnToBeCaptured.Instance.Parent = workspace:WaitForChild("Captured" .. pawnToBeCaptured.Team)
		else
			PieceTween.AnimatePieceMove(self.Instance, targetSpot.Instance)

			PieceTween.AnimatePieceCapture(pawnToBeCaptured)

			return true -- no need to do the rest if on client
		end
	end

	local move = Move.new()
		:SetInitSpot(initSpot)
		:SetTargetSpot(targetSpot)
		:SetMovedPiece(self)
		:SetCapturedPiece(pawnToBeCaptured)
		:SetEnPassant(true, otherPawnSpot)

	return move
end

function Pawn:Promote(promotedPiece, targetSpot, options)
	local simulatedMove, newPieceInstance

	if options then
		simulatedMove = options.simulatedMove or false
		newPieceInstance = options.newPieceInstance or false
	end

	local initSpot = self.Spot

	local initOccupyingPiece = targetSpot.Piece

	if initOccupyingPiece then
		initOccupyingPiece.Captured = true

		initOccupyingPiece:SetSpot(nil)
	end

	initSpot:SetPiece(nil)
	targetSpot:SetPiece(self)

	self.Type = promotedPiece
	self.Promoted = true
	self:SetSpot(targetSpot)
	setmetatable(self, PieceClasses[promotedPiece])

	self.MovesMade += 1

	if not simulatedMove then
		if self.isServer then
			self.Instance:Destroy()
			local model = PieceModels[promotedPiece]:Clone()
			model.Position = initSpot.Instance.Position + Vector3.new(0, model.Size.Y / 2, 0)
			--TEMP
			if self.Team == "White" then
				model.CFrame = model.CFrame * CFrame.Angles(0, math.rad(180), 0)
			end
			--
			model.Color = self.Team == "White" and Color3.new(1, 1, 1) or Color3.new(0, 0, 0)
			model.Parent = Pieces[self.Team]

			self.Instance = model

			if initOccupyingPiece then
				initOccupyingPiece.Instance.Parent = workspace:WaitForChild("Captured" .. initOccupyingPiece.Team)
			end
		else
			if not newPieceInstance then
				warn("[Promotion] New piece instance is nil. Cannot set the instance property of the new piece!")
			end
	
			self.Instance = newPieceInstance or nil

			PieceTween.AnimatePieceMove(self.Instance, targetSpot.Instance)

			if initOccupyingPiece then
				PieceTween.AnimatePieceCapture(initOccupyingPiece)
			end
			
			return true -- no need to do the rest if on client
		end
	end
	
	local move = Move.new()
		:SetInitSpot(initSpot)
		:SetTargetSpot(targetSpot)
		:SetMovedPiece(self)
		:SetCapturedPiece(initOccupyingPiece)
		:SetPromotion(true, promotedPiece, self.Instance)

	return move
end

return Pawn
