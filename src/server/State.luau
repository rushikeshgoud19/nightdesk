--!strict
-- Per-player profile, server-side only. Single owner of the numbers that matter.
--
-- Shift and Shop both read and write through here rather than keeping their own
-- copies, so there is exactly one place where takings can change and exactly one
-- place to look when they are wrong.
--
-- This is in-memory only. Week 4 of the plan swaps the body of load/release for
-- ProfileStore -- session-locked, autosaving, BindToClose-safe. The interface is
-- shaped for that swap: load returns a profile, release hands it back.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Anomalies = require(Shared:WaitForChild("Anomalies"))

export type Profile = {
	takings: number,
	mistakes: number,
	nightsWorked: number,
	owned: { [string]: boolean },
	-- Live shift, nil while the shop is open between nights.
	current: Anomalies.Guest?,
	tellVisible: boolean,
	guestsLeft: number,
}

local State = {}

local profiles: { [Player]: Profile } = {}

function State.load(player: Player): Profile
	local profile: Profile = {
		takings = 0,
		mistakes = 0,
		nightsWorked = 0,
		owned = {},
		current = nil,
		tellVisible = false,
		guestsLeft = 0,
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
