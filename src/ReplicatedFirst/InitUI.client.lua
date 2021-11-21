if not (game:IsLoaded()) then
    game.Loaded:Wait()
end

print("Done loading game!")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local PlayerGUI = Players.LocalPlayer:WaitForChild("PlayerGui")

ReplicatedStorage.UI:Clone().Parent = PlayerGUI

print("Loaded UI")