--!strict
-- Atmosphere manager: Spatial rainstorm soundscape, 2:00 AM volumetric fog,
-- fluorescent tube flickers, and psychoacoustic sanity effects.
--
-- Atmosphere is the core product in anomaly-horror. Subtle beats dramatic.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Atmosphere = {}

local colorCorrection: ColorCorrectionEffect?
local bloom: BloomEffect?
local atmosInstance: Atmosphere?
local humSound: Sound?
local rainSound: Sound?

local AUDIO = {
	bell = { id = "rbxasset://sounds/electronicpingshort.wav", speed = 1.7, volume = 0.8 },
	thud = { id = "rbxasset://sounds/snap.mp3", speed = 0.65, volume = 0.85 },
	footstep = { id = "rbxasset://sounds/action_footsteps_plastic.mp3", speed = 1.1, volume = 0.35 },
	paper = { id = "rbxasset://sounds/button.wav", speed = 1.4, volume = 0.4 },
	cash = { id = "rbxasset://sounds/electronicpingshort.wav", speed = 2.2, volume = 0.7 },
	flicker = { id = "rbxasset://sounds/switch.wav", speed = 0.9, volume = 0.3 },
	heartbeat = { id = "rbxasset://sounds/splat.mp3", speed = 0.45, volume = 0.9 },
	door = { id = "rbxasset://sounds/switch.wav", speed = 0.55, volume = 0.45 },
	stamp = { id = "rbxasset://sounds/snap.mp3", speed = 0.9, volume = 0.9 },
}

function Atmosphere.init()
	-- 1. Volumetric Atmosphere
	atmosInstance = Lighting:FindFirstChild("NightDesk_Atmos") :: Atmosphere?
	if not atmosInstance then
		local a = Instance.new("Atmosphere")
		a.Name = "NightDesk_Atmos"
		a.Density = 0.38
		a.Offset = 0.25
		a.Color = Color3.fromRGB(32, 36, 48)
		a.Decay = Color3.fromRGB(15, 18, 26)
		a.Glare = 0.05
		a.Haze = 1.2
		a.Parent = Lighting
		atmosInstance = a
	end

	-- 2. Post-processing Color Correction (Desaturated 2:00 AM Noir)
	colorCorrection = Lighting:FindFirstChild("NightDesk_CC") :: ColorCorrectionEffect?
	if not colorCorrection then
		local cc = Instance.new("ColorCorrectionEffect")
		cc.Name = "NightDesk_CC"
		cc.Brightness = -0.02
		cc.Contrast = 0.12
		cc.Saturation = -0.18
		cc.TintColor = Color3.fromRGB(240, 245, 252)
		cc.Parent = Lighting
		colorCorrection = cc
	end

	bloom = Lighting:FindFirstChild("NightDesk_Bloom") :: BloomEffect?
	if not bloom then
		local b = Instance.new("BloomEffect")
		b.Name = "NightDesk_Bloom"
		b.Intensity = 0.1
		b.Size = 10
		b.Threshold = 2.0
		b.Parent = Lighting
		bloom = b
	end

	-- 3. Exterior Spatial Rain Audio
	task.spawn(function()
		local lobby = Workspace:WaitForChild("Lobby", 5)
		if not lobby then
			return
		end

		local neonSign = lobby:WaitForChild("NeonSign_Glow", 5) :: BasePart?
		if neonSign then
			rainSound = Instance.new("Sound")
			rainSound.Name = "RainStormAmbient"
			rainSound.SoundId = "rbxasset://sounds/action_footsteps_plastic.mp3"
			rainSound.PlaybackSpeed = 0.35
			rainSound.Volume = 0.18
			rainSound.Looped = true
			rainSound.RollOffMinDistance = 10
			rainSound.RollOffMaxDistance = 55
			rainSound.Parent = neonSign
			rainSound:Play()
		end

		-- Fluorescent hum at ceiling light
		local ceilingLight = lobby:WaitForChild("CeilingLight", 5) :: BasePart?
		if ceilingLight then
			humSound = Instance.new("Sound")
			humSound.Name = "FluorescentHum"
			humSound.SoundId = "rbxasset://sounds/switch.wav"
			humSound.PlaybackSpeed = 0.2
			humSound.Volume = 0.04
			humSound.Looped = true
			humSound.RollOffMinDistance = 5
			humSound.RollOffMaxDistance = 30
			humSound.Parent = ceilingLight
			humSound:Play()

			local light = ceilingLight:FindFirstChildWhichIsA("Light")
			if light then
				local baseBrightness = light.Brightness
				task.spawn(function()
					local rng = Random.new()
					while true do
						task.wait(rng:NextNumber(7, 18))
						for _ = 1, rng:NextInteger(1, 3) do
							light.Brightness = baseBrightness * 0.20
							Atmosphere.playSound("flicker", ceilingLight, 0.2)
							task.wait(0.04)
							light.Brightness = baseBrightness
							task.wait(0.06)
						end
					end
				end)
			end
		end
	end)

	-- 4. Dynamic First-Person Footsteps
	local player = Players.LocalPlayer
	local function bindFootsteps(char: Model)
		local hum = char:WaitForChild("Humanoid", 10) :: Humanoid?
		local hrp = char:WaitForChild("HumanoidRootPart", 10) :: BasePart?
		if not hum or not hrp then
			return
		end

		local lastStep = 0
		RunService.Heartbeat:Connect(function()
			if hum.MoveDirection.Magnitude > 0.1 and hum.FloorMaterial ~= Enum.Material.Air then
				local now = os.clock()
				if now - lastStep > 0.40 then
					lastStep = now
					local speed = if hum.FloorMaterial == Enum.Material.Fabric then 0.9 else 1.15
					local vol = if hum.FloorMaterial == Enum.Material.Fabric then 0.16 else 0.28
					local s = Instance.new("Sound")
					s.SoundId = AUDIO.footstep.id
					s.PlaybackSpeed = speed
					s.Volume = vol
					s.RollOffMinDistance = 4
					s.RollOffMaxDistance = 25
					s.Parent = hrp
					s:Play()
					s.Ended:Connect(function()
						s:Destroy()
					end)
				end
			end
		end)
	end

	if player.Character then
		bindFootsteps(player.Character)
	end
	player.CharacterAdded:Connect(bindFootsteps)
