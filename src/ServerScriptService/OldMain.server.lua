local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local TS = game:GetService("TweenService")
local Teams = game:GetService("Teams")
local PS = game:GetService("Players")
--inbuilt functions
local char = string.char
local byte = string.byte
local insert = table.insert
local find = table.find
--Remote events and functions
local RequestMove = RS:WaitForChild("RequestMove")
local FindMoves = RS:WaitForChild("FindMoves")
local Promotion = RS:WaitForChild("Promotion")
local GameEvent = RS:WaitForChild("GameEvent")
--Instance tables
local White = game.Workspace.White
local Black = game.Workspace.Black 
local CB = game.Workspace.CapturedBlack
local CW = game.Workspace.CapturedWhite
local Board = game.Workspace.Board
--Game counters
local GameInProgress = false
local GameOver = false
local WhoseTurn = workspace:WaitForChild("WhoseTurn") 
local Players = {
	["PlrBlack"] = 0,
	["PlrWhite"] = 0
}	
local Castling = { 
	["White"] = {
		["HasCastled"] = false,
		["King"] = true,
		["A1"] = true,
		["H1"] = true 
	},
	["Black"] = {
		["HasCastled"] = false,
		["King"] = true,
		["H8"] = true,
		["A8"] = true 
	}
}

local EnPassant = {
	["White"] = nil,
	["Black"] = nil
}

local PieceMoves = {}

local VirtualBoard = {}
local VirtualPieces = {}
local Rooks = {
	["White"] = {},
	["Black"] = {}
}

for i,v in pairs(Board:GetChildren()) do
	VirtualBoard[v.Name] = v.Occupant.Value
end

for i,v in pairs(White:GetChildren()) do
	VirtualPieces[v] = v.Coordinates.Value
	if v.Name == "Rook" then
		insert(Rooks["White"],v)
	end
end

for i,v in pairs(Black:GetChildren()) do
	VirtualPieces[v] = v.Coordinates.Value
	if v.Name == "Rook" then
		insert(Rooks["Black"],v)
	end
end

local function InitializeBoard()
	print("Init")
	for i,v in ipairs(White:GetChildren()) do
		local tile = VirtualPieces[v]
		local Offset = (v.Size.Y/2) + (tile.Size.Y/2)
		v.Position = tile.Position + Vector3.new(0,Offset,0)
	end
	for i,v in ipairs(Black:GetChildren()) do
		local tile = VirtualPieces[v]
		local Offset = (v.Size.Y/2) + (tile.Size.Y/2)
		v.Position = tile.Position + Vector3.new(0,Offset,0)
	end
	for i,player in pairs(game.Players:GetChildren()) do
		Players["Plr"..player.Team.name] = player
	end
end

local function Restart()
	print("Restart")
	WhoseTurn.Value = true
	VirtualBoard = {}
	VirtualPieces = {}
	Rooks = {
		["White"] = {},
		["Black"] = {}
	}

	EnPassant = {
		["White"] = nil,
		["Black"] = nil
	}

	Castling = { 
		["White"] = {
			["HasCastled"] = false,
			["King"] = true,
			["A1"] = true,
			["H1"] = true 
		},
		["Black"] = {
			["HasCastled"] = false,
			["King"] = true,
			["H8"] = true,
			["A8"] = true 
		}
	}

	for i,tile in pairs(Board:GetChildren()) do
		tile.Occupant.Value = nil
		VirtualBoard[tile.Name] = nil
	end
	for i, piece in pairs(CB:GetChildren()) do
		piece.Parent = Black
		piece.CFrame = piece.CFrame * CFrame.Angles(0,math.rad(180),0)
	end
	for i, piece in pairs(CW:GetChildren()) do
		piece.Parent = White
		piece.CFrame = piece.CFrame * CFrame.Angles(0,math.rad(180),0)
	end
	for i, piece in pairs(SS.BlackPawns:GetChildren()) do
		piece.Parent = Black
	end
	for i, piece in pairs(SS.WhitePawns:GetChildren()) do
		piece.Parent = White
	end
	for i, piece in pairs(White:GetChildren()) do 
		if piece:FindFirstChild("OriginalCoordinates") then                 
			piece.Coordinates.Value = piece.OriginalCoordinates.Value
			piece.Coordinates.Value.Occupant.Value = piece
			VirtualPieces[piece] = piece.Coordinates.Value
			VirtualBoard[VirtualPieces[piece].Name] = piece
			if piece.Name == "Rook" then
				insert(Rooks["White"],piece)
			end
		else
			piece:Destroy()
		end
	end
	for i, piece in pairs(Black:GetChildren()) do
		if piece:FindFirstChild("OriginalCoordinates")  then                                   
			piece.Coordinates.Value = piece.OriginalCoordinates.Value
			piece.Coordinates.Value.Occupant.Value = piece
			VirtualPieces[piece] = piece.Coordinates.Value
			VirtualBoard[VirtualPieces[piece].Name] = piece
			if piece.Name == "Rook" then
				insert(Rooks["Black"],piece)
			end
		else
			piece:Destroy()
		end
	end
	InitializeBoard()
	GameEvent:FireAllClients("Restart")
