if not (game:IsLoaded()) then
	game.Loaded:Wait()
end
print("[Initalizer] Game loaded.")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local PlayerGUI = LocalPlayer:WaitForChild("PlayerGui")

--Game UI
local GameUI = ReplicatedStorage.UI:Clone()
GameUI.MainUI.Enabled = false
GameUI.Parent = PlayerGUI

--Loading screen
local LoadingScreen = script.Parent.LoadingScreen
LoadingScreen.Parent = PlayerGUI

print("[Initalizer] Loaded UI")

local LoadingContainer = LoadingScreen:WaitForChild("Container")
local LoadingMessage = LoadingContainer:WaitForChild("LoadingMessage")
local PlayBtnFrame = LoadingContainer:WaitForChild("PlayBtnFrame")

local Spinner = LoadingMessage:WaitForChild("Spinner")
local PlayBtn = PlayBtnFrame:WaitForChild("PlayBtn")

local isLoading = true

function loadingSpinner()
	local speed = 180
	local theta = 0

	while theta <= 360 do
		if not isLoading then
			break
		end
		if theta >= 360 then
			theta -= 360
		end
		Spinner.Rotation = theta
		task.wait(1 / speed)
		theta += 1
	end
end

function stopLoader()
	isLoading = false
	TweenService:Create(LoadingMessage, TweenInfo.new(0.3, Enum.EasingStyle.Quint), { Transparency = 1 }):Play()
	LoadingMessage.Visible = false
end

function showPlayBtn()
	PlayBtnFrame.Visible = true
	TweenService:Create(PlayBtnFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint), { Transparency = 0 }):Play()
end

task.spawn(loadingSpinner)

local playerScripts = LocalPlayer:WaitForChild("PlayerScripts")
local clientModule = playerScripts:WaitForChild("Client")
local client = require(clientModule)

if client then
	stopLoader()
	showPlayBtn()
end

PlayBtn.MouseButton1Down:Connect(function()
    TweenService:Create(LoadingContainer, TweenInfo.new(0.3, Enum.EasingStyle.Quint), { Size = UDim2.new(0, 0, 0, 0) }):Play()
    client:Init()
    task.wait(0.3)
    LoadingScreen:Destroy()
    GameUI.MainUI.Enabled = true
end)

local yOffset = -5
local initPos = PlayBtnFrame.Position

PlayBtn.MouseEnter:Connect(function()
	TweenService
		:Create(
			PlayBtnFrame,
			TweenInfo.new(0.3, Enum.EasingStyle.Quint),
			{ Position = UDim2.new(initPos.X.Scale, initPos.X.Offset, initPos.Y.Scale, initPos.Y.Offset + yOffset) }
		)
		:Play()
end)

PlayBtn.MouseLeave:Connect(function()
	TweenService:Create(PlayBtnFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint), { Position = initPos }):Play()
end)
