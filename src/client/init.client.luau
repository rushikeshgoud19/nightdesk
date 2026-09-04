--!strict
-- Client bootstrap. Sets up true First-Person FPS character controls,
-- ambient audio, 3D desk interactions, HUD, CRT overlays, and cinematic intro sequence.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))

local AnomalyViewer = require(script:WaitForChild("AnomalyViewer"))
local Atmosphere = require(script:WaitForChild("Atmosphere"))
local DeskCamera = require(script:WaitForChild("DeskCamera"))
local DeskProps = require(script:WaitForChild("DeskProps"))
local DeskUI = require(script:WaitForChild("DeskUI"))
local GuestRenderer = require(script:WaitForChild("GuestRenderer"))
local IntroUI = require(script:WaitForChild("IntroUI"))
local ShopUI = require(script:WaitForChild("ShopUI"))
local Theme = require(script:WaitForChild("Theme"))
local Viewmodel = require(script:WaitForChild("Viewmodel"))

local player = Players.LocalPlayer

-- Setup authentic First-Person character movement
local function setupFirstPersonCharacter(char: Model)
	local hum = char:WaitForChild("Humanoid", 10) :: Humanoid?
	local hrp = char:WaitForChild("HumanoidRootPart", 10) :: BasePart?

	if hum then
		hum.WalkSpeed = 13
		hum.JumpHeight = 0
		hum.JumpPower = 0
		hum.AutoRotate = true
	end

	-- LockFirstPerson already locks the mouse to centre, and Roblox's camera
	-- script owns MouseBehavior from then on -- it rewrites it every frame and
	-- releases it for modals. Setting MouseBehavior here by hand was overwritten
	-- immediately in the best case and fought the modals in the worst.
	player.CameraMode = Enum.CameraMode.LockFirstPerson
	player.CameraMinZoomDistance = 0.5
	player.CameraMaxZoomDistance = 0.5

	-- Ensure player spawns behind the front desk facing the counter
	if char and hrp then
		hrp.Anchored = false
		hrp.CanCollide = true
		char:PivotTo(CFrame.lookAt(Vector3.new(0, 3.5, 7.2), Vector3.new(0, 4.8, 1.8)))
	end
end

if player.Character then
	setupFirstPersonCharacter(player.Character)
end
player.CharacterAdded:Connect(setupFirstPersonCharacter)

local gui = Instance.new("ScreenGui")
gui.Name = "NightDesk"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 10
gui.Parent = player:WaitForChild("PlayerGui")

-- First-person center interaction crosshair dot
local crosshair = Instance.new("Frame")
crosshair.Name = "CenterCrosshair"
crosshair.Size = UDim2.fromOffset(4, 4)
crosshair.Position = UDim2.new(0.5, -2, 0.5, -2)
crosshair.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
crosshair.BackgroundTransparency = 0.4
crosshair.BorderSizePixel = 0
Theme.corner(crosshair, 2)
crosshair.Parent = gui

Atmosphere.init()
DeskProps.init()
DeskCamera.init()
Viewmodel.init()
Theme.attachCRTOverlay(gui)
DeskUI.build(gui)
ShopUI.build(gui)

-- Studio-only. Steps through all 42 anomalies at the desk so each one can be
-- looked at directly instead of waited for. It exists because six body tells and
-- three behaviour tells shipped rendering nothing, and nothing in the game ever
-- put them next to a genuine guest.
AnomalyViewer.setRenderer(GuestRenderer.arrive)
AnomalyViewer.init(gui)

Remotes.get("GuestArrived").OnClientEvent:Connect(DeskUI.onGuest)
Remotes.get("ShiftUpdate").OnClientEvent:Connect(DeskUI.onResult)
Remotes.get("SanityUpdate").OnClientEvent:Connect(DeskUI.onSanity)
Remotes.get("ShiftEnded").OnClientEvent:Connect(DeskUI.onShiftEnded)
Remotes.get("ShopState").OnClientEvent:Connect(ShopUI.render)

-- Which tools are actually installed. Sent at the start of every shift and
-- after every purchase.
Remotes.get("Loadout").OnClientEvent:Connect(function(payload)
	DeskCamera.setHasCCTV(payload.hasCCTV == true)
	DeskProps.setHasCoffee(payload.hasCoffee == true)
end)

-- Display starting cinematic briefing & timecard punch-in on boot
IntroUI.show(function()
	print("[nightdesk] clerk punched in - night shift active")
end)

print("[nightdesk] first-person FPS client fully initialized")
