print("Hello")

local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local plr = Players.LocalPlayer
local team = plr.Team.Name

local Remotes = RS:WaitForChild("Remotes")
local PE = Remotes:WaitForChild("Promotion")

local pf = script.Parent
local buttons = {}
buttons.WhiteButtons = pf:WaitForChild("WhiteOptions").Buttons:GetChildren()
buttons.BlackButtons = pf:WaitForChild("BlackOptions").Buttons:GetChildren()


local function FirePE(PromotedPiece)
	PE:FireServer(PromotedPiece)
	pf.Visible = false
	pf[team.."Options"].Visible = false
	pf[team.."Options"]["3DRotation"].Disabled = true
end

local function ConnectButtons(buttons)
	for i,v in pairs(buttons) do
		v.MouseButton1Click:Connect(function()
			FirePE(v.Name)
		end)
	end
end

PE.OnClientEvent:Connect(function()
	print("Promotion")
	pf.Visible = true
	pf[team.."Options"].Visible = true
	pf[team.."Options"]["3DRotation"].Disabled = false
end)

ConnectButtons(buttons[team.."Buttons"])