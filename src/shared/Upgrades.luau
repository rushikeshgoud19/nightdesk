--!strict
-- The master upgrade catalogue for the Highway Motel.
--
-- Upgrades buy INFORMATION, SURVEILLANCE, and MOTEL EXPANSION.
-- Server-authoritative: The server calculates and validates every stat and purchase.

export type Upgrade = {
	id: string,
	name: string,
	blurb: string,
	cost: number,
	category: "investigation" | "security" | "expansion",
	requires: string?,
}

local Upgrades = {}

Upgrades.list = {
	-- 1. INVESTIGATION & TOOLS
	{
		id = "uv_boost",
		name = "High-Output UV Blacklight",
		blurb = "Casts a wide ultraviolet beam revealing hidden occult runes and forged seals instantly.",
		cost = 80,
		category = "investigation",
	},
	{
		id = "lights",
		name = "Commercial Halogen Tube Lights",
		blurb = "Restores reception lighting. Physical anomaly tells show far more clearly.",
		cost = 220,
		category = "investigation",
	},
	{
		id = "cheat_sheet",
		name = "Dossier Anomaly Cheatsheet",
		blurb = "Pins known anomaly behavioral tell notes directly onto the reception desk.",
		cost = 300,
		category = "investigation",
		requires = "lights",
	},

	-- 2. SECURITY & SURVEILLANCE
	{
		id = "coffee_maker",
		name = "Commercial Espresso Machine",
		blurb = "Restores +25% sanity between high-stress anomaly encounters.",
		cost = 100,
		category = "security",
	},
	{
		id = "cctv_monitor",
		name = "CCTV Security Monitor System",
		blurb = "Installs a CRT surveillance monitor on the desk to cycle external & hallway cameras [C].",
		cost = 250,
		category = "security",
		requires = "lights",
	},
	{
		id = "steel_shutter",
		name = "Emergency Counter Security Shutter",
		blurb = "Reinforces the front desk against violent jumpscare breaches, halving sanity damage.",
		cost = 400,
		category = "security",
		requires = "cctv_monitor",
	},

	-- 3. MOTEL EXPANSION & REVENUE
	{
		id = "neon_restoration",
		name = "Restore Highway Neon Sign",
		blurb = "Illuminates the highway sign, attracting wealthier travelers and boosting payout +$15/guest.",
		cost = 120,
		category = "expansion",
	},
	{
		id = "room_2",
		name = "Reopen Guest Wing (Room 102)",
		blurb = "Expands guest capacity by +1 guest each night. More revenue, more judgement calls.",
		cost = 180,
		category = "expansion",
	},
	{
		id = "room_3",
		name = "Reopen Guest Wing (Room 103)",
		blurb = "Expands motel capacity by +1 guest each night.",
		cost = 320,
		category = "expansion",
		requires = "room_2",
	},
	{
		id = "floor_2",
		name = "Reopen Second Floor (Rooms 201–208)",
		blurb = "Twice the motel capacity. Unlocks high-stakes multi-entity shifts.",
		cost = 850,
		category = "expansion",
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

export type Stats = {
	guestsPerShift: number,
	tellChance: number,
	payout: number,
	hasCCTV: boolean,
	hasShutter: boolean,
	hasCoffee: boolean,
}

local BASE_GUESTS = 4
local BASE_TELL_CHANCE = 0.40
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
		rooms += 3
	end

	local tell = BASE_TELL_CHANCE
	if owned.lights then
		tell += 0.20
	end
	if owned.cheat_sheet then
		tell += 0.20
	end
	if owned.uv_boost then
		tell += 0.15
	end

	local bonusPayout = 0
	if owned.neon_restoration then
		bonusPayout += 15
	end

	return {
		guestsPerShift = BASE_GUESTS + rooms,
		tellChance = math.min(tell, MAX_TELL_CHANCE),
		payout = BASE_PAYOUT + rooms * 10 + bonusPayout,
		hasCCTV = owned.cctv_monitor == true,
		hasShutter = owned.steel_shutter == true,
		hasCoffee = owned.coffee_maker == true,
	}
end

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
		return false, `Costs ${u.cost}`
	end
	return true, nil
end

return Upgrades
