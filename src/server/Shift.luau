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
local arrivalToken: { [Player]: number } = {}

local function claimArrival(player: Player): number
	local token = (arrivalToken[player] or 0) + 1
	arrivalToken[player] = token
	return token
end

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
	sanityUpdate:FireClient(player, {
		sanity = p.sanity,
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

local function endShift(player: Player, survived: boolean)
	local p = State.get(player)
	if not p or not p.shiftActive then
		return
	end

	p.current = nil
	p.shiftActive = false
	p.waitingGuest = nil
	p.lastShiftSurvived = survived
	local bonus = 0

	if survived then
		if p.sanity > 50 then
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
		mistakes = p.mistakes,
		sanity = p.sanity,
		survived = survived,
		bonus = bonus,
		seed = p.shiftSeed,
	})
	if onShiftEnd then
		onShiftEnd(player)
	end
end

local function sendNext(player: Player)
	local p = State.get(player)
	if not p or not p.shiftActive then
		return
	end
	if p.current then
		return
	end

	if p.sanity <= 0 then
		endShift(player, false)
		return
	end

	if not p.waitingGuest then
		return
	end

	-- Occasional blackout fuse blowout on Night 3+
	if p.nightsWorked >= 2 and p.rng and p.rng:NextNumber() < 0.25 and not p.breakerTripped then
		p.breakerTripped = true
		breakerTripped:FireClient(player)
	end

	local guest = p.waitingGuest
	p.waitingGuest = nil
	p.waitingSince = nil
	p.current = guest

	local stats = Upgrades.stats(p.owned)
	local textVisible = guest.anomaly ~= nil and p.rng and p.rng:NextNumber() < stats.tellChance
	p.tellVisible = textVisible

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
		sanity = p.sanity,
		takings = p.takings,
		nightNumber = p.nightsWorked + 1,
		visualSeed = if p.rng then p.rng:NextInteger(1, 9999999) else 1,
	})
end

local function resolve(player: Player, admitted: boolean)
	local p = State.get(player)
	if not p then
		return
	end

	local guest = p.current
	if not guest then
		return
	end
	p.current = nil

	local isAnomaly = guest.anomaly ~= nil
	local correct = (isAnomaly and not admitted) or (not isAnomaly and admitted)
	local stats = Upgrades.stats(p.owned)

	-- The client used to hardcode "+$40" and "-40%" in its verdict line. Both
	-- move with upgrades -- neon_restoration raises the payout, steel_shutter
	-- halves the penalty -- so the numbers on screen were wrong the moment
	-- anything was bought. The server owns them, so the server states them.
	local paid = 0
	local sanityLost = 0

	if correct then
		paid = stats.payout
		p.takings += paid
	else
		local basePenalty = if isAnomaly and admitted then 40 else 20
		sanityLost = if stats.hasShutter then math.floor(basePenalty * 0.5) else basePenalty
		p.sanity = math.max(0, p.sanity - sanityLost)
		p.mistakes += 1
	end

	shiftUpdate:FireClient(player, {
		correct = correct,
		wasAnomaly = isAnomaly,
		anomalyId = if isAnomaly and guest.anomaly then guest.anomaly.id else nil,
		tell = if isAnomaly and guest.anomaly then guest.anomaly.tell else nil,
		paid = paid,
		sanityLost = sanityLost,
		takings = p.takings,
		mistakes = p.mistakes,
		sanity = p.sanity,
		nightNumber = p.nightsWorked + 1,
	})

	local token = claimArrival(player)
	task.wait(GAP_AFTER_JUDGEMENT)
	if arrivalToken[player] ~= token then
		return -- the bell already brought the next guest up
	end
	sendNext(player)
end

