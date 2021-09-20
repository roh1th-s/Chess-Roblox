--Services
local SSS = game:GetService("ServerScriptService")
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local TS = game:GetService("TweenService")
local PS = game:GetService("Players")
local Teams = game:GetService("Teams")

--Modules
local Modules = RS:WaitForChild("Modules")
local Board = require(Modules.Board)
local Spot = require(Modules.Spot)

--Remote events and functions
local Remotes = RS:WaitForChild("Remotes")
local RequestMove = Remotes:WaitForChild("RequestMove")
local Promotion = Remotes:WaitForChild("Promotion")
local GameEvent = Remotes:WaitForChild("GameEvent")
local OnClientTween = Remotes:WaitForChild("OnClientTween")
local ClientUpdate = Remotes:WaitForChild("ClientUpdate")
local GetPSDictionary = Remotes:WaitForChild("GetPieceSpotDictionary")

--Instance tables
local CB = game.Workspace.CapturedBlack
local CW = game.Workspace.CapturedWhite
local WorkspaceBoard = game.Workspace.Board

local ChessGame = {}
ChessGame.__index = ChessGame

ChessGame.Instance = nil

function ChessGame.new()
	if ChessGame.Instance then
		return ChessGame.Instance
	end
	
	local self = setmetatable({}, ChessGame)
	ChessGame.Instance = self
	
	self.currentBoard = Board.new(false, self)
	self.currentBoard:Init(WorkspaceBoard)

	self.gameInProgress = false
	self.gameOver = false
	self.currentTurn = true -- True for white , false for black.
	self.Players = {
		["Black"] = nil,
		["White"] = nil
	}
	self.Spectators = {}
	
	self.playerAddedEvent = PS.PlayerAdded:Connect(function(plr)
		GameEvent:FireClient(plr)
		
		if self.Players["White"] then --If white team's player already exists

			if not self.Players["Black"] then --If opposite team player doesnt exist then assign
				self.Players["Black"] = plr
				plr.Team = Teams["Black"]
			else
				table.insert(self.Spectators, plr) --If both players are there add to spectators list
				plr.Team = Teams["Spectators"]
			end
		else
			self.Players["White"] = plr --If white team player doesnt exist then assign
			plr.Team = Teams["White"]
		end
	end)	
	
	self.requestMoveEvent = RequestMove.OnServerEvent:Connect(function(plr, pieceSpotName, targetSpotName)
		local pieceSpotCoordinates = pieceSpotName:split("")
		local targetSpotCoordinates = targetSpotName:split("")

		local move = self.currentBoard:MakeMove(pieceSpotCoordinates, targetSpotCoordinates)
		
		ClientUpdate:FireAllClients(move:CreateSendableObject())
		
		self.currentTurn = not self.currentTurn
		workspace.WhoseTurn.Value = self.currentTurn
		
		--TEMP Testing Code
		if plr.Team == Teams["Black"] then
			plr.Team = Teams["White"]
		else
			plr.Team = Teams["Black"]
		end
	end)
	
	self.updateServerPiecePositionEvent = OnClientTween.OnServerEvent:Connect(function(plr, instance, newPos)
		instance.Position = newPos
	end)
	
	GetPSDictionary.OnServerInvoke = self:getPieceSpotDictionaryFunction()
end

function ChessGame:getPieceSpotDictionaryFunction()
	return function()
		local Dictionary = {}
		for _, spot in pairs(self.currentBoard.Spots) do
			if not spot.Piece then continue end
			Dictionary[spot.Letter .. spot.Number] = spot.Piece.Instance
		end

		return Dictionary
	end
end

function ChessGame:promptPromotion(team)
	local plr = self.Players[team]
	if not plr then error("Player not found") end
	print(plr)
	Promotion:FireClient(plr)
	local plr, promotedPiece = Promotion.OnServerEvent:Wait(50)
	print(promotedPiece)	
end

return ChessGame