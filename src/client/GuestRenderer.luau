--!strict
-- 3D High-Fidelity Guest Renderer & Cinematic Horror Mob Architecture for nightdesk
-- Constructs authentic R15 Humanoid Guests with sculpted anatomical facial contours,
-- tailored executive overcoats, 3D collared shirts, tapered neckties, articulated hands/fingers,
-- executive briefcases, natural breathing physics, eye blinking, gaze micro-saccades,
-- and the 6 Core Cinematic Horror Mob Archetypes.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))

local Atmosphere = require(script.Parent:WaitForChild("Atmosphere"))

export type GuestData = {
	name: string,
	reservation: string?,
	anomalyId: string?,
	horrorType: string?,
	roomNumber: number?,
	cityOrigin: string?,
	uvSymbol: string?,
	isRoomOccupied: boolean?,
	checkInDate: string?,
	checkOutDate: string?,
	idName: string?,
	tell: string?,
	sanity: number?,
	takings: number?,
	guestsLeft: number?,
	nightNumber: number?,
}

type LimbGroup =
	"Head"
	| "UpperTorso"
	| "LowerTorso"
	| "LeftArm"
	| "RightArm"
	| "LeftLeg"
	| "RightLeg"
	| "Root"

type PartInfo = {
	part: BasePart,
	group: LimbGroup,
	baseCF: CFrame,
	origTransparency: number,
}

type AnimState = {
	legAngleL: number,
	legAngleR: number,
	armAngleL: number,
	armAngleR: number,
	armRollL: number,
	armRollR: number,
	torsoLift: number,
	torsoPitch: number,
	torsoYaw: number,
	torsoRoll: number,
	hipBob: number,
	hipYaw: number,
	headPitch: number,
	headYaw: number,
	headRoll: number,
	headSnapCF: CFrame,
}

local GuestRenderer = {}

-- Key lobby waypoints
local SPAWN_POS = Vector3.new(0, 4.80, -14.00) -- Front entrance glass doors
local DESK_POS = Vector3.new(0, 4.80, 1.80) -- In front of reception counter
local EXIT_DOOR = Vector3.new(0, 4.80, -16.00) -- Front exit into the rain
local HALLWAY_POS = Vector3.new(-16.00, 4.80, 4.00) -- Corridor to rooms 101-108

-- Sophisticated formal tailored palettes
local SUIT_PALETTES = {
	Color3.fromRGB(42, 45, 52), -- Charcoal Executive
	Color3.fromRGB(24, 32, 48), -- Deep Midnight Navy
	Color3.fromRGB(64, 24, 32), -- Deep Burgundy Velvet
	Color3.fromRGB(22, 22, 26), -- Pitch Black Formal Tuxedo
	Color3.fromRGB(50, 54, 60), -- Slate Gray Worsted
	Color3.fromRGB(34, 42, 36), -- Forest Tweed Olive
	Color3.fromRGB(86, 72, 58), -- Camel Khaki Trench
}

local SHIRT_PALETTES = {
	Color3.fromRGB(248, 248, 252), -- Crisp Pure White
	Color3.fromRGB(215, 230, 245), -- Pale Oxford Blue
	Color3.fromRGB(245, 240, 228), -- Ivory Linen
	Color3.fromRGB(224, 226, 230), -- Light Silver Grey
}

local TIE_PALETTES = {
	Color3.fromRGB(155, 28, 34), -- Crimson Silk
	Color3.fromRGB(185, 140, 45), -- Ochre Gold
	Color3.fromRGB(26, 48, 98), -- Royal Navy
	Color3.fromRGB(28, 78, 48), -- Deep Emerald
	Color3.fromRGB(38, 40, 46), -- Dark Charcoal Stripe
	Color3.fromRGB(98, 38, 88), -- Amethyst Silk
}

local PANTS_PALETTES = {
	Color3.fromRGB(24, 26, 30),
	Color3.fromRGB(32, 30, 28),
	Color3.fromRGB(26, 30, 36),
	Color3.fromRGB(18, 18, 22),
}

local SKIN_TONES = {
	Color3.fromRGB(252, 230, 212), -- Fair Porcelain
	Color3.fromRGB(240, 210, 180), -- Light Peach
	Color3.fromRGB(220, 175, 135), -- Warm Honey
	Color3.fromRGB(180, 130, 92), -- Olive Bronze
	Color3.fromRGB(130, 85, 55), -- Rich Chestnut
	Color3.fromRGB(80, 50, 35), -- Deep Espresso
}

local IRIS_PALETTES = {
	Color3.fromRGB(58, 40, 30), -- Dark Brown
	Color3.fromRGB(48, 72, 105), -- Slate Blue
	Color3.fromRGB(115, 82, 42), -- Hazel Amber
	Color3.fromRGB(42, 78, 52), -- Forest Green
	Color3.fromRGB(90, 95, 102), -- Steel Gray
}

local HAIR_ASSETS = {
	"16630147", -- Ultra-Fabulous Hair
	"26867012", -- Classic Brown Charmer
	"13070796", -- Styled Sidepart
	"24996529", -- Executive Hair
	"439989001", -- Slicked Back Hair
}

local HAIR_COLORS = {
	Color3.fromRGB(22, 20, 20), -- Jet Black
	Color3.fromRGB(54, 38, 28), -- Dark Brown
	Color3.fromRGB(78, 52, 36), -- Espresso
	Color3.fromRGB(115, 78, 50), -- Chestnut
	Color3.fromRGB(175, 140, 95), -- Sandy Blonde
	Color3.fromRGB(135, 135, 140), -- Salt & Pepper
}

-- Module State
local currentGuestModel: Model?
local isCurrentAnomaly = false
local currentPartInfos: { PartInfo } = {}
local activeEyelids: { BasePart } = {}
local activeUvParts: { BasePart } = {}
local activeUvLights: { PointLight } = {}

local activeWalkConnection: RBXScriptConnection?
local activeIdleConnection: RBXScriptConnection?
local uvStateConnection: RBXScriptConnection?
local blinkThread: thread?
local footprints: { BasePart } = {}

local function makePart(
	name: string,
	shape: Enum.PartType,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	material: Enum.Material,
	transparency: number,
	parent: Instance
): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Shape = shape
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material
	p.Transparency = transparency
	p.Anchored = true
	p.CanCollide = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function spawnFootprint(pos: Vector3)
	local p = Instance.new("Part")
	p.Name = "WetFootprint"
	p.Shape = Enum.PartType.Block
	p.Size = Vector3.new(0.48, 0.02, 0.85)
	p.CFrame = CFrame.new(pos.X, 0.53, pos.Z)
		* CFrame.Angles(0, math.rad(Random.new():NextNumber(-14, 14)), 0)
	p.Color = Color3.fromRGB(12, 10, 14)
	p.Material = Enum.Material.SmoothPlastic
	p.Transparency = 0.20
	p.Anchored = true
	p.CanCollide = false
	p.Parent = Workspace
	table.insert(footprints, p)

	task.delay(10, function()
		if p and p.Parent then
			local tw = TweenService:Create(p, TweenInfo.new(3.0), { Transparency = 1.0 })
			tw:Play()
			tw.Completed:Connect(function()
				p:Destroy()
			end)
		end
	end)
end

local function classifyLimbGroup(name: string): LimbGroup
	if
		name:find("LeftUpperLeg")
		or name:find("LeftLowerLeg")
		or name:find("LeftFoot")
		or name:find("LeftShoe")
		or name:find("LeftPant")
		or name:find("LeftSole")
		or name:find("LeftHeel")
		or name:find("Shoe_L")
		or name:find("ShoeSole_L")
		or name:find("ShoeHeel_L")
		or name:find("PantCuff_L")
	then
		return "LeftLeg"
	elseif
		name:find("RightUpperLeg")
		or name:find("RightLowerLeg")
		or name:find("RightFoot")
		or name:find("RightShoe")
		or name:find("RightPant")
		or name:find("RightSole")
		or name:find("RightHeel")
		or name:find("Shoe_R")
		or name:find("ShoeSole_R")
		or name:find("ShoeHeel_R")
		or name:find("PantCuff_R")
	then
		return "RightLeg"
	elseif
		name:find("LeftUpperArm")
		or name:find("LeftLowerArm")
		or name:find("LeftHand")
		or name:find("LeftCuff")
		or name:find("LeftSleeve")
		or name:find("Palm_L")
		or name:find("ThumbProximal_L")
		or name:find("ThumbDistal_L")
		or name:find("ThumbKnuckle_L")
		or name:find("IndexProximal_L")
		or name:find("IndexDistal_L")
		or name:find("IndexKnuckle_L")
		or name:find("MiddleProximal_L")
		or name:find("MiddleDistal_L")
		or name:find("MiddleKnuckle_L")
		or name:find("RingProximal_L")
		or name:find("RingDistal_L")
		or name:find("RingKnuckle_L")
		or name:find("PinkyProximal_L")
		or name:find("PinkyDistal_L")
		or name:find("PinkyKnuckle_L")
		or name:find("ShirtCuff_L")
		or name:find("CuffButton_L")
	then
		return "LeftArm"
	elseif
		name:find("RightUpperArm")
		or name:find("RightLowerArm")
		or name:find("RightHand")
		or name:find("RightCuff")
		or name:find("RightSleeve")
		or name:find("Palm_R")
		or name:find("ThumbProximal_R")
		or name:find("ThumbDistal_R")
		or name:find("ThumbKnuckle_R")
		or name:find("IndexProximal_R")
		or name:find("IndexDistal_R")
		or name:find("IndexKnuckle_R")
		or name:find("MiddleProximal_R")
		or name:find("MiddleDistal_R")
		or name:find("MiddleKnuckle_R")
		or name:find("RingProximal_R")
		or name:find("RingDistal_R")
		or name:find("RingKnuckle_R")
		or name:find("PinkyProximal_R")
		or name:find("PinkyDistal_R")
		or name:find("PinkyKnuckle_R")
		or name:find("ShirtCuff_R")
		or name:find("CuffButton_R")
		or name:find("Briefcase")
		or name:find("BloodiedHandsUV")
	then
		return "RightArm"
	elseif
		name:find("Head")
		or name:find("Hair")
		or name:find("Face")
		or name:find("Cheekbone")
		or name:find("Jaw")
		or name:find("Chin")
		or name:find("Nose")
		or name:find("Nostril")
		or name:find("Ear")
		or name:find("Brow")
		or name:find("Sclera")
		or name:find("Iris")
		or name:find("Pupil")
		or name:find("Eyelid")
		or name:find("Lip")
		or name:find("Philtrum")
		or name:find("Mouth")
		or name:find("Teeth")
		or name:find("Tooth")
		or name:find("RazorTooth")
		or name:find("Socket")
		or name:find("Ember")
		or name:find("Tear")
		or name:find("Blood")
		or name:find("Vertebra")
		or name:find("TornMuscle")
		or name:find("Tissue")
		or name:find("Spinal")
		or name:find("Rune")
		or name:find("OccultRune")
		or name:find("Crack")
		or name:find("Fog")
		or name:find("Spiral")
		or name:find("Stitch")
		or name:find("NeckCross")
		or name:find("Ligament")
		or name:find("Dilated")
		or name:find("Asymm")
	then
		return "Head"
	elseif
		name:find("UpperTorso")
		or name:find("Shirt")
		or name:find("Collar")
		or name:find("Tie")
		or name:find("Lapel")
		or name:find("Button")
		or name:find("Pocket")
		or name:find("Artery")
		or name:find("Jacket")
		or name:find("Overcoat")
		or name:find("Seaweed")
		or name:find("WaterDrip")
	then
		return "UpperTorso"
	elseif
		name:find("LowerTorso")
		or name:find("Belt")
		or name:find("Buckle")
		or name:find("CoatTail")
		or name:find("JacketHem")
	then
		return "LowerTorso"
	end
	return "Root"
