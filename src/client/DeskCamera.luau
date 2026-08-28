--!strict
-- First-Person FPS Camera Controller with Document Inspection Overlay [F]
-- and Multi-Channel CCTV Surveillance Feeds [C].

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Atmosphere = require(script.Parent:WaitForChild("Atmosphere"))

local DeskCamera = {}

local CCTV_CAMERAS = {
	{
		name = "CAM 01: PARKING LOT / HIGHWAY",
		cf = CFrame.lookAt(Vector3.new(0, 11.5, -28.0), Vector3.new(0, 4.5, -14.0)),
	},
	{
		name = "CAM 02: GUEST HALLWAY (ROOMS 101-108)",
		cf = CFrame.lookAt(Vector3.new(-16.0, 8.5, 12.0), Vector3.new(-16.0, 5.0, -4.0)),
	},
	{
		name = "CAM 03: WAITING LOUNGE & VENDING",
		cf = CFrame.lookAt(Vector3.new(14.0, 9.5, 6.0), Vector3.new(12.0, 3.0, -5.0)),
	},
}

local currentCamMode: "fps" | "inspect" | "cctv" = "fps"
local currentCctvIndex = 1

local cctvOverlayGui: ScreenGui?
local cctvLabel: TextLabel?
local cctvTimeLabel: TextLabel?
local inspectModalGui: Frame?

function DeskCamera.getMode(): string
	return currentCamMode
end

function DeskCamera.toggleInspect()
	local player = Players.LocalPlayer
	local camera = Workspace.CurrentCamera
	local Viewmodel = require(script.Parent:WaitForChild("Viewmodel"))

	if currentCamMode == "inspect" then
		currentCamMode = "fps"
		Viewmodel.setInspecting(false)
		if inspectModalGui then
			inspectModalGui.Visible = false
		end
		if camera then
			camera.CameraType = Enum.CameraType.Custom
			player.CameraMode = Enum.CameraMode.LockFirstPerson
		end
	else
		currentCamMode = "inspect"
		Viewmodel.setInspecting(true)
		if cctvOverlayGui then
			cctvOverlayGui.Enabled = false
		end
		if inspectModalGui then
			inspectModalGui.Visible = true
		end
	end
	Atmosphere.playSound("paper", nil, 0.5)
end

function DeskCamera.cycleCCTV()
	local player = Players.LocalPlayer
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end

	if currentCamMode ~= "cctv" then
		currentCamMode = "cctv"
		currentCctvIndex = 1
		camera.CameraType = Enum.CameraType.Scriptable
		if inspectModalGui then
			inspectModalGui.Visible = false
		end
	else
		currentCctvIndex += 1
		if currentCctvIndex > #CCTV_CAMERAS then
			currentCamMode = "fps"
			camera.CameraType = Enum.CameraType.Custom
			player.CameraMode = Enum.CameraMode.LockFirstPerson
			if cctvOverlayGui then
				cctvOverlayGui.Enabled = false
			end
			Atmosphere.playSound("bell", nil, 0.15)
			return
		end
	end

	local camData = CCTV_CAMERAS[currentCctvIndex]
	camera.CFrame = camData.cf
	Atmosphere.playSound("stamp", nil, 0.3)

	if cctvOverlayGui and cctvLabel then
		cctvOverlayGui.Enabled = true
		cctvLabel.Text = `● REC [{camData.name}]`
	end
end

function DeskCamera.exitToFPS()
	local player = Players.LocalPlayer
	local camera = Workspace.CurrentCamera

	currentCamMode = "fps"
	if cctvOverlayGui then
		cctvOverlayGui.Enabled = false
	end
	if inspectModalGui then
		inspectModalGui.Visible = false
	end
	if camera then
		camera.CameraType = Enum.CameraType.Custom
		player.CameraMode = Enum.CameraMode.LockFirstPerson
	end
end

function DeskCamera.setInspectModal(frame: Frame)
	inspectModalGui = frame
end

function DeskCamera.init()
	local player = Players.LocalPlayer
	local camera = Workspace.CurrentCamera
	if camera then
		camera.CameraType = Enum.CameraType.Custom
		player.CameraMode = Enum.CameraMode.LockFirstPerson
	end

	local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui

	-- CCTV Screen Overlay
	cctvOverlayGui = Instance.new("ScreenGui")
	cctvOverlayGui.Name = "CCTVOverlay"
	cctvOverlayGui.ResetOnSpawn = false
	cctvOverlayGui.IgnoreGuiInset = true
	cctvOverlayGui.Enabled = false
	cctvOverlayGui.Parent = playerGui

	local crtTint = Instance.new("Frame")
	crtTint.Size = UDim2.fromScale(1, 1)
	crtTint.BackgroundColor3 = Color3.fromRGB(12, 28, 16)
	crtTint.BackgroundTransparency = 0.88
	crtTint.BorderSizePixel = 0
	crtTint.Parent = cctvOverlayGui

	cctvLabel = Instance.new("TextLabel")
	cctvLabel.Size = UDim2.new(1, -64, 0, 40)
	cctvLabel.Position = UDim2.fromOffset(32, 24)
	cctvLabel.BackgroundTransparency = 1
	cctvLabel.Font = Enum.Font.SpecialElite
	cctvLabel.Text = "● REC [CAM 01: PARKING LOT / HIGHWAY]"
	cctvLabel.TextColor3 = Color3.fromRGB(80, 255, 120)
	cctvLabel.TextSize = 20
	cctvLabel.TextXAlignment = Enum.TextXAlignment.Left
	cctvLabel.Parent = cctvOverlayGui

	cctvTimeLabel = Instance.new("TextLabel")
	cctvTimeLabel.Size = UDim2.new(1, -64, 0, 40)
	cctvTimeLabel.Position = UDim2.fromOffset(32, 60)
	cctvTimeLabel.BackgroundTransparency = 1
	cctvTimeLabel.Font = Enum.Font.RobotoMono
	cctvTimeLabel.Text = "OCT 24, 2026  02:14:38 AM  [LIVE FEED]"
	cctvTimeLabel.TextColor3 = Color3.fromRGB(80, 255, 120)
	cctvTimeLabel.TextSize = 14
	cctvTimeLabel.TextXAlignment = Enum.TextXAlignment.Left
	cctvTimeLabel.Parent = cctvOverlayGui

	local guideLabel = Instance.new("TextLabel")
	guideLabel.Size = UDim2.new(1, -64, 0, 30)
	guideLabel.Position = UDim2.new(0, 32, 1, -50)
	guideLabel.BackgroundTransparency = 1
	guideLabel.Font = Enum.Font.RobotoMono
	guideLabel.Text = "[C] Next Camera  ·  [ESC] / [F] Exit to First-Person Desk"
	guideLabel.TextColor3 = Color3.fromRGB(160, 255, 180)
	guideLabel.TextSize = 14
	guideLabel.TextXAlignment = Enum.TextXAlignment.Left
	guideLabel.Parent = cctvOverlayGui

	-- Keybinds
	ContextActionService:BindAction("Desk_CCTV", function(_, state)
		if state == Enum.UserInputState.Begin then
			DeskCamera.cycleCCTV()
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.C)

	ContextActionService:BindAction("Desk_ExitSpecialView", function(_, state)
		if state == Enum.UserInputState.Begin and currentCamMode ~= "fps" then
			DeskCamera.exitToFPS()
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.Escape)
end

return DeskCamera
