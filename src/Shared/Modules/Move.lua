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

    self.GameEnded = false
    self.EndInfo = nil

    self.IsCheck = false
    self.CheckData = nil
    
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

function Move:SetCastling(isCastling, castlingMoves)
    self.IsCastling = isCastling
    self.CastlingMoves = castlingMoves

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

function Move:SetEnPassant(isEnPassant, otherPawnSpot)
    self.IsEnPassant = isEnPassant
    self.OtherPawnSpotPartial = {
        Letter = otherPawnSpot.Letter,
        Number = otherPawnSpot.Number
    }

    return self
end

function Move:SetPromotion(isPromotion, promotedPiece, newPieceInstance)
	self.IsPromotion = isPromotion	

	self.PromotedPiece = promotedPiece
    self.NewPieceInstance = newPieceInstance

    return self
end

function Move:CreateSendableObject()
    local sendableMove = {}

    --clone table
    --this is not being deep cloned.
    for key, value in pairs(self) do 
        sendableMove[key] = value 
    end

    sendableMove.MovedPiece = nil
    sendableMove.CapturedPiece = nil

    if sendableMove.IsCastling then
        sendableMove.CastlingMoves.InitRookSpot = nil
        sendableMove.CastlingMoves.RookTargetSpot = nil
    end
    
    return sendableMove
end

return Move
