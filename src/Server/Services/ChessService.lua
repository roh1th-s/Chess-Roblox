local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local PlayerService = game:GetService("Players")
local Teams = game:GetService("Teams")

local Modules = ServerScriptService:WaitForChild("Modules")
local ChessGame = require(Modules:WaitForChild("ChessGame"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local RematchEvent = Remotes:WaitForChild("Rematch")
local PlayerReady = Remotes:WaitForChild("PlayerReady")
local GameEvent = Remotes:WaitForChild("GameEvent")
local ServerPiecePositionUpdate = Remotes:WaitForChild("ServerPiecePositionUpdate")

local insert = table.insert
local function table_length(t)
	local z = 0.
	for i, v in pairs(t) do
		z = z + 1
	end
	return z
end

local ChessService = {}

function ChessService:Init()
	self.GameInProgress = false
	self.Players = {
		Black = nil,
		White = nil,
	}
	self.Spectators = {}

	self.CurrentGame = ChessGame.new(self)
	self.RematchConsents = {}

	self.GameUpdateConnection = self.CurrentGame.Status.Event:Connect(function(...)
		self:HandleGameUpdate(...)
	end)

	self.PlayerJoinConnection = PlayerReady.OnServerEvent:Connect(function(...)
		self:HandlePlayerReady(...)
	end)

	self.UpdateServerPiecePositionEvent = ServerPiecePositionUpdate.OnServerEvent:Connect(function(...)
		self:HandlePiecePositionUpdate(...)
	end)

	self.RematchEventConnection = RematchEvent.OnServerEvent:Connect(function(...)
		self:HandleRematch(...)
	end)
end

function ChessService:HandleGameUpdate(info)
	local message = info.message

	if message == "End" then
		self.GameInProgress = false
		local reason = info.reason
		local winner = info.winner

		print("Game ended. Reason: " .. reason .. " Winner: " .. (info.isDraw and "Draw" or winner))

		self.CurrentGame:Destroy()
		self.CurrentGame = nil
		self.GameInProgress = false

		--[[ self.Players = {
			Black = nil,
			White = nil,
		} ]]

		self.GameUpdateConnection:Disconnect()
	elseif message == "Check" then
		print("Check")
		-- do something
	end
end

function ChessService:SetPlayerTeam(plr, teamName)
	plr.Team = Teams[teamName]
	if teamName == "Spectators" then
		insert(self.Spectators, plr)
	else
		self.Players[teamName] = plr
	end
end

function ChessService:HandleRematch(plr)
	if self.RematchConsents[plr.UserId] then
		return
	end
	self.RematchConsents[plr.UserId] = true
	if table_length(self.RematchConsents) >= 2 then
		if self.CurrentGame then
			self.CurrentGame:Destroy()
		end

		self.CurrentGame = ChessGame.new(self)
		self.GameUpdateConnection = self.CurrentGame.Status.Event:Connect(function(...)
			self:HandleGameUpdate(...)
		end)
		self.RematchConsents = {}

		self:StartGame() -- same teams from last match, as of now
	else
		print("Sending out rematch notification")
		GameEvent:FireAllClients({ message = "RematchRequest", initiatingPlayer = plr })
	end
end

function ChessService:HandlePlayerReady(plr)
	--TODO Implement a proper system for teams

	--If white team's player already exists
	if self.Players["White"] then
		--If opposite team player doesnt exist then assign
		if not self.Players["Black"] then
			self:SetPlayerTeam(plr, "Black")
		else
			--If both players are there add to spectators list
			self:SetPlayerTeam(plr, "Spectators")
		end
	else
		--If white team player doesnt exist then assign
		self:SetPlayerTeam(plr, "White")
	end

	if self.Players["Black"] and self.Players["White"] then
		self:StartGame()
	end

	--Debug
	if workspace.Debug and workspace.Debug.Value == true and RunService:IsStudio() then
		-- white player will be set first, then set black manually for singleplayer testing
		self.Players["Black"] = plr
		self:StartGame()
	end
end

function ChessService:StartGame()
	self.GameInProgress = true
	self.CurrentGame.GameInProgress = true

	GameEvent:FireClient(self.Players["Black"], { message = "Start" })
	GameEvent:FireClient(self.Players["White"], { message = "Start", turn = true })

	--tell spectators as well?
end

function ChessService:HandlePiecePositionUpdate(_, instance, newCFrame)
	local typeOfArg = typeof(newCFrame)
	if typeOfArg == "Vector3" then
		instance.Position = newCFrame
	elseif typeOfArg == "CFrame" then
		instance.CFrame = newCFrame
	end
end

return ChessService