end

local function getGroupTransform(
	group: LimbGroup,
	state: AnimState,
	scaleW: number,
	scaleH: number
): CFrame
	local leftHipPivot = Vector3.new(-0.48 * scaleW, -0.38 * scaleH, 0)
	local rightHipPivot = Vector3.new(0.48 * scaleW, -0.38 * scaleH, 0)
	local leftShoulderPivot = Vector3.new(-1.05 * scaleW, 0.72 * scaleH, 0)
	local rightShoulderPivot = Vector3.new(1.05 * scaleW, 0.72 * scaleH, 0)
	local waistPivot = Vector3.new(0, -0.10 * scaleH, 0)
	local neckPivot = Vector3.new(0, 0.82 * scaleH, 0)

	if group == "LeftLeg" then
		return CFrame.new(leftHipPivot)
			* CFrame.Angles(state.legAngleL, 0, 0)
			* CFrame.new(-leftHipPivot)
	elseif group == "RightLeg" then
		return CFrame.new(rightHipPivot)
			* CFrame.Angles(state.legAngleR, 0, 0)
			* CFrame.new(-rightHipPivot)
	elseif group == "LeftArm" then
		return CFrame.new(leftShoulderPivot)
			* CFrame.Angles(state.armAngleL, 0, state.armRollL)
			* CFrame.new(-leftShoulderPivot)
	elseif group == "RightArm" then
		return CFrame.new(rightShoulderPivot)
			* CFrame.Angles(state.armAngleR, 0, state.armRollR)
			* CFrame.new(-rightShoulderPivot)
	elseif group == "UpperTorso" then
		return CFrame.new(0, state.torsoLift, 0)
			* CFrame.new(waistPivot)
			* CFrame.Angles(state.torsoPitch, state.torsoYaw, state.torsoRoll)
			* CFrame.new(-waistPivot)
	elseif group == "Head" then
		local torsoCF = CFrame.new(0, state.torsoLift, 0)
			* CFrame.new(waistPivot)
			* CFrame.Angles(state.torsoPitch, state.torsoYaw, state.torsoRoll)
			* CFrame.new(-waistPivot)
		local headCF = CFrame.new(neckPivot)
			* CFrame.Angles(state.headPitch, state.headYaw, state.headRoll)
			* state.headSnapCF
			* CFrame.new(-neckPivot)
		return torsoCF * headCF
	elseif group == "LowerTorso" then
		return CFrame.new(0, state.hipBob, 0) * CFrame.Angles(0, state.hipYaw, 0)
	end

	return CFrame.identity
end

local function applyPose(hrp: BasePart, state: AnimState, scaleW: number, scaleH: number)
	for _, info in ipairs(currentPartInfos) do
		if info.part.Parent and info.part ~= hrp then
			local groupTransform = getGroupTransform(info.group, state, scaleW, scaleH)
			info.part.CFrame = hrp.CFrame * groupTransform * info.baseCF
		end
	end
end

-- =============================================================================
-- PROCEDURAL SCULPTING ARCHITECTURE
-- =============================================================================

