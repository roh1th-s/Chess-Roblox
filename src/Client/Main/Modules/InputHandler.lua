--services
local RS = game:GetService("ReplicatedStorage")
local TS = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local GUIS = game:GetService("GuiService")

--events
local Remotes = RS:WaitForChild("Remotes")
local RequestMove = Remotes:WaitForChild("RequestMove")

local byte = string.byte
local insert = table.insert

local TopBarSize = GUIS:GetGuiInset()
local camera = workspace.CurrentCamera

local blackPieces = workspace:WaitForChild("Black")
local whitePieces = workspace:WaitForChild("White")
local board = workspace:WaitForChild("Board")

local InputHandler = {}
InputHandler.__index = InputHandler

function InputHandler:IsMoveValid(target)
	local CheckFunc
	if type(target) == "userdata" then
		CheckFunc = function(spot)
			if spot.Instance == target then
				return true
			end
			return false
		end
	else
		CheckFunc = function(spot)
			if spot == target then
				return true
			end
			return false
		end
	end
	for _, move in pairs(self.Moves) do
		local spot = self.Client.BoardObject:GetSpotObjectAt(move.TargetPosLetter, move.TargetPosNumber)
		if CheckFunc(spot) then
			return true
		end
	end
	return false
end

function InputHandler:Init(client)
	self.Client = client
	self.Player = client.Player

	local selection = RS:WaitForChild("Highlight"):Clone()
	selection.Name = "Selection"
	selection.Material = Enum.Material.Plastic
	selection.Transparency = 1
	selection.Anchored = true
	selection.CanCollide = false

	self.Selection = selection

	self.IndicatorColors = {
		Indicator1 = Color3.fromRGB(173, 120, 27),
		Normal = Color3.fromRGB(86, 86, 86),
		Attack = Color3.fromRGB(165, 0, 30),
		Check = Color3.fromRGB(255, 0, 0),
		LastMoveInitSpot = Color3.fromRGB(216, 184, 130),
		LastMoveTargetSpot = Color3.fromRGB(223, 168, 74),
	}

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Whitelist
	raycastParams.FilterDescendantsInstances = { board, whitePieces, blackPieces }
	raycastParams.IgnoreWater = true

	self.RayCastParams = raycastParams

	self.SelectedPiece = nil
	self.Moves = {}

	UIS.InputBegan:Connect(function(input, processedByUi)
		if processedByUi or (not self.Client.LocalPlayersTurn) or self.Client.GameOver then
			return
		end

		local vect2Pos
		if
			input.UserInputType == Enum.UserInputType.Touch
			or input.UserInputType == Enum.UserInputType.MouseButton1
		then
			vect2Pos = input.Position
		else
			return
		end

		local unitRay = camera:ViewportPointToRay(vect2Pos.X, vect2Pos.Y + TopBarSize.Y, 0)

		local raycastResult = workspace:Raycast(unitRay.Origin, unitRay.Direction * 500, self.RayCastParams)

		if raycastResult then
			self:HandleInput(raycastResult.Instance)
		end
	
	end)

	--workspace.WhoseTurn.Changed:Connect(function(newVal)
	--	if newVal then
	--		if self.Player.Team.Name == "White" then
	--			self.turn = true
	--			return
	--		end
	--	else
	--		if self.Player.Team.Name == "Black" then
	--			self.turn = true
	--			return
	--		end
	--	end
	--	self.turn = false
	--end)
end

function InputHandler:ClearHighlights()
	for _, highlight in pairs(camera:GetChildren()) do
		if highlight:IsA("Folder") then continue end
		highlight:Destroy()
	end
end

function InputHandler:CreateHighlight(spot, color, isIndicator)
	local highlight = self.Selection:Clone()
	local piece = self.Client.BoardObject:GetPieceObjectAtSpot(spot)
	local coordsOfSpot = string.split(spot.Name, "")

	if piece and piece.Team ~= self.Player.Team.Name then
		highlight.Color = color or self.IndicatorColors.Attack
	elseif not piece and self.SelectedPiece and self.SelectedPiece.Type == "Pawn" then
		--En Passant
		local letterDiffFromTargetSpot = math.abs(byte(coordsOfSpot[1]) - byte(self.SelectedPiece.Letter))

		if letterDiffFromTargetSpot == 1 then
			print("En passant")
			highlight.Color = color or self.IndicatorColors.Attack
		else
			highlight.Color = color or self.IndicatorColors.Normal
		end
	else
		highlight.Color = color or self.IndicatorColors.Normal
	end

	highlight.Size = spot.Size + Vector3.new(0, 0.25, 0)
	highlight.Position = spot.Position --+ Vector3.new(0,Coordinate.Size.Y/2,0)

	if isIndicator then
		local indicators = camera:FindFirstChild("Indicators")
		if not indicators then 
			indicators = Instance.new("Folder")
			indicators.Name = "Indicators"
			indicators.Parent = camera
		end
		highlight.Size = spot.Size + Vector3.new(0, 0.01, 0)
		highlight.Parent = indicators
	else
		highlight.Parent = camera
	end
	
	TS:Create(highlight, TweenInfo.new(0.1), { Transparency = 0 }):Play()
