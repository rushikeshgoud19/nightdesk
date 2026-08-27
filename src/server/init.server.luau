--!strict
-- Night desk, server side.
--
-- SERVER-AUTHORITATIVE RULE, stated honestly:
--
-- The client IS sent the tell, because the player has to perceive it to play --
-- the empty mirror, the mismatched ID. There is no way around that, and any
-- claim that the client "doesn't know" would be a lie you could disprove with a
-- memory scanner. What the client is never sent is the VERDICT.
--
-- The server alone decides whether a tell counts as an anomaly, whether the
-- player's call was right, and what it pays. A tampered client can lie about
-- its answer and can read the tell early; it cannot mint money, cannot skip the
-- fine, and cannot write to the shift state. That is the boundary that actually
-- holds, so that is the one worth defending.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Anomalies = require(Shared:WaitForChild("Anomalies"))
local Remotes = require(Shared:WaitForChild("Remotes"))

type Guest = Anomalies.Guest

local guestArrived = Remotes.get("GuestArrived")
local judge = Remotes.get("Judge")
local shiftUpdate = Remotes.get("ShiftUpdate")

local rng = Random.new()

-- Per-player shift state. Lives on the server, dies with the player.
-- Week 4 of the plan replaces this with a DataStore-backed profile.
type Shift = {
	current: Guest?,
	takings: number,
	mistakes: number,
}

local shifts: { [Player]: Shift } = {}

local PAYOUT = 40
local FINE = 60

local function sendNextGuest(player: Player)
	local shift = shifts[player]
	if not shift then
		return
	end

	local guest = Anomalies.roll(rng)
	shift.current = guest

	-- The tell goes over the wire because the player must be able to see it.
	-- The verdict does not. See the note at the top of this file.
	guestArrived:FireClient(player, {
		name = guest.name,
		reservation = guest.reservation,
		tell = if guest.anomaly then guest.anomaly.tell else nil,
	})
end

local function resolve(player: Player, admitted: boolean)
	local shift = shifts[player]
	if not shift then
		return
	end

	local guest = shift.current
	if not guest then
		-- Client fired Judge with no guest pending. Either lag or a tampered
		-- client. Either way: ignore it, do not pay out.
		return
	end
	shift.current = nil

	local isAnomaly = guest.anomaly ~= nil
	-- Correct play: admit a real guest, refuse an anomaly.
	local correct = (isAnomaly and not admitted) or (not isAnomaly and admitted)

	if correct then
		shift.takings += PAYOUT
	else
		shift.takings = math.max(0, shift.takings - FINE)
		shift.mistakes += 1
	end

	shiftUpdate:FireClient(player, {
		correct = correct,
		wasAnomaly = isAnomaly,
		takings = shift.takings,
		mistakes = shift.mistakes,
	})

	task.wait(1.5)
	sendNextGuest(player)
end

judge.OnServerEvent:Connect(function(player: Player, admitted: unknown)
	-- Never trust the shape of anything that crosses the wire.
	if typeof(admitted) ~= "boolean" then
		return
	end
	resolve(player, admitted)
end)

Players.PlayerAdded:Connect(function(player)
	shifts[player] = { current = nil, takings = 0, mistakes = 0 }
	player.CharacterAdded:Wait()
	task.wait(1)
	sendNextGuest(player)
end)

Players.PlayerRemoving:Connect(function(player)
	shifts[player] = nil
end)

print("[nightdesk] server up")