end

local function CapturePiece(piece)
	local team
	if piece.Parent.Name == "Black" then
		team = "Black"
	else
		team = "White"
	end
	if piece.Name == "Rook" then
		for i = #Rooks[team],1,-1 do
			if Rooks[team][i] == piece then
				table.remove(Rooks[team],i)
			end
		end
	end
	piece.Parent = workspace["Captured"..team]
end

local function IsSquareUnderAttack(square,teamName)
	local AttackingPieces = {}
	local oppTeam
	if teamName == "White" then
		oppTeam = "Black"
	else
		oppTeam = "White"
	end
	for i,piece in pairs(workspace[oppTeam]:GetChildren()) do
		if VirtualPieces[piece] then
			local moves = {}
			local coordinates = VirtualPieces[piece].Name:split("")
			local letter = coordinates[1]
			local number = tonumber(coordinates[2])
			if piece.Name == "Pawn" then
				moves = PieceMoves.FindPawnAttacks(letter,number,teamName) -- u are ur opponent's oppTeam
			else
				moves = PieceMoves["Find"..piece.Name.."Moves"](letter,number,teamName)
			end
			for i,v in pairs(moves) do
				if v == square then
					insert(AttackingPieces,piece)
					break
				end
			end
			moves = {}
		end
	end
	if #AttackingPieces ~= 0 then
		return AttackingPieces
	end
	return false
end

local function IsCheck(teamName)
	local king = workspace[teamName]:WaitForChild("King",10)
	local square = VirtualPieces[king]

	local AttackingPieces = IsSquareUnderAttack(square,teamName)
	if AttackingPieces then
		return AttackingPieces
	end
	return false
end

local function DoesMoveCauseCheck(piece,coordinate)
	local teamName = piece.Parent.Name
	local king = workspace[teamName]:WaitForChild("King",10)
	local square = VirtualPieces[king]

	local OriginalCoordinates = VirtualPieces[piece]
	local OriginalOccupant = VirtualBoard[coordinate.Name]

	VirtualBoard[OriginalCoordinates.Name] = nil
	VirtualPieces[piece] = coordinate
	VirtualBoard[coordinate.Name] = piece
	if OriginalOccupant then
		VirtualPieces[OriginalOccupant] = nil
	end

	local Check = IsCheck(teamName)
	if  Check then
		VirtualPieces[piece] = OriginalCoordinates
		VirtualBoard[OriginalCoordinates.Name] = piece
		VirtualBoard[coordinate.Name] = nil
		if OriginalOccupant then
			VirtualPieces[OriginalOccupant] = coordinate
			VirtualBoard[coordinate.Name] = OriginalOccupant
		end
		return true
	end
	VirtualPieces[piece] = OriginalCoordinates
	VirtualBoard[OriginalCoordinates.Name] = piece
	VirtualBoard[coordinate.Name] = nil
	if OriginalOccupant then
		VirtualPieces[OriginalOccupant] = coordinate
		VirtualBoard[coordinate.Name] = OriginalOccupant
	end
	return false
