--!strict
-- 3D Interactive Desk Props: ProximityPrompts + ClickDetectors + Hotkeys for
-- Service Bell, Green/Red Stamps, Registry Clipboard, Rotary Phone, UV Blacklight, and Vending Machine.

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))

local Atmosphere = require(script.Parent:WaitForChild("Atmosphere"))
local DeskCamera = require(script.Parent:WaitForChild("DeskCamera"))
local Theme = require(script.Parent:WaitForChild("Theme"))
local Viewmodel = require(script.Parent:WaitForChild("Viewmodel"))

local ringBell = Remotes.get("RingBell")
local judge = Remotes.get("Judge")
local callRoom = Remotes.get("CallRoom")
local toggleUV = Remotes.get("ToggleUV")
local bellRang = Remotes.get("BellRang")
local phoneResponse = Remotes.get("PhoneResponse")
local uvState = Remotes.get("UVState")

local DeskProps = {}

local ledgerGui: SurfaceGui?
local nameLabel: TextLabel?
local idNameLabel: TextLabel?
local resLabel: TextLabel?
local datesLabel: TextLabel?
local roomLabel: TextLabel?
local cityLabel: TextLabel?
local uvWatermarkLabel: TextLabel?

-- 2D Inspect Modal Labels
local inspectModal: Frame?
local mNameLabel: TextLabel?
local mIdLabel: TextLabel?
local mResLabel: TextLabel?
local mRoomLabel: TextLabel?
local mCityLabel: TextLabel?
local mDatesLabel: TextLabel?
local mWatermarkLabel: TextLabel?

local zipLabel: TextLabel?
local stayLabel: TextLabel?
local signatureLabel: TextLabel?
local photoMask: Frame?

local mZipLabel: TextLabel?
local mStayLabel: TextLabel?
local mSignatureLabel: TextLabel?
local mPhotoMask: Frame?
local currentWatermarkText = "★ OFFICIAL GENUINE CRESTVIEW SEAL ★"

local stampAdmitPart: Model?
local stampRefusePart: Model?
local bellModel: Model?
local plungerStem: BasePart?
local plungerButton: BasePart?
local deskLight: SpotLight?
local uvLight: PointLight?
local uvActive = false
local currentRoomNumber = 101

local function makePart(
	name: string,
	shape: Enum.PartType,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	material: Enum.Material,
	parent: Instance
): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Shape = shape
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material
	p.Anchored = true
	p.CanCollide = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function addPrompt(
	parent: BasePart,
	actionText: string,
	objectText: string,
	keyCode: Enum.KeyCode,
	onTrigger: () -> ()
): ProximityPrompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = actionText
	prompt.ObjectText = objectText
	prompt.KeyboardKeyCode = keyCode
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Triggered:Connect(onTrigger)
	prompt.Parent = parent
	return prompt
end

local function addClick(primaryPart: BasePart, onClick: () -> ()): ClickDetector
	local click = Instance.new("ClickDetector")
	click.MaxActivationDistance = 14
	click.MouseClick:Connect(onClick)
	click.Parent = primaryPart
	return click
end

