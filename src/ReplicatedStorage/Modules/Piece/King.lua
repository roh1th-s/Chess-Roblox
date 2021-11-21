local RS = game:GetService("ReplicatedStorage")
local TS = game:GetService("TweenService")
local PieceModels = RS:WaitForChild("PieceModels")

local Piece = require(script.Parent)

local Modules = RS:WaitForChild("Modules")
local Move = require(Modules:WaitForChild("Move"))
local Config = require(Modules:WaitForChild("Config"))

local Remotes = RS:WaitForChild("Remotes")
local OnClientTween = Remotes:WaitForChild("OnClientTween")

local insert = table.insert
local char = string.char
local byte = string.byte
local num = tonumber

local King = {}
King.__index = King
setmetatable(King, Piece)

function King.new(...)
	local self = Piece.new(...)
	setmetatable(self, King)

	self.Type = "King"

	if self.isServer then
		local model = PieceModels.King:Clone()
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

--function King:MoveTo(letter,number)
--TODO Implement
--end
function King:Castle(rook, options)
	local simulatedMove = options and options.simulatedMove or false

	local kingTargetSpotLetter = rook.Letter == "A" and "C" or "G"
	local rookTargetSpotLetter = rook.Letter == "A" and "D" or "F"

	local kingTargetSpot = self.Board:GetSpotObjectAt(kingTargetSpotLetter, self.Number)
	local rookTargetSpot = self.Board:GetSpotObjectAt(rookTargetSpotLetter, self.Number)

	local initKingSpot = self.Spot
	local initRookSpot = rook.Spot

	initKingSpot:SetPiece(nil)
	initRookSpot:SetPiece(nil)
	rookTargetSpot:SetPiece(rook)
	kingTargetSpot:SetPiece(self)

	self.Spot = kingTargetSpot
	self.Number = kingTargetSpot.Number
	self.Letter = kingTargetSpot.Letter
	self.HasMoved = true

	rook.Spot = rookTargetSpot
	rook.Number = rookTargetSpot.Number
	rook.Letter = rookTargetSpot.Letter
	rook.HasMoved = true

	if not simulatedMove then
		if not self.isServer then
			local tweenDuration = Config.PieceTween.Duration
			local tweenEasingStyle = Config.PieceTween.EasingStyle

			--Moving king
			local Offset = (self.Instance.Size.Y / 2) + (kingTargetSpot.Instance.Size.Y / 2)
			local KingPos = kingTargetSpot.Instance.Position + Vector3.new(0, Offset, 0)

			local kingTween = TS:Create(
				self.Instance,
				TweenInfo.new(tweenDuration, tweenEasingStyle),
				{ Position = KingPos }
			)

			--Moving rook
			local Offset = (rook.Instance.Size.Y / 2) + (rookTargetSpot.Instance.Size.Y / 2)
			local RookPos = rookTargetSpot.Instance.Position + Vector3.new(0, Offset, 0)

			local rookTween = TS:Create(
				rook.Instance,
				TweenInfo.new(tweenDuration, tweenEasingStyle),
				{ Position = RookPos }
			)

			task.spawn(function()
				kingTween:Play()
				rookTween:Play()

				if not rookTween.PlaybackState == Enum.PlaybackState.Completed then
					rookTween.Completed:Wait(5)
				end

				OnClientTween:FireServer(self.Instance, KingPos)
				OnClientTween:FireServer(rook.Instance, RookPos)
			end)

			return true -- no need to do the rest if on client
		end
	end
	
	local castlingMoves = {
		["InitPosLetter"] = initRookSpot.Letter,
		["InitPosNumber"] = initRookSpot.Number,
		["TargetPosLetter"] = rookTargetSpot.Letter,
		["TargetPosNumber"] = rookTargetSpot.Letter,
	}

	local move = Move.new()
		:SetInitSpot(initKingSpot)
		:SetTargetSpot(kingTargetSpot)
		:SetMovedPiece(self)
		:SetCastlingMoves(castlingMoves)

	return move
end

function King:GetMoves(options)
	local moves = {}
	local oppTeam = self:GetOppTeam()
	local lnum = byte(self.Letter)
	local number = num(self.Number)

	local onlyAttacks, bypassCheckCondition
	if options then
		onlyAttacks = options.onlyAttacks or nil
		bypassCheckCondition = options.bypassCheckCondition or nil
	end

	for i = number - 1, number + 1 do
		for q = lnum - 1, lnum + 1 do
			if q == lnum and i == number then
				continue
			end
			local spot = self.Board:GetSpotObjectAt(char(q) .. i)

			if spot then
				local move = Move.new():SetInitSpot(self.Spot):SetTargetSpot(spot)
				if not spot.Piece then
					insert(moves, move)
				else
					if spot.Piece.Team == oppTeam then
						insert(moves, move)
					end
				end
			end
		end
	end

	--local canCastle = true
	if not onlyAttacks then
		if not self.HasMoved and not self.Board:IsCheck(self.Team) then
			local queenSideRook = self.Board:GetPieceObjectAtSpot("A" .. self.Number)
			local kingSideRook = self.Board:GetPieceObjectAtSpot("H" .. self.Number)

			if queenSideRook and not queenSideRook.HasMoved then
				local firstSpot = self.Board:GetSpotObjectAt(char(byte(self.Letter) - 1) .. self.Number)
				local secondSpot = self.Board:GetSpotObjectAt(char(byte(self.Letter) - 2) .. self.Number)
				local firstSpotPassable = not firstSpot:IsUnderAttack(self.Team) and not firstSpot.Piece
				local secondSpotPassable = not secondSpot:IsUnderAttack(self.Team) and not secondSpot.Piece

				if firstSpotPassable and secondSpotPassable then
					local move = Move.new():SetInitSpot(self.Spot):SetTargetSpot(secondSpot):SetIsCastling(true)

					insert(moves, move)
				end
			end

			if kingSideRook and not kingSideRook.HasMoved then
				local firstSpot = self.Board:GetSpotObjectAt(char(byte(self.Letter) + 1) .. self.Number)
				local secondSpot = self.Board:GetSpotObjectAt(char(byte(self.Letter) + 2) .. self.Number)
				local firstSpotPassable = not firstSpot:IsUnderAttack(self.Team) and not firstSpot.Piece
				local secondSpotPassable = not secondSpot:IsUnderAttack(self.Team) and not secondSpot.Piece

				if firstSpotPassable and secondSpotPassable then
					local move = Move.new():SetInitSpot(self.Spot):SetTargetSpot(secondSpot):SetIsCastling(true)

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

return King
