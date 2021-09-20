local UIS = game:GetService("UserInputService");

local dragger = {};
dragger.__index = dragger;

function dragger.new(guiElement)
	local self = setmetatable({}, dragger);
	
	local isDragging = false;
	self.GuiElement = guiElement
	local lastMousePosition = Vector3.new();

	self.events = {
		guiElement.Parent.InputBegan:Connect(function(input)
			if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
				local delta = Vector2.new(input.Position.x,input.Position.y) - guiElement.AbsolutePosition
				self:onDrag(input,delta)
				isDragging = true;
			end
		end),
		
		guiElement.Parent.InputEnded:Connect(function(input)
			if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
				isDragging = false;
			end
		end),
		
		guiElement.Parent.InputChanged:Connect(function(input, process)
			if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				local delta = input.Position - lastMousePosition;
				lastMousePosition = input.Position;
				if (isDragging and not process) then
					self:onDrag(input, delta);
				end
			end
		end)
	}
	
	return self;
end

function dragger:onDrag(input, delta)
	--relace this with whatever you desire
	self.GuiElement.Position = self.GuiElement.Position + UDim2.new(0, delta.x, 0, delta.y);
end

function dragger:Destroy()
	for i = 1, #self.events do
		self.events[i]:Disconnect();
	end
	self.events = {};
end

return dragger;