function DeskProps.init()
	local lobby = Workspace:WaitForChild("Lobby", 10)
	if not lobby then
		return
	end

	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui
	local nightDeskGui = playerGui:WaitForChild("NightDesk") :: ScreenGui

	-- 1. Front Desk Bell (X = 1.3, Y = 4.93, Z = 4.5)
	bellModel = lobby:WaitForChild("DeskBell_Parts", 5) :: Model?
	if bellModel then
		plungerStem = bellModel:FindFirstChild("Plunger_Stem") :: BasePart?
		plungerButton = bellModel:FindFirstChild("Plunger_Button") :: BasePart?
		local baseLower = bellModel:FindFirstChild("Base_Lower") :: BasePart?
		if baseLower then
			addPrompt(baseLower, "Ring Bell", "Service Bell", Enum.KeyCode.E, DeskProps.ring)
			addClick(baseLower, DeskProps.ring)
		end
	end

	-- 2. Green ADMIT Stamp (X = 2.8, Y = 4.96, Z = 4.6)
	local admitModel = Instance.new("Model")
	admitModel.Name = "Stamp_Admit"
	local aHandle = makePart(
		"Handle",
		Enum.PartType.Cylinder,
		Vector3.new(0.6, 0.4, 0.4),
		CFrame.new(2.8, 5.26, 4.6) * CFrame.Angles(0, 0, math.rad(90)),
		Color3.fromRGB(45, 95, 55),
		Enum.Material.Wood,
		admitModel
	)
	makePart(
		"Base",
		Enum.PartType.Block,
		Vector3.new(0.7, 0.2, 0.9),
		CFrame.new(2.8, 4.96, 4.6),
		Color3.fromRGB(35, 125, 60),
		Enum.Material.Plastic,
		admitModel
	)
	admitModel.PrimaryPart = aHandle
	admitModel.Parent = lobby
	stampAdmitPart = admitModel
	addPrompt(aHandle, "Admit Guest", "Green Stamp", Enum.KeyCode.Z, function()
		DeskProps.slamStamp(true)
	end)
	addClick(aHandle, function()
		DeskProps.slamStamp(true)
	end)

	-- 3. Red REFUSE Stamp (X = 4.0, Y = 4.96, Z = 4.6)
	local refuseModel = Instance.new("Model")
	refuseModel.Name = "Stamp_Refuse"
	local rHandle = makePart(
		"Handle",
		Enum.PartType.Cylinder,
		Vector3.new(0.6, 0.4, 0.4),
		CFrame.new(4.0, 5.26, 4.6) * CFrame.Angles(0, 0, math.rad(90)),
		Color3.fromRGB(95, 45, 45),
		Enum.Material.Wood,
		refuseModel
	)
	makePart(
		"Base",
		Enum.PartType.Block,
		Vector3.new(0.7, 0.2, 0.9),
		CFrame.new(4.0, 4.96, 4.6),
		Color3.fromRGB(145, 40, 40),
		Enum.Material.Plastic,
		refuseModel
	)
	refuseModel.PrimaryPart = rHandle
	refuseModel.Parent = lobby
	stampRefusePart = refuseModel
	addPrompt(rHandle, "Refuse Guest", "Red Stamp", Enum.KeyCode.X, function()
		DeskProps.slamStamp(false)
	end)
	addClick(rHandle, function()
		DeskProps.slamStamp(false)
	end)

	-- 4. Rotary Telephone (X = -4.6, Y = 5.10, Z = 5.0)
	local phone = lobby:WaitForChild("RotaryTelephone", 5) :: Model?
	if phone then
		local pBase = phone:FindFirstChild("PhoneBase") :: BasePart?
		if pBase then
			addPrompt(
				pBase,
				"Call Assigned Room",
				"Rotary Phone",
				Enum.KeyCode.T,
				DeskProps.callCurrentRoom
			)
			addClick(pBase, DeskProps.callCurrentRoom)
		end
	end

	-- 5. UV Blacklight
	local uvPart = makePart(
		"UVLamp",
		Enum.PartType.Block,
		Vector3.new(0.6, 0.2, 0.3),
		CFrame.new(-3.5, 4.96, 5.4),
		Color3.fromRGB(40, 20, 60),
		Enum.Material.Metal,
		lobby
	)
	uvLight = Instance.new("PointLight")
	uvLight.Color = Color3.fromRGB(160, 40, 255)
	uvLight.Brightness = 0
	uvLight.Range = 12
	uvLight.Shadows = true
	uvLight.Parent = uvPart
	addPrompt(uvPart, "Toggle UV Blacklight", "UV Lamp", Enum.KeyCode.Q, DeskProps.toggleUVLight)
	addClick(uvPart, DeskProps.toggleUVLight)

	-- 6. Interactive Guest Ledger Clipboard (X = -2.4, Y = 4.92, Z = 4.6)
	local board = makePart(
		"GuestLedger",
		Enum.PartType.Block,
		Vector3.new(1.9, 0.08, 2.5),
		CFrame.new(-2.4, 4.92, 4.6),
		Color3.fromRGB(85, 60, 40),
		Enum.Material.Wood,
		lobby
	)
	addPrompt(board, "Inspect Ledger", "Guest Registry", Enum.KeyCode.F, DeskCamera.toggleInspect)
	addClick(board, DeskCamera.toggleInspect)

	-- 3D SurfaceGui on Board
	ledgerGui = Instance.new("SurfaceGui")
	ledgerGui.Name = "LedgerSurfaceGui"
	ledgerGui.Face = Enum.NormalId.Top
	ledgerGui.CanvasSize = Vector2.new(420, 560)
	ledgerGui.LightInfluence = 0.90
	ledgerGui.Parent = board

	local paper = Instance.new("Frame")
	paper.Size = UDim2.fromScale(0.92, 0.94)
	paper.Position = UDim2.fromScale(0.04, 0.03)
	paper.BackgroundColor3 = Color3.fromRGB(224, 216, 202)
	paper.BorderSizePixel = 0
	paper.Parent = ledgerGui

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 40)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.SpecialElite
	title.Text = "CRESTVIEW HIGHWAY MOTEL\nGUEST REGISTRATION"
	title.TextColor3 = Color3.fromRGB(24, 20, 18)
	title.TextSize = 15
	title.Parent = paper

	local divider = Instance.new("Frame")
	divider.Size = UDim2.new(0.9, 0, 0, 2)
	divider.Position = UDim2.new(0.05, 0, 0, 46)
	divider.BackgroundColor3 = Color3.fromRGB(140, 125, 110)
	divider.BorderSizePixel = 0
	divider.Parent = paper

	nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.9, 0, 0, 28)
	nameLabel.Position = UDim2.new(0.05, 0, 0, 56)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.RobotoMono
	nameLabel.Text = "NAME: [No guest]"
	nameLabel.TextColor3 = Color3.fromRGB(24, 20, 18)
	nameLabel.TextSize = 14
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = paper

	idNameLabel = Instance.new("TextLabel")
	idNameLabel.Size = UDim2.new(0.9, 0, 0, 28)
	idNameLabel.Position = UDim2.new(0.05, 0, 0, 88)
	idNameLabel.BackgroundTransparency = 1
	idNameLabel.Font = Enum.Font.RobotoMono
	idNameLabel.Text = "ID CARD: [Pending]"
	idNameLabel.TextColor3 = Color3.fromRGB(24, 20, 18)
	idNameLabel.TextSize = 14
	idNameLabel.TextXAlignment = Enum.TextXAlignment.Left
	idNameLabel.Parent = paper

	resLabel = Instance.new("TextLabel")
	resLabel.Size = UDim2.new(0.9, 0, 0, 28)
	resLabel.Position = UDim2.new(0.05, 0, 0, 120)
	resLabel.BackgroundTransparency = 1
	resLabel.Font = Enum.Font.RobotoMono
	resLabel.Text = "RESERVATION: #"
	resLabel.TextColor3 = Color3.fromRGB(24, 20, 18)
	resLabel.TextSize = 14
	resLabel.TextXAlignment = Enum.TextXAlignment.Left
	resLabel.Parent = paper

	roomLabel = Instance.new("TextLabel")
	roomLabel.Size = UDim2.new(0.9, 0, 0, 28)
	roomLabel.Position = UDim2.new(0.05, 0, 0, 152)
	roomLabel.BackgroundTransparency = 1
	roomLabel.Font = Enum.Font.RobotoMono
	roomLabel.Text = "ASSIGNED: Room 101"
	roomLabel.TextColor3 = Color3.fromRGB(24, 20, 18)
	roomLabel.TextSize = 14
	roomLabel.TextXAlignment = Enum.TextXAlignment.Left
	roomLabel.Parent = paper

	cityLabel = Instance.new("TextLabel")
	cityLabel.Size = UDim2.new(0.9, 0, 0, 28)
	cityLabel.Position = UDim2.new(0.05, 0, 0, 184)
	cityLabel.BackgroundTransparency = 1
	cityLabel.Font = Enum.Font.RobotoMono
	cityLabel.Text = "ORIGIN: Portland, OR"
	cityLabel.TextColor3 = Color3.fromRGB(24, 20, 18)
	cityLabel.TextSize = 14
	cityLabel.TextXAlignment = Enum.TextXAlignment.Left
	cityLabel.Parent = paper

	datesLabel = Instance.new("TextLabel")
	datesLabel.Size = UDim2.new(0.9, 0, 0, 48)
	datesLabel.Position = UDim2.new(0.05, 0, 0, 216)
	datesLabel.BackgroundTransparency = 1
	datesLabel.Font = Enum.Font.RobotoMono
	datesLabel.Text = "IN: Oct 24, 2026\nOUT: Oct 25, 2026"
	datesLabel.TextColor3 = Color3.fromRGB(24, 20, 18)
	datesLabel.TextSize = 13
	datesLabel.TextXAlignment = Enum.TextXAlignment.Left
	datesLabel.Parent = paper

	uvWatermarkLabel = Instance.new("TextLabel")
	uvWatermarkLabel.Size = UDim2.new(0.9, 0, 0, 60)
	uvWatermarkLabel.Position = UDim2.new(0.05, 0, 0, 270)
	uvWatermarkLabel.BackgroundTransparency = 1
	uvWatermarkLabel.Font = Enum.Font.SpecialElite
	uvWatermarkLabel.Text = "★ OFFICIAL CRESTVIEW SEAL ★"
	uvWatermarkLabel.TextColor3 = Color3.fromRGB(80, 140, 255)
	uvWatermarkLabel.TextSize = 16
	uvWatermarkLabel.TextTransparency = 1.0
	uvWatermarkLabel.Parent = paper

	zipLabel = Instance.new("TextLabel")
	zipLabel.Size = UDim2.new(0.45, 0, 0, 28)
	zipLabel.Position = UDim2.new(0.05, 0, 0, 240)
	zipLabel.BackgroundTransparency = 1
	zipLabel.Font = Enum.Font.RobotoMono
	zipLabel.Text = "ZIP: 97204"
	zipLabel.TextColor3 = Color3.fromRGB(24, 20, 18)
	zipLabel.TextSize = 14
	zipLabel.TextXAlignment = Enum.TextXAlignment.Left
	zipLabel.Parent = paper

	stayLabel = Instance.new("TextLabel")
	stayLabel.Size = UDim2.new(0.45, 0, 0, 28)
	stayLabel.Position = UDim2.new(0.5, 0, 0, 240)
	stayLabel.BackgroundTransparency = 1
	stayLabel.Font = Enum.Font.RobotoMono
	stayLabel.Text = "STAY: 1 night"
	stayLabel.TextColor3 = Color3.fromRGB(24, 20, 18)
	stayLabel.TextSize = 14
	stayLabel.TextXAlignment = Enum.TextXAlignment.Left
	stayLabel.Parent = paper

	signatureLabel = Instance.new("TextLabel")
	signatureLabel.Size = UDim2.new(0.9, 0, 0, 36)
	signatureLabel.Position = UDim2.new(0.05, 0, 0, 330)
	signatureLabel.BackgroundTransparency = 1
	signatureLabel.Font = Enum.Font.SourceSansItalic
	signatureLabel.Text = "Signature"
	signatureLabel.TextColor3 = Color3.fromRGB(20, 20, 40)
	signatureLabel.TextSize = 22
	signatureLabel.TextXAlignment = Enum.TextXAlignment.Left
	signatureLabel.Parent = paper

	local photoFrame = Instance.new("Frame")
	photoFrame.Size = UDim2.fromOffset(60, 80)
	photoFrame.Position = UDim2.new(0.75, 0, 0, 56)
	photoFrame.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
	photoFrame.Parent = paper
	photoMask = Instance.new("Frame")
	photoMask.Size = UDim2.fromScale(1, 0.4)
	photoMask.Position = UDim2.fromScale(0, 0.2)
	photoMask.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	photoMask.BackgroundTransparency = 1.0
	photoMask.BorderSizePixel = 0
	photoMask.Parent = photoFrame

	-- 2D Inspect Modal (Brought up on [F] press)
	inspectModal =
		Theme.frame(nightDeskGui, UDim2.fromOffset(480, 580), UDim2.new(0.5, -240, 0.5, -290))
	inspectModal.BackgroundColor3 = Color3.fromRGB(224, 216, 202)
	inspectModal.Visible = false
	DeskCamera.setInspectModal(inspectModal)

	local mTitle = Instance.new("TextLabel")
	mTitle.Size = UDim2.new(1, 0, 0, 50)
	mTitle.BackgroundTransparency = 1
	mTitle.Font = Enum.Font.SpecialElite
	mTitle.Text = "CRESTVIEW HIGHWAY MOTEL\nGUEST REGISTRATION LEDGER"
	mTitle.TextColor3 = Color3.fromRGB(20, 18, 16)
	mTitle.TextSize = 18
	mTitle.Parent = inspectModal

	local mDivider = Instance.new("Frame")
	mDivider.Size = UDim2.new(0.9, 0, 0, 2)
	mDivider.Position = UDim2.new(0.05, 0, 0, 56)
	mDivider.BackgroundColor3 = Color3.fromRGB(140, 125, 110)
	mDivider.BorderSizePixel = 0
	mDivider.Parent = inspectModal

	mNameLabel = Instance.new("TextLabel")
	mNameLabel.Size = UDim2.new(0.9, 0, 0, 36)
	mNameLabel.Position = UDim2.new(0.05, 0, 0, 70)
	mNameLabel.BackgroundTransparency = 1
	mNameLabel.Font = Enum.Font.RobotoMono
	mNameLabel.Text = "NAME: [No guest]"
	mNameLabel.TextColor3 = Color3.fromRGB(20, 18, 16)
	mNameLabel.TextSize = 16
	mNameLabel.TextXAlignment = Enum.TextXAlignment.Left
	mNameLabel.Parent = inspectModal

	mIdLabel = Instance.new("TextLabel")
	mIdLabel.Size = UDim2.new(0.9, 0, 0, 36)
	mIdLabel.Position = UDim2.new(0.05, 0, 0, 110)
	mIdLabel.BackgroundTransparency = 1
	mIdLabel.Font = Enum.Font.RobotoMono
	mIdLabel.Text = "ID CARD: [Pending]"
	mIdLabel.TextColor3 = Color3.fromRGB(20, 18, 16)
	mIdLabel.TextSize = 16
	mIdLabel.TextXAlignment = Enum.TextXAlignment.Left
	mIdLabel.Parent = inspectModal

	mResLabel = Instance.new("TextLabel")
	mResLabel.Size = UDim2.new(0.9, 0, 0, 36)
	mResLabel.Position = UDim2.new(0.05, 0, 0, 150)
	mResLabel.BackgroundTransparency = 1
	mResLabel.Font = Enum.Font.RobotoMono
	mResLabel.Text = "RESERVATION: #"
	mResLabel.TextColor3 = Color3.fromRGB(20, 18, 16)
	mResLabel.TextSize = 16
	mResLabel.TextXAlignment = Enum.TextXAlignment.Left
	mResLabel.Parent = inspectModal

	mRoomLabel = Instance.new("TextLabel")
	mRoomLabel.Size = UDim2.new(0.9, 0, 0, 36)
	mRoomLabel.Position = UDim2.new(0.05, 0, 0, 190)
	mRoomLabel.BackgroundTransparency = 1
	mRoomLabel.Font = Enum.Font.RobotoMono
	mRoomLabel.Text = "ASSIGNED: Room 101"
	mRoomLabel.TextColor3 = Color3.fromRGB(20, 18, 16)
	mRoomLabel.TextSize = 16
	mRoomLabel.TextXAlignment = Enum.TextXAlignment.Left
	mRoomLabel.Parent = inspectModal

	mCityLabel = Instance.new("TextLabel")
	mCityLabel.Size = UDim2.new(0.9, 0, 0, 36)
	mCityLabel.Position = UDim2.new(0.05, 0, 0, 230)
	mCityLabel.BackgroundTransparency = 1
	mCityLabel.Font = Enum.Font.RobotoMono
	mCityLabel.Text = "ORIGIN: Portland, OR"
	mCityLabel.TextColor3 = Color3.fromRGB(20, 18, 16)
	mCityLabel.TextSize = 16
	mCityLabel.TextXAlignment = Enum.TextXAlignment.Left
	mCityLabel.Parent = inspectModal

	mDatesLabel = Instance.new("TextLabel")
	mDatesLabel.Size = UDim2.new(0.9, 0, 0, 50)
	mDatesLabel.Position = UDim2.new(0.05, 0, 0, 270)
	mDatesLabel.BackgroundTransparency = 1
	mDatesLabel.Font = Enum.Font.RobotoMono
	mDatesLabel.Text = "CHECK-IN:  Oct 24, 2026\nCHECK-OUT: Oct 25, 2026"
	mDatesLabel.TextColor3 = Color3.fromRGB(20, 18, 16)
	mDatesLabel.TextSize = 15
	mDatesLabel.TextXAlignment = Enum.TextXAlignment.Left
	mDatesLabel.Parent = inspectModal

	mWatermarkLabel = Instance.new("TextLabel")
	mWatermarkLabel.Size = UDim2.new(0.9, 0, 0, 60)
	mWatermarkLabel.Position = UDim2.new(0.05, 0, 0, 340)
	mWatermarkLabel.BackgroundTransparency = 1
	mWatermarkLabel.Font = Enum.Font.SpecialElite
	mWatermarkLabel.Text = "★ OFFICIAL CRESTVIEW SEAL ★"
	mWatermarkLabel.TextColor3 = Color3.fromRGB(60, 110, 225)
	mWatermarkLabel.TextSize = 18
	mWatermarkLabel.TextTransparency = 1.0
	mWatermarkLabel.Parent = inspectModal

	mZipLabel = Instance.new("TextLabel")
	mZipLabel.Size = UDim2.new(0.45, 0, 0, 36)
	mZipLabel.Position = UDim2.new(0.05, 0, 0, 310)
	mZipLabel.BackgroundTransparency = 1
	mZipLabel.Font = Enum.Font.RobotoMono
	mZipLabel.Text = "ZIP: 97204"
	mZipLabel.TextColor3 = Color3.fromRGB(20, 18, 16)
	mZipLabel.TextSize = 16
	mZipLabel.TextXAlignment = Enum.TextXAlignment.Left
	mZipLabel.Parent = inspectModal

	mStayLabel = Instance.new("TextLabel")
	mStayLabel.Size = UDim2.new(0.45, 0, 0, 36)
	mStayLabel.Position = UDim2.new(0.5, 0, 0, 310)
	mStayLabel.BackgroundTransparency = 1
	mStayLabel.Font = Enum.Font.RobotoMono
	mStayLabel.Text = "STAY: 1 night"
	mStayLabel.TextColor3 = Color3.fromRGB(20, 18, 16)
	mStayLabel.TextSize = 16
	mStayLabel.TextXAlignment = Enum.TextXAlignment.Left
	mStayLabel.Parent = inspectModal

	mSignatureLabel = Instance.new("TextLabel")
	mSignatureLabel.Size = UDim2.new(0.9, 0, 0, 46)
	mSignatureLabel.Position = UDim2.new(0.05, 0, 0, 420)
	mSignatureLabel.BackgroundTransparency = 1
	mSignatureLabel.Font = Enum.Font.SourceSansItalic
	mSignatureLabel.Text = "Signature"
	mSignatureLabel.TextColor3 = Color3.fromRGB(20, 20, 40)
	mSignatureLabel.TextSize = 26
	mSignatureLabel.TextXAlignment = Enum.TextXAlignment.Left
	mSignatureLabel.Parent = inspectModal

	local mPhotoFrame = Instance.new("Frame")
	mPhotoFrame.Size = UDim2.fromOffset(80, 100)
	mPhotoFrame.Position = UDim2.new(0.75, 0, 0, 70)
	mPhotoFrame.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
	mPhotoFrame.Parent = inspectModal
	mPhotoMask = Instance.new("Frame")
	mPhotoMask.Size = UDim2.fromScale(1, 0.4)
	mPhotoMask.Position = UDim2.fromScale(0, 0.2)
	mPhotoMask.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	mPhotoMask.BackgroundTransparency = 1.0
	mPhotoMask.BorderSizePixel = 0
	mPhotoMask.Parent = mPhotoFrame

	local mCloseBtn = Theme.button(
		inspectModal,
		UDim2.new(0.9, 0, 0, 44),
		UDim2.new(0.05, 0, 1, -54),
		"CLOSE INSPECTION [F / ESC]"
	)
	mCloseBtn.BackgroundColor3 = Color3.fromRGB(45, 50, 55)
	mCloseBtn.TextColor3 = Theme.ink
	mCloseBtn.Activated:Connect(DeskCamera.toggleInspect)

	-- 7. Desk Lamp Toggle (X = -6.2, Y = 6.4, Z = 4.6)
	local lampShade = lobby:FindFirstChild("DeskLampShade") :: BasePart?
	if lampShade then
		deskLight = lampShade:FindFirstChild("DeskWarmLight") :: SpotLight?
		addPrompt(lampShade, "Toggle Lamp", "Desk Lamp", Enum.KeyCode.L, function()
			if deskLight then
				deskLight.Enabled = not deskLight.Enabled
				Atmosphere.playSound("bell", lampShade, 0.2)
			end
		end)
		addClick(lampShade, function()
			if deskLight then
				deskLight.Enabled = not deskLight.Enabled
				Atmosphere.playSound("bell", lampShade, 0.2)
			end
		end)
	end

	-- 8. Back-Office Commercial Espresso Machine
	local coffee = lobby:FindFirstChild("CoffeeMachine") :: Model?
	if coffee and coffee.PrimaryPart then
		addPrompt(
			coffee.PrimaryPart,
			"Brew Hot Espresso (+25% Sanity)",
			"Coffee Maker",
			Enum.KeyCode.E,
			function()
				Atmosphere.playSound("flicker", coffee.PrimaryPart, 0.8)
				local brewCoffee = Remotes.get("BrewCoffee")
				brewCoffee:FireServer()
			end
		)
		addClick(coffee.PrimaryPart, function()
			Atmosphere.playSound("flicker", coffee.PrimaryPart, 0.8)
			local brewCoffee = Remotes.get("BrewCoffee")
			brewCoffee:FireServer()
		end)
	end

	-- 9. Hallway Electrical Breaker Box
	local breaker = lobby:FindFirstChild("BreakerBox") :: Model?
	if breaker and breaker.PrimaryPart then
		addPrompt(
			breaker.PrimaryPart,
			"Reset Electrical Breaker",
			"Breaker Box",
			Enum.KeyCode.E,
			function()
				Atmosphere.playSound("stamp", breaker.PrimaryPart, 1.0)
				local resetBreaker = Remotes.get("ResetBreaker")
				resetBreaker:FireServer()
			end
		)
		addClick(breaker.PrimaryPart, function()
			Atmosphere.playSound("stamp", breaker.PrimaryPart, 1.0)
			local resetBreaker = Remotes.get("ResetBreaker")
			resetBreaker:FireServer()
		end)
	end

	-- 10. Vending Machine Interaction (X = 15.5, Y = 4.25, Z = 6)
	local vend = lobby:FindFirstChild("VendingMachine") :: BasePart?
	if vend then
		addPrompt(
			vend,
			"Buy Cold Soda ($5 / +10% Sanity)",
			"Vending Machine",
			Enum.KeyCode.E,
			function()
				Atmosphere.playSound("cash", vend, 0.7)
				local buySoda = Remotes.get("BuySoda")
				buySoda:FireServer()
			end
		)
	end

	-- Keybindings
	ContextActionService:BindAction("RingBellKey", function(_, state)
		if state == Enum.UserInputState.Begin then
			DeskProps.ring()
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.E)

	ContextActionService:BindAction("CallPhoneKey", function(_, state)
		if state == Enum.UserInputState.Begin then
			DeskProps.callCurrentRoom()
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.T)

	ContextActionService:BindAction("ToggleUVKey", function(_, state)
		if state == Enum.UserInputState.Begin then
			DeskProps.toggleUVLight()
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.Q)

	ContextActionService:BindAction("AdmitStampKey", function(_, state)
		if state == Enum.UserInputState.Begin then
			DeskProps.slamStamp(true)
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.Z, Enum.KeyCode.One)

	ContextActionService:BindAction("RefuseStampKey", function(_, state)
		if state == Enum.UserInputState.Begin then
			DeskProps.slamStamp(false)
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.X, Enum.KeyCode.Two)

	bellRang.OnClientEvent:Connect(function()
		DeskProps.animateBell()
	end)

	phoneResponse.OnClientEvent:Connect(function(data)
		if data.audioType == "whisper" then
			Atmosphere.playSound("heartbeat", nil, 0.8)
		elseif data.audioType == "static" then
			Atmosphere.playSound("flicker", nil, 1.2)
			Atmosphere.shakeCamera()
		end
	end)

	uvState.OnClientEvent:Connect(function(data)
		uvActive = data.enabled
		if uvLight then
			uvLight.Brightness = if uvActive then 4.5 else 0
		end
		local text = if data.hasAnomaly
			then `⚠ WARNING: {data.symbolType or "COUNTERFEIT OCCULT MARK"} ⚠`
			else currentWatermarkText
		local color = if data.hasAnomaly
			then Color3.fromRGB(255, 40, 40)
			else Color3.fromRGB(80, 140, 255)
		local trans = if uvActive then 0.1 else 1.0

		if zipLabel then
			zipLabel.Text = "ZIP: ---"
		end
		if stayLabel then
			stayLabel.Text = "STAY: ---"
		end
		if signatureLabel then
			signatureLabel.Text = ""
		end
		if photoMask then
			photoMask.BackgroundTransparency = 1.0
		end

		if mZipLabel then
			mZipLabel.Text = "ZIP: ---"
		end
		if mStayLabel then
			mStayLabel.Text = "STAY: ---"
		end
		if mSignatureLabel then
			mSignatureLabel.Text = ""
		end
		if mPhotoMask then
			mPhotoMask.BackgroundTransparency = 1.0
		end

		if uvWatermarkLabel then
			uvWatermarkLabel.Text = text
			uvWatermarkLabel.TextColor3 = color
			uvWatermarkLabel.TextTransparency = trans
		end
		if mWatermarkLabel then
			mWatermarkLabel.Text = text
			mWatermarkLabel.TextColor3 = color
			mWatermarkLabel.TextTransparency = trans
		end
	end)

	local breakerTrippedRemote = Remotes.get("BreakerTripped")
	local breakerRestoredRemote = Remotes.get("BreakerRestored")

	breakerTrippedRemote.OnClientEvent:Connect(function()
		Atmosphere.playSound("flicker", nil, 1.0)
		Atmosphere.shakeCamera()
		local ceilingLight = lobby:FindFirstChild("CeilingLight")
		if ceilingLight then
			local s = ceilingLight:FindFirstChildWhichIsA("SpotLight")
			if s then
				s.Brightness = 0.2
			end
			local p = ceilingLight:FindFirstChildWhichIsA("PointLight")
			if p then
				p.Brightness = 0.1
			end
		end
		local bModel = lobby:FindFirstChild("BreakerBox")
		if bModel then
			local bLight = bModel:FindFirstChild("BreakerIndicator")
			if bLight and bLight:IsA("BasePart") then
				bLight.Color = Color3.fromRGB(240, 40, 40)
			end
			local bBox = bModel:FindFirstChild("BoxHousing")
			if bBox then
				local sparks = bBox:FindFirstChild("SparksEmitter") :: ParticleEmitter?
				if sparks then
					sparks.Enabled = true
				end
			end
		end
	end)

	breakerRestoredRemote.OnClientEvent:Connect(function()
		Atmosphere.playSound("bell", nil, 0.5)
		local ceilingLight = lobby:FindFirstChild("CeilingLight")
		if ceilingLight then
			local s = ceilingLight:FindFirstChildWhichIsA("SpotLight")
			if s then
				s.Brightness = 5.5
			end
			local p = ceilingLight:FindFirstChildWhichIsA("PointLight")
			if p then
				p.Brightness = 2.2
			end
		end
		local bModel = lobby:FindFirstChild("BreakerBox")
		if bModel then
			local bLight = bModel:FindFirstChild("BreakerIndicator")
			if bLight and bLight:IsA("BasePart") then
				bLight.Color = Color3.fromRGB(50, 220, 90)
			end
			local bBox = bModel:FindFirstChild("BoxHousing")
			if bBox then
				local sparks = bBox:FindFirstChild("SparksEmitter") :: ParticleEmitter?
				if sparks then
					sparks.Enabled = false
				end
			end
		end
	end)