end

function PieceMoves.FindPawnAttacks(letter,number,oppTeam)
	local moves = {}
	local team
	if oppTeam == "White" then
		team = "Black"
	else
		team = "White"
	end
	local lnum = byte(letter)
	local square = Board:FindFirstChild(letter..number)
	local piece = VirtualBoard[square.Name]
	local i,factor

	if team == "White" then
		factor = 1
	else
		factor = -1
	end

	for i = lnum - 1,lnum + 1 do
		if i~= lnum then
			local co = Board:FindFirstChild(char(i)..number + factor)
			if co then
				insert(moves,co)
			end
		end
	end	
	--En Passant
	if EnPassant[oppTeam] then
		local co_s = {(char(lnum + 1)..number) , (char(lnum - 1)..number)}
		for i,v in pairs(co_s) do
			if VirtualBoard[v] == EnPassant[oppTeam] then
				local coord = v:split("")
				local l = coord[1]
				local n = tonumber(coord[2])
				local co = Board:FindFirstChild(l..n+factor)
				insert(moves,co)
			end
		end
	end
	return moves
end

function PieceMoves.FindPawnMoves(letter,number,oppTeam)
	local moves = {}
	local team,factor,startn
	if oppTeam == "White" then
		team = "Black"
		factor = -1
		startn = 7
	else
		team = "White"
		factor = 1
		startn = 2
	end
	local lnum = byte(letter)
	local i

	if number == startn then
		for i = number + factor,number + (factor * 2),factor do
			local co = Board:FindFirstChild(letter..i)
			if co then
				if not VirtualBoard[co.Name] then
					insert(moves,co)
				else
					break
				end
			end
		end
	else
		local n = number + factor
		local co = Board:FindFirstChild(letter..n)
		if co then
			if not VirtualBoard[co.Name] then
				insert(moves,co)
			end
		end
	end

	for i = lnum - factor,lnum + factor,factor do
		if i~= lnum then
			local co = Board:FindFirstChild(char(i)..number + factor)
			if co then
				if VirtualBoard[co.Name] and VirtualBoard[co.Name].Parent.Name == oppTeam then
					insert(moves,co)
				end
			end
		end
	end
	--En Passant
	if EnPassant[oppTeam] then
		local co_s = {(char(lnum + 1)..number) , (char(lnum - 1)..number)}
		for i,v in pairs(co_s) do
			if VirtualBoard[v] == EnPassant[oppTeam] then
				local coord = v:split("")
				local l = coord[1]
				local n = tonumber(coord[2])
				local co = Board:FindFirstChild(l..n+factor)
				insert(moves,co)
			end
		end
	end

	return moves
end

function PieceMoves.FindRookMoves(letter,number,oppTeam)
	local moves = {}
	local MovesBtwn = {}
	local TempMoves = {}
	local square = Board:FindFirstChild(letter..number)
	local piece = VirtualBoard[square.Name]
	local lnum = byte(letter)
	local i
	for i = number + 1,8 do
		local co = Board:FindFirstChild(letter..i)
		if co then
			if not VirtualBoard[co.Name] then
				insert(moves,co)
				insert(TempMoves,co)
			else
				local occ = VirtualBoard[co.Name]
				if occ.Parent.Name == oppTeam then
					insert(moves,co)
					if occ.Name == "King" then
						MovesBtwn = TempMoves
					end
				end
				break
			end
		end
	end
	TempMoves = {}
	for i = number - 1,1,-1 do
		local co = Board:FindFirstChild(letter..i)
		if co then
			if not VirtualBoard[co.Name] then
				insert(moves,co)
				insert(TempMoves,co)
			else
				local occ = VirtualBoard[co.Name]
				if occ.Parent.Name == oppTeam then
					insert(moves,co)
					if occ.Name == "King" then
						MovesBtwn = TempMoves
					end
				end
				break
			end
		end
	end
	TempMoves = {}
	for i = lnum - 1,65,-1 do
		local co = Board:FindFirstChild(char(i)..number)
		if co then
			if not VirtualBoard[co.Name] then
				insert(moves,co)
				insert(TempMoves,co)
			else
				local occ = VirtualBoard[co.Name]
				if occ.Parent.Name == oppTeam then
					insert(moves,co)
					if occ.Name == "King" then
						MovesBtwn = TempMoves
					end
				end
				break
			end
		end
	end
	TempMoves = {}
	for i = lnum + 1,72 do
		local co = Board:FindFirstChild(char(i)..number)
		if co then
			if not VirtualBoard[co.Name] then
				insert(moves,co)
				insert(TempMoves,co)
			else
				local occ = VirtualBoard[co.Name]
				if occ.Parent.Name == oppTeam then
					insert(moves,co)
					if occ.Name == "King" then
						MovesBtwn = TempMoves
					end
				end
				break
			end
		end
	end
	return moves,MovesBtwn
