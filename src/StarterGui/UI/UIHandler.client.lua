local Players = game:GetService("Players")
local SGui = game:GetService("StarterGui")
local TS = game:GetService("TweenService")
local RunService = game:GetService('RunService')
local TelS = game:GetService("TeleportService")

local plr = Players.LocalPlayer

local SGUI = script.Parent
local SlFrm = SGUI:WaitForChild("SlideFrame")
local MenuBtn = SGUI:WaitForChild("Menu:")

SlFrm["Name:"].Text = plr.Name

local TInfo = TweenInfo.new(0.2,Enum.EasingStyle.Quint)
local SlFrmOpen = false
MenuBtn.MouseButton1Click:Connect(function()
	if not SlFrmOpen then
		MenuBtn.Text = "Close"
		local Open = TS:Create(SlFrm,TInfo,{Position = UDim2.new(0,0,0,0)}):Play()
		SlFrmOpen = true
	else
		MenuBtn.Text = "Menu"
		local Open = TS:Create(SlFrm,TInfo,{Position = UDim2.new(-0.3,0,0,0)}):Play()
		SlFrmOpen = false
	end
end)

SlFrm.ResignBtn.MouseButton1Click:Connect(function()
	TelS:Teleport(4978233703)
end)

local coreCall do
	local MAX_RETRIES = 8
	function coreCall(method, ...)
		local result = {}
		for retries = 1, MAX_RETRIES do
			result = {pcall(SGui[method], SGui, ...)}
			if result[1] then
				break
			end
			RunService.Stepped:Wait()
		end
		return unpack(result)
	end
end

coreCall('SetCore', 'ResetButtonCallback', false)
SGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList,false)