end

function DeskProps.updateLedger(guestData)
	currentRoomNumber = guestData.roomNumber or 101

	currentWatermarkText = guestData.watermarkText or "★ OFFICIAL GENUINE CRESTVIEW SEAL ★"
	if zipLabel then
		zipLabel.Text = `ZIP: {guestData.zipCode or "97204"}`
	end
	if stayLabel then
		stayLabel.Text = `STAY: {guestData.stayLength or "1 night"}`
	end
	if signatureLabel then
		signatureLabel.Font = Enum.Font[guestData.signatureFont or "SourceSansItalic"]
		signatureLabel.Text = guestData.name
	end
	if photoMask then
		photoMask.BackgroundTransparency = guestData.photoMaskTransparency or 1.0
	end

	if mZipLabel then
		mZipLabel.Text = `ZIP: {guestData.zipCode or "97204"}`
	end
	if mStayLabel then
		mStayLabel.Text = `STAY: {guestData.stayLength or "1 night"}`
	end
	if mSignatureLabel then
		mSignatureLabel.Font = Enum.Font[guestData.signatureFont or "SourceSansItalic"]
		mSignatureLabel.Text = guestData.name
	end
	if mPhotoMask then
		mPhotoMask.BackgroundTransparency = guestData.photoMaskTransparency or 1.0
	end

	if nameLabel then
		nameLabel.Text = `NAME: {guestData.name}`
	end
	if idNameLabel then
		idNameLabel.Text = `ID CARD: {guestData.idName or guestData.name}`
	end
	if resLabel then
		resLabel.Text = `RESERVATION: #{guestData.reservation}`
	end
	if roomLabel then
		roomLabel.Text = `ASSIGNED: Room {currentRoomNumber}`
	end
	if cityLabel then
		cityLabel.Text = `ORIGIN: {guestData.cityOrigin or "Portland, OR"}`
	end
	if datesLabel then
		datesLabel.Text =
			`IN: {guestData.checkInDate or "Oct 24, 2026"}\nOUT: {guestData.checkOutDate or "Oct 25, 2026"}`
	end

	-- 2D Modal
	if mNameLabel then
		mNameLabel.Text = `NAME: {guestData.name}`
	end
	if mIdLabel then
		mIdLabel.Text = `ID CARD: {guestData.idName or guestData.name}`
	end
	if mResLabel then
		mResLabel.Text = `RESERVATION: #{guestData.reservation}`
	end
	if mRoomLabel then
		mRoomLabel.Text = `ASSIGNED: Room {currentRoomNumber}`
	end
	if mCityLabel then
		mCityLabel.Text = `ORIGIN: {guestData.cityOrigin or "Portland, OR"}`
	end
	if mDatesLabel then
		mDatesLabel.Text =
			`CHECK-IN:  {guestData.checkInDate or "Oct 24, 2026"}\nCHECK-OUT: {guestData.checkOutDate or "Oct 25, 2026"}`
	end