local function buildAnatomicalFacialContours(
	head: BasePart,
	skinColor: Color3,
	eyeColor: Color3,
	scaleW: number,
	scaleH: number,
	scaleD: number,
	transparency: number,
	anomalyId: string?,
	model: Model
)
	if anomalyId == "shadow_entity" then
		return
	end
	if anomalyId == "dark_sclera" then
		eyeColor = Color3.fromRGB(30, 30, 30)
	end

	local isDilatedPupils = anomalyId == "dilated_pupils"
	local isAsymmetricFace = anomalyId == "asymmetric_face"
	local isSubtleSmile = anomalyId == "subtle_smile"
	local isMeltingWax = anomalyId == "melting_wax"
	local asymX = (anomalyId == "perfect_symmetry") and 0 or (math.random(-2, 2) * 0.008)
	local asymY = (anomalyId == "perfect_symmetry") and 0 or (math.random(-2, 2) * 0.008)

	makePart(
		"Cheekbone_L",
		Enum.PartType.Block,
		Vector3.new(0.20 * scaleW, 0.14 * scaleH, 0.08 * scaleD),
		head.CFrame
			* CFrame.new(-0.35 * scaleW, 0.05 * scaleH, 0.50 * scaleD)
			* CFrame.Angles(0, math.rad(14), math.rad(-10)),
		skinColor,
		Enum.Material.SmoothPlastic,
		transparency,
		model
	)
	makePart(
		"Cheekbone_R",
		Enum.PartType.Block,
		Vector3.new(0.20 * scaleW, 0.14 * scaleH, 0.08 * scaleD),
		head.CFrame
			* CFrame.new((0.35 + asymX) * scaleW, (0.05 + asymY) * scaleH, 0.50 * scaleD)
			* CFrame.Angles(0, math.rad(-14), math.rad(10)),
		skinColor,
		Enum.Material.SmoothPlastic,
		transparency,
		model
	)

	makePart(
		"Jaw_L",
		Enum.PartType.Block,
		Vector3.new(0.18 * scaleW, 0.26 * scaleH, 0.10 * scaleD),
		head.CFrame
			* CFrame.new(-0.30 * scaleW, -0.32 * scaleH, 0.44 * scaleD)
			* CFrame.Angles(0, math.rad(22), math.rad(-18)),
		skinColor,
		Enum.Material.SmoothPlastic,
		transparency,
		model
	)
	makePart(
		"Jaw_R",
		Enum.PartType.Block,
		Vector3.new(0.18 * scaleW, 0.26 * scaleH, 0.10 * scaleD),
		head.CFrame
			* CFrame.new((0.30 + asymX) * scaleW, (-0.32 + asymY) * scaleH, 0.44 * scaleD)
			* CFrame.Angles(0, math.rad(-22), math.rad(18)),
		skinColor,
		Enum.Material.SmoothPlastic,
		transparency,
		model
	)
	makePart(
		"ChinPlate",
		Enum.PartType.Block,
		Vector3.new(0.28 * scaleW, 0.16 * scaleH, 0.12 * scaleD),
		head.CFrame * CFrame.new(0, -0.42 * scaleH, 0.48 * scaleD),
		skinColor,
		Enum.Material.SmoothPlastic,
		transparency,
		model
	)

	local noseMat = isMeltingWax and Enum.Material.Ice or Enum.Material.SmoothPlastic
	makePart(
		"NoseBridge",
		Enum.PartType.Block,
		Vector3.new(0.08 * scaleW, 0.26 * scaleH, 0.10 * scaleD),
		head.CFrame * CFrame.new(0, 0.12 * scaleH, 0.55 * scaleD),
		skinColor,
		noseMat,
		transparency,
		model
	)
	makePart(
		"NoseTip",
		Enum.PartType.Block,
		Vector3.new(0.13 * scaleW, 0.10 * scaleH, 0.12 * scaleD),
		head.CFrame * CFrame.new(0, -0.02 * scaleH, 0.60 * scaleD),
		skinColor,
		noseMat,
		transparency,
		model
	)
	makePart(
		"Nostril_L",
		Enum.PartType.Block,
		Vector3.new(0.05 * scaleW, 0.05 * scaleH, 0.06 * scaleD),
		head.CFrame * CFrame.new(-0.08 * scaleW, -0.05 * scaleH, 0.57 * scaleD),
		skinColor,
		noseMat,
		transparency,
		model
	)
	makePart(
		"Nostril_R",
		Enum.PartType.Block,
		Vector3.new(0.05 * scaleW, 0.05 * scaleH, 0.06 * scaleD),
		head.CFrame * CFrame.new(0.08 * scaleW, -0.05 * scaleH, 0.57 * scaleD),
		skinColor,
		noseMat,
		transparency,
		model
	)

	makePart(
		"Ear_L",
		Enum.PartType.Block,
		Vector3.new(0.08 * scaleW, 0.32 * scaleH, 0.18 * scaleD),
		head.CFrame
			* CFrame.new(-0.55 * scaleW, 0.08 * scaleH, -0.02 * scaleD)
			* CFrame.Angles(0, math.rad(-10), 0),
		skinColor,
		Enum.Material.SmoothPlastic,
		transparency,
		model
	)
	makePart(
		"Ear_R",
		Enum.PartType.Block,
		Vector3.new(0.08 * scaleW, 0.32 * scaleH, 0.18 * scaleD),
		head.CFrame
			* CFrame.new((0.55 + asymX) * scaleW, (0.08 + asymY) * scaleH, -0.02 * scaleD)
			* CFrame.Angles(0, math.rad(10), 0),
		skinColor,
		Enum.Material.SmoothPlastic,
		transparency,
		model
	)
	makePart(
		"EarHelix_L",
		Enum.PartType.Block,
		Vector3.new(0.05 * scaleW, 0.16 * scaleH, 0.14 * scaleD),
		head.CFrame * CFrame.new(-0.57 * scaleW, 0.16 * scaleH, -0.02 * scaleD),
		skinColor,
		Enum.Material.SmoothPlastic,
		transparency,
		model
	)
	makePart(
		"EarHelix_R",
		Enum.PartType.Block,
		Vector3.new(0.05 * scaleW, 0.16 * scaleH, 0.14 * scaleD),
		head.CFrame * CFrame.new(0.57 * scaleW, 0.16 * scaleH, -0.02 * scaleD),
		skinColor,
		Enum.Material.SmoothPlastic,
		transparency,
		model
	)
	makePart(
		"EarLobe_L",
		Enum.PartType.Block,
		Vector3.new(0.06 * scaleW, 0.10 * scaleH, 0.10 * scaleD),
		head.CFrame * CFrame.new(-0.56 * scaleW, -0.06 * scaleH, -0.02 * scaleD),
		skinColor,
		Enum.Material.SmoothPlastic,
		transparency,
		model
	)
	makePart(
		"EarLobe_R",
		Enum.PartType.Block,
		Vector3.new(0.06 * scaleW, 0.10 * scaleH, 0.10 * scaleD),
		head.CFrame * CFrame.new(0.56 * scaleW, -0.06 * scaleH, -0.02 * scaleD),
		skinColor,
		Enum.Material.SmoothPlastic,
		transparency,
		model
	)

	makePart(
		"BrowRidge_L",
		Enum.PartType.Block,
		Vector3.new(0.22 * scaleW, 0.05 * scaleH, 0.06 * scaleD),
		head.CFrame
			* CFrame.new(-0.26 * scaleW, 0.28 * scaleH, 0.54 * scaleD)
			* CFrame.Angles(0, 0, math.rad(5)),
		skinColor,
		Enum.Material.SmoothPlastic,
		transparency,
		model
	)
	makePart(
		"BrowRidge_R",
		Enum.PartType.Block,
		Vector3.new(0.22 * scaleW, 0.05 * scaleH, 0.06 * scaleD),
		head.CFrame
			* CFrame.new(0.26 * scaleW, 0.28 * scaleH, 0.54 * scaleD)
			* CFrame.Angles(0, 0, math.rad(-5)),
		skinColor,
		Enum.Material.SmoothPlastic,
		transparency,
		model
	)

	local eyeY_L = isAsymmetricFace and 0.12 or 0.15
	local scleraColor = anomalyId == "dark_sclera" and Color3.fromRGB(150, 150, 150)
		or Color3.fromRGB(246, 246, 250)
	local pupilSize = isDilatedPupils and 0.08 or 0.05

	makePart(
		"Sclera_L",
		Enum.PartType.Block,
		Vector3.new(0.18 * scaleW, 0.11 * scaleH, 0.04 * scaleD),
		head.CFrame * CFrame.new(-0.26 * scaleW, eyeY_L * scaleH, 0.53 * scaleD),
		scleraColor,
		Enum.Material.SmoothPlastic,
		transparency,
		model
	)
	makePart(
		"Iris_L",
		Enum.PartType.Block,
		Vector3.new(0.10 * scaleW, 0.10 * scaleH, 0.03 * scaleD),
		head.CFrame * CFrame.new(-0.26 * scaleW, eyeY_L * scaleH, 0.55 * scaleD),
		eyeColor,
		Enum.Material.SmoothPlastic,
		transparency,
		model
	)
	makePart(
		"Pupil_L",
		Enum.PartType.Block,
		Vector3.new(pupilSize * scaleW, pupilSize * scaleH, 0.03 * scaleD),
		head.CFrame * CFrame.new(-0.26 * scaleW, eyeY_L * scaleH, 0.56 * scaleD),
		Color3.fromRGB(15, 12, 14),
		Enum.Material.SmoothPlastic,
		transparency,
		model
	)

	makePart(
		"Sclera_R",
		Enum.PartType.Block,
		Vector3.new(0.18 * scaleW, 0.11 * scaleH, 0.04 * scaleD),
		head.CFrame * CFrame.new((0.26 + asymX) * scaleW, (0.15 + asymY) * scaleH, 0.53 * scaleD),
		scleraColor,
		Enum.Material.SmoothPlastic,
		transparency,
		model
	)
	makePart(
		"Iris_R",
		Enum.PartType.Block,
		Vector3.new(0.10 * scaleW, 0.10 * scaleH, 0.03 * scaleD),
		head.CFrame * CFrame.new((0.26 + asymX) * scaleW, (0.15 + asymY) * scaleH, 0.55 * scaleD),
		eyeColor,
		Enum.Material.SmoothPlastic,
		transparency,
		model
	)
	makePart(
		"Pupil_R",
		Enum.PartType.Block,
		Vector3.new(pupilSize * scaleW, pupilSize * scaleH, 0.03 * scaleD),
		head.CFrame * CFrame.new((0.26 + asymX) * scaleW, (0.15 + asymY) * scaleH, 0.56 * scaleD),
		Color3.fromRGB(15, 12, 14),
		Enum.Material.SmoothPlastic,
		transparency,
		model
	)

	local lidUpperL = makePart(
		"EyelidUpper_L",
		Enum.PartType.Block,
		Vector3.new(0.20 * scaleW, 0.03 * scaleH, 0.05 * scaleD),
		head.CFrame * CFrame.new(-0.26 * scaleW, (eyeY_L + 0.05) * scaleH, 0.56 * scaleD),
		skinColor,
		Enum.Material.SmoothPlastic,
		transparency,
		model
	)
	local lidUpperR = makePart(
		"EyelidUpper_R",
		Enum.PartType.Block,
		Vector3.new(0.20 * scaleW, 0.03 * scaleH, 0.05 * scaleD),
		head.CFrame * CFrame.new(0.26 * scaleW, 0.20 * scaleH, 0.56 * scaleD),
		skinColor,
		Enum.Material.SmoothPlastic,
		transparency,
		model
	)
	makePart(
		"EyelidLower_L",
		Enum.PartType.Block,
		Vector3.new(0.20 * scaleW, 0.02 * scaleH, 0.05 * scaleD),
		head.CFrame * CFrame.new(-0.26 * scaleW, (eyeY_L - 0.05) * scaleH, 0.56 * scaleD),
		skinColor,
		Enum.Material.SmoothPlastic,
		transparency,
		model
	)
	makePart(
		"EyelidLower_R",
		Enum.PartType.Block,
		Vector3.new(0.20 * scaleW, 0.02 * scaleH, 0.05 * scaleD),
		head.CFrame * CFrame.new(0.26 * scaleW, 0.10 * scaleH, 0.56 * scaleD),
		skinColor,
		Enum.Material.SmoothPlastic,
		transparency,
		model
	)

	table.insert(activeEyelids, lidUpperL)
	table.insert(activeEyelids, lidUpperR)

	makePart(
		"Philtrum",
		Enum.PartType.Block,
		Vector3.new(0.06 * scaleW, 0.08 * scaleH, 0.04 * scaleD),
		head.CFrame * CFrame.new(0, -0.12 * scaleH, 0.55 * scaleD),
		skinColor,
		Enum.Material.SmoothPlastic,
		transparency,
		model
	)
	makePart(
		"LipUpper",
		Enum.PartType.Block,
		Vector3.new(0.26 * scaleW, 0.04 * scaleH, 0.05 * scaleD),
		head.CFrame * CFrame.new(0, -0.18 * scaleH, 0.55 * scaleD),
		Color3.fromRGB(140, 75, 75),
		Enum.Material.SmoothPlastic,
		transparency,
		model
	)
	makePart(
		"LipLower",
		Enum.PartType.Block,
		Vector3.new(0.24 * scaleW, 0.05 * scaleH, 0.05 * scaleD),
		head.CFrame * CFrame.new(0, -0.24 * scaleH, 0.55 * scaleD),
		Color3.fromRGB(140, 75, 75),
		Enum.Material.SmoothPlastic,
		transparency,
		model
	)

	local smileRot = isSubtleSmile and math.rad(10) or 0
	local smileY = isSubtleSmile and -0.18 or -0.20
	makePart(
		"MouthCorner_L",
		Enum.PartType.Block,
		Vector3.new(0.04 * scaleW, 0.04 * scaleH, 0.04 * scaleD),
		head.CFrame
			* CFrame.new(-0.14 * scaleW, smileY * scaleH, 0.54 * scaleD)
			* CFrame.Angles(0, 0, -smileRot),
		Color3.fromRGB(120, 65, 65),
		Enum.Material.SmoothPlastic,
		transparency,
		model
	)
	makePart(
		"MouthCorner_R",
		Enum.PartType.Block,
		Vector3.new(0.04 * scaleW, 0.04 * scaleH, 0.04 * scaleD),
		head.CFrame
			* CFrame.new(0.14 * scaleW, smileY * scaleH, 0.54 * scaleD)
			* CFrame.Angles(0, 0, smileRot),
		Color3.fromRGB(120, 65, 65),
		Enum.Material.SmoothPlastic,
		transparency,
		model
	)
end
local function buildVolumetricHairCrown(
	head: BasePart,
	hairColor: Color3,
	scaleW: number,
	scaleH: number,
	scaleD: number,
	transparency: number,
	isShadow: boolean,
	model: Model
)
	if isShadow then
		return
	end

	makePart(
		"HairTopVolume",
		Enum.PartType.Block,
		Vector3.new(1.24 * scaleW, 0.38 * scaleH, 1.26 * scaleD),
		head.CFrame * CFrame.new(0, 0.58 * scaleH, -0.05 * scaleD),
		hairColor,
		Enum.Material.SmoothPlastic,
		transparency,
		model
	)
	makePart(
		"HairCrownFront",
		Enum.PartType.Block,
		Vector3.new(1.15 * scaleW, 0.24 * scaleH, 0.35 * scaleD),
		head.CFrame * CFrame.new(0, 0.50 * scaleH, 0.38 * scaleD),
		hairColor,
		Enum.Material.SmoothPlastic,
		transparency,
		model
	)
	makePart(
		"HairSideburn_L",
		Enum.PartType.Block,
		Vector3.new(0.18 * scaleW, 0.68 * scaleH, 1.15 * scaleD),
		head.CFrame * CFrame.new(-0.56 * scaleW, 0.18 * scaleH, -0.05 * scaleD),
		hairColor,
		Enum.Material.SmoothPlastic,
		transparency,
		model
	)
	makePart(
		"HairSideburn_R",
		Enum.PartType.Block,
		Vector3.new(0.18 * scaleW, 0.68 * scaleH, 1.15 * scaleD),
		head.CFrame * CFrame.new(0.56 * scaleW, 0.18 * scaleH, -0.05 * scaleD),
		hairColor,
		Enum.Material.SmoothPlastic,
		transparency,
		model
	)
	makePart(
		"HairBackTaper",
		Enum.PartType.Block,
		Vector3.new(1.20 * scaleW, 0.72 * scaleH, 0.22 * scaleD),
		head.CFrame * CFrame.new(0, 0.12 * scaleH, -0.55 * scaleD),
		hairColor,
		Enum.Material.SmoothPlastic,
		transparency,
		model
	)
end

