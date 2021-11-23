local RS = game:GetService("RunService")
local TS = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")

local sin = math.sin
local cos = math.cos
local rad = math.rad

local ChessCam = {}
ChessCam.__index = ChessCam

function ChessCam.new(client)
	local self = setmetatable({}, ChessCam)

	self.client = client
	self.plr = client.Player
	self.cam = workspace.CurrentCamera
	self.board = workspace:WaitForChild("Board")

	self.ANGLE_AROUND_CENTER = 45
	self.VERTICAL_ANGLE = 90

	self.UNIT_ZOOM = 16
	self.SENSITIVITY_X = 0.5
	self.SENSITIVITY_Y = 0.8

	self.RADIUS = Instance.new("NumberValue")
	self.RADIUS.Value = 100

	self.currentZoomTween = nil

	return self
end

--static methods
function ChessCam.AngleClamp(angle)
	if angle > 360 then
		return angle - 360
	elseif angle < -360 then
		return angle + 360
	else
		return angle
	end
end

--function ChessCam.GetDirectionFromAngles(angleX, angleY)
--	local x = cos(rad(angleX)) + sin(rad(angleY))
--	local y = sin(rad(angleX))
--	local z = sin(rad(angleY))
--	print(x,y,z)
--	return Vector3.new(x, y, z).Unit
--end

--instance methods
function ChessCam:Init()
	self.centerCFrame, self.size = self.board:GetBoundingBox()
	self.centerCFrame = CFrame.new(self.centerCFrame.Position)

	repeat
		task.wait()
		self.cam.CameraType = Enum.CameraType.Scriptable
	until self.cam.CameraType == Enum.CameraType.Scriptable

	self.inputBeganConnection = UIS.InputBegan:Connect(function(input, gpe)
		self:HandleInputBegin(input, gpe)
	end)
	self.inputChangeConnection = UIS.InputChanged:Connect(function(input, gpe)
		self:HandleInputChange(input, gpe)
	end)
	self.inputEndedConnection = UIS.InputEnded:Connect(function(input, gpe)
		self:HandleInputEnd(input, gpe)
	end)

	self.renderSteppedConnection = RS.RenderStepped:Connect(function(dt)
		self:Update(dt)
	end)
end

function ChessCam:Update(dt)
	local camCFrame = self.centerCFrame
		* CFrame.Angles(0, rad(self.ANGLE_AROUND_CENTER), 0)
		* CFrame.Angles(-rad(self.VERTICAL_ANGLE), 0, 0)
	camCFrame = camCFrame * CFrame.new(0, 0, self.RADIUS.Value)

	self.cam.CFrame = camCFrame
end

function ChessCam:HandleInputBegin(input, gameProcessedEvent)
	if gameProcessedEvent then
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		UIS.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
	end
end

function ChessCam:HandleInputChange(input, gameProcessedEvent)
	if gameProcessedEvent then
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseWheel then
		local direction = -input.Position.Z
		local newValue = math.clamp(self.RADIUS.Value + (direction * self.UNIT_ZOOM), 10, 200)

		self.currentZoomTween = TS:Create(self.RADIUS, TweenInfo.new(0.13), { Value = newValue })
		self.currentZoomTween:Play()

		self.currentZoomTween.Completed:Connect(function()
			self.currentZoomTween:Destroy()
			self.currentZoomTween = nil
		end)
	elseif input.UserInputType == Enum.UserInputType.MouseMovement then
		if UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
			local delta = input.Delta
			local deltaX = delta.X
			local deltaY = delta.Y

			self.ANGLE_AROUND_CENTER = ChessCam.AngleClamp(self.ANGLE_AROUND_CENTER + -deltaX * self.SENSITIVITY_X)

			self.VERTICAL_ANGLE = math.clamp(self.VERTICAL_ANGLE + deltaY * self.SENSITIVITY_Y, 5, 90)
		end
	end
end

function ChessCam:HandleInputEnd(input, gameProcessedEvent)
	if gameProcessedEvent then
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		UIS.MouseBehavior = Enum.MouseBehavior.Default
	end
end

return ChessCam
