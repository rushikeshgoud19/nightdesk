--!strict
-- Bootstrap. Wires the server modules together and owns nothing itself.
--
-- Flow: a player joins, works a night, the shop opens on the takings they just
-- earned, they buy something, they start the next night. The first night runs
-- before the shop ever opens, because a shop with an empty wallet teaches
-- nothing.

local Players = game:GetService("Players")

local Shift = require(script:WaitForChild("Shift"))
local Shop = require(script:WaitForChild("Shop"))
local State = require(script:WaitForChild("State"))

Shift.bind()
Shop.bind()

-- Shift does not require Shop -- that would make the two mutually dependent.
-- It calls back through here instead.
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
	-- Once ProfileStore lands in week 4, the save goes here and in BindToClose --
	-- PlayerRemoving alone does not fire reliably on server shutdown.
	State.release(player)
	Shop.forget(player)
end)

print("[nightdesk] server up")
