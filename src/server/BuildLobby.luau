--!strict
-- Server-authoritative Motel Master Builder for nightdesk
-- Constructs the complete 3D Highway Motel lobby:
-- 1. Reception counter with polished wood grain, brass trim, pillars, and clerk back-office.
-- 2. Hallway archway with long corridor leading to numbered guest room doors (Rooms 101–104 ground floor, Rooms 105–108 upstairs).
-- 3. Waiting lounge with velvet sofa, coffee table, potted fern, and glowing vending machine.
-- 4. Frosted glass double doors with brass handles.
-- 5. Key rack cubby with 8 numbered brass hooks and room tags.
-- 6. Exterior highway environment: wet slate asphalt parking lot, downward rain particles, and glowing red MOTEL VACANCY neon sign.
-- 7. Balanced lighting: ceiling fixture with Future-technology Spotlight and ambient fill, green banker desk lamp, and hallway sconce lights.
-- 8. Spawn point at (0, 3.5, 7.5) facing the desk counter.

local Workspace = game:GetService("Workspace")

local function buildLobby(): Model
	-- Strip what the Studio template left behind. Rojo only manages what the
	-- project file declares, so template leftovers survive every sync and never
	-- appear in git -- you find them only by reading the live DataModel.
	--
	-- The stray SpawnLocation matters more than the baseplate. Roblox picks at
	-- random among every enabled neutral SpawnLocation, so a leftover one sends
	-- roughly half of all spawns somewhere that is not behind the desk -- and
	-- since the baseplate is destroyed in this same pass, that somewhere has no
	-- floor under it. This project owns exactly one spawn, and it is named "Spawn".
	for _, child in Workspace:GetChildren() do
		local isBaseplate = child.Name == "Baseplate"
			or (child:IsA("BasePart") and child.Name:lower():find("baseplate") ~= nil)
		local isStraySpawn = child:IsA("SpawnLocation") and child.Name ~= "Spawn"

		if isBaseplate or isStraySpawn then
			child:Destroy()
		end
	end

	local existing = Workspace:FindFirstChild("Lobby")
	if existing then
		existing:Destroy()
	end

	local lobby = Instance.new("Model")
	lobby.Name = "Lobby"

	local function makePart(
		name: string,
		shape: Enum.PartType,
		size: Vector3,
		cf: CFrame,
		color: Color3,
		material: Enum.Material,
		parent: Instance?
	): Part
		local p = Instance.new("Part")
		p.Name = name
		p.Shape = shape
		p.Size = size
		p.CFrame = cf
		p.Color = color
		p.Material = material
		p.Anchored = true
		p.CanCollide = true
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = parent or lobby
		return p
	end

	local function makeCustomPart(
		name: string,
		shape: Enum.PartType,
		size: Vector3,
		cf: CFrame,
		color: Color3,
		material: Enum.Material,
		transparency: number,
		canCollide: boolean,
		parent: Instance?
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
		p.CanCollide = canCollide
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = parent or lobby
		return p
	end

	local function makeSconce(name: string, cf: CFrame, parent: Instance?)
		local sconceModel = Instance.new("Model")
		sconceModel.Name = name

		-- Brass wall mount plate
		makePart(
			"Mount",
			Enum.PartType.Block,
			Vector3.new(0.6, 1.2, 0.15),
			cf,
			Color3.fromRGB(195, 160, 65),
			Enum.Material.Metal,
			sconceModel
		)
		-- Brass curved arm
		makePart(
			"Arm",
			Enum.PartType.Block,
			Vector3.new(0.2, 0.2, 0.7),
			cf * CFrame.new(0, -0.2, 0.4),
			Color3.fromRGB(195, 160, 65),
			Enum.Material.Metal,
			sconceModel
		)
		-- Frosted glass lamp shade
		local shade = makeCustomPart(
			"Shade",
			Enum.PartType.Cylinder,
			Vector3.new(0.8, 0.7, 0.7),
			cf * CFrame.new(0, 0.2, 0.7) * CFrame.Angles(0, 0, math.rad(90)),
			Color3.fromRGB(245, 235, 210),
			Enum.Material.Neon,
			0.15,
			false,
			sconceModel
		)

		-- Directional downward/ambient SpotLight
		local sLight = Instance.new("SpotLight")
		sLight.Name = "SconceSpotLight"
		sLight.Face = Enum.NormalId.Bottom
		sLight.Color = Color3.fromRGB(255, 220, 160)
		sLight.Brightness = 2.4
		sLight.Range = 15
		sLight.Angle = 85
		sLight.Shadows = true
		sLight.Parent = shade

		local pLight = Instance.new("PointLight")
		pLight.Name = "SconceGlow"
		pLight.Color = Color3.fromRGB(255, 215, 150)
		pLight.Brightness = 0.8
		pLight.Range = 8
		pLight.Shadows = false
		pLight.Parent = shade

		sconceModel.Parent = parent or lobby
	end

	local function makeDoor(roomNumber: string, cf: CFrame, parent: Instance?): Model
		local doorModel = Instance.new("Model")
		doorModel.Name = `Door_Room{roomNumber}`

		-- Outer wooden door frame
		makePart(
			"FrameLeft",
			Enum.PartType.Block,
			Vector3.new(0.4, 9.2, 0.4),
			cf * CFrame.new(-2.0, 0, 0),
			Color3.fromRGB(38, 26, 18),
			Enum.Material.Wood,
			doorModel
		)
		makePart(
			"FrameRight",
			Enum.PartType.Block,
			Vector3.new(0.4, 9.2, 0.4),
			cf * CFrame.new(2.0, 0, 0),
			Color3.fromRGB(38, 26, 18),
			Enum.Material.Wood,
			doorModel
		)
		makePart(
			"FrameTop",
			Enum.PartType.Block,
			Vector3.new(4.4, 0.4, 0.4),
			cf * CFrame.new(0, 4.4, 0),
			Color3.fromRGB(38, 26, 18),
			Enum.Material.Wood,
			doorModel
		)

		-- Main wooden door slab
		makePart(
			"DoorPanel",
			Enum.PartType.Block,
			Vector3.new(3.6, 8.8, 0.25),
			cf,
			Color3.fromRGB(48, 32, 22),
			Enum.Material.WoodPlanks,
			doorModel
		)

		-- Recessed door moulding accents
		makePart(
			"MouldingUpper",
			Enum.PartType.Block,
			Vector3.new(2.8, 3.2, 0.30),
			cf * CFrame.new(0, 1.8, 0),
			Color3.fromRGB(36, 24, 16),
			Enum.Material.Wood,
			doorModel
		)
		makePart(
			"MouldingLower",
			Enum.PartType.Block,
			Vector3.new(2.8, 3.2, 0.30),
			cf * CFrame.new(0, -1.8, 0),
			Color3.fromRGB(36, 24, 16),
			Enum.Material.Wood,
			doorModel
		)

		-- Brass doorknob & escutcheon
		makePart(
			"Doorknob",
			Enum.PartType.Ball,
			Vector3.new(0.35, 0.35, 0.35),
			cf * CFrame.new(1.3, -0.2, 0.22),
			Color3.fromRGB(215, 180, 60),
			Enum.Material.Metal,
			doorModel
		)
		makePart(
			"KeyholePlate",
			Enum.PartType.Block,
			Vector3.new(0.25, 0.6, 0.05),
			cf * CFrame.new(1.3, -0.2, 0.16),
			Color3.fromRGB(215, 180, 60),
			Enum.Material.Metal,
			doorModel
		)

		-- Brass Room Number Plaque
		local plaque = makePart(
			"NumberPlaque",
			Enum.PartType.Block,
			Vector3.new(1.2, 0.55, 0.06),
			cf * CFrame.new(0, 2.2, 0.18),
			Color3.fromRGB(220, 185, 65),
			Enum.Material.Metal,
			doorModel
		)

		local plaqueGui = Instance.new("SurfaceGui")
		plaqueGui.Face = Enum.NormalId.Front
		plaqueGui.CanvasSize = Vector2.new(200, 90)
		plaqueGui.Parent = plaque

		local plaqueLabel = Instance.new("TextLabel")
		plaqueLabel.Size = UDim2.fromScale(1, 1)
		plaqueLabel.BackgroundTransparency = 1
		plaqueLabel.Font = Enum.Font.SpecialElite
		plaqueLabel.Text = roomNumber
		plaqueLabel.TextColor3 = Color3.fromRGB(25, 20, 15)
		plaqueLabel.TextSize = 52
		plaqueLabel.Parent = plaqueGui

		doorModel.Parent = parent or lobby
		return doorModel
	end

	-- =========================================================================
	-- 1. MAIN LOBBY ARCHITECTURE: FLOOR, CEILING, WALLS, AND MOULDING
	-- =========================================================================
	-- Floor & Velvet Carpet Runner
	makePart(
		"Floor",
		Enum.PartType.Block,
		Vector3.new(36, 1, 32),
		CFrame.new(0, 0, -1),
		Color3.fromRGB(36, 32, 28),
		Enum.Material.WoodPlanks
	)
	makePart(
		"CarpetRunner",
		Enum.PartType.Block,
		Vector3.new(6, 0.05, 18),
		CFrame.new(0, 0.52, -4.5),
		Color3.fromRGB(95, 24, 24),
		Enum.Material.Fabric
	)

	-- Ceiling
	makePart(
		"Ceiling",
		Enum.PartType.Block,
		Vector3.new(36, 1, 32),
		CFrame.new(0, 14.5, -1),
		Color3.fromRGB(26, 26, 28),
		Enum.Material.Plaster
	)

	-- Back Wall behind clerk office (Z = 14.5)
	makePart(
		"WallBack",
		Enum.PartType.Block,
		Vector3.new(36, 14, 1),
		CFrame.new(0, 7.5, 14.5),
		Color3.fromRGB(48, 34, 24),
		Enum.Material.WoodPlanks
	)
	-- Back Wall baseboards & crown moulding
	makePart(
		"WallBack_Baseboard",
		Enum.PartType.Block,
		Vector3.new(36, 0.8, 0.2),
		CFrame.new(0, 0.9, 13.9),
		Color3.fromRGB(32, 22, 16),
		Enum.Material.Wood
	)
	makePart(
		"WallBack_CrownMoulding",
		Enum.PartType.Block,
		Vector3.new(36, 0.6, 0.3),
		CFrame.new(0, 13.7, 13.85),
		Color3.fromRGB(32, 22, 16),
		Enum.Material.Wood
	)

	-- Left Wall (X = -18) with Hallway Archway opening
	makePart(
		"WallLeft_Front",
		Enum.PartType.Block,
		Vector3.new(1, 14, 14),
		CFrame.new(-18, 7.5, -8),
		Color3.fromRGB(40, 38, 36),
		Enum.Material.Plaster
	)
	makePart(
		"WallLeft_Back",
		Enum.PartType.Block,
		Vector3.new(1, 14, 10),
		CFrame.new(-18, 7.5, 9),
		Color3.fromRGB(40, 38, 36),
		Enum.Material.Plaster
	)
	makePart(
		"WallLeft_Top",
		Enum.PartType.Block,
		Vector3.new(1, 4, 8),
		CFrame.new(-18, 12.5, 1),
		Color3.fromRGB(40, 38, 36),
		Enum.Material.Plaster
	)

	-- Archway trim pillars and lintel at X = -18
	makePart(
		"ArchPillarFront",
		Enum.PartType.Block,
		Vector3.new(1.3, 10.5, 0.6),
		CFrame.new(-18, 5.75, -2.7),
		Color3.fromRGB(48, 34, 24),
		Enum.Material.Wood
	)
	makePart(
		"ArchPillarBack",
		Enum.PartType.Block,
		Vector3.new(1.3, 10.5, 0.6),
		CFrame.new(-18, 5.75, 4.7),
		Color3.fromRGB(48, 34, 24),
		Enum.Material.Wood
	)
	makePart(
		"ArchLintel",
		Enum.PartType.Block,
		Vector3.new(1.4, 0.8, 8.0),
		CFrame.new(-18, 10.8, 1.0),
		Color3.fromRGB(48, 34, 24),
		Enum.Material.Wood
	)

	-- Right Wall (X = 18) with wainscoting and framed art
	makePart(
		"WallRight",
		Enum.PartType.Block,
		Vector3.new(1, 14, 32),
		CFrame.new(18, 7.5, -1),
		Color3.fromRGB(40, 38, 36),
		Enum.Material.Plaster
	)
	makePart(
		"WallRight_Wainscot",
		Enum.PartType.Block,
		Vector3.new(0.2, 4.2, 32),
		CFrame.new(17.4, 2.6, -1),
		Color3.fromRGB(44, 30, 20),
		Enum.Material.Wood
	)
	makePart(
		"WallRight_Baseboard",
		Enum.PartType.Block,
		Vector3.new(0.3, 0.8, 32),
		CFrame.new(17.35, 0.9, -1),
		Color3.fromRGB(32, 22, 16),
		Enum.Material.Wood
	)

	-- Framed Highway Landscape Artwork on Right Wall
	local artFrame = makePart(
		"LobbyArtwork_Frame",
		Enum.PartType.Block,
		Vector3.new(0.2, 4.5, 7.5),
		CFrame.new(17.4, 7.8, -4.0),
		Color3.fromRGB(48, 34, 22),
		Enum.Material.Wood
	)
	local artCanvas = makePart(
		"LobbyArtwork_Canvas",
		Enum.PartType.Block,
		Vector3.new(0.05, 3.9, 6.9),
		CFrame.new(17.28, 7.8, -4.0),
		Color3.fromRGB(32, 42, 48),
		Enum.Material.SmoothPlastic
	)
	local artGui = Instance.new("SurfaceGui")
	artGui.Face = Enum.NormalId.Left
	artGui.CanvasSize = Vector2.new(460, 260)
	artGui.Parent = artCanvas
	local artLabel = Instance.new("TextLabel")
	artLabel.Size = UDim2.fromScale(1, 1)
	artLabel.BackgroundColor3 = Color3.fromRGB(30, 40, 46)
	artLabel.Font = Enum.Font.SpecialElite
	artLabel.Text = "★ PACIFIC NORTHWEST HIGHWAY 9 ★\nEST. 1964"
	artLabel.TextColor3 = Color3.fromRGB(220, 205, 175)
	artLabel.TextSize = 22
	artLabel.Parent = artGui

	-- Brass picture light over artwork
	makePart(
		"ArtPictureLight",
		Enum.PartType.Block,
		Vector3.new(0.6, 0.2, 3.2),
		CFrame.new(17.1, 10.3, -4.0),
		Color3.fromRGB(210, 175, 60),
		Enum.Material.Metal
	)
	local artSpot = Instance.new("SpotLight")
	artSpot.Face = Enum.NormalId.Bottom
	artSpot.Color = Color3.fromRGB(255, 230, 175)
	artSpot.Brightness = 1.8
	artSpot.Range = 8
	artSpot.Angle = 60
	artSpot.Shadows = true
	artSpot.Parent = artFrame

	-- Front Wall with double entrance doors (Z = -16.5)
	makePart(
		"WallFront_Left",
		Enum.PartType.Block,
		Vector3.new(14, 14, 1),
		CFrame.new(-11, 7.5, -16.5),
		Color3.fromRGB(40, 38, 36),
		Enum.Material.Plaster
	)
	makePart(
		"WallFront_Right",
		Enum.PartType.Block,
		Vector3.new(14, 14, 1),
		CFrame.new(11, 7.5, -16.5),
		Color3.fromRGB(40, 38, 36),
		Enum.Material.Plaster
	)
	makePart(
		"WallFront_Top",
		Enum.PartType.Block,
		Vector3.new(8, 4, 1),
		CFrame.new(0, 12.5, -16.5),
		Color3.fromRGB(40, 38, 36),
		Enum.Material.Plaster
	)

	-- Frosted Glass Entrance Doors & Heavy Brass Handles
	makeCustomPart(
		"GlassDoorL",
		Enum.PartType.Block,
		Vector3.new(3.8, 10, 0.2),
		CFrame.new(-1.9, 5.5, -16.5),
		Color3.fromRGB(170, 205, 220),
		Enum.Material.Glass,
		0.65,
		true
	)
	makeCustomPart(
		"GlassDoorR",
		Enum.PartType.Block,
		Vector3.new(3.8, 10, 0.2),
		CFrame.new(1.9, 5.5, -16.5),
		Color3.fromRGB(170, 205, 220),
		Enum.Material.Glass,
		0.65,
		true
	)

	-- Brass door kickplates
	makePart(
		"DoorKickplateL",
		Enum.PartType.Block,
		Vector3.new(3.7, 1.2, 0.24),
		CFrame.new(-1.9, 1.1, -16.5),
		Color3.fromRGB(210, 175, 60),
		Enum.Material.Metal
	)
	makePart(
		"DoorKickplateR",
		Enum.PartType.Block,
		Vector3.new(3.7, 1.2, 0.24),
		CFrame.new(1.9, 1.1, -16.5),
		Color3.fromRGB(210, 175, 60),
		Enum.Material.Metal
	)

	-- Brass Door Handles (Interior & Exterior)
	makePart(
		"DoorHandleL",
		Enum.PartType.Cylinder,
		Vector3.new(1.4, 0.08, 0.08),
		CFrame.new(-0.3, 5.2, -16.3) * CFrame.Angles(math.rad(90), 0, 0),
		Color3.fromRGB(210, 175, 60),
		Enum.Material.Metal
	)
	makePart(
		"DoorHandleR",
		Enum.PartType.Cylinder,
		Vector3.new(1.4, 0.08, 0.08),
		CFrame.new(0.3, 5.2, -16.3) * CFrame.Angles(math.rad(90), 0, 0),
		Color3.fromRGB(210, 175, 60),
		Enum.Material.Metal
	)
	makePart(
		"DoorHandleExtL",
		Enum.PartType.Cylinder,
		Vector3.new(1.4, 0.08, 0.08),
		CFrame.new(-0.3, 5.2, -16.7) * CFrame.Angles(math.rad(90), 0, 0),
		Color3.fromRGB(210, 175, 60),
		Enum.Material.Metal
	)
	makePart(
		"DoorHandleExtR",
		Enum.PartType.Cylinder,
		Vector3.new(1.4, 0.08, 0.08),
		CFrame.new(0.3, 5.2, -16.7) * CFrame.Angles(math.rad(90), 0, 0),
		Color3.fromRGB(210, 175, 60),
		Enum.Material.Metal
	)

	-- =========================================================================
	-- 2. HALLWAY CORRIDOR & NUMBERED GUEST ROOM DOORS (ROOMS 101–108)
	-- =========================================================================
	-- Corridor extending West from X = -18 to X = -54, Z = -3 to 9 (Width = 12, Length = 36)
	makePart(
		"HallwayFloor",
		Enum.PartType.Block,
		Vector3.new(36, 1, 12),
		CFrame.new(-36, 0, 3),
		Color3.fromRGB(34, 30, 26),
		Enum.Material.WoodPlanks
	)
	makePart(
		"HallwayCarpetRunner",
		Enum.PartType.Block,
		Vector3.new(34, 0.05, 5),
		CFrame.new(-35, 0.52, 3),
		Color3.fromRGB(88, 22, 22),
		Enum.Material.Fabric
	)
	makePart(
		"HallwayCeiling",
		Enum.PartType.Block,
		Vector3.new(36, 1, 12),
		CFrame.new(-36, 14.5, 3),
		Color3.fromRGB(26, 26, 28),
		Enum.Material.Plaster
	)
	makePart(
		"HallwayWallNorth",
		Enum.PartType.Block,
		Vector3.new(36, 14, 1),
		CFrame.new(-36, 7.5, 9),
		Color3.fromRGB(42, 40, 38),
		Enum.Material.Plaster
	)
	makePart(
		"HallwayWallSouth",
		Enum.PartType.Block,
		Vector3.new(36, 14, 1),
		CFrame.new(-36, 7.5, -3),
		Color3.fromRGB(42, 40, 38),
		Enum.Material.Plaster
	)
	makePart(
		"HallwayWallWestEnd",
		Enum.PartType.Block,
		Vector3.new(1, 14, 12),
		CFrame.new(-54, 7.5, 3),
		Color3.fromRGB(42, 40, 38),
		Enum.Material.Plaster
	)

	-- Corridor Wainscoting
	makePart(
		"HallwayWainscotNorth",
		Enum.PartType.Block,
		Vector3.new(36, 3.8, 0.2),
		CFrame.new(-36, 2.4, 8.4),
		Color3.fromRGB(44, 30, 20),
		Enum.Material.Wood
	)
	makePart(
		"HallwayWainscotSouth",
		Enum.PartType.Block,
		Vector3.new(36, 3.8, 0.2),
		CFrame.new(-36, 2.4, -2.4),
		Color3.fromRGB(44, 30, 20),
		Enum.Material.Wood
	)

	-- Ground Floor Guest Room Doors: Rooms 101, 102, 103, 104
	makeDoor("101", CFrame.new(-24, 5.1, 8.85), lobby)
	makeDoor("102", CFrame.new(-24, 5.1, -2.85) * CFrame.Angles(0, math.rad(180), 0), lobby)
	makeDoor("103", CFrame.new(-34, 5.1, 8.85), lobby)
	makeDoor("104", CFrame.new(-34, 5.1, -2.85) * CFrame.Angles(0, math.rad(180), 0), lobby)

	-- Staircase rising to second floor mezzanine (X = -42 to -50, Z = 3)
	for s = 1, 10 do
		local xStep = -41.5 - (s - 1) * 0.95
		local yStep = 0.5 + s * 0.75
		local stepPart = makePart(
			`StairStep_{s}`,
			Enum.PartType.Block,
			Vector3.new(1.0, 0.75, 4.8),
			CFrame.new(xStep, yStep, 3),
			Color3.fromRGB(44, 30, 20),
			Enum.Material.Wood
		)
		-- Carpet step tread
		makePart(
			`StairCarpet_{s}`,
			Enum.PartType.Block,
			Vector3.new(0.9, 0.05, 3.6),
			CFrame.new(xStep, yStep + 0.38, 3),
			Color3.fromRGB(88, 22, 22),
			Enum.Material.Fabric,
			stepPart
		)
	end

	-- Brass Staircase Handrail & Spindles
	makePart(
		"StairHandrailNorth",
		Enum.PartType.Block,
		Vector3.new(11.5, 0.15, 0.15),
		CFrame.new(-46.0, 5.2, 5.4) * CFrame.Angles(0, 0, math.rad(38)),
		Color3.fromRGB(210, 175, 60),
		Enum.Material.Metal
	)
	makePart(
		"StairHandrailSouth",
		Enum.PartType.Block,
		Vector3.new(11.5, 0.15, 0.15),
		CFrame.new(-46.0, 5.2, 0.6) * CFrame.Angles(0, 0, math.rad(38)),
		Color3.fromRGB(210, 175, 60),
		Enum.Material.Metal
	)

	-- Upper Floor Mezzanine Landing Platform (Y = 8.0, X = -50 to -54, Z = -3 to 9)
	makePart(
		"UpperMezzanineFloor",
		Enum.PartType.Block,
		Vector3.new(6.0, 0.8, 12.0),
		CFrame.new(-51.0, 8.0, 3.0),
		Color3.fromRGB(36, 32, 28),
		Enum.Material.WoodPlanks
	)
	makePart(
		"UpperMezzanineRailing",
		Enum.PartType.Block,
		Vector3.new(0.2, 3.4, 12.0),
		CFrame.new(-47.9, 10.0, 3.0),
		Color3.fromRGB(210, 175, 60),
		Enum.Material.Metal
	)

	-- Upstairs Guest Room Doors: Rooms 105, 106, 107, 108
	makeDoor("105", CFrame.new(-51.0, 12.5, 8.85), lobby)
	makeDoor("106", CFrame.new(-51.0, 12.5, -2.85) * CFrame.Angles(0, math.rad(180), 0), lobby)
	makeDoor("107", CFrame.new(-53.85, 12.5, 5.5) * CFrame.Angles(0, math.rad(90), 0), lobby)
	makeDoor("108", CFrame.new(-53.85, 12.5, 0.5) * CFrame.Angles(0, math.rad(90), 0), lobby)

	-- Hallway Directional Sconces
	makeSconce("HallSconce_North1", CFrame.new(-21, 8.5, 8.35), lobby)
	makeSconce(
		"HallSconce_South1",
		CFrame.new(-21, 8.5, -2.35) * CFrame.Angles(0, math.rad(180), 0),
		lobby
	)
	makeSconce("HallSconce_North2", CFrame.new(-31, 8.5, 8.35), lobby)
	makeSconce(
		"HallSconce_South2",
		CFrame.new(-31, 8.5, -2.35) * CFrame.Angles(0, math.rad(180), 0),
		lobby
	)
	makeSconce("HallSconce_North3", CFrame.new(-41, 8.5, 8.35), lobby)
	makeSconce(
		"HallSconce_South3",
		CFrame.new(-41, 8.5, -2.35) * CFrame.Angles(0, math.rad(180), 0),
		lobby
	)

	-- Hallway Overhead Directional Sign
	local hallSign = makePart(
		"HallwaySign",
		Enum.PartType.Block,
		Vector3.new(0.2, 1.4, 5.5),
		CFrame.new(-17.8, 10.8, 1),
		Color3.fromRGB(28, 48, 38),
		Enum.Material.Metal
	)
	local hGui = Instance.new("SurfaceGui")
	hGui.Face = Enum.NormalId.Right
	hGui.CanvasSize = Vector2.new(340, 85)
	hGui.Parent = hallSign
	local hLabel = Instance.new("TextLabel")
	hLabel.Size = UDim2.fromScale(1, 1)
	hLabel.BackgroundColor3 = Color3.fromRGB(24, 42, 32)
	hLabel.Font = Enum.Font.GothamBold
	hLabel.Text = "ROOMS 101 - 108  ➔"
	hLabel.TextColor3 = Color3.fromRGB(240, 225, 185)
	hLabel.TextSize = 22
	hLabel.Parent = hGui

	-- Red Emergency Exit Sign in Hallway
	local exitSign = makePart(
		"ExitSign",
		Enum.PartType.Block,
		Vector3.new(2.4, 1.0, 0.25),
		CFrame.new(-53.8, 13.2, 3.0) * CFrame.Angles(0, math.rad(90), 0),
		Color3.fromRGB(15, 15, 18),
		Enum.Material.Metal
	)
	local exitGui = Instance.new("SurfaceGui")
	exitGui.Face = Enum.NormalId.Front
	exitGui.CanvasSize = Vector2.new(200, 80)
	exitGui.Parent = exitSign
	local exitLabel = Instance.new("TextLabel")
	exitLabel.Size = UDim2.fromScale(1, 1)
	exitLabel.BackgroundColor3 = Color3.fromRGB(180, 20, 20)
	exitLabel.Font = Enum.Font.GothamBold
	exitLabel.Text = "EXIT"
	exitLabel.TextColor3 = Color3.fromRGB(255, 240, 240)
	exitLabel.TextSize = 34
	exitLabel.Parent = exitGui
	local exitLight = Instance.new("PointLight")
	exitLight.Color = Color3.fromRGB(255, 40, 40)
	exitLight.Brightness = 1.2
	exitLight.Range = 8
	exitLight.Parent = exitSign

	-- Wall-mounted Fire Extinguisher in Hallway
	local fireExt = Instance.new("Model")
	fireExt.Name = "FireExtinguisher"
	makePart(
		"ExtinguisherTank",
		Enum.PartType.Cylinder,
		Vector3.new(2.4, 0.7, 0.7),
		CFrame.new(-38.0, 5.0, 8.4) * CFrame.Angles(0, 0, math.rad(90)),
		Color3.fromRGB(200, 30, 25),
		Enum.Material.Metal,
		fireExt
	)
	makePart(
		"ExtinguisherHandle",
		Enum.PartType.Block,
		Vector3.new(0.3, 0.5, 0.5),
		CFrame.new(-38.0, 6.4, 8.4),
		Color3.fromRGB(25, 25, 25),
		Enum.Material.Metal,
		fireExt
	)
	fireExt.Parent = lobby

	-- =========================================================================
	-- 3. RECEPTION DESK COUNTER & ARCHITECTURAL PILLARS (Z = 4.5)
	-- =========================================================================
	makePart(
		"CounterBase",
		Enum.PartType.Block,
		Vector3.new(18, 4.0, 2.8),
		CFrame.new(0, 2.5, 4.5),
		Color3.fromRGB(40, 26, 16),
		Enum.Material.WoodPlanks
	)
	makePart(
		"CounterTop",
		Enum.PartType.Block,
		Vector3.new(19.2, 0.4, 3.4),
		CFrame.new(0, 4.7, 4.5),
		Color3.fromRGB(62, 42, 26),
		Enum.Material.Wood
	)
	-- Polished Brass Trim along Front Edge
	makePart(
		"CounterTrim",
		Enum.PartType.Block,
		Vector3.new(19.3, 0.08, 0.08),
		CFrame.new(0, 4.5, 2.78),
		Color3.fromRGB(210, 175, 60),
		Enum.Material.Metal
	)
	makePart(
		"CounterTrimBack",
		Enum.PartType.Block,
		Vector3.new(19.3, 0.08, 0.08),
		CFrame.new(0, 4.5, 6.22),
		Color3.fromRGB(210, 175, 60),
		Enum.Material.Metal
	)

	-- Architectural Desk Pillars & Header Beam
	makePart(
		"DeskPillarL",
		Enum.PartType.Block,
		Vector3.new(0.8, 9.2, 0.8),
		CFrame.new(-9.2, 9.1, 4.5),
		Color3.fromRGB(48, 34, 24),
		Enum.Material.Wood
	)
	makePart(
		"DeskPillarR",
		Enum.PartType.Block,
		Vector3.new(0.8, 9.2, 0.8),
		CFrame.new(9.2, 9.1, 4.5),
		Color3.fromRGB(48, 34, 24),
		Enum.Material.Wood
	)
	-- Pillar Brass Collars
	makePart(
		"PillarBaseL",
		Enum.PartType.Block,
		Vector3.new(1.1, 0.4, 1.1),
		CFrame.new(-9.2, 4.9, 4.5),
		Color3.fromRGB(210, 175, 60),
		Enum.Material.Metal
	)
	makePart(
		"PillarBaseR",
		Enum.PartType.Block,
		Vector3.new(1.1, 0.4, 1.1),
		CFrame.new(9.2, 4.9, 4.5),
		Color3.fromRGB(210, 175, 60),
		Enum.Material.Metal
	)
	makePart(
		"PillarCapL",
		Enum.PartType.Block,
		Vector3.new(1.1, 0.4, 1.1),
		CFrame.new(-9.2, 13.5, 4.5),
		Color3.fromRGB(210, 175, 60),
		Enum.Material.Metal
	)
	makePart(
		"PillarCapR",
		Enum.PartType.Block,
		Vector3.new(1.1, 0.4, 1.1),
		CFrame.new(9.2, 13.5, 4.5),
		Color3.fromRGB(210, 175, 60),
		Enum.Material.Metal
	)
	-- Wooden Header Lintel Beam with Brass Title Sign
	local deskHeader = makePart(
		"DeskHeaderBeam",
		Enum.PartType.Block,
		Vector3.new(19.2, 1.2, 0.8),
		CFrame.new(0, 13.2, 4.5),
		Color3.fromRGB(48, 34, 24),
		Enum.Material.Wood
	)
	local dGui = Instance.new("SurfaceGui")
	dGui.Face = Enum.NormalId.Front
	dGui.CanvasSize = Vector2.new(400, 60)
	dGui.Parent = deskHeader
	local dLabel = Instance.new("TextLabel")
	dLabel.Size = UDim2.fromScale(1, 1)
	dLabel.BackgroundTransparency = 1
	dLabel.Font = Enum.Font.SpecialElite
	dLabel.Text = "★ FRONT DESK · REGISTRATION ★"
	dLabel.TextColor3 = Color3.fromRGB(240, 220, 160)
	dLabel.TextSize = 22
	dLabel.Parent = dGui

	-- Counter Privacy Screens / Dividers
	makePart(
		"DeskDividerL",
		Enum.PartType.Block,
		Vector3.new(0.2, 2.2, 3.2),
		CFrame.new(-8.8, 5.8, 4.5),
		Color3.fromRGB(40, 26, 16),
		Enum.Material.Wood
	)
	makePart(
		"DeskDividerR",
		Enum.PartType.Block,
		Vector3.new(0.2, 2.2, 3.2),
		CFrame.new(8.8, 5.8, 4.5),
		Color3.fromRGB(40, 26, 16),
		Enum.Material.Wood
	)

	-- =========================================================================
	-- 4. CLERK BACK-OFFICE WORKSPACE (Behind Counter Z = 6 to 14)
	-- =========================================================================
	-- Clerk Office Desk (X = -4.5, Z = 11.5)
	makePart(
		"OfficeDesk_Base",
		Enum.PartType.Block,
		Vector3.new(6.0, 3.2, 2.8),
		CFrame.new(-4.5, 2.1, 11.5),
		Color3.fromRGB(44, 28, 18),
		Enum.Material.Wood
	)
	makePart(
		"OfficeDesk_Top",
		Enum.PartType.Block,
		Vector3.new(6.4, 0.3, 3.2),
		CFrame.new(-4.5, 3.8, 11.5),
		Color3.fromRGB(58, 38, 24),
		Enum.Material.Wood
	)
	-- Office Desk Blotter / Paperwork
	makePart(
		"DeskBlotter",
		Enum.PartType.Block,
		Vector3.new(2.8, 0.04, 2.0),
		CFrame.new(-4.5, 3.98, 11.5),
		Color3.fromRGB(28, 34, 30),
		Enum.Material.Leather
	)
	makePart(
		"PaperStack1",
		Enum.PartType.Block,
		Vector3.new(1.0, 0.25, 1.4),
		CFrame.new(-6.2, 4.1, 11.2) * CFrame.Angles(0, math.rad(12), 0),
		Color3.fromRGB(230, 225, 215),
		Enum.Material.SmoothPlastic
	)
	makePart(
		"CoffeeMug",
		Enum.PartType.Cylinder,
		Vector3.new(0.4, 0.3, 0.3),
		CFrame.new(-2.8, 4.15, 12.0) * CFrame.Angles(0, 0, math.rad(90)),
		Color3.fromRGB(215, 215, 220),
		Enum.Material.SmoothPlastic
	)

	-- Clerk Office Swivel Chair (X = -4.5, Z = 9.5)
	local chairModel = Instance.new("Model")
	chairModel.Name = "ClerkOfficeChair"
	makePart(
		"ChairSeat",
		Enum.PartType.Block,
		Vector3.new(1.8, 0.4, 1.8),
		CFrame.new(-4.5, 2.2, 9.5),
		Color3.fromRGB(30, 25, 24),
		Enum.Material.Leather,
		chairModel
	)
	makePart(
		"ChairBack",
		Enum.PartType.Block,
		Vector3.new(1.8, 2.2, 0.3),
		CFrame.new(-4.5, 3.4, 10.3),
		Color3.fromRGB(30, 25, 24),
		Enum.Material.Leather,
		chairModel
	)
	makePart(
		"ChairStem",
		Enum.PartType.Cylinder,
		Vector3.new(1.6, 0.15, 0.15),
		CFrame.new(-4.5, 1.2, 9.5) * CFrame.Angles(0, 0, math.rad(90)),
		Color3.fromRGB(80, 85, 90),
		Enum.Material.Metal,
		chairModel
	)
	makePart(
		"ChairBaseStar",
		Enum.PartType.Block,
		Vector3.new(1.6, 0.1, 1.6),
		CFrame.new(-4.5, 0.55, 9.5),
		Color3.fromRGB(60, 65, 70),
		Enum.Material.Metal,
		chairModel
	)
	chairModel.Parent = lobby

	-- Heavy 4-Drawer Metal Filing Cabinet (X = 6.5, Z = 12.0)
	local fileCabinet = Instance.new("Model")
	fileCabinet.Name = "FilingCabinet"
	makePart(
		"CabinetBody",
		Enum.PartType.Block,
		Vector3.new(2.2, 6.0, 2.8),
		CFrame.new(6.5, 3.5, 12.0),
		Color3.fromRGB(42, 48, 44),
		Enum.Material.Metal,
		fileCabinet
	)
	for d = 1, 4 do
		local yDrawer = 1.2 + (d - 1) * 1.45
		makePart(
			`DrawerHandle_{d}`,
			Enum.PartType.Block,
			Vector3.new(0.08, 0.15, 0.8),
			CFrame.new(5.35, yDrawer, 12.0),
			Color3.fromRGB(210, 175, 60),
			Enum.Material.Metal,
			fileCabinet
		)
	end
	fileCabinet.Parent = lobby

	-- CCTV Security Surveillance Rack / Console (X = 6.5, Z = 7.8)
	local cctvRack = Instance.new("Model")
	cctvRack.Name = "CCTVSecurityRack"
	makePart(
		"RackFrame",
		Enum.PartType.Block,
		Vector3.new(2.2, 6.8, 2.4),
		CFrame.new(6.5, 3.9, 7.8),
		Color3.fromRGB(28, 30, 32),
		Enum.Material.Metal,
		cctvRack
	)
	-- CRT Monitors on Rack
	local crtScreen1 = makePart(
		"CRTMonitor1",
		Enum.PartType.Block,
		Vector3.new(0.2, 1.6, 1.8),
		CFrame.new(5.35, 5.8, 7.8),
		Color3.fromRGB(15, 25, 18),
		Enum.Material.Neon,
		cctvRack
	)
	local crtGui1 = Instance.new("SurfaceGui")
	crtGui1.Face = Enum.NormalId.Left
	crtGui1.CanvasSize = Vector2.new(180, 160)
	crtGui1.Parent = crtScreen1
	local crtLabel1 = Instance.new("TextLabel")
	crtLabel1.Size = UDim2.fromScale(1, 1)
	crtLabel1.BackgroundColor3 = Color3.fromRGB(12, 24, 15)
	crtLabel1.Font = Enum.Font.RobotoMono
	crtLabel1.Text = "CAM 01\n[LIVE]"
	crtLabel1.TextColor3 = Color3.fromRGB(60, 255, 100)
	crtLabel1.TextSize = 22
	crtLabel1.Parent = crtGui1

	local crtScreen2 = makePart(
		"CRTMonitor2",
		Enum.PartType.Block,
		Vector3.new(0.2, 1.6, 1.8),
		CFrame.new(5.35, 3.8, 7.8),
		Color3.fromRGB(15, 25, 18),
		Enum.Material.Neon,
		cctvRack
	)
	local crtGui2 = Instance.new("SurfaceGui")
	crtGui2.Face = Enum.NormalId.Left
	crtGui2.CanvasSize = Vector2.new(180, 160)
	crtGui2.Parent = crtScreen2
	local crtLabel2 = Instance.new("TextLabel")
	crtLabel2.Size = UDim2.fromScale(1, 1)
	crtLabel2.BackgroundColor3 = Color3.fromRGB(12, 24, 15)
	crtLabel2.Font = Enum.Font.RobotoMono
	crtLabel2.Text = "CAM 02\n[REC]"
	crtLabel2.TextColor3 = Color3.fromRGB(60, 255, 100)
	crtLabel2.TextSize = 22
	crtLabel2.Parent = crtGui2

	cctvRack.Parent = lobby

	-- Heavy Steel Floor Safe (X = 6.5, Z = 13.8)
	local safeModel = Instance.new("Model")
	safeModel.Name = "ClerkSafe"
	makePart(
		"SafeBody",
		Enum.PartType.Block,
		Vector3.new(2.2, 2.6, 2.0),
		CFrame.new(6.5, 1.8, 13.8),
		Color3.fromRGB(30, 32, 36),
		Enum.Material.Metal,
		safeModel
	)
	makePart(
		"SafeDial",
		Enum.PartType.Cylinder,
		Vector3.new(0.08, 0.5, 0.5),
		CFrame.new(5.35, 2.2, 13.8) * CFrame.Angles(0, 0, math.rad(90)),
		Color3.fromRGB(220, 185, 65),
		Enum.Material.Metal,
		safeModel
	)
	makePart(
		"SafeHandle",
		Enum.PartType.Block,
		Vector3.new(0.08, 0.4, 0.4),
		CFrame.new(5.35, 1.5, 13.8),
		Color3.fromRGB(220, 185, 65),
		Enum.Material.Metal,
		safeModel
	)
	safeModel.Parent = lobby

	-- Wall-mounted Corkboard / Bulletin Board (X = -4.5, Z = 14.1, Y = 8.6)
	local corkboard = makePart(
		"BulletinCorkboard",
		Enum.PartType.Block,
		Vector3.new(5.5, 3.4, 0.15),
		CFrame.new(-4.5, 8.6, 14.1),
		Color3.fromRGB(160, 125, 80),
		Enum.Material.Wood
	)
	local corkGui = Instance.new("SurfaceGui")
	corkGui.Face = Enum.NormalId.Front
	corkGui.CanvasSize = Vector2.new(440, 260)
	corkGui.Parent = corkboard
	local corkLabel = Instance.new("TextLabel")
	corkLabel.Size = UDim2.fromScale(1, 1)
	corkLabel.BackgroundColor3 = Color3.fromRGB(150, 115, 75)
	corkLabel.Font = Enum.Font.SpecialElite
	corkLabel.Text =
		"MOTEL REGULATIONS & SHIFT PROTOCOL\n1. Check IDs against registry.\n2. Ring bell for next guest.\n3. Report anomalous occurrences immediately.\n4. Call room if suspicious."
	corkLabel.TextColor3 = Color3.fromRGB(25, 20, 18)
	corkLabel.TextSize = 18
	corkLabel.Parent = corkGui

	-- Vintage Round Wall Clock (X = 0, Z = 14.1, Y = 12.2)
	local clockModel = Instance.new("Model")
	clockModel.Name = "WallClock"
	makePart(
		"ClockBody",
		Enum.PartType.Cylinder,
		Vector3.new(0.2, 1.8, 1.8),
		CFrame.new(0, 12.2, 14.1) * CFrame.Angles(math.rad(90), 0, 0),
		Color3.fromRGB(48, 34, 24),
		Enum.Material.Wood,
		clockModel
	)
	local clockFace = makePart(
		"ClockFace",
		Enum.PartType.Cylinder,
		Vector3.new(0.22, 1.5, 1.5),
		CFrame.new(0, 12.2, 14.0) * CFrame.Angles(math.rad(90), 0, 0),
		Color3.fromRGB(240, 235, 220),
		Enum.Material.SmoothPlastic,
		clockModel
	)
	local clockGui = Instance.new("SurfaceGui")
	clockGui.Face = Enum.NormalId.Front
	clockGui.CanvasSize = Vector2.new(180, 180)
	clockGui.Parent = clockFace
	local clockLabel = Instance.new("TextLabel")
	clockLabel.Size = UDim2.fromScale(1, 1)
	clockLabel.BackgroundTransparency = 1
	clockLabel.Font = Enum.Font.SpecialElite
	clockLabel.Text = "XII\nIX   ·   III\nVI"
	clockLabel.TextColor3 = Color3.fromRGB(25, 20, 18)
	clockLabel.TextSize = 32
	clockLabel.Parent = clockGui
	clockModel.Parent = lobby

	-- Back-Office "STAFF ONLY - PRIVATE" Door on Back Wall (X = -8.5, Z = 14.0)
	local staffDoor = Instance.new("Model")
	staffDoor.Name = "StaffOnlyDoor"
	makePart(
		"StaffDoorFrame",
		Enum.PartType.Block,
		Vector3.new(4.2, 9.2, 0.4),
		CFrame.new(-8.5, 5.1, 14.0),
		Color3.fromRGB(38, 26, 18),
		Enum.Material.Wood,
		staffDoor
	)
	makePart(
		"StaffDoorPanel",
		Enum.PartType.Block,
		Vector3.new(3.6, 8.6, 0.2),
		CFrame.new(-8.5, 5.1, 14.0),
		Color3.fromRGB(48, 32, 22),
		Enum.Material.WoodPlanks,
		staffDoor
	)
	local staffGlass = makeCustomPart(
		"StaffDoorGlass",
		Enum.PartType.Block,
		Vector3.new(2.4, 3.2, 0.1),
		CFrame.new(-8.5, 6.8, 13.9),
		Color3.fromRGB(180, 210, 225),
		Enum.Material.Glass,
		0.55,
		false,
		staffDoor
	)
	local staffGui = Instance.new("SurfaceGui")
	staffGui.Face = Enum.NormalId.Front
	staffGui.CanvasSize = Vector2.new(200, 100)
	staffGui.Parent = staffGlass
	local staffLabel = Instance.new("TextLabel")
	staffLabel.Size = UDim2.fromScale(1, 1)
	staffLabel.BackgroundTransparency = 1
	staffLabel.Font = Enum.Font.SpecialElite
	staffLabel.Text = "STAFF ONLY\nPRIVATE"
	staffLabel.TextColor3 = Color3.fromRGB(25, 20, 15)
	staffLabel.TextSize = 24
	staffLabel.Parent = staffGui
	makePart(
		"StaffDoorHandle",
		Enum.PartType.Cylinder,
		Vector3.new(0.6, 0.08, 0.08),
		CFrame.new(-7.2, 4.8, 13.8) * CFrame.Angles(0, 0, math.rad(90)),
		Color3.fromRGB(210, 175, 60),
		Enum.Material.Metal,
		staffDoor
	)
	staffDoor.Parent = lobby

	-- =========================================================================
	-- 5. KEY RACK CUBBY UNIT (X = 0, Y = 8.6, Z = 14.1)
	-- =========================================================================
	local keyRack = makePart(
		"KeyRackMount",
		Enum.PartType.Block,
		Vector3.new(8.0, 3.8, 0.3),
		CFrame.new(0, 8.6, 14.1),
		Color3.fromRGB(44, 28, 18),
		Enum.Material.Wood
	)
	-- Outer Key Rack Trim Box
	makePart(
		"KeyRackFrameTop",
		Enum.PartType.Block,
		Vector3.new(8.4, 0.3, 0.6),
		CFrame.new(0, 10.5, 14.0),
		Color3.fromRGB(34, 22, 14),
		Enum.Material.Wood,
		keyRack
	)
	makePart(
		"KeyRackFrameBottom",
		Enum.PartType.Block,
		Vector3.new(8.4, 0.3, 0.6),
		CFrame.new(0, 6.7, 14.0),
		Color3.fromRGB(34, 22, 14),
		Enum.Material.Wood,
		keyRack
	)

	-- 8 Individual Numbered Hooks and Room Key Fob Tags (101 to 108)
	for i = 1, 8 do
		local xOff = -3.15 + (i - 1) * 0.90
		local roomNum = `10{i}`

		-- Brass Hook
		makePart(
			`KeyHook_{i}`,
			Enum.PartType.Cylinder,
			Vector3.new(0.3, 0.08, 0.08),
			CFrame.new(xOff, 8.4, 13.8) * CFrame.Angles(math.rad(90), 0, 0),
			Color3.fromRGB(210, 175, 60),
			Enum.Material.Metal,
			keyRack
		)

		-- Diamond Room Key Tag
		local tag = makePart(
			`KeyTag_{i}`,
			Enum.PartType.Block,
			Vector3.new(0.40, 0.65, 0.04),
			CFrame.new(xOff, 7.8, 13.8),
			Color3.fromRGB(175, 45, 35),
			Enum.Material.SmoothPlastic,
			keyRack
		)

		-- Number SurfaceGui on Tag
		local tagGui = Instance.new("SurfaceGui")
		tagGui.Face = Enum.NormalId.Front
		tagGui.CanvasSize = Vector2.new(100, 140)
		tagGui.Parent = tag

		local tagLabel = Instance.new("TextLabel")
		tagLabel.Size = UDim2.fromScale(1, 1)
		tagLabel.BackgroundTransparency = 1
		tagLabel.Font = Enum.Font.SpecialElite
		tagLabel.Text = roomNum
		tagLabel.TextColor3 = Color3.fromRGB(255, 235, 180)
		tagLabel.TextSize = 34
		tagLabel.Parent = tagGui
	end

	-- =========================================================================
	-- 6. FRONT DESK INTERACTIVE PROPS (Bell, Rotary Phone, Green Banker Lamp)
	-- =========================================================================
	-- Service Bell (DeskBell_Parts)
	local bellModel = Instance.new("Model")
	bellModel.Name = "DeskBell_Parts"
	local bBaseLower = makePart(
		"Base_Lower",
		Enum.PartType.Cylinder,
		Vector3.new(0.06, 1.20, 1.20),
		CFrame.new(1.3, 4.93, 4.5) * CFrame.Angles(0, 0, math.rad(90)),
		Color3.fromRGB(45, 45, 50),
		Enum.Material.Metal,
		bellModel
	)
	makePart(
		"Base_Upper",
		Enum.PartType.Cylinder,
		Vector3.new(0.04, 1.00, 1.00),
		CFrame.new(1.3, 4.98, 4.5) * CFrame.Angles(0, 0, math.rad(90)),
		Color3.fromRGB(45, 45, 50),
		Enum.Material.Metal,
		bellModel
	)
	makePart(
		"Bell_Skirt",
		Enum.PartType.Cylinder,
		Vector3.new(0.12, 0.95, 0.95),
		CFrame.new(1.3, 5.06, 4.5) * CFrame.Angles(0, 0, math.rad(90)),
		Color3.fromRGB(225, 180, 50),
		Enum.Material.Metal,
		bellModel
	)
	makePart(
		"Bell_Dome",
		Enum.PartType.Ball,
		Vector3.new(0.90, 0.90, 0.90),
		CFrame.new(1.3, 5.08, 4.5),
		Color3.fromRGB(225, 180, 50),
		Enum.Material.Metal,
		bellModel
	)
	makePart(
		"Plunger_Stem",
		Enum.PartType.Cylinder,
		Vector3.new(0.22, 0.10, 0.10),
		CFrame.new(1.3, 5.60, 4.5) * CFrame.Angles(0, 0, math.rad(90)),
		Color3.fromRGB(190, 190, 195),
		Enum.Material.Metal,
		bellModel
	)
	makePart(
		"Plunger_Button",
		Enum.PartType.Cylinder,
		Vector3.new(0.06, 0.35, 0.35),
		CFrame.new(1.3, 5.73, 4.5) * CFrame.Angles(0, 0, math.rad(90)),
		Color3.fromRGB(225, 180, 50),
		Enum.Material.Metal,
		bellModel
	)
	bellModel.PrimaryPart = bBaseLower
	bellModel.Parent = lobby

	-- Rotary Telephone
	local phoneModel = Instance.new("Model")
	phoneModel.Name = "RotaryTelephone"
	makePart(
		"PhoneBase",
		Enum.PartType.Block,
		Vector3.new(0.9, 0.4, 0.9),
		CFrame.new(-4.6, 5.10, 5.0),
		Color3.fromRGB(25, 25, 28),
		Enum.Material.SmoothPlastic,
		phoneModel
	)
	makePart(
		"PhoneDial",
		Enum.PartType.Cylinder,
		Vector3.new(0.04, 0.5, 0.5),
		CFrame.new(-4.6, 5.32, 4.85) * CFrame.Angles(math.rad(45), 0, 0),
		Color3.fromRGB(220, 220, 225),
		Enum.Material.Metal,
		phoneModel
	)
	makePart(
		"PhoneHandset",
		Enum.PartType.Block,
		Vector3.new(0.3, 0.25, 1.2),
		CFrame.new(-4.6, 5.42, 5.0),
		Color3.fromRGB(25, 25, 28),
		Enum.Material.SmoothPlastic,
		phoneModel
	)
	phoneModel.Parent = lobby

	-- Green Banker Desk Lamp with Toggleable Spotlight
	makePart(
		"DeskLampBase",
		Enum.PartType.Cylinder,
		Vector3.new(0.15, 1.0, 1.0),
		CFrame.new(-6.5, 4.98, 4.8) * CFrame.Angles(0, 0, math.rad(90)),
		Color3.fromRGB(55, 65, 55),
		Enum.Material.Metal
	)
	makePart(
		"DeskLampArm",
		Enum.PartType.Cylinder,
		Vector3.new(1.4, 0.12, 0.12),
		CFrame.new(-6.5, 5.7, 4.8) * CFrame.Angles(0, 0, math.rad(90)),
		Color3.fromRGB(75, 80, 70),
		Enum.Material.Metal
	)
	local lampShade = makePart(
		"DeskLampShade",
		Enum.PartType.Block,
		Vector3.new(1.2, 0.6, 0.8),
		CFrame.new(-6.2, 6.4, 4.6) * CFrame.Angles(math.rad(25), 0, 0),
		Color3.fromRGB(35, 85, 55),
		Enum.Material.SmoothPlastic
	)
	local deskLight = Instance.new("SpotLight")
	deskLight.Name = "DeskWarmLight"
	deskLight.Face = Enum.NormalId.Bottom
	deskLight.Color = Color3.fromRGB(255, 210, 135)
	deskLight.Brightness = 3.2
	deskLight.Range = 12
	deskLight.Angle = 78
	deskLight.Shadows = true
	deskLight.Parent = lampShade

	-- =========================================================================
	-- 7. LOBBY WAITING LOUNGE & VENDING AREA (Right Wing X = 6 to 17, Z = -14 to 8)
	-- =========================================================================
	-- Plush Burgundy Velvet Sofa
	local sofaModel = Instance.new("Model")
	sofaModel.Name = "VelvetSofa"
	makePart(
		"SofaBase",
		Enum.PartType.Block,
		Vector3.new(8.0, 1.3, 3.4),
		CFrame.new(13.5, 1.15, -4),
		Color3.fromRGB(68, 24, 24),
		Enum.Material.Fabric,
		sofaModel
	)
	makePart(
		"SofaBack",
		Enum.PartType.Block,
		Vector3.new(8.0, 2.8, 0.9),
		CFrame.new(13.5, 3.0, -2.4),
		Color3.fromRGB(68, 24, 24),
		Enum.Material.Fabric,
		sofaModel
	)
	makePart(
		"SofaArmL",
		Enum.PartType.Block,
		Vector3.new(0.9, 2.2, 3.4),
		CFrame.new(9.1, 1.7, -4),
		Color3.fromRGB(68, 24, 24),
		Enum.Material.Fabric,
		sofaModel
	)
	makePart(
		"SofaArmR",
		Enum.PartType.Block,
		Vector3.new(0.9, 2.2, 3.4),
		CFrame.new(17.9, 1.7, -4),
		Color3.fromRGB(68, 24, 24),
		Enum.Material.Fabric,
		sofaModel
	)
	-- Sofa Seat Cushions & Accent Pillows
	makePart(
		"SofaCushion1",
		Enum.PartType.Block,
		Vector3.new(2.4, 0.5, 2.6),
		CFrame.new(11.0, 1.9, -4.1),
		Color3.fromRGB(75, 26, 26),
		Enum.Material.Fabric,
		sofaModel
	)
	makePart(
		"SofaCushion2",
		Enum.PartType.Block,
		Vector3.new(2.4, 0.5, 2.6),
		CFrame.new(13.5, 1.9, -4.1),
		Color3.fromRGB(75, 26, 26),
		Enum.Material.Fabric,
		sofaModel
	)
	makePart(
		"SofaCushion3",
		Enum.PartType.Block,
		Vector3.new(2.4, 0.5, 2.6),
		CFrame.new(16.0, 1.9, -4.1),
		Color3.fromRGB(75, 26, 26),
		Enum.Material.Fabric,
		sofaModel
	)
	makePart(
		"ThrowPillow1",
		Enum.PartType.Block,
		Vector3.new(0.9, 0.9, 0.4),
		CFrame.new(10.0, 2.5, -3.6) * CFrame.Angles(0, math.rad(25), math.rad(15)),
		Color3.fromRGB(185, 145, 55),
		Enum.Material.Fabric,
		sofaModel
	)
	makePart(
		"ThrowPillow2",
		Enum.PartType.Block,
		Vector3.new(0.9, 0.9, 0.4),
		CFrame.new(17.0, 2.5, -3.6) * CFrame.Angles(0, math.rad(-25), math.rad(-15)),
		Color3.fromRGB(185, 145, 55),
		Enum.Material.Fabric,
		sofaModel
	)
	-- Sofa Wooden Tapered Legs
	makePart(
		"SofaLeg1",
		Enum.PartType.Cylinder,
		Vector3.new(0.6, 0.2, 0.2),
		CFrame.new(9.6, 0.3, -2.6) * CFrame.Angles(0, 0, math.rad(90)),
		Color3.fromRGB(48, 34, 24),
		Enum.Material.Wood,
		sofaModel
	)
	makePart(
		"SofaLeg2",
		Enum.PartType.Cylinder,
		Vector3.new(0.6, 0.2, 0.2),
		CFrame.new(17.4, 0.3, -2.6) * CFrame.Angles(0, 0, math.rad(90)),
		Color3.fromRGB(48, 34, 24),
		Enum.Material.Wood,
		sofaModel
	)
	makePart(
		"SofaLeg3",
		Enum.PartType.Cylinder,
		Vector3.new(0.6, 0.2, 0.2),
		CFrame.new(9.6, 0.3, -5.4) * CFrame.Angles(0, 0, math.rad(90)),
		Color3.fromRGB(48, 34, 24),
		Enum.Material.Wood,
		sofaModel
	)
	makePart(
		"SofaLeg4",
		Enum.PartType.Cylinder,
		Vector3.new(0.6, 0.2, 0.2),
		CFrame.new(17.4, 0.3, -5.4) * CFrame.Angles(0, 0, math.rad(90)),
		Color3.fromRGB(48, 34, 24),
		Enum.Material.Wood,
		sofaModel
	)
	sofaModel.Parent = lobby

	-- Vintage Lounge Area Rug
	makePart(
		"LoungeRug",
		Enum.PartType.Block,
		Vector3.new(10.5, 0.05, 11.0),
		CFrame.new(13.5, 0.52, -6.5),
		Color3.fromRGB(52, 40, 36),
		Enum.Material.Fabric
	)

	-- Polished Hardwood Coffee Table & Tabletop Props
	makePart(
		"CoffeeTable",
		Enum.PartType.Block,
		Vector3.new(4.6, 1.1, 2.4),
		CFrame.new(13.5, 1.05, -7.8),
		Color3.fromRGB(48, 34, 24),
		Enum.Material.Wood
	)
	-- Tabletop Daily Newspaper
	local newsPart = makePart(
		"CoffeeTable_Newspaper",
		Enum.PartType.Block,
		Vector3.new(1.2, 0.04, 0.9),
		CFrame.new(12.6, 1.62, -7.8) * CFrame.Angles(0, math.rad(15), 0),
		Color3.fromRGB(225, 220, 210),
		Enum.Material.SmoothPlastic
	)
	local newsGui = Instance.new("SurfaceGui")
	newsGui.Face = Enum.NormalId.Top
	newsGui.CanvasSize = Vector2.new(140, 100)
	newsGui.Parent = newsPart
	local newsLabel = Instance.new("TextLabel")
	newsLabel.Size = UDim2.fromScale(1, 1)
	newsLabel.BackgroundTransparency = 1
	newsLabel.Font = Enum.Font.SpecialElite
	newsLabel.Text = "THE OBSERVER\n\nROUTE 9 CLOSURES"
	newsLabel.TextColor3 = Color3.fromRGB(20, 18, 16)
	newsLabel.TextSize = 13
	newsLabel.Parent = newsGui

	-- Glass Ashtray with Matchbook
	makePart(
		"GlassAshtray",
		Enum.PartType.Cylinder,
		Vector3.new(0.12, 0.45, 0.45),
		CFrame.new(14.4, 1.66, -7.8) * CFrame.Angles(0, 0, math.rad(90)),
		Color3.fromRGB(180, 205, 215),
		Enum.Material.Glass
	)

	-- Potted Fern in Glazed Ceramic Pot with Stand
	local plantModel = Instance.new("Model")
	plantModel.Name = "PottedFern"
	makePart(
		"PlantPot",
		Enum.PartType.Cylinder,
		Vector3.new(1.2, 1.3, 1.3),
		CFrame.new(16.5, 1.1, -12.5) * CFrame.Angles(0, 0, math.rad(90)),
		Color3.fromRGB(155, 95, 60),
		Enum.Material.Slate,
		plantModel
	)
	makePart(
		"PlantFern",
		Enum.PartType.Ball,
		Vector3.new(2.4, 1.8, 2.4),
		CFrame.new(16.5, 2.5, -12.5),
		Color3.fromRGB(40, 78, 45),
		Enum.Material.Grass,
		plantModel
	)
	makePart(
		"PlantStandLeg1",
		Enum.PartType.Cylinder,
		Vector3.new(0.6, 0.12, 0.12),
		CFrame.new(16.0, 0.3, -12.5) * CFrame.Angles(0, 0, math.rad(90)),
		Color3.fromRGB(48, 34, 24),
		Enum.Material.Wood,
		plantModel
	)
	makePart(
		"PlantStandLeg2",
		Enum.PartType.Cylinder,
		Vector3.new(0.6, 0.12, 0.12),
		CFrame.new(17.0, 0.3, -12.5) * CFrame.Angles(0, 0, math.rad(90)),
		Color3.fromRGB(48, 34, 24),
		Enum.Material.Wood,
		plantModel
	)
	plantModel.Parent = lobby

	-- Glowing 1980s Cold Soda Vending Machine (X = 15.5, Z = 5.5)
	local vend = makePart(
		"VendingMachine",
		Enum.PartType.Block,
		Vector3.new(3.5, 7.5, 2.8),
		CFrame.new(15.5, 4.25, 5.5),
		Color3.fromRGB(30, 45, 65),
		Enum.Material.Metal
	)
	local vGlass = makeCustomPart(
		"VendingGlass",
		Enum.PartType.Block,
		Vector3.new(2.8, 3.8, 0.1),
		CFrame.new(15.5, 5.2, 4.05),
		Color3.fromRGB(180, 220, 240),
		Enum.Material.Glass,
		0.55,
		false
	)
	local vLight = Instance.new("PointLight")
	vLight.Name = "VendingGlow"
	vLight.Color = Color3.fromRGB(180, 230, 255)
	vLight.Brightness = 1.8
	vLight.Range = 12
	vLight.Parent = vend

	-- Illuminated Soda Brand Panel
	local vendGui = Instance.new("SurfaceGui")
	vendGui.Face = Enum.NormalId.Front
	vendGui.CanvasSize = Vector2.new(220, 100)
	vendGui.Parent = vGlass
	local vendLabel = Instance.new("TextLabel")
	vendLabel.Size = UDim2.fromScale(1, 1)
	vendLabel.BackgroundColor3 = Color3.fromRGB(20, 75, 140)
	vendLabel.Font = Enum.Font.GothamBold
	vendLabel.Text = "ICE COLD SODAS\n$5.00"
	vendLabel.TextColor3 = Color3.fromRGB(245, 250, 255)
	vendLabel.TextSize = 20
	vendLabel.Parent = vendGui

	-- Motel Ice Dispenser Machine (X = 15.5, Z = 9.8)
	local iceMachine = Instance.new("Model")
	iceMachine.Name = "IceMachine"
	makePart(
		"IceMachineBody",
		Enum.PartType.Block,
		Vector3.new(3.4, 6.2, 2.6),
		CFrame.new(15.5, 3.6, 9.8),
		Color3.fromRGB(85, 95, 105),
		Enum.Material.Metal,
		iceMachine
	)
	local iceSign = makePart(
		"IceSign",
		Enum.PartType.Block,
		Vector3.new(2.8, 1.2, 0.1),
		CFrame.new(15.5, 5.8, 8.45),
		Color3.fromRGB(200, 225, 245),
		Enum.Material.Neon,
		iceMachine
	)
	local iceGui = Instance.new("SurfaceGui")
	iceGui.Face = Enum.NormalId.Front
	iceGui.CanvasSize = Vector2.new(200, 80)
	iceGui.Parent = iceSign
	local iceLabel = Instance.new("TextLabel")
	iceLabel.Size = UDim2.fromScale(1, 1)
	iceLabel.BackgroundColor3 = Color3.fromRGB(35, 65, 95)
	iceLabel.Font = Enum.Font.GothamBold
	iceLabel.Text = "HOTEL ICE\nFOR GUESTS"
	iceLabel.TextColor3 = Color3.fromRGB(230, 245, 255)
	iceLabel.TextSize = 20
	iceLabel.Parent = iceGui
	iceMachine.Parent = lobby

	-- =========================================================================
	-- 8. EXTERIOR HIGHWAY ENVIRONMENT: WET SLATE ASPHALT, RAIN, & NEON SIGN
	-- =========================================================================
	-- Wet Slate Asphalt Parking Lot
	makePart(
		"ExteriorAsphalt",
		Enum.PartType.Block,
		Vector3.new(64, 1, 36),
		CFrame.new(0, 0, -34.5),
		Color3.fromRGB(18, 20, 22),
		Enum.Material.Slate
	)

	-- Concrete Sidewalk & Entrance Curb
	makePart(
		"SidewalkCurb",
		Enum.PartType.Block,
		Vector3.new(44, 0.4, 3.0),
		CFrame.new(0, 0.3, -18.0),
		Color3.fromRGB(75, 78, 82),
		Enum.Material.Concrete
	)

	-- Yellow Parking Lot Bay Divider Stripes
	for b = -2, 2 do
		makePart(
			`ParkingStripe_{b + 3}`,
			Enum.PartType.Block,
			Vector3.new(0.4, 0.04, 14.0),
			CFrame.new(b * 10, 0.53, -34.0),
			Color3.fromRGB(215, 185, 45),
			Enum.Material.SmoothPlastic
		)
	end

	-- Downward Rain Particle Emitter
	local rainEmitterPart = makeCustomPart(
		"RainEmitterPart",
		Enum.PartType.Block,
		Vector3.new(58, 0.5, 32),
		CFrame.new(0, 22.0, -33.0),
		Color3.fromRGB(200, 220, 240),
		Enum.Material.Air,
		1.0,
		false
	)

	local rainParticles = Instance.new("ParticleEmitter")
	rainParticles.Name = "RainParticles"
	rainParticles.Rate = 220
	rainParticles.Speed = NumberRange.new(45, 58)
	rainParticles.Lifetime = NumberRange.new(0.45, 0.65)
	rainParticles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.14),
		NumberSequenceKeypoint.new(1, 0.14),
	})
	rainParticles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(1, 0.75),
	})
	rainParticles.Color = ColorSequence.new(Color3.fromRGB(190, 215, 240))
	rainParticles.EmissionDirection = Enum.NormalId.Bottom
	rainParticles.SpreadAngle = Vector2.new(3, 3)
	rainParticles.Parent = rainEmitterPart

	-- Exterior Awning over Entrance
	makePart(
		"ExteriorAwning",
		Enum.PartType.Block,
		Vector3.new(16, 0.5, 7.5),
		CFrame.new(0, 11.5, -20.2),
		Color3.fromRGB(28, 32, 36),
		Enum.Material.Metal
	)
	-- Awning Support Struts
	makePart(
		"AwningPillarL",
		Enum.PartType.Cylinder,
		Vector3.new(11.0, 0.4, 0.4),
		CFrame.new(-7.2, 5.5, -23.5) * CFrame.Angles(0, 0, math.rad(90)),
		Color3.fromRGB(45, 48, 52),
		Enum.Material.Metal
	)
	makePart(
		"AwningPillarR",
		Enum.PartType.Cylinder,
		Vector3.new(11.0, 0.4, 0.4),
		CFrame.new(7.2, 5.5, -23.5) * CFrame.Angles(0, 0, math.rad(90)),
		Color3.fromRGB(45, 48, 52),
		Enum.Material.Metal
	)

	-- Glowing Red Roadside MOTEL VACANCY Neon Sign
	makePart(
		"NeonSign_Back",
		Enum.PartType.Block,
		Vector3.new(9.2, 4.0, 0.5),
		CFrame.new(0, 15.0, -22.5),
		Color3.fromRGB(18, 18, 22),
		Enum.Material.Metal
	)
	local neonGlow = makePart(
		"NeonSign_Glow",
		Enum.PartType.Block,
		Vector3.new(8.6, 3.4, 0.2),
		CFrame.new(0, 15.0, -22.2),
		Color3.fromRGB(255, 45, 30),
		Enum.Material.Neon
	)
	local nLight = Instance.new("PointLight")
	nLight.Name = "NeonSignVolumetricLight"
	nLight.Color = Color3.fromRGB(255, 55, 35)
	nLight.Brightness = 3.6
	nLight.Range = 40
	nLight.Shadows = true
	nLight.Parent = neonGlow

	local nGui = Instance.new("SurfaceGui")
	nGui.Face = Enum.NormalId.Front
	nGui.CanvasSize = Vector2.new(460, 170)
	nGui.Parent = neonGlow
	local nLabel = Instance.new("TextLabel")
	nLabel.Size = UDim2.fromScale(1, 1)
	nLabel.BackgroundTransparency = 1
	nLabel.Font = Enum.Font.SpecialElite
	nLabel.Text = "MOTEL\nVACANCY"
	nLabel.TextColor3 = Color3.fromRGB(255, 240, 240)
	nLabel.TextSize = 44
	nLabel.Parent = nGui

	-- Neon Sign Support Poles
	makePart(
		"NeonSignPoleL",
		Enum.PartType.Cylinder,
		Vector3.new(4.0, 0.3, 0.3),
		CFrame.new(-3.6, 12.5, -22.5) * CFrame.Angles(0, 0, math.rad(90)),
		Color3.fromRGB(45, 48, 52),
		Enum.Material.Metal
	)
	makePart(
		"NeonSignPoleR",
		Enum.PartType.Cylinder,
		Vector3.new(4.0, 0.3, 0.3),
		CFrame.new(3.6, 12.5, -22.5) * CFrame.Angles(0, 0, math.rad(90)),
		Color3.fromRGB(45, 48, 52),
		Enum.Material.Metal
	)

	-- =========================================================================
	-- 9. MASTER LIGHTING BALANCE: CEILING FIXTURE & AMBIENT ILLUMINATION
	-- =========================================================================
	-- Main Lobby Industrial Fluorescent Pendant Fixture (X = 0, Y = 13.9, Z = 2.0)
	local ceilingLight = makePart(
		"CeilingLight",
		Enum.PartType.Block,
		Vector3.new(4.5, 0.3, 1.4),
		CFrame.new(0, 13.9, 2.0),
		Color3.fromRGB(235, 235, 225),
		Enum.Material.Neon
	)
	-- Future-technology Guest Area Spotlight
	local spot = Instance.new("SpotLight")
	spot.Name = "GuestSpotlight"
	spot.Face = Enum.NormalId.Bottom
	spot.Color = Color3.fromRGB(255, 246, 225)
	spot.Brightness = 5.5
	spot.Range = 28
	spot.Angle = 75
	spot.Shadows = true
	spot.Parent = ceilingLight

	-- Warm Ambient Fill Light
	local fill = Instance.new("PointLight")
	fill.Name = "GuestFillLight"
	fill.Color = Color3.fromRGB(245, 235, 220)
	fill.Brightness = 2.2
	fill.Range = 18
	fill.Shadows = false
	fill.Parent = ceilingLight

	-- Lobby Perimeter Sconces
	makeSconce(
		"LobbySconce_Right1",
		CFrame.new(17.35, 8.5, 2.0) * CFrame.Angles(0, math.rad(90), 0),
		lobby
	)
	makeSconce(
		"LobbySconce_Right2",
		CFrame.new(17.35, 8.5, -10.0) * CFrame.Angles(0, math.rad(90), 0),
		lobby
	)
	makeSconce(
		"LobbySconce_Left1",
		CFrame.new(-17.35, 8.5, -12.0) * CFrame.Angles(0, math.rad(-90), 0),
		lobby
	)

	-- =========================================================================
	-- 10. INTERACTIVE OFFICE COFFEE MACHINE & HALLWAY BREAKER BOX
	-- =========================================================================
	-- Commercial Espresso Coffee Machine (X = 3.5, Y = 4.96, Z = 7.8)
	local coffeeModel = Instance.new("Model")
	coffeeModel.Name = "CoffeeMachine"
	makePart(
		"MachineBody",
		Enum.PartType.Block,
		Vector3.new(1.2, 1.6, 1.2),
		CFrame.new(3.5, 5.4, 7.8),
		Color3.fromRGB(35, 40, 45),
		Enum.Material.Metal,
		coffeeModel
	)
	makePart(
		"DripTray",
		Enum.PartType.Block,
		Vector3.new(1.0, 0.15, 0.8),
		CFrame.new(3.5, 4.7, 7.4),
		Color3.fromRGB(180, 185, 190),
		Enum.Material.Metal,
		coffeeModel
	)
	local pot = makePart(
		"CoffeePot",
		Enum.PartType.Cylinder,
		Vector3.new(0.6, 0.5, 0.5),
		CFrame.new(3.5, 5.0, 7.4) * CFrame.Angles(0, 0, math.rad(90)),
		Color3.fromRGB(60, 30, 15),
		Enum.Material.Glass,
		coffeeModel
	)
	pot.Transparency = 0.4
	local cButton = makePart(
		"BrewButton",
		Enum.PartType.Cylinder,
		Vector3.new(0.06, 0.2, 0.2),
		CFrame.new(3.5, 5.9, 7.18) * CFrame.Angles(math.rad(90), 0, 0),
		Color3.fromRGB(50, 160, 80),
		Enum.Material.Neon,
		coffeeModel
	)
	coffeeModel.PrimaryPart = cButton
	coffeeModel.Parent = lobby

	-- Hallway Electrical Breaker Box (X = -17.8, Y = 6.5, Z = -2.0)
	local breakerModel = Instance.new("Model")
	breakerModel.Name = "BreakerBox"
	local bBox = makePart(
		"BoxHousing",
		Enum.PartType.Block,
		Vector3.new(0.4, 2.2, 1.6),
		CFrame.new(-17.8, 6.5, -2.0),
		Color3.fromRGB(45, 50, 55),
		Enum.Material.Metal,
		breakerModel
	)
	local bLever = makePart(
		"BreakerLever",
		Enum.PartType.Cylinder,
		Vector3.new(0.4, 0.15, 0.15),
		CFrame.new(-17.5, 6.5, -2.0) * CFrame.Angles(0, 0, math.rad(90)),
		Color3.fromRGB(200, 45, 35),
		Enum.Material.Metal,
		breakerModel
	)
	local bLight = makePart(
		"BreakerIndicator",
		Enum.PartType.Ball,
		Vector3.new(0.3, 0.3, 0.3),
		CFrame.new(-17.55, 7.2, -2.0),
		Color3.fromRGB(50, 220, 90),
		Enum.Material.Neon,
		breakerModel
	)
	local bPoint = Instance.new("PointLight")
	bPoint.Name = "IndicatorLight"
	bPoint.Color = Color3.fromRGB(50, 220, 90)
	bPoint.Brightness = 1.8
	bPoint.Range = 8
	bPoint.Parent = bLight

	local bSparks = Instance.new("ParticleEmitter")
	bSparks.Name = "SparksEmitter"
	bSparks.Enabled = false
	bSparks.Rate = 45
	bSparks.Speed = NumberRange.new(5, 12)
	bSparks.Lifetime = NumberRange.new(0.1, 0.3)
	bSparks.Size = NumberSequence.new(0.08)
	bSparks.Color = ColorSequence.new(Color3.fromRGB(255, 220, 80))
	bSparks.Parent = bBox

	breakerModel.PrimaryPart = bLever
	breakerModel.Parent = lobby

	-- =========================================================================
	-- 11. SPAWN POINT CALIBRATION (0, 3.5, 7.5) FACING DESK COUNTER
	-- =========================================================================
	lobby.Parent = Workspace

	local spawn = Workspace:FindFirstChild("Spawn")
	if spawn and spawn:IsA("BasePart") then
		spawn.CFrame = CFrame.lookAt(Vector3.new(0, 3.5, 7.5), Vector3.new(0, 4.8, 1.8))
	end

	return lobby
end

return buildLobby
