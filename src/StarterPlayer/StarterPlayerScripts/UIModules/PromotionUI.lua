local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local PromotionUI = {}

function PromotionUI:Init(handler)
	self.Handler = handler
	self.Player = handler.plr
	self.Initialized = false

	local plrGui = self.Player:WaitForChild("PlayerGui")
	local promotionUI = plrGui.UI.PromotionUI

	self.PromotionFrame = promotionUI.PromotionFrame
	self.Viewports = self.PromotionFrame.Viewports:GetChildren()
	self.Targets = {}

	self.RotationAngle = Instance.new("NumberValue")
	self.TweenComplete = false

	self.CAMERA_OFFSET = Vector3.new(0, 0, 24)
	self.ROTATION_TIME = 10
	self.ROTATION_TWEEN_INFO = TweenInfo.new(
		self.ROTATION_TIME,
		Enum.EasingStyle.Linear,
		Enum.EasingDirection.InOut,
		-1
	)

	self.LookAtTarget = false

	self:SetupViewports()

	self.Initialized = true
end

function PromotionUI:Enable()
	self:SetupViewports()

	if not self.RotationTween then
		self.RotationTween = TweenService:Create(self.RotationAngle, self.ROTATION_TWEEN_INFO, { Value = 360 })

		self.RotationTween.Completed:Connect(function()
			self.TweenComplete = true
			self.RotationTween = nil
		end)
	end

	self.RotationTween:Play()

	if self.RenderSteppedConnection then
		self.RenderSteppedConnection:Disconnect()
	end

	self.RenderSteppedConnection = RunService.RenderStepped:Connect(function()
		if not self.TweenComplete then
			self:UpdateCameras()
		end
	end)

	self.PromotionFrame.Visible = true
end

function PromotionUI:Disable()
	self.PromotionFrame.Visible = false

	if self.RotationTween then
		self.RotationTween:Pause()
	end

	if self.RenderSteppedConnection then
		self.RenderSteppedConnection:Disconnect()
	end
end

function PromotionUI:SetupViewports()
	local teamName = self.Player.Team.Name

	for _, viewport in pairs(self.Viewports) do
		if not viewport:IsA("ViewportFrame") then
			continue
		end
		
		local pieceModel = viewport:FindFirstChildWhichIsA("MeshPart")
		local button = viewport:FindFirstChildWhichIsA("GuiButton")

		if teamName == "White" then
			pieceModel.Color = Color3.new(1, 1, 1)
		else
			pieceModel.Color = Color3.new(0, 0, 0)
		end

		if not self.Initialized then
			local camera = Instance.new("Camera")
			camera.CameraType = Enum.CameraType.Scriptable
			camera.FieldOfView = 60
			camera.Parent = viewport
			viewport.CurrentCamera = camera

			table.insert(self.Targets, {
				Camera = camera,
				Model = pieceModel,
			})

			button.MouseButton1Click:Connect(function()
				self.Handler:HandlePromotionChoice(viewport.Name)
			end)
		end
	end
end

function PromotionUI:UpdateCameras()
	for _, target in ipairs(self.Targets) do
		local cam = target.Camera
		local model = target.Model

		cam.Focus = model.CFrame
		local rotatedCFrame = CFrame.Angles(0, math.rad(self.RotationAngle.Value), 0)
		rotatedCFrame = CFrame.new(model.Position) * rotatedCFrame
		cam.CFrame = rotatedCFrame:ToWorldSpace(CFrame.new(self.CAMERA_OFFSET))

		if self.LookAtTarget == true then
			cam.CFrame = CFrame.new(cam.CFrame.Position, target[1].Position)
		end
	end
end

return PromotionUI
