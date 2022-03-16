local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local SharedModules = RS:WaitForChild("Modules")
local Board = require(SharedModules:WaitForChild("Board"))

local ClientModules = script.Parent:WaitForChild("Modules")

local Remotes = RS:WaitForChild("Remotes")
local RematchEvent = Remotes:WaitForChild("Rematch")
local PromotionEvent = Remotes:WaitForChild("Promotion")
local PlayerReady = Remotes:WaitForChild("PlayerReady")
local GameEvent = Remotes:WaitForChild("GameEvent")
local ClientBoardUpdate = Remotes:WaitForChild("ClientBoardUpdate")

local Client = {}

function Client:Init()
	self.Player = Players.LocalPlayer
	self.LocalPlayersTurn = nil
	self.IsUpdating = false
	self.IsPromotion = false
	self.GameOver = false

	self.GameEventConnection = GameEvent.OnClientEvent:Connect(function(...)
		self:HandleGameEvent(...)
	end)

	self.ClientBoardUpdateConnection = ClientBoardUpdate.OnClientEvent:Connect(function(...)
		self:HandleClientBoardUpdate(...)
	end)

	self.PromotionEventConnection = PromotionEvent.OnClientEvent:Connect(function(...)
		self:HandlePromotion(...)
	end)

	--Load board object first (before modules)
	self.BoardObject = Board.new(true, self)

	--Dynamic module loading
	for _, module in pairs(ClientModules:GetChildren()) do
		if not module:IsA("ModuleScript") then
			continue
		end

		local moduleName = module.Name

		module = require(module)
		self[moduleName] = module
		module:Init(self)
	end

	-- tell the server we're ready to start receving game events
	PlayerReady:FireServer()

	print("Client initialized")
end

function Client:HandleGameEvent(data)
	if data then
		local message = data.message
		if message == "Start" then
			if not self.BoardObject then
				-- happens only during a rematch
				self.BoardObject = Board.new(true, self)
				self.IsUpdating = false
				self.IsPromotion = false
				self.GameOver = false
				self.GameUIHandler:ResetUI()
			end

			if data.turn then
				self.LocalPlayersTurn = true
				self.GameUIHandler:UpdateStatus({ message = "Your turn" })
			else
				self.LocalPlayersTurn = false
				self.GameUIHandler:UpdateStatus({ message = "Opponent's turn" })
			end

			self.BoardObject:Init(workspace.Board)
		elseif message == "RematchRequest" then
			
			if not data.initiatingPlayer or data.initiatingPlayer == self.Player then
				--[[ --Debug
				if not (workspace.Debug and workspace.Debug.Value == true and RunService:IsStudio()) then
					return
				end	 ]]
				return
			end
			
			print(data)
			self.GameUIHandler:ShowNotification({ message = data.initiatingPlayer.Name .. " has requested a rematch!" })
		end
	end
end

function Client:HandlePromotion()
	self.IsPromotion = true
	self.GameUIHandler:HandlePromotion()
end

function Client:HandleGameEnd(endData)
	self.GameOver = true
	self.BoardObject:Destroy()
	self.BoardObject = nil
	self.InputHandler:ClearEventIndicators()
	self.GameUIHandler:EndGame(endData)
end

function Client:HandleClientBoardUpdate(move)
	if move.GameEnded then
		if move.EndInfo.winner then
			move.EndInfo.playerWon = move.EndInfo.winner == self.Player.Team.Name
		end
		self:HandleGameEnd(move.EndInfo)
		return
	end

	self.IsUpdating = true

	--Update the local state of the board (including turn)
	self.BoardObject:Update(move)

	self.InputHandler:ClearEventIndicators()

	if move.IsCheck then
		local checkedTeam = move.CheckData and move.CheckData.CheckedTeam or nil
		local localPlayerChecked = checkedTeam and checkedTeam == self.Player.Team.Name or false

		self.GameUIHandler:UpdateStatus({ message = "Check", checkedTeam = localPlayerChecked and nil or checkedTeam })
		if checkedTeam then
			self.InputHandler:IndicateCheck(self.BoardObject.Kings[checkedTeam].Spot)
		end
	else
		if self.LocalPlayersTurn then
			self.GameUIHandler:UpdateStatus({ message = "Your turn" })
		else
			self.GameUIHandler:UpdateStatus({ message = "Opponent's turn" })
		end
	end

	self.InputHandler:IndicateLastMove(move)

	self.IsUpdating = false
end

function Client:HandleUIEvent(eventName, data)
	if eventName == "Rematch" then
		print("Requesting rematch")
		RematchEvent:FireServer()
	end
end

return Client