function Shift.start(player: Player)
	local p = State.get(player)
	if not p then
		return
	end
	local stats = Upgrades.stats(p.owned)
	local nightBonus = math.clamp(p.nightsWorked, 0, 4)
	local totalGuests = stats.guestsPerShift + nightBonus

	p.shiftSeed = math.random(10000, 99999)
	p.rng = Random.new(p.shiftSeed)

	p.sanity = 100
	p.shiftStartTakings = p.takings
	p.shiftActive = true
	p.mistakes = 0
	p.hasBrewedCoffee = false
	p.breakerTripped = false
	p.current = nil
	p.shiftTime = 0
	p.waitingGuest = nil
	p.waitingSince = nil
	p.spawnedGuests = 0
	p.nextArrivalMin = 360 / (totalGuests + 1)

	pushLoadout(player)

	task.spawn(function()
		while p.shiftActive do
			task.wait(1)
			if not p.shiftActive then
				break
			end

			p.shiftTime += 0.5

			if p.shiftTime >= 360 then
				endShift(player, true)
				break
			end

			if p.sanity <= 0 then
				endShift(player, false)
				break
			end

			if
				p.spawnedGuests < totalGuests
				and p.shiftTime >= p.nextArrivalMin
				and not p.waitingGuest
				and not p.current
			then
				local phase = getPhase(p.shiftTime)
				local chance = phase.chance + (p.nightsWorked * 0.05)
				if p.rng then
					p.waitingGuest = Anomalies.roll(p.rng, chance, phase.tiers)
				end
				p.waitingSince = p.shiftTime
				p.spawnedGuests += 1
				p.nextArrivalMin = (360 / (totalGuests + 1)) * (p.spawnedGuests + 1)
			end

			if p.waitingGuest and p.waitingSince and (p.shiftTime - p.waitingSince) > 20 then
				p.waitingGuest = nil
				p.waitingSince = nil
				-- "revenue that walked out" -> deduction
				p.takings = math.max(0, p.takings - 10)
			end

			timeTick:FireClient(player, {
				time = p.shiftTime,
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

		local p = State.get(player)
		if p and p.shiftActive and not p.current and p.waitingGuest then
			claimArrival(player)
			sendNext(player)
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

		local p = State.get(player)
		if not p or not p.current then
			phoneResponse:FireClient(player, {
				success = false,
				message = "Line dead. No active guest at desk.",
				audioType = "dead",
			})
			return
		end

		local guest = p.current
		local num = tonumber(roomNum) or guest.roomNumber

		-- The phone answers about the room that was dialled, not about whoever
		-- happens to be at the desk. Dialling 999 used to report the current
		-- guest's occupancy, which meant the ledger never had to be read to work
		-- the phone -- the signature investigation tool answered itself.
		--
		-- Rooms 101-108 are the motel. A number outside that range has no line,
		-- which is how the `invalid_room_109` ledger tell gets confirmed: read
		-- the room off the document, dial it, and the switchboard says it does
		-- not exist.
		if num < 101 or num > 108 then
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
		local p = State.get(player)
		local hasSymbol = p and p.current and p.current.uvSymbol ~= nil
		local symbolType = if p and p.current then p.current.uvSymbol else nil

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

		local p = State.get(player)
		if not p or not p.current then
			return
		end

		local guest = p.current
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
				answer = NORMAL_PURPOSES[p.rng:NextInteger(1, #NORMAL_PURPOSES)]
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
					`Oregon plates: {p.rng:NextInteger(100, 999)}-XNV on the sedan parked outside.`
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
		if not p or not p.shiftActive or p.hasBrewedCoffee then
			return
		end
		-- The espresso machine is a $100 upgrade. It used to work whether or not
		-- it had been bought.
		if not Upgrades.stats(p.owned).hasCoffee then
			return
		end
		p.hasBrewedCoffee = true
		p.sanity = math.min(100, p.sanity + 25)
		pushSanity(player)
	end)

	buySoda.OnServerEvent:Connect(function(player: Player)
		local p = State.get(player)
		if not p or not p.shiftActive or p.takings < 5 then
			return
		end
		p.takings -= 5
		p.sanity = math.min(100, p.sanity + 10)
		pushSanity(player)
	end)

	resetBreaker.OnServerEvent:Connect(function(player: Player)
		local p = State.get(player)
		-- Requires a breaker that is actually tripped. Without the check a client
		-- could fire this on a loop and never experience a blackout at all.
		if p and p.breakerTripped then
			p.breakerTripped = false
			breakerRestored:FireClient(player)
		end
	end)
end

-- Called from PlayerRemoving. These tables are keyed by Player, so without this
-- the server holds a reference to every player who has ever joined.
function Shift.forget(player: Player)
	lastBellRing[player] = nil
	lastPhoneCall[player] = nil
	lastInterrogate[player] = nil
	arrivalToken[player] = nil
end

return Shift
