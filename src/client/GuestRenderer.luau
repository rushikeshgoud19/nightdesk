--!strict
-- 3D High-Fidelity Guest Renderer & Cinematic Horror Mob Architecture for nightdesk
-- Constructs authentic R15 Humanoid Guests with sculpted anatomical facial contours,
-- tailored executive overcoats, 3D collared shirts, tapered neckties, articulated hands/fingers,
-- executive briefcases, natural breathing physics, eye blinking, gaze micro-saccades,
-- and the 6 Core Cinematic Horror Mob Archetypes.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Materials = require(Shared:WaitForChild("Materials"))
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
	visualSeed: number?,
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

local S = Materials.guest

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
	surface: Materials.Surface,
	transparency: number,
	parent: Instance
): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Shape = shape
	p.Size = size
	p.CFrame = cf
	p.Color = color
	Materials.applySurface(p, surface)
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
	Materials.applySurface(p, S.Gloss)
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
-- MAIN GUEST MODEL CONSTRUCTION
-- =============================================================================

local function createGuestModel(guestData: GuestData): (Model, BasePart, number, number)
	local rng = Random.new(guestData.visualSeed or 1)
	local skinColor = SKIN_TONES[rng:NextInteger(1, #SKIN_TONES)]
	local suitColor = SUIT_PALETTES[rng:NextInteger(1, #SUIT_PALETTES)]
	local shirtColor = SHIRT_PALETTES[rng:NextInteger(1, #SHIRT_PALETTES)]
	local pantsColor = PANTS_PALETTES[rng:NextInteger(1, #PANTS_PALETTES)]
	local tieColor = TIE_PALETTES[rng:NextInteger(1, #TIE_PALETTES)]
	local hairColor = HAIR_COLORS[rng:NextInteger(1, #HAIR_COLORS)]
	
	local HAIR_MESHES = {
		"rbxassetid://113756968918441",
		"rbxassetid://100645125889787",
		"rbxassetid://104867370093409"
	}
	local hairMeshId = HAIR_MESHES[rng:NextInteger(1, #HAIR_MESHES)]

	local anomalyId = guestData.anomalyId
	isCurrentAnomaly = anomalyId ~= nil

	local faceTexture = "rbxassetid://108872266733797" -- base
		local isMimic = false
	local isMandela = false
	local isBrokenNeck = false
	local isDrowned = false
	local isVoid = false
	local isBlinkEnabled = true

	if anomalyId == "colorless_skin" then
		skinColor = Color3.fromRGB(224, 226, 232)
	elseif anomalyId == "asymmetric_face" then
		faceTexture = "rbxassetid://72324569366732"
	elseif anomalyId == "dilated_pupils" then
		faceTexture = "rbxassetid://92790091595384"
	elseif anomalyId == "dark_sclera" then
		faceTexture = "rbxassetid://72653150459077"
	elseif anomalyId == "subtle_smile" then
		faceTexture = "rbxassetid://133455652046697"
	elseif anomalyId == "no_blinking" then
		isBlinkEnabled = false
	elseif anomalyId == "wet_clothing" or anomalyId == "drowned_drifter" then
		isDrowned = true
	elseif anomalyId == "flayed_mimic" then
		isMimic = true
		skinColor = Color3.fromRGB(200, 200, 200)
		faceTexture = "rbxassetid://76726493000690" -- uv mimic
	elseif anomalyId == "cavernous_hollow" then
		faceTexture = "rbxassetid://123991119403253"
	elseif anomalyId == "void_silhouette" or anomalyId == "shadow_entity" then
		isVoid = true
	elseif anomalyId == "mandela_alternate" then
		isMandela = true
	elseif anomalyId == "broken_cervical" then
		isBrokenNeck = true
	end

	local model = Instance.new("Model")
	model.Name = `Guest_{guestData.name}`

	local hrp = makePart("HumanoidRootPart", Enum.PartType.Block, Vector3.new(2, 2, 1), CFrame.new(SPAWN_POS), Color3.new(), S.Gloss, 1, model)
	model.PrimaryPart = hrp
	model:PivotTo(CFrame.lookAt(SPAWN_POS, DESK_POS))
	
	local baseCF = hrp.CFrame
	local suitMat = if isDrowned then S.WetSuit else S.Suit

	if isVoid then
		skinColor = Color3.new(0, 0, 0)
		suitColor = Color3.new(0, 0, 0)
		shirtColor = Color3.new(0, 0, 0)
		pantsColor = Color3.new(0, 0, 0)
		tieColor = Color3.new(0, 0, 0)
		hairColor = Color3.new(0, 0, 0)
		suitMat = S.Gloss
	end

	makePart("UpperTorso", Enum.PartType.Block, Vector3.new(2, 2, 1), baseCF * CFrame.new(0, 0, 0), suitColor, suitMat, 0, model)
	makePart("Shirt", Enum.PartType.Block, Vector3.new(0.8, 1.8, 1.05), baseCF * CFrame.new(0, 0, 0), shirtColor, S.Shirt, 0, model)
	makePart("Tie", Enum.PartType.Block, Vector3.new(0.2, 1.4, 1.1), baseCF * CFrame.new(0, -0.1, 0), tieColor, S.Wool, 0, model)
	makePart("Belt", Enum.PartType.Block, Vector3.new(2.05, 0.2, 1.05), baseCF * CFrame.new(0, -0.9, 0), Color3.fromRGB(20, 20, 20), S.Leather, 0, model)
	makePart("Buckle", Enum.PartType.Block, Vector3.new(0.3, 0.3, 1.1), baseCF * CFrame.new(0, -0.9, 0), Color3.fromRGB(200, 200, 200), S.Brass, 0, model)

	makePart("LeftUpperLeg", Enum.PartType.Block, Vector3.new(0.9, 2, 1), baseCF * CFrame.new(-0.5, -2, 0), pantsColor, suitMat, 0, model)
	makePart("RightUpperLeg", Enum.PartType.Block, Vector3.new(0.9, 2, 1), baseCF * CFrame.new(0.5, -2, 0), pantsColor, suitMat, 0, model)

	makePart("LeftShoe", Enum.PartType.Block, Vector3.new(0.95, 0.4, 1.2), baseCF * CFrame.new(-0.5, -3.2, -0.1), Color3.fromRGB(15, 15, 15), S.Shoe, 0, model)
	makePart("RightShoe", Enum.PartType.Block, Vector3.new(0.95, 0.4, 1.2), baseCF * CFrame.new(0.5, -3.2, -0.1), Color3.fromRGB(15, 15, 15), S.Shoe, 0, model)

	makePart("LeftUpperArm", Enum.PartType.Block, Vector3.new(1, 2, 1), baseCF * CFrame.new(-1.5, 0, 0), suitColor, suitMat, 0, model)
	makePart("RightUpperArm", Enum.PartType.Block, Vector3.new(1, 2, 1), baseCF * CFrame.new(1.5, 0, 0), suitColor, suitMat, 0, model)

	local handL = makePart("LeftHand", Enum.PartType.Block, Vector3.new(0.8, 0.4, 0.8), baseCF * CFrame.new(-1.5, -1.2, 0), skinColor, S.Skin, 0, model)
	local handR = makePart("RightHand", Enum.PartType.Block, Vector3.new(0.8, 0.4, 0.8), baseCF * CFrame.new(1.5, -1.2, 0), skinColor, S.Skin, 0, model)

	local headScaleY = if isMandela then 2.0 else 1.2
	local headOffset = if isMandela then -0.4 else 0
	local head = makePart("Head", Enum.PartType.Block, Vector3.new(1.2, headScaleY, 1.2), baseCF * CFrame.new(0, 1.6 + headOffset, 0), skinColor, S.Skin, 0, model)

	if isMandela then
		makePart("HeadVoid", Enum.PartType.Block, Vector3.new(1.25, 0.8, 1.25), baseCF * CFrame.new(0, 1.0, 0), Color3.new(0, 0, 0), S.Gloss, 0, model)
	end

	if isVoid then
		head.Color = Color3.new(0, 0, 0)
		handL.Color = Color3.new(0, 0, 0)
		handR.Color = Color3.new(0, 0, 0)
		Materials.applySurface(head, S.Gloss)
		Materials.applySurface(handL, S.Gloss)
		Materials.applySurface(handR, S.Gloss)
		faceTexture = "rbxassetid://108872266733797" -- cyan faces will be handled by Color3 tint
	end
    
    if isBrokenNeck then
        head.CFrame = head.CFrame * CFrame.Angles(0, 0, math.rad(85))
    end

	local faceDecal = Instance.new("Decal")
	faceDecal.Name = "face"
	faceDecal.Face = Enum.NormalId.Front
	faceDecal.Texture = faceTexture
	faceDecal.Parent = head
    if isVoid then
        faceDecal.Color3 = Color3.fromRGB(0, 255, 255)
    end
	
	table.clear(activeEyelids)
	table.clear(activeUvParts)
	
	if isBlinkEnabled then
		faceDecal:SetAttribute("BaseTexture", faceTexture)
		faceDecal:SetAttribute("BlinkTexture", "rbxassetid://106023531620267")
		table.insert(activeEyelids, { face = faceDecal })
	end

	if isMimic then
		local uvDecal = Instance.new("Decal")
		uvDecal.Name = "UVMimic"
		uvDecal.Face = Enum.NormalId.Front
		uvDecal.Texture = "rbxassetid://76726493000690" -- mimic suture
		uvDecal.Transparency = 1
		uvDecal.Parent = head
		table.insert(activeUvParts, uvDecal)
	end

	local hair = Instance.new("Part")
	hair.Name = "Hair"
	hair.Size = Vector3.new(1.4, 0.8, 1.4)
	hair.CFrame = head.CFrame * CFrame.new(0, (headScaleY/2) + 0.1, 0)
	hair.Color = hairColor
	Materials.applySurface(hair, S.Hair)
	hair.Anchored = true
	hair.CanCollide = false
	hair.Transparency = 1 -- Hide the block itself, show the mesh
	
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.FileMesh
	mesh.MeshId = hairMeshId
	mesh.Scale = Vector3.new(1.4, 0.8, 1.4)
	mesh.TextureId = ""
	mesh.VertexColor = Vector3.new(hairColor.R, hairColor.G, hairColor.B)
	mesh.Parent = hair
	
	hair.Parent = model

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

	if isDrowned then
		spawnFootprint(SPAWN_POS)
		spawnFootprint(SPAWN_POS + Vector3.new(0, 0, -2))
        local emitter = Instance.new("ParticleEmitter")
        emitter.Texture = "rbxassetid://243660364" 
        emitter.Color = ColorSequence.new(Color3.fromRGB(20, 20, 20))
        emitter.Size = NumberSequence.new(0.05)
        emitter.Rate = 10
        emitter.Speed = NumberRange.new(0)
        emitter.Acceleration = Vector3.new(0, -5, 0)
        emitter.Lifetime = NumberRange.new(1, 2)
        emitter.Parent = hrp
	end

	return model, hrp, 1.0, 1.0
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
							local face = lid.face
							if face and face.Parent then
								face.Texture = face:GetAttribute("BlinkTexture") or ""
							end
						end
						task.wait(0.12)
						for _, lid in ipairs(activeEyelids) do
							local face = lid.face
							if face and face.Parent then
								face.Texture = face:GetAttribute("BaseTexture") or ""
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