end

function DeskProps.clearLedger()
	if nameLabel then
		nameLabel.Text = "NAME: [No guest]"
	end
	if idNameLabel then
		idNameLabel.Text = "ID CARD: [Pending]"
	end
	if resLabel then
		resLabel.Text = "RESERVATION: #"
	end
	if roomLabel then
		roomLabel.Text = "ASSIGNED: ---"
	end
	if cityLabel then
		cityLabel.Text = "ORIGIN: ---"
	end
	if datesLabel then
		datesLabel.Text = "IN: ---\nOUT: ---"
	end

	if zipLabel then
		zipLabel.Text = "ZIP: ---"
	end
	if stayLabel then
		stayLabel.Text = "STAY: ---"
	end
	if signatureLabel then
		signatureLabel.Text = ""
	end
	if photoMask then
		photoMask.BackgroundTransparency = 1.0
	end

	if mZipLabel then
		mZipLabel.Text = "ZIP: ---"
	end
	if mStayLabel then
		mStayLabel.Text = "STAY: ---"
	end
	if mSignatureLabel then
		mSignatureLabel.Text = ""
	end
	if mPhotoMask then
		mPhotoMask.BackgroundTransparency = 1.0
	end

	if uvWatermarkLabel then
		uvWatermarkLabel.TextTransparency = 1.0
	end

	if mNameLabel then
		mNameLabel.Text = "NAME: [No guest]"
	end
	if mIdLabel then
		mIdLabel.Text = "ID CARD: [Pending]"
	end
	if mResLabel then
		mResLabel.Text = "RESERVATION: #"
	end
	if mRoomLabel then
		mRoomLabel.Text = "ASSIGNED: ---"
	end
	if mCityLabel then
		mCityLabel.Text = "ORIGIN: ---"
	end
	if mDatesLabel then
		mDatesLabel.Text = "CHECK-IN:  ---\nCHECK-OUT: ---"
	end
	if mWatermarkLabel then
		mWatermarkLabel.TextTransparency = 1.0
	end
