local RS = game:GetService("ReplicatedStorage")

local Modules = script.Parent
local Piece = Modules.Piece

local Spot = require(script.Parent.Spot)

local PieceClasses = {
	Pawn = require(Piece.Pawn),
	Rook = require(Piece.Rook),
	Knight = require(Piece.Knight),
	Bishop = require(Piece.Bishop),
	Queen = require(Piece.Queen),
	King = require(Piece.King),
}

local Remotes = RS:WaitForChild("Remotes")
local getPieceSpotDictionary = Remotes:WaitForChild("GetPieceSpotDictionary")

local char = string.char
local byte = string.byte
local insert = table.insert
local remove = table.remove
local find = table.find
local toNum = tonumber

local _INIT_POSITIONS = {
	["A8"] = "Rook",
	["B8"] = "Knight",
	["C8"] = "Bishop",
	["D8"] = "Queen",
	["E8"] = "King",
	["F8"] = "Bishop",
	["G8"] = "Knight",
	["H8"] = "Rook",
	["A7"] = "Pawn",
	["B7"] = "Pawn",
	["C7"] = "Pawn",
	["D7"] = "Pawn",
	["E7"] = "Pawn",
	["F7"] = "Pawn",
	["G7"] = "Pawn",
	["H7"] = "Pawn",

	["A2"] = "Pawn",
	["B2"] = "Pawn",
	["C2"] = "Pawn",
	["D2"] = "Pawn",
	["E2"] = "Pawn",
	["F2"] = "Pawn",
	["G2"] = "Pawn",
	["H2"] = "Pawn",
	["A1"] = "Rook",
	["B1"] = "Knight",
	["C1"] = "Bishop",
	["D1"] = "Queen",
	["E1"] = "King",
	["F1"] = "Bishop",
	["G1"] = "Knight",
	["H1"] = "Rook",
}

local RangedPieces = { "Queen", "Rook", "Bishop" }

--Private

local ChessBoard = {}
ChessBoard.__index = function(table, index)
	if ChessBoard[index] then
		return ChessBoard[index]
	end
	return nil
end

function ChessBoard.new(isClient, currentGame)
	local self = {}
	setmetatable(self, ChessBoard)

	self.Game = currentGame

	self.Spots = {}
	self.Kings = {}
	self.WhitePieces = {}
	self.BlackPieces = {}

	self.LastMove = nil
	self.LastSimulatedMove = nil

	if isClient then
		self.isServer = false
		self.pieceSpotDictionary = getPieceSpotDictionary:InvokeServer()
	else
		self.isServer = true
	end

	return self
end

function ChessBoard:CreatePiece(spot)
	local PieceName = _INIT_POSITIONS[spot.Instance.Name]
	local PieceObject, team

	local number = tonumber(spot.Number)
	if number == 1 or number == 2 then
		team = "White"
	else
		team = "Black"
	end

	PieceObject = PieceClasses[PieceName].new(spot, team, self.isServer)

	if PieceName == "King" then
		self.Kings[team] = PieceObject
	end

	if not self.isServer then
		PieceObject.Instance = self.pieceSpotDictionary[spot.Letter .. spot.Number]
	end

	insert(self[team .. "Pieces"], PieceObject)

	return PieceObject
end

function ChessBoard:Init(BoardModel)
	for _, tile in pairs(BoardModel:GetChildren()) do
		local coordinateString = tile.Name
		local coordinates = coordinateString:split("")
		local letter = coordinates[1]
		local number = coordinates[2]

		local spot = Spot.new(letter, number, nil, tile, self)

		if _INIT_POSITIONS[coordinateString] then
			spot.Piece = self:CreatePiece(spot)
		end

		self.Spots[coordinateString] = spot
	end
end