end

function PieceMoves.FindBishopMoves(letter,number,oppTeam)
	local moves = {}
	local MovesBtwn = {}
	local TempMoves = {}
	local square = Board:FindFirstChild(letter..number)
	local piece = VirtualBoard[square.Name]
	local lnum = byte(letter)
	local i,q
	q = number + 1
	for i = lnum + 1,72 do
		local co = Board:FindFirstChild(char(i)..q)
		if co then
			if not VirtualBoard[co.Name] then
				insert(moves,co)
				insert(TempMoves,co)
			else
				local occ = VirtualBoard[co.Name]
				if occ.Parent.Name == oppTeam then
					insert(moves,co)
					if occ.Name == "King" then
						MovesBtwn = TempMoves
					end
				end
				break
			end
		end
		q = q + 1
	end
	TempMoves = {}
	q = number + 1
	for i = lnum - 1,65,-1 do
		local co = Board:FindFirstChild(char(i)..q)
		if co then
			if not VirtualBoard[co.Name] then
				insert(moves,co)
				insert(TempMoves,co)
			else
				local occ = VirtualBoard[co.Name]
				if occ.Parent.Name == oppTeam then
					insert(moves,co)
					if occ.Name == "King" then
						MovesBtwn = TempMoves
					end
				end
				break
			end
		end
		q = q + 1
	end
	TempMoves = {}
	q = number - 1
	for i = lnum + 1,72 do
		local co = Board:FindFirstChild(char(i)..q)
		if co then
			if not VirtualBoard[co.Name] then
				insert(moves,co)
				insert(TempMoves,co)
			else
				local occ = VirtualBoard[co.Name]
				if occ.Parent.Name == oppTeam then
					insert(moves,co)
					if occ.Name == "King" then
						MovesBtwn = TempMoves
					end
				end
				break
			end
		end
		q = q - 1
	end

	TempMoves = {}
	q = number - 1
	for i = lnum - 1,65,-1 do
		local co = Board:FindFirstChild(char(i)..q)
		if co then
			if not VirtualBoard[co.Name] then
				insert(moves,co)
				insert(TempMoves,co)
			else
				local occ = VirtualBoard[co.Name]
				if occ.Parent.Name == oppTeam then
					insert(moves,co)
					if occ.Name == "King" then
						MovesBtwn = TempMoves
					end
				end
				break
			end
		end
		q = q - 1
	end
	return moves,MovesBtwn
end

