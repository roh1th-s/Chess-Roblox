--services
local RS = game:GetService("ReplicatedStorage")
local TS = game:GetService("TweenService")
local SSS = game:GetService("ServerScriptService")
local UIS = game:GetService("UserInputService")

--events
local RequestMove = RS:WaitForChild("RequestMove")
local FindMoves = RS:WaitForChild("FindMoves")
local GameEvent = RS:WaitForChild("GameEvent")

local plr = game.Players.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local mouse = plr:GetMouse() 
local camera = workspace.CurrentCamera

local WhoseTurn = workspace:WaitForChild("WhoseTurn")

--[[local selection = Instance.new("Part")
selection.Name = "Selection"
selection.Material = Enum.Material.Neon
selection.Transparency = 1
selection.Anchored = true
selection.CanCollide = false]]--

local selection = RS:WaitForChild("Highlight"):Clone()
selection.Name = "Selection"
selection.Material = Enum.Material.Plastic
selection.Transparency = 1
selection.Anchored = true
selection.CanCollide = false

local Colors = {
	["Indicator1"] = Color3.fromRGB(173, 120, 27),
	["Normal"] = Color3.fromRGB(86,86,86),
	["Attack"] = Color3.fromRGB(165,0,30),
	["Check"] = Color3.fromRGB(255,0,0)	
}

--functions
local function ClearHighlights()
	for i,v in pairs(camera:GetChildren()) do
		v:Destroy()
	end
end

local function CreateHighlight(Coordinate,color)
	local highlight = selection:Clone()
	if Coordinate.Occupant.Value and Coordinate.Occupant.Value.Parent.Name ~= plr.Team.Name then
		highlight.Color = color or Colors.Attack
	else
		highlight.Color = color or Colors.Normal
	end
	highlight.Size = Coordinate.Size + Vector3.new(0,0.2,0)
	highlight.Position = Coordinate.Position --+ Vector3.new(0,Coordinate.Size.Y/2,0)
	highlight.Parent = camera
	TS:Create(highlight,TweenInfo.new(0.1),{Transparency = 0.1}):Play()
end

local function HighlightMoves(moves)
	for i,v in pairs(moves) do
		CreateHighlight(v)
	end
end

local function IsMoveValid(move,movesTable)
	for i,v in pairs(movesTable) do
		if move == v then
			return true
		end
	end
	return false
end

local function ClearEventIndicators()  --like check
	for i,indicator in pairs(workspace["EventIndicators"]:GetChildren()) do
		indicator:Destroy()
	end
end

local selected = script.Selected
local piece = nil
local moves = {}
local turn

if plr.Team.Name == "White" then
	turn = true
else
	turn = false
end

local function HandleInput(target)
	if target and (target.Parent.Name == "Board" or target.Parent.Name == "White" or target.Parent.Name == "Black") then
			if target.Parent.Name == "Board" then
				if target.Occupant.Value then
					if selected.Value == true then
						if IsMoveValid(target,moves) == true then
							ClearEventIndicators()
							RequestMove:FireServer(piece,target)
						end
						ClearHighlights()
						selected.Value = false
						moves = {}
						piece = false
					else
						if target.Occupant.Value.Parent.Name == plr.Team.Name then
							CreateHighlight(target,Colors["Indicator1"])
							piece = target.Occupant.Value
							selected.Value = true
							moves = FindMoves:InvokeServer(piece)
							HighlightMoves(moves)
						end
					end
				else
					if selected.Value == true then
						if IsMoveValid(target,moves) == true then
							ClearEventIndicators()
							RequestMove:FireServer(piece,target)
						end
						ClearHighlights()
						selected.Value = false
						moves = {}
						piece = nil
					else
						ClearHighlights()
					end
				end
		
			elseif target.Parent.Name == "White" or target.Parent.Name == "Black" then
				if selected.Value == true then
					if IsMoveValid(target.Coordinates.Value,moves) == true then
						ClearEventIndicators()
						RequestMove:FireServer(piece,target.Coordinates.Value)
					end
					ClearHighlights()
					selected.Value = false
					moves = {}
					piece = nil
				else
					if target.Parent.Name == plr.Team.Name then
						CreateHighlight(target.Coordinates.Value,Colors["Indicator1"])
						piece = target
						selected.Value = true
						moves = FindMoves:InvokeServer(piece)
						HighlightMoves(moves)
					end
				end
			end
		else
			ClearHighlights()
		end
end

mouse.Button1Down:Connect(function()
	if UIS:GetLastInputType() == Enum.UserInputType.Touch then return end
	if WhoseTurn.Value == turn then
		local target = mouse.Target
		mouse.TargetFilter = camera -- Blacklists the highlights as selectable objects
		HandleInput(target)
	end
end)

UIS.TouchTapInWorld:Connect(function(vec2Pos,processedByUi)
	if processedByUi then return end
	if WhoseTurn.Value == turn then
		local unitRay = camera:ViewportPointToRay(vec2Pos.X,vec2Pos.Y,0)
		local ray = Ray.new(unitRay.Origin , unitRay.Direction * 500)
		local target,pos = workspace:FindPartOnRayWithIgnoreList(ray,camera:GetChildren())
		HandleInput(target)
	end
end)

GameEvent.OnClientEvent:Connect(function(event)
	if event == "Check" then
		local king = workspace[plr.Team.Name]:FindFirstChild("King")
		local square = king.Coordinates.Value
		local CH = selection:Clone()
		CH.Material = Enum.Material.Neon
		CH.Color = Colors["Check"]
		CH.Size = square.Size + Vector3.new(0,0.2,0)
		CH.Position = square.Position
		CH.Parent = workspace["EventIndicators"]
		TS:Create(CH,TweenInfo.new(0.1),{Transparency = 0.1}):Play()
	end
end)