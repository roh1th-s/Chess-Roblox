local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Config = require(Modules:WaitForChild("Config"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local ServerPiecePositionUpdate = Remotes:WaitForChild("ServerPiecePositionUpdate")

local PieceTween = {}

function PieceTween.AnimatePieceMove(pieceInstance, arg2)
	local arg2Type = typeof(arg2)

	local tweenDuration = Config.PieceTween.Duration
	local tweenEasingStyle = Config.PieceTween.EasingStyle

	local finalPos

	-- a spot instance has been passed in
	if arg2Type == "Instance" then
		local Offset = (pieceInstance.Size.Y / 2) + (arg2.Size.Y / 2)
		finalPos = arg2.Position + Vector3.new(0, Offset, 0)
		-- a vector 3 final position has been passed in
	elseif arg2Type == "Vector3" then
		finalPos = arg2
	end

	if not finalPos then
		warn("Incorrect inputs to piece tween function")
		return
	end

	local tween = TweenService:Create(
		pieceInstance,
		TweenInfo.new(tweenDuration, tweenEasingStyle),
		{ Position = finalPos }
	)

	task.spawn(function()
		tween:Play()
		tween.Completed:Wait(5)

		if not RunService:IsServer() then
			ServerPiecePositionUpdate:FireServer(pieceInstance, finalPos)
		end
	end)
end

function PieceTween.AnimatePieceCapture(piece)
	local typeOfArg = typeof(piece)
	local pieceInstance
	local teamName

	local tweenDuration = Config.PieceTween.Duration
	local tweenEasingStyle = Config.PieceTween.EasingStyle

	if typeOfArg == "table" then
		pieceInstance = piece.Instance
		teamName = piece.Team
	elseif typeOfArg == "Instance" then
		pieceInstance = piece

		--prolly should change this later; currently the container for the pieces has the team's name
		teamName = pieceInstance.Parent.Name
	end

	local originInstance = workspace[teamName .. "Origin"]
	local capturedTeamPieces = workspace["Captured" .. teamName]

	local PieceSize = pieceInstance.Size
	local originInstanceSize = originInstance.Size

	local Offset = Vector3.new(0, 0.05 + PieceSize.Y / 2, 0)
	
	local n = #(capturedTeamPieces:GetChildren()) - 1 --subtract by one because the new piece is already in the container by now.

	if n >= 8 then
		n -= 8

		--offset backward if its in row 2
		Offset = Offset + Vector3.new(0, 0, originInstanceSize.Z)
	end

	local pos = (originInstance.Position + Offset) + (Vector3.new(originInstanceSize.X, 0, 0) * n)
	local newCFrame = CFrame.new(pos) * CFrame.Angles(0, math.rad(180), 0)

	local fadeOut = TweenService:Create(
		pieceInstance,
		TweenInfo.new(0.25, tweenEasingStyle),
		{Transparency = 1}
	)

	local fadeIn = TweenService:Create(
		pieceInstance,
		TweenInfo.new(0.25, tweenEasingStyle),
		{Transparency = 0}
	)

	--[[ local tween = TweenService:Create(
		pieceInstance,
		TweenInfo.new(tweenDuration, tweenEasingStyle),
		{ CFrame = newCFrame }
	) ]]

	task.spawn(function()
		fadeOut:Play()
		fadeOut.Completed:Wait()
		pieceInstance.CFrame = newCFrame
		fadeIn:Play()

		if not RunService:IsServer() then
			ServerPiecePositionUpdate:FireServer(pieceInstance, newCFrame)
		end
	end)
end

return PieceTween
