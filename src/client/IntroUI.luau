--!strict
-- Cinematic Analog Horror Prologue & Timecard Punch-In Intro Screen
-- Sets the eerie 2:00 AM mood, teaches core controls, and transitions into the first-person shift.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))

local Atmosphere = require(script.Parent:WaitForChild("Atmosphere"))
local Theme = require(script.Parent:WaitForChild("Theme"))

local startShift = Remotes.get("StartShift")

local IntroUI = {}

local introGui: ScreenGui?
local curtain: Frame?

function IntroUI.show(onComplete: () -> ())
	local player = game:GetService("Players").LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	introGui = Instance.new("ScreenGui")
	introGui.Name = "NightDesk_Intro"
	introGui.ResetOnSpawn = false
	introGui.IgnoreGuiInset = true
	introGui.DisplayOrder = 500
	introGui.Parent = playerGui

	curtain = Instance.new("Frame")
	curtain.Name = "IntroCurtain"
	curtain.Size = UDim2.fromScale(1, 1)
	curtain.Position = UDim2.new()
	curtain.BackgroundColor3 = Color3.fromRGB(6, 8, 8)
	curtain.BorderSizePixel = 0
	curtain.Parent = introGui

	-- Vignette
	local vignette = Instance.new("ImageLabel")
	vignette.Size = UDim2.fromScale(1, 1)
	vignette.BackgroundTransparency = 1
	vignette.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
	vignette.ImageColor3 = Color3.fromRGB(0, 0, 0)
	vignette.ImageTransparency = 0.5
	vignette.Parent = curtain

	-- Main Briefing Container Card
	local card = Theme.card(
		curtain,
		UDim2.fromOffset(680, 440),
		UDim2.new(0.5, -340, 0.5, -220),
		Color3.fromRGB(12, 15, 14),
		Color3.fromRGB(45, 60, 52)
	)

	local header = Theme.label(
		card,
		UDim2.new(1, -40, 0, 32),
		UDim2.fromOffset(24, 20),
		22,
		Enum.Font.SpecialElite
	)
	header.TextColor3 = Color3.fromRGB(245, 215, 130)
	header.Text = "CRESTVIEW HIGHWAY MOTEL"

	local subHeader = Theme.label(
		card,
		UDim2.new(1, -40, 0, 20),
		UDim2.fromOffset(24, 52),
		12,
		Enum.Font.RobotoMono
	)
	subHeader.TextColor3 = Color3.fromRGB(110, 185, 140)
	subHeader.Text = "PACIFIC NORTHWEST · ROUTE 9 · 02:00 AM RAINSTORM"

	local divider = Instance.new("Frame")
	divider.Size = UDim2.new(1, -48, 0, 1)
	divider.Position = UDim2.fromOffset(24, 80)
	divider.BackgroundColor3 = Color3.fromRGB(38, 50, 44)
	divider.BorderSizePixel = 0
	divider.Parent = card

	local bodyText =
		Theme.label(card, UDim2.new(1, -48, 0, 210), UDim2.fromOffset(24, 96), 14, Enum.Font.Code)
	bodyText.TextColor3 = Theme.inkSoft
	bodyText.TextWrapped = true
	bodyText.TextYAlignment = Enum.TextYAlignment.Top
	bodyText.Text = ""

	local briefingLines = {
		"> You have clocked in for the graveyard shift at the front reception desk.",
		"> Inspect every guest who walks to the counter. Not all of them are human.",
		"> Verify credentials in the Ledger [F], dial room occupancy [T], use the UV Blacklight [Q], and question them via Intercom [G].",
		"> ADMIT genuine travelers [Z]. REFUSE unnatural anomalies [X].",
		"> Maintain your Sanity. Do not let breaches into the motel rooms.",
	}

	local punchButton = Theme.button(
		card,
		UDim2.new(1, -48, 0, 52),
		UDim2.new(0, 24, 1, -72),
		"PUNCH IN & COMMENCE SHIFT  [ENTER]",
		Color3.fromRGB(48, 145, 75),
		Theme.inkBright
	)
	punchButton.TextSize = 15

	-- Animate typewriter text line-by-line
	local dismissed = false
	task.spawn(function()
		local fullText = ""
		for _, line in briefingLines do
			if dismissed then
				break
			end
			fullText = fullText .. line .. "\n\n"
			bodyText.Text = fullText
			Atmosphere.playSound("paper", nil, 0.25)
			task.wait(0.4)
		end
	end)

	local function punchIn()
		if dismissed then
			return
		end
		dismissed = true

		Atmosphere.playSound("stamp", nil, 0.95)
		Atmosphere.playSound("bell", nil, 0.7)

		punchButton.Text = "SHIFT COMMENCED..."
		punchButton.BackgroundColor3 = Color3.fromRGB(25, 32, 28)

		TweenService
			:Create(card, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Position = UDim2.new(0.5, -340, 0.5, -180),
				BackgroundTransparency = 1,
			})
			:Play()

		for _, child in card:GetDescendants() do
			if child:IsA("TextLabel") or child:IsA("TextButton") then
				TweenService:Create(child, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
			elseif child:IsA("Frame") then
				TweenService:Create(child, TweenInfo.new(0.4), { BackgroundTransparency = 1 })
					:Play()
			end
		end

		task.wait(0.5)
		if curtain then
			local fadeTween = TweenService:Create(
				curtain,
				TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{
					BackgroundTransparency = 1,
				}
			)
			fadeTween:Play()
			fadeTween.Completed:Connect(function()
				if introGui then
					introGui:Destroy()
					introGui = nil
				end
			end)
		end

		startShift:FireServer()
		onComplete()
	end

	punchButton.Activated:Connect(punchIn)

	local connection: RBXScriptConnection?
	connection = UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.Space then
			if connection then
				connection:Disconnect()
				connection = nil
			end
			punchIn()
		end
	end)
end

return IntroUI