end

function InputHandler:HighlightMoves()
	for _, move in pairs(self.Moves) do
		local spot = self.Client.BoardObject:GetSpotObjectAt(move.TargetPosLetter, move.TargetPosNumber)
		if type(spot) == "userdata" then
			self:CreateHighlight(spot)
		else
			self:CreateHighlight(spot.Instance)
		end
	end
end

function InputHandler:HandleMove(pieceSpotName, targetSpotName)
	RequestMove:FireServer(pieceSpotName, targetSpotName)
end

function InputHandler:HandleInput(target)
	if not target or self.Client.IsUpdating or self.Client.IsPromotion then
		self:ClearHighlights()
		return
	end

	if target.Parent.Name == "Board" then
		--If target is a spot
		local piece = self.Client.BoardObject:GetPieceObjectAtSpot(target)

		if piece then
			if self.SelectedPiece then
				if self:IsMoveValid(target) then
					self:ClearEventIndicators()
					self:HandleMove(self.SelectedPiece.Spot.Instance.Name, target.Name)
				end
				self:ClearHighlights()

				self.Moves = {}
				self.SelectedPiece = false
			else
				if piece.Team == self.Player.Team.Name then
					self:CreateHighlight(target, self.IndicatorColors["Indicator1"])
					self.SelectedPiece = piece
					self.Moves = piece:GetMoves()
					self:HighlightMoves()
				end
			end
		else
			if self.SelectedPiece then
				if self:IsMoveValid(target) then
					self:ClearEventIndicators()
					self:HandleMove(self.SelectedPiece.Spot.Instance.Name, target.Name)
				end
				self:ClearHighlights()
				self.Moves = {}
				self.SelectedPiece = nil
			else
				self:ClearHighlights()
			end
		end
	elseif target.Parent.Name == "White" or target.Parent.Name == "Black" then
		--If target is a piece
		local piece = self.Client.BoardObject:GetPieceObjectFromInstance(target)

		if not piece then
			error("Piece object wasn't found")
		end
		if self.SelectedPiece then
			if self:IsMoveValid(piece.Spot.Instance) == true then
				self:ClearEventIndicators()
				self:HandleMove(self.SelectedPiece.Spot.Instance.Name, piece.Spot.Instance.Name)
			end
			self:ClearHighlights()
			self.Moves = {}
			self.SelectedPiece = nil
		else
			if piece.Team == self.Player.Team.Name then
				self:CreateHighlight(piece.Spot.Instance, self.IndicatorColors["Indicator1"])
				self.SelectedPiece = piece

				self.Moves = piece:GetMoves()
				self:HighlightMoves()
			end
		end
	else
		--If target is not a spot or a piece
		self:ClearHighlights()
	end
end

function InputHandler:ClearEventIndicators()
	if not camera:FindFirstChild("Indicators") then return end
	for _, indicator in pairs(camera.Indicators:GetChildren()) do
		indicator:Destroy()
	end
end

function InputHandler:IndicateCheck(kingSpot)
	if kingSpot ~= "userdata" then kingSpot = kingSpot.Instance end
	self:CreateHighlight(kingSpot, self.IndicatorColors.Check, true)
end

function InputHandler:IndicateLastMove(move)
	local initSpot = workspace.Board[move.InitPosLetter .. move.InitPosNumber]
	local targetSpot = workspace.Board[move.TargetPosLetter .. move.TargetPosNumber]

	self:CreateHighlight(initSpot, self.IndicatorColors.LastMoveInitSpot, true)
	self:CreateHighlight(targetSpot, self.IndicatorColors.LastMoveTargetSpot, true)
end

return InputHandler
