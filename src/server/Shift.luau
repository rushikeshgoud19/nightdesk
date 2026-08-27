--!strict
-- Runs a night. Sends guests to the desk one at a time, judges the player's
-- calls, and ends the shift when the queue is empty.
--
-- SERVER-AUTHORITATIVE, stated honestly:
--
-- The tell crosses the wire when the player's upgrades have earned it, because
-- the player has to perceive it to play. There is no way around that and any
-- comment claiming otherwise would be a lie you could disprove with a memory
-- scanner.
--
-- What never crosses: whether the guest is actually an anomaly, whether the
-- call was right, and what it pays. A tampered client can lie about its answer
-- and read the tell early; it cannot mint money, skip the fine, or write to the
-- profile.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Anomalies = require(Shared:WaitForChild("Anomalies"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Upgrades = require(Shared:WaitForChild("Upgrades"))

local State = require(script.Parent:WaitForChild("State"))

local guestArrived = Remotes.get("GuestArrived")
local judge = Remotes.get("Judge")
local shiftUpdate = Remotes.get("ShiftUpdate")
local shiftEnded = Remotes.get("ShiftEnded")

local rng = Random.new()

local GAP_AFTER_JUDGEMENT = 1.5

local Shift = {}

-- Set by init so Shift can reopen the shop without requiring Shop directly,
-- which would make the two modules mutually dependent.
local onShiftEnd: ((Player) -> ())? = nil

function Shift.setShiftEndHandler(fn: (Player) -> ())
	onShiftEnd = fn
end

local function sendNext(player: Player)
	local p = State.get(player)
	if not p then
		return
	end

	if p.guestsLeft <= 0 or p.sanity <= 0 then
		p.current = nil
		p.shiftActive = false
		p.guestsLeft = 0
		local survived = p.sanity > 0
		p.lastShiftSurvived = survived
		local bonus = 0

		if survived then
			if p.sanity > 50 then
				bonus = 50
				p.takings += bonus
			end
		else
			-- Forfeit this night's takings
			p.takings = p.shiftStartTakings
		end

		p.nightsWorked += 1
		shiftEnded:FireClient(player, {
			nightsWorked = p.nightsWorked,
			takings = p.takings,
			mistakes = p.mistakes,
			sanity = p.sanity,
			survived = survived,
			bonus = bonus,
		})
		if onShiftEnd then
			onShiftEnd(player)
		end
		return
	end

	p.guestsLeft -= 1

	local guest = Anomalies.roll(rng)
	p.current = guest

	-- The upgrades decide whether you get to see the tell at all. Without them
	-- most anomalies give you nothing and you are guessing -- which is the
	-- reason to buy anything.
	local stats = Upgrades.stats(p.owned)
	local visible = guest.anomaly ~= nil and rng:NextNumber() < stats.tellChance
	p.tellVisible = visible

	guestArrived:FireClient(player, {
		name = guest.name,
		reservation = guest.reservation,
		tell = if visible and guest.anomaly then guest.anomaly.tell else nil,
		guestsLeft = p.guestsLeft,
		sanity = p.sanity,
		takings = p.takings,
	})
end

local function resolve(player: Player, admitted: boolean)
	local p = State.get(player)
	if not p then
		return
	end

	local guest = p.current
	if not guest then
		-- Judge fired with no guest pending: lag, or a tampered client trying to
		-- farm payouts. Either way, no payout.
		return
	end
	p.current = nil

	local isAnomaly = guest.anomaly ~= nil
	local correct = (isAnomaly and not admitted) or (not isAnomaly and admitted)
	local stats = Upgrades.stats(p.owned)

	if correct then
		p.takings += stats.payout
	else
		-- Letting the wrong thing in is worse than being rude
		local penalty = if isAnomaly and admitted then 40 else 20
		p.sanity = math.max(0, p.sanity - penalty)
		p.mistakes += 1
	end

	shiftUpdate:FireClient(player, {
		correct = correct,
		wasAnomaly = isAnomaly,
		tell = if isAnomaly and guest.anomaly then guest.anomaly.tell else nil,
		takings = p.takings,
		mistakes = p.mistakes,
		sanity = p.sanity,
	})

	task.wait(GAP_AFTER_JUDGEMENT)
	sendNext(player)
end

function Shift.start(player: Player)
	local p = State.get(player)
	if not p then
		return
	end
	p.guestsLeft = Upgrades.stats(p.owned).guestsPerShift
	p.sanity = 100
	p.shiftStartTakings = p.takings
	p.shiftActive = true
	sendNext(player)
end

function Shift.bind()
	judge.OnServerEvent:Connect(function(player: Player, admitted: unknown)
		-- Never trust the shape of anything that crosses the wire.
		if typeof(admitted) ~= "boolean" then
			return
		end
		resolve(player, admitted)
	end)
end

return Shift
