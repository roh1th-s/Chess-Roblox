local Players = game:GetService("Players")
local RS = game:GetService("RunService")
local TS = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")

local plr = Players.LocalPlayer
local cam = workspace.CurrentCamera

local sin = math.sin
local cos = math.cos
local rad = math.rad

local board = workspace:WaitForChild("Board")
local centerCFrame, size = board:GetBoundingBox()
centerCFrame = CFrame.new(centerCFrame.Position)

repeat wait()
	cam.CameraType = Enum.CameraType.Scriptable
until cam.CameraType == Enum.CameraType.Scriptable

local RADIUS = Instance.new("NumberValue")
RADIUS.Value = 100

local ANGLE_AROUND_CENTER = 45
local VERTICAL_ANGLE = 90

local UNIT_ZOOM = 16
local SENSITIVITY_X = 0.5
local SENSITIVITY_Y = 0.8

local currentZoomTween = nil

--local function GetDirectionFromAngles(angleX, angleY)
--	local x = cos(rad(angleX)) + sin(rad(angleY))
--	local y = sin(rad(angleX))
--	local z = sin(rad(angleY))
--	print(x,y,z)
--	return Vector3.new(x, y, z).Unit
--end

local function AngleClamp(angle)
	if angle > 360 then
		return angle - 360
	elseif angle < -360 then
		return angle + 360
	else
		return angle
	end	
end

local function UpdateCamera()
	local camCFrame = centerCFrame * CFrame.Angles(0, rad(ANGLE_AROUND_CENTER), 0) * CFrame.Angles(-rad(VERTICAL_ANGLE),0, 0)
	camCFrame = camCFrame * CFrame.new(0,0,RADIUS.Value)

	cam.CFrame = camCFrame
end

local function InputBegan(input, gameProcessedEvent)
	if gameProcessedEvent then return end

	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		UIS.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
	end
end

local function InputChanged(input, gameProcessedEvent)
	if gameProcessedEvent then return end

	if input.UserInputType == Enum.UserInputType.MouseWheel then

		local direction = -input.Position.Z
		local newValue =  math.clamp(RADIUS.Value + (direction * UNIT_ZOOM) , 10 , 200)


		currentZoomTween = TS:Create(RADIUS, TweenInfo.new(0.13), {Value = newValue})
		currentZoomTween:Play()

		currentZoomTween.Completed:Connect(function()
			currentZoomTween:Destroy()
			currentZoomTween = nil
		end)


	elseif input.UserInputType == Enum.UserInputType.MouseMovement then

		if UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
			local delta = input.Delta
			local deltaX = delta.X
			local deltaY = delta.Y

			ANGLE_AROUND_CENTER = AngleClamp(ANGLE_AROUND_CENTER + -deltaX * SENSITIVITY_X)

			VERTICAL_ANGLE = math.clamp(VERTICAL_ANGLE + deltaY * SENSITIVITY_Y , 5, 90)
		end

	end
end

local function InputEnded(input, gameProcessedEvent)
	if gameProcessedEvent then return end

	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		UIS.MouseBehavior = Enum.MouseBehavior.Default
	end
end

UIS.InputBegan:Connect(InputBegan)
UIS.InputChanged:Connect(InputChanged)
UIS.InputEnded:Connect(InputEnded)

RS.RenderStepped:Connect(UpdateCamera)