local Move = {}
Move.__index = Move

function Move.new(initPosLetter, initPosNum, targetPosLetter, targetPosNum,
                  castlingMoves, isEnPassant, isPromotion, promotedPiece)

    local self = setmetatable({}, Move)

    self.MovedPiece = nil
    self.CapturedPiece = nil

    self.InitPosLetter = initPosLetter
    self.InitPosNumber = initPosNum
    self.TargetPosLetter = targetPosLetter
    self.TargetPosNumber = targetPosNum
    self.CastlingMoves = castlingMoves
    self.IsCastling = castlingMoves ~= nil
    self.IsEnPassant = isEnPassant
    self.IsPromotion = isPromotion
    self.PromotedPiece = promotedPiece

    return self
end

function Move:SetInitSpot(spot)
    self.InitPosLetter = spot.Letter
    self.InitPosNumber = spot.Number

    return self
end

function Move:SetInitPos(initPosLetter, initPosNum)
    self.InitPosLetter = initPosLetter
    self.InitPosNumber = initPosNum

    return self
end

function Move:SetTargetSpot(spot)
    self.TargetPosLetter = spot.Letter
    self.TargetPosNumber = spot.Number

    return self
end

function Move:SetTargetPos(targetPosLetter, targetPosNum)
    self.TargetPosLetter = targetPosLetter
    self.TargetPosNumber = targetPosNum

    return self
end

function Move:SetCastlingMoves(castlingMoves)
    self.CastlingMoves = castlingMoves
    self.IsCastling = true

    return self
end

function Move:SetMovedPiece(movedPiece)
    self.MovedPiece = movedPiece

    return self
end

function Move:SetCapturedPiece(capturedPiece)
    self.CapturedPiece = capturedPiece

    return self
end

function Move:SetIsCastling(isCastling)
    self.IsCastling = isCastling

    return self
end

function Move:SetIsEnPassant(isEnPassant)
    self.IsEnPassant = isEnPassant

    return self
end

function Move:SetIsPromotion(isPromotion, promotedPiece, newPieceInstance)
	self.IsPromotion = isPromotion	

	self.PromotedPiece = promotedPiece
    self.NewPieceInstance = newPieceInstance

    return self
end

function Move:CreateSendableObject()
    local sendableMove = {}

    --clone table
    for key, value in pairs(self) do 
        sendableMove[key] = value 
    end

    sendableMove.MovedPiece = nil
    sendableMove.CapturedPiece = nil

    return sendableMove
end

return Move
