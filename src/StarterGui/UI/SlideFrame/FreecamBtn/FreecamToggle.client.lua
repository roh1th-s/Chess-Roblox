local RepSt = game:GetService("ReplicatedStorage")

local plr = game.Players.LocalPlayer
local plrGui = plr:WaitForChild("PlayerGui")
local cam = workspace.CurrentCamera

local ControlModule = require(plr.PlayerScripts:WaitForChild("PlayerModule"))
local ClChar = require(RepSt:WaitForChild("CharacterModule"))
local controls = ControlModule:GetControls()
local FreecamScript = plr:WaitForChild("PlayerScripts"):WaitForChild("Freecam")

local button = script.Parent
local freecam = false

button.MouseButton1Click:Connect(function()
	local CtrlUI = plrGui:FindFirstChild("ControlGUI")
	local TouchGui = plrGui:FindFirstChild("TouchGui")

	if freecam == false then
		FreecamScript.Disabled = false
		freecam = true
	else
		FreecamScript.Disabled = true
		if CtrlUI then
			CtrlUI:Destroy()
		end
		if TouchGui then
			TouchGui.Enabled = true
		end
		freecam = false
		cam.CameraType = Enum.CameraType.Custom
		controls:Enable()
		ClChar.MakeVisible(plr.Character)
	end
end)