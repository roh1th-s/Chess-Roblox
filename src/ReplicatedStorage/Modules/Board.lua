local RS = game:GetService("RunService")
local TS = game:GetService("TweenService")
local RS = game:GetService("ReplicatedStorage")
local LocalizationService = game:GetService("LocalizationService")
local SSS = game:GetService("ServerScriptService")

local Modules = script.Parent
local Piece = Modules.Piece

local Spot = require(script.Parent.Spot)
local Pawn = require(Piece.Pawn)
local Rook = require(Piece.Rook)
local Knight = require(Piece.Knight)
local Bishop = require(Piece.Bishop)
local Queen = require(Piece.Queen)
local King = require(Piece.King)

local Remotes = RS:WaitForChild("Remotes")
local Promotion = Remotes:WaitForChild("Promotion")
local getPieceSpotDictionary = Remotes:WaitForChild("GetPieceSpotDictionary")
local gameEvent = Remotes:WaitForChild("GameEvent")

local char = string.char
local byte = string.byte
local insert = table.insert
local remove = table.remove

local _INIT_POSITIONS = {
	["A8"] = "R",
	["B8"] = "K",
	["C8"] = "B",
	["D8"] = "Q",
	["E8"] = "King",
	["F8"] = "B",
	["G8"] = "K",
	["H8"] = "R",
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
	["A1"] = "R",
	["B1"] = "K",
	["C1"] = "B",
	["D1"] = "Q",
	["E1"] = "King",
	["F1"] = "B",
	["G1"] = "K",
	["H1"] = "R",
}

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

	self.LastMove = {}
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

	if PieceName == "R" then
		PieceObject = Rook.new(spot, team, self.isServer)
	elseif PieceName == "Pawn" then
		PieceObject = Pawn.new(spot, team, self.isServer)
	elseif PieceName == "King" then
		PieceObject = King.new(spot, team, self.isServer)
		self.Kings[team] = PieceObject
	elseif PieceName == "Q" then
		PieceObject = Queen.new(spot, team, self.isServer)
	elseif PieceName == "B" then
		PieceObject = Bishop.new(spot, team, self.isServer)
	elseif PieceName == "K" then
		PieceObject = Knight.new(spot, team, self.isServer)
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

function ChessBoard:MakeMove(initSpotCoordinates, targetSpotCoordinates)
	local move = nil

	local piece = self:GetPieceObjectAtSpot(initSpotCoordinates[1], initSpotCoordinates[2])
	assert(piece, "There is no piece on the initial square!")

	local letterDiffFromTargetSpot = byte(targetSpotCoordinates[1]) - byte(piece.Letter)
	local absoluteLetterDiff = math.abs(letterDiffFromTargetSpot)
	local isNegative = (letterDiffFromTargetSpot ~= absoluteLetterDiff)

	--local numberDiffFromTargetSpot = targetSpotCoordinates[2] - piece.Number
	local absoluteNumberDiff = math.abs(letterDiffFromTargetSpot)

	--Castling checks
	if piece.Type == "King" and not piece.HasMoved and absoluteLetterDiff == 2 then
		print("Castling..")
		local rookLetter = isNegative and "A" or "H"
		local associatedRook = self:GetPieceObjectAtSpot(rookLetter .. piece.Number)
		move = piece:Castle(associatedRook)
	end

	--En Passant Checks
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
				move = piece:EnPassant(pieceOnSide, targetSpot)
			end
		end

		local lastRankForTeam = piece.Team == "White" and "8" or "1"
		if targetSpotCoordinates[2] == lastRankForTeam then
			print(self.Game)
			self.Game:PromptPromotion(piece.Team)
		end
	end

	if not move then
		move = piece:MoveTo(targetSpotCoordinates[1], targetSpotCoordinates[2])
	end

	local oppTeam = piece:GetOppTeam()

	if self:IsCheck(oppTeam) then
		print("Check")
	end

	self.LastMove = move

	return move
end

