--!strict
-- Per-player profile, server-side only. Single owner of the numbers that matter.

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local ProfileStore =
	require(ServerScriptService:WaitForChild("Packages"):WaitForChild("ProfileStore"))

export type Profile = {
	takings: number,
	shiftStartTakings: number,
	lastShiftSurvived: boolean?,
	nightsWorked: number,
	owned: { [string]: boolean },
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
	-- ProfileStore v1 API. These names differ from the older ProfileService and
	-- from ProfileStore's own pre-1.0 releases, and the mismatch is invisible to
	-- selene, to stylua and to `rojo build` -- a wrong name here only surfaces as
	-- a runtime crash on the first PlayerAdded, which then silently kills the
	-- whole shift loop. If you change the pinned version in wally.toml, re-read
	-- the API before trusting this file.
	--
	--   StartSessionAsync   (not LoadProfileAsync)
	--   OnSessionEnd:Connect (not ListenToRelease)
	--   EndSession          (not Release)
	local profile = store:StartSessionAsync("Player_" .. player.UserId)
	if profile ~= nil then
		profile:AddUserId(player.UserId)
		profile:Reconcile()

		-- Migration path for future versions
		if profile.Data.schemaVersion == nil then
			profile.Data.schemaVersion = 1
		end

		profile.OnSessionEnd:Connect(function()
			activeProfiles[player] = nil
			proxies[player] = nil
			-- Fires on our own EndSession too, where the player has usually left
			-- already and this is a no-op. It matters when another server steals
			-- the session lock: that player must not keep playing on stale data.
			player:Kick("Your save was opened on another server.")
		end)

		if player:IsDescendantOf(Players) then
			activeProfiles[player] = profile

			-- The night itself lives in Session now -- the guest, the clock, the
			-- seed, the sanity, the breaker -- because the server is one shared
			-- shift and those are facts about the motel, not about a person.
			--
			-- What is left here is what genuinely belongs to this player: their
			-- wallet and upgrades, which persist, and what their own takings were
			-- when the night began, so a failed shift forfeits theirs and nobody
			-- else's.
			local proxy = {
				shiftStartTakings = profile.Data.takings,
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
			profile:EndSession()
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
		profile:EndSession()
	end
	activeProfiles[player] = nil
	proxies[player] = nil
end

return State