local function buildArticulatedHands(
	leftHand: BasePart?,
	rightHand: BasePart?,
	skinColor: Color3,
	suitColor: Color3,
	scaleW: number,
	scaleH: number,
	scaleD: number,
	transparency: number,
	anomalyId: string?,
	isShadow: boolean,
	model: Model
)
	local cuffColorL = Color3.fromRGB(220, 185, 75)
	local cuffColorR = (anomalyId == "wrong_cufflink") and Color3.fromRGB(192, 192, 192)
		or Color3.fromRGB(220, 185, 75)

	local handColor = if isShadow then Color3.fromRGB(0, 0, 0) else skinColor

	-- 1. Left Hand & 5 Articulated Fingers
	if leftHand then
		makePart(
			"Palm_L",
			Enum.PartType.Block,
			Vector3.new(0.62 * scaleW, 0.38 * scaleH, 0.26 * scaleD),
			leftHand.CFrame * CFrame.new(0, -0.10 * scaleH, 0),
			handColor,
			Enum.Material.SmoothPlastic,
			transparency,
			model
		)
		-- Shirt Cuff & French Cuff Button
		if not isShadow then
			makePart(
				"LeftSleeveHem",
				Enum.PartType.Block,
				Vector3.new(0.78 * scaleW, 0.18 * scaleH, 0.78 * scaleD),
				leftHand.CFrame * CFrame.new(0, 0.42 * scaleH, 0),
				suitColor,
				Enum.Material.Fabric,
				transparency,
				model
			)
			makePart(
				"ShirtCuff_L",
				Enum.PartType.Block,
				Vector3.new(0.72 * scaleW, 0.14 * scaleH, 0.72 * scaleD),
				leftHand.CFrame * CFrame.new(0, 0.28 * scaleH, 0),
				Color3.fromRGB(248, 248, 252),
				Enum.Material.Fabric,
				transparency,
				model
			)
			makePart(
				"CuffButton_L",
				Enum.PartType.Cylinder,
				Vector3.new(0.03, 0.06, 0.06),
				leftHand.CFrame
					* CFrame.new(-0.37 * scaleW, 0.28 * scaleH, 0)
					* CFrame.Angles(0, 0, math.rad(90)),
				cuffColorL,
				Enum.Material.Metal,
				transparency,
				model
			)
		end

		-- Thumb
		makePart(
			"ThumbKnuckle_L",
			Enum.PartType.Ball,
			Vector3.new(0.10, 0.10, 0.10),
			leftHand.CFrame * CFrame.new(0.22 * scaleW, -0.08 * scaleH, 0.08 * scaleD),
			handColor,
			Enum.Material.SmoothPlastic,
			transparency,
			model
		)
		makePart(
			"ThumbProximal_L",
			Enum.PartType.Block,
			Vector3.new(0.09 * scaleW, 0.18 * scaleH, 0.09 * scaleD),
			leftHand.CFrame
				* CFrame.new(0.25 * scaleW, -0.16 * scaleH, 0.10 * scaleD)
				* CFrame.Angles(0, math.rad(-22), math.rad(-18)),
			handColor,
			Enum.Material.SmoothPlastic,
			transparency,
			model
		)
		makePart(
			"ThumbDistal_L",
			Enum.PartType.Block,
			Vector3.new(0.08 * scaleW, 0.14 * scaleH, 0.08 * scaleD),
			leftHand.CFrame
				* CFrame.new(0.30 * scaleW, -0.28 * scaleH, 0.12 * scaleD)
				* CFrame.Angles(0, math.rad(-14), math.rad(-10)),
			handColor,
			Enum.Material.SmoothPlastic,
			transparency,
			model
		)

		-- 4 Articulated Fingers (Index, Middle, Ring, Pinky)
		local fingerOffsetsL = {
			{ name = "Index", x = 0.15, len1 = 0.22, len2 = 0.16 },
			{ name = "Middle", x = 0.04, len1 = 0.25, len2 = 0.18 },
			{ name = "Ring", x = -0.07, len1 = 0.22, len2 = 0.16 },
			{ name = "Pinky", x = -0.18, len1 = 0.18, len2 = 0.13 },
		}
		for _, f in ipairs(fingerOffsetsL) do
			makePart(
				`{f.name}Knuckle_L`,
				Enum.PartType.Ball,
				Vector3.new(0.09, 0.09, 0.09),
				leftHand.CFrame * CFrame.new(f.x * scaleW, -0.26 * scaleH, 0),
				handColor,
				Enum.Material.SmoothPlastic,
				transparency,
				model
			)
			makePart(
				`{f.name}Proximal_L`,
				Enum.PartType.Block,
				Vector3.new(0.08 * scaleW, f.len1 * scaleH, 0.08 * scaleD),
				leftHand.CFrame * CFrame.new(f.x * scaleW, (-0.26 - f.len1 * 0.5) * scaleH, 0),
				handColor,
				Enum.Material.SmoothPlastic,
				transparency,
				model
			)
			makePart(
				`{f.name}Distal_L`,
				Enum.PartType.Block,
				Vector3.new(0.07 * scaleW, f.len2 * scaleH, 0.07 * scaleD),
				leftHand.CFrame
					* CFrame.new(f.x * scaleW, (-0.26 - f.len1 - f.len2 * 0.5) * scaleH, 0),
				handColor,
				Enum.Material.SmoothPlastic,
				transparency,
				model
			)
		end
	end

	-- 2. Right Hand & 5 Articulated Fingers
	if rightHand then
		makePart(
			"Palm_R",
			Enum.PartType.Block,
			Vector3.new(0.62 * scaleW, 0.38 * scaleH, 0.26 * scaleD),
			rightHand.CFrame * CFrame.new(0, -0.10 * scaleH, 0),
			handColor,
			Enum.Material.SmoothPlastic,
			transparency,
			model
		)
		if not isShadow then
			makePart(
				"RightSleeveHem",
				Enum.PartType.Block,
				Vector3.new(0.78 * scaleW, 0.18 * scaleH, 0.78 * scaleD),
				rightHand.CFrame * CFrame.new(0, 0.42 * scaleH, 0),
				suitColor,
				Enum.Material.Fabric,
				transparency,
				model
			)
			makePart(
				"ShirtCuff_R",
				Enum.PartType.Block,
				Vector3.new(0.72 * scaleW, 0.14 * scaleH, 0.72 * scaleD),
				rightHand.CFrame * CFrame.new(0, 0.28 * scaleH, 0),
				Color3.fromRGB(248, 248, 252),
				Enum.Material.Fabric,
				transparency,
				model
			)
			makePart(
				"CuffButton_R",
				Enum.PartType.Cylinder,
				Vector3.new(0.03, 0.06, 0.06),
				rightHand.CFrame
					* CFrame.new(0.37 * scaleW, 0.28 * scaleH, 0)
					* CFrame.Angles(0, 0, math.rad(90)),
				cuffColorR,
				Enum.Material.Metal,
				transparency,
				model
			)
		end

		-- Thumb
		makePart(
			"ThumbKnuckle_R",
			Enum.PartType.Ball,
			Vector3.new(0.10, 0.10, 0.10),
			rightHand.CFrame * CFrame.new(-0.22 * scaleW, -0.08 * scaleH, 0.08 * scaleD),
			handColor,
			Enum.Material.SmoothPlastic,
			transparency,
			model
		)
		makePart(
			"ThumbProximal_R",
			Enum.PartType.Block,
			Vector3.new(0.09 * scaleW, 0.18 * scaleH, 0.09 * scaleD),
			rightHand.CFrame
				* CFrame.new(-0.25 * scaleW, -0.16 * scaleH, 0.10 * scaleD)
				* CFrame.Angles(0, math.rad(22), math.rad(18)),
			handColor,
			Enum.Material.SmoothPlastic,
			transparency,
			model
		)
		makePart(
			"ThumbDistal_R",
			Enum.PartType.Block,
			Vector3.new(0.08 * scaleW, 0.14 * scaleH, 0.08 * scaleD),
			rightHand.CFrame
				* CFrame.new(-0.30 * scaleW, -0.28 * scaleH, 0.12 * scaleD)
				* CFrame.Angles(0, math.rad(14), math.rad(10)),
			handColor,
			Enum.Material.SmoothPlastic,
			transparency,
			model
		)

		-- 4 Articulated Fingers (Index, Middle, Ring, Pinky)
		local fingerOffsetsR = {
			{ name = "Index", x = -0.15, len1 = 0.22, len2 = 0.16 },
			{ name = "Middle", x = -0.04, len1 = 0.25, len2 = 0.18 },
			{ name = "Ring", x = 0.07, len1 = 0.22, len2 = 0.16 },
			{ name = "Pinky", x = 0.18, len1 = 0.18, len2 = 0.13 },
		}
		for _, f in ipairs(fingerOffsetsR) do
			makePart(
				`{f.name}Knuckle_R`,
				Enum.PartType.Ball,
				Vector3.new(0.09, 0.09, 0.09),
				rightHand.CFrame * CFrame.new(f.x * scaleW, -0.26 * scaleH, 0),
				handColor,
				Enum.Material.SmoothPlastic,
				transparency,
				model
			)
			makePart(
				`{f.name}Proximal_R`,
				Enum.PartType.Block,
				Vector3.new(0.08 * scaleW, f.len1 * scaleH, 0.08 * scaleD),
				rightHand.CFrame * CFrame.new(f.x * scaleW, (-0.26 - f.len1 * 0.5) * scaleH, 0),
				handColor,
				Enum.Material.SmoothPlastic,
				transparency,
				model
			)
			makePart(
				`{f.name}Distal_R`,
				Enum.PartType.Block,
				Vector3.new(0.07 * scaleW, f.len2 * scaleH, 0.07 * scaleD),
				rightHand.CFrame
					* CFrame.new(f.x * scaleW, (-0.26 - f.len1 - f.len2 * 0.5) * scaleH, 0),
				handColor,
				Enum.Material.SmoothPlastic,
				transparency,
				model
			)
		end
	end
end