function PieceMoves.FindKnightMoves(letter,number,oppTeam)
	local moves = {}
	local square = Board:FindFirstChild(letter..number)
	local piece = VirtualBoard[square.Name]
	local lnum = byte(letter)
	local i,q
	q = number + 2
	for i = lnum - 1,lnum + 1 do
		if i ~= lnum then
			local co = Board:FindFirstChild(char(i)..q)
			if co then
				if not VirtualBoard[co.Name] then
					insert(moves,co)
				elseif VirtualBoard[co.Name].Parent.Name == oppTeam then
					insert(moves,co)
				end
			end
		end
	end
	q = number - 2
	for i = lnum - 1,lnum + 1 do
		if i ~= lnum then
			local co = Board:FindFirstChild(char(i)..q)
			if co then
				if not VirtualBoard[co.Name] then
					insert(moves,co)
				elseif VirtualBoard[co.Name].Parent.Name == oppTeam then
					insert(moves,co)
				end
			end
		end
	end
	q = lnum + 2
	for i = number - 1,number + 1 do
		if i ~= number then
			local co = Board:FindFirstChild(char(q)..i)
			if co then
				if not VirtualBoard[co.Name] then
					insert(moves,co)
				elseif VirtualBoard[co.Name].Parent.Name == oppTeam then
					insert(moves,co)
				end
			end
		end
	end
	q = lnum - 2
	for i = number - 1,number + 1 do
		if i ~= number then
			local co = Board:FindFirstChild(char(q)..i)
			if co then
				if not VirtualBoard[co.Name] then
					insert(moves,co)
				elseif VirtualBoard[co.Name].Parent.Name == oppTeam then
					insert(moves,co)
				end
			end
		end
	end
	return moves
end

function PieceMoves.FindQueenMoves(letter,number,oppTeam)
	local moves = {}
	local MovesBtwn = {}
	local RookB,BishopB 
	local rookMoves
	local square = Board:FindFirstChild(letter..number)
	local piece = VirtualBoard[square.Name]
	local lnum = byte(letter)
	local i,q

	moves,BishopB = PieceMoves.FindBishopMoves(letter,number,oppTeam)
	rookMoves,RookB = PieceMoves.FindRookMoves(letter,number,oppTeam)
	for i, move in pairs(rookMoves) do
		insert(moves,move)
	end
	if #BishopB ~= 0 then
		MovesBtwn = BishopB
	else
		MovesBtwn = RookB
	end
	return moves,MovesBtwn
end

function PieceMoves.Castling(letter,number,oppTeam)
	local moves = {}
	local lnum = byte(letter)
	local factor 
	local team
	if oppTeam == "White" then
		team = "Black"
	else
		team = "White"
	end

	if Castling[team]["King"] then 
		local rooks = Rooks[team]
		for i,rook in pairs(rooks) do
			local CannotCastle = false
			local co = VirtualPieces[rook]
			print(co)
			local coordinates = co.Name:split("")
			local ln = byte(coordinates[1])
			local RookCanCastle = Castling[team][co.Name]
			if RookCanCastle then
				if ln == 65 then
					factor = -1
				else
					factor = 1
				end
				for i = lnum + factor,ln - factor ,factor do
					local co = Board:FindFirstChild(char(i)..number)
					print(VirtualBoard[co.Name])
					if VirtualBoard[co.Name] then
						print('Occupied')
						CannotCastle = true
						break
					end
				end
				if not CannotCastle then
					for i = lnum,lnum + (2*factor),factor do
						print(co)
						local co = Board:FindFirstChild(char(i)..number)
						if IsSquareUnderAttack(co,team) then
							print('SquareAttack')
							CannotCastle = true
							break
						end
					end
				end
				if not CannotCastle then
					print("Insert")
					insert(moves,co)
				end	
			end
		end
	end
	return moves
end

function PieceMoves.FindKingMoves(letter,number,oppTeam)
	local moves = {}
	local square = Board:FindFirstChild(letter..number)
	local piece = VirtualBoard[square.Name]
	local lnum = byte(letter)
	local i,q
	for i = number - 1,number + 1 do
		for q = lnum - 1,lnum + 1 do
			if q == lnum and i == number then continue end
			local co = Board:FindFirstChild(char(q)..i)
			if co then
				if not VirtualBoard[co.Name] then
					insert(moves,co)
				else
					if VirtualBoard[co.Name].Parent.Name == oppTeam then
						insert(moves,co)
					end
				end
			end
		end
	end
	return moves
