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

local rng = Random.new()

local GAP_AFTER_JUDGEMENT = 1.8

local Shift = {}

local onShiftEnd: ((Player) -> ())? = nil

function Shift.setShiftEndHandler(fn: (Player) -> ())
	onShiftEnd = fn
end

local function sendNext(player: Player)
	local p = State.get(player)
	if not p then
		return
	end

	if p.guestsLeft <= 0 or p.sanity <= 0 then
		p.current = nil
		p.shiftActive = false
		p.guestsLeft = 0
		local survived = p.sanity > 0
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
		})
		if onShiftEnd then
			onShiftEnd(player)
		end
		return
	end

	p.guestsLeft -= 1

	-- Occasional blackout fuse blowout on Night 3+
	if p.nightsWorked >= 2 and rng:NextNumber() < 0.25 and not p.breakerTripped then
		p.breakerTripped = true
		breakerTripped:FireClient(player)
	end

	local guest = Anomalies.roll(rng)
	p.current = guest

	local stats = Upgrades.stats(p.owned)
	local textVisible = guest.anomaly ~= nil and rng:NextNumber() < stats.tellChance
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

		tell = if textVisible and guest.anomaly then guest.anomaly.tell else nil,
		anomalyId = if guest.anomaly then guest.anomaly.id else nil,
		horrorType = if guest.anomaly then guest.anomaly.horrorType else nil,
		uvSymbol = guest.uvSymbol,
		isRoomOccupied = guest.isRoomOccupied,
		guestsLeft = p.guestsLeft,
		sanity = p.sanity,
		takings = p.takings,
		nightNumber = p.nightsWorked + 1,
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

	if correct then
		p.takings += stats.payout
	else
		-- Halve penalty if player owns Emergency Counter Steel Shutter
		local basePenalty = if isAnomaly and admitted then 40 else 20
		local penalty = if stats.hasShutter then math.floor(basePenalty * 0.5) else basePenalty
		p.sanity = math.max(0, p.sanity - penalty)
		p.mistakes += 1
	end

	shiftUpdate:FireClient(player, {
		correct = correct,
		wasAnomaly = isAnomaly,
		anomalyId = if isAnomaly and guest.anomaly then guest.anomaly.id else nil,
		tell = if isAnomaly and guest.anomaly then guest.anomaly.tell else nil,
		takings = p.takings,
		mistakes = p.mistakes,
		sanity = p.sanity,
		nightNumber = p.nightsWorked + 1,
	})

	task.wait(GAP_AFTER_JUDGEMENT)
	sendNext(player)
end

function Shift.start(player: Player)
	local p = State.get(player)
	if not p then
		return
	end
	local stats = Upgrades.stats(p.owned)
	-- Dynamic guest count scaling with night progression
	local nightBonus = math.clamp(p.nightsWorked, 0, 4)
	p.guestsLeft = stats.guestsPerShift + nightBonus
	p.sanity = 100
	p.shiftStartTakings = p.takings
	p.shiftActive = true
	sendNext(player)
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
		if p and p.shiftActive and not p.current and p.guestsLeft > 0 then
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
		if not p or not p.shiftActive or p.hasBrewedCoffee then
			return
		end
		p.hasBrewedCoffee = true
		p.sanity = math.min(100, p.sanity + 25)
		shiftUpdate:FireClient(player, {
			correct = true,
			wasAnomaly = false,
			takings = p.takings,
			mistakes = p.mistakes,
			sanity = p.sanity,
			nightNumber = p.nightsWorked + 1,
		})
	end)

	buySoda.OnServerEvent:Connect(function(player: Player)
		local p = State.get(player)
		if not p or not p.shiftActive or p.takings < 5 then
			return
		end
		p.takings -= 5
		p.sanity = math.min(100, p.sanity + 10)
		shiftUpdate:FireClient(player, {
			correct = true,
			wasAnomaly = false,
			takings = p.takings,
			mistakes = p.mistakes,
			sanity = p.sanity,
			nightNumber = p.nightsWorked + 1,
		})
	end)

	resetBreaker.OnServerEvent:Connect(function(player: Player)
		local p = State.get(player)
		if p then
			p.breakerTripped = false
			breakerRestored:FireAllClients()
		end
	end)
end

return Shift
