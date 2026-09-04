--!strict
-- The night, as one shared thing.
--
-- Before this, every field of a shift lived on a per-player profile: the guest
-- at the desk, the clock, the sanity, the seed. Two people joining meant two
-- separate games being played at the same counter -- different guests, different
-- nights, neither able to see what the other was arguing about.
--
-- The server IS the session. There are no lobbies and no party codes: everyone
-- on the server works the same desk, which is why MaxPlayers is 4. That is the
-- simplest thing that can work and the design asks for 2-4 players, not for a
-- social layer.
--
-- WHAT IS SHARED AND WHAT IS NOT
--
-- Shared: the guest, the clock, the seed, the sanity, the breaker. One motel.
-- A wrong admission costs everybody, which is what gives the argument stakes --
-- if your mistake only cost you, nobody would care what you thought.
--
-- Not shared: wallets and upgrades. Those stay on the player's own profile, so
-- ProfileStore is untouched and your progress is yours whoever you play with.
--
-- Deliberately not shared: whether the hint text is visible. tellChance is a
-- personal upgrade, so two players looking at the same guest may not both get
-- it. "I can see something wrong with his eyes" / "I've got nothing" is the
-- conversation this game is for, not a bug to average away.

local Players = game:GetService("Players")

local Session = {}

export type Shift = {
	-- The night
	active: boolean,
	time: number, -- minutes past midnight, 0 to 360
	seed: number,
	rng: Random?,

	-- The desk
	current: any?, -- the guest being judged
	waitingGuest: any?, -- arrived, standing at the door, not yet called up
	waitingSince: number?,
	nextArrivalMin: number,
	spawnedGuests: number,
	totalGuests: number,
	arrivalToken: number,

	-- Shared consequence
	sanity: number,
	mistakes: number,
	hasBrewedCoffee: boolean,
	breakerTripped: boolean,

	-- Which night the session is working. Taken from whoever starts it.
	nightNumber: number,
}

local shift: Shift = {
	active = false,
	time = 0,
	seed = 0,
	rng = nil,
	current = nil,
	waitingGuest = nil,
	waitingSince = nil,
	nextArrivalMin = 0,
	spawnedGuests = 0,
	totalGuests = 0,
	arrivalToken = 0,
	sanity = 100,
	mistakes = 0,
	hasBrewedCoffee = false,
	breakerTripped = false,
	nightNumber = 1,
}

function Session.get(): Shift
	return shift
end

function Session.reset(nightNumber: number, totalGuests: number, seed: number)
	shift.active = true
	shift.time = 0
	shift.seed = seed
	shift.rng = Random.new(seed)
	shift.current = nil
	shift.waitingGuest = nil
	shift.waitingSince = nil
	shift.spawnedGuests = 0
	shift.totalGuests = totalGuests
	shift.nextArrivalMin = 360 / (totalGuests + 1)
	-- A new night starts with a clean board. These used to persist for a whole
	-- login: night 2 opened carrying night 1's mistakes, the espresso machine was
	-- once per session rather than once per night, and a blackout left unresolved
	-- at dawn was still tripped when the next shift began.
	shift.sanity = 100
	shift.mistakes = 0
	shift.hasBrewedCoffee = false
	shift.breakerTripped = false
	shift.nightNumber = nightNumber
	Session.claimArrival()
end

function Session.stop()
	shift.active = false
	shift.current = nil
	shift.waitingGuest = nil
	shift.waitingSince = nil
end

-- One arrival may be in flight. `resolve` schedules the next guest behind a
-- wait, and the bell can ask for one during that wait; without a token both land
-- and the second overwrites the guest the players are still looking at. With
-- four people able to hit the bell this matters considerably more than it did
-- with one.
function Session.claimArrival(): number
	shift.arrivalToken += 1
	return shift.arrivalToken
end

function Session.arrivalStillValid(token: number): boolean
	return shift.arrivalToken == token
end

-- Everyone working the desk. The server is the session, so this is simply
-- whoever is here.
function Session.players(): { Player }
	return Players:GetPlayers()
end

-- Fire a remote to the whole crew. Every shared fact -- the guest, the clock,
-- the verdict, the sanity -- goes through one of these rather than to one
-- player, because a fact that reaches one client and not the others is how two
-- people end up arguing about different games.
function Session.fireAll(remote: RemoteEvent, payload: any)
	for _, player in Players:GetPlayers() do
		remote:FireClient(player, payload)
	end
end

return Session
