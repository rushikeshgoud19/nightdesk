--!strict
-- The master anomaly catalog for the Highway Motel.
-- Launch target: 42 distinct observable tells across 4 escalation tiers.
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
	-- TIER 1: SUBTLE ANOMALIES (60%)
	-- =========================================================================
	{
		id = "forged_signature",
		tell = "Their guest signature is written slightly too perfectly, like a printed font.",
		horrorType = "document",
		tier = 1,
	},
	{
		id = "redacted_id",
		tell = "The photo on their identification card has a very faint distortion over the eyes.",
		horrorType = "document",
		tier = 1,
	},
	{
		id = "counterfeit_watermark",
		tell = "The motel emblem watermark on their document is missing its left star.",
		horrorType = "document",
		tier = 1,
	},
	{
		id = "too_still",
		tell = "They stand completely rigid while idle and never subtly shift their weight between legs.",
		horrorType = "behavior",
		tier = 1,
	},
	{
		id = "no_blinking",
		tell = "They blink once every 14 seconds instead of a natural human 4-second rate.",
		horrorType = "behavior",
		tier = 1,
	},
	{
		id = "dilated_pupils",
		tell = "Their pupils are dilated exactly 15% wider than normal for this lighting.",
		horrorType = "visual_face",
		tier = 1,
	},
	{
		id = "asymmetric_face",
		tell = "Their left eye sits exactly 3 millimeters lower than their right eye.",
		horrorType = "visual_face",
		tier = 1,
	},
	{
		id = "colorless_skin",
		tell = "Their skin tone is desaturated by exactly 4% compared to natural lighting.",
		horrorType = "visual_body",
		tier = 1,
	},
	{
		id = "cold_fog",
		tell = "A very faint wisp of vapor escapes their mouth when they speak.",
		horrorType = "visual_face",
		tier = 1,
	},
	{
		id = "finger_twitch",
		tell = "Their fingers never curl or relax, staying perfectly straight.",
		horrorType = "behavior",
		tier = 1,
	},
	{
		id = "inverted_pulse",
		tell = "The pulse visible in their neck artery beats in a syncopated, unnatural rhythm.",
		horrorType = "visual_body",
		tier = 1,
	},
	{
		id = "subtle_smile",
		tell = "Their lips are curled into a very faint, unnatural half-smile that never wavers.",
		horrorType = "visual_face",
		tier = 1,
	},
	{
		id = "dark_sclera",
		tell = "The whites of their eyes are exactly 10% darker than natural.",
		horrorType = "visual_face",
		tier = 1,
	},
	{
		id = "perfect_symmetry",
		tell = "Their facial geometry is perfectly, mathematically symmetrical—real faces are not.",
		horrorType = "visual_face",
		tier = 1,
	},
	{
		id = "wrong_distance",
		tell = "They stand exactly 3 studs back from the counter instead of 2.",
		horrorType = "behavior",
		tier = 1,
	},
	{
		id = "late_tracking",
		tell = "Their head tracks your movements with exactly a half-second delay.",
		horrorType = "behavior",
		tier = 1,
	},
	{
		id = "button_wrong",
		tell = "The middle button of their suit jacket is fastened to the wrong buttonhole.",
		horrorType = "visual_body",
		tier = 1,
	},
	{
		id = "wrong_cufflink",
		tell = "Their left and right shirt cuff buttons are mismatched materials (gold and silver).",
		horrorType = "visual_body",
		tier = 1,
	},
	{
		id = "uv_occult_rune",
		tell = "Under UV blacklight, a very faint fingerprint is visible on their forehead.",
		horrorType = "uv_tool",
		tier = 1,
		uvRevealed = true,
	},
	{
		id = "uv_bloodied_hands",
		tell = "Under UV blacklight, a small smudged ink stain glows on their thumb.",
		horrorType = "uv_tool",
		tier = 1,
		uvRevealed = true,
	},
	{
		id = "uv_counterfeit_seal",
		tell = "Under UV blacklight, the motel seal on their ID is printed 2 degrees off-center.",
		horrorType = "uv_tool",
		tier = 1,
		uvRevealed = true,
	},
	{
		id = "flickering_presence",
		tell = "The reception ceiling light dims by just 5% whenever they lean in.",
		horrorType = "visual_face",
		tier = 1,
	},
	{
		id = "melting_wax",
		tell = "The tip of their nose appears to have a very faint, unnatural drooping sheen.",
		horrorType = "visual_face",
		tier = 1,
	},
	{
		id = "glitch_silhouette",
		tell = "Every 30 seconds, a single horizontal static tear line flashes across their suit.",
		horrorType = "visual_body",
		tier = 1,
	},
	{
		id = "whispering_vents",
		tell = "The ventilation duct hums at a slightly lower frequency when they are present.",
		horrorType = "audio",
		tier = 1,
	},

	-- =========================================================================
	-- TIER 2: NOTICEABLE ANOMALIES (30%)
	-- =========================================================================
	{
		id = "name_mismatch",
		tell = "The middle initial on their ID card does not match the reservation registry.",
		horrorType = "document",
		tier = 2,
	},
	{
		id = "wrong_checkout",
		tell = "Their checkout date on the register is dated October 1974.",
		horrorType = "document",
		tier = 2,
	},
	{
		id = "reversed_dates",
		tell = "Their checkout date is earlier than their check-in date.",
		horrorType = "document",
		tier = 2,
	},
	{
		id = "invalid_room_109",
		tell = "They are claiming reservation for Room 109, but the motel only has Rooms 101–108.",
		horrorType = "document",
		tier = 2,
	},
	{
		id = "fake_reservation_code",
		tell = "Their reservation number is an invalid code '#0000'.",
		horrorType = "document",
		tier = 2,
	},
	{
		id = "expired_license",
		tell = "Their driver's license expired in 1989.",
		horrorType = "document",
		tier = 2,
	},
	{
		id = "impossible_zip",
		tell = "Their home address postal code is listed as '00000'.",
		horrorType = "document",
		tier = 2,
	},
	{
		id = "wrong_city",
		tell = "Their city of origin is listed as 'Abyss Void, Nowhere'.",
		horrorType = "document",
		tier = 2,
	},
	{
		id = "negative_stay",
		tell = "Their scheduled length of stay is listed as -3 nights.",
		horrorType = "document",
		tier = 2,
	},
	{
		id = "no_reflection",
		tell = "Their physical body casts no solid shadow on the counter.",
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
		id = "wet_footprints",
		tell = "They left faint wet footprints on the lobby runner, despite no rain outside.",
		horrorType = "visual_body",
		tier = 2,
	},
	{
		id = "phone_occupied_room",
		tell = "Calling their assigned room connects to a sleeping resident who whispers someone is already in bed.",
		horrorType = "phone_tool",
		tier = 2,
		roomMismatch = true,
		phoneWhisper = "Who is at the front desk...? I'm already in this room...",
	},
	{
		id = "phone_whisper_echo",
		tell = "Calling their room connects, but you hear a half-second echo of your own breathing.",
		horrorType = "phone_tool",
		tier = 2,
		roomMismatch = true,
		phoneWhisper = "...kced... eht... ta... si... ohw...",
	},

	-- =========================================================================
	-- TIER 3: OVERT ANOMALIES (10%)
	-- =========================================================================
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
		id = "phone_static_screamer",
		tell = "Calling their assigned room emits a distorted high-pitched analog scream over the receiver.",
		horrorType = "phone_tool",
		tier = 3,
		roomMismatch = true,
		phoneWhisper = "[LOUD DISTORTED STATIC SCREAM]",
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
			idName = `{FIRST[rng:NextInteger(1, #FIRST)]} M. {LAST[rng:NextInteger(1, #LAST)]}`
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