local function buildTailoredSuitAndOvercoat(
	upperTorso: BasePart,
	lowerTorso: BasePart?,
	suitColor: Color3,
	shirtColor: Color3,
	tieColor: Color3,
	scaleW: number,
	scaleH: number,
	scaleD: number,
	transparency: number,
	anomalyId: string?,
	isShadow: boolean,
	model: Model
)
	local isBackwardTie = anomalyId == "backward_tie"
	local button2_offset = anomalyId == "button_wrong" and 0.08 or 0

	if isShadow then
		return
	end

	-- 1. V-Neck 3D Collared Shirt with Stiff Wings & Center Placket
	makePart(
		"ShirtChest",
		Enum.PartType.Block,
		Vector3.new(0.50 * scaleW, 0.95 * scaleH, 0.05 * scaleD),
		upperTorso.CFrame * CFrame.new(0, 0.30 * scaleH, 0.52 * scaleD),
		shirtColor,
		Enum.Material.Fabric,
		transparency,
		model
	)
	makePart(
		"ShirtPlacket",
		Enum.PartType.Block,
		Vector3.new(0.12 * scaleW, 0.90 * scaleH, 0.06 * scaleD),
		upperTorso.CFrame * CFrame.new(0, 0.28 * scaleH, 0.53 * scaleD),
		shirtColor,
		Enum.Material.Fabric,
		transparency,
		model
	)
	makePart(
		"ShirtCollarWing_L",
		Enum.PartType.Block,
		Vector3.new(0.20 * scaleW, 0.36 * scaleH, 0.06 * scaleD),
		upperTorso.CFrame
			* CFrame.new(-0.24 * scaleW, 0.68 * scaleH, 0.54 * scaleD)
			* CFrame.Angles(0, 0, math.rad(-24)),
		shirtColor,
		Enum.Material.Fabric,
		transparency,
		model
	)
	makePart(
		"ShirtCollarWing_R",
		Enum.PartType.Block,
		Vector3.new(0.20 * scaleW, 0.36 * scaleH, 0.06 * scaleD),
		upperTorso.CFrame
			* CFrame.new(0.24 * scaleW, 0.68 * scaleH, 0.54 * scaleD)
			* CFrame.Angles(0, 0, math.rad(24)),
		shirtColor,
		Enum.Material.Fabric,
		transparency,
		model
	)

	-- 2. Tailored Overcoat / Suit Jacket Chest Panels & Notch Lapels
	makePart(
		"JacketLapel_L",
		Enum.PartType.Block,
		Vector3.new(0.26 * scaleW, 1.10 * scaleH, 0.08 * scaleD),
		upperTorso.CFrame
			* CFrame.new(-0.35 * scaleW, 0.22 * scaleH, 0.55 * scaleD)
			* CFrame.Angles(0, 0, math.rad(-14)),
		suitColor,
		Enum.Material.Fabric,
		transparency,
		model
	)
	makePart(
		"JacketLapel_R",
		Enum.PartType.Block,
		Vector3.new(0.26 * scaleW, 1.10 * scaleH, 0.08 * scaleD),
		upperTorso.CFrame
			* CFrame.new(0.35 * scaleW, 0.22 * scaleH, 0.55 * scaleD)
			* CFrame.Angles(0, 0, math.rad(14)),
		suitColor,
		Enum.Material.Fabric,
		transparency,
		model
	)
	makePart(
		"JacketChest_L",
		Enum.PartType.Block,
		Vector3.new(0.55 * scaleW, 1.35 * scaleH, 0.07 * scaleD),
		upperTorso.CFrame * CFrame.new(-0.58 * scaleW, 0.05 * scaleH, 0.53 * scaleD),
		suitColor,
		Enum.Material.Fabric,
		transparency,
		model
	)
	makePart(
		"JacketChest_R",
		Enum.PartType.Block,
		Vector3.new(0.55 * scaleW, 1.35 * scaleH, 0.07 * scaleD),
		upperTorso.CFrame * CFrame.new(0.58 * scaleW, 0.05 * scaleH, 0.53 * scaleD),
		suitColor,
		Enum.Material.Fabric,
		transparency,
		model
	)

	-- 3. Polished Horn Suit Buttons
	makePart(
		"SuitButton_1",
		Enum.PartType.Cylinder,
		Vector3.new(0.04, 0.08, 0.08),
		upperTorso.CFrame
			* CFrame.new(0, -0.12 * scaleH, 0.56 * scaleD)
			* CFrame.Angles(0, 0, math.rad(90)),
		Color3.fromRGB(30, 28, 26),
		Enum.Material.SmoothPlastic,
		transparency,
		model
	)
	makePart(
		"SuitButton_2",
		Enum.PartType.Cylinder,
		Vector3.new(0.04, 0.08, 0.08),
		upperTorso.CFrame
			* CFrame.new(button2_offset * scaleW, -0.42 * scaleH, 0.56 * scaleD)
			* CFrame.Angles(0, 0, math.rad(90)),
		Color3.fromRGB(30, 28, 26),
		Enum.Material.SmoothPlastic,
		transparency,
		model
	)
	makePart(
		"SuitButton_3",
		Enum.PartType.Cylinder,
		Vector3.new(0.04, 0.08, 0.08),
		upperTorso.CFrame
			* CFrame.new(0, -0.72 * scaleH, 0.56 * scaleD)
			* CFrame.Angles(0, 0, math.rad(90)),
		Color3.fromRGB(30, 28, 26),
		Enum.Material.SmoothPlastic,
		transparency,
		model
	)

	-- 4. Left Breast Pocket with Silk Pocket Square
	makePart(
		"BreastPocket",
		Enum.PartType.Block,
		Vector3.new(0.24 * scaleW, 0.06 * scaleH, 0.04 * scaleD),
		upperTorso.CFrame * CFrame.new(0.54 * scaleW, 0.38 * scaleH, 0.55 * scaleD),
		suitColor,
		Enum.Material.Fabric,
		transparency,
		model
	)
	makePart(
		"PocketSquare_Fold",
		Enum.PartType.Block,
		Vector3.new(0.18 * scaleW, 0.12 * scaleH, 0.04 * scaleD),
		upperTorso.CFrame * CFrame.new(0.54 * scaleW, 0.44 * scaleH, 0.56 * scaleD),
		tieColor,
		Enum.Material.Fabric,
		transparency,
		model
	)

	-- 5. Tapered Silk Necktie with 3D Windsor Knot and Gold Tie Bar
	local tieZOffset = if isBackwardTie then -0.55 * scaleD else 0.56 * scaleD
	local tieRot = if isBackwardTie then math.rad(180) else 0

	makePart(
		"TieKnot_3D",
		Enum.PartType.Block,
		Vector3.new(0.20 * scaleW, 0.18 * scaleH, 0.09 * scaleD),
		upperTorso.CFrame * CFrame.new(0, 0.60 * scaleH, tieZOffset) * CFrame.Angles(0, tieRot, 0),
		tieColor,
		Enum.Material.Fabric,
		transparency,
		model
	)
	makePart(
		"TieBladeUpper",
		Enum.PartType.Block,
		Vector3.new(0.18 * scaleW, 0.55 * scaleH, 0.06 * scaleD),
		upperTorso.CFrame * CFrame.new(0, 0.28 * scaleH, tieZOffset) * CFrame.Angles(0, tieRot, 0),
		tieColor,
		Enum.Material.Fabric,
		transparency,
		model
	)
	makePart(
		"TieBladeLower",
		Enum.PartType.Block,
		Vector3.new(0.22 * scaleW, 0.55 * scaleH, 0.06 * scaleD),
		upperTorso.CFrame * CFrame.new(0, -0.22 * scaleH, tieZOffset) * CFrame.Angles(0, tieRot, 0),
		tieColor,
		Enum.Material.Fabric,
		transparency,
		model
	)
	if not isBackwardTie then
		makePart(
			"TieBarGold",
			Enum.PartType.Block,
			Vector3.new(0.16 * scaleW, 0.04 * scaleH, 0.04 * scaleD),
			upperTorso.CFrame * CFrame.new(0, 0.10 * scaleH, 0.58 * scaleD),
			Color3.fromRGB(225, 190, 70),
			Enum.Material.Metal,
			transparency,
			model
		)
	end

	-- 6. Leather Belt with Brass Buckle & Prong on LowerTorso
	if lowerTorso then
		makePart(
			"LeatherBeltStrap",
			Enum.PartType.Block,
			Vector3.new(1.88 * scaleW, 0.16 * scaleH, 1.06 * scaleD),
			lowerTorso.CFrame * CFrame.new(0, 0.38 * scaleH, 0),
			Color3.fromRGB(28, 22, 18),
			Enum.Material.Leather,
			transparency,
			model
		)
		makePart(
			"BeltBuckleOuter",
			Enum.PartType.Block,
			Vector3.new(0.34 * scaleW, 0.20 * scaleH, 0.06 * scaleD),
			lowerTorso.CFrame * CFrame.new(0, 0.38 * scaleH, 0.55 * scaleD),
			Color3.fromRGB(220, 185, 70),
			Enum.Material.Metal,
			transparency,
			model
		)
		makePart(
			"BeltBuckleInner",
			Enum.PartType.Block,
			Vector3.new(0.22 * scaleW, 0.12 * scaleH, 0.07 * scaleD),
			lowerTorso.CFrame * CFrame.new(0, 0.38 * scaleH, 0.55 * scaleD),
			Color3.fromRGB(28, 22, 18),
			Enum.Material.Leather,
			transparency,
			model
		)
		makePart(
			"BeltProng",
			Enum.PartType.Block,
			Vector3.new(0.04 * scaleW, 0.14 * scaleH, 0.08 * scaleD),
			lowerTorso.CFrame * CFrame.new(0, 0.38 * scaleH, 0.56 * scaleD),
			Color3.fromRGB(220, 185, 70),
			Enum.Material.Metal,
			transparency,
			model
		)
	end
end

