--!strict
-- High-Immersion First-Person Viewmodel & Kinematic Arms:
-- Provides responsive first-person clerk hands with natural walking sway,
-- bell press reach, stamp slam recoil, UV flashlight hold, and phone handset kinematics.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Viewmodel = {}

local viewmodelModel: Model?
local rootPart: BasePart?
local leftArm: BasePart?
local rightArm: BasePart?
local leftSleeve: BasePart?
local rightSleeve: BasePart?
local leftCuff: BasePart?
local rightCuff: BasePart?
local uvFlashlightProp: BasePart?
local uvLightProp: PointLight?

-- Offsets relative to camera CFrame (Prominent first-person hands framing)
local DEFAULT_OFFSET = CFrame.new(0, -0.85, -1.45)
local currentAnimAction: "idle" | "ring" | "stamp" | "phone" | "inspect" = "idle"
local animProgress = 0
local animTween: Tween?

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
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

function Viewmodel.init()
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end

	local vm = Instance.new("Model")
	vm.Name = "ClerkViewmodel"

	rootPart = makePart(
		"VMRoot",
		Enum.PartType.Block,
		Vector3.new(0.2, 0.2, 0.2),
		CFrame.identity,
		Color3.new(),
		Enum.Material.SmoothPlastic,
		vm
	)
	rootPart.Transparency = 1.0
	vm.PrimaryPart = rootPart

	-- Left Arm & Sleeve
	leftSleeve = makePart(
		"LeftSleeve",
		Enum.PartType.Block,
		Vector3.new(0.65, 1.45, 0.65),
		CFrame.new(-0.85, -0.4, 0.2),
		Color3.fromRGB(36, 40, 48),
		Enum.Material.Fabric,
		vm
	)
	leftCuff = makePart(
		"LeftCuff",
		Enum.PartType.Block,
		Vector3.new(0.67, 0.12, 0.67),
		CFrame.new(-0.85, -1.18, 0.2),
		Color3.fromRGB(245, 245, 250),
		Enum.Material.Fabric,
		vm
	)
	leftArm = makePart(
		"LeftHand",
		Enum.PartType.Block,
		Vector3.new(0.55, 0.65, 0.55),
		CFrame.new(-0.85, -1.55, 0.2),
		Color3.fromRGB(215, 175, 140),
		Enum.Material.SmoothPlastic,
		vm
	)

	-- Right Arm & Sleeve
	rightSleeve = makePart(
		"RightSleeve",
		Enum.PartType.Block,
		Vector3.new(0.65, 1.45, 0.65),
		CFrame.new(0.85, -0.4, 0.2),
		Color3.fromRGB(36, 40, 48),
		Enum.Material.Fabric,
		vm
	)
	rightCuff = makePart(
		"RightCuff",
		Enum.PartType.Block,
		Vector3.new(0.67, 0.12, 0.67),
		CFrame.new(0.85, -1.18, 0.2),
		Color3.fromRGB(245, 245, 250),
		Enum.Material.Fabric,
		vm
	)
	rightArm = makePart(
		"RightHand",
		Enum.PartType.Block,
		Vector3.new(0.55, 0.65, 0.55),
		CFrame.new(0.85, -1.55, 0.2),
		Color3.fromRGB(215, 175, 140),
		Enum.Material.SmoothPlastic,
		vm
	)

	-- UV Flashlight Attachment on Right Hand
	uvFlashlightProp = makePart(
		"UVFlashlight",
		Enum.PartType.Cylinder,
		Vector3.new(0.85, 0.25, 0.25),
		CFrame.new(0.85, -1.65, -0.4) * CFrame.Angles(0, 0, math.rad(90)),
		Color3.fromRGB(45, 30, 60),
		Enum.Material.Metal,
		vm
	)
	uvFlashlightProp.Transparency = 1.0

	uvLightProp = Instance.new("PointLight")
	uvLightProp.Color = Color3.fromRGB(160, 40, 255)
	uvLightProp.Brightness = 0
	uvLightProp.Range = 10
	uvLightProp.Parent = uvFlashlightProp

	vm.Parent = camera
	viewmodelModel = vm

	-- RenderStep loop: updates viewmodel position with natural walking sway & actions
	local player = Players.LocalPlayer
	RunService:BindToRenderStep(
		"NightDeskViewmodel",
		Enum.RenderPriority.Camera.Value + 2,
		function(_dt: number)
			local curCam = Workspace.CurrentCamera
			if not curCam or not rootPart or not viewmodelModel then
				return
			end

			local char = player.Character
			local hum = if char then char:FindFirstChildOfClass("Humanoid") else nil
			local isWalking = hum ~= nil and hum.MoveDirection.Magnitude > 0.1

			local t = os.clock()
			local walkSwayX = if isWalking
				then math.sin(t * 9.0) * 0.045
				else math.sin(t * 1.8) * 0.012
			local walkSwayY = if isWalking
				then math.abs(math.sin(t * 9.0)) * 0.035
				else math.sin(t * 1.8 * 2) * 0.008

			local camCF = curCam.CFrame
			local baseTargetCF = camCF * DEFAULT_OFFSET * CFrame.new(walkSwayX, walkSwayY, 0)
			rootPart.CFrame = baseTargetCF

			-- Compute Arm Relative Offsets based on Active Animation Action
			local lArmOffset = CFrame.new(-0.85, -0.4, 0.2)
			local rArmOffset = CFrame.new(0.85, -0.4, 0.2)

			if currentAnimAction == "ring" then
				-- Reach right arm forward to press bell
				local reachZ = -math.sin(animProgress * math.pi) * 0.95
				local reachY = -math.sin(animProgress * math.pi) * 0.35
				rArmOffset = rArmOffset
					* CFrame.new(-0.25, reachY, reachZ)
					* CFrame.Angles(math.rad(25 * math.sin(animProgress * math.pi)), 0, 0)
			elseif currentAnimAction == "stamp" then
				-- Lift right arm and slam down
				local slamY = if animProgress < 0.4
					then animProgress * 0.8
					else -math.sin((animProgress - 0.4) / 0.6 * math.pi * 0.5) * 0.6
				local slamZ = -math.sin(animProgress * math.pi) * 0.65
				rArmOffset = rArmOffset
					* CFrame.new(0.1, slamY, slamZ)
					* CFrame.Angles(math.rad(-30 * math.sin(animProgress * math.pi)), 0, 0)
			elseif currentAnimAction == "phone" then
				-- Left arm brings handset to ear
				lArmOffset = lArmOffset
					* CFrame.new(0.45, 0.95, -0.35)
					* CFrame.Angles(math.rad(45), math.rad(30), math.rad(-25))
			elseif currentAnimAction == "inspect" then
				-- Two arms lift clipboard forward
				lArmOffset = lArmOffset
					* CFrame.new(0.35, 0.55, -0.65)
					* CFrame.Angles(math.rad(35), math.rad(15), 0)
				rArmOffset = rArmOffset
					* CFrame.new(-0.35, 0.55, -0.65)
					* CFrame.Angles(math.rad(35), math.rad(-15), 0)
			end

			if leftSleeve and leftCuff and leftArm then
				leftSleeve.CFrame = baseTargetCF * lArmOffset
				leftCuff.CFrame = leftSleeve.CFrame * CFrame.new(0, -0.78, 0)
				leftArm.CFrame = leftSleeve.CFrame * CFrame.new(0, -1.15, 0)
			end

			if rightSleeve and rightCuff and rightArm then
				rightSleeve.CFrame = baseTargetCF * rArmOffset
				rightCuff.CFrame = rightSleeve.CFrame * CFrame.new(0, -0.78, 0)
				rightArm.CFrame = rightSleeve.CFrame * CFrame.new(0, -1.15, 0)
				if uvFlashlightProp then
					uvFlashlightProp.CFrame = rightArm.CFrame
						* CFrame.new(0, -0.2, -0.35)
						* CFrame.Angles(0, 0, math.rad(90))
				end
			end
		end
	)
end

function Viewmodel.playAction(action: "ring" | "stamp" | "phone" | "inspect", duration: number)
	if animTween then
		animTween:Cancel()
	end
	currentAnimAction = action
	animProgress = 0

	local numVal = Instance.new("NumberValue")
	numVal.Value = 0

	local tw = TweenService:Create(
		numVal,
		TweenInfo.new(duration or 0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Value = 1 }
	)
	tw:Play()

	numVal.Changed:Connect(function(val)
		animProgress = val
	end)

	tw.Completed:Connect(function()
		currentAnimAction = "idle"
		animProgress = 0
		numVal:Destroy()
	end)
end

function Viewmodel.setUVActive(active: boolean)
	if uvFlashlightProp and uvLightProp then
		uvFlashlightProp.Transparency = if active then 0.0 else 1.0
		uvLightProp.Brightness = if active then 3.5 else 0
	end
end

function Viewmodel.setInspecting(inspecting: boolean)
	currentAnimAction = if inspecting then "inspect" else "idle"
	animProgress = if inspecting then 1.0 else 0
end

function Viewmodel.setPhoneActive(active: boolean)
	currentAnimAction = if active then "phone" else "idle"
	animProgress = if active then 1.0 else 0
end

return Viewmodel