function ChessBoard:MakeMove(initSpotCoordinates, targetSpotCoordinates, options)
	local simulatedMove = false

	if options then
		simulatedMove = options.simulatedMove or false
	end

	local move = nil

	local piece = self:GetPieceObjectAtSpot(initSpotCoordinates[1], initSpotCoordinates[2])
	assert(piece, "There is no piece on the initial square!")

	local letterDiffFromTargetSpot = byte(targetSpotCoordinates[1]) - byte(piece.Letter)
	local absoluteLetterDiff = math.abs(letterDiffFromTargetSpot)
	local isNegative = (letterDiffFromTargetSpot ~= absoluteLetterDiff)

	--local numberDiffFromTargetSpot = targetSpotCoordinates[2] - piece.Number
	local absoluteNumberDiff = math.abs(letterDiffFromTargetSpot)

	--Castling checks
	if piece.Type == "King" and piece.MovesMade == 0 and absoluteLetterDiff == 2 then
		print("Castling..")
		local rookLetter = isNegative and "A" or "H"
		local associatedRook = self:GetPieceObjectAtSpot(rookLetter .. piece.Number)
		move = piece:Castle(associatedRook, { simulatedMove = simulatedMove })
	end

	--Pawn special move Checks
	if piece.Type == "Pawn" then
		if absoluteNumberDiff == 1 and absoluteLetterDiff == 1 then
			local pieceAtTargetSpot = self:GetPieceObjectAtSpot(targetSpotCoordinates[1], targetSpotCoordinates[2])
			local pieceOnSide = self:GetPieceObjectAtSpot(
				char(byte(piece.Letter) + letterDiffFromTargetSpot),
				piece.Number
			)
			local pieceOnSideIsPawn = pieceOnSide and (pieceOnSide.Type == "Pawn") or nil

			if not pieceAtTargetSpot and pieceOnSideIsPawn then
				local targetSpot = self:GetSpotObjectAt(targetSpotCoordinates[1], targetSpotCoordinates[2])
				move = piece:EnPassant(pieceOnSide, targetSpot, { simulatedMove = simulatedMove })
			end
		end

		local lastRankForTeam = piece.Team == "White" and "8" or "1"
		if targetSpotCoordinates[2] == lastRankForTeam then
			--For now the promoted piece while simulating a move can be anything really, but this needs to be
			--changed later if and when an ai is implemented.
			local promotedPiece = simulatedMove and "Queen" or self.Game:PromptPromotion(piece.Team)

			local targetSpot = self:GetSpotObjectAt(targetSpotCoordinates[1], targetSpotCoordinates[2])
			move = piece:Promote(promotedPiece, targetSpot, { simulatedMove = simulatedMove })
			print("Pawn promoted to " .. promotedPiece)
		end
	end

	if not move then
		move = piece:MoveTo(targetSpotCoordinates[1], targetSpotCoordinates[2], { simulatedMove = simulatedMove })
	end

	if simulatedMove then
		self.LastSimulatedMove = move
		--dont do the rest if its a simulated move.
		return move
	else
		self.LastMove = move
	end

	local oppTeam = piece:GetOppTeam()

	local attacks = self:IsCheck(oppTeam, true)
	if attacks then
		--If it's a check
		print("Check")
		local checkmate = self:IsCheckmate(oppTeam, attacks)

		if checkmate then
			print("Checkmate")
		end
	else
		--If it's not a check

		local stalemate = self:IsStalemate(oppTeam)

		if stalemate then
			print("Stalemate")
		end
	end

	return move
end

function ChessBoard:SimulateMove(initSpotCoordinates, targetSpotCoordinates)
	return self:MakeMove(initSpotCoordinates, targetSpotCoordinates, { simulatedMove = true })
end

function ChessBoard:WillMoveCauseCheck(initSpotCoordinates, targetSpotCoordinates)
	local isCheck = false

	local move = self:SimulateMove(initSpotCoordinates, targetSpotCoordinates)

	if self:IsCheck(move.MovedPiece.Team) then
		isCheck = true
	end

	self:UndoLastSimulatedMove()

	return isCheck
end

function ChessBoard:IsCheck(team, returnAttacks)
	local King = self.Kings[team]
	local KingSpot = King.Spot

	return self:IsSpotUnderAttack(King.Team, KingSpot.Letter, KingSpot.Number, returnAttacks)
end

