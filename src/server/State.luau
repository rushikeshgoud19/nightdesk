--!strict
-- Per-player profile, server-side only. Single owner of the numbers that matter.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Anomalies = require(Shared:WaitForChild("Anomalies"))

export type Profile = {
	takings: number,
	mistakes: number,
	sanity: number,
	shiftStartTakings: number,
	lastShiftSurvived: boolean?,
	nightsWorked: number,
	owned: { [string]: boolean },
	current: Anomalies.Guest?,
	tellVisible: boolean,
	guestsLeft: number,
	shiftActive: boolean,
	hasBrewedCoffee: boolean,
	breakerTripped: boolean,
}

local State = {}

local profiles: { [Player]: Profile } = {}

function State.load(player: Player): Profile
	local profile: Profile = {
		takings = 0,
		mistakes = 0,
		sanity = 100,
		shiftStartTakings = 0,
		nightsWorked = 0,
		owned = {},
		current = nil,
		tellVisible = false,
		guestsLeft = 0,
		shiftActive = false,
		hasBrewedCoffee = false,
		breakerTripped = false,
	}
	profiles[player] = profile
	return profile
end

function State.get(player: Player): Profile?
	return profiles[player]
end

function State.release(player: Player)
	profiles[player] = nil
end

return State
