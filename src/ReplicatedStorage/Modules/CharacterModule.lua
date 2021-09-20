local character = {}

function character.MakeInvisible(character)
	local function ScanParts(parent)
		for i,part in pairs(parent:GetChildren()) do
			if part:IsA("BasePart") or part:IsA("Decal") then
				part.Transparency = 1
			end
			if #part:GetChildren() ~= 0 then
				ScanParts(part)
			end
		end
	end
	ScanParts(character)
end

function character.MakeVisible(character)
	local function ScanParts(parent)
		for i,part in pairs(parent:GetChildren()) do
			if (part:IsA("BasePart") or part:IsA("Decal")) and part.Name ~= "HumanoidRootPart" then
				part.Transparency = 0
			end
			if #part:GetChildren() ~= 0 then
				ScanParts(part)
			end
		end
	end
	ScanParts(character)
end

return character