local CB = workspace.CapturedBlack
local CW = workspace.CapturedWhite

local BOrigin = workspace.BlackOrigin
local WOrigin = workspace.WhiteOrigin

local BSize = BOrigin.Size
local WSize = WOrigin.Size

CB.ChildAdded:Connect(function(child)
	local PieceSize = child.Size
	local RowTwo,Offset = false,Vector3.new(0,0.05 + PieceSize.Y/2,0)
	local n = #(CB:GetChildren()) - 1
	if n >= 8 then
		n = n - 8
		RowTwo = true
		Offset = Offset + Vector3.new(0,0,BSize.Z)
	end
	child.Position = (BOrigin.Position + Offset) + (Vector3.new(BSize.X,0,0) * n)
	child.CFrame = child.CFrame * CFrame.Angles(0,math.rad(180),0)
end)

CW.ChildAdded:Connect(function(child)
	local PieceSize = child.Size
	local RowTwo,Offset = false,Vector3.new(0,0.05 + PieceSize.Y/2,0)
	local n = #(CW:GetChildren()) - 1
	if n >= 8 then
		n = n - 8
		RowTwo = true
		Offset = Offset + Vector3.new(0,0,-WSize.Z)
	end
	child.Position = (WOrigin.Position + Offset) + (Vector3.new(-WSize.X,0,0) * n)
	child.CFrame = child.CFrame * CFrame.Angles(0,math.rad(180),0)
end)