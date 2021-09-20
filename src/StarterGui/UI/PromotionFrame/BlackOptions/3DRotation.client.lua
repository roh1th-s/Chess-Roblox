local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Viewports = script.Parent:FindFirstChild("Viewports"):GetChildren()
local Targets = {}

for i,v in pairs(Viewports) do
	local target = {v:FindFirstChildWhichIsA("MeshPart")}
	local camera = Instance.new("Camera",v)
	camera.FieldOfView = 60
	v.CurrentCamera = camera
	camera.CameraType = Enum.CameraType.Scriptable
	table.insert(target,camera)
	table.insert(Targets,target)
end

local rotationAngle = Instance.new("NumberValue")
local tweenComplete = false
 
local cameraOffset = Vector3.new(0, 0, 24)
local rotationTime = 10  
local rotationDegrees = 360
local rotationRepeatCount = -1  
local lookAtTarget = false  
 
local function updateCamera()
	for i,target in pairs(Targets) do
		target[2].Focus = target[1].CFrame
		local rotatedCFrame = CFrame.Angles(0, math.rad(rotationAngle.Value), 0)
		rotatedCFrame = CFrame.new(target[1].Position) * rotatedCFrame
		target[2].CFrame = rotatedCFrame:ToWorldSpace(CFrame.new(cameraOffset))
		if lookAtTarget == true then
			target[2].CFrame = CFrame.new(target[2].CFrame.Position, target[1].Position)
		end
	end
end
 
local tweenInfo = TweenInfo.new(rotationTime, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, rotationRepeatCount)
local tween = TweenService:Create(rotationAngle, tweenInfo, {Value=rotationDegrees})
tween.Completed:Connect(function()
	tweenComplete = true
end)
tween:Play()
 
RunService.RenderStepped:Connect(function()
	if tweenComplete == false then
		updateCamera()
	end
end)