function ChessBoard:IsCheckmate(team, attacks)
	local King = self.Kings[team]
	local KingSpot = King.Spot

	-- if there are 2 or more attacking pieces, the only way to get out of check is by moving the king.
	if #attacks > 1 then
		local kingMoves = King:GetMoves()

		--if the king can make a legal move, its not checkmate
		if #kingMoves > 0 then
			return false
		end
	else
		local attack = attacks[1]
		local attackType = attack.AttackType
		local initSpotLetter = attack.InitSpotLetter
		local initSpotNumber = attack.InitSpotNumber

		for _, piece in pairs(self[team .. "Pieces"]) do
			if piece.Captured then
				continue
			end
			
			for _, move in pairs(piece:GetMoves()) do
				--if its a ranged piece, check if we have any piece that can be interposed between the king and attacker.
				if piece.Spot.Instance.Name == "H6" then
					print(move)
				end
				
				if attackType == "Ranged" then
					local number = toNum(move.TargetPosNumber)
					local kingSpotNumber = toNum(KingSpot.Number)

					local letterCode = byte(move.TargetPosLetter)
					local initSpotLetterCode = byte(initSpotLetter)
					local kingSpotLetterCode = byte(KingSpot.Letter)
					local minLetter, maxLetter = findMinAndMax(initSpotLetterCode, kingSpotLetterCode)

					if minLetter <= letterCode and letterCode <= maxLetter then
						local minNumber, maxNumber = findMinAndMax(number, kingSpotNumber)
						if minNumber <= number and number <= maxNumber then
							return false
						end
					end
				else
					--if its not a ranged piece, see if we can directly capture the attacker.
					if move.TargetPosLetter == initSpotLetter and move.TargetPosNumber == initSpotNumber then
						return false
					end
				end
			end
		end
	end

	return true
end

function ChessBoard:IsStalemate(team)
	for _, piece in pairs(self[team .. "Pieces"]) do
		if piece.Captured then continue end
		if #piece:GetMoves() > 0 then
			return false
		end
	end

	return true
end

function ChessBoard:GetLastMove()
	return self.LastMove or {}
end

function ChessBoard:GetLastSimulatedMove()
	return self.LastSimulatedMove or {}
end

--TODO Implement an undo move (later sometime...maybe)
function ChessBoard:UndoLastMove()
	local move = self.LastMove
end

function ChessBoard:UndoLastSimulatedMove()
	local move = self.LastSimulatedMove

	if not move then
		warn("No last simulated move exists")
		return
	end

	local movedPiece = move.MovedPiece
	local capturedPiece = move.CapturedPiece
	local initSpot = self:GetSpotObjectAt(move.InitPosLetter, move.InitPosNumber)
	local targetSpot = self:GetSpotObjectAt(move.TargetPosLetter, move.TargetPosNumber)

	-- this shouldn't become negative
	movedPiece.MovesMade -= 1

	initSpot:SetPiece(movedPiece)
	targetSpot:SetPiece(capturedPiece or nil)

	movedPiece:SetSpot(initSpot)
	if capturedPiece then
		capturedPiece.Captured = false
		capturedPiece:SetSpot(targetSpot)
	end

	if movedPiece.CanBeKilledByEnPassant then
		--if it can be killed by en passant now, then it couldn't before
		movedPiece.CanBeKilledByEnPassant = false
	end

	if move.IsEnPassant then
		capturedPiece.CanBeKilledByEnPassant = true

		local otherPawnSpotPartial = move.OtherPawnSpotPartial
		local otherPawnSpot = self:GetSpotObjectAt(otherPawnSpotPartial.Letter, otherPawnSpotPartial.Number)

		otherPawnSpot:SetPiece(capturedPiece)
		targetSpot:SetPiece(nil)

		capturedPiece.Captured = false
		capturedPiece:SetSpot(otherPawnSpot)
	elseif move.IsPromotion then
		movedPiece.Promoted = false
		movedPiece.Type = "Pawn"
		setmetatable(movedPiece, PieceClasses.Pawn)
	elseif move.IsCastling then
		local castlingMoves = move.CastlingMoves
		local initRookSpot = castlingMoves.InitRookSpot
		local targetRookSpot = castlingMoves.RookTargetSpot

		local rook = self:GetPieceObjectAtSpot(targetRookSpot)

		rook.MovesMade -= 1

		rook:SetSpot(initRookSpot)
		initRookSpot:SetPiece(rook)
		targetRookSpot:SetPiece(nil)
	end
end

