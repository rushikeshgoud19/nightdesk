--!strict
-- Bootstrap. Wires the server modules, builds motel architecture, and manages session lifecycles.

local Players = game:GetService("Players")

local BuildLobby = require(script:WaitForChild("BuildLobby"))
local Shift = require(script:WaitForChild("Shift"))
local Shop = require(script:WaitForChild("Shop"))
local State = require(script:WaitForChild("State"))

-- Construct motel architecture, front desk, and props on server boot
BuildLobby()

Shift.bind()
Shop.bind()

Shift.setShiftEndHandler(function(player: Player)
	Shop.push(player)
end)

Players.PlayerAdded:Connect(function(player)
	State.load(player)
	player.CharacterAdded:Wait()
	task.wait(1)
	Shift.start(player)
end)

Players.PlayerRemoving:Connect(function(player)
	State.release(player)
	Shop.forget(player)
end)

print("[nightdesk] server initialized with master motel lobby")
