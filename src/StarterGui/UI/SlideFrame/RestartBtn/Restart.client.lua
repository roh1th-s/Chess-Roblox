local RS = game:GetService("ReplicatedStorage")

local plr = game.Players.LocalPlayer
local cam = workspace.CurrentCamera

local GameEvent = RS:WaitForChild("GameEvent")

script.Parent.MouseButton1Click:Connect(function()
	for i,v in pairs(cam:GetChildren()) do
		v:Destroy()
	end
	plr.PlayerScripts:WaitForChild("ClickDetector").Selected.Value = false
	GameEvent:FireServer("Restart")
	wait(0.1)
end)