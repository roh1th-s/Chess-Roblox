--services
local RS = game:GetService("ReplicatedStorage")
local TS = game:GetService("TweenService")
local SSS = game:GetService("ServerScriptService")
local UIS = game:GetService("UserInputService")
local GUIS = game:GetService("GuiService")

--events
local Remotes = RS:WaitForChild("Remotes")
local RequestMove = Remotes:WaitForChild("RequestMove")
local GameEvent = Remotes:WaitForChild("GameEvent")

local byte = string.byte

local plr = game.Players.LocalPlayer
local TopBarSize = GUIS:GetGuiInset()
local camera = workspace.CurrentCamera

local fixedInputFilter = workspace.Map:GetDescendants()

local WhoseTurn = workspace:WaitForChild("WhoseTurn")

local InputHandler = {}
InputHandler.__index = InputHandler

InputHandler.Colors = {
	["Indicator1"] = Color3.fromRGB(173, 120, 27),
	["Normal"] = Color3.fromRGB(86, 86, 86),
	["Attack"] = Color3.fromRGB(165, 0, 30),
	["Check"] = Color3.fromRGB(255, 0, 0),
}

local selection = RS:WaitForChild("Highlight"):Clone()
selection.Name = "Selection"
selection.Material = Enum.Material.Plastic
selection.Transparency = 1
selection.Anchored = true
selection.CanCollide = false

InputHandler.selection = selection

function InputHandler.new()
	local self = setmetatable({}, InputHandler)

	return self
end

function InputHandler.IsMoveValid(move, movesTable)
	local CheckFunc
	if type(move) == "userdata" then
		CheckFunc = function(spot)
			if spot.Instance == move then
				return true
			end
			return false
		end
	else
		CheckFunc = function(spot)
			if spot == move then
				return true
			end
			return false
		end
	end
	for i, spot in pairs(movesTable) do
		if CheckFunc(spot) then
			return true
		end
	end
	return false
end

function InputHandler:Initialize(client)
	self.client = client
	self.board = client.BoardObject
	self.selected = false
	self.selectedPiece = nil
	self.moves = {}

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

		local filter = fixedInputFilter
		for _, instance in pairs(camera:GetChildren()) do
			table.insert(filter, instance)
		end

		local unitRay = camera:ViewportPointToRay(vect2Pos.X, vect2Pos.Y + TopBarSize.Y, 0)
		local ray = Ray.new(unitRay.Origin, unitRay.Direction * 500)
		local target, pos = workspace:FindPartOnRayWithIgnoreList(ray, filter)

		self:HandleInput(target)
	end)

	--workspace.WhoseTurn.Changed:Connect(function(newVal)
	--	if newVal then
	--		if plr.Team.Name == "White" then
	--			self.turn = true
	--			return
	--		end
	--	else
	--		if plr.Team.Name == "Black" then
	--			self.turn = true
	--			return
	--		end
	--	end
	--	self.turn = false
	--end)
end

function InputHandler:ClearHighlights()
	for i, v in pairs(camera:GetChildren()) do
		v:Destroy()
	end
end

function InputHandler:CreateHighlight(spot, color)
	local highlight = selection:Clone()
	local piece = self.board:GetPieceObjectAtSpot(spot)
	local coordsOfSpot = string.split(spot.Name, "")

	if piece and piece.Team ~= plr.Team.Name then
		highlight.Color = color or InputHandler.Colors.Attack
	elseif not piece and self.selectedPiece and self.selectedPiece.Type == "Pawn" then
		--En Passant
		local letterDiffFromTargetSpot = math.abs(byte(coordsOfSpot[1]) - byte(self.selectedPiece.Letter))

		if letterDiffFromTargetSpot == 1 then
			print("En passant")
			highlight.Color = color or InputHandler.Colors.Attack
		else
			highlight.Color = color or InputHandler.Colors.Normal
		end
	else
		highlight.Color = color or InputHandler.Colors.Normal
	end

	highlight.Size = spot.Size + Vector3.new(0, 0.2, 0)
	highlight.Position = spot.Position --+ Vector3.new(0,Coordinate.Size.Y/2,0)
	highlight.Parent = camera
	TS:Create(highlight, TweenInfo.new(0.1), { Transparency = 0.1 }):Play()
end

function InputHandler:HighlightMoves(moves)
	for _, spot in pairs(self.moves) do
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
	if not target or self.client.IsUpdating then
		self:ClearHighlights()
		return
	end

	if target.Parent.Name == "Board" then
		--If target is a spot
		local piece = self.board:GetPieceObjectAtSpot(target)

		if piece then
			if self.selected == true then
				if InputHandler.IsMoveValid(target, self.moves) then
					self:ClearEventIndicators()
					self:HandleMove(self.selectedPiece.Spot.Instance.Name, target.Name)
				end
				self:ClearHighlights()
				self.selected = false
				self.moves = {}
				self.selectedPiece = false
			else
				if piece.Team == plr.Team.Name then
					self:CreateHighlight(target, InputHandler.Colors["Indicator1"])
					self.selectedPiece = piece
					self.selected = true
					self.moves = piece:GetMoves()
					self:HighlightMoves(self.moves)
				end
			end
		else
			if self.selected == true then
				if InputHandler.IsMoveValid(target, self.moves) then
					self:ClearEventIndicators()
					self:HandleMove(self.selectedPiece.Spot.Instance.Name, target.Name)
				end
				self:ClearHighlights()
				self.selected = false
				self.moves = {}
				self.selectedPiece = nil
			else
				self:ClearHighlights()
			end
		end
	elseif target.Parent.Name == "White" or target.Parent.Name == "Black" then
		--If target is a piece
		local piece = self.board:GetPieceObjectFromInstance(target)

		if not piece then
			error("Piece object wasn't found")
		end
		if self.selected == true then
			if InputHandler.IsMoveValid(piece.Spot.Instance, self.moves) == true then
				self:ClearEventIndicators()
				self:HandleMove(self.selectedPiece.Spot.Instance.Name, piece.Spot.Instance.Name)
			end
			self:ClearHighlights()
			self.selected = false
			self.moves = {}
			self.selectedPiece = nil
		else
			if piece.Team == plr.Team.Name then
				self:CreateHighlight(piece.Spot.Instance, InputHandler.Colors["Indicator1"])
				self.selectedPiece = piece
				self.selected = true
				self.moves = piece:GetMoves()
				self:HighlightMoves(self.moves)
			end
		end
	else
		--If target is not a spot or a piece
		self:ClearHighlights()
	end
end

function InputHandler:ClearEventIndicators()
	for i, indicator in pairs(workspace["EventIndicators"]:GetChildren()) do
		indicator:Destroy()
	end
end

function InputHandler:CheckIndicator()
	local king = workspace[plr.Team.Name]:FindFirstChild("King")
	local square = king.Coordinates.Value
	local CH = selection:Clone()
	CH.Material = Enum.Material.Neon
	CH.Color = InputHandler.InputHandler.Colors["Check"]
	CH.Size = square.Size + Vector3.new(0, 0.2, 0)
	CH.Position = square.Position
	CH.Parent = workspace["EventIndicators"]
	TS:Create(CH, TweenInfo.new(0.1), { Transparency = 0.1 }):Play()
end

return InputHandler