end

local function FindMovesFunction(plr,piece)
	if not GameInProgress or GameOver then return {} end
	local moves = {}
	local oppTeam,movesbtwn
	local team = plr.Team.Name
	local coordinates = piece.Coordinates.Value.Name:split("")
	local letter = coordinates[1]
	local number = tonumber(coordinates[2])

	if team == "White" then
		oppTeam = "Black"
	else
		oppTeam = "White"
	end
	moves = PieceMoves["Find"..piece.Name.."Moves"](letter,number,oppTeam)

	if piece.Name == "King" then
		local CastlingMoves = PieceMoves.Castling(letter,number,oppTeam)
		for i,move in pairs(CastlingMoves) do
			insert(moves,move)
		end
	end

	for i = #moves, 1,-1 do
		if DoesMoveCauseCheck(piece,moves[i]) then
			table.remove(moves,i)
		end
	end
	return moves
end


local function IsCheckmate(AttackingPieces,teamName)
	local king = workspace[teamName]:WaitForChild("King",10)
	if not king then return false end
	local square = king.Coordinates.Value
	local coordinates = square.Name:split("")
	local letter = coordinates[1]
	local number = tonumber(coordinates[2])
	local oppTeam

	if teamName == "White" then
		oppTeam = "Black"
	else
		oppTeam = "White"
	end

	local KMoves = PieceMoves.FindKingMoves(letter,number,oppTeam)
	for i = #KMoves, 1,-1 do
		if DoesMoveCauseCheck(king,KMoves[i]) then
			table.remove(KMoves,i)
		end
	end
	if #KMoves ~= 0 then
		return false
	end

	if #AttackingPieces == 1 then
		local NormalMoves,AMoves = {},{}
		local APiece = AttackingPieces[1]
		local coord = VirtualPieces[APiece]
		local coordinates = coord.Name:split("")
		local letter = coordinates[1]
		local number = tonumber(coordinates[2])
		NormalMoves,AMoves = PieceMoves["Find"..APiece.Name.."Moves"](letter,number,teamName)
		if not AMoves then AMoves = {} end
		table.insert(AMoves,coord)
		for i, piece in pairs(workspace[teamName]:GetChildren()) do
			if piece.Name == "King" then continue end
			if AMoves == nil then break end
			local coordinates = VirtualPieces[piece].Name:split("")
			local letter = coordinates[1]
			local number = tonumber(coordinates[2])
			local PMoves = PieceMoves["Find"..piece.Name.."Moves"](letter,number,oppTeam)
			for i,pmove in pairs(PMoves) do
				for i,amove in pairs(AMoves) do
					if pmove == amove then
						print(piece,pmove)
						return false
					end
				end
			end
		end
	end
	print("Checkmate")
	return true
end

local function IsStalemate(teamName)
	local oppTeam
	if teamName == "White" then
		oppTeam = "Black"
	else
		oppTeam = "White"
	end

	local pieces = workspace[teamName]:GetChildren()
	for i, piece in pairs(pieces) do
		local coordinates = VirtualPieces[piece].Name:split("")
		local letter = coordinates[1]
		local number = tonumber(coordinates[2])
		local moves,MovesBtwn = PieceMoves["Find"..piece.Name.."Moves"](letter,number,oppTeam)
		--Remove moves that cause check
		for i = #moves, 1,-1 do
			if DoesMoveCauseCheck(piece,moves[i]) then
				table.remove(moves,i)
			end
		end
		if #moves ~= 0 then
			return false
		end
	end
	print("Stalemate")
	return true
end