end

function Atmosphere.playSound(soundName: string, parent: Instance?, volumeOverride: number?)
	local def = AUDIO[soundName]
	if not def then
		return
	end

	local s = Instance.new("Sound")
	s.SoundId = def.id
	s.PlaybackSpeed = def.speed or 1.0
	s.Volume = volumeOverride or def.volume or 0.6
	s.RollOffMinDistance = 5
	s.RollOffMaxDistance = 40
	s.Parent = parent or Workspace
	s:Play()
	s.Ended:Connect(function()
		s:Destroy()
	end)
end

function Atmosphere.onSanityChanged(sanity: number)
	if not colorCorrection then
		return
	end

	local sanityRatio = math.clamp(sanity / 100, 0, 1)
	local targetSaturation = -0.18 - (1 - sanityRatio) * 0.45
	local targetContrast = 0.12 + (1 - sanityRatio) * 0.25
	local targetTint = Color3.fromRGB(
		240 + math.floor((1 - sanityRatio) * 15),
		math.floor(245 * sanityRatio + 180 * (1 - sanityRatio)),
		math.floor(252 * sanityRatio + 180 * (1 - sanityRatio))
	)

	TweenService
		:Create(
			colorCorrection,
			TweenInfo.new(1.0, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				Saturation = targetSaturation,
				Contrast = targetContrast,
				TintColor = targetTint,
			}
		)
		:Play()
end

-- Shake through Humanoid.CameraOffset, never by writing Camera.CFrame.
--
-- The old version snapshotted the camera, wrote absolute CFrames for ~150ms,
-- then restored the snapshot. In first person that fights Roblox's own camera
-- script, which writes CFrame every RenderStepped -- so the player's look kept
-- getting yanked back to wherever they were aiming when the shake started, and
-- the final restore discarded everything they looked at during it. It reads as
-- "the camera is stuck".
--
-- CameraOffset is applied relative to the head, so it composes with player look
-- instead of overwriting it, and unwinding it is a single assignment.
local shakeToken = 0

function Atmosphere.shakeCamera()
	local character = Players.LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	-- A shake starting mid-shake invalidates the earlier one, so two cannot fight
	-- over the offset or leave it stranded away from zero.
	shakeToken += 1
	local token = shakeToken

	task.spawn(function()
		local rng = Random.new()
		for _ = 1, 6 do
			if shakeToken ~= token or humanoid.Parent == nil then
				return
			end
			humanoid.CameraOffset =
				Vector3.new(rng:NextNumber(-0.15, 0.15), rng:NextNumber(-0.15, 0.15), 0)
			task.wait(0.025)
		end
		if shakeToken == token and humanoid.Parent ~= nil then
			humanoid.CameraOffset = Vector3.zero
		end
	end)
end

return Atmosphere
