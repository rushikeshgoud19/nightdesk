--!strict
-- Per-player profile, server-side only. Single owner of the numbers that matter.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Anomalies = require(Shared:WaitForChild("Anomalies"))

local ProfileStore =
	require(ServerScriptService:WaitForChild("Packages"):WaitForChild("ProfileStore"))

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

local profileTemplate = {
	schemaVersion = 1,
	takings = 0,
	owned = {},
	nightsWorked = 0,
}

local store = ProfileStore.New("PlayerData", profileTemplate)

local State = {}

local activeProfiles = {} -- stores the original ProfileStore profiles
local proxies: { [Player]: Profile } = {} -- stores the proxy tables

function State.load(player: Player): Profile
	local profile = store:LoadProfileAsync("Player_" .. player.UserId)
	if profile ~= nil then
		profile:AddUserId(player.UserId)
		profile:Reconcile()

		-- Migration path for future versions
		if profile.Data.schemaVersion == nil then
			profile.Data.schemaVersion = 1
		end

		profile:ListenToRelease(function()
			activeProfiles[player] = nil
			proxies[player] = nil
			player:Kick("Profile released")
		end)

		if player:IsDescendantOf(Players) then
			activeProfiles[player] = profile

			local proxy = {
				mistakes = 0,
				sanity = 100,
				shiftStartTakings = profile.Data.takings,
				current = nil,
				tellVisible = false,
				guestsLeft = 0,
				shiftActive = false,
				hasBrewedCoffee = false,
				breakerTripped = false,
			}

			setmetatable(proxy, {
				__index = profile.Data,
				__newindex = function(t, k, v)
					if
						profile.Data[k] ~= nil
						or k == "takings"
						or k == "owned"
						or k == "nightsWorked"
					then
						profile.Data[k] = v
					else
						rawset(t, k, v)
					end
				end,
			})

			local typedProxy = (proxy :: any) :: Profile
			proxies[player] = typedProxy
			return typedProxy
		else
			profile:Release()
			-- Return a dummy profile if the player left during load just to satisfy strict typing
			return State.get(player) or ({} :: any)
		end
	end

	player:Kick("Failed to load data profile.")
	return ({} :: any) :: Profile
end

function State.get(player: Player): Profile?
	return proxies[player]
end

function State.release(player: Player)
	local profile = activeProfiles[player]
	if profile then
		profile:Release()
	end
	activeProfiles[player] = nil
	proxies[player] = nil
end

return State