local function Castle(king,rook,coordinate)
	local Offset,Pos,factor
	local coord = coordinate.Name:split("")
	local rookln = byte(coord[1])
	local kingln = byte(VirtualPieces[king].Name:split("")[1])

	if rookln == 65 then
		factor = -1 
	else
		factor = 1
	end

	local KingEndSquare = Board:FindFirstChild(char(kingln + (factor * 2))..coord[2])
	local RookEndSquare = Board:FindFirstChild(char(kingln + factor)..coord[2])
	--clearing king initial square
	king.Coordinates.Value.Occupant.Value = nil
	VirtualBoard[VirtualPieces[king].Name] = nil
	--rook initial square
	rook.Coordinates.Value.Occupant.Value = nil
	VirtualBoard[VirtualPieces[rook].Name] = nil
	--king's coordinates
	king.Coordinates.Value = KingEndSquare
	VirtualPieces[king] = KingEndSquare
	--rook's coordinates
	rook.Coordinates.Value = RookEndSquare
	VirtualPieces[rook] = RookEndSquare
	--king's final square
	KingEndSquare.Occupant.Value = king
	VirtualBoard[KingEndSquare.Name] = king
	--rook's final square
	RookEndSquare.Occupant.Value = rook
	VirtualBoard[RookEndSquare.Name] = rook

	Offset = (king.Size.Y/2) + (coordinate.Size.Y/2)
	local KingPos = KingEndSquare.Position + Vector3.new(0,Offset,0)
	Offset = (rook.Size.Y/2) + (coordinate.Size.Y/2)
	local RookPos = RookEndSquare.Position + Vector3.new(0,Offset,0)
	local KingMove = TS:Create(king,TweenInfo.new(0.5),{Position = KingPos}):Play()
	local RookMove = TS:Create(rook,TweenInfo.new(0.5),{Position = RookPos}):Play()
	wait(1)
end

local function EnPassantMove(pawn,EPawn,coordinate)
	local Offset,Pos
	local pawnCoord = VirtualPieces[pawn]
	local EPawnCoord = VirtualPieces[EPawn]
	local canMove = math.abs(byte(EPawnCoord.Name:split("")[1]) - byte(pawnCoord.Name:split("")[1])) == 1 and (EPawnCoord.Name:split("")[2]) == (pawnCoord.Name:split("")[2])
	if canMove then
		pawnCoord.Occupant.Value = nil
		VirtualBoard[pawnCoord.Name] = nil	

		EPawnCoord.Occupant.Value = nil
		VirtualBoard[EPawnCoord.Name] = nil	

		pawn.Coordinates.Value = coordinate
		VirtualPieces[pawn] = coordinate

		EPawn.Coordinates.Value = nil
		VirtualPieces[EPawn] = nil

		coordinate.Occupant.Value = pawn
		VirtualBoard[coordinate.Name] = pawn

		Offset = (pawn.Size.Y/2) + (coordinate.Size.Y/2)
		Pos = coordinate.Position + Vector3.new(0,Offset,0)
		CapturePiece(EPawn)
		TS:Create(pawn,TweenInfo.new(0.5),{Position = Pos}):Play()
		wait(0.5)
		return true			
	end
	return false
end

local function Promote(pawn,PromP)
	local Offset,Pos
	local TeamFolder = pawn.Parent 
	local color = pawn.Color
	local ref = pawn.Reflectance
	local material = pawn.Material
	local cframe = pawn.CFrame
	local coordinates = pawn.Coordinates.Value

	local newP = SS.PromotionPieces:FindFirstChild(PromP):Clone()
	newP.Color = color
	newP.Reflectance = ref
	newP.Material = material
	newP.CFrame = pawn.CFrame
	newP.Coordinates.Value = coordinates
	VirtualPieces[newP] = coordinates
	VirtualPieces[pawn] = nil

	pawn.Parent = SS[TeamFolder.Name.."Pawns"]
	newP.Parent = TeamFolder

	return newP
end