end

function DeskProps.ring()
	Viewmodel.playAction("ring", 0.45)
	ringBell:FireServer()
	DeskProps.animateBell()
end

function DeskProps.callCurrentRoom()
	Atmosphere.playSound("bell", nil, 0.3)
	Viewmodel.setPhoneActive(true)
	callRoom:FireServer(currentRoomNumber)
	task.delay(3.0, function()
		Viewmodel.setPhoneActive(false)
	end)
end

function DeskProps.toggleUVLight()
	uvActive = not uvActive
	Viewmodel.setUVActive(uvActive)
	toggleUV:FireServer(uvActive)
end

function DeskProps.animateBell()
	if not plungerStem or not plungerButton then
		return
	end
	Atmosphere.playSound("bell", plungerStem, 1.0)
	local stemOrig = plungerStem.Position
	local btnOrig = plungerButton.Position
	plungerStem.Position = stemOrig - Vector3.new(0, 0.12, 0)
	plungerButton.Position = btnOrig - Vector3.new(0, 0.12, 0)
	task.delay(0.08, function()
		if plungerStem and plungerButton then
			local tw1 = TweenService:Create(
				plungerStem,
				TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
				{ Position = stemOrig }
			)
			local tw2 = TweenService:Create(
				plungerButton,
				TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
				{ Position = btnOrig }
			)
			tw1:Play()
			tw2:Play()
		end
	end)
end

function DeskProps.slamStamp(admit: boolean)
	Viewmodel.playAction("stamp", 0.40)
	local stampModel = if admit then stampAdmitPart else stampRefusePart
	if stampModel and stampModel.PrimaryPart then
		local hrp = stampModel.PrimaryPart
		local origCF = hrp.CFrame
		local downCF = origCF * CFrame.new(0, -0.22, 0)
		local twDown = TweenService:Create(
			hrp,
			TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ CFrame = downCF }
		)
		local twUp = TweenService:Create(
			hrp,
			TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ CFrame = origCF }
		)
		twDown:Play()
		twDown.Completed:Connect(function()
			Atmosphere.playSound("stamp", hrp, 1.0)
			judge:FireServer(admit)
			twUp:Play()
		end)
	else
		judge:FireServer(admit)
	end
end

return DeskProps
