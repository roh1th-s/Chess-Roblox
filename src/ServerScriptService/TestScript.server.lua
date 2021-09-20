for _ , spot in pairs(workspace.Board:GetChildren()) do
	if spot.Color ~= Color3.new(1,1,1) then
		spot.Color = Color3.fromRGB(99, 75, 40)
	end
end