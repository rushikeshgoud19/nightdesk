--!strict
-- The upgrade catalogue. This is the retention spine: the reason to come back on
-- day 8 rather than day 1, and the thing the whole game design rests on.
--
-- Upgrades buy INFORMATION, not raw power. Without them most anomalies give you
-- nothing to go on and you are guessing. With them you can actually see what is
-- wrong. That makes every purchase feel like the fog lifting slightly, which is
-- a better hook than a bigger number.
--
-- Balance intent: the first upgrade should land in the second or third shift.
-- The last should be out of reach for a couple of weeks. Nobody finishes this
-- tree in a weekend.

export type Upgrade = {
	id: string,
	name: string,
	blurb: string,
	cost: number,
	requires: string?, -- id of an upgrade that must be owned first
}

local Upgrades = {}

Upgrades.list = {
	{
		id = "room_2",
		name = "Open the second room",
		blurb = "One more guest each night. More money, more chances to be wrong.",
		cost = 200,
	},
	{
		id = "lights",
		name = "Fix the corridor lights",
		blurb = "You can finally see faces properly. Tells show far more often.",
		cost = 350,
	},
	{
		id = "room_3",
		name = "Open the third room",
		blurb = "Another guest, another judgement call.",
		cost = 600,
		requires = "room_2",
	},
	{
		id = "camera",
		name = "Install the lobby camera",
		blurb = "The monitor catches what you miss at the desk.",
		cost = 900,
		requires = "lights",
	},
	{
		id = "floor_2",
		name = "Reopen the second floor",
		blurb = "Twice the motel. Twice the night.",
		cost = 2000,
		requires = "room_3",
	},
} :: { Upgrade }

function Upgrades.byId(id: string): Upgrade?
	for _, u in Upgrades.list do
		if u.id == id then
			return u
		end
	end
	return nil
end

-- Derived stats for a given set of owned upgrades. The server is the only caller
-- that matters; the client may compute the same values for display, but nothing
-- the client computes is ever trusted.
export type Stats = {
	guestsPerShift: number,
	tellChance: number,
	payout: number,
}

local BASE_GUESTS = 4
local BASE_TELL_CHANCE = 0.4
local BASE_PAYOUT = 40
local MAX_TELL_CHANCE = 0.95

function Upgrades.stats(owned: { [string]: boolean }): Stats
	local rooms = 0
	if owned.room_2 then
		rooms += 1
	end
	if owned.room_3 then
		rooms += 1
	end
	if owned.floor_2 then
		rooms += 2
	end

	local tell = BASE_TELL_CHANCE
	if owned.lights then
		tell += 0.2
	end
	if owned.camera then
		tell += 0.25
	end

	return {
		guestsPerShift = BASE_GUESTS + rooms,
		tellChance = math.min(tell, MAX_TELL_CHANCE),
		payout = BASE_PAYOUT + rooms * 10,
	}
end

-- Whether an upgrade can be bought right now. Returns false plus a reason the UI
-- can show, so the client never has to guess why a button is dead.
function Upgrades.canBuy(
	u: Upgrade,
	owned: { [string]: boolean },
	takings: number
): (boolean, string?)
	if owned[u.id] then
		return false, "Already owned"
	end
	if u.requires and not owned[u.requires] then
		local prereq = Upgrades.byId(u.requires)
		return false, `Needs: {prereq and prereq.name or u.requires}`
	end
	if takings < u.cost then
		return false, `Costs {u.cost}`
	end
	return true, nil
end

return Upgrades