local function MovePiece(player,piece,coordinate)
	local turn,oppTeam
	local castling,endn = false,0
	if player.Team.Name == "White" then
		endn = 8
		oppTeam = "Black"
		turn = true
	else
		endn = 1
		oppTeam = "White"
		turn = false
	end

	EnPassant[player.Team.Name] = nil 

	local OriginalOccupant = coordinate.Occupant.Value

	if WhoseTurn.Value == turn  and GameInProgress then
		WhoseTurn.Value = not WhoseTurn.Value
		local Offset,Pos
		--Castling
		if not Castling[player.Team.Name]["HasCastled"] then
			if piece.Name == "Rook" then
				if Castling[player.Team.Name][VirtualPieces[piece].Name] then
					Castling[player.Team.Name][VirtualPieces[piece].Name] = false
				end
			elseif piece.Name == "King" then
				Castling[player.Team.Name]["King"] = false
				if OriginalOccupant and OriginalOccupant.Name == "Rook" and OriginalOccupant.Parent.Name == player.Team.Name then
					castling = true
				end
			end

			if castling == true then
				Castling[player.Team.Name]["HasCastled"] = true
				Castle(piece,OriginalOccupant,coordinate)
				return
			end
		end
		--En Passant and Promotion 
		if piece.Name == "Pawn" then
			if tonumber(coordinate.Name:split("")[2]) == endn then
				WhoseTurn.Value = not WhoseTurn.Value
				Promotion:FireClient(player)
				local plr,PromotedPiece = Promotion.OnServerEvent:Wait()
				local newP = Promote(piece,PromotedPiece)
				piece = newP
				WhoseTurn.Value = not WhoseTurn.Value
			end
			if math.abs(coordinate.Name:split("")[2] - VirtualPieces[piece].Name:split("")[2]) == 2 then
				EnPassant[player.Team.Name] = piece
			end
			if EnPassant[oppTeam] then
				local Ep = EnPassantMove(piece,EnPassant[oppTeam],coordinate)
				if Ep then
					return
				end
			end
		end

		--Update virtual board 
		piece.Coordinates.Value.Occupant.Value = nil
		VirtualBoard[VirtualPieces[piece].Name] = nil
		piece.Coordinates.Value = coordinate
		VirtualPieces[piece] = coordinate
		coordinate.Occupant.Value = piece
		VirtualBoard[coordinate.Name] = piece

		if OriginalOccupant then
			OriginalOccupant.Coordinates.Value = nil
			VirtualPieces[OriginalOccupant] = nil
			--Capture Piece
			if OriginalOccupant.Parent.Name ~= player.Team.Name then
				CapturePiece(OriginalOccupant)
			end
		end
		local AP = IsCheck(oppTeam)
		if AP then
			print("Check")
			local Cm = IsCheckmate(AP,oppTeam)
			if Cm then
				GameEvent:FireClient(Players["Plr"..oppTeam],"Checkmate")
				GameEvent:FireClient(player,"Win")
				GameInProgress = false
				GameOver = true	
			else
				GameEvent:FireClient(Players["Plr"..oppTeam],"Check")
			end
		else
			if IsStalemate(oppTeam) then
				print("Stalemate"..oppTeam)
				GameEvent:FireAllClients("Stalemate")
			end
		end
		--Move Piece
		Offset = (piece.Size.Y/2) + (coordinate.Size.Y/2)
		Pos = coordinate.Position + Vector3.new(0,Offset,0)
		TS:Create(piece,TweenInfo.new(0.5),{Position = Pos}):Play()
		wait(0.5)
	end
end

InitializeBoard()
----------TEMP-------------
--GameInProgress = true
---------------------------
RequestMove.OnServerEvent:Connect(MovePiece)
FindMoves.OnServerInvoke = FindMovesFunction

GameEvent.OnServerEvent:Connect(function(plr,Event)
	if Event == "Restart" then
		Restart()
	end
end)

PS.PlayerAdded:Connect(function(player)
	Players["Plr"..player.Team.Name] = player
	for i,v in pairs(Players) do
		if v == 0 then return end
	end
	print("Starting game!")
	GameInProgress = true
end)

PS.PlayerRemoving:Connect(function(player)
	local oppTeam    
	if player.Team.Name == "White" then
		oppTeam = "Black"
	else
		oppTeam = "White"
	end
	GameEvent:FireClient(Players["Plr"..oppTeam],"Resign")
end)

--TEST STUFF

