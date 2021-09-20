local Spot = {}
Spot.__index = Spot

function Spot.new(letter,number, piece, instance, board)
    local self = {}
    setmetatable(self,Spot)

    self.Letter = letter
	self.Number = number
	self.Board = board
    self.Piece = piece or nil
	self.Instance = instance or nil
		
    return self
end

function Spot:SetPiece(p)
	self.Piece = p or nil
end

function Spot:IsUnderAttack(team)
	return self.Board:IsSpotUnderAttack(team, self.Letter, self.Number)	
end

--function Spot:SetLetter(l)
--	self.Letter = l and l or self.Letter
--end

--function Spot:SetNumber(n)
--	self.Number = n and n or self.Number
--end

--function Spot:SetInstance(i)
--	self.Instance = i and i or self.Instance
--end

return Spot