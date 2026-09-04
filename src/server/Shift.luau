--!strict
-- Runs a multi-night story campaign. Sends guests to the desk one at a time, processes
-- telephone room checks, UV blacklight inspections, intercom interrogations, judges calls,
-- scales difficulty per night (Nights 1–5), and manages sanity/economy.
--
-- SERVER-AUTHORITATIVE:
-- The tell crosses the wire so the 3D guest model renders its physical appearance
-- and the player can observe it. The verdict, sanity deduction, and payouts
-- are strictly owned by the server.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Anomalies = require(Shared:WaitForChild("Anomalies"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Upgrades = require(Shared:WaitForChild("Upgrades"))

local Session = require(script.Parent:WaitForChild("Session"))
local State = require(script.Parent:WaitForChild("State"))

local guestArrived = Remotes.get("GuestArrived")
local judge = Remotes.get("Judge")
local shiftUpdate = Remotes.get("ShiftUpdate")
local sanityUpdate = Remotes.get("SanityUpdate")
local loadout = Remotes.get("Loadout")
local shiftEnded = Remotes.get("ShiftEnded")
local ringBell = Remotes.get("RingBell")
local bellRang = Remotes.get("BellRang")
local callRoom = Remotes.get("CallRoom")
local phoneResponse = Remotes.get("PhoneResponse")
local toggleUV = Remotes.get("ToggleUV")
local uvState = Remotes.get("UVState")
local interrogate = Remotes.get("Interrogate")
local interrogationResponse = Remotes.get("InterrogationResponse")
local brewCoffee = Remotes.get("BrewCoffee")
local buySoda = Remotes.get("BuySoda")
local resetBreaker = Remotes.get("ResetBreaker")
local breakerTripped = Remotes.get("BreakerTripped")
local breakerRestored = Remotes.get("BreakerRestored")

local timeTick = Remotes.get("TimeTick")

local PHASES = {
	{
		startMin = 0,
		name = "12:00 AM - Calm",
		chance = 0.05,
		tiers = { [1] = 100, [2] = 0, [3] = 0 },
	},
	{
		startMin = 60,
		name = "01:00 AM - Unease",
		chance = 0.20,
		tiers = { [1] = 80, [2] = 20, [3] = 0 },
	},
	{
		startMin = 120,
		name = "02:00 AM - Activity",
		chance = 0.35,
		tiers = { [1] = 60, [2] = 35, [3] = 5 },
	},
	{
		startMin = 210,
		name = "03:30 AM - Suspicion",
		chance = 0.55,
		tiers = { [1] = 40, [2] = 50, [3] = 10 },
	},
	{
		startMin = 300,
		name = "05:00 AM - Climax",
		chance = 0.85,
		tiers = { [1] = 10, [2] = 50, [3] = 40 },
	},
}

local function getPhase(time: number)
	local phase = PHASES[1]
	for i = 2, #PHASES do
		if time >= PHASES[i].startMin then
			phase = PHASES[i]
		else
			break
		end
	end
	return phase
end

local GAP_AFTER_JUDGEMENT = 1.8

-- One arrival may be in flight per player. `resolve` schedules the next guest
-- behind a wait, and the bell can ask for one during that wait -- without a
-- token both land and the second overwrites `p.current` while the client is
-- still showing the first.

local Shift = {}

local onShiftEnd: ((Player) -> ())? = nil

function Shift.setShiftEndHandler(fn: (Player) -> ())
	onShiftEnd = fn
end

-- Sanity moved without a verdict being passed. This is deliberately NOT
-- ShiftUpdate: that remote means "a guest was judged", and the client renders a
-- verdict line and clears the desk prompt when it arrives. Brewing coffee is not
-- a verdict.
local function pushSanity(player: Player)
	local p = State.get(player)
	if not p then
		return
	end
	Session.fireAll(sanityUpdate, {
		sanity = Session.get().sanity,
		takings = p.takings,
	})
end

-- What the player has actually bought. The client needs this to know whether a
-- tool is installed at all -- until now it offered every tool regardless, which
-- made three shop items placebo.
local function pushLoadout(player: Player)
	local p = State.get(player)
	if not p then
		return
	end
	local stats = Upgrades.stats(p.owned)
	loadout:FireClient(player, {
		hasCCTV = stats.hasCCTV,
		hasCoffee = stats.hasCoffee,
	})
end

Shift.pushLoadout = pushLoadout

-- The night ends once, for everyone. Each wallet is then settled on its own,
-- because takings and upgrades are per player -- your progress is yours whoever
-- you happen to have played with.
local function endShift(survived: boolean)
	local sh = Session.get()
	if not sh.active then
		return
	end
	Session.stop()

	for _, player in Session.players() do
		local p = State.get(player)
		if p then
			p.lastShiftSurvived = survived
			local bonus = 0

			if survived then
				if sh.sanity > 50 then
					bonus = 50
					p.takings += bonus
				end
				-- Night 5 Campaign Grand Survivor Bonus
				if p.nightsWorked == 4 then
					bonus += 500
					p.takings += 500
				end
			else
				p.takings = p.shiftStartTakings
			end

			p.nightsWorked += 1
			shiftEnded:FireClient(player, {
				nightsWorked = p.nightsWorked,
				takings = p.takings,
				mistakes = sh.mistakes,
				sanity = sh.sanity,
				survived = survived,
				bonus = bonus,
				seed = sh.seed,
			})
			if onShiftEnd then
				onShiftEnd(player)
			end
		end
	end
end

-- The payload one player receives. Identical for everyone except `tell` and the
-- player's own takings.
local function sendGuestTo(player: Player, guest: any, textVisible: boolean, visualSeed: number)
	local sh = Session.get()
	local p = State.get(player)
	guestArrived:FireClient(player, {
		name = guest.name,
		reservation = guest.reservation,
		idName = guest.idName,
		checkInDate = guest.checkInDate,
		checkOutDate = guest.checkOutDate,
		roomNumber = guest.roomNumber,
		cityOrigin = guest.cityOrigin,
		zipCode = guest.zipCode,
		stayLength = guest.stayLength,
		signatureFont = guest.signatureFont,
		watermarkText = guest.watermarkText,
		photoMaskTransparency = guest.photoMaskTransparency,
		licenseExpiry = guest.licenseExpiry,
		tell = if textVisible and guest.anomaly then guest.anomaly.tell else nil,
		anomalyId = if guest.anomaly then guest.anomaly.id else nil,
		horrorType = if guest.anomaly then guest.anomaly.horrorType else nil,
		uvSymbol = guest.uvSymbol,
		isRoomOccupied = guest.isRoomOccupied,
		sanity = sh.sanity,
		takings = if p then p.takings else 0,
		nightNumber = sh.nightNumber,
		-- Passed in, NOT drawn here. Drawing it per player would give every
		-- client a different number for the same guest, and two people at one
		-- desk would be looking at two different faces -- which is precisely the
		-- thing co-op has to make impossible.
		visualSeed = visualSeed,
	})
end

-- One guest, called up to the desk, shown to everyone working it.
local function sendNext()
	local sh = Session.get()
	if not sh.active or sh.current then
		return
	end

	if sh.sanity <= 0 then
		endShift(false)
		return
	end

	if not sh.waitingGuest then
		return
	end

	-- Occasional blackout fuse blowout on Night 3+
	if sh.nightNumber >= 3 and sh.rng and sh.rng:NextNumber() < 0.25 and not sh.breakerTripped then
		sh.breakerTripped = true
		Session.fireAll(breakerTripped, nil)
	end

	local guest = sh.waitingGuest
	sh.waitingGuest = nil
	sh.waitingSince = nil
	sh.current = guest

	-- The hint roll is taken ONCE per guest so the whole crew is looking at the
	-- same coin, then each player is told the answer only if their own upgrades
	-- earned it. tellChance is personal on purpose: two people disagreeing about
	-- what they can even see is the conversation this game is for.
	local hintRoll = if sh.rng then sh.rng:NextNumber() else 1
	-- Drawn once, for the guest, not once per player.
	local visualSeed = if sh.rng then sh.rng:NextInteger(1, 9999999) else math.random(1, 9999999)
	sh.currentVisualSeed = visualSeed

	for _, player in Session.players() do
		local p = State.get(player)
		if p then
			local stats = Upgrades.stats(p.owned)
			local textVisible = guest.anomaly ~= nil and hintRoll < stats.tellChance
			sendGuestTo(player, guest, textVisible, visualSeed)
		end
	end
end

-- Whoever stamps first passes the verdict for the crew. A second stamp a frame
-- later finds no guest and does nothing, so nobody gets paid or penalised twice.
local function resolve(player: Player, admitted: boolean)
	local sh = Session.get()
	local guest = sh.current
	if not guest then
		return
	end
	sh.current = nil

	local judgedBy = player.Name
	local isAnomaly = guest.anomaly ~= nil
	local correct = (isAnomaly and not admitted) or (not isAnomaly and admitted)

	-- The client used to hardcode "+$40" and "-40%" in its verdict line. Both
	-- move with upgrades -- neon_restoration raises the payout, steel_shutter
	-- halves the penalty -- so the numbers on screen were wrong the moment
	-- anything was bought. The server owns them, so the server states them.
	local sanityLost = 0
	if not correct then
		-- The shutter is a motel fixture, so the session takes the best one
		-- anybody present owns. A well-equipped player visibly protects the crew.
		local anyShutter = false
		for _, pl in Session.players() do
			local pp = State.get(pl)
			if pp and Upgrades.stats(pp.owned).hasShutter then
				anyShutter = true
				break
			end
		end
		local basePenalty = if isAnomaly and admitted then 40 else 20
		sanityLost = if anyShutter then math.floor(basePenalty * 0.5) else basePenalty
		-- Sanity is the motel's, not the clerk's. A wrong admission costs
		-- everyone, which is what gives the argument stakes.
		sh.sanity = math.max(0, sh.sanity - sanityLost)
		sh.mistakes += 1
	end

	-- Everyone sees the outcome. Each player is paid into their own wallet, at
	-- their own rate, so "who let him in" is answerable and progress stays yours.
	for _, pl in Session.players() do
		local pp = State.get(pl)
		if pp then
			local paid = 0
			if correct then
				paid = Upgrades.stats(pp.owned).payout
				pp.takings += paid
			end
			shiftUpdate:FireClient(pl, {
				correct = correct,
				wasAnomaly = isAnomaly,
				judgedBy = judgedBy,
				anomalyId = if isAnomaly and guest.anomaly then guest.anomaly.id else nil,
				tell = if isAnomaly and guest.anomaly then guest.anomaly.tell else nil,
				paid = paid,
				sanityLost = sanityLost,
				takings = pp.takings,
				mistakes = sh.mistakes,
				sanity = sh.sanity,
				nightNumber = sh.nightNumber,
			})
		end
	end

	local token = Session.claimArrival()
	task.wait(GAP_AFTER_JUDGEMENT)
	if not Session.arrivalStillValid(token) then
		return -- the bell already brought the next guest up
	end
	sendNext()
end

-- Any player may start the night. There is no ready-check: the crew is whoever
-- is standing here, and a session that waits for consensus is a session nobody
-- starts.
--
-- Motel-wide capacity is the best anyone present owns. A player who has bought
-- rooms brings them to the whole crew, which is the intended feeling -- turning
-- up well-equipped visibly helps everybody.
function Shift.start(_starter: Player)
	local sh = Session.get()
	if sh.active then
		return
	end

	local nightNumber, totalGuests = 1, 0
	local anyUpstairs = false
	for _, player in Session.players() do
		local p = State.get(player)
		if p then
			local stats = Upgrades.stats(p.owned)
			local nightBonus = math.clamp(p.nightsWorked, 0, 4)
			totalGuests = math.max(totalGuests, stats.guestsPerShift + nightBonus)
			nightNumber = math.max(nightNumber, p.nightsWorked + 1)
			anyUpstairs = anyUpstairs or stats.hasUpstairs
			-- Each wallet remembers what it opened the night with, so a failed
			-- shift forfeits that player's own takings and nobody else's.
			p.shiftStartTakings = p.takings
			pushLoadout(player)
		end
	end
	if totalGuests <= 0 then
		return
	end

	Session.reset(nightNumber, totalGuests, math.random(10000, 99999))

	task.spawn(function()
		while sh.active do
			task.wait(1)
			if not sh.active then
				break
			end

			sh.time += 0.5

			if sh.time >= 360 then
				endShift(true)
				break
			end

			if sh.sanity <= 0 then
				endShift(false)
				break
			end

			if
				sh.spawnedGuests < sh.totalGuests
				and sh.time >= sh.nextArrivalMin
				and not sh.waitingGuest
				and not sh.current
			then
				local phase = getPhase(sh.time)
				local chance = phase.chance + ((sh.nightNumber - 1) * 0.05)
				if sh.rng then
					sh.waitingGuest = Anomalies.roll(sh.rng, chance, phase.tiers, anyUpstairs)
				end
				sh.waitingSince = sh.time
				sh.spawnedGuests += 1
				sh.nextArrivalMin = (360 / (sh.totalGuests + 1)) * (sh.spawnedGuests + 1)
			end

			if sh.waitingGuest and sh.waitingSince and (sh.time - sh.waitingSince) > 20 then
				sh.waitingGuest = nil
				sh.waitingSince = nil
				-- Revenue that walked back out into the rain. It comes off every
				-- wallet, because the crew let it happen together.
				for _, pl in Session.players() do
					local pp = State.get(pl)
					if pp then
						pp.takings = math.max(0, pp.takings - 10)
					end
				end
			end

			-- A guest arrives, waits, and after 20 in-game minutes walks out and
			-- costs $10. None of that used to reach the client, so the player was
			-- fined for missing something they had no way to perceive.
			local waitLeft: number? = nil
			if sh.waitingGuest and sh.waitingSince then
				waitLeft = math.max(0, 20 - (sh.time - sh.waitingSince))
			end

			Session.fireAll(timeTick, {
				time = sh.time,
				waiting = sh.waitingGuest ~= nil,
				waitLeft = waitLeft,
			})
		end
	end)
end

local lastBellRing: { [Player]: number } = {}
local lastPhoneCall: { [Player]: number } = {}
local lastInterrogate: { [Player]: number } = {}

function Shift.bind()
	judge.OnServerEvent:Connect(function(player: Player, admitted: unknown)
		if typeof(admitted) ~= "boolean" then
			return
		end
		resolve(player, admitted)
	end)

	ringBell.OnServerEvent:Connect(function(player: Player)
		local now = os.clock()
		local last = lastBellRing[player] or 0
		if now - last < 0.25 then
			return
		end
		lastBellRing[player] = now

		bellRang:FireAllClients(player)

		-- Anybody can ring it, and it calls the waiting guest up for everyone.
		local sh = Session.get()
		if sh.active and not sh.current and sh.waitingGuest then
			Session.claimArrival()
			sendNext()
		end
	end)

	callRoom.OnServerEvent:Connect(function(player: Player, roomNum: unknown)
		if typeof(roomNum) ~= "number" and typeof(roomNum) ~= "string" then
			return
		end
		local now = os.clock()
		local last = lastPhoneCall[player] or 0
		if now - last < 1.0 then
			return
		end
		lastPhoneCall[player] = now

		local sh = Session.get()
		if not sh.current then
			phoneResponse:FireClient(player, {
				success = false,
				message = "Line dead. No active guest at desk.",
				audioType = "dead",
			})
			return
		end

		local guest = sh.current
		local num = tonumber(roomNum) or guest.roomNumber

		-- The phone answers about the room that was dialled, not about whoever
		-- happens to be at the desk. Dialling 999 used to report the current
		-- guest's occupancy, which meant the ledger never had to be read to work
		-- the phone -- the signature investigation tool answered itself.
		--
		-- Rooms 101-108 are the ground floor and are always open. 201-208 exist
		-- only once floor_2 has been bought -- before that the switchboard has no
		-- line to them, which is the same answer it gives for a room that was
		-- never real. That is how the `invalid_room_109` ledger tell gets
		-- confirmed: read the room off the document, dial it, get nothing.
		-- The second floor is a motel fixture, not a personal tool, so the
		-- switchboard reaches it if anyone on the crew has reopened it.
		local upstairs = false
		for _, pl in Session.players() do
			local pp = State.get(pl)
			if pp and Upgrades.stats(pp.owned).hasUpstairs then
				upstairs = true
				break
			end
		end
		local groundFloor = num >= 101 and num <= 108
		local upperFloor = upstairs and num >= 201 and num <= 208
		if not groundFloor and not upperFloor then
			phoneResponse:FireClient(player, {
				success = false,
				isOccupied = false,
				message = `Line dead. Room {num} is not a room in this motel.`,
				audioType = "dead",
			})
			return
		end

		if num ~= guest.roomNumber then
			phoneResponse:FireClient(player, {
				success = true,
				isOccupied = false,
				message = `...Ringing Room {num}... No answer. Room is vacant and clean.`,
				audioType = "vacant",
			})
			return
		end

		if guest.isRoomOccupied or (guest.anomaly and guest.anomaly.roomMismatch) then
			local whisper = if guest.anomaly and guest.anomaly.phoneWhisper
				then guest.anomaly.phoneWhisper
				else `[DISTORTED BREATHING] ...Who is at the front desk? I'm already in room {num}...`

			local aType = "whisper"
			if guest.anomaly and guest.anomaly.id == "phone_static_screamer" then
				aType = "static"
			end

			phoneResponse:FireClient(player, {
				success = true,
				isOccupied = true,
				message = whisper,
				audioType = aType,
			})
		else
			phoneResponse:FireClient(player, {
				success = true,
				isOccupied = false,
				message = `...Ringing Room {num}... No answer. Room is vacant and clean.`,
				audioType = "vacant",
			})
		end
	end)

	toggleUV.OnServerEvent:Connect(function(player: Player, enabled: unknown)
		if typeof(enabled) ~= "boolean" then
			return
		end
		local sh = Session.get()
		local hasSymbol = sh.current and sh.current.uvSymbol ~= nil
		local symbolType = if sh.current then sh.current.uvSymbol else nil

		uvState:FireClient(player, {
			enabled = enabled,
			hasAnomaly = hasSymbol,
			symbolType = symbolType,
		})
	end)

	interrogate.OnServerEvent:Connect(function(player: Player, questionId: unknown)
		if typeof(questionId) ~= "string" then
			return
		end
		local now = os.clock()
		local last = lastInterrogate[player] or 0
		if now - last < 0.8 then
			return
		end
		lastInterrogate[player] = now

		local sh = Session.get()
		if not sh.current or not sh.rng then
			return
		end

		local rng = sh.rng
		local guest = sh.current
		local isAnomaly = guest.anomaly ~= nil
		local aId = if guest.anomaly then guest.anomaly.id else ""
		local answer = ""
		local isCreepy = false

		if questionId == "purpose" then
			if not isAnomaly then
				local NORMAL_PURPOSES = {
					"Just driving through on the I-84 highway... needed a dry room for the night.",
					"Long haul drive from Spokane. Need a bed until sunrise.",
					"Business delivery in Portland tomorrow morning.",
				}
				answer = NORMAL_PURPOSES[rng:NextInteger(1, #NORMAL_PURPOSES)]
			else
				isCreepy = true
				if aId == "frozen_smile" then
					answer = "To smile for your camera, clerk. We are always smiling."
				elseif aId == "hollow_eyes" then
					answer = "The light hurts. We came to sleep in the pitch dark."
				elseif aId == "faceless" then
					answer = "...[HEAVY WET BREATHING THROUGH VOID MIC]..."
				elseif aId == "drowned_corpse" then
					answer = "The river was too cold. We wanted somewhere dry."
				else
					answer = "To observe the flesh beneath your uniform."
				end
			end
		elseif questionId == "plate" then
			if not isAnomaly then
				answer =
					`Oregon plates: {rng:NextInteger(100, 999)}-XNV on the sedan parked outside.`
			else
				isCreepy = true
				answer = "I did not require a vehicle to arrive here."
			end
		elseif questionId == "mirror" then
			if not isAnomaly then
				answer = "Look into the mirror? Sure... everything looks in order."
			else
				isCreepy = true
				if aId == "snapped_neck" then
					answer = "[LOUD BONE CRACKING SPASM] ...Do you like my angle, clerk?"
				elseif aId == "no_reflection" then
					answer = "Why search for a reflection when nothing stands before you?"
				else
					answer = "Look behind you first, clerk..."
				end
			end
		end

		interrogationResponse:FireClient(player, {
			questionId = questionId,
			answer = answer,
			isCreepy = isCreepy,
		})
	end)

	brewCoffee.OnServerEvent:Connect(function(player: Player)
		local p = State.get(player)
		local sh = Session.get()
		if not p or not sh.active or sh.hasBrewedCoffee then
			return
		end
		-- The espresso machine is a $100 upgrade. It used to work whether or not
		-- it had been bought.
		if not Upgrades.stats(p.owned).hasCoffee then
			return
		end
		-- One pot per night, for the motel. Four people do not get four pots.
		sh.hasBrewedCoffee = true
		sh.sanity = math.min(100, sh.sanity + 25)
		pushSanity(player)
	end)

	buySoda.OnServerEvent:Connect(function(player: Player)
		local p = State.get(player)
		local sh = Session.get()
		if not p or not sh.active or p.takings < 5 then
			return
		end
		p.takings -= 5
		sh.sanity = math.min(100, sh.sanity + 10)
		pushSanity(player)
	end)

	resetBreaker.OnServerEvent:Connect(function(_player: Player)
		-- Requires a breaker that is actually tripped. Without the check a client
		-- could fire this on a loop and never experience a blackout at all.
		-- The breaker is the motel's, so restoring it restores it for the crew.
		-- Narrowing this to one client was correct when the state was per player;
		-- the guard requiring it to actually be tripped is the part that matters
		-- and it stays.
		local sh = Session.get()
		if sh.breakerTripped then
			sh.breakerTripped = false
			Session.fireAll(breakerRestored, nil)
		end
	end)
end

-- Called from PlayerRemoving. These tables are keyed by Player, so without this
-- the server holds a reference to every player who has ever joined.
function Shift.forget(player: Player)
	lastBellRing[player] = nil
	lastPhoneCall[player] = nil
	lastInterrogate[player] = nil
end

return Shift
