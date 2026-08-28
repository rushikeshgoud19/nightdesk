--!strict
-- The master anomaly catalog for the Highway Motel.
-- Launch target: 40+ distinct observable tells across 4 escalation tiers.
--
-- Every entry defines an unmistakable tell observable via 3D character morphology,
-- document ledger cross-referencing, rotary telephone verification, or UV blacklight.

export type Anomaly = {
	id: string,
	tell: string,
	horrorType: "visual_face"
		| "visual_body"
		| "document"
		| "behavior"
		| "audio"
		| "uv_tool"
		| "phone_tool",
	tier: number,
	roomMismatch: boolean?,
	uvRevealed: boolean?,
	phoneWhisper: string?,
}

export type Guest = {
	name: string,
	reservation: string,
	anomaly: Anomaly?, -- nil = genuine living human
	checkInDate: string,
	checkOutDate: string,
	idName: string,
	roomNumber: number,
	cityOrigin: string,
	uvSymbol: string?,
	isRoomOccupied: boolean,
}

local Anomalies = {}

Anomalies.list = {
	-- =========================================================================
	-- TIER 1: ADMINISTRATIVE & DOCUMENT DISCREPANCIES (12)
	-- =========================================================================
	{
		id = "name_mismatch",
		tell = "The name on their ID card does not match the reservation registry.",
		horrorType = "document",
		tier = 1,
	},
	{
		id = "wrong_checkout",
		tell = "Their checkout date on the register is dated October 1974.",
		horrorType = "document",
		tier = 1,
	},
	{
		id = "reversed_dates",
		tell = "Their checkout date is earlier than their check-in date.",
		horrorType = "document",
		tier = 1,
	},
	{
		id = "invalid_room_109",
		tell = "They are claiming reservation for Room 109, but the motel only has Rooms 101–108.",
		horrorType = "document",
		tier = 1,
	},
	{
		id = "fake_reservation_code",
		tell = "Their reservation number is an invalid code '#0000'.",
		horrorType = "document",
		tier = 1,
	},
	{
		id = "expired_license",
		tell = "Their driver's license expired in 1989.",
		horrorType = "document",
		tier = 1,
	},
	{
		id = "impossible_zip",
		tell = "Their home address postal code is listed as '00000'.",
		horrorType = "document",
		tier = 1,
	},
	{
		id = "forged_signature",
		tell = "Their guest signature is written as '666-666'.",
		horrorType = "document",
		tier = 1,
	},
	{
		id = "redacted_id",
		tell = "The photo on their identification card is completely blacked out.",
		horrorType = "document",
		tier = 1,
	},
	{
		id = "wrong_city",
		tell = "Their city of origin is listed as 'Abyss Void, Nowhere'.",
		horrorType = "document",
		tier = 1,
	},
	{
		id = "negative_stay",
		tell = "Their scheduled length of stay is listed as -3 nights.",
		horrorType = "document",
		tier = 1,
	},
	{
		id = "counterfeit_watermark",
		tell = "The motel emblem watermark on their document is upside down.",
		horrorType = "document",
		tier = 1,
	},

	-- =========================================================================
	-- TIER 2: MICRO-PHYSIOLOGICAL & UNCANNY TELLS (10)
	-- =========================================================================
	{
		id = "too_still",
		tell = "They stand completely motionless like a wax mannequin—zero breathing or blinking.",
		horrorType = "behavior",
		tier = 2,
	},
	{
		id = "no_blinking",
		tell = "Their eyes remain wide open and never blink a single time.",
		horrorType = "behavior",
		tier = 2,
	},
	{
		id = "dilated_pupils",
		tell = "Their pupils are abnormally dilated, completely swallowing their irises in pitch blackness.",
		horrorType = "visual_face",
		tier = 2,
	},
	{
		id = "asymmetric_face",
		tell = "Their left eye is unnaturally sagging much lower than their right eye.",
		horrorType = "visual_face",
		tier = 2,
	},
	{
		id = "no_reflection",
		tell = "Their physical body is translucent and casts no solid shadow on the counter.",
		horrorType = "visual_body",
		tier = 2,
	},
	{
		id = "backward_tie",
		tell = "Their necktie is pinned backwards to the back of their collar.",
		horrorType = "visual_body",
		tier = 2,
	},
	{
		id = "colorless_skin",
		tell = "Their skin is stark chalk-white with no visible blood circulation.",
		horrorType = "visual_body",
		tier = 2,
	},
	{
		id = "cold_fog",
		tell = "Freezing vapor breath puffs from their mouth in the heated reception room.",
		horrorType = "visual_face",
		tier = 2,
	},
	{
		id = "finger_twitch",
		tell = "Their hands periodically undergo rapid, unnatural muscular spasms.",
		horrorType = "behavior",
		tier = 2,
	},
	{
		id = "inverted_pulse",
		tell = "An unnatural rhythmic throbbing is visible in their neck arteries.",
		horrorType = "visual_body",
		tier = 2,
	},

	-- =========================================================================
	-- TIER 3: OVERT & ANALOG HORROR ENTITIES (10)
	-- =========================================================================
	{
		id = "frozen_smile",
		tell = "Their mouth is stretched into an unhinged, ear-to-ear rigid grin with visible rows of teeth.",
		horrorType = "visual_face",
		tier = 3,
	},
	{
		id = "hollow_eyes",
		tell = "Their eyes are pitch-black empty sockets weeping dark residue with glowing crimson pupils.",
		horrorType = "visual_face",
		tier = 3,
	},
	{
		id = "faceless",
		tell = "Their face is a completely featureless, smooth skin mask with no eyes, nose, or mouth.",
		horrorType = "visual_face",
		tier = 3,
	},
	{
		id = "snapped_neck",
		tell = "Their neck is broken at a sharp 90-degree angle, violently twitching and clicking.",
		horrorType = "visual_body",
		tier = 3,
	},
	{
		id = "shadow_entity",
		tell = "Their entire body is a pitch-black void silhouette that absorbs the reception light.",
		horrorType = "visual_body",
		tier = 3,
	},
	{
		id = "too_tall",
		tell = "They are unnaturally tall and elongated, hunched menacingly beneath the ceiling spotlight.",
		horrorType = "visual_body",
		tier = 3,
	},
	{
		id = "drowned_corpse",
		tell = "Their skin is decaying blue-gray, dripping wet puddle footprints across the lobby runner.",
		horrorType = "visual_body",
		tier = 3,
	},
	{
		id = "whispering_throat",
		tell = "Distorted analog radio static and faint reversed whispers emit from their throat.",
		horrorType = "audio",
		tier = 3,
	},
	{
		id = "weeping_blood",
		tell = "Dark crimson fluid slowly drips down their forehead and cheeks.",
		horrorType = "visual_face",
		tier = 3,
	},
	{
		id = "porcelain_cracks",
		tell = "Deep black fissures run across their facial skin like shattered porcelain.",
		horrorType = "visual_face",
		tier = 3,
	},

	-- =========================================================================
	-- TIER 4: TOOL-DETECTED & ENVIRONMENTAL INFILTRATORS (10)
	-- =========================================================================
	{
		id = "uv_occult_rune",
		tell = "Under UV blacklight, a glowing crimson occult symbol is burned onto their forehead.",
		horrorType = "uv_tool",
		tier = 4,
		uvRevealed = true,
	},
	{
		id = "uv_bloodied_hands",
		tell = "Under UV blacklight, luminescent blood stains are splattered across their hands and ID.",
		horrorType = "uv_tool",
		tier = 4,
		uvRevealed = true,
	},
	{
		id = "uv_counterfeit_seal",
		tell = "Under UV blacklight, their ID reveals a glowing biohazard warning rather than a motel crest.",
		horrorType = "uv_tool",
		tier = 4,
		uvRevealed = true,
	},
	{
		id = "phone_occupied_room",
		tell = "Calling their assigned room connects to a sleeping resident who whispers someone is already in bed.",
		horrorType = "phone_tool",
		tier = 4,
		roomMismatch = true,
		phoneWhisper = "Who is at the front desk...? I'm already in this room...",
	},
	{
		id = "phone_static_screamer",
		tell = "Calling their assigned room emits a distorted high-pitched analog scream over the receiver.",
		horrorType = "phone_tool",
		tier = 4,
		roomMismatch = true,
		phoneWhisper = "[LOUD DISTORTED STATIC SCREAM]",
	},
	{
		id = "phone_whisper_echo",
		tell = "Calling their room connects to a voice repeating whatever words you speak in reverse.",
		horrorType = "phone_tool",
		tier = 4,
		roomMismatch = true,
		phoneWhisper = "...kced... eht... ta... si... ohw...",
	},
	{
		id = "flickering_presence",
		tell = "The reception ceiling light buzzes aggressively and micro-flickers whenever they are near.",
		horrorType = "visual_face",
		tier = 4,
	},
	{
		id = "melting_wax",
		tell = "Their facial features appear to slowly warp and droop under the warmth of the desk lamp.",
		horrorType = "visual_face",
		tier = 4,
	},
	{
		id = "glitch_silhouette",
		tell = "Their physical frame sporadically shifts with analog VHS horizontal tear lines.",
		horrorType = "visual_body",
		tier = 4,
	},
	{
		id = "whispering_vents",
		tell = "Subconscious whispers reverberate from the motel ventilation duct behind them.",
		horrorType = "audio",
		tier = 4,
	},
} :: { Anomaly }

