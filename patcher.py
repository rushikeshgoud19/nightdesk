import re

with open("src/client/GuestRenderer.luau", "r", encoding="utf-8") as f:
    code = f.read()

# 1. Remove build functions
start_str = "-- PROCEDURAL SCULPTING ARCHITECTURE"
end_str = "-- MAIN GUEST MODEL CONSTRUCTION"

idx_start = code.find(start_str)
idx_end = code.find(end_str)
if idx_start != -1 and idx_end != -1:
    code = code[:idx_start] + code[idx_end:]
else:
    print("Could not find start/end strings for deletion.")

# 2. Replace createGuestModel
create_start = code.find("local function createGuestModel(guestData: GuestData)")
create_end = code.find("local function animateEntranceDoors")

new_create_fn = """local function createGuestModel(guestData: GuestData): (Model, BasePart, number, number)
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
	local isHollow = false
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
		isHollow = true
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

	local torso = makePart("UpperTorso", Enum.PartType.Block, Vector3.new(2, 2, 1), baseCF * CFrame.new(0, 0, 0), suitColor, suitMat, 0, model)
	local shirt = makePart("Shirt", Enum.PartType.Block, Vector3.new(0.8, 1.8, 1.05), baseCF * CFrame.new(0, 0, 0), shirtColor, S.Shirt, 0, model)
	local tie = makePart("Tie", Enum.PartType.Block, Vector3.new(0.2, 1.4, 1.1), baseCF * CFrame.new(0, -0.1, 0), tieColor, S.Wool, 0, model)
	local belt = makePart("Belt", Enum.PartType.Block, Vector3.new(2.05, 0.2, 1.05), baseCF * CFrame.new(0, -0.9, 0), Color3.fromRGB(20, 20, 20), S.Leather, 0, model)
	local buckle = makePart("Buckle", Enum.PartType.Block, Vector3.new(0.3, 0.3, 1.1), baseCF * CFrame.new(0, -0.9, 0), Color3.fromRGB(200, 200, 200), S.Brass, 0, model)

	local legL = makePart("LeftUpperLeg", Enum.PartType.Block, Vector3.new(0.9, 2, 1), baseCF * CFrame.new(-0.5, -2, 0), pantsColor, suitMat, 0, model)
	local legR = makePart("RightUpperLeg", Enum.PartType.Block, Vector3.new(0.9, 2, 1), baseCF * CFrame.new(0.5, -2, 0), pantsColor, suitMat, 0, model)

	local shoeL = makePart("LeftShoe", Enum.PartType.Block, Vector3.new(0.95, 0.4, 1.2), baseCF * CFrame.new(-0.5, -3.2, -0.1), Color3.fromRGB(15, 15, 15), S.Shoe, 0, model)
	local shoeR = makePart("RightShoe", Enum.PartType.Block, Vector3.new(0.95, 0.4, 1.2), baseCF * CFrame.new(0.5, -3.2, -0.1), Color3.fromRGB(15, 15, 15), S.Shoe, 0, model)

	local armL = makePart("LeftUpperArm", Enum.PartType.Block, Vector3.new(1, 2, 1), baseCF * CFrame.new(-1.5, 0, 0), suitColor, suitMat, 0, model)
	local armR = makePart("RightUpperArm", Enum.PartType.Block, Vector3.new(1, 2, 1), baseCF * CFrame.new(1.5, 0, 0), suitColor, suitMat, 0, model)

	local handL = makePart("LeftHand", Enum.PartType.Block, Vector3.new(0.8, 0.4, 0.8), baseCF * CFrame.new(-1.5, -1.2, 0), skinColor, S.Skin, 0, model)
	local handR = makePart("RightHand", Enum.PartType.Block, Vector3.new(0.8, 0.4, 0.8), baseCF * CFrame.new(1.5, -1.2, 0), skinColor, S.Skin, 0, model)

	local headScaleY = if isMandela then 2.0 else 1.2
	local headOffset = if isMandela then -0.4 else 0
	local head = makePart("Head", Enum.PartType.Block, Vector3.new(1.2, headScaleY, 1.2), baseCF * CFrame.new(0, 1.6 + headOffset, 0), skinColor, S.Skin, 0, model)

	if isMandela then
		local void = makePart("HeadVoid", Enum.PartType.Block, Vector3.new(1.25, 0.8, 1.25), baseCF * CFrame.new(0, 1.0, 0), Color3.new(0, 0, 0), S.Gloss, 0, model)
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
		table.insert(activeEyelids, faceDecal)
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

	local hair = Instance.new("MeshPart")
	hair.Name = "Hair"
	hair.MeshId = hairMeshId
	hair.Size = Vector3.new(1.4, 0.8, 1.4)
	hair.CFrame = head.CFrame * CFrame.new(0, (headScaleY/2) + 0.1, 0)
	hair.Color = hairColor
	Materials.applySurface(hair, S.Hair)
	hair.Anchored = true
	hair.CanCollide = false
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
"""
code = code[:create_start] + new_create_fn + code[create_end:]

# 3. Update blinking logic
blink_target = """for _, lid in ipairs(activeEyelids) do
							if lid.Parent then
								lid.Size = Vector3.new(lid.Size.X, 0.12 * scaleH, lid.Size.Z)
							end
						end
						task.wait(0.12)
						for _, lid in ipairs(activeEyelids) do
							if lid.Parent then
								lid.Size = Vector3.new(lid.Size.X, 0.03 * scaleH, lid.Size.Z)
							end
						end"""
blink_replacement = """for _, face in ipairs(activeEyelids) do
							if face.Parent then
								face.Texture = face:GetAttribute("BlinkTexture") or ""
							end
						end
						task.wait(0.12)
						for _, face in ipairs(activeEyelids) do
							if face.Parent then
								face.Texture = face:GetAttribute("BaseTexture") or ""
							end
						end"""
if blink_target in code:
    code = code.replace(blink_target, blink_replacement)
else:
    print("Could not find blink loop.")
    
with open("src/client/GuestRenderer.luau", "w", encoding="utf-8") as f:
    f.write(code)

print("Patched successfully.")
