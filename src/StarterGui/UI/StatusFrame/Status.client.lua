local RS = game:GetService("ReplicatedStorage")

local GE = RS:WaitForChild("GameEvent")
local plr = game.Players.LocalPlayer

local StatusFrame = script.Parent
local SL = StatusFrame.StatusLabel

local turn 

local function Init()
	if plr.Team.Name == "White" then
		SL.Text = "Your turn"
		turn = true
	else
		SL.Text = "Opponents turn"
		turn = false
	end
end	

GE.OnClientEvent:Connect(function(Event)
	if Event == "Check" then
		SL.Text = "Check"
	elseif Event == "Checkmate" then
		SL.Text = "You lose!"
	elseif Event == "Win" then
		SL.Text = "You win!"
	elseif Event == "Stalemate" then
		SL.Text = "Draw"
	elseif Event == "Resign" then
		SL.Text = "You win!"
	elseif Event == "Restart" then
		Init()
	end
end)

workspace.WhoseTurn:GetPropertyChangedSignal("Value"):Connect(function()
	if not (SL.Text == "Draw" or SL.Text == "You win!" or SL.Text == "You lose!") then
		if workspace.WhoseTurn.Value == turn then
			SL.Text = "Your turn!"
		else
			SL.Text = "Opponents turn"
		end
	end
end)

Init()