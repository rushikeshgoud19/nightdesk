--!strict
-- The anomaly table. One entry = one thing that can be wrong about a guest.
--
-- This is the content spine of the game. The plan calls for 40+ entries before
-- launch so a shift cannot be memorised in three nights. Four is enough to prove
-- the loop works.
--
-- `tell` is what the player can actually observe at the desk. If a player cannot
-- see it, it is not an anomaly, it is a bug.

export type Anomaly = {
	id: string,
	tell: string,
}

export type Guest = {
	name: string,
	reservation: string,
	anomaly: Anomaly?, -- nil means this guest is genuinely fine
}

local Anomalies = {}

Anomalies.list = {
	{ id = "name_mismatch", tell = "The name on the ID does not match the reservation." },
	{ id = "no_reflection", tell = "The lobby mirror behind them is empty." },
	{ id = "wrong_checkout", tell = "Their checkout date is before their check-in date." },
	{ id = "too_still", tell = "They have not blinked once since walking in." },
} :: { Anomaly }

local FIRST = { "Halden", "Moss", "Vero", "Quinn", "Adler", "Pike", "Renn", "Cobb" }
local LAST = { "Vance", "Ruell", "Marsh", "Okonkwo", "Sabet", "Delacroix", "Hoyt" }

-- Chance that any given guest is an anomaly. Tuned low on purpose: the tension
-- comes from most guests being fine, so refusing costs you something real.
local ANOMALY_CHANCE = 0.35

function Anomalies.roll(rng: Random): Guest
	local name = `{FIRST[rng:NextInteger(1, #FIRST)]} {LAST[rng:NextInteger(1, #LAST)]}`
	local reservation = string.format("%04d", rng:NextInteger(1, 9999))

	local anomaly: Anomaly? = nil
	if rng:NextNumber() < ANOMALY_CHANCE then
		anomaly = Anomalies.list[rng:NextInteger(1, #Anomalies.list)]
	end

	return {
		name = name,
		reservation = reservation,
		anomaly = anomaly,
	}
end

return Anomalies