local function buildExecutiveBriefcase(
	rightHand: BasePart,
	scaleW: number,
	scaleH: number,
	scaleD: number,
	transparency: number,
	isShadow: boolean,
	model: Model
)
	if isShadow then
		return
	end

	-- Hard-shell Executive Leather Briefcase Body
	makePart(
		"BriefcaseBody",
		Enum.PartType.Block,
		Vector3.new(0.38 * scaleW, 1.20 * scaleH, 1.62 * scaleD),
		rightHand.CFrame * CFrame.new(0, -0.48 * scaleH, 0),
		Color3.fromRGB(42, 26, 18),
		Enum.Material.Leather,
		transparency,
		model
	)
	-- Metal Trim Perimeter
	makePart(
		"BriefcaseRim",
		Enum.PartType.Block,
		Vector3.new(0.40 * scaleW, 1.22 * scaleH, 0.06 * scaleD),
		rightHand.CFrame * CFrame.new(0, -0.48 * scaleH, 0),
		Color3.fromRGB(180, 150, 60),
		Enum.Material.Metal,
		transparency,
		model
	)
	-- Brass Latches
	makePart(
		"BriefcaseLatch_L",
		Enum.PartType.Block,
		Vector3.new(0.40 * scaleW, 0.12 * scaleH, 0.10 * scaleD),
		rightHand.CFrame * CFrame.new(0, -0.16 * scaleH, -0.45 * scaleD),
		Color3.fromRGB(220, 185, 75),
		Enum.Material.Metal,
		transparency,
		model
	)
	makePart(
		"BriefcaseLatch_R",
		Enum.PartType.Block,
		Vector3.new(0.40 * scaleW, 0.12 * scaleH, 0.10 * scaleD),
		rightHand.CFrame * CFrame.new(0, -0.16 * scaleH, 0.45 * scaleD),
		Color3.fromRGB(220, 185, 75),
		Enum.Material.Metal,
		transparency,
		model
	)
	-- Curved Handle
	makePart(
		"BriefcaseHandleArch",
		Enum.PartType.Cylinder,
		Vector3.new(0.12 * scaleW, 0.48 * scaleH, 0.48 * scaleD),
		rightHand.CFrame * CFrame.new(0, 0.12 * scaleH, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color3.fromRGB(28, 18, 12),
		Enum.Material.Leather,
		transparency,
		model
	)
	makePart(
		"BriefcaseHandleGrip",
		Enum.PartType.Block,
		Vector3.new(0.14 * scaleW, 0.08 * scaleH, 0.42 * scaleD),
		rightHand.CFrame * CFrame.new(0, 0.22 * scaleH, 0),
		Color3.fromRGB(220, 185, 75),
		Enum.Material.Metal,
		transparency,
		model
	)
end

local function buildTailoredLegsAndShoes(
	leftLowerLeg: BasePart?,
	rightLowerLeg: BasePart?,
	pantsColor: Color3,
	scaleW: number,
	scaleH: number,
	scaleD: number,
	transparency: number,
	isShadow: boolean,
	model: Model
)
	if isShadow then
		return
	end

	local shoeColor = Color3.fromRGB(20, 16, 14)

	-- Left Trouser Cuff & Oxford Shoe
	if leftLowerLeg then
		makePart(
			"PantCuff_L",
			Enum.PartType.Block,
			Vector3.new(0.96 * scaleW, 0.16 * scaleH, 0.96 * scaleD),
			leftLowerLeg.CFrame * CFrame.new(0, -0.65 * scaleH, 0),
			pantsColor,
			Enum.Material.Fabric,
			transparency,
			model
		)
		makePart(
			"Shoe_L",
			Enum.PartType.Block,
			Vector3.new(0.88 * scaleW, 0.36 * scaleH, 1.25 * scaleD),
			leftLowerLeg.CFrame * CFrame.new(0, -0.92 * scaleH, 0.14 * scaleD),
			shoeColor,
			Enum.Material.Leather,
			transparency,
			model
		)
		makePart(
			"ShoeSole_L",
			Enum.PartType.Block,
			Vector3.new(0.92 * scaleW, 0.08 * scaleH, 1.30 * scaleD),
			leftLowerLeg.CFrame * CFrame.new(0, -1.12 * scaleH, 0.14 * scaleD),
			Color3.fromRGB(10, 10, 10),
			Enum.Material.SmoothPlastic,
			transparency,
			model
		)
		makePart(
			"ShoeHeel_L",
			Enum.PartType.Block,
			Vector3.new(0.92 * scaleW, 0.12 * scaleH, 0.44 * scaleD),
			leftLowerLeg.CFrame * CFrame.new(0, -1.06 * scaleH, -0.32 * scaleD),
			Color3.fromRGB(28, 20, 16),
			Enum.Material.Leather,
			transparency,
			model
		)
	end

	-- Right Trouser Cuff & Oxford Shoe
	if rightLowerLeg then
		makePart(
			"PantCuff_R",
			Enum.PartType.Block,
			Vector3.new(0.96 * scaleW, 0.16 * scaleH, 0.96 * scaleD),
			rightLowerLeg.CFrame * CFrame.new(0, -0.65 * scaleH, 0),
			pantsColor,
			Enum.Material.Fabric,
			transparency,
			model
		)
		makePart(
			"Shoe_R",
			Enum.PartType.Block,
			Vector3.new(0.88 * scaleW, 0.36 * scaleH, 1.25 * scaleD),
			rightLowerLeg.CFrame * CFrame.new(0, -0.92 * scaleH, 0.14 * scaleD),
			shoeColor,
			Enum.Material.Leather,
			transparency,
			model
		)
		makePart(
			"ShoeSole_R",
			Enum.PartType.Block,
			Vector3.new(0.92 * scaleW, 0.08 * scaleH, 1.30 * scaleD),
			rightLowerLeg.CFrame * CFrame.new(0, -1.12 * scaleH, 0.14 * scaleD),
			Color3.fromRGB(10, 10, 10),
			Enum.Material.SmoothPlastic,
			transparency,
			model
		)
		makePart(
			"ShoeHeel_R",
			Enum.PartType.Block,
			Vector3.new(0.92 * scaleW, 0.12 * scaleH, 0.44 * scaleD),
			rightLowerLeg.CFrame * CFrame.new(0, -1.06 * scaleH, -0.32 * scaleD),
			Color3.fromRGB(28, 20, 16),
			Enum.Material.Leather,
			transparency,
			model
		)
	end
end

-- =============================================================================
-- 6 CORE CINEMATIC HORROR MOB ARCHETYPES
-- =============================================================================

local function buildHorrorArchetypes(
	head: BasePart,
	upperTorso: BasePart,
	hrp: BasePart,
	scaleW: number,
	scaleH: number,
	scaleD: number,
	transparency: number,
	anomalyId: string?,
	model: Model
)
	if anomalyId == "snapped_neck" then
		for i = 1, 4 do
			makePart(
				`Vertebra_C{i}`,
				Enum.PartType.Block,
				Vector3.new(0.24 * scaleW, 0.16 * scaleH, 0.24 * scaleD),
				head.CFrame * CFrame.new(0.38 * scaleW, (-0.40 - i * 0.14) * scaleH, 0),
				Color3.fromRGB(236, 230, 218),
				Enum.Material.SmoothPlastic,
				0,
				model
			)
		end
		makePart(
			"SpinalCore",
			Enum.PartType.Cylinder,
			Vector3.new(0.55 * scaleH, 0.12 * scaleW, 0.12 * scaleD),
			head.CFrame
				* CFrame.new(0.38 * scaleW, -0.68 * scaleH, 0)
				* CFrame.Angles(0, 0, math.rad(90)),
			Color3.fromRGB(180, 160, 140),
			Enum.Material.SmoothPlastic,
			0,
			model
		)
		for i = 1, 4 do
			makePart(
				`TornMuscle_{i}`,
				Enum.PartType.Block,
				Vector3.new(0.18 * scaleW, 0.22 * scaleH, 0.18 * scaleD),
				head.CFrame
					* CFrame.new(
						0.34 * scaleW,
						(-0.38 - i * 0.12) * scaleH,
						(i % 2 == 0) and 0.08 or -0.08
					),
				Color3.fromRGB(85, 10, 15),
				Enum.Material.SmoothPlastic,
				0,
				model
			)
		end
		makePart(
			"TornTissue_1",
			Enum.PartType.Block,
			Vector3.new(0.32 * scaleW, 0.25 * scaleH, 0.32 * scaleD),
			head.CFrame * CFrame.new(0.36 * scaleW, -0.48 * scaleH, 0),
			Color3.fromRGB(65, 8, 12),
			Enum.Material.SmoothPlastic,
			0,
			model
		)
	end
	if anomalyId == "shadow_entity" then
		local eyeL = makePart(
			"Eye_L",
			Enum.PartType.Block,
			Vector3.new(0.26 * scaleW, 0.15 * scaleH, 0.06 * scaleD),
			head.CFrame * CFrame.new(-0.28 * scaleW, 0.15 * scaleH, 0.56 * scaleD),
			Color3.fromRGB(0, 255, 235),
			Enum.Material.Neon,
			0,
			model
		)
		makePart(
			"Eye_R",
			Enum.PartType.Block,
			Vector3.new(0.26 * scaleW, 0.15 * scaleH, 0.06 * scaleD),
			head.CFrame * CFrame.new(0.28 * scaleW, 0.15 * scaleH, 0.56 * scaleD),
			Color3.fromRGB(0, 255, 235),
			Enum.Material.Neon,
			0,
			model
		)
		local cyanLight = Instance.new("PointLight")
		cyanLight.Color = Color3.fromRGB(0, 255, 235)
		cyanLight.Brightness = 3.2
		cyanLight.Range = 8
		cyanLight.Parent = eyeL
		local voidParticles = Instance.new("ParticleEmitter")
		voidParticles.Name = "VoidSmokeEmitter"
		voidParticles.Rate = 24
		voidParticles.Speed = NumberRange.new(0.3, 0.8)
		voidParticles.Lifetime = NumberRange.new(0.8, 1.5)
		voidParticles.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.5),
			NumberSequenceKeypoint.new(1, 1.4),
		})
		voidParticles.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.2),
			NumberSequenceKeypoint.new(1, 1.0),
		})
		voidParticles.Color = ColorSequence.new(Color3.fromRGB(0, 0, 0))
		voidParticles.SpreadAngle = Vector2.new(180, 180)
		voidParticles.Parent = hrp
	end
end

-- =============================================================================
-- MAIN GUEST MODEL CONSTRUCTION
-- =============================================================================