function ChessBoard:IsSpotUnderAttack(team, arg1, arg2, returnAttacks)
	local spot = self:GetSpotObjectAt(arg1, arg2)
	local oppTeam = team == "Black" and "White" or "Black"
	local opponentPieces = self[oppTeam .. "Pieces"]

	local attackingPieces = {}
	for _, opponentPiece in pairs(opponentPieces) do
		if opponentPiece.Captured then
			--remove(attackingPieces, table.find(attackingPieces, attackingPiece))
			continue
		end
		local moves = opponentPiece:GetMoves({ onlyAttacks = true, bypassCheckCondition = true })

		for _, move in pairs(moves) do
			if spot.Letter == move.TargetPosLetter and spot.Number == move.TargetPosNumber then
				if returnAttacks then
					insert(attackingPieces, {
						AttackType = find(RangedPieces, opponentPiece.Type) and "Ranged" or opponentPiece.Type,
						InitSpotLetter = opponentPiece.Spot.Letter,
						InitSpotNumber = opponentPiece.Spot.Number,
					})
					break
				else
					return true
				end
			end
		end
	end

	return (returnAttacks and #attackingPieces > 0) and attackingPieces or false
end

--CLIENT ONLY
function ChessBoard:Update(move)
	local castlingRookMoves = move.CastlingMoves

	--If the move involves castling
	if castlingRookMoves then
		local castlingRook = self:GetPieceObjectAtSpot(castlingRookMoves.InitPosLetter, castlingRookMoves.InitPosNumber)
		local castlingKing = self:GetPieceObjectAtSpot(move.InitPosLetter, move.InitPosNumber)

		castlingKing:Castle(castlingRook)

		return false -- Don't do the rest (already done)
	end

	local targetSpot = self:GetSpotObjectAt(move.TargetPosLetter, move.TargetPosNumber)
	local initSpot = self:GetSpotObjectAt(move.InitPosLetter, move.InitPosNumber)
	local initPiece = initSpot.Piece

	--If the move is En Passant
	if move.IsEnPassant then
		local otherPawnSpotPartial = move.OtherPawnSpotPartial

		local pieceOnSide = self:GetPieceObjectAtSpot(otherPawnSpotPartial.Letter, otherPawnSpotPartial.Number)
		local pieceOnSideIsPawn = pieceOnSide and (pieceOnSide.Type == "Pawn") or false

		if pieceOnSideIsPawn then
			local targetSpot = self:GetSpotObjectAt(move.TargetPosLetter, move.TargetPosNumber)
			move = initPiece:EnPassant(pieceOnSide, targetSpot)
		end

		return false
	end

	if move.IsPromotion then
		if initPiece.Type ~= "Pawn" then
			return
		end --idek why

		move = initPiece:Promote(move.PromotedPiece, targetSpot, { newPieceInstance = move.NewPieceInstance })

		return false
	end

	initPiece:MoveTo(targetSpot.Letter, targetSpot.Number)

	self.LastMove = move -- this is not really required as of now (but its there)
end

function ChessBoard:GetSpotObjectAt(arg1, arg2)
	if arg2 then
		return self.Spots[arg1 .. arg2]
	end

	return self.Spots[arg1]
end

function ChessBoard:GetSpotObjectFor(piece)
	local CheckFunc

	if type(piece) == "userdata" then
		CheckFunc = function(spot)
			if spot.Piece and spot.Piece.Instance == piece then
				return true
			end
			return false
		end
	else
		CheckFunc = function(spot)
			if spot.Piece == piece then
				return true
			end
			return false
		end
	end

	for _, spot in pairs(self.Spots) do
		if CheckFunc(spot) then
			return spot
		end
	end

	return nil
end

function ChessBoard:GetPieceObjectFromInstance(instance)
	for _, spot in pairs(self.Spots) do
		if spot.Piece and spot.Piece.Instance == instance then
			return spot.Piece
		end
	end
	return nil
end

function ChessBoard:GetPieceObjectAtSpot(arg1, arg2)
	local letter, number = arg1, arg2

	if type(arg1) == "userdata" then
		local tile = arg1
		local coordinates = tile.Name:split("")
		letter = coordinates[1]
		number = coordinates[2]
	elseif type(arg1) == "string" then
		if not arg2 then
			return self.Spots[arg1].Piece
		end
	elseif type(arg1) == "table" then
		return arg1.Piece
	end

	return self.Spots[letter .. number].Piece
end

function ChessBoard:GetPiecesOfType(pieceType, team)
	local pieces = {}

	for _, spot in pairs(self.Spots) do
		local piece = spot.Piece
		if piece.Type == pieceType then
			insert(piece, piece)
		end
	end

	--if (#pieces == 1) then
	--	return pieces[1]
	--end

	return pieces
end

function findMinAndMax(...)
	local array = { ... }

	local min = 0
	local max = 0

	for i = 1, #array do
		local num = array[i]
		if num < min then
			min = num
		end
		if num > max then
			max = num
		end
	end

	return min, max
end

return ChessBoard
