--Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Teams = game:GetService("Teams")

--Modules
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Board = require(Modules.Board)

--Remote events and functions
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local RequestMove = Remotes:WaitForChild("RequestMove")
local Promotion = Remotes:WaitForChild("Promotion")
local ClientBoardUpdate = Remotes:WaitForChild("ClientBoardUpdate")
local GetPSDictionary = Remotes:WaitForChild("GetPieceSpotDictionary")

--Containers
local WorkspaceBoard = game.Workspace.Board

local ChessGame = {}
ChessGame.__index = ChessGame

function ChessGame.new(service)
	local self = setmetatable({}, ChessGame)

	if service then
		self.ChessService = service
	end

	self.CurrentBoard = Board.new(false, self)
	self.CurrentBoard:Init(WorkspaceBoard)

	self.GameInProgress = false
	self.GameOver = false
	self.CurrentTurn = true -- True for white , false for black.
	self.Players = service.Players or {
		["Black"] = nil,
		["White"] = nil,
	}

	self.Status = Instance.new("BindableEvent")

	self.RequestMoveEvent = RequestMove.OnServerEvent:Connect(function(plr, pieceSpotName, targetSpotName)
		
		if not (self.GameInProgress and not self.GameOver) then
			return
		end

		if (self.CurrentTurn and plr.Team.Name ~= "White") or (not self.CurrentTurn and plr.Team.Name ~= "Black") then
			return
		end

		local pieceSpotCoordinates = pieceSpotName:split("")
		local targetSpotCoordinates = targetSpotName:split("")

		local move = self.CurrentBoard:MakeMove(pieceSpotCoordinates, targetSpotCoordinates)

		print(self)
		if move.GameEnded then
			move.EndInfo = {}

			if move.IsDraw then
				move.EndInfo.isDraw = true
			else
				move.EndInfo.winner = move.Winner
				move.EndInfo.loser = move.Winner == "Black" and "White" or "Black"

				move.Winner = nil
			end

			move.EndInfo.reason = move.GameEndReason

			move.GameEndReason = nil
		end

		print(move.EndInfo)
		if self.ChessService then
			-- just in case some additional code needs to be run before clients are updated
			self.ChessService:UpdateClients(move:CreateSendableObject())
		else
			-- ofc this cannot work if the game has ended and :Destroy() has been called (ChessService will be nil)
			ClientBoardUpdate:FireAllClients(move:CreateSendableObject())
		end
		
		
		if move.GameEnded then
			return
		end

		self.CurrentTurn = not self.CurrentTurn
		workspace.WhoseTurn.Value = self.CurrentTurn

		--Debug
		if workspace.Debug and workspace.Debug.Value == true and RunService:IsStudio() then
			if plr.Team == Teams["Black"] then
				plr.Team = Teams["White"]
			else
				plr.Team = Teams["Black"]
			end
		end
	end)

	GetPSDictionary.OnServerInvoke = self:GetPieceSpotDictionaryFunction()

	return self
end

function ChessGame:GetPieceSpotDictionaryFunction()
	return function()
		local Dictionary = {}
		for _, spot in pairs(self.CurrentBoard.Spots) do
			if not spot.Piece then
				continue
			end
			Dictionary[spot.Letter .. spot.Number] = spot.Piece.Instance
		end

		return Dictionary
	end
end

function ChessGame:PromptPromotion(team)
	local plr = self.Players[team]
	if not plr then
		error("Player not found")
	end

	Promotion:FireClient(plr)
	local _, promotedPiece = Promotion.OnServerEvent:Wait(50)

	return promotedPiece
end

function ChessGame:End(reason, isDraw)
	self.GameOver = true
	self.GameInProgress = false

	self.Status:Fire({
		message = "End",
		reason = reason,
		winner = self.CurrentTurn and "White" or "Black",
		loser = self.CurrentTurn and "Black" or "White",
		isDraw = isDraw,
	})
end

function ChessGame:Check(checkedTeam)
	self.Status:Fire({
		message = "Check",
		checkedTeam = checkedTeam,
	})
end

function ChessGame:Destroy()
	self.Status:Destroy()
	self.RequestMoveEvent:Disconnect()
	GetPSDictionary.OnServerInvoke = nil

	self.CurrentBoard:Destroy()
	
	for key, value in pairs(self) do
		self[key] = nil
	end
end

return ChessGame
