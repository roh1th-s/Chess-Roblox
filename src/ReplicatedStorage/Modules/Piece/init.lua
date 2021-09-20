local TS = game:GetService("TweenService")
local RS = game:GetService("ReplicatedStorage")

local Modules = RS:WaitForChild("Modules")
local Move = require(Modules:WaitForChild("Move"))
local Config = require(Modules:WaitForChild("Config"))

local Remotes = RS:WaitForChild("Remotes")
local OnClientTween = Remotes:WaitForChild("OnClientTween")

local Piece = {}
Piece.__index = Piece

Piece.Number = 0
Piece.Letter = ''
Piece.Team = ''

function Piece.new(spot, team, createInstance) 
	local self = {}

	self.Spot = spot
	self.Board = spot.Board
	self.Number = spot.Number
	self.Letter = spot.Letter
	self.Captured = false
	self.HasMoved = false

	if team == "White" then
		self.Team = team
	else
		self.Team = "Black"
	end

	if createInstance then
		self.isServer = true
	else
		self.isServer = false
	end

	return self
end

function Piece:getOppTeam()
	if self.Team == "White" then
		return "Black"
	end
	return "White"
end

function Piece:MoveTo(arg1, arg2)
	local targetSpot
	if typeof(arg1) == "Instance" then
		targetSpot = arg1
	else
		targetSpot = self.Board:GetSpotObjectAt(arg1, arg2)
	end

	local initOccupyingPiece = targetSpot.Piece
	local initSpot = self.Spot

	if initOccupyingPiece then
		initOccupyingPiece.Captured = true
		initOccupyingPiece.Spot = nil			
		initOccupyingPiece.Number = nil
		initOccupyingPiece.Letter = nil
	end

	initSpot:SetPiece(nil)
	targetSpot:SetPiece(self)

	self.Spot = targetSpot
	self.Number = targetSpot.Number
	self.Letter = targetSpot.Letter

	if self.Type == "Pawn" then 
		local diffBetweenInitialAndTargetSpotNum = math.abs(targetSpot.Number - initSpot.Number)
		if not self.HasMoved and diffBetweenInitialAndTargetSpotNum == 2 and not self.CanBeKilledByEnPassant then
			self.CanBeKilledByEnPassant = true
		else if self.CanBeKilledByEnPassant then
				self.CanBeKilledByEnPassant = false
			end
		end
	end

	self.HasMoved = true

	if self.isServer then
		
		if initOccupyingPiece then
			initOccupyingPiece.Instance.Parent = workspace:WaitForChild("Captured" .. initOccupyingPiece.Team)
		end
		
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
	:setCapturedPiece(initOccupyingPiece)

	return move
	
end

function Piece:GetMoves() end

return Piece