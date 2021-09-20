local il = script.Parent.Frame1.ImageLabel

local pic, ready = game.Players:GetUserThumbnailAsync(game.Players.LocalPlayer.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size100x100)
il.Image = pic
il.Parent.TextLabel.Text = game.Players.LocalPlayer.Name