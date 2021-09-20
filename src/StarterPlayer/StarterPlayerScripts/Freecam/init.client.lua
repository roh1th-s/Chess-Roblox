local UGS = UserSettings():GetService("UserGameSettings")

local RunService = game:GetService("RunService")
local RepSt = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local camera = workspace.CurrentCamera
local plr = game.Players.LocalPlayer
local PlrGui = plr:WaitForChild("PlayerGui")
local TouchGui = PlrGui:FindFirstChild("TouchGui")

local PlrModInstance = plr.PlayerScripts:WaitForChild("PlayerModule")
local PlayerModule = require(PlrModInstance)
local ClChar = require(RepSt:WaitForChild("CharacterModule"))
local controls = PlayerModule:GetControls()

local ControlGUI = Instance.new("ScreenGui")
ControlGUI.Name = "ControlGUI"
ControlGUI.Parent = PlrGui

controls:Disable()

if TouchGui then
	TouchGui.Enabled = false
end

local TouchThumbstick = nil
if UserInputService.TouchEnabled then
	local TouchMovementMode = UGS.TouchMovementMode
	if TouchMovementMode == Enum.TouchMovementMode.Thumbstick then
		TouchThumbstick = require(script.TouchThumbstick).new()
	else
		TouchThumbstick = require(script.DynamicThumbstick).new()
	end
	TouchThumbstick:Enable(true,ControlGUI)
end

ClChar.MakeInvisible(plr.Character)

repeat 
camera.CameraType = Enum.CameraType.Scriptable
until camera.CameraType == Enum.CameraType.Scriptable

local x = 0
local y = 0
local angle = Instance.new("CFrameValue")
local position = plr.Character:WaitForChild("HumanoidRootPart").Position + Vector3.new(0,3,10)

local mc = workspace.Map["mc"].Position
local Mc = workspace.Map["Mc"].Position

local nVec = {
	[Enum.KeyCode.A] = Vector3.new(-1, 0, 0),
	[Enum.KeyCode.D] = Vector3.new(1, 0, 0),
	[Enum.KeyCode.S] = Vector3.new(0, 0, 1),
	[Enum.KeyCode.W] = Vector3.new(0, 0, -1),
	[Enum.KeyCode.Q] = Vector3.new(0, -1, 0),
	[Enum.KeyCode.E] = Vector3.new(0, 1, 0)
}

local Vec = {}

local speed = 1

local UISTable = {}

function UISTable.InputBegan(input)
	if nVec[input.KeyCode] then
		Vec[input.KeyCode] = nVec[input.KeyCode]
	elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
	end
end

function UISTable.InputChanged(input,processedByUI)
	if processedByUI then return end
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		x = (x - math.rad(input.Delta.X*0.8))%(2*math.pi)
		y = math.clamp(y - math.rad(input.Delta.Y * 0.9), math.rad(-90), math.rad(90))
		TweenService:Create(
			angle,
			TweenInfo.new(
				0.1,
				Enum.EasingStyle.Quad,
				Enum.EasingDirection.Out,
				0,
				false, 
				0
			),
			{Value = CFrame.Angles(0, x, 0) * CFrame.Angles(y, 0, 0)}
		):Play()
	elseif input.UserInputType == Enum.UserInputType.MouseWheel then
		position = position + angle.Value * Vector3.new(0, 0, 5*-input.Position.Z)
	end
end

function UISTable.InputEnded(input)
	if nVec[input.KeyCode] then
		Vec[input.KeyCode] = nil
	elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	elseif input.KeyCode == Enum.KeyCode.LeftShift then
		speed = 1.5
	end
end

for k, fn in pairs(UISTable) do
	UserInputService[k]:Connect(fn)
end

local function DefaultCam(dt)
	local move = Vector3.new()
	if TouchThumbstick then
		move = TouchThumbstick.moveVector or Vector3.new()
	end
	
	for _, v in pairs(Vec) do
		move = move + v
	end

	position = Vector3.new(
		math.clamp(position.X,mc.X,Mc.X),
		math.clamp(position.Y,mc.Y,Mc.Y),
		math.clamp(position.Z,mc.Z,Mc.Z)
	)
	camera.CFrame = angle.Value + position
	position = position + angle.Value * (move * dt * 50)
end

RunService:BindToRenderStep("DefaultCam", Enum.RenderPriority.Camera.Value, DefaultCam)

UGS:GetPropertyChangedSignal("TouchMovementMode"):Connect(function()
	local success, cs = pcall(function()
		return UGS.TouchMovementMode
	end)
	if success then
		local TouchGui = PlrGui:FindFirstChild("TouchGui")
		if TouchGui then
			TouchGui.Enabled = false
		end
		local CurrentSetting = cs 
		TouchThumbstick:Enable(false,nil,true) 
		if cs == Enum.TouchMovementMode.Thumbstick then
			TouchThumbstick = require(script["TouchThumbstick"]).new()
		else 
			TouchThumbstick = require(script["DynamicThumbstick"]).new()
		end
		TouchThumbstick:Enable(true,ControlGUI)
	end
end)