local FIRST = {
	"Halden",
	"Moss",
	"Vero",
	"Quinn",
	"Adler",
	"Pike",
	"Renn",
	"Cobb",
	"Silas",
	"Elias",
	"Martha",
	"June",
	"Arthur",
	"Vincent",
	"Clara",
	"Eleanor",
	"Julian",
	"Roland",
	"Beatrice",
	"Lawrence",
}

local LAST = {
	"Vance",
	"Ruell",
	"Marsh",
	"Okonkwo",
	"Sabet",
	"Delacroix",
	"Hoyt",
	"Kessler",
	"Graves",
	"Lowell",
	"Blackwood",
	"Holloway",
	"Thorne",
	"Sinclair",
	"Cross",
	"Sterling",
}

local CITIES = {
	"Portland, OR",
	"Spokane, WA",
	"Boise, ID",
	"Helena, MT",
	"Reno, NV",
	"Salt Lake City, UT",
	"Sacramento, CA",
	"Eugene, OR",
}

-- Balanced anomaly spawn chance (45%)
local ANOMALY_CHANCE = 0.45

function Anomalies.roll(rng: Random): Guest
	local name = `{FIRST[rng:NextInteger(1, #FIRST)]} {LAST[rng:NextInteger(1, #LAST)]}`
	local reservation = string.format("%04d", rng:NextInteger(1000, 9999))
	local roomNum = rng:NextInteger(101, 108)
	local city = CITIES[rng:NextInteger(1, #CITIES)]

	local anomaly: Anomaly? = nil
	if rng:NextNumber() < ANOMALY_CHANCE then
		anomaly = Anomalies.list[rng:NextInteger(1, #Anomalies.list)]
	end

	local idName = name
	local checkIn = "Oct 24, 2026"
	local checkOut = "Oct 25, 2026"
	local isOccupied = false
	local uvSymbol: string? = nil

	if anomaly then
		if anomaly.id == "name_mismatch" then
			idName = `{FIRST[rng:NextInteger(1, #FIRST)]} {LAST[rng:NextInteger(1, #LAST)]}`
			while idName == name do
				idName = `{FIRST[rng:NextInteger(1, #FIRST)]} Miller`
			end
		elseif anomaly.id == "wrong_checkout" then
			checkOut = "Oct 24, 1974"
		elseif anomaly.id == "reversed_dates" then
			checkIn = "Oct 26, 2026"
			checkOut = "Oct 23, 2026"
		elseif anomaly.id == "invalid_room_109" then
			roomNum = 109
		elseif anomaly.id == "fake_reservation_code" then
			reservation = "0000"
		elseif anomaly.id == "expired_license" then
			checkOut = "Oct 25, 1989"
		elseif anomaly.id == "wrong_city" then
			city = "Abyss Void, Nowhere"
		elseif anomaly.id == "uv_occult_rune" then
			uvSymbol = "OCCULT_RUNE"
		elseif anomaly.id == "uv_bloodied_hands" then
			uvSymbol = "BLOOD_SPLATTER"
		elseif anomaly.id == "uv_counterfeit_seal" then
			uvSymbol = "BIOHAZARD_SEAL"
		elseif anomaly.roomMismatch then
			isOccupied = true
		end
	end

	return {
		name = name,
		reservation = reservation,
		anomaly = anomaly,
		checkInDate = checkIn,
		checkOutDate = checkOut,
		idName = idName,
		roomNumber = roomNum,
		cityOrigin = city,
		uvSymbol = uvSymbol,
		isRoomOccupied = isOccupied,
	}
end

return Anomalies
