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

function InputHandler.new(client)
	local self = setmetatable({}, InputHandler)

	self.Client = client
	self.Player = client.Player
	self.Board = self.Client.BoardObject

	local selection = RS:WaitForChild("Highlight"):Clone()
	selection.Name = "Selection"
	selection.Material = Enum.Material.Plastic
	selection.Transparency = 1
	selection.Anchored = true
	selection.CanCollide = false

	self.Selection = selection

	self.IndicatorColors = {
		["Indicator1"] = Color3.fromRGB(173, 120, 27),
		["Normal"] = Color3.fromRGB(86, 86, 86),
		["Attack"] = Color3.fromRGB(165, 0, 30),
		["Check"] = Color3.fromRGB(255, 0, 0),
	}

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Whitelist
	raycastParams.FilterDescendantsInstances = { board, whitePieces, blackPieces }
	raycastParams.IgnoreWater = true

	self.RayCastParams = raycastParams

	return self
end

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
		local spot = self.Board:GetSpotObjectAt(move.TargetPosLetter, move.TargetPosNumber)
		if CheckFunc(spot) then
			return true
		end
	end
	return false
end

function InputHandler:Init()
	self.SelectedPiece = nil
	self.Moves = {}

	UIS.InputBegan:Connect(function(input, processedByUi)
		if processedByUi then
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
		highlight:Destroy()
	end
end

function InputHandler:CreateHighlight(spot, color)
	local highlight = self.Selection:Clone()
	local piece = self.Board:GetPieceObjectAtSpot(spot)
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

	highlight.Size = spot.Size + Vector3.new(0, 0.2, 0)
	highlight.Position = spot.Position --+ Vector3.new(0,Coordinate.Size.Y/2,0)
	highlight.Parent = camera
	TS:Create(highlight, TweenInfo.new(0.1), { Transparency = 0.1 }):Play()
end

function InputHandler:HighlightMoves()
	for _, move in pairs(self.Moves) do
		local spot = self.Board:GetSpotObjectAt(move.TargetPosLetter, move.TargetPosNumber)
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
		local piece = self.Board:GetPieceObjectAtSpot(target)

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
		local piece = self.Board:GetPieceObjectFromInstance(target)

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
	for _, indicator in pairs(workspace["EventIndicators"]:GetChildren()) do
		indicator:Destroy()
	end
end

function InputHandler:CheckIndicator()
	local king = workspace[self.Player.Team.Name]:FindFirstChild("King")
	local square = king.Coordinates.Value
	local CH = self.Selection:Clone()
	CH.Material = Enum.Material.Neon
	CH.Color = self.IndicatorColors["Check"]
	CH.Size = square.Size + Vector3.new(0, 0.2, 0)
	CH.Position = square.Position
	CH.Parent = workspace["EventIndicators"]
	TS:Create(CH, TweenInfo.new(0.1), { Transparency = 0.1 }):Play()
end

return InputHandler