function ChessBoard:SimulateMove(initSpotCoordinates, targetSpotCoordinates)
	local move = nil

	local piece = self:GetPieceObjectAtSpot(initSpotCoordinates[1], initSpotCoordinates[2])
	assert(piece, "There is no piece on the initial square!")

	local letterDiffFromTargetSpot = byte(targetSpotCoordinates[1]) - byte(piece.Letter)
	local absoluteLetterDiff = math.abs(letterDiffFromTargetSpot)
	--local numberDiffFromTargetSpot = targetSpotCoordinates[2] - piece.Number
	local absoluteNumberDiff = math.abs(letterDiffFromTargetSpot)

	--cannot be castling

	--En Passant Checks
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
				move = piece:EnPassant(pieceOnSide, targetSpot, { simulatedMove = true })
			end
		end
	end

	if not move then
		move = piece:MoveTo(targetSpotCoordinates[1], targetSpotCoordinates[2], { simulatedMove = true })
	end

	self.LastSimulatedMove = move

	return move
end

function ChessBoard:WillMoveCauseCheck(initSpotCoordinates, targetSpotCoordinates)
	--local move = self:SimulateMove(initSpotCoordinates, targetSpotCoordinates)
	local isCheck = false
	-- if (self:IsCheck(move.MovedPiece.Team)) then
	-- 	isCheck = true
	-- end

	return isCheck
end

function ChessBoard:GetLastMove()
	return self.LastMove
end

function ChessBoard:GetLastSimulatedMove()
	return self.LastSimulatedMove
end

--SERVER ONLY
function ChessBoard:UndoLastMove() --TODO Need to update clients
	local move = self.LastMove
end

function ChessBoard:UndoLastSimulatedMove()
	local move = self.LastSimulatedMove
end

function ChessBoard:IsCheck(team)
	local King = self.Kings[team]
	local KingSpot = King.Spot

	return self:IsSpotUnderAttack(King.Team, KingSpot.Letter, KingSpot.Number)
end

function ChessBoard:IsSpotUnderAttack(team, arg1, arg2)
	local spot = self:GetSpotObjectAt(arg1, arg2)
	local oppTeam = team == "Black" and "White" or "Black"
	local attackingPieces = self[oppTeam .. "Pieces"]

	for _, attackingPiece in pairs(attackingPieces) do
		if attackingPiece.Captured then
			--remove(attackingPieces, table.find(attackingPieces, attackingPiece))
			continue
		end
		local moves = attackingPiece:GetMoves({ onlyAttacks = true })

		if attackingPiece.Type == "Queen" then
			print(oppTeam .. "'s pieces.")
			print(moves)
		end

		for _, move in pairs(moves) do
			if spot.Letter == move.TargetPosLetter and spot.Number == move.TargetPosNumber then
				return true
			end
		end
	end

	return false
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
		local letterDiffFromTargetSpot = byte(move.TargetPosLetter) - byte(initPiece.Letter)

		local pieceOnSide = self:GetPieceObjectAtSpot(
			char(byte(initPiece.Letter) + letterDiffFromTargetSpot),
			initPiece.Number
		)
		local pieceOnSideIsPawn = pieceOnSide and (pieceOnSide.Type == "Pawn") or nil

		if pieceOnSideIsPawn then
			local targetSpot = self:GetSpotObjectAt(move.TargetPosLetter, move.TargetPosNumber)
			move = initPiece:EnPassant(pieceOnSide, targetSpot)
		end

		return false
	end

	initPiece:MoveTo(targetSpot.Letter, targetSpot.Number)

	self.LastMove = move
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
	print(arg1,arg2)
	if type(arg1) == "userdata" then
		local tile = arg1
		local coordinates = tile.Name:split("")
		letter = coordinates[1]
		number = coordinates[2]
	elseif type(arg1) == "string" then
		if not arg2 then
			return self.Spots[arg1].Piece
		end
		return self.Spots[arg1 .. arg2].Piece
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

return ChessBoard