local function createGuestModel(guestData: GuestData): (Model, BasePart, number, number)
	local rng = Random.new()
	local skinColor = SKIN_TONES[rng:NextInteger(1, #SKIN_TONES)]
	local suitColor = SUIT_PALETTES[rng:NextInteger(1, #SUIT_PALETTES)]
	local shirtColor = SHIRT_PALETTES[rng:NextInteger(1, #SHIRT_PALETTES)]
	local pantsColor = PANTS_PALETTES[rng:NextInteger(1, #PANTS_PALETTES)]
	local tieColor = TIE_PALETTES[rng:NextInteger(1, #TIE_PALETTES)]
	local eyeColor = IRIS_PALETTES[rng:NextInteger(1, #IRIS_PALETTES)]
	local hairColor = HAIR_COLORS[rng:NextInteger(1, #HAIR_COLORS)]
	local hairAsset = HAIR_ASSETS[rng:NextInteger(1, #HAIR_ASSETS)]

	local anomalyId = guestData.anomalyId
	isCurrentAnomaly = anomalyId ~= nil

	local heightScale = 1.0
	local widthScale = 1.0
	local depthScale = 1.0
	local transparency = 0.0

	-- Apply Anomaly Property Changes
	if anomalyId == "skin_tone_off" then
		-- Desaturate 4%
		local h, s, v = skinColor:ToHSV()
		skinColor = Color3.fromHSV(h, math.clamp(s - 0.04, 0, 1), v)
	elseif anomalyId == "colorless_skin" then
		skinColor = Color3.fromRGB(224, 226, 232)
	elseif anomalyId == "no_reflection" then
		transparency = 0.55 -- We will also disable shadows below
	elseif anomalyId == "shadow_entity" then
		skinColor = Color3.fromRGB(0, 0, 0)
		suitColor = Color3.fromRGB(0, 0, 0)
		shirtColor = Color3.fromRGB(0, 0, 0)
		pantsColor = Color3.fromRGB(0, 0, 0)
		tieColor = Color3.fromRGB(0, 0, 0)
		hairColor = Color3.fromRGB(0, 0, 0)
	end

	local desc = Instance.new("HumanoidDescription")
	desc.HeadColor = skinColor
	desc.TorsoColor = suitColor
	desc.LeftArmColor = suitColor
	desc.RightArmColor = suitColor
	desc.LeftLegColor = pantsColor
	desc.RightLegColor = pantsColor
	desc.HeightScale = heightScale
	desc.WidthScale = widthScale
	desc.DepthScale = depthScale
	desc.HeadScale = 1.0
	desc.HairAccessory = if anomalyId ~= "shadow_entity" then hairAsset else ""
	desc.Face = 0

	local model: Model
	local success, result = pcall(function()
		return Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
	end)

	if success and result then
		model = result
	else
		model = Instance.new("Model")
		local hum = Instance.new("Humanoid")
		hum.RigType = Enum.HumanoidRigType.R15
		hum.Parent = model
		local root = makePart(
			"HumanoidRootPart",
			Enum.PartType.Block,
			Vector3.new(2, 2, 1),
			CFrame.new(SPAWN_POS),
			Color3.new(),
			Enum.Material.SmoothPlastic,
			1,
			model
		)
		model.PrimaryPart = root
	end

	model.Name = `Guest_{guestData.name}`
	model:PivotTo(CFrame.lookAt(SPAWN_POS, DESK_POS))

	local hrp = model:WaitForChild("HumanoidRootPart", 5) :: BasePart?
	if not hrp then
		hrp = makePart(
			"HumanoidRootPart",
			Enum.PartType.Block,
			Vector3.new(2, 2, 1),
			CFrame.new(SPAWN_POS),
			Color3.new(),
			Enum.Material.SmoothPlastic,
			1,
			model
		)
	end
	model.PrimaryPart = hrp

	local head = model:WaitForChild("Head", 5) :: BasePart?
	local upperTorso = model:WaitForChild("UpperTorso", 5) :: BasePart?
	local lowerTorso = model:WaitForChild("LowerTorso", 5) :: BasePart?
	local leftHand = model:WaitForChild("LeftHand", 5) :: BasePart?
	local rightHand = model:WaitForChild("RightHand", 5) :: BasePart?
	local leftLowerLeg = model:WaitForChild("LeftLowerLeg", 5) :: BasePart?
	local rightLowerLeg = model:WaitForChild("RightLowerLeg", 5) :: BasePart?

	if head then
		local faceDecal = head:FindFirstChild("face")
		if faceDecal then
			faceDecal:Destroy()
		end
	end

	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") then
			p.Anchored = true
			p.CanCollide = false
			p.Transparency = transparency
			if
				anomalyId == "no_reflection"
				or anomalyId == "shadow_entity"
				or anomalyId == "shadow_wrong_angle"
			then
				p.CastShadow = false
			end
			if anomalyId == "shadow_entity" then
				p.Color = Color3.fromRGB(0, 0, 0)
				p.Material = Enum.Material.SmoothPlastic
			elseif p.Name:find("Torso") or p.Name:find("Arm") then
				p.Color = suitColor
				p.Material = Enum.Material.Fabric
			elseif p.Name:find("Leg") then
				p.Color = pantsColor
				p.Material = Enum.Material.Fabric
			elseif p.Name == "Head" then
				p.Color = skinColor
				p.Material = Enum.Material.SmoothPlastic
			end
		end
	end

	table.clear(activeEyelids)
	table.clear(activeUvParts)
	table.clear(activeUvLights)

	if not upperTorso or not head or not hrp then
		return model, hrp or model.PrimaryPart :: BasePart, widthScale, heightScale
	end

	buildAnatomicalFacialContours(
		head,
		skinColor,
		eyeColor,
		widthScale,
		heightScale,
		depthScale,
		transparency,
		anomalyId,
		model
	)
	buildVolumetricHairCrown(
		head,
		hairColor,
		widthScale,
		heightScale,
		depthScale,
		transparency,
		anomalyId == "shadow_entity",
		model
	)
	buildTailoredSuitAndOvercoat(
		upperTorso,
		lowerTorso,
		suitColor,
		shirtColor,
		tieColor,
		widthScale,
		heightScale,
		depthScale,
		transparency,
		anomalyId == "backward_tie",
		anomalyId == "shadow_entity",
		model
	)
	buildArticulatedHands(
		leftHand,
		rightHand,
		skinColor,
		suitColor,
		widthScale,
		heightScale,
		depthScale,
		transparency,
		anomalyId == "shadow_entity",
		model
	)

	if rightHand then
		buildExecutiveBriefcase(
			rightHand,
			widthScale,
			heightScale,
			depthScale,
			transparency,
			anomalyId == "shadow_entity",
			model
		)
	end
	buildTailoredLegsAndShoes(
		leftLowerLeg,
		rightLowerLeg,
		pantsColor,
		widthScale,
		heightScale,
		depthScale,
		transparency,
		anomalyId == "shadow_entity",
		model
	)
	buildHorrorArchetypes(
		head,
		upperTorso,
		hrp,
		widthScale,
		heightScale,
		depthScale,
		transparency,
		anomalyId,
		model
	)

	if anomalyId == "glitch_silhouette" then
		makePart(
			"GlitchTear",
			Enum.PartType.Block,
			Vector3.new(2.5 * widthScale, 0.05 * heightScale, 1.5 * depthScale),
			upperTorso.CFrame,
			Color3.fromRGB(200, 200, 200),
			Enum.Material.Neon,
			1.0,
			model
		)
	end

	if anomalyId == "inverted_pulse" then
		makePart(
			"CarotidArtery",
			Enum.PartType.Block,
			Vector3.new(0.14 * widthScale, 0.35 * heightScale, 0.14 * depthScale),
			upperTorso.CFrame * CFrame.new(0.48 * widthScale, 0.70 * heightScale, 0.25 * depthScale),
			Color3.fromRGB(150, 20, 25),
			Enum.Material.SmoothPlastic,
			0,
			model
		)
	end
	if anomalyId == "cold_fog" then
		local fogEmitterPart = makePart(
			"FogEmitter",
			Enum.PartType.Block,
			Vector3.new(0.1, 0.1, 0.1),
			head.CFrame * CFrame.new(0, -0.22 * heightScale, 0.65 * depthScale),
			Color3.fromRGB(240, 245, 255),
			Enum.Material.Air,
			1,
			model
		)
		local fog = Instance.new("ParticleEmitter")
		fog.Name = "BreathVapor"
		fog.Rate = 4
		fog.Speed = NumberRange.new(1.0, 1.8)
		fog.Lifetime = NumberRange.new(0.8, 1.4)
		fog.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.15),
			NumberSequenceKeypoint.new(1, 0.65),
		})
		fog.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.4),
			NumberSequenceKeypoint.new(1, 1.0),
		})
		fog.Color = ColorSequence.new(Color3.fromRGB(225, 235, 245))
		fog.SpreadAngle = Vector2.new(12, 12)
		fog.Parent = fogEmitterPart
	end

	if anomalyId == "uv_occult_rune" then
		local rune = makePart(
			"OccultRuneForehead",
			Enum.PartType.Block,
			Vector3.new(0.32 * widthScale, 0.32 * heightScale, 0.05 * depthScale),
			head.CFrame * CFrame.new(0, 0.35 * heightScale, 0.55 * depthScale),
			Color3.fromRGB(255, 30, 45),
			Enum.Material.Neon,
			1.0,
			model
		)
		local rLight = Instance.new("PointLight")
		rLight.Color = Color3.fromRGB(255, 30, 45)
		rLight.Brightness = 0
		rLight.Range = 4
		rLight.Parent = rune
		table.insert(activeUvParts, rune)
		table.insert(activeUvLights, rLight)
	elseif anomalyId == "uv_bloodied_hands" and rightHand then
		local bloodHands = makePart(
			"BloodiedHandsUV",
			Enum.PartType.Block,
			Vector3.new(0.65 * widthScale, 0.65 * heightScale, 0.65 * depthScale),
			rightHand.CFrame,
			Color3.fromRGB(240, 25, 60),
			Enum.Material.Neon,
			1.0,
			model
		)
		local bLight = Instance.new("PointLight")
		bLight.Color = Color3.fromRGB(240, 25, 60)
		bLight.Brightness = 0
		bLight.Range = 4
		bLight.Parent = bloodHands
		table.insert(activeUvParts, bloodHands)
		table.insert(activeUvLights, bLight)
	end

	table.clear(currentPartInfos)
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") and p ~= hrp then
			table.insert(currentPartInfos, {
				part = p,
				group = classifyLimbGroup(p.Name),
				baseCF = hrp.CFrame:ToObjectSpace(p.CFrame),
				origTransparency = p.Transparency,
			})
		end
	end

	return model, hrp, widthScale, heightScale
end

local function animateEntranceDoors(open: boolean)
	local lobby = Workspace:FindFirstChild("Lobby")
	if not lobby then
		return
	end

	local doorL = lobby:FindFirstChild("GlassDoorL") :: BasePart?
	local doorR = lobby:FindFirstChild("GlassDoorR") :: BasePart?
	if not doorL or not doorR then
		return
	end

	local hingeL = CFrame.new(-3.8, 5.5, -16.5)
	local hingeR = CFrame.new(3.8, 5.5, -16.5)

	local angleL = if open then math.rad(65) else 0
	local angleR = if open then math.rad(-65) else 0

	local targetCFL = hingeL * CFrame.Angles(0, angleL, 0) * CFrame.new(1.9, 0, 0)
	local targetCFR = hingeR * CFrame.Angles(0, angleR, 0) * CFrame.new(-1.9, 0, 0)

	local twL = TweenService:Create(
		doorL,
		TweenInfo.new(0.65, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ CFrame = targetCFL }
	)
	local twR = TweenService:Create(
		doorR,
		TweenInfo.new(0.65, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ CFrame = targetCFR }
	)

	twL:Play()
	twR:Play()

	if open then
		Atmosphere.playSound("door", doorL, 0.45)
		task.delay(1.8, function()
			animateEntranceDoors(false)
		end)
	end
end

-- =============================================================================
-- PUBLIC API
-- =============================================================================

function GuestRenderer.arrive(guestData: GuestData)
	GuestRenderer.cleanup()

	local lobby = Workspace:FindFirstChild("Lobby")
	if not lobby then
		return
	end

	animateEntranceDoors(true)

	local guest, hrp, scaleW, scaleH = createGuestModel(guestData)
	guest.Parent = lobby
	currentGuestModel = guest

	local targetZ = (guestData.anomalyId == "wrong_distance") and 0.80 or 1.80
	local targetDeskPos = Vector3.new(0, 4.80, targetZ)

	if guestData.anomalyId == "whispering_vents" then
		local vent = Workspace:FindFirstChild("Lobby"):FindFirstChild("VentilationDuct")
		if vent then
			local sound = Instance.new("Sound")
			sound.Name = "VentWhisper"
			sound.SoundId = "rbxassetid://16124508659" -- Spooky whisper
			sound.Volume = 0.6
			sound.Looped = true
			sound.RollOffMode = Enum.RollOffMode.InverseTapered
			sound.RollOffMinDistance = 5
			sound.RollOffMaxDistance = 25
			sound.Parent = vent
			sound:Play()
		end
	end

	local startCF = CFrame.lookAt(SPAWN_POS, targetDeskPos)
	local targetCF = CFrame.lookAt(targetDeskPos, targetDeskPos + Vector3.new(0, 0, 10))

	local walkDuration = 2.4
	local startTime = os.clock()
	local lastFootstep = 0
	local isStill = guestData.anomalyId == "too_still"
	local isBrokenCervical = guestData.anomalyId == "snapped_neck"
		or guestData.anomalyId == "broken_cervical"
	local isFingerTwitch = guestData.anomalyId == "finger_twitch"
	local isInvertedPulse = guestData.anomalyId == "inverted_pulse"

	local state: AnimState = {
		legAngleL = 0,
		legAngleR = 0,
		armAngleL = 0,
		armAngleR = 0,
		armRollL = 0,
		armRollR = 0,
		torsoLift = 0,
		torsoPitch = 0,
		torsoYaw = 0,
		torsoRoll = 0,
		hipBob = 0,
		hipYaw = 0,
		headPitch = 0,
		headYaw = 0,
		headRoll = 0,
		headSnapCF = if isBrokenCervical
			then CFrame.Angles(math.rad(-6), math.rad(10), math.rad(85))
			else CFrame.identity,
	}

	-- 1. Smooth Entrance Walking Kinematics
	activeWalkConnection = RunService.RenderStepped:Connect(function()
		local elapsed = os.clock() - startTime
		local alpha = math.clamp(elapsed / walkDuration, 0, 1)
		local easedAlpha =
			TweenService:GetValue(alpha, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

		local currentPos = startCF.Position:Lerp(targetCF.Position, easedAlpha)
		local walkPhase = elapsed * 8.5
		local bob = if alpha < 1 then math.abs(math.sin(walkPhase)) * 0.20 else 0

		hrp.CFrame =
			CFrame.new(currentPos + Vector3.new(0, bob, 0), targetDeskPos + Vector3.new(0, 0, 10))

		if alpha < 1 then
			local swing = math.sin(walkPhase) * math.rad(28)
			state.legAngleL = swing
			state.legAngleR = -swing
			state.armAngleL = -swing * 0.85
			state.armAngleR = swing * 0.85
			state.torsoYaw = math.sin(walkPhase) * math.rad(2.5)

			if elapsed - lastFootstep > 0.36 then
				lastFootstep = elapsed
				Atmosphere.playSound("footstep", hrp, 0.40)
				if guestData.anomalyId == "wet_footprints" then
					spawnFootprint(hrp.Position + Vector3.new(0, -2.2, 0))
				end
			end
		else
			state.legAngleL = 0
			state.legAngleR = 0
			state.armAngleL = 0
			state.armAngleR = 0
			state.torsoYaw = 0
		end

		applyPose(hrp, state, scaleW, scaleH)

		-- 2. Arrival completed -> Transition to Natural Breathing & Horror Idle Physics
		if alpha >= 1 then
			if activeWalkConnection then
				activeWalkConnection:Disconnect()
				activeWalkConnection = nil
			end

			-- Setup natural eye blinking cycle
			local hasNoBlink = isStill
				or guestData.anomalyId == "no_blinking"
				or guestData.anomalyId == "frozen_smile"
				or guestData.anomalyId == "mandela_alternate"
				or guestData.anomalyId == "hollow_eyes"
				or guestData.anomalyId == "cavernous_hollow"
				or guestData.anomalyId == "faceless"
				or guestData.anomalyId == "flayed_mimic"
				or guestData.anomalyId == "shadow_entity"
				or guestData.anomalyId == "void_silhouette"

			if not hasNoBlink and #activeEyelids > 0 then
				blinkThread = task.spawn(function()
					local rngBlink = Random.new()
					while currentGuestModel == guest do
						if guestData.anomalyId == "slow_blink" then
							task.wait(rngBlink:NextNumber(13.5, 14.5))
						else
							task.wait(rngBlink:NextNumber(3.2, 5.8))
						end
						for _, lid in ipairs(activeEyelids) do
							if lid.Parent then
								lid.Size = Vector3.new(lid.Size.X, 0.12 * scaleH, lid.Size.Z)
							end
						end
						task.wait(0.12)
						for _, lid in ipairs(activeEyelids) do
							if lid.Parent then
								lid.Size = Vector3.new(lid.Size.X, 0.03 * scaleH, lid.Size.Z)
							end
						end
					end
				end)
			end

			-- Natural Human Idle Breathing & Horror Jitter Loop
			if not isStill then
				local idleStart = os.clock()
				local lastTwitchTime = 0
				local twitchAngle = CFrame.identity
				local gazePitch = 0
				local gazeYaw = 0
				local nextGazeTime = 0

				activeIdleConnection = RunService.RenderStepped:Connect(function()
					if currentGuestModel ~= guest or not hrp.Parent then
						if activeIdleConnection then
							activeIdleConnection:Disconnect()
							activeIdleConnection = nil
						end
						return
					end

					local t = os.clock() - idleStart

					-- Natural Human Breathing Physics (Ribcage expansion & vertical lift)
					local breathRate = guestData.anomalyId == "breathing_out_of_sync" and 0.8 or 2.2
					local breathWave = math.sin(t * breathRate)

					-- Flickering presence
					if guestData.anomalyId == "flickering_presence" then
						if math.random() < 0.02 then
							for _, info in ipairs(currentPartInfos) do
								if info.part.Parent then
									info.part.Transparency = 1.0
								end
							end
						else
							for _, info in ipairs(currentPartInfos) do
								if info.part.Parent then
									info.part.Transparency = info.origTransparency
								end
							end
						end
					end

					state.torsoLift = breathWave * 0.038
					state.torsoPitch = breathWave * math.rad(1.2)
					state.armAngleL = breathWave * math.rad(0.6)
					state.armAngleR = breathWave * math.rad(0.6)

					-- Subtle Human Gaze Micro-Saccades
					if t > nextGazeTime then
						local delay = guestData.anomalyId == "late_tracking" and 1.5 or 0
						nextGazeTime = t + math.random(3, 6) + delay
						gazePitch = math.rad(math.random(-2, 2))
						gazeYaw = math.rad(math.random(-4, 4))
					end

					state.headPitch = -breathWave * math.rad(0.8) + gazePitch
					state.headYaw = gazeYaw

					-- Broken Cervical violent sudden spasm tell
					if isBrokenCervical then
						local baseSnap = CFrame.Angles(math.rad(-6), math.rad(10), math.rad(85))
						if t - lastTwitchTime > 2.8 and math.random() < 0.06 then
							lastTwitchTime = t
							twitchAngle = CFrame.Angles(
								math.rad(math.random(-15, 15)),
								math.rad(math.random(-20, 20)),
								math.rad(math.random(-12, 12))
							)
							Atmosphere.playSound("flicker", hrp, 0.20)
						else
							twitchAngle = twitchAngle:Lerp(CFrame.identity, 0.18)
						end
						state.headSnapCF = baseSnap * twitchAngle
					end

					-- Nervous Finger Spasms Tell
					if isFingerTwitch then
						if math.random() < 0.12 then
							state.armRollR = math.rad(math.random(-18, 18))
						else
							state.armRollR = 0
						end
					end

					-- Inverted Throbbing Neck Artery Pulse
					if isInvertedPulse then
						local pulseWave = math.abs(math.sin(t * 6.5))
						for _, info in ipairs(currentPartInfos) do
							if info.part.Name == "CarotidArtery" and info.part.Parent then
								info.part.Size = Vector3.new(
									(0.14 + pulseWave * 0.08) * scaleW,
									0.35 * scaleH,
									(0.14 + pulseWave * 0.08) * scaleW
								)
							end
						end
					end

					applyPose(hrp, state, scaleW, scaleH)
				end)
			end
		end
	end)

	-- 3. Dynamic UV Blacklight Illuminator Support
	local uvRemote = Remotes.get("UVState")
	uvStateConnection = uvRemote.OnClientEvent:Connect(function(data)
		local isEnabled = data.enabled == true
		for _, part in ipairs(activeUvParts) do
			if part.Parent then
				part.Transparency = if isEnabled then 0.0 else 1.0
			end
		end
		for _, light in ipairs(activeUvLights) do
			if light.Parent then
				light.Brightness = if isEnabled then 2.8 else 0
			end
		end
	end)
end

function GuestRenderer.depart(admitted: boolean)
	local vent = Workspace:FindFirstChild("Lobby"):FindFirstChild("VentilationDuct")
	if vent then
		local snd = vent:FindFirstChild("VentWhisper")
		if snd then
			snd:Destroy()
		end
	end

	if not currentGuestModel then
		return
	end

	if activeIdleConnection then
		activeIdleConnection:Disconnect()
		activeIdleConnection = nil
	end
	if blinkThread then
		task.cancel(blinkThread)
		blinkThread = nil
	end

	local guest = currentGuestModel
	local hrp = guest.PrimaryPart
	if not hrp then
		guest:Destroy()
		currentGuestModel = nil
		return
	end

	-- =========================================================================
	-- JUMP SCARE BREACH SEQUENCE (If an anomaly was erroneously admitted!)
	-- =========================================================================
	if admitted and isCurrentAnomaly then
		task.spawn(function()
			Atmosphere.playSound("heartbeat", nil, 1.0)
			Atmosphere.shakeCamera()
			local lungeCF = hrp.CFrame + Vector3.new(0, 0.45, 2.4)

			for _ = 1, 8 do
				hrp.CFrame = hrp.CFrame:Lerp(lungeCF, 0.35)
				for _, info in ipairs(currentPartInfos) do
					if info.part.Parent and info.part ~= hrp then
						info.part.CFrame = hrp.CFrame * info.baseCF
					end
				end
				task.wait(0.025)
			end

			guest:Destroy()
			if currentGuestModel == guest then
				currentGuestModel = nil
			end
		end)
		return
	end

	-- =========================================================================
	-- NATURAL DEPARTURE WALKOUT & ATMOSPHERIC FADE
	-- =========================================================================
	local targetPos = if admitted then HALLWAY_POS else EXIT_DOOR
	local targetCF = CFrame.lookAt(targetPos, targetPos + (targetPos - hrp.Position).Unit)

	if not admitted then
		animateEntranceDoors(true)
	end

	local startCF = hrp.CFrame
	local walkDuration = 2.2
	local startTime = os.clock()

	local state: AnimState = {
		legAngleL = 0,
		legAngleR = 0,
		armAngleL = 0,
		armAngleR = 0,
		armRollL = 0,
		armRollR = 0,
		torsoLift = 0,
		torsoPitch = 0,
		torsoYaw = 0,
		torsoRoll = 0,
		hipBob = 0,
		hipYaw = 0,
		headPitch = 0,
		headYaw = 0,
		headRoll = 0,
		headSnapCF = CFrame.identity,
	}

	activeWalkConnection = RunService.RenderStepped:Connect(function()
		local elapsed = os.clock() - startTime
		local alpha = math.clamp(elapsed / walkDuration, 0, 1)

		local currentPos = startCF.Position:Lerp(targetCF.Position, alpha)
		local walkPhase = elapsed * 8.5
		local bob = math.abs(math.sin(walkPhase)) * 0.18

		hrp.CFrame = CFrame.new(currentPos + Vector3.new(0, bob, 0), targetPos)

		local swing = math.sin(walkPhase) * math.rad(28)
		state.legAngleL = swing
		state.legAngleR = -swing
		state.armAngleL = -swing * 0.85
		state.armAngleR = swing * 0.85

		applyPose(hrp, state, 1.0, 1.0)

		-- Fade out transparency over the departure path
		local fadeAlpha = math.clamp((alpha - 0.4) / 0.6, 0, 1)
		for _, info in ipairs(currentPartInfos) do
			if info.part.Parent then
				info.part.Transparency = math.clamp(info.origTransparency + fadeAlpha, 0, 1)
			end
		end
		hrp.Transparency = math.clamp(fadeAlpha, 0, 1)

		if alpha >= 1 then
			if activeWalkConnection then
				activeWalkConnection:Disconnect()
				activeWalkConnection = nil
			end
			guest:Destroy()
			if currentGuestModel == guest then
				currentGuestModel = nil
			end
		end
	end)
end

function GuestRenderer.cleanup()
	if activeWalkConnection then
		activeWalkConnection:Disconnect()
		activeWalkConnection = nil
	end
	if activeIdleConnection then
		activeIdleConnection:Disconnect()
		activeIdleConnection = nil
	end
	if uvStateConnection then
		uvStateConnection:Disconnect()
		uvStateConnection = nil
	end
	if blinkThread then
		task.cancel(blinkThread)
		blinkThread = nil
	end
	if currentGuestModel then
		currentGuestModel:Destroy()
		currentGuestModel = nil
	end
	for _, fp in ipairs(footprints) do
		if fp and fp.Parent then
			fp:Destroy()
		end
	end
	table.clear(footprints)
	table.clear(currentPartInfos)
	table.clear(activeEyelids)
	table.clear(activeUvParts)
	table.clear(activeUvLights)
end

return GuestRenderer
