--!strict
-- Client bootstrap. Builds the two screens and routes remotes to them.
-- Owns no game state.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))

local DeskUI = require(script:WaitForChild("DeskUI"))
local ShopUI = require(script:WaitForChild("ShopUI"))

local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "NightDesk"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

DeskUI.build(gui)
ShopUI.build(gui)

Remotes.get("GuestArrived").OnClientEvent:Connect(DeskUI.onGuest)
Remotes.get("ShiftUpdate").OnClientEvent:Connect(DeskUI.onResult)
Remotes.get("ShiftEnded").OnClientEvent:Connect(DeskUI.onShiftEnded)
Remotes.get("ShopState").OnClientEvent:Connect(ShopUI.render)

print("[nightdesk] client up")
