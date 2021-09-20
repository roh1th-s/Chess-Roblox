local Move = {}
Move.__index = Move

function Move.new(initPosLetter, initPosNum, targetPosLetter, targetPosNum , castlingMoves , isEnPassant)
	local self = setmetatable({}, Move)
	
	self.movedPiece = nil
	self.capturedPiece = nil
	
	self.initPosLetter = initPosLetter
	self.initPosNum = initPosNum
	self.targetPosLetter = targetPosLetter
	self.targetPosNum = targetPosNum
	self.castlingMoves = castlingMoves 
	self.isEnPassant = isEnPassant
	
	return self
end

function Move:setInitPos(initPosLetter, initPosNum)
	self.initPosLetter = initPosLetter
	self.initPosNum = initPosNum
	
	return self
end

function Move:setTargetPos(targetPosLetter, targetPosNum)
	self.targetPosLetter = targetPosLetter
	self.targetPosNum = targetPosNum

	return self
end

function Move:setCastlingMoves(castlingMoves)
	self.castlingMoves = castlingMoves

	return self
end

function Move:setMovedPiece(movedPiece)
	self.movedPiece = movedPiece

	return self
end

function Move:setCapturedPiece(capturedPiece)
	self.capturedPiece = capturedPiece

	return self
end

function Move:setEnPassant(isEnPassant)
	self.isEnPassant = isEnPassant

	return self
end

function Move:CreateSendableObject()
	local sendableMove = {}
	
	for key, value in pairs(self) do
		sendableMove[key] = value
	end
	
	sendableMove.movedPiece = nil
	sendableMove.capturedPiece = nil

	return sendableMove
end

return Move